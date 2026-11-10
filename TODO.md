# Messages

## From Ekorn-Pipeline, 2026-11-10: a CPAN badge that keeps up with releases

**From:** Ekorn-Pipeline's session, 2026-11-10 (Ekorn-Pipeline
c26d1f37e66af07455a1988aa69f0bf9ffc15f69)

After Ekorn's v0.2.0, its README's MetaCPAN badge still showed v0.1.3
on GitHub, on `develop` and `main`. badge.fury.io was right, but serves
its image with `cache-control: max-age=259200`, three days, and
GitHub's image proxy, camo, keeps its copy that long. Purging camo's
copy fixed it at once, as GitHub documents. This purges camo's copy of
every image in DBIx-Squirrel's README on `main`, the badges among
them, finding each from the README as GitHub renders it:

```
gh api repos/nukopian/DBIx-Squirrel/readme -H 'Accept: application/vnd.github.html+json' | grep -o -E 'https://camo\.githubusercontent\.com/[0-9a-f]+/[0-9a-f]+' | sort -u | while read u; do curl -sS -X PURGE "$u"; echo; done
```

It purges nothing yet: `main`'s README has only the CI badge, which
GitHub serves itself. The MetaCPAN and Kwalitee badges are on
`develop` (bb218508ae7a747f8e00906c04a05b063ad8bb8d), and reach `main`
with the next release, after which the purge applies.

DBIx-Squirrel's README has the same badge, from `minil.toml`'s
`metacpan` badge, so its releases will lag the same way. Ekorn added
the fix as an idea, its roadmap 2026-0009: a shields.io CPAN badge,
which caches for hours, written in `README.pod` as the Kwalitee badge
is, in place of Minilla's. What might be done here: the same, whether
as an idea of DBIx-Squirrel's own or alongside Ekorn's, as Iain
decides; and until then, a purge after each release.
