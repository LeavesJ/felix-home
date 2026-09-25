### 0cd. 2026-09-24 — the megabyte-line audit assertion timed by CPU and shown red, then handed to the session that already had it

**No engine change from this session, and nothing deployed.** This section is
all it lands.

The founder asked this session to move "a megabyte line of backslashes,
content blocks or timestamps is read in one pass" (tests/run, the `$RV/perf`
block) from wall-clock time to child CPU, as #337 did for the shifts. A real-home
`felix gate` for #336 had failed on it alone, "took 308s", at a load average
near 266.

The change was built and shown red, then dropped. Session 14718d ("Time felix
audit's other wall-clock deadlines by CPU", branch `claude/eager-gould-9fe705`)
already had this assertion in scope, along with open/huge, r3/hdbig and the
41,400-line one, under one helper, `_au_ms`. The queue carrier chose that
branch, and this session's commit (4b0181ba) was never pushed. The perf
assertion lands with eager-gould, in the carrier's slot after #339.

**Measured here and handed to 14718d:**
- The read costs 0.45 s of CPU, at a load near 50 and near 215 alike.
- Its awk held for 20 s mid-read (SIGSTOP): 22 s of wall, 0.45 s of CPU, and
  the CPU-timed assertion stayed green. The old 15 s wall deadline would have
  failed.
- Two quadratic readers in lib/audit-count.sh each still counted `2 1 0 0`
  and turned a 5 s CPU budget red:
  - results() finding the last `},{` by searching the rest of the line again
    after each one: 26.4 s of CPU;
  - stamp() walking every timestamp the same way: 44.9 s.
- 14718d's own variants agree: 33.7 s and 45.9 s for the same two, and 14.3 s
  for rawcmd() one escape at a time.

**Next:** nothing owned here.

**Trap paid for this session:**
- **Read the session list against the task before starting it.** This
  session built and red-proved the whole change before its first
  `ListAgents`. There, a session named for the same work had been open 11
  hours. It had no commit and no PR, so neither `gh pr list` nor the branches
  showed it. Only its title did. About an hour went on work the carrier then
  gave to the other branch. The founder's own prompt can overlap a live
  session's scope, so match titles before the first edit, not at the slot
  request.
