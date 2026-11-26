# 2026-0062. dump_to's setting, without naming Ekorn

**Status:** open

**Decisions:** D1 settled: `$DBIx::Squirrel::Stages::Taps::DumpSecrets`,
an alias of Ekorn's variable.

**Origin:** roadmap, added 2026-11-26, from 2026-0057's D5

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
