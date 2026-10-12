### 2026-10-12: declared tools' reach, the pulse's settings and reach lines, and felix status

**Engine 0.49.282**, branch claude/declared-tools-reach, from main at 0.49.280. The
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
  state/reach/<project>.tsv under a `# read <epoch> <cwd>` header. The SessionStart
  hook starts a detached refresh when the cache is absent or a day old and reads
  nothing back. Advisory only: felix stack plan still calls a plugin whose server
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

**Record.**
- The blind part 1100 against main's engine: 58 passed, 172 failed. Against this
  one: all 230 of its assertions pass. Part 1110 (the implementer's, after the blind
  part, so not blind; 10 assertions) has the two findings above and was shown red
  against the pre-fix gate row and the quadratic read.
- tests/assertions.tsv and tests/red.tsv are not re-recorded here: that is the
  landing slot's full run. The whole suite and the gate were not run in this stage.
- Prefix of the suite (parts 0010 to 0480, then 1100 and 1110) against this tree:
  3456 passed, 5 failed. The 5 are the deploy-check group (exit 126) that the
  unchanged engine also fails when the suite is exported outside a git checkout;
  part 0220, which the new usage lines tripped, passes again.

**Not built.**
- The status surface itself: a Claude Code mod, built outside this repository, that
  runs felix status --tsv on a timer and felix cost --tsv on a slower one.
- Weekly spend is not a status row, on purpose.
- Version: 0.49.282. origin/claude/setup-actions-node24 and
  LeavesJ/confident-archimedes-b76781 (stale since 10-08, no open PR) also carry
  0.49.282; renumber if either lands first.
