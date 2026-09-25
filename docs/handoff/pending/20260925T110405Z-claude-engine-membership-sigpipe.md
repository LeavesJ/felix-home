### 2026-09-25 — no engine test reads a pipe through a grep that can stop early: fifty sites converted, and a suite lint refuses the shape

**What shipped (claude/engine-membership-sigpipe).** Under `set -uo pipefail`
(the felix CLI, every hook, secret-scan, the suite) `producer | grep -q x`
reads a present value as absent whenever grep matches and exits while the
producer still writes: SIGPIPE, 141, and pipefail hands it to the `if`.
Deterministic past a pipe's 64 KB with the match early, load-dependent below.
Fifty engine sites are converted: whole-line membership is a case over
`"$nl$list$nl"`, a pattern over a value reads a here-string, and a producer
that is not printf of a variable is captured first or feeds one awk that
decides in END. Some of the old sites failed open: a confine left in a large
diff, destructive SQL in large added lines (escape and classify), a declined
moment that is wired, a duplicate candidate, a judge identical to the tree it
judges, and an unknown evidence row read as an all-clear.

A section in tests/run, "no engine test reads a pipe through a grep that can
stop early", holds the lint and one behavioural red per reachable site. The
lint scans felix, lib/*.sh, hooks/* and bin/*. Each red is a haystack past a
pipe matching on line 1, paired with a control at the last line, which can
never be falsely missed.

**Decided.**
- qualify.sh:138 and :238 took only the case-membership lines. The fuller
  rewrite in claude/qualify-membership-sigpipe returns 2 on an unreadable
  table, and main's callers read its empty output as `complete`. That rewrite
  lands with its callers in fdf77f's PR, which takes its own side of these
  hunks when it merges main.
- The lint covers engine code only. Table rows and projects/*.sh are separate
  work. Commissioning runs table commands in-process under the CLI's
  pipefail, unlike probes, obligations, setup and maintenance, which use
  `bash -c`. qualify.sh's `_felix_qualify_one` evals do the same.

**Traps worth keeping.**
- GNU grep treats a standard output of /dev/null like -q. Dropping -q and
  sending the output to /dev/null does not avoid the race on Linux
  (discover.sh said it did).
- The case idiom takes adjacent list lines as one match when the needle
  holds a newline. `felix maintenance --ran` now refuses such a value.
- `${v%"$nl"}` on a value that does not end in a newline scans every suffix:
  quadratic, 4 s on a 20k-line diff. A `$(...)` capture never ends in a
  newline, so feed it to the here-string as it is.
- On bash 3.2 a here-string is a 0600, immediately unlinked file in /var/tmp,
  whatever TMPDIR says.
- The lint cannot see head, sed q or an awk that exits early at the end of a
  pipeline whose status is read. The two there were (felix_overnight_field,
  felix_marketplace_root) are converted; its comment lists what else it
  misses.

**Open, and where.**
- The premise pair duplicates #364's. Whichever of the two lands second
  drops its own and re-records.
- Commissioning's in-process eval without pipefail: task started by the
  founder (branch claude/commission-eval-pipefail, #375).
- projects/*/*.sh (snapshot.sh:391 fails open on --public-readme; :457,
  elenchus/prepush.sh, sv2-apps/gate.sh): filed as a task.
- qualify.sh `_felix_qualify_one`'s evals under pipefail: session ad7567 is
  filing it.
