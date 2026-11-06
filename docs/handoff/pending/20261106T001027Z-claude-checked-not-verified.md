### 2026-10-31: the engine says checked, never verified or proven (decision 1, 0.49.321)

**What changed (branch `claude/checked-not-verified`, a draft pull request
labelled `needs-founder`).** This applies the founder's decision 1 of
2026-10-31, "Checked, in every text" (direction row 36 in draft #481), to the
engine's own printed and committed text. It is built to
`docs/2026-10-31-checked-not-verified-contract.md` (C1-C23). Round 3 of that
contract restates the first adversarial review's findings.
- On main, 25 engine lines said verified, unverified, proven, unproven or
  proves to a person. Each now says checked or what ran:
  - `felix help` (its first line said `and proves it`), `felix install`,
    `felix merge` and `felix classify`;
  - the pulse's backup line (`pushed and read back`);
  - the notifier's two deploy sentences and the standing issue's body;
  - the tick's deploy-owed reason, the cloud debt and SubagentStop messages,
    and the probes' witness sentences;
  - the unattended template's commit subject, `moments.tsv`,
    `lifecycle.tsv`, `/felix`, and the README's hook row.
- `felix receipt` is `felix.receipt/2`. `checked` is /1's `verified`. /1's
  `unverified` is now one of three words:
  - `failed`: the gate ran red on this exact tree;
  - `evidence-owed`: it ran green here and evidence is owed;
  - `unchecked`: nothing current judged this tree.

  The planned evidence packet is `felix.receipt/3` now. `docs/handoff/0cw.md`
  planned it as `/2`, and an archived section keeps its words.
  Nothing in the engine, its CI or a project gate reads a receipt's status;
  the suite does.
- The Stop hook's reason for a checkout with no gate receipt is
  `never checked`. `felix_hold_tree_seen` still counts a record written under
  the old reason as the same hold, so a session that spans the deploy is not
  held twice.
- Parts 2300 and 2301 (C18) fail on any engine line outside a comment that
  says the words, other than the kept names below. Part 2300 allows each of
  those only in its own files.

**Kept, and why.** Two kinds keep their names: `lib/escape.sh`'s merge blocker
kind `unverified` and the ledger kind `deployed-unverified`. Each has readers
and recorded rows, and a person reads both:
- `felix merge` and the session-start list print the blocker kind;
- `felix land --status` and the standing issue's comments print the ledger
  kind.

They move together, in a change of their own. Also kept: the say kind
`subagent-unverified` and `state/verified/`.

Outside the class on purpose:
- the obligations `what a fix must prove` and `the fix will have to prove`;
- the negation `nothing proving it`;
- `verify` as a step or an instruction.

**Stated limits.**
- L1 (high-stakes, `lib/receipt.sh`): an outside reader of
  `felix.receipt/1` that keys on `verified` now gets `/2`. None is known. The
  in-toto mapping draft #476 describes /1's values and needs the same rename.
  `/2` names no gate command and nothing the gate skipped; the /3 packet will
  carry those.
- L2: a governed repository's copy of `templates/unattended.yml` keeps
  "verified by the gate" until a person copies the template again.
- L3: records written before the deploy keep the old words. The 2026-10-09
  token-burn replay script in memory keys on the old reason.
- L4: a gate receipt that exists but cannot be read still reads as none.
- L5: C18 skips a printed here-document line that starts with `#`, and it
  reads words, not meaning.

**Follow-ups.**
- Rename the two kinds together.
- Make classify, receipt and evidence test `evidence.tsv` the way the judge
  does: `-e || -L`, not `-f`. This is older than this change.

**Built.**
- Contract: Opus 5.5, this session, rounds 1-3.
- Blind part 2300: Opus 5.5 xhigh, isolated worktree, 42 assertions. 30 were
  red against main and 12 were controls that stayed green. This session later
  added A43-A48 and moved A29, A34, A35 and A37 to round 3's words; none of
  that is blind.
- Blind part 2301: Opus 5.5 xhigh, from round 3 alone. Of its 38 assertions,
  19 were red before round 3 and 19 were controls that stayed green. This
  session rewrote A38 when C23 was amended; A38 is not blind.
- Review: Opus 5.5 xhigh, three lenses then one Opus 5.5 high skeptic for
  each lens's first two serious findings. A last round-3 lens, Opus 5.5 xhigh
  with an Opus 5.5 high skeptic, found two gaps in part 2300's tests of its
  own lint. A45 now covers all six allowed texts, and A48 a directory git
  tracks nothing of.
- Implementation: this session.
- The gate's result is in the pull request's body.
