### 2026-10-12: declared tools' reach, the pulse's settings and reach lines, and felix status

**Engine 0.49.283**, branch claude/declared-tools-reach, from main at 0.49.280. The
spec is docs/2026-10-12-declared-tools-reach-spec.md; the brief behind it was the
founder's: a declared-tools checker, the daily pulse reporting it with the settings
file's health, and one read-only command a status surface can poll. No table under
projects/, no escape, no deny row.

**Why.** felix stack calls a plugin row present once `claude plugin list` names it
and never asked whether the MCP servers that plugin ships connect. Measured
2026-10-12: one plugin declared `always` in eight projects listed as needing
authentication in a live session while `claude mcp list` from an empty folder said
Connected; the datadog plugin fails every session with ENOTFOUND on a placeholder
address; the github server fails with HTTP 400. Nothing in Felix said any of it.
And ~/.claude/settings.json is what enables Felix: a broken hand edit there removes
it, and nothing inside Felix can say so, because its hooks never load.

**Three surfaces.**
- Reach (lib/reach.sh, felix stack --reach [--tsv]). One `claude mcp list` read,
  classified per declared plugin or mcp row and per server: connected, needs-auth,
  failed, not-listed, no-server, unknown. Cached per project in
  state/reach/<project>.tsv under a `# read <epoch> <dir>` header. The list is read
  from a fresh empty directory under TMPDIR, never the checkout (see "Found in
  review"). The SessionStart hook starts a detached refresh when the cache is
  absent or a day old and reads nothing back. Advisory only: felix stack plan still calls a plugin whose server
  needs authentication present, and the gate, the Stop hook and commissioning never
  read the cache. A detail never carries a URL's query string.
- The pulse (lib/pulse.sh, lib/status.sh). Two new report duties and a record: a
  `settings` line (ok, felix-off, invalid, missing, unknown, through jq, never ok
  without a parse), reach lines from each project's cache only, and
  state/pulse.status.tsv, `# ran <epoch>` and the lines of the run. The pulse runs no
  `claude` command: the launchd job's /bin/bash holds Full Disk Access, and
  `claude mcp list` starts every configured stdio server, some at floating
  `npx @latest` versions.
- felix status [--tsv] (lib/status.sh). Five rows, `<row> TAB <state> TAB <value> TAB
  <detail>`, no header: settings, schedule, pulse, reach, gate; state is value, none
  or unknown. Read-only, no network, no claude. The contract a status surface
  reads, and the only one.

**Measured.** felix status --tsv, once in a governed checkout on this machine
(2026-10-12, load average 6): 0.25 s in this worktree (receipt stale) and 0.22 s in
the main checkout (receipt red). The slow path is a receipt that matches the tree,
which makes felix_verify_current recompute the epoch and run the project's probes:
0.73 s for felix, so about 1 s. The target was well under 2 s.

**What this machine said.** felix status here: settings ok, schedule loaded with
last exit 0, pulse `10` (days since the memory reached its remote; no record of a
last run existed before this change), reach unknown (no cache yet).

**Found after the blind part, and fixed.**
- `git diff HEAD` rewrites .git/index when a tracked file is only stat-dirty, with
  GIT_OPTIONAL_LOCKS=0 or without (git 2.54: the variable stops git status and
  not git diff). felix_tree_id runs it, so felix status with a receipt on the
  tree wrote to the checkout, which S4 forbids; the blind S4 assertion has no
  receipt and never reached it. The gate row now reads the receipt against a
  scratch copy of the index, removed after.
- A global `${x//pat/}` over a list is quadratic on bash 3.2: the first draft of
  the read took 3 s for 100 server lines and 100 s for 400. A case now.
- Two harness mistakes in part 1100, each marked with a comment above it:
  `_rx_pick` read "$3" unbound under set -u, and the reachy fixture declared no
  probes, so a green receipt carries no epoch and reads stale, never current.
- Part 0220's `adopt --help` assertion looked for the word "declared" in the usage
  text, which now says it (felix status, felix stack --reach); it looks for the
  writer's own sentences instead.

**Found in review, and fixed.** The adversarial review raised two blockers, and a
security review of the fix for the first raised a third.
- `claude mcp list` ran in the checkout, at every session start, so a project
  `.mcp.json` server that was approved or auto-enabled (enableAllProjectMcpServers)
  would have been started in a repository nobody had vetted. Measured with the
  real CLI: a server pending approval is listed and not started, and from an empty
  directory it is not listed at all (CLAUDE_PROJECT_DIR changes nothing). So the
  list is now read from a fresh `mktemp -d` directory under TMPDIR, removed after,
  for the refresh and for `felix stack --reach` alike; with no directory to read
  from it, or with a .mcp.json in any parent of it (the CLI walks up, measured), it
  reads nothing and runs no claude. An mcp row the list does not name is
  now `unknown`, its detail saying a project-scoped server is not started by Felix,
  and never `not-listed`. Part 1120: a claude stub that records its $PWD and starts
  the .mcp.json command of the directory it is run in, 29 assertions red before the
  fix, and six mutants of the fix each caught.
- A scratch FELIX_HOME_DIR wrote the real home's cache. Not a bug: FELIX_HOME is
  the CLI's override and FELIX_HOME_DIR is assigned from it, unconditionally, on
  main too. Nothing changed; part 1120 pins that the cache, the pulse record and
  log and the refresh land in the home the invocation resolved.
- The empty-directory fix fell back to /tmp when TMPDIR was unset or relative
  (security review, MEDIUM, toctou). /tmp is world-writable, so another local user
  could plant /tmp/.mcp.json after the ancestor check and before the read, and the
  CLI would find it from the parent. A check cannot close a race, so the shared
  place is gone: TMPDIR is used only when it is absolute, owned by the user,
  writable by neither group nor others, under ancestors that are owned by root or
  the user and writable by neither, all read on the physical path (stat -c, then
  stat -f, then ls -ldn; none able to say means not private). Otherwise claude is
  not run and the rows read unknown, with one sentence that says why. The ancestor
  .mcp.json check stays. macOS's per-user temporary directory passes (measured:
  0700 under 0755 parents); a Linux machine with TMPDIR unset or under /tmp reads
  nothing until TMPDIR names a private directory, and the pulse says reach-unread
  there. The read moved into lib/reach-read.sh because reach.sh would have passed
  500 lines (a blind assertion pins the limit). The suite's reach fixtures needed a
  private base too, so on a runner whose temporary directory is under /tmp (the
  Linux CI runner) parts 1100 to 1120 live under the first of XDG_RUNTIME_DIR,
  RUNNER_TEMP and HOME that qualifies and remove it at the end. Part 1120: 50 of
  its assertions fail against the engine before the fix and pass after it, and
  fourteen of fifteen mutants of the fix are caught (the fifteenth, dropping the
  guard on `id -u`, is equivalent: the chain test still refuses when the user is
  unknown).
- Not changed, and wanting its own decision (spec, "Left as it was"): the only
  unattended path that already runs `claude mcp list` in a checkout is
  commissioning. session-start starts `felix commission` detached, with the
  checkout as its cwd, under a `commission` autonomy grant (only projects/felix
  has one), and its `stack` row calls felix_stack_plan. A checkout's own `.felix`
  file names its project and wins, so a repository that holds `felix` in `.felix`
  is bound to project felix (measured with `felix which` in a scratch repository),
  and nothing in the commissioning path asks whether the checkout is the
  project's own. Read from the code, not run end to end.

**Record.**
- The blind part 1100 against main's engine: 58 passed, 172 failed. Against this
  one: all 230 of its assertions pass. Part 1110 (the implementer's, after the blind
  part, so not blind; 10 assertions) has the two findings above and was shown red
  against the pre-fix gate row and the quadratic read.
- The third blocker (parts 1100 to 1120 only, run with a cut-down runner from an
  empty directory outside any repository): 389 passed, 0 failed, against 310 at
  410e55d3; with the suite's temporary directory moved under world-writable
  /private/tmp, the layout of a Linux runner, 389 passed, 0 failed; the same
  assertions against the engine at 410e55d3, 339 passed, 50 failed.
- tests/assertions.tsv and tests/red.tsv are not re-recorded here: that is the
  landing slot's full run. The whole suite and the gate were not run in this stage.
- Prefix of the suite (parts 0010 to 0480, then 1100 and 1110) against this tree:
  3456 passed, 5 failed. The 5 are the deploy-check group (exit 126) that the
  unchanged engine also fails when the suite is exported outside a git checkout;
  part 0220, which the new usage lines tripped, passes again.

**The status surface, built outside this repository, and kept for reuse.** The
founder asked (2026-10-12) for a mini dashboard as a Claude Code mod, the way he set
one up on a friend's machine, until Felix has its own interface. He asked for it to
be recorded, because it is temporary and its parts are meant to be reused when the
real interface is built. It is the `dash` mod:
- Live source `~/.claude/mods/dash`, loaded in every session by
  `CLAUDE_CODE_PLUGIN_DIRS` in `~/.claude/settings.json`. A copy with a README is in
  the memory repository at `audits/2026-10-12-dash/`, which the pulse backs up;
  `~/.claude` is backed up by nothing.
- A band above the prompt (agents running and done, live sessions, enabled plugins,
  skills used, gate, tools, pulse, settings, the week's spend) and a pane, `/dash`,
  with the same and an activity log. Read-only: it hooks no tool call it could
  refuse. 9 tests under `claude plugin test`.
- It reads Felix only through `felix status --tsv`, every minute, and
  `felix cost --week --tsv`, about 20 s, run by one session every 15 minutes and
  shared through the mod store with a lock.

What the Felix interface should take from it, rather than rebuild:
- this branch's five-row contract as the data layer every surface reads (the
  2026-10-09 "data contract first, skin second" proposal, now real);
- the three-state cell rule: `?` is not measured, `-` is none, and nothing that was
  not read is ever drawn as 0 or ok;
- the expensive reading shared across sessions instead of run by each;
- live sessions read from `~/.claude/sessions/<pid>.json`, filtered by `ps`;
- two limits found: `$.agent.list()` does not list Workflow agents, and a tool
  called from a mod timer fires every classic PreToolUse hook (the ledger's
  included), so a surface must never poll through a tool.

**Next, a security item for its own pipeline.** The commissioning path in "Found in
review" above: a repository whose `.felix` names `felix` gets a detached
`felix commission` at session start, in that checkout. That matters because the
founder opens hostile repositories for bounty work. What it runs there has not been
traced end to end. The fix is to refuse unattended commissioning in a checkout
whose remote is not the project's, or to run its reads from a private empty
directory as reach now does.

**Not built.**
- Weekly spend is not a status row, on purpose.
- Version: 0.49.283. Read 2026-10-12 at ship time: main 0.49.280; unmerged
  branches and worktrees hold 0.49.281 (secret-scan-quoted-reference, gf-a family)
  and 0.49.282 (origin/claude/setup-actions-node24); nothing holds 0.49.283.
  Renumber if another engine PR lands first.
