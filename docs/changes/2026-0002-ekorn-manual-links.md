# 2026-0002. Link to Ekorn::Pipeline's manuals by module name

**Status:** in progress

**Decisions:** D1 settled: on a branch from 2026-0005's. D2 settled:
section names from Ekorn's installed manuals. D3 settled: whole
documents and the repository as module links.

**Origin:** roadmap, added 2026-11-08

**Depends on:** 2026-0005, whose branch this one starts from

**Started:** 2026-11-09, on `experiment/2026-0002-ekorn-manual-links`

## Background

The reference and the how-to link to Ekorn::Pipeline's docs by their
GitHub URLs: 20 links, to its repository, its reference and its
how-to. `scripts/manuals` carries a URL into the POD manuals as it is,
so a reader on MetaCPAN, or in `perldoc`, is sent to GitHub. Since
v0.1.2, Ekorn::Pipeline ships POD manuals of its own,
`Ekorn::Pipeline::Manual::Reference` and `::HowTo`, made the same way
as ours.

## Decisions

- [x] **D1.** Where is the work done? On
  `experiment/2026-0002-ekorn-manual-links`, from
  `experiment/2026-0005-plain-docs`, on 2026-11-09. The links are in
  the reference and the how-to, which that branch has just rewritten.
- [x] **D2.** Where do the section names come from? From Ekorn's
  installed manuals, on 2026-11-09: the script reads their headings
  from `@INC`. A link to a heading Ekorn renames or drops then makes
  the script die, and `xt/manuals.t` fail, where a table in the script
  would go stale without a word.
- [x] **D3.** What of a link to the repository, or to a whole
  document? Module links too, on 2026-11-09: the repository is
  `L<Ekorn::Pipeline>`, and a document its manual's module.

## The plan

**What:** `scripts/manuals` turns each link to Ekorn-Pipeline on
GitHub into a POD link by module name:

- `https://github.com/nukopian/Ekorn-Pipeline` to `L<Ekorn::Pipeline>`;
- `.../blob/main/docs/REFERENCE.md` to
  `L<Ekorn::Pipeline::Manual::Reference>`, and `HOWTO.md` to
  `::HowTo`;
- `...#end-functions` to
  `L<Ekorn::Pipeline::Manual::Reference/"End functions">`, the section
  found from the anchor in the installed manual's headings.

Any other link to Ekorn-Pipeline, or an anchor its manual has no
heading for, makes the script die, naming the link. The Markdown keeps
the URLs, for GitHub.

**Why:** a reader on MetaCPAN, or in `perldoc`, stays there.

**Steps:**

1. Add the conversion to `scripts/manuals`, finding Ekorn's manuals in
   `@INC`.
2. Test it in `xt/manuals.t`: each kind of link, a link to no such
   heading, and that each link to Ekorn's manuals in ours finds its
   section in the installed manual.
3. Make the manuals again, and check them with `podchecker` and the
   tests.

**Done when:** no GitHub URL to Ekorn-Pipeline is left in the POD
manuals, each link to its manuals finds its section, tested, and the
Markdown is unchanged.

## What happened

