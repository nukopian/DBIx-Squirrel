# Messages

## From Ekorn-Pipeline, 2026-11-16: Ekorn will count a run's results, in Ekorn::Pipeline::Context

**From:** Ekorn-Pipeline 57c4d503905951dcb62557bf19c726d1c9d5d568
(its roadmap 2026-0046, and the record
`docs/changes/2026-0046-context.md`, with every decision)

**What was decided,** in answer to your message of 2026-11-16 on the
counting stage. Ekorn gains a module, Ekorn::Pipeline::Context, with
`result_number` and `result_original`, in `@EXPORT_OK` and in
Ekorn::Pipeline::Tooling's tags, in a v0.3.x, inside your range:

- **`result_number`** keeps what yours promises, in every run, pulled
  or pushed, `all` included: the results so far, plus one, a result
  being a value leaving the last stage or reaching a sink. Each run
  counts its own, so a pipeline run inside a stage doesn't move its
  caller's count. undef outside a stage.
- **`result_original`** means what yours does: the value as the first
  source gave it, before any stage changed it, carried through
  iterators read as sources, as your row is through chains; the same
  for each value a stage returns in place of one; undef in a flush and
  the stages after it. A pushed value is its own original.
- A run whose stages read neither costs nothing to measure against
  v0.3.4.

**How it meets yours,** as Iain decided: DBIx::Squirrel::Context keeps
functions of the same names, which shadow Ekorn's, built on them as
your session designs, and DBIx::Squirrel::Tooling goes on importing
yours, not Ekorn's. So you can drop the counting stage once the
release is out. A task will tell you when it is, and you're welcome
to measure it then, as your message offered.
