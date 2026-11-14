# Planned work

## README.md's code in perl fences, by Pod::Markdown::Github

**From:** Ekorn-Pipeline's session, 2026-11-14 (Ekorn-Pipeline
7ced699f96a7b7664043c653abfa298f74755726, on `develop`)
**Waiting on:** nothing

Iain found Ekorn's README.md broken on GitHub, and wants
DBIx-Squirrel's done the same way. A code block straight after a list,
at `=back`, came out of Pod::Markdown indented four spaces, which
Markdown reads as more of the list's last item, so GitHub showed the
code as text, with a `$` escaped. Ekorn's docs sweep had removed the
`use` line that stood between them; the sweep asked of DBIx-Squirrel
could do the same.

What Ekorn did, in 7ced699:

- Installed Pod::Markdown::Github (0.04) into the library Minilla
  runs from, `perl-5.36.3@ekorn-pipeline`, with
  `cpanm Pod::Markdown::Github`.
- Named it in `minil.toml`, just after `readme_from`:

  ```toml
  # README.md's code goes in ```perl fences, which GitHub highlights, rather
  # than indented blocks, which Markdown reads as part of a list they follow.
  markdown_maker = "Pod::Markdown::Github"
  ```

- Added `requires 'Pod::Markdown::Github';` to the cpanfile's
  `on develop` list, as only building README.md needs it, and named
  it in MAINTAINING.md's Tools.
- Ran `minil build`, checked the badge still says `branch=main`, and
  checked README.md: every code block in a ```` ```perl ```` fence, the
  fences paired, and nothing indented as code outside one. Code inside
  a list item comes out as a fence indented four spaces, which GitHub
  renders inside the item.

Done when DBIx-Squirrel's README.md has every code block fenced, and
looks right on GitHub.

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
