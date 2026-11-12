# DBIx::Squirrel on Ekorn as it is: the design

**Status:** a draft for review, from task 3 in `TODO.md`, with its
decisions in [record 2026-0013](../changes/2026-0013-one-design.md).
It waits on Iain's approval, together with Ekorn-Pipeline's design,
before either is split into roadmap items. Its questions are numbered
**Q1** and on, in section 13; open ones first.

**Read with:** Ekorn-Pipeline's design, `docs/design/DESIGN.md` on its
`pipeline-experimental`, reviewed here at
a75d178e4becfd1c3b6c57194bf6c111dabb8b98, and brought up to date with
8ce1c95b6a3bb6b7c4052374c67660491416686a, which took in what was found. Its sections are written
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
7. [insert_into, dropped](#7-insert_into-dropped)
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
a user's own pipeline too. A run ends in one of Ekorn's sinks, such as
`all_items` or `count`, not in the iterator's `all`, `single` and
`count`, which go. That breaks code, which v3.0.0 is for: it's
DBIx::Squirrel v3.0.0, on Ekorn v0.3.0.

## 3. What DBIx::Squirrel delivers

One rule decides what every call gives back (Q19, settled):

> **A statement is a source. DBIx::Squirrel's own calls give the
> source, an iterator, and only a sink given last turns it into a
> result. The DBI's own calls give what the DBI gives.**

So no call of DBIx::Squirrel's lists or counts by its calling context.
Sections 4 and 6 follow from it.

Two kinds of part, each keeping one of Ekorn's protocols:

- **Sources:** a statement's rows (section 4).
- **Stages that need a database's knowledge:** `pluck` and `as_hash`
  (section 5).

It makes no sinks of its own: a run ends in Ekorn's (section 6).

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

### 4.1 The iterator offers `ekorn_source`

`DBIx::Squirrel::Iterator` is what users hold, from `$sth->iterate`
and the like. It offers `ekorn_source` (Ekorn's D44 and D49), so it can be
given wherever Ekorn takes a source:

- **Its set-up executes the statement,** with the iterator's bind
  values, and reads the column names before the first fetch.
- **Its step fetches,** in batches of 100, as now, from a buffer of the
  run's own.
- **Its end finishes the statement handle,** however the run ended.
- **Its context is the run's:** `{columns => [...], statement => $sth}`,
  and the row it gave last (section 5).

The column names are those `fetchrow_hashref` uses, from
`$sth->{FetchHashKeyName}`, not `$sth->{NAME}`. They're read before the
first fetch, as DBD::mysql gives none once the last row has been
fetched. A statement with list placeholders may be prepared again, on a
new handle, for the bind values given; the context names that handle.

### 4.2 Its own stages

An iterator given stages, `$sth->iterate(@binds, @stages)`, runs them
with `Ekorn::Pipeline->new(@stages)->iterator($statement_source)`. Its
`ekorn_source` hands on that iterator's. An iterator used as a source
passes on the context of the run inside it (Ekorn 4.4), so a stage
the user adds after it still sees the statement's columns.

### 4.3 One run of a handle at a time

A DBI statement handle can't have two executions going at once. So:

- **`ekorn_source` starts a fresh run,** from the first row, even after
  `next` (Q4, settled). It finishes the handle first if it's active,
  as `reset` does today.
- **It croaks if another of DBIx::Squirrel's iterators is part-way
  through the same handle,** as `reset` does today, rather than take
  the handle from under it.

Ekorn 12.3 had it croak whenever the handle is active. DBIx::Squirrel
keeps its own rule, which Ekorn has been told.

### 4.4 `next` and `reset`; `all`, `single` and `count` go

What's left of the iterator's methods is rebuilt over the same source:

- `next` pulls from the run, starting one if none is going.
- `reset` ends the run, if one is going, and keeps the bind values and
  stages given, as now.
- A new `ended` gives what Ekorn's iterator says about how the run
  ended: `done`, `stopped` or `died`.

`all`, `single` and `count` go (Q15, settled). Each ended a run, so
each becomes a sink, given last (section 6).

An iterator that's let go ends its run, through Ekorn's iterator's
`DESTROY` (Ekorn's D28), so its handle is finished. So
`my($first) = $sth->iterate->next` no longer leaves the handle active.

### 4.5 `|` and `@{}`

The iterator overloads `|` with `Ekorn::Pipeline::Operators::chain`
and `@{}` with `drain` (Ekorn's D14 and D23). They're in force only
where the user wrote `use Ekorn::Pipeline::Operators` (Ekorn's D32).

DBIx::Squirrel loads Operators itself, with an empty import list,
`use Ekorn::Pipeline::Operators ();`, which defines `chain` and `drain`
without putting the operators in force anywhere (Ekorn 12.3). So a
user who forgot to `use` it gets Operators' own message, not
"Undefined subroutine".

### 4.6 What the build must keep

Three things the design promises that are easy to lose in the code:

- **A run's end touches only its own run.** When `next` has a run
  going and a fresh one starts (4.3), the old run is ended first. An
  end finishes the handle only if its own run still holds it, so an
  old run's end, fired late as its Ekorn iterator is let go, can't
  finish the handle under a newer run.
- **No cycles keep an iterator alive.** The iterator holds Ekorn's
  iterator, which holds the source's closures. Those closures hold
  the iterator weakly, as the source does today, or `DESTROY` never
  runs and the handle is never finished (4.4).
- **Ends at program exit are quiet.** Ekorn runs ends during global
  destruction, in no set order, as warnings. An end there must not
  call `finish` on a handle whose database has gone, so that a program
  or a test under Test2::Plugin::NoWarnings ends without warnings.

Each gets a test when it's built.

### 4.7 Results

`DBIx::Squirrel::Results` stays a subclass of DBIx::Squirrel's own
Iterator, handing out each row as an object of a class made for its
columns. That's DBIx::Squirrel subclassing itself, not Ekorn, so
nothing changes but what sections 4.4 and 4.6 change for every iterator.

## 5. Context: what a stage may ask

`DBIx::Squirrel::Context` exports three functions today. Each becomes
a thin layer over what Ekorn gives a stage, `run_context()` and
`ending()`, wherever possible (Q3, settled):

| Function | Today | In this design |
|---|---|---|
| `result_original` | the row the value came from, as fetched; `undef` in a flush | the same, from the run's context: the statement's source keeps the row it gave last there, not the last of a batch it fetched. So it works in a user's own pipeline too, behind `pluck` or any stage. `undef` while `ending()` is true, as now |
| `result_number` | the number of the result being made, from 1 | the same, but only where DBIx::Squirrel's own iterator runs the stages. In a user's own pipeline, it's `undef`, as nothing of DBIx::Squirrel's counts what comes out |
| `iterator` | the iterator running the stages | the same, only where DBIx::Squirrel's own iterator runs them; otherwise `undef` |

Keeping the row given last in the context bends Ekorn's D46, that a
context describes the source, not the values. The source does change
it, and only it: the row is the source's state, read by the stages
behind it. A stage that reshapes values doesn't change it, as D46
asks. Ekorn has been told.

`pluck` and `as_hash` take the columns from `run_context()`. Each
croaks where there are none, as in a pushed run, or one over a source
that isn't a statement: "Expected an iterator, for the column names",
as now (Q13, settled). `pluck` by name on a hash row uses the row's
own keys, as now, so it needs no columns.

## 6. Ending a run: Ekorn's sinks

A run ends in a sink, given as its last stage, which says what the
caller wants back (Q15, settled). The calling context no longer
decides it: `my $n = ...` and `my @rows = ...` get what the sink gives,
not a count or a list by Perl's rules.

The sinks are Ekorn's, as none needs a database:

| Today | In this design |
|---|---|
| `$it->all` | `all_items`: every result, as a list |
| (none) | `first_item`: the first result, stopping the run there |
| `$it->single`, which croaks at a second result | `only_item`: the one result, with a warning if there's a second, for a SELECT that forgot `LIMIT 1`; it gives the first, and stops the run there |
| `$it->count`, after a drain | `count`, how many results there were |

Each is named for what it gives, not for what the result is put in
(Q16 and Q17, settled).

Container sinks are another kind, and valid too (Q18, settled): each
puts the items into a container, yours if you give one, or a new one,
and is named for it. `to_array` and `to_arrayref` take items;
`to_hash` and `to_hashref` take pairs. Ekorn's design has all four
(Ekorn 8.3).

`all_items` gives a list in list context, and in scalar context the
same list as an array reference (Q22, settled, from Ekorn's D51). So
`my $rows = ... all_items` is the rows, never a count of them, and a
`|` chain, which asks for one value, can end in `all_items` too.
`to_arrayref` keeps its job, filling an array you hand it. An empty
result is then true, so testing for no rows takes `@$rows`, or
`count`.

Ekorn took these in as its D50, and built them on its
`pipeline-experimental` (e03e71958e0052dd098672f77a099b90681644e2):
`Ekorn::Pipeline::Sinks` exports `all_items`, `first_item`, `only_item`
and `count`, and the containers `to_array`, `to_arrayref` and
`to_file`. `first_value` is now `first_item`. `only_item` warns
"Expected only one item, but there were more", at the caller's line.

A function that takes stages gives a sink's result when its last stage
is one, rather than an iterator, as Ekorn's D43 allows:

```perl
use Ekorn::Pipeline::Sinks qw(all_items only_item count);

my @rows   = $dbh->iterate('SELECT * FROM artist', all_items);
my $artist = $dbh->results('SELECT * FROM artist WHERE id = ?', 1, only_item);
my $n      = $sth->iterate(1990, count);
my @top    = @{ $sth->iterate | pluck('name') | take(5) };
```

That's `iterate`, `results`, the `select` methods and the Sugar's
statements. Without a sink last, each follows the rule in section 3:

- **`iterate` and `results`** give an iterator, as today.
- **The Sugar's statements, given stages,** give an iterator. Today
  they give every result, or a count in scalar context.
- **The `select` methods** are the DBI's, so without stages they give
  what the DBI gives, as today. Given stages, what the DBI gives is
  pushed through them, as `pipe` pushes a handle, and the call gives
  what comes out of the last stage (Q24, settled):
  `selectall_arrayref` pushes one value, its array reference, and
  `selectrow_array` the row's values. As a pushed run, it has no
  context, so `pluck` and `as_hash` croak there (Q13). What comes out
  is as Ekorn's pushed runs give it: every value in list context; in
  scalar context, a sink's result if a sink is last, a list sink's as
  an array reference, or, with no sink, a count (Ekorn's D17). That
  last is the one place a call of DBIx::Squirrel's still counts by its
  calling context.

The rule answers the rest:

- **`only_item` with no rows** gives what Ekorn's sinks of one value
  give, `undef`. A caller wanting nothing for no rows uses
  `all_items`.
- **Users get the sinks from Ekorn,** as any user of Ekorn does.
  DBIx::Squirrel may re-export them (Ekorn's D31), and needs no module
  of its own for them.
- **The iterator's "how many so far"** goes with its `count` method.
  Counting is a stage's or a sink's job: `count`, or
  `result_number` while DBIx::Squirrel's iterator runs the stages.
- **The sinks' names** are Ekorn's to settle, as the sinks are its.

Rows become `DBIx::Squirrel::Result` objects at the source, from
`results`, so there's no result sink of DBIx::Squirrel's own: `results`
and a sink do what one would.

## 7. insert_into, dropped

Iain dropped it for now (Q11, settled), with roadmap 2026-0012. It
will be found again if a need comes. If it is, it's as Ekorn 12.4 has
it, a scalar sink, with one change (Q5, settled): it begins and
commits a transaction only when `AutoCommit` is on. With `AutoCommit`
off, or in a transaction the user began, it leaves the transaction to
the user, and neither commits nor rolls back.

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
principle 5). Given stages, it gives an iterator, or a sink's result
if the last stage is one (section 6). Given none, it gives its handle,
executed, as now.

The Sugar keeps its own `install_sub` and `is_name`, rather than call
Ekorn's (Ekorn 10).

## 9. The modules

| Module | Today | In this design |
|---|---|---|
| `DBIx::Squirrel`, `::db`, `::st` | the DBI subclass and its handles; `iterate`, `results`, the `select` methods | the same. `db` and `st` take `pipe` and `tap` from `Ekorn::Pipeline::Pipes`, the parent class Ekorn offers for it (Ekorn 11.1), not from a facade |
| `::Iterator` | rows through a pipeline of its own class; `next`, `all`, `single`, `count`, `reset` | a source (section 4); its stages run by Ekorn's pipeline; `\|` and `@{}`; `next`, `reset` and `ended`, as `all`, `single` and `count` become sinks (section 6) |
| `::Results`, `::Result` | rows as objects | unchanged, but for section 4.4 |
| `::Context` | the iterator, the result's number and its row | a thin layer over `run_context()` and `ending()` (section 5) |
| `::Stages::Rows` | `pluck`, `as_hash`, by Context | the same, by `run_context()` |
| `::Pipeline` | a subclass of Ekorn's, with no code | goes (Q1, settled) |
| `::Pipes` | a subclass of Ekorn's Pipes | goes: `db` and `st` use Ekorn's directly |
| `::Stop` | a subclass of Ekorn's Stop, re-exporting `Stop` | a plain re-export of Ekorn's `Stop` (Q6, settled) |
| `::Gather`, `::Stages::Flow`, `::Batch`, `::Taps` | re-exports of Ekorn's functions | unchanged: plain re-exports (Ekorn's D31) |
| `::Errors` | `croakf`, with Ekorn's `@INTERNAL` in its `@CARP_NOT` | unchanged |
| `::Util` | `split_stages` and other helpers | unchanged; a test that an object bind value stays one (Q12) |
| `::Sugar` | databases, statements | names in definitions (section 8) |
| `::Placeholders` | placeholder rewriting | unchanged |

## 10. What changes for users, and how they move

| Users' code | What happens | How they move |
|---|---|---|
| `DBIx::Squirrel::Pipeline->new(...)` | fails: the module is gone | `Ekorn::Pipeline->new(...)`, or `pipeline(...)` from Ekorn::Pipeline::Factories |
| `$x isa 'DBIx::Squirrel::Pipeline'` | false | `$x isa 'Ekorn::Pipeline'` |
| `ref $stage eq 'CODE'`, `is_coderef($stage)`, for a stage made by `take`, `gather` and the like | false: they're objects now, called as code references (Ekorn's Q12) | `is_stage($stage)` |
| `$it->all`, `$it->single`, `$it->count` | fails: the methods are gone | a sink given last: `all_items`, `only_item`, `count` (section 6) |
| `my @names = artist_names sub {...}`, a Sugar statement given stages | gives an iterator, not every result | give a sink last, `all_items`, or drain it with `@{}` |
| a Sugar statement given stages in scalar context, for a count | gives an iterator | give `count` last |
| `result_number` or `Context::iterator` in a user's own pipeline over an iterator | `undef` | count in a stage of their own |
| `my($first) = $sth->iterate->next`, then using the handle | the handle is finished once the iterator goes | keep the iterator while the handle is in use |
| everything else: `iterate`, `results`, and the `select` methods and Sugar without stages or a sink last, `pluck`, `as_hash`, `take`, `Stop`, `gather` | unchanged | nothing |

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

Against a75d178, 8ce1c95 and e03e719, 25 of the 26 test files pass. `t/06-gather.t` fails
two subtests, both v0.3.0's intended changes: a gather is an object,
and its block may return a flush and an end.

Test2::V0 exports a check named `all_items`, as Ekorn has warned. A
test importing both it and the sink gets a prototype-mismatch warning,
which Test2::Plugin::NoWarnings fails. Tests call the sink by its full
name, `Ekorn::Pipeline::Sinks::all_items()`, or don't import
Test2::V0's. Iain kept the name over `every_item`, as the clash is
"only a problem in test harness" (Ekorn's D50).

The same goes for any clash between a sink and a name in the user's
package, such as a Sugar statement called `count` (Q23, settled). The
Sugar's clash check catches it, with a test to show it. And a user can
call the sink by its full name, or keep it in a lexical:

```perl
my $n = $sth->iterate(1990, Ekorn::Pipeline::Sinks::count());

my $count = \&Ekorn::Pipeline::Sinks::count;
my $m     = $sth->iterate(1991, $count->());
```

## 13. Questions

Each says whose it is, and recommends an answer. Settled ones keep
their numbers, with the decision in record 2026-0013.

### 13.1 Open

| | Question | Whose | Recommendation |
|---|---|---|---|
| **Q21** | `pluck` after a stage that reshapes rows reads the statement's columns, as a context describes the source (Ekorn's D46), and so picks the wrong field, silently. `\|` makes that easier to write | DBIx-Squirrel's | say so loudly in the reference and the how-to, and show `as_hash` first, then `pluck` by name, which uses the hash's own keys. Detecting a reshaped row isn't possible without more from Ekorn |

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
| **Q8** | What does a result sink give? | D10, overtaken by D11: a `Results` over the rows collected. No result sink is made now |
| **Q11** | Keep `insert_into`? | D9: not now. Roadmap 2026-0012 is dropped, and it'll be found again if a need comes |
| **Q12** | `is_stage` took a bind value with an `as_list` method for a sink | D8, from Ekorn's D49: its role methods are renamed `ekorn_source`, `ekorn_stage`, `ekorn_sink` and `ekorn_sink_scalar`, so `is_stage` leaves any other object as a bind value. Checked at 8ce1c95. DBIx::Squirrel adds a test with such a bind value |
| **Q13** | `pluck` and `as_hash` with no run's columns? | D13: croak, as now, with the message unchanged; `pluck` by name on a hash row uses the row's own keys, as now, without columns |
| **Q15** | Should `all`, `single` and `count` stay methods, or be sinks? | D11: sinks, Ekorn's, named in D14. The methods go in v3.0.0; `next` and `reset` stay. A call ending in a sink gives its result (Ekorn's D43). Weighed: keeping the methods as shorthands over the sinks, which keeps two ways to do one thing |
| **Q16** | `count` or `to_count`? | D12: `count`, as it says what the sink is, not where the result goes |
| **Q17** | What are the other sinks called? | D14: `all_items`, `first_item`, and `only_item`, which asserts it's the only item; named for what they are, as `count` is. `to_array`, `to_arrayref` and `to_scalar` were wrongly named for these, for their containers |
| **Q18** | What gives every result in one reference, to end a `\|` chain? | D15: `to_arrayref`, a container sink. Container sinks, `to_array`, `to_arrayref`, `to_hash` and `to_hashref`, are another kind, valid beside those named for what they give |
| **Q19** | What does a call give without a sink last? | D16: the rule in section 3: DBIx::Squirrel's own calls give an iterator, the Sugar's statements included; the DBI's calls give what the DBI gives |
| **Q20** | What does `only_item` do at a second item? | D17: it warns, not croaks, and gives the first: there's a second when a SELECT forgot `LIMIT 1` |
| **Q22** | A list sink last, `all_items`, gave a count in scalar context (Ekorn's D47), so `my $rows = ... all_items` quietly gave a number | D20, from Ekorn's D51, as Iain proposed: a list sink asked for one value gives its list as an array reference, at the end of a `\|` chain too. A run with no sink still gives a count |
| **Q23** | Ekorn's sinks, imported, can clash with names in the user's package, such as a Sugar database or statement called `count`, or Test2::V0's `all_items` | D19: a test shows the Sugar's clash check catches a sink of the same name; the docs import sinks by name. Where a name clashes, call the sink by its full name, `Ekorn::Pipeline::Sinks::count()`, or through a code reference in a lexical, `my $count = \&Ekorn::Pipeline::Sinks::count;`, called as `$count->()` |
| **Q24** | Do the `select` methods take stages? | D18: yes. What the DBI gives is pushed through them: with stages, the call gives what comes out of the last stage; without, what the DBI gives |

Q9, Q10 and Q14, about a result sink of DBIx::Squirrel's own, were
dropped as moot by D11, which leaves it none.

## 14. Where each roadmap item lands

| Item | Here | What becomes of it |
|---|---|---|
| 2026-0003, add-on stage distributions | 3 | unchanged; those needing no database may go to Ekorn |
| 2026-0009, export `pipeline` | 9 | not needed: users import `pipeline` from Ekorn::Pipeline::Factories. Drop it |
| 2026-0010, a `pipeline` key in Sugar | 8 | becomes names in a statement's definition (Ekorn's D36) |
| 2026-0011, Ekorn's `install_sub` and `is_name` | 8 | not needed: the Sugar keeps its own (Ekorn 10). Drop it |
| 2026-0012, `insert_into` | 7 | dropped (Q11) |
| (new) | 6 | runs ending in Ekorn's sinks; `all`, `single` and `count` gone |
| (new) | 4 | the iterator as a source, Context over `run_context()`, the facades gone: the v3.0.0 work |

## 15. Knock-on effects on other documents

- **README:** the synopsis gains a `|` chain; Acknowledgements say what
  Claude did in this work.
- **Reference:** `DBIx::Squirrel::Pipeline` goes, and its examples use
  `Ekorn::Pipeline->new`; the iterator's section says it's a source,
  with `ekorn_source`, `ended`, `|` and `@{}`; Context says where each
  function works; Stages say they're objects; `all`, `single` and `count` are sinks, given last;
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
