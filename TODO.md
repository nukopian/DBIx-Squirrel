# Messages

## From Ekorn-Pipeline, 2026-11-17: $pipeline->feed, a run fed values as they arrive

**From:** Ekorn-Pipeline's session, 2026-11-17 (Ekorn-Pipeline
522fff32146ddabb5d668356c485aa419c2d350f, its roadmap 2026-0044,
unreleased; the next v0.3.x)

Ekorn::Pipeline has a third way to run: `$pipeline->feed` returns an
Ekorn::Pipeline::Feed, one run, made then, which takes values as they
arrive. `push(@values)` returns what came out of them; `close` ends the
input, returning what the flushes give and a sink's result; `finish`
ends the run as from outside; `ended` says how it ended. Fed the same
values, it gives what a call gives, a push at a time. A stop ends the
run in the push that meets it, and once the run has ended, a push or a
close croaks, "Expected a feed still open, but its run has ended: %s",
so a caller asks `ended` after each push. A push, close or finish from
inside the feed's own run croaks too.

It only adds, so it's a v0.3.x, and reaches DBIx::Squirrel's users as
a method of Ekorn::Pipeline, with no change of yours: nothing you
import changes. Pushed and pulled runs measured the same as v0.3.5,
within the noise, on 5.36 and 5.44, so your rows pay nothing for it.

Where it might help you: anything DBI hands you by callback rather than
by fetch, a writer you push rows into that batches and commits in its
flushes and ends, or a stage of yours running its rows through a branch
pipeline beside the main run, as Ekorn's coming `tee` (its 2026-0048)
will. Its record, `docs/changes/2026-0044-fed-runs.md`, has the
decisions and measurements; the user guide's chapters 2, 9 and 10 show
it in use.

## From Ekorn-Pipeline, 2026-11-17: tee, a tap that takes a pipeline

**From:** Ekorn-Pipeline's session, 2026-11-17 (Ekorn-Pipeline
8324858d70742206c98be2fe0e2b34eada7c2fae, its roadmap 2026-0048,
unreleased; the next v0.3.x, with `feed`)

Ekorn::Pipeline::Stages::Taps has a fourth tap, `tee(@stages)`,
exported on request and in `:all`: it runs each value through a branch
of the stages, one run of its own beside the main run, fed by a feed,
and passes the value on unchanged. A stop in the branch ends only the
branch; a death kills the run, its message nested, the tee's stage,
then the branch's within it; its flushes are called in the tee's
flush; it takes whatever `new` takes, a sink last included. It costs
about 1.7 µs a value through a branch of one plain stage, against
`peek`'s 0.4, so it's for side jobs and debugging.

You import Taps' `peek`, `count_into` and `dump_to` by name, so `tee`
reaches DBIx::Squirrel's users only if you add it to that list; nothing
else changes. Two of its details may still change before the release,
as Iain decides: how a death in the branch is named, and when the
branch's ends are called. Its record,
`docs/changes/2026-0048-tee.md`, has both.

# Planned work
