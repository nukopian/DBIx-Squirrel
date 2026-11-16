# 2026-0033. CI installs only what each job needs, and caches it

**Status:** in progress

**Decisions:** D1 settled: Ekorn reinstalled at the newest in range.
D2 settled: the DBI 1.643 job stays uncached. D3 settled: Windows
stays uncached. D4 settled: a failed install still prints cpanm's
build log.

**Origin:** a TODO task from Ekorn-Pipeline's session, 2026-11-16
(Ekorn-Pipeline ace1c4266093b47fba654ce6708e1cfabf0ac1c0, its roadmap
2026-0047)

**Started:** 2026-11-16

## Background

Each CI job but `secrets` ran `cpanm --notest --installdeps
--with-develop .` from scratch, though the test jobs use only yath and
UUID of the develop modules. Installing was most of every job. Ekorn's
2026-0047 moved its jobs to actions-setup-perl's own install, which
installs into `local/` and caches it, and took its Linux test jobs
from 2.5 to 4 minutes to 12 to 16 seconds.

Read from actions-setup-perl's source at the pinned v1.44.5
(eebc5c886de14ebbfcd2493d49a12007d2c30477, `src/cpan-installer.ts`):
it runs `cpanm --local-lib-contained local --notest` with
`install-modules-args`, `--installdeps .`, then again for the modules
named in `install-modules`, on every run. The cache key is the
`perl -V` digest, a hash of `install-modules-args` with `cpanfile`,
and a hash of `install-modules`. A run that hits the cache doesn't save
it again, so a job keeps the versions it first installed until the key
changes: cpanm skips a module whose installed version satisfies the
`cpanfile`.

## Decisions

- [x] **D1.** How do cached jobs get Ekorn::Pipeline, when the cache
  would keep v0.3.4 after v0.3.5 is out, and CI would stop checking
  the release users get? A step after the install reinstalls it at the
  newest version in the `cpanfile`'s range, read from the `cpanfile`,
  with `cpanm --reinstall 'Ekorn::Pipeline~RANGE'`. Iain, 2026-11-16:
  CI testing the Ekorn users get is why it installs Ekorn from CPAN.
  Tried locally, it upgraded an installed v0.3.3 to v0.3.4, the newest
  in cpanmetadb's history at the time.
- [x] **D2.** The DBI 1.643 job installs that DBI before the rest, so
  DBD::SQLite builds against it; setup-perl installs the `cpanfile`'s
  modules before any later step. Left uncached, Iain, 2026-11-16: it
  takes about 2 minutes beside the others, and caching it by hand
  would mean a cache step of our own to keep.
- [x] **D3.** Windows? Left as it is, uncached, as Ekorn's task
  advised: its jobs use Strawberry Perl with DBD::SQLite among its
  modules, and setup-perl's `--local-lib-contained` ignores those, as
  it did when Ekorn's Windows 5.44 job broke. They take about a
  minute. Settled 2026-11-16.
- [x] **D4.** Our install step printed cpanm's build log when it
  failed, and setup-perl's doesn't. A step after it, run only if it or
  Ekorn's reinstall failed, prints the newest log in
  `~/.cpanm/work`. Settled 2026-11-16.

## The plan

**What:** the `perl` jobs install through setup-perl, naming
Test2::Harness and UUID; `style` and `coverage` install through it
with `--with-develop`; the `perl` and `coverage` jobs then reinstall
Ekorn at the newest in range; a failed install prints its build log.
The DBI 1.643 and Windows jobs are unchanged. The jobs keep their
names, so `main`'s required checks don't change. MAINTAINING.md says
how the caches work and how to delete them.

**Why:** most of each job's time is installing modules that haven't
changed.

**Done when:** CI passes on a run that makes the caches and on one
that uses them, with every job installing the newest Ekorn in range,
and the timings before and after are below.

## What happened

- **Measurements,** each job as GitHub timed it, without the wait for
  a runner. Before: three uncached runs of 43909983275, on
  fd5c2b4bbcf509af801a367b1e1477c8fec7de86, 2026-11-16.

| Job | Before | After |
|---|---|---|
| perl 5.36 to 5.44 (ubuntu-24.04) | 1m 28s to 2m 14s | |
| perl 5.44 (macos-26) | 2m 57s to 3m 14s | |
| style | 1m 43s to 2m 32s | |
| coverage | 1m 52s to 2m 25s | |
| perl 5.36, DBI 1.643 (ubuntu-24.04), uncached | 1m 48s to 2m 13s | |
| windows-2025, uncached | 56s to 1m 32s | |
