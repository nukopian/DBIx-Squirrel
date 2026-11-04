use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel;
use DBIx::Squirrel::Errors;
use DBIx::Squirrel::Context;
use DBIx::Squirrel::Iterator;
use DBIx::Squirrel::Pipeline;
use DBIx::Squirrel::Placeholders;
use DBIx::Squirrel::Stop ();

# Imported functions are cleaned out of each package, so they can't be
# called as methods.
my %imported = (
    'DBIx::Squirrel'     => [qw(croak is_hashref)],
    'DBIx::Squirrel::db' => [
        qw(
            at_caller  croak     failed is_arrayref is_coderef
            is_hashref in_method is_ref study_sql
        ),
    ],
    'DBIx::Squirrel::Pipeline'     => [qw(croak     is_coderef)],
    'DBIx::Squirrel::Placeholders' => [qw(croak     uniq)],
    'DBIx::Squirrel::st'           => [qw(at_caller croak is_arrayref is_hashref)],
    'DBIx::Squirrel::Errors'       => [qw(croak     is_ref)],
    'DBIx::Squirrel::Iterator'     => [qw(croak     is_coderef weaken)],
    'DBIx::Squirrel::Stop'         => [qw(croak)],
);

for my $pkg (sort keys %imported) {
    subtest $pkg => sub {
        ok !$pkg->can($_), "no $_" for @{ $imported{$pkg} };
    };
}

subtest 'what the packages need is kept' => sub {
    ok +DBIx::Squirrel::Placeholders->can('import'), 'Placeholders can export';
    ok +DBIx::Squirrel::Stop->can('import'),         'Stop can export';

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
