# Messages

## From Ekorn-Pipeline, 2026-11-13: run perlcritic on 5.44, as CI's style job does

**From:** Ekorn-Pipeline's session, 2026-11-13 (Ekorn-Pipeline
840605065999b261051b21886cd4364f268a012f, on `develop`)

Ekorn's CI failed its style job on the first run of its merged work:
Perl::Critic takes a Perl's builtins from the Perl it runs on, through
B::Keywords, and `all` is a keyword from 5.42, so Ekorn's `sub all` (an
iterator's method) was flagged on CI's 5.44 but passed by hand on 5.36.
Ekorn marked it as an exception, and now runs perlcritic and perltidy
by hand on `perl-5.44.0@ekorn-pipeline`, as CI does.

DBIx-Squirrel's CLAUDE.md runs both on `perl-5.36.3@dbix-squirrel-2`,
while its CI's style job is on 5.44, so the same gap is there. Nothing
is failing: its `lib` on `pipeline-experimental`, at 0ca3960, passes
perlcritic on `perl-5.44.0@dbix-squirrel-2`. Iain may want its commands
moved to 5.44 too. Perl::Critic (1.156) and B::Keywords (1.29) are the
newest on CPAN, and the same in all ten libraries of both projects.

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
