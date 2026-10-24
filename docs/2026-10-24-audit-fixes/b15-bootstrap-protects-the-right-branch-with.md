# Audit fixes, batch b15: bootstrap protects the right branch with a passable gate

Two findings of the 2026-10-24 audit about `felix bootstrap`. Branch
`claude/audit-b15-bootstrap-protects-the-right-branch-with`, cut from origin/main at 69b51a61
(0.49.307). Engine tier: `engine/harness/lib/bootstrap.sh`, `cmd_bootstrap` in
`engine/harness/felix` (lines 3930-4035), and one paragraph of `README.md`. New parts in 1910-1929.
This file is the whole specification the blind assertions are written from. It says what must be
true, not how. Line numbers are the base's.

## 1. Defects

**C040 (high; both skeptics kept high). `felix bootstrap --yes` makes a branch require the `gate`
check when the CI it wires cannot resolve the project, so the check fails, or never reports, on
every pull request.** The pin (`felix_bs_pin_ref`, bootstrap.sh:140-152) needs the engine
checkout's HEAD on origin's default branch and, when the project lives in that checkout, holding
`projects/<name>`. A stranger's home is a plain clone of someone else's Felix, where `felix new`
leaves `projects/<name>` untracked, so the pin is empty and the workflow gets `{{FELIX_REF}}`
(felix:3959-3964, 4002-4004). Protection requiring `gate` is then PUT whatever happened to the pin
or the workflow (felix:4015-4023). Even a filled-in sha fails: CI's home is the Felix checkout
(resolve.sh:184-203), which must hold `projects/<name>` (resolve.sh:467-494). *Scenario:* a stranger
follows the README, governs a repository and runs `felix bootstrap --yes`; every pull request now
has a required `gate` that fails at checkout whatever the code; collaborators without admin rights
cannot merge; the admin merges by bypassing. The skeptics' additions, folded in here: with the home
outside the clone (`FELIX_HOME`), the pin is the clone's HEAD with no project in it and nothing
warns; with an engine checkout that has no GitHub remote the workflow is skipped
(felix:3998-3999) and protection still requires a check no workflow produces; protection is applied
before the workflow is on the default branch, so other pull requests wait on a check that never
reports. The hint at felix:4004 ("set the full sha of a commit on <repo>'s default branch") cannot
be followed by a stranger.

**C095 (medium; the skeptic kept medium). Bootstrap protects the checked-out branch, reads any
failed protection read as "not protected" and PUTs a whole body over what is there, and says the
labels are missing or created without knowing.** `branch` is `git symbolic-ref --short HEAD`, else
`main` (felix:3937). `_felix_bs_have_protection` (bootstrap.sh:64-66) is true only on exit 0, so a
403, a 404 for a missing branch, a network error or bad auth reads as unprotected, and the PUT
(felix:4018-4019) replaces the rule with `enforce_admins:false` and no reviews. `gh label list`
runs at gh's default limit of 30 (bootstrap.sh:61-63), and `created 5 labels` prints whatever the
five creates returned (felix:4007-4013). `--yes` exits 0 after a `FAILED` line. *Scenario:* a
session in a worktree on `claude/adopt-x` runs `felix bootstrap --yes`; GitHub protects
`claude/adopt-x`, main stays open, and the commissioning `baseline` row (run from the session's
checkout) later reads done. Or a flaky read against a main that requires reviews drops them.
*Correction (skeptic):* the overwrite needs a failing read and then a passing PUT, so it is narrower
than the auditor said, and real when it happens; the plan line names the branch it means.

Both reproduced on this tree on 2026-10-24 in a scratch fixture shaped as F1 below (section 6).

## 2. Required behaviour

Terms, used by every item:

- **R**: the repository holding the directory bootstrap runs in (`felix_repo_root "$PWD"`), a
  worktree included. **S**: R's slug as `felix_repo_slug` reads it today. **S empty** is "no
  GitHub remote".
- **N**: the base name of the project directory that governs R.
- **E**: the engine checkout `felix_engine_source` answers, as today. **F**: E's origin slug, the
  value of the `felix repo:` line (empty when that line reads `none, ...`). **P**: the pin,
  `felix_bs_pin_ref`'s answer, unchanged; the value of `felix ref:` when it is a sha.
- **D**: the value of the top-level `default_branch` key in the JSON that `gh api repos/S` prints.
  The same key inside a nested object (a fork's `parent` or `source`) is not D.
- **gwf**: `felix_gate_workflow`'s file name (`gate.yml` unless project.json names another).
- **CI resolves the project**: F is non-empty, P is non-empty, and
  `git -C E cat-file -e P:projects/N/project.json` exits 0.
- **The workflow is on the default branch**: `git -C R cat-file -e
  refs/remotes/origin/D:.github/workflows/gwf` exits 0 (as R's clone last fetched it).
- **The workflow is filled**: that file's text does not contain `{{FELIX_REF}}`.
- **Ready**: all three hold.
- **A write**: a gh call that changes GitHub: `gh api` with `-X` or `--method` other than GET, or
  `gh label create`.
- **gh's message**: the first line gh printed on stderr; `exit N` when it printed none.
- **A row**: a line `  [M] NAME  TEXT` as today, M one of `x` (done), ` ` (outstanding), `?` (could
  not be read, new), or the existing `[-] github` line.

### A gate CI can pass (C040)

- **B1. The `ci project:` line.** Every run, plan or `--yes`, with or without S, prints as the line
  directly after `felix ref:` a line starting `ci project:  `. When CI resolves the project its
  value starts `projects/N`. Otherwise it starts `none: `, then the first reason that applies:
  `Felix has no GitHub remote for CI to fetch` (F empty), `no commit is pinned` (P empty), or
  `the pinned commit does not hold projects/N`; then `; ` and a remedy that names `projects/N` and
  the word `fork`: commit projects/N to the default branch of a Felix repository on GitHub you can
  push to (from a clone of someone else's Felix, a fork that the engine checkout's origin names),
  then re-run. The blank line that followed `felix ref:` follows this line. The `repo:`,
  `ecosystem:`, `felix repo:` and `felix ref:` lines are unchanged.
- **B2. Held back: CI cannot resolve the project.** When S is non-empty, D was read, the protection
  read (B13) is b or c, and CI does not resolve the project: the protection row is `[ ]` and holds
  `held back` and `CI cannot resolve N`. `--yes` makes no protection write and prints a line
  starting `  skipped    protection (` that holds `CI cannot resolve N`.
- **B3. Held back: the workflow is not on the default branch.** As B2 when CI resolves the project
  but the workflow is not on the default branch; the reason holds
  `.github/workflows/gwf is not on origin/D`. A workflow `--yes` writes in the same run is not on
  it. This is a wait, not a failure (B18).
- **B4. Held back: the workflow on the default branch still reads the placeholder.** As B2 when the
  workflow is on the default branch but not filled; the reason holds `still reads {{FELIX_REF}}`.
  The reasons apply in the order B2, B3, B4; the first that applies is the one printed.
- **B5. Ready and unprotected.** `--yes` makes exactly one protection write,
  `gh api -X PUT repos/S/branches/D/protection --input -`, whose standard input, with every blank
  and line break removed, is today's body byte for byte:
  `{"required_status_checks":{"strict":false,"contexts":["gate"]},"enforce_admins":false,"required_pull_request_reviews":null,"restrictions":null,"allow_force_pushes":false,"allow_deletions":false}`.
  On exit 0 it prints `  protected  D requires the gate`.
- **B6. Required but unpassable.** When the protection row is `[x]` and the run is not ready, the
  output holds a line containing `cannot pass` and the B2-B4 reason that applies, and does not hold
  `Baseline already in place.`, even when every row is `[x]`. Plan exits 0; `--yes` makes no
  protection write and exits 1. With every row `[x]` and the run ready, `Baseline already in
  place.` prints as today.
- **B7. The line after a written workflow.** When `--yes` writes the workflow and CI does not
  resolve the project, the line directly after `  wrote      .github/workflows/gwf (review, then
  commit it)` holds `projects/N`; when the ref written is the placeholder it also holds
  `{{FELIX_REF}}` (a commit on F's default branch that holds projects/N). The file written, its
  `repository:` and its `ref:`, is what today's renderer writes.
- **B8. No Felix remote.** With F empty, `  skipped    ci-workflow (Felix has no remote for CI to
  fetch)` prints as today, and protection is held back by B2.
- **B9. The README says when protection is set.** In `README.md`, the paragraph that names
  `felix bootstrap --yes` (the wall paragraph, lines 359-363) says: the rule goes on the
  repository's default branch; bootstrap sets it only once CI can resolve the project, meaning
  `projects/<name>` is committed on the default branch of the Felix repository the workflow checks
  out and the workflow is on the repository's default branch; from a plain clone of this repository
  that means forking Felix, pointing the clone's origin at the fork and pushing `projects/<name>`
  to its default branch, with a `FELIX_DEPLOY_KEY` secret in the governed repository when the fork
  is private. Line 273's "Felix can set that up for you" either names that condition or points at
  that paragraph. Checked at review with `grep -n 'fork' README.md` (a hit inside that paragraph)
  and `grep -n 'set that up for you' README.md`; no part asserts it, because the suite's copies
  carry no README (part 0004 copies the harness alone).

### The default branch, read and written honestly (C095)

- **B10. The branch is D.** Every gh call whose path holds `/branches/` names `/branches/D/`,
  whatever R has checked out: another branch in a worktree, or a detached HEAD. The protection row
  names D. The checked-out branch is not read for this.
- **B11. Reading D.** With S non-empty, D is read with `gh api repos/S`, a GET, with none of
  `--jq`, `-q`, `--template`, `-t`, `--paginate`, `--json` (extra `-H` headers are allowed). D is
  read the same whether the answer is on one line or pretty-printed over many, with or without a
  final line break.
- **B12. D unknown.** When that call exits non-zero, or exits 0 with no top-level `default_branch`
  holding a non-empty string: the protection row is `[?]` and holds `could not be read` and
  `default branch`; no gh call holds `/branches/`; `--yes` makes no protection write, prints a line
  starting `  skipped    protection (` and exits 1.
- **B13. Reading the protection.** With `gh api repos/S/branches/D/protection`, a GET, under B11's
  flag limits. Its answer is **a protection** when it holds a `"url"` key whose string value ends in
  `/protection`. Read as:
  - a. exit 0, a protection, and its `required_status_checks` object holds the string `"gate"` as an
    element of `contexts` or as the `context` of an element of `checks`: row `[x]`, text
    `D requires the gate`;
  - b. exit 0, a protection, and no such `"gate"` (no `required_status_checks` at all, or only other
    names such as `gate-lint`; `gate` in a URL, a team or any other key does not count): row `[ ]`,
    text `D is protected but does not require the gate`;
  - c. a non-zero exit with `Branch not protected` in its stdout or its stderr: row `[ ]`, text
    `require the gate on D, block force pushes`;
  - d. anything else: row `[?]` holding `could not be read`, and gh's message when gh exited
    non-zero. That is any other non-zero exit (403 `Upgrade to GitHub Pro or make this repository
    public to enable this feature.`, 404 `Branch not found`, 404 `Not Found`, a network error, 127),
    and an exit 0 whose answer is not a protection (empty, `{}`, not JSON).

  Every answer is read the same on one line or over many, with or without a final line break. The
  `[x]` text no longer says "block force pushes": that is not what was read.
- **B14. Protection writes.** Only `--yes` writes, only when ready (otherwise B2-B4), and at most
  one protection write per run. c leads to B5's PUT. b leads to exactly one
  `gh api -X POST repos/S/branches/D/protection/required_status_checks/contexts --input -` whose
  standard input with blanks removed is `{"contexts":["gate"]}`, and never to a PUT; on exit 0 it
  prints `  protected  D requires the gate`. a and d write nothing; d prints a line starting
  `  skipped    protection (could not be read`. A write that exits non-zero prints a line starting
  `  FAILED     protection on D: ` followed by gh's message, and `--yes` exits 1. No line says
  `admin rights needed` unless gh's message does.
- **B15. Reading the labels.** With S non-empty, with `gh label list --repo S --limit 1000` (none
  of `--json`, `--jq`, `-q`, `--template`, `--search`); each line is a label, its name the first
  tab-separated field, compared whole. The five are `needs-founder`, `needs-architecture`,
  `risk-green`, `risk-yellow`, `risk-red`. All five present: row `[x]`, today's text. Exit 0, fewer
  than 1000 lines and some missing: row `[ ]` naming each missing one. A non-zero exit, or 1000 lines
  or more with some missing (the list may be cut): row `[?]` holding `could not be read`.
- **B16. Label writes.** `--yes` with the row `[ ]`: one
  `gh label create NAME --repo S --color C --description TEXT` for each missing label and none for
  a present one, with today's colours and descriptions (felix:4008-4012). Each create's exit is
  read: 0 prints `  created    label NAME`; non-zero prints a line starting
  `  FAILED     label NAME: ` followed by gh's message, and `--yes` exits 1. With the row `[?]`: no
  create, a line starting `  skipped    labels (could not be read`, exit 1. `created    5 labels`
  is never printed.
- **B17. Plan mode** (no `--yes`) runs only B11's, B13's and B15's reads, writes no file, and exits
  0 whatever it read. With every row `[x]` it ends with `Baseline already in place.` when the run is
  ready, and with B6's line when it is not. With a row `[ ]` or `[?]` it ends with a line holding
  `step(s) outstanding` and `Nothing changed.`, which also holds `could not be read` when a row is
  `[?]`, then `apply with: felix bootstrap --yes`.
- **B18. `--yes` exit status.** 1 when a `FAILED` line printed, a row is `[?]`, protection was held
  back by B2 or B4, or B6 applies. 0 otherwise, which includes B3's wait and S empty. `--yes` goes on
  to apply whenever a row is `[ ]` or `[?]`.
- **B19. No GitHub remote.** With S empty: no gh call at all, and the `[-] github` line as today
  (`no github remote; labels and protection skipped`). B1's line is still printed.
- **B20. No other gh command.** Bootstrap runs only the gh commands of B5, B11 and B13-B16.

## 3. What must not change

- **The pin.** `felix_bs_pin_ref`'s arguments, rules and output (0160: "a source whose HEAD is
  origin's default branch pins that commit, in full" through "a commit on the default branch from
  before the project merged pins nothing"; 0110: "and pins the source checkout's commit once
  origin's default branch holds it", "a project no commit on the default branch holds yet is not
  pinned", "and is pinned once the default branch holds it"). 0110's pin case runs with the home
  outside the engine checkout: its `felix ref:` still prints the sha; only B1's new line says `none`
  there. Whether the pin resolves the project is B1's judgement, apart from the pin.
- **The rendered workflow.** `felix_bs_render_workflow`'s output (0160: "the generated workflow
  checks Felix out at the commit it was given", "and with no commit to give, at the placeholder,
  quoted so YAML reads a string", "every uses: in the gate workflow bootstrap renders names a full
  commit sha, for every stack it can render"; 0140: "the gate workflow bootstrap writes can be
  dispatched"; 0110: "and the gate workflow bootstrap writes checks Felix out at that commit").
- **The header.** `repo:`, `ecosystem:`, `felix repo:`, `felix ref:` and their values (0110 reads
  `felix repo:` and `felix ref:` by label: "bootstrap names the checkout's repo, not the cache's
  absence", "bootstrap with no commit to pin says the workflow gets the placeholder"). The text
  `CI cannot fetch the harness` appears only when F is empty (0110: "and never reports no remote for
  an engine that has one").
- **The ci-workflow and permissions rows.** The workflow counts as present in the working tree, at
  origin/HEAD or at origin/main; it is written only when absent and skipped when F is empty (0130:
  "bootstrap looks for gate.yml when the project names no gate workflow", "and bootstrap looks for
  the workflow the project names"). A refused gate_workflow still dies before anything prints
  (felix:3941; 0130 pins the same refusal for repair).
  settings.json is written only where none exists (0080: "a bootstrapped repository still asks
  before a merge that bypasses checks").
- **What gets written.** The PUT body (`enforce_admins` false, decided at felix:4016-4017); the five
  labels' names, colours and descriptions, which the repair loop and `felix incident` (felix:4820)
  apply.
- **Plan mode and commissioning.** Plan writes nothing and exits 0. `Baseline already in place.` is
  the literal the `baseline` row greps (templates/commissioning.tsv:89 and each
  projects/*/commissioning.tsv, not edited here); 0710 stubs cmd_bootstrap with that line.
- **Other parts' stubs.** Under 0130's gh stub (exit 0, prints nothing, for every bootstrap call)
  bootstrap neither hangs nor fails, and its output still names the workflow file. Under 0110's
  (exit 1 for everything) `--yes` still writes the workflow at the pin and settings.json; its exit
  status, now 1, is not asserted there. 0110's first bootstrap run has no stub and reaches whatever
  gh the machine has; this adds one read there, and nothing asserted depends on gh's answer.
- **Sizes.** felix gets no longer (6734 lines). lib/bootstrap.sh stays under 500 (295). A new
  library, if one is added, stays under 500. tests/run gains two part lines, after b00 makes room;
  part 1040 caps it at 500.
- **Lints and invariants.** 0960 (no `| grep -q` on a producer), 1000 (mktemp under TMPDIR), 1497
  (no gawk-only builtin in lib awk), 1530, and 0650 with the gate's independence check: the engine
  names no project, so new text names no repository (no `LeavesJ`, no `felix-home`). Bash 3.2 and
  5, BWK awk and gawk.

## 4. Assertions

**The gh stub (each part builds its own, at `$T/bin/gh`, first on `PATH` for every run).** It
appends `$*` as one line to `$T/gh.log`; when `--input` is followed by `-`, it saves standard input
to `$T/gh.in.<that line's number>`. It classifies the call: for `api`, METHOD is the value after
`-X` or `--method` (default GET) and PATH the first argument starting `repos/`; GET
`repos/fixture/app` is `repo`, GET `repos/fixture/app/branches/<b>/protection` is `prot`, PUT
`.../protection` is `put`, POST `.../protection/required_status_checks/contexts` is `post`;
`label list` is `list`, `label create` is `create` (NAME is the argument after `create`); anything
else is `other`: logged, `unexpected gh call` on stderr, exit 1. Class K answers with
`$T/ctl/K.out` on stdout, `$T/ctl/K.err` on stderr and exit `$T/ctl/K.rc` (0 when absent). `list`
then prints the first L lines of `$T/ctl/labels`, L the value after `--limit`, else 30 (gh's own
default). `create` exits `$T/ctl/create.NAME.rc` when present and prints `$T/ctl/create.err` only
then. Defaults: `repo` prints `{"default_branch":"main"}`; `prot` is **not protected**: stdout
`{"message":"Branch not protected","documentation_url":"https://docs.github.com/rest/branches/branch-protection#get-branch-protection","status":"404"}`
with no final line break, stderr `gh: Branch not protected (HTTP 404)`, exit 1 (gh's real answer,
read 2026-10-24); `put` and `post` print `{}`; `labels` holds the five as `NAME<TAB>desc<TAB>#ededed`.
It runs under bash 3.2 and 5 (no `case` inside `$( )`).

**Protection answers** (stdout, exit 0):
- **P1**, one line, no final line break (the shape GitHub answered for a protected main):
  `{"url":"https://api.github.com/repos/fixture/app/branches/main/protection","required_status_checks":{"url":"https://api.github.com/repos/fixture/app/branches/main/protection/required_status_checks","strict":true,"contexts":["gate"],"contexts_url":"https://api.github.com/repos/fixture/app/branches/main/protection/required_status_checks/contexts","checks":[{"context":"gate","app_id":15368}]},"required_pull_request_reviews":{"dismiss_stale_reviews":true,"required_approving_review_count":0},"enforce_admins":{"url":"https://api.github.com/repos/fixture/app/branches/main/protection/enforce_admins","enabled":true},"allow_force_pushes":{"enabled":false}}`
- **P2**, pretty-printed with two-space indents and a final line break: `url` as P1, then
  `required_status_checks` with `"strict": false`, `"contexts": [` and `"build",` and `"gate"` each
  on its own line, `]`, and `checks` holding `{ "context": "build", "app_id": null }` and
  `{ "context": "gate", "app_id": null }`, then `"enforce_admins": { "enabled": false }`.
- **P3**, one line: `{"url":"https://api.github.com/repos/fixture/app/branches/main/protection","required_status_checks":{"strict":false,"contexts":["gate-lint"],"checks":[{"context":"gate-lint","app_id":null}]},"required_pull_request_reviews":{"dismissal_restrictions":{"teams":[{"slug":"gate","name":"gate"}]},"required_approving_review_count":1},"enforce_admins":{"enabled":true}}`
- **P4**, one line: `{"url":"https://api.github.com/repos/fixture/app/branches/main/protection","required_pull_request_reviews":{"required_approving_review_count":1},"enforce_admins":{"enabled":true}}`

**Runs.** `( cd DIR && HOME="$T/u" FELIX_HOME=HOME_DIR PATH="$T/bin:$PATH" "$E/engine/harness/felix"
bootstrap [--yes] )`, stdout and stderr captured together, exit status kept, `$T/u` an empty
directory, `FELIX_MEMORY` as the suite exports it. `gh.log` is emptied before each run.

**Fixture F1 (part 1910).** `$T` is the part's directory under `$TMP`; repositories are made with
the suite's fixture git helpers (`_fx_cd`, `_fx_git`) and physical paths. **E** is `$T/felix`:
`git init -b main`, origin `https://github.com/fixture/felix.git` (never fetched), one empty commit,
`refs/remotes/origin/main` at HEAD and `refs/remotes/origin/HEAD` naming it; `$E/engine/harness`
a copy of `$FROOT/harness`, untracked; `$E/projects/app/project.json`
`{"name": "app", "remote_match": "github.com/fixture/app", "gate": "true"}`, untracked. That is
the **stranger** state. **Merged**: `projects/` committed in E and origin/main moved to it. **No
remote**: merged, then `git remote remove origin` and `refs/remotes/origin/main` set back to the
merged commit; restored afterwards (remote, ref, origin/HEAD). **H** is `$T/home-out` holding the
same `projects/app/project.json`. **A fresh G0** is a new repository with origin
`https://github.com/fixture/app.git`, one empty commit, origin/main and origin/HEAD at it; it
resolves to app by remote_match. **G** is G0 plus a committed `.github/workflows/gate.yml` holding
`name: gate` and `.claude/settings.json` holding `{"permissions":{"deny":["Read(./.env)"]}}`, with
origin/main at that commit. **Gp** is G whose gate.yml also holds the line
`          ref: '{{FELIX_REF}}'`. **Gx** has no remote and a `.felix` holding `app`. HOME_DIR is E
unless H is named. Controls are marked **(control)**: true before the fix and after it.

**Part 1910**

- **A1 (B1).** Stranger, plan from G: exit 0; the line after `felix ref:` starts
  `ci project:  none: ` and holds `no commit is pinned`, `projects/app` and `fork`. The `felix ref:`
  value holds `{{FELIX_REF}}` (control).
- **A2 (B2, B17).** The same run: the line starting `  [ ] protection` holds `held back` and
  `CI cannot resolve app`; no `Baseline already in place.`; gh.log holds no write.
- **A3 (B2, B18).** Stranger, `--yes` from G: gh.log holds no write; a line starts
  `  skipped    protection (` and holds `CI cannot resolve app`; exit 1.
- **A4 (B1).** Stranger, HOME_DIR H, plan from G: the `felix ref:` value is E's HEAD (control); the
  `ci project:` value starts `none: ` and holds `the pinned commit does not hold projects/app` and
  `fork`.
- **A5 (B2, B18).** The same with `--yes`: no write; exit 1.
- **A6 (B7).** Stranger, `--yes` from a fresh G0: the written gate.yml's line after
  `repository: fixture/felix`, with blanks removed, is `ref:'{{FELIX_REF}}'` (control); the line
  after the one starting `  wrote      .github/workflows/gate.yml` holds `{{FELIX_REF}}` and
  `projects/app`; gh.log holds no protection write.
- **A7 (B7).** Stranger, HOME_DIR H, `--yes` from a fresh G0: the written ref is E's HEAD
  (control); the line after the `wrote` line holds `projects/app`.
- **A8 (B6, B18).** Stranger, G, `prot` answering P1: plan exits 0, has no
  `Baseline already in place.`, and has a line holding `cannot pass` and `CI cannot resolve app`.
  `--yes`: no write; exit 1.
- **A9 (B1, B2).** Merged, plan from G: the `ci project:` value starts `projects/app`; the
  protection row starts `  [ ] protection`, holds `require the gate on main` and not `held back`.
- **A10 (B5, control).** Merged, `--yes` from G: gh.log holds exactly one write, a PUT whose path is
  `repos/fixture/app/branches/main/protection`, its saved input with blanks and line breaks removed
  equal to B5's body; the output holds `  protected  main requires the gate`; exit 0.
- **A11 (B6, control).** Merged, G, `prot` answering P1: plan prints `Baseline already in place.`,
  exits 0, and gh.log holds no write.
- **A12 (B3, B18).** Merged, a fresh G0, plan: the protection row holds `held back` and
  `.github/workflows/gate.yml is not on origin/main`. Then `--yes`: gate.yml is written, its ref
  line with blanks removed `ref:'<E's HEAD>'` (control); no protection write; a line starts
  `  skipped    protection (` and holds `is not on origin/main`; exit 0.
- **A13 (B3, B5, control).** That G0 with its files committed and origin/main moved to the commit,
  `--yes` again: one PUT to `repos/fixture/app/branches/main/protection`;
  `  protected  main requires the gate`; exit 0.
- **A14 (B4, B18).** Merged, Gp: plan's protection row holds `held back` and `{{FELIX_REF}}`;
  `--yes` makes no write, prints a line starting `  skipped    protection (` holding
  `still reads {{FELIX_REF}}`, and exits 1.
- **A15 (B8, B2).** No remote, `--yes` from G: the `felix repo:` value is
  `none, CI cannot fetch the harness` (control); the `ci project:` line holds `Felix has no GitHub
  remote for CI to fetch`; no write; exit 1. From a fresh G0: `  skipped    ci-workflow (Felix has
  no remote for CI to fetch)` (control) and no write.
- **A16 (B19).** Merged, plan from Gx: gh.log is empty and the `[-] github` line prints (control);
  a line starts `ci project:  projects/app`.

**Fixture F2 (part 1920).** E merged as in F1 (its own copy), HOME_DIR E; G as in F1, and
`refs/remotes/origin/trunk` at G's origin/main; **W** a worktree of G on branch `claude/adopt-x`;
the gh stub as above.

**Part 1920**

- **A17 (B10).** From W, `--yes`: every gh.log line holding `/branches/` holds `/branches/main/`;
  none holds `adopt-x`; one PUT to `repos/fixture/app/branches/main/protection`. Plan from W: the
  protection row holds `main` and not `adopt-x`.
- **A18 (B10, B11).** From W, `repo` answering, on one line with no final break,
  `{"default_branch":"main","fork":true,"parent":{"full_name":"up/app","default_branch":"trunk"},"source":{"full_name":"up/app","default_branch":"trunk"}}`:
  every `/branches/` call names `/branches/main/`.
- **A19 (B10, B11).** From G at a detached HEAD, `repo` answering
  `{` / `  "name": "app",` / `  "default_branch": "trunk"` / `}` on four lines with a final break:
  every `/branches/` call names `/branches/trunk/`, and `--yes` makes one PUT to
  `repos/fixture/app/branches/trunk/protection`.
- **A20 (B12, B17, B18).** `repo` exiting 1 with stderr `error connecting to api.github.com`: plan
  exits 0; a line starts `  [?] protection` holding `could not be read` and `default branch`; no
  gh.log line holds `/branches/`; no `Baseline already in place.`; a line holds `could not be read`
  and `Nothing changed.`. `--yes`: no write; a line starts `  skipped    protection (`; exit 1.
- **A21 (B12).** `repo` exiting 0 with `{"message":"Moved Permanently"}`: plan's protection row
  starts `  [?] protection`; no gh.log line holds `/branches/`.
- **A22 (B13, B14, B18).** Each in its own runs, `prot` answering: (1) exit 1, stdout
  `{"message":"Upgrade to GitHub Pro or make this repository public to enable this feature.","documentation_url":"https://docs.github.com/rest/branches/branch-protection#get-branch-protection","status":"403"}`,
  stderr `gh: Upgrade to GitHub Pro or make this repository public to enable this feature. (HTTP
  403)`; (2) the same shape with `Branch not found` and 404; (3) with `Not Found` and 404; (4) exit
  1, stdout empty, stderr `error connecting to api.github.com`; (5) exit 0, empty; (6) exit 0,
  `{}`; (7) exit 127, stderr `gh: command not found`. Plan: a line starts `  [?] protection` and
  holds `could not be read`, and for (1) the output holds `Upgrade to GitHub Pro`. `--yes`: no
  write; exit 1.
- **A23 (B13, control).** `prot` answering P1: the protection row starts `  [x] protection`; plan
  prints `Baseline already in place.`; `--yes` makes no write.
- **A24 (B13, control).** `prot` answering P2: the row starts `  [x] protection`; no write.
- **A25 (B13, B14).** `prot` answering P3: plan's row starts `  [ ] protection` and holds
  `does not require the gate`; `--yes` makes exactly one write, a POST whose path is
  `repos/fixture/app/branches/main/protection/required_status_checks/contexts`, its saved input with
  blanks removed `{"contexts":["gate"]}`; no PUT; `  protected  main requires the gate`; exit 0.
- **A26 (B14, B18).** `prot` answering P4 and `post` exiting 1 with stdout
  `{"message":"Required status checks not enabled","status":"404"}` and stderr
  `gh: Required status checks not enabled (HTTP 404)`: `--yes` makes one POST and no PUT; a line
  starts `  FAILED     protection on main: ` and holds `Required status checks not enabled`; exit 1.
- **A27 (B14, B18).** Not protected and `put` exiting 1 with stderr
  `gh: Resource not accessible by integration (HTTP 403)`: a line starts
  `  FAILED     protection on main: ` and holds `Resource not accessible by integration`; no line
  holds `admin rights needed`; exit 1.
- **A28 (B15).** `labels` holding `old-1` to `old-30` and then the five: the labels row starts
  `  [x] labels`; every `label list` line in gh.log holds `--limit 1000`; `--yes` makes no
  `label create`.
- **A29 (B15, B16).** `labels` holding `needs-founder`, `needs-architecture` and `risk-green` only:
  plan's row starts `  [ ] labels` and holds `risk-yellow` and `risk-red`. `--yes`: exactly two
  `label create` lines, one for `risk-yellow` holding `--color FBCA04`, one for `risk-red` holding
  `--color B60205`, each holding `--repo fixture/app`; the output holds
  `  created    label risk-yellow` and `  created    label risk-red`, and not `created    5 labels`.
- **A30 (B16, B18).** As A29 with `create.risk-red.rc` 1 and `create.err`
  `HTTP 422: Validation Failed`: the output holds `  created    label risk-yellow`, a line starting
  `  FAILED     label risk-red: ` that holds `Validation Failed`, and no `created    label risk-red`;
  exit 1.
- **A31 (B15, B18).** `list` exiting 1 with stderr `error connecting to api.github.com`: plan's row
  starts `  [?] labels` and holds `could not be read`; `--yes` makes no `label create`; exit 1.
- **A32 (B15).** `labels` holding 1000 lines `other-1` to `other-1000`: the row starts
  `  [?] labels`; `--yes` makes no `label create`.
- **A33 (B17, control).** For every plan run of this part: that run's gh.log holds no `-X`, no
  `--method` and no `label create`, and `git status --porcelain` in G and in W prints nothing after
  it.
- **A34 (B20, B11, B15, control).** Across every run of this part, every gh.log line is `api` with
  path `repos/fixture/app` or `repos/fixture/app/branches/<b>/protection` (GET or PUT) or ending
  `/protection/required_status_checks/contexts` (POST), or `label list`, or `label create`; no line
  holds `--jq`, `--json`, `--template`, `--paginate` or `--search`, and no word is `-q` or `-t`.

## 5. Parts

- `1910-bootstrap-passable-gate-blind.sh`: A1-A16, fixture F1.
- `1920-bootstrap-default-branch-and-reads-blind.sh`: A17-A34, fixture F2.

Both are written blind from this file, each builds its own fixture, and each gets one line in
tests/run in number order before 9990's. Neither joins a group in tests/groups.tsv.

## 6. Out of scope

- **The pin inside a workflow already committed.** Bootstrap judges its own pin P; beyond B4's
  placeholder it does not read back the `ref:` of the workflow on the default branch (an older pin,
  one a person edited). A project's own gate_workflow cannot be parsed for one, and neither finding
  names it. Follow-up.
- **A private Felix fork with no `FELIX_DEPLOY_KEY`** in the governed repository: CI fails at the
  Felix checkout, loudly, naming the key; bootstrap reads no secrets (`gh secret` is an ask row in
  the permissions it writes). B9's README text names the key.
- **Admins can bypass.** `enforce_admins` stays false (decided, felix:4016-4017). The scenario's
  "the admin merges by bypassing" is that decision's cost, not this batch's.
- **The commissioning `baseline` row reads held, not unknown, when bootstrap could not read
  GitHub.** It greps one literal; telling them apart needs a change to templates/commissioning.tsv
  and every projects/*/commissioning.tsv (felix's is bound to the commission grant, the founder's
  re-stamp), and neither finding names it.
- **templates/setup.tsv's `risk-labels` check** reads `gh label list` at gh's default 30 through
  `| grep -q`: the same limit in a template table and its per-project copies. C095 names
  bootstrap's reader (bootstrap.sh:61-63). Follow-up.
- **`felix_repo_slug` passes a non-GitHub origin URL through** (lib/detect.sh:365-368), so bootstrap
  asks gh about it; after this batch those reads are `[?]` and nothing is written. The reader has
  many callers, and lib/setup.sh already holds the right three-way classifier. Follow-up.
- **A gh call that hangs.** Bootstrap waits on it as every gh reader in the engine does; neither
  finding names it; a person runs bootstrap and can interrupt it. Time limits are b01's class.
- **`GH_HOST` or `GH_REPO` in the caller's environment**: as today.
- **No GitHub remote prints `Baseline already in place.`** with no protection: there is no branch to
  protect (B19 keeps it).
- **A project that names its own gate_workflow.** The precondition is about the workflow bootstrap
  renders; a project's own may fetch Felix otherwise. No project declares one
  (`grep -l gate_workflow projects/*/project.json` finds none on the base).
- **Publishing.** The public snapshot (0.49.232) carries today's bootstrap; strangers get this at
  the founder's next publish (b22). Landing this batch does not need it.

**Not fixed: not a defect.** None. Both hold on this tree. Reproduced on 2026-10-24 in a scratch
fixture shaped as F1, against the base's CLI and a logging gh stub: in the stranger state, plan
printed `felix ref:   none: ... {{FELIX_REF}} to fill` and `[ ] protection   require the gate on
main`, and `--yes` from a fresh repository wrote gate.yml with `ref: '{{FELIX_REF}}'`, then
`protected  main requires the gate`, exit 0. From a worktree on `claude/adopt-x` it PUT
`repos/fixture/app/branches/claude/adopt-x/protection`. With the home outside E it pinned E's HEAD,
which holds no projects/app. With no origin on E it printed `skipped    ci-workflow` and then
`protected  main requires the gate`. With the protection read answering 403 it PUT anyway and
printed `FAILED     branch protection (admin rights needed on fixture/app)`, exit 0. With the five
labels at positions 31-35 it created all five and printed `created    5 labels`. With P1 and the
stranger state it printed `Baseline already in place.`. Read the same day, read-only:
`LeavesJ/felix-home` answers the protection read with 403 `Upgrade to GitHub Pro ...` (today read
as unprotected); `LeavesJ/Elenchus` answers P1's shape with `enforce_admins` true and required
reviews, which today's PUT after a failed read would replace.

## 7. Founder PR

None. The batch changes no `.github/workflows` file, no deny or escape row, no commissioning table
or the commission grant, and publishes nothing.
