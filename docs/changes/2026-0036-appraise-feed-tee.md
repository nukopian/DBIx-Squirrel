# 2026-0036. Appraise Ekorn's feed and tee

**Status:** shipped, unreleased

**Decisions:** None.

**Origin:** two messages from Ekorn-Pipeline's session, 2026-11-17,
asking for an appraisal of `$pipeline->feed` (its 2026-0044, at
522fff32146ddabb5d668356c485aa419c2d350f) and `tee` (its 2026-0048, at
8324858d70742206c98be2fe0e2b34eada7c2fae)

**Started:** 2026-11-18, trying `feed` as a loader, which found
2026-0037

**Finished:** 2026-11-24

## Background

Both shipped in Ekorn::Pipeline v0.3.6, on 2026-11-18. `feed` opens a
run its caller pushes values into as they arrive, and `tee` runs each
value through a branch of stages of its own, beside the main run.
DBIx-Squirrel v3.2.0 exports `tee` (2026-0035), and its user guide's
"Load rows as they arrive" uses a feed as a loader, which, written with
`:name` placeholders, found that `execute_array` took only `?`
(2026-0037).

## The plan

**What:** read Ekorn's records and user guide for both, try them
against the DBI's ways of handing over rows, such as callbacks and a
writer batching inserts, and send what's found as a message.

**Why:** Ekorn's session asked for it, and DBIx-Squirrel is where both
meet a database.

**Steps:** read 2026-0044's and 2026-0048's records; try a feed with a
callback, with batches from `fetchall_arrayref`, and with PostgreSQL's
`COPY`; try a tee writing a copy of the rows in batches, with the main
run whole and stopped; try DBIx::Squirrel's own row stages in both;
write a message to Ekorn-Pipeline with the findings.

**Done when:** each trial has a result, anything that bites our users
is in our docs, and the message is sent.

## What happened

- **Outcome:** done. Tried on 2026-11-24, against Ekorn-Pipeline
  f45a7b5f47b6a860dbaf7be579eddd0b0e58fea9 (v0.3.9's code), on SQLite
  and PostgreSQL 18:
  - **A callback:** DBD::SQLite's `sqlite_update_hook` pushing each
    changed row into a feed works; the hook checks `ended` before each
    push, as Ekorn's D5 asks, in one line.
  - **Batches:** rows read with `fetchall_arrayref({}, 2)`, each batch
    pushed into a feed with `take(4)`, stop cleanly: the reading loop
    sees `ended` say `stopped` and finishes the statement.
  - **COPY:** lines from PostgreSQL's `COPY ... TO STDOUT`, read with
    `pg_getcopydata` and pushed into a feed, split and stopped by
    `take(2)` as expected.
  - **A writer:** a feed batching hash records into `execute_for_fetch`
    on a named statement, which 2026-0037 made possible, now in the
    user guide's loader.
  - **Context:** `as_hash` and `pluck` by name inside a tee's branch
    read the statement, as Ekorn's revised D6 meant; `pluck` by name on
    array rows in a feed pushed from outside any run croaks, as our
    docs already say.
  - **A death:** a stage dying in a feed is named, and the feed says
    `died`.
- **Found: a stop after a tee drops what its branch holds.** A tee
  whose branch writes rows in batches, `tee(batch(2), $writer)`, with
  `take(3)` after it, passed 3 rows and wrote none: the branch's end
  was told `stopped`, holding 2. An iterator's `first` did the same.
  The branch's flushes run in the tee's flush, and a stop after the
  tee ends the run before it, by Ekorn's rules for flushes, so nothing
  errors. With `take(3)` before the tee, all 3 were written. The user
  guide and the reference now say to put a stage that stops the run
  before a tee whose branch holds values; whether a tee should close
  its branch when the main run stops is Ekorn's to decide, and the
  message asks.
- **The message:** sent to Ekorn-Pipeline's `TODO.md` after this
  commit, with the findings, and a note for its 2026-0049 (CSV): from
  v3.5.0, `execute_for_fetch` takes a hash row for named placeholders,
  so rows from a header load with no reshaping.
- **What's left:** a user guide recipe loading a CSV file into a
  table, once Ekorn's 2026-0049 is released, is roadmap 2026-0044.
