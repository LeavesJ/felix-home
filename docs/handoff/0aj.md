## 0aj. Verified at session close, 2026-08-31 (day) — the correction that matters is about method, not code

Each line produced by a command. Newest first under §0. §0ai holds the night;
this holds the day, and the day's most important output is not a merge.

| | |
|---|---|
| head | `a60653b` on `main` (#125), CI `gate` **success** |
| deployed engine | **0.49.38**, cache live at 0.49.38, gate `installed ok` |
| suite | **1100 assertions**, from 1076 |
| merged today | #122, #123, #125 — all on green CI |
| open issues | **9**; open PRs | **1** — #124, deliberately held |
| decisions record | 4 mandates, 2 declined on the record |

### Read this first: build the class, not the instance

The founder's correction, and it is standing direction rather than a note
about one feature. When they name tools — semgrep, sentry, strix — or ask
"which MCP, which skill", they are giving **examples of a class**. The thesis
is a mechanism that decides what procedure runs at a lifecycle moment and
selects dynamically. Wiring the three tools they happened to name is
implementing the example and missing the point.

The measurable proof, and it is embarrassing in a useful way: handed a
security audit with five findings, this session built `felix preflight` with
checks for the two that were mechanizable and **silently dropped the third**,
a missing request ceiling. Not because it was hard — because there was no
table of what a deploy moment must answer, so nothing could report a question
that had gone unasked. Felix already had that pattern one file over.

Recorded in `lessons.md` and in the session memory as
`build-the-class-not-the-instance`. When the founder is scoping, answer at the
level of the class: what is the moment, what must be answered at it, what
selects the answer — before writing any check.

### What that produced: `felix procedures` (#125)

The frame, and the rule it exists to obey:

> **Felix may hold stances. Felix may never author the enumeration.**

`lifecycle.tsv` does not work because somebody wrote a good list. It works
because `felix_coverage_events` reads what the *platform* binds, the table
holds only stances, and the gap is `reality − table`. That is why it named
SubagentStop without anybody thinking of SubagentStop.

So items come from what the checkout **has** (detected off the tree) and what
has actually **bitten** (the distinct checks in `mistakes.log`). A stance says
at which moment an item is answered and by what — judgement, arguable,
authored by a person. **An item with no stance is the product.**

Live, with no stances taken anywhere: **6 of 6** unanswered for this project,
**9 of 9** for veldra. `capability:deploy` appearing unanswered is the shape
of the original miss.

### The review found this design's own defect inside the fix

Worth reading before trusting any surface built this way. Four red:

- **A row that recorded no judgement still closed its gap** — and every
  display path keys on the moment, so it rendered nowhere. One item vanished
  from the gap list, the stance list and the unknown-moment list at once while
  the report said everything had a stance. The surface built to report gaps
  had a class of gap it could not report.
- **The same sentence half-applied**: a stance at a moment nobody declared was
  reported as unknown *and* still counted as an answer.
- **The enumerator was not reading reality.** Items came from the curated
  `capabilities` file, not `felix_detect`, which made the file's entire thesis
  false for half of it.
- **Orphan stances** — a claim about a surface that is gone — were invisible.

All fixed. The lesson generalises: a design that cannot report its own gap is
an instance wearing a system's clothes.

### The other two merges

**#123 — Felix's top recommendation was built on evidence it manufactured.**
`felix next` ranked "the gate caught `installed` 20 times, the lesson is not
working" first. Measured: **16 of 20 rows are on feature branches** and **18 of
20** are runs where `installed` was the only failure — work in progress, not
mistakes. The engine already subtracts failures a gate marks
`FAIL (structural: …)`, which is issue #3, fixed once. **#115 dropped that word
yesterday** while improving the message, so every worktree failure recorded
again. The word is back, the evidence is kept, and the contract is now pinned
by an assertion that renders the shipped gate's own format — the three existing
tests used a line the fixture wrote itself, which is why the rename was silent.

**#122 — Decision C had not moved its number.** Measured the morning after
shipping: 0 of 35 plugins matched for this project, 4 of 35 for the widest.
The matcher was never the bottleneck; `_felix_discover_rules` iterated the
*table*, so a capability nobody wrote a row for contributed nothing. One
governed project declares `security`, the table has no such row, and every
security plugin was invisible to it. Now 4 → 6 and 0 → 1, every new match
correct. Its own review then found the `iac` row this PR added created the
table's first keyword tie, handing tie-breaking to a hand-edited file.

### Standing, and what is genuinely open

- `tests/run --record-assertions` after any assertion change; **1100** on
  record.
- **#124 is held, not abandoned.** Its review confirmed 6 red, worst being that
  `http.server --directory ~` serves the whole home to the LAN while the
  command prints "Nothing exposed". The listener and mode mechanisms are sound
  and tested; they become **two stances**, not a command.
- **The stances are the founder's.** The enumerators are wired and the gaps are
  sayable; naming what answers them at `pre-deploy`, `session-start`,
  `pre-conclude` and `post-incident` is scoping nobody should do alone. That is
  where this session deliberately stopped.
- **Nothing schedules the pulse.** `felix pulse --install` is the grant and no
  session may make it. Backup is current and restore-verified (`88f573e` on
  both sides), but only because a session typed the command.
- **Three reconcile proposals still stand** — `Claude_Browser`, `ccd_session`,
  `plugin_playwright_playwright`, all host-provided. Leaving them unacted is a
  legitimate answer and session-start will not raise them twice.
- **#58 was re-measured, not closed.** "0 of 34" was measured on *this*
  project, where it is the correct answer — felix is a bash harness with two
  surfaces. The remaining substance is table content, with a per-project metric.

### What this session got wrong

Three, all recorded rather than buried. **I merged #125 before CI reported on
its final commit** — `gh pr checks` said "no checks reported" and I read that
as permission; the run was still in progress on `main` afterwards. It passed,
which is luck rather than process, and it is now a lesson. **I destroyed my own
uncommitted work** with `git checkout <branch> -- <paths>` while rebranching,
and redid it. And **a review agent left a fixture directory in the worktree**
despite being told not to; it was inspected before removal.

