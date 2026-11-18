# 2026-0040. A section for each name the reference describes only in passing

**Status:** in progress

**Decisions:** D1 settled: Ekorn gets the same, by a task. D2 settled: a
heading each, in its chapter. D3 settled: split from the index's
synopses, which are 2026-0041.

**Origin:** roadmap, added 2026-11-18, Iain's idea

**Started:** 2026-11-18

## Background

The reference's index (2026-0039) links each name to where it's
described. For 39 of its 77 names, that's a row of a table or a section
shared with others, not a section of the name's own: the iterator's
methods (`all`, `column_names`, `EKORN_SOURCE`, `ended`, `first`,
`new`, `next`, `single`, `sth`), Context's functions (`iterator`,
`result_number`, `result_original`), `croakf`, the handles' `pipe`
and `tap`, the seven select methods, and the canned stages in Flow,
Batch, Rows and Taps (17). Iain asked for each index entry to have a
synopsis of all its forms, a paragraph or two, and a link to a fuller
description, written where there isn't one.

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
