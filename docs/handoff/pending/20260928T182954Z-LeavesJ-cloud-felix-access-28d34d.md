### 2026-09-28 — Felix governs a Claude Code cloud session of felix-home, and carries the toolbox its routes name

**Nothing under engine/.** The engine's hooks are unchanged and run from the
clone. The new files are repository wiring under `.claude/`, one gate check in
projects/felix/gate.sh and one risk.tsv row, so no version and no red.tsv are
owed.

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

**Not yet measured in a cloud VM.** `claude --cloud` refuses from a desktop
session's shell (no TTY, then no claude.ai login there), so no cloud run has
read this branch yet. Two things only a run answers: whether skills written at
SessionStart appear without a restart, and what the gate and the Stop hook do
there. If the skills do not appear, the fallback is the environment's setup
script, which runs before Claude Code starts.

**Open, and the founder's.**
- Memory. `~/.felix/memory` is backed up only to an iCloud bare repository no
  cloud VM can reach, so a cloud session has no lessons and what it writes dies
  with the VM. The auto-memory under `~/.claude/projects` and the user CLAUDE.md
  files are absent the same way. Carrying them means putting them on GitHub.
- Other governed repositories. Their clones hold neither the engine nor their
  doctrine, which lives in private felix-home. Where a governed project's
  doctrine lives when its session runs in the cloud is an architecture
  question, not this branch's.
