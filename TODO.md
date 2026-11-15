# Planned work

## main's required checks take the two Windows jobs

**Waiting on:** Iain, as it's a GitHub setting.

CI has run on Windows since 2026-11-14, in two jobs, `perl 5.36
(windows-2025)` and `perl 5.42 (windows-2025)`, which passed on
`develop` and at v3.0.2. `main`'s required checks don't list them yet,
so a push to `main` doesn't wait for Windows, which is where v3.0.0's
and v3.0.1's trials failed. On 2026-11-15 they were the ten other jobs
only.

The command is in docs/MAINTAINING.md's "Changing the CI matrix", with
the list already taking both jobs: Iain pastes it, or says Claude may
run it. Done when its last line, which reads the list back, shows
twelve checks, the two Windows jobs among them:

```sh
gh api repos/nukopian/DBIx-Squirrel/branches/main/protection --jq .required_status_checks.contexts
```

## MAINTAINING.md takes what v3.0.2's trials taught

**Waiting on:** nothing.

Three trials went to CPAN before v3.0.2 was released, and its record,
docs/changes/2026-0019-v3-0-0.md, says what each found. Some of what
was done isn't in docs/MAINTAINING.md's "A trial release" and "Making
a release", and should be, so the next release does it without being
told. Ekorn-Pipeline's MAINTAINING.md has most of it already (its
a95fe63 and cfcff54).

- **Minilla's POD spelling test:** `minil dist` runs it, and CI
  doesn't. Say so in the trial's build step, and that a word it
  doesn't know, but that's right, goes in the manuals'
  `<!-- stopwords: ... -->` comment, which scripts/manuals copies, or
  a module's `=for stopwords` line. It caught "bitwise" before
  v3.0.0's build.
- **`minil dist --skip-prepare`** in the trial's build step, as the
  release's step 6 has it, so the tarball is the files as committed.
- **The checks after a build:** the version in the tarball's
  `META.json`, that none of the maintainers' files (CLAUDE.md,
  ROADMAP.md, TODO.md, docs/, scripts/) went in, and that `git status`
  is clean.
- **Setting the version for a first trial:** the trial's step 2 sets
  it only "if it has had a trial", but v3.0.0's trial needed it set
  from v2.1.0.
- **The report commands:** step 5's second command keeps only versions
  starting "v2" or "2", so it missed v3's failures. Keep every report
  that isn't a pass, as Ekorn's does.
- **Testing the tarball over the previous release:** v3.0.0-TRIAL
  failed to install over v2.1.0, which CI and CPAN Testers' fresh
  environments don't see. Before uploading, run its tests in a
  library that has the last release installed, as
  `perl-5.36.3@jdc-lab` had, with `cpanm --test-only` given the
  tarball's path, which tests without installing.
- **Checking CPAN has a trial:** that MetaCPAN lists it as
  `developer`, with the last release still `latest`.

Done when both sections say all of the above, their commands paste
as they stand, as CLAUDE.md asks, and `xt/` passes.
