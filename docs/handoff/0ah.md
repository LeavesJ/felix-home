## 0ah. Verified at session close, 2026-08-30 (afternoon) — Decision C shipped, and the first review that ran before the merge

Each line produced by a command. Newest first under §0. This is the first
session on the A′ voice, and the voice held to §0ag's spec — see below.

| | |
|---|---|
| head | `a8c7f50` on `main` (#113), CI `gate` **success** |
| deployed engine | **0.49.32**, gate `installed ok` in the served checkout, full gate **pass** |
| suite | **975 assertions**, from 962 |
| open issues | **9**, unchanged |
| open PRs | none besides this handoff |
| decisions record | 4 mandates since the channel shipped, **2 declined on the record** |

**Decision C is built and deployed** (#113). Step 1 — doctor findings becoming
declared rows a person commits — was verified already live end to end
(`felix_adopt_capability` + the session-start adopt) and deliberately not
rebuilt. Step 2: matching reads what a plugin ships — `felix_discover_inspect`
names each skill, `felix_capability_match` (still the single scorer) takes the
list as evidence at triple weight, and both the toolbox column and the
`discover --quiet` re-score feed it the real list from the copy on disk. Step
3: `felix stack reconcile` proposes mounts and unmounts from the ledger's MCP
record, and session-start volunteers **unseen proposals once**,
discovery-style — a proposal shown and left unacted is an answer.

### Two deviations from the memo's letter, both on construction

Written here so the founder can reverse them knowingly; both are argued in
full in `lib/stack.sh`'s reconcile comment.

1. **There is no mount-on-play-named.** The rollup records a
   named-never-reached entry with kind `named` — nothing knows it IS a server
   — so the memo's "needed" mount trigger could never fire on pipeline data;
   and the one path that could reach it, rows outliving a deleted declaration,
   would have proposed re-mounting forever off Felix's own routing priors.
   Reach is the only mount evidence.
2. **The unmount side reads the kind-agnostic summary**, stack.tsv supplying
   the kind. A kind-filtered read is blind to exactly the rows the rule is
   about.

### The review ran before the merge, for the first time

Every prior red-tier engine PR merged with no reviewer but its author, and the
one retro-review (§0ae) found eight real defects. This one was reviewed while
still uncommitted: four lenses over the diff, every finding verified by two
independent refute-by-construction agents. **11 confirmed, 3 refuted, 9
notes** — all confirmed findings fixed before the PR opened. The two largest:

- **A pre-existing root defect in the rollup**: the zero-row `named` count was
  an unanchored substring, so a declared server accrued "pointed at and
  ignored" evidence from any play entry it merely prefixes — `context7`
  counted every naming of `context7-docs`. That column feeds
  `felix_ledger_retire` and now the reconciler; it is owner-anchored now,
  through the summary's own reduction.
- **The play-named mount branch died under construction** (above) — it was
  green in the suite only because its fixture hand-wrote a row shape the
  rollup never produces. The committed fixtures now hold every shape the
  pipeline actually writes, and an unconditional-mount mutant fails them.

The method note for whoever weighs review styles: the finder pool proposed 14
substantive claims and construction killed 3 — the survival ratio §0ab called
the evidence the method works, holding again on this diff's own author.

### The first live reconcile read, and what the next session should see

Run against felix's own record, `felix stack reconcile` proposes mounting
`Claude_Browser`, `ccd_session`, and `plugin_playwright_playwright` — all
reached across sessions, none declared, and all three host- or
plugin-provided, which is exactly the case the command's footer names: the
record saying they are used, not an instruction. **Expected next session:**
session-start renders that line once (they are unseen), and never again
unless the record changes. A reconcile line that repeats is a defect — file
it. Whether host-provided servers deserve rows is the founder's call; leaving
them unacted is an answer the machinery now respects.

### The A′ voice, observed on its first session

Held to §0ag's spec: one block at the declaration moment, silence on
mid-session topic words, one finish-line channel. The declaration-moment
route itself was wrong — `harness` → `brainstorming` for a turn that was
mid-delivery of an approved design — and was declined through the real
channel; the tracker reads 4 mandates, 2 answered, both declines citing their
cause. That is the promote loop's training data doing its job.

### Standing

- `tests/run --record-assertions` after any assertion change; 975 on record.
- Review notes not acted on, recorded so nobody re-derives them: a
  non-numeric `FELIX_LEDGER_MIN` silently suppresses unmount proposals (the
  guard errors and skips — over-refusing, the safe direction, and the same
  pattern retire already has); the discover stub carries no pinned sha, so
  the fetch-at-sha branch is still only covered by the real-network path.
- The retire line and the reconcile line can name the same server once, in
  adjacent lines, the first time an unmount is proposed. Accepted
  deliberately: seen-gating makes the steady state retire-only, and
  cross-filtering the two would couple what evidence kept apart.
- Decision C's remaining watch-item from the memo is the weekly
  `felix decisions` read and `felix route --promote` against the misses.

