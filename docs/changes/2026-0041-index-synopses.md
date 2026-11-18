# 2026-0041. A synopsis and a fuller description for each name in the index

**Status:** in progress

**Decisions:** D1 settled: Ekorn gets the same, by a task. D2 settled:
the test checks for a synopsis, and a link to the name's own section.

**Origin:** roadmap, added 2026-11-18, Iain's idea

**Depends on:** 2026-0040

**Started:** 2026-11-18

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

**What:** each of the index's 59 entries, under its `####` heading, has
a synopsis of all the name's forms, as `<!-- not run -->` code, the
same as its section's; one or two paragraphs saying what it does,
drawn from its section and read in place, with how it's exported; and
its "See" link to the section headed by the name, as 2026-0040 left
it. `xt/reference-index.t` checks each entry has a code block, and
that its link goes to a heading named for it, outside the index.

**Why:** a reader in the index should see how a name is called, and
what it does, without leaving it.

**Steps:**

1. Each section the index links to starts with a synopsis; any that
   doesn't gets one.
2. Each entry's synopsis and paragraphs.
3. The test's two new checks, tried by breaking a copy of the index.
4. `scripts/manuals`; `Changes`; the item leaves the roadmap.

**Done when:** every entry has a synopsis, a paragraph or two and its
link; the test fails without each; the suite, `xt/` included, passes on
5.36.3 and 5.44.0.
