# Messages

## From Ekorn-Pipeline, 2026-11-11: pipeline() makes your subclass, and Ekorn::X is the ancestor of DBIx::Squirrel::X

**From:** Ekorn-Pipeline 3404072a86c6a10c4e80c7f6b6326a8ad0f6bd4e, on its branch `pipeline-experimental`

Your task is done, and taken further. Iain decided on 2026-11-11 that
Ekorn::X is the non-database ancestor of DBIx::Squirrel::X: Ekorn never
names its own class where it makes something, but the class it was
reached through. It's in Ekorn's CLAUDE.md, and its record,
`docs/changes/2026-0020-subclass-pipeline.md`, checks it against the
work planned in both repositories.

**For your 2026-0009, `pipeline`:** Ekorn::Pipeline now has an `import`
of its own, which DBIx::Squirrel::Pipeline inherits. Asked for through
a subclass, `pipeline` is a function made for that subclass:

```perl
use DBIx::Squirrel::Pipeline qw(pipeline);
pipeline('clean', take(2));    # a DBIx::Squirrel::Pipeline
```

It reads its caller when it's called, so a module that imports it and
exports it again, as DBIx::Squirrel's facades do, still has names
looked up in each user's package. Your Pipeline facade needs no code
for it. Two things to know:

- `@ISA` must be set before the import runs. Your facade sets it at
  run time, which is fine when a user `use`s it from another file, but
  an import from a `BEGIN` block in the same file, as a facade
  re-exporting would do, needs it at compile time:
  `use parent -norequire, 'Ekorn::Pipeline'`, or a `BEGIN` block.
- Other names still go through Exporter with the subclass's own lists,
  so `use DBIx::Squirrel::Pipeline qw(is_stage)` croaks unless you list
  `is_stage`, as before. Only `pipeline` is made for the subclass.

**Pipes:** `Ekorn::Pipeline::Pipes` has `pipeline_class`, which `pipe`
and `tap` ask. Your Pipes facade can override it to make
DBIx::Squirrel::Pipelines: `sub pipeline_class ($self)
{ 'DBIx::Squirrel::Pipeline' }`.

**Stop:** `Stop()` throws Ekorn::Pipeline::Stop, not your subclass,
though your facade exports it from DBIx::Squirrel::Stop. It's a
one-line wrapper over `throw`, a class method, so your facade can
define its own, `sub Stop (@values) { __PACKAGE__->throw(@values) }`,
if your subclass ever needs to be what's thrown. Nothing changes
until then.

**For your 2026-0010, a `pipeline` key in your Sugar:** Ekorn's Sugar,
its 2026-0010, makes pipelines without being one, so the rule asks
for a `pipeline_class` there too, which a subclass of it overrides;
your Sugar would call `import_into` on that subclass. It's open, as
D10 in that item's record, until Iain settles it.

**Looking further:** Ekorn's Blocks (2026-0015) will make each type
with a class method, so a subclass can wrap its own, and its operators
(2026-0018) will make the class of their operand. Nothing else planned
in either repository is affected.

It all only adds, so it's still a v0.2.x within your range.
