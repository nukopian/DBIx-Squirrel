# 2026-0042. The index says how to use a name; the reference text shows it in context

**Status:** shipped, unreleased

**Decisions:** D1 settled: every section the index links to drops its
synopsis and definition. D2 settled: the sections 2026-0040 gave each
name fold back into connected discussion, which the index links to.

**Origin:** roadmap, added 2026-11-18, Iain's idea, on seeing
2026-0040 and 2026-0041 together

**Started:** 2026-11-18

**Finished:** 2026-11-18

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

## What happened

- **Outcome:** done as planned. No section the index links to opens
  with a synopsis, and none repeats the index's definition: each has
  discussion in context, and examples `xt/examples.t` runs. The index
  links each of its 59 entries to the section that discusses the
  name. `xt/reference-index.t` checks each link reaches a section of
  the reference, and that none of those opens with a synopsis; each
  check failed, as it should, on a copy with a synopsis put back, a
  link to a section that isn't there, and an entry's synopsis taken
  out. Every link in the reference, and the user guide's into it,
  resolves. The suite, `xt/` included, passes on 5.36.3 and 5.44.0,
  2,493 assertions, against Ekorn::Pipeline v0.3.7 as installed from
  CPAN.
- **The sections:** 2026-0040's per-name sections rejoined "The select
  methods", "pipe and tap", "The iterator's methods", "Context",
  "Taking and dropping" (by place, then by a test), "Batching and
  collecting", "Canned stages" (as "Reshaping rows" and "Taps"),
  "Stages for others" and "The iterator as a source". The older
  sections, from `connect` to `gather`, lost their synopsis and
  defining paragraph, and opened instead on when or why to use the
  name. `database` and `statement` became "Defining them as the
  program runs", with an example; `connect_cached`, left empty, gained
  a discussion and an example.
- **Found on the way:** `connect_cached`, given the attributes straight
  after the data source, as `connect` takes them, makes a new
  connection each time: the example written to show two calls sharing
  a handle printed `apart`. With the username and password, even
  empty, it shares, and `ekorn_slice` keeps handles apart. The section
  says so; making `connect_cached` take the shortcut is code, so it's
  for Iain to decide.
- **Fixed the same day,** at Iain's word, in the `fix:` commit after
  this one: `DBIx::Squirrel->connect_cached` takes its arguments as
  `connect` does, and the section's advice to give empty credentials
  went.
- **What's left:** nothing here.
