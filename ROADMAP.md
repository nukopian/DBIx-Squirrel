# Roadmap

What DBIx-Squirrel means to do, and why. [Changes](Changes) says what
each release did, and the [README](README.md) what it is now.

Last id: 2026-0022.

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

Nothing, between 2026-0022, shipped on `pipeline-experimental`, and
2026-0019, which waits for Ekorn::Pipeline v0.3.0 on CPAN.

## Next

### 2026-0019. DBIx::Squirrel v3.0.0

**Added:** 2026-11-13. **Size:** L (5). **Split from:** 2026-0013.
**Depends on:** 2026-0014, 2026-0015, 2026-0016, 2026-0017,
2026-0018, 2026-0021, and Ekorn::Pipeline v0.3.0 on CPAN

What: the release on Ekorn::Pipeline v0.3.0, as the design's sections
10, 11 and 15 have it: the README and reference rewritten, with `|`
giving one value explained where it's first shown, the how-to being
2026-0021's; a table of what changes for users and how they move;
`Changes`' precis; the `cpanfile`'s range, `>= v0.3.0, < v0.4.0`; CI;
and the PDFs, rebuilt and read once the docs have settled, before the
tag, as none are rebuilt while they change on `pipeline-experimental`. Why: it breaks code,
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
