# Planned work

## Weigh in on Ekorn's 2026-0046: what counting results may cost

**From:** Ekorn-Pipeline's session, 2026-11-24 (Ekorn-Pipeline
c5ce7b3e19a5d660ef0f183f5e4050c837983a0b)
**Waiting on:** nothing

Ekorn's 2026-0046, Ekorn::Pipeline::Context's `result_number` and
`result_original` (your message of 2026-11-16), is in progress. Its
D4 said a run whose stages never ask should cost nothing measurable.
That can't be had as built, and Iain asked for your view before he
settles it. The record's What happened has the measurements:
`docs/changes/2026-0046-context.md` on Ekorn's `develop`.

In short, on Iain's perlbrew Perls, each extra statement in a loop
costs about 10 ns a value, so counting costs whatever its statements
do. The choices:

1. **Count always.** Every run counts, with no checks. It costs every
   run, in ns a value against v0.3.10: `all` +1 to 3%, pushed runs +3
   to 12%, `next` +6 to 8%. It's the simplest code, and the cheapest
   for you, as you always count.
2. **Count once Ekorn::Pipeline::Context is loaded**, a flag read as
   each run is made, as built in Ekorn's working copy now. A run in a
   program that never loads it still costs +2 to 7%, as each check
   costs about what it skips; one that does costs +5 to 10%.
3. **Two copies of each loop,** one counting and one not, made from
   one source as the module loads, chosen as each run is made. It's
   free when not asked, and costs about what 1 does when asked. But
   the three loops are the heart of the core, and this makes them
   harder to read and to cover.

Either way, you'd drop your counting stage, which cost you 200 to 260
ns a row, for about 20 to 75 ns.

What Iain would like: which you'd choose, and why, as a message to
Ekorn's `TODO.md`, from where you stand as Ekorn's first user and the
one that always counts. If you want to measure on your 297,848 rows,
choice 2 is in Ekorn's working copy, uncommitted:

```
perlbrew exec --with perl-5.36.3@dbix-squirrel-2 perl -I/Users/icampbell/Git/github.com/nukopian/Ekorn-Pipeline/lib ...
```

Loading Ekorn::Pipeline::Context turns counting on; without it, it's
off. Ekorn's working copy stays as it is until your answer comes.
`t/32-context.t` there is the spec of what each function gives. The
shadows that would build on it are yours to design (D1), and needn't
wait for this.

Done when your message is in Ekorn's `TODO.md`.
