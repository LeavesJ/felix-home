### 2026-10-19: the mods round (#417) was measured, and what it changes for capability items 4, 6 and 8 and the input-rewriting floor

The round the pending section `20261008T040415Z-LeavesJ-mods-capabilities-roadmap-98a6c7.md` specified has now been
run. It covered that section's questions plus the 2026-10-18 delta (Q1-Q8 reworded, Q9-Q14 added). This section is
handoff material: no direction changes. The roadmap, the queue and 0cw keep their words until the founder says
otherwise.

**Where it is.** `audits/2026-10-19-mods-round/` under the memory root:

- `results.tsv`: 260 rows marked `[mods-round 2026-10-19]`;
- `results.md`;
- `disposition.md`;
- `challenge.md`;
- PDFs in `pdf/`.

The builds were desktop 2.1.293, desktop 2.1.295 and CLI 2.1.296, pinned by sha256 in `builds.tsv`. The runs used a
local stand-in API under `env -i`, a scratch HOME and a dummy key. No tokens were spent, no credential was touched,
nothing was installed, and nothing was downloaded. The blind predictions were frozen before the first run. An
adversarial round then ruled 11 verdicts STANDS, 5 REVISED and 3 WITHDRAWN. The 2.1.299+, 2.1.300+ and 2.1.301+ arms
are NOT-MEASURED-YET, and no disposition turns on them. Nothing here is an input to a receipt or a merge blocker, and
no probe put a model on an enforcing path.

**Capability item 4 (the dry-run lease).** The flags hold. Measured additions:

- **Read `is_error` or `terminal_reason`, never `subtype`.** A run whose model was refused ends with
  `subtype: "success"` and `is_error: true`.
- **Keep the full model id.** A refused full id fails the run. A refused default or alias steps down silently to the
  previous model of its tier on the real API. A project's `env` can redirect the `opus` alias, but not a full id.
- **The cap.** With no Agent tool, `--max-budget-usd` stopped after one request with rc 1. It overshoots only when
  subagents run.
- **Never `--bare` for a mod.** No mod hook fires there, yet the init line still lists the plugin.

**Capability item 6 (the outcome record).** Change its model source.

- **`resolvedModel` is not the model that ran.** `PostToolUse(Agent).tool_response.resolvedModel` names the spawn-time
  model after a `turn.step` rewrite, and `claude-opus-5-5` after a same-tier step-down to `claude-opus-5`.
- **The workflow record repeats the error.** Its `workflowProgress[].model` names the script's model in both cases.
- **What to read instead.** The result's `modelUsage` and the agent transcript's `message.model` were right every time.
- **Two more facts for the record:**
  - Under `-p` an Agent call runs in the background by default, so `PostToolUse(Agent)` fires at launch.
  - A resume skips `agent.spawn` and keeps the spawn-time model.

**Capability item 8 (the consequence floor).** The floor stays advisory and raise-only. The measured levers:

- **`agent.spawn`.** It raises or lowers an Agent call's model in every mode. It does not reach effort, forks, resumes,
  or Workflow agents before 2.1.300.
- **`turn.step`.** It reaches every request, Workflow agents included, but no record shows the change.
- **The Agent tool's own `effort` input.**
- **`CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL`.** It is a pin from user scope only. It lowers as well as raises, beats a
  stage's named model, and is dropped from project settings.

A floor named by alias is soft. An `opus` floor the API refuses runs on `claude-opus-5` with a normal result, and a
repository's `ANTHROPIC_DEFAULT_OPUS_MODEL` moved `opus` stages to haiku. A floor must name full ids, and its check must
read `modelUsage`.

**The input-rewriting floor.** It stays declined. Its two reasons were:

1. **"A rewrite can lower the model."** This still holds: `updatedInput` lowers an Agent call's model on all three
   builds, with or without `allow`. It is now one lowering path among several.
2. **"An enforcing output on the fail-open hook."** This no longer holds as a host limit. On 2.1.295+,
   `onFailure: "block"` on the hook entry makes PreToolUse and UserPromptSubmit fail closed, in a plugin's `hooks.json`
   too, and a mod gate with a denying `.catch` also fails closed. It still holds for Felix as built:
   - Felix's scripts use no errexit and exit 0 on their own errors.
   - With no `timeout`, a hung hook holds each tool call for 600 s.
   - A typo in `onFailure` or `shell` silently drops every hook in the plugin, or a whole settings file with its deny
     rules.
   - Stop and SubagentStop ignore the key, so the `stop` gate check cannot be made fail-closed this way.

If the floor is reconsidered, the measured lever is `agent.spawn` with a denying `.catch`, not `updatedInput`. That is
the founder's call, and nothing is asked now.

**Also measured:**

- **A Workflow stage that does nothing is recorded `done`.** A stage that writes an empty artifact looks identical to
  one that did its work. A denied spawn fails the whole workflow while the `-p` result says success. Stage checks must
  read each artifact's content.
- **On 2.1.293-2.1.296 the UserPromptSubmit hook already sees the slash command as typed.** Misrouting corpora need no
  re-basing for that field.
- **No Felix hook answers `allow`,** so the plan-mode write hole before 2.1.299 does not reach Felix.
- **Method.** The rig's 127.0.0.1 base URL closes a first-party-only path. The Q13 verdicts were rig artefacts until the
  challenge round re-ran them with `_CLAUDE_CODE_ASSUME_FIRST_PARTY_BASE_URL=1`. Model-routing cells must run both ways.

**Still owed.**

- **Q8, attended Desktop.** About ten minutes of the founder's time at the Code tab.
- **The 2.1.299-2.1.301 arms.** Rerun them with the scripts named in `disposition.md` once the desktop app has updated
  itself past 2.1.301. They need no download.
