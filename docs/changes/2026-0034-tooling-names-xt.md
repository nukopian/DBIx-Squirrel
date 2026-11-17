# 2026-0034. A name Ekorn adds to its Tooling fails only our CI

**Status:** shipped in v3.1.1

**Decisions:** D1 settled: the completeness checks become an author
test; the same-sub checks stay. D2 settled: two releases, v3.1.1 for
this, v3.2.0 for `tee` (2026-0035).

**Origin:** a TODO task from Ekorn-Pipeline's session, 2026-11-17
(Ekorn-Pipeline 369c2cca7ac27c6bf3a9b9e73a5da2d6dc2a84f3, its
pre-release wash-up of its 2026-0048)

**Started:** 2026-11-17

**Finished:** 2026-11-17

## Background

`t/28-tooling.t` checked that DBIx::Squirrel::Tooling holds every name
Ekorn::Pipeline::Tooling exports, tag by tag (2026-0025, D6). Ekorn's
next v0.3.x, v0.3.6, adds `tee` to its `:taps`, and so to `:stages`
and `:all`. Run against Ekorn's `develop` at
9b206d0b972bb141647f1e123088218f76875c8e, the test failed on 5.36.3
and 5.44.0, in "Ekorn's tags, by the same names, with the same words"
and "each name both export is one sub"; nothing else did.

v3.1.0, on CPAN, takes Ekorn `>= v0.3.3, < v0.4.0`, so a fresh
install after v0.3.6 is out gets it, and v3.1.0's tests fail, and it
doesn't install. As the test stood, any name added to Ekorn's Tooling,
in any v0.3.x, would do the same to every release of ours.

## Decisions

- [x] **D1.** Export `tee`, loosen the test, or both? Both, Iain,
  2026-11-17: exporting it is 2026-0035; here, the checks that ours
  holds every name Ekorn's does move to `xt/ekorn-tooling.t`, which
  CI runs and an install doesn't, so a name Ekorn adds fails our CI,
  which says to list it, and not an installed DBIx::Squirrel. The
  checks that a name both export is one sub, and that both imported
  into one package warn of nothing, stay in `t/`: they guard a user
  who imports both.
- [x] **D2.** Exporting `tee` means importing it from Ekorn by name,
  so requiring Ekorn >= v0.3.6, which isn't out and waits on us. Two
  releases, Iain, 2026-11-17: v3.1.1 with this, which passes with any
  Ekorn v0.3.x, before Ekorn's v0.3.6; v3.2.0 with `tee`, after it.

## The plan

**What:** move the two completeness checks from `t/28-tooling.t` to a
new `xt/ekorn-tooling.t`, tag by tag; keep the same-sub check in `t/`
for the names both export.

**Why:** an installed DBIx::Squirrel can't hold names Ekorn adds after
its release, and mustn't fail its tests for them.

**Done when:** against Ekorn's working copy, `t/` passes and
`xt/ekorn-tooling.t` fails on `tee`; against CPAN's, everything passes;
v3.1.1 is on CPAN.

## What happened

- **Outcome:** against Ekorn 9b206d0, `t/28-tooling.t` passes on
  5.36.3 and 5.44.0, and `xt/ekorn-tooling.t` fails for `:taps`,
  `:stages` and `:all`, lacking `tee`. Against Ekorn v0.3.5, from
  CPAN, the whole suite passes on both, 33 files. Released in v3.1.1,
  2026-11-17.
- **Changes from the plan:** none.
- **What's left:** 2026-0035.
