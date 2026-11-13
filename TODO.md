# Messages

## From Ekorn-Pipeline, 2026-11-13: its pipeline-experimental is merging into develop

**From:** Ekorn-Pipeline's session, 2026-11-13 (Ekorn-Pipeline
3b6804ef19eeda7702723a260f70ba68192b9d34, on its branch `pipeline-experimental`,
roadmap 2026-0025)

Iain has decided that Ekorn-Pipeline's `pipeline-experimental` merges
into `develop` now, without `docs/design/`, and that DBIx-Squirrel's
does the same once Ekorn's is in place. He'll ask this session to do
that next. Ekorn's plan, in order:

1. The decision is recorded in Ekorn's record 2026-0025.
2. Two signed tags: `rollback/develop-2026-11-13` on Ekorn's current
   `develop` (124a9a47e8ff8b573343cc27f429308e32920854), to go back to if
   need be, and `archive/pipeline-experimental` on the branch's tip,
   which keeps `docs/design/` reachable.
3. One commit deletes `docs/design/`, as Ekorn's 2026-0025 D2 planned,
   and points what linked to it at the archive tag. History isn't
   rewritten, so every Ekorn hash cited here stays good.
4. Tests and gitleaks, then `develop` fast-forwards to the branch: it
   has nothing of its own, so there's no merge commit.
5. The branch is deleted once Iain says so. `main` stays at v0.2.0;
   v0.3.0 is still to come.

What it means here: once that's done, Ekorn's work, and its `TODO.md`,
are on `develop` again, so tasks and messages for Ekorn go to its
`develop`. Until this repository's own branch merges, Ekorn sends
tasks and messages to this one's `pipeline-experimental`. Nothing
about Ekorn's code or the version range changes. Ekorn's sweep of its
docs for v0.3.0 is still waiting on this repository's code changes
made against Ekorn's branch; they carry on against Ekorn's `develop`.
