#!/usr/bin/env bash
# May this push to main stand on the green run its pull request already had,
# instead of running the gate again on the same tree?
#
#   reuse-verified-tree.sh        reads GITHUB_REPOSITORY, GITHUB_SHA and
#                                 GITHUB_WORKFLOW_REF, as a push run sets them
#
#   exit 0  reuse: prints the id of the run that gated this exact tree
#   exit 1  run the gate: prints why on stderr
#   exit 2  cannot examine: missing input or a GitHub read failed. Never read
#           as reuse; the workflow runs the gate.
#
# A push to main runs the gate on the commit a pull request has just landed.
# From 2026-09-01 to 09-25, 174 of the 203 such runs gated a tree that the pull
# request's own run had already passed. They were 28% of every Actions minute
# the repository spent, and none of the 203 failed. The evidence was bought
# twice because the workflow keys it on an event, "a push happened", and not on
# what the evidence is about, which is this tree.
#
# Every gate run names the tree it checked out, in an annotation titled
# "gated tree", before the gate runs on it. Reuse needs all of these, each read
# from GitHub and not from the tree being judged:
#   1. this commit is the merge commit of a merged pull request from this
#      repository;
#   2. of the pull_request runs of this same workflow file on that pull
#      request's head, the one that ran last concluded success. Last by when it
#      started, so a rerun that went red counts even if the run is older;
#   3. that run's gate job named exactly one gated tree, and it is this
#      commit's tree.
# Condition 3 is what makes it exact. A pull_request run gates the head merged
# into whatever its base was at the time, and the run itself no longer says
# which base once the pull request has merged. A run that merged into another
# branch, or into a main that has since moved or been rewritten, named a
# different tree and is not reused. The first version inferred the tree from
# history and could be fooled by a pull request retargeted to main after its
# last run; the review that found it is in the handoff.
#
# The runner image is the one thing outside the tree that can differ between
# the two runs, and it is not checked.
#
# Nothing here can turn a red tree green. The most it does is decline to run
# again a tree GitHub already recorded as gated green, on a commit already
# landed.
set -u
repo="${GITHUB_REPOSITORY:-}"; sha="${GITHUB_SHA:-}"; wref="${GITHUB_WORKFLOW_REF:-}"
job="${REUSE_GATE_JOB:-gate}"
[ -n "$repo" ] && [ -n "$sha" ] && [ -n "$wref" ] \
  || { printf 'reuse: cannot examine: GITHUB_REPOSITORY, GITHUB_SHA and GITHUB_WORKFLOW_REF must all be set\n' >&2; exit 2; }
command -v gh >/dev/null 2>&1 || { printf 'reuse: cannot examine: no gh on PATH\n' >&2; exit 2; }

# "owner/repo/.github/workflows/gate.yml@refs/heads/main" -> the file's path.
wpath="${wref#"$repo"/}"; wpath="${wpath%%@*}"
case "$wpath" in
  .github/workflows/*) ;;
  *) printf 'reuse: cannot examine: GITHUB_WORKFLOW_REF %s names no workflow file in %s\n' "$wref" "$repo" >&2; exit 2 ;;
esac

tree="$(git rev-parse --verify -q "$sha^{tree}")" \
  || { printf 'reuse: cannot examine: %s is not in this checkout\n' "$sha" >&2; exit 2; }

# 1. The pull request this commit is the merge commit of.
pr="$(gh api "repos/$repo/commits/$sha/pulls" \
  --jq "map(select(.merge_commit_sha == \"$sha\" and .merged_at != null)) | .[0] // empty | [.number, .head.sha, (.head.repo.full_name // \"\")] | @tsv")" \
  || { printf 'reuse: cannot examine: could not list the pull requests of %s\n' "$sha" >&2; exit 2; }
[ -n "$pr" ] || { printf 'reuse: no: %s is not the merge commit of a merged pull request\n' "$sha" >&2; exit 1; }
IFS=$'\t' read -r num head hrepo <<< "$pr"
[ "$hrepo" = "$repo" ] || { printf 'reuse: no: #%s came from %s, not %s\n' "$num" "${hrepo:-a repository that is gone}" "$repo" >&2; exit 1; }

# 2. The pull_request run of this workflow on the head that ran last.
run="$(gh api "repos/$repo/actions/workflows/${wpath##*/}/runs?head_sha=$head&event=pull_request&per_page=100" \
  --jq "[.workflow_runs[] | select(.status == \"completed\" and .path == \"$wpath\" and .head_repository.full_name == \"$repo\")]
        | sort_by(.run_started_at) | last // empty | [.id, .conclusion, .run_attempt, .html_url] | @tsv")" \
  || { printf 'reuse: cannot examine: could not list %s runs on %s\n' "$wpath" "$head" >&2; exit 2; }
[ -n "$run" ] || { printf 'reuse: no: no completed %s run on #%s head %s\n' "$wpath" "$num" "$head" >&2; exit 1; }
IFS=$'\t' read -r rid concl attempt url <<< "$run"
[ "$concl" = success ] \
  || { printf 'reuse: no: the %s run on #%s head %s that ran last ended %s (%s)\n' "$wpath" "$num" "$head" "$concl" "$url" >&2; exit 1; }

# 3. The tree that run's gate job says it gated.
jid="$(gh api "repos/$repo/actions/runs/$rid/jobs?filter=latest" \
  --jq "[.jobs[] | select(.name == \"$job\")] | if length == 1 then .[0].id else empty end")" \
  || { printf 'reuse: cannot examine: could not list the jobs of run %s\n' "$rid" >&2; exit 2; }
[ -n "$jid" ] || { printf 'reuse: no: run %s has no single job named %s\n' "$rid" "$job" >&2; exit 1; }
gated="$(gh api "repos/$repo/check-runs/$jid/annotations" \
  --jq '[.[] | select(.title == "gated tree") | .message] | if length == 1 then .[0] else empty end')" \
  || { printf 'reuse: cannot examine: could not read the annotations of job %s\n' "$jid" >&2; exit 2; }
gated="$(printf '%s' "$gated" | grep -oE '[0-9a-f]{40}' | sed -n '1p')"
[ -n "$gated" ] \
  || { printf 'reuse: no: job %s of run %s names no single gated tree\n' "$jid" "$rid" >&2; exit 1; }
[ "$gated" = "$tree" ] \
  || { printf 'reuse: no: run %s gated tree %s, and this commit'"'"'s tree is %s\n' "$rid" "$gated" "$tree" >&2; exit 1; }

msg="Tree $tree was gated green by run $rid, attempt $attempt ($url), on #$num head $head. The gate is not run again on it."
printf 'reuse: yes: %s\n' "$msg" >&2
[ -n "${GITHUB_STEP_SUMMARY:-}" ] && printf '%s\n' "$msg" >> "$GITHUB_STEP_SUMMARY"
printf '%s\n' "$rid"
exit 0
