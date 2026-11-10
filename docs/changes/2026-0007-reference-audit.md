# 2026-0007. Every claim in the reference, checked

**Status:** in progress

**Decisions:** D1 settled: two items, this audit first, then the
how-to (2026-0008). D2 settled: new checks in `t/23-documented.t`.

**Origin:** roadmap, added 2026-11-10, from Iain, after Ekorn-Pipeline
did the same for its docs (Ekorn-Pipeline
54d260735fd4c86894d8051ae3b48157f0b2b5f2 and
954824dc7f7d84c17b25e0703b4b3459c0108765)

**Started:** 2026-11-10

## Background

Ekorn-Pipeline checked its docs against its code: it matched each claim
in its reference to the test that checks it, and ran every example.
Even after that, omissions turned up. The biggest was that the docs
still said "a code reference" where a pipeline is now accepted. Here,
the same omission showed up in the review of 2026-11-09: a Sugar
statement defined with a pipeline straight after its SQL took the
pipeline for its attributes (2485131), and the how-to had no recipe
for a `gather` block returning a pipeline, a pipeline in a Sugar
statement, or a nested stage's name in a message.

## Decisions

- [x] **D1.** One item or two? Two, Iain decided on 2026-11-10, as one
  would be bigger than an L: this audit of the reference first, then
  the how-to rebuilt (2026-0008), which depends on it. The audit gives
  the how-to a full list of what DBIx::Squirrel does.
- [x] **D2.** Where do the new checks go? In a file of their own,
  `t/23-documented.t`, Iain decided on 2026-11-10, as Ekorn's
  `t/12-documented.t` does: each subtest named for the reference's
  section it checks.

## The plan

**What:** check `docs/REFERENCE.md` against the code, claim by claim.

- Match each claim the reference makes to the test that checks it.
  Where there's none, add a check to `t/23-documented.t`, its subtest
  named for the section.
- Run every example in the reference and the README, and check each
  prints or returns what it says.
- Look for omissions: what the code does that the reference doesn't
  say, especially where a feature added later (a pipeline as a stage,
  `gather`, Sugar) meets an older one. Add them to the reference, and
  to the module's POD where it should say it too.
- Where a claim is wrong, fix whichever is wrong, the docs or the
  code, and note it here.
- New and changed text keeps 2026-0005's rules for plain docs.

**Why:** a reader trusts the reference to say what the code does. A
claim no test checks can drift from the code unnoticed, and an
omission leaves a question with no answer.

**Steps:** one commit for each chapter of the reference, or a few
chapters together where they're short, each with its tests, the
manuals made again, and the tests, `podchecker` and coverage passing.

**Done when:** every claim in the reference has a test that checks
it, every example in the reference and the README does what it says,
each omission found is documented, and the record lists what was
found.

## What happened
