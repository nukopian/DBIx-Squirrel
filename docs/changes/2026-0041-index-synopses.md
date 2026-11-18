# 2026-0041. A synopsis and a fuller description for each name in the index

**Status:** shipped in v3.4.0

**Decisions:** D1 settled: Ekorn gets the same, by a task. D2 settled:
the test checks for a synopsis, and a link to the name's own section.

**Origin:** roadmap, added 2026-11-18, Iain's idea

**Depends on:** 2026-0040

**Started:** 2026-11-18

**Finished:** 2026-11-18

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

## What happened

- **Outcome:** done as planned. Each of the index's 59 entries has its
  section's synopsis, its section's first paragraph, or two where the
  first is short, with how it's exported, and its link. Where `iterate`,
  `results`, `pipe` and `tap` share a section between the handles,
  each handle's entry shows its own forms. `xt/reference-index.t`
  checks each entry has a synopsis and links to a section headed by
  its name; each check failed, as it should, on a copy of the index
  with a synopsis taken out, a link to a shared section, and a
  section's heading changed. The suite, `xt/` included, passes on
  5.36.3 and 5.44.0, 2,485 assertions, against Ekorn::Pipeline v0.3.7
  as installed from CPAN; `scripts/manuals` resolves every link, and
  podchecker is clean.
- **Changes from the plan:** `connect_cached`'s section had no
  synopsis, so it has one. The entries were drafted by a script from
  their sections, then each read in place: eight ended where their
  section went on to a list or an example (`prepare`, `croakf`,
  `EKORN_SOURCE`, `reset`, `bind_param`, `execute`, `Stop`,
  `gather`), and were rewritten to stand alone; `dump_to` said "On
  request" twice. The plan said 77 entries; the index has 59, as
  2026-0040's corrected record says.
- **Changed by 2026-0042,** the same day, before a release: the
  per-name sections folded back into connected discussion, and no
  section the index links to repeats its synopsis or definition. The
  index keeps the synopses and descriptions, linking each name to the
  section that discusses it.
- **Released** in v3.4.0, 2026-11-18.
- **What's left:** nothing; Ekorn-Pipeline's index has the task sent
  in 2026-0040.
