printf '\nthe suite receipt keys on what the suite reads of origin/main (audit b08, blind)\n'
# Written blind on 2026-10-24 from the contract alone (docs/2026-10-24-audit-fixes/
# b08-change-scoped-verification-and-receipt-f.md, A34 to A60 of its section 4),
# before the fix, without reading tests/receipt.sh or anything it sources. One
# assertion per item, named "b08 A<n> (B<m>): ..."; an item that checks several
# things is one assertion whose compared value says each of them.
#
# The contract's fixtures. FR1: commit A (engine/x, docs/y), then B, a child of A
# changing docs/y, at HEAD, with origin/main at A; A_docs (A plus a docs change),
# A_eng (A plus an engine/x change) and Z (a child of B with A's tree) are made
# with mktree and commit-tree and never checked out. FR2: A (engine/x e1), A1
# (engine/x e2), then B, a child of A1 changing docs/y, at HEAD, origin/main at A;
# X, a child of A1 whose engine/x is e1 again. Commit dates are fixed, so every
# FR1 has the same commits. Each scenario is one ( ) subshell of this part that
# sources the tree's tests/receipt.sh, calls _rcp_begin, makes any mid-run move
# through _fx_git, then calls _rcp_finish <root> <record> <compared> <judged> 5
# <failed> 0 and _sr_check, with FELIX_TEST_RECORD set to <record> as the driver
# has it. Every _sr_env and _sr_check here runs in a subshell of this shell, never
# in a child bash, so the environment a receipt names is the one it is judged in.
#
# Readings taken where the text leaves room: e, a and m are computed here by the
# three git reads the contract gives, in the fixture, as the reading is taken; a
# reason line is read as _rcp_finish's whole stdout; A46's and A47's aged
# receipt is A34's as it was written; a scenario that changes the working tree has
# a repository of its own.
_b8r="$TMP/b08-receipt"; _b8rO="$_b8r/out"; mkdir -p "$_b8rO"
_b8rS="$HERE/receipt.sh"
_b8rWhy=""; [ -f "$_b8rS" ] || _b8rWhy="no tests/receipt.sh beside this suite"
_b8r_is() { if [ -z "$_b8rWhy" ]; then is "$@"; else skip "$1" "$_b8rWhy"; fi; }
_b8r_g() {
  local d="$1"
  shift
  GIT_AUTHOR_DATE='2026-10-24T00:00:00Z' GIT_COMMITTER_DATE='2026-10-24T00:00:00Z' \
    _fx_git "$d" -c user.name=b08 -c user.email=b08@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"
}
_b8r_tree() {   # dir engine/x docs/y -> a tree holding those two files
  local d="$1" bx by tx ty
  bx="$(printf '%s\n' "$2" | _b8r_g "$d" hash-object -w --stdin)" || return 1
  by="$(printf '%s\n' "$3" | _b8r_g "$d" hash-object -w --stdin)" || return 1
  tx="$(printf '100644 blob %s\tx\n' "$bx" | _b8r_g "$d" mktree)" || return 1
  ty="$(printf '100644 blob %s\ty\n' "$by" | _b8r_g "$d" mktree)" || return 1
  printf '040000 tree %s\tdocs\n040000 tree %s\tengine\n' "$ty" "$tx" | _b8r_g "$d" mktree
}
_b8r_ct() { _b8r_g "$1" commit-tree "$2" -p "$3" -m "$4" 2>/dev/null; }   # dir tree parent message -> commit
_b8r_head() { git -C "$1" rev-parse HEAD 2>/dev/null; }
_b8r_start() {   # dir engine/x docs/y: a repository whose first commit holds those
  mkdir -p "$1/engine" "$1/docs" || return 1
  printf '%s\n' "$2" > "$1/engine/x"; printf '%s\n' "$3" > "$1/docs/y"
  ( _fx_cd "$1" && git init -q -b main ) >/dev/null 2>&1
  _b8r_g "$1" add -A >/dev/null 2>&1
  _b8r_g "$1" commit -qm A >/dev/null 2>&1
}
_b8r_fr1() {   # dir: FR1, its commits in _b8rA _b8rB _b8rAd _b8rAe _b8rZ
  _b8r_start "$1" e1 y1
  _b8rA="$(_b8r_head "$1")"
  printf 'y2\n' > "$1/docs/y"
  _b8r_g "$1" commit -qam B >/dev/null 2>&1
  _b8rB="$(_b8r_head "$1")"
  _b8r_g "$1" update-ref refs/remotes/origin/main "$_b8rA" >/dev/null 2>&1
  _b8rAd="$(_b8r_ct "$1" "$(_b8r_tree "$1" e1 y-docs)" "$_b8rA" 'A docs')"
  _b8rAe="$(_b8r_ct "$1" "$(_b8r_tree "$1" e2 y1)" "$_b8rA" 'A engine')"
  _b8rZ="$(_b8r_ct "$1" "$(git -C "$1" rev-parse "$_b8rA^{tree}" 2>/dev/null)" "$_b8rB" 'Z')"
}
_b8r_origin() {   # dir commit, or - for none
  if [ "$2" = - ]; then _b8r_g "$1" update-ref -d refs/remotes/origin/main >/dev/null 2>&1
  else _b8r_g "$1" update-ref refs/remotes/origin/main "$2" >/dev/null 2>&1; fi
}
_b8r_reads() {   # dir -> e,a,m by the contract's three git reads, now
  local d="$1" e a m mb
  e="$(git -C "$d" rev-parse -q --verify refs/remotes/origin/main:engine 2>/dev/null)"; [ -n "$e" ] || e=-
  if git -C "$d" merge-base --is-ancestor HEAD refs/remotes/origin/main 2>/dev/null; then a=yes; else a=no; fi
  mb="$(git -C "$d" merge-base HEAD refs/remotes/origin/main 2>/dev/null)"
  m=""; [ -z "$mb" ] || m="$(git -C "$d" rev-parse -q --verify "$mb:engine" 2>/dev/null)"; [ -n "$m" ] || m=-
  printf '%s,%s,%s' "$e" "$a" "$m"
}
_b8r_rp() {   # dir -> its suite receipt's path
  local p
  p="$(git -C "$1" rev-parse --git-path felix-suite-receipt 2>/dev/null)"
  case "$p" in /*) ;; ?*) p="$1/$p" ;; *) p="$1/.git/felix-suite-receipt" ;; esac
  printf '%s' "$p"
}
_b8r_f() { if [ -f "$1" ]; then LC_ALL=C awk -F'\t' -v k="$2" 'NR == 1 { print $k }' "$1"; else printf '<no receipt>'; fi; }
_b8r_has() { if [ -f "$(_b8r_rp "$1")" ]; then printf 'present'; else printf 'absent'; fi; }
_b8r_chk() { ( . "$_b8rS" >/dev/null 2>&1 || exit 97; _sr_check "$1" ) 2>/dev/null; }
# Mid-run steps, run inside the scenario's subshell.
_b8r_pathx() { PATH="$PATH:$_b8r/nowhere"; }
_b8r_new() { printf 'new\n' > "$1/new.txt"; }
_b8r_edit() { printf 'y-edited\n' > "$1/docs/y"; }
# name dir record compared judged failed [step...]: one run as the driver makes it.
# Out: <name>.env (_sr_env), .finish (_rcp_finish's stdout), .check (_sr_check).
_b8rCap=""
_b8r_run() {
  local n="$1" d="$2" rec="$3" cmp="$4" jud="$5" fl="$6"
  shift 6
  ( FELIX_TEST_RECORD="$rec"
    [ -z "$_b8rCap" ] || export FELIX_UNTRACKED_CAP="$_b8rCap"
    . "$_b8rS" >/dev/null 2>&1 || exit 97
    _sr_env > "$_b8rO/$n.env" 2>/dev/null
    _rcp_begin "$d" > "$_b8rO/$n.begin" 2>&1
    [ "$#" -eq 0 ] || "$@" >/dev/null 2>&1
    _rcp_finish "$d" "$rec" "$cmp" "$jud" 5 "$fl" 0 > "$_b8rO/$n.finish" 2> "$_b8rO/$n.ferr"
    _sr_check "$d" > "$_b8rO/$n.check" 2>/dev/null )
}
_b8r_out() { cat "$_b8rO/$1.$2" 2>/dev/null; }
_b8rNW="  receipt not written: "

# ---- FR1, and A34: the reading the receipt names
_b8r1="$_b8r/r1"; _b8r_fr1 "$_b8r1"; _b8r1="$(cd "${_b8r1:?}" && pwd -P)"
_b8r1A="$_b8rA"; _b8r1Ad="$_b8rAd"; _b8r1Ae="$_b8rAe"; _b8r1Z="$_b8rZ"
_b8r1P="$(_b8r_rp "$_b8r1")"
_b8r_run a34 "$_b8r1" 0 1 0 0
_b8r1R="$(_b8r_reads "$_b8r1")"
cp "$_b8r1P" "$_b8rO/a34.receipt" 2>/dev/null
_b8r1E="$(_b8r_out a34 env)"; _b8r1End="$(_b8r_f "$_b8r1P" 9)"
_b8r_is "b08 A34 (B13): a run that began at A leaves field 7 <_sr_env>;reads=<e>,<a>,<m>;origin=<A>, the reading and the commit both from its start" \
   "$(_b8r_f "$_b8r1P" 7)" "$_b8r1E;reads=$_b8r1R;origin=$_b8r1A"
_b8r_origin "$_b8r1" "$_b8r1Ad"
_b8r_is "b08 A35 (B14): origin/main moved to A_docs, a move that changes none of e, a and m, leaves the receipt standing: reuse" \
   "$(_b8r_chk "$_b8r1")" "reuse 5 0 0 $_b8r1End normal"
_b8r_origin "$_b8r1" "$_b8r1Ae"
_b8r_is "b08 A36 (B15): origin/main moved to A_eng, whose engine/ tree differs, is refused: run origin/main moved (control)" \
   "$(_b8r_chk "$_b8r1")" "run origin/main moved"
_b8r_origin "$_b8r1" "$_b8r1Z"
_b8r_is "b08 A37 (B15): origin/main moved to Z, so that HEAD became its ancestor, is refused: run origin/main moved (control)" \
   "$(_b8r_chk "$_b8r1")" "run origin/main moved"

# ---- FR2, A38: the engine tree at the merge base changed, origin/main's did not
_b8r2="$_b8r/r2"; _b8r_start "$_b8r2" e1 y1; _b8r2="$(cd "${_b8r2:?}" && pwd -P)"
_b8r2A="$(_b8r_head "$_b8r2")"
printf 'e2\n' > "$_b8r2/engine/x"; _b8r_g "$_b8r2" commit -qam A1 >/dev/null 2>&1
_b8r2A1="$(_b8r_head "$_b8r2")"
printf 'y2\n' > "$_b8r2/docs/y"; _b8r_g "$_b8r2" commit -qam B >/dev/null 2>&1
_b8r_origin "$_b8r2" "$_b8r2A"
_b8r2X="$(_b8r_ct "$_b8r2" "$(_b8r_tree "$_b8r2" e1 y1)" "$_b8r2A1" 'X')"
_b8r_run a38 "$_b8r2" 0 1 0 0
_b8r_origin "$_b8r2" "$_b8r2X"
if [ "$(git -C "$_b8r2" rev-parse -q --verify "$_b8r2X:engine" 2>/dev/null)" = "$(git -C "$_b8r2" rev-parse -q --verify "$_b8r2A:engine" 2>/dev/null)" ]; then
  _b8rV="$(_b8r_chk "$_b8r2")"
else _b8rV="<the fixture's X does not hold A's engine/ tree>"; fi
_b8r_is "b08 A38 (B15): FR2, origin/main moved to X, whose engine/ tree is A's but whose merge base with HEAD moved: run origin/main moved (control)" \
   "$_b8rV" "run origin/main moved"

# ---- A39 to A42, on FR1
_b8r_origin "$_b8r1" -
_b8r_is "b08 A39 (B15): origin/main named a commit when the receipt was written and names none now: run origin/main moved (control)" \
   "$(_b8r_chk "$_b8r1")" "run origin/main moved"
_b8r_run a40 "$_b8r1" 0 1 0 0
_b8rV="$(_b8r_f "$_b8r1P" 7)"; [ "$_b8rV" = "$(_b8r_out a40 env)" ] && _b8rV="_sr_env alone"
_b8r_origin "$_b8r1" "$_b8r1A"
_b8r_is "b08 A40 (B13, B15): a run with no origin/main writes field 7 as _sr_env alone, and once origin/main names A it is refused (control)" \
   "field 7 $_b8rV; then $(_b8r_chk "$_b8r1")" "field 7 _sr_env alone; then run origin/main moved"
# A receipt in today's form, written by hand as part 1260 writes one.
_b8rT="$( ( . "$_b8rS" >/dev/null 2>&1; _sr_tree "$_b8r1" ) 2>/dev/null)"
_b8rE="$( ( . "$_b8rS" >/dev/null 2>&1; _sr_env ) 2>/dev/null)"
_b8rV="$( ( . "$_b8rS" >/dev/null 2>&1; _sr_origin "$_b8r1" ) 2>/dev/null)"
[ -n "$_b8rV" ] && [ "$_b8rV" != - ] && _b8rE="$_b8rE;origin=$_b8rV"
_b8rEnd=$(( $(date +%s) - 100 ))
printf 'v1\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "${_b8rT:-<no tree id>}" normal 5 0 0 "$_b8rE" "$((_b8rEnd - 60))" "$_b8rEnd" > "$_b8r1P"
_b8r_is "b08 A41 (B16): a receipt in today's form, ;origin=<A> and no ;reads=, is reused while origin/main names A (control)" \
   "$(_b8r_chk "$_b8r1")" "reuse 5 0 0 $_b8rEnd normal"
_b8r_origin "$_b8r1" "$_b8r1Ad"
_b8r_is "b08 A42 (B16): and the same receipt is refused once origin/main names A_docs, as today: run origin/main moved (control)" \
   "$(_b8r_chk "$_b8r1")" "run origin/main moved"

# ---- A43 to A47: A34's receipt, edited
_b8r_put() {   # field-7: A34's receipt with that field 7, as FR1's receipt; 1 when there is none to edit
  [ -f "$_b8rO/a34.receipt" ] || return 1
  B8R_F7="$1" LC_ALL=C awk -F'\t' -v OFS='\t' 'NR == 1 { $7 = ENVIRON["B8R_F7"] } { print }' "$_b8rO/a34.receipt" > "$_b8r1P"
}
_b8r_edited() {   # field-7 -> _sr_check's answer on A34's receipt carrying it
  if _b8r_put "$1"; then _b8r_chk "$_b8r1"; else printf '<no A34 receipt to edit>'; fi
}
_b8r_origin "$_b8r1" "$_b8r1A"
_b8rM="${_b8r1R#*,}"; _b8rM="${_b8rM#*,}"; _b8rAa="${_b8r1R#*,}"; _b8rAa="${_b8rAa%%,*}"; _b8rEe="${_b8r1R%%,*}"
_b8r_is "b08 A43 (B17): A34's field 7 with e set to zz is run malformed receipt" \
   "$(_b8r_edited "$_b8r1E;reads=zz,$_b8rAa,$_b8rM;origin=$_b8r1A")" "run malformed receipt"
_b8r_is "b08 A44 (B17): A34's field 7 with a set to maybe is run malformed receipt" \
   "$(_b8r_edited "$_b8r1E;reads=$_b8rEe,maybe,$_b8rM;origin=$_b8r1A")" "run malformed receipt"
_b8r_is "b08 A45 (B17): A34's field 7 with the ;origin= tail cut is run malformed receipt" \
   "$(_b8r_edited "$_b8r1E;reads=$_b8r1R")" "run malformed receipt"
_b8r_aged() {   # -> _sr_check on A34's receipt with fields 8 and 9 moved back 50000 s
  [ -f "$_b8rO/a34.receipt" ] || { printf '<no A34 receipt to age>'; return 0; }
  LC_ALL=C awk -F'\t' -v OFS='\t' 'NR == 1 { $8 = $8 - 50000; $9 = $9 - 50000 } { print }' "$_b8rO/a34.receipt" > "$_b8r1P"
  _b8r_chk "$_b8r1"
}
_b8r_origin "$_b8r1" "$_b8r1Ad"
_b8r_is "b08 A46 (B18): A34's receipt aged past 12 hours, origin/main at A_docs and the reading unmoved: run older than 12 hours" \
   "$(_b8r_aged)" "run older than 12 hours"
_b8r_origin "$_b8r1" "$_b8r1Ae"
_b8r_is "b08 A47 (B18): the same aged receipt with origin/main at A_eng answers the origin check first: run origin/main moved (control)" \
   "$(_b8r_aged)" "run origin/main moved"

# ---- A48 to A58: what _rcp_finish writes and says
_b8r_origin "$_b8r1" "$_b8r1A"
_b8r_run a48 "$_b8r1" 0 1 0 0 _b8r_origin "$_b8r1" "$_b8r1Ad"
_b8rV="$(_b8r_f "$_b8r1P" 7)"
[ "${_b8rV%;origin=$_b8r1A}" != "$_b8rV" ] && _b8rV="ends ;origin=<A>"
_b8r_is "b08 A48 (B19): origin/main moved to A_docs during the run: the receipt is written, naming the start commit, and _sr_check reuses it" \
   "receipt $(_b8r_has "$_b8r1"); field 7 $_b8rV; $(_b8r_out a48 check)" \
   "receipt present; field 7 ends ;origin=<A>; reuse 5 0 0 $(_b8r_f "$_b8r1P" 9) normal"
_b8r_origin "$_b8r1" "$_b8r1A"
_b8r_run a49 "$_b8r1" 0 1 0 0 _b8r_origin "$_b8r1" "$_b8r1Ae"
_b8r_is "b08 A49 (B20, reason 5): origin/main moved to A_eng during the run: stdout is exactly the one reason line, and there is no receipt" \
   "[$(_b8r_out a49 finish)] receipt $(_b8r_has "$_b8r1")" "[${_b8rNW}origin/main moved during the run] receipt absent"
_b8r_origin "$_b8r1" "$_b8r1A"
_b8r_run a50 "$_b8r1" 0 1 0 2
_b8r_is "b08 A50 (B20, reason 1): a run with failures says receipt not written: the run had failures" \
   "$(_b8r_out a50 finish)" "${_b8rNW}the run had failures"
_b8r_run a51 "$_b8r1" 0 0 0 0
_b8r_is "b08 A51 (B20, reason 2): a run whose manifest was not compared says receipt not written: the manifest was not compared" \
   "$(_b8r_out a51 finish)" "${_b8rNW}the manifest was not compared"
_b8r52="$_b8r/r52"; _b8r_fr1 "$_b8r52"; _b8r52="$(cd "${_b8r52:?}" && pwd -P)"
printf 'u1\n' > "$_b8r52/u1.txt"; printf 'u2\n' > "$_b8r52/u2.txt"
_b8rCap=1; _b8r_run a52 "$_b8r52" 0 1 0 0; _b8rCap=""
_b8r_is "b08 A52 (B20, reason 3): FELIX_UNTRACKED_CAP=1 with two untracked files says receipt not written: the tree could not be read when the run began" \
   "$(_b8r_out a52 finish)" "${_b8rNW}the tree could not be read when the run began"
_b8r_run a53 "$_b8r1" 0 1 0 0 _b8r_pathx
_b8r_is "b08 A53 (B20, reason 4): PATH extended during the run says receipt not written: the environment changed during the run" \
   "$(_b8r_out a53 finish)" "${_b8rNW}the environment changed during the run"
_b8r_run a54 "$_b8r1" 1 1 0 0
_b8r_is "b08 A54 (B20, reason 6): a record run whose record was not judged says receipt not written: the record this run wrote was not judged" \
   "$(_b8r_out a54 finish)" "${_b8rNW}the record this run wrote was not judged"
_b8r55="$_b8r/r55"; _b8r_fr1 "$_b8r55"; _b8r55="$(cd "${_b8r55:?}" && pwd -P)"
_b8r_run a55 "$_b8r55" 0 1 0 0 _b8r_new "$_b8r55"
_b8r_is "b08 A55 (B20, reason 8): a normal run during which an untracked file appears says receipt not written: the tree changed during the run" \
   "$(_b8r_out a55 finish)" "${_b8rNW}the tree changed during the run"
_b8r56="$_b8r/r56"; _b8r_fr1 "$_b8r56"; _b8r56="$(cd "${_b8r56:?}" && pwd -P)"
_b8r_run a56 "$_b8r56" 1 1 1 0 _b8r_edit "$_b8r56"
_b8r_is "b08 A56 (B20, reason 8): a judged record run during which docs/y is edited says the tree changed during the run, beyond the manifest and red.tsv" \
   "$(_b8r_out a56 finish)" "${_b8rNW}the tree changed during the run, beyond the manifest and red.tsv"
_b8r_run a57 "$_b8r1" 0 1 0 2 _b8r_pathx
_b8r_is "b08 A57 (B20): failures and a changed PATH together say only the first reason: the run had failures" \
   "$(_b8r_out a57 finish)" "${_b8rNW}the run had failures"
_b8r_run a58 "$_b8r1" 0 1 0 0
_b8r_is "b08 A58 (B20): a clean pass prints no receipt not written line and leaves a receipt (control)" \
   "$(_b8r_out a58 finish | LC_ALL=C awk 'index($0, "receipt not written") { n++ } END { print n + 0 }') lines; receipt $(_b8r_has "$_b8r1")" \
   "0 lines; receipt present"

# ---- A59: the bridge (C10) across a move of origin/main the reading does not see
_b8r59="$_b8r/r59"; _b8r_fr1 "$_b8r59"; _b8r59="$(cd "${_b8r59:?}" && pwd -P)"
_b8r_edit "$_b8r59"
_b8r_run a59 "$_b8r59" 0 1 0 0
_b8rEnd="$(_b8r_f "$(_b8r_rp "$_b8r59")" 9)"
_b8r_g "$_b8r59" commit -qam record >/dev/null 2>&1
_b8r_origin "$_b8r59" "$_b8rAd"
_b8r_is "b08 A59 (B21): a receipt written over an uncommitted docs/y edit stands once that edit is committed and origin/main moves to A_docs: reuse with HEAD's sha" \
   "$(_b8r_chk "$_b8r59")" "reuse 5 0 0 $_b8rEnd normal $(_b8r_head "$_b8r59")"

# ---- A60: the header's false sentence is gone
# The contract's grep -cF reads one line at a time, and on 69b51a61 the sentence is
# wrapped across two comment lines, so that grep alone prints 0 before the fix
# too (found when this part was first run, by grepping for the sentence). The
# same assertion also counts it with the comment markers taken off and the lines
# joined, which is what B22's "no longer says" asks.
_b8rN60="b08 A60 (B22): tests/receipt.sh no longer says GitHub CI still runs the whole suite on Linux before anything merges, on one line or wrapped"
_b8rS60='GitHub CI still runs the whole suite on Linux before anything merges'
if [ -f "$REAL_HARNESS/tests/receipt.sh" ]; then
  _b8rL="$(grep -cF "$_b8rS60" "$REAL_HARNESS/tests/receipt.sh")"
  _b8rJ="$(B8R_S="$_b8rS60" LC_ALL=C awk '{ sub(/^[ \t]*#[ \t]*/, ""); j = j " " $0 }
    END { gsub(/[ \t]+/, " ", j); s = ENVIRON["B8R_S"]; n = 0
          while ((i = index(j, s)) > 0) { n++; j = substr(j, i + length(s)) }
          print n }' "$REAL_HARNESS/tests/receipt.sh")"
  is "$_b8rN60" "${_b8rL:-?} on one line, ${_b8rJ:-?} across lines" "0 on one line, 0 across lines"
else
  skip "$_b8rN60" "no tests/receipt.sh beside this harness"
fi
