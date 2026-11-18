# 2026-0040. A section for each name the reference describes only in passing

**Status:** shipped, unreleased

**Decisions:** D1 settled: Ekorn gets the same, by a task. D2 settled: a
heading each, in its chapter. D3 settled: split from the index's
synopses, which are 2026-0041.

**Origin:** roadmap, added 2026-11-18, Iain's idea

**Started:** 2026-11-18

**Finished:** 2026-11-18

## Background

The reference's index (2026-0039) links each name to where it's
described. For 41 of its 59 entries, 39 names, that's a row of a table
or a section shared with others, not a section of the name's own: the
iterator's methods (`all`, `column_names`, `EKORN_SOURCE`, `ended`,
`first`, `new`, `next`, `single`, `sth`), Context's functions
(`iterator`, `result_number`, `result_original`), `croakf`, the
handles' `pipe` and `tap`, the seven select methods, and the canned
stages in Flow, Batch, Rows and Taps (17). Iain asked for each index
entry to have a synopsis of all its forms, a paragraph or two, and a
link to a fuller description, written where there isn't one.

## Decisions

- [x] **D1.** Does Ekorn-Pipeline's reference get the same? Yes: a task
  in its `TODO.md`, for its own session to design. Iain, 2026-11-18.
- [x] **D2.** What's a fuller description? A section with a heading of
  the name's own, in the chapter it belongs to: a synopsis of all its
  forms, what it does, and an example `xt/examples.t` runs. A table
  that was the only description becomes a short overview, each row
  linking to its section. Iain, 2026-11-18.
- [x] **D3.** One item, or two? Two: this one, the sections, and
  2026-0041, the index's synopses and descriptions, which depends on
  it. Iain, 2026-11-18.

## The plan

**What:** a section for each of the 39 names, each headed by the name,
so its anchor is the name's: in "The iterator's methods", "Context",
"The select methods", "pipe and tap", "Stages for others", "Taking and
dropping", "Batching and collecting", and "Canned stages", which takes
Rows' and Taps'. The index links each name to its section.

**Why:** a reader following a name from the index should land on all
there is to know about it.

**Steps:**

1. The iterator's methods, Context's functions, `croakf`.
2. The select methods, `pipe` and `tap`.
3. The canned stages: Flow's, Batch's, Rows', Taps'.
4. The index's links; `scripts/manuals`; `xt/examples.t` runs each new
   example.
5. `Changes` under Unreleased; the item leaves the roadmap.

**Done when:** each of the 39 names has a section headed by it, with a
synopsis and a run example; the index links each to it; the suite,
`xt/` included, passes on 5.36.3 and 5.44.0.

## What happened

- **Outcome:** done as planned. Each of the 39 names has a section
  headed by it, the first heading in the reference with its anchor,
  with a synopsis of all its forms, what it does, and an example
  `xt/examples.t` runs and checks; the index links each of its 41
  entries for them (`pipe` and `tap` are under both handles) to the
  section. The suite, `xt/` included, passes on 5.36.3 and 5.44.0,
  2,445 assertions, against Ekorn::Pipeline v0.3.7 as installed from
  CPAN; `scripts/manuals` resolves every link, and podchecker is
  clean.
- **Changes from the plan:** "The select methods" keeps the rules all
  seven share at its head; "pipe and tap" keeps a paragraph on both;
  `EKORN_SOURCE` takes a heading inside "The iterator as a source",
  which stays its fuller description; `pluck`'s section takes the
  paragraphs on where it finds columns and the reshaped-rows trap, and
  `dump_to`'s the paragraph on redaction. Two claims the examples
  don't run, `selectall_hashref`'s nested keys and
  `selectcol_arrayref`'s `Columns`, were checked against plain DBI and
  give the same.
- **The Ekorn task** went to Ekorn-Pipeline's `TODO.md` in
  6437537ecbb3ab0a03b3d13038b1b14b8bdeb7e3.
- **What's left:** 2026-0041, the index's synopses and descriptions,
  which this unblocks.
