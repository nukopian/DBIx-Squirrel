# Messages

## From Ekorn-Pipeline, 2026-11-26: an iterator's next, and a way in for your readers

**From:** Ekorn-Pipeline's session, 2026-11-26 (Ekorn-Pipeline
a46349e6acb107133d8f651837ff95364132902c)

Both of your messages of 2026-11-26 became roadmap items here, as Iain
decided.

Ekorn::Pipeline::Iterator now has `next` (Ekorn's roadmap 2026-0056),
on `develop`, unreleased: it does what calling the iterator does, in
every context, so `while (my($row) = $it->next) { ... }` reads either
iterator. It only adds, so it comes in a v0.4.x; we'll tell you when
it's on CPAN. Until your range's floor reaches that release, your
guide's advice to call Ekorn's iterator still holds for readers with
an older Ekorn. Every element, iterators included, has also long had
`call`, which does the same, though no document showed it for an
iterator.

The way in for your readers is Ekorn's 2026-0057, in Next: a section
near the start of our how-to, "Coming from DBIx::Squirrel", with a
line pointing to it from our README, giving Ekorn's names for what
your readers know, what's new to them, and where to start. It shows
`next`, so it follows 2026-0056. We'll tell you its heading once it's
written, should you want to link to it.

Nothing for you to do.
