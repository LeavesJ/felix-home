## 0ak. Verified at session close, 2026-09-03 — the architecture is closed, and the floor has a one-line hole

No code changed. This session produced two governing documents, one published
page, three memory entries, two lessons, and one defect that outranks all of it.

| | |
|---|---|
| head | `e48df85` on `claude/felix-ecc-plugin-ba2871`, tree clean |
| governing docs | `~/Documents/UC Berkeley/Career/Founder OS/felix_v32_architecture_spec.md` and `felix_v32_conformance_amendments.md` in the same folder — **outside this repository, so nothing loads them for you; read both before proposing anything architectural** |
| page | https://claude.ai/code/artifact/7119c7ee-133d-40e1-bc4a-343f7b7a586a |
| workflows run | 7, about 13M subagent tokens |

### Start here, if you are the next session

1. Read the two governing documents named above. They are outside this
   repository and nothing mounts them for you.
2. `felix gate` fails on `installed` here and that is expected: the engine
   deployed on this machine is **0.49.39** (another session), this worktree is
   **0.49.38**, and the check is structurally unpassable in a worktree. Every
   other check is green and the suite is 1100 passed, 0 failed. Do not
   "fix" it; the drift is another session's merged work.
3. The first task is the marker bypass below. It is engine work, and it is the
   deliberate exception to the no-engine-work-before-2026-09-06 rule, because
   every other protection assumes the floor runs at all.
4. Do not design a fifth kernel. See the next heading.

### Read this first: the architecture question is closed

The founder wrote **Felix v3.2**, an authority-kernel spec, and directed that it
plus its conformance amendments be **strictly abided by**. Four in-session kernel
designs were produced before that and he rejected all four, each time because the
proposal narrowed Felix to what was cheap to prove. Do not derive a fifth. What
remains is conformance, sequencing and implementation.

The thesis, in his words: Felix catches the engineering obligation that **neither
he nor the coding model knew to look for**, so he stays in product space.

### The defect that outranks everything

`echo nonexistent > .felix` disables the whole floor. The marker is tracked, has
no row in any `risk.tsv` and no rule in any `deny.tsv`; `felix_resolve_project`
returns non-zero and `hooks/stop` reads that as ungoverned and exits 0. No gate,
no hold, no record. `$HOME/.felix-home` does the same from outside every
repository, so it leaves no diff and no escape channel at all.

Fix: an **absent** marker means ungoverned and is correct; a marker that is
**present and does not resolve** must refuse. This is the project's own rule that
"nothing due" and "nothing is being checked" must not render identically.

### What was measured, and what it cost to establish

- The rate-limit omission is at **five instances**. Opus shipped without it;
  `felix preflight` dropped it; Elenchus's own preflight has no request-ceiling
  check; this session false-negatived on it with a vocabulary grep; and veldra
  **wrote the check and ended it with `exit 0`**, so its scanner prints "All
  gates passed" while naming four unlimited services.
- **My claim that Elenchus had no ceiling was wrong.** `spend.py` ships a
  per-process call ceiling, armed by default at `scripts/serve_invitee.py:163`.
  The real gap is narrower: `src/elenchus/web/__main__.py` does not arm it, so
  one of two entrypoints serves unbounded, and the ceiling is a cumulative count
  with no clock rather than a rate.
- **There is no admission kernel to strengthen.** No obligation ledger, no
  project has a `procedures.tsv`, "obligation" appears twice in the repo and both
  are prose, `cmd_procedures` is never called by the gate, and a stance closes
  when its third column is a non-empty string nothing parses.
- **Elenchus CI checks out Felix with no ref**, so any change to the default
  branch lands in the product's gate unreviewed. Its gate is also the product's
  *only* CI check, and 30 of 30 runs are green.
- Asking an artefact beats grepping it, both ways: FastAPI reports 16 routes
  where the decorators show 12 (the four extra are the auto-mounted docs
  endpoints, in no source line), and cargo reports axum in 7 of 16 veldra
  members where the root manifest shows none.
- **Docker Desktop is installed and switched off.** Starting it closes the
  sandbox gap reported here as unbuildable, and is the path by which a
  hook-shipping provider could ever install without a person.
- Installation is **capable and ungranted**: `stack.sh` really runs
  `claude plugin install --scope user`, no hook or workflow ever calls it, and
  the autonomy file grants nothing. `--scope project` exists and is unused.

### Checker trust, tested rather than argued

Four worthless checkers and one honest one, authored blind, judged blind, on the
real ceiling obligation. The four controls plus a behavioural witness passed the
strongest cheat **8 of 8**. What separates them is a **decoupled violation** —
break the artefact while every syntactic marker stays perfect — plus a
**decoupled satisfaction**, a **coverage report** naming what was examined, and
mutations authored by something that has not seen the checker. Full rules in the
amendments, §2.

The residual, stated wherever the system reports its own trustworthiness: one
authority still writes both the work and the judgement of the work.

### Next, in order

1. Close the marker bypass. Minutes. Everything else assumes the floor runs.
2. Arm the ceiling in `web/__main__.py`; change veldra's D5 to fail; pin the
   Felix ref in Elenchus's workflow. Half an hour, all three.
3. No engine work before 2026-09-06 — beta opens the 5th, soak reads out the 6th.
4. Then the first increment from amendments §4: probes, four states with
   `unknown` blocking, wired to something that already refuses in the same
   commit, so it cannot ship empty the way `procedures.tsv` did.

### Method corrections earned this session

**An audit keyed on what fired cannot see an omission engine.** The first
assessment scored Felix on gate verdicts, denials and escalations, found every
mechanism either never fired or fired on Felix itself, and recommended freezing
the engine. That was wrong, and the founder caught it. A prevented omission and
an absent mechanism leave identical traces, so a method that reads events always
prefers the incumbent. Measure recall against known misses instead.

**Three times a proposal narrowed the system and had to be widened back.** The
tell is every finding pointing at "keep the part that already runs".

