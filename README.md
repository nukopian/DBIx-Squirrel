# NAME

DBIx::Squirrel - A module for working with databases

# VERSION

version 1.2.0

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

The `DBIx::Squirrel` package extends the `DBI`, offering a
few useful conveniences over and above what its venerable
ancestor already provides.

The enhancements provided by `DBIx::Squirrel` are subtle, and
they are additive in nature.

### Importing the package

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

DBI imports and database object helpers can be included in the same `use`
clause.

- Example:

        use DBIx::Squirrel database_objects=>['db', 'artists', 'artist'];

        # Associate the "db" helper with a database connection

        db DBIx::Squirrel->connect(
            'dbi:SQLite:dbname=chinook.db',
                    '',
                    '',
                    {
                      AutoCommit     => 0,
                      PrintError     => 0,
                      RaiseError     => 1,
                      sqlite_unicode => 1,
                    },
        );

        # Using the "db" association, associate the "artists" and "artist"
        # helpers with statements:

        artists db->prepare('SELECT * FROM artists');
        artist  db->prepare('SELECT * FROM artists WHERE Name=?');

        # Have the statement helpers to execute their queries.

        artists->execute
          or die 'Oops!';
        artist->execute('Eric Clapton')
          or die 'Oops!';

### Database connection

Connecting to a database using `DBIx::Squirrel` works the same
way as it does when using the `DBI` `connect` and `connect_cached`
methods. The `DBIx::Squirrel` `connect` method, however, can also
accept a database handle in place of a datasource name. The database
handle can even be a reference to a `DBI` object. The original database
connection will be cloned as as `DBIx::Squirrel` object.

### Statement preparation

- Both `prepare` and `prepare_cached` methods continue to work as
as they do in the `DBI`, though they will also accept a statement
handles in place of a statement strings. Again, this is useful when
the intention is to prepare a `DBI` statement object and represent
it as a `DBIx::Squirrel` statement object.
- Statements may be prepared using any one of a number of parameter
placeholder styles, with support provided for named and a variety
of positional styles. Styles supported are `:name`, `?1`, `$1`,
`:1` and `?`. Whether you prefer to use a particular style, or
you are converting queries to run on a different database engine,
any of these style will work regardless of the driver in use.

### Results processing

- A `DBIx::Squirrel` statement can produce two kinds of iterator, to
provide for efficient processing of results. These are generated using
statement's `iterate` and `results` methods in place of `execute`.
- Iterators offer a declarative way to process results using callbacks
chains to transform results before they are returned to the caller.
- Some DBIx-Squirrel iterator methods named `all`, `find`, `first`,
`next`, `single` may already be familiar to `DBIx::Class`
users, and they do similar jobs.

# COPYRIGHT AND LICENSE

The DBIx::Squirrel module is Copyright (c) 2020-2014 Iain Campbell.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl 5.10.0 README file.

# SUPPORT / WARRANTY

DBIx::Squirrel is free Open Source software. IT COMES WITHOUT WARRANTY OF ANY KIND.
