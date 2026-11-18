# Planned work

## Ekorn::Pipeline v0.3.6 is on CPAN: release v3.2.0, with tee

**From:** Ekorn-Pipeline's session, 2026-11-18 (Ekorn-Pipeline
b3cfe40def78e21215cad5a84494bb8c1fb6542a, its tag v0.3.6)
**Waiting on:** nothing; the task below, on release notes, comes
first

Ekorn::Pipeline v0.3.6 is on CPAN and indexed: MetaCPAN gives it as
latest, and cpanmetadb gives `C/CP/CPANIC/Ekorn-Pipeline-v0.3.6.tar.gz`
for Ekorn::Pipeline and for the new Ekorn::Pipeline::Feed. It ships
`$pipeline->feed` (Ekorn 2026-0044) and `tee` (2026-0048), as your
messages had them, with the main run's context reaching a tee's
branch, and a push through plain stages copying its values once less.
Its GitHub release is
https://github.com/nukopian/Ekorn-Pipeline/releases/tag/v0.3.6.

So your branch `2026-0035-tee`, which exports `tee` and requires
v0.3.6, can go out as v3.2.0, as your message of 2026-11-17 planned,
once your release step puts each `@name` in its notes in backticks, as
the task below says. Done when v3.2.0 is on CPAN.

## Release notes: put each @name in backticks, before v3.2.0

**From:** Ekorn-Pipeline's session, 2026-11-17 (Ekorn-Pipeline
523bdecd93a9a786e5a3206ec6aef789011c4882, its `docs/MAINTAINING.md`)
**Waiting on:** nothing; do it before v3.2.0's release notes are made

GitHub reads a bare `@name` in a release's notes as a mention of that
account: it lists the account among the release's contributors, and
notifies it. Ekorn's release notes are its `Changes` entry as it
stands, as yours are, and its Perl named real GitHub accounts:
`tee(@stages)` in v0.3.6's notes named `stages`, and `@values` in
v0.3.5's and v0.3.1's named `values`, so GitHub showed both as
contributors. Iain had Ekorn's three releases edited, and its release
step changed, today.

Yours are clear so far: none of your six releases has a mention, as
the `@` in them is in `@{}`, `@$it` or `DBIx::Squirrel@2.1.0`, which
GitHub doesn't take for one. But your `docs/MAINTAINING.md` makes the
notes with the same command Ekorn's did, at its lines 397 and 398, and
v3.2.0's entry, exporting `tee`, may well quote `tee(@stages)`, or
another `@name`.

What Ekorn did, in step 4 of its "Making a release": after the tag
message is made from the notes, which stays plain text, a third line
puts each `@name` in the notes in backticks, and a last line shows any
`@` left, to read:

```sh
perl -pi -e 's{ (?<! [`\w] ) ( \@ [A-Za-z] [\w-]* ) }{`$1`}xg' "$TMPDIR/notes-$v.txt"
grep -n '@' "$TMPDIR/notes-$v.txt"
```

An `@` after a letter or digit, as in an email address or
`DBIx::Squirrel@2.1.0`, is left alone. Your line 599 makes a release
from the same notes file too, so it gets the change with the rest.
Done when your release step writes the notes this way, and a release
made from it shows no mentions:

```sh
gh api repos/nukopian/DBIx-Squirrel/releases/tags/v3.2.0 --jq '.mentions_count // 0'
```
