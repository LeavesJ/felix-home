## 0af. Verified at session close, 2026-08-30 (overnight) — the advisory layer measured, and the redesign on the table

Each line produced by a command. Newest first under §0. The founder's overnight
directive: full sweep, build toward the redesign, don't stop. This section is
what the morning inherits.

| | |
|---|---|
| head | `main` at the docs merge carrying this section; the night then continued — **#105** and **#106** merged after it, CI `gate` **success** on every one |
| deployed engine | **0.49.29**, byte-identical to `main` — verified end-to-end against the cache, not the tree |
| suite | **922 assertions**, from 888 |
| governed projects | three — felix, elenchus, veldra — all committed |
| open issues | **9** — #97, #98, #100 closed by #103; #102 by #105; #82 by #106 |
| open PRs | none at close |

**Postscript, same night.** After this section first merged, two more backlog
fixes went through the full drill: **#105** (a flag is not a positional —
`felix adopt --help` had declared a capability named `--help`, created a
`setup.tsv` whose presence flips `felix setup` to "Nothing outstanding.", and
minted a memory root; the reverse-test replayed the incident inside the suite,
where the old code corrupted the fixture and seven unrelated assertions failed
downstream) and **#106** (#82 — `installed` compared `harness/` alone, so a
`hooks.json` that never deployed certified as ok; demonstrated live against a
scratch cache, old gate ok / new gate FAIL, then fixed at both install sites
and in the gate's own inline copy). Numbers above are post-postscript.

**Start here: `docs/2026-08-30-advisory-redesign.md`.** The redesign memo, with
three yes/no decisions at the end. Everything below is the evidence trail.

### The follow-through baseline exists, finally

Every prior section said no number could be produced before this one. Against
instrument #54, five days of data:

| | |
|---|---|
| mandates rendered | **11**, across 5 sessions |
| followed | **2** (≈18%) |
| live-audited mandates right for their turn | **0 of 3** |
| share of Felix's speech that was the false #97 message | **48 of 136 (35%)** |
| Stop-hold refusals audited correct | every one |

The composite: **the mechanical layer is where all the value is; the advisory
layer was speaking with precision it did not have, and its loudest voice was a
false sentence.** That split — not "governance is broken" — is the accurate
diagnosis, and it is what the redesign is shaped around.

### What shipped — #103, `fix(advisory)`, red tier, merged on green CI

- `subagent-stop` claims the checkout's condition, not the subagent's conduct,
  once per session. It said "This subagent changed files" to every read-only
  reviewer after any parent commit; the payload carries the parent's session id
  and nothing about the subagent, so the sentence asserted a fact the hook
  cannot know.
- The Stop finish-line message names the **play** (both slots were `${skipped}`,
  so a partly-followed play read as a one-step play ignored), fires once per
  session, and names its answer channel.
- **`felix route --ack "<reason>"`** — the answer channel. A decline lands as a
  durable row in `decisions.log` and quiets exactly one finish-line complaint
  (state consumed on read). This is HANDOFF §0z's recording-only carve-out
  built: `named` + `reached` (ledger) + `declined-with-reason` (new) is the
  observable set the deliberation layer needs, **enforcing nothing**.
- The mandate language is recalibrated: provenance stated, decline requested,
  "requirement, not a suggestion" retired — that sentence was calibrated for a
  channel that is nearly always right, on one measured at 2-of-11.
- #100: the unattended scope-bound row counts `red content` rules, through
  `felix_count`.

Reverse-tested wholesale: product reverted to HEAD with the new tests kept —
15 of 16 new assertions went red. Verified again after deploy by driving the
**cache's** hooks against a scratch governed repo: new sentence, dedup, ack
round trip, consumption, fresh-session behaviour all confirmed live.

### Two of tonight's own guards fired on tonight's own work

Worth more than the fixes. The independence check — hardened earlier tonight
on #96 — refused this change for a comment in the engine naming a governed
project. And `secret-scan` refused a test fixture whose content pattern was
shaped like a key marker. Both corrected by changing the input, not the guard.
A gate that fires on its own author the same night it was built is the
strongest evidence yet that invariant 5 is being held.

### The sweep, so nobody re-reads what was already read

All eleven docs in `docs/`, issues #2/#28/#29/#31/#58 with comments, the
auto-memory, lessons.md, says.log, routes.log, and the per-session ledgers.
The records the redesign anchors on: §0z (the deliberation architecture and
its gate), §0c (the charter correction), #58's registry verdict
(populate, don't build), #29's five causes, the earned-autonomy authority
kernel, and v3 §19's metric correction (the objective needs a quality term —
adopted in the memo §4).

Three live misroutes this session are recorded on #29 with the baseline. The
founder's gate on the deliberation layer — "confirm repeatedly that Felix has
no routing role" — resolved differently than either side expected: the role
exists, roughly an order of magnitude smaller than Felix's speaking volume,
and phase-keyed rather than keyword-keyed. Decision A in the memo is that
finding made structural.

### Standing

- `tests/run --record-assertions` after any assertion change; 904 on record.
- **The mandate path still fires per-turn until Decision A is taken.** #103
  made it honest, not smaller. If the founder says yes to A, the
  `UserPromptSubmit` mandate rendering is retired in favour of session-start,
  proven phase transitions, and the finish line.
- `decisions.log` accumulates from today. The 20-session review point for
  Decision B starts counting now.
- Two stale-copy notes for veldra, carried from the recovery: twelve
  ReserveGrid-OS worktrees hold a 136-line `scripts/gate.sh` predating the
  `FELIX_GATE_ROOT` fix — each is a false-pass gate if run in place; and the
  canonical is the 142-line copy. A veldra session should refresh them.
- The follow-through baseline is **11 mandates, 2 followed**. Small n, stated
  with it — but it is a number produced by the instrument, which no prior
  section could say.

