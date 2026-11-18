# 2026-0043. as_hash takes the columns to keep

**Status:** shipped, unreleased

**Decisions:** D1 settled: names in any case, keyed as now. D2 settled:
a name the statement hasn't got croaks. D3 settled: names only, not
positions. D4 settled: no prototype. D5 settled: a minor release.

**Origin:** roadmap, added 2026-11-18, Iain's idea

**Started:** 2026-11-18

**Finished:** 2026-11-18

## Background

`as_hash` makes each row a hash, keyed by every column, as
`fetchrow_hashref` keys them. Iain asked for it to take an optional
list of column names, the columns the hash keeps; with none, it keeps
them all, as now. It has an empty prototype, so `as_hash, keep_all`
parses; with it, `as_hash('id', 'name')` is a compile error.

## Decisions

- [x] **D1.** How do names match, and how is the hash keyed? In any
  case, as `pluck`'s do, and keyed as `fetchrow_hashref` keys them,
  following `FetchHashKeyName`: so the hash is a part of the one
  `as_hash` gives without names, which agrees with plain DBI. Iain,
  2026-11-18.
- [x] **D2.** A name the statement hasn't got? Croaks, at the first
  row, with `pluck`'s message, `Expected a column of the row (age)`, so
  a typo, or a query that lost a column, shows at once. Iain,
  2026-11-18.
- [x] **D3.** Positions, as `pluck` takes? No: names only. The hash is
  keyed by name, and a number can be a column's name. Iain, 2026-11-18.
- [x] **D4.** The prototype? None, as for `pluck` (2026-0038, D3): a
  bare `as_hash`, before a comma, in a `|` chain, or in parentheses,
  parses as it does with the empty prototype, tried before work
  started. Follows from 2026-0038; Iain asked for the arguments.
- [x] **D5.** What release? Minor: it only adds.

## The plan

**What:** `as_hash(@names)` keeps the columns named, matched in any
case against the statement's column names, for array rows and row
objects, or against the hash's own keys, for hash rows, found once a
run; keyed as now. A hash row given names is a new hash of those keys;
without names, it's passed on as now. An empty or undefined name
croaks, `Expected a column name`; one the row hasn't got croaks,
`Expected a column of the row (%s)`. Of two columns with the same
name, the hash keeps the last, as `fetchrow_hashref` does.

**Why:** a stage after `as_hash`, or code given its hashes, often
wants a few columns, not every one a `SELECT *` gives.

**Steps:**

1. `lib/DBIx/Squirrel/Stages/Rows.pm`: the stage, its POD and
   DIAGNOSTICS.
2. `t/18-stages-rows.t`: each row shape with names; any case; keyed
   under `FetchHashKeyName`; with none, as now; a hash row's new hash;
   the croaks; bare `as_hash` before a comma; coverage above its
   floors.
3. The reference: the index's entry, "Reshaping rows", and
   DIAGNOSTICS; `scripts/manuals`.
4. `Changes`; the item leaves the roadmap.

**Done when:** the suite, `xt/` included, passes on 5.36.3 and 5.44.0,
and under `prove -l t` on 5.36.3; Perl::Critic and Perl::Tidy are
clean on 5.44.0; coverage is above its floors.

## What happened

- **Outcome:** done as planned. `as_hash(@names)` keeps the columns
  named, from arrays, hashes and row objects alike, found in any case
  and keyed as without names; a hash row given names is made anew, one
  without passed on as before; of two columns of a name, the last, as
  without names. The suite, `xt/` included, passes on 5.36.3 and
  5.44.0, 2,517 assertions, against Ekorn::Pipeline v0.3.7 as installed
  from CPAN, and `prove -l t` on 5.36.3; Perl::Critic and Perl::Tidy
  are clean on 5.44.0; `Stages/Rows.pm` is at 100% for statements and
  branches, and coverage is above every floor.
- **Changes from the plan:** none. The existing tests, which write
  `as_hash` bare in lists of stages, compile and pass without the
  prototype, as D4's trial said.
- **What's left:** nothing.
