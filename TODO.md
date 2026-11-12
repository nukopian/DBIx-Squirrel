# Messages

## From Ekorn-Pipeline, 2026-11-12: `count` is `count_items`, and `only_item` is `single_item`

**From:** Ekorn-Pipeline's session, 2026-11-12 (Ekorn-Pipeline
1fffaa19d42306effac4825bcbf6d295f9075d30, on its branch
`pipeline-experimental`)

Iain renamed two of Ekorn's sinks, as 2026-0022's D53, revising D50's
names: `count` is now `count_items`, and `only_item` is now
`single_item`. Nothing else about either changes. `count_items`
completes the family of sinks named for what they give, a bare `count`
is likelier to clash with a caller's own sub, and beside the tap
`count_into(\$n)`, the second word says which is which. `single_item`
echoes `single`, the iterator method of yours it replaces. Neither had
been released.

Where your design, drafts or code name Ekorn's `count` sink or
`only_item`, they take the new names. Your iterator's own `all`,
`single` and `count` methods are untouched. Ekorn's design has the
reasons in 17.28.

## From Ekorn-Pipeline, 2026-11-12: no `to_array`, `to_arrayref`, `to_hash` or `to_hashref`

**From:** Ekorn-Pipeline's session, 2026-11-12 (Ekorn-Pipeline
5c800d9f55c4ca013a6f000d6fb466e174bb2626, on its branch
`pipeline-experimental`)

Iain dropped Ekorn's containers for arrays and hashes, as 2026-0022's
D54: `to_array`, `to_arrayref`, `to_hash` and `to_hashref` are gone,
and `to_fh` and `to_file` stay as the container sinks. Since D51,
`all_items` gives every item as an array reference wherever one value
is asked for, so `to_array` and `to_arrayref` were `all_items` under
other names. Filling your own array is `push @mine, @{ $src | all_items
}`, and a hash is assigned from the keys and values a stage gives,
`@{ $src | stage { ($_->{id}, $_) } | all_items }`. Ekorn's design has
the reasons in 17.29.

Your design names them in several places: its D15, answering Q18,
settled `to_arrayref` as the sink giving every result in one reference
to end a `|` chain, and its section on sinks lists all four. A chain
now ends `| all_items` for that. Where your tests import `all_items`
beside Test2::V0, `use Test2::V0 qw(!all_items)` leaves Test2's check
of that name out, so the sink can be imported by its short name.

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
