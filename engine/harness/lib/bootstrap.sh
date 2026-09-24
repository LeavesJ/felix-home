# Bring a repository up to the Engineering OS baseline.
#
# The first project onboarded here got its workflow file, escalation labels,
# branch protection, and permission policy applied by hand with gh. That is what
# made the claim false that `felix new` hands a newcomer what the first project
# has: they got a governed directory and none of the enforcement, because a
# person was the automation. This closes that gap.
#
# Every step is idempotent and reports what it found rather than assuming. Plan
# is the default; --yes applies. Branch protection and permission policy change
# what a repository will accept, so they are never a side effect of running a
# read command.

# The workflow file CI runs the gate in, and so the only workflow whose runs
# are evidence about the gate. The auto-merge streak and the repair ceiling both
# read it. Before they did, each read every workflow on the branch, so the
# unattended repair's runs and GitHub's Dependency Graph counted as the gate's.
#
# gate.yml by default, because that is the file this library writes. A project
# whose gate already runs in a workflow of its own, a ci.yml that calls felix
# gate, says so as `gate_workflow` in project.json, the way it states any other
# fact about itself, so the engine still names no project and the default is
# written here once.
#
# A bare file name under .github/workflows and nothing else. gh's --workflow
# also takes a display name or a numeric id, but only the file name is unique
# within a repository and is what this library writes: display names repeat,
# and an id means nothing to whoever reads project.json. A value that is not a
# file name is refused rather than replaced by the default, because a declared
# fact silently overridden reads a workflow the project said it does not use.
# On refusal the sentence to refuse with is what prints, so a caller writes
# `wf="$(felix_gate_workflow "$proj")" || die "$wf"`.
#
# The unattended repair template triggers on the gate by its display name,
# `gate`, which is the name this library writes inside gate.yml. A project that
# names another file has to name that workflow's display name in the trigger.
felix_gate_workflow() {
  local proj="$1" w
  w="$(felix_json_str "$proj/project.json" gate_workflow 2>/dev/null)"
  [ -n "$w" ] || { printf 'gate.yml'; return 0; }
  case "$w" in
    .*|*[!A-Za-z0-9._-]*) ;;
    *.yml|*.yaml) printf '%s' "$w"; return 0 ;;
  esac
  printf '%s/project.json declares gate_workflow "%s", which is not a workflow file name. Name the file under .github/workflows that runs the gate, such as ci.yml, or remove the key for gate.yml.' \
    "$(basename "$proj")" "$w"
  return 1
}

# Present in the working tree, or already on the remote's default branch. A
# checkout that has not pulled since the workflow merged would otherwise be told
# to write a file that already exists upstream, producing a conflict out of
# nothing.
_felix_bs_have_workflow() {
  local root="$1" wf="$2"
  [ -n "$wf" ] || return 1
  [ -f "$root/.github/workflows/$wf" ] && return 0
  git -C "$root" cat-file -e "origin/HEAD:.github/workflows/$wf" 2>/dev/null && return 0
  git -C "$root" cat-file -e "origin/main:.github/workflows/$wf" 2>/dev/null
}
_felix_bs_have_labels()   {
  felix_contains "$(gh label list --repo "$1" 2>/dev/null)" "needs-founder"
}
_felix_bs_have_protection() {
  gh api "repos/$1/branches/$2/protection" >/dev/null 2>&1
}
# grep on a file is safe; only pipelines can SIGPIPE.
_felix_bs_have_perms()    { [ -f "$1/.claude/settings.json" ] && \
                            grep -q '"deny"' "$1/.claude/settings.json" 2>/dev/null; }

# Which toolchain CI has to install before the gate can run.
felix_guess_ecosystem() {
  local root="$1"
  [ -f "$root/package.json" ]   && { echo node;   return; }
  [ -f "$root/pyproject.toml" ] && { echo python; return; }
  [ -f "$root/Cargo.toml" ]     && { echo rust;   return; }
  [ -f "$root/go.mod" ]         && { echo go;     return; }
  echo none
}

_felix_bs_setup_block() {
  case "$1" in
    node)   printf '      - uses: actions/setup-node@v4\n        with:\n          node-version: "22"\n      - run: npm ci\n        working-directory: repo\n' ;;
    python) printf '      - uses: actions/setup-python@v5\n        with:\n          python-version: "3.12"\n      - run: pip install -e ".[dev]"\n        working-directory: repo\n' ;;
    rust)   printf '      - uses: dtolnay/rust-toolchain@stable\n' ;;
    go)     printf '      - uses: actions/setup-go@v5\n        with:\n          go-version: stable\n' ;;
    *)      printf '      # no toolchain detected; add the setup step this project needs\n' ;;
  esac
}

# The workflow calls `felix gate` and nothing else. What the gate means stays in
# the project, so changing the checks never means editing CI.
felix_bs_render_workflow() {
  local eco="$1" felix_repo="$2"
  cat <<YAML
name: gate

# The gate lives in Felix, not here. This file is only the wiring that lets
# GitHub run it, which is why it should stay the smallest possible addition to
# this repository.

on:
  pull_request:
  push:
    branches: [main]

permissions:
  contents: read

concurrency:
  group: gate-\${{ github.ref }}
  cancel-in-progress: true

jobs:
  gate:
    runs-on: ubuntu-latest
    steps:
      # Sibling checkouts. A harness inside the tree being gated shows up in the
      # checks it is running.
      - uses: actions/checkout@v4
        with:
          path: repo

      - uses: actions/checkout@v4
        with:
          repository: ${felix_repo}
          ssh-key: \${{ secrets.FELIX_DEPLOY_KEY }}
          path: felix

$(_felix_bs_setup_block "$eco")
      - name: Confirm the governing project
        working-directory: repo
        run: ../felix/engine/harness/felix which

      - name: Run the gate
        working-directory: repo
        run: ../felix/engine/harness/felix gate
YAML
}

# Guidebook p11, as configuration rather than instruction. Written only when the
# project has no deny list of its own; an existing policy is never overwritten,
# because a permission file someone tightened by hand is not Felix's to relax.
#
# `gh pr merge` asked a person every time, whatever the tier or channel, which
# made the founder the merger of every governed repository after he had said
# Felix merges its own pull requests. The stop on a merge is felix merge's
# escape channels. What still asks is the merge that bypasses a required check.
felix_bs_render_perms() {
  cat <<'JSON'
{
  "permissions": {
    "deny": [
      "Bash(git push --force*)",
      "Bash(git push -f*)",
      "Bash(git reset --hard origin/*)",
      "Bash(rm -rf /*)",
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./**/*.pem)",
      "Read(./**/*.key)"
    ],
    "ask": [
      "Bash(git push*)",
      "Bash(gh pr merge*--admin*)",
      "Bash(gh secret*)",
      "Bash(gh api -X DELETE*)"
    ]
  }
}
JSON
}
