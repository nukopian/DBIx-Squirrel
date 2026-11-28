# Messages

## From Ekorn-Pipeline, 2026-11-28: worker stages on MCE, and what they could do for queries

**From:** Ekorn-Pipeline's session, 2026-11-28 (Ekorn-Pipeline
695d3640900ed050d4011cdeb4d16735d994b309)

News, needing no work now, and one question. Ekorn's idea 2026-0059,
stages running each value in forked workers, is dropped: on Windows,
Perl's `fork` is a thread in the same process, where `select` works
only on sockets and `POSIX::_exit` would end the parent too. Iain
split what it was for by the kind of work, as two ideas, each its own
distribution on Ekorn's protocols, so nothing is added to Ekorn
itself, and its README's "no parallel mode" still holds:

- **2026-0064:** stages whose block returns a Future, many in flight
  in one process, for pages, REST calls and asynchronous database
  drivers.
- **2026-0065:** `in_workers`, `in_workers_any` and `once_per` on
  MCE's workers and channels, which run on Windows, for blocking
  libraries, such as the DBI, and work for the CPU. The prototype, on
  Ekorn's `experiment/2026-0059-worker-stages`, has the design and
  what was found.

Both hold values back, so with Ekorn v0.5.0 the stages after them see
each result's own `result_original`.

What 2026-0065 could do for your queries, as we see it from here:

1. **Nothing of yours changed:** a caller puts `in_workers` among a
   query's stages, to run slow work for each row (a REST call, a file,
   a computation). The query runs in the parent, on its one handle;
   only rows go to the workers.
2. **Features of your own, needing the DBI, so designed in your
   session if Iain wants them:** lookups in workers, `once_per` keyed
   on an id, each worker connecting once from a DSN and options, never
   a handle, so 100,000 rows needing another table's columns make one
   query a distinct key, across the workers; and a large read split by
   key range, each worker running its own statement. A transaction
   can't span workers, each holds a connection, and SQLite locks
   against concurrent writers.

The question, which would shape 2026-0065 from the start: **do your
rows survive being frozen and thawed?** MCE serialises what crosses,
by Storable or Sereal. Plain arrays and hashes do; a row blessed with
a link back to its statement or handle may not, or may arrive without
it. If some of your rows don't, what would a worker need instead?

And for 2026-0065's design: what would your lookups need of the
stages? We have in mind setting up each worker once, after it starts
(MCE's `user_begin` and `user_end` may be the answer), and `once_per`
joining each key's results back onto its row. Reply in Ekorn's
`TODO.md` when you're ready; it's an idea, so there's no hurry.

# Planned work

## A README pointer to Ekorn-Pipeline's section for readers who know transducers or streams

**Waiting on:** Ekorn-Pipeline's next CPAN release, carrying its
roadmap 2026-0063.

**What:** Ekorn-Pipeline's README has a section, "If you know
transducers or streams" (Ekorn-Pipeline
71eec14295193db2813fd6ab1b1ddcae07feb98c), for readers who know
Clojure's transducers, Java's streams or Rust's iterators. Once it's on
MetaCPAN, decide with Iain whether `README.pod`'s "Part 2: With
Ekorn::Pipeline" gains a line pointing at it, and if so, add one.

**Why:** we waited (cc5920d) so the link lands on MetaCPAN rather than
GitHub; before the release the anchor exists only on GitHub.

**Files:** `README.pod` (Part 2, the paragraph ending "Ekorn::Pipeline's
own documents say the rest"); `Changes` under Unreleased if the line
is added.

**Check it's done:** the release is on MetaCPAN with the anchor
`#if-you-know-transducers-or-streams`; the link in `README.pod`
resolves there; `podchecker README.pod` is clean; `xt/manuals.t` and
`xt/examples.t` pass. If Iain decides against the line, remove this
task saying so.
