# 2026-0039. An index of the reference, by module

**Status:** shipped in v3.3.1

**Decisions:** D1 settled: it replaces "The modules". D2 settled: every
name our modules export, re-exports from Ekorn included, linked to our
sections. D3 settled: an internal module gets one line, without its
functions. D4 settled: a test in `xt/` keeps it in step with the code.

**Origin:** roadmap, added 2026-11-18, Iain's idea

**Started:** 2026-11-18

**Finished:** 2026-11-18

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

## What happened

- **Outcome:** done as planned. The index has 20 modules and 77 names,
  each linked to its section; `scripts/manuals` resolves every link,
  and the POD manual has it as `=head1 Index`. The suite, `xt/`
  included, passes on 5.36.3 and 5.44.0, 34 files, 2,363 assertions,
  against Ekorn's working copy at
  ec074f666af950b9f7f1c46e4d8881b125a8d7cc. Perl::Tidy is clean on
  the new test, and Perl::Critic on `lib`, which is all CI runs it on.
- **The test bites:** `xt/reference-index.t` failed, as it should, for
  a name taken out (`ended`), a name the module hasn't (`take_any`),
  two rows out of order, and a module's entry taken out.
- **Changes from the plan:** A to Z ignores case, with a name starting
  with a symbol, such as `@INTERNAL` or the operators, last; the test
  checks the order too. Tooling is listed by its tags, not the names
  they hold. The Sugar's `use` forms and the iterator's operators are
  rows of their own, which the test passes over as not names. The
  records list in `docs/changes/README.md` also had 2026-0038 as open,
  fixed in the commit starting this.
- **Released** in v3.3.1, 2026-11-18.
- **Corrected, 2026-11-18:** the runs above said "against Ekorn's
  working copy", but `perlbrew exec --with` replaces `PERL5LIB`, so
  they used Ekorn::Pipeline v0.3.6 as installed from CPAN. Its `lib`
  and `cpanfile` are the same as the working copy's at that commit,
  so the results stand. MAINTAINING.md's form, `PERL5LIB` set inside
  `sh -c`, is the one that puts the working copy first.
- **What's left:** nothing.
