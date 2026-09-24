### 2026-09-24 — the unattended model step could read its own API key from /proc, measured on ubuntu-latest, and the template now denies it

**One engine PR from this session, #341, version 0.49.193** (the queue carrier's number; #341 lands after #336 and #308). The
"Attempt a repair" step of `templates/unattended.yml` runs `claude -p` with
`--allowedTools "Read,Edit"` and `ANTHROPIC_API_KEY` in its environment. A
tool-name allow rule opens every path (§0bx's sibling finding on the checkout
token), and on Linux a process's environment is a file. macOS has no `/proc`,
so this was untested until now.

**Measured, not read.** The real `@anthropic-ai/claude-code@2.1.37`,
installed as the template installs it, ran on ubuntu-latest in a throwaway
private Actions repository (`LeavesJ/felix-measure-proc-environ`, safe to
delete) against a scripted Messages API stand-in, with a sentinel key and no
model:
- Read on `/proc/self/environ` returned the claude process's environment as
  one NUL-separated line, key included, and a scripted Edit put the key in a
  tracked file, which the push step commits.
- `--disallowedTools "Read(//proc/**)"` refused it, and every other spelling
  (`/proc/self/../self/environ`, a relative path climbing to `/proc`,
  `/proc//self/environ`, `/proc/thread-self/environ`), as a tool_use_error
  "File is in a directory that is denied by your permission settings"; the
  repository's own files stayed readable and editable.
- `Read(/proc/**)`, one slash, refused nothing: one slash names a path under
  the working directory.

**The fix** is one line, the deny rule after the allow list, with the
measurement in the comment above it and in tests/run ("the unattended repair
denies the model its own environment": the claude stub records its arguments
one per line, and the assertion reads the value after `--disallowedTools`).
Shown failing first on main's template. The measurement is the pin's: when
the claude-code version moves, dispatch the throwaway repository's workflow
again with the new version in `run.sh`, or rebuild the rig from #341's body.

**Sibling work, not this PR.** Session 6811a4 ("Keep credentials out of the
unattended model's reach", branch `claude/inspiring-villani-849cbd`) holds
the same template's other hole: `persist-credentials: false` on both
checkouts, a push-time credential helper, and the allow list scoped to
`Read(./**),Edit(./**)` with `.git/**` denied. It lands after #341, agreed by
message: one combined `--disallowedTools` keeps `Read(//proc/**)` as the lock
that does not depend on the allow list's shape, both tests/run sections stay
after "an install that succeeds goes on to the model", and assertions.tsv is
re-sorted in the C locale. The /proc assertion already reads every deny and
allow value, so their shape passes it.

**Founder answer, checked 2026-09-24.** No real unattended run has had the key
in a model's reach: Elenchus holds the `ANTHROPIC_API_KEY` secret (set
2026-08-10), `FELIX_UNATTENDED` is unset, and the "Attempt a repair" step was
skipped in all 48 of its unattended runs. No rotation is due from this vector.
bazaar and veldra carry no unattended workflow and no such secret.

**Traps paid for this session:**
- Felix's deny row "main is merged through felix merge and a person, never
  pushed from a session" refuses `git push origin main` for any repository a
  session pushes, a throwaway measurement repository included. Push a branch.
- Docker Desktop did not come up in five minutes at a load average above
  250 (`open -a Docker` returns 0 and no process appears). A throwaway Actions
  run answered in about a minute per run.
- A JS parser with `if (a) for (...) if (b) x; else if (c)` binds the else to
  the inner `if`: the log showed every tool call and no tool result, and the
  fix was lost once more inside a command Felix refused. Two runs.
- Every engine PR classifies red, from `engine/.claude-plugin/plugin.json`.
  The tier stops nothing; the escape channels do.
- A background Bash call is capped at ten minutes, and its `tests/red` child
  outlives the cap (bash defers TERM while it waits on a child), so two
  orphaned red runs were found later by their cwd. A long run goes through
  `nohup ... & disown` in a foreground call, which survives the call's end.
- The red check compares the record's base engine tree with the merge-base's,
  so a record against a queue-mate's head holds only once that head is main.
