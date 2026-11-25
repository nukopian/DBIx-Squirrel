# 2026-0029. Scanning with betterleaks

**Status:** shipped, unreleased

**Decisions:** D1 settled: install betterleaks with Homebrew. D2
settled: keep `.gitleaksignore`'s name. D3 settled: CI runs
betterleaks in place of gitleaks, not beside it.

**Origin:** a message from Ekorn-Pipeline, 2026-11-15 (its commit
17f3ac15803cb91a6bb5fb184c2d30c09921b606), as its 2026-0039

**Started:** 2026-11-25

**Finished:** 2026-11-25

## Background

gitleaks gets no new rules now; betterleaks, its successor, does. We
scanned with gitleaks in CI's `secrets` job, over the whole history,
by hand before a tag (MAINTAINING.md's release step 1), and before a
docs commit (CLAUDE.md). The idea left two questions: whether
betterleaks reads a `.gitleaksignore`, and installing it.

Betterleaks 1.10.1, installed from Homebrew, answered the first. Its
`-i` flag reads `.betterleaksignore` or `.gitleaksignore`, from the
current directory by default. Run on this repository, both tools
found nothing in its 636 commits or its working tree. Run on a copy
of `cover_db/digests` alone, both reported the same finding,
`cover_db/digests:generic-api-key:1`, and our entry silenced it under
betterleaks too. A history scan's fingerprints have the same form,
commit, file, rule and line, so an entry made by one tool works for
the other.

The two tools don't find the same things. In a scratch directory,
with a made-up AWS key built from pieces, gitleaks reported a key
ID wherever it appeared. Betterleaks' `aws-access-token` is a
composite: it reports an ID only with a 40-character secret within 5
lines. An ID on its own was caught by `generic-api-key`, beside a word
such as "key", and on one line it wasn't reported at all. Betterleaks
has 466 rules, and some of its rules can check a finding against the
live service (`--validation`), which we don't turn on. The rule on
secrets in messages, building one from pieces, stays as it is: it
doesn't depend on which tool would catch the whole.

The Linux release is packaged as gitleaks' was:
`betterleaks_1.10.1_linux_x64.tar.gz` holds the `betterleaks` binary.
Its SHA-256 agreed three ways: the release's asset digest, its
`checksums.txt`, and the file as downloaded.

## Decisions

- [x] **D1.** Install betterleaks? Yes, Iain, 2026-11-25:
  `brew install betterleaks`, 1.10.1. gitleaks stays installed, as
  other repositories still use it.
- [x] **D2.** Rename `.gitleaksignore` to `.betterleaksignore`? No,
  Iain, 2026-11-25: betterleaks reads the old name by default, and
  either tool then works on the repository.
- [x] **D3.** Replace gitleaks in CI, or run both for a while?
  Replace, Iain, 2026-11-25: one scanner, as the item said, and both
  found nothing in the whole history.

## The plan

What: scan with betterleaks in place of gitleaks. Why: gitleaks gets
no new rules. Steps: CI's `secrets` job downloads betterleaks 1.10.1,
checked against its SHA-256, and scans the history with the same
flags; MAINTAINING.md's release step, Security checks and tools, and
CLAUDE.md's rules, name betterleaks; `.gitleaksignore` keeps its name
and entry. Done when CI's `secrets` job passes with betterleaks.

## What happened

- **Outcome:** as planned. Locally, `betterleaks git --redact
  --no-banner .` and `betterleaks dir .` find nothing, exit 0, as
  gitleaks found nothing; CI's `secrets` job runs betterleaks on the
  commit that ships this.
- **Changes from the plan:** none. No `Changes` line, as nothing a
  user sees changed.
- **What's left:** nothing here. Ekorn-Pipeline's 2026-0039 is told
  what this found.
- **Ekorn's reply** (Ekorn-Pipeline
  cf19d735da817fde2148a54284ebc7c219d7289e): betterleaks found 9
  placeholders in its history, such as `*REDACTED*` as a DSN's
  password, which gitleaks didn't, and Ekorn allowed them with a
  `.betterleaks.toml`, loaded only with `--config`. Our history has no
  such example, and scans clean; we'd follow its way if one came to
  trip the scan (Iain, 2026-11-25).
