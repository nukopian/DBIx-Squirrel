use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBI;
use DBIx::Squirrel;

# Against a real MySQL server, named by a data source in the environment,
# such as "dbi:mysql:mysql_read_default_file=...;mysql_read_default_group=...",
# which can carry the user and password. Skipped without one.
my $source = $ENV{DBIX_SQUIRREL_TEST_MYSQL}
    or skip_all 'set DBIX_SQUIRREL_TEST_MYSQL to a MySQL data source';
eval { require DBD::mysql; 1 }
    or skip_all 'DBD::mysql is not installed';

my @attrs = (undef, undef, {RaiseError => 1, PrintError => 0});
my $dbh   = DBIx::Squirrel->connect($source, @attrs);
my $dbi   = DBI->connect($source, @attrs);

# The row a statement returns, executed with the values given.
sub row ($statement, @values) {
    my $sth = $dbh->prepare($statement);
    $sth->execute(@values);
    return $sth->fetchrow_arrayref;
}

subtest "a statement is read by MySQL's rules" => sub {
    is row(q{SELECT 'it\'s :no', :x}, x => 'y'), [q{it's :no}, 'y'],
        'a backslash escapes a quote';
    is row(q{SELECT "a :no", :x}, x => 'y'), ['a :no', 'y'],
        '"..." is a string';
    is row("SELECT :x # :no\n", x => 'y'), ['y'], '# starts a comment';
};

subtest 'placeholders' => sub {
    is row('SELECT $1 + $1, $2', 2, 3), [4, 3], 'numbered, used twice';
    is row('SELECT :a, :b', b => 2, a => 1), [1, 2], 'named';
    is row('SELECT ?, ?',   [1, 2]),         [1, 2], 'an array reference of values';
};

subtest 'the same results as the DBI' => sub {
    my $sql = q{SELECT 'it\'s', ?, ? + 1};
    is [$dbh->selectrow_array($sql, undef, 1, 2)],
        [$dbi->selectrow_array($sql, undef, 1, 2)], 'selectrow_array';
};

subtest "the DBI's messages" => sub {
    my sub message ($h) {
        my $error = dies { $h->do('SELEC 1') };
        return $error =~ s( \ at \ \S+ \ line \ \d+ \. \n \z )()xr;
    }
    is message($dbh), message($dbi), 'do';
};

done_testing;
