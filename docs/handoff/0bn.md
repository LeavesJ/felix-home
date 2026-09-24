## 0bn. 2026-09-19 — the endgame affirmed, and three direction decisions taken on evidence

Read `docs/2026-09-19-direction-decisions.md`; this section only points at it
and corrects the one below.

**Correction to §0bm.** It says the public repository is at engine 0.49.121
(`f6341ba`). After #262 merged it was brought forward again: **0.49.122**,
public main `609a4f6`, by `LeavesJ/Felix#2`, suite 2455 passed, 0 failed, 3
skipped, CI green.

**The founder's direction, 2026-09-18.** Felix's endgame is an autonomous
engineering control plane — a Capability Plane and a Trust Plane, with models
as the substrate Felix dispatches — and the thesis is engineering expertise as
infrastructure. How to get there was delegated: "we'll go with what's best".

**Decided, each by independent proposals, one refuter per proposal and judges
with different lenses (39 agents over three workflows):**

1. **The engine stays in bash: rows first.** No new runtime on the enforcing
   path. Language-caused lessons are 36 of 159; v3.2 §12's mutation rights
   come from git refs, not types; every alternative stalls 9 to 25 sessions
   and adds to the trust base. First build: `lib/table.sh` as a validator, an
   engine-only `schemas.tsv`, a gate `schema` check that fails on a table with
   no schema row, then `coverage.tsv` born on that layer. This reverses what I
   told the founder on 2026-09-18.
2. **ECC's hooks go off in two steps.** Now: the founder adds
   `ECC_DISABLED_HOOKS` and `GATEGUARD_BASH_ROUTINE_DISABLED` to the `env`
   block of the user settings, keeping four guards Felix has no equivalent
   for. After the harvest rows land (a seeded `deny.tsv`, `verifier` rows for
   checker configs, dependents as context, formatting inside the gate):
   `hooks_enabled` false. Measured: a settings `env` entry reaches ECC's hook
   processes. Project-scope plugin options are not read.
3. **Control plane v0 is the lease and its record, not the schedule.**
   `felix dispatch`, one tick typed by a person, one `--bare` session with a
   single allowed write. Measured: a launcher chooses a session's toolbox per
   dispatch (27 plugins down to 1), so leases and revocation do not need
   mid-session activation.

**Found in the engine along the way, each now Felix's to fix:** the decision
epoch depends on which `git` is on PATH, so a scheduled answer would read
stale on the laptop; `automerge.sh` and `repair.sh` read the latest run of any
workflow; the discovery protocol has never produced a file on this machine;
`guard.sh` cannot see a refusal made through `permissionDecision`.

**The market, verified at primary sources.** The whole-loop gap is real.
AI-SDLC already commits SHA-bound receipts to the adopter's repository, so that
claim is not novel; lead with a derived blocking UNKNOWN, receipts that go
stale, and need-driven capability lifecycle.

**Queue, in the order the decisions imply:** the validator and `coverage.tsv`;
the harvest rows; the obligations request run once by hand on elenchus; epoch
portability and the workflow filter; `felix dispatch`; the public wedge.
§0bl's items 2 to 7 stand behind these.

