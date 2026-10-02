### 2026-10-01 — handoff-check, lifecycle-check and obligations-check find their libraries before moving to the top, so a relative call from a subdirectory no longer ends 127

**Engine change, no version of its own.** The carrier put it in the weekly
batch: main's gate was never red. projects/felix/gate.sh, obligations.tsv and
qualification.tsv all call these scripts from the top level. It rides in
claude/handoff-fold-in-flight if that session takes it. Otherwise it waits on
claude/handoff-check-relative-path for a slot.

**The defect.** Each script ran `cd "$(git rev-parse --show-toplevel ...)"`
before `HERE="$(cd "$(dirname "$0")/.." && pwd)"`. A relative `$0` read from
the top names a directory that does not exist, HERE comes out empty, and the
library is sourced from /lib.

| Called as | Before | After |
|---|---|---|
| `cd docs && ../engine/harness/bin/handoff-check` | 127, `felix_handoff_check: command not found` | 0 |
| `cd engine/harness/templates && ../bin/lifecycle-check …` | 2, "cannot examine" | same as from the top |
| `cd engine/harness/templates && ../bin/obligations-check projects/felix release` | 1, ran on without its libraries | same as from the top |

**The fix.** HERE is found first, the way handoff-in-flight does it. Arguments
are still read from the top. A HERE that cannot be found exits 2, the
"cannot examine" code, in handoff-check and lifecycle-check. obligations-check
exits 127 there, because 1 would read as a violation (deploy-check's rule).
No other script under engine/ moves to the top before reading `$0`.

**Red first.** Three assertions in tests/run were shown failing against an
export of origin/main 27573cbe with a section runner (preamble plus section):
handoff-check got 127 where 0 was expected, and lifecycle-check and
obligations-check each gave a different answer from a subdirectory than from
the top. All three pass on this branch: 11/0 in the obligations block and
41/0 in the handoff section. The handoff fixture reaches the harness through
a link beside it, `$TMP/hxh`. Read from the top of the checkout, that
relative path lands one level too high, so the assertion cannot pass by
accident. assertions.tsv and red.tsv were not recorded, since a record waits
for a slot.
