# 2026-0024. pipeline-experimental back to develop

**Status:** shipped, unreleased

**Decisions:** D1 settled: merge without `docs/design/`, kept by an
archive tag. D2 settled: no TRIAL of Ekorn; test against its
`develop`, CI installing it from GitHub. D3 settled: a fast-forward,
history kept.

**Origin:** two messages from Ekorn-Pipeline's session, 2026-11-13
(Ekorn-Pipeline 3b6804ef19eeda7702723a260f70ba68192b9d34, its 2026-0025)

**Started:** 2026-11-13, in badcdb90464b149866dd5c2718d6c7e1bd8b0785

**Finished:** 2026-11-13

## Background

`pipeline-experimental` carried the work on Ekorn::Pipeline as it is,
from the design in record [2026-0013](2026-0013-one-design.md) to
roadmap items 2026-0014 to 2026-0018, 2026-0020 to 2026-0023, and
fixes. It paired with Ekorn-Pipeline's branch of the same name, which
merged into Ekorn's `develop` on 2026-11-13, without its
`docs/design/`, and was deleted. Ekorn::Pipeline v0.3.0, which this
work needs, isn't yet on CPAN.

Checked on the branch at 9286a162856c5e74ca5b6a01ef0ad4a138ca9a08,
against Ekorn's `develop` at 6a36bd7: the tests pass on Perl 5.36,
5.38, 5.40, 5.42 and 5.44, 30 files and 1,981 assertions each;
coverage is above every floor; perlcritic and the tidy check, on 5.44,
are clean; gitleaks finds nothing in 398 commits. CI has never run on
the branch, as it runs on `main` and `develop` only.

## Decisions

- [x] **D1.** Does `docs/design/` come too? No: the branch merges
  without it, as Ekorn's did, Iain decided on 2026-11-13, in Ekorn's
  first message. The design is approved and split into roadmap items,
  so it's history, not a working document. A signed tag,
  `archive/pipeline-experimental`, on the last commit that has it,
  keeps it reachable, and what linked to it points there.
- [x] **D2.** Wait for Ekorn v0.3.0 on CPAN, perhaps as a TRIAL? No:
  Iain decided against a TRIAL on 2026-11-13, in Ekorn's second
  message. DBIx-Squirrel tests against Ekorn's `develop` and merges
  once satisfied; the `cpanfile`'s range moves to `>= v0.3.0, < v0.4.0`
  only once v0.3.0 is on CPAN. Until then, CI installs Ekorn from
  GitHub's `develop` (829a5fe84b23ea1afac64a6e5834646fd9e96ac6), as
  Iain chose the same day, and a task in `TODO.md` undoes it.
- [x] **D3.** A merge commit, or a rebase? Neither: `develop` has
  nothing the branch lacks, so it fast-forwards, and no hash cited in a
  record or message changes. A signed tag,
  `rollback/develop-2026-11-13`, on `develop` as it was, is there to go
  back to.

## The plan

What: `develop` fast-forwards to `pipeline-experimental`, without
`docs/design/`.

Why: the work is done and checked, and Ekorn's side has merged.
Work goes on from `develop`, as before the experiment.

Steps:

1. This record, on the branch.
2. Two signed tags, pushed: `rollback/develop-2026-11-13` on `develop`
   (c2f593b46451757a9acb6d378438fd183a85127f), and
   `archive/pipeline-experimental` on the commit adding this record.
3. One commit deletes `docs/design/`, points what linked to it at the
   archive tag, says in `docs/MAINTAINING.md` and `ROADMAP.md` that
   the branch is done, and finishes this record.
4. The tests and gitleaks again, then `develop` fast-forwards and is
   pushed, and CI runs on it.
5. The branch is deleted once Iain says so.

Done when: `develop` is the branch's last commit, CI passes on it, and
the archive tag holds `docs/design/`.

## What happened

- **Outcome:** done, as Done when says. `develop` fast-forwarded from
  c2f593b46451757a9acb6d378438fd183a85127f to the branch's last
  commit, fb40bae750020efcb8fe38c1b0bf7189da867114, with no merge
  commit. CI's first run on the work, 43515052956, passed all ten
  jobs, the DBI 1.643 and macOS ones among them, and its log shows
  Ekorn installed from GitHub's `develop`. The archive tag holds
  `docs/design/DESIGN.md`.
- **Step 4:** before the fast-forward, at fb40bae, the tests passed
  against Ekorn's `develop` at 6a36bd7, 30 files and 1,981
  assertions, and gitleaks found nothing in 401 commits.
- **Step 5:** the branch deleted, here and on GitHub, as Iain said,
  on 2026-11-13.
- **Steps 1 and 2:** this record in
  badcdb90464b149866dd5c2718d6c7e1bd8b0785; the two tags signed and
  pushed, `rollback/develop-2026-11-13` on
  c2f593b46451757a9acb6d378438fd183a85127f, and
  `archive/pipeline-experimental` on
  badcdb90464b149866dd5c2718d6c7e1bd8b0785, which holds
  `docs/design/DESIGN.md`. `DESIGN.pdf` was never committed, as
  `.gitignore` ignores PDFs.
- **Step 3:** `docs/design/` deleted; record 2026-0013's link to it
  points at the archive tag on GitHub; `docs/MAINTAINING.md`'s
  Branches says there's no experimental branch now; `ROADMAP.md` no
  longer speaks of the branch as current.
- **Before the plan:** the README brought up to date for version 3,
  three test files tidied, the condition floor raised to 88%, and the
  linters' commands moved to Perl 5.44, as CI's style job runs them,
  the last at Ekorn's suggestion.
