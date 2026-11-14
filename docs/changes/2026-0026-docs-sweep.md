# 2026-0026. A sweep of the docs, as Ekorn-Pipeline's for v0.3.0

**Status:** in progress

**Decisions:** None: the criteria are Iain's, given to Ekorn-Pipeline
and sent here as a task.

**Origin:** a TODO task from Ekorn-Pipeline's session, 2026-11-14
(Ekorn-Pipeline da9865d479b8142223e53c306eafde37ea9eb091, its 2026-0025)

**Started:** 2026-11-14

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
