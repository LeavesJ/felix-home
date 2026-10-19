### 2026-10-19: session start names docs/direction.md first, as the standing direction

On 2026-10-19 the founder asked for one document with "the absolute say in
standing", so a fresh session knows which roadmap is current. Felix's copy is
`docs/direction.md`, written on `LeavesJ/felix-claude-code-2-1-303-07d9c8`
(2b8a6d21) and merged only on the founder's yes. This engine change is
independent of it: with no such file, nothing changes, so it can land first.

Branch `claude/direction-read-first`, engine head 4f823a9d (this section
rides on top of it), PR LeavesJ/felix-home#452, draft.
**Record + gate owed at slot.**

**Contract.** `docs/2026-10-19-direction-read-first-contract.md`, with
Amendment 1 from the review: P1-P9, A1-A5, W1-W2, G1.

**What changed.**
- `engine/harness/hooks/session-start`, the block that builds `read_lines`.
  When `R/docs/direction.md` is a regular file, and neither it nor `R/docs`
  is a symbolic link, the reading list opens with it:
  - one line above the list, unindented: `docs/direction.md is the standing
    direction: where an older roadmap, handoff section or memory note
    disagrees with it, it wins.`;
  - then `Read before planning: R/docs/direction.md`;
  - then the constitution, HANDOFF.md and the pending sections, as before.
- Absent, or a pipe, a directory, a link, or under a linked `docs/`: the
  output is byte-identical to main's. The path is generic (invariant 1), and
  the file is never opened: the link checks run first, then `-f`.
- README (install note, hooks table) and `engine/commands/felix.md` say so.
- Version 0.49.303 is a placeholder (carrier rule 1).

**Evidence (section runner only, by the starting session's decision).**
- Part 1550 is blind and has 125 assertions. Run alone (`marked.sh`):
  - 187 ok, 0 FAIL, reached, on the branch (the count includes the prelude's
    assertions);
  - 66 FAIL on main's hook (50601023);
  - 37 FAIL on the first implementation (a7e304ce), after Amendment 1;
  - part 0010 alone: 148 ok, 0 FAIL.
- Mutants, each killed by the clause it breaks. Round 1, on the first
  implementation: 11 of 11. Round 2, on the final code: 13 of 13, a
  fourteenth meant as "always named" having reduced by shell precedence to
  the linked-`docs/` mutant, killed with it. Round 2's were: `-e` for `-f`;
  a followed link at D; a linked `docs/`; the line between D and the
  constitution; `-s`; opening D; always named; `$PWD` for the root; an
  indented line; a blank line; no line; the old text; no constitution. P9 (the link checks run first) has no test, because it needs
  a mount that does not answer.
- A1 against main: ran main's hook (50601023) and this branch's on the same
  fixtures, outside the suite. Five states are byte-identical: bare;
  HANDOFF.md, seven pending sections and a session handoff; a pipe, a
  directory and a link at D. A regular D differs. Scripts and logs are in
  `audits/2026-10-19-direction-read-first/` under the memory root.

**Review (Opus).** "Ship after fixes". Taken:
- the line scopes "older" to all three;
- the line moved above the list, so "None of those" still points at the list;
- the link checks come first;
- the comment was made accurate;
- the doc disclosure;
- the A1 comparison against main.

Not taken, and why:
- An opt-in `project.json` key. It is not in the spec, and the convention
  needs no setup. An unrelated `docs/direction.md` costs one read the model
  can dismiss.
- A caveat in the line for an unmerged copy. It names the checkout's own copy,
  as it does HANDOFF.md, and the file itself says that a branch changing it is
  proposing direction.
- Saying in `felix status` that a link at D was refused. A possible follow-up.

**Order.** This enters the weekly batch under 0cw fix intake, unless the
carrier gives it a slot. #450 (.301) and the pattern-kill row (.302) go first.
At its slot:
1. merge main;
2. take the version;
3. `tests/run --record-assertions` (part 1550's names are not in
   `assertions.tsv` yet);
4. `felix gate`.

The direction document's PR is separate and needs the founder's yes.
