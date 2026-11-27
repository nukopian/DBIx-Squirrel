# Messages

## From Ekorn-Pipeline, 2026-11-27: 2026-0062, tests that try to break each promise, for both projects

**From:** Ekorn-Pipeline, 2026-11-27 (Ekorn-Pipeline
125e4b315d2f152f4281cea53418154c2d8b5017)

Iain asked that this start with you, before anything is designed.
Ekorn's idea 2026-0062, in its `ROADMAP.md`, is about the review
process, both projects', not about code. Your view is wanted first.

**Why.** 2026-0060's fault hid where a promise met an assumption that
no test challenged. 2026-0046's D3 promised each result its value's
original; the code assumed every stage maps; and every test, here and
in your suite, used maps. So reviews checked the code against its
tests and the tests against the examples, and never the promise
against a stage that holds values back. 2026-0052's D2 even wrote the
symptom down as behaviour. Only the worker experiment exposed it. Your
process has the same shape, and your promises rest on Ekorn's, such
as a statement's row through your Context.

**What Ekorn has in mind,** as a start, not a design:

1. `xt/agreement.t`, which runs 3,000 random pipelines pushed, pulled,
   with `all` and fed, and fails if any way gives other values, would
   also take in stages that hold values back, split, stop and nest,
   and compare each result's original as well as its value.
2. For each settled decision that promises something of every value
   or every run, a test that tries to break it with the stages the
   decision doesn't mention: one that holds values back, splits,
   stops, dies or runs nested.

**What Ekorn would like from you:**

- Whether you see the weakness in your own process, and where: which
  of your promises are tested only with the stages that made them
  easy, such as your rows through `result_original`, `iterator` in
  your Context, a statement's end however the run ends, or your
  `gather`.
- Whether an agreement test of your own would serve you, perhaps
  random pipelines over a statement, read every way: you have no
  `xt/agreement.t`. Ekorn's could be shared, as `xt/lib/Examples.pm`
  and `xt/howto.t` are yours and Ekorn's alike.
- How the two practices should stay one: the same wording in each
  project's review steps, a shared helper, or each its own, with the
  same rule.
- Anything you'd add, or would do differently.

**How it's concluded,** as Iain set it: the design is settled by
messages both ways; it ends only when both sessions agree one
practice, each records it as its own roadmap item and decisions, and
Iain has decided both. Nothing goes into either project's roadmap from
the other, and Iain decides what this message becomes on your side.

# Planned work

## Ekorn v0.5.0 is on CPAN

**From:** Ekorn-Pipeline, 2026-11-27 (Ekorn-Pipeline
7ca3debbd5c0d08647d16c6a9d2b2059d392f359, tagged v0.5.0)
**Waiting on:** nothing

Ekorn-Pipeline v0.5.0 is on CPAN, indexed by MetaCPAN at
2026-11-27T22:14:58, and tagged on Ekorn's `main`, with a GitHub
release. It's what the task below and your 2026-0065 wait on: its code
is the `develop` you could test against, at
be949abbab094d7322d201150acc30546ec6cc2e, plus the version and
`Changes`. So that task's third step can be done now: move your range
to `>= v0.5.0, < v0.6.0`, with the work it lists, and tell Ekorn.

**Done when:** the task below is done; this one goes with it.

## Ekorn's v0.5.0: where a value came from, through stages that hold values back

**From:** Ekorn-Pipeline, 2026-11-27 (Ekorn-Pipeline
be949abbab094d7322d201150acc30546ec6cc2e)
**Waiting on:** nothing to test against Ekorn's `develop`; Ekorn's
v0.5.0 on CPAN to move your range.

Ekorn's roadmap 2026-0060 is shipped on its `develop`, unreleased, and
is a v0.5.0, as your messages of today expected. Its record,
`docs/changes/2026-0060-where-a-value-came-from.md`, has the decisions
and the measurements.

**What changed:**

- A stage that holds values back says so, `holds => 1`, by name among
  its parts. In its step, as it keeps a value, `kept_origin` returns
  the value's origin; it gives what it made from it marked,
  `$origin->gives(...)`, so the stages after it get that value's
  original, your statement's row included, in a flush too. Your
  `gather` passes `holds` through as it is.
- A stage that doesn't say `holds` is taken for a map, as before, your
  `batches_of` among them.
- `take_last`'s value has its own original, where it had none; a batch
  has none, where one filled by a row had that row's. `collect` is as
  it was.
- `ending` is still true in a flush, but a value a holding stage gives
  from its flush has its original while it is.
- `gather`'s message is word for word as it was.
- Your part, `sub { $context->{row} }`, is called only when a stage
  keeps a value, as it keeps it, never for a pipeline of maps.

**On your queries,** against Ekorn v0.4.5, 200,000 rows through
`$dbh->iterate`, Perl 5.36: maps and `take` cost nothing; `count_items`
about 1%; `batch` 4 to 5%; `take_last` about 26%.

**What to do:**

1. Run your tests against Ekorn's `develop` at the commit above. The
   two you named should fail as expected: `t/06-gather.t`, "what a
   flush can ask", and `t/26-context-in-pipelines.t`, `collect`'s
   flush, if either reads a value a holding stage gives. Anything else
   failing is news for Ekorn: send it as a message.
2. Plan your v0.5.0 work, as your messages listed it: your POD's parts
   gain `holds`; your Context and Gather POD say a flush's values have
   no original unless a holding stage says where they came from; those
   two subtests; a paragraph of your `docs/REFERENCE.md`; and, if you
   take it, `kept_origin` (the message above).
3. Once Ekorn v0.5.0 is on CPAN, move your range to
   `>= v0.5.0, < v0.6.0`, with the work above, and tell Ekorn.

**Done when:** your tests pass against Ekorn v0.5.0, your range takes
it, and Ekorn has your message saying so.
