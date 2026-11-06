# >>> trust-table-unfinished-reads
printf '\ntrust plane step 1, the table check: felix_table_check says cannot examine when a read of its own did not finish, never accepted and never a false refusal (spec section 5, properties 1 and 28-37; blind)\n'
# Blind, written on 2026-11-05 from .felix/memory/felix/audits/2026-10-31-trust-plane-replay/step1/spec.md (sections 0-8
# and the merge-judge item) and the P2 case's table layouts and examples, before any fix. felix_table_check is run by
# the driver of tests/lib/trust-probes.sh: a fresh /bin/bash that sources lib/table.sh alone, under set -u and, unless a
# property turns it off (TRP_PF=off, as bin/schema-check runs), -o pipefail.
#
# "Unknown" for the table is exit 2 with exactly one line, FILE:- TAB cannot-examine TAB a read of the check's own did
# not finish (section 5's head; _trp_tcls). Readings where the spec leaves room:
# - A read the spec marks "if called" or "if one exists" (the arity's cut and awk, the empty cell's cut, the hi and the
#   refusal-line substitutions, the load-time substitution, tail) may be removed by the fix. Where its probe does not
#   act, the run must equal the clean run (section 5's head), and that is what the assertion then checks; on main
#   every one of them acts.
# - The main pass is the awk whose program counts rows (rows++); the schema lookup is every awk felix_table_schema runs.
# - P33's printf substitutions are each refusal line's own: no-final-newline on the shapes table less every per-line
#   shape, and nul-byte and empty on the NUL and empty-refused tables (T9 names all three). On tab-nul a refusal must
#   still hold the nul-byte line: gawk also refuses line 2's encoding (R10), so "never 0" alone cannot see it lost.
# - P35 is read over every run 28-34 says is unknown: stdout is that one line and nothing else.
# - P37's second half, felix merge --dry-run on the fix branch, needs the real felix project's risk table and a base
#   ref, which no fixture here carries; the count half reads this tree's lib/table.sh.
_lf_dir "$TMP/trust-2173"; TRD="$LF_DIR"
TRP_E="$FROOT/harness"
_trp_driver "$TRD/drv"
TRDBAD=""
for _trd_l in accepted cells empty-refused empty-allowed nul symlink shapes missing noschema finalnl encoding; do
  _trp_tab "$TMP/trust-2173/$_trd_l" "$_trd_l" || TRDBAD="$TRDBAD $_trd_l"
done
is "P1 (fixture control): every table layout of P2 and this part's own (finalnl, encoding) was built" "${TRDBAD:-built}" built
TRDUNK=""; TRDUN=0

# LAYOUT -> TRDS the layout's schemas.tsv and TRDF the file it checks.
_trd_at() {
  TRDS="$TRD/$1/tables/schemas.tsv"
  case "$1" in empty-allowed) TRDF="$TRD/$1/tables/e.tsv" ;; noschema) TRDF="$TRD/$1/tables/q.tsv" ;; *) TRDF="$TRD/$1/tables/t.tsv" ;; esac
}
# MODE LAYOUT -> felix_table_check (driver MODE: table, or tabempty) on LAYOUT with the probes armed now (none when
# TRP_NAMES is empty). TRDC its class (_trp_tcls), TRDO what it printed and its status (_trp_ro), TRDF2 the probe's mark.
_trd_run() {
  _trd_at "$2"
  if [ -n "${TRP_NAMES:-}" ]; then _trp_go _trp_drv "$TRD/o" "$TRD" "$1" "$TRDS" "$TRDF"; TRDF2="$TRP_FIRE"
  else _trp_drv "$TRD/o" "$TRD" "$1" "$TRDS" "$TRDF"; TRDF2=clean; fi
  TRDC="$(_trp_tcls "$TRD/o" "$TRDF")"; TRDO="$(_trp_ro "$TRD/o")"
}
# LAYOUT -> TRDCL the clean run's TRDO on LAYOUT.
_trd_clean() { TRP_NAMES=""; _trd_run table "$1"; TRDCL="$TRDO"; }
# LABEL LAYOUT ALTS MODE NAME WORDS STACK [NOT] -> one assertion: felix_table_check on LAYOUT under one probe is one of
# ALTS (classes), and the probe acted. A run ALTS holds unknown for is counted for P35.
_trd_one() {
  local lab="$1" l="$2" alts="$3"
  shift 3
  _trp_new "$TRD/p.fired"; _trp_arm "$@" || { bad "$lab" "the probe could not be armed: $*"; return; }
  _trd_run table "$l"; _trd_p35
  is "$lab" "$(_trp_in "$TRDC" "$alts")|$TRDF2" "ok|fired"
}
# LABEL LAYOUT ALTS MODE NAME WORDS STACK -> as _trd_one, for a read the fix may remove: a probe that acted gives one of
# ALTS, and one that never acted leaves the clean run's output and status. With TRDNEED set, a refused run that acted
# must also print TRDNEED (a refusal line's own words).
_trd_maybe() {
  local lab="$1" l="$2" alts="$3" v
  shift 3
  _trd_clean "$l"
  _trp_new "$TRD/p.fired"; _trp_arm "$@" || { bad "$lab" "the probe could not be armed: $*"; return; }
  _trd_run table "$l"
  case "$TRDF2" in
    fired) v="$(_trp_in "$TRDC" "$alts")"
      if [ "$v" = ok ] && [ "$TRDC" = refused ] && [ -n "${TRDNEED:-}" ]; then
        case "$TRDO" in *"$TRDNEED"*) ;; *) v="refused without its${TRDNEED//	/ } line: $TRDO" ;; esac
      fi ;;
    *) if [ "$TRDO" = "$TRDCL" ]; then v=ok; else v="not fired, and not the clean run: $TRDO"; fi ;;
  esac
  is "$lab" "$v" ok
}
# -> counts the last run for P35 when its expected class is unknown (TRDP35 set by the caller).
_trd_p35() {
  [ "${TRDP35:-}" = 1 ] || return 0
  TRDUN=$((TRDUN + 1))
  [ "$TRDC" = unknown ] || TRDUNK="$TRDUNK[$TRDLAB: $TRDO] "
}
TRP_NAMES=""; TRDP35=""

# --- P1: every P2 table layout, no fault.
_trd_ex() {   # LAYOUT -> the P2 example for LAYOUT as _trp_ro words it, FILE the checked file
  local f="$TRDF"
  case "$1" in
    accepted|empty-allowed) printf 'rc=0 out=[]' ;;
    cells) printf 'rc=1 out=[%s:2\tcells\t1 cell(s); 2 to 3 declares name kind note?\n%s:3\tcells\t4 cell(s); 2 to 3 declares name kind note?\n]' "$f" "$f" ;;
    empty-refused) printf 'rc=1 out=[%s:-\tempty\tno rows, and t.tsv declares that emptiness is never legitimate\n]' "$f" ;;
    nul) printf 'rc=1 out=[%s:-\tnul-byte\ta NUL byte, which makes grep treat the file as binary and print no rows\n]' "$f" ;;
    symlink) printf 'rc=1 out=[%s:-\tsymlink\ta link, so the escape check compares its text and a reader reads its target\n]' "$f" ;;
    missing) printf 'rc=2 out=[%s:-\tcannot-examine\tno readable file\n]' "$f" ;;
    noschema) printf 'rc=2 out=[%s:-\tno-schema\tq.tsv has no row in schemas.tsv\n]' "$f" ;;
    shapes) printf 'rc=1 out=[%s:2\tindented-comment\twhitespace before #, which the read-and-case loops take for a row\n' "$f"
      printf '%s:3\twhitespace-line\ta line of only whitespace, which the raw case loops take for a row\n' "$f"
      printf '%s:4\tnonascii-lead\ta line that starts with a non-ASCII byte, which is whitespace to some locales and not others\n' "$f"
      printf '%s:5\tcarriage-return\ta CR byte, which a tab-IFS read keeps in the last cell\n' "$f"
      printf '%s:6\tempty-cell\ta leading, trailing or doubled tab, which moves every later column under an IFS read\n' "$f"
      printf '%s:7\tencoding\ta line that is not UTF-8, which grep drops in a UTF-8 locale and macOS awk cannot read\n' "$f"
      printf '%s:-\tno-final-newline\tthe last line has no newline, and the done-< loops drop it while grep and awk keep it\n]' "$f" ;;
  esac
}
for _trd_l in accepted cells empty-refused empty-allowed nul symlink shapes missing noschema; do
  _trd_run table "$_trd_l"
  _trd_e="$(_trd_ex "$_trd_l")"
  # P2's residual R10: the NUL layout depends on the awk build. gawk reads the line holding the NUL whole and refuses its
  # encoding too, so that line before the nul-byte one is P2's example there.
  [ "$_trd_l" != nul ] || [ "$TRDO" != "rc=1 out=[$TRDF:2	encoding	a line that is not UTF-8, which grep drops in a UTF-8 locale and macOS awk cannot read
${_trd_e#rc=1 out=[}" ] || _trd_e="$TRDO"
  is "P1: felix_table_check on P2's tab-$_trd_l layout (base is accepted), no fault: P2's example, byte for byte, and its status (for tab-nul, under gawk, an encoding line for line 2 first: R10)" "$TRDO" "$_trd_e"
done

# --- P28: the main pass.
TRDP35=1
for _trd_l in accepted cells shapes nul empty-refused; do
  for _trd_m in f1 f2 f3 f5; do
    case "$_trd_l" in accepted) _trd_w="never 0, never 1" ;; *) _trd_w="never 0 (R2-F4)" ;; esac
    TRDLAB="P28 $_trd_l $_trd_m"
    _trd_one "P28: tab-$_trd_l (base is accepted), $_trd_m at the main awk pass: unknown, $_trd_w" \
      "$_trd_l" unknown "$_trd_m" awk '*rows++*' "*' felix_table_check '*"
  done
done
# --- P29: the schema lookup.
for _trd_m in f1 f2 f3; do
  TRDLAB="P29 $_trd_m"
  _trd_one "P29: table base, $_trd_m at the schema lookup's awk (every awk felix_table_schema runs): unknown, never 1 (R2-F9)" \
    accepted unknown "$_trd_m" awk '*' "*' felix_table_schema '*"
done
TRDP35=""
_trd_one "P29: table base, F5 at the schema lookup's awk: exit 2, with either line (no-schema or the unknown line)" \
  accepted "unknown|examine2" f5 awk '*' "*' felix_table_schema '*"
# --- P30: the arity, pipefail off.
TRDP35=1
for _trd_n in cut awk; do
  for _trd_m in f1 f2 f3 f5; do
    TRDLAB="P30 $_trd_n $_trd_m"
    TRP_PF=off _trd_maybe "P30: table base, run with pipefail off (as bin/schema-check), $_trd_m at the arity's $_trd_n (if called): unknown, never 1; not called, the clean run" \
      accepted unknown "$_trd_m" "$_trd_n" '*' "*' _felix_table_arity '*"
    [ "$TRDF2" != fired ] || _trd_p35
  done
done
TRDP35=""
# --- P31: the schema's empty cell.
for _trd_m in f1 f3 f5; do
  _trd_maybe "P31: tab-empty-refused, $_trd_m at the read of the schema's empty cell (cut -f4, if called): never 0; not called, the clean run" \
    empty-refused "refused|unknown|examine2" "$_trd_m" cut "*' -f4 '*" "*' felix_table_check '*"
done
# --- P32: the hi substitution.
_trd_maybe "P32: table base, F3 at the substitution that makes hi (printf [\\200-\\377], if one exists): never 1; none, the clean run" \
  accepted "accepted|unknown|examine2" f3z printf "*'[\\200-\\377]'*" "*' felix_table_check '*"
# --- P33: the file-level reads.
_trd_maybe "P33: the shapes table less every per-line shape (only no-final-newline), F3 at the substitution of its refusal line (if any): never 0" \
  finalnl "refused|unknown|examine2" f3z printf '*no-final-newline*' "*' felix_table_check '*"
TRDNEED=$'\tnul-byte\t' _trd_maybe "P33: tab-nul, F3 at the substitution of the nul-byte refusal line (if any): never 0, and a refusal still holds the nul-byte line (T9; under gawk the encoding line alone keeps it refused, R10)" \
  nul "refused|unknown|examine2" f3z printf '*nul-byte*' "*' felix_table_check '*"
_trd_maybe "P33: tab-empty-refused, F3 at the substitution of the empty refusal line (if any): never 0" \
  empty-refused "refused|unknown|examine2" f3z printf "*'emptiness is never legitimate'*" "*' felix_table_check '*"
for _trd_n in tail od; do
  case "$_trd_n" in tail) _trd_k="*' -c 1 '*" ;; *) _trd_k="*' -An '*" ;; esac
  _trd_maybe "P33: the shapes table less every per-line shape (only no-final-newline), F3 at $_trd_n (if called): never 0" \
    finalnl "refused|unknown|examine2" f3 "$_trd_n" "$_trd_k" "*' felix_table_check '*"
done
TRDP35=1
for _trd_n in od tail wc tr; do
  case "$_trd_n" in tail) _trd_k="*' -c 1 '*" ;; od) _trd_k="*' -An '*" ;; wc) _trd_k="*' -c '*" ;; *) _trd_k="*' -d \\000 '*" ;; esac
  for _trd_m in f1 f2 f3 f5; do
    TRDLAB="P33 $_trd_n $_trd_m"
    _trd_maybe "P33: table base, $_trd_m at $_trd_n (the last byte and the NUL count; if called): unknown, never 1; not called, the clean run" \
      accepted unknown "$_trd_m" "$_trd_n" "$_trd_k" "*' felix_table_check '*"
    [ "$TRDF2" != fired ] || _trd_p35
  done
done
TRDP35=""
# --- P34: the encoding pattern.
_trd_maybe "P34: table.sh sourced with F3 at its load-time substitution (the UTF-8 pattern, if one exists), then a good row and a line holding the byte 377: never 0" \
  encoding "refused|unknown|examine2" f3z printf "*'^([\\001-\\177]'*" '*'
TRDP35=1
for _trd_l in accepted cells shapes nul empty-refused; do
  TRP_NAMES=""; _trd_run tabempty "$_trd_l"; TRDLAB="P34 empty $_trd_l"; _trd_p35
  is "P34: FELIX_TABLE_UTF8= set after sourcing table.sh, tab-$_trd_l: felix_table_check is 2, the unknown line" "$TRDC" unknown
done
TRDP35=""
# --- P35: no partial refusal lines. How many runs it reads is the tree's (P30 and P33 count a run only where its probe
# acted: 40 here, 52 at 1fca9559), so the count stays out of the name, which must be one string on every tree for
# tests/red and the manifest to agree. None counted would leave the property vacuous, and is said.
is "P35: in each run P28-P34 call unknown (a probe that acted, or the empty pattern), the unknown line is the only line on stdout: no refusal line printed before the read failed" \
   "$([ "${TRDUN:-0}" -gt 0 ] || printf 'no run counted: ')${TRDUNK:-only that line}" "only that line"

# --- P36: bin/schema-check, the caller, over a tree whose one table check is faulted as in P28.
TRDX="$TRD/sc"; mkdir -p "$TRDX/engine/harness/templates"
printf '# table\tlives\tcolumns\tempty\nschemas.tsv\ttree\ttable lives columns empty\trefused\nt.tsv\ttree\tname kind note?\trefused\n' \
  > "$TRDX/engine/harness/templates/schemas.tsv"
printf 'alpha\tx\n' > "$TRDX/t.tsv"
# _lf_run's environment is this part's own: run alone (tests/run -j N), no earlier part has named one.
mkdir -p "$TRD/sc.home" "$TRD/sc.bin"; _lf_use "$TRD/sc.home" "$TRD/sc.mem" "$TRD/sc.user" "$TRD/sc.bin"
_lf_init "$TRDX" && _lf_commit "$TRDX" 1790000000 $'tables\n' "=engine/harness/templates/schemas.tsv" "=t.tsv"; TRDXB=$?
_lf_run "$TRD/x" "$TRDX" - "$FROOT/harness/bin/schema-check"
is "P36 (control): a tree with schemas.tsv and one good table t.tsv, no fault: bin/schema-check exits 0" "$TRDXB|$LF_RC" "0|0"
_trp_new "$TRD/p.fired"; _trp_arm f1 awk '*rows++*' "*' felix_table_check '*"
_trp_go _lf_run "$TRD/x" "$TRDX" - "$FROOT/harness/bin/schema-check"
is "P36: the same tree, F1 at felix_table_check's main pass: bin/schema-check exits non-zero with an unexaminable line for t.tsv (schema-check unchanged; this pins the caller)" \
   "$( [ "$LF_RC" != 0 ] && printf non-zero || printf 0)|$(LC_ALL=C awk -F'\t' '$1 == "t.tsv:-" && $2 == "unexaminable" { f = 1 } END { print (f ? "unexaminable" : "no unexaminable line") }' "$TRD/x.out" 2>/dev/null)|$TRP_FIRE" \
   "non-zero|unexaminable|fired"

# --- P37: the risk count of row 47.
is "P37: lib/table.sh holds at least 23 lines a literal \\t<reason>\\t matches (risk row 47's confine, counted as _felix_escape_fewer counts it; 23 at 1fca9559)" \
   "$( [ "$(LC_ALL=C grep -cE '\\t[a-z][a-z-]*\\t' "$FROOT/harness/lib/table.sh" 2>/dev/null)" -ge 23 ] 2>/dev/null && printf 'at least 23' || printf 'fewer: %s' "$(LC_ALL=C grep -cE '\\t[a-z][a-z-]*\\t' "$FROOT/harness/lib/table.sh" 2>&1)")" \
   "at least 23"
TRP_NAMES=""
# <<< trust-table-unfinished-reads
