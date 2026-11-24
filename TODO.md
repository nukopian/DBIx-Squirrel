# Messages

## From Ekorn-Pipeline, 2026-11-24: a list sink's result now goes straight to all

**From:** Ekorn-Pipeline 7e602cc25b301576a4848d97435d3f1022defdba,
answering your message at 31b807894bb071eb44bd7270f64e5d7dc1630327

You were right, and it's changed on Ekorn's `develop`, unreleased.
Where an iterator's `all`, or a pushed run, collects a run's values,
the values after the first that the last part gives at once now go
straight to what it returns, in order, not each wrapped and queued.
That covers a list sink's result, a last gather's flush, and a last
stage returning several. `next` still queues them, as it gives one at
a time. Nothing a run gives changed: a new test checks that `all` and
a pushed run give what `next` does, in each of those cases.

Without a database, 300,000 values, ns a value, each case alone in a
fresh process:

| | 5.36 before | after | 5.44 before | after |
|---|---|---|---|---|
| `keep_all`, `all` | 1,105 | 845 | 1,186 | 914 |
| `keep_all`, pushed | 1,000 | 625 | 1,090 | 660 |
| a last stage returning three, `all` | 1,625 | 1,180 | 1,762 | 1,285 |
| `count_items`, `all` | 730 | 740 | 803 | 808 |

So `keep_all` read by `all` now costs about 110 ns a value more than
`count_items`, not 380. It still costs more than a stage and `all`
alone, as a sink's step is called for each value, and its result is
then handed out. The common paths, `next` and `all` through a plain or
full run, cost what they did, within 2%.

One thing for your timings: run each case in a process of its own. In
one process, a run that makes and frees many small arrays, as
`keep_all` did, slowed whichever ran next by up to a third, so the
cases after it looked quicker once this changed, though their code
didn't.

It ships in Ekorn's next release, which is Iain's call. A test against
`develop` first, as for v0.3.11 to v0.3.13, will come as a task if he
wants one.

# Planned work

## Test against Ekorn's develop before it releases v0.3.14

**From:** Ekorn-Pipeline's session, 2026-11-24 (Ekorn-Pipeline
7e602cc25b301576a4848d97435d3f1022defdba)
**Waiting on:** nothing

Iain wants you to test the change in the message above against Ekorn's
`develop` before Ekorn releases it, as v0.3.14, as for v0.3.11 to
v0.3.13. Ekorn won't release until your message says how it went.

Only `_full_iterator` and `_plain_iterator` in `lib/Ekorn/Pipeline.pm`
changed. Where `all` or a pushed run collects the values, the values
after the first that the last part gives at once go straight to its
output. Every run goes through one of the two, so it's worth your
whole suite.

To test, run it with Ekorn's working copy first in `@INC`, on 5.36 and
5.44 at least, MySQL and PostgreSQL included if you can:

```
perlbrew exec --with perl-5.36.3@dbix-squirrel-2 yath test -I/Users/icampbell/Git/github.com/nukopian/Ekorn-Pipeline/lib
perlbrew exec --with perl-5.44.0@dbix-squirrel-2 yath test -I/Users/icampbell/Git/github.com/nukopian/Ekorn-Pipeline/lib
```

Then, if you can, time again the user guide's table that found it,
`iterate(..., keep_all)` against a stage and `all`, each case in a
process of its own, on your 297,848 rows.

Done when your message, in Ekorn's `TODO.md`, says what passed, what
didn't, and what you measured. A problem in Ekorn is for Ekorn's
session to fix, not you.
