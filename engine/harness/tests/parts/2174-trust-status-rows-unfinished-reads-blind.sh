# >>> trust-status-rows-unfinished-reads
printf '\ntrust plane step 1, felix status: the project rows say unknown when the resolution or the checkout root did not finish, and keep main'"'"'s bytes when it did (spec section 8, properties 39-44; blind)\n'
# Blind, written on 2026-11-05 from .felix/memory/felix/audits/2026-10-31-trust-plane-replay/step1/spec.md (section 8,
# added by the orchestrator, with sections 0-7) and the P2 case's resolver layouts, before any fix. felix status --tsv is
# run as a black box from each checkout's co/res/sub/dir through _lf_run, the probes being tests/lib/trust-probes.sh's.
# Readings where the spec leaves room:
# - "Scoped" (P39, P41, P42, P43) is the probe's calling functions: felix_resolve_project inside felix_status_rows, and
#   not inside _felix_status_alerts or the lane's resolution (felix_lane_resolve, _lane_resolve), for the nine rows;
#   inside _felix_status_alerts for the alerts row; felix_repo_root inside felix_status_rows, and not inside the
#   resolution, the lane or a row function, for the checkout root.
# - P40's "main's bytes" for every P2 res layout are the ten rows the spec's section 8 keeps unchanged, written out here:
#   the project rows of the project P2's example binds (reach, gate, land, hooks and lane), the miss rows "this directory
#   is not a governed checkout" where none binds, and the machine rows this fixture's stubs and empty HOME give.
# - P42's home resolves through its own .felix (a home that is its own checkout); the clean alerts row there is the
#   contract's "none - no alert has been tried for <project>".
_lf_dir "$TMP/trust-2174"; TRE="$LF_DIR"
TREBAD=""
for _tre_l in marker remote nest tie badmarker none slug; do _trp_res "$TMP/trust-2174/$_tre_l" "$_tre_l" || TREBAD="$TREBAD $_tre_l"; done
_lf_self "$TMP/trust-2174/self" hp && TRESH="$LF_HOME" || TREBAD="$TREBAD self"
_lf_stubs "$TRE/selfx" && TRESB="$LF_BIN" || TREBAD="$TREBAD selfstubs"
is "P40 (fixture control): every P2 resolver layout and a home that is its own checkout (project hp) were built" "${TREBAD:-built}" built
TRENOT="this directory is not a governed checkout"
TREUNK="could not be resolved: a read it stands on did not finish"

# LAYOUT P -> the ten rows the spec keeps as main's for felix status --tsv from LAYOUT's sub/dir, P the project P2's
# example binds (- for none).
_tre_rows() {
  local fx="$TRE/$1" p="$2"
  _lf_tsv settings value missing "$fx/user/.claude/settings.json does not exist"; printf '\n'
  _lf_tsv schedule none - 'no felix.pulse agent; felix pulse --install schedules one'; printf '\n'
  _lf_tsv pulse none - 'the pulse has never run here'; printf '\n'
  if [ "$p" = - ]; then
    _lf_tsv reach none - "$TRENOT"; printf '\n'; _lf_tsv gate none - "$TRENOT"; printf '\n'
    _lf_tsv land none - "$TRENOT"; printf '\n'; _lf_tsv hooks none - "$TRENOT"; printf '\n'
  else
    _lf_tsv reach none - "$p declares no plugin or mcp rows"; printf '\n'
    _lf_tsv gate value none-run 'no gate has run in this checkout'; printf '\n'
    _lf_tsv land none - "no land-on-green job for $p; felix land --install schedules one"; printf '\n'
    _lf_tsv hooks value clear "no project or local settings file in $fx/co/res/.claude turns hooks off; managed settings, a --settings file, --bare and an untrusted workspace are not read here"; printf '\n'
  fi
  _lf_tsv alerts unknown - "the home $fx/felix-home resolves no project, so no alert record was looked for"; printf '\n'
  _lf_tsv icloud value clear 'no name shaped like an iCloud copy under state/ and .git (objects not read); the home is not inside iCloud Drive or an iCloud-synced Desktop or Documents'; printf '\n'
  if [ "$p" = - ]; then _lf_tsv lane none - "$TRENOT"; else _lf_tsv lane none - "$fx/felix-home/projects/$p/lanes.tsv has no committed row, so no lane is counted"; fi
  printf '\n'
}
# OUT ROWS... -> OUT.out's rows with each named row's line left out, in order: what the other rows of two runs share.
_tre_but() { local o="$1"; shift; LC_ALL=C awk -F'\t' -v x=" $* " 'index(x, " " $1 " ") == 0 { print }' "$o.out" 2>/dev/null; }

# --- P40: every P2 res layout, clean.
for _tre_l in marker remote nest tie badmarker none slug; do
  case "$_tre_l" in marker|slug) _tre_p=alpha ;; remote|nest) _tre_p=beta ;; *) _tre_p=- ;; esac
  _trp_at "$TRE/$_tre_l"; _lf_run "$TRE/s" "$TRP_S" - "$FELIX" status --tsv
  is "P40: felix status --tsv from res layout $_tre_l's co/res/sub/dir, no fault: exit 0 and the ten rows byte-identical to main's" \
     "$(_trp_ro "$TRE/s")" "rc=0 out=[$(_tre_rows "$_tre_l" "$_tre_p")
]"
done

# --- P39, P41: the nine rows' resolution did not finish.
# LABEL LAYOUT MODE NAME WORDS -> one assertion: felix status --tsv from LAYOUT's sub/dir, the probe acting inside
# felix_resolve_project as felix_status_rows calls it: reach, gate, land and hooks the unknown row, the other six as the
# clean run's, exit 0, and the probe acted.
_tre_nine() {
  local lab="$1" l="$2" r want="" clean
  _trp_at "$TRE/$l"
  _lf_run "$TRE/c" "$TRP_S" - "$FELIX" status --tsv; clean="$(_tre_but "$TRE/c" reach gate land hooks)"
  _trp_new "$TRE/p.fired"
  _trp_arm "$3" "$4" "$5" "*' felix_resolve_project '*' felix_status_rows '*" "*' _felix_status_alerts '*|*' felix_lane_resolve '*|*' _lane_resolve '*"
  _trp_go _lf_run "$TRE/s" "$TRP_S" - "$FELIX" status --tsv
  for r in reach gate land hooks; do
    want="$want$r=[$(_lf_tsv "$r" unknown - "the project that governs $TRP_S $TREUNK")] "
  done
  is "$lab" \
     "rc=$LF_RC|$(for r in reach gate land hooks; do printf '%s=[%s] ' "$r" "$(_trp_row "$TRE/s" "$r")"; done)|$( [ "$(_tre_but "$TRE/s" reach gate land hooks)" = "$clean" ] && printf 'six as clean' || printf 'six differ: [%s]' "$(_tre_but "$TRE/s" reach gate land hooks)")|$TRP_FIRE" \
     "rc=0|$want|six as clean|fired"
}
for _tre_m in f1 f3; do
  _tre_nine "P39: base, felix status --tsv, $_tre_m at the marker's tr only inside felix_resolve_project as felix_status_rows calls it: reach, gate, land and hooks are unknown with the could-not-be-resolved sentence (never none), and the other six rows equal the clean run" \
    marker "$_tre_m" tr "*' -d [:space:] '*"
done
_tre_nine "P41: res-remote, felix status --tsv, F2 at git remote get-url only inside felix_resolve_project as felix_status_rows calls it: as P39" \
  remote f2 git "*' remote get-url origin '*"

# --- P42: the home's own resolution, for the alerts row.
_lf_use "$TRESH" "$TRE/self.mem" "$TRE/self.user" "$TRESB"
_lf_run "$TRE/c" "$TRESH" - "$FELIX" status --tsv
is "P42 (control): felix status --tsv in a home that is its own checkout (project hp), no fault: the alerts row is none, no alert has been tried for hp" \
   "$(_trp_row "$TRE/c" alerts)" "$(_lf_tsv alerts none - 'no alert has been tried for hp')"
for _tre_m in f1 f3; do
  _trp_new "$TRE/p.fired"; _trp_arm "$_tre_m" tr "*' -d [:space:] '*" "*' felix_resolve_project '*' _felix_status_alerts '*"
  _trp_go _lf_run "$TRE/s" "$TRESH" - "$FELIX" status --tsv
  is "P42: felix status --tsv in that home, $_tre_m at the marker's tr only inside the home's resolution of _felix_status_alerts: alerts is unknown with the could-not-be-resolved detail for the home, never resolves no project" \
     "$(_trp_row "$TRE/s" alerts)|$TRP_FIRE" "$(_lf_tsv alerts unknown - "the project that governs the home $TRESH $TREUNK")|fired"
done

# --- P43: the checkout root did not finish.
_trp_at "$TRE/marker"
for _tre_m in f2 f3; do
  _trp_new "$TRE/p.fired"
  _tre_not="*' felix_resolve_project '*|*' felix_lane_resolve '*|*' _lane_resolve '*|*' _lane_bind '*|*' _felix_status_'*|*' felix_lane_status_row '*"
  _trp_arm "$_tre_m" pwd "*' -P '*" "*' felix_repo_root '*' felix_status_rows '*" "$_tre_not"
  _trp_arm "$_tre_m" git "*' rev-parse --show-toplevel '*" "*' felix_repo_root '*' felix_status_rows '*" "$_tre_not"
  _trp_go _lf_run "$TRE/s" "$TRP_S" - "$FELIX" status --tsv
  is "P43: base, felix status --tsv, $_tre_m at felix_repo_root's reads (the walk's pwd -P, then git rev-parse) only as felix_status_rows calls it, the project resolving through its own call: gate and hooks are unknown with the checkout-root detail, and the probe acted" \
     "$(_trp_row "$TRE/s" gate)|$(_trp_row "$TRE/s" hooks)|$TRP_FIRE" \
     "$(_lf_tsv gate unknown - "the checkout root of $TRP_S $TREUNK" | LC_ALL=C sed 's/could not be resolved/could not be read/')|$(_lf_tsv hooks unknown - "the checkout root of $TRP_S $TREUNK" | LC_ALL=C sed 's/could not be resolved/could not be read/')|fired"
done

# --- P44: the size of lib/status.sh.
is "P44: lib/status.sh has at most 499 lines (part 1100 holds it under 500, and its limit is not raised)" \
   "$( [ "$(LC_ALL=C awk 'END { print NR }' "$FROOT/harness/lib/status.sh" 2>/dev/null)" -le 499 ] 2>/dev/null && printf 'at most 499' || printf 'more: %s' "$(LC_ALL=C awk 'END { print NR }' "$FROOT/harness/lib/status.sh" 2>&1)")" \
   "at most 499"
TRP_NAMES=""
# <<< trust-status-rows-unfinished-reads
