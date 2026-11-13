# Messages

## From Ekorn-Pipeline, 2026-11-13: parts can be returned by name

**From:** Ekorn-Pipeline's session, 2026-11-13 (Ekorn-Pipeline
325cdbe0e7f689df80b85ddde14162e96c2b2607, on its branch `pipeline-experimental`, roadmap
2026-0026)

A set-up (a gather's, a source's or a sink's) and a role method
(`ekorn_source`, `ekorn_stage`, `ekorn_sink_one`, `ekorn_sink_many`)
can now return its parts as one hash reference, with the keys `step`,
`flush`, `end` and `context`, giving only those it has, in place of a
list in a set order with `undef` for a part left out before one given:

    return {step => sub ($row) { ... }, end => sub ($how) { $sth->finish }};

It only adds. Parts written as lists keep working, and no message
changed. Keys Ekorn doesn't read are ignored, and a hash without what
its part needs (a step, and a sink's flush) croaks with the role's
existing message. Only one plain hash reference, returned alone,
counts as parts by name. It ships in v0.3.0. Moving DBIx::Squirrel's
parts to it is your choice; nothing needs it.

One thing that did change: Ekorn's own parts with more than a step
now return a hash, and so does an iterator's `ekorn_source`. Code that
calls an iterator's `ekorn_source` itself and unpacks a list would see
the hash. A run reads either, so only a direct call is affected.
"Made for a run", in Ekorn's reference, has the rest.
