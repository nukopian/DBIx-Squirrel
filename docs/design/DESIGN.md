# DBIx::Squirrel on Ekorn as it is: the design

**Status:** a draft for review, from task 3 in `TODO.md`, with its
decisions in [record 2026-0013](../changes/2026-0013-one-design.md).
It waits on Iain's approval, together with Ekorn-Pipeline's design,
before either is split into roadmap items. Its questions are numbered
**Q1** and on, in section 13, and all are settled.

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
`keep_all` or `count_items`, or in the iterator's `all`, `first` and
`single`, which take what's left of a run, as Ekorn's iterator's do;
its `count` goes. That breaks code, which v3.0.0 is for: it's
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

my $top = $sth->iterate(1990) | pluck('name') | take(5) | keep_all;
my $n   = $sth->iterate | stage { $_->[1] } | count_items;
```

## 4. A statement as a source

### 4.1 The iterator offers `ekorn_source`

`DBIx::Squirrel::Iterator` is what users hold, from `$sth->iterate`
and the like. It offers `ekorn_source` (Ekorn's D44 and D49), so it can be
given wherever Ekorn takes a source:

- **Its set-up executes the statement,** with the iterator's bind
  values, and reads the column names before the first fetch.
- **Its step fetches,** from a buffer of the run's own, in batches that
  grow, as version 1's did (Q26, settled): the first is 2 rows, the
  least that tells whether there's a second, so `first` and `single`
  read no more than they need; each fetch that fills its batch doubles
  the next, up to 64. Today's fixed batch of 100 goes. The step gives
  one row at a time, so the row the source gave last, which
  `result_original` reads, is the row being worked on (section 5),
  but for one case (Q31, settled): with no stages of the iterator's
  own, and no pipeline reading it, nothing asks which row a value came
  from, and the step gives the whole batch, which costs less. That
  serves `next` and `$it->all`.
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

### 4.4 `next`, `all`, `first`, `single` and `reset`; `count` goes

The iterator's methods are rebuilt over the same source:

- `next` pulls from the run, starting one if none is going.
- `reset` ends the run, if one is going, and keeps the bind values and
  stages given, as now. It clears everything the run held (Q29,
  settled): a value Ekorn's iterator holds, the source's batch, which
  starts again at 2 rows, the row `result_original` reads, and the
  count `result_number` keeps. The handle is finished. A fresh run
  started any other way, by a sink or by `|` (4.3), clears the same.
- A new `ended` gives what Ekorn's iterator says about how the run
  ended: `done`, `stopped` or `died`.

- `all`, `first` and `single` take what's left of the run, as Ekorn's
  iterator's do (Ekorn's D59 and D60; Q15, revised): `all` every
  result still to come, as a list, or an array reference where one
  value is asked for; `first` the next result, or `undef`, ending the
  run; `single` the next result, or `undef`, looking one ahead and
  warning "Expected only one item, but there were more" if there's
  another. Iain: "The iterator is getting single back. And all. And
  first." They're Ekorn's, through the Ekorn iterator inside, with no
  lookahead of DBIx::Squirrel's own (Q25, settled), and `next` pulls
  through that iterator too, even with no stages.
- **`single` then finishes the run, as `first` does** (Q28, settled),
  so the handle is finished, and a SELECT that forgot `LIMIT 1` holds
  no lock, as an active statement does on SQLite. Ekorn's own
  `single` keeps its iterator open, holding the value it looked at
  (Ekorn's D60); DBIx::Squirrel's calls it, then finishes the Ekorn
  iterator, which drops that value.
- **`all` has a fast path** (Q27, settled). With no stages, it tells
  its source to give every row left in one step: what's in the batch,
  and the rest with one `fetchall_arrayref`, as today's `all` does.
  Ekorn's protocol allows it, as a source's step returns "the next
  value or values", so `all` is still Ekorn's: it collects them, the
  next pull finds none, and the run ends `done`, its end told so. With
  stages, rows go one at a time, so `result_original` reads the row
  being worked on; with none, nothing reads it.

`count` goes (Q15). Counting is a stage's or a sink's job (section 6).

An iterator that's let go ends its run, through Ekorn's iterator's
`DESTROY` (Ekorn's D28), so its handle is finished. So
`my($first) = $sth->iterate->next` no longer leaves the handle active.

### 4.5 `|` and `@{}`

The iterator overloads `|` with `Ekorn::Pipeline::Operators::chain`
and `@{}` with `drain` (Ekorn's D14 and D23). They're in force only
where the user wrote `use Ekorn::Pipeline::Operators` (Ekorn's D32).

A chain ends in a sink, in the docs' examples, so it says what it
gives. `@{}` on a chain without one drains it, but reads like a
dereference of an array that isn't there. Iain: "Looks weird but you
should explain it in detail, and use more examples of alternatives"
(Ekorn's D52). So it stays, the docs lead with a sink, and the
reference and the how-to explain `@{}` in detail, as Ekorn's do:

- **Each use is a run of its own,** from the first row to the last.
  `$iterator->[0]`, `scalar @$iterator` and `$#$iterator` read every
  row to give one row, a count or an index, and two uses run the query
  twice.
- **`for (@$iterator)` reads every row before the loop starts.**
  `next`, in a `while`, gives each as it comes.
- **In `@{ chain | keep_all }`, the braces are Perl's own,**
  dereferencing the array reference `keep_all` gives.

With the alternatives, by what's wanted:

| Wanted | Write | Rather than |
|---|---|---|
| every row, as a reference | `my $rows = $it \| keep_all` | `my @rows = $it \| keep_all`, one element |
| every row, as a list | `my @rows = $sth->iterate(@binds, keep_all)`, or `@{ $it \| keep_all }` | |
| the first row | `$it \| keep_first`, fetching one | `$it->[0]`, fetching them all |
| the last row | `$it \| keep_last`, keeping only it | `$it->[-1]`, keeping every row |
| how many | `$it \| count_items` | `scalar @$it`, keeping every row |
| the first few | `$it \| keep(5)`, fetching five | `(@$it)[0 .. 4]`, fetching them all |
| each, as it comes | `while (my($row) = $it->next) {...}` | `for (@$it)`, fetching them all first |

And as `|` gives one value, a chain ending in `keep_all` gives an
array reference, even in a list assignment:

```perl
my $top = $sth->iterate | pluck('name') | take(5) | keep_all;      # the names, as a reference
my @top = @{ $sth->iterate | pluck('name') | take(5) | keep_all };  # the names
my @top = $sth->iterate | pluck('name') | take(5) | keep_all;      # one element: the reference
```

The last is a quiet trap, which the reference and the how-to warn of.
A list comes straight back without `|`, from a sink given last as an
argument: `$sth->iterate(pluck('name'), take(5), keep_all)`.

A chain run only for its sink's effect, written as a statement of its
own, runs, but Perl warns "Useless use of numeric bitwise or (|) in
void context" as it compiles the line, before any overload is called.
Neither project can stop it. The docs keep the result:
`my $n = $it | to_file($path)`.

DBIx::Squirrel loads Operators itself, with an empty import list,
`use Ekorn::Pipeline::Operators ();`, which defines `chain` and `drain`
without putting the operators in force anywhere (Ekorn 12.3). So a
user who forgot to `use` it gets Operators' own message, not
"Undefined subroutine".

### 4.6 What the build must keep

Four things the design promises that are easy to lose in the code:

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
- **A fresh run starts clean** (Q29). `reset`, or any fresh run,
  leaves nothing of the run before: no value held by Ekorn's iterator,
  no rows in the batch, a batch of 2 again, and no row or count for
  Context.

Each gets a test when it's built.

### 4.7 Results

`DBIx::Squirrel::Results` stays a subclass of DBIx::Squirrel's own
Iterator, handing out each row as an object of a class made for its
columns. That's DBIx::Squirrel subclassing itself, not Ekorn, so
nothing changes but what sections 4.4 and 4.6 change for every iterator.

### 4.8 What buffering may still need of Ekorn

Q24 to Q29 settle a statement's buffering with Ekorn's protocols as
they are. That holds for each decision, but it hasn't been shown for
them together, and four things may still need more of Ekorn (Q30,
settled below):

1. **Sinks have no fast path.** Q27's fast path is `$it->all`'s.
   `$sth->iterate(keep_all)`, `$it | keep_all` and `count_items` pull
   a row per step, so the way the docs lead with would be slower than
   the method. For its source to give every row at once there, it
   would need to know that nothing but a list sink follows it, which
   no protocol tells it.
2. **A lookahead that consumes nothing is only the iterator's.**
   Ekorn's iterator's `single` holds the value it looked at (Ekorn's
   D60), but `keep_single` and `take_single` in a pipeline pull the
   second value through the stages. A source can't say "there's more"
   without giving the value. Growing batches (Q26) make it cheap for a
   statement, but it's a gap in the protocol.
3. **A source can't be told how many its caller wants.** Its step is
   called with nothing. Growing batches cover it for now; `take(N)`
   and `keep(N)` could use it.
4. **Q25 to Q29 rest on Ekorn's behaviour, untested together:** that
   `finish` drops the value Ekorn's iterator holds; that a step
   returning many values works with its `all`; and that `ended` then
   says `done`.

**Recommended:** prove it with a spike before the design is split
into items: the statement's source with growing batches, `single`
finishing, `all`'s fast path and `reset` clearing, built against
Ekorn's working copy, with 4.6's tests, and `$it->all` timed against
`$it | keep_all` over a large result. Ask Ekorn for a protocol for 1
only if the timing shows the gap matters, and for 2 or 3 when a use
needs them.

**Settled** (Q30, D28; Iain, 2026-11-12), from the spike, whose code
and timings are in record 2026-0013:

1. **Confirmed, and wider than sinks.** On 297,848 narrow rows,
   `$it | keep_all` takes 0.81 s, and even `$it->all`, whose source
   gives every row in one step, takes 0.40 s, where version 2's took
   0.11 s: Ekorn wraps each value a step gives in an entry of its own,
   and its iterator's `all` collects them a call at a time. Ekorn is
   asked to make a step's many values cheap where nothing stands
   between the source and the end, and its iterator's `all` take them
   in bulk, which serves `$it->all`, a sink given last and `|` alike,
   and any source. DBIx::Squirrel doesn't route rows around Ekorn
   instead, which would serve `$it->all` alone. Ekorn's cost for each
   pull, which makes `next` 54% slower on narrow rows, is Ekorn's to
   profile, and isn't a protocol.
2. **Not needed.** With batches that start at 2 rows, `first` and
   `single` fetch 2, and the first row of wide rows is 20 times
   quicker than with version 2's batch of 100.
3. **Not needed,** for the same reason.
4. **Holds,** as `t/24-iterator-source.t` and Ekorn's own tests show.

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

The columns are the statement's, so `pluck` after a stage that
reshapes rows picks the wrong field, silently. The reference and the
how-to say so loudly, and show `as_hash` first, then `pluck` by name,
which uses the hash's own keys (Q21, settled).

## 6. Ending a run: Ekorn's sinks

A run ends in a sink, given as its last stage, which says what the
caller wants back (Q15, settled). The calling context no longer
decides it: `my $n = ...` and `my @rows = ...` get what the sink gives,
not a count or a list by Perl's rules. An iterator already running,
part-read with `next`, ends in its own `all`, `first` or `single`
instead, which take what's left of the run (section 4.4, D22).

The sinks are Ekorn's, as none needs a database:

| Today | In this design |
|---|---|
| `$it->all` | `keep_all`: every result, as a list; or `$it->all` still, for what's left |
| (none) | `keep_first`: the first result, stopping the run there; or `$it->first` |
| `$it->single`, which croaks at a second result | `keep_single`, or `$it->single`: the one result, with a warning if there's a second, for a SELECT that forgot `LIMIT 1`; it gives the first, and stops the run there |
| (none) | `keep_last`: the last result, reading every one to find it |
| (none) | `keep(N)`: the first N results, as a list, stopping the run once it has them |
| `$it->count`, after a drain | `count_items`, how many results there were |

Each is named for what it gives, not for what the result is put in
(Q16 and Q17, settled). Ekorn has since renamed them (its D53, D55
and D56): `count` is `count_items`, which is less likely to clash
with a caller's own `count`; and the sinks giving results are
`keep_all`, `keep_first`, `keep_single` and `keep_last`, each named
for what it keeps of what reaches it.

`keep(N)` came of Iain's asking, "So we have `take` for stages,
`keep...` for sinks" (Ekorn's D57). `$it | keep(5)` gives what
`take(5) | keep_all` does, an array reference where one value is
asked for, and fetches no more rows than it keeps. N is checked as
`take` checks it; `keep(0)` keeps nothing, and a negative N croaks.

There are no container sinks for arrays or hashes (Ekorn's D54, which
overtakes Q18). `to_array` and `to_arrayref` were `keep_all` under
other names, as it gives an array reference wherever one value is
asked for, and Perl fills a container of your own beside the call:

```perl
push @mine, @{ $it | keep_all };
my %by_id = @{ $it | stage { ($_->[0], $_) } | keep_all };
```

Ekorn's container sinks are `to_file`, and `to_fh` as designed.

`keep_all` gives a list in list context, and in scalar context the
same list as an array reference (Q22, settled, from Ekorn's D51). So
`my $rows = ... keep_all` is the rows, never a count of them, and a
`|` chain, which asks for one value, can end in `keep_all` too.
An empty result is then true, so testing for no rows takes `@$rows`,
or `count_items`.

Ekorn took these in as its D50, and built them on its
`pipeline-experimental` (e03e71958e0052dd098672f77a099b90681644e2):
`Ekorn::Pipeline::Sinks` exports `all_items`, `first_item`, `only_item`
and `count`, and the containers `to_array`, `to_arrayref` and
`to_file`. `first_value` is now `first_item`. Since then, at
fccef9cd7a3e6d18b538327d76da1983d0944832, it exports `keep`,
`keep_all`, `count_items`, `keep_first`, `keep_last`, `keep_single`
and `to_file` (Ekorn's D53 to D57). `keep_single` warns "Expected only one item, but
there were more", at the caller's line.

A function that takes stages gives a sink's result when its last stage
is one, rather than an iterator, as Ekorn's D43 allows:

```perl
use Ekorn::Pipeline::Sinks qw(keep_all keep_single count_items);

my @rows   = $dbh->iterate('SELECT * FROM artist', keep_all);
my $artist = $dbh->results('SELECT * FROM artist WHERE id = ?', 1, keep_single);
my $n      = $sth->iterate(1990, count_items);
my @top    = $sth->iterate(pluck('name'), take(5), keep_all);
my $names  = $sth->iterate | pluck('name') | take(5) | keep_all;
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

- **`keep_single` with no rows** gives what Ekorn's sinks of one value
  give, `undef`. A caller wanting nothing for no rows uses
  `keep_all`.
- **Users get the sinks from Ekorn,** as any user of Ekorn does.
  DBIx::Squirrel may re-export them (Ekorn's D31), and needs no module
  of its own for them.
- **The iterator's "how many so far"** goes with its `count` method.
  Counting is a stage's or a sink's job: `count_items`, or
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
| `::Iterator` | rows through a pipeline of its own class; `next`, `all`, `single`, `count`, `reset` | a source (section 4); its stages run by Ekorn's pipeline; `\|` and `@{}`; `next`, `all`, `first`, `single`, `reset` and `ended`, as Ekorn's iterator's (section 4.4); `count` goes |
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
| `$it->count` | fails: the method is gone | `count_items` given last (section 6), or `count_into(\$n)` as a tap |
| `my $n = $it->all`, for a count | an array reference | `count_items` given last |
| `$it->single`, after `next` | the next result, not a fresh run's one | `$it->reset->single` |
| `$it->single`, at a second result | a warning, and the first, not a croak | test for it, or keep the croak with a stage of your own |
| `my @names = artist_names sub {...}`, a Sugar statement given stages | gives an iterator, not every result | give a sink last, `keep_all` |
| a Sugar statement given stages in scalar context, for a count | gives an iterator | give `count_items` last |
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

Against a75d178, 8ce1c95, e03e719 and 89dfd3a, 25 of the 26 test files pass. `t/06-gather.t` fails
two subtests, both v0.3.0's intended changes: a gather is an object,
and its block may return a flush and an end.

Test2::V0 exports a check named `all_items`, which clashed with the
sink while it had that name (Ekorn's D50 and D54). The sink is
`keep_all` now (Ekorn's D55), so tests import it beside Test2::V0 by
its short name, with nothing left out.

The same goes for any clash between a sink and a name in the user's
package, such as a Sugar statement called `count_items` (Q23, settled). The
Sugar's clash check catches it, with a test to show it. And a user can
call the sink by its full name, or keep it in a lexical:

```perl
my $n = $sth->iterate(1990, Ekorn::Pipeline::Sinks::count_items());

my $count_items = \&Ekorn::Pipeline::Sinks::count_items;
my $m           = $sth->iterate(1991, $count_items->());
```

## 13. Questions

Each says whose it is, and recommends an answer. Settled ones keep
their numbers, with the decision in record 2026-0013.

### 13.1 Open

A question that arises, from Ekorn-Pipeline's answers or from
building, is added here, from Q33.

None, since 2026-11-12.

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
| **Q15** | Should `all`, `single` and `count` stay methods, or be sinks? | D11: sinks, Ekorn's, named in D14. The methods go in v3.0.0; `next` and `reset` stay. A call ending in a sink gives its result (Ekorn's D43). Weighed: keeping the methods as shorthands over the sinks, which keeps two ways to do one thing. Revised by D22: `all`, `single` and a new `first` come back, taking what's left of a run, as Ekorn's iterator's do (its D59 and D60); `count` stays gone |
| **Q16** | `count` or `to_count`? | D12: `count`, as it says what the sink is, not where the result goes. Ekorn named it `count_items` (its D53) |
| **Q17** | What are the other sinks called? | D14: `all_items`, `first_item`, and `only_item`, which asserts it's the only item; named for what they are, as `count` is. `to_array`, `to_arrayref` and `to_scalar` were wrongly named for these, for their containers. Ekorn named `only_item` `single_item` (its D53), then the three `keep_all`, `keep_first` and `keep_single` (its D55), each named for what it keeps; `keep_last` joined them (its D56) |
| **Q18** | What gives every result in one reference, to end a `\|` chain? | D15: `to_arrayref`, a container sink. Container sinks, `to_array`, `to_arrayref`, `to_hash` and `to_hashref`, are another kind, valid beside those named for what they give. Overtaken by Ekorn's D54, which drops all four: a chain ends `\| keep_all`, which gives a reference (D20) |
| **Q19** | What does a call give without a sink last? | D16: the rule in section 3: DBIx::Squirrel's own calls give an iterator, the Sugar's statements included; the DBI's calls give what the DBI gives |
| **Q20** | What does `only_item` do at a second item? | D17: it warns, not croaks, and gives the first: there's a second when a SELECT forgot `LIMIT 1`. It's `keep_single` now (Ekorn's D53 and D55) |
| **Q21** | `pluck` after a stage that reshapes rows reads the statement's columns, as a context describes the source (Ekorn's D46), and so picks the wrong field, silently | D21: the reference and the how-to say so loudly, and show `as_hash` first, then `pluck` by name, which uses the hash's own keys |
| **Q22** | A list sink last, `all_items`, gave a count in scalar context (Ekorn's D47), so `my $rows = ... all_items` quietly gave a number | D20, from Ekorn's D51, as Iain proposed: a list sink asked for one value gives its list as an array reference, at the end of a `\|` chain too. A run with no sink still gives a count |
| **Q23** | Ekorn's sinks, imported, can clash with names in the user's package, such as a Sugar database or statement called `count_items`, or Test2::V0's `all_items` | D19: a test shows the Sugar's clash check catches a sink of the same name; the docs import sinks by name. Where a name clashes, call the sink by its full name, `Ekorn::Pipeline::Sinks::count_items()`, or through a code reference in a lexical, `my $count_items = \&Ekorn::Pipeline::Sinks::count_items;`, called as `$count_items->()`. Test2::V0's `all_items` no longer clashes, as the sink is `keep_all` (Ekorn's D55) |
| **Q25** | Are the iterator's `all`, `first` and `single` Ekorn's, or DBIx::Squirrel's own, with `single` using the batch fetch as its lookahead? | D23: Ekorn's, through the Ekorn iterator inside. Its `single` consumes nothing (Ekorn's D60), and with no stages takes the second row from the batch already fetched; with stages, a count of rows would be wrong. The batch size stays at two or more |
| **Q26** | How many rows does a statement's source fetch at a time? | D24: as version 1 did: 2 at first, the least that tells whether there's a second, doubling each time a fetch fills its batch, up to 64. So `first`, `single` and `take(1)` fetch 2 rows, not 100, and `single`'s lookahead (Q25) is always in the first batch. Today's fixed 100 goes |
| **Q27** | `all` delegated to Ekorn pulls one row per step, losing today's one fetch of the rest | D26: a fast path, as Iain wanted. With no stages, `all` has its source give every row left in one step, which Ekorn's protocol allows, so Ekorn's `all` still collects them and the run ends `done` |
| **Q28** | Ekorn's `single` leaves its iterator open, so a statement that warned stays active, holding a lock on SQLite | D25: DBIx::Squirrel's `single` finishes the run after Ekorn's, as `first` does |
| **Q29** | What does `reset` clear? | D27: everything the run held: a value Ekorn's iterator holds, the batch, which starts again at 2, and Context's row and count. A fresh run started any other way does the same. A guarantee of 4.6, with a test |
| **Q30** | Do Ekorn's protocols support a statement's buffering, or does it need more of them? | D28, from the spike: one thing more. Ekorn is asked to make a step's many values cheap, and its iterator's `all` take them in bulk, as each value costs a wrapping and a call; a lookahead that consumes nothing and a way to tell a source how many are wanted aren't needed, as growing batches serve; the behaviour relied on holds (section 4.8) |
| **Q31** | Should a statement's source give its whole batch in a step, as each value costs Ekorn something, though `result_original` would then name the batch's last row? | D29: only with no stages of the iterator's own and no pipeline reading it, where nothing asks which row a value came from. `next` over 297,848 narrow rows then takes 0.38 s, against 0.47 s a row at a time and 0.35 s in version 2 |
| **Q32** | Should Ekorn be asked about what's left of each value's cost: a `try` and two `local`s for each stage, and the `&{}` overload on each call of an Element? | D30: about the `&{}` overload only, which every pull pays. The `try` and `local`s keep a stop or a die reported at its stage, and stay |
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
| (new) | 4.4, 6 | runs ending in Ekorn's sinks, or the iterator's `all`, `first` and `single`; `count` gone |
| (new) | 4 | the iterator as a source, Context over `run_context()`, the facades gone: the v3.0.0 work |

## 15. Knock-on effects on other documents

- **`|` gives one value, front and centre,** in the reference and the
  how-to, as Iain asked on 2026-11-12: an overloaded operator always
  returns one scalar, a limit of Perl's, so a chain ending in a list
  sink gives an array reference, and `my @rows = $it | keep_all` gets
  one element, the reference. Each says so where it first shows `|`,
  not in a note later, with the three forms that work, as in section
  4.5: `my $rows = ... | keep_all`, `my @rows = @{ ... | keep_all }`,
  and the sink given last as an argument, with no `|`. Two things go
  with it:
  - **The reference is also the cheaper form.** It's the array the sink
    built, where a list is copied out of it: over 297,848 narrow rows,
    `my $r = $it->all` took 0.136 s, and `my @r = $it->all` 0.147 s;
    over 104,082 rows, 0.101 s and 0.108 s.
  - **Postfix dereference needs parentheses.** `->` binds tighter than
    `|`, so `$it | keep_all->@*` dereferences the sink, and dies, "Not
    an ARRAY reference"; `($it | keep_all)->@*` is the list, as
    `@{ $it | keep_all }` is.
- **README:** the synopsis gains a `|` chain; Acknowledgements say what
  Claude did in this work.
- **Reference:** `DBIx::Squirrel::Pipeline` goes, and its examples use
  `Ekorn::Pipeline->new`; the iterator's section says it's a source,
  with `ekorn_source`, `ended`, `|` and `@{}`; Context says where each
  function works; Stages say they're objects; `all`, `first` and `single` take what's left of a run, and `count` goes;
  Sugar's definitions take names.
- **How-to:** about a dozen examples use `DBIx::Squirrel::Pipeline`, and
  move to Ekorn's. `@{}` on an iterator is explained in detail, with
  the alternatives in section 4.5, mirroring Ekorn's how-to. New recipes: a statement read through `|`, and rows
  collected as results.
- **`Changes`:** v3.0.0's precis names what breaks and how to move,
  from section 10.
- **CLAUDE.md:** the Ekorn version it tests against; the CI job, once
  added.
- **Roadmap:** section 14's changes, as items, once Iain approves.
- **The modules' POD:** each that changes, in the same commits.
- **`cpanfile`:** Ekorn's range, at the release.
