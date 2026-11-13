# 2026-0014. The iterator as a source

**Status:** shipped, unreleased, on `pipeline-experimental`

**Decisions:** None open. They're 2026-0013's: D4, a fresh run from
`ekorn_source`; D22 and D23, `all`, `first` and `single` as Ekorn's
iterator's; D24, batches from 2 rows to 64; D25, `single` finishes;
D26, `all`'s fast path; D27, `reset` clears; D28 and D29, whole
batches only where nothing asks for the row.

**Origin:** split from [2026-0013](2026-0013-one-design.md), the design
Iain approved on 2026-11-13

**Started:** 2026-11-12, as the spike for 2026-0013's Q30, in
af0324c3f8b11eaf0fa69a479bf4177103d9b2e9

**Finished:** 2026-11-13

## Background

The design's section 4: a statement's iterator becomes a source of
Ekorn::Pipeline's, offering `ekorn_source`, its stages run by Ekorn's
pipeline, and `all`, `first`, `single`, `next` and `reset` rebuilt over
the same source. The spike for 2026-0013's Q30 built most of it on
`pipeline-experimental`, against Ekorn's working copy, and timed it
on Iain's OSM gazetteer; 2026-0013's What happened has the findings
and every number.

## Decisions

None of its own: they're 2026-0013's, listed above.

## The plan

**What:** finish section 4. Built by the spike: the statement's source,
with batches growing from 2 rows to 64, whole batches where nothing
asks for the row, and its end finishing the handle; its stages run by
Ekorn; `all`, `first` and `single` through Ekorn's iterator, with
`all`'s fast path; `reset` clearing; `next` taking the run's code
reference once; and 4.6's four guarantees, tested in
`t/24-iterator-source.t`. Left: `ended`, giving how the run ended, as
Ekorn's iterator does (4.4); `|` and `@{}`, overloaded with Ekorn's
Operators' `chain` and `drain`, loading Operators with an empty import
list (4.5); and DBIx::Squirrel::Results checked against the new source
(4.7), including a result set read through a pipeline after it's let
go.

**Why:** everything else in 2026-0013's design rests on the statement
being a source: Context (2026-0015), sinks (2026-0016) and the release
(2026-0019).

**Steps:** `ended`, with tests; the overloads, with tests that `|` and
`@{}` work only where the user wrote `use Ekorn::Pipeline::Operators`;
Results through a pipeline; the tests against MySQL and PostgreSQL run
on Iain's Mac; the POD of DBIx::Squirrel::Iterator for all of it.

**Done when:** section 4 is built; its tests pass against Ekorn's
working copy, and against MySQL and PostgreSQL; `t/06-gather.t`'s two
failures are the only ones, as v0.3.0's intended changes; and coverage
meets its floors.

## What happened

- **2026-11-12:** the spike, in 2026-0013's What happened: built in
  af0324c3f8b11eaf0fa69a479bf4177103d9b2e9, with whole batches in
  9331a4d7ba024d3891e8dc47e9d336460a12aed5 and `next` taking the code
  reference once in 118538e.
- **2026-11-13, outcome:** section 4 is built, against Ekorn's
  working copy at a9e9891f6b9c48544e91e1706cce1cf6b5e46ce0, on its `pipeline-experimental`.
  Every test passes there, against SQLite, MySQL 8.4 and PostgreSQL
  18 on Iain's Mac; coverage meets its floors (branch 97.3%). Done when
  allowed for `t/06-gather.t`'s two failures; there are none, as
  f044232 followed Ekorn's flush and end first.
  - `ended` gives the last run's `done`, `stopped` or `died`, kept
    once the iterator lets the run go, and nothing while a run is
    going, or after `reset`.
  - `|` and `@{}` are Ekorn's `chain` and `drain`, overloaded on the
    iterator, so on DBIx::Squirrel::Results too, with Operators loaded
    with an empty import list. Without `use Ekorn::Pipeline::Operators`
    in scope, both croak with Ekorn's message, executing nothing.
  - The tests are in `t/25-iterator-ended-operators.t`.
- **Found: a result set read by a pipeline after it was let go gave
  plain arrays,** not objects: the source blessed each row through the
  weak reference to the result set, and gave the row as it was once
  that had gone. Now the source asks the iterator, as the run starts,
  for what makes each row (`_row_maker`, in place of `_row`), and
  keeps it. DBIx::Squirrel::Results finds its rows' class there, from
  the columns' names, in place of its own `reset`.
- **Found: two things the plan didn't say,** both as the design
  implies, and in the POD:
  - `single` on a statement with one row ends `done`, not
    `stopped`: its lookahead reached the end.
  - A run read with `|` or `@{}` is the iterator's last run, as
    `ekorn_source` starts it with `reset`. So `next` after one
    returns nothing, and `ended` says how that run ended, until
    `reset`.
- **Fixed: `t/12-mysql.t` and `t/13-pg.t` still took `all` in
  scalar context for a count,** which the spike changed to an array
  reference. CI has neither server, so only the run on Iain's Mac
  showed it.
- **What's left:** the iterator's stages ask DBIx::Squirrel::Context,
  so `pluck` and the like don't yet work in a user's own pipeline
  reading the iterator through `|`: 2026-0015. A sink given last as an
  argument: 2026-0016. The README, reference and how-to, with `|`
  giving one value explained where it's first shown: 2026-0019.
