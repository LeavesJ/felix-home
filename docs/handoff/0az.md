## 0az. Verified at session close, 2026-09-12 (overnight) — seven branches, and three things that were false before anybody checked

| | |
|---|---|
| open, green, waiting on the founder | #222 #223 #224 #225 #226 #227 #228 |
| suite at the top of the stack | **1977** passed, 0 failed |
| assertions authored blind tonight | 18 for the scanner, 44 for the digest, 48 for the epoch |
| decisions queued | 9: six merges and three questions |
| defects a blind author found that the code's author had not | 3 |

**Invariant 4 was literally false, and is now checkable (#224).** "Felix
installs what it has read and judged low-risk" described a thing that never
happened: `discover` fetches a candidate at its pinned sha into a scratch
directory and reads THAT, and `claude plugin install` then fetches its own copy
from the marketplace. Two fetches, no comparison — and no way to make one
afterwards, because the catalogue drops a plugin from `--available` the moment
it is installed, so its source coordinates stop existing. The digest is
therefore taken at read time, from the copy the tier was scored off, and kept
as the discovery cache's fourth column. Three places compare it: both install
doors, and `felix discover` for anything that has drifted since.

The exclusions were measured rather than guessed. Five plugins are present both
in the marketplace checkout and in the install cache here; three are
byte-identical once `.in_use/` is dropped, which is how the installer was shown
to be a straight copy. The other two have drifted: a marketplace advanced its
branch and left the version at 1.0.0, so the copy on disk is not the copy that
was judged, and nothing anywhere said so.

**The graphify row was on in almost every session and should not have been
(#225).** It asked whether the graph was newer than the newest commit in the
tree the caller stands in. In a worktree that is unmerged work no refresh would
put in the graph, and sixteen of seventeen recorded session roots here are
worktrees. Measured same-graph, same-second: `ok` from the checkout, `due` from
a worktree of it. That banner is what sent this session looking for a refresh
that was not owed. It reverses a reading the suite had written down on purpose,
and the PR argues the reversal rather than hiding it.

**Decision epochs exist (#227).** v3.2 §3's hash, composed from the four things
it names: the project and the repository it governs, the grounded probe facts,
`felix_commission_policy_version`, and the release target. It reports and
changes no verdict, deliberately — Felix's existing rule is stricter than the
spec's, and wiring an epoch into a stop so a shrink became permissible would
widen a mechanical refusal on the strength of a hash computed in the same
process. An unknown component yields no epoch at all rather than a hash over an
absence.

**Three defects were found by people who could not see the code.** The blind
author of the epoch assertions came back with two that did not pass, and both
were right: `felix_epoch_policy` answered for a project directory that does not
exist, with the same hash every empty project gets — two absences comparing
equal, which is the argument the digest on the branch below had already made
and which they arrived at independently; and two of five functions printed no
trailing newline, so three ended their line and two did not. The blind author
of the digest assertions found the third, by stopping where the specification
stopped rather than copying what the code did.

**Two environmental facts, both measured.** Installed plugins leave the
catalogue, as above. And the Felix home is inside iCloud Drive:
`~/Library/Mobile Documents/com~apple~CloudDocs/Documents` is a symlink to
`~/Documents`, so the checkout and `state/` are both synced, and eleven
zero-byte files in `state/discover/` named `felix.tsv 2.new` are the sync layer
renaming a temp file Felix meant to remove. Harmless where it landed; not
harmless if it ever lands on a receipt mid-write. The memory root is outside it,
because it is computed from `$HOME` and not from the home — invariant 6's
second, unplanned payoff.

**The stack merges in order.** Measured before it was claimed: merging #222
first made #223, #224 and #225 conflict in `tests/run`, because every block of
assertions is appended before the same anchor. Each branch now carries the one
below it, so the order is #222, #223, #224, #225, #227, with #226 independent.

**Next, in order.** (1) Merge the queue, then `felix install` in the home, then
re-grant commission. (2) The topology question in #227's body: counts or shape.
(3) The next checker through the six controls, blind. (4) `projects/bazaar` and
`projects/webapp` are still untracked and still the founder's call.

