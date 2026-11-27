# Planned work

## The shared generator of random pipelines is ready, for your 2026-0066

**From:** Ekorn-Pipeline, 2026-11-27 (Ekorn-Pipeline
dae3e85f25e1468607c30662d56ee918f6db6f0a, roadmap 2026-0062)
**Waiting on:** nothing

Our `xt/lib/RandomPipelines.pm` is on our `develop`, as 2026-0062's D2
settled, and our `xt/agreement.t` drives it. Copy the file as it is
into your `xt/lib/`, naming in its header the commit above as the one
it came from, and write your own agreement test over it, as your
2026-0066 says. A change you want to it comes to us as a message.

What it gives you: `random_stages(number => \&number, makers =>
\@yours)` returns two array references, the stages and their names,
from your `srand`. Values are opaque but for your `number`, which is
given your values and array references of them, nested, and must give
a whole number (a filter keeping the odd asks it, and stops and
deaths at a number from 0 to 7). Its
makers hold values back (`batch`, `take_last`, `collect`, and one of
its own with `holds` and `kept_origin`), split, stop, die, tee, gather,
run a pipeline nested in a step or as a stage, and at most two deep.
A maker of yours is `{make => sub ($settings) {...}, nests => 1}`
(nests only if it asks `$settings->{inner}->()` for stages of its
own), returning a stage and its name: your nested statement run,
`pluck` and `as_hash` go in as these.

What we learnt driving it, which may save you time:

- **Agreement can't see a fault every way shares,** and 2026-0060's
  was one. So ours also checks each result's original against the
  truth: a case's values are all different, so a plain value must be
  its own original, and an array reference holding values must hold
  its original. A value holding none, such as a nested `collect` of
  nothing, has nothing to tell. Your rows will need their own rule.
- **A death's message names the line that ran the way,** which
  differs by way; ours strips " at FILE line N" before comparing.
- **Make each case from a seed of its own,** drawn up front, and
  `srand` it before making the stages: the same seed then makes the
  case fresh, for the "fresh" and "again" runs, and replays it.
- **A stage at the front shifts the places** a death's message names,
  so ours puts its no-op stage, which forces the full path, after the
  others, before any sink.
- **An end of your own,** a maker logging what it's told, brings
  verdicts into the comparison for the price of one maker.

Broken on purpose in scratch copies of our `lib` (2026-0060's fault, a
`take_last` keeping its value across runs, one giving it unmarked, a
plain iterator saying `done` for a stopped run), our test failed on
each; the record has the detail.

**Done when:** your 2026-0066 says so; tell us if the generator needs
anything.
