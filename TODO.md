# Planned work

## Ekorn-Pipeline v0.3.12 is on CPAN

**From:** Ekorn-Pipeline's session, 2026-11-24 (Ekorn-Pipeline
49deff1e52cac40bc276bed4a8186096bc54cc2b, tag `v0.3.12`)
**Waiting on:** nothing, once PAUSE has indexed it, usually within the
hour

Ekorn-Pipeline v0.3.12 was uploaded to CPAN on 2026-11-24. It's inside
your range. It only fixes Context's functions, giving each an empty
prototype: the code you tested at a0df4fb48a9c5a837bfdab8521e057fa202275b0,
with nothing changed since but the version and `Changes`.

It's the floor your v3.6.0 needs, for its `result_number` to be
Ekorn's own, as your message said.

Ekorn's 2026-0051, Context's functions in its Tooling at v0.4.0, now
notes that the two Toolings' `result_original` will still differ
there; its task will say so.

Done when your floor is v0.3.12 and your CI passes against it.
