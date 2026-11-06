# >>> trust-cli-refusals-unfinished-reads
printf '\ntrust plane step 1, the CLI refusals: the broken and no-project sentences, every resolve_or_die command, felix which'"'"'s own reads and the merge judge'"'"'s resolve.sh (spec section 5, properties 17-21, 23, 24, 38 and 45; blind)\n'
# Blind, written on 2026-11-05 from .felix/memory/felix/audits/2026-10-31-trust-plane-replay/step1/spec.md (sections 0-8
# and the merge-judge item) and the P2 case's layouts, before any fix. Felix is run as a black box through _lf_run, in
# the environment _lf_use names; the probes are tests/lib/trust-probes.sh's. Readings where the spec leaves room:
# - "Byte for byte" (P17-P21) compares exit, stdout and stderr with the clean run's, leaving out bash's own note of a
#   fork it could not make (_trp_said), which is the probe's doing and no sentence of the engine's.
# - P21's memory-root read may be made fork-free by the fix (R14). Where the probe does not act, the run must equal the
#   clean run, as section 5's head says; where it acts, unknown or the clean sentence. On main it acts.
# - P23's "unknown sentence" is a line of stderr exactly the CLI's; felix land --tick is run with FELIX_LAND_LEDGER, so
#   the unresolved row it writes is read in that file.
# - P24's F3 at felix_repo_root for the governs line is the fork failing at both its reads (the walk's pwd -P, then git),
#   called by cmd_which and not by the resolution; the gate's sed is the read of the gate key called by cmd_which.
# - P45's "suite's judge fixtures" are built here as part 1401 builds them: a home whose main ships engine/ at 4.0.0
#   and a cache entry cut from it, plus that entry with a file more and a cache with no entry. Main's answer is the
#   function's contract there (0 and the entry, 1 naming the path, 2), and the copy holding only resolve.sh must give it.
_lf_dir "$TMP/trust-2172"; TRC="$LF_DIR"
TRP_E="$FROOT/harness"
_trp_driver "$TRC/drv"
TRCBAD=""
for _trc_l in badmarker none tie marker bound boundhome; do
  case "$_trc_l" in bound|boundhome) _trc_k=remote ;; *) _trc_k="$_trc_l" ;; esac
  _trp_res "$TMP/trust-2172/$_trc_l" "$_trc_k" || TRCBAD="$TRCBAD $_trc_l"
done
is "P17 (fixture control): the layouts of this part were built (res-badmarker, res-none, res-tie, base, and two res-remote copies for the bindings record)" \
   "${TRCBAD:-built}" built
TRCDIS=""; TRCN=0

# OUT DIR RC -> unknown when the run exited RC with nothing on stdout and a line of stderr exactly the CLI's
# could-not-be-resolved sentence for DIR; else what it said (_trp_said).
_trc_unk() {
  if [ "$LF_RC" = "$3" ] && [ ! -s "$1.out" ] \
     && LC_ALL=C grep -Fxq "felix: the project that governs $2 could not be resolved: a read it stands on did not finish." "$1.err" 2>/dev/null; then
    printf unknown
  else _trp_said "$1"; fi
}
# LAYOUT -> felix which, felix lane --tsv and felix_resolve_project from LAYOUT's sub/dir under the probes armed now,
# as part 2171's _trb_three runs them: TRCW which's class, TRCS what it said (_trp_said), TRCF its probe mark; a
# disagreement P38 forbids is added to TRCDIS.
_trc_three() {
  local d r
  _trp_at "$TRC/$1"; d="$TRP_S"
  _trp_go _lf_run "$TRC/w" "$d" - "$FELIX" which; TRCF="$TRP_FIRE"; TRCW="$(_trp_wcls "$TRC/w" "$d")"; TRCS="$(_trp_said "$TRC/w")"
  _trp_go _lf_run "$TRC/l" "$d" - "$FELIX" lane --tsv
  if [ "$LF_RC" = 2 ] && [ ! -s "$TRC/l.out" ] \
     && LC_ALL=C grep -Fxq "felix: the project that governs $d could not be resolved: a read it stands on did not finish." "$TRC/l.err" 2>/dev/null
  then TRCL=unresolved; else TRCL="status $LF_RC"; fi
  _trp_go _trp_drv "$TRC/r" "$d" resolve "$d" "$TRP_H"; TRCR="$(_trp_rcls "$TRC/r")"
  TRCN=$((TRCN + 1)); r=""
  case "$TRCW:$TRCL" in (unknown:unresolved) ;; (unknown:*) r="which unknown, lane $TRCL" ;; (*:unresolved) r="lane unresolved, which $TRCW" ;; esac
  case "$TRCW" in
    found:*) [ "$TRCR" = "found:$TRP_H/projects/${TRCW#found:}" ] || r="${r:+$r; }which $TRCW, resolve $TRCR" ;;
    *) case "$TRCR" in found:*) r="${r:+$r; }resolve $TRCR, which $TRCW" ;; esac ;;
  esac
  [ -z "$r" ] || TRCDIS="$TRCDIS[$1 $TRCCASE: $r] "
}
# LAYOUT -> TRCCL what felix which says from LAYOUT's sub/dir with no fault (_trp_said), TRCCW its class.
_trc_clean() { _trp_at "$TRC/$1"; _lf_run "$TRC/c" "$TRP_S" - "$FELIX" which; TRCCL="$(_trp_said "$TRC/c")"; TRCCW="$(_trp_wcls "$TRC/c" "$TRP_S")"; }
# LABEL LAYOUT MODE NAME WORDS -> one assertion: under the probe (any calling function), felix which from LAYOUT is
# unknown, or says exactly what the clean run says; and the probe acted.
_trc_or_clean() {
  local lab="$1" l="$2" v
  _trp_new "$TRC/p.fired"; _trp_arm "$3" "$4" "$5" '*' || { bad "$lab" "the probe could not be armed"; return; }
  TRCCASE="$3 $4"; _trc_three "$l"
  if [ "$TRCW" = unknown ] || [ "$TRCS" = "$TRCCL" ]; then v=ok; else v="$TRCS"; fi
  is "$lab" "$v|$TRCF" "ok|fired"
}

# --- P17, P18, P19: the refusal sentences' own reads.
_trc_clean badmarker
is "P17 (control): felix which on res-badmarker, no fault: the broken sentence, which lists the known projects" \
   "$TRCCW|$(case "$TRCCL" in (*"known projects: alpha beta gamma "*) printf listed ;; (*) printf 'not listed' ;; esac)" "broken|listed"
for _trc_m in f2 f3; do
  _trc_or_clean "P17: felix which on res-badmarker (a broken marker), $_trc_m at the ls of the projects directory: unknown, or the clean broken sentence byte for byte; never known projects: none while projects exist" \
    badmarker "$_trc_m" ls "*'/projects '*"
done
_trc_clean none
is "P18 (control): felix which on res-none, no fault: no project governs, with Known projects: alpha beta gamma" \
   "$TRCCW|$(case "$TRCCL" in (*"Known projects: alpha beta gamma "*) printf listed ;; (*) printf 'not listed' ;; esac)" "none|listed"
for _trc_m in f2 f3; do
  _trc_or_clean "P18: felix which on res-none, $_trc_m at the ls behind Known projects: unknown, or main's no-project sentence byte for byte" \
    none "$_trc_m" ls "*'/projects '*"
done
_trc_clean tie
is "P19 (control): felix which on res-tie, no fault: the tie sentence naming alpha, beta" \
   "$TRCCW|$(case "$TRCCL" in (*"fits alpha, beta equally well"*) printf named ;; (*) printf 'not named' ;; esac)" "broken|named"
_trc_or_clean "P19: felix which on res-tie, F3 at the tr -cd [:print:] that cleans the names (_felix_binding_sane): unknown, or the clean tie sentence byte for byte" \
  tie f3 tr "*' -cd [:print:] '*"
is "P38: over the $TRCN runs of P17-P19 (res-badmarker, res-none and res-tie under their faults), felix which is unknown exactly where felix lane says could not be resolved, and found with P only where felix_resolve_project prints .../projects/P with 0" \
   "${TRCDIS:-agreed}" agreed

# --- P20, P21: a checkout once bound by remote whose project.json went missing.
# LAYOUT NOMEM -> the bindings record of LAYOUT's checkout written by felix_binding_broken itself (a clean run, in the
# memory root FELIX_MEMORY names, or HOME's default when NOMEM is 1), then beta's project.json moved to
# project.json.bak. TRCB "built" when the record names beta and the move was made.
_trc_bound() {
  local f
  _trp_at "$TRC/$1"
  if [ "$2" = 1 ]; then f="$TRP_U/.felix/memory/bindings.tsv"; else f="$TRP_M/bindings.tsv"; fi
  TRP_NOMEM="$2" _trp_drv "$TRC/b" "$TRP_S" broken "$TRP_S" "$TRP_H"
  TRCB="not built: $(_trp_ro "$TRC/b") record [$(cat "$f" 2>&1)]"
  LC_ALL=C awk -F'\t' '$2 == "beta" { f = 1 } END { exit !f }' "$f" 2>/dev/null || return 1
  mv "$TRP_H/projects/beta/project.json" "$TRP_H/projects/beta/project.json.bak" || return 1
  [ ! -e "$TRP_H/projects/beta/project.json" ] && TRCB=built
}
_trc_bound bound 0
_trp_at "$TRC/bound"; _lf_run "$TRC/c" "$TRP_S" - "$FELIX" which
is "P20 (control): a checkout once bound to beta by remote (its bindings.tsv row written), beta's project.json moved to project.json.bak, no fault: felix which says it no longer resolves (main's), exit 2" \
   "$TRCB|$(_trp_wcls "$TRC/c" "$TRP_S")|$(LC_ALL=C grep -c 'no longer resolves' "$TRC/c.err" 2>/dev/null)" "built|broken|1"
for _trc_m in f2 f3; do
  _trp_new "$TRC/p.fired"; _trp_arm "$_trc_m" git "*' hash-object --stdin '*" '*'
  _trp_go _lf_run "$TRC/w" "$TRP_S" - "$FELIX" which
  is "P20: the same checkout, $_trc_m at the git hash-object that keys the bindings record: unknown, never no project governs" \
     "$(_trc_unk "$TRC/w" "$TRP_S" 2)|$TRP_FIRE" "unknown|fired"
done
_trc_bound boundhome 1
_trp_at "$TRC/boundhome"; _lf_run "$TRC/c" "$TRP_S" - env -u FELIX_MEMORY "$FELIX" which; TRCCL="$(_trp_said "$TRC/c")"
is "P21 (control): the same layout with FELIX_MEMORY unset (the record in ~/.felix/memory), no fault: felix which says it no longer resolves, exit 2" \
   "$TRCB|$(_trp_wcls "$TRC/c" "$TRP_S")|$(LC_ALL=C grep -c 'no longer resolves' "$TRC/c.err" 2>/dev/null)" "built|broken|1"
_trp_new "$TRC/p.fired"; _trp_arm f3z printf '*' "*' felix_mem_root '*' _felix_binding_remote '*"
_trp_go _lf_run "$TRC/w" "$TRP_S" - env -u FELIX_MEMORY "$FELIX" which
TRCS="$(_trp_said "$TRC/w")"
case "$TRP_FIRE:$(_trp_wcls "$TRC/w" "$TRP_S")" in
  fired:unknown) _trc_v=ok ;;
  fired:*) [ "$TRCS" = "$TRCCL" ] && _trc_v=ok || _trc_v="fired: $TRCS" ;;
  *) [ "$TRCS" = "$TRCCL" ] && _trc_v=ok || _trc_v="not fired, and not the clean run: $TRCS" ;;
esac
is "P21: FELIX_MEMORY unset, F3 at the memory-root read (the substitution around felix_mem_root inside _felix_binding_remote): unknown or the clean sentence, never no project governs (a probe that never acts, the read made fork-free, must leave the clean run)" \
   "$_trc_v" ok

# --- P23: every resolve_or_die command under a marker read that did not finish.
_trp_at "$TRC/marker"
_trc_sha() { ( _fx_cd "$TRP_CO" || exit 1; _lf_g 1700000000 rev-parse HEAD ) 2>/dev/null; }
TRCH0="$(_trc_sha)"
for _trc_c in which merge "land --status" repair "land --tick"; do
  case "$_trc_c" in repair) _trc_rc=4 ;; *) _trc_rc=2 ;; esac
  _trp_new "$TRC/p.fired"; _trp_arm f3 tr "*' -d [:space:] '*" '*'
  # shellcheck disable=SC2086
  _trp_go _lf_run "$TRC/w" "$TRP_S" - env FELIX_LAND_LEDGER="$TRP_FX/land/ledger.tsv" "$FELIX" $_trc_c
  case "$_trc_c" in
    merge) _trc_x="|says.log merged rows $(LC_ALL=C awk '/merged/ { n++ } END { print n + 0 }' "$TRP_M/alpha/says.log" 2>/dev/null || printf 0)|HEAD $( [ "$(_trc_sha)" = "$TRCH0" ] && printf kept || printf moved)"
           _trc_w="|says.log merged rows 0|HEAD kept" ;;
    "land --tick") _trc_x="|unresolved rows $(LC_ALL=C awk -F'\t' '$2 == "unresolved" { n++ } END { print n + 0 }' "$TRP_FX/land/ledger.tsv" 2>/dev/null)"
           _trc_w="|unresolved rows 1" ;;
    *) _trc_x=""; _trc_w="" ;;
  esac
  is "P23: felix $_trc_c on base, F3 at the marker's tr: exit $_trc_rc, nothing on stdout, stderr the could-not-be-resolved sentence${_trc_w:+ (and$(printf '%s' "$_trc_w" | tr '|' ' '))}" \
     "$(_trc_unk "$TRC/w" "$TRP_S" "$_trc_rc")$_trc_x|$TRP_FIRE" "unknown$_trc_w|fired"
done

# --- P24: felix which's own reads.
_trp_new "$TRC/p.fired"
_trp_arm f3 pwd "*' -P '*" "*' felix_repo_root '*' cmd_which '*" "*' resolve_or_die '*|*' felix_resolve_project '*|*' felix_binding_broken '*"
_trp_arm f3 git "*' rev-parse --show-toplevel '*" "*' felix_repo_root '*' cmd_which '*" "*' resolve_or_die '*|*' felix_resolve_project '*|*' felix_binding_broken '*"
_trp_go _lf_run "$TRC/w" "$TRP_S" - "$FELIX" which
is "P24: felix which on base, F3 at felix_repo_root for the governs line (the walk's pwd -P and git rev-parse, called by cmd_which): unknown, nothing on stdout (never four lines, never an empty or wrong governs:)" \
   "$(_trc_unk "$TRC/w" "$TRP_S" 2)|$TRP_FIRE" "unknown|fired"
_trp_new "$TRC/p.fired"; _trp_arm f1 sed "*'\"gate\"'*" "*' cmd_which '*" "*' resolve_or_die '*"
_trp_go _lf_run "$TRC/w" "$TRP_S" - "$FELIX" which
is "P24: felix which on base, F1 at the sed that reads the gate key (called by cmd_which): unknown, nothing on stdout (never an empty gate:)" \
   "$(_trc_unk "$TRC/w" "$TRP_S" 2)|$TRP_FIRE" "unknown|fired"

# --- P45: felix_accepted_deploy_diff from a directory that holds only resolve.sh.
TRCJ="$TRC/judge"; TRCJR="$TRCJ/home"; TRCJC="$TRCJ/cache"; TRCJE="$TRCJC/felix/felix/4.0.0"
mkdir -p "$TRCJR/engine/harness/lib" "$TRCJR/engine/hooks" "$TRCJR/engine/commands" "$TRCJ/alone" "$TRCJ/empty"
printf 'real\n' > "$TRCJR/engine/harness/felix"; printf 'x\n' > "$TRCJR/engine/harness/lib/x.sh"
printf '{}\n' > "$TRCJR/engine/hooks/hooks.json"; printf '# felix\n' > "$TRCJR/engine/commands/felix.md"
( _fx_cd "$TRCJR" && git init -q -b main ) >/dev/null 2>&1
_jr_commit "$TRCJR" main engine/.claude-plugin/plugin.json '{ "name": "felix", "version": "4.0.0" }'
_jr_on "$TRCJR" "$(_jr_sha "$TRCJR" HEAD)" refs/remotes/origin/main
cp "$FROOT/harness/lib/resolve.sh" "$TRCJ/alone/resolve.sh"
# -> TRCJE holds main's engine/{harness,hooks,commands,.claude-plugin}, cut from the commit.
_trc_cut() {
  rm -rf "$TRCJE" "$TRCJ/x" "$TRCJ/x.tar"; mkdir -p "$TRCJE" "$TRCJ/x"
  _fx_git "$TRCJR" archive -o "$TRCJ/x.tar" HEAD engine >/dev/null 2>&1 && tar -x -C "$TRCJ/x" -f "$TRCJ/x.tar"
  for _trc_d in harness hooks commands .claude-plugin; do [ ! -d "$TRCJ/x/engine/$_trc_d" ] || cp -R "$TRCJ/x/engine/$_trc_d" "$TRCJE/$_trc_d"; done
}
# CACHE LIB -> TRCJO: felix_accepted_deploy_diff HOME main, run by the driver from HOME with FELIX_PLUGIN_CACHE CACHE and
# the library directory LIB (the suite's engine lib/ when empty), FELIX_KERNEL_CACHE and GIT_CONFIG_GLOBAL unset, as
# "rc=<status> out=[<stdout>]".
_trc_judge() {
  TRCJO="$( unset FELIX_KERNEL_CACHE GIT_CONFIG_GLOBAL
            FELIX_PLUGIN_CACHE="$1" TRP_LIB="$2" _trp_drv "$TRCJ/o" "$TRCJR" judge "$TRCJR" main; _trp_ro "$TRCJ/o" )"
}
for _trc_v in identical drift nocache; do
  _trc_cut; _trc_cache="$TRCJC"
  case "$_trc_v" in drift) printf 'only in the entry\n' > "$TRCJE/harness/extra.sh" ;; nocache) _trc_cache="$TRCJ/empty" ;; esac
  _trc_judge "$_trc_cache" ""; _trc_full="$TRCJO"
  _trc_judge "$_trc_cache" "$TRCJ/alone"; _trc_one="$TRCJO"
  case "$_trc_v" in
    identical) _trc_ok="$( [ "$_trc_full" = "rc=0 out=[$TRCJE
]" ] && printf contract || printf 'not the contract' )" ;;
    drift) _trc_ok="$(case "$_trc_full" in ("rc=1 out=["*extra.sh*) printf contract ;; (*) printf 'not the contract' ;; esac)" ;;
    *) _trc_ok="$(case "$_trc_full" in ("rc=2 out=["*) printf contract ;; (*) printf 'not the contract' ;; esac)" ;;
  esac
  case "$_trc_v:$_trc_one" in nocache:*) _trc_tell=told ;; *:rc=2*) _trc_tell="cannot tell" ;; *) _trc_tell=told ;; esac
  is "P45: the merge judge's call with the entry $_trc_v: felix_accepted_deploy_diff sourced from a directory holding only resolve.sh gives main's answer (the contract's: identical 0 and the entry, drift 1 naming the path, no cache 2), the same as with every library beside it, and never cannot tell where the full engine tells" \
     "$_trc_ok|$( [ "$_trc_one" = "$_trc_full" ] && printf same || printf 'alone [%s] full [%s]' "$_trc_one" "$_trc_full")|$_trc_tell" "contract|same|told"
done
TRP_NAMES=""
# <<< trust-cli-refusals-unfinished-reads
