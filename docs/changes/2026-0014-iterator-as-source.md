# 2026-0014. The iterator as a source

**Status:** in progress

**Decisions:** None open. They're 2026-0013's: D4, a fresh run from
`ekorn_source`; D22 and D23, `all`, `first` and `single` as Ekorn's
iterator's; D24, batches from 2 rows to 64; D25, `single` finishes;
D26, `all`'s fast path; D27, `reset` clears; D28 and D29, whole
batches only where nothing asks for the row.

**Origin:** split from [2026-0013](2026-0013-one-design.md), the design
Iain approved on 2026-11-13

**Started:** 2026-11-12, as the spike for 2026-0013's Q30, in
af0324c3f8b11eaf0fa69a479bf4177103d9b2e9

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
