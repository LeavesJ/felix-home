# >>> lane-command
printf '\nfelix lane: its usage, exits, thirteen columns and human line, the last change of a row, next, and read-only bytes (slice 0, design 6.5 item 1 and 6.6, C5, L-DET, L-RO; blind)\n'
# Blind, written on 2026-10-29 from docs/2026-10-29-capability-lane-first-slices-design.md and the slice 0 plan's
# Contracts (C1-C13) alone, before lib/lane.sh existed, without reading lib/, hooks/, bin/ or felix. Felix is run as a
# black box; the builders are tests/lib/lane-fixture.sh's. C11's row for this part: section 6.5 item 1 and 6.6 "The
# last change" and "Determinism": the usage line and exits; the thirteen columns and the human line; the last lane
# landing, and column 7 unknown with the state unchanged (C11's second worked expectation); next none and unknown; the
# commit that last changed a lane's row, unmoved by a comment line or another lane's row; an uncommitted edit changes
# nothing printed; L-DET; L-RO; no committed lanes.tsv prints nothing.
#
# The home apart (C9): H holds project ck with lanes.tsv (capability, ^engine/, 1/2, 14) and lane-next.tsv committed,
# and stays as built until the uncommitted edits at the end; the checkout C (bound by an untracked .felix) holds the
# root, a marked engine landing three days back, an unmarked one two days back and a marked docs one a day back, so
# capability reads ok, L 1 of T 2. The usage text is read from felix help, whose stdout is the general usage
# (felix --help prints the same on main). Readings where the Contracts leave room:
# - "In any directory" is a governed checkout and a directory under the fixture that no project governs.
# - The last change is asserted in a home of its own, whose history is commit A (the row), B (a comment line), C
#   (another lane's row), D (another file) and E (the row's share): capability names A until E, the other lane C; a
#   home whose root commit holds the row names its root. A --depth 1 clone of H is a shallow home: column 10 unknown.
# - L-RO's marker is touched a second after the fixture's last write, and what it finds newer is printed in the
#   assertion, so a write is named, not only counted.
# - The --help and -h exits are controls (C10); every other assertion here is red on main.
LNKN=1793000000; LNKDAY=86400
LNKNEXT='obligation intake, slice 1: felix situations --change (branch claude/lane-situations-owed)'
LNKMARK='Felix-Lane: capability'
LNKUSE='    felix lane [--tsv]     read-only: each lane'"'"'s share of engine landings on origin/main, against its target'
_lf_dir "$TMP/lane-2220"; LNKD="$LF_DIR"; mkdir -p "$LNKD/plain"
_lf_stubs "$LNKD"; LNKB="$LF_BIN"
_lf_home "$LNKD/home" ck 1792700000; LNKH="$LF_HOME"; LNKP="$LF_PROJ"
LNKLANES=$'# The lanes this fixture counts.\ncapability\t^engine/\t1/2\t14\n'
LNKNEXTS="$(_lf_tsv capability "$LNKNEXT")"$'\n'
_lf_table "$LNKP" 1792700100 lanes.tsv "$LNKLANES"; LNKTAB="$LF_SHA"; LNKTABISO="$(_lf_iso 1792700100)"
_lf_table "$LNKP" 1792700200 lane-next.tsv "$LNKNEXTS"
_lf_use "$LNKH" "$LNKD/memory" "$LNKD/user" "$LNKB"
_lf_checkout "$LNKD/c" ck $((LNKN - 30 * LNKDAY)); LNKC="$LF_REPO"
_lf_chain "$LNKC" capability $((LNKN - 3 * LNKDAY)) "$LNKDAY" m u md
if [ -n "$LNKTAB" ] && [ "$(_lf_spine "$LNKC")" = "$((LNKN - LNKDAY)):1 $((LNKN - 2 * LNKDAY)):1 $((LNKN - 3 * LNKDAY)):1 $((LNKN - 30 * LNKDAY)):0" ]; then
  LNKBUILT=built; else LNKBUILT="not built: the checkout reads [$(_lf_spine "$LNKC")]"; fi
LNKREFD="$(_lf_iso $((LNKN - LNKDAY)))"; LNKLASTD="$(_lf_iso $((LNKN - 3 * LNKDAY)))"
LNKLINE="$(_lf_tsv capability ok 1 2 14 1/2 "$LNKLASTD" "$LNKMARK" "$LNKNEXT" "$LNKTAB" "$LNKTABISO" "$LNKREFD" -)"
LNKCHG="its lanes.tsv row last changed by $(printf '%.12s' "$LNKTAB") at $LNKTABISO"
LNKHUMAN="capability: ok, 1 of 2 engine landings in 14 days, target 1/2; last lane landing $LNKLASTD; mark $LNKMARK; next: $LNKNEXT; $LNKCHG; refs/remotes/origin/main at $LNKREFD"
LNKROW="$(_lf_tsv lane value ok '1 of 2 engine landings in 14 days, target 1/2')"
# OUT -> status|bytes on stdout|stderr, of the run whose files are OUT.out and OUT.err.
_lnk_res() { printf '%s|%s|%s' "$LF_RC" "$(wc -c < "$1.out" | tr -d ' ')" "$(cat "$1.err")"; }

# ---- usage and exits ------------------------------------------------------------------------------------------------------
_lf_run "$LNKD/help" "$LNKC" - "$FELIX" help
LNKa="$(LC_ALL=C awk 'p { print; exit } index($0, "felix status [--tsv]") { p = 1 }' "$LNKD/help.out")"
is "lane command: felix help lists felix lane [--tsv] byte for byte, its text from column 28, on the line right after the one holding felix status [--tsv]" \
   "$LF_RC|$LNKa" "0|$LNKUSE"
_lf_run "$LNKD/lh1" "$LNKC" - "$FELIX" lane --help; LNKa="$LF_RC|$(cmp -s "$LNKD/lh1.out" "$LNKD/help.out" && echo usage || echo other)"
_lf_run "$LNKD/lh2" "$LNKC" - "$FELIX" lane -h x; LNKa="$LNKa|$LF_RC|$(cmp -s "$LNKD/lh2.out" "$LNKD/help.out" && echo usage || echo other)"
is "lane command: in a governed checkout felix lane --help and felix lane -h x print the general usage on stdout and exit 0 (control)" \
   "$LNKa" "0|usage|0|usage"
_lf_run "$LNKD/lh3" "$LNKD/plain" - "$FELIX" lane -h; LNKa="$LF_RC|$(cmp -s "$LNKD/lh3.out" "$LNKD/help.out" && echo usage || echo other)"
_lf_run "$LNKD/lh4" "$LNKD/plain" - "$FELIX" lane --help --tsv; LNKa="$LNKa|$LF_RC|$(cmp -s "$LNKD/lh4.out" "$LNKD/help.out" && echo usage || echo other)"
is "lane command: in a directory no project governs felix lane -h and felix lane --help --tsv print the general usage on stdout and exit 0 (control)" \
   "$LNKa" "0|usage|0|usage"
LNKUERR='felix: usage: felix lane [--tsv]'
# LABEL ARGS... -> felix lane ARGS is a usage error, in the checkout and in the ungoverned directory.
_lnk_usage() {
  local l="$1" g
  shift
  _lf_run "$LNKD/ug" "$LNKC" - "$FELIX" lane "$@"; g="$(_lnk_res "$LNKD/ug")"
  _lf_run "$LNKD/up" "$LNKD/plain" - "$FELIX" lane "$@"
  is "lane command: felix lane $l is a usage error, in a governed checkout and where no project governs: nothing on stdout, the usage line alone on stderr, exit 2" \
     "$g||$(_lnk_res "$LNKD/up")" "2|0|$LNKUERR||2|0|$LNKUERR"
}
_lnk_usage --json --json
_lnk_usage '--tsv --tsv' --tsv --tsv
_lnk_usage x x
_lnk_usage '--tsv --help' --tsv --help
_lf_run "$LNKD/ng1" "$LNKD/plain" - "$FELIX" lane; LNKa="$LF_RC|$(wc -c < "$LNKD/ng1.out" | tr -d ' ')|$(LC_ALL=C awk 'NR == 1' "$LNKD/ng1.err")|$(_lf_count "$LNKD/ng1.err")"
_lf_run "$LNKD/ng2" "$LNKD/plain" - "$FELIX" lane --tsv; LNKa="$LNKa||$LF_RC|$(wc -c < "$LNKD/ng2.out" | tr -d ' ')|$(LC_ALL=C awk 'NR == 1' "$LNKD/ng2.err")|$(_lf_count "$LNKD/ng2.err")"
LNKb="felix: no project governs $LNKD/plain."
is "lane command: where no project governs, felix lane and felix lane --tsv exit 2 with nothing on stdout and three lines on stderr, the first felix: no project governs <dir>." \
   "$LNKa" "2|0|$LNKb|3||2|0|$LNKb|3"

# ---- no committed lanes.tsv: nothing printed ----------------------------------------------------------------------------
_lf_home "$LNKD/home-none" ck 1792700000; LNKH2="$LF_HOME"; LNKP2="$LF_PROJ"
_lf_use "$LNKH2" "$LNKD/memory" "$LNKD/user" "$LNKB"
# LABEL -> felix lane and felix lane --tsv in C print nothing and exit 0.
_lnk_none() {
  _lf_run "$LNKD/none1" "$LNKC" "$LNKN" "$FELIX" lane; LNKa="$LF_RC|$(wc -c < "$LNKD/none1.out" | tr -d ' ')"
  _lf_run "$LNKD/none2" "$LNKC" "$LNKN" "$FELIX" lane --tsv
  is "lane command: $1: felix lane and felix lane --tsv print nothing and exit 0" "$LNKBUILT|$LNKa|$LF_RC|$(wc -c < "$LNKD/none2.out" | tr -d ' ')" "built|0|0|0|0"
}
_lnk_none "a home that never held lanes.tsv counts no lane"
printf '%s' "$LNKLANES" > "$LNKP2/lanes.tsv"
_lnk_none "a lanes.tsv with a row in the home's working tree, never committed, counts no lane"
_lf_table "$LNKP2" 1792700300 lanes.tsv $'# No lane is counted yet.\n\n'
_lnk_none "a committed lanes.tsv holding only a comment and a blank line counts no lane"
_lf_table "$LNKP2" 1792700400 lanes.tsv "$LNKLANES" && _lf_commit "$LNKP2" 1792700500 $'lanes.tsv removed\n' -lanes.tsv
printf '%s' "$LNKLANES" > "$LNKP2/lanes.tsv"
_lnk_none "a lanes.tsv committed, then removed by a later commit and left in the working tree, counts no lane"
_lf_use "$LNKH" "$LNKD/memory" "$LNKD/user" "$LNKB"

# ---- the thirteen columns and the human line --------------------------------------------------------------------------
_lf_run "$LNKD/tsv" "$LNKC" "$LNKN" "$FELIX" lane --tsv
is "lane command: felix lane --tsv prints one line of thirteen columns: lane, ok, L 1, T 2, window, share, the last lane landing's date, the mark, next, the commit that last changed the row and its date, the ref's date, and -" \
   "$LNKBUILT|$LF_RC|$(cat "$LNKD/tsv.out")" "built|0|$LNKLINE"
_lf_run "$LNKD/human" "$LNKC" "$LNKN" "$FELIX" lane
is "lane command: felix lane prints the human line built from those columns, the commit shortened to twelve characters" \
   "$LNKBUILT|$LF_RC|$(cat "$LNKD/human.out")" "built|0|$LNKHUMAN"

# ---- the review's F2: git variables the caller exported change nothing (C2) ------------------------------------------
# Added on 2026-10-30 from the adversarial review of the first build, still blind. C2 names the repository, the one
# holding the current directory, and where the tables are read, HEAD of the repository holding <PROJ>, whatever git
# variables the caller exported. Each setting below, given on the felix command alone, must leave felix lane --tsv's
# line and the status row as they are without it. O is another repository, with one commit of its own.
LNKa="not built: another repository"
_lf_init "$LNKD/f2-other" && _lf_commit "$LNKD/f2-other" 1792700000 $'another repository\n' other.txt \
  && LNKO="$(cd -P "$LNKD/f2-other" && pwd -P)" && [ -n "$LNKO" ] && LNKa="$LNKBUILT"
LNKb=""; LNKc=""; LNKw=""; LNKv=""
# LABEL ASSIGNMENT... -> felix lane --tsv and felix status --tsv in C with the ASSIGNMENTs on the felix command alone:
# LNKb and LNKc gain " [LABEL] <status>|<output>" and " [LABEL] <status>|<last row>", LNKw and LNKv the same unchanged.
_lnk_env() {
  local l="$1"
  shift
  _lf_run "$LNKD/f2" "$LNKC" "$LNKN" "$@" "$FELIX" lane --tsv
  LNKb="$LNKb [$l] $LF_RC|$(cat "$LNKD/f2.out")"; LNKw="$LNKw [$l] 0|$LNKLINE"
  _lf_run "$LNKD/f2s" "$LNKC" "$LNKN" "$@" "$FELIX" status --tsv
  LNKc="$LNKc [$l] $LF_RC|$(_lf_last "$LNKD/f2s.out")"; LNKv="$LNKv [$l] 0|$LNKROW"
}
_lnk_env 'GIT_DIR=<C>/.git' "GIT_DIR=$LNKC/.git"
_lnk_env 'GIT_DIR=<H>/.git' "GIT_DIR=$LNKH/.git"
_lnk_env 'GIT_DIR=.git' GIT_DIR=.git
_lnk_env 'GIT_WORK_TREE=<C>' "GIT_WORK_TREE=$LNKC"
_lnk_env 'GIT_DIR=<C>/.git and GIT_WORK_TREE=<C>' "GIT_DIR=$LNKC/.git" "GIT_WORK_TREE=$LNKC"
_lnk_env 'GIT_DIR=<O>/.git' "GIT_DIR=$LNKO/.git"
_lnk_env 'GIT_OBJECT_DIRECTORY=<O>/.git/objects' "GIT_OBJECT_DIRECTORY=$LNKO/.git/objects"
is "lane command F2-caller-git-dir: GIT_DIR naming the checkout, the home, .git or another repository, GIT_WORK_TREE, both, or GIT_OBJECT_DIRECTORY of another repository, exported by the caller, leave felix lane --tsv's exit 0 and line as they are without them" \
   "$LNKa$LNKb" "built$LNKw"
is "lane command F2-caller-git-dir: the same settings leave felix status --tsv's exit 0 and its lane row as they are without them" \
   "$LNKa$LNKc" "built$LNKv"

_lf_checkout "$LNKD/noref" ck $((LNKN - 30 * LNKDAY)); LNKR="$LF_REPO"
_lf_commit "$LNKR" $((LNKN - LNKDAY)) $'engine: x\n\nFelix-Lane: capability\n' engine/x.sh && LNKa=built || LNKa="not built"
_lf_run "$LNKD/noref-h" "$LNKR" "$LNKN" "$FELIX" lane
is "lane command: an unknown line in human form reads <lane>: unknown, the reason, the last change, and the ref at -" \
   "$LNKa|$LF_RC|$(cat "$LNKD/noref-h.out")" \
   "built|0|capability: unknown, refs/remotes/origin/main cannot be read in $LNKR; $LNKCHG; refs/remotes/origin/main at -"

_lf_home "$LNKD/home-r4" ck 1792700000; LNKH4="$LF_HOME"; LNKP4="$LF_PROJ"
_lf_table "$LNKP4" 1792700100 lanes.tsv $'capability\t^engine/\t1/2\n' && LNKa=built || LNKa="not built"
_lf_use "$LNKH4" "$LNKD/memory" "$LNKD/user" "$LNKB"
_lf_run "$LNKD/r4-h" "$LNKC" "$LNKN" "$FELIX" lane
is "lane command: an R4 line in human form has lane -, and no last-change part since column 10 is -" \
   "$LNKa|$LF_RC|$(cat "$LNKD/r4-h.out")" "built|0|-: unknown, $LNKP4/lanes.tsv cannot be read as lanes.tsv; refs/remotes/origin/main at $LNKREFD"

LNKa="not built"
if ( _fx_cd "$LNKD" && _lf_g 1700000000 clone -q --depth 1 "file://$LNKH" home-shallow ) >/dev/null 2>&1; then
  LNKa="$( _fx_cd "$LNKD/home-shallow" || exit 1; [ "$(_lf_g 1700000000 rev-parse --is-shallow-repository)" = true ] \
           && _lf_g 1700000000 cat-file -e HEAD:projects/ck/lanes.tsv && echo built )"
fi
_lf_use "$LNKD/home-shallow" "$LNKD/memory" "$LNKD/user" "$LNKB"
_lf_run "$LNKD/hs-t" "$LNKC" "$LNKN" "$FELIX" lane --tsv
is "lane command: with the home a shallow clone, column 10 reads unknown and 11 -, and the state and every other column stand" \
   "${LNKa:-not built}|$LF_RC|$(cat "$LNKD/hs-t.out")" \
   "built|0|$(_lf_tsv capability ok 1 2 14 1/2 "$LNKLASTD" "$LNKMARK" "$LNKNEXT" unknown - "$LNKREFD" -)"
_lf_run "$LNKD/hs-h" "$LNKC" "$LNKN" "$FELIX" lane
is "lane command: with the home a shallow clone, the human line says its lanes.tsv row's last change cannot be read" \
   "${LNKa:-not built}|$LF_RC|$(cat "$LNKD/hs-h.out")" \
   "built|0|capability: ok, 1 of 2 engine landings in 14 days, target 1/2; last lane landing $LNKLASTD; mark $LNKMARK; next: $LNKNEXT; its lanes.tsv row's last change cannot be read; refs/remotes/origin/main at $LNKREFD"
_lf_use "$LNKH" "$LNKD/memory" "$LNKD/user" "$LNKB"

# ---- the last lane landing ------------------------------------------------------------------------------------------------
_lf_checkout "$LNKD/zero" ck $((LNKN - 30 * LNKDAY)); LNKR="$LF_REPO"
_lf_chain "$LNKR" capability $((LNKN - 2 * LNKDAY)) 3600 u u && LNKa=built || LNKa="not built"
_lf_run "$LNKD/zero-t" "$LNKR" "$LNKN" "$FELIX" lane --tsv
is "lane command: with no marked engine landing anywhere on the chain, the last lane landing reads none" \
   "$LNKa|$LF_RC|$(_lf_cols "$LNKD/zero-t.out" 1 2 3 4 7)" "built|0|zero|0|2|none"
_lf_checkout "$LNKD/old" ck $((LNKN - 30 * LNKDAY)); LNKR="$LF_REPO"
_lf_commit "$LNKR" $((LNKN - 20 * LNKDAY)) $'engine: old\n\nFelix-Lane: capability\n' engine/old.sh \
  && _lf_commit "$LNKR" $((LNKN - LNKDAY)) $'engine: new\n' engine/new.sh && _lf_publish "$LNKR" && LNKa=built || LNKa="not built"
_lf_run "$LNKD/old-t" "$LNKR" "$LNKN" "$FELIX" lane --tsv
is "lane command: a lane landing twenty days back is out of the window and is still the last lane landing: zero, L 0 of T 1, its date in column 7" \
   "$LNKa|$LF_RC|$(_lf_cols "$LNKD/old-t.out" 1 2 3 4 7)" "built|0|zero|0|1|$(_lf_iso $((LNKN - 20 * LNKDAY)))"

# C11's worked expectation: B root at -50 d, M the only marked landing at -40 d (engine/m), N docs/n at -39 d, W engine/w
# at -1 d; M's root tree removed, which only the last-landing search reads.
_lf_checkout "$LNKD/tree" ck $((LNKN - 50 * LNKDAY)); LNKR="$LF_REPO"; LNKa="not built"
if _lf_commit "$LNKR" $((LNKN - 40 * LNKDAY)) $'engine: m\n\nFelix-Lane: capability\n' engine/m && LNKM="$LF_SHA" \
   && _lf_commit "$LNKR" $((LNKN - 39 * LNKDAY)) $'docs: n\n' docs/n && LNKNS="$LF_SHA" \
   && _lf_commit "$LNKR" $((LNKN - LNKDAY)) $'engine: w\n' engine/w && _lf_publish "$LNKR"; then
  LNKb="$( _fx_cd "$LNKR" || exit 1; printf '%s %s' "$(_lf_g 1700000000 rev-parse "$LNKM^{tree}")" "$(_lf_g 1700000000 rev-parse "$LNKNS^{tree}")" )"
  if [ "${LNKb% *}" != "${LNKb#* }" ] && _lf_unobject "$LNKR" "$LNKM^{tree}"; then
    ( _fx_cd "$LNKR" && _lf_g 1700000000 cat-file -e "${LNKb% *}" ) >/dev/null 2>&1 || LNKa=built
  fi
fi
_lf_run "$LNKD/tree-t" "$LNKR" "$LNKN" "$FELIX" lane --tsv
is "lane command: with M's root tree gone, which only the last-landing search reads, column 7 reads unknown and the state stays zero, L 0 of T 1, columns 10 to 13 as before" \
   "$LNKa|$LF_RC|$(cat "$LNKD/tree-t.out")" \
   "built|0|$(_lf_tsv capability zero 0 1 14 1/2 unknown "$LNKMARK" "$LNKNEXT" "$LNKTAB" "$LNKTABISO" "$(_lf_iso $((LNKN - LNKDAY)))" -)"
_lf_run "$LNKD/tree-h" "$LNKR" "$LNKN" "$FELIX" lane
is "lane command: with M's root tree gone, the human line reads last lane landing unknown and the state zero" \
   "$LNKa|$LF_RC|$(cat "$LNKD/tree-h.out")" \
   "built|0|capability: zero, 0 of 1 engine landings in 14 days, target 1/2; last lane landing unknown; mark $LNKMARK; next: $LNKNEXT; $LNKCHG; refs/remotes/origin/main at $(_lf_iso $((LNKN - LNKDAY)))"
_lf_run "$LNKD/tree-s" "$LNKR" "$LNKN" "$FELIX" status --tsv
is "lane command: with M's root tree gone, the status row still reads the value zero, 0 of 1 engine landings in 14 days, target 1/2" \
   "$LNKa|$LF_RC|$(_lf_last "$LNKD/tree-s.out")" "built|0|$(_lf_tsv lane value zero '0 of 1 engine landings in 14 days, target 1/2')"

# ---- next: none and unknown, never a state ---------------------------------------------------------------------------------
_lf_home "$LNKD/home-next" ck 1792700000; LNKH6="$LF_HOME"; LNKP6="$LF_PROJ"
_lf_table "$LNKP6" 1792700100 lanes.tsv "$LNKLANES"; LNKa="${LF_SHA:+built}"
_lf_use "$LNKH6" "$LNKD/memory" "$LNKD/user" "$LNKB"
# LABEL WANT -> columns 2, 3, 4 and 9 of felix lane --tsv in C read ok, 1, 2 and WANT.
_lnk_next() {
  _lf_run "$LNKD/next" "$LNKC" "$LNKN" "$FELIX" lane --tsv
  is "lane command: $1: next reads $2 and the state stays ok, L 1 of T 2" "${LNKa:-not built}|$LF_RC|$(_lf_cols "$LNKD/next.out" 1 2 3 4 9)" "built|0|ok|1|2|$2"
}
_lnk_next "no lane-next.tsv committed" none
printf '%s' "$LNKNEXTS" > "$LNKP6/lane-next.tsv"
_lnk_next "a lane-next.tsv in the home's working tree, never committed" none
_lf_table "$LNKP6" 1792700200 lane-next.tsv "$LNKNEXTS" || LNKa=""
_lnk_next "one committed row for the lane" "$LNKNEXT"
_lf_table "$LNKP6" 1792700300 lane-next.tsv "$LNKNEXTS$(_lf_tsv capability 'a second item')"$'\n' || LNKa=""
_lnk_next "two committed rows for the lane" unknown
_lf_table "$LNKP6" 1792700400 lane-next.tsv "$(_lf_tsv capability "$LNKNEXT")"$'\r\n' || LNKa=""
_lnk_next "a committed lane-next.tsv the shape check refuses, a CR in its row" unknown
_lf_table "$LNKP6" 1792700500 lane-next.tsv "$(_lf_tsv docs 'a lane this table does not hold')"$'\n' || LNKa=""
_lnk_next "a committed lane-next.tsv whose only row names a lane lanes.tsv does not hold" none

# ---- the last change of a lane's row ----------------------------------------------------------------------------------------
_lf_home "$LNKD/home-chg" ck 1792700000; LNKH5="$LF_HOME"; LNKP5="$LF_PROJ"; LNKa=built
_lf_use "$LNKH5" "$LNKD/memory" "$LNKD/user" "$LNKB"
_lf_table "$LNKP5" 1792710000 lanes.tsv "$LNKLANES" && LNKA="$LF_SHA" || LNKa="not built"
_lf_run "$LNKD/chg-a" "$LNKC" "$LNKN" "$FELIX" lane --tsv
is "lane command: after commit A adds the lane's row, columns 10 and 11 name A and its committer date" \
   "$LNKa|$LF_RC|$(_lf_cols "$LNKD/chg-a.out" 1 1 10 11)" "built|0|capability|${LNKA:-A}|$(_lf_iso 1792710000)"
_lf_run "$LNKD/chg-ah" "$LNKC" "$LNKN" "$FELIX" lane
is "lane command: after commit A, the human line names A's first twelve characters and its date" \
   "$LNKa|$LF_RC|$(cat "$LNKD/chg-ah.out")" \
   "built|0|capability: ok, 1 of 2 engine landings in 14 days, target 1/2; last lane landing $LNKLASTD; mark $LNKMARK; next: none; its lanes.tsv row last changed by $(printf '%.12s' "$LNKA") at $(_lf_iso 1792710000); refs/remotes/origin/main at $LNKREFD"
_lf_table "$LNKP5" 1792720000 lanes.tsv $'# The lanes, reworded.\ncapability\t^engine/\t1/2\t14\n' || LNKa="not built"
_lf_table "$LNKP5" 1792730000 lanes.tsv $'# The lanes, reworded.\ncapability\t^engine/\t1/2\t14\ndocs\t^docs/\t1/2\t14\n' && LNKC3="$LF_SHA" || LNKa="not built"
_lf_commit "$LNKP5" 1792740000 $'notes beside the tables\n' notes.md || LNKa="not built"
_lf_run "$LNKD/chg-d" "$LNKC" "$LNKN" "$FELIX" lane --tsv
is "lane command: commits that change only a comment line, another lane's row and another file leave capability's columns 10 and 11 at A; the other lane names its own commit" \
   "$LNKa|$LF_RC|$(_lf_cols "$LNKD/chg-d.out" 1 1 10 11)|$(_lf_cols "$LNKD/chg-d.out" 2 1 10 11)" \
   "built|0|capability|${LNKA:-A}|$(_lf_iso 1792710000)|docs|${LNKC3:-C}|$(_lf_iso 1792730000)"
_lf_table "$LNKP5" 1792750000 lanes.tsv $'# The lanes, reworded.\ncapability\t^engine/\t1/4\t14\ndocs\t^docs/\t1/2\t14\n' && LNKE="$LF_SHA" || LNKa="not built"
_lf_run "$LNKD/chg-e" "$LNKC" "$LNKN" "$FELIX" lane --tsv
is "lane command: commit E lowers capability's share to 1/4: columns 10 and 11 name E and its date, and the other lane's stay" \
   "$LNKa|$LF_RC|$(_lf_cols "$LNKD/chg-e.out" 1 1 6 10 11)|$(_lf_cols "$LNKD/chg-e.out" 2 1 10 11)" \
   "built|0|capability|1/4|${LNKE:-E}|$(_lf_iso 1792750000)|docs|${LNKC3:-C}|$(_lf_iso 1792730000)"
LNKa="not built"; LNKh="$LNKD/home-root"
if _lf_init "$LNKh" && mkdir -p "$LNKh/projects/ck"; then
  printf '{"name":"ck","gate":"true"}\n' > "$LNKh/projects/ck/project.json"; printf '# ck\n' > "$LNKh/projects/ck/CLAUDE.md"
  printf '%s' "$LNKLANES" > "$LNKh/projects/ck/lanes.tsv"
  _lf_commit "$LNKh" 1792760000 $'the home, its lane table from the start\n' =projects/ck/project.json =projects/ck/CLAUDE.md =projects/ck/lanes.tsv \
    && LNKRT="$LF_SHA" && LNKa=built
fi
_lf_use "$LNKh" "$LNKD/memory" "$LNKD/user" "$LNKB"
_lf_run "$LNKD/chg-r" "$LNKC" "$LNKN" "$FELIX" lane --tsv
is "lane command: in a home whose root commit holds the row, columns 10 and 11 name the root and its date" \
   "$LNKa|$LF_RC|$(_lf_cols "$LNKD/chg-r.out" 1 1 10 11)" "built|0|capability|${LNKRT:-root}|$(_lf_iso 1792760000)"
_lf_use "$LNKH" "$LNKD/memory" "$LNKD/user" "$LNKB"

# ---- the review's F6: a last change that cannot be read is unknown, never another commit (C5 column 10, C3) ----------
# Added on 2026-10-30 from the adversarial review of the first build, still blind. Column 10 is unknown when git could
# not finish its search, a read that did not finish never yields a value (C3), and a commit that changes only a comment
# line does not move the column. A home's history: A adds the row (share 1/2), B changes it (1/3), C adds only a comment
# line; with every object there, column 10 names B, and the checkout C reads ok, L 1 of T 2 at 1/3. (i) B's lanes.tsv
# blob, a loose object only the search reads, is removed. (ii) In a second home of the same history, then D adding
# notes.md, C's root tree, which only the search reads, is removed. The state and every other column stand.
LNKF6L1=$'capability\t^engine/\t1/2\t14\n'; LNKF6L2=$'capability\t^engine/\t1/3\t14\n'
LNKF6L3=$'# The lanes, with a comment.\ncapability\t^engine/\t1/3\t14\n'
LNKF6LINE="$(_lf_tsv capability ok 1 2 14 1/3 "$LNKLASTD" "$LNKMARK" none unknown - "$LNKREFD" -)"
# DIR -> a home at DIR (project ck), its history A, B and C as above. LNKF6H the home, LNKF6B B and LNKF6C C, empty
# when not made.
_lnk_f6home() {
  LNKF6H=""; LNKF6B=""; LNKF6C=""
  _lf_home "$1" ck 1792700000 || return 1
  _lf_table "$LF_PROJ" 1792780000 lanes.tsv "$LNKF6L1" || return 1
  _lf_table "$LF_PROJ" 1792781000 lanes.tsv "$LNKF6L2" || return 1
  LNKF6B="$LF_SHA"
  _lf_table "$LF_PROJ" 1792782000 lanes.tsv "$LNKF6L3" || return 1
  LNKF6C="$LF_SHA"; LNKF6H="$LF_HOME"
}
# HOME REV -> 0 when REV names an object HOME's repository can read.
_lnk_has() { ( _fx_cd "$1" && _lf_g 1700000000 cat-file -e "$2" ) >/dev/null 2>&1; }
LNKa="not built: F6 (i)"; LNKb=""
if _lnk_f6home "$LNKD/home-f6"; then
  _lf_use "$LNKF6H" "$LNKD/memory" "$LNKD/user" "$LNKB"
  _lf_run "$LNKD/f6-0" "$LNKC" "$LNKN" "$FELIX" lane --tsv; LNKb="$(_lf_cols "$LNKD/f6-0.out" 1 10)"
  _lf_unobject "$LNKF6H" "$LNKF6B:projects/ck/lanes.tsv" && ! _lnk_has "$LNKF6H" "$LNKF6B:projects/ck/lanes.tsv" \
    && _lnk_has "$LNKF6H" "$LNKF6C:projects/ck/lanes.tsv" && _lnk_has "$LNKF6H" "HEAD:projects/ck/lanes.tsv" && LNKa=built
fi
_lf_run "$LNKD/f6-i" "$LNKC" "$LNKN" "$FELIX" lane --tsv
is "lane command F6-column-10-names-a-wrong-commit-when-history-objects-are-missing: with B's lanes.tsv blob gone from the home, column 10 reads unknown and 11 -, never C, the comment-only commit; with it there, column 10 named B; the state ok and every other column stand" \
   "$LNKa|before ${LNKb:-none}|$LF_RC|$(cat "$LNKD/f6-i.out")" "built|before ${LNKF6B:-B}|0|$LNKF6LINE"
_lf_run "$LNKD/f6-ih" "$LNKC" "$LNKN" "$FELIX" lane
is "lane command F6-column-10-names-a-wrong-commit-when-history-objects-are-missing: with B's lanes.tsv blob gone, the human line says its lanes.tsv row's last change cannot be read" \
   "$LNKa|$LF_RC|$(cat "$LNKD/f6-ih.out")" \
   "built|0|capability: ok, 1 of 2 engine landings in 14 days, target 1/3; last lane landing $LNKLASTD; mark $LNKMARK; next: none; its lanes.tsv row's last change cannot be read; refs/remotes/origin/main at $LNKREFD"
LNKa="not built: F6 (ii)"; LNKb=""
if _lnk_f6home "$LNKD/home-f6t" && _lf_commit "$LNKF6H" 1792783000 $'notes beside the tables\n' notes.md; then
  _lf_use "$LNKF6H" "$LNKD/memory" "$LNKD/user" "$LNKB"
  _lf_run "$LNKD/f6-1" "$LNKC" "$LNKN" "$FELIX" lane --tsv; LNKb="$(_lf_cols "$LNKD/f6-1.out" 1 10)"
  _lf_unobject "$LNKF6H" "$LNKF6C^{tree}" && ! _lnk_has "$LNKF6H" "$LNKF6C^{tree}" && _lnk_has "$LNKF6H" "HEAD^{tree}" \
    && _lnk_has "$LNKF6H" "HEAD:projects/ck/lanes.tsv" && LNKa=built
fi
_lf_run "$LNKD/f6-ii" "$LNKC" "$LNKN" "$FELIX" lane --tsv
is "lane command F6-column-10-names-a-wrong-commit-when-history-objects-are-missing: with C's root tree gone from the home, below D, which adds notes.md, column 10 reads unknown and 11 -, never D; with it there, column 10 named B; the state ok and every other column stand" \
   "$LNKa|before ${LNKb:-none}|$LF_RC|$(cat "$LNKD/f6-ii.out")" "built|before ${LNKF6B:-B}|0|$LNKF6LINE"
_lf_use "$LNKH" "$LNKD/memory" "$LNKD/user" "$LNKB"

# ---- partial clones: the review's F6 (no object fetched, a search that cannot finish is unknown) and F3 (an old git) ---
# Added on 2026-10-30 from the adversarial review of the first build, still blind. The source S is self-governed (C9):
# its root holds .felix (ck), then lanes.tsv commits A (share 1/2), B (1/3) and C (a comment line only), then E, one
# unmarked engine landing a day before the clock; uploadpack.allowFilter lets it serve partial clones. Each clone is the
# home and the checkout; its refs/remotes/origin/main is S's main. Its remote.origin.uploadpack is a logger that writes
# a line and fails, so a fetch is seen and fetches nothing, and nothing reaches a network. In a --filter=blob:none clone
# B's lanes.tsv blob is missing and HEAD's is there; in a --filter=tree:0 clone C's root tree is missing.
# - F6, with the suite's git: the blobless clone reads zero, L 0 of T 1, column 10 unknown, never C; the tree:0 clone
#   reads unknown with R2 (E's changed paths need C's tree), column 10 unknown, never E. Nothing is fetched.
# - F3: a git before 2.44 ignores GIT_NO_LAZY_FETCH (C3). The stand-in, first on PATH, says git version 2.43.0, refuses
#   --no-lazy-fetch as such a git does, and drops GIT_NO_LAZY_FETCH before it runs the suite's git. (a) In the blobless
#   clone a partial clone is not read: R2, column 10 unknown. (b) A full clone of S as the checkout, the blobless clone
#   as the home: the full clone is counted, zero, L 0 of T 1, and column 10 is unknown. Column 12 is not compared in
#   (a): C3 does not say whether the ref's date is read there. Nothing is fetched in either.
LNKRG="$(type -P git)"; LNKFL="$LNKD/fetch.log"; LNKa="not built: the partial clones"
mkdir -p "$LNKD/oldgit"
printf '#!/bin/sh\nprintf '"'"'upload-pack ran: %%s\\n'"'"' "$*" >> %s\nexit 1\n' "$(printf '%q' "$LNKFL")" > "$LNKD/logger"
{ printf '#!/bin/bash\n# A git that says it is 2.43.0: it refuses --no-lazy-fetch and ignores GIT_NO_LAZY_FETCH, as git before 2.44 does.\n'
  printf 's=0\nfor a in "$@"; do\n  if [ "$s" = 1 ]; then s=0; continue; fi\n  case "$a" in\n'
  printf '    --version|version) printf '"'"'git version 2.43.0\\n'"'"'; exit 0 ;;\n'
  printf '    --no-lazy-fetch) printf '"'"'unknown option: --no-lazy-fetch\\n'"'"' >&2; exit 129 ;;\n'
  printf '    -c|-C) s=1 ;;\n    -*) ;;\n    *) break ;;\n  esac\ndone\nunset GIT_NO_LAZY_FETCH\nexec %s "$@"\n' "$(printf '%q' "$LNKRG")"; } > "$LNKD/oldgit/git"
chmod +x "$LNKD/logger" "$LNKD/oldgit/git"
LNKS=""
if [ -n "$LNKRG" ] && _lf_self "$LNKD/pc-src" ck $((LNKN - 40 * LNKDAY)); then
  LNKS="$LF_HOME"
  _lf_table "$LF_PROJ" $((LNKN - 35 * LNKDAY)) lanes.tsv "$LNKF6L1" && _lf_table "$LF_PROJ" $((LNKN - 30 * LNKDAY)) lanes.tsv "$LNKF6L2" \
    && LNKPB="$LF_SHA" && _lf_table "$LF_PROJ" $((LNKN - 20 * LNKDAY)) lanes.tsv "$LNKF6L3" && LNKPC="$LF_SHA" \
    && _lf_commit "$LNKS" $((LNKN - LNKDAY)) $'engine: e\n\nNo mark.\n' engine/e.sh && LNKPE="$LF_SHA" \
    && ( _fx_cd "$LNKS" && _lf_g 1700000000 config uploadpack.allowFilter true ) >/dev/null 2>&1 || LNKS=""
fi
# NAME [FILTER] -> a clone of S at $LNKD/NAME (with --filter=FILTER), its uploadpack the logger; 0 when it holds
# refs/remotes/origin/main at E, and a partial one is a promisor.
_lnk_clone() {
  [ -n "$LNKS" ] || return 1
  ( unset GIT_NO_LAZY_FETCH; _fx_cd "$LNKD" && _lf_g 1700000000 clone -q ${2:+"--filter=$2"} "file://$LNKS" "$1" ) >/dev/null 2>&1 || return 1
  ( _fx_cd "$LNKD/$1" || exit 1; _lf_g 1700000000 config remote.origin.uploadpack "$LNKD/logger" || exit 1
    [ "$(_lf_g 1700000000 rev-parse --verify -q refs/remotes/origin/main)" = "$LNKPE" ] || exit 1
    [ -z "${2:-}" ] || [ "$(_lf_g 1700000000 config --get remote.origin.promisor)" = true ] ) >/dev/null 2>&1
}
# NAME REV -> 0 when the clone NAME can read REV without fetching it.
_lnk_lazy() { ( _fx_cd "$LNKD/$1" && GIT_NO_LAZY_FETCH=1 _lf_g 1700000000 cat-file -e "$2" ) >/dev/null 2>&1; }
_lnk_clone pc-blob blob:none && _lnk_clone pc-tree tree:0 && _lnk_clone pc-full \
  && ! _lnk_lazy pc-blob "$LNKPB:projects/ck/lanes.tsv" && _lnk_lazy pc-blob "HEAD:projects/ck/lanes.tsv" \
  && ! _lnk_lazy pc-tree "$LNKPC^{tree}" && _lnk_lazy pc-tree "HEAD:projects/ck/lanes.tsv" \
  && _lnk_lazy pc-full "$LNKPB:projects/ck/lanes.tsv" && [ ! -e "$LNKFL" ] \
  && [ "$("$LNKD/oldgit/git" --version)" = 'git version 2.43.0' ] && LNKa=built
LNKPBD="$(_lf_iso $((LNKN - LNKDAY)))"
# The suite's own git must be 2.44 or later: before it, C3 reads every partial clone as R2, and GIT_NO_LAZY_FETCH, which
# the checks above lean on, does not exist. Then these assertions skip, with the version.
LNKRGV="$("$LNKRG" --version 2>/dev/null)"
LNKGV="$(printf '%s\n' "$LNKRGV" | LC_ALL=C awk '{ n = split($3, v, "."); s = "old"; if (n >= 2 && (v[1] + 0 > 2 || (v[1] + 0 == 2 && v[2] + 0 >= 44))) s = "new"; print s }')"
_lnk_is() { if [ "$LNKGV" = new ]; then is "$1" "$2" "$3"; else skip "$1" "the suite's git says [$LNKRGV], before 2.44, where C3 reads a partial clone as R2"; fi; }
# OUT DIR HOME [PATH-FIRST] -> felix lane --tsv run from $LNKD/DIR with the home $LNKD/HOME (and PATH-FIRST before the
# stubs on PATH), the fetch log cleared first; LNKf "fetch[<what the logger wrote>]".
_lnk_pc() {
  rm -f "$LNKFL"
  _lf_use "$LNKD/$3" "$LNKD/memory" "$LNKD/user" "$LNKB"
  if [ -n "${4:-}" ]; then _lf_run "$LNKD/$1" "$LNKD/$2" "$LNKN" PATH="$4:$LNKB:$PATH" "$FELIX" lane --tsv
  else _lf_run "$LNKD/$1" "$LNKD/$2" "$LNKN" "$FELIX" lane --tsv; fi
  LNKf="fetch[$(cat "$LNKFL" 2>/dev/null)]"
}
_lnk_pc pc-b pc-blob pc-blob
_lnk_is "lane command F6-column-10-names-a-wrong-commit-when-history-objects-are-missing: a --filter=blob:none clone as home and checkout reads zero, L 0 of T 1, column 10 unknown and 11 -, never C, the comment-only commit, and fetches nothing" \
   "$LNKa|$LNKf|$LF_RC|$(cat "$LNKD/pc-b.out")" \
   "built|fetch[]|0|$(_lf_tsv capability zero 0 1 14 1/3 none "$LNKMARK" none unknown - "$LNKPBD" -)"
_lnk_pc pc-t pc-tree pc-tree
_lnk_is "lane command F6-column-10-names-a-wrong-commit-when-history-objects-are-missing L-NEVER-OK: a --filter=tree:0 clone as home and checkout reads unknown with R2, column 10 unknown and 11 -, never E, the latest landing, and fetches nothing" \
   "$LNKa|$LNKf|$LF_RC|$(cat "$LNKD/pc-t.out")" \
   "built|fetch[]|0|$(_lf_tsv capability unknown - - 14 1/3 - "$LNKMARK" none unknown - "$LNKPBD" \
      "git could not read the landings on refs/remotes/origin/main in $LNKD/pc-tree")"
_lnk_pc pc-oa pc-blob pc-blob "$LNKD/oldgit"
_lnk_is "lane command F3-old-git-lazy-fetch-through-the-home L-NEVER-OK: (a) with a git that says 2.43.0, the --filter=blob:none clone as home and checkout is not read: unknown with R2, column 10 unknown, and nothing is fetched" \
   "$LNKa|$LNKf|$LF_RC|$(_lf_count "$LNKD/pc-oa.out")|$(_lf_cols "$LNKD/pc-oa.out" 1 1 2 3 4 5 6 7 8 9 10 11 13)" \
   "built|fetch[]|0|1|capability|unknown|-|-|14|1/3|-|$LNKMARK|none|unknown|-|git could not read the landings on refs/remotes/origin/main in $LNKD/pc-blob"
_lnk_pc pc-ob pc-full pc-blob "$LNKD/oldgit"
_lnk_is "lane command F3-old-git-lazy-fetch-through-the-home: (b) with a git that says 2.43.0, a full clone as the checkout and the --filter=blob:none clone as the home: zero, L 0 of T 1, column 10 unknown and 11 -, and nothing is fetched" \
   "$LNKa|$LNKf|$LF_RC|$(_lf_count "$LNKD/pc-ob.out")|$(_lf_cols "$LNKD/pc-ob.out" 1 1 2 3 4 10 11 13)" \
   "built|fetch[]|0|1|capability|zero|0|1|unknown|-|-"
_lf_use "$LNKH" "$LNKD/memory" "$LNKD/user" "$LNKB"

# ---- L-DET -------------------------------------------------------------------------------------------------------------------
for LNKk in 1 2; do
  _lf_run "$LNKD/det-h$LNKk" "$LNKC" "$LNKN" "$FELIX" lane
  _lf_run "$LNKD/det-t$LNKk" "$LNKC" "$LNKN" "$FELIX" lane --tsv
  _lf_run "$LNKD/det-s$LNKk" "$LNKC" "$LNKN" "$FELIX" status --tsv
done
LNKa=""
for LNKk in det-h det-t det-s; do cmp -s "$LNKD/${LNKk}1.out" "$LNKD/${LNKk}2.out" && LNKa="$LNKa|same" || LNKa="$LNKa|differ"; done
is "lane command L-DET: two runs each of felix lane, felix lane --tsv and felix status --tsv print identical bytes, the expected human line, TSV line and lane row" \
   "$LNKBUILT$LNKa|$(cat "$LNKD/det-h1.out")|$(cat "$LNKD/det-t1.out")|$(_lf_last "$LNKD/det-s1.out")" \
   "built|same|same|same|$LNKHUMAN|$LNKLINE|$LNKROW"

# ---- L-RO and the uncommitted edit ------------------------------------------------------------------------------------------
# LABEL -> a marker touched a second after the last write, then felix lane, felix lane --tsv and felix status --tsv in C;
# what they left newer under H, the memory root and C (.git included), and C's refs and worktree list before and after.
_lnk_ro() {
  local f="$LNKD/ro" r1 r2 w1 w2 nw
  sleep 1; touch "$f.marker"
  r1="$( _fx_cd "$LNKC" && _lf_g 1700000000 for-each-ref )"; w1="$( _fx_cd "$LNKC" && _lf_g 1700000000 worktree list --porcelain )"
  _lf_run "$f-h" "$LNKC" "$LNKN" "$FELIX" lane
  _lf_run "$f-t" "$LNKC" "$LNKN" "$FELIX" lane --tsv
  _lf_run "$f-s" "$LNKC" "$LNKN" "$FELIX" status --tsv
  r2="$( _fx_cd "$LNKC" && _lf_g 1700000000 for-each-ref )"; w2="$( _fx_cd "$LNKC" && _lf_g 1700000000 worktree list --porcelain )"
  nw="$(find "$LNKH" "$LNKD/memory" "$LNKC" -newer "$f.marker" 2>&1)"
  is "lane command L-RO: $1: felix lane and felix status leave nothing newer under the home, the memory root and the checkout, its refs and worktree list unchanged, and print the expected lines" \
     "$LNKBUILT|newer[${nw}]|$([ -n "$r1" ] && [ "$r1" = "$r2" ] && echo same || echo changed)|$([ -n "$w1" ] && [ "$w1" = "$w2" ] && echo same || echo changed)|$(cat "$f-h.out")|$(cat "$f-t.out")|$(_lf_last "$f-s.out")" \
     "built|newer[]|same|same|$LNKHUMAN|$LNKLINE|$LNKROW"
}
_lnk_ro "as built"
touch "$LNKP/lanes.tsv"
_lnk_ro "after touch of lanes.tsv, its content unchanged"
printf '%s' $'# The lanes this fixture counts.\ncapability\t^engine/\t1/4\t7\n' > "$LNKP/lanes.tsv"
printf '%s' "$(_lf_tsv capability 'an item never committed')"$'\n' > "$LNKP/lane-next.tsv"
_lnk_ro "after uncommitted edits to lanes.tsv (share 1/4, window 7) and lane-next.tsv"
rm -f "$LNKP/lanes.tsv"
_lf_run "$LNKD/gone" "$LNKC" "$LNKN" "$FELIX" lane --tsv
is "lane command: with lanes.tsv deleted from the home's working tree and still committed, felix lane --tsv prints the committed row's line unchanged" \
   "$LNKBUILT|$LF_RC|$(cat "$LNKD/gone.out")" "built|0|$LNKLINE"
printf '%s' "$LNKLANES" > "$LNKP/lanes.tsv"; printf '%s' "$LNKNEXTS" > "$LNKP/lane-next.tsv"
# <<< lane-command
