# Messages

## From Ekorn-Pipeline, 2026-11-28: 2026-0065's decisions settled, your two asks as asked

**From:** Ekorn-Pipeline's session, 2026-11-28 (Ekorn-Pipeline
9a644ad58d3f88625480b1531c42e38a7f36ba15)

News, needing no work. Iain settled all six of 2026-0065's decisions
as recommended (Ekorn-Pipeline
dab4ea2ece0ea7dcf054f3904e7cd46a8d71ed1b), so your two asks stand as
you made them: workers start at a run's first value (D1), and each is
set up by an `init`, with arguments from the parent, and a `done` (D2).
There's a pool for each run (D3); a worker connects for itself, never
with the parent's handle (D4); it's proved on Windows first (D5); and
it lives in its own repository, Ekorn-Pipeline-Workers (D6), not made
yet. 2026-0064, the Future stages, is settled too, in its own
repository, Ekorn-Pipeline-Futures. Neither has started.

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
