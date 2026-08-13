# Risk classification for a diff.
#
# The guidebook's merge policy (p8) sorts changes into green, yellow, and red.
# The labels existed already; nothing decided which one applied, so they sat
# unused and every change was treated identically.
#
# Three properties this has to have, or it is worse than nothing.
#
# Deterministic. A classifier a model can talk itself past is not a gate. These
# are declared patterns matched against a diff, and the same diff always
# produces the same tier.
#
# Conservative by default. A file matching no rule is yellow, never green. Green
# has to be earned by matching a pattern someone deliberately declared safe, so
# an unfamiliar file cannot get itself auto-merged by being unrecognised.
#
# Escalate-only. The highest tier any file reaches wins for the whole diff. One
# red file makes the change red no matter how much green sits beside it, because
# risk does not average.
#
# risk.tsv rows: tier <TAB> kind <TAB> pattern <TAB> reason
#   kind=path     extended regex matched against each changed path
#   kind=content  extended regex matched against added lines only

# felix_changed_paths lives in resolve.sh, which every hook and the CLI source
# first. Sourced here too rather than assumed: a lib whose helper is missing
# returns an empty path list, which reads as "nothing changed" and silently
# stops enforcing. That is the same shape as a test that is green because it
# cannot reach the branch it names, and it cost 15 assertions to notice.
if ! command -v felix_changed_paths >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

FELIX_RISK_DEFAULT="yellow"

_felix_risk_rows() {
  local proj="$1"
  [ -f "$proj/risk.tsv" ] || return 0
  grep -vE '^\s*(#|$)' "$proj/risk.tsv"
}

_felix_tier_rank() {
  case "$1" in green) echo 0 ;; yellow) echo 1 ;; red) echo 2 ;; *) echo 1 ;; esac
}

# Emits: tier <TAB> path-or-ADDED <TAB> reason, one line per rule that fired.
felix_classify_diff() {
  local proj="$1" base="$2" root="$3"
  local paths added
  paths="$(felix_changed_paths "$root" "$base")"
  # Added lines only. A removed secret is not a new exposure, and counting it as
  # one trains people to ignore the finding.
  added="$(git -C "$root" diff "$base...HEAD" 2>/dev/null | grep '^+' | grep -v '^+++' || true)"

  local matched_paths=""
  while IFS=$'\t' read -r tier kind pattern reason; do
    [ -n "${tier:-}" ] || continue
    case "$kind" in
      path)
        while IFS= read -r f; do
          [ -n "$f" ] || continue
          if printf '%s' "$f" | grep -qE "$pattern"; then
            printf '%s\t%s\t%s\n' "$tier" "$f" "$reason"
            matched_paths="$matched_paths
$f"
          fi
        done <<EOF
$paths
EOF
        ;;
      content)
        if [ -n "$added" ] && printf '%s' "$added" | grep -qE "$pattern"; then
          printf '%s\tADDED-LINES\t%s\n' "$tier" "$reason"
        fi
        ;;
    esac
  done <<EOF
$(_felix_risk_rows "$proj")
EOF

  # Anything no rule recognised. Reported so the default is visible rather than
  # silently deciding the outcome.
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    felix_has_line "$matched_paths" "$f" || \
      printf '%s\t%s\tno rule matched\n' "$FELIX_RISK_DEFAULT" "$f"
  done <<EOF
$paths
EOF
}

felix_classify_tier() {
  local findings="$1" best=0 rank line tier
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    tier="${line%%	*}"
    rank="$(_felix_tier_rank "$tier")"
    [ "$rank" -gt "$best" ] && best="$rank"
  done <<EOF
$findings
EOF
  case "$best" in 0) echo green ;; 2) echo red ;; *) echo yellow ;; esac
}
