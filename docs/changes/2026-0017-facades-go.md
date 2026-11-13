# 2026-0017. The facades go

**Status:** shipped, unreleased, on `pipeline-experimental`

**Decisions:** None open. They're 2026-0013's: D1, DBIx::Squirrel::Pipeline
goes; D6, DBIx::Squirrel::Pipes goes, and Gather, Stop and the
`Stages::` modules stay as plain re-exports of Ekorn's functions.

**Origin:** split from [2026-0013](2026-0013-one-design.md), the design
Iain approved on 2026-11-13

**Started:** 2026-11-13

**Finished:** 2026-11-13

## Background

The design's section 9. DBIx::Squirrel::Pipeline and
DBIx::Squirrel::Pipes are subclasses of Ekorn's with no code of their
own, and DBIx::Squirrel::Stop subclasses Ekorn's Stop as well as
re-exporting `Stop`. Ekorn's principle that its users subclass and
wrap nothing of it rules them out, and DBIx::Squirrel uses Ekorn as it
is.

## Decisions

None of its own: they're 2026-0013's, listed above.

## The plan

**What:**

- DBIx::Squirrel::Pipeline goes. Code, tests and docs make pipelines
  with `Ekorn::Pipeline->new`.
- DBIx::Squirrel::Pipes goes. DBIx::Squirrel::db and
  DBIx::Squirrel::st inherit `pipe` and `tap` from
  Ekorn::Pipeline::Pipes.
- DBIx::Squirrel::Stop stays, re-exporting Ekorn's `Stop`, but is no
  longer a subclass: `Ekorn::Pipeline::Stop->throw` in place of
  `DBIx::Squirrel::Stop->throw`.
- Gather and the `Stages::` modules stay as they are, plain
  re-exports.
- `META.json`'s `provides` drops the two modules.

**Why:** DBIx::Squirrel uses Ekorn as it is, subclassing and wrapping
nothing of it.

**Steps:** the modules; their uses in `lib/`; the tests; the
reference, the how-to, the README and the POD; `Changes`.

**Done when:** the two modules are gone and Stop is plain; nothing
checks a pipeline `isa` DBIx::Squirrel::Pipeline; every test passes
against Ekorn's working copy; and coverage meets its floors.

## What happened

- **2026-11-13, outcome:** as planned, against Ekorn's working copy at
  fd541c497274676cb068f5aabccf12810381fead, on its `pipeline-experimental`.
  Every test passes there, against SQLite, MySQL 8.4 and PostgreSQL 18;
  coverage meets its floors.
  - DBIx::Squirrel::Pipeline and DBIx::Squirrel::Pipes are deleted;
    `t/07-namespaces.t` checks they can't be loaded. The handles'
    `@ISA` names Ekorn::Pipeline::Pipes, and `Errors`' `@INTERNAL`
    drops the two, adding DBIx::Squirrel::Stop, which it lacked.
  - DBIx::Squirrel::Stop is a plain re-export: no `@ISA`, so no
    `throw`. A subclass of a stop is a subclass of
    Ekorn::Pipeline::Stop.
  - The tests, the reference, the how-to, the README and the POD make
    pipelines with `Ekorn::Pipeline->new`, and throw with
    `Ekorn::Pipeline::Stop->throw`. `README.md` was made again from
    `README.pod` with `minil build`.
- **Changed from the plan: `META.json` needed nothing,** as it lists no
  modules.
- **What's left:** nothing of this item. The reference's Upgrading
  from 1.x, and a table of what changes for users, are 2026-0019's.
