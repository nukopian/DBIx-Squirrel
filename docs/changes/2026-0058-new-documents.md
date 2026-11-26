# 2026-0058. The new documents in place of the old

**Status:** shipped, unreleased

**Decisions:** None: they're 2026-0052's, and 2026-0053's D2.

**Origin:** roadmap, added 2026-11-26

**Depends on:** 2026-0054, 2026-0055, 2026-0056

**Started:** 2026-11-26

**Finished:** 2026-11-26

## Background

2026-0052 settled that the new README, guide and reference be written
in `docs/next/`, with today's left untouched and published until all
three were done, then put in place in one commit (its D6). 2026-0054
to 2026-0056 wrote them, each approved by Iain's sceptical review with
GitHub Copilot, which advised the swap next, and its `Changes` entry.

## The plan

**What:** `docs/next/`'s README, guide and reference in place of
today's, with the manuals and `README.md` made from them, the tests
reading `docs/` and `README.pod` again, and the `Changes` entry.

**Why:** the new documents are approved, and while they wait in
`docs/next/` readers still have the old.

**Steps:**

1. `git mv` each of `docs/next/README.pod`, `HOWTO.md` and
   `REFERENCE.md` over today's, which git's history keeps, and remove
   `docs/next/README.md`.
2. `scripts/manuals`, for the manuals' POD, and `minil build`, for
   `README.md`, checking its badge says `branch=main`.
3. The tests that read `docs/next/` read `docs/` and `README.pod`:
   `xt/examples.t`, `xt/spelling.t`, `xt/manuals.t`,
   `xt/reference-index.t` and `xt/part-one.t`, which fails now if a
   document lacks its Part 2 heading.
4. The `Changes` entry, the one readers see for 2026-0052 to
   2026-0056, saying why, as 2026-0052's record asks: the coupling the
   documents showed, the synergy the two parts aim for, and that the
   split's separation is only now being completed (2026-0053's D2).
5. This record, and `ROADMAP.md`.

**Done when:** `yath test -L t xt` passes on 5.36 and 5.44, and
`docs/next/` is gone.

## What happened

- **Outcome:** done. `docs/next/` is gone; `README.pod`,
  `docs/HOWTO.md` and `docs/REFERENCE.md` are the new documents, and
  `lib/DBIx/Squirrel/Manual/HowTo.pod`, `Reference.pod` and
  `README.md` are made from them, its badge on `main`. `yath test -L t
  xt` passes on 5.36 and 5.44, against Ekorn-Pipeline's working copy
  at 446058f8873907be8d53f2befd49bbaa70e6f101, and the document tests
  under `prove` too.
- **Changes from the plan:** `xt/manuals.t`'s check of the drafts
  became a check of `README.pod`: sound POD, no link to Ekorn's
  manuals on GitHub, and each link to a manual finding its section, as
  the README links to the guide's Part 2. `xt/spelling.t` checks
  `README.pod`'s spelling, which before the drafts nothing did.
- **What's left:** 2026-0057, what Part 1 still takes from
  Ekorn::Pipeline's code, now plain in the documents, with the
  candidates 2026-0055's and 2026-0056's records list. The phrase "the
  DBI, minus the boilerplate, plus a pipeline" in `CLAUDE.md`, which
  2026-0052's D8 replaces in time, is Iain's to change.
