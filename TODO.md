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
- Pipeline, Stop, Gather, Pipes and Stages::Flow, Batch and Taps stay,
  as a permanent facade: subclasses of Ekorn's modules, or exporting
  what they export, copied from their lists when loaded, so a stage
  added to Ekorn is here too. DBIx::Squirrel always inherits from
  Ekorn, never the reverse. Iain decided this on 2026-11-07, and it's
  done, on the branch.
- The documented way to throw a stop on in a stage that catches errors
  becomes `die $e if $e isa 'Ekorn::Pipeline::Stop';`. Checking for
  `DBIx::Squirrel::Stop` would miss the stops Ekorn's own stages throw,
  such as `take`'s.
- The tests stay, and test DBIx::Squirrel's behaviour through its own
  names, so a change in Ekorn that its users would notice fails here;
  only the class names they expect changed. `t/07-namespaces.t` checks
  that the facade exports what Ekorn does. The docs say where the
  pipeline lives, and `Changes` says so too. Done, on the branch; the
  condition coverage floor went from 88 to 87, as the pipeline's
  conditions, all covered, left `lib/`.

Until Ekorn::Pipeline is on CPAN, the branch installs it from GitHub:
its `test.yml` adds `ekorn-pipeline` to the branches it runs on, and a
step before `cpanm --installdeps` runs
`cpanm https://github.com/nukopian/Ekorn-Pipeline.git@develop`. Locally,
install it from the same place into each DBIx-Squirrel-2 library, not
from the working copy, which may hold a session's unfinished work, and
again after each change to it there:

```
for p in perl-5.36.3 perl-5.38.5 perl-5.40.5 perl-5.42.3 perl-5.44.0; do perlbrew exec --quiet --with "${p}@dbix-squirrel-2" cpanm --notest https://github.com/nukopian/Ekorn-Pipeline.git@develop || echo "FAILED on ${p}"; done
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
