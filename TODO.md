# Planned work

## 1. Take a pipeline where a stage goes, with Ekorn::Pipeline's is_stage

**From:** Ekorn-Pipeline's session, 2026-11-09 (Ekorn-Pipeline
3f3e94d809bf7a277f749dfa1e7fae4abb76038a)
**Waiting on:** Ekorn-Pipeline v0.1.3, on CPAN

**What:** Ekorn-Pipeline's roadmap 2026-0004 lets
`Ekorn::Pipeline->new` take a pipeline where a stage goes, composing
its stages in place, as if its `stages` had been given there; a stage
inside is named in messages by its place in each pipeline, "#2.3".
It's in v0.1.3, an addition within `cpanfile`'s range,
`>= v0.1.1, < v0.2.0`, so DBIx::Squirrel's users get it without a
release here, but only where DBIx::Squirrel passes its stages straight
to `new`: `DBIx::Squirrel::Pipeline->new($hits, take(1))` works at
once. `$dbh->iterate($sql, $hits)` doesn't, as DBIx::Squirrel looks
for stages at the end of a call's arguments with Ref::Util's
`is_coderef`, and a pipeline, a blessed hash that overloads `&{}`,
fails it, so it's taken for a bind value.

v0.1.3 exports `is_stage` on request (`use Ekorn::Pipeline
qw(is_stage)`), true for a code reference or an `Ekorn::Pipeline`, of
a subclass too: the test `new` makes, so DBIx::Squirrel and
Ekorn::Pipeline agree on what a stage is.

**Steps:**

1. Raise `cpanfile`'s range for Ekorn::Pipeline to `>= v0.1.3,
   < v0.2.0`, as `is_stage` is new in v0.1.3, and regenerate
   `META.json` and `Build.PL` with `minil build`.
2. Use `is_stage` in place of `is_coderef` where a call's stages are
   looked for: `split_stages` in `lib/DBIx/Squirrel/Util.pm`,
   `_ends_in_stages` in `lib/DBIx/Squirrel/Sugar.pm`, and Sugar's check
   of a statement's definition (`grep { !is_coderef($_) } @rest`, near
   line 103). Leave `is_coderef` where it means a code reference, as in
   `Errors.pm`.
3. Test `iterate`, `results` and Sugar's statements with a pipeline
   among the stages, alone and with others after it, and that its
   stages run in the call's run (a `take(2)` inside gives 2 in all).
4. Rewrite "Give `$hits->stages`, not `$hits`" in `docs/REFERENCE.md`
   (near line 910) and `docs/HOWTO.md` (near line 769), and their
   examples, to give `$hits`, keeping `->stages` for a function that
   takes only code references; then the manuals, and `Changes`.

**Done when:** `$dbh->iterate($sql, $pipeline, take(2))` runs the
pipeline's stages and then `take(2)`, in one run, tested; the docs
show it; and `cpanfile` asks for v0.1.3.
