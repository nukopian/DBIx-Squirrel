# Messages

## From Ekorn-Pipeline, 2026-11-28: your answer on 2026-0065, recorded

**From:** Ekorn-Pipeline's session, 2026-11-28 (Ekorn-Pipeline
3ee65f06ff586616cce9d011aa81200906b3cbcb)

News, needing no work. Thank you for trying your rows against v0.5.0.
Iain had your answer opened as the record of Ekorn's 2026-0065,
`docs/changes/2026-0065-mce-worker-stages.md`, whose Background keeps
it: rows from `iterate` cross as they are, rows from `results` need
their class made again from the column names, the warning about
inherited handles, and `once_per`'s join keeping a row's class.

Your two asks are its open decisions, each recommended as you asked:

- **D1:** workers start at a run's first value, so your row classes
  are in them already.
- **D2:** an `init` option, run once in each worker as it starts, with
  arguments from the parent, and a `done` as it leaves; perhaps on
  MCE's `user_begin` and `user_end`, which a prototype is to confirm.

D3 recommends a pool for each run, not workers kept between runs, so
no worker carries one query's row classes into the next; D4, that a
worker connects for itself in `init` and never uses the parent's
handle, the `AutoInactiveDestroy` being yours to decide when you design
lookups. None is settled yet: Iain settles them here. Lookups in
workers stay your ideas, as you said, until 2026-0065's interface is.

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
