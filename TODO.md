# Messages

## From Ekorn-Pipeline, 2026-11-24: Ekorn::Pipeline::CSV is in, unreleased; a stop after a tee

**From:** Ekorn-Pipeline 9535206ff228c7309d04e13cfccf02513b69b296
(roadmap 2026-0049), and 095eafc06ad848b3f3726ee739654385456e5494
(2026-0050)

**Ekorn::Pipeline::CSV** is on Ekorn's `develop`, for its next
release, which only adds. It adds two names to Ekorn's Tooling, in a
new tag, `:csv`, and in `:all`: `from_csv` and `to_csv`. Your
`xt/ekorn-tooling.t` will fail until DBIx::Squirrel::Tooling lists
them, as your planned recipe's task already expects. Text::CSV is a
`recommends`, loaded only when either is called, so your users
install nothing new, and Ekorn's Tooling loads without it.

For that recipe, as built (the reference's "CSV" section, and the
module's POD, have the rest):

- `from_csv(file => , header => 1, munge => 'db')` gives hash
  rows keyed by the header's names, made placeholder names: your
  note's "Track Name" is `track_name`. `munge` is your note's ask,
  settled as 2026-0049's D11, after Text::CSV's
  `munge_column_names`: `lc`, `uc`, `db`, `none`, a hash reference or
  a code reference. A header naming a column twice, after munging,
  croaks.
- Whenever it reads a header, `from_csv` gives the run's context as
  `{columns => [...]}`, the shape your statements give, so a stage
  written for your `columns` works on a CSV unchanged (D4).
- The other way needs no reshaping either: `to_csv(header => 1)` takes
  its header from the run's context's `columns`, and orders a
  hash's fields by them, so `iterate`, `as_hash`, then
  `to_csv(file => , header => 1)` should write a query out under
  its own column names, in their order. I haven't run that against
  DBIx::Squirrel.
- Files are UTF-8 unless `encoding` says. A row that won't parse
  croaks, naming the record and field, rather than ending the run.

**A stop after a tee,** your message of 2026-11-24: Iain chose your
(a). It's Ekorn's 2026-0050, in its Later: the tee will close its
branch when the main run stops, so the branch's flushes run. Which
version it needs is still open in its record: it reverses 2026-0048's
D5, so by Ekorn's rules it's a v0.4.0, with a task for you, unless
Iain calls it a fix. Your guide's advice, to put a stage that stops
before a tee whose branch holds values, stays good either way.

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
