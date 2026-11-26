# 2026-0062. dump_to's setting, without naming Ekorn

**Status:** shipped in v4.2.0

**Decisions:** D1 settled: `$DBIx::Squirrel::Stages::Taps::DumpSecrets`;
amended: tied to Ekorn's variable, not aliased.

**Origin:** roadmap, added 2026-11-26, from 2026-0057's D5

**Started:** 2026-11-26

**Finished:** 2026-11-26

## Background

`dump_to`, from DBIx::Squirrel::Stages::Taps on request, is
Ekorn::Pipeline's. It writes each value in full, without redacting
secrets, while `$Ekorn::Pipeline::Stages::Taps::DumpSecrets` is true,
a package variable, so that it can be localised, as Data::Dumper's
are. Part 1 of the documents can't name it. Iain chose, in 2026-0057,
to give DBIx::Squirrel a way of its own. Ekorn's own message, when
Text::Redact::Secrets is installed but can't be used, names Ekorn's
variable, and that stays Ekorn's.

## Decisions

- [x] **D1.** How is it set?
  `$DBIx::Squirrel::Stages::Taps::DumpSecrets`, an alias of Ekorn's
  variable, as Iain decided on 2026-11-26, as recommended. The options
  were:
  - `$DBIx::Squirrel::Stages::Taps::DumpSecrets`, an alias of Ekorn's
    variable, so `local` on either sets both, as callers set
    Data::Dumper's;
  - an option given to `dump_to`, which Ekorn's `dump_to` would need
    to take first, so a message to Ekorn-Pipeline;
  - a function of DBIx::Squirrel's that sets it.

  The alias needs nothing of Ekorn's, works as the setting does today,
  and keeps `local`, which a function can't.

  Amended by Iain on 2026-11-26, as work started: tied, not aliased.
  Tried first, `local` on an aliased package variable gave our name a
  fresh value of its own for the scope, which Ekorn's variable never
  saw, so the alias's reason for being chosen, that `local` on either
  sets both, was false. A tie of the same name passes every read and
  write to Ekorn's, `local`'s included, and `local` puts Ekorn's value
  back as its scope ends: a caller sees what D1 promised.

## The plan

**What:** `$DBIx::Squirrel::Stages::Taps::DumpSecrets`, standing for
`$Ekorn::Pipeline::Stages::Taps::DumpSecrets`, so `local` on either
sets both.

**Why:** `dump_to` writes each value in full while Ekorn's variable is
set, and Part 1 of the documents can't name it.

**Steps:**

1. The variable, in DBIx::Squirrel::Stages::Taps, with a comment
   saying why it's done as it is; its POD.
2. `t/20-stages-taps.t`: set on ours, it's Ekorn's; with `local` on
   ours, Ekorn's too, put back after; with `local` on Ekorn's, ours
   reads it.
3. The reference's Part 1 names it, in place of Part 2's "Settings of
   the pipeline", which says it stands for Ekorn's; its index too;
   `scripts/manuals`.
4. `Changes`, this record and `ROADMAP.md`.

**Done when:** the variable is tested, `local` on it included, in
DBIx::Squirrel::Stages::Taps' POD and the reference's Part 1, with a
`Changes` line, and `yath test -L t xt` passes on 5.36 and 5.44.

## What happened

- **Outcome:** done. `yath test -L t xt` passes on 5.36 and 5.44,
  against Ekorn-Pipeline's working copy at
  446058f8873907be8d53f2befd49bbaa70e6f101.
- **Changes from the plan:** a tie in place of the alias, as D1's
  amendment says, found by testing `local` on an alias before writing
  the code. The comment above the `tie` answers why, as Iain asked:
  why not an alias.
