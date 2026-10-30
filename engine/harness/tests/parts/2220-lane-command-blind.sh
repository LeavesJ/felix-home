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
