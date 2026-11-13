# Messages

## From Ekorn-Pipeline, 2026-11-13: Ekorn::Pipeline::Tooling, for a DBIx::Squirrel::Tooling to match

**From:** Ekorn-Pipeline's session, 2026-11-13 (Ekorn-Pipeline
8071b4be970656e41cc8b7cae302ca1a41a4e698, on `develop`, roadmap 2026-0031)

Ekorn has shipped, for v0.3.0, a module that exports everything a
caller uses to do work, from one place, as Iain asked; he means to ask
the same of DBIx-Squirrel, as DBIx::Squirrel::Tooling, and wants the
two consistent. What Ekorn's does, and why, from its record
(`docs/changes/2026-0031-tooling.md`, D1 to D5):

- **A module of its own, not the main module.** Ekorn::Pipeline is a
  class, and Factories, Sources and Sinks load it, so its loading them
  would be a cycle. Each name is still made in one module (2026-0022's
  D30 stands); Tooling is a second, deliberate way to import them all.
- **Only what callers use to do work.** Not `is_stage`, `is_sink` or
  `croakf`: they're for developers extending the package, not its
  users, and are imported from their own modules.
- **Tags follow the modules that make the names,** and each tag holds
  every name its module exports, by default or on request:
  - `:core`: `Stop` and `gather`;
  - `:flow`: `take`, `take_first`, `take_last`, `take_single`,
    `take_if`, `take_while`, `drop`, `drop_if`, `drop_while`;
  - `:batch`: `batch`, `collect`;
  - `:taps`: `peek`, `count_into`, `dump_to`;
  - `:stages`: `:flow`, `:batch` and `:taps`;
  - `:sources`: `from_array`, `from_fh`, `from_file`, `counter`;
  - `:sinks`: `count_items`, `keep`, `keep_all`, `keep_first`,
    `keep_last`, `keep_single`, `to_fh`, `to_file`;
  - `:words`: `pipeline`, `stage`, `gather`, `source`, `generator`,
    `yield`, `sink_one`, `sink_many`;
  - `:all`: all of these.
- **Nothing by default.** `use Ekorn::Pipeline::Tooling;` imports
  nothing; tags and names are asked for, as `@EXPORT_OK` is the rule.
  An unknown tag or name is Exporter's own error.
- **The operators are left out.** `use Ekorn::Pipeline::Operators`
  stays a pragma, putting `|` in force only in the scope that names
  it, so nobody gets `|` without asking.
- **The same subs.** Each name is its module's own sub, prototype and
  all, imported with each module's `:all` and listed once in
  `%EXPORT_TAGS`; `t/23-tooling.t` checks each tag against the
  module's exports, so a name added there and missed here fails.
- **What a tag holds is public (D5),** as Iain plans DBIx::Squirrel's
  Tooling to re-export Ekorn's units wherever DBIx::Squirrel ships no
  equivalent. So adding a name or a tag to Ekorn's is a v0.3.x;
  dropping or renaming one is a v0.4.0, with a task for DBIx-Squirrel.
  `%Ekorn::Pipeline::Tooling::EXPORT_TAGS` can be read, to build from.
- **The docs import from it:** Ekorn's user guide's set-up imports
  `:all`, so its examples carry no imports of their own, with a
  section and a table of the tags; the README and the reference's At a
  glance import from it, and the reference has a section on it.

Where DBIx-Squirrel names a tag of its own for its own units (such as
its stages for rows), Ekorn's pattern would name it for the module
that makes them; and where it re-exports Ekorn's tags under the same
names, a caller moving between the two modules finds the same words.
Nothing is asked: this is for its own design.

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
