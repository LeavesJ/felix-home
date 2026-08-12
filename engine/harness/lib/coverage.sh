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
# A decline is permanent by construction, which is the one way this table rots
# quietly. `wired` is re-checked against reality on every run; `declined` never
# is, because the reason lives in prose nothing can read. `PreCompact` is
# declined *because* the `SessionStart` matcher contains `compact` — narrow that
# matcher and the decline becomes false with nothing to say so.
#
# So a row may carry a fourth column, `holds`: a literal that must still be
# present in hooks.json for its reason to remain true. When it goes, the row
# goes red. `-` is allowed and is not a failure — a decline rooted in judgement
# rather than in a token is honest, and demanding a literal from everyone would
# only produce invented ones. Those are counted instead, by
# felix_coverage_unchecked, so "N declines rest on nothing checkable" is visible
# rather than the excuses being invisible.
#
# Emits: state <TAB> event <TAB> detail
#   ok        stance and reality agree
#   gap       no stance at all — the case that had to be found by hand twice
#   missing   declared wired, nothing wires it
#   undeclared    wired, but no row says why
#   stale-reason  declined, and the premise the reason rests on is gone
felix_coverage_check() {
  local tpl="$1" hooks="$2" event stance reason holds wired seen=""
  [ -f "$tpl/lifecycle.tsv" ] || return 0
  [ -f "$hooks" ] || return 0

  while IFS=$'\t' read -r event stance reason holds; do
    case "$event" in ''|'#'*) continue ;; esac
    [ -n "${stance:-}" ] || continue
    seen="$seen $event"

    wired=no
    grep -q "\"$event\"" "$hooks" 2>/dev/null && wired=yes

    case "$stance:$wired" in
      wired:yes)    printf 'ok\t%s\t%s\n'      "$event" "${reason:-wired}" ;;
      wired:no)     printf 'missing\t%s\t%s\n' "$event" "declared wired, nothing wires it" ;;
      declined:yes) printf 'missing\t%s\t%s\n' "$event" "declined, yet something wires it" ;;
      declined:no)
        # A three-column table predates this column and must keep working, or
        # every governed project's table breaks the day the engine updates.
        if [ -n "${holds:-}" ] && [ "$holds" != "-" ] \
             && ! grep -qF -- "$holds" "$hooks" 2>/dev/null; then
          printf 'stale-reason\t%s\t%s\n' "$event" \
            "declined because '$reason', but '$holds' is no longer in hooks.json"
        else
          printf 'ok\t%s\t%s\n' "$event" "declined: ${reason:-no reason given}"
        fi ;;
      *)            printf 'gap\t%s\t%s\n'     "$event" "stance '$stance' is not wired or declined" ;;
    esac
  done < "$tpl/lifecycle.tsv"

  # The other direction, and the one that caught nothing today only because the
  # table was written after the fact: something wired that no row explains. A
  # hook nobody wrote a reason for is a hook nobody can argue with.
  local h
  for h in $(grep -oE '"[A-Z][A-Za-z]+"[[:space:]]*:[[:space:]]*\[' "$hooks" 2>/dev/null \
               | sed 's/"[[:space:]]*:.*//; s/"//g' | sort -u); do
    case " $seen " in *" $h "*) continue ;; esac
    printf 'undeclared\t%s\t%s\n' "$h" "wired, but lifecycle.tsv says nothing about it"
  done
}

# How many declines rest on nothing a check can read.
#
# Not a failure and not a target to drive to zero. Some declines genuinely rest
# on judgement — Notification is declined because speaking there would break
# stealth, and no literal in hooks.json can stand for that. The number exists so
# the unfalsifiable share is a figure somebody can look at rather than a
# property nobody can see.
felix_coverage_unchecked() {
  local tpl="$1" event stance reason holds n=0
  [ -f "$tpl/lifecycle.tsv" ] || { printf '0'; return 0; }
  while IFS=$'\t' read -r event stance reason holds; do
    case "$event" in ''|'#'*) continue ;; esac
    [ "${stance:-}" = "declined" ] || continue
    case "${holds:-}" in ''|'-') n=$((n+1)) ;; esac
  done < "$tpl/lifecycle.tsv"
  printf '%s' "$n"
}

# Every event something on this machine actually binds.
#
# Discovered, not remembered. The first version of this was a list typed from
# memory, and it was wrong within the hour: `SubagentStart` was bound in
# settings.json the whole time and the table said "every moment has a stance".
# A roster of what somebody recalls is the same defect as a list of files to
# check — it stops matching reality quietly, and the report keeps saying ok.
#
# A binding is proof the event exists, so nothing here is guessed and there are
# no false positives to teach anyone to skim. What it cannot see is an event the
# platform offers that nothing on this machine binds yet; those become visible
# the day anything binds one, which is also the first day they could matter.
felix_coverage_events() {
  {
    grep -ohE '"[A-Z][A-Za-z]+"[[:space:]]*:[[:space:]]*\[' \
      "$HOME/.claude/settings.json" \
      "$HOME/.claude/settings.local.json" \
      "$HOME"/.claude/plugins/cache/*/*/*/hooks/hooks.json 2>/dev/null \
      | sed 's/"[[:space:]]*:.*//; s/"//g'
  } 2>/dev/null | LC_ALL=C sort -u
}

# Moments something binds that the stance table has never heard of. This is the
# row that would have named SubagentStop months before anybody swept the
# lifecycle by hand — and that named SubagentStart an hour after the table
# meant to prevent exactly this was written.
felix_coverage_unconsidered() {
  local tpl="$1" e known
  [ -f "$tpl/lifecycle.tsv" ] || return 0
  known="$(grep -vE '^[[:space:]]*(#|$)' "$tpl/lifecycle.tsv" | cut -f1)"
  while IFS= read -r e; do
    [ -n "$e" ] || continue
    printf '%s\n' "$known" | grep -qxF "$e" || printf '%s\n' "$e"
  done <<EOF
$(felix_coverage_events)
EOF
}
