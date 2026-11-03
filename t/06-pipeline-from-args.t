use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel::Pipeline;

my $s1 = sub { "$_-1" };
my $s2 = sub { "$_-2" };

subtest 'from_args splits the trailing code references off' => sub {
    my($p, @rest) = DBIx::Squirrel::Pipeline->from_args(1, undef, $s1, $s2);
    isa_ok $p, ['DBIx::Squirrel::Pipeline'], 'a pipeline';
    is [$p->('x')], ['x-1-2'],  'running them, in order';
    is \@rest,      [1, undef], 'the rest, in order';
};

subtest 'only the trailing ones' => sub {
    my($p, @rest) = DBIx::Squirrel::Pipeline->from_args($s1, 1, $s2);
    is [$p->('x')],   ['x-2'], 'the stage';
    is scalar(@rest), 2,       'the rest';
    ref_is $rest[0], $s1, 'a code reference before them stays in the rest';
};

subtest 'all stages, or none' => sub {
    my($p, @rest) = DBIx::Squirrel::Pipeline->from_args($s1, $s2);
    is [$p->('x')], ['x-1-2'], 'all stages';
    is \@rest,      [],        'no rest';

    ($p, @rest) = DBIx::Squirrel::Pipeline->from_args(1, 2);
    is [$p->('x')], ['x'],  'no stages: values pass through';
    is \@rest,      [1, 2], 'all rest';

    ($p, @rest) = DBIx::Squirrel::Pipeline->from_args;
    is [$p->('x')], ['x'], 'nothing at all';
    is \@rest,      [],    'and no rest';
};

subtest 'a subclass gets its own pipeline' => sub {

    package My::Pipeline {
        our @ISA = 'DBIx::Squirrel::Pipeline';
    }
    my($p) = My::Pipeline->from_args($s1);
    isa_ok $p, ['My::Pipeline'], 'a pipeline of the subclass';
};

done_testing;
