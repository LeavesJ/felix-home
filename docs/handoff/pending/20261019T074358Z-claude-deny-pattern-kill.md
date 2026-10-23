### 2026-10-19: Felix refuses a pattern kill

**What.** One new row in `projects/felix/deny.tsv`, tool Bash, whose reason begins `a pattern kill`. It refuses `killall`, `pkill` unless a word binds it to a pid, and pids from a pgrep that no pid binds being handed to kill. Part 1600 holds the cases.

**Why.** Twice an agent killed by pattern although its prompt forbade it: `pkill -f 'engine/harness/tests/run'` on 2026-09-25, and `pkill -f 'sleep 3'` on 2026-10-18. Each time the pattern reached other sessions' runs on this machine. The founder chose to refuse them on 2026-10-19 ("Refuse them"). The row is an escape table change, so the founder merges it.

**Decided while building.**
- **Pid-bound forms are allowed.** `pkill -P <ppid>` (a list without 1) and `-F <pidfile>` kill the children of a pid the session holds. The machine's real commands showed 23 of them used for exactly that, so they are allowed.
- **No-signal forms are allowed.** `kill -0` and `kill -s 0` send no signal, and a pgrep piped to `wc` prints a count.
- **A quoted pattern is one word.** The reading prints every separator as a token with blanks round it, so a `|` glued inside a word came from quotes.
- **pgrep's pids killed through a variable or a loop are refused** (`p=$(pgrep -f x); kill $p`, `for p in $(pgrep ...)`, `pgrep ... | while read p; do kill $p`). This is the natural workaround once `pkill -f` is refused. The adversarial reader found it, and the corpus held 12 real cases.

**Limits.** These follow from the reading appending each substitution's body after the text. The row's comment lists them, and the tests assert none of them either way.
- A kill whose pgrep body is not the last body is missed.
- A command that kills by pid and ends with a `"$(pgrep -fl x)"` check is refused. Run the check as its own command.
- Inside a `-c` script, the variable and loop forms are missed.
- Remote forms and quoted sed, cp, rm or touch operands holding `; pkill` are refused although nothing is harmed.

**Evidence.**
- The contract and its two amendments: `audits/2026-10-19-pattern-kill-deny/contract.md`. The readable regex source that reproduces the row byte for byte, the corpus tools and the adversarial case files are in `tools/` beside it.
- Part 1600 was written blind, red before the row existed, and extended blind for each amendment: 279 cases.
- Over the 4705 distinct commands naming kill in this machine's transcripts, the row refuses 173. Of those, 159 are pkill -f or a pgrep -f feeding kill, 12 are variable or loop kills, and 2 are the second limit.
- CPU: about 1 ms per Bash call, mostly bash compiling the pattern, and about 14 ms on a 30,000-character reading of plain words.

**Next.** Once the founder merges this, the PreToolUse hook refuses pattern kills in every session and subagent that judges against the home checkout. Prompts may keep the no-pattern-kill rule as a reason, but the row is what enforces it.
