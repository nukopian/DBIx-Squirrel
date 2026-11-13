# 2026-0020. The how-to's tests check what its examples print

**Status:** shipped, unreleased, on `pipeline-experimental`

**Decisions:** None. Iain decided on 2026-11-13 that it be done
before 2026-0021, so the user guide is written against it.

**Origin:** found in 2026-0016, whose Sugar examples printed
iterators where their comments showed names, and passed; added as an
idea on 2026-11-13, at Iain's agreement.

**Started:** 2026-11-13

**Finished:** 2026-11-13

## Background

`xt/howto.t` runs every example in `docs/HOWTO.md` as one program,
and checks that it runs without warnings or errors, and prints
something. It doesn't check what each prints against the comments
beside it, which is what a reader trusts.

## The plan

**What:** `xt/howto.t` marks where each example's output starts, and
compares it, line by line, with what the example's comments say it
prints, by a rule the guide follows:

- a comment at the end of a line that prints, with `say` or `print`,
  is what that line prints;
- comment lines straight after a line that prints, with no comment of
  its own, or after the end of a block that prints, are what it
  prints, a line each;
- `...` stands for any text, such as a file's path or a line number.

**Why:** an example whose output drifts from its comments misleads
the reader, and nothing caught it.

**Steps:** the rule in `xt/howto.t`; the how-to following it.

**Done when:** each example's output is compared with its comments,
a mismatch fails naming the example's line, and the how-to passes.

## What happened

- **2026-11-13, outcome:** as planned. Against the old how-to, the
  rule failed 19 of its 86 examples, nearly all comments describing
  what was printed ("Parklife, six times"; "Abba, Blur, Cream" for
  three lines) rather than showing it. As 2026-0021 was about to
  replace the how-to, they weren't corrected one by one: the user
  guide was written against the new test, kept uncommitted, and the
  test committed after it, so that each commit passes. All 85
  examples the guide runs pass.
- **Not done:** Ekorn-Pipeline checked its own guide with a script it
  hasn't committed; this test is DBIx-Squirrel's own.
