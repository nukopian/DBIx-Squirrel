# 2026-0044. CSV in and out: a recipe, an export, and the README

**Status:** shipped in v3.5.0

**Decisions:** D1 settled: Text::CSV recommended, and required for
development. D2 settled: the export, the recipe and the README, all
before v3.5.0.

**Origin:** roadmap, added 2026-11-24, from 2026-0036's appraisal, as
Iain asked; Ekorn-Pipeline's message of 2026-11-24 (Ekorn-Pipeline
9535206ff228c7309d04e13cfccf02513b69b296)

**Depends on:** Ekorn-Pipeline 2026-0049, released in v0.3.10

**Started:** 2026-11-24

**Finished:** 2026-11-24

## Background

Ekorn::Pipeline v0.3.10 adds Ekorn::Pipeline::CSV: `from_csv`, a
source of rows read from a file, as hashes keyed by a header's names,
and `to_csv`, a sink writing rows as lines, a header first. Its Tooling
exports both in `:csv`, and so, from the same release, does ours, with
Ekorn v0.3.10 required.

Tried against DBIx::Squirrel on 2026-11-24, with Ekorn-Pipeline
4c069b6e48fd029c267822b9916df1ef2dee7645:

- `iterate` into `to_csv(file => ..., header => 1)` writes the
  statement's column names as the header, from the run's context,
  with rows as arrays, so an export needs no `as_hash`.
- After `as_hash` with columns (2026-0043), the context still names
  every column the statement has, so `header => 1` writes them all,
  and each row an empty field for those left out. Giving the header
  as the names, `header => [qw(name plays)]`, writes just them.
  Changing the context in `as_hash` would change it for the stages
  before it too, from the second row on, so the docs say to name the
  header instead.
- `from_csv(file => ..., header => 1, munge => 'db')`, as the source
  of a pipeline of `batch` and a writer calling `execute_for_fetch` on
  an `INSERT` with `:name` placeholders, loaded a file whose header
  said "Track Name" into a `track_name` column, with no reshaping.

## Decisions

- [x] **D1.** How does DBIx::Squirrel depend on Text::CSV? Recommended
  at runtime, as Ekorn::Pipeline does, since only `from_csv` and
  `to_csv` need it, and required for development, so `xt/examples.t`
  runs the examples; CI's tests on each Perl name it, as they don't
  install the develop requirements. On 2026-11-24: Iain doesn't mind
  adding or recommending it, as CSV and a database are "useful
  bedfellows".
- [x] **D2.** Only the recipe, or more? The recipe, an export in the
  user guide's "Write the results to a file", a sentence in the
  README's pitch, and a note in the reference's `as_hash`, all before
  v3.5.0. On 2026-11-24, Iain: "Let's do it all before a release."

## The plan

**What:** show CSV in and out, as jobs that are tedious with plain DBI
and a few lines here.

**Why:** loading a file into a table, and writing a query out with a
header, are jobs readers do by hand with plain DBI, and neither is a
job SQL can do; they show `execute_for_fetch`'s hash rows (2026-0037)
at their best.

**Steps:**

- `cpanfile`: `recommends 'Text::CSV'`, and `requires 'Text::CSV'` on
  develop; CI's per-Perl job names it beside UUID.
- `docs/HOWTO.md`: in "Write the results to a file", a query written
  out with `to_csv`, and the header to give after `as_hash` with
  columns; a row in "Methods or sinks?"; a recipe, "Load a CSV file
  into a table", after "Load rows as they arrive", with a sentence in
  the feed's section pointing to it.
- `docs/REFERENCE.md`: in `as_hash`'s section, the header to give
  `to_csv` with columns.
- `README.pod`: a sentence, with an example, in "Why use it".
- Run `scripts/manuals`, `minil build`, `xt/examples.t` and
  `xt/manuals.t`; a line in `Changes`.

**Done when:** the examples run under `xt/examples.t`, the manuals and
README are made again, and `Changes` says so.

## What happened

- **Outcome:** as planned. The user guide writes a query to
  `hits.csv` in "Write the results to a file", with a row in "Methods
  or sinks?", and has "Load a CSV file into a table" after the feed's
  section, which points to it; the reference's `as_hash` says which
  header to give `to_csv`; the README's pitch has "Files in and out,
  without the plumbing". Both examples run under `xt/examples.t`, on
  5.36.3 and 5.44.0, against Ekorn-Pipeline
  4c069b6e48fd029c267822b9916df1ef2dee7645 (v0.3.10), with Text::CSV
  2.06 (its pure-Perl backend) installed in each perlbrew library.
- **Changes from the plan:** the recipe drops the rows whose plays are
  0 before writing them, a test on the file's rows, which the database
  hasn't got yet, so a stage is the place for it. The README says JSON
  Lines go in and out much the same way, after trying `from_jsonl` and
  `to_jsonl` the same way.
- **What's left:** nothing.
