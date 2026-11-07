# Messages

## From Ekorn-Pipeline, 2026-11-07: v0.1.0 is on CPAN as a trial

**From:** Ekorn-Pipeline's session, 2026-11-07 (Ekorn-Pipeline
b5e28c4e48c9615366e9b34191c8c4d86ace0865)

`Ekorn-Pipeline-v0.1.0-TRIAL.tar.gz` was uploaded to PAUSE on
2026-11-07, built from Ekorn-Pipeline
b5e28c4e48c9615366e9b34191c8c4d86ace0865 on `develop`, after every CI
job passed on that commit and its own tests passed in the tarball. It's
at
https://cpan.metacpan.org/authors/id/C/CP/CPANIC/Ekorn-Pipeline-v0.1.0-TRIAL.tar.gz,
SHA-256
2a67c85f1067fcfaa32693f09427ac4755dab530a9f28586fb02d2636966fdee.

- **What it is:** the same code the `ekorn-pipeline` branch installs
  from GitHub's `develop` today, with the fixes of this session: digits
  0-9 only for counts and sizes, a stop that isn't an array carries
  nothing, and the docs notes on `croakf` and `dump_to` (tasks 3 and 5
  here).
- **What it isn't:** the release. CPAN doesn't index a trial, so
  `cpanm Ekorn::Pipeline` won't find it, and task 2's wait is
  unchanged: it waits on v0.1.0 proper. To try the trial from CPAN:
  `cpanm CPANIC/Ekorn-Pipeline-v0.1.0-TRIAL.tar.gz`.
- **Next:** CPAN Testers' reports come in over the next few days. A
  failure is fixed and goes out as a new trial, v0.1.1, which the
  release then takes; `>= v0.1.0, < v0.2.0` covers either. Three
  decisions are with Iain before the release: whether an iterator
  carries on after a stage dies, whether a pipeline in scalar context
  keeps returning its count, and whether a pipeline is accepted as a
  stage. A release that changes any of them says so here first. The
  release ends, as before, with a task here saying it's on CPAN.

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

## 5. Take on what Ekorn-Pipeline's security review found

**From:** Ekorn-Pipeline's session, 2026-11-07 (Ekorn-Pipeline
b5e28c4e48c9615366e9b34191c8c4d86ace0865)
**Waiting on:** nothing

**What:** a security review of Ekorn::Pipeline found nothing serious.
Three of its findings apply here:

1. **Pin the CI's actions to commits.** `test.yml`, on `develop` and
   on `ekorn-pipeline`, uses `actions/checkout@v7` and
   `shogo82148/actions-setup-perl@v1`, tags their owners can move to
   other code. Ekorn-Pipeline pinned them in
   b5e28c4e48c9615366e9b34191c8c4d86ace0865, to the commits the tags
   point at today:

   ```
   uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
   uses: shogo82148/actions-setup-perl@eebc5c886de14ebbfcd2493d49a12007d2c30477 # v1.44.5
   ```

2. **Say `croakf`'s format is a literal,** wherever DBIx::Squirrel's
   docs tell stage authors to use it (task 4 may be the place): values
   go in as arguments, never as the format, as a format made from data
   does what its directives say (`%999999999s` makes a gigabyte). Its
   own calls all use literals already.
3. **Say `dump_to` is for debugging,** where DBIx::Squirrel documents
   it: it writes values in full, and Data::Dumper doesn't escape
   control characters. Ekorn's wording, in its Stages::Taps POD, is in
   b791dbe951c8f30e3807ccaada630226adf965d3.

A fourth needs nothing here: a stop that isn't an array, as by blessing
a hash into the class, made `@$e` die inside the pipeline. Ekorn fixed
it in f6827617d2c2cc820e56bea07cf6534f9b728a3a; DBIx::Squirrel's own
copy on `develop` has it, and loses it when task 1 replaces that copy.

**Why:** the same code and the same CI, so the same exposure.

**Done when:** the actions are pinned on the branch that's merged, and
the two notes are in DBIx::Squirrel's docs.
