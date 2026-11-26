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

### 2026-0052. Two parts: DBIx::Squirrel, then Ekorn::Pipeline

**Size:** S (2). **Decisions:** D1 settled: Part 1 is DBIx::Squirrel,
complete; Part 2 is Ekorn::Pipeline, by choice. D2 settled: Ekorn's
names are those imported from its modules, and Tooling goes to Part 2
whole. D3 settled: a divider heading for each part, "Part 1:
DBIx::Squirrel" and "Part 2: With Ekorn::Pipeline"; the chapters keep
theirs, numbered on through both. D4 settled: Part 1 names what it
asks a reader to learn, and ends where they may stop. D5 settled: an
author test keeps Ekorn's names out of Part 1. D6 settled: the new
documents are written in `docs/next/`, and today's are kept untouched
until they're swapped in (2026-0058). D7 settled: success is
measured by the D5 test, a cold reader given Part 1 alone and then
both parts, coupling before and after, and Iain's sceptical review;
the README and the guide carry the sales pitch, for sceptical and
enthusiastic readers alike; amended after a first review, with the
cold reader's tasks, and every claimed gain shown in code. D8 open:
the smallest description of DBIx::Squirrel that stays true if
Ekorn::Pipeline disappeared, as Part 1's foundation, leading with
control of SQL.
[Record](docs/changes/2026-0052-two-parts.md).

**What:** where the line between the two parts falls, the same in the
README, the guide and the reference, and how it's kept; and `docs/next/` made ready for the new documents,
with `xt/examples.t` and `xt/spelling.t` reading it too. The D5 test
comes with the first document written, 2026-0054. The cold reader
(D7) is run on today's documents, for a baseline.

**Why:** the documents tell DBIx::Squirrel's story in Ekorn::Pipeline's
words: `keep_all` comes up more often than the iterator's `->all` in
the README. So the two distributions read as tightly coupled, which is
what the split was meant to escape, and a reader must learn both to
follow either. Told in two parts, DBIx::Squirrel is complete in
itself, and Ekorn::Pipeline is a choice that builds on it: synergy,
not dependency.

**Done when:** `xt/examples.t` and `xt/spelling.t` read `docs/next/`
as they read `docs/`, `yath test -L xt` passes, the cold reader's
baseline is in the record, and D8 is settled.

### 2026-0053. Why Ekorn::Pipeline split from DBIx::Squirrel

**Size:** S (2). **Decisions:** D1 open: the reasons, from Iain; where
the pipeline came from is settled, 1.x's transformations. D2 open:
told in full once, at the opening of the guide's Part 2.
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

`docs/next/README.pod`, by 2026-0052. Part 1 opens with 2026-0052's
D8, then shows DBIx::Squirrel with its own iterator, its gains in
pairs, plain DBI beside DBIx::Squirrel, for work a DBI user does every
week. Part 2 is a paragraph on Ekorn::Pipeline, a sentence on why the
two split, and links on. The first document written, so the test from
2026-0052's D5 comes with it, failing where a document's Part 1 names
one of Ekorn's names. Done when that test and `xt/examples.t` pass on
it.

### 2026-0055. The guide in two parts

**Size:** L (5). **Depends on:** 2026-0052, 2026-0053.

`docs/next/HOWTO.md`, by 2026-0052, from `docs/HOWTO.md`. Part 1 is
the round trip to the database. It opens with 2026-0052's D8, shows
each gain in a pair, plain DBI beside DBIx::Squirrel, and says what
comes back with the iterator's methods; the diagram in "The layers, at
a glance" ends at the iterator, and "Import everything from one place"
moves on. Part 2 is data crossing the database's edge. It opens with
why the two split (2026-0053), then the recipes that put them
together: sinks, files, JSON and CSV, `feed` for loading in batches,
`tee`, and pipelines built from pipelines. Done when the 2026-0052
test and `xt/examples.t` pass on it.

### 2026-0056. The reference in two parts

**Size:** L (5). **Depends on:** 2026-0052, 2026-0053.

`docs/next/REFERENCE.md`, by 2026-0052, from `docs/REFERENCE.md`, its
index too: Tooling and the 25 names it exports from Ekorn::Pipeline
(2026-0051) go to Part 2, where the reason they're there is said, with
a sentence on the split and a link to the guide's telling of it. Done when the 2026-0052 test,
`xt/examples.t` and `xt/reference-index.t` pass on it.

### 2026-0058. The new documents in place of the old

**Size:** XS (1). **Depends on:** 2026-0054, 2026-0055, 2026-0056.

One commit moves `docs/next/`'s README, guide and reference over
today's, which git's history then keeps, and runs `scripts/manuals`;
the tests read `docs/` alone again. Its `Changes` entry is the one
readers see for 2026-0052 to 2026-0056, and says why, as 2026-0052's
record asks: the coupling the documents showed, and the synergy the
two parts aim for. Done when `yath test -L t xt` passes on 5.36 and
5.44, and `docs/next/` is gone.

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
