# Messages

## From Ekorn-Pipeline, 2026-11-14: `finally` needs a `catch`

**From:** Ekorn-Pipeline's session, 2026-11-14 (Ekorn-Pipeline
d1a02db5506723f41a6985e82e0d1aefa8ef9fad)

Your CLAUDE.md's Perl section says `use experimental qw(try);` "also
allows `finally`". It does, but only after a `catch`: `try {...}
finally {...}` is a syntax error on every Perl CI covers, 5.36 to 5.44,
checked on each on 2026-11-14, and `try {...} catch ($e) {...} finally
{...}` compiles. Code that only cleans up catches, throws again, and
cleans up after. Under `use v5.40`, `try`/`catch` needs no line, but
`finally` still warns that it's experimental, so the rest of the
sentence holds. Ekorn's CLAUDE.md was corrected in the commit above
(its 2026-0025, D8), as Iain decided; yours may want the same.

# Planned work

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

## Expose Ekorn::Pipeline::JSON: from_json and to_json

**From:** Ekorn-Pipeline's session, 2026-11-14 (Ekorn-Pipeline
aadbc05c3e1f8ffd588351de157d5ed0a2344f5e)
**Waiting on:** nothing: it's on Ekorn's `develop`, which CI installs

Ekorn-Pipeline has a new module, Ekorn::Pipeline::JSON (its roadmap
2026-0034), shipping in v0.3.0, and Iain wants DBIx::Squirrel to expose
it too. It exports, on request, `from_json` and `to_json`: each a
source or a sink given `file` or `fh`, and a stage given neither, with
options `type` (`json`, `jsonl`, `ndjson`) and `json` (options for
JSON::MaybeXS, or an encoder object). Reading works out whether it has
JSON Lines or one array; writing picks by the file's name. Ekorn's
Tooling exports both by a new `:json` tag, in its `:all`. It adds a
runtime dependency to Ekorn: JSON::MaybeXS.

What to do:

- `lib/DBIx/Squirrel/Tooling.pm`: a `:json` tag, `from_json` and
  `to_json`, imported from Ekorn::Pipeline::Tooling's `:json` (or
  Ekorn::Pipeline::JSON), and `json` in the list `:all` is made from;
  its POD's tags, and `t/28-tooling.t`'s list of tags and modules.
- The reference's Importing section (`lib/DBIx/Squirrel/Manual/Reference.pod`
  is made from `docs/`, as here), with a line for `:json`, and anywhere
  else it lists Ekorn's tags or the names it documents.
- Ekorn's CLAUDE.md lists the names DBIx::Squirrel imports by name;
  tell Ekorn's session, by a message, once `from_json` and `to_json`
  are among them, so its list can follow.
- Note that JSON.pm exports a `from_json` and a `to_json` of its own by
  default, so `:all` beside `use JSON` overrides one or the other; Ekorn's
  docs say so, and DBIx::Squirrel's might too.

Ekorn's reference has a section, "JSON: Ekorn::Pipeline::JSON", and its
how-to reads and writes JSON in chapters 5 and 6, and walks through how
the module is built in chapter 10. Done when DBIx::Squirrel::Tooling
exports both by `:json` and `:all`, the tests pass with Ekorn's
`develop`, and the reference says so.
