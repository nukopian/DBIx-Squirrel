use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel;
use DBIx::Squirrel::Helpers;
use DBIx::Squirrel::Pipeline;
use DBIx::Squirrel::Stop ();

# Imported functions are cleaned out of each package, so they can't be
# called as methods.
my %imported = (
    'DBIx::Squirrel'     => [qw(croak is_hashref split_stages)],
    'DBIx::Squirrel::db' =>
        [qw(croak is_arrayref is_coderef is_hashref is_ref study_statement)],
    'DBIx::Squirrel::Helpers'  => [qw(is_coderef)],
    'DBIx::Squirrel::Pipeline' => [qw(croak is_coderef)],
    'DBIx::Squirrel::Stop'     => [qw(croak)],
);

for my $pkg (sort keys %imported) {
    subtest $pkg => sub {
        ok !$pkg->can($_), "no $_" for @{ $imported{$pkg} };
    };
}

subtest 'what the packages need is kept' => sub {
    ok +DBIx::Squirrel::Helpers->can('import'), 'Helpers can export';
    ok +DBIx::Squirrel::Stop->can('import'),    'Stop can export';

    my $p = DBIx::Squirrel::Pipeline->new(sub { $_ * 2 });
    is [$p->(1, 2)], [2, 4], 'a pipeline can be called';
    is '' . dies { DBIx::Squirrel::Stop->throw },
        "Stop used outside a pipeline\n",
        'a stop explains itself as a string';
};

subtest 'both handle classes inherit pipe and tap' => sub {
    for my $class (qw(DBIx::Squirrel::db DBIx::Squirrel::st)) {
        isa_ok $class, ['DBIx::Squirrel::Pipes'], $class;
        ref_is $class->can($_), DBIx::Squirrel::Pipes->can($_), "$class can $_"
            for qw(pipe tap);
    }
};

done_testing;
