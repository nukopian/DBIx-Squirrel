use v5.36;

package DBIx::Squirrel::db;

use Carp      qw(croak);
use DBI       qw();
use Ref::Util qw(is_arrayref is_coderef is_hashref is_ref);

use DBIx::Squirrel::Errors       qw(at_caller failed in_method);
use DBIx::Squirrel::Placeholders qw(study_sql);
use DBIx::Squirrel::Pipes        qw();

use namespace::clean;

our @ISA = ('DBI::db', 'DBIx::Squirrel::Pipes');

# Croak at the line that called DBIx::Squirrel, past the DBI's own code,
# which calls prepare from its prepare_cached, and DBIx::Squirrel's.
our @CARP_NOT = qw(
    DBI            DBI::db            DBI::st
    DBD::_::common DBD::_::db         DBD::_::st
    DBIx::Squirrel DBIx::Squirrel::st DBIx::Squirrel::Errors
);

# Prepare a statement, with placeholders in any style, and return its
# handle.
sub prepare ($self, $statement, $attrs = undef, @args) {
    return _prepare($self, $statement, $attrs, @args)
        || croak failed($self, 'prepare');
}

# Prepare a statement, as prepare does, and return its handle, or
# nothing, as the DBI's prepare does, if it can't be prepared.
sub _prepare ($self, $statement, $attrs, @args) {
    my($normalised, $state, $dbi_attrs) = _study($self, $statement, $attrs);
    my $sth = at_caller { $self->SUPER::prepare($normalised, $dbi_attrs, @args) }
        or return;
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
    my $sth = in_method $self, 'prepare_cached', sub {
        at_caller { $self->SUPER::prepare_cached($normalised, $dbi_attrs, @args) }
            or croak failed($self, 'prepare_cached');
    };
    $sth->{private_ekorn} = $state;
    return $sth;
}

# Run a statement, and return what the DBI's do returns. Unlike the DBI's,
# the attributes may be left out. A statement DBIx::Squirrel doesn't
# rewrite goes to the driver's own do, as with plain DBI, so the driver's
# row counts and options, such as DBD::SQLite's multiple statements,
# apply; any other is prepared and executed, returning undef, as the DBI
# does, if it can't be prepared.
sub do ($self, $statement, @args) {
    my $attrs = _shift_attrs(\@args);
    my($normalised, $state, $dbi_attrs) = _study($self, $statement, $attrs);
    return in_method $self, 'do', sub {
        my $sth = _prepare($self, $statement, $attrs) or return;
        $sth->execute(@args);
        }
        if $state->{Binds};
    @args = @{ $args[0] }
        if @args == 1
        && is_arrayref($args[0])
        && !($self->{Driver}{Name} eq 'Pg'
            && _values_taken($state->{Placeholders}) == 1);
    return at_caller { $self->SUPER::do($normalised, $dbi_attrs, @args) };
}

# Return how many values a statement the DBI binds as written takes: one
# for each "?", or the highest number of those DBD::Pg reads as "$1".
sub _values_taken ($placeholders) {
    my @placeholders = values %$placeholders;
    return scalar @placeholders
        unless @placeholders && $placeholders[0] =~ m( \A \$ )x;
    my($highest) = sort { $b <=> $a } map { s( \A \$ )()xr } @placeholders;
    return $highest;
}

# Prepare a statement, and return an iterator over its results, executed
# with the bind values given, and run through the stages given after
# them. As with do, the attributes may be left out.
sub iterate ($self, $statement, @args) {
    my $attrs = @args && is_coderef($args[0]) ? undef : _shift_attrs(\@args);
    return $self->prepare($statement, $attrs)->iterate(@args);
}

# Prepare a statement, and return a result set over its results, as
# iterate does.
sub results ($self, $statement, @args) {
    my $attrs = @args && is_coderef($args[0]) ? undef : _shift_attrs(\@args);
    return $self->prepare($statement, $attrs)->results(@args);
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
#
# A statement that can't be prepared returns what the DBI's method does,
# without RaiseError: undef from those returning a reference to one row
# or all of them, and nothing from the others.
sub _select ($self, $method, $statement, $before, $attrs, @args) {
    state %UNDEF = map { ($_ => 1) } qw(
        selectrow_arrayref selectrow_hashref selectall_arrayref
    );
    return in_method $self, $method, sub {
        my $sth
            = $statement isa 'DBI::st'
            ? $statement
            : _prepare($self, $statement, $attrs);
        return $UNDEF{$method} ? undef : ()
            unless $sth;
        # Values for ? placeholders go to the DBI, which checks them as
        # plain DBI does; those for numbered or named ones are bound.
        my @values = DBIx::Squirrel::st::_unwrap($sth, @args);    ## no critic (Subroutines::ProtectPrivateSubs)
        if (@values && $sth->{private_ekorn}{Binds}) {
            $sth->bind(@values) or return;
            @values = ();
        }
        my $super = "SUPER::$method";
        at_caller { $self->$super($sth, @$before, $attrs, @values) };
    };
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
    my $slice = $options{ekorn_slice};
    croak 'Expected ekorn_slice to be a reference to an ARRAY or HASH'
        if defined $slice && !is_arrayref($slice) && !is_hashref($slice);
    my($placeholders, $normalised, $original)
        = study_sql(_statement_text($statement), \%options)
        or croak 'Expected a statement';
    my $dbi_attrs = $attrs
        && {map { ($_ => $attrs->{$_}) } grep { !m( \A ekorn_ )x } keys %$attrs};
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
be prepared, whatever C<RaiseError> is set to, with the message the DBI
raises under C<RaiseError>, such as
C<DBD::SQLite::db prepare failed: near "SELEC": syntax error>.

=head2 prepare_cached

    $sth = $dbh->prepare_cached($statement);
    $sth = $dbh->prepare_cached($statement, \%attr);
    $sth = $dbh->prepare_cached($statement, \%attr, $if_active);

As L</prepare>, using the DBI's cache of statement handles. Its errors
name C<prepare_cached>, as the DBI's do.

=head2 do

    $rv = $dbh->do($statement);
    $rv = $dbh->do($statement, \%attr, @bind_values);
    $rv = $dbh->do($statement, undef, @bind_values);
    $rv = $dbh->do($statement, @bind_values);

Runs a statement, and returns what the DBI's C<do> returns: the number
of rows affected, C<0E0> for none, or C<undef> on an error without
C<RaiseError>. Unlike the DBI's, the attributes may be left out: the
first argument after the statement is taken as the attributes only if
it's a hash reference or C<undef>. An error names C<do>, as the DBI's
does: C<DBD::SQLite::db do failed: ...>.

A statement with C<?> placeholders, or none, goes to the driver's own
C<do>, as with plain DBI, so the driver's row counts and options apply,
such as running several statements with DBD::SQLite's
C<sqlite_allow_multiple_statements>. A statement with numbered or named
placeholders is prepared, as L</prepare> does, and executed, with the
values bound as L<DBIx::Squirrel::st/bind> binds them; some drivers,
such as DBD::SQLite, then count the rows of an C<UPDATE ... RETURNING>
only as they're fetched, giving C<0E0>.

Like the DBI's, C<do> returns no rows, even from a C<SELECT> or a
C<RETURNING> clause. Use L</prepare> and C<execute>, or the select
methods, for those.

=head2 iterate

    $it = $dbh->iterate($statement, \%attr, @bind_values, @stages);
    $it = $dbh->iterate($statement, @bind_values, @stages);

Prepares a statement, as L</prepare> does, and returns a
L<DBIx::Squirrel::Iterator>, an iterator over its results, as
L<DBIx::Squirrel::st/iterate> does. As with L</do>, the attributes may
be left out.

=head2 results

    $results = $dbh->results($statement, \%attr, @bind_values, @stages);
    $results = $dbh->results($statement, @bind_values, @stages);

As L</iterate>, returning a L<DBIx::Squirrel::Results>, whose rows are
objects with a method for each column.

=head2 selectrow_array, selectrow_arrayref, selectrow_hashref

=head2 selectall_arrayref, selectall_hashref, selectcol_arrayref

    $ary_ref = $dbh->selectrow_arrayref($statement, \%attr, @bind_values);
    $hash_ref = $dbh->selectall_hashref($statement, $key_field, \%attr, @bind_values);

As the DBI's, preparing the statement as L</prepare> does, unless it's
already a statement handle, and binding the values as
L<DBIx::Squirrel::st/bind> binds them. The DBI's C<selectall_array>
goes through C<selectall_arrayref>, so it does too. Unlike L</prepare>,
they don't croak if the statement can't be prepared: without
C<RaiseError>, each returns what the DBI's returns, as C<do> does.

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
