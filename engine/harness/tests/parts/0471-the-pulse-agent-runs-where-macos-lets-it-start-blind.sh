printf '\nthe pulse agent runs where macOS lets it start (contract P1-P5, blind)\n'
# Blind, written from docs/2026-10-29-pulse-agent-contract.md alone on
# 2026-10-29. Nothing here was read off lib/pulse.sh or the pulse command.
#
# launchd opens StandardOutPath itself, before the program starts, and macOS
# refuses that open under ~/Documents. On the new Mac the agent's capture sat
# inside the Felix home there, and the spawn failed with 78 every morning while
# nothing Felix reads said so. These assertions drive the real CLI the way the
# install block of part 0470 does: launchctl and uname are stubbed in a PATH
# directory, HOME is a fixture directory, and a registered marketplace root
# serves the engine. Every name under $TMP here begins pa71-, so this part runs
# alone (contract C) and touches nothing another part builds.
#
# The plist is plain XML the engine writes. It is read by flattening it to one
# line and walking it with index(), which BWK awk and gawk both have.
PA71B="$TMP/pa71-bin"; PA71D="$TMP/pa71-logs"; mkdir -p "$PA71B" "$PA71D"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "${LAUNCHCTL_LOG:-/dev/null}"\nexit 0\n' > "$PA71B/launchctl"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "${UNAME_STUB:-Darwin}"\n' > "$PA71B/uname"
chmod +x "$PA71B/launchctl" "$PA71B/uname"
PA71S="$TMP/pa71-served"; mkdir -p "$PA71S/engine/harness"
printf '#!/bin/sh\n' > "$PA71S/engine/harness/felix"; chmod +x "$PA71S/engine/harness/felix"
PA71S="$(cd "$PA71S" && pwd -P)"
_pa71_home() {   # DIR -> a fake HOME whose marketplace registry serves $PA71S
  mkdir -p "$1/.claude/plugins"
  printf '{\n  "felix": {\n    "installLocation": "%s"\n  }\n}\n' "$PA71S" > "$1/.claude/plugins/known_marketplaces.json"
}
_pa71_felix() {  # HOME UNAME LAUNCHCTL_LOG ARGS... -> output in PA71OUT, status in PA71RC
  local h="$1" u="$2" l="$3"; shift 3
  PA71OUT="$(cd "$REPO" && HOME="$h" PATH="$PA71B:$PATH" UNAME_STUB="$u" LAUNCHCTL_LOG="$l" \
             "$FELIX" pulse "$@" 2>&1)"; PA71RC=$?
}
_pa71_flat() { tr '\n\r\t' '   ' < "$1" 2>/dev/null; }
_pa71_args() {   # PLIST -> each ProgramArguments string, one per line
  _pa71_flat "$1" | LC_ALL=C awk '{
    i = index($0, "<key>ProgramArguments</key>"); if (!i) exit
    s = substr($0, i + 27); a = index(s, "<array>"); e = index(s, "</array>")
    if (!a || !e || e < a) exit
    s = substr(s, a + 7, e - a - 7)
    while ((p = index(s, "<string>")) > 0) {
      s = substr(s, p + 8); q = index(s, "</string>"); if (!q) exit
      print substr(s, 1, q - 1); s = substr(s, q + 9)
    }
  }'
}
_pa71_str() {    # PLIST KEY -> the <string> that is KEY's value
  _pa71_flat "$1" | LC_ALL=C awk -v k="<key>$2</key>" '{
    i = index($0, k); if (!i) exit
    s = substr($0, i + length(k)); sub(/^ */, "", s)
    if (substr(s, 1, 8) != "<string>") exit
    s = substr(s, 9); q = index(s, "</string>"); if (q) print substr(s, 1, q - 1)
  }'
}
_pa71_under() {  # PATH ROOT -> status 0 when PATH is ROOT or below it
  [ -n "$2" ] || return 1
  case "$1" in "$2"|"$2"/*) return 0 ;; esac; return 1
}

# ------------------------------------------------------------ install --------
PA71H="$TMP/pa71-home"; mkdir -p "$PA71H"; PA71H="$(cd "$PA71H" && pwd -P)"; _pa71_home "$PA71H"
PA71P="$PA71H/Library/LaunchAgents/felix.pulse.plist"; PA71C="$PA71H/Library/Logs/felix/pulse.launchd.log"
_pa71_felix "$PA71H" Darwin "$PA71D/launchctl.ok.log" --install
is "pulse agent P5: install on Darwin answers 0" "$PA71RC" "0"
[ -f "$PA71P" ] && ok "pulse agent P5: install writes ~/Library/LaunchAgents/felix.pulse.plist" \
  || bad "pulse agent P5: install writes ~/Library/LaunchAgents/felix.pulse.plist" "no $PA71P"
has "pulse agent P5: and launchd is handed that plist" "$(cat "$PA71D/launchctl.ok.log" 2>/dev/null)" "$PA71P"

# P1: /bin/bash, the served engine's felix, pulse, and nothing else.
_pa71a="$(_pa71_args "$PA71P")"
is "pulse agent P1: ProgramArguments holds exactly three strings" \
   "$(printf '%s\n' "$_pa71a" | LC_ALL=C awk 'NF' | wc -l | tr -d ' ')" "3"
is "pulse agent P1: the first is /bin/bash" "$(printf '%s\n' "$_pa71a" | sed -n 1p)" "/bin/bash"
is "pulse agent P1: the second is the served engine's felix, not the running copy" \
   "$(printf '%s\n' "$_pa71a" | sed -n 2p)" "$PA71S/engine/harness/felix"
is "pulse agent P1: the third is pulse" "$(printf '%s\n' "$_pa71a" | sed -n 3p)" "pulse"
is "pulse agent P1: the three in order are /bin/bash, the served felix, pulse" \
   "$(printf '%s\n' "$_pa71a" | tr '\n' '|')" "/bin/bash|$PA71S/engine/harness/felix|pulse|"
case "$_pa71a" in */usr/bin/env*) bad "pulse agent P1: the program does not go through /usr/bin/env" "$_pa71a" ;;
  *) ok "pulse agent P1: the program does not go through /usr/bin/env" ;; esac

# P2: one capture file, under ~/Library/Logs/felix, outside the home and Documents.
_pa71o="$(_pa71_str "$PA71P" StandardOutPath)"; _pa71e="$(_pa71_str "$PA71P" StandardErrorPath)"
is "pulse agent P2: StandardOutPath is \$HOME/Library/Logs/felix/pulse.launchd.log" "$_pa71o" "$PA71C"
is "pulse agent P2: StandardErrorPath is \$HOME/Library/Logs/felix/pulse.launchd.log" "$_pa71e" "$PA71C"
if [ -n "$_pa71o" ] && [ "$_pa71o" = "$_pa71e" ]; then ok "pulse agent P2: stdout and stderr are captured to the same file"
else bad "pulse agent P2: stdout and stderr are captured to the same file" "out [$_pa71o] err [$_pa71e]"; fi
_pa71fr="$(cd "$FROOT" && pwd -P)"; _pa71in=""
for _pa71x in "$_pa71o" "$_pa71e"; do
  for _pa71r in "$FROOT" "$_pa71fr" "${FELIX_HOME:-}" "${FELIX_HOME_DIR:-}" "$REPO"; do
    _pa71_under "$_pa71x" "$_pa71r" && _pa71in="$_pa71in [$_pa71x under $_pa71r]"
  done
done
if [ -n "$_pa71o$_pa71e" ] && [ -z "$_pa71in" ]; then ok "pulse agent P2: neither capture path is inside the Felix home"
else bad "pulse agent P2: neither capture path is inside the Felix home" "out [$_pa71o] err [$_pa71e]$_pa71in"; fi
_pa71in=""
for _pa71x in "$_pa71o" "$_pa71e"; do
  _pa71_under "$_pa71x" "$PA71H/Documents" && _pa71in="$_pa71in [$_pa71x]"
done
if [ -n "$_pa71o$_pa71e" ] && [ -z "$_pa71in" ]; then ok "pulse agent P2: neither capture path is under \$HOME/Documents"
else bad "pulse agent P2: neither capture path is under \$HOME/Documents" "out [$_pa71o] err [$_pa71e]$_pa71in"; fi

# P3: launchd will not make the parent, so the installer does.
[ -d "$PA71H/Library/Logs/felix" ] && ok "pulse agent P3: a successful install leaves ~/Library/Logs/felix in place" \
  || bad "pulse agent P3: a successful install leaves ~/Library/Logs/felix in place" "no directory $PA71H/Library/Logs/felix"

# P4: the message names both logs.
has "pulse agent P4: the install message names the capture file" "$PA71OUT" "Library/Logs/felix/pulse.launchd.log"
has "pulse agent P4: and still names the pulse's own log, state/pulse.log" \
    "$(printf '%s\n' "$PA71OUT" | sed 's/pulse\.log\.launchd\.log//g')" "state/pulse.log"

# P5: label and schedule hold.
is "pulse agent P5: the label is still felix.pulse" "$(_pa71_str "$PA71P" Label)" "felix.pulse"
_pa71t="$( { tr -d ' \t\r\n' < "$PA71P"; } 2>/dev/null)"
has "pulse agent P5: the agent still runs on a StartCalendarInterval" "$_pa71t" "<key>StartCalendarInterval</key><dict>"
has "pulse agent P5: at hour 9" "$_pa71t" "<key>Hour</key><integer>9</integer>"
has "pulse agent P5: and minute 7" "$_pa71t" "<key>Minute</key><integer>7</integer>"

# P5: uninstall takes the plist back and leaves the capture file, since a log is
# not a grant. The file is made here if the install did not make its directory,
# so this holds or fails on uninstall alone.
mkdir -p "$PA71H/Library/Logs/felix" 2>/dev/null; printf 'a launchd line\n' >> "$PA71C"
_pa71_felix "$PA71H" Darwin "$PA71D/launchctl.un.log" --uninstall
is "pulse agent P5: uninstall answers 0" "$PA71RC" "0"
[ -e "$PA71P" ] && bad "pulse agent P5: uninstall removes the plist" "still present: $PA71P" \
  || ok "pulse agent P5: uninstall removes the plist"
has "pulse agent P5: uninstall leaves the capture file and what it holds" \
    "$(cat "$PA71C" 2>/dev/null)" "a launchd line"

# P5: the non-Darwin refusal stays.
PA71L="$TMP/pa71-home-linux"; mkdir -p "$PA71L"; PA71L="$(cd "$PA71L" && pwd -P)"; _pa71_home "$PA71L"
_pa71_felix "$PA71L" Linux "$PA71D/launchctl.linux.log" --install
is "pulse agent P5: a machine without launchd is still refused with 1" "$PA71RC" "1"
[ -e "$PA71L/Library/LaunchAgents/felix.pulse.plist" ] \
  && bad "pulse agent P5: and no plist is written on it" "plist appeared" \
  || ok  "pulse agent P5: and no plist is written on it"

# ------------------------------------------------- P3: no directory, no agent -
# ~/Library/Logs is a regular file here, so ~/Library/Logs/felix cannot be made.
PA71F="$TMP/pa71-home-blocked"; mkdir -p "$PA71F/Library"; PA71F="$(cd "$PA71F" && pwd -P)"; _pa71_home "$PA71F"
printf 'not a directory\n' > "$PA71F/Library/Logs"
_pa71_felix "$PA71F" Darwin "$PA71D/launchctl.blocked.log" --install
is "pulse agent P3: install exits 1 when ~/Library/Logs/felix cannot be created" "$PA71RC" "1"
has "pulse agent P3: and says which directory it could not create" "$PA71OUT" "Library/Logs/felix"
[ -e "$PA71F/Library/LaunchAgents/felix.pulse.plist" ] \
  && bad "pulse agent P3: and writes no plist" "plist written: $PA71F/Library/LaunchAgents/felix.pulse.plist" \
  || ok  "pulse agent P3: and writes no plist"
if [ -s "$PA71D/launchctl.blocked.log" ]; then
  bad "pulse agent P3: and hands launchctl nothing" "launchctl got: $(tr '\n' '|' < "$PA71D/launchctl.blocked.log")"
else ok "pulse agent P3: and hands launchctl nothing"; fi
