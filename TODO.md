# Planned work

## Review the v2.0.2 trial, then release v2.0.2

**When:** from 2026-11-09, or sooner at a failing report, a new release
of DBI or DBD::SQLite, or a new session before then.

**Uploaded:** v2.0.2 went to CPAN as a trial on 2026-11-06,
`DBIx-Squirrel-v2.0.2-TRIAL.tar.gz`, built from
`b733ac03d2b3d374538046e5fb39dc495ae68abc`, which passed every CI job.
Its own tests passed in the build (`Result: PASS`).

**What:** v2.0.0 went to CPAN as a trial on 2026-11-05, and by
2026-11-06 had drawn 55 passes, on platforms including Windows and four
BSDs, and Perls from 5.36.3 to 5.44.0, and 8 `na` from Perls older than
5.36. v2.0.1 followed on 2026-11-06, with gather, the canned stages, an
iterator's column_names and faster fetching, and drew 31 passes the
same day. Then list placeholders (`...:ids`, written as a `?` for each
value), from `2ae3e6318b3f702307308219205b41d44104d5b0`, went onto
`develop`, so that trial no longer tests what the release would be.
Iain reviews that commit, which Claude wrote, reads the v2.0.2 trial's
reports, and decides whether v2.0.2 is ready to release. CPAN doesn't
index a trial, so `cpanm DBIx::Squirrel` still installs 1.6.5.

The version moves on with each trial, as Iain decided on 2026-11-06,
because PAUSE won't take a file name twice, and an underscore version,
such as `v2.0.1_1`, would rank above the release it was a trial of. So
v2.0.0 and v2.0.1 stay trials, and the first 2.x release is v2.0.2.

**Why:** CI runs on Linux and macOS only. A trial is tested on
platforms it doesn't cover, such as Windows and the BSDs, and against
other versions of DBI and DBD::SQLite, before v2.0.2 replaces 1.6.5 for
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
