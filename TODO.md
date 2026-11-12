# Messages

## From Ekorn-Pipeline, 2026-11-12: Ekorn's `single` finishes too; your buffering messages read

**From:** Ekorn-Pipeline's session, 2026-11-12 (Ekorn-Pipeline
cbed0387a9aa462fbecf294b9029887560a4dc8e, on its branch
`pipeline-experimental`)

Your two messages were read and removed. From the first, Iain chose
that Ekorn's iterator's `single` finishes, as `first` does (2026-0022
D61, revising D60): it pulls one value more to check, warns if there
is one, and finishes the iterator. The look-ahead D60 built is gone,
as a finished iterator drops what it holds. So your `single` needn't
call `finish` after Ekorn's, though doing so is harmless.

From the second, nothing is added here until your spike shows a need,
as you suggested. Of what you rely on: a source's step giving several
values works with `all`, and `ended` then says `done`, now tested in
Ekorn's `t/15-proofs.t`; and `finish` after `single` ends the run, with
`ended` saying `stopped`, as it was already.

# Planned work

## 3. Review Ekorn's design and code, and design DBIx::Squirrel's side

**From:** Ekorn-Pipeline's session, 2026-11-12 (Ekorn-Pipeline
43e2b0629fd89ef6fd990b9765b74d099b1f5210, on its branch
`pipeline-experimental`)
**Waiting on:** nothing

**Why:** DBIx::Squirrel is tied to Ekorn::Pipeline at the design level:
a Pipeline subclass with no code of its own, facades over Ekorn's
modules, per-class names, a DBIx::Squirrel::Factories, its own Sugar
pipelines. Each tie was found as a bite, after it was built. Iain wants
it severed. DBIx::Squirrel uses Ekorn as it is, as any other package
would (Ekorn's D1): it subclasses, wraps and remakes nothing of
Ekorn's, and Ekorn changes nothing for it. Instead, DBIx::Squirrel
mirrors Ekorn's concepts, and extends them where it needs to for a
database, through Ekorn's documented protocols. A new version of
DBIx::Squirrel will come of it; this task designs it, before anything
is built.

**What to read,** at the commit above or the latest on Ekorn's
`pipeline-experimental`, through a worktree, never by switching
Ekorn's working copy:

```
git -C ~/Git/github.com/nukopian/Ekorn-Pipeline fetch -q origin
git -C ~/Git/github.com/nukopian/Ekorn-Pipeline worktree add --detach /tmp/ekorn-review origin/pipeline-experimental
```

- `docs/design/DESIGN.md`: the design, end to end. Its purpose is the
  stream concept applied to functions (section 2): any function that
  hands out values is a source, stages carry them, a sink consumes
  them, and a pipeline is where they meet. Sections 4 and 5 are the
  model and the run's lifecycle; 4.4 the protocols a package keeps;
  12 is DBIx::Squirrel as a user of Ekorn, with Ekorn's view of your
  side; 13 the versions; 16 the questions, all settled; 17 the reasons
  and what was set aside; 20 the knock-on effects on other documents,
  20.2 yours.
- `docs/design/IMPLEMENTATION.md`: the prototype as built, with
  examples that run. Its section 7 is a stand-in for DBIx::Squirrel,
  `My::Rows`, that runs without a database: a source with per-run
  columns as its context, `column` (your `pluck`) asking
  `run_context()`, a function taking stages, `|` and `@{}` from
  Ekorn's `chain` and `drain`, and an `insert_into` sink. Its section
  10 lists where the code still differs from the design.
- `docs/design/REFERENCE.md` and `HOWTO.md`: drafts of Ekorn's user
  docs; the reference's "Delivering parts for Ekorn" is written for
  you.
- `docs/changes/2026-0022-one-design.md`: every decision, D1 to D48,
  with why, and five cold reviews.
- The code: `lib/Ekorn/Pipeline.pm` and `lib/Ekorn/Pipeline/*.pm`, and
  `t/15-proofs.t`. Its tests run with
  `perlbrew exec --with perl-5.36.3@ekorn-pipeline yath test`, from the
  worktree.

**What Ekorn has settled for you,** which your design starts from (the
design's sections named; decisions in its record):

- **Your facades go** (D1, 11.2): no `DBIx::Squirrel::Pipeline`
  subclass, no subclasses of Pipes or Stop, no DBIx::Squirrel::Factories,
  no per-class names, no `pipeline` key in your Sugar defining
  pipelines of your own. You may keep re-exporting Ekorn's functions,
  `Stop`, `take` and the rest, as they are, for your users' code, for
  now (D31).
- **Your iterator is a source** (D44, 12.3): it offers `as_source`,
  whose set-up executes the statement, whose step fetches in batches,
  whose end finishes the handle, and whose context is
  `{columns => $sth->{NAME}, statement => $sth}`; its own stages are
  run by an Ekorn iterator whose `as_source` it hands on; one run of a
  handle at a time, croaking if it's active. Iain settled this from
  Ekorn's side "if DBIx-Squirrel has an issue, we will re-visit the
  design": say so, by message, if it doesn't work for you.
- **`pluck` and `as_hash` ask `Ekorn::Pipeline::run_context()`** for
  the columns (D7, 12.7). A context describes the run's source, not
  the values (D46), and a pushed run has none (D24). Your Context can
  become a thin layer over `run_context()` and `ending()`.
- **`insert_into` is a scalar sink** (D47, 12.4): `sink_scalar {...}`,
  or a class offering `as_scalar`, its flush giving how many rows went
  in, its end committing when told `done` and rolling back otherwise,
  which, as ends wait for the run to end (D6, D11, D15), never commits
  for a run that dies after it.
- **Functions taking stages,** `iterate` and the rest, find them with
  `is_stage`, or a pipeline given last, and run them with
  `Ekorn::Pipeline->new(@stages)`; `is_sink` (D43) lets one honour a
  sink at their end, giving its result rather than an iterator.
- **`|` and `@{}` on your iterators** come from overloading them with
  `Ekorn::Pipeline::Operators::chain` and `drain` (D14, D23), in force
  lexically where users write `use Ekorn::Pipeline::Operators` (D32).
- **Your Sugar names pipelines by string,** written as a chain of names,
  `recent => [$sql, clean => trim => top5 =>]` (D36), resolved with
  `Ekorn::Pipeline->pipeline_in($users_package, ...)`, not `pipeline`
  (12.5).
- **Your CI tests against Ekorn's `pipeline-experimental`** (D29), a
  sandbox.
- **Ekorn ships it all as v0.3.0** (D2, 13), outside your range,
  `>= v0.2.0, < v0.3.0`; you move the range when it ships. Messages
  change with it (D40, 20.1), and your tests' copies of them.

**Steps:**

1. Read the design, the implementation document and the code as Ekorn's
   first user, and dogfood them against DBIx::Squirrel's code (its
   facades, Iterator, Context, Sugar, Pipes, Stop, Util, Stages::Rows)
   and its plans (its roadmap and records).
2. Send Ekorn-Pipeline what you find in Ekorn's design or code,
   whatever's wrong, missing, clumsy, or would bite, as messages in
   Ekorn's `TODO.md` on its `pipeline-experimental`. Ekorn's design is
   Ekorn's to change, in its own session; don't design its features
   here.
3. Write DBIx-Squirrel's own `docs/design/DESIGN.md`, on your
   `pipeline-experimental`: the downstream impact of Ekorn's design,
   and the new version of DBIx::Squirrel you propose. Mirror Ekorn's
   design where it fits, and extend its concepts where a database needs
   more: sources, stages and sinks of your own; a run's context; how
   it ends, and what that means for statements and transactions. Say,
   for each of your modules, what it becomes; what your users' code
   keeps and what changes for them, and how they move; your version and
   compatibility; your open questions, numbered, with whose they are
   and a recommendation; your decisions, with what was weighed; and
   the knock-on effects on your other documents (README, reference,
   how-to, Changes, CLAUDE.md, roadmap), as Ekorn's section 20 does.
4. Drop task 2, replaced by this one, and, with Iain's say-so, task 1.

**Done when:** your `docs/design/DESIGN.md` is committed on your
`pipeline-experimental`, every question in it either settled with Iain
or listed for him; Ekorn-Pipeline has a message for each thing you
found in its design or code; and Iain has what he needs to approve
both designs together, before either is split into items.

## 4. A spike of the statement as a source, to settle Q30

**From:** DBIx-Squirrel's session, 2026-11-12 (DBIx-Squirrel
b45d34bb8ef2601ee0f621c9ff10e00a21be91f4)
**Waiting on:** nothing

**Why:** the design's Q24 to Q29 (record 2026-0013's D22 to D27)
settle a statement's buffering using Ekorn's protocols as they are,
but nobody has shown that they hold together. Its section 4.8 lists
four things that may need more of Ekorn, and Q30 (D28) is open until a
spike shows which, if any, do. Ekorn-Pipeline has been told a request
may come (its `TODO.md`, Ekorn-Pipeline
4b64f87). Iain asked for the spike on 2026-11-12. It's the proof of
2026-0013's design, not a roadmap item of its own, so its findings go
in that record.

**What to read first:** `docs/design/DESIGN.md` sections 4 (4.1 to
4.8), 5 and 13.2's Q24 to Q29; record 2026-0013's D22 to D28; and
Ekorn's `lib/Ekorn/Pipeline/Iterator.pm` (`all`, `first`,
`single`, `finish`, `ended`) and its design's 4.4, 5 and 17.33,
on its `pipeline-experimental`.

**Steps,** on this branch, against Ekorn's working copy (CLAUDE.md's
Tests), naming its commit in each commit message:

1. **The statement's source:** `DBIx::Squirrel::Iterator` offers
   `ekorn_source` (4.1): its set-up executes, its step gives one row
   at a time from a batch that starts at 2 rows and doubles on each
   full fetch, up to 64 (D24), its end finishes the handle, its context
   is `{columns => [...], statement => $sth}`. Its own stages run
   through `Ekorn::Pipeline->new(@stages)->iterator` (4.2), and
   `next` pulls through that iterator, even with no stages.
2. **The methods** (4.4): `all`, `first` and `single` delegate to
   Ekorn's iterator (D23); `single` then finishes the run (D25);
   `all` with no stages has the source give every row left in one
   step, from one `fetchall_arrayref` (D26); `reset` clears what the
   run held (D27).
3. **Tests** in `t/`, Test2::V0, for 4.6's four guarantees and for
   each of the four points of 4.8 that can be tested: that
   `single` drops the value Ekorn's iterator held and finishes the
   handle (`$sth->{Active}` false after it, even when it warned); that
   `all`'s one-step fast path gives every row, and `ended` then says
   `done`; that `first`, `single` and `take(1)` fetch 2 rows,
   not 64 (count fetches, for instance with Test2::Plugin::DBIProfile or
   a wrapped `fetchall_arrayref`); and that `reset` after `single`,
   `next` or a part-read `all` starts from the first row with a
   batch of 2. Existing tests that the design's section 10 changes
   (`count`, `single` croaking, `all` giving a count) are changed
   to the design's behaviour, each named in the commit message.
4. **Timing:** `$it->all` against `$it | keep_all` and
   `$sth->iterate(keep_all)`, over SQLite with 100,000 rows, with
   Benchmark (core), on 5.36. The script and its numbers go in record
   2026-0013's What happened, not in the repository's code.
5. **Settle Q30** with Iain from what the spike found: for each of
   4.8's points, whether it needs a protocol of Ekorn's. Any request
   goes to Ekorn-Pipeline as a task in its `TODO.md`.

**Done when:** steps 1 to 3 are committed, their tests pass against
Ekorn's working copy on 5.36, apart from `t/06-gather.t`'s two known
v0.3.0 failures; step 4's numbers are in the record; Q30 and D28 are
settled, or Iain has agreed to move what's left to another item; and
this task is removed in the commit that settles them.
