# >>> gate-friction-d-runner-failures-blind
printf '\ngate friction D: a unit that goes wrong, what that does to a run and to a record run, and the gate (blind, revision 11)\n'
# Blind, written from contract D revision 11 alone (docs/2026-10-18-gate-friction-
# contract-d.md: D3, D4, D8, R1, R7, R12, R16, R27, R28, R30, R32, R33, R38). Nothing here was read off an
# implementation; tests/run, tests/red and tests/receipt.sh are run, never read,
# in copies of this suite that _suite_copy_tree (part 0003) makes under $TMP, each
# with planted parts of this block's own. Every case points TMPDIR at a fixture
# directory, runs every inner run under a bounded runner that makes its own
# process group and resets INT, QUIT, HUP and TERM, and ends by asking that
# group to hold no live process, stopped or running (zombies aside), for 30 s;
# what is left is named, then sent CONT and KILL by pid. Nothing is killed by
# pattern. Names say the clause: D3 the runner's failures and the log, D4 the
# record, R1 red's tree, R7 the log's shape, R8 and R16 the shell a unit leaves,
# R27 a TERM sent to a stopper of red's tree while it stops (R32 red's monitor on bash 5.2, R33 the watcher's stopper found whatever /bin/sh is), R30 the end of a run
# whose parent cannot read its job table, R38 the 13 R1 leftover cases below (the "and once the record run after ... has exited" names of _db3_rf).
# R38: red's suite runs this part on the base's tests/red and tests/receipt.sh, which lack R1's stopper, so a record run that ends on a runner failure
# exits there only once red's suite has ended by itself, and what is left of red's tree then is a matter of timing. Each _db3_rf case therefore plants, in
# its record half only (DJX_HOLD names hold.pl, which the case gives that run alone), a red-only holder H: red's suite, at the planted step, makes the case's
# hold.dir (only the first to do so goes on), starts H (a process that ends within 0.2 s of hold.release appearing, and on its own 60 s after it started),
# writes hold.pid and hold.start, then waits until hold.go exists and C = 10 s more. The record run's own units wait for hold.start (60 s at most) and write
# hold.go, then fail as the case says. Against a build without R1 red's suite goes on after C and ends by itself, leaving H running, so the record run
# exits with H in its group at both of _db3_atexit's listings; against D's build red's monitor ends red's suite on the failed mark while the step holds, H
# with it, so nothing is left. _db3_run writes hold.release as soon as _db3_atexit has listed, so _db3_clean waits about a second, not its 30 s. The step is
# one perl process (no short-lived child to be left behind), run by the part's one line, so the unit's shell is not changed.
# An assertion whose name ends in (control) passes before D is built on purpose.
DB3="$TMP/db3"
mkdir -p "$DB3/pp/std" "$DB3/n"
cat > "$DB3/hold.pl" <<'DB3HOLD'
# hold.pl SIDE DIR (R38): SIDE 1 is red's suite (FELIX_TEST_NO_MANIFEST=1), anything else the record run. DIR is the case's directory.
use strict; use Time::HiRes qw(time sleep);
my ($side, $d) = @ARGV;
sub ms { sprintf "%d\n", time * 1000 }
sub put { my ($f, $t) = @_; open(my $h, ">", "$f.t") or return; print $h $t; close $h; rename "$f.t", $f }
if ($side eq "1") {
  mkdir "$d/hold.dir" or exit 0;
  $SIG{TERM} = sub { put("$d/hold.ended", ms()); exit 143 };
  my $t0 = time; my $h = fork; defined $h or exit 0;
  if (!$h) {
    open(STDIN, "<", "/dev/null"); open(STDOUT, ">", "/dev/null"); open(STDERR, ">", "/dev/null");
    $SIG{TERM} = "DEFAULT";
    sleep 0.1 until -e "$d/hold.release" || time > $t0 + 60;
    exit 0;
  }
  put("$d/hold.pid", "$h\n"); put("$d/hold.start", ms());
  my $e = $t0 + 60; sleep 0.1 until -e "$d/hold.go" || time > $e;
  if (-e "$d/hold.go") { $e = time + 10; sleep 0.1 while time < $e }
} else {
  my $e = time + 60; sleep 0.1 until -e "$d/hold.start" || time > $e;
  put("$d/hold.go", ms());
}
DB3HOLD
_db3_HL='[ -z "${DJX_HOLD:-}" ] || perl "$DJX_HOLD" "${FELIX_TEST_NO_MANIFEST:-0}" "$DJX_DIR"'
_db3_E=(); _db3_INT=DEFAULT; _db3_QUIT=DEFAULT; _db3_ctl=0; _db3_ctlr=0; _db3_pf=(); _db3_cl=ok; _db3_ex=ok; _db3_leak=""; _db3_skip=""; _db3_hook=""; _db3_post=""; _db3_postn=""
cat > "$DB3/run.pl" <<'DB3PL'
my ($t, $i, $q, $f) = splice(@ARGV, 0, 4);
my $p = fork; defined $p or exit 125;
if (!$p) { setpgrp(0, 0); $SIG{INT} = $i; $SIG{QUIT} = $q; $SIG{HUP} = 'DEFAULT'; $SIG{TERM} = 'DEFAULT'; if (open(my $h, ">", $f)) { print $h "$$\n"; close $h } exec @ARGV; exit 127 }
$SIG{ALRM} = sub { kill "KILL", -$p; exit 124 };
alarm $t; waitpid $p, 0;
exit(($? & 127) ? 128 + ($? & 127) : $? >> 8);
DB3PL
: > "$DB3/g-empty.tsv"; printf '1\tdjx a1\n' > "$DB3/man.tsv"
_db3_ms() { perl -MTime::HiRes=time -e 'printf "%d", time * 1000'; }
_db3_until() { local n="$1" i=0; shift; while [ "$i" -lt "$n" ]; do "$@" && return 0; sleep 0.2; i=$((i + 1)); done; "$@"; }
_db3_cnt()  { LC_ALL=C awk -v p="$2" 'index($0, p) == 1 { n++ } END { print n + 0 }' "$1" 2>/dev/null; }   # FILE PREFIX: lines starting with it
_db3_line() { grep -cxF -e "$2" "$1" 2>/dev/null; }   # FILE LINE: lines that are exactly it
# The members of the process groups $* that are not zombies, one a line: PID STAT COMMAND.
_db3_gm() { ps -A -o pid= -o pgid= -o stat= -o command= 2>/dev/null | G=" $* " LC_ALL=C awk 'index(ENVIRON["G"], " " $2 " ") && $3 !~ /^Z/ { c = $0; sub(/^ *[0123456789]+ +[0123456789]+ +[^ ]+ +/, "", c); print $1 " " $3 " " substr(c, 1, 70) }'; }
_db3_gs() { local f; for f in ${_db3_pf[@]+"${_db3_pf[@]}"}; do printf ' %s' "$(cat "$f" 2>/dev/null)"; done; }   # the ids of the process groups of this case's runs
# R1: "ok" when no process of those groups is alive at two listings 0.1 s apart, the first taken at once after a run has exited (a process killed
# a moment ago is in the first listing only), else the processes that were in both.
_db3_atexit() {
  local g l1 l2 l="" p; g="$(_db3_gs)"
  [ -n "${g// /}" ] || { printf ok; return 0; }
  l1="$(_db3_gm $g)"; [ -n "$l1" ] || { printf ok; return 0; }
  sleep 0.1; l2="$(_db3_gm $g)"
  for p in $(printf '%s\n' "$l1" | awk '{ print $1 }'); do case "$l2" in "$p "*|*$'\n'"$p "*) l="$l$(printf '%s\n' "$l2" | grep -F -e "$p " | sed -n 1p);" ;; esac; done
  [ -n "$l" ] && printf 'left at its exit: %s' "$l" || printf ok
}
# R12: "ok" once the groups of this case's runs hold no live process (30 s), else what was left, sent CONT and then KILL by pid.
_db3_clean() {
  local g l="" i=0 p; g="$(_db3_gs)"
  [ -n "${g// /}" ] || { printf ok; return 0; }
  while [ "$i" -lt 150 ]; do l="$(_db3_gm $g)"; [ -n "$l" ] || { printf ok; return 0; }; sleep 0.2; i=$((i + 1)); done
  for p in $(printf '%s\n' "$l" | awk '{ print $1 }'); do kill -CONT "$p" 2>/dev/null; done
  for p in $(printf '%s\n' "$l" | awk '{ print $1 }'); do kill -KILL "$p" 2>/dev/null; done
  printf 'left behind: %s' "$(printf '%s' "$l" | tr '\n' ';')"
}
_db3_cores() { local n; n="$(sysctl -n hw.ncpu 2>/dev/null)"; case "$n" in ''|*[!0123456789]*) n="$(getconf _NPROCESSORS_ONLN 2>/dev/null)" ;; esac
  case "$n" in ''|*[!0123456789]*) n=1 ;; esac; [ "$n" -ge 1 ] || n=1; [ "$n" -le 64 ] || n=64; printf '%s' "$n"; }
# CASE [--red] GROUPS MANIFEST STUB...: the copy at $DB3/n/CASE (_db3_F, _db3_T, _db3_c, _db3_tmp); 1 when it could not be made
_db3_new() {
  local n="$1" r=""; shift
  [ "${1:-}" != --red ] || { r=--red; shift; }
  _db3_c="$DB3/n/$n"; _db3_F="$_db3_c/f"; _db3_T="$_db3_F/engine/harness/tests"; _db3_tmp="$_db3_c/tmp"; _db3_pf=()
  rm -rf "$_db3_c"; mkdir -p "$_db3_tmp" || return 1
  _suite_copy_tree ${r:+"$r"} "$_db3_F" "$@"
}
# LABEL ARG...: the copy's driver in the background under a bounded runner (stdout LABEL.out, stderr LABEL.err, the group's id LABEL.pid)
_db3_start() {
  local l="$1"; shift
  ( cd "$_db3_F" && exec env -u FELIX_TEST_NO_MANIFEST -u FELIX_TEST_JOBS -u FELIX_TEST_SLOTS -u FELIX_TEST_RED_JOBS -u FELIX_TEST_SLOT_NOTE -u FELIX_TEST_PART_LOG \
      -u FELIX_TEST_PART_RAN -u FELIX_TEST_PART_END -u FELIX_TEST_PART_RECORD -u PERL5OPT \
      TMPDIR="$_db3_tmp" FELIX_TEST_SLOTS=8 DJX_DIR="$_db3_c" DJX_CFG="$_db3_F/.git/config" DJX_KEEP=1 ${_db3_E[@]+"${_db3_E[@]}"} \
      perl "$DB3/run.pl" "${_db3_lim:-150}" "$_db3_INT" "$_db3_QUIT" "$_db3_c/$l.pid" "$BASH" "$_db3_T/run" "$@" \
  ) > "$_db3_c/$l.out" 2> "$_db3_c/$l.err" &
  _db3_bg=$!; _db3_pf[${#_db3_pf[@]}]="$_db3_c/$l.pid"
}
_db3_wait() { { wait "$_db3_bg"; } 2>/dev/null; _db3_rc=$?; _db3_E=(); _db3_INT=DEFAULT; _db3_QUIT=DEFAULT; }
_db3_run()  {   # _db3_ex: R1's verdict on this run, _db3_cl: R12's, whose findings _db3_leak keep
  _db3_start "$@"; _db3_wait; _db3_t1="$(_db3_ms)"; _db3_ex="$(_db3_atexit)"
  : > "$_db3_c/hold.release"   # R38: the red-only holder ends (within 0.2 s) as soon as the listings are taken, so _db3_clean has about a second to wait for
  _db3_cl="$(_db3_clean)"
  [ "$_db3_cl" = ok ] || _db3_leak="$_db3_leak [$_db3_c: $_db3_cl]"
  # evidence only: with DJX_MLOG naming a file, a run that had a holding step logs the case, hold.go to the end of the step (hold.ended) and to the record run's exit, in ms
  [ -z "${DJX_MLOG:-}" ] || [ ! -e "$_db3_c/hold.go" ] || printf '%s go-to-step-end %s go-to-exit %s ex %s\n' "${_db3_c##*/}" \
    "$([ -e "$_db3_c/hold.ended" ] && echo $(($(cat "$_db3_c/hold.ended") - $(cat "$_db3_c/hold.go"))) || echo natural)" "$((_db3_t1 - $(cat "$_db3_c/hold.go")))" "$_db3_ex" >> "$DJX_MLOG"
}
_db3_rcpt() { if [ -f "$_db3_F/.git/felix-suite-receipt" ]; then echo present; else echo absent; fi; }
_db3_last() { tail -n 1 "$_db3_c/$1.out" 2>/dev/null; }
_db3_redrows() { if [ -f "$_db3_T/red.tsv" ]; then grep -v '^#' "$_db3_T/red.tsv" | tr '\n' '|'; else printf '(no red.tsv)'; fi; }
_db3_std() { printf 'printf "\\ndjx-sec %s\\n"\nok "djx %s"\nok "djx %s again"\n' "$2" "$3" "$3" > "$1"; }
_db3_std "$DB3/pp/std/0010-pa.sh" 0010-pa.sh a1; _db3_std "$DB3/pp/std/0020-pb.sh" 0020-pb.sh b1; _db3_std "$DB3/pp/std/0030-pc.sh" 0030-pc.sh c1
_db3_mk() {   # CASE [FILE]: pp/CASE holds 0010-pa.sh, 0030-pc.sh and the part read from stdin (default 0020-pb.sh)
  local d="$DB3/pp/$1"; mkdir -p "$d" && cp "$DB3/pp/std/0010-pa.sh" "$DB3/pp/std/0030-pc.sh" "$d/" && cat > "$d/${2:-0020-pb.sh}"
}
# LABEL EXPECT...: "ok", or what differed, for the run LABEL just made: exit 1; each EXPECT a FAIL line printed once ("!X": never starting so;
# "#N": N failures in the summary; else as many as the log has "  FAIL  " lines); no receipt, and a control showing a passing run leaves one
_db3_chk() {
  local l="$1" e c r="" wf="" s; shift
  [ "$_db3_rc" = 1 ] || r="$r exit $_db3_rc, not 1;"
  for e in "$@"; do
    case "$e" in
      \#*) wf="${e#\#}" ;;
      !*) c="$(_db3_cnt "$_db3_c/$l.out" "  FAIL  ${e#!}")"; [ "$c" = 0 ] || r="$r [${e#!}] printed $c times;" ;;
      *) c="$(_db3_cnt "$_db3_c/$l.out" "  FAIL  $e")"; [ "$c" = 1 ] || r="$r [$e] printed $c times;" ;;
    esac
  done
  s="$(_db3_last "$l")"; [ -n "$wf" ] || wf="$(_db3_cnt "$_db3_c/$l.out" '  FAIL  ')"
  case "$s" in *" passed, "*" failed"*) s="${s#* passed, }"; s="${s%% failed*}"; [ "$s" = "$wf" ] || r="$r summary counts $s failed, not $wf;" ;; esac
  [ "$_db3_ctl" = 1 ] || r="$r the control left no receipt, so a missing one says nothing;"
  [ "$(_db3_rcpt)" = absent ] || r="$r a receipt was left;"
  printf '%s' "${r:-ok}"
}
# LABEL EXPECT...: _db3_chk for a record run, the manifest as it was, and red.tsv the two retraction rows (red has gone: _db3_run waited for the group)
_db3_chkr() {
  local r; r="$(_db3_chk "$@")"; [ "$r" != ok ] || r=""
  cmp -s "$DB3/man.tsv" "$_db3_T/assertions.tsv" || r="$r the manifest was rewritten;"
  [ "$(_db3_redrows)" = "$(printf 'base\t-\t-\t-|run\t-\t-\t-|')" ] || r="$r red.tsv holds [$(_db3_redrows)];"
  [ "$_db3_ctlr" = 1 ] || r="$r the record control wrote no manifest and no counts, so their absence says nothing;"
  printf '%s' "${r:-ok}"
}

# ---- the positive controls: planted passing parts under -j 3, plain and as a record run in a --red copy (D8)
# A receipt is left by a passing run only where a manifest was compared, so every copy whose "no receipt" means something has one: it lists the first
# assertion of the prelude, which every run reaches once, and which a serial run without a manifest names here.
_db3_new pn "$DB3/g-empty.tsv" - "$DB3/pp/std/0010-pa.sh"; _db3_run n1 -j 1
printf '1\t%s\n' "$(sed -n 's/^  ok    //p' "$_db3_c/n1.out" | sed -n 1p)" > "$DB3/pman.tsv"
_db3_new ctl "$DB3/g-empty.tsv" "$DB3/pman.tsv" "$DB3/pp/std"/*.sh
_db3_run c3 -j 3
[ "$_db3_rc" = 0 ] && [ -n "$(cat "$_db3_F/.git/felix-suite-receipt" 2>/dev/null)" ] && _db3_ctl=1
is "D8: a -j 3 run of planted passing parts in a copy with a manifest exits 0 and leaves a receipt (runner-failure copy, positive control)" "$_db3_rc $_db3_ctl" "0 1"
is "R12: and it leaves no process in its group, stopped or running (control)" "$_db3_cl" ok
_db3_new rc --red "$DB3/g-empty.tsv" "$DB3/man.tsv" "$DB3/pp/std"/*.sh
_db3_run r3 -j 3 --record-assertions
case "$_db3_rc|$(_db3_redrows)" in 0\|base$'\t'origin/main$'\t'*$'\t'0.0.1\|run$'\t'0$'\t'[0123456789]*$'\t'[0123456789]*\|) cmp -s "$DB3/man.tsv" "$_db3_T/assertions.tsv" || _db3_ctlr=1 ;; esac
is "D8: a -j 3 record run of planted passing parts rewrites the manifest and leaves red.tsv with counts (runner-failure copy, positive control)" "$_db3_ctlr $_db3_cl" "1 ok"
rm -rf "$DB3/n/pn" "$DB3/n/ctl" "$DB3/n/rc"

# ---- the runner's own failures (D3), and what they do to a record run (D4, R1)
# CASE GROUPS DESC EXPECT...: pp/CASE under -j 3, then under -j 3 --record-assertions in a --red copy. _db3_hook runs in each copy before its run,
# _db3_post after the plain run (it asserts the names in _db3_postn, one a line); _db3_skip says why to reach every name below as a skip.
_db3_rf() {
  local n="$1" g="$2" d="$3" a1 a2 a3; shift 3
  a1="D3: $d fails with its runner line, exits 1 and leaves no receipt and no process"
  a2="D4: $d in a record run writes no manifest, and red.tsv holds the rows base - - - and run - - -"
  a3="R1: and once the record run after $d has exited no process of red's tree is left, stopped or running"
  if [ -n "$_db3_skip" ]; then
    skip "$a1" "$_db3_skip"; skip "$a2" "$_db3_skip"; skip "$a3" "$_db3_skip"; while IFS= read -r _db3_pn; do [ -z "$_db3_pn" ] || skip "$_db3_pn" "$_db3_skip"; done <<< "$_db3_postn"
    _db3_skip=""; _db3_hook=""; _db3_post=""; _db3_postn=""; return 0
  fi
  if _db3_new "$n" "$g" "$DB3/pman.tsv" "$DB3/pp/$n"/*.sh; then
    [ -z "$_db3_hook" ] || "$_db3_hook"
    _db3_run p -j 3
    is "$a1" "$(_db3_chk p "$@") $_db3_cl" "ok ok"
    [ -z "$_db3_post" ] || "$_db3_post"
  else bad "$a1" "the copy could not be made"; fi
  rm -rf "$DB3/n/$n"
  if _db3_new "$n-r" --red "$g" "$DB3/man.tsv" "$DB3/pp/$n"/*.sh; then
    [ -z "$_db3_hook" ] || "$_db3_hook"
    _db3_E=(DJX_HOLD="$DB3/hold.pl"); _db3_lim=240   # R38: the red-only holder, for this run alone
    _db3_run r -j 3 --record-assertions; unset _db3_lim
    is "$a2" "$(_db3_chkr r "$@")" ok
    is "$a3" "$_db3_ex" ok
  else bad "$a2" "the copy could not be made"; bad "$a3" "the copy could not be made"; fi
  rm -rf "$DB3/n/$n-r"; _db3_hook=""; _db3_post=""; _db3_postn=""
}
_db3_mk kill9 <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx kill9 before"
[ -z "${DJX_HOLD:-}" ] || perl "$DJX_HOLD" "${FELIX_TEST_NO_MANIFEST:-0}" "$DJX_DIR"
kill -9 $$
ok "djx kill9 after"
X
_db3_rf kill9 "$DB3/g-empty.tsv" "a unit killed with kill -9 while it runs a member" \
   "part did not finish: 0020-pb.sh" "part ended without its mark: 0020-pb.sh" "!part process ended with status"
_db3_mk lastkill <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx lastkill member"
[ -z "${DJX_HOLD:-}" ] || perl "$DJX_HOLD" "${FELIX_TEST_NO_MANIFEST:-0}" "$DJX_DIR"
_og_check() { : > "$DJX_DIR/killed.lastkill"; kill -9 $$; }
X
_db3_rf lastkill "$DB3/g-empty.tsv" "a unit killed after its last member and before its mark" \
   "part ended without its mark: 0020-pb.sh" "!part did not finish" "!part process ended with status"
_db3_mk exit0 <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx exit0 before"
[ -z "${DJX_HOLD:-}" ] || perl "$DJX_HOLD" "${FELIX_TEST_NO_MANIFEST:-0}" "$DJX_DIR"
exit 0
X
_db3_rf exit0 "$DB3/g-empty.tsv" "a part that runs exit 0" "part did not finish: 0020-pb.sh" "part ended without its mark: 0020-pb.sh"
_db3_mk setu <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx setu before"
[ -z "${DJX_HOLD:-}" ] || perl "$DJX_HOLD" "${FELIX_TEST_NO_MANIFEST:-0}" "$DJX_DIR"
: "$djx_unbound_variable_zz"
ok "djx setu after"
X
_db3_rf setu "$DB3/g-empty.tsv" "a part that dies on an unbound variable under set -u" "part did not finish: 0020-pb.sh" "part ended without its mark: 0020-pb.sh"
_db3_mk reached <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx reached"
[ -z "${DJX_HOLD:-}" ] || perl "$DJX_HOLD" "${FELIX_TEST_NO_MANIFEST:-0}" "$DJX_DIR"
printf 'reached\n'
X
_db3_pr7() { is "$_db3_postn" "$(_db3_line "$_db3_c/p.out" '  | reached') $([ "$(_db3_line "$_db3_c/p.out" reached)" -le 1 ] && echo one-or-none || echo two)" "1 one-or-none"; }
_db3_post=_db3_pr7; _db3_postn="R7: a part's own reached line is printed in its place as a bar line, once, and reads as no completion marker"
_db3_rf reached "$DB3/g-empty.tsv" "a part that prints reached" "part printed a line the runner owns: 0020-pb.sh" "!part did not finish" "!part ended without its mark"
_db3_mk forged <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
[ -z "${DJX_HOLD:-}" ] || perl "$DJX_HOLD" "${FELIX_TEST_NO_MANIFEST:-0}" "$DJX_DIR"
printf '@@prelude-done\n'
X
printf '%s\n' 'printf "\ndjx-sec 0030-pc.sh\n"' 'printf "@@member-done 0030-pc.sh\n"' > "$DB3/pp/forged/0030-pc.sh"
printf '%s\n' 'printf "\ndjx-sec 0040-pd.sh\n"' 'printf "@@part-done 0040-pd.sh\n"' > "$DB3/pp/forged/0040-pd.sh"
_db3_rf forged "$DB3/g-empty.tsv" "parts that print a runner line (a second @@prelude-done, a forged @@member-done, a forged @@part-done)" \
   "part printed a line the runner owns: 0020-pb.sh" "part printed a line the runner owns: 0030-pc.sh" "part printed a line the runner owns: 0040-pd.sh" \
   "!part printed a line the runner owns: 0010-pa.sh"
mkdir -p "$DB3/pp/gdie"; printf 'grp\t0010-ga.sh\ngrp\t0020-gb.sh\ngrp\t0030-gc.sh\n' > "$DB3/g-grp.tsv"
printf '%s\n' 'printf "\ndjx-sec 0010-ga.sh\n"' 'ok "djx gdie a"' > "$DB3/pp/gdie/0010-ga.sh"
printf '%s\n' 'printf "\ndjx-sec 0020-gb.sh\n"' 'ok "djx gdie b"' '[ -z "${DJX_HOLD:-}" ] || perl "$DJX_HOLD" "${FELIX_TEST_NO_MANIFEST:-0}" "$DJX_DIR"' 'kill -9 $$' > "$DB3/pp/gdie/0020-gb.sh"
printf '%s\n' 'printf "\ndjx-sec 0030-gc.sh\n"' 'ok "djx gdie c"' > "$DB3/pp/gdie/0030-gc.sh"
_db3_rf gdie "$DB3/g-grp.tsv" "a group member that dies" "part did not finish: 0020-gb.sh" "part did not finish: 0030-gc.sh" \
   "part ended without its mark: grp" "!part did not finish: 0010-ga.sh"
_db3_mk partial <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
[ -z "${DJX_HOLD:-}" ] || perl "$DJX_HOLD" "${FELIX_TEST_NO_MANIFEST:-0}" "$DJX_DIR"
printf 'djx partial text'
bad "djx lands on a partial line"
X
_db3_rf partial "$DB3/g-empty.tsv" "a part whose bad line lands on a partial line" "part failed more than it printed: 0020-pb.sh" "!part did not finish"
_db3_mk trap5 <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx trap5"
[ -z "${DJX_HOLD:-}" ] || perl "$DJX_HOLD" "${FELIX_TEST_NO_MANIFEST:-0}" "$DJX_DIR"
trap 'rm -rf "$TMP"; exit 5' EXIT
X
_db3_pt5() {
  local n1="${_db3_postn%%$'\n'*}" n2="${_db3_postn#*$'\n'}"
  is "$n2" "$(LC_ALL=C awk -v a="  FAIL  part process ended with status 5: 0020-pb.sh" -v u="  FAIL  part left the shell changed for the parts after it: 0020-pb.sh" '
      $0 == a { na++; ia = NR } $0 == u { nu++; iu = NR; on = 1; next }
      on && index($0, "  | ") == 1 { b = b substr($0, 5) "|"; next } { on = 0 }
      END { print na + 0, nu + 0, (ia && iu > ia) ? "after" : "not-after", b }' "$_db3_c/p.out")" "1 1 after trap on EXIT changed|"
  _db3_run t1 -j 1; is "$n1" "$_db3_rc $_db3_cl" "5 ok"
}
_db3_post=_db3_pt5; _db3_postn="D3: the part that replaces the EXIT trap with one that exits 5 makes a -j 1 run exit 5 (control)
R16: and under -j 3 the status-5 failure is followed by the seventh failure of that unit, and its one bar line is trap on EXIT changed"
_db3_rf trap5 "$DB3/g-empty.tsv" "a part that replaces the EXIT trap with one that removes \$TMP and exits 5" \
   "part process ended with status 5: 0020-pb.sh" "part left the shell changed for the parts after it: 0020-pb.sh" "!part did not finish" "!part ended without its mark"
# The units' preludes alone. The copy's 0006 gets a line that does nothing the first time it runs, in the parent's prelude, which makes a marker file,
# and does PLANT in every prelude after it, the units'. Each unit's prelude lines are then printed behind a bar, so none reads as an assertion.
_db3_plant() {   # PLANT: the copy's 0006 runs PLANT only where the marker file exists
  local f; for f in "$_db3_T"/parts/0006-*.sh; do printf '\nif [ -e "%s" ]; then %s; %s; else : > "%s"; fi\n' "$_db3_c/pre.marker" "$_db3_HL" "$1" "$_db3_c/pre.marker" >> "$f"; done
}
mkdir -p "$DB3/pp/pre"; cp "$DB3/pp/std"/*.sh "$DB3/pp/pre/"
_db3_h6() { _db3_plant 'bad "djx planted prelude failure"'; }
_db3_pp6() { is "$_db3_postn" "$(_db3_line "$_db3_c/p.out" '  |   FAIL  djx planted prelude failure') $(_db3_line "$_db3_c/p.out" '  FAIL  djx planted prelude failure')" "3 0"; }
_db3_hook=_db3_h6; _db3_post=_db3_pp6; _db3_postn="D3: the lines of a failed prelude follow its runner line, each behind two spaces, a bar and a space, so none reads as an assertion"
_db3_rf pre "$DB3/g-empty.tsv" "a FAIL in the units' prelude only" "part's prelude failed: 0010-pa.sh" "part's prelude failed: 0020-pb.sh" "part's prelude failed: 0030-pc.sh"
mkdir -p "$DB3/pp/prp"; cp "$DB3/pp/std"/*.sh "$DB3/pp/prp/"
_db3_h7() { _db3_plant 'printf "djx-partial"; bad "djx planted partial prelude failure"'; }
_db3_pp7() { is "$_db3_postn" "$(_db3_cnt "$_db3_c/p.out" '  | djx-partial  FAIL  djx planted partial prelude failure')" 3; }
_db3_hook=_db3_h7; _db3_post=_db3_pp7; _db3_postn="R7: and the prelude lines it prints are behind a bar, the FAIL that landed on a partial line among them"
_db3_rf prp "$DB3/g-empty.tsv" "a FAIL printed onto a partial line in the units' prelude only" \
   "part's prelude failed: 0010-pa.sh" "part's prelude failed: 0020-pb.sh" "part's prelude failed: 0030-pc.sh" "!part failed more than it printed"
mkdir -p "$DB3/pp/prk"; cp "$DB3/pp/std"/*.sh "$DB3/pp/prk/"
_db3_hk() { _db3_plant 'printf "djx-prekill\n"; kill -9 $$'; }
_db3_pk() { is "$_db3_postn" "$(_db3_cnt "$_db3_c/p.out" '  | djx-prekill')" 3; }
_db3_hook=_db3_hk; _db3_post=_db3_pk; _db3_postn="D3: and a unit that dies in its prelude, with no @@prelude-done at all, prints the lines it wrote behind a bar"
_db3_rf prk "$DB3/g-empty.tsv" "a unit that dies in its prelude, before @@prelude-done" \
   "part's prelude failed: 0010-pa.sh" "part's prelude failed: 0020-pb.sh" "part's prelude failed: 0030-pc.sh" "part ended without its mark: 0020-pb.sh"
# Does a top-level a[1/0]=1 end a sourced file and the rest of the line that sourced it, in this bash? Measured in a child of it.
printf 'echo S1\na[1/0]=1\necho S2\n' > "$DB3/cut.sh"; printf '. "%s"; echo SAMELINE\necho NEXTLINE\n' "$DB3/cut.sh" > "$DB3/cut.drv"
_db3_m="$("$BASH" "$DB3/cut.drv" 2>/dev/null | tr '\n' ' ')"
mkdir -p "$DB3/pp/acut"; printf 'acut\t0010-ka.sh\nacut\t0020-kb.sh\nacut\t0030-kc.sh\n' > "$DB3/g-acut.tsv"
printf '%s\n' 'printf "\ndjx-sec 0010-ka.sh\n"' 'ok "djx acut a"' > "$DB3/pp/acut/0010-ka.sh"
printf '%s\n' 'printf "\ndjx-sec 0020-kb.sh\n"' 'ok "djx acut b before"' '[ -z "${DJX_HOLD:-}" ] || perl "$DJX_HOLD" "${FELIX_TEST_NO_MANIFEST:-0}" "$DJX_DIR"' 'a[1/0]=1' 'ok "djx acut b after"' > "$DB3/pp/acut/0020-kb.sh"
printf '%s\n' 'printf "\ndjx-sec 0030-kc.sh\n"' 'ok "djx acut c"' > "$DB3/pp/acut/0030-kc.sh"
_db3_pcut() { is "$_db3_postn" "$(_db3_line "$_db3_c/p.out" '  ok    djx acut c') $(_db3_line "$_db3_c/p.out" '  ok    djx acut b after')" "1 0"; }
_db3_post=_db3_pcut; _db3_postn="D2: and the member after it ran, as the next part line does in a serial run"
[ "$_db3_m" = "S1 NEXTLINE " ] || _db3_skip="this bash does not end a sourced file and the rest of its line there (it printed [$_db3_m])"
_db3_rf acut "$DB3/g-acut.tsv" "a member whose sourcing a top-level a[1/0]=1 cuts short, while later members run" \
   "part did not finish: 0020-kb.sh" "!part did not finish: 0010-ka.sh" "!part did not finish: 0030-kc.sh" "!part ended without its mark"
_db3_mk arith <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx arith before"
x=$((1/0))
ok "djx arith after"
X
_db3_new arith "$DB3/g-empty.tsv" "$DB3/pman.tsv" "$DB3/pp/arith"/*.sh; _db3_run a3 -j 3; _db3_run a1 -j 1
_db3_x="$(LC_ALL=C diff <(grep -E '^  (ok    |FAIL  |skip  )' "$_db3_c/a3.out" | LC_ALL=C sort) <(grep -E '^  (ok    |FAIL  |skip  )' "$_db3_c/a1.out" | LC_ALL=C sort) | head -4 | tr '\n' '|')"
is "D2: a top-level x=\$((1/0)) between two assertions gives the same (verdict, name) lines under -j 3 as under -j 1, the -j 3 run counted from lines" \
   "${_db3_x:-same} $(_db3_last a3 | grep -c ' (counted from lines)$')" "same 1"
rm -rf "$DB3/n/arith"

# ---- a runner failure in red's suite only (D4, R8): red leaves the runner's lines out of its counts and names, and refuses a log it cannot trust
# The part dies, prints reached or leaves the shell changed only where FELIX_TEST_NO_MANIFEST=1, which only red's suite sees. The record run itself passes.
_db3_pfx=("part's prelude failed: " "part did not finish: " "part ended without its mark: " "part process ended with status " "part failed more than it printed: " "part printed a line the runner owns: " "part left the shell changed for the parts after it: ")
_db3_ro() {   # CASE BODY: pp/CASE's 0020 does BODY in red's suite only; a -j 3 record run in a --red copy
  local n="$1"; mkdir -p "$DB3/pp/$n"; cp "$DB3/pp/std/0010-pa.sh" "$DB3/pp/std/0030-pc.sh" "$DB3/pp/$n/"
  printf 'printf "\\ndjx-sec 0020-pb.sh\\n"\nok "djx b1"\n[ "${FELIX_TEST_NO_MANIFEST:-0}" != 1 ] || { %s; }\nok "djx b2"\n' "$2" > "$DB3/pp/$n/0020-pb.sh"
  _db3_new "$n" --red "$DB3/g-empty.tsv" "$DB3/man.tsv" "$DB3/pp/$n"/*.sh && _db3_run r -j 3 --record-assertions
}
_db3_rt() {   # red.tsv's name rows: how many, their failed counts added, the run row's failed count, djx b2's, how many start with a runner prefix
  P="$(printf '%s\n' "${_db3_pfx[@]}")" LC_ALL=C awk -F'\t' 'BEGIN { np = split(ENVIRON["P"], P, "\n") }
    /^#/ || $1 == "base" { next }
    $1 == "run" { f = $2; next }
    { n++; s += $2; if ($1 == "djx b2") b = $2; for (i = 1; i <= np; i++) if (P[i] != "" && index($1, P[i]) == 1) q++ }
    END { print n + 0, s + 0, f + 0, b + 0, q + 0 }' "$_db3_T/red.tsv" 2>/dev/null
}
_db3_ro rdie 'kill -9 $$'
read -r _db3_n _db3_s _db3_f _db3_b _db3_q <<< "$(_db3_rt)"
is "D4: a unit that dies in red's suite only: the record run exits 0, no process is left, and red.tsv counts the run with name rows that add up to its failed count" \
   "$_db3_rc $_db3_cl $([ "$_db3_n" -gt 0 ] && [ "$_db3_s" = "$_db3_f" ] && echo adds-up || echo "rows $_db3_n sum $_db3_s run $_db3_f")" "0 ok adds-up"
is "D4: and no name row starts with one of the runner's seven failure prefixes, and djx b2, which the dead unit never reached, is named by its shortfall of one" "$_db3_q $_db3_b" "0 1"
rm -rf "$DB3/n/rdie"
_db3_ro rrch 'printf "reached\n"'
is "D4: a unit that prints reached in red's suite only makes red refuse the log, the record run having passed: red.tsv holds the rows base - - - and run - - -" \
   "$_db3_rc $_db3_cl $(_db3_redrows)" "0 ok $(printf 'base\t-\t-\t-|run\t-\t-\t-|')"
rm -rf "$DB3/n/rrch"
_db3_ro rshl 'umask 077'
read -r _db3_n _db3_s _db3_f _db3_b _db3_q <<< "$(_db3_rt)"
_db3_x="$(_db3_redrows)"; case "$_db3_x" in base$'\t'origin/main$'\t'*run$'\t'[0123456789]*) _db3_x=counts ;; esac
is "R8: a unit that leaves the shell changed in red's suite only is left out of red's counts and names, and red does not refuse the log: red.tsv counts the run with no failure and no name row" \
   "$_db3_rc $_db3_cl $_db3_n $_db3_f $_db3_x" "0 ok 0 0 counts"
rm -rf "$DB3/n/rshl"

# ---- red acts on a failed mark while its suite runs (R1): the record run's runner failure, with a part in red's suite that sleeps 90 s
# 0020 sleeps only where FELIX_TEST_NO_MANIFEST=1, which only red's suite sees, and writes the millisecond it starts to sleep into a file; 0030 dies only in
# the record run, which fails it, and first waits (60 s at most, since red's base checkout and its units' preludes can take longer than the record run's
# own under load) for that file, so the failure always comes while red's suite sleeps. The record run must
# not wait for red's suite (nor for the bound it gives red, 60 s): red ends its suite on the mark, so it exits within 30 s of the sleeper's start.
mkdir -p "$DB3/pp/rsl"; cp "$DB3/pp/std/0010-pa.sh" "$DB3/pp/rsl/"
cat > "$DB3/pp/rsl/0020-pb.sh" <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx b1"
[ "${FELIX_TEST_NO_MANIFEST:-0}" != 1 ] || { perl -MTime::HiRes=time -e 'printf "%d\n", time * 1000' > "$DJX_DIR/slept.$$"; sleep 90; }
ok "djx b2"
X
cat > "$DB3/pp/rsl/0030-pc.sh" <<'X'
printf '\ndjx-sec 0030-pc.sh\n'
ok "djx c1"
if [ "${FELIX_TEST_NO_MANIFEST:-0}" != 1 ]; then
  djx_i=0; while [ -z "$(ls "$DJX_DIR"/slept.* 2>/dev/null)" ] && [ "$djx_i" -lt 300 ]; do sleep 0.2; djx_i=$((djx_i + 1)); done
  kill -9 $$
fi
ok "djx c2"
X
_db3_new rsl --red "$DB3/g-empty.tsv" "$DB3/man.tsv" "$DB3/pp/rsl"/*.sh
_db3_start r -j 3 --record-assertions; _db3_wait; _db3_t1="$(_db3_ms)"; _db3_ex="$(_db3_atexit)"; _db3_cl="$(_db3_clean)"
[ "$_db3_cl" = ok ] || _db3_leak="$_db3_leak [$_db3_c: $_db3_cl]"
_db3_t0="$(cat "$_db3_c"/slept.* 2>/dev/null | sed -n 1p)"
case "$_db3_t0" in ""|*[!0123456789]*) _db3_x="red's suite never reached the sleeper" ;; *) _db3_x="$([ $((_db3_t1 - _db3_t0)) -lt 30000 ] && echo within-30s || echo "took $((_db3_t1 - _db3_t0)) ms")" ;; esac
is "R1: a record run with a runner failure, while red's suite sleeps 90 s in a part, exits 1 within 30 s of the sleep's start, writes no manifest, and red.tsv holds the rows base - - - and run - - -" \
   "$(_db3_chkr r "part did not finish: 0030-pc.sh" "part ended without its mark: 0030-pc.sh") $_db3_x" "ok within-30s"
is "R1: and once it has exited nothing of its group is left, stopped or running: the sleeper of red's suite is gone, red's tree with it" "$_db3_ex $_db3_cl" "ok ok"
rm -rf "$DB3/n/rsl"

# ---- a TERM sent to a stopper of red's tree while it stops, between its STOP and its KILL (R27, R2's ignore where it can be seen; R32, R33)
# Red ends its suite, and a stopper that ends a tree with a TERM-ignoring unit in it is not to be ended itself half way: red's monitor (after a record run's
# runner failure) and the record run's watcher (after the record run is killed with kill -9). Each case plants, in red's suite only
# (FELIX_TEST_NO_MANIFEST=1), a unit that makes the file trig and the file slept.PID (the millisecond it starts), and turns into a perl that ignores TERM and forks
# a "sleep 1" each second. A ps put first on PATH (psh/ps) is the real ps until trig exists. Once it does, the shim finds the stopper as its own grandparent
# (its parent is the $( ) that runs the listing, and that one's parent runs the steps) and counts the stopper's "ps -A ... ppid=" listings: the 2nd is delayed
# 1.5 s, so that step 4's first round finds a new sleep and adds a member, which makes a 2nd round, and the 3rd, that 2nd round's listing, falls between the
# STOP and the KILL: it is held (15 s at most) until the case has sent that stopper a TERM, and the shim names the stopper's pid in the file held first. The
# case counts the stopped processes of the group as it sends the TERM (one that lands after the KILL pins nothing, so no stopped process fails the case), and
# sends it only to a pid whose command line is red's or a record run's. A stopper that does not ignore TERM dies there, leaving what it had stopped stopped.
# Which listings are the stopper's (R33): only one whose parent is a $( ) subshell of the stopper, which keeps its parent's command line, so the parent's
# command line is the grandparent's. A holder lists through perl's backticks, which run /bin/sh -c: on ubuntu /bin/sh is dash, which execs the listing's ps in
# place, so its parent is the holder's perl (its own command line) and its grandparent a wrapper, a fork of the record run with the record run's command line,
# which a test of the grandparent alone takes for the watcher's stopper. Under macOS's /bin/sh (bash 3.2) the parent is the sh, so no shell makes the shim wrong.
# In the watcher case the shim also holds, until the TERM has been sent (100 s at most), every listing that a process of red's tree makes (its callers are red,
# its monitor, its suite's own parent), so that red's own stoppers cannot end the tree within the 30 s the watcher's stopper waits for red, which would leave
# that stopper nothing to stop. Measured on this build: the monitor is red's child with red's command line, and so is the subshell that runs _rcp_stop.
# In the monitor case it holds, until the TERM has been sent (75 s at most), every listing made by a process of red's suite (R32): one whose caller's command
# line is not red's (the -j parent, a holder, a wrapper), so that the suite's own ending stops nothing before the monitor's STOP. What each bash does matters
# there: red starts its suite as ( cd "$TREE" && ... bash run -j N ) &. Bash 3.2 forks for the last command, so SUITE (the monitor's root) is that subshell,
# which dies at the monitor's TERM, and the -j parent is its child, in its own ending with a TERM-ignoring unit under it. Bash 5.2 runs the last command in
# place, so SUITE is the -j parent itself: it lives through the monitor's wait for its root, and its own ending (TERM to the unit, a 10 s wait for it, then
# STOP and KILL) would end the unit about when that wait ends, before the monitor's second listing finds the new sleep (CI's ubuntu run gave stopped=0). With
# the hold the -j parent's ending cannot get past its first listing until the TERM has been sent, on either bash. Checked here by a copy whose red execs bash there.
mkdir -p "$DB3/psh"
cat > "$DB3/psh/ps" <<'DB3PSH'
#!/bin/sh
case " $* " in *" -A "*ppid=*) ;; *) exec "$DJX_PSREAL" "$@" ;; esac
[ -e "$DJX_DIR/trig" ] || exec "$DJX_PSREAL" "$@"
R="$DJX_PSREAL"
gp=$("$R" -o ppid= -p "$PPID" 2>/dev/null); gp=$(echo $gp)
[ -n "$gp" ] || exec "$R" "$@"
gc=$("$R" -o command= -p "$gp" 2>/dev/null)
pc0=$("$R" -o command= -p "$PPID" 2>/dev/null)
inred=0; a=$gp; i=0
while [ "$i" -lt 8 ] && [ -n "$a" ] && [ "$a" -gt 1 ] 2>/dev/null; do
  c=$("$R" -o command= -p "$a" 2>/dev/null)
  case "$c" in *tests/red\ --after*) inred=1; break ;; esac
  a=$("$R" -o ppid= -p "$a" 2>/dev/null); a=$(echo $a); i=$((i + 1))
done
case "$gc" in *tests/run\ -j\ 3) inred=1 ;; esac
hold() { i=0; while [ ! -e "$DJX_DIR/$1" ] && [ "$i" -lt "$2" ]; do sleep 0.2; i=$((i + 1)); done; }
stopper=0
case "$DJX_MODE" in
  mon) if [ "$inred" = 1 ]; then
         case "$gc" in
           *tests/red\ --after*) pp=$("$R" -o ppid= -p "$gp" 2>/dev/null); pc=$("$R" -o command= -p "$(echo $pp)" 2>/dev/null)
             case "$pc" in *tests/red\ --after*) stopper=1 ;; esac ;;
           *) hold termsent 375 ;;
         esac
       fi ;;
  wat) if [ "$inred" = 1 ]; then hold release 500
       else case "$gc" in *--record-assertions*) [ "$pc0" != "$gc" ] || stopper=1 ;; esac; fi ;;
esac
if [ "$stopper" = 1 ]; then
  echo x >> "$DJX_DIR/cnt.$gp"; n=$(wc -l < "$DJX_DIR/cnt.$gp"); n=$(echo $n)
  case "$n" in
    2) sleep 1.5 ;;
    3) echo "$gp" > "$DJX_DIR/held.tmp"; mv "$DJX_DIR/held.tmp" "$DJX_DIR/held"; hold termsent 75; sleep 0.5 ;;
  esac
fi
exec "$R" "$@"
DB3PSH
chmod +x "$DB3/psh/ps"
# the planted parts: 0010 passes; 0020 does the above in red's suite only; 0030 waits for the sleeper (60 s at most) and dies, in the record run only
# (CASE=mon), or sleeps 100 s there, so that the case can kill the record run (CASE=wat)
mkdir -p "$DB3/pp/r27"; cp "$DB3/pp/std/0010-pa.sh" "$DB3/pp/r27/"
cat > "$DB3/pp/r27/0020-pb.sh" <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx b1"
if [ "${FELIX_TEST_NO_MANIFEST:-0}" = 1 ]; then
  : > "$DJX_DIR/trig"
  perl -MTime::HiRes=time -e 'printf "%d\n", time * 1000' > "$DJX_DIR/slept.$$"
  exec perl -e '$SIG{TERM} = "IGNORE"; while (1) { system("sleep", "1") }'
fi
ok "djx b2"
X
cat > "$DB3/pp/r27/0030-pc.sh" <<'X'
printf '\ndjx-sec 0030-pc.sh\n'
ok "djx c1"
if [ "${FELIX_TEST_NO_MANIFEST:-0}" != 1 ]; then
  djx_i=0; while [ -z "$(ls "$DJX_DIR"/slept.* 2>/dev/null)" ] && [ "$djx_i" -lt 300 ]; do sleep 0.2; djx_i=$((djx_i + 1)); done
  [ "$DJX_MODE" != wat ] || sleep 100
  kill -9 $$
fi
ok "djx c2"
X
# R12's bound is 30 s; the watcher's stopper waits 30 s for red on its own, so the watcher case waits up to 90 s for its group to be empty, and then R12's check
_db3_emptyby() { local g i=0; g="$(_db3_gs)"; [ -n "${g// /}" ] || return 0; while [ "$i" -lt "$(($1 * 5))" ]; do [ -z "$(_db3_gm $g)" ] && return 0; sleep 0.2; i=$((i + 1)); done; return 1; }
# the controller: waits (80 s at most, and while the group lives) for the stopper's pid in held, counts the group's stopped processes, sends that pid TERM (once
# its command line is red's or a record run's), and writes termsent and release; with the argument wat it first waits for the sleeper and kills the record run, by the
# pid the runner wrote
_db3_ctl27() {
  local i=0 p c g n
  while [ ! -s "$_db3_c/r.pid" ] && [ "$i" -lt 50 ]; do sleep 0.1; i=$((i + 1)); done
  g="$(_db3_gs)"
  if [ "$1" = wat ]; then
    while [ -z "$(ls "$_db3_c"/slept.* 2>/dev/null)" ] && [ "$i" -lt 400 ]; do sleep 0.2; i=$((i + 1)); done
    p="$(cat "$_db3_c/r.pid" 2>/dev/null)"; c="$(ps -o command= -p "$p" 2>/dev/null)"
    case "$c" in *--record-assertions*) kill -KILL "$p" 2>/dev/null ;; esac
  fi
  i=0; while [ ! -s "$_db3_c/held" ] && [ "$i" -lt 400 ]; do
    sleep 0.2; i=$((i + 1)); [ $((i % 5)) -ne 0 ] || [ -n "$(_db3_gm $g)" ] || break
  done
  [ -s "$_db3_c/held" ] || { echo none > "$_db3_c/ctl.res"; : > "$_db3_c/termsent"; : > "$_db3_c/release"; return 0; }
  p="$(cat "$_db3_c/held")"
  n="$(ps -A -o pid= -o pgid= -o stat= 2>/dev/null | G=" $g " LC_ALL=C awk 'index(ENVIRON["G"], " " $2 " ") && $3 ~ /^T/ { n++ } END { print n + 0 }')"
  c="$(ps -o command= -p "$p" 2>/dev/null)"
  case "$c" in *tests/red\ --after*|*--record-assertions*) kill -TERM "$p" 2>/dev/null; echo "stopped=$n" > "$_db3_c/ctl.res" ;; *) echo "not-the-stopper=$c" > "$_db3_c/ctl.res" ;; esac
  : > "$_db3_c/termsent"; : > "$_db3_c/release"
}
# CASE MODE: the copy of pp/r27 as a record run in a --red copy, the shim first on PATH, the controller beside it. In mode mon the run ends by itself, and its
# processes are looked for at once (R1); in mode wat the record run is killed, red's tree outlives it by the 30 s its stopper waits, and the group is waited for.
_db3_r27() {
  _db3_new "$1" --red "$DB3/g-empty.tsv" "$DB3/man.tsv" "$DB3/pp/r27"/*.sh || return 1
  _db3_E=(DJX_PSREAL="$(command -v ps)" PATH="$DB3/psh:$PATH" DJX_MODE="$2")
  _db3_start r -j 3 --record-assertions
  _db3_ctl27 "$2" & _db3_cp=$!
  _db3_wait; _db3_t1="$(_db3_ms)"
  { wait "$_db3_cp"; } 2>/dev/null
  _db3_t0="$(cat "$_db3_c"/slept.* 2>/dev/null | sed -n 1p)"
  if [ "$2" = mon ]; then _db3_ex="$(_db3_atexit)"; else _db3_emptyby 90; _db3_ex=ok; fi
  _db3_cl="$(_db3_clean)"
  [ "$_db3_cl" = ok ] || _db3_leak="$_db3_leak [$_db3_c: $_db3_cl]"
  _db3_res="$(cat "$_db3_c/ctl.res" 2>/dev/null)"
  case "$_db3_res" in
    stopped=0|"") _db3_w="no stopped process when the TERM was sent [$_db3_res]" ;;
    stopped=*) _db3_w=between-stop-and-kill ;;
    none) _db3_w="the stopper never made a third listing, so no TERM reached it between its STOP and its KILL" ;;
    *) _db3_w="[$_db3_res]" ;;
  esac
}
_db3_c27m() {
  _db3_r27 r27m mon
  case "$_db3_t0" in ""|*[!0123456789]*) _db3_x="red's suite never reached the sleeper" ;; *) _db3_x="$([ $((_db3_t1 - _db3_t0)) -lt 45000 ] && echo within-45s || echo "took $((_db3_t1 - _db3_t0)) ms")" ;; esac
  is "R32: a TERM sent to red's monitor between its STOP and its KILL, while it stops a suite whose unit ignores TERM (the suite's own ending held, so it stops nothing first, as red's suite is a fork on bash 3.2 and the -j parent itself on 5.2), changes nothing: the record run exits within 45 s of the sleeper's start, not after the 60 s it gives red, and the TERM landed with processes stopped" \
     "$_db3_x $_db3_w" "within-45s between-stop-and-kill"
  is "R32: and red.tsv holds the rows base - - - and run - - -, the manifest is as it was, and nothing of the group is left, stopped or running" "$(_db3_chkr r "part did not finish: 0030-pc.sh" "part ended without its mark: 0030-pc.sh") $_db3_ex $_db3_cl" "ok ok ok"
  rm -rf "$DB3/n/r27m"
}
_db3_c27w() {
  _db3_r27 r27w wat
  is "R33: a TERM sent to the subshell that runs the record run's watcher's _rcp_stop steps (found as the parent of a listing's parent, whatever /bin/sh does with a holder's listing), between their STOP and their KILL, while the record run (killed with kill -9) leaves red's suite to it, changes nothing: the TERM landed with processes stopped, and the group is empty within 90 s, none left stopped" \
     "$_db3_w $_db3_ex $_db3_cl" "between-stop-and-kill ok ok"
  rm -rf "$DB3/n/r27w"
}
_db3_c27m
_db3_c27w

# ---- the end of a -j run whose parent cannot read its job table (R30): no KILL by pid, and the FIFO closed before the wait for the ticker
# The parent reads its job table through a file of its own, $TMP/pj/jobs (the contract names it: `builtin jobs -rp` written there, and a read that fails when
# that path cannot be written). A unit is sourced in a shell that keeps its log as $_pm_log, the parent's $TMP/pj/log.N, so ${_pm_log%/*}/jobs is that file: the
# planted part replaces it with a directory (rm -f, then mkdir, again if the parent wrote the file in between), sleeps 10 s, which is 2W for
# FELIX_TEST_SLOT_NOTE=5, so that at least one tick's read fails while the unit runs, writes the millisecond it ends and passes. The run (-j 2, slots for all)
# must exit 0 within 15 s of that time, and leave nothing, the ticker included: with the table unreadable at the loop's end the parent sends the ticker no KILL
# by pid (it may be another process's), so it ends only because the parent closes the FIFO first, and its next write then fails. A parent that closes the FIFO
# after its wait for the ticker waits for ever; the runner's bound (150 s) ends it as 124.
_db3_mk jtab <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx jt before"
djx_d="${_pm_log:-}"; djx_d="${djx_d%/*}"; djx_i=0
if [ -n "${_pm_log:-}" ]; then
  while [ ! -d "$djx_d/jobs" ] && [ "$djx_i" -lt 50 ]; do rm -f "$djx_d/jobs"; mkdir "$djx_d/jobs" 2>/dev/null; djx_i=$((djx_i + 1)); done
  [ ! -d "$djx_d/jobs" ] || : > "$DJX_DIR/jobsdir.ok"
fi
sleep 10
perl -MTime::HiRes=time -e 'printf "%d\n", time * 1000' > "$DJX_DIR/jt.end"
ok "djx jt after"
X
_db3_new jtab "$DB3/g-empty.tsv" - "$DB3/pp/jtab"/*.sh
_db3_E=(FELIX_TEST_SLOT_NOTE=5)
_db3_start t -j 2; _db3_wait; _db3_t1="$(_db3_ms)"; _db3_ex="$(_db3_atexit)"; _db3_cl="$(_db3_clean)"
[ "$_db3_cl" = ok ] || _db3_leak="$_db3_leak [$_db3_c: $_db3_cl]"
_db3_t0="$(sed -n 1p "$_db3_c/jt.end" 2>/dev/null)"
case "$_db3_t0" in ""|*[!0123456789]*) _db3_x="the part never reached its end" ;; *) _db3_x="$([ $((_db3_t1 - _db3_t0)) -lt 15000 ] && echo within-15s || echo "took $((_db3_t1 - _db3_t0)) ms")" ;; esac
is "R30: a -j 2 run whose parent cannot read its job table at the end of its loop (the unit made \$TMP/pj/jobs a directory) exits 0 within 15 s of the unit's end, the ticker's wait not hanging, and the unit's directory was made" \
   "$_db3_rc $_db3_x $([ -e "$_db3_c/jobsdir.ok" ] && echo planted || echo not-planted)" "0 within-15s planted"
is "R30: and it leaves nothing of its group, stopped or running, the ticker included" "$_db3_ex $_db3_cl" "ok ok"
rm -rf "$DB3/n/jtab"

# ---- the parent's own state under -j N (D3): a failure the parent alone makes is not lost when the units end well
# The copy's 0006 does nothing in a unit's prelude (the marker is there) and, in the parent's only, fails an assertion, plants a refusal record, and moves
# the origin's config (newer than the guard's stamp, so the next assertion sees it) and puts it back: put back is not unmoved.
mkdir -p "$DB3/pp/par"; cp "$DB3/pp/std"/*.sh "$DB3/pp/par/"
_db3_n9a="no fixture git command was refused for a directory outside the suite's temporary directory"
_db3_n9b="fixture floor: at the end of the suite it still stands in cwd inside its temporary directory, under a ceiling at that directory's parent"
_db3_n9c="the remotes of the checkout this run started in did not move while it ran"
# each of the three names the cases below read is one 9990 prints: "missing" and the name for one that is not (a name that is not 9990's would make its case read a FAIL that never comes)
_db3_x=""; for _db3_n in "$_db3_n9a" "$_db3_n9b" "$_db3_n9c"; do grep -qF -e "$_db3_n" "$HERE"/parts/9990-*.sh || _db3_x="$_db3_x missing [$_db3_n]"; done
is "D3: the three 9990 names the cases below read are 9990's (control)" "${_db3_x:-ok}" ok
_db3_parent() {
  local f m="$_db3_c/par.marker"
  for f in "$_db3_T"/parts/0006-*.sh; do
    printf '\nif [ ! -e "%s" ]; then : > "%s"; bad "djx parent-only prelude failure"; printf "djx planted refusal\\n" >> "$FELIX_TEST_FXREFUSED"\n' "$m" "$m" >> "$f"
    printf '  cp -p "$DJX_CFG" "$DJX_DIR/cfg.save"; printf "[remote \\"djxmoved\\"]\\n\\turl = /djx/moved\\n" >> "$DJX_CFG"; touch -t 203001010000 "$DJX_CFG"\n  ok "djx tick"; cp -p "$DJX_DIR/cfg.save" "$DJX_CFG"\nfi\n' >> "$f"
  done
}
_db3_new par "$DB3/g-empty.tsv" "$DB3/pman.tsv" "$DB3/pp/par"/*.sh; _db3_parent; _db3_run q3 -j 3; _db3_q3="$(_db3_chk q3 "djx parent-only prelude failure" "$_db3_n9a" "$_db3_n9c" "!part " '#3') $_db3_cl"
rm -f "$_db3_c/par.marker"; _db3_run q1 -j 1; _db3_q1="$(_db3_chk q1 "djx parent-only prelude failure" "$_db3_n9a" "$_db3_n9c" '#3') $_db3_cl"
is "D3: a failure, a refusal record and a moved origin made in the parent's prelude alone give three FAILs under -j 3, each once, with no runner failure, exit 1, three in the summary and no receipt" "$_db3_q3" "ok ok"
is "D3: and under -j 1, where one shell runs everything, the same three (control)" "$_db3_q1" "ok ok"
rm -rf "$DB3/n/par"

# ---- assertion failures (D3, D4): their own FAIL, exit 1, and the manifest written as -j 1 writes it
_db3_af() {   # CASE DESC FAILNAME: pp/CASE under -j 3: that FAIL once, no runner failure, exit 1, no receipt; and the record run's manifest is -j 1's
  local n="$1" d="$2" w="$3" a b
  _db3_new "$n" "$DB3/g-empty.tsv" "$DB3/pman.tsv" "$DB3/pp/$n"/*.sh; _db3_run p -j 3
  a="$(_db3_chk p "$w" "!part " '#1')"
  is "D3: $d gives its own FAIL, no runner failure, exit 1, no receipt and no process" "$a $_db3_cl" "ok ok"
  rm -rf "$DB3/n/$n"; _db3_new "$n-r" --red "$DB3/g-empty.tsv" "$DB3/man.tsv" "$DB3/pp/$n"/*.sh
  _db3_run r -j 3 --record-assertions; a="$_db3_rc $_db3_cl"; b="$(cat "$_db3_T/assertions.tsv")"
  cp "$DB3/man.tsv" "$_db3_T/assertions.tsv"; _db3_run r1 -j 1 --record-assertions
  is "D4: $d in a -j 3 record run exits 1 and writes the manifest -j 1 writes (not the old one)" \
     "$a $([ "$b" = "$(cat "$_db3_T/assertions.tsv")" ] && [ "$b" != "$(cat "$DB3/man.tsv")" ] && echo same || echo differ)" "1 ok same"
  rm -rf "$DB3/n/$n-r"
}
_db3_mk afail <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx afail one"
bad "djx afail fails"
ok "djx afail two"
X
_db3_af afail "a failing assertion" "djx afail fails"
_db3_mk arefuse <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
printf 'djx planted refusal line\n' >> "$FELIX_TEST_FXREFUSED"
ok "djx arefuse one"
X
_db3_af arefuse "a refusal record planted in a unit" "$_db3_n9a"
_db3_mk afloor <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
cd /
ok "djx afloor one"
X
_db3_af afloor "a unit that ends outside its \$TMP/cwd" "$_db3_n9b"

# ---- the shell a unit leaves (R8, R16) is part 1295's

# ---- the gate (D1, R10): gate.sh beside a stub tests/run that records its arguments and FELIX_TEST_JOBS
_db3_G="$DB3/gt"; mkdir -p "$_db3_G/engine/harness/tests" "$_db3_G/projects/felix" "$DB3/gtmp" "$DB3/gout"
cp "$REAL_HARNESS/../../projects/felix/gate.sh" "$_db3_G/projects/felix/gate.sh"
cat > "$_db3_G/engine/harness/tests/run" <<'DB3STUB'
#!/usr/bin/env bash
printf '%s:%s\n' "$#" "$*" >> "$DJX_OUT/$DJX_L.args"
printf '%s\n' "${FELIX_TEST_JOBS-unset}" >> "$DJX_OUT/$DJX_L.jobs"
if [ -n "${DJX_EXIT2:-}" ]; then printf 'djx stub: a refusal of its own\n' >&2; exit 2; fi
printf 'reused the suite run that ended 09:00 on this tree (normal), not run again\n'
printf '\n7 passed, 0 failed (reused)\n'
DB3STUB
chmod +x "$_db3_G/engine/harness/tests/run"
( _fx_cd "${_db3_G:?}" && git init -q -b main && git add -A && git -c user.name=djx -c user.email=djx@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm seed ) >/dev/null 2>&1
_db3_gate() {   # LABEL ENV...: gate.sh in the fixture, the stub recording as LABEL
  local l="$1"; shift
  ( cd "${_db3_G:?}" && perl "$DB3/run.pl" 90 DEFAULT DEFAULT "$DB3/gout/$l.pid" env -u FELIX_TEST_NO_MANIFEST -u GITHUB_ACTIONS -u FELIX_TEST_JOBS \
      FELIX_KERNEL_CACHE="$_db3_G/no-cache" TMPDIR="$DB3/gtmp" DJX_OUT="$DB3/gout" DJX_L="$l" ${1+"$@"} bash projects/felix/gate.sh ) > "$DB3/gout/$l.out" 2>&1
}
_db3_gate g1; _db3_gate g2 GITHUB_ACTIONS=true; _db3_gate g3 DJX_EXIT2=1; _db3_gate g4 GITHUB_ACTIONS=true FELIX_TEST_JOBS=7
is "D1: with GITHUB_ACTIONS unset, gate.sh sets FELIX_TEST_JOBS to the core count for its call to tests/run (sysctl, then getconf, then 1; held to 1 to 64)" "$(cat "$DB3/gout/g1.jobs" 2>/dev/null)" "$(_db3_cores)"
is "D1: with GITHUB_ACTIONS=true it does not set it (control)" "$(cat "$DB3/gout/g2.jobs" 2>/dev/null)" unset
is "R10: and with GITHUB_ACTIONS=true and a FELIX_TEST_JOBS=7 it inherited, the stub sees it unset" "$(cat "$DB3/gout/g4.jobs" 2>/dev/null)" unset
is "D1: and its argument list stays --reuse, in all three (control)" "$(cat "$DB3/gout/g1.args" 2>/dev/null) $(cat "$DB3/gout/g2.args" 2>/dev/null) $(cat "$DB3/gout/g4.args" 2>/dev/null)" "1:--reuse 1:--reuse 1:--reuse"
is "D1: when tests/run exits 2, the log's last line is shown under tests FAIL" \
   "$(LC_ALL=C awk '/^  tests +FAIL$/ { f = 1; next } f && index($0, "djx stub: a refusal of its own") { h = 1 } END { print f + 0, h + 0 }' "$DB3/gout/g3.out" 2>/dev/null)" "1 1"
is "R12: no run of this part left a process in its process group, stopped or running, after the 30 s it was given" "${_db3_leak:-none}" none
unset -f $(compgen -A function _db3_) 2>/dev/null
unset $(compgen -A variable _db3_) DB3 2>/dev/null
# <<< gate-friction-d-runner-failures-blind
