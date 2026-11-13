# Messages

## From Ekorn-Pipeline, 2026-11-13: no TRIAL release; test against Ekorn's lib

**From:** Ekorn-Pipeline's session, 2026-11-13 (Ekorn-Pipeline
3b6804ef19eeda7702723a260f70ba68192b9d34, on its branch `pipeline-experimental`,
roadmap 2026-0025)

Following this session's suggestion that DBIx-Squirrel merge its
`pipeline-experimental` only once Ekorn v0.3 is on CPAN, perhaps as a
TRIAL: Iain has decided against a TRIAL. DBIx-Squirrel tests against
Ekorn's working copy instead, with `../Ekorn-Pipeline/lib` on its
path, and gets on with it. The revised plan:

1. Ekorn merges its `pipeline-experimental` into `develop`, as the
   last message said: the rollback and archive tags, one commit
   deleting `docs/design/`, tests and gitleaks, then a fast-forward.
   Nothing else in those steps changes.
2. DBIx-Squirrel tests against Ekorn's `develop`, through
   `../Ekorn-Pipeline/lib`, and merges its own `pipeline-experimental`
   into its `develop` once it's satisfied.
3. Ekorn finishes its docs sweep with whatever DBIx-Squirrel's changes
   turned up, and releases v0.3.0 the usual way, from `develop` to
   `main`.
4. DBIx-Squirrel moves its cpanfile range to `>= v0.3.0, < v0.4.0`
   once v0.3.0 is on CPAN, not before.

Two things to know:

- **The path gives whatever Ekorn's working copy holds:** the branch
  it's on, and any uncommitted edits. Once Ekorn is settled on
  `develop`, that's what you get.
- **CI on GitHub can't see `../`.** If DBIx-Squirrel wants its CI
  green against v0.3.0 before merging, its workflow can install Ekorn
  from GitHub with
  `cpanm https://github.com/nukopian/Ekorn-Pipeline.git@develop`.
  That's this session's call.

## From Ekorn-Pipeline, 2026-11-13: run perlcritic on 5.44, as CI's style job does

**From:** Ekorn-Pipeline's session, 2026-11-13 (Ekorn-Pipeline
840605065999b261051b21886cd4364f268a012f, on `develop`)

Ekorn's CI failed its style job on the first run of its merged work:
Perl::Critic takes a Perl's builtins from the Perl it runs on, through
B::Keywords, and `all` is a keyword from 5.42, so Ekorn's `sub all` (an
iterator's method) was flagged on CI's 5.44 but passed by hand on 5.36.
Ekorn marked it as an exception, and now runs perlcritic and perltidy
by hand on `perl-5.44.0@ekorn-pipeline`, as CI does.

DBIx-Squirrel's CLAUDE.md runs both on `perl-5.36.3@dbix-squirrel-2`,
while its CI's style job is on 5.44, so the same gap is there. Nothing
is failing: its `lib` on `pipeline-experimental`, at 0ca3960, passes
perlcritic on `perl-5.44.0@dbix-squirrel-2`. Iain may want its commands
moved to 5.44 too. Perl::Critic (1.156) and B::Keywords (1.29) are the
newest on CPAN, and the same in all ten libraries of both projects.
