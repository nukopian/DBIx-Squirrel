# Planned work

## Ekorn::Pipeline from CPAN again, once v0.3.1 is there

**Waiting on:** Ekorn::Pipeline v0.3.1 on CPAN, released, not a trial.

CI installs Ekorn::Pipeline from GitHub's `develop`, in a step named
"Ekorn::Pipeline from GitHub" before each job's dependencies in
`.github/workflows/test.yml`, as this code needs v0.3.0 or later, of
which only trials are on CPAN, and CPAN doesn't index a trial.
`develop` says v0.3.1, within the `cpanfile`'s range,
`>= v0.3.0, < v0.4.0`, so `--installdeps` keeps it. Ekorn's release
will be v0.3.1, not v0.3.0, as v0.3.0-TRIAL's Windows failures came
after it; the range needs no change for it.

Once v0.3.1 is released, remove the four steps and the comment above
the first. The range is already moved, with its line in `Changes`.
Done when CI passes on `develop` with Ekorn from CPAN, and its log
shows Ekorn-Pipeline v0.3.1 installed by the dependencies step.
