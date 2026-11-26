# 2026-0055. The guide in two parts

**Status:** shipped in v4.2.0

**Decisions:** None: they're 2026-0052's, and 2026-0053's.

**Origin:** roadmap, added 2026-11-26

**Depends on:** 2026-0052, 2026-0053

**Started:** 2026-11-26

**Finished:** 2026-11-26

## Background

2026-0052 settled how each document is split, and 2026-0054 wrote the
README by it, approved by Iain's sceptical review with GitHub Copilot,
which advised carrying the same principles into the guide. 2026-0053
settled the split's story, told in full once, at the opening of the
guide's Part 2.

Today's guide, `docs/HOWTO.md`, has 17 chapters. Its opening and "The
layers, at a glance" end in a sink, and "Import everything from one
place" comes before its first chapter, so every example has Tooling's
names. `keep_all` appears in it 29 times, and Ekorn 54 times.
2026-0052's baseline found, in it: `drop_if`'s module not said where
it's used; `do`'s `0E0` not said; `to_json` never shown; and a
pipeline's `iterator` never explained.

## The plan

**What:** `docs/next/HOWTO.md`, the guide in two parts, from
`docs/HOWTO.md`.

**Why:** with the README, the guide carries the sales pitch
(2026-0052's D7), and today's teaches DBIx::Squirrel in
Ekorn::Pipeline's words.

**Steps:**

1. Assemble the new guide from today's sections, by heading, with
   new text for its opening, the parts' introductions and "Where you
   can stop":
   - the opening is 2026-0052's D8, then the two parts and the three
     things Part 1 asks a reader to learn (D4);
   - "The layers, at a glance" ends at the iterator;
   - the examples' database imports each stage from the
     DBIx::Squirrel module that makes it;
   - **Part 1**, chapters 1 to 13: today's chapters 1 to 7, 9 (rows as
     objects), 12 (the Sugar), 13 (caching), 14 (functions that take
     stages), 15 (errors) and 16 (questions), with results from the
     iterator's methods, and what names Ekorn::Pipeline moved out;
     then "Where you can stop";
   - **Part 2**, chapters 14 to 22: 2026-0053's story and what
     Ekorn::Pipeline adds (D4), then "Import everything from one
     place", sinks, files with JSON and CSV, pipelines from
     pipelines, feeds, `tee`, `|` and `@{}`, stages beyond the
     database, and coming from version 1 or 2.
2. Renumber the chapters' links, and fix each passage the D5 test
   finds in Part 1.
3. Close the baseline's gaps, and show gains in pairs, plain DBI
   beside DBIx::Squirrel (D7), checking each claim against plain DBI.
4. Run `xt/part-one.t`, `xt/examples.t` and `xt/spelling.t`, then
   `yath test -L t xt` on 5.36 and 5.44.
5. This record's What happened, and `ROADMAP.md`.

**Done when:** the three tests pass on `docs/next/HOWTO.md`, `yath
test -L t xt` passes on 5.36 and 5.44, and Iain's sceptical review
approves it.

## What happened

- **Outcome:** done. `docs/next/HOWTO.md` is written, and approved by
  Iain's sceptical review with GitHub Copilot (below). Its 102
  examples run and print what their comments say; `xt/part-one.t`
  and `xt/spelling.t` pass on it;
  and `yath test -L t xt` passes on 5.36 and 5.44, against
  Ekorn-Pipeline's working copy at
  446058f8873907be8d53f2befd49bbaa70e6f101. Part 1 has `keep_all`
  none of the 29 times today's guide has it, and names Ekorn only in
  Contents, giving Part 2's heading.
- **The baseline's gaps,** closed: `do` gives `0E0` when nothing
  changes, shown; the stage modules are named where stages are
  introduced, and `drop_if` as on request; JSON written and read back,
  in a recipe of its own; and a pipeline's `iterator` explained in the
  CSV recipe.
- **Pairs,** plain DBI beside DBIx::Squirrel: a list into `IN (...)`;
  a missing value; and a page of rows after a test in Perl.
- **Corrected against plain DBI:** today's guide says plain DBI runs a
  query with a missing value as `NULL`. With `?`, the DBI counts the
  values and fails; bound by name with `bind_param`, a missing one is
  `NULL`, without a word. The pair shows the second.
- **Changes from the plan:** a section in Part 2, "End a caller's
  stages with a sink", shows Part 1's function and named statement
  taking a sink unchanged, the plainest case of the two working
  together. "Why does `my @rows = $it | keep_all` give one element?"
  went, as chapter 20 answers it.
- **The tests:** `xt/part-one.t` now counts a name with an underscore,
  such as `count_items`, in plain text; checks only Perl blocks as
  code, so a diagram is text; and allows the Part 2 heading's words,
  which Contents gives. `xt/spelling.t` checks links to the reference
  against today's until 2026-0056 writes the new one, as the
  converter checks every link. And, as Iain reminded, the guide is
  also `lib/DBIx/Squirrel/Manual/HowTo.pod`, made by
  `scripts/manuals`, and that's what MetaCPAN shows and the README
  links to. So `xt/manuals.t` checks the manuals `docs/next/` will
  make, now, not at the swap: that each is sound POD, links to none of
  Ekorn's manuals on GitHub, and that each link to a manual, the new
  README's among them, finds its section. The README's link to the
  guide's "Part 2: With Ekorn::Pipeline" does.
- **For 2026-0057:** catching errors in a stage, Part 1 passes on any
  error that's an object, as DBIx::Squirrel has no way to name a stop
  of its own; Part 2 names Ekorn::Pipeline::Stop. And an iterator from
  a pipeline has `all`, `first` and `single`, but no `next`, where
  DBIx::Squirrel's has, so the guide says to call it; a message to
  Ekorn-Pipeline could suggest one.
- **The review,** by GitHub Copilot on 2026-11-26, as a sceptical,
  pragmatic reader: "Approve and move forward", with no change
  required. Part 1 reads as complete, with its own identity, learning
  path and stopping point, and Part 2 as additive, not explanatory: a
  reader can learn DBIx::Squirrel without first learning
  Ekorn::Pipeline. The pairs worked better than the README's, the
  page of rows after a test in Perl the strongest, and "End a caller's
  stages with a sink" shows the relationship meant. Its notes, needing
  no change: "The layers, at a glance" is where to cut first, if words
  must go; chapter 13's closing claim is a design argument, not shown
  by an example; and chapter 10, on caching, is operational, so it
  isn't to grow. It advised stopping here, but for factual
  corrections, and putting the effort into the reference.
- **What's left:** the reference (2026-0056), and the swap (2026-0058),
  which makes the manual's POD from this guide; the candidates for
  2026-0057 above.
- **After the review, each example imports what it calls,** as Iain
  noticed on 2026-11-26 that many lacked their `use` lines, leaning on
  the set-up's imports, so an example copied from chapter 6 failed on
  `take`. In Part 1, each imports from DBIx::Squirrel's own module,
  and in Part 2 from Tooling, by name; the set-up imports only
  DBIx::Squirrel. `xt/examples.t` now checks that each example in
  `docs/next/` imports every function it calls of those
  DBIx::Squirrel::Tooling and DBIx::Squirrel::Errors export, as
  neither running the examples, where one example's import reaches
  every one after it, nor compiling them could show it. It found 48
  examples in the guide that didn't, and none in the README.
- **Copilot on the imports,** on 2026-11-26: they change the guide's
  contract with its reader, from "everything is imported in the
  examples' database; remember that while reading" to each example
  showing where its names come from, which reads better in isolation,
  from a link into the middle, and when copied. It revised its earlier
  advice: a short README should keep its imports few, but a long guide,
  read piecemeal and copied from, is better with them.
