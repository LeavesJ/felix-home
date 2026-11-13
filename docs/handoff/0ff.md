### 0ff. 2026-10-27: the founder's decisions of 10-23 to 10-27, and the documents that lived only on this Mac

**Docs only, no engine change (branch `claude/main-picture-2026-10-27`, on
origin/main 69b51a61).** It records five founder decisions made in
conversation in session 758939f7 between 10-23 and 10-27, and it brings onto
main the Felix documents that sat untracked at the home root, in Downloads,
or on unproposed branches.

**Why now.** The founder, 10-27: "i have gotten official access to claude
duet but it won't know the full picture of felix if work that's passed are not
landed in main. Many parts were missing even including important things like
direction decks. In fact check if direction.md sits in main. Claude Duet is
now my CSO it needs to know what's going on". Earlier the same evening: "also
i think a lot of thing we haven't commit yet so many things stayed
local....commit everything to felix home if applicable".

`docs/direction.md` is on main, and so is its PDF. It landed 10-19 (3999c182,
#453), and no branch carries a different copy. It does not yet hold the
decisions below. Under its §10 they bind from this section, and the fold into
direction waits for his yes in its own draft PR.

**Founder decisions, binding from this section.**
1. **10-23, the audit.** Every incomplete or naive design and build in Felix is
   to be found and fixed. He raised it because the gate had been slowing every
   build. The audit confirmed 96 defects in 23 file-disjoint batches. They are
   listed in `docs/2026-10-24-audit-register.md`, with its PDF.
2. **10-24, plan A is approved** (`docs/2026-10-24-reach-checks-design.md`):
   - local checks run what a change reaches, plus the project's essentials;
   - CI stays full;
   - the home advances only on release green;
   - the build follows the design's step order, report-only first.

   The essentials are not a hard-coded list. Felix re-derives each project's
   necessary checks from the project itself: it finds the guards, then breaks
   each one in a scratch copy, and a guard whose removal no test notices is an
   unguarded essential.
3. **10-24, two smaller decisions.**
   - GitHub-issue alerts are allowed. The land job may post one comment per new
     event on one standing issue, and nothing else on GitHub. That widens
     contract G6 for exactly that.
   - felix-home was made private. It had been public since 08-09.
4. **10-25, nothing stalls silent.** A stalled run, agent or test must say so
   where he will see it. Once that holds, the priority is speed per item:
   several PRs landing, and a suite that never sits idle. It came after he
   found most of the audit build stalled ("so many went stalled what
   happened"). The cause was 20 orphaned hang-repro loops with no time limit.
5. **10-26, off-Mac alerts come from github-actions[bot]**, through a
   dispatched `.github/workflows/felix-alert.yml` (option b of the b05
   contract). The b05 review found that a comment posted under his own gh
   login most likely never notifies his phone.
   - The engine side is in audit batch b05.
   - The workflow file is a founder stop, so it goes in one draft PR labelled
     `needs-founder`, together with b01's `gate.yml` timeouts.

**Documents now on main.** All of them were his, or were made for him. None
was edited; each was only renamed by date.
- `docs/reports/`:
  - 2026-08-17, the research brief;
  - 2026-09-21, the Claude Code usage analysis and the control-plane report;
  - 2026-09-22, the product positioning discussion (in Chinese);
  - 2026-09-24, the 48-hour engineering systems report;
  - 2026-09-27, the report collection brief (Markdown, instructions for a
    collecting agent);
  - 2026-09-29, the strategic intelligence note;
  - 2026-09-30, the second engineering systems report, v5;
  - 2026-10-10, the commercial technology radar.
- `docs/decks/`: investor deck v3 (10-14) and v4 (10-19). v4 is current.
  - Row 25 superseded v3's "Trust Plane first".
  - v4's slide 17 still says "Current build focus: Trust Plane MVP"
    (direction §6, his documents).
- `docs/outreach/2026-10-22-linkedin/`: the post and its three figures. It
  was found as uncommitted work in worktree `felix-linkedin-post-2790bc`.
  Whether it was posted is not recorded here.
- `docs/2026-10-24-audit-register.md` and `docs/2026-10-24-reach-checks-design.md`,
  with their PDFs, from `claude/audit-fixes` (gated 10-24 and 10-26).

**Read with care.**
- The radar is AI-generated from news and funding headlines. Three of its
  lines conflict with decided direction, and none of them is adopted: the
  trust-only framing, a go-to-market track, and the category name
  "independent engineering acceptance" (direction §1's rule against
  narrowing Felix, and rows 10 and 17). Its two additions are row 21.
- The v5 report and the strategic note describe the subcontractor test. It is
  approved in principle only (direction §6, boundaries).

**Left out on purpose.**
- The second report's drafts v2 (09-27) and v3 (09-29), which v5 supersedes.
- `handover.tar.gz.age`, which is 0 bytes.
- Two Veldra documents in Downloads, which are another project's.

The copies at the home root and in Downloads are untouched. Once this lands,
`salvage/home-reports-2026-10-03` is superseded: its four reports are byte
for byte the ones here.

**Work that lived only on this Mac, pushed 10-27.** Fourteen worktrees each
held commits or edits that existed nowhere else. Each is now on origin as
`salvage/2026-10-27/<worktree>`, with a `wip(salvage)` commit wherever the
tree was dirty. None of it was reviewed or run.
- Eight subagent worktrees: `agent-a15b8785c910d2bd2`,
  `agent-a6b62cc893ccbe84c`, `agent-aa5026727973f189d`,
  `agent-abcdce6e7a5348484`, `agent-ad44e156157efdd82`,
  `agent-ad4cc59f499274ac9`, `agent-af8f461d31fa6530a` and
  `agent-afc133b4976fdc7cb`.
- Three named ones: `carry-3c-locale`, `felix-linkedin-post-2790bc` and
  `secret-scan-ref`.
- Three workflow worktrees: `wf_09de129d-71a-1`, `wf_6e4f8fea-6c8-2` and
  `wf_c65a24cb-ab3-1`.

`interesting-napier` had live processes and was already on its remote, so it
was skipped. Triage of every unlanded branch and open PR (superseded, passed
and owed a landing, work in progress, or the founder's) is the next step.

**The audit build, where it stands.** The state is in the memory root,
`audits/2026-10-24-audit-fixes/`: `build-state-2026-10-26.txt`, one card per
batch in `resume/`, `combine-followups.md` and the tools. All 26 branches are
on origin.
- Final green and merged into `claude/audit-combined`: b04, b21 and b23.
- Resumed 10-27 as run wf_7f5544ff-988:
  - 15 batches at their round-2 fix;
  - b15 at its round-2 tests;
  - b13 and b30 at review;
  - b17, b19 and b22 finishing their build.

**Not backed up anywhere.** The Claude Code auto-memory folder
(`~/.claude/projects/-Users-a14808-Documents-Felix/memory/`, about 150 notes)
is in no repository, and `felix pulse` does not cover it. Doctrine keeps
memory out of felix-home, so where it is backed up is his question.
