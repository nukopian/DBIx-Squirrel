# 2026-0001. The reference and the how-to on MetaCPAN

**Status:** shipped in v2.0.5

**Decisions:** D1 settled: Markdown stays the source; POD made from it. D2 settled: DBIx::Squirrel::Manual::Reference and ::HowTo.

**Origin:** roadmap, added 2026-11-08, from Iain noticing that
Ekorn-Pipeline's reference and how-to were missing from its
Documentation on MetaCPAN

**Started:** 2026-11-08

**Finished:** 2026-11-08

## Background

MetaCPAN's Documentation section lists a distribution's POD: its
modules, and `.pod` files under `lib/`. DBIx-Squirrel's reference and
how-to are Markdown, in `docs/`, which `minil.toml` leaves out of the
tarball, so CPAN's users see neither; Ekorn-Pipeline v0.1.1's are
missing from MetaCPAN the same way. The module POD links to them on
GitHub instead, by URLs that change when the repository is renamed at
the first release.

## Decisions

- [x] **D1.** Which is the source, Markdown or POD? Markdown, with the
  POD made from it, Iain decided on 2026-11-08 (option B). Writing the
  manuals in POD would suit CPAN best, but the PDF build, `xt/howto.t`,
  which runs the how-to's examples, and the links between sections are
  all built on the Markdown, and POD has no tables, so the reference's
  would be rewritten by hand. Made from the Markdown, there's still one
  source, and GitHub, the PDFs and the tests stay as they are; the cost
  is a converter, for the subset of Markdown the docs use.
- [x] **D2.** What are the manuals called? DBIx::Squirrel::Manual::Reference
  and DBIx::Squirrel::Manual::HowTo, in `lib/DBIx/Squirrel/Manual/`, as
  Moose::Manual and DBIx::Class::Manual name theirs: proposed with D1's
  options on 2026-11-08, and taken with option B.

## The plan

**What:** a script, `scripts/manuals`, that makes
`lib/DBIx/Squirrel/Manual/Reference.pod` from `docs/REFERENCE.md` and
`lib/DBIx/Squirrel/Manual/HowTo.pod` from `docs/HOWTO.md`, both
committed, as the README.md Minilla makes is. It converts what the
docs use: headings to `=head`, the first as NAME; code blocks to
verbatim paragraphs; inline code, bold and links to POD's codes, a
link to a heading becoming a link to its section, in the same manual
or the other; lists to `=over` lists; and each table to a list, its
first column the items. Anything else it meets, it refuses, so a new
construct in the Markdown is noticed, not mangled. `--check` exits
non-zero if the committed POD isn't what the Markdown makes.

**Why:** CPAN's users find v2 on MetaCPAN first, at the release, and
the reference and the how-to should be there with the modules.

**Steps:**

1. `scripts/manuals`, a modulino, so its conversion can be tested.
2. `xt/manuals.t`: each construct converted as expected; the
   committed POD current, as `--check` says; and both manuals clean
   under Pod::Checker, every internal link resolving.
3. The POD and the README link to the manuals by module name, not
   GitHub URLs.
4. docs/MAINTAINING.md and CLAUDE.md say to edit the Markdown and run
   the script, never to edit the POD; `Changes` says what ships.
5. A message to Ekorn-Pipeline, which has the same gap, offering the
   script.

**Done when:** the tarball has both manuals, they pass Pod::Checker,
the check that they're current runs in CI, and the PDFs and the
rendered POD of the changed pages are read.

## What happened

- **Outcome:** against Done when, met. `scripts/manuals` makes
  `lib/DBIx/Squirrel/Manual/Reference.pod` and `HowTo.pod`, which the
  tarball has, from `docs/`; both pass Pod::Checker, with no errors and
  no unresolved links, and `xt/manuals.t`, which CI runs, fails if
  they're not what the Markdown makes, as a stale how-to showed it
  does. Rendered through pod2html, the tables read as lists, each
  column after its name in bold. The README, the main module's POD and
  `Changes` link to the manuals by module name, not GitHub URLs.
- **Changes from the plan:**
  - The Markdown carries its spelling stopwords, as a comment,
    `<!-- stopwords: ... -->`, which the script makes `=for stopwords`:
    Minilla's spelling test, run by `minil dist`, failed on
    "flatMap" and "jsonb's" in the manuals.
  - A second heading of the same name, as the reference's two
    "Pipelines", has `-1` added to its anchor, as GitHub adds it. POD
    names a section by its text, so a link to such a heading is
    refused; none is made. Pod::Checker warns of such repeats, and of
    table rows that share a section's name, as link targets met twice;
    the test passes over that warning alone.
  - `scripts/coverage` adds up `lib/`'s coverage itself. Loading
    `scripts/manuals` into `xt/manuals.t`'s process put it in
    Devel::Cover's report, whose Total counts every file, whatever
    `-select_re` says, which took branch coverage from 97.3% to 92.7%;
    added up from `lib/`'s files, it's 97.3% again, as before.
- **Found by the tests:** escaping `<` as `E<lt>` and then `>` turned
  `E<lt>` into `E<ltE<gt>`; both are escaped in one pass now. The docs
  had no bare `<` in their text, so the manuals weren't affected.
- **Shared with Ekorn-Pipeline, 2026-11-08:** Ekorn-Pipeline took the
  script and its test, and added what its docs needed: quotes, as
  indented paragraphs; italics; links to other files, through a table,
  `%ELSEWHERE`, of where each is instead; and refusing a list in a
  list, which had been folded into the item's text. Taken here as Iain
  asked, from Ekorn-Pipeline
  448171b83782eb5004d814123881319d01569f92, with its tests, so the two
  copies differ only in their settings; the manuals made here are
  unchanged by it. Test::Spellunker joined the `cpanfile`'s develop
  modules, as there, so a fresh library runs Minilla's spelling test
  rather than skipping it.
- **What's left:** the manuals' own Contents sections repeat the
  contents MetaCPAN builds itself; harmless, and left. The message to
  Ekorn-Pipeline, step 5, follows this commit.

