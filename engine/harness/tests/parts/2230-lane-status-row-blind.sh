# >>> lane-status-row
printf '\nlane status row: felix status gains the lane row, last, in every case C6 names, with the status shape, L-DET and L-RO (slice 0, design 6.5 item 2 and 6.6, C6, L-NEVER-OK; blind)\n'
# Blind, written on 2026-10-29 from docs/2026-10-29-capability-lane-first-slices-design.md and the slice 0 plan's
# Contracts (C1-C13) alone, before lib/lane.sh existed, without reading lib/, hooks/, bin/ or felix. Felix is run as a
# black box; the builders are tests/lib/lane-fixture.sh's. C11's row for this part: section 6.5 item 2 and 6.6 "felix
# status --tsv": exactly one row more, at the end, every row before it byte-identical; every C6 case, an unreadable ref
# giving state unknown and value -; the status shape; L-DET and L-RO for status.
#
# The home apart (C9): H holds project sr, and each checkout is bound to sr by an untracked .felix. H's lanes.tsv is
# committed, replaced and removed by commits as the cases need, and every case checks that H's HEAD holds what it names.
# Each checkout's root is a month before the clock, its landings (_lf_chain) five days before it, an hour apart.
# Readings where the Contracts leave room:
# - "Byte-identical without the lane row's input" is read in one checkout and one home, before lanes.tsv is first
#   committed and after: every row but the lane row is compared, and that comparison is the control C10 names.
# - The status shape is D16's (part 1100's awk), checked over every felix status --tsv this part runs, together with
#   the ten rows ending in lane, so it is red on main.
# - Besides C6's cases: the first data row speaks when it sits under a comment and a blank line, when the row after it
#   is broken and when it is broken itself; the detail takes W and n/d from the table; with FELIX_LANE_NOW unset or
#   empty the machine clock is read (C9); plain felix status aligns the row as C6 says.
# - L-RO's marker is touched a second after the fixture's last write, and what the runs leave newer is printed in the
#   assertion. The checkout's refs and worktree list are compared before and after.
# - The review's second amendment (2026-10-30, design 11 item 45, still blind) adds C11's 1 day (F11) and a count that
#   ends early (F1), after the shape check.
LNTN=1793000000; LNTDAY=86400; LNTK=0
LNTNINE='settings schedule pulse reach gate land hooks alerts icloud '
LNTTEN="${LNTNINE}lane "
_lf_dir "$TMP/lane-2230"; LNTD="$LF_DIR"; mkdir -p "$LNTD/plain" "$LNTD/st"
_lf_stubs "$LNTD"; LNTB="$LF_BIN"
_lf_home "$LNTD/home" sr 1792600000; LNTH="$LF_HOME"; LNTP="$LF_PROJ"
_lf_use "$LNTH" "$LNTD/memory" "$LNTD/user" "$LNTB"
LNTLANES=$'# The lanes this fixture counts.\n\ncapability\t^engine/\t1/2\t14\n'
LNTUNG="$(_lf_tsv lane none - 'this directory is not a governed checkout')"
LNTNONE="$(_lf_tsv lane none - "$LNTP/lanes.tsv has no committed row, so no lane is counted")"
LNTVOK="$(_lf_tsv lane value ok '1 of 2 engine landings in 14 days, target 1/2')"
LNTPOK="$(printf '%-9s %-12s %s' lane ok '1 of 2 engine landings in 14 days, target 1/2')"

# NAME SPEC... -> LNTR a checkout $LNTD/NAME bound to sr, its root a month before the clock, then SPEC's landings
# (_lf_chain: m, u, md, ud) from five days before it, an hour apart, published. LNTE "built" when the first-parent chain
# of refs/remotes/origin/main holds the root and every landing.
_lnt_chk() {
  local n="$1"
  shift
  LNTE="not built: $n"; LNTR=""
  _lf_checkout "$LNTD/$n" sr $((LNTN - 30 * LNTDAY)) || return 1
  LNTR="$LF_REPO"
  _lf_chain "$LNTR" capability $((LNTN - 5 * LNTDAY)) 3600 "$@" || return 1
  [ "$(_lf_spine "$LNTR" | LC_ALL=C awk '{ print NF }')" = "$(($# + 1))" ] && LNTE=built
}
# DIR [NOW] -> felix status --tsv from DIR at the clock LNTN (or NOW: - unset, anything else as given, empty
# included), kept as $LNTD/st/<k>.out for the shape check at the end. LNTF the stem, LNTROWS the row names, a space
# after each, LNTLAST the last row, LF_RC the status.
_lnt_st() {
  LNTK=$((LNTK + 1)); LNTF="$LNTD/st/$LNTK"
  _lf_run "$LNTF" "$1" "${2-$LNTN}" "$FELIX" status --tsv
  LNTROWS="$(LC_ALL=C awk -F'\t' '{ printf "%s ", $1 }' "$LNTF.out")"
  LNTLAST="$(_lf_last "$LNTF.out")"
}
# LABEL BYTES -> H's lanes.tsv holds BYTES, committed at the next time; LNTT "built" when H's HEAD holds exactly them.
_lnt_put() {
  local f="$LNTD/put"
  LNTK=$((LNTK + 1)); LNTT="not built: lanes.tsv $1"
  rm -f "$LNTP/lanes.tsv"
  _lf_table "$LNTP" $((1792600000 + 100 * LNTK)) lanes.tsv "$2" "lanes.tsv: $1"$'\n' || return 1
  printf '%s' "$2" > "$f.want"
  ( _fx_cd "$LNTH" || exit 1; _lf_g 1700000000 cat-file blob HEAD:projects/sr/lanes.tsv ) > "$f.got" 2>/dev/null
  cmp -s "$f.want" "$f.got" && LNTT=built
}
# LABEL -> H's HEAD holds no lanes.tsv: a commit removes it when HEAD holds one. LNTT "built" when HEAD holds none.
_lnt_absent() {
  LNTK=$((LNTK + 1)); LNTT="not built: $1"
  if ( _fx_cd "$LNTH" && _lf_g 1700000000 cat-file -e HEAD:projects/sr/lanes.tsv ) >/dev/null 2>&1; then
    _lf_commit "$LNTP" $((1792600000 + 100 * LNTK)) "lanes.tsv removed: $1"$'\n' -lanes.tsv || return 1
  fi
  ( _fx_cd "$LNTH" && _lf_g 1700000000 cat-file -e HEAD:projects/sr/lanes.tsv ) >/dev/null 2>&1 || LNTT=built
}

# ---- one row more, at the end, and every row before it unchanged ----------------------------------------------------------
_lnt_chk ok m u; LNTOK="$LNTR"; LNTOKE="$LNTE"
_lnt_absent "never committed"; _lnt_st "$LNTOK"; LNTF0="$LNTF"
is "lane status row: with no lanes.tsv ever committed, felix status --tsv exits 0 with ten rows, main's nine in their order and then lane none - <PROJ>/lanes.tsv has no committed row, so no lane is counted" \
   "$LNTOKE|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" "built|built|0|$LNTTEN|$LNTNONE"
_lnt_put "the capability row" "$LNTLANES"; _lnt_st "$LNTOK"; LNTF1="$LNTF"
is "lane status row: with lanes.tsv committed, felix status --tsv prints exactly one row more than main, ten, the lane row last: lane value ok 1 of 2 engine landings in 14 days, target 1/2" \
   "$LNTOKE|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" "built|built|0|$LNTTEN|$LNTVOK"
LC_ALL=C awk -F'\t' '$1 != "lane"' "$LNTF0.out" > "$LNTD/before.0"
LC_ALL=C awk -F'\t' '$1 != "lane"' "$LNTF1.out" > "$LNTD/before.1"
is "lane status row: every row but the lane row is byte-identical with no lanes.tsv committed and with one committed, in the same checkout and home (control)" \
   "$LNTOKE|$LNTT|$(_lf_count "$LNTD/before.0")|$(_lf_count "$LNTD/before.1")|$(cmp -s "$LNTD/before.0" "$LNTD/before.1" && echo identical || echo different)" \
   "built|built|9|9|identical"
_lf_run "$LNTD/plain-ok" "$LNTOK" "$LNTN" "$FELIX" status
is "lane status row: plain felix status prints the lane row last, aligned as every row is: lane, the state word ok, the detail" \
   "$LNTOKE|$LNTT|$LF_RC|$(_lf_count "$LNTD/plain-ok.out")|$(_lf_last "$LNTD/plain-ok.out")" "built|built|0|10|$LNTPOK"

# ---- C6: no lane is counted -----------------------------------------------------------------------------------------------
_lnt_put "comments and a blank line, no row" $'# No lane is counted yet.\n\n'; _lnt_st "$LNTOK"
is "lane status row: a committed lanes.tsv holding only a comment and a blank line reads lane none - with the no-committed-row detail, last of ten" \
   "$LNTOKE|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" "built|built|0|$LNTTEN|$LNTNONE"
_lnt_absent "removed by a later commit"; printf '%s' "$LNTLANES" > "$LNTP/lanes.tsv"; _lnt_st "$LNTOK"
is "lane status row: a lanes.tsv with a row in the home's working tree, after a commit removed it, counts no lane: lane none - with the no-committed-row detail" \
   "$LNTOKE|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" "built|built|0|$LNTTEN|$LNTNONE"
_lf_run "$LNTD/plain-none" "$LNTOK" "$LNTN" "$FELIX" status
is "lane status row: plain felix status aligns the none row with the state word none in the value column" \
   "$LNTOKE|$LNTT|$LF_RC|$(_lf_last "$LNTD/plain-none.out")" \
   "built|built|0|$(printf '%-9s %-12s %s' lane none "$LNTP/lanes.tsv has no committed row, so no lane is counted")"

# ---- C6: no project governs ---------------------------------------------------------------------------------------------------
_lnt_put "the capability row again" "$LNTLANES"
_lnt_st "$LNTD/plain"
is "lane status row: in a directory no project governs, outside any repository, the lane row is lane none - this directory is not a governed checkout, last of ten" \
   "$LF_RC|$LNTROWS|$LNTLAST" "0|$LNTTEN|$LNTUNG"
LNTa="not built: an unbound repository"
_lf_init "$LNTD/unbound" && _lf_commit "$LNTD/unbound" $((LNTN - LNTDAY)) $'engine: a repository no project binds\n' engine/x.sh \
  && _lf_publish "$LNTD/unbound" && [ ! -e "$LNTD/unbound/.felix" ] && LNTa=built
_lnt_st "$LNTD/unbound"
is "lane status row: in a repository with refs/remotes/origin/main and an engine landing that no project binds (no .felix, no remote), the lane row is the same none row" \
   "$LNTa|$LF_RC|$LNTROWS|$LNTLAST" "built|0|$LNTTEN|$LNTUNG"
_lf_run "$LNTD/plain-ung" "$LNTD/plain" "$LNTN" "$FELIX" status
is "lane status row: plain felix status in a directory no project governs ends with lane, none, this directory is not a governed checkout, aligned" \
   "$LF_RC|$(_lf_last "$LNTD/plain-ung.out")" "0|$(printf '%-9s %-12s %s' lane none 'this directory is not a governed checkout')"

# ---- C6: the first lane's state ---------------------------------------------------------------------------------------------
_lnt_chk short m u u u
_lnt_st "$LNTR"
is "lane status row: L 1 of T 4 at share 1/2 reads lane value short 1 of 4 engine landings in 14 days, target 1/2" \
   "$LNTE|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" "built|built|0|$LNTTEN|$(_lf_tsv lane value short '1 of 4 engine landings in 14 days, target 1/2')"
_lnt_chk zero u u
_lnt_st "$LNTR"
is "lane status row: L 0 of T 2 reads lane value zero 0 of 2 engine landings in 14 days, target 1/2" \
   "$LNTE|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" "built|built|0|$LNTTEN|$(_lf_tsv lane value zero '0 of 2 engine landings in 14 days, target 1/2')"
_lnt_chk idle
_lnt_st "$LNTR"
is "lane status row: no landing in the window reads lane value idle 0 of 0 engine landings in 14 days, target 1/2" \
   "$LNTE|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" "built|built|0|$LNTTEN|$(_lf_tsv lane value idle '0 of 0 engine landings in 14 days, target 1/2')"

# ---- the first data row speaks, its window and share from the table -----------------------------------------------------
_lnt_put "another lane first, window 9, share 2/5" $'# Two lanes.\n\ntrust_b\t^engine/\t2/5\t9\ncapability\t^engine/\t1/2\t14\n'
_lnt_st "$LNTOK"
is "lane status row: the row speaks for the first data row, under a comment and a blank line, with its window and share from the table: lane trust_b reads value zero, 0 of 2 engine landings in 9 days, target 2/5" \
   "$LNTOKE|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" "built|built|0|$LNTTEN|$(_lf_tsv lane value zero '0 of 2 engine landings in 9 days, target 2/5')"
_lnt_put "a broken second row" $'capability\t^engine/\t1/2\t14\ndocs\t^docs/\t0/2\t14\n'
_lnt_st "$LNTOK"
is "lane status row: a second row whose share is 0/2 leaves the row speaking for the first: lane value ok 1 of 2 engine landings in 14 days, target 1/2" \
   "$LNTOKE|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" "built|built|0|$LNTTEN|$LNTVOK"
_lnt_put "a broken first row" $'capability\t(\t1/2\t14\ndocs\t^docs/\t1/2\t14\n'
_lnt_st "$LNTOK"
is "lane status row L-NEVER-OK: a first row whose counts is ( reads lane unknown - with R7 for that lane, never the value ok, though the row after it is valid" \
   "$LNTOKE|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" \
   "built|built|0|$LNTTEN|$(_lf_tsv lane unknown - 'the counts pattern of lane capability is not an ERE grep accepts')"

# ---- C6: unknown ------------------------------------------------------------------------------------------------------------------
_lnt_put "the capability row, for the unknown cases" "$LNTLANES"
_lf_checkout "$LNTD/noref" sr $((LNTN - 30 * LNTDAY)); LNTNR="$LF_REPO"; LNTa="not built: a checkout with no ref"
_lf_commit "$LNTNR" $((LNTN - LNTDAY)) $'engine: x\n\nFelix-Lane: capability\n' engine/x.sh \
  && LNTa="$( _fx_cd "$LNTNR" || exit 1; _lf_g 1700000000 rev-parse --verify -q refs/remotes/origin/main >/dev/null 2>&1 && echo has-ref || echo built )"
LNTR1="refs/remotes/origin/main cannot be read in $LNTNR"
_lnt_st "$LNTNR"
is "lane status row L-NEVER-OK: an unreadable ref (no refs/remotes/origin/main) gives state unknown and value -: lane unknown - refs/remotes/origin/main cannot be read in <repo>, never a calm value" \
   "$LNTa|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" "built|built|0|$LNTTEN|$(_lf_tsv lane unknown - "$LNTR1")"
_lf_run "$LNTD/plain-r1" "$LNTNR" "$LNTN" "$FELIX" status
is "lane status row L-NEVER-OK: plain felix status aligns the unknown row with the state word unknown in the value column" \
   "$LNTa|$LNTT|$LF_RC|$(_lf_last "$LNTD/plain-r1.out")" "built|built|0|$(printf '%-9s %-12s %s' lane unknown "$LNTR1")"
_lnt_st "$LNTOK" 12a
is "lane status row L-NEVER-OK: FELIX_LANE_NOW=12a over a valid table reads lane unknown - FELIX_LANE_NOW is not a whole number of seconds" \
   "$LNTOKE|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" "built|built|0|$LNTTEN|$(_lf_tsv lane unknown - 'FELIX_LANE_NOW is not a whole number of seconds')"
_lnt_put "a CR in its row" $'capability\t^engine/\t1/2\t14\r\n'
_lnt_st "$LNTOK"
is "lane status row L-NEVER-OK: a committed lanes.tsv the shape check refuses (a CR in its row) reads lane unknown - <PROJ>/lanes.tsv cannot be read as lanes.tsv" \
   "$LNTOKE|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" "built|built|0|$LNTTEN|$(_lf_tsv lane unknown - "$LNTP/lanes.tsv cannot be read as lanes.tsv")"

# ---- the clock: unset or empty is the machine's (C9) ---------------------------------------------------------------------------
_lnt_put "the capability row, for the clock" "$LNTLANES"
LNTNOW="$(date +%s)"; LNTa="not built: the clock checkout"
_lf_checkout "$LNTD/clock" sr $((LNTNOW - 30 * LNTDAY)); LNTCK="$LF_REPO"
_lf_chain "$LNTCK" capability $((LNTNOW - 3 * LNTDAY)) "$LNTDAY" m u \
  && [ "$(_lf_spine "$LNTCK")" = "$((LNTNOW - 2 * LNTDAY)):1 $((LNTNOW - 3 * LNTDAY)):1 $((LNTNOW - 30 * LNTDAY)):0" ] && LNTa=built
_lnt_st "$LNTCK" -; LNTb="$LF_RC|$LNTLAST"
_lnt_st "$LNTCK" ""; LNTb="$LNTb|$LF_RC|$LNTLAST"
_lnt_st "$LNTCK" $((LNTNOW - 4 * LNTDAY)); LNTb="$LNTb|$LF_RC|$LNTLAST"
is "lane status row: with FELIX_LANE_NOW unset, and set and empty, now is the machine clock, so landings three and two days back read value ok 1 of 2; with the clock four days back they read idle 0 of 0" \
   "$LNTa|$LNTT|$LNTb" \
   "built|built|0|$LNTVOK|0|$LNTVOK|0|$(_lf_tsv lane value idle '0 of 0 engine landings in 14 days, target 1/2')"

# ---- L-DET ---------------------------------------------------------------------------------------------------------------------------
_lnt_put "the capability row, for L-DET and L-RO" "$LNTLANES"
for LNTk in 1 2; do
  _lf_run "$LNTD/det-t$LNTk" "$LNTOK" "$LNTN" "$FELIX" status --tsv
  _lf_run "$LNTD/det-p$LNTk" "$LNTOK" "$LNTN" "$FELIX" status
  _lf_run "$LNTD/det-u$LNTk" "$LNTNR" "$LNTN" "$FELIX" status --tsv
  [ "$LNTk" = 2 ] || sleep 1
done
LNTa=""
for LNTk in det-t det-p det-u; do cmp -s "$LNTD/${LNTk}1.out" "$LNTD/${LNTk}2.out" && LNTa="$LNTa|same" || LNTa="$LNTa|differ"; done
is "lane status row L-DET: two runs a second apart of felix status --tsv and of felix status, same fixture and FELIX_LANE_NOW, print identical bytes, each ending with the expected lane row" \
   "$LNTOKE|$LNTT${LNTa%|*}|$(_lf_last "$LNTD/det-t1.out")|$(_lf_last "$LNTD/det-p1.out")" "built|built|same|same|$LNTVOK|$LNTPOK"
is "lane status row L-DET L-NEVER-OK: two runs of felix status --tsv in the checkout with no ref print identical bytes, ending with the unknown row" \
   "$LNTT|${LNTa##*|}|$(_lf_last "$LNTD/det-u1.out")" "built|same|$(_lf_tsv lane unknown - "$LNTR1")"

# ---- L-RO and the uncommitted edit ---------------------------------------------------------------------------------------------
# LABEL -> a marker touched a second after the last write, then felix status --tsv and felix status in the ok checkout;
# what they left newer under H (.git and its index included), the memory root and the checkout (.git included), and
# the checkout's refs and worktree list before and after.
_lnt_ro() {
  local f="$LNTD/ro" r1 r2 w1 w2 nw
  sleep 1; touch "$f.marker"
  r1="$( _fx_cd "$LNTOK" && _lf_g 1700000000 for-each-ref )"; w1="$( _fx_cd "$LNTOK" && _lf_g 1700000000 worktree list --porcelain )"
  _lf_run "$f-t" "$LNTOK" "$LNTN" "$FELIX" status --tsv; r2="$LF_RC"
  _lf_run "$f-p" "$LNTOK" "$LNTN" "$FELIX" status; r2="$r2|$LF_RC"
  nw="$(find "$LNTH" "$LNTD/memory" "$LNTOK" -newer "$f.marker" 2>&1)"
  w2="$( _fx_cd "$LNTOK" && _lf_g 1700000000 worktree list --porcelain )"
  r2="$r2|$([ -n "$r1" ] && [ "$r1" = "$( _fx_cd "$LNTOK" && _lf_g 1700000000 for-each-ref )" ] && echo same || echo changed)"
  is "lane status row L-RO: $1: felix status --tsv and felix status exit 0, leave nothing newer under the home, the memory root and the checkout, leave the checkout's refs and worktree list as they were, and print the committed lane row" \
     "$LNTOKE|$LNTT|newer[${nw}]|$r2|$([ -n "$w1" ] && [ "$w1" = "$w2" ] && echo same || echo changed)|$(_lf_last "$f-t.out")|$(_lf_last "$f-p.out")" \
     "built|built|newer[]|0|0|same|same|$LNTVOK|$LNTPOK"
}
_lnt_ro "as built"
touch "$LNTP/lanes.tsv"
_lnt_ro "after a touch of lanes.tsv, its content unchanged"
printf '%s' $'# The lanes this fixture counts.\n\ncapability\t^engine/\t1/4\t7\n' > "$LNTP/lanes.tsv"
_lnt_ro "after an uncommitted edit to lanes.tsv (share 1/4, window 7)"
printf '%s' "$LNTLANES" > "$LNTP/lanes.tsv"

# ---- the status shape, over every felix status --tsv above -------------------------------------------------------------------
LNTo=""; LNTc=0
for LNTw in "$LNTD"/st/*.out; do
  [ -f "$LNTw" ] || continue
  LNTc=$((LNTc + 1))
  LNTl="$(LC_ALL=C awk -F'\t' '{ printf "%s ", $1 }' "$LNTw")"
  [ "$LNTl" = "$LNTTEN" ] || LNTo="$LNTo [run ${LNTw##*/}: rows $LNTl]"
  LNTl="$(LC_ALL=C awk -F'\t' 'NF != 4 || $2 !~ /^(value|none|unknown)$/ || ($2 != "value" && $3 != "-") || $4 == "" || $3 ~ / / { print NR ": " $0 }' "$LNTw")"
  [ -z "$LNTl" ] || LNTo="$LNTo [run ${LNTw##*/}: line $LNTl]"
done
is "lane status row: every felix status --tsv this part ran prints ten rows ending in lane, and no row breaks D16's shape: four tab fields, a known state, - unless the state is value, a detail, a value with no space" \
   "$LNTc runs:$LNTo" "18 runs:"

# ---- the review's second amendment: 1 day (F11) and a count that ends early (F1) --------------------------------------
# Added on 2026-10-30, still blind, after the shape check, whose count of runs stands; these runs are not kept in st/.
_lnt_put "the capability row, window 1" $'capability\t^engine/\t1/2\t1\n'
_lf_run "$LNTD/f11" "$LNTOK" "$LNTN" "$FELIX" status --tsv
is "lane status row F11-one-day-reads-1-days: with window 1 and no landing in the last day, the row reads lane value idle 0 of 0 engine landings in 1 day, target 1/2, never 1 days, the last of ten" \
   "$LNTOKE|$LNTT|$LF_RC|$(LC_ALL=C awk -F'\t' '{ printf "%s ", $1 }' "$LNTD/f11.out")|$(_lf_last "$LNTD/f11.out")" \
   "built|built|0|$LNTTEN|$(_lf_tsv lane value idle '0 of 0 engine landings in 1 day, target 1/2')"
# C9's fault through _lf_fault kill, with TMPDIR a directory of the fixture's own, in the ok checkout: when the read of
# the landings starts, the shell that runs it has its parent, then itself, killed. C6 and C9 allow two rows, and the
# assertion accepts exactly these: the lane count did not finish in <repo>, or, where the process ended was one read's
# own, R2. felix status still exits 0 with its ten rows (C6).
_lnt_put "the capability row, for a count that ends early" "$LNTLANES"
LNTkt="$LNTD/f1k-tmp"; rm -rf "$LNTkt"; mkdir -p "$LNTkt"
_lf_fault kill "$LNTD/f1k.fired" "$LNTkt" _lf_run "$LNTD/f1k" "$LNTOK" "$LNTN" "$FELIX" status --tsv
LNTa="$(_lf_last "$LNTD/f1k.out")"
case "$LNTa" in
  ("$(_lf_tsv lane unknown - "the lane count did not finish in $LNTOK")"|"$(_lf_tsv lane unknown - "git could not read the landings on refs/remotes/origin/main in $LNTOK")") LNTa="C3 or R2" ;;
  (*) LNTa="last row [$LNTa]" ;;
esac
is "lane status row F1-count-ends-early L-NEVER-OK: the parent of the shell that runs the read of the landings, then that shell, killed (C9): felix status --tsv exits 0 with ten rows, the last lane unknown - the lane count did not finish in <repo>, or lane unknown - with R2; never a value, the none row or no lane row" \
   "$LNTOKE|$LNTT|$LF_FIRE|$LF_RC|$(LC_ALL=C awk -F'\t' '{ printf "%s ", $1 }' "$LNTD/f1k.out")|$LNTa" "built|built|fired|0|$LNTTEN|C3 or R2"

# ---- the second review's round 1: a resolution that fails, and plain status losing rows (R2-F3, R2-F7) ----------------
# Added on 2026-10-30 from the second review's findings (their inputs and observed output only), still blind, after the
# shape check, whose count of runs stands. In the review's home-apart fixture (_lf_r2, the clock at LNTN), where the lane
# row reads value zero 0 of 2. The faults are the review's probes (_lf_fork), by the words and calling functions it
# names, inputs of the findings: R2-F3 a fork that fails at tr -d [:space:] in felix_resolve_project under
# felix_status_rows; R2-F7 a function command that lowers the limit at command -v felix_capture, so the shell that asked
# fails at its next fork (it reaches the land and hooks rows too, as the review says). Readings: C6's none row is for a
# directory no project governs, so a resolution that did not finish gives the value row, lane unknown - with a reason,
# or, as C3 says of a fork that fails in the surface's own shell, felix status ended with status 128; plain felix status
# prints ten rows ending in the lane row, value or unknown, aligned, or ends with 128, never exit 0 without the lane row.
# Each assertion also compares the run without the fault, so it is red on main.
LNTRT="$LNTD/r2-tmp"; mkdir -p "$LNTRT"; LNTRA="not built: the second review's fixture"; LNTtb=$'\t'
_lf_r2 "$LNTD/r2" p "$LNTN" && LNTRA=built
LNTRC="$LF_REPO"
_lf_use "$LF_HOME" "$LNTD/memory" "$LNTD/user" "$LNTB"
LNTRV="$(_lf_tsv lane value zero '0 of 2 engine landings in 14 days, target 1/2')"
LNTRP="$(printf '%-9s %-12s %s' lane zero '0 of 2 engine landings in 14 days, target 1/2')"
_lf_run "$LNTD/r2f3-0" "$LNTRC" "$LNTN" "$FELIX" status --tsv
LNTb="$LF_RC|$(LC_ALL=C awk -F'\t' '{ printf "%s ", $1 }' "$LNTD/r2f3-0.out")|$(_lf_last "$LNTD/r2f3-0.out")"
_lf_fork fork tr "*' -d [:space:] '*" "*' felix_resolve_project felix_status_rows '*|*' felix_resolve_project '*' felix_status_rows '*" \
  "$LNTD/r2f3.fired" "$LNTRT" _lf_run "$LNTD/r2f3" "$LNTRC" "$LNTN" "$FELIX" status --tsv
LNTa="$(_lf_last "$LNTD/r2f3.out")"; LNTc="$(LC_ALL=C awk -F'\t' '{ printf "%s ", $1 }' "$LNTD/r2f3.out")"
case "$LF_RC|$LNTc|$LNTa" in
  ("128|"*|"0|$LNTTEN|$LNTRV") LNTa="value, unknown or 128" ;;
  ("0|$LNTTEN|lane${LNTtb}unknown${LNTtb}-${LNTtb}"?*) case "${LNTa##*"$LNTtb"}" in (-) LNTa="status 0, last [$LNTa]" ;; (*) LNTa="value, unknown or 128" ;; esac ;;
  (*) LNTa="status $LF_RC, rows [$LNTc], last [$LNTa]" ;;
esac
is "lane status row R2-F3-status-none-row-when-resolution-fails L-NEVER-OK: a fork that fails while felix status --tsv resolves the project (tr -d [:space:] in felix_resolve_project, under felix_status_rows), in a checkout the project governs: the lane row is the value zero 0 of 2 or lane unknown - with a reason, the last of ten, or felix status ends with 128; never the none row this directory is not a governed checkout" \
   "$LNTRA|unfaulted $LNTb|$LF_FIRE|$LNTa" "built|unfaulted 0|$LNTTEN|$LNTRV|fired|value, unknown or 128"
_lf_run "$LNTD/r2f7-0" "$LNTRC" "$LNTN" "$FELIX" status; LNTb="$LF_RC|$(_lf_count "$LNTD/r2f7-0.out")|$(_lf_last "$LNTD/r2f7-0.out")"
_lf_fork lower command "' -v felix_capture '" '*' "$LNTD/r2f7.fired" "$LNTRT" _lf_run "$LNTD/r2f7" "$LNTRC" "$LNTN" "$FELIX" status
LNTa="$(_lf_last "$LNTD/r2f7.out")"; LNTc="$(_lf_count "$LNTD/r2f7.out")"
case "$LF_RC|$LNTc|$LNTa" in
  ("128|"*|"0|10|$LNTRP"|"0|10|$(printf '%-9s %-12s ' lane unknown)"?*) LNTa="ten rows or 128" ;;
  (*) LNTa="status $LF_RC, $LNTc rows, last [$LNTa]" ;;
esac
is "lane status row R2-F7-plain-status-loses-rows-with-exit-0 L-NEVER-OK: plain felix status with a function command that lowers the process limit at command -v felix_capture, so the shell that asked fails at its next fork: ten rows ending in the lane row, zero or unknown, aligned, or felix status ends with 128; never exit 0 without the lane row" \
   "$LNTRA|unfaulted $LNTb|$LF_FIRE|$LNTa" "built|unfaulted 0|10|$LNTRP|fired|ten rows or 128"
# <<< lane-status-row
