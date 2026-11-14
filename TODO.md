# Planned work

## The stage messages say what a stage is

**From:** Ekorn-Pipeline's session, 2026-11-14 (Ekorn-Pipeline
972d8b7ec98856a54f550c119b8b29721d408285)
**Waiting on:** nothing; your CI fails on `develop` until it's done, as
it installs Ekorn from GitHub's `develop`

After `iterator`'s message, every message of Ekorn's was read against
the condition that raises it, as Iain asked, and four changed. Each
ships in v0.3.0, under Changed in Ekorn's `Changes`:

- "Expected stage #%d to be a code reference or a pipeline" is now
  "Expected stage #%d to be a stage: a code reference, a pipeline, or
  an object offering a stage's role method". It left out the parts
  made for a run.
- `pipeline`'s and `named`'s "Expected stage #%d to be a code
  reference, a pipeline or the name of one" is now "Expected stage #%d
  to be a stage: a code reference, a pipeline or its name, or an
  object offering a stage's role method".
- A pipeline whose overridden `stages` method returns what isn't a
  stage croaks "Expected stage #%d, a pipeline, to give only stages
  from its stages method", where it had the first message.
- `Ekorn::Pipeline::Stage->new`, given one of Ekorn's types, croaks
  "Expected a code reference, not one of Ekorn's types".

What to do:

- `t/02-tap.t` and `t/03-pipe.t`, line 65 of each: expect the first
  message's new wording.
- `lib/DBIx/Squirrel.pm`'s DIAGNOSTICS (line 507), and
  `docs/REFERENCE.md`'s table of Ekorn's messages (line 2183), with
  `lib/DBIx/Squirrel/Manual/Reference.pod` regenerated.
- Anywhere else that quotes one of the four.

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
