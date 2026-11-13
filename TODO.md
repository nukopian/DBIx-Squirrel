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
