# 2026-0066. Tests that try to break each promise

**Status:** open

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

**Depends on:** Ekorn's generator, from its 2026-0062.
