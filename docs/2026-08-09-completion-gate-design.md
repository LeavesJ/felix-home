# Completion gate — design

Written 2026-08-09. Every capability claim below was checked against Claude Code
2.1.226 on this machine, by reading the shipped binary's own embedded hooks
reference and its hook-dispatch code, not by reading external documentation.

Built before the intent router, because it is smaller and because it closes the
gap between what Felix claims and what Felix enforces.

## The problem

The guidebook's central principle (p7) is that an agent must never declare a
task complete while a required deterministic verification step is failing.

Felix has an excellent deterministic verification step. `felix gate` runs the
project's real checks as a subprocess and exits with their real status
(`felix:161-197`). It cannot be talked out of a failure.

Nothing makes it run.

`engine/hooks/hooks.json` wires two events: `SessionStart` and
`UserPromptSubmit`. Both only inject text. There is no `Stop` hook, no
`PreToolUse`, no `PostToolUse`. So inside a live session, "run the gate before
claiming anything is done" is a sentence in `CLAUDE.md` addressed to a model.

Enforcement exists at exactly two places today, both outside the session:

- Branch protection makes `gate` a required check before a PR merges. Real, but
  opt-in via `felix bootstrap --yes`, requires admin rights, and governs merging
  rather than claiming.
- `templates/unattended.yml` refuses to push on a red gate. Real code — and
  **never installed by anything**. `grep -rn "unattended.yml" engine/` matches
  only the file itself. No command copies it into a workflows directory.

Between an agent writing code and an agent saying it is done, there is nothing.

## Verified mechanics

From the 2.1.226 binary at `~/.local/share/claude/versions/2.1.226`:

**Payload.** The Stop event receives `session_id`, `transcript_path`, `cwd`,
`prompt_id`, `permission_mode`, `agent_id`, `agent_type`, `effort`,
`hook_event_name`, `stop_hook_active`, `last_assistant_message`, and
`background_tasks` / `session_crons`. Confirmed in the hook-dispatch code, which
constructs the object literally.

`last_assistant_message` is the text the agent is about to finish on. Felix can
see the claim before it lands.

**Two strengths of response.**

- `{"decision": "block", "reason": "..."}` — hard. The embedded reference lists
  `decision` as valid for `PostToolUse`/`Stop`/`UserPromptSubmit`, deprecated
  only for `PreToolUse`.
- `hookSpecificOutput.additionalContext` — soft. *"Hook-specific output for the
  Stop event. additionalContext is non-error feedback delivered to the model;
  the conversation continues so the model can act on it."*

An earlier audit reported that Stop cannot use `hookSpecificOutput`. That is
wrong for 2.1.226; the string above is in the shipped binary.

**Loop protection is the platform's, not ours.** *"For Stop/SubagentStop hooks,
check `stop_hook_active` in the input and return success while it's true. Set
`CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` to raise this limit."* So there is already a
cap on consecutive blocks, and the documented contract is to allow when the flag
is set.

## Decision: block on tree state, never on wording

Whether to block is objective. The hook does not read `last_assistant_message`
to decide anything.

Keyword-matching "done", "complete", "tests pass" would be exactly the
brittleness the intent router deliberately avoids, and it fails in the direction
that matters: an agent that says "that should do it" slips through while one
that says "the refactor is complete, though I haven't run anything" is blocked
for honesty.

So: **uncommitted changes exist, and no green receipt matches this exact tree →
block.** `last_assistant_message` is quoted back in the message only, so the
block reads as a response to what was actually said.

A session that changed nothing has a tree identical to `HEAD`, so the hook is
silent. Conversation is untouched.

## Receipts, not re-running

Re-running the gate on every attempt to finish is not viable. Elenchus's gate
runs `ruff format --check`, `ruff check`, and 1,229 pytest tests. Paying that
every time an agent tries to stop would make the tool unusable, and would
encourage disabling it, which is worse than not having it.

Instead `felix gate` writes a receipt when it runs, and the hook compares.

```
$FELIX_HOME/state/gate/<repo-hash>       one line, overwritten each run
  <tree_id>	<result>	<iso8601>	<gate command>
```

The comparison is O(1) and runs no tests.

This is **stronger** than re-running, not weaker. Re-running answers "does the
gate pass right now"; the receipt answers "has this exact tree ever been
verified", which also catches the case where the gate was never run at all —
the common case, and the one re-running would silently paper over by passing.

### Tree identity

```
tree_id = sha1( HEAD sha
               + git diff HEAD
               + sorted untracked paths, each with size and mtime )
```

`git status --porcelain` alone was rejected: two different edits to the same
file produce identical status output, so a receipt would stay valid across a
change it never saw. The diff content has to be in the hash.

Untracked files are included because a new, uncommitted source file is exactly
the kind of change a gate needs to see. Their **contents are deliberately not
hashed** — Felix governs projects in languages it does not know, and an
untracked directory in one of them may be a virtualenv, a build output, or a
multi-gigabyte model artifact. Hashing bytes would make the hook's cost a
function of someone else's project layout. Size and mtime change on any write,
which is sufficient, and costs one `stat` per file.

Two bounds, for the same reason:

- `git ls-files --others --exclude-standard` respects `.gitignore`, so ignored
  build directories never enter the calculation.
- Above 500 untracked files, hash the sorted path list and the count instead of
  per-file metadata, and mark the receipt `coarse`. A repository in that state
  has bigger problems than receipt precision, and the hook must stay fast.

## Behaviour

| State | Response |
|---|---|
| No project governs this directory | Silent, exit 0 |
| Not a git repository | Silent, exit 0 |
| Tree identical to `HEAD`, nothing uncommitted | Silent, exit 0 |
| `stop_hook_active` is true | Silent, exit 0 — the platform's contract |
| `FELIX_ALLOW_RED=1` in the environment | Allow, and record the override |
| Receipt matches this tree, result green | Silent, exit 0 |
| Receipt matches this tree, result red | **Block** — the gate failed on this tree |
| Receipt is for a different tree | **Block** — the gate has not seen this work |
| No receipt at all | **Block** — the gate has never run here |
| Receipt file unreadable or corrupt | Allow, and record. A broken receipt must not strand a session |
| Project declares no gate | Silent, exit 0. Nothing to enforce |

The block message names which of the last three cases applies, since the remedy
differs, and quotes the closing claim so the interruption is legible.

```
The gate has not passed on this tree.

  last run   14:02, on a different tree (3 commits ago)
  this tree  a3f9c2, never verified

  you wrote: "all tests pass and the feature works"

  felix gate
```

## The override is yours, not the model's

`FELIX_ALLOW_RED=1` is read from the hook's environment, which is inherited from
the shell that launched Claude Code. An agent cannot set it for itself mid-session:
`export` inside a Bash tool call affects that subprocess, not the already-running
parent whose environment the hook inherits.

That asymmetry is the whole point. An override the model can reach for is not an
override, it is a suggestion.

Overrides are recorded like everything else. A pattern of them is a fact about
the gate, not about the person.

## What it records

`projects/<p>/memory/verification.log`, tab-separated, committed:

```
2026-08-09T15:41:02Z	blocked	a3f9c2	no-receipt	-
2026-08-09T15:52:18Z	allowed	a3f9c2	green	felix gate
2026-08-09T16:20:44Z	override	b71e08	red	FELIX_ALLOW_RED
```

The instrumentation audit established that **verification result has no native
field anywhere in Claude Code** — not in the session transcript, not in
`~/.claude.json`, not in the telemetry events. Transcripts record `is_error` on
tool results and nothing about whether a gate passed; Bash results carry
`stdout` and `stderr` but no exit code.

So this log is the only place the fact exists, and the corrected capability
ledger depends on it. It starts accumulating the day this ships, which is the
argument for shipping it before the ledger rather than after.

## Error handling

Every unexpected condition allows and records. A completion gate that can strand
a session will be removed, and then it protects nothing.

| Condition | Behaviour |
|---|---|
| `git` unavailable or fails | Allow, record `error` |
| Receipt directory unwritable | Allow, record nothing, exit 0 |
| Hook itself errors | Allow — the hook must never exit non-zero for its own bugs |
| `verification.log` unwritable | Allow, drop the record |
| Hook exceeds its timeout | Claude Code's own timeout applies; the hook does no I/O beyond a diff and two small files |

Blocking is reserved for the one thing this exists to catch. Everything else
fails open.

## Project-agnostic by construction

Felix governs projects in languages it must not require, so this hook must work
on a Rust service, a .NET solution, or a repository whose gate is a Makefile,
with no change to engine code. Adding a project is creating a directory and a
JSON file; if governing something new ever requires editing the harness, that is
a bug, and Felix's own gate enforces it with an independence check.

What this design assumes, and nothing more:

- **git and bash.** Already Felix's only dependencies (`README.md`).
- **A gate that exits non-zero on failure.** Whatever the project declares —
  `npm run verify`, `cargo test`, `dotnet test`, `make check`, a stored script.
  The hook never inspects what the gate does, only whether it passed on this
  tree.
- **Nothing about file extensions, directory names, or toolchains.** "Uncommitted
  changes" is defined by git, not by a list of source suffixes.

Two situations that need naming rather than solving:

- **Two Felix projects in one repository.** The receipt is keyed by repository,
  so they would share one. Rare today, and the fix — keying by project as well —
  is a one-line change made when someone actually hits it, not before.
- **Very large diffs.** `git diff HEAD` is what makes the hash content-sensitive,
  and on a repository-wide refactor it is proportionally slower. Still far
  cheaper than running the gate, which is the alternative being avoided.

## Scope

`Stop` only. `SubagentStop` is out of scope for now: subagents are dispatched
for narrow tasks and frequently should not run a whole project gate. Revisit
once the verification log shows whether subagent work reaches the tree
unverified.

## Testing

In `harness/tests/run`, against a throwaway Felix root, driving the real hook
with real JSON on stdin.

1. Clean tree, no changes → silent, exit 0.
2. Dirty tree, no receipt → blocks, and the message says the gate never ran.
3. Dirty tree, receipt for a different tree → blocks, and the message says so.
4. Dirty tree, matching green receipt → silent, exit 0.
5. Dirty tree, matching red receipt → blocks.
6. `stop_hook_active: true` → allows even with a dirty unverified tree.
7. `FELIX_ALLOW_RED=1` → allows, and writes an `override` line.
8. Editing a file's contents without changing which files are modified invalidates the receipt. This is the `git status --porcelain` trap; it needs a test or the hash will silently regress to it.
9. A new untracked source file invalidates the receipt.
10. No project resolves → silent, exit 0.
11. Project declares no gate → silent, exit 0.
12. Unreadable receipt → allows, records.
13. Non-git directory → silent, exit 0.
14. `felix gate` writes a receipt whose `tree_id` matches what the hook computes for the same tree. This is the integration point and the most likely place for the two implementations to drift.
15. A failing gate writes a red receipt rather than no receipt.
16. `verification.log` gains exactly one line per decision.
17. The hook exits 0 in every case above except a deliberate block.
18. A project whose gate is an arbitrary shell command, in a checkout with no recognisable ecosystem, behaves identically to one with a stored gate script. The existing suite already builds exactly this fixture; the new assertions must reuse it rather than inventing a Python or Node project.
19. An untracked file larger than any sane hash budget does not slow the hook measurably — metadata only, never contents.
20. Above the untracked-file cap the receipt is marked `coarse` and the hook still decides rather than erroring.

Test 14 matters most: the gate and the hook compute `tree_id` independently, and
if they ever disagree the gate silently stops counting. Both must call one shared
function, and the test must prove they do.

## Files

New:

```
engine/harness/hooks/stop
engine/harness/lib/verify.sh        tree_id, receipts, the verification log
```

Changed:

```
engine/hooks/hooks.json             + Stop
engine/harness/felix                cmd_gate writes a receipt
engine/harness/tests/run            the assertions above
.gitignore                          stop ignoring Felix's own memory
```

The `.gitignore` change is shared with the intent router spec and is a
precondition for both: `*.log` currently untracks `mistakes.log`,
`maintenance.log`, and would untrack `verification.log`. `git ls-files` confirms
zero `.log` files are tracked today.

## Known limits

- **One block per stop-chain.** `stop_hook_active` must be honoured, so a
  determined agent reaches its conclusion on the next attempt. This is a speed
  bump with a permanent record, not an inescapable barrier. The inescapable
  barrier is CI at the PR boundary, which already exists.
- **It proves the gate ran, not that the gate is good.** A project whose gate
  checks nothing gets a green receipt for free. `felix gate`'s value is
  unchanged by this work.
- **It cannot see work that never touched the tree.** Configuration changed
  through a UI, a migration run against a live database, anything with no
  diff — invisible.
- **Committed work is unverified by this hook.** `tree_id` is computed against
  `HEAD`, so an agent that commits its changes clears the tree and stops
  cleanly. Committing is itself a deliberate act with a record, and CI catches
  it afterwards, so this is a boundary rather than a hole — but it is a real
  one, and the verification log will show whether it gets used as an exit.
