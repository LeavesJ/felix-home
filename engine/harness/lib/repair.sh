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
#
# felix repair's exit status is its contract with templates/unattended.yml,
# which branches on it and on nothing else, so each status means one thing:
#
#   0  a brief for the newest gate run, which failed or timed out; the only
#      status a repair acts on
#   1  the gate's runs could not be read: no gh, no GitHub remote, no gate
#      workflow, no branch checked out, or gh did not answer. Also the failing
#      run's own log, when gh does not answer, GitHub no longer holds it, or
#      it is empty. And a run that failed to start, which left no log, or one
#      whose conclusion this code does not know. And an --implicated file
#      that could not be written
#   2  the repair ceiling is reached, or could not be counted
#   3  the failure implicates a red path, which unattended repair leaves alone
#   4  no project governs the checkout, or the binding naming one is broken
#   5  nothing to repair: the gate has not run on the branch, is still running,
#      is green, or ended without failing (cancelled, skipped, neutral, stale,
#      action_required)
#
# 4 was 2 until 2026-09-23, the status every other command still exits on a
# failed resolve, and the template's case read it as a spent ceiling.
# A failed resolve says the workflow is wired to a Felix that does not govern
# this repository, which is true of every branch at once and says nothing about
# the failing change, so the template fails the job on it rather than labelling
# a pull request.
#
# 5 was 0 until the same day, the status of a brief, so the template would
# have spent the budget and run a model on a brief saying nothing was wrong.
# Nothing failed, so it stops the job without failing it or asking anyone.
#
# Repair acts only on what its ceiling counts. Until the same day only success
# was caught, so every other conclusion a completed run can have fell through
# to a brief: a cancelled or skipped run, which felix_repair_attempts then
# stopped at, so its ceiling read as unspent however many failures sat behind
# it. A failed run whose excerpt came back empty was a brief too, and
# implicated no path, so the red-path check never ran and the model was handed
# no failing output.
# startup_failure is left alone too, whether or not the ceiling counts it: the
# gate never ran, so no step left a log to read.
#
# `--implicated <file>` is the contract's second half. The file is emptied on
# every run, and a brief (0) writes into it the files the failing log names,
# one per line, the set the brief lists under "implicated files". The template
# holds a repair to that set: it stops at scope when the set is empty, since a
# repair would have nothing it may change, and refuses a diff that reaches
# outside it. Until 2026-09-24 that boundary was a sentence in the model's
# prompt and nothing checked it.
#
# felix brief keeps this shape and uses 0, 1, 2 and 3 of it: its 2 is a failed
# resolve, and it has no 5, because an issue is always something to act on.

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
#
# A run waiting for a person to approve it is passed over like one still
# running: it has no verdict, so it neither counts nor ends the count. On
# github.com a pull request updated with a workflow's GITHUB_TOKEN gets its
# pull_request runs in that state, so each unattended push leaves one between
# the gate run it dispatches and the run before. Stopping there held the count
# at the failures since the last push, and the ceiling never came.
felix_repair_attempts() {
  local branch="$1" repo="$2" workflow="${3:-}" n=0 c runs
  [ -n "$workflow" ] || return 1
  runs="$(gh run list --repo "$repo" --branch "$branch" --workflow "$workflow" --limit 10 \
            --json conclusion -q '.[].conclusion' 2>/dev/null)" || return 1
  while read -r c; do
    case "$c" in
      failure|timed_out) n=$((n+1)) ;;
      ""|action_required) continue ;;
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
#
# Non-zero with nothing printed when there is nothing to show: gh failed, or
# answered with a log that is empty once blank lines go. The pipeline's status
# was tail's, 0 either way, and an empty excerpt read as a failure with no
# output and no path in it.
felix_repair_excerpt() {
  local run_id="$1" repo="$2" log out
  log="$(gh run view "$run_id" --repo "$repo" --log-failed 2>/dev/null)" || return 1
  out="$(printf '%s\n' "$log" \
    | sed 's/^[^\t]*\t[^\t]*\t//' \
    | sed 's/^[0-9TZ:.-]*Z //' \
    | grep -vE '^\s*$' \
    | tail -40)"
  [ -n "$out" ] || return 1
  printf '%s\n' "$out"
}
