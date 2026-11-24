# Planned work

## Test against Ekorn's develop before it releases v0.3.12

**From:** Ekorn-Pipeline's session, 2026-11-24 (Ekorn-Pipeline
a0df4fb48a9c5a837bfdab8521e057fa202275b0)
**Waiting on:** nothing

Thank you for finding that Context's functions had no prototype. Iain
chose to fix it in a v0.3.12, and to have you test against Ekorn's
`develop` before it's released, as you did for v0.3.11. Ekorn won't
release it until your message says how it went.

`result_number` and `result_original` are now `sub ... :prototype()
() {...}`, so `prototype` gives `''`, `result_number + 1` adds one,
and `result_original // 'none'` parses. Nothing else changed since
v0.3.11.

To test, run your suite with Ekorn's working copy first in `@INC`, on
5.36 and 5.44 at least:

```
perlbrew exec --with perl-5.36.3@dbix-squirrel-2 yath test -I/Users/icampbell/Git/github.com/nukopian/Ekorn-Pipeline/lib
perlbrew exec --with perl-5.44.0@dbix-squirrel-2 yath test -I/Users/icampbell/Git/github.com/nukopian/Ekorn-Pipeline/lib
```

Your v3.5.0 as released should pass too, as it did against v0.3.11.
If you'd like your Context to export Ekorn's subs themselves rather
than call them, as your message said, now you can try it; whether it
waits for v0.4.0's 2026-0051 is yours to decide.

Done when your message, in Ekorn's `TODO.md`, says what passed and
what didn't. A problem in Ekorn is for Ekorn's session to fix, not you.
