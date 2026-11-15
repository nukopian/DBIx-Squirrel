# 2026-0028. Measured gains in the handles, for v3.0.3

**Status:** in progress

**Decisions:** D1 settled: `_prepare_as` passes its study on. D2
settled: an array inside the handles, `study_sql` keeps its hash. D3
settled: nothing in v3.0.3, an LRU is idea 2026-0030. D4 settled: this
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

- [x] **D1.** How is a statement given attributes studied once? Pass
  `_prepare_as`'s study on to `prepare` and `prepare_cached`, or cache
  studies with attributes too, keyed by them, or both. Passing it on
  keeps the cache as it is; caching by attributes helps every caller.
  **Settled 2026-11-15:** pass the study on, as Iain chose. It saves
  the second full study, about 32 µs, needs no change to the cache,
  and no key built from attributes, which can hold code references and
  objects.
- [x] **D2.** Do `study_sql`'s placeholders become an array, by
  position from 1? It's exported, and its POD says it returns a hash
  reference, so it changes an interface in a patch release, for under
  a microsecond a statement. Or keep the hash for `study_sql`, and use
  an array only inside the handles.
  **Settled 2026-11-15:** an array only inside the handles, as Iain
  chose; `study_sql` keeps returning a hash, so v3.0.3 changes no
  interface. Kept only if it measures as a gain (D5).
- [x] **D3.** What replaces emptying the cache at 1,000 statements: an
  LRU, dropping the oldest, or nothing? Measured first against a
  workload with more than 1,000 statement texts.
  **Settled 2026-11-15:** nothing in v3.0.3, as Iain chose. Emptying
  costs only programs with more than 1,000 statement texts, mostly SQL
  built with literals, where caching helps little, and an LRU adds work
  to every hit. Measuring one against such a workload is idea
  2026-0030, so step 3 of the plan leaves this item.
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

Written 2026-11-15, as work starts. Each change is timed before and
after, on Perl 5.36.3 and DBD::SQLite unless it says otherwise, as the
best of several runs, and kept only if it gains beyond the noise
between runs (D5). Each lands as its own commit on `develop`, with the
tests and coverage passing, and Iain reviews the code before it's
committed.

1. **Profile an `iterate`'s setup** with Devel::NYTProf, reading one
   row from SQLite in memory and from the gazetteer, then from
   `bench_places` on PostgreSQL and MySQL, to find where the 64 µs over
   plain DBI goes: in `db.pm` and `st.pm`, in the iterator, or in
   Ekorn::Pipeline. What's Ekorn's goes to its session as a task, with
   the profile and a way to check it (D4).
2. **Study a statement given attributes once** (D1): `_prepare_as`
   passes its study on to `prepare` and `prepare_cached`.
3. **The gains step 1 finds** in DBIx::Squirrel's own code, costliest
   first.
4. **The smaller gains,** Copilot's 1, 2, 4 and 8, the placeholders in
   an array inside the handles only (D2).
5. **v3.0.3,** with what was kept, through docs/MAINTAINING.md's
   release.

The cache's eviction, step 3 of the plan as proposed, isn't in it:
2026-0030 measures it later (D3).

## What happened

### Step 1, profiling, begun 2026-11-15

On Perl 5.36.3, DBD::SQLite in memory, the five-column table of one
row, five named placeholders; Ekorn-Pipeline's working copy at its
v0.3.2 tag (6e86271); the best of five runs, per call:

| | Time |
|---|---|
| DBI `prepare`, `execute`, fetch | 8.0 µs |
| DBI `prepare_cached`, `execute`, fetch | 2.5 µs |
| `iterate($sql, ...)->all` | 77.1 µs |
| the same, with an attributes hash | 148.6 µs |
| a prepared statement's `iterate(...)` alone | 1.9 µs |
| a prepared statement's `iterate(...)->all` | 59.2 µs |
| a prepared statement's `execute`, then `fetchall_arrayref` | 13.0 µs |
| `selectrow_array` | 34.5 µs |

The parts, timed on their own:

| | Time |
|---|---|
| `Ekorn::Pipeline->new->iterator($source)`, no stages, a one-row source | 19.1 µs |
| the same, read with `all` | 21.5 µs |
| Ekorn's `source { ... }` alone | 0.4 µs |
| `execute`, five named values | 12.2 µs |
| `execute`, five positional values | 3.4 µs |
| the DBI's own `execute`, five values | 3.3 µs |
| `Iterator->new` | 1.1 µs |
| `Iterator->new`, then `reset` | 40.9 µs |
| `Iterator->new(...)->all`, positional | 47.9 µs |
| `Iterator->new(...)->all`, named | 59.6 µs |
| `at_caller { 1 }` | 0.67 µs |

- **The setup is cheap; the run isn't.** Making the iterator takes
  2 µs; reading it, about 57 µs more, against 13 µs for the DBI way on
  the same handle.
- **Ekorn's run costs 19 µs before a row is read,** with no stages:
  a third of the whole. NYTProf puts most of it in `_iterator`,
  `_source_run`, `Iterator::DESTROY` and the run's end
  (Pipeline.pm:611 and :812). It's Ekorn's, so it goes to its session
  as a task (D4).
- **Named placeholders cost about 9 µs an `execute`,** over positional
  ones: `Placeholders::values_for`, `key_of` and `st::_in_order`.
  DBIx::Squirrel's own.
- **`reset` costs about 18 µs** beyond Ekorn's run and the `execute`,
  and `Iterator::all` shows a share of its own in the profile; not yet
  broken down.
- **`at_caller` costs 0.7 µs a call,** and an `all` makes two (the
  columns' names, and the fetch).

### Step 1, finished 2026-11-15

**`reset`, broken down,** on a positional statement, per call:

| | Time |
|---|---|
| `Ekorn::Pipeline->new->iterator(_statement(...))`, then `finish` | 33.0 µs |
| of which the source's set-up: `execute`, the columns' names through `at_caller` | 5.8 µs |
| `iterator_going`, `split_stages`, `_finish`, `_slice`, the fresh state, `_statement`, `Ekorn::Pipeline->new` | 0.4 to 1.3 µs each, about 5 µs together |
| `reset`, then `_finish` | 38.9 µs |
| `reset`, then `all` | 45.6 µs |

So `reset`'s own work is about 5 µs, and `all` adds about 7 µs
(`Context::within`, Ekorn's `all`, the fetch). The 18 µs of the first
results was mostly Ekorn's `finish` and the source's set-up.

**Ekorn's run, with no stages,** on Perl 5.36.3 and 5.44.0:

| | 5.36.3 | 5.44.0 |
|---|---|---|
| `iterator($source)` of a `source { ... }`, let go | 17.5 µs | 16.0 µs |
| the same, read with `all` | 20.0 µs | 18.3 µs |
| `iterator($code)` of a code reference, let go | 14.7 µs | 13.3 µs |
| `_source_run`, `_make_run`, `_end_all` of one end | 1.9, 0.3, 0.6 µs | 1.8, 0.3, 0.6 µs |
| a model: 12 closures over 20 lexicals | 4.8 µs | 4.6 µs |

NYTProf's lines put about a third of `_iterator` in making its dozen
closures, `$next` the largest (Pipeline.pm:785) and the iterator's
(:813 to :822), and about as much again in leaving scopes: the
`return`s of `$finish` (:610), `$end_run` (:811), `_end_all` (:423) and
`_make_run` (:503). It's Ekorn's, so it went to its session as a task.

**Lookups by primary key,** 2,000 in a shuffled order, the best of five
runs, in µs a lookup: SQLite on the gazetteer's `places`; PostgreSQL
and MySQL on 2,000 rows of `bench_places`, copied into a temporary
table with a primary key, as `bench_places` has none on PostgreSQL:

| | SQLite | PostgreSQL | MySQL |
|---|---|---|---|
| DBI `prepare_cached`, `execute`, fetch | 5.4 | 36.1 | 25.9 |
| DBI `selectrow_array` | 9.8 | 54.5 | 28.9 |
| Squirrel `selectrow_array` | 20.0 | 65.8 | 40.7 |
| Squirrel, prepared, `execute`, fetch | 7.1 | 41.9 | 27.7 |
| Squirrel, prepared, `iterate($id)->first` | 49.7 | 92.3 | 71.1 |
| the same, named, `iterate(id => $id)->first` | 53.4 | 95.9 | 74.9 |
| Squirrel `iterate($sql, $id)->first` | 62.9 | 114.6 | 82.8 |

- **An iterator's run costs about the same on every driver,** 43 to
  50 µs over `execute` and a fetch on the same handle, so it's a
  third to two thirds of a lookup on a local server, and nine tenths
  on SQLite. A server's round trip narrows the ratio, not the gap.
- **The handles themselves cost little:** a prepared statement's
  `execute` and fetch take 2 to 6 µs over the DBI's.
- **Of the iterator's run,** about 27 µs is Ekorn's, 6 µs the source's
  set-up (`execute` and the columns' names), 5 µs `reset`'s own work,
  and 7 µs `all` or `first`.
- **A named placeholder** costs about 3.6 µs a lookup with one, and
  9 µs an `execute` with five.
