## 0ay. Verified at session close, 2026-09-12 (night) — the standing direction became a mechanism, and two probes caught what reading could not

| | |
|---|---|
| head | `main` 77ed1b2; this work on `fix/deny-the-hanging-wait`, tier **red** |
| suite | **1865** passed, 0 failed — 1818 plus 47 authored blind |
| new | `felix overnight`, a deny row, 3 duplicate lessons cut, the graph at 1957 nodes |
| deferred | 2 decisions waiting on the founder, in the night's own queue |

**The founder asked for an overnight session and, more to the point, for the
instructions to stop being something he types.** Four of them, every long
session: keep going rather than stopping to report, skip what needs my
permission and collect it for the morning, verify with the gate, keep building.
A standing direction repeated by hand is a mechanism nobody built, which this
project's charter calls a Felix failure in as many words.

**`felix overnight` is that mechanism, and it grants no authority.** A person
starts a night; it is bounded three ways — wall-clock hours, a count of
continuations, and two consecutive continuations that found nothing to do —
and whichever arrives first ends it. `--defer` writes a boundary down with the
command that would clear it, instead of waiting on somebody asleep, and
`--report` is the morning page. Every refusal, channel and gate still stands
exactly as it did; what changed is what a session does when one of them stops
it. SessionStart mounts the direction while a night is live and says nothing
otherwise. The Stop hook, on a green gate only, spends one continuation and
blocks with what it can actually see — maintenance due, decisions deferred —
then ends the night itself at a bound and hands back the report.

It cannot loop, and not because of anything written here: the platform sets
`stop_hook_active` on a block and caps consecutive blocks, which is the same
ceiling the gate's own refusal has always had. What Felix cannot do is make a
model take a turn, so this lays rails and does not drive: a night with nobody's
session open is a night where nothing happens.

**The night this was built during ran without it, and that is the usual trap.**
The hooks that fire in a session are the ones the plugin cache held when that
session started, so the mode's hook half reaches the NEXT session after `felix
install`, not this one. The state and the command work immediately from the
tree, which is how tonight's two deferrals were written. A redeployed engine
never reaches the session that deployed it; this is that lesson again, and it
means the first real test of the Stop-hook branch is somebody else's session.

**Two defects in it were found by probing, not by reading.** The branch first
asked "is a night live", which made the code that ends an expired night
unreachable — live is false exactly when a bound has been reached, so a
deadline that passed while a session sat idle would skip the branch, leave the
state behind and close without ever handing over the report. A fixture whose
deadline was in the past found it in one run. And blocking first silenced every
message below it, including the verification nudge the founder had just asked
to always run; the block carries them now. Both are the same shape: a branch
that cannot be reached, and a branch that swallows its neighbours.

**The founder also spotted a real defect, and it was mine.** Seventeen
background tasks and thirty-four stray helper processes, some over a day old.
Every wait this session used a timed read from a process substitution, which
returns after five seconds under bash and NEVER returns under zsh — measured
from a probe, still blocked when a twelve-second cap killed it — and leaks the
helper either way. Sessions here run zsh, so each wait hung on its first pass,
was moved to the background by the tool's own timeout, and spun there. The
pattern appears in exactly one transcript out of 116: this one, 22 times. It is
a deny row now, shown refusing the shape through the deployed hook and leaving
five ordinary commands alone.

**The two due routines ran.** `lessons` read all 135 entries through nine
readers, each defaulting to keep, and every proposed cut then went to a
defender told to save it: three survived, all exact duplicate pairs, and the
better-written twin of each was kept. That conservatism is the point — one
defender re-ran a scenario with a patched `route.sh` to show a "mechanized"
claim was false. `graphify` refreshed to 1957 nodes, 2601 edges, 194
communities.

**Three things the graph refresh found, none of them about Felix.** A hyperedge
with no `id` crashes `build_merge` outright rather than warning, and the
extraction that produced it was one of my own subagents dropping a schema
field. The shrink guard then refused the write, correctly, until the reduction
was accounted for: every one of the 13 lost nodes belonged to the single
re-extracted document and no other source moved. And re-extraction replaces
only what the LAST run wrote, so `HANDOFF.md` carried 414 nodes for a document
that yields about 270 — roughly 135 stale nodes minted by an older run under
ids that no longer match. That is worth a pass of its own.

**Next, in order.** (1) Merge this branch; it is red tier, so that is the
founder's. (2) find-skills item one, the content hash: `felix discover` fetches
a candidate at a pinned sha and reads it, then `felix stack apply` installs
whatever the marketplace currently holds, and nothing compares the two. The
read copy is deleted after judging, so the hash has to be taken at read time
and stored in the cache row. (3) Step 2's epochs as hashes. (4) The stale-node
pass on the graph. (5) Standing, unchanged: `projects/bazaar` and
`projects/webapp` are untracked, and `53fc527` holds three assertions absent
from `main` — both are in the night's deferred queue.

