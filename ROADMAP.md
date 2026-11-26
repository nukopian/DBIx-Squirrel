# Roadmap

What DBIx-Squirrel means to do, and why. [Changes](Changes) says what
each release did, and the [README](README.md) what it is now.

Last id: 2026-0057.

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

### 2026-0052. Two parts: DBIx::Squirrel, then Ekorn::Pipeline

**Size:** S (2). **Decisions:** D1 settled: Part 1 is DBIx::Squirrel,
complete; Part 2 is Ekorn::Pipeline, by choice. D2 to D5 open: which
names are Ekorn's, how the parts are marked, what Part 1 says it asks
and where it ends, and a test keeping the line.
[Record](docs/changes/2026-0052-two-parts.md).

**What:** where the line between the two parts falls, the same in the
README, the guide and the reference, and how it's kept.

**Why:** the documents tell DBIx::Squirrel's story in Ekorn::Pipeline's
words: `keep_all` comes up more often than the iterator's `->all` in
the README. So the two distributions read as tightly coupled, which is
what the split was meant to escape, and a reader must learn both to
follow either. Told in two parts, DBIx::Squirrel is complete in
itself, and Ekorn::Pipeline is a choice that builds on it: synergy,
not dependency.

**Done when:** D2 to D5 are settled, so 2026-0054 to 2026-0056 can
split each document by them.

### 2026-0053. Why Ekorn::Pipeline split from DBIx::Squirrel

**Size:** S (2). **Decisions:** D1 open: the reasons, from Iain. D2
open: told in full once, at the opening of the guide's Part 2.
[Record](docs/changes/2026-0053-why-the-split.md).

**What:** the story of the split: why the pipeline left DBIx::Squirrel
for a distribution of its own, and what a reader gains by putting the
two back together.

**Why:** it's what makes Part 2 read as two pieces recombined on
purpose, not a dependency explained after the fact. The documents now
say what changed for a caller at each version, but not why.

**Done when:** the text is written, ready for 2026-0055 to place.


## Later

### 2026-0054. The README in two parts

**Size:** S (2). **Depends on:** 2026-0052, 2026-0053.

The README by 2026-0052: Part 1 shows DBIx::Squirrel with its own
iterator, and Part 2 is a paragraph on Ekorn::Pipeline, a sentence on
why the two split, and links on. The first document split, so the
test from 2026-0052's D5 comes with it. Done when that test passes on
the README, and `xt/examples.t` and `xt/manuals.t` do.

### 2026-0055. The guide in two parts

**Size:** L (5). **Depends on:** 2026-0052, 2026-0053.

`docs/HOWTO.md` by 2026-0052. Part 1 says what comes back with the
iterator's methods; the diagram in "The layers, at a glance" ends at
the iterator, and "Import everything from one place" moves on. Part 2
opens with why the two split (2026-0053), then the recipes that put
them together: sinks, files, JSON and CSV, `feed` for loading in
batches, `tee`, and pipelines built from pipelines. Done when the
2026-0052 test, `xt/examples.t` and `xt/manuals.t` pass.

### 2026-0056. The reference in two parts

**Size:** L (5). **Depends on:** 2026-0052, 2026-0053.

`docs/REFERENCE.md` by 2026-0052, its index too: Tooling and the 25
names it exports from Ekorn::Pipeline (2026-0051) go to Part 2, where
the reason they're there is said, with a sentence on the split and a
link to the guide's telling of it. Done when the 2026-0052 test,
`xt/reference-index.t`, `xt/examples.t` and `xt/manuals.t` pass.

### 2026-0057. What Part 1 still takes from Ekorn::Pipeline's code

**Size:** S (2). **Depends on:** 2026-0054, 2026-0055, 2026-0056.

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
