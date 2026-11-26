# Roadmap

What DBIx-Squirrel means to do, and why. [Changes](Changes) says what
each release did, and the [README](README.md) what it is now.

Last id: 2026-0062.

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

Nothing yet.

## Next

Nothing yet.

## Later

### 2026-0061. is_stage, from a module of DBIx::Squirrel's

**Size:** XS (1). From 2026-0057's D4. **Decisions:** D1 open: which
module exports it. [Record](docs/changes/2026-0061-is-stage.md).

A module of DBIx::Squirrel's exports Ekorn::Pipeline's `is_stage` on
request, so a function taking any number of values, then stages, can
find the stages, and Part 1 can show it.

### 2026-0062. dump_to's setting, without naming Ekorn

**Size:** S (2). From 2026-0057's D5. **Decisions:** D1 open: how it's
set. [Record](docs/changes/2026-0062-dump-to-setting.md).

`dump_to` writes each value in full while
`$Ekorn::Pipeline::Stages::Taps::DumpSecrets` is set, Ekorn's
variable. DBIx::Squirrel gives a way to set it of its own, so Part 1
can say how.

## Ideas

An idea is a numbered heading, the date it was added, its size, and a
line or two on what and why. Each is kept, promoted to Later or Next
with its id, or dropped, as Iain decides.

Nothing yet.
