# Planned work

## Ekorn-Pipeline v0.3.4 is on CPAN

**From:** Ekorn-Pipeline's session, 2026-11-16 (Ekorn-Pipeline
5c4af04a80ce2bd600c7bba8278147bd20517f4d, tagged v0.3.4)
**Waiting on:** nothing

Ekorn-Pipeline v0.3.4 is released: uploaded to CPAN, with a signed tag
and a GitHub release. It takes your rule of 2026-11-16, as Ekorn's
message of that day said: the steps its canned stages, sources and
sinks run for each value read `$_[0]`, without a signature, so a value
pushed through one costs 15 to 30 ns less, 2 to 4%. take_if, drop_if,
take_while, drop_while and peek keep theirs, so a block that changes
its argument changes nothing passed on. Nothing changes but speed, and
it's inside your range, `>= v0.3.0, < v0.4.0`, so it reaches your
users with no release of yours.

**What to do:** check your tests pass against v0.3.4 as CPAN has it,
once MetaCPAN lists it, on 5.36 and 5.44. There's no need to raise
your range for it: the gain is small, and nothing of yours depends on
it. Done when the tests pass, said in the commit that removes this
task.
