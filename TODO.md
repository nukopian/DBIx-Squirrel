# Planned work

## Test against Ekorn's develop before it releases v0.3.15

**From:** Ekorn-Pipeline's session, 2026-11-24 (Ekorn-Pipeline
3f18f252191f19ecaa6969e92d0598cf7fe5094b, roadmap 2026-0051)
**Waiting on:** nothing

Ekorn's 2026-0051 is built, on its `develop`, unreleased: its
Tooling exports `result_number` and `result_original` in a `:context`
tag and in `:all`. Iain made it a **v0.3.x, v0.3.15**, not the v0.4.0
first planned. Your v3.6.1 exports Ekorn's own functions under both
names, so the two Toolings agree, and a v0.4.0 would fail v3.6.1's
installs, as its range is `< v0.4.0`. Ekorn won't release until your
message says how your test went.

**Your 2026-0047** waited for this at v0.4.0, to widen your range.
It's no longer tied to it: v0.3.15 is inside your range. It's yours to
drop, or to keep for whenever Ekorn has a v0.4.0 for its own reasons.

Your v3.6.1's `t/28-tooling.t` and `xt/ekorn-tooling.t`, from its tag,
already pass against Ekorn's working copy, run with `prove` on 5.36.
Your v3.6.0 and v3.5.0, whose `result_original` was their own, would
fail their own `t/28-tooling.t` beside it, as older releases than the
one CPAN's index gives.

To test, run your whole suite with Ekorn's working copy first in
`@INC`, on 5.36 and 5.44 at least:

```
perlbrew exec --with perl-5.36.3@dbix-squirrel-2 yath test -I/Users/icampbell/Git/github.com/nukopian/Ekorn-Pipeline/lib
perlbrew exec --with perl-5.44.0@dbix-squirrel-2 yath test -I/Users/icampbell/Git/github.com/nukopian/Ekorn-Pipeline/lib
```

Done when your message, in Ekorn's `TODO.md`, says what passed and
what didn't, and what becomes of your 2026-0047. A problem in Ekorn is
for Ekorn's session to fix, not you.
