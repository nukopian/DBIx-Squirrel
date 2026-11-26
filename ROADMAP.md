# Roadmap

What DBIx-Squirrel means to do, and why. [Changes](Changes) says what
each release did, and the [README](README.md) what it is now.

Last id: 2026-0058.

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

### 2026-0058. The new documents in place of the old

**Size:** XS (1). **Depends on:** 2026-0054, 2026-0055, 2026-0056.

One commit moves `docs/next/`'s README, guide and reference over
today's, which git's history then keeps, and runs `scripts/manuals`;
the tests read `docs/` alone again. Its `Changes` entry is the one
readers see for 2026-0052 to 2026-0056, and says why, as 2026-0052's
record asks: the coupling the documents showed, the synergy the two
parts aim for, and that the split's separation is only now being
completed (2026-0053's D2). Done when `yath test -L t xt` passes on
5.36 and 5.44, and `docs/next/` is gone.

### 2026-0057. What Part 1 still takes from Ekorn::Pipeline's code

**Size:** S (2). **Depends on:** 2026-0058.

Once the documents are split, list what DBIx::Squirrel's Part 1 still
needs from Ekorn::Pipeline, by what a caller sees and what CI checks,
and make an item to cut each link worth cutting. The candidates already
seen: Tooling exporting a stated list of Ekorn's names, not every name
Ekorn's Tooling has, so `xt/ekorn-tooling.t` can go; the range's upper
bound, which makes each minor version of Ekorn's a release of ours;
and a message to Ekorn-Pipeline suggesting a way into its documents
for readers coming from DBIx::Squirrel. Done when each is an item, or
dropped with the reason.

## Ideas

An idea is a numbered heading, the date it was added, its size, and a
line or two on what and why. Each is kept, promoted to Later or Next
with its id, or dropped, as Iain decides.

Nothing yet.
