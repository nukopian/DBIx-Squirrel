# 2026-0007. Every claim in the reference, checked

**Status:** shipped, unreleased

**Decisions:** D1 settled: two items, this audit first, then the
how-to (2026-0008). D2 settled: new checks in `t/23-documented.t`.

**Origin:** roadmap, added 2026-11-10, from Iain, after Ekorn-Pipeline
did the same for its docs (Ekorn-Pipeline
54d260735fd4c86894d8051ae3b48157f0b2b5f2 and
954824dc7f7d84c17b25e0703b4b3459c0108765)

**Started:** 2026-11-10

**Finished:** 2026-11-10

## Background

Ekorn-Pipeline checked its docs against its code: it matched each claim
in its reference to the test that checks it, and ran every example.
Even after that, omissions turned up. The biggest was that the docs
still said "a code reference" where a pipeline is now accepted. Here,
the same omission showed up in the review of 2026-11-09: a Sugar
statement defined with a pipeline straight after its SQL took the
pipeline for its attributes (2485131), and the how-to had no recipe
for a `gather` block returning a pipeline, a pipeline in a Sugar
statement, or a nested stage's name in a message.

## Decisions

- [x] **D1.** One item or two? Two, Iain decided on 2026-11-10, as one
  would be bigger than an L: this audit of the reference first, then
  the how-to rebuilt (2026-0008), which depends on it. The audit gives
  the how-to a full list of what DBIx::Squirrel does.
- [x] **D2.** Where do the new checks go? In a file of their own,
  `t/23-documented.t`, Iain decided on 2026-11-10, as Ekorn's
  `t/12-documented.t` does: each subtest named for the reference's
  section it checks.

## The plan

**What:** check `docs/REFERENCE.md` against the code, claim by claim.

- Match each claim the reference makes to the test that checks it.
  Where there's none, add a check to `t/23-documented.t`, its subtest
  named for the section.
- Run every example in the reference and the README, and check each
  prints or returns what it says.
- Look for omissions: what the code does that the reference doesn't
  say, especially where a feature added later (a pipeline as a stage,
  `gather`, Sugar) meets an older one. Add them to the reference, and
  to the module's POD where it should say it too.
- Where a claim is wrong, fix whichever is wrong, the docs or the
  code, and note it here.
- New and changed text keeps 2026-0005's rules for plain docs.

**Why:** a reader trusts the reference to say what the code does. A
claim no test checks can drift from the code unnoticed, and an
omission leaves a question with no answer.

**Steps:** one commit for each chapter of the reference, or a few
chapters together where they're short, each with its tests, the
manuals made again, and the tests, `podchecker` and coverage passing.

**Done when:** every claim in the reference has a test that checks
it, every example in the reference and the README does what it says,
each omission found is documented, and the record lists what was
found.

## What happened

- **Outcome, 2026-11-10:** against Done when, met. Each section of the
  reference was read, its claims listed, and each matched to the test
  that checks it. Those with none have checks in
  `t/23-documented.t` now: 64, in 18 subtests named for the sections. All passed as they
  stood: the code does what the reference says. Every message in
  Diagnostics is raised by some test. The tests went from 1,500
  assertions to 1,582, and branch coverage from 97.3% to 97.5%, short
  of a new floor.
- **The checks added,** by section:
  - Connecting: `connect` croaks at the caller's line; a clone is a
    separate connection (in memory, a new, empty database);
    `connect_cached` croaks too; a subclass without handle classes
    gets the DBI's warning and handles.
  - Placeholders: a numbered placeholder bound once (`$2 + $1, $1`); a
    named one by pairs or a hash, with or without the sigil; a name
    the statement hasn't croaks; a Sugar statement taking a list isn't
    cached.
  - Preparing and binding: `$if_active` of 2 hands out the cached
    handle unchanged; `bind` croaks at the caller on an odd number of
    named values, and returns nothing if the DBI can't bind; the
    select methods take a hash of named values only after the
    attributes, and `selectall_hashref`'s after its key field.
  - Iterators and rows: a statement isn't executed until a result is
    asked for, and is finished when they run out; a column named as
    one of your own methods gets no method.
  - Pipelines: none of the pipeline, `gather`, `Stop`, Context or the
    canned stages' modules loads the DBI; a pipeline can be given to
    `pipe`, `tap`, `reset`, `results` and a database's function, and a
    stop or `result_number` inside one works as in any stage.
  - Canned stages and Context: naming a stage in the import list
    replaces the defaults, and `:DEFAULT` keeps them; `pluck` by name
    on an array, and `as_hash`, need an iterator; `result_original`,
    in a result set, is the row object.
  - Writing stages: a module of stages with
    `@DBIx::Squirrel::Errors::INTERNAL` as its `@CARP_NOT` croaks at
    the line that asked for the result.
  - Sugar: a database is found by name anywhere in the program; two
    defined with the same arguments share a handle; one defined with a
    handle is cloned when first used; stages given to a statement's
    function are for that call only.
- **The examples:** each Perl block in the reference and the README
  was compiled. Those that failed are fragments, Sugar functions
  called without parentheses, the 1.x code, or shell commands, so
  none is wrong. Those that say what they give were run and do: `pipe`'s
  `(6, 10)`, `reset`'s, `bind_param`'s `2 + 2, 3`, counting with
  `() =`, and the test in Writing stages. The README's examples run
  against the how-to's example database.
- **Fixed in the reference, as omissions:**
  - Where a pipeline can go now lists an iterator's `reset` and a
    database's function, as well as `iterate`, `results`, `pipe`,
    `tap` and a statement's function.
  - Writing stages said "A stage of your own is a code reference". It
    can be a pipeline of other stages too.
  - Upgrading listed 2.0's dependencies without Ekorn::Pipeline.
- **Changes from the plan:** one commit, not one for each chapter, as
  the audit changed only three sentences of the reference. The module
  POD needed no change: it already says a stage is a code reference or
  a pipeline.
- **Found on the way:** Perl::Tidy splits a long call inside `dies`
  over lines, which breaks a `__LINE__ + 1` before it. The checks set
  `$line = __LINE__` inside the block, on the call's line, and keep
  the call short.
