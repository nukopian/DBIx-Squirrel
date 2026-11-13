# 2026-0021. The how-to as a user guide

**Status:** shipped, unreleased, on `pipeline-experimental`

**Decisions:** All settled: D1, its own item, written now on
`pipeline-experimental`, following the outline below; D2, Ekorn's
features as they apply to rows; D3, 2026-0020 first; D4, a short
chapter for moving from versions 1 and 2.

**Started:** 2026-11-13

**Finished:** 2026-11-13

**Origin:** Iain's request of 2026-11-13, after Ekorn-Pipeline's how-to
was rewritten as a user guide (Ekorn-Pipeline 45b6243): "re-work HOWTO
structuring it around the concepts and architectural layers of this
Package covering anything that Ekorn-Pipeline contributes when that
makes sense, starting with a thorough examination of what is possible
at lower layer and working upwards." Split from 2026-0019, whose plan
had the how-to rewritten with the README and the reference.

## Background

`docs/HOWTO.md` grew a recipe at a time, grouped by task: connecting,
statements, binding, iterating, stages, Sugar, errors. It doesn't show
how the parts fit: that a statement is a source, that stages and sinks
are Ekorn::Pipeline's, and what each layer adds to the one below.
Iain asked for it to read as a user guide: plain English, engaging,
recipes that work and explore what the features offer, how to use and
extend them, where they have an advantage over the alternatives, and
answers to the questions a potential user has.

## Decisions

- [x] **D1.** Its own item, or part of 2026-0019? Its own, 2026-0021,
  split from 2026-0019, and written now, on `pipeline-experimental`,
  against Ekorn's working copy, Iain decided on 2026-11-13, approving
  this outline, bottom layer first:

  1. Still the DBI: connecting, handles, your own handle classes.
  2. Writing statements: any placeholder style, lists, quoting.
  3. Binding and running: bind, execute, `do`, the `select` methods,
     with stages.
  4. A statement as a source: `iterate`, `next`, `all`, `first`,
     `single`, batches, `reset`, `ended`, handles finished.
  5. Stages on rows: map, filter and flatMap, `pluck`, `as_hash`,
     Context, `peek`; compared with `map` over `fetchall`.
  6. Stopping early: `Stop`, `take`, `take_while`; compared with `LIMIT`.
  7. Parts made for each run: `gather`, `batch`, flushes and ends.
  8. Sinks: `keep_all`, `count_items`, `keep_single`, `keep(N)`.
  9. Rows as objects: `results`, row classes.
  10. Composition: pipelines as stages, named pipelines, `pipe` and
      `tap` on handles.
  11. Chaining with `|` and `@{}`.
  12. Sugar: a function for each database and statement.
  13. Caching and connections.
  14. Functions that take stages, and stages for others.
  15. When things go wrong.
  16. Questions you may have: compared with plain DBI, DBIx::Class
      and DBIx::Simple; speed, with the gazetteer's timings; limits.
  17. Coming from version 1 or 2.

  The file stays `docs/HOWTO.md`, made into
  DBIx::Squirrel::Manual::HowTo, titled as a user guide, as Ekorn's is.
- [x] **D2.** How much of Ekorn::Pipeline does it carry? Its features
  as they apply to rows and statements, in enough depth to use them
  here, with Ekorn's guide linked for the general case and for writing
  sources and sinks of one's own, Iain decided on 2026-11-13. Not
  self-contained, which would keep two accounts in step, nor minimal,
  which would send a reader away for the pipeline at the package's
  core.
- [x] **D3.** How are the examples proved? By 2026-0020, done first:
  `xt/howto.t` compares what each prints with its comments, so the
  guide is written against it, and stays true, Iain decided on
  2026-11-13, rather than by eye, as Ekorn's examples were.
- [x] **D4.** Where does moving from earlier versions go? A short
  chapter of recipes in the guide, for versions 1 and 2; the full table
  of what changes stays in the reference, under 2026-0019, Iain decided
  on 2026-11-13.

## What happened

- **2026-11-13, outcome:** `docs/HOWTO.md` is rewritten as
  "DBIx::Squirrel user guide", in the seventeen chapters of D1, with
  "The layers, at a glance" and the examples' database before them.
  Its 85 examples that run, of 90, each print what their comments say,
  checked by 2026-0020's `xt/howto.t`, written first, as D3 has it,
  and committed after this, so that each commit passes; the five not
  run need a server, a driver or a version 1 the tests don't have, or,
  as a test file, run elsewhere. Against
  Ekorn's working copy at 2f828965b20bdc7ad25b5da66826e75d16754a3e.
  - **Changes from the old how-to:** the examples' data is never
    changed for good, as the two that wrote now roll back, so every
    output is fixed; each layer says what it adds to the one below,
    and where it has an advantage over the alternative ("compared
    with" a fetch loop, `map` over every row, `LIMIT` and `last`);
    sinks have a chapter, as do `|` and `@{}`, with `|` giving one
    value explained where it's first shown; the Sugar returns
    iterators and sink results, as 2026-0016 made it; functions that
    take stages lead with one that wraps a query.
  - **Questions you may have:** whether the DBI is given up, Ekorn's
    part, speed, memory, SQL generation, DBIx::Class, DBIx::Simple,
    `|` giving one value, and what it doesn't do.
  - **The README, the reference and the main module's POD** call it
    the user guide.
- **Measurements:** the speed answer's table was timed on 2026-11-13,
  against Ekorn 2f82896, on the OSM gazetteer's `place_areas` (297,848
  narrow rows) and `areas` (21,826 rows averaging 24 KB), each case in
  a process of its own, the best of three:

  | Case | place_areas | areas |
  |---|---|---|
  | DBI `fetchrow_arrayref` loop | 0.079 | 0.125 |
  | DBI `selectall_arrayref` | 0.109 | 0.187 |
  | DBIx::Squirrel `selectall_arrayref` | 0.107 | 0.185 |
  | `iterate->all` | 0.155 | 0.188 |
  | `map` over `all` | 0.172 | 0.190 |
  | `next` to the end | 0.346 | 0.163 |
  | `iterate(keep_all)` | 0.556 | 0.225 |
  | `iterate($stage)->all` | 0.683 | 0.185 |
  | the first row, 1,000 times, DBI | 0.009 | 0.112 |
  | the first row, 1,000 times, `first` | 0.065 | 0.344 |

  The first row through `first` costs more than the DBI's
  `fetchrow_arrayref`, as `first` fetches two rows, to stop cleanly;
  the guide doesn't quote it.
- **Found, and corrected before committing:** three claims the
  examples don't test were wrong in the first draft: that a first
  value is never taken for `do`'s attributes (a hash reference of named
  values is); that the DBI warns when an active statement is executed
  again (that's the driver's to decide); and that DBIx::Simple can't
  fill a list of values (its `(??)` does).
- **What's left:** Ekorn's fast paths, its 2026-0028, are being built
  as this is written; once they land, the speed table is timed again,
  before the release, under 2026-0019.
- **2026-11-13, timed again, as planned,** once Ekorn's fast paths
  landed (its 2026-0028, Ekorn-Pipeline
  297f1379f7fc96d59ca1659e392372cf9d97b90c), in the same way, and the
  guide's table follows. The change is small, 2 to 4% where it shows,
  as DBIx::Squirrel's rows are pulled, which takes Ekorn's full path:

  | Case | place_areas | areas |
  |---|---|---|
  | DBI `fetchrow_arrayref` loop | 0.076 | 0.125 |
  | DBI `selectall_arrayref` | 0.103 | 0.182 |
  | DBIx::Squirrel `selectall_arrayref` | 0.102 | 0.183 |
  | `iterate->all` | 0.152 | 0.198 |
  | `map` over `all` | 0.174 | 0.199 |
  | `next` to the end | 0.334 | 0.171 |
  | `iterate(keep_all)` | 0.570 | 0.234 |
  | `iterate($stage)->all` | 0.665 | 0.193 |
  | the first row, 1,000 times, DBI | 0.009 | 0.124 |
  | the first row, 1,000 times, `first` | 0.067 | 0.358 |

  Ekorn expected its full path 10 to 20% faster; it's told what was
  measured here.
