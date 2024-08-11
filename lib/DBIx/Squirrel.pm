use strict 'vars', 'subs';                                                                                                         # Moved to stop Perl::Critic carping when Dist::Zilla adds
                                                                                                                                   # $VERSION information.

package DBIx::Squirrel;

use warnings;
use constant E_BAD_ENT_BIND     => 'Cannot associate with an invalid object';
use constant E_EXP_HASH_ARR_REF => 'Expected a reference to a HASH or ARRAY';

=pod

=encoding UTF-8

=head1 NAME

DBIx::Squirrel - A module for working with databases

=head1 SYNOPSIS

    # Simply use the package.

    use DBIx::Squirrel;

    $dbh = DBIx::Squirrel->connect($dsn, $user, $pass, \%attr);
    $sth = $dbh->prepare('SELECT * FROM product WHERE id = ?');
    $res = $sth->execute('1001099');
    $itr = $sth->iterate('1001099');
    while ($row = $itr->next) {...}

    # Or, use it and have it create and import helper functions that
    # you can use to interact with database objects.

    use DBIx::Squirrel database_objects=>['db', 'st', 'it'];

    db DBIx::Squirrel->connect($dsn, $user, $pass, \%attr);
    st db->prepare('SELECT * FROM product WHERE id = ?');
    $res = st->execute('1001099');
    $res = st('1001099');  # Same as line above.
    it st->iterate('1001099');
    while ($row = it->next) {...}

    # Clone another database connection.

    $dbi = DBI->connect($dsn, $user, $pass, \%attr);
    $dbh = DBIx::Squirrel->connect($dbi);

    # Prepare a statement object.

    $sth = $dbh->prepare($statement, \%attr);
    $sth = $dbh->prepare_cached($statement, \%attr, $if_active);

    # Commonly used positional and named parameter placeholder schemes
    # conveniently supported regardless of database driver in use.

    $sth = $dbh->prepare('SELECT * FROM product WHERE id = ?');
    $sth = $dbh->prepare('SELECT * FROM product WHERE id = ?1');
    $sth = $dbh->prepare('SELECT * FROM product WHERE id = $1');
    $sth = $dbh->prepare('SELECT * FROM product WHERE id = :1');
    $sth = $dbh->prepare('SELECT * FROM product WHERE id = :id');

    # Able to bind values to individual parameters for both positional
    # and named placeholder schemes.

    $sth->bind_param(1, '1001099');
    $sth->bind_param(':id', '1001099');
    $sth->bind_param('id', '1001099');

    # Bind multiple values to parameters in a single statement.

    $sth->bind( '1001099', ... );
    $sth->bind( [ '1001099', ... ] );
    $sth->bind( ':id' => '1001099', ... );
    $sth->bind( id => '1001099', ... );
    $sth->bind( { ':id' => '1001099', ... } );
    $sth->bind( { id => '1001099', ... } );

    # Or just have the statement handle's or iterator's "execute"
    # method bind all values to parameters by passing it the same
    # arguments you would pass to "bind".

    $res = $obj->execute( '1001099', ... );
    $res = $obj->execute( [ '1001099', ... ] );
    $res = $obj->execute( ':id' => '1001099', ... );
    $res = $obj->execute( id => '1001099', ... );
    $res = $obj->execute( { ':id' => '1001099', ... } );
    $res = $obj->execute( { id => '1001099', ... } );

    # The database handle "do" method works as it does with DBI,
    # with the exception that returns the result followed by the
    # statement handle when called in list-context. This means
    # we can use it to prepare and execute statements, before we
    # fetch results. Be careful to use "undef" if passing named
    # parameters in a hashref so they are not used as statement
    # attributes. The new "do" is smart enough not to confuse
    # other things as statement attributes.

    ($res, $sth) = $dbh->do(
        'SELECT * FROM product WHERE id = ?', '1001099'
    );
    ($res, $sth) = $dbh->do(
        'SELECT * FROM product WHERE id = ?', ['1001099']
    );
    ($res, $sth) = $dbh->do(
        'SELECT * FROM product WHERE id = :id', ':id' => '1001099'
    );
    ($res, $sth) = $dbh->do(
        'SELECT * FROM product WHERE id = :id', id => '1001099'
    );
    ($res, $sth) = $dbh->do( # ------------ undef or \%attr
        'SELECT * FROM product WHERE id = :id', undef,
        { ':id' => '1001099'}
    );
    ($res, $sth) = $dbh->do( # ------------ undef or \%attr
        'SELECT * FROM product WHERE id = :id', undef,
        { id => '1001099' },
    );

    # Statement objects can create iterators using the "iterate"
    # method (or its "it" alias). Use it as you would "execute"

    $itr = $sth->iterate( '1001099' );
    $itr = $sth->iterate(['1001099']);

    $itr = $sth->iterate( '1001099' );
    $itr = $sth->iterate(['1001099']);

    $itr = $sth->iterate( '1001099' );
    $itr = $sth->iterate(['1001099']);

    $itr = $sth->iterate( '1001099' );
    $itr = $sth->iterate(['1001099']);

    $itr = $sth->iterate( '1001099' );
    $itr = $sth->iterate(['1001099']);

    $itr = $sth->iterate( ':id' => '1001099' );
    $itr = $sth->iterate( id => '1001099' );

    $itr = $sth->iterate( { ':id' => '1001099' } );
    $itr = $sth->iterate( { id => '1001099' } );

    # Using the iterators couldn't be easier!

    @ary = ();
    while ($row = $itr->next) {
        push @ary, $row;
    }

    @ary = $itr->first;
    push @ary, $_ while $itr->next;

    @ary = $itr->first;
    push @ary, $itr->remaining;

    @ary = $itr->all;

    $itr = $itr->reset;     # Repositions iterator at the start
    $itr = $itr->reset({}); # Fetch rows as hashrefs
    $itr = $itr->reset([]); # Fetch rows as arrayrefs

    $row = $itr->single;
    $row = $itr->single( id => '1001100' );
    $row = $itr->single( { id => '1001100' } );
    $row = $itr->find( id => '1001100' );
    $row = $itr->find( { id => '1001100' } );

    # A result set is just fancy subclass of the iterator. It will
    # "bless" results, enabling us to get a column's value using an
    # accessor methods, without ever having to worry about whether
    # the row is a array or hash reference. While the accessor
    # methods use lowercase names, they will access the column's
    # value regardless of the case used.

    $sth = $dbh->prepare('SELECT MediaTypeId, Name FROM media_types');
    $res = $sth->results;
    while ($res->next) {
        print $_->name, "\n";
    }

    # Iterators allow for the use of lambda functions to process
    # each row just in time during iteration.

    $it = $sth->iterate(
        sub { $_->{Name} }
    )->reset({});
    print "$_\n" foreach $it->all;

    # Lambdas may be chained.

    $res = $sth->results(
        sub { $_->Name },
        sub { "Media type: $_" },
    );
    print "$_\n" while $res->next;

    print "$_\n" for $dbh->results(
        q/SELECT MediaTypeId, Name FROM media_types/,
        sub { $_->Name },
    )->all;

    print "$_\n" for $dbh->select('media_types')->results(
        sub { $_->Name },
    )->all;

=cut

use DBI;
use Exporter;
use Scalar::Util 'reftype';
use Sub::Name;

use DBIx::Squirrel::dr ();
use DBIx::Squirrel::db ();
use DBIx::Squirrel::st ();
use DBIx::Squirrel::it ();
use DBIx::Squirrel::rs ();
use DBIx::Squirrel::rc ();
use DBIx::Squirrel::util 'throw';

BEGIN {
    *EXPORT_OK   = *DBI::EXPORT_OK;
    *EXPORT_TAGS = *DBI::EXPORT_TAGS;
    *err         = *DBI::err;
    *errstr      = *DBI::errstr;
    *rows        = *DBI::rows;
    *lasth       = *DBI::lasth;
    *state       = *DBI::state;

    *connect         = *DBIx::Squirrel::dr::connect;
    *connect_cached  = *DBIx::Squirrel::dr::connect_cached;
    *SQL_ABSTRACT    = *DBIx::Squirrel::db::SQL_ABSTRACT;
    *DEFAULT_SLICE   = *DBIx::Squirrel::it::DEFAULT_SLICE;
    *DEFAULT_MAXROWS = *DBIx::Squirrel::it::DEFAULT_MAXROWS;
    *BUF_MULT        = *DBIx::Squirrel::it::BUF_MULT;
    *BUF_MAXROWS     = *DBIx::Squirrel::it::BUF_MAXROWS;

    our @ISA                   = ('DBI');
    our $STRICT_PARAM_CHECKING = 0;
    our $AUTO_FINISH_ON_ACTIVE = 1;
    our $NORMALISE_SQL         = 1;
    *NORMALIZE_SQL = *NORMALISE_SQL;
}

sub import {
    my $class  = shift;
    my $caller = caller;

    my ( @helpers, @dbi_imports );
    while (@_) {
        if ( $_[0] =~ m/^database_objects?$/i ) {
            shift;

            if (@_) {
                if ( defined $_[0] ) {
                    if ( ref $_[0] ) {
                        if ( reftype( $_[0] ) eq 'ARRAY' ) {
                            push @helpers, @{ +shift };
                        }
                    } else {
                        push @helpers, shift;
                    }
                }
            }
        } else {
            push @dbi_imports, shift;
        }
    }

    my %seen;
    @helpers = grep { !$seen{$_}++ } @helpers;

    for my $name (@helpers) {
        my $symbol = $class . '::' . $name;
        my $helper = sub {

            # First time the helper receives a value then it is assumed to be
            # the reference to the associated database object.

            unless ( defined ${$symbol} ) {
                if (@_) {
                    if (   UNIVERSAL::isa( $_[0], 'DBI::db' )
                        or UNIVERSAL::isa( $_[0], 'DBI::st' )
                        or UNIVERSAL::isa( $_[0], 'DBIx::Squirrel::it' ) )
                    {
                        ${$symbol} = shift;
                        return ${$symbol};
                    }

                    throw E_BAD_ENT_BIND;
                }
            }

            # At this point, return nothing if no association is defined.

            return unless defined ${$symbol};


            # At this point, we have an association. If we have arguments then
            # we are addressing the associated database object, and they are
            # passed to the object's relevant method for processing.

            if (@_) {
                my @params = do {
                    if ( @_ == 1 && ref $_[0] ) {
                        if ( reftype( $_[0] ) eq 'ARRAY' ) {
                            @{ +shift };
                        } elsif ( reftype( $_[0] ) eq 'HASH' ) {
                            %{ +shift };
                        } else {
                            throw E_EXP_HASH_ARR_REF;
                        }
                    } else {
                        @_;
                    }
                };

                if ( UNIVERSAL::isa( ${$symbol}, 'DBI::db' ) ) {
                    return ${$symbol}->prepare(@params);
                } elsif ( UNIVERSAL::isa( ${$symbol}, 'DBI::st' ) ) {
                    return ${$symbol}->execute(@params);
                } elsif ( UNIVERSAL::isa( ${$symbol}, 'DBIx::Squirrel::it' ) ) {
                    return ${$symbol}->iterate(@params);
                }
            }

            # At this point, return the reference to the associated database
            # object.

            return ${$symbol};
        };

        *{$symbol} = subname( $name => $helper );

        # Export any relevant symbols to caller's namespace.

        unless ( defined &{ $caller . '::' . $name } ) {
            *{ $caller . '::' . $name } = \&{$symbol};
        }
    }

    # If the caller tried to import any of DBI's exports then take care
    # of that, otherwise just return our class name.

    if (@dbi_imports) {

        # First import them here.

        DBI->import(@dbi_imports);

        # Then export them to the caller!

        @_ = ( 'DBIx::Squirrel', @dbi_imports );
        goto &Exporter::import;
    } else {
        return $class;
    }
}

1;
__END__

=pod

=encoding UTF-8

=head1 DESCRIPTION

The C<DBIx::Squirrel> package extends the C<DBI>, by providing a few extra
conveniences that are subtle and additive in nature, and, hopefully, quite
useful.

=head2 Importing the package

In the simplest case, just import the package as you would any other:

    use DBIx::Squirrel;

Any symbols and tags that you would typically import from the C<DBI> can
also be requested via C<DBIx::Squirrel>:

    use DBIx::Squirrel DBI-IMPORT-LIST;

If required (and in addition to any C<DBI> imports), C<DBIx::Squirrel> can
create and import Database Object Helper functions for you:

    use DBIx::Squirrel database_object=>NAME;
    use DBIx::Squirrel database_objects=>[NAMES];

=head3 Database Object Helper Functions

A database object helper is nothing more than a standard function providing
some syntactic sugar in the form of a polymorphic interface for interacting
with database entities such as database connections, statements and
iterators.

While it is not absolutely necessary to use themE<mdash>you could just as
easily use scalar referencesE<mdash>helper functions do possess the advantage
of being shared more easily among package namespaces than, say, lexical
variables.

Helper semantics deal with three common types of interaction:

=over

=item * B<Establishing an association>

Before it can be used, a helper must first be associated with a database
entity. This accomplished by passing the function single argument: a
reference to the associated object.

Once established, associations are I<sticky> and cannot easily be undone.
You should take care to create them once only, in a sensible place.

Use Perl's standard importing mechanisms (as shown above) to share
associations among different package namespaces.

=item * B<Resolving an association>

Fetching the reference to the associated database object is accomplished
by calling the helper function without any arguments.

When no association exists in this scenario, a helper returns C<undef>.

=item * B<Addressing an association>

Addressing an association amounts to doing something meaningful with it.

We do this by calling the helper function with one or more arguments. Once
associated with a database object, a helper function will any arguments
that are passed to it and send a version of these to the database object
method that imbues meaning to the interaction.

Meaning in this context is determined by the type of association:

=over

=item * 

for a database connection, a statement is prepared using the C<prepare> method;

=item *

for statements and iterators, these are executed with the C<execute> and C<iterate>
methods respectively.

=back

Clearly there is a paradox here, and it centres around statements expect no
bind-values.

Optionally, you may enclose any arguments inside anonymous array or hash. In
order to coerce the helper into performing the execution, you are allowed to
pass an empty array reference (C<[]>) or hash reference (C<{}>), or resolve
the association and call the relevant method manually.

=back

=head4 Examples

=over

=item 1.

Let us do a full worked example. We will connect to a database, create and
work with two result sets, one of which expects a single bind-value. Some
concepts will be expanded upon later, but it might be helpful to dip a
toe in the water ahead of time:

    use DBIx::Squirrel database_objects => [ qw/db artists artist/ ];

    # Associate helper ("db") with our database connection:

    @connect_args = ( 'dbi:SQLite:dbname=chinook.db', '', '', { sqlite_unicode => 1 } );
    db( DBIx::Squirrel->connect(@connection_args) );

    # Resolve the database connection helper ("db"), using it to
    # associate helpers ("artist" and "artists") with different
    # result sets:

    artist( db->results('SELECT * FROM artists WHERE Name=? LIMIT 1') );
    artists( db->results('SELECT * FROM artists') );

    # Address the helper ("artist"), passing it a bind-value, to get
    # the ArtistId of the artist whose name is "Aerosmith".
    #
    # We could have called "next" to get the only matching record, but by
    # calling "single" (or "first") we can ensure that there are no warnings
    # about dangling active statements emitted when we disconnect from the
    # database.

    print artist('Aerosmith')->single->ArtistId, "\n";

    # Iterate over the "artists" result set, printing the Name-column for
    # each artist:

    while ( artists->next ) {
        print $_->Name, "\n";
    };


=back

=head2 Database connection

Connecting to a database using C<DBIx::Squirrel> works the same
way as it does when using the C<DBI> C<connect> and C<connect_cached>
methods. The C<DBIx::Squirrel> C<connect> method, however, can also
accept a database handle in place of a datasource name. The database
handle can even be a reference to a C<DBI> object. The original database
connection will be cloned as as C<DBIx::Squirrel> object.

=head2 Statement preparation

=over

=item *

Both C<prepare> and C<prepare_cached> methods continue to work as
as they do in the C<DBI>, though they will also accept a statement
handles in place of a statement strings. Again, this is useful when
the intention is to prepare a C<DBI> statement object and represent
it as a C<DBIx::Squirrel> statement object.

=item *

Statements may be prepared using any one of a number of parameter
placeholder styles, with support provided for named and a variety
of positional styles. Styles supported are C<:name>, C<?1>, C<$1>,
C<:1> and C<?>. Whether you prefer to use a particular style, or
you are converting queries to run on a different database engine,
any of these style will work regardless of the driver in use.

=back

=head2 Results processing

=over

=item *

A C<DBIx::Squirrel> statement can produce two kinds of iterator, to
provide for efficient processing of results. These are generated using
statement's C<iterate> and C<results> methods in place of C<execute>.

=item *

Iterators offer a declarative way to process results using callbacks
chains to transform results before they are returned to the caller.

=item *

Some DBIx-Squirrel iterator methods named C<all>, C<find>, C<first>,
C<next>, C<single> may already be familiar to C<DBIx::Class>
users, and they do similar jobs.

=back

=head1 COPYRIGHT AND LICENSE

The DBIx::Squirrel module is Copyright (c) 2020-2014 Iain Campbell.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl 5.10.0 README file.

=head1 SUPPORT / WARRANTY

DBIx::Squirrel is free Open Source software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=cut
