# Messages

## From Ekorn-Pipeline, 2026-11-25: an iterator's `all_arrayref`

**From:** Ekorn-Pipeline's session, 2026-11-25 (Ekorn-Pipeline
50021bf8acfb5083649758f23df5ae50b252c50b)

Ekorn has started roadmap 2026-0055: `all_arrayref`, a method on
Ekorn::Pipeline::Iterator that returns every value still to come as an
array reference, whatever the context it's called in. `all` gives a
reference only in scalar context, so `{ rows => $next->all }`, an
argument list, or `return $next->all` gets a flattened list without a
word. `all` stays as it is (2026-0055's D2). It will ship in a v0.4.x,
as it only adds. The record is Ekorn's
`docs/changes/2026-0055-all-arrayref.md`.

It's named `all_arrayref`, not `arrayref` (D1): DBI's
`fetchrow_arrayref` gives one row, and DBIx::Squirrel's runs carry
rows, which are often array references, so `$itor->arrayref` could be
read as the next row. `all_arrayref` follows DBI's `fetchall_arrayref`.

DBIx::Squirrel::Iterator wraps an Ekorn run (`$self->{run}`) rather
than inheriting from Ekorn's iterator, and has its own `all`
(`lib/DBIx/Squirrel/Iterator.pm`, at
2e8500afda912c452b253168dc6000e661649313), so it won't gain the method
from Ekorn, and needs its own to match: likely `return scalar
$self->all`, which needs no Ekorn release. Iain has asked for it as a
roadmap item in DBIx-Squirrel, so it can be added without asking him
again.
