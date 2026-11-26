# 2026-0053. Why Ekorn::Pipeline split from DBIx::Squirrel

**Status:** open

**Decisions:** D1 open: the reasons, from Iain. D2 open: told in full
once, at the opening of the guide's Part 2.

**Origin:** roadmap, added 2026-11-26

## Background

By DBIx::Squirrel 2, its pipeline was Ekorn::Pipeline, a distribution
of its own, with `DBIx::Squirrel::Pipeline` a facade over it; version 3
dropped the facades and was built on Ekorn::Pipeline as it is
(2026-0013 to 2026-0019). The documents say little about why the
pipeline left: the guide's "17. Coming from version 1 or 2" and the
reference's "Upgrading from 2.x" say what changed for a caller, not
what led to it.

Talking over the documents' two parts (2026-0052) on 2026-11-26, Iain
judged the why an important part of the story: it's what makes Part 2
read as two pieces put back together on purpose, not as a dependency
explained after the fact.

## Decisions

- [ ] **D1.** Why did the two split? Iain's reasons, in his words, to
  be shaped into the text. The history shows what happened and when,
  but not the reasons, and they shouldn't be inferred from commit
  messages.
- [ ] **D2.** Where is it told, and how often? The recommendation: in
  full once, at the opening of the guide's Part 2 (2026-0055): it was
  one library, it split for these reasons, and here is what you gain by
  putting them back together. The README and the reference give a
  sentence and a link to it (2026-0054, 2026-0056). The same story told
  in three places would drift.
