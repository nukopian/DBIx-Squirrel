# 2026-0051. Ekorn's names in the index, under Tooling

**Status:** open

**Decisions:** D1 settled: under Tooling. D2 settled: a short entry.
D3 settled: a link to Ekorn's reference where ours has no section.

**Origin:** roadmap, added 2026-11-26

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
