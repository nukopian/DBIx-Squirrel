# Messages

## From Ekorn-Pipeline, 2026-11-25: a quality review, and how Iain settled its questions

**From:** Ekorn-Pipeline's session, 2026-11-25 (Ekorn-Pipeline
707bbc2d310f70c8f9e110990b98bd667edc9822, and
f1fd15cb4d65000cd4b45451d25abdc84dac8962 on its branch
`experiment/2026-0053-pipe`)

Iain asked Ekorn's session for a quality review, and means to ask you
for the same. He asked that his prompts, and how the questions were
settled, come to you word for word, so that none is asked again here,
or settled differently by accident. Ekorn's roadmap 2026-0053 and its
record, `docs/changes/2026-0053-quality-release.md`, have the whole of
it, with each finding and the commit that fixed it.

### Iain's prompts

The first:

> I'd like a thorough quality review conducted. We are looking for
> inefficient and inconsistent code, errors, untested code,as well as
> code that should be but is not documented. We're also looking for
> slop and hallucinations, as well as documentation that is poor
> quality. The next release is a quality release.

The review came back with findings numbered 1 to 14, and four
questions. His answer, where his "8" is the finding that "new in
v0.3.0" appeared 21 times, though v0.3.0 was only a trial, and his
"6" the finding that CLAUDE.md's rule on blank lines and the code
disagreed:

> yes, write up 2026-0053 with the findings. Fix and test everything,
> itemising findings in Changes. Hand off anything that affects
> DBIx-Squirrel to DBIx-Squirrel, as I shall be asking the same of it.
>
> 8. Remove the "New in v0.3.0", it sounds unnecessarily repetetive.
>
> 6. Only one blank line above a sub's comment. Two above an
> uncommented sub.
>
> Module $VERSION. Happy to have them as long a they are kept in sync
> and are easy to maintain. I don't need stray $VERSIONS.
>
> Ensure `pipe` behaves consistently with our other code. It was one
> of the first routines written, so it may not be. Redocument as
> necessary and especially important to hand off to DBIx-Squirrel. I
> don't want the same questions there or an opportunity to settle them
> differently by accident.

Asked how `pipe` should behave, given three choices (as a pipeline;
the first result, but a sink's result where a sink is last; or as it
is, documented), he chose **"Same as a pipeline"**. Asked whether the
release should be one v0.4.0, or v0.3.16 for the fixes and then v0.4.0
for `pipe`, he chose **"v0.3.16, then v0.4.0"**. And while the work
went on:

> As part of the DBIx-Squirrel hand-off. Relay the prompt and how we
> settled the questions here.

### How they were settled (2026-0053's D1 to D6)

- **D1. Two releases:** v0.3.16, inside your range, with the fixes,
  the docs and the module versions; then v0.4.0, for `pipe`, which
  changes what code may depend on. A task below is for v0.4.0.
- **D2. `pipe` gives what a pipeline gives, in either context:**
  `$object->pipe(@stages)` is `Ekorn::Pipeline->new(@stages)->($object)`.
  In list context nothing changes. In scalar context it gave the first
  result, or undef; now it gives how many results came out, or a
  sink's result, a list sink's as an array reference. For one value,
  read it in list context, `my($x) = $object->pipe(...)`, or end with
  `keep_first`. Your handles inherit it: see the task.
- **D3. "New in v0.3.0" removed, not replaced** with v0.3.1, as
  needlessly repetitive. Later "new in" notes stayed. If your docs say
  the same thing over and over of one version, the same reasoning
  applies.
- **D4. One blank line above a sub's comment, two above a sub
  without one,** as both CLAUDE.md's say, the code made to follow,
  in `lib/`, `t/`, `xt/` and `scripts/`. Ekorn's code had two above a
  comment 110 times. Perl::Tidy, with Iain's `.perltidyrc`, makes two
  above a sub without a comment even straight after a block opens,
  and above `sub {` starting a line inside a list, so a closure
  returned in a list is named in a variable first. Ekorn's CLAUDE.md
  now says so, in place of "Perl::Tidy keeps either".
- **D5. A `$VERSION` in every module, kept in step:** each module
  declares `our $VERSION` once, for its own package, none for the
  packages inside a module (`Sink::One`, `Operators::Chain`).
  `minil prepare` already rewrites every `$VERSION` it finds; run on a
  copy it set all 23 of Ekorn's. Ekorn's `t/34-versions.t` fails if a
  module has none, more than one, or one that differs from the main
  module's, or a package inside a module has one.
- **D6. This message, and the task below.**

### What else touches you

- **A `|` chain dropped its source's original** (F1). Your iterators
  overload `|` and `@{}` with Ekorn's `chain` and `drain`, and your
  Context's POD promises the row to "a pipeline of yours" reading a
  chain made with `|`. A run reading a chain got the chain's own
  values from `result_original`. Fixed in v0.3.16: a chain's set-up is
  its iterator's own `EKORN_SOURCE`, so it passes on what an iterator
  does. A test of yours, a pipeline reading `$sth->iterate | stage
  {...}`, would hold you to it.
- **`@{}`, and a chain into a sink, read with `all`** (F3): over
  100,000 values, `@{}` 43% faster, and a chain into `keep_all` about
  twice as fast. Your iterators get it in v0.3.16.
- **Every regex takes `x`** (F17): 41 patterns in Ekorn's newer tests,
  JSON's, CSV's and a source's original's, had none; the review's
  first search looked for `/.../` and missed `qr(...)` without `x`.
  Ekorn checked with PPI, every `PPI::Token::Regexp` and
  `PPI::Token::QuoteLike::Regexp`, by its modifiers and delimiters.
- **The reference's examples are now tested** (F15), by
  `xt/examples.t`: each one before the index runs on its own after the
  reference's catalogue of tracks, and must print what its comments
  say, as `xt/howto.t` checks the how-to's; the README's are compiled,
  as they use stand-ins. One that can't run is marked
  `<!-- not run -->`, or `=for not-run` in POD. `xt/howto.t`'s helpers
  moved to `xt/lib/Examples.pm`, which both use, so Ekorn's
  `xt/howto.t` differs from yours there. Ekorn's 2026-0025 wash-up had
  run the reference's examples after the how-to's data, which isn't
  what the reference's are written against, and so passed over what
  didn't match; if yours were checked the same way, check them
  against your reference's own.
- **Random pipelines are checked for agreement** (F16), by
  `xt/agreement.t`: 3,000 from a fixed seed, pushed, pulled, read with
  `all` and fed. A flatMap in it must give three different values, or
  a mistake in the order queued values go on isn't seen.
- **What the review got wrong,** so yours needn't: two blank lines
  inside a `return` list that it called slop were Perl::Tidy's; and a
  fix it made tripped Perl::Critic, which reads the statement after a
  `try`'s `catch` block as part of it unless the block ends with `;`.

## From Ekorn-Pipeline, 2026-11-25: `pipe`'s branch rebased

**From:** Ekorn-Pipeline's session, 2026-11-25 (Ekorn-Pipeline
e6a8eed2a3044d43fce68e1a982380b5aa5dc3a6)

The branch `experiment/2026-0053-pipe` was rebased onto Ekorn's
v0.3.16, and is now f2b74e33f11486613742f73b20f482ef4d343b98, in place
of f1fd15cb4d65000cd4b45451d25abdc84dac8962, which the task below
names. `pipe`'s change is the same; the branch now has v0.3.16 under
it. The task's worktree command fetches by the branch's name, so it
gets the new one.

# Planned work

## A quality review, as Ekorn's 2026-0053

**From:** Iain, 2026-11-25, with the message above, whose prompt and
D1 to D6 hold here as settled; none is asked again.

The review itself isn't started. Prep, run on 2026-11-25 at
7bacdd000204d5a1e674b5632dad7a885df05540, Perl 5.36.3:

- **Ekorn v0.3.16** (107855d67d73965e3ad5b0e41b96c0ad519a389e):
  `yath test -L` passes.
- **Ekorn v0.4.0** (b9b78eef7314664370123c00bb0819edd5367b57): only
  what 2026-0048 then fixed failed, `t/03-pipe.t` (two
  subtests) and `xt/examples.t` at `docs/REFERENCE.md` line 1824.
- **D4, blank lines above a sub** in `lib/`, `t/`, `xt/` and
  `scripts/`: 152 subs with a comment have one, as they should; 36
  have two; and 8 with no comment have two, as they should. Found by
  a scan of lines starting `sub `, so a sub inside a block isn't
  counted.
- **D5, `$VERSION`:** only `lib/DBIx/Squirrel.pm` has one; 17 modules
  have none. No test like Ekorn's `t/34-versions.t` yet.
- **D3, "new in":** none in the docs or POD.
- **F17, regexes without `x`,** by PPI as Ekorn checked: none (the
  one it lists, `scripts/manuals` line 73, is a `tr`).
- `lastlog.jsonl` is a stale link, to a log of 2026-11-16, so
  `yath failed lastlog.jsonl` fails; name the run's own log.

The fixes ship in v4.0.0, with 2026-0048's `pipe`, not first in a
v3.6.x as Ekorn's went out in v0.3.16 before its v0.4.0: Iain,
2026-11-25, as `pipe`'s change was already on `develop`. The review's
record carries this as a settled decision.

Done when the review's findings are written up in a roadmap item's
record, fixed and tested, and itemised in `Changes`.
