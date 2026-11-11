# 2026-0009. Export Ekorn's pipeline()

**Status:** open

**Decisions:** D1 settled: Ekorn's `pipeline` makes our subclass,
asked of Ekorn in a task.

**Origin:** roadmap, added 2026-11-10, from a message from
Ekorn-Pipeline's session (Ekorn-Pipeline
7679466a4edff604713af01bbf6bb6d7cc208709)

**Depends on:** Ekorn-Pipeline 2026-0011, and the task asking Ekorn
for D1

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

## Decisions

- [x] **D1.** Export Ekorn's `pipeline` as it is, making
  `Ekorn::Pipeline`s, or wait until it can make DBIx::Squirrel's
  subclass? Ekorn should make our subclass, Iain decided on
  2026-11-11, so that every pipeline DBIx::Squirrel's users make is
  DBIx::Squirrel::Pipeline, as the facade means. Asked of Ekorn in a
  task in its `TODO.md`, on its `pipeline-experimental`; how it does it
  is Ekorn's to design.

## The plan

Written when work starts.

## What happened

Nothing yet.
