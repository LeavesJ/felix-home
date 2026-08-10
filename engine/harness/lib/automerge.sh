# Earned auto-merge.
#
# The guidebook's last principle is that autonomy is earned by proving
# reliability, and the ladder it draws ends at acting autonomously within policy
# rather than starting there. The machinery for auto-merge exists: a green tier
# means no risky path was touched, and no evidence gap means the change proved
# itself. What does not exist is evidence that the rules draw the line where
# anyone would draw it, because the rules were written in one sitting and no
# change has gone through them yet.
#
# So the criterion is a mechanism, not a note. "Turn it on in five PRs" is a
# promise that gets forgotten or, worse, remembered early. This counts.
#
# A green pull request is clean when its own CI never failed. A green
# classification says the local judgement was that nothing risky was touched; CI
# failing afterwards means that judgement was wrong, which is the thing being
# tested. Nothing here counts test flakes as evidence of good rules, because a
# red run is a red run and the whole point is to be strict about what earns trust.

FELIX_AUTOMERGE_REQUIRED="${FELIX_AUTOMERGE_REQUIRED:-5}"

# Emits: pr <TAB> clean|dirty <TAB> title, newest first.
felix_automerge_history() {
  local repo="$1" limit="${2:-20}"
  gh pr list --repo "$repo" --state merged --label risk-green \
     --limit "$limit" --json number,title,headRefName \
     -q '.[] | "\(.number)\t\(.headRefName)\t\(.title)"' 2>/dev/null \
  | while IFS=$'\t' read -r num branch title; do
      [ -n "${num:-}" ] || continue
      local failures
      failures="$(gh run list --repo "$repo" --branch "$branch" --limit 20 \
                    --json conclusion -q '[.[] | select(.conclusion=="failure")] | length' 2>/dev/null)"
      if [ "${failures:-0}" -eq 0 ] 2>/dev/null; then
        printf '%s\tclean\t%s\n' "$num" "$title"
      else
        printf '%s\tdirty\t%s\n' "$num" "$title"
      fi
    done
}

# Consecutive clean greens at the head of the history.
felix_automerge_streak() {
  local history="$1" n=0 num state title
  while IFS=$'\t' read -r num state title; do
    [ -n "${num:-}" ] || continue
    [ "$state" = "clean" ] || break
    n=$((n+1))
  done <<EOF
$history
EOF
  printf '%s' "$n"
}
