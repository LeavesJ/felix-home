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
#
# Section 12 (B08R3Z2-1 to B08R3Z2-5, A155 to A169) was written blind on 2026-10-28 from the same
# file, after A154, without reading gate.sh's cloud check. Its names start "B08R3Z2 A<n>", and
# A151's name now says it is a pin of a normal exit (B08R3Z2-5); what A151 checks is unchanged.
# - FC's settings.json runs .claude/cloud/provision (its SessionStart hook), so A161 and A162 add
#   no hook. _b84_cloud gives provision mode 100755 in the index, as this tree's.
# - "The toolbox clause" is section 12's clause for toolbox.json, its reason the reader's words
#   section 7 gives (a key repeated in one object, not JSON). A160's reason is not worded there,
#   so it is matched up to its parenthesis, and not as the not-JSON one, since the file is JSON.
#   A158 to A160 put this tree's stack.tsv in FC, so "no has no entry" is a test: a reader of the
#   last tools, or of none, would say it for every row.
# - A157: FC's own .git/config holds core.ignorecase true for the case, and as it was after. The
#   fixture checks check-attr says felixtest under ignorecase true and unspecified under false.
#   "As Linux reads it": cloud ok and the line under it empty, as A140, and no filter clause.
# - A163's link points at an untracked cfg/stack.tsv, this tree's rows and one plugin row more,
#   b08r3z2-extra. A164's branches append different lines to stack.tsv; like A152 it pins the
#   cloud FAIL line and the detail, not the last line or exit status.
# - A166's .git/info/attributes is removed after its run. A167's two runs (provision, and
#   settings.local.json, each with U+017F for an s) are one assertion; entries as A148 makes them.
# - A169, widened by section 13 (B08R3Z3-4), reads gate.sh's cloud section: from its cloud banner,
#   a line "# -...- cloud -...-", to the line before the next such banner, or to the end of the
#   file. Read as text, a comment inside it counts. Section 13's A170 to A187 are in part 1773.

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
_b84N151="B08R3Z A151 (R3Z-5), a pin of a normal exit: the gate run to its end with TMPDIR and GTLOG_DIR naming one empty directory, settings, the toolbox and stack.tsv each carrying a marker: cloud ok, and no file left there holds a marker or harness/hooks/"
_b84N152="B08R3Z A152 (R3Z-6): .claude/settings.json in a merge conflict, stages 1 to 3 in the index and no stage 0: the cloud FAIL line, the stage-0 clause exactly, settings named once, and no slash inside its parentheses"
_b84N153="B08R3Z A153 (R3Z-7): HEAD and the disk hold the tree's settings.json, the index a staged, uncommitted copy with an unguarded harness command on its own line: cloud FAIL with 1 command(s) without the CLAUDE_CODE_REMOTE guard"
_b84N154="B08R3Z A154 (R3Z-7): HEAD holds that unguarded copy, the index and the disk the tree's settings.json: cloud ok and the line under it empty, as A140 (control)"

# Section 12's clauses, its names for the entries, and its helpers.
_b85TB='.claude/cloud/toolbox.json'; _b85NE='has no entry in .claude/cloud/toolbox.json'
_b85_tc() { printf 'unreadable: .claude/cloud/toolbox.json (%s);' "$1"; }
_b85PV="unreadable: .claude/cloud/provision (settings.json runs it, and git's index holds no executable file there);"
_b85ST="unreadable: projects/felix/stack.tsv (not a regular file at stage 0 in git's index);"
_b85S="$(printf '\305\277')"; _b85PN=".claude/cloud/provi${_b85S}ion"; _b85LN=".claude/${_b85S}ettings.local.json"; _b85NN=".claude/cloud/notes-${_b85S}.md"
_b85IX='100755 .claude/cloud/provision; 100644 .claude/cloud/toolbox.json; 100644 .claude/settings.json'
_b85Xr="$(B85_R="$_b84Row" LC_ALL=C awk 'BEGIN { n = split(ENVIRON["B85_R"], f, "\t"); s = f[1] "\tb08r3z2-extra"; for (i = 3; i <= n; i++) s = s "\t" f[i]; print s }')"
# line n: FC's toolbox holds the line n times (grep -cxF), else a fixture fault.
_b85_tn() { local n; n="$(LC_ALL=C grep -cxF -e "$1" "$_b83C/$_b85TB" 2>/dev/null)"; [ "${n:-0}" = "$2" ] || _b83Fx="$_b83Fx the toolbox holds ${n:-0} lines [$1], not $2;"; }
# path: the index's blob of path is FC's file on disk, else a fixture fault.
_b85_same() { _b83_git "$_b83C" cat-file blob ":$1" > "$_b83/sm.tmp" 2>/dev/null; cmp -s "$_b83/sm.tmp" "$_b83C/$1" || _b83Fx="$_b83Fx the index's $1 is not the disk's;"; }
# full|line want... [-- unwanted...]: the misses of the run just made: the cloud FAIL line once (with full, the
# last line gate: FAIL (cloud) and exit 1 too), every want in the detail, and no unwanted; empty when none.
_b85_miss() {
  local k="$1" w no=0 m=""
  shift
  [ "${_b83N:-0}" = 1 ] || m="$m no line [$_b83FAIL] (cloud [${_b83V:-none}]);"
  [ "$k" = line ] || [ "$_b83L" = "gate: FAIL (cloud)" ] || m="$m last line [$_b83L];"
  [ "$k" = line ] || [ "$_b83Rc" = 1 ] || m="$m exit $_b83Rc;"
  for w in "$@"; do
    if [ "$w" = -- ]; then no=1; continue; fi
    if _b83_in "$w" "$_b83D"; then [ "$no" = 0 ] || m="$m detail holds [$w];"; else [ "$no" = 1 ] || m="$m detail lacks [$w];"; fi
  done
  printf '%s' "$m"
}
# name misses: the verdict, a fixture fault first.
_b85_v() { if [ -n "$_b83Fx" ]; then bad "$1" "fixture:$_b83Fx"; elif [ -z "$2" ]; then ok "$1"; else bad "$1" "$(_b83_why "$2")"; fi; }
# path: the stages git's index holds for path, blank between.
_b85_stg() { _b83_git "$_b83C" ls-files -s -- "$1" 2>/dev/null | LC_ALL=C awk -F '\t' '{ split($1, m, " "); printf "%s%s", (NR > 1 ? " " : ""), m[3] }'; }

_b85N155="B08R3Z2 A155 (R3Z2-1): a committed .gitattributes gives .claude/cloud/provision text eol=crlf: cloud FAIL, with the eol clause naming .claude/cloud/provision"
_b85N156="B08R3Z2 A156 (R3Z2-1): a committed .gitattributes gives .claude/settings.json text eol=crlf, a JSON file section 11 exempts: cloud ok and the line under it empty, as A140 (control)"
_b85N157="B08R3Z2 A157 (R3Z2-1): a committed .gitattributes gives .CLAUDE/settings.json filter=felixtest, FC's own config core.ignorecase true: no filter clause, as Linux reads it, so cloud ok and the line under it empty, as A140"
_b85N158="B08R3Z2 A158 (R3Z2-2): toolbox.json gains a second, empty tools key before its closing brace, stack.tsv in FC: cloud FAIL, the toolbox clause for a repeated key, and no has-no-entry clause"
_b85N159="B08R3Z2 A159 (R3Z2-2): toolbox.json's last tools entry gains a trailing comma, stack.tsv in FC: cloud FAIL, the toolbox clause for not JSON, and no has-no-entry clause"
_b85N160="B08R3Z2 A160 (R3Z2-2): toolbox.json's tools is an object holding the array, stack.tsv in FC: cloud FAIL, a toolbox clause and not the not-JSON one, and no has-no-entry clause"
_b85N161="B08R3Z2 A161 (R3Z2-2): settings.json runs .claude/cloud/provision, and provision is removed from the index, kept on disk: cloud FAIL, with the provision clause"
_b85N162="B08R3Z2 A162 (R3Z2-2): .claude/cloud/provision committed at mode 100644, executable on disk: cloud FAIL, with the provision clause"
_b85N163="B08R3Z2 A163 (R3Z2-3): projects/felix/stack.tsv committed as a symlink, mode 120000, to an untracked file holding the tree's rows and one plugin row more: cloud FAIL, the stack.tsv clause, and no has-no-entry clause"
_b85N164="B08R3Z2 A164 (R3Z2-3): projects/felix/stack.tsv in a merge conflict, stages 1 to 3 in the index and no stage 0: the cloud FAIL line, the stack.tsv clause, and no has-no-entry clause"
_b85N165="B08R3Z2 A165 (R3Z-1, coverage): a committed .gitattributes gives .claude/settings.json ident: cloud FAIL, with the attribute clause naming .claude/settings.json and ident"
_b85N166="B08R3Z2 A166 (R3Z-1, coverage): .git/info/attributes, a machine-local source, gives .claude/cloud/provision filter=x: cloud FAIL, with the attribute clause naming .claude/cloud/provision and filter"
_b85N167="B08R3Z2 A167 (R3Z-3, coverage): the index holds .claude/cloud/provision spelled with U+017F for its s in place of provision, and in a second run .claude/settings.local.json spelled so: cloud FAIL with the non-ASCII clause naming that entry, each run"
_b85N168="B08R3Z2 A168 (R3Z-3): the tree's own .claude plus a committed .claude/cloud/notes-<U+017F>.md: cloud ok and the line under it empty, as A140 (control)"
_b85N169="B08R3Z2 A169 (R3Z2-5, R3Z3-4): gate.sh's whole cloud section, from its cloud banner to the next banner or the end of the file, read as text, holds no mktemp"

if [ -n "$_b84Why" ]; then
  for _b84n in "$_b84N141" "$_b84N142" "$_b84N143" "$_b84N144" "$_b84N145" "$_b84N146" "$_b84N147" \
               "$_b84N148" "$_b84N149" "$_b84N150" "$_b84N151" "$_b84N152" "$_b84N153" "$_b84N154" \
               "$_b85N155" "$_b85N156" "$_b85N157" "$_b85N158" "$_b85N159" "$_b85N160" "$_b85N161" \
               "$_b85N162" "$_b85N163" "$_b85N164" "$_b85N165" "$_b85N166" "$_b85N167" "$_b85N168"; do
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

  # ======== The fifth follow-up (contract section 12), A155 to A169
  _b83_l ztr '  ,"tools": []'; _b83_l ztc '    },'; _b83_l zto '  "tools": {"list": ['; _b83_l ztx '  ]}'
  # ---- B08R3Z2-1: a line-ending conversion outside the two JSON files (A155 to A157)
  _b84_start; _b84_cloud; _b84_ixw "$_b85IX"; _b84_ga '.claude/cloud/provision text eol=crlf'; _b83_yo a155
  _b84_ca .claude/cloud/provision eol crlf; _b84_head .gitattributes; _b85_same .claude/cloud/provision
  _b83_seq "$_b85N155" any "$(_b84_at .claude/cloud/provision eol)"
  _b84_start; _b84_cloud; _b84_ga '.claude/settings.json text eol=crlf'; _b84_add; _b83_yo a156
  _b84_ca .claude/settings.json eol crlf; _b84_head .gitattributes; _b84_ixs; _b84_ixw "$_b85IX"
  _b83_asok a156 "$_b85N156"
  _b84_start; _b84_cloud; _b85Ic="$(_b83_git "$_b83C" config --local --get core.ignorecase 2>/dev/null)"
  _b83_git "$_b83C" config --local core.ignorecase true >/dev/null 2>&1 || _b83Fx="$_b83Fx core.ignorecase could not be set;"
  _b84_ga '.CLAUDE/settings.json filter=felixtest'; _b83_yo a157; _b84_head .gitattributes; _b84_ixw "$_b85IX"
  [ "$(_b83_git "$_b83C" config --local --get core.ignorecase 2>/dev/null)" = true ] || _b83Fx="$_b83Fx FC's config lacks core.ignorecase true;"
  _b85a="$(_b83_git "$_b83C" -c core.ignorecase=true check-attr --cached filter -- .claude/settings.json 2>/dev/null)|$(_b83_git "$_b83C" -c core.ignorecase=false check-attr --cached filter -- .claude/settings.json 2>/dev/null)"
  [ "$_b85a" = ".claude/settings.json: filter: felixtest|.claude/settings.json: filter: unspecified" ] \
    || _b83Fx="$_b83Fx git check-attr --cached says [$_b85a] under core.ignorecase true|false;"
  if [ -n "$_b85Ic" ]; then _b83_git "$_b83C" config --local core.ignorecase "$_b85Ic"; else _b83_git "$_b83C" config --local --unset core.ignorecase; fi >/dev/null 2>&1
  _b85c="$(LC_ALL=C grep -cxF -e "$(printf '  %-18s %s' cloud ok)" "$_b83/a157.out" 2>/dev/null)"; _b85g=none
  ! _b83_in '(git attribute filter' "$_b83All" || _b85g=held
  if [ -n "$_b83Fx" ]; then bad "$_b85N157" "fixture:$_b83Fx"
  else _b83_is "$_b85N157" "${_b85c:-0} cloud ok lines; the line under it [$_b83D]; filter clause $_b85g" "1 cloud ok lines; the line under it []; filter clause none"; fi

  # ---- B08R3Z2-2: the toolbox parsed, and provision required (A158 to A162)
  _b84_start; _b84_cloud; _b84_stack; _b84_edp "$_b85TB" before '=}' "$_b83/l/ztr"; _b85_tn '  ,"tools": []' 1
  _b84_add "$_b85TB"; _b85_same "$_b85TB"; _b83_yo a158
  _b83_seq "$_b85N158" any "$(_b85_tc 'a key repeated in one object')" -- "$_b85NE"
  _b84_start; _b84_cloud; _b84_stack; _b85_tn '    }' 1; _b84_edp "$_b85TB" instead '=    }' "$_b83/l/ztc"; _b85_tn '    }' 0
  _b84_add "$_b85TB"; _b85_same "$_b85TB"; _b83_yo a159
  _b83_seq "$_b85N159" any "$(_b85_tc 'not JSON')" -- "$_b85NE"
  _b84_start; _b84_cloud; _b84_stack; _b84_edp "$_b85TB" instead '=  "tools": [' "$_b83/l/zto"; _b84_edp "$_b85TB" instead '=  ]' "$_b83/l/ztx"
  _b85_tn '  "tools": {"list": [' 1; _b85_tn '  ]}' 1; _b85_tn '  ]' 0; _b84_add "$_b85TB"; _b85_same "$_b85TB"; _b83_yo a160
  _b83_seq "$_b85N160" any 'unreadable: .claude/cloud/toolbox.json (' -- "$_b85NE" "$(_b85_tc 'not JSON')"
  _b84_start; _b84_cloud; _b84_ixw "$_b85IX"
  _b83_git "$_b83C" rm -q --cached -- .claude/cloud/provision >/dev/null 2>&1 || _b83Fx="$_b83Fx provision could not be removed from the index;"
  _b83_yo a161; _b84_ixw "100644 .claude/cloud/toolbox.json; 100644 .claude/settings.json"; _b83_blob
  { [ -x "$_b83C/.claude/cloud/provision" ] && [ "$(LC_ALL=C grep -cF -e '.claude/cloud/provision' "$_b83/ix.tmp" 2>/dev/null)" = 1 ]; } \
    || _b83Fx="$_b83Fx provision is not on disk, or the index's settings.json does not name it in one line;"
  _b83_seq "$_b85N161" any "$_b85PV"
  _b84_start; _b84_cloud
  _b83_git "$_b83C" update-index --chmod=-x -- .claude/cloud/provision >/dev/null 2>&1 || _b83Fx="$_b83Fx provision's mode could not be changed;"
  _b83_yo a162; _b84_ixw "100644 .claude/cloud/provision; 100644 .claude/cloud/toolbox.json; 100644 .claude/settings.json"
  _b85_same .claude/cloud/provision; [ -x "$_b83C/.claude/cloud/provision" ] || _b83Fx="$_b83Fx provision is not executable on disk;"
  _b83_seq "$_b85N162" any "$_b85PV"

  # ---- B08R3Z2-3: stack.tsv as a stage-0 regular file (A163, A164)
  _b84_start; _b84_cloud; [ -n "$_b84Row" ] || _b83Fx="$_b83Fx no anthropic-skills plugin row in this tree's stack.tsv;"
  { mkdir -p "$_b83C/cfg" && cp "$_b84ST" "$_b83C/cfg/stack.tsv" && printf '%s\n' "$_b85Xr" >> "$_b83C/cfg/stack.tsv" \
      && ln -s ../../cfg/stack.tsv "$_b83C/projects/felix/stack.tsv"; } || _b83Fx="$_b83Fx the stack.tsv symlink could not be made;"
  _b84_add projects/felix/stack.tsv; _b83_yo a163
  { [ "$(_b83_ix projects/felix/stack.tsv)" = "120000 projects/felix/stack.tsv" ] && [ -L "$_b83C/projects/felix/stack.tsv" ] && [ -z "$(_b83_ix cfg)" ] \
      && [ "$(LC_ALL=C grep -cxF -e "$_b85Xr" "$_b83C/projects/felix/stack.tsv" 2>/dev/null)" = 1 ]; } \
    || _b83Fx="$_b83Fx stack.tsv is not a symlink (120000) to an untracked file holding the extra row;"
  _b83_seq "$_b85N163" any "$_b85ST" -- "$_b85NE"
  _b84_start; _b84_cloud; _b84_stack; _b83_git "$_b83C" commit -qm a164-base >/dev/null 2>&1
  _b83_git "$_b83C" checkout -q -b b84side >/dev/null 2>&1 || _b83Fx="$_b83Fx the side branch could not be made;"
  printf '# b08r3z2 a164 side\n' >> "$_b83C/projects/felix/stack.tsv"; _b83_git "$_b83C" commit -qam a164-side >/dev/null 2>&1
  _b83_git "$_b83C" checkout -q main >/dev/null 2>&1 || _b83Fx="$_b83Fx main could not be checked out again;"
  printf '# b08r3z2 a164 main\n' >> "$_b83C/projects/felix/stack.tsv"; _b83_git "$_b83C" commit -qam a164-main >/dev/null 2>&1
  ! _b83_git "$_b83C" merge -q --no-edit b84side >/dev/null 2>&1 || _b83Fx="$_b83Fx the merge did not conflict;"
  _b85t="$(_b85_stg projects/felix/stack.tsv)"
  { [ "$_b85t" = "1 2 3" ] && [ -f "$_b83C/.git/MERGE_HEAD" ]; } || _b83Fx="$_b83Fx git ls-files -s shows stages [$_b85t] for stack.tsv, not [1 2 3], or no merge is in progress;"
  _b83_run a164
  _b85_v "$_b85N164" "$(_b85_miss line "$_b85ST" -- "$_b85NE")"
  _b83_git "$_b83C" merge --abort >/dev/null 2>&1; _b83_git "$_b83C" branch -q -D b84side >/dev/null 2>&1

  # ---- B08R3Z-1 and B08R3Z-3, the coverage section 11 left (A165 to A168)
  _b84_start; _b84_cloud; _b84_ga '.claude/settings.json ident'; _b84_add; _b83_yo a165
  _b84_ca .claude/settings.json ident set; _b84_head .gitattributes; _b84_ixs
  _b83_seq "$_b85N165" any "$(_b84_at .claude/settings.json ident)"
  _b84_start; _b84_cloud
  { mkdir -p "$_b83C/.git/info" && printf '.claude/cloud/provision filter=x\n' > "$_b83C/.git/info/attributes"; } || _b83Fx="$_b83Fx .git/info/attributes could not be written;"
  _b83_yo a166; _b84_ca .claude/cloud/provision filter x
  { [ ! -e "$_b83C/.gitattributes" ] && [ -z "$(_b83_ix .gitattributes)" ]; } || _b83Fx="$_b83Fx FC holds a .gitattributes;"
  rm -f "$_b83C/.git/info/attributes"
  _b83_seq "$_b85N166" any "$(_b84_at .claude/cloud/provision filter)"
  _b84_start; _b84_cloud; _b85h="$(_b83_git "$_b83C" hash-object -w -- .claude/cloud/provision 2>/dev/null)"
  { [ -n "$_b85h" ] && _b83_git "$_b83C" rm -q --cached -- .claude/cloud/provision >/dev/null 2>&1 \
      && _b83_git "$_b83C" update-index --add --cacheinfo "100755,$_b85h,$_b85PN" >/dev/null 2>&1; } || _b83Fx="$_b83Fx the provision entry with U+017F could not be made;"
  _b83_yo a167a; _b84_ixw "100755 $_b85PN; 100644 .claude/cloud/toolbox.json; 100644 .claude/settings.json"
  _b85m="$(_b85_miss full "$(_b84_na "$_b85PN")")"; _b85f="$_b83Fx"; _b85d="$_b83D"
  _b84_start; _b84_cloud; _b85h="$(printf '{}\n' | _b83_git "$_b83C" hash-object -w --stdin 2>/dev/null)"
  { [ -n "$_b85h" ] && _b83_git "$_b83C" update-index --add --cacheinfo "100644,$_b85h,$_b85LN" >/dev/null 2>&1; } || _b83Fx="$_b83Fx the settings.local.json entry with U+017F could not be made;"
  _b83_yo a167b; _b84_ixw "$_b85IX; 100644 $_b85LN"
  _b85m2="$(_b85_miss full "$(_b84_na "$_b85LN")")"
  if [ -n "$_b85f$_b83Fx" ]; then bad "$_b85N167" "fixture: the provision run:${_b85f:- held}; the settings.local.json run:${_b83Fx:- held}"
  elif [ -z "$_b85m$_b85m2" ]; then ok "$_b85N167"
  else bad "$_b85N167" "$(_b83_why " the provision run:${_b85m:- held} (its detail [$_b85d]); the settings.local.json run:${_b85m2:- held};")"; fi
  _b84_start; _b84_cloud; { printf 'notes\n' > "$_b83C/$_b85NN"; } || _b83Fx="$_b83Fx the U+017F notes file could not be written;"
  _b84_add "$_b85NN"; _b83_yo a168
  _b84_ixw "100644 $_b85NN; 100755 .claude/cloud/provision; 100644 .claude/cloud/toolbox.json; 100644 .claude/settings.json"
  _b83_asok a168 "$_b85N168"
fi

# ---- B08R3Z2-5, widened by B08R3Z3-4: no mktemp in the cloud section (A169), read from this tree's gate.sh without FC.
_b85G="$REAL_HARNESS/../../projects/felix/gate.sh"
if [ ! -f "$_b85G" ]; then skip "$_b85N169" "no projects/felix/gate.sh beside this engine"
else
  _b85r="$(LC_ALL=C awk '/^# -+ [a-z0-9-]+ -+$/ { if (s && !e) e = NR; if (!s && $3 == "cloud") s = NR }
    s && !e && index($0, "mktemp") { t = t " " NR }
    END { if (s && !e) e = NR + 1; printf "%d %d%s", s, (s ? e - 1 : 0), t }' "$_b85G" 2>/dev/null)"
  read -r _b85s _b85e _b85m <<B85R
$_b85r
B85R
  if [ "${_b85s:-0}" = 0 ]; then bad "$_b85N169" "fixture: no cloud banner found in gate.sh (${_b85r:-no output})"
  else is "$_b85N169" "lines $_b85s to $_b85e hold mktemp on lines [${_b85m:-}]" "lines $_b85s to $_b85e hold mktemp on lines []"; fi
fi
