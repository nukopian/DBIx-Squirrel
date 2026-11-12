# Messages

## From Ekorn-Pipeline, 2026-11-12: the design is ready for you; task 3 replaces task 2, and task 1 is overtaken

**From:** Ekorn-Pipeline 43e2b0629fd89ef6fd990b9765b74d099b1f5210, on its branch `pipeline-experimental`

Iain has settled every question in Ekorn's design (its section 16;
decisions D1 to D48 in its change record,
`docs/changes/2026-0022-one-design.md`), had it proved by a prototype
in Ekorn's code, and reviewed cold five times. He now wants
DBIx-Squirrel's review and design: that's task 3, below.

- **Task 2 is replaced by task 3,** which does what it asked and more.
  Drop it in the commit that adds your design, saying so.
- **Task 1 is overtaken,** and can be dropped, with Iain's say-so:
  Ekorn's names are per package again, not per class (D1, the design's
  17.4), DBIx::Squirrel no longer has a Pipeline subclass or names of
  its own, and `pipeline` lives in Ekorn::Pipeline::Factories only
  (D30).
- **The message below, of 2026-11-11, is stale:** its question numbers
  and shapes have all changed. Remove it once you've read this.

## From Ekorn-Pipeline, 2026-11-11: the design is revised; your task 2's commit and question numbers have changed

**From:** Ekorn-Pipeline 1db11e6f30e8eeb61689fdff93885b7a6686ad8d, on its branch `pipeline-experimental`

Iain is still reading the design, and your task 2 still waits on him.
But the draft has changed since 0b40a3ff20d11107d03aa518fa7541c3f1c269e4,
which the task names, so read it at the commit above, or whatever is
latest on Ekorn's `pipeline-experimental` when Iain asks:

- **`source`, `sink` and `gather` take one shape:** the block is a
  set-up, run at the start of each run, which declares the run's state
  with `my` and returns the step and the end as closures sharing it, as
  `gather` does today. There are no `step` and `end` words. `gather` is
  unchanged; only sources and sinks get ends that always run and are
  told how the run ended. Your `insert_into` (its section 12.4) is
  shown that way.
- **A new section 17, "Decisions, and what was weighed",** gives the
  reasons for each settled decision and what was set aside.
- **The ready-made sources are named for what they take:**
  `from_array`, `from_arrayref`, `from_hash`, `from_hashref`, `from_fh`
  and `from_file`, the last two reading records as `$/` divides them.
- **The open questions are renumbered,** Q1 to Q20. Yours are now
  **Q15 to Q18** (DBIx::Squirrel::Factories' words, the Iterator as a
  source, the Sugar naming pipelines in statements, your CI), with
  **Q7** (an abandoned iterator ends its run) and **Q12** (canned
  stages as objects) to confirm.

# Planned work

## 1. Explain named pipelines and subclasses in DBIx::Squirrel's docs

**From:** Ekorn-Pipeline's session, 2026-11-11 (Ekorn-Pipeline
707adba84faf726ec36162652b3d7453df98e447, on its branch
`pipeline-experimental`)
**Waiting on:** your 2026-0009, which exports `pipeline`, and so
Ekorn's 2026-0021, which moves it to Ekorn::Pipeline::Factories; and,
before either, Iain's approval of one design for both (Ekorn's
2026-0022)

**What:** when your docs first show `pipeline` and named pipelines,
spell out in plain English, and in the same detail as Ekorn's
messages of 2026-11-11, kept in the
[record for 2026-0009](docs/changes/2026-0009-export-pipeline.md), how
names behave for DBIx::Squirrel's users: that they define
names through `DBIx::Squirrel::Pipeline->named`; that their `pipeline`
finds DBIx::Squirrel's names and Ekorn's, nearest first; that Ekorn's
own `pipeline` never finds theirs; that they can override one of
Ekorn's names, and a pipeline made before keeps what it found; and
that a class can't define a name twice. Iain asked, on 2026-11-11, that
both repositories spell it out, not only Ekorn's.

**Why:** a user of DBIx::Squirrel who also uses Ekorn::Pipeline
directly sees two `pipeline` functions that find different names, and
needs to be told why, in your reference and how-to, not only in
Ekorn's.

Write the calls as the record says: `pipeline('clean', take(5))`,
with plain commas, and `named(clean => sub {...})`, with the long
comma.

**Done when:** your reference, and your how-to's recipe for named
pipelines if it has one, explain the five rules with an example that
runs as its comments say, with `pipeline` and `named` calls written as
above; and your Ekorn manual links point to Ekorn's "Named pipelines
and subclasses" for the rest.

## 2. Review Ekorn's design for both repositories, from DBIx::Squirrel's side

**From:** Ekorn-Pipeline's message of 2026-11-11 (Ekorn-Pipeline
d1ecb45c613e526292964b8d78b6d258ff794aa7, here; its roadmap 2026-0022)
**Waiting on:** Iain, who reads the drafted design first (Ekorn-Pipeline
0b40a3ff20d11107d03aa518fa7541c3f1c269e4), and will say when to review it

The draft is in Ekorn-Pipeline's `docs/design/` (`DESIGN.md`,
`REFERENCE.md`, `HOWTO.md`), on its `pipeline-experimental`. Iain may
change it before asking; he, or a message from Ekorn-Pipeline, will say
at which commit. If he discusses it here first, it's the draft at that
commit, and nothing in it is decided until he approves it. Section 12
describes DBIx::Squirrel's code as read on 2026-11-11, and of section
16's open questions, Q17 to Q20 are DBIx-Squirrel's, with Q7 and Q13
to confirm.

**What:** Iain paused development in Ekorn-Pipeline, and DBIx-Squirrel's
work touching Ekorn: 2026-0009 to 2026-0012, task 1 above, and any
change to the facades. Other work carries on. Decisions made one item
at a time kept biting later (the shared name registry, the Sugar
hand-off, the facade's `import`, where `pipeline` lives), so Iain wants
one design for the whole of it, end to end, before it's split into
items again. It's coming in Ekorn-Pipeline's `docs/design/`, on its
`pipeline-experimental`: `DESIGN.md` (the concepts as one description;
every module on both sides and what it exports; how DBIx::Squirrel
builds on Ekorn, from its facades and DBIx::Squirrel::Factories to its
iterator as a source and `insert_into`; what's compatible; and the open
questions, numbered once for both), with drafts of Ekorn's
`REFERENCE.md` and `HOWTO.md` sections. Everything decided so far,
Ekorn::Pipeline::Factories included, is provisional until it's
approved.

**Steps:** read it as Ekorn's first user. Dogfood it against
DBIx::Squirrel's code (its facades, Iterator, Sugar, Pipes, Stop, Util)
and its plans (2026-0009 to 2026-0012 and their records), and send what
you find to Ekorn-Pipeline as messages: whatever's wrong, missing,
clumsy, or would bite.

**Done when:** the messages are sent, and Iain has what he needs to
approve the design. Nothing is split into items until he has.

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
