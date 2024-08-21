#!perl
use Modern::Perl;
use Carp qw/croak/;
use Test::More;

BEGIN {
    use_ok('DBIx::Squirrel', database_entity => 'db', database_entities => [qw/st it rs/]) || print "Bail out!\n";
    use_ok('Test::DBIx::Squirrel')                                                         || print "Bail out!\n";
}

diag("Testing DBIx::Squirrel $DBIx::Squirrel::VERSION, Perl $], $^X");

subtest 'clone connection to mock database' => sub {
    my $dbh = DBIx::Squirrel->connect(@MOCK_DB_CONNECT_ARGS)
      or croak "Cannot create handle: $DBIx::Squirrel::errstr";
    my $clone = DBIx::Squirrel->connect($dbh)
      or croak "Cannot create handle: $DBIx::Squirrel::errstr";
    isa_ok($dbh, 'DBIx::Squirrel::db');
    isa_ok($dbh->prepare('SELECT 1'), 'DBIx::Squirrel::st');
    isa_ok($clone, 'DBIx::Squirrel::db');
    isa_ok($clone->prepare('SELECT 1'), 'DBIx::Squirrel::st');
    $clone->disconnect();
    $dbh->disconnect();
};

subtest 'clone connection to test database' => sub {
    my $dbh = DBIx::Squirrel->connect(@TEST_DB_CONNECT_ARGS)
      or croak "Cannot create handle: $DBIx::Squirrel::errstr";
    my $clone = DBIx::Squirrel->connect($dbh)
      or croak "Cannot create handle: $DBIx::Squirrel::errstr";
    isa_ok($dbh, 'DBIx::Squirrel::db');
    isa_ok($dbh->prepare('SELECT 1'), 'DBIx::Squirrel::st');
    isa_ok($clone, 'DBIx::Squirrel::db');
    isa_ok($clone->prepare('SELECT 1'), 'DBIx::Squirrel::st');
    $clone->disconnect();
    $dbh->disconnect();
};

subtest 'clone connection created by DBI to mock database' => sub {
    my $dbh = DBI->connect(@MOCK_DB_CONNECT_ARGS)
      or croak "Cannot create handle: $DBI::errstr";
    my $clone = DBIx::Squirrel->connect($dbh)
      or croak "Cannot create handle: $DBIx::Squirrel::errstr";
    isa_ok($dbh, 'DBI::db');
    isa_ok($dbh->prepare('SELECT 1'), 'DBI::st');
    isa_ok($clone, 'DBIx::Squirrel::db');
    isa_ok($clone->prepare('SELECT 1'), 'DBIx::Squirrel::st');
    $clone->disconnect();
    $dbh->disconnect();
};

subtest 'clone connection created by DBI to test database' => sub {
    my $dbh = DBI->connect(@TEST_DB_CONNECT_ARGS)
      or croak "Cannot create handle: $DBI::errstr";
    my $clone = DBIx::Squirrel->connect($dbh)
      or croak "Cannot create handle: $DBIx::Squirrel::errstr";
    isa_ok($dbh, 'DBI::db');
    isa_ok($dbh->prepare('SELECT 1'), 'DBI::st');
    isa_ok($clone, 'DBIx::Squirrel::db');
    isa_ok($clone->prepare('SELECT 1'), 'DBIx::Squirrel::st');
    $clone->disconnect();
    $dbh->disconnect();
};

done_testing();
