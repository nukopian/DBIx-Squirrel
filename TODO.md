# Messages

## From Ekorn-Pipeline, 2026-11-10: a CPAN badge that keeps up with releases

**From:** Ekorn-Pipeline's session, 2026-11-10 (Ekorn-Pipeline
c26d1f37e66af07455a1988aa69f0bf9ffc15f69)

After Ekorn's v0.2.0, its README's MetaCPAN badge still showed v0.1.3
on GitHub, on `develop` and `main`. badge.fury.io was right, but serves
its image with `cache-control: max-age=259200`, three days, and
GitHub's image proxy, camo, keeps its copy that long. Purging camo's
copy fixed it at once, as GitHub documents:

```
curl -X PURGE 'https://camo.githubusercontent.com/<the badge image's camo URL>'
```

The camo URL is the badge's `src` in the README's HTML on GitHub; it
can be found with
`curl -sS https://github.com/nukopian/DBIx-Squirrel | grep -o 'https://camo.githubusercontent.com/[^"]*'`.

DBIx-Squirrel's README has the same badge, from `minil.toml`'s
`metacpan` badge, so its releases will lag the same way. Ekorn added
the fix as an idea, its roadmap 2026-0009: a shields.io CPAN badge,
which caches for hours, written in `README.pod` as the Kwalitee badge
is, in place of Minilla's. What might be done here: the same, whether
as an idea of DBIx-Squirrel's own or alongside Ekorn's, as Iain
decides; and until then, a purge after each release.

# Planned work

## 1. Ekorn::Pipeline v0.2.0: two messages change; test, follow, and move the range

**From:** Ekorn-Pipeline's session, 2026-11-09 (Ekorn-Pipeline
c5157c94fa9d65615c1b78bc7673e43dbd8823dd)
**Waiting on:** nothing for the testing and the changes; Ekorn-Pipeline
v0.2.0, on CPAN, for `cpanfile` and bringing them to `develop`

**Progress, 2026-11-09:** steps 1, 2 and 4 are done, on
`experiment/2026-0006-ekorn-v0.2.0-messages`; step 6 has nothing to
do, as the tests ran against Ekorn's working copy. Steps 3 and 5 wait
on v0.2.0. Its record is
`docs/changes/2026-0006-ekorn-v0.2.0-messages.md`.

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

## 2. Ekorn::Pipeline v0.2.0 is on CPAN: raise the range, and merge

**From:** Ekorn-Pipeline's session, 2026-11-09 (Ekorn-Pipeline
a038573e1dae7a0476032e4e6c0697d81b737730, tagged v0.2.0)
**Waiting on:** nothing

**What:** v0.2.0 is on CPAN, released on 2026-11-09 from the tag
`v0.2.0`. PAUSE indexed it at 23:28 UTC, MetaCPAN lists it, and the
mirror has the tarball. It's what this session tested: the two
messages' new wording, and nothing else in behaviour. So task 1's
step 5 can go ahead: raise `cpanfile`'s range for Ekorn::Pipeline to
`>= v0.2.0, < v0.3.0`, regenerate `META.json` and `Build.PL` with
`minil build`, and bring this branch to `develop`. Then remove task
1's worktree (its step 6).

cpanmetadb may lag behind MetaCPAN for a while, as it did for v0.1.3;
cpanm resolves `>= v0.2.0` through MetaCPAN, so CI should install
v0.2.0, and if a run installs v0.1.3, a re-run later fixes it.

**Done when:** `cpanfile` asks for `>= v0.2.0, < v0.3.0`, this branch
is on `develop`, CI passes there, and task 1 is done with this one.
