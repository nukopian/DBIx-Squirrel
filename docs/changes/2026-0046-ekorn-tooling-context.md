# 2026-0046. Ekorn v0.4.0, and its Tooling's :context

**Status:** open

**Decisions:** D1 open: how the two Toolings agree on
`result_original`.

**Origin:** roadmap, added 2026-11-24, the other side of
Ekorn-Pipeline's 2026-0051, as Iain asked

**Depends on:** Ekorn-Pipeline 2026-0051, released in its first v0.4.0

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
iterator handed out. With both in the Toolings, `t/28-tooling.t` fails,
and a program importing both `:context`s gets whichever came last,
silently, as both have an empty prototype.

Our range is `< v0.4.0`, so taking Ekorn's v0.4.0 needs a release of
ours whatever's decided.

## Decisions

- [ ] **D1.** How do the two Toolings agree on `result_original`?
  (1) Ekorn's asks the run's context for an original first, which a
  source keeps current as it gives each value, so ours can be Ekorn's
  under our name, as `result_number` is; (2) Ekorn's `:context` holds
  `result_number` alone, and `result_original` is exported only by
  Ekorn::Pipeline::Context; (3) our `t/28-tooling.t` excuses the name,
  and our docs warn of importing both. Recommended: (1), with (2) if
  Ekorn's session doesn't take it; (3) leaves the clash silent. It's
  Ekorn's to design, so a message proposing (1) went to its `TODO.md`
  on 2026-11-24, and D1 is settled by its answer.
