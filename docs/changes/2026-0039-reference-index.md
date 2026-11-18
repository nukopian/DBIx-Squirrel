# 2026-0039. An index of the reference, by module

**Status:** in progress

**Decisions:** D1 settled: it replaces "The modules". D2 settled: every
name our modules export, re-exports from Ekorn included, linked to our
sections. D3 settled: an internal module gets one line, without its
functions. D4 settled: a test in `xt/` keeps it in step with the code.

**Origin:** roadmap, added 2026-11-18, Iain's idea

**Started:** 2026-11-18

## Background

The reference is long, 2,700 lines in sixteen chapters and five
sections after them, and finds a method or function by where it's
used, not by its name. Its closing section, "The modules", gives a
line to each module and names some of what they export, but not in
order, without the methods, and without links. To find what `ended`
does, or where `take_last` is described, a reader searches.

## Decisions

- [x] **D1.** Where does it go? It replaces "The modules", at the end:
  each module, A to Z, with that table's line saying what it is, then
  what callers use from it, A to Z, each described in a line and
  linked to its section. One list, not two to keep in step. Iain,
  2026-11-18.
- [x] **D2.** Does it list the names our facades re-export from Ekorn,
  such as `take`, `batch`, `tee`, `Stop` and `gather`, and Ekorn's own
  modules? Every name our modules export, re-exports included, each
  linked to where our reference describes it; Tooling by its tags.
  Ekorn's own modules, such as Sinks and Sources, keep the one closing
  paragraph pointing to them. Iain, 2026-11-18.
- [x] **D3.** The internal functions, such as Placeholders' and Util's?
  Each internal module gets its entry, saying it's internal, without
  its functions; a public module's internal functions, such as
  Context's `within`, are left out. The index stays a guide to what
  callers use. Iain, 2026-11-18.
- [x] **D4.** Is it kept in step by a test? Yes, `xt/reference-index.t`,
  run in CI, never by installers, as `xt/ekorn-tooling.t` is. Iain,
  2026-11-18.

## The plan

**What:** an "Index" section at the end of `docs/REFERENCE.md`, in
place of "The modules". Each module has a heading of its name, a line
saying what it is, and, unless it's internal, a table of the methods,
functions, variables and tags callers use, A to Z, each with a line
saying what it does and a link to its section.

**Why:** a reader who knows a name should find it, and what it does,
in one place.

**Steps:**

1. The index, from each module's POD and exports, its links to the
   reference's sections; the contents list and any link to "The
   modules" updated.
2. `xt/reference-index.t`: each module under `lib` has an entry; each
   name a public module exports, and each public method it defines,
   is listed, but for those the test names as internal; each name
   listed is one the module exports, can call, or is a tag of; and an
   internal module lists nothing.
3. `scripts/manuals`, and `xt/examples.t` and `xt/manuals.t`.
4. `Changes` under Unreleased; the item leaves the roadmap.

**Done when:** the suite, `xt/` included, passes on 5.36.3 and 5.44.0;
the new test fails when a name is taken out of the index; Perl::Critic
and Perl::Tidy are clean on 5.44.0.
