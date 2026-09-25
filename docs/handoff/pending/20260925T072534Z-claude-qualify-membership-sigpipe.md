### 2026-09-25 — the needs-count flake was printf into grep -q under pipefail, not a failed read; qualify's membership is a case in the shell now, and an unreadable qualification.tsv is said, not resolved

**One engine PR from this session, version 0.49.222** (lib/qualify.sh,
lib/obligations.sh, felix, tests/run). Why the #310 count assertion read
`3 0 2 1 2` once under load: `printf '%s\n' "$have" | grep -qxF "$c" || missing`.
grep -q leaves at its first match, bash 3.2's printf writes a list one write()
per line, the writer still writing dies of SIGPIPE, and pipefail (the CLI's and
the suite's) turns that into "not declared". Stress on main: 205 false misses
in 72,000 membership tests, every one `PIPESTATUS=141 0`, and never the last
line, which is what ruled out the fork-failure hypothesis. Deterministic once
a list outgrows a pipe (~64 KB): the writer must block.

**Two follow-ups filed as tasks, not done here:**
- `felix qualify --gate` fails OPEN on main when `felix_qualify_run`'s read of
  the table fails after the first read held: 0 of 0 held, exit 0, `qualified
  ok`. Found by this PR's adversarial review; it moves a verdict, so it takes
  its own spec and red.
- Twelve more `printf "$var" | grep -q` sites under pipefail (exceptions.sh,
  candidates.sh, escape.sh, ledger.sh, coverage.sh, felix:665/878/915/3236).
  Some may fail open (felix:3236 misses an `unknown`).

**Traps paid:**
- A roster name with digits is not a checker line to
  `felix_qualify_ungoverned` (`[a-z][a-z-]*`), so a probe with `c00000`
  looked like the race did not exist there. It did.
- To tell two candidate causes of a flake apart, find the observation they
  disagree on (here: which control can be named missing) before building on
  either.
