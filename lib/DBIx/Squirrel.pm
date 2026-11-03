use v5.36;

package DBIx::Squirrel;

use Carp      qw(croak);
use DBI       qw();
use Ref::Util qw(is_hashref);

use DBIx::Squirrel::Stop qw();
use DBIx::Squirrel::db   qw();
use DBIx::Squirrel::st   qw();

use namespace::clean;

our @ISA     = 'DBI';
our $VERSION = 'v2.0.0';

# Return the handle of the connection to the requested data source.
sub connect ($class, $source, @args) {
    return _connect_dbh($class, $source, @args)
        if $source isa 'DBI::db';
    my $username = is_hashref($args[0]) ? undef       : shift @args;
    my $password = is_hashref($args[0]) ? undef       : shift @args;
    my $attrs    = is_hashref($args[0]) ? shift @args : {};
    my $dbh      = $class->SUPER::connect(
        $source,
        $username,
        $password, {
            %$attrs,
            RootClass => ref($class) || $class,
        },
    );
    croak $DBI::errstr
        unless $dbh;
    return $dbh;
}

# Return the handle of a new connection using the same parameters as
# another connection.
sub _connect_dbh ($class, $dbh, @args) {
    my $attrs = @args && is_hashref($args[0]) ? shift @args : {};
    $dbh = $dbh->clone({
        %$attrs,
        RootClass => ref($class) || $class,
    });
    croak $DBI::errstr
        unless $dbh;
    return $dbh;
}

1;

__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel - DBI, minus the boilerplate, plus a pipeline

=head1 SYNOPSIS

    use DBIx::Squirrel;

    my $dbh = DBIx::Squirrel->connect($data_source, $username, $password, \%attr);

    # A new connection with the same parameters as an existing one
    my $other = DBIx::Squirrel->connect($dbh, \%attr);

    # Run the database handle through a pipeline of stages
    my @results = $dbh->pipe(
        sub ($dbh)   { ... },
        sub ($value) { ... },
    );

    # The same, as a branch off to the side: get the handle back
    $dbh = $dbh->tap(
        sub ($dbh)   { ... },
        sub ($value) { ... },
    );

=head1 DESCRIPTION

DBIx::Squirrel keeps you writing SQL, as the L<DBI> does, and takes away
the friction around it: placeholders in whatever style you like,
iterators over results, and a pipeline of transformations declared
beside the query.

It subclasses the DBI, so everything the DBI does still works, and
where the two do the same thing they give the same result. This page
notes where they differ.

B<In development.> This is the successor to DBIx-Squirrel 1.x, being
rewritten for Perl 5.36 or later, and much of it is still to come. In
particular, DBIx::Squirrel's statement handles have only L</pipe> and
L</tap> of their own so far.

=head1 METHODS

=head2 connect

    $dbh = DBIx::Squirrel->connect($data_source, $username, $password);
    $dbh = DBIx::Squirrel->connect($data_source, $username, $password, \%attr);
    $dbh = DBIx::Squirrel->connect($dbh, \%attr);

Connects to a data source, as the DBI's C<connect> does, and returns a
database handle, a L<DBIx::Squirrel::db>. Its statement handles are
L<DBIx::Squirrel::st>s. Both are subclasses of the DBI's own, so they
do everything the DBI's handles do.

Unlike the DBI's C<connect>, it B<always croaks> if the connection
fails, whatever C<RaiseError> is set to, with the DBI's error message,
reported at the line that called C<connect>. The DBI returns C<undef>
unless C<RaiseError> is set.

Called on a subclass of DBIx::Squirrel, it uses that subclass's database
and statement handle classes in place of DBIx::Squirrel's. The subclass
needs both, as the DBI requires, each a subclass of DBIx::Squirrel's:

    package My::Squirrel     { our @ISA = 'DBIx::Squirrel' }
    package My::Squirrel::db { our @ISA = 'DBIx::Squirrel::db' }
    package My::Squirrel::st { our @ISA = 'DBIx::Squirrel::st' }

Without them, the DBI warns that the subclass isn't set up, and returns
its own handles.

=head3 Connecting with an existing handle

Given a database handle in place of a data source, C<connect> makes a
new connection with the same parameters, using the DBI's C<clone>. Any
attributes passed are applied to the new connection. The handle can
come from the DBI itself, or from code that made its own connection.

The new handle is a separate connection, not a second name for the
first: it doesn't share the first one's transaction, temporary tables
or session settings. An in-memory SQLite database, for example, gives
a new, empty database.

=head3 connect_cached

C<connect_cached> is the DBI's own, unchanged. The DBI's C<connect_cached>
calls C<connect> when it needs a new connection, so it croaks on failure
too.

=head1 HANDLE METHODS

Database and statement handles both have these methods, inherited from
L<DBIx::Squirrel::Pipes>. The examples use a database handle; on a
statement handle, the statement handle goes through the stages instead.

=head2 pipe

    @results = $dbh->pipe(@stages);
    $result  = $dbh->pipe(@stages);

Runs the database handle through a pipeline of stages, and returns what
comes out of the last one.

Each stage is a code reference, called with one value, as its argument
and in C<$_>. The first is called with the database handle. A stage
returns nothing to drop the value, one value to pass it on, or several,
each of which goes through the rest of the stages on its own:

    my @odd_doubled = $dbh->pipe(
        sub ($dbh) { (3, 4, 5) },
        sub { $_ % 2 ? $_ : () },
        sub { $_ * 2 },
    );    # (6, 10)

To end the pipeline early, call L</Stop>. With no stages, C<pipe>
returns the database handle.

Called in list context, C<pipe> returns all the values. In scalar
context, it returns the first, or C<undef> if there are none. To count
the values instead, assign them to an empty list, and take that in
scalar context:

    my $count = () = $dbh->pipe(@stages);

If a stage dies, C<pipe> croaks at the line that called it, naming the
stage by its position, from C<#1>:

    Pipeline stage #2 failed at script.pl line 12:
        ...

L<DBIx::Squirrel::Pipeline> says more about stages.

=head2 tap

    $dbh = $dbh->tap(@stages);

Runs the database handle through a pipeline of stages, as a branch off
to the side for their side effects, and returns the handle, so that a
chain of method calls can carry on after it.

    $dbh ───┬───▶ $dbh
            │
            └───▶ stage #1 ───▶ stage #2 ───▶ ...

The stages work as they do in L</pipe>; what comes out of the last one
is dropped. For example, to log how many rows a table has, then carry
on with the handle:

    $dbh->tap(
        sub ($dbh)   { $dbh->selectrow_array('SELECT COUNT(*) FROM artist') },
        sub ($count) { log_count($count) },
    )->do('DELETE FROM artist WHERE id = ?', undef, $id);

A stage passes on whatever its last statement gives, even one run for
its side effects, so each stage except the last should return what the
next one needs.

C<tap> returns the handle however the stages end: having run out of
values, been stopped with L</Stop>, or with no stages at all. If a
stage dies, C<tap> croaks at the line that called it, as L</pipe> does.

=head1 FUNCTIONS

=head2 Stop

    use DBIx::Squirrel::Stop;
    Stop();
    Stop(@values);

    DBIx::Squirrel::Stop->throw(@values);

Called from a stage of a pipeline, ends the pipeline quietly. The rest
of that stage doesn't run. The values already out of the pipeline are
kept, C<@values> go on through the stages after it, and nothing else is
processed. C<Stop> is exported automatically by
L<DBIx::Squirrel::Stop>; C<< DBIx::Squirrel::Stop->throw >> does the same
without importing it.

Stop works by throwing an exception, which the pipeline catches. So a stage that catches errors itself, with C<eval> or C<try>,
should throw a stop on again:

    sub ($row) {
        try { ... }
        catch ($e) {
            die $e if $e isa 'DBIx::Squirrel::Stop';
            ...
        }
    }

Called outside a stage, it dies with "Stop used outside a pipeline".
L<DBIx::Squirrel::Stop> says more, including what a stop carries.

=head1 DIAGNOSTICS

=over

=item Pipeline stage #%d failed at %s line %d:

A stage passed to L</pipe> or L</tap> died. The message it died with
follows, indented.

=item Stage #%d is not a code-reference

Something passed to L</pipe> or L</tap> wasn't a code reference. No
stage runs.

=item Stop used outside a pipeline

L</Stop> was called where no pipeline was running to catch it.

=back

=head1 SEE ALSO

L<DBI>, L<DBIx::Squirrel::db>, L<DBIx::Squirrel::st>,
L<DBIx::Squirrel::Pipes>, L<DBIx::Squirrel::Pipeline>,
L<DBIx::Squirrel::Stop>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
