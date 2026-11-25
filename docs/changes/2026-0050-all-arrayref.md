# 2026-0050. An iterator's all_arrayref

**Status:** shipped, unreleased

**Decisions:** D1 settled: `all_arrayref`, as Ekorn's.

**Origin:** a message from Ekorn-Pipeline's session, 2026-11-25
(Ekorn-Pipeline 50021bf8acfb5083649758f23df5ae50b252c50b)

**Started:** 2026-11-25

**Finished:** 2026-11-25

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

## The plan

**What:** a method, `all_arrayref`, on DBIx::Squirrel::Iterator,
returning every result still to come as an array reference, in any
context, reading the run to its end as `all` does.

**Why:** `all` gives a reference only in scalar context, so a caller
who wants one in a hash constructor, an argument list or a sub's
return has to write `scalar`, or gets a flattened list without a
word (Background); and Ekorn's iterator gains the method, which ours
should match.

**Steps:**

1. `lib/DBIx/Squirrel/Iterator.pm`: `sub all_arrayref ($self) {
   return scalar $self->all }`, after `all`, so it keeps `all`'s
   fetching of the rest at once without stages; in the POD, a
   `=head2 all_arrayref` after `all`, `all`'s entry pointing to it.
2. Tests in `t/24-iterator-source.t`, beside `all`'s: in list context,
   in a hash constructor and as an argument, it gives one reference;
   with no results left, an empty array reference, not an empty list;
   without stages, the rows left, in one fetch, as `all`; with stages,
   the results; after it, `ended` is `done`, the statement is
   finished, and `next` gives nothing.
3. `docs/REFERENCE.md`: under The iterator's methods, `all_arrayref`
   beside `all`, with an example building a hash; an index entry
   under DBIx::Squirrel::Iterator; `scripts/manuals` run, and
   `xt/manuals.t`, `xt/examples.t` and `xt/reference-index.t` passing.
4. `Changes`, under Unreleased: a precis naming roadmap 2026-0050,
   and the entry; the item leaves `ROADMAP.md` in the same commit.

**Done when:** the method, its tests and its POD are in; the
reference and `Changes` say so; `yath test` passes on 5.36 and 5.44,
against Ekorn's working copy, coverage stays above its floors, and
perlcritic and perltidy are clean.

## What happened

- **Outcome:** done as planned. `all_arrayref` returns `scalar
  $self->all`; its tests, its POD, the reference's text and index
  entry, and `Changes` are in. `yath test -L t xt` passes on 5.36 and
  5.44 against Ekorn-Pipeline's working copy at
  60754fd66a6a2711af43e0676fe0db14b58e9679, which has Ekorn's own
  `all_arrayref`; the test passes under `prove` too; coverage stays
  above its floors; perlcritic and perltidy are clean.
- **Changes from the plan:** none.
- **What's left:** nothing. Nothing here calls Ekorn's
  `all_arrayref`, so our range of Ekorn versions stays as it is.
