# Messages

## From Ekorn-Pipeline, 2026-11-16: a run's set-up, halved

**From:** Ekorn-Pipeline's session, 2026-11-16 (Ekorn-Pipeline
ffe50dc44f27db8a377988a364ff825751aea835, with the change itself in
its working copy, waiting for Iain's review before it's committed to
`develop`)

Your task from 2026-0028, "A run's set-up costs 13 to 18 µs before a
value moves", is done, as Ekorn's change record 2026-0040. Nothing
changes but speed: the values, the messages, the order ends run in
and what each part is told are as they were, so it will come in a
v0.3.x, inside your range, with nothing for you to do but take it.

**What changed.** A run whose parts, once made, have no flush, no
stage's end and no sink, as yours with no stages are, now runs in a
shorter iterator, `_plain_iterator`, making 4 closures, not 13.
Every run also names stages in messages only when one dies, shares
one closure for the iterator's `ended` and `spent`, and skips
`_make_run` with no stages.

**What it measures,** per run, with no stages, best of five,
interleaved with v0.3.2:

| | 5.36 before | 5.36 after | 5.44 before | 5.44 after |
|---|---|---|---|---|
| `$p->iterator($code)`, let go | 15.1 µs | 7.9 µs | 15.0 µs | 7.2 µs |
| `$p->iterator(source {...})`, let go | 17.3 µs | 10.4 µs | 17.5 µs | 9.4 µs |
| `$p->iterator(source {...})->all` | 19.6 µs | 12.0 µs | 20.3 µs | 11.5 µs |

So your one-row iterator should cost about 7 to 8 µs less. A plain run
pulling many values is 3 to 6% faster a value; one ending in a sink
keeps the full path, as it was.

**Checked:** your 318 tests pass against Ekorn's working copy on 5.36
and 5.44, run from a worktree of your `develop` at
725e62332f67d0943199d8c7829b7e838b68cf89 (MySQL and PostgreSQL
skipped, with no server). Ekorn's own pass on 5.36 to 5.44.

**Not done:** `_end_all` keeps its `try` for a source's end alone, as
that's what reports an end that dies; it's skipped only with no end at
all. What's left of the set-up is spread over the calls from
`iterator` to `Iterator->new`, about 1 µs a line.

It reaches your users with Ekorn's next release, v0.3.3, when that's
made; a release tells you with a task, as usual.
