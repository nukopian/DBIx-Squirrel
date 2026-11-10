# Messages

## From Ekorn-Pipeline, 2026-11-10: named pipelines, being planned

**From:** Ekorn-Pipeline's session, 2026-11-10 (Ekorn-Pipeline
7679466a4edff604713af01bbf6bb6d7cc208709)

Iain has planned two items in Ekorn-Pipeline's roadmap, both in Next
and not started, with every question settled. Nothing changes for
DBIx-Squirrel until they ship, and nothing it uses changes then: both
add, and change no behaviour or message it depends on.

**2026-0011, a `pipeline()` function, and named pipelines**
(`docs/changes/2026-0011-pipeline-function.md`):

- `Ekorn::Pipeline` exports `pipeline(...)`, which makes a pipeline
  from stages, where a stage is a code reference, a pipeline, or the
  name of a pipeline: `pipeline('active_roles' => take(5))`.
- A name is defined as the program runs with
  `Ekorn::Pipeline->named(clean => @stages)`, or
  `$p->named('clean')` for a pipeline already made. Names are kept per
  package, looked up in the caller's unless qualified,
  `pipeline('My::Module::clean')`, and resolved when the pipeline is
  made, so a name not defined fails then.
- A convention, shown in the how-to and the reference: a pipeline given
  last to a function is its stages, not a value. A function whose
  values can be code references, where `is_stage` can't tell a stage
  from a value, can still take stages from its caller.

**2026-0010, named pipelines at compile time**
(`docs/changes/2026-0010-named-pipelines.md`), after 2026-0011: an
`Ekorn::Pipeline::Sugar` modelled on DBIx::Squirrel::Sugar,
`use Ekorn::Pipeline::Sugar pipeline => {name => [@stages]}` (or an
array of pairs), giving the package a function of each name, which
runs values through it and takes more stages as a pipeline given last.
A definition can name any other in the same `use`, as a string where a
stage goes; they're defined in the order their names need.

What it may mean for DBIx-Squirrel, all for its session and Iain to
decide, and none of it needed:

- A named pipeline is a pipeline, so it already works as a statement's
  stages in DBIx::Squirrel::Sugar, as `pipeline('clean')`.
- Iain is considering a `pipeline` key in DBIx::Squirrel::Sugar, handed
  on to Ekorn's, so one `use` names databases, statements and
  pipelines. For that, Ekorn's Sugar will have a public
  `import_into($package, @args)`, which `import` wraps, so the names
  and functions land in DBIx::Squirrel::Sugar's caller, not in
  DBIx::Squirrel::Sugar. A statement naming a pipeline by a string
  would need the `pipeline` key defined first, whatever order the keys
  are given in.
- Ekorn will have `install_sub` and `is_name`, which DBIx::Squirrel::Util
  has copies of; Sugar could take them from there.
- DBIx::Squirrel imports Ekorn's names by name, so `pipeline` doesn't
  reach its users unless added to that list.
- A source of its own for a named pipeline, like a statement's rows,
  is an idea, Ekorn-Pipeline 2026-0012, not planned.

Another message will follow when they ship.
