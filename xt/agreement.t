use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# A statement's run gives the same results however it's read: by all,
# a row at a time by next, through a chain made with |, by a pipeline
# of the user's own reading the iterator, and by a sink given last.
# Each gives the same values, each with the same number and the row it
# was made from; or each dies with the same error. Each way runs a
# result set made fresh, and the iterator runs again after all and
# reset, as a
# stop or a death mustn't leave anything behind for the next run; and
# after every run, the statement is no longer active (roadmap
# 2026-0066's D1). Random stages from xt/lib/RandomPipelines.pm, copied
# from Ekorn-Pipeline (D2), with makers of ours: a statement run nested
# in a step, and stages reading the run's context. Each case is made
# from a seed of its own, printed with a failure:
# DBIX_SQUIRREL_AGREEMENT_CASE set to it runs that case alone.

use FindBin qw($Bin);
use lib "$Bin/lib";

use experimental qw(builtin);
use builtin      qw(blessed);

use DBIx::Squirrel;
use DBIx::Squirrel::Context qw(result_number result_original);
use DBIx::Squirrel::Gather;
use DBIx::Squirrel::Stages::Rows qw(as_hash pluck);
use Ekorn::Pipeline;
use Ekorn::Pipeline::Operators;
use Ekorn::Pipeline::Sinks qw(keep_all);
use RandomPipelines        qw(random_stages);

my $CASES = $ENV{DBIX_SQUIRREL_AGREEMENT_CASES} // 1000;
my $SEED  = $ENV{DBIX_SQUIRREL_AGREEMENT_SEED}  // 20260066;
my $ONE   = $ENV{DBIX_SQUIRREL_AGREEMENT_CASE};
srand $SEED;

my $dbh = DBIx::Squirrel->connect(
    'dbi:SQLite:dbname=:memory:', '', '',
    {RaiseError => 1, PrintError => 0},
);
$dbh->do('CREATE TABLE t (o INTEGER PRIMARY KEY, n INTEGER)');
my $SQL = 'SELECT n FROM t ORDER BY o';

# What the way being run did, in the order it came: each value reaching
# the end, with its number and original; and each value whose original
# it wasn't made from.
my(@log, @wrong);

# Whether a value must have an original: not in a case with pluck or
# as_hash, which can take a row out of a batch, whose original is none.
my $STRICT;


# The number a value stands for: a row's n, wherever the row is, as a
# row object, a hash from as_hash, or a number from pluck; and an array
# reference's size, as the generator asks of a batch. Nothing, as
# pluck or as_hash gives reading an empty batch, is 0, as the generator
# needs a whole number.
sub _number ($value) {
    return $value->n            if blessed $value;
    return _number($value->{n}) if ref $value eq 'HASH';
    return scalar @$value       if ref $value;
    return $value // 0;
}


# Return the rows' numbers in a value, however deep in array references.
sub _leaves ($value) {
    return map { _leaves($_) } @$value if ref $value eq 'ARRAY';
    return _number($value);
}


# A value, or a list of them, as text to compare.
sub _shown (@values) {
    return join ',', map {
             !defined $_        ? 'undef'
            : ref $_ eq 'ARRAY' ? '[' . _shown(@$_) . ']'
            : ref $_ eq 'HASH'  ? '{' . _shown($_->{n}) . '}'
            : blessed $_        ? 'r' . $_->n
            : $_
    } @values;
}


# Whether a value was made from its original, the row result_original
# gives. A case's rows all differ, so a row, its hash or its plucked
# number stands for its own row, and an array reference holding any
# was made from its original only if the original is one of them: a
# stage that holds values back mustn't give another row's. An array
# reference may have none, as a batch has, and one holding no rows has
# nothing to tell.
sub _made_from ($value, $original) {
    return 1 if !defined $original && !$STRICT;
    my $row = defined $original ? $original->n : undef;
    return defined $row && _number($value) == $row if ref $value ne 'ARRAY';
    my @leaves = _leaves($value);
    return !defined $row || !@leaves || grep { $_ == $row } @leaves;
}

# Makers of ours, among the generator's: a statement run nested in a
# step, with random stages of its own, which mustn't change the outer
# run's original; and pluck and as_hash, which read the run's context.
my @makers = (
    {
        nests => 1,
        make  => sub ($settings) {
            my($stages, $names) = $settings->{inner}->();
            my $nested = sub ($value) {
                $dbh->results($SQL, @$stages)->all;
                return $value;
            };
            ($nested, 'a statement run in a step, of (' . join(', ', @$names) . ')');
        },
    },
    {make => sub ($settings) { (pluck('n'), "pluck('n')") }},
    {make => sub ($settings) { (as_hash,    'as_hash') }},
);

# The last stage of each case, noting what reaches it.
my $note = sub ($value) {
    my $original = result_original;
    my $shown
        = '#' . result_number . ' ' . _shown($value) . ':' . _shown($original);
    push @log,   $shown;
    push @wrong, $shown unless _made_from($value, $original);
    return $value;
};


# Return a case made from a seed: its stages, the rows' numbers, and
# what it is, for a failure's message. The same seed makes the same
# case, fresh.
sub make_case ($seed) {
    srand $seed;
    my($stages, $names) = random_stages(number => \&_number, makers => \@makers);
    my @all  = 0 .. 9;
    my @rows = map { splice @all, rand @all, 1 } 1 .. int rand 8;
    $STRICT = !grep { m( pluck | as_hash )x } @$names;
    return ([@$stages, $note], \@rows, join(', ', @$names));
}

# Each way reads the statement through the stages, returning what it
# gave, and the statement handles it ran, to check each has finished.
my %ways = (
    all => sub ($stages) {
        my $it = $dbh->results($SQL, @$stages);
        return ([$it->all], $it->sth);
    },
    again => sub ($stages) {
        my $it = $dbh->results($SQL, @$stages);
        # After all, an iterator gives nothing until reset.
        eval { $it->all };
        @log = @wrong = ();
        $it->reset;
        return ([$it->all], $it->sth);
    },
    next => sub ($stages) {
        my $it = $dbh->results($SQL, @$stages);
        my @got;
        while (my($value) = $it->next) { push @got, $value }
        return (\@got, $it->sth);
    },
    chain => sub ($stages) {
        my $it    = $dbh->results($SQL);
        my $chain = $it;
        $chain = $chain | $_ for @$stages;
        return ($chain | keep_all, $it->sth);
    },
    pipeline => sub ($stages) {
        my $it = $dbh->results($SQL);
        return ([Ekorn::Pipeline->new(@$stages)->iterator($it)->all], $it->sth);
    },
    sink => sub ($stages) {
        my $it = $dbh->results($SQL, @$stages, keep_all);
        return ($it, undef);
    },
);
my @ways = sort keys %ways;


# Run a case one way, returning what it gave and the log, or the error
# it died with and the log so far, and any value whose original it
# wasn't made from, or a statement left active.
sub run_way ($way, $seed) {
    my($stages) = make_case($seed);
    @log = @wrong = ();
    my($got, $sth);
    my $died = !eval { ($got, $sth) = $ways{$way}->($stages); 1 };
    # A death's message names the line that ran the way, so not that.
    my $what
        = $died
        ? 'died: ' . ($@ =~ s( \ at\ \S+\ line\ \d+\.? )()xgr =~ s( \n )( )xgr)
        : _shown(@$got);
    my $wrong  = @wrong ? " | not made from its original: @wrong"         : '';
    my $active = $sth && $sth->{Active} ? ' | the statement still active' : '';
    return "$what | @log$wrong$active";
}

# Each case's seed, drawn first, so a case is made the same whatever
# the cases before it did with rand.
my @seeds = defined $ONE ? ($ONE) : map { int rand 2**31 } 1 .. $CASES;

my $failed = 0;
for my $seed (@seeds) {
    my(undef, $rows, $named) = make_case($seed);
    $dbh->do('DELETE FROM t');
    $dbh->do('INSERT INTO t (n) VALUES (?)', undef, $_) for @$rows;
    my %got    = map { ($_ => run_way($_, $seed)) } @ways;
    my $first  = $got{all};
    my @differ = grep { $got{$_} ne $first } @ways;
    next if !@differ && !grep { m( not\ made\ from | still\ active )x } values %got;
    $failed++;
    fail "seed $seed: (@$rows) through $named";
    diag "    $_: $got{$_}" for @ways;
    last if $failed >= 5;
}
ok !$failed,
    scalar(@seeds) . " statement pipelines agree every way, from seed $SEED";

done_testing;
