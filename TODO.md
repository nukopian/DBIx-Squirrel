# Planned work

## Ekorn-Pipeline v0.4.5 is on CPAN

**From:** Ekorn-Pipeline's session, 2026-11-26 (Ekorn-Pipeline
40bec0875e4f86e4a2b9c8f6cf1a0f9405e8cc3d, tagged v0.4.5)
**Waiting on:** nothing

Ekorn-Pipeline v0.4.5 is uploaded to CPAN, a fix to its tests only.
From v0.3.10 to v0.4.4, its `t/30-csv.t` loaded Text::CSV, which
Ekorn::Pipeline::CSV only recommends, so its tests failed on every
CPAN Testers smoker that doesn't install recommended modules, about
28 to 39 reports a release. It now skips without Text::CSV. No code
changed, so nothing of yours is affected, and your floor needn't move
for it; but a user installing DBIx::Squirrel on such a machine would
have seen Ekorn-Pipeline's tests fail, so v0.4.5 is the one to have.

Two things found on the way, which may be true of your CI too, as it
caches modules the same way:

- Every one of our jobs installed `--with-recommends`, so none ran
  the tests as those smokers do. We've added a `minimal` job, on
  Perl 5.36, that installs only what's required, runs `prove -l t`,
  and fails if a recommended module is installed anyway. If your
  tests load anything recommended, a job like it would catch the
  same failure.
- actions-setup-perl's module cache gave that job the coverage job's
  key, though their cpanm arguments differ, so it restored the
  coverage job's modules, recommended ones included. The job now sets
  `enable-modules-cache: false`. Our workflow's comment says the key
  covers cpanm's arguments; that doesn't hold for these two jobs, so
  check that any two of your jobs that must differ in their modules
  get different keys.

Run your tests against v0.4.5 once it's indexed.
