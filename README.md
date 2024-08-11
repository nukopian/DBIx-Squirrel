# NAME

DBIx::Squirrel - A module for working with databases

# VERSION

version 1.2.3

# SYNOPSIS

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

# DESCRIPTION

The `DBIx::Squirrel` package extends the `DBI`, by providing a few extra
conveniences that are subtle and additive in nature, and, hopefully, quite
useful.

## Importing the package

In the simplest case, just import the package as you would any other:

    use DBIx::Squirrel;

Any symbols and tags that you would typically import from the `DBI` can
also be requested via `DBIx::Squirrel`:

    use DBIx::Squirrel DBI-IMPORT-LIST;

If required (and in addition to any `DBI` imports), `DBIx::Squirrel` can
create and import Database Object Helper functions for you:

    use DBIx::Squirrel database_object=>NAME;
    use DBIx::Squirrel database_objects=>[NAMES];

### Database Object Helper Functions

A database object helper is nothing more than a standard function providing
some syntactic sugar in the form of a polymorphic interface for interacting
with database entities such as database connections, statements and
iterators.

While it is not absolutely necessary to use them—you could just as
easily use scalar references—helper functions do possess the advantage
of being shared more easily among package namespaces than, say, lexical
variables.

Helper semantics deal with three common types of interaction:

- **Establishing an association**

    Before it can be used, a helper must first be associated with a database
    entity. This is accomplished by passing the function single argument: a
    reference to the associated object.

    Once established, associations are _sticky_ and cannot easily be undone.
    You should take care to create them once only, in a sensible place.

    Use Perl's standard importing mechanisms (as shown above) to share
    associations among different package namespaces.

- **Resolving an association**

    Fetching the reference to the associated database object is accomplished
    by calling the helper function without any arguments.

    When no association exists in this scenario, a helper returns `undef`.

- **Addressing an association**

    Addressing an association amounts to doing something meaningful with it,
    and we accomplish this by calling the helper function with one or more
    arguments.

    Once associated with a database object, a helper function will any arguments
    that are passed to it and send a version of these to the database object
    method that imbues meaning to the interaction.

    Meaning in this context is determined by the type of association:

    - for a database connection, a statement is prepared using the `prepare` method;
    - for statements and iterators, these are executed with the `execute` and `iterate`
    methods respectively.

    **Clearly there is a paradox here**, which centres around those statements
    and iterators expecting _no bind-values_. In order to smooth-out this wrinkle,
    you can opt to enclose arguments inside an anonymous array or hash. When no
    bind-values are expected, you can coerce the helper into performing the
    execution by passing an empty array or hash reference. Alternatively, you
    could just resolve the association and call the relevant method manually.

#### Examples

- Let us do a full worked example. We will connect to a database, create and
work with two result sets, one of which expects a single bind-value. Some
concepts will be expanded upon and improved later, but it might be helpful
to dip a toe in the water ahead of time:

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
        # each artist. We don't need to trigger execution manually because
        # the "next" method will do that for us, if it is necessary.

        while ( artists->next ) {
            print $_->Name, "\n";
        };

## Connecting to databases

Connecting to a database using `DBIx::Squirrel` may be done exactly as it
would when using the `DBI`'s `connect_cached` and `connect` methods.

### Cloning database connections

The `connect` method implemented by the `DBIx::Squirrel` package offers
an alternative form:

    $new_dbh = DBIx::Squirrel->connect($original_dbh, \%attr);

This form clones another connection object and returns a brand object that
is blessed using the same class that invoked the `connect` method. Objects
being cloned are allowed to be those created by the `DBI` or any of its
subclasses, `DBIx::Squirrel` being one of those.

## Preparing statements

Preparing a statement using `DBIx::Squirrel` may be done exactly as
it would be done using the `DBI`'s `prepare_cached` and `prepare`
methods.

### Placeholders

A nice quality-of-life improvement offered by `DBIx::Squirrel`'s own
implementation of the `prepare_cached` and `prepare` methods is the
built-in support for different placeholder styles:

- named (`:name`);
- positional (`:number`, `$number`, `?number`);
- legacy (`?`)

Regardless of your `DBD` driver, or your preferred style, statements
will be normalised to the legacy placeholder (`?`) by the time they
are executed.

Use your preferred style, or the style that most helps your query to
be reasoned by others.

#### Examples

- Legacy placeholders (`?`):

        $sth = $dbh->prepare('SELECT * FROM artists WHERE Name=? LIMIT 1');

        # Any of the following value-binding styles will work:
        $res = $sth->execute('Aerosmith');
        $res = $sth->execute([ 'Aerosmith' ]);

- SQLite positional placeholders (`?number`):

        $sth = $dbh->prepare('SELECT * FROM artists WHERE Name=?1 LIMIT 1');

        # Any of the following value-binding styles will work:
        $res = $sth->execute('Aerosmith');
        $res = $sth->execute([ 'Aerosmith' ]);

- PostgreSQL positional placeholders (`$number`):

        $sth = $dbh->prepare('SELECT * FROM artists WHERE Name=$1 LIMIT 1');

        # Any of the following value-binding styles will work:
        $res = $sth->execute('Aerosmith');
        $res = $sth->execute([ 'Aerosmith' ]);

- Oracle positional placeholders (`:number`):

        $sth = $dbh->prepare('SELECT * FROM artists WHERE Name=:1 LIMIT 1');

        # Any of the following value-binding styles will work:
        $res = $sth->execute('Aerosmith');
        $res = $sth->execute([ 'Aerosmith' ]);

- Oracle named placeholders (`:number`):

        $sth = $dbh->prepare('SELECT * FROM artists WHERE Name=:Name LIMIT 1');

        # Any of the following value-binding styles will work:
        $res = $sth->execute( Name => 'Aerosmith' );
        $res = $sth->execute({ Name => 'Aerosmith' });
        $res = $sth->execute( ':Name' => 'Aerosmith' );
        $res = $sth->execute({ ':Name' => 'Aerosmith' });

## Iterators

(TO DO)

## Processing results

(TO DO)

# COPYRIGHT AND LICENSE

The DBIx::Squirrel module is Copyright (c) 2020-2014 Iain Campbell.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl 5.10.0 README file.

# SUPPORT / WARRANTY

DBIx::Squirrel is free Open Source software. IT COMES WITHOUT WARRANTY OF ANY KIND.
