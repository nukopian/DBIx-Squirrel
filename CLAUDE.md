# Working on DBIx-Squirrel

These are the working rules for this repository. DBIx-Squirrel is Iain
Campbell's: much of it starts from his code for version 1, which he and
Claude bring over and improve together, and Claude reviews what he
writes by hand. The rules below say who does what. Each rule comes with
the reason for it.

Decisions still to be made, and the plan for the rewrite, are in the
Claude Doc
[DBIx-Squirrel successor: plan](https://claude.ai/artifact/1cnZmM5LRgpgX3F6sF8VqB).
How the repository is kept, from every commit to a release on CPAN and
the cut-over to the final name, is in
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
- Locally, Iain uses perlbrew with a library of the project's own,
  `perl-5.36.3@dbix-squirrel-2`, so its modules don't mix with other
  projects'. Whatever his default Perl is at the time, run commands with
  the library named, so they don't depend on it, and never `perlbrew
  switch` or `use`, which would change his shell:

  ```
  perlbrew exec --with perl-5.36.3@dbix-squirrel-2 yath test
  ```

  5.38.5, 5.40.5 and 5.42.3 are installed too, for testing across the
  range CI covers.

### Building a new Perl on Iain's Mac

Since Xcode 27.1 (Apple clang 21, with the macOS 27.0 SDK), `perlbrew
install` fails for every new Perl on his Mac, running macOS 26.7: the
build stops at "Failed to build miniperl", with a segmentation fault,
whatever the optimisation and with or without `--notest`. Building
against the older SDK works:

```
SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk MACOSX_DEPLOYMENT_TARGET=26.0 perlbrew install perl-5.42.3 --notest
```

XS modules installed with `cpanm` need neither variable: DBI and
DBD::SQLite built, passed their tests and worked on a Perl built this
way, on 2026-10-22. If an XS module ever crashes the same way, try the
same prefix on `cpanm`. Check whether this is still needed after the
next Xcode update.

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

The repository is DBIx-Squirrel-2 while it's in development. At release
it's renamed to DBIx-Squirrel, as the plan doc's "Cut-over to
DBIx-Squirrel" section describes. Minilla takes the repository and
issues URLs in `META.json` from the git remote, with no setting to
override them, so until then they name DBIx-Squirrel-2. The first
release comes after the rename, so its metadata names the final URL.

**Never create anything at `github.com/nukopian/DBIx-Squirrel`**, in any
case: GitHub's names ignore case, so `dbix-squirrel` is the same name.
That name now redirects to the archived DBIx-Squirrel-1, which is how
CPAN's links for 1.6.5 reach it. Anything created there ends the redirect
early.

## Planned work

- **At the start of a session, check for `TODO.md`** at the top of the
  repository, on `develop`. If it's there, read it, ask Iain whether each
  task should still be done, and do the ones he confirms. Remove each
  task in the commit that completes it, so the history shows which
  commit did which, and delete the file with the last one. A task he
  drops is removed too, saying why in the commit message.
- **Work planned for a later session goes into `TODO.md`,** committed on
  `develop`, with enough to do it cold: what, why, the files involved,
  and how to check it's done. Not only in Claude's memory or the chat,
  which Iain can't review and a fresh session may not have.
- **`TODO.md` never reaches `main`.** `main` moves only by a
  fast-forward to `develop`, so a release waits until the file is gone:
  each task done, or moved to a GitHub issue, or for a decision awaiting
  Iain, to the plan doc.

Why: planned work survives between sessions in the open, where Iain
reviews it like any other change, and a release never carries an
unfinished list.

## Commits

- Conventional commits, such as `feat: ...`, `fix: ...`, `docs: ...`,
  `test: ...` or `ci: ...`. Say why as well as what.
- Commits are signed. Work is committed and pushed to `develop`. `main`
  is the latest release, and moves only at a release, by a fast-forward
  to `develop`, with a signed tag on it.
- Add what changed for users to `Changes`, under Unreleased, in the same
  commit.
- gitleaks scans the whole history for secrets in CI on every push, and
  by hand before a tag. A leak stops the work like a failing test: once
  history is published, it can't be taken back.
