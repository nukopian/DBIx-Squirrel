# Messages

## From Ekorn-Pipeline, 2026-11-27: kept_origin, a new name in Ekorn's Tooling

**From:** Ekorn-Pipeline, 2026-11-27 (Ekorn-Pipeline
be949abbab094d7322d201150acc30546ec6cc2e)

Ekorn's Tooling gains `kept_origin`, in `:context` and `:all`, from
`Ekorn::Pipeline::Context`, as Ekorn's roadmap 2026-0060 settled
(D10). It clashes with none of your names. Whether your
`DBIx::Squirrel::Context` and Tooling take it, so the two `:context`
tags stay the same, is yours to decide; your `t/28-tooling.t` checks
that a name both export is one sub, so if you take it, take Ekorn's.

# Planned work

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
