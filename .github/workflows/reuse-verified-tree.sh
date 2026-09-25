#!/usr/bin/env bash
# May this push to main stand on the green run its pull request already had,
# instead of running the gate again on the same tree?
#
#   reuse-verified-tree.sh        reads GITHUB_REPOSITORY, GITHUB_SHA and
#                                 GITHUB_WORKFLOW_REF, as a push run sets them
#
#   exit 0  reuse: prints the id of the run that verified this exact tree
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
# Reuse needs all four of these, each read from GitHub and not from the tree
# being judged:
#   1. this commit is the merge commit of a merged pull request from this
#      repository;
#   2. main's previous tip is an ancestor of that pull request's head. The head
#      was then pushed after that tip landed, so its pull_request runs merged it
#      into that tip, and a merge into an ancestor has the head's own tree.
#      This leans on main only moving forward, which the deny table's refusal
#      of force-pushes is what holds;
#   3. the head's tree is this commit's tree;
#   4. the latest completed pull_request run of this same workflow file on that
#      head concluded success. The latest, not any: a head that went green and
#      then red on a rerun is not reused.
# The runner image is the one thing outside the tree that can differ between
# the two runs, and it is not checked.
#
# Nothing here can turn a red tree green. The most it does is decline to run
# again a tree GitHub already recorded as green, on a commit already landed.
set -u
repo="${GITHUB_REPOSITORY:-}"; sha="${GITHUB_SHA:-}"; wref="${GITHUB_WORKFLOW_REF:-}"
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
# No first parent means a root commit, which no pull request landed.
parent="$(git rev-parse --verify -q "$sha^1")" \
  || { printf 'reuse: no: %s has no parent\n' "$sha" >&2; exit 1; }

# 1. The pull request this commit is the merge commit of.
pr="$(gh api "repos/$repo/commits/$sha/pulls" \
  --jq "map(select(.merge_commit_sha == \"$sha\" and .merged_at != null)) | .[0] // empty | [.number, .head.sha, .head.repo.full_name] | @tsv")" \
  || { printf 'reuse: cannot examine: could not list the pull requests of %s\n' "$sha" >&2; exit 2; }
[ -n "$pr" ] || { printf 'reuse: no: %s is not the merge commit of a merged pull request\n' "$sha" >&2; exit 1; }
IFS=$'\t' read -r num head hrepo <<< "$pr"
[ "$hrepo" = "$repo" ] || { printf 'reuse: no: #%s came from %s, not %s\n' "$num" "$hrepo" "$repo" >&2; exit 1; }

# 2. main's previous tip is in the head's history.
rel="$(gh api "repos/$repo/compare/$parent...$head" --jq .status)" \
  || { printf 'reuse: cannot examine: could not compare %s with #%s head %s\n' "$parent" "$num" "$head" >&2; exit 2; }
case "$rel" in
  ahead|identical) ;;
  *) printf 'reuse: no: #%s head %s is %s main'"'"'s previous tip %s, so its runs gated a different merge\n' "$num" "$head" "$rel" "$parent" >&2; exit 1 ;;
esac

# 3. Same tree.
htree="$(gh api "repos/$repo/git/commits/$head" --jq .tree.sha)" \
  || { printf 'reuse: cannot examine: could not read #%s head %s\n' "$num" "$head" >&2; exit 2; }
[ "$htree" = "$tree" ] \
  || { printf 'reuse: no: #%s head tree %s is not this commit'"'"'s tree %s\n' "$num" "$htree" "$tree" >&2; exit 1; }

# 4. The latest completed pull_request run of this workflow on the head.
run="$(gh api "repos/$repo/actions/workflows/${wpath##*/}/runs?head_sha=$head&event=pull_request&per_page=100" \
  --jq "[.workflow_runs[] | select(.status == \"completed\" and .path == \"$wpath\" and .head_repository.full_name == \"$repo\")]
        | sort_by(.created_at) | last // empty | [.id, .conclusion, .run_attempt, .html_url] | @tsv")" \
  || { printf 'reuse: cannot examine: could not list %s runs on %s\n' "$wpath" "$head" >&2; exit 2; }
[ -n "$run" ] || { printf 'reuse: no: no completed %s run on #%s head %s\n' "$wpath" "$num" "$head" >&2; exit 1; }
IFS=$'\t' read -r rid concl attempt url <<< "$run"
[ "$concl" = success ] \
  || { printf 'reuse: no: the latest %s run on #%s head %s ended %s (%s)\n' "$wpath" "$num" "$head" "$concl" "$url" >&2; exit 1; }

msg="Tree $tree was verified green by run $rid, attempt $attempt ($url), on #$num head $head, which already held main's previous tip $parent. The gate is not run again on it."
printf 'reuse: yes: %s\n' "$msg" >&2
[ -n "${GITHUB_STEP_SUMMARY:-}" ] && printf '%s\n' "$msg" >> "$GITHUB_STEP_SUMMARY"
printf '%s\n' "$rid"
exit 0
