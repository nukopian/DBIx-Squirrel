use v5.36;

package DBIx::Squirrel::Sugar;

use Ref::Util qw(is_arrayref is_coderef is_hashref);

use DBIx::Squirrel         qw();
use DBIx::Squirrel::Errors qw(croakf);

use namespace::clean;

# Croak at the line that called DBIx::Squirrel.
our @CARP_NOT = @DBIx::Squirrel::Errors::INTERNAL;

# Each database defined, by name: the arguments to connect with, and, for
# one defined with a handle, the handle cloned from it.
my %connect_args;
my %clone;

# Give the calling package database or statement, and define the
# databases or statements named in a hash reference after each, with
# their arguments in an array reference.
sub import ($class, @args) {
    state %define = (database => \&_define, statement => \&_define_statement);
    state %what = (database => 'arguments to connect to', statement => 'statement');
    my $package = caller;
    while (@args) {
        my $arg = shift @args;
        croakf 'Expected database or statement, not %s', $arg
            unless $define{$arg};
        _install($package, $arg => $class->can($arg));
        next unless @args && is_hashref($args[0]);
        my $definitions = shift @args;
        for my $name (sort keys %$definitions) {
            croakf 'Expected the %s %s in an ARRAY', $what{$arg}, $name
                unless is_arrayref($definitions->{$name});
            $define{$arg}->($package, $name, @{ $definitions->{$name} });
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

# Define a statement on a database, with the attributes to prepare it
# with and stages, if given, give the calling package a function of its
# name, and return that.
sub statement ($name, $database, $statement, @rest) {
    return _define_statement(scalar caller, $name, $database, $statement, @rest);
}

# Define a database, and give a package a function of its name, returning
# the function.
sub _define ($package, $name, @connect) {
    croakf 'Expected a name for a database (%s)', $name
        unless _is_name($name);
    croakf 'Expected a database defined once (%s)', $name
        if $connect_args{$name};
    my $function = sub (@args) { _run($name, @args) };
    _install($package, $name, $function);
    $connect_args{$name} = \@connect;
    return $function;
}

# Define a statement, and give a package a function of its name, returning
# the function.
sub _define_statement ($package, $name, @definition) {
    my($database, $statement, @rest) = @definition;
    croakf 'Expected a name for a statement (%s)', $name
        unless _is_name($name);
    croakf 'Expected a database and a statement for %s', $name
        unless defined $database && defined $statement;
    my $attrs = @rest
        && (!defined $rest[0] || is_hashref($rest[0])) ? shift @rest : undef;
    croakf 'Expected only stages after the statement for %s', $name
        if grep { !is_coderef($_) } @rest;
    my %definition = (
        database  => $database,
        statement => $statement,
        attrs     => $attrs,
        stages    => \@rest,
    );
    my $function = sub (@args) { _run_statement(\%definition, @args) };
    _install($package, $name, $function);
    return $function;
}

# Run a statement's function: execute the statement with the bind values
# given, and return its handle, or, with stages, its own or those given
# after the bind values, return the results. The statement is prepared
# once for each handle, unless the one prepared is in use, when it's
# prepared again for this call.
sub _run_statement ($definition, @args) {
    my $dbh       = database($definition->{database});
    my @statement = @$definition{qw(statement attrs)};
    my $sth       = $dbh->prepare_cached(@statement, 3);
    $sth = $dbh->prepare(@statement)
        if DBIx::Squirrel::Iterator::_going($sth);    ## no critic (Subroutines::ProtectPrivateSubs)
    my $n = @args;
    $n -= 1 while $n && is_coderef($args[$n - 1]);
    my @stages = (@{ $definition->{stages} }, splice @args, $n);
    return $sth->iterate(@args, @stages)->all if @stages;
    defined $sth->execute(@args) or return;
    return $sth;
}

# Return true if a name can be a function's.
sub _is_name ($name) {
    return $name =~ m( \A [^\W\d] \w* \z )x;
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

DBIx::Squirrel::Sugar - a function for each database, and each statement

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

    # Statements, with stages of their own
    use DBIx::Squirrel::Sugar statement => {
        artist_names => [music => 'SELECT name FROM artist', sub ($row) { $row->[0] }],
        artist       => [music => 'SELECT * FROM artist WHERE id = :id'],
    };

    my @all   = artist_names;                             # the results
    my @upper = artist_names sub ($name) { uc $name };    # with more stages
    my $found = artist id => 1;                           # executed

    # Or defined as the program runs
    use DBIx::Squirrel::Sugar qw(database statement);
    database(archive => 'dbi:SQLite:dbname=archive.db', '', '', \%attr);
    statement(albums => archive => 'SELECT * FROM album');

=head1 DESCRIPTION

DBIx::Squirrel::Sugar gives each database a name, and the package that
names it a function of that name, which returns the database handle, or
runs a statement on it. It gives a statement a function too, which runs
it, with the bind values and any stages given.

A database is connected to when it's first used, not when it's defined,
with L<DBIx::Squirrel/connect_cached>, so each use has the same handle,
and a connection that has dropped is made again. Two databases defined
with the same arguments share a handle, as C<connect_cached> shares it.

=head1 IMPORTING

    use DBIx::Squirrel::Sugar qw(database statement);
    use DBIx::Squirrel::Sugar database => {$name => [@connect_args], ...};
    use DBIx::Squirrel::Sugar statement => {
        $name => [$database, $statement, \%attr, @stages], ...
    };

Gives the package L</database>, or L</statement>, or both. Given a hash
reference after either, it also defines each database or statement named
in it, with the arguments it takes, in an array reference, and gives the
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

=head2 statement

    $function = statement($name, $database, $statement, @stages);
    $function = statement($name, $database, $statement, \%attr, @stages);

Defines a statement by that name, on the database of that name, with the
attributes to prepare it with, and stages, if given, gives the calling
package a function of that name, and returns the function. The database
is found when the function runs, so it can be defined after the
statement.

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

=head2 The function a statement is given

    $sth     = artist(@bind_values);
    @results = artist(@bind_values, @stages);
    $count   = artist(@bind_values, @stages);

Executes the statement with the bind values, and returns the statement
handle, or nothing if it couldn't be executed. With stages, its own or
those given after the bind values, it iterates over the results, through
its own stages and then those given, and returns them all, or how many
there were in scalar context. Stages given are for that call only.

The statement is prepared once for each database handle, with
L<DBIx::Squirrel::db/prepare_cached>. While its handle is in use, by a
statement handle not read to the end, or by a stage calling the same
function, a call prepares one of its own.

=head1 DIAGNOSTICS

=over

=item Expected database or statement, not %s

C<use DBIx::Squirrel::Sugar> was given something other than C<database>
or C<statement> and their definitions.

=item Expected the arguments to connect to %s in an ARRAY

=item Expected the statement %s in an ARRAY

A definition given to C<use> wasn't an array reference.

=item Expected a name for a statement (%s)

A name can't be a function's.

=item Expected a database and a statement for %s

A statement given to C<use> didn't name its database, or have its SQL.

=item Expected only stages after the statement for %s

A statement's definition had something other than code references after
the statement and its attributes.

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

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
