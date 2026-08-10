# Project resolution for Felix. Sourced by the CLI and the session hook, which
# are the two real callers; it is not a layer waiting for a third.
#
# Dependencies are bash and git only. Deliberately no jq and no python: Felix
# governs projects in languages it must not require, so it cannot drag a runtime
# along. The JSON reader below is the price of that, and its limits are stated.

# Substring test that never builds a pipeline.
#
# `producer | grep -q x` is a trap under `set -o pipefail`: grep exits the moment
# it matches, the producer takes SIGPIPE, and the pipeline reports 141. The check
# then says "absent" about something that is present. It is worse than a plain
# bug because it is timing-dependent for small producers, so it passes in testing
# and fails against a real repository.
felix_contains() {
  case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac
}

# Whole-line variant, for lists where a substring match would be too loose.
felix_has_line() {
  local line
  while IFS= read -r line; do [ "$line" = "$2" ] && return 0; done <<EOF
$1
EOF
  return 1
}

# Where Felix keeps writable state: projects, their doctrine, their memory.
#
# Separate from the engine because an installed plugin lives in a versioned cache
# that is replaced wholesale on update. Writing project memory in there would
# lose it on the next `claude plugin update`, silently, which is the worst way to
# lose a lesson someone paid for.
#
# Order: an explicit environment variable, then the pointer file `felix install`
# writes, then a repo checkout that already carries projects/ beside the engine,
# then the default.
felix_home() {
  local engine="$1"
  if [ -n "${FELIX_HOME:-}" ]; then printf '%s' "$FELIX_HOME"; return; fi
  if [ -f "$HOME/.felix-home" ]; then
    local p; p="$(tr -d '[:space:]' < "$HOME/.felix-home")"
    [ -n "$p" ] && [ -d "$p" ] && { printf '%s' "$p"; return; }
  fi
  # A plugin install is a frozen copy of the whole repository, projects/
  # included. Trusting that copy would govern from a constitution frozen at
  # install time and write memory into a directory the next plugin update
  # deletes, both silently. The copy is never a home.
  case "$engine" in
    */.claude/plugins/cache/*|*/.claude/plugins/marketplaces/*) ;;
    *) [ -d "$engine/projects" ] && { printf '%s' "$engine"; return; } ;;
  esac
  printf '%s' "$HOME/.felix"
}

# Read one top-level string field out of a flat JSON file.
# Handles exactly what project.json needs: one nesting level, no escaped quotes.
# Anything richer belongs in a real parser, and would mean project.json has
# outgrown its job.
felix_json_str() {
  sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$1" | head -1
}

# Print the repo root for a directory, or the directory itself when not in git.
# Felix must work in a checkout that is not a git repo at all.
felix_repo_root() {
  local start="${1:-$PWD}" root
  root="$(cd "$start" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)"
  [ -n "$root" ] && printf '%s' "$root" || printf '%s' "$start"
}

# Resolve which project governs a working directory.
# Prints the project directory on success, prints nothing and returns 1 on miss.
#
# Order matters. The .felix marker wins because it is the only mechanism that
# works for a repo with no remote, a fork, a rename, or a checkout of somebody
# else's code. Remote matching is the convenience path, not the contract.
felix_resolve_project() {
  local start="${1:-$PWD}" felix_root="$2"
  local root name remote meta match
  root="$(felix_repo_root "$start")"

  # 1. explicit marker file naming the project
  if [ -f "$root/.felix" ]; then
    name="$(tr -d '[:space:]' < "$root/.felix")"
    if [ -n "$name" ] && [ -d "$felix_root/projects/$name" ]; then
      printf '%s' "$felix_root/projects/$name"
      return 0
    fi
    return 1
  fi

  # 2. git remote substring match declared by each project
  remote="$(cd "$root" 2>/dev/null && git remote get-url origin 2>/dev/null)" || remote=""
  [ -n "$remote" ] || return 1
  for meta in "$felix_root"/projects/*/project.json; do
    [ -e "$meta" ] || continue
    match="$(felix_json_str "$meta" remote_match)"
    [ -n "$match" ] || continue
    case "$remote" in
      *"$match"*) printf '%s' "$(dirname "$meta")"; return 0 ;;
    esac
  done
  return 1
}
