# 2026-0028. Measured gains in the handles, for v3.0.3

**Status:** open

**Decisions:** D1 open: how a statement studied with attributes is
studied once. D2 open: whether `study_sql`'s placeholders become an
array, as v3.0.3 is a patch release. D3 open: what replaces emptying
the study cache at 1,000 statements, if anything.

**Origin:** Iain, 2026-11-14, as v3.0.2 went out: "Let's take that
db.pm module and st.pm and see where real gains could be measured and
made for 3.0.3 after 3.0.2 is out." Then a review of `db.pm` by
GitHub Copilot, which he passed on the same day, and asked to have on
the slate for v3.0.3 with what was measured of it.

## Background

### Measured, 2026-11-14

On Perl 5.36.3, DBD::SQLite in memory, a five-column table of one row,
and a statement with five named placeholders; each the best of
several seconds of runs, per call:

| | Time |
|---|---|
| `_study`, cached | 0.9 µs |
| `_study_afresh`, a full study | 32.2 µs |
| `prepare` | 8.8 µs |
| `prepare_cached` | 6.9 µs |
| `iterate(...)->all`, one row, no attributes | 72.9 µs |
| the same, with an attributes hash | 144.0 µs |
| plain DBI: prepare, execute and fetch | 9.0 µs |

- **An `iterate` reading one row costs eight times plain DBI.**
  Studying is about 1 µs of it, and `prepare` costs much as the DBI's,
  so most of the 64 µs over DBI goes on setting up the iterator: its
  run through Ekorn, binding, and the batches. Nothing below touches
  it, and it's where profiling starts.
- **A statement given attributes is studied twice, in full.**
  `_prepare_as` studies the statement, then calls `prepare` or
  `prepare_cached`, which study it again. Without attributes, the
  second is a cache hit; with them, `_study` skips its cache, so both
  are full studies, about 32 µs each, which is the 71 µs between the
  two `iterate` rows above.
- **`_binds`'s sort** costs about 0.7 µs of a 3.9 µs `_binds`, with
  five placeholders, once per new statement text: without it, `_binds`
  was 20% quicker, and 16 to 19% with twenty. With the placeholders in
  an array, `expand_lists`, run at each `execute` of a statement with
  a list placeholder, was 3 to 4% quicker.

### Copilot's review of db.pm, and what was found of it

1. **`_binds` sorts the positions:** true, and under a microsecond a
   statement; the sort keeps each name's positions in order, as hash
   order is random. With an array, it goes (D2).
2. **`_values_taken` builds lists:** true; it runs only for `do` with
   `?` placeholders, through a callback. Small.
3. **The state is copied on a cache hit:** true, and cheap: a cached
   `_study`, copy included, takes 0.9 µs. The copy is deliberate, as
   `prepare_cached` updates a handle's state in place, so as not to
   make the weak reference to its iterator strong.
4. **The cache key is joined:** only for DBD::Pg, from three options.
   Small.
5. **`_uncache` walks the DBI's cache:** true, O(n), but it runs only
   when `prepare_cached` finds its handle part-way through an
   iterator. Copilot's fix relies on the DBI's internal cache keys.
6. **The study cache empties at 1,000 statements:** true. It costs
   only programs with more than a thousand statement texts, mostly
   SQL built with literals, where caching helps little; an LRU adds
   work to every hit (D3).
7. **Statements studied twice:** true, and the costliest found, but
   only with attributes, as above (D1).
8. **Integer-keyed hashes, where arrays would do:** as 1 (D2).
9. **State copied on cache hits:** as 3.

Copilot's own advice was to profile first, and its suspicion was that
the cost lies in the state handled around `_study`, `_for_values` and
`prepare_cached`. The timings put most of it elsewhere: in setting up
the iterator.

## Decisions

- [ ] **D1.** How is a statement given attributes studied once? Pass
  `_prepare_as`'s study on to `prepare` and `prepare_cached`, or cache
  studies with attributes too, keyed by them, or both. Passing it on
  keeps the cache as it is; caching by attributes helps every caller.
- [ ] **D2.** Do `study_sql`'s placeholders become an array, by
  position from 1? It's exported, and its POD says it returns a hash
  reference, so it changes an interface in a patch release, for under
  a microsecond a statement. Or keep the hash for `study_sql`, and use
  an array only inside the handles.
- [ ] **D3.** What replaces emptying the cache at 1,000 statements: an
  LRU, dropping the oldest, or nothing? Measured first against a
  workload with more than 1,000 statement texts.

## The plan

Written when work starts. Its order, as proposed on 2026-11-14:

1. Profile an `iterate` setup with Devel::NYTProf, against the
   gazetteer's tables in SQLite, PostgreSQL and MySQL, for the time
   over plain DBI.
2. Study a statement given attributes once (D1).
3. The cache's eviction, against a workload that reaches it (D3).
4. The smaller gains, Copilot's 1, 2, 4 and 8, only if they measure.

## What happened

Nothing yet.
