# 2026-0001. The reference and the how-to on MetaCPAN

**Status:** in progress

**Decisions:** D1 settled: Markdown stays the source; POD made from it. D2 settled: DBIx::Squirrel::Manual::Reference and ::HowTo.

**Origin:** roadmap, added 2026-11-08, from Iain noticing that
Ekorn-Pipeline's reference and how-to were missing from its
Documentation on MetaCPAN

**Started:** 2026-11-08

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

