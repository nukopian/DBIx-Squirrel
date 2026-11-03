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
        $sth->execute(2);
        is $sth->fetchrow_arrayref, ['Accept'], "$p: binds by position";
    }
};

subtest 'the statement handle keeps what was studied' => sub {
    my $dbh = connect_both()->{squirrel};
    my $sth = $dbh->prepare(" SELECT :a, \$2 -- two\n ");
    is $sth->{private_ekorn}, {
        Placeholders      => {1 => ':a', 2 => '$2'},
        OriginalStatement => 'SELECT :a, $2 -- two',
        },
        'placeholders and the original statement';
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
    is $dbh->do('UPDATE artist SET name = :name WHERE id = :id', 'z', 2), 1,
        'rows affected';
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
    $sth->execute('y');
    is $sth->fetchrow_arrayref, ['C:\\', 'y'],
        "SQLite: a backslash doesn't escape the quote";

    # No MySQL server here, so give _study a handle naming its driver.
    my $mysql = {Driver => {Name => 'mysql'}};
    my($normalised, $state)
        = DBIx::Squirrel::db::_study($mysql, q{SELECT 'it\'s :no', :x});    ## no critic (Subroutines::ProtectPrivateSubs)
    is $normalised, q{SELECT 'it\'s :no', ?}, 'MySQL: it does';
    is $state->{Placeholders}, {1 => ':x'}, 'MySQL: one placeholder';
};

todo 'binding an array reference waits on DBIx::Squirrel::st' => sub {
    my $dbh = connect_both()->{squirrel};
    my $rv
        = eval { $dbh->do('UPDATE artist SET name = ? WHERE id = ?', ['w', 1]); };
    is $rv, 1, 'an array reference of bind values';
};

done_testing;
