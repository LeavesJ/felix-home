printf '\nthe cloud check fails closed on escapes and repeated keys (audit b08 round 3, blind)\n'
# Written blind on 2026-10-28 from the round-3 contract alone (docs/2026-10-24-
# audit-fixes/b08-round-3.md, A69 to A84 of its section 4), before the fix, without
# reading projects/felix/gate.sh, engine/hooks/ or anything the gate sources. One
# assertion per item, named "B08R3 A<n> (R3-<m>...): ..."; an item that checks
# several things is one assertion whose verdict says each of them.
#
# The fixture is FC, built as part 1770 builds it: a checkout holding this tree's
# projects/felix/gate.sh beside the stubs (schema-check, independence-scan,
# lib/detect.sh, an ecosystem.tsv header and a tests/run that prints a summary),
# and copies of this tree's engine/hooks/hooks.json and .claude/settings.json. Each
# case starts from the tree's two files, edits one or both with one awk program,
# commits, and runs `bash projects/felix/gate.sh --quick` there, bounded at 60 s,
# with HOME and TMPDIR under $TMP, FELIX_KERNEL_CACHE naming a missing directory,
# and stubs for jq, python3 and node first on PATH (A84) that record every call
# and exit 1.
#
# Readings taken where the text leaves room:
# - The contract's Decision 9 puts this block in part 1770. It is a part of its
#   own here, as the workflow that wrote it asked, so it builds FC itself and runs
#   alone; part 1040 allows the driver its 500th line.
# - cloud FAIL is the three things the contract names together: the line
#   `  cloud              FAIL` once, the output's last line `gate: FAIL (cloud)`,
#   and exit status 1. The detail is the line under the cloud line.
# - <path> is `engine/hooks/hooks.json` for the plugin's file, as A28 names it,
#   and `.claude/settings.json` for the settings, as Decision 6 prints it.
# - Before the rule is read, each case checks with grep -cxF that each edited
#   file holds the line the case names exactly once; when one does not, the
#   assertion fails saying "fixture:" and why, never as the rule. A80's plugin
#   line is not named; it is settings' PreToolUse matcher line widened by A25's
#   own program, because A23 reads the two matchers as equal and B27 compares
#   them exactly.
# - A79 is read on its detail alone, as written: both clauses present, the
#   hooks.json one first.
# - Every text the edits and the checks match comes in through ENVIRON or a file,
#   never an awk string constant or a shell pattern, so a backslash is itself
#   under BWK awk and gawk alike (gawk 5.3 reads a backslash-u in a constant).
#   The u-escapes the cases name are built from _b83U, a backslash then a u, so
#   this file holds none as text.

_b83="$TMP/b08r3"; mkdir -p "$_b83/stub/bin" "$_b83/l" "$_b83/home" "$_b83/tmp"
_b83_bounded() {   # <seconds> <cmd>...: cmd in a process group of its own, the group killed at the limit (status 124)
  perl -e '$t = shift; $p = fork; defined $p or exit 125;
    if (!$p) { setpgrp(0, 0); exec @ARGV; exit 127 }
    $SIG{ALRM} = sub { kill "KILL", -$p; exit 124 }; alarm $t; waitpid $p, 0;
    exit(($? & 127) ? 128 + ($? & 127) : $? >> 8)' "$@"
}
_b83_flat() { printf '%s' "$1" | LC_ALL=C tr '\t\n' ' |' | cut -c1-900; }
# needle haystack: status 0 when the haystack holds the needle, byte for byte.
_b83_in() { B83_S="$2" B83_W="$1" LC_ALL=C awk 'BEGIN { if (index(ENVIRON["B83_S"], ENVIRON["B83_W"])) exit 0; exit 1 }'; }
# needle haystack: where the needle begins in the haystack, 0 when it is not there.
_b83_at() { B83_S="$2" B83_W="$1" LC_ALL=C awk 'BEGIN { print index(ENVIRON["B83_S"], ENVIRON["B83_W"]) }'; }

# The three stubs: every call one line in calls, and a failure. A probe first, so
# an empty calls file means no call and not a stub that records nothing.
for _b83t in jq python3 node; do
  printf '#!/bin/sh\nprintf "%%s %%s\\n" "%s" "$*" >> "%s/stub/calls"\nexit 1\n' "$_b83t" "$_b83" > "$_b83/stub/bin/$_b83t"
  chmod +x "$_b83/stub/bin/$_b83t"
done
_b83PATH="$_b83/stub/bin:$PATH"
for _b83t in jq python3 node; do PATH="$_b83PATH" "$_b83t" b08r3-probe >/dev/null 2>&1; done
_b83Probe="$(LC_ALL=C tr '\n' ' ' 2>/dev/null < "$_b83/stub/calls")"
: > "$_b83/stub/calls"

# The clauses (section 2's terms), the backslash in each escape clause as itself.
_b83PH='engine/hooks/hooks.json'; _b83PS='.claude/settings.json'
_b83EH="unreadable: $_b83PH"' (an escape other than \");'
_b83ES="unreadable: $_b83PS"' (an escape other than \");'
_b83RS="unreadable: $_b83PS (a key repeated in one object);"
_b83RTAIL='(a key repeated in one object)'
_b83FAIL="$(printf '  %-18s %s' cloud FAIL)"

# ---- FC
_b83G="$REAL_HARNESS/../../projects/felix/gate.sh"
_b83H="$REAL_HARNESS/../hooks/hooks.json"
_b83S="$REAL_HARNESS/../../.claude/settings.json"
_b83Why=""
[ -f "$_b83G" ] || _b83Why="no projects/felix/gate.sh beside this engine"
if [ -z "$_b83Why" ] && { [ ! -f "$_b83H" ] || [ ! -f "$_b83S" ]; }; then
  _b83Why="no engine/hooks/hooks.json and .claude/settings.json in this tree"
fi
_b83_git() { local d="$1"; shift; _fx_git "$d" -c user.name=b08 -c user.email=b08@example.invalid -c commit.gpgsign=false "$@"; }
_b83_mk() {   # dir: FC, this tree's gate and the two hook files beside the stubs, committed once
  local d="$1"
  mkdir -p "$d/engine/harness/bin" "$d/engine/harness/lib" "$d/engine/harness/tests" "$d/projects/felix" \
    "$d/engine/hooks" "$d/.claude" || return 1
  cp "$_b83G" "$d/projects/felix/gate.sh" || return 1
  printf '#!/bin/sh\nexit 0\n' > "$d/engine/harness/bin/schema-check"
  printf '#!/bin/sh\n[ "${1:-}" = --paths ] && echo engine/harness/bin\nexit 0\n' > "$d/engine/harness/bin/independence-scan"
  printf '_b8c_probe() {\n  _felix_dep_grep "$root" "b08zzword"\n}\n' > "$d/engine/harness/lib/detect.sh"
  printf '# kind\tfile\ttoken\treason\n' > "$d/engine/harness/ecosystem.tsv"
  printf '#!/bin/sh\nprintf "ran\\n" > "%s/suite.mark"\nprintf "\\n5 passed, 0 failed\\n"\nexit 0\n' "$_b83" > "$d/engine/harness/tests/run"
  chmod +x "$d/engine/harness/bin/schema-check" "$d/engine/harness/bin/independence-scan" "$d/engine/harness/tests/run"
  cp "$_b83H" "$d/engine/hooks/hooks.json" && cp "$_b83S" "$d/.claude/settings.json" || return 1
  ( _fx_cd "${d:?}" && git init -q -b main && git add -A \
      && git -c user.name=b08 -c user.email=b08@example.invalid -c commit.gpgsign=false commit -qm fixture ) >/dev/null 2>&1
}

# The edit, one awk program for every case but A80's: the lines of the file B83_I
# put before, after, or instead of the first line that B83_A names (=text: equal
# to it; ~text: holding it), counted from the line after one holding B83_C (from
# the top when B83_C is empty). Status 3 when no such line was met.
_b83ED='function put(  l) { while ((getline l < f) > 0) print l; close(f) }
  BEGIN { m = ENVIRON["B83_M"]; c = ENVIRON["B83_C"]; a = ENVIRON["B83_A"]; f = ENVIRON["B83_I"]
          k = substr(a, 1, 1); a = substr(a, 2); seen = (c == "") }
  { hit = 0 }
  !done && seen && ((k == "=" && $0 == a) || (k == "~" && index($0, a) > 0)) { hit = 1; done = 1 }
  !seen && index($0, c) > 0 { seen = 1 }
  hit && m != "after" { put() }
  !(hit && m == "instead") { print }
  hit && m == "after" { put() }
  END { if (!done) exit 3 }'
# A25's edit, as part 1770 writes it: the plugin's PreToolUse matcher widened by |Glob|Grep.
_b83WIDEN='index($0, "\"PreToolUse\"") { p = 1 } p && index($0, "\"matcher\"") { sub(/",[ ]*$/, "|Glob|Grep\","); p = 0 } { print }'
_b83_file() { if [ "$1" = hooks ]; then printf '%s' "$_b83CH"; else printf '%s' "$_b83CS"; fi; }
_b83_apply() {   # hooks|settings program [NAME=value...]: FC's copy of that file run through the program
  local w="$1" p="$2" f
  shift 2
  f="$(_b83_file "$w")"
  if env "$@" LC_ALL=C awk "$p" "$f" > "$_b83/ed.tmp" && ! cmp -s "$f" "$_b83/ed.tmp"; then
    cat "$_b83/ed.tmp" > "$f"
  else
    _b83Fx="$_b83Fx the edit of $w changed nothing;"
  fi
}
_b83_ed() { _b83_apply "$1" "$_b83ED" B83_M="$2" B83_C="$3" B83_A="$4" B83_I="$5"; }
_b83_has() {   # hooks|settings line: FC's copy holds the line exactly once (grep -cxF), else a fixture fault
  local f n
  f="$(_b83_file "$1")"
  n="$(LC_ALL=C grep -cxF -e "$2" "$f" 2>/dev/null)"
  if [ -z "$2" ] || [ "${n:-0}" != 1 ]; then _b83Fx="$_b83Fx $1 holds ${n:-0} lines [$2], not 1;"; fi
}
_b83_start() { cp "$_b83H" "$_b83CH"; cp "$_b83S" "$_b83CS"; _b83Fx="$_b83MkFx"; }
_b83_go() {   # name: FC committed, its gate run; the cloud verdict, the detail, the last line, the FAIL-line count
  _b83_git "$_b83C" commit -qam "$1" >/dev/null 2>&1
  ( cd "${_b83C:?}" && _b83_bounded 60 env PATH="$_b83PATH" HOME="$_b83/home" FELIX_KERNEL_CACHE="$_b83/nocache" \
      TMPDIR="$_b83/tmp" bash projects/felix/gate.sh --quick ) > "$_b83/$1.out" 2>&1
  _b83Rc=$?
  _b83All="$(cat "$_b83/$1.out" 2>/dev/null)"
  _b83V="$(LC_ALL=C awk 'index($0, "  cloud ") == 1 { print $2; exit }' "$_b83/$1.out" 2>/dev/null)"
  _b83D="$(LC_ALL=C awk 'f { print; exit } index($0, "  cloud ") == 1 { f = 1 }' "$_b83/$1.out" 2>/dev/null)"
  _b83L="$(LC_ALL=C awk '{ l = $0 } END { print l }' "$_b83/$1.out" 2>/dev/null)"
  _b83N="$(LC_ALL=C grep -cxF -e "$_b83FAIL" "$_b83/$1.out" 2>/dev/null)"
}
_b83_why() { printf '%s detail [%s]; output: %s' "$1" "$_b83D" "$(_b83_flat "$_b83All")"; }
_b83_fail() {   # name want... [-- unwanted...]: the fixture held, cloud FAIL, and the detail holds every want and no unwanted
  local n="$1" w miss="" no=0
  shift
  if [ -n "$_b83Fx" ]; then bad "$n" "fixture:$_b83Fx"; return 0; fi
  [ "${_b83N:-0}" = 1 ] || miss="$miss no line [$_b83FAIL] (cloud [${_b83V:-none}]);"
  [ "$_b83L" = "gate: FAIL (cloud)" ] || miss="$miss last line [$_b83L];"
  [ "$_b83Rc" = 1 ] || miss="$miss exit $_b83Rc;"
  for w in "$@"; do
    if [ "$w" = "--" ]; then no=1; continue; fi
    if _b83_in "$w" "$_b83D"; then [ "$no" -eq 0 ] || miss="$miss detail holds [$w];"
    else [ "$no" -eq 1 ] || miss="$miss detail lacks [$w];"; fi
  done
  if [ -z "$miss" ]; then ok "$n"; else bad "$n" "$(_b83_why "$miss")"; fi
}
_b83_ok() {   # name: the fixture held and the cloud line says ok
  if [ -n "$_b83Fx" ]; then bad "$1" "fixture:$_b83Fx"; return 0; fi
  if [ "$_b83V" = ok ]; then ok "$1"
  else bad "$1" "$(_b83_why "expected [cloud ok] got [cloud ${_b83V:-<no cloud line, gate exit $_b83Rc>}];")"; fi
}

# The lines the cases name, each written to a file as it stands: printf '%s\n' of a
# single-quoted text keeps every backslash.
_b83_l() { printf '%s\n' "$2" > "$_b83/l/$1"; }
_b83U="$(printf '%su' '\')"   # a backslash, then u
_b83_l mU   '        "matc'"$_b83U"'0068er": "Read",'
_b83_l tU   '            "timeou'"$_b83U"'0074": 1,'
_b83_l pc   '    "PreCompact": [ { "hooks": [ { "type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}\/harness\/hooks\/pre-compact\"" } ] } ],'
_b83_l sU   '            "statusMessage": "Checking'"$_b83U"'0020the gate"'
_b83_l sBS  '            "statusMessage": "Checking the gate\\"'
_b83_l cmd  '            "command": "[ \"$CLAUDE_CODE_REMOTE\" = true ] || exit 0; true",'
_b83_l hk   '  ,"hooks": {}'
_b83_l ptu  '    "PreToolUse": [],'
_b83_l mR   '        "matcher": "Read",'
_b83_l hU   '  "hook'"$_b83U"'0073": {'
_b83_l sQ   '            "statusMessage": "Checking \"the\" gate"'
# A83: a PreCompact group under matcher auto with A64's one-line hook, the
# plugin's and the settings' (with its guard).
_b83PL='          { "type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}/harness/hooks/pre-compact\"" }'
_b83SL='          { "type": "command", "command": "[ \"$CLAUDE_CODE_REMOTE\" = true ] || exit 0; exec bash \"$CLAUDE_PROJECT_DIR/engine/harness/hooks/pre-compact\"" }'
_b83_grp() { printf '    "PreCompact": [\n      {\n        "matcher": "auto",\n        "hooks": [\n%s\n        ]\n      }\n    ],\n' "$2" > "$_b83/l/$1"; }
_b83_grp gP "$_b83PL"
_b83_grp gS "$_b83SL"
_b83Sub='=    "SubagentStart": ['
_b83Pre='~harness/hooks/pre-tool'

_b83N69="B08R3 A69 (R3-1; S1): settings' PostToolUse group gains a matcher key spelled with a u-escape, value Read, as its first line: cloud FAIL, with the escape clause for settings"
_b83N70="B08R3 A70 (R3-1; S2): settings' pre-tool hook gains a timeout key spelled with a u-escape, value 1, after its command: cloud FAIL, with the escape clause for settings"
_b83N71="B08R3 A71 (R3-1, R3-4; S6): hooks.json gains a one-line PreCompact group whose command writes its slashes escaped, unbound in settings: cloud FAIL, with the escape clause for hooks.json and no not bound"
_b83N72="B08R3 A72 (R3-1, R3-4; S7): settings' PreToolUse keeps its matcher and gains a u-escaped matcher key, value Read, after it: cloud FAIL, with the escape clause for settings and no repeat clause"
_b83N73="B08R3 A73 (R3-1): settings' Stop statusMessage written with a u-escaped space, which a parser reads as the tree's own value: cloud FAIL, with the escape clause for settings"
_b83N74="B08R3 A74 (R3-1): settings' Stop statusMessage ending in an escaped backslash just before its closing quote: cloud FAIL, with the escape clause for settings"
_b83N75="B08R3 A75 (R3-3; S3): settings' pre-tool hook gains a second command key after its command, one that runs true: cloud FAIL, with the repeat clause for settings"
_b83N76="B08R3 A76 (R3-3; S4): settings' top object gains a second, empty hooks key before its final brace: cloud FAIL, with the repeat clause for settings"
_b83N77="B08R3 A77 (R3-3; S5): settings gains an empty PreToolUse key before its PostToolUse, a second PreToolUse in one object: cloud FAIL, with the repeat clause for settings"
_b83N78="B08R3 A78 (R3-3): settings' PreToolUse gains matcher Read before its own matcher, so the last is still the plugin's: cloud FAIL, with the repeat clause for settings"
_b83N79="B08R3 A79 (R3-4): A71's hooks.json with A75's settings: the detail holds the escape clause for hooks.json and then the repeat clause for settings, in that order"
_b83N80="B08R3 A80 (R3-4): the plugin's PreToolUse matcher widened as in A25, with A73's settings: cloud FAIL, with the escape clause for settings and no bound differently"
_b83N81="B08R3 A81 (R3-4): settings' line 2 written with its hooks key u-escaped: cloud FAIL, with the escape clause for settings and no no event-to-hook pairs"
_b83N82="B08R3 A82 (R3-2): settings' Stop statusMessage written with two quote escapes inside it: cloud ok (control)"
_b83N83="B08R3 A83 (R3-2, R3-3): both files gain a PreCompact group under matcher auto with A64's one-line hook: cloud ok, quote escapes read and keys repeated across objects no repeat (control)"
_b83N84="B08R3 A84 (R3-5): over A69 to A83, stubs for jq, python3 and node first on PATH record no call (control)"

if [ -n "$_b83Why" ]; then
  for _b83n in "$_b83N69" "$_b83N70" "$_b83N71" "$_b83N72" "$_b83N73" "$_b83N74" "$_b83N75" "$_b83N76" \
               "$_b83N77" "$_b83N78" "$_b83N79" "$_b83N80" "$_b83N81" "$_b83N82" "$_b83N83" "$_b83N84"; do
    skip "$_b83n" "$_b83Why"
  done
else
  _b83C="$_b83/fc"; _b83MkFx=""
  _b83_mk "$_b83C" || _b83MkFx=" FC could not be built;"
  _b83C="$(cd "${_b83C:?}" && pwd -P)"
  _b83CH="$_b83C/engine/hooks/hooks.json"; _b83CS="$_b83C/.claude/settings.json"

  # ---- B08R3-1: escapes other than the quote escape (A69 to A74)
  _b83_start; _b83_ed settings after '"PostToolUse"' '=      {' "$_b83/l/mU"
  _b83_has settings "$(cat "$_b83/l/mU")"; _b83_go a69
  _b83_fail "$_b83N69" "$_b83ES"
  _b83_start; _b83_ed settings after "" "$_b83Pre" "$_b83/l/tU"
  _b83_has settings "$(cat "$_b83/l/tU")"; _b83_go a70
  _b83_fail "$_b83N70" "$_b83ES"
  _b83_start; _b83_ed hooks before "" "$_b83Sub" "$_b83/l/pc"
  _b83_has hooks "$(cat "$_b83/l/pc")"; _b83_go a71
  _b83_fail "$_b83N71" "$_b83EH" -- "not bound"
  _b83_start; _b83_ed settings after '"PreToolUse"' '~"matcher"' "$_b83/l/mU"
  _b83_has settings "$(cat "$_b83/l/mU")"; _b83_go a72
  _b83_fail "$_b83N72" "$_b83ES" -- "$_b83RTAIL"
  _b83_start; _b83_ed settings instead "" '~"statusMessage"' "$_b83/l/sU"
  _b83_has settings "$(cat "$_b83/l/sU")"; _b83_go a73
  _b83_fail "$_b83N73" "$_b83ES"
  _b83_start; _b83_ed settings instead "" '~"statusMessage"' "$_b83/l/sBS"
  _b83_has settings "$(cat "$_b83/l/sBS")"; _b83_go a74
  _b83_fail "$_b83N74" "$_b83ES"

  # ---- B08R3-3: repeated keys (A75 to A78)
  _b83_start; _b83_ed settings after "" "$_b83Pre" "$_b83/l/cmd"
  _b83_has settings "$(cat "$_b83/l/cmd")"; _b83_go a75
  _b83_fail "$_b83N75" "$_b83RS"
  _b83_start; _b83_ed settings before "" '=}' "$_b83/l/hk"
  _b83_has settings "$(cat "$_b83/l/hk")"; _b83_go a76
  _b83_fail "$_b83N76" "$_b83RS"
  _b83_start; _b83_ed settings before "" '=    "PostToolUse": [' "$_b83/l/ptu"
  _b83_has settings "$(cat "$_b83/l/ptu")"; _b83_go a77
  _b83_fail "$_b83N77" "$_b83RS"
  _b83_start; _b83_ed settings before '"PreToolUse"' '~"matcher"' "$_b83/l/mR"
  _b83_has settings "$(cat "$_b83/l/mR")"; _b83_go a78
  _b83_fail "$_b83N78" "$_b83RS"

  # ---- B08R3-4: one clause per file, and no comparison over an unreadable file (A79 to A81)
  _b83_start; _b83_ed hooks before "" "$_b83Sub" "$_b83/l/pc"; _b83_ed settings after "" "$_b83Pre" "$_b83/l/cmd"
  _b83_has hooks "$(cat "$_b83/l/pc")"; _b83_has settings "$(cat "$_b83/l/cmd")"; _b83_go a79
  _b83p1="$(_b83_at "$_b83EH" "$_b83D")"; _b83p2="$(_b83_at "$_b83RS" "$_b83D")"
  if [ -n "$_b83Fx" ]; then bad "$_b83N79" "fixture:$_b83Fx"
  elif [ "${_b83p1:-0}" -gt 0 ] && [ "${_b83p2:-0}" -gt "${_b83p1:-0}" ]; then ok "$_b83N79"
  else bad "$_b83N79" "$(_b83_why "hooks.json's escape clause at ${_b83p1:-0}, settings' repeat clause at ${_b83p2:-0} (0: absent);")"
  fi
  _b83WL="$(LC_ALL=C awk "$_b83WIDEN" "$_b83S" 2>/dev/null | LC_ALL=C grep -F '|Glob|Grep"')"
  _b83_start; _b83_apply hooks "$_b83WIDEN"; _b83_ed settings instead "" '~"statusMessage"' "$_b83/l/sU"
  _b83_has hooks "$_b83WL"; _b83_has settings "$(cat "$_b83/l/sU")"; _b83_go a80
  _b83_fail "$_b83N80" "$_b83ES" -- "bound differently"
  _b83_start; _b83_ed settings instead "" '=  "hooks": {' "$_b83/l/hU"
  _b83_has settings "$(cat "$_b83/l/hU")"; _b83_go a81
  _b83_fail "$_b83N81" "$_b83ES" -- "no event-to-hook pairs"

  # ---- B08R3-2: the quote escape stays readable (A82, A83, controls)
  _b83_start; _b83_ed settings instead "" '~"statusMessage"' "$_b83/l/sQ"
  _b83_has settings "$(cat "$_b83/l/sQ")"; _b83_go a82
  _b83_ok "$_b83N82"
  _b83_start; _b83_ed hooks before "" "$_b83Sub" "$_b83/l/gP"; _b83_ed settings before "" "$_b83Sub" "$_b83/l/gS"
  _b83_has hooks "$_b83PL"; _b83_has settings "$_b83SL"; _b83_go a83
  _b83_ok "$_b83N83"

  # ---- B08R3-5: no other tool decides (A84, control)
  if [ "$_b83Probe" = "jq b08r3-probe python3 b08r3-probe node b08r3-probe " ]; then _b83O="$(cat "$_b83/stub/calls" 2>/dev/null)"
  else _b83O="[the stubs do not record a call: their probe left (${_b83Probe:-nothing})]"; fi
  is "$_b83N84" "$_b83O" ""
fi
