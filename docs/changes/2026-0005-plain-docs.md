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

- **Outcome, 2026-11-09:** each document has had the pass, in a commit
  of its own: the README (338ae9b), the modules' POD (63aeb8b), the
  reference (af8f116), the how-to (9079f0f) and MAINTAINING (466142b).
  The manuals and `README.md` are made again. The tests, `xt/howto.t`
  and `xt/manuals.t` among them, `podchecker` and coverage pass,
  against Ekorn-Pipeline's `develop`. Iain's reading of the PDFs is
  what's left of Done when.
- **How the rules were kept:** a script compared each document with
  9e6fbd7, the commit that started the work: every code block,
  heading and DIAGNOSTICS entry, and in the reference, the first
  column of every table. None changed. Nothing above `__END__` in a
  module changed. The edits were made as old and new pairs, each
  refused unless its old text matched exactly once.
- **Lists:** where a sentence listed three or more things, it became
  a bullet list: what `prepare` leaves alone, the forms a statement
  takes, DBD::Pg's options, `study_sql`'s values, what a stop does,
  Ekorn's advice on writing stages, step 3 of a release, and the
  tools.
- **Fixed, as unclear or wrong:**
  - `do`'s POD put "So is a statement taking a list" after a sentence
    about row counts, which it didn't follow on from.
  - `prepare_cached`, in the POD and the reference, packed what the
    DBI does with an active handle, why that's a problem, and what
    DBIx::Squirrel does instead into one sentence. It's three now.
  - The reference's "A stage is called with one value" now says "a
    stage that's a code reference", as a stage can be a pipeline
    since 2026-0004.
  - gather's example of a block returning a pipeline, added in
    2026-0004, moved below the paragraph on end functions, which it
    had cut off from what it followed.
  - MAINTAINING's trial section said the next trial and the release
    "are v2.0.2". That's past, so "were".
- **Changes from the plan:** none.
