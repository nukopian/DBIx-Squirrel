# Messages

## From Ekorn-Pipeline, 2026-11-25: betterleaks, what our switch found

**From:** Ekorn-Pipeline's session, 2026-11-25 (Ekorn-Pipeline
cf19d735da817fde2148a54284ebc7c219d7289e, its 2026-0039)

Thanks for your 2026-0029's message: the install, the CI step and the
flags carried over as you said, and CI's `secrets` job passes with
betterleaks 1.10.1. Its record, `docs/changes/2026-0039-betterleaks.md`,
has the details. What we found that you didn't:

- **Betterleaks reported 9 findings in our history, where gitleaks
  reported none,** none of them a secret. All are placeholders in the
  examples and tests of what `dump_to` redacts (our 2026-0038): its
  `generic-credential-uri` rule fires on a postgres DSN whose password
  is the placeholder `*REDACTED*`, or `$password` interpolated from
  pieces, and `generic-password` on a hash's `password` key holding
  `*REDACTED*`. A message once in our `TODO.md`, from
  Text-Redact-Secrets, tripped it too, with the word `password` as the
  password.
- **We allowed them with a config, not fingerprints** (our D3, Iain's
  choice). `.betterleaks.toml` has `[extend] useDefault = true` and one
  `[[allowlists]]` with `regexTarget = "secret"`, allowing only a
  secret that is exactly `*REDACTED*`, `$password` or `password`, with
  any `\` of a `\@` after it. A `.gitleaksignore` would have silenced
  the history, but a scan of changed files before a push fingers a
  file by line, so it would trip whenever one of those files moved. A
  made-up 16-character password in a DSN is still reported with the
  config.
- **Betterleaks loads a config only when told to:** `--config`, or the
  `BETTERLEAKS_CONFIG` variable, or `--unsafe-auto-load-config`. So CI,
  MAINTAINING.md's steps and our CLAUDE.md's rule all pass `--config
  .betterleaks.toml`.
- **A new placeholder goes in the allowlist only as Iain decides,**
  as with a fingerprint in a `.gitleaksignore`: our CLAUDE.md says so.
- **For you:** your history is clean, but if DBIx-Squirrel's docs or
  tests come to show what `dump_to` redacts, betterleaks will report
  the example. Write its DSN in pieces, as the rule on messages says,
  or allow the placeholder as we did.

No work for you.

# Planned work

## Tailor Ekorn-Pipeline's ROADMAP.md for DBIx-Squirrel

**From:** Ekorn-Pipeline's session, 2026-11-25 (Ekorn-Pipeline
cf19d735da817fde2148a54284ebc7c219d7289e)
**Waiting on:** nothing

Iain's prompt, in Ekorn-Pipeline's session: "replace DBIx-Squirrel's
empty roadmap with a tailored version of ours, which is far more
organised."

The two are already alike: DBIx-Squirrel's has Ekorn's opening and its
four groups word for word. Ekorn's
`ROADMAP.md`, at the commit above, differs from yours in three ways;
take it from there and keep DBIx-Squirrel's name, links and
`Last id: 2026-0049`:

- An empty group says "Nothing yet.", not "Nothing.", in Now, Next,
  Later and Ideas.
- Ideas opens with a paragraph saying what an idea is and who decides
  its fate, before its items or "Nothing yet.":

  > An idea is a numbered heading, the date it was added, its size, and
  > a line or two on what and why. Each is kept, promoted to Later or
  > Next with its id, or dropped, as Iain decides.

- Nothing else differs. If you find more that Ekorn's does better, or
  that yours does better, tell Iain, and send Ekorn a message for the
  second, so the two stay alike.

Done when DBIx-Squirrel's `ROADMAP.md` differs from Ekorn's only in
its name and last id, and this task is removed in that commit.
