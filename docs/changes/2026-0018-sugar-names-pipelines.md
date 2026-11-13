# 2026-0018. Pipelines named in the Sugar's definitions

**Status:** shipped, unreleased, on `pipeline-experimental`

**Decisions:** None open. The design's section 8, approved with it on
2026-11-13, and Ekorn's D36: a definition's strings after the statement
are pipelines' names, resolved with Ekorn's `pipeline_in` in the
package that made the definition; a string given when a statement is
called is a bind value.

**Origin:** split from [2026-0013](2026-0013-one-design.md), the design
Iain approved on 2026-11-13. It replaces 2026-0010, retired into it.

**Started:** 2026-11-13

**Finished:** 2026-11-13

## Background

Ekorn::Pipeline names pipelines, per package, with `named`, and
resolves names with `pipeline_in`, the method its `pipeline` word
calls. DBIx::Squirrel::Sugar's statement definitions take stages after
the statement, but only code references and pipelines. 2026-0010 had
proposed a `pipeline` key of the Sugar's own; names are Ekorn's, so the
Sugar uses them instead.

## Decisions

None of its own, as above.

## The plan

**What:**

- In a statement's definition, on `use` or with `statement`, a string
  after the statement and its attributes is a pipeline's name. With
  any names, the stages are resolved as the definition is made, with
  `Ekorn::Pipeline->pipeline_in($package, @stages)`, in the package
  that made it, into one pipeline. Without, they're kept as now.
- Anything else, neither a stage nor a string, croaks, the message
  naming names as well: "Expected only code references, pipelines or
  their names after the statement for %s". A name not defined croaks
  with Ekorn's message, at the definition's line.
- When a statement is called, its arguments are bind values, then
  stages, as now: a string there is a bind value, never a name.
- The reference's entry for "Pipeline stage #%s failed" shows the name
  of a named pipeline, as Ekorn's 2026-0013 gives it.

**Why:** names are Ekorn's, so the Sugar uses them rather than defining
pipelines itself.

**Steps:** the definition; tests of names on `use` and at run time, of
a name not defined, of a string at the call staying a bind value, and
of a named pipeline's stage dying; the reference, the how-to and the
POD; `Changes`.

**Done when:** a definition's names resolve; a string given when a
statement is called stays a bind value; the docs show it, with the
named form of "Pipeline stage #%s failed"; every test passes against
Ekorn's working copy; and coverage meets its floors.

## What happened

- **2026-11-13, outcome:** as planned, against Ekorn's working copy at
  fd541c497274676cb068f5aabccf12810381fead, on its
  `pipeline-experimental`. Every test passes there, against SQLite,
  MySQL 8.4 and PostgreSQL 18; coverage meets its floors. Tests in
  `t/16-sugar.t`: names on `use`'s timing and at run time, per
  package and qualified, a name not defined, a string that isn't a
  name, a string at the call staying a bind value, and a named
  pipeline's stage dying. The how-to's new example prints what its
  comment says.
- **Changed from the plan: each name is resolved on its own,** with
  `pipeline_in($package, $name)`, not all the stages at once, so the
  other stages keep their places in a message: a code reference
  given first stays `#1`. Ekorn's `pipeline_in` gives a pipeline
  holding the named one, so a named pipeline's stage is `#2.1.2
  (main::fussy#2)`, a level deeper than its place in the definition,
  as `pipeline('fussy')` gives it too. Ekorn is told.
- **Changed from the plan: the Sugar checks a name's form itself,**
  words joined by `::`, as Ekorn's are. A string that isn't one gets
  the Sugar's message, as anything else does, rather than Ekorn's
  "Expected stage #1 to be ...", whose number would be the name's
  place in a pipeline of its own, not in the definition.
- **What's left:** nothing of this item.
