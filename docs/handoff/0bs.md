### 0bs. 2026-09-22/23 — Felix is a product for other people's projects, built first; the first obligations request answered blind; the roadmap

**No engine change from this session.** Records and doctrine only. The engine
moved to 0.49.142 and 0.49.143 through other sessions' pull requests (#289,
#292) while this one ran.

| PR | What |
|---|---|
| #290 | Constitution: Felix is a product for other people's projects, built first on Claude Code; the Phase-1-only scope is replaced |
| #293 | `docs/2026-09-23-roadmap.md`, replacing direction-decisions §5's queue |
| this | The roadmap revised to build first, and this section |

**Founder decisions, 2026-09-22/23:**

- Felix is a product for other people's projects (#290): Claude Code first
  and best, host-independent by design, a second host once Claude Code is
  right. The name stays for now, the IP is his, pricing is deferred, and both
  planes stay.
- **Build first (2026-09-23).** Real obligations and working machinery come
  before anything else; commercialisation is a natural outcome of Felix's
  quality, not a goal. No outreach track and no user deadlines. The roadmap
  was revised the same day to say so.
- The Capability Plane is not "call an agent API". Labour (Claude, Codex,
  Factory) is one commoditised provider class, consumed on the customer's own
  key; the distinct core is qualifying the evidence providers (observers and
  checkers) and deriving needs from standing obligations. Integration order:
  merge-point check, then ride-along adapters, then dispatch.
- Approved: the obligations request by hand on Elenchus (done, below) and the
  qualified-judge slice (roadmap Phase 1). No row is armed before control 7
  and the judge pin exist; the chat plan of 2026-09-22 said new rows would arm
  at once, and the roadmap records that correction.

**Queue item 4a, done 2026-09-22.** `felix obligations --request` ran on a
scratch clone of Elenchus at origin/main `a45a985`, with `.[dev,web]`
installed so `http_route` read found (16) rather than blind. A Plan subagent
answered it: that type loads no memory, so it was not primed by the session's
talk of rate limiting. The answer was written verbatim to
`~/.felix/memory/elenchus/commission/obligations_surveyed.tsv` and read back
by `felix obligations`: 7 proposed, 7 accepted, 0 refused, 0 admitted
(`candidates.tsv`, 7 rows, epoch `5d2d7b05`). Six of the seven evidence
commands fail on main. `public_bind_has_spend_ceiling` is LeavesJ/Elenchus#16,
open since 2026-09-03, and `app.py:74` names it, so this is calibration, not
recall. The other five are unverified against what Elenchus already records.
Admission waits on the founder. The scratch clone does not outlive the session.

**Records.** Memory: `felix-is-a-commercial-product`,
`agent-vendor-access-and-terms`, and the market map's 2026-09-22 delta:
Factory's 2026-08-27 post states the inventory-plus-current-evidence thesis
for next-generation Missions, Claude Code Projects redesigned on 2026-09-17,
and Anthropic's Agent SDK terms for products. The founder has PDFs of the
positioning continuation and of both roadmap versions; their Markdown was
scratch, so the repository's roadmap is the source.

**Open, in roadmap order:** Phase 0 of `docs/2026-09-23-roadmap.md`. Live in
other sessions: the table validator on `claude/table-validator`, and
qualification hardening in `happy-snyder-20f100`, which touches
`lib/qualify.sh`, so the judge work waits for it. PR #291 is red. Carried from
§0br: deny rows reading heredocs and quoted text (roadmap Phase 0), and the
harvest rows (Phase 4).

**Traps paid for this session:**

- A gate receipt belongs to the tree, and committing changes the tree even
  when no content does. Gate after the commit.
- `origin/main` moved twice mid-work. Merge it into the branch rather than
  rebase (a force-push is refused), then gate again.
- Running probes in another project moved this checkout's grounded facts, and
  the Stop hold asked for a fresh gate on an unchanged tree.
- `felix merge` takes no pull request number; it merges the checked-out
  branch.
- A discovery answer must not come from the session's own model once the
  session has discussed what it expects to find. A Plan subagent loads no
  memory.
- The request records probe state as last read. Install the product's extras
  first, or `http_route` reads blind.
- Headless Chrome with a fresh `--user-data-dir` writes the PDF and then
  hangs. Bound it and check the file.
- In zsh a bare word starting with `=`, such as a line of equals signs passed
  to `echo`, is an expansion error.
