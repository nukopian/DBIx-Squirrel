# Messages

## From Ekorn-Pipeline, 2026-11-15: scanning with betterleaks, Ekorn's 2026-0039

**From:** Ekorn-Pipeline's session, 2026-11-15 (Ekorn-Pipeline
17f3ac15803cb91a6bb5fb184c2d30c09921b606)

gitleaks gets no new rules now, as its maintainer has stopped adding
them; betterleaks, its successor, does. Ekorn-Pipeline added an idea,
its roadmap 2026-0039, to scan with betterleaks in place of gitleaks,
once it's settled: in CI's job over the whole history, and in the scans
by hand before a push and a tag. Iain has five repositories that would
need the same change, this one among them, so it's sent here for him
to decide whether it becomes an idea, an item or a task.

Two things to settle when it's picked up: whether betterleaks reads a
`.gitleaksignore`, which the rule on secrets in messages relies on, and
installing it, which is asking Iain first.

## From Ekorn-Pipeline, 2026-11-15: no secret whole in a message, and .gitleaksignore

**From:** Ekorn-Pipeline's session, 2026-11-15, passing on a task from
Text-Redact-Secrets' session (Text-Redact-Secrets
6c2ab4e2cb0c9cdf572c73ba785bce946e5062f4), as Iain asked, since it
applies to every repository whose CI scans its history with gitleaks

**What happened.** A message between sessions, in Text-Redact-Secrets'
`TODO.md`, quoted a made-up password from a test whole, beside its
key, and was pushed. gitleaks' scan of the whole history then failed
on every push there, and removing the message didn't help, as history
keeps it.

**The rule Iain made for it,** in Text-Redact-Secrets' CLAUDE.md,
under Planned work: a message between sessions never holds a secret
whole, made-up or not. It's built from pieces, as a test's is, such as
`join '', 'AKIA', 'MADEUP', ...`, or left out.

**If one reaches published history anyway,** rewriting a published
branch means resetting every clone and changing every hash written
since. What Iain chose instead (Text-Redact-Secrets 2026-0001's D14):

- A `.gitleaksignore` at the top of the repository, listing that one
  finding by its fingerprint (commit, file, rule and line), as
  `gitleaks git --redact -f json -r report.json .` gives it, in each
  finding's `Fingerprint`.
- A comment above it giving the reason, as it's a decision of Iain's.
- Nothing else is passed over, so a real secret still fails CI.
  gitleaks reads the file in CI's scan too. Minilla leaves dotfiles out
  of the tarball, so it doesn't ship.

**One more thing to watch:** a full commit hash in a file that also
holds one of gitleaks' keywords, such as a rule's name, can look like a
secret to gitleaks. Running `gitleaks dir .` before a docs commit
catches it before it's pushed; a git-ignored `cover_db/` may show a
finding there, which isn't in history.

Whether DBIx-Squirrel takes on the rule is Iain's to decide.

# Planned work

## main's required checks take the two Windows jobs

**Waiting on:** Iain, as it's a GitHub setting.

CI has run on Windows since 2026-11-14, in two jobs, `perl 5.36
(windows-2025)` and `perl 5.42 (windows-2025)`, which passed on
`develop` and at v3.0.2. `main`'s required checks don't list them yet,
so a push to `main` doesn't wait for Windows, which is where v3.0.0's
and v3.0.1's trials failed. On 2026-11-15 they were the ten other jobs
only.

The command is in docs/MAINTAINING.md's "Changing the CI matrix", with
the list already taking both jobs: Iain pastes it, or says Claude may
run it. Done when its last line, which reads the list back, shows
twelve checks, the two Windows jobs among them:

```sh
gh api repos/nukopian/DBIx-Squirrel/branches/main/protection --jq .required_status_checks.contexts
```
