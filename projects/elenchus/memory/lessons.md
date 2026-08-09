# Elenchus — Lessons Learned

Read this checklist before every code change. Update it after every correction or build/test failure.

## Pre-Commit Checklist (every commit)
1. `ruff format .`
2. `ruff check .`
3. `pytest`
4. Update `docs/DEVLOG.md` with what changed and why.
5. No secrets/`.env` staged (`git diff --cached`).
6. No confidential docs tracked:
   `git ls-files | grep -iE 'berkeley|guidebook|blueprint|brief|founderceo|judgmentloop|lifttest|mvp_scope|\.pdf'`
   must be empty.
   Also `git ls-files | grep -E 'content/lift/scenarios\.yaml$|content/lift/candidates\.yaml$'` must be empty
   (the real lift banks are gitignored; only the *.example.yaml stubs are tracked).
7. Inversion check: `git status --short | grep -v '^??'` empty, or every Modified file
   has a written hold reason in DEVLOG.
8. Stage explicit paths only (no `git add -A`).

## Before Declaring a Change Complete
1. Pre-commit checklist passes.
2. The relevant test actually runs and passes — observe the output (evidence before assertion).
3. DEVLOG updated.
4. No confidential docs tracked (`git ls-files` check).
5. For core-path changes (`orchestration`, `judgment_loop`, `persistence`, `types`):
   an adversarial review pass was run and its findings addressed.

## Seeded principles
- **L-1 Doctrine is data.** Maps + curator rubrics live in `content/`, versioned, never
  hardcoded in `src/`. The model rents capability; the gates hold doctrine.
- **L-2 Confidential docs never tracked.** The Berkeley Guidebook is a personal life +
  financial plan; the design docs are internal. Gitignore + `git ls-files` verify, every
  time. (Mirrors the Veldra TP-3 near-miss where a private doc was nearly pushed.)
- **L-3 Reversible decay, never deletion.** State demotes/reschedules; rows are not deleted
  (Guidebook §5: forgetting is retrieval failure, not erasure).
- **L-4 Open-ended state moves on rigor/trajectory, never correctness.** The conclusion is
  never graded.
- **L-5 Judgment-loop disband rules.** It never hands the answer, names the frame, agrees to
  soften, removes effort, or grades the conclusion. The friction is the product.
- **L-6 The unlabeled problem is the moat.** If recognizing the type + running a procedure
  solves it, it is homework in a costume and does not ship.
- **L-7 Never force-add gitignored scratch.** The SDD workspace `.superpowers/sdd/` (task
  briefs, implementer reports, review packages) and tool dirs (`.claude-flow/`) are gitignored
  scratch and must never be committed. A fix subagent used `git add -f` to commit its report;
  it was reverted. Subagent dispatches must say: write reports under `.superpowers/sdd/` and
  stage ONLY source/test/docs paths — never `git add -A`, never `-f` on an ignored file.
- **L-8 A green suite can hide a broken bootstrap.** When a runtime gate fails loud over the
  *whole* content library (e.g. `load_gated_library` raises on any rubric lacking a corpus
  anchor), every state-builder entry point (`cli.build_store`) must seed the WHOLE library, not
  one hardcoded item. In Step 3 the e2e tests seeded all three refs explicitly AND the local
  `data/elenchus.db` was already fully seeded — both masked a fresh-DB `GateError`; only the
  final adversarial review, with a fresh-tempdir repro, caught it. Prevention: for any entry
  point that seeds state, add a fresh-DB end-to-end regression test that exercises the real gated
  path (build state → select → assert no raise), so fixtures and a pre-seeded local DB cannot hide
  a broken shipped seed.
- **L-9 A green test over a SYNTHETIC fixture can hide a dead production path.** In Project 1 the
  estimator's `strong` path read `unprompted_breadth`, populated only when a frame is reasoned
  *unprompted*. The test hand-built an `Assessment` with that shape and passed — but the judgment loop
  *never emits* it (it co-populates the `present_reasoned` delta with `frames_closed_under_pressure`, and
  intake-reasoned frames make no delta), so `strong` was unreachable in production. The pre-existing code
  even documented the unreachability and the test still "passed." Prevention: for any signal the engine
  *consumes*, add a test that a real PRODUCTION path *produces* it (e.g. run `assess()` and assert the
  field is populated), not only a hand-built fixture. Extends L-8: a fixture that can't occur is a worse
  lie than a pre-seeded DB. The whole-branch review then caught a second-order bug (the
  `reasoned_unprompted` signal over-credited stress-probed decision frames and bypassed the sharper
  veto) → fixed with `code not in probed`.
- **L-10 A return-type change updates every caller in the SAME commit.** When `schedule_next` went from
  returning a spec to `(spec, receipt)`, splitting "change the function" and "fix the callers" into two
  tasks would leave a red suite between them, which breaks the SDD per-task green gate and poisons the
  next task's baseline. Order the plan so the signature swap is one atomic task after the additive pieces
  land; every commit leaves `pytest` green. (Caught in plan self-review, not execution.)
- **L-11 Background processes don't survive agent turn boundaries — use a checkpointed stepper for
  interactive dogfooding.** A long-running `run_session` driver that blocked on file-IPC for the human's
  reply was reaped at the turn boundary (twice). For a multi-turn, human-in-the-loop live dogfood, drive
  the loop as discrete synchronous steps that each run to completion within one turn and persist loop
  state to a checkpoint file (`/tmp/dogfood/step.py`: `opening` → classify_intake + first push;
  `reply` → classify_response + continue), faithfully porting `assess()`'s control flow (the real
  `_select_target`/`_converged`/stress logic, `update_state`, `audit_sharper`) rather than reimplementing
  it loosely.
- **L-12 A spec section inherits stale claims from earlier sections — verify against the MERGED CODE, not
  the prior prose.** §17 (Project 3) leaned on §16's claim that `_INTERVAL_DAYS` "moves to
  `content/cadence/progression.yaml`, loaded via `load_progression()`." Against the merged P2 code that was
  false — P2 deliberately kept the constant in `state.py` (a DEVLOG-recorded refinement) and
  `load_progression` loads no staleness keys, so a P3 promote-threshold plan built on it would have rested
  on an unfinished L-1 migration. A 5-lens adversarial review caught it before writing-plans. Prevention:
  when a new spec section depends on a factual claim an earlier section makes about already-built code,
  re-verify that claim against the code/tests before building on it — prior spec text drifts from what was
  actually shipped (the spec-level cousin of L-9).
- **L-13 Conclusion-agnostic is not leak-proof — a surface that names the FRAME (not the conclusion) still
  contaminates the unprompted signal.** The first P3 receipt draft showed the learner the target frame
  ("serving `lead_with_what_you_refuse_to_do` … aims it at licensing") *before* the experience. Naming a
  frame is not naming a conclusion, so the conclusion-agnostic invariant passed it — yet it re-attaches the
  label `content/prompts/push.md` exists to strip and turns an unprompted deployment into a prompted one,
  corrupting `reasoned_unprompted`/`evidence_count` (the hard-won P1 rev.3 signal). Prevention: any
  learner-facing surface, in any medium, must withhold the move — surface the problem/scenario/trajectory,
  never the frame or drive; guard it with an explicit "no `frame_code` in the learner-facing string"
  assertion, and keep frame-level decomposition to the async author log. Medium-independent — carries to the
  future UI.
- **L-14 Moving selection from queue-time to live-propose changes WHICH item is served — re-verify every
  test fixture that implicitly depended on the old selection.** The P3 plan removed the `build_store` queue
  seed that had steered selection to `license_continuity`; under cold-start propose-from-live the value
  function instead ranks `decision_under_stakes` (frame `choose_the_failure_default_deliberately`) first,
  whose frames the test `FakeModel`s don't script → `KeyError` at the single atomic L-10 commit. The plan's
  own self-review missed it; an adversarial review that *actually ran* `select_next` over the real library
  reproduced it. Prevention: when a change alters a selection policy, enumerate the tests whose model/data
  fixtures assume a specific selected item and re-steer them (e.g. via the redirect seam) or broaden the
  fixture — and don't claim "green at every commit" for the seam-swap commit without running the rewritten
  suite against real content. (Corollary: an adversarial reviewer that runs code beats one that only reads
  it — for selection/ranking claims, have the review execute the function.)
- **L-15 An adversarial review's *synthesis* can be confidently wrong — trust the per-finding VERIFY stage,
  and check terminology against the source before acting.** The lift-harness spec review's headline
  ("dominant, load-bearing defect: EXP-001 mislabeled as `negative_lift`, it's a NULL") was **refuted on
  verification**: the doctrine's phrase "true null *of value*" means null-of-*preference* (the frame landed
  but didn't win), NOT the spec's two-axis dist-0 `null` cell ("the model can't see it") — EXP-001 was
  distinguishable (dist 1) + dispreferred = `negative`, exactly as written. Acting on the synthesis would
  have injected a doctrine error (scripting EXP-001 as indistinguishable, contradicting its documented
  dist=1). Prevention: when a review flags a "dominant defect," read the cited source span yourself before
  changing anything; a confident synthesis built on a terminology conflation is more dangerous than no
  review. (This is why the review harness keeps a separate verify stage — and why a near-tie of opposite
  conclusions gets escalated to the human, not silently resolved.)
- **L-16 An audit/decision record must not force a verdict its author never made.** SP2's `AdmissionRecord`
  required `gates: Gates` (5 non-optional human-gate verdicts), but a *screen-reject* (a candidate killed on
  the marginal_lift necessity result) never reaches the human gate-walk — so writing its record forced 5
  invented `pass`/`fail` verdicts into a committable provenance artifact whose entire purpose is honest
  audit. Surfaced only by **dogfooding the tool for real** (writing the 5 reject records during the Phase-2
  mine), not by any test. Fix: made `gates` optional (`Gates | None`), with the coherence validator
  requiring it for `admit_provisional`/`file_as_subframe` and allowing `None` for `reject`. Prevention: when
  a record models a multi-stage decision, make the later-stage fields optional for the exits that short-circuit
  before those stages — a required field that some valid path can't honestly fill is a latent lie in the
  record. (The spec's own §6 said "human gates left unevaluated" for rejects; the implemented type didn't
  encode it — a spec/impl drift the test suite couldn't catch because no test constructed a reject without
  gates.)
- **L-17 A shared helper's hardcoded resource budget, tuned for its original caller, silently breaks a new
  caller with different output characteristics — and the break may surface only in the live path.**
  `AnthropicModel.generate_output` hardcoded `max_tokens=1024`, correct for SP1's short lift outputs ("write a
  120-word pitch"). Reused by the SP3 elicitation probe on long reasoned-decision prompts, 1024 truncated the
  opening (`stop_reason=max_tokens` with a partial answer) or — when adaptive thinking fired — consumed the whole
  budget and left NO text block, raising `ModelError("no text...")`. Non-deterministic between the two faces.
  EVERY offline fake test passed (fakes return canned text, never hit the cap); it surfaced ONLY on the first
  @live run. Truncation was also a measurement risk: an opening cut off before the embed insight reads as absent
  for a non-genuine reason. Fix: make the budget a keyword param (`max_tokens: int = 1024`) defaulting to the old
  value (lift byte-identical), with the new caller passing a larger `LEARNER_MAX_TOKENS`. Prevention: when reusing
  a shared helper for a caller whose output size/shape differs materially, check its hardcoded budgets/limits
  against the new need and parameterize them (default preserving existing callers) rather than assuming the
  original constant fits; and for live-only behavior, run a cheap single-call sanity BEFORE a full multi-call
  batch — it catches the break without burning the whole run (and the tokens).
- **L-18 A runnable entry point that needs an env var must load it — or the documented launch command fails,
  even when a `.env` file is present.** `python -m elenchus.web` started uvicorn WITHOUT loading `.env`, so
  `ANTHROPIC_API_KEY` never reached `os.environ` and the Anthropic SDK raised `TypeError("Could not resolve
  authentication method…")` at the first model call — surfaced only in the founder's BROWSER dogfood, because the
  @live smokes had each done `set -a && . ./.env && set +a` first, so "it works in my smoke" was not "the
  documented command works." A mounted `.env` file ≠ the variable in the process environment. Fix: a best-effort
  `.env` loader in the launch entry (`os.environ.setdefault` per KEY=VALUE line, so a real exported var always
  wins; never log values). Prevention: when an entry point depends on env vars, either load them itself or make
  the documented launch command include the sourcing — and when validating a runnable thing, run it the EXACT way
  the user will (a smoke that pre-sets env the real command doesn't is testing a different command).
- **L-19 The setuptools editable install (`pip install -e .`) is UNRELIABLE on this Python 3.14 venv — launch and
  test with `PYTHONPATH=src`, do NOT depend on `import elenchus` resolving on its own.** Recurring symptom: the
  founder runs the documented `python -m elenchus.web` and gets `ModuleNotFoundError: No module named
  'elenchus'`. Root cause (diagnosed 2026-06-29): the `__editable__.elenchus-0.1.0.pth` is present and
  contains the correct plain path (`…/src`), yet `src` is NOT added to `sys.path` at startup — Python 3.14 +
  setuptools silently drops it. Every editable mode fails the **`-m`/`runpy`** resolution path: lenient (plain
  `.pth`) → `src` never on `sys.path`; strict (`editable_mode=strict`) → a `build/__editable__…` symlink-finder
  makes `import elenchus` work in a `python -c` context but `python -m elenchus.web` STILL raises (runpy
  doesn't consult the editable finder the same way). Prior handoffs "fixed" it with `pip install -e . --no-deps`,
  which works *momentarily in the same shell* then breaks again — a false fix. **The robust, deterministic
  commands (verified via health smoke, `GET /api/health → {"ok":true}`, `GET / → 200`):**
  - Web app: `cd ~/Documents/Elenchus && PYTHONPATH=src .venv/bin/python -m elenchus.web` → http://127.0.0.1:8000
  - Tests: `PYTHONPATH=src .venv/bin/pytest -q` (already the documented form).
  `PYTHONPATH=src` does not depend on the editable install at all, so it cannot recur. Prevention: when a `python
  -m pkg` launch fails with ModuleNotFoundError on a `src/` layout, do NOT reinstall editable and call it fixed —
  validate the EXACT command with a health smoke, and prefer `PYTHONPATH=src` (a thin repo-root launcher script is
  the only way to restore the bare `python -m` form, since a package cannot self-bootstrap its own import for `-m`).
- **L-20 MEASURE per-call latency before tuning `effort` — with adaptive thinking, high effort is NOT slow on easy
  calls, and the real lever is usually call COUNT, not per-call depth.** Diagnosing "the engaged agent is slow," the
  intuitive fix was to drop `output_config.effort` to low/medium on the simple classifier calls. Measured on Opus
  4.8 (2026-06-29): `classify_entry` was 1.3s at HIGH vs 1.8s at low and 6.5s at medium — high is *faster*, because
  adaptive thinking already spends little when the task is easy; lowering effort just changed the thinking regime
  for the worse. `generate_push` (a real judgment call) was 3.3s, not the 20–30s assumed. The actual cost was the
  egress fan-out: the old gate made one `check_injection_expressed` call PER hidden move (4 serial calls ≈ 11.3s),
  fired on every Echo, ~6–8× per session — that is where the minutes went. Fix that moved the needle: BATCH the N
  per-move screens into ONE `screen_moves(moves, text)` call (≈2.5s), reducing call count; the effort-lowering was
  reverted as a wash-or-worse. Prevention: never assume effort↔latency is monotonic on adaptive-thinking models —
  time low/medium/high (n≥3; they're noisy) on the ACTUAL call before changing it, and look first for redundant
  serial round-trips to collapse. A counterfactual timing of the old path (per-move @ high) vs the new (batched) is
  what proved the win — bake that comparison into the change; don't claim a speedup you didn't measure.
- **L-21 A review subagent that runs the suite on the SHARED working tree, dispatched while the controller keeps
  editing, will report false failures from the half-applied tree — isolate the reviewer.** During the engaged-agent
  build (controller-implements + parallel review subagents), the T1 terrain reviewer ran `pytest` on the live tree
  while the controller was mid-T3 editing `session_runner.py`/`voice.py`/`model.py`; it saw "8 failures in
  test_session_runner/test_web_api, one that passes in isolation but fails in the full run" and correctly flagged
  them as likely-unrelated. They were an ARTIFACT: at that instant the tree was inconsistent (a caller referenced
  `voice.opening`/`concierge_open` before the source defined them). Every committed state was green (282→284→288);
  re-running at the clean HEAD confirmed 0 failures and no random-ordering plugin. Prevention: dispatch review
  subagents that run tests with `isolation: "worktree"` (a frozen checkout at the reviewed commit, immune to the
  controller's later edits), OR instruct them to review the COMMIT via `git show <sha>` and run only that commit's
  own tests — never `pytest` the live tree — and to treat any full-suite failure as possibly later in-progress work,
  not the commit under review. "Passes in isolation, fails in the full run" during an active build is the tell.
- **L-22 A key-gated (@live) test rots SILENTLY when a signature changes — it never runs offline, so the drift
  is invisible until the next paid live run.** `test_live_intake_on_fixed_experience` called
  `select_experience(core, state, ledger, spec=None)`; when Step 3/immersive-scenes added the required `corpus`
  param (3915964/6d0f836) every OFFLINE caller was updated (L-10) but this @live test was not — it is
  `skipif(no key)`, so six merged builds and every `pytest -q` stayed green while the test was un-runnable. It
  surfaced a week later as a TypeError in the founder's first full `-m live` run, costing a 5-minute paid run to
  discover a bug that was free to catch. Prevention: (a) L-10's "update every caller in the same commit" includes
  callers the offline suite never EXECUTES — when changing a signature, grep tests/ for the symbol including
  live/skipped files, and treat a hit in an @live file as a real caller; (b) build live-test setups on the
  production path shared with offline-covered helpers (mirror `_first_open_exp`), never on retired shortcuts —
  everything before the model call should be executable offline, so a setup-only repro
  (`python -c` the setup lines) can verify it for free; (c) after fixing a live-only break, verify with a
  single-call live run of just that test (L-17), not the whole batch.
- **L-24 Read the ERROR CLASS of a live failure before debugging anything — `529 Overloaded` is Anthropic-side
  capacity, not the product.** A full `-m live` run died 9/25 with identical `anthropic.OverloadedError: 529`
  during a sustained overload window (the SDK's 2 default retries can't outlast minutes-long windows); the 16
  outside the window passed, including tests that had "failed" suspiciously the run before. Prevention: (a) a
  block of same-class 5xx/529 failures = infrastructure — wait it out, don't touch code; (b) resume with the
  cache instead of re-burning the whole suite: `pytest -m live --lf -q` re-runs exactly the failed subset;
  (c) only an ASSERTION failure (read the printed turn) is product signal on live runs.
- **L-23 A `pytest | tail` pipe MASKS the exit status — an `&&` gate chain built on it will commit a RED
  state.** The woven-stance Minor-hardening commit ran `pytest -q ... | tail -2 && ... && git commit`; pytest
  failed but the chain's status came from `tail` (zsh, no pipefail), so the commit landed red and had to be
  amended after a fix-forward. Prevention: when a pipe feeds the gate, capture the real status — either
  `pytest -q > /tmp/out 2>&1; echo "exit: $?"; tail -1 /tmp/out` and branch on the echoed status, or read the
  tail output and ONLY commit after seeing the literal "N passed" with 0 failed — never let `&&` after a piped
  pytest stand in for "tests passed."
- **L-25 A founder-gated dogfood that spans a server restart tests the WRONG build — and, when the
  experience under test lives in process memory, the restart DESTROYS the thing being tested.** The
  chained-sittings dogfood (2026-07-01) never touched the built feature: the evening sitting ran
  against a process started BEFORE the feature's commits existed, and the mid-evening restart done
  to "pick up the new build" wiped the in-memory sitting (`_last_record`/`_sitting_done`/channels),
  so the founder experienced exactly the amnesia the feature was built to kill — and reported it as
  a defect in the feature. Diagnosis required forensics (selection_log timestamps × the server
  PID's lstart × commit times) because NOTHING in the product said which build was running.
  Prevention: (a) any dogfood-gated build must be VISIBLE in one glance — `/api/health` and the
  session payload now carry `git describe` (`build`), and `/` is served `Cache-Control: no-store`
  so a stale shell cannot render against a new server; (b) when handing a dogfood gate to the
  founder, state the exact choreography ("restart the server FIRST, verify build X in the tab,
  THEN start the sitting") — a restart mid-experience is part of the test surface, not setup;
  (c) experience-critical state must not live only in process memory or the DOM — that is what
  durable sittings fixed; after it, restarts/reloads are safe mid-sitting BY DESIGN and belong IN
  the dogfood script rather than avoided.
- **L-27 A caught-and-surfaced error whose only copy rides the client wire is DESTROYED by the
  recovery action the product itself recommends — log the traceback server-side BEFORE
  genericizing the wire.** The living-sitting worker's terminal `except` put `repr(e)` on the
  wire (one transient muted line) and wrote nothing anywhere else; the honesty copy said
  "refresh to pick up where you left off," and the refresh wiped the DOM — so the founder's
  2026-07-03 mid-press door death left NO recoverable error class (terminal = caught exception,
  uvicorn logs access lines only; store = L-14 correctly refuses error text; browser = reloaded).
  L-24 ("read the error class first") is impossible when the product swallows the class.
  Prevention: (a) every terminal exception handler that surfaces-and-continues must
  `log.exception(...)` server-side first — the server log is not learner-facing, so L-13/L-14 do
  not apply to it; (b) the client wire gets a GENERIC honest nudge, never `repr(e)` — exception
  text can name frames/refs/paths, and "transient" is not a leak defense (screenshots, console
  copies); (c) when designing a recovery path (refresh/retry/reset), ask what evidence the
  recovery destroys and make sure a durable copy exists first.
- **L-26 Repo visibility: internal process docs and tooling config are never tracked, and the
  public `.gitignore` must not NAME what it hides.** Found by the founder on GitHub (2026-07-02):
  `.claude/`, `docs/DEVLOG.md`, `docs/lessons.md`, all superpowers specs/plans, and the admissions
  provenance were tracked — the specs describe the moat and the founder's business context — and
  worse, the tracked `.gitignore` listed the confidential documents' FILENAMES (Berkeley/
  FounderCEO/etc.), leaking the existence and nature of exactly what it existed to hide.
  Fixed @ a139f61: `git rm -r --cached .claude docs`; public `.gitignore` reduced to
  non-revealing generics (`/*.md`, `*.pdf`, `/docs/`, `.claude/`); the confidential-name patterns
  moved to `.git/info/exclude` (local-only, never uploaded). Prevention: (a) anything
  process-internal (session protocol, devlogs, lessons, specs, plans, provenance) lives under
  `docs/` or `.claude/` and those are ignored wholesale; (b) ignore patterns in the tracked file
  must be generic — a pattern that names a secret IS a leak; machine-local names belong in
  `.git/info/exclude`; (c) the pre-commit `git ls-files` guard stays, and gains
  `^docs/|^\.claude` to catch re-adds. Accepted trade (founder-directed): internal docs are now
  version-controlled NOWHERE — this machine is their only home (like SESSION_HANDOFF already
  was); a fresh clone has no lessons/DEVLOG/specs. History before a139f61 still contains them
  (private repo; founder deemed rewrite unnecessary for now).
- **L-28 A go/no-go report that projects a multi-axis gate onto a pass-bool misreads itself, and
  discards exactly the signal the gate exists to surface.** The frame-gen spike (2026-07-05) reported
  "10/20 lift"; the founder's read of the same rows showed the summary was hiding the finding.
  Collapsing the two-axis lift result (distinguishability + SIGNED preference) to `verdict=="lift"`
  hid that the distribution is BIMODAL — a clean pref=1.0 hard-lift cluster and a pref≈0.33 band
  indistinguishable from the mush control — and buried the DEPRECIATION frames (dist high, pref
  negative = the base model already does the move and fights the injection, the §12 signal the lift
  spec was rebuilt to keep) in the same "not-lift" bucket as INVISIBLE (dist≈0) frames. It also
  counted 2 errored runs (measured nothing) in the "20" denominator, and left the actual go
  criterion (novelty) a blank free-text column. Prevention: a report ABOUT a gate must carry every
  axis the gate keeps as its own column; exclude runs that produced no valid comparison (a
  manipulation-check failure or an error) from the denominator and mark them inconclusive; surface
  the per-scenario manipulation check (on an n=2–3 protocol a single un-expressed injection swings
  the aggregate); and make the go criterion a DEFINED check, not a judgment that gets weaker exactly
  as the case gets harder. Recomputed from the persisted per-scenario artifacts (no re-run needed —
  the machinery kept the axes; only the report projected them away): 9 hard-lift, ~5 hard-lift∧novel,
  0/8 mush hard-lift.
- **L-29 A screen's teeth are a property of (gate × problem distribution) — demonstrate the safety
  property in the regime the tool RUNS, not the flattering one.** The spike's 0/8 mush rejection was
  measured on problems NEAR the 5 curated territories (the center: pricing-vs-incumbent, staffing,
  IP-disclosure, regulatory-timing), where the gate is strongest AND the generator produces
  recognizably-sharp frames (it even rediscovered curated frames — proof the problems were
  center-of-distribution). But the live vision runs on UNFAMILIAR problems (the edge), where the
  generator can't reach for a move you'd recognize as sharp — it reaches for PLAUSIBLE, and
  plausible-but-not-necessary is exactly the boundary band the gate is weakest against (the same band
  the mush landed in). So the safety property was shown where it holds and the tool runs where it is
  thinnest — the identical shape as the Cartographer corpus-density guard (L-13 family: demonstrated
  where corpus is dense, runs where it is thin). Prevention: name the distribution a safety property
  was measured on; if the tool runs on a different distribution, the property is UNPROVEN there —
  spike the actual regime, and measure the GATE-LEAK (not the recall) in it, because the leak is
  where it fails.
- **L-30 The human-in-the-loop that made a result trustworthy is often invisible until you name the
  unsupervised claim.** Every gate in the frame-mining arc (SP1–SP3, the spike) kept the FOUNDER (or,
  in the spike, Felix) as the adjudicator who read the survivors and judged novelty. A "live for
  whatever the user walks in with" vision silently REMOVES that adjudicator, and no run in the arc
  tested the no-human condition. Prevention: when a vision claims automation, identify which human
  judgment each validating run actually relied on, and treat "the same mechanism, unsupervised" as a
  DISTINCT, untested claim that needs its own spike. Corollary (this session): the mapper-based
  novelty GATE (a defined confidence check that a move restates a curated move) is not a reporting
  nicety — it is the first mechanical piece of the no-human machinery, the replacement for the
  adjudicator's novelty judgment. FIRST OBSERVED RUN (2026-07-06, 9 hard-lift frames): the gate
  returned HIGH confidence on only 1/9 (the one clean restatement, correctly) and LOW confidence on
  8/9, with the verdict rule defaulting uncertainty to "novel" — a ONE-SIDED confidence (decisive
  only when it FINDS a restatement) that leaks toward OVER-admission on exactly the frames it is
  least sure about. So the first no-human piece is itself not yet trustworthy: it wobbles on the
  boundary the same way the lift screen does (L-29). Watch a gate's behavior on genuinely ambiguous
  cases before trusting it to decide unsupervised — a gate that cleanly separates the obvious and
  goes mute on the boundary has not earned the unsupervised role.
- **L-31 Relocating a spec-mandated invariant guard to dodge one caller's constraint silently un-guards the
  original site's OTHER callers.** The novelty-gate M2 plan (2026-07-07) had to place a partition-invariant guard
  (spec §3D/§5/§8: every HARD-LIFT row falls in exactly one of novel/convergent/uncertain). An unconditional
  `assert hard_lift == novel+convergent+uncertain` in `_summary` — the counting seam the spec named — would have
  CRASHED on the mush arm, whose HARD-LIFT rows are intentionally ungated (`verdict=None`). The plan's fix was to
  RELOCATE the guard: a per-row `assert verdict in (...)` inside `_apply_novelty_gate`. That protected the gated
  arm — but `_summary` has OTHER callers (the mush arm, hand-built/resumed rows), and for them the seam now had
  NO guard: a `verdict=None` hard-lift row counts in `hard_lift` but in none of the three buckets, silently
  under-summing (the exact L-28 hidden-bucket failure the guard existed to trip). The per-task reviews (each
  scoped to ONE commit) missed it — the T2 core-path review even praised the relocation as "sound placement";
  only the WHOLE-BRANCH review, seeing `_summary`'s full caller set, caught it. Prevention: when a spec mandates
  an invariant at a specific seam and you relocate the check to satisfy one awkward caller, do NOT delete it at
  the seam — REFORMULATE it into a shape EVERY caller can satisfy. Here: surface the dropped case as a
  first-class bucket (`hard_lift_unscored` = HARD-LIFT rows not in the three), so the row is COUNTED and visible
  (a gating drift in the gated arm shows up instead of hiding; the ungated mush arm reports it honestly) and the
  total partition `novel+convergent+uncertain+unscored == hard_lift` holds for gated AND ungated callers. A
  relocated guard protects one path; the seam it left still needs a form of the guard every caller can honor.
  (Corollary: a per-task review scoped to one commit cannot see a shared function's full caller set — this class
  is the whole-branch review's job, and catching it there before merge is the review earning its keep.)
- **L-32 An overloaded column/timestamp — one field serving two purposes with different preconditions — breaks
  silently when a writer bumps it for purpose A outside purpose B's precondition; and the bugs that hide in the
  seams BETWEEN a new feature and the older machinery are found by a post-merge cross-arc adversarial hunt, not by
  the feature's own per-diff review.** `web_sitting.updated_at` served TWO masters: the 18h idle-reaper heartbeat
  (bumped on every activity — `append_turn`, and the Phase-3 `reopen_sitting` re-entry stamp) AND the homebase
  selector `_latest_landed_record` (which read it as a proxy for "the most cumulative frozen LANDING"). Those two
  meanings agreed only while "most recently touched" == "most recently landed" — true until re-entry (or any
  turn/converse on an older saga) bumped `updated_at` without a new landing, promoting a stale, smaller record and
  making newer sagas' houses VANISH from the world. Three cross-arc bugs of this shape (the overloaded column; a
  cause inferred from `ch is None` that a new state violated; a label recomputed without consulting a surviving
  steer) all sat in the interaction between Phase-3 re-entry and the durable-sitting/steer/homebase machinery —
  each whole-branch-clean on its own diff. Prevention: (a) when a column encodes a fact two subsystems read
  differently, give each its OWN column (here: `landed_at` stamped only at genuine terrain-freezing landings,
  immune to reaper/turn/reopen bumps) rather than overloading one — and when you add such a decoupling column,
  BACKFILL existing rows at migration time or the fix is inert on real data until it churns (two review lenses
  caught the missing backfill); (b) after merging a feature that threads through older machinery, run an explicit
  cross-arc hunt (diverse lenses over each feature×subsystem seam, every candidate reproduced by an offline probe
  before it counts) — it finds the interaction bugs the feature's own reviews structurally cannot, and reproduced
  bugs convert directly into failing regression tests. (Also re-confirmed L-23: run pytest and `git commit` as
  ONE gated chain — separate lines let a red suite commit; I amended forward.)
- **L-33 A guard's SCOPE is part of the guard, and a guard whose assertion the code satisfies by
  accident has no teeth.** Three instances in one session, all in the same file. (a) The helper that
  extracts a nested `def` for the structural guards measured the base indent from the `def` KEYWORD
  rather than from the start of its line, so every nested def looked top-level and each "decide()
  body" extraction ran to end-of-file — 117,959 characters instead of 22,173. Nothing failed for
  weeks; the guards passed for reasons outside the function they guarded, and it surfaced only when
  a refactor let one of them match a `map_territories(` call 63,254 characters away. (b)
  `test_agreement_never_rewrites_the_world` scopes its scan to the region ABOVE the confirm loop's
  affirmative break, which is exactly right for the defect it was written for and structurally
  blind to a NEW park added BELOW it — so a change that re-introduced the very same
  world-destroying assignment one beat lower passed it. (c)
  `test_gap_is_logged_only_when_the_correction_still_does_not_fit` asserts `"verdict" in seg and
  "confidence" in seg`, which the call it is guarding satisfies with its own kwargs
  (`log_content_gap(confidence=…, verdict=…)`), so deleting the entire condition it exists to pin
  still passes. Prevention: (i) assert on the EXTRACTION, not just on what you find inside it — a
  guard that can silently widen its own region is not bounded; (ii) when you add a branch or a park
  to a loop some guard protects, re-derive that guard's region before assuming you inherited its
  protection, because a scoped guard protects a scope and not a property; (iii) mutate every new
  static guard the moment you write it, and prefer a runtime test whenever the property is
  observable at the surface — three of the four holes here were static guards, and the runtime
  tests that replaced them bite mutations the static ones never could.
