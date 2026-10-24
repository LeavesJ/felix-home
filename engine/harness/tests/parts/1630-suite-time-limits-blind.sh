# >>> suite-time-limits-blind
printf '\ntime limits on the suite: the quiet limit, and the record run waiting for red (audit b01, blind)\n'
# Blind, written on 2026-10-24 from the contract alone (docs/2026-10-24-audit-fixes/b01-time-limits-on-suite-gate-ci-and-probe-c.md, B1 to
# B13 and B21, assertions A1 to A20). tests/run, tests/red and tests/receipt.sh are run, never read, in copies of this suite that
# _suite_copy_tree (part 0003) makes under $TMP, each with planted parts of this block's own; no part 0001, 0007 or engine file was read.
# Every inner run is under this part's bounded runner (run.pl): it forks, the child makes a process group of its own, resets INT, QUIT, HUP
# and TERM and execs, and at T seconds the parent sends that group KILL and exits 124. So against a suite without the limits an assertion
# fails at its T and does not hang. Every run points TMPDIR at its case's directory (slots included) and has a mktemp first on PATH that
# writes down each call and, given no template, makes its name under TMPDIR, so a run's $TMP is made below the case. Every case ends by asking
# its runs' groups to hold no live process (30 s), and what is left is named in its verdict and sent CONT and KILL by pid. Nothing is ended
# by pattern: the stand-in reds write their own pids, and a group is signalled by its id.
# Readings taken where the contract leaves room. "Exits within N s" for a run that goes quiet (A1, A5, A6, A9, A12) is counted from the moment
# the planted part wrote its $TMP, which is just before its first assertion (B3(e) and B4 count from the last assertion reached), in whole
# seconds read from that file's mtime; A17 and A19 count from the run's start, as the contract says for A17. A6's controls and the three
# readings of A7 and A8 are one assertion each. The planted parts print a section line, `djx-sec NAME`, so that a unit's section can be found.
QTL="$TMP/qtl"
rm -rf "$QTL"; mkdir -p "$QTL/pp" "$QTL/n" "$QTL/mk" "$QTL/noperl"; : > "$QTL/g-empty.tsv"
_qt_perl="$(command -v perl)"; _qt_mkreal="$(command -v mktemp)"
_qt_E=(); _qt_lim=60; _qt_prog=run; _qt_pf=(); _qt_ctl=0; _qt_cl=ok; _qt_rc=0; _qt_t0=0; _qt_t1=0
cat > "$QTL/run.pl" <<'QTLRUN'
# run.pl T PIDFILE CMD...: CMD in a process group of its own (its id to PIDFILE), INT QUIT HUP TERM at their defaults; KILL to it at T s, exit 124
my ($t, $f) = splice(@ARGV, 0, 2);
my $p = fork; defined $p or exit 125;
if (!$p) { setpgrp(0, 0); $SIG{$_} = "DEFAULT" for qw(INT QUIT HUP TERM); if (open(my $h, ">", $f)) { print $h "$$\n"; close $h } exec @ARGV; exit 127 }
$SIG{ALRM} = sub { kill "KILL", -$p; exit 124 };
alarm $t; waitpid $p, 0;
exit(($? & 127) ? 128 + ($? & 127) : $? >> 8);
QTLRUN
cat > "$QTL/mk/mktemp" <<'QTLMK'
#!/bin/sh
# mktemp that writes each call down in $DJX_MKLOG and, given no template, makes its name under $TMPDIR; then the host's ($QT_MKREAL)
t=0
for a in "$@"; do case "$a" in -*) ;; *) t=1 ;; esac; done
printf '%s\n' "mktemp $*" >> "${DJX_MKLOG:-/dev/null}"
if [ "$t" = 0 ] && [ -n "${TMPDIR:-}" ]; then set -- "$@" "${TMPDIR%/}/tmp.XXXXXXXXXX"; fi
exec "$QT_MKREAL" "$@"
QTLMK
printf '#!/bin/sh\nexit 1\n' > "$QTL/noperl/perl"; chmod +x "$QTL/mk/mktemp" "$QTL/noperl/perl"
# The planted parts. SET FILE LINE...: pp/SET/FILE writes its $TMP to the case file tmp.FILE, prints its section line, then LINE...
_qt_part() {
  local d="$QTL/pp/$1" f="$2"; shift 2; mkdir -p "$d"
  { printf 'printf "%%s\\n" "$TMP" > "$DJX_DIR/tmp.%s"\n' "$f"; printf 'printf "\\ndjx-sec %s\\n"\n' "$f"; printf '%s\n' "$@"; } > "$d/$f"
}
_qt_ten=(); for _qt_i in 1 2 3 4 5 6 7 8 9 10; do _qt_ten[${#_qt_ten[@]}]="ok \"djx f$_qt_i\""; done
_qt_steady=('djx_i=1' 'while [ "$djx_i" -le "${DJX_STEADY:-12}" ]; do ok "djx s$djx_i"; sleep 1; djx_i=$((djx_i + 1)); done' 'unset djx_i')
_qt_sleeper=('#!/bin/sh' 'printf "%s\n" "$$" > "$DJX_DIR/red.pid"' 'sleep 600 &' 'printf "%s\n" "$!" > "$DJX_DIR/red.child"' 'wait')
_qt_part h 0010-q-hang.sh 'ok "djx q1"' 'sleep 300'
_qt_part j 0010-q-hang.sh 'ok "djx q1"' 'sleep 300'; _qt_part j 0020-fast.sh "${_qt_ten[@]}"
_qt_part s 0010-q-steady.sh "${_qt_steady[@]}"
_qt_part sj 0010-q-steady.sh "${_qt_steady[@]}"; _qt_part sj 0020-fast.sh "${_qt_ten[@]}"
_qt_part w 0010-q-wait.sh 'jobs -p > "$DJX_DIR/jobs.q-wait"' 'sleep 1 & wait' 'ok "djx w1"'
_qt_part i 0010-q-ignore.sh "trap '' TERM" 'ok "djx i1"' 'sleep 300'
_qt_part f 0010-fast.sh "${_qt_ten[@]}"
_qt_part r15 0010-q-red.sh 'ok "djx q1"' '[ "${FELIX_TEST_NO_MANIFEST:-}" != 1 ] || sleep 300' 'ok "djx q2"'; _qt_part r15 0020-fast.sh "${_qt_ten[@]}"
_qt_part r19 0010-umask.sh 'ok "djx u1"' 'umask 077'; _qt_part r19 0020-fast.sh "${_qt_ten[@]}"
printf 'djx f1\n' | _ran_rows > "$QTL/m-f.tsv"; printf 'djx q1\n' | _ran_rows > "$QTL/m-h.tsv"; printf 'djx s1\n' | _ran_rows > "$QTL/m-s.tsv"
printf 'djx w1\n' | _ran_rows > "$QTL/m-w.tsv"; printf 'djx u1\n' | _ran_rows > "$QTL/m-u.tsv"
{ printf 'djx q1\ndjx q2\n'; for _qt_i in 1 2 3 4 5 6 7 8 9 10; do printf 'djx f%s\n' "$_qt_i"; done; } | _ran_rows > "$QTL/m-r.tsv"

_qt_ms()  { perl -MTime::HiRes=time -e 'printf "%d", time * 1000'; }
_qt_until() { local n="$1" i=0; shift; while [ "$i" -lt "$n" ]; do "$@" && return 0; sleep 0.2; i=$((i + 1)); done; "$@"; }
_qt_cnt() { grep -cxF -e "$2" "$1" 2>/dev/null; }   # FILE LINE: lines that are exactly it
_qt_pre() { LC_ALL=C awk -v p="$2" 'index($0, p) == 1 { n++ } END { print n + 0 }' "$1" 2>/dev/null; }   # FILE PREFIX: lines that begin so
_qt_last() { LC_ALL=C awk '/^  (ok    |FAIL  |skip  )/ { l = $0 } END { print l }' "$1" 2>/dev/null; }   # the last assertion-shaped line
_qt_b3()  { printf '  FAIL  no new assertion in %s s, so the run was ended; the last it reached: %s' "$1" "$2"; }   # Q NAME: the B3 line
_qt_gm()  { ps -A -o pid= -o pgid= -o stat= -o command= 2>/dev/null | G=" $* " LC_ALL=C awk 'index(ENVIRON["G"], " " $2 " ") && $3 !~ /^Z/ { c = $0; sub(/^ *[0123456789]+ +[0123456789]+ +[^ ]+ +/, "", c); print $1 " " $3 " " substr(c, 1, 60) }'; }
_qt_alive() { case "$(ps -o stat= -p "$1" 2>/dev/null | tr -d ' ')" in ''|Z*) return 1 ;; *) return 0 ;; esac; }
# CASE [--red] MANIFEST SET: a copy of this suite at $QTL/n/CASE with the parts of pp/SET (_qt_c, _qt_F, _qt_T, _qt_tmp); 1 when it could not be made
_qt_new() {
  local n="$1" r=""; shift
  [ "${1:-}" != --red ] || { r=--red; shift; }
  _qt_c="$QTL/n/$n"; _qt_F="$_qt_c/f"; _qt_T="$_qt_F/engine/harness/tests"; _qt_tmp="$_qt_c/tmp"; _qt_pf=(); _qt_cl=ok
  rm -rf "$_qt_c"; mkdir -p "$_qt_tmp" || return 1
  _suite_copy_tree ${r:+"$r"} "$_qt_F" "$QTL/g-empty.tsv" "$1" "$QTL/pp/$2"/*.sh
}
# LABEL ARG...: the copy's tests/$_qt_prog in the background under the bounded runner (T = _qt_lim), with _qt_E; LABEL.out, .err and .pid
_qt_start() {
  local l="$1"; shift
  _qt_t0="$(_qt_ms)"
  ( cd "$_qt_F" && exec env -u FELIX_TEST_NO_MANIFEST -u FELIX_TEST_JOBS -u FELIX_TEST_SLOTS -u FELIX_TEST_RED_JOBS -u FELIX_TEST_SLOT_NOTE \
      -u FELIX_TEST_PART_LOG -u FELIX_TEST_PART_RAN -u FELIX_TEST_PART_END -u FELIX_TEST_PART_RECORD -u PERL5OPT \
      -u FELIX_TEST_QUIET_LIMIT -u FELIX_TEST_RED_WAIT -u FELIX_PROBE_LIMIT -u FELIX_EVIDENCE_LIMIT \
      TMPDIR="$_qt_tmp" FELIX_TEST_SLOTS=8 DJX_DIR="$_qt_c" DJX_MKLOG="$_qt_c/mktemp.log" QT_MKREAL="$_qt_mkreal" PATH="$QTL/mk:$PATH" \
      ${_qt_E[@]+"${_qt_E[@]}"} "$_qt_perl" "$QTL/run.pl" "$_qt_lim" "$_qt_c/$l.pid" "$BASH" "$_qt_T/$_qt_prog" "$@" \
  ) > "$_qt_c/$l.out" 2> "$_qt_c/$l.err" &
  _qt_bg=$!; _qt_pf[${#_qt_pf[@]}]="$_qt_c/$l.pid"
}
_qt_wait() { { wait "$_qt_bg"; } 2>/dev/null; _qt_rc=$?; _qt_t1="$(_qt_ms)"; _qt_E=(); _qt_lim=60; _qt_prog=run; }
_qt_run() { _qt_start "$@"; _qt_wait; }
# PART: whole seconds from PART's writing its $TMP to the end of the last run, or "never" when it wrote none
_qt_since() {
  local m; m="$(perl -e 'my @s = stat $ARGV[0]; print @s ? $s[9] : ""' "$_qt_c/tmp.$1" 2>/dev/null)"
  case "$m" in ''|*[!0123456789]*) printf never ;; *) printf '%s' "$(( _qt_t1 / 1000 - m ))" ;; esac
}
_qt_within() { local s; s="$(_qt_since "$1")"; [ "$s" != never ] && [ "$s" -le "$2" ] && return 0; printf ' it exited %s s after %s wrote its $TMP, not within %s;' "$s" "$1" "$2"; return 1; }
# LABEL SECONDS: "ok" once the group of run LABEL holds no live process, stopped or running, within SECONDS; else what it holds
_qt_gone() {
  local g i=0 n="$(( $2 * 5 ))" l; g="$(cat "$_qt_c/$1.pid" 2>/dev/null)"; [ -n "$g" ] || { printf 'no group id was written'; return 0; }
  while l="$(_qt_gm "$g")"; [ -n "$l" ]; do [ "$i" -lt "$n" ] || { printf 'its group holds: %s' "$(printf '%s' "$l" | tr '\n' ';')"; return 0; }; sleep 0.2; i=$((i + 1)); done
  printf ok
}
# LABEL: "ok" when the group of run LABEL holds no live process at a listing taken now and at one 0.1 s later
_qt_now() {
  local g l1 l2; g="$(cat "$_qt_c/$1.pid" 2>/dev/null)"; [ -n "$g" ] || { printf 'no group id was written'; return 0; }
  l1="$(_qt_gm "$g")"; sleep 0.1; l2="$(_qt_gm "$g")"
  [ -z "$l1$l2" ] && printf ok || printf 'at the first listing [%s], 0.1 s later [%s]' "$(printf '%s' "$l1" | tr '\n' ';')" "$(printf '%s' "$l2" | tr '\n' ';')"
}
# The case's closing check: the groups of its runs hold no live process (30 s); what is left is sent CONT and KILL by pid. _qt_cl: ok, or what
_qt_sweep() {
  local f g="" l="" i=0 p
  for f in ${_qt_pf[@]+"${_qt_pf[@]}"}; do g="$g $(cat "$f" 2>/dev/null)"; done
  _qt_cl=ok; [ -n "${g// /}" ] || return 0
  while [ "$i" -lt 150 ]; do l="$(_qt_gm $g)"; [ -n "$l" ] || return 0; sleep 0.2; i=$((i + 1)); done
  for p in $(printf '%s\n' "$l" | awk '{ print $1 }'); do kill -CONT "$p" 2>/dev/null; kill -KILL "$p" 2>/dev/null; done
  _qt_cl="left behind: $(printf '%s' "$l" | tr '\n' ';')"
}
_qt_rcpt() { if [ -f "$_qt_F/.git/felix-suite-receipt" ]; then echo present; else echo absent; fi; }
_qt_locked() { perl -e 'use Fcntl ":flock"; for my $f (glob "$ARGV[0]/felix-suite-slots/*") { open(my $h, "<", $f) or next; print "$f " unless flock($h, LOCK_EX | LOCK_NB); close $h }' "$1"; }
# FILE B3LINE UNIT: "ok" when UNIT's section (its djx-sec line to the next) holds the B3 line, then did-not-finish, then without-its-mark, once each
_qt_ord() {
  LC_ALL=C awk -v b="$2" -v u="$3" '
    $0 == "djx-sec " u { s = NR; next }
    index($0, "djx-sec ") == 1 && s && !e { e = NR }
    $0 == b { nb++; pb = NR }
    $0 == "  FAIL  part did not finish: " u { nd++; pd = NR }
    $0 == "  FAIL  part ended without its mark: " u { nm++; pm = NR }
    END { if (!e) e = NR + 1
      if (s && nb == 1 && nd == 1 && nm == 1 && s < pb && pb < pd && pd < pm && pm < e) print "ok"
      else printf "section at lines %d-%d; the quiet line %d time(s), at %d; did not finish %d, at %d; without its mark %d, at %d", s, e, nb, pb, nd, pd, nm, pm }' "$1" 2>/dev/null
}
# LABEL RC BASE: what a run that never goes quiet must show (A7, A8): its exit RC 0, reached, no quiet line, no stderr line the run BASE lacks
_qt_calm() {
  local r="" x
  [ "$2" = 0 ] || r="$r exit $2;"
  [ "$(_qt_cnt "$_qt_c/$1.out" reached)" = 1 ] || r="$r no reached;"
  [ "$(_qt_pre "$_qt_c/$1.out" '  FAIL  no new assertion in ')" = 0 ] || r="$r a quiet line was printed;"
  x="$(LC_ALL=C comm -23 <(LC_ALL=C sort -u "$_qt_c/$1.err") <(LC_ALL=C sort -u "$_qt_c/$3.err") | head -3 | tr '\n' '|')"
  [ -z "$x" ] || r="$r stderr it alone has [$x];"
  printf '%s' "${r:-ok}"
}

# ---- a serial run of passing parts: the positive control, which leaves a receipt, and its group at its exit (A10, B9)
_qt_new ctl "$QTL/m-f.tsv" f; _qt_run c1
_qt_x="$(_qt_now c1)"; [ "$_qt_rc" = 0 ] && [ "$(_qt_rcpt)" = present ] && _qt_ctl=1
_qt_sweep
is "time limits A10 (B9; control): a serial run of passing parts exits 0, prints reached and leaves a receipt, and its group holds no live process at the first listing after its exit and 0.1 s later" \
   "$_qt_rc $(_qt_cnt "$_qt_c/c1.out" reached) $(_qt_rcpt) $_qt_x $_qt_cl" "0 1 present ok ok"
_qt_fc="$_qt_c"   # kept for A13 and A14

# ---- a serial run that goes quiet, and the same part by hand (A1 to A5, B1, B3)
_qt_new h "$QTL/m-h.tsv" h; _qt_E=(FELIX_TEST_QUIET_LIMIT=5); _qt_run h1
_qt_b="$(_qt_b3 5 'djx q1')"; _qt_p="$(cat "$_qt_c/tmp.0010-q-hang.sh" 2>/dev/null)"; _qt_g="$(_qt_gone h1 3)"
# A run the case's runner ended at its bound was emptied by that runner, so its empty group says nothing about the run (A4)
[ "$_qt_rc" != 124 ] || _qt_g="the run reached the case's bound and was ended by it, not by itself"
_qt_r=""; case "$_qt_rc" in 0|2) _qt_r=" exit $_qt_rc;" ;; esac; _qt_r="$_qt_r$(_qt_within 0010-q-hang.sh 25)"
is "time limits A1 (B3): a serial run with FELIX_TEST_QUIET_LIMIT=5 whose part hangs after an assertion exits within 25 s of it, with a status that is neither 0 nor 2" "${_qt_r:-ok}" ok
is "time limits A2 (B3): it prints the line '  FAIL  no new assertion in 5 s, so the run was ended; the last it reached: djx q1' once, on a line of its own, as its last assertion line, and no reached" \
   "$(_qt_cnt "$_qt_c/h1.out" "$_qt_b") $([ "$(_qt_last "$_qt_c/h1.out")" = "$_qt_b" ] && echo last || echo "last is [$(_qt_last "$_qt_c/h1.out")]") $(_qt_cnt "$_qt_c/h1.out" reached)" "1 last 0"
is "time limits A3 (B3): it leaves no receipt, where the control run left one, and its \$TMP is removed" \
   "$(_qt_rcpt) $([ "$_qt_ctl" = 1 ] && echo control || echo no-control) $([ -n "$_qt_p" ] && { [ -e "$_qt_p" ] && echo tmp-left || echo tmp-removed; } || echo no-tmp-written)" "absent control tmp-removed"
is "time limits A4 (B3): within 3 s of its exit nothing of its group is left, stopped or running" "$_qt_g" ok
rm -f "$_qt_c/tmp.0010-q-hang.sh"; _qt_E=(FELIX_TEST_QUIET_LIMIT=5); _qt_run p5 --part 0010-q-hang.sh
_qt_r=""; case "$_qt_rc" in 0|2) _qt_r=" exit $_qt_rc;" ;; esac; _qt_r="$_qt_r$(_qt_within 0010-q-hang.sh 25)"
[ "$(_qt_cnt "$_qt_c/p5.out" "$_qt_b")" = 1 ] || _qt_r="$_qt_r the quiet line was printed $(_qt_cnt "$_qt_c/p5.out" "$_qt_b") times;"
_qt_sweep; [ "$_qt_cl" = ok ] || _qt_r="$_qt_r $_qt_cl;"
is "time limits A5 (B1): the same part run by hand with --part and FELIX_TEST_QUIET_LIMIT=5 prints the same line, exits neither 0 nor 2, and within 25 s of its assertion" "${_qt_r:-ok}" ok
rm -rf "$QTL/n/h"

# ---- a -j 2 unit that goes quiet (A6, B5)
_qt_new j "$QTL/m-f.tsv" j; printf '7\t0010-q-hang.sh\n3\t0020-fast.sh\n' > "$_qt_F/.git/felix-suite-durations"; cp "$_qt_F/.git/felix-suite-durations" "$QTL/dur.ref"
_qt_E=(FELIX_TEST_QUIET_LIMIT=5); _qt_lim=90; _qt_run j6 -j 2
_qt_g="$(_qt_gone j6 3)"
_qt_r=""; [ "$_qt_rc" = 1 ] || _qt_r=" exit $_qt_rc, not 1;"; _qt_r="$_qt_r$(_qt_within 0010-q-hang.sh 45)"
_qt_x="$(_qt_ord "$_qt_c/j6.out" "$_qt_b" 0010-q-hang.sh)"; [ "$_qt_x" = ok ] || _qt_r="$_qt_r $_qt_x;"
for _qt_i in 1 2 3 4 5 6 7 8 9 10; do [ "$(_qt_cnt "$_qt_c/j6.out" "  ok    djx f$_qt_i")" = 1 ] || _qt_r="$_qt_r djx f$_qt_i printed $(_qt_cnt "$_qt_c/j6.out" "  ok    djx f$_qt_i") times;"; done
[ "$(_qt_rcpt)" = absent ] || _qt_r="$_qt_r a receipt was left;"; [ "$_qt_ctl" = 1 ] || _qt_r="$_qt_r the control left no receipt, so its absence says nothing;"
is "time limits A6 (B5): under -j 2 a unit that goes quiet for FELIX_TEST_QUIET_LIMIT=5 has, in its section, the quiet line, then part did not finish and part ended without its mark; the other unit's ten assertions are all printed, the run exits 1 within 45 s of the quiet unit's assertion, and no receipt is left" "${_qt_r:-ok}" ok
_qt_sweep
is "time limits A6 (B5; control): and the durations file it found is byte for byte as it was, no slot file under its TMPDIR is locked, and its group is empty within 3 s" \
   "$(cmp -s "$QTL/dur.ref" "$_qt_F/.git/felix-suite-durations" && echo same || echo changed) [$(_qt_locked "$_qt_tmp")] $_qt_g $_qt_cl" "same [] ok ok"
rm -rf "$QTL/n/j"

# ---- runs that never go quiet, serial and -j 2 (A7, A8, B2, B9), and frozen time (A11, B10)
_qt_new s "$QTL/m-s.tsv" s
_qt_E=(FELIX_TEST_QUIET_LIMIT=3 DJX_STEADY=12); _qt_run s7; _qt_z="$_qt_rc"; _qt_E=(DJX_STEADY=12); _qt_run s7u
_qt_x="$(_qt_calm s7 "$_qt_z" s7u)"; _qt_y="$_qt_rc"; _qt_sweep
is "time limits A7 (B2, B9; control): a serial run with FELIX_TEST_QUIET_LIMIT=3 whose part passes an assertion each second for 12 s exits 0, prints reached and no quiet line, and says nothing on stderr that the same run with the variable unset does not" \
   "$_qt_x unset-run-exit-$_qt_y $_qt_cl" "ok unset-run-exit-0 ok"
_qt_E=(FELIX_TEST_QUIET_LIMIT=5 DJX_STEADY=15); _qt_lim=90; _qt_start s11
_qt_three() { [ "$(_qt_pre "$_qt_c/s11.out" '  ok    djx s')" -ge 3 ] || ! kill -0 "$_qt_bg" 2>/dev/null; }
_qt_until 450 _qt_three; _qt_x="$(_qt_pre "$_qt_c/s11.out" '  ok    djx s')"
_qt_g="$(cat "$_qt_c/s11.pid" 2>/dev/null)"
if [ "$_qt_x" -ge 3 ] && [ -n "$_qt_g" ]; then perl -e 'kill "STOP", -$ARGV[0]' "$_qt_g"; sleep 20; perl -e 'kill "CONT", -$ARGV[0]' "$_qt_g"; _qt_y=stopped; else _qt_y="never stopped: $_qt_x lines"; fi
_qt_wait; _qt_sweep
is "time limits A11 (B10; control): a serial run with FELIX_TEST_QUIET_LIMIT=5 whose whole group is stopped for 20 s between two assertions a second apart, then continued, is not ended: it exits 0, prints reached and no quiet line" \
   "$_qt_y $_qt_rc $(_qt_cnt "$_qt_c/s11.out" reached) $(_qt_pre "$_qt_c/s11.out" '  FAIL  no new assertion in ') $_qt_cl" "stopped 0 1 0 ok"
rm -rf "$QTL/n/s"
_qt_new sj "$QTL/m-s.tsv" sj
_qt_E=(FELIX_TEST_QUIET_LIMIT=3 DJX_STEADY=12); _qt_run s8 -j 2; _qt_z="$_qt_rc"; _qt_E=(DJX_STEADY=12); _qt_run s8u -j 2
_qt_x="$(_qt_calm s8 "$_qt_z" s8u)"; _qt_y="$_qt_rc"; _qt_sweep
is "time limits A8 (B2; control): the same under -j 2, with the steady part and ten fast assertions as two units: exit 0, reached, no quiet line, and no stderr line the unset run lacks" \
   "$_qt_x unset-run-exit-$_qt_y $_qt_cl" "ok unset-run-exit-0 ok"
rm -rf "$QTL/n/sj"

# ---- the watchdog is no job of the run's shell (A9, B9)
_qt_new w "$QTL/m-w.tsv" w; _qt_run w9
_qt_r=""; [ "$_qt_rc" = 0 ] || _qt_r=" exit $_qt_rc;"; _qt_r="$_qt_r$(_qt_within 0010-q-wait.sh 15)"
[ -f "$_qt_c/jobs.q-wait" ] && _qt_x="$(awk 'END { print NR }' "$_qt_c/jobs.q-wait")" || _qt_x=never-written
[ "$_qt_x" = 0 ] || _qt_r="$_qt_r jobs -p before its own & listed $_qt_x;"
_qt_sweep; [ "$_qt_cl" = ok ] || _qt_r="$_qt_r $_qt_cl;"
is "time limits A9 (B9; control): a part's jobs -p lists none it did not start, and its bare wait waits only for its own sleep 1: the run exits 0 within 15 s of the part's start" "${_qt_r:-ok}" ok
rm -rf "$QTL/n/w"

# ---- a part that leaves TERM ignored (A12, B4)
_qt_new i - i; _qt_E=(FELIX_TEST_QUIET_LIMIT=5); _qt_lim=90; _qt_run i12
_qt_p="$(cat "$_qt_c/tmp.0010-q-ignore.sh" 2>/dev/null)"; _qt_g="$(_qt_gone i12 3)"
_qt_r=""; case "$_qt_rc" in 0|2) _qt_r=" exit $_qt_rc;" ;; esac; _qt_r="$_qt_r$(_qt_within 0010-q-ignore.sh 40)"
[ -n "$_qt_p" ] || _qt_r="$_qt_r the part wrote no \$TMP;"
[ "$(_qt_cnt "$_qt_c/i12.out" "  note  the run's shell did not end on TERM and was killed; its temporary directory is left: $_qt_p")" = 1 ] || _qt_r="$_qt_r the note naming [$_qt_p] was printed $(_qt_cnt "$_qt_c/i12.out" "  note  the run's shell did not end on TERM and was killed; its temporary directory is left: $_qt_p") times;"
[ -z "$_qt_p" ] || [ -d "$_qt_p" ] || _qt_r="$_qt_r its \$TMP is gone;"
[ "$_qt_g" = ok ] || _qt_r="$_qt_r $_qt_g;"
case "$_qt_p" in "$QTL"/*) rm -rf "$_qt_p" ;; esac
_qt_sweep; [ "$_qt_cl" = ok ] || _qt_r="$_qt_r $_qt_cl;"
is "time limits A12 (B4): a quiet run whose part left TERM ignored exits within 40 s of its assertion, neither 0 nor 2, prints the note that its shell did not end on TERM and was killed, naming its \$TMP, which is left, and its group is empty within 3 s" "${_qt_r:-ok}" ok
rm -rf "$QTL/n/i"

# ---- the two variables refused (A13, B7), and no perl (A14, B8): in the control's copy
_qt_c="$_qt_fc"; _qt_F="$_qt_c/f"; _qt_T="$_qt_F/engine/harness/tests"; _qt_tmp="$_qt_c/tmp"; _qt_pf=()
printf 'djx planted receipt\n' > "$_qt_F/.git/felix-suite-receipt"; cp "$_qt_F/.git/felix-suite-receipt" "$QTL/rcpt.ref"
_qt_r=""
for _qt_a in FELIX_TEST_QUIET_LIMIT= FELIX_TEST_QUIET_LIMIT=0 FELIX_TEST_QUIET_LIMIT=07 FELIX_TEST_QUIET_LIMIT=86401 FELIX_TEST_QUIET_LIMIT=5s \
             FELIX_TEST_QUIET_LIMIT=-1 'FELIX_TEST_QUIET_LIMIT= 5' FELIX_TEST_QUIET_LIMIT=+5 FELIX_TEST_RED_WAIT=0 FELIX_TEST_RED_WAIT=; do
  _qt_n="${_qt_a%%=*}"; _qt_v="${_qt_a#*=}"; rm -f "$_qt_c/mktemp.log"; _qt_E=("$_qt_a"); _qt_run r13
  _qt_x=""; [ "$_qt_rc" = 2 ] || _qt_x="$_qt_x exit $_qt_rc;"
  [ "$(awk 'END { print NR }' "$_qt_c/r13.err")" = 1 ] || _qt_x="$_qt_x $(awk 'END { print NR }' "$_qt_c/r13.err") stderr lines;"
  [ "$(sed -n 1p "$_qt_c/r13.err")" = "tests/run: $_qt_n is [$_qt_v]: it must be a number of seconds from 1 to 86400 in plain decimal" ] || _qt_x="$_qt_x said [$(sed -n 1p "$_qt_c/r13.err")];"
  [ ! -s "$_qt_c/mktemp.log" ] || _qt_x="$_qt_x mktemp was called;"
  cmp -s "$QTL/rcpt.ref" "$_qt_F/.git/felix-suite-receipt" || { _qt_x="$_qt_x the receipt changed;"; cp "$QTL/rcpt.ref" "$_qt_F/.git/felix-suite-receipt"; }
  [ -z "$_qt_x" ] || _qt_r="$_qt_r [$_qt_a]$_qt_x"
done
_qt_sweep; [ "$_qt_cl" = ok ] || _qt_r="$_qt_r $_qt_cl;"
is "time limits A13 (B7): FELIX_TEST_QUIET_LIMIT set to '', 0, 07, 86401, 5s, -1, ' 5' or +5, and FELIX_TEST_RED_WAIT set to 0 or '', each exit 2 with exactly the one stderr line 'tests/run: NAME is [V]: it must be a number of seconds from 1 to 86400 in plain decimal', call no mktemp, and leave the receipt there as it was" "${_qt_r:-ok}" ok
_qt_E=(PATH="$QTL/noperl:$QTL/mk:$PATH"); _qt_run p14; _qt_sweep
is "time limits A14 (B8): with a perl first on PATH that exits 1 a serial run goes on as before, exiting 0 and printing reached, and says on one stderr line beginning 'tests/run: this run has no quiet limit: ' that it has none" \
   "$_qt_rc $(_qt_cnt "$_qt_c/p14.out" reached) $(_qt_pre "$_qt_c/p14.err" 'tests/run: this run has no quiet limit: ') $_qt_cl" "0 1 1 ok"
rm -rf "$_qt_fc"

# ---- red leaves the quiet line out (A15, A16, B6)
_qt_new r15 --red "$QTL/m-r.tsv" r15; _qt_prog=red; _qt_E=(FELIX_TEST_RED_JOBS=2 FELIX_TEST_QUIET_LIMIT=5); _qt_lim=180; _qt_run r15; _qt_sweep
_qt_x="$(LC_ALL=C awk -F'\t' '$1 == "djx q2" { q = $2 } index($1, "no new assertion in ") == 1 { n++ } END { print (q == "" ? "no-row" : q), n + 0 }' "$_qt_T/red.tsv" 2>/dev/null)"
is "time limits A15 (B6): red by hand with FELIX_TEST_RED_JOBS=2 and FELIX_TEST_QUIET_LIMIT=5, over a part that hangs in red's suite only, exits 0, its red.tsv names djx q2 with one failure, and no row whose name begins 'no new assertion in '" \
   "$_qt_rc ${_qt_x:-no red.tsv} $_qt_cl" "0 1 0 ok"
rm -rf "$QTL/n/r15"
is "time limits A16 (B6; control): no name in this tree's assertions.tsv begins with 'no new assertion in '" \
   "$(cut -f2 "$HERE/assertions.tsv" | LC_ALL=C awk 'index($0, "no new assertion in ") == 1 { n++ } END { print n + 0 }')" 0

# ---- the record run's wait for red (A17 to A19, B11 to B13), with stand-in reds that write their pids
_qt_dead() {   # "ok" when the stand-in red and its child are gone within 3 s of the run's exit
  local p c i=0; p="$(cat "$_qt_c/red.pid" 2>/dev/null)"; c="$(cat "$_qt_c/red.child" 2>/dev/null)"
  [ -n "$p" ] && [ -n "$c" ] || { printf 'the stand-in red never wrote its pids'; return 0; }
  while _qt_alive "$p" || _qt_alive "$c"; do [ "$i" -lt 15 ] || { printf 'still running after 3 s:'; _qt_alive "$p" && printf ' red %s' "$p"; _qt_alive "$c" && printf ' child %s' "$c"; return 0; }; sleep 0.2; i=$((i + 1)); done
  printf ok
}
_qt_new rec "$QTL/m-f.tsv" f; printf '%s\n' "${_qt_sleeper[@]}" > "$_qt_T/red"; chmod +x "$_qt_T/red"
_qt_E=(FELIX_TEST_RED_WAIT=5); _qt_lim=120; _qt_run r17 --record-assertions; _qt_x="$(_qt_dead)"; _qt_sweep
_qt_r=""; [ "$_qt_rc" = 0 ] || _qt_r=" exit $_qt_rc;"; [ "$(( _qt_t1 - _qt_t0 ))" -le 60000 ] || _qt_r="$_qt_r it took $(( _qt_t1 - _qt_t0 )) ms;"
[ "$(_qt_cnt "$_qt_c/r17.out" '  red stopped: still running after its limit of 5 s, so it was ended')" = 1 ] || _qt_r="$_qt_r the red stopped line was printed $(_qt_cnt "$_qt_c/r17.out" '  red stopped: still running after its limit of 5 s, so it was ended') times;"
[ "$_qt_x" = ok ] || _qt_r="$_qt_r $_qt_x;"; [ "$_qt_cl" = ok ] || _qt_r="$_qt_r $_qt_cl;"
is "time limits A17 (B11): a serial record run with FELIX_TEST_RED_WAIT=5 and a red that never ends exits 0 within 60 s of its start, prints '  red stopped: still running after its limit of 5 s, so it was ended', and the red and its child are gone within 3 s of its exit" "${_qt_r:-ok}" ok
printf '#!/bin/sh\nprintf "red: stand-in\\n"\nexit 0\n' > "$_qt_T/red"; chmod +x "$_qt_T/red"; _qt_run r18 --record-assertions; _qt_sweep
is "time limits A18 (B13; control): a record run whose red prints a line and ends at once shows that line, indented, and no red stopped line, and exits 0" \
   "$_qt_rc $(_qt_cnt "$_qt_c/r18.out" '  red: stand-in') $(LC_ALL=C awk 'index($0, "red stopped") { n++ } END { print n + 0 }' "$_qt_c/r18.out") $_qt_cl" "0 1 0 ok"
rm -rf "$QTL/n/rec"
_qt_new rj "$QTL/m-u.tsv" r19; printf '%s\n' "${_qt_sleeper[@]}" > "$_qt_T/red"; chmod +x "$_qt_T/red"
_qt_lim=180; _qt_run r19 -j 2 --record-assertions; _qt_x="$(_qt_dead)"; _qt_sweep
_qt_r=""; [ "$_qt_rc" = 1 ] || _qt_r=" exit $_qt_rc, not 1;"; [ "$(( _qt_t1 - _qt_t0 ))" -le 110000 ] || _qt_r="$_qt_r it took $(( _qt_t1 - _qt_t0 )) ms;"
[ "$(_qt_cnt "$_qt_c/r19.out" '  red stopped: still running after its limit of 60 s, so it was ended')" = 1 ] || _qt_r="$_qt_r the red stopped line was printed $(_qt_cnt "$_qt_c/r19.out" '  red stopped: still running after its limit of 60 s, so it was ended') times;"
[ "$_qt_x" = ok ] || _qt_r="$_qt_r $_qt_x;"; [ "$_qt_cl" = ok ] || _qt_r="$_qt_r $_qt_cl;"
is "time limits A19 (B12): a -j 2 record run with a runner failure (a part leaves umask 077) and a red that ignores its mark exits 1 within 110 s, prints '  red stopped: still running after its limit of 60 s, so it was ended', and the red's tree is gone within 3 s" "${_qt_r:-ok}" ok
rm -rf "$QTL/n/rj"

# ---- sizes (A20, B21)
_qt_wc() { if [ -f "$1" ]; then awk 'END { print NR }' "$1"; else printf missing; fi; }
_qt_r=""
_qt_x="$(_qt_wc "$HERE/run")"; [ "$_qt_x" != missing ] && [ "$_qt_x" -le 500 ] || _qt_r="$_qt_r tests/run $_qt_x;"
_qt_x="$(_qt_wc "$HERE/red")"; [ "$_qt_x" != missing ] && [ "$_qt_x" -le 559 ] || _qt_r="$_qt_r tests/red $_qt_x;"
_qt_x="$(_qt_wc "$HERE/receipt.sh")"; [ "$_qt_x" != missing ] && [ "$_qt_x" -le 500 ] || _qt_r="$_qt_r receipt.sh $_qt_x;"
_qt_x="$(_qt_wc "$(ls "$HERE"/parts/0007-*.sh 2>/dev/null | sed -n 1p)")"; [ "$_qt_x" != missing ] && [ "$_qt_x" -le 835 ] || _qt_r="$_qt_r 0007 $_qt_x;"
for _qt_a in "$REAL_HARNESS/lib/probes.sh" "$REAL_HARNESS/lib/obligations.sh" "$(ls "$HERE"/parts/0001-*.sh 2>/dev/null | sed -n 1p)"; do
  _qt_x="$(_qt_wc "$_qt_a")"; [ "$_qt_x" != missing ] && [ "$_qt_x" -lt 500 ] || _qt_r="$_qt_r ${_qt_a##*/} $_qt_x;"
done
is "time limits A20 (B21; control): tests/run is at most 500 lines, tests/red at most 559, receipt.sh at most 500, part 0007 at most 835, and lib/probes.sh, lib/obligations.sh and part 0001 each under 500" "${_qt_r:-ok}" ok

rm -rf "$QTL"
unset -f $(compgen -A function _qt_) 2>/dev/null
unset $(compgen -A variable _qt_) QTL 2>/dev/null
# <<< suite-time-limits-blind
