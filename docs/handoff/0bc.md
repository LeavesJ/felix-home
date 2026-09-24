## 0bc. Verified at session close, 2026-09-13 (night) — Felix merges its own pull requests, and the engine stopped saying otherwise

| | |
|---|---|
| merged by this session | #236 #237 #238 #239 #240 #241 — the last through `felix merge`, from a worktree |
| deployed | **0.49.113**, carried in #241 and installed from the home with no bump and nothing left uncommitted |
| gate on main (`4e5bb98`) | **pass** in the home and in a worktree — 2134 passed, 0 failed; `installed ok`; 38 controls met |
| commission | **stale**: #241 changed `routes.tsv`, which the grant covers. Re-running it is the founder's |

**The direction, and why a session missed it.** The founder said on
2026-09-12T23:39Z, in his own words in `says.log`: "since when do I have to
manually merge edits? Are all of these merges problematic or not safe for you to
auto merge?" The next session merged #222–#235 itself. This session still closed
§0bb with four merges listed as his, and he had to say it again. It believed the
engine's own printed sentences over his direction: `felix classify` said "a human
merges" for yellow and "Approval required before merge" for red, `route.sh`
injected "A person decides here" into every session touching a red path, the
receipt set `founder_required` on a red tier, bootstrap made `gh pr merge` ask a
person, and §0bb repeated it. None of it was enforced — `felix merge` never reads
the tier, and `risk.tsv` says tier is advice and the channel is the stop. The
direction had never been written anywhere a session starts. It is now a standing
feedback memory, `felix-merges-its-own-prs`.

**What stays with him**, stated once so it is not re-derived: `felix commission`
and consent grants (`felix autonomy`), accepting a red gate (`FELIX_ALLOW_RED`),
and the hard stops — risk=high installs, credentials or live keys, irreversible
external writes, an escape channel actually firing, and publishing to the public
repository. Merging, deploying and the version bump are Felix's.

**#241, found by a sweep and not by reading.** A read-only workflow over the
engine, tables, hooks, skills, templates, handoff and memory raised 120
statements about who merges; skeptics refuted 89 as history, real stops or
unread, and 31 survived. The live ones are fixed in #241, with eleven
assertions of which eight fail against the previous engine. The unattended
loop's refusal to start or repair red work was kept, reworded: running with
nobody present is consent, not a merge rule. The repository's own label
descriptions were edited to match.

**#2, observed working.** With #239 deployed, a worktree that changed
`engine/harness/lib` read `installed ok`, the gate went green, and `felix merge`
merged it — the command #2 was filed because it could not run. Its evidence
policy refused first, correctly: "a changed engine at an unchanged version
deploys nothing". The bump now rides in the pull request, and the home's
`felix install` deploys the declared version without writing one of its own,
so there is no second version pull request. Criterion 2 was seen on real data
once: between #239 merging and #240, a worktree read `installed FAIL` because
main named an entry that did not hold main's engine.

**Where Felix stands against v3.2.** A workflow extracted the end state from the
spec and amendments, assessed each of the eight components against main with
evidence, and had skeptics try to downgrade every "implemented" claim. Of 190
requirements: **11 implemented, 95 partial, 84 missing** — unweighted, so a
direction rather than a distance. The foundation is real: unknown blocks,
applicability is derived and never stored, the marker refusal, checker
qualification, a Stop hook that ignores what the model says. What makes it v3.2
is mostly absent: nothing proposes an obligation nobody named, admission is
writing a row, receipts do not name what they discharge, and there is no
release state machine beyond merge. The north-star eval breaks at its first
step. Three findings were re-read in the code before being believed:

- **Applicability fails open.** `felix_obligation_state` reads any `applies` exit
  other than 0, 126 or 127 as DORMANT, "the grounded state says this does not
  apply here". A check that crashes with 2 or 128 makes a blocking obligation
  vanish. Same defect #236 fixed for qualification premises, in a worse place.
- **A witness that errors reads as absent.** In `probes.sh`, after a probe finds
  nothing, a witness exiting anything but 0, 126 or 127 yields `empty`.
- **Session start adopts capability rows on its own** ("Adopted automatically,
  because the checkout grew them"), which the assessment reads against v3.2's
  rule that a relation produces facts and never policy.

**Next, in order.** (1) Applicability and witnesses fail closed: one exit code
means grounded-false and every other is UNKNOWN, qualified through the six
controls. Felix's. (2) The epoch's topology hash in the gate receipt, so a
changed gitignored or `$HOME` fact cannot ride an old green. Felix's. (3) A
baseline obligation-discovery pass on one governed product that writes
candidates and admits nothing — Felix builds it; the schedule and model spend
are the founder's. (4) CI enforcement of `felix merge`'s blockers, which needs
the founder to choose GitHub Pro or accept that CI is advisory. (5) Grants for
high-risk plugins whose hooks run in every session with no record (ECC,
semgrep, security-guidance), and a gate that refuses a `stack.tsv` risk below
its inspected risk. (6) Re-point `deploy-check` and `engine_deployed` to #239's
question. Standing: `projects/bazaar` and `projects/webapp` stay untracked.

