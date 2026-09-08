# Elenchus handover: the working notes

For Riyan. Read `2026-09-06-elenchus-environment.md` (env vars, key resolution, the two-entrypoint asymmetry) and `2026-09-06-riyan-onboarding.md` (install, the eight gate checks, tiers, invariants) first. This document does not repeat either. It is the things they do not say, measured on this machine on 2026-09-08 with the command output beside each claim.

Where the material I worked from disagreed with itself, I say so and give both sides. Confidence labels follow the constitution: **verified** (I ran it, output below), **read** (I read the code, did not run it).

---

## 1. Integration, in order

Two things before anything else, because two later steps degrade silently without them:

```
command -v claude gh ; gh auth status
```

`claude` missing makes `felix install` leave you a working CLI and ungoverned sessions (`engine/harness/felix:325` tests for it *after* `:288` has already written `~/.felix-home`). `gh` missing pins the `baseline` commissioning row at `unknown` forever: its instrument column is literally `gh` (`projects/elenchus/commissioning.tsv`, row `baseline`), and any `unknown` row makes the receipt indeterminate, which blocks `felix merge`. Neither is on this box; `gh` is the one to install.

Then, in this order. The published runbook puts the bundle before the venv; do it the other way so every check between here and step 8 means something.

| # | Command | Check that it worked |
|---|---|---|
| 1 | `git clone https://github.com/LeavesJ/Elenchus.git && cd Elenchus` | `git remote get-url origin` names `LeavesJ`. A fork binds to nothing, silently. |
| 2 | `python3.14 -m venv .venv && .venv/bin/pip install -e ".[dev,web]" "ruff==0.16.0" "pytest==9.1.1"` | `pip list \| grep ruff` says 0.16.0. See the disagreement below. |
| 3 | `PYTHONPATH=src .venv/bin/pytest -q` | `1439 passed, 35 skipped`. Record it. This number moves later on its own; §5 says when. |
| 4 | `/path/to/bundle/restore.sh` run from inside the checkout, **not piped** | last line `structure matches` |
| 5 | manifest check (there is no manifest; build one, §7) | |
| 6 | `$EDITOR ~/.config/elenchus/env` then `grep -c paste-your-key-here "$(readlink -f .env)"` | must print `0`. `restore.sh:122` writes a non-empty placeholder, and every key check in the tree accepts it. §5. |
| 7 | `git clone git@github.com:LeavesJ/felix.git ~/felix && cd ~/felix && ./engine/harness/felix install --home ~/felix` | ends `verified   the installed engine matches this tree`; then `claude plugin list` against `grep '"version"' ~/felix/engine/.claude-plugin/plugin.json` |
| 8 | `cd <Elenchus>; ~/felix/engine/harness/felix which; echo $?` | `0`. If it refuses, read the last line: `Known projects:` **empty** means the home did not resolve; `Known projects: elenchus felix veldra` means the home is fine and your `origin` is wrong. That one line settles what the onboarding doc has you test twice. |
| 9 | new Claude Code session in the checkout | banner line `Felix: elenchus`. Its absence is the only tell that your session is ungoverned, and absence is hard to notice. |
| 10 | `~/felix/engine/harness/felix gate` | `gate: pass`, `secret ok` (not `skipped`), `probes ok`. **`gate: pass` is not the last line**, §3. |
| 11 | lessons mount check, below | non-empty output |
| 12 | `bash ~/felix/projects/elenchus/prepush.sh` before your first push | `self-test: PASS` on `--self-test`; on a real range see §3 |
| 13 | `felix commission` after your first real gate failure | §3 |

**Step 11, the lessons mount.** `restore.sh` seeds J's `lessons.md` into `~/.felix/memory/elenchus/` and symlinks `docs/lessons.md` at it. That is what makes the 252 `L-nn` code comments resolve. The mount at `engine/harness/hooks/user-prompt:191` reads `$(felix_mem_dir "$PROJ")/lessons.md`, and the selector only starts an entry on a line matching `/^- \*\*/` (`engine/harness/lib/lessons.sh:23-24`, verified by reading the awk). A heading-shaped lessons file mounts nothing, forever, and looks exactly like "no lesson was relevant".

```
. ~/felix/engine/harness/lib/lessons.sh
felix_lessons_for ~/.felix/memory/elenchus/lessons.md "pytest venv editable install gate" 4
```

Empty output means the mount is dead.

**Also step 4, worth knowing before it confuses you.** `restore.sh:143-159` unconditionally moves J's `lessons.md`, `DEVLOG.md` and `SESSION_HANDOFF.md` into your memory root and symlinks `docs/` at them. The onboarding doc §8 presents the same arrangement as your choice and tells you to ask J first. The script wins; by the time you read the offer it is done. It is the right default. If you want separation, act between step 4 and step 9, before your first `felix lesson` write.

---

## 2. What you own, ML first

### 2.1 The measurement surfaces

This is the half of the codebase where you outrank the author, and it is also the half with the least verification. Everything here is one draw from one model with no measured variance.

**`scripts/model_breakpoint.py` is a finished harness missing two model calls.** Live mode is `print("live mode is not wired yet"); return 2` at `:213`. What is already built and works: the sitting driver runs through the real `SessionRegistry` serving path, a nonce-fenced judge prompt (`:65`, a per-call `secrets.token_hex(8)` so a transcript turn cannot forge the closing marker), a strict verdict parser using `[0-9]` not `\d` because a red team got an Arabic-Indic "٨٧" coerced into a recorded score, and the ladder at `:47`. Both prompts are tracked: `content/eval/student_sim.md` and `content/eval/judge.md`. Missing: the student-sim reply loop and the judge dispatch.

Verified, 0.5s, no key:

```
$ PYTHONPATH=src .venv/bin/python scripts/model_breakpoint.py --dry-run | tail -6
  "converged": true,
  "mechanical": { "leaks": [] },
  "judge": null,
  "distribution": "student-scripted-v0",
  "content_version": "cv-8e8b588077cab85e"
```

Note `"leaks": []` next to `"judge": null`. The only leak signal that runs today is `mechanical_leak_scan` (`:89-104`), which matches the literal snake_case identifier in engine-authored turns; its own docstring calls it "a code-constant-leak tripwire, NOT a real leak floor (red team F4)". That zero will get quoted as "no doctrine leaks". Until the judge is wired, a green breakpoint row means the plumbing carried a sitting end to end and nothing about doctrine. This is the highest-leverage single build available to you, and it is the instrument every other measurement here can ride.

**The blind sharper audit is same-model, one vote, revoke-only.** `audit_sharper` (`src/elenchus/assessment/sharper_grader.py:76-91`) calls `model.grade_sharper` once per credited frame on the same model object the instructor used; `disputed` can only remove codes from `frames_closed_under_pressure` and drop their `FrameDelta`. There is no path that grants credit the instructor withheld. The auditor prompt says "Default to sharper=false when no mechanism is clearly cited" (`content/prompts/grade_sharper.md:22`). The two votes in the docstring's "blind 2-vote audit" are instructor and auditor, not two auditors. Correlated errors plus a conservative auditor plus one-sided revocation deflates `evidence_count`, which is the sole input to `_storage_tier` → `Strength` → `derive_due`.

And the disagreement rate, the single best grader-reliability signal this system can produce, is computed on every sitting and discarded. Verified:

```
$ git grep -n sharper_audit -- src
src/elenchus/assessment/sharper_grader.py:10, :96
src/elenchus/types.py:249, :310
```

Nothing in `web/` or `persistence.py` reads it. The sibling field on the same object *is* persisted, four lines of loop at `web/session_runner.py:1369-1370` via `add_gate_rejection`. Persisting `sharper_audit` beside it is the cheapest real dataset in the repo, and it has to happen before the thirty invitations go out or the transcripts that would have carried it are gone.

**Lift is a single-draw, single-rater preference test that scores a refusing control as a clean lift.** `run_lift_test` (`src/elenchus/lift_test.py:31-45`) gates aggregation on `ie.expressed` only. `ScenarioVerdict` stores `framed_refused` and `control_refused` (`types.py:501-502`) and `status()` (`types.py:504-513`, read) never looks at either. `generate_output` returns empty text with `refused=True` rather than raising, so the rater is handed a blank Output B and prefers the non-blank side. The injection scorer has exactly this guard, first in fixed precedence: `refusal_minimum` at `injection_scoring.py:200-206`, whose comment names it "a false-pass path". The lift path has no equivalent. Symptom: a candidate frame near a safety boundary reads HARD-LIFT, passes the novelty gate, comes out an auto-go candidate whose entire effect was that the control refused, and nothing in the report flags it. One line in `run_lift_test` fixes it.

**The spike overrides its own config file and it changes the headline count.** `frame_gen_spike.py:325` is `config = {"theta_dist": 1, "min_scenarios": 2}`. `content/lift/lift.yaml` says `min_scenarios: 3` (verified, both read directly). `_categorize` (`frame_gen_spike.py:86`) awards HARD-LIFT only when `not result.below_floor`, and `below_floor` is `len(valid) < min_scenarios`. Three scenarios with one inconclusive: under the hardcode that row is HARD-LIFT, under the doctrine file it is `lift(below_floor n=2)` and excluded. Doctrine-as-data is Invariant 1 and this is a live violation with a numeric consequence.

**The injection probe is rigorous and underpowered, and has a named unfixed defect.** With `MIN_SCORABLE=5` and `ALPHA=0.05`, k=5 unanimous gives p=0.03125, the only significant outcome out of 32 sign assignments; one discordant payload at k=5 gives 0.1875. At the floor the test is "all five agree or nothing". More draws per cell buy nothing because k is over payloads. D3 (`injection_scoring.py:337-351`) is stated in the code: `Draw` drops `mechanism_span`, so a verdict where `classify_response`'s evidence-anchor floor rejected a fabricated span is byte-identical to an honest no-mechanism, and `landed()` counts the floored one as a landing. `classify_response` already returns the span. The run has never been executed.

**Every threshold was set by one person in one sitting before any data existed.** `MIN_SCORABLE = 5` landed 919cefe 2026-08-03; `theta_dist: 1`, `min_angle_count: 8` and the policy weights `wU/wR/wT/wL = 1.0/1.0/1.5/0.5` all landed in commit da22174 on 2026-08-02, sole author. The files say so themselves: `content/gate/depth.yaml` reads "User-set floor (no corpus basis)" (verified, it is a four-line file), `content/lift/lift.yaml` says "Dogfood-tunable". You do not need permission to move these, you need data. `SelectionReceipt` already records every term, the drive, the runner-up drive and the margin for each candidate the policy scores; check whether it is persisted before assuming.

**The advertised interrogation depth of 8 angles is arithmetic, not behaviour.** `angle_count = frames + traps + binding + ARTIFACT_DIMENSIONS`, and `ARTIFACT_DIMENSIONS = 4` (`src/elenchus/generator.py:15-16,25-27`, verified) is a bare constant: rigor, completeness, internal consistency, defensible assumptions appear nowhere else in the repo. No prompt, no code path, no test probes them. Meanwhile `_select_target` (`assessment/judgment_loop.py:168-192`, verified) skips `exhausted` codes and skips frames already `present_reasoned`, so every code is pushed at most once and `MAX_PUSHES = 8` (`:18`) is unreachable. A reader swept 34,992 real `assess` runs and found 0 repeated target codes, 0 budget stops, max trajectory 6. If you want deeper sittings the change is in `_select_target`, not in the cap.

### 2.2 Probes: what you can actually run

| Probe | Runnable today | Price | Blocker |
|---|---|---|---|
| push_screen | yes, with a caveat | 94 calls flat | positions pool |
| injection | yes if you get the payload corpus | 180 sched / up to 360 billed on the real corpus; 15/30 on the tracked stub | `data/injection_payloads.yaml` |
| prompt_shift | **no** | schedules 0 calls and writes a result anyway | needs `data/elenchus.db` learner turns |

Verified on this checkout:

```
$ PYTHONPATH=src .venv/bin/python -c "...build_cases..."
open_ended experiences: 8
cases: 94
Counter({'blind': 47, 'positioned': 47})
```

`build_cases` (`src/elenchus/push_screen_probe.py:64-69`) doubles every push target into a blind arm and a positioned arm. `sample_positions([])` returns an empty `Positions()` (`:77-78`) and `read_learner_turns` returns `[]` for an absent db, so with no database the two arms compose byte-identical prompts. The run still prices and spends all 94 calls and writes 47 records labelled `position_mode="positioned"` with no positions in them. The only tell is one stdout line at `run_push_screen_probe.py:99-101` and a `corpus_source: empty_fallback` field. Read that field on every probe artifact before quoting a rate off it.

That probe also answers a question J explicitly left open. `_push_label_leak`'s docstring (`assessment/judgment_loop.py:92-108`) records that both bars rejected 0 of 64 real `generate_push` outputs and ends "Whether to simply restore the full bar on the push path is open and unresolved here, a question for the founder." The 64 was five rubrics; three more shipped 2026-09-02, so the bar is unproven on 3 of 8. A full re-run is 94 calls with checkpointing and a typed cost confirmation. Cheapest real measurement available to you, and the answer is a doctrine call you are qualified to make.

Probe 2 is structurally dead on your machine: both corpora come from `data/elenchus.db` (`run_prompt_shift_probe.py:203,208`), and with none present it computes `n_calls=0` and still offers you the confirm prompt "about to make 0 real Anthropic API call(s)". A fast, free, apparently successful run with an empty denominator.

### 2.3 The one dormant half, so you do not read it

`ASSESSORS` is regime-split (`assessment/__init__.py:8-11`) but `web/session_runner.py:1360` hardcodes `regime=Regime.open_ended` and nothing in `web/` references `cs_technical`. `checkable_scorer.assess`, `model.grade_answer`, `state.update_state_checkable` and both files under `content/checkables/` are reachable only through the CLI. It looks like half the grading system. The live grading path is `judgment_loop` → `classify_response` → `grade_sharper`.

### 2.4 Content, if you author rubrics

Adding a territory is four files, two of them tests, measured by a reader on a clean tree: `content/rubrics/<eid>.yaml`, `content/territories/<eid>.md`, `tests/test_forge.py:113` PINNED_DECISION_FRAMES, and re-pinning `tests/test_sp3_progression.py:200-205`. No map edit, no DB edit. The receipt is a number: 1439 + 2.

Three authoring constraints that only fail at runtime or in an unrelated file:

- `paired_trap` is unvalidated. Pydantic ignores unknown keys, so `paried_trap:` silently yields `paired_trap=None`, the value is interpolated into the graded system prompt at `model.py:353`, grading gets quietly worse, suite green (`types.py:88-92`, read).
- `role:` is a free string (`content_loader.py:128`, read) and `web/voice.py:282` does `content/voice/role_{role}.md`.read_text(). A bad role fails 16 tests in `test_web_api.py` and `test_session_runner.py` asserting `'error' == 'say'`, with the `FileNotFoundError` buried. `load_theme` degrades silently for a missing theme; `load_role_text` raises.
- Frame codes and trap codes are unique across kinds *by accident*. `judgment_loop._group_positions` says so in its own comment: a trap code matching a frame code puts a trap position in `on_angle` and tells the stress author it was the reasoned engagement with this angle, silently. Current margin: 5 distinct frame codes against 14 hand-grown trap codes. `content_loader.py:166` already calls `_reject_duplicate_ledger_refs` at the load chokepoint; the cross-kind assertion belongs beside it and is probably the cheapest real risk reduction in the tree.

---

## 3. The dev loop

**`felix gate --quick` exists and nothing documents it where you can reach it.** `cmd_gate` passes `"$@"` straight through to the project gate (`engine/harness/felix:503`), `gate.sh:38-44` parses `--quick`, `:123-124` prints `test  skipped (--quick)`. But the dispatcher intercepts `--help` on `$2` (`engine/harness/felix:4044`) so `felix gate --help` prints Felix's usage and never reaches `gate.sh`. Verified, this checkout:

```
$ time felix gate --quick
  format ok / lint ok / test skipped (--quick) / confidential ok / secret ok
  lift-bank ok / ignore-leak ok / inversion ok
gate: pass
  probes ok
  commission never commissioned on this machine
real 0m1.369s
```

Full gate on the same tree: 78s, of which the suite is 71.

**Disputed, and both sides are right.** One reader calls `--quick` the whole inner loop; another calls it a trap, because the verdict word is `pass` and nothing in that line says the suite was skipped (`gate.sh:210-213`). The receipt records the skip in field 5 (`lib/verify.sh:208`), the merge boundary reads only fields 1 and 2 (`lib/escape.sh:338`), and the Stop hook is the only reader of field 5 and only softens a sentence. So: run it constantly, never quote its last line as evidence of a green suite, and run the full gate before you claim done.

Timings, all verified on this box (4 cores):

| Command | Time |
|---|---|
| `felix classify` | 0.10s |
| `felix evidence` | 0.09s |
| `felix gate --quick` | 1.37s |
| `pytest tests/test_voice.py` (71 tests) | 0.13s |
| full suite minus the four heavy files (1187 tests) | 10.6s |
| full suite | 70.7s |
| full suite `-n 4` | 22.4s |
| `tests/test_session_runner.py` alone (170 tests) | 35.6s |

The suite is 96% of the gate. `pytest-xdist` is not in `pyproject.toml`; installing it into `.venv` alone touches no tracked file and is not an escape. `gate.sh:126` runs a bare `pytest -q`, so `PYTEST_ADDOPTS="-n 4" felix gate` works and drops the gate to about 25s. The caveat is real: `PYTEST_ADDOPTS` applies to every pytest in that shell, so putting `-m "not live"` or `-x` in there changes what a green gate means in a variable nobody reads.

Half the serial suite is one uncached glob. Verified: `load_library` has no `lru_cache` (`content_loader.py:162`), costs 15.26 ms per call here, and `session_runner.py` alone calls it 12 times. A reader instrumented a full run at 2,314 calls for 36.8s. Do not patch a cache into `content_loader` casually: today you can edit `content/*.yaml` against a running server and the next request picks it up, so caching trades live reload for speed and is a T2 doctrine-surface change. The zero-risk version is an out-of-tree pytest plugin loaded with `-p`, which leaves the gate measuring the real cost.

**Red is advice. The channel is the stop.** `lib/escape.sh:1-14` says it outright: "Empty output means nothing escaped and Felix may merge." Verified against `projects/elenchus/risk.tsv`: `src/elenchus/(types|orchestration).py` is `red` with **no channel column**, so it produces no escape and merges. Only four things actually stop a merge: `persistence.py` (channel `durable`), `assessment/judgment_loop.py` and `content/(maps|rubrics)/` (channel `reviewed`), `pyproject.toml` (channel `verifier`). And `felix review --pass` clears `reviewed` and nothing else (`lib/review.sh:27-28`, verified) so `durable` is permanently a J decision. You will otherwise self-censor on `types.py`, which is free, while assuming a review can clear `persistence.py`, which it cannot.

A pyproject version bump is free; adding a dependency is not. The row carries a confine regex and `_felix_escape_confined` additionally requires the package name sets on both sides of the hunk to be identical, so `pyyaml>=6.0.3` → `>=6.0.4` produces no escape and a new `httpx` line produces `verifier  pyproject.toml  a manifest also configures the gate`.

**`felix evidence` cannot see an untracked file.** `felix_changed_paths` unions the base diff with `git diff` and `git diff --cached`; none enumerates untracked files. The symptom is Felix insisting you owe a test while the test file is open in front of you. `git add` it. Also: `felix evidence` exits 0 and is advisory, but every `gap` row is a hard blocker inside `felix_merge_blockers`, so read it as a preview of a merge refusal. Note `evidence.tsv:7` covers only `^content/(maps|rubrics)/` of fourteen content directories, and it fires at merge, not at the gate, so your first rubric edit without a test passes `felix gate` and refuses at `felix merge`.

**`prepush.sh` is the only guard on a public repo and nothing references it.** Verified: `git ls-files | grep prepush` in Elenchus is empty, and `grep -rn prepush ~/felix/engine/` hits only Felix's own test fixtures, never a command. It checks five things `felix gate` does not: no `Co-Authored-By` trailer in the range (`:134`, which is the one constitution rule nothing else enforces, and Claude Code adds that trailer by default), no absolute local path in added lines (`:120`), no private-context term (`:125`), `.gitignore` unchanged in the range (`:100`), new files joining the tracked set (`:107`). Its confidential list is wider than the gate's: it adds `^data/`, `^\.env`, `^\.superpowers` (`:93`). Warning you will need on day one: the private-context list at `:125` includes `riyan`, so a `# TODO(riyan):` you wrote thirty seconds earlier fails the guard I am telling you to run. It is working as designed; the list was written when the private surface was one person.

One more use for it: `prepush.sh:140` runs `pytest -q -m "not live"` where `gate.sh:126` runs a bare `pytest -q`. So in a shell that has your key exported, prepush is the verification command that stays free.

**Small things worth knowing.** `felix log` appends to `~/.felix/memory/elenchus/DEVLOG.md`, outside the checkout, which resolves the onboarding doc's "impossible taken literally" DEVLOG rule without you hand-editing a frozen snapshot. `felix route --ack "why it does not fit"` is the third option on a routing mandate; the engine's own comment records 11 mandates in five days, 2 followed, and every one audited live being wrong for its turn. `FELIX_ALLOW_RED=1` is read from the environment the session launched in, so exporting it inside a Bash tool call reaches that subprocess and not the already-running hook parent, and it looks like the override is broken. After `git pull` in the Felix clone, every project table (`gate.sh`, `risk.tsv`, `deny.tsv`, `probes.tsv`) is live in the session you are already sitting in; only engine logic waits for `felix install` and a new session.

**Commission.** `gate_shown_failing` (`commissioning.tsv`) requires a recorded gate failure that was not probes or commission, so on a fresh machine it sits at `held` and stays there until you break something real. `held` is a valid state and blocks nothing. `unknown` is the one that blocks, and `baseline`'s instrument is `gh`. So: install `gh`, run `felix commission` once, and stop reading `held` as broken. Also note the receipt hashes eleven project tables plus `felix_detect`'s output over your checkout, so a `git pull` in the Felix clone, or your own branch adding a first `.env.example` or Dockerfile, invalidates it and produces a merge refusal that has nothing to do with your work. Re-run commission, 13 seconds.

---

## 4. Spend

**`ELENCHUS_MAX_CALLS` bounds one process and nothing else.** Verified:

```
$ git grep -n 'AnthropicModel(' -- src scripts
cli.py:92 / frame_gen_spike.py:324 / run_elicitation.py:38
run_injection_probe.py:293 / run_prompt_shift_probe.py:229 / run_push_screen_probe.py:110
web/app.py:97          <- the only one with budget=
```

`web/app.py:69-99` mints the Budget once and closes the factory over it. `AnthropicModel._budget = None` is the class default, so unbudgeted is the default state, and `pytest -m live` builds its own unbudgeted model per test. Every command you would run to evaluate the product is outside the ceiling. **The ceiling that covers all of it is the spend limit on your own workspace key.** Set that before your first live anything; it is the real reason §3.4 of the onboarding says use your own key.

Also verified, and it matters for the probes: `web/app.py` never names `ELENCHUS_MAX_CALLS` in code. The only occurrence in that file is a docstring sentence at `:84`. Felix's `ceiling_site` probe is `git grep -l ELENCHUS_MAX_CALLS -- scripts src` (`projects/elenchus/probes.tsv:29`), which reports `3 found` and counts `web/app.py` on the strength of that sentence. Reword the docstring and the enumeration silently drops to two with no red gate.

Per-sitting cost, measured by a reader on the real serving path with a world fake: 16 model calls for a 4-step converged sitting, of which **6 are `screen_moves`**, more than grading and push generation combined. Two readers describe this as "4 calls per learner step" and as "the egress screen is 38% of the bill"; same measurement, and both framings are useful. `spend.py:23-26` sizes the 500 default on "16 turns at ~6 calls per turn". So screen efficiency is the cost lever, not model choice. The screen already runs at `_MED_PARAMS` while everything else is `_PARAMS` = adaptive thinking + `effort=high` (`model.py:282,290`), and that comment records the measurement: medium took the screen 3.6s to 2.5s, while lowering effort on the simple calls "buys nothing and slightly hurts". Thinking tokens bill as output, so a call ceiling bounds cost only to within the factor `_PARAMS` sets.

Three live entrypoints ask you nothing. The three probes each require a typed `yes` at a real `input()`, chosen over a CLI flag so it cannot be replayed by habit. `frame_gen_spike.main()` (`:324`), `run_elicitation.main()` (`:50`) and `cli.main()` (`:92`) have no confirm and no budget. `cli.main` is the installed `elenchus` console script (`pyproject.toml:47`), so a one-word command on your PATH is an unbounded interactive Opus session against the default DB. `frame_gen_spike` is roughly 370 calls at effort=high, and the count is set by model output rather than config: the prompts ask for 4 frames and 3 scenarios but neither `_FramesWire` nor `_ScenariosWire` caps the list. Do not run it to see what it does.

Retries are charged before dispatch and a call that raises is still charged (`model.py:677-694`), which is why the probe confirms pass `max_calls=2 * len(schedule)`. The SDK's own retries happen below that choke point (no `max_retries` set at `model.py:743`), so one `model_call` log line can cover up to three HTTP requests (`call_log.py:180`). No probe resumes: `run_injection_probe.run`'s docstring at `:315` says the next call draws and prices a fresh schedule and the checkpoint is kept for its data, not consumed. With `DEFAULT_SEED` fixed, a probe that dies at cell 170 of 180 costs a full 180 to finish. Merge the checkpoint JSONL by hand or change the seed.

The safe sweep order: workspace spend limit first; `unset ANTHROPIC_API_KEY` in your gating shell and confirm the suite still reports the expected skips; `model_breakpoint --dry-run` (free); then in a separate keyed shell `pytest -m live -x`, which is 31 tests and at least 58 dispatches before assertions abort them, so `-x` matters; then probes one at a time, doubling any confirm figure that names a max.

Local audit after the fact: `python -m elenchus.web` owns its logging config specifically so the `model_call` timing lines survive (`web/__main__.py:20`), and `scripts/call_report.py` reads a `<root>/<slug>/server.log` layout. `mkdir -p /tmp/spend/local`, redirect stderr there, run the report. It distinguishes the per-process ceiling refusing a call from Anthropic's classifier declining, and its footer enumerates four reasons a refusal *rate* is not computable from the log.

---

## 5. What breaks quietly

Symptom first.

**"preflight is green, health is green, and every door 500s on the first click."** `restore.sh:122` writes `ANTHROPIC_API_KEY=paste-your-key-here`, and `resolve_key`'s test is `if val:`. A reader ran preflight against that state and against `sk-ant-fake123` and got byte-identical `[ok] key-reachable`. The environment doc names `key_reachable` as the axis that answers §4 directly; it answers "is there a non-empty string". Grep the placeholder out yourself, step 6.

**"the suite count changed and I did not touch anything."** Verified on this checkout, which has a `data/elenchus.db` and no `docs/`:

```
$ PYTHONPATH=src .venv/bin/pytest -q | tail -1
1441 passed, 33 skipped, 2 warnings in 70.67s
```

The onboarding doc says "35 is your number before and after unpacking" and "those four stay skipped for you, permanently". That is true only while no database exists. Both `test_generator.py` skips gate on `Path("data/elenchus.db").exists()` (`:534`, `:552`), and `cli.build_store` creates that file on your first `python -m elenchus.web` or `elenchus` run. So the count moves to 1441/33 on its own. Worse, those two flip from honest skips to vacuous passes: `test_seed_ledger_refs_resolve_in_the_real_corpus` asserts only that `entry.unlabeled.strip()` is non-empty, and what `build_store` writes is the 37-character placeholder. Verified by dumping the db here: `corpus` 8 rows, `ledger` 8 rows, every one `provenance='seed'`, `unlabeled='genuinely unlabeled (abstracted seed)'`, and all six other tables at 0.

**"the vessel surface shows zero and I cannot find the bug."** There is no bug. `web/vessels.py:26-27` skips every row whose provenance is `seed`. Verified: `vessel_count('data/elenchus.db')` returns `0` on this machine. Same root cause: without a real corpus you have placeholder rows.

**"my wording fix did not ship."** `experience._attach_scene` (`src/elenchus/experience.py:26-39`, verified) looks up the corpus row by `ledger_ref` and, when it carries a `scene`, returns `exp.model_copy(update={"prompt": entry.scene.prompt, ...})`. On J's instance the served stimulus for a seeded territory comes from the database, not from `content/rubrics/X.yaml`'s `prompt:`. On yours it falls back to the file. You will edit the rubric, see it change locally, and it will not change on his. The same gap means `validate_scene`, the framework/scaffold denylist check Invariant 3 rests on, never runs on any production path on your machine.

**"a green test that proves nothing."** `sitting_store.py:184` sets `self._inert = db_path == ":memory:"` and every read and write returns early. Eighteen test sites use `":memory:"`, and the copy-paste form is `TestClient(create_app(db_path=":memory:", ...))`. Any assertion shaped "after X, the store holds Y" passes vacuously, because `converged_log() == []` is true when nothing was ever written. Use `tmp_path` for anything touching persistence.

**"the feature works all session and is gone after the reload I did to check it."** `_serialize_record` (`session_runner.py:637-668`) and `_rebuild` (`:1753-1815`) are two hand-maintained parallel key lists with no test pinning that they correspond. `_rebuild` returns the in-memory `_last_record` cache first (`:1761-1763`), so a field missing from the allowlist survives in-process and is dropped by the very next `converse`/`close` re-serialization. The comments at `:1403` and `:1796` say this was already paid for once, for `pushes`.

**"all eight checks ok, `gate: FAIL (probes)`, one blind row, no traceback."** `gate.sh:51-57` falls back to the main checkout's `.venv` when a worktree has none. `probes.tsv:29` has no such fallback, and `probes.sh:250` runs every probe with `2>/dev/null`. So a worktree without a `.venv` symlink gives a `ModuleNotFoundError: No module named 'fastapi'` you never see, while the witness `test -f src/elenchus/web/app.py` still succeeds, which is exactly `blind`. T2 doctrine puts you in an isolated worktree, so this is the first thing that happens the first time you do it properly. `ln -s <main-checkout>/.venv .venv` in the worktree.

**"`felix gate | tail -1` says something wrong."** `cmd_gate` runs the project gate, which prints its own verdict, then appends probes and commission lines below it, and on a probe failure prints a corrected `gate: FAIL (probes)` (`engine/harness/felix:539-570`). Branch on the exit status. Same family, non-pytest: `scripts/preflight.py --repo . | head -40` reported exit 0 to a reader while the unpiped run exits 1 with three FAIL axes. L-23 is not pytest-specific.

**"a phantom misfile after restore."** `git status --short --untracked-files=all` shows `?? data` after a correct restore, permanently. `restore.sh:112` replaces `data/` with a symlink, and `.gitignore:13` is `/data/` with a trailing slash, which matches directories only. The gate is unaffected because `gate.sh:200` filters `^??`. The onboarding checklist item "shows none of it" is wrong about this one path.

**"the breakpoint eval is measuring a model we do not ship."** The onboarding doc says a model change is one line for the product and four for the tree. Verified, it is five:

```
$ git grep -n 'claude-opus-5' -- src scripts   # excluding comments
model.py:727, run_injection_probe.py:79, run_prompt_shift_probe.py:55,
run_push_screen_probe.py:38, scripts/model_breakpoint.py:47   <- the LADDER
```

Whose own comment says "Walk DOWN from what production serves today; a ladder starting anywhere else measures a product nobody ships."

**Latent, and it is the worst failure this product has.** `sitting_store.py:60-77` documents an off-by-one it cannot fix: two `session_runner` paths break the landing-to-convergence-row correspondence in opposite directions, and both in the same sitting cancel out, so the `len(chosen) == len(rows)` guard passes and `zip(rows, chosen)` pairs every convergence with the wrong landing. Output is a memory that opens to the words of an arc the user abandoned, presented as a faithful record. The stated blocker is that `web_sitting_turn` has no timestamp column to re-anchor on. Adding one is T2/T3, so a conversation with J.

**Traps in Felix's own tables.** `deny.tsv` is four rows, all `Bash`, and none of them covers `git commit -a` or `-am`, which stages every tracked modification and produces exactly what the `git add -A` row exists to prevent. And the gate's `confidential` regex (`gate.sh:145`) matches the bare substrings `brief`, `judgmentloop`, `lifttest`, `founderceo`: `content/prompts/debrief.md` and `content/territories/board_briefing.md` both match, and the gate will tell you to `git rm --cached` a file you just authored.

**One that nobody has fixed.** The gate's lift-bank check greps only `content/lift/(scenarios|candidates)\.yaml$` (`gate.sh:175`) and `.gitignore` names only those two paths. The injection stub lives at `content/gate/injection_payloads.example.yaml` while the real corpus lives at `data/injection_payloads.yaml`. `git check-ignore content/gate/injection_payloads.yaml` says not ignored. Anyone following the lift convention (stub beside real bank, same directory) publishes working exploits against our own grader to a public repo with `gate: pass`. One line in `.gitignore` plus one in `gate.sh`, and it is a request to J.

---

## 6. Disagreements worth your own judgment

**ruff.** The onboarding doc pins `ruff==0.16.0`. This venv has 0.16.6 (verified, `pip list`), and CI installs 0.16.0 (`.github/workflows/gate.yml:90`). One reader calls this a live divergence about to surface as "Riyan's environment is wrong"; another checked both versions against this tree and got `169 files already formatted` and `All checks passed!` from each, so they agree today. `[tool.ruff.lint] select` pins the rule set explicitly, which protects `lint`; `ruff format` behaviour is not pinned by that and the `format` check both rewrites files and decides the exit code. Install the pin, and if you and J ever disagree on a format, check versions before anything else.

**`data/`.** The onboarding doc says `data/` never travels, and for `data/elenchus.db`'s sitting tables and `data/tenants/*` that is settled and permanent. Three readers argue independently that the *seed* is a different thing: `data/seed/veldra_ledger.yaml` is the declared input to `elenchus-ingest`, a shipped public console script (`pyproject.toml:48`, `veldra_ingest.py:18`), it carries abstracted owned problems and no sittings and no invitee text, and it is what turns `_attach_scene`, `validate_scene` and the vessel count from dead paths into live ones on your machine. The bundle builder's deny regex matches the bare segment `data` at any depth and is tested before the ask list, so no flag can send it. Verified here: the six tables that would hold sittings are all at 0 rows, so the separation is real and not incidental. This is a J decision, and the narrow version (a dump of the `corpus` table's `scene` column for eight ledger_refs) costs one query.

**`docs/admissions/`.** Held back by the bundle's ask list on the strength of filenames like `withhold_your_best_product_from_funders.yaml`, which read as founder strategy. A reader opened the code path: these are serialized `AdmissionRecord` YAML (`admission.py:76` `format_admission_record`, `types.py:748-760`), and those filenames are `frame_code` slugs in the `founder_ceo` posture, i.e. the product's own domain vocabulary. They are the only worked outputs of the pipeline you own, and the only calibration for its five human gates. J's own notes template lists this as a decision he had not made yet. Ask for it.

---

## 7. Gaps: what is not verified anywhere

- **`AnthropicModel.forge_scenario` and `.fit_check` are executed by no test, offline or live.** These author the scenario the learner reads and gate whether it fits the rubric. Verified by grep: every hit in `tests/` is either a `FakeModel` subclass returning a canned string (`test_forge.py:234`, `:259`) or a signature pin (`test_forge.py:79`, `:82`, whose comment says "live behavior is @live-only" and no such live test exists). Their refusal handling and text-block extraction are asserted nowhere. Coverage over the full suite shows five generative model bodies at zero executed statements: `generate_frames` (`model.py:1492`), `generate_scenarios` (`:1505`), `frame_convergence` (`:1517`), `forge_scenario` (`:1534`), `fit_check` (`:1559`). The classifier and grader half has 104 tests in 1.2s. The split is exact: everything that classifies or grades is covered, everything that generates is not, and the generation side is where you will want to work.
- **The seam that makes that cheap to fix is `AnthropicModel(client=...)`** (`model.py:724-733`). `tests/test_anthropic_model.py:187` is a 20-line duck-typed client that scripts results and exceptions and records every kwarg. That is how you pin the exact bytes sent to Opus for any surface, in about ten lines, for free. New model behaviour belongs there, not in an `@live` test the gate never runs.
- **The 21 `@live` voice tests are n=1 Bernoulli trials dressed as assertions and cannot be seeded.** `model.py:276-282` records that temperature and top_p are removed on Opus 4.7 onward, so there is no determinism knob. One test's own docstring concedes it was rewritten to an absolute assertion because the diff form "was flaky by construction", citing a 6/6 vs 0/6 hand measurement never committed as a harness. They encode real doctrine properties. As rates with a binomial CI they are the product's regression suite; as pass/fail they are noise. Mechanical change.
- **Doctrine has a two-test net.** A reader truncated `content/prompts/push.md` to zero bytes and the full suite failed 2 of 1441. `content/prompts/` holds 19 files and `tests/test_prompts.py` is 2 tests pinning about six substrings across three of them. `concierge*`, `forge_scenario`, `grade`, `grade_sharper`, `egress`, `voice_craft` are unpinned. Green says nothing about a prompt edit.
- **The L-13 learner-text guard is an allowlist, and it says so.** `tests/test_prompt_text.py:232-290` enumerates its own blind spots in eight bullets: it cannot see a new compose method, text routed through a helper, a renamed variable at the boundary, concatenation, `%`-formatting, or a triple-quoted f-string whose continuation starts at column 0. Its green is evidence about nine named functions. Add the row by hand when you add a compose site.
- **`src/elenchus/web/__main__.py` is the only module at 0% coverage** (26 statements, 26 missed), and `_load_dotenv` at `:25` is exactly the key-resolution asymmetry the environment doc spends a section on. The launcher's parallel resolver has 16 tests. There are two independent `.env` parsers (`web/__main__.py:25-37`, `scripts/serve_invitee.py:94-108`) that agree today and are held equal by nothing, and `preflight.py:39-43` imports the launcher's, so preflight answers the launcher's question and only accidentally the module's.
- **The whole `cs_technical` regime rests on `tests/test_cs_dry_run.py`, one test.**
- **1,945 lines of frontend are guarded by Python string-grep.** `tests/test_renderer_pipeline_static.py:1-8` states it: "textual by necessity (there is no JS test runner in this repo); the browser smoke supplies the behavioural teeth." A correct refactor fails these with a missing-substring message. The behavioural check is a manual browser pass that no command runs, and `scripts/smoke_server.py` is how you do it: it boots the real `create_app` wired to `tests/conftest.py`'s scripted `FakeModel`, zero tokens, no key (verified by reading `scripts/smoke_server.py:1-25`, which imports from `tests/`). It is in neither handover doc.
- **251 lesson citations and 213 `§` spec-section references resolve to nothing in a fresh checkout.** 109 of the `§` refs are in `session_runner.py` alone, pointing at "spec §2b", "living sitting §2c", "Spec-3 §4c", "MF-3". Only four are named with a resolvable filename. Verified: `docs/`, `.superpowers/` and `docs/superpowers/` do not exist here. A comment that tells you a rule exists and refuses to tell you what it is is worse than silence. The bundle table lists `docs/` wholesale and names none of these; confirm they are inside it, and confirm `.superpowers/sdd/probes-report.md`, which three probe modules cite as the record of the actual paid runs, is somewhere you can read.
- **What J knows that is written nowhere:** the per-call latency distribution from the 2026-08-30 dogfood sitting, which is both the basis for `DEFAULT_MAX_CALLS = 500` and the measurement `model_breakpoint.py:26` explicitly defers the client timeout constant to; the 2026-08-30 red-team findings F1 through F5, cited inline by `model_breakpoint.py` with no file in the tree that defines them, and you are the one wiring the judge those findings hardened; and `~/.felix/memory/elenchus/mistakes.log`, which four Felix surfaces read and which is empty for you, so the part of the engine that turns repeated gate failures into a mechanism is silent for weeks. All three are cheap to ask for and none of them is invitee data.