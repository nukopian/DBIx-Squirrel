use v5.36;

# DBIx::Squirrel's rows through Ekorn-Pipeline's fresh-perl workers
# (Ekorn 2026-0065). On SQLite, in a directory of its own, unless
# WORKER_CHECK_DSN names another database; WORKER_CHECK_AID sets
# AutoInactiveDestroy on the parent's handle.

use Test2::V0;
use Test2::Plugin::NoWarnings;

use File::Temp  qw(tempdir);
use FindBin     qw($Bin);
use Time::HiRes qw(time);
use lib "$Bin/lib";

use DBIx::Squirrel;
use DBIx::Squirrel::Tooling  qw(take);
use Ekorn::Pipeline::Workers qw(in_workers in_workers_any once_per);
use WorkerChecks;

my $dir   = tempdir(CLEANUP => 1);
my $dsn   = $ENV{WORKER_CHECK_DSN} // "dbi:SQLite:dbname=$dir/probe.db";
my $aid   = $ENV{WORKER_CHECK_AID} ? 1 : 0;
my %attrs = (
    RaiseError          => 1, PrintError => 0, PrintWarn => 0,
    AutoInactiveDestroy => $aid,
);
my $dbh = DBIx::Squirrel->connect($dsn, undef, undef, \%attrs);
note "driver $dbh->{Driver}{Name}, AutoInactiveDestroy $aid, parent $$";

$dbh->do('DROP TABLE IF EXISTS probe_album');
$dbh->do('DROP TABLE IF EXISTS probe_artist');
$dbh->do(
    'CREATE TABLE probe_artist (id INTEGER PRIMARY KEY, name VARCHAR(20))');
$dbh->do('CREATE TABLE probe_album (artist_id INTEGER, title VARCHAR(20))');
for my $id (1 .. 20) {
    $dbh->do('INSERT INTO probe_artist VALUES (?, ?)', $id, "artist$id");
    $dbh->do('INSERT INTO probe_album VALUES (?, ?)',  $id, "album$id.$_")
        for 1 .. $id % 4;
}

my $sql   = 'SELECT id, name FROM probe_artist ORDER BY id';
my @ids   = 1 .. 20;
my @names = map { "artist$_" } @ids;


# Every worker started so far has been reaped, by waitpid's answer.
sub all_reaped () {
    my @unreaped = grep { ($Ekorn::Pipeline::Workers::REAPED{$_} // 0) != $_ }
        @Ekorn::Pipeline::Workers::FORKED;
    return is \@unreaped, [], 'every worker reaped';
}


sub parent_handle_ok ($label) {
    my $n = eval { $dbh->selectrow_array('SELECT COUNT(*) FROM probe_artist') };
    is $n, 20, "$label: the parent's handle still answers" or diag $@;
    return;
}


subtest '1a. a results row, with nothing done' => sub {
    my @got = $dbh->results($sql, in_workers(4, 'WorkerChecks::seen'))->all;
    ok !(grep { $_->[0] == $$ } @got), 'each ran in a worker';
    is [map { $_->[5] } @got], \@ids, 'its values arrive, in order';
    like $got[0][1], qr( \A DBIx::Squirrel::Result::Row_ [0-9a-f]{16} \z )x,
        'blessed into its class, by name';
    is [grep { $_->[2] } @got], [], 'but not a DBIx::Squirrel::Result';
    like $got[0][3], qr( \A died:\ Can't\ locate\ object\ method\ "name" )x,
        'and its accessors die';

    my @back = $dbh->results($sql, in_workers(4, 'WorkerChecks::echo'))->all;
    is [map { $_->name } @back], \@names,
        'a row sent back is a row again in the parent';
    all_reaped();
};


subtest '1b. a results row, with init making its class' => sub {
    # Pg and MySQL give the names only once the statement's executed.
    my $sth = $dbh->prepare($sql);
    $sth->execute;
    my $names = [@{ $sth->{NAME_lc} }];
    $sth->finish;
    my @init = (
        init      => 'WorkerChecks::make_classes',
        init_args =>
            [['DBIx::Squirrel::Result', $names], ['WorkerChecks::Artist', $names]],
    );
    my @got
        = $dbh->results($sql, in_workers(4, 'WorkerChecks::seen', @init))->all;
    is [grep { !$_->[2] } @got], [],
        'a DBIx::Squirrel::Result, in every worker';
    is [map { $_->[3] } @got], \@names, 'its accessors work';

    my @mine = $dbh->results(
        $sql, {ekorn_result_class => 'WorkerChecks::Artist'},
        in_workers(4, 'WorkerChecks::seen', @init),
    )->all;
    is [map { $_->[4] } @mine], [map { uc } @names],
        'a custom ekorn_result_class keeps its methods';

    my @any
        = $dbh->results($sql, in_workers_any(4, 'WorkerChecks::seen', @init))->all;
    is [sort map { $_->[3] } @any], [sort @names], 'in_workers_any too';
    all_reaped();
};


subtest '2. rows from iterate: arrays and ekorn_slice hashes' => sub {
    for my $shape ([array => {}], [hash => {ekorn_slice => {}}]) {
        my($what, $attrs) = @$shape;
        my @got
            = $dbh->iterate($sql, $attrs, in_workers(4, 'WorkerChecks::seen'))->all;
        is [map { [@$_[5, 6]] } @got], [map { [$_, "artist$_"] } @ids],
            "$what rows, in_workers";
        like $got[0][1], $what eq 'hash' ? qr( \A HASH \z )x : qr( \A ARRAY \z )x,
            "$what rows arrive as plain ${what}es";

        my @any
            = $dbh->iterate($sql, $attrs, in_workers_any(4, 'WorkerChecks::seen'))->all;
        is [sort { $a <=> $b } map { $_->[5] } @any], \@ids,
            "$what rows, in_workers_any";

        my @joined = $dbh->iterate(
            $sql, $attrs,
            once_per(
                \&WorkerChecks::id_of, 4, 'WorkerChecks::key',
                join => sub ($row, $seen)
                { [WorkerChecks::id_of($row), $seen->[1], $seen->[0] != $$] },
            ),
        )->all;
        is \@joined, [map { [$_, $_, 1] } @ids],
            "$what rows, once_per, each key in a worker";
    }

    my @joined = $dbh->results(
        $sql,
        once_per(
            sub { $_[0]->id }, 4, 'WorkerChecks::key', join => sub ($row, @) { $row },
        ),
    )->all;
    is [map { $_->name } @joined], \@names,
        'a results row joined by once_per keeps its class: only its key crossed';
    all_reaped();
};


subtest '3. lookups in the workers, each connecting for itself' => sub {
    my @lookup = (
        init      => 'WorkerChecks::connect_db',
        init_args => [$dsn],
        done      => 'WorkerChecks::disconnect_db',
    );
    my @got
        = $dbh->results($sql, in_workers(4, 'WorkerChecks::albums', @lookup))->all;
    is \@got, [map { [$_, $_ % 4] } @ids], 'each row looked up';
    parent_handle_ok('after in_workers');

    my @keyed = $dbh->results(
        $sql,
        once_per(
            sub { $_[0]->id }, 4, 'WorkerChecks::albums_for_id', @lookup,
            join => sub ($row, $n) { [$row->id, $n] },
        ),
    )->all;
    is \@keyed, [map { [$_, $_ % 4] } @ids], 'once_per keyed on the id';
    parent_handle_ok('after once_per');

    my $it
        = $dbh->iterate($sql, in_workers(2, 'WorkerChecks::albums', @lookup));
    my @first = map { $it->next } 1 .. 3;
    is \@first, [map { [$_, $_ % 4] } 1 .. 3],
        'three rows read, workers running';
    parent_handle_ok('mid-run');
    my @rest = $it->all;
    is scalar(@rest), 17, 'the rest still read';
    parent_handle_ok('after the mid-run check');
    all_reaped();
};


subtest '4. a stop after the stage, and an error in the block' => sub {
    my @three
        = $dbh->results($sql, in_workers(4, 'WorkerChecks::id'), take(3))->all;
    is \@three, [1, 2, 3], 'take(3) after in_workers';
    all_reaped();
    parent_handle_ok('after the stop');

    my $ok = eval {
        $dbh->results($sql, in_workers(4, 'WorkerChecks::die_at_5'))->all;
        1;
    };
    ok !$ok, 'the run dies';
    my $where = qr( at\ \S+\ line\ \d+ )x;
    like $@,
        qr( \A Pipeline\ stage\ \#1\ failed\ $where :\n \s+ boom\ at\ 5\n \z )x,
        "the block's error, wrapped as a plain stage's is";
    all_reaped();
    parent_handle_ok('after the error');

    my @after = $dbh->results($sql, in_workers(4, 'WorkerChecks::id'))->all;
    is \@after, \@ids, 'the next run, on the same handle, runs whole';
};


subtest '5. what starting workers costs a query' => sub {
    my $one   = 'SELECT id, name FROM probe_artist WHERE id = 1';
    my %block = (
        'Ekorn alone'         => ['WorkerChecks::Bare::id'],
        'with DBIx::Squirrel' => ['WorkerChecks::id'],
        'and a connection'    => [
            'WorkerChecks::albums', init => 'WorkerChecks::connect_db',
            init_args => [$dsn], done => 'WorkerChecks::disconnect_db',
        ],
        'no workers' => undef,
    );
    for my $label (
        'no workers', 'Ekorn alone', 'with DBIx::Squirrel',
        'and a connection',
    ) {
        my @times;
        for (1 .. 7) {
            my $start = time;
            my @got
                = $block{$label}
                ? $dbh->iterate($one, in_workers(4, @{ $block{$label} }))->all
                : $dbh->iterate($one)->all;
            push @times, time - $start;
            is scalar(@got), 1, "$label: one row" if $_ == 1;
        }
        my $median = (sort { $a <=> $b } @times)[3];
        note sprintf '%-20s median of 7 one-row runs, 4 workers: %6.1f ms', $label,
            1000 * $median;
    }
    all_reaped();
};


# Last, as it installs Storable hooks on the row classes, in the parent
# as well as the workers.
subtest '1c. a results row, with a STORABLE_thaw hook making its class' => sub {
    require WorkerChecks::Hooks;
    my @got
        = $dbh->results($sql, in_workers(4, 'WorkerChecks::Hooks::seen'))->all;
    is [grep { !$_->[2] } @got], [],
        'a DBIx::Squirrel::Result, in every worker';
    is [map { $_->[3] } @got], \@names, 'its accessors work';

    my @mine = $dbh->results(
        $sql, {ekorn_result_class => 'WorkerChecks::Artist'},
        in_workers(4, 'WorkerChecks::Hooks::seen'),
    )->all;
    is [map { $_->[4] } @mine], [map { uc } @names],
        'a custom ekorn_result_class keeps its methods';

    my @back
        = $dbh->results($sql, in_workers(4, 'WorkerChecks::Hooks::echo'))->all;
    is [map { $_->name } @back], \@names,
        'a row sent back is a row again in the parent';

    my @counts
        = $dbh->results($sql, in_workers(1, 'WorkerChecks::Hooks::counts'))->all;
    is $counts[-1][2], 20, "the worker's hook thawed every row";
    all_reaped();
};

$dbh->do('DROP TABLE probe_album');
$dbh->do('DROP TABLE probe_artist');
$dbh->disconnect;

done_testing;
