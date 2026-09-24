### 0bx. 2026-09-23/24 — every stuck PR triaged, why the night went stale, and the landing actor designed (not built)

**No engine change from this session.** It read, measured and wrote documents.
Everything it produced is under `~/.felix/memory/felix/audits/` (memory root,
outside iCloud):

| What | Where |
|---|---|
| The founder's queue: everything the sessions left for him, from where each stopped, with commands, re-checked against the state at 19:06Z | `2026-09-23-founder-queue/pdf/founder-queue.pdf` |
| Root cause of the stale-merge night, 17 pages, three reviewers, evidence E1-E20 | `2026-09-23-merge-staleness/pdf/why-merges-went-stale.pdf` (+ `evidence.json`, `reviews.json`) |
| Landing actor design, **draft**: three designs, three judges, a synthesis; the skeptics and the final revision did not run | `2026-09-23-landing-actor/design-synthesis-DRAFT.md` (+ `designs.json`, `judgments.json`) |

**The root cause, in two lines.** Nothing in Felix lands a PR outside a live
chat session, and a PR's readiness (version, red.tsv, manifest, gate receipt)
decays with every merge and every deploy. Of the 7 PRs stuck at 17:45Z, 2 needed
the founder on substance (#309, #311), 2 by rule or hold (#310, #304), 3 not at
all (#308, #312, #315); 51% of commits and 48% of CI minutes were catch-up, and
0 of 7 CI failures were functional. Memory: `merge-staleness-rca-2026-09-23`.

**The founder said "go" to the landing actor** (the report's rank-1 remedy) on
2026-09-23. The draft design: a launchd agent runs `felix land --tick` every
five minutes in its own clone, re-executes as main's accepted engine, takes the
oldest ready PR, merges main in, writes main-relative files from a declared
`land.tsv`, gates the merged tree with main's engine as judge, runs `felix
merge`'s unchanged boundary, checks the landed tree is the gated one, deploys,
verifies and reverts. No model inside it. Build plan L1-L10 (about 10 sessions
plus 3 shadow days); L1 (dry runs write nothing, every refusal logged) and L2
(bookkeeping at landing time, `_rtn3`/`_rtn4` skip untouched files) pay off
before the actor exists. His decisions F1-F5 are in the draft's §12: F1 (build
order, a roadmap edit) is direction-level under #319.

**A carrier session is landing the no-escape queue** (task_d9dbaf89, "Carry the
no-escape felix-home PR queue serially"): #315, #308 then #309's rebuild, #312
and the snapshot, #267 (closing #265), efcfe13, closing #124, then #310/#311/#309
green for one founder decision. Read its session before touching any of those.

**Next:**
1. Finish the design: run the safety, mechanics and plan skeptics on the draft,
   then the final revision (script:
   `~/.claude/projects/-Users-a14808-Documents-Felix--claude-worktrees-recent-prs-commission-check-1429ca/edb8e650-6a60-467f-aa31-366db70e74e9/workflows/scripts/landing-actor-design-wf_a6cea05a-7ac.js`;
   its phases after Synthesize can be run with the draft as input). Check the
   draft against bd740748, which moved restart-moments 1a to the end of Phase 0
   after the draft was written. Render the PDF, put F1-F5 to the founder.
2. Build L1, then L2, one PR at a time behind the carrier's queue.
3. The founder's open items are the queue PDF's §1-§4; the most blocking are the
   Elenchus `felix commission` (#17 and #19 wait on it), Elenchus #22, and one
   yes/no on #309/#310/#311 followed by `felix autonomy --allow commission`.

**Traps paid for this session:**

- The session ran far past the ~500K restart line (memory
  `session-lifetime-measured-2026-09-21`) because nothing checked; the founder
  had to say so, and the process restart killed a running workflow. A long
  orchestration session should check its size at each workflow boundary.
- `felix merge --dry-run` writes an `escalated` row to says.log when an escape
  is present, before it checks `--dry-run`. This session's triage wrote about 19
  of them on 09-23 between 17:38Z and 18:52Z; they are not founder interruptions.
- Workflow agents that make scratch worktrees register them in the shared repo,
  with local branches that track real PR branches. Remove them when done (this
  session removed 23).
- Python-markdown needs a blank line before a list, four-space nesting, and no
  fenced block inside a list item (it collapses to inline code). Check `<pre>`
  counts before sending a PDF.
- Resuming a workflow is same-session only; across a restart, read its
  journal.jsonl (`result` records) and restart from the last completed phase.
