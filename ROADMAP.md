# Roadmap

What DBIx-Squirrel means to do, and why. [Changes](Changes) says what
each release did, and the [README](README.md) what it is now.

Last id: 2026-0043.

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

### 2026-0043. as_hash takes the columns to keep

**Size:** S (2).

`as_hash(@names)` keeps only the columns named, matched in any case,
and keyed as `fetchrow_hashref` keys them; with no names, every
column, as now. A name the statement hasn't got croaks. A minor
release. Its [record](docs/changes/2026-0043-as-hash-columns.md) has
the plan and the decisions.

## Next

### 2026-0037. execute_array and execute_for_fetch, for every placeholder style

**Size:** M (3).

`execute_array` fails for `:name` placeholders, and for a placeholder
used twice, where plain DBI's works: our `execute` takes a named
statement's values in pairs, and the driver counts each use of a
placeholder. Make both work for every style we take, with
`bind_param_array` taking names and a hash as a named statement's row,
in v3.3.0. Its decisions are settled, in [its
record](docs/changes/2026-0037-execute-array.md).

### 2026-0036. Appraise Ekorn's feed and tee

**Size:** S (2).

Ekorn-Pipeline's session asked, in two messages of 2026-11-17, for
this one to appraise `$pipeline->feed`, a run fed values as they
arrive (its 2026-0044, at 522fff32146ddabb5d668356c485aa419c2d350f),
and `tee`, a tap that takes a pipeline (its 2026-0048, at
8324858d70742206c98be2fe0e2b34eada7c2fae), for fixes and
opportunities. Both shipped in its v0.3.6, on 2026-11-18. Read its
records and user guide, try both against DBI's ways of handing over
rows, such as callbacks and a writer batching inserts, and send what's
found as messages. Trying `feed` as a loader found 2026-0037.

## Later

### 2026-0032. DBIx::Squirrel::Context on Ekorn's, without the counting stage

**Size:** S (2). **Depends on:** Ekorn-Pipeline 2026-0046, released.

Once Ekorn::Pipeline::Context is out, build `result_number` and
`result_original` on Ekorn's, and drop the stage every iterator with
stages adds to count its results, 11 to 15% a row. Iain won't start
it the week of 2026-11-16. Its questions are open, in [its
record](docs/changes/2026-0032-context-on-ekorn.md).

## Ideas

### 2026-0003. Add-on stage distributions

Added 2026-11-08. Stages for one concern each, in distributions of
their own, as the plan for 2.0 had them: serializers (YAML, XML, CSV,
dumps), decoding columns, types such as dates and booleans,
validation, and progress and logging taps. Those that need no database
may belong in Ekorn::Pipeline's `Ekorn::Pipeline::Stages::` instead.
Split into items, each sized, when one is taken up.

### 2026-0029. Scanning with betterleaks

Added 2026-11-15. Scan for secrets with betterleaks, gitleaks'
successor, in place of gitleaks, which gets no new rules now: in CI's
job over the whole history (`.github/workflows/test.yml`) and in the
scans by hand before a push and a tag (docs/MAINTAINING.md), as
Ekorn-Pipeline's 2026-0039 does there. Two questions when it's taken
up: whether betterleaks reads a `.gitleaksignore`, which the rule on
secrets in messages relies on, and installing it, asking Iain first.
**Origin:** a message from Ekorn-Pipeline, 2026-11-15 (its commit
17f3ac15803cb91a6bb5fb184c2d30c09921b606), whose details are in TODO.md at
62b4c63b98f1efdc8e518e5e4c070985abb8c3a5.
