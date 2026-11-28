# Planned work

## Check your `results` rows through Ekorn's MCE worker prototype (Ekorn 2026-0065)

**From:** Ekorn-Pipeline's session, 2026-11-28 (Ekorn-Pipeline
d40cd221bd33b7ce0047292fd76a616f90e8e95a, on the branch
`experiment/2026-0065-mce-worker-stages`)

**Waiting on:** nothing; Iain asked for it as you offered.

**What:** run a `results` query through Ekorn's prototype of
`in_workers`, on a real MCE pool, and say whether your row objects keep
their methods in the workers. The prototype starts its workers at a
run's first value (D1) and sets each up with `init`, given `init_args`,
its results following the value into the block, and `done` as it
leaves (D2), as Ekorn's record
`docs/changes/2026-0065-mce-worker-stages.md` settled. Its README, at
`docs/experiments/2026-0065-mce-worker-stages/README.md` on that
branch, has the rest.

The checks that would tell us most, each a pass or a fail with what
you saw:

1. A `results` query's rows through `in_workers(4, sub ($row) { ... })`,
   the block calling a column accessor and `isa('DBIx::Squirrel::Result')`:
   with workers started at the first value, does each row have its
   class, with nothing more?
2. The same with `in_workers_any`, and through `once_per`, keyed by a
   column, with a `join` returning the row: does the joined row keep
   its class, as you asked?
3. A lookup in the workers, each connecting for itself in `init` from a
   DSN, `init_args` carrying it, `done` disconnecting, the parent's
   handle untouched: does the parent's connection survive the run, with
   and without `AutoInactiveDestroy` on it?
4. A stop after the stage (`take`), and an error in the block: does the
   run end cleanly, with every worker gone?

**Why:** your Storable test showed a row thawed without its class loses
its methods. This tries the case D1 was settled for, with your rows,
through the pool as it will be built.

**Files:** none of yours change. From a worktree of Ekorn's branch, or
`git -C ~/Git/github.com/nukopian/Ekorn-Pipeline show
d40cd221bd33b7ce0047292fd76a616f90e8e95a:docs/experiments/2026-0065-mce-worker-stages/lib/Ekorn/Pipeline/Workers.pm`,
the module goes on `@INC` before Ekorn's `lib`. It needs MCE 1.904;
we installed it with `cpanm -n -L` into a directory of the scratchpad,
not a perlbrew library, and you'd want the same, as installing is
Iain's to agree. Run it on Perl 5.36 with `perl-5.36.3@dbix-squirrel-2`,
which has DBD::SQLite.

**Check it's done:** a message in Ekorn's `TODO.md` with each check's
result, what you ran, and anything that surprised you. Remove this task
in the commit that sends it. On Windows the pool is still being proved
(D5); a check on macOS is what we ask.

## A README pointer to Ekorn-Pipeline's section for readers who know transducers or streams

**Waiting on:** Ekorn-Pipeline's next CPAN release, carrying its
roadmap 2026-0063.

**What:** Ekorn-Pipeline's README has a section, "If you know
transducers or streams" (Ekorn-Pipeline
71eec14295193db2813fd6ab1b1ddcae07feb98c), for readers who know
Clojure's transducers, Java's streams or Rust's iterators. Once it's on
MetaCPAN, decide with Iain whether `README.pod`'s "Part 2: With
Ekorn::Pipeline" gains a line pointing at it, and if so, add one.

**Why:** we waited (cc5920d) so the link lands on MetaCPAN rather than
GitHub; before the release the anchor exists only on GitHub.

**Files:** `README.pod` (Part 2, the paragraph ending "Ekorn::Pipeline's
own documents say the rest"); `Changes` under Unreleased if the line
is added.

**Check it's done:** the release is on MetaCPAN with the anchor
`#if-you-know-transducers-or-streams`; the link in `README.pod`
resolves there; `podchecker README.pod` is clean; `xt/manuals.t` and
`xt/examples.t` pass. If Iain decides against the line, remove this
task saying so.
