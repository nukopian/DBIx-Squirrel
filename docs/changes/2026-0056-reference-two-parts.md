# 2026-0056. The reference in two parts

**Status:** shipped, unreleased

**Decisions:** None: they're 2026-0052's, and 2026-0053's.

**Origin:** roadmap, added 2026-11-26

**Depends on:** 2026-0052, 2026-0053

**Started:** 2026-11-26

**Finished:** 2026-11-26

## Background

2026-0054 and 2026-0055 wrote the README and the guide in two parts,
each approved by Iain's sceptical review with GitHub Copilot, which
advised putting the effort into the reference next. Its examples
import what they use, as Iain asked of the guide, and `xt/examples.t`
checks it of every document in `docs/next/`.

Today's reference, `docs/REFERENCE.md`, has 16 chapters, then "Making
each kind of part", "Differences from plain DBI", three notes on
upgrading, and the index (2026-0039 to 2026-0042, 2026-0051), which
`xt/reference-index.t` keeps in step with the code. Its set-up imports
everything from Tooling, and "Importing: DBIx::Squirrel::Tooling"
comes before its first chapter. `keep_all` appears in it 25 times, and
Ekorn 173 times, as it says how DBIx::Squirrel's stages, stops and
runs are Ekorn::Pipeline's.

## The plan

**What:** `docs/next/REFERENCE.md`, the reference in two parts, from
`docs/REFERENCE.md`, its index too.

**Why:** the reference is the third document, and the last before the
swap (2026-0058).

**Steps:**

1. Assemble it from today's chapters, by heading, with a new opening
   (2026-0052's D8, and the two parts), a set-up importing only
   DBIx::Squirrel, an "At a glance" without sinks, and Part 2's
   introduction, a sentence on the split with a link to the guide's
   telling of it (2026-0053's D2):
   - **Part 1**, chapters 1 to 12: today's 1 to 7, 9 (result sets),
     12 (the Sugar, but its pipelines), 13 (caching), 14 (writing
     stages) and 16 (errors), then "Differences from plain DBI" and
     "Where you can stop";
   - **Part 2**, chapters 13 to 17: importing from Tooling, sinks,
     pipelines with the Sugar's, operators, and protocols; then
     "Making each kind of part", the notes on upgrading, and the
     index, which covers both parts.
2. Renumber the links, to the reference's chapters and the guide's.
3. Rewrite each passage the D5 test finds in Part 1, moving what it
   says of Ekorn::Pipeline to Part 2, and give each example the
   imports it needs.
4. `xt/reference-index.t` checks the new reference's index as it
   checks today's.
5. Run the document tests and `yath test -L t xt` on 5.36 and 5.44.
6. This record, and `ROADMAP.md`.

**Done when:** `xt/part-one.t`, `xt/examples.t`, `xt/spelling.t`,
`xt/manuals.t` and `xt/reference-index.t` pass on it, `yath test -L t
xt` passes on 5.36 and 5.44, and Iain's sceptical review approves it.

## What happened

- **Outcome:** done. `docs/next/REFERENCE.md` is written, and approved
  by Iain's sceptical review with GitHub Copilot (below). Its 81
  examples run, print what their comments say, and import what they
  call; the D5 test, the POD checks and the index's checks pass on it;
  and `yath test -L t xt` passes on 5.36 and 5.44, against
  Ekorn-Pipeline's working copy at
  446058f8873907be8d53f2befd49bbaa70e6f101. Part 1 has `keep_all` none
  of the 25 times today's reference has it, and names Ekorn only in
  Contents, giving Part 2's heading, where today's names it 173 times.
- **Moved to Part 2,** as Part 1 now says what each does without
  naming Ekorn::Pipeline: a stop's class, `Ekorn::Pipeline::Stop`, and
  its `throw`; `gather`'s class; `is_stage`, for finding the stages at
  the end of a list; how Context's functions work in a chain or a
  pipeline; `dump_to`'s `DumpSecrets`; the Sugar's pipeline names; and
  the messages of what Part 2 adds, under "Messages of the pipeline",
  in chapter 17. Part 1 passes on any error that's an object, as the
  guide does.
- **Changes from the plan:** "Importing: DBIx::Squirrel::Tooling"
  became "13. Import everything from one place", as in the guide, so
  that Contents, in Part 1, names nothing of Ekorn's. `xt/part-one.t`
  now counts a plain-word name, such as `stage` or `keep`, in the text
  only as code of its own, alone or called, so the reference's
  messages, quoted as code, such as `Expected stage #%s, made with
  gather, to return a code reference or a pipeline`, aren't counted.
  A name with an underscore still counts anywhere.
- **For 2026-0057:** what Part 1 can't say without naming Ekorn:
  a stop's class, `dump_to`'s setting, and `is_stage`.
- **The review,** by GitHub Copilot on 2026-11-26, as a sceptical,
  pragmatic reader: "Approved". Part 1 is a complete reference: a
  reader looking up any of its features finds the behaviour there, with
  no "learn Ekorn first" gap. "Part 1 says what it does, Part 2 says
  what it is" it called the reference's strongest idea; passing on any
  error that's an object is a sound rule for Part 1, with Part 2's
  class test for those who want it; the index belongs at the end,
  whole; and chapter 17 reads as a real Protocols chapter, not a
  dumping ground. Its one note, made: chapter 6, "Stopping a
  pipeline", brought Ekorn's vocabulary into Part 1, so it's now
  "Stopping early", as in the guide. It advised moving on to the swap
  and its `Changes` entry, then the work on the code's coupling.
- **What's left:** the swap (2026-0058), which makes the manual's POD
  from this reference; the candidates for 2026-0057 above.
