# Messages

## From Ekorn-Pipeline, 2026-11-08: what its scripts/manuals added

**From:** Ekorn-Pipeline 448171b83782eb5004d814123881319d01569f92, on `develop`

Ekorn-Pipeline took `scripts/manuals` and `xt/manuals.t` from
871779ac4f818e0a55680f4ef6ba08d69840879c, as task 4 asked, and its
docs needed more than DBIx-Squirrel's use. Iain asked for what was
added to be shared, so the two copies stay alike. Each has tests in
Ekorn's `xt/manuals.t`:

- **Quotes,** `> ...` lines, become indented paragraphs, `=over 4`
  with no items, which Pod::Checker passes; a blank `>` line splits
  paragraphs, and anything but paragraphs in a quote is refused. A
  quote also ends a paragraph, as in GitHub's Markdown. Ekorn uses
  them for its "For stage authors" notes.
- **Italics,** `*word*`, become `I<word>`, and are stripped from
  anchors in `plain`; a lone `*`, with spaces round it, is left as it
  is.
- **Links to other files,** which POD can't make, go where a table,
  `%ELSEWHERE`, says each file is instead: Ekorn's reference links to
  `../Changes`, now its page on MetaCPAN.
- **A list in a list** is refused, naming the line. It had been folded
  into the item's text as a line starting `- `.

Two things found on the way: Minilla packs only the files git tracks,
so its spelling test passes on new manuals until they're added; and
`minil dist` exits 0 when it fails, so read its `Result:` line. Its
spelling test also skips without Test::Spellunker.

Diff the two copies to take what's wanted:

```
git -C ~/Git/github.com/nukopian/Ekorn-Pipeline show 448171b83782eb5004d814123881319d01569f92:scripts/manuals | diff ~/Git/github.com/nukopian/DBIx-Squirrel-2/scripts/manuals -
git -C ~/Git/github.com/nukopian/Ekorn-Pipeline show 448171b83782eb5004d814123881319d01569f92:xt/manuals.t | diff ~/Git/github.com/nukopian/DBIx-Squirrel-2/xt/manuals.t -
```

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
   Uploaded at 02:15 UTC on 2026-11-08, at Iain's word, a day before
   the date above: `DBIx-Squirrel-v2.0.3-TRIAL.tar.gz`, built from
   `512cd7439c3d21ed6d8bed7e4fc45cf11d7d4f49` after CI passed on it,
   its tests passing in the tarball, SHA-256
   9c7399f9ffb1fee973f88f0f0099bc370aaee8d30ad5c5f75e8bff4a4f54d20c.
   Before it, the v2.0.2 trial's reports were read again: no new ones
   since 01:06 UTC. Its reports come in over the next few days; read
   them with the commands below, and fix a failure on `develop`, with
   a test, before a new trial, v2.0.4.
   Read on 2026-11-08, at 16:38 UTC: 57 passes on 13 operating
   systems, Perl 5.36.0 to 5.44.0, 9 `na` from older Perls, and 2
   failures, both Slaven Rezić's, on Debian and Ubuntu system Perls
   5.36.0 and 5.38.2 with their DBI, 1.643. Both failed one check,
   `t/07-namespaces.t`'s "no croak" for DBIx::Squirrel: DBI 1.643
   imports Carp's croak into the DBI package (1.656 doesn't), and the
   test asked `can`, which found it through inheritance. The code was
   fine; the test now looks in each package's own symbol table, and
   the whole suite passes on DBI 1.643 and 1.656, and CI now has a
   job on DBI 1.643. The v2.0.4 trial, with the fix, was uploaded at
   16:56 UTC on 2026-11-08, at Iain's word:
   `DBIx-Squirrel-v2.0.4-TRIAL.tar.gz`, built from
   `9b0dd65efe4e756de4e084f668eac2279d2be8cf` after CI passed on it, its tests
   passing in the tarball, SHA-256
   3576350cac66e488232bfbaeee78f74d675da463779ac9917371fb148c3a0cf9.
   Read its reports next; the release takes the version of its last
   trial.
   The v2.0.5 trial followed at 17:27 UTC on 2026-11-08, as Iain asked,
   as the reference and the how-to became POD manuals after v2.0.4's
   upload (roadmap 2026-0001), so the release would otherwise differ
   from what was tried: `DBIx-Squirrel-v2.0.5-TRIAL.tar.gz`, built from
   `149f991f5faa39134a6e1e26ed544b3489f97dcf` after CI passed on it, its
   tests passing in the tarball, SHA-256
   06fb09da0914bd7c7d1f960bad2f08c3eaf85d337122c05ea7ed8008aea8b671.
   Its reports, and v2.0.4's, come next.
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
