# 2026-0032. DBIx::Squirrel::Context on Ekorn's, without the counting stage

**Status:** shipped, unreleased

**Decisions:** D1 settled: `result_number` is Ekorn's, in every run. D2
settled: `result_original` falls back to Ekorn's outside a statement's
run. D3 settled: `iterator` keeps the `local`ised global. D4 settled:
v3.6.0, with the floor raised. D5 settled: `next` and `all`, before
and after.

**Origin:** a message from Ekorn-Pipeline's session, 2026-11-16
(Ekorn-Pipeline 5ff0ea15ada5f95207001e740889614f32c574ff, its roadmap
2026-0046), answering DBIx-Squirrel's of the same day (Ekorn-Pipeline
ce1c31c73368604c409831b1d446bc6e886ef034) on the counting stage

**Depends on:** Ekorn-Pipeline 2026-0046, released in v0.3.11

**Started:** 2026-11-24

**Finished:** 2026-11-24

## Background

Every iterator with stages adds a stage of its own,
`sub { $counter->{produced}++; $_[0] }`, in `Iterator.pm`'s
`_pipeline`, only so `result_number` can say which result a stage is
making. Reading all 297,848 rows of `place_areas` through one bare
stage, it costs 200 to 260 ns a row, 11 to 15%, on 5.36 and 5.44, with
`next` or `all`; the table is in Ekorn's record.

Ekorn's 2026-0046 adds Ekorn::Pipeline::Context, with
`result_number` and `result_original`, in a v0.3.x:

- its `result_number` counts each run's own results, pulled or pushed,
  a result being a value leaving the last stage or reaching a sink;
  undef outside a stage;
- its `result_original` is the value the run's own source gave, or
  that was pushed; it isn't carried through chains, where ours, kept
  in the statement's context, is;
- a run that reads neither costs nothing more.

Iain decided there that DBIx::Squirrel::Context keeps functions of the
same names, built on Ekorn's as this session designs, and that
DBIx::Squirrel::Tooling goes on importing ours.

Iain, 2026-11-16: not to be started this week.

## Decisions

- [x] **D1.** Is `result_number` Ekorn's, in every run? Ours is there
  only in an iterator's own stages, and is undef in them when another
  pipeline reads the iterator as its source. Ekorn's would answer in
  every run, those included. Ekorn's, as recommended, Iain decided
  on 2026-11-24: it widens what ours promises, adding and taking
  nothing away.
- [x] **D2.** Does `result_original` fall back to Ekorn's outside a
  statement's run, where ours is undef now? Ours stays the row from
  the statement's context wherever there is one, chains included.
  Yes, as recommended, Iain decided on 2026-11-24, for the same
  reason as D1.
- [x] **D3.** Does `iterator` keep the global `next` `local`ises? Once
  the counting stage goes, `result_number` no longer needs it, and
  `iterator` is its only user. 2026-0031, dropped, measured moving it
  into the run's context: `next` gained 0 to 5%, and a stage reading
  it each row lost 7 to 12%. Keep it, as recommended, Iain decided on
  2026-11-24: a stage reading `iterator` stays as cheap as it is.
- [x] **D4.** Relying on Ekorn::Pipeline::Context raises the
  `cpanfile`'s floor to the release that has it, so this needs a
  release of ours. With D1 and D2 widening promises, which version?
  When this was written, v3.2.0 was next. v3.6.0, as recommended,
  Iain decided on 2026-11-24: a minor release, as it widens promises and
  raises the floor, taking nothing away.
- [x] **D5.** What's measured? `next` and `all` over `place_areas`,
  through one bare stage, and one reading `result_number`, before and
  after, on 5.36 and 5.44, as recommended, Iain decided on 2026-11-24:
  Ekorn's record has the before, measured the same way.

## The plan

**What:** DBIx::Squirrel::Context's `result_number` and
`result_original` built on Ekorn::Pipeline::Context's, as D1 and D2
say, and the iterator's counting stage gone.

**Why:** the stage costs 200 to 260 ns a row only to count, and
Ekorn v0.3.11 counts every run's results itself; a throwaway copy
measured the change at 159 to 271 ns a row quicker, 8 to 17%.

**How:** `result_number` is Ekorn's own sub, the same code under our
name, as D1 makes it Ekorn's in every run, so a stage reading it pays
no call of ours, and the two packages export one sub when Ekorn's
Tooling gains it in v0.4.0. `result_original` stays ours: the row from
the statement's context where there is one, as now, and Ekorn's
elsewhere (D2). `iterator` and the global the iterator localises stay
as they are (D3). The iterator's `_pipeline` drops the stage, and
`reset` the `produced` count.

**Steps:**

1. Raise the floor to Ekorn::Pipeline v0.3.11 in `cpanfile`, and make
   `META.json` again.
2. Change `Context.pm` and `Iterator.pm`, and Context's POD.
3. Tests: `t/26-context-in-pipelines.t` checks the widened promises,
   `result_number` in a pipeline of a user's own and in a chain, and
   `result_original` falling back to Ekorn's outside a statement's
   run; `t/28-tooling.t` still passes.
4. The reference's Context section, its table of what a statement's
   run gives each piece, its index entries, and its row on
   `result_number` in a pipeline of your own; the user guide where it
   says the same; `scripts/manuals`.
5. Measure, as D5 says, and put it here.
6. `Changes`, coverage, and the style checks.

**Done when:** the tests pass on 5.36 to 5.44 against Ekorn v0.3.11,
coverage holds its floors, the measurements are here, and `Changes`
says so, for v3.6.0 (D4).

## What happened

- **Outcome:** as planned, for v3.6.0. The tests pass on 5.36.3,
  5.38.5, 5.40.5, 5.42.3 and 5.44.0, MySQL and PostgreSQL included,
  against Ekorn-Pipeline 2569157773e688e290f0e7beebfe0a53234068e3
  (v0.3.11), and coverage holds its floors.
- **Changes from the plan:** `result_number` is a sub of ours calling
  Ekorn's, not Ekorn's under our name. Ekorn's has no prototype: under
  `use v5.36`, its `()` is an empty signature. Ours has always had an
  empty prototype, so `result_number + 1` adds one; with Ekorn's sub,
  it passes `+1` as an argument, and `result_number // 'none'` reads
  `//` as a pattern, as `t/14-iterate.t` found. So a stage reading it
  pays one more call, and when Ekorn's Tooling gains the names in
  v0.4.0 (its 2026-0051), the two are different subs; Ekorn's session
  is told. A sink's step now sees the number of the value it's given,
  not the next, and an end sees `undef`, as Ekorn's promise has it:
  the reference's table says so.
- **Measurements** (D5): all 297,848 rows of `place_areas`, ns a row,
  best of five, through one stage passing the row on ("bare") or one
  calling `result_number` ("reading"); before is DBIx::Squirrel at
  e3400a0fb11cc493053e6e705b47e823f6f9f4c6, v3.5.0's code, with Ekorn
  v0.3.10; after is this commit's, with Ekorn v0.3.11:

  | | before | after | gain |
  |---|---|---|---|
  | `next`, bare, 5.36 | 1,956 | 1,757 | 199 (10.2%) |
  | `all`, bare, 5.36 | 1,673 | 1,468 | 205 (12.3%) |
  | `next`, reading, 5.36 | 2,085 | 1,874 | 211 (10.1%) |
  | `all`, reading, 5.36 | 1,794 | 1,575 | 219 (12.2%) |
  | `next`, bare, 5.44 | 1,889 | 1,664 | 225 (11.9%) |
  | `all`, bare, 5.44 | 1,650 | 1,376 | 274 (16.6%) |
  | `next`, reading, 5.44 | 1,997 | 1,800 | 197 (9.9%) |
  | `all`, reading, 5.44 | 1,756 | 1,511 | 245 (14.0%) |

  So 197 to 274 ns a row quicker, 10 to 17%: the counting stage's cost,
  less Ekorn's counting, as the throwaway copy measured.
- **What's left:** nothing.
