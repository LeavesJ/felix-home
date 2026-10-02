# Human setup steps.
#
# Some things Felix cannot do and should not pretend to: creating a Sentry
# account, completing an OAuth consent screen, entering a payment method,
# holding a live API key. Those are not gaps in the harness, they are the
# boundary of what an agent should touch.
#
# The failure mode worth designing against is not "Felix cannot do it." It is
# "Felix cannot do it and nobody wrote down what to do instead," which is how a
# half-provisioned environment sits broken for a week because the one person who
# knew was not asked.
#
# So every human step is declared with a check that proves whether it is done.
# The list is derived, never hand-maintained: finish the step and it disappears
# on the next run. Same principle as capability detection, pointed at people.
#
# setup.tsv rows: id <TAB> title <TAB> capability <TAB> check-command

command -v felix_final_filter_lead >/dev/null 2>&1 \
  || . "$(dirname "${BASH_SOURCE[0]:-$0}")/final-filter.sh"

_felix_setup_rows() {
  local proj="$1"
  [ -f "$proj/setup.tsv" ] || return 0
  grep -vE '^\s*(#|$)' "$proj/setup.tsv"
}

# Each row led by `-`, or by the sentence refusing its check. The check runs
# in a `bash -c` without pipefail, so one a final filter makes unable to fail
# (final-filter.sh) reads done whatever it asked, and the step it guards
# disappears from the list for good. Such a check is not run: the row stays
# todo, which every reader that counts todo sees, felix_setup_malformed says
# why, and schema-check fails the gate on it.
_felix_setup_judged() {
  _felix_setup_rows "$1" | felix_final_filter_lead setup.tsv
}

# id <TAB> why, for every row whose check is refused, dormant or not.
felix_setup_malformed() {
  local ff id rest
  _felix_setup_judged "$1" | while IFS=$'\t' read -r ff id rest; do
    [ "$ff" != "-" ] && [ -n "${id:-}" ] && printf '%s\t%s\n' "$id" "$ff"
  done
  return 0
}

# done | todo | dormant, one row each: status <TAB> id <TAB> title
felix_setup_status() {
  local proj="$1"
  _felix_setup_judged "$proj" | while IFS=$'\t' read -r ff id title cap check; do
    [ -n "${id:-}" ] || continue
    if ! _felix_cap_active "${cap:-always}" "$proj"; then
      printf 'dormant\t%s\t%s\n' "$id" "$title"
    elif [ "$ff" != "-" ]; then
      printf 'todo\t%s\t%s\n' "$id" "$title"
    elif [ -n "${check:-}" ] && bash -c "$check" </dev/null >/dev/null 2>&1; then
      printf 'done\t%s\t%s\n' "$id" "$title"
    else
      printf 'todo\t%s\t%s\n' "$id" "$title"
    fi
  done
}

felix_setup_runbook() {
  local proj="$1" id="$2"
  if [ -f "$proj/setup/$id.md" ]; then
    cat "$proj/setup/$id.md"
  else
    printf 'No runbook written for "%s" yet.\n' "$id"
    printf 'Add one at %s/setup/%s.md\n' "$proj" "$id"
    return 1
  fi
}
