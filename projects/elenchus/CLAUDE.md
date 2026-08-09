# Elenchus

A retention and deployment engine: a thin doctrine layer over a rented model,
not a tutor. Rent capability, gate doctrine. The durable value is the loop, the
gates, and the owned context. Never the raw model.

Python, `src/` layout, package `elenchus`. Run everything with
`PYTHONPATH=src`.

---

## Operating doctrine

### 1. Default: act

You have standing authority over this repo. Attempt first, report after.

Out of scope is not a reason to decline. If a question sits outside the current
task, outside Python, or outside what you are certain of, attempt it anyway and
label the confidence. A labelled wrong answer is worth more than a refusal.

You may disagree with the plan, propose work nobody asked for, choose your own
tooling, read anything in the tree, and refactor opportunistically inside your
tier. Do not ask permission for reversible work. Do not narrate what you are
about to do. Do it, then show what happened.

There is no mandatory reading ritual. `docs/lessons.md` is a runbook, not a
gate. Open it when you are working a surface it covers. It is long and mostly
historical; the parts that still bind are restated as Invariants below, and the
parts a linter can catch now live in `scripts/gate.sh`.

### 2. Abstraction police

One rule with two faces: **nothing may sit above the evidence under it.**

**Claims.** Every statement about this codebase is pinned to something you read
or ran in this session.

* Cite `file:line`, or the command whose output you saw. "The loop emits X"
  means you read the line that populates it.
* Never infer that a symbol exists from a doc, a spec, a filename, or a prior
  session. Grep it. This file's previous version named an `aim` / `core` module
  pair, and `core.py` has never existed.
* Label confidence explicitly, always one of three. **verified**: I ran it and
  read the output. **read**: I read the code and did not run it. **assumed**:
  neither, and here is what would falsify it.
* "Wired", "green", "resolved", and "should work" are claims. Prove the path
  executed, not that a suite passed. A green test over a hand-built fixture no
  production path can emit is a lie with a checkmark on it, so for any signal
  the engine consumes, test that a real path produces it.
* A spec section inherits stale claims from earlier sections. Verify against the
  merged code, not the prior prose. When they disagree, the code wins and you
  fix the spec in the same change.

**Structure.** No indirection without a second real caller.

* Rule of three. Two call sites is a copy. Extract on the third.
* No protocol, base class, registry, or dispatch dict with exactly one entry. If
  the second one is coming, wait for it.
* No config key, env var, or flag with one caller and one value. A knob nobody
  turns is a false promise of flexibility.
* No function whose entire body is a call to another function. Delete it and
  call through.
* Before adding a layer to make something easier, check whether removing an
  existing layer does the same job.
* `Manager`, `Helper`, `Util`, or `Handler` in a name means the boundary is
  wrong. Name what it does.
* When you do add a seam, write "this exists because X and Y both need it" next
  to it. If you cannot name X and Y, do not add it.
* Relocating an invariant guard to satisfy one awkward caller un-guards every
  other caller of the original seam. Reformulate the check into a shape every
  caller can satisfy instead of moving it.

Override the structural half only when a second caller is genuinely blocked on
the seam existing first, such as a protocol needed to fake in tests. State the
override and name the second caller.

### 3. Dynamic workflow

Rigor scales with blast radius. Pick the tier from the surface you are touching,
state it in one line before you start, run that tier's gate. Escalate freely.
Never downgrade silently.

**T0 direct.** Reversible, one module, no behavior or interface change. Docs,
comments, tests, an internal refactor.
Gate: `./scripts/gate.sh`. Then ship. No plan, no review, no announcement.

**T1 checked.** Behavior changes, or the diff crosses a module boundary, or a
dependency moves.
Gate: T0, plus name the failure classes specific to that surface and check each
against the diff, plus run the test that covers the change and read its output.
A return type change updates every caller in the same commit, including callers
the offline suite never executes, so grep `tests/` for the symbol and treat a
hit inside a `@live` file as a real caller.

**T2 adversarial.** A canonical interface, durable state, or a doctrine surface.
Surfaces: `types.py`, `persistence.py`, `orchestration.py`,
`assessment/judgment_loop.py`, the `content/` schemas, and anything a learner
sees.
Gate: T1, plus an independent reviewer running in an isolated worktree at the
reviewed commit, so in-flight edits cannot poison its results. A reviewer that
runs `pytest` against the live tree while you keep editing reports false
failures. The reviewer executes the claim; one that only reads the diff is a T1.
For any selection or ranking claim, the reviewer runs the function against real
content. A confident review synthesis can be wrong, so read the cited source
span yourself before acting on a headline finding, and escalate a near tie of
opposite conclusions to J rather than resolving it quietly.

**T3 stop and ask.** Do not proceed without J.

* Changing the meaning of a stable identifier instead of adding a new one.
* Deleting or migrating durable state: the ledger, learner state, the queue.
* Secrets, `.env*`, or anything that changes the tracked set of the public repo.
* Force push, history rewrite, or any git operation that drops commits.
* Your better design conflicts with an explicit instruction from J. Surface the
  conflict, do not solve it silently.

Parallelism is a property of the tier, not a standing order. Fan work out when
the streams have no data dependency and each returns something checkable. Do not
fan out to look busy.

Installed is not active. Load the MCPs and plugins the task needs and no others.
A server that is connected but unused still costs context on every turn.

---

## Architecture

`orchestration.run_session` wires the loop. Verified against its import list;
re-verify before relying on this map.

* `aim` opens the session. `Core`, `CoreCandidate`, `CoreVerdict` are types in
  `types.py`, not a module.
* `experience.select_experience` picks what gets served. `forge` builds dynamic
  experiences over curated rubrics.
* `assessment` is regime split behind `ASSESSORS[regime]`: `judgment_loop.assess`
  for `open_ended`, `checkable_scorer.assess` for `cs_technical`, with
  `sharper_grader` auditing.
* `state.STATE_UPDATERS` moves learner state. `scheduler.propose_open_ended` and
  `scheduler.schedule_cs` queue what is next.
* `persistence.Store` is the only thing that persists: state, ledger, queue.
* `content_loader.load_library` and `load_progression` read `content/`.
* `surface` and `terrain` shape what reaches the learner. `web/` is a package:
  `app`, `session_runner`, `sitting_store`, `slots`, `vessels`, `voice`.
* Mining and validation tooling sits alongside the loop: `generator`,
  `admission`, `crystallization`, `elicitation`, `lift_test`, `policy`,
  `veldra_ingest`.

Adding a domain later means new content plus a map under `content/`, never an
engine edit.

Twelve strategy documents sit untracked at the repo root. Only `POSITIONING.md`
binds; the rest are drafts kept for history. When it disagrees with the code,
the code wins.

---

## Invariants

Things no linter can catch. Everything mechanical is `scripts/gate.sh`'s job.

1. **Doctrine is data.** Maps in `content/maps/` and rubrics in
   `content/rubrics/` are first class versioned content kept out of `src/`. The
   model never holds the doctrine.
2. **The judgment loop never** hands the answer, names the frame, agrees or
   reassures to soften, removes effort, or grades the conclusion. The friction is
   the product.
3. **No learner-facing surface names a frame or a move, in any medium.** Naming
   the frame is not naming the conclusion, so the conclusion-agnostic check
   passes it, and it still re-attaches the label the push prompt exists to strip
   and corrupts the unprompted signal. Frame level decomposition belongs in the
   author log only.
4. **Decay demotes, never deletes.** Forgetting is retrieval failure, not
   erasure. State rows are demoted and rescheduled, never removed.
5. **Open-ended state moves on rigor and trajectory, never correctness.** The
   conclusion is never graded.
6. **The unlabeled problem is the moat.** If recognizing the type and running a
   procedure solves it, it is homework in a costume and does not ship.
7. **A safety property is a property of gate times distribution.** Name the
   distribution it was measured on. If the tool runs on a different one, the
   property is unproven there.
8. **When a vision claims automation, name the human judgment each validating
   run relied on.** The same mechanism unsupervised is a distinct, untested
   claim.
9. **Confidential docs and `data/` never enter git**, and the tracked
   `.gitignore` must stay generic. A pattern that names a secret is itself a
   leak; machine local names belong in `.git/info/exclude`.
10. **Log the traceback server side before genericizing the wire.** A caught
    error whose only copy rides the client wire is destroyed by the refresh the
    product itself recommends.

---

## Delivery

* Output a unified diff against the current files, never a rewritten file.
* Never invent a path or a symbol. Grep first. Missing context becomes a
  `TODO(assumption):` inside the patch.
* Response shape: plan in bullets, patch, run commands, risks. Terse, no filler.
* TDD: the failing test first, then the implementation. Keep files under roughly
  500 lines. Validate input at system boundaries.
* Run and launch with `PYTHONPATH=src`, never relying on the editable install.
  Web app: `PYTHONPATH=src .venv/bin/python -m elenchus.web`. Tests:
  `PYTHONPATH=src .venv/bin/pytest -q`.
* Stage explicit paths. Never `git add -A`, never `git add .`, never `-f` on an
  ignored file. Subagent reports go under `.superpowers/sdd/` and are never
  staged.
* Run the suite and `git commit` as one gated chain. A piped `pytest | tail`
  masks the exit status and will commit a red tree.
* `docs/DEVLOG.md` entry in the same change. A change without one did not
  happen.
* Never add a `Co-Authored-By` trailer.
* No em dashes in prose.
