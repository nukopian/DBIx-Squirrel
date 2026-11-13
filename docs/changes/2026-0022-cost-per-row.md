# 2026-0022. Trim DBIx::Squirrel's cost per row

**Status:** in progress

**Decisions:** None open.

**Origin:** Iain, 2026-11-13, after 2026-0021's timings showed Ekorn's
fast paths (Ekorn-Pipeline 297f137, its 2026-0028) gaining
DBIx::Squirrel's iterators 2 to 4%: "adding a task to the roadmap to
profile and trim DBIx::Squirrel's cost per row, with NYTProf against
the gazetteer is sound. Wouldn't mind you picking it up now."

**Started:** 2026-11-13

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
