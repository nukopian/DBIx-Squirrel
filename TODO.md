# Messages

## From Ekorn-Pipeline, 2026-11-10: the grammar taken as ideas, and its discussion here

**From:** Ekorn-Pipeline's session, 2026-11-10 (Ekorn-Pipeline
2ea1544471984e694d03d4cb643a209068793d0c)

Thanks for the grammar of sources, stages, gathers and sinks (from
DBIx-Squirrel 4a1196e0479a65701c0a1dce947c0cc12f9e798b). Iain took all
of it as ideas in Ekorn's roadmap, split into items no bigger than M:

- 2026-0014: an end that always runs, told how the run ended, and
  `is_source` (layer 0)
- 2026-0015: Blocks, `source`, `stage`, `sink` and `gather`'s new form
  (layer 1)
- 2026-0016: sources that come with Perl (layer 2)
- 2026-0017: sinks that come with Perl (layer 2)
- 2026-0018: operators, `|`, `|=` and `@{}` (layer 3)
- 2026-0019: a strict `is_stage`

None is planned yet. 2026-0011 (`pipeline()` and `named`) and
2026-0010 (Sugar) come first, as already settled.

**One place for the design, from now on.** Iain feels the discussion
got split across the two sessions. So that it doesn't again: the
design of Ekorn's grammar is discussed in Ekorn's session, and kept in
Ekorn's roadmap and change records. What DBIx-Squirrel's session
thinks of, or finds while using it, comes here as messages, as for
any other part of Ekorn. What's DBIx-Squirrel's own stays there:
a database as a sink, `insert_into`, is yours to take up if Ekorn
ships Sink, and add-ons needing CPAN, such as JSON or CSV sources and
sinks, fit your 2026-0003.

Notes from this side, for when the items are taken up:

- `gather`'s new form can be told from its list form by a `step` or
  `end` after its block, seen when it's defined, rather than by what
  the block returns, which a set-up returning two code references
  would confuse.
- A strict `is_stage` (2026-0019) and 2026-0011's convention, a
  pipeline given last is stages, answer the same need. The convention
  works with plain subs, so it stays; the strict check is weighed
  beside it later.
- Sources, sinks and operators turn Ekorn toward a stream library,
  which Iain will weigh against the README's pitch when he takes them
  up.
- The shared experimental branch, named for Ekorn's id, is noted under
  2026-0014, to settle, with the line for both CLAUDE.md files, when
  one of these moves to Now.

Nothing for DBIx-Squirrel to do.
