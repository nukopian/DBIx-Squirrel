# DBIx::Squirrel on Ekorn as it is: the design

**Status:** a draft for review, from task 3 in `TODO.md`, with its
decisions in [record 2026-0013](../changes/2026-0013-one-design.md).
It waits on Iain's approval, together with Ekorn-Pipeline's design,
before either is split into roadmap items. Its questions are numbered
**Q1** and on, in section 13; open ones first.

**Read with:** Ekorn-Pipeline's design, `docs/design/DESIGN.md` on its
`pipeline-experimental`, reviewed here at
a75d178e4becfd1c3b6c57194bf6c111dabb8b98. Its sections are written
"Ekorn 12.3" below; its decisions "Ekorn's D44".

**For:** Iain, and Ekorn-Pipeline's session, which gets what's found
in its design as messages, not from this document.

## Contents

1. [Why this document](#1-why-this-document)
2. [What changes, in one paragraph](#2-what-changes-in-one-paragraph)
3. [What DBIx::Squirrel delivers](#3-what-dbixsquirrel-delivers)
4. [A statement as a source](#4-a-statement-as-a-source)
5. [Context: what a stage may ask](#5-context-what-a-stage-may-ask)
6. [Result sinks](#6-result-sinks)
7. [insert_into](#7-insert_into)
8. [Its Sugar](#8-its-sugar)
9. [The modules](#9-the-modules)
10. [What changes for users, and how they move](#10-what-changes-for-users-and-how-they-move)
11. [Versions](#11-versions)
12. [Testing](#12-testing)
13. [Questions](#13-questions)
14. [Where each roadmap item lands](#14-where-each-roadmap-item-lands)
15. [Knock-on effects on other documents](#15-knock-on-effects-on-other-documents)

## 1. Why this document

DBIx::Squirrel is tied to Ekorn::Pipeline by its design. It has a
Pipeline subclass with no code of its own, facades that subclass
Ekorn's Pipes and Stop, and plans for names per class, a Factories
module and a Sugar of its own for pipelines. Each tie was found as a
bite, after it was built.

Iain wants the ties cut. Ekorn's design, approved on its side, says
how: DBIx::Squirrel uses Ekorn as any other package would (Ekorn's
principle 2). It subclasses, wraps and remakes nothing of Ekorn's. It
delivers sources, stages and sinks that keep Ekorn's protocols (Ekorn
4.4), and runs them in Ekorn's own pipelines.

This document is DBIx::Squirrel's side of that: what each of its
modules becomes, what its users keep and what changes for them, and
what's still to decide.

## 2. What changes, in one paragraph

A statement's iterator becomes a source, which Ekorn's pipelines can
read from, and which `|` can start a chain with. Its stages are run
by Ekorn's own pipeline, not DBIx::Squirrel's subclass, which goes.
`pluck` and `as_hash` ask Ekorn for the run's columns, so they work in
a user's own pipeline too. New sinks collect rows into DBIx::Squirrel's
result objects. Everything else a user writes today keeps working,
except code that names `DBIx::Squirrel::Pipeline`, or checks that a
stage is a code reference. It's DBIx::Squirrel v3.0.0, on Ekorn
v0.3.0.

## 3. What DBIx::Squirrel delivers

Three kinds of part, each keeping one of Ekorn's protocols:

- **Sources:** a statement's rows (section 4).
- **Stages that need a database's knowledge:** `pluck` and `as_hash`
  (section 5).
- **Sinks:** rows collected as result objects (section 6), and,
  perhaps, `insert_into` (section 7).

And functions that take stages, as any user of Ekorn writes them:
`iterate`, `results`, the `select` methods, `pipe` and `tap`, and its
Sugar's statements. Each finds its stages with `is_stage` and runs them
with `Ekorn::Pipeline->new(@stages)`.

A user composes these with Ekorn's parts, and nothing in the result
knows which package made which:

```perl
use Ekorn::Pipeline::Operators;

my @top = @{ $sth->iterate(1990) | pluck('name') | take(5) };
my $n   = $sth->iterate | stage { $_->[1] } | count;
```

## 4. A statement as a source

### 4.1 The iterator offers `as_source`

`DBIx::Squirrel::Iterator` is what users hold, from `$sth->iterate`
and the like. It offers `as_source` (Ekorn's D44), so it can be given
wherever Ekorn takes a source:

- **Its set-up executes the statement,** with the iterator's bind
  values, and reads the column names before the first fetch.
- **Its step fetches,** in batches of 100, as now, from a buffer of the
  run's own.
- **Its end finishes the statement handle,** however the run ended.
- **Its context is the run's:** `{columns => [...], statement => $sth}`,
  and the row fetched last (section 5).

The column names are those `fetchrow_hashref` uses, from
`$sth->{FetchHashKeyName}`, not `$sth->{NAME}`. They're read before the
first fetch, as DBD::mysql gives none once the last row has been
fetched. A statement with list placeholders may be prepared again, on a
new handle, for the bind values given; the context names that handle.

### 4.2 Its own stages

An iterator given stages, `$sth->iterate(@binds, @stages)`, runs them
with `Ekorn::Pipeline->new(@stages)->iterator($statement_source)`. Its
`as_source` hands on that iterator's. An iterator used as a source
passes on the context of the run inside it (Ekorn 4.4), so a stage
the user adds after it still sees the statement's columns.

### 4.3 One run of a handle at a time

A DBI statement handle can't have two executions going at once. So:

- **`as_source` starts a fresh run,** from the first row, even after
  `next` (Q4, settled). It finishes the handle first if it's active,
  as `reset` does today.
- **It croaks if another of DBIx::Squirrel's iterators is part-way
  through the same handle,** as `reset` does today, rather than take
  the handle from under it.

Ekorn 12.3 had it croak whenever the handle is active. DBIx::Squirrel
keeps its own rule, which Ekorn has been told.

### 4.4 `next`, `all`, `single`, `reset` and `count`

They're rebuilt over the same source, so each is one run, or part of
one:

- `next` pulls from the run, starting one if none is going.
- `all` drains the run, and `single` starts a fresh one and croaks at
  a second result, as now.
- `reset` ends the run, if one is going, and keeps the bind values and
  stages given, as now.
- `count` counts the results handed out.
- A new `ended` gives what Ekorn's iterator says about how the run
  ended: `done`, `stopped` or `died`.

An iterator that's let go ends its run, through Ekorn's iterator's
`DESTROY` (Ekorn's D28), so its handle is finished. So
`my($first) = $sth->iterate->next` no longer leaves the handle active.

### 4.5 `|` and `@{}`

The iterator overloads `|` with `Ekorn::Pipeline::Operators::chain`
and `@{}` with `drain` (Ekorn's D14 and D23). They're in force only
where the user wrote `use Ekorn::Pipeline::Operators` (Ekorn's D32).

DBIx::Squirrel loads Operators itself, so a user who forgot to gets
Operators' own message, not "Undefined subroutine". Loading it
switches nothing on outside the scopes that use it. Ekorn has been
told of this.

### 4.6 Results

`DBIx::Squirrel::Results` stays a subclass of DBIx::Squirrel's own
Iterator, handing out each row as an object of a class made for its
columns. That's DBIx::Squirrel subclassing itself, not Ekorn, so
nothing changes but what section 4.4 changes for every iterator.

## 5. Context: what a stage may ask

`DBIx::Squirrel::Context` exports three functions today. Each becomes
a thin layer over what Ekorn gives a stage, `run_context()` and
`ending()`, wherever possible (Q3, settled):

| Function | Today | In this design |
|---|---|---|
| `result_original` | the row the value came from, as fetched; `undef` in a flush | the same, from the run's context: the statement's source keeps the row it fetched last there. So it works in a user's own pipeline too, behind `pluck` or any stage. `undef` while `ending()` is true, as now |
| `result_number` | the number of the result being made, from 1 | the same, but only where DBIx::Squirrel's own iterator runs the stages. In a user's own pipeline, it's `undef`, as nothing of DBIx::Squirrel's counts what comes out |
| `iterator` | the iterator running the stages | the same, only where DBIx::Squirrel's own iterator runs them; otherwise `undef` |

Keeping the row fetched last in the context bends Ekorn's D46, that a
context describes the source, not the values. The source does change
it, and only it: the row is the source's state, read by the stages
behind it. A stage that reshapes values doesn't change it, as D46
asks. Ekorn has been told.

`pluck` and `as_hash` take the columns from `run_context()`. Each
croaks where there are none, as in a pushed run, or one over a source
that isn't a statement: "Expected an iterator, for the column names",
as now (**Q13**).

## 6. Result sinks

Iain is more interested in these than in `insert_into` (2026-11-12).
They're sinks that collect rows into DBIx::Squirrel's result objects,
so a pipeline can end in a result set, whatever its source.

Today, `results` makes a `DBIx::Squirrel::Results`, an iterator that
blesses each row into a class made for the statement's columns, with
an accessor for each. A row's class comes from its columns' names. So
the same can be done by any run whose source gives columns in its
context, a statement or not.

A first shape, for review:

```perl
use DBIx::Squirrel::Sinks qw(to_results);

my $set    = $sth->iterate(1990) | take(10) | to_results;
my $artist = $set->first;
say $artist->name;
```

- **`to_results`** is a scalar sink, made with Ekorn's `sink_scalar`.
  Its set-up finds the row class for the run's columns, with
  `DBIx::Squirrel::Result->class_for`. Its step blesses each row, an
  array, into it. Its result is a result set.
- **A result set** holds the rows, in order. It has `all`, `first` and
  `count`, and is a source of its rows (`as_source`), giving its
  columns as its context. So it can be read again, through any
  pipeline, as a statement can, but from memory.
- **Its rows are `DBIx::Squirrel::Result` objects,** the same as
  `results` hands out, with their accessors, `get_column`, and any
  class given by `ekorn_result_class`.

Open questions: what a result set is (Q8), what rows `to_results`
takes (Q9), which other result sinks follow (Q10), and whether a
result set keeps `result_original` (Q14).

## 7. insert_into

Iain isn't bothered about keeping it (2026-11-12). If it's kept, it's
as Ekorn 12.4 has it, a scalar sink, with one change (Q5, settled): it begins and commits a transaction only when `AutoCommit`
is on. With `AutoCommit` off, or in a transaction the user began, it
leaves the transaction to the user, and neither commits nor rolls back.

Whether it's kept at all is **Q11**.

## 8. Its Sugar

`DBIx::Squirrel::Sugar` defines databases and statements, as now. It
names no pipelines of its own. Its users name them with Ekorn's Sugar
or `named`, and a statement's definition can use those names (Ekorn's
D36):

```perl
use DBIx::Squirrel::Sugar statement => {
    recent => [music => 'SELECT * FROM track WHERE year > ?', clean => trim => top5 =>],
};
```

A definition is a database, a statement, optional attributes in a
hash, and stages. It has no bind values, which come when it's called.
So anything after the statement and its attributes is a stage, and a
string there is a pipeline's name. The names are resolved with
`Ekorn::Pipeline->pipeline_in($package, ...)`, in the package that
used the Sugar, as the definition is made. A name must be defined
before it's used.

When a statement is called, its arguments are bind values, then
stages, as now. A string there is a bind value, never a name (Ekorn's
principle 5).

The Sugar keeps its own `install_sub` and `is_name`, rather than call
Ekorn's (Ekorn 10).

## 9. The modules

| Module | Today | In this design |
|---|---|---|
| `DBIx::Squirrel`, `::db`, `::st` | the DBI subclass and its handles; `iterate`, `results`, the `select` methods | the same. `db` and `st` take `pipe` and `tap` from `Ekorn::Pipeline::Pipes`, the parent class Ekorn offers for it (Ekorn 11.1), not from a facade |
| `::Iterator` | rows through a pipeline of its own class | a source (section 4); its stages run by Ekorn's pipeline; `\|` and `@{}` |
| `::Results`, `::Result` | rows as objects | unchanged, but for section 4.4 |
| `::Context` | the iterator, the result's number and its row | a thin layer over `run_context()` and `ending()` (section 5) |
| `::Stages::Rows` | `pluck`, `as_hash`, by Context | the same, by `run_context()` |
| `::Sinks` | (new) | result sinks (section 6); `insert_into`, if kept (section 7) |
| `::Pipeline` | a subclass of Ekorn's, with no code | goes (Q1, settled) |
| `::Pipes` | a subclass of Ekorn's Pipes | goes: `db` and `st` use Ekorn's directly |
| `::Stop` | a subclass of Ekorn's Stop, re-exporting `Stop` | a plain re-export of Ekorn's `Stop` (Q6, settled) |
| `::Gather`, `::Stages::Flow`, `::Batch`, `::Taps` | re-exports of Ekorn's functions | unchanged: plain re-exports (Ekorn's D31) |
| `::Errors` | `croakf`, with Ekorn's `@INTERNAL` in its `@CARP_NOT` | unchanged |
| `::Util` | `split_stages` and other helpers | unchanged, but for **Q12** |
| `::Sugar` | databases, statements | names in definitions (section 8) |
| `::Placeholders` | placeholder rewriting | unchanged |

## 10. What changes for users, and how they move

| Users' code | What happens | How they move |
|---|---|---|
| `DBIx::Squirrel::Pipeline->new(...)` | fails: the module is gone | `Ekorn::Pipeline->new(...)`, or `pipeline(...)` from Ekorn::Pipeline::Factories |
| `$x isa 'DBIx::Squirrel::Pipeline'` | false | `$x isa 'Ekorn::Pipeline'` |
| `ref $stage eq 'CODE'`, `is_coderef($stage)`, for a stage made by `take`, `gather` and the like | false: they're objects now, called as code references (Ekorn's Q12) | `is_stage($stage)` |
| `result_number` or `Context::iterator` in a user's own pipeline over an iterator | `undef` | count in a stage of their own |
| `my($first) = $sth->iterate->next`, then using the handle | the handle is finished once the iterator goes | keep the iterator while the handle is in use |
| everything else: `iterate`, `results`, the `select` methods, Sugar, `pluck`, `as_hash`, `take`, `Stop`, `gather` | unchanged | nothing |

The last but one is a fix rather than a break, but a program that
relied on the handle staying active would see it.

## 11. Versions

- **DBIx::Squirrel v3.0.0** (Q2, settled). Dropping
  `DBIx::Squirrel::Pipeline` breaks code that names it.
- **It requires Ekorn::Pipeline `>= v0.3.0, < v0.4.0`,** once v0.3.0
  is on CPAN. Its tests' copies of Ekorn's messages change with it.
- **Perl 5.36 or later,** unchanged.
- Until v0.3.0 ships, DBIx::Squirrel v2.x stays on Ekorn v0.2.x, and
  takes only fixes.

## 12. Testing

Locally first (Q7, settled): the work is tested against Ekorn's
working copy on its `pipeline-experimental`, as CLAUDE.md's Tests
section already says, with the commit named. CI follows once the two
designs are nailed down: a job on DBIx-Squirrel's
`pipeline-experimental`, installing Ekorn from that branch. `develop`
and `main` keep installing Ekorn from CPAN.

Against a75d178, 25 of the 26 test files pass. `t/06-gather.t` fails
two subtests, both v0.3.0's intended changes: a gather is an object,
and its block may return a flush and an end.

## 13. Questions

Each says whose it is, and recommends an answer. Settled ones keep
their numbers, with the decision in record 2026-0013.

### 13.1 Open

| | Question | Whose | Recommendation |
|---|---|---|---|
| **Q8** | What is a result set: a list of rows, or an object? | DBIx-Squirrel's | an object, `DBIx::Squirrel::ResultSet`, with `all`, `first` and `count`, and `as_source`, so it can be read again; `to_results` is its scalar sink. A list sink, `to_result_rows`, can follow if wanted |
| **Q9** | What rows does `to_results` take? | DBIx-Squirrel's | arrays in the run's column order, as a statement gives them; hashes by their keys, sorted, as there's no order to take; and croak at anything else, or at an array without a run's columns |
| **Q10** | Which other result sinks? | DBIx-Squirrel's | none at first. Candidates: `to_result` (the first row as an object, as `single`), and a sink keyed by a column, as `selectall_hashref` |
| **Q11** | Keep `insert_into`? | Iain's | not now: drop roadmap 2026-0012, and find it again if a need comes |
| **Q12** | `split_stages` and Sugar find stages with `is_stage`, which at a75d178 takes a bind value with an `as_list` method for a sink | Ekorn's to fix; DBIx-Squirrel's to test | wait for Ekorn's answer, sent 2026-11-12; then add a test with such a bind value |
| **Q13** | `pluck` and `as_hash` with no run's columns | DBIx-Squirrel's | croak, as now, with the message unchanged; give a hash row's own keys to `pluck` by name, as now, without needing columns |
| **Q14** | Does a result set's `as_source` keep `result_original`? | DBIx-Squirrel's | yes: its source keeps the row it gave last in its context, as a statement's does |

### 13.2 Settled

| | Question | Settled |
|---|---|---|
| **Q1** | Keep `DBIx::Squirrel::Pipeline`? | D1: no. It goes; the docs show `Ekorn::Pipeline->new` and `pipeline` |
| **Q2** | The version? | D2: v3.0.0 |
| **Q3** | Keep `result_number` and `result_original`? | D3: yes, as section 5 says |
| **Q4** | An iterator used as a source after `next`? | D4: a fresh run, from the first row; croak only if another of DBIx::Squirrel's iterators is part-way through the handle |
| **Q5** | `insert_into` and a transaction already begun? | D5: it begins and commits only with `AutoCommit` on |
| **Q6** | The facades? | D6: `Gather`, `Stop` and the `Stages::*` modules are plain re-exports; `Pipeline` and `Pipes` go |
| **Q7** | CI against Ekorn's `pipeline-experimental`? | D7: yes, but locally first, and CI once the designs are nailed down |

## 14. Where each roadmap item lands

| Item | Here | What becomes of it |
|---|---|---|
| 2026-0003, add-on stage distributions | 3 | unchanged; those needing no database may go to Ekorn |
| 2026-0009, export `pipeline` | 9 | not needed: users import `pipeline` from Ekorn::Pipeline::Factories. Drop it |
| 2026-0010, a `pipeline` key in Sugar | 8 | becomes names in a statement's definition (Ekorn's D36) |
| 2026-0011, Ekorn's `install_sub` and `is_name` | 8 | not needed: the Sugar keeps its own (Ekorn 10). Drop it |
| 2026-0012, `insert_into` | 7 | Q11 |
| (new) | 6 | result sinks |
| (new) | 4 | the iterator as a source, Context over `run_context()`, the facades gone: the v3.0.0 work |

## 15. Knock-on effects on other documents

- **README:** the synopsis gains a `|` chain; Acknowledgements say what
  Claude did in this work.
- **Reference:** `DBIx::Squirrel::Pipeline` goes, and its examples use
  `Ekorn::Pipeline->new`; the iterator's section says it's a source,
  with `as_source`, `ended`, `|` and `@{}`; Context says where each
  function works; Stages say they're objects; result sinks are new;
  Sugar's definitions take names.
- **How-to:** about a dozen examples use `DBIx::Squirrel::Pipeline`, and
  move to Ekorn's. New recipes: a statement read through `|`, and rows
  collected as results.
- **`Changes`:** v3.0.0's precis names what breaks and how to move,
  from section 10.
- **CLAUDE.md:** the Ekorn version it tests against; the CI job, once
  added.
- **Roadmap:** section 14's changes, as items, once Iain approves.
- **The modules' POD:** each that changes, in the same commits.
- **`cpanfile`:** Ekorn's range, at the release.
