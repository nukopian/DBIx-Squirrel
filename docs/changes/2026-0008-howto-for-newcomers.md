# 2026-0008. A how-to that answers a newcomer's questions

**Status:** shipped, unreleased

**Decisions:** D1 settled: by task, with an opening that says who it's
for. D2 settled: Iain reads the PDFs, 2026-0005's too, at the end.

**Origin:** roadmap, added 2026-11-10, from Iain, after Ekorn-Pipeline
rebuilt its how-to the same way

**Depends on:** 2026-0007

**Started:** 2026-11-10

**Finished:** 2026-11-10

## Background

The how-to grew recipe by recipe. A newcomer's questions aren't all
answered there, and some features have no recipe: before 2026-11-09,
none showed a `gather` block returning a pipeline, or a pipeline in a
Sugar statement. Ekorn-Pipeline's how-to opens by naming its readers,
has Contents and the examples' data, and gives each task a recipe.

## Decisions

- [x] **D1.** How is it organised? By task, Iain decided on
  2026-11-10, as Ekorn's is: an opening naming its readers, people
  who use the DBI and want less boilerplate, and authors of functions
  and stages; Contents; the examples' data; then chapters in the order
  a newcomer meets things, from connecting to handling errors, each
  recipe headed by its task, with the chapters for authors last.
- [x] **D2.** When does Iain read the PDFs? Once, at the end of this
  item, Iain decided on 2026-11-10: the README, the how-to, the
  reference and MAINTAINING. That read finishes 2026-0005's Done when
  too.

## The plan

**What:** rebuild `docs/HOWTO.md` by task, keeping every recipe it has
and adding one for each topic of the reference that has none, and for
the questions a newcomer asks first.

- **An opening** naming its readers: people who use the DBI and want
  less boilerplate; people moving from 1.x; and authors of functions
  and stages. Then Contents, and the examples' database.
- **Chapters, in the order a newcomer meets things:** Connecting;
  Writing statements; Binding values; Running statements; Iterating
  over results; Transforming rows with stages; Stopping and taking;
  Gathering and ends; Rows as objects; A function for each database
  and statement; Caching and connections; Handling errors; Moving
  from 1.x. Then, for authors: Pipelines without a database; Writing
  a function that takes stages; Writing stages for others.
- **New recipes,** from 2026-0007's audit and a newcomer's
  questions: transactions and the DBI's other methods; handle classes
  of your own; an iterator's column names, and one iterator to a
  statement handle; `drop_while`; Sugar's connections; `HandleError`;
  moving code from 1.x; and, for stage authors, a function that makes
  a stage, reporting mistakes at the caller's line, a stage made of
  others, testing and publishing.
- **Each recipe** has a task for its heading and an example
  `xt/howto.t` runs, unless it needs a server the tests don't have.
  What each example prints is checked against its comments, by
  running the how-to as `xt/howto.t` does.
- **The writing** keeps 2026-0005's rules for plain docs.

**Why:** a newcomer should find the answer to each first question in
a recipe they can run, and a reader of the reference a recipe for each
thing it describes.

**Done when:** every topic in the reference has a recipe, or the
record says why not; every example runs and prints what it says;
`xt/howto.t`, `xt/manuals.t` and `podchecker` pass; and Iain has read
the PDFs of the README, the how-to, the reference and MAINTAINING,
which finishes 2026-0005 too.

## What happened

- **The rebuild, 2026-11-10:** the how-to has the planned opening,
  Contents and chapters. Every recipe it had is kept, word for word
  but for four: "Loop over the rows" says a large result is never held
  at once; "Stop when you've had enough" names `count`; "Reuse a
  pipeline" lists `reset` among the places a pipeline goes; and "Give
  rows methods of your own" says a column named as one of your methods
  gets none. Recipes moved between chapters: stopping and taking, and
  gathering and ends, are chapters of their own, and "See what went
  wrong in a stage" is under Handling errors. Nothing linked to the
  how-to's anchors but its own Contents.
- **New recipes:** "Give the handles methods of your own"; "Read one
  statement by another database's rules"; "Use DBD::Pg's own
  placeholder options"; "Use transactions, and the DBI's other
  methods"; "Find the column names"; "Use one iterator at a time on a
  statement handle"; "Skip rows until a test fails"; "Let Sugar
  connect when it's needed"; "Handle errors your own way"; the three
  recipes of "Moving from 1.x"; and, for stage authors, "Decide where
  a stage belongs", "Write a function that makes a stage", "Report
  mistakes at the caller's line", "Make a stage out of others", "Test
  a stage" and "Publish a module of stages". Each was tried before it
  was written, and every example prints what its comments say,
  checked line by line against a run of the how-to as `xt/howto.t`
  runs it: 151 lines of output.
- **Ekorn-Pipeline's task, "Say where a stage belongs"**
  (Ekorn-Pipeline 497f33a7b2bfbbd6b22a7e23921ab0c0796f0a1a), is done
  here: the recipe "Decide where a stage belongs", and the reference's
  "Where they go", which now says the same and links to it. The task
  put the recipe near "Write a stage that keeps count"; it's first in
  "Writing stages for others", which this rebuild made for that
  reader. It doesn't link to Ekorn's own recipe, which is on Ekorn's
  `develop` but not in v0.2.0: `xt/manuals.t` checks each link to
  Ekorn's manuals against the installed release. Add the link once
  Ekorn releases it.
- **Found on the way:** the recipe for Sugar's connections first
  defined its database with `music`'s arguments, so the two shared a
  handle, and disconnecting it cut off `music`'s open statements. Its
  database has attributes of its own now, as the recipe says why.
- **Also, on 2026-11-10:** the placeholder styles' recipe gained
  `$name`, which it had left out, and so did three other lists of the
  styles (82c7329, 6c2d7f5). The PDFs keep short sections whole and
  code with the sentence introducing it (caa8137), after Iain saw
  awkward page breaks.
- **Outcome, 2026-11-10:** against Done when, met. Every topic in the
  reference has a recipe; every example runs and prints what it says;
  `xt/howto.t`, `xt/manuals.t` and `podchecker` pass; and Iain read
  the PDFs of the README, the how-to, the reference and MAINTAINING,
  saying "Docs look good". That read finishes 2026-0005 too. The item
  ships, unreleased.
