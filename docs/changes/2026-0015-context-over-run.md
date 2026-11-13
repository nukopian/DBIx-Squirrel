# 2026-0015. Context over Ekorn's run

**Status:** shipped, unreleased, on `pipeline-experimental`

**Decisions:** None open. They're 2026-0013's: D3, `result_number`
and `result_original` kept; D13, `pluck` and `as_hash` croak with no
statement's columns; D21, `pluck` after a reshaping stage, warned of
in the docs.

**Origin:** split from [2026-0013](2026-0013-one-design.md), the design
Iain approved on 2026-11-13

**Started:** 2026-11-13

**Finished:** 2026-11-13

## Background

The design's section 5. DBIx::Squirrel::Context answers a stage from
the iterator running it, which DBIx::Squirrel's iterator sets as it
runs its stages. Since 2026-0014, a statement can be read through `|`
or by a pipeline of the user's own, whose stages Ekorn runs, so no
iterator is set, and `pluck` by name, `as_hash` and `result_original`
have nothing to ask.

## Decisions

None of its own: they're 2026-0013's, listed above.

## The plan

**What:** the statement's source keeps the row it gave last in its
run's context, beside the columns, so `result_original` reads it from
Ekorn's `run_context()`, and is `undef` while `ending()` is true, as
now. `pluck` and `as_hash` take the columns from `run_context()`, and
croak "Expected an iterator, for the column names" where it isn't a
statement's. `result_number` and `iterator` stay as they are: only
where DBIx::Squirrel's iterator runs the stages. The iterator stops
keeping the row itself.

**Why:** so `$it | pluck('name')`, and any pipeline reading a
statement, works as the iterator's own stages do.

**Steps:** the source's context and `result_original`; the columns in
`pluck` and `as_hash`; tests in a user's pipeline and through `|`,
with the iterator's own stages unchanged; the reference, the how-to
and the POD, warning that `pluck` after a reshaping stage reads the
statement's columns, and showing `as_hash`, then `pluck` by name, first
(D21).

**Done when:** `pluck`, `as_hash` and `result_original` work in
`$it | stage` and in a pipeline reading an iterator, with tests; the
docs warn as D21 says; every test passes against Ekorn's working copy;
and coverage meets its floors.

## What happened

- **2026-11-13, outcome:** as planned, against Ekorn's working copy at
  a9e9891f6b9c48544e91e1706cce1cf6b5e46ce0, on its `pipeline-experimental`. Every
  test passes there, against SQLite, MySQL 8.4 and PostgreSQL 18;
  coverage meets its floors (branch 97.4%).
  - The statement's source keeps the row it gave last in its run's
    context, beside the columns, and clears it as the run ends; the
    iterator no longer keeps it.
  - `statement_context`, in DBIx::Squirrel::Context, gives the run's
    context only where it's a statement's, for `result_original` and
    the Rows stages. It's documented as `within` is, as not for use
    elsewhere. Context now cleans its namespace.
  - `pluck`, `as_hash` and `result_original` work through `|` and in
    a pipeline of the user's own; `result_number` and `iterator` are
    `undef` there, and unchanged in the iterator's own stages. Tests
    in `t/26-context-in-pipelines.t`.
  - D21: the reference, the how-to and Rows' POD warn that `pluck`
    reads the statement's columns, and show `as_hash` first, with an
    example the how-to's tests run.
- **Found: `sub {%$_, ...}` is a block, not a hash.** The first
  draft of D21's example returned a list, and `pluck` croaked; running
  the how-to's examples caught it. The examples write `+Ellipsis`.
- **Changed, a little, for a pipeline called inside a stage:** with no
  statement as its source, `result_original` is `undef` in its stages,
  where it was the outer iterator's row. It's the run's row now, and
  that run has none.
- **What's left:** nothing of section 5.
