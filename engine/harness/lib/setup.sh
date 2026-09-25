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

# felix_repo_slug is in detect.sh, which the CLI loads before this file and a
# caller sourcing this file alone may not have.
command -v felix_repo_slug >/dev/null 2>&1 || . "$(dirname "${BASH_SOURCE[0]:-$0}")/detect.sh"

_felix_setup_rows() {
  local proj="$1"
  [ -f "$proj/setup.tsv" ] || return 0
  grep -vE '^\s*(#|$)' "$proj/setup.tsv"
}

# {{REPO}} is filled in when a row is read, never when it is written (G5.1,
# U19).
#
# felix new and adopt used to splice the slug in as they wrote, and with no
# GitHub remote the slug is empty: the saved check read `gh label list --repo
# 2>/dev/null`, failed forever, and counted as a step to do, so commissioning's
# human_steps was held on every repository created before its remote, which is
# every repository `felix new` is run in first. Adding the remote later changed
# nothing, because adopt skips an id that exists. Now the file keeps the
# placeholder, and the remote the checkout has today decides what it reads.
#
# The slug is spliced into a command bash runs and into a replacement, so it is
# taken only in the shape a GitHub owner/name has. Anything else is no slug:
# a remote that is not GitHub, which felix_repo_slug passes through unstripped,
# and a URL carrying shell text. A GitHub URL with a trailing slash fails the
# shape too, and waits; that edge is the price of never running what a remote
# URL says.
_felix_setup_slug() {
  local s
  s="$(felix_repo_slug "${1:-$PWD}" 2>/dev/null)" || s=""
  case "$s" in
    ''|/*|*/|*/*/*|*[!A-Za-z0-9._/-]*) return 0 ;;
    */*) printf '%s' "$s" ;;
  esac
  return 0
}

# Rows and runbooks an older felix new saved with an empty slug are read as if
# they held {{REPO}}: `--repo`, blanks, and then nothing a slug could be (the
# end, another flag, a pipe, a separator, a backtick or a redirection) gets
# the placeholder put back. Only the text in hand changes, never the file.
# `--repo {{REPO}}` and `--repo owner/name` do not match and are left alone.
_felix_setup_norm() {
  sed -E 's/--repo([[:space:]]+)(--|[0-9]*[<>]|[|;&`]|$)/--repo {{REPO}}\1\2/g'
}

# done | todo | dormant, one row each: status <TAB> id <TAB> title, and a
# fourth field only for a row that waits on something the checkout lacks.
#
# A row whose check needs the slug, in a checkout with none, is dormant with
# the reason `waits for a GitHub remote` and its check is not run: it is not
# a step a person can take yet, so it holds nothing, and once origin points at
# GitHub the same saved row reads todo or done with the slug in it.
#
# ROOT is the checkout, defaulting to the one the working directory is in: the
# human_steps row calls this with the project alone, from inside the checkout.
felix_setup_status() {
  local proj="$1" root="${2:-}" slug
  [ -n "$root" ] || root="$(felix_repo_root "$PWD")"
  slug="$(_felix_setup_slug "$root")"
  _felix_setup_rows "$proj" | while IFS=$'\t' read -r id title cap check; do
    [ -n "${id:-}" ] || continue
    if ! _felix_cap_active "${cap:-always}" "$proj"; then
      printf 'dormant\t%s\t%s\n' "$id" "$title"
      continue
    fi
    case "${check:-}" in *--repo*) check="$(printf '%s\n' "$check" | _felix_setup_norm)" ;; esac
    case "${check:-}" in
      *'{{REPO}}'*)
        if [ -z "$slug" ]; then
          printf 'dormant\t%s\t%s\twaits for a GitHub remote\n' "$id" "$title"
          continue
        fi
        check="${check//\{\{REPO\}\}/$slug}" ;;
    esac
    if [ -n "${check:-}" ] && bash -c "$check" >/dev/null 2>&1; then
      printf 'done\t%s\t%s\n' "$id" "$title"
    else
      printf 'todo\t%s\t%s\n' "$id" "$title"
    fi
  done
}

# The runbook, with {{REPO}} filled in the same way the check is. With no slug
# the placeholder is left as written and the first line says why, so nobody
# pastes a command that names no repository.
felix_setup_runbook() {
  local proj="$1" id="$2" root="${3:-}" f slug
  f="$proj/setup/$id.md"
  if [ ! -f "$f" ]; then
    printf 'No runbook written for "%s" yet.\n' "$id"
    printf 'Add one at %s/setup/%s.md\n' "$proj" "$id"
    return 1
  fi
  [ -n "$root" ] || root="$(felix_repo_root "$PWD")"
  slug="$(_felix_setup_slug "$root")"
  if ! grep -qF '{{REPO}}' "$f" 2>/dev/null && ! grep -qE -- '--repo[[:space:]]' "$f" 2>/dev/null; then
    cat "$f"
  elif [ -n "$slug" ]; then
    _felix_setup_norm < "$f" | sed "s|{{REPO}}|$slug|g"
  elif _felix_setup_norm < "$f" | grep -qF '{{REPO}}'; then
    printf 'No GitHub remote yet, so {{REPO}} below is left as written; it fills in once origin points at GitHub.\n'
    _felix_setup_norm < "$f"
  else
    cat "$f"
  fi
}
