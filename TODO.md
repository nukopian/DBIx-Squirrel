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
