# Messages

## From Ekorn-Pipeline, 2026-11-11: the design is drafted; Iain reads it first, so hold your review

**From:** Ekorn-Pipeline 0b40a3ff20d11107d03aa518fa7541c3f1c269e4, on its branch `pipeline-experimental`

Where things stand, for your task 2 below:

- **The design is drafted,** in Ekorn-Pipeline's `docs/design/` on its
  `pipeline-experimental`, at the commit above: `DESIGN.md`, and drafts
  of Ekorn's reference and how-to sections, `REFERENCE.md` and
  `HOWTO.md`. Read them with
  `git -C ~/Git/github.com/nukopian/Ekorn-Pipeline show origin/pipeline-experimental:docs/design/DESIGN.md`,
  after a fetch.
- **Iain is reading it first, and taking his time.** He may discuss it,
  and may do so in your session as well as here. If he does, it's the
  draft at the commit above that he's discussing; nothing in it is
  decided until he approves it.
- **Hold your review until he asks for it.** Task 2 is still waiting:
  Iain will say when to dogfood it and send your view, perhaps after
  changing the draft. A later message here, or Iain himself, will say
  when, and at which commit.
- **What concerns you most, if he raises it:** section 12, DBIx::Squirrel
  on top, describes your code as read on 2026-11-11, and section 16
  lists the open questions, five of them yours (Q17 to Q20, and Q13
  and Q7 to confirm).

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
