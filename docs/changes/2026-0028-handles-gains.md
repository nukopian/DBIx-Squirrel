# 2026-0028. Measured gains in the handles, for v3.0.3

**Status:** shipped in v3.0.3

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

### Step 2, a statement given attributes studied once (D1), 2026-11-15

`_prepare_as` hands what it studied to the `prepare` or
`prepare_cached` it calls, in `$DBIx::Squirrel::db::HANDED`, set with
`local` while it calls it, as a subclass's method may stand between
them and can't be passed another argument. `_study` takes it once, and
only for the same handle, statement text and attributes hash: a
subclass changing either has its statement studied afresh. A
statement given as a reference isn't handed on, as code given as the
statement is called each time it's studied.

Before and after, on Perl 5.36.3 and DBD::SQLite in memory, the best
of five runs, Ekorn v0.3.2:

| | Before | After |
|---|---|---|
| `iterate($sql, $attrs, ...)->all`, a quiet machine | 169 to 175 µs | 125 to 127 µs |
| the same, a busy one, three rounds | 284 to 315 µs | 211 to 249 µs |
| `iterate($sql, ...)->all`, no attributes | within the noise | |

It saves more than the one study of 32 µs measured on its own: about
45 µs, quiet. Without attributes, the second study was a cache hit
already, about 1 µs, too little to see.


### Ekorn's run, halved, 2026-11-16

Ekorn-Pipeline took the task from step 1 as its 2026-0040, committed as
its 83c2ac2: a run with no flush, stage's end or sink takes a shorter
way, with 4 closures, not 13, and `$p->iterator($code)` costs about
8 µs, not 15. Checked here against its working copy at 83c2ac2, with
step 2's change: the tests pass on Perl 5.36 and 5.44; against Ekorn
v0.3.2, two rounds, on SQLite in memory:

| | Ekorn v0.3.2 | Ekorn 83c2ac2 |
|---|---|---|
| a prepared statement's `iterate(...)->all` | 61.6, 61.9 µs | 53.8, 54.1 µs |
| `iterate($sql, ...)->all` | 80.0, 80.4 µs | 70.8, 71.6 µs |
| `iterate($sql, ...)->first` | 77.0, 77.7 µs | 69.7, 70.0 µs |
| `iterate($sql, $attrs, ...)->all` | 120.2, 121.6 µs | 110.0, 111.0 µs |

Lookups by key gain 2 to 5 µs: 49.7 to 47.3 µs on SQLite for a
prepared statement's `iterate($id)->first`, within the noise on
PostgreSQL and MySQL. It reaches users with Ekorn v0.3.3. Skipping
Ekorn for an iterator with no stages would now save about 18 µs a run,
not 27.

### Step 3, named placeholders, 2026-11-16

A named `execute` cost about 9 µs over a positional one: `values_for`
ran each name through `key_of`, a substitution and a match, and
looked for missing names with a sort, and `_in_order` built two more
hashes through `place_values` to put the values in order. Now:

- **The order is kept.** `_study_afresh` keeps, as `Order`, the number
  or name of the placeholder at each position, an array inside the
  handles only, as D2 says, for a statement with numbered or named
  placeholders and no list. `_in_order` puts the values in order with
  a slice of it, without `place_values`. A list placeholder's
  statement goes the way it went, as its positions change with its
  lists.
- **`values_for` takes the commonest case first:** as many values as
  placeholders, each named as the statement keys it, are returned as
  given. Otherwise a name the statement keys as given skips `key_of`,
  and as many keys as the statement has are all of them, so the
  search for missing ones is skipped.

Before and after, on Perl 5.36.3, DBD::SQLite in memory, five named
placeholders, Ekorn at 83c2ac2, three rounds, the best of five each:

| | Before | After |
|---|---|---|
| `values_for` | 4.21 to 4.23 µs | 1.87 to 1.92 µs |
| `_in_order` | 7.61 to 7.69 µs | 2.55 to 2.58 µs |
| `execute`, five named values | 12.19 to 12.31 µs | 6.80 to 6.96 µs |
| `execute`, five positional values | 3.44 to 3.59 µs | 3.40 to 3.45 µs |
| `Iterator->new(...)->all`, named | 50.96 to 51.21 µs | 44.83 to 45.67 µs |

Tried and left out: walking the pairs in place, rather than copying
them into a hash first, measured no gain (2.68 µs against 2.64).

### Step 3, values as references, 2026-11-16

Iain asked whether `_in_order`'s copy of `place_values`' pairs into a
hash was the cheapest way, or a reference was quicker. Measured with
stand-ins, a hash returned by reference, rather than as its pairs made
into another hash, saved 0.36 µs with 5 values and 1.9 µs with 20, on
5.36 and 5.44 alike. `values_for` and `place_values` are exported and
documented as returning lists, so, as D2 decided for `study_sql`,
private versions return references: `_values_for` a hash reference,
and `_place_values` an array reference of its pairs, given its values
as a hash reference. The handles use them; the public functions wrap
them. For a list placeholder's statement, `_in_order` puts the pairs
in order in an array, without a hash.

`values_for` as a wrapper with a signature cost 0.45 µs more a call
than before, copying its arguments; without a signature, passing `@_`
on with `&_values_for`, it costs 0.05 to 0.1 µs more.

Before and after, five named placeholders, two rounds:

| | Before | After |
|---|---|---|
| `_in_order` | 2.57 to 2.66 µs | 2.16 to 2.20 µs |
| `execute` | 6.52 to 6.75 µs | 6.05 to 6.22 µs |
| `_in_order`, with a list placeholder | 6.49 to 6.56 µs | 5.96 to 5.98 µs |
| `execute`, with a list placeholder | 10.91 µs | 10.38 to 10.63 µs |
| the public `values_for` | 1.92 to 1.94 µs | 1.99 to 2.03 µs |

### Step 3, `is_numbered` takes one key, 2026-11-16

Iain asked whether `$key !~ m( \A \D \z )xa` was faster than
`is_numbered`'s `m( \A \d+ \z )xa`. It isn't the same test: `\A \D \z`
matches only one non-digit, so a name of two or more characters, such
as `artist_id`, would be taken as numbered. Its correct form, `!~
m( \D )xa`, was about 20 ns quicker on a number and 5 ns slower on a
name, the commoner kind, so the regex stays.

Most of `is_numbered`'s 250 ns was `my($key) = keys %$binds`, making a
list of every key to take one. Taking it with `each`, the iterator
reset with `keys` in void context before and after, cost 203 ns
against 288 with 5 keys, and 208 against 592 with 20, on 5.36; 179
against 252 and 180 against 527 on 5.44. Through `execute`, three
rounds, against the step before:

| | `keys` | `each` |
|---|---|---|
| `execute`, five named values | 6.08 to 6.23 µs | 6.04 to 6.22 µs |
| `execute`, twenty named values | 13.83 to 14.14 µs | 13.41 to 13.64 µs |

Within the noise with five; with twenty, a gain each round, so it's
kept (D5).

### Signatures and copies on the hot paths, 2026-11-16

Iain asked whether other subs on the hot paths had signatures costing
cycles. A signature costs about 20 ns a call; a slurpy `@args` copies
each argument, about 15 ns each, and as much again if they're
returned, while an array reference costs the same whatever it holds.
On Perl 5.36, a call with 11 arguments: 77 ns without a signature,
238 ns with `($self, @args)`, 349 ns returning them, and 114 ns given
a reference. Four places were found worth a change, each its own
commit: `Iterator::_statement`'s `$made`, per batch, which for `all`
without stages is every row left; the chain from `execute` through
`_unwrap`, `_in_order` and `_values_for`, per `execute`; the row
objects' column accessors, per column read; and the `Results` row
maker, per row.

**`$made` takes an array of rows.** It made them in place, rather
than taking and returning a list; `all` without stages gives it the
array fetched, rather than copying every row into another first; and
a whole batch goes to it as fetched, not through `@buffer`. With
nothing left in `@buffer` when `all` reads at once, as there never
is, its `if` went, a branch no test could reach. On the gazetteer's
`place_areas`, 297,848 rows, Ekorn at 83c2ac2, three runs each, per
row:

| | Before | After |
|---|---|---|
| `all`, no stages | 443 to 462 ns | 416 to 425 ns |
| `next`, no stages | 866 to 877 ns | 817 to 833 ns |
| `results->all` | 635 to 648 ns | 596 to 599 ns |
| `all`, one stage | 1681 to 1735 ns | 1701 to 1727 ns |

With a stage, rows go one at a time by `$step`'s first branch, which
this doesn't touch.

**`execute` passes its values on by reference.** `_in_order` and
`_values_for` take them as an array reference, not a list, and
`execute` calls `_unwrap` only for an array reference given alone, as
it acts on nothing else; the public `values_for` passes `\@_` on, with
a `## no critic` for RequireArgUnpacking, as unpacking is the copy it
saves. Each copy grew with the values, so it gained more than the 0.4
µs a call estimated. Three rounds, per call:

| `execute` | Before | After |
|---|---|---|
| five named values | 6.18 to 6.20 µs | 4.71 to 4.80 µs |
| twenty named values | 13.62 to 13.75 µs | 8.48 to 8.58 µs |
| a list placeholder | 10.40 to 10.46 µs | 8.91 to 9.45 µs |
| five positional values | 3.44 to 3.45 µs | 3.00 to 3.08 µs |
| the public `values_for` | 1.90 to 1.93 µs | 1.76 to 1.79 µs |

**Row objects without signatures.** Each column accessor,
`sub ($row) { $row->[$n] }`, became `sub { $_[0][$n] }`, and the
`Results` row maker, `sub ($row) { bless $row, $class }`, became
`sub { bless $_[0], $class }`, each with a comment saying why. An
accessor given an argument by mistake, as `$row->name('x')`, now
ignores it, where the signature died "Too many arguments"; nothing
documented or tested that. On `place_areas`, three rounds, per row:

| | Before | After |
|---|---|---|
| one column read on a row object | 142 to 146 ns | 120 to 122 ns |
| `results->all` | 539 to 551 ns | 512 to 524 ns |

### Step 4, `reset`'s own work, 2026-11-16

`reset` did about 5 µs of work of its own, in half a dozen small
calls. Now it reads the statement handle's `private_ekorn`, a tied
fetch of about 0.3 µs, once, where `iterator_going`, `reset` and
`_slice` each read it; it calls `split_stages` only when given
arguments; it sets the fresh state with a slice, not a hash copied
into one; and it keeps its pipeline, made by a new `_pipeline`, until
it's given other stages, rather than making one for each run, as each
run of a pipeline has its own state, as Ekorn's documentation says.
Tests in `t/14-iterate.t` run a kept pipeline twice: the count starts
again from 1, and a gather's batch is new for each run; they pass
before the change too. `iterator_going`'s finished case lost the call
that covered it, so `t/09-db.t` tests it directly.

Three rounds, Ekorn at 83c2ac2, per call, on SQLite in memory:

| | Before | After |
|---|---|---|
| `reset`, then `_finish`, an iterator run again | 32.5 to 33.0 µs | 29.3 to 29.8 µs |
| `reset`, then `all`, an iterator run again | 38.5 to 39.0 µs | 35.1 to 35.8 µs |
| a new iterator, `new` then `all` | 40.8 to 41.0 µs | 39.3 to 39.8 µs |
| a prepared statement's `iterate(...)->all` | 44.6 to 45.3 µs | 43.2 to 43.7 µs |
| `iterate($sql, ...)->all` | 61.0 to 61.8 µs | 59.1 to 59.8 µs |

### `at_caller`, tried and dropped, 2026-11-16

`at_caller` costs about 0.69 µs a call, most of it making `%SIG`'s
`__WARN__` local, about 280 ns, and `(caller)[1]`, about 160 ns. Tried:
a nested `at_caller` setting neither `$OUTER` nor the handler, as the
outer one's are in place, and the iterator's source executing and
reading the columns' names within one, so `execute`'s own ran nested.
With `local ... if` for both `local`s, the outermost cost about 50 ns
more; with the nested case a path of its own, and the error handling
shared in a `_raise_at`, it cost what it did, and a new iterator
reading one row gained 0.5 to 1.2 µs a round, within the noise
through a whole `iterate`. Iain dropped it: the gain was marginal for
a second `try` in `at_caller`, which is simpler as it is.

### Copilot's smaller points, left, 2026-11-16

Steps 3 and 4 end here. Copilot's remaining points are off the paths
that run for each call or row, and `at_caller`'s change, gaining about
a microsecond a run, was judged marginal, so Iain agreed to leave them
unmeasured:

- **1, `_binds`' sort,** and **8, arrays for integer-keyed hashes:**
  once for each new statement text, about 0.7 µs, as the study cache
  keeps the rest.
- **2, `_values_taken` building lists:** only for `do` with `?`
  placeholders, through a callback.
- **4, the cache key joined:** only for DBD::Pg, from three options.

What's left is step 5, v3.0.3, which waits for Ekorn-Pipeline's
v0.3.3, with its run's shorter way (its 2026-0040).

### The outcome, 2026-11-16

Against Done when: each change was measured before and after, and kept
only where it gained; the one that didn't gain enough, `at_caller`'s,
was dropped. v3.0.3 is still to go to CPAN, after Ekorn-Pipeline's
v0.3.3.

Kept, in order: 67d2755 (D1, a statement given attributes studied
once), 0f92a92 (named values put in order with less work), 6648907
(values as references; `is_numbered` taking one key), 34bd86e (rows
handed on without copying), 58f2606 (`execute` passing its values by
reference), 05d16b5 and d6b0faf (row objects without signatures), and
5cc66ea (`reset` keeping its pipeline). Ekorn-Pipeline's 83c2ac2 (its
2026-0040) halved a run's set-up.

v3.0.2 against `develop` at 7c8fc24, measured together on 2026-11-16,
Perl 5.36.3, two rounds, per call, on SQLite in memory unless it says
otherwise; with Ekorn v0.3.2, as users have it now, and with Ekorn at
83c2ac2, as v0.3.3 will have it:

| | v3.0.2, Ekorn v0.3.2 | now, Ekorn v0.3.2 | now, Ekorn 83c2ac2 |
|---|---|---|---|
| `iterate($sql, $attrs, ...)->all` | 149 µs | 107 to 116 µs | 98 to 104 µs |
| `iterate($sql, ...)->all` | 77 µs | 69 to 70 µs | 59 to 63 µs |
| a prepared statement's `iterate(...)->all` | 59 to 60 µs | 50 to 51 µs | 43 to 45 µs |
| `selectrow_array` | 33 to 34 µs | 31 µs | 30 to 32 µs |
| `execute`, five named values | 11.8 to 12.2 µs | 4.7 to 4.9 µs | |
| `execute`, twenty named values | 33.0 to 33.5 µs | 8.5 to 8.8 µs | |
| `execute`, a list placeholder | 13.2 to 13.3 µs | 9.2 to 9.7 µs | |
| `execute`, five positional values | 3.5 to 3.6 µs | 3.0 to 3.1 µs | |

Reading all 297,848 rows of the gazetteer's `place_areas`, per row,
with Ekorn v0.3.2:

| | v3.0.2 | now |
|---|---|---|
| `all`, no stages | 475 to 476 ns | 435 to 445 ns |
| `next`, no stages | 908 to 922 ns | 872 to 876 ns |
| `results->all` | 670 to 672 ns | 612 to 613 ns |
| a column read on a row object | 148 to 149 ns | 126 to 127 ns |
| `all`, one stage | 1822 to 1840 ns | 1828 to 1831 ns |

Lookups by key gain 2 to 5 µs, on every driver: a prepared statement's
`iterate($id)->first` takes 50.9 µs, not 52.6, on SQLite; 93.5, not
96.0, on PostgreSQL; 73.6, not 75.3, on MySQL. With one value, there's
little to gain in `execute`; most of a lookup is the iterator's run,
and Ekorn's share of it reaches users with its v0.3.3.

Released as v3.0.3 on 2026-11-16, requiring Ekorn::Pipeline v0.3.3 or
later, unattended, as Iain asked before he slept: Ekorn v0.3.3's 63
CPAN Testers reports were 55 passes and 8 na from Perls below 5.36,
with no fails, and CI passed on every commit.

