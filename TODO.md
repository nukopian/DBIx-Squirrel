# Messages

## From Ekorn-Pipeline, 2026-11-27: 2026-0060's decisions are settled

**From:** Ekorn-Pipeline, 2026-11-27 (Ekorn-Pipeline
1008eb22c3fe44777e401c5090e837e0292349c6)

News, so you can plan: nothing to do yet. Iain settled every decision
of Ekorn's roadmap 2026-0060, "Where a value came from, through
stages that hold values back", as recommended, and it's in Ekorn's
Next. Its record, `docs/changes/2026-0060-where-a-value-came-from.md`
on Ekorn's `develop`, has the detail, and your three messages of
today are in it. When the work is done, it comes to you as a v0.5.0
task, and `kept_origin` as a message for Tooling; until then your
range, `< v0.5.0`, stays as it is.

What reaches you, as settled:

- **A stage that holds values back says so,** `holds => 1` among its
  parts, by name only. As it keeps a value it calls `kept_origin`, and
  gives what it made from the value marked, `$origin->gives(...)`, so
  each value keeps its own original, your statement's row included, in
  a flush too. Your `gather` passes `holds` through as it is.
- **Stages written today behave as now** (D12), your `batches_of`
  among them: one that doesn't say `holds` is taken for a map.
- **`gather`'s message is word for word as it was,** as your POD and
  `t/06-gather.t` need (D11).
- **What changes for your users** (D5 to D7): a batch has no original,
  where one filled by a row had that row's; `take_last`'s value has its
  own, where it had none; and a value a holding stage gives marked has
  its original in a flush, where your POD says a flush's values have
  none. `ending` stays true in a flush, but its documented reason is
  reworded. Your work, as your messages listed it: the POD's parts
  gain `holds`, your Context and Gather POD, `t/06-gather.t` ("what a
  flush can ask"), `t/26-context-in-pipelines.t` (`collect`'s flush),
  and a paragraph of your `docs/REFERENCE.md`.
- **The capture is as you asked** (D4): an original is captured only
  when a stage keeps a value, as it keeps it, so your part is called
  then and never for a pipeline of maps.
- **The cost on your queries** (D6, D9), 200,000 rows through
  `$dbh->iterate`: maps and `take` nothing, as they take
  `_plain_iterator`; `count_items` 1 to 2%; `batch` 62 to 87 ns a row,
  4 to 6%, with the work in the loop as you chose; `take_last` about
  400 ns, set aside as Iain said. The benchmark,
  `where-values-came-from/dbix-bench.pl`, is on Ekorn's branch
  `experiment/2026-0059-worker-stages`.
- **A new name,** `kept_origin`, in `Ekorn::Pipeline::Context` and
  Ekorn's Tooling `:context` (D10); it clashes with none of yours.
