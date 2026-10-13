# Contract A: pay once per tree (gate friction, step 1)

Design: docs/2026-10-12-gate-friction-design.md in felix-home, section 3.
Branch: LeavesJ/queue-based-build-7a2cda. Version placeholder 0.49.281.
Tier: adversarial (the suite driver, tests/red and the gate decide what counts
as verified). Weaken no check. Everything here is bash 3.2 and git, as on a Mac.

Paths below are relative to the repository root. `HERE` is
`engine/harness/tests`, the directory of the suite driver `tests/run`.

## Files

- `engine/harness/tests/run`: the driver. C2, C3, C4, C6.
- `engine/harness/tests/red`: C1.
- `engine/harness/tests/receipt.sh`: NEW. Sourced by the driver. C4 and C5
  helpers. Sourceable on its own (it needs only bash, git and
  `engine/harness/lib/verify.sh`, which it loads inside a subshell so the
  suite's shell gains no `felix_verify_*` names).
- `engine/harness/lib/verify.sh`: C8, one additive change to `felix_tree_id`.
- `projects/felix/gate.sh`: C7, the `tests` check only.
- `engine/harness/tests/parts/1010-the-record-this-branch-carries.sh`: one
  assertion restated (C3), marked "restated, not blind" in place.
- `engine/.claude-plugin/plugin.json`: 0.49.281.
- New part(s) for the blind block, sourced from the driver after the last part.

## C1. tests/red --after MARK PID

`tests/red [--after <mark> <pid>] [base]`. Without `--after`, nothing changes.

With `--after`:
1. The retraction is written first, as today.
2. `--after` with a missing mark argument, a missing pid, or a pid that is not
   a positive decimal integer: stdout `red: not run: --after needs a mark file
   and a process id`, exit 2, red.tsv holding the two retraction rows.
3. The manifest is NOT read before the suite. Base resolution, the base
   checkout, placing this tree's run and parts into it, and the suite run are
   as today.
4. The suite's completion check comes first: a suite that did not finish is
   refused with today's message and today's exit 2, without waiting.
5. Then red waits until the file `<mark>` exists, or process `<pid>` no longer
   exists (`kill -0` fails), checking at most once a second. The mark is
   checked first on each pass, so a mark written just before the process
   ended counts.
   - Process gone and no mark: `red: not run: the record run ended before it
     wrote the manifest`, exit 2, retraction rows.
   - Mark whose first line is not exactly `written`: `red: not run: the record
     run did not write a manifest (<first line, or "empty">)`, exit 2,
     retraction rows.
   - Mark reading `written`: the manifest is read and validated exactly as the
     pre-suite read does today (same refusals, same messages, same exit 2),
     and then the comparison and the write, as today.
6. The stray-kill and cleanup rules are unchanged.

## C2. Record and red at once

In `tests/run --record-assertions`:
1. Right after the suite's temporary directory exists, before any part runs:
   if `$HERE/red` is executable, start `"$HERE/red" --after <mark> <pid>` in
   the background, where `<mark>` is a path under the suite's temporary
   directory and `<pid>` is the driver's own process id (`$$`). Its stdout and
   stderr go to a file under the suite's temporary directory.
2. At the end, where it writes the manifest today: write the manifest. If that
   write fails, write `failed` to the mark; otherwise write `written`. Each
   mark write is a sibling file then one `mv`, so red never reads half a mark.
3. Print the `  recorded N assertions to <path>` line as today.
4. Wait for red's process. Print its output with every line prefixed by two
   spaces, as today's `| sed 's/^/  /'` does.
5. If `$HERE/red` is not executable, print today's line
   `  no tests/red beside this suite: red.tsv not written` and start nothing.
6. A record run ended by a signal: its EXIT trap removes the temporary
   directory, mark included, and red's wait sees the process gone (C1.5).

## C3. The record run judges what it wrote

In record mode only, after C2.4:
1. If the function `_rt_judge` is defined: print an empty line, then
   `the record this run wrote`, then call `_rt_judge "$REAL_HARNESS/../.."`
   with `FELIX_TEST_RECORD` not equal to 1 for that call, so the four record
   names (`_rtn1` to `_rtn4`) are reported as a normal run reports them. They
   count in PASS, FAIL, SKIP and the ran file like any assertion.
2. If `_rt_judge` is not defined: print
   `  no record judge in this suite: the record is not re-judged`, and C4
   writes no receipt for this run.
3. Then the manifest comparison runs, the same code a normal run uses, against
   the manifest just written. The comparison loop stays exactly one line in the
   driver (part 0770 asserts that line). The re-judged names are reached twice
   by then. Over-reached names are not a failure, as today.
4. The summary line and the exit status come after that, and the exit status
   counts every FAIL, the re-judge's included: a record run whose own record
   fails the judge exits 1. (Before this, record mode exited on the suite's
   FAIL only and never compared.)
5. Part 1010's assertion "the suite judges its own checkout's record with one
   bare call at the top level, and nowhere else" is restated: one exact,
   unindented call in the parts, and one more call in the driver, inside the
   record-mode branch. Marked "restated, not blind" in place.

## C4. A run leaves a receipt, or removes one

Helpers in `tests/receipt.sh`:
- `_sr_path <root>`: the absolute path `git -C <root> rev-parse --git-path
  felix-suite-receipt` names, made absolute against `<root>` if git prints it
  relative. Status 1 and no output when `<root>` is not a git checkout.
- `_sr_tree <root> [stable]`: `felix_tree_id <root> ""` (home empty, so it
  excludes nothing). With `stable`, also excluding
  `engine/harness/tests/assertions.tsv` and `engine/harness/tests/red.tsv`
  (C8). Status 1 and no output when it cannot be computed. A coarse id (one
  that begins `coarse:`) counts as cannot be computed.
- `_sr_env`: one line, `host=<uname -n>;bash=<$BASH_VERSION>;locale=<value of
  LC_ALL, else LC_CTYPE, else LANG, else empty>;path=<git hash-object of
  $PATH>;claude=<yes|no>`, where claude is whether `command -v claude`
  succeeds.

The receipt is one line, tab-separated, ending in a newline:

```
v1  <tree id>  <mode>  <passed>  <failed>  <skipped>  <env>  <start>  <end>
```

`<mode>` is `normal` or `record`; `<start>` and `<end>` are Unix seconds;
counts are the driver's PASS, FAIL and SKIP at the end, re-judge included.
It is written as a sibling temporary file in the same directory, then one
`mv`.

The driver, in a run that is not a red run (`FELIX_TEST_NO_MANIFEST` is not
exactly 1) and is not `--reuse` answered from a receipt:
1. At its start, before any part: takes `_sr_tree root`, `_sr_tree root
   stable`, `_sr_env` and the time, where root is `$REAL_HARNESS/../..`.
2. At its end, after the summary line is printed, writes the receipt only when
   all of these hold:
   - the run reached its end (every part sourced, `reached` printed);
   - FAIL is 0;
   - in normal mode a manifest was there and compared (no "no manifest yet");
   - in record mode C3.1 ran (the judge was there);
   - normal mode: the full tree id now equals the one taken at the start;
     record mode: the stable id now equals the stable one at the start;
   - `_sr_env` now equals the one at the start;
   - both ids could be computed.
   The tree id written is the full id taken at the end.
3. Otherwise, if the run reached its end, it removes the checkout's receipt
   when one is there, so a failing or moved run never leaves an earlier pass
   standing. A receipt path that is a symbolic link or not a regular file is
   neither written through nor removed; the run says
   `  receipt not written: <path> is not a regular file`.
4. In a red run, no receipt is read, written or removed.
5. Nothing about the receipt changes the run's exit status or its summary line.

## C5. Whether a receipt can be reused

`_sr_check <root>` prints exactly one line and returns 0:
- `reuse <passed> <failed> <skipped> <end> <mode>` when the receipt can be
  reused;
- otherwise `run <reason>`, the first that applies, in this order:
  - `no checkout`: `_sr_path` fails;
  - `no receipt`: nothing at the path;
  - `not a regular file`: a symbolic link, a directory, a FIFO, anything else;
  - `unreadable receipt`: it cannot be read;
  - `malformed receipt`: not exactly one line of nine tab-separated fields
    beginning `v1`, a mode that is neither `normal` nor `record`, a count or
    time that is not decimal digits, a start after its end, or an end more than
    60 seconds in the future;
  - `failures recorded`: failed is not 0;
  - `another tree`: its tree id differs from `_sr_tree root` now, or that
    cannot be computed;
  - `another environment`: its env differs from `_sr_env` now;
  - `older than 12 hours`: now minus end is more than 43200.

## C6. tests/run --reuse

1. `--reuse` and `--record-assertions` together: stderr `tests/run: --reuse
   and --record-assertions do not go together`, exit 2, nothing run.
2. With `--reuse`, before the fixture is built: `_sr_check
   "$REAL_HARNESS/../.."`.
   - `reuse ...`: print, and exit 0 without running any part:
     ```
     reused the suite run that ended <HH:MM, local time> on this tree (<mode>), not run again

     <passed> passed, 0 failed, <skipped> skipped (reused)
     ```
     with `, <skipped> skipped` left out when skipped is 0, exactly as the
     normal summary leaves it out.
   - `run <reason>`: print `not reused: <reason>` as the first line, then run
     as a normal run, receipt rules and all.
3. Without `--reuse`, no receipt is read: every plain run runs.

## C7. The gate's tests check

In `projects/felix/gate.sh`, the `tests` check runs
`./engine/harness/tests/run --reuse` where it runs `./engine/harness/tests/run`
today, into the same log. Then:
- exit 0 and the log's first line begins `reused `: print
  `printf '  %-18s reused\n' tests`, then the log's first line and its last
  line, each indented to column 21 as the `ok` detail line is today. The gate's
  verdict is a pass. The receipt `felix gate` writes then reports
  `tests:reused`.
- exit 0 otherwise: `pass tests` and the last line, as today.
- non-zero: as today.
`--quick` and the skip after an `installed` failure are unchanged. The lines
`pass tests` and `fail tests` stay where the `verifier` confine counts them.

## C8. felix_tree_id takes extra exclusions

`felix_tree_id <root> [home] [pathspec...]`: arguments after the second are
pathspecs appended to the exclusions for both the diff and the untracked list,
exactly as given. With two arguments or fewer it is byte-for-byte today's
function. No existing caller changes.

## What the build must show

- The blind block red on the commit before the implementation, then green.
- Every existing assertion green, with the one 1010 restatement and any other
  restatement marked in place.
- **The differential for C3/C4's soundness claim.** The suite run twice on one
  tree, with two different valid record files (a red.tsv retraction and a real
  one; two manifests), gives the same verdict on every name outside `_rtn1` to
  `_rtn4`.
- **Measured.** One record run on a quiet machine, wall and CPU, against the
  serial record plus red before; and one gate on the tree a record run left,
  showing `tests reused`.

## Not in this contract

Steps 2 and 3 of the design. Making the suite count FAIL lines printed inside
subshells (today the exit status counts the main shell's only; reuse is exactly
as strict as the run it reuses, no more). CI is unchanged.

## Addendum (second review, 2026-10-12)

The second review added the items below. Each amends the clause it names and
does not change the others. The blind block for them is part 1230
(`1230-gate-friction-a-addendum-blind.sh`).

- **C4/C5, origin/main.** The receipt records the commit `refs/remotes/origin/main`
  named when the run started, or `-` when there was none, and it is written only
  when that ref is the same at the run's end. `_sr_check` refuses with `run
  origin/main moved` when the ref now differs from the one recorded, or cannot
  be read while one was recorded. That check comes before the 12-hour check.
  *Where it rides.* The receipt stays nine fields. The commit is the tail of the
  env field, `<_sr_env>;origin=<commit>`. A run that began with no
  `refs/remotes/origin/main` writes the env field as `_sr_env` alone, and a
  receipt whose env field has no `;origin=` tail reads as having recorded `-`.
  A tail that is not 40 or 64 hex digits makes the receipt malformed.
- **C4, the earlier receipt goes first.** A run that may leave a receipt (not a
  red run, and not a `--reuse` run answered from a receipt) removes the
  checkout's existing receipt before its first part, under the same rules for a
  path that is not a regular file. The only receipt that can exist after such a
  run is one the run itself wrote at its end, so a run that fails, is
  interrupted, or dies before its end never leaves an earlier pass standing.
- **C6/C7, what says a run was reused.** Whether the tests check reused a run is
  decided by a signal that only the reuse path produces and that stderr cannot
  displace. The gate looks for the reuse line (`reused the suite run that ended
  `) anywhere in the log, not at its first line. A log that holds the reuse line
  anywhere is never reported as `ok` or recorded as `tests:ok`.
- **C4/C5, no checkout.** `_sr_path` and `_sr_tree` treat a root that is not
  `git rev-parse --show-toplevel` of itself as no checkout. `_sr_check` then
  answers `run no checkout`, and no run writes or removes a receipt for such a
  root.
- **C2.1, red is not a job of the suite's shell.** The red that a record run
  starts must not be a child job that any `wait` with no arguments in the
  suite's shell waits for. A part that waits for its own background jobs
  returns exactly as it does in a plain run. The record run learns that red has
  finished from something other than the suite shell's job table (red's process
  id and start time, from `ps`). The build shows this with a record run of the
  whole suite, parts 0150 and 0330 included, ending on its own.
- **C2.2, no mark.** If neither `written` nor `failed` can be put in place as the
  mark, the record run ends red and red's suite and does not wait for them. It
  prints `  red not run: the record run could not write its mark (<path>)`,
  red.tsv keeps the retraction, and the record run's exit status and the C3
  re-judge are as for any other run red refused.
- **C2.6 and C1.4, a signal.** A record run ended by SIGINT, SIGTERM or SIGHUP
  ends red and red's suite within a few seconds. Red also checks for the record
  run while its own suite runs, not only after it. If the record run is gone and
  no mark is there, red stops its suite, removes its base checkout and refuses
  with `the record run ended before it wrote the manifest`, leaving the
  retraction in red.tsv.
- **C1.5, what gone means.** `The record run is gone` means that process
  `<pid>` no longer exists or is no longer the process that started red. Red,
  which the record run starts as its own child, takes its parent having changed
  as the record run being gone. A process that merely holds the same id never
  extends the wait: a pid that is not one of red's ancestors, or whose start
  time is not the one it had when red began, is gone.
- **C1.5, a mark that is not a file.** A mark that is not a regular file
  (directory, FIFO, socket, device, or a symbolic link to any of these) is
  refused at once, without opening it for reading: `red: not run: the record run
  did not write a manifest (<path> is not a regular file)`, exit 2, retraction
  rows.
- **C4.5, the summary stays last.** The summary line `N passed, N failed[, N
  skipped]` stays the last line the suite prints, whatever the receipt does.
  Anything the receipt has to say is printed before the summary.

### Inputs from outside the tree

The tree id covers every tracked and untracked file under the root and the
commit HEAD names. The assertions also read things the tree does not hold. For
each one, whether the receipt names it or whether only the 12-hour bound covers
it:

| Input | Read by | The receipt |
| --- | --- | --- |
| the host name, the bash version, the locale (`LC_ALL`, else `LC_CTYPE`, else `LANG`), the `PATH` (by hash) | the whole suite | names them (`_sr_env`) |
| whether a `claude` CLI is on `PATH` (some assertions become skips) | `has_claude` | names it (`claude=yes` or `no`) |
| the commit `refs/remotes/origin/main` names | part 1010's judge (`_rtn3`, `_rtn4`) | names it (`;origin=`), and refuses when it moved |
| the memory lessons.md at `~/.felix/memory/felix/lessons.md` | part 0590, which copies it when it is there | not named; the 12-hour bound alone |
| the deployed plugin cache and install state: `claude plugin list --json` (`felix_deployed_engine`) and the cache under `~/.claude/plugins` it names | part 0440, through the `engine_deployed` row of `obligations-check projects/felix`; the gate's `installed` check | not named (only whether `claude` is on `PATH`); the 12-hour bound alone |
| the user's real `HOME`: `~/.felix-home`, the Claude settings directory, the global git configuration and its global excludes file, wherever the suite does not set one | any part that is not given a home of its own | not named; the 12-hour bound alone |
| the versions of git and of the other tools on `PATH` | every part that runs one | the path hash names a path, not a version; the 12-hour bound alone |
| the machine: load, clock, process cap, free disk, network | the assertions that time or fork heavily; `gh` and the network where an assertion is not given a stub | not named; the 12-hour bound alone |

A change to any input the receipt does not name rides on a receipt for up to
twelve hours. A receipt is a file a session can write, as the gate's own receipt
is that `felix merge` already trusts; reuse adds no new kind of trust, and
GitHub CI still runs the whole suite on Linux before anything merges.
