# Change records

How each planned change to DBIx-Squirrel went: its decisions, the
plan as it was written, then what happened. [Changes](../../Changes)
says what changed for users; a record keeps the thinking behind it,
for anyone looking back, including whoever plans the next change.

A record is opened for a [roadmap](../../ROADMAP.md) item when it
first has a question to settle, or when work on it starts, and for a
task in `TODO.md` with steps. A planned change that's dropped keeps its
record, saying why, as dead ends are the history most worth having.
Small fixes don't need one.

## How a record is kept

- **It's named for its id, then the change,** such as
  `2026-0001-stages-method.md`. A roadmap item's id is the item's; a
  `TODO.md` task's record takes the next id from the roadmap's opening,
  in the same sequence, though the task never appears there. So records
  sort in the order their ids were given, and their names line up.
- **Its questions are settled first.** Each is numbered in Decisions,
  unchecked while open. Once settled, in the chat with Iain, it's
  checked, with the answer, the date and why. Work starts only once
  each is checked, or moved to another item or task, which the record
  says. A **Decisions:** line under the status sums them up, each
  settled or open in a few words, so the record's state shows at a
  glance; it changes in the commit that settles one.
- **The plan is written when work starts, and isn't edited after.**
  What changed goes under What happened, so the record shows how the
  plan held up.
- **What happened is added as the work goes,** and finished when the
  change ships or is dropped, in the same commit. When it ships, the
  status says "shipped, unreleased", and the release names its version.
- **It's public,** on GitHub and `main`, though not in the CPAN
  tarball, so nothing personal goes in it. There's no PDF of it.

## The template

```markdown
# 2026-0001. Title

**Status:** open | in progress | shipped, unreleased | shipped in v2.0.3 | dropped

**Decisions:** D1 settled: the answer, in a few words. D2 open: the question, in a few words. | None.

**Origin:** roadmap, added 2026-11-07 | a TODO task from Ekorn-Pipeline's session (Ekorn-Pipeline <commit>) | a message from Ekorn-Pipeline's session, 2026-11-08 (Ekorn-Pipeline <commit>)

**Depends on:** 2026-0003, if anything

**Started:** 2026-11-08, in <commit>

**Finished:** 2026-11-09

## Background

What's known before the plan: the problem, what was tried, and what it
showed.

## Decisions

- [x] **D1.** The question? The answer, on 2026-11-07, and why.
- [ ] **D2.** A question still open? The options, and the
  recommendation.

## The plan

The plan as it was when work started, word for word: What, Why,
Steps, Done when.

## What happened

- **Outcome:** against Done when.
- **Changes from the plan,** and why.
- **Measurements,** and how they were taken.
- **Tried and reverted,** with the numbers.
- **What's left,** linked to its roadmap item or `TODO.md` task.
```

## Records

Newest id first.

- [Pipelines named in the Sugar's definitions](2026-0018-sugar-names-pipelines.md),
  roadmap 2026-0018: shipped, unreleased.
- [The facades go](2026-0017-facades-go.md),
  roadmap 2026-0017: shipped, unreleased.
- [Runs that end in a sink](2026-0016-runs-ending-in-a-sink.md),
  roadmap 2026-0016: shipped, unreleased.
- [Context over Ekorn's run](2026-0015-context-over-run.md),
  roadmap 2026-0015: shipped, unreleased.
- [The iterator as a source](2026-0014-iterator-as-source.md),
  roadmap 2026-0014: shipped, unreleased.
- [DBIx::Squirrel on Ekorn as it is: one design](2026-0013-one-design.md),
  from a task of Ekorn-Pipeline's: split into 2026-0014 to 2026-0019.
- [Export Ekorn's pipeline()](2026-0009-export-pipeline.md),
  roadmap 2026-0009: dropped.
- [A how-to that answers a newcomer's questions](2026-0008-howto-for-newcomers.md),
  roadmap 2026-0008: shipped in v2.1.0.
- [Every claim in the reference, checked](2026-0007-reference-audit.md),
  roadmap 2026-0007: shipped in v2.1.0.
- [Ekorn::Pipeline v0.2.0's two messages](2026-0006-ekorn-v0.2.0-messages.md),
  from a task of Ekorn-Pipeline's: shipped in v2.1.0.
- [Plain docs](2026-0005-plain-docs.md), roadmap 2026-0005: shipped in v2.1.0.
- [A pipeline where a stage goes](2026-0004-pipeline-as-stage.md),
  from a task of Ekorn-Pipeline's: shipped in v2.1.0.
- [Link to Ekorn::Pipeline's manuals by module name](2026-0002-ekorn-manual-links.md),
  roadmap 2026-0002: shipped in v2.1.0.
- [The reference and the how-to on MetaCPAN](2026-0001-manuals-on-metacpan.md),
  roadmap 2026-0001: shipped in v2.0.5.
