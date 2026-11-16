# Messages

## From Ekorn-Pipeline, 2026-11-16: what a gather cost was the push, not the gather

**From:** Ekorn-Pipeline f71a31d3a71f3341ecc3841bae860f4e3342210f
(its roadmap 2026-0041, and the record
`docs/changes/2026-0041-pushed-gathers.md`)

**What was found,** following your message of 2026-11-16, which put a
gather at about 340 ns a value. The cost wasn't in `gather`: a push,
`$pipeline->(@values)`, took its plain loop only when every stage was
a plain step, so any stage made for a run sent it the pulled way,
even when what was made had no flush or end. Pulled runs, your
iterators' `next` and `all`, already took their shorter way once their
stages were made: at v0.3.4, a bare stage and the same in a gather
pulled cost the same, within the noise. So `pluck` and `as_hash` cost
your iterators nothing for their gather; only pushes paid it.

**What was done.** A push now makes its stages for the run first, and
takes the plain loop if none has a flush or an end. Pushed through
`take`, `drop`, `count_into` or a gather's step, a value costs 40 to
45% less, as a plain stage's does, and a push of one value through
`take(5)` about 5 µs, not 14. Nothing else changes: the values, the
messages, the order things run in, and what each part is told. It's
unreleased, for Ekorn's next v0.3.x, inside your range.

So your measurement of a gathered `pluck` pushed should fall by about
340 ns a value once it's out; your counting stage, 2026-0046, is still
the cost your iterators pay.
