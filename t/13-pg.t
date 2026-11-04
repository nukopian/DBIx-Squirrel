use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBI;
use DBIx::Squirrel;

# Against a real PostgreSQL server, named by a data source in the
# environment, such as "dbi:Pg:dbname=test;host=localhost;user=test".
# Skipped without one.
my $source = $ENV{DBIX_SQUIRREL_TEST_PG}
    or skip_all 'set DBIX_SQUIRREL_TEST_PG to a PostgreSQL data source';
eval { require DBD::Pg; 1 }
    or skip_all 'DBD::Pg is not installed';

my @attrs = (undef, undef, {RaiseError => 1, PrintError => 0});
my $dbh   = DBIx::Squirrel->connect($source, @attrs);
my $dbi   = DBI->connect($source, @attrs);

# The row a statement returns, prepared with the attributes given and
# executed with the values.
sub row ($statement, $attrs, @values) {
    my $sth = $dbh->prepare($statement, $attrs);
    $sth->execute(@values);
    return $sth->fetchrow_arrayref;
}

subtest 'placeholders' => sub {
    is row('SELECT $1::int + $1::int, $2::int', undef, 2, 3), [4, 3],
        'numbered, used twice';
    is row('SELECT :a::int, :b::int', undef, b => 2, a => 1), [1, 2], 'named';
    is row(q{SELECT '{"k": 1}'::jsonb \? 'k', :x::text}, undef, x => 'y'),
        [T(), 'y'], 'a backslash before ?, for the jsonb operator';
};

subtest "DBD::Pg's placeholder options" => sub {
    my $dollar = {pg_placeholder_dollaronly => 1};
    is row('SELECT $1::int + $1::int', $dollar, 2), [4],
        'pg_placeholder_dollaronly, with $1 used twice, for DBD::Pg to bind';
    is row(q{SELECT '{"k": 1}'::jsonb ? 'k', $1::text}, $dollar, 'y'),
        [T(), 'y'], 'and ? as an operator';

    my $colons = {pg_placeholder_nocolons => 1};
    is row('SELECT (ARRAY[1, 2, 3])[2:3], ?::int', $colons, 4),
        [[2, 3], 4], 'pg_placeholder_nocolons, with an array slice';

    my $other = DBIx::Squirrel->connect(
        $source, undef, undef,
        {%{ $attrs[2] }, pg_placeholder_dollaronly => 1},
    );
    my $sth = $other->prepare('SELECT $1::int + $1::int');
    $sth->execute(2);
    is $sth->fetchrow_arrayref, [4], 'read from the database handle';
};

subtest 'an array reference' => sub {
    is row('SELECT 2 = ANY(?::int[])', undef, [1, 2]), [T()],
        'is one PostgreSQL array, to a statement taking one value';
    is row('SELECT ?::int, ?::int', undef, [1, 2]), [1, 2],
        'and stands for its values, to one taking two';
    is row('SELECT 3 = ANY($1::int[])', undef, [[1, 2]]), [F()],
        'or inside another, to a numbered placeholder';
};

subtest 'the same results as the DBI' => sub {
    my $sql = 'SELECT 2 = ANY(?::int[]), ?::int';
    is [$dbh->selectrow_array($sql, undef, [1, 2], 3)],
        [$dbi->selectrow_array($sql, undef, [1, 2], 3)], 'selectrow_array';
    is [$dbh->selectrow_array('SELECT 2 = ANY(?::int[])', undef, [1, 2])],
        [$dbi->selectrow_array('SELECT 2 = ANY(?::int[])', undef, [1, 2])],
        'with an array reference alone';
};

subtest "the DBI's messages" => sub {
    my sub message ($h) {
        my $error = dies { $h->do('SELEC 1') };
        return $error =~ s( \ at \ \S+ \ line \ \d+ \. \n \z )()xr;
    }
    is message($dbh), message($dbi), 'do';
};

done_testing;
