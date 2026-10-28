printf '\nthe cloud check judges what a checkout writes (audit b08 round 3, section 11, blind)\n'
# Written blind on 2026-10-28 from section 11 of docs/2026-10-24-audit-fixes/b08-round-3.md
# (B08R3Z-1 to B08R3Z-7, A141 to A154), with its sections 2 to 10 as context, without
# reading projects/felix/gate.sh, engine/ code or anything the gate sources. One assertion
# per item, named "B08R3Z A<n> (R3Z-<m>...): ...". Part 1771 would pass 950 lines with them,
# so they are a part of their own, sourced right after 1771, over 1771's FC with 1771's
# helpers (_b83_ystart, _b83_yo, _b83_seq, _b83_asok and the rest), in the state A140 leaves.
# - Under tests/run -j N a part is a unit of its own, and groups.tsv, which could put 1771 and
#   this part in one unit, is a table this round may not touch. So when 1771's helpers are
#   not in this shell, this part reads them from 1771's text (every line after its first,
#   up to its first case block) and builds FC as 1771 does; when that fails, each case skips
#   and says why.
# Readings taken where the text leaves room:
# - Each case starts from _b84_start: nothing a case before it left (a merge in progress, the
#   side branch, .gitattributes, projects/felix/stack.tsv, any index entry or file under any
#   case of .claude), then _b83_ystart. _b84_cloud adds this tree's .claude/cloud and stages
#   .claude, so "the tree's own .claude" and "the cloud line as A140" read as A140 does.
# - A141, A142: the file on disk is the tree's file written by iconv as UTF-16 (a byte order
#   mark first) and staged after the attribute, so git stores the tree's UTF-8 bytes; the
#   fixture compares the index blob with the tree's file. Without iconv both skip.
# - Every clause is matched without the blank the contract writes before it.
# - A145 to A147: the hook is a one-hook PreCompact group before SubagentStart in settings
#   alone, as A136's is (a settings binding the plugin lacks is allowed, B26). A147's "no
#   guard clause": no guard-count text in the output, and the cloud line as A140, since its
#   settings is the tree's plus an allowed binding.
# - A148: <path> in the non-ASCII clause is the entry's path as its bytes (git's quoted form
#   is an encoding of it). The entry is made by update-index --cacheinfo, as A134's, and the
#   index is listed with core.quotePath off. This file builds U+017F and the e-acute of A149
#   with printf octal escapes, so it holds no byte above 0x7f.
# - A150's entry is anthropic-skills, a plugin row whose name has no @, so <name> is the same
#   however the check maps stack.tsv names onto toolbox names. FC gains this tree's
#   stack.tsv for A150 and A151 only.
# - A151: TMPDIR and GTLOG_DIR name one new, empty directory (GTLOG_DIR is set whether or not
#   the gate reads it). "A file the cloud check made" is one holding what the check reads:
#   settings, the toolbox and stack.tsv each carry a marker, and a file there holding a marker
#   or harness/hooks/ is the check's. Any other file left there is named on a failure only.
# - A152: two branches give the Stop statusMessage different values and are merged; git
#   ls-files -s shows stages 1, 2 and 3 for settings and no 0. "The stage-0 clause exactly":
#   the clause byte for byte, settings named once, and no / between the parentheses after its
#   path. It pins no last line or exit status, as the contract names the clause alone and
#   other checks may read a conflicted index too. The merge is aborted after the run.
# - A153, A154: "the guard clause" is A136's; HEAD's copy is read with cat-file HEAD:<path>.

_b84Why=""
if [ "$(type -t _b83_ystart)" != function ]; then
  B84_L='if [ -n "$_b83Why" ]; then' LC_ALL=C awk 'NR > 1 && $0 == ENVIRON["B84_L"] { exit } NR > 1 { print }' \
    "$HERE/parts/1771-b08-round-3-blind.sh" > "$TMP/b84-1771.sh" 2>/dev/null && . "$TMP/b84-1771.sh"
  if [ "$(type -t _b83_ystart)" = function ] && [ -z "${_b83Why:-}" ]; then
    _b83C="$_b83/fc"; _b83MkFx=""
    _b83_mk "$_b83C" || _b83MkFx=" FC could not be built;"
    _b83C="$(cd "${_b83C:?}" && pwd -P)"
    _b83CH="$_b83C/engine/hooks/hooks.json"; _b83CS="$_b83C/.claude/settings.json"
  fi
fi
if [ "$(type -t _b83_ystart)" != function ]; then _b84Why="part 1771's helpers are not in this shell and could not be read from its text"
elif [ -n "${_b83Why:-}" ]; then _b84Why="$_b83Why"
elif [ -z "${_b83C:-}" ] || [ ! -d "$_b83C/.git" ]; then _b84Why="part 1771's FC is not there"; fi

# Section 11's clauses, its names for the entries, and its lines.
_b84_at() { printf 'unreadable: %s (git attribute %s changes it at checkout);' "$1" "$2"; }
_b84_na() { printf '%s' "unreadable: $1 (a non-ASCII name the Mac's file system may fold onto one the cloud reads);"; }
_b84S0="unreadable: .claude/settings.json (git's index holds no stage-0 copy of it);"
_b84TB='anthropic-skills has no entry in .claude/cloud/toolbox.json;'
_b84NF=".claude/$(printf '\305\277')ettings.json"
_b84NE=".claude/cloud/notes-$(printf '\303\251').md"
_b84ST="$REAL_HARNESS/../../projects/felix/stack.tsv"
_b84Row=""; [ ! -f "$_b84ST" ] || _b84Row="$(LC_ALL=C awk -F '\t' '$1 == "plugin" && $2 == "anthropic-skills"' "$_b84ST")"
_b84Iv=""; command -v iconv >/dev/null 2>&1 || _b84Iv="no iconv on PATH to write the UTF-16 file"
_b84C1='          { "type": "command", "command" : "exec bash \"$CLAUDE_PROJECT_DIR/engine/harness/hooks/pre-compact\"" }'
_b84C2a='          { "type": "command", "command"'
_b84C2b='            : "exec bash \"$CLAUDE_PROJECT_DIR/engine/harness/hooks/pre-compact\"" }'
_b84C3='          { "type": "command", "command" : "[ \"$CLAUDE_CODE_REMOTE\" = true ] || exit 0; exec bash \"$CLAUDE_PROJECT_DIR/engine/harness/hooks/pre-compact\"" }'
_b84M1='b08r3z a151 settings marker'; _b84M2='b08r3z a151 toolbox marker'; _b84M3='b08r3z a151 stack marker'

# FC with nothing left of a case before it, then _b83_ystart: .claude holding settings.json alone, staged.
_b84_start() {
  [ ! -f "$_b83C/.git/MERGE_HEAD" ] || _b83_git "$_b83C" merge --abort >/dev/null 2>&1
  _b83_git "$_b83C" branch -q -D b84side >/dev/null 2>&1
  _b83_git "$_b83C" rm -q --cached --ignore-unmatch -- .gitattributes projects/felix/stack.tsv >/dev/null 2>&1
  rm -f "$_b83C/.gitattributes" "$_b83C/projects/felix/stack.tsv"
  _b83_git "$_b83C" -c core.quotePath=false ls-files 2>/dev/null | LC_ALL=C awk 'index(tolower($0), ".claude") == 1' \
    | while IFS= read -r _b84p; do _b83_git "$_b83C" update-index --force-remove -- "$_b84p" >/dev/null 2>&1; done
  if [ -L "$_b83C/.claude" ]; then rm -f "$_b83C/.claude"; else rm -rf "${_b83C:?}/.claude"; fi
  _b83_ystart
}
# This tree's .claude/cloud copied into FC's .claude, and .claude staged: A140's .claude.
_b84_cloud() {
  cp -R "$_b83T/cloud" "$_b83C/.claude/cloud" || _b83Fx="$_b83Fx the cloud directory could not be copied;"
  _b83_git "$_b83C" add -- .claude >/dev/null 2>&1 || _b83Fx="$_b83Fx .claude could not be staged;"
}
_b84_add() { _b83_git "$_b83C" add -- "${1:-.claude/settings.json}" >/dev/null 2>&1 || _b83Fx="$_b83Fx ${1:-.claude/settings.json} could not be staged;"; }
# line: FC's .gitattributes holds the line alone, staged.
_b84_ga() {
  { printf '%s\n' "$1" > "$_b83C/.gitattributes" && _b83_git "$_b83C" add -- .gitattributes >/dev/null 2>&1; } \
    || _b83Fx="$_b83Fx .gitattributes could not be written and staged;"
}
# path attr value: git check-attr --cached reports that value for path, else a fixture fault.
_b84_ca() {
  local s
  s="$(_b83_git "$_b83C" check-attr --cached "$2" -- "$1" 2>/dev/null)"
  [ "$s" = "$1: $2: $3" ] || _b83Fx="$_b83Fx git check-attr --cached says [$s], not [$1: $2: $3];"
}
_b84_head() { [ "$(_b83_git "$_b83C" ls-tree --name-only HEAD -- "$1" 2>/dev/null)" = "$1" ] || _b83Fx="$_b83Fx HEAD does not hold $1;"; }
_b84_ixs() { _b83_blob; cmp -s "$_b83S" "$_b83/ix.tmp" || _b83Fx="$_b83Fx the index's settings.json is not the tree's;"; }
_b84_ixd() { _b83_blob; cmp -s "$_b83CS" "$_b83/ix.tmp" || _b83Fx="$_b83Fx the index's settings.json is not the disk's;"; }
_b84_hb() { _b83_git "$_b83C" cat-file blob HEAD:.claude/settings.json > "$_b83/hd.tmp" 2>/dev/null || : > "$_b83/hd.tmp"; }
# tree-file path: FC's path written by iconv as UTF-16 and staged through the attribute; its blob the tree's UTF-8 file.
_b84_u16() {
  local b
  { LC_ALL=C iconv -f UTF-8 -t UTF-16 < "$1" > "$_b83C/$2" && _b83_git "$_b83C" add -- "$2" >/dev/null 2>&1; } \
    || _b83Fx="$_b83Fx $2 could not be written as UTF-16 and staged;"
  b="$(LC_ALL=C od -An -tx1 -N 2 "$_b83C/$2" 2>/dev/null | LC_ALL=C tr -d ' \n')"
  case "$b" in feff|fffe) ;; *) _b83Fx="$_b83Fx $2 on disk begins [$b], not a UTF-16 byte order mark;" ;; esac
  _b83_git "$_b83C" cat-file blob ":$2" > "$_b83/u16.tmp" 2>/dev/null
  cmp -s "$1" "$_b83/u16.tmp" || _b83Fx="$_b83Fx the index blob of $2 is not the tree's UTF-8 file;"
}
# Every index entry whose path, ASCII case folded, is .claude or under it, its bytes as they are: "<mode> <path>", "; " between.
_b84_ixq() { _b83_git "$_b83C" -c core.quotePath=false ls-files -s 2>/dev/null | LC_ALL=C awk -F '\t' '{ p = tolower($2) }
  p == ".claude" || index(p, ".claude/") == 1 { split($1, m, " "); printf "%s%s %s", (n++ ? "; " : ""), m[1], $2 }'; }
_b84_ixw() { local s; s="$(_b84_ixq)"; [ "$s" = "$1" ] || _b83Fx="$_b83Fx git ls-files -s shows [$s] under any case of .claude, not [$1];"; }
# The stages the index holds for .claude/settings.json, blank between.
_b84_stg() { _b83_git "$_b83C" ls-files -s -- .claude/settings.json 2>/dev/null | LC_ALL=C awk -F '\t' '{ split($1, m, " "); printf "%s%s", (NR > 1 ? " " : ""), m[3] }'; }
# This tree's stack.tsv in FC, staged; a fixture fault when it has no anthropic-skills plugin row.
_b84_stack() {
  [ -n "$_b84Row" ] || _b83Fx="$_b83Fx no anthropic-skills plugin row in this tree's stack.tsv;"
  cp "$_b84ST" "$_b83C/projects/felix/stack.tsv" || _b83Fx="$_b83Fx stack.tsv could not be copied;"
  _b84_add projects/felix/stack.tsv
}
# The toolbox's five-line anthropic-skills entry dropped from FC's copy.
_b84DROP='{ l[NR] = $0 } !at && $0 == ENVIRON["B84_N"] { at = NR }
  END { if (!at || l[at - 1] != "    {" || l[at + 3] != "    },") exit 3; for (i = 1; i <= NR; i++) if (i < at - 1 || i > at + 3) print l[i] }'
_b84_dropt() {
  local f="$_b83C/.claude/cloud/toolbox.json"
  if B84_N='      "name": "anthropic-skills",' LC_ALL=C awk "$_b84DROP" "$f" > "$_b83/ed.tmp"; then cat "$_b83/ed.tmp" > "$f"
  else _b83Fx="$_b83Fx no five-line anthropic-skills entry in the toolbox to remove;"; fi
}
# fc-path mode text line-file: as _b83_ed, on any file of FC.
_b84_edp() {
  local f="$_b83C/$1"
  if env B83_M="$2" B83_C="" B83_A="$3" B83_I="$4" LC_ALL=C awk "$_b83ED" "$f" > "$_b83/ed.tmp" && ! cmp -s "$f" "$_b83/ed.tmp"; then
    cat "$_b83/ed.tmp" > "$f"
  else _b83Fx="$_b83Fx the edit of $1 changed nothing;"; fi
}
# dir: each file under dir holding a marker or harness/hooks/, "; " after each; and every file there, with its size.
_b84_made() { find "$1" -type f 2>/dev/null | LC_ALL=C sort | while IFS= read -r _b84f; do
    if LC_ALL=C grep -qF -e "$_b84M1" -e "$_b84M2" -e "$_b84M3" -e 'harness/hooks/' -- "$_b84f" 2>/dev/null; then printf '%s; ' "${_b84f#"$1"/}"; fi
  done; }
_b84_all() { find "$1" -type f 2>/dev/null | LC_ALL=C sort | while IFS= read -r _b84f; do
    printf '%s (%s bytes); ' "${_b84f#"$1"/}" "$(LC_ALL=C wc -c < "$_b84f" | LC_ALL=C tr -d ' ')"; done; }
# detail: the text between the parentheses after "unreadable: .claude/settings.json (" that holds a /, the first.
_b84_par() { B83_S="$1" B83_W="unreadable: .claude/settings.json (" LC_ALL=C awk 'BEGIN { s = ENVIRON["B83_S"]; w = ENVIRON["B83_W"]
  while ((i = index(s, w)) > 0) { s = substr(s, i + length(w)); j = index(s, ")"); p = j ? substr(s, 1, j - 1) : s; if (index(p, "/")) { print p; exit } } }'; }
# name: the fixture held, the cloud FAIL line once, the detail holds the stage-0 clause and names settings once, no / in its parentheses.
_b84_s0() {
  local m p
  _b83_once "$_b83PS"; m="$_b83Xm"; _b83Xm=""
  if [ -n "$_b83Fx" ]; then bad "$1" "fixture:$_b83Fx"; return 0; fi
  [ "${_b83N:-0}" = 1 ] || m="$m no line [$_b83FAIL] (cloud [${_b83V:-none}]);"
  _b83_in "$_b84S0" "$_b83D" || m="$m detail lacks [$_b84S0];"
  p="$(_b84_par "$_b83D")"; [ -z "$p" ] || m="$m a / inside the parentheses after settings' path [$p];"
  if [ -z "$m" ]; then ok "$1"; else bad "$1" "$(_b83_why "$m")"; fi
}
# run name: as _b83_asok, and no guard-count text anywhere in the output.
_b84_okg() {
  local c g=none
  c="$(LC_ALL=C grep -cxF -e "$(printf '  %-18s %s' cloud ok)" "$_b83/$1.out" 2>/dev/null)"
  ! _b83_in "$_b83GT" "$_b83All" || g=held
  if [ -n "$_b83Fx" ]; then bad "$2" "fixture:$_b83Fx"
  else _b83_is "$2" "${c:-0} cloud ok lines; the line under it [$_b83D]; guard clause $g" "1 cloud ok lines; the line under it []; guard clause none"; fi
}

_b84N141="B08R3Z A141 (R3Z-1): a committed .gitattributes gives .claude/settings.json working-tree-encoding=UTF-16, and the tree's settings is staged through it from a UTF-16 file, so its index blob is the tree's UTF-8: cloud FAIL, with the attribute clause naming .claude/settings.json and working-tree-encoding"
_b84N142="B08R3Z A142 (R3Z-1): the same for .claude/cloud/toolbox.json, UTF-16 on disk and the tree's UTF-8 in the index: cloud FAIL, with the attribute clause naming .claude/cloud/toolbox.json and working-tree-encoding"
_b84N143="B08R3Z A143 (R3Z-1): a committed .gitattributes gives .claude/settings.json filter=felixtest, with no driver configured: cloud FAIL, with the attribute clause naming .claude/settings.json and filter"
_b84N144="B08R3Z A144 (R3Z-1): a committed .gitattributes gives .claude/settings.json text eol=lf: cloud ok and the line under it empty, as A140 (control)"
_b84N145="B08R3Z A145 (R3Z-2): settings gains a hook whose command key has a blank before its colon and whose command runs a harness hook unguarded: cloud FAIL with 1 command(s) without the CLAUDE_CODE_REMOTE guard"
_b84N146="B08R3Z A146 (R3Z-2): the same with a newline between the command key and its colon: cloud FAIL with 1 command(s) without the CLAUDE_CODE_REMOTE guard"
_b84N147="B08R3Z A147 (R3Z-2): a guarded harness command whose command key has a blank before its colon: no guard clause, and the cloud line ok with the line under it empty, as A140 (control)"
_b84N148="B08R3Z A148 (R3Z-3): the index holds .claude/settings.json spelled with U+017F (bytes C5 BF) for its s, the tree's blob, and no exact .claude/settings.json: cloud FAIL, the non-ASCII clause naming that entry, and no skipped"
_b84N149="B08R3Z A149 (R3Z-3): the tree's own .claude plus a committed .claude/cloud/notes-<e-acute>.md, U+00E9: cloud ok and the line under it empty, as A140 (control)"
_b84N150="B08R3Z A150 (R3Z-4): the toolbox entry anthropic-skills removed and staged, its stack.tsv row removed on disk only: cloud FAIL with anthropic-skills has no entry in .claude/cloud/toolbox.json"
_b84N151="B08R3Z A151 (R3Z-5): the gate run with TMPDIR and GTLOG_DIR naming one empty directory, settings, the toolbox and stack.tsv each carrying a marker: cloud ok, and no file left there holds a marker or harness/hooks/"
_b84N152="B08R3Z A152 (R3Z-6): .claude/settings.json in a merge conflict, stages 1 to 3 in the index and no stage 0: the cloud FAIL line, the stage-0 clause exactly, settings named once, and no slash inside its parentheses"
_b84N153="B08R3Z A153 (R3Z-7): HEAD and the disk hold the tree's settings.json, the index a staged, uncommitted copy with an unguarded harness command on its own line: cloud FAIL with 1 command(s) without the CLAUDE_CODE_REMOTE guard"
_b84N154="B08R3Z A154 (R3Z-7): HEAD holds that unguarded copy, the index and the disk the tree's settings.json: cloud ok and the line under it empty, as A140 (control)"

if [ -n "$_b84Why" ]; then
  for _b84n in "$_b84N141" "$_b84N142" "$_b84N143" "$_b84N144" "$_b84N145" "$_b84N146" "$_b84N147" \
               "$_b84N148" "$_b84N149" "$_b84N150" "$_b84N151" "$_b84N152" "$_b84N153" "$_b84N154"; do
    skip "$_b84n" "$_b84Why"
  done
else
  _b83_grp zc1 "$_b84C1"; _b83_grp zc2 "$(printf '%s\n%s' "$_b84C2a" "$_b84C2b")"; _b83_grp zc3 "$_b84C3"
  _b83_l zm1 '            "statusMessage": "b08r3z a151 settings marker"'
  _b83_l zm2 '    "b08r3z a151 toolbox marker",'
  _b83_l zsd '            "statusMessage": "Checking the gate on the side"'
  _b83_l zmn '            "statusMessage": "Checking the gate on main"'

  # ---- B08R3Z-1: a checkout conversion is a fault (A141 to A144)
  if [ -n "$_b84Iv" ]; then skip "$_b84N141" "$_b84Iv"; skip "$_b84N142" "$_b84Iv"
  else
    _b84_start; _b84_cloud; _b84_ga '.claude/settings.json working-tree-encoding=UTF-16'
    _b84_u16 "$_b83S" .claude/settings.json; _b83_yo a141
    _b84_ca .claude/settings.json working-tree-encoding UTF-16; _b84_head .gitattributes
    _b83_seq "$_b84N141" any "$(_b84_at .claude/settings.json working-tree-encoding)"
    _b84_start; _b84_cloud; _b84_ga '.claude/cloud/toolbox.json working-tree-encoding=UTF-16'
    _b84_u16 "$_b83T/cloud/toolbox.json" .claude/cloud/toolbox.json; _b83_yo a142
    _b84_ca .claude/cloud/toolbox.json working-tree-encoding UTF-16; _b84_head .gitattributes
    _b83_seq "$_b84N142" any "$(_b84_at .claude/cloud/toolbox.json working-tree-encoding)"
  fi
  _b84_start; _b84_cloud; _b84_ga '.claude/settings.json filter=felixtest'; _b84_add; _b83_yo a143
  _b84_ca .claude/settings.json filter felixtest; _b84_head .gitattributes; _b84_ixs
  [ -z "$(_b83_git "$_b83C" config --get-regexp '^filter[.]felixtest[.]' 2>/dev/null)" ] || _b83Fx="$_b83Fx a felixtest filter driver is configured;"
  _b83_seq "$_b84N143" any "$(_b84_at .claude/settings.json filter)"
  _b84_start; _b84_cloud; _b84_ga '.claude/settings.json text eol=lf'; _b84_add; _b83_yo a144
  _b84_ca .claude/settings.json text set; _b84_ca .claude/settings.json eol lf; _b84_head .gitattributes; _b84_ixs
  _b83_asok a144 "$_b84N144"

  # ---- B08R3Z-2: the guard count reads the JSON (A145 to A147)
  _b84_start; _b84_cloud; _b83_ed settings before "" "$_b83Sub" "$_b83/l/zc1"; _b83_has settings "$_b84C1"
  _b84_add; _b83_yo a145; _b84_ixd
  _b83_g1; _b83_seq "$_b84N145" any "$_b83G1"
  _b84_start; _b84_cloud; _b83_ed settings before "" "$_b83Sub" "$_b83/l/zc2"; _b83_has settings "$_b84C2a"; _b83_has settings "$_b84C2b"
  _b84_add; _b83_yo a146; _b84_ixd
  _b83_g1; _b83_seq "$_b84N146" any "$_b83G1"
  _b84_start; _b84_cloud; _b83_ed settings before "" "$_b83Sub" "$_b83/l/zc3"; _b83_has settings "$_b84C3"
  _b84_add; _b83_yo a147; _b84_ixd
  _b84_okg a147 "$_b84N147"

  # ---- B08R3Z-3: a non-ASCII name the Mac may fold (A148, A149)
  _b84_start; _b84h="$(_b83_git "$_b83C" hash-object -w -- .claude/settings.json 2>/dev/null)"
  { [ -n "$_b84h" ] && _b83_git "$_b83C" rm -q --cached -- .claude/settings.json >/dev/null 2>&1 \
      && _b83_git "$_b83C" update-index --add --cacheinfo "100644,$_b84h,$_b84NF" >/dev/null 2>&1; } \
    || _b83Fx="$_b83Fx the index entry with U+017F could not be made;"
  _b83_yo a148; _b84_ixw "100644 $_b84NF"
  cmp -s "$_b83S" "$_b83CS" || _b83Fx="$_b83Fx the disk lacks the tree's settings.json;"
  _b83_nsk a148; _b83_seq "$_b84N148" any "$(_b84_na "$_b84NF")" -- skipped
  _b84_start; _b84_cloud
  printf 'notes\n' > "$_b83C/$_b84NE" || _b83Fx="$_b83Fx the e-acute file could not be written;"
  _b84_add "$_b84NE"; _b83_yo a149; _b84t="$(_b84_ixq)"
  for _b84w in "100644 $_b84NE" "100644 .claude/cloud/toolbox.json" "100644 .claude/settings.json"; do
    _b83_in "$_b84w" "$_b84t" || _b83Fx="$_b83Fx git ls-files -s shows [$_b84t] under .claude, without [$_b84w];"
  done
  _b83_asok a149 "$_b84N149"

  # ---- B08R3Z-4: both sides of the toolbox comparison from the index (A150)
  _b84_start; _b84_cloud; _b84_stack; _b84_dropt; _b84_add .claude/cloud/toolbox.json
  { B84_R="$_b84Row" LC_ALL=C awk '$0 != ENVIRON["B84_R"]' "$_b83C/projects/felix/stack.tsv" > "$_b83/ed.tmp" \
      && cat "$_b83/ed.tmp" > "$_b83C/projects/felix/stack.tsv"; } || _b83Fx="$_b83Fx the stack row could not be removed on disk;"
  _b83_yo a150
  _b83_git "$_b83C" cat-file blob :projects/felix/stack.tsv > "$_b83/st.tmp" 2>/dev/null
  { [ "$(LC_ALL=C grep -cxF -e "$_b84Row" "$_b83/st.tmp" 2>/dev/null)" = 1 ] \
      && [ "$(LC_ALL=C grep -cxF -e "$_b84Row" "$_b83C/projects/felix/stack.tsv" 2>/dev/null)" = 0 ]; } \
    || _b83Fx="$_b83Fx the anthropic-skills row is not in the index's stack.tsv alone;"
  _b83_git "$_b83C" cat-file blob :.claude/cloud/toolbox.json > "$_b83/tb.tmp" 2>/dev/null
  { [ "$(LC_ALL=C grep -cF -e '"anthropic-skills"' "$_b83/tb.tmp" 2>/dev/null)" = 0 ] && cmp -s "$_b83/tb.tmp" "$_b83C/.claude/cloud/toolbox.json"; } \
    || _b83Fx="$_b83Fx the toolbox's anthropic-skills entry is not removed and staged;"
  _b83_seq "$_b84N150" any "$_b84TB"

  # ---- B08R3Z-5: the check leaves no file behind (A151)
  _b84_start; _b84_cloud; _b84_stack
  printf '# %s\n' "$_b84M3" >> "$_b83C/projects/felix/stack.tsv"; _b84_add projects/felix/stack.tsv
  _b83_ed settings instead "" '~"statusMessage"' "$_b83/l/zm1"; _b83_has settings "$(cat "$_b83/l/zm1")"; _b84_add
  _b84_edp .claude/cloud/toolbox.json after '=  "about": [' "$_b83/l/zm2"; _b84_add .claude/cloud/toolbox.json
  _b83_git "$_b83C" commit -qm a151 >/dev/null 2>&1
  for _b84w in ".claude/settings.json|$_b84M1" ".claude/cloud/toolbox.json|$_b84M2" "projects/felix/stack.tsv|$_b84M3"; do
    _b83_git "$_b83C" cat-file blob ":${_b84w%%|*}" > "$_b83/mk.tmp" 2>/dev/null
    [ "$(LC_ALL=C grep -cF -e "${_b84w#*|}" "$_b83/mk.tmp" 2>/dev/null)" = 1 ] || _b83Fx="$_b83Fx the index's ${_b84w%%|*} does not hold its marker once;"
  done
  { mv "$_b83/tmp" "$_b83/tmp-before-a151" && mkdir "$_b83/tmp" && [ -z "$(ls -A "$_b83/tmp" 2>/dev/null)" ]; } \
    || _b83Fx="$_b83Fx no new, empty directory for TMPDIR;"
  GTLOG_DIR="$_b83/tmp" _b83_run a151
  _b84m="$(_b84_made "$_b83/tmp")"; _b84a="$(_b84_all "$_b83/tmp")"
  if [ -n "$_b83Fx" ]; then bad "$_b84N151" "fixture:$_b83Fx"
  elif [ "$_b83V" = ok ] && [ -z "$_b84m" ]; then ok "$_b84N151"
  else bad "$_b84N151" "$(_b83_why " cloud [${_b83V:-none}]; files the cloud check made [$_b84m]; every file left there [$_b84a];")"; fi

  # ---- B08R3Z-6: a missing stage-0 copy is said as such (A152)
  _b84_start; _b84_cloud; _b83_git "$_b83C" commit -qm a152-base >/dev/null 2>&1
  _b83_git "$_b83C" checkout -q -b b84side >/dev/null 2>&1 || _b83Fx="$_b83Fx the side branch could not be made;"
  _b83_ed settings instead "" '~"statusMessage"' "$_b83/l/zsd"; _b83_git "$_b83C" commit -qam a152-side >/dev/null 2>&1
  _b83_git "$_b83C" checkout -q main >/dev/null 2>&1 || _b83Fx="$_b83Fx main could not be checked out again;"
  _b83_ed settings instead "" '~"statusMessage"' "$_b83/l/zmn"; _b83_git "$_b83C" commit -qam a152-main >/dev/null 2>&1
  ! _b83_git "$_b83C" merge -q --no-edit b84side >/dev/null 2>&1 || _b83Fx="$_b83Fx the merge did not conflict;"
  _b84t="$(_b84_stg)"
  { [ "$_b84t" = "1 2 3" ] && [ -f "$_b83C/.git/MERGE_HEAD" ]; } || _b83Fx="$_b83Fx git ls-files -s shows stages [$_b84t] for settings.json, not [1 2 3], or no merge is in progress;"
  _b83_run a152
  _b84_s0 "$_b84N152"
  _b83_git "$_b83C" merge --abort >/dev/null 2>&1; _b83_git "$_b83C" branch -q -D b84side >/dev/null 2>&1

  # ---- B08R3Z-7: the index, not HEAD (A153, A154)
  _b84_start; _b84_cloud; _b83_git "$_b83C" commit -qm a153-base >/dev/null 2>&1
  _b83_ed settings before "" "$_b83Sub" "$_b83/l/gU"; _b83_has settings "$_b83UL"; _b84_add
  cp "$_b83S" "$_b83CS"; _b83_run a153; _b83_blob; _b84_hb
  { [ "$(LC_ALL=C grep -cxF -e "$_b83UL" "$_b83/ix.tmp" 2>/dev/null)" = 1 ] && cmp -s "$_b83S" "$_b83/hd.tmp" && cmp -s "$_b83S" "$_b83CS"; } \
    || _b83Fx="$_b83Fx the index's settings.json lacks the unguarded line, or HEAD's or the disk's is not the tree's;"
  _b83_g1; _b83_seq "$_b84N153" any "$_b83G1"
  _b84_start; _b84_cloud; _b83_ed settings before "" "$_b83Sub" "$_b83/l/gU"; _b83_has settings "$_b83UL"; _b84_add
  _b83_git "$_b83C" commit -qm a154-base >/dev/null 2>&1; cp "$_b83S" "$_b83CS"; _b84_add
  _b83_run a154; _b83_blob; _b84_hb
  { [ "$(LC_ALL=C grep -cxF -e "$_b83UL" "$_b83/hd.tmp" 2>/dev/null)" = 1 ] && cmp -s "$_b83S" "$_b83/ix.tmp" && cmp -s "$_b83S" "$_b83CS"; } \
    || _b83Fx="$_b83Fx HEAD's settings.json lacks the unguarded line, or the index's or the disk's is not the tree's;"
  _b83_asok a154 "$_b84N154"
fi
