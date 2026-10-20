# >>> gate-friction-d-signals-blind
printf '\ngate friction D: signals, endings and holders (blind, author 2; revision 11)\n'
# Blind, written on 2026-10-18 from contract D, then rewritten on 2026-10-19 against revision 7 (D1 to D8 and
# "Amended after review 1"), by an author who read no implementation. tests/run, tests/red and tests/receipt.sh
# are run, never read, in copies of this suite that _suite_copy_tree (part 0003) makes under $TMP with planted
# parts of this block's own. Part 1294 holds the slots, the gate and the log, part 1296 what a run loses (the ending
# under a short read timeout, a parent or a holder killed with -9); this part holds what ends a run: D6's signals,
# dispositions and holders, with R2 to R4 (every stopper, units that outlive their wrapper). Revision 8 fixes here:
# proc2 2 (the holder-streams file test while the unit runs), 5 (R4's two mechanisms apart), 6 (R18, the start-up
# check's name), 7a (TERM and HUP dispositions) and conf2 2 (the lingering child is no job of the unit's shell).
# Revision 9 fix here: proc3 4(b) (R27): the TERM-ignored and HUP-ignored dispositions runs no longer claim to show the
# ticker's reset. With TERM ignored at the parent every unit inherits it ignored, and the run ends normally, which ends the
# ticker with KILL, never TERM; the same holds of the run started with HUP ignored. So the ticker's reset cannot be observed
# in those runs and rests on review and on R13's measurement of a perl that sets them to their defaults; what the runs pin is
# that units read what a -j 1 run reads, that the run passes with exit 0 (not the runner's 124) and that nothing of its group is left.
# Revision 10 fixes here: proc4 2 (R34): the ps shim of the R2 cases counts only `ps -A` calls, as R19 defines the ending's listing, so a
# holder's `ps -o ppid= -p WRAPPER` (R20, every 10 s) never takes a number; and proc4 3 (R35): a case for R20's own check, that a holder's
# wrapper still has the -j parent as its parent, with a ps first on PATH that answers that one call with 1 once a gate file exists.
# Revision 11 fix here: ev1 2 (R38): the record run's TERM case (D6, "TERM to a record run under -j 2") sends its TERM only once red's suite has started its
# own sleeper children and holds, read from a file the red-only side writes (rup.NAME, written where FELIX_TEST_NO_MANIFEST=1, which only red's suite sees).
# Before, the TERM could land before red's suite had started a child, and the one-list stopper of a build without R1 (the base's tests/red and receipt.sh, as
# red's suite runs this part) then missed it: the case was red on some runs and not on others, so red.tsv could not be reproduced. The parts' up.NAME is now
# the record run's alone, so "both units up" is read of the record run's units, not of red's. The case's name and its checks stand.
# Names say the clause: D6 the runner, R2 R4 R13 R18 R20 R38 the amendments.
#
# What every case does (R12): it points TMPDIR at a fixture directory under $TMP, so none touches the machine's
# slots; it runs the copy under a bounded runner (run.pl) that makes the run's process group and starts it with
# INT and QUIT as the case asks and HUP and TERM at their defaults, so the HUP and TERM cases hold under nohup;
# every wait is bounded; and when the run has ended it waits up to 30 s for that group to hold no live process,
# stopped or running (zombies aside), reads from ps, and fails with the processes it names when one is left; it
# then sends CONT and KILL to those pids. A process outside such a group is ended by the pid the case recorded.
# No signal goes to a pid found by a pattern: a process is found by its group, its command line or its id for
# the check, and killed only by group or by a recorded pid whose command line still carries the case's id.
#
# Readings taken where the contract leaves room, for the reviewers to confirm:
# - "no unit, holder or wrapper left" is read from ps after the parent has ended: nothing in the run's group,
#   with the copy's directory or the case's id in its command line, that is not a zombie, within 5 s;
# - "no slot held" is a LOCK_EX|LOCK_NB that every slot file grants, and "the slot files keep their names and
#   inode numbers" is read from a stat of felix-suite-slots before the signal and after the exit (D6: no step
#   removes a slot);
# - "the holder's stdout and stderr are the unit's log" is read with lsof (or /proc) as: the holder's descriptors
#   1 and 2 name one regular file, and it is the file the unit's own descriptor 1 names;
# - a run read through a pipe, as out=$(tests/run ...) reads it, ends with the run: the pipe is closed within 10 s
#   of the driver's exit;
# - the lu and hk cases leave FELIX_TEST_SLOT_NOTE unset (W = 30), so that within 3 s of a wrapper's kill -9 only the
#   holder's own check of its parent can end the holder and its unit; the parent still waits on its FIFO then;
# - "within 3 s" is timed inside the perl (djk.pl) that takes the ps listing, from the moment of the kill (or of the
#   marker a unit writes right after killing) to the start of the first listing that shows what was asked for.
# An assertion whose name ends in (control) passes before D is built on purpose: it pins what makes the others
# mean something. Against a tree where -j is not understood every run below is a serial one, so each case that
# would pass serially also asks for something only -j gives.
DB2="$TMP/db2"; mkdir -p "$DB2/n" "$DB2/pp" "$DB2/psshim" "$DB2/oshim"
_db2_E=(); _db2_I=DEFAULT; _db2_Q=DEFAULT; _db2_Tm=DEFAULT; _db2_Hu=DEFAULT; _db2_lim=100; _db2_S=8; _db2_td=""; _db2_hp=0; _db2_ctl=0; _db2_bg=0; _db2_rc=0; _db2_lab=""
_db2_leak=""; _db2_ino0=""; _db2_pipe=0; _db2_late=""; _db2_x=""; _db2_gn=150
: > "$DB2/g-empty.tsv"; printf '1\tdjy seed\n' > "$DB2/man.tsv"
cat > "$DB2/run.pl" <<'DB2PL'
# run.pl LIMIT INT QUIT TERM HUP PIDFILE CMD...: CMD leads a process group of its own, started with INT QUIT TERM and HUP as given (the cases
# give TERM and HUP their defaults unless they ask) and no descriptor above 2; at LIMIT seconds the group is killed (exit 124). Exits as bash
# reports CMD's status.
use POSIX ();
my ($t, $i, $q, $tm, $hu, $f) = splice(@ARGV, 0, 6);
my $p = fork;
defined $p or exit 125;
if (!$p) { setpgrp(0, 0); $SIG{INT} = $i; $SIG{QUIT} = $q; $SIG{HUP} = $hu; $SIG{TERM} = $tm; POSIX::close($_) for 3 .. 255; exec @ARGV; exit 127 }
if (open(my $h, ">", "$f.t")) { print $h "$p\n"; close $h; rename "$f.t", $f }
$SIG{ALRM} = sub { kill "KILL", -$p; exit 124 };
alarm $t; waitpid $p, 0;
exit(($? & 127) ? 128 + ($? & 127) : $? >> 8);
DB2PL
cat > "$DB2/ign.pl" <<'DB2IGN'
# ign.pl DIR ID MODE: ignores TERM and sleeps. MODE h: each TERM it gets forks one sleeper; MODE s: from its first TERM on it forks one every
# 20 ms, 100 at most. Pids go to DIR/ign.pid and DIR/gc.pids; the sleepers carry ID in their command line.
my ($d, $id, $mode) = @ARGV;
my ($t, $n) = (0, 0);
sub spawn {
  return if $n >= 100;
  $n++;
  my $k = fork;
  return unless defined $k;
  if (!$k) { exec "perl", "-e", "sleep 300", $id, "gc"; exit 1 }
  if (open(my $g, ">>", "$d/gc.pids")) { print $g "$k\n"; close $g }
}
$SIG{TERM} = sub { $t = 1; spawn() if $mode eq "h" };
open(my $h, ">", "$d/ign.pid") or exit 3; print $h "$$\n"; close $h;
while (1) { select(undef, undef, undef, 0.02); spawn() if $t && $mode eq "s" }
DB2IGN
cat > "$DB2/psshim/ps" <<'DB2PS'
#!/bin/sh
# The real ps ($DJ2_PSREAL), except that the DJ2_PSFAIL-th listing asked for once the file $DJ2_PSTRIG exists fails with no output and status 1. A listing is a
# `ps -A` call whose arguments hold ppid= (R19, R34): the ending's. A holder's `ps -o ppid= -p WRAPPER` (R20, every 10 s) holds no -A and is never counted.
# Every listing asked for after the trigger is counted in $DJ2_PSCNT.
case " $* " in *" -A "*ppid=*)
  if [ -e "$DJ2_PSTRIG" ]; then
    echo x >> "$DJ2_PSCNT"
    [ "$(wc -l < "$DJ2_PSCNT" | tr -d ' ')" != "$DJ2_PSFAIL" ] || exit 1
  fi ;;
esac
exec "$DJ2_PSREAL" "$@"
DB2PS
chmod +x "$DB2/psshim/ps"
cat > "$DB2/djk.pl" <<'DB2DJK'
# djk.pl SIG KILLPID WAITFILE MAXMS MODE ARG...: sends SIG to KILLPID (0: none), waits for the file WAITFILE (- : none; at most 120 s), takes the time T0, then
# takes ps listings until what MODE asks about has gone or MAXMS ms have passed. MODE pids PID...: those pids; MODE pidfile FILE: the pids in that
# file (read after the wait); MODE group PGID KEY ID: every live process
# (zombies aside, not this perl) in group PGID or with KEY or ID in its command line. Prints "gone MS" (MS: from T0 to the start of the first listing that
# showed none of them), "left MS PID,PID..." or "nopids".
use Time::HiRes qw(time sleep);
my ($sig, $kp, $wf, $max, $mode, @a) = @ARGV;
kill $sig, $kp if $kp;
if ($wf ne "-") { my $e = time + 120; while (!-e $wf && time < $e) { sleep 0.02 } }
my $t0 = time; my $t; my @left;
if ($mode eq "pidfile") { if (open(my $h, "<", $a[0])) { @a = map { split " " } <$h>; close $h } else { @a = () } $mode = "pids" }
if ($mode eq "pids" && !@a) { print "nopids\n"; exit }
while (1) {
  $t = time; @left = ();
  for my $l (split /\n/, `ps -A -ww -o pid= -o pgid= -o stat= -o command= 2>/dev/null`) {
    next unless $l =~ /^\s*(\d+)\s+(\d+)\s+(\S+)\s+(.*)$/;
    my ($p, $g, $s, $c) = ($1, $2, $3, $4);
    next if $s =~ /^Z/ || $p == $$;
    if ($mode eq "pids") { push @left, $p if grep { $_ == $p } @a }
    else { push @left, $p if ($a[0] && $g == $a[0]) || index($c, $a[1]) >= 0 || index($c, $a[2]) >= 0 }
  }
  last if !@left || ($t - $t0) * 1000 > $max;
  sleep 0.05;
}
if (@left) { printf "left %d %s\n", (time - $t0) * 1000, join(",", @left) } else { printf "gone %d\n", ($t - $t0) * 1000 }
DB2DJK
_db2_until() { local n="$1" i=0; shift; while [ "$i" -lt "$n" ]; do "$@" && return 0; sleep 0.2; i=$((i + 1)); done; "$@"; }
_db2_cnt() { LC_ALL=C awk -v l="$2" '$0 == l { n++ } END { print n + 0 }' "$1" 2>/dev/null || echo 0; }   # FILE LINE: lines that are exactly LINE
_db2_pfx() { LC_ALL=C awk -v p="$2" 'index($0, p) == 1 { n++ } END { print n + 0 }' "$1" 2>/dev/null || echo 0; }   # FILE PREFIX: lines that start with it
_db2_ms()  { perl -MTime::HiRes=time -e 'printf "%d", time * 1000'; }
_db2_sel() { _db2_c="$DB2/n/$1"; _db2_F="$_db2_c/f"; _db2_T="$_db2_F/engine/harness/tests"; _db2_tmp="${_db2_td:-$_db2_c/tmp}"; }
# CASE [--red] GROUPS MANIFEST STUB...: the copy at $DB2/n/CASE and its fixture TMPDIR; 1 when it could not be made. A MANIFEST of + is a manifest
# of one row for each STUB that says ok "djy $DJ2N", so that a run that passes has compared one and leaves a receipt; - is none
_db2_new() {
  local n="$1" r="" s m; shift
  [ "${1:-}" != --red ] || { r=--red; shift; }
  _db2_sel "$n"
  rm -rf "$_db2_c"; mkdir -p "$_db2_c" "$_db2_tmp" || return 1
  if [ "${2:-}" = + ]; then
    m="$_db2_c/manifest.gen"; : > "$m"
    for s in "${@:3}"; do ! grep -qF 'ok "djy $DJ2N"' "$s" || printf '1\tdjy %s\n' "${s##*/}" >> "$m"; done
    set -- "$1" "$m" "${@:3}"
  fi
  _suite_copy_tree ${r:+"$r"} "$_db2_F" "$@"
}
_db2_run() {   # ARG...: the copy's driver under run.pl, TMPDIR $_db2_tmp, INT and QUIT as _db2_I and _db2_Q, FELIX_TEST_SLOTS=$_db2_S (none when empty), _db2_E added
  ( cd "$_db2_F" && exec env -u FELIX_TEST_NO_MANIFEST -u FELIX_TEST_JOBS -u FELIX_TEST_SLOTS -u FELIX_TEST_SLOT_NOTE -u FELIX_TEST_PART_LOG \
      -u FELIX_TEST_PART_RAN -u FELIX_TEST_PART_END -u FELIX_TEST_PART_RECORD -u FELIX_TEST_RED_JOBS -u PERL5OPT TMPDIR="$_db2_tmp" \
      ${_db2_S:+FELIX_TEST_SLOTS=$_db2_S} ${_db2_E[@]+"${_db2_E[@]}"} perl "$DB2/run.pl" "$_db2_lim" "$_db2_I" "$_db2_Q" "$_db2_Tm" "$_db2_Hu" "$_db2_c/$_db2_lab.pid" \
      "$BASH" "$_db2_T/run" "$@" )
}
# LABEL ARG...: the run in the background; its pid file is $_db2_c/LABEL.pid (the run's group), its output LABEL.out and LABEL.err. With _db2_pipe=1 the
# output goes through a pipe that a reader closes into LABEL.eof, as out=$(...) reads it, and the status goes to LABEL.rc
_db2_go() {
  _db2_lab="$1"; shift
  if [ "$_db2_pipe" = 1 ]; then
    { _db2_run "$@" 2> "$_db2_c/$_db2_lab.err"; echo $? > "$_db2_c/$_db2_lab.rc"; } | { cat > "$_db2_c/$_db2_lab.out"; : > "$_db2_c/$_db2_lab.eof"; } &
  else _db2_run "$@" > "$_db2_c/$_db2_lab.out" 2> "$_db2_c/$_db2_lab.err" &
  fi
  _db2_bg=$!
}
_db2_pid() { cat "$_db2_c/$1.pid" 2>/dev/null; }
_db2_gl()  { ps -A -ww -o pid= -o pgid= -o stat= -o command= 2>/dev/null | G="$1" LC_ALL=C awk '$2 == ENVIRON["G"] && $3 !~ /^Z/ { c = $0; sub(/^ *[0-9]+ +[0-9]+ +[^ ]+ +/, "", c); printf "%s:%s:%s\n", $1, $3, substr(c, 1, 50) }'; }
# GROUP: waits up to 30 s for the run's group to hold no live process; what is left goes into _db2_leak, and is continued and killed
_db2_grp() {
  local g="$1" i=0 l p
  [ -n "$g" ] || return 0
  while [ "$i" -lt "$_db2_gn" ]; do [ -z "$(_db2_gl "$g")" ] && break; sleep 0.2; i=$((i + 1)); done
  l="$(_db2_gl "$g")"
  [ -z "$l" ] || _db2_leak="$_db2_leak left in the run's group: $(printf '%s' "$l" | tr '\n' ' ')"
  for p in $(printf '%s\n' "$l" | sed 's/:.*//'); do kill -CONT "$p" 2>/dev/null; kill -KILL "$p" 2>/dev/null; done
}
# the end of a run, in two halves: _db2_wait0 collects its status, _db2_fin checks and ends its group and puts the knobs back
_db2_wait0() {
  if [ "$_db2_pipe" = 1 ]; then _db2_until $((_db2_lim * 5 + 50)) test -s "$_db2_c/$_db2_lab.rc"; _db2_rc="$(cat "$_db2_c/$_db2_lab.rc" 2>/dev/null)"
  else { wait "$_db2_bg"; } 2>/dev/null; _db2_rc=$?; fi
}
_db2_fin() {
  _db2_grp "$(_db2_pid "$_db2_lab")"
  if [ "$_db2_pipe" = 1 ]; then _db2_until 50 _db2_dead "$_db2_bg" || kill -KILL "$_db2_bg" 2>/dev/null; { wait "$_db2_bg"; } 2>/dev/null; fi
  _db2_E=(); _db2_I=DEFAULT; _db2_Q=DEFAULT; _db2_Tm=DEFAULT; _db2_Hu=DEFAULT; _db2_lim=100; _db2_S=8; _db2_pipe=0
}
_db2_wait() { _db2_wait0; _db2_fin; }
# LABEL SIGNAL: SIGNAL to the driver, then at most 45 s for it to end (a run still there is killed by group, and _db2_late says so)
_db2_stop() {
  local p i=0; p="$(_db2_pid "$1")"; _db2_late=""
  [ -z "$p" ] || kill -"$2" "$p" 2>/dev/null
  while [ "$i" -lt 225 ]; do kill -0 "$p" 2>/dev/null || break; sleep 0.2; i=$((i + 1)); done
  if kill -0 "$p" 2>/dev/null; then _db2_late=" the parent was still running 45 s after the signal;"; kill -KILL -- "-$p" 2>/dev/null; fi
  _db2_wait
}
_db2_rcpt() { if [ -f "$_db2_F/.git/felix-suite-receipt" ]; then echo present; else echo absent; fi; }
_db2_id()   { printf '%s' "${TMP##*/}-${_db2_c##*/}"; }
_db2_key()  { printf '%s' "${DB2#/private}/n/${_db2_c##*/}/"; }
# GROUP: the live pids of the current case's run, for the check: in its group, or with its directory or its id in the command line (not mine at _db2_hp)
_db2_ps() {
  ps -A -ww -o pid= -o pgid= -o stat= -o command= 2>/dev/null | G="${1:-}" K="$(_db2_key)" I="$(_db2_id)" H="$_db2_hp" LC_ALL=C awk \
    '$3 !~ /^Z/ && $1 != ENVIRON["H"] && (($2 == ENVIRON["G"] && ENVIRON["G"] != "") || index($0, ENVIRON["K"]) || index($0, ENVIRON["I"])) { printf "%s ", $1 }'
}
_db2_clear() { [ -z "$(_db2_ps "$1")" ]; }
_db2_dead()  { ! _db2_alive "$1"; }
_db2_alive() { local s; s="$(ps -o stat= -p "$1" 2>/dev/null | tr -d ' ')"; [ -n "$s" ] && [ "${s#Z}" = "$s" ]; }   # PID: there, and not a zombie
_db2_kf() {   # FILE...: ends the pids those files record, each only while its command line still carries the case's id
  local f p
  for f in "$@"; do [ -f "$f" ] || continue
    for p in $(cat "$f" 2>/dev/null); do case "$(ps -o command= -p "$p" 2>/dev/null)" in *"$(_db2_id)"*) kill -CONT "$p" 2>/dev/null; kill -KILL "$p" 2>/dev/null ;; esac; done
  done
}
# the unit processes of the current case: bash run --part, not perl (the holder may carry the same words)
_db2_units() { ps -A -ww -o pid= -o stat= -o command= 2>/dev/null | K="$(_db2_key)" LC_ALL=C awk '$2 !~ /^Z/ && index($0, ENVIRON["K"]) && index($0, " --part ") && $3 !~ /perl/ { printf "%s ", $1 }'; }
# DRIVERPID: "wrapper holder" - a child of the driver that has a perl child, which waits for a slot or runs a unit
_db2_wh() {
  ps -A -ww -o pid= -o ppid= -o command= 2>/dev/null | D="$1" LC_ALL=C awk '{ pp[$1] = $2; c[$1] = $3 }
    END { for (q in pp) if (c[q] ~ /perl/ && (pp[q] in pp) && pp[pp[q]] == ENVIRON["D"]) { print pp[q], q; exit } }'
}
# "unit holder": a bash run --part below a perl in the current case
_db2_uh() {
  ps -A -ww -o pid= -o ppid= -o command= 2>/dev/null | K="$(_db2_key)" LC_ALL=C awk '{ pp[$1] = $2; c[$1] = $0; w[$1] = $3 }
    END { for (q in pp) if (index(c[q], ENVIRON["K"]) && index(c[q], " --part ") && w[q] !~ /perl/ && (pp[q] in w) && w[pp[q]] ~ /perl/) { print q, pp[q]; exit } }'
}
_db2_fdn() {   # PID FD: the file descriptor FD of PID names, or nothing
  if [ -d /proc/self/fd ]; then readlink "/proc/$1/fd/$2" 2>/dev/null
  elif command -v lsof >/dev/null 2>&1; then lsof -a -p "$1" -d "$2" -Fn 2>/dev/null | LC_ALL=C awk '/^n/ { print substr($0, 2); exit }'
  fi
}
_db2_inos() {   # TMPDIR: name:kind:inode of each entry of felix-suite-slots, in name order
  perl -e 'for my $f (sort glob("$ARGV[0]/felix-suite-slots/*")) { my @s = lstat($f); (my $n = $f) =~ s{.*/}{}; print "$n:", (-f _ ? "f" : "x"), ":$s[1] " }' "$1"
}
_db2_held() {   # TMPDIR: the slot files under it that some process holds
  perl -e 'use Fcntl ":flock"; for my $f (sort glob("$ARGV[0]/felix-suite-slots/*")) { next unless -f $f; open(my $h, "<", $f) or next; flock($h, LOCK_EX | LOCK_NB) or print "$f "; close $h }' "$1"
}
_db2_hold() {   # SLOTFILE: a perl of mine holds its lock until _db2_unhold; _db2_hp is its pid
  [ -d "${1%/*}" ] || mkdir -m 0700 "${1%/*}"
  perl -e 'use Fcntl ":flock"; open(my $h, ">>", $ARGV[0]) or exit 4; flock($h, LOCK_EX | LOCK_NB) or exit 3; $| = 1; print "held\n"; sleep 300' "$1" > "$_db2_c/hold.out" 2>&1 &
  _db2_hp=$!
  _db2_until 100 test -s "$_db2_c/hold.out"
}
_db2_unhold() { [ "$_db2_hp" = 0 ] || { kill -KILL "$_db2_hp" 2>/dev/null; { wait "$_db2_hp"; } 2>/dev/null; }; _db2_hp=0; return 0; }
_db2_started() { local f r=""; for f in "$_db2_c"/started.*; do [ -e "$f" ] && r="$r${f##*/} "; done; printf '%s' "$r"; }
_db2_up() { test -e "$_db2_c/up.$1"; }
_db2_rup() { test -e "$_db2_c/rup.0010-sa.sh" && test -e "$_db2_c/rup.0020-sb.sh"; }   # R38: red's suite has started both sleepers and holds
_db2_pre()   { local f; for f in "$_db2_T"/parts/0006-*.sh; do printf '\n: > "%s/pre.done.$$"\n' "$_db2_c" >> "$f"; done; }   # the parent's prelude is done
_db2_pre_up() { ls "$_db2_c"/pre.done.* >/dev/null 2>&1; }
# "ok", or what an interrupted run left behind: LABEL STATUS (the slot files keep their names and inodes when _db2_ino0 was taken)
_db2_gone() {
  local l="$1" r="" g; g="$(_db2_pid "$l")"
  [ "$_db2_rc" = "$2" ] || r="$r exit $_db2_rc, not $2;"
  [ "$(_db2_cnt "$_db2_c/$l.out" reached)" = 0 ] || r="$r reached was printed;"
  _db2_until 25 _db2_clear "$g" || r="$r still running: $(_db2_ps "$g");"
  [ -z "$(_db2_held "$_db2_tmp")" ] || r="$r a slot is still held;"
  [ -z "$_db2_ino0" ] || [ "$(_db2_inos "$_db2_tmp")" = "$_db2_ino0" ] || r="$r the slot files changed: [$_db2_ino0] became [$(_db2_inos "$_db2_tmp")];"
  [ "$(_db2_rcpt)" = absent ] || r="$r a receipt was left;"
  [ "$_db2_ctl" = 1 ] || r="$r no positive control, so these absences say nothing;"
  printf '%s' "${r:-ok}"
}
# NAME ACTUAL EXPECTED: is, with what the run's group had left added to the actual
_db2_is() { local a="$2"; [ -z "$_db2_leak" ] || a="$a [$_db2_leak ]"; _db2_leak=""; is "$1" "$a" "$3"; }
# CASE FILE: pp/CASE/FILE is stdin behind a header that names the case's directory, id, the part and this block's directory
_db2_w() {
  mkdir -p "$DB2/pp/$1" || return 1
  { printf 'DJ2D=%q; DJ2I=%q; DJ2N=%q; DJ2L=%q\n' "$DB2/n/$1" "${TMP##*/}-$1" "$2" "$DB2"
    printf '%s\n' "printf '\\ndjy-sec %s\\n' \"\$DJ2N\""; cat; } > "$DB2/pp/$1/$2"
}
_db2_q() {   # CASE: four quick parts that note they started and pass
  local f
  for f in 0010-qa.sh 0020-qb.sh 0030-qc.sh 0040-qd.sh; do _db2_w "$1" "$f" <<'X'
: > "$DJ2D/started.$DJ2N"
ok "djy $DJ2N"
X
  done
}
_db2_sl() {   # CASE: two parts that start a sleeping child and wait for a release file, and a third that only notes it started; up.NAME says so in a record run or a plain one, rup.NAME in red's suite (R38)
  local f
  for f in 0010-sa.sh 0020-sb.sh; do _db2_w "$1" "$f" <<'X'
: > "$DJ2D/started.$DJ2N"
perl -e 'open(my $h, ">", $ARGV[0]); close $h; sleep 300' "$DJ2D/ch.$DJ2N" "$DJ2I" sl &
_k=$!
until [ -e "$DJ2D/ch.$DJ2N" ]; do sleep 0.1; done
if [ "${FELIX_TEST_NO_MANIFEST:-0}" = 1 ]; then : > "$DJ2D/rup.$DJ2N"; else : > "$DJ2D/up.$DJ2N"; fi
while [ ! -e "$DJ2D/release" ]; do sleep 0.2; done
kill "$_k" 2>/dev/null; wait "$_k" 2>/dev/null
ok "djy $DJ2N"
X
  done
  _db2_w "$1" 0030-sc.sh <<'X'
: > "$DJ2D/started.$DJ2N"
ok "djy $DJ2N"
X
}
# ---- end of the helpers

# ---- the control: released at once, the sleeper parts pass under -j 2 and leave a receipt
_db2_sl ctl; _db2_new ctl "$DB2/g-empty.tsv" + "$DB2/pp/ctl"/*.sh
: > "$_db2_c/release"; _db2_go c -j 2; _db2_wait
[ "$_db2_rc" = 0 ] && [ "$(_db2_rcpt)" = present ] && [ -e "$_db2_c/started.0030-sc.sh" ] && _db2_ctl=1
_db2_is "D6: the sleeper parts, released at once, pass under -j 2: exit 0, a receipt, and the third part ran (positive control)" "$_db2_rc $_db2_ctl" "0 1"
rm -rf "$DB2/n/ctl"

# ---- the controls for the checks that look at ps: units are counted and a perl carrying their words is not; a sleeper with the case's id is seen, and not once killed
_db2_sel snapctl; mkdir -p "$_db2_c"; mkfifo "$_db2_c/ff" 2>/dev/null
printf 'exec 3<> "$1"; read -t 60 -u 3 _x\n' > "$_db2_c/unit.sh"
bash "$_db2_c/unit.sh" "$_db2_c/ff" --part 0010-x.sh & _db2_p1=$!
bash "$_db2_c/unit.sh" "$_db2_c/ff" --part 0020-y.sh & _db2_p2=$!
perl -e 'sleep 60' "$_db2_c/unit.sh" --part 0030-z.sh & _db2_p3=$!
perl -e 'sleep 60' "$(_db2_id)" probe & _db2_p4=$!
_db2_four() { [ "$(set -- $(_db2_ps ''); echo $#)" = 4 ]; }
_db2_until 50 _db2_four
_db2_x="$(set -- $(_db2_units); echo $#) $(set -- $(_db2_ps ''); echo $#)"
kill -KILL "$_db2_p1" "$_db2_p2" "$_db2_p3" "$_db2_p4" 2>/dev/null
for _db2_p in "$_db2_p1" "$_db2_p2" "$_db2_p3" "$_db2_p4"; do { wait "$_db2_p"; } 2>/dev/null; done
_db2_y="$(_db2_until 25 _db2_clear '' && echo gone || echo "still [$(_db2_ps '')]")"
_db2_is "D6: the process checks below see what they should: two unit processes and not the perl that carries their words, four processes of the case in all, and none once killed (control)" "$_db2_x $_db2_y" "2 4 gone"
rm -rf "$DB2/n/snapctl"
# the group check finds a process left in a run's group after its leader has gone, names it, and ends it
_db2_sel gctl; mkdir -p "$_db2_c"; _db2_lab=g
perl "$DB2/run.pl" 60 DEFAULT DEFAULT DEFAULT DEFAULT "$_db2_c/g.pid" bash -c 'perl -e "sleep 100" "$0" gc & exit 0' "$(_db2_id)" & _db2_p1=$!
{ wait "$_db2_p1"; } 2>/dev/null
_db2_gn=5; _db2_grp "$(_db2_pid g)"; _db2_gn=150
case "$_db2_leak" in *"perl -e sleep 100"*) _db2_x=named ;; *) _db2_x="not named [$_db2_leak]" ;; esac   # not inside $( ): bash 3.2 ends the substitution at the pattern's )
_db2_x="$_db2_x $(_db2_until 25 _db2_clear '' && echo gone || echo still)"; _db2_leak=""
is "R12: the group check names a process left in the run's group after the leader exited, and ends it (control)" "$_db2_x" "named gone"
rm -rf "$DB2/n/gctl"

# ---- dispositions (D6, R13): a unit starts with INT and QUIT as the parent had them, in each of the four ways, and with TERM or HUP as it had them when the parent started with one of them ignored. The ticker's own reset of TERM and HUP cannot be seen here (R27): the units ignore them too, and the normal end KILLs the ticker
_db2_dp() {   # CASE: three parts that print what perl reads of INT QUIT TERM HUP, and whether they ran as a unit; the last two are a group
  local f
  for f in 0010-da.sh 0020-db.sh 0030-dc.sh; do _db2_w "$1" "$f" <<'X'
perl -e 'print "djy-sig:", join(",", map { $_ . "=" . ((defined $SIG{$_} && length $SIG{$_}) ? $SIG{$_} : "DEFAULT") } qw(INT QUIT TERM HUP)), "\n"'
case "$(ps -p $$ -o command= 2>/dev/null)" in *" --part "*) printf 'djy-mode:unit\n' ;; *) printf 'djy-mode:serial\n' ;; esac
ok "djy $DJ2N"
X
  done
}
printf 'dg\t0020-db.sh\ndg\t0030-dc.sh\n' > "$DB2/g-dis.tsv"
_db2_dp dis; _db2_new dis "$DB2/g-dis.tsv" + "$DB2/pp/dis"/*.sh
for _db2_m in "DEFAULT DEFAULT DEFAULT DEFAULT" "IGNORE IGNORE DEFAULT DEFAULT" "IGNORE DEFAULT DEFAULT DEFAULT" "DEFAULT IGNORE DEFAULT DEFAULT" "DEFAULT DEFAULT IGNORE DEFAULT" "DEFAULT DEFAULT DEFAULT IGNORE"; do
  read -r _db2_i _db2_qv _db2_tv _db2_hv <<< "$_db2_m"   # not set --: that would change the positional parameters of every part after this one
  _db2_I="$_db2_i"; _db2_Q="$_db2_qv"; _db2_Tm="$_db2_tv"; _db2_Hu="$_db2_hv"; _db2_go d3 -j 3; _db2_wait; _db2_r3="$_db2_rc"; _db2_l3="$_db2_leak"; _db2_leak=""
  _db2_I="$_db2_i"; _db2_Q="$_db2_qv"; _db2_Tm="$_db2_tv"; _db2_Hu="$_db2_hv"; _db2_go d1 -j 1; _db2_wait
  _db2_x3="$(grep '^djy-sig:' "$_db2_c/d3.out" | LC_ALL=C sort | tr '\n' ' ')"; _db2_x1="$(grep '^djy-sig:' "$_db2_c/d1.out" | LC_ALL=C sort | tr '\n' ' ')"
  _db2_k="$(grep -c "^djy-sig:INT=$_db2_i,QUIT=$_db2_qv,TERM=$_db2_tv,HUP=$_db2_hv\$" "$_db2_c/d1.out")"
  if [ "$_db2_tv$_db2_hv" = DEFAULTDEFAULT ]; then
    _db2_is "D6: -j 1 parts read INT $_db2_i and QUIT $_db2_qv from a parent started that way, TERM and HUP at their defaults, on all three parts (control)" "$_db2_k $(_db2_cnt "$_db2_c/d1.out" djy-mode:serial)" "3 3"
    _db2_leak="$_db2_l3"
    _db2_is "D6: from a parent with INT $_db2_i and QUIT $_db2_qv the three parts, two of them a group, ran as units under -j 3 and read the dispositions a -j 1 run reads" \
       "$(_db2_cnt "$_db2_c/d3.out" djy-mode:unit) $([ "$_db2_x3" = "$_db2_x1" ] && echo same || echo "differ [$_db2_x3] [$_db2_x1]")" "3 same"
  else
    _db2_w3=TERM; [ "$_db2_hv" = IGNORE ] && _db2_w3=HUP
    _db2_is "D6: -j 1 parts read $_db2_w3 ignored, and the other three signals at their defaults, from a parent started that way, on all three parts (control)" "$_db2_k $(_db2_cnt "$_db2_c/d1.out" djy-mode:serial)" "3 3"
    _db2_leak="$_db2_l3"
    _db2_is "R13: from a parent started with $_db2_w3 ignored the three parts ran as units under -j 3 and read what a -j 1 run reads, the run passed with exit 0 (not the runner's 124) and left nothing in its group" \
       "$(_db2_cnt "$_db2_c/d3.out" djy-mode:unit) $([ "$_db2_x3" = "$_db2_x1" ] && echo same || echo "differ [$_db2_x3] [$_db2_x1]") $_db2_r3" "3 same 0"
  fi
done
rm -rf "$DB2/n/dis"

# ---- an interrupt (D6): units are up, the signal goes to the parent, and the run ends as D6 says. The slot files are the same files afterwards (no step removes a slot)
# CASE SIGNAL STATUS [INT QUIT]: a -j 2 run of three parts, SIGNAL once the first two are up: _db2_x is "ok", or what was wrong
_db2_intr() {
  local c="$1" s="$2" w="$3" r="" g
  _db2_sl "$c"
  _db2_new "$c" "$DB2/g-empty.tsv" + "$DB2/pp/$c"/*.sh || { _db2_x="the copy could not be made"; return 0; }
  _db2_I="${4:-DEFAULT}"; _db2_Q="${5:-DEFAULT}"; _db2_lim=150
  _db2_go i -j 2
  _db2_until 450 _db2_up 0010-sa.sh || r=" no unit came up;"
  _db2_until 75 _db2_up 0020-sb.sh || r="$r the second unit did not come up;"
  _db2_ino0="$(_db2_inos "$_db2_tmp")"; [ -n "$_db2_ino0" ] || r="$r no slot file before the signal;"
  sleep 0.5
  _db2_stop i "$s"; r="$r$_db2_late"
  g="$(_db2_gone i "$w")"; _db2_ino0=""; [ "$g" = ok ] || r="$r$g"
  [ ! -e "$_db2_c/started.0030-sc.sh" ] || r="$r the part that was queued started;"
  _db2_x="${r:-ok}"; rm -rf "$_db2_c"
}
_db2_intr i-term TERM 143
_db2_is "D6: TERM to the parent while two units run and a third waits: exit 143, no reached, nothing of the run left, no slot held, the slot files kept (names and inodes), no receipt, the queued unit never started" "$_db2_x" ok
_db2_intr i-int INT 130
_db2_is "D6: INT to a parent started with INT at its default: exit 130, with the same afterwards" "$_db2_x" ok
_db2_intr i-hup HUP 129
_db2_is "D6: HUP to the parent: exit 129, with the same afterwards" "$_db2_x" ok
_db2_intr i-quit QUIT 131
_db2_is "R4: QUIT to a parent started with QUIT at its default: exit 131, no reached, no unit, holder or wrapper left, no slot held, the slot files kept, no receipt" "$_db2_x" ok
_db2_intr i-ign TERM 143 IGNORE IGNORE
_db2_is "D6: TERM to a parent started with INT and QUIT both ignored: exit 143, with the same afterwards" "$_db2_x" ok

# ---- a child that ignores TERM and is moved to pid 1 when its unit dies, and what it forks (D6, the ending). With a ps first on PATH that fails the ending's Nth listing (R2)
_db2_igr() {   # CASE MODE [N]: MODE n h s: a unit starts that child with & and waits, MODE u: the unit itself ignores TERM and forks a sleeper on it; TERM to the parent; afterwards nothing of the run runs, stopped or not
  local c="$1" m="$2" n="${3:-}" r="" g y
  if [ "$m" = u ]; then _db2_w "$c" 0010-ka.sh <<'X'
trap 'perl -e "sleep 300" "$DJ2I" gc & echo $! >> "$DJ2D/gc.pids"' TERM
: > "$DJ2D/up.$DJ2N"
while :; do sleep 0.1; done
X
  else _db2_w "$c" 0010-ka.sh <<'X'
perl "$DJ2L/ign.pl" "$DJ2D" "$DJ2I" "$(cat "$DJ2D/mode")" &
until [ -s "$DJ2D/ign.pid" ]; do sleep 0.1; done
: > "$DJ2D/up.$DJ2N"
wait
X
  fi
  _db2_new "$c" "$DB2/g-empty.tsv" + "$DB2/pp/$c"/0010-ka.sh || { _db2_x="the copy could not be made"; return 0; }
  printf '%s' "$m" > "$_db2_c/mode"
  [ -z "$n" ] || _db2_E=(PATH="$DB2/psshim:$PATH" DJ2_PSREAL="$(command -v ps)" DJ2_PSFAIL="$n" DJ2_PSTRIG="$_db2_c/trig" DJ2_PSCNT="$_db2_c/pscnt")
  _db2_lim=150; _db2_go i -j 2
  _db2_until 450 _db2_up 0010-ka.sh || r=" no unit came up;"
  _db2_ino0="$(_db2_inos "$_db2_tmp")"; [ -n "$_db2_ino0" ] || r="$r no slot file before the signal;"
  sleep 0.5; : > "$_db2_c/trig"
  _db2_stop i TERM; r="$r$_db2_late"
  g="$(_db2_gone i 143)"; _db2_ino0=""; [ "$g" = ok ] || r="$r$g"
  case "$m" in h|u) [ -s "$_db2_c/gc.pids" ] || r="$r the TERM never reached the child, which forked nothing;" ;; esac
  y="$({ wc -l < "$_db2_c/pscnt"; } 2>/dev/null | tr -d ' ')"
  [ -z "$n" ] || [ "${y:-0}" -ge "$n" ] || r="$r the ending asked for ${y:-0} listings, so listing $n never failed;"
  _db2_kf "$_db2_c/gc.pids" "$_db2_c/ign.pid"
  _db2_x="${r:-ok}"; rm -rf "$_db2_c"
}
_db2_igr g-ign n
_db2_is "D6: a child a unit started with & that ignores TERM, once the unit dies on TERM and the child is at pid 1, is gone when the parent has ended" "$_db2_x" ok
_db2_igr g-h h
_db2_is "D6: and so is the sleeper that child forked in its TERM handler, which is a descendant of a pid the parent had listed" "$_db2_x" ok
_db2_igr g-s s
_db2_is "D6: and so are the sleepers a child forks every 20 ms from its first TERM on, which only STOP can hold still" "$_db2_x" ok
for _db2_n in 1 2 3; do
  _db2_igr "r2-$_db2_n" u "$_db2_n"
  _db2_is "R2: with the ending's listing number $_db2_n failing (a ps first on PATH that exits 1 once), a unit that ignores TERM and forks a sleeper when it gets one leaves nothing, stopped or running, once the parent has exited with 143" "$_db2_x" ok
done

# ---- start-up (R18): TERM at a spread of short delays after the parent's prelude, over many short units under -j 4, leaves no wrapper, holder or unit once the parent has exited. The fork window of R3 itself (microseconds) rests on review and on its 12-of-12 measurement, not on this case
for _db2_n in 1 2 3 4 5 6 7 8 9 10 11 12; do _db2_w r3 "$(printf '%04d' $((_db2_n * 10)))-r$_db2_n.sh" <<'X'
: > "$DJ2D/started.$DJ2N"
perl -e 'select(undef, undef, undef, 0.6)'
ok "djy $DJ2N"
X
done
_db2_new r3 "$DB2/g-empty.tsv" + "$DB2/pp/r3"/*.sh; _db2_pre; _db2_x=""
for _db2_d in 0 0.02 0.05 0.08 0.12 0.2 0.35 0.6; do
  rm -f "$_db2_c"/pre.done.* "$_db2_c"/started.*; _db2_lim=100; _db2_go t -j 4
  _db2_until 450 _db2_pre_up; sleep "$_db2_d"; _db2_stop t TERM
  _db2_y="$(_db2_gone t 143)"; [ "$_db2_y" = ok ] || _db2_x="$_db2_x [delay $_db2_d:$_db2_y$_db2_late]"
done
_db2_is "D6: TERM at a spread of short delays during a -j 4 run's start-up (twelve short units, eight delays from 0 to 0.6 s after the parent's prelude) ends everything: each time exit 143, and no wrapper, holder or unit runs once the parent has exited" "${_db2_x:-ok}" ok
rm -rf "$DB2/n/r3"

# ---- units that outlive their wrapper (R4). With FELIX_TEST_SLOT_NOTE unset the parent looks for a wrapper that is gone only every 30 s (R13's tick), so within 3 s the holder's own check is the only thing that can end the holder and its unit
# a wrapper killed with kill -9 while its unit runs a member longer than that silence: the holder and the unit are gone within 3 s, the unit has no mark, and neither it nor its holder runs once the parent has exited. The run is read through a pipe
_db2_w lu 0010-wa.sh <<'X'
_d="$(cat "$DJ2D/w.pid")"; _p=$$; _w=""
while [ -n "$_p" ] && [ "$_p" -gt 1 ]; do
  _pp="$(ps -o ppid= -p "$_p" 2>/dev/null | tr -d ' ')"
  [ -n "$_pp" ] || break
  if [ "$_pp" = "$_d" ]; then _w="$_p"; break; fi
  _p="$_pp"
done
printf '%s %s\n' "$$" "$(ps -o ppid= -p $$ 2>/dev/null | tr -d ' ')" > "$DJ2D/lu.pids"
: > "$DJ2D/wrapper.${_w:-none}"
[ -z "$_w" ] || kill -KILL "$_w" 2>/dev/null
: > "$DJ2D/killed"
_i=0; until [ -e "$DJ2D/release" ] || [ "$_i" -ge 450 ]; do sleep 0.2; _i=$((_i + 1)); done
ok "djy $DJ2N"
X
_db2_w lu 0020-wb.sh <<'X'
ok "djy $DJ2N"
X
_db2_new lu "$DB2/g-empty.tsv" + "$DB2/pp/lu"/*.sh
_db2_pipe=1; _db2_lim=120; _db2_go w -j 2
_db2_x="$(perl "$DB2/djk.pl" 0 0 "$_db2_c/killed" 3000 pidfile "$_db2_c/lu.pids")"; _db2_y="$(_db2_alive "$(_db2_pid w)" && echo parent-running || echo parent-gone)"
_db2_is "R4: with the parent's FIFO silent for 30 s (W = 30), the holder's own check ends a unit whose wrapper was killed with kill -9: within 3 s of the kill the unit and its holder are gone, and the parent is still running" "${_db2_x%% *} $_db2_y" "gone parent-running"
_db2_wait0
_db2_until 50 test -e "$_db2_c/w.eof"; _db2_x="$([ -e "$_db2_c/w.eof" ] && echo closed || echo open)"
_db2_y=""; for _db2_p in $(cat "$_db2_c/lu.pids" 2>/dev/null); do _db2_until 25 _db2_dead "$_db2_p" && continue; _db2_y="$_db2_y $_db2_p"; done
_db2_x="$_db2_rc $(ls "$_db2_c" | grep -c '^wrapper\.[0-9]') $(_db2_cnt "$_db2_c/w.out" '  FAIL  part ended without its mark: 0010-wa.sh') $(_db2_pfx "$_db2_c/w.out" '  FAIL  part ended without its mark: 0020-wb.sh') $(_db2_rcpt) $_db2_x${_db2_y:+ still-running:$_db2_y}"
_db2_kf "$_db2_c/lu.pids"; _db2_fin
_db2_is "R4: the wrapper of a unit killed with kill -9 while the unit runs a member longer than the parent's silence: that unit alone fails without its mark, exit 1, no receipt, and once the parent has exited neither the unit nor its holder runs and the pipe it read is closed" "$_db2_x" "1 1 1 0 absent closed"
rm -rf "$DB2/n/lu"

# a wrapper killed with kill -9 while its holder waits for a slot another process holds: once the slot is let go no unit of that holder starts, and the holder is gone within 3 s
_db2_q hk; _db2_td="$DB2/td-hk"; rm -rf "$_db2_td"; mkdir -p "$_db2_td"
_db2_new hk "$DB2/g-empty.tsv" + "$DB2/pp/hk"/0010-qa.sh
_db2_hold "$_db2_tmp/felix-suite-slots/0"; _db2_ino0="$(_db2_inos "$_db2_tmp")"
_db2_S=1; _db2_lim=100; _db2_go h -j 2
_db2_r=""; _db2_wr=""; _db2_k=0
while [ "$_db2_k" -lt 300 ]; do _db2_d="$(_db2_pid h)"; [ -z "$_db2_d" ] || _db2_wr="$(_db2_wh "$_db2_d")"; [ -z "$_db2_wr" ] || break; sleep 0.2; _db2_k=$((_db2_k + 1)); done
_db2_y=""
if [ -z "$_db2_wr" ]; then _db2_r=" no wrapper with a holder was found;"
else
  sleep 1.5; _db2_hd="${_db2_wr#* }"
  # the slot is still held when the holder is looked for: only its own check of its parent (W = 30, so the parent is silent) can end it
  _db2_y="$(perl "$DB2/djk.pl" KILL "${_db2_wr% *}" - 3000 pids "$_db2_hd")"
  _db2_alive "$(_db2_pid h)" || _db2_r="$_db2_r the parent was gone when the holder was looked for;"
  case "$_db2_y" in gone*) ;; *) _db2_r="$_db2_r the holder was still there within 3 s of its wrapper being killed, the slot held ($_db2_y);" ;; esac
  _db2_unhold
  sleep 2.5
  [ -z "$(_db2_started)$(_db2_units)" ] || _db2_r="$_db2_r a unit of that holder ran ($(_db2_started)$(_db2_units));"
fi
_db2_wait; _db2_x="$_db2_rc $(_db2_cnt "$_db2_c/h.out" '  FAIL  part ended without its mark: 0010-qa.sh') $(_db2_rcpt)${_db2_r}"
_db2_unhold; _db2_ino0=""
_db2_is "R4: the wrapper of a unit killed with kill -9 while its holder waits for a slot another process holds: with the parent silent (W = 30) the holder is gone within 3 s by its own check, the slot still held; once the slot is let go no unit starts; the unit has no mark, exit 1, no receipt" "$_db2_x" "1 1 absent"
rm -rf "$DB2/n/hk" "$DB2/td-hk"; _db2_td=""

# ---- R20, R35: a holder also asks, at least every 10 s and just before it forks, who its wrapper's parent is (ps -o ppid= -p WRAPPER), and takes a pid other than the -j parent's for the parent gone.
# The kill 0 of the parent's pid does not see that while the pid is alive, and R15's start-time comparison is the Linux clock-step hazard R20 removes. A ps first on PATH answers that one call (its arguments
# hold ppid= and -p and no -A) with 1 once a gate file exists, and logs each answer it gave in $DJ2_PSCNT. The gate is written once the unit is up: within 20 s the unit is gone, the parent fails it without its mark
cat > "$DB2/oshim/ps" <<'DB2OS'
#!/bin/sh
# The real ps ($DJ2_PSREAL), except that once the file $DJ2_GATE exists a call that holds ppid= and -p and no -A prints 1 (and is logged in $DJ2_PSCNT).
case " $* " in
  *" -A "*) ;;
  *ppid=*" -p "*) if [ -e "$DJ2_GATE" ]; then echo x >> "$DJ2_PSCNT"; echo 1; exit 0; fi ;;
esac
exec "$DJ2_PSREAL" "$@"
DB2OS
chmod +x "$DB2/oshim/ps"
_db2_w or 0010-oa.sh <<'X'
printf '%s %s\n' "$$" "$(ps -o ppid= -p $$ 2>/dev/null | tr -d ' ')" > "$DJ2D/or.pids"
: > "$DJ2D/up.$DJ2N"
_i=0; until [ -e "$DJ2D/release" ] || [ "$_i" -ge 450 ]; do sleep 0.2; _i=$((_i + 1)); done
ok "djy $DJ2N"
X
_db2_new or "$DB2/g-empty.tsv" + "$DB2/pp/or"/0010-oa.sh
_db2_E=(PATH="$DB2/oshim:$PATH" DJ2_PSREAL="$(command -v ps)" DJ2_GATE="$_db2_c/gate" DJ2_PSCNT="$_db2_c/oans")
_db2_lim=100; _db2_go o -j 2
_db2_r=""; _db2_until 450 _db2_up 0010-oa.sh || _db2_r=" no unit came up;"
_db2_ino0="$(_db2_inos "$_db2_tmp")"
: > "$_db2_c/gate"
_db2_y="$(perl "$DB2/djk.pl" 0 0 - 20000 pidfile "$_db2_c/or.pids")"
: > "$_db2_c/release"
_db2_wait
# the run is not interrupted: it ends by itself with the unit's failure, so it reaches its end (reached is printed) and _db2_gone's reached test does not apply
[ "$_db2_rc" = 1 ] || _db2_r="$_db2_r exit $_db2_rc, not 1;"
_db2_until 25 _db2_clear "$(_db2_pid o)" || _db2_r="$_db2_r still running: $(_db2_ps "$(_db2_pid o)");"
[ -z "$(_db2_held "$_db2_tmp")" ] || _db2_r="$_db2_r a slot is still held;"
[ "$(_db2_inos "$_db2_tmp")" = "$_db2_ino0" ] || _db2_r="$_db2_r the slot files changed;"
[ "$(_db2_rcpt)" = absent ] || _db2_r="$_db2_r a receipt was left;"
_db2_ino0=""
_db2_x="${_db2_y%% *} $([ "$(wc -l < "$_db2_c/oans" 2>/dev/null | tr -d ' ')" -ge 1 ] 2>/dev/null && echo asked || echo not-asked) $(_db2_cnt "$_db2_c/o.out" '  FAIL  part ended without its mark: 0010-oa.sh')${_db2_r:- ok}"
_db2_is "R20: a holder whose ps -o ppid= -p WRAPPER is answered with another pid than the -j parent's takes the parent for gone: within 20 s of that answer the unit is gone, the holder asked and was answered, the parent, still running, fails the unit without its mark, exit 1, no receipt, no slot held, and nothing of the run is left" "$_db2_x" "gone asked 1 ok"
rm -rf "$DB2/n/or"

# while a unit runs, its holder's stdout and stderr are the unit's log: one regular file, the one the unit's own stdout is
_db2_w hs 0010-ha.sh <<'X'
: > "$DJ2D/up.$DJ2N"
_i=0; until [ -e "$DJ2D/release" ] || [ "$_i" -ge 450 ]; do sleep 0.2; _i=$((_i + 1)); done
ok "djy $DJ2N"
X
_db2_n="R4: while a unit runs, its holder's stdout and stderr are the unit's log: both name one regular file, which is the file the unit's own stdout names, and the run then passes"
if [ ! -d /proc/self/fd ] && ! command -v lsof >/dev/null 2>&1; then skip "$_db2_n" "neither /proc nor lsof here to read a process's descriptors"
else
  _db2_new hs "$DB2/g-empty.tsv" + "$DB2/pp/hs"/0010-ha.sh; _db2_lim=100; _db2_go s -j 2
  _db2_until 450 _db2_up 0010-ha.sh; _db2_uhv=""; _db2_k=0
  while [ "$_db2_k" -lt 50 ] && [ -z "$_db2_uhv" ]; do _db2_uhv="$(_db2_uh)"; [ -n "$_db2_uhv" ] || sleep 0.2; _db2_k=$((_db2_k + 1)); done
  _db2_f1="$(_db2_fdn "${_db2_uhv#* }" 1)"; _db2_f2="$(_db2_fdn "${_db2_uhv#* }" 2)"; _db2_fu="$(_db2_fdn "${_db2_uhv% *}" 1)"
  _db2_ff="$([ -n "$_db2_f1" ] && [ -f "$_db2_f1" ] && echo file || echo not-a-file)"   # while the unit runs: its parent's EXIT trap removes $TMP, and the log with it, once the run has ended
  : > "$_db2_c/release"; _db2_wait
  _db2_is "$_db2_n" "$([ -n "$_db2_f1" ] && [ "$_db2_f1" = "$_db2_f2" ] && [ "$_db2_f1" = "$_db2_fu" ] && [ "$_db2_ff" = file ] && echo same || echo "holder 1 [$_db2_f1] 2 [$_db2_f2], unit 1 [$_db2_fu], $_db2_ff") $_db2_rc" "same 0"
  rm -rf "$DB2/n/hs"
fi

# a background child a unit leaves running holds no slot lock, and does not keep a pipe that reads the run open (out=$(tests/run -j 2 ...) returns when the run ends)
_db2_w lc 0010-la.sh <<'X'
( perl -e 'open(my $h, ">", $ARGV[0]); print $h "$$\n"; close $h; sleep 60' "$DJ2D/lc.pid" "$DJ2I" lc & )   # no job of this shell (R16): it is left behind as D6's Reach says
until [ -s "$DJ2D/lc.pid" ]; do sleep 0.1; done
ok "djy $DJ2N"
X
_db2_w lc 0020-lb.sh <<'X'
ok "djy $DJ2N"
X
_db2_new lc "$DB2/g-empty.tsv" + "$DB2/pp/lc"/*.sh
_db2_pipe=1; _db2_lim=100; _db2_go l -j 2; _db2_wait0
_db2_until 50 test -e "$_db2_c/l.eof"
_db2_x="$_db2_rc $([ -e "$_db2_c/l.eof" ] && echo closed || echo open) $(_db2_alive "$(cat "$_db2_c/lc.pid" 2>/dev/null)" && echo child-alive || echo child-gone) [$(_db2_held "$_db2_tmp")] $(_db2_cnt "$_db2_c/l.out" reached)"
_db2_kf "$_db2_c/lc.pid"; _db2_fin
_db2_is "D6: a background child a unit leaves running holds no slot lock: the run passes, the child is still there, and every slot file grants its lock" "${_db2_x% *}" "0 closed child-alive []"
_db2_is "R4: a run read through a pipe, as out=\$(tests/run -j 2 ...) reads it, ends with the run though a unit left a background child: the pipe is closed within 10 s and the output reached its end" "$(set -- $_db2_x; echo "$2 $5")" "closed 1"
rm -rf "$DB2/n/lc"

# ---- a record run that is interrupted writes no manifest (D6, what it leaves), and red's tree goes with it
_db2_sl rrt; _db2_new rrt --red "$DB2/g-empty.tsv" "$DB2/man.tsv" "$DB2/pp/rrt"/*.sh
_db2_lim=150; _db2_go r -j 2 --record-assertions
_db2_until 450 _db2_up 0010-sa.sh; _db2_until 75 _db2_up 0020-sb.sh; _db2_until 300 _db2_rup; sleep 0.5; _db2_ino0="$(_db2_inos "$_db2_tmp")"
_db2_stop r TERM; _db2_x="$([ -e "$_db2_c/up.0020-sb.sh" ] && echo both-up || echo one-up) $(cmp -s "$DB2/man.tsv" "$_db2_T/assertions.tsv" && echo same || echo changed) $(_db2_cnt "$_db2_c/r.out" reached) $(_db2_pfx "$_db2_c/r.out" '  recorded ') $(_db2_rcpt) $([ -n "$_db2_ino0" ] && [ "$(_db2_inos "$_db2_tmp")" = "$_db2_ino0" ] && echo slots-kept || echo slots-changed)"; _db2_ino0=""
_db2_is "D6: TERM to a record run under -j 2, both units up: exit 143, the manifest as it was, no reached, no recorded line, no receipt, the slot files kept, and nothing of red's tree left in the run's group" "$_db2_rc $_db2_x" "143 both-up same 0 0 absent slots-kept"
rm -rf "$DB2/n/rrt"

# ---- no unit holds the FIFO the parent reads (D6, the wrapper): no pipe descriptor above 2 in a unit that a serial part has not
_db2_w fd 0010-pf.sh <<'X'
_probe() { perl -e 'for my $n (3 .. 250) { open(my $h, "<&=", $n) or next; print "$n " if -p $h }'; }
printf 'djy-fds:[%s]\n' "$(_probe)"
if mkfifo "$DJ2D/ff.$$" 2>/dev/null; then exec 9<> "$DJ2D/ff.$$"; fi
printf 'djy-fds-ctl:[%s]\n' "$(_probe)"
exec 9>&-; rm -f "$DJ2D/ff.$$"
case "$(ps -p $$ -o command= 2>/dev/null)" in *" --part "*) printf 'djy-mode:unit\n' ;; *) printf 'djy-mode:serial\n' ;; esac
ok "djy $DJ2N"
X
_db2_new fd "$DB2/g-empty.tsv" + "$DB2/pp/fd"/*.sh; _db2_go f3 -j 3; _db2_wait; _db2_go f1 -j 1; _db2_wait
_db2_x3="$(sed -n 's/^djy-fds:\(.*\)$/\1/p' "$_db2_c/f3.out")"; _db2_x1="$(sed -n 's/^djy-fds:\(.*\)$/\1/p' "$_db2_c/f1.out")"; _db2_y3="$(sed -n 's/^djy-fds-ctl:\(.*\)$/\1/p' "$_db2_c/f3.out")"
case "$_db2_y3" in *9*) _db2_y3=sees-9 ;; *) _db2_y3="ctl [$_db2_y3]" ;; esac   # not inside $( ): bash 3.2 ends the substitution at the pattern's )
_db2_is "D6: a unit has no pipe or FIFO descriptor above 2 that the same part has not under -j 1, and the probe sees a FIFO a part opens itself" \
   "$([ "$_db2_x3" = "$_db2_x1" ] && echo same || echo "[$_db2_x3] differs from [$_db2_x1]") $_db2_y3 $(_db2_cnt "$_db2_c/f3.out" djy-mode:unit)" "same sees-9 1"
rm -rf "$DB2/n/fd"

# ---- the part leaves the shell as it found it
_db2_unhold
rm -rf "${DB2:?}"
unset -f $(compgen -A function _db2_) 2>/dev/null
unset $(compgen -A variable _db2_) DB2 2>/dev/null
# <<< gate-friction-d-signals-blind
