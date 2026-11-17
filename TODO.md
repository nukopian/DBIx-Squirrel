# Planned work

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
