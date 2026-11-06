# >>> trust-which-unfinished-reads
printf '\ntrust plane step 1, felix which: a resolution that did not finish is said as one, and felix which agrees with felix lane and the resolver (spec section 5, properties 1-9 and 38; blind)\n'
# Blind, written on 2026-11-05 from .felix/memory/felix/audits/2026-10-31-trust-plane-replay/step1/spec.md (sections 0-8
# and the merge-judge item) and the P2 case's layouts and examples, before any fix. Felix is run as a black box
# ("$FELIX" which and "$FELIX" lane --tsv, from the checkout's co/res/sub/dir, through _lf_run in the environment
# _lf_use names), and the resolver through the driver of tests/lib/trust-probes.sh.
#
# Each fault is armed once and the three runs are made under it: felix which (asserted, with the probe's TRP_FIRE),
# felix lane --tsv and felix_resolve_project (recorded for P38). The faults match their command's words in any calling
# function, as the spec names them by the read alone ("at the marker's tr"): felix_binding_broken's and the lane's reads
# of the same file are faulted with the resolver's. Readings where the spec leaves room:
# - "Unknown" for which is exit 2, empty stdout, and a line of stderr exactly "felix: the project that governs <dir>
#   could not be resolved: a read it stands on did not finish." (the CLI's sentence, section 0); bash's own note of a
#   fork it could not make may stand on another line, since it is the probe's doing.
# - Broken and none are P2's outcomes.tsv classes (its stderr EREs); found is five lines with the project line.
# - P38's "every fault in 2-21" is read over res layouts only (P2's res-* and base, here and in part 2172), since 20 and 21
#   are a layout no res layout is; felix lane's "could not be resolved" is its C5 line on stderr with exit 2.
_lf_dir "$TMP/trust-2171"; TRB="$LF_DIR"
TRP_E="$FROOT/harness"
_trp_driver "$TRB/drv"
TRBBAD=""
for _trb_l in marker remote nest tie badmarker none slug alphabet unread noorigin; do
  _trp_res "$TMP/trust-2171/$_trb_l" "$_trb_l" || TRBBAD="$TRBBAD $_trb_l"
done
is "P1 (fixture control): every resolver layout of P2 and this part's own (alphabet, unread, noorigin) was built" "${TRBBAD:-built}" built
TRBDIS=""; TRBN=0

# LAYOUT -> TRBWANT the which class the clean run gives (P2's examples): found:P, broken or none.
_trb_want() {
  case "$1" in
    marker|slug) TRBWANT=found:alpha ;; alphabet) TRBWANT=found:alphabet ;; remote|nest) TRBWANT=found:beta ;;
    tie|badmarker|unread) TRBWANT=broken ;; *) TRBWANT=none ;;
  esac
}
# OUT DIR -> unresolved when felix lane (OUT.out, OUT.err, LF_RC) exited 2 with nothing on stdout and a line of stderr
# exactly C5's "could not be resolved" line; else its status and the first line of stderr.
_trb_lane() {
  if [ "$LF_RC" = 2 ] && [ ! -s "$1.out" ] \
     && LC_ALL=C grep -Fxq "felix: the project that governs $2 could not be resolved: a read it stands on did not finish." "$1.err" 2>/dev/null; then
    printf unresolved
  else
    printf 'status %s [%s]' "$LF_RC" "$(LC_ALL=C awk 'NR == 1' "$1.err" 2>/dev/null)"
  fi
}
# LAYOUT [FROM] -> with the probes armed now (none when TRP_NAMES is empty), felix which, felix lane --tsv and
# felix_resolve_project, each from FROM (LAYOUT's co/res/sub/dir). TRBW which's class (_trp_wcls), TRBF its probe mark
# (clean when none is armed), TRBL the lane's (_trb_lane), TRBR the resolver's (_trp_rcls). A disagreement P38 forbids
# is added to TRBDIS.
_trb_three() {
  local d r
  _trp_at "$TRB/$1"; d="${2:-$TRP_S}"
  if [ -n "${TRP_NAMES:-}" ]; then
    _trp_go _lf_run "$TRB/w" "$d" - "$FELIX" which; TRBF="$TRP_FIRE"; TRBW="$(_trp_wcls "$TRB/w" "$d")"
    _trp_go _lf_run "$TRB/l" "$d" - "$FELIX" lane --tsv; TRBL="$(_trb_lane "$TRB/l" "$d")"
    _trp_go _trp_drv "$TRB/r" "$d" resolve "$d" "$TRP_H"; TRBR="$(_trp_rcls "$TRB/r")"
  else
    _lf_run "$TRB/w" "$d" - "$FELIX" which; TRBF=clean; TRBW="$(_trp_wcls "$TRB/w" "$d")"
    _lf_run "$TRB/l" "$d" - "$FELIX" lane --tsv; TRBL="$(_trb_lane "$TRB/l" "$d")"
    _trp_drv "$TRB/r" "$d" resolve "$d" "$TRP_H"; TRBR="$(_trp_rcls "$TRB/r")"
  fi
  TRBN=$((TRBN + 1)); r=""
  case "$TRBW:$TRBL" in (unknown:unresolved) ;; (unknown:*) r="which unknown, lane not" ;; (*:unresolved) r="lane unresolved, which $TRBW" ;; esac
  case "$TRBW" in
    found:*) [ "$TRBR" = "found:$TRP_H/projects/${TRBW#found:}" ] || r="${r:+$r; }which $TRBW, resolve $TRBR" ;;
    *) case "$TRBR" in found:*) r="${r:+$r; }resolve $TRBR, which $TRBW" ;; esac ;;
  esac
  [ -z "$r" ] || TRBDIS="$TRBDIS[$1 ${TRBCASE:-clean}: $r] "
}
# LABEL LAYOUT ALTS MODE NAME WORDS -> one assertion: under one probe acting at NAME with WORDS in any calling function,
# felix which from LAYOUT is one of ALTS, and the probe acted.
_trb_one() {
  local lab="$1" l="$2" alts="$3"
  _trp_new "$TRB/p.fired"; _trp_arm "$4" "$5" "$6" '*' || { bad "$lab" "the probe could not be armed: $4 $5 $6"; return; }
  TRBCASE="$4 $5 $6"; _trb_three "$l"; TRBCASE=""
  is "$lab" "$(_trp_in "$TRBW" "$alts")|$TRBF" "ok|fired"
}
TRP_NAMES=""

# --- P1: every P2 layout, no fault.
for _trb_l in marker remote nest tie badmarker none slug; do
  _trb_want "$_trb_l"; _trb_three "$_trb_l"
  case "$TRBWANT" in
    found:*) _trb_p="${TRBWANT#found:}"
      is "P1: felix which from res layout $_trb_l's co/res/sub/dir, no fault, gives P2's example: the five lines for $_trb_p, exit 0" \
         "$(_trp_ro "$TRB/w")" "rc=0 out=[project:      $_trb_p
doctrine:     $TRP_H/projects/$_trb_p/CLAUDE.md
memory:       $TRP_M/$_trb_p/
gate:         gate-$_trb_p
governs:      $TRP_CO
]" ;;
    *) is "P1: felix which from res layout $_trb_l's co/res/sub/dir, no fault, gives P2's example: exit 2, nothing on stdout, stderr of P2's $TRBWANT class" \
         "$TRBW" "$TRBWANT" ;;
  esac
done

# --- P2, P3: the marker read.
for _trb_m in f1 f2 f3 f4; do
  _trb_one "P2: felix which on base, $_trb_m at the marker's tr -d [:space:]: unknown (exit 2, nothing on stdout, the could-not-be-resolved sentence), never alpha's prefix, beta, no project governs or a broken sentence" \
    marker unknown "$_trb_m" tr "*' -d [:space:] '*"
done
_trb_one "P3: felix which, the marker names alphabet beside alpha, the marker's tr prints alpha (its first five bytes) then exits 1: unknown, never alpha" \
  alphabet unknown p5 tr "*' -d [:space:] '*"
TRP_NAMES=""; _trb_three alphabet
is "P3 (control): felix which, the marker names alphabet, no fault: found alphabet" "$TRBW" found:alphabet

# --- P4: an unreadable marker.
if [ "$(id -u)" = 0 ]; then
  skip "P4: felix which on base with the marker mode 000: the broken sentence" "run as root, so mode 000 does not stop the read"
else
  TRP_NAMES=""; _trb_three unread
  is "P4: felix which on base with the marker mode 000 (not root), no fault: exit 2, nothing on stdout, a broken-binding sentence for the marker (main's), never no project governs and never unknown" \
     "$TRBW" broken
fi

# --- P5, P6: the origin read.
for _trb_m in f1 f127 f2 f3 f5; do
  _trb_one "P5: felix which on res-remote, $_trb_m at git remote get-url origin: unknown, never no project governs" \
    remote unknown "$_trb_m" git "*' remote get-url origin '*"
done
TRP_NAMES=""; _trb_three noorigin
is "P6: felix which in a checkout with no origin remote (res-remote's projects), no fault: no project governs (main's sentence class), exit 2" "$TRBW" none
_trp_at "$TRB/remote"; _lf_run "$TRB/w" "$TRP_P" - "$FELIX" which
is "P6: felix which outside any repository, no fault: no project governs (main's sentence class), exit 2" "$(_trp_wcls "$TRB/w" "$TRP_P")" none

# --- P7, P8, P9: a remote_match unread.
for _trb_m in f1 f2 f3 f4; do
  _trb_one "P7: felix which on res-nest, $_trb_m at the sed that reads beta's project.json: unknown, never alpha" \
    nest unknown "$_trb_m" sed "*remote_match*'/projects/beta/project.json '*"
  _trb_one "P7: felix which on res-nest, $_trb_m at the sed that reads alpha's project.json: unknown, never beta" \
    nest unknown "$_trb_m" sed "*remote_match*'/projects/alpha/project.json '*"
done
for _trb_m in f1 f2 f3; do
  for _trb_p in alpha beta; do
    _trb_one "P8: felix which on res-tie, $_trb_m at the sed that reads $_trb_p's project.json: unknown, never the other project, never the tie sentence" \
      tie unknown "$_trb_m" sed "*remote_match*'/projects/$_trb_p/project.json '*"
  done
  _trb_one "P9: felix which on res-none, $_trb_m at the sed that reads every project.json's remote_match: unknown, never no project governs" \
    none unknown "$_trb_m" sed "*remote_match*'/project.json '*"
done

# --- P38, over the res layouts and faults of this part (the badmarker, none and tie faults of 17-19 are part 2172's).
is "P38: over the $TRBN runs of this part (seven res layouts clean, and the faults of P2-P9 on base, res-remote, res-nest, res-tie and res-none, with alphabet, the unreadable marker and no origin), felix which is unknown exactly where felix lane says could not be resolved, and found with P only where felix_resolve_project prints .../projects/P with 0" \
   "${TRBDIS:-agreed}" agreed
TRP_NAMES=""
# <<< trust-which-unfinished-reads
