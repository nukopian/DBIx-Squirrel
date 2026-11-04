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

## 1. DBI errors report db.pm's line under RaiseError

**What.** With `RaiseError` on, the DBI's own errors from `prepare`
say "at lib/DBIx/Squirrel/db.pm line 20" (the `SUPER::prepare` call),
not the caller's line. Errors DBIx::Squirrel raises itself already
report the caller's line.

**Files.** `lib/DBIx/Squirrel/db.pm`; the DBI's docs on `RaiseError`,
`HandleError` and `ShowErrorStatement`.

**Done when.** `prepare('SELEC 1')` on a `RaiseError` handle dies
naming the test file and line, with a test, or Iain decides it isn't
worth it.

## 2. iterate and results on the database handle

**What.** v1's `lib/DBIx/Squirrel/db.pm` has `iterate` (lines 156-191)
and `results` (199-234), which prepare a statement and hand it to
`$sth->iterate` or `$sth->results`. They wait on the statement handle
having those methods. Bind values followed by stages should be split
with `DBIx::Squirrel::Pipeline->from_args`.

**Ask Iain** which of v1's aliases to keep: `iterator`, `itor` and
`it` for `iterate`; `resultset`, `rset` and `rs` for `results`.

**Files.** `lib/DBIx/Squirrel/db.pm`, `lib/DBIx/Squirrel/st.pm`, v1's
`it.pm` and `rs.pm`.

## 3. Test against real MySQL and PostgreSQL servers

**What.** The MySQL dialect, `\?`, DBD::Pg's placeholder options, and
DBD::Pg's array references (`_unwrap` in `lib/DBIx/Squirrel/st.pm`)
are tested only with stand-in handles (`t/09-db.t`, "the options a
statement is studied with"; `t/10-st.t`, "an array reference, with
DBD::Pg"). Add tests that connect to a real server
and skip without one, as CLAUDE.md's Tests section describes.
MySQL 8.4 is in `/usr/local/mysql`, and Postgres.app has PostgreSQL.

**Done when.** Each skips cleanly without a server, and passes against
a local one: MySQL's `'it\'s :no'`, PostgreSQL's `data \? 'k'`,
`pg_placeholder_dollaronly` with `$1` used twice, and
`execute([1, 2])` on `SELECT 2 = ANY(?)` binding one PostgreSQL array,
on `SELECT ?, ?` binding two values.

## 4. do replaces the driver's own do

**What.** `DBIx::Squirrel::db::do` prepares and executes, so a
driver's own `do` is never called. DBD::SQLite's runs several
statements at once with `sqlite_allow_multiple_statements`, and that's
lost.

**Decide** whether to document it or to call `SUPER::do` when there are
no placeholders to rewrite. Plain DBI is the baseline (CLAUDE.md).
