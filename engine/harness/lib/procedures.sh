# What each moment has to answer for, and what nothing answers yet.
#
# Written after a failure of method rather than of code. A governed project's
# security audit found five things four days before its launch; Felix was
# handed the list and grew a command with checks for the two that were
# mechanizable — a stray listener, a file mode — and silently dropped the
# third, a missing request ceiling. Not because the check was hard. Because
# there was no table of what a deploy moment must answer, so nothing could
# say a question had gone unasked. A list of checks cannot report the check
# nobody wrote.
#
# The fix is not a better list, and this is the part worth holding on to.
# `lifecycle.tsv` already solves exactly this shape for hook events, and it
# does not work by being well written: `felix_coverage_events` reads what the
# PLATFORM actually binds, the table carries only stances, and the gap is
# whatever reality has that the table does not. That is why it named
# SubagentStop without anybody thinking of SubagentStop.
#
# So the rule here, and it is the whole design:
#
#   Felix may hold stances. Felix may never author the enumeration.
#
# Items come from two sources it does not control — what the checkout HAS
# (capabilities, read off the tree by detection) and what has actually BITTEN
# (the distinct checks in mistakes.log, written by gate failures as they
# happened). Both grow without anybody deciding they should.
#
# A stance is judgement: at which moment this item is answered, and by what.
# It is authored, arguable, and recorded, which is precisely what an
# enumeration must not be. An item with no stance is not an error and not a
# defect — it is the product. On a project that has never taken one, this
# reports every item, which is the output that would have named the request
# ceiling on the first day rather than after the audit.

# Moments a person has declared. Data, not code: the set is a table so that
# adding one is an edit rather than a release.
felix_procedures_moments() {
  local tpl="$1"
  [ -f "$tpl/moments.tsv" ] || return 0
  grep -vE '^[[:space:]]*(#|$)' "$tpl/moments.tsv" 2>/dev/null | cut -f1
}

# Everything this project could be asked about. One `kind:name` per line.
#
# Neither half is a list Felix wrote. Capabilities are detected from the
# checkout or adopted from that detection; failures are whatever the gate
# caught, recorded as it caught them. Add a surface and an item appears; break
# something new and an item appears. Nothing here has an opinion about which
# of them matter.
felix_procedures_items() {
  local proj="$1" mem cap term
  {
    while IFS= read -r cap; do
      [ -n "$cap" ] || continue
      printf 'capability:%s\n' "$cap"
    done <<EOF
$(felix_declared "$proj")
EOF
    mem="$(felix_mem_dir "$proj")"
    if [ -f "$mem/mistakes.log" ]; then
      # Column four holds every check that failed in one run, space separated.
      awk -F'\t' '{ n = split($4, t, " "); for (i = 1; i <= n; i++)
                    if (t[i] != "") print "failure:" t[i] }' \
          "$mem/mistakes.log" 2>/dev/null
    fi
  } | LC_ALL=C sort -u
  return 0
}

# item <TAB> moment <TAB> answered-by <TAB> note, for stances a person took.
felix_procedures_stances() {
  local proj="$1"
  [ -f "$proj/procedures.tsv" ] || return 0
  grep -vE '^[[:space:]]*(#|$)' "$proj/procedures.tsv" 2>/dev/null
}

# Items nothing answers. The product.
#
# Absence is reported rather than assumed away, which is the property whose
# lack caused this file to be written: a surface that exists, or a failure
# that has already happened, and no moment at which anybody says it is
# handled.
felix_procedures_gaps() {
  local proj="$1" item stanced
  stanced="$(felix_procedures_stances "$proj" | cut -f1)"
  while IFS= read -r item; do
    [ -n "$item" ] || continue
    felix_has_line "$stanced" "$item" && continue
    printf '%s\n' "$item"
  done <<EOF
$(felix_procedures_items "$proj")
EOF
  return 0
}

# Stances pointing at a moment nobody declared.
#
# A typo answers nothing while looking like an answer, which is the same
# defect one level up — a stance that cannot be reached is a gap wearing a
# stance's clothes.
felix_procedures_unknown_moments() {
  local proj="$1" tpl="$2" known item moment rest
  known="$(felix_procedures_moments "$tpl")"
  while IFS=$'\t' read -r item moment rest; do
    [ -n "${moment:-}" ] || continue
    felix_has_line "$known" "$moment" && continue
    printf '%s\t%s\n' "$moment" "$item"
  done <<EOF
$(felix_procedures_stances "$proj")
EOF
  return 0
}
