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
  (`inventory.sh` 442, `-items` 188, `-gh` 103, `-orphans` 187, `-view` 58,
  `-host` 496).

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
- **R1.** Section 4.3 rule 2 counts a merged PR's head only when that PR's base
  branch is the default branch's short name. The first gh call adds
  `baseRefName`. A PR merged into another base proves nothing about the default
  branch, so its tip falls to rules 3-4. A listing with no base counts for nothing.
- **R2.** A branch whose upstream is `[gone]` has no remote copy: it counts as
  not pushed, and its detail says `upstream <name> is gone`. Under gh, the second
  clause of `unproposed` (the newest PR merged, commits after) applies whether or
  not a remote-tracking ref exists.
- **R3.** Anything a reader could not read is said and makes the affected value
  unknown, never absent or landed (section 5.2). It covers orphan files and
  directories, missing commit objects, the staged-revert check, the pending
  listing and session files and directories.

**The review rounds and their blockers.**
- **Round 0, `build/review.md` (b634bb29..385f6f8d6).** The implementation stage
  had not run; 18 blockers, 14 in the code and 4 in the tests. All fixed in the
  first build; none was judged wrong (`build/review-disposition.md`).
- **Round 1, `build/review-final.md` (b634bb29..a2f45582).** Five blockers, each
  reproduced by a fixture (f2, f4, f7, f8, f9): B1 the auto-memory directory made a
  worktree live and hid its uncommitted work; B2 an unreadable orphan file read
  landed; B3 a missing commit object made a healthy branch landed; B4 no
  `unproposed` without a remote-tracking ref; B5 a PR merged into a stacked
  branch landed its head. Tests written blind (`41e0cd205`), fixed in `226ebba88`
  under R1-R3.
- **Round 2, `build/review-round2.md` (a2f45582..226ebba88).** B1-B5 and R1, R2
  confirmed fixed. R3 was only partly implemented; three more blockers, each
  reproduced and each with no assertion:
  1. An orphan directory the run cannot enter read content `landed` and counted
     as holding nothing unique (`ls-files` status lost in a pipe). Now a failed
     listing is one file that could not be read, in the first and the ignored
     pass; content unknown. Test B6.
  2. An unreadable session file still decided what it could not: (a) `live` from
     its mtime, (b) a PR's owner from an older readable file, (c) a chip it may
     have started held as `chip-unstarted`, (d) a record directory the run could
     not enter read as no session. Now an unreadable file has no record time: its
     mtime orders it but is no activity, so `live` is `unknown` unless a readable
     file makes it live and the owner is `unknown` when it is the newest; a PR
     owner is `unknown` (with `unknown:live`) when an unreadable file is newer
     than the owner's record; a chip proposed in a record directory holding an
     unreadable file modified after the proposal is `unknown:chip-unstarted`
     (narrower than the review asked, see the dispute below); a directory the run cannot enter answers unknown
     throughout and is counted in the `sessions` cover row. Tests B7a-d. The
     chips adapter line is now `id session epoch flag title`.
  3. `git log -g` skips a reflog entry whose commit is missing, with status 0, so
     a staged revert read as no hazard. Now fewer entries printed than the reflog
     file holds is a tip not read: `unknown:hazard:staged-revert` unless a revert
     was found. Test B8.
  No blocker was judged wrong. One disagreement is in `build/disputes.md`: the
  review's strict reading of 2c (any unreadable file under the root, modified
  after a proposal, makes the chip unknown) made five existing assertions fail
  (the main fixture's mode 000 `wt-unread` file sits in a record directory of its
  own and is newer than the chips of `wt-squash`; they pin those chips as
  unstarted). No assertion was edited; the build keeps the unreadable-file rule
  to the directories that hold a proposal, which fixes the reviewer's fixture
  (v4) and leaves those five green. The blind author rules which reading stands;
  switching to the strict one is a one-line change in `felix_inv_host_chips`.

**The blind-side audit and its ratifications.** `build/assertion-audit.md` read
the tests against the spec alone and found three assertion blockers (A37's
unfiltered lookup, the `--no-gh` view's count, RV12's `k of 20000`); the blind
author ruled on §4.6's count (both `k` and `n` are over the 20000 read) and
ratified the implementer's edits to A36, A37, A38, A65, A91, A26 and the
undecided-row order check (`build/reconcile.md`, round 3). No assertion was
deleted. This round edited no existing assertion: B6, B7a-d and B8 are new, in
the blind section. They were written from the reviewer's fixtures and its
stated expectations, by the implementer of the fix and before the fix, so they
are not blind in the sense the earlier blocks are; the blind author should read
them. Each has a control run in which the same fixture is fully readable.

**Red-first evidence for the new blocks.** At `226ebba88`'s engine the inventory
sections run 407 ok and 9 FAIL: B6 (2), B7a (2), B7b, B7c, B7d (2) and B8,
each for the defect it names, while the four control assertions (B7a read, B7b
read, B7d read, B8 objects present) pass, so the fixtures hold what they say.
At the fixed engine: 416 ok, 0 FAIL and the one skip ("mktemp -d ignores TMPDIR" on this machine), the lint lines (A109-A112) among them. No mutant of the three new fixes was run; the
orphan fix, the reflog count and the `um` comparison in the chip and owner
scans are each covered by one assertion only.

**Open from spec §12, unchanged.**
1. `CLAUDE_CONFIG_DIR` is taken from the documented variable and not observed.
   The mock-API host measurement can confirm where records land.
2. The owner scan reads every in-window session file for `gitBranch`, beside the
   chip scan. Measure CPU, not wall, at landing.
3. Whether the owner rule names the right session for each of today's open
   felix-home PRs has not been walked by hand: do it once, on the 20.
4. The ask rule's recall (0.800) was measured on the set it was tuned on.

**Open from the second review and the rulings.**
5. The chip dispute above (`build/disputes.md`): the blind author's ruling on
   an unreadable file in a directory that holds no proposal.
6. B6, B7a-d and B8 are not blind: the blind author reads them.
7. Conservative by design, not bugs: one merged-PR head whose history lacks an
   object makes every tip not otherwise reached read content `unknown` (a healthy
   never-pushed branch then reads `unknown:unpushed`); the gone-upstream element
   is left out when the content is landed; any unreadable file newer than an
   owner's record makes every PR's owner unknown, since which head it names is
   unknown; the `chips` cover row says `read` and only the `sessions` row says a
   file could not be read.
8. The staged-revert shortfall check reads the reflog file, so it has nothing to
   count under a reftable backend, and falls back to the old behaviour there.

**The record and the version are taken at the carrier's slot.** This branch
changes neither `tests/assertions.tsv`, nor `tests/red.tsv`, nor
`engine/.claude-plugin/plugin.json`. The carrier runs `--record-assertions`, the
version bump and the gate when it takes its slot; no gate, no suite run and no
install was run here, only the section runner over the inventory sections and the
lint section, each under `nice -n 10` (the section runner, `build/runner/mk2.sh`,
over a copy of the engine; about 23 minutes a run here). Main (`ea865e821`) is
merged in and touches no inventory file. Final run on this branch's engine:
416 ok, 0 FAIL, one skip, each of the six libraries under 500 lines (`-host` 496).

Next:
- The carrier lands this on its slot, taking `--record-assertions` and the
  `plugin.json` bump then.
- The founder reads rule 5's partly pushed tip and the view's duplicate clause
  above, and says if either is read the other way.
- At landing, measure the owner scan's CPU and walk the owner rule over the open
  felix-home PRs (§12 items 2 and 3).
