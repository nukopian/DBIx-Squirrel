# 2026-0049. A quality release

**Status:** shipped, unreleased

**Decisions:** D1 settled: the review's questions settled in Ekorn's
2026-0053 hold here. D2 settled: the fixes ship in v4.0.0, with
2026-0048. D3 settled: `prepare_cached`'s fallback for a subclass is
kept, and tested. D4 settled: all 13 findings fixed as proposed.

**Origin:** a message from Ekorn-Pipeline's session, 2026-11-25
(Ekorn-Pipeline 707bbc2d310f70c8f9e110990b98bd667edc9822), relaying
Iain's request for a quality review, and its own 2026-0053

**Started:** 2026-11-25

**Finished:** 2026-11-25

## Background

Iain asked Ekorn-Pipeline's session for a quality review, and then
asked for the same here:

> I'd like a thorough quality review conducted. We are looking for
> inefficient and inconsistent code, errors, untested code,as well as
> code that should be but is not documented. We're also looking for
> slop and hallucinations, as well as documentation that is poor
> quality. The next release is a quality release.

The review read the code, ran the tests under coverage against Ekorn
v0.4.0 (b9b78eef7314664370123c00bb0819edd5367b57), on Perl 5.36.3, and
with MySQL and PostgreSQL, ran Perl::Critic and Perl::Tidy on 5.44.0,
checked each `croakf` message against a DIAGNOSTICS entry, and checked
the docs' claims, version notes and examples. What it found sound:
coverage above every floor; Perl::Critic and Perl::Tidy clean on
`lib`; all 37 messages documented; no regex without `x`; no "new in"
notes; no roadmap ids in the user's docs.

## Decisions

- [x] **D1.** Settle again what Ekorn's 2026-0053 settled? No, Iain,
  2026-11-25: its D2 (`pipe` as a pipeline, taken by 2026-0048), D3
  ("new in" notes), D4 (blank lines above subs) and D5 (a `$VERSION`
  in every module) hold here as settled, not asked again.
- [x] **D2.** Ship the fixes in a v3.6.x first, as Ekorn's went out in
  v0.3.16 before its v0.4.0? No, Iain, 2026-11-25: in v4.0.0, with
  2026-0048, as `pipe`'s change was already on `develop`.
- [x] **D3.** `prepare_cached`'s `else`, which sets what was studied
  on a handle whose `private_ekorn` is unset, never ran: drop it, or
  keep and test it? Keep and test, Iain, 2026-11-25: only a subclass
  whose `prepare` skips ours reaches it, and the reference documents
  subclassing.
- [x] **D4.** Fix all 13 findings as proposed, as 2026-0049? Yes,
  Iain, 2026-11-25.

## The plan

Fix each finding, with a test where it changes what the code does:

1. A test that a pipeline of the caller's own, reading a `|` chain
   made from an iterator, gets the row from `result_original`, as
   Context's POD promises (Ekorn's F1).
2. "Upgrading from 3.x" in the reference, for v4.0.0's `pipe`, and
   the README and the POD saying this is version 4.
3. A `$VERSION` in each of the 17 modules without one, and a test
   keeping them in step, as Ekorn's `t/34-versions.t` (D5).
4. One blank line above each of the 36 commented subs with two, in
   `lib/`, `t/`, `xt/` and `scripts/` (D4), and Ekorn's note on
   Perl::Tidy in CLAUDE.md.
5. The README's examples compiled by `xt/examples.t`, as Ekorn
   compiles its own (Ekorn's F15).
6. A test of `prepare_cached` after a subclass's `prepare` that skips
   ours (D3).
7. The unreachable `return` in `Placeholders.pm`'s `_values_for`
   gone.
8. A select method whose values fail to bind returning what a failed
   `prepare` does: `undef` where the method returns a reference.
9. One figure, 19 ns, for a signature's cost per call.
10. "A plain re-export", as `Stop.pm` says, not "a facade", in
    Gather and the Stages modules.
11. The comments left short by edits rewrapped.
12. The iterator's POD and the reference giving the measured 7% for
    a batch bigger than 64; and no blank line between `1;` and
    `__END__`.
13. The local `lastlog.jsonl`, linking to a log macOS had cleaned
    up, removed, so yath links its new log again.

Done when each is fixed, the tests pass, and `Changes` itemises them.

## What happened

- **Outcome:** as planned; each finding fixed. The tests pass on Perl
  5.36.3 under coverage, and on 5.44.0 with yath and prove, against
  Ekorn-Pipeline's working copy at
  872599c635c1cdd3f5fa8a0b82b30a3a5fa740f0, a docs commit after its
  v0.4.0; MySQL's and PostgreSQL's pass on 5.36.3. Coverage: branches
  97.8%, conditions 90.4%, statements 99.5%, subs 99.4%, POD 100%.
- **The tests bite:** finding 1's fails against Ekorn v0.3.15, before
  its fix, and passes from v0.3.16; finding 8's fails without the fix.
  A README example broken on purpose fails finding 5's check.
- **Changes from the plan:** `t/31-versions.t` finds the modules under
  `DBIx/Squirrel` and `DBIx/Squirrel.pm` only, not all of `DBIx`, where
  other distributions install theirs. The README's two `cpanm` lines
  are marked `=for not-run`, as they aren't Perl.
- **What's left:** nothing.
