printf '\nevery command-carrying tool is judged with the Bash rows (audit b16, round 3, blind)\n'
# Written blind on 2026-10-28 from the round-3 contract, b16-round-3.md (section 5: A9 and A59 restated,
# A63 to A86), with docs/2026-10-24-audit-fixes/b16-deny-floor-judges-effects-on-every-tool.md for the
# fixtures it names. No engine code was read: the hook is driven as a black box by _pre
# (tests/lib/deny-hook.sh), and A84, A85 and A59 read engine files only as those assertions say to. The
# round's contract puts these assertions in part 1930; here they are a part of their own, and 1930's own
# A9 and A59, which the round restates the other way, are left as they are. The part runs alone: each
# fixture is its own, under $TMP, and it relies on the prelude only (FROOT, TMP, MEM, REAL_HARNESS, _pre,
# _fx_cd, ok, bad, is, skip).
#
# "Refused" is exit 2 with the row's whole reason on stderr; "allowed" is exit 0 with nothing on stderr;
# any other exit is named in the failure. "Adds" counts the lines of $MEM/widget/says.log after the one
# call against before it. A fixture that cannot be built makes its assertions skips with the same names.
#
# Readings, where the contract leaves room:
# - The B16R3-2 line is matched whole where an assertion names the line (A63, A66), and as far as the
#   assertion quotes it elsewhere (A9, A71, A83).
# - "Holding" a text is anywhere in the says.log line; its fields are tab-separated.
# - A75's table is two rows: the one naming mcp__fixture__assess, and T1's Bash pattern-kill row.
# - A76 and A77 are one assertion each, and the failure names the payloads or cases that went wrong.
#   A77's "no line" is counted over every says.log under $MEM, since an ungoverned call has no project.
# - A78's tab and line break stand alone between the key and its colon, with no blank after the colon.
# - A81 holds the padded call and its unpadded twin each to the contract's verdict and kinds of line, so
#   that "the same as without it" cannot pass with both wrong alike.
# - A82 reads the second line bash's `times` prints (the children's user and system time), with LC_ALL=C
#   set just before it, and a decimal comma read as a point.
# - A84's files are those git lists under engine/harness (tracked, and untracked not ignored), or every
#   file outside dot-directories when git lists none.
# - A83 needs the scratch clone under the suite's TMPDIR, as 1930's T3 does; it is a skip when it is not.

# ---- helpers
_d3_tb="$(printf '\t')"; _d3_lf=$'\n'
_d3_esc() { printf '%s' "$1" | LC_ALL=C sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }
_d3_pay() { printf '{"session_id":"s1930r3","tool_name":"%s","tool_input":%s}' "$1" "$2"; }   # TOOL INPUT-JSON
_d3_cpay() { _d3_pay "$1" "{\"command\":\"$(_d3_esc "$2")\"${3:-}}"; }   # TOOL COMMAND [,MORE-KEYS]
_d3_cwdpay() {   # CWD TOOL INPUT-JSON
  printf '{"session_id":"s1930r3","cwd":"%s","tool_name":"%s","tool_input":%s}' "$(_d3_esc "$1")" "$2" "$3"
}
_d3_line() { printf 'Felix does not know whether %s runs its command on this machine; until it does, the Bash rows judge that command as well.' "$1"; }
# DIR PAYLOAD REASON -> _d3_got: refused (exit 2, REASON on stderr), allowed (exit 0, stderr empty), or
# what happened instead; _d3_err: the stderr. _d3_path, when set, is the PATH the hook runs under.
_d3_path=""
_d3_v() {
  local rc
  _d3_new=""; rm -f "$FROOT/.deny-err"
  if [ -n "$_d3_path" ]; then ( cd "$1" && PATH="$_d3_path" && export PATH && _pre "$2" ) >/dev/null 2>&1
  else ( cd "$1" && _pre "$2" ) >/dev/null 2>&1; fi
  rc=$?
  _d3_err="$(cat "$FROOT/.deny-err" 2>/dev/null)"
  case "$rc" in
    2) case "$_d3_err" in *"$3"*) _d3_got=refused ;; *) _d3_got="exit 2 without [$3] on stderr" ;; esac ;;
    0) if [ -z "$_d3_err" ]; then _d3_got=allowed; else _d3_got="exit 0 with something on stderr"; fi ;;
    *) _d3_got="exit $rc, which is neither 0 nor 2" ;;
  esac
}
_d3_with() {   # TEXT: a refusal from the last _d3_v counts only when stderr also holds TEXT
  [ "$_d3_got" = refused ] || return 0
  case "$_d3_err" in *"$1"*) ;; *) _d3_got="refused without [$1] on stderr" ;; esac
}
_d3_says="$MEM/widget/says.log"
_d3_cnt() { if [ -f "$_d3_says" ]; then LC_ALL=C awk 'END { print NR }' "$_d3_says"; else echo 0; fi; }
_d3_all() {   # -> the lines of every says.log under $MEM
  local f k n=0
  for f in "$MEM"/*/says.log; do
    [ -f "$f" ] || continue
    k="$(LC_ALL=C awk 'END { print NR }' "$f")"; n=$((n + k))
  done
  echo "$n"
}
_d3_call() {   # DIR PAYLOAD REASON -> as _d3_v, and _d3_new, _d3_nn: the lines it added to widget's says.log
  local n0; n0="$(_d3_cnt)"
  _d3_v "$1" "$2" "$3"
  [ ! -f "$_d3_says" ] || _d3_new="$(LC_ALL=C awk -v n="$n0" 'NR > n' "$_d3_says")"
  _d3_nn="$(( $(_d3_cnt) - n0 ))"
}
_d3_want() {   # KIND SESSION|- TOOL|- TEXT [TEXT] -> how many added lines have those fields and hold the texts
  printf '%s\n' "$_d3_new" | _K="$1" _S="$2" _T="$3" _A="$4" _B="${5:-}" LC_ALL=C awk -F'\t' '
    $2 != ENVIRON["_K"] { next }
    ENVIRON["_S"] != "-" && $3 != ENVIRON["_S"] { next }
    ENVIRON["_T"] != "-" && $4 != ENVIRON["_T"] { next }
    index($0, ENVIRON["_A"]) && (ENVIRON["_B"] == "" || index($0, ENVIRON["_B"])) { n++ }
    END { print n + 0 }'
}
_d3_kinds() {   # -> field 2 of each added line, sorted, one blank between
  printf '%s\n' "$_d3_new" | LC_ALL=C awk -F'\t' 'NF > 1 { print $2 }' | LC_ALL=C sort \
    | LC_ALL=C awk '{ s = s (NR > 1 ? " " : "") $0 } END { print s }'
}
_d3_is() {   # NAME GOT WANT: is, and on a miss the stderr and the lines the last call added
  if [ "$2" = "$3" ]; then ok "$1"
  else bad "$1" "wanted [$3], got [$2]; stderr [$(printf '%s' "$_d3_err" | LC_ALL=C tr '\n' ' ' | cut -c 1-300)]; added [$(printf '%s' "$_d3_new" | LC_ALL=C tr '\t\n' '|;' | cut -c 1-300)]"; fi
}
_d3_nofx=""
_d3_case() {   # NAME WANT REASON PAYLOAD [TEXT]: one verdict on T1; TEXT, when given, must be on stderr too
  if [ -n "$_d3_nofx" ]; then skip "$1" "$_d3_nofx"; return 0; fi
  _d3_v "$_d3_t1" "$4" "$3"
  [ -z "${5:-}" ] || _d3_with "$5"
  _d3_is "$1" "$_d3_got" "$2"
}
_d3_rep() {   # NAME PAYLOAD TOOL|- TEXT: allowed, and exactly one added line, unknown-shell, field 4 TOOL, holding TEXT
  if [ -n "$_d3_nofx" ]; then skip "$1" "$_d3_nofx"; return 0; fi
  _d3_call "$_d3_t1" "$2" ""
  _d3_is "$1" "$_d3_got; $_d3_nn line(s), $(_d3_want unknown-shell - "$3" "$4") as wanted" "allowed; 1 line(s), 1 as wanted"
}
_d3_pad="$(printf '%1100s' '' | LC_ALL=C tr ' ' a)"
_d3_pk="a pattern kill reaches other sessions"; _d3_fp="force push drops commits"
_d3_xt=mcp__plugin_x__terminal_execute

# ---- fixture T1: a checkout bound to widget by marker, and the four rows of the batch contract's table
_d3_t1="$TMP/deny1931-t1"; mkdir -p "$_d3_t1"
( _fx_cd "$_d3_t1" && git init -q -b main ) >/dev/null 2>&1
_d3_t1="$(cd "$_d3_t1" && pwd -P)"
printf 'widget\n' > "$_d3_t1/.felix"
_d3_t1tab() {
  mkdir -p "$FROOT/projects/widget"
  { printf 'Bash\tgit push --force\tforce push drops commits\n'
    printf 'Bash\tpkill -f\ta pattern kill reaches other sessions\n'
    printf 'Monitor\tsleep 600\ta monitor must not sleep this long\n'
    printf 'Read\t\\.env$\treading a secret\n'
  } > "$FROOT/projects/widget/deny.tsv"
}
_d3_t1tab
{ [ -d "$_d3_t1/.git" ] && [ -f "$_d3_t1/.felix" ] && [ -s "$FROOT/projects/widget/deny.tsv" ]; } \
  || _d3_nofx="fixture T1 could not be built (a repository at $_d3_t1, its marker, the widget deny.tsv)"

printf '\nround 3: an MCP tool on neither list that carries a command is judged by the Bash rows (R3-1, R3-2, R3-5, R3-6)\n'
_d3_case "B16R3 A9 (R3-1, restated): an mcp__ tool on neither list whose input carries a command is judged by the Bash rows, and the refusal says why" \
  refused "$_d3_pk" "$(_d3_cpay mcp__fixture__shell 'pkill -f x')" \
  "Felix does not know whether mcp__fixture__shell runs its command on this machine"
_d3_n="B16R3 A63 (R3-1, R3-2): a plugin-prefixed terminal_execute running a pattern kill is refused with the Bash row's reason and the line naming that tool"
_d3_n2="B16R3 A71 (R3-3): that refusal adds two says.log lines, one denied holding the added line, one unknown-shell with its session, tool and command"
if [ -n "$_d3_nofx" ]; then skip "$_d3_n" "$_d3_nofx"; skip "$_d3_n2" "$_d3_nofx"
else
  _d3_call "$_d3_t1" "$(_d3_cpay "$_d3_xt" 'pkill -f x')" "$_d3_pk"
  _d3_with "$(_d3_line "$_d3_xt")"
  _d3_is "$_d3_n" "$_d3_got" refused
  _d3_d="$(_d3_want denied - - 'pkill -f x' "does not know whether $_d3_xt")"
  _d3_u="$(_d3_want unknown-shell s1930r3 "$_d3_xt" 'pkill -f x')"
  _d3_is "$_d3_n2" "$_d3_nn line(s): $_d3_d denied and $_d3_u unknown-shell as wanted" \
    "2 line(s): 1 denied and 1 unknown-shell as wanted"
fi
_d3_case "B16R3 A64 (R3-1): desktop-commander's start_process running a force push is refused" \
  refused "$_d3_fp" "$(_d3_cpay mcp__desktop-commander__start_process 'git push --force origin feat/x' ',"timeout_ms":1000')"
_d3_case "B16R3 A65 (R3-1, B5): an unknown MCP shell handing a pattern kill to bash -c is refused" \
  refused "$_d3_pk" "$(_d3_cpay mcp__shell__execute_command "bash -c 'pkill -f x'")"
_d3_case "B16R3 A66 (R3-6): a plugin-prefixed spelling of run_in_terminal is not a named terminal: refused, and the line names that spelling" \
  refused "$_d3_pk" "$(_d3_cpay mcp__plugin_terminal_terminal__run_in_terminal 'pkill -f x' ',"title":"t"')" \
  "$(_d3_line mcp__plugin_terminal_terminal__run_in_terminal)"
_d3_case "B16R3 A67 (R3-5): a plugin-prefixed spelling of claude-flow's hooks_pre-command is not exempt: its force push is refused" \
  refused "$_d3_fp" "$(_d3_cpay mcp__plugin_claude-flow_claude-flow__hooks_pre-command 'git push --force origin feat/x')"
_d3_case "B16R3 A67 (R3-5): another server's run_session_command is not exempt: its nested pattern kill is refused" \
  refused "$_d3_pk" "$(_d3_pay mcp__vercel__run_session_command '{"sessionId":"s","requestBody":{"command":"pkill -f x","args":[]}}')"
_d3_case "B16R3 A68 (R3-1, B5) [control]: an unknown MCP shell that only echoes a quoted pattern kill is allowed" \
  allowed "" "$(_d3_cpay "$_d3_xt" "echo 'pkill -f x'")"
_d3_case "B16R3 A69 (R3-8): an unknown MCP shell's command over 1,024 characters is read whole, and its pattern kill refused" \
  refused "$_d3_pk" "$(_d3_cpay "$_d3_xt" "echo $_d3_pad ; pkill -f x")"
_d3_case "B16R3 A70 (R3-8): an unknown MCP shell's command after a field of 1,100 characters is refused" \
  refused "$_d3_pk" "$(_d3_pay "$_d3_xt" "{\"note\":\"$_d3_pad\",\"command\":\"pkill -f x\"}")"

printf '\nround 3: every unknown or unread call is reported, and an unread one has no subject (R3-3, R3-4)\n'
_d3_rep "B16R3 A72 (R3-3): an unknown MCP shell's allowed command exits 0 silently and adds one unknown-shell line holding the command" \
  "$(_d3_cpay "$_d3_xt" 'ls -la')" "$_d3_xt" 'ls -la'
_d3_rep "B16R3 A73 (R3-4): a command given as an array is allowed, unread, and reported once as not a string" \
  "$(_d3_pay mcp__fixture__exec '{"command":["pkill","-f","x"]}')" mcp__fixture__exec 'not a string'
_d3_rep "B16R3 A74 (R3-4): a null command is allowed and reported once as not a string" \
  "$(_d3_pay mcp__fixture__exec '{"command":null}')" mcp__fixture__exec 'not a string'
_d3_rep "B16R3 A74 (R3-4): a number for a command is allowed and reported once as not a string" \
  "$(_d3_pay mcp__fixture__exec '{"command":42}')" mcp__fixture__exec 'not a string'
_d3_rep "B16R3 A74 (R3-4): an object for a command is allowed and reported once as not a string, though it holds a pattern kill" \
  "$(_d3_pay mcp__fixture__exec '{"command":{"argv":"pkill -f x"}}')" mcp__fixture__exec 'not a string'
_d3_n="B16R3 A75 (R3-4, B6): a row naming the tool no longer reads the string after an array command: allowed, and reported once"
if [ -n "$_d3_nofx" ]; then skip "$_d3_n" "$_d3_nofx"
else
  { printf 'mcp__fixture__assess\tpkill\tthis tool is named by the row\n'
    printf 'Bash\tpkill -f\ta pattern kill reaches other sessions\n'; } > "$FROOT/projects/widget/deny.tsv"
  _d3_rep "$_d3_n" "$(_d3_pay mcp__fixture__assess '{"command":["pkill","-f","x"]}')" - 'not a string'
  _d3_t1tab
fi
_d3_n="B16R3 A86 (R3-2) [control]: a refusal by a row naming the tool, with no Bash row, does not gain the added line"
if [ -n "$_d3_nofx" ]; then skip "$_d3_n" "$_d3_nofx"
else
  printf 'mcp__fixture__assess\tpkill -f\tthis tool is named by the row\n' > "$FROOT/projects/widget/deny.tsv"
  _d3_v "$_d3_t1" "$(_d3_cpay mcp__fixture__assess 'pkill -f x')" "this tool is named by the row"
  case "$_d3_err" in *"does not know whether"*) [ "$_d3_got" != refused ] || _d3_got="refused, with the added line" ;; esac
  _d3_is "$_d3_n" "$_d3_got" refused
  _d3_t1tab
fi

_d3_n="B16R3 A76 (R3-3, R3-6) [control]: named terminals, the three exempt tools, first-party tools and calls with no command key add no unknown-shell line"
_d3_kind() {   # KIND -> the lines of widget's says.log whose field 2 is KIND
  if [ -f "$_d3_says" ]; then _K="$1" LC_ALL=C awk -F'\t' '$2 == ENVIRON["_K"] { n++ } END { print n + 0 }' "$_d3_says"
  else echo 0; fi
}
if [ -n "$_d3_nofx" ]; then skip "$_d3_n" "$_d3_nofx"
else
  _d3_off=""
  while IFS="$_d3_tb" read -r _d3_tool _d3_in <&3; do
    [ -n "$_d3_tool" ] || continue
    _d3_k0="$(_d3_kind unknown-shell)"
    _d3_v "$_d3_t1" "$(_d3_pay "$_d3_tool" "$_d3_in")" "" </dev/null
    [ "$(_d3_kind unknown-shell)" = "$_d3_k0" ] || _d3_off="$_d3_off $_d3_tool $_d3_in;"
  done 3<<'J'
Bash	{"command":"ls"}
Monitor	{"command":"ls","description":"d","timeout_ms":1000}
mcp__terminal__run_in_terminal	{"command":"ls","title":"t"}
mcp__claude-flow__terminal_execute	{"command":"ls","sessionId":"s1"}
mcp__claude-flow__hooks_pre-command	{"command":"git push --force origin feat/x"}
mcp__claude-flow__hooks_post-command	{"command":"pkill -f vitest","exitCode":0}
mcp__plugin_vercel_vercel__run_session_command	{"sessionId":"sbx_1","requestBody":{"command":"pkill -f vitest","args":[]}}
StructuredOutput	{"command":"pkill -f x"}
Fixturetool	{"command":"pkill -f x"}
mcp__fixture__memory	{"key":"k","value":"{\"command\": \"pkill -f x\"}"}
mcp__fixture__navigate	{"url":"https://example.com"}
J
  _d3_new=""; _d3_err=""
  _d3_is "$_d3_n" "$_d3_off" ""
fi
_d3_n="B16R3 A77 (R3-3) [control]: no report without a Bash row, without a deny.tsv, or outside a governed repository"
if [ -n "$_d3_nofx" ]; then skip "$_d3_n" "$_d3_nofx"
else
  _d3_q="$(_d3_cpay "$_d3_xt" 'pkill -f x')"
  printf 'Read\t\\.env$\treading a secret\n' > "$FROOT/projects/widget/deny.tsv"
  _d3_a0="$(_d3_all)"; _d3_v "$_d3_t1" "$_d3_q" ""
  _d3_x="only a Read row: $_d3_got, $(( $(_d3_all) - _d3_a0 )) line(s)"
  rm -f "$FROOT/projects/widget/deny.tsv"
  _d3_a0="$(_d3_all)"; _d3_v "$_d3_t1" "$_d3_q" ""
  _d3_x="$_d3_x; no deny.tsv: $_d3_got, $(( $(_d3_all) - _d3_a0 )) line(s)"
  _d3_t1tab
  _d3_t0="$TMP/plain1931"; mkdir -p "$_d3_t0"
  ( _fx_cd "$_d3_t0" && git init -q -b main ) >/dev/null 2>&1
  if [ -d "$_d3_t0/.git" ]; then
    _d3_a0="$(_d3_all)"; _d3_v "$_d3_t0" "$_d3_q" ""
    _d3_x="$_d3_x; ungoverned: $_d3_got, $(( $(_d3_all) - _d3_a0 )) line(s)"
  else _d3_x="$_d3_x; ungoverned: no repository could be made"; fi
  is "$_d3_n" "$_d3_x" "only a Read row: allowed, 0 line(s); no deny.tsv: allowed, 0 line(s); ungoverned: allowed, 0 line(s)"
fi

printf '\nround 3: the field is read as a key, for every tool (R3-7)\n'
_d3_case "B16R3 A78 (R3-7): Bash with two blanks either side of the colon is read and refused" \
  refused "$_d3_pk" "$(_d3_pay Bash '{"command"  :  "pkill -f x"}')"
_d3_case "B16R3 A78 (R3-7): Bash with a tab between the command key and its colon is read and refused" \
  refused "$_d3_pk" "$(_d3_pay Bash "{\"command\"$_d3_tb:\"pkill -f x\"}")"
_d3_case "B16R3 A78 (R3-7): an unknown MCP shell with a line break between the command key and its colon is read and refused" \
  refused "$_d3_pk" "$(_d3_pay "$_d3_xt" "{\"command\"$_d3_lf:\"pkill -f x\"}")"
_d3_case "B16R3 A79 (R3-7): run_in_terminal with an earlier value spelling command reads the key, and is refused" \
  refused "$_d3_pk" "$(_d3_pay mcp__terminal__run_in_terminal '{"type":"command","command":"pkill -f x"}')"
_d3_case "B16R3 A79 (R3-7): an unknown MCP shell with an earlier value spelling command reads the key, and is refused" \
  refused "$_d3_pk" "$(_d3_pay "$_d3_xt" '{"type":"command","command":"pkill -f x"}')"
_d3_case "B16R3 A79 (R3-7): a Read with an earlier value spelling file_path reads the key, and is refused" \
  refused "reading a secret" "$(_d3_pay Read '{"mode":"file_path","file_path":"/w/.env"}')"

# ---- fixture T2 (B8): a project resolved by remote_match, and a git shim that logs every call
_d3_gp="$FROOT/projects/gizmo1931"; mkdir -p "$_d3_gp"
printf '{"name":"gizmo1931","remote_match":"example.com/gizmo1931"}\n' > "$_d3_gp/project.json"
printf 'Bash\tpkill -f\tno pattern kills\n' > "$_d3_gp/deny.tsv"
_d3_t2="$TMP/gizmo1931-repo"; mkdir -p "$_d3_t2"
( _fx_cd "$_d3_t2" && git init -q -b main && git remote add origin https://example.com/gizmo1931.git ) >/dev/null 2>&1
_d3_t2="$(cd "$_d3_t2" && pwd -P)"
_d3_git="$(type -P git 2>/dev/null)"
_d3_shim="$TMP/shim1931"; _d3_glog="$TMP/shim1931.log"; mkdir -p "$_d3_shim"
if [ -n "$_d3_git" ]; then
  { printf '#!/bin/sh\n'
    printf 'printf %s "$*" >> %s\n' "'%s\\n'" "'$_d3_glog'"
    printf 'exec %s "$@"\n' "'$_d3_git'"; } > "$_d3_shim/git"
  chmod 755 "$_d3_shim/git"
fi
_d3_nofx2=""
{ [ -n "$_d3_git" ] && [ -x "$_d3_shim/git" ] && [ ! -e "$_d3_t2/.felix" ] \
  && [ "$(git -C "$_d3_t2" config --get remote.origin.url 2>/dev/null)" = "https://example.com/gizmo1931.git" ]; } \
  || _d3_nofx2="fixture T2 could not be built (the git shim, or the repository with its origin and no marker)"
_d3_gcall() {   # PAYLOAD REASON -> _d3_got, _d3_err, and _d3_gn: the git calls the shim logged
  : > "$_d3_glog"
  _d3_path="$_d3_shim:$PATH"; _d3_v "$_d3_t2" "$1" "$2"; _d3_path=""
  _d3_gn="$(LC_ALL=C awk 'END { print NR }' "$_d3_glog" 2>/dev/null)"
}
_d3_n="B16R3 A80 (R3-7) [control]: an mcp__ call whose only command is a value exits 0 before the project is resolved, running no git"
if [ -n "$_d3_nofx2" ]; then skip "$_d3_n" "$_d3_nofx2"
else
  _d3_gcall '{"tool_name":"Read","tool_input":{"file_path":"x"}}' ""
  if [ "$_d3_got" != allowed ]; then _d3_x="the Read probe was not allowed: $_d3_got"
  elif [ "${_d3_gn:-0}" -lt 1 ] 2>/dev/null; then _d3_x="unknown: the Read probe left the git log empty, so the shim is not shown to be on the hook's path"
  else
    _d3_gcall '{"tool_name":"mcp__fixture__memory","tool_input":{"kind":"command","note":"x"}}' ""
    if [ "$_d3_got" != allowed ]; then _d3_x="$_d3_got"
    elif [ "${_d3_gn:-x}" != 0 ]; then _d3_x="the hook ran git ${_d3_gn:-?} time(s): $(LC_ALL=C head -3 "$_d3_glog" 2>/dev/null | LC_ALL=C tr '\n' ';')"
    else _d3_x="exit 0, nothing on stderr, no git"; fi
  fi
  is "$_d3_n" "$_d3_x" "exit 0, nothing on stderr, no git"
fi
[ -z "$FROOT" ] || rm -rf "$FROOT/projects/gizmo1931"

printf '\nround 3: size changes nothing, and costs nothing new (R3-8)\n'
_d3_same() {   # NAME TOOL INPUT-KEYS REASON WANT: WANT is "<verdict>; <kinds>", with a pad first and without
  local p q
  if [ -n "$_d3_nofx" ]; then skip "$1" "$_d3_nofx"; return 0; fi
  _d3_call "$_d3_t1" "$(_d3_pay "$2" "{$3}")" "$4"; q="$_d3_got; $(_d3_kinds)"
  _d3_call "$_d3_t1" "$(_d3_pay "$2" "{\"pad\":\"$_d3_pad\",$3}")" "$4"; p="$_d3_got; $(_d3_kinds)"
  _d3_is "$1" "padded: $p / without: $q" "padded: $5 / without: $5"
}
_d3_same "B16R3 A81 (R3-8): A63's call with a 1,100-character pad first gets the same verdict and lines" \
  "$_d3_xt" '"command":"pkill -f x"' "$_d3_pk" "refused; denied unknown-shell"
_d3_same "B16R3 A81 (R3-8): A73's call with a 1,100-character pad first gets the same verdict and line" \
  mcp__fixture__exec '"command":["pkill","-f","x"]' "" "allowed; unknown-shell"
_d3_same "B16R3 A81 (R3-8): A79's run_in_terminal call with a 1,100-character pad first gets the same verdict and line" \
  mcp__terminal__run_in_terminal '"type":"command","command":"pkill -f x"' "$_d3_pk" "refused; denied"

_d3_n="B16R3 A82 (R3-8): a pattern kill after a 300,000-character field is refused, in under 20 s of CPU"
if [ -n "$_d3_nofx" ]; then skip "$_d3_n" "$_d3_nofx"
else
  _d3_big="$(printf '%300000s' '' | LC_ALL=C tr ' ' a)"
  _d3_bp="$(_d3_pay "$_d3_xt" "{\"note\":\"$_d3_big\",\"command\":\"pkill -f x\"}")"
  rm -f "$FROOT/.deny-err"
  _d3_tm="$( ( cd "$_d3_t1" || exit 97; _pre "$_d3_bp" >/dev/null 2>&1; printf 'rc %s\n' "$?"; LC_ALL=C; times ) 2>/dev/null )"
  _d3_cpu="$(printf '%s\n' "$_d3_tm" | LC_ALL=C awk '
    function sec(s,  m) { sub(/,/, ".", s); if (s !~ /^[0123456789]+m[0123456789]+([.][0123456789]+)?s$/) return -1
      m = index(s, "m"); return substr(s, 1, m - 1) * 60 + substr(s, m + 1, length(s) - m - 1) }
    /^rc / { next }
    NF == 2 { t++; if (t == 2) { u = sec($1); y = sec($2); if (u >= 0 && y >= 0) { printf "%.2f\n", u + y; f = 1 } } }
    END { if (!f) print "x" }')"
  _d3_brc="$(printf '%s\n' "$_d3_tm" | LC_ALL=C awk '/^rc / { print $2; exit }')"
  if [ "$_d3_cpu" = x ]; then skip "$_d3_n" "times printed nothing parseable: [$(printf '%s' "$_d3_tm" | LC_ALL=C tr '\n' ';')]"
  else
    _d3_err="$(cat "$FROOT/.deny-err" 2>/dev/null)"; _d3_new=""
    case "$_d3_brc" in
      2) case "$_d3_err" in *"$_d3_pk"*) _d3_x=refused ;; *) _d3_x="exit 2 without the reason" ;; esac ;;
      0) _d3_x="exit 0" ;;
      *) _d3_x="exit $_d3_brc" ;;
    esac
    _d3_x="$_d3_x, $(LC_ALL=C awk -v c="$_d3_cpu" 'BEGIN { if (c + 0 < 20) print "under 20 s"; else print c " s" }') of CPU"
    _d3_is "$_d3_n" "$_d3_x" "refused, under 20 s of CPU"
  fi
  _d3_big=""; _d3_bp=""
fi

# ---- fixture T3 (B9): a governed checkout and a scratch clone, as 0620 and 1930 build them
printf '\nround 3: a checkout-scoped row stands for an unknown call (R3-9)\n'
_d3_sc="$TMP/scoped1931"; _d3_gov="$_d3_sc/gov"; _d3_scr="$_d3_sc/scr"
mkdir -p "$_d3_gov" "$_d3_scr"
( _fx_cd "$_d3_gov" && git init -q -b main && printf 'widget\n' > .felix && printf 'readme\n' > README \
  && git add .felix README && git -c user.name=t -c user.email=t@t commit -qm init \
  && git remote add origin https://example.com/widget.git ) >/dev/null 2>&1
( _fx_cd "$_d3_scr" && git clone -q "$_d3_gov" clone ) >/dev/null 2>&1
_d3_gov="$(cd "$_d3_gov" && pwd -P)"; _d3_scr="$(cd "$_d3_scr" && pwd -P)"; _d3_cl="$_d3_scr/clone"
_d3_tr="$(cd -P "${TMPDIR:-/tmp}" 2>/dev/null && pwd -P)"
_d3_nofx3="fixture T3 could not be built under the suite's TMPDIR (checkout [$_d3_gov], clone [$_d3_cl], TMPDIR [${TMPDIR:-}])"
if [ -d "$_d3_gov/.git" ] && [ -f "$_d3_gov/.felix" ] && [ -d "$_d3_cl/.git" ] && [ -n "$_d3_tr" ] \
   && case "$_d3_cl/" in "${_d3_tr%/}/"*) true ;; *) false ;; esac; then _d3_nofx3=""; fi
_d3_n="B16R3 A83 (R3-9): a checkout-scoped row stands for an unknown MCP shell in a scratch clone, and says both why"
if [ -n "$_d3_nofx3" ]; then skip "$_d3_n" "$_d3_nofx3"
else
  printf 'Bash\tgit( +-[^ ]+( +[^ ]+)?)* +remote +(add|set-url|rename|remove|rm)( |$)\tthe remote is where the person is\tcheckout\n' \
    > "$FROOT/projects/widget/deny.tsv"
  _d3_v "$_d3_gov" "$(_d3_cwdpay "$_d3_cl" "$_d3_xt" '{"command":"git remote add up https://example.com/up.git"}')" \
    "the remote is where the person is"
  _d3_with "It stood although this row covers only the governed checkout"
  _d3_with "does not know whether $_d3_xt"
  _d3_is "$_d3_n" "$_d3_got" refused
  _d3_t1tab
fi

# ---- the engine's text: one predicate, the sizes, and the README
printf '\nround 3: one predicate, the sizes, and the README (R3-10 to R3-12)\n'
_d3_n="B16R3 A84 (R3-10) [control]: pre-tool names no mcp__ tool outside comments, and the five MCP names live in lib/deny.sh alone"
_d3_x=""
if [ -f "$REAL_HARNESS/hooks/pre-tool" ]; then
  _d3_k="$(LC_ALL=C awk '/^[[:space:]]*#/ { next } index($0, "mcp__") { n++ } END { print n + 0 }' "$REAL_HARNESS/hooks/pre-tool")"
  [ "$_d3_k" = 0 ] || _d3_x="$_d3_x hooks/pre-tool holds mcp__ on $_d3_k line(s) that are not comments;"
else _d3_x="$_d3_x there is no hooks/pre-tool;"; fi
_d3_fl="$TMP/files1931"
git -C "$REAL_HARNESS" ls-files -co --exclude-standard . > "$_d3_fl" 2>/dev/null
[ -s "$_d3_fl" ] || ( cd "$REAL_HARNESS" && find . -name '.?*' -prune -o -type f -print ) 2>/dev/null \
  | LC_ALL=C sed 's|^\./||' > "$_d3_fl"
_d3_names="mcp__terminal__run_in_terminal mcp__claude-flow__terminal_execute mcp__claude-flow__hooks_pre-command mcp__claude-flow__hooks_post-command mcp__plugin_vercel_vercel__run_session_command"
_d3_hits="$( cd "$REAL_HARNESS" && LC_ALL=C awk '!/^tests\//' "$_d3_fl" \
  | while IFS= read -r _d3_f; do [ -f "$_d3_f" ] && printf '%s\0' "$_d3_f"; done \
  | xargs -0 env LC_ALL=C awk -v names="$_d3_names" '
      BEGIN { k = split(names, N, " ") }
      { for (i = 1; i <= k; i++) if (index($0, N[i])) hit[i SUBSEP FILENAME] = 1 }
      END { for (h in hit) { split(h, p, SUBSEP); print N[p[1]] "\t" p[2] } }' 2>/dev/null )"
for _d3_nm in $_d3_names; do
  _d3_fs="$(printf '%s\n' "$_d3_hits" | _N="$_d3_nm" LC_ALL=C awk -F'\t' '$1 == ENVIRON["_N"] { print $2 }' \
    | LC_ALL=C sort -u | LC_ALL=C awk '{ s = s (NR > 1 ? " " : "") $0 } END { print s }')"
  [ "$_d3_fs" = lib/deny.sh ] || _d3_x="$_d3_x $_d3_nm is in [$_d3_fs];"
done
_d3_new=""; _d3_err=""
_d3_is "$_d3_n" "$_d3_x" ""

_d3_n="B16R3 A85 (R3-12) [control]: lib/deny.sh, hooks/pre-tool and part 1930 have 500 lines or fewer"
_d3_x=""
for _d3_f in lib/deny.sh hooks/pre-tool tests/parts/1930-deny-every-tool-blind.sh; do
  if [ -f "$REAL_HARNESS/$_d3_f" ]; then
    _d3_k="$(LC_ALL=C awk 'END { print NR }' "$REAL_HARNESS/$_d3_f")"
    [ "$_d3_k" -le 500 ] 2>/dev/null || _d3_x="$_d3_x $_d3_f has $_d3_k lines;"
  else _d3_x="$_d3_x there is no $_d3_f;"; fi
done
is "$_d3_n" "$_d3_x" ""

_d3_rm="$(cd "$REAL_HARNESS/../.." && pwd)/README.md"
_d3_n="B16R3 A59 (R3-11, restated): README's deny-table row says any MCP tool whose input carries a command is read"
if [ -f "$_d3_rm" ]; then
  _d3_rl="$(LC_ALL=C awk 'index($0, "| **The deny table** |") == 1 && !f { print; f = 1 }' "$_d3_rm" 2>/dev/null)"
  if [ -z "$_d3_rl" ]; then _d3_x="no line of README.md begins | **The deny table** |"
  else
    _d3_x=""
    case "$_d3_rl" in *"any MCP tool whose input carries a command"*) ;; *) _d3_x="$_d3_x it does not say any MCP tool whose input carries a command;" ;; esac
    case "$_d3_rl" in *"an MCP terminal tool Felix names"*) _d3_x="$_d3_x it still says an MCP terminal tool Felix names;" ;; esac
  fi
  is "$_d3_n" "$_d3_x" ""
else skip "$_d3_n" "no README.md beside this harness"; fi

rm -f "$FROOT/projects/widget/deny.tsv" "$FROOT/.deny-err" "$_d3_fl"
