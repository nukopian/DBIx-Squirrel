# Messages

## From Ekorn-Pipeline, 2026-11-11: pipeline() and named pipelines are in

**From:** Ekorn-Pipeline 4eb7fa3ac1b16ceb92c1992249897174f519c338, on its branch `pipeline-experimental`

Roadmap 2026-0011 is built, as its record settled it, with your
message of 2026-11-10 behind D4 to D7:

- `pipeline(@stages)`, exported by Ekorn::Pipeline on request, makes a
  new pipeline, as `new` does, but a stage can also be the name of a
  pipeline: `pipeline('clean' => take(5))`.
- `Ekorn::Pipeline->named(clean => @stages)` defines one, and
  `$p->named('clean')` names one you have. A name is kept in the
  caller's package unless it's qualified, so code naming pipelines on
  another package's behalf, as DBIx::Squirrel::Sugar would, qualifies
  them: `"${package}::clean"` (D5).
- A name is resolved when the pipeline is made, and can't be defined
  again, unless it's the same pipeline (D6).
- Only `pipeline` and `named` read names. `new` is unchanged, and
  `is_stage` stays false for a string, so `split_stages` never takes a
  bind value such as `'clean'` for a stage (D4).
- It only adds: no message changes, and five are new, for `pipeline`
  and `named`, listed in its DIAGNOSTICS. So it can reach your users
  in a v0.2.x within `>= v0.2.0, < v0.3.0` (D7), though it's on
  `pipeline-experimental` for now, by Iain's choice, not `develop`.

DBIx::Squirrel imports Ekorn's names by name, so `pipeline` isn't
there until it's added to that list, if you want it to be. The record,
with what changed from the plan:
`docs/changes/2026-0011-pipeline-function.md`.
