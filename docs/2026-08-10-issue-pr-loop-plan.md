# Issue → PR loop implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give Felix the two verbs it is missing — turn a GitHub issue into a scoped brief, and turn a branch into a pull request — closing the two unmet Phase 1 exit criteria ("take an issue", "open PR").

**Architecture:** One new library, `engine/harness/lib/intake.sh`, holding pure rendering functions that take text and emit a brief. The CLI does the I/O: `cmd_brief` fetches the issue (or reads stdin) and calls the renderer; `cmd_pr` assembles a pull request from the branch and calls `gh`. Fetching is separated from rendering so the interesting logic is testable without a network or a `gh` binary — the suite stubs neither today, which is why the repair loop's fetch path has no assertions.

**Tech Stack:** bash, git, `gh`. No jq, no python, no node — the second constitutional invariant.

## Global Constraints

- **Bash and git only.** No jq, no python, no node anywhere in `engine/`.
- **The engine names no project.** Anything under `engine/harness` mentioning a specific project is a bug the gate fails on.
- `engine/harness/lib/intake.sh` is **red tier**; `engine/harness/felix` is **yellow**. Both require a `engine/harness/tests/run` assertion per `evidence.tsv`.
- **A gate that cannot fail is not a gate.** Every assertion is shown failing before the implementation is written.
- Run the suite and commit as one chain: `./engine/harness/tests/run && git commit`. A piped test run masks the exit status and commits a red tree.
- Felix's own red tier is honoured by behaviour: branch, classify, founder approval before merge. Deploying requires a version bump in `engine/.claude-plugin/plugin.json`, because Claude Code caches by version.
- No em dashes are required anywhere; match the surrounding prose style of each file.

---

## File Structure

| File | Responsibility |
|---|---|
| `engine/harness/lib/intake.sh` (create) | Pure functions: render a brief from issue text; assemble a pull request title and body from a branch. No I/O, no `gh`. |
| `engine/harness/felix` (modify) | `cmd_brief` and `cmd_pr`: fetch, flags, exit codes, `gh` invocation. Two new dispatch arms. |
| `engine/harness/tests/run` (modify) | Assertions for both verbs, driven through stdin so no `gh` stub is needed. |

Rendering is split from fetching because it is the only way to test the brief without inventing a `gh` stub harness the suite does not have. It also mirrors `felix incident`, which already reads error text from stdin so the loop works before any observability vendor is wired.

---

### Task 1: The brief renderer

**Files:**
- Create: `engine/harness/lib/intake.sh`
- Test: `engine/harness/tests/run` (new `issue intake` section, after the `repair loop` section ending at the line `printf '\nrisk classification\n'`)

**Interfaces:**
- Consumes: `felix_incident_paths root text` → newline-separated repo-relative paths (from `lib/incident.sh`); `felix_incident_severity proj paths` → `green|yellow|red`.
- Produces: `felix_brief_render proj root title body` → prints the brief to stdout, returns `0` normally and `3` when a red path is implicated.

- [ ] **Step 1: Write the failing test**

Append to `engine/harness/tests/run`, immediately before the line `printf '\nrisk classification\n'`:

```bash
printf '\nissue intake\n'
# Mirrors felix repair exactly: brief on stdout, scope verdict in the exit code.
# unattended.yml already branches on `rc != 3`, so matching that contract is
# what makes the unattended path a workflow edit rather than a rewrite.
mkdir -p "$REPO/src"
printf 'x\n' > "$REPO/src/widget.py"
cp "$REAL_HARNESS/templates/risk.tsv" "$FROOT/projects/widget/risk.tsv"

out="$(cd "$REPO" && bash -c '
  . '"$FROOT"'/harness/lib/incident.sh
  . '"$FROOT"'/harness/lib/intake.sh
  felix_brief_render "'"$FROOT"'/projects/widget" "'"$REPO"'" \
    "the widget renders twice" "src/widget.py double-renders on mount"')"
has "the brief names the file the issue names" "$out" "src/widget.py"
has "and states the tier"                      "$out" "tier"
```

- [ ] **Step 2: Run it and watch it fail**

Run: `cd /Users/a14808/Documents/Felix && ./engine/harness/tests/run 2>&1 | grep -A3 "issue intake"`

Expected: both assertions FAIL, because `intake.sh` does not exist and sourcing it errors.

- [ ] **Step 3: Create the renderer**

Create `engine/harness/lib/intake.sh`:

```bash
# Issue intake.
#
# The guidebook's first exit criterion (p41) is "take an issue", and nothing
# read one. Felix turns an issue into the same shape felix repair produces for a
# CI failure: which files it names, what tier that makes it, what a fix will
# have to prove, and which tool to reach for. Brief on stdout, scope verdict in
# the exit code.
#
# It supplies scaffolding and refuses to supply judgment, the same division the
# repair and incident loops take. Reading an issue is mechanical. Deciding what
# to build is not, and a script that guessed would be believed.
#
# Rendering is separated from fetching so the brief can be produced from text
# that came from anywhere: gh, a paste, a file. No integration is required for
# the loop to work, which matters because the alternative is a loop that only
# exists once somebody finishes wiring an issue tracker.

# Prints the brief. Returns 3 when a red path is implicated, matching
# felix repair's contract so the same callers can branch on it unchanged.
felix_brief_render() {
  local proj="$1" root="$2" title="$3" body="$4"
  local implicated sev

  printf 'title:    %s\n' "$title"

  implicated="$(felix_incident_paths "$root" "$title
$body")"

  if [ -z "$implicated" ]; then
    printf 'files:    none named that exist in this checkout\n'
    printf 'tier:     unknown\n\n'
    printf 'The issue names no file that exists here, so nothing can be scoped\n'
    printf 'from it mechanically. Read it and say which paths it means before\n'
    printf 'starting, because a brief that guessed would be believed.\n'
    return 0
  fi

  printf 'files:\n'
  printf '%s\n' "$implicated" | sed 's|^|  |'

  sev="green"
  [ -f "$proj/risk.tsv" ] && sev="$(felix_incident_severity "$proj" "$implicated")"
  printf 'tier:     %s\n' "$sev"

  if [ "$sev" = "red" ]; then
    printf '\nOUT OF SCOPE. This issue implicates a red path. Escalate rather\n'
    printf 'than starting: approval comes before the work, not after it.\n'
    return 3
  fi
  return 0
}
```

- [ ] **Step 4: Run the tests and watch them pass**

Run: `cd /Users/a14808/Documents/Felix && ./engine/harness/tests/run 2>&1 | grep -A3 "issue intake"`

Expected: `ok the brief names the file the issue names`, `ok and states the tier`.

- [ ] **Step 5: Commit**

```bash
cd /Users/a14808/Documents/Felix
./engine/harness/tests/run && git add engine/harness/lib/intake.sh engine/harness/tests/run && \
git commit -m "feat(intake): render a brief from issue text

Mirrors felix repair: brief on stdout, scope verdict in the exit code.
Rendering is split from fetching so the brief can come from gh, a paste or a
file, and so the interesting half is testable without a gh stub the suite does
not have."
```

---

### Task 2: The red path exits 3, and the play is named

**Files:**
- Modify: `engine/harness/lib/intake.sh`
- Test: `engine/harness/tests/run` (extend the `issue intake` section)

**Interfaces:**
- Consumes: `felix_evidence_check proj base root` → lines of `status <TAB> name <TAB> reason` where status is `met|gap|n/a`; `felix_route_best proj want ctx` → tab-separated fields where field 7 is the play.
- Produces: no new function; `felix_brief_render` gains an evidence section and a play line.

- [ ] **Step 1: Write the failing tests**

Append to the `issue intake` section:

```bash
# The exit code is the contract. unattended.yml reads it before it reads the
# issue, because telling a model what it may not touch after handing it the
# details is the wrong order: by then it has a plan.
mkdir -p "$REPO/.github/workflows"
printf 'on: push\n' > "$REPO/.github/workflows/ci.yml"
chmod -x "$REPO/.github/workflows/ci.yml"
out="$(cd "$REPO" && bash -c '
  . '"$FROOT"'/harness/lib/incident.sh
  . '"$FROOT"'/harness/lib/intake.sh
  felix_brief_render "'"$FROOT"'/projects/widget" "'"$REPO"'" \
    "ci is wrong" ".github/workflows/ci.yml needs a new job"')"; rc=$?
is  "a red path exits 3"           "$rc" "3"
has "and says so before the detail" "$out" "OUT OF SCOPE"

out="$(cd "$REPO" && bash -c '
  . '"$FROOT"'/harness/lib/incident.sh
  . '"$FROOT"'/harness/lib/intake.sh
  felix_brief_render "'"$FROOT"'/projects/widget" "'"$REPO"'" \
    "no such file" "nothing here names a real path"')"; rc=$?
is  "an issue naming no real file still exits 0" "$rc" "0"
has "and says it cannot be scoped"               "$out" "no file"
```

- [ ] **Step 2: Run and watch the last assertion fail**

Run: `cd /Users/a14808/Documents/Felix && ./engine/harness/tests/run 2>&1 | grep -A8 "issue intake"`

Expected: `a red path exits 3` and `and says so before the detail` PASS (Task 1 implemented them). `and says it cannot be scoped` FAILS: the current text reads `none named that exist in this checkout`, which does not contain the string `no file`.

- [ ] **Step 3: Fix the wording so the assertion describes real behaviour**

In `engine/harness/lib/intake.sh`, replace:

```bash
    printf 'files:    none named that exist in this checkout\n'
```

with:

```bash
    printf 'files:    no file it names exists in this checkout\n'
```

- [ ] **Step 4: Run and watch all four pass**

Run: `cd /Users/a14808/Documents/Felix && ./engine/harness/tests/run 2>&1 | grep -A8 "issue intake"`

Expected: four `ok` lines.

- [ ] **Step 5: Write the failing tests for evidence and the play**

`felix_evidence_check` cannot be reused here: it compares a *diff* against `evidence.tsv`, and an issue has no diff yet because the work has not happened. What the brief can honestly say is which evidence rows *will* apply to a fix touching these paths. That needs its own helper.

Append to the `issue intake` section:

```bash
out="$(cd "$REPO" && bash -c '
  . '"$FROOT"'/harness/lib/incident.sh
  . '"$FROOT"'/harness/lib/route.sh
  . '"$FROOT"'/harness/lib/intake.sh
  felix_brief_render "'"$FROOT"'/projects/widget" "'"$REPO"'" \
    "the widget renders twice" "src/widget.py double-renders on mount"')"
has "the brief says what a fix must prove" "$out" "prove"
has "and names the tool to reach for"      "$out" "play"
```

- [ ] **Step 6: Run and watch both fail**

Run: `cd /Users/a14808/Documents/Felix && ./engine/harness/tests/run 2>&1 | grep -A12 "issue intake"`

Expected: both FAIL. The brief currently prints `title`, `files` and `tier` and nothing else.

- [ ] **Step 7: Add the two helpers**

Append to `engine/harness/lib/intake.sh`:

```bash
# Which evidence rows a fix touching these paths will have to satisfy.
#
# Deliberately not felix_evidence_check: that compares a diff against the policy
# and there is no diff yet. This answers the forward-looking question instead —
# what will this have to prove — which is the one worth asking before the work
# rather than after it.
felix_brief_evidence() {
  local proj="$1" paths="$2" name when requires reason p
  [ -f "$proj/evidence.tsv" ] || return 0
  grep -vE '^\s*(#|$)' "$proj/evidence.tsv" | while IFS=$'\t' read -r name when requires reason; do
    [ -n "${when:-}" ] || continue
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      if printf '%s' "$p" | grep -qE "$when"; then
        printf '%s\t%s\n' "$name" "${reason:-$requires}"
        break
      fi
    done <<EOF
$paths
EOF
  done
}

# The play this project already decided this kind of work goes through. Scored
# against the issue text alone: the working tree says what you are standing in,
# which has nothing to do with an issue you have not started.
felix_brief_play() {
  local proj="$1" text="$2" best
  [ -f "$proj/routes.tsv" ] || return 0
  best="$(felix_route_best "$proj" "$text" "" 2>/dev/null)" || return 0
  printf '%s' "$best" | cut -f7
}
```

- [ ] **Step 8: Call them from the renderer**

In `engine/harness/lib/intake.sh`, inside `felix_brief_render`, replace the block:

```bash
  if [ "$sev" = "red" ]; then
```

with:

```bash
  local ev play
  ev="$(felix_brief_evidence "$proj" "$implicated")"
  if [ -n "$ev" ]; then
    printf '\nwhat a fix must prove\n'
    printf '%s\n' "$ev" | while IFS=$'\t' read -r name reason; do
      printf '  %-12s %s\n' "$name" "$reason"
    done
  fi

  play="$(felix_brief_play "$proj" "$title
$body")"
  [ -n "$play" ] && printf '\nplay:     %s\n' "$play"

  if [ "$sev" = "red" ]; then
```

`felix_brief_render` now depends on `route.sh` being sourced. `engine/harness/felix` already sources it; the test sources it explicitly in Step 5.

- [ ] **Step 9: Run and watch all six pass**

Run: `cd /Users/a14808/Documents/Felix && ./engine/harness/tests/run 2>&1 | grep -A12 "issue intake"`

Expected: six `ok` lines across Tasks 1 and 2.

- [ ] **Step 10: Commit**

```bash
cd /Users/a14808/Documents/Felix
./engine/harness/tests/run && git add engine/harness/lib/intake.sh engine/harness/tests/run && \
git commit -m "feat(intake): scope verdict in the exit code, and what a fix must prove

Three exits: 0 with a brief, 0 saying it cannot be scoped, 3 when a red path is
implicated. Scope is decided before the issue body is printed, because telling
a model what it may not touch after handing it the details is the wrong order.

Evidence is answered forward rather than backward. felix_evidence_check compares
a diff against the policy and there is no diff yet, so the brief asks what this
will have to prove instead, which is the question worth asking before the work."
```

---

### Task 3: `felix brief` on the CLI

**Files:**
- Modify: `engine/harness/felix` — add `cmd_brief` immediately before `cmd_incident`, and a `brief)` dispatch arm in the `case` block next to `incident)`
- Modify: `engine/harness/felix` — add one line to `usage()`
- Test: `engine/harness/tests/run` (extend the `issue intake` section)

**Interfaces:**
- Consumes: `felix_brief_render proj root title body` (Task 1); `resolve_or_die` setting `$PROJ`; `felix_repo_root path`.
- Produces: `felix brief <issue-number>` and `felix brief --from -` (issue text on stdin).

- [ ] **Step 1: Write the failing test**

Append to the `issue intake` section:

```bash
# --from - is what makes this testable and what makes it usable before any
# issue tracker is wired, the same reason felix incident reads stdin.
out="$(cd "$REPO" && printf 'src/widget.py double-renders on mount\n' \
       | "$FELIX" brief --from - --title "the widget renders twice" 2>&1)"; rc=$?
is  "brief reads an issue from stdin" "$rc" "0"
has "and briefs the file it names"    "$out" "src/widget.py"

out="$(cd "$PLAIN" && printf 'x\n' | "$FELIX" brief --from - --title t 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ok "brief refuses outside a governed repo" \
                || bad "brief refuses outside a governed repo" "$out"
```

- [ ] **Step 2: Run and watch it fail**

Run: `cd /Users/a14808/Documents/Felix && ./engine/harness/tests/run 2>&1 | grep -A12 "issue intake"`

Expected: FAIL with `unknown command: brief`.

- [ ] **Step 3: Add `cmd_brief`**

Insert into `engine/harness/felix` immediately before the line `cmd_incident() {`:

```bash
cmd_brief() {
  resolve_or_die; local proj="$PROJ" src="" title="" num="" body=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --from)  src="${2:-}"; shift 2 ;;
      --title) title="${2:-}"; shift 2 ;;
      -*)      die "unknown flag: $1" ;;
      *)       num="$1"; shift ;;
    esac
  done

  local root; root="$(felix_repo_root "$PWD")"

  if [ -n "$src" ]; then
    if [ "$src" = "-" ]; then body="$(cat)"; else
      [ -f "$src" ] || die "no such file: $src"
      body="$(cat "$src")"
    fi
  elif [ -n "$num" ]; then
    command -v gh >/dev/null 2>&1 || die "felix brief needs the gh CLI, which is not on PATH"
    local slug; slug="$(felix_repo_slug "$root")"
    [ -n "$slug" ] || die "no github remote; pass the issue text with --from - instead"
    # Two calls rather than one with a template: the engine parses no JSON.
    title="$(gh issue view "$num" --repo "$slug" --json title -q .title 2>/dev/null)" \
      || die "could not read issue $num from $slug"
    [ -n "$title" ] || die "issue $num has no title, or does not exist in $slug"
    body="$(gh issue view "$num" --repo "$slug" --json body -q .body 2>/dev/null)"
  else
    die "felix brief <issue-number>, or felix brief --from - with the text on stdin"
  fi

  felix_brief_render "$proj" "$root" "${title:-untitled}" "$body"
}
```

- [ ] **Step 4: Wire the dispatch and the help text**

In `engine/harness/felix`, in the `case "${1:-help}" in` block, add immediately after the `incident)` arm:

```bash
  brief)    shift; cmd_brief "$@" ;;
```

In `usage()`, add after the `felix discover` line:

```bash
  printf '  felix brief <issue>  what an issue names, what tier it is, what to reach for\n'
```

Confirm `intake.sh` is sourced. Near the other `. "${SCRIPT_DIR}/lib/..."` lines, add:

```bash
. "${SCRIPT_DIR}/lib/intake.sh"
```

- [ ] **Step 5: Run and watch all three pass**

Run: `cd /Users/a14808/Documents/Felix && ./engine/harness/tests/run 2>&1 | grep -A12 "issue intake"`

Expected: `ok brief reads an issue from stdin`, `ok and briefs the file it names`, `ok brief refuses outside a governed repo`.

- [ ] **Step 6: Commit**

```bash
cd /Users/a14808/Documents/Felix
./engine/harness/tests/run && git add engine/harness/felix engine/harness/tests/run && \
git commit -m "feat(brief): take an issue

Closes the first of the two unmet p41 exit criteria. Reads a GitHub issue by
number, or the text on stdin so the loop works before any tracker is wired.
Creates no branch: a command that mutates a dirty working tree to save a
keystroke is not worth having."
```

---

### Task 4: `felix pr` previews, and creates behind a flag

**Files:**
- Modify: `engine/harness/lib/intake.sh` — add `felix_pr_body`
- Modify: `engine/harness/felix` — add `cmd_pr` immediately after `cmd_brief`, plus a `pr)` dispatch arm and a `usage()` line
- Test: `engine/harness/tests/run` (extend the `issue intake` section)

**Interfaces:**
- Consumes: `felix_classify_rows proj base root` as already used by `cmd_classify`; `felix_repo_slug root`.
- Produces: `felix_pr_body root base` → prints the pull request body (commit subjects plus the tier line). `felix pr` prints a preview; `felix pr --create` calls `gh pr create`.

- [ ] **Step 1: Write the failing test**

Append to the `issue intake` section:

```bash
# Preview by default, act behind a flag: the pattern felix incident --create and
# felix classify --apply already set, against felix discover which refuses --yes
# outright. A preview that could create by accident is not a preview.
( cd "$REPO" && git checkout -qb feature/thing 2>/dev/null
  printf 'y\n' >> src/widget.py
  git add -A >/dev/null 2>&1
  git -c user.name=t -c user.email=t@t commit -qm "fix: stop the double render" >/dev/null 2>&1 )
out="$(cd "$REPO" && "$FELIX" pr 2>&1)"; rc=$?
is  "pr previews and exits 0"        "$rc" "0"
has "naming the branch's commit"     "$out" "stop the double render"
case "$out" in
  *"created"*) bad "and creates nothing without --create" "$out" ;;
  *)           ok  "and creates nothing without --create" ;;
esac
```

- [ ] **Step 2: Run and watch it fail**

Run: `cd /Users/a14808/Documents/Felix && ./engine/harness/tests/run 2>&1 | grep -A18 "issue intake"`

Expected: FAIL with `unknown command: pr`.

- [ ] **Step 3: Add `felix_pr_body` to `engine/harness/lib/intake.sh`**

Append to `engine/harness/lib/intake.sh`:

```bash
# The body of a pull request, from the commits that are actually on the branch.
# Written from git rather than from the model's memory of what it did, because
# the branch is the record and the memory is not.
felix_pr_body() {
  local root="$1" base="$2"
  printf 'what this carries\n\n'
  git -C "$root" log --format='- %s' "$base..HEAD" 2>/dev/null
}
```

- [ ] **Step 4: Add `cmd_pr` to `engine/harness/felix`**

Insert immediately after the closing brace of `cmd_brief`:

```bash
cmd_pr() {
  resolve_or_die; local proj="$PROJ" base="main" create=0 issue="" title=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --base)   base="${2:-main}"; shift 2 ;;
      --issue)  issue="${2:-}"; shift 2 ;;
      --title)  title="${2:-}"; shift 2 ;;
      --create) create=1; shift ;;
      *) shift ;;
    esac
  done

  local root branch body tier
  root="$(felix_repo_root "$PWD")"
  branch="$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  [ "$branch" != "$base" ] || die "already on $base; make a branch before opening a pull request"

  [ -n "$title" ] || title="$(git -C "$root" log -1 --format=%s 2>/dev/null)"
  body="$(felix_pr_body "$root" "$base")"
  [ -n "$issue" ] && body="$body

closes #$issue"

  # Two calls, exactly as cmd_classify does it: diff produces findings, tier
  # reduces them. felix_classify_tier takes the findings, not the paths.
  local findings
  findings="$(felix_classify_diff "$proj" "$base" "$root")"
  tier="$(felix_classify_tier "$findings")"
  [ -n "$tier" ] || tier=green

  printf 'branch:   %s -> %s\ntitle:    %s\ntier:     %s\n\n' "$branch" "$base" "$title" "$tier"
  printf '%s\n' "$body"

  if [ "$create" -eq 0 ]; then
    printf '\nPreview only. Add --create to open it.\n'
    return 0
  fi

  command -v gh >/dev/null 2>&1 || die "felix pr --create needs the gh CLI, which is not on PATH"
  local slug; slug="$(felix_repo_slug "$root")"
  [ -n "$slug" ] || die "no github remote"

  # Draft when the gate has not passed on this exact tree. Read the receipt the
  # same way the Stop hook does: identity must match AND the result must be
  # green, because a green receipt for a different tree is not a green gate.
  # Opening anyway is deliberate: the repair loop attaches to an existing pull
  # request, so refusing here would leave it nothing to attach to.
  local draft="--draft" tid receipt
  tid="$(felix_tree_id "$root" "$FELIX_HOME_DIR")" || tid=""
  receipt="$(felix_verify_receipt "$root" "$FELIX_HOME_DIR")"
  if [ -n "$tid" ] && [ "$(printf '%s' "$receipt" | cut -f1)" = "$tid" ] \
     && [ "$(printf '%s' "$receipt" | cut -f2)" = "green" ]; then
    draft=""
  fi

  gh pr create --repo "$slug" --base "$base" --head "$branch" \
    --title "$title" --body "$body" $draft \
    || die "gh pr create failed"
  printf '\ncreated. labelling risk-%s\n' "$tier"
  gh pr edit --repo "$slug" --add-label "risk-$tier" >/dev/null 2>&1 \
    || printf 'could not apply risk-%s; the label may not exist yet\n' "$tier"
}
```

`cmd_pr` uses helpers from four libraries. Confirm `engine/harness/felix` already sources `classify.sh`, `verify.sh` and `detect.sh` (it does, for `cmd_classify`, the gate, and `felix_repo_slug`), and add the `intake.sh` source line from Task 3 if it is not there yet.

- [ ] **Step 5: Wire the dispatch and the help text**

In the `case` block, after the `brief)` arm:

```bash
  pr)       shift; cmd_pr "$@" ;;
```

In `usage()`, after the `felix brief` line:

```bash
  printf '  felix pr [--create]  open a pull request for this branch, tier and all\n'
```

- [ ] **Step 6: Run and watch all three pass**

Run: `cd /Users/a14808/Documents/Felix && ./engine/harness/tests/run 2>&1 | grep -A18 "issue intake"`

Expected: `ok pr previews and exits 0`, `ok naming the branch's commit`, `ok and creates nothing without --create`.

- [ ] **Step 7: Commit**

```bash
cd /Users/a14808/Documents/Felix
./engine/harness/tests/run && git add engine/harness/lib/intake.sh engine/harness/felix engine/harness/tests/run && \
git commit -m "feat(pr): open one

Closes the second unmet p41 exit criterion. Felix has always been able to label
and merge a pull request and never able to open one. Previews by default and
creates behind --create, the pattern incident --create and classify --apply
already set. Opens draft when the gate has not passed, because the repair loop
attaches to an existing pull request and refusing would leave it nothing."
```

---

### Task 5: Deploy and verify against the real repository

**Files:**
- Modify: `engine/.claude-plugin/plugin.json`
- Modify: `HANDOFF.md`

- [ ] **Step 1: Classify the branch**

Run: `cd /Users/a14808/Documents/Felix && felix classify`

Expected: `tier: red` (because `engine/harness/lib/intake.sh` matches `^engine/harness/lib/`). Stop and ask for approval before merging. Do not merge on a green gate alone.

- [ ] **Step 2: After approval, merge and bump**

```bash
cd /Users/a14808/Documents/Felix
git checkout main && git merge --no-edit <branch>
sed -i '' 's/"version": "0.13.1"/"version": "0.14.0"/' engine/.claude-plugin/plugin.json
```

The bump is the deployment: Claude Code caches by version, so a changed engine at an unchanged version never deploys and still reports success.

- [ ] **Step 3: Gate, commit, deploy**

```bash
cd /Users/a14808/Documents/Felix
./engine/harness/tests/run && git add engine/.claude-plugin/plugin.json && \
git commit -m "chore(engine): 0.14.0 - felix takes an issue and opens a pull request"
felix install
felix gate
```

Expected: `verified the installed engine matches this tree`, then `gate: pass`.

- [ ] **Step 4: Run the deployed thing against the real repository**

The suite tests the code; only running it where it will run tests the deployment. Three defects in this project's history survived a green suite and were found this way within minutes.

```bash
cd /Users/a14808/Documents/Elenchus
printf 'src/elenchus/web/app.py returns 500 on the results page\n' | felix brief --from - --title "results page 500"
```

Expected: the brief names `src/elenchus/web/app.py`, states a tier, and exits 0.

- [ ] **Step 5: Update `HANDOFF.md`**

In the exit-criteria table, change the `take an issue` row from **no** to yes with evidence `felix brief`, and the `open PR` row from **Felix does not** to yes with evidence `felix pr --create`. Both rows currently read as unmet and would otherwise be stale the moment this lands.

- [ ] **Step 6: Commit**

```bash
cd /Users/a14808/Documents/Felix
./engine/harness/tests/run && git add HANDOFF.md && \
git commit -m "docs(handoff): two exit criteria that stopped being unmet"
```

---

## What this plan does not do

- **No branch creation.** `felix brief` names the branch to make; the caller makes it. A command that mutates a possibly-dirty working tree to save a keystroke is not worth having.
- **No unattended wiring.** Stage two of intake is a separate change. `unattended.yml` can consume `felix brief` the moment somebody edits it, because the stdout-plus-exit-3 contract already matches `felix repair`, but nothing here edits that workflow.
- **No auto-merge.** Still earned by five consecutive green merges, not granted.
- **No `gh` stub in the suite.** The fetch path stays untested, exactly as `felix repair`'s does. `--from -` exists so the half worth testing is testable; adding a stub harness is its own change.
