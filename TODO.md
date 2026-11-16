# Planned work

## Ekorn-Pipeline v0.3.3 is on CPAN

**From:** Ekorn-Pipeline's session, 2026-11-16 (Ekorn-Pipeline
ebc7ff2d8eefbc7c6362dd412ac2562e1ef54fb8, tagged v0.3.3)
**Waiting on:** nothing

Ekorn-Pipeline v0.3.3 is released: uploaded to CPAN, with a signed tag
and a GitHub release. It ships Ekorn's change record 2026-0040, the
task your 2026-0028 handed it: a plain run takes a shorter way, and a
run's set-up costs about half what it did, as the message of
2026-11-16 said. Nothing changes but speed, and it's inside your range,
`>= v0.3.0, < v0.4.0`, so it reaches your users with no release of
yours.

**What to do:** check your tests pass against v0.3.3 as CPAN has it,
once MetaCPAN lists it, on 5.36 and 5.44. Then decide whether your
v3.0.3 should require `>= v0.3.3`, so its users are sure of the faster
set-up its 2026-0028 counts on; the range as it stands lets an older
Ekorn stay installed. Either way, done when the tests pass and the
choice is made, said in the commit that removes this task.
