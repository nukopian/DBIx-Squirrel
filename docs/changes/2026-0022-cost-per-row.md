# 2026-0022. Trim DBIx::Squirrel's cost per row

**Status:** shipped, unreleased, on `pipeline-experimental`

**Decisions:** None open.

**Origin:** Iain, 2026-11-13, after 2026-0021's timings showed Ekorn's
fast paths (Ekorn-Pipeline 297f137, its 2026-0028) gaining
DBIx::Squirrel's iterators 2 to 4%: "adding a task to the roadmap to
profile and trim DBIx::Squirrel's cost per row, with NYTProf against
the gazetteer is sound. Wouldn't mind you picking it up now."

**Started:** 2026-11-13

**Finished:** 2026-11-13

## Background

On the OSM gazetteer's `place_areas`, 297,848 narrow rows, against
Ekorn 297f137, best of three, in seconds: the DBI's
`fetchrow_arrayref` loop 0.076; `iterate->all`, no stages, 0.152;
`next` to the end 0.334; `iterate(keep_all)` 0.570;
`iterate($stage)->all` 0.665. A stage costs about 1.7 microseconds a
row, and `next` 0.8 more than the DBI's loop. Ekorn's full path, which
a pull takes, got 10 to 20% faster, yet these hardly moved, so the
cost is likely DBIx::Squirrel's: `DBIx::Squirrel::Context::within`
around each `next`, the counting stage added after the iterator's
stages, and the source's step and its `$made`.

## The plan

**What:** profile `next` to the end, `iterate($stage)->all` and
`iterate(keep_all)` over `place_areas` with Devel::NYTProf, find where
DBIx::Squirrel's own time goes, and trim it, keeping every behaviour
the tests pin down. Anything found in Ekorn goes to it as a message.

**Why:** a stage's cost per row is the price of the pipeline, which
the user guide quotes, and DBIx::Squirrel shouldn't add to Ekorn's.

**Steps:** profile; trim, a change at a time, each timed as 2026-0021
timed, each case in a process of its own, best of three; the user
guide's speed table follows.

**Done when:** each case is timed before and after, every change kept
is measured to help, the tests pass against Ekorn's working copy and
coverage meets its floors, and the guide's table is current.

## What happened

- **2026-11-13, profiled:** with Devel::NYTProf, each case run alone
  over `place_areas`. `next` to the end spent 1.45 s of profiled time
  in `next`, of which about 1.05 s was DBIx::Squirrel's own: `next`
  0.60 s, Context's `within`, called for each row, 0.39 s, and
  `_executed`, called for each row, 0.06 s; Ekorn's pull 0.40 s. With
  a stage, Ekorn's step loop took 1.5 of 2.0 s, and DBIx::Squirrel's
  source step, its `$made` and its counting stage about 0.45 s.
- **Kept: `next` localises the Context itself.** Context's iterator is
  a package variable, `$DBIx::Squirrel::Context::ITERATOR`, in place
  of a lexical hash, so `next` localises it, and checks whether the
  statement has run, without a call of `within` and `_executed` for
  each row. `within` stays, for `all`, `first` and `single`, called
  once each. `next` to the end: 0.334 s to 0.278 s.
- **Kept: the source's step gives a row at a time directly,** while
  the batch has rows and stages or a pipeline read it, without a call
  of `$made` and a list copy for each row. With a stage: 0.668 s to
  0.625 s; `keep_all` given last: 0.557 s to 0.527 s. That made the
  step's check for an empty batch always true, a branch no test could
  reach, so it went, which kept branch coverage above its floor.
- **Tried and reverted:** the counting stage without a signature:
  0.625 s to 0.624 s, no measurable gain.
- **Outcome,** against Ekorn's working copy at
  be205aecafe1a9d1f9ba64310e9177417cbf50cc, best of three, in seconds, before (Ekorn 297f137, the user
  guide's table) and after:

  | Case | place_areas, before | after | areas, before | after |
  |---|---|---|---|---|
  | `next` to the end | 0.334 | 0.276 | 0.171 | 0.167 |
  | `iterate($stage)->all` | 0.665 | 0.637 | 0.193 | 0.193 |
  | `iterate(keep_all)` | 0.570 | 0.533 | 0.234 | 0.223 |
  | `iterate->all`, no stages | 0.152 | 0.156 | 0.198 | 0.196 |

  `next` to the end is 17% quicker; a stage or a sink 4 to 6%. Every
  test passes, against SQLite, MySQL 8.4 and PostgreSQL 18, and
  coverage meets its floors. The user guide's table follows.
- **What's left is Ekorn's:** with a stage, its step loop is about
  three quarters of a row's profiled time, and DBIx::Squirrel's about
  a tenth. Nothing more of DBIx::Squirrel's is worth trimming without
  changing what it does.
