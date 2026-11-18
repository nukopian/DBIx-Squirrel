# 2026-0038. pluck with no column gives the only one

**Status:** open

**Decisions:** D1 settled: only when the row has one column, else a
croak. D2 settled: decided from each row, not the statement. D3
settled: a `(;$)` prototype, so it's written bare. D4 settled: a minor
release.

**Origin:** roadmap, added 2026-11-18, Iain's idea

## Background

`pluck($column)` takes a name or a position, and its signature takes
exactly one, so `pluck()` dies in Perl's own argument check. A
one-column `SELECT` made into plain values is written
`sub { $_->[0] }`: 33 times in the how-to and 27 in the reference.
The DBI's `selectcol_arrayref` takes the first column of any query.

## Decisions

- [x] **D1.** With no column, which does `pluck` give? The only one:
  a row of more than one column croaks, as "Expected one column to
  pluck, not 3", rather than giving the first, as
  `selectcol_arrayref` does. The first would go silently wrong when a
  query gains a column, and `pluck(0)` says "the first" already.
  Iain, 2026-11-18.
- [x] **D2.** Counted how? From each row: an array of one element, a
  hash of one key, a row object of one column. So it works without a
  statement, unlike `pluck` by name for an array row, and catches
  `SELECT *` and rows reshaped by an earlier stage, the trap the
  reference warns of for `pluck` by name. A size check a row costs
  next to nothing. Iain, 2026-11-18.
- [x] **D3.** Written bare, as `as_hash` is? Yes, with a `(;$)`
  prototype, so `pluck, keep_all` doesn't take `keep_all` as its
  column. It changes how an odd call parses, such as
  `pluck $x || 'id'`, which the tests check. Iain, 2026-11-18.
- [x] **D4.** What release? Minor: it only adds. Iain, 2026-11-18.

## The plan

To be written when work starts: the stage, in
`lib/DBIx/Squirrel/Stages/Rows.pm`; tests over every row shape and
the prototype's parsing; DIAGNOSTICS and the reference; and the docs'
`sub { $_->[0] }` examples, where `pluck()` reads better.
