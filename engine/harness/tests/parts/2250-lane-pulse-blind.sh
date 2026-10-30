# >>> lane-pulse
printf '\nlane pulse: a lane line per row of the home project'"'"'s lanes.tsv, last, in the output, the log and the record (slice 0, design 6.5 item 5 and 6.6, C8, L-NEVER-OK; blind)\n'
# Blind, written on 2026-10-29 from docs/2026-10-29-capability-lane-first-slices-design.md and the slice 0 plan's
# Contracts (C1-C13) alone, before lib/lane.sh existed, without reading lib/, hooks/, bin/ or felix. Felix is run as a
# black box; the builders are tests/lib/lane-fixture.sh's. C11's row for this part: section 6.5 item 5 and 6.6 "The
# pulse": the pulse lines, in the log and in the record, last, each with the state, L and T that felix lane --tsv prints
# at the same FELIX_LANE_NOW; unknown with -; no line without a committed lanes.tsv; no line for a project other than
# the home's.
#
# The self-governed layout (C9): S is one repository, the home and the checkout, with .felix (pl) committed at its top;
# its root a month before the clock, its tables committed 29 days before it, then five landings from five days before
# it, an hour apart (_lf_chain: m u u md ud, the marks capability's), with refs/remotes/origin/main at the last. The
# memory root sits beside S, outside every repository. felix pulse runs as C9 says (_lf_run: the fixture HOME, the stubs
# first on PATH, uname and launchctl among them), from S unless a case says otherwise, then waits for the discovery
# lock. On this engine a run prints a pulse header, a backup line and a settings line; its record is "# ran <epoch>"
# and every line it printed after the header, and the log gains every line it printed. Readings where the Contracts
# leave room:
# - "Last" is asserted as: from the first line whose first field is lane to the end, the lines are exactly the lane
#   lines expected, and a backup and a settings line come before them.
# - The four-row table holds a valid lane counting engine/, one counting docs/, a row whose share is 3/2 (lane bad, R5)
#   and a row whose lane cell .x is no lane name (R5, column 1 -), so it shows unknown with - per row.
# - "Writes nothing it did not write before" is read as: nothing newer in S outside state/, .git included, and S's refs
#   and worktree list unchanged, asserted with the lane lines the run printed.
# - The no-line cases are controls (C10): lanes.tsv only in the working tree, a committed one with no row, a home that is
#   not a git checkout, a git home that binds no project, and a home whose own project has no lanes.tsv while another
#   project in it, whose checkout the pulse runs from, has one.
LNPN=1793000000; LNPDAY=86400; LNPK=0
_lf_dir "$TMP/lane-2250"; LNPD="$LF_DIR"
_lf_stubs "$LNPD"; LNPB="$LF_BIN"
_lf_self "$LNPD/home" pl $((LNPN - 30 * LNPDAY)); LNPH="$LF_HOME"; LNPP="$LF_PROJ"
_lf_use "$LNPH" "$LNPD/memory" "$LNPD/user" "$LNPB"
LNP1=$'capability\t^engine/\t1/2\t14\n'
LNP4=$'# The lanes the home counts.\ncapability\t^engine/\t1/2\t14\n\ndocs\t^docs/\t1/3\t7\nbad\t^engine/\t3/2\t14\n.x\t^engine/\t1/2\t14\n'
LNPW1="$(_lf_tsv lane capability short 1 3)"
LNPW4="$LNPW1"$'\n'"$(_lf_tsv lane docs zero 0 2)"$'\n'"$(_lf_tsv lane bad unknown - -)"$'\n'"$(_lf_tsv lane - unknown - -)"
LNPU4="$(_lf_tsv lane capability unknown - -)"$'\n'"$(_lf_tsv lane docs unknown - -)"$'\n'"$(_lf_tsv lane bad unknown - -)"$'\n'"$(_lf_tsv lane - unknown - -)"

# HOME PROJ REL LABEL BYTES -> PROJ/REL holds BYTES, committed in HOME at the next time; LNPT "built" when HOME's HEAD
# holds exactly them. REL - instead: PROJ's lanes.tsv removed by a commit, LNPT "built" when HEAD holds none.
_lnp_put() {
  local h="$1" p="$2" r="$3" t
  LNPK=$((LNPK + 1)); t=$((LNPN - 29 * LNPDAY + 100 * LNPK)); LNPT="not built: $4"
  if [ "$r" = - ]; then
    ( _fx_cd "$h" && _lf_g 1700000000 cat-file -e "HEAD:${p#"$h"/}/lanes.tsv" ) >/dev/null 2>&1 \
      && { _lf_commit "$p" "$t" "lanes.tsv removed: $4"$'\n' -lanes.tsv || return 1; }
    ( _fx_cd "$h" && _lf_g 1700000000 cat-file -e "HEAD:${p#"$h"/}/lanes.tsv" ) >/dev/null 2>&1 || LNPT=built
    return 0
  fi
  rm -f "$p/$r"
  _lf_table "$p" "$t" "$r" "$5" "$r: $4"$'\n' || return 1
  printf '%s' "$5" > "$LNPD/put.want"
  ( _fx_cd "$h" || exit 1; _lf_g 1700000000 cat-file blob "HEAD:${p#"$h"/}/$r" ) > "$LNPD/put.got" 2>/dev/null
  cmp -s "$LNPD/put.want" "$LNPD/put.got" && LNPT=built
}
# OUT [DIR [NOW]] -> felix pulse from DIR (the home of _lf_use) at the clock LNPN (or NOW; - unset), then the
# discovery lock waited for. OUT.out and OUT.err, LF_RC; LNPL0 the log's lines before the run.
_lnp_pulse() {
  LNPL0="$(_lf_count "$LF_H/state/pulse.log")"; [ -n "$LNPL0" ] || LNPL0=0
  _lf_run "$1" "${2:-$LF_H}" "${3-$LNPN}" "$FELIX" pulse
  _lf_calm "$LF_H"
}
# FILE -> its lines from the first whose first field is lane to its end; _lnp_lanes FILE -> its lane lines only.
_lnp_tail() { LC_ALL=C awk -F'\t' 'f || $1 == "lane" { f = 1; print }' "$1" 2>/dev/null; }
_lnp_lanes() { LC_ALL=C awk -F'\t' '$1 == "lane"' "$1" 2>/dev/null; }
# FILE -> "backup settings" when a backup line and a settings line come before its first lane line.
_lnp_before() {
  LC_ALL=C awk -F'\t' '$1 == "lane" { f = 1 } !f && $1 == "backup" { b = 1 } !f && $1 == "settings" { s = 1 }
    END { printf "%s %s", (f && b) ? "backup" : "no-backup-before-a-lane-line", (f && s) ? "settings" : "no-settings-before-a-lane-line" }' "$1" 2>/dev/null
}
# OUT -> LNPRS "same" when the record holds # ran <epoch> and then every line OUT printed after its header, else
# "differ"; LNPRT the record's lines from the first lane line on.
_lnp_rec() {
  local r="$LF_H/state/pulse.status.tsv"
  tail -n +2 "$r" > "$LNPD/rec.rest" 2>/dev/null; tail -n +2 "$1.out" > "$LNPD/out.rest" 2>/dev/null
  LNPRT="$(_lnp_tail "$r")"; LNPRS=differ
  if [ -n "$(LC_ALL=C awk 'NR == 1 && /^# ran [0123456789]+$/' "$r" 2>/dev/null)" ] && cmp -s "$LNPD/rec.rest" "$LNPD/out.rest"; then LNPRS=same; fi
}
# OUT -> LNPLS "same" when the log grew by exactly the lines OUT printed, and they are its last, else "differ"; LNPLT
# those lines from the first lane line on.
_lnp_log() {
  local l="$LF_H/state/pulse.log" n m
  n="$(_lf_count "$1.out")"; [ -n "$n" ] || n=0
  m="$(_lf_count "$l")"; [ -n "$m" ] || m=0
  tail -n "$n" "$l" > "$LNPD/log.last" 2>/dev/null
  LNPLT="$(_lnp_tail "$LNPD/log.last")"; LNPLS=differ
  if [ "$((m - LNPL0))" = "$n" ] && cmp -s "$LNPD/log.last" "$1.out"; then LNPLS=same; fi
}

# ---- the home: tables, landings, one lane ---------------------------------------------------------------------------------
_lnp_put "$LNPH" "$LNPP" lanes.tsv "one lane" "$LNP1"; LNPT1="$LNPT"
_lnp_put "$LNPH" "$LNPP" lane-next.tsv "the next item" "$(_lf_tsv capability 'the next capability item')"$'\n'
_lf_chain "$LNPH" capability $((LNPN - 5 * LNPDAY)) 3600 m u u md ud; LNPTIP="$LF_SHA"
LNPE="not built: the home's landings [$(_lf_spine "$LNPH")]"
case "$(_lf_spine "$LNPH")" in
  "$((LNPN - 5 * LNPDAY + 4 * 3600)):1 $((LNPN - 5 * LNPDAY + 3 * 3600)):1 $((LNPN - 5 * LNPDAY + 2 * 3600)):1 $((LNPN - 5 * LNPDAY + 3600)):1 $((LNPN - 5 * LNPDAY)):1 "*" $((LNPN - 30 * LNPDAY)):0")
    [ "$LNPT1" = built ] && [ -n "$LNPTIP" ] && LNPE=built ;;
esac
_lnp_pulse "$LNPD/p1"
is "lane pulse: one lane, capability, L 1 of T 3: felix pulse exits 0 and its last line is lane capability short 1 3, after its backup and settings lines" \
   "$LNPE|$LF_RC|$(_lnp_tail "$LNPD/p1.out")|$(_lnp_before "$LNPD/p1.out")" "built|0|$LNPW1|backup settings"
_lf_run "$LNPD/t1" "$LNPH" "$LNPN" "$FELIX" lane --tsv
is "lane pulse: the line carries the state, L and T that felix lane --tsv prints in the home at the same FELIX_LANE_NOW" \
   "$LNPE|$(_lnp_lanes "$LNPD/p1.out")|$(LC_ALL=C awk -F'\t' '{ printf "%slane\t%s\t%s\t%s\t%s", (NR > 1 ? "\n" : ""), $1, $2, $3, $4 }' "$LNPD/t1.out")" \
   "built|$LNPW1|$LNPW1"
_lnp_rec "$LNPD/p1"; _lnp_log "$LNPD/p1"
is "lane pulse: state/pulse.status.tsv opens # ran <epoch>, holds every line the run printed after its header, and ends with the lane line" \
   "$LNPE|$LNPRS|$LNPRT" "built|same|$LNPW1"
is "lane pulse: state/pulse.log gains exactly the lines the run printed, the lane line last" \
   "$LNPE|$LNPLS|$LNPLT" "built|same|$LNPW1"

# ---- four rows: a line each, in file order, unknown with - ------------------------------------------------------------------
_lnp_put "$LNPH" "$LNPP" lanes.tsv "four rows" "$LNP4"; LNPT4="$LNPT"
_lnp_pulse "$LNPD/p2"
is "lane pulse L-NEVER-OK: four rows give four lines, last and in file order: capability short 1 3, docs zero 0 2, lane bad unknown - - (share 3/2) and lane - unknown - - (a lane cell that is no lane name)" \
   "$LNPE|$LNPT4|$LF_RC|$(_lnp_tail "$LNPD/p2.out")|$(_lnp_before "$LNPD/p2.out")" "built|built|0|$LNPW4|backup settings"
_lf_run "$LNPD/t2" "$LNPH" "$LNPN" "$FELIX" lane --tsv
is "lane pulse L-NEVER-OK: each of the four lines is lane, then columns 1 to 4 of the felix lane --tsv line of its row at the same FELIX_LANE_NOW" \
   "$LNPE|$LNPT4|$(_lnp_lanes "$LNPD/p2.out")|$(LC_ALL=C awk -F'\t' '{ printf "%slane\t%s\t%s\t%s\t%s", (NR > 1 ? "\n" : ""), $1, $2, $3, $4 }' "$LNPD/t2.out")" \
   "built|built|$LNPW4|$LNPW4"
_lnp_rec "$LNPD/p2"; _lnp_log "$LNPD/p2"
is "lane pulse L-NEVER-OK: the record ends with the four lane lines, and the log gains the run's lines, the four lane lines last" \
   "$LNPE|$LNPT4|$LNPRS|$LNPRT|$LNPLS|$LNPLT" "built|built|same|$LNPW4|same|$LNPW4"
_lnp_pulse "$LNPD/p3"
is "lane pulse: a second run appends its four lane lines to the log (nine there, after one and four), and the record, rewritten, holds four" \
   "$LNPE|$LNPT4|$LF_RC|$(_lnp_lanes "$LF_H/state/pulse.log" | LC_ALL=C awk 'END { print NR }')|$(_lnp_lanes "$LF_H/state/pulse.status.tsv")" \
   "built|built|0|9|$LNPW4"

# ---- the review's F1: a fork that fails in the read of the landings (C3, C8) ----------------------------------------------
# Added on 2026-10-30 from the adversarial review of the first build, still blind. C3 counts a fork that fails among the
# git reads that do not finish, so every lane the fault reaches reads unknown with - for L and T, and C8 still gives a
# line per row, last. The fault is part 2210's: a bash function git, exported into felix pulse, that lowers the process
# limit to 1 (ulimit -S -u 1) in the shell running it when its words hold --first-parent and refs/remotes/origin/main,
# then runs git, which that shell cannot fork; "fired" and, if the shell gets there, "ran <status>" go to a file. It
# runs here, after the log's count above, so that count stays as it was; the table is the four-row one.
_lnp_fork() {
  local f="$1.fired"
  rm -f "$f"
  LNPL0="$(_lf_count "$LF_H/state/pulse.log")"; [ -n "$LNPL0" ] || LNPL0=0
  ( eval "git() { local z='' r; case \" \$* \" in *' --first-parent '*) case \" \$* \" in *' refs/remotes/origin/main'*) z=1; printf 'fired\n' >> $(printf '%q' "$f"); ulimit -S -u 1 ;; esac ;; esac; command git \"\$@\"; r=\$?; [ -z \"\$z\" ] || printf 'ran %s\n' \"\$r\" >> $(printf '%q' "$f"); return \"\$r\"; }"
    export -f git
    _lf_run "$1" "$LF_H" "$LNPN" "$FELIX" pulse
    exit "$LF_RC" )
  LF_RC=$?
  _lf_calm "$LF_H"
  LNPFIRE="$(LC_ALL=C awk '$0 == "fired" { f = 1 } $0 == "ran 0" { r = 1 }
    END { s = "not fired"; if (f && r) s = "fired, but git ran to a clean exit after it"; if (f && !r) s = "fired"; print s }' "$f" 2>/dev/null)"
  [ -n "$LNPFIRE" ] || LNPFIRE="not fired"
}
_lnp_fork "$LNPD/f1"
is "lane pulse F1-fork-reads-as-no-lane L-NEVER-OK: a fork that fails in the read of the landings on refs/remotes/origin/main still gives the four lane lines last, each unknown with L and T -, after the backup and settings lines, never no line" \
   "$LNPE|$LNPT4|$LNPFIRE|$LF_RC|$(_lnp_tail "$LNPD/f1.out")|$(_lnp_before "$LNPD/f1.out")" "built|built|fired|0|$LNPU4|backup settings"

# ---- the clock, and unknown ----------------------------------------------------------------------------------------------------
_lnp_pulse "$LNPD/p4" "$LNPH" $((LNPN + 20 * LNPDAY))
is "lane pulse: with FELIX_LANE_NOW twenty days on, no landing is in either window: capability and docs read idle 0 0, the broken rows still unknown" \
   "$LNPE|$LNPT4|$LF_RC|$(_lnp_tail "$LNPD/p4.out")" \
   "built|built|0|$(_lf_tsv lane capability idle 0 0)"$'\n'"$(_lf_tsv lane docs idle 0 0)"$'\n'"$(_lf_tsv lane bad unknown - -)"$'\n'"$(_lf_tsv lane - unknown - -)"
_lnp_pulse "$LNPD/p5" "$LNPH" 0123
is "lane pulse L-NEVER-OK: FELIX_LANE_NOW=0123 (R8) gives every row unknown, L and T -, never a count" \
   "$LNPE|$LNPT4|$LF_RC|$(_lnp_tail "$LNPD/p5.out")" "built|built|0|$LNPU4"
LNPa="not built: the ref deleted"
( _fx_cd "$LNPH" && _lf_g 1700000000 update-ref -d refs/remotes/origin/main ) >/dev/null 2>&1 \
  && ! ( _fx_cd "$LNPH" && _lf_g 1700000000 rev-parse --verify -q refs/remotes/origin/main ) >/dev/null 2>&1 && LNPa=built
_lnp_pulse "$LNPD/p6"
is "lane pulse L-NEVER-OK: with refs/remotes/origin/main deleted in the home (R1), every row reads unknown, L and T -" \
   "$LNPa|$LNPT4|$LF_RC|$(_lnp_tail "$LNPD/p6.out")" "built|built|0|$LNPU4"
_lf_publish "$LNPH" "$LNPTIP" && [ "$( _fx_cd "$LNPH" && _lf_g 1700000000 rev-parse --verify -q refs/remotes/origin/main )" = "$LNPTIP" ] \
  || LNPE="not built: refs/remotes/origin/main not put back at the last landing"
_lnp_put "$LNPH" "$LNPP" lanes.tsv "a CR in a row" $'capability\t^engine/\t1/2\t14\r\n'
_lnp_pulse "$LNPD/p7"
is "lane pulse L-NEVER-OK: a committed lanes.tsv the shape check refuses (a CR in its row, R4) gives the one line lane - unknown - -" \
   "$LNPE|$LNPT|$LF_RC|$(_lnp_tail "$LNPD/p7.out")" "built|built|0|$(_lf_tsv lane - unknown - -)"

# ---- the run writes nothing else -------------------------------------------------------------------------------------------------
_lnp_put "$LNPH" "$LNPP" lanes.tsv "four rows again" "$LNP4"
sleep 1; touch "$LNPD/ro.marker"
LNPa="$( _fx_cd "$LNPH" && _lf_g 1700000000 for-each-ref )"; LNPb="$( _fx_cd "$LNPH" && _lf_g 1700000000 worktree list --porcelain )"
_lnp_pulse "$LNPD/p8"
LNPc="$(find "$LNPH" -newer "$LNPD/ro.marker" ! -path "$LNPH/state" ! -path "$LNPH/state/*" 2>&1)"
LNPa="$([ -n "$LNPa" ] && [ "$LNPa" = "$( _fx_cd "$LNPH" && _lf_g 1700000000 for-each-ref )" ] && echo same || echo changed)"
LNPb="$([ -n "$LNPb" ] && [ "$LNPb" = "$( _fx_cd "$LNPH" && _lf_g 1700000000 worktree list --porcelain )" ] && echo same || echo changed)"
is "lane pulse: a run leaves nothing newer in the home outside state/, .git included, its refs and worktree list as they were, and prints the four lane lines last" \
   "$LNPE|$LNPT|$LF_RC|newer[$LNPc]|$LNPa|$LNPb|$(_lnp_tail "$LNPD/p8.out")" "built|built|0|newer[]|same|same|$LNPW4"

# ---- only the home's project ------------------------------------------------------------------------------------------------------
LNPa="not built: project qo"
mkdir -p "$LNPH/projects/qo"; printf '{"name":"qo","gate":"true"}\n' > "$LNPH/projects/qo/project.json"; printf '# qo\n' > "$LNPH/projects/qo/CLAUDE.md"
printf 'other\t^engine/\t1/2\t14\n' > "$LNPH/projects/qo/lanes.tsv"
_lf_commit "$LNPH" $((LNPN - 29 * LNPDAY + 9000)) $'project qo, with a lane of its own\n' \
  =projects/qo/project.json =projects/qo/CLAUDE.md =projects/qo/lanes.tsv && LNPa=built
_lf_checkout "$LNPD/qo" qo $((LNPN - 30 * LNPDAY)); LNPQ="$LF_REPO"
_lf_chain "$LNPQ" other $((LNPN - 3 * LNPDAY)) 3600 m u || LNPa="not built: qo's checkout"
_lnp_pulse "$LNPD/p9" "$LNPQ"
is "lane pulse: run from the checkout of another project of the home, whose own lanes.tsv has a row, the lane lines are the home project's four and no other" \
   "$LNPE|$LNPa|$LF_RC|$(_lnp_tail "$LNPD/p9.out")" "built|built|0|$LNPW4"

# ---- no lane line (controls) ------------------------------------------------------------------------------------------------------
# OUT LABEL BUILT [DIR] -> a pulse run from DIR (the home): it exits 0 and prints no lane line, nor does its record hold one.
_lnp_none() {
  _lnp_pulse "$1" "${4:-$LF_H}"
  is "lane pulse: $2: felix pulse exits 0 with no lane line in its output or its record (control)" \
     "$3|$LF_RC|$(_lnp_lanes "$1.out")|$(_lnp_lanes "$LF_H/state/pulse.status.tsv")" "built|0||"
}
_lnp_put "$LNPH" "$LNPP" lanes.tsv "comments and a blank line, no row" $'# No lane is counted yet.\n\n'
_lnp_none "$LNPD/n1" "a committed lanes.tsv holding only a comment and a blank line" "$LNPT"
_lnp_put "$LNPH" "$LNPP" - "removed"; printf '%s' "$LNP4" > "$LNPP/lanes.tsv"
_lnp_none "$LNPD/n2" "lanes.tsv with four rows in the home's working tree, removed from HEAD by a commit" "$LNPT"

LNPa="not built: a home that is not a git checkout"; LNPG="$LNPD/plain-home"
mkdir -p "$LNPG/projects/pl" && printf 'pl\n' > "$LNPG/.felix" && printf '{"name":"pl","gate":"true"}\n' > "$LNPG/projects/pl/project.json" \
  && printf '# pl\n' > "$LNPG/projects/pl/CLAUDE.md" && printf '%s' "$LNP1" > "$LNPG/projects/pl/lanes.tsv" \
  && ! ( _fx_cd "$LNPG" && _lf_g 1700000000 rev-parse --git-dir ) >/dev/null 2>&1 && LNPa=built
_lf_use "$LNPG" "$LNPD/memory" "$LNPD/user" "$LNPB"
_lnp_none "$LNPD/n3" "a home that is not a git checkout, with .felix and a lanes.tsv holding a row" "$LNPa"

_lf_home "$LNPD/apart-home" pl $((LNPN - 30 * LNPDAY)); LNPA="$LF_HOME"; LNPa="not built: a home that binds no project"
_lnp_put "$LNPA" "$LF_PROJ" lanes.tsv "one lane, in a home that binds no project" "$LNP1"
_lf_chain "$LNPA" capability $((LNPN - 5 * LNPDAY)) 3600 m u u && [ "$LNPT" = built ] && [ ! -e "$LNPA/.felix" ] && LNPa=built
_lf_use "$LNPA" "$LNPD/memory" "$LNPD/user" "$LNPB"
_lnp_none "$LNPD/n4" "a git home with engine landings on origin/main and pl's lanes.tsv committed, which binds no project (no .felix, no remote)" "$LNPa"

_lf_self "$LNPD/other-home" pl $((LNPN - 30 * LNPDAY)); LNPO="$LF_HOME"; LNPa="not built: a home whose project has no lanes.tsv"
mkdir -p "$LNPO/projects/qo"; printf '{"name":"qo","gate":"true"}\n' > "$LNPO/projects/qo/project.json"; printf '# qo\n' > "$LNPO/projects/qo/CLAUDE.md"
_lf_commit "$LNPO" $((LNPN - 29 * LNPDAY)) $'project qo\n' =projects/qo/project.json =projects/qo/CLAUDE.md
_lnp_put "$LNPO" "$LNPO/projects/qo" lanes.tsv "qo's lane" "$LNP1"
_lf_chain "$LNPO" capability $((LNPN - 5 * LNPDAY)) 3600 m u u && [ "$LNPT" = built ] \
  && ! ( _fx_cd "$LNPO" && _lf_g 1700000000 cat-file -e HEAD:projects/pl/lanes.tsv ) >/dev/null 2>&1 && LNPa=built
_lf_checkout "$LNPD/qo2" qo $((LNPN - 30 * LNPDAY)); LNPQ2="$LF_REPO"
_lf_chain "$LNPQ2" capability $((LNPN - 3 * LNPDAY)) 3600 m u || LNPa="not built: qo's checkout"
_lf_use "$LNPO" "$LNPD/memory" "$LNPD/user" "$LNPB"
_lnp_none "$LNPD/n5" "run from a checkout of project qo, whose lanes.tsv has a row, in a home bound to pl, which has none" "$LNPa" "$LNPQ2"
_lf_use "$LNPH" "$LNPD/memory" "$LNPD/user" "$LNPB"
# <<< lane-pulse
