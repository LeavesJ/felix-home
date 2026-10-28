printf '\nthe cloud check judges the chain the cloud runs (audit b08 round 3, section 13, blind)\n'
# Written blind on 2026-10-28 from section 13 of docs/2026-10-24-audit-fixes/b08-round-3.md
# (B08R3Z3-1 to B08R3Z3-4, A170 to A187), with its sections 2 to 12 as context, without
# reading projects/felix/gate.sh's cloud check, engine/ code or anything the gate sources. One
# assertion per item, named "B08R3Z3 A<n> (R3Z3-<m>...): ...". Part 1772 would pass 500 lines
# with them, so they are a part of their own, sourced right after 1772, over 1771's FC with
# 1771's and 1772's helpers (_b84_start, _b84_cloud, _b84_edp, _b85_tn, _b83_yo, _b83_seq,
# _b83_asok and the rest). A169, widened by B08R3Z3-4, stays in 1772.
# - When 1772's helpers are not in this shell (this part alone, or a unit of its own under
#   tests/run -j N), this part reads them from 1772's text (every line after its first, up to
#   its first case block), which reads 1771's the same way and builds FC; when that fails,
#   each case skips and says why.
# Readings taken where the text leaves room:
# - Each case starts from _b84_start and, unless it says otherwise, _b84_cloud: the tree's
#   settings.json, toolbox.json and provision (100755) staged, and no stack.tsv. Section 13's
#   fixture names the toolbox and provision, not stack.tsv, so the shape cases (A181 to A186)
#   hold none: the toolbox is judged for itself.
# - Each settings variant is the tree's settings.json run through one awk program (_b86HK),
#   which first checks that the provision hook object is the seven lines around the one
#   command line naming .claude/cloud/provision, after its sibling's "},", as this tree has it;
#   a variant that cannot be made is a fixture fault, never the rule. Each case then checks
#   with grep -cxF the lines it names, and that the index holds .claude as A140's does.
# - "The binding clause" is B08R3Z3-1's clause for settings.json, matched without its leading
#   blank. With a count (A170 and A171 `0`, A175 `2`) it is matched exactly; without one (A172
#   to A174) any count written in digits is taken.
# - A171's command is the text section 13 gives, unguarded as given; a guard-count clause
#   beside the binding clause is neither required nor refused.
# - A172's "new SessionStart entry" is a second group in the SessionStart array, its matcher
#   startup, holding the provision hook object alone; the first group keeps session-start.
# - A176 reorders all five keys: timeout, async, command, shell, type.
# - A177: .claude/cloud and stack.tsv are committed, then removed from the index and the disk
#   by git rm, and the hook deleted, so nothing of them is left for the cloud. "cloud ok" is
#   the cloud line's verdict, as A82 reads it.
# - "The provision clause" names .claude/cloud/provision once (B08R3Z3-2's "the first of
#   these"), with the reason the case gives. A178's CR bytes go in by awk from a CR made by
#   printf, the add runs with core.autocrlf false, and od counts one CR a line in the index
#   blob; FC holds no .gitattributes. A179's entry is git add -N after provision was removed
#   and committed; the gate runs over the index as it stands, since a commit takes nothing.
# - "The shape clause" is B08R3Z3-3's, matched without its leading blank. A181's note is
#   superpowers' (an array of two strings); A183's url goes into superpowers' entry and A185's
#   sha comes out of it, a fetch entry; A184's and A186's entry is code-review, whose carry is
#   builtin. "As A140": cloud ok and the line under it empty (_b83_asok).

_b86Why=""
if [ "$(type -t _b84_start)" != function ] || [ "$(type -t _b85_tn)" != function ]; then
  B86_L='if [ -n "$_b84Why" ]; then' LC_ALL=C awk 'NR > 1 && $0 == ENVIRON["B86_L"] { exit } NR > 1 { print }' \
    "$HERE/parts/1772-b08-round-3-checkout-blind.sh" > "$TMP/b86-1772.sh" 2>/dev/null && . "$TMP/b86-1772.sh"
fi
if [ "$(type -t _b84_start)" != function ] || [ "$(type -t _b85_tn)" != function ]; then _b86Why="part 1772's helpers are not in this shell and could not be read from its text"
elif [ -n "${_b84Why:-}" ]; then _b86Why="$_b84Why"
elif [ -z "${_b83C:-}" ] || [ ! -d "$_b83C/.git" ]; then _b86Why="part 1771's FC is not there"; fi

# Section 13's clauses, and the lines its cases name.
_b86_bc() { printf 'unreadable: .claude/settings.json (%s SessionStart hooks run provision as gate.sh binds it, not 1);' "$1"; }
_b86_pv() { printf 'unreadable: .claude/cloud/provision (%s);' "$1"; }
_b86SH='unreadable: .claude/cloud/toolbox.json (not the toolbox shape provision reads);'
_b86PV='.claude/cloud/provision'; _b86E0='e69de29bb2d1d6434b8b29ae775ad8c2e48c5391'
_b86PL="$(LC_ALL=C awk 'index($0, "\"command\"") && index($0, "/.claude/cloud/provision") { print; exit }' "${_b83S:-/dev/null}" 2>/dev/null)"
_b86CD='            "command": "cd \"$CLAUDE_PROJECT_DIR/.claude/cloud\" && exec ./provision --session-start",'
_b86Sha="$(LC_ALL=C grep -cF -e '"sha": ' "${_b83T:-/dev/null}/cloud/toolbox.json" 2>/dev/null)"
_b86Nl="$(LC_ALL=C awk 'END { print NR }' "${_b83T:-/dev/null}/cloud/provision" 2>/dev/null)"
# The tree's settings with its provision hook object (lines p-2 to p+4 around its command line p,
# after the sibling's "}," at p-3) changed as B86_M says; status 3 when the object is not as read.
_b86HK='{ l[NR] = $0 } !p && index($0, "\"command\"") && index($0, "/.claude/cloud/provision") { p = NR }
  END { m = ENVIRON["B86_M"]
    if (!p || l[p - 3] != "          }," || l[p - 2] != "          {" || l[p - 1] != "            \"type\": \"command\"," \
        || l[p + 1] != "            \"shell\": \"bash\"," || l[p + 2] != "            \"async\": false," \
        || l[p + 3] != "            \"timeout\": 120" || l[p + 4] != "          }") exit 3
    for (i = 1; i <= NR; i++) {
      if (m == "del" && i == p - 3) { print "          }"; continue }
      if (m == "del" && i >= p - 2 && i <= p + 4) continue
      if (m == "cmd" && i == p) { print ENVIRON["B86_X"]; continue }
      if (m == "move" && i == p - 3) { print "          }"; print "        ]"; print "      },"; print "      {"
        print "        \"matcher\": \"startup\","; print "        \"hooks\": ["; continue }
      if (m == "async" && i == p + 2) { print "            \"async\": true,"; continue }
      if (m == "notime" && i == p + 2) { print "            \"async\": false"; continue }
      if (m == "notime" && i == p + 3) continue
      if (m == "dup" && i == p + 4) { print "          },"; for (j = p - 2; j <= p + 4; j++) print l[j]; continue }
      if (m == "order" && i == p - 1) { print "            \"timeout\": 120,"; print "            \"async\": false,"; print l[p]
        print "            \"shell\": \"bash\","; print "            \"type\": \"command\""; continue }
      if (m == "order" && i >= p && i <= p + 3) continue
      print l[i] } }'
# mode [line]: FC's settings.json made the tree's variant, else a fixture fault.
_b86_set() {
  if B86_M="$1" B86_X="${2:-}" LC_ALL=C awk "$_b86HK" "$_b83S" > "$_b83/ed.tmp" && ! cmp -s "$_b83S" "$_b83/ed.tmp"; then
    cat "$_b83/ed.tmp" > "$_b83CS"
  else _b83Fx="$_b83Fx the settings variant $1 could not be made;"; fi
}
# A miss for _b83_seq unless the detail holds the binding clause with a count written in digits.
_b86_bany() {
  B83_S="$_b83D" B83_W='unreadable: .claude/settings.json (' B83_T=' SessionStart hooks run provision as gate.sh binds it, not 1);' \
    LC_ALL=C awk 'BEGIN { s = ENVIRON["B83_S"]; w = ENVIRON["B83_W"]; t = ENVIRON["B83_T"]
      while ((i = index(s, w)) > 0) { s = substr(s, i + length(w)); j = index(s, t); if (j > 1 && substr(s, 1, j - 1) ~ /^[0-9]+$/) exit 0 }
      exit 1 }' || _b83Xm="$_b83Xm the detail lacks [$(_b86_bc '<digits>')];"
}
# want: git ls-files -s shows provision's entry as "<mode> <sha> <stage>" want, else a fixture fault.
_b86_pe() {
  local s
  s="$(_b83_git "$_b83C" ls-files -s -- "$_b86PV" 2>/dev/null | LC_ALL=C awk -F '\t' '{ printf "%s%s", (NR > 1 ? "; " : ""), $1 }')"
  [ "$s" = "$1" ] || _b83Fx="$_b83Fx git ls-files -s shows provision as [$s], not [$1];"
}
# awk program: FC's toolbox run through it, else a fixture fault.
_b86_tbx() {
  local f="$_b83C/$_b85TB"
  if LC_ALL=C awk "$1" "$f" > "$_b83/ed.tmp" && ! cmp -s "$f" "$_b83/ed.tmp"; then cat "$_b83/ed.tmp" > "$f"
  else _b83Fx="$_b83Fx the toolbox edit changed nothing;"; fi
}
# n: FC's toolbox holds n lines holding "sha": , else a fixture fault.
_b86_sh() { local n; n="$(LC_ALL=C grep -cF -e '"sha": ' "$_b83C/$_b85TB" 2>/dev/null)"; [ "${n:-0}" = "$1" ] || _b83Fx="$_b83Fx the toolbox holds ${n:-0} sha lines, not $1;"; }

_b86N170="B08R3Z3 A170 (R3Z3-1): the provision hook object deleted from settings.json, the toolbox and provision in the index: cloud FAIL, with the binding clause counting 0"
_b86N171="B08R3Z3 A171 (R3Z3-1): the provision hook's command spelled as a cd into .claude/cloud then exec ./provision --session-start, without the literal path: cloud FAIL, with the binding clause counting 0"
_b86N172="B08R3Z3 A172 (R3Z3-1): the provision hook object moved into a new SessionStart entry whose matcher is startup: cloud FAIL, with the binding clause"
_b86N173="B08R3Z3 A173 (R3Z3-1): the provision hook's async set to true: cloud FAIL, with the binding clause"
_b86N174="B08R3Z3 A174 (R3Z3-1): the provision hook's timeout removed: cloud FAIL, with the binding clause"
_b86N175="B08R3Z3 A175 (R3Z3-1): the provision hook object duplicated in its entry: cloud FAIL, with the binding clause counting 2"
_b86N176="B08R3Z3 A176 (R3Z3-1): the provision hook object's five keys reordered: cloud ok and the line under it empty, as A140 (control)"
_b86N177="B08R3Z3 A177 (R3Z3-1): .claude/cloud and projects/felix/stack.tsv removed from the index after a commit, and the provision hook deleted: cloud ok (control)"
_b86N178="B08R3Z3 A178 (R3Z3-2): provision committed at 100755 with CRLF line ends and no attribute: cloud FAIL, with the provision clause for a CR byte, provision named once"
_b86N179="B08R3Z3 A179 (R3Z3-2): provision removed and committed, then git add -N for it, an intent-to-add entry: cloud FAIL, with the provision clause empty in git's index, provision named once"
_b86N180="B08R3Z3 A180 (R3Z3-2): an empty provision committed at 100755: cloud FAIL, with the provision clause empty in git's index, provision named once"
_b86N181="B08R3Z3 A181 (R3Z3-3): one tools entry's note made an array of strings: cloud FAIL, with the shape clause"
_b86N182="B08R3Z3 A182 (R3Z3-3): the toolbox gains a top-level key depth holding an array inside an array: cloud FAIL, with the shape clause"
_b86N183="B08R3Z3 A183 (R3Z3-3): one tools entry gains a url key: cloud FAIL, with the shape clause"
_b86N184="B08R3Z3 A184 (R3Z3-3): one entry's carry set to maybe: cloud FAIL, with the shape clause"
_b86N185="B08R3Z3 A185 (R3Z3-3): one fetch entry without its sha: cloud FAIL, with the shape clause"
_b86N186="B08R3Z3 A186 (R3Z3-3): one entry without its carry: cloud FAIL, with the shape clause"
_b86N187="B08R3Z3 A187 (R3Z3-3): the toolbox's about key removed: cloud ok and the line under it empty, as A140 (control)"

if [ -n "$_b86Why" ]; then
  for _b86n in "$_b86N170" "$_b86N171" "$_b86N172" "$_b86N173" "$_b86N174" "$_b86N175" "$_b86N176" "$_b86N177" "$_b86N178" \
               "$_b86N179" "$_b86N180" "$_b86N181" "$_b86N182" "$_b86N183" "$_b86N184" "$_b86N185" "$_b86N186" "$_b86N187"; do
    skip "$_b86n" "$_b86Why"
  done
else
  [ -n "$_b86PL" ] || _b83MkFx="$_b83MkFx no command line naming .claude/cloud/provision in the tree's settings.json;"
  _b83_l zn1 '      "note": ["skills", "the session-start context"]'
  _b83_l zdp '  "depth": [[1]],'
  _b83_l zur '      "url": "x",'
  _b83_l zmb '      "carry": "maybe",'

  # ---- B08R3Z3-1: one canonical provision hook (A170 to A177)
  _b84_start; _b84_cloud; _b86_set del; _b83_cnt settings "$_b86PL" 0; _b84_add; _b83_yo a170; _b84_ixw "$_b85IX"
  _b83_seq "$_b86N170" any "$(_b86_bc 0)"
  _b84_start; _b84_cloud; _b86_set cmd "$_b86CD"; _b83_has settings "$_b86CD"; _b83_cnt settings "$_b86PL" 0
  _b84_add; _b83_yo a171; _b84_ixw "$_b85IX"
  _b83_seq "$_b86N171" any "$(_b86_bc 0)"
  _b84_start; _b84_cloud; _b86_set move; _b83_has settings '        "matcher": "startup",'; _b83_cnt settings "$_b86PL" 1
  _b83_has settings '        "matcher": "startup|resume|clear|compact",'; _b84_add; _b83_yo a172; _b84_ixw "$_b85IX"
  _b86_bany; _b83_seq "$_b86N172" any
  _b84_start; _b84_cloud; _b86_set async; _b83_has settings '            "async": true,'; _b83_cnt settings "$_b86PL" 1
  _b84_add; _b83_yo a173; _b84_ixw "$_b85IX"
  _b86_bany; _b83_seq "$_b86N173" any
  _b84_start; _b84_cloud; _b86_set notime; _b83_cnt settings '            "timeout": 120' 0; _b83_cnt settings "$_b86PL" 1
  _b84_add; _b83_yo a174; _b84_ixw "$_b85IX"
  _b86_bany; _b83_seq "$_b86N174" any
  _b84_start; _b84_cloud; _b86_set dup; _b83_cnt settings "$_b86PL" 2; _b83_cnt settings '            "timeout": 120' 2
  _b84_add; _b83_yo a175; _b84_ixw "$_b85IX"
  _b83_seq "$_b86N175" any "$(_b86_bc 2)"
  _b84_start; _b84_cloud; _b86_set order; _b83_has settings '            "timeout": 120,'; _b83_has settings '            "type": "command"'
  _b83_cnt settings "$_b86PL" 1; _b84_add; _b83_yo a176; _b84_ixw "$_b85IX"
  _b83_asok a176 "$_b86N176"
  _b84_start; _b84_cloud; _b84_stack; _b83_git "$_b83C" commit -qm a177-base >/dev/null 2>&1
  _b83_git "$_b83C" rm -r -q -- .claude/cloud projects/felix/stack.tsv >/dev/null 2>&1 || _b83Fx="$_b83Fx .claude/cloud and stack.tsv could not be removed;"
  _b86_set del; _b83_cnt settings "$_b86PL" 0; _b84_add; _b83_yo a177; _b84_ixw '100644 .claude/settings.json'
  { [ -z "$(_b83_ix projects/felix/stack.tsv)" ] && [ ! -e "$_b83C/.claude/cloud" ] && [ ! -e "$_b83C/projects/felix/stack.tsv" ] \
      && [ -z "$(_b83_git "$_b83C" ls-tree -r --name-only HEAD -- .claude/cloud projects/felix/stack.tsv 2>/dev/null)" ]; } \
    || _b83Fx="$_b83Fx .claude/cloud or stack.tsv is still in the index, on disk or in HEAD;"
  _b83_ok "$_b86N177"

  # ---- B08R3Z3-2: provision's bytes (A178 to A180)
  _b84_start; _b84_cloud
  { B86_R="$(printf '\r')" LC_ALL=C awk '{ printf "%s%s\n", $0, ENVIRON["B86_R"] }' "$_b83T/cloud/provision" > "$_b83C/$_b86PV" \
      && _b83_git "$_b83C" -c core.autocrlf=false add -- "$_b86PV" >/dev/null 2>&1; } || _b83Fx="$_b83Fx provision could not be written with CRLF and staged;"
  _b83_yo a178; _b84_ixw "$_b85IX"; _b84_head "$_b86PV"; _b85_same "$_b86PV"
  _b83_git "$_b83C" cat-file blob ":$_b86PV" > "$_b83/pv.tmp" 2>/dev/null
  _b86c="$(LC_ALL=C od -An -v -tx1 "$_b83/pv.tmp" 2>/dev/null | LC_ALL=C awk '{ for (i = 1; i <= NF; i++) if ($i == "0d") n++ } END { print n + 0 }')"
  { [ -n "$_b86Nl" ] && [ "$_b86Nl" -gt 0 ] && [ "$_b86c" = "$_b86Nl" ]; } || _b83Fx="$_b83Fx the index blob of provision holds ${_b86c:-?} CR bytes, not one for each of its ${_b86Nl:-?} lines;"
  { [ ! -e "$_b83C/.gitattributes" ] && [ -z "$(_b83_ix .gitattributes)" ]; } || _b83Fx="$_b83Fx FC holds a .gitattributes;"
  _b84_ca "$_b86PV" eol unspecified; _b84_ca "$_b86PV" text unspecified
  _b83_once "$_b86PV"; _b83_seq "$_b86N178" any "$(_b86_pv "a CR byte in git's index blob")"
  _b84_start; _b84_cloud; _b83_git "$_b83C" commit -qm a179-base >/dev/null 2>&1
  _b83_git "$_b83C" rm -q --cached -- "$_b86PV" >/dev/null 2>&1 || _b83Fx="$_b83Fx provision could not be removed from the index;"
  _b83_git "$_b83C" commit -qm a179-rm >/dev/null 2>&1
  _b83_git "$_b83C" add -N -- "$_b86PV" >/dev/null 2>&1 || _b83Fx="$_b83Fx git add -N of provision failed;"
  _b83_run a179; _b86_pe "100755 $_b86E0 0"
  [ -z "$(_b83_git "$_b83C" ls-tree --name-only HEAD -- "$_b86PV" 2>/dev/null)" ] || _b83Fx="$_b83Fx HEAD still holds provision;"
  { [ -x "$_b83C/$_b86PV" ] && cmp -s "$_b83T/cloud/provision" "$_b83C/$_b86PV"; } || _b83Fx="$_b83Fx the disk's provision is not the tree's, executable;"
  _b83_once "$_b86PV"; _b83_seq "$_b86N179" any "$(_b86_pv "empty in git's index")"
  _b84_start; _b84_cloud; : > "$_b83C/$_b86PV"; _b84_add "$_b86PV"; _b83_yo a180
  _b86_pe "100755 $_b86E0 0"; _b84_head "$_b86PV"; [ -x "$_b83C/$_b86PV" ] || _b83Fx="$_b83Fx provision is not executable on disk;"
  _b83_once "$_b86PV"; _b83_seq "$_b86N180" any "$(_b86_pv "empty in git's index")"

  # ---- B08R3Z3-3: the toolbox shape provision's reader accepts (A181 to A187)
  _b84_start; _b84_cloud; _b84_edp "$_b85TB" instead '~"note": "skills, and the session-start context' "$_b83/l/zn1"
  _b85_tn "$(cat "$_b83/l/zn1")" 1; _b84_add "$_b85TB"; _b85_same "$_b85TB"; _b83_yo a181; _b84_ixw "$_b85IX"
  _b83_seq "$_b86N181" any "$_b86SH"
  _b84_start; _b84_cloud; _b84_edp "$_b85TB" after '={' "$_b83/l/zdp"; _b85_tn '  "depth": [[1]],' 1
  _b84_add "$_b85TB"; _b85_same "$_b85TB"; _b83_yo a182; _b84_ixw "$_b85IX"
  _b83_seq "$_b86N182" any "$_b86SH"
  _b84_start; _b84_cloud; _b84_edp "$_b85TB" before '=      "name": "superpowers",' "$_b83/l/zur"; _b85_tn '      "url": "x",' 1
  _b84_add "$_b85TB"; _b85_same "$_b85TB"; _b83_yo a183; _b84_ixw "$_b85IX"
  _b83_seq "$_b86N183" any "$_b86SH"
  _b84_start; _b84_cloud; _b84_edp "$_b85TB" instead '=      "carry": "builtin",' "$_b83/l/zmb"; _b85_tn '      "carry": "maybe",' 1
  _b85_tn '      "carry": "builtin",' 0; _b84_add "$_b85TB"; _b85_same "$_b85TB"; _b83_yo a184; _b84_ixw "$_b85IX"
  _b83_seq "$_b86N184" any "$_b86SH"
  _b84_start; _b84_cloud; _b84_edp "$_b85TB" instead '~"sha": ' "$_b83/l/none"; _b86_sh "$(( ${_b86Sha:-0} - 1 ))"
  _b85_tn '      "source": "obra/superpowers",' 1; _b84_add "$_b85TB"; _b85_same "$_b85TB"; _b83_yo a185; _b84_ixw "$_b85IX"
  _b83_seq "$_b86N185" any "$_b86SH"
  _b84_start; _b84_cloud; _b84_edp "$_b85TB" instead '=      "carry": "builtin",' "$_b83/l/none"; _b85_tn '      "carry": "builtin",' 0
  _b85_tn '      "name": "code-review",' 1; _b84_add "$_b85TB"; _b85_same "$_b85TB"; _b83_yo a186; _b84_ixw "$_b85IX"
  _b83_seq "$_b86N186" any "$_b86SH"
  _b84_start; _b84_cloud
  _b86_tbx '!d && $0 == "  \"about\": [" { d = 1; next } d == 1 { if ($0 == "  ],") d = 2; next } { print } END { if (d != 2) exit 3 }'
  _b85_tn '  "about": [' 0; _b85_tn '  "tools": [' 1; _b84_add "$_b85TB"; _b85_same "$_b85TB"; _b83_yo a187; _b84_ixw "$_b85IX"
  _b83_asok a187 "$_b86N187"
fi
