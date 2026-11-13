# 2026-0023. The reference, rewritten for v3

**Status:** shipped, unreleased, on `pipeline-experimental`

**Decisions:** All settled: D1, its own item, now; D2, in the user
guide's layer order; D3, its examples run and checked; D4, upgrading
from 2.x in it; D5, DBIx::Squirrel's protocols covered.

**Origin:** Iain, 2026-11-13: "Fancy having a crack at REFERENCE? It
must be quite stale now." Split from 2026-0019, whose plan had the
reference rewritten with the README.

**Started:** 2026-11-13

**Finished:** 2026-11-13

## Background

`docs/REFERENCE.md` describes every feature, but it was last written
whole for v2.1.0, and each item since added to it piecemeal. Missing:
sinks, `ended`, `|` and `@{}`, `selectall_array`'s stages, and
upgrading from 2.x. Stale: the iterator's `all`, `first` and `single`,
and the Sugar's statements given stages. Its order isn't the user
guide's, which 2026-0021 rewrote by layers. Its 69 examples aren't run.

## Decisions

- [x] **D1.** Its own item, or 2026-0019's? Its own, 2026-0023, split
  from 2026-0019, done now on `pipeline-experimental`, Iain decided on
  2026-11-13.
- [x] **D2.** How is it organised? In the user guide's layer order,
  still a complete map of every method, attribute, function and
  message, each section linking to its chapter, so a reader can move
  between the two, Iain decided on 2026-11-13, rather than keep its
  order and update in place.
- [x] **D3.** Are its examples run? Yes, by 2026-0020's checker,
  generalised to the reference, so its examples print what their
  comments say, Iain decided on 2026-11-13.
- [x] **D4.** Where does the table of what changes for users in v3.0.0
  go? In the reference now, as "Upgrading from 2.x", beside the 1.x
  section, from the design's section 10, Iain decided on 2026-11-13.
- [x] **D5.** Are DBIx::Squirrel's protocols covered? Yes, Iain said
  on 2026-11-13: "Might want to cover protocols, too." So the reference
  documents what other code can rely on: the iterator as a source,
  through `EKORN_SOURCE`, each use a fresh run; the context a
  statement's run gives its stages, the column names, the statement
  handle and the row the value came from, which `pluck`, `as_hash` and
  `result_original` read, and which a stage of anyone's can read with
  `Ekorn::Pipeline::run_context()`; and the parts the iterator and the
  Sugar take, Ekorn's stages, sinks and named pipelines.

## The plan

**What:** a reference for what's on `pipeline-experimental`, in the
guide's order: at a glance; then connecting, placeholders, binding and
running, iterators, stages and Context, stopping, `gather`, sinks, row
objects, pipelines and `pipe` and `tap`, `|` and `@{}`, the Sugar,
caching, writing stages and functions, and the protocols; then errors
and every message, differences from plain DBI, upgrading from 1.x and
2.x, and the modules. Every example runs, against the guide's database,
and prints what its comments say.

**Why:** a reference that's out of date misleads more than none.

**Steps:** `xt/howto.t` generalised to the reference; the reference
rewritten; `t/23-documented.t` kept in step with its claims; the
manuals made again; the README and POD where they point at sections.

**Done when:** every method, attribute, function and message on the
branch is in it, as it now behaves; its examples run and print what
they say; the tests pass against Ekorn's working copy, with coverage at
its floors; and the manuals are made from it.

## What happened

- **2026-11-13, outcome:** `docs/REFERENCE.md` is rewritten for what's
  on `pipeline-experimental`, against Ekorn's working copy at
  be205aecafe1a9d1f9ba64310e9177417cbf50cc, in the guide's order, each
  chapter linking to the guide's. Every test passes, on SQLite, MySQL
  8.4 and PostgreSQL 18, and coverage meets its floors.
  - **Added:** the examples' database and a runnable at-a-glance;
    sinks (8); the iterator's `first`, `ended` and what `all`,
    `first` and `single` take; stages for the select methods,
    `selectall_array` among them; named pipelines; `|` and `@{}`
    (11); 15. Protocols, D5: the iterator as a source, the run's
    context (`statement`, `columns`, `row`) as a documented contract,
    what a call takes as stages, and a `gather` block's parts;
    Ekorn's messages users meet; differences for stages; and
    "Upgrading from 2.x", the design's section 10 table, D4.
  - **Corrected:** the 1.x table's right-hand column described v2
    (`all` giving a count, `count`, `single` croaking); it now says
    what happens now. Stop is no longer a class. The Sugar's handle
    in use is an earlier call's iterator, as well as a statement
    handle not read to the end.
  - **Examples:** 81, of which 50 run, each printing what its
    comments say; the 31 not run are usage synopses, or need a server
    or a driver the tests don't have. `xt/howto.t` became
    `xt/examples.t`, running both documents, each as a program of its
    own, D3; CLAUDE.md and MAINTAINING.md name it.
  - **Tests:** `t/23-documented.t`'s subtests follow the sections'
    new names, and "The run's context" pins down D5's contract.
- **Found:** `xt/manuals.t`'s check of links between the manuals
  didn't unescape `E<verbar>`, a `|` in a section's name, so the link
  to the guide's chapter 11 failed it; it does now.
- **What's left:** the README's upgrade note names 1.x only; the
  README is 2026-0019's.
