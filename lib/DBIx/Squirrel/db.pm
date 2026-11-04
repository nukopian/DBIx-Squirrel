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
sub prepare ($self, $statement, $attrs = undef, @args) {
    my($normalised, $state, $dbi_attrs) = _study($self, $statement, $attrs);
    my $sth = $self->SUPER::prepare($normalised, $dbi_attrs, @args)
        or croak $self->errstr;
    $sth->{private_ekorn} = $state;
    return $sth;
}


# Prepare a statement, with placeholders in any style, using the DBI's
# cache of statement handles, and return its handle.
#
# The DBI caches a handle by its statement and attributes, and different
# statements can be rewritten the same, as "SELECT :a, :b" and
# "SELECT :b, :a" both are, so the original statement goes in a private
# attribute, to keep their handles apart.
sub prepare_cached ($self, $statement, $attrs = undef, @args) {
    my($normalised, $state, $dbi_attrs) = _study($self, $statement, $attrs);
    $dbi_attrs = {
        %{ $dbi_attrs // {} },
        private_ekorn_statement => $state->{OriginalStatement},
    };
    my $sth = $self->SUPER::prepare_cached($normalised, $dbi_attrs, @args)
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


# The DBI's select methods, each preparing the statement and binding its
# values as DBIx::Squirrel does. Drivers built on the DBI's own C code,
# such as DBD::SQLite, DBD::mysql and DBD::Pg, bind and execute in C, not
# through DBIx::Squirrel's methods, so each is given a statement handle
# with its values already bound.
sub selectrow_array ($self, $statement, $attrs = undef, @args) {
    return _select($self, 'selectrow_array', $statement, [], $attrs, @args);
}


sub selectrow_arrayref ($self, $statement, $attrs = undef, @args) {
    return _select($self, 'selectrow_arrayref', $statement, [], $attrs, @args);
}


sub selectrow_hashref ($self, $statement, $attrs = undef, @args) {
    return _select($self, 'selectrow_hashref', $statement, [], $attrs, @args);
}


sub selectall_arrayref ($self, $statement, $attrs = undef, @args) {
    return _select($self, 'selectall_arrayref', $statement, [], $attrs, @args);
}


sub selectall_hashref ($self, $statement, $key_field, $attrs = undef, @args) {
    return _select(
        $self, 'selectall_hashref', $statement, [$key_field], $attrs, @args,
    );
}


sub selectcol_arrayref ($self, $statement, $attrs = undef, @args) {
    return _select($self, 'selectcol_arrayref', $statement, [], $attrs, @args);
}


# Call one of the DBI's select methods with a statement handle, prepared,
# unless it was given one, and with any values bound. Return what the
# DBI's method returns.
sub _select ($self, $method, $statement, $before, $attrs, @args) {
    my $sth
        = $statement isa 'DBI::st'
        ? $statement
        : $self->prepare($statement, $attrs);
    if (@args) {
        $sth->bind(@args) or return;
    }
    my $super = "SUPER::$method";
    return $self->$super($sth, @$before, $attrs);
}


# Return a statement with its placeholders rewritten as "?", for the DBI
# to prepare, what its statement handle keeps about it, and the attributes
# to prepare it with, without DBIx::Squirrel's own. Study it with the
# driver's name, DBD::Pg's placeholder options from the handle, the
# handle's own defaults, from connect, and the attributes given, each
# overriding the last.
sub _study ($self, $statement, $attrs) {
    my $driver  = $self->{Driver}{Name};
    my $state   = $self->{private_ekorn};
    my @pg      = qw(pg_placeholder_dollaronly pg_placeholder_nocolons);
    my %options = (
        ekorn_dialect => $driver,
        ($driver eq 'Pg' ? map { ($_ => $self->{$_}) } @pg : ()),
        %{ $state && $state->{Options} // {} },
        %{ $attrs // {} },
    );
    my($placeholders, $normalised, $original)
        = study_sql(_statement_text($statement), \%options)
        or croak 'Expected a statement';
    my $dbi_attrs = $attrs
        && {map { ($_ => $attrs->{$_}) } grep { !/^ekorn_/x } keys %$attrs};
    return $normalised, {
        Placeholders      => $placeholders,
        OriginalStatement => $original,
        Options           => \%options,
        Binds             => scalar _binds($placeholders, $normalised, $original),
    }, $dbi_attrs;
}


# Return a map of each number or name a statement's placeholders use to
# the positions using it, from 1, or nothing if the statement goes to the
# DBI as written: with "?" placeholders or none, or with placeholders left
# for DBD::Pg to read.
sub _binds ($placeholders, $normalised, $original) {
    return if $normalised eq $original;
    my %binds;
    for my $position (sort { $a <=> $b } keys %$placeholders) {
        my $placeholder = $placeholders->{$position};
        my $key         = $placeholder =~ s( \A [?:\$] )()xr;
        if ($key =~ m( \A \d+ \z )x) {
            croak "Expected placeholders numbered from 1 ($placeholder)"
                if $key == 0;
            $key += 0;
        }
        push @{ $binds{$key} }, $position;
    }
    return \%binds;
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
L<DBIx::Squirrel::st>. L</do> and the DBI's select methods, such as
C<selectrow_array>, prepare a statement this way too.

The statement can use placeholders in any of these styles, which are
rewritten as C<?> before the DBI sees them:

    SELECT * FROM artist WHERE id = ?
    SELECT * FROM artist WHERE id = ?1
    SELECT * FROM artist WHERE id = :1
    SELECT * FROM artist WHERE id = $1
    SELECT * FROM artist WHERE id = :id

A statement uses one style of placeholder throughout; C<prepare> croaks
if it finds more than one. The same placeholder can appear more than
once.

A numbered placeholder is bound once, wherever it appears, and a named
one by name, as L<DBIx::Squirrel::st/bind> describes. Numbers start
from 1.

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
except in PostgreSQL's C<E'...'> strings. MySQL's
C<NO_BACKSLASH_ESCAPES> mode isn't noticed.

A database reached through another driver, such as DBD::ODBC or
DBD::Proxy, is read by its own rules if it says what it is, as
L<DBIx::Squirrel/connect> describes, and by the standard rules if it
doesn't. To read a statement as another dialect, name that dialect's
driver in the C<ekorn_dialect> attribute:

    $dbh->prepare($statement, {ekorn_dialect => 'mysql'});

Attributes starting C<ekorn_> are DBIx::Squirrel's own, and aren't
passed on to the DBI. Passed to L<DBIx::Squirrel/connect>, they're the
defaults for every statement the handle prepares; passed to C<prepare>,
they override those for one statement.

To use a C<?>, C<:> or C<$> that isn't a placeholder, such as one of
PostgreSQL's C<?>, C<?|> and C<?&> operators, put a backslash before it,
as L<DBD::Pg> allows. The backslash and the character after it are
passed on as they are, and DBD::Pg removes the backslash:

    $dbh->prepare(q{SELECT * FROM doc WHERE data \? 'key' AND id = :id});

DBD::Pg's own placeholder options are followed too, whether set on the
database handle or passed to C<prepare>. With C<pg_placeholder_dollaronly>,
only C<$1>-style placeholders are recognised, and the statement is passed
on as written, for DBD::Pg to read. With C<pg_placeholder_nocolons>, the
C<:1> and C<:name> styles aren't placeholders, so array slices such as
C<data[:2]> are left alone.

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
taken as the attributes only if it's a hash reference or C<undef>. The
values are bound as L<DBIx::Squirrel::st/bind> binds them.

=head2 selectrow_array, selectrow_arrayref, selectrow_hashref

=head2 selectall_arrayref, selectall_hashref, selectcol_arrayref

    $ary_ref = $dbh->selectrow_arrayref($statement, \%attr, @bind_values);
    $hash_ref = $dbh->selectall_hashref($statement, $key_field, \%attr, @bind_values);

As the DBI's, preparing the statement as L</prepare> does, unless it's
already a statement handle, and binding the values as
L<DBIx::Squirrel::st/bind> binds them. The DBI's C<selectall_array>
goes through C<selectall_arrayref>, so it does too.

=head1 DIAGNOSTICS

=over

=item Expected one placeholder style, not several (%s)

The statement used more than one style of placeholder, such as C<?> and
C<:name>. The styles found are listed, each as an example: C<?>, C<?1>,
C<:1>, C<$1>, C<:name> or C<$name>.

=item Expected placeholders numbered from 1 (%s)

The statement had a numbered placeholder such as C<$0>.

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
