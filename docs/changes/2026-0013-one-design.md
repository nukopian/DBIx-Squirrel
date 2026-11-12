# 2026-0013. DBIx::Squirrel on Ekorn as it is: one design

**Status:** in progress

**Decisions:** D1 settled: `DBIx::Squirrel::Pipeline` goes. D2
settled: v3.0.0. D3 settled: keep `result_number` and
`result_original`. D4 settled: a fresh run from `ekorn_source`. D5
settled: `insert_into` begins a transaction only with `AutoCommit`
on. D6 settled: the facades are plain re-exports. D7 settled: test
locally first, CI later. D8 settled: Ekorn renamed its role methods,
so a bind value is never taken for a stage. Six questions open, in the
design's section 13.1.

**Origin:** a TODO task from Ekorn-Pipeline's session, 2026-11-12
(Ekorn-Pipeline 43e2b0629fd89ef6fd990b9765b74d099b1f5210)

**Depends on:** Ekorn-Pipeline 2026-0022, its one design

**Started:** 2026-11-12, on `pipeline-experimental`

## Background

Ekorn-Pipeline settled a design for both repositories, its 2026-0022:
DBIx::Squirrel uses Ekorn as any other package would, and subclasses,
wraps and remakes nothing of it. Task 3 asks DBIx-Squirrel to review
it as Ekorn's first user, send what it finds as messages, and design
its own side, in [docs/design/DESIGN.md](../design/DESIGN.md).

Reviewed at Ekorn-Pipeline a75d178e4becfd1c3b6c57194bf6c111dabb8b98,
on 2026-11-12:

- Against it, 25 of DBIx::Squirrel's 26 test files pass. `t/06-gather.t`
  fails two subtests, both v0.3.0's intended changes.
- `is_stage` takes a bind value with an `as_list` method for a sink,
  which breaks a working call. Tried with a class of one method.
- An overload of `|` naming Operators' `chain` dies with "Undefined
  subroutine" until Operators is loaded.
- Ekorn's section 12 leaves out `result_number` and `result_original`.

Each went to Ekorn-Pipeline as a message, with small corrections to
its section 12.3 (Ekorn-Pipeline
7d4bd8f95f05675635e2d39312987ca1da1d934f).

## Decisions

- [x] **D1.** Keep `DBIx::Squirrel::Pipeline`? No, Iain decided on
  2026-11-12. It's a subclass with no code, which Ekorn's principle 2
  rules out, and the docs show `Ekorn::Pipeline->new` and `pipeline`
  instead. Weighed: keeping it as a name that makes Ekorn's pipelines,
  which is a wrapper by another name.
- [x] **D2.** The version? v3.0.0, Iain decided on 2026-11-12, as
  dropping the class breaks code that names it, and stages become
  objects with Ekorn v0.3.0.
- [x] **D3.** Keep `result_number` and `result_original`? Yes, Iain
  decided on 2026-11-12. `result_original` comes from the statement's
  source, as the row it fetched last, kept in the run's context, so it
  works in a user's own pipeline too. `result_number` works only where
  DBIx::Squirrel's own iterator runs the stages. Weighed: dropping
  both, which the reference and the how-to use.
- [x] **D4.** An iterator used as a source after `next`? A fresh run,
  from the first row, Iain decided on 2026-11-12, as Ekorn's D44
  implies. It croaks only if another of DBIx::Squirrel's iterators is
  part-way through the handle, as `reset` does today. Weighed: going
  on from where `next` left off, which would make one iterator two
  runs at once; and croaking whenever the handle is active, as Ekorn
  12.3 had it, which would break code that works today.
- [x] **D5.** `insert_into` and a transaction already begun, or
  `AutoCommit` off? It begins and commits a transaction only with
  `AutoCommit` on, and otherwise leaves it to the user, Iain decided
  on 2026-11-12. He added that he isn't bothered about keeping
  `insert_into`, and is more interested in result sinks (the design's
  Q11 and section 6).
- [x] **D6.** The facades? `Gather`, `Stop` and the `Stages::*`
  modules stay as plain re-exports of Ekorn's functions, as Ekorn's
  D31 allows; `Pipes` goes, as the handles use Ekorn's Pipes directly,
  Iain decided on 2026-11-12.
- [x] **D7.** CI against Ekorn's `pipeline-experimental`? Yes, Iain
  decided on 2026-11-12, but he'd rather nail things down locally
  first: tested against Ekorn's working copy, and CI once the two
  designs are settled.
- [x] **D8.** `is_stage` took a bind value with an `as_list` method for
  a sink. Ekorn-Pipeline settled it on 2026-11-12, its D49, by renaming
  its role methods `ekorn_source`, `ekorn_stage`, `ekorn_sink` and
  `ekorn_sink_scalar` (Ekorn-Pipeline
  8ce1c95b6a3bb6b7c4052374c67660491416686a). Checked against that
  commit: the bind value stays one, and the query gives its row.
  DBIx::Squirrel adds a test of it when the work is built.

## The plan

Written when the design is approved and split into items.

## What happened

- **2026-11-12:** the review's findings sent to Ekorn-Pipeline, and the
  design drafted, with its open questions, for Iain.
- **2026-11-12:** Ekorn-Pipeline took in all four findings (its message,
  Ekorn-Pipeline 8ce1c95b6a3bb6b7c4052374c67660491416686a): the role
  methods renamed, Operators loaded with an empty import list to
  overload with its functions, `result_number` and `result_original`
  named as DBIx::Squirrel's, and 12.3 corrected. The design is brought
  up to date with it. Against that commit, DBIx::Squirrel's tests stand
  as before: 25 of 26 files pass, and `t/06-gather.t`'s two failures
  are v0.3.0's intended changes.
