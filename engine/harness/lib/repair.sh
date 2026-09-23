# The bounded repair loop.
#
# Felix does not fix anything here. It supplies the deterministic scaffolding a
# repair loop needs and refuses to be the part that requires judgment: fetch the
# failure, extract what actually broke, count how many attempts have already been
# spent, and enforce the ceiling. Diagnosis and the patch are the agent's job.
#
# The ceiling is the point. The guidebook (p8) asks for a bounded loop, because
# an agent that retries indefinitely burns money converging on nothing and looks
# busy the entire time. After FELIX_REPAIR_MAX consecutive failures the answer
# stops being "try again" and becomes "a human needs to look at this."
#
# Attempts are counted from CI history rather than a local counter, so the count
# survives a new session, a different machine, and a cleared scratch directory.
# A counter that resets when the agent restarts cannot bound anything.
#
# GitHub Actions only for now, via gh. Stated plainly rather than hidden behind a
# provider abstraction with one implementation.

FELIX_REPAIR_MAX="${FELIX_REPAIR_MAX:-3}"

_felix_repair_require_gh() {
  command -v gh >/dev/null 2>&1 || {
    printf 'felix repair needs the gh CLI, which is not on PATH.\n' >&2
    return 1
  }
}

felix_repair_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null
}

# Both reads below are of the gate workflow's runs, named by the caller from
# felix_gate_workflow, and of no other workflow's. `gh run list --branch` alone
# is every workflow on the branch. The unattended repair's own runs are
# recorded on the default branch, which is where a workflow_run event puts
# them, and on any branch it is dispatched on; GitHub's Dependency Graph runs
# on the default branch as well. There the newest run was usually the repair's:
# skipped, which stops the count of the gate's failures at zero, or, while it
# runs, in progress, which would tell the very repair asking that the gate is
# still running. Any other workflow's failures there spend the ceiling.
#
# Where the runs cannot be read, the direction is fixed. No workflow named, or
# one the repository does not have (gh answers 404 and prints nothing), or any
# other gh failure, returns non-zero with nothing printed. An empty --workflow
# is no filter to gh, so it is never passed through. And an unreadable count is
# never zero: a ceiling that reads as unspent whenever the network does not
# answer bounds nothing.

# Consecutive failures at the head of this branch's gate runs.
felix_repair_attempts() {
  local branch="$1" repo="$2" workflow="${3:-}" n=0 c runs
  [ -n "$workflow" ] || return 1
  runs="$(gh run list --repo "$repo" --branch "$branch" --workflow "$workflow" --limit 10 \
            --json conclusion -q '.[].conclusion' 2>/dev/null)" || return 1
  while read -r c; do
    case "$c" in
      failure|timed_out) n=$((n+1)) ;;
      "") continue ;;
      *) break ;;
    esac
  done <<EOF
$runs
EOF
  printf '%s' "$n"
}

# The newest gate run on the branch, or nothing when the gate has not run
# there. `.[0]` of an empty list is null, and interpolating null printed
# `null<TAB>null<TAB>-`, which the caller read as a run still in progress.
felix_repair_latest() {
  local branch="$1" repo="$2" workflow="${3:-}"
  [ -n "$workflow" ] || return 1
  gh run list --repo "$repo" --branch "$branch" --workflow "$workflow" --limit 1 \
    --json databaseId,conclusion,status \
    -q '.[0] // empty | "\(.databaseId)\t\(.status)\t\(.conclusion // "-")"' 2>/dev/null
}

# The failing lines, not the whole log. A repair agent handed 4000 lines of
# ANSI-coded setup output spends its context on apt-get.
felix_repair_excerpt() {
  local run_id="$1" repo="$2"
  gh run view "$run_id" --repo "$repo" --log-failed 2>/dev/null \
    | sed 's/^[^\t]*\t[^\t]*\t//' \
    | sed 's/^[0-9TZ:.-]*Z //' \
    | grep -vE '^\s*$' \
    | tail -40
}
