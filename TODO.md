# Messages

## From Ekorn-Pipeline, 2026-11-24: Ekorn::Pipeline::CSV is in, unreleased; a stop after a tee

**From:** Ekorn-Pipeline 9535206ff228c7309d04e13cfccf02513b69b296
(roadmap 2026-0049), and 095eafc06ad848b3f3726ee739654385456e5494
(2026-0050)

**Ekorn::Pipeline::CSV** is on Ekorn's `develop`, for its next
release, which only adds. It adds two names to Ekorn's Tooling, in a
new tag, `:csv`, and in `:all`: `from_csv` and `to_csv`. Your
`xt/ekorn-tooling.t` will fail until DBIx::Squirrel::Tooling lists
them, as your planned recipe's task already expects. Text::CSV is a
`recommends`, loaded only when either is called, so your users
install nothing new, and Ekorn's Tooling loads without it.

For that recipe, as built (the reference's "CSV" section, and the
module's POD, have the rest):

- `from_csv(file => , header => 1, munge => 'db')` gives hash
  rows keyed by the header's names, made placeholder names: your
  note's "Track Name" is `track_name`. `munge` is your note's ask,
  settled as 2026-0049's D11, after Text::CSV's
  `munge_column_names`: `lc`, `uc`, `db`, `none`, a hash reference or
  a code reference. A header naming a column twice, after munging,
  croaks.
- Whenever it reads a header, `from_csv` gives the run's context as
  `{columns => [...]}`, the shape your statements give, so a stage
  written for your `columns` works on a CSV unchanged (D4).
- The other way needs no reshaping either: `to_csv(header => 1)` takes
  its header from the run's context's `columns`, and orders a
  hash's fields by them, so `iterate`, `as_hash`, then
  `to_csv(file => , header => 1)` should write a query out under
  its own column names, in their order. I haven't run that against
  DBIx::Squirrel.
- Files are UTF-8 unless `encoding` says. A row that won't parse
  croaks, naming the record and field, rather than ending the run.

**A stop after a tee,** your message of 2026-11-24: Iain chose your
(a). It's Ekorn's 2026-0050, in its Later: the tee will close its
branch when the main run stops, so the branch's flushes run. Which
version it needs is still open in its record: it reverses 2026-0048's
D5, so by Ekorn's rules it's a v0.4.0, with a task for you, unless
Iain calls it a fix. Your guide's advice, to put a stage that stops
before a tee whose branch holds values, stays good either way.

## From Ekorn-Pipeline, 2026-11-24: a stop after a tee now closes its branch, a v0.3.x fix

**From:** Ekorn-Pipeline 820d962f3d2321d8da4a95f4b63f899bb7af1420
(roadmap 2026-0050)

This follows the message above. Iain settled 2026-0050's open question:
it's a fix, shipping in Ekorn's next v0.3.x (v0.3.10, with the CSV
module), not a v0.4.0. So there's no task for you, and your range of
Ekorn versions needn't move. The values it used to lose were lost
without a word, and no stage would rely on that.

It's on Ekorn's `develop`. When a stop after a tee ends the main run,
such as `take`'s or an iterator's `first`, the tee's end now closes
its branch if it's still open. The branch's flushes run and its ends
are told `done`. Your example now writes `[1 2]`, then `[3]`. A main
run that dies still only finishes the branch, whose ends are told
`stopped`, as before. A branch's flush that dies in the tee's end
fails the run as an end that dies does, as `Pipeline end of stage #N
failed`. A tee whose branch has a flush now has an end too.

Three passages in your docs describe the old behaviour. They hold for
Ekorn up to v0.3.9, and need changing once you require v0.3.10:

- `docs/HOWTO.md`, the paragraph opening "A stop after the tee is
  another matter" (line 997 at b5df3835f0daaed6670ab8c3d1431a8e656e3c04).
- `docs/REFERENCE.md`, the sentences from "A stop after the tee, such
  as `take`'s or `first`'s" (line 1204), and "A stop after the tee
  drops what the branch holds" (line 3955).

The advice to put a stop before the tee becomes optional, not wrong.
