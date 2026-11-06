use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel;
use DBIx::Squirrel::Errors;
use DBIx::Squirrel::Context;
use DBIx::Squirrel::Gather ();
use DBIx::Squirrel::Iterator;
use DBIx::Squirrel::Result;
use DBIx::Squirrel::Results;
use DBIx::Squirrel::Pipeline;
use DBIx::Squirrel::Placeholders;
use DBIx::Squirrel::Stages::Flow ();
use DBIx::Squirrel::Stop         ();
use DBIx::Squirrel::Sugar        ();
use DBIx::Squirrel::Util;

# Imported functions are cleaned out of each package, so they can't be
# called as methods.
my %imported = (
    'DBIx::Squirrel'     => [qw(canonical croak is_hashref split_attrs)],
    'DBIx::Squirrel::db' => [
        qw(
            at_caller      canonical  croak       croakf      failed
            is_arrayref    is_coderef is_hashref  in_method   is_ref
            iterator_going max        shift_attrs split_attrs study_sql
            unwrap_values
        ),
    ],
    'DBIx::Squirrel::Errors'   => [qw(croak  is_ref)],
    'DBIx::Squirrel::Gather'   => [qw(croakf is_coderef)],
    'DBIx::Squirrel::Iterator' =>
        [qw(at_caller croakf is_coderef iterator_going split_stages weaken)],
    'DBIx::Squirrel::Pipeline'     => [qw(croak  croakf is_coderef is_ref)],
    'DBIx::Squirrel::Placeholders' => [qw(croakf uniq)],
    'DBIx::Squirrel::Result'       =>
        [qw(croakf install_sub is_name sha1_hex set_subname)],
    'DBIx::Squirrel::Results'      => [qw(at_caller croakf)],
    'DBIx::Squirrel::Stop'         => [qw(croak)],
    'DBIx::Squirrel::Stages::Flow' => [qw(croakf gather is_coderef)],
    'DBIx::Squirrel::Sugar'        => [
        qw(
            croakf     install_sub is_arrayref is_coderef
            is_hashref is_name     shift_attrs split_stages
        ),
    ],
    'DBIx::Squirrel::st'   => [qw(at_caller croakf is_hashref max unwrap_values)],
    'DBIx::Squirrel::Util' => [
        qw(croakf is_arrayref is_coderef is_hashref is_ref set_subname subname),
    ],
);

for my $pkg (sort keys %imported) {
    subtest $pkg => sub {
        ok !$pkg->can($_), "no $_" for @{ $imported{$pkg} };
    };
}

subtest 'what the packages need is kept' => sub {
    ok +DBIx::Squirrel::Gather->can('import'),       'Gather can export';
    ok +DBIx::Squirrel::Gather->can('gather'),       'and keeps gather';
    ok +DBIx::Squirrel::Placeholders->can('import'), 'Placeholders can export';
    ok +DBIx::Squirrel::Stop->can('import'),         'Stop can export';
    ok +DBIx::Squirrel::Stages::Flow->can('import'), 'Stages::Flow can export';
    ok +DBIx::Squirrel::Sugar->can('import'),        'Sugar can export';
    ok +DBIx::Squirrel::Sugar->can('database'),      'and keeps database';
    ok +DBIx::Squirrel::Util->can('import'),         'Util can export';

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
