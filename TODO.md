# Planned work

## A recipe: load a CSV file into a table

**From:** 2026-0036's appraisal, 2026-11-24
**Waiting on:** Ekorn-Pipeline's 2026-0049, Ekorn::Pipeline::CSV,
released to CPAN

Ekorn::Pipeline::CSV gives `from_csv`, whose rows are hashes when a
header names the columns (its D3), and `to_csv` (its D7). From v3.5.0,
`execute_for_fetch` takes a hash row for named placeholders (roadmap
2026-0037), so a CSV file loads into a table with no reshaping:
`from_csv` with a header, `batch`, and `execute_for_fetch` on an
`INSERT` with `:name` placeholders, each batch in a transaction. The
other way, `iterate` and `as_hash` into `to_csv`, writes a query out.
It's the kind of example the docs now lead with, a job that's tedious
with plain DBI. Iain asked for it once the CSV work is ready.

What to do:

- Read Ekorn's 2026-0049 record and reference for `from_csv` and
  `to_csv` as released: their arguments, what a header does, and
  where Text::CSV is needed (its D1 recommends it, not requires it).
- Add a recipe to `docs/HOWTO.md`, beside "Load rows as they arrive",
  loading a small CSV file, written by the example to a temp file,
  into a temp table, and writing a query back out with `to_csv`. Mark
  it `<!-- not run -->` if CI can't have Text::CSV, or check what the
  test needs.
- Add `Ekorn::Pipeline::CSV` to DBIx::Squirrel::Tooling if Ekorn's
  Tooling exports it (`xt/ekorn-tooling.t` fails until it's listed),
  and raise the Ekorn floor in `cpanfile` and the dist's requirements
  to the release that has it, with a `Changes` line.
- Run `scripts/manuals`, `xt/examples.t` and `xt/manuals.t`.

**Done when:** the recipe runs under `xt/examples.t` (or is marked not
run, with the reason), the manuals are made again, `Changes` says so,
and this task is removed in the same commit.
