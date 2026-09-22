## 0ap. Verified at session close, 2026-09-05 (overnight) — the measurement audit is closed, and one of the findings I closed it with was false

| | |
|---|---|
| head | `main` (#181–#198, eighteen merges), CI `gate` **success** on each |
| suite | **1611** passed, 0 failed, manifest re-recorded |
| deployed engine | **0.49.95**, read from the manifest rather than remembered |
| the 2026-09-04 measurement audit | **closed** — 4 high (§0ao), 8 medium, 2 low |
| v3.2 amendments §6, the residual | **stated**, on three surfaces |

### The correction first

I shipped a design decision built on a measurement that was wrong, caught it,
and reversed it inside the same night. It is the most useful thing here.

Measuring `grep -vc '^$'` over `routes.log` returned 0 for a 394-line file. I
concluded real `grep` mis-counts logs holding high bytes, rewrote a counter as
`awk`, and wrote an assertion for that property. The assertion passed against
the very implementation it was written to catch. I proved the harness around
it was sound by poisoning the function body and watching it fail — which left
the premise as the only remaining explanation.

**The shell behind my Bash tool defines `grep` as a function wrapping
`ugrep -I`**, which silently skips any file it reads as binary: empty output,
exit 1. It shadows `find` with bfs too. `/usr/bin/grep` counts `routes.log`
correctly, at 394, identical to `awk`. The engine runs under
`#!/usr/bin/env bash` and gets the real binaries, so the measurement was never
about the engine — it was about my shell.

The assertion is gone rather than shipped, and the comment that recorded the
false measurement now records what happened. `awk` stayed, on the smaller and
true ground that it does not depend on which `grep` is on `PATH`. This is §8's
sixth variant — *the place it ran was not the place it mattered* — and it
arrived twice more the same night, below.

### What the banner said before, and what it says now

The single clearest measure of the night. Every line a session reads at start
is now a claim the data supports.

Before, one sentence with a denominator nothing checked and a verb nothing
read: *"Mounted every session and never once reached for: semgrep"*. Now:

```
Pointed at and never once reached for:
  code-review — pointed at in 63 of 66 sessions, named 8 times, never reached
Partial: 1 session(s) have calls on disk that no fold accounts for...
The record proposes changing what is mounted: declare:context7 declare:playwright
```

`code-review` is a finding that was **invisible before tonight** — its zero was
being filled in by a different provider's reaches. `declare:` is a row a person
can actually write. The `Partial:` line is this session, correctly.

### What closed

1. **#181 — the page's totals count the file, not the window.** "Things said"
   read 60 over a log holding 774; "gate failures" 20 over 40. The template
   rendered `array.length` over an array the reader had already bounded with
   `tail -n limit`. Five totals now travel beside their windows.

2. **#182 — the retire banner reports the count the filter checked.** The
   filter admits a row at five sessions; the banner discarded that count with
   `cut -f1` and supplied "every session". And nothing on that path reads
   mount state at all, so "Mounted" was asserting something the data does not
   carry. `felix_ledger_sessions` added for the denominator, one reader shared
   with the report.

3. **#183 — a check nobody could ask is said, not dropped.** A cadence-0 row
   with a CHECK fell through to `event` with no root — which is also what a row
   with no check emits — and `felix pulse` kept only `due`. `unchecked` is its
   own word now, and the pulse offers a root to the one project whose checkout
   it can honestly name.

4. **#184, #185 — a fold that stopped keeping up is not a finished fold.** Both
   ledger loops tested whether a fold *exists*, not whether it accounts for the
   file. Two stale folds here, one three days old holding four signals. #185
   then corrected the sentence #184 had just made untrue.

5. **#186 — a server a plugin provides is a plugin row.** `declared` read kind
   `mcp` only, so a project declaring the plugin was told "no row declares it".
   One governed project had the same capability on the mount list for hundreds
   of reaches and the retire list for zero, simultaneously.

6. **#189 — the decisions tracker says what the record holds.** "answered 12 of
   51" was not a rate: `decisions.log` has one verdict, `declined`, and nothing
   writes a row when a mandate is *followed*. The gap collapsed compliance and
   disregard. The disregard half was never missing — the Stop hook's `skipped`
   row — and is now rendered; the rest is named as unwritten.

7. **#190 — a built-in skill is not the plugin that shares its name.** The host
   provides skills unqualified into an identity space where
   `<name>@<marketplace>` reduces to the same string. The donation is what kept
   a plugin off *every* list: retire needs calls at zero, unrouted needs named
   at zero, and the borrowed numbers disqualified it from both.

8. **#191 — silence over a partial record is not agreement.** `felix stack
   reconcile` never folded; the hook could not, and marked what it showed as
   seen. A mount survives folding, an unmount is exactly what folding
   falsifies, so the hook now *holds* the zero-backed half rather than
   suppressing it forever.

9. **#192 — a caveat that cannot become untrue, and a kind that cannot be
   routed.** "Weak while few sessions are recorded" printed identically at
   n=1 and n=66, and was the only thing standing where retire has a threshold.
   And a `marketplace` was being reported as a routing gap `felix next` told
   the reader to wire.

**Verified already closed, no work done:** the "four hand-made probe files
counted as real sessions". #168's ownership gate and the data repair had
removed them. 66 folds, every id session-shaped, plus three `.bak` files the
glob never reads; `perf.tsv` cannot be folded because its mark names a sha this
repository does not contain. Measured, not assumed.

**#188 — graphify refreshed.** 1447 nodes, 1828 edges, 155 communities, health
OK.

### What the gate caught that I would have shipped

Worth more than the fixes. Three times the engine refused its own author.

- **The independence check refused a comment** naming a governed project and a
  marketplace. Invariant 1, enforced on me.
- **`felix merge` refused a two-line wording change** with "anything running in
  every session needs an assertion that would have caught it breaking". Right:
  two sentences a person reads every session had changed, and the only thing
  pointing at either was a source-grep for a function name.
- **Four assertions became machine-dependent** the moment the reconciler read
  the plugin registry under `$HOME` — and one fixture used a server name that
  is a real installed plugin here. They would have passed in CI and failed at
  the desk. §8's sixth variant, third sighting in one night; the fix is the one
  §8 already names, a fixture `HOME`.

### One thing for the founder, not acted on

**The graphify row is due again, and structurally almost always will be.** Its
check is `graph.json` newer than the last commit, so any commit makes it due —
including the commit that records the refresh. Tonight it went `due → ok →
due` within one PR. That is the same defect class as everything above, in a
project table rather than in the engine: a signal that is on almost always
carries no information. It is a project decision, so it is stated rather than
changed. A cadence in days, or a check against the last commit that touched
what the graph covers, would both make it mean something.

### After the audit closed

Four more, from Felix's own ranking rather than from the audit.

10. **#195 — a deployment that is not this tree is found before the gate run.**
    `felix next` ranks the gate's recurring catches and `installed` is the top
    one at twenty-two separate commits, with its own advice being that the
    lesson has outgrown `lessons.md` and the mechanism should be built. The
    lesson is not working because it is advice about an ordering, and what a
    person needs before running the gate is the state. `felix next` now says
    it, guarded to checkouts that are the engine's own source, silent when the
    CLI cannot answer. `felix_deployed_engine` replaces the engine's two copies
    of that question; the project gate keeps its own, because a project gate
    must run without the engine's libraries.

11. **#196 — recurrence is counted in occasions, not attempts.** The same rank
    tells a person to write a lesson, and a lesson generalises across
    occasions. It was counting rows in `mistakes.log`, which is attempts:
    `ecosystem` appeared five times, every one the same branch at the same sha,
    ranked beside `installed` at twenty-two commits. The threshold now reads
    distinct commits and both numbers are reported. **This changes what earns
    promotion, which is a judgement rather than a miscount** — the threshold
    reads `count[t]`, and pointing it back at `runs[t]` restores the old
    behaviour exactly.

12. **#197 — the residual is stated where trust is claimed.** Amendments §6
    ends with an instruction, not a design: state plainly, wherever the system
    reports its own trustworthiness, that one authority writes both the work
    and the judgement, and that an entrypoint never found is never executed. It
    was stated nowhere — once in this file and in no surface Felix prints.
    `felix receipt` now carries it as a field, because the receipt is the one
    that travels to a peer; `felix probes` and `felix coverage` carry it as
    prose. `felix coverage` had no test at all before this, which for a command
    whose subject is "was every moment considered" is the joke telling itself.

### §2 checker qualification: assessed, not started, and why

It is the largest unbuilt piece and this file already says so. Two things
learned tonight that the next session should have.

**Blind authorship (§2.2) is achievable.** It requires mutations authored by
something that has not seen the checker, and a subagent given the obligation in
prose with the checker source withheld is exactly that. It is the one control
that cannot be satisfied by whoever writes the checker, and it now has a
mechanism.

**Arming is a founder decision and it is the blocker.** A report-only
qualification cannot be armed without turning every gate red on day one, so the
mutation runner has to ship with it — and whether the gate refuses on an
unqualified check is a question about how much Felix may block, which no
session may answer. Starting the build without that answer risks a large piece
half-built against the wrong arming model, which is why this session stopped at
the assessment rather than the code.

### For the next session

The ordering that cost three merge refusals: **record the manifest, install,
commit, gate, merge.** `felix install` mutates the tree — it bumps
`engine/.claude-plugin/plugin.json` — so install-then-gate-then-commit leaves
the commit changing the tree the receipt was written for, and merge then
refuses with "no green receipt for this exact tree".

An earlier draft of this section added "install also needs a second pass,
because it bumps after it deploys". That is not true, and it is worth leaving
the correction here rather than the claim. I measured it four times: perturb
the tree, run install once, compare the tree against the deployed copy. Every
run bumped and verified in one pass — the bump branch redeploys and re-checks,
which is exactly what it was written to do. I had inferred a mechanism from a
single incident whose real cause I never established, which is the same error
as the `grep` one at the top of this section, made twice in one night. The
second pass I kept running was superstition, and it cost nothing but it
explained nothing either.

**PR 4 of the commissioning pipeline is still unbuilt**, and §0ao's note
stands: its premise in amendments §1.3 is stale, discovery is already
scheduled, and it is the sharpest trust boundary in the plan. It wants the
founder, not a session.

