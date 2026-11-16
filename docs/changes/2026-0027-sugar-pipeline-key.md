# 2026-0027. A pipeline key for the Sugar

**Status:** shipped, unreleased

**Decisions:** D1 settled: pipelines are defined first, wherever
they're given. D2 settled: `pipeline` takes what Ekorn's takes. D3
settled: the message names `pipeline`. D4 settled: it ships in
v3.1.0.

**Origin:** a message from Ekorn-Pipeline's session, 2026-11-14
(Ekorn-Pipeline d5be2efc91490bfc9c4e94582a4b937fd2327dbd), whose
details are in TODO.md at fb67c9ab896aff6d67e8a4a6d8d97b1389ae11b7

**Started:** 2026-11-16, in 7db6ca5

**Finished:** 2026-11-16

## Background

Ekorn-Pipeline's 2026-0010 named pipelines: `use
Ekorn::Pipeline::Sugar pipeline => {...}` defines each, and gives the
package a function of each name. Its `import_into` does the same for
another package, for a module whose own sugar defines pipelines for
its caller. It's been in each Ekorn release since, and so in each one
DBIx-Squirrel's `cpanfile` allows, `>= v0.3.3, < v0.4.0`.

A statement defined through `use DBIx::Squirrel::Sugar` can already
name a pipeline as a stage, but the pipeline must be defined with a
`use Ekorn::Pipeline::Sugar` of its own. Statements look a pipeline's
name up as they're defined, in `_resolved`, so it must be defined by
then.

## Decisions

- [x] **D1.** Should `import` define every `pipeline` group before any
  statement, wherever it comes in the list, or require it first?
  Defined first, on 2026-11-16: it can't then be given in the wrong
  order, and Ekorn reports pipelines that name each other in a circle.
- [x] **D2.** Should `pipeline` take both forms Ekorn's takes, a HASH
  or an ARRAY of pairs, or only the HASH that `database` and
  `statement` take? Both, on 2026-11-16: what's after `pipeline` goes
  to Ekorn as it is, so its rules and its errors are the ones users
  meet.
- [x] **D3.** Should `Expected database or statement, not %s` name
  `pipeline` too? Yes, on 2026-11-16, as `Expected database, pipeline
  or statement, not %s`, in its DIAGNOSTICS entry,
  `docs/REFERENCE.md`'s table and `t/16-sugar.t`.
- [x] **D4.** It adds a feature, and changes a message, so is the
  next release v3.1.0? Yes, on 2026-11-16, Iain accepting the minor
  version, with the perf changes under Unreleased going out with it.

## The plan

**What:** `use DBIx::Squirrel::Sugar` takes a `pipeline` key, and
passes what follows it to `Ekorn::Pipeline::Sugar->import_into` for the
package using it, before it defines any statement. It installs no
`pipeline` function: that's Ekorn's word, in Tooling's `:all`.

**Why:** one `use` names a program's databases, statements and
pipelines, and a statement can name a pipeline defined beside it.

**Steps:**

1. `import` takes each `pipeline` and what follows it out of the list,
   and passes them to `import_into` first, in the order given, with
   `at_caller`, so Ekorn's errors are reported at the `use`.
2. The message names `pipeline` (D3).
3. Tests in `t/16-sugar.t`: a pipeline defined by the key, as a HASH
   and as an ARRAY of pairs; a statement naming one given after it in
   the list; no `pipeline` function installed; Ekorn's errors at the
   `use`; the new message.
4. Docs: the Sugar's POD (SYNOPSIS, IMPORTING, DIAGNOSTICS),
   `docs/REFERENCE.md` chapter 12 and its table, and `docs/HOWTO.md`
   chapter 12, with an example `xt/examples.t` runs; the manuals made
   again.
5. `Changes`, under Unreleased.

**Done when:** the tests above pass, on every Perl CI covers, with
coverage above its floors, and `xt/examples.t` runs the new example.

## What happened

- **Outcome:** done as planned. `use DBIx::Squirrel::Sugar` takes
  `pipeline`, passes each with what follows it to `import_into` before
  any statement is defined, and installs no `pipeline` function. The
  tests in `t/16-sugar.t` pass on Perl 5.36.3, 5.38.5, 5.40.5, 5.42.3
  and 5.44.0 against Ekorn's working copy at 38a57ed, and on 5.36.3
  against Ekorn v0.3.3 from CPAN; coverage stays above its floors, and
  `xt/examples.t` runs the how-to's new example.
- **Changes from the plan:** none to the code. The docs that named a
  pipeline in a `BEGIN` block for a statement defined with `use`, the
  reference's example and the Sugar's POD, use the key now, and say
  `BEGIN` is still the way for a pipeline named with `named`. The
  README's sixth step says the Sugar names pipelines too.
- **What's left:** nothing. It ships in v3.1.0 (D4).
