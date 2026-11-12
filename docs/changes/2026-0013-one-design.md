# 2026-0013. DBIx::Squirrel on Ekorn as it is: one design

**Status:** in progress

**Decisions:** D1 settled: `DBIx::Squirrel::Pipeline` goes. D2
settled: v3.0.0. D3 settled: keep `result_number` and
`result_original`. D4 settled: a fresh run from `ekorn_source`. D5
settled: `insert_into` begins a transaction only with `AutoCommit`
on. D6 settled: the facades are plain re-exports. D7 settled: test
locally first, CI later. D8 settled: Ekorn renamed its role methods,
so a bind value is never taken for a stage. D9 settled: `insert_into`
dropped for now. D10 settled, then overtaken by D11. D11 settled: `all`,
`single` and `count` become sinks, Ekorn's. D12 settled: `count`, not
`to_count`. D13 settled: `pluck` and `as_hash` croak without columns,
as now. D14 settled: the sinks are `all_items`, `first_item` and
`only_item`. D15 settled: container sinks are another kind. D16 settled:
DBIx::Squirrel's calls give an iterator unless a sink is last. D17
settled: `only_item` warns at a second item. D18 settled: the `select`
methods take stages. Three open, in the design's section 13.1.

**Origin:** a TODO task from Ekorn-Pipeline's session, 2026-11-12
(Ekorn-Pipeline 43e2b0629fd89ef6fd990b9765b74d099b1f5210)

**Depends on:** Ekorn-Pipeline 2026-0022, its one design

**Started:** 2026-11-12, on `pipeline-experimental`

## Background

Ekorn-Pipeline settled a design for both repositories, its 2026-0022:
DBIx::Squirrel uses Ekorn as any other package would, and subclasses,
wraps and remakes nothing of it. Task 3 asks DBIx-Squirrel to review
it as Ekorn's first user, send what it finds as messages, and design
its own side, in [docs/design/DESIGN.md](../design/DESIGN.md).

Reviewed at Ekorn-Pipeline a75d178e4becfd1c3b6c57194bf6c111dabb8b98,
on 2026-11-12:

- Against it, 25 of DBIx::Squirrel's 26 test files pass. `t/06-gather.t`
  fails two subtests, both v0.3.0's intended changes.
- `is_stage` takes a bind value with an `as_list` method for a sink,
  which breaks a working call. Tried with a class of one method.
- An overload of `|` naming Operators' `chain` dies with "Undefined
  subroutine" until Operators is loaded.
- Ekorn's section 12 leaves out `result_number` and `result_original`.

Each went to Ekorn-Pipeline as a message, with small corrections to
its section 12.3 (Ekorn-Pipeline
7d4bd8f95f05675635e2d39312987ca1da1d934f).

## Decisions

- [x] **D1.** Keep `DBIx::Squirrel::Pipeline`? No, Iain decided on
  2026-11-12. It's a subclass with no code, which Ekorn's principle 2
  rules out, and the docs show `Ekorn::Pipeline->new` and `pipeline`
  instead. Weighed: keeping it as a name that makes Ekorn's pipelines,
  which is a wrapper by another name.
- [x] **D2.** The version? v3.0.0, Iain decided on 2026-11-12, as
  dropping the class breaks code that names it, and stages become
  objects with Ekorn v0.3.0.
- [x] **D3.** Keep `result_number` and `result_original`? Yes, Iain
  decided on 2026-11-12. `result_original` comes from the statement's
  source, as the row it fetched last, kept in the run's context, so it
  works in a user's own pipeline too. `result_number` works only where
  DBIx::Squirrel's own iterator runs the stages. Weighed: dropping
  both, which the reference and the how-to use.
- [x] **D4.** An iterator used as a source after `next`? A fresh run,
  from the first row, Iain decided on 2026-11-12, as Ekorn's D44
  implies. It croaks only if another of DBIx::Squirrel's iterators is
  part-way through the handle, as `reset` does today. Weighed: going
  on from where `next` left off, which would make one iterator two
  runs at once; and croaking whenever the handle is active, as Ekorn
  12.3 had it, which would break code that works today.
- [x] **D5.** `insert_into` and a transaction already begun, or
  `AutoCommit` off? It begins and commits a transaction only with
  `AutoCommit` on, and otherwise leaves it to the user, Iain decided
  on 2026-11-12. He added that he isn't bothered about keeping
  `insert_into`, and is more interested in result sinks (the design's
  Q11 and section 6).
- [x] **D6.** The facades? `Gather`, `Stop` and the `Stages::*`
  modules stay as plain re-exports of Ekorn's functions, as Ekorn's
  D31 allows; `Pipes` goes, as the handles use Ekorn's Pipes directly,
  Iain decided on 2026-11-12.
- [x] **D7.** CI against Ekorn's `pipeline-experimental`? Yes, Iain
  decided on 2026-11-12, but he'd rather nail things down locally
  first: tested against Ekorn's working copy, and CI once the two
  designs are settled.
- [x] **D8.** `is_stage` took a bind value with an `as_list` method for
  a sink. Ekorn-Pipeline settled it on 2026-11-12, its D49, by renaming
  its role methods `ekorn_source`, `ekorn_stage`, `ekorn_sink` and
  `ekorn_sink_scalar` (Ekorn-Pipeline
  8ce1c95b6a3bb6b7c4052374c67660491416686a). Checked against that
  commit: the bind value stays one, and the query gives its row.
  DBIx::Squirrel adds a test of it when the work is built.
- [x] **D9.** Keep `insert_into`? Not for now, Iain decided on
  2026-11-12, so roadmap 2026-0012 is dropped. It'll be found again if
  a need comes, and D5 says how it would treat a transaction. Result
  sinks come first (the design's section 6).
- [x] **D10.** What does a result sink give? One of DBIx::Squirrel's
  own iterators, a `DBIx::Squirrel::Results` over the rows it
  collected, Iain decided on 2026-11-12. It has the interface
  `results` gives today, `next`, `all`, `single`, `count` and `reset`,
  and can be read again as a source. So Iterator takes rows in hand as
  well as a statement. Weighed: a list of rows, simpler, but not
  readable again; and a new class for them, which the first draft
  called `DBIx::Squirrel::ResultSet`, a name taken from DBIx::Class
  that nothing asked for, and which copied Iterator's interface.
  Overtaken by D11 the same day: there's no result sink of
  DBIx::Squirrel's own.
- [x] **D11.** Should the iterator's `all`, `single` and `count` stay
  methods, or be sinks? Sinks, Iain decided on 2026-11-12: "So we
  break things. v3.0.0 is where we get to do that." A sink given last
  says what comes back, which removes the calling-context problems of
  a call that lists or counts by Perl's rules. The sinks are Ekorn's,
  as none needs a database: `to_array`, `to_arrayref`, `count`, and
  `to_scalar`, which gives the one result, `undef` for none, and
  croaks at a second, as `single` does, and was asked of Ekorn's
  session. `next` and `reset` stay; a call ending in a sink gives its
  result, as Ekorn's D43 allows. Rows become `Result` objects at the
  source, from `results`, so no result sink of DBIx::Squirrel's own is
  needed, and the design's Q9, Q10 and Q14, about one, are dropped as
  moot. Weighed: the methods kept as shorthands over the sinks, which
  keeps two ways to do one thing; and `all` as a sink of ours, whose
  name clashes with List::Util's. The names can be fine-tuned later,
  Iain said: what's settled is that they're sinks.
- [x] **D12.** `count` or `to_count`? `count`, Iain decided on
  2026-11-12, "as in that's what it is, not what we're putting the
  result in".
- [x] **D13.** What do `pluck` and `as_hash` do in a run whose source
  gives no columns, such as a pushed run? Croak, as now, with the
  message unchanged, Iain decided on 2026-11-12, as recommended.
  `pluck` by name on a hash row uses the row's own keys, as now, so it
  needs no columns.
- [x] **D14.** What are the sinks called? `all_items`, `first_item`,
  and `only_item`, "that asserts it's the only item", Iain decided on
  2026-11-12. He said `to_scalar`, `to_array` and `to_arrayref` were
  wrongly named: by D12's rule, a sink is named for what it is, not
  for what the result is put in. `to_array` and `to_arrayref` were
  Ekorn's names, taken over unasked, and `to_scalar` was made up to
  match. Ekorn's design has `to_array`, `first_value` and `count` for
  the same jobs, so the names, and `only_item`, go to its session as a
  message. A list sink can't end a `|` chain (Ekorn's D10), so the
  name of the sink giving every result in one reference is left open
  (the design's Q18).
- [x] **D15.** What gives every result in one reference, to end a `|`
  chain? `to_arrayref`, Iain decided on 2026-11-12, as a container
  sink: "I think to_array is still *a* valid sink, but it's another
  sink. The same way I think to_hash and to_hashref might also be
  valid sinks for pairwise lists." So there are two kinds: sinks named
  for what they give, `all_items`, `first_item`, `only_item` and
  `count`; and container sinks, named for where the items go,
  `to_array` and `to_arrayref` for items, `to_hash` and `to_hashref`
  for pairs, each filling a container given or a new one. D14's rule
  holds for each kind, and Ekorn's container sinks keep their names.
- [x] **D16.** What does a call give without a sink last? Iain agreed
  on 2026-11-12 to a rule, so the questions about sinks would answer
  themselves ("If we get this right, answers to questions might be
  self-evident"): **a statement is a source; DBIx::Squirrel's own
  calls give the source, an iterator, and only a sink given last turns
  it into a result; the DBI's own calls give what the DBI gives.** He
  had first asked to "leave it as the iterator", for now. From it:
  the Sugar's statements, given stages, give an iterator, not every
  result or a count by context; the `select` methods, being the DBI's,
  are unchanged; `only_item` with no rows gives Ekorn's `undef`; users
  get the sinks from Ekorn, re-exported or not; the iterator's "how
  many so far" goes, as counting is a stage's or a sink's job; and
  the sinks' names are Ekorn's to settle. No call of DBIx::Squirrel's
  lists or counts by its calling context.
- [x] **D17.** What does `only_item` do at a second item? It warns, and
  doesn't croak, Iain said on 2026-11-12: "It warns if there are more
  than 1 items. For when you SELECT but forget LIMIT 1." It gives the
  first item, and stops the run once it has seen the second. That
  corrects D11 and D14, which said it croaks at a second, as `single`
  does today.
- [x] **D18.** Do the `select` methods take stages? Yes, Iain decided on
  2026-11-12: "the value or values returned by the select methods are
  what enter the pipeline. If that's an arrayref, fine by me." So what
  the DBI gives is pushed through the stages, as `pipe` pushes a
  handle; "with stages, what comes out the final stage, without
  stages, what comes from DBI." The first draft wrongly listed them
  among the calls taking stages, which they don't today; the reference
  says each works as the DBI's does.

## The plan

Written when the design is approved and split into items.

## What happened

- **2026-11-12:** the review's findings sent to Ekorn-Pipeline, and the
  design drafted, with its open questions, for Iain.
- **2026-11-12:** Ekorn-Pipeline took in all four findings (its message,
  Ekorn-Pipeline 8ce1c95b6a3bb6b7c4052374c67660491416686a): the role
  methods renamed, Operators loaded with an empty import list to
  overload with its functions, `result_number` and `result_original`
  named as DBIx::Squirrel's, and 12.3 corrected. The design is brought
  up to date with it. Against that commit, DBIx::Squirrel's tests stand
  as before: 25 of 26 files pass, and `t/06-gather.t`'s two failures
  are v0.3.0's intended changes.
- **2026-11-12:** Ekorn-Pipeline took in the message on the sinks, with
  its three amendments, as its D50, and built them (Ekorn-Pipeline
  e03e71958e0052dd098672f77a099b90681644e2): `all_items`, `first_item`,
  `only_item` and `count`, and the containers `to_array`,
  `to_arrayref` and `to_file`; `first_value` became `first_item`.
  It warned that Test2::V0's `all_items` clashes with the sink in a
  test importing both. Against that commit, the tests stand as before.
- **2026-11-12:** a reread of the design against the code, asked for by
  Iain, found two mistakes in it, now fixed: the `select` methods were
  listed as taking stages (settled since, D18), and `result_original`
  was "the row fetched last", which with batches of 100 would be the
  wrong row. It found three things the build must keep, now in the
  design's 4.6: a run's end touching only its own run, no cycles
  keeping an iterator alive, and quiet ends at program exit. And three
  questions, Q21 to Q23.
