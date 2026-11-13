# Messages

## From Ekorn-Pipeline, 2026-11-13: the role methods are to be renamed in capitals

**From:** Ekorn-Pipeline's session, 2026-11-13 (Ekorn-Pipeline
19465996e55b4c613ac1e00a277f0efcd158ab08, on its branch `pipeline-experimental`, roadmap
2026-0027)

Iain has decided that the role methods are to be renamed:
`ekorn_source`, `ekorn_stage`, `ekorn_sink_one` and `ekorn_sink_many`
become `EKORN_SOURCE`, `EKORN_STAGE`, `EKORN_SINK_ONE` and
`EKORN_SINK_MANY`. That follows Perl's convention for a sub the
runtime calls rather than its caller (`DESTROY`, `FETCH`), and CPAN's
for a hook offered to another package's framework (`TO_JSON`,
`STORABLE_freeze`).

It's planned, not done: roadmap 2026-0027, ahead of v0.3.0, which now
depends on it. No release has the lowercase names, so they won't be
kept as aliases. Your parts will need renaming once it lands on
`pipeline-experimental`; a task will follow then. Until then, the
lowercase names are the ones that work, so there's no need to change
anything yet. If you'd rather write new parts against the capitals
now, wait for the task.

# Planned work

## Rename the role methods in capitals, from Ekorn's 2026-0027

**From:** Ekorn-Pipeline's session, 2026-11-13 (Ekorn-Pipeline
7ade8ae501c2377b75e7478c86f7971dc6a8d14e, on its branch `pipeline-experimental`)
**Waiting on:** nothing

Ekorn's role methods are now `EKORN_SOURCE`, `EKORN_STAGE`,
`EKORN_SINK_ONE` and `EKORN_SINK_MANY`, on its
`pipeline-experimental`. The lowercase names are no longer read, and
no aliases are kept, as no release had them. This supersedes the
message above: the rename has landed.

- `lib/DBIx/Squirrel/Iterator.pm` has four uses of the old names, and
  any other part of DBIx::Squirrel's offering one, with its tests and
  docs, needs the new names.
- One Ekorn message changed with them: "Expected stage #%d to offer
  one of EKORN_STAGE, EKORN_SINK_ONE and EKORN_SINK_MANY, not %s".
  A test matching the old text would need it.
- Records and the design's history may keep the old names, as Ekorn's
  do.

Done when `git grep -E 'ekorn_(source|stage|sink_one|sink_many)'`
finds them only in records and history, and the tests pass against
Ekorn's `pipeline-experimental`.
