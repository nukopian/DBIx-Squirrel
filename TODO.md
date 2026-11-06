# Planned work

## A second trial of 2.0.0, its review, then the release

**When:** now that gather is on `develop`, once CI has passed on it.
Then read the reports from a few days after the upload, or sooner at a
failing report.

**What:** v2.0.0 went to CPAN as a trial on 2026-11-05,
`DBIx-Squirrel-v2.0.0-TRIAL.tar.gz`, built from
`cb9556c9493fb7f7729d33c7cefeb3ce060e61fc`. By 2026-11-06 it had drawn
35 reports, all passes, on 13 platforms, including Windows and four
BSDs, and Perls from 5.36.3 to 5.44.0. Then gather, which changes how a
pipeline runs, and a fix to Context's prototypes, went onto `develop`,
so that trial no longer tests what 2.0.0 would be. Upload a second
trial, built from `develop`, read its reports, and decide with Iain
whether 2.0.0 is ready to release. CPAN doesn't index a trial, so
`cpanm DBIx::Squirrel` still installs 1.6.5.

First, decide the second trial's name. PAUSE won't take a file name it
has had before, so it can't be `DBIx-Squirrel-v2.0.0-TRIAL.tar.gz`
again. Either a version of its own, which then moves the release's
version on too, or another name for a trial of v2.0.0; check how PAUSE
treats it before uploading, and update "A trial release" in
docs/MAINTAINING.md, which assumes one trial for each version.

**Why:** CI runs on Linux and macOS only. A trial is tested on
platforms it doesn't cover, such as Windows and the BSDs, and against
other versions of DBI and DBD::SQLite, before 2.0.0 replaces 1.6.5 for
everyone. 1.6.5 drew 266 reports: 262 passes, 1 failure on OpenBSD,
and 3 for Perls it didn't support.

**How:** upload the trial as "A trial release" in docs/MAINTAINING.md
says. Then the reports' counts by version and grade, and each report
that didn't pass, with a link to it:

```
curl -sSf https://api.cpantesters.org/v3/summary/DBIx-Squirrel | jq -r 'group_by(.version)[] | group_by(.grade)[] | "\(.[0].version) \(.[0].grade): \(length)"'
curl -sSf https://api.cpantesters.org/v3/summary/DBIx-Squirrel | jq -r '.[] | select((.version | startswith("v2") or startswith("2")) and .grade != "pass") | "\(.version) \(.grade) \(.osname) perl \(.perl) https://www.cpantesters.org/cpan/report/\(.guid)"'
```

A failure is fixed on `develop`, with a test, and a new trial uploaded.
An `na` from a Perl older than 5.36 is expected, and needs nothing.

**Done when:** Iain has decided. If it's to release, the commit that
removes this file starts release day, as `main` can't take it; the
release then follows "Making a release" in docs/MAINTAINING.md, with
the cut-over between its steps 1 and 2.
