# 2026-0046. result_original is Ekorn's own sub

**Status:** shipped, unreleased

**Decisions:** D1 settled: a source's `original` part, as Ekorn
designs it.

**Origin:** roadmap, added 2026-11-24, the other side of
Ekorn-Pipeline's 2026-0051, as Iain asked; split on 2026-11-24, with
taking Ekorn's v0.4.0 moved to 2026-0047

**Depends on:** Ekorn-Pipeline 2026-0052, a source's `original` part,
released in v0.3.13

**Started:** 2026-11-24

**Finished:** 2026-11-24

## Background

Ekorn-Pipeline's 2026-0051 adds `result_number` and `result_original`
to Ekorn::Pipeline::Tooling, in a `:context` tag, our Tooling's name
for its own, and in `:all`, in its first v0.4.0. Not before, as our
v3.5.0's `t/28-tooling.t` fails when both Toolings export different
subs by one name, and our range takes every v0.3.x. Iain likes the idea
of `:context` there.

From our v3.6.0 (2026-0032), our `result_number` is Ekorn's own sub,
so the two agree on it. Our `result_original` is still ours: our
statement's source keeps the row it gave last in the run's context,
and a run reading our iterator, a chain made with `|` or a pipeline of
the user's own, sees that context, so ours gives the fetched row
through chains. Ekorn's, by its 2026-0046's D3, gives the value the
iterator handed out. With both in the Toolings, `t/28-tooling.t` would
fail, and a program importing both `:context`s would get whichever
came last, silently, as both have an empty prototype.

We proposed that Ekorn's `result_original` ask the run's context for
an original (Ekorn-Pipeline 40c755f). Ekorn's session answered, as
Iain passed on, on 2026-11-24, with something better: a source may
give an **`original`** part, a code reference called with no
arguments, returning the original of the value it gave last. Ekorn's
`result_original` calls it, if the run's source gave one or an
iterator passed one on, and otherwise gives the run's own kept
original; it's undef in a flush and the stages after it, either way.
It claims no name in a caller's context, and is called only when
`result_original` is, so a run that never asks pays nothing per value.
An iterator read as a source passes its source's part on, so our row
reaches outer pipelines with no code of ours. It can't speak for a
source whose step gives several values at once; ours does so only when
an iterator has no stages and no pipeline reads it, where nothing can
ask. It only adds, so it's for a v0.3.x, ahead of 2026-0051, which
will depend on it; Ekorn proposed it as its 2026-0052, committed at
dee853233996cb433e8b544e251448f949b26c83, its factory taking the part
by name too (its D6). Tested at its
1bce895f7d3b2eecc387416991514ab99536ed89, before its v0.3.13, with our
source giving the part and our `result_original` as Ekorn's: every
test passed on 5.36 to 5.44, our row reached outer pipelines in every
kind of chain, and a stage reading `result_original` each row was 229
to 270 ns a row quicker, 12 to 14%.

Our side, then: the statement source gives `original => sub {
$context->{row} }`, our `result_original` becomes Ekorn's sub under
our name, and the floor rises to the Ekorn release with the part.
Taking Ekorn's v0.4.0, with the names in its Tooling, is 2026-0047.

## Decisions

- [x] **D1.** How do the two Toolings agree on `result_original`? Our
  proposal, a key in the run's context; Ekorn's `:context` holding
  `result_number` alone; or our `t/28-tooling.t` excusing the name.
  Ekorn's answer: a source's `original` part, as above, which we
  recommend over all three. Settled as "a source part, as Ekorn designs
  it" on 2026-11-24, once Ekorn committed its 2026-0052
  (Ekorn-Pipeline dee853233996cb433e8b544e251448f949b26c83), as its
  session suggested: it claims no name in a caller's context, costs a
  run nothing until asked, and carries our row through chains with no
  code of ours.

## The plan

**What:** our statement source gives Ekorn's `original` part, and our
`result_original` is Ekorn's own sub, under our name, as D1 settled.

**Why:** so the two Toolings agree on every name when Ekorn's gains
`:context` (Ekorn's 2026-0051, our 2026-0047), and a stage reading
`result_original` pays one call, not a look at the run's context:
229 to 270 ns a row quicker in the test against Ekorn's 1bce895.

**How:** `_statement`'s set-up returns `original => sub {
$context->{row} }` beside its step, end and context; Ekorn's iterator
passes it through chains. `result_original` is
`\&Ekorn::Pipeline::Context::result_original`, as `result_number` is.
`statement_context` stays, for `pluck` and `as_hash`.

**Steps:**

1. Raise the floor to Ekorn::Pipeline v0.3.13 in `cpanfile`, and make
   `META.json` again.
2. Change `Iterator.pm` and `Context.pm`, and Context's POD.
3. Tests: `t/26-context-in-pipelines.t` checks `result_original` is
   Ekorn's sub, with its empty prototype, and that a chain's outer
   pipelines, two deep, see the fetched row.
4. The reference and the user guide, where they say how
   `result_original` works; `scripts/manuals`.
5. Measure a stage reading `result_original`, and one that doesn't,
   over `place_areas`, before and after, on 5.36 and 5.44.
6. `Changes`, coverage, and the style checks.

**Done when:** the tests pass on 5.36 to 5.44 against Ekorn v0.3.13,
coverage holds its floors, the measurements are here, and `Changes`
says so.

## What happened

- **Outcome:** as planned. The tests pass on 5.36.3, 5.38.5, 5.40.5,
  5.42.3 and 5.44.0, MySQL and PostgreSQL included, against
  Ekorn-Pipeline 5e1cf7634bd3b3e5b29ff2175234225c773b89cf (v0.3.13),
  and coverage holds its floors. `t/26-context-in-pipelines.t` checks
  that `result_original` is Ekorn's sub, with an empty prototype, and
  gives the fetched row two pipelines from the statement.
- **Changes from the plan:** none. The user guide needed no change; the
  reference's three passages on how `result_original` works say the
  source gives Ekorn the row.
- **Measurements:** all 297,848 rows of `place_areas`, ns a row, best
  of five, through one stage passing the row on ("bare") or one
  calling `result_original` ("reading"); before is DBIx::Squirrel at
  7301f0ad89aaf465a58c11fb9089b94807842784, v3.6.0's code, with Ekorn
  v0.3.12; after is this commit's, with Ekorn v0.3.13:

  | | before | after | gain |
  |---|---|---|---|
  | `next`, bare, 5.36 | 1,723 | 1,713 | 10 (0.6%) |
  | `all`, bare, 5.36 | 1,406 | 1,411 | -5 (-0.4%) |
  | `next`, reading, 5.36 | 2,177 | 1,931 | 246 (11.3%) |
  | `all`, reading, 5.36 | 1,876 | 1,634 | 242 (12.9%) |
  | `next`, bare, 5.44 | 1,642 | 1,630 | 12 (0.7%) |
  | `all`, bare, 5.44 | 1,342 | 1,346 | -4 (-0.3%) |
  | `next`, reading, 5.44 | 2,111 | 1,852 | 259 (12.3%) |
  | `all`, reading, 5.44 | 1,819 | 1,581 | 238 (13.1%) |

  So a stage reading `result_original` is 238 to 259 ns a row quicker,
  11 to 13%, and one that doesn't is the same, within a run's noise.
- **What's left:** nothing; taking Ekorn's v0.4.0 is 2026-0047.
