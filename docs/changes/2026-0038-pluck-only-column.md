# 2026-0038. pluck with no column gives the only one

**Status:** shipped in v3.3.0

**Decisions:** D1 settled: only when the row has one column, else a
croak. D2 settled: decided from each row, not the statement. D3
settled, revised: no prototype, as bare `pluck` parses without one. D4
settled: a minor release. D5 settled: `pluck(undef)` and `pluck('')`
still croak.

**Origin:** roadmap, added 2026-11-18, Iain's idea

**Started:** 2026-11-18

**Finished:** 2026-11-18

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
- [x] **D3.** Written bare, as `as_hash` is? Yes, and with no
  prototype. Iain, 2026-11-18, revised the same day.
  - First settled as a `(;$)` prototype, so `pluck, keep_all` wouldn't
    take `keep_all` as its column. Tried before work started, that
    reason didn't hold: with no prototype, `pluck, keep_all` already
    parses as `pluck(), keep_all`, as a comma can't start an argument.
    What the prototype does instead is give its argument scalar
    context, so `pluck(@cols)` silently plucks the column at position
    `scalar @cols`, and let `pluck 'name', keep_all` work without
    parentheses, which without it dies loudly, "Too many arguments".
    A silent wrong column is what D1 avoids, so: no prototype.
- [x] **D4.** What release? Minor: it only adds. Iain, 2026-11-18.
- [x] **D5.** Do `pluck(undef)` and `pluck('')` mean "the only
  column", as `pluck()` does? No: they still croak, "Expected a
  column, by name or position", as now. Only an empty argument list
  asks for the only column; an undefined or empty variable is more
  likely a mistake, and stays loud. Iain, 2026-11-18.

## The plan

**What:** `pluck` with no arguments gives each row's only column: an
array of one element, a hash of one key, a row object of one column,
counted from the row itself, so it needs no statement. A row of more
than one column croaks, "Expected one column to pluck, not %d". The
signature becomes `(@column)`, so it can tell no column from an
undefined one; more than one argument croaks, as the signature does
now. No prototype.

**Why:** a one-column `SELECT` made into plain values is the commonest
stage in the docs, and `sub { $_->[0] }` says how, not what.

**Steps:**

1. The stage, in `lib/DBIx/Squirrel/Stages/Rows.pm`, without a
   signature on the step, as for `pluck` by column; its POD and
   DIAGNOSTICS.
2. Tests in `t/18-stages-rows.t`: each row shape with one column, and
   with two, which croaks; without a statement, in a pipeline called
   with values; `pluck, keep_all` written bare; `pluck(undef)`,
   `pluck('')` and two columns still croaking; coverage above its
   floors.
3. The reference's Rows table and DIAGNOSTICS, then
   `scripts/manuals`.
4. The examples in the how-to, the reference, the README and the POD
   that take the first column of a one-column `SELECT` with a stage
   doing nothing else become `pluck`. Those showing how a stage is
   written, or reading more than one column, stay.
5. `Changes` under Unreleased; the item leaves the roadmap.

**Done when:** the suite, `xt/` included, passes on 5.36.3 and 5.44.0
against Ekorn's working copy, and under `prove -l t` on 5.36.3;
Perl::Critic and Perl::Tidy are clean on 5.44.0.

## What happened

- **Outcome:** done as planned. The suite, `xt/` included, passes on
  5.36.3 and 5.44.0, 2,306 assertions, against Ekorn's working copy
  at ec074f666af950b9f7f1c46e4d8881b125a8d7cc, and `prove -l t` passes
  on 5.36.3.
  Perl::Critic and Perl::Tidy are clean on 5.44.0, and coverage is
  above every floor: `Stages/Rows.pm` is at 100% for statements and
  branches.
- **Changes from the plan:** the signature isn't `(@column)` but
  `($column = $ONLY)`, a default no caller can give, a reference
  compared by address. So `pluck()` is told from `pluck(undef)`, and
  more than one column still dies in Perl's own check, "Too many
  arguments", with no check of ours. The step is a plain sub, not a
  `gather`, as it keeps nothing between rows.
- **The docs:** 40 examples became `pluck`: 11 in the how-to, 20 in
  the reference, 2 in the README and 7 in the POD (Sugar's, db's,
  Iterator's). Those kept: the multi-column queries, which a
  `pluck()` would croak on; the how-to's first taste of stages, and
  DBIx::Squirrel's SYNOPSIS, which show what a stage is; a `gather`
  step; a pipeline named `first_column`, and Sugar's `first`, which
  are that sub by definition; and the how-to's method in
  `My::Squirrel::db`, a package without `pluck`. The reference's
  select methods example now shows `pluck` working in a pushed run,
  where `pluck` by name for an array row can't.
- **Released** in v3.3.0, 2026-11-18.
- **Corrected, 2026-11-18:** the runs above said "against Ekorn's
  working copy", but `perlbrew exec --with` replaces `PERL5LIB`, so
  they used Ekorn::Pipeline v0.3.6 as installed from CPAN. Its `lib`
  and `cpanfile` are the same as the working copy's at that commit,
  so the results stand. MAINTAINING.md's form, `PERL5LIB` set inside
  `sh -c`, is the one that puts the working copy first.
- **What's left:** nothing.
