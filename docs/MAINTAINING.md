# Maintaining

How DBIx-Squirrel is kept: its branches, releases to CPAN, and the git
and GitHub work done by hand.
It's for whoever maintains it, Iain and Claude now. Every command can be
pasted as it stands. The few that need a value say so on the line
before, and set it in a variable on their first line.

[scalar](https://github.com/nukopian/scalar) is kept the same way, and
this guide comes from
[its guide](https://github.com/nukopian/scalar/blob/main/docs/MAINTAINING.md).
What's particular here is Perl: Minilla builds the distribution, and a
release goes to CPAN.

The working copy is `~/Git/github.com/nukopian/DBIx-Squirrel`. Perl
commands run in the project's perlbrew library. It's named on each
command, so they don't depend on the default Perl.
[Iain's Mac](#iains-mac) has the libraries, and how to build a Perl
or the database drivers there.

## Branches

- `develop` is where work happens. Every commit goes there, and CI runs
  on every push to it.
- `main` is the latest release, and nothing else. It moves only when a
  release is made, by a fast-forward to `develop`. The release's tag is
  on it. Visitors to GitHub see `main`, so its README describes what
  CPAN installs.
- There are no feature branches, for now. Changes are made one at a
  time. An experiment may have a branch, named for its roadmap item's
  id, as below.
- `TODO.md`, when there is one, lists work planned for a later session.
  It's committed on `develop` and gone before a release, so it never
  reaches `main`. [CLAUDE.md](../CLAUDE.md#planned-work) has the rules.
- [ROADMAP.md](../ROADMAP.md) lists what the project means to do. Each
  item has an id, such as 2026-0001.
  [docs/changes/](changes/README.md) keeps a record of each planned
  change. Both are public, on `main`, but not in the CPAN tarball.
  [ROADMAP.md](../ROADMAP.md) and
  [docs/changes/](changes/README.md) say how they're kept.
- A branch for a roadmap item, when there is one, is named for its id,
  as `experiment/2026-0001-manuals-on-metacpan`.
- An experimental branch carrying work, if there is one, has its
  `TODO.md` read and worked from, not `develop`'s. There's none now:
  `pipeline-experimental`, which paired with Ekorn-Pipeline's branch of
  the same name, merged into `develop` on 2026-11-13 (2026-0024). The
  tag `archive/pipeline-experimental` keeps its `docs/design/`.

`main` is protected on GitHub. Pushes to it need signed commits, a
linear history (no merge commits) and CI passing on every job. It
can't be force-pushed or deleted. This holds for admins too. To see
the settings:

```sh
gh api repos/nukopian/DBIx-Squirrel/branches/main/protection --jq '{signatures: .required_signatures.enabled, linear: .required_linear_history.enabled, checks: .required_status_checks.contexts, force_push: .allow_force_pushes.enabled, admins: .enforce_admins.enabled}'
```

### A fresh clone

The settings that sign commits are in the working copy's own
`.git/config`, not the global one. So a fresh clone needs them before
its first commit. Then switch to `develop`, and install the
dependencies, the maintainers' tools among them. Install Minilla too,
which builds the distribution. Minilla isn't in `cpanfile`, so that
installing from it shows the distribution needs nothing else:

```sh
cd ~/Git/github.com/nukopian/DBIx-Squirrel
git config user.name nukopian
git config user.email nukopian@users.noreply.github.com
git config user.signingkey /Users/icampbell/.ssh/github_nukopian_noreply_rsa.pub
git config gpg.format ssh
git config gpg.ssh.allowedsignersfile '~/.config/git/allowed_signers'
git config commit.gpgsign true
git fetch origin
git switch develop
git pull --ff-only
perlbrew exec --with perl-5.36.3@dbix-squirrel-2 cpanm --installdeps --with-develop .
perlbrew exec --with perl-5.36.3@dbix-squirrel-2 cpanm Minilla
```

## Every commit

Run these first, and check that each one succeeds. Don't pipe them
through `tail` or `grep` to judge them. The pipe's exit status is the
last command's, and hides a failure. The perltidy loop is CI's style
check. It prints a diff for each file perltidy would change. Both
linters run on Perl 5.44, as CI's style job does: Perl::Critic takes
the Perl's keywords from the Perl it runs on, so an older one can pass
what CI flags.

```sh
cd ~/Git/github.com/nukopian/DBIx-Squirrel
perlbrew exec --with perl-5.36.3@dbix-squirrel-2 yath test -L
perlbrew exec --with perl-5.44.0@dbix-squirrel-2 perlcritic lib
for f in $(git ls-files 'lib/*.pm' 't/*.t' 'xt/*.t'); do perlbrew exec --quiet --with perl-5.44.0@dbix-squirrel-2 perltidy "$f" | diff -u "$f" -; done
```

DBIx::Squirrel's pipeline is Ekorn::Pipeline's. CI installs Ekorn from
CPAN, so it tests what users get. Locally, test against
Ekorn-Pipeline's working copy too, so a change there that breaks
DBIx::Squirrel shows up before Ekorn releases it. Its `lib` goes first
on `PERL5LIB`, which reaches the Perls `xt/examples.t` starts, as yath's
`-I` doesn't:

```sh
cd ~/Git/github.com/nukopian/DBIx-Squirrel
git -C ~/Git/github.com/nukopian/Ekorn-Pipeline log -1 --oneline
perlbrew exec --with perl-5.36.3@dbix-squirrel-2 sh -c 'PERL5LIB=$HOME/Git/github.com/nukopian/Ekorn-Pipeline/lib:$PERL5LIB yath test -L'
```

The first line says which Ekorn commit the run used. A failure only
against the working copy means the two have parted: find which should
change, and if it's Ekorn, tell it in a message in its `TODO.md`.

After a change to the code, check its coverage too, as CI does.
`scripts/coverage` runs the tests under Devel::Cover, from an empty
`cover_db`. It fails if the coverage of `lib/` falls below any of the
floors at its top, and prints each floor with what the tests reached.
New code comes with the tests that keep it above them. When coverage
rises, raise the floors to just under it. Lower one only with the
reason in the commit message.

```sh
perlbrew exec --with perl-5.36.3@dbix-squirrel-2 ~/Git/github.com/nukopian/DBIx-Squirrel/scripts/coverage
```

To see which lines and branches the tests miss, after it has run:

```sh
cd ~/Git/github.com/nukopian/DBIx-Squirrel
perlbrew exec --with perl-5.36.3@dbix-squirrel-2 cover -report text -select_re '^lib/'
```

`Build.PL`, `META.json` and `README.md` are generated. They're
committed so that `cpanm` can install from GitHub. After a change to
`cpanfile`, `minil.toml`, `README.pod` or the main module's POD,
generate them again. Commit what changes with the change that caused
it:

```sh
cd ~/Git/github.com/nukopian/DBIx-Squirrel
perlbrew exec --with perl-5.36.3@dbix-squirrel-2 minil build
git status --short
```

The manuals, `lib/DBIx/Squirrel/Manual/Reference.pod` and
`HowTo.pod`, are generated too. `scripts/manuals` makes them from
`docs/REFERENCE.md` and `docs/HOWTO.md`, so that MetaCPAN lists the
reference and the how-to with the modules (roadmap 2026-0001). After a
change to either, generate them again, and commit them with it.
`xt/manuals.t`, which CI runs, fails if they're not what the Markdown
makes. The script converts only the Markdown the docs use. It refuses
anything else, naming it:

```sh
cd ~/Git/github.com/nukopian/DBIx-Squirrel
perlbrew exec --with perl-5.36.3@dbix-squirrel-2 scripts/manuals
git status --short
```

`xt/spelling.t` checks the POD's spelling as Minilla's release test
does, in CI's coverage job, and locally on Perl 5.36, whose library
has Test::Spellunker. If it flags a word that's right, add it to the
Markdown as `<!-- stopwords: word another -->`, or, in a module, to
its `=for stopwords` line.

Minilla takes the branch in `README.md`'s CI badge from GitHub, with
`git remote show origin`. If GitHub can't be reached, it writes
`master` instead, and the badge breaks. Check that this prints
`branch=main` before committing:

```sh
head -1 ~/Git/github.com/nukopian/DBIx-Squirrel/README.md | grep -o 'branch=[a-z]*'
```

If it prints `branch=master`, put `main` back:

```sh
sed -i '' '1s/branch=master/branch=main/' ~/Git/github.com/nukopian/DBIx-Squirrel/README.md
```

Commits are signed, and use conventional prefixes (`feat:`, `fix:`,
`docs:`, `test:`, `ci:`, `refactor:`, `style:`, `chore:`). They say
why as well as what. To check the signatures of the last ten (`G` is
good, `N` is none):

```sh
git log --format='%h %G? %s' -10
```

Add what changed for users to `Changes` under Unreleased, in the same
commit. A change that ships a roadmap item ends its line with the
item's id, as "(roadmap 2026-0001)". It names the item in the entry's
precis, and takes the item off [ROADMAP.md](../ROADMAP.md).

## A trial release

A trial puts a version on CPAN for CPAN Testers to test, on platforms
CI doesn't cover, such as the BSDs and Solaris. CI has run on Windows
since the v3.0.0 trial failed there. CPAN doesn't index a trial, so
`cpanm DBIx::Squirrel` still installs the last release. PAUSE takes a
tarball whose name ends `-TRIAL` as a trial. That's all Minilla's own
`minil release --trial` does, and `minil dist` has no `--trial`, so we
rename the tarball by hand. The `META.json` inside still says
`"release_status" : "stable"`; PAUSE and MetaCPAN go by the name.
There's no tag and no GitHub release, `main` doesn't move, and
`Changes` keeps its Unreleased heading. v2.0.0 had a trial, uploaded
on 2026-11-05, v2.0.1 and v2.0.2 one each, on 2026-11-06, v2.1.0 one
on 2026-11-10, and v3.0.0, v3.0.1 and v3.0.2 one each, on 2026-11-14.

PAUSE never takes the same file name twice. So each trial has a
version of its own, and the release takes the version of its last
trial. A change to code or tests after a trial moves the version on.
Gather changed the pipeline after v2.0.0's trial, so the next trial
was v2.0.1. List placeholders came after that one, so the next, and
the release, were v2.0.2. v3.0.0's trial failed to install over
v2.1.0, and v3.0.1's on Windows, so the release was v3.0.2. Don't use
an underscore version, such as `v2.0.0_1`, for a trial of v2.0.0.
`version.pm` reads it as v2.0.1, so it would rank above the release
it was a trial of.

The commands below are for v3.0.2's trial. For another version,
change the first line of each.

1. **Check `develop`,** as in step 1 of
   [Making a release](#making-a-release), with the working tree clean.
   Then the tarball is built from a commit CI has passed. Unlike a
   release, a trial doesn't wait for `TODO.md` to go, as `minil.toml`
   leaves it out of the tarball. But a task that changes code is done
   first, or the trial tests something other than what's released.

2. **Set the version,** unless the main module has it already: for a
   new version's first trial, as v3.0.0's was set from v2.1.0, and for
   each trial after one already on PAUSE. `minil prepare` writes it
   into the main module, and regenerates `META.json`:

   ```sh
   v=v3.0.2
   cd ~/Git/github.com/nukopian/DBIx-Squirrel
   perlbrew exec --with perl-5.36.3@dbix-squirrel-2 minil prepare "$v" </dev/null
   git status --short
   ```

   Commit what changed as `chore: version v3.0.2, for a trial`, with
   the version, push, and wait for CI to pass on the commit before
   going on.

3. **Build the tarball, and check it.** `--skip-prepare` builds from
   the files as committed, as a release does from its tag:

   ```sh
   v=v3.0.2
   cd ~/Git/github.com/nukopian/DBIx-Squirrel
   perlbrew exec --with perl-5.36.3@dbix-squirrel-2 minil dist --skip-prepare > "$TMPDIR/dist-$v.log" 2>&1
   grep '^Result:' "$TMPDIR/dist-$v.log"
   tar -xOzf "DBIx-Squirrel-$v.tar.gz" "DBIx-Squirrel-$v/META.json" | jq -r .version
   tar -tzf "DBIx-Squirrel-$v.tar.gz" | grep -E "^DBIx-Squirrel-$v/(CLAUDE|ROADMAP|TODO|docs/|logo/|scripts/)"
   git status --short
   ```

   It must print `Result: PASS`, then the version, and nothing after:
   `minil dist` exits 0, and writes the tarball, even when the tests
   fail; no maintainers' file, nor the README's logos, goes in the
   tarball; and git ignores the tarball. On a failure, remove the
   tarball, fix the problem on `develop`, and start again.

   The build also runs Minilla's own tests, which CI doesn't, among
   them a POD spelling test. It caught "bitwise" before v3.0.0's
   build, and "21st" only after v3.4.0's tag. `xt/spelling.t` now runs
   the same check in CI, and a word it doesn't know, but that's right,
   goes where the note on the manuals in
   [Every commit](#every-commit) says.

4. **Test it over the last release.** Installing never removes a
   file, so code that relies on a module being gone can fail for
   someone upgrading, where CI and CPAN Testers, in fresh
   environments, don't see it. v3.0.0's trial failed that way, over
   v2.1.0's `DBIx::Squirrel::Pipeline`. So run the tarball's tests in
   a library that has the last release installed, such as Iain's
   `perl-5.36.3@jdc-lab`. `--test-only` tests without installing:

   ```sh
   v=v3.0.2
   cd ~/Git/github.com/nukopian/DBIx-Squirrel
   perlbrew exec --with perl-5.36.3@jdc-lab perl -MDBIx::Squirrel -e 'print "installed: $DBIx::Squirrel::VERSION\n"'
   perlbrew exec --with perl-5.36.3@jdc-lab cpanm --test-only "./DBIx-Squirrel-$v.tar.gz"
   ```

   It must end `Successfully tested`.

5. **Rename it, and upload it.** `cpan-upload` reads the PAUSE account
   from `~/.pause`:

   ```sh
   v=v3.0.2
   cd ~/Git/github.com/nukopian/DBIx-Squirrel
   mv "DBIx-Squirrel-$v.tar.gz" "DBIx-Squirrel-$v-TRIAL.tar.gz"
   perlbrew exec --with perl-5.36.3@dbix-squirrel-2 cpan-upload "DBIx-Squirrel-$v-TRIAL.tar.gz"
   rm "DBIx-Squirrel-$v-TRIAL.tar.gz"
   ```

6. **Check that CPAN has it, as a trial.** PAUSE emails when it has
   the upload. MetaCPAN lists it within minutes, and `developer` says
   it's a trial:

   ```sh
   curl -sSf https://fastapi.metacpan.org/v1/release/versions/DBIx-Squirrel | jq -r '.releases[] | "\(.name) \(.maturity) \(.status) \(.date)"' | head -3
   ```

   The first line should name the trial, with `developer cpan`, and
   the last release should still say `latest`.

7. **Read the reports,** as they come in over the next few days, most
   within the hour. The first command counts each version's reports
   by grade. The second lists every report that didn't pass, of any
   version, with a link to each:

   ```sh
   curl -sSf https://api.cpantesters.org/v3/summary/DBIx-Squirrel | jq -r 'group_by(.version)[] | group_by(.grade)[] | "\(.[0].version) \(.[0].grade): \(length)"'
   curl -sSf https://api.cpantesters.org/v3/summary/DBIx-Squirrel | jq -r '.[] | select(.grade != "pass") | "\(.version) \(.grade) \(.osname) perl \(.perl) https://www.cpantesters.org/cpan/report/\(.guid)"'
   ```

   A failure is fixed on `develop` before the release, and a new trial
   uploaded, with a version of its own. An `na` from a Perl older than
   5.36 is expected, and needs nothing. Windows' testers report too:
   v3.0.0's failed on Perl 5.36.3 and 5.42.3 within twenty minutes.

## Making a release

A release is a version on CPAN, and a signed, annotated tag on `main`,
with a GitHub release for it. Versions are dotted, as `v2.0.0`. That
goes for the main module's `$VERSION`, the tag and the tarball's name
alike. Claude asks before tagging.

Releases don't use `minil release`. It makes its own commit and an
unsigned tag, and pushes both. `minil prepare` sets the version, and
`minil dist` builds the tarball. The git steps are ours.

1. **Check `develop`:** CI is green on its last commit, there's no
   `TODO.md`, and the history has no secrets.

   ```sh
   cd ~/Git/github.com/nukopian/DBIx-Squirrel
   git switch develop
   git pull --ff-only
   gh run list --branch develop --limit 1
   if [ -e TODO.md ]; then cat TODO.md; else echo "no TODO.md"; fi
   betterleaks git --redact --no-banner .
   ```

   If `TODO.md` is there, its tasks come first. Do them, or move them
   where CLAUDE.md says. Delete the file before going on.

2. **Set the version.** `minil prepare` writes it into the main module.
   It also regenerates `META.json`, `Build.PL` and `README.md`. Set the
   version on the first line:

   ```sh
   v=v3.0.2
   cd ~/Git/github.com/nukopian/DBIx-Squirrel
   perlbrew exec --with perl-5.36.3@dbix-squirrel-2 minil prepare "$v" </dev/null
   git status --short
   ```

   After a trial, the main module has its version already, so this
   changes nothing, and `git status` prints nothing.

3. **Turn Unreleased into the release** in [Changes](../Changes):
   - Rename the heading to the version and date, as
     `v3.0.2 2026-11-14`.
   - Start the entry with a sentence that sums it up. It becomes the
     tag's title.
   - Follow it with the precis of the roadmap items it ships, by id.
   - Add an empty Unreleased above it.

   Each shipped item's record says "shipped in" the version. The
   entry's lines stay indented by four spaces:

   ```text
   Unreleased

   v3.0.2 2026-11-14

       Version 3: a statement is a source for Ekorn::Pipeline, and a sink
       given last turns it into a result.

       - Requires Ekorn::Pipeline v0.3.0 or later, below v0.4.0.
   ```

   Commit it with the version (`chore: release v3.0.2`), push, and wait
   for CI.

   Then build the tarball from `develop`, as step 6 will from the tag,
   and check it passes, before anything is tagged. `minil dist` runs
   release tests that CI doesn't, as Minilla writes them only into the
   tarball it builds, and a tag, once pushed, can't be taken back.
   v3.4.0's reference failed Minilla's POD spelling test here, on
   "21st", after its tag. `xt/spelling.t` now runs that check in CI,
   but this catches anything else of Minilla's. Set the version on the
   first line:

   ```sh
   v=v3.0.2
   cd ~/Git/github.com/nukopian/DBIx-Squirrel
   perlbrew exec --with perl-5.36.3@dbix-squirrel-2 minil dist --skip-prepare > "$TMPDIR/dist-$v.log" 2>&1
   grep '^Result:' "$TMPDIR/dist-$v.log"
   rm "DBIx-Squirrel-$v.tar.gz"
   ```

   It must print `Result: PASS`, as in step 6. On a failure, fix it on
   `develop`, and push; the version isn't spent, as nothing is tagged
   or uploaded.

4. **Write the tag message from the entry,** and read it. The entry,
   without its indent, is also the GitHub release's notes. The tag
   message is the same, with the version in front. An empty file means
   the heading doesn't match the version. Set the version on the first
   line:

   ```sh
   v=v3.0.2
   cd ~/Git/github.com/nukopian/DBIx-Squirrel
   v=$v perl -0777 -ne 'print "$1\n" =~ s/^    //mgr if /^\Q$ENV{v}\E [^\n]*\n\n(.*?)\n*(?=^\S|\z)/ms' Changes > "$TMPDIR/notes-$v.txt"
   sed "1s/^/$v: /" "$TMPDIR/notes-$v.txt" > "$TMPDIR/tag-$v.txt"
   perl -pi -e 's( (?<! [`\w] ) ( \@ [A-Za-z] [\w-]* ) )(`$1`)xg' "$TMPDIR/notes-$v.txt"
   cat "$TMPDIR/tag-$v.txt"
   grep -n '@' "$TMPDIR/notes-$v.txt"
   ```

   The third line puts each `@name` in the notes in backticks, after
   the tag message is made from them, which stays plain text. GitHub
   reads a bare `@name` in a release's notes as a mention: it lists
   that account among the release's contributors, and notifies it.
   Perl in an entry, such as `tee(@stages)`, would name a real
   account. An `@` after a letter or digit, as in an email address or
   `DBIx::Squirrel@2.1.0`, is left alone, as is one in `@{...}` or
   `@$it`. The last line shows each `@` left in the notes: read it.
   After the release, step 5 checks it has no mentions.

5. **Move `main` and tag it.** First check `develop` once more, as
   another session may have sent a task or a message since step 1, as
   one did during Ekorn-Pipeline's v0.4.2. Pull it, and check there's
   still no `TODO.md`, and that its last commit is the release's:

   ```sh
   cd ~/Git/github.com/nukopian/DBIx-Squirrel
   git switch develop
   git pull --ff-only
   if [ -e TODO.md ]; then cat TODO.md; else echo "no TODO.md"; fi
   git log -1 --format='%H %s'
   ```

   If `TODO.md` is back, `main` doesn't move: its tasks come first, as
   in step 1, and the release goes on from the commit that deletes it,
   once CI is green there. Then check that every check run on the
   commit has completed successfully. `gh run watch` can report a run
   as passed while one of its jobs is still marked in progress, and
   `main`'s protection refuses the push until it isn't. Each check is
   listed once, from `develop`'s push:

   ```sh
   cd ~/Git/github.com/nukopian/DBIx-Squirrel
   gh api "repos/nukopian/DBIx-Squirrel/commits/$(git rev-parse develop)/check-runs" --jq '.check_runs[] | "\(.name) \(.status) \(.conclusion)"'
   ```

   Every line ends `completed success`. If one doesn't, see
   [When something goes wrong](#when-something-goes-wrong). Then
   merge. The merge is a fast-forward, so `main` gets exactly the
   commits CI tested on `develop`, with their signatures. Set the
   version on the first line:

   ```sh
   v=v3.0.2
   git switch main
   git pull --ff-only
   git merge --ff-only develop
   git tag -s "$v" -F "$TMPDIR/tag-$v.txt"
   git push origin main "$v"
   gh release create "$v" --verify-tag --title "$(git tag -l --format='%(contents:subject)' "$v")" --notes-file "$TMPDIR/notes-$v.txt"
   gh api "repos/nukopian/DBIx-Squirrel/releases/tags/$v" --jq '.mentions_count // 0'
   git switch develop
   ```

   The `gh api` line prints how many accounts the notes mention. It
   must print 0. If not, edit the release's notes on GitHub, putting
   each `@name` in backticks.

   `--verify-tag` refuses to make a tag of its own if the push didn't
   happen. If the merge says it can't fast-forward, `main` has a commit
   `develop` doesn't. Stop and find out why. Don't make a merge commit.

6. **Build the tarball and upload it to CPAN,** from the tag.
   `minil dist` runs the tests again on the built distribution first.
   `cpan-upload` reads the PAUSE account from `~/.pause`. Set the version
   on the first line:

   ```sh
   v=v3.0.2
   cd ~/Git/github.com/nukopian/DBIx-Squirrel
   git switch --detach "$v"
   perlbrew exec --with perl-5.36.3@dbix-squirrel-2 minil dist --skip-prepare > "$TMPDIR/dist-$v.log" 2>&1
   grep '^Result:' "$TMPDIR/dist-$v.log"
   tar -xOzf "DBIx-Squirrel-$v.tar.gz" "DBIx-Squirrel-$v/META.json" | jq -r .version
   tar -tzf "DBIx-Squirrel-$v.tar.gz" | grep -E "^DBIx-Squirrel-$v/(CLAUDE|ROADMAP|TODO|docs/|logo/|scripts/)"
   ```

   It must print `Result: PASS`, then the version, and nothing after,
   as for a trial. `minil dist` exits 0, and writes the tarball, even
   when the tests fail. So read this line, not its exit status. On a
   failure, the log says which test failed. Remove the tarball, fix it
   on `develop`, and start again. Then upload:

   ```sh
   v=v3.0.2
   cd ~/Git/github.com/nukopian/DBIx-Squirrel
   perlbrew exec --with perl-5.36.3@dbix-squirrel-2 cpan-upload "DBIx-Squirrel-$v.tar.gz"
   git switch develop
   rm "DBIx-Squirrel-$v.tar.gz"
   ```

7. **Check that CPAN has it.** PAUSE emails when it has indexed the
   upload, usually within the hour. Then MetaCPAN shows the new version,
   with the repository's URL:

   ```sh
   curl -sSf https://fastapi.metacpan.org/v1/release/DBIx-Squirrel | jq -r '"\(.name) \(.date) \(.resources.repository.web)"'
   ```

## The name

The repository was DBIx-Squirrel-2 while version 2 was in development.
It took the name DBIx-Squirrel on 2026-11-08, before its first
release, so that release's metadata names the final URL. Minilla takes
the repository's URL in `META.json`, and the CI badge in `README.md`,
from `origin`. The name DBIx-Squirrel had redirected to the archived
DBIx-Squirrel-1. That's how CPAN's links for 1.6.5 reached it. The
rename ended that, as intended.

GitHub now redirects DBIx-Squirrel-2 here. Never create anything at
`github.com/nukopian/DBIx-Squirrel-2`, which would end that redirect.
The perlbrew libraries keep their name, as `perl-5.36.3@dbix-squirrel-2`.

## Changing the CI matrix

`main` requires each CI job by its name, as `perl 5.44 (ubuntu-24.04)`. So
a new Perl, or a new runner, means changing the required checks to
match. Otherwise `main` waits for a check that never reports, and
can't move. After the new jobs have passed once on `develop`, change
the list here to the jobs' names, and run it. It replaces the whole
list, so `secrets`, `style` and `coverage` stay in it. It's a GitHub
setting, so Iain runs it, or says Claude may:

```sh
gh api --method PATCH repos/nukopian/DBIx-Squirrel/branches/main/protection/required_status_checks --silent --input - <<'EOF'
{
  "strict": false,
  "checks": [
    {"context": "secrets", "app_id": 15368},
    {"context": "perl 5.36 (ubuntu-24.04)", "app_id": 15368},
    {"context": "perl 5.38 (ubuntu-24.04)", "app_id": 15368},
    {"context": "perl 5.40 (ubuntu-24.04)", "app_id": 15368},
    {"context": "perl 5.42 (ubuntu-24.04)", "app_id": 15368},
    {"context": "perl 5.44 (ubuntu-24.04)", "app_id": 15368},
    {"context": "perl 5.36 (windows-2025)", "app_id": 15368},
    {"context": "perl 5.42 (windows-2025)", "app_id": 15368},
    {"context": "perl 5.36, DBI 1.643 (ubuntu-24.04)", "app_id": 15368},
    {"context": "style", "app_id": 15368},
    {"context": "coverage", "app_id": 15368}
  ]
}
EOF
gh api repos/nukopian/DBIx-Squirrel/branches/main/protection --jq .required_status_checks.contexts
```

`15368` is GitHub Actions, so only a job of this repository's
workflows can satisfy a check. When the floor moves up, from Perl 5.36
to 5.40 for `try`/`catch`, the oldest jobs go, from the matrix and this
list alike. The job on DBI 1.643 moves to the new floor. When Debian's
and Ubuntu's DBI moves on, so does that job's.

## CI's caches

The Linux jobs, but the one on DBI 1.643, have their modules
installed by actions-setup-perl, into `local/`, which it caches
(roadmap 2026-0033). The cache is keyed on the Perl, `cpanfile`,
cpanm's arguments and the modules named, and once made it isn't
updated: a job keeps the versions it first installed until `cpanfile`
changes. A job with no cache of its own key, as after a change to
`cpanfile`, restores the newest made on the same Perl, whichever job
made it, and installs what it lacks on top: so the test jobs may have
the coverage or style job's modules too. The `minimal` job, which must
have only the required modules, isn't cached (2026-0064).
Ekorn::Pipeline is the exception to keeping versions: each job
reinstalls the newest version in `cpanfile`'s range, so CI tests the
release users get. That newest comes from cpanmetadb's history of the module, which
can lag behind the rest of CPAN's indexes by an hour or more after a
release: a run in that time installs the version before.

To test against the newest of everything, delete the caches, and run
CI again. The next run makes them afresh:

```sh
cd ~/Git/github.com/nukopian/DBIx-Squirrel
gh cache list
gh cache delete --all
gh run rerun "$(gh run list --branch develop --limit 1 --json databaseId --jq '.[0].databaseId')"
```

## When something goes wrong

- **A bad commit pushed to `develop`:** fix it in a new commit, or
  revert it with `git revert`, and push. Don't force-push. Iain reviews
  what's pushed, and a rewrite moves it under him.
- **A mistake in a pushed commit message:** leave it, and correct it in
  the next release's entry in `Changes`.
- **A bad release:** never move or delete a published tag, and never
  reuse a version. PAUSE refuses a file name it has had before, even one
  deleted since. Release a fixed version instead. To keep the bad one
  from being installed meanwhile, delete it from CPAN on PAUSE
  (`https://pause.perl.org`, "Delete Files"). It goes after three days,
  and stays on BackPAN.
- **An upload refused or lost:** if PAUSE never had the file, run
  `cpan-upload` again with the same tarball. If it did, the version is
  spent. Release the next one.
- **`cpan-upload --dry-run` prints the PAUSE password,** with or without
  `--verbose`. Don't run it where the output is shared or logged.
- **A commit made on `main` by mistake,** before it's pushed: move it
  to `develop`, and put `main` back. Do this only if `main` hasn't been
  pushed since:

  ```sh
  git switch develop
  git cherry-pick main
  git branch -f main origin/main
  ```

- **A push to `main` refused:** the protection did its job. Push to
  `develop` instead, or, at a release, wait for CI to pass on the commit.
- **A check stuck "in progress"** after all its steps passed: GitHub
  never marked it complete. Re-run that job alone. This finds every
  unfinished check on `develop`'s commit, and re-runs it:

  ```sh
  cd ~/Git/github.com/nukopian/DBIx-Squirrel
  gh api "repos/nukopian/DBIx-Squirrel/commits/$(git rev-parse develop)/check-runs" --jq '.check_runs[] | select(.status != "completed") | .details_url' | sed -E 's|.*/runs/([0-9]+)/job/([0-9]+).*|\1 \2|' | while read run job; do gh run rerun "$run" --job "$job"; done
  ```

  Then check the check runs again, as in step 5.
- **`main` refused after the tag went up:** `git push origin main "$v"`
  sends both, so the tag can be published while `main` is refused.
  Leave the tag unchanged. It points at the right commit. Fix the
  check, then push `main` to the tagged commit, make the release, and
  go on with step 6. Set the version on the first line:

  ```sh
  v=v3.0.2
  cd ~/Git/github.com/nukopian/DBIx-Squirrel
  git switch main
  git merge --ff-only "$v"
  git push origin main
  gh release create "$v" --verify-tag --title "$(git tag -l --format='%(contents:subject)' "$v")" --notes-file "$TMPDIR/notes-$v.txt"
  gh api "repos/nukopian/DBIx-Squirrel/releases/tags/$v" --jq '.mentions_count // 0'
  git switch develop
  ```

## Security checks

- **betterleaks**, gitleaks' successor, scans the whole history for
  secrets on every push, in `test.yml`'s `secrets` job, and by hand
  before a tag (step 1). It reads `.gitleaksignore`, whose name is kept.
- **Secret scanning and push protection** are on. Push protection
  refuses a push with a recognised secret in it, before betterleaks
  would see it.
- **Dependabot alerts** are on, and **Dependabot security updates** are
  off on purpose. They'd open pull requests against `main`, which moves
  only at a release. Dependabot doesn't read a `cpanfile`, so its alerts
  cover the workflow's actions, not the Perl dependencies.

To see the settings, and any open alerts:

```sh
gh api repos/nukopian/DBIx-Squirrel --jq '.security_and_analysis | to_entries[] | "\(.key) \(.value.status)"'
gh api repos/nukopian/DBIx-Squirrel/vulnerability-alerts --silent && echo "Dependabot alerts on"
gh api repos/nukopian/DBIx-Squirrel/dependabot/alerts --jq '.[] | select(.state == "open") | "\(.number) \(.security_advisory.summary)"'
gh api repos/nukopian/DBIx-Squirrel/secret-scanning/alerts --jq '.[] | select(.state == "open") | "\(.number) \(.secret_type_display_name)"'
```

## Tools

- The project's perlbrew library, with Minilla and the dependencies in
  `cpanfile` (yath, Perl::Critic, Perl::Tidy, CPAN::Uploader and
  Pod::Markdown::Github, which writes README.md's code in fences,
  among them);
- `gh`, `betterleaks` and `jq`;
- for the PDFs, `pandoc` and Prince.

`scripts/readme-pdf.sh` builds a PDF of the README, the reference, the
how-to and this guide, for reading offline. The PDFs are git-ignored.

## Iain's Mac

What worked for building Perls and the drivers on Iain's Mac, kept here
for when it's needed again.

### The perlbrew libraries

Each Perl CI covers has a library of the project's own, with the
cpanfile's runtime, test and develop modules, made on 2026-11-05:
`perl-5.36.3@dbix-squirrel-2`, `perl-5.38.5@dbix-squirrel-2`,
`perl-5.40.5@dbix-squirrel-2`, `perl-5.42.3@dbix-squirrel-2` and
`perl-5.44.0@dbix-squirrel-2`. The 5.36 library has the day-to-day
tools: Minilla, CPAN::Uploader, Data::Dump, Perl::Critic, Perl::Tidy,
yath with its helpers (Cpanel::JSON::XS, JSON::MaybeXS,
Term::ANSIColor, IO::Pager, Email::Stuffer), Test2's optional plugins
(Cover, IOEvents, DBIProfile, NoWarnings, MemUsage, UUID),
Test2::Tools::Explain, Devel::Cover and Devel::NYTProf. The 5.44
library has the two linters too.

### Building a Perl

On macOS 27.2, with Apple clang 21 and the macOS 27.2 SDK, a plain
`perlbrew install` works: Perl 5.44.0 built that way on 2026-11-05.

On macOS 26.7 with Xcode 27.1, every new Perl stopped at "Failed to
build miniperl", with a segmentation fault, whatever the optimisation.
Building against the older SDK worked, and is what to try if that ever
comes back. XS modules installed with `cpanm` needed neither variable:

```sh
SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk MACOSX_DEPLOYMENT_TARGET=26.0 perlbrew install perl-5.42.3 --notest
```

### Net::SSLeay and OpenSSL 4

Homebrew's `openssl` is OpenSSL 4, which made `ASN1_TIME` opaque, and
Net::SSLeay 1.96 (which IO::Socket::SSL, and so `cpanm` over HTTPS,
needs) fails against it with "incomplete definition of type
'ASN1_TIME'". Point it at Homebrew's OpenSSL 3 instead, until a
Net::SSLeay release supports 4:

```sh
perlbrew exec --with perl-5.36.3@dbix-squirrel-2 sh -c 'OPENSSL_PREFIX=/opt/homebrew/opt/openssl@3 cpanm IO::Socket::SSL'
```

### DBD::mysql and DBD::Pg

Each is built so that every library in one Perl process uses OpenSSL 3.

DBD::mysql builds against Oracle's MySQL 8.4 in `/usr/local/mysql`.
MySQL's bundled OpenSSL libraries record bare install names, so
DBD::mysql's library check can't run against them; and MakeMaker joins
rpaths with colons, which macOS reads as one directory. So take
OpenSSL from Homebrew's `openssl@3`, and add the rpath through
`LDDLFLAGS`, starting from Perl's own. `-Wl,-rpath` can't go in
`--libs`, as Devel::CheckLib's check fails on it:

```sh
F=$(perlbrew exec --quiet --with perl-5.36.3@dbix-squirrel-2 perl -MConfig -e 'print $Config{lddlflags}')
perlbrew exec --with perl-5.36.3@dbix-squirrel-2 cpanm --configure-args="--libs='-L/opt/homebrew/opt/openssl@3/lib -L/usr/local/mysql/lib -lmysqlclient -lssl -lcrypto -lresolv' LDDLFLAGS='$F -Wl,-rpath,/usr/local/mysql/lib'" DBD::mysql
```

DBD::Pg builds against Postgres.app's `libpq`, not Homebrew's
PostgreSQL 18, whose `libpq` links to OpenSSL 4. It links to that
`libpq` by full path, so Postgres.app must stay installed:

```sh
A=/Applications/Postgres.app/Contents/Versions/latest
POSTGRES_HOME=$A PATH=$A/bin:$PATH perlbrew exec --with perl-5.36.3@dbix-squirrel-2 cpanm DBD::Pg
```

### The test databases

Each server has a test account that reaches only its own database,
`dbix_squirrel_test`: `dbix_squirrel@localhost` on MySQL 8.4, whose
password is in `~/.config/dbix-squirrel/my.cnf` (mode 600, never in
the repository), and the role `dbix_squirrel` on Postgres.app's
PostgreSQL 18, which trusts local connections. `mysql
--login-path=root` is root, for setting up accounts, not for tests. To
run every test against both:

```sh
export DBIX_SQUIRREL_TEST_MYSQL="dbi:mysql:mysql_read_default_file=${HOME}/.config/dbix-squirrel/my.cnf;mysql_read_default_group=dbix_squirrel"
export DBIX_SQUIRREL_TEST_PG='dbi:Pg:dbname=dbix_squirrel_test;host=localhost;user=dbix_squirrel'
cd ~/Git/github.com/nukopian/DBIx-Squirrel
perlbrew exec --with perl-5.36.3@dbix-squirrel-2 yath test -L
```
