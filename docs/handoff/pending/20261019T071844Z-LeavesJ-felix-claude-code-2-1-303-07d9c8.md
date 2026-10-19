### 2026-10-19: the capability lane stays; need intake is built now, and capability authority waits on the trust milestones

This records the founder's answer to the 2026-10-18 capability-plane brief. The
brief is `docs/2026-10-18-capability-plane-thesis.md`, with its PDF in
`docs/pdf/`. Its evidence is in the memory root, under
`audits/2026-10-18-capability-plane/`:
- the changelog snapshot;
- deck v3's text;
- the scout's report;
- five blind candidates, with their refutations;
- three verification reports.

This section changes no code. The roadmap text is unchanged, because the
09-25 capability lane (roadmap §3) already says what was decided.

**Decided by the founder, 2026-10-19.** "Keep the 09-25 lane: build intake now,
and gate capability authority (dispatch, leases, floor) on the trust
milestones. Reword deck slide 13 to match."

- **What it settles.** Deck v3's slide 13 note read "finish Trust Plane MVP
  before Capability work". That contradicted roadmap §3, and the roadmap binds.
  On 10-18 the founder had described trust-first as the original decision.
  This answer replaces that reading.
- **Need side.** None of these waits on a trust milestone:
    - obligation intake and admission (I1, I2 in the brief);
    - the seeded-omission corpus, with a second-family arm and a
      strongest-host arm added by protocol amendment;
    - Codex read-only as a second-family author;
    - the mods round (#417), extended with Q9-Q14. A lane session started it
      on 2026-10-19, and its record goes to `audits/2026-10-19-mods-round/`.
- **Authority side.** Each of these keeps its trust gate:
    - the attended dispatch tick (D3), after the dry-run lease;
    - any lease that grants real authority;
    - the consequence floor, which stays advisory, after the outcome record;
    - retirement on attributed outcomes, after the outcome record and the
      retire re-key;
    - any capability act that runs with nobody present (dispatch, a lease,
      a retirement), after the step 15 judge pin and the arming sitting.
      Unattended landing is a separate decision (land-on-green, 2026-10-15)
      and is live; this sentence does not reach it.
- **Lane order.** 0cw makes the order Felix's call. It is the brief's §10:
    1. Workflow stage checks start now. On builds before 2.1.301 a Workflow
       agent can skip its step while the run reports success (changelog
       line 85).
    2. The extended #417 round.
    3. The corpus, once its ceiling is set.
    4. Codex read-only.
    5. The dry-run lease.
    6. The retire re-key.
    7. The outcome record.
    8. The D3 tick.
    9. The replay, as approved.
    10. The floor.
- **What counts as a lane session.** Only one that lands engine code or
  produces a sealed, measured number. From 09-25 to 10-19, 16 of the 80
  commits on main touched capability libraries. Two were features, and none
  was a lane item.
- **The deck.** v4 sits beside v3 in `~/Downloads`, with slide 13 reworded:
    - title: "Two planes, built together. Authority follows trust.";
    - subtitle: need intake is built alongside the trust layer, and the right
      to act on it comes only as fast as the trust plane can verify;
    - capability questions: what the project owes, who supplies each item and
      under what lease, who checks it besides the builder, and when a
      provider loses its place;
    - box footer: "Intake now · dispatch and leases wait on trust";
    - closing line: "Capability without trust is ungoverned speed; trust
      without capability judges only what was listed";
    - source note: this decision, dated.

  No other slide changed. Slide 17 still says "Current build focus: Trust
  Plane MVP" and "Next frontier: Capability Plane", which is now out of step.
  The brief's §9 has wording for it. The deck is the founder's document.

**Still the founder's, and not asked again until he raises them.** These are
the brief's §11:
- Decide the 22 waiting candidates (Elenchus 7, Veldra 15).
- Whether Felix may later admit witness-backed TASK_BLOCKING rows itself.
  That could happen only after control 7 and the judge pin.
- Two consents:
    - the corpus spending ceiling: $96-349 for one corpus at 3 runs, and
      $172-632 with the replication;
    - a Claude Code 2.1.300+ binary, downloaded into the rig folder rather
      than installed in place.

**Stale text this exposes, for the next fold and README pass.** Two places
still say a weak corpus result narrows Felix to "the obligations people
name": 0cw's capability item 3, and `README.md:410-414`. Roadmap §5, as
amended on 10-01, replaced that rule.

**The standing direction file.** The founder also asked, on 10-19, for one
document with "the absolute say in standing", so that the next session knows
which roadmap is current without reading every past roadmap note. This pull
request adds `docs/direction.md`, with a PDF in `docs/pdf/`.
- It wins over the roadmap, 0cw, the pending sections and memory notes.
- It records this decision as its row 25.
- It lists what is no longer binding.
- It holds no live status, so engineering PRs never touch it.

The constitution gains one sentence naming it, which is why this pull request
waits on the founder's yes. A small engine change is proposed separately: the
session-start hook should name `docs/direction.md` first in its reading list
(`engine/harness/hooks/session-start`, around line 532).
