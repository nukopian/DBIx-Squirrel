# 2026-0042. The index says how to use a name; the reference text shows it in context

**Status:** in progress

**Decisions:** D1 settled: every section the index links to drops its
synopsis and definition. D2 settled: the sections 2026-0040 gave each
name fold back into connected discussion, which the index links to.

**Origin:** roadmap, added 2026-11-18, Iain's idea, on seeing
2026-0040 and 2026-0041 together

**Started:** 2026-11-18

## Background

2026-0040 gave each of 39 names a section headed by it, and 2026-0041
gave each index entry a synopsis and a paragraph or two, lifted from
that section. So each name's synopsis and definition were in the
reference twice. Iain wanted them once, divided by purpose: the index
for direct lookup, how to call a name and what it's for, with a link;
the reference text for discussion in context and examples of use, in
much greater detail.

## Decisions

- [x] **D1.** Which sections drop their synopsis and definition? All
  the index links to, the long-standing ones included (`connect`,
  `prepare`, `execute`, `bind`, `do`, `iterate`, `results`, `reset`,
  `database`, `statement`, `Stop`, `gather`, `get_column`...). The
  index is the one place for a name's synopsis. Iain, 2026-11-18.
- [x] **D2.** What becomes of 2026-0040's sections, a heading each?
  They fold back into connected discussion with examples, in the
  section their name belongs to, and the index links each name there.
  Iain, 2026-11-18. It reverses 2026-0040's D2, and 2026-0041's D2
  in part: the test checks each link reaches a section outside the
  index, not one headed by the name.

## The plan

**What:** each section the index links to keeps its discussion and its
examples, but not the name's synopsis, or the paragraph defining it,
which are the index's. 2026-0040's per-name sections rejoin their
parents: "The select methods", "pipe and tap", "The iterator's
methods", "Context", "Taking and dropping", "Batching and collecting",
"Canned stages", "Stages for others" and "The iterator as a source".
The tables there that only defined each name go, as the index has the
definitions. A section left with nothing gets discussion and an
example; `database` and `statement` become "Defining them as the
program runs". A section showing forms no index entry has, such as
"Defining them on use" or "The function a database is given", keeps
its synopsis.

**Why:** the index answers "how do I call this, and what is it for";
the text answers "how is it used", without repeating the first.

**Steps:**

1. Chapters 1 to 4: `connect`, the statement methods, the select
   methods, `iterate`, the iterator's methods, `reset`.
2. Chapters 5 to 10: Context, the canned stages, `Stop`, `gather`,
   `results`, `get_column`, `pipe` and `tap`.
3. Chapters 12 to 15: the Sugar's definitions, the caches, `croakf`,
   `EKORN_SOURCE`.
4. The index's links; the test: each link reaches a section outside
   the index, and no section an entry links to opens with a synopsis;
   tried by breaking a copy.
5. `scripts/manuals`; `Changes`; the item leaves the roadmap; 2026-0040
   and 2026-0041's records say what this changed.

**Done when:** no section the index links to repeats its synopsis or
definition; each keeps or gains discussion and an example the tests
run; the suite, `xt/` included, passes on 5.36.3 and 5.44.0.
