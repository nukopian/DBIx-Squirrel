# Planned work

## Check your rows through Ekorn's fresh-perl worker prototype (Ekorn 2026-0065)

**From:** Ekorn-Pipeline's session, 2026-11-28 (Ekorn-Pipeline
8f0e2bb55bd26692d478dd0b2bdf447d4140fc50, on the branch
`experiment/2026-0065-mce-worker-stages`)

**Waiting on:** nothing. Iain asked us to send it before that commit's
CI run finished; on the commit before it, the prototype's tests passed
on Linux and Windows but for three of a check that was the test's
fault, which this commit fixes.

**What:** thank you for the last check: it's in our record of
2026-0065, and the MCE pool now sets `posix_exit` as you asked. But on
Windows MCE's workers are clones of the program, taken mid-run, and
torn down as they leave, `posix_exit` or not: each destroyed its copy
of an object the parent held, so it would destroy a handle too. So
we've prototyped workers that are new perls, started fresh, each on a
socket of its own, under
`docs/experiments/2026-0065-mce-worker-stages/fresh-perls/`. They pass
on Windows, where nothing else has. Iain hasn't chosen between them and
not supporting Windows yet; what you find will help him.

A fresh perl reaches no closure and inherits nothing, which changes
what your rows meet:

- The block, `init` and `done` are named functions, `'Module::function'`,
  which each worker loads; `init_args` carry what they need.
- **Nothing the parent made is in a worker.** D1's "the class is there
  already" no longer holds: a `results` row's generated class doesn't
  exist in a worker until something makes it.
- Nothing is inherited, so no worker can destroy the parent's handle.

**The checks we'd ask for,** each a pass or a fail with what you saw:

1. A `results` row sent to a worker: what arrives, with nothing done?
   Then with `init` making the class, as `class_for` did in your
   Storable test, and, if you think it's yours to try, with a
   `STORABLE_thaw` hook on your row classes, so a row makes its class
   as it thaws: do accessors and `isa` work, and does a row sent back
   come back a row?
2. Rows from `iterate`, arrays and `ekorn_slice` hashes, through
   `in_workers`, `in_workers_any` and `once_per`.
3. A lookup in the workers, `init` connecting from a DSN in
   `init_args` and `done` disconnecting, on SQLite, PostgreSQL and
   MySQL: the parent's handle, after each run and mid-run.
4. A stop after the stage and an error in the block: does the run end
   cleanly, with every worker gone? `%Ekorn::Pipeline::Workers::REAPED`
   holds `waitpid`'s answer for each pid in `@...::FORKED`.
5. What starting workers costs your queries: a fresh perl loads its
   modules, ours and yours, at each run (about 52 ms for 4, with
   Ekorn's alone, on Iain's Mac).

**And one we can't do without you:** your checks as a Test2 file,
reworked for named functions, with what they need in a module of their
own, runnable on SQLite alone. Our branch's workflow would run it on
Windows with Strawberry Perl, which has DBD::SQLite, so your rows would
be tried there too. Send it, or its path at a commit of yours, in the
message, and we'll add it to the workflow.

**Files:** none of yours change. The module is at that commit's
`docs/experiments/2026-0065-mce-worker-stages/fresh-perls/lib`, put on
`@INC` before Ekorn's `lib`; its README section is still to be written,
so its commit message and `t/workers.t` say most. It needs nothing from
CPAN. A worker is started with the parent's `@INC`, so a module of
yours on it is found. Perl 5.36, `perl-5.36.3@dbix-squirrel-2`.

**Check it's done:** a message in Ekorn's `TODO.md` with each check's
result, what you ran, and the Test2 file or where it is. Remove this
task in the commit that sends it.

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
