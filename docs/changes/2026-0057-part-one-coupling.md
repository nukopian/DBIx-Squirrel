# 2026-0057. What Part 1 still takes from Ekorn::Pipeline's code

**Status:** shipped, unreleased

**Decisions:** D1 settled: Tooling's own list, 2026-0059. D2 settled:
the upper bound stays until Ekorn's v1.0.0. D3 settled: `is_stop`,
2026-0060. D4 settled: `is_stage`, 2026-0061. D5 settled: `dump_to`'s
setting, 2026-0062. D6 settled: both messages sent.

**Origin:** roadmap, added 2026-11-26

**Depends on:** 2026-0058

**Finished:** 2026-11-26

## Background

With the documents split (2026-0052 to 2026-0058), Part 1 of each
says what DBIx::Squirrel does without naming Ekorn::Pipeline, and
what it still can't say shows plainly. This item lists what Part 1
still takes from Ekorn::Pipeline's code, by what a caller sees and
what CI checks, and makes an item of each link worth cutting.

Part 1's code runs on Ekorn::Pipeline, as designed in 2026-0013: its
stages, stops, `gather` and runs are Ekorn's, exported under
DBIx::Squirrel's names from lists of DBIx::Squirrel's own, so a name
Ekorn adds reaches its users only once DBIx::Squirrel lists it. That
is the dependency, not a link to cut. The links are the places where
a change of Ekorn's reaches a caller, or fails our CI, without a
choice of ours:

1. **Tooling's tags follow Ekorn's.** `xt/ekorn-tooling.t` fails when
   Ekorn::Pipeline::Tooling's tags hold a name ours don't, so a name
   Ekorn adds in any v0.4.x must be added to ours, in a release
   (2026-0025, 2026-0034).
2. **The range's upper bound,** `< v0.5.0`, so each minor version of
   Ekorn's needs a release of ours to be installable with it.
3. **A stop's class.** A stage catching errors must pass on a stop;
   Part 1 can only say to pass on any error that's an object, as the
   class, `Ekorn::Pipeline::Stop`, is Ekorn's.
4. **`is_stage`,** to find the stages at the end of a list of any
   length, is Ekorn's; Part 1 shows a function with a fixed number of
   values instead.
5. **`dump_to`'s setting,**
   `$Ekorn::Pipeline::Stages::Taps::DumpSecrets`,
   is Ekorn's variable.
6. **Two messages to Ekorn-Pipeline,** not code of ours: a way into
   its documents for readers coming from DBIx::Squirrel (from the
   roadmap), and an iterator's `next`, which DBIx::Squirrel's iterator
   has and a pipeline's lacks (2026-0055).

What CI checks of Ekorn's otherwise stays: `t/28-tooling.t`, that a
name both export is one sub (2026-0025, D6), and the link checks in
`xt/manuals.t` and `xt/reference-index.t`, which find a section of
Ekorn's manuals Part 2 links to that's gone. Those catch a real fault
in our documents, so they aren't links to cut.

## Decisions

- [x] **D1.** Tooling's tags: a stated list of our own, or Ekorn's?
  Our own, as Iain decided on 2026-11-26, as recommended: 2026-0059.
  Tooling exports the names it lists, `xt/ekorn-tooling.t` goes, and
  a name Ekorn adds comes into Tooling when we choose, in a release
  that adds. A caller sees no change today.
- [x] **D2.** The upper bound? Kept until Ekorn::Pipeline's v1.0.0, as
  Iain decided on 2026-11-26, as recommended, and this link dropped: a
  minor version of a v0.x may change its interface, and the bound
  keeps an install from taking one we haven't tested.
- [x] **D3.** A stop's class? DBIx::Squirrel::Stop exports `is_stop`,
  on request, true of any stop, so Part 1's catch can pass on stops
  alone without naming Ekorn, as Iain decided on 2026-11-26, as
  recommended: 2026-0060.
- [x] **D4.** `is_stage`? An item, 2026-0061, as Iain decided on
  2026-11-26. The recommendation had been to drop it, as a function
  with a fixed number of values covers most callers. Which module
  exports it is its D1.
- [x] **D5.** `dump_to`'s setting? An item, 2026-0062, as Iain decided
  on 2026-11-26. The recommendation had been to drop it, as a
  debugging aid, rarely set. How it's set is its D1.
- [x] **D6.** The two messages to Ekorn-Pipeline? Both sent, as Iain
  decided on 2026-11-26, as recommended.

## What happened

- **Outcome:** done. Each link is an item, 2026-0059 to 2026-0062, or
  dropped with its reason, as D2 is; both messages are sent (below).
  No `Changes` line, as nothing changes for a caller until the items
  ship.
