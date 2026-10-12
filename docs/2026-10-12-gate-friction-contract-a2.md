# Contract A2: a reused tests verdict merges only on a green CI gate

Addendum to contract A (docs/2026-10-12-gate-friction-contract-a.md), from
the push security review of 2026-10-12 on `projects/felix/gate.sh`'s reuse
branch. Same branch, same version (0.49.281), same tier.

**Why.** felix-home has no branch protection (the plan does not allow it on a
private repository), and `felix merge` does not ask CI: its boundary,
`felix_merge_blockers` in `engine/harness/lib/escape.sh`, needs a current
green gate receipt for the exact tree and the evidence rows. "Merge on green
CI" has been a convention. Contract A lets the receipt's tests verdict come
from a suite receipt, a second file a session can write. Forging it grants
nothing that writing the gate receipt does not already grant, but a defect
that reuses a run it should not would reach a merge with nothing independent
behind it. So a reused verdict needs the independent one.

## C9. felix merge and tests:reused

In `felix_merge_blockers`, after the current-receipt check and only when the
receipt is current and green:

1. If the receipt's reported field (the sixth) holds the pair `tests:reused`,
   the merge needs the project's gate workflow (the one `felix_gate_workflow`
   names, as `lib/repair.sh` and `lib/automerge.sh` already ask it) to have a
   run on the exact head commit being merged whose status is `completed` and
   whose conclusion is `success`. Asked with `gh run list` for that workflow
   and that commit, as those two libraries ask it.
2. When it has one: no blocker from this rule.
3. Otherwise one blocker row, kind `unverified`, subject `tests`, whose reason
   begins `the gate reused a suite run for this tree (tests:reused), and the
   gate workflow has not passed on <first 8 of the head sha>:` followed by
   which of these held:
   - `no run on this commit`;
   - `its run is <status>` when none is completed;
   - `its run concluded <conclusion>` when the newest completed one did not
     succeed;
   - `GitHub could not be asked (<what failed>)` when `gh` is missing, fails,
     or prints nothing a run can be read from. Unreadable is never "no runs"
     and never a pass.
4. A receipt without `tests:reused`, `tests:ok` included, is judged exactly as
   today: this rule asks nothing of it and makes no call to `gh`.
5. `felix merge --dry-run` reports the blocker as it reports the others.

The judge is the engine main declares, so this rule binds from the deploy of
the commit that carries it. PR A itself is gated with a full suite run, not a
reused one, so it is not held by its own rule.

## What the build must show

The block red on the code before C9, then green. Mutants: drop the rule;
treat a gh failure as a pass; accept a run on another commit; accept
`in_progress`; ask gh when the receipt says `tests:ok`.
