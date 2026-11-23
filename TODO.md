# Planned work

## The POD's spelling checked in CI, and the tarball before the tag

**From:** Ekorn-Pipeline's session, 2026-11-23 (Ekorn-Pipeline
699a76cc7238d44bcdd0632be48699758973405b)
**Waiting on:** nothing

Minilla's POD spelling test, `xt/minilla/spelling.t`, runs only as
`minil dist` builds the tarball, which the release steps do after the
tag is pushed. A word it doesn't know then fails the release when the
tag can't be taken back. Ekorn-Pipeline's v0.3.8 was tagged, and its
GitHub release made, before its tarball failed on "setlist", a word
in the reference's examples, so that version never reached CPAN, and
v0.3.9 follows it. It was the second time there; DBIx-Squirrel had
the same in 5d1801c4c54dc027e7de53975a8a931f00dfed77. Iain asked for
the fix to be made permanent, and for DBIx-Squirrel to have it too.

What Ekorn-Pipeline did, in the commit above, to do here the same way:

- **`xt/spelling.t`, which CI runs on every push,** checks the POD as
  Minilla's test does: Test::Spellunker's
  `all_pod_files_spelling_ok('lib')`, with the distribution's name as
  a stopword, and `minil.toml`'s stopwords, if it has any. It's skipped,
  saying so, where Test::Spellunker isn't installed; the coverage job,
  which installs the cpanfile's develop modules, Test::Spellunker
  among them, runs it, as `.yath.rc` searches `xt/`. Ekorn's, for a
  start, as DBIx-Squirrel's differs only in the name:

  ```perl
  BEGIN {
      eval { require Test::Spellunker; Test::Spellunker->VERSION('v0.2.2') }
          or skip_all "Test::Spellunker v0.2.2 or later isn't installed";
      Test::Spellunker->import;
  }

  add_stopwords('DBIx-Squirrel');

  all_pod_files_spelling_ok('lib');
  ```

  Check that it fails with a stopword taken out that the POD needs,
  passes with it back, and that the coverage job's log shows it
  `PASSED`, not skipped.
- **The release builds and tests the tarball before anything is
  tagged.** At the end of MAINTAINING's "Making a release" step 3,
  after CI passes on the release commit, `minil dist --skip-prepare`
  from `develop`, which must print `Result: PASS`, and the tarball
  removed, so any other release test of Minilla's that CI doesn't run
  fails while the version isn't spent. Ekorn added it there, rather
  than as a step of its own, as other text refers to the steps by
  number.
- **MAINTAINING's note on the manuals** says `xt/spelling.t` checks the
  spelling, and where an unknown word that's right goes: the
  `<!-- stopwords: ... -->` comment at the top of the Markdown.

**Done when:** `xt/spelling.t` is in, failing on an unknown word and
passing without one; CI's coverage job runs it; and MAINTAINING's
release builds the tarball, and reads `Result: PASS`, before the tag.

## Ekorn::Pipeline v0.3.9 is on CPAN

**From:** Ekorn-Pipeline's session, 2026-11-23 (Ekorn-Pipeline
efe7089a6c434a4dd5839d995c8a91e606d469db, tagged v0.3.9)
**Waiting on:** nothing

Ekorn::Pipeline v0.3.9 is on CPAN, uploaded 2026-11-23. It changes
only the documentation, and the code is v0.3.7's, so DBIx::Squirrel's
range, `>= v0.3.7, < v0.4.0`, takes it with no change. v0.3.8 was
tagged, and has a GitHub release, but never reached CPAN, as its
tarball failed Minilla's POD spelling test (the task above).

What's new to CPAN: the reference's index gives each name a synopsis
of all its forms, a paragraph or two, "Exported by default." or
"Exported upon request.", and a link to the section showing it in
use, the reference's text rewritten to match, as DBIx-Squirrel's
task 2026-11-18 asked. Ekorn's index says "upon request" where
DBIx-Squirrel's says "on request", as Iain chose for Ekorn; Iain will
say whether DBIx-Squirrel's should follow.

**Done when:** read, and nothing here needs doing; remove it, saying
so, in the commit that does.
