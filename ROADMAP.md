# Roadmap

What DBIx-Squirrel means to do, and why. [Changes](Changes) says what
each release did, and the [README](README.md) what it is now.

Last id: 2026-0005.

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

### 2026-0005. Plain docs

**Added:** 2026-11-09. **Size:** L (5). **Depends on:** 2026-0004

A pass over the README, every module's POD, the reference, the
how-to and MAINTAINING, in shorter sentences, keeping what they say,
the examples, the DIAGNOSTICS entries and the anchors. It's on a
branch from 2026-0004's, so it reaches `develop` after it. Its
[record](docs/changes/2026-0005-plain-docs.md) has the rules.

## Next

Nothing yet.

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
