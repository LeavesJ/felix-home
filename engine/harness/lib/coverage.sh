# Felix diagnosing its own coverage.
#
# Two gaps were found today by a person noticing: the Stop hook checked the gate
# and never asked anyone to verify their claims, and SubagentStop was not wired
# at all. Both are the same defect — a completion moment with nothing at it —
# and neither was findable by reading code, because **absence has no line
# number**. Nothing greps for a hook that was never written.
#
# So the stance is written down instead, one row per lifecycle moment, and this
# compares the stance against what is actually wired. That turns a missing hook
# from something somebody has to notice into something that fails.
#
# Deliberately narrow. This checks that every moment has been *considered*, not
# that what runs at it is any good — a wired hook that does the wrong thing
# passes here, and should, because judging that is not mechanical. Overclaiming
# would be worse than not checking: a green coverage report that means "somebody
# thought about this" is honest, and one that implies "this is handled" is not.
#
# Emits: state <TAB> event <TAB> detail
#   ok        stance and reality agree
#   gap       no stance at all — the case that had to be found by hand twice
#   missing   declared wired, nothing wires it
#   undeclared  wired, but no row says why
felix_coverage_check() {
  local tpl="$1" hooks="$2" event stance reason wired seen=""
  [ -f "$tpl/lifecycle.tsv" ] || return 0
  [ -f "$hooks" ] || return 0

  while IFS=$'\t' read -r event stance reason; do
    case "$event" in ''|'#'*) continue ;; esac
    [ -n "${stance:-}" ] || continue
    seen="$seen $event"

    wired=no
    grep -q "\"$event\"" "$hooks" 2>/dev/null && wired=yes

    case "$stance:$wired" in
      wired:yes)    printf 'ok\t%s\t%s\n'      "$event" "${reason:-wired}" ;;
      wired:no)     printf 'missing\t%s\t%s\n' "$event" "declared wired, nothing wires it" ;;
      declined:yes) printf 'missing\t%s\t%s\n' "$event" "declined, yet something wires it" ;;
      declined:no)  printf 'ok\t%s\t%s\n'      "$event" "declined: ${reason:-no reason given}" ;;
      *)            printf 'gap\t%s\t%s\n'     "$event" "stance '$stance' is not wired or declined" ;;
    esac
  done < "$tpl/lifecycle.tsv"

  # The other direction, and the one that caught nothing today only because the
  # table was written after the fact: something wired that no row explains. A
  # hook nobody wrote a reason for is a hook nobody can argue with.
  local h
  for h in $(grep -oE '"(SessionStart|UserPromptSubmit|PreToolUse|PostToolUse|Stop|SubagentStop|SessionEnd|PreCompact|Notification)"' \
               "$hooks" 2>/dev/null | tr -d '"' | sort -u); do
    case " $seen " in *" $h "*) continue ;; esac
    printf 'undeclared\t%s\t%s\n' "$h" "wired, but lifecycle.tsv says nothing about it"
  done
}

# Every event the platform offers, whether or not Felix has an opinion yet.
#
# Hardcoded, because it is a property of Claude Code rather than of any project,
# and because the whole point is to notice when this list grows past what the
# stance table covers. A list derived from the stance table could never do that.
FELIX_LIFECYCLE_EVENTS="SessionStart UserPromptSubmit PreToolUse PostToolUse Stop SubagentStop SessionEnd PreCompact Notification"

# Moments the platform offers that the stance table has never heard of. This is
# the row that would have said "SubagentStop" out loud, months before anybody
# thought to sweep the lifecycle by hand.
felix_coverage_unconsidered() {
  local tpl="$1" e known
  [ -f "$tpl/lifecycle.tsv" ] || return 0
  known="$(grep -vE '^[[:space:]]*(#|$)' "$tpl/lifecycle.tsv" | cut -f1)"
  for e in $FELIX_LIFECYCLE_EVENTS; do
    printf '%s\n' "$known" | grep -qxF "$e" || printf '%s\n' "$e"
  done
}
