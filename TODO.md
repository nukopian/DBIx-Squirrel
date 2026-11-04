# TODO

Work left over from the session of 2026-11-03, which brought
DBIx-Squirrel-1's `prepare`, `prepare_cached` and `do` over to
DBIx::Squirrel::db, and the placeholder scanner to
DBIx::Squirrel::Placeholders.

**Next session: start here.** As CLAUDE.md's "Planned work" says, ask
Iain whether each task should still be done, do the ones he confirms,
and remove each task in the commit that completes it. Delete this file
with the last one. It must be gone before `main` moves.

The v1 code referred to is in
`/Users/icampbell/Git/github.com/nukopian/DBIx-Squirrel-1`.

## 1. Bind placeholders by number and by name, in DBIx::Squirrel::st

**What.** Give `DBIx::Squirrel::st` its own `bind`, `bind_param` and
`execute`, using what `prepare` keeps in `$sth->{private_ekorn}`:
`Placeholders` (position → placeholder as written, from 1) and
`Options` (what the statement was studied with).

- A numbered placeholder is bound once, wherever it appears: in
  `SELECT $1 + $1`, value 1 goes to both positions (decided this
  session).
- A named placeholder is bound by name, once, to every position using
  it.
- An array reference of bind values works, as v1's did: `do` already
  accepts one (`_shift_attrs` in db.pm), but nothing binds it yet.
- With `pg_placeholder_dollaronly` (in `Options`), the statement still
  holds `$1` placeholders, and DBD::Pg binds them itself, so values
  pass through as they are.

**Why.** Until then, a repeated `$1` needs a value each time, named
placeholders can only be bound by position, and an array reference
of bind values fails.

**Files.** `lib/DBIx/Squirrel/st.pm`; v1's
`lib/DBIx/Squirrel/st.pm` (`bind`, `bind_param`, `execute`,
`_placeholders_map_to_values`) for reference; the POD for `prepare` in
`lib/DBIx/Squirrel/db.pm`, which says "for now" about repeats.

**Done when.** The `todo` test at the end of `t/09-db.t` passes and
loses its `todo`; `$dbh->do('SELECT $1 + $1', undef, 2)` and
`$dbh->selectrow_array('SELECT :a + :a', undef, a => 2)`-style calls
work on SQLite, with tests; the "for now" in the POD is gone.

## 2. Two statements sharing one prepare_cached handle

**What.** `SELECT :a, :b` and `SELECT :b, :a` both become
`SELECT ?, ?`, which is what the DBI's `prepare_cached` caches by, so
they share one statement handle, and the second call overwrites the
first's `Placeholders`. Once binding by name exists (task 1), the
first statement binds the wrong values.

**Idea.** The DBI's cache key includes the attributes, so passing the
original statement in a private attribute (for example
`private_ekorn_statement`) to `SUPER::prepare_cached` would keep them
apart. Check that DBI leaves `private_` attributes alone.

**Files.** `lib/DBIx/Squirrel/db.pm` (`prepare_cached`, `_study`),
`t/09-db.t`.

**Done when.** A test shows the two statements get different handles,
each with its own `Placeholders`.

## 3. DBI errors report db.pm's line under RaiseError

**What.** With `RaiseError` on, the DBI's own errors from `prepare`
say "at lib/DBIx/Squirrel/db.pm line 20" (the `SUPER::prepare` call),
not the caller's line. Errors DBIx::Squirrel raises itself already
report the caller's line.

**Files.** `lib/DBIx/Squirrel/db.pm`; the DBI's docs on `RaiseError`,
`HandleError` and `ShowErrorStatement`.

**Done when.** `prepare('SELEC 1')` on a `RaiseError` handle dies
naming the test file and line, with a test, or Iain decides it isn't
worth it.

## 4. iterate and results on the database handle

**What.** v1's `lib/DBIx/Squirrel/db.pm` has `iterate` (lines 156-191)
and `results` (199-234), which prepare a statement and hand it to
`$sth->iterate` or `$sth->results`. They wait on the statement handle
having those methods. Bind values followed by stages should be split
with `DBIx::Squirrel::Pipeline->from_args`.

**Ask Iain** which of v1's aliases to keep: `iterator`, `itor` and
`it` for `iterate`; `resultset`, `rset` and `rs` for `results`.

**Files.** `lib/DBIx/Squirrel/db.pm`, `lib/DBIx/Squirrel/st.pm`, v1's
`it.pm` and `rs.pm`.

## 5. Test against real MySQL and PostgreSQL servers

**What.** The MySQL dialect, `\?` and DBD::Pg's placeholder options
are tested only with stand-in handles (`t/09-db.t`, "the options a
statement is studied with"). Add tests that connect to a real server
and skip without one, as CLAUDE.md's Tests section describes.
MySQL 8.4 is in `/usr/local/mysql`, and Postgres.app has PostgreSQL.

**Done when.** Each skips cleanly without a server, and passes against
a local one: MySQL's `'it\'s :no'`, PostgreSQL's `data \? 'k'`, and
`pg_placeholder_dollaronly` with `$1` used twice.

## 6. do replaces the driver's own do

**What.** `DBIx::Squirrel::db::do` prepares and executes, so a
driver's own `do` is never called. DBD::SQLite's runs several
statements at once with `sqlite_allow_multiple_statements`, and that's
lost.

**Decide** whether to document it or to call `SUPER::do` when there are
no placeholders to rewrite. Plain DBI is the baseline (CLAUDE.md).
