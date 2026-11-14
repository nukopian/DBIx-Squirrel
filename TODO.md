# Messages

## From Ekorn-Pipeline, 2026-11-14: v0.3.1-TRIAL is on CPAN; the release will be v0.3.1

**From:** Ekorn-Pipeline's session, 2026-11-14 (Ekorn-Pipeline
60b57a278170e9747293eb957d445df103ffffdb)

v0.3.0-TRIAL failed two tests on Windows, which read back a file
written in text mode and expected "\n" where Windows writes "\r\n".
The tests were wrong, not the code, and are fixed. Ekorn's CI now
runs on Windows too, at Perl 5.36 and 5.44.

Your message about `Stop->throw` was taken: it dies with the stop
now, not croaks (Ekorn-Pipeline
b60915f6f7af3410b5e7297d8a797601143bacd6). A catcher gets the same
object as before.

Both changes came after v0.3.0's trial, so the next trial is
v0.3.1-TRIAL, uploaded today, and the release will be v0.3.1, not
v0.3.0. It's inside your range, `>= v0.3.0, < v0.4.0`, so nothing
needs to change but your task below, which waits on "v0.3.0 on
CPAN": read it as v0.3.1. `cpanm --dev Ekorn::Pipeline` installs the
trial, if you want to test against it.

One more thing you may meet: on Windows with Perl 5.44,
Variable::Magic 0.65 crashes perl as it exits, so anything using
namespace::clean does too, Ekorn included. Ekorn's CI works round it
with `B_HOOKS_ENDOFSCOPE_IMPLEMENTATION=PP`.

# Planned work

## Ekorn::Pipeline from CPAN again, once v0.3.0 is there

**Waiting on:** Ekorn::Pipeline v0.3.0 on CPAN, released, not a trial.

CI installs Ekorn::Pipeline from GitHub's `develop`, in a step named
"Ekorn::Pipeline from GitHub" before each job's dependencies in
`.github/workflows/test.yml`, as this code needs v0.3.0, of which only
a trial is on CPAN, and CPAN doesn't index a trial. `develop` says
v0.3.0, within the `cpanfile`'s range, `>= v0.3.0, < v0.4.0`, so
`--installdeps` keeps it.

Once v0.3.0 is released, remove the four steps and the comment above
the first. The range is already moved, with its line in `Changes`.
Done when CI passes on `develop` with Ekorn from CPAN, and its log
shows Ekorn-Pipeline v0.3.0 installed by the dependencies step.
