### 2026-09-23 — the public README rewritten for a general reader first, with the Felix mark, and checked against the code three times

**No engine change.** `README.md`, a new `assets/` and
`projects/felix/snapshot.sh`, on `claude/public-readme-styling-e3d61b`.

**What changed.**

- **One README, layered by depth.** The founder asked whether a README can
  offer versions for different readers. GitHub renders one README with no
  toggle; the only in-page switch is an exclusive `<details name>` accordion,
  which hides what it doesn't show. The READMEs he named (OpenClaw, Hermes
  Agent, Stratum V2) keep one README and send depth elsewhere, and Hermes'
  parallel translations have already drifted. So: one file, general reader
  first, reference collapsed.
- **Order, from his brief** (keep the causal structure, drop the specialist
  words, story before vocabulary): the failure; how the Stop hold works, with a
  diagram of its real exit; "One change, start to finish", a money-transfer
  story with each step marked built or not, closing on the loop that is the
  trust plane and the part of the capability plane that exists; then guards,
  glossary, Try it, the CI comparison (couldn't-check and staleness first, as
  the market map says), limits, Status, direction, Install, Reference.
- **`assets/`.** The mark and the mark-plus-name lockup, light and dark, redrawn
  as vector from his brand sheet. The wordmark is outlined from Montserrat
  (OFL), with the sheet's square i-dot. The generator was session scratch and
  is not committed. The sheet's "Intelligence under control." and "Resolver"
  labels were left out: an unsourced slogan is what the README's register
  rules out.
- **`snapshot.sh` publishes `assets/`** where the source has it, and stages it
  only where one side has it, so both historic self-tests still MATCH. A full
  dry run from a scratch home whose main was this branch staged `assets/` and
  the README; audit clean (8 acknowledged, none open), no new secret.

**True of the engine, found by the review and now stated in the README:**

- The platform's `stop_hook_active` is shared by every Stop hook, so another
  hook's block spends Felix's one hold, and the release after a hold is not
  recorded.
- security-guidance, which commissioning installs, runs an `asyncRewake` Stop
  hook whose source says Claude Code sets `stop_hook_active` while it runs.
  Untested; a chip was raised to measure it.
- Exceptions are read only for Felix's own project; a product's rules live in
  the home, where no merge of the product sees an edit.
- `felix automerge --enable` turns on GitHub auto-merge, which skips
  `felix merge`. `ready --fix` re-enables plugins a route names.
- An edit to a gate script, or a skipped test, is not an escape.
- A probe's value changing at the same count and state does not stale a pass.

**Traps paid for this session.**

- **The suite reads the README.** `tests/run` near the audit section pins the
  Try it section: "held" exactly once there, `felix gate` with "straight away"
  only beside a condition, and several phrases verbatim. A reviewer said
  nothing reads the README; the snapshot dry run failed on it.
- `gh api markdown`: `mode=gfm` renders alerts and hard line breaks,
  `mode=markdown` renders anchors and no alerts, and neither runs mermaid or
  the themed `<picture>`.
- A plain-language rewrite drifts into overclaim. Three rounds of a
  fact-checker reading the engine found about thirty sentences that said more
  than the code does, most of them written to be simpler.

**Open.**

- **Publishing** is the snapshot command after the merge (§0bm), then a pull
  request on LeavesJ/Felix.
- **The social preview** (1280x640, made in the session) is set by hand in
  LeavesJ/Felix's settings.
- **Numbers the reviewers asked for:** what followed the roughly 76 holds with
  no rerun, the 3 holds outside the three causes, and how many deny firings
  were in earnest ("a handful").
