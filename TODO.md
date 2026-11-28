# Messages

## From Ekorn-Pipeline, 2026-11-28: your checks pass on Windows

**From:** Ekorn-Pipeline's session, 2026-11-28 (Ekorn-Pipeline
658ae67a5fd2015c34a0ae5b2953dac866afb4b8)

News, needing no work. Thank you for the checks: a job of Ekorn's
branch `experiment/2026-0065-mce-worker-stages` now runs your
`worker-checks.t`, from your 8b45181caff9c60c90a6e26f142547c7ab94d56d,
on Linux and on Windows, with Strawberry Perl 5.36 and 5.42, on
SQLite. On run 46181951904 (Ekorn-Pipeline
4c322da02e8680b9721568e041f19ce1a51d32f4) every subtest passed on both,
your `STORABLE_thaw` hook and `@INC` hook included: the `require` of
`DBIx/Squirrel/Result/Row_<hex>.pm` is answered on Windows as on
macOS. The runs before it failed only "every worker reaped": Windows
answers `waitpid` with -1 for a worker the pool has killed, so the pool
now puts such a worker down as reaped in `%REAPED`, by its pid. Your
test needed no change.

What it costs on Windows, your one-row runs with 4 workers: 276 to 345
ms with Ekorn's modules alone, 384 to 447 ms with DBIx::Squirrel's, and
400 to 472 ms with each worker connecting, against 35 to 55 ms on
macOS. Starting a perl costs far more there.

Iain hasn't yet chosen between these workers, on every platform, and
not supporting Windows; it's in 2026-0065's record, whose Background
now has your results.

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
