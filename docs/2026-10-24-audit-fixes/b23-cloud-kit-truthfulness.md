# Audit fix b23: the cloud kit says what is true

*Written 2026-10-24 against felix-home `origin/main` `69b51a61` (engine 0.49.307), from the batch brief b23 (defects C108 and C111, each with one skeptic's note). Both skeptics lowered the severity to low, and this contract follows them. Line numbers cite the base commit.*

**This document is the whole contract for assertions.** An assertion author needs nothing else, apart from the suite's own helpers (`ok`, `bad`, `is`, `has`, `skip`, `_copy_content`, `_fx_cd`, `_fx_git`, `$TMP`, `$FROOT`, `$REAL_HARNESS`).

---

## 1. Defects

**C108 (low; the skeptic corrected it from medium).** When `bin/secret-scan` finds no base ref on a branch that has commits, it scans only the uncommitted changes and exits 0. The gate then prints `secret ok` over commits it never read.

*Scenario, as the skeptic corrected it.* A cloud session's clone has no `origin/main`, because provision's fetch of main failed. A single-branch clone has only `refs/heads/<branch>` and `refs/remotes/origin/<branch>`, and a bare `git fetch origin main` adds nothing.

`secret-scan` tries `origin/HEAD origin/main origin/master main master` (secret-scan:391-395), finds none, and writes `no base ref found; scanning uncommitted changes only` to stderr. It then scans the uncommitted changes and exits 0 (secret-scan:445-452, 456).

`projects/felix/gate.sh:367-369` treats exit 0 as a pass, prints `secret ok`, and drops the note. Nothing on the secret line says why the gate is red. `qualified` then FAILs, because the secret rows' committed mutations go unseen and come back HELD. That verdict is correct, and the misleading `secret ok` sits beside it.

The same exit 0 comes back when the caller names a base that does not resolve (`secret-scan no-such-ref`). It also comes back with an AWS key committed on the branch. That was reproduced on `69b51a61`: a repository whose only branch is `feat`, a key in a commit, no remote, and `secret-scan` exits 0.

The two other claims in the brief (that the repair is refused, and that the release is lost) are in §6 under "Not fixed: not a defect".

**C111 (low; the skeptic corrected it from medium and from "three pins").** `.claude/cloud/toolbox.json:6` says "So the cloud runs what a local session runs." It does not. One pin lags the local install, and nothing would notice.

*Scenario.* `superpowers` is pinned at `896224c4` (toolbox.json:15). The founder's `~/.claude/plugins/installed_plugins.json` has it at `bb92a777`, version 7.0.0, last updated 2026-10-16. Its `hooks/session-start` and most of its skill texts differ from the cached 6.3.0.

`test-coverage-intelligence` and `ci-optimizer` are pinned at `a7a800dd` and installed at `0b19c0dd`. Their files are identical at both commits (`diff -rq` with `.in_use` and `.orphaned_at` excluded finds no difference), so those two do not lag in any way that matters.

The pins come from one laptop's registry. CI has no registry, and the gate's cloud check compares only entry names (gate.sh:635-639). So a pin falls behind and the file goes on claiming the two match.

The same claim appears in `.claude/cloud/provision:8-9`, which says it fetches each pin "at the commit the founder's machine runs".

The harm is latent. On the one measured cloud run, every codeload fetch got HTTP 403 (cloud-verify.md:54, :70), so that cloud got no superpowers at any sha.

---

## 2. Required behaviour

### Terms used below and in §4

- **SS** is `$FROOT/harness/bin/secret-scan`, the suite's copy of the branch's scanner.
- **KEY** is put together at run time, as `$(printf '%s%s' AKIA Q7XK2M9PLR4TWN3B)`, so the part file never holds a credential's shape. The **key line** is `aws = "KEY"`.
- **git in a fixture.** Every git write uses `_fx_cd` or `_fx_git`, as parts 0430 and 1520 do. It also passes `-c user.name=t -c user.email=t@t`, and every `git init` names its branch with `-b`. The host's git configuration is not isolated by the suite, so nothing may depend on `init.defaultBranch` or `clone.defaultRemoteName`.
- **A scan.** Run `( _fx_cd DIR && perl -e 'alarm shift; exec @ARGV or exit 127' 60 SS [ARG] ) >OUT 2>ERR`, then record the exit status, stdout and stderr. A run the alarm ends counts as a failure, with the reason `did not finish`.
- **No base.** None of `origin/HEAD`, `origin/main`, `origin/master`, `main` or `master` passes `git rev-parse -q --verify` in the fixture. Every fixture marked *no base* checks this first. If one of them resolves, each assertion on that fixture is `bad`, and its detail names the ref. It never passes by accident.
- **Fixtures.** Each one lives in its own directory under `$TMP/b23/`:
  - **N-key** (*no base*): `git init -q -b feat`; commit `a.txt` (`a`); commit `k.txt` holding the key line. No remote.
  - **N-clean** (*no base*): the same, but the second commit is `b.txt` (`b`).
  - **C** (*no base*), a single-branch clone. A source repository `S` is made with `git init -q -b main` and a commit of `a.txt`. Then `git checkout -q -b feat`, a commit of `k.txt` holding the key line, and `git checkout -q main`. Then `git clone -q -o origin --single-branch --branch feat "file://S" C`. C holds only `refs/heads/feat` and `refs/remotes/origin/feat`.
  - **D** (*no base*), a detached HEAD on no branch. This is the shape actions/checkout leaves on a pull request at its default depth. `git init -q -b feat`; commit `a.txt`; commit `k.txt` with the key line; `git checkout -q --detach`; `git branch -q -D feat`.
  - **M-key**: `git init -q -b main`; commit `a.txt`; `git checkout -q -b feat`; commit `k.txt` with the key line.
  - **M-clean**: the same, but the `feat` commit is `b.txt`.
  - **M0**: `git init -q -b main` with one commit of `a.txt`. HEAD is the base itself.
  - **U-clean**: `git init -q -b feat`; write `a.txt` and `git add a.txt`; no commit (an unborn HEAD).
  - **U-key**: U-clean, plus an untracked `k.txt` holding the key line.
- **Gate fixture G** follows part 0430's construction. `$TMP/b23/g` holds:
  - `engine/harness`, made with `_copy_content "$REAL_HARNESS"`;
  - `engine/hooks`, made with `_copy_content "$REAL_HARNESS/../hooks"`;
  - `engine/.claude-plugin/plugin.json`, reading `{ "name": "felix", "version": "0.0.1" }`;
  - `gate.sh`, copied from `$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix/gate.sh`.

  `git init -q -b main`, add everything, and commit. A **gate run** is `( _fx_cd G && perl -e 'alarm shift; exec @ARGV or exit 127' 300 bash gate.sh --quick ) 2>&1`. Its **secret line** is the output line that begins with two spaces and then `secret`. If `projects/felix/gate.sh` is absent, every gate assertion is skipped, with that reason, as 0430 does.
- **The cloud files** are `ROOT/.claude/cloud/toolbox.json` and `ROOT/.claude/cloud/provision`, where ROOT is `$(cd "$REAL_HARNESS/../.." && pwd)`. The public snapshot does not ship `.claude/cloud/` (snapshot.sh:216-219). So where `ROOT/.claude/cloud` is absent, every assertion on these files is skipped, with that reason. Where the directory exists and one of the files is missing, each assertion on that file is `bad`.
- **JSON reader**: `jq` if it is on PATH, otherwise `python3 -I` if that is. An assertion that needs one is skipped where neither is present.

### C108: no base is not clean

- **B1.** *No base, a branch with commits, a key committed.* On N-key, `SS` with no argument exits **2**, not 0. Its stdout is empty. Its stderr contains each of these:
  - `no base ref found`
  - `origin/HEAD origin/main origin/master main master` (the refs it tried, in the order it tried them)
  - `what this branch committed was not scanned`
  - `nothing here can be called clean`
  - `git fetch origin main:main` (a repair that makes a local `main`, so the next scan has a base)

  It does not contain `refs/remotes/`: projects/felix/deny.tsv:133 refuses any fetch refspec that names one, so the hint must never suggest such a refspec.

  A suggested wording, which binds only through the phrases above:
  `secret-scan: no base ref found (tried origin/HEAD origin/main origin/master main master), so what this branch committed was not scanned; nothing here can be called clean`
  `secret-scan: name a base as the first argument, or make one of those refs exist, for example a local main with: git fetch origin main:main`
- **B2.** *No base, clean commits.* On N-clean, `SS` exits 2 and gives B1's stderr. A scan that could not read the commits is not clean, whatever they hold.
- **B3.** *The single-branch clone.* On C, `SS` exits 2 and its stderr contains `no base ref found`. Then run `git fetch -q origin main:main` in C, which is the repair B1 names. After it, `SS` exits 1, and its stderr contains `possible credential in added lines` and KEY. (The second half is a control: it holds today.)
- **B4.** *Detached on no branch.* On D, `SS` exits 2 and its stderr contains `what this branch committed was not scanned`.
- **B5.** *A named base that does not resolve.* On M-key, `SS no-such-ref` exits 2. It does not fall back to `main`, which does resolve there, because the caller asked a different question. Its stderr contains `no-such-ref`, `does not resolve`, `what this branch committed was not scanned` and `nothing here can be called clean`. On M-clean, `SS no-such-ref` also exits 2.
- **B6.** *A hit in what was read still counts.* These are controls, and they hold today.
  - N-clean plus an untracked `u.txt` holding the key line: `SS` exits 1, and its stderr contains `possible credential in added lines`, KEY and `no base ref found`.
  - M-clean plus the same untracked file: `SS no-such-ref` exits 1.

  The order of judgement is: a read that failed gives 2 (as today); then a hit gives 1; then a missing or unresolvable base on a branch with commits gives 2; and only then 0.
- **B7.** *An unborn HEAD has no commits to miss.* These are controls.
  - On U-clean, `SS` exits 0, and its stderr contains neither `nothing here can be called clean` nor `was not scanned`. The old note `no base ref found; scanning uncommitted changes only` may stay there.
  - On U-key, `SS` exits 1.

  This holds whether or not a base is named, because with no commit there is nothing for a base to compare.
- **B8.** *A base found is unchanged.* These are controls.
  - On M-clean, `SS` exits 0 with stderr empty, and `SS main` exits 0.
  - On M-key, `SS` exits 1, and its stderr names KEY.
  - On M0, `SS` exits 0: HEAD is its base, and an empty change is clean.
- **B9.** *The modes that read no base are unchanged.* These are controls.
  - On N-key, `SS --tree` exits 1. On N-clean, `SS --tree` exits 0.
  - `printf '+%s\n' 'note = 1' | SS -` exits 0. The key line fed the same way (`printf '+%s\n' "aws = \"KEY\""`) exits 1.
- **B10.** *The gate's secret line.* Three gate runs on G, in this order. Each must finish within 300 s.
  - (a) `git checkout -q -b side`, then commit `b.txt` (`b`). The secret line contains `ok`. (control)
  - (b) Then commit `leak.txt` holding the key line. The secret line contains `FAIL`, and the output contains `possible credential in added lines`. (control)
  - (c) Then `git branch -q -D main`, after which G is *no base*. The secret line contains `FAIL` and does not contain `ok`. The output also contains `    secret-scan: no base ref found`, indented four spaces as gate.sh:371 prints its detail, and `what this branch committed was not scanned`.

  gate.sh does not change in this batch. This item shows that the unchanged gate, given the new scanner, says why the check failed.

### C111: the toolbox says how its pins relate to the local install

- **B11.** No text of `toolbox.json`, read without regard to case, contains `the cloud runs what a local session runs`.
- **B12.** `toolbox.json` contains `moved by hand`, `may lag`, `nothing compares` and `installed_plugins.json`, and all four are in one string of its `about` array. A suggested replacement for the string at toolbox.json:6, which binds only through the four phrases:

  > The shas were copied from the founder's machine (~/.claude/plugins/installed_plugins.json): 2026-09-25 for the official ones, 2026-10-12 for the five from the plugin directory, each at the commit the directory reviewed. They are moved by hand and may lag the local install, which updates itself; nothing compares a pin with the local install, and CI has no registry to compare it with, so a cloud session can run an older plugin than a local one. To check a pin, compare its sha with that plugin's gitCommitSha in installed_plugins.json. On 2026-10-24 superpowers lagged (pinned 896224c4, installed bb92a777, 7.0.0 since 2026-10-16); test-coverage-intelligence and ci-optimizer were pinned at an older commit of their repository (a7a800dd against 0b19c0dd) whose files for those two plugins are the same.
- **B13.** *Its shape is kept.* These are controls.
  - It parses as JSON. `.about` is an array of strings. `.tools` is an array whose length equals the number of lines in the file that contain `"name":`.
  - That line count equals the number of names `sed -n 's/^      "name": "\([^"]*\)",$/\1/p'` prints (the reader at gate.sh:635), and is at least 1.
  - Every `plugin` or `skill` row of `ROOT/projects/felix/stack.tsv` (comment and blank lines skipped, `@…` removed from the second field, as gate.sh:636-637 does) names one of those names.
- **B14.** No line of `provision` contains `founder's machine runs`. Its header at lines 8-9 says instead that it fetches each plugin at the commit toolbox.json pins.

**Required and not asserted:**
- secret-scan's header (lines 7-9) says that exit 2 also covers a branch with commits whose base was not found or does not resolve. The comment above the no-base block (lines 446-448) says why that exit is 2 and not 0.
- secret-scan stays under 500 lines (459 today).
- Its new text must hold no credential shape, because the gate's own secret check scans the branch's added lines, including `bin/secret-scan` itself. For example, no `token: <twelve characters>`.
- B12's dated note on the superpowers lag.
- No `tools` entry changes in this batch: not a name, carry, source, sha, subdir or note.

---

## 3. What must not change

- **The scanner's verdicts wherever a base is found**, and every pattern and exclusion. These are pinned by:
  - 0120-scheduled-maintenance.sh (stdin samples and exclusions);
  - 0994-bash-s-own-collation-and-the-bsd-text-tools.sh and 0998-continued.sh (bytes and locales);
  - 1500-git-colour-never-reaches-what-the-engine-parses.sh (colour settings, and `felix receipt`'s secret-scan child);
  - 1510-no-caller-environment-changes-a-tool-s-output.sh;
  - 1530-patch-reads-the-repository-not-a-diff-setting.sh and 1540-patch-reads-the-review-s-cases-and-findings.sh (diff settings, paths, the fixture exclusion, binary files, and a key staged on an unborn HEAD, exit 1).
- **Exit 2 for a read that did not finish**, with git's reason. This is pinned by 1520-git-readers-fail-closed.sh (X1 to X4), including X2: no base anywhere and a tracked pipe still exits 2 from the read failure. It is also pinned by 1530 (U1, U2). The unread check stays ahead of the no-base check.
- **`--tree` and `-`.** They read no base. `projects/felix/snapshot.sh:383` and :456 depend on `--tree` finding the suite's planted fixtures.
- **The callers.**
  - lib/escape.sh:356-364 reads 0 as clean, 1 as `disclose` and anything else as `unknown`. It always passes a base that `felix_changed_paths` has already read, so no merge it allows today is blocked by this change.
  - projects/felix/gate.sh and projects/elenchus/gate.sh do not change. Both run the scanner with no base: in felix-home and in Elenchus locally, `origin/main` exists.
  - felix-home's CI checks out with `fetch-depth: 0` (.github/workflows/gate.yml:68-77), so `origin/main` is there.
  - `felix qualify`'s secret rows (projects/felix/qualification.tsv:39-75) run in a `git worktree` of the root, which shares the root's refs, so they read as they do today wherever the root has a base.
- **gate.sh as it stands.** Its secret block, and its `pass secret` and `fail secret` lines behind the verifier confine (0090-what-a-revert-cannot-undo.sh). Its executable check, which names `bin/secret-scan` when the bit is lost (0430-hooks-events-reads-keys-not-strings.sh). Its cloud check, which reads toolbox names by the six-space `"name":` layout (gate.sh:635-639).
- **bin/secret-scan's opening block.** The caller-environment block (1510) and the git colour pin (1500:461) stay as its first lines.
- **toolbox.json's readers.** provision reads `.tools[]` with jq (provision:43-47) and never reads `about`. The gate reads the `name` lines. The `tools` array, its layout and its 17 entries are untouched.
- **The deny floor.** projects/felix/deny.tsv does not change, row 133 included.
- **Coding rules for the scanner and the part:**
  - bash 3.2 and bash 5;
  - no `case` inside `$( )`;
  - digit brackets spelled out (`[0123456789]`);
  - `LC_ALL=C` on every grep, sort or comparison of fixture output;
  - no gawk-only awk builtins;
  - no `printf … | grep -q` (the pipefail lint, #376); use `case` or a here-string;
  - every git write in a fixture through `_fx_cd` or `_fx_git` (the lint in 0003-the-lint-the-origin-record-and-the-exit-trap.sh).

---

## 4. Assertions

Part 2070 builds every fixture. A control holds both before and after the fix. Every other assertion is red on `69b51a61`, where each *no base* scan exits 0.

**Scanner**
- A1 (B1): N-key, `SS`: exit 2.
- A2 (B1, control): N-key: stdout is empty.
- A3 (B1, control): N-key: stderr contains `no base ref found`.
- A4 (B1): N-key: stderr contains `origin/HEAD origin/main origin/master main master`.
- A5 (B1): N-key: stderr contains `what this branch committed was not scanned`.
- A6 (B1): N-key: stderr contains `nothing here can be called clean`.
- A7 (B1): N-key: stderr contains `git fetch origin main:main`.
- A8 (B1, control): N-key: stderr does not contain `refs/remotes/`.
- A9 (B2): N-clean, `SS`: exit 2, and stderr contains `what this branch committed was not scanned`.
- A10 (B3): C, `SS`: exit 2, and stderr contains `no base ref found`.
- A11 (B3, control): C after `git fetch -q origin main:main`: exit 1, and stderr contains `possible credential in added lines` and KEY.
- A12 (B4): D, `SS`: exit 2, and stderr contains `what this branch committed was not scanned`.
- A13 (B5): M-key, `SS no-such-ref`: exit 2.
- A14 (B5): its stderr contains `no-such-ref`, `does not resolve`, `what this branch committed was not scanned` and `nothing here can be called clean`.
- A15 (B5): M-clean, `SS no-such-ref`: exit 2.
- A16 (B6, control): N-clean with the untracked key file, `SS`: exit 1, and stderr contains `possible credential in added lines`, KEY and `no base ref found`. The file is removed afterwards.
- A17 (B6, control): M-clean with the untracked key file, `SS no-such-ref`: exit 1. The file is removed afterwards.
- A18 (B7, control): U-clean, `SS`: exit 0, and stderr contains neither `nothing here can be called clean` nor `was not scanned`.
- A19 (B7, control): U-key, `SS`: exit 1.
- A20 (B8, control): M-clean, `SS`: exit 0 with stderr empty.
- A21 (B8, control): M-clean, `SS main`: exit 0.
- A22 (B8, control): M-key, `SS`: exit 1, and stderr contains KEY.
- A23 (B8, control): M0, `SS`: exit 0.
- A24 (B9, control): N-key `SS --tree` exits 1, and N-clean `SS --tree` exits 0.
- A25 (B9, control): stdin `+note = 1` exits 0, and the stdin key line exits 1.

**Gate**
- A26 (B10a, control): the secret line contains `ok`.
- A27 (B10b, control): the secret line contains `FAIL`, and the output contains `possible credential in added lines`.
- A28 (B10c): after `main` is deleted, with G checked to be *no base*: the secret line contains `FAIL`.
- A29 (B10c): that output contains `    secret-scan: no base ref found` and `what this branch committed was not scanned`.

**Cloud files**
- A30 (B11): `toolbox.json` does not contain `the cloud runs what a local session runs` (`LC_ALL=C grep -qiF`).
- A31 (B12): it contains `moved by hand`.
- A32 (B12): it contains `may lag`.
- A33 (B12): it contains `nothing compares`.
- A34 (B12, control): it contains `installed_plugins.json`.
- A35 (B12): exactly one string of `.about` contains all four of `moved by hand`, `may lag`, `nothing compares` and `installed_plugins.json` (JSON reader).
- A36 (B13, control): it parses, `.about` is an array of strings, and `.tools` has as many entries as the file has lines containing `"name":` (JSON reader).
- A37 (B13, control): the count of `"name":` lines equals the count of names the gate's sed prints, and is at least 1.
- A38 (B13, control): every plugin and skill name in `ROOT/projects/felix/stack.tsv` is among those names. One assertion for the whole set. Its detail names any that are missing.
- A39 (B14): no line of `provision` contains `founder's machine runs`.

---

## 5. Parts

- `engine/harness/tests/parts/2070-cloud-kit-truthfulness-blind.sh`: A1 to A39.

It is one part, so the driver gains one line. `tests/run` is at 497 lines, and other batches add lines too. The line goes in numeric order with any other new part: after `1600-felix-refuses-a-pattern-kill-blind.sh`, and before the `! alias .` line that precedes `9990-the-run-stayed-inside-its-temporary-directory.sh`.

The part builds its fixtures under `$TMP/b23` and keeps its helpers inside itself, with no new `tests/lib` file. It stays under 500 lines, and it passes both `alone.sh … bwk` and `alone.sh … gawk`. Its three gate runs cost about 6 s each on the founder's machine.

---

## 6. Out of scope, with why

- **C108: report the no-base scan as a skip** (the fix sketch's first option: a `skipped` secret line and an entry in the receipt's skips). Not chosen, for four reasons.
  - The scanner's own contract already gives that case a meaning. Exit 2 is "could not read what it was asked to scan" (secret-scan:8-9), and the default mode is asked what the branch adds on top of a base.
  - A skip lets a gate pass while its only credential check has read none of the commits.
  - projects/felix/gate.sh is 652 lines, over the 500-line limit, and `felix gate` runs the home's copy, so a branch's change to it is not exercised by its own gate.
  - Both project gates would each need the mapping.

  With exit 2, the unchanged gate prints `secret FAIL` and puts the reason directly under it (gate.sh:371).
- **C108: exit non-zero only when `CLAUDE_CODE_REMOTE=true`** (the second option). Rejected. A tool's verdict must not depend on its caller's environment (secret-scan:22-29), and the defect is not confined to the cloud: any single-branch clone has it, and so does a detached checkout like an Elenchus pull-request run (§7).
- **C108: provision's failure line naming `bash .claude/cloud/provision` as the retry** (the third option). provision's report on what did not arrive, a missing `origin/main` included, is batch b07's (C107, its B26). The engine scanner must not name a felix-home path either: its hint is generic (`git fetch origin main:main`).
- **C108: a HEAD that equals its base** (M0) reads zero lines and exits 0 (secret-scan:349-350). That is the empty change, and it is clean for the question the default mode asks. `--tree` answers the other question.
- **C108: docs/handoff/0dh.md:104-106** records the behaviour as "Found, not fixed here". It is left alone: this workflow does not edit `docs/handoff/`.
- **C111: a local comparison of pins against the registry** (in felix status, the pulse or session-start). Not built here, for three reasons. The registry exists only on the founder's machine, and CI has none. The engine never reads toolbox.json, by design (toolbox.json:8; b07 §6). And a gate check that read `~/.claude` would give one tree two verdicts, red on the laptop and green in CI. B12 makes the file say that nothing compares the two, and how to check by hand.
- **C111: moving the superpowers pin to `bb92a777`.** That changes what a cloud session runs, since 7.0.0 brings a new session-start hook and new skill texts. It cannot be verified while codeload answers 403, which is the only cloud run ever measured. It belongs with the first cloud run that can fetch. The two `petrovicistefan` pins need no move, because their files are identical.

**Not fixed: not a defect**
- **C108: "the session's obvious repair is refused by a deny row".** deny.tsv:133 refuses only a fetch or push whose refspec names `refs/remotes/`. That is deliberate: the exception table is read from `refs/remotes/origin/main` (deny.tsv:100-127). Other repairs pass every Bash row in deny.tsv, as the skeptic checked by matching each pattern with bash `[[ =~ ]]` under `LC_ALL=C`:
  - `git fetch origin main:main`;
  - `git fetch origin main` followed by `git branch main FETCH_HEAD`;
  - `git remote set-branches --add origin main` followed by a plain fetch;
  - `bash .claude/cloud/provision`, which runs fetch_main again (provision:169).

  Reproduced here with git 2.54 on `69b51a61`. In a single-branch clone of a branch that commits a key, `git fetch origin main` leaves `origin/main` unresolved, and the scan exits 0. After `git fetch origin main:main`, the scan exits 1 and names the key. B1 now names that repair.
- **C108: "the session ends red and the release is lost".** The red verdict is correct. `qualified` holds on the unseen secret controls (engine/harness/felix:870-942), and nothing passes that should fail. What was wrong was the `secret ok` line beside it, which B10 fixes.
- **C111: "three pins lag".** Two of them do not: for `test-coverage-intelligence` and `ci-optimizer`, the cached builds at `a7a800dd` and `0b19c0dd` have identical files.

---

## 7. Founder PR

**None for this batch to land.** It changes no `.github/workflows` file, no deny or escape row, no land row and not the commission grant, and it publishes nothing. `.claude/cloud/` is classed red by projects/felix/risk.tsv:36, but that row has no channel, so it stops nothing.

**Owed later, in another repository, and the founder's.** Elenchus's CI runs Felix pinned at felix-home `cb3a72ce` (Elenchus `origin/main`, `.github/workflows/gate.yml:113`). Its own checkout of Elenchus uses actions/checkout's defaults (gate.yml:42-45).

On a pull request, that default fetches only the merge ref, at depth 1. That leaves no `origin/main`, so its `secret ok` today has read none of the pull request's commits. This was read from the workflow and the action's documented defaults, not measured on a run.

Once Elenchus moves its Felix pin past this change, every pull-request run would print `secret FAIL` with the no-base line. So the pull request that moves the pin, or one before it, needs this change in Elenchus `.github/workflows/gate.yml`, step "Check out Elenchus":

```yaml
      - name: Check out Elenchus
        uses: actions/checkout@v5
        with:
          path: repo
          fetch-depth: 0
```

---

## 8. Red

*Run 2026-10-24 on `d7e56ee1` (the part and the driver line added, no code changed), with `alone.sh … bwk 2070-cloud-kit-truthfulness-blind.sh`: macOS awk under bash 3.2, about 100 s, driver exit 0.*

**Part 2070 holds 39 assertions (A1 to A39). 19 failed and 20 passed.** The driver's own summary line reads `ok=82 fail=19`, because it also counts the 62 fixture-floor lines that print before the part's own.

**The 19 that failed**, all of them the non-control assertions of §4, as the contract said they would be:
- A1, A4, A5, A6, A7, A9, A10, A12: every *no base* scan (N-key, N-clean, C, D) exits 0 and says only `no base ref found; scanning uncommitted changes only`.
- A13, A14, A15: `SS no-such-ref` exits 0 on M-key and M-clean, and prints the same note (it does not name `no-such-ref`).
- A28, A29: with `main` deleted the gate's secret line reads `ok`, and no reason is printed under it.
- A30, A31, A32, A33, A35: toolbox.json still says the cloud runs what a local session runs, and none of `moved by hand`, `may lag` or `nothing compares` is in it.
- A39: provision's header still says `founder's machine runs`.

**The 20 that passed, and why.** Every one is a control the contract marked as holding before the fix. Each ran its fixture and its *no base* check; the one that is vacuous today is named below (A8).
- *Already true.* A2 (stdout is empty: the note goes to stderr only), A3 (stderr already says `no base ref found`), A34 (toolbox.json already names `installed_plugins.json`).
- *Guards a future hint.* A8 (stderr has no `refs/remotes/`). It passes today only because the note has no hint at all, so it is vacuous now, and it bites only once the hint exists.
- *A control on the repair or on a hit in what was read.* A11 (after `git fetch -q origin main:main` the scan has a base, exits 1 and names the key), A16 and A17 (a key in an untracked file is a hit, exit 1).
- *Unchanged behaviour wherever there is no gap.* A18, A19 (an unborn HEAD), A20, A21, A22, A23 (a base is found), A24 (`--tree`), A25 (stdin).
- *The gate, before the no-base case.* A26 (secret `ok` over a clean side branch) and A27 (secret `FAIL` over a committed key).
- *The toolbox's shape.* A36, A37, A38 (it parses, the gate's reader finds every name line, every stack row has an entry).
