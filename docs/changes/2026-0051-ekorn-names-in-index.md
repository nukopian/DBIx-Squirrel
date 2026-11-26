# 2026-0051. Ekorn's names in the index, under Tooling

**Status:** shipped in v4.1.1

**Decisions:** D1 settled: under Tooling. D2 settled: a short entry.
D3 settled, amended: where Ekorn's index links, where ours has no
section.

**Origin:** roadmap, added 2026-11-26

**Started:** 2026-11-26

**Finished:** 2026-11-26

## Background

DBIx::Squirrel::Tooling exports, on request, 25 names from
Ekorn::Pipeline's modules, besides DBIx::Squirrel's own:

- sources: `from_array`, `from_fh`, `from_file`, `counter`;
- sinks: `count_items`, `keep`, `keep_all`, `keep_first`, `keep_last`,
  `keep_single`, `to_fh`, `to_file`;
- JSON and CSV: `from_json`, `from_jsonl`, `to_json`, `to_jsonl`,
  `from_csv`, `to_csv`;
- words: `pipeline`, `stage`, `source`, `generator`, `yield`,
  `sink_one`, `sink_many`.

The reference's index (roadmap 2026-0039, 2026-0041, 2026-0042) has an
entry for each name DBIx::Squirrel's modules define, but Tooling's
entry names only its tags, and `xt/reference-index.t` expects it to
list no names. So none of the 25 is in the index, and some, such as
`counter`, `generator`, `yield` and `sink_many`, appear in the
reference only in the tag table. The names exported by default, such
as `Stop`, `gather`, `take` and `pluck`, are DBIx::Squirrel's own, and
are in the index already, under their modules. Iain found the index
incomplete without the 25, on 2026-11-26.

## Decisions

- [x] **D1.** Where do the entries go? Under DBIx::Squirrel::Tooling, a
  `####` heading for each of the 25, A to Z as other modules' are, as
  Iain decided on 2026-11-26: a caller imports them from Tooling, so
  that's where they'd look. DBIx::Squirrel's own names that Tooling
  exports again stay under their own modules. A heading for each Ekorn
  module, as Ekorn's index has, was the alternative, but those modules
  aren't DBIx::Squirrel's.
- [x] **D2.** How much does an entry say? Its synopsis, a line or two on
  what it does, "Exported upon request.", and a link, as Iain decided
  on 2026-11-26. Ekorn::Pipeline's reference keeps the detail, and a
  full copy here would drift from it.
- [x] **D3.** Where does an entry link? To the section of this reference
  that shows the name in use, where there is one, as the sinks, JSON
  and CSV have; otherwise to the name's entry in Ekorn::Pipeline's
  reference, as Iain decided on 2026-11-26. `xt/reference-index.t`
  changes to allow that link. Writing a section here for each name
  without one, as 2026-0040 did, was the alternative, at more cost for
  little gain.

  Amended by Iain on 2026-11-26, once work had started: a link to
  Ekorn's reference goes where Ekorn's own index links the name, the
  section that shows it in use, not to its index entry. `stage` and
  `source` have index entries whose headings come second in Ekorn's
  reference, after sections of the same name, as `#stage-1` and
  `#source-1`, and `scripts/manuals` can't make a POD link to a second
  heading of a name. Linking to the sections works for all 13, and
  matches the rule for links within this reference.

## The plan

**What:** under DBIx::Squirrel::Tooling in the reference's index, a
`####` entry for each name Tooling exports that no other module of
DBIx::Squirrel's does, which are the 25 from Ekorn::Pipeline's
modules; and `xt/reference-index.t` checking Tooling's entries as it
checks other modules'.

**Why:** the index looks incomplete without them, and some appear in
the reference only in the tag table (Background).

**Steps:**

1. `docs/REFERENCE.md`, the index: Tooling's opening says its entries
   are the names it exports from Ekorn::Pipeline, and that its own
   modules' names are under them; then an entry for each of the 25,
   A to Z: its synopsis, from Ekorn's index entry, marked
   `<!-- not run -->`; a line or two on what it does, naming the
   Ekorn module it's from; "Exported upon request."; and a link (D3):
   - to [8. Sinks](#8-sinks), for `count_items`, `keep`, `keep_all`,
     `keep_first`, `keep_last`, `keep_single`, `to_fh`, `to_file`,
     `to_json` and `to_jsonl`;
   - to [10. Pipelines](#10-pipelines), for `pipeline`;
   - to "A sink into a table, with the word `sink_one`", for
     `sink_one`;
   - for the other 13, to the name's entry in Ekorn's reference on
     `main`, as
     `https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#from_array`;
     `stage` and `source` are `#stage-1` and `#source-1`, as headings
     of the same name come before them there.
2. `xt/reference-index.t`: Tooling's listed names are exactly those it
   exports that no other DBIx::Squirrel module exports; each says
   "Exported upon request."; it still names each tag. A link may go to
   Ekorn's reference on `main`, as above, and then its anchor must be
   that of the name's entry in Ekorn's index, worked out from the
   installed Ekorn::Pipeline::Manual::Reference's headings, which are
   the Markdown's, with NAME and DESCRIPTION for its title, and SEE
   ALSO, AUTHOR and LICENSE after; skipped if that POD isn't found.
3. `scripts/manuals` run; `xt/manuals.t`, `xt/examples.t`,
   `xt/reference-index.t` and `xt/spelling.t` passing.
4. `Changes`, under Unreleased: the entry, and a precis naming roadmap
   2026-0051; the item leaves `ROADMAP.md` in the same commit.

**Done when:** each of the 25 has an entry, the index test checks
them, and fails if one is missing, unlisted, or links to an anchor
Ekorn's reference lacks; `yath test -L t xt` passes on 5.36 and 5.44;
perlcritic and perltidy are clean.

## What happened

- **Outcome:** done, with D3 amended. Tooling's entry in the index
  has the 25 names, A to Z, each with its synopsis, a line or two
  naming its Ekorn module, "Exported upon request." and a link: ten
  sinks to 8. Sinks, `pipeline` to 10. Pipelines, `sink_one` to "A
  sink into a table, with the word `sink_one`", and the other 13 to
  the sections of Ekorn's reference that its index links them to.
  `xt/reference-index.t` checks that Tooling lists exactly the names
  it exports that no other module of DBIx::Squirrel's does, each upon
  request, and that each link to Ekorn's reference goes where Ekorn's
  index links the name, read from the installed
  Ekorn::Pipeline::Manual::Reference. Broken by hand, it failed for a
  missing entry, a name Tooling doesn't export, and a wrong anchor.
- **Changes from the plan:** the 13 links go to Ekorn's sections, not
  its index entries (D3, amended), so the test reads where Ekorn's
  index links each name, not the entries' own anchors; `scripts/manuals`
  needed no change.
- **What's left:** nothing.
