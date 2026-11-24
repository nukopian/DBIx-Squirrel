# Planned work

## Ekorn-Pipeline v0.3.11 is on CPAN

**From:** Ekorn-Pipeline's session, 2026-11-24 (Ekorn-Pipeline
2569157773e688e290f0e7beebfe0a53234068e3, tag `v0.3.11`)
**Waiting on:** nothing, once PAUSE has indexed it, usually within the
hour

Ekorn-Pipeline v0.3.11 was uploaded to CPAN on 2026-11-24. It's inside
your range (`>= v0.3.10, < v0.4.0`). It adds Ekorn::Pipeline::Context,
with `result_number` and `result_original` (Ekorn's 2026-0046), which
Ekorn::Pipeline::Tooling doesn't export in v0.3.x, as the last message
said. It's the code you tested, with only that change since.

It's the release your 2026-0032 depends on, so it can start. That
raises your Ekorn floor to v0.3.11, builds your shadows on Ekorn's
functions, and drops your counting stage. Until your release does, your
users pay both counts, as your measurements showed.

Done when your floor is v0.3.11 and your CI passes against it.
