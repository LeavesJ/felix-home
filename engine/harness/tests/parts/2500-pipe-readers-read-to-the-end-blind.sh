# >>> pipe-readers-read-to-the-end
printf '\na pipe'\''s reader reads to the end: _felix_instr_sha, _gt_detail and _gt_class over output past 256 KB (contract 2026-11-16, blind)\n'
# Blind, written on 2026-11-16 from docs/2026-11-16-pipe-readers-contract.md (rev 1, PR1 to PR8) alone, and amended
# the same day from rev 3 by a second blind author, who read the contract, this part, and the engine only as an
# export of main from before the fix. The first author read that engine for how to call _felix_instr_sha,
# _gt_detail and _gt_class, for what they print today, and for the suite's idiom (tests/run's helpers, part 0960's
# _spl_scan and its samples, part 0970's size check, part 2490's opening); every expected value of the new
# behaviour comes from the contract's text. A name ending (control) holds on main, on purpose. Of the others, the
# new behaviour, three hold on main too: the two checks that the large inputs are large and in order, and _gt_detail
# with SIGPIPE at its default, which PR2 says already reads clean there (its cut-off printf sits in an assignment
# whose status is not the function's). The rest fail on main: the four first-match _felix_instr_sha cases and the
# three other _gt_detail and _gt_class cases.
#
# Readings, where the contract leaves room:
# - "Under set -o pipefail, with SIGPIPE ignored and at its default" is a child bash that sets pipefail, sources the
#   one library and calls the function, started through perl with $SIG{PIPE} set to IGNORE or DEFAULT, since the
#   suite's own shell may run with it ignored. A large argument is read by the child from a file, never handed on argv.
# - "Writes nothing to standard error" is an empty stderr file, the library's sourcing excepted (sent to /dev/null).
# - PR2's _gt_class with STATUS not 3 prints hourly with no newline (rev 2), compared exactly from rev 3. The STATUS 3
#   words are compared exactly, newline included; _gt_detail exactly, with no newline.
# - _gt_detail's "the last line that holds a non-blank character" over an OUTPUT with no such line is read as nothing.
# - A felix merge block line is laid out as '  %-11s %-22s %s'; its fields are awk's blank-split fields.
# Everything this writes is under $TMP/_pra.

PRA="$TMP/_pra"; mkdir -p "$PRA"
_pra_t="$(printf '\t')"
_pra_nl='
'
# DISP LIB FUNC ARG...: FUNC of LIB in a child bash under pipefail with SIGPIPE at DISP (IGNORE or DEFAULT). An
# argument @FILE is FILE's text. stdout to $PRA/so, stderr to $PRA/se, the status in _pra_rc.
_pra_go() {
  _pra_rc=0
  perl -e '$SIG{PIPE} = shift; exec @ARGV; exit 127' "$1" "$BASH" -c '
    set -o pipefail
    . "$1" >/dev/null 2>&1 || exit 125
    f="$2"; shift 2; n=0
    for x in "$@"; do case "$x" in @*) a[n]="$(cat "${x#@}")" ;; *) a[n]="$x" ;; esac; n=$((n + 1)); done
    "$f" "${a[@]}"' _ "$REAL_HARNESS/$2" "$3" "${@:4}" > "$PRA/so" 2> "$PRA/se" || _pra_rc=$?
}
# NAME WANT: the last _pra_go printed WANT exactly, nothing on stderr, and returned 0.
_pra_is() {
  _pra_o="$(cat "$PRA/so"; printf x)"; _pra_o="${_pra_o%x}"
  _pra_e="$(sed -n 1p "$PRA/se")"
  if [ "$_pra_o" = "$2" ] && [ ! -s "$PRA/se" ] && [ "$_pra_rc" = 0 ]; then ok "$1"
  else bad "$1" "stdout [$_pra_o] want [$2]; stderr [$_pra_e]; status $_pra_rc (want empty and 0)"; fi
}
# FILE FIRST LAST LINE: FILE is FIRST (lines, may be empty), 6,000 copies of LINE (awk printf, one %05d), then LAST.
_pra_big() {
  _PRA_F="$2" _PRA_L="$3" _PRA_B="$4" awk 'BEGIN { f = ENVIRON["_PRA_F"]; l = ENVIRON["_PRA_L"]; b = ENVIRON["_PRA_B"]
    if (f != "") print f
    for (i = 1; i <= 6000; i++) printf b "\n", i
    if (l != "") print l }' > "$1"
}
_pra_size() { wc -c < "$1" | tr -d ' '; }

# ---------------------------------------------------------------- PR1 ----
_pra_id=0123456789abcdef0123456789abcdef01234567
_pra_id2=fedcba9876543210fedcba9876543210fedcba98
_pra_idt=eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
_pra_hit="100644 blob $_pra_id${_pra_t}pra/target.sh"
_pra_row="100644 blob 00000000000000000000000000000000%08d${_pra_t}pra/bulk/file.sh"
_pra_big "$PRA/first.ls" "$_pra_hit" "100644 blob $_pra_id2${_pra_t}pra/target.sh" "$_pra_row"
_pra_big "$PRA/tree.ls" "040000 tree $_pra_idt${_pra_t}pra/target.sh$_pra_nl$_pra_hit" "" "$_pra_row"
_pra_big "$PRA/last.ls" "" "$_pra_hit" "$_pra_row"
_pra_big "$PRA/none.ls" "" "" "$_pra_row"
_pra_short=""
for _pra_f in first tree last none; do
  [ "$(_pra_size "$PRA/$_pra_f.ls")" -ge 262144 ] || _pra_short="$_pra_short $_pra_f.ls ($(_pra_size "$PRA/$_pra_f.ls") bytes)"
done
[ "$(sed -n 1p "$PRA/first.ls")" = "$_pra_hit" ] || _pra_short="$_pra_short first.ls does not start with the blob asked for"
[ "$(sed -n 2p "$PRA/tree.ls")" = "$_pra_hit" ] || _pra_short="$_pra_short tree.ls does not hold the blob on its second line"
[ "$(tail -n 1 "$PRA/last.ls")" = "$_pra_hit" ] || _pra_short="$_pra_short last.ls does not end with the blob asked for"
[ -z "$_pra_short" ] \
  && ok  "every _felix_instr_sha listing below is past 256 KB, the early ones with the blob asked for first" \
  || bad "every _felix_instr_sha listing below is past 256 KB, the early ones with the blob asked for first" \
         "too small or out of order, so a pass below would prove nothing:$_pra_short"
for _pra_d in IGNORE DEFAULT; do
  case "$_pra_d" in IGNORE) _pra_w="with SIGPIPE ignored" ;; *) _pra_w="with SIGPIPE at its default" ;; esac
  _pra_go "$_pra_d" lib/instrument.sh _felix_instr_sha "@$PRA/first.ls" pra/target.sh
  _pra_is "_felix_instr_sha over a listing past 256 KB whose first line is the blob prints its id and a newline, writes nothing on stderr and returns 0, $_pra_w" "$_pra_id$_pra_nl"
  _pra_go "$_pra_d" lib/instrument.sh _felix_instr_sha "@$PRA/tree.ls" pra/target.sh
  _pra_is "_felix_instr_sha over a listing past 256 KB that opens with a tree at the path and then the blob prints the blob's id, quietly and with status 0, $_pra_w" "$_pra_id$_pra_nl"
  _pra_go "$_pra_d" lib/instrument.sh _felix_instr_sha "@$PRA/last.ls" pra/target.sh
  _pra_is "_felix_instr_sha over a listing past 256 KB whose last line is the blob prints its id, quietly and with status 0, $_pra_w (control)" "$_pra_id$_pra_nl"
  _pra_go "$_pra_d" lib/instrument.sh _felix_instr_sha "@$PRA/none.ls" pra/target.sh
  _pra_is "_felix_instr_sha over a listing past 256 KB that does not hold the path prints nothing, quietly and with status 0, $_pra_w (control)" ""
done
_pra_go IGNORE lib/instrument.sh _felix_instr_sha "040000 tree $_pra_idt${_pra_t}pra/target.sh
160000 commit $_pra_id2${_pra_t}pra/target.sh
$_pra_hit" pra/target.sh
_pra_is "_felix_instr_sha passes over a tree and a commit at the path for the blob after them (control)" "$_pra_id$_pra_nl"
_pra_go IGNORE lib/instrument.sh _felix_instr_sha "040000 tree $_pra_idt${_pra_t}pra/target.sh" pra/target.sh
_pra_is "_felix_instr_sha prints nothing when the path is there only as another type (control)" ""
_pra_go IGNORE lib/instrument.sh _felix_instr_sha "100644 blob $_pra_idt${_pra_t}pra/target.sh.bak
100644 blob $_pra_id2${_pra_t}x/pra/target.sh
$_pra_hit
100644 blob $_pra_idt${_pra_t}pra/target.sh" pra/target.sh
_pra_is "_felix_instr_sha takes only a path that is exactly the one asked for, and the first such blob (control)" "$_pra_id$_pra_nl"

# ---------------------------------------------------------------- PR2 ----
_pra_blk="  not-green   tests                  the gate receipt is not green on this head"
_pra_big "$PRA/detail.out" "$_pra_blk" "  escape      write                  a later blocker${_pra_nl}closing words" \
  "felix merge output line %05d, read past the deciding line"
_pra_rcpt="  commission  receipt                the commission receipt predates the change"
_pra_big "$PRA/class.out" "not merging$_pra_nl$_pra_nl$_pra_rcpt$_pra_nl" \
  "not merging$_pra_nl$_pra_nl  escape      write                  notes/x.md: outside the tree$_pra_nl${_pra_nl}closing words" \
  "  escape      write                  notes/file-%05d.md: outside the tree"
_pra_short=""
for _pra_f in detail class; do
  [ "$(_pra_size "$PRA/$_pra_f.out")" -ge 262144 ] || _pra_short="$_pra_short $_pra_f.out ($(_pra_size "$PRA/$_pra_f.out") bytes)"
done
[ "$(sed -n 1p "$PRA/detail.out")" = "$_pra_blk" ] || _pra_short="$_pra_short detail.out does not open with its two-space line"
[ "$(sed -n 1p "$PRA/class.out")" = "not merging" ] && [ "$(sed -n 3p "$PRA/class.out")" = "$_pra_rcpt" ] \
  && [ -z "$(sed -n 4p "$PRA/class.out")" ] || _pra_short="$_pra_short class.out does not open with not merging and its one-line block"
[ -z "$_pra_short" ] \
  && ok  "the _gt_detail and _gt_class outputs below are past 256 KB with their deciding lines first" \
  || bad "the _gt_detail and _gt_class outputs below are past 256 KB with their deciding lines first" \
         "too small or out of order, so a pass below would prove nothing:$_pra_short"
for _pra_d in IGNORE DEFAULT; do
  case "$_pra_d" in IGNORE) _pra_w="with SIGPIPE ignored" ;; *) _pra_w="with SIGPIPE at its default" ;; esac
  _pra_go "$_pra_d" lib/green-tick.sh _gt_detail "@$PRA/detail.out"
  _pra_is "_gt_detail over felix merge output past 256 KB whose first line is a blocker prints that line with no newline, writes nothing on stderr and returns 0, $_pra_w" "$_pra_blk"
  _pra_go "$_pra_d" lib/green-install.sh _gt_class 3 "@$PRA/class.out"
  _pra_is "_gt_class 3 over felix merge output past 256 KB that opens with a receipt-only block prints receipt and a newline, writes nothing on stderr and returns 0, $_pra_w" "receipt$_pra_nl"
done
_pra_go IGNORE lib/green-tick.sh _gt_detail "a
 one space is not two
  the first blocker
b
  a second blocker"
_pra_is "_gt_detail prints the first line that begins with two spaces (control)" "  the first blocker"
_pra_go IGNORE lib/green-tick.sh _gt_detail "first words
last words
$_pra_t
"
_pra_is "_gt_detail with no two-space line prints the last line that holds a non-blank character (control)" "last words"
_pra_go IGNORE lib/green-tick.sh _gt_detail ""
_pra_is "_gt_detail of an empty output prints nothing (control)" ""

# STATUS WANT OUTPUT NAME: _gt_class STATUS OUTPUT prints WANT and a newline.
_pra_cls() { _pra_go IGNORE lib/green-install.sh _gt_class "$1" "$3"; _pra_is "$4" "$2$_pra_nl"; }
_pra_cl="  commission  receipt                stale"
_pra_nt="  not-green   tests                  red"
_pra_es="  escape      write                  notes/x.md: outside the tree"
_pra_bp="  base        provider               unknown"
_pra_go IGNORE lib/green-install.sh _gt_class 1 "not merging

$_pra_cl

closing"
_pra_is "_gt_class prints hourly when STATUS is 1, whatever the block (control)" "hourly"
_pra_go IGNORE lib/green-install.sh _gt_class 4 "not merging

$_pra_es"
_pra_is "_gt_class prints hourly when STATUS is 4, a blocker in the block notwithstanding (control)" "hourly"
_pra_cls 3 receipt "not merging

$_pra_cl

closing" "_gt_class prints receipt for a block of a commission receipt line alone (control)"
_pra_cls 3 hourly "not merging

$_pra_nt
$_pra_cl

closing" "_gt_class prints hourly for a block whose not-green line names tests (control)"
_pra_cls 3 hourly "not merging

  unverified  tests                  red

closing" "_gt_class prints hourly for a block whose unverified line names tests (control)"
_pra_cls 3 receipt "not merging

  not-green   gate                   red

closing" "_gt_class reads a not-green line that does not name tests as setting neither h nor b (control)"
_pra_cls 3 final "not merging

$_pra_nt
$_pra_es

closing" "_gt_class prints final for a block that holds any other blocker (control)"
_pra_cls 3 hourly "not merging

$_pra_bp

closing" "_gt_class prints hourly for a block of a base provider line alone (control)"
_pra_cls 3 final "not merging

$_pra_bp
$_pra_cl

closing" "_gt_class prints final for a base provider line beside another line (control)"
_pra_cls 3 receipt "not merging

$_pra_cl

$_pra_es
$_pra_bp" "_gt_class does not read the lines after the block's closing empty line (control)"
_pra_cls 3 receipt "not merging

$_pra_cl

not merging

$_pra_es

closing" "_gt_class does not read a second not merging and its block (control)"
_pra_cls 3 receipt "not merging
$_pra_cl

$_pra_es" "_gt_class reads a block that starts on the line after not merging when that line is not empty (control)"
_pra_cls 3 final "not merging


$_pra_cl" "_gt_class prints final for an empty block, and reads nothing after it (control)"
_pra_cls 3 final "  not merging
$_pra_cl" "_gt_class prints final when no line is exactly not merging (control)"

# PR4, the lint (its matcher, samples, allowance and scan), is part 2501-pipe-readers-lint-blind.sh since rev 3.
unset -f _pra_go _pra_is _pra_big _pra_size _pra_cls
# <<< pipe-readers-read-to-the-end
