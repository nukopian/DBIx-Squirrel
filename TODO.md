# Planned work

## 9. Ekorn::Pipeline v0.1.1 is released: take it on

**From:** Ekorn-Pipeline's session, 2026-11-08 (Ekorn-Pipeline
1c345d8828ac3c651ed97a98b006fbed5571b946, tagged `v0.1.1` on `main`)
**Waiting on:** nothing; PAUSE's index, for task 2's trial only

**What:** Ekorn::Pipeline v0.1.1 is released properly, not as a trial,
as Iain decided, after the v0.1.1 trial's first reports (46 pass on 13
platforms, Perl 5.36.0 to 5.44.0; 7 na from Perls older than 5.36):

- `Ekorn-Pipeline-v0.1.1.tar.gz`, built from the tag after CI passed
  on the commit above, SHA-256
  d4058ccf8606ee282ef13e6898fd6b24b72ca03f9d491099abb801b1eb7592e3,
  uploaded to PAUSE at about 01:31 UTC on 2026-11-08. The CPAN mirror
  has it; PAUSE hadn't indexed it yet at 01:35 UTC. Check before anything
  that installs it from CPAN, as task 2's trial does; each prints
  v0.1.1 once it's indexed:

  ```
  curl -sSf https://cpanmetadb.plackperl.org/v1.0/package/Ekorn::Pipeline
  curl -sSf https://fastapi.metacpan.org/v1/release/Ekorn-Pipeline | jq -r .name
  ```

- The GitHub release, and the signed tag: `main` is now at the commit
  above, with `docs/HOWTO.md` and `docs/REFERENCE.md` on it.
- It differs from the v0.1.1 trial in its documentation only, as Iain
  decided needs no new trial: corrected POD on a plain closure's state
  when its stages are spliced (Ekorn-Pipeline
  f9b44b8f895203cb07c945829f9af7ecc19e33ea, from your message), and a
  SECURITY.md and a CONTRIBUTING.md (Ekorn-Pipeline
  5028cc3212dcd24469837a24f4b23e74f3a236c6, from your task 3).

Your tasks this frees, for Iain to say which to do:

- **Task 4,** linking to Ekorn::Pipeline's docs: it waited on v0.1.1
  with the how-to and the reference on `main`, which they now are.
- **Task 1,** merging `ekorn-pipeline` into `develop`: it waited on
  v0.1.1. Your range, `>= v0.1.1, < v0.2.0`, takes it.
- **Task 2,** the v2.0.3 trial: from 2026-11-09, once v0.1.1 is
  indexed and task 1 is merged.

**Why:** nothing else tells this session a release has landed.

**Done when:** read, and the tasks above are taken up as Iain says.

## 1. Develop DBIx::Squirrel against Ekorn::Pipeline, on a branch

**When:** now, until Ekorn::Pipeline v0.1.1 is released, a couple of
days from 2026-11-08, as Iain expects, with no more trials before it;
Ekorn-Pipeline is stabilised in a session of its own, in
`~/Git/github.com/nukopian/Ekorn-Pipeline`.

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
  their functions, imported by name from lists of DBIx::Squirrel's own,
  so a function Ekorn drops fails as the module loads, and one it adds
  reaches DBIx::Squirrel only once it's listed. DBIx::Squirrel always
  inherits from Ekorn, never the reverse. Iain decided this on
  2026-11-07, and it's done, on the branch.
- `cpanfile` requires Ekorn::Pipeline `>= v0.1.1, < v0.2.0`, as Iain
  decided on 2026-11-07 (from v0.1.1, its first with an iterator that
  ends once a stage dies, task 8, on 2026-11-08): the facade keeps the names, not the
  behaviour, so a v0.2.0 reaches DBIx::Squirrel's users only once it's
  been tested here and the range moved. Done, on the branch.
- The documented way to throw a stop on in a stage that catches errors
  becomes `die $e if $e isa 'Ekorn::Pipeline::Stop';`. Checking for
  `DBIx::Squirrel::Stop` would miss the stops Ekorn's own stages throw,
  such as `take`'s.
- The tests stay, and test DBIx::Squirrel's behaviour through its own
  names, so a change in Ekorn that its users would notice fails here;
  only the class names they expect changed. `t/07-namespaces.t` checks
  that the facade's lists stay as documented, and name only functions
  Ekorn still exports. The docs say where the pipeline lives, and
  `Changes` says so too. Done, on the branch; the condition coverage
  floor went from 88 to 87, as the pipeline's conditions, all covered,
  left `lib/`.

Until Ekorn::Pipeline v0.1.1 is released (a trial is on CPAN, but
CPAN's index, which `cpanm` installs from, doesn't hold trials), the
branch installs it from GitHub: its `test.yml` adds `ekorn-pipeline`
to the branches it runs on, and a step before `cpanm --installdeps`
runs `cpanm https://github.com/nukopian/Ekorn-Pipeline.git@develop`.
Locally, install it from the same place into each DBIx-Squirrel-2
library, not from the working copy, which may hold a session's
unfinished work, and again after each change to it there:

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

**Done when:** task 4 is done on the branch, as task 5 is, it passes every
CI job and `scripts/coverage` on Ekorn::Pipeline as released, and
Iain has reviewed it. It's merged into `develop` by a fast-forward,
after `develop`'s other commits are rebased under it; the CI steps
that install from GitHub go in that merge, and the branch is deleted.
The note on it in docs/MAINTAINING.md's Branches goes too. `TODO.md`
is kept on the branch while it lives, as CLAUDE.md's Planned work says
(Iain, 2026-11-08), and `develop`'s copy falls behind, so where the
rebase conflicts in it, the branch's text is the answer.

## 4. Link to Ekorn::Pipeline's docs, and say what stage authors need

**From:** a message from Ekorn-Pipeline's session, 2026-11-07
(Ekorn-Pipeline eeec4c24f932e92d588acfcb1d8e6c5b74f3bdb6)
**Waiting on:** Ekorn::Pipeline v0.1.1, with its `docs/HOWTO.md` and
`docs/REFERENCE.md` on its `main`.

**When:** on the branch `ekorn-pipeline`, before it merges, as the
merge waits for v0.1.1 too (task 1).

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
   Where they're told to use `croakf`, say its format is a literal, with
   the values as arguments, as Errors.pm's POD has said since task 5.

What an iterator does after a stage dies, the third part of this task
when it came, was settled by Ekorn-Pipeline's v0.1.1 and done with
task 8, on 2026-11-08: the docs say it, and `t/14-iterate.t` pins it.

**Why:** two copies of how the pipeline works would drift apart, and
Ekorn's is the one kept up to date with the code.

**Done when:** the docs link to Ekorn's for the pipeline, and the
`@CARP_NOT` line is documented; the tests pass and the PDFs are read.

## 6. Move the plan doc's open work and decisions into the roadmap

**From:** Ekorn-Pipeline's session, 2026-11-07 (Ekorn-Pipeline
1109d1352d9773062c1916e00ee2964bd3670fec, and its dogfooding rule in
89e12df5d6ebaaf7246ef0d99920a3f554420a4e)
**Waiting on:** Iain, once he's done with Ekorn-Pipeline, as he said
on 2026-11-07.

**What:** the rest of the task to keep a roadmap and change records,
with ids, as Ekorn-Pipeline does. Its other steps are done: CLAUDE.md's
"The roadmap", "Change records", dogfooding and precis rules,
`ROADMAP.md`, `docs/changes/README.md`, docs/MAINTAINING.md and
`minil.toml`, as Ekorn-Pipeline has them, with DBIx-Squirrel's names.
Iain decided on 2026-11-07 that the tasks already in `TODO.md` get no
ids or records: the rule applies to tasks added from then on.

1. With Iain, go through the Claude Doc "DBIx-Squirrel successor:
   plan" (https://claude.ai/artifact/1cnZmM5LRgpgX3F6sF8VqB). Each part
   still to be done becomes a roadmap item, with the next id, from
   2026-0001, and each decision still open a numbered, unchecked
   decision in its item's record. Decisions already made stay in the
   commits and CLAUDE.md that hold them. `ROADMAP.md` and the records
   are public: nothing personal from the doc goes in them.
2. Replace the examples "A title" and `a-title`, in CLAUDE.md's "The
   roadmap" and docs/MAINTAINING.md's Branches, with the first item's
   title and slug.
3. Three places still point into the doc. Move what they need, and
   point them at its new home:
   - the opening of CLAUDE.md, whose sentence "Until the open work and
     decisions of the Claude Doc ... they're in it still" goes;
   - the doc's "Cut-over to DBIx-Squirrel" section, which CLAUDE.md's
     "The name" and docs/MAINTAINING.md's "The cut-over" both name:
     check it against "The cut-over", move anything that's only in the
     doc there, and name that section instead;
   - the doc's "Canned stages" section, which Claude's memory
     `default-exports.md` names for the open questions on canned
     stages: point it at their record instead.
4. Then leave the doc alone; deleting it is Iain's call.

**Why:** Claude Docs sit outside the repository, apart from the history
and the chat, and Iain finds them impermanent.

**Done when:** the plan doc's open work and decisions are in the
roadmap and its records, and nothing in the repository, or Claude's
memory, points into it.

## 2. Trial, then release, v2.0.3 on Ekorn::Pipeline

**When:** from 2026-11-09, once Ekorn::Pipeline v0.1.1 is released
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
   Read on 2026-11-08, at 01:06 UTC: 80 passes, 16 `na`, no failures.
   The `na`s are all Perls before 5.36 (5.12.5 to 5.34.3); the passes
   span 5.36.0 to 5.45.5, on Linux, FreeBSD, OpenBSD, NetBSD,
   DragonFly, MidnightBSD, Windows, Cygwin, macOS, Solaris, Android,
   Haiku and GNU/Hurd. CPANTS gives the trial no core Kwalitee issues,
   only the experimental three, for a SECURITY and a CONTRIBUTING
   document. Read again for reports since, before the v2.0.3 trial.
2. Check `cpanfile`'s range for Ekorn::Pipeline, `>= v0.1.1, < v0.2.0`,
   takes the version released, and regenerate `META.json` and
   `Build.PL` with `minil build` if it changes. Iain decided on
   2026-11-07 that DBIx::Squirrel requires a range of Ekorn's 0.x
   releases, rather than waiting for Ekorn 1.0 or having Ekorn promise
   no breaks in 0.x: the facade keeps the names, but not the behaviour,
   such as when a `gather` stage is made, so a v0.2.0, which may break
   it, reaches DBIx::Squirrel's users only once it's been tested here
   and the range moved.
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
