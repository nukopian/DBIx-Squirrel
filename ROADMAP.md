# Roadmap

What DBIx-Squirrel means to do, and why. [Changes](Changes) says what
each release did, and the [README](README.md) what it is now.

Last id: 2026-0019.

Items come in four groups:

- **Now:** being worked on, each with a paragraph and a link to its
  [change record](docs/changes/README.md); never more than three, so
  that it stays a queue;
- **Next:** decided, but not started: what, why, and when it's done;
- **Later:** meant to be done, but not yet planned, in a line or two;
- **Ideas:** might be done, or never; kept so they aren't lost, in a
  line or two, newest last.

Now, Next and Later put the most useful first.

Each item has an id, its year and a serial, such as 2026-0001. The year
is when the item was added, and the serial counts from 0001, starting
again each year. An id is given when the item is added, whichever group
it goes in, and is kept as the item moves, so that 2026-0001 means the
same item in a commit message years later. It names the item's change
record, its line in Changes ("(roadmap 2026-0001)") and any branch for
it. The line above gives the last id allocated.

Each item has a size too, a guess at how much work it is, as a T-shirt
size and its story points: XS 1, S 2, M 3 and L 5. Sizes compare items
with each other; they aren't a measure of time. An item bigger than L
is split into items that aren't, each saying what it was split from.
An item that can't be done before another says so ("Depends on:"), and
is never in a group ahead of it.

An item whose questions aren't all settled says so, and its record
lists them. Work on it starts only once each is settled, or moved to
another item or task.

When an item ships, it leaves here for Changes. An item that's
dropped is deleted, and the commit that drops it names its id.

## Now

### 2026-0014. The iterator as a source

**Added:** 2026-11-13. **Size:** M (3). **Split from:** 2026-0013

DBIx::Squirrel's iterator becomes a source of Ekorn::Pipeline's, its
stages run by Ekorn, reading only as many rows as it needs: the design's
section 4. The spike for its Q30 built most of it on
`pipeline-experimental`; what's left is `ended`, `|` and `@{}`, and
results as objects through it. Its [record](docs/changes/2026-0014-iterator-as-source.md)
has the plan.

## Next

### 2026-0015. Context over Ekorn's run

**Added:** 2026-11-13. **Size:** S (2). **Split from:** 2026-0013.
**Depends on:** 2026-0014

What: DBIx::Squirrel::Context and the stages `pluck` and `as_hash` ask
Ekorn's `run_context()` and `ending()`, as the design's section 5 has
it: the columns, and the row a value came from, from the statement's
context, so they work in a user's own pipeline too; `result_number`
and `iterator` only where DBIx::Squirrel's iterator runs the stages.
Why: a statement read through `|` has its stages run by Ekorn, not by
DBIx::Squirrel. Done when: `pluck`, `as_hash` and `result_original`
work in `$it | stage`, with tests, and the docs warn that `pluck` after
a stage that reshapes rows reads the statement's columns (D21).

### 2026-0016. Runs that end in a sink

**Added:** 2026-11-13. **Size:** M (3). **Split from:** 2026-0013.
**Depends on:** 2026-0014

What: a call taking stages gives a sink's result when its last stage is
one, as the design's section 6 has it: `iterate`, `results`, the Sugar's
statements, and the `select` methods, which take stages and push the
DBI's result through them (D18). Without a sink, DBIx::Squirrel's own
calls give an iterator, the Sugar's statements included (D16). Why: a
sink given last says what comes back, so no call lists or counts by its
calling context. Done when: each call does so, with tests, and section
10's table of what changes for users holds.

### 2026-0017. The facades go

**Added:** 2026-11-13. **Size:** S (2). **Split from:** 2026-0013

What: DBIx::Squirrel::Pipeline and DBIx::Squirrel::Pipes go; `db` and
`st` take `pipe` and `tap` from Ekorn::Pipeline::Pipes; Stop, Gather and
the `Stages::` modules stay as plain re-exports of Ekorn's functions
(D1, D6), as the design's section 9 has it. Why: DBIx::Squirrel uses
Ekorn as it is, subclassing and wrapping nothing of it. Done when: the
modules are gone or plain, their tests and docs follow, and nothing
checks a pipeline `isa` DBIx::Squirrel::Pipeline.

### 2026-0018. Pipelines named in the Sugar's definitions

**Added:** 2026-11-13. **Size:** M (3). **Split from:** 2026-0013.
**Depends on:** 2026-0017

What: a statement's definition in DBIx::Squirrel::Sugar can name
pipelines, as `[music => $sql, clean => trim =>]`, resolved with
Ekorn's `pipeline_in` in the package that used the Sugar, as the
design's section 8 has it (Ekorn's D36). It replaces 2026-0010, a
`pipeline` key of the Sugar's own. Why: names are Ekorn's, so the Sugar
uses them rather than defining pipelines itself. Done when: a
definition's names resolve, a string given when a statement is called
stays a bind value, and the docs show it, the reference's entry for
"Pipeline stage #%s failed" with the name of a named pipeline (Ekorn's
2026-0013).

### 2026-0019. DBIx::Squirrel v3.0.0

**Added:** 2026-11-13. **Size:** L (5). **Split from:** 2026-0013.
**Depends on:** 2026-0014, 2026-0015, 2026-0016, 2026-0017,
2026-0018, and Ekorn::Pipeline v0.3.0 on CPAN

What: the release on Ekorn::Pipeline v0.3.0, as the design's sections
10, 11 and 15 have it: the README, reference and how-to rewritten,
with `|` giving one value explained where it's first shown; a table of
what changes for users and how they move; `Changes`' precis; the
`cpanfile`'s range, `>= v0.3.0, < v0.4.0`; and CI. Why: it breaks code,
which a major version is for. Done when: v3.0.0 is on CPAN.

## Later

### 2026-0003. Add-on stage distributions

**Added:** 2026-11-08. **Size:** L (5)

Stages for one concern each, in distributions of their own after 2.0,
as the plan for 2.0 had them: serializers (JSON, YAML, XML, CSV,
dumps), decoding columns, types such as dates and booleans,
validation, and progress and logging taps. Those that need no database
may belong in Ekorn::Pipeline's `Ekorn::Pipeline::Stages::` instead.
Split into items, each sized, when one is taken up.

## Ideas

Nothing yet.
