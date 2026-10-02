### 2026-09-25 — a lesson or devlog entry settles only its writer's catches: `felix lesson` and `felix log` record who wrote each entry in written.log, and the unrecorded-catch prompt reads nothing else

**Engine change, adversarial tier.** lib/guard.sh, lib/memory.sh, felix
(`cmd_lesson`, `cmd_log`) and tests/run. It is stacked on the session-scoped
catch side (claude/unrecorded-this-session) and rides in that PR. No
commissioning table moves.

**The gap.** The catch side knew whose catch it was, but the settling side
still read the modification times of lessons.md and DEVLOG.md. So any
session's write silenced any session's catch. The real lessons.md gains 5 to
16 lessons a day against 2 to 21 catches, so a peer's lesson landed within
hours of nearly every catch.

**What changed.**
- **A new record.** `felix lesson` and `felix log` append one row per entry to
  `<memory>/written.log`, in mistakes.log's six-column shape: day, branch,
  sha, kind (`lesson`/`log`), epoch, session. One set of helpers at the top of
  lib/memory.sh spells the branch, sha and session. The gate's row, the
  entry's row and the devlog header all use it, which makes a devlog header on
  a checkout with no commit one line.
- **Who can settle a catch.** The guard settles a catch only with an entry its
  owner wrote strictly after it. A catch filed under a session needs an entry
  from one of the conversation's sessions. A catch filed under no session
  needs an entry on its branch. Where the guard can tell neither, nothing
  settles it.
- **Owners are weighed separately.** The newest catch of each kind of owner is
  weighed on its own, and the newest one still owed is the one named. This
  came from review: a session-less catch landing after this session's own let
  a peer's lesson silence both. An entry dated after now settles nothing.
- **What no longer settles.** Hand edits, consolidations, and anything written
  before written.log existed settle nothing. lessons.md and DEVLOG.md text is
  byte-identical.
- **The prompt** names `felix log "..."` for a one-off, and says that only an
  entry written by the catch's owner settles it.
- **Failed writes.** If the written.log append fails, `felix lesson`/`felix log`
  exit 1 and say the entry is there and must not be written twice. This used
  to print success.

**Transition.** No written.log exists until this deploys. A running session
that explained a catch from the last week will be asked once more;
`felix lesson` or `felix log` answers it. Sessions on an older engine keep
writing session-less catch rows until they restart. Those rows are owned by
their branch, which is why each kind of owner is weighed separately.

**Evidence.**
- **Blind block.** 110 assertions were written from the contract alone. 60 are
  red on the engine before this change.
- **Author and re-keyed cases.** Another 22 are red there, and the section
  passes 226/226.
- **Mutations.** Every mutation of the guard, the writer and the CLI fails at
  least one assertion. An unsanitised session id is caught only by the blind
  block. The two rules review added, each owner weighed separately and no
  future-dated entries, are covered only by the author's cases, and the blind
  header says so.
- **Re-keyed cases.** Eighteen earlier cases settled by file time: three in the
  oldest block, six in the session-scope block and nine in its blind block.
  They now write through the writers, or write the row at the same stated
  second, and each asks what it asked.

**Left open.**
- A resumed or forked copy of a conversation whose transcript opens under
  another copy's id could settle that copy's catches. This was reasoned in
  review, not demonstrated.
- A CRLF edit to mistakes.log hides a catch. That is the catch side, and only
  a hand edit produces it.
