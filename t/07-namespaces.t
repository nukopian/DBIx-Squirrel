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
use DBIx::Squirrel::Stages::Batch ();
use DBIx::Squirrel::Stages::Flow  ();
use DBIx::Squirrel::Stages::Rows  ();
use DBIx::Squirrel::Stages::Taps  ();
use DBIx::Squirrel::Stop          ();
use DBIx::Squirrel::Sugar         ();
use DBIx::Squirrel::Util;

# Imported functions are cleaned out of each package, so they can't be
# called as methods.
my %imported = (
    'DBIx::Squirrel'     => [qw(canonical croak is_hashref split_attrs)],
    'DBIx::Squirrel::db' => [
        qw(
            all          at_caller     canonical      croak       croakf
            expand_lists failed        in_method      is_arrayref is_coderef
            is_hashref   is_ref        iterator_going key_of
            max          shift_attrs   split_attrs    split_stages
            study_sql    unwrap_values values_for     values_taken
        ),
    ],
    'DBIx::Squirrel::Errors'   => [qw(croak  is_ref)],
    'DBIx::Squirrel::Gather'   => [qw(croakf is_coderef)],
    'DBIx::Squirrel::Iterator' => [
        qw(
            at_caller      croakf       is_coderef is_plain_arrayref
            iterator_going split_stages weaken
        ),
    ],
    'DBIx::Squirrel::Pipeline'     => [qw(croak croakf is_coderef is_ref)],
    'DBIx::Squirrel::Placeholders' =>
        [qw(any croakf is_arrayref is_hashref is_plain_ref max uniq)],
    'DBIx::Squirrel::Result' =>
        [qw(croakf install_sub is_name sha1_hex set_subname)],
    'DBIx::Squirrel::Results'       => [qw(at_caller croakf)],
    'DBIx::Squirrel::Stages::Batch' => [qw(croakf    gather is_coderef)],
    'DBIx::Squirrel::Stages::Flow'  => [qw(croakf    gather is_coderef)],
    'DBIx::Squirrel::Stages::Rows'  =>
        [qw(croakf gather is_plain_arrayref is_plain_hashref)],
    'DBIx::Squirrel::Stages::Taps' =>
        [qw(croakf gather is_coderef is_plain_scalarref openhandle)],
    'DBIx::Squirrel::Stop'  => [qw(croak)],
    'DBIx::Squirrel::Sugar' => [
        qw(
            croakf     install_sub is_arrayref is_coderef
            is_hashref is_name     shift_attrs split_stages
        ),
    ],
    'DBIx::Squirrel::st' => [
        qw(
            at_caller croakf       is_arrayref   is_numbered key_of
            pairs     place_values unwrap_values values_for  values_taken
        ),
    ],
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
    my @stages = map { "DBIx::Squirrel::Stages::$_" } qw(Batch Flow Rows Taps);
    ok $_->can('import'),                       "$_ can export" for @stages;
    ok +DBIx::Squirrel::Stop->can('import'),    'Stop can export';
    ok +DBIx::Squirrel::Sugar->can('import'),   'Sugar can export';
    ok +DBIx::Squirrel::Sugar->can('database'), 'and keeps database';
    ok +DBIx::Squirrel::Util->can('import'),    'Util can export';

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

# The pipeline is Ekorn::Pipeline's, behind a facade of DBIx::Squirrel's
# names, which exports what Ekorn's modules export, whatever that becomes.
subtest 'the facades follow Ekorn::Pipeline' => sub {
    for my $name (qw(Gather Stop Stages::Batch Stages::Flow Stages::Taps)) {
        my($ours, $theirs) = ("DBIx::Squirrel::$name", "Ekorn::Pipeline::$name");
        no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)
        is \@{ "${ours}::$_" }, \@{ "${theirs}::$_" }, "$ours\'s \@$_"
            for qw(EXPORT EXPORT_OK);
        is \%{ "${ours}::EXPORT_TAGS" }, \%{ "${theirs}::EXPORT_TAGS" },
            "$ours\'s %EXPORT_TAGS";
        for my $function (@{ "${theirs}::EXPORT" }, @{ "${theirs}::EXPORT_OK" }) {
            ref_is $ours->can($function), $theirs->can($function),
                "$ours\'s $function is $theirs\'s";
        }
    }
    isa_ok 'DBIx::Squirrel::Pipeline', ['Ekorn::Pipeline'],        'Pipeline';
    isa_ok 'DBIx::Squirrel::Pipes',    ['Ekorn::Pipeline::Pipes'], 'Pipes';
    isa_ok 'DBIx::Squirrel::Stop',     ['Ekorn::Pipeline::Stop'],  'Stop';

    my $p = DBIx::Squirrel::Pipeline->new(sub { $_ * 2 });
    isa_ok $p, ['DBIx::Squirrel::Pipeline'], 'a pipeline made with it';
    is [$p->(1, 2)], [2, 4], 'which can be called';
};

done_testing;
