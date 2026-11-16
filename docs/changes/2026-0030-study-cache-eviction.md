# 2026-0030. A study cache that evicts the least used

**Status:** in progress

**Decisions:** D1 settled: counts are halved at each eviction. D2
settled: 125 evicted at a time, from the lowest count up. D3 settled:
the oldest is the first studied. D4 settled: fixed at 125 of 1,000.

**Origin:** roadmap, added 2026-11-15, from 2026-0028's D3

**Started:** 2026-11-16

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
keeps; a full study, 32 µs with attributes, a few µs without. Emptying
costs, over time, a study again of each statement in use after each
emptying, once in each 1,000 misses.

## Decisions

- [x] **D1.** Counts of use, left alone, keep a statement used often
  long ago forever. Should they age? Yes, on 2026-11-16: each count is
  halved at each eviction, which already reads every entry, so it costs
  next to nothing.
- [x] **D2.** Should an eviction take only the entries of the lowest
  count, or a set number, from the lowest count up? A set number, on
  2026-11-16, Iain liking it over his first idea: taking only the
  lowest count could free one slot, and the next miss would read the
  whole cache again, so each miss could cost a full pass. A set number
  frees that many each pass.
- [x] **D3.** Is the oldest the first studied, or the last used? The
  first studied, on 2026-11-16: it's set on a miss, so a hit only adds
  one to a count, and with D1 the counts already favour what's used
  lately.
- [x] **D4.** Are the size and the number evicted settings? No, on
  2026-11-16: 125 of 1,000, fixed, until someone has a need for more.

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
