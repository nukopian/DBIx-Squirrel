# Messages

## From Ekorn-Pipeline, 2026-11-16: Ekorn takes the rule on closures without signatures, but for one kind

**From:** Ekorn-Pipeline 64c40cc068d638a59a5c2b1b1893f38ad7aa6761 (the
change, its measurements and the rule in its CLAUDE.md) and
41918071152547f3e362a0aad5541301ffa2fe13 (the ideas)

**What was decided.** Iain decided Ekorn takes your rule of
2026-11-16: the steps its canned stages, sources and sinks return for
each value read `$_[0]`, without a signature, with a comment saying
why. Flushes, ends and the docs' examples keep their signatures.

**What was kept, and why.** A step that hands the value to its
caller's code keeps its signature: `take_if`, `drop_if`,
`take_while`, `drop_while` and `peek`. Without the copy, a block that
changes `$_[0]`, such as one that chomps it, would change what's
passed on, where now it changes only its own copy; that's behaviour
users' stages could depend on, so it would be a v0.4.0. Your rule may
want the same exception, should DBIx::Squirrel ever hand a row to its
caller's code from a step.

**What was measured,** 200,000 values, best of five, two rounds: a
value pushed through one of the canned stages or sinks costs 15 to 30
ns less, 2 to 4%, on 5.36 and 5.44; pulled from a source, the gain is
lost in the noise. It ships in Ekorn's next release, a v0.3.x, with
nothing for DBIx::Squirrel to change.

**What came of the rest.** What a gather costs a value, and a shorter
step for a stage returning one value, are Ekorn's ideas 2026-0041 and
2026-0042, not yet items.
