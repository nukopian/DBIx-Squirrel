# 2026-0054. The README in two parts

**Status:** shipped, unreleased

**Decisions:** None: they're 2026-0052's, and 2026-0053's D2.

**Origin:** roadmap, added 2026-11-26

**Depends on:** 2026-0052, 2026-0053

**Started:** 2026-11-26

**Finished:** 2026-11-26

## Background

2026-0052 settled how each document is split: Part 1 is
DBIx::Squirrel, complete, and Part 2 is Ekorn::Pipeline, by choice
(D1); which names are Ekorn's (D2); the headings (D3); that Part 1
names what it asks a reader to learn, and ends where they may stop
(D4); the test that keeps the line (D5); where the new documents are
written (D6); how success is measured (D7); and Part 1's opening (D8).
2026-0053's D2 settled that the README tells why the two split in a
sentence, with a link to the guide's telling of it.

The README is written first, as it's the shortest, and the one most
readers meet first, so the D5 test comes with it.

2026-0052's baseline found, in today's README: sinks, words, the
Sugar, `gather`, `|` and `@{}`, `pipe` and `tap`, feeds,
`result_original` and Ekorn::Pipeline, all before its sixth step;
`keep_all` five times, the iterator's `->all` twice; and gaps a cold
reader met: where `\%attr` goes among `iterate`'s bind values, which
module exports `drop_if`, and `do` giving `0E0` when nothing changes.

## The plan

**What:** `docs/next/README.pod`, the README in two parts, and the D5
test, `xt/part-one.t`.

**Why:** the README carries most of the sales pitch (2026-0052's D7),
and today's tells DBIx::Squirrel's story in Ekorn::Pipeline's words.
The test keeps the line from drifting as the other documents are
written.

**Steps:**

1. `xt/part-one.t`, for each document in `docs/next/` with a "Part 2:
   With Ekorn::Pipeline" heading: it fails unless a "Part 1:
   DBIx::Squirrel" heading comes before it, and where anything before
   the Part 2 heading names `Ekorn` (but not the `ekorn_` prefix),
   `DBIx::Squirrel::Tooling`, or a name imported from Ekorn's modules,
   in code, or as code in the text (`C<...>`, `L<...>`, backticks).
   Ekorn's names are worked out when it runs: those
   DBIx::Squirrel::Tooling exports that none of DBIx::Squirrel's own
   modules does, so a name Ekorn adds is caught without a change here.
   Plain words in the text, such as "stage" and "pipeline", aren't
   names, and 1.x used both.
2. Tried on samples, not committed: a Part 1 naming `keep_all` in
   code, `C<to_csv>` in the text, `Ekorn::Pipeline` in a link, and
   `use DBIx::Squirrel::Tooling` each make it fail; `ekorn_slice`
   doesn't; a Part 2 heading without a Part 1 heading fails.
3. `docs/next/README.pod`:
   - it opens with 2026-0052's D8, an example, and the three things
     Part 1 asks a reader to learn: placeholders, the iterator, and
     stages (D4);
   - "Part 1: DBIx::Squirrel": its gains in pairs, plain DBI beside
     DBIx::Squirrel, for work a DBI user does every week, each claim
     followed by the code that shows it (D7); then today's steps,
     with results from the iterator's own methods, stages from
     DBIx::Squirrel's own modules, each named, and the Sugar; where
     `\%attr` goes, `do`'s `0E0`, and that `ekorn_` attributes are
     DBIx::Squirrel's own; ending where a reader may stop (D4);
   - "Part 2: With Ekorn::Pipeline": a paragraph on what it adds, a
     sentence on why the two split, with a link to the guide's
     Part 2 (2026-0053), one example, and links on;
   - Documentation, Installing, Upgrading, Licence and
     Acknowledgements, as today's, after Part 2.
4. Run `xt/part-one.t`, `xt/examples.t` and `xt/spelling.t`; then
   `yath test -L t xt` on 5.36 and 5.44, and perltidy on the test.
5. This record's What happened, and `ROADMAP.md`.

**Done when:** `xt/part-one.t`, `xt/examples.t` and `xt/spelling.t`
pass on `docs/next/README.pod`, `yath test -L t xt` passes on 5.36 and
5.44, and the test fails on each sample of step 2.

## What happened

- **Outcome:** done. `docs/next/README.pod` is written, approved by
  Iain's sceptical review with GitHub Copilot (2026-0052's D7), and
  `xt/part-one.t` keeps its Part 1 to DBIx::Squirrel's own names.
  `xt/part-one.t`, `xt/examples.t` and `xt/spelling.t` pass on it, and `yath test -L t xt` on 5.36 and 5.44,
  against Ekorn-Pipeline's working copy at
  446058f8873907be8d53f2befd49bbaa70e6f101.
- **The test,** tried on samples, not committed: `keep_all` in Part
  1's code, `C<to_csv>` in its text, `L<Ekorn::Pipeline>`, `use
  DBIx::Squirrel::Tooling`, and a missing Part 1 heading each made it
  fail, naming the line; `ekorn_slice`, and "stage" and "pipeline" as
  plain words, didn't. It found Tooling's 25 names from Ekorn.
- **The draft's claims, checked** by running them against the guide's
  database: `do` gives `0E0` when nothing changes; a misspelt name
  croaks with "Expected a placeholder of the statement (play)", and a
  missing one with "Expected a value for each placeholder (none for
  plays)"; `single` warns "Expected only one item, but there were
  more"; a misspelt column method dies; attributes come after the SQL
  and before the values; both handles are the DBI's classes.
- **Changes from the plan:** "Installing" is in Part 1, before "Where
  you can stop", as it's DBIx::Squirrel's own. The link to the guide's
  Part 2 resolves only once 2026-0055's guide is in place (2026-0058).
  Perlcritic flags `die` in the test, as in the other xt tests.
- **The first review,** by GitHub Copilot on 2026-11-26, as a
  sceptical reader: "approve with minor edits"; Part 1 reads as
  complete, and Part 2 as a different job, not the better half held
  back. Its edits, made: the weakest pair, a value used twice, folded
  into the pair on values bound in the wrong place; a stage in the
  opening example, so D8's last sentence is shown at once; a sentence
  saying a large result isn't held in memory; rows as objects and
  named statements called conveniences in "Where you can stop", and
  step 6 begun "If you like", where it suggested marking it optional,
  as every step is; and "The DBI is the foundation", less defensive.
- **The second review,** on 2026-11-26: "Approved". The opening now
  shows SQL, named placeholders, the iterator and a stage in a few
  lines; every pair is about preventing a bug or saying what's meant
  more plainly; and Part 2 reads as something related that solves a
  different problem, not an apology for Ekorn::Pipeline. Its one
  tweak, made: "A placeholder prefixed with `...`". It advised
  stopping here and carrying the same principles into the guide.
- **What's left:** the guide (2026-0055) and the reference (2026-0056)
  by the same principles; the link to the guide's Part 2, and the
  README's place, at the swap (2026-0058).
- **After the review,** on 2026-11-26, `xt/examples.t` began checking
  that each example in `docs/next/` imports every function it calls,
  as Iain asked for the guide (2026-0055). The README's examples
  already did.
