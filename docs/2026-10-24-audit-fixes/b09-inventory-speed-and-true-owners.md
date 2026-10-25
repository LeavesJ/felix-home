# Audit fix b09: inventory speed and true owners

*Written 2026-10-24 against felix-home `origin/main` `69b51a61` (engine 0.49.307), from the batch brief b09 (defects C050, C028, C047 and C025, with their skeptics' notes). Where a skeptic corrected a claim or a severity, this contract follows the correction and says so in §1. Figures marked "measured here" were read on 2026-10-24, read-only, from this laptop's `~/.claude/projects` and from fixtures run against the base engine.*

**This document is the whole contract for assertions.** An assertion author needs nothing else, apart from the suite's helpers (`ok`, `bad`, `is`, `has`, `skip`, `$TMP`, `$FELIX`) and the builders and readers of `tests/lib/lost-work.sh` (`_lw_build`, `_lw_repo`, `_lw_put`, `_lw_mk`, `_lw_mainwt`, `_lw_ago`, `_lw_prs`, `_lw_pr`, `_lw_enc`, `_lw_open`, `_lw_sess`, `_lw_u`, `_lw_ax`, `_lw_h`, `_lw_a`, `_lw_tu`, `_lw_tr`, `_lw_spawn`, `_lw_title`, `_lw_raw`, `_lw_ts`, `_lw_age`, `_lw_run`, `_lw_o`, `_lw_rc`, `_lw_row`, `_lw_col`, `_lw_st`, `_lw_holds`, `_lw_elem`, `_lw_kind`). Line numbers cite the base commit.

---

## 1. Defects

**C050 (medium, slow; the skeptic corrected where the time goes and what sets the window).** `felix inventory` and `felix monitor` take about three minutes on felix-home, because the chip reader reads whole session files, 3.7 GB of them, to decide whether a chip was started.

*Scenario.* The founder opens the lost-work page and waits: `felix inventory --no-gh` took 174 s (144 s user), `felix monitor --no-gh` 171 s, and `--no-host` 21.7 s. Each extra `--repo` runs the inventory again (lost-work.sh:97-98), and the cost grows with transcript history. The skeptic's timing by stage: S2 and S3 (inventory-chips.sh:101-114) are the largest, 65 s of 138 s, where `grep` prints the custom-title and proposal_id lines of 302 whole files holding 3.47 GB; then the proposal list (:34-36, 33 s), the proposal extraction (:41-77, 30 s, every `tool_result` line of 97 files handed to awk) and S1 (:88-99, 7 s). The window at :80 starts at the oldest of all proposals read, started ones included (1675 h). Measured here: 3.57 of the 3.71 GB in that window were modified within the last 14 days, so narrowing the window saves little; reading less of each file is what saves. Not claimed: that roadmap step 7's closing notice needs the inventory (§6).

**C028 (high; both skeptics confirmed it).** A plugin's SDK session, the security-guidance reviewer that the Stop and commit hooks start (`"entrypoint":"sdk-py"`), is filed in the worktree's own record directory after the person's last turn, and the inventory reads it as the worktree's newest session: the wrong owner, a false `blocked`, and the person's open question hidden.

*Scenario.* A person's session ends `Should I merge #12?`. The reviewer then runs in the same worktree and becomes the newest session file (inventory-host.sh:349). If it ends on an unanswered StructuredOutput call, the worktree reads `blocked` with the reviewer's id an hour later (`cloud-toolbox-five`, 280 h, on the live page); if its result was written, the worktree reads neither question nor blocked, and the question never reaches "needs you". The skeptics' corrections: most SDK sessions end with their result written (805 of 879), so hiding the question is the common half and the false `blocked` the rarer (48); a pull request's owner can be a reviewer too (inventory-host.sh:421-426); and `secret-scan-ref` holds no person's session at all, so passing reviewers over leaves its owner `-`, not the session that made its commits (§6). Measured here: 836 of the 1146 session files modified within 30 days that carry an entrypoint carry `sdk-py`; all 764 top-level files whose last 256 KiB name StructuredOutput are SDK ones; in the six helper record directories checked, every top-level session was an SDK one.

**C047 (medium).** A records root that exists but cannot be listed or entered reads as `sessions read`, so blocked, question and live read as complete zeros.

*Scenario.* `~/.claude/projects` (or `$CLAUDE_CONFIG_DIR/projects`) is at mode 000, or belongs to another account. `_fi_host_root` (inventory-host.sh:51-55) tests only `-d`, so the sessions and chips cover rows say `read` (inventory.sh:244-247), every owner reads `-`, every live, question and blocked reads `no`, and the page reports `blocked sessions: 0` and `open questions: 0` as complete. Measured here on the base: at mode 000 every worktree's owner is `-`; at mode 100 the record directories are still found by name while the root-wide listing fails. The skeptic: a missing root, or one whose stat is denied, already reads `unknown` (`no session records`); only a root that can be stat'ed but not entered slips through. It is recorded as open in the lost-work contract's C2 and in the helper-worktrees handoff note.

**C025 (low per the brief and the register; skeptic A argued low, skeptic B medium).** The lost-work page shows helper worktrees only as a count, so helper work that never reached a pull request, such as a dead workflow's per-item commits, is not visible on it.

*Scenario, as the skeptics corrected it.* lost-work.sh:128 puts every `helper` row in group `helper`, and :218 prints only `helper worktrees N`, which cannot tell an unpushed helper from a landed one. The 10 rows the evidence cited are not lost work: their content reached main through other pull requests (94 to 100% of their added lines are on main), and they read `not` or `partly` only because the suite was split into parts. `felix inventory` and `--tsv` list every helper row. What remains: when a workflow dies before its commits are carried, the page does not say that work is there.

---

## 2. Required behaviour

### Terms used below and in §4

- **Records root, record directory, session file** are as the host adapter defines them (inventory-host.sh:6-14). A fixture's records root is `<home>/.claude/projects`, with the home given to `_lw_run`.
- **Person record**: a line as `_lw_u` or `_lw_ax` writes it. **SDK record**: the same line with `,"entrypoint":"sdk-py","cwd":"<the worktree's path>"` inserted before its final `}`, after its `"timestamp"`, which is where Claude Code writes it. **Desktop record**: the same with `claude-desktop` for `sdk-py`.
- **A record's entrypoint** is the value of the last `"entrypoint":"` in its line (Claude Code writes a record's own keys after its message).
- **SDK session file**: a session file the run can read whose last user or assistant record that has an entrypoint, within its last 256 KiB, has one beginning `sdk-`. A file none of whose records there has an entrypoint is not one.
- **Reviewer session R(m, pending | answered)**, in this order: the line `{"type":"queue-operation","operation":"enqueue","timestamp":"<m+1 minutes ago>","sessionId":"<sid>","content":"Review this change for security vulnerabilities."}`; an SDK user record of that text at m+1; an SDK assistant record holding only a `tool_use` of `StructuredOutput`, id `toolu_<sid>`, input `{"findings":[]}`, at m. *Answered* adds an SDK `tool_result` for that id and an SDK assistant text `No findings.`, both at m. File mtime m minutes ago.
- **Person session P(m, TEXT[, desktop])**: a user record of human text `fix it` at m+2, then an assistant record of TEXT at m, person records (desktop records when marked). File mtime m.
- **ASK** is the text `Fixed and committed. Should I merge #12?`.
- **Filler line**: `{"type":"progress","data":"`, then 4,000 `x`, then `"}` (4,030 bytes with its newline). Every reader passes such a record over.
- **Windows** of a session file: its first 1,048,576 bytes (**head**) and its last 262,144 bytes (**tail**). A record is in a window only when its whole line is. A file of 1,310,720 bytes or less is read whole.
- **CPU of a run**: the run inside a subshell that ends with the builtin `times`; the two fields of `times`' second line (`XmY.YYYs`, user and system) summed, in seconds. It counts the run and every process under it.
- Defaults the fixtures rely on (inventory.sh:147): `live` within 60 minutes, `blocked` after 20, `--days` 14.

### C028: a plugin's SDK session is not the worktree's session

- **B1.** `felix inventory` reads a record directory's session files as if its SDK session files were absent: none of them is the owner, and none decides `question` or `blocked`. So a person's question stays the worktree's while a reviewer runs after it, and an SDK session's unanswered StructuredOutput call is no wait. When no other session file remains, the owner is `-` and the detail gains the element `passed over <n> SDK session(s)`, n being how many were passed over. When another session file remains, no element begins `passed over`.
- **B2.** An SDK session file is no activity: neither its record time nor any file under its `<sid>/` directory makes the directory `live`. The other activity sources stay (inventory spec §6.3 and §6.4: the other sessions' records and `<sid>/` files, a helper's spawning transcript).
- **B3.** Only a record's own entrypoint counts. A desktop session whose human text quotes `\"entrypoint\":\"sdk-py\"` (escaped, inside a JSON string), or one of whose records holds a tool input `{"entrypoint":"sdk-py"}` before its own `"entrypoint":"claude-desktop"`, is a person's.
- **B4.** A session file with no entrypoint at all is a person's, as every existing fixture is, and a pending call in it, StructuredOutput included, is a wait as today. (control)
- **B5.** A pull request's owner (inventory spec §6.7) is never read from an SDK record: a record line whose entrypoint begins `sdk-` names no owner and adds nothing to an owner's activity. With only such records for a head, the owner is `-` and the row holds no `live`.
- **B6.** A session file the run cannot read is not known to be an SDK one, and reads as today: owner `unknown` when it is the newest by mtime, `unknown:` for what it could decide, and the unread count in the sessions cover row. (control)
- **B7.** On the page (`felix monitor --tsv`), a worktree that B1 makes `question` is in group `question`, and one B1 releases from `blocked` is not in group `blocked`.

### C047: a records root the run cannot read is unknown

- **B8.** When the records root exists as a directory but the run cannot both list it and enter it (it fails `-r` or `-x`: modes 000, 100 and 400 for a user who is not root), `felix inventory --tsv` prints:
  - the `sessions` cover row with states exactly `unknown,unknown:live,unknown:question,unknown:blocked` and detail exactly `Claude Code session records under $HOME/.claude/projects could not be read` (`$HOME` literal, as in the readable detail);
  - the `chips` cover row with states exactly `unknown,unknown:chip-unstarted` and the same detail;
  - every worktree row with owner `unknown`, holding `unknown:live`, `unknown:question` and `unknown:blocked` and none of `live`, `question` or `blocked`; a helper-form name also carries `unknown:helper` and no `helper`;
  - every pull request row with owner `unknown`, holding `unknown:live`;
  - no chip row.
- **B9.** With `CLAUDE_CONFIG_DIR` set and its `projects` unreadable as in B8, the detail is `Claude Code session records under $CLAUDE_CONFIG_DIR/projects could not be read` (literal), whatever `$HOME/.claude/projects` holds.
- **B10.** On the page (`felix monitor --tsv`) under B8: the `blocked`, `question`, `running` and `helper` summaries are `incomplete`, content `unknown` when they hold no row, and each reason holds the element `sessions unknown: Claude Code session records under $HOME/.claude/projects could not be read`; the `never-proposed` summary is `incomplete` and its reason holds the element `chips unknown: Claude Code session records under $HOME/.claude/projects could not be read`.
- **B11.** Unchanged (controls): a readable root reads `read`, detail `Claude Code session records under $HOME/.claude/projects`; a missing root reads as today, detail `no session records` (part 0920's A31); one worktree's record directory at mode 000 under a readable root leaves the sessions cover row's first word `read` and gives that worktree owner `unknown` and the element `could not read the record directory <its path>`.

### C050: the chip reader reads windows, not whole files

- **B12.** *S2, a title* (lost-work contract A3), reads only the windows of each session file, the proposing files included: a `custom-title` record equal to the chip's title starts the chip when it lies in the file's head or tail, and not when it lies only between them. Every other S2 condition stands (a file other than the proposer's, modified after the proposal, the decoded title equal byte for byte).
- **B13.** *S3, a start call*, reads the windows of each session file, and the whole of each file the reader reads whole for proposals (an in-scope file modified within `--days` that holds a proposal). The `start_session` call naming the chip's task id as `proposal_id` and a `tool_result` for that call must both lie in what is read: in any other file, a call and result only between the windows start nothing.
- **B14.** *S1, a prompt*, is unchanged: a starter whose first human text begins with the chip's prompt starts the chip however long the file is. So are the proposals, the dismissals, the result rules (A2), the expiry, and the unread-file rule (`unknown:chip-unstarted`, the chips cover row's count). (control)
- **B15.** Session files outside every window cost nearly nothing. Adding, outside the repository's scope and modified after its proposals, eight session files of 16 MiB of filler lines each (each opening with a user record of human text, four of them then with a `custom-title` that names no chip) adds at most 0.75 s to the CPU of `felix inventory --tsv --no-gh`, comparing the lower of two runs with them and the lower of two runs without, interleaved. And they change no chip row. On the base the extra is about 2.2 s (measured here).

### C025: the page says how much helper work never reached a pull request

- **B16.** On the text page, when group `helper` holds rows whose states hold `uncommitted`, `unpushed`, `unproposed` or `pr-closed-unlanded`, or `orphan` with content other than `landed` (what would place a row in `never-proposed` but for `helper`), the line right after the `collapsed:` line is exactly `  helper worktrees holding work that never reached a PR: <k>`, k being how many rows. The `collapsed:` line is unchanged, and no helper row's ref appears on any line. When no row holds them, no such line is printed and the `collapsed:` line stays the block's last. When helper rows not counted carry the `unknown:` form of one of those states, the count reads `at least <k>`, or `unknown` when k is 0.
- **B17.** `--tsv` is unchanged: 17 summary rows per repository and every row as before. (control)

### Required, and not asserted

- **The felix-home measurement (C050).** From a `mktemp -d` scratch, run `felix inventory --tsv --no-gh --repo /Users/a14808/Documents/Felix` with the base engine and with the fixed one, back to back. The fixed run's user CPU is at most half the base run's. Their rows are equal once the age column and the digits of the detail are read as N, except (a) worktree and pull request rows whose owner, `live`, `question` or `blocked` B1, B2 or B5 change, and (b) chip rows whose start B12 or B13 decides differently; each is listed in the pull request. The windows bound S2 and S3; the rest of the halving is expected from the proposal read, which hands every `tool_result` line of the proposing files to awk where the proposal lines, then the results of their ids, would do.
- **Contract text.** In `docs/2026-10-18-lost-work-page-contract.md`, each clause replaced in place, the file getting no longer (it is past 500 lines), each replacement naming this contract: C0's "What needs a person is said by the spawning session's own row" (now B16's count); C2's bullet on a records root the run cannot enter (closed by B8); A3's S2 and S3 (B12, B13); B6's statement that the `collapsed:` line is last (B16); and, where it restates inventory spec §5.2's owner `-`, that SDK sessions are not counted (B1).
- **Comments** that would otherwise claim less or more than the code: the adapter's head (inventory-host.sh:1-37: SDK sessions, an unreadable root), the chip reader's head (inventory-chips.sh:14-20: the windows) and lost-work.sh's head (the count line).
- **Not asserted for want of a fixture:** B16's `at least` and `unknown` forms; a root that passes `-r` and `-x` but whose listing fails (a sandbox) also reads as B8 says.

---

## 3. What must not change

- **Chips:** A2 and A3 on files that fit the windows (B9.13 to B9.25), the unread-file rule and its count of files later than a proposal, `--days`, the card expiry, denied and unanswered proposals. Pinned by `1460-lost-work-inventory-chips-blind.sh`, `0900-felix-inventory-the-settled-contract-of-2026.sh` (A99, A119), `0930-continued.sh` (M4-R4) and `0920-continued.sh`.
- **The adapter's other readings:** the owner as the newest session, activity from `<sid>/` files and a spawning transcript, `blocked` after `--blocked` unless a `<sid>/` file is newer, the ask rule, the 256 KiB end window, both spellings of a path, long names, an unreadable record directory, a file named `.jsonl` (owner `unknown`, contract C8.1). Pinned by `0920-continued.sh` (A76 to A94), `0930-continued.sh`, `1570-helper-worktrees-inventory-blind.sh` and `1585-helper-worktrees-review-fixes-blind.sh`.
- **A pending StructuredOutput call in a session with no entrypoint is a wait:** 1570's C5.4 (`blocked,unproposed,helper`).
- **PR owners:** the record's own `sessionId`, resumed sessions, `-` for a fork, `unknown` when an unreadable file is newer. Pinned by the owner assertions of `0910-continued.sh` to `0930-continued.sh`.
- **`--no-host` and a missing root** (sessions and chips `unknown`, every owner `unknown`), and `CLAUDE_CONFIG_DIR` read literally: 0920's A31 and N13, 1570's C5.5, 1580's C5.17.
- **Helpers (contract Part C):** `1570-helper-worktrees-inventory-blind.sh`, `1580-helper-worktrees-page-blind.sh`, `1585-helper-worktrees-review-fixes-blind.sh`.
- **The page:** groups, 17 summaries, B4's reasons, the text page, the terminal filter, exit status: `1470-lost-work-page-groups-blind.sh`, `1480-lost-work-page-readings-blind.sh`, `1490-lost-work-review-fixes.sh`, `1495-lost-work-page-awk-fails-blind.sh`, and 1580. 1470's B9.33 (the `collapsed:` line is last) holds on its fixture, which has no helper row; 1580's C5.16 reads the `collapsed:` line, which B16 does not change.
- **Read-only:** the inventory and the page write nothing outside one scratch directory each, removed on exit and on signals: `0880-felix-inventory-what-review-found-each-held.sh`, `0910-continued.sh` (A13, RV11), `0920-continued.sh` (A14), 1470 (B9.34). No cache outlives a run.
- **Lints:** the adapter runs no git, and no library but `inventory*.sh` names the inventory's files (`0940-the-handoff-as-sections-no-two-sessions-writ.sh`, A111); no library reads a here-document or here-string (0880); no gawk-only awk name (`1497-lib-awk-gawk-names-blind.sh`); every git call keeps `_fi_git`'s flags (0910, A11).
- **Limits:** `lib/inventory.sh` (483 lines), `lib/inventory-host.sh` (444), `lib/inventory-items.sh` (269), `lib/lost-work.sh` (219) and `lib/inventory-chips.sh` (141) each stay under 500. `tests/run` gains the two part lines only.
- **Coding rules:** bash 3.2 and 5; BWK awk and gawk; `LC_ALL=C` on every tool that reads transcripts; digit brackets spelled out; the adapter's line read by position, never by a tab-IFS split (C8.1); no pipe into a grep that can stop early.

**Existing assertion restated.** Part 1570's "C5.6 control: with the records root unreadable the main worktree's owner is -, where it is s5-boss when the root is read" pins C047's defect. It keeps its case and fixture; its expected value becomes `unknown s5-boss`, and its name says `unknown` where it says `-`. No other existing assertion changes: no fixture before this batch writes an entrypoint, puts an S2 or S3 record past a file's head, or puts helper work on a page whose last line is read.

---

## 4. Assertions

A control holds before and after the fix; every other assertion is red on `69b51a61` (A36 on macOS grep; with GNU grep the base may pass it).

### Part 1790: true owners and an unreadable root

*Fixture tw9 (C028).* `_lw_repo tw9`, with worktrees on branches of their own from main under `$LW/tw9-wt/`: `ask9`, `asr9`, `ctl9`, `sdk9`, `nest9`, `old9`, `blk9`, `unr9`, `prw9`. Home `$LW/htw9`, records in each worktree's own record directory:
- `ask9`: P(120, ASK, desktop), then R(118, pending). R's records and mtime are newer than P's mtime, so a reader that lets an SDK file's record time end its newest-first scan never reads P.
- `asr9`: P(120, ASK, desktop), then R(118, answered). `ctl9`: P(120, ASK, desktop) alone.
- `sdk9`: R(5, pending) alone, and a file `<its sid>/tool-results/t.txt` beside it, 2 minutes old.
- `nest9`, desktop records only: a user record of human text `please check \"entrypoint\":\"sdk-py\" handling` at 124; an assistant `tool_use` of `mcp__fx__probe`, input `{"entrypoint":"sdk-py"}`, at 123; its `tool_result` at 122; an assistant text ASK at 120; mtime 120.
- `old9`: P(120, ASK). `blk9`, person records: user `run the checks` at 292, then an assistant `tool_use` of `StructuredOutput`, input `{"findings":[]}`, at 290, unanswered; mtime 290.
- `unr9`: P(120, ASK), and a newer person-shaped session file at 60 minutes, set to mode 000 for run T and back to 600 after it.
- Pull requests: commits X and Y made with `_lw_mk` on main and pushed to origin as `pr9` and `pr9b`, with no local branch; `_lw_prs fixture_tw9` lists #91 (head `pr9` at X) and #92 (head `pr9b` at Y), open. In `prw9`'s record directory: a person session whose two records carry `,"gitBranch":"pr9"` at 31 and 30 minutes; an SDK session whose records carry `,"gitBranch":"pr9"` at 6 and 5; an SDK session whose records carry `,"gitBranch":"pr9b"` at 11 and 10.

Runs: `inventory --tsv --repo tw9` (T), then `monitor --tsv --repo tw9` (M).

- A1 (B1): `ask9` has owner its person session's id, holds `question` and not `blocked`, and its detail holds the element `ended on: Fixed and committed. Should I merge #12?`.
- A2 (B1): `asr9` has owner its person session's id and holds `question`.
- A3 (B1, control): `ctl9` has owner its session's id and holds `question`.
- A4 (B1): `sdk9` has owner `-`, holds neither `question` nor `blocked`, and its detail holds the element `passed over 1 SDK session(s)`.
- A5 (B1, control): no element of `ask9`'s or `asr9`'s detail begins `passed over`.
- A6 (B2): `sdk9` does not hold `live`.
- A7 (B3, control): `nest9` has owner its session's id and holds `question`.
- A8 (B4, control): `old9` has owner its session's id and holds `question`; `blk9` holds `blocked`, and its detail holds an element beginning `waiting on StructuredOutput for `.
- A9 (B5): the `pr` row `#91` has owner the person session's id and holds `live`.
- A10 (B5): the `pr` row `#92` has owner `-` and does not hold `live`.
- A11 (B6, control): `unr9` has owner `unknown` and holds `unknown:question`. Skipped where a mode-000 file is readable.
- A12 (B7): in M, `ask9` and `asr9` are in group `question`, `blk9` is in group `blocked`, and the `blocked` summary's content is 1.

*Fixture uw9 (C047).* `_lw_repo uw9`; a helper-form worktree `$UW9/.claude/worktrees/agent-9f9f9f01` on a branch of its own; a commit Z pushed as `uw9pr` with no local branch, listed open as #95 by `_lw_prs fixture_uw9`. Home `$LW/huw9a`: in the main worktree's record directory, session `s9-main`: a user record at 202, `_lw_spawn 201 toolu_9u task_9c9c9c01 'Chip uw nine' 'Prompt uw nine: do it once.'`, an assistant text `The branch is ready. Shall I push it?` at 200, mtime 200; in `agent-9f9f9f01`'s record directory, a person session whose records carry `,"gitBranch":"uw9pr"` at 31 and 30. Homes `huw9z`, `huw9x` and `huw9r` are `cp -Rp` copies of `huw9a/.claude`, their `.claude/projects` then at modes 000, 100 and 400; `huw9n` has a `.claude` with no `projects`; `huw9d` is a copy whose main worktree record directory is at mode 000. `$LW/cuw9` holds a copy of `projects` at mode 000. A case whose directory is still readable and searchable after its chmod is skipped. Every mode returns to 755 at the part's end.

Runs, each `inventory --tsv --repo uw9`: UA, UZ, UX, UR, UN and UD under those homes; UC under home `huw9a` with `CLAUDE_CONFIG_DIR=$LW/cuw9`, through the part's own runner (`_lw_run`'s body with `CLAUDE_CONFIG_DIR` set where it unsets it). And `monitor --tsv --repo uw9` under `huw9z` (UM).

- A13 (B8): UZ's `sessions` cover row has states `unknown,unknown:live,unknown:question,unknown:blocked` and detail `Claude Code session records under $HOME/.claude/projects could not be read`.
- A14 (B8): UZ's `chips` cover row has states `unknown,unknown:chip-unstarted` and the same detail.
- A15 (B8): UZ's main worktree has owner `unknown`, holds `unknown:live`, `unknown:question` and `unknown:blocked`, and none of `live`, `question` or `blocked`.
- A16 (B8, control): UZ's `agent-9f9f9f01` carries `unknown:helper` and not `helper`.
- A17 (B8): UZ's `pr` row `#95` has owner `unknown` and holds `unknown:live`.
- A18 (B8, control): UA lists the chip `task_9c9c9c01`; UZ lists no chip row.
- A19 (B8): UX's `sessions` cover row has A13's states and detail.
- A20 (B8): UR's `sessions` cover row has A13's states and detail.
- A21 (B9): UC's `sessions` cover row has A13's states and detail `Claude Code session records under $CLAUDE_CONFIG_DIR/projects could not be read`.
- A22 (B10): in UM, the `blocked`, `question`, `running` and `helper` summaries are `incomplete` with content `unknown`, and each reason holds the element `sessions unknown: Claude Code session records under $HOME/.claude/projects could not be read`.
- A23 (B10): in UM, the `never-proposed` summary is `incomplete`, and its reason holds the element `chips unknown: Claude Code session records under $HOME/.claude/projects could not be read`.
- A24 (B11, control): UA's `sessions` cover row is `read` with detail `Claude Code session records under $HOME/.claude/projects`; the main worktree has owner `s9-main` and holds `question`.
- A25 (B11, control): UN's `sessions` cover row has A13's states and detail `no session records`.
- A26 (B11, control): UD's `sessions` cover row's first word is `read`; its main worktree has owner `unknown`, and its detail holds the element `could not read the record directory $LW/huw9d/.claude/projects/<E>`, E being `_lw_enc` of the main worktree's path.

### Part 1800: chip windows and helper work on the page

*Fixture cw9 (C050 windows).* `_lw_repo cw9` and a worktree `$LW/cw9-wt/own9`. Home `$LW/hcw9`. In the main worktree's record directory, session `s9-prop`: a user record at 612, then `_lw_spawn 610` for each of these, title then task id, each prompt `Prompt nine <n>: do the named thing and test it once.` with n the task id's last digit: `Chip head nine` `task_9e000001`, `Chip tail nine` `task_9e000002`, `Chip mid nine` `task_9e000003`, `Chip s3 head nine` `task_9e000004`, `Chip s3 tail nine` `task_9e000005`, `Chip s3 mid nine` `task_9e000006`, `Chip s3 own nine` `task_9e000007`, `Chip prompt nine` `task_9e000008`; an assistant `Filed.` at 600; mtime 600. Starters, each alone in a record directory `-elsewhere-<name>` under the root and outside the scope, each opening with a user record of human text `unrelated <name>` at 302 and ending with an assistant `Done.` at 300, mtime 300:
- `hd9`: the `custom-title` `Chip head nine` right after its first record, then 600 filler lines.
- `tl9`: 600 filler lines, then the title `Chip tail nine`.
- `md9`: 400 filler lines, the title `Chip mid nine`, 300 filler lines.
- `s3hd9`: right after its first record, `_lw_tu 302 toolu_9go4 mcp__ccd_session__start_session '{"proposal_id":"task_9e000004"}'` and `_lw_tr 302 toolu_9go4 'Started.'`, then 600 filler lines.
- `s3tl9`: 600 filler lines, then that call and result for `task_9e000005` (id `toolu_9go5`).
- `s3md9`: 400 filler lines, that call and result for `task_9e000006` (id `toolu_9go6`), 300 filler lines.
- `pr9`: its first record is a user record whose human text is exactly chip 8's prompt; then 600 filler lines.

And in `own9`'s record directory (in scope), session `s9-own`: a user record at 402; `_lw_spawn 401 toolu_9o task_9e000009 'Chip other nine' 'Prompt nine 9: do the other thing once.'`; 400 filler lines; the call and result for `task_9e000007` (id `toolu_9go7`) at 302; 300 filler lines; an assistant `Done.` at 300; mtime 300. Run: `inventory --tsv --no-gh --repo cw9` (CW).

- A27 (B12, control): CW has no row `task_9e000001`.
- A28 (B12, control): CW has no row `task_9e000002`.
- A29 (B12): CW's row `task_9e000003` is a chip with states `chip-unstarted`.
- A30 (B13, control): CW has no row `task_9e000004`.
- A31 (B13, control): CW has no row `task_9e000005`.
- A32 (B13): CW's row `task_9e000006` is a chip with states `chip-unstarted`.
- A33 (B13, control): CW has no row `task_9e000007`, and its row `task_9e000009` has states `chip-unstarted`.
- A34 (B14, control): CW has no row `task_9e000008`.
- A35 (fixture control): by `grep -b` offsets, the title line of `md9` and the call line of `s3md9` each begin at least 1,572,864 bytes into the file and end at least 1,048,576 bytes before its end; the title and call lines of `hd9` and `s3hd9` lie in the first 65,536 bytes, and those of `tl9` and `s3tl9` in the last 65,536.

*Fixture cb9 (C050 cost).* `_lw_repo cb9`. Home `$LW/hcb9`: in the main worktree's record directory, session `s9-bprop` with `_lw_spawn 610 toolu_9b task_9e00000b 'Chip bulk nine' 'Prompt nine b: carry the bulk once.'` and an assistant `Filed.` at 600; mtime 600. The bulk, built under `$LW/bulk9` (outside the root): eight record directories `-elsewhere-bulk9-<i>`, i from 1 to 8, each holding one session file that opens with a user record of human text `bulk <i>` at 302, then (for i up to 4) a `custom-title` `Bulk title <i>`, then 16,777,216 bytes of filler lines (its last line cut, then a newline), then an assistant `Done.` at 300; mtime 300. The run is `inventory --tsv --no-gh --repo cb9`, each one measured as CPU of a run, in this order: A1 with the bulk away; the bulk directories moved into the root with `mv`; B1; moved out; A2; moved in; B2; moved out. Then `$LW/bulk9` is removed.

- A36 (B15): min(B1, B2) minus min(A1, A2) is at most 0.75 s; a failure's detail prints all four values.
- A37 (B15, control): B1's chip rows, ref and states, equal A1's: one row, `task_9e00000b`, `chip-unstarted`.

*Fixture hq9 (C025).* `_lw_repo hq9`, helpers under `$HQ9/.claude/worktrees/` (inside the main worktree): `agent-9a0a0a01` with one unpushed commit; `agent-9a0a0a02` with one untracked file; `agent-9a0a0a03` with nothing of its own; `agent-9a0a0a04` with nothing of its own, its record directory holding a person session whose last record is a `Bash` call 290 minutes old, unanswered; and `agent-9a0a0a05`, a plain directory (no worktree) holding one file of its own. A plain worktree `$LW/hq9-wt/plain-9u` with one unpushed commit. Home `$LW/hhq9`: session `s9-qboss` in the main worktree's record directory (a user record at 302, an assistant at 300, mtime 300) and, for each helper n, `s9-qboss/subagents/agent-q<n>.meta.json` holding `{"agentType":"general-purpose","description":"helper <n>","worktreePath":"<its path>"}` beside an `agent-q<n>.jsonl` holding `{}`, both 300 minutes old, the shape parts 1570 and 1580 build. `_lw_prs fixture_hq9` with no pull request. *Fixture hr9*: the same with only `agent-9b0b0b01` (nothing of its own) and `agent-9b0b0b02` (blocked as above) and no plain worktree. Runs: `monitor --repo hq9` (QX), `monitor --tsv --repo hq9` (QT), `monitor --repo hr9` (RX).

- A38 (B16): QX's `collapsed:` line holds the element `helper worktrees 5`, and the line after it is exactly `  helper worktrees holding work that never reached a PR: 3`.
- A39 (B16, control): no line of QX names the path of any of the five helpers (as 1580's C5.16 reads it), and `plain-9u` is listed once.
- A40 (B17, control): QT holds 17 summary rows; the `helper` summary is `complete` with content 5; `plain-9u` is in group `never-proposed`, whose summary is `complete` with content 1.
- A41 (B16, control): no line of RX begins `  helper worktrees holding`, and RX's last line is its `collapsed:` line, which holds `helper worktrees 2`.

---

## 5. Parts

- `engine/harness/tests/parts/1790-inventory-true-owners-blind.sh`: A1 to A26.
- `engine/harness/tests/parts/1800-inventory-chip-windows-blind.sh`: A27 to A41.

Both are sourced by the driver in numeric order, after every part below 1790 and before 9990. Each calls `_lw_build`, builds its fixtures under `$LW` with names of its own and keeps its helpers inside the part (no new `tests/lib` file), so it runs alone. Each stays under 500 lines and passes on `alone.sh … bwk` and `alone.sh … gawk`, the two given together. Part 1800 removes its 128 MiB of bulk before it ends.

---

## 6. Out of scope, with why

- **Not fixed: not a defect.** C050's claim that roadmap step 7's session-end notice would call the inventory within a hook budget. The step 7 line is the PR readiness line (L6a), made by `felix land` through `lib/pr-status.sh`, which sources only `lib/inventory-gh.sh`, never the chip reader (skeptic's note 3).
- **C028, "never treat a pending StructuredOutput call as a wait".** Once SDK files are passed over it is not needed: every top-level file found ending near a StructuredOutput call is an SDK one (§1). A rule on the tool's name would also release a real wait, which 1570's C5.4 pins as `blocked`.
- **C028, queue-operation as the mark.** A person's desktop session writes queue-operation records when a message is typed during a turn (seven desktop session files of the main checkout hold them), so the entrypoint is the mark.
- **C028, naming the session that made `secret-scan-ref`'s commits.** It ran from another directory, and sessions filed under another path are not read (inventory spec §10). Owner `-` with B1's element is the true answer there.
- **C028, a record with no entrypoint of its own whose content holds a tool input `{"entrypoint":"sdk-…"}`.** B3's last-key rule reads it as SDK. None was seen: current Claude Code writes its own entrypoint on every user and assistant record.
- **C050, a cache that outlives the run.** The inventory and the page write nothing outside one scratch directory each (§3), and the inventory is "derived, every time" (inventory.sh:8). A per-user cache changes both contracts: a design of its own, once the felix-home measurement says what remains.
- **C050, `felix monitor` reading the root once for several repositories.** After B12 and B13 what two inventories share is S1's first texts and the S2 windows, a few seconds; the rest is each repository's own scope. Sharing it would need the page to hand the inventory a cache or to split one run's rows by repository, and the page derives no fact (its contract's B2).
- **C050, capping the started-check window** at a card's lifetime, at `--days` or at the oldest unstarted chip. 3.57 of the 3.71 GB in the window were modified within 14 days, so a cap saves little, and any cap leaves older chips undecided.
- **C050, a window for S1.** S1 stops at the first human text and cost 7 s. The first user record of a desktop session is often 300 KB long, and the first title, which follows it, was seen 3.9 MB into a file, so a head bound would lose starts.
- **C025, `helper` only while the spawning session is live (the fix sketch).** It would put the 10 leftover rows back under "work that never reached a PR", the false alarms Part C removed (contract C6), and it misses a workflow killed under a live spawner. B16's count says the work is there without claiming each row needs the founder.
- **C025, listing helper rows on the page.** The same reason; `felix inventory` lists each one under `in helper worktrees`.

---

## 7. Founder PR

None. The batch changes `lib/inventory-host.sh`, `lib/inventory-chips.sh`, `lib/inventory-items.sh`, `lib/inventory.sh` where the core needs it, `lib/lost-work.sh` and the lost-work contract, and adds parts 1790 and 1800. It touches no `.github/workflows` file, no deny, escape or land row, not the commission grant, and publishes nothing. It is risk-red for its lib edits and merges on green.

---

## 8. Red

*Run on 2026-10-24 on `c4ae0e2d` (the contract and the two blind parts, no engine change), before any code was touched: `alone.sh <worktree> bwk 1790-inventory-true-owners-blind.sh 1800-inventory-chip-windows-blind.sh`, macOS awk under bash 3.2, one run of both parts, about 2.5 minutes. The run counted 83 `ok` and 20 `FAIL`; 62 of the `ok` lines are the suite's own preamble (the fixture-floor checks the driver prints before any part), so the two parts hold 41 assertions: **20 failed, 21 passed.**

**The 20 that failed (all non-controls, as §4 says):** A1, A2, A4, A6, A9, A10, A12 (C028); A13, A14, A15, A17, A19, A20, A21, A22, A23 (C047); A29, A32, A36 (C050); A38 (C025). Each failed on the reading the contract says is wrong, not on a fixture fault. A1 and A2 read the reviewer as owner (`t9-ask-r`, `t9-asr-r`) with `question` no; A4 gives the reviewer's id as owner; A6 finds `sdk9` live; A9 and A10 read the SDK sessions' ids as the pull requests' owners (A10 live); A12 puts `ask9` and `asr9` in no `question` group and counts two blocked; A13, A14, A19, A20, A21 read the sessions and chips cover rows as `read`; A15 and A17 give owner `-` and `unknown:*` `no`; A22 and A23 give the summaries `complete`, content 0. A29 and A32 find no row for the chip (the whole file is read, so the mid-file title or call starts it). A36 measured A1 0.694 s, A2 0.681 s, B1 2.800 s, B2 2.839 s, all four runs exiting 0: 2.119 s more, near the 2.2 s the contract measured on the base. A38 found the `collapsed:` line the page's last line.

**The 21 that passed, and why:**

- *Controls that hold before and after (already true on the base; they guard what the fix must keep)*, 16: A3, A7, A8 (B1, B3, B4: a person's session, an SDK entrypoint only quoted, no entrypoint at all); A11 (B6: not skipped, a mode-000 file was unreadable here); A16 (B8: the base already says `unknown:helper` for a helper whose spawning transcript it cannot read); A24, A25, A26 (B11: readable root, missing root, one record directory at 000); A27, A28, A30, A31, A33, A34 (B12 to B14: a title or call in the head or the tail, an in-scope file read whole, a first human text, which a reader of whole files finds too); A37 (B15: the same one chip row with the bulk present); A40 (B17: `--tsv` unchanged).
- *Vacuous on the base (they assert the absence of something the base never prints, so they only become a test once the fix prints it elsewhere)*, 4: A5 (no `passed over` element: the base prints none), A18 (its second half, no chip row at a mode-000 root: the base reads nothing there, so lists none; its first half, the chip under the readable root, is a live control), A39 (no helper path on the page: the base prints a count only), A41 (no count line and `collapsed:` last: the base prints no count line for any fixture; this one starts to bite when B16 prints a line elsewhere).
- *Fixture control (no engine involved)*, 1: A35 (offsets by `grep -b`).

No assertion passed for the wrong reason that the fix would make false; none was already true while labelled as red. `tests/run` exits 0 under `--part` whatever the count of FAIL lines, so the `FAIL` count is read from the log, not from the status.
