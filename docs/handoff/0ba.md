## 0ba. Verified at session close, 2026-09-13 — the engine is public, and the repository it came from is not

| | |
|---|---|
| public | `github.com/LeavesJ/Felix` — Apache-2.0, 5 commits, 114 files, CI green |
| private | `LeavesJ/felix-home`, renamed; engine **0.49.111** deployed and confirmed by the CLI |
| merged | #222 through #232, eleven pull requests |
| gate, on the deployed engine | **pass** — 2057 passed, 0 failed; 36 controls across 5 checkers |

**A snapshot, not a path filter, and the reason is in the history.** The
release plan in §0 item 1 said the open-source path is a filter on `engine/`,
because a filter structurally cannot carry `projects/` content. That reasoning
holds for the tree and not for what a filter would drag behind it. Commit
`98c48ce` is an ancestor of main, and `98c48ce^` still yields 16 files and
899,744 bytes under `projects/*/memory/` — verified by fetching
`says.log` from it, 99 lines of verbatim founder prompts with session
identifiers. Another project's session memory is in there too, quoting its
users' confidential material. So the public repository has four commits and no
prior history, and **`felix-home` must never be flipped public** without a
history rewrite nobody has done.

**What a six-lens audit found, after adversarial refutation.** Forty-six
findings survived, eleven were refuted, eight were blockers. Two were checked
again by hand before being acted on, because eleven of the forty-six came back
with no skeptic verdict and "confirmed" there means only "not refuted".

**The grant that would have shipped.** `projects/felix/autonomy` permits
commissioning unattended and `autonomy.commission` pins the policy hash it was
granted over — a hash that still matches in a fresh clone. Publishing both
would have handed every stranger who clones the repository a permission they
never gave, which is the one thing the constitution says a system may never do
for itself. The question worth carrying forward is not "is this secret" but
**is this state, or is this consent**.

**The scanner could not see the one credential Felix is about.**
`ANTHROPIC_API_KEY` sat in `FELIX_SCAN_CONTEXT`, which is applied whole-line and
claims "nothing on this line is a literal". Every other entry there is an
expression that produces a value; a variable name is not one. Given one live
key written twice, differing only in the variable it was assigned to, the
scanner exited 0 on the one named for Anthropic and 1 on the other. Fixed, bounded by a new `FELIX_SCAN_HARD` so a lookup no
longer deletes a real key used as its fallback default, `github_pat_` added,
and `--tree` added because the diff gate compares main to main on a fresh clone
and reports clean having read zero lines. `--tree` over the tree returns 17
hits and every one is a planted fixture.

**And it caught this file.** The first draft of the paragraph above quoted the
two assignments verbatim to show the difference. The fixed scanner flagged the
line — correctly, it is keyword-assignment shaped — and because the gate's
`secret` check runs over the tree, four `secret` qualification controls that
expect a clean tree went from pass to fail with it. Prose poisoned the
baseline, which is the hazard `qualification.tsv` already solves for itself by
assembling its credential values at run time. The demonstration is described
rather than quoted now. Worth knowing before writing the next one: the
placeholder exclusion covers three ASCII dots and not the single-character
ellipsis, so `…` does not read as a redaction.

**Ten seconds of every session, in every governed project.** With a commission
grant live, the session-start hook's process exits at 1.9s and the stderr pipe
the platform reads reaches EOF at 12.2s. Closing descriptors above the standard
three inside each background subshell made it 1.9s, repeatably. **Measured and
inferred are kept apart** in the code and here: the A/B is measured; *why* a
descriptor in the 10–13 range holds the pipe is inference, and a minimal
reproduction of that shape did not reproduce the hang. The helper's first
version silenced each close with `2>/dev/null` and thereby destroyed stderr for
the rest of the shell, which an assertion caught.

**The graph is now stated rather than routed.** Built three times and queried
once in 72 sessions; the `orient` route only helps somebody who already knew to
ask. Every session is now told three facts — it exists, whether it still
describes this tree, and the command — read from the last 4KB of the graph in
8ms rather than 83ms for the whole file. `graphify update` needs no model and
writes by atomic rename, both checked in its source, so a code-only refresh
fires in the background when the graph is behind.

**Two checks could not run in a repository that governs only itself**, which is
what anybody who clones Felix has. The independence assertion now skips and
says why (#231). The independence *qualification* controls still cannot be
satisfied there, because their premise is a second project's name leaking, and
`felix_qualify_run` has no word for a control whose premise is absent — only
met, held, unrunnable. That is issue #233, and until it is closed the public
repository's CI runs the suite and not `felix gate`, with the workflow saying
why in full.

**The rename, and what it cost.** GitHub treats repository names
case-insensitively, so `Felix` and `felix` cannot coexist on one account and
the private repository became `felix-home`. `gh repo create` reported "Name
already exists" on the attempt that had in fact succeeded — verify with
`gh api repos/<slug>`, not with the error. `remote_match` went stale and is
corrected; the `.felix` marker is what kept the binding working throughout. The
matcher is a case-sensitive substring test, so the public `Felix` was never
going to bind to this project's doctrine — checked, not assumed.

**The licence, and why it was cheap to change twice.** It shipped MIT and was
changed to Apache-2.0 the same hour, for the patent grant from future
contributors and the explicit trademark reservation on the name. Neither
matters yet, which is exactly why it was the moment to decide: with one
copyright holder and no outside contributions, relicensing is a commit. The
first patch somebody else lands makes it a negotiation.

**Next, in order.** (1) `felix commission` — the grant went stale when the
tables moved, which is the mechanism working, and re-granting is consent only a
person can give. (2) Three routines due: `discover`, `promote`, and `graphify`,
the last because main moved past the commit the graph was built at, which is the
corrected row (#225) reporting correctly. (3) Issue #233, the inapplicable
verdict for qualification. (4) Standing: `projects/bazaar` and `projects/webapp`
are untracked and the founder has said both are done, so they stay that way.

