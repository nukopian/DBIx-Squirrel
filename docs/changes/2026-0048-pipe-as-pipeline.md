# 2026-0048. pipe gives what a pipeline gives

**Status:** shipped, unreleased

**Decisions:** D1 settled: `pipe` gives what a pipeline gives, in
either context (Ekorn's 2026-0053 D2). D2 settled: the range is
`>= v0.4.0, < v0.5.0`, not from v0.3.16. D3 settled: the docs say what
`pipe` gave until v4.0.0, as Ekorn's do. D4 settled: the release that
takes it is v4.0.0.

**Origin:** a TODO task from Ekorn-Pipeline's session, 2026-11-25
(Ekorn-Pipeline f1fd15cb4d65000cd4b45451d25abdc84dac8962, on its
branch `experiment/2026-0053-pipe`, released as v0.4.0 at
b9b78eef7314664370123c00bb0819edd5367b57)

**Started:** 2026-11-25

**Finished:** 2026-11-25

## Background

Database and statement handles inherit `pipe` from
Ekorn::Pipeline::Pipes. In Ekorn v0.4.0, `$object->pipe(@stages)` is
`Ekorn::Pipeline->new(@stages)->($object)` in either context: in
scalar context, how many results came out, or a sink's result, where
before it gave the first result, or `undef`. Run against v0.4.0 at
7bacdd000204d5a1e674b5632dad7a885df05540, only `t/03-pipe.t` (two
subtests) and the example at `docs/REFERENCE.md` line 1824 failed;
against v0.3.16, nothing did.

## Decisions

- [x] **D1.** How should `pipe` behave? As a pipeline does, Iain,
  2026-11-25, in Ekorn's session (its 2026-0053 D2), and settled the
  same here, not again.
- [x] **D2.** Move the floor to v0.3.16, for its fix to a `|` chain's
  original? Iain, 2026-11-25: to v0.4.0, `>= v0.4.0, < v0.5.0`. A
  range taking both would leave what `pipe` gives in scalar context
  to whichever Ekorn a user has, while our docs describe v0.4.0's;
  v0.4.0 carries v0.3.16's fix.
- [x] **D3.** Should the docs say what `pipe` gave before? Yes, Iain,
  2026-11-25, aligning with Ekorn for consistency: as its reference's
  text, its index entry and its POD say "Until v0.4.0, in scalar
  context, it gave the first result", ours say the same of v4.0.0.
- [x] **D4.** Which version takes it? v4.0.0, Iain, 2026-11-25,
  aligning with Ekorn: it marked the change by the part of its version
  that says code may need to change, v0.3 to v0.4, which for us is v3
  to v4.

## The plan

The task "Take Ekorn-Pipeline v0.4.0", in TODO.md at
2e921f75dd7b88f7191dbbc253c13979a3c4e18c, in short: the tests and docs take `pipe` as a pipeline, and the
range takes v0.4.0; done when they do, and Ekorn's session has a message saying so.

## What happened

- **Outcome:** as planned. `t/03-pipe.t` reads one value in list
  context, and checks scalar context against a pipeline: a count, 0,
  a sink of one's result, a list sink's array reference, and 1 with no
  stages. The reference's text and synopses, the example at line
  1824, and `DBIx::Squirrel`'s POD say what `pipe` gives now.
- **Changes from the plan:** the note on what `pipe` gave until
  v4.0.0 (D3) came in a second commit, after D3 and D4 were settled.
- **What's left:** nothing.
