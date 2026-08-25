# Handoff

Rewritten 2026-08-10, late. Read the first section before doing anything. It is
standing direction that has already been decided and should not be re-derived,
re-litigated, or asked about again.

For the mechanical state of the tree — branch, head, uncommitted, recent commits
— run `felix handoff`, which regenerates `SESSION_HANDOFF.md` in the memory root
and therefore overwrites it. Durable prose goes here, not there. That file left
this repository on 2026-08-14 along with the rest of memory; `felix which` will
tell you where it landed.

---

## 0. DECIDED 2026-08-14 — private, and the memory lives outside it

Two decisions in one day, and the second supersedes the first. Earlier this file
recorded "public stays, the memory moves out". **The repository is private
again** — verified by an unauthenticated request to the GitHub API returning
404, not by reading a settings page. It was public for roughly two hours with no
stars, forks or watchers.

**The memory migration stands and was right either way.** It was never only a
publishing fix. A home *is* the checkout whenever Felix governs itself, so
rooting memory under the home meant every governed project's record accumulated
inside a repository that also wants to be shown to people. Taking it out is
correct with the repository private, and it is what makes an eventual release
possible at all. `felix_mem_dir` roots at `$FELIX_MEMORY` or
`~/.felix/memory/<project>`, computed from `$HOME` and never from `felix_home`,
and the gate's `memory` check was inverted rather than deleted — it used to
demand memory be tracked and now fails if any is, which is the only thing that
would notice the old layout returning one project at a time.

**What going private takes back.** The argument for publishing was that clause 3
of the earned-autonomy design needs an *unavoidable* enforcement point, local
bash cannot be one, and a required status check needs a public repository or a
paid plan. Private again means that route is closed and the paid plan is back on
the table — or the enforcement waits. That is a real cost of this decision and
it should be paid deliberately, not rediscovered.

### What is still open

1. **The history holds it and always did.** `git rm` removes a file from HEAD,
   not from the 207 commits behind it. **Recommendation: do not rewrite.** The
   repository is private, and the eventual open-source path is a path filter on
   `engine/` — which structurally cannot carry `projects/` content, because
   those paths were never in the filtered set. Invariant 1 is what makes that
   split clean, and it is mechanically enforced: `tests/run` greps runtime code
   for a project name and fails. A rewrite invalidates every clone and worktree
   to remove a risk the release path already removes.
   One trap for whoever does that release: **a path filter does not filter
   prose.** 21 of the 105 commits touching `engine/` name the other project in
   their messages, and messages travel with commits.
2. **Memory no longer survives the machine, and that has not been decided.**
   Measured at session close 2026-08-14, not estimated: **1.0 MB across two
   projects**, holding `lessons.md`, `ledger.tsv`, `DEVLOG.md`,
   `SESSION_HANDOFF.md`, `mistakes.log` and `verification.log` for each. It sits
   in `~/.felix/memory/`, which is inside a home directory that *is* a git
   repository — with **no remote, and `.felix` tracked in 0 files**. So it is
   not versioned, not pushed, and not backed up by anything Felix can see.

   Carry-over is therefore split: **the next session on this machine inherits
   everything; a session anywhere else inherits nothing.** A disk failure takes
   every lesson this project has paid for, which is the one asset here that
   cannot be rebuilt from the repository.

   **CLOSED 2026-08-18.** `~/.felix` is its own repository with a bare remote in
   iCloud Drive, and the backup was restored and diffed before it was believed —
   see §0a. It had been the top item for two sessions. What is still not decided
   is *when* it runs: nothing schedules it, so it is as current as the last time
   somebody typed the command. The paragraph above is left standing because it
   describes what was true for four days and why it mattered.

## 0z. Verified at session close, 2026-08-25 — the instrument was broken, and every number below it

Each line produced by a command. Read this before §0a, which is now superseded
in its numbers and kept for its reasoning.

| | |
|---|---|
| head | `00664ca` on `main`, 0 unpushed, 0 modified |
| gate | **pass** — 765 assertions, `installed` ok, run from `./engine/harness/felix` |
| engine | **0.49.7**, deployed and byte-identical to `main` |
| open issues | **9** — the four design questions, plus #51 and #55–#58 filed today |
| open PRs | **none** |

Merged today: **#54** (the instrument), **#59** (this section), **#60** (two
route plays). Filed: **#55–#58**.

**Start here, and it is one thing.** Before any conclusion drawn from routing
data is trusted again — including the conclusion this session was heading
toward, that Felix has no routing role — **re-derive the follow-through
baseline.** It could not be measured correctly until today. It needs sessions to
accumulate against the fixed instrument first; days, not minutes. Do not produce
a number before then, and do not let the absence of one licence the old
conclusion.

**Then: #56.** Agreed as the next piece of work, deliberately not started at the
tail of the session that found it. `felix merge` clears every escape channel when
the base ref does not resolve. Write the failing fixture first — a branch adding
an `execute`-channel path, merged with `--base` naming a ref that does not
exist, must be refused and today is not. It is `escape.sh`, so `risk-red`.

**Do not reopen the capability-registry design without reading #58 and its
comment.** Fourteen adversarial reviewers, 124 findings, 32 fatal, verdict
implement-only-after-changes-and-not-the-registry. That is settled until new
evidence, not until somebody feels differently.

### Two routes gained a step, and the engine ships a better table than it uses

`#60`. Both additions came from measurement and both were inert before `#54`,
because a play is a sequence and no play had advanced past its first entry in
months.

- **`ship` gained `superpowers:verification-before-completion`, last.** The
  engine's own `templates/routes.tsv` ships a `release` row naming it. Felix's
  table replaced that row with `ship` and dropped it — so the one capability
  whose entire purpose is *check before you say it is done* was missing from the
  route that fires when somebody says it is done, and the Stop hook has been
  retrofitting it after the fact. Twice in this session, on this very change.
- **`build` gained `superpowers:executing-plans`, third.** Installed, and named
  nowhere in the engine at all — no project table, not the template. The blind
  study found it was the capability wanted on three of the eight applicable turns.

Verified under `bash`, not assumed: with nothing used, `ship` names `code-review`
and defers the rest; once the three review steps have run, it names
`verification-before-completion`.

**The general case is worth a check nobody has written.**
`projects/felix/routes.tsv` and `engine/harness/templates/routes.tsv` have
diverged and nothing compares them. Felix's table dropped `backend`, `frontend`,
`incident` and `release`; the first three are correct — no frontend, nothing
deployed — and the fourth was not. A check that a project dropped a template
route *deliberately* would have caught this and is cheap. Recorded on #58.

### Two mistakes this session made, both caught, both worth the space

Recorded because §8 is a list of exactly this shape and both are recurrences of
entries already in it.

**A fixture that only carried `attributionSkill` would have gone green against a
fix repairing one line of three.** Production writes `attributionSkill` and
`attributionPlugin` on the same line — 1483 such lines for `using-superpowers`
alone, 7137 occurrences of the plugin key. The fixture was rewritten to the real
shape before the fix was written, and the MCP third of the defect was then caught
by *review* rather than by tests, because no assertion reached that branch.

**A test of the play loop was run under `zsh` and reported the whole play as one
step.** zsh does not word-split unquoted parameter expansions; the engine is
`#!/usr/bin/env bash`. Re-run under bash it was correct. This is §8's sixth
variant — *where the test runs* — and it cost ten minutes of believing a real
feature was broken. When a shell-level result looks structurally impossible,
check the shell before the code.

### The instrument was broken, and it invalidates the case against routing

`felix_route_step_used` asked three questions and all three were the wrong one.
The `attributionSkill` line was missing its closing quote, so it prefix-matched
the plugin; the `attributionPlugin` line was correctly quoted and asked whether
the *plugin* ran rather than the *step*; the MCP probe asked it a third time.
superpowers ships `using-superpowers`, injected before anything else runs, and
16 of 23 slots in `routes.tsv` are `superpowers:*` — so from turn one of nearly
every session `felix_route_due` found every step used and **rendered nothing**,
while `felix_ledger_note_named` recorded the play as named anyway.

**152 namings on disk against 37 a session was ever shown.** Every follow-through
figure this project has quoted — 5.4%, 7.2%, "sessions ignore Felix" — was
computed against suggestions nobody was given. Fixed in #54, deployed at 0.49.7.
The number is now measurable and has not been measured. It needs sessions to
accumulate; days, not minutes.

Expect Felix to get **noisier**: ~115 suppressed mandates return on a channel
whose precision was measured at ~2%.

### What was measured, and what it does and does not settle

A blind study over 158 logged prompts — judges shown the prompt and the
capability inventory, shown neither what Felix named nor what ran; two
independent strict judges agreeing 33/33 on the binary question:

- a capability was **applicable on ~5% of turns** (8 of 158; strict judges lower)
- Felix **spoke on 94 of 158 turns** — precision ≈ 2%
- Felix's **recall on applicable turns was 2 of 8**
- **4 of the 8 needed a capability installed but absent from every row of
  `routes.tsv`** — `superpowers:executing-plans` ×3, `verification-before-completion` ×1

So the 43% miss rate is largely correct silence, not failure. And **the evidence
does not support "Felix has no role in routing."** It supports a role roughly an
order of magnitude smaller in volume, currently failing in both directions.
n=8 — directional only.

### The architecture that was proposed and rejected

A capability registry with deterministic retrieval feeding a semantic router.
14 adversarial reviewers, 124 findings, 32 fatal. Verdict: **implement only after
architectural changes, and not the registry.**

The load-bearing finding: **the host runtime already enumerates and retrieves.**
Claude Code puts every installed skill and description in the session prompt
(~6.5k tokens for 105 skills) and ships `ToolSearch` for MCP. A Felix registry
duplicates it from a weaker vantage point. What survived: **the between-sessions
configuration path, which is already built and whose inputs are empty.** That is
#58. Also established: BM25 over real descriptions has high precision on
vocabulary match and near-zero recall without it, and cannot abstain — measured,
not argued.

Do not reopen the registry design without reading #58 first.

### DECIDED 2026-08-25 — the deliberation layer is held, and the gate on it is explicit

The founder proposed a different architecture and then deliberately withheld it.
It is recorded here in full because it is the most valuable unbuilt idea on the
table and because the condition for building it is precise.

**The idea.** Capability *awareness* may be fine — the host already supplies it.
The failure may sit in the middle stages: opportunity recognition, action
selection, execution commitment. So Felix's missing layer may not be routing at
all but **deliberation forcing** — not *"use tool X"* but *"you may not silently
skip the action-selection step here"* — plus **decision-action closure**: an
actionable decision must terminate in an observable state (EXECUTED,
BLOCKED_BY_POLICY, FAILED, SUPERSEDED, ABSTAINED_WITH_NEW_EVIDENCE) and never
in DECIDED_BUT_DID_NOT_ACT. Felix would hardcode the *procedure* and leave the
*semantics* to the model, which is the cleanest resolution yet proposed for the
invariant-2 tension.

**The founder's gate, verbatim in intent: do not think about this until it is
confirmed, repeatedly, that Felix has no role in routing.** That is a change to
the product thesis, not a refactor.

**And that confirmation has not happened. The evidence currently points the
other way.** The blind study says the routing role is real but roughly an order
of magnitude smaller in volume than Felix attempts, and that half its misses were
capabilities absent from the table — two of which #60 has now added. Meanwhile
the follow-through evidence that motivated the deliberation idea turned out to be
measured with a broken instrument, so *"Claude ignores Felix"* was substantially
*"Felix never asked."*

**One structural trap to carry.** The measurement that would justify the
deliberation layer requires building part of it: the only way to observe *"the
agent considered capability X and decided NONE"* is to require that decision be
emitted. So "measure first, then decide" has a floor. The cheap way through is a
**recording-only** version — Felix asks for an explicit consider/decline record,
enforces nothing, changes no behaviour — which is instrumentation rather than
architecture and needs none of the registry, retrieval or routing work.

## 0a. Verified at session close, 2026-08-18

Each line produced by a command, because a status table is the least trustworthy
thing in this repository. The 2026-08-14 version is kept further down, unedited,
because two of its numbers were wrong and the shape of that error is worth more
than the numbers were.

| | |
|---|---|
| head | `83061fd` on `main`, 0 unpushed |
| gate | **pass** — 758 assertions, `installed` ok |
| engine | **0.49.6**, deployed and byte-identical to `main` |
| repository | **private** |
| memory | backed up; §0 item 2 closed. Nothing schedules it — as current as the last time somebody typed the command |
| open issues | **5** — the four design questions, plus #51 |
| open PRs | **none** |
| auto-merge | **5 of 5. `felix automerge` prints "Earned."** Read §0d before acting on that word. |

**Start here.** Nothing is mid-flight and nothing is blocking. The work is §0b,
and its spec now exists at `docs/2026-08-18-promotion-spec.md` — start at that
file's §9, which is an ordered list, and note that its step 1 is already done.

The 2026-08-18 05:43 version of this table is superseded and is *not* kept
below, because unlike the 2026-08-14 one its numbers were right when written.
What it said was: head `b47423d`, #49 open and unmerged, and an engine deployed
from #49's branch that was ahead of `main`. All three were true and all three
are now false. #49 merged as `bbb545d`, #50 as `53b1f61`, and the deployed
engine is `main` again, checked with `diff -rq` rather than assumed.

## 0b. DECIDED 2026-08-18 — issue #2 is "make promotion real", and the spec is unwritten

The direction is settled and the design survived two rounds of stress testing.
**Nothing is implemented.** ~~Next session writes the spec, then implements.~~

**The spec is written**, 2026-08-18, at `docs/2026-08-18-promotion-spec.md`
(#52). Its §9 is the ordered list to work from. Two things in it supersede what
the rest of this section says:

- **The demotion experiment was run, not deferred, and the risk is retired.**
  `claude plugin update` *does* move the live pointer backwards when the cache
  already holds the base's version. `install` does not — it answers `already
  installed` and changes nothing, so anything written to demote must not rely on
  it. `marketplace update` has to come first. The reused cache entry was
  byte-identical to the commit it claimed to be. `felix install` therefore needs
  no demotion path, which was the largest unknown the design carried. Run in a
  throwaway `HOME` against a scratch clone; the machine's own marketplace mtime,
  102-entry cache and live pointer were unchanged either side.
- **A green `installed` will no longer tell anyone which engine is live.** The
  new check certifies the cache entry for the base's version. Installing a
  candidate adds a *different* entry and never touches the one being checked, so
  the gate stays green while a developer's sessions run an unreviewed engine.
  The judge is still correct — `felix merge` reads through `felix_kernel_dir`,
  which reads the cache and not the live pointer — but this is a real narrowing
  and the spec's §8 criterion 2 is the assertion that keeps the original
  "written is not installed" protection alive by relocating it rather than
  dropping it. If that assertion cannot be made to fail, the change is a loss.

**What #2 actually is, at the level worth deciding.** Felix can only be worked
on in one place. The gate red-lights every checkout except the single directory
the marketplace serves, and merge needs a green gate — so the command that ships
work exists in exactly one folder. That is why worktrees are a trap, why
concurrent sessions are a hazard rather than a capability, and why a peer
session can review but never *finish*.

**The change.** `installed` stops asking "is the engine you are holding
deployed?" — a question a secondary checkout can never answer yes to — and asks
"is the deployed engine the one this project has accepted?". Every checkout can
answer that, and #2 dissolves rather than being excused. It is a strengthening,
not a loosening: `resolve.sh` currently disclaims "the trust is that the cache
entry for the base's version is what the base contained when somebody installed
it", and this turns that assumption into a checked fact.

**The blocker round 2 found, which the spec must carry.** The first version of
this design changed only the LEFT side of the comparison and inherited the right
side from today's check — the *live* plugin, or the newest cache entry. Those
disagree the moment anyone runs `felix install` on a branch, which is what the
current workflow demands. The check would have been **green if you skip the
install and red if you perform it**. Resolve BOTH sides from the base, which is
verbatim what `felix_kernel_dir` already computes — so call it rather than
re-deriving. That also closes the loop: the gate then certifies the exact engine
that judges merges.

**Verified, so the spec can cite rather than re-measure.** The check is 56–58ms.
`git archive origin/main engine/harness` is byte-identical to the cache entry
for main's declared version, modes included, and differs from the previous one.
In the live worktree at `aaa60e3` today's check FAILs and the base-pointed one
returns ok — #2 dissolving on real data, not a fixture. And a green receipt is
*sufficient*: with one granted by hand, `felix_merge_blockers` in that worktree
returned nothing at all.

**Untested and required before it lands.** Whether the plugin machinery will
move the live pointer BACKWARDS when the cache already holds the base's version.
Nothing pins a version — the marketplace is a directory source and the version
is read from the served checkout — so demotion is probably just
`git checkout <base> && felix install`, but *probably* is not the standard here.

**Named and not fixed.** `projects/felix/gate.sh` is promoted by nothing: every
worktree runs the served checkout's *working copy* of it, dirty or on any
branch, and it is the file that decides whether Felix's own merges are
permitted. That is an authority-kernel hole and it is larger than #2.

## 0d. DECIDED 2026-08-18 — the streak reads "Earned." and the founder says not yet

`felix automerge` now says this, and every word of it is arithmetically true:

```
streak:  5 of 5 consecutive clean green merges
Earned. 5 consecutive green merges, none of which CI disagreed with.
enable with: felix automerge --enable
```

Look at what it lists underneath. **#8, #14, #18, #19, #52 — every one of them
begins `docs(`.** The unlock exists to test whether a green classification is
trustworthy, and the test is CI disagreeing with one. No green change has ever
touched anything that runs, so CI has never had the opportunity to disagree.
The counter is not wrong; it is measuring a thing that cannot fail.

That it *cannot* fail is structural, not bad luck. `risk.tsv` has three green
rows — `^docs/.*\.md$`, `^projects/[^/]+/maintenance\.log$` and
`^projects/[^/]+/memory/`. Engine work is red by construction. `HANDOFF.md` sits
at the repository root and so matches no green row at all; it falls to the
yellow default, which is why handoff commits have never advanced this number and
why one session predicted they would and was wrong.

**The founder's decision: 5 is reached, and auto-merge stays off until one green
merge touches something that is not prose.** The unlock stops being reachable by
writing documents.

**This is recorded in prose and enforced by nothing, which is the trap.** The
banner above will keep saying `Earned.` and offering the command. This
repository already carries "a status table is the least trustworthy thing in the
repository" as a written lesson, and that lesson failed to fire once already —
§6's auto-merge entry said "still 0 of 5" for four merges and was then repeated
out loud to the founder by the session that read it. A note is what failed last
time.

**So the immediate next work, before §0b:** `felix automerge` should report how
many merges in the run touched anything outside the green documentation rows,
and `--enable` should refuse while that count is zero. `felix_automerge_history`
already spends one `gh` call per PR, so a `gh pr view <n> --json files` beside it
is in keeping. It is `engine/harness/lib/automerge.sh`, therefore **`risk-red`**,
therefore a founder approval and a version bump. Deliberately not built at the
end of the session that decided it — §0a lists three green-but-wrong states
shipped in one week by exactly that impulse.

## 0c. What this session established about how Felix should work

**Concurrent sessions are being built as a capability, not defended against.**
Rungs: peers verify finished work (real today), peers verify designs (real
today), peers hold independent state and hand off (needs #31 and #2), peers do
concurrent work (needs conflict resolution, which nothing here has). Rungs 1–2
are safe because verification only ever *narrows* — a peer can add an objection,
never remove one — so invariant 2 is untouched. Order: **#2 → make hedging
automatic → #31 shared state → rung 3.** Automatic hedging goes second
deliberately: use the ladder to build the ladder, or you build the harder thing
without the tool that would catch its defects.

**Blind derivation beat adversarial review, measured.** One agent given the
problem and *not* the design produced a better design plus five findings in
160k tokens. Forty-one agents given the design filed 37 findings of which **one**
survived — a blocker, so the round paid for itself, but at 27× the tokens. The
refinement that matters: they do different jobs. Blind derivation produces
*direction*; adversarial review produces *correctness within a direction*. And
the surviving blocker came from the "is there a simpler design" lens, not the
"try to defeat it" lens — asking what a thing really does surfaces correctness
bugs that asking how to break it does not.

**Reviews get a committed sha and their own worktree from now on.** Development
stalled ~20 minutes during round 2 because reviewers were promised a clean
working tree. That pause was self-inflicted and needs no new capability to fix.

**Every misroute is a bug.** Three in one session, all reproduced through
`felix_route_best`: "peer review" hit `review`, "back the memory" hit
`doctrine`, and "the semgrep misroute" hit `harness` because `route` is a
substring of `misroute`. Fixed on #49 by narrowing, and `review` renamed to
`security`, which is what that row always was. The principle: **a missed route
loses one suggestion; a false route arrives worded as a requirement and teaches
the session to read routing as noise, after which the correct ones stop working
too.** Prefer rows that fire rarely and rightly.

**On semantic routing, asked 2026-08-18 and answered without building.** Worth
having as a layer that can only *suppress* a candidate the table produced —
never as the router. The observed failures were all false positives, so a veto
is the right shape, and a veto is what invariant 2 permits. As the router it
would break the offline guarantee and force a fallback table nobody tests. Try
intent-by-shape first (none of the three misroutes was an imperative), and note
`claude-flow` already ships `agentdb_semantic-route` and `embeddings_*` —
evaluate before building. It does **not** fix #29, which is about where you are
in the work rather than what the work is about.

### The memory is backed up, and the backup was restored before it was believed

`~/.felix` is its own git repository now, pushed to a bare repo in iCloud Drive
at `felix-memory.git`. 26 files, 580K. Verified by cloning it back and diffing:
byte-identical, 49 lessons on both sides. Scanned before it was committed, and
the scanner was shown failing first — a quoted credential and an AWS-shaped key
both exit 1, ordinary prose exits 0, every byte of the memory exits 0.

Repeat it with:

```
cd ~/.felix && git add -A && git commit -m "memory: $(date +%F)" && git push icloud HEAD:main
```

Not automated. A backup that runs itself and is never restored is the shape this
project distrusts, and nothing yet decides when it should run.

### #28's engine half landed, and #2 is now the thing standing in front of it

**`felix merge` on Felix itself is judged by the engine `main` declares**, in a
child shell sourcing only that version's libraries — `V_n` judging `V_n+1` for
the enforcing path, as #42 did for the tables. A branch that weakens the rule
which would have stopped it is still stopped. Reproduced before the fix and
asserted after, with the refusal naming the channel rather than counting merges.

Three things it deliberately is not, all written into `resolve.sh` rather than
implied. It is **not a signature** — the trust is that the cache entry for the
base's version is what the base contained when somebody installed it.
`FELIX_KERNEL` still overrides everything, so whatever sets the environment
picks the judge. And **only the repository that ships the engine** is affected;
a governed product's rules live in the Felix home and are not in its diff, so it
needs no installed engine and merges exactly as before.

**#2 is untouched and is now the blocker on the rest.** The deadlock was
side-stepped, not solved: `installed` compares the tree against the newest cache
entry while the kernel reads the base's, and both hold at once. The next honest
step is deciding whether a green gate should still require the candidate to be
deployed, now that the verdict no longer depends on it.

### Three green-but-wrong states on one feature, which is the real finding

Worth more than the feature. The suite was green for all three.

1. **The first design was vacuous.** It resolved the judge as "newest entry in
   the plugin cache" — which the gate's own `installed` check guarantees is
   byte-identical to the tree. The judge was the candidate.
   `docs/2026-08-14-earned-autonomy-decision.md` §4a had said so in advance and
   was not read first. Caught by an adversarial review, after it had already
   been deployed.
2. **The second was machine-dependent.** Fixtures built with `git init` inherit
   `init.defaultBranch`, so a resolver looking for `main` worked on this laptop
   and found nothing on a runner that says `master`. Caught by CI. Fixed twice
   over: fixtures pin `-b main`, and the branch to judge against became an
   argument — whatever is being merged into, never the literal word.
3. **The third was an environment-variable collision.** `FELIX_KERNEL_CACHE` is
   called that because `toolbox.sh` has always owned `FELIX_PLUGIN_CACHE` and
   means the plugins cache *root* by it. Seven assertions covered the resolver
   and all seven passed, because every one set the variable explicitly and so
   never ran the default. Caught by the founder typing `felix merge`.

The through-line: **the suite only varies what somebody thought to vary.** Each
was caught by a different thing — review, CI, a real invocation — and none by
the tests. Before trusting a green suite on anything load-bearing, ask which of
those three it would have caught.

### What closed, 2026-08-14 → 16

**#32** and **#33**, both `risk-red`, both merged (`145cbdb`, `652fca8`).

- **#32** — the rollup no longer shares a file. Per-session `ledger.d/<sid>.tsv`,
  staged under a dotted name so the reader's glob cannot catch a rename in
  flight. `ledger.tsv` is read as data, never migrated.
- **#33** — `felix merge` reads branch, sha and tree id *before*
  `felix_merge_blockers` and again immediately before `gh`, and refuses on any
  difference, naming which of the three moved. Also: `felix merge 35` used to
  shift the argument away unread and merge whatever HEAD was on.

### What closed, and what the defect queue has left

Seven pull requests merged 2026-08-14 → 16, and **the defect queue is empty**.
Every issue still open is a design question, not a fix somebody could sit down
and write.

| closed | |
|---|---|
| [#32](https://github.com/LeavesJ/felix/issues/32) | the rollup shared one file and deleted what it had not read |
| [#33](https://github.com/LeavesJ/felix/issues/33) | `felix merge` verified one branch and merged whichever one you were on |
| [#37](https://github.com/LeavesJ/felix/issues/37) | a bare `^docs/` row classified a committed `rm -rf /` green. Closed after re-running its own reproduction against merged `main`: now **yellow** |
| [#38](https://github.com/LeavesJ/felix/issues/38) | a flag with no value spun forever — in **25** parsers, not the one the issue named |
| [#39](https://github.com/LeavesJ/felix/pull/39) | superseded by #42, which carries its commit; nothing lost |

| still open | | |
|---|---|---|
| [#2](https://github.com/LeavesJ/felix/issues/2) → [#28](https://github.com/LeavesJ/felix/issues/28) | `risk-red` | the trust chain. #42 closed the data half of the kernel — `risk.tsv` is now judged against its inherited version — and the engine half **cannot** be closed from inside the tree, because the CLI sources `lib/*.sh` from the branch under judgement. That needs a pinned base engine or an off-tree enforcement point. This is the largest thing left and it is blocked on a decision, not on effort. |
| [#31](https://github.com/LeavesJ/felix/issues/31) | design | concurrency as a feature, with a second live instance below. |
| [#29](https://github.com/LeavesJ/felix/issues/29) | `risk-yellow` | routing: two causes recorded, one fixed, one open. |
| [#51](https://github.com/LeavesJ/felix/issues/51) | `risk-yellow` | filed 2026-08-18, by hitting it. A stacked branch is classified against a merge-base that squashing freezes, so it inherits the tier of changes already merged into the base byte-identically. #50 classified **red** on #49's version bump when its real delta against `main` was one documentation file; rebasing reclassified it yellow, which is correct. It fails safe — three-dot returns a superset, so the tier only ever comes out stricter — but it demands founder approval for changes that do not warrant it, and it stamps stacked green work `risk-red` so it cannot advance the streak. The obvious patch is wrong in both directions: two-dot blames the branch for the base's independent progress. The object to classify is the tree a merge would produce, which is the same object #2's staleness clause wants. |

### What is still unprotected, said here so it is not rediscovered

- **`evidence.tsv` gets no base-version treatment.** It is read off the branch
  that changes it, exactly as `risk.tsv` was before #42. It cannot demote a
  tier — the `^projects/[^/]+/(routes|profiles|stack|risk|evidence)\.tsv$` row
  floors any diff touching it at yellow — but `felix_merge_blockers` consults it
  for the evidence blocker, and there the candidate is still its own judge. The
  CLI text now says so out loud rather than promising both tables and fixing one.
- **The auto-merge streak counts a `risk-green` label applied by hand** and never
  re-derived from the merged diff.
- **Two of #39's four classify assertions pass unchanged against `main`.** They
  are honest regression guards against the trap that fix could have set, but
  they do not test the fix; the other two do, shown failing.

### #31 has a second live instance, and it is worse than the first

The first was three worktrees sharing one `SESSION_HANDOFF.md`. The second was
observed rather than reasoned about, on 2026-08-15:

**Subagents dispatched to review a diff wrote another session's uncommitted work
into this checkout.** Four review agents were told to review and report. What
appeared in the working tree was a complete implementation of base-version table
evaluation in `lib/classify.sh`, two `risk.tsv` edits and an `automerge.sh`
change — all uncommitted, all red-tier, all staged to be committed with the
change under review. The timestamps settle it: the files were written at
**18:33**, and the session that owns that work committed it at **18:45**, twelve
minutes later, from a sibling worktree. They did not invent it. They picked it
up from a neighbour's working files and copied it into a different branch.

It was caught only because the gate failed on two assertions the same suite had
passed minutes earlier — and by then it had already been deployed, at 0.48.6.
`git status` did not show all of it until the first files were reverted.

**What follows from it, and it is not "stop using subagents".** Before
dispatching review agents, decide whether they may write. Afterwards, diff every
changed file against the base and account for each hunk by author before
committing; `git diff --stat` is the check and "I only edited three files" is
not. That is in `lessons.md`. The salvage branch
`salvage/review-agent-findings` holds what was carried in — kept, not deleted,
because it is the only artefact of the incident, and it is byte-equivalent to
#39 apart from comment wording.

### The 2026-08-14 table, kept because two of its numbers were wrong

| | |
|---|---|
| head | `04d583e`, clean, 0 unpushed |
| gate | **pass** — 701 assertions, `installed` ok, on both trees |
| engine | **0.48.4**, deployed and byte-identical |
| repository | **private**; unauthenticated API returns 404 |
| memory | **1.0 MB, unbacked** |
| open issues | **6** |

It said the ledger held real data and was worth reading. It did, and it was not:
**215 of its 280 lines were a stray `0`**, and `felix ledger` reported **7
sessions where there were 6**, because a bare `0` has one field and `cut -f1`
reads it as a session id. The summary was right the whole time — its awk skips
short lines — so the defect lived exactly where nobody would check, in the
headline above a correct table. `grep -c` prints the count *and* exits 1 when it
is zero, so `$(grep -c … || echo 0)` yields `"0\n0"`. The trap was already
written in `lessons.md` before any of this was built.

Fixed on #40 as one `felix_count` in `resolve.sh` rather than eight repaired
call sites. The memory on disk is repaired in place, every real row
byte-identical, originals kept beside it as `.bak`.

### What the concurrency audit established

15 agents, 6 findings confirmed after independent refutation, 4 refuted. Two
things from it are worth carrying forward more than the findings.

**The refuters corrected the finders in both directions** — struck a claim that
torn handoffs look well-formed (5/5 were visibly broken), corrected a rollup
timing from ~1s to ~0.17s, found a scaling claim that *decays* with N where the
finder said it climbed, and *raised* severity on a half one finder filed as
secondary. Trust the numbers in #32 and #33 accordingly; they survived that.

**The lens aimed at the actual design question was refuted, usefully.** The
finder called cross-session blindness a defect. The verdict: *"an accurate
description of an unbuilt feature, not a defect."* That is the third time this
week the project nearly treated absence of a feature as evidence of failure, and
it is why #31 stays a design question. The defects it turned up are worth fixing
whether or not coordination is ever built, because they are wrong at N=2.

**One finding is live on this machine.** Three worktrees share one
`SESSION_HANDOFF.md`, and a handoff note is tree-scoped while the memory
directory is project-scoped, so a note written in one tree can be read as
another tree's standing direction. Deterministic, no race, silent. Recorded on
#31 with the scope note: do **not** fix it by keying memory per tree.

### Two things deliberately not done

**Nothing from the audit was fixed.** All of it is wrong at N=2 and none of it
bites at the current scale — the ledger loss needs roughly 15 session-ends per
second. Filing was the requested action, and the session that found these had
already made eight mistakes, one of which shipped a silently inert fix past a
green suite. Same reasoning as the trust chain.

**22 local `claude/*` branches remain.** `felix merge` squashes, so
`git branch --merged` cannot confirm them even though their content is in main.
Deleting branches git will not vouch for is not a session-close job.

Superseded 2026-08-16. Two of those three are done and the audit's own advice —
that none of it bites at current scale — held for the ledger loss and did not
hold for the rest: the stray-zero defect was corrupting the ledger on every
rollup the whole time, at N=1, with no concurrency involved at all.

Nothing is mid-flight. `main` is `c3fd863`, the working tree is clean, the
deployed engine is 0.48.11 and `felix install` verifies it byte-identical, and
there are no open pull requests.

One trap from this session that cost real time and is not in the code. **A test
for a hang leaks the hang unless its watchdog kills the children.** The red run
of #38's test left a `felix merge --base` spinning for twenty-four minutes; the
suite reported a clean pass both times, and it was noticed only because a later
gate ran slowly enough to look. `pkill -9 -P` before `kill -9` reaps it, shown
working against a deliberate spinner. It leaks only when the test *fails*, so
the run that proves such a test works is the run that poisons every run after
it — check for strays after any red run of a bounded test.

## 1. Standing direction — decided, do not ask again

**Felix is the engineering OS and the pilot of implementation.** Not a
governance layer, not a recommender, not a sandbox. A product that adopts Felix
should get a system that does whatever implementation takes.

**The split.** The founder owns *what* gets built: product thesis, vision,
prioritisation, pitching, and approval at the risk boundaries. Felix owns *how*
it gets built, optimally — which MCP, which plugin, which skill, which agent, in
which order, in one context or several — plus installing them, tracking what
happened, and correcting course. **If the founder is thinking about tooling,
Felix has failed.** The end state is a founder who only ever considers "what
should we build next" and "should we add this".

**Interfere as much as possible.** Felix is meant to intervene, not advise. A
command that prints a suggestion for something it could safely have done is a
defect, not caution. Irreversible work still stops and asks; everything else
acts.

**Scope is Phase 1 engineering only.** Revenue, customer, support and company
administration are later phases owned by other systems. Stripe rows in the
templates are dormant capabilities, not a direction Felix grows in. Later, when
those systems exist, Felix becomes one sub-OS reporting to a chief agent — so
design its surfaces to be drivable by something that is not a human.

**How to work, decided across this session:**

- **Routine engine work on Felix does not need approving each time.** Decided
  2026-08-11. Felix's own `risk.tsv` classifies most engine changes red, and
  asking per change turned the founder into a queue for work that is tested,
  reversible, and about Felix rather than about a product. Build it, gate it,
  deploy it, say what shipped. Still stop and ask for: anything destructive in
  a product repository, credentials, money, anything irreversible, and any
  change to what Felix is *for* rather than what it does.
- **Never hand over tidying as a decision.** If Felix could safely have done
  it, doing it is the job. A founder should never be told where a duplicate
  script lives, which plugins matched no capability, or that a log needs
  truncating. Report what was done, not what they could do.
- **Decide, do not ask.** Subagents versus inline execution is Felix's call and
  the session's call, made on the shape of the work and justified in one line.
  Coupling is the usual tiebreaker: several agents editing one file invent
  conflicting assumptions. Genuinely separate files, separate repos, or
  independent adversarial review of finished work are real fan-out candidates.
- **An escape stops the merge. It does not stop the session.** Noticed
  2026-08-13, by the founder, about this session. `felix merge` refusing on an
  `execute` or `verifier` channel is correct — the mechanical path fires on a
  path because it cannot read intent. What followed was not: the escape was
  forwarded verbatim as "the founder's call", twice, and both times a single
  command settled it (the new jobs referenced zero existing secrets; the two
  they did name do not exist). Same for the Stop-hook gap, deferred as needing a
  decision and then answered in twenty minutes once asked.
  **When a channel escalates, do the analysis and arrive with a recommendation.**
  The founder's input should be a yes or no on a resolved question, never a
  research task handed back. Reserve the open question for things that turn on
  their preference or authority — which credit pool to spend, what gets built —
  not for facts a command can establish.
  This is the charter's own defect worn as prose. `felix promote` had the
  finding and printed `felix lesson "..."`; `felix install` knew the fix and
  printed "bump the version"; both were called defects and fixed this session by
  the same session that was doing it in conversation. And it moves the declared
  objective the wrong way: forwarding a mechanical stop *is* a founder
  interruption, which is the number Felix exists to reduce.
- **Ask about outcomes, never mechanics.** If a question is about how something
  is built rather than what will happen, answer it yourself.
- **Override self-imposed ceilings.** Before saying something cannot be done,
  establish who set the limit. A rule in Felix's own doctrine, invariants or CLI
  is a decision, not a constraint. If this repository owns the refusal, say so
  and default to overriding it. Reserve "impossible" for cases where a specific
  mechanism can be named.
- **A model may propose, never widen.** The enforcing path stays bash and git so
  it works with no network, key or model. Advisory commands may call a model,
  but its output is a proposal and may only narrow what mechanics already
  allowed.

**The objective, declared 2026-08-12: founder interruptions per session.** Felix
had no named objective, so every improvement was argued rather than measured. An
interruption is a moment Felix needed a decision it could not make — an escape
from `felix merge`, recorded as `escalated` in `says.log` at the moment it
happens. Deliberately *not* an unrun gate or a missing test: those are Felix's
own work, and counting them would let the number improve by gating less.
Deliberately not gate pass rate either, for the same reason in sharper form — a
gate you keep loosening passes more, so that metric moves the right way for the
worst possible reason. (The `verifier` channel now detects loosening
mechanically, which makes pass rate defensible as a *paired* number, but it
still measures the gate rather than the work.)

**What the monitor is for.** Witnessing Felix guide Claude Code, so the founder
can stop caring about what it handles. It currently shows records — routes
defined, verdicts, what Felix said — and never shows whether Claude *did* what
Felix named. The compliance signal already exists in `felix_route_due`, which
reads the transcript to see whether a play step was used. **Built 2026-08-12**,
though not from that: the ledger's `named` beside `calls` is the same question
answered from committed rows instead of a transcript, so the panel is arithmetic
rather than a parser. It reports "no data" until sessions accumulate under the
new column, and refuses to read an absence as compliance.

### The shape Felix is growing into

Named by the founder 2026-08-13. The middle is becoming strong; **both ends are
missing**, and they are the ends that make it autonomous rather than assistive.

| Stage a mature Felix needs | What exists today |
|---|---|
| INTENT | **absent.** Nothing initiates. Every session begins with a human prompt. |
| PLAN | partial. `felix brief` scopes an issue and says what a fix must prove; routes name `superpowers:writing-plans`. Felix does not plan. |
| CHOOSE EXECUTION SHAPE | `felix shape` — computes coupling, refuses the unsafe half, records the choice. |
| ASSEMBLE CAPABILITIES | `stack.tsv`, `felix ready`, `felix toolbox`. Bounded: **cannot mount mid-session**, so it writes config the next session boots with. |
| DISPATCH | **absent.** Felix names the tool; the session dispatches it. |
| IMPLEMENT | the session. |
| TEST | `felix gate`. |
| DIAGNOSE | partial. `felix next` rank 5 reads `mistakes.log` and distinguishes "no lesson yet" from "the lesson is not working". |
| REPAIR ↺ | `unattended.yml` — wired, and off. Never run for real. |
| VERIFY | gate receipts keyed on tree identity, plus the `Stop` hook. |
| REVIEW | `felix review` and the `reviewed` channel. Built 2026-08-13. |
| SHIP | `felix pr`, `felix merge`. Merge only started working 2026-08-13. |
| OBSERVE PRODUCTION | **absent.** Sentry is declared and unconfigured; nothing is deployed. |
| REPAIR / LEARN | `lessons.md` matched into prompts, the ledger, `felix promote`, `felix next`. |

Where Felix actually sits, in its own vocabulary: UNDERSTAND → ROUTE → CONFIGURE
→ GUIDE EXECUTION → OBSERVE → VERIFY → CLASSIFY → PR/MERGE → REMEMBER.

**The two gaps are not the same size.** *Autonomous initiation* is blocked on a
design question nobody has answered — what may wake Felix, and on whose
authority. *Production feedback* is blocked on a fact: nothing is deployed, so
there is nothing to observe. The second unblocks itself the day there is a
deploy target; the first will not unblock on its own.

### Where the durable copies live

| What | File |
|---|---|
| Charter and invariants | `projects/felix/CLAUDE.md` |
| Hard-won lessons, matched into prompts | `$FELIX_MEMORY/felix/lessons.md`, default `~/.felix/memory/felix/` |
| This direction | this file |
| Per-project rules | `projects/<p>/{routes,risk,evidence,stack,deny,maintenance}.tsv` |

Nothing in Felix's home is auto-loaded into a session. `SessionStart` names
these files and says they are required reading; whether they get read is the
delivery risk. Inside the Felix repo this is masked because Claude Code
auto-loads `CLAUDE.md` files it finds in the tree. In a governed product repo it
is not masked at all.

---

## 2. State as of 2026-08-11

- Engine **0.47.5**, deployed and verified (`felix install` → "verified the
  installed engine matches this tree").
- `felix gate` → **pass**. **601 assertions**, 0 failed. `main` is pushed and
  **CI is green — checked, not assumed.** It had been red for at least two
  commits while this line claimed otherwise. Read `gh run list --branch main`
  before writing that sentence again.
- **`PreToolUse` now binds `Bash|Edit|Write|Read|NotebookEdit|WebFetch`.** It
  bound `Bash` alone until 0.27.0. What replaced the matcher as the
  blast-radius control is `felix_deny_overbroad`: a pattern is tested against
  two ordinary subjects — `git status --short` and `/felix/probe/ordinary` —
  before it is allowed to refuse anything, and one that matches them is skipped
  as a rule that is wrong rather than honoured as a rule that is strict.
  Skipping can only ever allow more, never less. `felix doctor` reports every
  row skipped that way, because the hook runs on every call and saying it there
  would be noise. Measured cost of the widening: **34 ms per call**, synchronous
  — roughly 1.7s across a session at the rates the ledger records.
- Felix wires **8 of the 11 lifecycle moments** anything on this machine binds,
  and has a written stance on the other three. `felix coverage` shows the table.
  At the start of 2026-08-10 it wired 3, and all three only injected text.
- **A stop now names what a revert cannot reach, and Felix can merge.** Decided
  2026-08-12 after PR #4 waited a day on a one-line dependency floor correction.
  A tier used to be a function of which file you touched; `risk.tsv` now carries
  `channel` (what merging writes outside the tree) and `confine` (what must stay
  true for the row not to fire). Most rows carry neither and are advisory. Four
  channels are engine constants no project may declare away — `disclose`,
  `execute`, `durable`, `verifier` — and `felix merge` refuses on any of them,
  computing every blocker offline and touching the network only to merge.
  **Corrected 2026-08-13:** `felix merge` could not merge at all until 0.42.0 —
  it built `gh pr merge --repo <slug> --squash` with no pull request named, and
  gh refuses that client-side. The refusal paths were all tested; the one line
  that reaches gh was not.
  **`felix merge` has now merged something — PR #6, 2026-08-13 — which is the
  first time in its existence.** Output: `merged. nothing in it escaped the
  tree.` Every previous session's claim that it had never merged anything was
  true when written; it is not any more.
  What made the difference is the second finding, and it is worth knowing before
  the next engine change: **merge cannot be reached from a worktree, and the
  constraint is the path rather than the branch.** Merge wants a green gate receipt for that
  exact tree; the gate's `installed` check compares the tree with the deployed
  cache; the marketplace is pinned to one directory, so a worktree's engine is
  never the served one and `installed` can never pass there. No receipt, no
  merge, permanently — the same cycle already recorded for install-versus-push,
  closing one stage later. PR #1 was merged through `gh` on green CI instead,
  and the gate was then run in the tree that can deploy, where `installed`
  passed. Loosening the gate was available and deliberately not done; the two
  candidate fixes are in `lessons.md`, and the better one leaves the verifier
  alone.
  **The workaround costs nothing and should be the default: do engine work on a
  branch inside `/Users/a14808/Documents/Felix`, not in a worktree.** `felix
  install` deploys from whatever branch is checked out in the served directory,
  so `installed` passes, the receipt is real, and `felix merge` works — that is
  exactly how PR #6 went in. Tracked as issue #2 with the evidence.
  **A side effect worth fixing with it.** Every gate run in such a worktree
  records `installed` in `mistakes.log`, because the gate writes a row for each
  check that failed and cannot know this one was never able to pass. This
  session's own runs took the count from 9 to 11. So the check that is
  structurally unpassable there is also the loudest entry in the recurrence
  report — it manufactures its own evidence. The liveness window added today
  bounds how long that lasts but does not stop it accruing; whichever of the two
  candidate fixes lands should also stop a skipped-by-construction check being
  written down as a mistake.
  **What always stops:** a secret in added lines; `.github/workflows`; an
  enforcing table or a verifier losing checks; migrations or destructive SQL;
  money; a declared consumer. Nothing else.
- **Several sessions at once is a supported case, and was checked rather than
  assumed.** People keep multiple terminals on one checkout. Receipts are safe
  by construction: `felix_tree_id` hashes every uncommitted byte, so a second
  session's edit changes the identity and no verdict or gate receipt can be
  inherited across it; the gate receipt is keyed on the root path and a review
  verdict on project plus tree, so two worktrees of one project never collide.
  The ledger was **not** safe and is now — `user-prompt`'s repo-derived fallback
  key exists for announce dedup, where a shared key costs one missed
  suggestion, and ledger data had been hung on it. No session id, no row.
- **A reviewer's isolation is checked; its independence is not.** `felix review
  --in <worktree>` refuses to record a *pass* that claims it ran in the tree
  under review, because a clean result from a tree being edited means nothing.
  A *block* is always recorded wherever it ran, or the check becomes a way to
  lose bad news. Independence remains unverifiable and the output says so.
- **`felix next` ranks the backlog, anchored on the objective.** Six commands
  reported upkeep, drift, setup gaps, evidence, coverage and retirement and
  none said which mattered. The order is: work Felix owes on the change in
  hand; an escape (the number the objective counts, never buried); a tool a
  route names and cannot reach (fixable only between sessions, since plugins
  bind at start); upkeep; checks that are not checking; routing. It ranks and
  does not act, and `next.sh` argues why rather than apologising.
- **Felix's own upkeep had never been able to fire.** `maintenance.tsv`'s third
  column takes `always` or a capability; Felix's used `-`, so all four routines
  were dormant from birth and `felix maintenance` printed "Nothing due" —
  identical to a well-kept repository. Found by `felix next` asking for due rows
  and getting none from a project with four overdue. Now **4 due**;
  `felix_maint_unreachable` guards it and the suite asserts no shipped row is
  unreachable.
- **Felix's own latency, measured 2026-08-13 and then halved.** `PreToolUse` is
  synchronous on every Bash/Edit/Write/Read/NotebookEdit/WebFetch call, so its
  cost is the session's cost. It was recorded at 34ms when it bound Bash alone;
  widening the matcher tripled the per-call cost to **105ms** and multiplied the
  calls paying it, and nobody re-measured because the handoff still said 34.
  Now **42ms** (Bash) / **37ms** (Read), by replacing process spawns with bash
  builtins — parameter expansion instead of a four-process sed pipeline,
  `[[ =~ ]]` instead of a grep per probe per rule, an upward walk for `.git`
  instead of `git rev-parse`, and an early exit when no row names the tool.
  **Re-measure whenever the matcher widens.** For scale: the full gate is
  **89s**, so a single verification run costs more than Felix does all session.
- **A `declined` stance is now falsifiable.** `lifecycle.tsv` carries a fourth
  column, `holds`, naming the literal in `hooks.json` its reason rests on:
  `PreCompact` holds `compact`, `PostToolBatch` holds `"PostToolUse"`. Delete
  either and the row goes `stale-reason` and the suite fails — shown failing
  against the shipped table, not only a fixture. `-` stays legal for a decline
  resting on judgement, and **1 currently does** (`Notification`); the count is
  printed every run so the unfalsifiable share is a number rather than a
  property nobody can see. Three-column tables still parse.
- **The ledger has real data for the first time.** One session: `Bash` 66,
  `Read` 23, `Edit` 15, `Write` 5, `Agent` 1 — and zero rows for
  `code-review`, `code-simplifier`, `security-guidance`, `claude-md-management`
  and `anthropic-skills`, every one mounted and never reached for. That is the
  unconfounded signal working. The retire threshold is 5 sessions, so nothing
  is actionable yet; do not act on one session.

### What Felix does without being asked

Binds the session and names the constitution and handoff as required reading;
reports capability drift and upkeep; tidies where a project has opted in;
routes each prompt and names the tool that is due; states the shape of a plan
when a prompt points at one; refuses forbidden shell commands, and forbidden
reads, writes, edits and fetches; records every
tool call and rolls it into a ledger with a zero row for everything mounted and
never reached for; checks the gate when the session stops.

### What it can do when asked

Run and record a gate; classify a diff; say what a change owes; brief an issue;
open a pull request; reach, read and route any installed plugin; install what it
has read and judged low risk; compute which tasks may run apart; report what has
never been reached for; detect a rival gate and remove it where that is safe.

### What Felix still cannot do

Mount an MCP server or enable a plugin mid-session — that needs a restart, so
tooling decisions are written as configuration between sessions. Deploy a
product. Plan work from scratch. Dispatch subagents itself. Enforce its own red
tier mechanically (see §3).

**The mid-session limit is still real and its cause moved, checked 2026-08-13.**
It is no longer a protocol gap. MCP revision `2026-07-28` deletes the handshake
and the session, so every request is self-contained and *attaching* a server
mid-session now costs almost nothing; what the protocol still lacks is any way
to learn a server exists — `server/discover` describes only the server already
addressed, the Registry is a preview REST service not meant for host
consumption, and Server Cards (SEP-2127) is in review, not landed.
Meanwhile **Claude Code 2.1.226 already ships a complete 2026-07-28 client and
has it switched off.** Verified on this machine against the binary, not taken on
report: `server/discover`, `subscriptions/listen`, `inputRequests` and
`Mcp-Method` are all present, and the gates read
`nt("tengu_mcp_protocol_negotiation_http", !1)` — server-side flags defaulting
to false, falling back to `{mode:"legacy"}`. Observed traffic is `2025-11-25`
with the old handshake.
So this is a feature flag in the host, not a fact about what is possible, and it
is likely to move without Felix doing anything. Report it that way — the lesson
about establishing who set a limit applies to this one. Full analysis in
`docs/2026-08-13-ultron-federation-gap.md` §8.

---

## 3. Operational traps that have each cost real time

- **Hooks are bound at session start.** `felix install` updates the cache and
  the CLI on PATH, so verifying a hook fix through the CLI passes convincingly
  while the hook still firing on every prompt is the one loaded hours ago. A
  routing fix was built, deployed and verified three times today and the session
  that shipped it kept misrouting for its whole life. **Check the version in the
  SessionStart banner before claiming a hook change is live here.** It is live
  for the *next* session, which is a much weaker claim.
- **A changed engine at an unchanged version never deploys.** Claude Code caches
  by version. `felix install` refuses and tells you to bump
  `engine/.claude-plugin/plugin.json`. The bump *is* the deployment.
- **`FELIX_HOME` is the main tree, not your worktree.** Editing
  `projects/*/…tsv` inside a worktree changes nothing until merged. Override
  with `FELIX_HOME=<path>` to test.
- **`felix gate` is red on any undeployed engine branch.** The `installed` check
  compares the tree against the deployed cache, so a branch that changes the
  engine cannot be green locally until it is deployed. CI skips the check when
  no plugin is installed, so a pull request can still go green.
- **Felix's red tier is honoured by behaviour, not enforced.**
  `gh api repos/LeavesJ/felix/rulesets` → 403, "Upgrade to GitHub Pro or make
  this repository public". Branch protection is unavailable on a private free
  repo. Elenchus gets real enforcement only because it is public. The decision
  was to behave as if the rule applied and state the gap rather than hide it.
  **Nothing mechanically stops a bypass.**
- **Debug `tests/run` in place.** It computes the harness path from `$0`; run it
  from elsewhere and it starts copying the root filesystem.
- **Run the suite and commit as one chain.** A piped test run masks the exit
  status and commits a red tree.

---

## 4. Guidebook exit criteria (p41)

**Re-audited 2026-08-13 against the guide itself, every row re-run.** The guide
was decoded from the PDF rather than recalled; Phase 1 asks for Build: CLAUDE.md,
GitHub integration, PR workflow, tests, Sentry, Playwright, Strix, basic audit —
Exit: take an issue, create code, run tests, deploy preview, test it, open PR,
report confidence. The previous version of this table was hand-maintained and
wrong in nine places; do not edit a cell here without re-running its command.

| Promised | Status | Evidence, as of the audit |
|---|---|---|
| take an issue | **yes, on real input at last** | **The `<n>` path had never had real input, and now has.** Four issues were filed 2026-08-13 — #2 to #5, the first this repository has ever held — and running `felix brief` on one immediately found a fifth defect: **a path in inline backticks resolved to nothing**, because the splitter breaks on quotes, parens and brackets and never on a backtick. Issues are markdown, so that is how every path in one is written. `brief 2` listed one of two files and said tier **yellow**; the file it dropped was `engine/harness/lib/resolve.sh`, which `risk.tsv` calls red. Not an omission — a confident risk verdict one tier low, from the command whose job is to say how dangerous work is. Fixed in 48d3f9f, with asterisk and the trailing `,;:` marks. `brief 2` now reports both files, tier red, and refuses to start; `brief 3` says it can scope nothing and declines to guess. Earlier fixes that hold: a path ending a sentence, an unmatched path reporting green, no risk.tsv reporting green. Still open: an issue asking for a file to be **created** is silently dropped (`incident.sh` only emits paths that exist), and the `gh` body fetch has no `\|\| die`, so a rate limit renders as a confident "no file it names exists". |
| create code | **supervised only** | All 547 Elenchus commits carry the founder's identity. `unattended.yml` has run 3 times, every one skipped in under a second because `FELIX_UNATTENDED` is unset. No model has written code here unattended. |
| run tests | **yes** | Elenchus `felix gate` → `1229 passed`, 32.8s. Felix → `577 passed`. |
| deploy preview | **yes, smallest honest version** | A `preview` job stands the real app up on :8123 against the scripted fake model. Verified in CI 2026-08-13: "preview answered after 3s". Not a deploy a stranger can reach; it is a real app on a real port over real HTTP. |
| test it | **yes** | `tests/test_preview.py`, marked `preview`, runs against that server in CI — **4 passed**, not skipped. Verified in all three states: skipped with no URL, FAILED against a dead port, passed against the real one. The two static suites no longer delegate their teeth to a manual habit. |
| open PR | **yes, and merging too** | PR bodies, base, branch, tier label and `--draft`-unless-green all verified. **Merging: yes as of 2026-08-13** — `felix merge` merged PR #6, the first merge it has ever performed. Two things had to be true that never had been: the five risk labels had to exist (`felix pr` could not apply one on PR #1 because none had ever been created), and the work had to be on a branch in the served checkout rather than a worktree. Both in §2. |
| report confidence | **partial** | Fixed 2026-08-13: `scope` used a path-only reader and was blind to content rules, so a diff adding a credential to a `.md` printed "In scope … unattended attempt" while `classify` called it red. `scope` now classifies the diff, and says so when given bare paths. `classify` still exits 0 on red while `scope` exits 3. |
| DEFINITION OF DONE | **fixed 0.45.0** | A clean tree used to end the hook before the receipt was read, so committing your work — what you do at the end — skipped the check entirely. `UserPromptSubmit` now records the HEAD it first saw (SessionStart cannot: it never reads its payload), and Stop is silent on a clean tree only when the session also committed nothing. Unknown counts as unchanged, so a session with no mark behaves as before. |

Build list, re-checked: `CLAUDE.md` **on this Mac only** — gitignored, untracked,
absent from every clone including the CI runner that `unattended.yml` hands to
`claude -p`. GitHub integration **partial** — `gh` and Actions real, the MCP
returns HTTP 400 and `felix setup` already says so. PR workflow yes on Elenchus,
0 PRs ever on Felix. tests yes. Sentry **absent**, capability undeclared.
Playwright installed and routed, **0 browser tests**. **Strix does not exist** —
0 of 286 marketplace entries. basic audit **partial**: three gate checks are
real and semgrep is wired into nothing.

**Corrected 2026-08-13.** This row also said `secret-scan`'s exclusions apply to
the whole line, so a real key beside the word "example" exits 0. That was fixed
before the line was written and the line was never re-run. Re-checked by feeding
the scanner four cases: an AWS-shaped access key assigned to a variable on a
line whose trailing comment says "example config" exits 1; a private key header
wrapped in `<pre>` exits 1; a password assigned an angle-bracket placeholder
exits 0; and AWS's own documentation key exits 0, because there the exclusion
token sits inside the credential rather than beside it. Context exclusions read
whole-line and value exclusions read the matched credential, which is what the
lesson in `lessons.md` already described.

Written out longhand rather than quoted, because quoting the first case is what
a scanner reading added lines is for: the first draft of this paragraph pasted
the literal and the gate stopped the commit. Correct behaviour, and the cheapest
possible demonstration that this row is now true.

## 4b. Playwright: assessed 2026-08-11, deliberately not adopted

The p41 list asks for browser coverage and the honest answer is that this
project already has the coverage and does not need the browser.

Checked rather than assumed. The app was started, driven in a real browser, and
came back clean: title renders, ten scripts load including three.js and its
shaders, a canvas is present, the shell auto-creates a session and gets 200, and
the console has **zero errors**. Nobody had ever confirmed that.

Underneath it sit 45+ HTTP-level tests in `tests/test_web_api.py` — including
`test_vendor_three_is_served`, `test_index_references_*`,
`test_static_assets_are_not_cacheable` and
`test_shell_renders_the_front_door_and_living_sitting_affordances` — plus
`test_renderer_pipeline_static.py` and `test_visual_theme.py`. Every asset the
shell references resolves.

Adopting Playwright would add a ~300MB browser download to a gate that runs on
every change, in exchange for regression protection on a surface that is
already better covered than most. Revisit it when there is browser behaviour
these cannot reach — real drag-to-orbit interaction, or a visual regression that
matters — and not to tick a criterion.

## 4c. Self-diagnosis, and the ceiling on it

Two coverage gaps were found on 2026-08-11 by the founder noticing: the `Stop`
hook checked the gate and never asked anyone to verify their claims, and
`SubagentStop` was unwired. Both are one defect — a completion moment with
nothing at it — and neither was findable by reading code, because **absence has
no line number**. Nothing greps for a hook that was never written.

`lifecycle.tsv` plus `felix coverage` fix the second kind. Every moment
something binds gets a stance, the stance is compared against reality, and the
suite fails on a mismatch. The roster is **discovered** from what anything on
this machine actually binds — the first version was typed from memory and was
wrong within the hour, printing "every moment has a stance" while
`settings.json` bound `SubagentStart` and something bound `PostToolBatch`.

**The ceiling, which matters more than the mechanism.** Of the two gaps that
prompted all this, coverage finds *one*. `SubagentStop` was an unbound event, so
a table could see it. The first gap was `Stop` — wired, with a row, with a
reason, and still saying nothing useful after a green gate. It would be green
under every check proposed. **No table comparison finds a missing sentence.**

The full design, including five further states and a proposal to make
`declined` reasons falsifiable, is in
`docs/2026-08-11-self-diagnosis-design.md`. Its own conclusion is that the only
mechanical hint for the missing-sentence class is an inventory of silent
`exit 0` paths after project resolution — a triage queue for a model, never a
check, because a model may only narrow what mechanics already allowed.

Read that before building the next layer. A self-diagnosis that overclaims is
worse than none: it converts "nobody checked" into "something checked and said
it was fine".

## 5. Next, in leverage order

Everything that used to be above this is done. One item is left, and it is not
one anybody can sit down and build.

1. **Auto-merge and the unattended switch.** Elenchus is 1 of 5, **Felix is 4 of
   5 — one green merge from the unlock.** Both unlock on five consecutive green
   merges, and maintenance will not produce them: a well-kept repository yields
   about one real PR from a full sweep of due routines, measured rather than
   guessed. They come from real feature work, so this advances as a side effect
   of building things. Read the number from `felix automerge`, never from here.

**Closed 2026-08-13 — and the entry was wrong.** "Convert the pure recommenders:
`doctor`, `handoff`, `promote`, `recommend`, `which`" misfiled three of five.
`handoff` already writes `SESSION_HANDOFF.md`. `which` is a query with nothing
to do. `recommend` deliberately installs nothing and the suite asserts it, which
was a decision. `doctor` already acts through `--fix`. Only `promote` was pure:
it computed that the gate had caught the same check eight times and then asked a
person to type `felix lesson`. It is now rank 5 of `felix next`, carrying the
distinction it always printed and never acted on — a recurrence with no lesson
needs one written, and a recurrence that already has one means the lesson is not
working and the fix belongs where the gate can see it.

### Explicitly not next, with reasons

- **Playwright.** Assessed 2026-08-11 and declined; see section 4b. Revisit for
  browser behaviour the HTTP tests cannot reach, not to tick a criterion.
- **Deploy, smoke tests, telemetry.** Three empty boxes in the guidebook loop
  that are product-stage facts rather than Felix gaps. Elenchus has no deploy
  target, so there is nothing to wire.

## 5a. Session of 2026-08-13/14 — what shipped, and what it cost

Engine **0.47.5 → 0.47.15**, suite **601 → 678 assertions**, 14 pull requests
merged, of which 8 went through `felix merge` — which had never merged anything
before this session. The repository had never held an issue; it now has six,
three still open.

**The theme, stated because it recurred seven times.** Every substantial defect
found was one species: **a signal that reports the wrong thing, usually an
emptiness read as an all-clear.** `felix route --promote` printed "nothing has
missed often enough" after its pipeline crashed. `felix next` ranked a
recurrence that had stopped recurring, and ranked it on evidence a
structurally-unpassable check was manufacturing for itself. The lesson matcher
missed two of Felix's own seven gate check names. `felix doctor` invented drift
in a worktree. The Stop hook told the founder to `felix quarantine felix` in
response to Felix working correctly. A check written to catch checks that cannot
fail, could not fail.

Four of those were introduced *by this session*, in the commits that were fixing
the others, and were found only because a 24-agent adversarial audit went
looking. That number is the honest headline: **at this rate, a new public
surface inherits the same defect rate with no audit standing by.** It is why the
receipt refuses to claim more than it knows, and it is the strongest argument in
`docs/2026-08-14-earned-autonomy-decision.md` §3.1.

**Built:**

- `felix receipt` — `felix.receipt/1`, the first thing Felix can hand to
  something that is not a person. Serialises facts already computed. Its
  `verification` object has three states and reported `stale` against the change
  that built it, which is the distinction earning its place on day one.
- A gate may mark a failure `FAIL (structural: …)` — it failed for a property of
  where it ran, not of the work — and the engine subtracts those from
  `mistakes.log`. The verdict is unchanged; only the record is.
- `felix_same_repo`, replacing two path-prefix guards that lapsed in a worktree.
  One of them was the last defence on the only path in Felix that deletes.
- `felix_guard_is_own`, so Felix stops reporting its own correct refusals as
  another plugin's malfunction.
- Locale pinning on the route text pipelines, a `ship` route, backtick-aware
  path extraction in `felix brief`, and the machine-text filter on routing.

**Traps found that will cost somebody else time:**

- `git rev-parse --verify <40-hex>` exits **0** for a sha that does not exist —
  it checks syntax, not existence. Only a *name* it cannot resolve fails. Peel
  with `^{commit}`.
- `grep -c` prints the count **and** exits 1 when that count is zero, so
  `$(grep -c … || printf 0)` yields `"0\n0"` and every integer test on it errors
  into the wrong branch.
- `felix merge` squashes, so the merged commit SHA never matches the branch —
  but the **tree OID is identical**, verified across four merges. Content
  identity survives the merge; commit identity does not.

## 5b. What is now tracked as an issue

The repository held **zero issues for its whole life** until 2026-08-13. Four
were filed so the open findings stop living only in this file, and so the
`felix brief <n>` path finally had real input — which is how the backtick
defect in §4 was found within a minute of the first one existing.

| # | Label | What |
|---|---|---|
| [#2](https://github.com/LeavesJ/felix/issues/2) | `risk-red` `needs-architecture` | `felix merge` unreachable from a worktree. Workaround found and commented: work on a branch in the served checkout. Preferred fix accepts a CI receipt and touches no verifier. |
| [#3](https://github.com/LeavesJ/felix/issues/3) | `risk-red` | A check that cannot pass still writes a `mistakes.log` row, so it manufactures the recurrence evidence that ranks it. `installed` went 9 → 11 during the session that fixed the recurrence report. |
| [#4](https://github.com/LeavesJ/felix/issues/4) | `risk-yellow` | Three mounted plugins no keyword can reach, and `felix next` rank 6 advises fixing keywords. It should distinguish "no route matched" from "no route may name this at all". |
| [#5](https://github.com/LeavesJ/felix/issues/5) | `needs-founder` | **Decided 2026-08-14, and it grew into the largest open design question.** Recorded in `docs/2026-08-14-earned-autonomy-decision.md`. Not "red counts as green": an earned harness-autonomy record, with authority-widening behind a separate gate. The founder then refined it twice — the protected thing is the smallest *transitive* authority kernel, and the evaluator must be the base version (`V_n` judges `V_n+1`), which is **violated today, structurally**: the gate's `installed` check forces the candidate to be deployed before green, so by merge time the candidate is the evaluator. That makes #5 and #2 one problem. Open sub-question, newly created: how base-version evaluation is achieved. A pinned copy of the trusted commit is the obvious candidate and is undesigned. |

Do not re-derive these here. If one is closed, say so in this table.

## 6. Open decisions

- **Strix: wired, skipping, and deliberately unfunded. Decided 2026-08-13.**
  No Strix account is needed — verified against `docs.strix.ai` and the source,
  not a blog: the prerequisites are Docker and an LLM API key, Apache 2.0, no
  registration. So there is no signup to do, ever. The `pentest` job exists in
  Elenchus's gate.yml, is `continue-on-error`, and **skips entirely until
  `LLM_API_KEY` is set**, which is the state it should stay in for now.
  *Why not yet:* Elenchus has no deploy manifest, binds `127.0.0.1` everywhere,
  has no auth module and declares `consumers: none`. There is nothing reachable
  to attack, so findings would describe a threat model that does not exist.
  *Trigger to revisit:* a real deploy target.
  *Which provider is genuinely undecided, and the evidence does not settle it.*
  There is no published head-to-head; the one benchmark (XBEN, 96%) used
  `gemini-3-pro-preview`, and the README recommends OpenAI, Anthropic and
  Google equally. So choose on billing separation rather than capability, and
  prefer a pool that is NOT the Anthropic key the product and `unattended.yml`
  already share — commingled spend cannot be attributed, which is the same
  confounding this project spent a session removing from the ledger.
  *Cheapest first step, when curious:* one manual laptop run against the smoke
  server with `--max-budget 5`. `--max-budget` is a hard cumulative cap across
  every agent, so "activate or save the credit" was never binary. Note the
  upstream default scan mode is **deep, 1-4 hours** — always pass `--scan-mode
  quick` explicitly. `STRIX_TELEMETRY` is opt-out and already set to 0.

- **Two of the four 2026-08-12 autonomy decisions are only half built.**
  *Doctrine content* is **done** as of 0.35.0: a `reviewed` channel, cleared
  only by a passing verdict recorded against that exact tree, wired to
  `content/(maps|rubrics)/` and `judgment_loop.py`. It is the one place a
  model's output widens rather than narrows, which is why invariant 2 in
  `projects/felix/CLAUDE.md` now carries a written exception — read that before
  extending it to a second channel. *The plugin bump* was freed to merge, and the compensating stop at `felix install` turned
  out to be unbuildable — see `lessons.md`: the gate's `installed` check means
  install must precede green, so any refusal keyed on "already pushed"
  deadlocks the loop. There is currently **no** stop on deploying an engine
  that never reached CI, only the fact that `felix install` is typed by hand.

- **Unattended repair.** Wired and off. `gh variable set FELIX_UNATTENDED --body
  true --repo LeavesJ/Elenchus`. Felix will not flip it: the evidence that would
  justify it cannot be gathered without spending it, so the first real run wants
  someone watching.
- **Exploration arm on capability mounting: not yet, revisit at 20 sessions.**
  Decided 2026-08-12. Recording what the policy *named* shipped today and is
  what makes future ledger data usable, so the retrofit problem is solved.
  Exploration is the other half and it is not cheap the same way: it spends
  degraded real work sessions to buy bits, and at roughly one session a day
  against 2 recorded it buys almost nothing for a long time. Nothing is lost by
  waiting. Revisit when the ledger holds 20 sessions.
- **Auto-merge.** Elenchus is **1 of 5**: #4 merged green 2026-08-12, the first
  of the run. **Felix is 4 of 5, checked 2026-08-14 with `felix automerge`** —
  #8, #14, #18 and #19, all documentation. One more green merge earns it.
  The mechanism is the counter working rather than failing: the streak counts
  *green* merges, and Felix's own `risk.tsv` calls anything under
  `engine/harness/lib` red by construction, so **engine work on Felix can never
  advance this number**. It moves on template, per-project and documentation
  changes, or not at all — which is what the four above are. A red merge does
  not reset the run, it simply does not count; PR #21 was `risk-red` and the
  streak stayed at 4. Worth deciding whether that is the intended reading: the
  unlock exists to test whether a green classification is trustworthy, and a
  repository whose green changes are all prose gathers thin evidence for it.

  **This entry said "still 0 of 5" until 2026-08-14 and had been wrong for
  four merges.** It was then repeated out loud to the founder by the session
  that read it. `lessons.md` already carries "a status table is the least
  trustworthy thing in the repository", so the lesson did not fail to exist —
  it failed to fire. Every number in this file has a command that produces it;
  run the command.
- **GitHub MCP is broken, not missing.** `plugin:github:github` returns
  `HTTP 400: Authorization header is badly formatted`. It was authenticated once
  and the credential is now malformed. Needs an interactive session.
- **`scripts/prepush.sh` in Elenchus** is an untracked copy of a file Felix
  holds, identical today and free to drift. `felix doctor` reports it. The stale
  `scripts/gate.sh` beside it was deleted 2026-08-10 after it caused a session
  to report green from a gate missing the `secret` check.
- **`routes.log` pollution: closed 2026-08-13, and "new rows are clean" was
  false when it was written.** The envelope fix went into `felix_route_tokens`
  and never into `felix_route_log`, which stripped the runtime's pairs but not
  the JSON keys — so every miss recorded the literal words `prompt` and
  `prompt_id`, and they were rows one and two of `felix route --promote`, above
  every word anybody had typed. The row from the session that found this still
  had them. Both now go through one `_felix_envelope_text`, applied on write and
  again on read, so rows already on disk clean up without truncating anything.
  Top misses after: `felix` 9, `continue` 7, `session` 5, `merge` 4.
  `merge` was the only one naming a kind of work and now has a `ship` route.

- **Three mounted plugins cannot be reached by any keyword, and `felix next`
  gives the wrong advice about them.** `code-simplifier`, `security-guidance`
  and `claude-plugins-official` show in the ledger as mounted-and-never-named,
  and rank 6 says to fix the keywords in `routes.tsv`. No keyword can reach
  them: they are among the 29 installed plugins matching no capability Felix
  declares, so `felix toolbox` does not list them and no route may name them.
  The fix is `felix adopt`, not a keyword — and whether those capabilities are
  worth declaring is a real question, not a typo. Not done here.

---

## 7. Approaches already tried and rejected

Do not re-propose these without new information.

- **Retiring capabilities by usage count.** Circular: loading a capability is
  what causes it to be used, so a high count can never justify mounting.
  **Corrected 2026-08-12:** the second half of this entry used to say absence of
  use given presence is *unconfounded*, and it is not. Felix decides what the
  routes name, so a capability no route named was never in scope in a way any
  session could act on — its zero measures Felix's priors. The ledger now
  records `named` beside `calls`, and only `named>0, calls=0` proposes
  retirement. Do not restore the stronger claim; it survived a month because it
  was written in the file that decides what counts as evidence.
- **Blacklisting words to silence hook-payload field names.** Banning `hook` to
  silence `hook_event_name` made "the stop hook is blocking" match nothing.
  Remove the structure, not the vocabulary.
- **Parsing session transcripts in the engine.** 1.7MB of JSONL, and general
  JSON parsing in bash is not practical at that size. Record at the moment it
  happens instead.
- **Making Felix public to get branch protection.** The doctrine is the moat.
- **`felix shape` deciding execution by itself.** Felix cannot reason inside a
  hook. It computes coupling, refuses the unsafe half, and records the choice.

---

## 8. The failure mode this project keeps having

Four times now, correct and tested code did nothing because of *where* it was or
was not installed: a hook absent from the plugin cache; an engine that never
deployed because its version had not changed; a receipt written inside the tree
it described; and a hook fix that never reached the session that shipped it.
Every one was found by running the deployed thing against a real repository,
never by the suite.

A fifth variant is about where an explanation lives: a fix described in a commit
message rather than in `lessons.md` was repeated within the day. `lessons.md` is
matched into prompts; a commit message is read once and never again.

A sixth, found 2026-08-11: *where the test runs*. Three assertions about bundled
plugins passed on the laptop and failed on every CI run, because the branch they
name only executes where no `claude` CLI answers — which is every runner and no
laptop. Sitting in that branch was a real defect: the 0.26.0 bundled fix had gone
in one line below the short-circuit that returns first. Same shape as the others.
The code was correct; the place it ran was not the place it mattered. The tell is
CI and local disagreeing, so treat that as a finding rather than as flakiness,
and put the machine into the fixture — a stripped `PATH`, a fixture `HOME`.
