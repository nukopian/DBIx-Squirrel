# 2026-0037. execute_array and execute_for_fetch, for every placeholder style

**Status:** shipped, unreleased

**Decisions:** D1 settled: a named statement's values in the order its
names first appear. D2 settled: `bind_param_array` takes names. D3
settled: a hash is a row for a named statement. D4 settled: a list
statement croaks, with a message of our own. D5 settled: a minor
release, now v3.5.0.

**Origin:** roadmap, added 2026-11-18, from trying Ekorn::Pipeline's
`feed` as a bulk loader (2026-0036)

**Started:** 2026-11-24

**Finished:** 2026-11-24

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
  Releases since have taken v3.3.0 to v3.4.2, so it's v3.5.0, still
  minor. Iain, 2026-11-24.

## The plan

**What:** `execute_array`, `execute_for_fetch` and `bind_param_array`
work for every placeholder style we take, as D1 to D4 settle, on a
statement whose placeholders we map (numbered, named, or used more
than once). A statement the DBI gets as written, with plain `?` or
none, or left for DBD::Pg to read, goes to the DBI as now.

**Why:** a feed loading rows through `execute_array` works only with
`?`; plain DBI does more on SQLite, and the DBI's way of loading many
rows at once should work in whatever style the SQL is written.

**Steps:**

1. Probe first, as found on 2026-11-24: the DBI's own
   `execute_for_fetch`, which DBD::SQLite, DBD::Pg and DBD::mysql use,
   calls our `execute` with each row's values by position, and its
   `execute_array` checks the arrays against `NUM_OF_PARAMS`, which
   counts each use of a placeholder.
2. In `st.pm`, `execute_for_fetch` wraps the fetch: each row, an array
   of values in placeholder order (numbers in order, names in the order
   they first appear, D1), or a hash by name for a named statement
   (D3), becomes the values for every position, in order, with the map
   `execute` uses. While it runs, our `execute` passes values by
   position straight on. A driver with its own `execute_for_fetch`
   gets the positions too.
3. `execute_array` follows the DBI's: arrays given, or those bound by
   `bind_param_array`, or `ArrayTupleFetch` (a code reference or an
   active statement handle), and `ArrayTupleStatus`, its counts checked
   against the placeholders, not their uses; then it calls
   `execute_for_fetch`. Context passes through, so a list gives the
   tuples and the rows changed.
4. `bind_param_array` takes a placeholder's number or name, with or
   without its sigil (D2), croaking for one the statement hasn't; with
   attributes, it binds them to every use, as `bind_param` does.
5. A statement with a list placeholder croaks in all three, with a
   message of our own, in `croakf` and DIAGNOSTICS (D4).
6. Tests on SQLite compare plain DBI wherever it has an answer: `?`,
   `$1, $2`, `:id, :name` and repeated placeholders, arrays,
   `bind_param_array`, `ArrayTupleFetch` both ways, `ArrayTupleStatus`,
   errors in a row, and context. MySQL and PostgreSQL where set.
7. Docs: `st.pm`'s POD, the reference, the how-to's "Load rows as they
   arrive" with a named statement, and `Changes`.

**Done when:** the table in Background reads "2 rows" for every
statement on our side, D2 to D4 hold, the tests pass on SQLite (and
MySQL and PostgreSQL where set), coverage stays above its floors, and
the docs say so.

## What happened

- **Outcome:** done, against Done when. The table in Background reads
  "2 rows" for every statement on our side, on DBD::SQLite, and the
  same on PostgreSQL 18 and MySQL. Compared with plain DBI on each,
  2026-11-24:

  | Statement | SQLite: DBI, ours | PostgreSQL: DBI, ours | MySQL: DBI, ours |
  |---|---|---|---|
  | `?, ?` | 2 rows, 2 rows | 2 rows, 2 rows | 2 rows, 2 rows |
  | `$1, $2` | 2 rows, 2 rows | 2 rows, 2 rows | fails, 2 rows |
  | `:id, :name` | 2 rows, 2 rows | fails, 2 rows | fails, 2 rows |
  | `:id, :name, :id` | 2 rows, 2 rows | fails, 2 rows | fails, 2 rows |
  | `$1, $2, $1` | 2 rows, 2 rows | 2 rows, 2 rows | fails, 2 rows |

  Plain DBI fails on DBD::Pg with "Placeholders must begin with ':'
  when using the ":foo" style", and on DBD::mysql with "2 bind values
  supplied but 0 expected". `t/30-execute-array.t` holds the SQLite
  comparisons and D2 to D4; `t/12-mysql.t` and `t/13-pg.t` each have a
  subtest. Coverage stays above its floors, and the condition floor
  rose from 88% to 89% (89.9%), without MySQL or PostgreSQL.
- **The probe held:** the DBI's `execute_for_fetch` calls our
  `execute` with each row's values by position (from `DBI.pm` line
  2010, DBI 1.656). So `execute_for_fetch` sets `InOrder` in the
  handle's state, with `local`, and `execute` passes values straight
  on while it's set.
- **Changes from the plan:**
  - `bind_param_array` keeps its arrays in the handle's state, as
    `ParamArrays`, not in the DBI's `ParamArrays` attribute: the
    driver refuses to have it set from our side of the handle ("Can't
    set ...->{ParamArrays}: unrecognised attribute name"). The DBI's
    own does the same from the driver's side. A `?` statement still
    uses the DBI's, as before; the POD and the reference say so.
  - The DBI's errors are set with `set_err`, naming the method, so
    they read "execute_array failed" as plain DBI's do. An error left
    from an earlier call is cleared first: our methods aren't run
    through the DBI's dispatcher, which clears it at the start of each,
    so `set_err` added to the last message.
  - A row of the wrong shape croaks, with the messages `execute` gives
    (`Expected 2 bind values, not 1`, and the named ones), where plain
    DBI's driver would record an error for that row in the status. Only
    a malformed row does this; a row the database refuses goes in the
    status as with the DBI, tested on a unique key.
  - Plain DBI on SQLite takes `:name, :id` in the order the names first
    appear, as D1 does, so the test gives that statement its arrays in
    that order; a first draft of the test had them the other way.
- **What's left:** 2026-0036, the appraisal of Ekorn's `feed` and
  `tee`, follows: the how-to's loader now writes hashes with
  `execute_for_fetch`, which is the trial it was waiting on.
