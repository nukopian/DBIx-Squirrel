use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBI;
use DBIx::Squirrel;

my @source = (
    'dbi:SQLite:dbname=:memory:', '', '',
    {RaiseError => 1, PrintError => 0},
);

# A database handle of each kind, each with the same table and rows.
sub connect_both {
    my %dbh = (
        dbi      => DBI->connect(@source),
        squirrel => DBIx::Squirrel->connect(@source),
    );
    for my $dbh (values %dbh) {
        $dbh->do('CREATE TABLE artist (id INTEGER, name TEXT)');
        $dbh->do('INSERT INTO artist VALUES (1, ?), (2, ?)', undef, 'AC/DC', 'Accept');
    }
    return \%dbh;
}

subtest 'prepare rewrites each placeholder style as ?' => sub {
    my $dbh = connect_both()->{squirrel};
    for my $p (qw(? ?1 :1 $1 :id)) {
        my $sth = $dbh->prepare("SELECT name FROM artist WHERE id = $p");
        isa_ok $sth, ['DBIx::Squirrel::st'], "$p: a statement handle";
        is $sth->{Statement}, 'SELECT name FROM artist WHERE id = ?',
            "$p: the DBI sees ?";
        $sth->execute($p eq ':id' ? (id => 2) : 2);
        is $sth->fetchrow_arrayref, ['Accept'], "$p: binds the value";
    }
};

subtest 'the statement handle keeps what was studied' => sub {
    my $dbh = connect_both()->{squirrel};
    my $sth = $dbh->prepare(" SELECT :a, :b -- two\n ");
    like $sth->{private_ekorn}, {
        Placeholders      => {1 => ':a', 2 => ':b'},
        OriginalStatement => 'SELECT :a, :b -- two',
        Options           => {ekorn_dialect => 'SQLite'},
        },
        'placeholders, the original statement, and the options';
};

subtest 'the forms a statement can take' => sub {
    my $dbh  = connect_both()->{squirrel};
    my $want = 'SELECT name FROM artist WHERE id = ?';
    is $dbh->prepare(['SELECT name', 'FROM artist', 'WHERE id = :id'])
        ->{Statement}, $want, 'lines in an array reference';
    is $dbh->prepare(sub { 'SELECT name FROM artist WHERE id = $1' })
        ->{Statement}, $want, 'a code reference returning a string';
    is $dbh->prepare(sub { ['SELECT name FROM artist', 'WHERE id = ?'] })
        ->{Statement}, $want, 'a code reference returning lines';

    my $sth = $dbh->prepare('SELECT name FROM artist WHERE id = :id');
    is $dbh->prepare($sth)->{private_ekorn}{OriginalStatement},
        'SELECT name FROM artist WHERE id = :id',
        "a DBIx::Squirrel statement handle's original statement";
    my $dbi_sth = DBI->connect(@source)->prepare('SELECT 1');
    is $dbh->prepare($dbi_sth)->{Statement}, 'SELECT 1',
        "a DBI statement handle's statement";
};

subtest 'prepare croaks at the caller' => sub {
    my $dbh  = connect_both()->{squirrel};
    my $line = __LINE__ + 2;
    for my $bad ('', " \n\t", undef, {}, \'SELECT 1') {
        is dies { $dbh->prepare($bad) },
            "Expected a statement at ${\__FILE__} line $line.\n",
            'Expected a statement';
    }
};

subtest 'a statement of only a comment goes to the database' => sub {
    my $dbh = connect_both();
    for my $kind (sort keys %$dbh) {
        my $sth = $dbh->{$kind}->prepare(" -- nothing\n");
        ok $sth->execute, "$kind: executes";
        is $sth->{NUM_OF_FIELDS}, 0, "$kind: with no columns";
    }
};

subtest 'prepare croaks at the caller on mixed placeholder styles' => sub {
    my $dbh  = connect_both()->{squirrel};
    my $line = __LINE__ + 1;
    my $err  = dies { $dbh->prepare('SELECT ?, :x') };
    is $err,
        "Expected one placeholder style, not several (?, :name)"
        . " at ${\__FILE__} line $line.\n",
        'Expected one placeholder style';
};

subtest 'prepare croaks without RaiseError' => sub {
    my $dbh = DBIx::Squirrel->connect(
        'dbi:SQLite:dbname=:memory:', '', '',
        {RaiseError => 0, PrintError => 0},
    );
    like dies { $dbh->prepare('SELEC 1') }, qr/syntax error/, 'a bad statement';
};

subtest 'prepare_cached' => sub {
    my $dbh = connect_both()->{squirrel};
    my @sth = map { $dbh->prepare_cached('SELECT :x') } 1 .. 2;
    ref_is $sth[0], $sth[1], 'caches the statement handle';
    isa_ok $sth[0], ['DBIx::Squirrel::st'], 'a statement handle';
    is $sth[0]{private_ekorn}{Placeholders}, {1 => ':x'},
        'keeps what was studied';
};

subtest 'do gives the same result as the DBI' => sub {
    my $dbh = connect_both();
    for my $kind (sort keys %$dbh) {
        my $h = $dbh->{$kind};
        is $h->do('UPDATE artist SET name = name'), 2, "$kind: no binds";
        is $h->do('UPDATE artist SET name = ? WHERE id = ?', undef, 'x', 1),
            1, "$kind: undef attributes";
        is $h->do('UPDATE artist SET name = ? WHERE id = ?', {}, 'y', 1),
            1, "$kind: a hash of attributes";
        is $h->do('DELETE FROM artist WHERE id = 99'), '0E0',
            "$kind: no rows";
        is [$h->do('UPDATE artist SET name = name')], [2],
            "$kind: one value in list context";
    }
};

subtest 'do takes bind values without attributes' => sub {
    my $dbh = connect_both()->{squirrel};
    is $dbh->do('UPDATE artist SET name = :name WHERE id = :id', name => 'z',
        id => 2),
        1, 'rows affected';
    is $dbh->selectrow_array(
        'SELECT name FROM artist WHERE id = $1',
        undef, 2,
        ),
        'z', 'and the row changed';
};

subtest 'do croaks on a reference other than a HASH or ARRAY' => sub {
    my $dbh  = connect_both()->{squirrel};
    my $code = sub { 1 };
    my $line = __LINE__ + 1;
    my $err  = dies { $dbh->do('SELECT ?', $code) };
    is $err,
        "Expected a reference to a HASH or ARRAY at ${\__FILE__} line $line.\n",
        'a code reference';
};

subtest "prepare reads a statement by its driver's rules" => sub {
    my $dbh = connect_both()->{squirrel};
    my $sth = $dbh->prepare(q{SELECT 'C:\', :x});
    $sth->execute(x => 'y');
    is $sth->fetchrow_arrayref, ['C:\\', 'y'],
        "SQLite: a backslash doesn't escape the quote";

    # No MySQL server here, so give _study a handle naming its driver.
    my $mysql = {Driver => {Name => 'mysql'}};
    my($normalised, $state)
        = DBIx::Squirrel::db::_study($mysql, q{SELECT 'it\'s :no', :x}, undef);    ## no critic (Subroutines::ProtectPrivateSubs)
    is $normalised, q{SELECT 'it\'s :no', ?}, 'MySQL: it does';
    is $state->{Placeholders}, {1 => ':x'}, 'MySQL: one placeholder';
};

## no critic (Subroutines::ProtectPrivateSubs)
# No PostgreSQL or MySQL server here, so give _study handles naming their
# drivers.
subtest 'the options a statement is studied with' => sub {
    my $sql         = q{SELECT :x, :y};
    my $pg          = {Driver => {Name => 'Pg'}, pg_placeholder_dollaronly => 1};
    my($normalised) = DBIx::Squirrel::db::_study($pg, $sql, undef);
    is $normalised, $sql, "DBD::Pg's options are read from the handle";
    ($normalised) = DBIx::Squirrel::db::_study(
        $pg, $sql,
        {pg_placeholder_dollaronly => 0},
    );
    is $normalised, 'SELECT ?, ?', "and prepare's attributes override them";

    my $sqlite = {Driver => {Name => 'SQLite'}, pg_placeholder_dollaronly => 1};
    ($normalised) = DBIx::Squirrel::db::_study($sqlite, $sql, undef);
    is $normalised, 'SELECT ?, ?', "they're not read from another driver";

    my($state, $dbi_attrs);
    ($normalised, $state, $dbi_attrs) = DBIx::Squirrel::db::_study(
        $sqlite, q{SELECT 'it\'s :no', :x},
        {ekorn_dialect => 'mysql', RaiseError => 1},
    );
    is $normalised, q{SELECT 'it\'s :no', ?},
        'ekorn_dialect overrides the driver, as for MySQL through ODBC';
    is $dbi_attrs, {RaiseError => 1}, "and doesn't reach the DBI";
    is +(DBIx::Squirrel::db::_study($sqlite, $sql, undef))[2], undef,
        'no attributes in, none out';
};
## use critic

subtest 'prepare takes ekorn_ attributes' => sub {
    my $dbh = connect_both()->{squirrel};
    my $sth = $dbh->prepare('SELECT :x', {ekorn_dialect => 'SQLite'});
    $sth->execute(x => 1);
    is $sth->fetchrow_arrayref, [1], 'and prepares the statement';
};

subtest 'connect takes ekorn_ attributes as defaults' => sub {
    my $dbh = DBIx::Squirrel->connect(
        @source[0 .. 2], {
            %{ $source[3] }, ekorn_dialect => 'mysql',
        },
    );
    is $dbh->{private_ekorn}, {Options => {ekorn_dialect => 'mysql'}},
        'kept in the private_ekorn attribute';
    is $dbh->{ekorn_dialect}, undef, 'not passed on to the DBI';

    my($normalised) = DBIx::Squirrel::db::_study(
        $dbh, q{SELECT 'it\'s :no', :x}, undef,
    );
    is $normalised, q{SELECT 'it\'s :no', ?}, 'statements are read by them';
    is $dbh->prepare('SELECT :x')->{private_ekorn}{Options}{ekorn_dialect},
        'mysql', 'and keep them';
    is $dbh->prepare('SELECT :x', {ekorn_dialect => 'SQLite'})
        ->{private_ekorn}{Options}{ekorn_dialect},
        'SQLite', "prepare's attributes override them";

    is DBIx::Squirrel->connect($dbh)->{private_ekorn},
        {Options => {ekorn_dialect => 'mysql'}}, 'a clone keeps them';
    is DBIx::Squirrel->connect($dbh, {ekorn_dialect => 'Pg'})->{private_ekorn},
        {Options => {ekorn_dialect => 'Pg'}}, 'unless given others';
    is $dbh->{private_ekorn}, {Options => {ekorn_dialect => 'mysql'}},
        "and the first handle's are unchanged";

    is DBIx::Squirrel->connect(@source)->{private_ekorn},
        {Options => {ekorn_dialect => 'SQLite'}},
        "a handle without them is given its driver's dialect";
    is DBIx::Squirrel->connect(@source)->prepare('SELECT :x')
        ->{private_ekorn}{Options}{ekorn_dialect},
        'SQLite', "and statements are read by the driver's rules";
};

# A database handle, standing in for one whose driver passes the
# connection on to another database, and says what it is, or doesn't.
package Stand::In {
    sub get_info ($self, $type) { $type == 17 ? $self->{dbms} : undef }
}


sub stand_in ($driver, $dbms = undef) {
    return bless {Driver => {Name => $driver}, dbms => $dbms}, 'Stand::In';
}

subtest 'connect discerns the dialect' => sub {
    my $dialect = \&DBIx::Squirrel::_dialect;
    is $dialect->(stand_in('mysql', 'PostgreSQL')), 'mysql',
        "a driver's own name, without asking the database";
    is $dialect->(stand_in('ODBC',  'MySQL')),   'mysql',   'MySQL through ODBC';
    is $dialect->(stand_in('ODBC',  'MariaDB')), 'MariaDB', 'MariaDB';
    is $dialect->(stand_in('Proxy', 'PostgreSQL')), 'Pg',
        'PostgreSQL through Proxy';
    is $dialect->(stand_in('ODBC', 'Microsoft SQL Server')), 'ODBC',
        "a database with no rules of its own";
    is $dialect->(stand_in('ODBC')), 'ODBC', "a database that doesn't say";

    my $gofer = DBIx::Squirrel->connect(
        'dbi:Gofer:transport=null;dsn=dbi:SQLite:dbname=:memory:', '', '',
        $source[3],
    );
    is $gofer->{private_ekorn}{Options}{ekorn_dialect}, 'SQLite',
        'SQLite through Gofer, connected';
    is $gofer->{RaiseError}, T(), 'leaving RaiseError as it was';
};

subtest 'do binds an array reference of values' => sub {
    my $dbh = connect_both()->{squirrel};
    is $dbh->do('UPDATE artist SET name = ? WHERE id = ?', ['w', 1]), 1,
        'with ? placeholders';
    is $dbh->do('UPDATE artist SET name = $1 WHERE id = $2', ['x', 1]), 1,
        'and numbered ones';
    is $dbh->selectrow_array('SELECT name FROM artist WHERE id = 1'), 'x',
        'binding each value to its own placeholder';
};

subtest 'prepare_cached keeps statements rewritten the same apart' => sub {
    my $dbh = connect_both()->{squirrel};
    my $ab  = $dbh->prepare_cached('SELECT :a, :b');
    my $ba  = $dbh->prepare_cached('SELECT :b, :a');
    ok $ab != $ba, 'giving each its own handle';
    is $ab->{private_ekorn}{Placeholders}, {1 => ':a', 2 => ':b'},
        'the first keeps its placeholders';
    is $ba->{private_ekorn}{Placeholders}, {1 => ':b', 2 => ':a'},
        'and so does the second';
    $ab->execute(a => 1, b => 2);
    is $ab->fetchrow_arrayref, [1, 2], 'each binding by its own names';
    $ba->execute(a => 1, b => 2);
    is $ba->fetchrow_arrayref, [2, 1], 'in its own order';
    $_->finish for $ab, $ba;
    ref_is $dbh->prepare_cached('SELECT :b, :a'), $ba,
        'and the same statement still gets the cached handle';
};

done_testing;
