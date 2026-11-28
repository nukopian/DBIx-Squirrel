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
