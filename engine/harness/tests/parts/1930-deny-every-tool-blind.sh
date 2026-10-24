printf '\nthe deny floor judges effects on every tool (audit b16, C020, blind)\n'
# Written blind on 2026-10-24 from docs/2026-10-24-audit-fixes/b16-deny-floor-judges-effects-on-every-tool.md
# alone (sections 2 and 4, A1 to A31). No engine code was read: hooks.json and settings.json are read
# here only as the contract says to read them, and the hook is driven as a black box by _pre
# (tests/lib/deny-hook.sh). Every part runs alone: each fixture below is this part's own, under $TMP,
# and it relies on the prelude only (FROOT, TMP, MEM, REAL_HARNESS, _pre, _fx_cd, ok, bad, is, skip).
#
# "Refused" is exit 2 with the row's whole reason on stderr; "allowed" is exit 0 with nothing on
# stderr; any other exit is named in the failure. A fixture that cannot be built makes its
# assertions skips with the same names, never passes.
#
# Readings, where the contract leaves room:
# - A1 and A3 read "the span" from the line holding "PreToolUse" to the next line that opens another
#   event's array (a key that begins with a capital, then a colon and a bracket). That is the line
#   holding "PostToolUse" when that event comes next, as the contract says it does in hooks.json; a
#   settings.json that orders its events otherwise is still read over its PreToolUse entry alone.
# - Every Monitor payload carries "description" and "timeout_ms" after "command", as A4's does.
# - A27 wants the row's own reason as well as the line saying the row stood, since "refused" means
#   the row's reason is on stderr; a scoped refusal through an MCP tool is still that row's refusal.
# - A20 to A22 are said unknown, not passed, when the Read probe of A23 left the git log empty: an
#   empty log from a shim the hook never reaches proves nothing.
# - A30's payload that does not parse is the text `not json at all` itself, as 0600 sends it.
# - A2, A19 and A30 are one assertion each; the failure names which half went wrong.

# ---- helpers
_dt_esc() { printf '%s' "$1" | LC_ALL=C sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }
_dt_mon()  { printf '{"tool_name":"Monitor","tool_input":{"command":"%s","description":"d","timeout_ms":1000}}' "$(_dt_esc "$1")"; }
_dt_bash() { printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$(_dt_esc "$1")"; }
# CWD|- TOOL INPUT-JSON: a payload with a session and, unless -, the cwd it names (as 0620's are).
_dt_cwdpay() {
  local c=""; [ "$1" = - ] || c="\"cwd\":\"$(_dt_esc "$1")\","
  printf '{"session_id":"s1930",%s"tool_name":"%s","tool_input":%s}' "$c" "$2" "$3"
}
# DIR PAYLOAD REASON -> _dt_got: refused (exit 2, REASON on stderr), allowed (exit 0, stderr empty),
# or what happened instead; _dt_err: the stderr. _dt_path, when set, is the PATH the hook runs under.
_dt_path=""
_dt_v() {
  local rc
  rm -f "$FROOT/.deny-err"
  if [ -n "$_dt_path" ]; then ( cd "$1" && PATH="$_dt_path" && export PATH && _pre "$2" ) >/dev/null 2>&1
  else ( cd "$1" && _pre "$2" ) >/dev/null 2>&1; fi
  rc=$?
  _dt_err="$(cat "$FROOT/.deny-err" 2>/dev/null)"
  case "$rc" in
    2) case "$_dt_err" in *"$3"*) _dt_got=refused ;; *) _dt_got="exit 2 without [$3] on stderr" ;; esac ;;
    0) if [ -z "$_dt_err" ]; then _dt_got=allowed; else _dt_got="exit 0 with something on stderr"; fi ;;
    *) _dt_got="exit $rc, which is neither 0 nor 2" ;;
  esac
}
_dt_is() {   # NAME WANT: one assertion from the last _dt_v
  if [ "$_dt_got" = "$2" ]; then ok "$1"
  else bad "$1" "wanted $2, got $_dt_got; stderr [$(printf '%s' "$_dt_err" | LC_ALL=C tr '\n' ' ' | cut -c 1-300)]"; fi
}
_dt_nofx=""
_dt_case() {   # NAME DIR WANT REASON PAYLOAD
  if [ -n "$_dt_nofx" ]; then skip "$1" "$_dt_nofx"; return 0; fi
  _dt_v "$2" "$5" "$4"; _dt_is "$1" "$3"
}
# FILE -> the lines from the first holding "PreToolUse" to the next opening another event's array.
_dt_span() {
  LC_ALL=C awk '
    on && !/"PreToolUse"/ && /"[ABCDEFGHIJKLMNOPQRSTUVWXYZ][ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz]*"[[:space:]]*:[[:space:]]*\[/ { print; exit }
    /"PreToolUse"/ { on = 1 }
    on { print }' "$1" 2>/dev/null
}
_dt_count() {   # TEXT NEEDLE -> how many lines of TEXT hold NEEDLE
  printf '%s\n' "$1" | _DTN="$2" LC_ALL=C awk 'index($0, ENVIRON["_DTN"]) { n++ } END { print n + 0 }'
}
_dt_root="$(cd "$REAL_HARNESS/../.." && pwd)"

# ---- the wiring (B1, B2)
_dt_hj="$REAL_HARNESS/../hooks/hooks.json"
_dt_n="deny floor A1 (B1): hooks.json binds PreToolUse with no matcher, so every tool reaches the hook, and runs pre-tool once"
if [ -f "$_dt_hj" ]; then
  _dt_sp="$(_dt_span "$_dt_hj")"
  if [ -z "$_dt_sp" ]; then _dt_x="no line of hooks.json holds \"PreToolUse\""
  elif [ "$(_dt_count "$_dt_sp" '"matcher"')" != 0 ]; then _dt_x="the PreToolUse span still holds a \"matcher\""
  else _dt_x="no matcher, $(_dt_count "$_dt_sp" 'harness/hooks/pre-tool') line(s) run harness/hooks/pre-tool"; fi
  is "$_dt_n" "$_dt_x" "no matcher, 1 line(s) run harness/hooks/pre-tool"
else skip "$_dt_n" "no hooks.json beside this harness"; fi

_dt_n="deny floor A2 (B1): hooks.json keeps every other event once, and SessionStart's matcher is startup|resume|clear|compact"
if [ -f "$_dt_hj" ]; then
  _dt_x=""
  for _dt_e in PostToolUse SubagentStop SessionEnd SessionStart UserPromptSubmit Stop SubagentStart; do
    _dt_k="$(LC_ALL=C grep -o "\"$_dt_e\"[[:space:]]*:" "$_dt_hj" 2>/dev/null | LC_ALL=C awk 'END { print NR }')"
    [ "$_dt_k" = 1 ] || _dt_x="$_dt_x $_dt_e is a key $_dt_k time(s);"
  done
  _dt_m="$(LC_ALL=C awk '/"SessionStart"/ { on = 1 }
    on && /"matcher"/ && !f { s = $0; sub(/.*"matcher"[[:space:]]*:[[:space:]]*"/, "", s); sub(/".*/, "", s); print s; f = 1 }' "$_dt_hj" 2>/dev/null)"
  [ "$_dt_m" = "startup|resume|clear|compact" ] || _dt_x="$_dt_x the SessionStart matcher is [$_dt_m];"
  is "$_dt_n" "$_dt_x" ""
else skip "$_dt_n" "no hooks.json beside this harness"; fi

_dt_sj="$_dt_root/.claude/settings.json"
_dt_n="deny floor A3 (B2): the cloud copy in .claude/settings.json binds PreToolUse with no matcher, behind the CLAUDE_CODE_REMOTE guard"
if [ -f "$_dt_sj" ]; then
  _dt_sp="$(_dt_span "$_dt_sj")"
  _dt_c="$(printf '%s\n' "$_dt_sp" | LC_ALL=C awk 'index($0, "CLAUDE_CODE_REMOTE") && index($0, "engine/harness/hooks/pre-tool") { n++ } END { print n + 0 }')"
  if [ -z "$_dt_sp" ]; then _dt_x="no line of settings.json holds \"PreToolUse\""
  elif [ "$(_dt_count "$_dt_sp" '"matcher"')" != 0 ]; then _dt_x="the PreToolUse span still holds a \"matcher\""
  elif [ "$_dt_c" = 0 ]; then _dt_x="no command in the span holds both CLAUDE_CODE_REMOTE and engine/harness/hooks/pre-tool"
  else _dt_x="no matcher, guarded command"; fi
  is "$_dt_n" "$_dt_x" "no matcher, guarded command"
else skip "$_dt_n" "no .claude/settings.json beside this harness"; fi

# ---- fixture T1: a checkout bound to widget by marker, and the four rows of the contract's table
_dt_t1="$TMP/deny1930-t1"; mkdir -p "$_dt_t1"
( _fx_cd "$_dt_t1" && git init -q -b main ) >/dev/null 2>&1
_dt_t1="$(cd "$_dt_t1" && pwd -P)"
printf 'widget\n' > "$_dt_t1/.felix"
_dt_t1tab() {
  mkdir -p "$FROOT/projects/widget"
  { printf 'Bash\tgit push --force\tforce push drops commits\n'
    printf 'Bash\tpkill -f\ta pattern kill reaches other sessions\n'
    printf 'Monitor\tsleep 600\ta monitor must not sleep this long\n'
    printf 'Read\t\\.env$\treading a secret\n'
  } > "$FROOT/projects/widget/deny.tsv"
}
_dt_t1tab
{ [ -d "$_dt_t1/.git" ] && [ -f "$_dt_t1/.felix" ] && [ -s "$FROOT/projects/widget/deny.tsv" ]; } \
  || _dt_nofx="fixture T1 could not be built (a repository at $_dt_t1, its marker, the widget deny.tsv)"
_dt_says() {   # -> the denied lines of widget's says.log that hold pkill -f x
  if [ -f "$MEM/widget/says.log" ]; then
    LC_ALL=C awk -F'\t' '$2 == "denied" && index($0, "pkill -f x") { n++ } END { print n + 0 }' "$MEM/widget/says.log"
  else echo 0; fi
}
_dt_pk="a pattern kill reaches other sessions"; _dt_fp="force push drops commits"

printf '\ndeny floor: a Bash row judges the command of every shell tool (B3 to B5)\n'
_dt_s0="$(_dt_says)"
_dt_case "deny floor A4 (B3): a Monitor command that kills by pattern is refused, with the Bash row's reason" "$_dt_t1" refused "$_dt_pk" \
  '{"tool_name":"Monitor","tool_input":{"command":"pkill -f x","description":"d","timeout_ms":1000}}'
_dt_s1="$(_dt_says)"
_dt_case "deny floor A5 (B3): a Monitor command that force-pushes is refused" "$_dt_t1" refused "$_dt_fp" "$(_dt_mon 'git push --force origin feat/x')"
_dt_case "deny floor A6 (B3): the same pattern kill through Bash is refused, as it always was" "$_dt_t1" refused "$_dt_pk" "$(_dt_bash 'pkill -f x')"
_dt_case "deny floor A7 (B4): mcp__terminal__run_in_terminal running a pattern kill is refused" "$_dt_t1" refused "$_dt_pk" \
  '{"tool_name":"mcp__terminal__run_in_terminal","tool_input":{"command":"pkill -f x","title":"t"}}'
_dt_case "deny floor A8 (B4): mcp__claude-flow__terminal_execute running a force push is refused" "$_dt_t1" refused "$_dt_fp" \
  '{"tool_name":"mcp__claude-flow__terminal_execute","tool_input":{"command":"git push --force origin feat/x","sessionId":"s1"}}'
_dt_case "deny floor A9 (B4): any mcp__ tool whose input carries a command is read as a shell command" "$_dt_t1" refused "$_dt_pk" \
  '{"tool_name":"mcp__fixture__shell","tool_input":{"command":"pkill -f x"}}'
_dt_case "deny floor A10 (B5): a Monitor command that only echoes a quoted pattern kill is allowed" "$_dt_t1" allowed "" "$(_dt_mon "echo 'pkill -f x'")"
_dt_case "deny floor A11 (B5): a Monitor command that hands a pattern kill to bash -c is refused" "$_dt_t1" refused "$_dt_pk" "$(_dt_mon "bash -c 'pkill -f x'")"
_dt_case "deny floor A12 (B5): a Monitor tail piped to a grep for the quoted words is allowed" "$_dt_t1" allowed "" \
  "$(_dt_mon "tail -f log | grep --line-buffered 'pkill -f x'")"
_dt_a="$(printf '%1100s' '' | LC_ALL=C tr ' ' a)"
_dt_case "deny floor A13 (B5): a Monitor command over 1,024 characters is read whole, and its pattern kill refused" "$_dt_t1" refused "$_dt_pk" \
  "$(_dt_mon "echo $_dt_a ; pkill -f x")"

printf '\ndeny floor: the tool column keeps its meaning (B6, B7)\n'
_dt_case "deny floor A14 (B6): a Monitor row refuses its Monitor command, with its own reason" "$_dt_t1" refused "a monitor must not sleep this long" "$(_dt_mon 'sleep 600')"
_dt_case "deny floor A15 (B6): and the same text through Bash is not that row's to refuse" "$_dt_t1" allowed "" "$(_dt_bash 'sleep 600')"
_dt_case "deny floor A16 (B7): StructuredOutput is not a shell tool, whatever its input holds" "$_dt_t1" allowed "" \
  '{"tool_name":"StructuredOutput","tool_input":{"command":"pkill -f x"}}'
_dt_case "deny floor A17 (B7): nor is a first-party tool of an unknown name" "$_dt_t1" allowed "" \
  '{"tool_name":"Fixturetool","tool_input":{"command":"pkill -f x"}}'
_dt_case "deny floor A18 (B7): a command key inside a JSON string of an mcp__ tool is not a key" "$_dt_t1" allowed "" \
  '{"tool_name":"mcp__fixture__memory","tool_input":{"key":"k","value":"{\"command\": \"pkill -f x\"}"}}'
_dt_n="deny floor A19 (B6): a Bash row never judges a Write's file_path, and a Read row still refuses a Read"
if [ -n "$_dt_nofx" ]; then skip "$_dt_n" "$_dt_nofx"
else
  _dt_v "$_dt_t1" '{"tool_name":"Write","tool_input":{"file_path":"/w/pkill -f x","content":"y"}}' ""; _dt_w="$_dt_got"
  _dt_v "$_dt_t1" '{"tool_name":"Read","tool_input":{"file_path":"/w/.env"}}' "reading a secret"; _dt_r="$_dt_got"
  is "$_dt_n" "Write $_dt_w, Read $_dt_r" "Write allowed, Read refused"
fi

# ---- fixture T2 (B8): a project resolved by remote_match, and a git shim that logs every call
printf '\ndeny floor: a call with nothing to read is cheap (B8)\n'
_dt_gp="$FROOT/projects/gizmo1930"; mkdir -p "$_dt_gp"
printf '{"name":"gizmo1930","remote_match":"example.com/gizmo1930"}\n' > "$_dt_gp/project.json"
printf 'Bash\tpkill -f\tno pattern kills\n' > "$_dt_gp/deny.tsv"
_dt_t2="$TMP/gizmo1930-repo"; mkdir -p "$_dt_t2"
( _fx_cd "$_dt_t2" && git init -q -b main && git remote add origin https://example.com/gizmo1930.git ) >/dev/null 2>&1
_dt_t2="$(cd "$_dt_t2" && pwd -P)"
_dt_git="$(type -P git 2>/dev/null)"
_dt_shim="$TMP/shim1930"; _dt_glog="$TMP/shim1930.log"; mkdir -p "$_dt_shim"
if [ -n "$_dt_git" ]; then
  cat > "$_dt_shim/git" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> '$_dt_glog'
exec '$_dt_git' "\$@"
EOF
  chmod 755 "$_dt_shim/git"
fi
_dt_nofx2=""
{ [ -n "$_dt_git" ] && [ -x "$_dt_shim/git" ] && [ ! -e "$_dt_t2/.felix" ] \
  && [ "$(git -C "$_dt_t2" config --get remote.origin.url 2>/dev/null)" = "https://example.com/gizmo1930.git" ]; } \
  || _dt_nofx2="fixture T2 could not be built (the git shim, or the repository with its origin and no marker)"
_dt_gcall() {   # PAYLOAD REASON -> _dt_got, _dt_err, and _dt_gn: the git calls the shim logged
  : > "$_dt_glog"
  _dt_path="$_dt_shim:$PATH"; _dt_v "$_dt_t2" "$1" "$2"; _dt_path=""
  _dt_gn="$(LC_ALL=C awk 'END { print NR }' "$_dt_glog" 2>/dev/null)"
}
# The probe first, so that A20 to A22 know whether the shim is on the path the hook takes.
_dt_onpath=""; _dt_probe="not run"
if [ -z "$_dt_nofx2" ]; then
  _dt_gcall '{"tool_name":"Read","tool_input":{"file_path":"x"}}' ""
  if [ "$_dt_got" != allowed ]; then _dt_probe="$_dt_got"
  elif [ "${_dt_gn:-0}" -ge 1 ] 2>/dev/null; then _dt_probe="exit 0, and the shim logged git"; _dt_onpath=1
  else _dt_probe="exit 0, and the shim logged nothing"; fi
fi
_dt_b8() {   # NAME PAYLOAD
  local v want="exit 0, nothing on stderr, no git"
  if [ -n "$_dt_nofx2" ]; then skip "$1" "$_dt_nofx2"; return 0; fi
  _dt_gcall "$2" ""
  if [ "$_dt_got" != allowed ]; then v="$_dt_got"
  elif [ "${_dt_gn:-x}" != 0 ]; then v="the hook ran git ${_dt_gn:-?} time(s): $(LC_ALL=C head -3 "$_dt_glog" 2>/dev/null | LC_ALL=C tr '\n' ';')"
  elif [ -z "$_dt_onpath" ]; then v="unknown: the Read probe left the git log empty, so the shim is not shown to be on the hook's path"
  else v="$want"; fi
  is "$1" "$v" "$want"
}
_dt_b8 "deny floor A20 (B8): a Glob, which carries no file_path, exits 0 before the project is resolved, running no git" \
  '{"tool_name":"Glob","tool_input":{"pattern":"**/*.sh","path":"."}}'
_dt_b8 "deny floor A21 (B8): an mcp__ tool with no command exits 0 running no git" \
  '{"tool_name":"mcp__fixture__navigate","tool_input":{"url":"https://example.com"}}'
_dt_b8 "deny floor A22 (B8): a Monitor with no command, only a nested url, exits 0 running no git" \
  '{"tool_name":"Monitor","tool_input":{"ws":{"url":"wss://example.com/s"},"description":"d","timeout_ms":1000}}'
_dt_n="deny floor A23 (B8): a Read with a file_path resolves the project, so the shim is on the hook's path"
if [ -n "$_dt_nofx2" ]; then skip "$_dt_n" "$_dt_nofx2"; else is "$_dt_n" "$_dt_probe" "exit 0, and the shim logged git"; fi
_dt_n="deny floor A24 (B8): in the same fixture a Bash pattern kill is still refused"
if [ -n "$_dt_nofx2" ]; then skip "$_dt_n" "$_dt_nofx2"
else _dt_path="$_dt_shim:$PATH"; _dt_v "$_dt_t2" "$(_dt_bash 'pkill -f x')" "no pattern kills"; _dt_path=""; _dt_is "$_dt_n" refused; fi
[ -z "$FROOT" ] || rm -rf "$FROOT/projects/gizmo1930"

# ---- fixture T3 (B9): a governed checkout and a scratch clone, as 0620 builds them
printf '\ndeny floor: rows scoped to the checkout, through every shell tool (B9)\n'
_dt_sc="$TMP/scoped1930"; _dt_gov="$_dt_sc/gov"; _dt_scr="$_dt_sc/scr"
mkdir -p "$_dt_gov" "$_dt_scr"
( _fx_cd "$_dt_gov" && git init -q -b main && printf 'widget\n' > .felix && printf 'readme\n' > README \
  && git add .felix README && git -c user.name=t -c user.email=t@t commit -qm init \
  && git remote add origin https://example.com/widget.git ) >/dev/null 2>&1
( _fx_cd "$_dt_scr" && git clone -q "$_dt_gov" clone ) >/dev/null 2>&1
_dt_gov="$(cd "$_dt_gov" && pwd -P)"; _dt_scr="$(cd "$_dt_scr" && pwd -P)"; _dt_cl="$_dt_scr/clone"
_dt_tr="$(cd -P "${TMPDIR:-/tmp}" 2>/dev/null && pwd -P)"
_dt_n="deny floor T3: the scoped fixture has its governed checkout and its clone, and the clone lies under the suite's TMPDIR"
_dt_nofx3=""
if [ -d "$_dt_gov/.git" ] && [ -f "$_dt_gov/.felix" ] && [ -d "$_dt_cl/.git" ] && [ -n "$_dt_tr" ] \
   && case "$_dt_cl/" in "${_dt_tr%/}/"*) true ;; *) false ;; esac; then ok "$_dt_n"
else
  bad "$_dt_n" "checkout [$_dt_gov] clone [$_dt_cl] TMPDIR [${TMPDIR:-}]"
  _dt_nofx3="fixture T3 could not be built under the suite's TMPDIR"
fi
printf 'Bash\tgit( +-[^ ]+( +[^ ]+)?)* +remote +(add|set-url|rename|remove|rm)( |$)\tthe remote is where the person is\tcheckout\n' \
  > "$FROOT/projects/widget/deny.tsv"
_dt_rem='{"command":"git remote add up https://example.com/up.git"'
_dt_rr="the remote is where the person is"
_dt_v3() { _dt_v "$_dt_gov" "$(_dt_cwdpay "$1" "$2" "$3")" "$_dt_rr"; }   # CWD|- TOOL INPUT-JSON, run from the checkout
_dt_case3() {   # NAME WANT CWD|- TOOL INPUT-JSON
  if [ -n "$_dt_nofx3" ]; then skip "$1" "$_dt_nofx3"; return 0; fi
  _dt_v3 "$3" "$4" "$5"; _dt_is "$1" "$2"
}
_dt_case3 "deny floor A25 (B9): a Monitor command acting only in a scratch clone is passed over by a checkout-scoped row" allowed \
  "$_dt_cl" Monitor "$_dt_rem,\"description\":\"d\",\"timeout_ms\":1000}"
_dt_case3 "deny floor A26 (B9): the same Monitor command with no cwd starts in the governed checkout, and is refused" refused \
  - Monitor "$_dt_rem,\"description\":\"d\",\"timeout_ms\":1000}"
_dt_n="deny floor A27 (B9): through an mcp__ shell tool, where the command runs cannot be told, the scoped row stands, and says so"
if [ -n "$_dt_nofx3" ]; then skip "$_dt_n" "$_dt_nofx3"
else
  _dt_v3 "$_dt_cl" mcp__terminal__run_in_terminal "$_dt_rem,\"title\":\"t\"}"
  case "$_dt_err" in
    *"It stood although this row covers only the governed checkout"*) ;;
    *) [ "$_dt_got" != refused ] || _dt_got="refused without the line saying the row stood although it covers only the governed checkout" ;;
  esac
  _dt_is "$_dt_n" refused
fi
_dt_case3 "deny floor A28 (B9): a Bash command acting only in the scratch clone is passed over, as it always was" allowed \
  "$_dt_cl" Bash "$_dt_rem}"

# ---- back on T1: the record, fail-open, and the README
printf '\ndeny floor: a refusal is recorded, and fail-open stays fail-open (B10, B11)\n'
_dt_n="deny floor A29 (B10): a Monitor refusal appends one denied line holding its command to the project's says.log"
if [ -n "$_dt_nofx" ]; then skip "$_dt_n" "$_dt_nofx"
else is "$_dt_n" "$((_dt_s1 - _dt_s0)) more denied line(s) holding pkill -f x" "1 more denied line(s) holding pkill -f x"; fi
_dt_n="deny floor A30 (B11): a payload that does not parse, an ungoverned repository, and a project with no deny.tsv all allow"
if [ -n "$_dt_nofx" ]; then skip "$_dt_n" "$_dt_nofx"
else
  _dt_t0="$TMP/plain1930"; mkdir -p "$_dt_t0"
  ( _fx_cd "$_dt_t0" && git init -q -b main ) >/dev/null 2>&1
  _dt_t1tab
  _dt_v "$_dt_t1" 'not json at all' ""; _dt_x="not JSON: $_dt_got"
  if [ -d "$_dt_t0/.git" ]; then _dt_v "$_dt_t0" "$(_dt_mon 'pkill -f x')" ""; _dt_x="$_dt_x; ungoverned: $_dt_got"
  else _dt_x="$_dt_x; ungoverned: no repository could be made"; fi
  rm -f "$FROOT/projects/widget/deny.tsv"
  _dt_v "$_dt_t1" "$(_dt_mon 'pkill -f x')" ""; _dt_x="$_dt_x; no deny.tsv: $_dt_got"
  is "$_dt_n" "$_dt_x" "not JSON: allowed; ungoverned: allowed; no deny.tsv: allowed"
fi

_dt_rm="$_dt_root/README.md"
_dt_n="deny floor A31 (B12): README's deny-table row names Monitor and no longer lists only the six tools"
if [ -f "$_dt_rm" ]; then
  _dt_rl="$(LC_ALL=C awk 'index($0, "| **The deny table** |") == 1 && !f { print; f = 1 }' "$_dt_rm" 2>/dev/null)"
  if [ -z "$_dt_rl" ]; then _dt_x="no line of README.md begins | **The deny table** |"
  else
    case "$_dt_rl" in
      *"Before a Bash, Edit, Write, Read, NotebookEdit or WebFetch call runs"*) _dt_x="it still begins with the six tools" ;;
      *Monitor*) _dt_x="names Monitor" ;;
      *) _dt_x="does not name Monitor" ;;
    esac
  fi
  is "$_dt_n" "$_dt_x" "names Monitor"
else skip "$_dt_n" "no README.md beside this harness"; fi

rm -f "$FROOT/projects/widget/deny.tsv" "$FROOT/.deny-err"
