# Working on DBIx-Squirrel

These are the working rules for this repository. DBIx-Squirrel is Iain
Campbell's: much of it starts from his code for version 1, which he and
Claude bring over and improve together, and Claude reviews what he
writes by hand. The rules below say who does what. Each rule comes with
the reason for it.

What DBIx-Squirrel means to do is in [ROADMAP.md](ROADMAP.md), and
the decisions each item waits on in its record, in
[docs/changes/](docs/changes/README.md).
How the repository is kept, from every commit to a release on CPAN, is in
[docs/MAINTAINING.md](docs/MAINTAINING.md), with commands to paste.

## What DBIx-Squirrel is for

DBI, minus the boilerplate, plus a pipeline. It keeps you writing SQL, as
the DBI does, and takes away the friction around it: placeholders in any
of the common styles, iterators over results, and a pipeline of
transformations declared beside the query. A stage of the pipeline can
change a row (map), drop it by returning nothing (filter), or return
several values (flatMap). The pipeline is the core of the design.

It subclasses the DBI, so everything the DBI does still works. Where
DBIx-Squirrel and plain DBI do the same thing, they should give the same
result: plain DBI is the baseline, as Perl is for scalar.

## Who does what

- **The code is a two-way process.** Iain writes some by hand, and
  Claude reviews it, suggests, and explains. Where Iain asks, Claude
  writes code too, often bringing his version 1 code over and improving
  it, and Iain reviews that. Claude doesn't change code it wasn't asked
  to.
- **Claude helps with the Git Ops and the repository's setup:** branches,
  CI, releases, and the files around the code. Ask before changing
  anything on GitHub.
- **Tests and documentation,** where Iain asks: the pipeline's spec as
  tests, the edge cases of placeholder rewriting, tests comparing
  results with plain DBI, and keeping the POD, README and `Changes` up to
  date with the code.
- **Commit messages:** Claude drafts them when asked, for Iain's commits
  as well as its own.

Why: DBIx-Squirrel is a tool Iain uses, so it matters most that it's
right. His version 1 code has the design and many of the holes, and
moving it over is a good place for AI to save labour and check the work,
with Iain reviewing each change, as Claude reviews his.

## Credit

- Iain's commits carry no `Co-Authored-By` trailer, even when Claude
  drafted the message.
- Commits Claude wrote, such as code, CI, setup files, tests or docs
  written at Iain's request, end with a trailer for the Claude model that wrote
  them, currently
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- The README's Acknowledgements say what Claude did. Keep them accurate.
- **On CPAN, Iain is `Iain Campbell <cpanic@cpan.org>`,** and no other
  address goes in the distribution: the main module's AUTHOR and so
  `META.json`. Commits use his GitHub noreply address, which GitHub
  needs to verify their signatures, so `.mailmap` maps it to the CPAN
  one. Minilla reads authors through it, and would otherwise list Iain
  as a contributor to his own distribution.

Why: credit goes where the work was done, so a reader can see exactly
what was Iain's.

## Perl

- **Perl 5.36 or later.** Modules start `use v5.36`, which gives strict,
  warnings, `say` and signatures. `try`/`catch` is still experimental
  in 5.36, and is used anyway, as decided on 2026-10-28: a module that
  needs it adds `use experimental qw(try);`, which also allows
  `finally`. Once the floor reaches 5.40, `use v5.40` turns on
  `try`/`catch` by itself, and the line is needed only for `finally`.
  `builtin::` functions are experimental in 5.36 too, and are used the
  same way, as decided on 2026-11-04, in place of Scalar::Util: a
  module adds `use experimental qw(builtin);` and imports what it needs,
  such as `use builtin qw(weaken);`. Only functions stable in 5.40 are
  used, so that once the floor reaches 5.40, `use v5.40` imports them,
  and both lines go. CI tests from the floor to the newest Perl.
- **Minilla** builds and releases the distribution. It's opinionated,
  and that's why it was chosen over Dist::Zilla, whose configuration is
  a tax on an occasional release: the repository is the distribution,
  with the `Build.PL` and `META.json` it generates committed and a
  `cpanfile` listing the dependencies, so CI and `cpanm` from GitHub
  need nothing else. Follow its conventions rather than work around
  them. Three settings in `minil.toml` part from its defaults, decided
  on 2026-10-22:
  - **The README is written by hand in `README.pod`.** Minilla always
    writes `README.md` from POD, so it's generated from that file, not
    from the main module. Edit `README.pod`, never `README.md`.
  - **`Changes` keeps its "Unreleased" heading** (`manage_changes =
    false`), edited by hand at a release, rather than `{{$NEXT}}`.
  - **The git steps of a release are ours.** `minil release` makes its
    own commit and an unsigned tag, and pushes both, so releases don't
    use it: `minil prepare VERSION` sets the version, we commit, move
    `main` and sign the tag, `minil dist --skip-prepare` builds the
    tarball, and `cpan-upload` uploads it.
- **The manuals are made from `docs/`.** `scripts/manuals` makes
  `lib/DBIx/Squirrel/Manual/Reference.pod` and `HowTo.pod` from
  `docs/REFERENCE.md` and `docs/HOWTO.md`, so MetaCPAN lists the
  reference and the how-to, as Iain decided on 2026-11-08 (roadmap
  2026-0001). Edit the Markdown and run the script, as with the README,
  never the POD; `xt/manuals.t` fails if they differ.
- Locally, Iain uses perlbrew with a library of the project's own,
  `perl-5.36.3@dbix-squirrel-2`, so its modules don't mix with other
  projects'. Whatever his default Perl is at the time, run commands with
  the library named, so they don't depend on it, and never `perlbrew
  switch` or `use`, which would change his shell:

  ```
  perlbrew exec --with perl-5.36.3@dbix-squirrel-2 yath test
  ```

  Each Perl CI covers has a library of the same name, made on
  2026-11-05 with the cpanfile's runtime, test and develop modules, so
  the tests run across the whole range: `perl-5.38.5@dbix-squirrel-2`,
  `perl-5.40.5@dbix-squirrel-2`, `perl-5.42.3@dbix-squirrel-2` and
  `perl-5.44.0@dbix-squirrel-2`. The tools Iain uses day to day, and
  the extras listed under Tests, are in the 5.36 library.

### Building a new Perl on Iain's Mac

On macOS 27.2, with Apple clang 21 and the macOS 27.2 SDK, a plain
`perlbrew install` works: Perl 5.44.0 built that way on 2026-11-05.

Before that, on macOS 26.7 with Xcode 27.1, every new Perl failed to
build: the build stopped at "Failed to build miniperl", with a
segmentation fault, whatever the optimisation and with or without
`--notest`. Building against the older SDK worked, and is what to try
if that ever comes back:

```
SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk MACOSX_DEPLOYMENT_TARGET=26.0 perlbrew install perl-5.42.3 --notest
```

XS modules installed with `cpanm` needed neither variable, even then.

### Net::SSLeay and OpenSSL 4

Homebrew's `openssl` is now OpenSSL 4, and Net::SSLeay (which
IO::Socket::SSL, and so `cpanm` over HTTPS, needs) doesn't build against
it yet: OpenSSL 4 made `ASN1_TIME` opaque, and Net::SSLeay 1.96 fails
with "incomplete definition of type 'ASN1_TIME'". Point it at Homebrew's
OpenSSL 3 instead:

```
perlbrew exec --with perl-5.36.3@dbix-squirrel-2 sh -c 'OPENSSL_PREFIX=/opt/homebrew/opt/openssl@3 cpanm IO::Socket::SSL'
```

That built Net::SSLeay 1.96 and IO::Socket::SSL 2.099 against OpenSSL
3.5.9 on 2026-10-22, and a TLS connection to metacpan verified its
certificate. Drop the prefix once a Net::SSLeay release supports
OpenSSL 4.

### DBD::mysql and DBD::Pg

Both build against client libraries outside Perl, and on Iain's Mac each
needs telling which, so that every library in one Perl process uses
OpenSSL 3 (built 2026-10-22: DBD::mysql 5.014, DBD::Pg 3.21.2, and with
DBD::SQLite and IO::Socket::SSL they all load in one process, with TLS
still verifying).

**DBD::mysql** builds against MySQL 8.4.13, Oracle's package in
`/usr/local/mysql`, whose `mysql_config` is on the PATH. Two things
break a plain `cpanm DBD::mysql`: MySQL's bundled `libssl.3.dylib` and
`libcrypto.3.dylib` record bare filenames as their install names, so
DBD::mysql's library check can't run against them; and MakeMaker joins
rpaths with colons, as on Linux, which macOS reads as one directory, so
`@rpath/libmysqlclient.24.dylib` isn't found. So take OpenSSL from
Homebrew's `openssl@3` (the same 3.5.9 that MySQL bundles), and add the
rpath through `LDDLFLAGS`, starting from Perl's own:

```
F=$(perlbrew exec --quiet --with perl-5.36.3@dbix-squirrel-2 perl -MConfig -e 'print $Config{lddlflags}')
perlbrew exec --with perl-5.36.3@dbix-squirrel-2 cpanm --configure-args="--libs='-L/opt/homebrew/opt/openssl@3/lib -L/usr/local/mysql/lib -lmysqlclient -lssl -lcrypto -lresolv' LDDLFLAGS='$F -Wl,-rpath,/usr/local/mysql/lib'" DBD::mysql
```

`-Wl,-rpath` can't go in `--libs`: Devel::CheckLib's check fails on it.
Its tests skip without a test database ("no database connection").

**DBD::Pg** builds against Postgres.app's `libpq`, not Homebrew's
PostgreSQL 18, whose `libpq` links to OpenSSL 4:

```
A=/Applications/Postgres.app/Contents/Versions/latest
POSTGRES_HOME=$A PATH=$A/bin:$PATH perlbrew exec --with perl-5.36.3@dbix-squirrel-2 cpanm DBD::Pg
```

Its tests start a temporary cluster of their own with `initdb`, so they
run against a real server: 1,802 passed. Postgres.app must stay
installed, as DBD::Pg links to its `libpq` by full path.

## Tests

- **Test2::V0, not Test::More,** in every test: `use Test2::V0;`, with
  `is`, `like` and Test2's checks (`T()`, `F()`, `hash`, `array`) for
  structures. Compare values, never Data::Dumper output: a boolean
  dumps as `1` on Perl 5.36 and as `!!1` from 5.38.
- **Test2::Plugin::NoWarnings** in each test file, so a warning fails
  the test that caused it.
- **yath, not prove,** runs them. It adds `lib`, `blib/lib` and
  `blib/arch` itself, and runs files in parallel. With `-L`, it keeps a
  log of the run, in the system's temporary directory, linked from
  `./lastlog.jsonl` (git-ignored), so a failure can be read after it,
  even one that doesn't happen again:

  ```
  perlbrew exec --with perl-5.36.3@dbix-squirrel-2 yath test -L
  perlbrew exec --with perl-5.36.3@dbix-squirrel-2 yath failed lastlog.jsonl
  ```

  The second shows the tests that failed in the last run;
  `yath replay lastlog.jsonl` shows all of it.

- **Locally, test against Ekorn-Pipeline's working copy,** as Iain
  decided on 2026-11-09. DBIx-Squirrel dogfoods Ekorn-Pipeline, so its
  tests should catch a change there before Ekorn releases it, not
  after. Put `~/Git/github.com/nukopian/Ekorn-Pipeline/lib` first on
  `PERL5LIB`, which reaches the subprocesses `xt/howto.t` starts, as
  yath's `-I` doesn't; its manuals' POD is there too, for
  `xt/manuals.t` and `scripts/manuals`:

  ```
  perlbrew exec --with perl-5.36.3@dbix-squirrel-2 sh -c 'PERL5LIB=/Users/icampbell/Git/github.com/nukopian/Ekorn-Pipeline/lib:$PERL5LIB yath test -L'
  ```

  The same `sh -c` wraps `scripts/coverage`, `scripts/manuals`, and the
  other Perls' libraries. Say which Ekorn commit a run used
  (`git -C ~/Git/github.com/nukopian/Ekorn-Pipeline log -1 --oneline`),
  as its working copy may be on any branch, with changes not yet
  committed. CI installs Ekorn from CPAN, within the `cpanfile`'s
  range, so it checks the release DBIx-Squirrel's users get; a run of
  both, where they differ, is the full check. A failure only against
  the working copy means the two have parted: find which side should
  change, and if it's Ekorn's, tell it in a message in its `TODO.md`.

- **Coverage has floors, which it mustn't fall below.**
  `scripts/coverage` runs the tests under Devel::Cover, from an empty
  `cover_db`, and fails if the coverage of `lib/` falls below the floors
  at its top; CI runs it on every push. New code comes with the tests
  that keep coverage above them. Raise a floor when coverage rises, and
  lower one only with the reason in the commit message. The floors are
  set from a run without MySQL or PostgreSQL, as CI has neither.

  ```
  perlbrew exec --with perl-5.36.3@dbix-squirrel-2 scripts/coverage
  perlbrew exec --with perl-5.36.3@dbix-squirrel-2 cover -report text -select_re '^lib/'
  ```

  The second, after the first, shows the lines and branches the tests
  miss.
- The core tests run on DBD::SQLite, so they need no server. Tests
  against MySQL and PostgreSQL (`t/12-mysql.t`, `t/13-pg.t`) are extra,
  and skip unless `DBIX_SQUIRREL_TEST_MYSQL` or `DBIX_SQUIRREL_TEST_PG`
  names a data source; `Test2::Plugin::DBIProfile` can profile the DBI
  calls a test makes.
- Users installing from CPAN run the tests with whatever harness their
  installer uses, so they must pass under `prove` too. yath is the
  maintainers' choice, not a requirement.
- **`xt/` holds the maintainers' tests,** which yath runs with those in
  `t/`, as `.yath.rc` says, and `prove` doesn't. `xt/howto.t` runs the
  examples in `docs/HOWTO.md`, so they can't drift from the code; an
  example needing a server the tests don't have is marked
  `<!-- not run -->` above it.

On Iain's Mac, each server has a test account of its own, set up on
2026-11-04, which can reach only its own database, `dbix_squirrel_test`:
`dbix_squirrel@localhost` on MySQL 8.4, whose password is in
`~/.config/dbix-squirrel/my.cnf` (mode 600, never in the repository),
and the role `dbix_squirrel` on Postgres.app's PostgreSQL 18, which
trusts local connections. To run every test against both:

```
export DBIX_SQUIRREL_TEST_MYSQL="dbi:mysql:mysql_read_default_file=${HOME}/.config/dbix-squirrel/my.cnf;mysql_read_default_group=dbix_squirrel"
export DBIX_SQUIRREL_TEST_PG='dbi:Pg:dbname=dbix_squirrel_test;host=localhost;user=dbix_squirrel'
perlbrew exec --with perl-5.36.3@dbix-squirrel-2 yath test -L
```

Iain's own `mysql --login-path=root` is root on MySQL, for setting up
accounts, not for tests.

The library `perl-5.36.3@dbix-squirrel-2` has Test2::Harness (yath)
1.000180 and the optional extras installed on 2026-10-22: coverage
(Test2::Plugin::Cover, Devel::Cover), Test2::Plugin::IOEvents,
DBIProfile, NoWarnings, MemUsage and UUID, Test2::Tools::Explain, and
yath's suggested helpers (Cpanel::JSON::XS and JSON::MaybeXS for its
logs, Term::ANSIColor, IO::Pager, Email::Stuffer). Devel::NYTProf
6.16, for profiling, joined them on 2026-11-04.

## Style and tools

- **Perl::Tidy** formats the code, with `.perltidyrc` (Iain's, from the
  earlier version 2). It sets `--standard-output`, for editors, so
  `perltidy` prints the result instead of writing a `.tdy` file. To see
  what it would change:

  ```
  perlbrew exec --quiet --with perl-5.36.3@dbix-squirrel-2 perltidy lib/DBIx/Squirrel.pm | diff lib/DBIx/Squirrel.pm -
  ```

- **Perl::Critic** reviews it, with `.perlcriticrc`: severity 3 and up,
  core policies. Its comments say why each excluded policy is excluded;
  `ProhibitVersionStrings` among them, since modules start `use v5.36`.

  ```
  perlbrew exec --with perl-5.36.3@dbix-squirrel-2 perlcritic lib
  ```

- **Data::Dump**'s `pp` is for looking at data while debugging, not for
  the shipped modules or for test expectations (see Tests).
- **`croakf` raises our own errors.** A message DBIx::Squirrel writes is
  raised with `croakf` from DBIx::Squirrel::Errors, a `sprintf` format
  and its arguments, as in `croakf 'Expected a column of the row (%s)',
  $column`, so each message is one plain string, matching its
  DIAGNOSTICS entry. `croak` is for what we pass on: the DBI's own
  messages, which can hold a `%`, and objects, such as a stop. A `%` in
  a message of our own is written `%%`.
- **Two blank lines between subs, or one above a sub's comment.** A sub
  without a comment above it has two blank lines before it, to make the
  gap between subs plain; one with a comment has one, above the
  comment, which marks the gap itself. Perl::Tidy keeps either.
- **Every regex takes the `x` flag** and is written with its operator
  and parentheses: `m( \A \d+ \z )x`, `s( \s+ \z )()xr`, `qr( ... )x`;
  never `/.../`. The whitespace makes a regex easier to read, and the
  operator and parentheses make it read like a function. Under `x`, a
  literal space is `\ ` and a literal `#` is `\#`.

All three are in the project's perlbrew library: Data::Dump 1.25,
Perl::Critic 1.156 and Perl::Tidy 20260826, installed 2026-10-22, when
both profiles were checked against a module with signatures.
CPAN::Uploader 0.103019, for `cpan-upload` at a release, joined them the
same day.

## The name

The repository was DBIx-Squirrel-2 while it was in development, and
was renamed to DBIx-Squirrel on 2026-11-08, before the first release,
so that Minilla, which takes the repository and issues URLs in
`META.json` from the git remote, names the final URL. The perlbrew
libraries keep the name `dbix-squirrel-2`.

**Never create anything at `github.com/nukopian/DBIx-Squirrel-2`**, in
any case: GitHub's names ignore case, and that name now redirects here,
so old links still reach the repository. Anything created there ends
the redirect.

## Planned work

- **At the start of a session, check for `TODO.md`** at the top of the
  repository, on `develop`, and on any experimental branch carrying
  work, which docs/MAINTAINING.md's Branches names. If it's there, read
  it, ask Iain whether each task should still be done, and do the ones
  he confirms. Remove each task in the commit that completes it, so the
  history shows which commit did which, and delete the file with the
  last one. A task he drops is removed too, saying why in the commit
  message.
- **Work planned for a later session goes into `TODO.md`,** committed on
  `develop`, with enough to do it cold: what, why, the files involved,
  and how to check it's done. Not only in Claude's memory or the chat,
  which Iain can't review and a fresh session may not have.
- **`TODO.md`'s tasks and messages are the only way the two sessions
  talk.** Now that DBIx-Squirrel and Ekorn-Pipeline are separate,
  DBIx-Squirrel dogfoods Ekorn-Pipeline, as its first user, and what
  this session finds using it matters most: friction, a gap, a clumsy
  name, or a stage it had to write that others would want. Either
  session that finds such a thing in the other's product while working
  sends it as a message:
  what was found, where (the file and commit), and what might be done.
  Nothing enters the other's `ROADMAP.md` or records directly; the
  session it's for takes the message to Iain, who decides whether it
  becomes an idea, an item or a task there, and the commit that
  removes the message says so. An item that comes of one gives the
  message in its record's Origin, with the repository, date and commit.
- **`TODO.md` never reaches `main`.** `main` moves only by a
  fast-forward to `develop`, so a release waits until the file is gone:
  each task done, or, to outlast the release, moved to `ROADMAP.md`, a
  decision awaiting Iain with it, in its record. No GitHub issues or
  Claude Docs for planned work or decisions, as Iain decided on
  2026-11-07: they sit outside the repository, apart from the history
  and the chat.
- **While an experimental branch carries the work, `TODO.md` is kept
  there,** as Iain decided on 2026-11-08. The branch's copy is the one
  worked from: its tasks are added, done and removed there, and
  Ekorn-Pipeline's session hands tasks and messages to that branch, not
  `develop`. `develop`'s copy is left alone, and falls behind; the
  merge brings the branch's back, so where the rebase conflicts in
  `TODO.md`, the branch's text is the answer.
- **Tasks for Ekorn-Pipeline go in its `TODO.md`,** as grammar and
  scalar hand tasks to each other: committed from a session here into
  `~/Git/github.com/nukopian/Ekorn-Pipeline`'s `TODO.md` on its
  `develop`, or on the experimental branch carrying its work, if it has
  one, as `docs: a task from DBIx-Squirrel: ...`, with **From:** (this
  repository's commit the task came from) and **Waiting on:** lines
  above the task, and pushed at once. Commit only that file, by its
  path, so nothing of a session working there goes with it. Commit in
  its working copy only if it's on that branch with a clean tree, after
  a `git pull --ff-only`; otherwise, never switch it, as a session may
  be working there, but use a worktree of the branch as GitHub has it,
  and push from there:

  ```
  git -C ~/Git/github.com/nukopian/Ekorn-Pipeline fetch -q origin
  git -C ~/Git/github.com/nukopian/Ekorn-Pipeline worktree add --detach /tmp/ekorn-pipeline-todo origin/develop
  git -C /tmp/ekorn-pipeline-todo push origin HEAD:develop
  git -C ~/Git/github.com/nukopian/Ekorn-Pipeline worktree remove /tmp/ekorn-pipeline-todo
  ```

  A push refused as not a fast-forward means the branch moved: remove
  the worktree and start again from the fetch. Its tasks for
  DBIx-Squirrel come here the same way, as its CLAUDE.md says. It's the
  only other repository this one touches, as Iain decided on
  2026-11-07.
- **Messages go in a `# Messages` section, above `# Planned work`,** in
  the same `TODO.md`, as Iain decided on 2026-11-07. A message is news
  the other session should know, but needs no work of its own: what one
  side has decided or done, or a change in plan. A message that asks
  for work is a task instead. Each is a `##` heading saying who it's
  from, the date and what it's about, with a **From:** line, sent as
  `docs: a message from DBIx-Squirrel: ...`, committing only that file.
  Read messages at the start of a session, with the tasks; the session
  they're for removes each once read, in a commit saying what came of
  it, and the heading with the last one.

Why: planned work survives between sessions in the open, where Iain
reviews it like any other change, and a release never carries an
unfinished list.

## The roadmap

These rules, and those for change records, are Ekorn-Pipeline's and
DBIx-Squirrel's, as Iain decided on 2026-11-07. They follow the shared
practice grammar and scalar use, but name items by an id rather than
a number.

- **`ROADMAP.md` holds what DBIx-Squirrel means to do:** features and
  outcomes, not session tasks. Its opening says how it's kept. **Now**
  is what's being worked on, at most three items, so it stays a queue:
  each a paragraph and a link to its record. Another starts only when
  one ships or goes back to Next. **Next** is decided but not started
  (what, why, done when). **Later** is meant to be done but not yet
  planned, in a line or two. **Ideas** might be done, or never: the
  date added, a line or two, newest last. The others put the most
  useful first.
- **Every item has an id, its year and a serial: `2026-0001`.** The
  year is the year it was added, and the serial is four digits, from
  0001, starting again each year. It's given when the item is added,
  never changed, and never used again. The roadmap's opening gives the
  last id allocated, as "Last id: 2026-0004": to allocate one, take
  this year, and add one to the last serial if its year is this year,
  or start at 0001 if not, and change that line in the commit that adds
  the item.
- **The id names the item everywhere:** its heading, `### 2026-0001.
  The reference and the how-to on MetaCPAN`; its record,
  `docs/changes/2026-0001-manuals-on-metacpan.md`; its line in
  `Changes`, which ends "(roadmap 2026-0001)"; commit messages; and a
  branch for it, such as `experiment/2026-0001-manuals-on-metacpan`.
  Another repository's id goes with that repository's name, as
  "Ekorn-Pipeline 2026-0001".
- **Every item has a size,** a guess at how much work it is, as a
  T-shirt size and its story points, XS 1, S 2, M 3 and L 5, in a
  **Size:** line, such as `**Size:** S (2)`. An item bigger than L is
  split into items that aren't, each with an id of its own and a
  **Split from:** line; the item split is retired, its id named in the
  commit.
- **An item that can't be done before another says so,** in a
  **Depends on:** line naming each id. It's never in a group ahead of
  an item it depends on: moving it forward moves those too, so a chain
  of them moves together, and they ship first or with it.
- **An item's questions are settled before work on it starts.** They're
  discussed in the chat, and kept in its record's Decisions, numbered,
  D1, D2 and on: unchecked while open, and checked once settled, with
  the answer, the date and why. A **Decisions:** line under the
  record's status sums them up, each settled or open in a few words,
  so its state shows at a glance. An item moves to Now only once every
  decision is checked, or Iain agrees to move one still open to another
  item or task, which the record says. A decision that needs no work
  of its own is kept in the commit message that records it.
- **When Iain mentions an idea in passing,** offer in one line to add
  it ("add as 2026-0005?"), and add it in a `docs:` commit.
- **It's kept current:** an item leaves when it ships, in the commit
  that adds it to `Changes`, and a change that ships, starts or drops
  an item updates it in the same commit. A dropped item is deleted, the
  commit naming its id, and its record, if it has one, says why.
- **It's public, on GitHub and `main`,** but not in the CPAN tarball,
  as `minil.toml` says, so nothing personal goes in it. There's no PDF
  of it.

Why: `Changes` is the past, the README the present, and the roadmap
the future, so anyone following the project can see what's coming; and
an id that sorts and never changes can be searched for years later.

## Change records

- **A planned change keeps a record** in `docs/changes/`, named for its
  id and the change: `2026-0001-manuals-on-metacpan.md`. A roadmap item's
  record is opened when it first has a question to settle, or when
  work on it starts. A task in `TODO.md` with steps gets a record too,
  taking the next id from the roadmap's opening, in the same sequence,
  though the task never appears there.
- **The plan is written in it when work starts, and isn't edited
  after.** What happened is added as the work goes: the outcome against
  Done when, changes from the plan and why, measurements, what was
  tried and reverted, and what's left. Experiments go in it too, with
  what they showed, as they won't survive anywhere else.
- **It's finished in the commit that ships or drops the change.** Its
  status is open, in progress, shipped, unreleased, shipped in vX.Y.Z,
  or dropped; a dropped change keeps its record, saying why.
- `docs/changes/README.md` has the template, and lists the records.
  Small fixes need none. There's no PDF of a record.

Why: the plan and its outcome sit side by side, with the decisions
that shaped it, so a reader can see what was predicted and what was
found.

## Commits

- Conventional commits, such as `feat: ...`, `fix: ...`, `docs: ...`,
  `test: ...` or `ci: ...`. Say why as well as what.
- Commits are signed. Work is committed and pushed to `develop`. `main`
  is the latest release, and moves only at a release, by a fast-forward
  to `develop`, with a signed tag on it.
- Add what changed for users to `Changes`, under Unreleased, in the same
  commit. Each entry opens with a precis, a short paragraph saying what
  the release brings, naming by id the roadmap items it ships, kept
  current as Unreleased grows: CPAN's users don't get the roadmap, and
  the precis is their account of it.
- gitleaks scans the whole history for secrets in CI on every push, and
  by hand before a tag. A leak stops the work like a failing test: once
  history is published, it can't be taken back.
