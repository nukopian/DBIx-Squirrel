use 5.010_001;
use strict;
use warnings;
use open ':std', ':encoding(utf8)';
use Carp qw/croak/;
use Test::More;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

BEGIN {
    use_ok('DBIx::Squirrel')              || print "Bail out!\n";
    use_ok('T::Squirrel', qw/:var :func/) || print "Bail out!\n";
}

diag("Testing DBIx::Squirrel $DBIx::Squirrel::VERSION, Perl $], $^X");
note(' ');

{
    note('Mock database checks:');
    note(' ');
    notedump(\@MOCK_DB_CONNECT_ARGS);

    my $dbh = DBIx::Squirrel->connect(@MOCK_DB_CONNECT_ARGS);
    isa_ok($dbh, 'DBIx::Squirrel::db');

    my $clone = DBIx::Squirrel->connect($dbh);
    isa_ok($clone, 'DBIx::Squirrel::db');

    $clone->disconnect();
    $dbh->disconnect();

    $dbh   = DBI->connect(@MOCK_DB_CONNECT_ARGS);
    $clone = DBIx::Squirrel->connect($dbh);
    isa_ok($clone, 'DBIx::Squirrel::db');

    $clone->disconnect();
    $dbh->disconnect();
}

{
    note('Test database checks:');
    note(' ');
    notedump(\@TEST_DB_CONNECT_ARGS);

    my $dbh = DBIx::Squirrel->connect(@TEST_DB_CONNECT_ARGS);
    isa_ok($dbh, 'DBIx::Squirrel::db');

    my @tests = (
        {line => __LINE__, got => [$dbh->_private_state()],            exp => [{}, $dbh]},
        {line => __LINE__, got => [$dbh->_private_state({foo => 99})], exp => [$dbh]},
        {line => __LINE__, got => [$dbh->_private_state()],            exp => [{foo => 99}, $dbh]},
        {line => __LINE__, got => [$dbh->_private_state()->{foo}],     exp => [99]},
        {line => __LINE__, got => [$dbh->_private_state(foo => 77)],   exp => [$dbh]},
        {line => __LINE__, got => [$dbh->_private_state()],            exp => [{foo => 77}, $dbh]},
        {line => __LINE__, got => [$dbh->_private_state()->{foo}],     exp => [77]},
        {line => __LINE__, got => [$dbh->_private_state(undef)],       exp => [$dbh]},
    );
    foreach my $t (@tests) {
        is_deeply(
            UNIVERSAL::isa($t->{got}, 'CODE') ? $t->{got}->() : $t->{got},
            $t->{exp}, sprintf('A test at line %d%s', $t->{line}, $t->{name} ? " - $t->{name}" : ''),
        );
    }

    my $clone = DBIx::Squirrel->connect($dbh);
    isa_ok($clone, 'DBIx::Squirrel::db');

    $clone->disconnect();
    $dbh->disconnect();

    $dbh   = DBI->connect(@TEST_DB_CONNECT_ARGS);
    $clone = DBIx::Squirrel->connect($dbh);
    isa_ok($clone, 'DBIx::Squirrel::db');

    $clone->disconnect();
    $dbh->disconnect();
}

done_testing();
