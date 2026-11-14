# Planned work

## Ekorn::Pipeline from CPAN again, once v0.3.0 is there

**Waiting on:** Ekorn::Pipeline v0.3.0 on CPAN.

CI installs Ekorn::Pipeline from GitHub's `develop`, in a step named
"Ekorn::Pipeline from GitHub" before each job's dependencies in
`.github/workflows/test.yml`, as this code needs v0.3.0, which isn't
released. Ekorn's `develop` still says v0.2.0, inside the `cpanfile`'s
range, so `--installdeps` keeps it.

Once v0.3.0 is on CPAN, in one commit: remove the four steps and the
comment above the first; change the `cpanfile` to
`requires 'Ekorn::Pipeline', '>= v0.3.0, < v0.4.0';`; regenerate
`META.json` and `Build.PL` with `minil build`; and add the new range to
`Changes`. Done when CI passes on `develop` with Ekorn from CPAN, and
its log shows Ekorn-Pipeline v0.3.0 installed by the dependencies step.

## Expose Ekorn::Pipeline::JSON: from_json, from_jsonl, to_json and to_jsonl

**From:** Ekorn-Pipeline's session, 2026-11-14 (Ekorn-Pipeline
94c5db287ae9fd016dbcff3ff99c4cf370c49618), revised from the task of
Ekorn-Pipeline aadbc05c3e1f8ffd588351de157d5ed0a2344f5e
**Waiting on:** nothing: it's on Ekorn's `develop`, which CI installs

Ekorn-Pipeline has a new module, Ekorn::Pipeline::JSON (its roadmap
2026-0034), shipping in v0.3.0, and Iain wants DBIx::Squirrel to expose
it too. Revised the same day: there are now four functions, a pair for
each format, where the first version had two with a `type` option.

It exports, on request:

- `from_json` and `to_json`: one JSON document. `from_json` gives an
  array's elements, or the document itself, and croaks at a second
  document, pointing to `from_jsonl`; `to_json` writes every value as
  one array.
- `from_jsonl` and `to_jsonl`: JSON Lines, a document a line, arrays
  kept whole; `from_jsonl` reads a block at a time, as values are
  pulled.

Each is a source or a sink given `file` or `fh`, and a stage given
neither, passing on what a file would hold. The options are `file`,
`fh` and `json` (options for JSON::MaybeXS, or an encoder object);
there's no `type`. Ekorn's Tooling exports all four by a `:json` tag,
in its `:all`. It adds a runtime dependency to Ekorn: JSON::MaybeXS.

What to do:

- `lib/DBIx/Squirrel/Tooling.pm`: a `:json` tag, `from_json`,
  `from_jsonl`, `to_json` and `to_jsonl`, imported from
  Ekorn::Pipeline::Tooling's `:json` (or Ekorn::Pipeline::JSON), and
  `json` in the list `:all` is made from; its POD's tags, and
  `t/28-tooling.t`'s list of tags and modules.
- The reference's Importing section (`lib/DBIx/Squirrel/Manual/Reference.pod`
  is made from `docs/`, as here), with a line for `:json`, and anywhere
  else it lists Ekorn's tags or the names it documents.
- Ekorn's CLAUDE.md lists the names DBIx::Squirrel imports by name;
  tell Ekorn's session, by a message, once the four are among them, so
  its list can follow.
- JSON.pm exports a `from_json` and a `to_json` of its own by default,
  so `:all` beside `use JSON` overrides one or the other; Ekorn's docs
  say so, and DBIx::Squirrel's might too.

Ekorn's reference has a section, "JSON: Ekorn::Pipeline::JSON", and its
how-to reads and writes JSON in chapters 5 and 6, and walks through how
a module like it is built in chapter 10. Done when
DBIx::Squirrel::Tooling exports all four by `:json` and `:all`, the
tests pass with Ekorn's `develop`, and the reference says so.
