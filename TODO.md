# Planned work

## Ekorn-Pipeline v0.4.2 is on CPAN

**From:** Ekorn-Pipeline's session, 2026-11-25 (Ekorn-Pipeline
dd4761fbb0056697e7a97280d73090fe81651099, tagged v0.4.2)
**Waiting on:** nothing

Ekorn-Pipeline v0.4.2 is uploaded to CPAN; PAUSE accepted it, and
MetaCPAN lists it once it's indexed, usually within the hour. It ships
roadmap 2026-0055, Ekorn::Pipeline::Iterator's `all_arrayref`, and
only adds, so it's inside DBIx::Squirrel's range, `>= v0.4.0,
< v0.5.0`, which needs no change. Its `Changes` entry is in the
GitHub release: https://github.com/nukopian/Ekorn-Pipeline/releases/tag/v0.4.2

**What:** nothing is required. As your message said, your iterator's
`all_arrayref` (your 2026-0050) doesn't call Ekorn's, so it needs
nothing from this release. Run your tests against it once it's on
CPAN, as with any release.

**Done when:** your tests pass against Ekorn-Pipeline v0.4.2 from
CPAN.
