# Is every tool this project names actually usable in a session?
#
# The router can point at a skill mid-turn and the agent will invoke it, which
# is the whole reason routing works at all. What cannot happen mid-turn is
# enabling a plugin that is switched off, or connecting an MCP server: Claude
# Code says "Restart to apply changes" and means it.
#
# So availability is decided before the session starts, and a project's needs
# are not the same as the next project's. One project routes to a browser
# tester and a design critic; another routes to a database plugin it alone
# declares. A tool that is installed but disabled looks identical to a tool that
# is present, right up until the turn where it is needed and silently is not.
#
# This is the pre-flight. It reads every play in routes.tsv and every row in
# stack.tsv, and reports each named tool as usable, disabled, or absent.

# Everything usable on this machine: enabled plugins, and standalone skills,
# which are directories rather than packages and appear in no plugin list.
#
# MCP servers are deliberately absent. They are fixed at session start and
# cannot be reached for on demand, so listing them here would invite routes to
# name something the router can never make happen.
felix_ready_inventory() {
  local d
  if command -v claude >/dev/null 2>&1; then
    claude plugin list --json 2>/dev/null \
      | sed -n -e 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/ID \1/p' \
               -e 's/.*"enabled"[[:space:]]*:[[:space:]]*\([a-z]*\).*/EN \1/p' \
      | awk '/^ID /{id=$2} /^EN /{ if ($2=="true") { sub(/@.*/,"",id); print "plugin\t" id } }'
  fi
  for d in "$HOME"/.claude/skills/*/; do
    [ -d "$d" ] || continue
    d="${d%/}"
    printf 'skill\t%s\n' "${d##*/}"
  done
}

# What exists here that no route in this project ever reaches for.
#
# The point is not tidiness. A router is only ever as good as the tools its
# table knows about, and a table that names one plugin five times while thirty
# others sit unused is not routing, it is a habit. This is the list that makes
# the habit visible.
felix_ready_unused() {
  local proj="$1" wanted kind name owner
  # sed rather than a case statement, and not for style. bash 3.2 parses the
  # closing paren of a `case` pattern written inside $( ) as the end of the
  # substitution, so `case "$w" in *:*)` fails at runtime with a syntax error
  # about an unexpected newline. It parses cleanly under zsh, which is how it
  # survived a hand-check and died the moment the real CLI ran it.
  wanted="$(
    felix_ready_wanted "$proj" | sed 's/:.*//'
    grep -vE '^[[:space:]]*(#|$)' "$proj/stack.tsv" 2>/dev/null | cut -f2 | sed 's/@.*//'
  )"
  felix_ready_inventory | while IFS=$'\t' read -r kind name; do
    [ -n "$name" ] || continue
    felix_has_line "$wanted" "$name" && continue
    printf '%s\t%s\n' "$kind" "$name"
  done
}

# Every distinct tool this project could reach for, from any route.
felix_ready_wanted() {
  local proj="$1" n k pr pl p
  [ -f "$proj/routes.tsv" ] || return 0
  while IFS=$'\t' read -r n k pr pl; do
    case "$n" in ''|'#'*) continue ;; esac
    [ -n "${pl:-}" ] && [ "$pl" != "-" ] || continue
    for p in $pl; do printf '%s\n' "$p"; done
  done < "$proj/routes.tsv" | LC_ALL=C sort -u
}

# A play entry names a skill; the manifest declares the plugin that owns it.
_felix_ready_owner() {
  case "$1" in *:*) printf '%s' "${1%%:*}" ;; *) printf '%s' "$1" ;; esac
}

# state <TAB> name <TAB> detail
#
# `usable` means installed and switched on. `disabled` is the dangerous one: it
# is installed, so every eyeball check passes, and it contributes nothing.
felix_ready_report() {
  local proj="$1" want owner line id enabled found
  # id and enabled are not adjacent in the object — version and scope sit
  # between them — so a naive "pull both values and pair them" produces nothing
  # at all. Tag each line with which field it is, then pair in awk, which holds
  # the last id it saw. Line-oriented because the CLI pretty-prints, and no jq
  # because the engine may not require a runtime.
  local plugins=""
  if command -v claude >/dev/null 2>&1; then
    plugins="$(claude plugin list --json 2>/dev/null \
      | sed -n -e 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/ID \1/p' \
               -e 's/.*"enabled"[[:space:]]*:[[:space:]]*\([a-z]*\).*/EN \1/p' \
      | awk '/^ID /{id=$2} /^EN /{print id "\t" $2}')"
  fi

  while IFS= read -r want; do
    [ -n "$want" ] || continue
    owner="$(_felix_ready_owner "$want")"

    # Declared in the project's own manifest? A tool nobody declared is a tool
    # nobody agreed to, whatever happens to be installed on this laptop.
    local row kind
    row="$(grep -E "	($want|$owner)(@[^	]*)?	" "$proj/stack.tsv" 2>/dev/null | head -1)"
    if [ -z "$row" ]; then
      printf 'undeclared\t%s\t%s\n' "$want" "named by a route, absent from stack.tsv"
      continue
    fi
    kind="$(printf '%s' "$row" | cut -f1)"

    # A standalone skill is a directory, not a package: there is no plugin to
    # enable and nothing in the plugin list to find. Looking for one there
    # reported a perfectly working skill as missing, which is exactly the kind
    # of false alarm that gets a pre-flight check ignored.
    if [ "$kind" = "skill" ] && [ "$want" = "$owner" ]; then
      if [ -d "$HOME/.claude/skills/$want" ]; then
        printf 'usable\t%s\t%s\n' "$want" "skill, always available"
      else
        printf 'absent\t%s\t%s\n' "$want" "skill directory not present"
      fi
      continue
    fi

    if [ -z "$plugins" ]; then
      printf 'unknown\t%s\t%s\n' "$want" "no claude CLI here, cannot check"
      continue
    fi

    found=""; enabled=""
    while IFS=$'\t' read -r id enabled; do
      case "$id" in "$owner@"*|"$owner") found="$id"; break ;; esac
    done <<EOF
$plugins
EOF

    if [ -z "$found" ]; then
      printf 'absent\t%s\t%s\n' "$want" "not installed"
    elif [ "$enabled" = "true" ]; then
      printf 'usable\t%s\t%s\n' "$want" "$found"
    else
      printf 'disabled\t%s\t%s\n' "$want" "installed but switched off"
    fi
  done <<EOF
$(felix_ready_wanted "$proj")
EOF
}
