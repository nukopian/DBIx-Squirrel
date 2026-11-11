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

