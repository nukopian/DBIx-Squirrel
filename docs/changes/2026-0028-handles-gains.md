# 2026-0028. Measured gains in the handles, for v3.0.3

**Status:** open

**Decisions:** D1 open: how a statement studied with attributes is
studied once. D2 open: whether `study_sql`'s placeholders become an
array, as v3.0.3 is a patch release. D3 open: what replaces emptying
the study cache at 1,000 statements, if anything. D4 settled: this
session leads v3.0.3's optimisation, and Ekorn's changes go to its
session as tasks. D5 settled: small gains count, as they add up, if
each measures as a gain.

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

### Compared with DBI and DBIx::Class, 2026-11-15

On Perl 5.36.3 and the gazetteer's SQLite file, read-only, with
DBIx::Class 0.082844, installed apart from Iain's libraries; each the
best of three runs. Reading every row, in µs a row, and times plain
DBI's `fetchrow_arrayref`:

| | `place_areas`, 297,848 narrow rows | `places`, 104,082 of 1.6 KB |
|---|---|---|
| DBI `fetchrow_arrayref` | 0.24 (1.0×) | 0.50 (1.0×) |
| DBI `fetchrow_hashref` | 1.01 (4.2×) | 1.94 (3.9×) |
| Squirrel `all`, arrays | 0.44 (1.8×) | 0.92 (1.9×) |
| Squirrel `next`, arrays | 0.85 (3.5×) | 1.29 (2.6×) |
| Squirrel `next`, hashes | 1.16 (4.8×) | 1.83 (3.7×) |
| DBIx::Class `cursor->next`, arrays | 0.95 (3.9×) | 1.38 (2.8×) |
| DBIx::Class HashRefInflator | 3.14 (12.9×) | 4.54 (9.1×) |
| DBIx::Class row objects | 4.85 (19.9×) | 6.35 (12.8×) |

2,000 lookups in `places` by primary key, in µs a lookup:

| | Time |
|---|---|
| DBI `selectrow_array`, `prepare_cached` | 6.3 (1.0×) |
| Squirrel `selectrow_array` | 22.0 (3.5×) |
| Squirrel, prepared once, `iterate($id)->first` | 53.0 (8.4×) |
| Squirrel `iterate($sql, $id)->first` | 65.9 (10.4×) |
| DBIx::Class `find($id)->name` | 176.4 (27.9×) |
| DBIx::Class `search(...)->get_column->first` | 191.0 (30.2×) |

- **Reading rows,** DBIx::Squirrel's hashes cost about what the DBI's
  `fetchrow_hashref` does, and it's 3 to 4 times quicker than
  DBIx::Class's hashes and row objects.
- **Looking one row up,** it's 3 to 8 times quicker than DBIx::Class,
  but `iterate(...)->first` takes about 47 µs more than its own
  `selectrow_array`, the setup of an iterator, which the plan's first
  step profiles. Against a server, each lookup also pays a round trip,
  of 50 to 200 µs, which narrows every gap.

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
- [x] **D4.** How is v3.0.3's optimisation driven, as some gains may
  be Ekorn::Pipeline's? From this session, as Iain decided on
  2026-11-15, as the measurements are made here: this record sets the
  order of work for both repositories. Ekorn-Pipeline's session still
  makes Ekorn's changes, sent as tasks in its `TODO.md`, each with the
  measurements and a way to check it, and this session checks them
  against Ekorn's working copy, as the tests do. Iain chose that over
  this session changing Ekorn's code on a branch, which would have
  needed CLAUDE.md's rules on designing in each repository's session,
  and on the sessions talking only through `TODO.md`, changed in both.
- [x] **D5.** Is a change worth making for a small gain? Yes, as Iain
  said on 2026-11-15: "Even if changes result in small gains, they'll
  be cumulative." So the smaller points, Copilot's 1, 2, 4 and 8, are
  candidates like the rest, not left for last. Each is still measured
  before and after, and kept only if it gains beyond the noise between
  runs: a change under a microsecond can as easily cost as save, and
  that adds up too.

## The plan

Written when work starts. Its order, as proposed on 2026-11-14:

1. Profile an `iterate` setup with Devel::NYTProf, against the
   gazetteer's tables in SQLite, PostgreSQL and MySQL, for the time
   over plain DBI.
2. Study a statement given attributes once (D1).
3. The cache's eviction, against a workload that reaches it (D3).
4. The smaller gains, Copilot's 1, 2, 4 and 8, each kept if it
   measures as a gain, however small (D5).

## What happened

Nothing yet.
