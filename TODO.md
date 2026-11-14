# Planned work

## iterator's new message for what isn't a source

**From:** Ekorn-Pipeline's session, 2026-11-14 (Ekorn-Pipeline
9551602423cba7f1c1772cd0ccdbb6bb102d2f0b)
**Waiting on:** nothing; your CI fails on `develop` until it's done, as
it installs Ekorn from GitHub's `develop`

Ekorn's `iterator`, given something other than a source, now croaks
"Expected a source: a code reference, or an object offering
EKORN_SOURCE", where it said "Expected a code reference", which was
accurate only until sources could be objects. Iain asked for it, from
Ekorn's pre-release washup, and it ships in v0.3.0, under Changed in
Ekorn's `Changes`. The other "Expected a code reference" messages, for
blocks and set-ups, stay as they are.

What to do:

- `t/05-pipeline.t`, the subtest "iterator checks its source": expect
  the new message.
- `docs/REFERENCE.md`'s table of Ekorn's messages (around line 2182):
  `Expected a code reference` no longer covers "the source given to a
  pipeline's `iterator`"; give that its own row, with the new message,
  and regenerate `lib/DBIx/Squirrel/Manual/Reference.pod`.
- Anywhere else that says what `iterator` croaks with.

Done when the tests pass against Ekorn's `develop` at the commit above,
and CI is green.

## Ekorn::Pipeline from CPAN again, once v0.3.0 is there

**Waiting on:** Ekorn::Pipeline v0.3.0 on CPAN.

CI installs Ekorn::Pipeline from GitHub's `develop`, in a step named
"Ekorn::Pipeline from GitHub" before each job's dependencies in
`.github/workflows/test.yml`, as this code needs v0.3.0, which isn't
released. Ekorn's `develop` still says v0.2.0, inside the `cpanfile`'s
range, so `--installdeps` keeps it.

Once v0.3.0 is on CPAN, in one commit: remove the four steps and the
comment above the first; change the `cpanfile` to
`requires 'Ekorn::Pipeline', '>= v0.3.0, < v0.4.0';`; regenerate
`META.json` and `Build.PL` with `minil build`; and add the new range to
`Changes`. Done when CI passes on `develop` with Ekorn from CPAN, and
its log shows Ekorn-Pipeline v0.3.0 installed by the dependencies step.
