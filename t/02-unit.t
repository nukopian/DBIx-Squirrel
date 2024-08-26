use 5.010_001;
use strict;
use warnings;
use open ':std', ':encoding(utf8)';
use Test::More;

BEGIN {
    use_ok('DBIx::Squirrel') || print "Bail out!\n";
    use_ok('DBIx::Squirrel::util', qw/part_args/) || print "Bail out!\n";
    use_ok('T::Squirrel',          qw/diagdump/)  || print "Bail out!\n";
}

my(@tests, $test, $count);
my $sub = sub {'DUMMY'};

diag("Testing DBIx::Squirrel $DBIx::Squirrel::VERSION, Perl $], $^X");

note('Testing &DBIx::Squirrel::util::part_args');

($count, @tests) = (
    __LINE__,
    {got => [part_args()],                            exp => [[]]},
    {got => [part_args(1)],                           exp => [[], 1]},
    {got => [part_args(1, 2)],                        exp => [[], 1, 2]},
    {got => [part_args(1, 2, 3)],                     exp => [[], 1, 2, 3]},
    {got => [part_args($sub)],                        exp => [[$sub]]},
    {got => [part_args($sub, $sub)],                  exp => [[$sub, $sub]]},
    {got => [part_args($sub, $sub, $sub)],            exp => [[$sub, $sub, $sub]]},
    {got => [part_args(1 => $sub)],                   exp => [[$sub], 1]},
    {got => [part_args(1, 2 => $sub)],                exp => [[$sub], 1, 2]},
    {got => [part_args(1, 2, 3 => $sub)],             exp => [[$sub], 1, 2, 3]},
    {got => [part_args(1, 2, 3 => $sub, $sub, $sub)], exp => [[$sub, $sub, $sub], 1, 2, 3]},
    {got => [part_args(1, $sub, 3 => $sub, $sub)],    exp => [[$sub, $sub], 1, $sub, 3]},
);

foreach $test (@tests) {
    is_deeply($test->{got}, $test->{exp}, sprintf('line %2d', ++$count));
}

done_testing();
