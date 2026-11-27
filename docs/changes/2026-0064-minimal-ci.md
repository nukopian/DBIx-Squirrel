# 2026-0064. CI runs the tests with only the required modules

**Status:** shipped, unreleased

**Decisions:** D1 settled: a `minimal` job, uncached. D2 settled: the
other jobs keep their caches, and the comments say what a restored
cache may hold.

**Origin:** a task from Ekorn-Pipeline's session, 2026-11-26
(Ekorn-Pipeline 40bec0875e4f86e4a2b9c8f6cf1a0f9405e8cc3d, tagged
v0.4.5)

**Started:** 2026-11-26

**Finished:** 2026-11-27

## Background

Ekorn-Pipeline v0.4.5 fixes its tests only: from v0.3.10 to v0.4.4,
its `t/30-csv.t` loaded Text::CSV, which it only recommends, so they
failed on every CPAN Testers smoker that installs only what's
required. Its CI hadn't caught it, as every job installed the
recommended modules. Its task raised two points for our CI.

**Recommended modules.** None of our jobs installs with
`--with-recommends`, and nothing in `t/` loads either of the
cpanfile's recommended modules, Text::Redact::Secrets and Text::CSV;
`xt/examples.t` alone needs Text::CSV. But the Linux test jobs install
Text::CSV by name, for `xt/`, and the old-DBI job installs the develop
modules; Windows installs only what's required, but nothing fails
there if a recommended module turns up, as one might in Strawberry
Perl. So no job checks `t/` the way such a smoker runs it.

**The cache.** Ekorn's task said a job's cache key doesn't cover
cpanm's arguments. Read from actions-setup-perl's source at the pinned
v1.44.5 (eebc5c886de14ebbfcd2493d49a12007d2c30477,
`src/cpan-installer.ts`), it does: `hashFiles` hashes
`install-modules-args` with `cpanfile`, as 2026-0033 found. What lets
one job get another's modules is the restore keys: without a cache of
its exact key, a job restores the newest whose key starts with the
same Perl and cpanfile, then the newest with the same Perl alone, and
installs what it lacks on top. Our 5.36 test job and the coverage job
share a Perl, as do the 5.44 test job and the style job; so after a
`cpanfile` change, a test job may run with the develop modules too.

Run locally on 5.36, with an `@INC` hook hiding Text::CSV and
Text::Redact::Secrets as Perl does a missing module, against
Ekorn-Pipeline's working copy at v0.4.5, `prove -l t` passes.
Ekorn's `dump_to` tells a missing Text::Redact::Secrets from a broken
one by Perl's own message; the hook's first message differed, and
`t/20-stages-taps.t` failed, as it should, for a broken one.

## Decisions

- [x] **D1.** How does CI test as a minimal smoker does? A `minimal`
  job on Perl 5.36, the floor, installing only what's required, with
  the module cache off, failing if any of the cpanfile's recommended
  modules is installed, then running `prove -l t`, as Iain decided on
  2026-11-26, as recommended.
- [x] **D2.** Separate the other jobs' caches? No: for them a few
  modules too many is harmless, and the cache is most of their speed.
  The workflow's opening comment and MAINTAINING.md's "CI's caches"
  say what a restored cache may hold. Settled on 2026-11-26, with D1,
  as Iain decided to fix as recommended.

## The plan

**What:** the `minimal` job; the comments on caching corrected.

**Why:** a user installing DBIx::Squirrel on a machine without the
recommended modules runs `t/` as that job does, and nothing else in CI
does.

**Steps:**

1. `.github/workflows/test.yml`: the `minimal` job, and the opening
   comment on restored caches.
2. `docs/MAINTAINING.md`'s "CI's caches", likewise.
3. This record, its line in the records, and the roadmap's last id.
4. Once MetaCPAN indexes Ekorn-Pipeline v0.4.5, the suite run against
   it, and `TODO.md`'s task removed.

**Done when:** the `minimal` job passes on CI, and would fail
were a recommended module installed; the suite passes against v0.4.5 from
CPAN.

## What happened

- **Outcome:** done. The `minimal` job passes on CI, and its check
  fails when a recommended module is installed. `yath test -L t xt`
  passes on 5.36 and 5.44 against Ekorn-Pipeline v0.4.5 installed from
  CPAN's tarball, which `TODO.md`'s task asked for; the task goes with
  the file.
- **CI rerun on 2026-11-27** passed on every job, but installed
  v0.4.4: cpanmetadb's package lookup had v0.4.5, but its history,
  which cpanm reads for the cpanfile's range, didn't yet, as
  MAINTAINING.md's "CI's caches" warns. So the run against v0.4.5 was
  made locally, from the tarball by its path, rather than waiting.
- The check of recommended modules was run locally both ways: with
  them installed it fails, naming both; hidden, it passes.
- CI passed on every job at b5883208feff5fccb205d13401edb0d8a670b7aa,
  the `minimal` job's first run among them.
- `main` requires the new job's check, `perl 5.36, required modules
  only (ubuntu-24.04)`, set by Iain on 2026-11-26, and MAINTAINING.md's
  list of required checks has it.
- A message to Ekorn-Pipeline, that its cache key does cover cpanm's
  arguments, and the restore keys gave its `minimal` job the coverage
  job's modules: Ekorn-Pipeline
  efce6e6c199be3b05b6b045ea6bdb5f044ab09f7.
