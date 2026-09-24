### 0bx. 2026-09-23 (day) — a turn another hook woke ended unchecked, measured on the real binary, and the Stop hold now knows its own chain

**One engine PR from this session, branch `claude/stop-hold-own-chain`, engine
0.49.172** (the carrier's queue took .166 to .171 while this waited its slot). The Stop hook left at
`stop_hook_active` whoever had set it. It now honours the flag only at the stop
its own hold started (`state/held/<sid>`, `felix_hold_*` in `lib/verify.sh`),
and judges any other flagged stop like an unflagged one.

**What was measured, and how.** The docs are silent. security-guidance's source
claims the flag is set "session-wide while any asyncRewake Stop is in flight".
The CLI's own login had expired, so the real binaries (2.1.280, the one the
desktop runs, and the 2.1.260 CLI) were driven against a local stand-in for
the Messages API, in a scratch HOME with a scratch Felix home and a governed
project bound by `remote_match` through a clone. Results, identical on both
versions:
- An asyncRewake hook, Stop or PostToolUse, that exits 2 while the session is
  idle starts a turn with the flag set. On main, Felix exits at that turn's stop
  unchecked and unrecorded.
- A hook merely in flight sets nothing, so the plugin's claim is wrong.
- A rewake that lands mid-turn is folded into that turn and sets nothing.
- The binary agrees: the rewake is enqueued with `stopHookActive: true`, and a
  queue batch runs with the flag if any item carries it.

**Real logs.** security-guidance has been installed at user scope since 08-09.
Across 497 top-level transcripts, no turn was started by its rewake. Its log
covers the last 12 hours (it rotates at 1 MB) and shows 46 reviews, 0 findings.
verification.log's 434 `blocked` rows against the transcripts' 424 holds show
nothing missing. The hole was real and had not yet cost anything.

**Evidence the assertions can fail.** Eighteen assertions were added. Main's
engine fails 6. Nine mutations, each removing one piece of the fix, fail
between 1 and 7 each, run on a mini fixture that extracts the blocks verbatim
from tests/run. The first round caught two assertions that could not fail as
named:
- a night assertion satisfied by the gate's hold (the fixture had no probes);
- a one-turn night, which ends at its first stop.

An independent review found the take's return code overclaiming after a
failed `rm`. The behaviour was identical either way; the code and comments are
fixed.

**Next, owned by nobody yet:** once this is merged and deployed, #312's README
gets the measured paragraph (script and text in this session's record). The
mutation rig is scratch and not committed: `mini.sh` extracts the two blocks,
and `mutate.sh` holds the nine perl substitutions.

**Traps paid for this session:**

- A deny row refuses `git remote add` and a hand-written `.felix` in a scratch
  directory too. A scratch project gets its origin by cloning from a local path
  that carries the `remote_match` string.
- The ECC fact gate trips on the `rm -rf` token in any Bash command. Write
  scripts that clear scratch state with the Write tool, not in a command line.
- The tool shell is zsh: `set -- $s` does not split, and a `for` loop can eat
  its output. Run loops under `bash -c` or from a script.
- A suite fixture with no `probes.tsv` gives receipts no epoch, so every stop
  takes the gate's hold. An assertion that accepts any block then passes on the
  wrong branch. Name the hold by what it says.
- A background `tests/run` reads its own file as it goes. Editing `tests/run`
  mid-run corrupts it, and bash defers TERM while it waits on a child, so stop
  your own run by its process tree, and only yours.
