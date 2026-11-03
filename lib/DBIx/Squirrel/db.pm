use v5.36;

package DBIx::Squirrel::db;

use Carp      qw(croak);
use DBI       qw();
use Ref::Util qw(is_arrayref is_coderef is_hashref is_ref);

use DBIx::Squirrel::Placeholders qw(study_sql);
use DBIx::Squirrel::Pipes        qw();

use namespace::clean;

our @ISA = ('DBI::db', 'DBIx::Squirrel::Pipes');

# Prepare a statement, with placeholders in any style, and return its
# handle.
sub prepare ($self, $statement, @args) {
    my($normalised, $state) = _study($self, $statement);
    my $sth = $self->SUPER::prepare($normalised, @args)
        or croak $self->errstr;
    $sth->{private_ekorn} = $state;
    return $sth;
}


# Prepare a statement, with placeholders in any style, using the DBI's
# cache of statement handles, and return its handle.
sub prepare_cached ($self, $statement, @args) {
    my($normalised, $state) = _study($self, $statement);
    my $sth = $self->SUPER::prepare_cached($normalised, @args)
        or croak $self->errstr;
    $sth->{private_ekorn} = $state;
    return $sth;
}


# Prepare and execute a statement, and return what execute returns, as the
# DBI's do does. Unlike the DBI's, the attributes may be left out.
sub do ($self, $statement, @args) {
    my $attrs = _shift_attrs(\@args);
    my $sth   = $self->prepare($statement, $attrs);
    return $sth->execute(@args);
}


# Return a statement with its placeholders rewritten as "?", for the DBI
# to prepare, and what its statement handle keeps about it.
sub _study ($self, $statement) {
    my($placeholders, $normalised, $original)
        = study_sql(_statement_text($statement), $self->{Driver}{Name})
        or croak 'Expected a statement';
    return $normalised, {
        Placeholders      => $placeholders,
        OriginalStatement => $original,
    };
}


# Return the text of a statement given as a string, as lines in an array
# reference, as a code reference returning either, or as a statement
# handle.
sub _statement_text ($statement) {
    $statement = $statement->() if is_coderef($statement);
    return join ' ', @$statement if is_arrayref($statement);
    if ($statement isa 'DBI::st') {
        my $state = $statement->{private_ekorn};
        return $state ? $state->{OriginalStatement} : $statement->{Statement};
    }
    croak 'Expected a statement' if is_ref($statement);
    return $statement;
}


# Take the attributes off the front of the arguments to do, if they're
# there: a hash reference, or undef, as the DBI allows. An array reference
# or a plain value there is a bind value, and is left in place.
sub _shift_attrs ($args) {
    return unless @$args;
    my $first = $args->[0];
    return shift @$args if !defined $first || is_hashref($first);
    croak 'Expected a reference to a HASH or ARRAY'
        if is_ref($first) && !is_arrayref($first);
    return;
}

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::db - DBIx::Squirrel's database handle class

=head1 DESCRIPTION

A database handle from L<DBIx::Squirrel/connect> is blessed into this
class, a subclass of the DBI's C<DBI::db>, so it does everything a DBI
database handle does. It also inherits L<DBIx::Squirrel/pipe> and
L<DBIx::Squirrel/tap> from L<DBIx::Squirrel::Pipes>.

=head1 METHODS

=head2 prepare

    $sth = $dbh->prepare($statement);
    $sth = $dbh->prepare($statement, \%attr);

Prepares a statement, as the DBI's C<prepare> does, and returns a
L<DBIx::Squirrel::st>. The DBI's other methods that take a statement,
such as C<selectrow_array>, prepare it this way too.

The statement can use placeholders in any of these styles, which are
rewritten as C<?> before the DBI sees them:

    SELECT * FROM artist WHERE id = ?
    SELECT * FROM artist WHERE id = ?1
    SELECT * FROM artist WHERE id = :1
    SELECT * FROM artist WHERE id = $1
    SELECT * FROM artist WHERE id = :id

Placeholders are bound by position, as with C<?>, counting every
placeholder in the statement, whatever its style. One that appears
twice, such as C<$1>, is two placeholders, each needing its own value.
Binding named placeholders by name is still to come.

Placeholders are looked for only in the SQL itself. Anything that looks
like one inside a quoted string or identifier (C<'10:30'>, C<"a:b">,
C<`c?`>), a comment (C<-- :x>, C</* $1 */>) or a PostgreSQL
dollar-quoted body (C<$$ ... $$>, C<$tag$ ... $tag$>) is left as it is,
and so is a cast, such as C<x::int>, or an identifier containing C<$>,
such as C<v$session>.

Strings are read by the rules of the database handle's driver. With
DBD::mysql and DBD::MariaDB, a backslash escapes a character in a string
(C<'it\'s'>), C<"..."> is a string, and C<#> starts a comment. With other
drivers, a backslash is an ordinary character in a string (C<'C:\'>),
except in PostgreSQL's C<E'...'> strings. A driver used through another,
such as DBD::ODBC or DBD::Proxy, is read by the standard rules, whatever
the database behind it. MySQL's C<NO_BACKSLASH_ESCAPES> mode isn't
noticed.

To use a C<?>, C<:> or C<$> that isn't a placeholder, such as one of
PostgreSQL's C<?>, C<?|> and C<?&> operators, put a backslash before it,
as L<DBD::Pg> allows. The backslash and the character after it are
passed on as they are, and DBD::Pg removes the backslash:

    $dbh->prepare(q{SELECT * FROM doc WHERE data \? 'key' AND id = :id});

The statement can be a string, an array reference of lines, which are
joined with spaces, a code reference returning either, or a statement
handle, whose statement is prepared again. Blank space around the
statement is removed; comments are passed on to the database.

Unlike the DBI's C<prepare>, it B<always croaks> if the statement can't
be prepared, whatever C<RaiseError> is set to.

=head2 prepare_cached

    $sth = $dbh->prepare_cached($statement);
    $sth = $dbh->prepare_cached($statement, \%attr);
    $sth = $dbh->prepare_cached($statement, \%attr, $if_active);

As L</prepare>, using the DBI's cache of statement handles.

=head2 do

    $rv = $dbh->do($statement);
    $rv = $dbh->do($statement, \%attr, @bind_values);
    $rv = $dbh->do($statement, undef, @bind_values);
    $rv = $dbh->do($statement, @bind_values);

Prepares a statement, as L</prepare> does, executes it, and returns the
number of rows affected, as the DBI's C<do> does. Unlike the DBI's, the
attributes may be left out: the first argument after the statement is
taken as the attributes only if it's a hash reference or C<undef>.

=head1 DIAGNOSTICS

=over

=item Expected a statement

The statement was blank, or was a reference other than those L</prepare>
takes.

=item Expected a reference to a HASH or ARRAY

The first argument after the statement in L</do> was a reference, but
not to a hash or an array.

=back

=head1 SEE ALSO

L<DBIx::Squirrel>, L<DBI>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
