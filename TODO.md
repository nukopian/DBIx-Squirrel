# Planned work

## 1. Develop DBIx::Squirrel against Ekorn::Pipeline, on a branch

**When:** now, until 2026-11-09, while Ekorn-Pipeline is stabilised in
a session of its own, in `~/Git/github.com/nukopian/Ekorn-Pipeline`.

**What:** on a branch `ekorn-pipeline`, made from `develop`, replace
DBIx::Squirrel's own copy of the pipeline with Ekorn::Pipeline, as a
dependency. The copy came out as Ekorn-Pipeline on 2026-11-07, from
`5e30135672d8002b0bb67ba68278e5b1c262df8b`, renamed and otherwise
unchanged, so the code to change is small:

- `Iterator.pm` makes an `Ekorn::Pipeline`, and `Context.pm` calls
  `Ekorn::Pipeline::ending()`.
- `db.pm` and `st.pm` inherit `pipe` and `tap` from
  `Ekorn::Pipeline::Pipes`.
- `Stages/Rows.pm` stays DBIx::Squirrel's, made with Ekorn's `gather`;
  stages that need DBIx::Squirrel stay under `DBIx::Squirrel::Stages::*`,
  as Iain decided on 2026-11-07.
- `Errors.pm`'s `@INTERNAL` takes Ekorn's packages, so errors raised
  inside Ekorn are still reported at the user's line.
- Pipeline, Stop, Gather, Pipes and Stages::Flow, Batch and Taps go, or
  stay as re-exports and subclasses of Ekorn's (always DBIx::Squirrel
  inheriting from Ekorn, never the reverse). Which, for each, is Iain's
  decision. Nothing of 2.x is released yet, so no user's code names
  them.
- The documented way to throw a stop on in a stage that catches errors
  becomes `die $e if $e isa 'Ekorn::Pipeline::Stop';`. Checking for
  `DBIx::Squirrel::Stop` would miss the stops Ekorn's own stages throw,
  such as `take`'s.
- The tests of the modules that go are Ekorn-Pipeline's now; their
  subtests on SQLite stay here. The docs (REFERENCE.md, HOWTO.md and
  the README, about 55 mentions) follow the code, and `Changes` says
  where the pipeline now lives.

Until Ekorn::Pipeline is on CPAN, the branch installs it from GitHub:
its `test.yml` adds `ekorn-pipeline` to the branches it runs on, and a
step before `cpanm --installdeps` runs
`cpanm https://github.com/nukopian/Ekorn-Pipeline.git`. Locally, install
it from the working copy into each DBIx-Squirrel-2 library:

```
for p in perl-5.36.3 perl-5.38.5 perl-5.40.5 perl-5.42.3 perl-5.44.0; do perlbrew exec --quiet --with "${p}@dbix-squirrel-2" cpanm --notest ~/Git/github.com/nukopian/Ekorn-Pipeline || echo "FAILED on ${p}"; done
```

A change Ekorn-Pipeline needs, found here, is made there, in its own
session, and installed again; not patched here.

**Why:** DBIx::Squirrel is to depend on Ekorn::Pipeline. Doing it
before the first 2.x release means no user has code naming
DBIx::Squirrel's pipeline modules, so nothing has to be kept for them,
and DBIx::Squirrel, as Ekorn::Pipeline's first real user, tests the
names Ekorn::Pipeline is about to make public.

**Done when:** the branch passes every CI job and `scripts/coverage`,
on Ekorn::Pipeline as released (task 2), and Iain has reviewed it. It's
merged into `develop` by a fast-forward, after `develop`'s other
commits, if any, are rebased under it; the CI steps that install from
GitHub go in that merge, and the branch is deleted. The note on it in
docs/MAINTAINING.md's Branches goes too.

## 4. Link to Ekorn::Pipeline's docs, and say what stage authors need

**From:** a message from Ekorn-Pipeline's session, 2026-11-07
(Ekorn-Pipeline eeec4c24f932e92d588acfcb1d8e6c5b74f3bdb6)
**Waiting on:** Ekorn::Pipeline v0.1.0, with its `docs/HOWTO.md` and
`docs/REFERENCE.md` on its `main`, and Iain's decisions there on the
three behaviours below.

**When:** on the branch `ekorn-pipeline`, before it merges, as the
merge waits for v0.1.0 too (task 1).

**What:**

1. Where DBIx::Squirrel's reference, how-to and POD explain how the
   pipeline works, link to Ekorn-Pipeline's how-to and reference
   instead, keeping to what's DBIx::Squirrel's own: rows, statements,
   iterators and result sets, `pipe` and `tap` on handles,
   DBIx::Squirrel::Context, `pluck` and `as_hash`. Show Iain the
   trimmed sections before committing: how much to cut is his call.
2. Say, for anyone writing stages under DBIx::Squirrel's namespace,
   that a module running its callers' stages reports their failures
   at the callers' lines only with
   `our @CARP_NOT = @DBIx::Squirrel::Errors::INTERNAL;`, which takes in
   Ekorn's packages, as DBIx::Squirrel's own modules do. Errors.pm's
   POD doesn't document `@INTERNAL` yet, so document it there too.
3. Ekorn-Pipeline is deciding, before v0.1.0, whether an iterator
   carries on with the next value after a stage dies; whether a
   pipeline called in scalar context returns its count; and whether a
   pipeline is accepted as a stage. DBIx::Squirrel's docs promise none
   of them, and its code uses none but the first: an iterator's `next`
   pulls through Ekorn's iterator, so what Ekorn decides is what `next`
   does after a stage dies, and no test here pins it
   (`t/14-iterate.t`'s "errors are reported at the caller" checks the
   error, never a `next` after it). Add a test that does, and say it
   in the reference's "When a stage dies". Mention the other two only
   if Iain wants DBIx::Squirrel to.

**Why:** two copies of how the pipeline works would drift apart, and
Ekorn's is the one kept up to date with the code. A behaviour no test
pins could change in a v0.1.x without DBIx::Squirrel noticing, though
its version range assumes v0.1.x never changes behaviour.

**Done when:** the docs link to Ekorn's for the pipeline, the
`@CARP_NOT` line is documented, and a test pins `next` after a stage
dies; the tests pass and the PDFs are read.

## 2. Trial, then release, v2.0.3 on Ekorn::Pipeline

**When:** from 2026-11-09, once Ekorn::Pipeline v0.1.0 is released
(not as a trial: CPAN Testers install dependencies from the index,
which doesn't hold trials, so a DBIx::Squirrel trial needing an
Ekorn::Pipeline trial would mostly report a missing prerequisite) and
task 1 is merged.

**What:** v2.0.2 went to CPAN as a trial on 2026-11-06,
`DBIx-Squirrel-v2.0.2-TRIAL.tar.gz`, built from
`b733ac03d2b3d374538046e5fb39dc495ae68abc`. v2.0.0 and v2.0.1 went
before it, on 2026-11-05 and 2026-11-06. With the pipeline moved to
Ekorn::Pipeline, the v2.0.2 trial no longer tests what the release
would be, so, as the version moves on with each trial (Iain's decision
of 2026-11-06), v2.0.2 stays a trial and the next is v2.0.3:

1. Read the v2.0.2 trial's reports first, as a failure in them may
   still apply; fix one on `develop`, with a test.
2. Require Ekorn::Pipeline at the version released, in `cpanfile`, and
   regenerate `META.json` and `Build.PL` with `minil build`.
3. Upload a trial of v2.0.3, as "A trial release" in
   docs/MAINTAINING.md says, and read its reports.
4. Iain decides whether v2.0.3 is ready to release.

The reports' counts by version and grade, then each report that didn't
pass, with a link to it:

```
curl -sSf https://api.cpantesters.org/v3/summary/DBIx-Squirrel | jq -r 'group_by(.version)[] | group_by(.grade)[] | "\(.[0].version) \(.[0].grade): \(length)"'
curl -sSf https://api.cpantesters.org/v3/summary/DBIx-Squirrel | jq -r '.[] | select((.version | startswith("v2") or startswith("2")) and .grade != "pass") | "\(.version) \(.grade) \(.osname) perl \(.perl) https://www.cpantesters.org/cpan/report/\(.guid)"'
```

An `na` from a Perl older than 5.36 is expected, and needs nothing.
CPAN doesn't index a trial, so `cpanm DBIx::Squirrel` still installs
1.6.5 meanwhile.

**Why:** CI runs on Linux and macOS only. A trial is tested on
platforms it doesn't cover, such as Windows and the BSDs, and now
against Ekorn::Pipeline as CPAN installs it, before 2.x replaces 1.6.5
for everyone.

**Done when:** Iain has decided. If it's to release, the commit that
removes this file starts release day, as `main` can't take it; the
release then follows "Making a release" in docs/MAINTAINING.md, with
the cut-over between its steps 1 and 2.
