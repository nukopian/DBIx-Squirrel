# Messages

## From Ekorn-Pipeline, 2026-11-11: Ekorn::X is the ancestor of DBIx::Squirrel::X, and the streams don't cross

**From:** Ekorn-Pipeline c27229735709b3bd35823b682e22f526ca8dc4d5, on its branch `pipeline-experimental`

This replaces the message of 6af6d0d1cd7797086d59499aecd39d350623f1d9,
which was never read: Iain's decision has grown since, and part of
what it recommended, a subclass of Ekorn's Sugar, is now ruled out.
It was amended in place three more times before you read it: for a
subclass overriding an ancestor's named pipeline, and for how
`pipeline` and `named` calls are written in docs. Read only this
one. A task below it asks for your docs to explain the same.

Your task, to have `pipeline` make DBIx::Squirrel::Pipeline, is done.
Doing it, Iain set a rule for both repositories, which decides more
than the task.

### The rule

Iain decided on 2026-11-11, in Ekorn-Pipeline's session:

1. **Ekorn::X is the non-database ancestor of DBIx::Squirrel::X.**
   Ekorn::Pipeline is the pipeline without a database, and
   DBIx::Squirrel::Pipeline its descendant, notionally a subclass, as
   is any DBIx::Squirrel module with an Ekorn analogue. So Ekorn never
   names its own class where it makes something, but the class it was
   reached through.
2. **"Anything created in the DBIx::Squirrel:: namespace needs to
   remain there. We mustn't cross the streams."** DBIx::Squirrel
   inherits from Ekorn, one way. Ekorn never holds, finds or makes
   DBIx::Squirrel's things on its behalf.

It's in Ekorn's CLAUDE.md, and record 2026-0020,
`docs/changes/2026-0020-subclass-pipeline.md`, checks it against the
work planned in both repositories.

### What it means for you now

**`pipeline` (your 2026-0009).** Ekorn::Pipeline has an `import` of its
own, which DBIx::Squirrel::Pipeline inherits. Asked for through a
subclass, `pipeline` is a function made for that subclass:

```perl
use DBIx::Squirrel::Pipeline qw(pipeline);
pipeline('clean', take(2));    # a DBIx::Squirrel::Pipeline
```

It reads its caller when it's called, so a module that imports it and
exports it again, as your facades do, still has names looked up in
each user's package. Your Pipeline facade needs no code for it. Two
things to know:

- `@ISA` must be set before the import runs. Your facade sets it at
  run time, which is fine when a user `use`s it from another file; an
  import from a `BEGIN` block in the same file needs it at compile
  time: `use parent -norequire, 'Ekorn::Pipeline'`.
- Other names still go through Exporter with your class's own lists,
  so `use DBIx::Squirrel::Pipeline qw(is_stage)` croaks unless you list
  `is_stage`, as before. Only `pipeline` is made for the subclass.

**Named pipelines belong to a class, and are inherited one way, as
methods are.** This is rule 2 in the code, and it's new since your
test against 4eb7fa3, where one registry held every class's names, so
that a pipeline named through DBIx::Squirrel::Pipeline could be found
by Ekorn's own `pipeline`. In full:

- **Every named pipeline belongs to a class:** the class whose `named`
  defined it. `Ekorn::Pipeline->named(...)` defines a name for
  Ekorn::Pipeline. `DBIx::Squirrel::Pipeline->named(...)` defines one
  for DBIx::Squirrel::Pipeline. `$p->named(...)`, called on a pipeline,
  defines one for the pipeline's class.
- **`pipeline` looks a name up for a class too.** Ekorn's own
  `pipeline` looks it up for Ekorn::Pipeline. The one your users get
  through DBIx::Squirrel::Pipeline looks it up for
  DBIx::Squirrel::Pipeline. It looks first among that class's own
  names, then its parent's, and so on up to Ekorn::Pipeline, and takes
  the first it finds. It never looks down, among a subclass's names.
  Names given to `named` among the stages after the new name are looked
  up the same way, for the class `named` was called on.

So, for DBIx::Squirrel::Pipeline and Ekorn::Pipeline:

1. **You see Ekorn's names.** A pipeline named through Ekorn::Pipeline
   can be used by your users' `pipeline`, as your class can call
   Ekorn::Pipeline's methods.
2. **Ekorn never sees yours.** A pipeline named through
   DBIx::Squirrel::Pipeline can't be found by Ekorn's own `pipeline`,
   which croaks "No pipeline named main::clean". Your names never
   reach a program's plain Ekorn pipelines.
3. **You can override one of Ekorn's names,** by defining the same
   name for your class. From then on, your class and any subclass of
   it get your pipeline for that name; Ekorn::Pipeline, and anything
   looking names up for it, still get Ekorn's. Ekorn can likewise
   define a name you already have, and each class keeps its own.
4. **A class can't define the same name twice.** That croaks: "A
   pipeline named main::clean is already defined". Overriding is
   defining a name for a different class, so it isn't defining it
   twice.
5. **Overriding doesn't change a pipeline already made.** A name is
   looked up when a pipeline is made, so a pipeline made before your
   override keeps Ekorn's. Define names before using them, as a
   program usually does at its start, and as your Sugar will at
   compile time, so every pipeline finds the same.

This example, from Ekorn's reference, runs as its comments say, with
My::Pipeline standing for DBIx::Squirrel::Pipeline:

```perl
package My::Pipeline { use parent -norequire, 'Ekorn::Pipeline' }

package main;
BEGIN { My::Pipeline->import(qw(pipeline)) }    # here, pipeline makes My::Pipelines

Ekorn::Pipeline->named(tidy => sub { lc });     # Ekorn::Pipeline's name
My::Pipeline->named(loud => sub { uc });        # My::Pipeline's name

say pipeline('tidy')->('Hi');                   # hi     (the subclass sees its ancestor's name)
say pipeline('loud')->('Hi');                   # HI     (and its own)
say eval { Ekorn::Pipeline::pipeline('loud') } ? 'found' : 'not found';
                                                # not found  (the ancestor never sees the subclass's)

my $made_before = pipeline('tidy');
My::Pipeline->named(tidy => sub { ucfirst lc });    # the subclass overrides tidy

say pipeline('tidy')->('hI');                   # Hi     (the subclass now gets its own)
say Ekorn::Pipeline::pipeline('tidy')->('hI');  # hi     (the ancestor keeps its own)
say $made_before->('hI');                       # hi     (a pipeline made earlier keeps what it found)
```

So for your users: define named pipelines through
`DBIx::Squirrel::Pipeline->named`, and look them up with the `pipeline`
your facade exports. Ekorn's reference has the same rules, under
"Named pipelines and subclasses", and Ekorn's record 2026-0020 has the
decisions, D4 and D5.

**Pipes.** `Ekorn::Pipeline::Pipes` has `pipeline_class`, which `pipe`
and `tap` ask. Your Pipes facade can override it to make your own:
`sub pipeline_class ($self) { 'DBIx::Squirrel::Pipeline' }`.

**Stop.** `Stop()` throws Ekorn::Pipeline::Stop, though your facade
exports it from DBIx::Squirrel::Stop, your subclass. It's a one-line
wrapper over `throw`, a class method, so define your own,
`sub Stop (@values) { __PACKAGE__->throw(@values) }`, if your subclass
ever needs to be what's thrown. Nothing changes until then.

### How `pipeline` and `named` are written

Iain decided on 2026-11-11 how calls to the two are written in docs
and examples, and Ekorn's POD, reference, how-to and `Changes` now
follow it:

- **`pipeline` takes plain commas between its stages:**
  `pipeline('clean', take(5))`, `pipeline(sub { uc }, take(5))`. Never
  `pipeline('clean' => take(5))`. In Iain's words, the long comma "gives
  the wrong impression when a name is on the left and a function is on
  the right": it reads as a key and its value, when the name and the
  function are both stages in a list.
- **`named` keeps the long comma:**
  `DBIx::Squirrel::Pipeline->named(clean => sub {...})`. There "the
  long comma is giving the correct impression": the name labels the
  stages that follow.
- Hashes keep the long comma, as Sugar's import lists do.

Please write yours the same way, in docs, examples and tests, so the
two projects read alike.

### What it means for your plans

**A `pipeline` key in your Sugar (your 2026-0010).** Your Sugar
defines its own pipelines, with `DBIx::Squirrel::Pipeline->named`,
qualifying each name with its caller's package. It doesn't hand them
to Ekorn's Sugar's `import_into`, as Ekorn's 2026-0010 D6 had it: that
would have Ekorn make and hold your pipelines, crossing the streams.
Ekorn's Sugar makes only Ekorn::Pipelines (its 2026-0010, D10). If
you want Ekorn's ordering of definitions and its cycle check, they
can be a function that makes nothing, which your Sugar calls before
defining its own; send a message if you do. Your 2026-0010's text,
"handed on to Ekorn::Pipeline::Sugar's `import_into`", no longer
holds.

**Ekorn's install_sub and is_name (your 2026-0011).** Unaffected:
they're functions that make nothing.

**A database as a sink (your 2026-0012).** Unaffected: `insert_into`
is built from Ekorn's sink, in your namespace.

**Ekorn's later items.** Its Blocks (2026-0015) will make each type
with a class method, so you can wrap your own, and its operators
(2026-0018) will make the class of their operand, so your pipelines
chain as yours.

It all only adds, so it's still a v0.2.x within your range.

# Planned work

## 1. Explain named pipelines and subclasses in DBIx::Squirrel's docs

**From:** Ekorn-Pipeline's session, 2026-11-11 (Ekorn-Pipeline
707adba84faf726ec36162652b3d7453df98e447, on its branch
`pipeline-experimental`)
**Waiting on:** your 2026-0009, which exports `pipeline`

**What:** when your docs first show `pipeline` and named pipelines,
spell out in plain English, and in the same detail as the message
above, how names behave for DBIx::Squirrel's users: that they define
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

Write the calls as the message says: `pipeline('clean', take(5))`,
with plain commas, and `named(clean => sub {...})`, with the long
comma.

**Done when:** your reference, and your how-to's recipe for named
pipelines if it has one, explain the five rules with an example that
runs as its comments say, with `pipeline` and `named` calls written as
above; and your Ekorn manual links point to Ekorn's "Named pipelines
and subclasses" for the rest.

