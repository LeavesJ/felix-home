# felix status: five rows a surface can poll, and the settings check the pulse
# shares.
#
# The status surface is a Claude Code mod, built outside this repository. Its
# whole contract with Felix is the TSV below; it never parses pulse.log or a
# cache file, so what a row cannot say grows a detail or a new row at the end.
#
#   <row> TAB <state> TAB <value> TAB <detail>
#
# One line per row, no header, in this order: settings, schedule, pulse, reach,
# gate. state is value, none or unknown. value is a bare word (no spaces) when
# state is value, and `-` otherwise; detail is never empty. A consumer ignores
# rows it does not know. Weekly spend is not a row: felix cost has its own --tsv
# and takes about twenty seconds, so a surface runs it on its own timer.
#
# Read-only. It writes nothing, takes no network, and never runs claude, the
# suite, felix gate, claude mcp list or felix cost: every row reads a file, a
# table, a git object or launchd's own list. Its one slow row is the gate,
# because a receipt that matches the tree makes felix_verify_current recompute
# the decision epoch, which runs the project's probes. The CLI exports
# GIT_OPTIONAL_LOCKS=0 before any of this so git refreshes no index.
#
# Unknown is its own answer. A parser that is missing, a launchctl that cannot
# answer, a cache nobody wrote: each is `unknown` and never a zero or an ok.

# Libraries a row needs, sourced at call time and never at load: pulse.sh
# sources this file at load for the settings check, so a load-time source back
# would be a cycle. At call time every file is complete.
_felix_status_need() {
  command -v "$1" >/dev/null 2>&1 || . "$(dirname "${BASH_SOURCE[0]:-$0}")/$2.sh"
}

# Is Felix switched on in ~/.claude/settings.json? That file is what enables the
# plugin (enabledPlugins["felix@felix"]), so a broken hand edit there silently
# removes Felix, and nothing inside Felix can say so because its hooks never
# load. Prints `<value><TAB><detail>` and returns 0, always:
#   ok        parses, and enabledPlugins["felix@felix"] is true
#   felix-off parses, and that key is not true (a hook registered by hand is
#             named, since that is the other way Felix can be live)
#   invalid   does not parse, is empty, or its top level is not an object
#   missing   there is no file
#   unknown   no parser on this machine, or the file cannot be read
# ok is printed only on output exactly `ok` from a parser that exited 0, so a
# parser that is absent, empty, stubbed or wrong can never read as fine. Only
# the user settings file is read (CLAUDE_CONFIG_DIR when set): project and local
# settings can also enable a plugin, and this does not claim to know about them.
# FELIX_JQ names the parser, because on macOS 15 and later jq is always on PATH
# and without a knob "no parser" could never be exercised.
felix_settings_state() {
  local f="${CLAUDE_CONFIG_DIR:-${HOME:-}/.claude}/settings.json" jq="${FELIX_JQ:-jq}" out rc first v t
  local nl=$'\n' tab=$'\t' cr=$'\r'
  if [ -z "${CLAUDE_CONFIG_DIR:-}" ] && [ -z "${HOME:-}" ]; then
    printf 'unknown\tno home directory to look for settings.json in\n'; return 0
  fi
  if [ ! -e "$f" ]; then printf 'missing\t%s does not exist\n' "$f"; return 0; fi
  if [ ! -r "$f" ]; then printf 'unknown\t%s is not readable\n' "$f"; return 0; fi
  if ! command -v "$jq" >/dev/null 2>&1; then
    printf 'unknown\tno JSON parser on this machine (jq); %s was not read\n' "$f"; return 0
  fi
  out="$("$jq" -r 'if type == "object" then (if (try (.enabledPlugins["felix@felix"] == true) catch false) then "ok" else "felix-off \(try (.enabledPlugins["felix@felix"] | tojson) catch "null")" end) else "not-object" end' "$f" 2>&1)"; rc=$?
  if [ "$rc" -ne 0 ]; then
    first="${out%%$nl*}"; first="${first//$tab/ }"; first="${first//$cr/ }"
    printf 'invalid\t%s does not parse as JSON: %s\n' "$f" "$first"; return 0
  fi
  case "$out" in
    '')         printf 'invalid\t%s is empty\n' "$f" ;;
    not-object) printf 'invalid\t%s parses, and its top level is not an object\n' "$f" ;;
    ok)         printf 'ok\t%s enables felix@felix\n' "$f" ;;
    "felix-off "*)
      v="${out#felix-off }"; v="${v//$tab/ }"
      t="$(cat "$f" 2>/dev/null)"
      case "$t" in
        *harness/hooks/session-start*)
          printf 'felix-off\t%s does not enable felix@felix (enabledPlugins["felix@felix"] reads %s); a session-start hook is registered by hand\n' "$f" "$v" ;;
        *)
          printf 'felix-off\t%s does not enable felix@felix (enabledPlugins["felix@felix"] reads %s)\n' "$f" "$v" ;;
      esac ;;
    *) printf 'unknown\tthe parser answered something this check does not know\n' ;;
  esac
  return 0
}

# Is the felix.pulse LaunchAgent loaded, and how did its last run end? Prints
# `<state><TAB><value><TAB><detail>`. One `launchctl list` call, read whole and
# matched on the exact label in its third field: the table's Status column is
# already decoded (negative for a signal), where `launchctl list <label>` reports
# the raw wait status, in which exit 1 is 256.
felix_schedule_state() {
  local plist="${HOME:-}/Library/LaunchAgents/felix.pulse.plist" un list line pid rest st detail value
  local tab=$'\t' nl=$'\n'
  un="$(uname 2>/dev/null)"
  if [ "$un" != "Darwin" ]; then printf 'unknown\t-\tno launchd on %s\n' "${un:-this machine}"; return 0; fi
  if [ -z "${HOME:-}" ]; then printf 'unknown\t-\tno home directory to look for the agent in\n'; return 0; fi
  if [ ! -e "$plist" ]; then
    printf 'none\t-\tno felix.pulse agent; felix pulse --install schedules one\n'; return 0
  fi
  if ! command -v launchctl >/dev/null 2>&1 || ! list="$(launchctl list 2>/dev/null)" \
     || [ "${list%%$nl*}" != "PID${tab}Status${tab}Label" ]; then
    printf 'unknown\t-\tlaunchctl could not answer\n'; return 0
  fi
  line="$(printf '%s\n' "$list" | LC_ALL=C awk -F'\t' '!f && $3 == "felix.pulse" { print; f = 1 }')"
  if [ -z "$line" ]; then
    printf 'value\tnot-loaded\tthe agent'\''s plist exists and launchd has not loaded it\n'; return 0
  fi
  pid="${line%%$tab*}"; rest="${line#*$tab}"; st="${rest%%$tab*}"
  case "$st" in
    0)
      value=loaded; detail="last exit 0" ;;
    -[1-9]*)
      case "${st#-}" in
        *[!0-9]*) value=""; detail="launchctl reported a status this check does not read: $st" ;;
        *)        value="signal-${st#-}"; detail="loaded; the last run was stopped by signal ${st#-}" ;;
      esac ;;
    [1-9]*)
      case "$st" in
        *[!0-9]*) value=""; detail="launchctl reported a status this check does not read: $st" ;;
        *)        value="exit-$st"; detail="loaded; the last run exited $st" ;;
      esac ;;
    *)
      value=""; detail="launchctl reported a status this check does not read: $st" ;;
  esac
  case "$pid" in ''|*[!0-9]*) ;; *) detail="$detail; running now, pid $pid" ;; esac
  if [ -n "$value" ]; then printf 'value\t%s\t%s\n' "$value" "$detail"
  else printf 'unknown\t-\t%s\n' "$detail"; fi
  return 0
}

_felix_status_utc() {
  date -u -r "$1" +%Y-%m-%dT%H:%MZ 2>/dev/null || date -u -d "@$1" +%Y-%m-%dT%H:%MZ 2>/dev/null
}

# One row, normalised: value is `-` unless state is value, detail is one line
# and never empty.
_felix_status_row() {
  local row="$1" state="$2" value="$3" detail="$4" tab=$'\t' nl=$'\n' cr=$'\r'
  [ "$state" = value ] || value="-"
  [ -n "$value" ] || value="-"
  detail="${detail//$tab/ }"; detail="${detail//$nl/ }"; detail="${detail//$cr/ }"
  [ -n "$detail" ] || detail="-"
  printf '%s\t%s\t%s\t%s\n' "$row" "$state" "$value" "$detail"
}

# Split the `<a><TAB><b>[<TAB><c>]` a state function printed and emit the row.
_felix_status_from3() {
  local row="$1" r="$2" tab=$'\t' state value detail
  state="${r%%$tab*}"; r="${r#*$tab}"; value="${r%%$tab*}"; detail="${r#*$tab}"
  case "$state" in
    value|none|unknown) _felix_status_row "$row" "$state" "$value" "$detail" ;;
    *) _felix_status_row "$row" unknown - "the $row check printed nothing this check can read" ;;
  esac
}

_felix_status_settings() {
  local r value detail tab=$'\t'
  r="$(felix_settings_state)"
  if [ -z "$r" ]; then _felix_status_row settings unknown - "the settings check could not run"; return 0; fi
  value="${r%%$tab*}"; detail="${r#*$tab}"
  case "$value" in
    ok|felix-off|invalid|missing) _felix_status_row settings value "$value" "$detail" ;;
    *) _felix_status_row settings unknown - "$detail" ;;
  esac
}

# Days since the memory last reached its remote (felix_pulse_backup_age: whole
# days, or never), and when the pulse last ran, from the record it writes.
_felix_status_pulse() {
  local home="$1" age rec first="" ep="" last tab=$'\t'
  _felix_status_need felix_pulse_backup_age pulse
  if [ -z "$home" ] || [ ! -d "$home" ]; then
    _felix_status_row pulse unknown - "no Felix home resolved"; return 0
  fi
  rec="$home/state/pulse.status.tsv"
  if [ ! -e "$home/state/pulse.log" ] && [ ! -e "$rec" ]; then
    _felix_status_row pulse none - "the pulse has never run here"; return 0
  fi
  # Empty only when the stamp and the log are both absent, which beside a
  # record means the pulse ran and no push was ever verified.
  age="$(felix_pulse_backup_age "$home")"
  [ -n "$age" ] || age=never
  if [ -f "$rec" ] && [ -r "$rec" ]; then
    { IFS= read -r first || [ -n "$first" ]; } < "$rec" 2>/dev/null
    case "$first" in "# ran "*) ep="${first#"# ran "}" ;; esac
    case "$ep" in ''|*[!0-9]*) ep="" ;; esac
    [ "${#ep}" -le 12 ] || ep=""
  fi
  last=""
  [ -z "$ep" ] || last="$(_felix_status_utc "$ep")"
  if [ -n "$last" ]; then
    _felix_status_row pulse value "$age" "days since memory reached its remote; last run $last"
  else
    _felix_status_row pulse value "$age" "days since memory reached its remote; last run not recorded"
  fi
}

_felix_status_reach() {
  local proj="$1" home="$2"
  if [ -z "$proj" ]; then
    _felix_status_row reach none - "this directory is not a governed checkout"; return 0
  fi
  _felix_status_need felix_reach_summary reach
  _felix_status_from3 reach "$(felix_reach_summary "$proj" "$home")"
}

# felix_verify_current's answer, without git touching the checkout's index.
# GIT_OPTIONAL_LOCKS=0 stops git status from refreshing the index and does not
# stop git diff, which felix_tree_id runs: measured on git 2.54, a tracked file
# that is only stat-dirty (touched, not edited) has `git diff HEAD` rewrite
# .git/index under it. So when a receipt exists, and the tree id has to be
# computed, it is computed against a scratch copy of the index, removed after.
# A receipt that cannot be checked without writing the real index is not
# checked: empty output, which the caller reads as unknown.
_felix_status_verify() {
  local root="$1" home="$2" proj="$3" idx tmp="" out
  if [ -n "$(felix_verify_receipt "$root" "$home" 2>/dev/null)" ]; then
    idx="$(git -C "$root" rev-parse --git-path index 2>/dev/null)"
    case "$idx" in /*|'') ;; *) idx="$root/$idx" ;; esac
    if [ -n "$idx" ] && [ -f "$idx" ]; then
      tmp="$(mktemp "${TMPDIR:-/tmp}/felix-status-index.XXXXXX" 2>/dev/null)" || return 0
      cp "$idx" "$tmp" 2>/dev/null || { rm -f "$tmp"; return 0; }
    fi
  fi
  if [ -n "$tmp" ]; then
    out="$(GIT_INDEX_FILE="$tmp"; export GIT_INDEX_FILE; felix_verify_current "$root" "$home" "$proj" 2>/dev/null)"
    rm -f "$tmp"
  else
    out="$(felix_verify_current "$root" "$home" "$proj" 2>/dev/null)"
  fi
  printf '%s' "$out"
}

# felix_verify_current's answer for the checkout: current, stale with its reason,
# red, or none-run when no gate has recorded a receipt here.
_felix_status_gate() {
  local root="$1" home="$2" proj="$3" v kind reason tab=$'\t'
  if [ -z "$proj" ]; then
    _felix_status_row gate none - "this directory is not a governed checkout"; return 0
  fi
  _felix_status_need felix_verify_current verify
  v="$(_felix_status_verify "$root" "$home" "$proj")"
  kind="${v%%$tab*}"; reason="${v#*$tab}"
  [ "$reason" != "$v" ] || reason=""
  case "$kind" in
    current) _felix_status_row gate value current "-" ;;
    red)     _felix_status_row gate value red "the last gate run here was red" ;;
    stale)   _felix_status_row gate value stale "${reason:-the receipt is not current}" ;;
    none)    _felix_status_row gate value none-run "no gate has run in this checkout" ;;
    *)       _felix_status_row gate unknown - "the receipt could not be read" ;;
  esac
}

# The five rows for the directory <cwd> under the Felix home <home>.
felix_status_rows() {
  local home="$1" cwd="$2" root proj
  _felix_status_need felix_repo_root resolve
  root="$(felix_repo_root "$cwd" 2>/dev/null)"
  proj="$(felix_resolve_project "$cwd" "$home" 2>/dev/null)" || proj=""
  _felix_status_settings
  _felix_status_from3 schedule "$(felix_schedule_state)"
  _felix_status_pulse "$home"
  _felix_status_reach "$proj" "$home"
  _felix_status_gate "$root" "$home" "$proj"
}

# felix status [--tsv]: the rows as written, or aligned for a person, with the
# value shown when there is one and the state word otherwise. No header.
felix_status_command() {
  local home="$1" cwd="$2" tsv="${3:-0}"
  if [ "$tsv" -eq 1 ]; then felix_status_rows "$home" "$cwd"; return 0; fi
  felix_status_rows "$home" "$cwd" | while IFS=$'\t' read -r row state value detail; do
    [ -n "$row" ] || continue
    [ "$state" = value ] || value="$state"
    printf '%-9s %-12s %s\n' "$row" "$value" "$detail"
  done
  return 0
}
