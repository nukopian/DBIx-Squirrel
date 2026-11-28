use v5.36;
# Per row: nfreeze and thaw of a results row, without and with the trial hooks.
use FindBin qw($Bin);
use lib "$Bin/t/lib";
use Storable    qw(nfreeze thaw);
use Time::HiRes qw(time);
use DBIx::Squirrel;
my $dbh = DBIx::Squirrel->connect(
    'dbi:SQLite:dbname=:memory:', undef, undef,
    {RaiseError => 1},
);
$dbh->do('CREATE TABLE t (id INTEGER, name TEXT, plays INTEGER, album TEXT)');
$dbh->do('INSERT INTO t VALUES (?, ?, ?, ?)', 1, 'Ann', 42, 'First');
my $n = 100_000;


sub cost ($label) {
    my $row   = $dbh->results('SELECT * FROM t')->first;
    my $start = time;
    thaw(nfreeze([1, $row, {}])) for 1 .. $n;
    printf "%-12s %5.2f us a row\n", $label, 1e6 * (time - $start) / $n;
    return;
}
cost('plain') for 1 .. 3;
require WorkerChecks::Hooks;
cost('hooked') for 1 .. 3;
