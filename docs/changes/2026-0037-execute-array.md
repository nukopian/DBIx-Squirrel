# 2026-0037. execute_array and execute_for_fetch, for every placeholder style

**Status:** open

**Decisions:** D1 settled: a named statement's values in the order its
names first appear. D2 settled: `bind_param_array` takes names. D3
settled: a hash is a row for a named statement. D4 settled: a list
statement croaks, with a message of our own. D5 settled: a minor
release.

**Origin:** roadmap, added 2026-11-18, from trying Ekorn::Pipeline's
`feed` as a bulk loader (2026-0036)

## Background

A feed batching rows into `execute_array` worked with `?`
placeholders, but not with `:name`. Compared with plain DBI on
DBD::SQLite, on 2026-11-18, with two arrays of values:

| Statement | Plain DBI | DBIx::Squirrel |
|---|---|---|
| `?, ?` | 2 rows | 2 rows |
| `$1, $2` | 2 rows | 2 rows |
| `:id, :name` | 2 rows | croaks: `Expected a placeholder of the statement (1)` |
| `:id, :name, :id` | 2 rows, 2 values a row | `2 bind values supplied but 3 expected` |
| `$1, $2, $1` | 2 rows, 2 values a row | the same |

Two causes:

- DBD::SQLite, DBD::Pg and DBD::mysql use the DBI's own
  `execute_array`, which ends in `execute_for_fetch`, calling
  `$sth->execute(@$tuple)`: values by position. Our `execute` takes a
  named statement's values as names and values in pairs, so `(1, 'a')`
  is a value for a placeholder called `1`.
- We send the driver every placeholder style as `?`, a `?` for each
  use, so `NUM_OF_PARAMS` counts uses (3), not placeholders (2), and
  the DBI's `execute_array` refuses the arrays before any row runs.

The DBI's `bind_param_array` refuses names (`Can't use named
placeholder ':id' for non-driver supported bind_param_array`), in
plain DBI too, and DBD::Pg's does the same, only because its fallback
executes by position. Nothing in our tests or docs mentions
`execute_array`, `execute_for_fetch` or `bind_param_array`.

## Decisions

- [x] **D1.** In what order does a row give a named statement's
  values? The order its names first appear, as DBD::SQLite numbers
  them, and as plain DBI on SQLite takes `:id, :name, :id`: two values
  a row. Iain, 2026-11-18, as recommended.
- [x] **D2.** Does `bind_param_array` take a name, `:id` or `id`, for
  a named statement? Yes, beyond plain DBI, whose fallback refuses
  names only because it can't map them, and ours can. Iain,
  2026-11-18, as recommended.
- [x] **D3.** May a row be a hash, from `ArrayTupleFetch` or
  `execute_for_fetch`'s fetch, for a named statement, its keys the
  names? Yes, beyond plain DBI: rows shaped by `as_hash`, or pushed
  into a feed, load without being made arrays. Iain, 2026-11-18.
- [x] **D4.** A statement with a list placeholder (`...`) is prepared
  for its values, so rows of other lengths can't share it: these croak
  for it, with a message of our own, in `croakf` and DIAGNOSTICS.
  Iain, 2026-11-18, as recommended.
- [x] **D5.** What release? Minor, v3.3.0: the cases plain DBI handles
  are fixes, but D2 and D3 are new. Iain, 2026-11-18, as recommended.

## The plan

To be written when work starts. In outline: in `st.pm`, for a
statement whose placeholders we map (numbered, named, or repeated),
`execute_for_fetch` takes each row's values in placeholder order, or
by name from a hash, places each at every use with the map `bind` and
`execute` use, and executes by position, so a driver with its own
`execute_for_fetch` gets positions too; `execute_array` checks the
count against the placeholders, and otherwise follows the DBI's:
arrays given, `bind_param_array`, `ArrayTupleFetch`,
`ArrayTupleStatus`. A statement of plain `?` goes to the DBI as it
does now. Tests on SQLite, and on MySQL and PostgreSQL where set,
compare plain DBI wherever it has an answer.
