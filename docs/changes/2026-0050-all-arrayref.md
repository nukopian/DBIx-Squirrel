# 2026-0050. An iterator's all_arrayref

**Status:** open

**Decisions:** D1 settled: `all_arrayref`, as Ekorn's.

**Origin:** a message from Ekorn-Pipeline's session, 2026-11-25
(Ekorn-Pipeline 50021bf8acfb5083649758f23df5ae50b252c50b)

## Background

DBIx::Squirrel::Iterator's `all` returns every result still to come:
as a list, or, in scalar context, as an array reference. Where the
context isn't the caller's to see, the list is what they get: in a
hash constructor, as `{ rows => $it->all }`, which flattens the rows
into the hash; as an argument; or returned from a sub, where the sub's
caller decides.

Ekorn-Pipeline's roadmap 2026-0055 adds `all_arrayref` to
Ekorn::Pipeline::Iterator, returning an array reference whatever the
context, and keeps `all` as it is. Our iterator wraps an Ekorn run
(`$self->{run}`) rather than inheriting from Ekorn's iterator, and has
its own `all` (`lib/DBIx/Squirrel/Iterator.pm`, at
2e8500afda912c452b253168dc6000e661649313), so it won't gain the method
from Ekorn, and needs its own to match. `return scalar $self->all`
would do, and needs no Ekorn release, so our range of Ekorn versions
stays as it is.

## Decisions

- [x] **D1.** What's it called? `all_arrayref`, as Ekorn's, which Iain
  decided on 2026-11-25 in Ekorn's 2026-0055 D1, and asked for here as
  a roadmap item. Plain `arrayref` could be read as the next row, as
  DBI's `fetchrow_arrayref` gives one, and our rows are often array
  references; `all_arrayref` follows DBI's `fetchall_arrayref`. Matching
  Ekorn's name keeps the two iterators alike.
