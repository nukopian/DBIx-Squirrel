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

        *{$symbol} = subname(
            $symbol => sub {
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

                return unless defined ${$symbol};

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

                return ${$symbol};
            }
        );

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

The C<DBIx::Squirrel> package extends the C<DBI>, offering a
few useful conveniences over and above what its venerable
ancestor already provides.

The enhancements provided by C<DBIx::Squirrel> are subtle, and
they are additive in nature.

=head2 Importing the package

Simply use the package as you would any other:

    use DBIx::Squirrel;

Any symbols and tags imported from the DBI can still be requested
via DBIx::Squirrel:

    use DBIx::Squirrel DBI-IMPORTS;

You can also have DBIx::Squirrel create and import database object helpers
during your script's compile-phase:

    use DBIx::Squirrel database_object=>NAME;
    use DBIx::Squirrel database_objects=>[NAMES];

Helpers serve simply as syntactic sugar, providing standardised polymorphic
functions that may be associated during runtime with connections, statements
and/or iterators, and then used to address the underlying objects.

DBI imports and database object helpers can be included in the same C<use>
clause.

=over

=item *

Example 1:

    use DBIx::Squirrel database_objects=>['db', 'artists', 'artist'];

    # Associate the "db" helper with a database connection

    @connection_args = ( 'dbi:SQLite:dbname=chinook.db', '', '', {
            AutoCommit     => 0,
            PrintError     => 0,
            RaiseError     => 1,
            sqlite_unicode => 1,
        },
    );

    db @connection_args;

    # Associate the "artists" and "artist" helpers with their result sets,
    # and then do something with the results:

    artists db->results('SELECT * FROM artists');
    artist  db->results('SELECT * FROM artists WHERE Name=? LIMIT 1');

    print $_->Name, "\n" while artists->next;

    print artist('Aerosmith')->single->ArtistId, "\n";

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
