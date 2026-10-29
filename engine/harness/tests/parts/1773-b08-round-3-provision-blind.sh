printf '\nthe cloud check judges the chain the cloud runs (audit b08 round 3, sections 13 to 15, blind)\n'
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
#   blank, with its count exactly: A170 to A174 `0` (A172 to A174 since section 14, R3Z4-5,
#   which narrowed their checks in that alone), A175 `2`.
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
#
# Section 14 (B08R3Z4-1 to B08R3Z4-5, A188 to A199) was written blind on 2026-10-28 from the same
# file, after A187, without reading gate.sh's cloud check. Its names start "B08R3Z4 A<n>". Readings:
# - Each case starts from _b84_start, _b84_cloud and _b84_stack: the tree's settings.json,
#   toolbox.json, provision (100755) and stack.tsv staged, as "each case runs over FC with the
#   tree's stack.tsv unless it says otherwise" reads.
# - A188's settings.json is removed by git rm, from the index and the disk, so the case's commit
#   leaves HEAD without it too; "no skipped" reads as A127's. A189 commits FC, then git rm takes
#   settings.json, .claude/cloud and stack.tsv; `skipped` is the line A128 pins.
# - A190's fetch entry is superpowers' (subdir "."); A191's entry is security-guidance's.
# - A192's entry goes first in tools, on a line of its own, as section 14 writes it. Section 14's
#   new clauses are matched without their leading blank.
# - A193's semgrep entry has its carry no line replaced by carry fetch, a source, a 40-hex sha and
#   subdir ".", before its note. A194 also rates stack.tsv's semgrep row low in the index. Its "no
#   risk clause" reads as A147's "no guard clause": none in the output, and cloud ok with the line
#   under it empty, as A140, since nothing else in its tree departs from the tree's.
# - A195's copy is the tree's seven-line provision hook object, put after the user-prompt hook
#   object in UserPromptSubmit's one group. SessionStart keeps its own, so only the outside clause
#   is required.
# - A196's NUL goes in by printf after provision's last byte; od reads the index blob: one NUL, as
#   its last byte, and no CR.
#
# Section 15 (B08R3Z5-1, B08R3Z5-2, A200 to A206) was written blind on 2026-10-28 from the same
# file, after A199, without reading gate.sh's cloud check. Its names start "B08R3Z5 A<n>". Readings:
# - Each case starts from _b84_start, _b84_cloud and _b84_stack, as section 14's do. Its clauses
#   are matched without their leading blank.
# - A200 to A202 rate stack.tsv's superpowers plugin row (its fourth field) High, hgh or medium in
#   the index; the toolbox stays the tree's, superpowers' carry fetch.
# - A203, A205 and A206 each add one one-line hook object to UserPromptSubmit's one group, after
#   the user-prompt hook: type command, the command with the tree's guard prefix first, shell bash,
#   async false. So the guard clause is refused there. A204's is the tree's seven-line provision
#   hook object with timeout 30, after the canonical one in its group; "the binding count stays 1"
#   reads as no binding clause, whatever its count.
# - A202 and A206, "as A140", read as _b83_asok.

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
  !q && index($0, "harness/hooks/user-prompt") { q = NR }
  END { m = ENVIRON["B86_M"]
    if (!p || l[p - 3] != "          }," || l[p - 2] != "          {" || l[p - 1] != "            \"type\": \"command\"," \
        || l[p + 1] != "            \"shell\": \"bash\"," || l[p + 2] != "            \"async\": false," \
        || l[p + 3] != "            \"timeout\": 120" || l[p + 4] != "          }") exit 3
    if (m == "upc" || m == "upo") { for (j = q + 1; q && !u && j <= NR; j++) if (l[j] == "          }") u = j; if (!u) exit 3 }
    for (i = 1; i <= NR; i++) {
      if (m == "upc" && i == u) { print "          },"; for (j = p - 2; j <= p + 4; j++) print l[j]; continue }
      if (m == "upo" && i == u) { print "          },"; print ENVIRON["B86_X"]; continue }
      if (m == "t30" && i == p + 4) { print "          },"; for (j = p - 2; j <= p + 2; j++) print l[j]
        print "            \"timeout\": 30"; print l[p + 4]; continue }
      if (m == "sm" && i == p + 3) { print "            \"timeout\": 120,"; print "            \"statusMessage\": \"x\""; continue }
      if (m == "nosh" && i == p + 1) continue
      if (m == "t60" && i == p + 3) { print "            \"timeout\": 60"; continue }
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
_b86N172="B08R3Z3 A172 (R3Z3-1, R3Z4-5): the provision hook object moved into a new SessionStart entry whose matcher is startup: cloud FAIL, with the binding clause counting 0"
_b86N173="B08R3Z3 A173 (R3Z3-1, R3Z4-5): the provision hook's async set to true: cloud FAIL, with the binding clause counting 0"
_b86N174="B08R3Z3 A174 (R3Z3-1, R3Z4-5): the provision hook's timeout removed: cloud FAIL, with the binding clause counting 0"
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

# Section 14's clauses, its lines, and its helpers.
_b87OUT='unreadable: .claude/settings.json (1 copies of the provision hook outside SessionStart startup|resume|clear|compact);'
_b87NS='undeclared-x is in .claude/cloud/toolbox.json and not in projects/felix/stack.tsv;'
_b87RK='semgrep is fetched into the cloud and stack.tsv rates it risk=high;'
_b87UX='    {"name":"undeclared-x","carry":"no","note":"x"},'; _b87SG='      "name": "semgrep",'
_b87Sd="$(LC_ALL=C grep -cxF -e '      "subdir": ".",' "${_b83T:-/dev/null}/cloud/toolbox.json" 2>/dev/null)"
_b87Pz="$(LC_ALL=C wc -c < "${_b83T:-/dev/null}/cloud/provision" 2>/dev/null | LC_ALL=C tr -d ' ')"
# stack.tsv in FC's index as one 100644 entry, else a fixture fault.
_b87_st() { local s; s="$(_b83_ix projects/felix/stack.tsv)"; [ "$s" = "100644 projects/felix/stack.tsv" ] || _b83Fx="$_b83Fx git ls-files -s shows [$s] for stack.tsv;"; }
# The risk column of the semgrep plugin rows in the index's stack.tsv, blank between.
_b87_rk() { _b83_git "$_b83C" cat-file blob :projects/felix/stack.tsv 2>/dev/null | LC_ALL=C awk -F '\t' '$1 == "plugin" && index($2, "semgrep@") == 1 { printf "%s%s", (n++ ? " " : ""), $4 }'; }
# FC's toolbox's semgrep entry made a fetch, qsf's four lines in place of its carry no, else a fixture fault.
_b87_sg() {
  local f="$_b83C/$_b85TB"
  if env B83_M=instead B83_C="$_b87SG" B83_A='=      "carry": "no",' B83_I="$_b83/l/qsf" LC_ALL=C awk "$_b83ED" "$f" > "$_b83/ed.tmp" \
      && ! cmp -s "$f" "$_b83/ed.tmp"; then cat "$_b83/ed.tmp" > "$f"
  else _b83Fx="$_b83Fx the semgrep entry could not be made a fetch;"; fi
  B87_N="$_b87SG" LC_ALL=C awk 'p && n < 4 { print; n++ } $0 == ENVIRON["B87_N"] { p = 1 }' "$f" > "$_b83/sg.tmp" 2>/dev/null
  cmp -s "$_b83/sg.tmp" "$_b83/l/qsf" || _b83Fx="$_b83Fx the four lines after the semgrep name are not the fetch lines;"
}
# file: "<NUL bytes> <CR bytes> <last byte>" as od reads it.
_b87_ox() { LC_ALL=C od -An -v -tx1 "$1" 2>/dev/null | LC_ALL=C awk '{ for (i = 1; i <= NF; i++) { if ($i == "00") z++; if ($i == "0d") r++; b = $i } } END { printf "%d %d %s", z, r, b }'; }
# The line after FC's settings' provision command line.
_b87_nx() { B87_P="$_b86PL" LC_ALL=C awk 'p { print; exit } $0 == ENVIRON["B87_P"] { p = 1 }' "$_b83CS" 2>/dev/null; }

_b87N188="B08R3Z4 A188 (R3Z4-1): settings.json removed from the index and the disk, the toolbox, provision and stack.tsv kept in the index: cloud FAIL, with the binding clause counting 0, and no skipped"
_b87N189="B08R3Z4 A189 (R3Z4-1): settings.json, .claude/cloud and stack.tsv all removed from the index and the disk: the skipped line A128 pins (control)"
_b87N190="B08R3Z4 A190 (R3Z4-2): one fetch entry's subdir, superpowers', set to the empty string, stack.tsv in FC: cloud FAIL, with the shape clause"
_b87N191="B08R3Z4 A191 (R3Z4-2): one entry's note, security-guidance's, set to the empty string, stack.tsv in FC: cloud FAIL, with the shape clause"
_b87N192="B08R3Z4 A192 (R3Z4-3): the toolbox gains a tools entry undeclared-x, carry no, that no stack.tsv row names: cloud FAIL, with the not-in-stack clause naming undeclared-x"
_b87N193="B08R3Z4 A193 (R3Z4-3): the toolbox's semgrep entry made carry fetch with a source, a 40-hex sha and subdir dot, stack.tsv's semgrep row kept at risk high: cloud FAIL, with the risk clause naming semgrep"
_b87N194="B08R3Z4 A194 (R3Z4-3): the same semgrep fetch entry with stack.tsv's semgrep row rated low: no risk clause, and cloud ok with the line under it empty, as A140 (control)"
_b87N195="B08R3Z4 A195 (R3Z4-4): the canonical provision hook object also appended to UserPromptSubmit's hooks: cloud FAIL, with the outside clause counting 1"
_b87N196="B08R3Z4 A196 (R3Z3-2, R3Z4-5, coverage): one NUL byte appended to provision, at 100755: cloud FAIL, with the provision clause for a NUL byte, provision named once"
_b87N197="B08R3Z4 A197 (R3Z3-1, R3Z4-5, coverage): the provision hook gains a sixth key, statusMessage x: cloud FAIL, with the binding clause counting 0"
_b87N198="B08R3Z4 A198 (R3Z3-1, R3Z4-5, coverage): the provision hook's shell removed: cloud FAIL, with the binding clause counting 0"
_b87N199="B08R3Z4 A199 (R3Z3-1, R3Z4-5, coverage): the provision hook's timeout set to 60: cloud FAIL, with the binding clause counting 0"

# Section 15's clauses, its lines, and its helpers.
_b88_nr() { printf '%s' "$1 is fetched into the cloud and stack.tsv's risk for it is not low, medium or high;"; }
_b88_oh() { printf 'unreadable: .claude/settings.json (%s other hooks name provision);' "$1"; }
_b88BT='SessionStart hooks run provision as gate.sh binds it, not 1);'
# command: a one-line hook object running the tree's guard prefix, then command.
_b88_one() { printf '          { "type": "command", "command": "%s%s", "shell": "bash", "async": false }' '[ \"$CLAUDE_CODE_REMOTE\" = true ] || exit 0; ' "$1"; }
_b88P3="$(_b88_one 'bash \"$CLAUDE_PROJECT_DIR/.claude/cloud/provision\"')"
_b88P5="$(_b88_one 'echo provisional')"; _b88P6="$(_b88_one 'echo hello')"
# risk: FC's stack.tsv's superpowers plugin row given that risk (field 4) and staged, else a fixture fault.
_b88_rate() {
  { B88_R="$1" LC_ALL=C awk -F '\t' 'BEGIN { OFS = "\t" } $1 == "plugin" && index($2, "superpowers@") == 1 { $4 = ENVIRON["B88_R"]; n++ } { print } END { if (n != 1) exit 3 }' \
      "$_b83C/projects/felix/stack.tsv" > "$_b83/ed.tmp" && cat "$_b83/ed.tmp" > "$_b83C/projects/felix/stack.tsv"; } \
    || _b83Fx="$_b83Fx stack.tsv's superpowers row could not be rated $1;"
  _b84_add projects/felix/stack.tsv
}
# The risk column of the superpowers plugin rows in the index's stack.tsv, blank between.
_b88_rk() { _b83_git "$_b83C" cat-file blob :projects/felix/stack.tsv 2>/dev/null | LC_ALL=C awk -F '\t' '$1 == "plugin" && index($2, "superpowers@") == 1 { printf "%s%s", (n++ ? " " : ""), $4 }'; }
# The line after the superpowers name line in the index's toolbox.
_b88_sc() { _b83_git "$_b83C" cat-file blob ":$_b85TB" 2>/dev/null | LC_ALL=C awk 'p && !d { print; d = 1 } $0 == "      \"name\": \"superpowers\"," { p = 1 }'; }
# risk: the index rates superpowers risk and keeps its toolbox entry carry fetch, else a fixture fault.
_b88_sp() {
  [ "$(_b88_rk)" = "$1" ] || _b83Fx="$_b83Fx the index's stack.tsv rates superpowers [$(_b88_rk)], not [$1];"
  [ "$(_b88_sc)" = '      "carry": "fetch",' ] || _b83Fx="$_b83Fx the index's toolbox gives superpowers [$(_b88_sc)], not carry fetch;"
}
# line event n: FC's settings holds the line n times inside that event's array and nowhere else, else a fixture fault.
_b88_ev() {
  B88_L="$1" B88_E="    \"$2\": [" B88_N="$3" LC_ALL=C awk '/^    "[A-Za-z]+": \[$/ { e = ($0 == ENVIRON["B88_E"]) }
    $0 == ENVIRON["B88_L"] { if (e) a++; else b++ } END { exit !(a + 0 == ENVIRON["B88_N"] + 0 && b + 0 == 0) }' "$_b83CS" 2>/dev/null \
    || _b83Fx="$_b83Fx settings does not hold [$1] $3 times in $2 and nowhere else;"
}
# n: FC's settings holds n lines naming provision, else a fixture fault.
_b88_pn() { local n; n="$(LC_ALL=C awk 'index($0, "provision") { n++ } END { print n + 0 }' "$_b83CS" 2>/dev/null)"; [ "$n" = "$1" ] || _b83Fx="$_b83Fx settings holds ${n:-?} lines naming provision, not $1;"; }

_b88N200="B08R3Z5 A200 (R3Z5-1): stack.tsv's superpowers row rated High in its risk column, superpowers still carry fetch in the toolbox: cloud FAIL, with the not-a-rating clause naming superpowers"
_b88N201="B08R3Z5 A201 (R3Z5-1): stack.tsv's superpowers row rated hgh, superpowers still carry fetch: cloud FAIL, with the not-a-rating clause naming superpowers"
_b88N202="B08R3Z5 A202 (R3Z5-1): stack.tsv's superpowers row rated medium, superpowers still carry fetch: cloud ok and the line under it empty, as A140 (control)"
_b88N203="B08R3Z5 A203 (R3Z5-2): a guarded UserPromptSubmit hook running bash on .claude/cloud/provision: cloud FAIL, with the other-hooks clause counting 1, and no guard clause"
_b88N204="B08R3Z5 A204 (R3Z5-2): a second hook in the startup|resume|clear|compact SessionStart group, the canonical provision object with timeout 30: cloud FAIL, no binding clause, and the other-hooks clause counting 1"
_b88N205="B08R3Z5 A205 (R3Z5-2): a guarded UserPromptSubmit hook running echo provisional, a plain substring: cloud FAIL, with the other-hooks clause counting 1, and no guard clause"
_b88N206="B08R3Z5 A206 (R3Z5-2): a guarded UserPromptSubmit hook running echo hello: cloud ok and the line under it empty, as A140 (control)"

if [ -n "$_b86Why" ]; then
  for _b86n in "$_b86N170" "$_b86N171" "$_b86N172" "$_b86N173" "$_b86N174" "$_b86N175" "$_b86N176" "$_b86N177" "$_b86N178" \
               "$_b86N179" "$_b86N180" "$_b86N181" "$_b86N182" "$_b86N183" "$_b86N184" "$_b86N185" "$_b86N186" "$_b86N187" \
               "$_b87N188" "$_b87N189" "$_b87N190" "$_b87N191" "$_b87N192" "$_b87N193" "$_b87N194" "$_b87N195" "$_b87N196" \
               "$_b87N197" "$_b87N198" "$_b87N199" "$_b88N200" "$_b88N201" "$_b88N202" "$_b88N203" "$_b88N204" "$_b88N205" \
               "$_b88N206"; do
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
  _b83_seq "$_b86N172" any "$(_b86_bc 0)"
  _b84_start; _b84_cloud; _b86_set async; _b83_has settings '            "async": true,'; _b83_cnt settings "$_b86PL" 1
  _b84_add; _b83_yo a173; _b84_ixw "$_b85IX"
  _b83_seq "$_b86N173" any "$(_b86_bc 0)"
  _b84_start; _b84_cloud; _b86_set notime; _b83_cnt settings '            "timeout": 120' 0; _b83_cnt settings "$_b86PL" 1
  _b84_add; _b83_yo a174; _b84_ixw "$_b85IX"
  _b83_seq "$_b86N174" any "$(_b86_bc 0)"
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

  # ======== The seventh follow-up (contract section 14), A188 to A199
  _b83_l qsd '      "subdir": "",'; _b83_l qnt '      "note": ""'; _b83_l qux "$_b87UX"
  _b83_l qsf "$(printf '%s\n' '      "carry": "fetch",' '      "source": "b08r3z4/semgrep",' \
    '      "sha": "0123456789abcdef0123456789abcdef01234567",' '      "subdir": ".",')"
  # ---- B08R3Z4-1: no settings file does not skip a committed chain (A188, A189)
  _b84_start; _b84_cloud; _b84_stack
  _b83_git "$_b83C" rm -q -- .claude/settings.json >/dev/null 2>&1 || _b83Fx="$_b83Fx settings.json could not be removed;"
  _b83_yo a188; _b83_nos; _b84_ixw '100755 .claude/cloud/provision; 100644 .claude/cloud/toolbox.json'; _b87_st
  _b83_nsk a188; _b83_seq "$_b87N188" any "$(_b86_bc 0)" -- skipped
  _b84_start; _b84_cloud; _b84_stack; _b83_git "$_b83C" commit -qm a189-base >/dev/null 2>&1
  _b83_git "$_b83C" rm -r -q -- .claude/settings.json .claude/cloud projects/felix/stack.tsv >/dev/null 2>&1 \
    || _b83Fx="$_b83Fx settings.json, .claude/cloud and stack.tsv could not be removed;"
  _b83_yo a189; _b83_nos; _b84_ixw ''
  { [ -z "$(_b83_ix projects/felix/stack.tsv)" ] && [ ! -e "$_b83C/.claude/cloud" ] && [ ! -e "$_b83C/projects/felix/stack.tsv" ] \
      && [ -z "$(_b83_git "$_b83C" ls-tree -r --name-only HEAD -- .claude projects/felix/stack.tsv 2>/dev/null)" ]; } \
    || _b83Fx="$_b83Fx .claude/cloud or stack.tsv is still in the index, on disk or in HEAD;"
  _b87t="$(LC_ALL=C awk 'index($0, "  cloud ") == 1' "$_b83/a189.out" 2>/dev/null)"
  if [ -n "$_b83Fx" ]; then bad "$_b87N189" "fixture:$_b83Fx"; else _b83_is "$_b87N189" "[$_b87t]" "[$_b83SK]"; fi

  # ---- B08R3Z4-2: every toolbox value a non-empty string (A190, A191)
  _b84_start; _b84_cloud; _b84_stack; _b84_edp "$_b85TB" instead '=      "subdir": ".",' "$_b83/l/qsd"
  _b85_tn '      "subdir": "",' 1; _b85_tn '      "subdir": ".",' "$(( ${_b87Sd:-0} - 1 ))"; _b84_add "$_b85TB"; _b85_same "$_b85TB"
  _b83_yo a190; _b84_ixw "$_b85IX"; _b87_st
  _b83_seq "$_b87N190" any "$_b86SH"
  _b84_start; _b84_cloud; _b84_stack; _b84_edp "$_b85TB" instead '=      "note": "its only content is a Python hook that calls a model"' "$_b83/l/qnt"
  _b85_tn '      "note": ""' 1; _b85_tn '      "name": "security-guidance",' 1; _b84_add "$_b85TB"; _b85_same "$_b85TB"
  _b83_yo a191; _b84_ixw "$_b85IX"; _b87_st
  _b83_seq "$_b87N191" any "$_b86SH"

  # ---- B08R3Z4-3: the toolbox read back against stack.tsv and invariant 4 (A192 to A194)
  _b84_start; _b84_cloud; _b84_stack; _b84_edp "$_b85TB" after '=  "tools": [' "$_b83/l/qux"; _b85_tn "$_b87UX" 1
  _b84_add "$_b85TB"; _b85_same "$_b85TB"; _b83_yo a192; _b84_ixw "$_b85IX"; _b87_st
  _b83_git "$_b83C" cat-file blob :projects/felix/stack.tsv > "$_b83/st.tmp" 2>/dev/null
  { [ -s "$_b83/st.tmp" ] && [ -z "$(LC_ALL=C awk -F '\t' '$2 == "undeclared-x" || index($2, "undeclared-x@") == 1' "$_b83/st.tmp")" ]; } \
    || _b83Fx="$_b83Fx the index's stack.tsv is empty or names undeclared-x;"
  _b83_seq "$_b87N192" any "$_b87NS"
  _b84_start; _b84_cloud; _b84_stack; _b87_sg; _b84_add "$_b85TB"; _b85_same "$_b85TB"; _b83_yo a193; _b84_ixw "$_b85IX"; _b87_st
  [ "$(_b87_rk)" = high ] || _b83Fx="$_b83Fx the index's stack.tsv rates semgrep [$(_b87_rk)], not high;"
  _b83_seq "$_b87N193" any "$_b87RK"
  _b84_start; _b84_cloud; _b84_stack; _b87_sg; _b84_add "$_b85TB"; _b85_same "$_b85TB"
  { LC_ALL=C awk -F '\t' 'BEGIN { OFS = "\t" } $1 == "plugin" && index($2, "semgrep@") == 1 { $4 = "low"; n++ } { print } END { if (n != 1) exit 3 }' \
      "$_b83C/projects/felix/stack.tsv" > "$_b83/ed.tmp" && cat "$_b83/ed.tmp" > "$_b83C/projects/felix/stack.tsv"; } \
    || _b83Fx="$_b83Fx stack.tsv's semgrep row could not be rated low;"
  _b84_add projects/felix/stack.tsv; _b83_yo a194; _b84_ixw "$_b85IX"; _b87_st
  [ "$(_b87_rk)" = low ] || _b83Fx="$_b83Fx the index's stack.tsv rates semgrep [$(_b87_rk)], not low;"
  _b87c="$(LC_ALL=C grep -cxF -e "$(printf '  %-18s %s' cloud ok)" "$_b83/a194.out" 2>/dev/null)"; _b87g=none
  ! _b83_in 'rates it risk=high' "$_b83All" || _b87g=held
  if [ -n "$_b83Fx" ]; then bad "$_b87N194" "fixture:$_b83Fx"
  else _b83_is "$_b87N194" "${_b87c:-0} cloud ok lines; the line under it [$_b83D]; risk clause $_b87g" "1 cloud ok lines; the line under it []; risk clause none"; fi

  # ---- B08R3Z4-4: the canonical hook counted everywhere (A195)
  _b84_start; _b84_cloud; _b84_stack; _b86_set upc; _b83_cnt settings "$_b86PL" 2; _b83_cnt settings '            "timeout": 120' 2
  B87_P="$_b86PL" LC_ALL=C awk '$0 == "    \"UserPromptSubmit\": [" { u = 1 } $0 == "    \"Stop\": [" { u = 0 }
    $0 == ENVIRON["B87_P"] { if (u) a++; else b++ } END { exit !(a == 1 && b == 1) }' "$_b83CS" \
    || _b83Fx="$_b83Fx the provision command line is not once in UserPromptSubmit and once outside it;"
  _b84_add; _b83_yo a195; _b84_ixw "$_b85IX"; _b87_st
  _b83_seq "$_b87N195" any "$_b87OUT"

  # ---- B08R3Z3-2's NUL reason, and B08R3Z3-1's sixth key, shell and timeout (A196 to A199, coverage)
  _b84_start; _b84_cloud; _b84_stack; printf '\000' >> "$_b83C/$_b86PV" || _b83Fx="$_b83Fx a NUL could not be appended to provision;"
  _b84_add "$_b86PV"; _b83_yo a196; _b84_ixw "$_b85IX"; _b87_st; _b85_same "$_b86PV"
  _b83_git "$_b83C" cat-file blob ":$_b86PV" > "$_b83/pv.tmp" 2>/dev/null
  _b87o="$(_b87_ox "$_b83/pv.tmp")"; _b87z="$(LC_ALL=C wc -c < "$_b83/pv.tmp" | LC_ALL=C tr -d ' ')"
  { [ "$_b87o" = "1 0 00" ] && [ -n "$_b87Pz" ] && [ "$_b87z" = "$(( _b87Pz + 1 ))" ]; } \
    || _b83Fx="$_b83Fx the index blob of provision is ${_b87z:-?} bytes with [NUL CR last] [$_b87o], not one byte more than the tree's ${_b87Pz:-?} with [1 0 00];"
  _b83_once "$_b86PV"; _b83_seq "$_b87N196" any "$(_b86_pv "a NUL byte in git's index blob")"
  _b84_start; _b84_cloud; _b84_stack; _b86_set sm; _b83_has settings '            "statusMessage": "x"'; _b83_has settings '            "timeout": 120,'
  _b83_cnt settings "$_b86PL" 1; _b84_add; _b83_yo a197; _b84_ixw "$_b85IX"; _b87_st
  _b83_seq "$_b87N197" any "$(_b86_bc 0)"
  _b84_start; _b84_cloud; _b84_stack; _b86_set nosh; _b83_cnt settings '            "shell": "bash",' "$(( ${_b83ShN:-0} - 1 ))"
  [ "$(_b87_nx)" = '            "async": false,' ] || _b83Fx="$_b83Fx the provision command line is followed by [$(_b87_nx)], not its async;"
  _b83_cnt settings "$_b86PL" 1; _b84_add; _b83_yo a198; _b84_ixw "$_b85IX"; _b87_st
  _b83_seq "$_b87N198" any "$(_b86_bc 0)"
  _b84_start; _b84_cloud; _b84_stack; _b86_set t60; _b83_has settings '            "timeout": 60'; _b83_cnt settings '            "timeout": 120' 0
  _b83_cnt settings "$_b86PL" 1; _b84_add; _b83_yo a199; _b84_ixw "$_b85IX"; _b87_st
  _b83_seq "$_b87N199" any "$(_b86_bc 0)"

  # ======== The eighth follow-up (contract section 15), A200 to A206
  # ---- B08R3Z5-1: a risk value outside low, medium and high (A200 to A202)
  _b84_start; _b84_cloud; _b84_stack; _b88_rate High; _b83_yo a200; _b84_ixw "$_b85IX"; _b87_st; _b88_sp High; _b85_same "$_b85TB"
  _b83_seq "$_b88N200" any "$(_b88_nr superpowers)"
  _b84_start; _b84_cloud; _b84_stack; _b88_rate hgh; _b83_yo a201; _b84_ixw "$_b85IX"; _b87_st; _b88_sp hgh; _b85_same "$_b85TB"
  _b83_seq "$_b88N201" any "$(_b88_nr superpowers)"
  _b84_start; _b84_cloud; _b84_stack; _b88_rate medium; _b83_yo a202; _b84_ixw "$_b85IX"; _b87_st; _b88_sp medium; _b85_same "$_b85TB"
  _b83_asok a202 "$_b88N202"

  # ---- B08R3Z5-2: every other hook that names provision (A203 to A206)
  _b84_start; _b84_cloud; _b84_stack; _b86_set upo "$_b88P3"; _b88_ev "$_b88P3" UserPromptSubmit 1; _b88_ev "$_b86PL" SessionStart 1
  _b88_pn 2; _b84_add; _b83_yo a203; _b84_ixw "$_b85IX"; _b87_st
  _b83_seq "$_b88N203" any "$(_b88_oh 1)" -- "$_b83GT"
  _b84_start; _b84_cloud; _b84_stack; _b86_set t30; _b88_ev "$_b86PL" SessionStart 2; _b88_ev '            "timeout": 30' SessionStart 1
  _b83_cnt settings '            "timeout": 120' 1; _b83_cnt settings '        "matcher": "startup|resume|clear|compact",' 1; _b88_pn 2
  _b84_add; _b83_yo a204; _b84_ixw "$_b85IX"; _b87_st
  _b83_seq "$_b88N204" any "$(_b88_oh 1)" -- "$_b88BT" "$_b83GT"
  _b84_start; _b84_cloud; _b84_stack; _b86_set upo "$_b88P5"; _b88_ev "$_b88P5" UserPromptSubmit 1; _b88_ev "$_b86PL" SessionStart 1
  _b88_pn 2; _b84_add; _b83_yo a205; _b84_ixw "$_b85IX"; _b87_st
  _b83_seq "$_b88N205" any "$(_b88_oh 1)" -- "$_b83GT"
  _b84_start; _b84_cloud; _b84_stack; _b86_set upo "$_b88P6"; _b88_ev "$_b88P6" UserPromptSubmit 1; _b88_ev "$_b86PL" SessionStart 1
  _b88_pn 1; _b84_add; _b83_yo a206; _b84_ixw "$_b85IX"; _b87_st
  _b83_asok a206 "$_b88N206"
fi
