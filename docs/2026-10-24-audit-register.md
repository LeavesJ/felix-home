# Felix audit register, 2026-10-24

## What this is

On 2026-10-23 you said that, reviewing what is built, you found many designs and builds incomplete or naive, and asked for all of them to be addressed in this session. This is the list, and the order they are being fixed in.

How it was made:

- **Sweep.** Fourteen sweepers read Felix from different angles: the open items in the 48 pending handoff notes; the claims in the README, docs/direction.md and the roadmap, checked against the code; every place work can wait or fail with no one told; the verification pipeline; four groups of engine code; read-only commands run against the real home; assumptions that hold only on this laptop; and four gaps a critic named after the first round.
- **Merge.** They returned 202 findings. Duplicates were merged into 158.
- **Refute.** Two skeptics tried to refute each high finding and one each medium one, by reading the cited lines or by making the scenario happen in a throwaway fixture.
- **Result.** 96 survived (21 high, 44 medium, 31 low after the skeptics' corrections), 22 were refuted, and the 40 low findings were not checked.

Nothing here was measured by running the suite or a gate. Each scenario was read from the code, and many were reproduced in a fixture by a skeptic.

## The order of work

The defects are grouped into batches, and no two batches touch the same file, so they are built in parallel, each in its own worktree. Each batch goes through the engine build you set: a contract, blind tests written from the contract alone, red first, the fix, an adversarial review, and a second round when the review finds a major. The order follows your priorities: what stalls silently first, then what slows each item, then wrong verdicts and lost work, then the rest.

| # | Batch | Defects | Needs you |
|---|---|---|---|
| 1 | Time limits on suite, gate, CI and probe commands | 3 | no |
| 2 | Land tick never refuses or waits silently | 7 | no |
| 3 | Session start names what waits | 6 | no |
| 4 | Status shows a stopped lander, hooks off and ungoverned projects | 3 | no |
| 5 | Lander install guard and off-Mac notifier | 3 | yes |
| 6 | Pulse and discovery never promise what cannot happen | 7 | no |
| 7 | Stop hook and cloud session never let go silently | 5 | no |
| 8 | Change-scoped verification and receipt freshness | 3 | no |
| 9 | Inventory speed and true owners | 4 | no |
| 10 | Escape channels see what they claim | 6 | yes |
| 11 | Evidence policy gives true verdicts | 3 | no |
| 12 | Judge base and binding read what is committed | 6 | no |
| 13 | felix CLI trust and binding | 5 | no |
| 14 | Lessons, handoff and maintenance records stay true | 4 | no |
| 15 | Bootstrap protects the right branch with a passable gate | 2 | no |
| 16 | Deny floor judges effects on every tool | 3 | yes |
| 17 | Commission grant cannot be self-given or misdescribed | 6 | yes |
| 18 | Ledger reads dead hooks and iCloud duplicates | 2 | no |
| 19 | Capability detection and omission surfaces | 5 | no |
| 20 | Obligation proposals for new projects | 2 | waits for the design |
| 21 | README claims match the engine | 4 | no |
| 22 | Snapshot builds, is tested, and ships the Stop fix | 4 | yes |
| 23 | Cloud kit truthfulness | 2 | no |

## What needs you

- **Batches 10, 16 and 17** change escape rows, deny rows and the PreToolUse matcher, and the commission grant. They are built and tested, then opened as drafts labelled needs-founder. Only you merge them.
- **Batch 22** fixes the snapshot build. Publishing the public snapshot stays your act.
- **The CI time limit** in batch 1 is a .github/workflows change, which is an escape channel, so it goes in a separate PR for your merge.
- **The off-Mac alert (C018)** was decided on 2026-10-24: the GitHub app. Felix mentions you in one standing issue on the repository.
- **C044 (choosing tests by reach) and batch 20 (C023, C091, essentials a project never names)** wait for the design document, which comes to you separately for approval because it changes what a green verdict means.

## Batch 1: Time limits on suite, gate, CI and probe commands

Files: `engine/harness/tests/run`, `engine/harness/tests/parts/0007-the-parallel-runner.sh`, `.github/workflows/gate.yml`, `engine/harness/lib/probes.sh`. Founder stop: none

- **C004** (high, silent-stall) Suite, record, gate and CI job have no time limit
  - What goes wrong: A part waits on a FIFO or a signal that never comes on the 2-core runner, the class slot 3f and R13-R15 dealt with locally. The job runs 360 minutes, the PR reads `pending` on the stuck-PR page the whole time, the tick skips it every tick, and about 18% of the 2,000-minute Free quota goes to one hang. No failure is …
  - The fix: Set `timeout-minutes: 90` on the gate job (2x the longest observed run) and something small on the other job. A .github/workflows change is an execute escape, so it lands on the founder's merge. Have the stuck-PR page name a check running longer than its …
- **C041** (medium, silent-stall) Probe, evidence and qualification commands (including in Stop) run with no time limit
  - What goes wrong: In an Elenchus checkout whose receipt matches the tree, create_app blocks on an unreachable service, or a probe reads a file evicted by iCloud's Optimize Storage. Every stop shows 'Checking the gate' for ten minutes, then the host kills the hook and the session goes on with no hold and no record. An unattended …
  - The fix: Set a `timeout` on every hooks.json entry (for example 10 s pre-tool, 60 s stop and session-start), which the host enforces without adding a runtime to the enforcing path. Write a start marker in state/ at hook entry and remove it at exit, so the next …
- **C019** (low, machine-bound) Nothing keeps the Mac awake during unattended work, and nothing records that it slept; direction row 16 assumes it is kept awake
  - What goes wrong: The founder starts a record and an 8 h night and leaves. The Mac's default energy settings put it to sleep after 1 h on battery. The suite freezes for 9 h. The night's deadline passes with nothing done, and the report says "the granted time ran out". Gate timing and cost numbers read 9 h as gate time. On a user's …
  - The fix: Start `caffeinate -i -w $$` from cmd_gate, tests/run --record-assertions and the trampoline, and `caffeinate -i -t <seconds left>` from `felix overnight --start`. Note in the README and the install guide that -i does not stop lid-close sleep on battery. At …

## Batch 2: Land tick never refuses or waits silently

Files: `engine/harness/lib/green-tick.sh`, `docs/2026-10-15-land-on-green-contract.md`. Founder stop: none

- **C011** (high, silent-stall) A refusal made while the author's gate is still running stays final (A13)
  - What goes wrong: A session marks its PR ready, and CI goes green before its 3-4 h local gate finishes. The tick refuses "no green receipt" and posts one banner. The gate goes green an hour later. The tick never looks again, and nothing tells anyone the PR can now land. It waits until main moves, which may be days while nothing else …
  - The fix: Treat a refusal whose only blocker is the receipt (unverified, tree, stale) as a skip that every tick checks again. Before calling felix merge, compare the worktree's receipt mtime or tree id with the refused row's time. Keep finality for blockers that need a …
- **C001** (medium, silent-stall) Deploy, and so all landing, waits on any gate or suite running anywhere on the Mac
  - What goes wrong: (a) The founder's goal is that the suite never idles. The suite takes 3-4 h locally, and several sessions run gates. After the tick lands an engine PR there may be no moment when pgrep finds nothing, so no PR of any kind lands. The only trace is one row and one banner. An orphaned tests/run (memory 10-22: an orphan …
  - The fix: Narrow the A14 check to processes that run the engine being replaced. Match the home checkout's path or the cache entry in their argv or cwd (ps -o args plus lsof -d cwd), not every gate.sh and tests/run on the machine. Name the blocking pids in the row. Age …
- **C097** (medium, machine-bound) The land tick's `gh auth status` fails when any account on any host has a stale token, so one dead token stops all landing
  - What goes wrong: A user also has a GitHub Enterprise host, or a second github.com account, whose token has expired. gh works for the governed repository, but every tick stops at the auth check. One deduplicated row and one notification are written, and no PR lands until the unrelated token is fixed.
  - The fix: Check only the host the repository lives on with `gh auth status --hostname github.com --active`, or treat `gh pr list` succeeding as the auth check.
- **C082** (medium, silent-stall) An engine merge made by hand strands land-on-green until someone deploys by hand
  - What goes wrong: A session lands an engine PR with `felix merge` (#458), or the founder merges an escape PR on GitHub (#455), then fetches, as sessions routinely do in shared refs. Every later tick exits at the trampoline. No PR lands until a person runs `felix install` in the home, and the only signal is one macOS banner.
  - The fix: When main's version is missing but the previous accepted entry exists, let the trampoline run that entry's tick in deploy-only mode, which merges nothing (A11 already separates the two). Or have cmd_merge, after an engine merge in the home's project, run the …
- **C083** (medium, naive) A deploy can never repair a cache entry at main's version holding other bytes, and landing plus deploy share one 30-minute watchdog
  - What goes wrong: Under load, a landing tick's felix merge plus install exceeds 30 minutes, TERM lands mid `claude plugin install`, and a partial entry is left at main's version. Or a branch's install (a worktree install re-points the marketplace, per memory), or two PRs carrying the same placeholder version, leaves an entry at main's …
  - The fix: In `_gt_deploy`, when the entry at main's version fails felix_accepted_deploy_diff, move it aside before installing (A1 already says it is not main's). Run the deploy after a landing in the next tick, as A11 does for owed deploys, so each gets its own …
- **C100** (low, naive) The post-deploy check after land-on-green cannot fail on broken hooks
  - What goes wrong: A PR changes lib/deny-read.sh in a way gawk accepts and BWK awk aborts on. CI passes, the author's local gate ran with --quick, land-on-green merges and deploys, and the ledger says 'deployed ... passed'. From then on every session on the laptop allows every Bash row, with no record (finding 1). Nobody is told.
  - The fix: After install, run the deployed cache entry's hooks with the machine's own bash and awk. pre-tool, given a payload that one of the project's deny rows names, must exit 2. stop, on a dirty fixture checkout with no receipt, must return a block decision. …
- **C104** (low, naive) Land brakes carry no actor: --resume clears a person's hand pause with no ledger row, and --install/--uninstall arm or disarm landing without a row
  - What goes wrong: The founder runs `felix land --pause "hold until I read #460"`. A session sees 'paused' on the stuck-PR page and runs `felix land --resume`. The next tick lands #460, and the ledger shows no resume, no resumer and no reason. In the same way, a session can run `felix land --uninstall`, and landing stops with no ledger …
  - The fix: Write ledger rows for resumed, installed and uninstalled, carrying the session id or '-', and send them through _gt_say. Refuse --resume over a hand-written reason unless --override is given, and record it when it is.

## Batch 3: Session start names what waits

Files: `engine/harness/hooks/session-start`, `engine/harness/hooks/pre-tool`, `engine/harness/lib/overnight-stop.sh`, `engine/harness/lib/pr-status.sh`, `engine/harness/lib/pr-status-state.sh`. Founder stop: none

- **C002** (high, silent-stall) PRs waiting on a session or skip row are never notified or aged
  - What goes wrong: A PR is gated green in a scratch clone or a cloud session, or its worktree gets pruned, or main moves under it and it conflicts. Its CI is green. Every 5 minutes the tick writes one ledger row (row_once) and never merges it. Nobody is notified, and no session start or end mentions it. It sits until the founder happens …
  - The fix: Treat a green-CI PR that waits on session, conflict or CI-pending past a bound (say 30 minutes) as a notifiable `stuck-pr` event, sent once per head. Add one line for each such PR to session-start's closing context and to `felix pulse`/`felix status`, read …
- **C038** (medium, silent-stall) The overdue snapshot reaches the founder only as an unnamed 'N due' count, which has not been zero since 10-10 and partly cannot clear
  - What goes wrong: Every session since 10-17 opens with '· 5 due'. One of the five is work the unattended tick already does, and one is a decision only the founder can make. The badge is identical every day, so a 27-day-old publication gap carrying a wrong-verdict fix looks the same as routine upkeep. The founder learns of it only by …
  - The fix: Add a `founder` column, or a value of the trigger column, to maintenance.tsv so that a founder-only row is named on the screen line ('snapshot waits on your yes, 13 days over'). Have _gt_deploy's verified deploy count as a 'deployed' run, by appending to a …
- **C069** (medium, silent-stall) Decisions deferred overnight are shown only to the session that owned the night; rows from 09-23 still wait unseen
  - What goes wrong: At 01:00 a night ends after two continuations that called no tool, or its session freezes. The founder starts a new session in the morning. Felix says nothing about the queue of decisions waiting on him, so they wait until he remembers `felix overnight --report`. This has already gone a month.
  - The fix: Whenever deferred.tsv is non-empty, print at every session start: "N decisions deferred overnight wait on you (oldest <date>): felix overnight --report". The queue is a fact about the project, not the night's direction. Also send it through felix_notify when …
- **C029** (medium, silent-stall) When PreToolUse cannot judge, it allows the call and leaves no record anywhere
  - What goes wrong: A governed checkout's deployed engine cannot load lib/deny-read.sh (an iCloud-style rename, a bash-3.2-only construct, a BWK awk abort, or process exhaustion as on 09-25). From then on, every Bash call that a deny row names runs: force pushes, --no-verify, rewriting .felix. The banner still says Felix governs the …
  - The fix: Give each hook an inline prologue that needs no library and no fork: `_felix_fault(){ printf '%s\t%s\t%s\n' "$hook" "$1" "${sid:-}" >> "${FELIX_MEMORY:-$HOME/.felix/memory}/hook-faults.log" 2>/dev/null; }`. It uses only builtins, so it still works under …
- **C027** (high, machine-bound) On an organisation-owned repository every member's pull request reads 'outside, waits for nobody', so red and conflicting PRs drop out of 'needs you'
  - What goes wrong: A team governs acme/app. Alice's PR fails CI and conflicts with main. `felix monitor` shows it under neither 'pull requests waiting on a session' nor 'needs you', only as '1' in 'pull requests waiting on nobody'. Nobody is told it needs work. A green PR of hers likewise never shows as ready for the lander, though the …
  - The fix: Base 'outside' on isCrossRepository only, or widen the governed account to a set: the repo owner, gh's authenticated login, and a project.json list of accounts. Keep the author check only to tell bots apart.
- **C087** (low, naive) The stuck-PR page names the wrong actor for trust-base PRs and for PRs whose gate run the tick cannot read
  - What goes wrong: A trust-base PR is shown as needing an attended session, so a session or the founder spends time on a PR the tick would have landed. A PR whose rollup is green but whose gate run gh cannot read (the tick writes 'skip: gate run not green: GitHub could not be asked') is shown as waiting on the lander, which will never …
  - The fix: Build the page's green from `_felix_merge_gate_held`, as the tick does, and let a same-head skip row move the state to unknown or session. Make the trust-base rule one rule: either the tick holds those PRs (T1) or the page drops needs-attended.

## Batch 4: Status shows a stopped lander, hooks off and ungoverned projects

Files: `engine/harness/lib/status.sh`, `engine/harness/lib/lifecycle.sh`, `engine/harness/lib/guard.sh`. Founder stop: none (detection only; a deny row against disableAllHooks would be his)

- **C005** (high, silent-stall) A paused or stopped lander shows on no surface beyond a macOS banner
  - What goes wrong: The migration kit's prepare.sh retires both jobs (memory new-laptop-migration). Or the founder logs out, or the Mac reboots and sits at FileVault, or the plist is removed, or a `felix land --install` bootstrap fails. Landing stops. No row, banner or session line says so. The founder learns only when he notices PRs not …
  - The fix: Have the trampoline write `land/heartbeat` (epoch and exit reason) on every run, before any dedupe. Add a `lander` row to felix status (installed, loaded, paused, heartbeat age, newest row). Add a session-start line when the plist exists and the heartbeat is …
- **C014** (high, incomplete) Settings that switch Felix hooks off (disableAllHooks, enabledPlugins false) go undetected; status says ok
  - What goes wrong: An agent (or a stranger's tooling) writes {"disableAllHooks": true} to .claude/settings.local.json in a governed checkout. That file is usually gitignored, so no diff shows it. Every later session there runs with no deny rows, no Stop hold, no ledger and no banner. `felix status` keeps printing `settings ok`, and …
  - The fix: Extend the settings row, or add a `hooks` row: read disableAllHooks at user, project and local level, and enabledPlugins false at project and local level, for the checkout. Report each as a value, never as ok. Add deny rows (Write, Edit, Bash) for …
- **C115** (medium, silent-stall) A project with no guessed gate looks governed everywhere a person looks, and no stop is ever checked
  - What goes wrong: A Java team runs `felix new` on a Gradle repository and gets 'gate guess none' once in the output. From then on every session shows 'Felix: app', doctor lists capabilities, status says none-run, and every agent stop passes unchecked. 'Nothing due' and 'nothing is being checked' render identically, which is the …
  - The fix: With no gate, make the screen line `Felix: <name> · no gate, stops unchecked`. Have doctor print a 'gate: none declared' line, and status print `gate none no-gate`. Extend the guess to gradle/mvn/bundle/composer/dotnet/swift, and to python3.

## Batch 5: Lander install guard and off-Mac notifier

Files: `engine/harness/lib/green-install.sh`, `engine/harness/lib/notify.sh`. Founder stop: yes: which off-Mac channel and device reach him (C018)

- **C018** (high, incomplete) No signal reaches the founder away from the Mac: the only notifier is a local macOS banner, used by the land job alone, and its delivery is never checked
  - What goes wrong: The founder is away for 8 hours. At 01:00 the tick refuses a PR with "commission receipt stale", or pauses on deployed-unverified, or the trampoline writes deploy-owed. At most one banner is posted to a Mac whose display is asleep, or under a Focus mode, or from a sender that may not be registered. Nothing reaches his …
  - The fix: Add one lib function, felix_notify KIND DETAIL, that every unattended path calls: the tick, the trampoline, overnight end and defer, pulse failure, a gate past its deadline. Primary channel: open or update one GitHub issue per project titled "Felix needs …
- **C013** (high, incomplete) felix land --install outside the home installs a second lander that only ticks the home
  - What goes wrong: A new user clones LeavesJ/Felix, governs `myapp`, and runs `felix land --install` from myapp. They see 'land on green is installed for myapp'. myapp's PRs never land, and `felix land --status` in myapp shows installed yes / loaded yes / last none forever. Meanwhile, every 5 minutes the job fetches LeavesJ/Felix. …
  - The fix: Make _gt_install refuse unless felix_self_governed holds for the project's checkout and PROJ is the project the home resolves to. Until per-project landing is built, say so in the refusal. Gate _gt_deploy on the home's origin being a repository the person …
- **C042** (low, machine-bound) Land on green and scheduled loops are launchd/macOS-only; on Linux, install leaves macOS files
  - What goes wrong: An engineer on a Linux laptop, the corporate user of direction row 28, adopts Felix. `felix land --install` fails at launchctl. Land on green, the one loop that runs without the founder, cannot run, and the pulse runs only if they write a cron line by hand. felix status then still shows the schedule as unknown. Felix …
  - The fix: Add a scheduler adapter in green-install.sh and the pulse: a systemd --user timer, else a crontab line written with a marker comment, chosen by uname. Report it through one `felix_schedule_state` function that status.sh reads for both backends, and use …

## Batch 6: Pulse and discovery never promise what cannot happen

Files: `engine/harness/lib/pulse.sh`, `engine/harness/lib/discover.sh`, `engine/harness/lib/reach-read.sh`, `engine/harness/lib/say.sh`, `engine/harness/lib/route.sh`, `engine/harness/hooks/session-end`. Founder stop: none

- **C016** (medium, silent-stall) Discovery never refreshes where TMPDIR is unset or not private (the Linux default), and the pulse says the next session will refresh it
  - What goes wrong: A stranger installs Felix on Ubuntu, where TMPDIR is unset by default, or on any machine whose TMPDIR sits under /tmp. Every SessionStart starts a discovery refresh that runs nothing. The catalogue is never built, or stays at its last value forever. No context line, ledger row or status row says so, and the pulse …
  - The fix: Give felix_neutral_dir a Felix-owned fallback when TMPDIR fails: a 0700 directory under $FELIX_HOME/state/neutral or ${XDG_RUNTIME_DIR}, checked with the same ancestor rules. When no private directory exists, write a `discover-unread <why>` row the pulse and …
- **C043** (low, silent-stall) Discovery refresh lock is never broken after a killed run, while the pulse promises a refresh
  - What goes wrong: The Mac sleeps or reboots, or the process is SIGKILLed, while the weekly clone-and-inspect runs. state/discover/.lock survives. Every later session start sees a stale cache, calls refresh_bg, and returns at the mkdir. Discovery stops for good, while README.md:552 still promises weekly refreshes and the daily pulse …
  - The fix: Break a lock older than 30 minutes, as reach.sh does. Write one line per refresh outcome (ran, failed, locked-since) to state/discover, and have the pulse print the last outcome and its age rather than a promise.
- **C055** (high, naive) Every engine release invalidates the discovery cache, so it re-clones far more often than weekly
  - What goes wrong: On felix-home, 0.49.300 to 0.49.307 deployed in about five days, so the first session after each deploy clones and inspects every candidate again over the network: about seven refreshes where README promises one. The same holds for any adopter after each plugin update.
  - The fix: Stamp only the matcher and the rules file, not the engine version, or make the README say 'weekly and after each engine update'.
- **C093** (medium, naive) One nested repository anywhere in memory stops the whole backup, and the refusal surfaces only after 3 days
  - What goes wrong: A session or workflow builds a fixture repository under the memory root, as audits routinely do. The next pulse backs up nothing at all, lessons and ledgers included, and keeps doing so. For 3 days no surface says so, and after that a person still has to find and ignore the fixture by hand.
  - The fix: Stage with `git add -A -- . ':(exclude)<each new gitlink path>'`, commit the rest, and print the excluded paths as a refusal line. At session start, read state/pulse.status.tsv and name any backup line containing 'NOT backed up' or 'nested' on day 1, not only …
- **C094** (low, overclaim) A 'verified' push to a remote on the same disk is stamped as memory having left this disk
  - What goes wrong: iCloud upload is stalled (offline, quota, or Optimize Mac Storage). The pulse writes 'pushed and verified' daily, status shows 0 days, and the banner stays quiet. A disk failure then loses the memory and its 'backup' together. Any adopter who points the backup at a local bare repo gets the same false assurance.
  - The fix: When the remote URL is a filesystem path, write a different stamp (pulse.last-local-push). Make the status row and banner say 'copied to a repository on this disk' and leave the off-disk age 'never'. Optionally, for a path under ~/Library/Mobile Documents, …
- **C036** (medium, incomplete) Everything a cloud session records dies with the VM, and the warning written for 'memory exists in one place' cannot fire there
  - What goes wrong: A cloud session's gate fails. The catch goes to mistakes.log, and the Stop guard asks for a lesson. The session runs felix lesson, the guard is satisfied, and the session ends. The lesson, the catch, any felix route --ack decline (decisions.log), the says.log record and the ledger's zero rows vanish with the VM. The …
  - The fix: Have felix_mem_root honour CLAUDE_CODE_REMOTE_MEMORY_DIR, or a Felix variable set in the cloud environment, when present. Otherwise, when CLAUDE_CODE_REMOTE=true, have session-start say that memory here is ephemeral and dies with the VM. At SessionEnd, push …
- **C080** (medium, naive) Felix's records keep prompts and denied commands verbatim, and the memory backup commits them with no credential scan
  - What goes wrong: A user pastes a token into a prompt, or a refused command carries one. It lands in says.log and routes.log and is pushed to the memory remote by the daily pulse. For another user that remote may be GitHub. Felix treats the same blob in code as a 'disclose' escape.
  - The fix: Run bin/secret-scan's patterns over the felix_say and felix_route_log text before writing and redact matches. Have pulse refuse to push a memory commit whose added lines match.

## Batch 7: Stop hook and cloud session never let go silently

Files: `engine/harness/hooks/stop`, `engine/harness/hooks/user-prompt`, `engine/harness/lib/monitor.sh`, `projects/felix/routes.tsv`, `.claude/cloud/provision`, `.claude/settings.json`. Founder stop: none

- **C030** (low, silent-stall) Stop hook ends a session unheld and unrecorded when a lib fails to load or project.json is unreadable
  - What goes wrong: project.json in the iCloud home is evicted by Optimize Mac Storage or replaced by a ' 2' copy, or a deploy carries a lib that does not load under macOS bash 3.2. A session edits the tree and stops with nothing verified. The hook exits 0, the work ends unheld, and verification.log has no row, so the stop looks exactly …
  - The fix: Guard each source with the same no-library fault append used for pre-tool. On a fault, emit a non-blocking `systemMessage` at the stop, which is the end-of-session moment the charter allows: 'Felix could not judge this stop: <lib> did not load; nothing was …
- **C035** (medium, silent-stall) A cloud session that ends on an unrun or red gate is let go as a 'debt' that only the dying VM records, and CI never runs on its branch
  - What goes wrong: The founder starts a cloud session from claude.ai while the Mac sleeps. The session edits files. At Stop it is held once with 'Do not describe this work as complete until it has passed. felix gate'. The gate takes about 40 minutes, longer than any single foreground call, so the session stops again on the same tree. …
  - The fix: When CLAUDE_CODE_REMOTE=true, the release must leave a trace that travels with the branch. Options: require a pending handoff line or a commit trailer naming the unverified tree, or have the hold tell the session to open a draft PR so CI's gate runs and …
- **C102** (low, silent-stall) Prompt-hook timeouts go unrecorded, and one before the session mark drops the Stop check on committed work
  - What goes wrong: A one-prompt workflow agent's prompt hook times out before it writes the mark. The agent commits all its work, leaving a clean tree, and stops. The Stop hook lets it go with no hold and no verification row, which is the 'committing skipped the completion check' defect the mark was built to close.
  - The fix: Write the session mark in session-start, which already has session_id and runs before any prompt; the first mark still wins. Keep the user-prompt write as a fallback. Record a prompt hook that did not finish (a start line written with builtins on entry, …
- **C106** (medium, naive) Even when provision works, the routes name skills the cloud does not have under those names, and the Stop hook then reports the play as skipped
  - What goes wrong: Once provision succeeds (after codeload is allowed), a session routed to build is told to reach for superpowers:brainstorming. The Skill tool knows only 'brainstorming'. If the model finds and uses the bare name, the transcript's attributionSkill is 'brainstorming', felix_route_step_used says unused, and the Stop hook …
  - The fix: In a remote session, either install through `claude plugin install`, which the handoff saw working through the proxy, so names match, or have the router and felix_route_step_used map plugin:skill to the bare name when the owner is a toolbox fetch entry.
- **C107** (medium, silent-stall) provision fails silently: its log has no reader, --report has no caller, and its worst-case run is far beyond the 120 s hook timeout
  - What goes wrong: The environment's network blocks or blackholes codeload. Claude Code kills provision at 120 s, partway through. No skill or agent arrives, and the superpowers preamble is never printed. Nothing in the session says so. The router still names superpowers skills (the 09-28 run routed to an uninstalled …
  - The fix: Cap the whole run under the hook timeout: -m 15, no retry for a src@sha that already failed. On --session-start, print one line of context naming what is MISSING (the --report output). Have session-start read provision's exit or a status file and say the …

## Batch 8: Change-scoped verification and receipt freshness

Files: `engine/harness/lib/verify.sh`, `engine/harness/tests/receipt.sh`, `projects/felix/gate.sh`, `engine/harness/tests/parts/0100-merging.sh`, `engine/harness/tests/parts/1010-the-record-this-branch-carries.sh`, `docs/2026-10-12-gate-friction-design.md`, `docs/2026-10-12-gate-friction-contract-a.md`, `docs/2026-10-18-gate-friction-contract-d.md`. Founder stop: none

- **C045** (low, slow) Suite receipt goes stale on any landing on main
  - What goes wrong: A docs-only PR lands on main while a branch's 3-hour suite is running, or the branch fixes a typo in README after its suite passed. The suite's answer cannot change, because _rtn3 and _rtn4 see the same engine tree and version, but reuse is refused and the full suite runs again. This is the user's 'small edits run the …
  - The fix: Key the receipt's origin component on what 1010 reads, `git rev-parse origin/main:engine` plus origin's plugin.json version, not on the commit. Then add an impact map per part: the engine paths it sources or fixtures, derived from the driver's sourcing and …
- **C003** (high, incomplete) A gate --quick receipt lets felix merge land a tree whose suite never ran
  - What goes wrong: A session short on time runs `felix gate --quick`, which writes a current green receipt with field 5 `tests`, and then runs `felix merge`. Every blocker passes, C9 is not asked because the receipt says skipped, not reused, and gh squash-merges a change whose test suite never ran anywhere. That includes an engine …
  - The fix: In felix_merge_blockers, when the receipt is current and field 5 is not `-` (or field 6 holds `tests:skipped`), emit `unverified tests the gate skipped <list>`. Alternatively, route it through _felix_merge_gate_held, as tests:reused already is. The spec and …
- **C110** (medium, naive) The gate's cloud check compares event-to-hook pairs only, so a change to the plugin's matcher never reaches the cloud's deny floor
  - What goes wrong: A deny row is added for a tool the matcher does not cover, so hooks.json's PreToolUse matcher widens to, say, add Glob|Grep|WebSearch or mcp__.* and close a gap. settings.json keeps the old matcher, and the cloud check reads ok. In every cloud session, pre-tool, and so every deny row, never runs for those tools. The …
  - The fix: Read and compare the matcher string, plus async and timeout, per event as part of the pair: `event<TAB>matcher<TAB>hook`. Move the check into a bin/ command so felix qualify can pin a matcher-drift mutation.
- **C044** (medium, slow) No change-scoped verification. Held for the design.

## Batch 9: Inventory speed and true owners

Files: `engine/harness/lib/inventory-chips.sh`, `engine/harness/lib/lost-work.sh`, `engine/harness/lib/inventory-host.sh`, `engine/harness/lib/inventory-items.sh`, `engine/harness/lib/inventory.sh`, `docs/2026-10-18-lost-work-page-contract.md`. Founder stop: none

- **C050** (medium, slow) felix inventory/monitor take about 3 minutes because the chip reader rescans transcripts
  - What goes wrong: The founder opens the lost-work page and waits more than 3 minutes. A session-end notice line, owed as roadmap step 7, could not call the inventory within a hook budget. On a laptop with a longer history the wait keeps growing.
  - The fix: Use two passes. First grep only the proposal lines (spawn_task/start_session with input) and collect their tool_use ids. Then grep -F -f those ids for the matching result lines. For each scoped file, cache (mtime, size) and its parsed proposals in the …
- **C028** (high, naive) Plugins' SDK sessions (security-guidance's Stop-hook reviewer) are read as the worktree's own session: a false 'blocked' and the wrong owner, which can hide the person's open question
  - What goes wrong: A person's session ends with 'Should I merge #12?'. The Stop hook then starts the security reviewer in the same worktree, which becomes the newest session. The inventory reads the reviewer's end instead. If the reviewer ends on StructuredOutput, the worktree shows as 'blocked' an hour later with the reviewer's id. If …
  - The fix: When choosing the owner and reading question/blocked, skip session files whose records carry "entrypoint":"sdk-*" (or whose first human text is a queue-operation from a hook). Separately, never treat a pending StructuredOutput call as a wait.
- **C047** (medium, naive) An unreadable session-records root reads as 'sessions read', complete zero
  - What goes wrong: felix monitor runs where ~/.claude/projects (or $CLAUDE_CONFIG_DIR/projects) exists but cannot be listed, for example a sandboxed shell or a config directory owned by another account. The page says blocked 0, question 0, live 0 as complete, and the founder is told no session waits on him. That breaks the 'unknown, …
  - The fix: In _fi_host_root, require `-r` and `-x` and a successful `find "$r" -maxdepth 1` read. Otherwise return a distinct status that sets the sessions and chips cover rows to unknown, with 'records root not readable'. Add the 000 case to part 1570 or 1585.
- **C025** (low, naive) The lost-work page hides helper worktrees whose spawning session is dead, including 10 holding unpushed commits 12-15 days old
  - What goes wrong: A workflow dies (memory: workflow agents die together), and its agents' per-item commits sit only in their agent-*/wf_* worktrees. The founder runs felix monitor. The page shows "helper worktrees 14" on the collapsed line and lists none of those refs under "work that never reached a PR". Implementation commits whose …
  - The fix: In the adapter, make helper=yes only while the spawning session is live: its record time or its <sid>/ directory written within --live, read the way felix_inv_host_dir already reads activity. When the spawner is dead, use a new word such as helper-orphaned, …

## Batch 10: Escape channels see what they claim

Files: `engine/harness/lib/escape.sh`, `engine/harness/lib/classify.sh`. Founder stop: yes: escape rows (docs/direction.md as a founder path, wider durable and execute channels)

- **C015** (high, naive) A workflow file whose name git quotes is never seen as an escape, so felix merge lands it without the founder
  - What goes wrong: An agent's branch adds `.github/workflows/déploy.yml`, a job that runs on push with the repository secrets. felix escapes reports nothing and felix merge says the rest escapes nothing. Land on green or the session itself then merges it with no founder decision, although `execute` is the one channel risk.tsv calls …
  - The fix: Read every name list with `-c core.quotePath=false` and `-z`, splitting on NUL through a scratch file as bin/secret-scan's _names already does. As defence in depth, any changed-path line that begins with a double quote becomes an `unknown CHANGED-PATHS` row, …
- **C021** (high, overclaim) The durable channel keys on three directory names and upper-case SQL, so common destructive migrations merge without a person
  - What goes wrong: A governed Rails or Spring project adds a migration that drops a table or column. felix_escapes prints nothing, felix merge (or land-on-green) merges it and reports nothing escaped. The data loss happens on deploy, where a revert cannot reach.
  - The fix: Match migration paths by effect class: db/migrate, db/migration(s), */migration(s)/, drizzle/, liquibase changelogs, schema.rb/structure.sql. Make the SQL rule case-insensitive and include DROP COLUMN/SCHEMA/DATABASE, unqualified UPDATE/DELETE, and ORM verbs …
- **C081** (medium, naive) The execute channel names only .github/workflows and actions, not the scripts those jobs run with main-only secrets
  - What goes wrong: A product's push-to-main deploy job runs ./scripts/deploy.sh with environment secrets that only main can read. A branch changing that script merges with no escape, and the changed script first runs holding those secrets after merge. That is the effect the channel exists to stop, but it keys on the file name.
  - The fix: Parse workflow files on main for `run:` paths and `uses: ./` local actions that run on push, schedule, workflow_run or release, or under an environment. Treat changes to those paths as execute. Include root action.yml and reusable workflows.
- **C006** (medium, incomplete) A PR editing docs/direction.md lands on green unattended
  - What goes wrong: A session folds a founder decision into docs/direction.md and opens a normal (non-draft, unlabelled) PR, as the constitution's 'records merge on green' habit suggests. CI passes, a home worktree holds the head, and the tick runs felix merge and lands it unattended. A direction change binds without the founder's yes, …
  - The fix: Land #452, or add `docs/direction.md` to _gt_direction's case. Add an assertion that a PR touching only docs/direction.md gets a founder row. Then put docs/direction.md first in read_lines at session-start:532.
- **C075** (medium, naive) Basename matching of enforcing tables fires the verifier escape on ordinary product files such as Nx project.json
  - What goes wrong: In an Nx monorepo every apps/*/project.json edit that changes a value removes its old line. felix merge stops with 'verifier ... this decides what stops, and the change removes from it' and hands an ordinary build-config change to the founder. That inflates founder interruptions, the binding objective.
  - The fix: Apply FELIX_ESCAPE_TABLES only when the changed path resolves to the project's own table (felix_table_rel
- **C077** (medium, silent-stall) The merge boundary drops the credential scan with no unknown row when bin/secret-scan is not executable
  - What goes wrong: An install or sync loses the exec bit, or a copy drops bin/. A branch adding a key then passes the gate (secret skipped) and felix_escapes prints no disclose and no unknown row. felix merge reports nothing escaped. For products, whose gates do not run secret-scan, this is the only credential check.
  - The fix: Add an else branch printing 'unknown ADDED-LINES the secret scan is missing or not executable, so nothing says the added lines hold no credential'. Make the gate's skip a failure for a self-governed repo.

## Batch 11: Evidence policy gives true verdicts

Files: `engine/harness/lib/evidence.sh`, `engine/harness/templates/evidence.tsv`, `engine/harness/lib/intake.sh`, `engine/harness/lib/final-filter.sh`, `engine/harness/lib/review.sh`. Founder stop: none

- **C024** (high, naive) The seeded evidence policy gives wrong verdicts that felix merge enforces: false gaps on co-located tests, n/a on monorepos, met by any file under tests/
  - What goes wrong: Go repos (and a Rust workspace whose code sits under crates/*/src) never merge through felix merge or the land-on-green tick unless the change also adds a file under a top-level tests/ directory. Clearing that means editing evidence.tsv, which is an escape table, so it goes to the founder. Meanwhile a monorepo change …
  - The fix: Treat grep exit 2 as unknown, which blocks, and split rows with awk -F'\t'. Make requires relative to each changed path (same directory or basename stem: x_test.go, x.test.ts, test_x.py, a tests/ mirror) and let when match at any depth instead of only under …
- **C074** (low, naive) The final-filter check refuses only a pipe tail; `make test || true`, `; exit 0`, `true` and `echo ok` are admitted as evidence that cannot fail
  - What goes wrong: An obligation's evidence or a commissioning check is written as `pytest || true`. Adding a row is free at the merge boundary. It reads SATISFIED or met whatever the tests do, and the obligation never blocks. The validator exists for exactly this class and says nothing.
  - The fix: Refuse any judged column whose outcome set contains no failure path (no n or g), not only those ending in h. Keep the admit-when-unsure list. Name the reason 'no path through it can fail'.
- **C078** (low, naive) The reviewed channel's isolation check is opt-in: a pass with no --in is recorded and clears the escape
  - What goes wrong: The session that edited an Elenchus rubric records `felix review --pass --by <name>` without --in on its own tree. escape.sh:409 reads it as pass and the doctrine change merges with nobody independent. A reviewer that honestly states it ran in the live tree is refused, so stating location is penalised.
  - The fix: Require --in for --pass, and refuse a pass whose --in resolves to the reviewed root, to a directory at a different HEAD, or to none. Record the reviewer's worktree HEAD and compare it to the tree id.

## Batch 12: Judge base and binding read what is committed

Files: `engine/harness/lib/resolve.sh`, `engine/harness/lib/exceptions.sh`, `engine/harness/lib/ready.sh`, `engine/harness/lib/stack.sh`, `engine/harness/lib/commission-provider.sh`, `docs/2026-09-21-where-felix-stands.md`. Founder stop: none

- **C009** (high, naive) Local origin/main ref is trusted for the judge base and the exception grant, but plain writes can move it
  - What goes wrong: In an attended session, `cp .git/refs/heads/mine .git/refs/remotes/origin/main` (or a Write to that path) points origin/main at a local commit whose projects/felix/exceptions.tsv grants the session an exception and whose engine version names an entry it installed. felix gate and felix merge then read the forged base …
  - The fix: In felix merge and before the gate's exception read, compare refs/remotes/origin/main with `git ls-remote origin refs/heads/main`, or fetch it, and refuse on mismatch (merge already needs the network for gh). Add Write, Edit and Bash redirect, cp and mv rows …
- **C010** (medium, naive) Live enforcing tables are read from the home working tree, unguarded against uncommitted edits
  - What goes wrong: A session in any worktree runs `sed -i '/engine_deployed/d' /Users/a14808/Documents/Felix/projects/felix/obligations.tsv`, or makes the same edit carelessly in the home. Every later Felix gate in every worktree reads the shrunken table. The receipt's policy hash moves, the gate re-runs green under the weaker table, …
  - The fix: For a self-governed project, read each enforcing table (FELIX_ESCAPE_TABLES) at refs/remotes/origin/main and take the stricter of base and working copy, the way exceptions are read. Or refuse the gate when the home's tracked tables differ from origin/main. …
- **C031** (medium, silent-stall) A project bound by remote_match goes silently ungoverned when its project.json is unreadable
  - What goes wrong: iCloud evicts projects/veldra/project.json, or leaves only a 'project 2.json' (live ' 2' files sit in the home's state/ today). Every session in the ReserveGrid checkout then runs with no banner, no deny rows and no Stop hold. Nothing says the project used to be governed.
  - The fix: Keep a home-side record of resolved bindings (remote substring to project, last seen time), appended when a resolve succeeds. In felix_binding_broken, report a checkout whose origin matched a recorded project that no longer resolves, and also any …
- **C046** (medium, naive) Project binding by unanchored substring remote_match picks the wrong project
  - What goes wrong: A team governs acme/api (project acme-api) and acme/api-gateway (project acme-api-gateway). A checkout of acme/api-gateway with no .felix marker binds to acme-api, whose name sorts first. Its sessions are judged by acme-api's gate, deny rows and obligations, a wrong verdict nobody sees. Here, a clone of a …
  - The fix: Bind by exact owner/repo equality through felix_remote_github_slug when remote_match has the owner/repo form, and by the longest substring otherwise. When two projects match equally, bind none and say so at session start. Add the acme/api pair as a suite case.
- **C061** (low, silent-stall) felix_repo_root never returns for a path that does not start with a slash
  - What goes wrong: In a felix process whose stdout write failed earlier (a closed pipe in a scheduled land tick, or a hook whose reader went away), the next felix_repo_root spins at 100% CPU. The land tick or the PreToolUse hook hangs with nothing written and nobody told.
  - The fix: Refuse a non-absolute d before the walk (`case $d in /*) ;; *) d= ;; esac`), and stop when `${d%/*}` equals d. Flush the stdout buffer before the substitution, as revoke does with `printf '%s' '' > /dev/null`. Pin it with the pwd-stub assertion above.
- **C098** (medium, machine-bound) CLAUDE_CONFIG_DIR is honoured by some readers and ignored by about twenty others
  - What goes wrong: Under CLAUDE_CONFIG_DIR=~/.claude-work, Claude Code keeps plugins and skills under that directory. `felix stack plan` and `felix ready` then report every declared skill missing, commission provenance reads none for every plugin, and in a self-governed home `felix merge` refuses with 'no installed copy of the engine …
  - The fix: Add one helper, felix_claude_dir, that returns ${CLAUDE_CONFIG_DIR:-$HOME/.claude}, use it for every path above, and let the FELIX_* overrides compose on top of it.

## Batch 13: felix CLI trust and binding

Files: `engine/harness/felix`, `.gitignore`. Founder stop: none

- **C067** (high, overclaim) 'Judged by main, never by the candidate' depends on which felix the session typed
  - What goes wrong: A session in a Felix worktree runs `engine/harness/felix merge` from its branch, and that branch carries a bug in cmd_merge, such as an inverted `[ -n "$blockers" ]` or a dropped kernel branch. The candidate's own prologue decides the verdict and merges itself through gh. README tells the reader that cannot happen.
  - The fix: In cmd_merge's self-governed path, re-exec the installed kernel's felix (the cache entry for main's version) when $SCRIPT_DIR is not that entry, exactly as the tick does. Otherwise refuse, naming the installed CLI. Until then, qualify README:181.
- **C063** (low, naive) felix merge checks the judge's cache entry byte for byte, then sources the judge's libraries from that same user-writable directory
  - What goes wrong: A session that wants an escape-channel change merged loops over writes to the cache entry's lib/escape.sh, restoring main's bytes during the roughly 1 s comparison and swapping a permissive copy in before the source. felix merge then judges with code main never accepted. That defeats the #260 pin that the merge …
  - The fix: After the byte check, read the judge's libraries by sha from the base commit (`git show $base:engine/harness/lib/<f>.sh`) into a private mktemp -d directory, as the code already does for resolve.sh at felix:1868. Source only from there, so the cache entry is …
- **C116** (medium, naive) A second felix new in a monorepo, or any checkout already bound, silently rebinds the checkout
  - What goes wrong: In a monorepo, `felix new web apps/web` and then `felix new api apps/api` leave .felix reading 'api'. projects/web keeps its tables, gate and obligations, but nothing resolves to it any more. Its sessions are now judged by api's gate, with no warning.
  - The fix: Before writing, resolve the checkout. If it is already bound to another project, refuse with 'already governed by <x>; felix new does not rebind' and name the manual step. Say in the synopsis that a project is one git root.
- **C117** (medium, naive) remote_match is captured once, at the moment the engine says no remote usually exists, which leaves no own checkout and unbound worktrees
  - What goes wrong: A stranger runs `felix new` on a fresh `git init`, adds a GitHub remote the next day, and uses Desktop worktrees. remote_match stays "". Every worktree session is judged at the clean main checkout, so stops pass. Capability drift is never adopted. The one hint is a 'Nothing ran here unattended' line, given once to the …
  - The fix: At session start, when remote_match is empty and origin now parses as a github.com slug, say so on the screen line and offer `felix rebind --remote`. Have felix new print 'commit .felix so worktrees and CI resolve'. Parse non-GitHub hosts into host/owner/repo …
- **C064** (low, naive) A stray untracked file in the home's engine/ (a Finder .DS_Store) turns `installed` red everywhere until a version bump lands
  - What goes wrong: The founder opens engine/ in Finder on the home checkout, and Finder writes .DS_Store. The next `felix install` copies it into the cache. Every worktree's gate then fails `installed` and felix merge refuses the judge, so land on green stops for all PRs until someone ships a version-bump PR. That PR cannot pass the …
  - The fix: Make felix install refuse, or strip after naming them, untracked and ignored files under engine/ before installing (`git -C home ls-files --others --ignored --exclude-standard engine/`). Alternatively, populate the served engine from `git archive` of main. …

## Batch 14: Lessons, handoff and maintenance records stay true

Files: `engine/harness/lib/lessons.sh`, `engine/harness/lib/memory.sh`, `engine/harness/lib/maintenance.sh`, `engine/harness/templates/maintenance.tsv`, `projects/felix/maintenance.tsv`, `projects/felix/maintenance.log`, `engine/harness/tests/parts/0200-generated-constitution.sh`. Founder stop: none

- **C026** (high, naive) The lessons mount turns every lesson written by `felix lesson` into a bare date
  - What goes wrong: A session's prompt matches three of the lessons the gate has been teaching since 10-13. The hook mounts three date lines with no claims under the heading "Lessons this project already paid for". The session learns nothing and repeats the mistake. The README claim fails for 78% of the recorded lessons.
  - The fix: In _felix_lessons_headline, when the bold span is a date (^- \*\*[0-9]{4}-[0-9]{2}-[0-9]{2}\*\*), keep the date plus the first sentence of the text after it, cut at 240 characters as now. Add a part-0200 case built with `felix lesson "..."` that asserts the …
- **C058** (low, naive) felix handoff says "tree is clean" when git status fails, and calls a clean tree dirty under status.branch
  - What goes wrong: A session ends on a worktree whose index git cannot read, for example after an interrupted git operation, or iCloud renaming files in the home. felix handoff tells it the tree is clean and writes the same into SESSION_HANDOFF.md. The session stops or the worktree is archived with uncommitted work in it, and the next …
  - The fix: Read through _felix_git_read with `status --porcelain --untracked-files=no` (it has no branch line). On a failed read print `[?] whether the tree is clean is not known: <felix_tree_why>` and write the same into SESSION_HANDOFF.md.
- **C105** (low, naive) A cloud session is told to run maintenance it cannot do, and felix maintenance --ran puts a false 'done' into the tracked log the Mac reads
  - What goes wrong: A cloud session does as it is told. It runs promote over an empty /root mistakes.log ('nothing caught twice'), lessons over an empty lessons.md, and deployed where no engine is installed. Then it runs felix maintenance --ran for each and commits maintenance.log. The PR lands. On the Mac, promote reads ok for 14 days, …
  - The fix: Give maintenance rows a column for what they read: memory, install, graph or network. When CLAUDE_CODE_REMOTE=true, session-start withholds those rows, the way felix_own_gate withholds unattended kinds. --ran refuses a memory-reading routine when the memory …
- **C118** (medium, machine-bound) Every new project is seeded with a graphify upkeep row that is due forever without the founder's own tool
  - What goes wrong: Every stranger's first and every later session shows '· N due' including graphify, and the model is told to 'do them on one branch' and refresh a graph with a tool nobody installed. The due badge never reaches zero, so the line that should carry real upkeep is ignored.
  - The fix: Gate the row on a capability (for example `graph`) that is declared only when graphify-out/ exists or the tool is on PATH, or make the check exit 0 when there is no graph to keep current.

## Batch 15: Bootstrap protects the right branch with a passable gate

Files: `engine/harness/lib/bootstrap.sh`. Founder stop: none

- **C040** (high, naive) felix bootstrap --yes makes a stranger's main require a CI gate that can never pass
  - What goes wrong: A stranger follows the README, governs their repository and runs `felix bootstrap --yes`. Every pull request now has a required 'gate' check that fails at checkout, whatever the code. Collaborators without admin rights cannot merge at all. The admin merges by bypassing, which trains bypassing, and CI's verdict is …
  - The fix: Refuse to set protection while felix_ref is empty, and say why: the project's rules must live in a Felix repository CI can fetch. Document the fork-and-push-projects path in the Install section, or have CI read the rules from the governed repository.
- **C095** (medium, naive) `felix bootstrap` protects the checked-out branch instead of the default branch, and `--yes` can overwrite stronger protection after a failed read
  - What goes wrong: A session in a worktree on claude/adopt-x runs `felix bootstrap --yes` for a newly adopted repository. GitHub protects claude/adopt-x, main stays unprotected, and the re-run prints '[x] protection' and 'Baseline already in place.' Or the GET fails on a flaky network against a repo whose main requires reviews: the PUT …
  - The fix: Take the branch from origin/HEAD or `gh repo view --json defaultBranchRef`. Treat any gh api status but 404 'Branch not protected' as unknown and refuse to PUT. When protection exists, PATCH required_status_checks to add `gate` rather than PUT the whole body. …

## Batch 16: Deny floor judges effects on every tool

Files: `engine/hooks/hooks.json`, `engine/harness/lib/deny.sh`, `engine/harness/lib/deny-read.sh`, `projects/felix/deny.tsv`, `engine/harness/templates/schemas.tsv`. Founder stop: yes: deny rows and the PreToolUse matcher

- **C020** (low, naive) PreToolUse binds six tool names, so any MCP tool that runs a shell or writes files is never judged by a deny row
  - What goes wrong: A session whose Bash call is refused by the pattern-kill or push-to-main row runs the same command through a terminal MCP tool, and nothing is checked or recorded. A project's Read row for .env is sidestepped by the Grep tool. The rows read as enforcing for every shell command when they cover one tool name.
  - The fix: Bind PreToolUse to all tools (matcher '.*'), keep the fast name pre-check, and map known shell-running tools' command fields onto the Bash reader. Unknown MCP tools carrying a command/cmd/script field are read as Bash. Have felix doctor list installed tools …
- **C076** (low, machine-bound) Deny and risk patterns are never compiled or probed; invalid or GNU-only patterns silently refuse or escape nothing
  - What goes wrong: A product owner writes a deny row or a risk.tsv escape row using \b, \d or (?i), habits from other tools. On macOS the row never fires, and its tests pass on Linux CI. Nothing reports it, so a declared stop is silently declared away, which the constitution says a table may never do.
  - The fix: In schema-check and felix doctor, compile every pattern column with the same engine that will run it ([[ =~ ]] for deny, grep -E for risk). Refuse Perl/GNU escapes as audit.sh:226 already does for --verify. Report rows that can never match their own probe.
- **C079** (low, naive) Felix's own deny rows refuse spellings, not effects; equivalent short and global-option forms walk past
  - What goes wrong: A force push to a PR branch via a combined flag or a + refspec, or a commit skipping hooks via -n, goes through while the row's reason says it is refused.
  - The fix: Widen rows 19-20: tolerate git global options, match -[a-z]*f[a-z]* and +refspec, and -[a-z]*n[a-z]* for commit. Add interpreter -c/-e forms (python, perl, node, ruby, osascript) to the reader's run-its-argument set. Keep a blind corpus of equivalent …

## Batch 17: Commission grant cannot be self-given or misdescribed

Files: `engine/harness/lib/commission.sh`, `engine/harness/lib/autonomy.sh`, `engine/harness/lib/own.sh`, `engine/harness/templates/commissioning.tsv`, `projects/felix/commissioning.tsv`, `projects/elenchus-capital-research/commissioning.tsv`, `projects/veldra/commissioning.tsv`. Founder stop: yes: the commission grant and its consent text

- **C032** (medium, incomplete) A session can give itself the commission or tidy grant: no deny row, no TTY check, no record of who granted it, and the grant is read live from the home's working tree
  - What goes wrong: A session uses the Write tool to add a row to /Users/a14808/Documents/Felix/projects/felix/commissioning.tsv. The table is ordinary-tier, no deny row covers it, and the row's check column holds any shell. The session then runs `felix autonomy --allow commission` from its Bash tool. The stamp becomes the new policy …
  - The fix: Read the grant and its stamp from refs/remotes/origin/main, as exceptions.tsv is read, so the authority escape at merge becomes the act that grants. Note this conflicts with roadmap step 16, which moves stamps out of the tracked tree, so decide which one …
- **C033** (medium, overclaim) felix merge's founder hold on a stale commission is cleared by any session's `felix commission`, and session start tells sessions to run it
  - What goes wrong: A PR changes deny.tsv, as #455 did. deny.tsv is a commission table, so after deploy every later PR's felix merge refuses with 'commission receipt stale', and direction says the founder must re-stamp. A session in a home worktree sees that refusal, or follows the session-start line, and runs `felix commission`. The …
  - The fix: Write the actor into the receipt: the session id from the environment, or 'person' when a TTY is attached and no session id is set. Make felix_merge_blockers refuse a receipt whose policy hash differs from the hash in a person-written grant stamp. Then a …
- **C034** (medium, overclaim) The commission grant's consent text says the run installs nothing; the unattended run installs plugins and MCP servers
  - What goes wrong: Felix's commission grant is current (projects/felix/autonomy.commission = 2798bb0f). A stack.tsv row that is DECLARED low or medium, or an OBSERVED low row that discovery declared, is not yet installed. The next session to start in a home worktree runs `felix commission` in the background. The stack row is held, so …
  - The fix: Pick one of two. (a) Correct felix:2411-2415 and autonomy.sh:30-33 to say the run installs low and person-declared medium rows and enables plugins, and say the grant should be re-read. (b) Make the background run pass a flag, for example …
- **C085** (medium, naive) One commission receipt per project is checked against the surfaces of whichever checkout asks, so concurrent PRs fight over it
  - What goes wrong: In a governed product, PR A adds a Dockerfile or a dependency whose name contains 'next', 'flask' or 'stripe'. felix merge in A's worktree refuses 'stale (detected surfaces moved)'. Re-commissioning there makes the receipt stale for every other worktree and for the home, so PR A and PR B cannot both be landable, and …
  - The fix: Key the receipt by project and checkout, or hash surfaces from refs/remotes/origin/main's tree for the merge check and treat a PR's new surface as an escape row on its own. Match dependency keys, not substrings.
- **C068** (low, silent-stall) Unattended commissioning failures go to a log nothing reads, and a hung run locks commissioning out
  - What goes wrong: A commissioning check hangs, for example on an MCP server or an npx download. The background run holds the lock forever. Every later session's resume and the founder's own `felix commission` print "already in progress (pid N)" or append declined-or-failed, which nobody reads. The commission receipt then goes stale, …
  - The fix: At session start, read the newest bg.log row. When it is declined-or-failed, or when the lock is held and its dir is over 1 h old, print one line with the reason and the command. Run the background commission under a deadline, using the same holder pattern as …
- **C048** (low, incomplete) Project commissioning.tsv copies drift from the template
  - What goes wrong: In a checkout bound to elenchus-capital-research by its .felix marker, felix_stack_plan dies under fork pressure (or a capabilities read fails and the plan prints unknown rows). The stack and human_steps rows read done, the receipt reads commissioned, and the commission blocker lets a merge through. A person who does …
  - The fix: Bring the nine tables to the template's check cells in one escaping PR on the founder's yes, followed by one re-stamp. Key the session-start seen store, or a pulse line, to the template's hash so drift is said once after an engine upgrade without a hand run. …

## Batch 18: Ledger reads dead hooks and iCloud duplicates

Files: `engine/harness/lib/ledger.sh`, `engine/harness/hooks/post-tool`. Founder stop: none

- **C101** (medium, naive) A dead PostToolUse hook is folded into the ledger as zero use
  - What goes wrong: post-tool cannot fork or load ledger.sh for a session that really used the play the router named. The ledger records that the session never reached for it, and that row feeds the retire list and reach analysis as unconfounded evidence of non-use.
  - The fix: Have post-tool append a builtin-only `alive` line to the session's state file on every run, or at least the first. Have rollup write the count as `-` (unknown) instead of 0 for a session that has named rows and no alive line, and have the readers of the …
- **C052** (low, machine-bound) iCloud duplicate/conflict files sit in Felix state and nothing detects them
  - What goes wrong: Two hooks append to the same state/ledger/<sid>.tsv while iCloud syncs, and the newer half becomes '<sid> 2.tsv'. The ledger's 'only unconfounded signal' silently drops those reaches, and felix_ledger_stranded reports 0. Or the pulse record is renamed: felix status shows an older run as the last one with no hint that …
  - The fix: Keep machine state out of the synced home (state under ~/.felix/state, or FELIX_STATE defaulting there). Until then, have the pulse report and felix status list any `* [0-9]`

## Batch 19: Capability detection and omission surfaces

Files: `engine/harness/lib/detect.sh`, `engine/harness/lib/facts.sh`, `engine/harness/lib/next.sh`, `engine/harness/lib/procedures.sh`. Founder stop: none

- **C089** (medium, incomplete) What the plane works out about omissions reaches no automatic surface, and felix next says 'nothing due' over it
  - What goes wrong: Elenchus has 7 unadmitted candidates and a detected surface that no probe grounds. Session start, every gate pass, the pulse and felix next all stay silent about both. The only way to learn of them is to type felix probes or felix obligations.
  - The fix: Add ranks to felix_next for candidates awaiting admission (a count, the founder's), surfaces nothing probes and items with no stance (Felix's), and members added on this branch. Under the gate's 'probes ok' line, print the gap and drift lines when they are …
- **C090** (medium, naive) Capability detection reads only root manifests and a short framework list, so monorepos and most API stacks show no api, database or billing surface, and no auth or rate-limit surface exists
  - What goes wrong: A Go/gin service gains an unauthenticated admin endpoint and a new Postgres dependency. felix_detect returns nothing, so no gap, no stance item, no commission re-run and no candidate request names a surface, and felix probes lists no 'surfaces nothing probes'.
  - The fix: Enumerate manifests with git ls-files at any depth, excluding vendor and node_modules. Extend the framework table (rails, sinatra, spring-boot, laravel, gin, echo, chi, fiber, axum, actix, koa, hono, nestjs, aspnet). Stop inferring frontend from package.json …
- **C096** (medium, naive) felix_repo_slug returns a non-slug for any remote that is not github.com (GitLab, GitHub Enterprise, an SSH host alias for GitHub), so every 'no github remote' guard is bypassed
  - What goes wrong: A developer keeps two GitHub accounts apart with Host github-work in ~/.ssh/config, the usual setup. Every `felix merge` refuses with 'GitHub could not be asked (gh run list failed with status 1)', the lander writes gh rows instead of landing, and `felix pr` fails, each with a diagnosis that does not mention the …
  - The fix: Have felix_repo_slug reuse setup.sh's URL parser: print owner/name only when the host is github.com, www.github.com or ssh.github.com, or an ssh alias that `ssh -G` resolves to one of them, and print nothing otherwise.
- **C056** (medium, naive) Probe drift compares against whichever tree last wrote the shared facts log
  - What goes wrong: Two branches gate minutes apart. felix probes on branch B reports 'hook_binding 8 members -> 6 members, 2 fewer than on the last tree' because A deleted hooks, not B. That sends someone hunting for a regression that is not on their branch.
  - The fix: Compare against the last run on this branch's merge base, or on the receipt's previous tree for the same checkout. Read the log once with one awk keyed by predicate.
- **C060** (low, naive) Lookups that end in `return 0` or a here-document of an unchecked substitution still answer done when a nested fork dies
  - What goes wrong: Under a parallel gate (tests/run -j at the performance-core count) or a loaded machine near kern.maxprocperuid, one fork inside felix_ready_wanted fails. The preflight row reads done with nothing checked, the receipt reads commissioned, and nothing says a lookup failed. The same death in felix_detect drops a surface …
  - The fix: Give each lookup its pipeline's status (no blanket `return 0`). Read each inner list once through felix_capture before looping over it, and return 2 when that capture fails. Apply this to felix_ready_wanted, felix_obligations_orphans, felix_probe_state and …

## Batch 20: Obligation proposals for new projects

Files: `engine/harness/lib/candidates.sh`, `engine/harness/lib/obligations.sh`, `engine/harness/templates/obligations.tsv`, `engine/harness/templates/probes.tsv`, `docs/2026-10-18-capability-plane-thesis.md`. Founder stop: none (intake only; admission authority stays gated)

- **C023** (medium, incomplete) On a product project only the project's own test command speaks for auth, rate limits or fallbacks, and new projects are never asked to propose obligations
  - What goes wrong: Take an Express API set up with felix new defaults. An agent adds a feature and deletes the express-rate-limit middleware, and npm test does not exercise limits. felix gate prints 'probes ok' (3 found) and 'obligations ok' (1 obligation: 0 active, 1 dormant), then writes a green receipt. The Stop hook releases and …
  - The fix: (1) Add 'obligations_surveyed provider:felix:obligations' to templates/commissioning.tsv so every project is asked once per topology. (2) Build row 27's first class rule for the founding omission (a served route must have a ceiling), founder-admitted once as …
- **C091** (low, naive) A candidate's grounding is only a name lookup, so 'grounded' accepts any declared predicate whatever the claim
  - What goes wrong: A felix-new project's probes are tracked_file, test_file and ci_workflow. A model proposes 'routes_have_auth ADVISORY applies=<a grep for routes> grounds=tracked_file', and it is recorded as grounded. Its staleness then follows the tracked-file count instead of the routes, and an admitted copy would switch between …
  - The fix: Pass applies the members of its grounding predicates (FELIX_MEMBERS_<pred> files written from the probe run) and refuse a candidate whose applies does not read them. Failing that, record such grounds as nominal and say so in felix obligations.

## Batch 21: README claims match the engine

Files: `README.md`. Founder stop: none (README follows docs/direction.md; direction.md is not edited)

- **C008** (high, overclaim) README's probe-instrument staleness claim is false since #304
  - What goes wrong: A project's probe `cargo metadata ...` resolves to a cargo binary of a different size after a toolchain upgrade, and the member count does not change. README promises the green receipt goes stale. felix_verify_current (verify.sh:610-613) recomputes the same epoch and reports `current`, so Stop and `felix merge` accept …
  - The fix: Remove the instrument-size clause from README:289-291, or bring the instrument back as invalidation by selector (v3.2's 'affected receipts invalidated') kept outside the epoch hash. Replace the Status 'Partial' sentence with the real residual, or drop it. …
- **C017** (high, overclaim) README still says a weak corpus result will narrow Felix to the obligations people name, and still gives the old lane order
  - What goes wrong: An outside reader of the public-facing README (and the snapshot that publishes it) is told Felix will shrink to a checking tool if one experiment is weak. That contradicts the founder's 10-01 ruling and 'do not narrow Felix', and the README is the document strangers judge Felix by.
  - The fix: Rewrite README 408-420: the lane order from direction §5, and 'a weak result is investigated, not narrowed on'. Add a suite lint that fails when README holds the phrase 'narrow to the obligations people name'.
- **C007** (medium, overclaim) README says nothing merges on its own except automerge
  - What goes wrong: A reader trusts README:455 and the Status table and concludes merges only happen by hand or through GitHub auto-merge. On a home where `felix land --install` was run, the job squash-merges any open PR that meets the tick's rules, judge-changing engine PRs included (direction row 24), then deploys it. README's …
  - The fix: Add land on green to the Status table, scoped to the home's own repository. Rewrite README:455 to name both `felix automerge --enable` and `felix land --install` as the ways something merges unattended. Add `felix land --uninstall` to the uninstall list.
- **C099** (medium, machine-bound) The documented install step `ln -s ... /usr/local/bin/felix` fails on a stock Mac
  - What goes wrong: A new user follows the three README lines in order. The third fails with 'Permission denied' or 'No such file or directory', and every later instruction that says `felix ...` gives 'command not found'.
  - The fix: Print `mkdir -p ~/.local/bin && ln -s <path> ~/.local/bin/felix`, check whether ~/.local/bin is on PATH and say how to add it if not, and change the README to match.

## Batch 22: Snapshot builds, is tested, and ships the Stop fix

Files: `projects/felix/snapshot.sh`, `projects/felix/snapshot-audit.sh`, `projects/felix/snapshot-scrub.sh`, `.snapshot-ack.tsv`, `engine/harness/lib/incident.sh`. Founder stop: yes: publishing the public snapshot (C037)

- **C113** (low, silent-stall) snapshot.sh dies today before it builds: an empty two-letter memory directory, and acknowledgements voided by the suite split
  - What goes wrong: The founder finally says 'publish'. The session runs snapshot.sh, which stops at the names stage. Two founder-reviewed PRs to .snapshot-ack.tsv are needed before a build can even start, and the run after that publishes garbled comments.
  - The fix: Add the @name row for zz, find what writes into the real memory root, and give the suite's FELIX_MEMORY isolation a lint. Drop the three void rows. Correct the webapp comment. Have the halves rewrite of a scrub name require that the joined form appears in the …
- **C114** (low, untested) The irreversible publication path is exercised by no suite part and no gate, and it changed after its last run
  - What goes wrong: A carry PR changes a regex in snapshot-audit.sh, or a shared helper that snapshot.sh relies on. The gate is green, because nothing reads these files. The failure shows up only at publish time, the one moment where a wrong pass is irreversible.
  - The fix: Add a suite part with an offline fixture. It builds a tiny home with two projects, a memory root and a planted owner, given name, address and escaped stand-in. It runs snapshot-scrub.sh and snapshot-audit.sh directly, and it asserts each planted leak is …
- **C037** (high, overclaim) Strangers' Claude Desktop worktree sessions get wrong Stop verdicts from the public engine; the fix has sat unpublished for 21 days
  - What goes wrong: A stranger installs from github.com/LeavesJ/Felix and works in Claude Desktop, which runs each session in a git worktree. An agent edits files in the worktree and stops. The Stop hook runs in the main checkout, which is clean, and the session committed nothing there, so it exits 0 (public stop:181 onward). The …
  - The fix: Bring the snapshot forward, which needs the founder's yes. Until then, add a line to the public README Status table: 'Claude Desktop worktree sessions are judged at the main checkout before 0.49.245'.
- **C039** (low, incomplete) The audit cannot see third-party or out-of-tree names: remote owners, TSMC, and repositories outside projects/
  - What goes wrong: A session designs the egress control that direction.md:400-401 asks for and writes, in an engine comment or in projects/felix/CLAUDE.md (published whole), 'needed for the TSMC-subcontractor test'. Or a lesson promoted into the constitution names a teammate by GitHub handle. The scrub leaves it, the audit reports no …
  - The fix: Add owners to remote_forms (print the owner and owner-without-separators). Add a seventh, tracked source, `.snapshot-names.tsv` (withheld like the acks), for third parties and private names that are no project, seeded with TSMC and the founder's other …

## Batch 23: Cloud kit truthfulness

Files: `engine/harness/bin/secret-scan`, `.claude/cloud/toolbox.json`. Founder stop: none

- **C108** (low, naive) With no origin/main the gate prints 'secret ok' over a tree it never scanned, and the session's obvious repair is refused by a deny row
  - What goes wrong: provision's fetch_main fails or is killed (see the provision finding). In the cloud gate, secret reads ok while the committed history went unscanned. qualified then FAILs on the held secret controls, as it did on 09-28 (cloud-verify.md:137-144), and Stop holds. The session tries the obvious repair, `git fetch origin …
  - The fix: Have the gate treat secret-scan's no-base note as a skip it reports, in the receipt's skips field and on the secret line, not a pass. Or let secret-scan exit non-zero with no base when CLAUDE_CODE_REMOTE=true. Have provision's failure line name `bash …
- **C111** (low, machine-bound) toolbox.json's 'the cloud runs what a local session runs' is already false: three pins lag the local install, and only the founder's laptop can tell
  - What goes wrong: Local plugins update on their own, as on 10-16 and 10-19, and no one moves the pin, because the pin's source of truth is one laptop's registry and nothing reads it. Cloud sessions run an older superpowers, including its session-start hook and skill text, than local sessions, while the file says they match. Behaviour …
  - The fix: Add a local-only comparison, in felix status, the pulse or session-start on the founder's machine, of toolbox shas against installed_plugins.json, saying which pins lag. Change the sentence to say the pins are moved by hand and may lag.

## Refuted

- C012 An unattended landing behind main lands on stale CI and deploys after only gate --quick. Why: The code does what the finding describes, but a recorded decision covers it, its one piece of real-world evidence is wrong, and its two scenarios are mostly blocked by other paths.
- C022 The tick's founder holds live only in green-tick.sh, which no escape or trust-base rule protects, so an unattended PR can remove them. Why: The code facts mostly check out, but a recorded decision covers the scenario, and the assumption that decision rests on is still true.
- C049 Deploys under launchd fail on the 256-descriptor limit and pause landing. Why: The cited code is as described, but the failure it is said to cause has not happened since 10-19, and it did not cause the 10-19 failure either.
- C051 48 handoff sections sit unfolded in pending/. Why: The basic facts check out on this tree. origin/main holds 48 pending sections. The last fold was 6fe5f986 (#416, 10-03). HANDOFF.md:50 is still 0di. maintenance.tsv:63 is due: the count is 48, which is at least 3, and …
- C053 The earned-automerge threshold can be lowered by an environment variable. Why: The mechanics are as the finding describes, but the risk it names does not follow from them. A gap that does exist is already recorded and scheduled.
- C054 Stack rows a session or adoption wrote read as DECLARED (person-chosen) and install. Why: The mechanics the finding describes are real, but neither scenario ends in the harm it claims.
- C057 The gate-ready fix for writes through links and pipes (slot 12) has sat unlanded since 10-08 with no PR; the commission stamp still writes blind and says "stamped". Why: The stall and silence parts of the finding are false. The code gaps it names are real, but they fail closed, the same command shows them, and they need a non-regular file that git cannot deliver.
- C059 On a machine with the claude CLI and no marketplace plugin, preflight says "no claude CLI here" and its own answer can never clear it. Why: The mechanism the finding describes is real, but its scenario is not. The stranger on a fresh laptop is not left with a preflight row held until a person installs a plugin by hand, because the row just before it in the …
- C062 Hold-once debts are written and never surfaced: the released stop prints nothing and the lost-work page has no debt group. Why: The cited lines are accurate, but the outcome the finding claims does not follow from them. engine/harness/hooks/stop:582-585 does write a `debt` row and exit 0 with no additionalContext. That is the decided hold-once …
- C065 Each engine landing turns every in-flight Felix gate red, and the deploy that would fix it waits for those gates. Why: The cited lines say what the finding quotes. The conclusions drawn from them do not hold.
- C066 Session-start auto-adoption stales the founder's commission grant and every receipt, forcing a founder step. Why: The finding describes the mechanics correctly, but the result it calls a defect is the safety boundary working as designed, and recorded decisions cover it.
- C070 A branch learns it is stale only after a full suite: two CI runs of #456 spent 38.7 and 33.8 min failing on _rtn3 and _rtn4. Why: The mechanism is described correctly. The finding's evidence and scenario are not.
- C071 Every engine landing forces every other open engine PR through merge-main, record, red, gate and CI, and land.tsv's resolvers are declared with nothing to run them. Why: The code facts are mostly right, but they describe a gap that is already recorded and scheduled. The finding's ledger evidence is also misread. (1) The files say this themselves, so nothing overclaims. …
- C072 For governed projects, risk tiers exist and choose no verification: any edit demands the whole project gate, which has no reuse. Why: The facts cited are accurate on this tree, but the defect does not hold, because Felix has recorded rules that cover this case and the finding's reading of the tier table is wrong.
- C073 CI runs the suite serially on a 4-core runner, the slowest step on every PR's path to landing. Why: The facts are right. The conclusion that the serial run buys no safety is not, because a recorded decision covers it and that decision still holds. (1) gate.sh:302-315 sets GTJOBS only when GITHUB_ACTIONS is not true, …
- C084 The founder's commission re-grant writes a tracked file in the home, which pauses the next deploy. Why: The cited code is accurate, but the gap is already recorded and scheduled, and the part that is new costs less than the finding says.
- C086 Every PR pays the full suite twice before the tick lands it, locally and in CI, and no path lets one count for the other. Why: The code does what the finding says. engine/harness/lib/escape.sh around lines 629-640 blocks a merge unless a current local receipt exists. Lines 642-663 (rule C9) ask CI only when the receipt says tests:reused. …
- C088 The daily unattended-run ceiling never binds in CI, its only consumer. Why: The mechanics are right, but the gap is already known, disclosed and deliberately deferred. On this tree:
- C092 The seeded tracked_file count puts every added file into the decision epoch, so every candidate reads stale after the next commit. Why: The mechanism is described correctly, but it is the designed behaviour, the tests assert it, it is recorded as decided, and it changes nothing except one label in a report.
- C103 The overnight cross-session guard trusts the presence of CLAUDE_CODE_SESSION_ID, so `env -u` lets a session grant another session's night; the queue can also be wiped by any session. Why: The mechanics are accurate, but the finding fails as stated, for four reasons.
- C109 provision is a second install path that skips admit.sh: no risk, grounding or capability check, and it runs a third-party hook as root. Why: The cited lines are accurate, but the finding's two scenarios do not hold on this tree, and the harm it describes does not happen.
- C112 The cloud is the one path that runs Felix work with the Mac asleep, but it exists only for felix-home and nothing it makes can land or be learned from until the Mac re-does it. Why: The facts the finding cites are accurate, but its conclusions are either covered by recorded decisions and recorded open questions, or contradicted by the tree.

## Low, not checked

C119 independence-scan reads a git grep error as no leak; C120 An added line that begins with "++" is never scanned for credentials or destructive SQL; C121 The squash body and PR body read git log without --no-show-signature, and log.showSignature is outside the git pin; C122 The owed after-measure of hold-once and felix cost has not run, and nothing will prompt it; C123 The gawk-builtin lint reads lib/*.sh only, not the hooks, the felix CLI or bin/; C124 Part 0573's 'TERM cuts at least one run short' passes on its delay-0 run alone, which never reaches felix; C125 The lost-work page's handoff group reads complete when the default cover row is unknown, and part 0940's library lints skip inventory-chips.sh; C126 A topology stale reason says 'the grounded facts moved' without naming which probe moved; C127 The suite driver is at 497 of the 500 lines part 1040 allows, and #452 adds two; C128 Three governed projects declare no remote_match, so they get no unattended adoption, graph refresh, tidying or commissioning, and are told once; C129 Stop's hold message offers exceptions.tsv to every project, but only felix-home reads it; C130 `felix automerge --enable` claims yellow and red are untouched, but nothing enforces tier; C131 README puts the suite at about 3,000 assertions; the manifest holds 13,902; C132 direction §5 orders work that has already landed; C133 The tick's watchdog sends TERM once and never KILL, and a lock held past 45 minutes is reported once and never broken; C134 The commission lock judges liveness by pid alone, so a reused pid after a reboot holds it forever; C135 Reach's `claude mcp list` has no time limit, and breaking its lock after 30 minutes leaves the old run alive, so each later start can add an orphan; C136 qualified re-runs all 81 controls at every gate, whether or not a checker or control changed; C137 The suite receipt names the machine by its Bonjour LocalHostName, which carries a conflict suffix that can move; C138 GitHub's lazy mergeable UNKNOWN reads as 'not conflicting', so rows flap and the checkout is probed for a PR that cannot merge; C139 felix cost hard-codes this founder's plan week (Thursday 13:00Z) and cap (905M); C140 Qualification runs each control against HEAD while the receipt certifies the working tree; C141 The discovery capability matcher forks several processes per keyword, about 0.57 s per catalogue entry; C142 Probes run several times per item: twice in the gate and twice in felix merge, each time in full; C143 SESSION_HANDOFF.md is one slot per project shared by every session; the current one is 21 days old and is named at every start without its date; C144 Worktree rows ignore ignored files, so a worktree whose only unique content is ignored reads 'landed'; C145 The 500-line rule is enforced only where a lib's own test happens to assert it; 15 engine files exceed it; C146 Maintenance and setup checks run with no time limit inside session start, the Stop hook and the pulse; C147 The reach row reports the bundled anthropic-skills plugin as unknown, though felix ready reads it as installed; C148 The lander row reads 'not-live' when the job is installed, loaded and unpaused; C149 448 of 845 lib functions are never named by any test part; two are dead code; C150 The suite pins silent fail-open; no test asserts a hook that could not judge says so; C151 FELIX_ALLOW_RED is 'the founder's' but reachable by a session for the sessions it launches; C152 No test covers the cloud path, and the only cloud run was 3.5 times the suite ago; C153 The cloud design rests on 'plugins never load in a cloud session', which its own measurement disproved, so hooks can fire twice in the cloud; C154 provision deletes, or hides from git, an untracked path that shares a plugin skill's name, and re-runs at every resume, clear and compact; C155 The published projects/felix tables govern a stranger's own Felix clone and report the founder's chores as due; C156 The audit's self-exclusion lets the private repository's bare name, and its protection posture, through; C157 snapshot.sh promises a ten-minute suite that no longer fits a session's 600 s Bash cap; C158 Two gate guesses are red by default on stock machines.
