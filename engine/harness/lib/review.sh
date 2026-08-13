# The verdict on a surface no test can judge.
#
# Most escapes name something mechanical: a credential in the added lines, a job
# that will run holding secrets, a store that moves. One class has no mechanical
# test at all. A rubric that teaches the wrong thing is revert-complete, touches
# no store, reaches no stranger, and passes every check there is — and it is
# still the change you least want merged unread.
#
# A governed project had already written the answer into its own constitution
# before Felix could enforce any of it: an independent reviewer running in an
# isolated worktree at the reviewed commit, with the part that matters attached
# — a reviewer that executes the claim, because one that only reads the diff is
# a weaker tier wearing the name. So a verdict attests to something run.
#
# ---------------------------------------------------------------------------
# THE ONE PLACE A MODEL'S OUTPUT PERMITS RATHER THAN RESTRICTS.
#
# Invariant 2 says a model "may only ever narrow what the mechanical path
# already allowed", and a `reviewed` verdict widens: it clears an escape. That
# is a real exception and it is written here rather than smuggled past, because
# the invariant exists to stop a model overriding a mechanical verdict — and
# there is no mechanical verdict here to override. The alternative is not a
# stricter check; it is nobody reading it.
#
# Three things bound it, and they are the reason it is safe to have:
#
#   - A verdict clears `reviewed` and nothing else. `disclose`, `execute`,
#     `durable` and `verifier` are untouched by any review, so no reviewer can
#     release a secret, run CI, or move a store. Tested in that direction.
#   - It is keyed to the exact tree, the same way the gate receipt is, because
#     the trap is the same: a verdict for a different tree is not a verdict.
#   - Only `pass` clears. A missing verdict and a blocking verdict behave
#     identically, so a reviewer that never ran cannot read as approval.
#
# What Felix cannot check, and must not imply it does: that the reviewer was
# independent, that it ran in an isolated worktree, or that it executed anything
# at all. It records the claim and who made it. Independence is a property of
# how the review was dispatched, and nothing in a receipt can establish it.

_felix_review_path() {
  # Keyed on project and tree so two projects, or two trees, never share one.
  printf '%s/state/review/%s-%s' "$1" "$(basename "$2")" "$3"
}

# Write a verdict. Overwrites: the latest word on a tree is the one that counts,
# and keeping a history here would invite reading the wrong row.
felix_review_record() {
  local home="$1" proj="$2" tid="$3" verdict="$4" by="${5:-unknown}" note="${6:-}" path
  [ -n "$tid" ] || return 1
  case "$verdict" in pass|block) ;; *) return 1 ;; esac
  path="$(_felix_review_path "$home" "$proj" "$tid")"
  mkdir -p "$(dirname "$path")" 2>/dev/null || return 1
  printf '%s\t%s\t%s\t%s\t%s\n' "$tid" "$verdict" \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$by" \
    "$(printf '%s' "$note" | tr '\t\n' '  ' | cut -c1-300)" \
    > "$path" 2>/dev/null || return 1
}

felix_review_verdict() {
  cat "$(_felix_review_path "$1" "$2" "$3")" 2>/dev/null
}

# Has this exact tree been reviewed and passed?
felix_review_passed() {
  local home="$1" proj="$2" tid="$3" rec
  [ -n "$tid" ] || return 1
  rec="$(felix_review_verdict "$home" "$proj" "$tid")"
  [ -n "$rec" ] || return 1
  [ "$(printf '%s' "$rec" | cut -f1)" = "$tid" ] || return 1
  [ "$(printf '%s' "$rec" | cut -f2)" = "pass" ]
}
