# >>> lane-session-start
printf '\nlane session start: the paragraph and the screen token, where they show and where they stay silent (slice 0, design 6.5 items 3 and 4 and 6.6, C7, L-RF2 to L-RF5, L-RO; blind)\n'
# Blind, written on 2026-10-29 from docs/2026-10-29-capability-lane-first-slices-design.md and the slice 0 plan's
# Contracts (C1-C13) alone, before lib/lane.sh existed, without reading lib/, hooks/, bin/ or felix. Felix is run as a
# black box; the builders are tests/lib/lane-fixture.sh's. C11's row for this part: section 6.5 items 3 and 4 and 6.6
# "What shows where": the paragraph only for short, zero and idle, the token only for zero and idle, neither without a
# committed lanes.tsv; the exact paragraph at share 1/2 and at 1/4; a Claude Code resume; L-RF2; L-RF4; the
# session-start half of L-RO; the hook with lib/lane.sh removed from a harness copy. With them, the session-start halves
# of L-RF3 and L-RF5.
#
# The home apart (C9): H holds project sx, each checkout is bound to sx by an untracked .felix, and H's lanes.tsv and
# lane-next.tsv are committed as each case needs; every case checks that H's HEAD holds what it names. Each checkout's
# root is a month before the clock, its landings (_lf_chain) five days before it, an hour apart. Session start runs as C9
# says (_lf_start): the suite's hooks/session-start, a startup payload, the fixture HOME and memory root, the stubs first
# on PATH, then up to 20 s for the discovery lock. Its JSON is read with python3, and every assertion that reads it is
# skipped, with the reason, when python3 is absent. Readings where the Contracts leave room:
# - A paragraph is asserted as C7 places it in the context, LF, its first line, LF, its second line, LF, and counted:
#   once, or not at all. On this engine the screen line of such a session is "Felix: sx" alone, so the token is asserted
#   on the whole line, which also shows it last and once.
# - "While the share is 1/2" is C12 item 10's 2n = d: 2/4 closes as 1/2 does, and 1/4 and 1/3 as any other share.
# - The placement case adds a pull request waiting in the lander's ledger, as part 1670's A43 builds it, so a "what
#   waits" paragraph comes before the lane paragraph and a PRs waiting token before the lane token.
# - L-RF2's control bytes are ESC and FF, as C10 names them, and 0x01 and DEL from C7's range: each reads ? in the
#   context and stands unchanged in felix lane --tsv column 9.
# - The controls are C10's: silence for ok, unknown, no committed lanes.tsv or none with a row, a Claude Code resume and
#   a directory no project governs; L-RF3's and L-RF5's session-start halves; L-RO's; the broken engine. Each silent
#   case that has a lane uses a checkout where the committed 1/2 table shows the paragraph and the token.
LNGN=1793000000; LNGDAY=86400; LNGK=0
LNGNEXT='obligation intake, slice 1: felix situations --change (branch claude/lane-situations-owed)'
LNGPY=0; command -v python3 >/dev/null 2>&1 && LNGPY=1
LNGWHY="python3 is absent, and the hook's JSON is read with it"
_lf_dir "$TMP/lane-2240"; LNGD="$LF_DIR"; mkdir -p "$LNGD/plain"
_lf_stubs "$LNGD"; LNGB="$LF_BIN"
_lf_home "$LNGD/home" sx 1792500000; LNGH="$LF_HOME"; LNGP="$LF_PROJ"
_lf_use "$LNGH" "$LNGD/memory" "$LNGD/user" "$LNGB"
LNGLANES=$'capability\t^engine/\t1/2\t14\n'
LNGNEXTS="$(_lf_tsv capability "$LNGNEXT")"$'\n'
LNGSCR='Felix: sx'; LNGTOK14="$LNGSCR · lane: 0 in 14 days"
LNGCLH='Trust work takes the other half.'; LNGCLR='The rest goes to trust work.'
# STATE L T W SHARE NEXT CLOSING [LANE] -> the paragraph's two lines (C7), a newline between them.
_lng_par() {
  printf 'Lane %s is %s: %s of %s engine landings in %s days, target %s.\nIf the founder has not given this session a task, take the first open lane item: %s. End the body of a commit on its branch that is not a merge with the line `Felix-Lane: %s`. %s' \
    "${8:-capability}" "$1" "$2" "$3" "$4" "$5" "$6" "${8:-capability}" "$7"
}
LNGZ12="$(_lng_par zero 0 2 14 1/2 "$LNGNEXT" "$LNGCLH")"

# NAME SPEC... -> LNGR a checkout $LNGD/NAME bound to sx, its root a month before the clock, then SPEC's landings
# (_lf_chain) from five days before it, an hour apart, published. LNGE "built" when the first-parent chain of
# refs/remotes/origin/main holds the root and every landing.
_lng_chk() {
  local n="$1"
  shift
  LNGE="not built: $n"; LNGR=""
  _lf_checkout "$LNGD/$n" sx $((LNGN - 30 * LNGDAY)) || return 1
  LNGR="$LF_REPO"
  _lf_chain "$LNGR" capability $((LNGN - 5 * LNGDAY)) 3600 "$@" || return 1
  [ "$(_lf_spine "$LNGR" | LC_ALL=C awk '{ print NF }')" = "$(($# + 1))" ] && LNGE=built
}
# REL BYTES -> H's HEAD holds projects/sx/REL as exactly BYTES; status 0 when it does.
_lng_holds() {
  printf '%s' "$2" > "$LNGD/holds.want"
  ( _fx_cd "$LNGH" || exit 1; _lf_g 1700000000 cat-file blob "HEAD:projects/sx/$1" ) > "$LNGD/holds.got" 2>/dev/null
  cmp -s "$LNGD/holds.want" "$LNGD/holds.got"
}
_lng_lacks() { ! ( _fx_cd "$LNGH" && _lf_g 1700000000 cat-file -e "HEAD:projects/sx/$1" ) >/dev/null 2>&1; }
# LABEL LANES [NEXT] -> lanes.tsv LANES and lane-next.tsv NEXT (LNGNEXTS when not given; - for none), committed in H
# at the next times. LNGT "built" when H's HEAD holds exactly those bytes, and no lane-next.tsv for -.
_lng_put() {
  local n="${3-$LNGNEXTS}" t
  LNGK=$((LNGK + 1)); t=$((1792500000 + 100 * LNGK)); LNGT="not built: $1"
  rm -f "$LNGP/lanes.tsv" "$LNGP/lane-next.tsv"
  _lf_table "$LNGP" "$t" lanes.tsv "$2" "lanes.tsv: $1"$'\n' || return 1
  if [ "$n" = - ]; then
    _lng_lacks lane-next.tsv || _lf_commit "$LNGP" $((t + 50)) "lane-next.tsv removed: $1"$'\n' -lane-next.tsv || return 1
    _lng_holds lanes.tsv "$2" && _lng_lacks lane-next.tsv && LNGT=built
  else
    _lf_table "$LNGP" $((t + 50)) lane-next.tsv "$n" "lane-next.tsv: $1"$'\n' || return 1
    _lng_holds lanes.tsv "$2" && _lng_holds lane-next.tsv "$n" && LNGT=built
  fi
}
# LABEL -> H's HEAD holds neither table: commits remove the ones it holds. LNGT "built" when so.
_lng_absent() {
  local f
  LNGK=$((LNGK + 1)); LNGT="not built: $1"
  for f in lanes.tsv lane-next.tsv; do
    _lng_lacks "$f" || _lf_commit "$LNGP" $((1792500000 + 100 * LNGK)) "$f removed: $1"$'\n' "-$f" || return 1
  done
  _lng_lacks lanes.tsv && _lng_lacks lane-next.tsv && LNGT=built
}
# DIR [NOW [SOURCE [ROOT]]] -> session start in DIR (_lf_start: the clock LNGN, source startup, the suite's engine);
# LNGF the stem of its files, LF_RC, LF_JSON, LF_CTX, LF_SCR as _lf_start sets them.
_lng_ss() {
  LNGK=$((LNGK + 1)); LNGF="$LNGD/ss-$LNGK"
  _lf_start "$LNGF" "$1" "${2-$LNGN}" "${3:-startup}" ${4+"$4"}
}
# TEXT -> how many times the last session's context holds LF TEXT LF (C7); "unread" when python3 cannot say.
_lng_n() {
  printf '%s' "$1" > "$LNGD/want"
  python3 -c 'import sys
d = open(sys.argv[1], "rb").read(); t = b"\n" + open(sys.argv[2], "rb").read() + b"\n"
sys.stdout.write(str(d.count(t)))' "$LNGF.ctx" "$LNGD/want" 2>/dev/null || printf 'unread'
}
# TEXT -> the byte offset of LF TEXT LF in the last context, -1 when it is not there.
_lng_at() {
  printf '%s' "$1" > "$LNGD/want"
  python3 -c 'import sys
d = open(sys.argv[1], "rb").read(); t = b"\n" + open(sys.argv[2], "rb").read() + b"\n"
sys.stdout.write(str(d.find(t)))' "$LNGF.ctx" "$LNGD/want" 2>/dev/null || printf 'unread'
}
# LINE -> "between" when the last context's line LINE comes after its first line starting "Memory: ", after the
# waiting-PR header and before its first line starting "Read before planning:", else the four line numbers.
_lng_where() {
  LC_ALL=C awk -v p="$1" -v w="Pull requests waiting longer than four hours" '
    index($0, "Memory: ") == 1 && !m { m = NR } index($0, "Read before planning:") == 1 && !r { r = NR }
    index($0, w) == 1 && !x { x = NR } $0 == p && !l { l = NR }
    END { print (m && x && l && r && m < x && x < l && l < r) ? "between" : "out(" m "," x "," l "," r ")" }' "$LNGF.ctx" 2>/dev/null
}
_lng_is() { if [ "$LNGPY" = 1 ]; then is "$1" "$2" "$3"; else skip "$1" "$LNGWHY"; fi; }

_lng_chk zero u u; LNGZ="$LNGR"; LNGZE="$LNGE"
_lng_chk short m u u u; LNGS="$LNGR"; LNGSE="$LNGE"
_lng_chk ok m u; LNGO="$LNGR"; LNGOE="$LNGE"
_lng_chk idle; LNGI="$LNGR"; LNGIE="$LNGE"

# ---- the paragraph and the token, by state, at share 1/2 ---------------------------------------------------------------
_lng_put "share 1/2" "$LNGLANES"
_lng_ss "$LNGZ"
_lng_is "lane session start: zero at share 1/2: exit 0, valid JSON, the context holds the paragraph once, word for word, ending Trust work takes the other half., and the screen line ends with the token · lane: 0 in 14 days" \
   "$LNGZE|$LNGT|$LF_RC|$LF_JSON|$(_lng_n "$LNGZ12")|$LF_SCR" "built|built|0|ok|1|$LNGTOK14"
_lng_ss "$LNGS"
_lng_is "lane session start: short at share 1/2 (L 1 of T 4): the context holds the short paragraph once, and the screen line carries no lane token" \
   "$LNGSE|$LNGT|$LF_RC|$LF_JSON|$(_lng_n "$(_lng_par short 1 4 14 1/2 "$LNGNEXT" "$LNGCLH")")|$LF_SCR" "built|built|0|ok|1|$LNGSCR"
_lng_ss "$LNGI"
_lng_is "lane session start: idle at share 1/2 (no landing in the window): the context holds the idle paragraph once, 0 of 0, and the screen line ends with · lane: 0 in 14 days" \
   "$LNGIE|$LNGT|$LF_RC|$LF_JSON|$(_lng_n "$(_lng_par idle 0 0 14 1/2 "$LNGNEXT" "$LNGCLH")")|$LF_SCR" "built|built|0|ok|1|$LNGTOK14"
_lng_ss "$LNGO"
_lng_is "lane session start: ok at share 1/2 (L 1 of T 2): exit 0, valid JSON, neither a lane paragraph nor a lane token (control)" \
   "$LNGOE|$LNGT|$LF_RC|$LF_JSON|$(_lf_silent capability)" "built|built|0|ok|none"
_lf_checkout "$LNGD/noref" sx $((LNGN - 30 * LNGDAY)); LNGNR="$LF_REPO"; LNGa="not built: a checkout with no ref"
_lf_commit "$LNGNR" $((LNGN - LNGDAY)) $'engine: x\n' engine/x.sh \
  && LNGa="$( _fx_cd "$LNGNR" || exit 1; _lf_g 1700000000 rev-parse --verify -q refs/remotes/origin/main >/dev/null 2>&1 && echo has-ref || echo built )"
_lng_ss "$LNGNR"
_lng_is "lane session start: unknown, a checkout with no refs/remotes/origin/main: exit 0, valid JSON, neither a lane paragraph nor a lane token (control)" \
   "$LNGa|$LNGT|$LF_RC|$LF_JSON|$(_lf_silent capability)" "built|built|0|ok|none"
_lng_ss "$LNGZ" "$LNGN" resume
_lng_is "lane session start: a Claude Code resume where startup shows the zero paragraph and token exits 0 with neither (control)" \
   "$LNGZE|$LNGT|$LF_RC|$(_lf_silent capability)" "built|built|0|none"
_lng_ss "$LNGD/plain"
_lng_is "lane session start: in a directory no project governs, session start exits 0 with neither a lane paragraph nor a lane token (control)" \
   "$LF_RC|$(_lf_silent capability)" "0|none"

# ---- where the paragraph sits, and an uncommitted edit ------------------------------------------------------------------
LNGNOW="$(date +%s)"; LNGL="$LNGD/memory/sx/land"; LNGT30="$(_lf_iso $((LNGNOW - 108000)))"
LNGW="waits on a session since $LNGT30: session: no checkout holds the gated head"
mkdir -p "$LNGL"
printf '%s\tsession\t425\t%s\t-\t0\t%s\n' "$LNGT30" 0425c0ffeec0ffeec0ffeec0ffeec0ffeec0ffee 'no checkout holds the gated head' > "$LNGL/ledger.tsv"
printf '%s\twaiting\t425\t%s\t-\t0\t%s\n' "$(_lf_iso $((LNGNOW - 7200)))" 0425c0ffeec0ffeec0ffeec0ffeec0ffeec0ffee "$LNGW" >> "$LNGL/ledger.tsv"
_lng_ss "$LNGZ"
_lng_is "lane session start: with a pull request waiting, the zero paragraph sits after Memory: and after the waiting-PR paragraph, before Read before planning:, and the lane token is last on the screen line, after PRs waiting: 1" \
   "$LNGZE|$LNGT|$LF_RC|$(_lng_n "$LNGZ12")|$(_lng_where 'Lane capability is zero: 0 of 2 engine landings in 14 days, target 1/2.')|$LF_SCR" \
   "built|built|0|1|between|$LNGSCR · PRs waiting: 1 · lane: 0 in 14 days"
rm -rf "$LNGL"
printf '%s' $'capability\t^engine/\t1/4\t7\n' > "$LNGP/lanes.tsv"; printf '%s\n' "$(_lf_tsv capability 'an item never committed')" > "$LNGP/lane-next.tsv"
_lng_ss "$LNGZ"
_lng_is "lane session start: uncommitted edits to lanes.tsv (share 1/4, window 7) and lane-next.tsv change nothing: the paragraph and the token read the committed share 1/2, 14 days and next" \
   "$LNGZE|$LNGT|$LF_RC|$(_lng_n "$LNGZ12")|$LF_SCR" "built|built|0|1|$LNGTOK14"

# ---- the closing sentence, and the lane and window from the table ---------------------------------------------------------
_lng_put "share 1/4" $'capability\t^engine/\t1/4\t14\n'
_lng_ss "$LNGZ"
_lng_is "lane session start: zero at share 1/4: the paragraph, word for word, ends The rest goes to trust work., and the token is · lane: 0 in 14 days" \
   "$LNGZE|$LNGT|$LF_RC|$LF_JSON|$(_lng_n "Lane capability is zero: 0 of 2 engine landings in 14 days, target 1/4."$'\n'"If the founder has not given this session a task, take the first open lane item: $LNGNEXT. End the body of a commit on its branch that is not a merge with the line \`Felix-Lane: capability\`. The rest goes to trust work.")|$LF_SCR" \
   "built|built|0|ok|1|$LNGTOK14"
_lng_put "share 2/4" $'capability\t^engine/\t2/4\t14\n'
_lng_ss "$LNGZ"
_lng_is "lane session start: zero at share 2/4, where 2n = d as at 1/2: the paragraph ends Trust work takes the other half." \
   "$LNGZE|$LNGT|$LF_RC|$(_lng_n "$(_lng_par zero 0 2 14 2/4 "$LNGNEXT" "$LNGCLH")")|$LF_SCR" "built|built|0|1|$LNGTOK14"
_lng_put "lane cap.lane_2, window 9, share 1/3" $'cap.lane_2\t^engine/\t1/3\t9\n' "$(_lf_tsv cap.lane_2 "the second lane's own item")"$'\n'
_lng_ss "$LNGZ"
_lng_is "lane session start: the paragraph and the token take the lane name and the window from the table: lane cap.lane_2, 9 days, share 1/3, its mark and its next, and · lane: 0 in 9 days" \
   "$LNGZE|$LNGT|$LF_RC|$(_lng_n "$(_lng_par zero 0 2 9 1/3 "the second lane's own item" "$LNGCLR" cap.lane_2)")|$LF_SCR" \
   "built|built|0|1|$LNGSCR · lane: 0 in 9 days"

# ---- two rows: a paragraph per row, the token from the first ----------------------------------------------------------------
_lng_put "ok first, then an idle docs lane" $'capability\t^engine/\t1/2\t14\ndocs\t^docs/\t1/2\t14\n' \
  "$LNGNEXTS$(_lf_tsv docs 'the docs item')"$'\n'
_lng_ss "$LNGO"
_lng_is "lane session start: a first row ok and a second idle: the idle row's paragraph only, none for the ok lane, and no token, since the first row is ok" \
   "$LNGOE|$LNGT|$LF_RC|$(_lng_n "$(_lng_par idle 0 0 14 1/2 'the docs item' "$LNGCLH" docs)")|$(case "$LF_CTX" in (*'Lane capability is '*) echo 'a capability paragraph' ;; (*) echo none ;; esac)|$LF_SCR" \
   "built|built|0|1|none|$LNGSCR"
_lng_put "zero first, then short" $'trust\t^engine/\t1/2\t10\ncapability\t^engine/\t1/2\t14\n' \
  "$(_lf_tsv trust 'the trust item')"$'\n'"$LNGNEXTS"
_lng_ss "$LNGS"
LNGa="$(_lng_at "$(_lng_par zero 0 4 10 1/2 'the trust item' "$LNGCLH" trust)")"; LNGb="$(_lng_at "$(_lng_par short 1 4 14 1/2 "$LNGNEXT" "$LNGCLH")")"
_lng_is "lane session start: a first row zero (window 10) and a second short: both paragraphs, in file order, and the token from the first row, · lane: 0 in 10 days" \
   "$LNGSE|$LNGT|$LF_RC|$([ "$LNGa" -ge 0 ] 2>/dev/null && [ "$LNGb" -gt "$LNGa" ] 2>/dev/null && echo 'in order' || echo "at $LNGa and $LNGb")|$LF_SCR" \
   "built|built|0|in order|$LNGSCR · lane: 0 in 10 days"

# ---- L-RF2: next is free text -------------------------------------------------------------------------------------------------------
LNGQ='fix "a\b" — now'
_lng_put "next with a quote, a backslash and an em dash" "$LNGLANES" "$(_lf_tsv capability "$LNGQ")"$'\n'
_lng_ss "$LNGZ"; _lf_run "$LNGD/rf2a" "$LNGZ" "$LNGN" "$FELIX" lane --tsv
_lng_is "lane session start L-RF2: next holding a double quote, a backslash and an em dash, the lane zero: exit 0, valid JSON, the context holds the next text byte for byte in the paragraph, and felix lane --tsv prints it unchanged in column 9" \
   "$LNGZE|$LNGT|$LF_RC|$LF_JSON|$(_lng_n "$(_lng_par zero 0 2 14 1/2 "$LNGQ" "$LNGCLH")")|$(_lf_cols "$LNGD/rf2a.out" 1 2 9)" \
   "built|built|0|ok|1|zero|$LNGQ"
LNGQ=$'esc \033[1m bold\014page \001 one \177 del'
_lng_put "next with ESC, FF, 0x01 and DEL" "$LNGLANES" "$(_lf_tsv capability "$LNGQ")"$'\n'
_lng_ss "$LNGZ"; _lf_run "$LNGD/rf2b" "$LNGZ" "$LNGN" "$FELIX" lane --tsv
_lng_is "lane session start L-RF2: next holding ESC, FF, 0x01 and DEL: the output still parses, the context holds ? in their places, and felix lane --tsv column 9 prints the bytes unchanged" \
   "$LNGZE|$LNGT|$LF_RC|$LF_JSON|$(_lng_n "$(_lng_par zero 0 2 14 1/2 'esc ?[1m bold?page ? one ? del' "$LNGCLH")")|$(_lf_cols "$LNGD/rf2b.out" 1 2 9)" \
   "built|built|0|ok|1|zero|$LNGQ"

# ---- L-RF4: a broken pointer never silences a stall ------------------------------------------------------------------------
# LABEL NEXT-READ IN-PARAGRAPH -> session start and felix lane --tsv in the zero checkout, as committed now.
_lng_rf4() {
  _lng_ss "$LNGZ"; _lf_run "$LNGD/rf4" "$LNGZ" "$LNGN" "$FELIX" lane --tsv
  _lng_is "lane session start L-RF4: $1: felix lane --tsv reads zero, L 0 of T 2, next $2, and session start shows the paragraph with $3 and the token" \
     "$LNGZE|$LNGT|$LF_RC|$LF_JSON|$(_lf_cols "$LNGD/rf4.out" 1 2 3 4 9)|$(_lng_n "$(_lng_par zero 0 2 14 1/2 "$3" "$LNGCLH")")|$LF_SCR" \
     "built|built|0|ok|zero|0|2|$2|1|$LNGTOK14"
}
_lng_put "no lane-next.tsv" "$LNGLANES" -
_lng_rf4 "no committed lane-next.tsv" none "(lane-next.tsv names none)"
_lng_put "lane-next.tsv with a CR" "$LNGLANES" "$(_lf_tsv capability "$LNGNEXT")"$'\r\n'
_lng_rf4 "a committed lane-next.tsv the shape check refuses, a CR in its row" unknown "(lane-next.tsv cannot be read)"
_lng_put "two next rows" "$LNGLANES" "$LNGNEXTS$(_lf_tsv capability 'a second item')"$'\n'
_lng_rf4 "two committed lane-next.tsv rows for the lane" unknown "(lane-next.tsv cannot be read)"

# ---- no committed lanes.tsv, or none with a row ---------------------------------------------------------------------------------
_lng_absent "no table"
_lng_ss "$LNGZ"
_lng_is "lane session start: with no lanes.tsv committed, session start exits 0 with valid JSON and neither a lane paragraph nor a lane token (control)" \
   "$LNGZE|$LNGT|$LF_RC|$LF_JSON|$(_lf_silent capability)" "built|built|0|ok|none"
printf '%s' "$LNGLANES" > "$LNGP/lanes.tsv"; printf '%s' "$LNGNEXTS" > "$LNGP/lane-next.tsv"
_lng_ss "$LNGZ"
_lng_is "lane session start: with both tables in the home's working tree and neither committed, neither a lane paragraph nor a lane token (control)" \
   "$LNGZE|$LNGT|$LF_RC|$LF_JSON|$(_lf_silent capability)" "built|built|0|ok|none"
_lng_put "comments and a blank line, no row" $'# No lane is counted yet.\n\n'
_lng_ss "$LNGZ"
_lng_is "lane session start: with a committed lanes.tsv holding no row, neither a lane paragraph nor a lane token (control)" \
   "$LNGZE|$LNGT|$LF_RC|$LF_JSON|$(_lf_silent capability)" "built|built|0|ok|none"

# ---- L-RF3's session-start half: a table broken by hand, committed (controls) ----------------------------------------------
# LABEL BYTES [NOW] -> lanes.tsv BYTES committed, then session start in the zero checkout.
_lng_rf3() {
  _lng_put "$1" "$2"
  _lng_ss "$LNGZ" "${3-$LNGN}"
  _lng_is "lane session start L-RF3: $1: session start exits 0 with valid JSON and neither a lane paragraph nor a lane token (control)" \
     "$LNGZE|$LNGT|$LF_RC|$LF_JSON|$(_lf_silent capability)" "built|built|0|ok|none"
}
for LNGw in 1/0 3/2 0/2 1/2/3; do _lng_rf3 "share $LNGw" "$(_lf_tsv capability '^engine/' "$LNGw" 14)"$'\n'; done
for LNGw in 0 14d 014; do _lng_rf3 "window $LNGw" "$(_lf_tsv capability '^engine/' 1/2 "$LNGw")"$'\n'; done
_lng_rf3 "counts (" $'capability\t(\t1/2\t14\n'
_lng_rf3 "a lane named on two rows" $'capability\t^engine/\t1/2\t14\ncapability\t^engine/\t1/2\t14\n'
_lng_rf3 "a CR in a row" $'capability\t^engine/\t1/2\t14\r\n'
_lng_rf3 "no final newline" $'capability\t^engine/\t1/2\t14'
_lng_rf3 "an empty cell" $'capability\t\t1/2\t14\n'
_lng_rf3 "a row of three cells" $'capability\t^engine/\t1/2\n'
_lng_rf3 "FELIX_LANE_NOW=0123 over a valid table" "$LNGLANES" 0123

# ---- L-RF5's session-start half: a shallow clone (control) ---------------------------------------------------------------
_lng_put "share 1/2, for the shallow clone, L-RO and the broken engine" "$LNGLANES"
_lng_chk rf5-source u u u; LNGa="not built: the shallow clone"
if [ "$LNGE" = built ] && ( _fx_cd "$LNGD" && _lf_g 1700000000 clone -q --depth 2 "file://$LNGR" rf5 ) >/dev/null 2>&1; then
  { printf 'sx\n' > "$LNGD/rf5/.felix"; } 2>/dev/null
  LNGa="$( _fx_cd "$LNGD/rf5" || exit 1; [ "$(_lf_g 1700000000 rev-parse --is-shallow-repository)" = true ] \
           && _lf_g 1700000000 rev-parse --verify -q refs/remotes/origin/main >/dev/null && echo built )"
fi
_lng_ss "$LNGD/rf5"
_lng_is "lane session start L-RF5: in a --depth 2 clone holding refs/remotes/origin/main, session start exits 0 with valid JSON and neither a lane paragraph nor a lane token (control)" \
   "${LNGa:-not built: the shallow clone}|$LNGT|$LF_RC|$LF_JSON|$(_lf_silent capability)" "built|built|0|ok|none"

# ---- L-RO's session-start half (control) ----------------------------------------------------------------------------------
touch "$LNGP/lanes.tsv"; sleep 1; touch "$LNGD/ro.marker"
_lng_ss "$LNGZ"
LNGa="$(find "$LNGH/.git/index" -newer "$LNGD/ro.marker" 2>&1)"
_lng_is "lane session start L-RO: after a touch of lanes.tsv, its content unchanged, a session start exits 0 with valid JSON and leaves the home's .git/index no newer than a marker touched before it (control)" \
   "$LNGZE|$LNGT|$LF_RC|$LF_JSON|newer[$LNGa]" "built|built|0|ok|newer[]"

# ---- the broken engine (control) -------------------------------------------------------------------------------------------
LNGa="not built: the broken engine"
_lf_broken "$LNGD/broken" && [ -x "$LF_ROOT/harness/hooks/session-start" ] && [ -f "$LF_ROOT/harness/felix" ] \
  && [ ! -e "$LF_ROOT/harness/lib/lane.sh" ] && LNGa=built
_lng_ss "$LNGZ" "$LNGN" startup "$LF_ROOT"
_lng_is "lane session start: an engine copy with lib/lane.sh removed, where the intact engine shows the zero paragraph and token, exits 0 with valid JSON and neither (control)" \
   "$LNGZE|$LNGT|$LNGa|$LF_RC|$LF_JSON|$(_lf_silent capability)" "built|built|built|0|ok|none"
# <<< lane-session-start
