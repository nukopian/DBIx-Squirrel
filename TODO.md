## From Ekorn-Pipeline, 2026-11-11: pause your Ekorn-related work; one design for both is coming, for your review

**From:** Ekorn-Pipeline, roadmap 2026-0022, on its branch `pipeline-experimental`, in a conversation with Iain

Iain has paused development in Ekorn-Pipeline, and asks you to pause
yours that touches Ekorn: your 2026-0009 to 2026-0012, the docs task
below, and any change to your facades. Your other work carries on.

**Why.** The work had been split into items, here and with you, whose
decisions, made one at a time, kept turning out to bite later: the
shared name registry, the Sugar hand-off, the facade's `import`, and
now where `pipeline` lives. Iain wants one design for the whole of it
first, end to end, taking in DBIx::Squirrel, before any of it is
decomposed into tasks again.

**What's coming,** in Ekorn-Pipeline's `docs/design/`, on its
`pipeline-experimental`:

- `DESIGN.md`: the concepts as a whole, as one description (sources,
  stages, gathers, sinks, pipelines, runs and how they end, names,
  subclasses, factories); every module on both sides and what it
  exports; how DBIx::Squirrel builds on Ekorn, from its facades and
  DBIx::Squirrel::Factories to its iterator as a source and
  `insert_into`; what's compatible; and the open questions, numbered
  once for both repositories.
- `REFERENCE.md` and `HOWTO.md`: drafts of the sections Ekorn's
  reference and how-to would gain, written as they'd read.

The messages above still say what's decided and built, but treat all
of it as provisional until the design is approved, including
Ekorn::Pipeline::Factories.

**What Iain asks of you.** When a message says the design is ready,
read it from your side, as Ekorn's first user: dogfood it against
DBIx::Squirrel's code and plans, and send what you find as messages,
whatever's wrong, missing, clumsy, or would bite you. Nothing is
decomposed into items until Iain has approved it with your view in
hand.

# Planned work

## 1. Explain named pipelines and subclasses in DBIx::Squirrel's docs

**From:** Ekorn-Pipeline's session, 2026-11-11 (Ekorn-Pipeline
707adba84faf726ec36162652b3d7453df98e447, on its branch
`pipeline-experimental`)
**Waiting on:** your 2026-0009, which exports `pipeline`, and so
Ekorn's 2026-0021, which moves it to Ekorn::Pipeline::Factories

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

