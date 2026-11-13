# 2026-0016. Runs that end in a sink

**Status:** shipped, unreleased, on `pipeline-experimental`

**Decisions:** None open. They're 2026-0013's: D16, a sink given last
says what comes back, and DBIx::Squirrel's calls give an iterator
without one, the Sugar's statements included; D18, the `select`
methods push the DBI's result through stages; D19, the Sugar's clash
check catches a sink of the same name, with a test; D20, a sink of
many gives an array reference where one value is asked for.

**Origin:** split from [2026-0013](2026-0013-one-design.md), the design
Iain approved on 2026-11-13

**Started:** 2026-11-13

**Finished:** 2026-11-13

## Background

The design's sections 3, 6 and 10. Today a call of DBIx::Squirrel's
that takes stages gives an iterator, or, from the Sugar, every result,
or a count in scalar context. In the design, a statement is a source:
DBIx::Squirrel's calls give the source, an iterator, and only a sink
given last turns it into a result. The DBI's own calls give what the
DBI gives.

## Decisions

None of its own: they're 2026-0013's, listed above.

## The plan

**What:**

- `iterate` and `results`, on database and statement handles, give the
  sink's result when the last stage is one of Ekorn's sinks, reading
  the run to its end: a sink of one gives its value; a sink of many
  gives a list, or, where one value is asked for, an array reference.
  Without a sink last, an iterator, as now.
- The Sugar's statements, and a database's function given a statement
  and stages, give an iterator when given stages, or the sink's result
  when the last is a sink, in place of every result, or a count.
- The `select` methods, given stages after the bind values, push what
  the DBI gives through them, as a pushed run of Ekorn's, and give what
  comes out: every value in list context; in scalar context, a sink's
  result, or, with no sink, a count (Ekorn's D17). Without stages, what
  the DBI gives, as now.

**Why:** a sink given last says what comes back, so no call lists or
counts by its calling context, but for a `select` method's stages
without a sink.

**Steps:** a sink last in `iterate` and `results`; the Sugar, with
D19's test; the `select` methods; tests of each, with section 10's
table checked against them; the reference, the how-to, the POD and `Changes`.

**Done when:** each call does so, with tests; section 10's table holds;
every test passes against Ekorn's working copy, and against MySQL and
PostgreSQL; and coverage meets its floors.

## What happened

- **2026-11-13, outcome:** as planned, against Ekorn's working copy at
  fd541c497274676cb068f5aabccf12810381fead, on its
  `pipeline-experimental`. Every test passes there, against SQLite,
  MySQL 8.4 and PostgreSQL 18; coverage meets its floors (branch
  97.4%). Tests in `t/27-sinks.t`, and D19's in `t/16-sugar.t`.
  - `iterate` and `results` end in the iterator's `_or_sink`: with a
    sink last, a sink of one gives `first`, and a sink of many `all`,
    a list, or an array reference for one value.
  - The Sugar's functions give what `iterate` gives, so an iterator
    for stages, or a sink's result; its `_all` is gone.
  - The `select` methods split stages off the end, leaving the
    attributes off when a stage is first, as `iterate` does, and push
    what the DBI's method gives through a pipeline called with it.
  - Section 10's table holds for what this item covers; its rows for
    DBIx::Squirrel::Pipeline are 2026-0017's.
- **Changed from the plan: a sink of many, pulled, gives its items
  one by one,** not one array reference, as Ekorn's sinks give a
  reference only where one value is asked for, by `|` or a pushed run.
  So `_or_sink` takes a sink of many with `all`, which gives the
  reference where one value is asked for, not with `first`.
- **Found: the how-to's tests run its examples, but don't compare what
  they print with the comments beside them.** The Sugar's examples
  printed iterators once they gave one, and passed. Each was given a
  sink, and what the examples print was read against the comments by
  hand: they agree.
- **Found: `t/12-mysql.t` and `t/13-pg.t` used a Sugar statement for a
  list,** which only a run against the servers showed, as CI has
  neither.
- **What's left:** the reference's Upgrading from 1.x still says what
  `all` and `count` did in v2: 2026-0019, which rewrites the docs.
