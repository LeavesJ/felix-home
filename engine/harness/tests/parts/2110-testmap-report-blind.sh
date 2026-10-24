# >>> testmap-report-blind
printf '\naudit b30: felix testmap, its report and its usage (blind)\n'
# Blind, written on 2026-10-24 from docs/2026-10-24-audit-fixes/b30-plan-a-unit-facts-and-map.md alone (B21 to B30, A68 to A108, fixture RP).
# No code the contract is about was read: felix testmap is run as a black box. RP is a git repository made by hand under $TMP/tr; no suite
# runs in it. Its maps are written here in B18's shape. Every case starts from RP's clean tree at C1, makes its change, runs felix testmap
# --report from RP's top with FELIX_HOME naming no directory, and puts the tree back.
# Readings taken where the contract leaves room, said here:
# - A path the report prints may be spelled with links resolved (/private/var on macOS) or as $TMP spells it; output is read with the first
#   spelling of $TMP replaced by the second.
# - A68 has no line 4 or 5, so its whole stdout is the six lines it names, and that is what is asserted.
# - A102 makes each of its three changes before a marker of its own, one second before the marker, and runs the report one second after it, so
#   a one-second clock cannot hide a write; it also asks that each of the three reports ran to its last line, or "nothing newer" says nothing.
# - A103 reads each logged call's subcommand after git's global options, which is stricter than a line's first word; and a log with no call in
#   it is a failure, since it would prove nothing.
# - A106: _awk_names always prints its programs row (part 1497), so "no output" is read as no row other than that one.
RP0="$TMP/tr"; RP="$RP0/rp"; RPO="$RP0/o"; _rp_T="$RP/engine/harness/tests"; _rp_L="$RP/engine/harness/lib"
mkdir -p "$_rp_T/parts" "$_rp_L" "$RP/projects/x" "$RP/docs" "$RPO" "$RP0/plain" "$RP0/sh" "$RP0/src" "$RP0/bare"
_rp_P="$(uname -s 2>/dev/null | LC_ALL=C tr ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz)"
_rp_ph="$(cd "$TMP" && pwd -P)"; _rp_all=""; _rp_E=(); _rp_new=""; _rp_ro='report only: nothing was run, and no verdict, receipt or gate changes'
{ printf '# the driver of fixture RP: its part lines are read, and nothing runs it\n'
  for _rp_p in 0001-pre.sh 0010-a.sh 0020-b.sh 0030-c.sh 0040-d.sh 0050-e.sh 0060-f.sh 1010-r.sh 9990-end.sh; do
    printf '. "$HERE/parts/%s"\n' "$_rp_p"; printf 'ok "x"\n' > "$_rp_T/parts/$_rp_p"; done; } > "$_rp_T/run"
printf 'g\t0040-d.sh\ng\t0050-e.sh\n' > "$_rp_T/groups.tsv"; printf '1\tx\n' > "$_rp_T/assertions.tsv"; printf 'run\t0\t1\t1\n' > "$_rp_T/red.tsv"
printf '%s\n' 'a_top=1' 'f1() {' '  echo one' '}' 'f2() {' '  echo two' '}' 'f3() { echo three; }' 'f4() {' '  echo four' '} 2>/dev/null' 'function f5 {' '  echo five' '}' > "$_rp_L/a.sh"
printf '%s\n' 'f1() {' '  echo b-one' '}' > "$_rp_L/b.sh"; printf '%s\n' 'c1() {' '  echo c' > "$_rp_L/c.sh"; printf '%s\n' 'd1() { :; }' > "$_rp_L/d.sh"
printf 'a\tb\n' > "$RP/projects/x/t.tsv"; printf '# n\n' > "$RP/docs/n.md"
_rp_now="$(date +%s)"; _rp_d0="@$((_rp_now - 20 * 86400 - 3600)) +0000"; _rp_d1="@$_rp_now +0000"
_rp_cm() { ( _fx_cd "$RP" && git add -A && GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$1" git -c user.name=rp -c user.email=rp@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm "$2" ) >/dev/null 2>&1; }
( _fx_cd "$RP" && git init -q -b main ) >/dev/null 2>&1
_rp_cm "$_rp_d0" C0; _rp_C0="$(git -C "$RP" rev-parse HEAD 2>/dev/null)"
printf 'changed\n' >> "$RP/docs/n.md"; _rp_cm "$_rp_d1" C1; _rp_C1="$(git -C "$RP" rev-parse HEAD 2>/dev/null)"
_rp_X="$( _fx_cd "$RP" && GIT_AUTHOR_DATE="$_rp_d1" GIT_COMMITTER_DATE="$_rp_d1" git -c user.name=rp -c user.email=rp@example.invalid -c commit.gpgsign=false commit-tree -p "$_rp_C0" -m X "$_rp_C0^{tree}" 2>/dev/null )"
{ _fx_git "$RP" update-ref refs/heads/x "$_rp_X" && _fx_git "$RP" update-ref refs/remotes/origin/main "$_rp_C1"; } >/dev/null 2>&1
_rp_day="$(perl -e '@t = gmtime($ARGV[0]); printf "%04d-%02d-%02d", $t[5] + 1900, $t[4] + 1, $t[3]' "$_rp_now")"
_rp_MD="$RP/.git/felix-testmap/$_rp_P"; _rp_M1="$_rp_MD/$_rp_C1/map.tsv"
_rp_put() {   # ID [SECONDS-OF-0020-b.sh [VERSION]]: the map of fixture RP at ID, in B18's shape
  mkdir -p "$_rp_MD/$1"
  { printf 'map\t%s\t%s\t%s\t%s\tuntraced\n' "${3:-v1}" "$1" "$_rp_P" "$_rp_now"
    printf 'unit\t%s\t%s\t%s\t%s\n' 0010-a.sh complete 10.00 - 0020-b.sh complete "${2:-10.00}" - 0030-c.sh complete 10.00 - g complete 10.00 - \
      0060-f.sh incomplete 10.00 'a command started without the tracer: env -i x' 1010-r.sh complete 50.00 -
    { printf 'fn\t%s\t%s\t%s\n' 0010-a.sh engine/harness/lib/a.sh f1 0020-b.sh engine/harness/lib/a.sh f2 0030-c.sh engine/harness/lib/b.sh f1 \
        0030-c.sh engine/harness/lib/c.sh c1 g engine/harness/lib/a.sh f3 g engine/harness/lib/a.sh f4 g engine/harness/lib/a.sh f5
      printf 'top\t%s\t%s\n' 0010-a.sh engine/harness/lib/a.sh 0020-b.sh engine/harness/lib/a.sh g engine/harness/lib/a.sh \
        0030-c.sh engine/harness/lib/b.sh 0030-c.sh engine/harness/lib/c.sh; } | LC_ALL=C sort; } > "$_rp_MD/$1/map.tsv"
}
_rp_put "$_rp_C1"; _rp_put "$_rp_C0"; _rp_put "$_rp_X"
_rp_in() { local d="$1" l="$2"; shift 2; ( cd "$d" && exec env FELIX_HOME="$RP0/nohome" ${_rp_E[@]+"${_rp_E[@]}"} "$FELIX" testmap "$@" ) > "$RPO/$l.out" 2> "$RPO/$l.err"; _rp_rc=$?; _rp_E=(); }
_rp_rep() { local l="$1"; shift; _rp_in "$RP" "$l" --report "$@"; _rp_all="$_rp_all $l"; }   # LABEL [BASE]: a report case from RP's top
_rp_out() { PH="$_rp_ph" LG="$TMP" LC_ALL=C awk '{ s = $0; o = ""; if (ENVIRON["PH"] != ENVIRON["LG"]) while ((i = index(s, ENVIRON["PH"])) > 0) { o = o substr(s, 1, i - 1) ENVIRON["LG"]; s = substr(s, i + length(ENVIRON["PH"])) } print o s }' "$RPO/$1.out" 2>/dev/null; }
_rp_n() { _rp_out "$1" | grep -cxF -e "$2"; }   # LABEL LINE: how many stdout lines are exactly LINE
_rp_p() { _rp_out "$1" | P="$2" LC_ALL=C awk 'index($0, ENVIRON["P"]) == 1 { n++ } END { print n + 0 }'; }   # LABEL PREFIX: how many start with it
_rp_s() { _rp_out "$1" | grep '^selected ' | tr '\n' '|'; }   # LABEL: the selected lines, joined
_rp_reset() { _fx_git "$RP" checkout -q -- . >/dev/null 2>&1; rm -f "$_rp_T/parts/0070-n.sh" "$_rp_T/select.sh" "$_rp_L/new.sh"; rm -rf "$RP/.github"; }
_rp_sed() { sed -e "$2" "$1" > "$1.djx" && mv "$1.djx" "$1"; }   # FILE EXPR
_rp_ins() { L="$3" LC_ALL=C awk -v n="$2" 'NR == n + 1 && n == 0 { print ENVIRON["L"] } { print } NR == n + 0 && n > 0 { print ENVIRON["L"] }' "$1" > "$1.djx" && mv "$1.djx" "$1"; }   # FILE N LINE: LINE after line N (0: first)
_rp_one() { _rp_sed "$_rp_L/a.sh" 's/echo one/echo uno/'; }   # A69's change
_rp_ce() { printf '%s' "$(_rp_p "$1" 'everything runs: ')"; }
"$FELIX" help > "$RPO/help0.out" 2>&1

# ---- the report: lines, selection and what makes everything run (B22 to B29)
_rp_rep a68
is "A68: with no change the report is the top, the base, the map, a summary of nothing and the tail, and says nothing on stderr" "$_rp_rc|[$(cat "$RPO/a68.err")]|$(_rp_out a68)" \
   "0|[]|$(printf 'testmap: %s\nbase: origin/main %s\nmap: %s %s dated %s, unit time from untraced runs\nsummary: 0 of 6 units selected, 0%% of unit time\nresult: nothing to run\n%s' "$RP" "$_rp_C1" "$_rp_C1" "$_rp_P" "$_rp_day" "$_rp_ro")"
_rp_one; _rp_rep a69; _rp_reset
is "A69: a changed function selects the unit that entered it and the unit the map holds incomplete, 20% of unit time, and the selection runs" \
   "$(_rp_s a69)$(_rp_n a69 'summary: 2 of 6 units selected, 20% of unit time')$(_rp_n a69 'result: the selection runs')" \
   "selected 0010-a.sh: function f1 in engine/harness/lib/a.sh|selected 0060-f.sh: incomplete in the map: a command started without the tracer: env -i x|11"
_rp_sed "$_rp_L/b.sh" 's/echo b-one/echo b-uno/'; _rp_rep a70; _rp_reset
is "A70: a function's name is read with its file: b.sh's f1 selects 0030, and a.sh's f1 unit is not selected" "$(_rp_n a70 'selected 0030-c.sh: function f1 in engine/harness/lib/b.sh')$(_rp_p a70 'selected 0010-a.sh')" 10
_rp_sed "$_rp_L/a.sh" 's/a_top=1/a_top=2/'; _rp_rep a71; _rp_reset
is "A71: a changed top level selects every unit that ran the file's top level, and no other" \
   "$(_rp_n a71 'selected 0010-a.sh: top level of engine/harness/lib/a.sh')$(_rp_n a71 'selected 0020-b.sh: top level of engine/harness/lib/a.sh')$(_rp_n a71 'selected g: top level of engine/harness/lib/a.sh')$(_rp_p a71 'selected 0030-c.sh')" 1110
_rp_sed "$_rp_L/a.sh" 's/echo three/echo tres/'; _rp_rep a72; _rp_reset
is "A72: a change inside a one-line definition is that function's" "$(_rp_n a72 'selected g: function f3 in engine/harness/lib/a.sh')$(_rp_p a72 'selected 0010-a.sh')$(_rp_p a72 'selected 0020-b.sh')" 100
_rp_sed "$_rp_L/a.sh" 's/echo four/echo cuatro/'; _rp_rep a73; _rp_reset
is "A73: a definition closed by } 2>/dev/null ends there: the change is f4's and the file parses" "$(_rp_n a73 'selected g: function f4 in engine/harness/lib/a.sh')$(_rp_out a73 | grep -c 'could not be parsed')" 10
_rp_sed "$_rp_L/a.sh" 's/echo five/echo cinco/'; _rp_rep a74; _rp_reset
is "A74: a definition spelled function NAME { is read as one" "$(_rp_n a74 'selected g: function f5 in engine/harness/lib/a.sh')" 1
_rp_sed "$_rp_L/a.sh" '5,7d'; _rp_rep a75; _rp_reset
is "A75: a function deleted from the file selects the unit that entered it, and only it" "$(_rp_n a75 'selected 0020-b.sh: function f2 in engine/harness/lib/a.sh')$(_rp_p a75 'selected 0010-a.sh')" 10
LC_ALL=C awk 'NR >= 2 && NR <= 4 { f = f $0 "\n"; next } { print } NR == 7 { printf "%s", f }' "$_rp_L/a.sh" > "$_rp_L/a.sh.djx" && mv "$_rp_L/a.sh.djx" "$_rp_L/a.sh"; _rp_rep a76; _rp_reset
is "A76: two functions moved past each other, bodies unchanged, select neither unit" "$(_rp_p a76 'selected 0010-a.sh')$(_rp_p a76 'selected 0020-b.sh')$(_rp_p a76 'selected 0060-f.sh')" 001
printf '  echo more\n' >> "$_rp_L/c.sh"; _rp_rep a77; _rp_reset
is "A77: a file with a definition that never ends selects the unit with its rows as not parsed into functions" "$(_rp_n a77 'selected 0030-c.sh: engine/harness/lib/c.sh could not be parsed into functions')" 1
printf 'ok "y"\n' >> "$_rp_T/parts/0020-b.sh"; _rp_rep a78; _rp_reset
is "A78: an edited part selects its unit as a changed part, and runs nothing else for it" "$(_rp_n a78 'selected 0020-b.sh: changed part 0020-b.sh')$(_rp_ce a78)" 10
printf 'ok "y"\n' >> "$_rp_T/parts/0050-e.sh"; _rp_rep a79; _rp_reset
is "A79: an edited member of a group selects the group" "$(_rp_n a79 'selected g: changed part 0050-e.sh')" 1
printf 'ok "x"\n' > "$_rp_T/parts/0070-n.sh"
LC_ALL=C awk '{ print } index($0, "/0060-f.sh\"") { print ". \"$HERE/parts/0070-n.sh\"" }' "$_rp_T/run" > "$_rp_T/run.djx" && mv "$_rp_T/run.djx" "$_rp_T/run"; _rp_rep a80; _rp_reset
is "A80: a new part and its driver line: the driver is code outside the units, the part is a new unit of seven, and everything runs" \
   "$(_rp_n a80 'everything runs: engine/harness/tests/run is code outside the units')$(_rp_n a80 'selected 0070-n.sh: new unit; new part 0070-n.sh')$(_rp_out a80 | grep '^summary: ' | grep -c ' of 7 units')$(_rp_n a80 'result: everything runs')" 1111
printf '# a comment\n' >> "$_rp_T/groups.tsv"; _rp_rep a81; _rp_reset
is "A81: any change to groups.tsv is code outside the units" "$(_rp_n a81 'everything runs: engine/harness/tests/groups.tsv is code outside the units')" 1
printf 'ok "y"\n' >> "$_rp_T/parts/0001-pre.sh"; _rp_rep a82a; _rp_reset; printf 'ok "y"\n' >> "$_rp_T/parts/9990-end.sh"; _rp_rep a82b; _rp_reset
is "A82: the prelude parts and 9990 are code outside the units" \
   "$(_rp_n a82a 'everything runs: engine/harness/tests/parts/0001-pre.sh is code outside the units')$(_rp_n a82b 'everything runs: engine/harness/tests/parts/9990-end.sh is code outside the units')" 11
printf '# x\n' > "$_rp_T/select.sh"; _rp_rep a83a; _rp_reset; mkdir -p "$RP/.github/workflows"; printf 'on: push\n' > "$RP/.github/workflows/g.yml"; _rp_rep a83b; _rp_reset
is "A83: an untracked tests/select.sh, and a file under .github/, are code outside the units" \
   "$(_rp_n a83a 'everything runs: engine/harness/tests/select.sh is code outside the units')$(_rp_n a83b 'everything runs: .github/workflows/g.yml is code outside the units')" 11
_rp_ins "$_rp_L/a.sh" 3 '  eval "$x"'; _rp_rep a84; _rp_reset
is "A84: an added eval line is a computed call, named by its line in the tree, and its function is still selected" \
   "$(_rp_n a84 'everything runs: engine/harness/lib/a.sh:4 adds a computed call')$(_rp_n a84 'selected 0010-a.sh: function f1 in engine/harness/lib/a.sh')" 11
_rp_w=""; _rp_i=0
for _rp_l in '  "$tool" --flag' '  . "$f"' "  bash -c 'true'" "  trap 'echo t' EXIT" '  declare -f f1' '  export -f f1' '  compgen -A function'; do
  _rp_i=$((_rp_i + 1)); _rp_ins "$_rp_L/a.sh" 3 "$_rp_l"; _rp_rep "a85-$_rp_i"; _rp_reset
  [ "$(_rp_n "a85-$_rp_i" 'everything runs: engine/harness/lib/a.sh:4 adds a computed call')" = 1 ] || _rp_w="$_rp_w [$_rp_l]"; done
is "A85: a variable command word, a computed source, bash -c, a quoted trap, declare -f, export -f and compgen -A function each add a computed call" "${_rp_w:-ok}" ok
_rp_w=""; _rp_i=0
for _rp_l in '  # eval "$x" in a comment' '  echo "eval it"'; do
  _rp_i=$((_rp_i + 1)); _rp_ins "$_rp_L/a.sh" 3 "$_rp_l"; _rp_rep "a86-$_rp_i"; _rp_reset
  [ "$(_rp_ce "a86-$_rp_i")$(_rp_n "a86-$_rp_i" 'selected 0010-a.sh: function f1 in engine/harness/lib/a.sh')" = 01 ] || _rp_w="$_rp_w [$_rp_l]"; done
is "A86: a comment and a quoted word naming eval add no computed call, and the function is selected (control)" "${_rp_w:-ok}" ok
printf '  eval "$x"\n' >> "$_rp_T/parts/0020-b.sh"; _rp_rep a87; _rp_reset
is "A87: a part is exempt from the computed-call rule: an eval in a part selects its unit as a changed part" "$(_rp_out a87 | grep -c 'adds a computed call')$(_rp_n a87 'selected 0020-b.sh: changed part 0020-b.sh')" 01
_rp_w=""
for _rp_l in projects/x/t.tsv docs/n.md engine/harness/lib/d.sh engine/harness/lib/new.sh; do
  printf 'more\n' >> "$RP/$_rp_l"; _rp_rep "a88-${_rp_l##*/}"; _rp_reset
  [ "$(_rp_n "a88-${_rp_l##*/}" "everything runs: $_rp_l changed and no map reads it")" = 1 ] || _rp_w="$_rp_w [$_rp_l]"; done
is "A88: a data file, a document, a library no unit ran and an untracked new library each make everything run: changed and no map reads it" "${_rp_w:-ok}" ok
printf '1\ty\n' >> "$_rp_T/assertions.tsv"; _rp_rep a89; _rp_reset
is "A89: a changed record file selects the unit holding part 1010, and nothing makes everything run" \
   "$(_rp_n a89 'selected 1010-r.sh: record file engine/harness/tests/assertions.tsv')$(_rp_ce a89)$(_rp_n a89 'summary: 2 of 6 units selected, 60% of unit time')" 101
printf '1\ty\n' >> "$_rp_T/assertions.tsv"; _rp_ins "$_rp_L/b.sh" 0 'b_top=1'; _rp_rep a90; _rp_reset
is "A90: a selection of 70% of unit time makes everything run" \
   "$(_rp_n a90 'everything runs: the selection is 70% of unit time (the limit is 70%)')$(_rp_n a90 'selected 0030-c.sh: top level of engine/harness/lib/b.sh')" 11
_rp_put "$_rp_C1" unknown; _rp_one; _rp_rep a91; _rp_reset; _rp_put "$_rp_C1"
is "A91: with a selected unit's seconds unknown the share is not known, and everything runs" \
   "$(_rp_n a91 "everything runs: the selection's share of unit time is not known")$(_rp_n a91 'summary: 2 of 6 units selected, share of unit time not known')" 11

# ---- which map (B23)
_rp_rep a92 nosuch
is "A92: a base that is no commit is unknown, uses no map, and everything runs, with no summary" \
   "$(_rp_n a92 'base: nosuch unknown')$(_rp_n a92 'map: none')$(_rp_n a92 'everything runs: the base [nosuch] is not a commit here')$(_rp_p a92 'summary: ')$(_rp_n a92 'result: everything runs')" 11101
_rp_rep a93 "$_rp_C0"
is "A93: with C0 as the base its map is used, and a map 20 days old makes everything run" \
   "$(_rp_p a93 "map: $_rp_C0 $_rp_P dated ")$(_rp_n a93 "everything runs: the map's commit $_rp_C0 is 20 days old (the limit is 14)")" 11
mv "$_rp_MD/$_rp_C1" "$_rp_MD/notacommit"; _rp_rep a94; mv "$_rp_MD/notacommit" "$_rp_MD/$_rp_C1"
is "A94: a map under a directory that is no commit id is not read, and a map on another branch is not used: C0's is, with its age" \
   "$(_rp_p a94 "map: $_rp_C0 ")$(_rp_n a94 "everything runs: the map's commit $_rp_C0 is 20 days old (the limit is 14)")" 11
mv "$_rp_MD" "$RP/.git/felix-testmap/otheros"; _rp_rep a95; mv "$RP/.git/felix-testmap/otheros" "$_rp_MD"
is "A95: maps of another platform are not read" "$(_rp_n a95 'map: none')$(_rp_n a95 "everything runs: no map for $_rp_P here whose commit is an ancestor of origin/main")" 11
_rp_put "$_rp_C1" "" v9; _rp_rep a96; _rp_put "$_rp_C1"
is "A96: the chosen map in another shape is not read, no older map is tried, and nothing is selected or summed" \
   "$(_rp_n a96 'map: none')$(_rp_p a96 "everything runs: the map $_rp_M1 cannot be read: ")$(_rp_p a96 'selected ')$(_rp_p a96 'summary: ')" 1100

# ---- the one-line answers and the command (B21, B22)
_rp_in "$RP0/plain" a97 --report; _rp_all="$_rp_all a97"
is "A97: outside a git checkout the report is one line, and exits 0" "$_rp_rc|$(_rp_out a97)" "0|testmap: $RP0/plain is not in a git checkout, so there is nothing to select"
printf 'b\n' > "$RP0/bare/README"; ( _fx_cd "$RP0/bare" && git init -q -b main && git add -A && git -c user.name=rp -c user.email=rp@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm b ) >/dev/null 2>&1
_rp_in "$RP0/bare" a98 --report; _rp_all="$_rp_all a98"
is "A98: in a checkout with no engine/harness/tests/run the report is one line, and exits 0" "$_rp_rc|$(_rp_out a98)" "0|testmap: $RP0/bare has no engine/harness/tests/run, so there is no suite to select from"
_rp_w=""; _rp_i=0
for _rp_l in "" --bogus "--report a b" --compile; do
  _rp_i=$((_rp_i + 1)); _rp_in "$RP" "a99-$_rp_i" $_rp_l
  _rp_x="$(grep -c '^usage: felix testmap' "$RPO/a99-$_rp_i.err")"
  [ "$_rp_rc|$(wc -c < "$RPO/a99-$_rp_i.out" | tr -d ' ')" = "2|0" ] && [ "${_rp_x:-0}" -ge 1 ] || _rp_w="$_rp_w [${_rp_l:-no argument}: exit $_rp_rc, $_rp_x usage lines]"; done
is "A99: no argument, an unknown word, two bases and --compile with no directory each give the usage on stderr, nothing on stdout, exit 2" "${_rp_w:-ok}" ok
_rp_in "$RP" a100 --help
is "A100: felix testmap --help prints the usage on stdout and exits 0" "$_rp_rc|$(sed -n 1p "$RPO/a100.out")" "0|usage: felix testmap --report [BASE] | --compile DIR"
"$FELIX" help > "$RPO/help1.out" 2>&1
is "A101: felix help names no testmap, before the cases above and after them (control)" \
   "$([ -s "$RPO/help0.out" ] && [ -s "$RPO/help1.out" ] && echo printed || echo empty) $(cat "$RPO/help0.out" "$RPO/help1.out" | grep -c testmap)" "printed 0"

# ---- read-only (B22): nothing under RP is newer than a marker, and no git call reaches a remote
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "$RP_GITLOG"\nexec "%s" "$@"\n' "$(type -P git)" > "$RP0/sh/git"; chmod +x "$RP0/sh/git"; : > "$RPO/git.log"
_rp_quiet() {   # LABEL [BASE]: the report with the logging git first on PATH, one second after a marker made one second after the case's change
  sleep 1; touch "$RP0/marker"; sleep 1
  _rp_E=(PATH="$RP0/sh:$PATH" RP_GITLOG="$RPO/git.log"); _rp_rep "$@"
  _rp_new="$_rp_new$(find "$RP" -newer "$RP0/marker" -print 2>/dev/null | tr '\n' ' ')"
  [ "$(_rp_out "$1" | sed -n '$p')" = "$_rp_ro" ] || _rp_new="$_rp_new [$1 did not run to its last line]"
}
_rp_quiet q68; _rp_one; _rp_quiet q69; _rp_reset
mv "$_rp_MD" "$RP/.git/felix-testmap/otheros"; _rp_quiet q95; mv "$RP/.git/felix-testmap/otheros" "$_rp_MD"
is "A102: three reports, A68's, A69's and A95's, change nothing under RP, the index included" "${_rp_new:-none}" none
is "A103: and none of them runs git fetch, pull, push, ls-remote or remote" \
   "$(LC_ALL=C awk '{ n++; s = ""; k = split($0, w, " "); for (i = 1; i <= k; i++) { if (w[i] == "-C" || w[i] == "-c" || w[i] == "--git-dir" || w[i] == "--work-tree" || w[i] == "--namespace" || w[i] == "--config-env") { i++; continue } if (substr(w[i], 1, 1) == "-") continue; s = w[i]; break }
      if (s == "fetch" || s == "pull" || s == "push" || s == "ls-remote" || s == "remote") b = b " [" $0 "]" } END { print (n == 0) ? "no git call was logged" : (b == "" ? "ok" : b) }' "$RPO/git.log")" ok
_rp_w=""; for _rp_l in $_rp_all; do
  [ -s "$RPO/$_rp_l.err" ] && _rp_w="$_rp_w [$_rp_l: stderr]"
  case "$_rp_l" in a97|a98) ;; *) [ "$(_rp_out "$_rp_l" | sed -n '$p')" = "$_rp_ro" ] || _rp_w="$_rp_w [$_rp_l: last line]" ;; esac; done
is "A104: every report above ends with the report-only line and says nothing on stderr" "${_rp_w:-ok}" ok

# ---- where the code is (B30)
_rp_f=("$HERE/trace.sh" "$HERE/select.sh"); for _rp_l in "$HERE"/select-*.sh; do [ ! -f "$_rp_l" ] || _rp_f[${#_rp_f[@]}]="$_rp_l"; done; _rp_f[${#_rp_f[@]}]="$REAL_HARNESS/lib/testmap.sh"
_rp_w=""; _rp_have=()
for _rp_l in "${_rp_f[@]}"; do
  if [ ! -f "$_rp_l" ]; then _rp_w="$_rp_w ${_rp_l##*/}: missing;"; continue; fi
  _rp_have[${#_rp_have[@]}]="$_rp_l"; _rp_x=""; { IFS= read -r _rp_x || :; } < "$_rp_l"
  case "$_rp_x" in '#!'*) _rp_w="$_rp_w ${_rp_l##*/}: a #! line;" ;; esac
  [ ! -x "$_rp_l" ] || _rp_w="$_rp_w ${_rp_l##*/}: executable;"
  _rp_x="$(awk 'END { print NR }' "$_rp_l")"; [ "$_rp_x" -lt 500 ] || _rp_w="$_rp_w ${_rp_l##*/}: $_rp_x lines;"; done
is "A105: tests/trace.sh, tests/select.sh, each select-*.sh and lib/testmap.sh exist, with no #! line, not executable, each under 500 lines" "${_rp_w:-ok}" ok
_rp_x="missing"; if [ "${#_rp_have[@]}" -eq "${#_rp_f[@]}" ] && declare -F _awk_names >/dev/null 2>&1; then
  ( _awk_names "${_rp_have[@]}" ) < /dev/null > "$RPO/an.out" 2> "$RPO/an.err"; _rp_x="$?|$(awk -F'\t' 'NF && $1 != "programs" { printf "[%s]", $0 }' "$RPO/an.out")|$(cat "$RPO/an.err")"; fi
is "A106: _awk_names over the same files exits 0 with no row but its programs row" "$_rp_x" "0||"
_rp_w=""; _rp_sf=("$HERE/select.sh"); for _rp_l in "$HERE"/select-*.sh; do [ ! -f "$_rp_l" ] || _rp_sf[${#_rp_sf[@]}]="$_rp_l"; done
for _rp_l in "${_rp_sf[@]}"; do if [ ! -f "$_rp_l" ]; then _rp_w="$_rp_w ${_rp_l##*/}: missing"; else _rp_x="$(_lib_runs_nothing "$_rp_l")" || _rp_w="$_rp_w [$_rp_x]"; fi; done
is "A107: sourcing select.sh, or any select-*.sh, defines functions and does nothing else" "${_rp_w:-ok}" ok
_rp_x="$(cd "$RP0/src" && env -i PATH="$PATH" HOME="$RP0/src" "$BASH" --noprofile --norc -c 'for f; do [ -f "$f" ] && . "$f"; done >/dev/null 2>&1; compgen -A function' rp "${_rp_sf[@]}" 2>/dev/null)"
_rp_w="$(printf '%s\n' "$_rp_x" | LC_ALL=C awk 'NF { n++; if (index($0, "_tm_") != 1) b = b " " $0 } END { print (n > 0 && b == "") ? "all _tm_" : n + 0 " functions, not _tm_:" b }')"
_rp_y="$(LC_ALL=C awk '/^[ \t]*function[ \t]+_tm_/ || /^[ \t]*_tm_[^ \t(]*[ \t]*\(\)/ { printf "%s:%d ", FILENAME, FNR }' "$HERE"/parts/*.sh "$HERE"/lib/*.sh "$HERE/run" "$HERE/red" "$HERE/receipt.sh" 2>/dev/null)"
is "A108: every function select.sh and select-*.sh define starts _tm_, and no part, tests/lib file, run, red or receipt.sh defines one" "$_rp_w|$_rp_y" "all _tm_|"
unset -f $(compgen -A function _rp_) 2>/dev/null
unset $(compgen -A variable _rp_) RP0 RP RPO 2>/dev/null
# <<< testmap-report-blind
