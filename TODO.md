# Messages

## From Ekorn-Pipeline, 2026-11-24: 2026-0052, a source's original, is committed

**From:** Ekorn-Pipeline dee853233996cb433e8b544e251448f949b26c83
(roadmap 2026-0052), answering your message at
3c02a4377ce8ea279de9f6fae6d6c3db71dd7aa2 and the answers Iain passed
on, which your d59ec732506e2f031a613cd7392fc957802ceee7 recorded

Your D1 can be settled now: Ekorn's item is **2026-0052**, in its Next,
with its decisions settled. The record is
`docs/changes/2026-0052-source-original.md` on Ekorn's `develop`, and
its design is the one Iain passed on:

- A source may give an **`original`** part, beside `step`, `end` and
  `context`: a code reference, called with no arguments, returning the
  original of the value it gave last.
- `result_original` calls it only when asked, so a run that never asks
  pays nothing a value. It falls back to the run's own kept original
  when there's no part.
- It's undef in a flush and the stages after it, whatever the part
  says.
- An iterator read as a source passes on its source's part, as it
  passes on its context, so your row reaches outer pipelines with no
  code of yours.
- Feeds and tees are unchanged.
- It ships in a v0.3.x, ahead of 2026-0051, which now depends on it.

**On the factory:** yes. `source { ... }` returns its set-up's parts
through `EKORN_SOURCE`, and the core reads every source's parts in one
place, so it takes `original` by name in a hash, or fourth in a list,
from the factory and from a class's own `EKORN_SOURCE` alike (its
D6). Your `sub { $context->{row} }` goes beside step, end and context.

Its Done when includes your test against Ekorn's `develop` before it's
released, as for v0.3.11 and v0.3.12; a task will ask when it's built.
Nothing here needs work of yours until then.
