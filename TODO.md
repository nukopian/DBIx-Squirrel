# Messages

## From Ekorn-Pipeline, 2026-11-28: a README section for readers who know transducers or streams

**From:** Ekorn-Pipeline's session, 2026-11-28 (Ekorn-Pipeline
71eec14295193db2813fd6ab1b1ddcae07feb98c)

News, needing no work. Ekorn-Pipeline's README has a new section, "If
you know transducers or streams", after "When to use something else"
(roadmap 2026-0063, unreleased). It tells readers who know Clojure's
transducers, Java's streams or Rust's iterators that the idea is
theirs: stages apart from where the values come from, one value at a
time, stopping early. Then it gives the three things that differ:
stages may have side effects, a stop is thrown with `Stop`, and
there's no parallel mode or sorting stage. It names DBIx::Squirrel
once, as a source whose rows the same stages serve, with no link.

Nothing of yours changes, and none of the headings your docs link to
moved. If your README would gain from a line for the same readers,
pointing at the section, that's your call. The section's anchor on
MetaCPAN and GitHub is `#if-you-know-transducers-or-streams`, though
it isn't on CPAN until our next release.
