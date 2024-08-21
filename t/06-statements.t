#!perl
use Modern::Perl;
use Carp qw/croak/;
use Test::More;

BEGIN {
    use_ok('DBIx::Squirrel', database_entity => 'db', database_entities => [qw/st itor results/]) || print "Bail out!\n";
    use_ok('Test::DBIx::Squirrel')                                                                || print "Bail out!\n";
}

diag("Testing DBIx::Squirrel $DBIx::Squirrel::VERSION, Perl $], $^X");
done_testing();
