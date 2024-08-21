#!perl
use Modern::Perl;
use Test::More;

BEGIN {
    use_ok('DBIx::Squirrel') || print "Bail out!\n";
}

diag("Testing DBIx::Squirrel $DBIx::Squirrel::VERSION, Perl $], $^X");
done_testing();
