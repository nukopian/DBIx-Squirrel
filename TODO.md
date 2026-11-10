# Planned work

## 1. Say where a stage belongs, in the how-to and the reference

**From:** Ekorn-Pipeline's session, 2026-11-10 (Ekorn-Pipeline
497f33a7b2bfbbd6b22a7e23921ab0c0796f0a1a)
**Waiting on:** nothing

**What:** Iain asked where a stage of his own should go, Ekorn's
namespace or DBIx::Squirrel's, and how to decide, and asked that
DBIx-Squirrel's docs cover it too. Ekorn's how-to has a new recipe,
"Decide where a stage belongs" (in `docs/HOWTO.md` at the commit
above). The rule is the one Iain decided on 2026-11-07, in both
repositories' CLAUDE.md: a stage goes where what it needs to know is.

DBIx-Squirrel's reference has it in two lines, under "Where they go"
in its section on writing stages (`docs/REFERENCE.md`, near line
1307). Its how-to has nothing on it. A reader writing a stage for rows
is the one most likely to ask, so the how-to is where it helps most.

**Steps:**

1. Add a recipe to `docs/HOWTO.md`, near "Write a stage that keeps
   count, or acts at the end", saying how to decide, from a
   DBIx::Squirrel reader's side:
   - A stage that needs a database, a statement, a row's column names
     or the row a value came from goes under `DBIx::Squirrel::Stages::`,
     as `pluck` and `as_hash` do.
   - A stage that would work on values from anywhere belongs under
     `Ekorn::Pipeline::Stages::`, where any function's stages can use
     it, even if it was first written for rows: a stage that works on
     hash references from a query works as well on hash references
     from a JSON file. Only what it has to know decides.
   - Ekorn::Pipeline can't depend on DBIx::Squirrel, so a stage that
     would `use` DBIx::Squirrel belongs here.
   - Either way it's built from the same parts: `gather`, `Stop` and
     `croakf`.
   - A stage added under `Ekorn::Pipeline::Stages::` reaches
     DBIx::Squirrel's users only once DBIx::Squirrel adds it to the
     names it imports.
   Ekorn's recipe has the wording these come from; say them in this
   repository's own terms, plainly, and link to Ekorn's recipe for the
   rest.
2. Bring the reference's "Where they go" into line, if the recipe says
   more than it does, or link from it to the recipe.
3. The manuals, and `Changes`.

**Done when:** DBIx-Squirrel's how-to has the recipe, its reference
agrees with it, and the manuals are made again.
