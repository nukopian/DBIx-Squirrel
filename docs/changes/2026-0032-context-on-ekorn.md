# 2026-0032. DBIx::Squirrel::Context on Ekorn's, without the counting stage

**Status:** open

**Decisions:** D1 settled: `result_number` is Ekorn's, in every run. D2
settled: `result_original` falls back to Ekorn's outside a statement's
run. D3 settled: `iterator` keeps the `local`ised global. D4 settled:
v3.6.0, with the floor raised. D5 settled: `next` and `all`, before and after.

**Origin:** a message from Ekorn-Pipeline's session, 2026-11-16
(Ekorn-Pipeline 5ff0ea15ada5f95207001e740889614f32c574ff, its roadmap
2026-0046), answering DBIx-Squirrel's of the same day (Ekorn-Pipeline
ce1c31c73368604c409831b1d446bc6e886ef034) on the counting stage

**Depends on:** Ekorn-Pipeline 2026-0046, released

## Background

Every iterator with stages adds a stage of its own,
`sub { $counter->{produced}++; $_[0] }`, in `Iterator.pm`'s
`_pipeline`, only so `result_number` can say which result a stage is
making. Reading all 297,848 rows of `place_areas` through one bare
stage, it costs 200 to 260 ns a row, 11 to 15%, on 5.36 and 5.44, with
`next` or `all`; the table is in Ekorn's record.

Ekorn's 2026-0046 adds Ekorn::Pipeline::Context, with
`result_number` and `result_original`, in a v0.3.x:

- its `result_number` counts each run's own results, pulled or pushed,
  a result being a value leaving the last stage or reaching a sink;
  undef outside a stage;
- its `result_original` is the value the run's own source gave, or
  that was pushed; it isn't carried through chains, where ours, kept
  in the statement's context, is;
- a run that reads neither costs nothing more.

Iain decided there that DBIx::Squirrel::Context keeps functions of the
same names, built on Ekorn's as this session designs, and that
DBIx::Squirrel::Tooling goes on importing ours.

Iain, 2026-11-16: not to be started this week.

## Decisions

- [x] **D1.** Is `result_number` Ekorn's, in every run? Ours is there
  only in an iterator's own stages, and is undef in them when another
  pipeline reads the iterator as its source. Ekorn's would answer in
  every run, those included. Ekorn's, as recommended, Iain decided
  on 2026-11-24: it widens what ours promises, adding and taking
  nothing away.
- [x] **D2.** Does `result_original` fall back to Ekorn's outside a
  statement's run, where ours is undef now? Ours stays the row from
  the statement's context wherever there is one, chains included.
  Yes, as recommended, Iain decided on 2026-11-24, for the same
  reason as D1.
- [x] **D3.** Does `iterator` keep the global `next` `local`ises? Once
  the counting stage goes, `result_number` no longer needs it, and
  `iterator` is its only user. 2026-0031, dropped, measured moving it
  into the run's context: `next` gained 0 to 5%, and a stage reading
  it each row lost 7 to 12%. Keep it, as recommended, Iain decided on
  2026-11-24: a stage reading `iterator` stays as cheap as it is.
- [x] **D4.** Relying on Ekorn::Pipeline::Context raises the
  `cpanfile`'s floor to the release that has it, so this needs a
  release of ours. With D1 and D2 widening promises, which version?
  When this was written, v3.2.0 was next. v3.6.0, as recommended,
  Iain decided on 2026-11-24: a minor release, as it widens promises and
  raises the floor, taking nothing away.
- [x] **D5.** What's measured? `next` and `all` over `place_areas`,
  through one bare stage, and one reading `result_number`, before and
  after, on 5.36 and 5.44, as recommended, Iain decided on 2026-11-24:
  Ekorn's record has the before, measured the same way.
