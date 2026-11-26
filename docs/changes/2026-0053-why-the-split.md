# 2026-0053. Why Ekorn::Pipeline split from DBIx::Squirrel

**Status:** shipped, unreleased

**Decisions:** D1 settled: a separation of concerns, the pipeline
useful beyond databases; principle, not pain; the text is in D1. D2
settled: told in full once, at the opening of the guide's Part 2; "only
now completed" goes in 2026-0058's `Changes` entry.

**Origin:** roadmap, added 2026-11-26

**Finished:** 2026-11-26

## Background

The pipeline began in DBIx::Squirrel 1.x, as transformations:
`$dbh->iterate($sql, [@bind_values, @transforms])` ran each row
through functions that could change it, drop it or turn it into
several, before Ekorn::Pipeline existed. Stages are those
transformations by a new name ("Transformations, now stages", in the
reference's "Upgrading from 1.x"), and Ekorn::Pipeline grew from the
same idea, made general, for values from anywhere, not only rows. So
transforming rows beside the query is DBIx::Squirrel's own idea, as
Iain confirmed on 2026-11-26. It answers a question from the first
sceptical review of 2026-0052's plan, whether DBIx::Squirrel has
stages only because Ekorn::Pipeline does.

The review asked that the account be pinned to a primary source, so
it doesn't become folklore. DBIx::Squirrel 1.6.5, the last of 1.x,
still on CPAN (CPANIC/DBIx-Squirrel-1.6.5, 2025-04-18), says in
`lib/DBIx/Squirrel.pod`, under DESCRIPTION:

> Just as with the DBI, all database queries are crafted with SQL,
> keeping you close to the data. With its built-in support for named,
> positional and legacy parameter placeholders, DBIx-Squirrel makes
> the task of crafting that SQL a lot less bothersome, while its
> iterators and transformations offer a clean and elegant way to
> process results.
>
> Most comforting of all, everything that could be done with the DBI
> can still be done using DBIx-Squirrel.

And under TRANSFORMING RESULTS:

> All `DBIx::Squirrel` iterators support an optional processing step
> called *transformation*.
>
> Transformation can be summarised as the automatic, just-in-time
> processing, re-shaping or filtering of results, as they are fetched
> from the database and before they are handed-off to the caller.
>
> A transformation is comprised of one or more processing stages.

It goes on to call `[@transforms]` "the transformation pipeline", and
says that returning nothing from a stage "will filter the result out
entirely". So 1.x had iterators, a pipeline and its stages, by those
names. Its `Changes` has an example script for transformations in
1.2.8, on 2024-08-16, the same day as 1.2.7, "First version, released
on an unsuspecting world". Ekorn::Pipeline's first release was
v0.1.0-TRIAL, on 2026-11-07, according to MetaCPAN.

1.6.5's DESCRIPTION is close to 2026-0052's D8, two years apart: SQL
kept close, placeholders made less bothersome, iterators and
transformations for results, and everything the DBI does still done.

DBIx::Squirrel 2's trials, v2.0.0 to v2.0.4 (2026-11-05 to
2026-11-08), carried the pipeline as their own. Ekorn-Pipeline's first
commit, 0b45ac977eac8dba7d59562267e04d4895f1037d on 2026-11-07, took
it from DBIx-Squirrel at v2.0.2
(5e30135672d8002b0bb67ba68278e5b1c262df8b), renamed from
`DBIx::Squirrel::*` to `Ekorn::Pipeline::*` with the code unchanged,
leaving behind what needs the DBI or DBIx::Squirrel's iterators: the
run's context, and the stages for rows. Ekorn::Pipeline v0.1.0-TRIAL
came out the same day. From v2.0.5, 2.x's first full release, on
2026-11-08, DBIx::Squirrel used Ekorn::Pipeline in place of its own
copy, with `DBIx::Squirrel::Pipeline` a facade over it; version 3
dropped the facades and was built on Ekorn::Pipeline as it is
(2026-0013 to 2026-0019). An earlier version of this record said 2.x
used Ekorn::Pipeline throughout, which its trials didn't.

The reasons recorded then are in Ekorn-Pipeline's first commit's
message:

> So that any function, not only a query, can take stages from its
> caller, and the pipeline can grow beyond what rows need, with
> DBIx-Squirrel to depend on it once both are stable.

and its README, under "Where it came from":

> The pipeline began in DBIx::Squirrel, where stages written beside a
> query shape the rows it returns. None of it needs a database, so
> it's here on its own, for any function to use, and to grow beyond
> what rows need.

DBIx::Squirrel's own documents say little about why the pipeline
left: the guide's "17. Coming from version 1 or 2" and the reference's
"Upgrading from 2.x" say what changed for a caller, not what led to
it.

Talking over the documents' two parts (2026-0052) on 2026-11-26, Iain
judged the why an important part of the story: it's what makes Part 2
read as two pieces put back together on purpose, not as a dependency
explained after the fact.

## Decisions

- [x] **D1.** Why did the two split? A separation of concerns, on
  2026-11-26. In Iain's words, nothing hurt: many of the pipeline's
  ideas were useful, and usable, outside the database, which made them
  a separate set of concerns, to be kept separately. What ceased to
  belong in DBIx::Squirrel was the pipeline itself, and nothing got
  simpler yet, as the two still felt tightly coupled, which is why
  2026-0052 exists. So the story is told as principle, not pain, and
  claims no gain that hasn't arrived. A sceptical review agreed: don't
  sell the principle, let Part 2's code persuade. The text, for
  2026-0055 to place:

  > Stages began in DBIx::Squirrel, in 2024, as a way to change query
  > results as they're fetched. The pipeline behind them was useful,
  > and usable, well beyond database rows, so in 2026 it moved into a
  > distribution of its own, Ekorn::Pipeline, and DBIx::Squirrel kept
  > what needs a database. Everything in Part 1 is DBIx::Squirrel's
  > own. What follows shows what the two give you together: query
  > results written to files, JSON and CSV, loaded from them in
  > batches, or sent to several places in one run.

- [x] **D2.** Where is it told, and how often? In full once, at the
  opening of the guide's Part 2 (2026-0055), with a sentence and a link
  to it in the README and the reference (2026-0054, 2026-0056), on
  2026-11-26: the same story told in three places would drift. That the
  separation is only now being completed is news for a release, not
  the guide, so it goes in 2026-0058's `Changes` entry, as the
  sceptical review suggested.

## What happened

- **Outcome:** done. The story, settled in D1, opens the guide's Part 2
  word for word, in `docs/next/HOWTO.md` (2026-0055), and the README's
  Part 2 tells it in a sentence with a link to it (2026-0054), as D2
  says. GitHub Copilot's sceptical reviews of both found it concrete,
  matching the documented history, and not apologising for
  Ekorn::Pipeline.
- **What's left:** the reference's sentence and link (2026-0056), and
  "only now completed" in 2026-0058's `Changes` entry.
