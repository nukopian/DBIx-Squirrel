# Planned work

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

**When:** from 2026-11-09. What it waited on is done: Ekorn::Pipeline
v0.1.1 was released on 2026-11-08, not as a trial, and indexed, as
CPAN Testers install dependencies from the index, which doesn't hold
trials; and the branch `ekorn-pipeline`, which ran DBIx::Squirrel on
it, was merged into `develop` the same day.

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
