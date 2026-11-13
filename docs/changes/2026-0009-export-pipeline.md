# 2026-0009. Export Ekorn's pipeline()

**Status:** dropped, on 2026-11-13

**Decisions:** D1 settled: Ekorn's `pipeline` makes our subclass,
asked of Ekorn in a task. D2 settled: our `pipeline` goes in
DBIx::Squirrel::Factories, one line over an inherited class method.

**Origin:** roadmap, added 2026-11-10, from a message from
Ekorn-Pipeline's session (Ekorn-Pipeline
7679466a4edff604713af01bbf6bb6d7cc208709)

**Depends on:** Ekorn-Pipeline 2026-0011, 2026-0020 and 2026-0021

## Background

Ekorn-Pipeline built its 2026-0011 on its `pipeline-experimental`, in
4eb7fa3ac1b16ceb92c1992249897174f519c338, and said so in a message on
2026-11-11: `pipeline(@stages)` makes a pipeline whose stages can be
names, and `named` gives a pipeline a name, kept in the caller's
package unless it's qualified.

On 2026-11-11, on this repository's `pipeline-experimental`, every test
passed against Ekorn's working copy at that commit: 26 files, 1,585
assertions, `xt/` included. None of them uses the new functions yet,
so a script tried them through DBIx::Squirrel:

- `pipeline('names', take(2))` works as a stage of `iterate` and of
  `pipe`.
- A bind value `'names'` stays a bind value, though a pipeline has
  that name.
- `DBIx::Squirrel::Pipeline->named(...)` makes a
  `DBIx::Squirrel::Pipeline`, as `named` calls `new` on its invocant.
- A qualified name works from another package, and an unqualified one
  dies there with "No pipeline named Other::names", as Ekorn's D5 has
  it.

But `pipeline` always makes an `Ekorn::Pipeline`, as it calls
`__PACKAGE__->new`, so a pipeline made with it is never
DBIx::Squirrel's subclass. A function of DBIx::Squirrel's own can't
fix that: `pipeline` looks names up in the package that called it, so
a wrapper would look them up in its own package, and the lookup,
`_resolved`, is Ekorn's private function. Nothing differs yet, as the
subclass changes nothing, but it's where DBIx::Squirrel changes how
its pipelines behave.

### What Ekorn's messages of 2026-11-11 settled

Ekorn's session did the task (its 2026-0020), and sent three messages
on 2026-11-11 (Ekorn-Pipeline c27229735709b3bd35823b682e22f526ca8dc4d5
and ab5c829b930ddf8c4ba56285a57ca86d76fa1001, on its
`pipeline-experimental`). In them, Iain set a rule for both
repositories:

1. **Ekorn::X is the non-database ancestor of DBIx::Squirrel::X,**
   notionally its parent class, so Ekorn makes the class it was
   reached through, never its own by name.
2. **"Anything created in the DBIx::Squirrel:: namespace needs to
   remain there. We mustn't cross the streams."** DBIx::Squirrel
   inherits from Ekorn, one way, and Ekorn never holds, finds or makes
   DBIx::Squirrel's things.

So named pipelines belong to a class, and are inherited one way, as
methods are. For DBIx::Squirrel's users:

1. **They see Ekorn's names.** Their `pipeline` looks a name up for
   DBIx::Squirrel::Pipeline, then its parent, nearest first.
2. **Ekorn never sees theirs.** A pipeline named through
   `DBIx::Squirrel::Pipeline->named` isn't found by Ekorn's own
   `pipeline`, which croaks "No pipeline named main::clean". A name is
   qualified by a package and seen by a class: two separate things.
3. **They can override one of Ekorn's names,** by defining it for
   DBIx::Squirrel::Pipeline; Ekorn::Pipeline keeps its own.
4. **A class can't define a name twice:** "A pipeline named
   main::clean is already defined". `named` on a class always makes a
   new pipeline, so it croaks even given the same one twice;
   `$p->named('clean')` twice doesn't. Names can't be removed.
5. **Overriding doesn't change a pipeline already made,** as a name is
   looked up when a pipeline is made. Define names first, at load
   time.

Also:

- **How calls are written,** in docs, examples and tests, as Iain
  decided: `pipeline('clean', take(5))`, with plain commas, as the name
  and the function are both stages; `named(clean => sub {...})`, with
  the long comma, as the name labels the stages after it.
- **`pipe` and `tap` don't read names:** `$sth->pipe('clean')` croaks;
  `$sth->pipe(pipeline('clean'))` works.
- **Pipes:** Ekorn::Pipeline::Pipes has `pipeline_class`, which `pipe`
  and `tap` ask, so DBIx::Squirrel::Pipes can override it to make
  DBIx::Squirrel::Pipelines.
- **Stop:** `Stop()` throws Ekorn::Pipeline::Stop. Define
  `sub Stop (@values) { __PACKAGE__->throw(@values) }` in
  DBIx::Squirrel::Stop only if the subclass ever needs to be what's
  thrown.
- **2026-0010:** DBIx::Squirrel::Sugar defines its pipelines itself,
  with `DBIx::Squirrel::Pipeline->named`, rather than handing them to
  Ekorn's Sugar, which makes only Ekorn::Pipelines.

Ekorn's reference has the same rules, with an example, under "Named
pipelines and subclasses", and its record 2026-0020 the decisions.

The last message paused this item: `pipeline` leaves Ekorn::Pipeline
for Ekorn::Pipeline::Factories, Ekorn's 2026-0021, so what the earlier
two said about getting it through the subclass's `import` no longer
applies.

A fourth, on 2026-11-11 (Ekorn-Pipeline
d1ecb45c613e526292964b8d78b6d258ff794aa7), paused all of DBIx-Squirrel's
work touching Ekorn, as Iain asked, until one design for both
repositories, Ekorn's 2026-0022, is approved. All of the above is
provisional until then, Ekorn::Pipeline::Factories included.

## Decisions

- [x] **D1.** Export Ekorn's `pipeline` as it is, making
  `Ekorn::Pipeline`s, or wait until it can make DBIx::Squirrel's
  subclass? Ekorn should make our subclass, Iain decided on
  2026-11-11, so that every pipeline DBIx::Squirrel's users make is
  DBIx::Squirrel::Pipeline, as the facade means. Asked of Ekorn in a
  task in its `TODO.md`, on its `pipeline-experimental`; how it does it
  is Ekorn's to design. Ekorn did it in its 2026-0020, which D2
  overtook.
- [x] **D2.** Where does DBIx::Squirrel's `pipeline` come from? From
  DBIx::Squirrel::Factories, Iain decided on 2026-11-11, in
  Ekorn-Pipeline's session, following the mapping of
  `Ekorn::Pipeline::X` to `DBIx::Squirrel::X`: each word one line over
  DBIx::Squirrel::Pipeline's inherited class method, passing its
  caller's package, so it makes the subclass with no `import` of its
  own. `pipeline` is syntax, not behaviour, so it leaves the class for
  a module of words to import, the first of the family Ekorn's
  2026-0015 adds. The class method's name is Ekorn's 2026-0021's to
  choose. Work waits on a message saying 2026-0021 is built.

## The plan

Written when work starts.

## What happened

Nothing yet.
- **2026-11-13:** dropped, as the design both repositories share, which
  Iain approved, has it (DBIx-Squirrel 2026-0013, its section 14).
  DBIx::Squirrel uses Ekorn as it is, so it makes no `pipeline` of its
  own, and no DBIx::Squirrel::Factories: its users import `pipeline`
  from Ekorn::Pipeline::Factories, and name pipelines with Ekorn's
  Sugar or `named`. D1 and D2, which planned the export over a
  subclass, are overtaken by that design's D1, which drops the
  subclass.

