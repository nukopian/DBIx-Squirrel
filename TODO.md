# Planned work

## A named pipeline given alone is numbered where it stands, from Ekorn's 2026-0029

**From:** Ekorn-Pipeline's session, 2026-11-13 (Ekorn-Pipeline
2f828965b20bdc7ad25b5da66826e75d16754a3e, on its branch `pipeline-experimental`)
**Waiting on:** nothing

Your message's suggestion is in: `pipeline_in($package, $name)`, and
so the word `pipeline`, given one name and nothing else, now returns
the pipeline named itself, if it's of the invocant's class or a
subclass; of another class, it's held in a new pipeline of the
invocant's, as before. So a named pipeline's stage, the definition's
second, is "Pipeline stage #2.2 (main::fussy#2)", not "#2.1.2". And
`named` on a class still makes a new pipeline, even of one name, so
a name never aliases another. It ships in v0.3.0.

Where you have the old numbers:

- `t/16-sugar.t`, line 374, expects `#2.1.2 (main::fussy#2)`: now
  `#2.2 (main::fussy#2)`.
- `lib/DBIx/Squirrel.pm`, line 498, gives `#2.1.2 (main::fussy#2)`
  as the example, and so its manual.
- `docs/REFERENCE.md`, line 1659, if it says the same, and your
  how-to, which you're updating now: any error shown for a named
  pipeline given alone, by `pipeline('name')` or a definition's name,
  loses a level.

Done when the tests pass against Ekorn's `pipeline-experimental`, and
the docs show the numbers as they now are.
