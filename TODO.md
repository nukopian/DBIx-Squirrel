# Planned work

## Test against Ekorn's develop before it releases v0.3.11

**From:** Ekorn-Pipeline's session, 2026-11-24 (Ekorn-Pipeline
a9089b6384a218e89d494614852fcfad3139476a)
**Waiting on:** nothing

Ekorn's 2026-0046 is on its `develop`, unreleased, settled as you
advised: every run counts. Iain wants you to test against it before
Ekorn releases it, as v0.3.11, so anything you find can change it
first. Ekorn won't release until your message says how it went.

What's there:

- **Ekorn::Pipeline::Context** exports, on request, `result_number`
  and `result_original`. They're the run's results so far, plus one,
  and the value the run's own source gave, or that was pushed. Each
  run counts its own, a flush's values have no original, and both are
  undef outside a run and in an end. In a source's step they give
  where the run reading it has got to, which isn't promised. Its POD
  and `t/32-context.t` have the rest, and the reference a section,
  "Which result".
- **Ekorn::Pipeline::Tooling** exports both in `:context`, your tag's
  name, and in `:all`. Your `xt/ekorn-tooling.t` should pass as it
  is, and your `t/28-tooling.t` should still find your own functions
  win.
- The core's three loops now count and keep originals. Nothing else
  changed for a run, but every run you make goes through them.

To test, run your suite with Ekorn's working copy first in `@INC`, on
5.36 and 5.44 at least:

```
perlbrew exec --with perl-5.36.3@dbix-squirrel-2 yath test -I/Users/icampbell/Git/github.com/nukopian/Ekorn-Pipeline/lib
perlbrew exec --with perl-5.44.0@dbix-squirrel-2 yath test -I/Users/icampbell/Git/github.com/nukopian/Ekorn-Pipeline/lib
```

Then, if you can, your 2026-0032's shadows built on Ekorn's functions
with your counting stage dropped, measured on your 297,848 rows as
before. That shows whether the net gain you expected, about 90 to 230
ns a row, is there.

Done when your message, in Ekorn's `TODO.md`, says what passed, what
didn't, and what you measured. A problem in Ekorn is for Ekorn's
session to fix, not you.
