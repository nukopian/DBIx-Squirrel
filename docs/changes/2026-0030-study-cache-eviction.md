# 2026-0030. A study cache that evicts the least used

**Status:** shipped in v3.1.0

**Decisions:** D1 settled: a count is halved as the walk passes it
(revised). D2 settled: 125 evicted at a time, the first found unused
(revised). D3 settled: the walk starts from the first studied
(revised). D4 settled: fixed at 125 of 1,000. D5 settled: a hit costs
more than the plan allowed, accepted.

**Origin:** roadmap, added 2026-11-15, from 2026-0028's D3

**Started:** 2026-11-16, in 10a60b9

**Finished:** 2026-11-16

## Background

Each database handle keeps what `_study` found about each statement
given as a string without attributes, in `private_ekorn_studied`, so
it's studied once. So that statements made as a program runs can't
fill memory, the handle keeps no more than 1,000: the 1,001st empties
the cache, in `lib/DBIx/Squirrel/db.pm`'s `_study`. 2026-0028's D3 left
that alone for v3.0.3: emptying costs only programs with more than
1,000 statement texts, mostly SQL built with literals, where caching
helps little, and keeping track of use adds work to every hit.

Iain, 2026-11-16: "I like the bounded cache idea, but hate that we
nuke the entire cache." He asked for an LRU evicting the oldest of the
least used, a number at a time.

A hit costs about 0.9 µs, most of it copying what the statement handle
keeps; a full study, 32 µs with attributes, as 2026-0028 measured it,
and about 17 µs without, for the short statements measured below
(corrected in the wash-up of 2026-11-16, where it said a few µs).
Emptying costs, over time, a study again of each statement in use after
each emptying, once in each 1,000 misses.

## Decisions

- [x] **D1.** Counts of use, left alone, keep a statement used often
  long ago forever. Should they age? Yes, on 2026-11-16: each count is
  halved at each eviction, which already reads every entry, so it costs
  next to nothing.
  **Revised 2026-11-16,** with D2 and D3, as the full pass measured
  slower than emptying (see What happened): a count is halved as the
  queue's walk passes it, not every count at each eviction.
- [x] **D2.** Should an eviction take only the entries of the lowest
  count, or a set number, from the lowest count up? A set number, on
  2026-11-16, Iain liking it over his first idea: taking only the
  lowest count could free one slot, and the next miss would read the
  whole cache again, so each miss could cost a full pass. A set number
  frees that many each pass.
  **Revised 2026-11-16:** 125 a time still, but the first 125 the
  walk finds unused since it last passed them, from the front of the
  queue, not strictly the lowest counts of all.
- [x] **D3.** Is the oldest the first studied, or the last used? The
  first studied, on 2026-11-16: it's set on a miss, so a hit only adds
  one to a count, and with D1 the counts already favour what's used
  lately.
  **Revised 2026-11-16:** the queue starts in the order first
  studied, but a study used goes to the back as the walk passes it, so
  the oldest becomes the one longest since the walk last passed it.
- [x] **D4.** Are the size and the number evicted settings? No, on
  2026-11-16: 125 of 1,000, fixed, until someone has a need for more.
- [x] **D5.** A hit costs about 1% more on Perl 5.44 and 3 to 4% more
  on 5.36, over the plan's Done when of about 1%. Ship it anyway? Yes,
  on 2026-11-16: up to 60 ns is lost in a `prepare`'s 7 to 9 µs, and
  under pressure the queue is 1 to 4% faster than emptying.

## The plan

**What:** each cached study keeps a count of its uses, one added on
each hit, and the order it was first studied in. When the cache is
full, a miss evicts 125 entries: those of the lowest counts, and of
the count where the total reaches 125, the first studied (D2, D3).
Every count left is halved (D1).

**Why:** a program with more than 1,000 statement texts keeps the ones
it uses, rather than studying them all again after each emptying.

**Steps:**

1. A prototype in the scratchpad, measured against today's emptying on
   a workload of a few dozen statements used over and over among a
   stream of one-off SQL with literals: the cost of a hit, of a miss
   with its evictions over time, and the studies done again.
2. If it measures as a gain, the change in `_study`, with tests of
   which entries are evicted, and the comment above `_study` and
   `Changes`.
3. If it doesn't, the measurements here, and the item dropped.

**Done when:** a hit costs no more than about 1% more, a program with
fewer than 1,000 statements is otherwise untouched, and the workload
above studies fewer statements again, in less time, than with
emptying; or the measurements show it isn't worth it, and the item is
dropped.

## What happened

- **Outcome:** shipped as a queue, not the full pass the plan set out
  (D1 to D3 revised). Each study keeps a count of its uses, and the
  handle a queue of their keys, in the order first studied. When the
  cache is full, a miss walks the queue from the front: a study unused
  since the walk last passed it is evicted, and one used has its count
  halved, and goes to the back, until 125 are gone. Under pressure it's
  faster than emptying, and keeps the statements in use; a hit costs
  more than the Done when allowed, which Iain accepted (D5). Tests in
  `t/09-db.t` say which go, and in what order the rest are kept.
- **How it was measured:** `_study` called directly, on SQLite in
  memory, so the DBI's own `prepare` isn't timed; best of three, two
  rounds. "Hits only": 100 statements, studied, then 200,000 hits.
  The others: 200,000 calls, seeded, each one of 50 statements used
  again and again, at the share given, or else a new statement with a
  literal in it. ns a call, and studies done at 50%:

  | | Emptying | Full pass | Queue | Slots, MD5 | Slots, `hash_value` | Ring |
  |---|---|---|---|---|---|---|
  | hits only, 5.36 | 1,171 to 1,218 | 1,216 to 1,230 | 1,203 to 1,241 | 1,222 to 1,234 | | 1,217 to 1,240 |
  | 50%, 5.36 | 9,597 to 9,824 | 10,734 to 10,746 | 9,259 to 9,422 | 10,042 to 10,059 | 9,901 to 9,904 | 9,490 to 9,564 |
  | 90%, 5.36 | 2,986 to 3,036 | 3,213 to 3,243 | 2,925 to 2,979 | 3,092 to 3,099 | 3,066 to 3,069 | 2,990 to 3,010 |
  | 99%, 5.36 | 1,423 to 1,468 | 1,466 to 1,477 | 1,447 to 1,478 | 1,480 to 1,483 | 1,466 to 1,471 | 1,466 to 1,471 |
  | hits only, 5.44 | 1,061 to 1,093 | | 1,081 to 1,099 | | | 1,086 to 1,096 |
  | 50%, 5.44 | 9,227 to 9,248 | | 8,831 to 8,869 | | | 8,933 to 8,945 |
  | 90%, 5.44 | 2,771 to 2,800 | | 2,720 to 2,752 | | | 2,756 to 2,757 |
  | studies at 50% | 104,891 | 99,785 | 99,691 | 99,701 | 99,695 to 99,798 | 99,691 |

  Each of the others keeps the 50 statements in use; emptying studies
  each again after each emptying, about 5,100 more studies at 50%.
- **Tried and not kept:**
  - **The full pass, as planned.** An eviction of 125 from 1,000
    entries cost 879 µs, sorting those at the cut-off count by when
    they were first studied, through the hash; 392 µs once it sorted
    plain numbers, against 81 µs to empty the cache. Reading every
    entry three times each eviction cost more than studying the 50
    again, so it was 7 to 11% slower than emptying.
  - **Slots, Iain's idea:** a home slot of 1,000 from the statement's
    hash, the study evicted from it or a neighbour being the one used
    least, the three counts halved; one eviction a miss. It kept the
    statements in use, but each miss cost about 1.1 µs more than the
    queue's in Perl around the hash, so it was slower than emptying.
    It also evicts while the cache has room, when a neighbourhood is
    full, and with `hash_value`, seeded afresh in each process, which
    studies collide changes from run to run.
  - **Hashing a statement to a slot,** 100,000 statements differing
    only in a literal, ns a statement, and how many in a slot, 100 if
    even: `Hash::Util::hash_value` 53 ns, 67 to 132; `crc32` from
    Compress::Zlib 180 ns, 70 to 136; `Digest::MD5::md5` 307 ns, 66 to
    128; `unpack '%32W*'`, a sum of the characters, 60 ns, but 0 to
    5,520, as statements differing in their digits sum alike.
  - **A ring, with a hand,** Iain's idea in place of `shift` and
    `push`: the hand stops at the first study unused since it last
    passed, halving those it passes, and the new study takes its place,
    one a miss, as the CLOCK algorithm does. Its studies were the
    queue's, but it was 1 to 2% slower under pressure, and no cheaper
    on a hit: Perl's `shift` only moves the array's start, in C, where
    the ring's `%` and lookups are Perl's.
- **Does the queue's size matter?** Iain asked, after it shipped.
  `shift` and `push` cost the same at any length: `shift` moves the
  array's start, and a `push` out of room moves the elements back,
  rarely. The queue holds a second copy of each key, about 200 KB a
  handle at 1,000 statements of 200 bytes. The walk is what grows: a
  study with a count of c survives about log2(c) + 1 passes, so when
  nearly every study is in use, one eviction may go round the queue
  many times. One eviction of 125 from 1,000 studies, every one with
  the count given, on Perl 5.36, best of 20:

  | Every study's count | That eviction | The next one |
  |---|---|---|
  | 0 | 26 µs | 26 µs |
  | 1 | 214 µs | 27 µs |
  | 100 | 1,343 µs | 27 µs |
  | 10,000 | 2,526 µs | 26 µs |
  | 1,000,000 | 3,603 µs | 26 µs |

  A count of c takes c hits to build, and about log2(c) + 1 steps to
  bring down, so the walk costs a small share of the hits that made it
  long: the 3.6 ms comes after a billion hits, about 20 minutes of
  them. The eviction after it is back to 26 µs. The longest walk grows
  with the size, so a cache of 10,000 would make it about ten times
  as long; at 1,000, fixed (D4), it doesn't matter. If the size ever
  becomes a setting, its docs should say so.
- **What's left:** nothing.
