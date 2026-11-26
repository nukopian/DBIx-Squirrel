# 2026-0053. Why Ekorn::Pipeline split from DBIx::Squirrel

**Status:** open

**Decisions:** D1 open: the reasons, from Iain; where the pipeline
came from is settled, 1.x's transformations. D2 open: told in full
once, at the opening of the guide's Part 2.

**Origin:** roadmap, added 2026-11-26

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

- [ ] **D1.** Why did the two split? Iain's reasons, in his words, to
  be shaped into the text. Where the pipeline came from is settled
  (Background), and the reasons recorded at the split are quoted
  there; whether there's more to them is Iain's to say. Reasons
  shouldn't be inferred beyond what's recorded.
- [ ] **D2.** Where is it told, and how often? The recommendation: in
  full once, at the opening of the guide's Part 2 (2026-0055): it was
  one library, it split for these reasons, and here is what you gain by
  putting them back together. The README and the reference give a
  sentence and a link to it (2026-0054, 2026-0056). The same story told
  in three places would drift.
