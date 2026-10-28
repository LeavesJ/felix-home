# Audit wave 2: documentation is not a frontend, contract, 2026-10-28

Found live on 2026-10-28, while wave 1 (#469) waited to land. This file is the contract for the
fix. It goes into wave 2 (`claude/audit-wave-2`) from the side branch `claude/audit-wave-2-docs`.

## 1. What happened

- #467 landed at 05:21Z with a pitch deck: `strategy/applications/deck/2026-11-speedrun-deck.html`
  and `strategy/applications/deck/deck.css`.
- Felix's frontend test (`_felix_frontend_assets`, lib/detect.sh) counts tracked files ending
  `.js`, `.jsx`, `.ts`, `.tsx`, `.vue`, `.svelte`, `.css`, `.sass` or `.scss`. It calls the
  checkout a frontend at `FELIX_FRONTEND_MIN` (3).
- Before #467 the home tracked two such files, both documentation:
  - `docs/episodes/method/workflow.js`;
  - `docs/outreach/2026-10-22-linkedin/figures/fig.css`.
  The deck's CSS made three.
- At 07:28:04Z a session started in the home's own checkout. Session start adopts every
  detected capability the project has not declared (`felix_undeclared`, then
  `felix_adopt_capability`). It wrote three files, all at that second:
  - `frontend` into `projects/felix/capabilities`;
  - a `DECLARED` stack row for the frontend-design plugin;
  - a header-only `projects/felix/setup.tsv`.
- Those are commission tables. The policy hash moved off the founder's grant (2798bb0f), so
  the commission receipt read stale.
- From then on `felix merge` refused every pull request: #468 at 11:06Z, #469 at 14:26Z. The
  only remedies were the founder's: re-commission, or remove the adoption.
- Felix has no product frontend. Its web files are a deck, figures for a post, and a page in a
  method write-up.

## 2. Required behaviour

- **F1. Documentation and presentations are not a frontend.**
  - A tracked file is not counted as a web asset for frontend detection when any directory
    component of its path, compared without regard to case, is one of: `docs`, `doc`,
    `documentation`, `deck`, `decks`, `slides`.
  - A component is a whole directory name. `docs-viewer/`, `mydocs/` and a file named
    `docs.css` still count.
  - The file's own name is never a directory component.
- **F2. Nothing else in detection changes.**
  - A `package.json` at the root still detects `frontend`.
  - Assets elsewhere still count, and `FELIX_FRONTEND_MIN` still sets the threshold.
  - Every other capability is detected as before.
  - The fallback used when the checkout is not a git repository applies the same rule.
- **F3. Felix's own tree detects no frontend.**
  - A checkout holding exactly the four web files listed below detects no `frontend`, so
    session start adopts nothing for it:
    - `docs/episodes/method/workflow.js`;
    - `docs/outreach/2026-10-22-linkedin/figures/fig.css`;
    - `strategy/applications/deck/deck.css`;
    - `engine/harness/templates/monitor.html` (not an asset by extension).
  - Its other capabilities (`ci`, `tests`) are unchanged.

## 3. What must not change

- Every part that pins detection: 0230, 0240, 0250, 0370, 0380, 0480, 0580, 0590, 0680 and 0730,
  and any other part that greps `frontend`.
- Adoption itself (session start, `felix adopt`) and the commission. This contract fixes what is
  detected, not what is done with it.

## 4. Assertions

New part `2160-docs-are-not-a-frontend-blind.sh`, written from this contract alone. Each name
starts `W2D`. Red first. At least these cases, each in a fresh git fixture with tracked files only:
- **F3:** the four files above, plus a `tests/` directory. `felix_detect` prints no `frontend`
  and still prints `tests`.
- **F1:**
  - three `.css` files under `docs/a/`, `Docs/b/` and `DOCUMENTATION/c/`: no `frontend`;
  - three `.js` files under `slides/`, `deck/x/` and `decks/`: no `frontend`.
- **F1 controls:**
  - three `.css` files under `static/`: `frontend`;
  - three under `docs-viewer/`, `mydocs/` and the root as `docs.css`: `frontend`.
- **F2:**
  - a root `package.json` with no assets: `frontend`;
  - two assets under `static/` and one under `docs/`: no `frontend`;
  - the same with `FELIX_FRONTEND_MIN=2`: `frontend`.
- **Session start:** in a governed fixture home whose own checkout holds the F3 layout, session
  start adopts nothing: `capabilities`, `stack.tsv` and `setup.tsv` are byte for byte as before.

## 5. Found, not this contract's (for a batch of its own)

- **Adoption moves policy unasked.** Session start writes uncommitted edits into the home's
  tracked tables whenever detection finds something undeclared. Those tables are commission
  policy, so any detection change, or any new file pattern in the repository, can stale the
  commission and stop all landing until the founder acts. There is no way to decline a
  detected capability.
- **The same class as b11's rejected finding 3.** The home's checked-out tables are the policy,
  uncommitted edits included.
- **What a batch should decide:** whether adoption may write tables that move the commission,
  and what a decline looks like.
- **b19 rewrites detection** (`_fm_assets`). It is a founder hand merge. F1 must be carried
  into its counting before it lands, or it brings the false positive back.
