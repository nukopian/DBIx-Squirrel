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

## 1. iterate and results on the database handle

**What.** v1's `lib/DBIx/Squirrel/db.pm` has `iterate` (lines 156-191)
and `results` (199-234), which prepare a statement and hand it to
`$sth->iterate` or `$sth->results`. They wait on the statement handle
having those methods. Bind values followed by stages should be split
with `DBIx::Squirrel::Pipeline->from_args`.

**Ask Iain** which of v1's aliases to keep: `iterator`, `itor` and
`it` for `iterate`; `resultset`, `rset` and `rs` for `results`.

**Files.** `lib/DBIx/Squirrel/db.pm`, `lib/DBIx/Squirrel/st.pm`, v1's
`it.pm` and `rs.pm`.
