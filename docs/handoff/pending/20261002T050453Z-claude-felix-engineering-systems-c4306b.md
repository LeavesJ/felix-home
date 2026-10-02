### 2026-10-02: felix inventory (Phase 0b step 4), revised against the settled spec

Branch `claude/felix-engineering-systems-c4306b` (built locally as `inv-build`). The spec is
the founder-settled contract of 2026-10-01, `audits/2026-10-01-report-v5-review/specs/inventory/spec.md`
under the memory root, with its `assertions.md` (blind), `disposition.md` and,
under `build/`, `reconcile.md`, `review.md`, `review-disposition.md` and
`red-evidence.md`. An earlier push of this branch (`385f6f8d6`) held the tests
and no implementation: the implementation stage had not run, and the adversarial
review said so. This section is the build that answers it.

**What `felix inventory` does now.** `felix inventory [--repo DIR]... [--tsv]
[--live M] [--blocked M] [--days N] [--no-gh] [--no-host]` reads, and writes
nothing into a repository, where unlanded work is. It is dispatched right after
`felix audit` and answers from a plain clone.
- **Rows.** Per repository, five `cover` rows first (default, prs, sessions,
  chips, objects: what was read, how stale, or why it is unknown), then one row
  per worktree, orphan (a directory git forgot), local branch checked out
  nowhere, remote branch no local branch covers, open PR no local branch
  proposes (a fork's PR is always one), unstarted chip and pending handoff
  section. `--tsv` has eight columns: `kind repo ref states owner age_h content
  detail`.
- **States and content.** States print in a fixed order, the first the
  headline. `landed` needs none held but `live` and content `landed` or `-`.
  Content is landed, partly, not or unknown: a tip the default branch reaches or
  a merged PR's head equals or descends from is landed; otherwise each path the
  tip changed is compared with the default branch's blob. Rule 5: a pushed tip
  whose rule-3 value is not or partly reads unknown when the PR facts could not
  settle it.
- **GitHub.** Two `gh pr list` calls per repository, with `isCrossRepository`
  and `isDraft`, flags joined by spaces, a fork's PR never a proposal.
  A listing of 1000 is partial and says so.
- **The host (Claude Code).** One adapter, `lib/inventory-host.sh`, reads the
  records under `$CLAUDE_CONFIG_DIR/projects` or `$HOME/.claude/projects`. A
  session's time is its newest user or assistant record's timestamp, the file's
  mtime only as a stand-in and said so. The newest session is the latest by
  that; activity counts every file under `<session-id>/` and a spawning agent's
  transcript; `blocked` is measured from the pending `tool_use` record; a last
  line cut before its end is no record. A PR's owner is the session of the
  newest record whose `gitBranch` is its head, by its own `sessionId`.
- **The view.** Without `--tsv`, grouped for a person by the states and the
  content column, with each repository's counts line.
- **Shell.** bash 3.2, awk under `LC_ALL=C`, no here-document, no pipe into an
  early-exit grep, every git call through one prefix that includes
  `-c log.showSignature=false`. Six libraries, all under 500 lines
  (`inventory.sh` 443, `-items` 212, `-gh` 103, `-orphans` 187, `-view` 58,
  `-host` 484).

**The §11 rows applied: 1-8 and 10-19.** Row 9 (re-record, bump, this section)
is the carrier's at its slot.
1. Eight columns. 2. `cover` rows replace kind `repo`. 3. `isDraft` and
`draft`. 4. PR owner and `live` from `gitBranch`. 5. Activity counts every file
under `<sid>/`. 6. `spawned by session`, and the agent file counts. 7. No pipe
into an early-exit grep. 8. The split: `lib/inventory-items.sh`. 10. Flags
joined by spaces. 11. Record time, `blocked` from the pending call, newest by
activity. 12. `landed` needs content. 13. Content rule 5. 14.
`log.showSignature=false`. 15. `isCrossRepository`, forks, a PR headed like the
default. 16. `cover default` fetch age and resolved ref. 17. `CLAUDE_CONFIG_DIR`.
18. The small contract holes: exit 1 with no scratch, shallow clones, `ssh://`
ports, the 20000-file cap said, the 120-byte transcript cut, the complete-record
rule. 19. The view's comment.

**Reconciliation.** `build/reconcile.md` lists every assertion in the branch's
own section that was changed to follow the settled spec, and why. Round 1 changed
34 (25 directly, 9 through a helper): seven columns to eight, D3 to `cover` rows,
the header regexes. Round 2, after the review, made the two weakened ones strong
again, corrected A36, A37, A38 (a lookup that took a row from the clone), A65 (a
window of 30 characters for a 28-character clause) and A91 (a fixture of 205
KiB for a 256 KiB window) and added RV1-RV12. No assertion was deleted: the
`ok|is|has|bad` lines are 2595 at `b634bb29`, 3047 at `385f6f8d6`, 3059 on the
branch before main was merged in.

**Red-first evidence and mutants.** `build/red-evidence.md`, per row. Against
the original libraries (`b634bb29`, byte for byte) the inventory sections ran
248 ok and 128 FAIL with the assertions of `385f6f8d6`, and with the final
assertions 253 ok and 135 FAIL. The new engine runs 388 ok, 0 FAIL, one skip
("mktemp -d ignores TMPDIR" on this machine). The early-exit-grep lint was red
at `lib/inventory.sh:155` and is 20 ok. Eleven one-line mutants of the new
engine were each killed: the staged-revert call (6 red), the shared-branch note
(3), record time as mtime (3), blocked from mtime (1), the whole-line rule (1), the
owner by any record kind (1), by file time (2), the owner's live from the head
record (1), the 120-byte cut (1), rule 5 ignoring a listed PR (1) and the view's
comment (1). Untested, by name:
- row 18's exit 1 with no scratch (RV11) was never red: the code already held it;
- row 18's 20000-file cap (RV12) is red at `b634bb29` only for the column;
- row 19 (RV9) reads a comment, and cannot tell a different wording that
  misdescribes the readers;
- row 12's `unproposed` second clause has no mutant, and the spawning agent's
  description has no long-text assertion of its own.

**Rulings of 2026-10-02 (the build session; spec design is Felix's, so they bind).**
- **R1.** A merged PR's head counts for section 4.3 rule 2 only when the PR's base
  is the default branch. The first gh call asks for `baseRefName`.
- **R2.** A branch whose upstream is `[gone]` counts as not pushed and says
  `upstream <name> is gone`. Under gh, `unproposed`'s second clause applies with
  or without a remote-tracking ref.
- **R3.** Whatever a reader could not read is said, and the value it would have
  decided is unknown, never absent or landed (section 5.2).
- **R4.** A chip proposed before the mtime of any unreadable session file
  anywhere under the records root is `unknown:chip-unstarted`. The `chips` cover
  row then says `<u> session files could not be read`, counting the unreadable
  files later than the oldest proposal. Built at `44dcce193`
  (`felix_inv_host_chips` looks at every record directory; the chips are read
  before the cover rows, `_fi_chipsread`). The main fixture's mode 000
  `wt-unread` file is now older than every proposal, so the five assertions that
  pinned the narrow reading keep testing the decided path.

**Review rounds.**
- Round 0 (`build/review.md`): the implementation had not run; 18 blockers, all
  fixed in the first build.
- Round 1 (`build/review-final.md`): B1-B5, each reproduced by a fixture; fixed
  under R1-R3 at `226ebba88`.
- Round 2 (`build/review-round2.md`): B1-B5, R1 and R2 confirmed. Three more
  R3 blockers: an orphan directory the run cannot enter read landed (B6);
  an unreadable session file decided live, a PR owner, a chip and a record
  directory's answer (B7a-d); `git log -g` skipping a missing reflog commit with
  status 0 (B8). Fixed at `c24113e97`.
- Round 3 (`build/reconcile.md`, round 3; `build/assertion-audit.md`): the blind
  author ratified the implementer's edits to A26, A36, A37, A38, A65 and A91
  and ruled on section 4.6's count. No assertion was deleted.
- Round 4 (`build/reconcile.md`, round 4): the blind author read B6, B7a-d and B8
  against the spec and ratified every one, and added R4a-b and G1-G4.
  `build/disputes.md` 1 was ruled (R4) and built.
- Final check (this update): the diff `c24113e97..44dcce193` conforms to the spec
  and R4. The round-2 fixtures v3, v5 and v7 read as the review asked at HEAD;
  v4 does too in a fresh records root (the shared one holds earlier runs' copies
  of its starting session, which start its chip). No engine defect found.

**Mutants.** `build/mutants-round4.md`: one or more mutants of every fix since
`a2f45582`, 50 in all. Round 4 killed 29. The 21 survivors (assertion gaps, two
defences backing each other, and R4d, which round 4 misread as equivalent) are
each killed by an assertion in the new M4 block of `tests/run` (`3702e4b93`):
every one red on its mutant, green on HEAD, with a control run. A stand-in git
fails the three reads no fixture can (a file deleted mid-scan, a walk that dies,
a reflog read that dies). M4-CDPATH carries the `.git` decoy that
`build/disputes.md` 2 asked for; G2 is unchanged. **50 of 50 killed.** No
existing assertion was edited. The M4 assertions are not blind.

**Final counts** (section runner, bash 3.2.57, `nice -n 10`, engine of
`44dcce193`, tests of `3702e4b93`): the four inventory sections 455 ok, 0 FAIL,
one skip ("mktemp -d ignores TMPDIR" on this machine); the two library lints
22 ok. Libraries: `inventory.sh` 443, `-host` 484, `-items` 212, `-orphans`
187, `-gh` 103, `-view` 58.

**Open.**
1. Spec section 12: `CLAUDE_CONFIG_DIR` is taken from the documentation, not
   observed; the owner scan's CPU is not measured; the owner rule has not been
   walked over the 20 open felix-home PRs; the ask rule's recall (0.800) is
   from its tuning set.
2. Reftable: the staged-revert shortfall check counts lines of the reflog file,
   so under a reftable backend it has nothing to count and a skipped reflog
   commit reads as before the fix.
3. Conservative by design: one unwalkable merged head makes every tip it does
   not reach `unknown`; any unreadable file newer than an owner's record makes
   every PR owner unknown; an unreadable record directory anywhere under the
   root makes every chip unknown.
4. The M4 block (and B6-B8 before ratification) was written by the build
   side, not blind; the blind author may read it.

**Carrier.** This branch changes neither `tests/assertions.tsv`, `tests/red.tsv`
nor `engine/.claude-plugin/plugin.json`. The carrier runs `--record-assertions`
(the M4 assertions are new), the version bump and `felix gate` at its slot. No
gate, whole suite, `tests/red` or install was run here. Main (`ea865e821`) is
merged in and touches no inventory file.

Next:
- The carrier lands this on its slot, taking `--record-assertions`, the
  `plugin.json` bump and the gate then.
- The founder reads rule 5's partly pushed tip and the view's duplicate clause
  above, and says if either is read the other way.
- At landing, measure the owner scan's CPU and walk the owner rule over the open
  felix-home PRs (section 12 items 2 and 3).
