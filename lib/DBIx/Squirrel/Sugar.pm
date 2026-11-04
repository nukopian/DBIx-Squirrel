use v5.36;

package DBIx::Squirrel::Sugar;

use Ref::Util qw(is_arrayref is_coderef is_hashref);

use DBIx::Squirrel         qw();
use DBIx::Squirrel::Errors qw(croakf);

use namespace::clean;

# Croak at the line that called DBIx::Squirrel, past its own code and the
# DBI's.
our @CARP_NOT = qw(
    DBIx::Squirrel         DBIx::Squirrel::db       DBIx::Squirrel::st
    DBIx::Squirrel::Errors DBIx::Squirrel::Iterator DBIx::Squirrel::Pipeline
    DBIx::Squirrel::Context
);

# Each database defined, by name: the arguments to connect with, and, for
# one defined with a handle, the handle cloned from it.
my %connect_args;
my %clone;

# Give the calling package database, and define the databases named in a
# hash reference after it, each with the arguments to connect with in an
# array reference.
sub import ($class, @args) {
    my $package = caller;
    while (@args) {
        my $arg = shift @args;
        croakf 'Expected database, not %s', $arg
            unless $arg eq 'database';
        _install($package, database => \&database);
        next unless @args && is_hashref($args[0]);
        my $definitions = shift @args;
        for my $name (sort keys %$definitions) {
            croakf 'Expected the arguments to connect to %s in an ARRAY', $name
                unless is_arrayref($definitions->{$name});
            _define($package, $name, @{ $definitions->{$name} });
        }
    }
    return;
}

# Return the handle of the database named, or, given the arguments to
# connect with, define it, give the calling package a function of its
# name, and return that.
sub database ($name, @connect) {
    return _define(scalar caller, $name, @connect) if @connect;
    croakf 'Expected a database defined as %s', $name
        unless $connect_args{$name};
    my($source, @rest) = @{ $connect_args{$name} };
    return $clone{$name} //= DBIx::Squirrel->connect($source, @rest)
        if $source isa 'DBI::db';
    return DBIx::Squirrel->connect_cached($source, @rest);
}

# Define a database, and give a package a function of its name, returning
# the function.
sub _define ($package, $name, @connect) {
    croakf 'Expected a name for a database (%s)', $name
        unless $name =~ m( \A [^\W\d] \w* \z )x;
    croakf 'Expected a database defined once (%s)', $name
        if $connect_args{$name};
    my $function = sub (@args) { _run($name, @args) };
    _install($package, $name, $function);
    $connect_args{$name} = \@connect;
    return $function;
}

# Run what a database's function is given: nothing, for the handle; a
# statement and its bind values, for the statement handle, executed; or
# those and stages after them, for the results.
sub _run ($name, @args) {
    my $dbh = database($name);
    return $dbh unless @args;
    my $statement = shift @args;
    my $stages    = @args && is_coderef($args[-1]);
    if ($statement isa 'DBI::st') {
        return $statement->iterate(@args)->all if $stages;
        defined $statement->execute(@args) or return;
        return $statement;
    }
    return $dbh->iterate($statement, @args)->all if $stages;
    my $attrs = DBIx::Squirrel::db::_shift_attrs(\@args);    ## no critic (Subroutines::ProtectPrivateSubs)
    my $sth   = $dbh->prepare($statement, $attrs);
    defined $sth->execute(@args) or return;
    return $sth;
}

# Give a package a named function, croaking if it has one of that name,
# unless it's the same.
sub _install ($package, $name, $code) {
    my $have = $package->can($name);
    return if $have && $have == $code;
    croakf 'Expected no function of the name in %s already (%s)', $package, $name
        if $have;
    no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    *{ "${package}::$name" } = $code;
    return;
}

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Sugar - a function for each database

=head1 SYNOPSIS

    use DBIx::Squirrel::Sugar database => {
        music => [$ENV{MUSIC_DSN}, $ENV{MUSIC_USER}, $ENV{MUSIC_PASS}],
    };

    my $dbh = music;                                   # the handle

    my $sth = music 'SELECT * FROM artist WHERE id = ?', 1;   # executed
    say $sth->fetchrow_hashref->{name};

    my @names = music 'SELECT name FROM artist',       # through stages
        sub ($row) { $row->[0] };

    # Anywhere in the program
    my $handle = database('music');

    # Or defined as the program runs
    use DBIx::Squirrel::Sugar qw(database);
    database(archive => 'dbi:SQLite:dbname=archive.db', '', '', \%attr);

=head1 DESCRIPTION

DBIx::Squirrel::Sugar gives each database a name, and the package that
names it a function of that name, which returns the database handle, or
runs a statement on it.

A database is connected to when it's first used, not when it's defined,
with L<DBIx::Squirrel/connect_cached>, so each use has the same handle,
and a connection that has dropped is made again. Two databases defined
with the same arguments share a handle, as C<connect_cached> shares it.

=head1 IMPORTING

    use DBIx::Squirrel::Sugar qw(database);
    use DBIx::Squirrel::Sugar database => {$name => [@connect_args], ...};

Gives the package L</database>. Given a hash reference after it, it also
defines each database named in it, with the arguments
L<DBIx::Squirrel/connect> takes, in an array reference, and gives the
package its function, while the package is compiled, so it can be
called without parentheses. The arguments are worked out then too: the
environment, literals, and what a C<BEGIN> block has set are there, but
a variable the program sets as it runs is not yet.

=head1 FUNCTIONS

=head2 database

    $dbh      = database($name);
    $function = database($name, @connect_args);

Given a name, returns the handle of the database defined by that name,
anywhere in the program, connecting to it if it isn't connected.

Given a name and the arguments L<DBIx::Squirrel/connect> takes, defines
a database by that name, gives the calling package a function of that
name, and returns the function. A database defined with a database
handle, in place of a data source, is a clone of it, as
L<DBIx::Squirrel/connect> makes, made when it's first used. The DBI
makes a clone the way the handle was made, so a clone of a handle from
C<connect_cached>, such as another database's, is that same handle.

A database is defined once in a program, by a name that can be a
function's, and the package can't have a function of that name already.

=head2 The function a database is given

    $dbh     = music();
    $sth     = music($statement, @bind_values);
    $sth     = music($statement, \%attr, @bind_values);
    @results = music($statement, @bind_values, @stages);
    $count   = music($statement, @bind_values, @stages);

Called with nothing, returns the database handle.

Called with a statement, prepares it, executes it with the bind values,
in any form L<DBIx::Squirrel::st/execute> takes, and returns the
statement handle, or nothing if it couldn't be executed. A hash
reference, or C<undef>, straight after the statement is the attributes
to prepare it with, as with L<DBIx::Squirrel::db/do>.

With stages, the code references at the end, it iterates over the
results, as L<DBIx::Squirrel::db/iterate> does, and returns them all, or
how many there were in scalar context.

The statement can be a statement handle, which is executed, or iterated
over, itself.

=head1 DIAGNOSTICS

=over

=item Expected database, not %s

C<use DBIx::Squirrel::Sugar> was given something other than C<database>
and its definitions.

=item Expected the arguments to connect to %s in an ARRAY

A definition given to C<use> wasn't an array reference.

=item Expected a name for a database (%s)

A name can't be a function's.

=item Expected a database defined once (%s)

The name was given to another database already.

=item Expected no function of the name in %s already (%s)

The package has a function of that name already.

=item Expected a database defined as %s

L</database> was given a name no database has.

=back

=head1 SEE ALSO

L<DBIx::Squirrel>, L<DBIx::Squirrel::Iterator>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
