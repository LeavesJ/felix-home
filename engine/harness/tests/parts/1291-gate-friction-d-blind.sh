# >>> gate-friction-d-blind
printf '\ngate friction D: the parallel runner, part mode, groups and slots (blind, author 1)\n'
# Blind, written on 2026-10-18 from contract D alone (docs/2026-10-18-gate-
# friction-contract-d.md, D1 to D6 and D8) before any of it was built. Nothing
# here was read off an implementation; tests/run, tests/red and tests/receipt.sh
# are run, never read, in copies of this suite that _suite_copy_tree (part 0003)
# makes under $TMP, each with planted parts of this block's own. Every case
# points TMPDIR at a fixture directory, so none touches the machine's slots.
# Names say the clause: D1 the interface, D2 a unit and part mode, D3 the log
# and the verdict, D4 the record, red, the receipt and the durations, D5
# groups, D6 the runner (signals, slots, holders), D8 the fixtures.
#
# Readings taken where the contract leaves room, for author 2 to confirm:
# - a runner failure's FAIL line is matched by its prefix and the unit after it,
#   a refusal by its exit status (2), one stderr line and no $TMP made (a
#   mktemp on PATH that writes down its calls), and "its line" by that line
#   differing from rule to rule;
# - a FELIX_TEST_JOBS that is invalid beside a valid -j, an empty one, and a
#   groups.tsv member the driver does not source, are not asked;
# - the unit killed after its last member is made by a part that redefines
#   _og_check, which D2 step 4 says the end state calls;
# - _suite_copy_tree copies part 0007 where the tree has one, so the controls
#   run before D is built: against that tree -j is not understood and every
#   run below is a serial one.
# An assertion whose name ends in (control) passes before D is built on
# purpose: it pins what makes the others mean something.
DB1="$TMP/db1"; DB1K="${DB1#/private}"
mkdir -p "$DB1/pp/std" "$DB1/pp/ref" "$DB1/n" "$DB1/shim"
_db1_E=(); _db1_INT=DEFAULT; _db1_QUIT=DEFAULT; _db1_td=""; _db1_ctl=0; _db1_ctlr=0
cat > "$DB1/run.pl" <<'DB1PL'
my ($t, $i, $q, $f) = splice(@ARGV, 0, 4);
my $p = fork; defined $p or exit 125;
if (!$p) { setpgrp(0, 0); $SIG{INT} = $i; $SIG{QUIT} = $q; if (open(my $h, ">", $f)) { print $h "$$\n"; close $h } exec @ARGV; exit 127 }
$SIG{ALRM} = sub { kill "KILL", -$p; exit 124 };
alarm $t; waitpid $p, 0;
exit(($? & 127) ? 128 + ($? & 127) : $? >> 8);
DB1PL
printf '#!/bin/sh\nprintf "x\\n" >> "$DJX_DIR/mktemp.log"\nexec "%s" "$@"\n' "$(command -v mktemp)" > "$DB1/shim/mktemp"; chmod +x "$DB1/shim/mktemp"
: > "$DB1/g-empty.tsv"; printf '1\tdjx a1\n' > "$DB1/man.tsv"
_db1_until() { local n="$1" i=0; shift; while [ "$i" -lt "$n" ]; do "$@" && return 0; sleep 0.2; i=$((i + 1)); done; "$@"; }
_db1_cnt()  { LC_ALL=C awk -v p="$2" 'index($0, p) == 1 { n++ } END { print n + 0 }' "$1" 2>/dev/null; }   # FILE PREFIX: lines starting with it
_db1_line() { grep -cxF -e "$2" "$1" 2>/dev/null; }   # FILE LINE: lines that are exactly it
_db1_seen() { [ "$(_db1_line "$1" "$2")" != 0 ]; }
_db1_ps()  { ps -A -o pid= -o command= 2>/dev/null | K="$1" LC_ALL=C awk 'index($0, ENVIRON["K"]) { printf "%s ", $1 }'; }   # pids whose command line holds K
_db1_ps2() { ps -A -o pid= -o command= 2>/dev/null | K="$1" L="$2" LC_ALL=C awk 'index($0, ENVIRON["K"]) && index($0, ENVIRON["L"]) { printf "%s ", $1 }'; }
_db1_alive() { local p; p="$(cat "$1" 2>/dev/null)"; [ -n "$p" ] || return 1; case "$(ps -p "$p" -o command= 2>/dev/null)" in *"$2"*) kill -KILL "$p" 2>/dev/null; return 0 ;; esac; return 1; }   # FILE MARK
_db1_slots() { perl -e 'use Fcntl ":flock"; for my $f (glob "$ARGV[0]/felix-suite-slots/*") { open(my $h, "<", $f) or next; print "$f " unless flock($h, LOCK_EX | LOCK_NB); close $h }' "$1"; }
_db1_hold() {   # SLOTFILE SECONDS: this process holds the lock on the file for that long; _db1_hp is its pid
  mkdir -p "${1%/*}"
  perl -e 'use Fcntl ":flock"; open(my $h, ">>", $ARGV[0]) or exit 4; flock($h, LOCK_EX | LOCK_NB) or exit 3; $| = 1; print "held\n"; sleep $ARGV[1]' "$1" "$2" > "$_db1_c/hold.out" 2>&1 &
  _db1_hp=$!; _db1_until 100 test -s "$_db1_c/hold.out"
}
_db1_unhold() { kill -KILL "$_db1_hp" 2>/dev/null; { wait "$_db1_hp"; } 2>/dev/null; return 0; }
_db1_cores() { local n; n="$(sysctl -n hw.ncpu 2>/dev/null)"; case "$n" in ''|*[!0-9]*) n="$(getconf _NPROCESSORS_ONLN 2>/dev/null)" ;; esac
  case "$n" in ''|*[!0-9]*) n=1 ;; esac; [ "$n" -ge 1 ] || n=1; [ "$n" -le 64 ] || n=64; printf '%s' "$n"; }
# CASE [--red] GROUPS MANIFEST STUB...: the copy at $DB1/n/CASE (_db1_F, _db1_T, _db1_c, _db1_tmp); 1 when it could not be made
_db1_new() {
  local n="$1" r=""; shift
  [ "${1:-}" != --red ] || { r=--red; shift; }
  _db1_c="$DB1/n/$n"; _db1_F="$_db1_c/f"; _db1_T="$_db1_F/engine/harness/tests"; _db1_tmp="$_db1_c/tmp"
  rm -rf "$_db1_c"; mkdir -p "$_db1_tmp" || return 1
  _suite_copy_tree ${r:+"$r"} "$_db1_F" "$@"
}
# LABEL ARG...: the copy's driver run in the background under a bounded runner (INT and QUIT as _db1_INT and _db1_QUIT);
# stdout $_db1_c/LABEL.out, stderr LABEL.err, the driver's pid LABEL.pid; _db1_bg is the runner's pid
_db1_start() {
  local l="$1"; shift
  ( cd "$_db1_F" && exec env -u FELIX_TEST_NO_MANIFEST -u FELIX_TEST_JOBS -u FELIX_TEST_SLOTS -u FELIX_TEST_PART_LOG \
      -u FELIX_TEST_PART_RAN -u FELIX_TEST_PART_END -u FELIX_TEST_PART_RECORD -u PERL5OPT \
      TMPDIR="${_db1_td:-$_db1_tmp}" FELIX_TEST_SLOTS=8 DJX_DIR="$_db1_c" DJX_PL="$DB1" DJX_ID="${TMP##*/}-${_db1_c##*/}" ${_db1_E[@]+"${_db1_E[@]}"} \
      perl "$DB1/run.pl" "${_db1_lim:-150}" "$_db1_INT" "$_db1_QUIT" "$_db1_c/$l.pid" "$BASH" "$_db1_T/run" "$@" \
  ) > "$_db1_c/$l.out" 2> "$_db1_c/$l.err" &
  _db1_bg=$!
}
_db1_wait() { { wait "$_db1_bg"; } 2>/dev/null; _db1_rc=$?; _db1_E=(); _db1_INT=DEFAULT; _db1_QUIT=DEFAULT; }
_db1_run() { _db1_start "$@"; _db1_wait; }
_db1_rcpt() { if [ -f "$_db1_F/.git/felix-suite-receipt" ]; then echo present; else echo absent; fi; }
_db1_last() { tail -n 1 "$_db1_c/$1.out" 2>/dev/null; }
_db1_vl() { grep -E '^  (ok    |FAIL  |skip  )' "$1" 2>/dev/null | LC_ALL=C sort; }
_db1_same() { local d; d="$(LC_ALL=C diff <(_db1_vl "$1") <(_db1_vl "$2") | head -4 | tr '\n' '|')"; printf '%s' "${d:-same}"; }
_db1_sum() { local s="$1"; s="${s% (counted from lines)}"; s="${s% (reused)}"; printf '%s' "$s"; }
_db1_redrows() { if [ -f "$_db1_T/red.tsv" ]; then grep -v '^#' "$_db1_T/red.tsv" | tr '\n' '|'; else printf '(no red.tsv)'; fi; }
_db1_cnts() { case "$(_db1_redrows)" in base$'\t'origin/main$'\t'*$'\t'0.0.1\|run$'\t'0$'\t'[0-9]*$'\t'[0-9]*\|) echo counts ;; *) _db1_redrows ;; esac; }
_db1_nored() { [ -z "$(_db1_ps "${_db1_c#/private}/f/engine/harness/tests/red")" ]; }
# The standard planted parts: three that pass, 0010-pa.sh, 0020-pb.sh and 0030-pc.sh, in pp/std.
_db1_snip='printf "djx-redjobs:%s\n" "${FELIX_TEST_RED_JOBS-unset}"
[ "${FELIX_TEST_NO_MANIFEST:-0}" != 1 ] || printf "%s\n" "$$" >> "$DJX_DIR/redpids"'
_db1_std() { local f="$1" s="$2" a; shift 2; { printf 'printf "\\ndjx-sec %s\\n"\n%s\n' "$s" "$_db1_snip"; for a in "$@"; do printf '%s\n' "$a"; done; } > "$f"; }
_db1_std "$DB1/pp/std/0010-pa.sh" 0010-pa.sh 'ok "djx a1"' 'ok "djx a2"'
_db1_std "$DB1/pp/std/0020-pb.sh" 0020-pb.sh 'ok "djx b1"' 'ok "djx b2"'
_db1_std "$DB1/pp/std/0030-pc.sh" 0030-pc.sh 'ok "djx c1"' 'skip "djx c skip" "a reason"'
_db1_mk() {   # CASE [FILE]: pp/CASE holds 0010-pa.sh, 0030-pc.sh and the part read from stdin (default 0020-pb.sh)
  local d="$DB1/pp/$1"; mkdir -p "$d" && cp "$DB1/pp/std/0010-pa.sh" "$DB1/pp/std/0030-pc.sh" "$d/" && cat > "$d/${2:-0020-pb.sh}"
}
# A reached summary: "ok" when run $1 reused a receipt and ran no part.
_db1_reuse() { local f="$_db1_c/$1.out" r=""
  [ "$_db1_rc" = 0 ] || r="$r exit $_db1_rc;"; [ "$(_db1_cnt "$f" 'reused the suite run that ended ')" = 1 ] || r="$r no reuse line;"
  [ "$(_db1_cnt "$f" '  ok    ')" = 0 ] || r="$r a part ran;"; case "$(_db1_last "$1")" in *" (reused)") ;; *) r="$r summary [$(_db1_last "$1")];" ;; esac
  printf '%s' "${r:-ok}"; }

# ---- the helper (D8)
_db1_new h "$DB1/g-empty.tsv" "$DB1/man.tsv" "$DB1/pp/std"/*.sh
_db1_g="$(git -C "$_db1_F" rev-parse --abbrev-ref HEAD 2>/dev/null) $(git -C "$_db1_F" rev-list --count HEAD 2>/dev/null) $([ "$(git -C "$_db1_F" rev-parse HEAD 2>/dev/null)" = "$(git -C "$_db1_F" rev-parse refs/remotes/origin/main 2>/dev/null)" ] && echo origin-at-head)"
is "D8: _suite_copy_tree makes a checkout on main with one commit and refs/remotes/origin/main at it (control)" "$_db1_g" "main 1 origin-at-head"
is "D8: and its driver sources every part it holds once, in name order: 0001 to 0006 (0007 where there is one), the stubs, then 9990 (control)" \
   "$(sed -n 's|^\. "\$HERE/parts/\(.*\)"$|\1|p' "$_db1_T/run" | tr '\n' ' ')" "$(cd "$_db1_T/parts" && LC_ALL=C ls | LC_ALL=C sort | tr '\n' ' ')"
_db1_x=""; _suite_copy_tree "$DB1/n/hx" "$DB1/g-empty.tsv" "$DB1/man.tsv" "$DB1/pp/std/0010-pa.sh" "$DB1/nosuch/0020-pb.sh" 2>/dev/null; _db1_x="$?"
for _db1_p in 0005-x.sh 9990-x.sh x.sh; do mkdir -p "$DB1/pp/bad"; : > "$DB1/pp/bad/$_db1_p"; _suite_copy_tree "$DB1/n/hy" "$DB1/g-empty.tsv" "$DB1/man.tsv" "$DB1/pp/bad/$_db1_p" 2>/dev/null; _db1_x="$_db1_x $?"; done
_suite_copy_tree "$DB1/n/hz" "$DB1/g-empty.tsv" "$DB1/man.tsv" "$DB1/pp/std/0010-pa.sh" "$DB1/pp/std/0010-pa.sh" 2>/dev/null; _db1_x="$_db1_x $?"
is "D8: _suite_copy_tree returns 1 for a missing stub, a stub numbered 0005 or 9990, one not named NNNN-name.sh, and a repeated stub" "$_db1_x" "1 1 1 1 1"
is "D8: and leaves no run in the copy when it fails" "$(ls "$DB1/n/hx/engine/harness/tests/run" "$DB1/n/hy/engine/harness/tests/run" "$DB1/n/hz/engine/harness/tests/run" 2>/dev/null | wc -l | tr -d ' ')" "0"

# ---- the positive control: planted passing parts under -j 3 (D8), and -j 1 beside them
_db1_new ctl "$DB1/g-empty.tsv" "$DB1/man.tsv" "$DB1/pp/std"/*.sh
_db1_run c3 -j 3
_db1_r3="$(cat "$_db1_F/.git/felix-suite-receipt" 2>/dev/null)"; _db1_d3="$(cat "$_db1_F/.git/felix-suite-durations" 2>/dev/null)"
[ "$_db1_rc" = 0 ] && [ -n "$_db1_r3" ] && _db1_ctl=1
is "D8: a -j 3 run of planted passing parts exits 0 and leaves a receipt (positive control)" "$_db1_rc $_db1_ctl" "0 1"
_db1_run ru1 --reuse;        is "D4: --reuse accepts the receipt a -j 3 run left, and runs no part" "$(_db1_reuse ru1)" ok
_db1_run ru2 -j 2 --reuse;   is "D1: -j 2 --reuse accepts it as well" "$(_db1_reuse ru2)" ok
_db1_run ru3 --reuse -j 2;   is "D1: and --reuse -j 2, in the other order" "$(_db1_reuse ru3)" ok
_db1_run c1 -j 1
_db1_r1="$(cat "$_db1_F/.git/felix-suite-receipt" 2>/dev/null)"
_db1_run ru4 -j 3 --reuse;   is "D4: and -j 3 --reuse accepts the receipt a -j 1 run left" "$(_db1_reuse ru4)" ok
_db1_s1="$(_db1_last c1)"; _db1_s3="$(_db1_last c3)"
is "D3: the summary of a -j 3 run is the -j 1 summary and ends (counted from lines), which -j 1's does not" \
   "$(_db1_sum "$_db1_s3") | $_db1_s3 | $_db1_s1" "$_db1_s1 | $_db1_s1 (counted from lines) | $_db1_s1"
is "D3: a -j 3 run gives the (verdict, name) lines a -j 1 run gives" "$(_db1_same "$_db1_c/c3.out" "$_db1_c/c1.out")" "same"
is "D3: and prints the part sections in the same order" \
   "$(grep '^djx-sec ' "$_db1_c/c3.out" | tr '\n' ' ')" "$(grep '^djx-sec ' "$_db1_c/c1.out" | tr '\n' ' ')"
_db1_k="$(printf '%s' "$_db1_s1" | awk '{ print $1, $3 + 0, ($6 == "skipped" ? $5 : 0) }')"
is "D4: the receipt a -j 3 run leaves is one v1 line of nine fields, mode normal, with the summary's counts" \
   "$(printf '%s\n' "$_db1_r3" | awk -F'\t' 'END { print NR, NF, $1, $3, $4, $5, $6 }') | $(printf '%s\n' "$_db1_r1" | awk -F'\t' '{ print $3, $4, $5, $6 }')" \
   "1 9 v1 normal $_db1_k | normal $_db1_k"
is "D4: a -j 3 run writes durations, one line a unit: whole seconds, a tab, the unit's name" \
   "$(printf '%s\n' "$_db1_d3" | awk -F'\t' '$1 ~ /^(0|[1-9][0-9]*)$/ { print $2 }' | LC_ALL=C sort | tr '\n' ' ')" "0010-pa.sh 0020-pb.sh 0030-pc.sh "

# ---- the record control (D4): a --red copy writes the manifest and red.tsv, serially and under -j 3, and the manifest is the same
_db1_new rc --red "$DB1/g-empty.tsv" "$DB1/man.tsv" "$DB1/pp/std"/*.sh
_db1_run r1 --record-assertions
_db1_m1="$(cat "$_db1_T/assertions.tsv")"; _db1_ctlr=0
case "$_db1_rc|$(_db1_redrows)" in
  0\|base$'\t'origin/main$'\t'*$'\t'0.0.1\|run$'\t'0$'\t'[0-9]*$'\t'[0-9]*\|) cmp -s "$DB1/man.tsv" "$_db1_T/assertions.tsv" || _db1_ctlr=1 ;;
esac
is "D8: a record run in a --red copy of planted passing parts exits 0, rewrites the manifest and leaves red.tsv with counts (positive control)" "$_db1_ctlr" 1
cp "$DB1/man.tsv" "$_db1_T/assertions.tsv"; rm -f "$_db1_c/redpids"; _db1_run r3 -j 3 --record-assertions
_db1_m3="$(cat "$_db1_T/assertions.tsv")"
is "D4: a -j 3 record run exits 0, writes the manifest a serial one writes on the same tree, byte for byte, and leaves red.tsv with counts" \
   "$_db1_rc $([ "$_db1_m3" = "$_db1_m1" ] && echo same || echo differ) $(_db1_cnts)" "0 same counts"
is "D4: red's suite ran under -j 3 (FELIX_TEST_RED_JOBS): its three units were three processes" "$(LC_ALL=C sort -u "$_db1_c/redpids" 2>/dev/null | wc -l | tr -d ' ')" 3
is "D4: and no FELIX_TEST_RED_JOBS reaches a part (control)" "$(grep '^djx-redjobs:' "$_db1_c/r3.out" | LC_ALL=C sort -u | tr '\n' ' ')" "djx-redjobs:unset "
cp "$DB1/man.tsv" "$_db1_T/assertions.tsv"; _db1_run r3b --record-assertions -j 3
is "D1: --record-assertions -j 3, in the other order, exits 0 and records the same manifest" "$_db1_rc $([ "$(cat "$_db1_T/assertions.tsv")" = "$_db1_m1" ] && echo same || echo differ)" "0 same"
_db1_s3="$(_db1_last r3)"
is "D4: a -j 3 record run prints no record judge in this suite, as it did, and its summary ends (counted from lines)" \
   "$(_db1_line "$_db1_c/r3.out" '  no record judge in this suite: the record is not re-judged') ${_db1_s3##* (}" "1 counted from lines)"
rm -rf "$DB1/n/rc"

# ---- refusals (D1, D5): exit 2 with one stderr line, before $TMP is made
for _db1_i in 1 2 3 4 5 6 7; do printf 'ok "djx r%s"\n' "$_db1_i" > "$DB1/pp/ref/00${_db1_i}0-r$_db1_i.sh"; done
_db1_new ref "$DB1/g-empty.tsv" - "$DB1/pp/ref"/*.sh
_db1_gp="$_db1_T/groups.tsv"; _db1_X=(); _db1_w=""; _db1_els=""
_db1_ref() {   # ARG...: run the copy's driver with them under a mktemp that writes down its calls; _db1_v is ok when it refused as D1 says
  local r="" n
  rm -f "$_db1_c/mktemp.log"; _db1_E=(PATH="$DB1/shim:$PATH" ${_db1_X[@]+"${_db1_X[@]}"}); _db1_X=()
  _db1_run ref "$@"
  n="$(awk 'END { print NR }' "$_db1_c/ref.err")"
  [ "$_db1_rc" = 2 ] || r="$r exit $_db1_rc, not 2;"
  [ "$n" = 1 ] || r="$r $n stderr lines, not 1;"
  [ ! -s "$_db1_c/mktemp.log" ] || r="$r a temporary directory was made;"
  _db1_v="${r:-ok}"; _db1_el="$(sed -n 1p "$_db1_c/ref.err")"
}
_db1_acc() {   # ARG...: the run is accepted (exit 0) and made its temporary directory, so the shim saw it
  local r=""
  rm -f "$_db1_c/mktemp.log"; _db1_E=(PATH="$DB1/shim:$PATH"); _db1_run ref "$@"
  [ "$_db1_rc" = 0 ] || r="$r exit $_db1_rc, not 0;"; [ -s "$_db1_c/mktemp.log" ] || r="$r no temporary directory was made;"
  _db1_v="${r:-ok}"
}
_db1_refs() {   # LABEL ARGS-LIST...: each list, split on blanks, is refused; _db1_w names the ones that were not
  local l="$1" a; shift
  _db1_w=""; for a in "$@"; do _db1_ref $a; [ "$_db1_v" = ok ] || _db1_w="$_db1_w [$a]$_db1_v"; done
}
_db1_refs j '-j' '-j3' '-j 2 -j 3'
is "D1: -j with no N, -jN as one word and a second -j are each refused: exit 2, one stderr line, no \$TMP made" "${_db1_w:-ok}" ok
_db1_w=""; for _db1_a in 0 65 007 +2 -2 x 2x ''; do _db1_ref -j "$_db1_a"; [ "$_db1_v" = ok ] || _db1_w="$_db1_w [-j $_db1_a]$_db1_v"; done
is "D1: an N that is not 1 to 64 in plain decimal (0 65 007 +2 -2 x 2x and empty) is refused the same way" "${_db1_w:-ok}" ok
_db1_w=""; for _db1_a in 0 65 abc 03 -1; do _db1_X=(FELIX_TEST_JOBS="$_db1_a"); _db1_ref; [ "$_db1_v" = ok ] || _db1_w="$_db1_w [$_db1_a]$_db1_v"; done
is "D1: a FELIX_TEST_JOBS that is not a valid N (0 65 abc 03 -1) is refused the same way" "${_db1_w:-ok}" ok
_db1_p1="$(cd "$_db1_T/parts" && ls 0001-*.sh)"; _db1_p6="$(cd "$_db1_T/parts" && ls 0006-*.sh)"; _db1_p9="$(cd "$_db1_T/parts" && ls 9990-*.sh)"
_db1_refs p "--part 0010-nosuch.sh" "--part $_db1_p1" "--part $_db1_p6" "--part $_db1_p9" "--part 0020-r2.sh 0010-r1.sh" "--part 0010-r1.sh 0030-r3.sh" \
   "--part 0010-r1.sh 0020-r2.sh 0030-r3.sh 0040-r4.sh 0050-r5.sh 0060-r6.sh 0070-r7.sh" "--part"
is "D1: --part refuses a name the driver does not source, a prelude part, 9990, names out of order or not contiguous, seven names and none" "${_db1_w:-ok}" ok
_db1_refs q "--part 0010-r1.sh -j 2" "-j 2 --part 0010-r1.sh" "--part 0010-r1.sh --record-assertions" "--part 0010-r1.sh --reuse"
is "D1: --part with -j, --record-assertions or --reuse is refused" "${_db1_w:-ok}" ok
_db1_run ref -j 3 --reuse --record-assertions
is "D1: --reuse with --record-assertions is refused with -j given, with the text it had" "$_db1_rc|$(sed -n 1p "$_db1_c/ref.err")" "2|tests/run: --reuse and --record-assertions do not go together"
# groups.tsv (D5): each rule refuses with its own line
_db1_gcase() {   # LABEL FORMAT ARG...: groups.tsv is the printf of the format; -j 2 must be refused
  local l="$1" f="$2"; shift 2
  printf "$f" "$@" > "$_db1_gp"; _db1_ref -j 2
  [ "$_db1_v" = ok ] || _db1_w="$_db1_w $l:$_db1_v"
  _db1_els="$_db1_els$_db1_el"$'\n'
}
_db1_p2="$(cd "$_db1_T/parts" && ls 0002-*.sh)"; _db1_w=""; _db1_els=""
_db1_gcase adjacent 'ga\t0010-r1.sh\ngb\t0030-r3.sh\ngb\t0040-r4.sh\nga\t0020-r2.sh\n'
_db1_gcase contiguous 'ga\t0010-r1.sh\nga\t0030-r3.sh\n'
_db1_gcase one-member 'ga\t0010-r1.sh\n'
_db1_gcase two-groups 'ga\t0010-r1.sh\nga\t0020-r2.sh\ngb\t0020-r2.sh\ngb\t0030-r3.sh\n'
_db1_gcase prelude 'ga\t%s\nga\t%s\n' "$_db1_p1" "$_db1_p2"
_db1_five="$_db1_els"; _db1_els=""
_db1_gcase seven 'ga\t0010-r1.sh\nga\t0020-r2.sh\nga\t0030-r3.sh\nga\t0040-r4.sh\nga\t0050-r5.sh\nga\t0060-r6.sh\nga\t0070-r7.sh\n'
_db1_gcase last 'ga\t0070-r7.sh\nga\t%s\n' "$_db1_p9"
_db1_gcase no-tab 'ga 0010-r1.sh\nga 0020-r2.sh\n'
is "D5: a groups.tsv whose lines for a group are not adjacent, whose members are not contiguous or number one or seven, that puts a part in two groups, or that names 0001, 0002 or 9990, is refused as D1 says, and so is a line with no tab" "${_db1_w:-ok}" ok
is "D5: the refusals name the rule: five different rules give five different lines" "$(printf '%s' "$_db1_five" | LC_ALL=C sort -u | wc -l | tr -d ' ')" 5
rm -f "$_db1_gp"; _db1_ref -j 2; _db1_w="$_db1_v"
printf 'ga\t0010-r1.sh\nga\t0020-r2.sh\n' > "$_db1_gp"; chmod 000 "$_db1_gp"
if [ -r "$_db1_gp" ]; then _db1_w2=skip; else _db1_ref -j 2; _db1_w2="$_db1_v"; fi
chmod 644 "$_db1_gp"; rm -f "$_db1_gp"; mkdir "$_db1_gp"; _db1_ref -j 2; _db1_w3="$_db1_v"; rmdir "$_db1_gp"
is "D1: with N above 1 a groups.tsv that is missing, or a directory, is refused as D1 says" "$_db1_w $_db1_w3" "ok ok"
if [ "$_db1_w2" = skip ]; then skip "D1: with N above 1 an unreadable groups.tsv is refused as D1 says" "a mode 000 file is still readable by this user"
else is "D1: with N above 1 an unreadable groups.tsv is refused as D1 says" "$_db1_w2" ok; fi
printf '# a comment\nga\t0010-r1.sh\nga\t0020-r2.sh\n# another\n' > "$_db1_gp"; _db1_acc -j 2
is "D5: a groups.tsv with comment lines and one valid group is accepted" "$_db1_v" ok
printf 'ga\t0010-r1.sh\n' > "$_db1_gp"; _db1_acc -j 1; _db1_w="$_db1_v"; rm -f "$_db1_gp"; _db1_acc -j 1
is "D1: -j 1 does not read groups.tsv: a broken one and a missing one change nothing" "$_db1_w $_db1_v" "ok ok"
rm -rf "$DB1/n/ref"

# ---- what the suite's own text says (D1, D3, D5)
_db1_n=_suite_; _db1_n="${_db1_n}jobs"
_db1_jobs() {   # the places outside 0001 that name the jobs variable other than in an expansion, file:line
  local f
  while IFS= read -r f; do
    case "${f##*/}" in 0001-*) continue ;; esac
    LC_ALL=C awk -v n="$_db1_n" -v f="${f##*/}" '{ l = $0; gsub("[$][{]?" n, "", l); if (index(l, n)) printf "%s:%s ", f, FNR }' "$f"
  done < <(_suite_files)
}
_db1_x="$(_db1_jobs)"
is "D1: no file of the suite other than 0001 names the jobs variable except in a \$ or \${ expansion" "$_db1_x" ""
is "D1: and 0001 sets it, at its head, before it makes \$TMP" \
   "$(LC_ALL=C awk -v n="$_db1_n" '{ l = $0; gsub("[$][{]?" n, "", l) } !a && index(l, n) { a = FNR } !t && index($0, "mktemp -d") { t = FNR } END { print (a && t && a < t) ? "before" : "a=" a " mktemp=" t }' "$HERE"/parts/0001-*.sh)" "before"
_db1_pre=("part's prelude failed: " "part did not finish: " "part ended without its mark: " "part process ended with status " "part failed more than it printed: " "part printed a line the runner owns: ")
_db1_pfx() {   # MANIFEST: the runner-failure prefixes some name in it starts with, one a line
  local p; for p in "${_db1_pre[@]}"; do LC_ALL=C awk -v p="$p" '{ i = index($0, "\t"); if (i && index(substr($0, i + 1), p) == 1) { print p; exit } }' "$1"; done
}
for _db1_p in "${_db1_pre[@]}"; do printf '1\t%sX\n' "$_db1_p"; done > "$DB1/planted.tsv"
is "D3: the check for runner-failure prefixes in a manifest reads six planted names as six hits (control)" "$(_db1_pfx "$DB1/planted.tsv" | wc -l | tr -d ' ')" 6
is "D3: no name in the manifest starts with one of the runner's six failure prefixes" "$(_db1_pfx "$HERE/assertions.tsv" | wc -l | tr -d ' ')" 0
_db1_rg="$HERE/groups.tsv"; _db1_ib=""
for _db1_a in 0900 0910 0920 0930 0940; do
  _db1_f="$(cd "$HERE/parts" && ls "$_db1_a"-*.sh 2>/dev/null | sed -n 1p)"
  _db1_ib="$_db1_ib$(awk -F'\t' -v p="$_db1_f" '/^#/ { next } $2 == p { print $1; exit }' "$_db1_rg" 2>/dev/null) "
done
is "D5: the tree's own groups.tsv puts 0900, 0910, 0920, 0930 and 0940 in one group" \
   "$(set -- $_db1_ib; a="${1:-}"; n=$#; for x in "$@"; do [ "$x" = "$a" ] || n=0; done; echo "$n parts in one group")" "5 parts in one group"
is "D5: and that group is ib" "${_db1_ib%% *}" ib
mkdir -p "$DB1/pp/real"
while IFS= read -r _db1_f; do [ -f "$HERE/parts/$_db1_f" ] && printf 'ok "djx stand-in %s"\n' "$_db1_f" > "$DB1/pp/real/$_db1_f"
done < <(awk -F'\t' '!/^#/ && NF >= 2 { print $2 }' "$_db1_rg" 2>/dev/null | LC_ALL=C sort -u)
if _db1_new real "$_db1_rg" - "$DB1/pp/real"/*.sh; then
  _db1_run real -j 2; is "D5: the tree's own groups.tsv is accepted by the driver, with stand-ins for the parts it names" "$_db1_rc $(awk 'END { print NR }' "$_db1_c/real.err")" "0 0"
else bad "D5: the tree's own groups.tsv is accepted by the driver, with stand-ins for the parts it names" "no copy: is there an engine/harness/tests/groups.tsv naming parts of this suite?"; fi
rm -rf "$DB1/n/real"

# ---- a group runs as one process (D2, D5): A and B each write a file below $TMP, C counts them
mkdir -p "$DB1/pp/grp"
printf '%s\n' 'printf "\ndjx-sec 0010-ga.sh\n"' 'printf "djx-jobs:%s\n" "${FELIX_TEST_JOBS-unset}"' \
  'mkdir -p "$TMP/djx-g"; : > "$TMP/djx-g/a"; printf "%s\n" "$$" > "$DJX_DIR/pid.a"' > "$DB1/pp/grp/0010-ga.sh"
printf '%s\n' 'printf "\ndjx-sec 0020-gb.sh\n"' 'mkdir -p "$TMP/djx-g"; : > "$TMP/djx-g/b"; printf "%s\n" "$$" > "$DJX_DIR/pid.b"' > "$DB1/pp/grp/0020-gb.sh"
printf '%s\n' 'printf "\ndjx-sec 0030-gc.sh\n"' 'printf "%s\n" "$$" > "$DJX_DIR/pid.c"' '_n="$(ls "$TMP/djx-g" 2>/dev/null | wc -l | tr -d " ")"' \
  '[ "$_n" = 2 ] && ok "djx group C sees the files of A and B" || bad "djx group C sees the files of A and B" "the directory holds $_n files"' > "$DB1/pp/grp/0030-gc.sh"
printf 'grp\t0010-ga.sh\ngrp\t0020-gb.sh\ngrp\t0030-gc.sh\n' > "$DB1/g-grp.tsv"
_db1_pids() { cat "$_db1_c"/pid.? 2>/dev/null | LC_ALL=C sort -u | wc -l | tr -d ' '; }
_db1_gc="  ok    djx group C sees the files of A and B"; _db1_gf="  FAIL  djx group C sees the files of A and B"
_db1_new grp "$DB1/g-grp.tsv" - "$DB1/pp/grp"/*.sh
rm -f "$_db1_c"/pid.?; _db1_run g1 -j 3
is "D2: a group runs as one process: with A, B and C in a group, -j 3 passes C, and the three parts had one process id" \
   "$_db1_rc $(_db1_line "$_db1_c/g1.out" "$_db1_gc") $(_db1_pids) $(_db1_last g1 | grep -c ' (counted from lines)$')" "0 1 1 1"
is "D4: and the durations name the group once, and not its members" "$(awk -F'\t' '{ print $2 }' "$_db1_F/.git/felix-suite-durations" 2>/dev/null | tr '\n' ' ')" "grp "
cp "$DB1/g-empty.tsv" "$_db1_T/groups.tsv"; rm -f "$_db1_c"/pid.?; _db1_run g2 -j 3
is "D2: with no groups line the same three parts are three units: -j 3 fails C, in three processes" \
   "$_db1_rc $(_db1_line "$_db1_c/g2.out" "$_db1_gf") $(_db1_pids)" "1 1 3"
rm -f "$_db1_c"/pid.?; _db1_E=(FELIX_TEST_JOBS=3); _db1_run g3
is "D1: FELIX_TEST_JOBS=3 with no -j makes a -j 3 run (C fails), and no part sees the variable" \
   "$_db1_rc $(_db1_line "$_db1_c/g3.out" "$_db1_gf") $(_db1_line "$_db1_c/g3.out" djx-jobs:unset)" "1 1 1"
_db1_E=(FELIX_TEST_JOBS=3); _db1_run g4 -j 1
is "D1: and -j 1 beats it: C passes" "$_db1_rc $(_db1_line "$_db1_c/g4.out" "$_db1_gc")" "0 1"
rm -rf "$DB1/n/grp"
_db1_new grr --red "$DB1/g-empty.tsv" - "$DB1/pp/grp"/*.sh; cp "$DB1/g-grp.tsv" "$_db1_T/groups.tsv"; _db1_run gr -j 3 --record-assertions
case "$_db1_rc|$(_db1_redrows)" in 0\|*'run'$'\t'0$'\t'*) _db1_x=ok ;; *) _db1_x="exit $_db1_rc, red.tsv $(_db1_redrows)" ;; esac
is "D4: red's suite takes this tree's groups.tsv, not the base's: with the group only in the working tree red.tsv counts no failure" "$_db1_x" ok
rm -rf "$DB1/n/grr"

# ---- the runner's own failures (D3), and what they do to a record run (D4)
_db1_hook=""; _db1_post=""; _db1_nr=""
# LABEL EXPECT...: "ok", or what differed, for the run LABEL just made: exit 1; each EXPECT a FAIL line printed once ("!X": never; "@F": the file F there;
# "#N": N failures in the summary, where there is one; else as many as the log has "  FAIL  " lines); no receipt, and a control that shows a passing run leaves one
_db1_chk() {
  local l="$1" e c r="" np=0 wf="" s; shift
  [ "$_db1_rc" = 1 ] || r="$r exit $_db1_rc, not 1;"
  for e in "$@"; do
    case "$e" in
      @*) [ -e "$_db1_c/${e#@}" ] || r="$r no witness ${e#@};" ;;
      \#*) wf="${e#\#}" ;;
      !*) c="$(_db1_cnt "$_db1_c/$l.out" "  FAIL  ${e#!}")"; [ "$c" = 0 ] || r="$r [${e#!}] printed $c times;" ;;
      *) np=$((np + 1)); c="$(_db1_cnt "$_db1_c/$l.out" "  FAIL  $e")"; [ "$c" = 1 ] || r="$r [$e] printed $c times;" ;;
    esac
  done
  s="$(_db1_last "$l")"; [ -n "$wf" ] || wf="$(_db1_cnt "$_db1_c/$l.out" '  FAIL  ')"
  case "$s" in *" passed, "*" failed"*) s="${s#* passed, }"; s="${s%% failed*}"; [ "$s" = "$wf" ] || r="$r summary counts $s failed, not $wf;" ;; esac
  [ "$_db1_ctl" = 1 ] || r="$r the control left no receipt, so a missing one says nothing;"
  [ "$(_db1_rcpt)" = absent ] || r="$r a receipt was left;"
  printf '%s' "${r:-ok}"
}
# LABEL EXPECT...: _db1_chk for a record run, and the manifest as it was, and red.tsv the two retraction rows once red has gone
_db1_chkr() {
  local r; r="$(_db1_chk "$@")"; [ "$r" != ok ] || r=""
  _db1_until 300 _db1_nored || r="$r red was still running;"
  cmp -s "$DB1/man.tsv" "$_db1_T/assertions.tsv" || r="$r the manifest was rewritten;"
  [ -n "$_db1_nr" ] || [ "$(_db1_redrows)" = "$(printf 'base\t-\t-\t-|run\t-\t-\t-|')" ] || r="$r red.tsv holds [$(_db1_redrows)];"
  [ "$_db1_ctlr" = 1 ] || r="$r the record control wrote no manifest and no counts, so their absence says nothing;"
  printf '%s' "${r:-ok}"
}
_db1_rf() {   # CASE GROUPS DESC EXPECT...: pp/CASE under -j 3, then under -j 3 --record-assertions in a --red copy
  local n="$1" g="$2" d="$3"; shift 3
  if _db1_new "$n" "$g" - "$DB1/pp/$n"/*.sh; then
    [ -z "$_db1_hook" ] || "$_db1_hook"
    _db1_run p -j 3
    is "D3: $d fails with its runner line, exits 1 and leaves no receipt" "$(_db1_chk p "$@")" ok
    [ -z "$_db1_post" ] || "$_db1_post"
  else bad "D3: $d fails with its runner line, exits 1 and leaves no receipt" "the copy could not be made"; fi
  rm -rf "$DB1/n/$n"
  if _db1_new "$n-r" --red "$g" "$DB1/man.tsv" "$DB1/pp/$n"/*.sh; then
    [ -z "$_db1_hook" ] || "$_db1_hook"
    _db1_run r -j 3 --record-assertions
    is "D4: $d in a record run writes no manifest$([ -n "$_db1_nr" ] || echo ', and red.tsv holds the rows base - - - and run - - -')" "$(_db1_chkr r "$@")" ok
  else bad "D4: $d in a record run writes no manifest" "the copy could not be made"; fi
  rm -rf "$DB1/n/$n-r"; _db1_hook=""; _db1_post=""; _db1_nr=""
}
_db1_mk kill9 <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx kill9 before"
kill -9 $$
ok "djx kill9 after"
X
_db1_rf kill9 "$DB1/g-empty.tsv" "a unit killed with kill -9 while it runs a member" \
   "part did not finish: 0020-pb.sh" "part ended without its mark: 0020-pb.sh" "!part process ended with status"
_db1_mk lastkill <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx lastkill member"
_og_check() { : > "$DJX_DIR/killed.lastkill"; kill -9 $$; }
X
_db1_rf lastkill "$DB1/g-empty.tsv" "a unit killed after its last member and before its mark" \
   "part ended without its mark: 0020-pb.sh" "!part did not finish" "!part process ended with status" "@killed.lastkill"
_db1_mk exit0 <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx exit0 before"
exit 0
X
_db1_rf exit0 "$DB1/g-empty.tsv" "a part that runs exit 0" "part did not finish: 0020-pb.sh" "part ended without its mark: 0020-pb.sh"
_db1_mk setu <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx setu before"
: "$djx_unbound_variable_zz"
ok "djx setu after"
X
_db1_rf setu "$DB1/g-empty.tsv" "a part that dies on an unbound variable under set -u" "part did not finish: 0020-pb.sh" "part ended without its mark: 0020-pb.sh"
_db1_mk reached <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx reached"
printf 'reached\n'
X
_db1_rf reached "$DB1/g-empty.tsv" "a part that prints reached" "part printed a line the runner owns: 0020-pb.sh" "!part did not finish" "!part ended without its mark"
_db1_mk forged <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
printf '@@prelude-done\n'
X
printf '%s\n' 'printf "\ndjx-sec 0030-pc.sh\n"' 'printf "@@member-done 0030-pc.sh\n"' > "$DB1/pp/forged/0030-pc.sh"
printf '%s\n' 'printf "\ndjx-sec 0040-pd.sh\n"' 'printf "@@part-done 0040-pd.sh\n"' > "$DB1/pp/forged/0040-pd.sh"
_db1_rf forged "$DB1/g-empty.tsv" "parts that print a runner line (a second @@prelude-done, a forged @@member-done, a forged @@part-done)" \
   "part printed a line the runner owns: 0020-pb.sh" "part printed a line the runner owns: 0030-pc.sh" "part printed a line the runner owns: 0040-pd.sh" \
   "!part printed a line the runner owns: 0010-pa.sh"
mkdir -p "$DB1/pp/gdie"
printf '%s\n' 'printf "\ndjx-sec 0010-ga.sh\n"' 'ok "djx gdie a"' > "$DB1/pp/gdie/0010-ga.sh"
printf '%s\n' 'printf "\ndjx-sec 0020-gb.sh\n"' 'ok "djx gdie b"' 'kill -9 $$' > "$DB1/pp/gdie/0020-gb.sh"
printf '%s\n' 'printf "\ndjx-sec 0030-gc.sh\n"' 'ok "djx gdie c"' > "$DB1/pp/gdie/0030-gc.sh"
_db1_rf gdie "$DB1/g-grp.tsv" "a group member that dies" "part did not finish: 0020-gb.sh" "part did not finish: 0030-gc.sh" \
   "part ended without its mark: grp" "!part did not finish: 0010-ga.sh"
_db1_mk partial <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
printf 'djx partial text'
bad "djx lands on a partial line"
X
_db1_rf partial "$DB1/g-empty.tsv" "a part whose bad line lands on a partial line" "part failed more than it printed: 0020-pb.sh" "!part did not finish"
_db1_mk trap5 <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx trap5"
trap 'rm -rf "$TMP"; exit 5' EXIT
X
_db1_pt5() { _db1_run t1 -j 1; is "D3: the part that replaces the EXIT trap with one that exits 5 makes a -j 1 run exit 5 (control)" "$_db1_rc" 5; }
_db1_post=_db1_pt5
_db1_rf trap5 "$DB1/g-empty.tsv" "a part that replaces the EXIT trap with one that removes \$TMP and exits 5" \
   "part process ended with status 5: 0020-pb.sh" "!part did not finish" "!part ended without its mark"
_db1_plant6() {   # the copy's 0006 FAILs when a marker file exists, and otherwise makes it
  local f; _db1_nr=1; for f in "$_db1_T"/parts/0006-*.sh; do printf '\nif [ -e "%s" ]; then bad "djx planted prelude failure"; else : > "%s"; fi\n' "$_db1_c/pre.marker" "$_db1_c/pre.marker" >> "$f"; done
}
_db1_pp6() { is "D3: the lines of a failed prelude follow its runner line, each behind two spaces, a bar and a space, so none reads as an assertion" \
  "$(_db1_line "$_db1_c/p.out" '  |   FAIL  djx planted prelude failure') $(_db1_line "$_db1_c/p.out" '  FAIL  djx planted prelude failure')" "3 0"; }
_db1_hook=_db1_plant6; _db1_post=_db1_pp6
mkdir -p "$DB1/pp/pre"; cp "$DB1/pp/std"/*.sh "$DB1/pp/pre/"
_db1_rf pre "$DB1/g-empty.tsv" "a FAIL in the units' prelude only" "part's prelude failed: 0010-pa.sh" "part's prelude failed: 0020-pb.sh" "part's prelude failed: 0030-pc.sh"
# Does a top-level a[1/0]=1 end a sourced file and the rest of the line that sourced it, in this bash? Measured in a child of it.
printf 'echo S1\na[1/0]=1\necho S2\n' > "$DB1/cut.sh"; printf '. "%s"; echo SAMELINE\necho NEXTLINE\n' "$DB1/cut.sh" > "$DB1/cut.drv"
_db1_m="$("$BASH" "$DB1/cut.drv" 2>/dev/null | tr '\n' ' ')"
mkdir -p "$DB1/pp/acut"; printf 'acut\t0010-ka.sh\nacut\t0020-kb.sh\nacut\t0030-kc.sh\n' > "$DB1/g-acut.tsv"
printf '%s\n' 'printf "\ndjx-sec 0010-ka.sh\n"' 'ok "djx acut a"' > "$DB1/pp/acut/0010-ka.sh"
printf '%s\n' 'printf "\ndjx-sec 0020-kb.sh\n"' 'ok "djx acut b before"' 'a[1/0]=1' 'ok "djx acut b after"' > "$DB1/pp/acut/0020-kb.sh"
printf '%s\n' 'printf "\ndjx-sec 0030-kc.sh\n"' 'ok "djx acut c"' > "$DB1/pp/acut/0030-kc.sh"
_db1_pcut() { is "D2: and the member after it ran, as the next part line does in a serial run" \
  "$(_db1_line "$_db1_c/p.out" '  ok    djx acut c') $(_db1_line "$_db1_c/p.out" '  ok    djx acut b after')" "1 0"; }
if [ "$_db1_m" = "S1 NEXTLINE " ]; then
  _db1_post=_db1_pcut
  _db1_rf acut "$DB1/g-acut.tsv" "a member whose sourcing a top-level a[1/0]=1 cuts short, while later members run" \
     "part did not finish: 0020-kb.sh" "!part did not finish: 0010-ka.sh" "!part did not finish: 0030-kc.sh" "!part ended without its mark"
else
  skip "D3: a member whose sourcing a top-level a[1/0]=1 cuts short fails with its runner line, exits 1 and leaves no receipt" "this bash does not end a sourced file and the rest of its line there (it printed [$_db1_m])"
  skip "D4: a member whose sourcing a top-level a[1/0]=1 cuts short, in a record run, writes no manifest, and red.tsv holds the rows base - - - and run - - -" "this bash does not end a sourced file and the rest of its line there"
fi
_db1_mk arith <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx arith before"
x=$((1/0))
ok "djx arith after"
X
_db1_new arith "$DB1/g-empty.tsv" - "$DB1/pp/arith"/*.sh; _db1_run a3 -j 3; _db1_run a1 -j 1
is "D2: a top-level x=\$((1/0)) between two assertions gives the same (verdict, name) lines under -j 3 as under -j 1, the -j 3 run counted from lines" \
   "$(_db1_same "$_db1_c/a3.out" "$_db1_c/a1.out") $(_db1_last a3 | grep -c ' (counted from lines)$')" "same 1"
rm -rf "$DB1/n/arith"

# ---- assertion failures (D3, D4): their own FAIL, exit 1, and the manifest written as -j 1 writes it
_db1_n9a="no fixture git command was refused for a directory outside the suite's temporary directory"
_db1_n9b="fixture floor: at the end of the suite it still stands in cwd inside its temporary directory, under a ceiling at that directory's parent"
is "D3: the two 9990 names the cases below read are 9990's (control)" "$(grep -qF -e "$_db1_n9a" "$HERE"/parts/9990-*.sh && grep -qF -e "$_db1_n9b" "$HERE"/parts/9990-*.sh && echo both)" both
_db1_af() {   # CASE DESC FAILNAME: pp/CASE under -j 3: that FAIL once, no runner failure, exit 1, no receipt; and the record run's manifest is -j 1's
  local n="$1" d="$2" w="$3" a b
  _db1_new "$n" "$DB1/g-empty.tsv" - "$DB1/pp/$n"/*.sh; _db1_run p -j 3
  a="$(_db1_chk p "$w" "!part " '#1')"
  is "D3: $d gives its own FAIL, no runner failure, exit 1 and no receipt" "$a" ok
  rm -rf "$DB1/n/$n"; _db1_new "$n-r" --red "$DB1/g-empty.tsv" "$DB1/man.tsv" "$DB1/pp/$n"/*.sh
  _db1_run r -j 3 --record-assertions; a="$_db1_rc"; b="$(cat "$_db1_T/assertions.tsv")"
  cp "$DB1/man.tsv" "$_db1_T/assertions.tsv"; _db1_run r1 -j 1 --record-assertions
  is "D4: $d in a -j 3 record run exits 1 and writes the manifest -j 1 writes (not the old one)" \
     "$a $([ "$b" = "$(cat "$_db1_T/assertions.tsv")" ] && [ "$b" != "$(cat "$DB1/man.tsv")" ] && echo same || echo differ)" "1 same"
  rm -rf "$DB1/n/$n-r"
}
_db1_mk afail <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx afail one"
bad "djx afail fails"
ok "djx afail two"
X
_db1_af afail "a failing assertion" "djx afail fails"
_db1_mk arefuse <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
printf 'djx planted refusal line\n' >> "$FELIX_TEST_FXREFUSED"
ok "djx arefuse one"
X
_db1_af arefuse "a refusal record planted in a unit" "$_db1_n9a"
_db1_mk afloor <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
cd /
ok "djx afloor one"
X
_db1_af afloor "a unit that ends outside its \$TMP/cwd" "$_db1_n9b"

# ---- signals (D6): what a unit starts with, and how a run ends
cat > "$DB1/sig.pl" <<'DB1SIG'
print "djx-sig:", join(",", map { $_ . "=" . ((defined $SIG{$_} && length $SIG{$_}) ? $SIG{$_} : "DEFAULT") } qw(INT QUIT TERM HUP)), "\n";
DB1SIG
cat > "$DB1/gc.pl" <<'DB1GC'
# gc.pl PIDFILE GCFILE ID MODE: ignores TERM; with MODE 1, forks a sleeping grandchild every 50 ms once its parent is gone
my ($pf, $gf, $id, $mode) = @ARGV;
$SIG{TERM} = 'IGNORE';
open(my $h, ">", $pf) or exit 3; print $h "$$\n"; close $h;
my $pp = getppid; my $n = 0;
while (1) {
  select(undef, undef, undef, 0.05);
  next unless $mode && getppid != $pp && $n < 60;
  $n++; my $k = fork;
  if (defined $k && !$k) { open(my $g, ">>", $gf); print $g "$$\n"; close $g; exec "perl", "-e", "sleep 120", $id, "gc"; exit 1 }
}
DB1GC
_db1_mk sig <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
perl "$DJX_PL/sig.pl"
ok "djx sig"
X
_db1_new sig "$DB1/g-empty.tsv" - "$DB1/pp/sig"/*.sh
for _db1_m in "DEFAULT DEFAULT" "IGNORE IGNORE" "IGNORE DEFAULT" "DEFAULT IGNORE"; do
  _db1_i="${_db1_m% *}"; _db1_q="${_db1_m#* }"
  _db1_INT="$_db1_i"; _db1_QUIT="$_db1_q"; _db1_run s3 -j 3
  _db1_x="$(grep '^djx-sig:' "$_db1_c/s3.out" | tr '\n' ' ')"; _db1_y="$(_db1_last s3 | grep -c ' (counted from lines)$')"
  _db1_INT="$_db1_i"; _db1_QUIT="$_db1_q"; _db1_run s1 -j 1
  _db1_z="$(grep '^djx-sig:' "$_db1_c/s1.out" | tr '\n' ' ')"
  is "D6: a -j 1 run's part sees INT $_db1_i and QUIT $_db1_q as its parent had them (control)" "$([ "${_db1_z#djx-sig:INT=$_db1_i,QUIT=$_db1_q,}" != "$_db1_z" ] && echo yes || echo "no [$_db1_z]")" yes
  is "D6: a -j 3 run's unit reports the same four dispositions as a -j 1 run's part, from a parent with INT $_db1_i and QUIT $_db1_q" \
     "$_db1_y $([ "$_db1_x" = "$_db1_z" ] && echo same || echo "differ [$_db1_x] [$_db1_z]")" "1 same"
done
rm -rf "$DB1/n/sig"
_db1_id()     { printf '%s' "${TMP##*/}-${_db1_c##*/}"; }
_db1_key()    { printf '%s' "${_db1_c#/private}/f/engine/harness/tests/run"; }
_db1_up()     { ls "$_db1_c"/up.* >/dev/null 2>&1; }
_db1_pe()     { ls "$_db1_c"/prelude-end.* >/dev/null 2>&1; }
_db1_plantpe() { local f; for f in "$_db1_T"/parts/0006-*.sh; do printf '\n: > "%s/prelude-end.$$"\n' "$_db1_c" >> "$f"; done; }
_db1_pl()     { local p i; i="$(_db1_id)"; for p in $(cat "$_db1_c"/ign.pid "$_db1_c"/gc.pids "$_db1_c"/sl.pid 2>/dev/null); do
                case "$(ps -p "$p" -o command= 2>/dev/null)" in *"$i"*) printf '%s ' "$p" ;; esac; done; }
_db1_nopl()   { [ -z "$(_db1_pl)" ]; }
_db1_reap()   { local p; for p in $(_db1_pl); do kill -KILL "$p" 2>/dev/null; done; }
_db1_noproc() { [ -z "$(_db1_ps "$(_db1_key)")" ]; }
_db1_unitps() { ps -A -o pid= -o command= 2>/dev/null | K="$(_db1_key)" LC_ALL=C awk 'index($0, ENVIRON["K"]) && index($0, " --part ") && $2 !~ /perl/ { printf "%s ", $1 }'; }
_db1_gone() {   # LABEL STATUS: "ok", or what a run that was interrupted left behind; what it finds still running is killed
  local l="$1" r=""
  [ "$_db1_rc" = "$2" ] || r="$r exit $_db1_rc, not $2;"
  [ "$(_db1_line "$_db1_c/$l.out" reached)" = 0 ] || r="$r reached was printed;"
  _db1_until 25 _db1_noproc || r="$r processes of the run still ran: $(_db1_ps "$(_db1_key)");"
  _db1_until 25 _db1_nopl || r="$r a child of a unit still ran: $(_db1_pl);"
  _db1_reap
  [ -z "$(_db1_slots "${_db1_td:-$_db1_tmp}")" ] || r="$r a slot was still held;"
  [ "$(_db1_rcpt)" = absent ] || r="$r a receipt was left;"
  [ "$_db1_ctl" = 1 ] || r="$r no positive control, so these absences say nothing;"
  printf '%s' "${r:-ok}"
}
_db1_intr() {   # CASE SIGNAL STATUS: a -j 3 run of pp/CASE, SIGNAL to the driver once a unit is up; the copy stays for the caller
  local c="$1" s="$2" w="$3" r="" p g
  _db1_new "$c-$s" "$DB1/g-empty.tsv" - "$DB1/pp/$c"/*.sh || { printf 'the copy could not be made'; return 0; }
  _db1_start i -j 3
  _db1_until 150 _db1_up || r=" no unit came up;"
  sleep 0.5
  p="$(cat "$_db1_c/i.pid" 2>/dev/null)"; [ -z "$p" ] || kill -"$s" "$p" 2>/dev/null
  _db1_wait
  g="$(_db1_gone i "$w")"; [ "$g" != ok ] || g=""
  r="$r$g"; printf '%s' "${r:-ok}"
}
_db1_mk slp <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
perl -e 'open(my $h, ">", $ARGV[0]); print $h "$$\n"; close $h; sleep 120' "$DJX_DIR/sl.pid" "$DJX_ID" &
while [ ! -s "$DJX_DIR/sl.pid" ]; do sleep 0.1; done
: > "$DJX_DIR/up.$$"
wait
X
_db1_mk ign <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
perl "$DJX_PL/gc.pl" "$DJX_DIR/ign.pid" "$DJX_DIR/gc.pids" "$DJX_ID" 0 &
while [ ! -s "$DJX_DIR/ign.pid" ]; do sleep 0.1; done
: > "$DJX_DIR/up.$$"
wait
X
_db1_mk gcx <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
perl "$DJX_PL/gc.pl" "$DJX_DIR/ign.pid" "$DJX_DIR/gc.pids" "$DJX_ID" 1 &
while [ ! -s "$DJX_DIR/ign.pid" ]; do sleep 0.1; done
: > "$DJX_DIR/up.$$"
wait
X
is "D6: TERM sent to the parent while units run: exit 143, no reached, no unit, holder, wrapper or child left running, no slot held, no receipt" "$(_db1_intr slp TERM 143)" ok
is "D6: INT sent to a parent started with INT at its default: exit 130, with the same afterwards" "$(_db1_intr slp INT 130)" ok
is "D6: HUP sent to the parent: exit 129, with the same afterwards" "$(_db1_intr slp HUP 129)" ok
is "D6: a child a unit started with & that ignores TERM, and is moved to pid 1 when the unit dies, is gone once the parent has ended" "$(_db1_intr ign TERM 143)" ok
_db1_x="$(_db1_intr gcx TERM 143)"
if [ "$_db1_x" = ok ] && [ ! -s "$DB1/n/gcx-TERM/gc.pids" ]; then
  skip "D6: and a grandchild that child forks after the parent's TERM is gone once the parent has ended" "the child was stopped before it forked one, so there was none to find"
else is "D6: and a grandchild that child forks after the parent's TERM is gone once the parent has ended" "$_db1_x" ok; fi
rm -rf "$DB1/n/slp-TERM" "$DB1/n/slp-INT" "$DB1/n/slp-HUP" "$DB1/n/ign-TERM" "$DB1/n/gcx-TERM"

# ---- an interrupt while a holder waits, and the slots (D6): an outside process holds the lock of slot 0
rm -rf "$DB1/td-w"; mkdir -p "$DB1/td-w"; _db1_td="$DB1/td-w"
_db1_new hw "$DB1/g-empty.tsv" - "$DB1/pp/slp"/*.sh; _db1_plantpe
_db1_hold "$_db1_td/felix-suite-slots/0" 120
_db1_E=(FELIX_TEST_SLOTS=1); _db1_start hw -j 2
_db1_until 150 _db1_pe; sleep 2
_db1_x="$(_db1_unitps)"; _db1_up && _db1_x="$_db1_x marker"
kill -TERM "$(cat "$_db1_c/hw.pid" 2>/dev/null)" 2>/dev/null; _db1_wait; _db1_unhold; sleep 3
is "D6: with FELIX_TEST_SLOTS=1 and the slot's lock held elsewhere, TERM to the parent starts no unit, neither before it nor after the parent has exited, which is 143" \
   "$_db1_rc|${_db1_x}|$(_db1_up && echo started)|$(_db1_unitps)|$(_db1_noproc && echo none || echo left)" "143||||none"
_db1_reap; rm -rf "$DB1/n/hw" "$DB1/td-w"
rm -rf "$DB1/td-k"; mkdir -p "$DB1/td-k"; _db1_td="$DB1/td-k"
_db1_new hk "$DB1/g-empty.tsv" - "$DB1/pp/slp"/*.sh; _db1_plantpe
_db1_hold "$_db1_td/felix-suite-slots/0" 120
_db1_E=(FELIX_TEST_SLOTS=1); _db1_start hk -j 2
_db1_until 150 _db1_pe; sleep 2
_db1_x="$(_db1_unitps)"
_db1_unhold
_db1_i=0; _db1_y=""; while [ "$_db1_i" -lt 20 ]; do _db1_y="$(_db1_unitps)"; [ -z "$_db1_y" ] || break; sleep 0.1; _db1_i=$((_db1_i + 1)); done
kill -TERM "$(cat "$_db1_c/hk.pid" 2>/dev/null)" 2>/dev/null; _db1_wait; _db1_gone hk 143 >/dev/null
is "D6: a slot whose holder was killed with kill -9 is free at once: no run --part process while it was held, one within two seconds of the kill" "${_db1_x:+running while held}|${_db1_y:+appeared}" "|appeared"
rm -rf "$DB1/n/hk" "$DB1/td-k"
mkdir -p "$DB1/pp/note"
for _db1_a in a:0010 b:0020; do _db1_n="${_db1_a#*:}-n${_db1_a%:*}.sh"
  printf 'printf "\\ndjx-sec %s\\n"\nok "djx note %s"\nsleep 2\n' "$_db1_n" "$_db1_n" > "$DB1/pp/note/$_db1_n"; done
rm -rf "$DB1/td-n"; mkdir -p "$DB1/td-n"; _db1_td="$DB1/td-n"
_db1_new nt "$DB1/g-empty.tsv" - "$DB1/pp/note"/*.sh; _db1_E=(FELIX_TEST_SLOTS=1); _db1_run nt -j 2
_db1_x="$(LC_ALL=C awk '/^  note  / { n++; ln = NR; u = $2; if ($0 !~ /^  note  [^ ]+ waited [0-9]+ s for a slot$/) bad = 1 }
  index($0, "djx-sec ") == 1 { sec[substr($0, 9)] = NR }
  END { print n + 0, bad + 0, (u in sec && sec[u] > ln && sec[u] - ln <= 2) ? "head" : "elsewhere" }' "$_db1_c/nt.out")"
is "D3: with one slot and two units, the one that waited more than a second gets one note, UNIT waited S s for a slot, at the head of its section" "$_db1_rc $_db1_x" "0 1 0 head"
_db1_x="$(_db1_cnt "$_db1_c/nt.out" '  ok    ')"; _db1_y="$(_db1_last nt | awk '{ print $1 }')"
is "D3: and a note is not an assertion: the summary counts as many passes as the log has ok lines" "$([ "$_db1_x" = "$_db1_y" ] && echo same || echo "$_db1_x lines, summary $_db1_y")" same
rm -rf "$DB1/n/nt" "$DB1/td-n"; _db1_td=""

# ---- the slots cap the machine (D6): two -j 4 runs at once, units of 3 s each write their start and end
cat > "$DB1/span.pl" <<'DB1SP'
use Time::HiRes qw(time sleep);
my $s = time; sleep 3; my $e = time;
open(my $h, ">>", $ARGV[0]) or exit 1; printf $h "%.3f %.3f\n", $s, $e; close $h;
DB1SP
mkdir -p "$DB1/pp/span"
for _db1_a in a:0010 b:0020 c:0030 d:0040; do _db1_n="${_db1_a#*:}-s${_db1_a%:*}.sh"
  printf 'printf "\\ndjx-sec %s\\n"\nperl "$DJX_PL/span.pl" "$DJX_SPAN"\nok "djx span %s"\n' "$_db1_n" "$_db1_n" > "$DB1/pp/span/$_db1_n"; done
_db1_sel() { _db1_c="$DB1/n/$1"; _db1_F="$_db1_c/f"; _db1_T="$_db1_F/engine/harness/tests"; _db1_tmp="$_db1_c/tmp"; }
_db1_ov() { LC_ALL=C awk '{ s[NR] = $1; e[NR] = $2 } END { m = 0; for (i = 1; i <= NR; i++) { c = 0; for (j = 1; j <= NR; j++) if (s[j] <= s[i] && s[i] < e[j]) c++; if (c > m) m = c } print m, NR }' "$1" 2>/dev/null; }
_db1_cap() {   # TMPDIR SLOTS SPANFILE: both runs share TMPDIR; _db1_ovr is "most units at once, units"
  local td="$1" k="$2" f="$3" ba bb
  rm -rf "$td"; rm -f "$f"; mkdir -p "$td"; _db1_td="$td"
  _db1_new capA "$DB1/g-empty.tsv" - "$DB1/pp/span"/*.sh; _db1_new capB "$DB1/g-empty.tsv" - "$DB1/pp/span"/*.sh
  _db1_sel capA; _db1_E=(FELIX_TEST_SLOTS="$k" DJX_SPAN="$f"); _db1_start a -j 4; ba="$_db1_bg"
  _db1_sel capB; _db1_E=(FELIX_TEST_SLOTS="$k" DJX_SPAN="$f"); _db1_start b -j 4; bb="$_db1_bg"
  _db1_bg="$ba"; _db1_wait; _db1_bg="$bb"; _db1_wait
  _db1_ovr="$(_db1_ov "$f")"; _db1_td=""; rm -rf "$DB1/n/capA" "$DB1/n/capB" "$td"
}
_db1_cap "$DB1/td-c3" 3 "$DB1/span3"
is "D6: with FELIX_TEST_SLOTS=3, two -j 4 runs of eight 3 s units reach three at once and never more" "$_db1_ovr" "3 8"
_db1_cap "$DB1/td-c8" 8 "$DB1/span8"
is "D6: and with FELIX_TEST_SLOTS=8 the same two runs do overlap more than three units (control for the count above)" "$([ "${_db1_ovr% *}" -gt 3 ] 2>/dev/null && echo more || echo "$_db1_ovr")" more

# ---- slots that cannot be taken (D6): the parent refuses with exit 2 and one line, and starts no unit
_db1_srv() {   # sets _db1_v: ok when the -j 2 run in the current copy was refused, exit 2, one stderr line, and no unit came up
  local r="" n
  _db1_run sr -j 2
  n="$(awk 'END { print NR }' "$_db1_c/sr.err")"
  [ "$_db1_rc" = 2 ] || r="$r exit $_db1_rc, not 2;"; [ "$n" = 1 ] || r="$r $n stderr lines, not 1;"
  ! _db1_up || r="$r a unit started;"
  _db1_v="${r:-ok}"
}
printf 'package Djflock;\nuse Errno qw(ENOLCK);\nBEGIN { *CORE::GLOBAL::flock = sub { $! = ENOLCK; return 0 } }\n1;\n' > "$DB1/Djflock.pm"
rm -rf "$DB1/td-f"; mkdir -p "$DB1/td-f"; _db1_td="$DB1/td-f"
_db1_new fl "$DB1/g-empty.tsv" - "$DB1/pp/slp"/*.sh; _db1_E=(PERL5OPT="-I$DB1 -MDjflock" FELIX_TEST_SLOTS=2); _db1_srv
is "D6: where flock fails with ENOLCK, and not with EWOULDBLOCK, the parent's one lock fails and the run is refused: exit 2, one stderr line, no unit" "$_db1_v" ok
rm -rf "$DB1/n/fl" "$DB1/td-f"
rm -rf "$DB1/td-d"; mkdir -p "$DB1/td-d/felix-suite-slots/0"; _db1_td="$DB1/td-d"
_db1_new nd "$DB1/g-empty.tsv" - "$DB1/pp/slp"/*.sh; _db1_E=(FELIX_TEST_SLOTS=2); _db1_srv
is "D6: a name under the slots directory that is not a regular file (a directory) makes a -j run refuse: exit 2, one stderr line, no unit" "$_db1_v" ok
rm -rf "$DB1/n/nd" "$DB1/td-d"
rm -rf "$DB1/td-m"; mkdir -p "$DB1/td-m/felix-suite-slots"; : > "$DB1/td-m/felix-suite-slots/0"; chmod 000 "$DB1/td-m/felix-suite-slots/0"; _db1_td="$DB1/td-m"
if [ -r "$DB1/td-m/felix-suite-slots/0" ]; then skip "D6: a slot file the parent cannot open makes a -j run refuse: exit 2, one stderr line, no unit" "a mode 000 file is still readable by this user"
else _db1_new nm "$DB1/g-empty.tsv" - "$DB1/pp/slp"/*.sh; _db1_E=(FELIX_TEST_SLOTS=2); _db1_srv
  is "D6: a slot file the parent cannot open makes a -j run refuse: exit 2, one stderr line, no unit" "$_db1_v" ok; fi
chmod 644 "$DB1/td-m/felix-suite-slots/0"; rm -rf "$DB1/n/nm" "$DB1/td-m"; _db1_td=""

# ---- the order units start in, and the durations file (D4, D6)
mkdir -p "$DB1/pp/ord"
printf 'printf "\\ndjx-sec 0010-oa.sh\\n"\nprintf "%%s\\n" 0010-oa.sh >> "$DJX_DIR/starts"\nsleep 14\nok "djx ord 0010-oa.sh"\n' > "$DB1/pp/ord/0010-oa.sh"
for _db1_a in 0020-ob.sh 0030-oc.sh 0040-od.sh 0050-oe.sh; do
  printf 'printf "\\ndjx-sec %s\\n"\nprintf "%%s\\n" %s >> "$DJX_DIR/starts"\nok "djx ord %s"\n' "$_db1_a" "$_db1_a" "$_db1_a" > "$DB1/pp/ord/$_db1_a"; done
_db1_new ord "$DB1/g-empty.tsv" - "$DB1/pp/ord"/*.sh
_db1_w="$DB1/hostile.witness"; rm -f "$_db1_w"
{ printf '99\t0010-oa.sh\n9\t0030-oc.sh\n9\t0040-od.sh\n08\t0020-ob.sh\n2\t0020-ob.sh\n'
  printf 'a[$(touch %s)]\t0050-oe.sh\n' "$_db1_w"
  printf '08\t0099-zz.sh\n-3\t0098-zz.sh\n7 0097-zz.sh\n\njunk\n1e3\t0096-zz.sh\n'; } > "$_db1_F/.git/felix-suite-durations"
rm -f "$_db1_c/starts"; _db1_run o2 -j 2
_db1_x="$(sed -n '1,2p' "$_db1_c/starts" | LC_ALL=C sort | tr '\n' ' ')|$(sed -n '3,$p' "$_db1_c/starts" | tr '\n' ' ')"
is "D6: units start longest first by the durations file: the unit with no row, then 99, then 9 and 9 in driver order, then 2 (the first two are a pair started at once)" \
   "$_db1_rc $_db1_x" "0 0010-oa.sh 0050-oe.sh |0030-oc.sh 0040-od.sh 0020-ob.sh "
is "D4: rows with a bad seconds field, a space for the tab, a non-unit name or a subscript are ignored: nothing in the file ran, and no arithmetic error was printed" \
   "$([ -e "$_db1_w" ] && echo ran || echo not-run) $(grep -c -E 'syntax error|arithmetic|invalid|bad substitution|unbound' "$_db1_c/o2.err" 2>/dev/null)" "not-run 0"
_db1_x="$(awk -F'\t' '$1 ~ /^(0|[1-9][0-9]*)$/ { print $2 }' "$_db1_F/.git/felix-suite-durations" | LC_ALL=C sort | tr '\n' ' ')"
is "D4: the run writes the file whole at its end: one valid row for each of its five units, and the old rows gone" "$_db1_x" "0010-oa.sh 0020-ob.sh 0030-oc.sh 0040-od.sh 0050-oe.sh "
rm -f "$_db1_F/.git/felix-suite-durations" "$_db1_c/starts"; _db1_run o3 -j 2
_db1_x="$(sed -n '1,2p' "$_db1_c/starts" | LC_ALL=C sort | tr '\n' ' ')|$(sed -n '3,$p' "$_db1_c/starts" | tr '\n' ' ')"
is "D6: with no durations file the order is the driver's: the first two at once, then the rest one after another" "$_db1_rc $_db1_x" "0 0010-oa.sh 0020-ob.sh |0030-oc.sh 0040-od.sh 0050-oe.sh "
rm -rf "$DB1/n/ord"

# ---- the gate (D1): gate.sh beside a stub tests/run that records its arguments and FELIX_TEST_JOBS
_db1_G="$DB1/gt"; mkdir -p "$_db1_G/engine/harness/tests" "$_db1_G/projects/felix" "$DB1/gtmp" "$DB1/gout"
cp "$REAL_HARNESS/../../projects/felix/gate.sh" "$_db1_G/projects/felix/gate.sh"
cat > "$_db1_G/engine/harness/tests/run" <<'DB1STUB'
#!/usr/bin/env bash
printf '%s:%s\n' "$#" "$*" >> "$DJX_OUT/$DJX_L.args"
printf '%s\n' "${FELIX_TEST_JOBS-unset}" >> "$DJX_OUT/$DJX_L.jobs"
if [ -n "${DJX_EXIT2:-}" ]; then printf 'djx stub: a refusal of its own\n' >&2; exit 2; fi
printf 'reused the suite run that ended 09:00 on this tree (normal), not run again\n'
printf '\n7 passed, 0 failed (reused)\n'
DB1STUB
chmod +x "$_db1_G/engine/harness/tests/run"
( _fx_cd "${_db1_G:?}" && git init -q -b main && git add -A && git -c user.name=djx -c user.email=djx@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm seed ) >/dev/null 2>&1
_db1_gate() {   # LABEL ENV...: gate.sh in the fixture, the stub recording as LABEL
  local l="$1"; shift
  ( cd "${_db1_G:?}" && perl "$DB1/run.pl" 90 DEFAULT DEFAULT "$DB1/gout/$l.pid" env -u FELIX_TEST_NO_MANIFEST -u GITHUB_ACTIONS -u FELIX_TEST_JOBS \
      FELIX_KERNEL_CACHE="$_db1_G/no-cache" TMPDIR="$DB1/gtmp" DJX_OUT="$DB1/gout" DJX_L="$l" ${1+"$@"} bash projects/felix/gate.sh ) > "$DB1/gout/$l.out" 2>&1
}
_db1_gate g1; _db1_gate g2 GITHUB_ACTIONS=true; _db1_gate g3 DJX_EXIT2=1
is "D1: with GITHUB_ACTIONS unset, gate.sh sets FELIX_TEST_JOBS to the core count for its call to tests/run (sysctl, then getconf, then 1; held to 1 to 64)" "$(cat "$DB1/gout/g1.jobs" 2>/dev/null)" "$(_db1_cores)"
is "D1: with GITHUB_ACTIONS=true it does not set it (control)" "$(cat "$DB1/gout/g2.jobs" 2>/dev/null)" unset
is "D1: and its argument list stays --reuse, in both (control)" "$(cat "$DB1/gout/g1.args" 2>/dev/null) $(cat "$DB1/gout/g2.args" 2>/dev/null)" "1:--reuse 1:--reuse"
is "D1: when tests/run exits 2, the log's last line is shown under tests FAIL" \
   "$(LC_ALL=C awk '/^  tests +FAIL$/ { f = 1; next } f && index($0, "djx stub: a refusal of its own") { h = 1 } END { print f + 0, h + 0 }' "$DB1/gout/g3.out" 2>/dev/null)" "1 1"

# ---- part mode (D1, D2): by hand, and as the runner uses it
_db1_mk pm <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
printf 'djx-rec:%s\n' "${FELIX_TEST_RECORD-unset}"
printf 'djx-pv:%s\n' "$(env | grep -c '^FELIX_TEST_PART_')"
ok "djx pm one"
bad "djx pm fails"
printf 'djx-no-newline'
X
_db1_new pm --red "$DB1/g-empty.tsv" "$DB1/man.tsv" "$DB1/pp/pm"/*.sh
_db1_run pm1 --part 0020-pb.sh 0030-pc.sh
_db1_x="$(grep '^@@' "$_db1_c/pm1.out" | tr '\n' '|')"
is "D2: --part by hand prints @@prelude-done, a @@member-done line for each member in order, and the mark naming the members, each on a line of its own" \
   "$_db1_x" "@@prelude-done|@@member-done 0020-pb.sh|@@member-done 0030-pc.sh|@@part-done 0020-pb.sh 0030-pc.sh|"
is "D2: it exits 0 whatever it counts as failed, and the mark is the last line" "$_db1_rc $(_db1_last pm1)" "0 @@part-done 0020-pb.sh 0030-pc.sh"
is "D2: a partial last line of a member is ended before the runner line, and the part's own lines are printed" \
   "$(_db1_line "$_db1_c/pm1.out" djx-no-newline) $(_db1_line "$_db1_c/pm1.out" '  FAIL  djx pm fails') $(_db1_line "$_db1_c/pm1.out" djx-rec:unset) $(_db1_line "$_db1_c/pm1.out" djx-pv:0)" "1 1 1 1"
is "D2: the prelude's lines come before @@prelude-done and the first member's after it" \
   "$(LC_ALL=C awk '/^@@prelude-done$/ { pd = NR } /^  ok    / && !pd { pre++ } index($0, "djx-sec 0020-pb.sh") == 1 { s = NR } END { print (pre > 0 && pd && s > pd) ? "ordered" : "pre=" pre + 0 " pd=" pd + 0 " sec=" s + 0 }' "$_db1_c/pm1.out")" ordered
is "D2: it prints no reached and no summary, takes no receipt, starts no red run, leaves the manifest and writes no red.tsv" \
   "$(_db1_line "$_db1_c/pm1.out" reached) $(grep -c -E '^[0-9]+ passed, [0-9]+ failed' "$_db1_c/pm1.out") $(_db1_rcpt) $(cmp -s "$DB1/man.tsv" "$_db1_T/assertions.tsv" && echo same || echo changed) $([ -e "$_db1_T/red.tsv" ] && echo red.tsv || echo no-red.tsv) $(_db1_nored && echo no-red || echo red-ran)" \
   "0 0 absent same no-red.tsv no-red"
_db1_E=(FELIX_TEST_PART_LOG="$_db1_c/pl.log" FELIX_TEST_PART_RAN="$_db1_c/pl.ran" FELIX_TEST_PART_END="$_db1_c/pl.end" FELIX_TEST_PART_RECORD=1)
_db1_run pm2 --part 0020-pb.sh 0030-pc.sh
is "D2: with the FELIX_TEST_PART_ files it writes the log, in order, with the runner lines in it and none on stdout, and exits 0" \
   "$_db1_rc $(grep '^@@' "$_db1_c/pl.log" 2>/dev/null | tr '\n' '|') $(grep -c '^@@' "$_db1_c/pm2.out")" \
   "0 @@prelude-done|@@member-done 0020-pb.sh|@@member-done 0030-pc.sh|@@part-done 0020-pb.sh 0030-pc.sh| 0"
is "D2: the ran file holds the names reached after @@prelude-done, and only those" "$(LC_ALL=C sort "$_db1_c/pl.ran" 2>/dev/null | tr '\n' '|')" "djx c skip|djx c1|djx pm fails|djx pm one|"
is "D2: it writes an end file, and with FELIX_TEST_PART_RECORD=1 it sets FELIX_TEST_RECORD=1 first, and unsets the FELIX_TEST_PART_ variables once read" \
   "$([ -s "$_db1_c/pl.end" ] && echo end-file || echo none) $(_db1_line "$_db1_c/pl.log" djx-rec:1) $(_db1_line "$_db1_c/pl.log" djx-pv:0)" "end-file 1 1"
rm -rf "$DB1/n/pm"

# ---- the part leaves the shell as it found it
unset -f $(compgen -A function _db1_) 2>/dev/null
unset $(compgen -A variable _db1_) DB1 DB1K 2>/dev/null
# <<< gate-friction-d-blind
