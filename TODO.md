# Planned work

## Review the v2.0.1 trial, then release v2.0.1

**When:** from 2026-11-09, or sooner at a failing report, a new release
of DBI or DBD::SQLite, or a new session before then.

**Uploaded:** v2.0.1 went to CPAN as a trial on 2026-11-06,
`DBIx-Squirrel-v2.0.1-TRIAL.tar.gz`, built from
`24709c87b7daf64d79a81f5262a90e3fcd9f022c`, which passed every CI job.
Its own tests passed in the build (`Result: PASS`).

**What:** v2.0.0 went to CPAN as a trial on 2026-11-05,
`DBIx-Squirrel-v2.0.0-TRIAL.tar.gz`, built from
`cb9556c9493fb7f7729d33c7cefeb3ce060e61fc`. By 2026-11-06 it had drawn
35 reports, all passes, on 13 platforms, including Windows and four
BSDs, and Perls from 5.36.3 to 5.44.0. Then gather, which changes how a
pipeline runs, a fix to Context's prototypes, the canned stages in
DBIx::Squirrel::Stages::*, an iterator's column_names, and faster
fetching by all and by every iterator went onto `develop`, so that
trial no longer tests what the release would be. Read the v2.0.1
trial's reports, and decide with Iain whether v2.0.1 is ready to
release. CPAN doesn't index a trial, so
`cpanm DBIx::Squirrel` still installs 1.6.5.

The version moves on, as Iain decided on 2026-11-06, because PAUSE
won't take `DBIx-Squirrel-v2.0.0-TRIAL.tar.gz` twice, and an underscore
version, `v2.0.0_1`, would rank above v2.0.0. So v2.0.0 stays a trial,
and the first 2.x release is v2.0.1.

**Why:** CI runs on Linux and macOS only. A trial is tested on
platforms it doesn't cover, such as Windows and the BSDs, and against
other versions of DBI and DBD::SQLite, before v2.0.1 replaces 1.6.5 for
everyone. 1.6.5 drew 266 reports: 262 passes, 1 failure on OpenBSD,
and 3 for Perls it didn't support.

**How:** the reports' counts by version and grade, then each report
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
