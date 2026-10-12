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
