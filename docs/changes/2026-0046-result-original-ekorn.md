# 2026-0046. result_original is Ekorn's own sub

**Status:** open

**Decisions:** D1 open: how the two Toolings agree on
`result_original`; Ekorn's answer recommends a source's `original`
part.

**Origin:** roadmap, added 2026-11-24, the other side of
Ekorn-Pipeline's 2026-0051, as Iain asked; split on 2026-11-24, with
taking Ekorn's v0.4.0 moved to 2026-0047

**Depends on:** Ekorn-Pipeline 2026-0052, proposed: a source's
`original` part, released in a v0.3.x

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
will depend on it; Ekorn proposed it as its 2026-0052.

Our side, then: the statement source gives `original => sub {
$context->{row} }`, our `result_original` becomes Ekorn's sub under
our name, and the floor rises to the Ekorn release with the part.
Taking Ekorn's v0.4.0, with the names in its Tooling, is 2026-0047.

## Decisions

- [ ] **D1.** How do the two Toolings agree on `result_original`? Our
  proposal, a key in the run's context; Ekorn's `:context` holding
  `result_number` alone; or our `t/28-tooling.t` excusing the name.
  Ekorn's answer: a source's `original` part, as above, which we
  recommend over all three. To be settled as "a source part, as
  Ekorn designs it" once Ekorn's 2026-0052 is committed, as its
  session suggested.
