# Planned work

## Review the v2.0.0 trial, then release 2.0.0

**When:** from 2026-11-08, or sooner at the next significant event: a
failing report, a new release of DBI or DBD::SQLite, or a new session
before then.

**What:** v2.0.0 went to CPAN as a trial on 2026-11-05,
`DBIx-Squirrel-v2.0.0-TRIAL.tar.gz`, built from
`cb9556c9493fb7f7729d33c7cefeb3ce060e61fc`, which passed every CI job.
CPAN doesn't index a trial, so `cpanm DBIx::Squirrel` still installs
1.6.5. Read the CPAN Testers reports it has drawn, and decide with Iain
whether 2.0.0 is ready to release.

**Why:** CI runs on Linux and macOS only. The trial is tested on
platforms it doesn't cover, such as Windows and the BSDs, and against
other versions of DBI and DBD::SQLite, before 2.0.0 replaces 1.6.5 for
everyone. 1.6.5 drew 266 reports: 262 passes, 1 failure on OpenBSD,
and 3 for Perls it didn't support.

**How:** the reports' counts by version and grade, then each report
that didn't pass, with a link to it:

```
curl -sSf https://api.cpantesters.org/v3/summary/DBIx-Squirrel | jq -r 'group_by(.version)[] | group_by(.grade)[] | "\(.[0].version) \(.[0].grade): \(length)"'
curl -sSf https://api.cpantesters.org/v3/summary/DBIx-Squirrel | jq -r '.[] | select((.version | startswith("v2") or startswith("2")) and .grade != "pass") | "\(.version) \(.grade) \(.osname) perl \(.perl) https://www.cpantesters.org/cpan/report/\(.guid)"'
```

A failure is fixed on `develop`, with a test, and a new trial uploaded,
as docs/MAINTAINING.md's "A trial release" says. An `na` from a Perl
older than 5.36 is expected, and needs nothing.

**Done when:** Iain has decided. If it's to release, the commit that
removes this file starts release day, as `main` can't take it; the
release then follows "Making a release" in docs/MAINTAINING.md, with
the cut-over between its steps 1 and 2.
