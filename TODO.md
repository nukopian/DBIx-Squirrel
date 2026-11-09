# Planned work

## 1. Take a pipeline where a stage goes, with Ekorn::Pipeline's is_stage, and sign off v0.1.3

(Updated 2026-11-09, at Ekorn-Pipeline
514e19d1a385791ac7aae6723173c9097542c462, for roadmap 2026-0007 and
the docs. Iain asked that DBIx-Squirrel follow suit, so the docs are
now a step of this task, not only a message.)

**From:** Ekorn-Pipeline's session, 2026-11-09 (Ekorn-Pipeline
45b33a4668c2700a825bfb25483bc4386158d9ca), in place of the task of the
same name from 3f3e94d809bf7a277f749dfa1e7fae4abb76038a
**Waiting on:** nothing for the work and the sign-off; Ekorn-Pipeline
v0.1.3, on CPAN, for `cpanfile` and a release here

**What:** Ekorn-Pipeline's roadmap 2026-0004 lets
`Ekorn::Pipeline->new` take a pipeline where a stage goes, composing
its stages in place, as if its `stages` had been given there (its
`stages` method, so a subclass that overrides it is composed as it
says); a stage inside is named in messages by its place in each
pipeline, "#2.3". It also exports `is_stage` on request
(`use Ekorn::Pipeline qw(is_stage)`), true for a code reference or an
`Ekorn::Pipeline`, of a subclass too: the test `new` makes, so
DBIx::Squirrel and Ekorn::Pipeline agree on what a stage is.

Ekorn-Pipeline's roadmap 2026-0007 (514e19d1a385791ac7aae6723173c9097542c462)
also lets a `gather` block return a pipeline as its stage: its stages
are made for each run in its place, `gather` stages inside it afresh,
and the block's end function, if any, is called after theirs. A stage
inside it is named "#2.3". The message for a bad block is unchanged.
DBIx::Squirrel's `gather` is Ekorn's, so it gets this as it stands.
This repository's tests pass against Ekorn's `develop` at that commit,
on 5.36.3 and 5.44.0, run by Ekorn's session.

It's on Ekorn-Pipeline's `develop`, for v0.1.3, an addition within
`cpanfile`'s range, `>= v0.1.1, < v0.2.0`. Iain has gated v0.1.3's
release on this session's sign-off, so it's tried here first, as
DBIx::Squirrel's use of it, before CPAN has it.

With no change here, `DBIx::Squirrel::Pipeline->new($hits, take(1))`
works, and this repository's tests pass: Ekorn-Pipeline's session ran
them, 1431 assertions, against its `develop` at
ce35c04334e0b9138bd90ac193c76a7c50f02be4, on 5.36.3 and 5.44.0. But
`$dbh->iterate($sql, $hits)` doesn't work, as DBIx::Squirrel looks for
stages at the end of a call's arguments with Ref::Util's `is_coderef`,
and a pipeline, a blessed hash that overloads `&{}`, fails it, so it's
taken for a bind value.

Two things to know. `DBIx::Squirrel::Pipeline` now inherits Exporter's
`import` from Ekorn::Pipeline, which is harmless for
`use DBIx::Squirrel::Pipeline;` and `qw()`, but `is_stage` must be
imported from Ekorn::Pipeline, not the facade, unless the facade
exports it. And the two messages naming a stage that runs read "#%s"
in Ekorn's DIAGNOSTICS now; a flat pipeline's read as before.

**Steps:**

1. Try Ekorn-Pipeline's `develop` without installing it, so this
   repository's library keeps v0.1.2, from a worktree of it:

   ```
   git -C ~/Git/github.com/nukopian/Ekorn-Pipeline fetch -q origin
   git -C ~/Git/github.com/nukopian/Ekorn-Pipeline worktree add --detach /tmp/ekorn-pipeline-develop origin/develop
   perlbrew exec --with perl-5.36.3@dbix-squirrel-2 yath test -I/tmp/ekorn-pipeline-develop/lib
   ```

   `-I` is needed: perlbrew's library sets `PERL5LIB`, which would
   otherwise find the installed v0.1.2 first.
2. Use `is_stage` in place of `is_coderef` where a call's stages are
   looked for: `split_stages` in `lib/DBIx/Squirrel/Util.pm`,
   `_ends_in_stages` in `lib/DBIx/Squirrel/Sugar.pm`, and Sugar's check
   of a statement's definition (`grep { !is_coderef($_) } @rest`, near
   line 103). Leave `is_coderef` where it means a code reference, as in
   `Errors.pm`.
3. Test `iterate`, `results` and Sugar's statements with a pipeline
   among the stages, alone and with others after it, and that its
   stages run in the call's run (a `take(2)` inside gives 2 in all).
4. Rewrite "Give `$hits->stages`, not `$hits`" in `docs/REFERENCE.md`
   (near line 910) and `docs/HOWTO.md` (near line 769), and their
   examples, to give `$hits`, keeping `->stages` for a function that
   takes only code references; then the manuals, and `Changes`.
5. Bring the docs into line with Ekorn's, as v0.1.3 makes them:
   - Where they say what a stage is, say it's a code reference or a
     pipeline, as the message "a stage is a code reference or a
     pipeline", above, lists: `lib/DBIx/Squirrel.pm` near line 324,
     `docs/REFERENCE.md` near line 796, `docs/HOWTO.md` near line 521.
   - DIAGNOSTICS, in `lib/DBIx/Squirrel.pm` (near lines 488 to 501)
     and `docs/REFERENCE.md`'s table (near lines 1475 to 1478): the
     two messages naming a stage that runs read `#%s`, not `#%d`, since
     a stage inside a pipeline is named "#2.3"; "Expected stage #%d to
     be a code reference" is raised for something that isn't a code
     reference or a pipeline; and a `gather` block may return a code
     reference or a pipeline as its stage. Ekorn's
     `lib/Ekorn/Pipeline.pm` DIAGNOSTICS has the wording.
   - Test that `gather` (this repository's) takes a block returning a
     pipeline, in one run, as Ekorn's `t/11-gather-pipeline.t` does.
6. Keep this work off `develop` until v0.1.3 is on CPAN, as CI installs
   Ekorn::Pipeline from CPAN, where v0.1.2 has no `is_stage`: on a
   branch, as Iain decides.
7. Sign off: send Ekorn-Pipeline a message, in its `TODO.md`, on its
   `develop`, saying what was tried, against which Ekorn commit, and
   whether the tests pass; or what was found, if not, for its session
   to fix before the release. Its release task waits on it, and covers
   2026-0004 and 2026-0007.
8. Once Ekorn-Pipeline tells this session v0.1.3 is on CPAN: raise
   `cpanfile`'s range to `>= v0.1.3, < v0.2.0`, regenerate `META.json`
   and `Build.PL` with `minil build`, and bring the work to `develop`.
9. Remove the worktree: `git -C ~/Git/github.com/nukopian/Ekorn-Pipeline worktree remove /tmp/ekorn-pipeline-develop`.

**Done when:** the sign-off is sent; and, after v0.1.3,
`$dbh->iterate($sql, $pipeline, take(2))` runs the pipeline's stages
and then `take(2)`, in one run, tested, on `develop`, with the docs
showing it, saying a stage is a code reference or a pipeline, and
matching Ekorn's DIAGNOSTICS, and `cpanfile` asking for v0.1.3.
