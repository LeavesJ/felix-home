### 0cl. 2026-09-25 — the project scripts read a pipe's answer from the whole list: a README change under --public-readme and a monitoring change in sv2-apps are no longer read as absent

**No engine change.** Three files under projects/, ordinary tier, none of them
a commissioning table, so the commission receipt does not move.

**What changed (claude/projects-sigpipe).** The engine's sweep (#376) left
projects/*/*.sh as open work. Each site below read `producer | grep -q` or
`| head -1` with its status taken under pipefail: the reader quits at its
match, the producer dies of SIGPIPE writing the rest, and 141 reads as no
match.

| Site | Before, with the match early past 64 KB | Direction |
|---|---|---|
| snapshot.sh, README under `--public-readme` | a README change passed, 10/10 | open |
| sv2-apps/gate.sh, openapi trigger | a monitoring change skipped the check, 10/10 | open |
| elenchus/prepush.sh, `must_pass` | a hit read as none, 10/10 | open |
| elenchus/prepush.sh, `must_flag` | a hit reported as MISS, 10/10 | closed |
| snapshot.sh, suite summary | a passing suite refused, 10/10 | closed |
| snapshot.sh, `slug_of` and `ver_of` | `set -e` ended the run with no message, 10/10 | closed |

Every last-line control and every no-match row answered the same before and
after. Both of snapshot.sh's self-test rows still reproduce their trees
(MATCH), and prepush's `--self-test` passes. The grep sites read a here-string
of the captured output, so a failing git still reads as no match. The two
helpers end in `sed -n 1p`, which reads to the end, in place of `head -1`.

**Checked and left alone.**
- felix/gate.sh has five `$(... | head -1)` captures. That gate runs without
  `-e` and reads none of their statuses, so the race costs nothing there.
- sv2-apps/gate.sh:23 feeds grep through `<(...)`. A process substitution is
  not a pipeline, and pipefail never sees it.
- The gates' `| head -N | sed` display lines have unread statuses too.
- No script writes GNU grep's output to /dev/null through a pipe.

**Trap worth keeping.** A filter between the producer and `grep -q` hides the
race. prepush's `secret_hits` is two greps, and a grep writing to a pipe
buffers its output. A single early hit reaches `grep -q` only when the filter
exits at EOF, after the producer has finished, so that fixture never goes red
(one hit on line 1 of 900 KB: caught 20/20 on the old code).
The red fixture needs enough hits to flush the filter's buffer before the
input ends: 30,000 lines, about 1 MB.

**Open.** The engine suite's lint covers engine code only. A lint over
projects/*/*.sh would be an engine change to tests/run. Not filed.
