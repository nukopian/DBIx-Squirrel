# Planned work

## 1. Ekorn::Pipeline v0.2.0: two messages change; test, follow, and move the range

**From:** Ekorn-Pipeline's session, 2026-11-09 (Ekorn-Pipeline
c5157c94fa9d65615c1b78bc7673e43dbd8823dd)
**Waiting on:** nothing for the testing and the changes; Ekorn-Pipeline
v0.2.0, on CPAN, for `cpanfile` and bringing them to `develop`

**What:** Ekorn-Pipeline's roadmap 2026-0008, done on its `develop`,
changes two messages, so its next release is v0.2.0, and, as
Ekorn-Pipeline's CLAUDE.md says, comes with this task:

- "Expected stage #%d to be a code reference" is now "Expected stage
  #%d to be a code reference or a pipeline", worded as this
  repository's own Sugar message is.
- "Expected stage #%s, made with gather, to return one or two code
  references" is now "Expected stage #%s, made with gather, to return
  a code reference or a pipeline, and optionally an end function".

Nothing else changes in behaviour. Ekorn's session ran this
repository's tests against its `develop` at the commit above, from
`develop` here at 2eb3fb8c4573e73bfd0406f9efe927111e9ce1b5, with
Ekorn's `lib` first on `PERL5LIB`, on 5.36.3 and 5.44.0. Four files
fail, all on the old wording and nothing else: `t/02-tap.t`,
`t/03-pipe.t`, `t/05-pipeline.t` ("new checks", a regex) and
`t/06-gather.t`.

**Steps:**

1. Try Ekorn's `develop` without installing it, as before, from a
   worktree, with its `lib` first on `PERL5LIB` so `xt/howto.t` sees
   it too:

   ```
   git -C ~/Git/github.com/nukopian/Ekorn-Pipeline fetch -q origin
   git -C ~/Git/github.com/nukopian/Ekorn-Pipeline worktree add --detach /tmp/ekorn-pipeline-develop origin/develop
   perlbrew exec --with perl-5.36.3@dbix-squirrel-2 bash -c 'PERL5LIB=/tmp/ekorn-pipeline-develop/lib:$PERL5LIB yath test'
   ```

2. Change this repository's copies of the two messages to the new
   wording: the four test files above; `lib/DBIx/Squirrel.pm`'s
   DIAGNOSTICS (near lines 497 and 502) and what they say; and
   `docs/REFERENCE.md`'s table (near lines 1535 and 1537). Then the
   manuals, and `Changes`, saying the messages changed with Ekorn's
   v0.2.0.
3. Keep this work off `develop` until v0.2.0 is on CPAN, as CI
   installs Ekorn from CPAN, where v0.1.3 has the old wording: on a
   branch, as Iain decides.
4. Tell Ekorn-Pipeline, with a message in its `TODO.md` on its
   `develop`, whether the tests pass against its `develop` with the
   changes, or what was found. Ekorn's session will raise anything
   found with Iain before v0.2.0.
5. Once Ekorn-Pipeline tells this session v0.2.0 is on CPAN: raise
   `cpanfile`'s range for Ekorn::Pipeline to `>= v0.2.0, < v0.3.0`,
   regenerate `META.json` and `Build.PL` with `minil build`, and bring
   the work to `develop`.
6. Remove the worktree:
   `git -C ~/Git/github.com/nukopian/Ekorn-Pipeline worktree remove /tmp/ekorn-pipeline-develop`.

**Done when:** the message is sent; and, after v0.2.0, this
repository's tests and docs use the new wording on `develop`, and
`cpanfile` asks for `>= v0.2.0, < v0.3.0`.
