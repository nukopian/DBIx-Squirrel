# 2026-0026. A sweep of the docs, as Ekorn-Pipeline's for v0.3.0

**Status:** shipped, unreleased

**Decisions:** None: the criteria are Iain's, given to Ekorn-Pipeline
and sent here as a task.

**Origin:** a TODO task from Ekorn-Pipeline's session, 2026-11-14
(Ekorn-Pipeline da9865d479b8142223e53c306eafde37ea9eb091, its 2026-0025)

**Started:** 2026-11-14

**Finished:** 2026-11-14

## Background

Iain asked Ekorn-Pipeline for a sweep of its docs before v0.3.0, and
for DBIx-Squirrel to do the same, by the same criteria. Ekorn's
record 2026-0025 says how its sweep went: one apparent gap in the
reference's coverage, covered on a wrapped line; old terms left over,
such as "the closure"; 97 calls and ten `|` chains put a stage to a
line; paragraphs filled again to 70 columns; and a section, Making
each kind of part, whose writing turned up a rule easy to get
backwards and two details the reference hadn't said.

## The plan

What: the README, the user guide, the reference and the modules' POD,
swept by Iain's five criteria, in this order:

1. **The reference's coverage.** Every method, function and message
   each module's POD documents is in `docs/REFERENCE.md`, checked by a
   script with whitespace collapsed, then each public sub; and its
   Contents, and the guide's, list every section.
2. **Plain English.** The reference read through, and what's left from
   older versions taken out.
3. **Lines.** Paragraphs filled again to 70 columns, checked to change
   nothing but whitespace; a Contents line and a POD NAME line stay one
   line.
4. **A stage to a line.** In examples, a pipeline of two or more
   stages has a stage to a line, indented, with a trailing comma: in
   `->new(...)` and `pipeline(...)`, calls of functions taking stages,
   and `|` chains, one `| stage` to a line. A call that prints, spanning
   lines, has its comment on the line after its `);`; a chain that
   prints keeps its result in a variable first. Calls by a script,
   checked to change only layout; chains by hand.
5. **Worked examples for developers,** of how to make each kind of
   DBIx::Squirrel's own parts, such as its sources and its stages for
   rows, pointing to Ekorn's reference for the protocols themselves.

Why: Iain wants both projects' docs swept by the same criteria before
their releases, so neither is missed.

Done when: the README, the user guide and the reference read as one
account, every example prints what it says, and `xt/manuals.t` passes.

## What happened

- **Outcome:** as Done when says, as far as checks can tell: every
  example prints what it says, `xt/manuals.t` passes, and all 31 test
  files pass, 2,166 assertions, against Ekorn's `develop` at da9865d.
  The three documents weren't read through end to end as one account;
  the sweep searched them, and changed what it found.
- **Coverage:** a script checked each module's POD headings and
  DIAGNOSTICS messages against the reference, whitespace collapsed,
  then each public sub. Every message, and every function and method
  for users, was there, and both Contents lists matched their
  sections. The gaps were internal functions, documented as not for
  use elsewhere; the table of modules now names each, as internal.
- **Old terms:** "a pipeline of transformations", version 1's word,
  in the README and the main module's POD; "This is version 2" in the
  main module's POD; and Ekorn's iterator method returning "a closure"
  in the reference. The modules' POD had none of version 3's changed
  behaviour left.
- **Lines:** 212 paragraphs filled again to 70 columns, by a script
  that kept code spans, POD codes and links' targets whole, and never
  began a line with what Markdown or POD reads as structure; each file
  changed only in whitespace, and each POD file and manual rendered to
  the same text. The first run wrapped the Contents lists and ten NAME
  lines, which were put back. What's past 70 is a long URL or a
  message in backticks.
- **A stage to a line:** 52 calls by a script, checked to change only
  layout, three by hand, and three `|` chains. The script's first list
  of stages missed four calls whose stages had names it didn't know,
  such as `and_count`; a wider scan found them. Runs of printing calls
  got a blank line after each comment.
- **Developers' worked examples:** a section of the reference, Making
  each kind of part, with a table of what a statement's run gives each
  piece, and a stage for rows and a sink into a table, each with a
  word and as a class, run before their output was written. Breaking
  two expected outputs made `xt/examples.t` fail on both, so the
  section is checked. Running them showed two things the reference
  hadn't said: a set-up has no context, as the statement hasn't been
  read, so a stage reads its columns in its first step; and in a
  sink's own step, `result_number` is one more than the value's
  number, as the counter before the sink has counted it, so a sink
  counts for itself.
- **A test run that wasn't:** twice, `PERL5LIB=... scripts/manuals &&
  yath test`, in one `sh -c`, set the variable for the first command
  only, so yath ran against the installed Ekorn v0.2.0 and failed. The
  first time it looked unexplained; `export` fixed it.

