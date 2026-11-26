# 2026-0059. Tooling exports a list of its own

**Status:** shipped, unreleased

**Decisions:** None: it's 2026-0057's D1.

**Origin:** roadmap, added 2026-11-26, from 2026-0057's D1

**Started:** 2026-11-26

**Finished:** 2026-11-26

## Background

DBIx::Squirrel::Tooling exports, by tags named as
Ekorn::Pipeline::Tooling's are, its own stages and Ekorn::Pipeline's
sources, sinks, JSON, CSV and words (2026-0025). Its tags were fixed
lists, but two tests held them to Ekorn's: `xt/ekorn-tooling.t`, that
each of ours holds every name Ekorn's tag of that name does
(2026-0034); and `t/28-tooling.t`, that each tag holds every name its
modules export, Ekorn's among them. So a name Ekorn::Pipeline added in
any v0.4.x failed our CI, and, as `t/28-tooling.t` is an install test,
failed DBIx::Squirrel's install beside it, until a release of ours
listed it. Iain chose, in 2026-0057's D1, a list of our own.

## The plan

**What:** Tooling's tags are lists of its own, and the tests hold it
to them, not to Ekorn's.

**Why:** a name Ekorn adds should come into Tooling when we choose, in
a release that adds it, and fail nothing until then.

**Steps:**

1. Tooling imports Ekorn's names by name, not `:all`, so one Ekorn
   drops fails as it loads.
2. `t/28-tooling.t`: a tag of DBIx::Squirrel's modules holds all they
   export; a tag of Ekorn's, only names its modules export, each the
   same sub. `xt/ekorn-tooling.t` goes.
3. Tooling's POD, the guide and the reference say its tags are its own
   lists; `scripts/manuals`.
4. Tried with a name faked into Ekorn::Pipeline::Sinks: today's
   `t/28-tooling.t` fails, the new one passes.
5. `Changes`, this record and `ROADMAP.md`.

**Done when:** `xt/ekorn-tooling.t` is gone, Tooling's POD and the
reference say its tags are its own, and `yath test -L t xt` passes on
5.36 and 5.44.

## What happened

- **Outcome:** done. `yath test -L t xt` passes on 5.36 and 5.44,
  against Ekorn-Pipeline's working copy at
  446058f8873907be8d53f2befd49bbaa70e6f101. With a sink faked into
  Ekorn::Pipeline::Sinks, as a later v0.4.x might add, today's
  `t/28-tooling.t` failed two subtests, and the new one passes.
- **Changes from the plan:** the reference's new paragraph first cited
  "(roadmap 2026-0059)", which the spelling test rejected; a user
  document cites no roadmap id, so it went.
- **Kept:** that each name both Toolings export is one sub, and that
  both import into one package without a warning (2026-0025's D6).
