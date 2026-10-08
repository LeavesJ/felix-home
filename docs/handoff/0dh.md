### 0dh. 2026-09-28 — Felix governs a Claude Code cloud session of felix-home, and carries the toolbox its routes name

**One engine file, the suite.** The engine's hooks are unchanged and run from
the clone. The wiring is under `.claude/`, with one gate check in
projects/felix/gate.sh, one risk.tsv row and one probes.tsv row. The only
engine file is engine/harness/tests/run, so the version, the manifest and
red.tsv travel with it.

**Why.** A cloud session (claude.ai/code, the desktop's Cloud, `claude --cloud`)
loads no plugin, whether a user or a repository enables it, and reads nothing
from `~/.claude`: no user settings, skills, hooks or CLAUDE.md. It reads the
repository's `.claude/settings.json` (in a session with one repository),
`.claude/skills`, `.claude/agents`, `.claude/commands`, `.mcp.json` and
`CLAUDE.md` (code.claude.com/docs/en/cloud-environments, "What carries over";
docs/en/settings, "Settings in cloud sessions"). So until this branch a cloud
session on felix-home ran with no Felix: no deny rows, no gate at stop, no
routes, and none of the skills the routes name.

**What changed (LeavesJ/cloud-felix-access-28d34d).**
- `.claude/settings.json` binds every hook `engine/hooks/hooks.json` binds, from
  `$CLAUDE_PROJECT_DIR/engine/harness/hooks/`, each behind
  `[ "$CLAUDE_CODE_REMOTE" = true ] || exit 0`. The hooks find the home from
  their own path (engine/../projects), so no variable is needed. Locally each
  guard costs one bash exit, about 3 ms of CPU per tool call (`times`, load 133).
- `.claude/cloud/provision` fetches the plugins `.claude/cloud/toolbox.json`
  pins, from codeload at the shas installed locally on 2026-09-25, and copies
  their skills, agents and commands into the clone's `.claude/`, each listed in
  `.git/info/exclude` so the session cannot commit them. The two tarballs are
  2.3 MB and took under a second here. On SessionStart it also replays
  superpowers' own session hook from the fetched copy, skipping resume as the
  plugin does.
- `toolbox.json` decides every stack.tsv plugin and skill: superpowers,
  claude-md-management and code-simplifier are carried; code-review is Claude
  Code's built-in; security-guidance (a model-calling Python hook) and semgrep
  (risk=high) are not; anthropic-skills arrive through claude.ai; graphify is
  not, because its graph is not in the clone. It is JSON because the engine
  never reads it, and schemas.tsv registers the tables the engine reads; a row
  there made this an engine change for a file only provision and the gate read.
- The gate's `cloud` check fails when the plugin binds a hook, or binds it under
  an event, that the settings do not; when a settings command lacks the guard;
  and when a stack row has no toolbox entry. Shown failing on each of the four,
  and on reformatted files; passing on the tree and on an irrelevant edit.
- risk.tsv classes `.claude/settings.json` and `.claude/cloud/` red, beside
  `engine/hooks/`, which they mirror. Like that row, it carries no channel.

**Measured in a cloud VM, 2026-09-28 and 29.** A session on this branch ran as
root in a Firecracker VM, on Ubuntu with mawk as awk, in a shallow clone
holding only this branch.
- The hooks fire. SessionStart and UserPromptSubmit hand over their context,
  and Stop holds every turn's end until the gate has passed on the exact tree.
- provision's codeload fetch gets HTTP 403 through the session's proxy, so
  nothing it carries arrived that way, and whether skills written at
  SessionStart appear without a restart is still unmeasured.
- Plugins do load in a cloud session when the VM's own `~/.claude` holds them,
  which corrects "loads no plugin" above: the plugins installed into it on
  2026-09-28 (below) were live when the session resumed on the 29th,
  superpowers' skills and the code-simplifier agent among them. What does not
  carry over is the founder's `~/.claude`. So `claude plugin install`, which
  reached GitHub through the same proxy, is a route provision could take for
  the next session instead of codeload.

**Why the gate was red there, and what changed.** Five causes, none in the
engine's behaviour.
- Root. Root writes and reads through any file mode, so ten assertions that
  build a refusal out of chmod failed on a refusal that never happened. They
  now ask the machine first and skip where it cannot refuse, as the unreadable
  table assertions already did: `_unwritable` for writes, beside the budget
  tests, and the existing `_unreadable` for the one read that came before it.
  The graphify lock test's skip branch named one of its two assertions, so
  the other read as never reached. A run as an unprivileged user still runs
  and passes every one of them.
- No main. secret-scan found no base in a single-branch clone, scanned
  uncommitted changes only, and read ok over committed trees it never
  scanned; eleven secret controls and one handoff control held for that
  alone. provision now fetches main by an explicit refspec, since a bare
  `git fetch origin main` fills FETCH_HEAD and makes no origin/main there, and
  unshallows when main and HEAD do not meet; `--report` prints the base. On a
  fresh depth-3 clone a committed planted key passed secret-scan before and
  failed it after.
- marketplace_root read blind wherever a registry exists without a felix
  marketplace. Its `when` now asks for a felix entry, as deployed_engine's
  asks for a felix cache. On scratch homes it reads not-applicable with no
  registry and with another marketplace, found with a felix entry, and blind
  with a felix entry that has no installLocation.
- mawk 1.3.4, the awk there, fails an anchored repeat whose minimum is two
  or more once the text runs past that minimum: /^ {20,}[^ ]/ matches twenty
  spaces and not the help's twenty-seven, so the help assertion read an empty
  help. It measures the indent now. No engine awk has that shape.
- The 6 MB audit bound counted system time, and there the one mawk reading
  that command made 136,471 mremap calls, costing 0.8 to 9.9 s of system time
  on an idle VM around 0.4 s of user time. The bounds read user time now.
Beside those, the suite installed real plugins. At 18:37 on 2026-09-28, in the
first gate run, the seven low `always` plugin rows of templates/catalog.tsv
were installed into the real `~/.claude`, security-guidance among them
although toolbox.json declines it, and the registry that made
marketplace_root blind was written with them (docs/handoff/0bm.md saw that
half on a clean runner). `felix new probeseed` and `probeseedq` commission,
and with `stack apply --yes` they ran the real claude against the real HOME.
They go through CMSTUB now, as every other `felix new` in the suite does.
"already-installed rows report present" assumed superpowers is installed
wherever the claude CLI is, and now asks the list felix reads.

**Found, not fixed here.**
- secret-scan with no base exits 0 over what it did not scan and says so on
  stderr only, so anywhere main is absent the gate's secret line is a pass
  over nothing. Failing closed there is an engine decision.

**Open, and the founder's.**
- Memory. `~/.felix/memory` is backed up only to an iCloud bare repository no
  cloud VM can reach, so a cloud session has no lessons and what it writes dies
  with the VM. The auto-memory under `~/.claude/projects` and the user CLAUDE.md
  files are absent the same way. Carrying them means putting them on GitHub.
- Other governed repositories. Their clones hold neither the engine nor their
  doctrine, which lives in private felix-home. Where a governed project's
  doctrine lives when its session runs in the cloud is an architecture
  question, not this branch's.
- probes.tsv is an escape table, so the marketplace_root row changed in place
  stops `felix merge` for a person.
