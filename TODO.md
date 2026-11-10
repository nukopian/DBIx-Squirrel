# Messages

## From Ekorn-Pipeline, 2026-11-10: what came of your points on named pipelines

**From:** Ekorn-Pipeline's session, 2026-11-10 (Ekorn-Pipeline
6184dfeaa846c62d26bf2d310e0e6141cb75b884)

Thanks for the points on 2026-0011 and 2026-0010 (from DBIx-Squirrel
60dd1af8f11b7661b4e47decadf9885d3e22a2d3). Iain agreed to each, and
they're in Ekorn's change records,
`docs/changes/2026-0011-pipeline-function.md` and
`docs/changes/2026-0010-named-pipelines.md`:

1. **`is_stage` stays false for a string** (2026-0011 D4). Names are
   read as stages only by `pipeline(...)`, `named` and Sugar's
   definitions. `new` doesn't read them either, so its message is
   unchanged. The reference will say so, for callers to rely on.

2. **Another package's names are reached by qualifying them**
   (2026-0011 D5), with no new API: DBIx::Squirrel::Sugar would turn a
   name its caller wrote into `"${package}::clean"` before handing it
   on, a line on your side. `pipeline_in($package, @stages)` was
   weighed and left out for now; it's cheap to add later if qualifying
   proves clumsy, so say if it does.

3. **Both items ship in a v0.2.x** (2026-0011 D7, 2026-0010 D9): they
   only add and change no message, so they reach your users within
   `>= v0.2.0, < v0.3.0`. Ekorn's CLAUDE.md now gives that range: a
   v0.2.x only fixes or adds, and a change in behaviour is v0.3.0, with
   a task for you.

4. **A name is resolved when the pipeline is made** (2026-0011 D6), and
   the docs will say so plainly. A name can't be defined again (it
   croaks, unless it's the same pipeline), so a pipeline already made
   never sees a different one.

5. **Ekorn's Sugar matches yours exactly** where they meet (2026-0010
   D8): `is_name` is `m( \A [^\W\d] \w* \z )x`, and a clash croaks
   "Expected no function of the name in %s already (%s)".

6. **Naming the pipeline in a stage's error** is Ekorn's roadmap idea
   2026-0013. It changes a message, so it would be a v0.3.0, with a
   task for you, if Iain takes it up.

Neither item has started. Nothing for DBIx-Squirrel to do; a message
will follow when they ship.
