# Scheduled maintenance.
#
# Maintenance is the work that never has a deadline, so it never happens, and
# then happens all at once as a crisis. Putting it on a clock is the whole point
# of the guidebook's table on p10.
#
# Felix tracks what is due and refuses to lose track. It does not perform the
# routines: cleaning dead code and grouping dependency updates are judgment, and
# a script that did them unattended would produce exactly the flood of
# unreviewable pull requests the guidebook warns against.
#
# The last-run log is durable state in the project directory, committed like
# everything else, because a cadence tracked in a scratch file resets the first
# time someone works from a different machine and quietly reports everything as
# never-run.
#
# Times are stored as epoch seconds. Parsing a date back is where portability
# goes to die: BSD date wants -j -f, GNU date wants -d, and a maintenance tracker
# that only works on the author's laptop is not a tracker.
#
# maintenance.tsv rows: name <TAB> cadence-days <TAB> capability <TAB> description
#   cadence 0 means event-driven, never on a clock.

_felix_maint_rows() {
  local proj="$1"
  [ -f "$proj/maintenance.tsv" ] || return 0
  grep -vE '^\s*(#|$)' "$proj/maintenance.tsv"
}

_felix_maint_last() {   # epoch of the most recent run, or empty
  local proj="$1" name="$2" line last=""
  [ -f "$proj/maintenance.log" ] || return 0
  while IFS=$'\t' read -r n epoch _; do
    [ "${n:-}" = "$name" ] && last="$epoch"
  done < "$proj/maintenance.log"
  printf '%s' "$last"
}

felix_maint_record() {
  local proj="$1" name="$2" now
  now="$(date +%s)"
  printf '%s\t%s\t%s\n' "$name" "$now" "$(date -r "$now" +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)" \
    >> "$proj/maintenance.log"
}

# Emits: status <TAB> name <TAB> days-since <TAB> cadence <TAB> description
# status is due | ok | event | dormant
# Upkeep rows that can never come due.
#
# The capability column takes `always` or a capability name. Anything else
# resolves to dormant, and dormant renders as a dash next to "Nothing due" —
# which is indistinguishable from a well-kept repository. Felix's own table used
# `-` in that column for four routines that had therefore never run and never
# could, and the report said nothing was outstanding every single time.
#
# A row naming a REAL capability the project has not declared is not an error:
# that is a dormant row working as designed, and flagging it would turn this
# into noise. Only a name that is not a capability at all is caught, because
# that is a typo wearing a dash.
#
# Emits: name <TAB> capability, one line per unreachable row.
FELIX_MAINT_CAPABILITIES='ci deploy iac observability billing e2e database api frontend llm rust tests secrets'

felix_maint_unreachable() {
  local proj="$1" name cadence cap desc
  [ -f "$proj/maintenance.tsv" ] || return 0
  while IFS=$'\t' read -r name cadence cap desc; do
    case "$name" in ''|'#'*) continue ;; esac
    [ -n "${cap:-}" ] || continue
    [ "$cap" = "always" ] && continue
    case " $FELIX_MAINT_CAPABILITIES " in *" $cap "*) continue ;; esac
    felix_has_line "$(felix_declared "$proj")" "$cap" 2>/dev/null && continue
    printf '%s\t%s\n' "$name" "$cap"
  done < "$proj/maintenance.tsv"
}

felix_maint_status() {
  local proj="$1" now; now="$(date +%s)"
  _felix_maint_rows "$proj" | while IFS=$'\t' read -r name cadence cap desc; do
    [ -n "${name:-}" ] || continue
    if ! _felix_cap_active "${cap:-always}" "$proj"; then
      printf 'dormant\t%s\t-\t%s\t%s\n' "$name" "${cadence:-0}" "$desc"; continue
    fi
    if [ "${cadence:-0}" -eq 0 ] 2>/dev/null; then
      printf 'event\t%s\t-\t0\t%s\n' "$name" "$desc"; continue
    fi
    local last age days
    last="$(_felix_maint_last "$proj" "$name")"
    if [ -z "$last" ]; then
      printf 'due\t%s\tnever\t%s\t%s\n' "$name" "$cadence" "$desc"; continue
    fi
    age=$(( (now - last) / 86400 ))
    if [ "$age" -ge "$cadence" ]; then days="due"; else days="ok"; fi
    printf '%s\t%s\t%s\t%s\t%s\n' "$days" "$name" "$age" "$cadence" "$desc"
  done
}
