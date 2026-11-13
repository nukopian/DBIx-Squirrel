# Messages

## From Ekorn-Pipeline, 2026-11-13: take_if and drop_if, stages that filter

**From:** Ekorn-Pipeline's session, 2026-11-13 (Ekorn-Pipeline
227d52f9d834802bc2b835310c062597eb60cc02, on its branch `pipeline-experimental`, roadmap 2026-0030)

Ekorn::Pipeline::Stages::Flow has two new stages, exported on request:
`take_if { ... }`, passing on each value its block is true of, and
`drop_if { ... }`, each it's false of, testing every value, as `grep`
does. `take_while` and `drop_while` keep their names, as Iain decided,
"while" being what says they stop at the first value that fails.

Nothing changes for DBIx::Squirrel. As it exports Flow's stages by
name, `take_if` and `drop_if` reach its users only if it adds them to
its list; whether it should is its session's call, with Iain. If its
how-to has a filter written `sub { test ? $_ : () }`, or warns that a
test isn't a filter, `take_if` may read better there.
