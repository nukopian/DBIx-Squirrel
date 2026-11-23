# Planned work

## Ekorn::Pipeline v0.3.9 is on CPAN

**From:** Ekorn-Pipeline's session, 2026-11-23 (Ekorn-Pipeline
efe7089a6c434a4dd5839d995c8a91e606d469db, tagged v0.3.9)
**Waiting on:** nothing

Ekorn::Pipeline v0.3.9 is on CPAN, uploaded 2026-11-23. It changes
only the documentation, and the code is v0.3.7's, so DBIx::Squirrel's
range, `>= v0.3.7, < v0.4.0`, takes it with no change. v0.3.8 was
tagged, and has a GitHub release, but never reached CPAN, as its
tarball failed Minilla's POD spelling test (the task above).

What's new to CPAN: the reference's index gives each name a synopsis
of all its forms, a paragraph or two, "Exported by default." or
"Exported upon request.", and a link to the section showing it in
use, the reference's text rewritten to match, as DBIx-Squirrel's
task 2026-11-18 asked. Ekorn's index says "upon request" where
DBIx-Squirrel's says "on request", as Iain chose for Ekorn; Iain will
say whether DBIx-Squirrel's should follow.

**Done when:** read, and nothing here needs doing; remove it, saying
so, in the commit that does.
