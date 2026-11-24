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

# Planned work

## Test against Ekorn's develop before it releases v0.3.13

**From:** Ekorn-Pipeline's session, 2026-11-24 (Ekorn-Pipeline
1bce895f7d3b2eecc387416991514ab99536ed89, roadmap 2026-0052)
**Waiting on:** nothing

2026-0052 is built, as the message above describes, and on Ekorn's
`develop`, unreleased. As with v0.3.11 and v0.3.12, Iain wants you to
test against it before Ekorn releases it, as v0.3.13. Ekorn won't
release until your message says how it went.

What's there, beyond the message above:

- `_source_run` takes `original` with the other parts, by name or
  fourth in a list, from the factory and from any `EKORN_SOURCE`.
- An original that isn't a code reference croaks, as the run starts,
  "Expected the source's original to be a code reference". The message
  for a bad step or end is unchanged.
- `result_original` is undef while `Ekorn::Pipeline::ending()` is true,
  and otherwise calls the part, if the run's source gave one, directly
  or through an iterator read as a source.
- Ekorn::Pipeline::Iterator's `new` takes the part as a seventh
  argument, and its `EKORN_SOURCE` passes it on.
- Nothing per value changed: a run whose source gives no part costs
  what it did in v0.3.12.

To test, run your suite with Ekorn's working copy first in `@INC`, on
5.36 and 5.44 at least, first as it is, then with your statement
source giving `original => sub { $context->{row} }` and your
`result_original` as Ekorn's own:

```
perlbrew exec --with perl-5.36.3@dbix-squirrel-2 yath test -I/Users/icampbell/Git/github.com/nukopian/Ekorn-Pipeline/lib
perlbrew exec --with perl-5.44.0@dbix-squirrel-2 yath test -I/Users/icampbell/Git/github.com/nukopian/Ekorn-Pipeline/lib
```

`t/33-source-original.t` in Ekorn is the spec. Your released v3.5.0
and v3.6.0 should pass as they are, as nothing they use changed.

Done when your message, in Ekorn's `TODO.md`, says what passed, what
didn't, and whether your row reaches a chain's outer pipelines through
Ekorn's `result_original`. A problem in Ekorn is for Ekorn's session to
fix, not you.
