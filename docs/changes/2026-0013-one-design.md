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
`to_count`, which Ekorn named `count_items`. D13 settled: `pluck`
and `as_hash` croak without columns, as now. D14 settled: the sinks
are `all_items`, `first_item` and `only_item`; Ekorn has since named
them `keep_all`, `keep_first` and `keep_single`, and added
`keep_last`. D15 settled, then overtaken: Ekorn has no containers for arrays or hashes. D16 settled:
DBIx::Squirrel's calls give an iterator unless a sink is last. D17
settled: `only_item` warns at a second item. D18 settled: the `select`
methods take stages. D19 settled: sinks' names clashing on import.
D20 settled: a list sink asked for one value gives an array
reference. D21 settled: `pluck` after a reshaping stage, warned of in
the docs. D22 settled: `all`, `single` and a new `first` come back
on the iterator, as on Ekorn's; `count` stays gone. D23 settled:
they're Ekorn's, delegated to. D24 settled: batches grow from 2 to 64,
as in version 1. D25 settled: `single` finishes the run, as `first`
does. D26 settled: `all` has a fast path. D27 settled: `reset` clears
everything the run held. D28 settled: Ekorn is asked to make a
step's many values cheap; nothing else is needed. D29 settled: a whole
batch in a step, only with no stages and no pipeline reading. D30
settled: Ekorn is asked about its `&{}` overload's cost. None open.

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
  result in". Ekorn named it `count_items` on 2026-11-12, as its D53,
  which completes the family named for what they give, and is less
  likely to clash with a caller's own `count`.
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
  (the design's Q18). Ekorn named `only_item` `single_item` on
  2026-11-12, as its D53, echoing `single`, the method it replaces.
  Later the same day, as its D55, Iain renamed the three `keep_all`,
  `keep_first` and `keep_single`, each named for what it keeps of what
  reaches it, and Ekorn's designed `last_item` became `keep_last`,
  built, as its D56.
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
  Overtaken the same day by Ekorn's D54, which drops `to_array`,
  `to_arrayref`, `to_hash` and `to_hashref`: since D20, `all_items`
  gives every result as an array reference wherever one value is asked
  for, so a `|` chain ends in it, and Perl fills a container of the
  caller's own beside the call. Ekorn's container sinks are `to_file`,
  and `to_fh` as designed.
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
- [x] **D19.** What about Ekorn's sinks, imported, clashing with names
  in the user's package, such as a Sugar statement called `count`?
  Settled as recommended, Iain decided on 2026-11-12: a test shows the
  Sugar's clash check catches a sink of the same name, and the docs
  import sinks by name. He added that a clash can be avoided by calling
  the sink by its full name, `Ekorn::Pipeline::Sinks::count()`, "or use
  a lexically scoped code ref", `my $count =
  \&Ekorn::Pipeline::Sinks::count`, called as `$count->()`. Test2::V0's
  `all_items` is the same case (Ekorn's D50).
- [x] **D20.** A list sink last gave a count in scalar context, so
  `my $rows = ... all_items` quietly gave a number. Iain proposed on
  2026-11-12 that it give its list as a reference, as `count` is there
  for counting, and Ekorn adopted it as its D51 ("quite nice, too", in
  his words), built at Ekorn-Pipeline
  89dfd3a2ab792c595dd4246788db3940d7fde4ef: a list sink asked for one
  value, in scalar context or at the end of a `|` chain, gives an array
  reference. Checked against that commit. A run with no sink still
  gives a count (Ekorn's D17), which for DBIx::Squirrel is only a
  `select` method given stages and no sink, in scalar context.
- [x] **D21.** `pluck` after a stage that reshapes rows reads the
  statement's columns, as a context describes the source (Ekorn's
  D46), and so picks the wrong field, silently. Settled as
  recommended, Iain decided on 2026-11-12: the reference and the
  how-to say so loudly, and show `as_hash` first, then `pluck` by
  name, which uses the hash's own keys. Detecting a reshaped row would
  need more from Ekorn, and wasn't asked for.
- [x] **D22.** Do `all`, `single` and `first` come back as the
  iterator's methods? Yes, Iain decided on 2026-11-12: "The iterator is
  getting single back. And all. And first. At the Ekorn level, too."
  Ekorn's iterator has them, as its D59 and D60: `all` gives what's
  left of the run, a list, or an array reference where one value is
  asked for; `first` the next value, ending the run; `single` the next
  value, looking one ahead and warning if there's another, without
  consuming it. DBIx::Squirrel's take the same meanings. It came of
  asking what went with the methods: taking the rest of a run after
  `next`, which a sink can't, as a sink over an iterator starts a fresh
  run (D4); a call with nothing to import; and discoverability. `count`
  isn't named, and stays gone. This revises D11, which stays as the
  rule for a run given a sink last. For users, `all` asked for one
  value now gives a reference, not a count; `single` gives the next
  result, not a fresh run's, and warns at a second, rather than croak.
- [x] **D23.** Are they Ekorn's, through the Ekorn iterator inside
  DBIx::Squirrel's, or its own? Iain suggested `single` be
  specialised, using the batch fetch as a lookahead that consumes
  nothing. Ekorn's `single` already consumes nothing (its D60), and
  with no stages, its lookahead takes the second row from the batch
  already fetched; with stages, a count of rows would be wrong, as a
  filter or a flatMap changes how many results there are.
  Recommended: delegate all three to Ekorn's, and keep the batch size
  at two or more. The design's Q25. Settled as recommended, Iain
  decided on 2026-11-12, adding that buffering rows needs more
  thought.
- [x] **D24.** How many rows does a statement's source fetch at a
  time? As version 1 did, Iain said on 2026-11-12: "the reason my
  original code started with a batch of two. That was the minimum
  required to determine if a warning was warranted. It also meant that
  we didn't read too much. Subsequent reads increased that count
  exponentially to a small but sensible maximum." Version 1's
  `DBIx::Squirrel::it` started at 2 (`DEFAULT_CACHE_SIZE`), doubled
  whenever a fetch filled its batch, and stopped at 64
  (`CACHE_SIZE_LIMIT`); version 2 fixed it at 100, so `first`,
  `single` and `take(1)` fetch up to 100 rows to use one or two. The
  design takes version 1's numbers. The step still gives one row at a
  time, so `result_original` reads the row being worked on. It came of
  asking what more buffering needs, after D23; nothing of it needs
  Ekorn, as a source's step is called with nothing and can't be told
  how many its caller wants.
- [x] **D25.** Ekorn's `single` keeps its iterator open after warning,
  holding the value it looked at (its D60), so a statement that
  forgot `LIMIT 1` would stay active, holding a lock on SQLite. Iain
  decided on 2026-11-12: "single should behave like first and finish
  the statement." DBIx::Squirrel's `single` calls Ekorn's, then
  finishes the run. The design's Q28; Ekorn-Pipeline is told.
- [x] **D26.** Delegated to Ekorn (D23), `all` pulls a row per step,
  where today it fetches the rest at once. Iain decided on 2026-11-12:
  "I'm happy with a fast path. I don't think I'd considered it in the
  original code." With no stages, `all` has its source give every row
  left in one step, the batch and the rest from one
  `fetchall_arrayref`, which Ekorn's protocol allows, as a source's
  step returns "the next value or values"; Ekorn's `all` collects them,
  and the run ends `done`. With stages, rows go one at a time, so
  `result_original` stays right. Nothing is asked of Ekorn. The
  design's Q27.
- [x] **D27.** What does `reset` clear? Everything the run held, Iain
  decided on 2026-11-12: "Yes, a reset should clear any cruft away."
  A value Ekorn's iterator holds, the batch, which starts at 2 again,
  and Context's row and count; the handle is finished. A fresh run
  started any other way does the same. It's a fourth guarantee in the
  design's 4.6, with a test. The design's Q29.
- [x] **D28.** Do Ekorn's protocols support a statement's buffering,
  or does it need more of them? D24 to D27 each said nothing was
  asked of Ekorn, true of each alone, but not shown for them
  together. Iain asked on 2026-11-12 whether it was said that more
  might be needed, and it wasn't. Four things may need more: a fast
  path for sinks, as `$it | keep_all` pulls a row per step where
  `$it->all` doesn't; a lookahead that consumes nothing, only the
  iterator's today; a way to tell a source how many are wanted; and
  the untested behaviour D23 to D27 rest on. Recommended: a spike
  against Ekorn's working copy, timing `$it->all` against
  `$it | keep_all`, asking Ekorn for more only where it shows a need.
  The design's 4.8 and Q30; Ekorn-Pipeline is told. Settled by Iain on
  2026-11-12, as recommended from the spike: of the four, only the
  first needs Ekorn, and wider than sinks, as `$it->all` over 297,848
  narrow rows went from 0.108 s to 0.403 s, with Ekorn wrapping and
  handing out each value. Ekorn is asked, as a task, to make a step's
  many values cheap where nothing stands between the source and the
  end, and its iterator's `all` take them in bulk; DBIx::Squirrel
  doesn't route rows around Ekorn, which would serve `$it->all` alone.
  Growing batches serve the second and third; the fourth holds.
- [x] **D29.** Should a statement's source give its whole batch in a
  step? Each value a step gives costs Ekorn something, so handing out
  a batch at a time is quicker: over 297,848 narrow rows, `next` took
  0.37 s, against 0.47 s a row at a time, and 0.35 s in version 2. But
  `result_original` would then name the batch's last row, not the row
  being worked on, as the design's 4.1 rules out. Iain decided on
  2026-11-12, as recommended: only with no stages of the iterator's own
  and no pipeline reading it, where nothing asks which row a value
  came from, which serves `next` and `$it->all`. Weighed: also with
  only a sink, 23% quicker for `iterate(keep_all)`, but a user's own
  sink asking `result_original` would get the wrong row; and a row at a
  time always. The design's Q31.
- [x] **D30.** Should Ekorn be asked about what's left of each value's
  cost, which it named: a `try` and two `local`s for each value
  through a stage, and the `&{}` overload on each call of an Element?
  About the `&{}` overload only, Iain decided on 2026-11-12, as
  recommended: every pull pays it. The `try` and `local`s keep a stop
  or a die reported at its stage, and stay. Sent as a task. The
  design's Q32.

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
- **2026-11-12:** Ekorn-Pipeline's message (Ekorn-Pipeline
  8d7d185e1413c03af0a1eb41fcbeb4fe605f513e): Iain kept `all_items` over
  `every_item`, which is designed as the yes/no test paired with
  `any_item`, and the clash with Test2::V0's check is "only a problem
  in test harness". That settles the test half of the design's Q23.
- **2026-11-12:** for the design's Q22, Iain proposed that `all_items`,
  and any list sink, give its list as a reference in scalar context,
  as `count` is there for counting: "all_items as a scalar (when I
  have a count sink) could be a reference?" It's Ekorn's rule to
  change (its D47 and D10), so it went to Ekorn-Pipeline as a message.
- **2026-11-12:** Ekorn-Pipeline took in the message on a bare
  `@{ chain }` as its D52 (Ekorn-Pipeline
  0f3321facd799b7df57dd34cac81a5bcbdbb6a81). Iain: "Looks weird but you
  should explain it in detail, and use more examples of alternatives."
  So `@{}` stays, explained, and both projects' chains lead with a
  sink. The design's 4.5 mirrors Ekorn's explanation and its table of
  alternatives, for statements. Ekorn also found that a chain written
  as a statement of its own draws Perl's "Useless use of numeric
  bitwise or (|) in void context" at compile time, which neither
  project can stop; checked here, and the docs keep the result.
- **2026-11-12:** Ekorn-Pipeline's two messages. Iain renamed two of
  its sinks, as its D53 (Ekorn-Pipeline
  1fffaa19d42306effac4825bcbf6d295f9075d30): `count` is `count_items`,
  and `only_item` is `single_item`. And he dropped its containers for
  arrays and hashes, as its D54 (Ekorn-Pipeline
  5c800d9f55c4ca013a6f000d6fb466e174bb2626), which overtakes D15. The
  design takes both in, and its tests are to import `all_items` beside
  Test2::V0 as Ekorn's do, with `use Test2::V0 qw(!all_items)`. None of
  DBIx::Squirrel's code or tests used the sinks, so nothing else
  changes.
- **2026-11-12:** Ekorn-Pipeline's next two messages. Iain renamed
  three of its sinks, as its D55 (Ekorn-Pipeline
  2078ed2348b385b93087a656d30420a7f3651c2e): `all_items` is `keep_all`,
  `first_item` `keep_first`, and `single_item` `keep_single`;
  `count_items` keeps its name. And its `last_item` became `keep_last`,
  built, as its D56 (Ekorn-Pipeline
  c1cceddbffd5f6a643f14e3d1ea9bd48f6d01114): the last item, or `undef`
  for none, reading every item to find it. The design takes both in.
  `keep_all` doesn't clash with Test2::V0's `all_items`, so its tests
  need no `qw(!all_items)`, and the half of D19 about Test2::V0 falls
  away.
- **2026-11-12:** Iain asked for a `keep(N)` sink, "So we have `take`
  for stages, `keep...` for sinks", sent to Ekorn-Pipeline as a task.
  Its message: built as its D57 (Ekorn-Pipeline
  fccef9cd7a3e6d18b538327d76da1983d0944832), a list sink giving the
  first N items, stopping the run once it has them, with N checked as
  `take` checks it, and a negative N croaking. The design lists it.
- **2026-11-12:** Ekorn-Pipeline's two messages on its iterator's
  `all`, `first` and `single`, its D59 (Ekorn-Pipeline
  1c10f0ce3e703936f983f0f82ffc902bbd1e4529) and D60, a lookahead that
  consumes nothing (Ekorn-Pipeline
  15578ab00286da51edb502c7af7fb1f48b197617). Iain decided the same for
  DBIx::Squirrel's iterator, D22, and D23 asks whether it delegates.
- **2026-11-12:** the spike of TODO task 4, against Ekorn-Pipeline
  cbed0387a9aa462fbecf294b9029887560a4dc8e (its D61, `single`
  finishing). `DBIx::Squirrel::Iterator` is rebuilt as the design's
  section 4 has it: the statement's source is made with Ekorn's
  `source`, its batches grow from 2 to 64 and are the run's own, its
  stages are run by `Ekorn::Pipeline`, and `all`, `first` and `single`
  delegate to Ekorn's iterator, with `all`'s fast path and `reset`
  clearing. `t/24-iterator-source.t` tests it, with 4.6's four
  guarantees; the tests D22 and D25 change are changed. All 27 test
  files pass but `t/06-gather.t`'s two known failures, and coverage
  meets its floors (branches 97.0%, the floor).

  What it found:

  - **4.6's first guarantee holds by the structure,** not a check: the
    iterator ends a run before it starts another, and Ekorn calls
    nothing of a run that has ended. A token checked in the step and the
    end, built first, could never be false, and went.
  - **The batch is the run's,** not the iterator's: the step held it
    through the iterator, weakly, so a pipeline reading the iterator
    after it was let go would have read nothing.
  - **The stage counting results for `result_number` isn't put after a
    sink,** whose result is the run's.
  - **The Sugar keeps giving every result, or a count by context,**
    from `all`, until section 6's work makes it give an iterator.
  - **A regression in Ekorn,** sent to it as a task: a flush giving n
    values, followed by a stage, takes time in n squared, pushed or
    pulled, as each value reaching the end scans every value waiting
    (`grep { $_->[0] < @stages } @todo` in `$end_if_ended`,
    `lib/Ekorn/Pipeline.pm` line 508). 20,000 values took 6.5 s, where
    v0.2.0 takes 0.03 s.

  **Timing,** for Q30: Iain's OSM gazetteer
  (`jdc-lab/local/osm/gazetteer.sqlite`), opened read-only, three
  tables: `place_areas`, 297,848 narrow rows; `places`, 104,082 rows,
  polygons of 1.6 KB on average; `areas`, 21,826 wide rows, polygons
  of 24 KB. Each case in a process of its own, warmed once, then the
  mean of three reads, in seconds; "before" is the commit before the
  spike, 1fb24bd. A first run with every case in one process, under
  Benchmark, slowed `selectall_arrayref` itself by half in the
  spike's process, so it isn't used.

  | Table | Case | Before | Spike |
  |---|---|---|---|
  | place_areas | `selectall_arrayref` | 0.096 | 0.095 |
  | | `$it->all` | 0.108 | 0.403 |
  | | `$it->all`, with a stage | 0.540 | 0.655 |
  | | `next`, to the end | 0.351 | 0.542 |
  | | `$it \| keep_all` | | 0.807 |
  | places | `selectall_arrayref` | 0.078 | 0.078 |
  | | `$it->all` | 0.090 | 0.186 |
  | | `$it->all`, with a stage | 0.239 | 0.278 |
  | | `next`, to the end | 0.168 | 0.235 |
  | | `$it \| keep_all` | | 0.334 |
  | areas | `selectall_arrayref` | 0.172 | 0.178 |
  | | `$it->all` | 0.174 | 0.185 |
  | | `$it->all`, with a stage | 0.204 | 0.214 |
  | | `next`, to the end | 0.169 | 0.183 |
  | | `$it \| keep_all` | | 0.227 |
  | areas | the first row, 1,000 times | 5.311 | 0.264 |

  So: the growing batch makes the first row of wide rows 20 times
  quicker. Fetching dominates wide rows, and there the spike costs 5 to
  8%. On narrow rows, Ekorn's cost for each value shows: `next` is 54%
  slower, and `$it->all` 3.7 times slower than before, though its
  source gives every row in one step, as Ekorn's run wraps each value
  it's given (`push @todo, map { [0, $_] } reverse @values`, line 544)
  and its iterator's `all` collects them one call at a time.
  `$it | keep_all` is twice as slow as `$it->all`. `$it` here is
  `$sth->iterate`, and `|` is `Ekorn::Pipeline->new(keep_all)->iterator($it)`.

  The script, run as `perl -Ilib one.pl TABLE CASE 3` with Ekorn's
  working copy first on `PERL5LIB`:

  ```perl
  use v5.36;
  use Time::HiRes qw(time);
  use DBD::SQLite;
  use DBIx::Squirrel;
  my($table, $case, $times) = @ARGV;
  my $dbh = DBIx::Squirrel->connect(
      'dbi:SQLite:dbname=/Users/icampbell/Git/github.com/nukopian/jdc-lab/local/osm/gazetteer.sqlite', '', '',
      {RaiseError => 1, sqlite_open_flags => DBD::SQLite::OPEN_READONLY()},
  );
  my $sql = "SELECT * FROM $table";
  my $sth = $dbh->prepare($sql);
  my $keep_all = DBIx::Squirrel::Iterator->can('first')
      && do { require Ekorn::Pipeline::Sinks; \&Ekorn::Pipeline::Sinks::keep_all };
  my %code = (
      selectall => sub { my $r = $dbh->selectall_arrayref($sql) },
      all       => sub { my @r = $sth->iterate->all },
      stage     => sub { my @r = $sth->iterate(sub { $_[0] })->all },
      next      => sub { my $it = $sth->iterate; 1 while my($r) = $it->next },
      chain     => sub { my @r = Ekorn::Pipeline->new($keep_all->())->iterator($sth->iterate)->all },
      first     => sub { for (1 .. 1000) { my $it = $sth->iterate; my($r) = $it->next; $it->sth->finish } },
      first_m   => sub { for (1 .. 1000) { my $r = $sth->iterate->first } },
  );
  $code{$case}->();    # warm the page cache
  my $t = time;
  $code{$case}->() for 1 .. $times;
  printf "%.3f\n", (time - $t) / $times;
  ```

  Q30 waits on Iain, with these numbers.
- **2026-11-12:** Ekorn-Pipeline's two messages: the flush followed by
  a stage is linear again (Ekorn-Pipeline
  2fe666313e1462d4d9c88b0d91f8b603a893e1cc), and, as its D62, a
  step's many values are cheap and its iterator's `all` takes them in
  bulk (Ekorn-Pipeline f1cb2da14a307f0c6b1d7c0529fc0c61de97628e),
  internally, with no protocol changed. Against f1cb2da, the tests
  stand as before: 26 of 27 files pass, and `t/06-gather.t`'s two
  failures are v0.3.0's intended changes. Timed again, as before, in
  seconds:

  | Table | Case | v2 | Spike, Ekorn cbed038 | Ekorn f1cb2da |
  |---|---|---|---|---|
  | place_areas | `selectall_arrayref` | 0.096 | 0.095 | 0.099 |
  | | `$it->all` | 0.108 | 0.403 | 0.150 |
  | | `$it->all`, with a stage | 0.540 | 0.655 | 0.709 |
  | | `next`, to the end | 0.351 | 0.542 | 0.489 |
  | | `$it \| keep_all` | | 0.807 | 0.685 |
  | | `iterate(keep_all)` | | | 0.546 |
  | | `iterate(keep_all, $stage)` | | | 1.126 |
  | places | `selectall_arrayref` | 0.078 | 0.078 | 0.079 |
  | | `$it->all` | 0.090 | 0.186 | 0.105 |
  | | `$it->all`, with a stage | 0.239 | 0.278 | 0.295 |
  | | `next`, to the end | 0.168 | 0.235 | 0.208 |
  | | `$it \| keep_all` | | 0.334 | 0.284 |
  | | `iterate(keep_all)` | | | 0.235 |
  | | `iterate(keep_all, $stage)` | | | 0.432 |
  | areas | `selectall_arrayref` | 0.172 | 0.178 | 0.173 |
  | | `$it->all` | 0.174 | 0.185 | 0.179 |
  | | `$it->all`, with a stage | 0.204 | 0.214 | 0.217 |
  | | `next`, to the end | 0.169 | 0.183 | 0.177 |
  | | `$it \| keep_all` | | 0.227 | 0.207 |
  | | `iterate(keep_all)` | | | 0.203 |
  | | `iterate(keep_all, $stage)` | | | 0.248 |
  | areas | the first row, 1,000 times | 5.311 | 0.264 | 0.255 |

  `$it->all` over narrow rows is 1.4 times version 2's, from 3.7.
  The rest is each value's cost: `next` is 39% slower than version 2's,
  a stage 31%, and a sink last, `iterate(keep_all)` or `|`, five times
  `$it->all`, as each row comes from its own step, a batch row at a
  time, and goes through the sink's step alone. Ekorn names what's
  left for each value going through a stage: a `try` and two `local`s,
  and the `&{}` overload on each call of an Element; it offers to look
  at them if asked.
- **2026-11-12:** Ekorn-Pipeline's message on D30's task, its D63
  (Ekorn-Pipeline df8efc42cda9338a1a62264b597d24d3e74e0a5f): the `&{}`
  overload costs about 0.03 s over 300,000 pulls, and stays, with
  `\&$it`, taken once, documented for a loop. A pipeline reading
  DBIx::Squirrel's iterator doesn't pay it, as Ekorn's run takes the
  code reference already; its 0.67 s over 297,848 narrow rows is the
  `try` and `local`s for each value through a stage, which D30 keeps.
  DBIx::Squirrel's `next` could take the code reference once, at the
  run's start, for those 0.03 s; that waits on Iain.
- **2026-11-12:** Iain chose that `next` takes the run's code
  reference once, at the run's start, as Ekorn's D63 suggests, rather
  than pay the `&{}` overload on each call. The iterator holds the run,
  so the code reference never outlives it, and `_finish` drops both.
  Timed three times each, `next` to the end: over `place_areas`, 0.369
  s to 0.334 s; over `places`, 0.176 s to 0.162 s; version 2 took
  0.351 s and 0.168 s.
- **2026-11-12:** Iain has read the design, and likes it. He's
  reviewing Ekorn-Pipeline's design, the bigger, and both are approved
  together, before either is split into items.

