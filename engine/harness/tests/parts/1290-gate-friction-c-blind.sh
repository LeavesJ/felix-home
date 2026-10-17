# >>> gate-friction-c-blind
printf '\ngate friction C: the suite reads tests/lib, and nothing in it runs when sourced (blind)\n'
# Blind, written on 2026-10-16 from contract C alone (docs/2026-10-16-gate-
# friction-contract-c.md, C2 and C3) and the interface decided for it, before
# any implementation existed. Nothing here was read off one. The interface:
#
# - tests/run sources every tests/lib/*.sh by one line, . "$HERE/lib/NAME.sh",
#   in LC_ALL=C name order, all of them between the line sourcing
#   parts/0005-fixture-floor.sh and the line sourcing parts/0010-resolution.sh,
#   and no line names a file that is not there;
# - _suite_files, in the driver or a prelude part, prints the path of the
#   driver, of every tests/parts/*.sh and of every tests/lib/*.sh, one a line,
#   and nothing else;
# - _suite_src prints the text of every part, every lib file and the driver;
#   _suite_flat gives the driver with each part line and each lib line
#   replaced by the text of the file it names;
# - _lib_runs_nothing FILE sources FILE in a subshell, in a scratch directory
#   standing in for $TMP, with TMP, FROOT, MEM and REPO pointed under it, and
#   returns 0 only when that printed nothing, created, changed or removed
#   nothing under the scratch directory and left PASS, FAIL and SKIP as they
#   were; otherwise 1, with one line naming FILE and what it did.
#
# Readings taken where the interface leaves room. The lib-line check below is
# this part's own function, run on the real driver and on planted copies of it,
# so a planted copy proves the same code bites. A lib line is one whole line of
# exactly that form; any other spelling is not a line for the file. Paths
# _suite_files prints are compared as files, with their directories resolved
# physically, in no particular order. A copy of the tree is pointed at the way
# _suite_src and _suite_flat read today, HERE and REAL_HARNESS both, in a
# subshell with a TMP of its own, so _suite_flat's cache under $TMP is the
# copy's and not this run's. Each planted file for _lib_runs_nothing does one
# thing, silently where the thing is not printing, so it is caught for that
# thing: the ok case's output is thrown away, so only PASS can give it away.
# Its git init goes through _fx_git, as every fixture git write does, so it
# runs only where the scratch directory lies below a fixture root such as
# $TMP; elsewhere _fx_git refuses it, the record makes the run's end red, and
# the case reads as not caught. Those calls run in a subshell of this part's
# whose FELIX_TEST_RAN is a sink of its own, so a planted ok never reaches the
# run's list of names.
#
# Before the implementation, the lib-line checks pass (the real tree has no
# lib and no lib line, and the planted copies test this part's own check); the
# rest FAIL, and the check of the real lib files skips, saying there are none.
GCI="$TMP/gci"; mkdir -p "$GCI"
GCI_NO="no function by that name in the prelude"

# ---- (a) and (b): the driver's lib lines
# <driver> <lib dir>: silent, status 0, when the driver sources each
# <lib dir>/*.sh, as ls lists them, by one line, in LC_ALL=C name order, every
# such line after the line sourcing part 0005 and before the line sourcing
# part 0010, and no such line names a file that is not there. Otherwise one
# line a problem, and status 1.
_gci_lib_lines() {
  local want=""
  if [ -n "${2:-}" ] && [ -d "$2" ]; then
    want="$(cd "$2" && LC_ALL=C ls | LC_ALL=C awk '/\.sh$/' | LC_ALL=C sort)"
  fi
  [ -n "${1:-}" ] && [ -f "$1" ] || { printf 'no driver at [%s]\n' "${1:-}"; return 1; }
  GCI_WANT="$want" LC_ALL=C awk '
    BEGIN {
      k = split(ENVIRON["GCI_WANT"], w, "\n")
      for (i = 1; i <= k; i++) if (w[i] != "") { want[++nw] = w[i]; there[w[i]] = 1 }
      A5 = ". \"$HERE/parts/0005-fixture-floor.sh\""; A10 = ". \"$HERE/parts/0010-resolution.sh\""
    }
    $0 == A5  { n5++;  at5 = FNR }
    $0 == A10 { n10++; at10 = FNR }
    /^\. "\$HERE\/lib\/[^"]*"$/ { g++; got[g] = substr($0, 14, length($0) - 14); at[g] = FNR; cnt[got[g]]++ }
    END {
      if (n5 != 1)  { print "the driver has " (n5 + 0) " lines sourcing parts/0005-fixture-floor.sh, not one"; bad = 1 }
      if (n10 != 1) { print "the driver has " (n10 + 0) " lines sourcing parts/0010-resolution.sh, not one"; bad = 1 }
      for (i = 1; i <= nw; i++) if (!(want[i] in cnt)) { print "no line sources lib/" want[i]; bad = 1 }
      for (i = 1; i <= g; i++) {
        n = got[i]
        if (!(n in there)) { print "line " at[i] " sources lib/" n ", which is not there"; bad = 1 }
        else if (cnt[n] > 1 && !(n in said)) { said[n] = 1; print "lib/" n " is sourced by " cnt[n] " lines, not one"; bad = 1 }
        if (n5 == 1 && at[i] < at5) { print "line " at[i] " sources lib/" n " before the line sourcing parts/0005-fixture-floor.sh, line " at5; bad = 1 }
        if (n10 == 1 && at[i] > at10) { print "line " at[i] " sources lib/" n " after the line sourcing parts/0010-resolution.sh, line " at10; bad = 1 }
      }
      if (!bad) for (i = 1; i <= g; i++) if (got[i] != want[i]) {
        print "the lib lines are out of name order: line " at[i] " sources lib/" got[i] " where lib/" want[i] " comes next by name"
        bad = 1; break
      }
      exit bad
    }' "$1"
}
_gci_o="$(_gci_lib_lines "$HERE/run" "$HERE/lib")"; _gci_rc=$?
_gci_n="the driver sources every tests/lib/*.sh by one line each, in name order, between the lines sourcing parts 0005 and 0010, and no line names a lib file that is not there"
if [ "$_gci_rc" -eq 0 ]; then ok "$_gci_n"
else bad "$_gci_n" "the check returned $_gci_rc: $(LC_ALL=C tr '\n' ' ' <<<"$_gci_o")"; fi

# Planted copies: the real driver with its own lib lines dropped and lines for
# three planted lib files, gci-a.sh, gci-b.sh and gci-c.sh, put where a case
# says, against a lib directory that holds just those three.
GCI_PL="$GCI/plant-lib"; mkdir -p "$GCI_PL"
: > "$GCI_PL/gci-a.sh"; : > "$GCI_PL/gci-b.sh"; : > "$GCI_PL/gci-c.sh"
_gci_plant() {   # <out> <lib names before the 0005 line> <after it> <after the 0010 line>
  GCI_B="$2" GCI_W="$3" GCI_A="$4" LC_ALL=C awk '
    function put(list,   n, i, w) { n = split(list, w, " "); for (i = 1; i <= n; i++) print ". \"$HERE/lib/" w[i] "\"" }
    /^\. "\$HERE\/lib\/[^"]*"$/ { next }
    $0 == ". \"$HERE/parts/0005-fixture-floor.sh\"" { put(ENVIRON["GCI_B"]); print; put(ENVIRON["GCI_W"]); next }
    $0 == ". \"$HERE/parts/0010-resolution.sh\"" { print; put(ENVIRON["GCI_A"]); next }
    { print }' "$HERE/run" > "$1"
}
_gci_bites() {   # <assertion name> <words the reason must hold> <before 0005> <after 0005> <after 0010>
  local o rc
  _gci_plant "$GCI/plant-run" "$3" "$4" "$5"
  o="$(_gci_lib_lines "$GCI/plant-run" "$GCI_PL")"; rc=$?
  case "$rc|$o" in
    "1|"*"$2"*) ok "$1" ;;
    *) bad "$1" "the check returned $rc and said [$(LC_ALL=C tr '\n' ' ' <<<"$o")]; a defect wants 1 and a reason holding [$2]" ;;
  esac
}
_gci_plant "$GCI/plant-run" "" "gci-a.sh gci-b.sh gci-c.sh" ""
_gci_o="$(_gci_lib_lines "$GCI/plant-run" "$GCI_PL")"; _gci_rc=$?
is  "the lib-line check passes a planted copy of the driver whose three lib files have one line each, in name order, inside the window (control)" \
    "$_gci_rc|$_gci_o" "0|"
_gci_bites "the lib-line check catches, in a planted copy of the driver, a lib file with no line" \
    "no line sources lib/gci-b.sh" "" "gci-a.sh gci-c.sh" ""
_gci_bites "the lib-line check catches, in a planted copy of the driver, a line naming a lib file that is not there" \
    "lib/gci-d-gone.sh, which is not there" "" "gci-a.sh gci-b.sh gci-c.sh gci-d-gone.sh" ""
_gci_bites "the lib-line check catches, in a planted copy of the driver, two lib lines out of name order" \
    "out of name order" "" "gci-b.sh gci-a.sh gci-c.sh" ""
_gci_bites "the lib-line check catches, in a planted copy of the driver, a lib line after the line sourcing part 0010" \
    "sources lib/gci-c.sh after the line sourcing parts/0010-resolution.sh" "" "gci-a.sh gci-b.sh" "gci-c.sh"
_gci_bites "the lib-line check catches, in a planted copy of the driver, a lib line before the line sourcing part 0005" \
    "sources lib/gci-a.sh before the line sourcing parts/0005-fixture-floor.sh" "gci-a.sh" "gci-b.sh gci-c.sh" ""
_gci_bites "the lib-line check catches, in a planted copy of the driver, a lib file sourced by two lines" \
    "lib/gci-b.sh is sourced by 2 lines" "" "gci-a.sh gci-b.sh gci-b.sh gci-c.sh" ""

# ---- (c): _suite_files
# Paths on stdin, one a line -> each with its directory made physical, a
# relative one read from where the shell stands. One fork per directory met.
_gci_canon() {
  local p d b last="" lastp="" pd
  while IFS= read -r p; do
    case "$p" in /*) ;; *) p="$PWD/$p" ;; esac
    d="${p%/*}"; b="${p##*/}"
    if [ -n "$last" ] && [ "$d" = "$last" ]; then pd="$lastp"
    else
      pd="$(cd -P -- "${d:-/}" 2>/dev/null && pwd -P)" || pd="(no directory ${d:-/})"
      last="$d"; lastp="$pd"
    fi
    printf '%s/%s\n' "$pd" "$b"
  done
}
_gci_want_files() {   # <tests dir>: its driver, every parts/*.sh and every lib/*.sh, one path a line
  local f
  printf '%s\n' "$1/run"
  for f in "$1"/parts/*.sh "$1"/lib/*.sh; do [ -f "$f" ] && printf '%s\n' "$f"; done
  return 0
}
_gci_same() {   # <assertion name> <got> <want>, files of lines sorted in C: ok when they are the same lines
  local m x
  if cmp -s "$2" "$3"; then ok "$1"; return 0; fi
  m="$(LC_ALL=C comm -13 "$2" "$3" | head -3 | cut -c1-160 | LC_ALL=C tr '\n' ' ')"
  x="$(LC_ALL=C comm -23 "$2" "$3" | head -3 | cut -c1-160 | LC_ALL=C tr '\n' ' ')"
  bad "$1" "$(LC_ALL=C comm -13 "$2" "$3" | wc -l | tr -d ' ') line(s) missing, the first [$m]; $(LC_ALL=C comm -23 "$2" "$3" | wc -l | tr -d ' ') extra, the first [$x]"
}
_gci_want_files "$HERE" | _gci_canon | LC_ALL=C sort > "$GCI/files.want"
_gci_n="_suite_files lists exactly the driver, every tests/parts/*.sh and every tests/lib/*.sh, one path a line, as ls finds them"
if declare -F _suite_files >/dev/null; then
  _suite_files 2>/dev/null | _gci_canon | LC_ALL=C sort > "$GCI/files.got"
  _gci_same "$_gci_n" "$GCI/files.got" "$GCI/files.want"
else
  bad "$_gci_n" "_suite_files: $GCI_NO"
fi

# The copy: this tree's tests directory, then a lib file planted in it with
# its line in the driver, last in the window, and beside it a file in lib that
# is not a .sh. The planted file's first line holds a value made at run time,
# so no file of the tree holds it, this one included.
GCI_T="$GCI/tree/tests"; GCI_PN="zz-gci-planted.sh"; GCI_NONCE="$$.$RANDOM.$RANDOM"
GCI_MARK="# gci planted lib file $GCI_NONCE: one definition and one plain assignment"
_copy_content "$HERE" "$GCI_T"; mkdir -p "$GCI_T/lib"
printf '%s\n_gci_planted_fn() { :; }\n_gci_planted_var=planted\n' "$GCI_MARK" > "$GCI_T/lib/$GCI_PN"
printf 'not a lib file\n' > "$GCI_T/lib/gci-planted-notes.txt"
GCI_PN="$GCI_PN" LC_ALL=C awk '$0 == ". \"$HERE/parts/0010-resolution.sh\"" { print ". \"$HERE/lib/" ENVIRON["GCI_PN"] "\"" } { print }' \
  "$GCI_T/run" > "$GCI/run.planted" && cat "$GCI/run.planted" > "$GCI_T/run"
mkdir -p "$GCI/tmp-files" "$GCI/tmp-src" "$GCI/tmp-flat"
GCI_PP="$(printf '%s\n' "$GCI_T/lib/$GCI_PN" | _gci_canon)"
_gci_n1="_suite_files, pointed at a copy of the tree, lists a lib file planted in the copy"
_gci_n2="and lists exactly that copy's driver, parts and lib files, leaving out a file in lib that is not a .sh"
if declare -F _suite_files >/dev/null; then
  ( HERE="$GCI_T"; REAL_HARNESS="${GCI_T%/tests}"; TMP="$GCI/tmp-files"; _suite_files ) 2>/dev/null \
    | _gci_canon | LC_ALL=C sort > "$GCI/copy-files.got"
  if LC_ALL=C grep -qxF -e "$GCI_PP" "$GCI/copy-files.got"; then ok "$_gci_n1"
  else bad "$_gci_n1" "[$GCI_PP] is not among the $(LC_ALL=C awk 'END { print NR }' "$GCI/copy-files.got") path(s) it printed"; fi
  _gci_want_files "$GCI_T" | _gci_canon | LC_ALL=C sort > "$GCI/copy-files.want"
  _gci_same "$_gci_n2" "$GCI/copy-files.got" "$GCI/copy-files.want"
else
  bad "$_gci_n1" "_suite_files: $GCI_NO"; bad "$_gci_n2" "_suite_files: $GCI_NO"
fi
rm -f "$GCI_T/lib/gci-planted-notes.txt"

# ---- (d): _suite_src and _suite_flat, in the same copy
_gci_n1="_suite_src, pointed at a copy of the tree, prints the text of a lib file planted there"
_gci_n2="and prints exactly the copy's driver, parts and lib files, line for line, in whatever order"
if declare -F _suite_src >/dev/null; then
  ( HERE="$GCI_T"; REAL_HARNESS="${GCI_T%/tests}"; TMP="$GCI/tmp-src"; _suite_src ) > "$GCI/src.out" 2>/dev/null
  _gci_c="$(LC_ALL=C grep -cxF -e "$GCI_MARK" "$GCI/src.out")"
  [ "${_gci_c:-0}" -ge 1 ] 2>/dev/null && ok "$_gci_n1" \
    || bad "$_gci_n1" "the planted file's first line is not in the $(LC_ALL=C awk 'END { print NR }' "$GCI/src.out") line(s) it printed"
  LC_ALL=C sort "$GCI/src.out" > "$GCI/src.got"
  cat "$GCI_T/run" "$GCI_T"/parts/*.sh "$GCI_T"/lib/*.sh | LC_ALL=C sort > "$GCI/src.want"
  _gci_same "$_gci_n2" "$GCI/src.got" "$GCI/src.want"
else
  bad "$_gci_n1" "_suite_src: $GCI_NO"; bad "$_gci_n2" "_suite_src: $GCI_NO"
fi
# The copy's driver with each part line and each lib line replaced by the
# text of the file it names, built here on its own, to compare whole.
LC_ALL=C awk -v d="$GCI_T/" '
  /^\. "\$HERE\/parts\/[^"\/]+"$/ { f = d "parts/" substr($0, 16, length($0) - 16) }
  /^\. "\$HERE\/lib\/[^"\/]+"$/   { f = d "lib/" substr($0, 14, length($0) - 14) }
  f != "" { while ((getline l < f) > 0) print l; close(f); f = ""; next }
  { print }' "$GCI_T/run" > "$GCI/flat.want"
_gci_n1="_suite_flat, pointed at a copy of the tree with a TMP of its own, holds the text of a lib file planted and sourced there"
_gci_n2="and is exactly the copy's driver with each part line and each lib line replaced by the text of the file it names"
if declare -F _suite_flat >/dev/null; then
  ( HERE="$GCI_T"; REAL_HARNESS="${GCI_T%/tests}"; TMP="$GCI/tmp-flat"
    _gci_f="$(_suite_flat)" || exit 1; cat "$_gci_f" ) > "$GCI/flat.out" 2>/dev/null; _gci_rc=$?
  _gci_c="$(LC_ALL=C grep -cxF -e "$GCI_MARK" "$GCI/flat.out")"
  if [ "$_gci_rc" -ne 0 ]; then bad "$_gci_n1" "_suite_flat returned non-zero for the copy"
  elif [ "${_gci_c:-0}" -ge 1 ] 2>/dev/null; then ok "$_gci_n1"
  else bad "$_gci_n1" "the planted file's first line is not in it; the line sourcing it reads [$(LC_ALL=C grep -cF -e "lib/$GCI_PN" "$GCI/flat.out")] time(s)"; fi
  if [ "$_gci_rc" -eq 0 ] && cmp -s "$GCI/flat.out" "$GCI/flat.want"; then ok "$_gci_n2"
  else bad "$_gci_n2" "status $_gci_rc; $(cmp "$GCI/flat.out" "$GCI/flat.want" 2>&1 | head -1)"; fi
else
  bad "$_gci_n1" "_suite_flat: $GCI_NO"; bad "$_gci_n2" "_suite_flat: $GCI_NO"
fi

# ---- (e): _lib_runs_nothing on planted lib files
GCI_L="$GCI/lrn"; mkdir -p "$GCI_L"; : > "$GCI/lrn-ran"
cat > "$GCI_L/gci-lrn-clean.sh" <<'GCI_LRN_CLEAN'
# planted: definitions and plain assignments, nothing that runs
_gci_lrn_fn() {
  printf 'gci: _gci_lrn_fn ran, which only a call does\n'
  mkdir -p "$TMP/gci-lrn-fn-ran"
  ok "gci: _gci_lrn_fn ran"
}
_gci_lrn_var="a plain value"
_gci_lrn_two='one two'
_gci_lrn_three=3
GCI_LRN_CLEAN
cat > "$GCI_L/gci-lrn-prints.sh" <<'GCI_LRN_PRINTS'
printf 'gci: a line printed at source time\n'
GCI_LRN_PRINTS
cat > "$GCI_L/gci-lrn-writes.sh" <<'GCI_LRN_WRITES'
{ printf 'gci\n' > "$TMP/gci-lrn-written"; } 2>/dev/null
GCI_LRN_WRITES
cat > "$GCI_L/gci-lrn-mkdir.sh" <<'GCI_LRN_MKDIR'
mkdir "$TMP/gci-lrn-made" 2>/dev/null
GCI_LRN_MKDIR
cat > "$GCI_L/gci-lrn-ok.sh" <<'GCI_LRN_OK'
ok "gci: an ok called at source time" >/dev/null 2>&1
GCI_LRN_OK
cat > "$GCI_L/gci-lrn-git-init.sh" <<'GCI_LRN_GIT'
_fx_git "$TMP" init -q >/dev/null 2>&1
GCI_LRN_GIT

_gci_n1="_lib_runs_nothing returns 0 for a lib file that holds only definitions and plain assignments"
_gci_n2="_lib_runs_nothing leaves its caller as it was: no function or variable from the file, and TMP, FROOT, MEM and REPO unchanged"
if declare -F _lib_runs_nothing >/dev/null; then
  _gci_was="${TMP-}|${FROOT-}|${MEM-}|${REPO-}"
  _lib_runs_nothing "$GCI_L/gci-lrn-clean.sh" > "$GCI/lrn.clean" 2>&1; _gci_rc=$?
  [ "$_gci_rc" -eq 0 ] && ok "$_gci_n1" \
    || bad "$_gci_n1" "it returned $_gci_rc and said [$(head -3 "$GCI/lrn.clean" | LC_ALL=C tr '\n' ' ')]"
  _gci_v="$(declare -F _gci_lrn_fn >/dev/null && printf 'the function is defined; ')$([ -n "${_gci_lrn_var+x}" ] && printf 'the variable is set; ')"
  [ "${TMP-}|${FROOT-}|${MEM-}|${REPO-}" = "$_gci_was" ] || _gci_v="${_gci_v}TMP|FROOT|MEM|REPO went from [$_gci_was] to [${TMP-}|${FROOT-}|${MEM-}|${REPO-}]"
  [ -z "$_gci_v" ] && ok "$_gci_n2" || bad "$_gci_n2" "$_gci_v"
else
  bad "$_gci_n1" "_lib_runs_nothing: $GCI_NO"; bad "$_gci_n2" "_lib_runs_nothing: $GCI_NO"
fi
# <assertion name> <planted file>: it returns 1 and prints one line, which
# names the file. Run in a subshell whose FELIX_TEST_RAN is a sink.
_gci_caught() {
  local o="$GCI/lrn.out.${2##*/}" rc lines named v
  if ! declare -F _lib_runs_nothing >/dev/null; then bad "$1" "_lib_runs_nothing: $GCI_NO"; return 0; fi
  ( FELIX_TEST_RAN="$GCI/lrn-ran"; _lib_runs_nothing "$2" ) > "$o" 2>&1; rc=$?
  lines="$(LC_ALL=C awk 'END { print NR }' "$o")"
  if LC_ALL=C grep -qF -e "${2##*/}" "$o"; then named="names the file"; else named="does not name the file"; fi
  v="$rc|$lines line(s)|$named"
  [ "$v" = "1|1 line(s)|names the file" ] && ok "$1" \
    || bad "$1" "status|lines|naming: [$v], wanted [1|1 line(s)|names the file]; it said [$(head -3 "$o" | LC_ALL=C tr '\n' ' ')]"
}
_gci_caught "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that prints a line when sourced" \
    "$GCI_L/gci-lrn-prints.sh"
_gci_caught "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that silently writes a file under TMP when sourced" \
    "$GCI_L/gci-lrn-writes.sh"
_gci_caught "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that silently creates a directory when sourced" \
    "$GCI_L/gci-lrn-mkdir.sh"
_gci_caught "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that calls ok when sourced, its output thrown away" \
    "$GCI_L/gci-lrn-ok.sh"
_gci_caught "_lib_runs_nothing returns 1 and prints one line naming the file, for a lib file that silently runs git init in the scratch directory when sourced" \
    "$GCI_L/gci-lrn-git-init.sh"

# ---- (f): every real tests/lib/*.sh
_gci_k=0; _gci_names=""; _gci_failed=""
for _gci_f in "$HERE"/lib/*.sh; do
  [ -f "$_gci_f" ] || continue
  _gci_k=$((_gci_k + 1)); _gci_names="$_gci_names ${_gci_f##*/}"
  declare -F _lib_runs_nothing >/dev/null || continue
  ( FELIX_TEST_RAN="$GCI/lrn-ran"; _lib_runs_nothing "$_gci_f" ) > "$GCI/lrn.real" 2>&1 \
    || _gci_failed="$_gci_failed [${_gci_f##*/}: $(head -1 "$GCI/lrn.real")]"
done
_gci_n="every tests/lib/*.sh in this tree defines things and runs nothing when sourced, as _lib_runs_nothing judges it"
if [ "$_gci_k" -eq 0 ]; then
  skip "$_gci_n" "tests/lib holds no *.sh on this branch yet: 0 files to judge"
elif ! declare -F _lib_runs_nothing >/dev/null; then
  bad "$_gci_n" "$_gci_k lib file(s), and _lib_runs_nothing: $GCI_NO"
elif [ -n "$_gci_failed" ]; then
  bad "$_gci_n" "of $_gci_k lib file(s), these ran something:$_gci_failed"
else
  ok "$_gci_n"
  printf '        %s lib file(s) judged:%s\n' "$_gci_k" "$_gci_names"
fi
# <<< gate-friction-c-blind
