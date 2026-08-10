# Desired-state provisioning for a project's Claude environment.
#
# A project declares the marketplaces, plugins, and MCP servers it needs. Felix
# reads what is actually installed, diffs, and either prints the plan or applies
# it. Same shape as the guidebook's infrastructure rule (p32): propose, plan,
# check the diff against policy, get approval if required, apply, verify.
#
# Two things keep this from being a footgun.
#
# Capability gating: an entry is only in scope when the capability that justifies
# it is active. A project with no payments never gets billing tooling proposed,
# and the day it does, detection surfaces it first.
#
# Risk tiers: low and medium can be applied unattended with --yes. High never
# can, at any flag, from any caller. High means the tool can move money, reach
# production, or hold a credential, and no automation flag should be able to
# mount one of those without a person present.

FELIX_RISK_AUTO="low medium"

# Manifest rows: kind <TAB> name <TAB> source <TAB> risk <TAB> capability
_felix_stack_rows() {
  local proj="$1"
  [ -f "$proj/stack.tsv" ] || return 0
  grep -vE '^\s*(#|$)' "$proj/stack.tsv"
}

# Actual state, read once because `claude mcp list` runs health checks and is slow.
_felix_load_state() {
  _FELIX_PLUGINS="$(claude plugin list 2>/dev/null || true)"
  _FELIX_MCPS="$(claude mcp list 2>/dev/null || true)"
  _FELIX_MKTS="$(claude plugin marketplace list 2>/dev/null || true)"
}

_felix_have() {
  case "$1" in
    plugin)      printf '%s' "$_FELIX_PLUGINS" | grep -qF "$2" ;;
    # A connected MCP and a merely-configured one are different states. The
    # GitHub server sits in the list reporting "Failed to connect" until someone
    # completes OAuth, and calling that mounted would hide the one fact that
    # matters.
    mcp)         printf '%s' "$_FELIX_MCPS" | grep -E "(^|:)$2:" | grep -qv "Failed to connect\|Needs authentication" ;;
    marketplace) printf '%s' "$_FELIX_MKTS" | grep -qF "$2" ;;
    skill)       [ -d "$HOME/.claude/skills/$2" ] ;;
    *) return 1 ;;
  esac
}

_felix_cap_active() {
  local cap="$1" proj="$2"
  [ "$cap" = "always" ] && return 0
  felix_declared "$proj" | grep -qxF "$cap"
}

_felix_risk_is_auto() {
  case " $FELIX_RISK_AUTO " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}

# Classify every manifest row. Emits: action <TAB> kind <TAB> name <TAB> detail
felix_stack_plan() {
  local proj="$1"
  _felix_load_state
  _felix_stack_rows "$proj" | while IFS=$'\t' read -r kind name source risk cap; do
    [ -n "${kind:-}" ] || continue
    if _felix_have "$kind" "$name"; then
      printf 'present\t%s\t%s\t-\n' "$kind" "$name"
    elif ! _felix_cap_active "${cap:-always}" "$proj"; then
      printf 'dormant\t%s\t%s\tneeds capability: %s\n' "$kind" "$name" "$cap"
    elif [ "$risk" = "high" ]; then
      printf 'blocked\t%s\t%s\thigh risk, install by hand\n' "$kind" "$name"
    elif [ "$kind" = "skill" ]; then
      # Standalone skills are files, not packages. There is no install command
      # to run, so they route to a setup runbook instead of pretending.
      printf 'manual\t%s\t%s\tsee: felix setup\n' "$kind" "$name"
    else
      printf 'install\t%s\t%s\trisk: %s\n' "$kind" "$name" "$risk"
    fi
  done
}

# Install one row. Returns non-zero on failure so the caller can report honestly.
felix_stack_install() {
  local kind="$1" name="$2" source="$3"
  case "$kind" in
    marketplace)
      claude plugin marketplace add "$source" >/dev/null 2>&1 ;;
    plugin)
      claude plugin install "$name" --scope user >/dev/null 2>&1 ;;
    mcp)
      case "$source" in
        http*) claude mcp add --transport http "$name" "$source" >/dev/null 2>&1 ;;
        *)     # shellcheck disable=SC2086
               claude mcp add "$name" -- $source >/dev/null 2>&1 ;;
      esac ;;
    *) return 1 ;;
  esac
}
