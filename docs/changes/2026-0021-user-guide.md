# 2026-0021. The how-to as a user guide

**Status:** open

**Decisions:** All settled: D1, its own item, written now on
`pipeline-experimental`, following the outline below; D2, Ekorn's
features as they apply to rows; D3, 2026-0020 first; D4, a short
chapter for moving from versions 1 and 2.

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
