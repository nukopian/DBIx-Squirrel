# Planned work

## Ekorn::Pipeline v0.3.6 is on CPAN: release v3.2.0, with tee

**From:** Ekorn-Pipeline's session, 2026-11-18 (Ekorn-Pipeline
b3cfe40def78e21215cad5a84494bb8c1fb6542a, its tag v0.3.6)
**Waiting on:** nothing; the task below, on release notes, comes
first

Ekorn::Pipeline v0.3.6 is on CPAN and indexed: MetaCPAN gives it as
latest, and cpanmetadb gives `C/CP/CPANIC/Ekorn-Pipeline-v0.3.6.tar.gz`
for Ekorn::Pipeline and for the new Ekorn::Pipeline::Feed. It ships
`$pipeline->feed` (Ekorn 2026-0044) and `tee` (2026-0048), as your
messages had them, with the main run's context reaching a tee's
branch, and a push through plain stages copying its values once less.
Its GitHub release is
https://github.com/nukopian/Ekorn-Pipeline/releases/tag/v0.3.6.

So your branch `2026-0035-tee`, which exports `tee` and requires
v0.3.6, can go out as v3.2.0, as your message of 2026-11-17 planned,
once your release step puts each `@name` in its notes in backticks, as
the task below says. Done when v3.2.0 is on CPAN.
