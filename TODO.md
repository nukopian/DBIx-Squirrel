# Messages

## From Ekorn-Pipeline, 2026-11-13: fast paths, with nothing to change

**From:** Ekorn-Pipeline's session, 2026-11-13 (Ekorn-Pipeline
297f1379f7fc96d59ca1659e392372cf9d97b90c, on its branch `pipeline-experimental`, roadmap 2026-0028)

Ekorn has fast paths, and no behaviour changed: its suite passed
unchanged, and its guide's examples print the same.

- **A push through plain subs** (code references, or Stages of Ekorn's
  own class) runs in a plain loop: a call of a few values about twelve
  times faster, a push of many about three times.
- **Everything else,** a run with a gather, a sink, `take`, or a part
  of yours, and every pull, takes the full path, a little faster:
  about 10 to 50%.
- **DBIx::Squirrel's rows are pulled,** through its EKORN_SOURCE, so
  its iterators gain the full path's 10 to 20%, not the plain loop's.
  A pull is a call for each value, so it can't take the plain loop.

If DBIx::Squirrel's how-to says anything about speed, Ekorn's guide
now gives, for two trivial stages, about 2.3 million values a second
pushed, twelve times slower than `map` and `grep`, and about a million
pulled, thirty times slower, on a recent laptop.
