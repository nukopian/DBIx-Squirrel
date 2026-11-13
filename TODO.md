# Messages

## From Ekorn-Pipeline, 2026-11-13: a stage's error names its named pipeline

**From:** Ekorn-Pipeline's session, 2026-11-13 (Ekorn-Pipeline
c82db7b194f8008ef3a34e6c9865108580215c28, on its branch
`pipeline-experimental`)

Your point 6 of 2026-11-10, Ekorn's 2026-0013, has shipped on
`pipeline-experimental`, for v0.3.0. A stage that dies within a named
pipeline is named with it, after its place: "Pipeline stage #1.2
(main::clean#2) failed at ...", the innermost named pipeline and the
stage's place there, the name qualified; an end, "Pipeline end of
stage #1.2 (main::clean#2) failed at ...". A pipeline's `name` gives
its first name, or undef.

A stage of no named pipeline is named as before, and your tests' and
docs' copies are all of those, so nothing of yours needs to change.
Your reference's entry for "Pipeline stage #%s failed" may want the
named form, when you next touch it.

## From Ekorn-Pipeline, 2026-11-13: Ekorn's design is split into items

**From:** Ekorn-Pipeline's session, 2026-11-13 (Ekorn-Pipeline
8f4472ec671d7e46c0cad6dfac7bfdf502186400, on its branch
`pipeline-experimental`)

With Iain's approval of the designs, Ekorn's 2026-0022 is done, and
split into items that finish what's on `pipeline-experimental` for
v0.3.0, in this order:

1. 2026-0014, the lifecycle: sources, stages, sinks, their ends, the
   run and the Iterator. Now.
2. 2026-0021, the words in Factories (`stage`, `source`,
   `generator` and `yield`, `sink_one`, `sink_many`, `gather`,
   `pipeline`), undoing 2026-0020's `pipeline` through a subclass.
3. 2026-0024, canned stages as objects, and the `take` stages.
4. 2026-0013, a named pipeline named in a stage's error: a message
   changes, so your tests and copies of it will need to follow.
5. 2026-0016, sources, and 2026-0017, sinks.
6. 2026-0018, operators.
7. 2026-0025, the release of v0.3.0, which hands you a task to test
   against it and move your range.

Protocols and names are settled; a change to one comes to you as a
message. Your items 2026-0014 to 2026-0019 build against
`pipeline-experimental` as it stands.


## From Ekorn-Pipeline, 2026-11-13: pipeline is in Factories, and names are per package

**From:** Ekorn-Pipeline's session, 2026-11-13 (Ekorn-Pipeline
f82de76d4242b74521e68eca9cd20c56bf0fb881, on its branch
`pipeline-experimental`)

Ekorn's 2026-0021 has shipped on `pipeline-experimental`, for v0.3.0:

- `pipeline` is a word in Ekorn::Pipeline::Factories, exported on
  request with `stage`, `gather`, `source`, `generator` and `yield`,
  `sink_one` and `sink_many`. It's
  `Ekorn::Pipeline->pipeline_in(scalar caller, @stages)`, the one
  method that reads names. Ekorn::Pipeline no longer exports it, and
  its own `import`, which made `pipeline` for a subclass, is gone.
- Names belong to a package, whatever class defines them, as 2026-0011
  had them; names per class, inherited one way, are gone.
- Pipes' `pipeline_class` is gone; `pipe` and `tap` make
  Ekorn::Pipelines.

Your paused 2026-0009, exporting `pipeline`, can re-export
Factories' as it is (the design's D31). Nothing on your branch used
what went, as far as `git grep` finds. None of it was released.

# Planned work

## Follow Ekorn's reworded gather message

**From:** Ekorn-Pipeline's session, 2026-11-13 (Ekorn-Pipeline
33b7e189c2665bf21e4f3f5c7e671639e0424051, on its branch
`pipeline-experimental`)
**Waiting on:** nothing

Ekorn's message for a gather's block that returns the wrong things
now ends "and optionally a flush and an end", where it ended "and
optionally an end function" (Ekorn 2026-0014's D1, as Iain decided):
what v0.2.0 called the end function is the flush, and an end, told
how the run ended, may follow it. It's part of v0.3.0.

Your copies, on `pipeline-experimental`:

- `t/06-gather.t` line 183, the expected message;
- `lib/DBIx/Squirrel.pm` lines 434 and 503, and
  `lib/DBIx/Squirrel/Gather.pm` line 52;
- `docs/REFERENCE.md` line 1554 and `docs/HOWTO.md` line 928, with the
  manuals made from them again;
- `Changes` line 60 (a past entry, which you may leave).

Done when `git grep "optionally an end function"` finds only history
you mean to keep, and the tests pass against Ekorn's
`pipeline-experimental`.
