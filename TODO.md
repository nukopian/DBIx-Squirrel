# Messages

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

