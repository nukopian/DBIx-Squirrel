# 2026-0005. Plain docs

**Status:** in progress

**Decisions:** D1 settled: on a branch from 2026-0004's.

**Origin:** roadmap, added 2026-11-09, from a message from
Ekorn-Pipeline's session, 2026-11-09 (Ekorn-Pipeline
1fd32e559291e64203c5c716eec2466013259b9a)

**Depends on:** 2026-0004, whose branch this one starts from

**Started:** 2026-11-09, on `experiment/2026-0005-plain-docs`

## Background

The docs share a house style, written to match one another, that makes
them hard to read: the same word several times in a sentence; chains
of "as X says" links; long sentences joined by commas, colons and
semicolons; and qualifiers that repeat each other. Ekorn-Pipeline
found the same in its docs, and rewrote them as its 2026-0006
(Ekorn-Pipeline c4bcddf76f64ddbf50bae65e607922fad8c35518). Its record
gives the rules below, which suit these docs too.

## Decisions

- [x] **D1.** Where is the work done? On
  `experiment/2026-0005-plain-docs`, from
  `experiment/2026-0004-pipeline-as-stage`, on 2026-11-09. That branch
  already changes the reference, the how-to and the POD. A pass on
  `develop` would rewrite the same paragraphs, and the two would
  conflict throughout. So this one reaches `develop` after 2026-0004,
  and waits on Ekorn-Pipeline v0.1.3 too. `TODO.md` is still worked
  from 2026-0004's branch, where its last step is.

## The plan

**What:** a plainness pass over the README (`README.pod`), the POD of
every module, `docs/REFERENCE.md`, `docs/HOWTO.md` and
`docs/MAINTAINING.md`.

**Why:** a reader meets the docs before the code, and they should be
easy to read.

**Rules for the pass:**

- Say what the text said: no claim added, dropped or changed. Where a
  sentence turns out to be wrong or unclear in what it says, fix it,
  and note it here.
- One idea a sentence, where that reads better. A short sentence
  beats a list of clauses.
- Name a thing once, then "it", unless that's unclear.
- Link once to a section, and not in a chain of "as X says".
- Keep the examples, the headings and the anchors other pages link to,
  and the DIAGNOSTICS entries, which match the messages.
- Plain words: "use" not "make use of", "unchanged" not "as they are".

**Steps:** one commit for each: the README; the modules' POD; the
reference; the how-to; MAINTAINING. Each regenerates the manuals or
`README.md` as needed, and passes the tests, `xt/howto.t`,
`xt/manuals.t` and `podchecker`. A script compares each document's
code blocks and headings before and after, so none changes by
accident.

**Done when:** each document has had the pass, every example still
prints what it says, and Iain has read the PDFs of the README, the
how-to, the reference and MAINTAINING.

## What happened

