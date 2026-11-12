# Messages

## From Ekorn-Pipeline, 2026-11-12: the design is ready for you; task 3 replaces task 2, and task 1 is overtaken

**From:** Ekorn-Pipeline 43e2b0629fd89ef6fd990b9765b74d099b1f5210, on its branch `pipeline-experimental`

Iain has settled every question in Ekorn's design (its section 16;
decisions D1 to D48 in its change record,
`docs/changes/2026-0022-one-design.md`), had it proved by a prototype
in Ekorn's code, and reviewed cold five times. He now wants
DBIx-Squirrel's review and design: that's task 3, below.

- **Task 2 is replaced by task 3,** which does what it asked and more.
  Drop it in the commit that adds your design, saying so.
- **Task 1 is overtaken,** and can be dropped, with Iain's say-so:
  Ekorn's names are per package again, not per class (D1, the design's
  17.4), DBIx::Squirrel no longer has a Pipeline subclass or names of
  its own, and `pipeline` lives in Ekorn::Pipeline::Factories only
  (D30).
- **The message below, of 2026-11-11, is stale:** its question numbers
  and shapes have all changed. Remove it once you've read this.

## From Ekorn-Pipeline, 2026-11-11: the design is revised; your task 2's commit and question numbers have changed

**From:** Ekorn-Pipeline 1db11e6f30e8eeb61689fdff93885b7a6686ad8d, on its branch `pipeline-experimental`

Iain is still reading the design, and your task 2 still waits on him.
But the draft has changed since 0b40a3ff20d11107d03aa518fa7541c3f1c269e4,
which the task names, so read it at the commit above, or whatever is
latest on Ekorn's `pipeline-experimental` when Iain asks:

- **`source`, `sink` and `gather` take one shape:** the block is a
  set-up, run at the start of each run, which declares the run's state
  with `my` and returns the step and the end as closures sharing it, as
  `gather` does today. There are no `step` and `end` words. `gather` is
  unchanged; only sources and sinks get ends that always run and are
  told how the run ended. Your `insert_into` (its section 12.4) is
  shown that way.
- **A new section 17, "Decisions, and what was weighed",** gives the
  reasons for each settled decision and what was set aside.
- **The ready-made sources are named for what they take:**
  `from_array`, `from_arrayref`, `from_hash`, `from_hashref`, `from_fh`
  and `from_file`, the last two reading records as `$/` divides them.
- **The open questions are renumbered,** Q1 to Q20. Yours are now
  **Q15 to Q18** (DBIx::Squirrel::Factories' words, the Iterator as a
  source, the Sugar naming pipelines in statements, your CI), with
  **Q7** (an abandoned iterator ends its run) and **Q12** (canned
  stages as objects) to confirm.

# Planned work

## 1. Explain named pipelines and subclasses in DBIx::Squirrel's docs

**From:** Ekorn-Pipeline's session, 2026-11-11 (Ekorn-Pipeline
707adba84faf726ec36162652b3d7453df98e447, on its branch
`pipeline-experimental`)
**Waiting on:** your 2026-0009, which exports `pipeline`, and so
Ekorn's 2026-0021, which moves it to Ekorn::Pipeline::Factories; and,
before either, Iain's approval of one design for both (Ekorn's
2026-0022)

**What:** when your docs first show `pipeline` and named pipelines,
spell out in plain English, and in the same detail as Ekorn's
messages of 2026-11-11, kept in the
[record for 2026-0009](docs/changes/2026-0009-export-pipeline.md), how
names behave for DBIx::Squirrel's users: that they define
names through `DBIx::Squirrel::Pipeline->named`; that their `pipeline`
finds DBIx::Squirrel's names and Ekorn's, nearest first; that Ekorn's
own `pipeline` never finds theirs; that they can override one of
Ekorn's names, and a pipeline made before keeps what it found; and
that a class can't define a name twice. Iain asked, on 2026-11-11, that
both repositories spell it out, not only Ekorn's.

**Why:** a user of DBIx::Squirrel who also uses Ekorn::Pipeline
directly sees two `pipeline` functions that find different names, and
needs to be told why, in your reference and how-to, not only in
Ekorn's.

Write the calls as the record says: `pipeline('clean', take(5))`,
with plain commas, and `named(clean => sub {...})`, with the long
comma.

**Done when:** your reference, and your how-to's recipe for named
pipelines if it has one, explain the five rules with an example that
runs as its comments say, with `pipeline` and `named` calls written as
above; and your Ekorn manual links point to Ekorn's "Named pipelines
and subclasses" for the rest.

## 2. Review Ekorn's design for both repositories, from DBIx::Squirrel's side

**From:** Ekorn-Pipeline's message of 2026-11-11 (Ekorn-Pipeline
d1ecb45c613e526292964b8d78b6d258ff794aa7, here; its roadmap 2026-0022)
**Waiting on:** Iain, who reads the drafted design first (Ekorn-Pipeline
0b40a3ff20d11107d03aa518fa7541c3f1c269e4), and will say when to review it

The draft is in Ekorn-Pipeline's `docs/design/` (`DESIGN.md`,
`REFERENCE.md`, `HOWTO.md`), on its `pipeline-experimental`. Iain may
change it before asking; he, or a message from Ekorn-Pipeline, will say
at which commit. If he discusses it here first, it's the draft at that
commit, and nothing in it is decided until he approves it. Section 12
describes DBIx::Squirrel's code as read on 2026-11-11, and of section
16's open questions, Q17 to Q20 are DBIx-Squirrel's, with Q7 and Q13
to confirm.

**What:** Iain paused development in Ekorn-Pipeline, and DBIx-Squirrel's
work touching Ekorn: 2026-0009 to 2026-0012, task 1 above, and any
change to the facades. Other work carries on. Decisions made one item
at a time kept biting later (the shared name registry, the Sugar
hand-off, the facade's `import`, where `pipeline` lives), so Iain wants
one design for the whole of it, end to end, before it's split into
items again. It's coming in Ekorn-Pipeline's `docs/design/`, on its
`pipeline-experimental`: `DESIGN.md` (the concepts as one description;
every module on both sides and what it exports; how DBIx::Squirrel
builds on Ekorn, from its facades and DBIx::Squirrel::Factories to its
iterator as a source and `insert_into`; what's compatible; and the open
questions, numbered once for both), with drafts of Ekorn's
`REFERENCE.md` and `HOWTO.md` sections. Everything decided so far,
Ekorn::Pipeline::Factories included, is provisional until it's
approved.

**Steps:** read it as Ekorn's first user. Dogfood it against
DBIx::Squirrel's code (its facades, Iterator, Sugar, Pipes, Stop, Util)
and its plans (2026-0009 to 2026-0012 and their records), and send what
you find to Ekorn-Pipeline as messages: whatever's wrong, missing,
clumsy, or would bite.

**Done when:** the messages are sent, and Iain has what he needs to
approve the design. Nothing is split into items until he has.
