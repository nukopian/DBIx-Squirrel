use 5.010_001;
use strict;
use warnings;

use Test::More;
#
# We use Test::More::UTF8 to enable UTF-8 on Test::Builder
# handles (failure_output, todo_output, and output) created
# by Test::More. Requires Test::Simple 1.302210+, and seems
# to eliminate the following error on some CPANTs builds:
#
# > Can't locate object method "e" via package "warnings"
#
use Test::More::UTF8;

BEGIN {
    use_ok('DBIx::Squirrel', database_entity => 'foo', database_entities => ['bar', 'baz']) || print "Bail out!\n";
}

diag("Testing DBIx::Squirrel $DBIx::Squirrel::VERSION, Perl $], $^X");

ok(defined(&foo),                  'import "database_entity"');
ok(defined(&bar) && defined(&baz), 'import "database_entities"');

done_testing();
