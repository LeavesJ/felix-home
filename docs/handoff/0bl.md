## 0bl. The session of 2026-09-17/18, whole — what shipped, what waits on one command, and where the next session starts

Written at session close, after §0bi, §0bj and §0bk, which each describe a part
of it. This is the section to read first. The session's instruction was the
founder's "continue felix dev following session handoff and working toward
v3.2 rearchitecture final form using whatever's necessary from felix and ECC",
which is also why ECC's review agents were used on engine changes. Every
claim below and in the three sections under it was handed to read-only
readers before this landed; what they found is at the end, and §0bj and §0bk
were corrected in place because they had not merged yet.

### Where the next session starts

**Main does not carry this section.** §0bj, §0bk and this one live on
`docs/handoff-0bj`, pull request #262, which cannot merge until the founder
re-stamps the commission (below). A session that starts from main and finds
§0bi at the top of HANDOFF.md should read this instead:

```bash
git fetch origin && git show origin/docs/handoff-0bj:HANDOFF.md | sed -n '/^## 0bl\./,/^## 0bi\./p'
```

`SESSION_HANDOFF.md` in the memory root carries the same command.

| | |
|---|---|
| main | `a8ab281` (#261); the home is at it with no tracked changes, and with the ten untracked paths and the old stash §0bh counted |
| deployed | **0.49.121**, byte-identical to main's engine, installed for sessions that start after 2026-09-18T00:40Z. This session's own hooks ran **0.49.117** throughout — a redeployed engine never reaches the session that deployed it — so the Stop hook's new sentence about exceptions has not yet fired anywhere |
| suite on main | **2444 assertions** reached; 2458 on #263 |
| open | **#262** (§0bj, §0bk, this section, two documents, one maintenance record) and **#263** (#260's fix, 0.49.122); gate green and CI green on both trees when opened, and `felix merge` refuses each on the stale commission receipt alone. #124 (preflight, 2026-08-31) is also open and is not this session's |
| filed | #254, #259, #260, #264 — all open; #263 closes #260 |
| branches | this session's five merged branches were removed from origin; `docs/handoff-0bj` and `fix/judge-not-chosen-by-environment` remain, for #262 and #263 |
| public snapshot | `LeavesJ/Felix` at `3091a76`, 2026-09-13; 22 merged pull requests behind, counting from #236 as §0bh did |

### The one command that unblocks everything

```bash
cd ~/Documents/Felix && felix commission
```

#261 added rows to `projects/felix/risk.tsv` and `deny.tsv`. Both are in the
commission's policy tables, so the receipt went stale the moment #261 merged,
and every later merge is refused on it. That is the boundary working, and the
re-stamp is the founder's act: Felix's autonomy grant for commission reads
`[!]`, stamped over an earlier table. After it, a session merges #263 through
`felix merge`, pulls the home and runs `felix install` to deploy 0.49.122,
then gates #262's moved tree and merges it.

### What shipped

| PR | What | Engine | Assertions reached | Red against the base |
|---|---|---|---|---|
| #255 | `tests/red` writes `red.tsv`: this tree's suite against the engine the base ref holds, run from a detached worktree | 0.49.118 | 2383 | 0 of 2383, 25 skipped (the base had no recorder) |
| #256 | the gate's `installed` check asks `felix_accepted_deploy_diff`, sourced from main's own `resolve.sh`, instead of a private copy | 0.49.119 | 2399 | 9 of 2399 |
| #257 | HANDOFF §0bi | — | — | — |
| #258 | the graphify maintenance row keys on code, not Markdown, in felix's table and the template | 0.49.120 | 2399 | — |
| #261 | amendments §3, the scoped exception channel | 0.49.121 | 2444 | 39 of 2444 |
| #263, open | the judge is pinned outside the tree it judges (#260) | 0.49.122 | 2458 | 10 of 2458 |

**The exception channel (§0bj).** A row in `projects/<name>/exceptions.tsv`
clears one admitted TASK_BLOCKING obligation at the task moment and nothing
else, keyed to the ledger line by content hash, with an expiry no later than
the end of the next calendar year. It is read only from
`refs/remotes/origin/main`, never the working tree or a local branch, and
only where the tables and the governed tree share a repository, which today
means Felix governing itself. Any change to the file fires the new
`exception` escape. Two limits worth knowing: a grant revoked on the remote is
honoured locally until somebody fetches, because nothing on the enforcing path
fetches; and felix has exactly one TASK_BLOCKING obligation,
`engine_deployed`, so that is the one thing the channel could clear today.
Felix's own table is empty. The design is
`docs/2026-09-17-exception-channel-design.md`, corrected on #262 for the bar
separator, the anchored `now` and the calendar-year horizon.

**The judge (§0bk).** `FELIX_KERNEL` let a session choose the kernel that
judged its own merge. #263 removes it and has the boundary refuse any judge
that is not byte-identical to main's engine at the base ref. It is not live
until it merges.

### What waits, and on whom

The founder's, in order: (1) `felix commission` in the home; (2) branch
protection on `main`, which the exception channel's deny rows name as the
wall they are the floor of, and which needs GitHub Pro or a public
repository; (3) #254, the moment to re-hash the policy version so comment
edits stop re-stamping, after which the table-header sweep §0bh listed is one
commit; (4) the first real discovery run on elenchus; (5) the public
snapshot; (6) grants for high-risk plugins; (7) #2 step 5; (8) #252.

Felix's, in order:

1. After the commission, merge #263 and deploy 0.49.122, then gate and merge
   #262.
2. The merge boundary reading the Felix home's diff as a second (root, base)
   pair, so the exception channel reaches governed products.
3. Qualification control 7, the coverage report, and an author column in
   `qualification.tsv`, so blind authorship stops being self-report the way
   #255 made the red count stop being self-report.
4. The `granted` count is untested. Its assertion skips on every run because
   the sentence it reads prints only with a candidates section the fixture
   never builds; the suite's "1 skipped" since #261 is that assertion.
5. #264: the prompt hook records the platform's session-summary requests as
   sessions — 56 of them in `says.log` since 2026-09-03 — so the ledger counts
   phantom sessions.
6. #259, the graph row that cannot be both honest and quiet. Whatever it
   decides has to reach elenchus's and veldra's tables too: #258 changed only
   felix's table and the template, so theirs keep the old key. The refresh also
   warned that eight source files produced no nodes and that community labels
   are stale.
7. A verifier confine on the CLI and the libraries deserves a design pass.
   Today a branch that deleted #263's refusal would set no escape, and only
   the ten assertions `red.tsv` records would go red.

### Distance to v3.2

The full table, one row per sub-item of spec §13 and every amendments
section with file and line, is `docs/2026-09-17-v32-distance.md` on #262. It
was measured at `392289d` by a read-only agent and until now existed only in
that agent's transcript. What moved after it: amendments §3 went from absent
to built for the self-governed case, with products the named second
increment. Amendments §2.3 went from "the judge pinned for `felix merge`
only" to byte-verified against main's engine at the merge boundary once #263
merges; the rest of the gate and `felix qualify` still source the branch's
own libraries. The red count is an artifact in the tree. Step 5 (sandbox,
leases, revocation, behaviour receipts) is unchanged and still needs Docker
or a platform that activates a capability mid-session.

### Method, measured this session

- **Blind authorship and review are a pair.** The four engine changes that had
  a blind author (#258's two-row table change had none) got 25, 14, 45 and 14
  blind assertions, which caught one contract deviation in each of two. Three
  design refuters, five code reviewers and two critics found every other real
  defect the session knows of: a local branch forged as main, a tab in an
  evidence line writing the exception column, a colon inside the column
  separator, a date format that ignores `TZ`, a listing that read the wrong
  tree, a merge's exit status lost to a short-circuit. The refuters' findings
  were written into the contracts before the builds, so the blind blocks
  assert them; the reviewers' lay outside.
- **A fixture can model the hole a fix closes.** The self-governing merge
  fixture had a stub engine on main and a real one in the cache, which is a
  doctored judge, and it went red the day the boundary started refusing one.
- **Commit, then gate, then merge.** Lesson 2026-09-04 cost one eight-minute
  gate again, because the route matched was `orient` and that lesson is keyed
  to other words (#29); a second eight minutes went to the squash trap below.
  The same cause made the session write two lessons that already existed.

### Traps, recorded so they cost nothing next time

- The tool shell is **zsh**, and sourcing an engine library into it changes
  what it computes: `"$ref:engine/..."` lost its `e` to a zsh modifier, twice.
  lessons.md had held this since 2026-08-29; it is now noted there as recurring.
- `felix merge` **squashes**, so a branch stacked on another's commits carries
  them again after the first merges. Held since 2026-08-17; noted as recurring.
- **A table edit to `risk.tsv` or `deny.tsv` stales the commission receipt**
  when it merges, and every later merge waits on the founder. Land such an
  edit last in a session, or say at its start that a re-stamp will be needed.
- **Deny rows match command text, prose included.** #261's rows refused this
  session's own regex tests, a heredoc carrying a test block and a lesson
  that named the forged commands. Put such text in a file and pass it with
  `--body-file` or by reading the file.
- **ECC is installed** (2.2.1, user scope, since 2026-09-03). Its fact gate
  stops the first Bash call and the first edit of each file until facts are
  typed into the reply. Its `silent-failure-hunter` and `code-reviewer` were
  among the session's best readers.

### What the readers found in this record

Four readers, one per section, and an omissions critic, all forbidden the
suite, the gate and anything that writes, following lesson 2026-09-16.

| section | claims | true | flagged |
|---|---|---|---|
| §0bi (on main) | 69 | 56 | 13 |
| §0bj | 82 | 72 | 10 |
| §0bk | 58 | 49 | 8 |
| this section, as drafted | 94 | 81 | 10 |

Every false claim was a figure, a count, a date or an attribution; none was a
claim about what the code does. §0bj, §0bk and this section were corrected in
place. §0bi is on main and stands as written; its corrections are these:

- "All three are in #255's second commit": they are in its third, `5aa481b`;
  the second, `28e1175`, is only the version bump. #255's body says the same
  wrong thing.
- "§0bh's third item was to bring the headers to #243's wording": it was the
  second; the third, the red-run count, is what #255 built. #254's body
  repeats the misnumbering.
- "The public snapshot, now eighteen pull requests behind": nineteen at the
  time, counting from #236 as §0bh did; twenty-two now.
- "The judge pinned for `felix merge` only": `felix merge` only half-pinned it,
  since `FELIX_KERNEL` overrode the cache — #260, fixed by #263.
- Stale since it was written mid-session: the heading's "at session close",
  the deployed version (0.49.119, now 0.49.121), "§3 is absent" (#261 built
  it), and the queue that put the exception channel first (done).

The omissions critic found seventeen things no section recorded; each is
folded in above, in lessons.md, or in #264. Two more, for completeness: one of
the seven suite runs behind #263 stopped part way because this session stopped
it to reorder a check, not because it hung; and lessons.md now holds nine
entries dated 2026-09-17 and recurrence notes on three older ones, after two
entries that repeated older lessons were folded into the originals.

