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
(felix:3959-3964, 4002-4004); protection requiring `gate` is PUT whatever happened to either
(felix:4015-4023). Even a filled-in sha fails: CI's home is the Felix checkout (resolve.sh:184-203),
which must hold `projects/<name>` (resolve.sh:467-494). *Scenario:* a stranger follows the README
and runs `felix bootstrap --yes`; every pull request has a required `gate` that fails at checkout;
collaborators without admin rights cannot merge. The skeptics' additions: with the home outside
the clone (`FELIX_HOME`) the pin is the clone's HEAD with no project in it; with no GitHub remote on
the engine checkout the workflow is skipped (felix:3998-3999) and protection still requires a check
no workflow produces; protection is applied before the workflow is on the default branch. The hint
at felix:4004 ("set the full sha of a commit on <repo>'s default branch") cannot be followed.

**C095 (medium; the skeptic kept medium). Bootstrap protects the checked-out branch, reads any
failed protection read as "not protected" and PUTs a whole body over what is there, and says the
labels are missing or created without knowing.** `branch` is `git symbolic-ref --short HEAD`, else
`main` (felix:3937). `_felix_bs_have_protection` (bootstrap.sh:64-66) is true only on exit 0, so a
403, a 404 for a missing branch, a network error or bad auth reads as unprotected, and the PUT
(felix:4018-4019) replaces the rule with `enforce_admins:false` and no reviews. `gh label list`
runs at gh's default limit of 30 (bootstrap.sh:61-63); `created 5 labels` prints whatever the five
creates returned (felix:4007-4013); `--yes` exits 0 after a `FAILED` line. *Scenario:* a session in
a worktree on `claude/adopt-x` runs `felix bootstrap --yes`; GitHub protects `claude/adopt-x`, main
stays open, and the commissioning `baseline` row (run from that checkout) later reads done. Or a
flaky read against a main that requires reviews drops them. *Correction (skeptic):* that needs a
failing read and then a passing PUT, so it is narrower than the auditor said, and real when it is.

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
- **B9. The README says when protection is set.** In `README.md`, the paragraph that names `felix
  bootstrap --yes` (the wall paragraph, lines 359-363) says: the rule goes on the repository's
  default branch; bootstrap sets it only once `projects/<name>` is committed on the default branch
  of the Felix repository the workflow checks out and the workflow is on the repository's default
  branch; from a plain clone that means forking Felix, pointing the clone's origin at the fork and
  pushing `projects/<name>` to its default branch, with a `FELIX_DEPLOY_KEY` secret in the governed
  repository when the fork is private. Line 273's "Felix can set that up for you" names that
  condition or points at that paragraph. Checked at review with `grep -n 'fork' README.md` and
  `grep -n 'set that up for you' README.md`; no part asserts it (the suite's copies carry no README).

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
  `gh label create NAME --repo S --color C --description TEXT` for each missing label and none for a
  present one, with today's colours and descriptions (felix:4008-4012). Each create's exit is read:
  0 prints `  created    label NAME`; non-zero prints a line starting `  FAILED     label NAME: `
  followed by gh's message, and `--yes` exits 1. With the row `[?]`: no create, a line starting
  `  skipped    labels (could not be read`, exit 1. `created    5 labels` is never printed.
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

- **The pin.** `felix_bs_pin_ref`'s arguments, rules and output, as 0160's and 0110's pin
  assertions read them. 0110's pin case runs with the home outside the engine checkout: its
  `felix ref:` still prints the sha; only B1's line says `none` there.
- **The rendered workflow.** `felix_bs_render_workflow`'s output: the commit it is given, else the
  placeholder quoted as a YAML string, every `uses:` at a full sha (0160, 0140, 0110).
- **The header.** `repo:`, `ecosystem:`, `felix repo:`, `felix ref:` and their values (0110 reads
  the last two by label). `CI cannot fetch the harness` appears only when F is empty.
- **The ci-workflow and permissions rows.** The workflow counts as present in the working tree, at
  origin/HEAD or at origin/main; it is written only when absent and skipped when F is empty (0130,
  for gate.yml and for a named workflow). A refused gate_workflow still dies before anything prints
  (felix:3941). settings.json is written only where none exists (0080).
- **What gets written.** The PUT body (`enforce_admins` false, felix:4016-4017); the five labels'
  names, colours and descriptions, which the repair loop and `felix incident` (felix:4820) apply.
- **Plan mode and commissioning.** Plan writes nothing and exits 0. `Baseline already in place.` is
  the literal the `baseline` row greps (templates/commissioning.tsv:89 and each
  projects/*/commissioning.tsv, not edited here); 0710 stubs cmd_bootstrap with that line.
- **Other parts' stubs.** Under 0130's gh stub (exit 0, prints nothing) bootstrap neither hangs nor
  fails and still names the workflow file. Under 0110's (exit 1 for everything) `--yes` still writes
  the workflow at the pin and settings.json; its exit status, now 1, is not asserted there. 0110's
  first run has no stub and reaches whatever gh the machine has; nothing asserted depends on it.
- **Sizes.** felix gets no longer (6734 lines); lib/bootstrap.sh and any new library stay under
  500; tests/run gains one line per part and stays within part 1040's cap of 500.
- **Lints and invariants.** 0960 (no `| grep -q` on a producer), 1000 (mktemp under TMPDIR), 1497
  (no gawk-only builtin in lib awk), 1530, and 0650 with the gate's independence check: new engine
  text names no repository (no `LeavesJ`, no `felix-home`). Bash 3.2 and 5, BWK awk and gawk.

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
- `1925-bootstrap-judges-the-workflow-ci-runs-blind.sh`: A35-A48, fixture F3 (section 10).

Each is written blind from this file, builds its own fixture, and has one line in tests/run in
number order before 9990's. None joins a group in tests/groups.tsv.

## 6. Out of scope

- **The pin inside a workflow already committed**: withdrawn by the review round (B21, B22).
- **A private Felix fork with no `FELIX_DEPLOY_KEY`** in the governed repository: CI fails at the
  Felix checkout, loudly, naming the key; bootstrap reads no secrets. B9's README text names it.
- **Admins can bypass.** `enforce_admins` stays false (decided, felix:4016-4017).
- **The commissioning `baseline` row reads held, not unknown, when bootstrap could not read
  GitHub.** It greps one literal; telling them apart changes templates/commissioning.tsv and every
  projects/*/commissioning.tsv (felix's is bound to the commission grant).
- **Follow-ups.** templates/setup.tsv's `risk-labels` check reads `gh label list` at gh's default 30
  through `| grep -q`, in a template table and its copies. `felix_repo_slug` passes a non-GitHub
  origin URL through (lib/detect.sh:365-368); those reads are `[?]` here and nothing is written.
- **A hung gh call** waits like every engine gh reader (b01's class); `GH_HOST`, `GH_REPO`: as today.
- **No GitHub remote prints `Baseline already in place.`** with no protection: no branch to protect.
- **A workflow that names no checkout** (a project's own gate_workflow; a Felix home's gate.yml runs
  the Felix in its own tree) is judged from P, or from Dt when P is empty (B24).
- **Publishing.** Strangers get this at the founder's next publish (b22); landing does not need it.

**Not fixed: not a defect.** None. Both reproduced on 2026-10-24 in a fixture shaped as F1 with the
base's CLI and a logging gh stub: the stranger's `--yes` protected main at the placeholder, exit 0;
so did an E with no origin; a worktree on `claude/adopt-x` PUT that branch; a 403 read was PUT over
with `admin rights needed`; labels at 31-35 were created again. Read-only that day,
`LeavesJ/felix-home` answers the protection read with 403 `Upgrade to GitHub Pro ...` and
`LeavesJ/Elenchus` with P1's shape.

## 7. Founder PR

None: no workflow file, deny or escape row, commissioning table or grant changes; nothing published.

## 8. Red

Run 2026-10-25 on the base plus 1910 and 1920, before any engine change (`alone.sh <worktree> bwk`,
macOS awk, bash 3.2): of A1-A34, **27 failed and 7 passed**. No failure named a fixture step; each
detail was a behaviour asked for here. The 7 are the controls A10, A11, A13, A23, A24, A33 and A34,
true before and after the fix. The full record is commit fb109d5c; the review round's is section 10.

## 9. Build notes

- **B4's "filled"** is built as: no line that is not a comment holds `{{FELIX_REF}}`. The renderer
  explains the placeholder in a comment, so the literal reading made A13 impossible.
- **B12** also covers a default branch name outside `A-Za-z0-9._/-`: it goes into a request path.

## 10. Review round (2026-10-26)

The review of 7e916ce8 found three majors of one kind (CI judged from local state, not from the
workflow CI runs); they amend section 2 where named. **The committed workflow** is
`git -C R show refs/remotes/origin/D:.github/workflows/gwf`; it **names a checkout** when a line
that is not a comment has `repository:` as its first word: **Rw** is the first such value, **Yw**
the value of the first `ref:` line after it, quotes removed. **origin/D is in the clone** when
`git -C R rev-parse -q --verify 'refs/remotes/origin/D^{commit}'` exits 0. **Dt** is E's
origin/HEAD, else its origin/main. **Baseline** is `Baseline already in place.`. **Held for a
reason**: a `[ ]` protection row holds `held back` and it; `--yes` makes no protection write, prints
a line starting `  skipped    protection (` holding it, and exits 1; under `[x]` it is B6's reason.

- **B21. CI is judged by the workflow it runs (M1, M2).** When the committed workflow is filled and
  names a checkout, whether CI resolves the project is judged from it, not from P. In order: F
  empty; Rw is not F, case aside: `the workflow on origin/D checks out Rw, not F`; Yw unknown
  (B22); Yw a commit without `projects/N/project.json`: `the workflow on origin/D pins Yw, which
  does not hold projects/N`. Protection is held for the first that applies, and the `ci project:`
  value starts `none: ` and holds it, its remedy naming `.github/workflows/gwf`. Else the value
  starts `projects/N` and the run is ready whatever P is. Unless B24 applies, B1's fork remedy and
  B7's line also say to set the workflow's `repository:` to the fork: each holds `repository:`.
- **B22. A committed pin E cannot vouch for is unknown.** Yw is unknown when it is not 40 hex
  characters, not a commit E has, or not an ancestor of Dt; an Rw holding `${{` is unknown too.
  The `ci project:` value starts `unknown: ` and holds `could not be read` and Yw; no line holds
  `cannot pass` or Baseline; protection is held for that reason (the row may be `[?]` instead of
  `[ ]`), its skipped line holding `could not be read`.
- **B23. origin/D missing from the clone is unknown (M3).** When D and the protection were read (B13
  a-c) and origin/D is not in the clone, the workflow's place on D, its fill and its checkout are
  unknown, never absent: no line holds `is not on origin/D`, `cannot pass` or Baseline; protection
  is held for `origin/D could not be read in this clone` (remedy `git fetch origin`; the row may be
  `[?]`), a reason after F empty and before all others, the `ci project:` line judged from P.
- **B24. An engine checkout off its default branch is not a missing project (M2).** When F is
  non-empty, P is empty and `git -C E cat-file -e Dt:projects/N/project.json` exits 0: a `ci
  project:` value judged from P says the engine checkout is `not on its default branch` (or is
  `behind` it), with the remedy to check it out and pull, and names no `fork`; a committed, filled
  workflow that names no checkout is judged from Dt, not P, so nothing is held back for it, B6 does
  not apply, and with every row `[x]` Baseline prints. With P empty and no Dt, it is B22's unknown.
- **B17, B18 amended.** With every row `[x]`, plan ends with B22's or B23's line when one applies.
  `--yes` exits 1 on B21-B23's holds; B3's wait still exits 0. B9's sentence holds once B21 does.

**Fixture F3 (part 1925).** E as F1's stranger (its own copy, h0 its commit), HOME_DIR E; G1 a fresh
G0; section 4's gh stub. **r0**: `--yes` from G1 renders gate.yml at `repository: fixture/felix`
and the placeholder (control). Then E's origin becomes `https://github.com/stranger/felix.git`,
projects/ is committed (m1) and origin/main moved there; G1's gate.yml is set at (Rw, Yw), only its
first `repository:` line and the `ref:` after it, and landed. **R3**: on master, origin fixture/app,
gate.yml (`name: gate`) and settings.json committed, origin/master and origin/HEAD at it, no
origin/main; gh answers D main. "The value" is the `ci project:` value; "no write" as section 4.

- **A35 (B21, M1).** (fixture/felix, m1), plan: `felix repo:` is `stranger/felix` and `felix ref:`
  m1 (control); the value starts `none: ` and holds `checks out fixture/felix, not stranger/felix`.
- **A36 (B21).** Its row starts `  [ ] protection` and holds `held back` and that text; `--yes`: no
  write, a `  skipped    protection (` line holding `checks out fixture/felix`, exit 1.
- **A37 (B21, B6).** P1: plan exits 0, no Baseline, a line holding `cannot pass` and `checks out
  fixture/felix`; `--yes`: no write, exit 1.
- **A38 (B21).** (stranger/felix, h0): the value starts `none: ` holding `which does not hold
  projects/app`; `--yes`: no write, a skipped line holding it, a line holding h0 and it, exit 1.
- **A39 (B21, control).** (stranger/felix, m1): the value starts `projects/app`; `--yes` makes one
  PUT to `repos/fixture/app/branches/main/protection`, `  protected  main requires the gate`, exit 0.
- **A40, A41 (B21, M2).** E on a new branch with one unpushed commit u, P1: `felix ref:` holds
  `{{FELIX_REF}}` (control); the value starts `projects/app`; plan prints Baseline, no `cannot
  pass`, exit 0; `--yes`: no write, exit 0. A41, the same unprotected: that one PUT, exit 0. E then
  returns to main.
- **A42 (B22).** (stranger/felix, `0123456789abcdef0123456789abcdef01234567`), then (stranger/felix,
  u): plan, P1: exit 0, no Baseline or `cannot pass`, the value starts `unknown: `, a line holds
  `could not be read` and Yw; `--yes` unprotected: no write, a skipped line holding it, exit 1.
- **A43 (B23, M3).** R3, P1: plan exits 0, holds `origin/main could not be read`, and none of
  `cannot pass`, `is not on origin/main`, Baseline; `--yes`: no write, exit 1.
- **A44 (B23, M3).** R3 unprotected: the row starts `  [?] protection`, or `  [ ] protection` with
  `held back`, and holds `origin/main could not be read`; neither run holds `is not on origin/main`;
  `--yes`: no write, a skipped line holding `origin/main could not be read`, exit 1.
- **A45 (B23, control).** R3 with `refs/remotes/origin/main` set at its HEAD, P1: Baseline, exit 0.
- **A46 (B21, M1).** r0's value, and the line after its `wrote` line, each hold `repository:`.
- **A47, A48 (B24, M2).** R3, E's main one unpushed commit ahead (pin empty: control), P1: the value
  holds `not on its default branch`, not `fork`; plan: Baseline, no `cannot pass`, exit 0; `--yes`:
  no write, exit 0. A48, unprotected: one PUT, `  protected  main requires the gate`, exit 0.

**Red (review round).** 2026-10-27, 8ad29cdf (engine as 7e916ce8) plus this round's 1925 under
`alone.sh <worktree> bwk`: of A35-A48, **12 failed and 2 passed**, the controls A39 and A45. No
detail named a fixture step; each was a behaviour asked for here.
