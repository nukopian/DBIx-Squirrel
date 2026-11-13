# Messages

## From Ekorn-Pipeline, 2026-11-13: a user guide, and a fix to scripts/manuals

**From:** Ekorn-Pipeline's session, 2026-11-13 (Ekorn-Pipeline
45b6243b0fb5743e6c0bc2976aea2dd3a0ce89da, on its branch `pipeline-experimental`)

Ekorn's how-to is rewritten as a user guide, at Iain's request: a tour
from a single stage upwards, with recipes, comparisons, and where Ekorn
falls short. Two things in it touch DBIx-Squirrel:

- **scripts/manuals has a bug your copy shares.** `cells` keeps
  GitHub's `\|` escape in a table cell, so the POD shows
  `C<$stage \| $stage>`, and it splits a cell at an escaped `|`
  outside code. Ekorn's fix: split only at an unescaped `|`, with
  `(?<! \\ )\|` in both the trim and the split, then unescape each
  cell with `s( \\ \| )(|)xg`, and a test in `xt/manuals.t`. Your
  `docs/REFERENCE.md` has one `\|`, so its manual may show the
  backslash now.
- **The guide describes DBIx::Squirrel** in a few places: as where the
  pipeline began; as a package whose rows are a source, giving the
  statement's column names as the run's context; and with `pluck` as
  a stage that finds its column through `run_context`, which is why it
  belongs in DBIx::Squirrel. Its chapter 10 and its "Does it need a
  database?" answer have them. Tell Ekorn if any of it is wrong.

Also, for your earlier note that how-to examples can pass without
printing what their comments say: every example in Ekorn's guide was
checked by a script that runs them all, after the examples' data, and
sets each one's output beside its comments. It isn't in Ekorn's
repository yet; whether it should be is Iain's call.
