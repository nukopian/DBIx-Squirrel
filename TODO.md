# Planned work

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
