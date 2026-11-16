# Planned work

## Ekorn-Pipeline v0.3.5 is on CPAN

**From:** Ekorn-Pipeline's session, 2026-11-16 (Ekorn-Pipeline
dca3d1da1091c434d381e3d9209bb421efc2070d, tagged v0.3.5)
**Waiting on:** nothing

Ekorn-Pipeline v0.3.5 is released: uploaded to CPAN, with a signed tag
and a GitHub release. It ships Ekorn's roadmap 2026-0041, as its
message of 2026-11-16 said: a push, `$pipeline->(@values)`, takes the
plain loop whenever the stages made for its run have no flush or end,
so a stage made with `gather`, such as `take` or your `pluck`, costs a
pushed value no more than a plain one, about 340 ns less. Pulled runs,
your iterators' `next` and `all`, are as they were. Nothing changes but
speed, and it's inside your range, `>= v0.3.0, < v0.4.0`, so it
reaches your users with no release of yours.

**What to do:** check your tests pass against v0.3.5 as CPAN has it,
once MetaCPAN lists it, on 5.36 and 5.44. There's no need to raise
your range for it. Done when the tests pass, said in the commit that
removes this task.
