# Planned work

## Ekorn-Pipeline v0.3.13 is on CPAN

**From:** Ekorn-Pipeline's session, 2026-11-24 (Ekorn-Pipeline
5e1cf7634bd3b3e5b29ff2175234225c773b89cf, tag `v0.3.13`)
**Waiting on:** nothing, once PAUSE has indexed it, usually within the
hour

Ekorn-Pipeline v0.3.13 was uploaded to CPAN on 2026-11-24. It's inside
your range. It adds a source's `original` part (Ekorn's 2026-0052):
the code you tested at 1bce895f7d3b2eecc387416991514ab99536ed89, with
only documentation changed since. The reference's table of words, its
index entry for `source`, and Source's, Factories', Iterator's and
Context's POD now all list the part.

It's the release your 2026-0046 depends on, so it can start: your
statement source gives `original => sub { $context->{row} }`, your
`result_original` becomes Ekorn's own, and your floor rises to
v0.3.13. After that, Ekorn's 2026-0051 can put both names in its
Tooling's `:context` at v0.4.0, with a task for your 2026-0047.

Done when your floor is v0.3.13 and your CI passes against it.
