# Phase 1 gaps — design

Written 2026-08-10. Three changes, each independent, each closing something the
Phase 1 review found open. Every claim below was checked by running something
today, not by reading code.

Follows the existing `docs/` convention rather than the brainstorming skill's
default path, because this repository already has one.

## What this closes

| Guidebook p41 exit criterion | Before | After |
|---|---|---|
| take an issue | nothing reads an issue | `felix brief <n>` |
| open PR | Felix never opened one | `felix pr --create` |
| basic audit | real, but blind to a rival gate | D closes that hole |

E closes nothing on p41. It exists because the audit trail is unreadable past
the last few events, which makes the other two harder to trust.

---

## D. The rival gate

### The problem, in real data

Elenchus has two gates:

| | checks | dated | tracked |
|---|---|---|---|
| `Elenchus/scripts/gate.sh` | 7 | Aug 8 13:42 | no (`??`) |
| `Felix/projects/elenchus/gate.sh` | 8 (`+secret`) | Aug 9 19:23 | yes |

An untracked, day-stale, strictly weaker copy of the gate sits inside the
governed repo, and it is the one physically in front of any session that looks
around. A real session ran `./scripts/gate.sh` all day and reported green from
a gate missing a check. It found out only because the completion gate nagged it
into running the real one.

`felix doctor` in that checkout reports `undeclared: none`. Nothing in the
engine references a rival `gate.sh` — verified by grep across `lib/` and
`hooks/`.

### Why this is not a documentation problem

A gate with a lookalike is not a gate. It is a coin flip on which file somebody
reaches for, and the wrong side of the flip reports success. The failure is
silent and it is indistinguishable from a pass, which is the same shape as the
lesson already on file: a check that skips absent files passes by finding
nothing.

### Design

Extend `felix doctor` with one additional report: **executable files in the
governed checkout whose name or content marks them as a gate, and which are not
the gate this project declares.**

Detection is deliberately narrow, because a broad one would flag every script:

- the file is executable, and
- its repo-relative path matches `gate|verify|check` in the basename, and
- it is not the declared gate for this project.

For each hit, report the path, whether git tracks it, and — when both are
readable — the count of check names each one runs, so the weaker one is
visible rather than merely different. Comparing check *counts* rather than
diffing keeps this bash-and-git and avoids claiming two scripts are equivalent,
which is not decidable.

`doctor` reports and never deletes. A rival gate can be legitimate — a fast
subset a human runs by hand — and Felix does not get to decide that.

Lands in `engine/harness/lib/detect.sh` (red tier) with the report rendered by
`cmd_doctor` in `engine/harness/felix` (yellow).

---

## A. Issue → PR

Two verbs, because intake and delivery are separated by all of the actual work,
and `felix pr` is useful for work that began without an issue — which is most
work.

### `felix brief <issue>`

Mirrors `felix repair` exactly. That is the whole design argument: `repair`
already prints a brief to stdout for CI failures and carries its scope verdict
in the exit code, and `unattended.yml` already consumes it with
`felix repair | tee /tmp/brief.txt` and branches on `rc != 3`. Building `brief`
to the same contract makes the unattended path a workflow edit rather than a
rewrite.

Behaviour:

1. `gh issue view <n> --json title,body,labels` — fails loudly if `gh` is
   unauthenticated, because a brief built from a failed fetch is a brief about
   nothing.
2. Extract repo-relative paths from title and body by reusing
   `felix_incident_paths`. That helper is already conservative: a token is a
   path only when the file exists in the checkout, which is what keeps a brief
   from blaming vendor code.
3. Derive the tier from `risk.tsv` via `felix_incident_severity`.
4. Name the evidence `evidence.tsv` requires for those paths.
5. Name the play `routes.tsv` calls for, scored against the issue text.
6. Print. Exit `3` when a red path is implicated.

No branch is created. Cutting a branch mutates a working tree that may be
dirty, and a command that loses work to save a keystroke is not worth having.
The brief names the branch to create; the caller creates it.

No storage. The brief is derived and regenerable, so it stays on stdout and
callers redirect it. That also keeps it out of the diff of the PR it describes
— the same trap as the receipt written inside the tree it recorded.

### `felix pr`

- Assembles a title and body from the branch's commits, plus the brief when
  `--issue <n>` names one. The issue is passed explicitly rather than parsed out
  of the branch name: inferring it would impose a branch naming convention the
  engine has no business having, and would silently attach the wrong brief when
  a branch happened to contain a number.
- Prints by default. Creates behind `--create`. This is the precedent
  `felix incident --create` and `felix classify --apply` set, against
  `felix discover`, which refuses `--yes` outright.
- Applies `risk-<tier>` through the existing `classify --apply` path.
- Opens even when the gate is red, marked draft. Refusing would leave the
  repair loop nothing to attach to, which is the loop's entire premise.

Lands in a new `engine/harness/lib/intake.sh` (red tier) with both commands
dispatched from `engine/harness/felix` (yellow).

---

## E. Archive popup

### What is already there

`monitor.html` already groups records by session: `liveSession()`,
`sessionSays()` and `pastSays()` at lines 363–367, and line 438 already counts
distinct past sessions for the header. The archive renders events flat. Making
each session clickable is a rendering change, not a data change.

### What the popup shows

Per session, from records Felix already writes: every routing decision with its
score and prompt excerpt, everything Felix said in full, every gate verdict,
every mistake. That is Felix's complete side of the session.

Plus the session id and a copyable `claude --resume <id>`.

### What it does not show, and why

Claude's replies and tool calls. Both roads are closed:

- The transcript is JSONL in `~/.claude/projects/`. Parsing it in the engine
  breaks the bash-and-git invariant; the capability ledger design already
  rejected this exact approach for this exact reason.
- A `file://` page cannot fetch a sibling local file. CORS forbids it, so
  client-side parsing is not a way around the first point.

Claiming the popup holds the chat would be inventing. It holds Felix's record
and points at the chat.

### The cap

`monitor.sh` reads the last 40 route rows, 60 says, 40 verdicts, 20 mistakes.
"All past sessions" is bounded by that today. This design raises the says cap
only, to 200, because that is the record the popup renders and the others are
already summarised. Raising all four would grow the rendered page without
anything reading the extra rows.

Lands in `engine/harness/templates/monitor.html` (yellow) and
`engine/harness/lib/monitor.sh` (red — `risk.tsv` puts all of `lib/` there,
because it is sourced by the CLI and by every hook).

---

## Risk and evidence

| Path | Tier | Required evidence |
|---|---|---|
| `engine/harness/lib/detect.sh` | red | assertion in `tests/run` |
| `engine/harness/lib/intake.sh` | red | assertion in `tests/run` |
| `engine/harness/lib/monitor.sh` | red | assertion in `tests/run` |
| `engine/harness/felix` | yellow | assertion in `tests/run` |
| `engine/harness/templates/monitor.html` | yellow | — |

`evidence.tsv` requires a `tests/run` assertion for anything under `lib/` and
for the CLI. Every assertion is written failing first and shown failing before
it is believed, per the constitution's fourth invariant.

Felix's own red tier applies to this work. Branch protection is unavailable on
a private free repository — `gh api repos/LeavesJ/felix/rulesets` returns 403,
"Upgrade to GitHub Pro or make this repository public" — so the rule is honoured
by behaviour and the gap is stated in `HANDOFF.md` rather than left silent.

## What this deliberately does not do

- **No unattended wiring.** Stage two of intake is a separate change, and the
  risk rules still have not judged a real failure.
- **No branch creation, no auto-merge.** Both remain earned rather than granted.
- **No transcript in the popup.** See above.
- **Does not fix mid-turn blindness.** The router runs on `UserPromptSubmit`,
  once per submitted prompt. A message sent while a turn is running never
  reaches it — confirmed today, where four top-level prompts were logged and one
  mid-turn message was not. No Felix change fixes this; Claude Code emits no
  hook for it.
- **Does not fix the two routing misses found today.** The Elenchus-sessions
  prompt scored 0 against the table, and no route names
  `dispatching-parallel-agents`. Both are `routes.tsv` edits, green tier, and
  belong with the other table work rather than in an engine change.
