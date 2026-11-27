# Working on DBIx-Squirrel

The working rules for this repository. What it means to do is in
[ROADMAP.md](ROADMAP.md), with each item's decisions in its record in
[docs/changes/](docs/changes/README.md). How it's kept, from a commit
to a CPAN release, with commands to paste, is in
[docs/MAINTAINING.md](docs/MAINTAINING.md): read the section for the
job before doing it. Its last section, Iain's Mac, has the perlbrew
libraries, building Perl and the DBD drivers, and the test databases.

## What it is

DBI, minus the boilerplate, plus a pipeline: you still write SQL, with
placeholders in any common style, iterators over results, and a
pipeline of transformations declared beside the query. A stage can
change a row (map), drop it by returning nothing (filter), or return
several values (flatMap). It subclasses the DBI, and where it and plain
DBI do the same thing, they give the same result: plain DBI is the
baseline.

## Who does what

- **Code goes both ways.** Iain writes some by hand, and Claude reviews
  it. Where Iain asks, Claude writes code, often bringing his version 1
  over and improving it, and Iain reviews that. Claude doesn't change
  code it wasn't asked to.
- **Claude helps with Git ops and setup:** branches, CI, releases, the
  files around the code. Ask before changing anything on GitHub.
- **Tests and docs where Iain asks,** keeping the POD, `README.pod`,
  `Changes` and the README's Acknowledgements (what Claude did)
  accurate.
- **PDFs only when Iain asks** (`scripts/readme-pdf.sh`), not after
  every docs change. Check a docs change as text: run its examples,
  read the diff, run `xt/examples.t` and `xt/manuals.t`.
- **Commit messages:** Claude drafts them when asked. Every commit
  ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`,
  Iain's own included: we share the credit and the blame.
- **On CPAN, Iain is `Iain Campbell <cpanic@cpan.org>`,** the only
  address in the distribution. `.mailmap` maps his GitHub noreply
  address to it, so Minilla doesn't list him as his own contributor.

## Perl

- **Perl 5.36 or later;** modules start `use v5.36`. A module using
  `try`/`catch` adds `use experimental qw(try);`. `finally` works only
  after a `catch`: `try {...} finally {...}` is a syntax error on every
  Perl up to 5.44, so cleanup-only code catches, cleans up and throws
  again. `builtin::` functions replace Scalar::Util, with
  `use experimental qw(builtin);` and `use builtin qw(weaken);`; only
  those stable in 5.40.
- **Minilla builds the distribution;** follow its conventions. Our
  three departures: the README is `README.pod` (never edit
  `README.md`); `Changes` keeps an "Unreleased" heading; and releases
  do their own git steps rather than `minil release`, as
  MAINTAINING.md says.
- **The manuals are generated:** edit `docs/REFERENCE.md` and
  `docs/HOWTO.md`, run `scripts/manuals`, never edit the POD.
- **Run everything with the library named,** never `perlbrew switch`
  or `use`, which would change Iain's shell:
  `perlbrew exec --with perl-5.36.3@dbix-squirrel-2 ...`. Libraries of
  the same name exist for 5.38.5, 5.40.5, 5.42.3 and 5.44.0.

## Tests

- **Test2::V0, never Test::More,** with Test2::Plugin::NoWarnings in
  every file. Compare values, never Data::Dumper output (booleans dump
  differently from 5.38).
- **yath, not prove,** with `-L`; `yath failed lastlog.jsonl` shows the
  failures. They must still pass under `prove`, which users have.
- **Locally, test against Ekorn-Pipeline's working copy,** its `lib`
  first on `PERL5LIB`, and say which Ekorn commit the run used.
  MAINTAINING.md's Every commit has the commands. A failure only there
  means the two have parted: decide which side should change, and if
  it's Ekorn's, send it a message.
- **Coverage has floors** in `scripts/coverage`. New code comes with
  tests that keep above them; raise a floor when coverage rises, lower
  one only with the reason in the commit message. Floors are set
  without MySQL or PostgreSQL, as CI has neither.
- Core tests run on DBD::SQLite. `t/12-mysql.t` and `t/13-pg.t` skip
  unless `DBIX_SQUIRREL_TEST_MYSQL` or `DBIX_SQUIRREL_TEST_PG` is set.
- `xt/examples.t` runs the examples in `docs/HOWTO.md` and
  `docs/REFERENCE.md` against their comments; mark one that can't run
  `<!-- not run -->`.

## Style

- **Perl::Tidy and Perl::Critic** (`.perltidyrc`, `.perlcriticrc`) run
  on Perl 5.44, as CI's style job does, since Perl::Critic takes
  keywords from the Perl it runs on.
- **`croakf` raises our own errors,** from DBIx::Squirrel::Errors, as a
  `sprintf` format and arguments matching its DIAGNOSTICS entry; a
  literal `%` is `%%`. `croak` passes on others' messages, such as the
  DBI's.
- **An object is thrown with `die`, never `croak`,** with
  `## no critic (ErrorHandling::RequireCarping)`: `croak` adds nothing
  for an object, and costs about three times as much.
- **A closure run for each value reads `$_[0]`, without a signature**
  (our stages, sources, sinks and row accessors), with a comment saying
  why: a signature, or copying to a `my`, costs about 19 ns a call,
  around 4% of a stage. A step that hands the value to the caller's
  code keeps its signature, so a block changing `$_[0]` can't change
  what's passed on. Other subs, and the docs' examples, keep theirs
  unless a measurement shows a gain.
- **Two blank lines between subs,** or one above a sub's comment, in
  tests and scripts too (2026-0049, as Ekorn's 2026-0053 D4).
  Perl::Tidy keeps one above a comment, but makes two above a sub
  without one, even at the start of a block, and above `sub {`
  starting a line in a list: name such a closure in a variable first.
- **Every regex takes `x`, and its operator with parentheses:**
  `m( \A \d+ \z )x`, `s( \s+ \z )()xr`, `qr( ... )x`; never `/.../`.
  A literal space is `\ `, a literal `#` is `\#`.
- **Data::Dump's `pp`** is for debugging only.

## The name

The repository was DBIx-Squirrel-2 until 2026-11-08; the perlbrew
libraries keep that name. **Never create anything at
`github.com/nukopian/DBIx-Squirrel-2`,** in any case: it now redirects
here, and creating it ends the redirect.

## Planned work

- **At a session's start, read `TODO.md`** on `develop`, or on the
  experimental branch carrying work, if any. Ask Iain whether each
  task and message still stands. Remove each in the commit that
  completes or drops it (saying why), and delete the file with the
  last one.
- **Work for a later session goes in `TODO.md`** on `develop`, with
  enough to do it cold: what, why, the files, and how to check it's
  done. Never only in memory or the chat. While an experimental branch
  carries the work, its `TODO.md` is the one used; in a rebase
  conflict, the branch's text wins.
- **`TODO.md` never reaches `main`:** before a release each task is
  done or moved to `ROADMAP.md`. No GitHub issues or Claude Docs for
  plans or decisions.
- **Ekorn-Pipeline is the only other repository this one touches,**
  and only its `TODO.md`. DBIx-Squirrel dogfoods it: send friction,
  gaps, clumsy names or stages others would want. A **task** asks for
  work, under `# Planned work`, committed as
  `docs: a task from DBIx-Squirrel: ...`, with **From:** (our commit)
  and **Waiting on:** lines. A **message** is news needing no work, in
  a `# Messages` section above it, a `##` heading with sender, date and
  subject, a **From:** line, committed as
  `docs: a message from DBIx-Squirrel: ...`. Commit only that file, by
  path, on its `develop` (or its experimental branch), and push at
  once. Use its working copy only if it's on that branch with a clean
  tree, after `git pull --ff-only`; otherwise never switch it, but use
  a worktree:

  ```
  git -C ~/Git/github.com/nukopian/Ekorn-Pipeline fetch -q origin
  git -C ~/Git/github.com/nukopian/Ekorn-Pipeline worktree add --detach /tmp/ekorn-pipeline-todo origin/develop
  git -C /tmp/ekorn-pipeline-todo push origin HEAD:develop
  git -C ~/Git/github.com/nukopian/Ekorn-Pipeline worktree remove /tmp/ekorn-pipeline-todo
  ```

  If the push isn't a fast-forward, remove the worktree and start from
  the fetch. Nothing goes in the other's roadmap or records directly:
  Iain decides what a message becomes, and an item from one names it
  in its record's Origin.
- **A feature is designed in its own repository's session:**
  Ekorn::Pipeline's there, anything needing the DBI here. The other
  session only sends messages.
- **No secret whole in a message or task,** made-up or not: build it
  from pieces (`join '', 'AKIA', 'MADEUP', ...`) or leave it out. Run
  `betterleaks dir .` before a docs commit; a full hash beside a rule's
  name can look like a secret.

## The roadmap and change records

ROADMAP.md's opening and docs/changes/README.md say how they're kept;
follow them. In short:

- Ids are year and serial, `2026-0001`, taken from "Last id:" in the
  roadmap's opening, which the adding commit updates. The id names the
  heading, the record, the `Changes` line ("(roadmap 2026-0001)"),
  commits and any branch. Another repository's id carries its name.
- Every item has a **Size:** (XS 1, S 2, M 3, L 5; bigger is split),
  and a **Depends on:** line where needed. Now holds at most three.
- An item's questions are numbered decisions (D1, D2...) in its record,
  checked with answer, date and why, and summed up in a
  **Decisions:** line. It moves to Now only once all are settled.
- **When Iain mentions an idea in passing,** offer in one line to add
  it ("add as 2026-0033?").
- The plan in a record isn't edited once work starts; what happened is
  added as it goes, and finished in the commit that ships or drops it.
  A shipped item leaves the roadmap in the commit adding it to
  `Changes`.
- Both are public, so nothing personal.

## Commits

- Conventional, signed, saying why as well as what; pushed to
  `develop`. `main` moves only at a release, by fast-forward, with a
  signed tag.
- User-visible changes go in `Changes` under Unreleased in the same
  commit, and the entry's precis, naming the roadmap ids it ships, is
  kept current.
- **Secrets:** betterleaks scans history in CI. A finding stops the
  work. Published history is never rewritten: list that one finding by
  fingerprint (from
  `betterleaks git --redact -f json -r report.json .`) in
  `.gitleaksignore`, which betterleaks reads, with Iain's reason above
  it, and revoke a real secret first. Claude changes `.gitleaksignore`
  only with its Edit tool, never from the shell: a rule in Iain's
  settings makes each such edit ask him.
