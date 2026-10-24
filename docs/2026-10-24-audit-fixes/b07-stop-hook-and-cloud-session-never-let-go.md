# Audit fix b07: the Stop hook and the cloud session never let go silently

*Written 2026-10-24 against felix-home `origin/main` `69b51a61` (engine 0.49.307), from the batch brief b07 (defects C030, C035, C102, C106, C107, each with two skeptics' notes where it has them). Where a skeptic corrected a claim or a severity, this contract follows the correction and says so in §1.*

**This document is the whole contract for assertions.** An assertion author needs nothing else, apart from the suite's own helpers (`ok`, `bad`, `is`, `has`, `skip`, `_copy_content`, `_fx_cd`, `$TMP`, `$REAL_HARNESS`). Line numbers cite the base commit.

---

## 1. Defects

**C030 (low; both skeptics corrected it from high).** When a bound project's `project.json` cannot be read, or a library it cannot work without fails to load, the Stop hook ends the session with no hold, no output and no row, which looks exactly like a session that changed nothing.

*Scenario.* A `.felix` marker names `p`; `projects/p/` exists, but its `project.json` is gone, is a pipe or a directory, or cannot be read. `felix_resolve_project` binds on the directory alone (resolve.sh:473-479), so `felix_binding_broken` says nothing. `GATE` reads empty (stop:200) and stop:201 exits 0, the exit for "declares no gate". SessionStart tells the session `Gate: none declared` (session-start:226-230). And with `lib/resolve.sh` or `lib/verify.sh` missing from the engine copy, the hook exits 0 with nothing on stdout and no row: stop:50-59 source ten libraries with no guard, so an undefined `felix_tree_dirty` reads as a clean tree at stop:218. The skeptics' corrections, which this contract follows: the iCloud evidence was misread (the `' 2'` copies keep their originals, and the orphaned held-tree copy is one that `felix_hold_tree_clear` deleted); the libraries load from the plugin cache, not from iCloud; and no trigger has been seen. What survives is the rule this project wrote for itself: "nothing due" and "nothing is being checked" must not look the same.

**C035 (medium per the brief; skeptic A argued low, skeptic B medium).** A cloud session that stops with the gate not passed is let go, and the only record of it lives in the VM.

*Scenario, as skeptic B corrected it.* The founder starts a cloud session and it edits files. At Stop it is held once with `felix gate`, a bare command name the VM is not shown to have on PATH (cloud-verify.md ran the gate as `bash engine/harness/felix gate`). The gate takes 33 to 43 minutes on the current suite, and one Bash call ends at ten. The flagged stop after the hold is released by the chain rule (stop:118) and writes no row. A later stop on the same tree, for example a background task waking the session, is let go as debt (stop:582-585) and prints nothing. The debt row and the `held` line live under `/root/.felix/memory` and die with the VM. Not claimed: that CI never runs (it runs once a PR exists), or that the work is hidden (`felix inventory` lists a remote-only branch as unproposed).

**C102 (low; the skeptic refuted half of it).** Felix keeps no record when its prompt hook is cancelled at the platform's 30-second limit.

*Scenario.* Claude Code recorded 81 to 85 cancelled runs of `hooks/user-prompt` (`timedOut true`, `timeoutMs 30000`) between 08-31 and 10-23. Each time the person waited 30 s and the prompt got no route, lessons or brief, and nothing under the memory root says it happened. The other half, that a timeout before the session mark drops the Stop check on committed work, is not a defect (§6).

**C106 (medium, confirmed).** In a cloud session, a play step the session did use is reported as never used.

*Scenario.* `provision` copies each plugin skill to `.claude/skills/<base>` (provision:101-111), so the cloud session has a project skill named `brainstorming` and no `superpowers:brainstorming`. The transcript attributes a use of it as `"attributionSkill":"brainstorming"`. But `felix_route_step_used` counts a qualified step only on `"attributionSkill":"superpowers:brainstorming"` (route.sh:511), with no fallback for qualified steps (route.sh:527-528). So `felix_route_due` never moves past step one, and at a green Stop `_felix_stop_skipped` (stop:252-278, 443-485) says the play was never used and asks for `felix route --ack`. This is latent: provision has never delivered a skill, because codeload answered 403 (docs/handoff/0dh.md:51-53).

**C107 (medium, confirmed; the timeout half is the weaker one).** When `provision` fails, nobody is told.

*Scenario.* The cloud's network refuses codeload, which is the one failure ever measured (403, three fetches in about a second), or drops its packets. On failure provision prints nothing (provision:155-168). Every mode but `--report` exits 0. Its log has no reader, and `--report` has no caller. A source that failed is fetched again for its second entry (provision:54-65). Each fetch can take 3 × 60 s (`--retry 2 -m 60`), and `git fetch` has no bound at all, against a 120 s hook timeout (settings.json:62-68). The session starts with no skills, and the router still names them. The gate's cloud check reads ok, because it checks structure only.

---

## 2. Required behaviour

### Terms used below and in §4

- **Stop fixture S.** A home `H` = `$TMP/b07/home` holds `harness/` (a `_copy_content` copy of `$REAL_HARNESS`) and `projects/p/` with `project.json` reading `{"name": "p", "gate": "true"}`, a `CLAUDE.md`, and a `probes.tsv` of one row, `marker<TAB>-<TAB>-<TAB>ls -1 .felix<TAB>test -f .felix`. The memory root is `M` = `$TMP/b07/mem`. The repository `R` is made with `git init -b main`: one commit holding `WORK.txt` and a `.felix` that reads `p`, then one uncommitted line appended to `WORK.txt` (**dirty**). A case that says **clean** leaves that line out.
- **Hook run.** `cd R && printf '%s' PAYLOAD | env -u FELIX_ALLOW_RED -u CLAUDE_CODE_REMOTE FELIX_HOME=H FELIX_MEMORY=M [NAME=value ...] HOOK`. A run that has not ended in 20 s is killed, along with every process below it, by pid. Record its stdout, stderr and exit status, and the rows it appended to `M/p/verification.log`, `M/p/says.log` and `M/unresolved.log`.
- **Stop payload.** `{"hook_event_name":"Stop","stop_hook_active":F,"session_id":"SID"}`, where F is `false` unless the case says **flagged**. Each case uses a fresh SID unless it says otherwise.
- **Row fields** are separated by tabs. In `verification.log`: 1 time, 2 verdict, 3 tree id, 4 reason. In `says.log`: 1 time, 2 kind, 3 session, 4 cause, 5 text.
- **holds**: stdout contains `"decision"` and then `"block"`. **says X**: stdout has a top-level `"systemMessage"` key whose value contains X. **prints nothing**: stdout is empty.
- **one JSON object**: where `jq` is on PATH, `jq -e 'type == "object"'` accepts the whole of stdout. Where it is not, that assertion is skipped.

### C030: the stop says what it could not judge

- **B1.** Take fixture S. `H/projects/p/` exists, and its `project.json` is in any one of these states: absent, a named pipe, a directory, a symbolic link to nothing, or a regular file of mode 000 (that last only where this user's read of a mode-000 file is refused). A dirty unflagged stop must then:
  - exit 0 within 20 s, never opening the pipe;
  - print one JSON object, with no `"decision"`, that says `Felix could not judge this stop`, the path `H/projects/p/project.json` (H as given), and `nothing was held`;
  - append one `verification.log` row: field 2 `unjudged`, field 3 `none`, field 4 containing `project.json`;
  - append one `says.log` row whose field 2 is `unjudged`.
- **B2.** A readable `project.json` that declares no gate stays silent. `{"name": "p"}`, and `{"name": "p", "gate": ""}`, both exit 0 with stdout and stderr empty and no row added to any of the three logs. (control)
- **B3.** *A library the stop cannot do without.* With `harness/lib/verify.sh` removed from H's copy, a dirty unflagged stop:
  - exits 0;
  - prints one JSON object, with no `"decision"`, that says `Felix could not judge this stop`, `lib/verify.sh` and `nothing was held`;
  - appends one row to `M/unresolved.log` whose text contains `lib/verify.sh`.

  With `harness/lib/resolve.sh` removed instead, the stop exits 0, says `Felix could not judge this stop` and `lib/resolve.sh`, and has no `"decision"`. No row is required, because the writer is what failed to load.
- **B4.** Every library the stop sources is named in `hooks/stop` as the literal `lib/<name>.sh`. Remove any one of them from H's copy, and a dirty unflagged stop on a never-verified tree either holds or says `lib/<name>.sh`. It never does neither. The eight libraries the stop sources today besides `resolve` and `verify` (`route`, `ready`, `guard`, `say`, `detect`, `maintenance`, `overnight`, `overnight-stop`) still hold when removed, as they do today. (control)
- **B5.** In S with `project.json` absent, `hooks/session-start` given the payload `{"source":"startup","session_id":"SID"}` exits 0. Its stdout contains `Gate: unknown`, the path `H/projects/p/project.json`, and, in the line for the person (`systemMessage`), `gate unknown`. It does not contain `Gate: none declared`. Two controls: with `{"name": "p"}` the stdout still contains `Gate: none declared`; with the gate set it still contains `Gate: ` followed by a path ending `/felix gate`.
- **B6.** Take S with `project.json` absent and B1's `unjudged` row already in `verification.log`. `H/harness/felix monitor --log`, run with FELIX_HOME=H, FELIX_MEMORY=M and HOME set to a fixture directory, exits 0. The data in the `H/state/monitor.html` it writes contains `"name":"p","gate":{"unknown":"` followed by a reason that names `project.json`, and a row with `"verdict":"unjudged"`. A second project `q`, whose `project.json` is `{"name":"q","gate":"true"}`, keeps `"name":"q","gate":"true"`. (control for q)
- **B7.** The monitor page's log panel gives a verification row the class `ok` only when its verdict is `allowed`. `blocked` gets `bad`. Every other verdict gets `warn` and never `ok`: `override` and `debt` (as today), `unjudged`, `quarantine` (which `felix quarantine` writes; it is `ok` until now), and any verdict the page has never seen.

### C035: a cloud session is told, and tells

- **B8.** With `CLAUDE_CODE_REMOTE=true`, a dirty stop on a never-verified tree holds as it does today. Its reason still contains `Do not describe this work as complete until it has passed.` and `FELIX_ALLOW_RED=1`, and it also contains:
  - `This is a cloud session.`;
  - `nohup`;
  - `D/felix gate`, where D is `$(cd H/harness && pwd)`: the gate named by the path of the hook's own engine;
  - `If you stop before the gate passes on this tree, say so in your last message`.
- **B9.** Only the value `true` counts as remote. With `CLAUDE_CODE_REMOTE` unset, `1` or `false`, the reason contains neither `This is a cloud session.` nor `nohup`. (control)
- **B10.** With `CLAUDE_CODE_REMOTE=true`, run three stops of one session: the hold from B8; the flagged stop that ends its chain, which still prints nothing and writes no row; then the next unflagged stop on the unchanged tree. That third stop:
  - appends the debt row as it does today: field 2 `debt`, field 4 containing `never verified` and `held once on this tree already`;
  - exits 0;
  - prints one JSON object, with no `"decision"` and no `"hookSpecificOutput"`, that says `let go with the gate not passed on this tree`, `never verified` and `ends with the VM`;
  - appends one `says.log` row whose field 2 is `debt`.
- **B11.** Without the variable, the same sequence prints nothing at the debt stop. (control)
- **B12.** The suite runs with `CLAUDE_CODE_REMOTE` unset. A prelude part (0001 to 0007) unsets it in the suite's own shell before any part from 0010 on runs, so a part only ever sees it for a command that sets it. Otherwise a gate run in a cloud VM would judge every local-behaviour assertion against the cloud behaviour.

### C102: a prompt hook that did not finish is recorded and said

*Prompt fixture P2.* A home `H2` like S's, but with a project `p2` and memory root `M2`. The repository `R2` is clean: one commit, and a `.felix` reading `p2`. A stub directory comes first on PATH and holds `git`. While a sentinel file exists, that stub touches a "reached" file and execs `sleep 60`; otherwise it execs the real git, whose path is taken before PATH is changed. The prompt payload is `{"session_id":"SID","transcript_path":"","prompt":"tidy the readme please"}`.

- **B13.** Start `hooks/user-prompt` while the sentinel exists. Once "reached" exists (wait at most 10 s), end the hook and every process below it with SIGKILL. A second case does the same with SIGTERM. Then remove the sentinel. The session's next unflagged stop, on the clean tree, exits 0 and prints one JSON object, with no `"decision"`, that says `Felix's prompt hook did not finish`. `M2/p2/says.log` gains one row: field 2 `prompt-unfinished`, field 3 the SID.
- **B14.** If that stop holds (the tree is dirty and was never verified), the object it prints holds as today, with a reason that still contains `Do not describe this work as complete`, and also says `Felix's prompt hook did not finish`.
- **B15.** It is said once. The next stop of the same session, with nothing else changed, prints nothing.
- **B16.** An interrupt does not hide it. Sequence: an unfinished run (B13); then a second `user-prompt` run of the same session that ends normally, with exit 0; then the stop. The stop still says `Felix's prompt hook did not finish`.
- **B17.** A run that ends normally leaves nothing to report. After a `user-prompt` run that exits 0, a stop on the clean tree prints nothing and appends no `says.log` row. (control)
- **B18.** The session mark stays where it is. After a normal `user-prompt` run, `H2/state/session/SID` holds R2's HEAD (control). `hooks/session-start` run with a new SID writes no `H2/state/session/<that SID>` (control). The start record that B13 needs is not the session mark: a summary request still leaves no mark (part 0230).

### C106: a skill used under its bare name counts as used

- **B19.** `felix_route_step_used TRANSCRIPT OWNER:SKILL` (lib/route.sh, sourced in a subshell) returns 0 when the transcript holds `"attributionSkill":"SKILL"` exactly, the bare name the platform gives a project or user skill. It returns 0, as today, for `"attributionSkill":"OWNER:SKILL"`. It returns 1 for:
  - a bare attribution of another skill;
  - an attribution that only begins with SKILL (`"attributionSkill":"SKILL-x"`);
  - `"attributionPlugin":"OWNER"` alone;
  - an MCP tool name of OWNER.
- **B20.** `felix_route_skipped TRANSCRIPT PLAY` leaves out every qualified step whose bare skill was attributed, and prints the rest separated by spaces, in play order.
- **B21.** The router moves on after a bare attribution. Give `p2` a `routes.tsv` row `build<TAB>build implement feature create<TAB>core<TAB>superpowers:brainstorming superpowers:writing-plans superpowers:executing-plans` and a `stack.tsv` row `plugin<TAB>superpowers@claude-plugins-official<TAB>claude-plugins-official<TAB>low<TAB>always`. Run `user-prompt` with the prompt `build and implement the new feature` and a transcript of one line, `{"type":"assistant","attributionSkill":"brainstorming"}`. Its context contains `Use this now: superpowers:writing-plans`. With an empty transcript it contains `Use this now: superpowers:brainstorming`. (control for the empty transcript)

### C107: provision says what did not arrive, inside the hook's time

*Provision fixture.* Everything lives under `$TMP/b07p`.
- **The script under test** is the real one, `$(cd "$REAL_HARNESS/../.." && pwd)/.claude/cloud/provision`. If it is absent, every provision assertion is `bad` and names the path. It is never skipped, because the suite runs from the felix-home tree.
- **A template repository**, made with `git init -b main`: one commit holding `README`, then `git update-ref refs/remotes/origin/main HEAD`, and origin set to `$TMP/b07p/no-origin`, which does not exist. Each case runs in a fresh `cp -R` copy, P, which gets `P/.claude/cloud/provision` (a copy of the real one) and the case's `P/.claude/cloud/toolbox.json`.
- **The toolbox**, in the real file's layout (an object whose `tools` array holds entries with `name`, `carry`, and, for `fetch`, `source`, `sha`, `subdir` and `note`):
  - `superpowers`, fetch, `fx/superpowers` at forty `1`s, subdir `.`;
  - `alpha`, fetch, `fx/plugins` at forty `2`s, subdir `plugins/alpha`;
  - `beta`, fetch, the same source and sha, subdir `plugins/beta`;
  - `gamma`, builtin, with a note.
- **Served trees**, each a tar.gz whose one top directory is `<repo>-<sha>`:
  - `fx/superpowers` holds an executable `hooks/session-start` that prints exactly `{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"SP-CONTEXT-B07"}}`, and `skills/brainstorming/SKILL.md`;
  - `fx/plugins` holds `plugins/alpha/skills/alpha-skill/SKILL.md` and `plugins/beta/agents/beta-agent.md`.
- **Stubs**, first on PATH:
  - `curl` takes the URL argument `https://codeload.github.com/<owner>/<repo>/tar.gz/<sha>`, appends `<owner>/<repo>@<sha>` to `calls`, and follows that source's plan line. `serve` writes the tarball to stdout and exits 0. `refuse` prints `curl: (22) The requested URL returned error: 403` to stderr and exits 22. `hang` appends its pid to `pids`; given `-m N` or `--max-time N` it sleeps N and exits 28, and otherwise it execs `sleep 300`.
  - `git`, for a `fetch` subcommand, appends to `fetches` and follows its plan: `refuse` exits 1, and `hang` appends its pid to `pids` and execs `sleep 300`. Any other command execs the real git.
- **A run** is `printf '%s' '{"source":"startup"}' | env -u CLAUDE_CODE_REMOTE PATH=<stubs>:$PATH HOME=$TMP/b07p/home FELIX_CLOUD_FORCE=1 FELIX_CLOUD_CACHE=<the case's own cache> [FELIX_CLOUD_BUDGET=N] bash P/.claude/cloud/provision --session-start`, killed at 60 s. Record stdout, the exit status and the seconds elapsed. The log is `<cache>/provision.log`.
- **Skips.** An assertion that needs provision to read a well-formed toolbox is skipped where `jq` is not on PATH, because provision reads the toolbox with jq.

- **B22.** Nothing missing (control). With both sources served, a startup run exits 0. Its stdout equals the served `hooks/session-start` output byte for byte. `P/.claude/skills/brainstorming/SKILL.md`, `P/.claude/skills/alpha-skill/SKILL.md` and `P/.claude/agents/beta-agent.md` exist, and `.git/info/exclude` holds the line `/.claude/skills/brainstorming`. A run with `{"source":"resume"}` prints nothing.
- **B23.** What is missing is said. With `fx/superpowers` served and `fx/plugins` refused, the run exits 0 and prints one JSON object in which:
  - `.systemMessage` names `alpha`, `beta` and the log's path;
  - `.hookSpecificOutput.hookEventName` is `SessionStart`;
  - `.hookSpecificOutput.additionalContext` holds a line that begins `MISSING` and names `alpha`, another for `beta`, and still `SP-CONTEXT-B07`.

  With `{"source":"resume"}` the report is the same, without `SP-CONTEXT-B07`. With every source refused, the report names `superpowers`, `alpha` and `beta`, and holds no `SP-CONTEXT-B07`.
- **B24.** A source that failed is tried once in a run. In B23's refused run, `calls` holds `fx/plugins@2222…` exactly once.
- **B25.** One time budget covers the whole run. `FELIX_CLOUD_BUDGET` is a whole number of seconds, 90 by default, which is below the 120 s that settings.json gives the hook. Any other value is read as 90. It is one deadline for every network call the run makes: a curl or a `git fetch` still running at the deadline is ended, and an entry the run never reached is reported with the words `not tried`. Three cases:
  - (a) Every curl and every `git fetch` hangs, origin/main is absent, and `FELIX_CLOUD_BUDGET=4`. The run exits 0 within 30 s. Its stdout names `superpowers`, `alpha`, `beta` and `origin/main`. Two seconds after it exits, no pid in `pids` is still running.
  - (b) `FELIX_CLOUD_BUDGET=0`, with origin/main present. The run exits 0 within 10 s, `calls` stays empty, and the stdout says `not tried` and names `superpowers`, `alpha` and `beta`.
  - (c) `FELIX_CLOUD_BUDGET=soon` with every source refused. The run exits 0 and its report names all three, as it would with the default.
- **B26.** A missing base is said. With origin/main absent, `git fetch` refused and both sources served, `.systemMessage` names `origin/main`, and the context holds a `MISSING` line naming `origin/main` as well as `SP-CONTEXT-B07`.
- **B27.** A toolbox that cannot be read is said. `toolbox.json` reads `{ not json`. `--report` exits non-zero and prints a line that begins `MISSING` and contains `toolbox.json`. `--session-start` exits 0, and its `systemMessage` contains `toolbox.json`. This must hold where jq is absent too, so it is not skipped.
- **B28.** (control) Outside a cloud session, with neither `CLAUDE_CODE_REMOTE=true` nor `FELIX_CLOUD_FORCE=1` set, a run exits 0, prints nothing, creates no cache directory, and makes no curl call. `--report` with `FELIX_CLOUD_FORCE=1`:
  - on B22's cache: exits 0 and prints a line beginning `carried` for each fetch entry, the builtin entry's line, and a line beginning `base`;
  - on B23's cache: exits non-zero and prints lines beginning `MISSING` for `alpha` and `beta`.
- **B29.** (control) A skill the repository tracks is never overwritten. If P has a committed `.claude/skills/brainstorming/SKILL.md` that reads `OWN`, it still reads `OWN` after a served run.

**Required and not asserted:**
- the default budget of 90 s (a wait that long does not belong in the suite);
- comments corrected where they now overclaim: stop:25-26 ("allows and records"), user-prompt:112-114 (SessionStart now parses a session id; the mark stays at the prompt because of the #264 rule, verify.sh:102-105), and provision:28-29 ("the log says what failed").

---

## 3. What must not change

- **Stop decisions**, pinned by parts 0210-the-completion-gate.sh, 0220-the-binding-itself.sh, 1080-the-stop-hook-holds-once-per-session-per-tre.sh and 1090-the-stop-hook-holds-once-per-session-tree-re.sh:
  - an absent binding is silent;
  - a broken marker holds and writes an `unresolved.log` row;
  - a project with no gate is silent on stdout and stderr (0220's `_allows`);
  - the hold text and its exit status;
  - hold once per session, tree, reason and checkout;
  - the local debt row with empty stdout ("1:debt:[]");
  - the flagged stop after Felix's own hold, which prints nothing and writes no row;
  - the `FELIX_ALLOW_RED` override row.
- **Hold-once economics** (#426). A remote debt's message is a `systemMessage`. It is shown to the person and starts no model turn, so the count of holds does not change.
- **The stop's other outputs:**
  - the green-path plugin report (0290-noticing-when-another-plugin-breaks-the-sess.sh);
  - unrecorded catches (0270-unrecorded-catches-per-checkout-blind.sh, 0280-unrecorded-catches-settled-by-their-writer-b.sh);
  - the skipped-play message, its `--ack` channel and the verification nudge (0250-on-path-via-a-symlink.sh, 0210);
  - the night chain (1080, 1090, 0740-what-a-grant-refuses.sh);
  - a pipe at stack.tsv (1030-a-pipe-at-stack-tsv-read-by-the-stop-hook-in.sh);
  - a tree git cannot read (1520-git-readers-fail-closed.sh);
  - the payload's cwd (0204-hooks-stand-where-the-session-stands.sh);
  - project.json read in a UTF-8 locale (0994-bash-s-own-collation-and-the-bsd-text-tools.sh).
- **The prompt hook** (0230-the-intent-router.sh, 0204, 0210, 0800-the-lifecycle-recorder.sh):
  - the session mark is written at the first prompt, and the first mark wins;
  - a summary request leaves no mark, brief, route or ledger entry;
  - the route renders and the due step advances (0240-continued.sh, 0250). The new start record must not live under `state/session/`.
- **Step counting.** One superpowers skill does not mark the plugin's other steps used, owner-level answers count only for bare steps, and an MCP call marks only the bare plugin step (0240).
- **SessionStart:**
  - the broken-binding report (0220);
  - the `Gate:` line for governed projects (1130-unattended-work-runs-only-in-its-own-checkout.sh);
  - the lifecycle row (0800).
- **The monitor:**
  - the classes of `allowed`, `blocked`, `override` and `debt` (1090 section I);
  - the rendered `felix monitor --log` page (0590-the-pre-flight.sh, 0600-what-to-do-next.sh).
- **Every executable file** under the engine begins with the same caller-environment block as `engine/harness/felix` (1510-no-caller-environment-changes-a-tool-s-output.sh). So the unset that B12 requires is its own command in a prelude part, never a word added to that block.
- **provision.** Outside the cloud it does nothing. A tracked path is never overwritten, the paths it copies are excluded from git, the superpowers context goes out on startup, clear and compact but not on resume, and the `--report` format and exit status stay as they are. No existing part pins these; B22, B28 and B29 add controls for them. `.claude/settings.json` does not change, so the gate's cloud check (projects/felix/gate.sh:598-646) is untouched.
- **Limits.** These files are past 500 lines and must not get longer: `hooks/stop` (610), `hooks/session-start` (780), `lib/verify.sh` (663), `lib/route.sh` (777), `lib/resolve.sh` (1872) and `templates/monitor.html` (563). New logic goes in a new lib under 500 lines, or replaces lines (comments may be tightened). `tests/run` (497) takes only the two new part lines. `hooks/user-prompt`, `lib/monitor.sh` and `.claude/cloud/provision` stay under 500 lines.
- **Coding rules:** bash 3.2 and 5; no awk builtins that only gawk has (1497-lib-awk-gawk-names-blind.sh); and `LC_ALL=C` on each tool that reads bytes Felix did not write (project.json, transcripts), by the lint in tests/run.

---

## 4. Assertions

Part 1750 builds fixture S. Part 1760 builds P2 and the provision fixture. A control holds before and after the fix; every other assertion is red on `69b51a61`.

**Part 1750: the stop**
- A1 (B1): project.json absent. Exit 0; says `Felix could not judge this stop`, `H/projects/p/project.json` and `nothing was held`; no decision.
- A2 (B1): A1's run appended a `verification.log` row with field 2 `unjudged`, field 3 `none`, and field 4 containing `project.json`.
- A3 (B1): A1's run appended a `says.log` row with field 2 `unjudged`.
- A4 (B1): A1's stdout is one JSON object (jq skip).
- A5 to A8 (B1): project.json is a named pipe (the run is not killed at 20 s), then a directory, then a symbolic link to nothing, then mode 000 (skipped where a mode-000 read succeeds). Each says `Felix could not judge this stop` and adds an `unjudged` row.
- A9 (B2, control): `{"name": "p"}`. Exit 0, stdout and stderr empty, no rows.
- A10 (B2, control): `"gate": ""`. The same.
- A11 (control): project.json restored with its gate; the dirty stop holds.
- A12 (B3): `lib/verify.sh` removed. Exit 0; says `lib/verify.sh` and `Felix could not judge this stop`; no decision; `M/unresolved.log` gains a row containing `lib/verify.sh`. Restored afterwards.
- A13 (B3): `lib/resolve.sh` removed. Exit 0; says `lib/resolve.sh`; no decision. Restored afterwards.
- A14 (B4, control): the `lib/<name>.sh` names that `grep -oE 'lib/[A-Za-z0-9._-]+\.sh'` finds in `H/harness/hooks/stop` include all ten of today's.
- A15 to A22 (B4, control): each of `route`, `ready`, `guard`, `say`, `detect`, `maintenance`, `overnight`, `overnight-stop` removed in turn, with a fresh SID each time. The stop still holds.
- A23 (B4): any other name that A14's grep finds, removed: the stop holds or says that name. One assertion per name. On the base commit there are none, and the loop reaches no assertion.
- A24 (B5): session-start with project.json absent. Stdout contains `Gate: unknown`, `H/projects/p/project.json` and `gate unknown`.
- A25 (B5): and it does not contain `Gate: none declared`.
- A26 (B5, control): `{"name": "p"}` gives `Gate: none declared`.
- A27 (B5, control): with the gate set, `Gate: ` and `/felix gate`.
- A28 (B6): `felix monitor --log` with project.json absent exits 0. The page contains `"name":"p","gate":{"unknown":"` and `"verdict":"unjudged"`.
- A29 (B6, control): project q's `"name":"q","gate":"true"`.
- A30 to A35 (B7): run the page's own script under node with a stand-in document, call `renderLog()`, and read the class of each child of the log panel whose text begins `gate ` (the shape of part 1090's section I). Verdicts: `allowed`, `blocked`, `override`, `debt`, `unjudged`, `quarantine`, `zz-unseen`.
  - A30, A31 and A32 (controls): `allowed` has `ok`; `blocked` has `bad`; `override` and `debt` have `warn`.
  - A33 to A35: `unjudged`, `quarantine` and `zz-unseen` each have `warn` and not `ok`.
  - Every one of them is skipped where node is not on PATH.
- A36 (B8): a remote dirty stop, SID r1, holds. Its reason contains `This is a cloud session.`, `nohup`, `D/felix gate` and `If you stop before the gate passes on this tree, say so in your last message`.
- A37 (B8): and it still contains `Do not describe this work as complete until it has passed.` and `FELIX_ALLOW_RED=1`.
- A38 to A40 (B9, control): the variable unset, then `1`, then `false`. Each stop holds, and its reason contains neither `This is a cloud session.` nor `nohup`.
- A41 (B10/B12, control): r1's flagged stop, remote, prints nothing and adds no row.
- A42 (B10): r1's next unflagged stop, remote, adds one row whose field 2 is `debt` and whose field 4 contains `never verified`.
- A43 (B10): it says `let go with the gate not passed on this tree`, `never verified` and `ends with the VM`, with no `"decision"` and no `"hookSpecificOutput"`. It is one JSON object (jq skip).
- A44 (B10): `says.log` gains a row whose field 2 is `debt`.
- A45 (B11, control): the same three stops, local, SID l1. The debt stop adds one `debt` row and prints nothing.
- A46 (B12): inside the part, `${CLAUDE_CODE_REMOTE+set}` is empty. This is a control on a host that does not export the variable; for the red run before the fix, export it when calling `alone.sh`.

**Part 1760: the prompt hook and the cloud toolbox**
- A47 (B13): run killed by SIGKILL, SID u1, then a clean stop. Exit 0; says `Felix's prompt hook did not finish`; no decision; one JSON object (jq skip).
- A48 (B13): `says.log` gains a row with field 2 `prompt-unfinished` and field 3 `u1`.
- A49 (B15): u1's next stop prints nothing.
- A50 (B13): run killed by SIGTERM, SID u2. The stop says `Felix's prompt hook did not finish`.
- A51 (B14): a killed run for SID u3, then an edit to R2. The stop holds, with a reason containing `Do not describe this work as complete`, and says `Felix's prompt hook did not finish`. The edit is reverted afterwards.
- A52 (B16): a killed run for SID u4, then a normal run for u4 (exit 0), then the stop. It says `Felix's prompt hook did not finish`.
- A53 (B17, control): a normal run for SID u5, then a clean stop. It prints nothing and adds no `says.log` row.
- A54 (B18, control): `H2/state/session/u5` holds R2's HEAD.
- A55 (B18, control): session-start with SID u6 leaves no `H2/state/session/u6`.
- A56 (B19): a transcript holding bare `brainstorming`. `superpowers:brainstorming` returns 0.
- A57 to A60 (B19, controls): each returns 1. With bare `brainstorming`, `superpowers:writing-plans`. With `brainstorming-extra`, `superpowers:brainstorming`. With bare `writing-plans`, `superpowers:brainstorming`. With only `"attributionPlugin":"superpowers"`, `superpowers:brainstorming`.
- A61 (B19, control): `"attributionSkill":"superpowers:brainstorming"` gives 0 for `superpowers:brainstorming`.
- A62 (B20): with bare `brainstorming` and bare `writing-plans`, `felix_route_skipped` over the three-step play prints exactly `superpowers:executing-plans`.
- A63 (B21): the build prompt with the bare-attribution transcript. `Use this now: superpowers:writing-plans`.
- A64 (B21, control): the empty transcript gives `Use this now: superpowers:brainstorming`.
- A65 (B22, control): both sources served, startup. Exit 0; stdout is byte-equal to the served hook's output.
- A66 (B22, control): the three copied paths exist, and the exclude line is present.
- A67 (B22, control): resume, everything carried, prints nothing.
- A68 (B23): `fx/plugins` refused. Exit 0; one JSON object; `.systemMessage` names `alpha`, `beta` and the log's path.
- A69 (B23): its additionalContext has `MISSING` lines for `alpha` and `beta`, and still holds `SP-CONTEXT-B07`. Its `hookEventName` is `SessionStart`.
- A70 (B24): `calls` holds `fx/plugins@2222…` once.
- A71 (B23): the same plan on resume. The report is present, and `SP-CONTEXT-B07` is absent.
- A72 (B23): every source refused. The report names all three fetch entries.
- A73 (B25a): everything hangs, with a budget of 4. Exit 0 within 30 s; the report names all three and `origin/main`.
- A74 (B25a): two seconds later no pid in `pids` is running. Any that is gets killed by pid afterwards, as cleanup.
- A75 (B25b): a budget of 0. Exit 0 within 10 s; `calls` is empty; the output says `not tried` and names all three.
- A76 (B25c): the budget `soon`, with refusals. Exit 0; all three are named.
- A77 (B26): the base is missing. `.systemMessage` names `origin/main`, the context has a `MISSING` `origin/main` line, and `SP-CONTEXT-B07` is still there.
- A78 (B27): toolbox.json is `{ not json`. `--report` exits non-zero with a `MISSING` line containing `toolbox.json`.
- A79 (B27): `--session-start` on that toolbox exits 0, and its `systemMessage` contains `toolbox.json`.
- A80 (B28, control): outside the cloud. Exit 0, no stdout, no cache directory, `calls` empty.
- A81 (B28, control): `--report` on A65's cache. Exit 0, `carried` lines and a `base` line.
- A82 (B28, control): `--report` on A68's cache. Exit non-zero, with `MISSING` lines for `alpha` and `beta`.
- A83 (B29, control): a tracked `.claude/skills/brainstorming/SKILL.md` still reads `OWN`.

---

## 5. Parts

- `engine/harness/tests/parts/1750-stop-says-what-it-could-not-judge-blind.sh`: A1 to A46.
- `engine/harness/tests/parts/1760-prompt-hook-and-cloud-toolbox-blind.sh`: A47 to A83.

Both are sourced by the driver, in that order, after `1600-felix-refuses-a-pattern-kill-blind.sh` and before 9990. Each part builds its own fixtures under `$TMP` and keeps its helpers inside the part: no new `tests/lib` file. Each stays under 500 lines and passes on both `alone.sh … bwk` and `alone.sh … gawk`. B12's unset belongs to the implementation, in a prelude part (part 0005's floor already unsets the `GIT_DIR` family), and not to a new part.

---

## 6. Out of scope, with why

- **C030, a library that aborts while loading** (an unbound variable under `set -u`). bash exits 1 before any guard can run, and the platform reports a non-zero exit as a hook error. No path to it exists: guard.sh runs no code at load time.
- **C030, the other hooks.** pre-tool, post-tool, subagent-stop and session-end end with `|| exit 0` when a library fails to load. That is the recorded design of each, and a fault channel for the whole family of hooks is a design of its own. pulse.sh:398 also skips a project directory that has no project.json, but pulse writes nothing this batch adds.
- **C030, a project bound by its remote that lost its project.json.** It reads as ungoverned, and the hook cannot tell otherwise, because the `remote_match` it would bind on is in the file that is gone.
- **C030, holding instead of saying.** Not chosen. The cause may be the home's storage, which the session cannot repair from its tree. And `felix gate` dies on a project that declares no gate (felix:743), so the work can pass neither `felix merge` nor landing on green.
- **C030, `unresolved.log` has no reader.** That was already true before this batch, and broken markers write there too. B3's saying is the `systemMessage`.
- **C035, CI on pushed `claude/*` branches.** That needs a change to `.github/workflows/gate.yml`, which is the founder's, and the Actions minutes quota already binds. Opening a PR runs CI already.
- **C035, carrying memory off the VM.** This is the founder's open question (docs/handoff/0dh.md, under "Open, and the founder's").
- **C035, the flagged stop right after Felix's own hold** stays silent. The hold before it is in the transcript the person reads, and the platform's rule for a Stop hook's chain stands.
- **C035, the release at stop:587-590** (inside another hook's chain, where the hold could not be recorded). It needs a home whose state cannot be written, and it already writes a row.
- **C102, moving the mark to SessionStart** (the first half of the fix sketch). Refuted: it would end the #264 exemption, which holds only while no mark exists (verify.sh:102-105, 124).
- **C102, why the prompt hook is slow.** The slow steps are after the mark: route context, `felix_route_best`, `felix_route_due` over the transcript, lessons, `felix_say`. Finding which one needs measurement. This batch records each cancellation so that the rate can be read.
- **Not fixed: not a defect.** C102's claim that a timeout before the session mark drops the Stop check on committed work. The skeptic checked all 76 distinct timed-out runs against `state/session`:
  - in 70 the mark already existed before the run began;
  - in 6 the cancelled run itself wrote the mark, 0.8 to 11.2 s into its 30 s, so the slow part comes after user-prompt:123;
  - in none was the mark absent.

  The one session with no mark (5141dd42) was not a timeout: `timedOut false`, 104 ms, then "[Request interrupted by user]". The scenario's workflow agents never run UserPromptSubmit (none in 7,112 subagent transcripts), and they end through SubagentStop, which reads the parent's mark.
- **C106, `claude plugin install` in provision.** Whether a plugin installed at SessionStart loads in that same session is unmeasured; 0dh saw plugins load only on a resume. It also needs network access that the suite cannot fake.
- **C106, naming the bare skill in the route block and the stop:521 nudge.** Whether the qualified name resolves in the cloud is unmeasured (cloud-verify.md:107 tested only a bare name that was absent). Fixing the count is what removes the false skipped-play ask. `projects/felix/routes.tsv` stays as it is, because local sessions attribute qualified names.
- **C107, the gate's cloud check reading what was fetched.** That would turn every cloud gate red while codeload is refused, which is the only cloud ever measured. The report at session start is where it is said.
- **C107, allowing codeload in the cloud environment.** That is the founder's setting (cloud-verify.md, follow-up 1).
- **C107, the router naming skills the cloud lacks.** The engine never reads `toolbox.json`, by design. The report tells the model what is missing, and `felix route --ack` is the way to decline.

---

## 7. Founder PR

None. The batch changes:
- no `.github/workflows` file;
- no deny row, escape table (`FELIX_ESCAPE_TABLES`) or land row;
- not the commission grant;
- nothing published.

`.claude/cloud/` is classed red by risk.tsv:36, but with no channel, so it stops nothing. `.claude/settings.json` does not change.
