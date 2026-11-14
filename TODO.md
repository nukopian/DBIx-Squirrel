# Planned work

## Sweep the docs as Ekorn-Pipeline did for its v0.3.0

**From:** Ekorn-Pipeline's session, 2026-11-14 (Ekorn-Pipeline
da9865d479b8142223e53c306eafde37ea9eb091, on `develop`, roadmap 2026-0025)
**Waiting on:** nothing

Iain asked Ekorn-Pipeline for a sweep of its docs before v0.3.0, and
wants DBIx-Squirrel to do the same, by the same criteria, so neither
is missed. They were, as he gave them:

1. **The reference's coverage matters most.** Every method, function
   and message each module's POD documents is in `docs/REFERENCE.md`,
   and its Contents lists every section. Ekorn checked it with a
   script: each POD `=head2` and each DIAGNOSTICS `=item` against the
   reference, with whitespace collapsed, as messages wrap across
   lines; then each public sub in the code. It found one gap, which
   was in fact covered on a wrapped line, so grep across lines.
2. **Plain English.** Read the reference through, and take out what's
   left from older versions; Ekorn's still called an iterator "the
   closure", and a flush `$end`, in places.
3. **Line wrapping.** Paragraphs had lines broken early, where an edit
   shortened one and the paragraph wasn't filled again, and some ran
   long. Fill them again to the docs' width, 70 columns, leaving a
   long piece of code that wouldn't fit on its own line, and check
   that nothing but whitespace changed. A Contents line and a POD NAME
   line stay one line.
4. **In examples, a pipeline of two or more stages has a stage to a
   line,** indented, with a trailing comma, in all three forms:
   `->new(...)` and `pipeline(...)`, calls of functions that take
   stages, and `|` chains, one `| stage` to a line. Iain chose all
   three. In the README, the user guide, the reference and the
   modules' POD. Two things Ekorn learned:
   - `xt/howto.t` reads an end-of-line comment as what a line prints
     only on the line with `say` or `print`, so when a call that
     prints spans lines, its comment goes on the line after the
     closing `);`, which the test reads as following a block that
     prints. A `|` chain has no closing line, so a chain that prints
     keeps its result in a variable first, and prints that.
   - A list of one-line forms, each with a comment, reads badly once
     its calls span lines: make each a statement with its comment
     above.
   Ekorn did the calls with a script, and checked each file's code was
   the same once whitespace, trailing commas and comments were set
   aside; the chains by hand.
5. **Worked examples for developers,** of how to make each kind of
   part, covering the protocols in detail. Ekorn's reference has a
   section, Making each kind of part: a table of each piece (set-up,
   step, flush, end, context), when it's called, what it's given and
   returns, and whether it may stop the run; then an example of each
   kind, by a word and as a class, each run before its output was
   written. DBIx-Squirrel's would be for its own parts, such as its
   sources and its stages for rows, and can point to Ekorn's for the
   protocols themselves.

Done when the README, the user guide and the reference read as one
account, every example prints what it says, and `xt/manuals.t` passes.
Ekorn's record 2026-0025, under What happened, has how its sweep went.

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
