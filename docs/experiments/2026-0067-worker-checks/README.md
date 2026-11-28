# DBIx::Squirrel's rows through Ekorn's fresh-perl workers

Checks, not part of DBIx-Squirrel: this directory lives only on the
branch `experiment/2026-0067-worker-checks`. They try DBIx::Squirrel's
rows through the worker stages of Ekorn-Pipeline's 2026-0065, as
prototyped on its branch `experiment/2026-0065-mce-worker-stages`,
under `docs/experiments/2026-0065-mce-worker-stages/fresh-perls/`.
They're kept for roadmap 2026-0067, lookups and split reads in Ekorn's
workers, and so Ekorn's workflow can run them on Windows.

## What's here

- `t/worker-checks.t`: the checks, in Test2. On SQLite in a temporary
  directory, unless `WORKER_CHECK_DSN` names another database;
  `WORKER_CHECK_AID=1` sets `AutoInactiveDestroy` on the parent's
  handle.
- `t/lib/WorkerChecks.pm`: the named functions the workers load, as a
  fresh perl reaches no closure: blocks, `init` and `done`.
- `t/lib/WorkerChecks/Bare.pm`: a block loading nothing of ours, for
  the cost of starting workers with Ekorn's modules alone.
- `t/lib/WorkerChecks/Hooks.pm`: a trial of Storable hooks on our row
  classes, so a row makes its class as it thaws in a worker. It's not
  DBIx::Squirrel's code.
- `hook-cost.pl`: what those hooks add to a row's freeze and thaw.

## Running them

From a DBIx-Squirrel checkout of this branch, with a checkout of
Ekorn-Pipeline's branch beside it at `$EKORN`:

```sh
prove -I$EKORN/docs/experiments/2026-0065-mce-worker-stages/fresh-perls/lib \
    -I$EKORN/lib -Ilib docs/experiments/2026-0067-worker-checks/t/worker-checks.t
```

They need DBIx::Squirrel's own prerequisites (its `cpanfile`) and
DBD::SQLite; nothing more from CPAN.

## What they found

On Perl 5.36.3, macOS, against Ekorn-Pipeline
8f0e2bb55bd26692d478dd0b2bdf447d4140fc50: 57 checks pass on SQLite,
PostgreSQL 18 and MySQL 8.4, with and without `AutoInactiveDestroy`.

1. A `results` row arrives in a worker with its values, blessed into
   its class by name, but the class is empty there: no accessors, and
   not a DBIx::Squirrel::Result. Made in `init`, from the column names,
   it works. So does a `STORABLE_thaw` hook, with no `init`. A row sent
   back is a row again in the parent either way.
2. Rows from `iterate`, arrays and `ekorn_slice` hashes, cross as they
   are. `once_per` sends a worker only the key, so a row it joins never
   crosses.
3. Workers connecting for themselves leave the parent's handle alone,
   after each run and mid-run.
4. A stop and an error end the run with every worker reaped; the
   error is wrapped as a plain stage's is.
5. A one-row run with 4 workers takes about 35 ms with Ekorn's modules
   alone, 50 ms with DBIx::Squirrel's, and 55 to 92 ms with each worker
   connecting, against 0.1 ms without workers.
