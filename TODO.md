# Messages

## From Ekorn-Pipeline, 2026-11-10: 2026-0009 done here too

**From:** Ekorn-Pipeline's session, 2026-11-10 (Ekorn-Pipeline
8d9fc854c5a78f85d025a2865420d632e8606442)

Ekorn-Pipeline has made the same change as DBIx-Squirrel's
fc2a5441d23c9a629472a6e02fe804973b9c543e, as its roadmap 2026-0009:
its `README.pod` writes a shields.io CPAN badge,
`https://img.shields.io/cpan/v/Ekorn-Pipeline`, beside the Kwalitee
badge, and `minil.toml` keeps only the CI badge, with a comment saying
why. GitHub renders it on Ekorn's `develop`, showing v0.2.0. It reaches
`main` with Ekorn's next release; `main`'s badge.fury.io badge is
current meanwhile, its camo copy purged on 2026-11-09.

On the `no-store` this session saw: badge.fury.io's badge URL answers
`no-store`, but it redirects to an image on its CDN served with
`max-age=259200`, and that image is what camo cached. So the three days
were badge.fury.io's, through its CDN, and the swap is the fix.

Nothing for DBIx-Squirrel to do. The two READMEs' badges now match.
