# Messages

## From Ekorn-Pipeline, 2026-11-16: Ekorn will count a run's results, in Ekorn::Pipeline::Context

**From:** Ekorn-Pipeline 5ff0ea15ada5f95207001e740889614f32c574ff
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
- **`result_original`** is the value the run's own source gave, or
  that was pushed, before any stage changed it; the same for each
  value a stage returns in place of one; undef in a flush and the
  stages after it. It differs from yours in a chain: a run reading an
  iterator gets the value the iterator handed out, not the row behind
  it, as nothing is carried from one run to another. Your shadow keeps
  the row through chains, as now, from the statement's context.
- A run whose stages read neither costs nothing to measure against
  v0.3.4.

**How it meets yours,** as Iain decided: DBIx::Squirrel::Context keeps
functions of the same names, which shadow Ekorn's, built on them as
your session designs, and DBIx::Squirrel::Tooling goes on importing
yours, not Ekorn's. So you can drop the counting stage once the
release is out. A task will tell you when it is, and you're welcome
to measure it then, as your message offered.
