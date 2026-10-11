### 2026-10-11: the Stop hook holds once for each tree, reason and checkout in a session, and then records the unrun gate as a debt (slot 2a, part B)

Branch claude/hold-once, stacked on claude/token-governor (#423, part A) at
A_HEAD. Slot 2a of the carrier queue, part B of the brief in
audits/2026-10-09-token-burn/BRIEF.md (memory root). Engine only: hooks/stop,
hooks/session-end, hooks/user-prompt, lib/verify.sh and templates/monitor.html,
plus the suite: the two blind blocks as parts 1080 and 1090, and the rewake
assertions restated in parts 0210 and 0220. No table under projects/, no escape.

**What changes.** Today the Stop hook holds at every unflagged stop while the gate
has not passed on the tree. Every wake-up of an idle session (a task notification,
another session's message) ends in a stop, so the same unverified tree was held
again and again. Now:
- The first stop of a session on a tree is held exactly as before. The hook
  records the tree id, the reason (never verified, stale receipt, failed, epoch
  moved) and the checkout in `state/held-tree/<session>`.
- A later stop on the same tree, for the same reason, in the same checkout, lets
  the session go. It writes a `debt` row to verification.log, naming the tree and
  `held once on this tree already (session <8 chars>)`.
- A changed tree, or a new reason on the same tree, is held again once.
- A person's prompt clears the record and SessionEnd removes it, so the next
  unpassed stop holds once again. A runtime message (a task notification, the
  hook's own feedback) does not clear it.
- Held at every stop, as before, and never recorded:
  - a session that holds a night;
  - an unborn HEAD, or a coarse tree id;
  - a session id that cannot name a file;
  - a record that cannot be read or written, or is a link.
- FELIX_ALLOW_RED, a green gate and the foreign-chain rule are unchanged.
- The record is written only after the block is printed.
- The monitor page shows a debt row with the warning class.

**Measured.** `audits/2026-10-09-token-burn/replay_holds.py` replays the brief's
13.5 hours (2026-10-08T13:00Z to 2026-10-09T02:30Z). It reads holds from the
transcripts and tree ids from the verification rows they wrote.
- Before: 366 holds in 41 sessions, a median of 7 and at most 48. The brief
  counted 365.
- Replayed under this rule: 157, a median of 2 and at most 18. Every hold
  matched its row.
- At about 69K tokens a hold, the 209 that go are about 1.6% of a week.
- The replay assumes the same stops happen afterwards. The measured after is
  owed: re-run it, and `felix cost`, a week after this deploys.

**How it was built.**
- **Blind round 1.** 118 assertions from the contract, 45 red on main. The first
  implementation passed all 118.
- **Opus adversarial review.** It produced the addendum (contract items A to I):
  - the reason and the checkout in the key;
  - a night's session never debt;
  - no hold-once where the tree id cannot tell work apart;
  - mark after print;
  - a person's prompt clears the record;
  - links neither read nor written;
  - the session named in the debt row;
  - the monitor class.
- **Restated, not blind.** The record line changed shape, so two round-1 helpers
  and one assertion name were restated, and so were three existing rewake
  assertions. Each is marked in place.
- **Blind round 2.** 100 assertions on the addendum, 63 red on main. All 37
  that pass on main are controls. The implementation passes all 100.
- **Mutation.** All 18 mutants of this implementation are caught, each by the
  assertions it targets. Round 1 catches 6. The other 12 each break an
  addendum rule (every rule but B, whose case the reason mutant covers), and only
  round 2 catches them.
- **Record.** RECORD_RESULT. The gate passed on the final tree.
- **Version.** 0.49.279, pipelined on #423 (0.49.278).

**Not done here.**
- C: chips stay frozen until the founder lifts the deny row.
- The after measurement above.
