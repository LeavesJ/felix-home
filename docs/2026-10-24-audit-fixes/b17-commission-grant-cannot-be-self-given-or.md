# Audit fix b17: the commission grant is not a session's to give, and says what it grants

*Written 2026-10-24 against felix-home `origin/main` `69b51a61` (engine 0.49.307), from the batch brief b17 (defects C032, C033, C034, C085, C068, C048, each with its skeptics' notes). Where a skeptic corrected a claim or a severity, this contract follows the correction and says so in §1. This batch touches a founder stop (the commission grant, its consent text, and deny rows): it is built and tested fully, opened as a draft labelled `needs-founder`, and only he merges it.*

**This document is the whole contract for assertions.** An assertion author needs nothing else, apart from the suite's own helpers (`ok`, `bad`, `is`, `has`, `skip`, `_copy_content`, `_fx_cd`, `_fx_git`, `$TMP`, `$REAL_HARNESS`). Line numbers cite the base commit.

This is the floor, not the wall (memory felix-floor-and-wall). Everything below stops a session that follows Felix's instructions. A session that unsets its own environment, fakes a terminal, or writes a file through a shell redirect is not stopped, and nothing here may claim it is.

---

## 1. Defects

**C032 (medium; skeptic A argued low, skeptic B medium, and this contract follows B).** A session can give itself the `tidy` or `commission` grant, and nothing records who gave it.

*Scenario.* A session runs `felix autonomy --allow commission` (or `--allow tidy`) from its Bash tool. `cmd_autonomy` (felix:2269-2424) checks the argument shape and a writer lock and nothing else: no terminal test (the CLI's only one is felix:1195), no `CLAUDECODE` or `CLAUDE_CODE_SESSION_ID`. It writes the grant and the stamp (felix:2375-2379), records nothing, and then prints "a permission a system grants itself is not a permission" (felix:2388-2389). No deny row names an autonomy file (projects/felix/deny.tsv:33-34 cover only `.felix`). From then on every session start in the project's own checkout runs `felix commission` with nobody present (own.sh:269-291). Measured on this tree: a run with `CLAUDECODE=1 CLAUDE_CODE_SESSION_ID=x` and stdin `/dev/null` grants either capability, exit 0. The skeptics' corrections, which this contract follows: the planted-check scenario is a hostile session, which the floor does not claim to stop; the careless case is the defect (Felix's own merge text names the exact command, felix:2019-2024, and nothing refuses a session that runs it); the grant is not silent for the two projects that hold one, because their autonomy files are tracked and the land tick pauses on a tracked change (§6).

**C033 (medium; one skeptic argued high, one medium).** The founder's hold on a stale commission is cleared by any session's `felix commission`, and session start tells sessions to run it.

*Scenario, as the skeptics corrected it.* A PR adds or changes a `commissioning.tsv` row. The policy version moves, so every receipt reads stale and `felix merge` refuses (escape.sh:779-781), printing that the commission "is not a session's to clear" (felix:2014) and that "a session does not commission for itself" (felix:2035-2036). Session start, because provider answers are keyed to `commissioning.tsv` (commission-provider.sh:103-127), puts in the model's context "A session still owes these — run the skill each request names, write the answer file it names, then felix commission" (session-start:731-734). The session runs `felix commission`; `cmd_commission` checks nothing about its caller (felix:5707-5715); the receipt comes back `held`, which is valid (commission.sh:700-705); the next merge lands. Not claimed (skeptics): a `deny.tsv` change does not produce that session-start line, since the topology does not hash `deny.tsv`; there a session clears the hold only by acting on the blocker row's own text `run felix commission` (commission.sh:687).

**C034 (medium; one skeptic argued high).** The commission grant's consent text says the run installs nothing; the unattended run installs plugins and MCP servers.

*Scenario.* `felix autonomy` prints "What it does NOT do is install anything ... installing them is still felix stack apply, which a person still runs" (felix:2411-2414), and lib/autonomy.sh:30-33 says "no installer is downstream of it". With the grant current, session start runs `felix commission` detached; the runner maps `felix:stack apply --yes`, `felix:discover --adopt` and `felix:ready --fix` to the real commands (felix:5696-5705), each held row runs its answer (commission.sh:474-477), and `claude plugin install --scope user`, `claude plugin marketplace add` or `claude mcp add` runs for every row the install policy admits (stack.sh:301-314; lib/admit.sh: low DECLARED or OBSERVED, medium DECLARED). `ready --fix` also runs `claude plugin enable` (felix:3625-3640). Measured on this tree with a stub `claude`: a grant and one run installed `some-low-plugin@mkt --scope user` and never the high row. The install policy is the founder's (2026-09-04), so option (a) of the brief is taken: the text is corrected and the grant is bound to it. Option (b), reporting installer answers as held under the unattended run, would contradict that decision.

**C048 (low; the skeptic refuted the "merge let through" consequence).** The nine projects' `commissioning.tsv` check cells drift from the template's.

*Scenario.* `felix_commission_template_drift` (commission.sh:779-796) reports 9 drifting `check` cells for bazaar, behaviorchangebench, elenchus-capital-research, felix, sv2-apps, team1 and webapp, and 8 for elenchus and veldra; no other column drifts (measured). The project cells lack the template's `LC_ALL=C` on `grep`, so under a UTF-8 locale `grep -c .` skips a line holding an invalid byte and a row reads answered when it is not. elenchus-capital-research also keeps the pre-#393 shapes: a `$(felix_... | grep -c ...)` substitution whose producer can die unseen, and stack/preflight/human_steps checks that never look for `unknown`. A person running `felix commission` sees nine drift rows in every project and cannot tell which matter. What the skeptic refuted is in §6.

**C085 and C068** are dropped from this batch (§6).

---

## 2. Required behaviour

### Terms used below and in §4

- **Caller class.** `terminal` when the command's standard input is a terminal. Otherwise `session` when `CLAUDECODE` or `CLAUDE_CODE_SESSION_ID` is set and non-empty. Otherwise `no-terminal`. A session's Bash tool, as measured, is `session`; the CI runner and launchd are `no-terminal`.
- **Fixture A.** Under `B` = `$TMP/b17a`: a home `G` = `B/home` holding `harness/` (a `_copy_content` copy of `$REAL_HARNESS`) and `projects/p/` with `project.json` reading `{"name": "p", "remote_match": "example/p", "gate": "true"}`, `CLAUDE.md` reading `# p`, a `commissioning.tsv` holding only the template's `stack` row (the line of `harness/templates/commissioning.tsv` whose first field is `stack`), and a `stack.tsv` of two rows, `plugin<TAB>some-low-plugin@mkt<TAB>-<TAB>low<TAB>always` and `plugin<TAB>some-high-plugin@mkt<TAB>-<TAB>high<TAB>always`. Memory root `M` = `B/mem`; user home `U` = `B/user`; `B/tmp` of mode 700; a stub directory `S` holding an executable `claude` that appends its arguments (`$*`) and a newline to `B/claude.log`, prints nothing and exits 0, and a `gh` that exits 0. The checkout `R` = `B/repo`: `git init -b main`, origin `https://github.com/example/p.git`, a `.felix` reading `p`. `R2` = `B/other`: the same but origin `https://github.com/someone-else/p.git` (bound to `p`, not its own checkout). "Fresh fixture A" means one rebuilt from nothing.
- **Fixture B.** The same shape under `$TMP/b17b`, with project `q` (`remote_match` `example/q`, origin `https://github.com/example/q.git`, `.felix` reading `q`) and its own harness copy.
- **Run.** `cd R && env -u CLAUDECODE -u CLAUDE_CODE_SESSION_ID -u FELIX_COMMISSION_UNATTENDED HOME=U FELIX_HOME=G FELIX_MEMORY=M TMPDIR=B/tmp PATH=S:$PATH [NAME=value ...] G/harness/felix ARGS </dev/null`. This is a **no-terminal run**. A **session run** adds `CLAUDECODE=1 CLAUDE_CODE_SESSION_ID=b17-sid`. A **terminal run** is the no-terminal command under a pseudo-terminal: BSD `script -q /dev/null CMD...` or util-linux `script -q -e -c "CMD" /dev/null`, whichever makes `sh -c 'test -t 0 && echo b17-tty'` print `b17-tty`; where neither does, every terminal case is skipped with a reason naming `script`, never passed. Terminal output is compared after removing carriage returns and `^D` followed by two backspaces. Every run that has not ended in 60 s is killed, with every process below it, by pid. Record stdout, stderr and exit status.
- **says row.** A line appended to `M/p/says.log`. Tab-separated fields: 1 time, 2 kind, 3 session, 4 cause, 5 text (field 5 may end in a literal `\n`, so it is matched by its start).
- **The stamp** is `G/projects/p/autonomy.commission`. **Policy version P**: what `( . H/lib/resolve.sh; . H/lib/detect.sh; . H/lib/commission.sh; felix_commission_policy_version G/projects/p )` prints, H being the harness copy (0579 computes it this way). **Currency**: what `( . H/lib/resolve.sh; . H/lib/detect.sh; . H/lib/commission.sh; . H/lib/autonomy.sh; felix_autonomy_commission_current G/projects/p && echo current || echo stale )` prints.
- **Status page**: the stdout of a no-terminal run of `felix autonomy` with no arguments. **The commission line**: its one line matching `^ *\[.\] commission `, compared with leading blanks removed and each run of blanks collapsed to one space.
- **Snapshot**: the sorted list of every path under `G/state`, `G/projects/p` and `M/p`, each regular file with its `cksum`, leaving out `M/p/says.log`. **Changes nothing** means equal snapshots before and after.
- **Unattended run**: a run with `FELIX_COMMISSION_UNATTENDED=1` added.

### C032: a grant is typed by a person, and says who typed it

- **B1.** A session run of `felix autonomy --allow tidy`, or `--allow commission`, is refused before anything is written or locked: exit 1; stderr contains `<cap> is not allowed`, `from a terminal` and `Nothing was written`; `G/projects/p/autonomy` and the stamp are unchanged (absent stays absent, present stays byte-identical); no `G/projects/p/autonomy.lock` is left. One says row is appended: field 2 `consent`, field 3 the session id, field 4 `felix autonomy`, field 5 beginning `refused: allow <cap> (session)`.
- **B2.** A refused session run is refused whole. `--revoke tidy --allow commission` with tidy granted exits 1, stderr contains `commission is not allowed` and `tidy is not revoked`, and `autonomy` still holds the line `tidy`.
- **B3.** Taking a grant away, and reading, stay open to a session. A session run of `--revoke tidy` exits 0, removes the grant as today, and appends one says row: field 2 `consent`, field 3 the session id, field 4 `felix autonomy`, field 5 beginning `revoked tidy (session)`. A session run of `felix autonomy` with no arguments exits 0, changes nothing and appends no says row.
- **B4.** A no-terminal or terminal grant works as today and is recorded. `--allow commission` exits 0, prints `allowed: commission` and `stamped against`, and writes a stamp of exactly two newline-ended lines: line 1 is P (as today, so every `head -1` reader is unchanged); line 2 is four tab-separated fields `consent`, H, the caller class (`terminal` or `no-terminal`), and the UTC time as `YYYY-MM-DDTHH:MM:SSZ`. H is a run of 40 or more lowercase hex digits (B21-B23 say what it is). One says row: field 2 `consent`, field 3 `-` when no session id is set, field 4 `felix autonomy`, field 5 beginning `allowed commission (<class>)`. `--allow tidy` records `allowed tidy (<class>)` the same way and writes no `autonomy.tidy`.
- **B5.** Re-granting commission re-stamps (as today) and records another row. `--allow tidy` when tidy is already allowed prints `already allowed: tidy`, writes nothing and records no row: a row is written only when the grant or the stamp was, or a grant was refused.
- **B6.** Field 3 is the session id, or `-` when it is unset, empty, or holds a tab or a newline; a says row always has exactly five fields and is one line.
- **B7.** `terminal` wins over the session variables: a terminal run with `CLAUDECODE=1 CLAUDE_CODE_SESSION_ID=b17-sid` may grant, and records `(terminal)` with field 3 `b17-sid`.
- **B8.** The status page says where the stamp was made, on a line after the commission line: `stamped from a terminal` (line 2 class `terminal`), `stamped with no terminal attached` (`no-terminal`), `the stamp does not say where it was made` (any other value; currency is unaffected by it). Every status page has exactly one commission line (0574's `_lwpage` reads it), and every one says what the refusal is worth, containing `not one that works around it` (for example: "Felix refuses a grant typed by a session. That stops a session that follows its instructions, not one that works around it.").
- **B9.** A record that cannot be written is said, and does not undo the grant. With `M/p` a regular file, a no-terminal `--allow tidy` exits 0, `autonomy` holds `tidy`, and stdout or stderr contains `not recorded`.
- **B10.** *Deny rows (founder stop).* `projects/felix/deny.tsv` gains exactly two rows whose reason (field 3) begins `a grant is a person's word`: one `Write`, one `Edit`, each with four fields, field 4 `checkout`, and the same field 2. With those two rows alone in a fixture project's `deny.tsv`, `hooks/pre-tool` refuses (exit 2, the reason whole on stderr) a `Write` or `Edit` of `projects/<name>/autonomy` or `projects/<name>/autonomy.<lowercase word>` anywhere but a throwaway fixture outside the bound checkout, including under `.claude/worktrees/`, and allows `commissioning.tsv`, `docs/autonomy`, `my-autonomy`, `autonomy/notes`, a `Read` of an autonomy file, and a path under `$TMPDIR` outside the bound checkout. A path inside the bound checkout is refused (the `checkout` scope). Measured on this tree with the rows of §7: every case of A24-A25 gives the stated answer.
- **B11.** The suite runs with `CLAUDECODE` unset. Part 0004, which already unsets `CLAUDE_CODE_SESSION_ID` ("No session, as on the CI runner"), unsets `CLAUDECODE` beside it, so a gate run from inside a session judges the no-terminal behaviour CI judges.

### C033: the commission run is a person's or the grant's, never a session's

- **B12.** A session run of `felix commission` (no `--status`) is refused before the lock or any table is read for running: exit 1; stderr contains `from a terminal`, `nothing was run or written` and `felix commission --status`; it changes nothing (an existing receipt keeps its bytes); `claude` is never called. One says row: field 2 `consent`, field 3 the session id, field 4 `felix commission`, field 5 beginning `refused: commission run (session)`.
- **B13.** `felix commission --status` stays open to a session. Its exit status is the no-terminal run's, its stdout is the no-terminal run's once every run of digits is replaced by `0`, and it changes nothing, says.log included.
- **B14.** `FELIX_COMMISSION_UNATTENDED=1` (exactly `1`) marks the run session start makes on the grant. Then, whatever the caller class, `felix commission` runs only when the grant is current (B21) and the checkout is the project's own (`felix_checkout_is_own`), and then runs as a no-terminal run does. Otherwise it exits 1 having changed nothing, with stderr containing `FELIX_COMMISSION_UNATTENDED` and `nothing was run or written`, and `no current commission grant` (grant absent, stale, or not over this engine's consent) or `own checkout` (grant current, checkout not its own). Any other value (`yes`, `0`, empty) is as if unset. `--status` is unaffected by it.
- **B15.** `felix_commission_resume_bg` passes `FELIX_COMMISSION_UNATTENDED=1` to the detached run, keeping its arguments exactly `commission` (part 1130's stub logs `$*`) and its log words. Session start in a session's environment, with the grant current and the checkout its own, still runs the commission: the bg log gains a `ran` row and the low row is installed.
- **B16.** Session start's owed paragraph no longer tells a session to run the commission. Where provider rows are awaiting, the context still says `A session still owes these` and `write the answer file it names`, says the run is made `from a terminal` (or by the grant's unattended run), names `felix commission --status` as how to read where the rows stand, and no longer contains `write the answer file it names, then felix commission`.
- **B17.** The skill `engine/commands/felix.md` no longer says `` Then run `felix commission` again ``, and says the run is made `from a terminal`.
- **B18.** `felix new` from a session binds the project and does not commission: exit 0, the project directory and `project.json` exist, the checkout's `.felix` names the project, no receipt is written, and stdout contains `commissioning skipped` and `from a terminal`. A no-terminal `felix new` commissions as today (control).
- `felix merge`'s three grant paragraphs (felix:2006-2037) are unchanged. Their sentences "The commission is not a session's to clear" and "a session does not commission for itself" are now held by B12 at the floor.

### C034: the consent says what the run does, and the grant is bound to that text

- **B19.** In every grant state (none, current, stale), the status page contains, each whole on one line: `With nobody present, the run installs`, `at user scope`, `nothing marked high is installed`, and `enables`. It contains neither `What it does NOT do is install anything` nor `which a person still runs`. In the engine, exactly one file outside `tests/` holds a line containing `With nobody present, the run installs`. The wording is the builder's; one that carries all four: "With nobody present, the run installs every stack.tsv row the install policy admits (a low row, and a medium row a person declared), through claude plugin install, plugin marketplace add or mcp add, at user scope, and it enables a plugin that is installed but disabled; nothing marked high is installed, and a medium row Felix only observed waits for a person."
- **B20.** The text is true (control). A no-terminal `felix commission`, and an unattended run under a current grant, call `claude` with a line containing `plugin install`, `some-low-plugin@mkt` and `--scope user`, and with no line containing both `some-high-plugin@mkt` and `install`.
- **B21.** The grant is current only when the stamp's line 1 is P **and** its line 2 has field 1 `consent` and field 2 equal to the H this engine computes. When line 1 differs from P, the commission line reads `[!] commission granted, but not over this commissioning.tsv` (today's wording). When line 1 is P but line 2 is missing, malformed, or carries another H (a one-line stamp, as every engine before this one wrote), it reads `[!] commission granted, but not over what this engine says the grant does`. Either way the currency is `stale`, the unattended run is refused (B14), and `felix merge`'s grant paragraph is the stale one. The currency is the same whether computed by the CLI or by a subshell that sources only `resolve.sh`, `detect.sh`, `commission.sh` and `autonomy.sh` (so whatever H needs is loaded by those).
- **B22.** H is a hash of the commission's consent text as the engine holds it, not as printed: it is the same for every project and every home path, and for two copies of the same engine at different paths.
- **B23.** H moves with the consent text and with nothing else on the status page: an engine copy whose consent line is edited computes another H; one whose tidy paragraph is edited computes the same H.
- **B24.** A stamp that cannot be written is said and never reported as stamped. When something that is not a regular file is at the stamp's path (a directory, a named pipe), `--allow commission` returns within 20 s, exits non-zero, prints `stamp` and `not written` on stderr, prints `stamped against` nowhere, and leaves the thing at that path as it was; the commission line afterwards does not begin `[x]`. Measured on the base: a directory there gives exit 0 and `stamped against`.

### C048: the project tables carry the template's checks

- **B25.** For every `projects/*/commissioning.tsv` in the repository, `felix_commission_template_drift <project dir> <harness>/templates` exits 0 and names no row whose field 2 contains `check`. (Today only `check` drifts, so after the refresh it prints nothing.)
- **B26.** Three lints hold for the template and every project table, on field 6 (`check`) of every row that is not a comment and has seven fields:
  - **L1.** Every word `grep`, `cut` or `tr` that starts the field or follows a blank, `|`, `(` or `;`, and is followed by a blank or the field's end, is immediately preceded by `LC_ALL=C ` (nine characters).
  - **L2.** No `$(felix_` substitution has a `|` before its first `)`.
  - **L3.** The checks of the rows `stack`, `preflight` and `human_steps` contain `unknown`.
  The template passes all three today; every project table fails L1, and elenchus-capital-research also fails L2 and L3 (measured).

### Required and not asserted

- The comments that state the false or now-stale rule are corrected: lib/autonomy.sh:21-43 ("no installer is downstream of it", "when a person types the command"), lib/own.sh:261-262 ("`felix commission` typed by a person is not refused anywhere"), and the status page's "a permission a system grants itself is not a permission" sentence, which B8's floor sentence replaces or qualifies.
- When H cannot be computed, nothing is stamped and the run says so as in B24.
- The consent text and the caller-class test live in one lib that `autonomy.sh` loads itself (as `commission.sh` loads `final-filter.sh`), so no caller sees a different H.
- Files that must not grow: `felix` (6734 lines), `lib/autonomy.sh` (722), `lib/commission.sh` (808), `lib/escape.sh` (799), `hooks/session-start` (780), `lib/commission-provider.sh` (633). The consent paragraphs move out of `felix` into the lib, which pays for the new code there. `lib/own.sh` (291) and any new lib stay at or under 500. `engine/commands/felix.md` (118) and `projects/felix/deny.tsv` (190) may grow by what B10 and B17 need.
- Bash 3.2 and 5; no `case` inside `$( )`; `LC_ALL=C` on every sort and comparison; no associative arrays; no gawk-only builtins (part 1497).

---

## 3. What must not change

- **A no-terminal caller sees today's behaviour**, apart from the says row, the stamp's second line, the status page's added line and the consent wording: grants, revokes, refusals, NUL-byte and lock handling, and every message they print. Parts `0030-appends-onto-a-hand-written-last-line.sh`, `0040-an-unterminated-last-line-that-cannot-be-end.sh`, `0050-appends-that-fail-paths-that-are-not-files-a.sh`, `0571-revoke-is-the-inverse-of-the-reader.sh`, `0572-allow-says-allowed-only-when-the-grant-holds.sh`, `0573-the-autonomy-file-has-one-writer-at-a-time.sh`, `0574-revoke-then-allow-on-a-last-line-with-no-new.sh` (its `_lwpage` and its count of `allowed`/`revoked` in the stamp, which stays 0), `1020-readers-keep-the-unended-last-line-of-a-hand.sh`.
- **The stamp's line 1 and the policy version.** `FELIX_COMMISSION_TABLES` and `felix_commission_policy_version` are unchanged (`0190-continued.sh`, `0680-continued.sh`, `0681-continued.sh`, `0990-land-table-l2a.sh`). A table edit still stales the grant (`0579-the-commission-grant-is-bound-to-its-table.sh`).
- **The receipt and the merge.** Ten tab fields (`0690-continued.sh`, `0700-continued.sh`), `felix_commission_receipt_valid` accepting `commissioned` and `held`, the commission blocker (escape.sh:754-783), `felix merge`'s grant paragraphs and its CLI grant and revoke cases (`0100-merging.sh`). The commission lock, its message and `--status` (`0700-continued.sh`); a check run under `--status` (`0711-commissioning-a-check-says-it-could-not-be-a.sh`, `1510-no-caller-environment-changes-a-tool-s-output.sh`).
- **The unattended run's shape.** `felix_commission_resume_bg`'s refusals, its `ran` / `declined-or-failed` / `refused-not-own` log, and the argument `commission` (`1130-unattended-work-runs-only-in-its-own-checkout.sh`, `0580-tidying-with-the-checks-that-make-it-safe.sh`). `felix_commission_apply_declares` installs nothing (0580).
- **`felix new` without a session** (`0820-felix-new-no-commission-governed-not-commiss.sh`).
- **The authority escape** regex and the escape table list (`0090-what-a-revert-cannot-undo.sh`, `0990-land-table-l2a.sh:212`).
- **Denial.** `hooks/pre-tool`, `felix_deny_match`, lib/where.sh, the `.felix` rows and every other row (`0610-denial-reads-the-command-the-shell-runs.sh`, `0620-denial-refuses-what-a-command-changes-not-wh.sh`, `1600-felix-refuses-a-pattern-kill-blind.sh`); table shapes (`0730-schema-check-every-table-declared-every-row.sh`).
- **Fixture lines that change, assertions unchanged.** `0579-...` lines 15-17 and 1130's `_ow_stamp` (lines 72-73) write a one-line stamp by hand and expect it current; under B21 they write the stamp as the engine writes it (a no-terminal `felix autonomy --allow commission`, or the lib's own stamp writer). `0004-the-widget-fixture.sh` gains `unset CLAUDECODE` (B11). `0580-...`:23 repeats the false sentence in a comment and may be corrected.

---

## 4. Assertions

Part 1950 holds A1-A37; part 1960 holds A38-A60. **(control)** marks an assertion that passes on today's engine and must keep passing.

**Prelude and C032**

- **A1 (B11).** In the part's shell, `${CLAUDECODE+set}` and `${CLAUDE_CODE_SESSION_ID+set}` are both empty.
- **A2 (B1).** Fixture A, nothing granted: a session run of `felix autonomy --allow tidy` exits 1; stderr contains `tidy is not allowed`, `from a terminal`, `Nothing was written`.
- **A3 (B1).** After A2, `G/projects/p/autonomy` and `G/projects/p/autonomy.lock` do not exist.
- **A4 (B1).** A session run of `--allow commission` exits 1, stderr contains `commission is not allowed`, `from a terminal`, `Nothing was written`, and neither `autonomy` nor the stamp exists.
- **A5 (B1).** A2 and A4 appended exactly two says rows, both with field 2 `consent`, field 3 `b17-sid`, field 4 `felix autonomy`; field 5 begins `refused: allow tidy (session)` in the first and `refused: allow commission (session)` in the second.
- **A6 (B1).** With tidy granted by a no-terminal run, a session run of `--allow commission` leaves `autonomy`'s `cksum` unchanged and creates no stamp.
- **A7 (B2).** With tidy granted: a session run of `--revoke tidy --allow commission` exits 1; stderr contains `commission is not allowed` and `tidy is not revoked`; `autonomy` holds a line exactly `tidy`.
- **A8 (B3).** A session run of `--revoke tidy` exits 0; `autonomy` holds no line `tidy`; one says row is appended with field 3 `b17-sid` and field 5 beginning `revoked tidy (session)`.
- **A9 (B3).** (control) A session run of `felix autonomy` exits 0; the snapshot and says.log's line count are unchanged.
- **A10 (B4).** A no-terminal run of `--allow commission` exits 0; stdout contains `allowed: commission` and `stamped against`. (control for the exit and the words)
- **A11 (B4).** The stamp has exactly two lines, and line 1 equals P.
- **A12 (B4).** Line 2 has exactly four tab fields: `consent`; a match of `^[0123456789abcdef]{40,}$`; `no-terminal`; a match of `^[0123456789]{4}-[0123456789]{2}-[0123456789]{2}T[0123456789]{2}:[0123456789]{2}:[0123456789]{2}Z$`.
- **A13 (B4).** A10 appended one says row: `consent`, `-`, `felix autonomy`, field 5 beginning `allowed commission (no-terminal)`.
- **A14 (B4).** A no-terminal `--allow tidy` appends one row with field 5 beginning `allowed tidy (no-terminal)`, and `G/projects/p/autonomy.tidy` does not exist.
- **A15 (B5).** A second no-terminal `--allow commission` appends one more `allowed commission (no-terminal)` row and the stamp still has two lines; a second `--allow tidy` prints `already allowed: tidy` and appends no row.
- **A16 (B6).** A session run of `--allow tidy` with `CLAUDE_CODE_SESSION_ID` set to `b17`, a tab, `x` appends exactly one line to says.log, with exactly five fields and field 3 `-`. The same with a newline in place of the tab.
- **A17 (B4, B7; terminal).** A terminal run of `--allow commission` exits 0; line 2 field 3 is `terminal`; the says row's field 5 begins `allowed commission (terminal)`.
- **A18 (B7; terminal).** A terminal run with `CLAUDECODE=1 CLAUDE_CODE_SESSION_ID=b17-sid` of `--allow tidy` exits 0; `autonomy` holds `tidy`; the row's field 3 is `b17-sid` and field 5 begins `allowed tidy (terminal)`.
- **A19 (B8).** The status page after A17 contains `stamped from a terminal`; after A10, `stamped with no terminal attached`. With line 2's field 3 of an engine-written stamp replaced by `elsewhere`, it contains `the stamp does not say where it was made` and the commission line begins `[x] commission`.
- **A20 (B8).** Every status page this part reads has exactly one commission line and contains `not one that works around it`.
- **A21 (B9).** With `M/p` a regular file reading `x`, a no-terminal `--allow tidy` exits 0, `autonomy` holds `tidy`, and stdout or stderr contains `not recorded`.

**Deny rows (B10).** The rows are read out of `$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix/deny.tsv` by their reason, as part 1600 reads its row, and put alone into `G/projects/d/deny.tsv`, with `G/projects/d/project.json` reading `{"name": "d", "gate": "true"}` and a checkout `B/drepo` (`git init -b main`, `.felix` reading `d`). A case is `cd B/drepo && printf '%s' '{"tool_name":"T","tool_input":{"file_path":"PATH","content":"x"},"cwd":"B/drepo"}' | env FELIX_HOME=G FELIX_MEMORY=M TMPDIR=$TMP G/harness/hooks/pre-tool`, with B written out as an absolute path. Every name is emitted on every run; with no `deny.tsv` beside the harness, each is skipped with that reason.

- **A22.** Exactly two non-comment rows have field 3 beginning `a grant is a person's word`.
- **A23.** One is `Write` and one `Edit`; each has four fields, field 4 `checkout`; their field 2 is the same.
- **A24.** Refused (exit 2, stderr contains the reason whole): `Write /b17-nowhere/home/projects/p/autonomy`; `Write /b17-nowhere/home/projects/p/autonomy.commission`; `Edit /b17-nowhere/home/projects/felix/autonomy`; `Edit /b17-nowhere/home/.claude/worktrees/w/projects/q/autonomy.tidy`; `Write B/drepo/projects/p/autonomy` (inside the bound checkout).
- **A25.** Allowed (exit 0): `Write /b17-nowhere/home/projects/p/commissioning.tsv`; `Write /b17-nowhere/home/docs/autonomy`; `Write /b17-nowhere/home/projects/p/my-autonomy`; `Write /b17-nowhere/home/projects/p/autonomy/notes`; `Read /b17-nowhere/home/projects/p/autonomy`; `Write B/home/projects/p/autonomy` (a fixture outside the bound checkout). (control for the scope)

**C033**

- **A26 (B12).** Fixture A, no receipt: a session run of `felix commission` exits 1; stderr contains `from a terminal`, `nothing was run or written`, `felix commission --status`.
- **A27 (B12).** A26 changed nothing (snapshot); `G/state/commission/p` does not exist; `B/claude.log` is absent or empty.
- **A28 (B12).** A26 appended one says row: `consent`, `b17-sid`, `felix commission`, field 5 beginning `refused: commission run (session)`.
- **A29 (B12).** After a no-terminal `felix commission` wrote a receipt, and a comment line was then appended to `G/projects/p/commissioning.tsv`, a session run of `felix commission` exits 1 and the receipt's `cksum` is unchanged.
- **A30 (B13).** (control) A session run and a no-terminal run of `felix commission --status` exit with the same status, and their stdouts are equal once every run of digits is replaced by `0`; the session run changes nothing and appends no says row.
- **A31 (B14).** A session run with `FELIX_COMMISSION_UNATTENDED=yes`, and one with `=0`, is refused as A26 (exit 1, stderr contains `from a terminal`).
- **A32 (B14).** (control) A session run of `felix commission --status` with `FELIX_COMMISSION_UNATTENDED=1` exits as A30's no-terminal run does.
- **A33 (B16; jq).** Fixture A with `commissioning.tsv` holding only the template's `constitution_audited` row: `G/harness/hooks/session-start` given `{"source":"startup","session_id":"b17-ss"}` on stdin, run as a session run (`CLAUDE_CODE_SESSION_ID=b17-ss`) from `R`, exits 0. The context (`jq -r '.hookSpecificOutput.additionalContext'` over stdout; skipped where `jq` is not on PATH) contains `A session still owes these`, `write the answer file it names`, `from a terminal`, `felix commission --status`, and does not contain `write the answer file it names, then felix commission`.
- **A34 (B17).** `$REAL_HARNESS/../commands/felix.md` does not contain `` Then run `felix commission` again `` and contains `from a terminal`.
- **A35 (B18).** A home `G3` = `B/newhome` with its own harness copy whose `templates/commissioning.tsv` holds only the template's `stack` row; checkout `R3` (`git init -b main`, origin `https://github.com/example/q.git`, no `.felix`). A session run of `G3/harness/felix new q` (FELIX_HOME=G3) exits 0; `G3/projects/q/project.json` exists; `R3/.felix` reads `q`; stdout contains `commissioning skipped` and `from a terminal`; `G3/state/commission/q` does not exist.
- **A36 (B18).** (control) A no-terminal `felix new r` in a checkout with origin `https://github.com/example/r.git`, same home, exits 0 and `G3/state/commission/r` exists.
- **A37 (B3, B6).** This part's runs appended at least six says rows to fixture A's `M/p/says.log`, and every one has exactly five fields and field 2 `consent`.

**The run installs, and only on the grant (part 1960)**

- **A38 (B20).** (control) Fixture A: a no-terminal `felix commission` exits 0; `G/state/commission/p` is one line of ten tab fields with field 5 `held` or `commissioned`; `B/claude.log` has a line containing `plugin install`, `some-low-plugin@mkt` and `--scope user`, and no line containing both `some-high-plugin@mkt` and `install`.
- **A39 (B14, B20).** (control) Fresh fixture A, commission granted by a no-terminal run: a session run with `FELIX_COMMISSION_UNATTENDED=1` of `felix commission` exits 0, writes the ten-field receipt, and `B/claude.log` has the low install line and no high one.
- **A40 (B14).** Fresh fixture A, nothing granted: an unattended session run exits 1; stderr contains `no current commission grant`, `FELIX_COMMISSION_UNATTENDED`, `nothing was run or written`; it changes nothing; `B/claude.log` is absent or empty.
- **A41 (B14).** Granted, then a comment line appended to `commissioning.tsv` (stale): as A40.
- **A42 (B14).** Granted and current, run from `R2`: an unattended session run exits 1; stderr contains `own checkout` and `nothing was run or written`; no receipt.
- **A43 (B15).** Fresh fixture A, commission granted by a no-terminal run: `G/harness/hooks/session-start` given `{"source":"startup","session_id":"b17-ss"}`, run as a session run from `R`, exits 0; within 60 s `G/state/commission/p.bg.log` gains a row whose field 2 is `ran`; `B/claude.log` then has the low install line. (control: today's engine does this too)

**C034**

- **A44 (B19).** The status page with nothing granted, with commission current, and with commission stale (a comment line appended to the table after the grant) each contain `With nobody present, the run installs`, `at user scope`, `nothing marked high is installed` and `enables`, each whole on one line; none contains `What it does NOT do is install anything` or `which a person still runs`.
- **A45 (B19).** Exactly one file under `G/harness`, outside `tests/`, has a line containing `With nobody present, the run installs`.
- **A46 (B21).** A stamp of the one line P (with commission granted): the commission line is `[!] commission granted, but not over what this engine says the grant does`.
- **A47 (B21).** With that one-line stamp: the currency is `stale`; an unattended no-terminal run exits 1 with `no current commission grant` on stderr and calls no `claude`.
- **A48 (B21).** (control) After a no-terminal `--allow commission`, the currency is `current` and the commission line begins `[x] commission`.
- **A49 (B21).** That engine-written stamp with the first hex digit of line 2's field 2 changed: the commission line is `[!] commission granted, but not over what this engine says the grant does`.
- **A50 (B21).** (control) An engine-written stamp, then a comment line appended to the table: the commission line is `[!] commission granted, but not over this commissioning.tsv`.
- **A51 (B22).** Fixture B granted by a no-terminal run: its line 2 field 2 equals fixture A's.
- **A52 (B23).** `E2` = `B/e2`, a `_copy_content` copy of `$REAL_HARNESS`; in the one file outside `tests/` with a line containing `With nobody present, the run installs`, that line's `With nobody present` becomes `With nobody at all present`, written over the file with `cat` so its mode stays. A no-terminal run of `E2/felix autonomy` (FELIX_HOME=G, the stamp written by `G/harness`): the commission line is `[!] commission granted, but not over what this engine says the grant does`; an unattended no-terminal run of `E2/felix commission` exits 1 with `no current commission grant`.
- **A53 (B23).** (control) `E3` = `B/e3`, the same but editing instead the line containing `Tidy removes a file only when every one of these holds` (`Tidy removes` becomes `Tidy only removes`): the commission line begins `[x] commission`.
- **A54 (B24).** With a directory at the stamp's path: a no-terminal `--allow commission` returns within 20 s and exits non-zero; stderr contains `stamp` and `not written`; neither stream contains `stamped against`; the path is still an empty directory; the commission line does not begin `[x]`.
- **A55 (B24).** The same with a named pipe at the stamp's path (a 20 s watchdog, killing by pid); the path is still a named pipe.

**C048.** Tables are found at `$(cd "$REAL_HARNESS/../.." && pwd)/projects/*/commissioning.tsv`; one assertion per table, named by its project; where none is found, one skip says so.

- **A56 (B25).** `( . $REAL_HARNESS/lib/resolve.sh; . $REAL_HARNESS/lib/commission.sh; felix_commission_template_drift <project dir> $REAL_HARNESS/templates )` exits 0 and prints no line whose field 2 contains `check`.
- **A57 (B26).** L1 holds for `$REAL_HARNESS/templates/commissioning.tsv` and for each project table.
- **A58 (B26).** L2 holds for the template and each project table.
- **A59 (B26).** L3 holds for the template and each project table.
- **A60 (B26).** (control: the lints have teeth) A fixture table of two rows, `stack<TAB>-<TAB>-<TAB>-<TAB>-<TAB>[ "$(felix_stack_plan p | grep -c install)" -eq 0 ]<TAB>6` and `preflight<TAB>-<TAB>-<TAB>-<TAB>-<TAB>true<TAB>5`, fails L1 and L2 on its first row and L3 on both.

---

## 5. Parts

- `engine/harness/tests/parts/1950-a-grant-is-a-persons-word-blind.sh`: A1-A37 (C032, the deny rows, C033's refusals, owed paragraph, skill and `felix new`).
- `engine/harness/tests/parts/1960-commission-consent-says-what-runs-blind.sh`: A38-A60 (the unattended path, C034's text and binding, C048).

Each is written blind from this contract, under 500 lines, and runs alone: it builds its own fixtures under `$TMP/b17a` and `$TMP/b17b` and relies on nothing an earlier part left. `tests/run` sources both after the `1600-...` line and before the line that undoes the `.` alias (497 lines, then 499). Each part passes under BWK awk and gawk, bash 3.2 and 5, and is run with the batch's `alone.sh <worktree> bwk|gawk 1950 1960`. Red first: on the base engine every assertion not marked control fails, except A1, which fails there only when the suite is started from inside a session (CI never sets `CLAUDECODE`); A56-A59 fail on the project tables and pass on the template.

---

## 6. Out of scope

- **C085 dropped (medium).** One receipt per project checked against whichever checkout asks. Keying the receipt per checkout, or hashing surfaces from `origin/main` and matching dependency keys instead of substrings, is a design of its own that moves every receipt's caps hash and the ten-field receipt parts 0690 and 0700 pin. It fails closed and loudly, with a workaround (land one PR, merge main into the other), and it is not about the grant or its consent text.
- **C068 dropped (low).** A deadline on the background run could kill it mid-append to `stack.tsv` or `routes.tsv`, which is what its lock exists to prevent; no hang has ever been measured; a stale receipt is already reported by `felix merge`, the land tick, `felix gate` and session start; and the lock prints its pid. A lock-age line is a later piece.
- **Reading the grant from `origin/main`** (C032's sketch). It conflicts with direction step 16, which moves the founder's stamps out of the tracked tree, and direction wins; which gives is his call.
- **Engine-level default deny rows** for the seven projects with no `deny.tsv`, and Bash deny rows on autonomy files or on `felix autonomy --allow`. A default row set is a new mechanism in the founder's lane (step 18); a Bash row would refuse every PR body, doc edit and echo that quotes the command. The CLI refusal (B1, B12) covers every project.
- **A faked terminal, unset session variables, a shell redirect, an upper-case `autonomy.Commission` on a case-insensitive disk.** The floor; the authority escape uses the same lower-case pattern.
- **The actor in the receipt** (C033's sketch): the receipt's ten fields are pinned, and B12 keeps a session-written receipt from arising through the CLI.
- **Refusing a session's `--status`**, which writes nothing; **the drift report's wording** and a seen store keyed to the template's hash (C048's optional sketch).
- **docs/direction.md and the roadmap** are the founder's documents and are not edited; the PR body says step 18's grant rows are delivered for the felix project only.

### Not fixed: not a defect

- **C048 "a merge let through".** `held` never blocks (escape.sh:757-767; `receipt_valid` accepts it, commission.sh:700); an unread capability list makes the reach row `unknown` and the receipt `indeterminate`, which blocks (toolbox.sh:161); probes and obligations are blocked by the merge on their own (escape.sh:688-751). The drift changes a row's word, not the merge.
- **C068 "69 unread failures".** All 69 `declined-or-failed` rows sit in bursts of session starts seconds apart, each ending in a `ran` row within minutes: the designed quiet give-up on the lock (own.sh:247-250).
- **C032 "the grant is silent".** The two projects holding a grant track their autonomy files, and the land tick pauses on a tracked home change (green-tick.sh:238-240; #459 recorded it on 10-23). The other seven hold none.
- **C033 "a deny.tsv change makes session start tell a session to commission".** The topology hashes the capability union and `commissioning.tsv` only (commission-provider.sh:103-127).

---

## 7. Founder PR

The whole batch is his: one PR, draft, labelled `needs-founder`, merged only by him. Its founder-stop changes, exactly:

1. **`projects/felix/deny.tsv`** gains, after the `.felix` rows, a comment and two rows (tab-separated, four fields):
   ```
   # A grant is a person's word. felix autonomy writes these files, refuses a
   # session, and records who granted (audit b17). A grant written by hand records
   # nothing, so Write and Edit are refused on them. The floor: a shell redirect
   # is not matched, and a fixture outside this checkout is passed over.
   Write	(^|/)projects/[^/]+/autonomy(\.[a-z]+)?$	a grant is a person's word: felix autonomy writes this file from a terminal and records who gave it; a hand-written grant records nothing	checkout
   Edit	(^|/)projects/[^/]+/autonomy(\.[a-z]+)?$	a grant is a person's word: felix autonomy writes this file from a terminal and records who gave it; a hand-written grant records nothing	checkout
   ```
2. **The consent text and its binding** (B19-B23): the corrected paragraph, and a grant current only over the consent this engine prints.
3. **The nine `projects/*/commissioning.tsv`**: each `check` cell set to the template's cell for the same need, nothing else (the verifier escape fires on each, as a loosened row removes its old line).

What follows the merge and deploy, all his, from a terminal in the home's main checkout:

- Every project's policy version moves (item 3, and `deny.tsv` for felix), and felix's one-line stamp no longer covers the new consent (item 2). Until he acts, `felix merge` refuses every PR for a stale commission receipt and the land tick lands nothing, as direction row 26 says; nothing runs unattended.
- `felix autonomy` (read the new consent), then `felix autonomy --allow commission`, then `felix commission`, in a checkout bound to felix.
- Commit the re-stamped `projects/felix/autonomy.commission` through a PR he merges (the authority escape fires, as for #459), promptly, since the tick pauses on the uncommitted change.
- `felix commission` in each other project with a receipt (bazaar, behaviorchangebench, elenchus, sv2-apps, veldra, webapp) before its next merge. elenchus-capital-research and team1 have none.

---

## 8. Red

Run 2026-10-25 on the base engine (branch head `24e22632`, no engine file changed): `alone.sh <worktree> bwk 1950 1960` (macOS awk, bash 3.2, started from inside a Claude session, so `CLAUDECODE` was set). The run named 95 assertions in the two parts (A56-A59 are one line per table): **63 failed, 32 passed**. The 62 `ok` lines of the preamble parts (0001-0004) are not counted. No terminal case was skipped (`script` makes a terminal here).

**The 63 failures**: A1-A8, A11-A24, A26-A29, A31, A33-A35, A37, A40-A42, A44-A47, A49, A51, A52, A54, A55, all nine A56 lines, nine of the ten A57 lines (every project table; the template passes), and the `elenchus-capital-research` lines of A58 and A59. A1 fails here only because the run was started from inside a session (`CLAUDECODE` set); the contract expected that, and CI does not set it.

**The 32 passes, and why each is not a defect found:**

| Assertion | Why it passes on the base |
|---|---|
| A9, A10, A30, A32, A36, A38, A39, A43, A48, A50 | Controls, marked in §4: they pin what already works and must keep working. A39 is the one a reader might not expect: on the base nothing refuses a session, so an unattended session run passes too. |
| A25 | Control for the deny rows' scope, and vacuous on the base: the fixture `deny.tsv` holds no rows (A22 and A23 fail), so nothing is refused and every allowed case passes. A24 is the assertion with teeth. |
| A53 | Control, and already true: the base binds the grant to nothing in the consent text, so an edited tidy paragraph cannot unseat it. It stops an H that hashes the whole page. A52 is the assertion with teeth. |
| A57 (template), A58 (template and 8 projects), A59 (template and 8 projects) | Already true. Only the project tables' L1, and elenchus-capital-research's L2 and L3, are broken (§2 B26 says so); the template and the other tables pass L2 and L3 today. |
| A60 | Control: a planted two-row table that the lints must fail. It tests the lints, not the engine. |

Nothing passed that should have failed: no vacuous pass hides a defect. The two vacuous or already-true groups (A25, A53, A57-A59 on the template) each sit beside a failing assertion that has the teeth.
