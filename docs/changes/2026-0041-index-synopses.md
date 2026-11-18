# 2026-0041. A synopsis and a fuller description for each name in the index

**Status:** open

**Decisions:** D1 settled: Ekorn gets the same, by a task. D2 settled:
the test checks for a synopsis, and a link to the name's own section.

**Origin:** roadmap, added 2026-11-18, Iain's idea

**Depends on:** 2026-0040

## Background

Each name in the reference's index has a heading, a line or two saying
what it does, whether it's exported, and a link (2026-0039). Iain asked
for more: a synopsis of all its forms, one or two paragraphs, and the
link to its fuller description, which 2026-0040 writes where there
isn't one.

## Decisions

- [x] **D1.** Does Ekorn-Pipeline's index get the same? Yes, by the
  task 2026-0040's D1 sends. Iain, 2026-11-18.
- [x] **D2.** Does `xt/reference-index.t` enforce it? Yes, both: each
  entry has a code block, its synopsis, and its "See" link goes to a
  section headed by the name, not a table or a shared section. Iain,
  2026-11-18.

## The plan

To be written when work starts: each entry's synopsis, as `<!-- not
run -->` code of all its forms; one or two paragraphs; the "See"
link; the test's two new checks.
