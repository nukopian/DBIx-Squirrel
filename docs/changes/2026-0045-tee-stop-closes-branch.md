# 2026-0045. A stop after a tee no longer loses what its branch holds

**Status:** shipped, unreleased

**Decisions:** None.

**Origin:** roadmap, added 2026-11-24, from 2026-0036's appraisal and
Ekorn-Pipeline's message of 2026-11-24 (Ekorn-Pipeline
820d962f3d2321d8da4a95f4b63f899bb7af1420)

**Depends on:** Ekorn-Pipeline 2026-0050, released in v0.3.10

**Started:** 2026-11-24

**Finished:** 2026-11-24

## Background

2026-0036 found that a stage stopping the run after a `tee`, such as
`take`, or an iterator's `first`, ended the run before the branch's
flushes ran, so what the branch held, such as a part-filled `batch`,
was dropped without a word. The user guide and the reference said to
put the stopping stage before the tee. Ekorn took it as its 2026-0050,
Iain chose that the tee close its branch when the main run stops, and
it shipped as a fix in Ekorn::Pipeline v0.3.10, which DBIx::Squirrel
requires from the same release as this.

## The plan

**What:** drop the cautions, and say what a stop after a tee does now.

**Why:** with v0.3.10 required, they describe what no longer happens,
and send readers to work around it.

**Steps:** in `docs/HOWTO.md`, the paragraph opening "A stop after the
tee is another matter"; in `docs/REFERENCE.md`, the sentence from "A
stop after the tee" in Taps, and the one in tee's index entry; run
`scripts/manuals`. Add a test to `t/20-stages-taps.t`: a branch
batching values, with `take` after the tee, has its last part-filled
batch flushed. Replace 2026-0036's line in `Changes`.

**Done when:** the cautions are gone, the test passes against
Ekorn::Pipeline v0.3.10, and `Changes` says so.

## What happened

- **Outcome:** as planned. The new subtest in `t/20-stages-taps.t`, a
  branch batching in twos with `take(3)`, and then `first`, after the
  tee, passes against Ekorn-Pipeline
  4c069b6e48fd029c267822b9916df1ef2dee7645 (v0.3.10), and fails
  against v0.3.7, which drops the held batch, so it tests the fix.
- **Changes from the plan:** the test reads a five-row `WITH ...
  VALUES` query rather than the test's three artists, so `take(3)`
  stops the run rather than meeting the end of the rows.
- **What's left:** nothing.
