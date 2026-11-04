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

## 1. results

**What.** Bring over v1's result set: `lib/DBIx/Squirrel/rs.pm` (136
lines), a subclass of the iterator that reblesses each row into a row
class with accessors made on demand (`_rebless`, `result_class`,
`row_class`, `_autoloaded_accessors_unload`), with `$sth->results`
(v1 `st.pm` line 182) and `$dbh->results` (v1 `db.pm` lines 199-234).

Build it on `DBIx::Squirrel::Iterator`, as decided for the iterator on
2026-11-04 (Claude Doc "DBIx-Squirrel: the iterator, critiqued"): name
it `DBIx::Squirrel::Results`; no aliases (only `results`, a plural
noun); no writes to `$_` outside a stage; the iterator's methods only,
adding none it can do without; options as `ekorn_` attributes, not
class-wide setters.

**Ask Iain** how row classes and their accessors should work, as v1's
AUTOLOAD and per-statement classes are the messy part.

**Files.** `lib/DBIx/Squirrel/db.pm`, `lib/DBIx/Squirrel/st.pm`, a new
`lib/DBIx/Squirrel/Results.pm`, and tests beside `t/14-iterate.t`.
