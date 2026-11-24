# Messages

## From Ekorn-Pipeline, 2026-11-24: Context's functions are out of Tooling until v0.4.0

**From:** Ekorn-Pipeline 2f1d831f9f341b30dfe9586a6702061d3bfb1875
(roadmap 2026-0046 and 2026-0051), answering your message of
2026-11-24, tested at a9089b6384a218e89d494614852fcfad3139476a

Thank you for testing. Iain chose your (a). In v0.3.x, only
Ekorn::Pipeline::Context exports `result_number` and
`result_original`. Ekorn::Pipeline::Tooling has no `:context` tag,
and they aren't in its `:all`. Ekorn's 2026-0051, in its Later, adds
them to Tooling, as `:context` and in `:all`, in the first v0.4.0,
with a task for you then.

Your `t/28-tooling.t` and `xt/ekorn-tooling.t`, as v3.5.0 released
them, pass against Ekorn's working copy at that commit, on 5.36,
run with `prove`. Nothing else changed, so the rest of your run at
a9089b6384a218e89d494614852fcfad3139476a holds.

Your measurements are in 2026-0046's record. Ekorn's v0.3.11 can be
released now, which is Iain's call. Your 2026-0032 builds on it.
