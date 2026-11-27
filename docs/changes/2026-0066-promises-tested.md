# 2026-0066. Tests that try to break each promise

**Status:** shipped, unreleased

**Decisions:** D1 settled: an agreement test of our own. D2 settled:
Ekorn's generator, copied as it is. D3 settled: the rule, in Ekorn's
words, where decisions are settled. D4 settled: a one-time list of
our promises, each tried. D5 settled: the same check in step 1 of
Making a release.

**Origin:** roadmap idea, added 2026-11-27, from Ekorn-Pipeline's
message on its idea 2026-0062 (Ekorn-Pipeline
125e4b315d2f152f4281cea53418154c2d8b5017); agreed by messages both
ways, ending with Ekorn-Pipeline's of 2026-11-27 in our 9f51052. Its
counterpart is Ekorn-Pipeline's roadmap 2026-0062.

**Depends on:** Ekorn-Pipeline's generator, from its 2026-0062, ready
at Ekorn-Pipeline dae3e85f25e1468607c30662d56ee918f6db6f0a

**Started:** 2026-11-27

**Finished:** 2026-11-27

## Background

Ekorn's 2026-0060 fault, originals wrong past stages that hold values
back, passed every wash-up and review in both projects. Each checked
code against tests and tests against examples, and every one of them
used maps, so nothing tried the promise, 2026-0046's D3, with a stage
it didn't mention. Checking that things agree can't find a fault they
all share.

A probe against our v4.3.0 tried six promises our suite tests only
with maps, using stages that hold values back, stop, die or nest:
`iterator` in values from `batch`'s flush; `result_number` after
`take_last` and `batch`; the statement no longer `Active` after a
stop past `batch`, a die past `take_last`, a die in `batch`'s flush,
and `take(1)` past `batch`; `first` after `take_last`; a nested
statement run in `batch`'s flush keeping its own original; and `all`,
`next` and `|` agreeing over `batch`. All held, but none is in the
suite.

## Decisions

Each settled by Iain on 2026-11-27, as the two sessions agreed and as
recommended.

- [x] **D1.** A test of our own? Yes: an agreement test comparing
  values and originals across `all`, `next`, `first`, `|`, a pipeline
  of the user's and a sink, with stages that hold values back, split,
  stop, die and run nested; after each stop or die, the statement run
  again gives what a fresh run gives, and isn't `Active` after
  either.
- [x] **D2.** The generator? Ekorn's `xt/lib/RandomPipelines.pm`,
  copied as it is, its header naming the Ekorn-Pipeline commit it came
  from and its contract: values opaque but for the caller's `number`
  (ours, a row's first column), extra makers from the caller (ours, a
  nested statement run and a stage reading the run's context, such as
  `pluck` and `as_hash`), and driven by the caller's `srand`, whose
  seed the driver prints. A change to it goes to Ekorn as a message.
- [x] **D3.** The rule, in `docs/changes/README.md` beside how
  decisions are settled, in the same words as Ekorn's:
  > **A promise is tested against what it doesn't mention.** A
  > decision that promises something of every value or every run
  > names, when it's settled, the test that tries to break it with
  > stages the decision doesn't mention: one that holds values back,
  > splits, stops, dies or runs nested. The item doesn't ship until
  > that test passes.
- [x] **D4.** Promises already made? A one-time list of our settled
  decisions promising something of every value or every run, each
  with a test that tries it, as part of this item.
- [x] **D5.** Between decisions? The same sentence as a check in step
  1 of `docs/MAINTAINING.md`'s Making a release, as Ekorn puts it in
  its own, rather than in the shared practice's wash-ups, which this
  repository doesn't import.

## The plan

**What:** `xt/lib/RandomPipelines.pm`, copied from Ekorn-Pipeline as
it is; `xt/agreement.t` over it; the rule in this directory's README;
the check in step 1 of Making a release; and the list of D4, each
promise with the test that tries it.

**Why:** as Background says.

**Steps:**

1. Copy the generator, naming its commit in its header.
2. `xt/agreement.t`: a result set over a table made for each case,
   read six ways (`all`; `all` again after `reset`; `next`; a chain
   made with `|`; a pipeline of the user's reading the iterator; a
   sink given last), comparing values, numbers and originals, each
   original checked against the truth, and the statement checked no
   longer active; makers of ours for a nested statement run, `pluck`
   and `as_hash`.
3. Break `lib` on purpose in scratch copies, to see the test fail.
4. The D4 list, and a test for each promise the agreement test
   doesn't reach.
5. The rule and the check; the suite; this record; a message to Ekorn.

**Done when:** the agreement test passes on 5.36 and 5.44 and in CI,
fails on each fault put in on purpose, the rule and the check are in
place, and each listed promise has its test.

## The promises of D4

Each a settled promise of every value or every run, with the test that
tries it against stages it doesn't mention:

| Promise | Made in | Tried by |
|---|---|---|
| `result_original` is the row a result is made from | 2026-0046, 2026-0065 | `xt/agreement.t`, each original against the truth |
| `result_number` counts results, in every run | 2026-0032's D1 | `xt/agreement.t`, the numbers compared every way |
| `iterator` is the iterator in its own stages, and none elsewhere | 2026-0032's D3 | `t/26-context-in-pipelines.t`, after `batch` |
| a statement is finished however its run ends | the reference, `all` and the iterator's end | `xt/agreement.t`, not active after each way |
| a chain made with `\|`, a pipeline reading the iterator, and a sink given last give what the iterator's stages give | 2026-0014, 2026-0016, 2026-0049 | `xt/agreement.t`, its six ways |
| `first` gives the first result | the reference, `first` | `t/26-context-in-pipelines.t`, after `take_last` |

## What happened

- **Outcome:** done as planned. `xt/agreement.t` passes 3,000 cases
  on Perl 5.36 and 5.44, about seven seconds each; it runs 1,000 by
  default, `DBIX_SQUIRREL_AGREEMENT_CASES` setting more.
- **Broken on purpose:** in scratch copies of `lib`, a statement's end
  not finishing it failed the test (a chain and a pipeline left it
  active), and an original answering for the row after the right one
  failed it every way.
- **Changes from the plan:** the truth check couldn't be Ekorn's
  as it is. Our `pluck` and `as_hash` can take a row out of a batch,
  as `pluck('n')` gives a `collect`'s first row, whose original is
  rightly none; so in a case with either, a value may have no
  original, and only a wrong one fails. Every other case needs each
  row's own. And `all` read twice gives nothing the second time, as
  documented, so the run again calls `reset` first.
- **For Ekorn:** the generator needed nothing changed.
