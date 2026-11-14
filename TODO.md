# Messages

## From Ekorn-Pipeline, 2026-11-14: a `pipeline` key for your Sugar

**From:** Ekorn-Pipeline's session, 2026-11-14 (Ekorn-Pipeline
d5be2efc91490bfc9c4e94582a4b937fd2327dbd)

Ekorn has Ekorn::Pipeline::Sugar now (its roadmap 2026-0010), shipping
in v0.3.0, and on its `develop`, which your CI installs. Iain asked
for this message to carry enough for DBIx::Squirrel::Sugar to take a
`pipeline` key, so one `use` can name databases, statements and
pipelines. Whether to do it, and how, is for you and Iain; this is
what Ekorn offers, and what to mind.

**What Ekorn's Sugar does:**

```perl
use Ekorn::Pipeline::Sugar pipeline => {
    clean => [sub { $_->[0] }, sub { s( \s+ \z )()xr }],
    top   => ['clean', take(5)],
};
my @names = clean(@rows);                        # a function of each name
my @loud  = top(@rows, pipeline(sub { uc }));    # a pipeline last: more stages
my $next  = pipeline('top')->iterator($source);  # named, so pipeline() finds it
```

- The definitions are a hash, or an array of pairs, each a name and an
  ARRAY of stages. A string where a stage goes names a pipeline: one
  from the same `use`, in either order, or one named before.
- Each pipeline is named, with `Ekorn::Pipeline->named`, in the package
  that uses the module, as `"${package}::$name"`, and that package gets
  a function of the name. Called, it runs its values through the
  pipeline, in the caller's context, as calling the pipeline does;
  given a pipeline last, it runs them through that too. Only a pipeline
  last is taken for stages, as values can be code references; your
  statement functions take any stage last, as bind values can't be, so
  the two differ there, by design.
- Its messages match your Sugar's where they meet: "Expected a name for
  a pipeline (%s)", the rule `m( \A [^\W\d] \w* \z )x`; "Expected the
  pipeline %s in an ARRAY"; "Expected a pipeline defined once (%s)";
  and "Expected no function of the name in %s already (%s)", which
  checks `$package->can($name)`, so inherited functions count. Its own:
  "Expected pipeline, not %s"; "Expected the pipelines after pipeline
  in a HASH or an ARRAY of pairs"; "... in pairs of a name and an
  ARRAY"; and "Expected pipelines that don't name each other in a
  circle (%s)". Ekorn::Pipeline's "No pipeline named %s" and "A
  pipeline named %s is already defined" come through as they are.
  `install_sub` and `is_name` stay private to Ekorn, as Iain decided:
  keep your own.

**The way in, `import_into`:** a public class method, which does what
`use` does, for the package given:

```perl
Ekorn::Pipeline::Sugar->import_into($package, pipeline => $definitions);
```

`$definitions` is the hash or array your `use` was given, passed on as
it is. Names are read, and functions installed, in `$package`, so
`clean` above is your caller's, and `pipeline('clean')` finds it there.

**What to mind:**

- **Where errors are reported.** Ekorn croaks with Carp, its
  `@CARP_NOT` trusting only Ekorn's own packages. Called from your
  `import`, a mistake would be reported at a line in your Sugar.pm.
  Call it inside `at_caller { ... }`, as your `_resolved` calls
  `pipeline_in`, so it's reported at your user's `use`.
- **Define pipelines before statements.** A statement naming a pipeline
  resolves it as it's defined, through `pipeline_in`, so a `pipeline`
  key in the same `use` has to be defined first, wherever it's given.
  Your `import` takes keys in the order given, so either handle
  `pipeline` first, or say it must come first.
- **No `pipeline` function.** Your keys each install a function of
  their own name, so `use DBIx::Squirrel::Sugar qw(database
  statement)` defines as the program runs. Ekorn's Sugar installs
  none: `pipeline` is the word in Ekorn::Pipeline::Factories, and
  `Ekorn::Pipeline->named` defines as the program runs. A `pipeline`
  key would want the same, or it shadows the word.
- **Names share a package.** A pipeline's function and a statement's or
  database's live in the same package, so one name can't be both;
  whichever comes second croaks, with the same message from either.
- **The docs.** Ekorn's reference has "Named at compile time:
  Ekorn::Pipeline::Sugar", and its how-to "Name pipelines as the program
  compiles", in chapter 7. A statement naming a pipeline from the same
  `use` is the example yours would want.

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
