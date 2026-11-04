use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel;

# An in-memory SQLite database lasts as long as its handle, which
# connect_cached keeps, so each use of music sees the same one.
use DBIx::Squirrel::Sugar database => {
    music => [
        'dbi:SQLite:dbname=:memory:', '', '',
        {RaiseError => 1, PrintError => 0},
    ],
};

music 'CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT)';
music 'INSERT INTO artist (name) VALUES (?)', $_ for qw(Abba Blur Cream);

subtest 'defined on use' => sub {
    isa_ok music, ['DBIx::Squirrel::db'], 'music, called with nothing';
    ref_is music,             music, 'the same handle each time';
    ref_is database('music'), music, 'database gives it too';
    ok main->can('database'), 'database is imported';
};

subtest 'a statement, executed' => sub {
    my $sth = music 'SELECT name FROM artist WHERE id = ?', 2;
    isa_ok $sth, ['DBIx::Squirrel::st'], 'the statement handle';
    is $sth->fetchrow_arrayref, ['Blur'], 'executed with the bind values';
    $sth = music 'SELECT name FROM artist WHERE id = :id', id => 3;
    is $sth->fetchrow_arrayref, ['Cream'], 'in any placeholder style';
    is music('UPDATE artist SET name = name WHERE id <= ?', 2)->rows, 2,
        'and one that changes rows';
};

subtest 'through stages' => sub {
    my $sql = 'SELECT id, name FROM artist ORDER BY id';
    is [music $sql, sub ($row) { $row->[1] }], [qw(Abba Blur Cream)],
        'the results';
    is scalar(music $sql, sub ($row) { $row->[0] > 1 ? $row : () }), 2,
        'or how many in scalar context';
    is [music $sql, {ekorn_slice => {}}, sub ($row) { $row->{name} }],
        [qw(Abba Blur Cream)], 'with attributes';
    is [music 'SELECT name FROM artist WHERE id > ?', 1, sub { $_->[0] }],
        [qw(Blur Cream)], 'and bind values';
};

subtest 'a statement handle' => sub {
    my $sth = music->prepare('SELECT name FROM artist WHERE id = ?');
    ref_is music($sth, 1), $sth, 'executed itself';
    is $sth->fetchrow_arrayref,                   ['Abba'],  'with the bind values';
    is [music $sth, 3, sub ($row) { $row->[0] }], ['Cream'], 'or iterated';
};

subtest 'defined as the program runs' => sub {
    my $function = database(
        archive => 'dbi:SQLite:dbname=:memory:',
        '', '', {RaiseError => 1, PrintError => 0, ShowErrorStatement => 1},
    );
    ok main->can('archive'), 'gives the package its function';
    ref_is $function, \&archive, 'and returns it';
    isa_ok archive(), ['DBIx::Squirrel::db'], 'which gives the handle';
    ref_is_not archive(), music,
        'of its own database, as its attributes differ';
};

subtest 'connected when first used' => sub {
    my $source = 'dbi:SQLite:dbname=/nonexistent/directory/x.db';
    ok lives { database(nowhere => $source, '', '', {PrintError => 0}) },
        'not when defined';
    my $line = __LINE__ + 1;
    like dies { nowhere() },
        qr( \A DBIx::Squirrel\ connect\( .* \ at\ \Q${\ __FILE__ }\E\ line\ $line\. )xs,
        'croaking at the caller when it fails';
};

subtest 'defined with a handle' => sub {
    my $original = DBIx::Squirrel->connect(
        'dbi:SQLite:dbname=:memory:', '', '',
        {RaiseError => 1, PrintError => 0},
    );
    database(copy => $original);
    my $copy = copy();
    isa_ok $copy, ['DBIx::Squirrel::db'], 'a clone';
    ref_is_not $copy, $original, 'not the handle itself';
    ref_is copy(), $copy, 'kept';
};

# The error from using DBIx::Squirrel::Sugar with the arguments given.
sub use_error ($args) {
    return eval "use DBIx::Squirrel::Sugar $args; 1" ? undef : $@;    ## no critic (BuiltinFunctions::ProhibitStringyEval)
}

subtest 'mistakes' => sub {
    my $expected = 'Expected a database defined as unknown';
    my $line     = __LINE__ + 1;
    like dies { database('unknown') },
        qr( \A \Q$expected\E \ at\ \Q${\ __FILE__ }\E\ line\ $line\. )x,
        'a name not defined';
    my sub define ($name) {
        return database($name => 'dbi:SQLite:dbname=:memory:');
    }
    like dies { define('music') },
        qr( \A \QExpected a database defined once (music)\E )x,
        'a name defined twice';
    like dies { define('no good') },
        qr( \A \QExpected a name for a database (no good)\E )x,
        'a name no function can have';
    like dies { define('is') },
        qr( \A \QExpected no function of the name in main already (is)\E )x,
        'a function the package has';
    like use_error(q{'other'}), qr( \A \QExpected database, not other\E )x,
        'on use, anything else';
    like use_error(q{database => {x => 'y'}}),
        qr( \A \QExpected the arguments to connect to x in an ARRAY\E )x,
        'or a definition not in an array';
};

done_testing;
