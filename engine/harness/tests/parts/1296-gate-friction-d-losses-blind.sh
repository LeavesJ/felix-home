# >>> gate-friction-d-losses-blind
printf '\ngate friction D: the ending under a short read, a lost holder, a parent and a holder killed (blind, author 2; revision 10)\n'
# Blind, written on 2026-10-19 from contract D, revision 9 (D1 to D8, "Amended after review 1", "Amended after review 2"
# and "Amended after review 3"), by an author who read no implementation. tests/run, tests/red and tests/receipt.sh are run,
# never read, in copies of this suite that _suite_copy_tree (part 0003) makes under $TMP with planted parts of this block's
# own. Part 1292 holds the signals, dispositions and holders, part 1294 the slots, the gate and the log; this part holds
# what the revisions added about losing something: R13 (the parent never waits in an alarm-timed read, so an ending is not
# cut, and its @@gone read-back), R2 (a second TERM while it stops), R4 (the parent's own ending of a lost unit's holder),
# R14 and R21 (a stopper signals a member only while a listing shows its start time, and what it has stopped by its pid),
# R15 and R20 (a parent killed with -9, also while a holder waits for a slot; a holder killed with -9) and R22 (no unit runs
# before unit.I is written). Names say the clause.
#
# Every case follows R12, as in 1292: TMPDIR is a fixture directory under $TMP, the copy runs under a bounded runner
# (run.pl) that leads its own process group and starts it with INT and QUIT as the case asks and HUP and TERM at their
# defaults, every wait is bounded (loops too), and when the run has ended the case waits up to 30 s for that group to
# hold no live process (stopped or running, zombies aside), fails with what it names, and then sends CONT and KILL to
# those pids. A process outside the group is ended by the pid recorded. No signal goes to a pid found by a pattern.
#
# Readings taken where the contract leaves room, for the reviewers to confirm:
# - R13 makes the ending outlast a 2 s read with units that ignore TERM (the ending waits 10 s for its roots before
#   STOP and KILL), and FELIX_TEST_SLOT_NOTE=2 (W = 2); the INT case uses units that end at once when signalled;
# - a run ended by USR1 (which the parent does not trap, so the EXIT trap runs the ending) exits with a status that is
#   neither 0 nor the runner's 124: the contract fixes no number for it, and it differs between systems;
# - "no stderr line printed twice" is: no non-empty line of the parent's stderr occurs twice after a second TERM. That
#   case pins only that a second TERM during the ending changes nothing (R27): the parent's own ignore of TERM rests on
#   review, because on bash 3.2 the second TERM is held back until the first trap's exit, and a parent without the
#   ignore then finds every unit ended and exits 143 again;
# - a run's own slot file is found from the run (R28): a planted member writes ${FELIX_TEST_RAN%/*}, the parent's
#   $TMP/pj, to a file of the case's directory, and the case reads slot.* there and nowhere else. It does not guess where
#   mktemp -d put a run's $TMP (GNU mktemp honours TMPDIR, macOS's ignores it), and FELIX_TEST_PART_LOG is empty in a
#   member (part mode has unset it). "The holder's slot line" is line 2 of a slot.I whose first field is the holder's pid;
# - R4's lost-holder case reads: with W = 2 a STOPped holder (a stopped process cannot check its parent) whose wrapper
#   is then killed is ended by the parent alone, and once the parent has exited neither holder nor unit runs. Its second
#   unit ends while the parent is inside that ending (R13's read-back, R28): its line waits in the FIFO behind a @@tick;
# - R15's "within 3 s" is timed inside the perl (djk.pl) that takes the ps listing, from the kill to the start of the
#   first listing that shows what was asked for (the listing's own cost is not charged to the run);
# - R14 and R21 are told apart from a pid-only stopper by a ps first on PATH (ps/ in this block's directory): it runs the
#   real ps and passes its output on, and once a gate file exists it counts the listings that hold -A, ppid= and lstart=
#   (the ending's; a holder's ps -o ppid= -p holds no -A) and changes what the listings print: R14 prints P's start time
#   one second later from the second listing on; R21 leaves R (P's child) out of the first and shifts P from the third on.
#   The date is shifted by perl (Time::Local); where its shape is not the one ps prints here, a suffix makes it differ;
# - R22: the holder's ps -o lstart= -p for the unit it forked is the first such call after the gate file (the holder's
#   own was made before it took its first try, while the case held the slot). One case makes every such call print
#   nothing, one holds the first and kills the holder with kill -9 in that window; the unit must not run in either.
# An assertion whose name ends in (control) passes before D is built on purpose.
DB6="$TMP/db6"; mkdir -p "$DB6/n" "$DB6/pp" "$DB6/psshim"
_db6_E=(); _db6_I=DEFAULT; _db6_Q=DEFAULT; _db6_lim=100; _db6_S=8; _db6_td=""; _db6_hp=0; _db6_ctl=0; _db6_bg=0; _db6_rc=0; _db6_lab=""
_db6_leak=""; _db6_ino0=""; _db6_late=""; _db6_x=""; _db6_gn=150; _db6_W=""; _db6_twice=""; _db6_ol=""
: > "$DB6/g-empty.tsv"
cat > "$DB6/run.pl" <<'DB6PL'
# run.pl LIMIT INT QUIT PIDFILE CMD...: CMD leads a process group of its own, started with INT and QUIT as given, HUP and TERM at their
# defaults and no descriptor above 2; at LIMIT seconds the group is killed (exit 124). Exits as bash reports CMD's status.
use POSIX ();
my ($t, $i, $q, $f) = splice(@ARGV, 0, 4);
my $p = fork;
defined $p or exit 125;
if (!$p) { setpgrp(0, 0); $SIG{INT} = $i; $SIG{QUIT} = $q; $SIG{HUP} = "DEFAULT"; $SIG{TERM} = "DEFAULT"; POSIX::close($_) for 3 .. 255; exec @ARGV; exit 127 }
if (open(my $h, ">", "$f.t")) { print $h "$p\n"; close $h; rename "$f.t", $f }
$SIG{ALRM} = sub { kill "KILL", -$p; exit 124 };
alarm $t; waitpid $p, 0;
exit(($? & 127) ? 128 + ($? & 127) : $? >> 8);
DB6PL
cat > "$DB6/djk.pl" <<'DB6DJK'
# djk.pl SIG KILLPID WAITFILE MAXMS MODE ARG...: sends SIG to KILLPID (0: none), waits for the file WAITFILE (- : none; at most 120 s), takes the time T0, then
# takes ps listings until what MODE asks about has gone or MAXMS ms have passed. MODE pids PID...: those pids; MODE group PGID KEY ID: every live process
# (zombies aside, not this perl) in group PGID or with KEY or ID in its command line. Prints "gone MS" (MS: from T0 to the start of the first listing that
# showed none of them) or "left MS PID,PID...".
use Time::HiRes qw(time sleep);
my ($sig, $kp, $wf, $max, $mode, @a) = @ARGV;
kill $sig, $kp if $kp;
if ($wf ne "-") { my $e = time + 120; while (!-e $wf && time < $e) { sleep 0.02 } }
my $t0 = time; my $t; my @left;
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
DB6DJK
cat > "$DB6/p.pl" <<'DB6P'
# p.pl PIDFILE TERMFILE RFILE ID: writes its pid to PIDFILE, appends a line to TERMFILE for each TERM it gets and goes on running. When RFILE is not -, it first forks a child R that writes
# its pid to RFILE and sleeps (its command line carries ID). It leads a process group of its own: when the run's driver exits, the kernel sends SIGHUP and SIGCONT to a group that has just become orphaned
# and holds a stopped process, so a process stopped in the run's group would be ended by the kernel and a stopper that leaves it stopped could not be seen. P's group is orphaned when the unit dies, before any STOP.
use POSIX ();
POSIX::setpgid(0, 0);
my ($pf, $tf, $rf, $id) = @ARGV;
$SIG{TERM} = sub { if (open(my $h, ">>", $tf)) { print $h "term\n"; close $h } };
if ($rf ne "-") { my $k = fork; defined $k or exit 3; if (!$k) { if (open(my $h, ">", $rf)) { print $h "$$\n"; close $h } exec "perl", "-e", "sleep 300", $id, "R"; exit 1 } }
if (open(my $h, ">", "$pf.t")) { print $h "$$\n"; close $h; rename "$pf.t", $pf }
select(undef, undef, undef, 0.1) while 1;
DB6P
cat > "$DB6/psshim/ps" <<'DB6SH'
#!/usr/bin/env perl
# ps for R14, R21 and R22: the real ps ($DJ6_PSREAL), except by $DJ6_MODE once the file $DJ6_GATE exists.
#   skew:  a listing that holds -A, ppid= and lstart= (the ending's; a holder's ps -o ppid= -p holds no -A) is counted in $DJ6_CNT. From the second on, the row of the pid in the file $DJ6_P shows a
#          start time one second later (R14).
#   twin:  the same count. The first listing leaves out the row of the pid in the file $DJ6_R, the second is as it is, and from the third on the row of $DJ6_P is shifted (R21).
#   blank: a call that holds lstart= and -p, for a pid that is not in the file $DJ6_SKIPF (the holder's own and the parent's), prints nothing and fails: the start time of the unit a holder forked (R22).
#   block: the first such call (once: mkdir $DJ6_ONCE) writes its pid to $DJ6_BLK, waits for the file $DJ6_GO (at most 25 s), and then runs the real ps (R22).
use strict; use Time::Local;
my @a = @ARGV; my $args = " @a "; my $real = $ENV{DJ6_PSREAL}; my $mode = $ENV{DJ6_MODE} || ""; my $gate = $ENV{DJ6_GATE} || "";
sub real { exec { $real } $real, @a; exit 127 }
sub rd { my ($f) = @_; open(my $h, "<", $f) or return ""; my $l = <$h>; close $h; defined $l or return ""; $l =~ s/\s+$//; $l }
real() unless $gate ne "" && -e $gate;
if ($mode eq "blank" || $mode eq "block") {
  real() unless $args =~ /lstart=/ && $args =~ / -p (\d+)/;
  my $t = $1;
  real() if grep { $_ eq $t } split(" ", rd($ENV{DJ6_SKIPF} || ""));
  exit 1 if $mode eq "blank";
  real() unless mkdir $ENV{DJ6_ONCE};
  if (open(my $h, ">", "$ENV{DJ6_BLK}.t")) { print $h "$$\n"; close $h; rename "$ENV{DJ6_BLK}.t", $ENV{DJ6_BLK} }
  my $n = 0; while (!-e $ENV{DJ6_GO} && $n++ < 250) { select(undef, undef, undef, 0.1) }
  real();
}
real() unless $args =~ / -A / && $args =~ /ppid=/ && $args =~ /lstart=/;
open(my $c, ">>", $ENV{DJ6_CNT}) or real(); print $c "x\n"; close $c;
my $n = 0; if (open(my $c2, "<", $ENV{DJ6_CNT})) { $n++ while <$c2>; close $c2 }
my $p = rd($ENV{DJ6_P} || ""); my $r = rd($ENV{DJ6_R} || "");
my ($hide, $shift) = ("", "");
if ($mode eq "skew") { $shift = $p if $n >= 2 } elsif ($mode eq "twin") { $hide = $r if $n == 1; $shift = $p if $n >= 3 }
open(my $ps, "-|", $real, @a) or exit 127;
my %m = (Jan => 0, Feb => 1, Mar => 2, Apr => 3, May => 4, Jun => 5, Jul => 6, Aug => 7, Sep => 8, Oct => 9, Nov => 10, Dec => 11);
while (my $l = <$ps>) {
  if ($l =~ /^(\s*(\d+)\s+\d+\s+)(.*?)\s*$/) {
    my ($pre, $pid, $d) = ($1, $2, $3);
    next if $hide ne "" && $pid eq $hide;
    if ($shift ne "" && $pid eq $shift) {
      my $t;
      if ($d =~ /^\w+\s+(\w+)\s+(\d+)\s+(\d+):(\d+):(\d+)\s+(\d+)$/ && exists $m{$1}) { $t = eval { timelocal($5, $4, $3, $2, $m{$1}, $6) } }
      $d = defined $t ? scalar(localtime($t + 1)) : "$d +1s";
      $l = "$pre$d\n";
    }
  }
  print $l;
}
exit 0;
DB6SH
chmod +x "$DB6/psshim/ps"
_db6_until() { local n="$1" i=0; shift; while [ "$i" -lt "$n" ]; do "$@" && return 0; sleep 0.2; i=$((i + 1)); done; "$@"; }
_db6_cnt() { LC_ALL=C awk -v l="$2" '$0 == l { n++ } END { print n + 0 }' "$1" 2>/dev/null || echo 0; }   # FILE LINE: lines that are exactly LINE
_db6_pfx() { LC_ALL=C awk -v p="$2" 'index($0, p) == 1 { n++ } END { print n + 0 }' "$1" 2>/dev/null || echo 0; }   # FILE PREFIX: lines that start with it
_db6_sel() { _db6_c="$DB6/n/$1"; _db6_F="$_db6_c/f"; _db6_T="$_db6_F/engine/harness/tests"; _db6_tmp="${_db6_td:-$_db6_c/tmp}"; }
# CASE GROUPS MANIFEST STUB...: the copy at $DB6/n/CASE and its fixture TMPDIR; 1 when it could not be made. A MANIFEST of + is a manifest of one row for
# each STUB that says ok "djy $DJ6N", so that a run that passes has compared one and leaves a receipt
_db6_new() {
  local n="$1" s m; shift
  _db6_sel "$n"
  rm -rf "$_db6_c"; mkdir -p "$_db6_c" "$_db6_tmp" || return 1
  if [ "${2:-}" = + ]; then
    m="$_db6_c/manifest.gen"; : > "$m"
    for s in "${@:3}"; do ! grep -qF 'ok "djy $DJ6N"' "$s" || printf '1\tdjy %s\n' "${s##*/}" >> "$m"; done
    set -- "$1" "$m" "${@:3}"
  fi
  _suite_copy_tree "$_db6_F" "$@"
}
# ARG...: the copy's driver under run.pl, TMPDIR $_db6_tmp, INT and QUIT as _db6_I and _db6_Q, FELIX_TEST_SLOTS=$_db6_S (none when empty), _db6_E added
_db6_run() {
  ( cd "$_db6_F" && exec env -u FELIX_TEST_NO_MANIFEST -u FELIX_TEST_JOBS -u FELIX_TEST_SLOTS -u FELIX_TEST_SLOT_NOTE -u FELIX_TEST_PART_LOG \
      -u FELIX_TEST_PART_RAN -u FELIX_TEST_PART_END -u FELIX_TEST_PART_RECORD -u FELIX_TEST_RED_JOBS -u PERL5OPT TMPDIR="$_db6_tmp" \
      ${_db6_S:+FELIX_TEST_SLOTS=$_db6_S} ${_db6_E[@]+"${_db6_E[@]}"} perl "$DB6/run.pl" "$_db6_lim" "$_db6_I" "$_db6_Q" "$_db6_c/$_db6_lab.pid" \
      "$BASH" "$_db6_T/run" "$@" )
}
# LABEL ARG...: the run in the background; its pid file is $_db6_c/LABEL.pid (the run's group), its output LABEL.out and LABEL.err
_db6_go() { _db6_lab="$1"; shift; _db6_run "$@" > "$_db6_c/$_db6_lab.out" 2> "$_db6_c/$_db6_lab.err" & _db6_bg=$!; }
_db6_pid() { cat "$_db6_c/$1.pid" 2>/dev/null; }
_db6_gl()  { ps -A -ww -o pid= -o pgid= -o stat= -o command= 2>/dev/null | G="$1" LC_ALL=C awk '$2 == ENVIRON["G"] && $3 !~ /^Z/ { c = $0; sub(/^ *[0-9]+ +[0-9]+ +[^ ]+ +/, "", c); printf "%s:%s:%s\n", $1, $3, substr(c, 1, 50) }'; }
# GROUP: waits up to 30 s for the run's group to hold no live process; what is left goes into _db6_leak, and is continued and killed
_db6_grp() {
  local g="$1" i=0 l p
  [ -n "$g" ] || return 0
  while [ "$i" -lt "$_db6_gn" ]; do [ -z "$(_db6_gl "$g")" ] && break; sleep 0.2; i=$((i + 1)); done
  l="$(_db6_gl "$g")"
  [ -z "$l" ] || _db6_leak="$_db6_leak left in the run's group: $(printf '%s' "$l" | tr '\n' ' ')"
  for p in $(printf '%s\n' "$l" | sed 's/:.*//'); do kill -CONT "$p" 2>/dev/null; kill -KILL "$p" 2>/dev/null; done
}
_db6_wait0() { { wait "$_db6_bg"; } 2>/dev/null; _db6_rc=$?; }
_db6_fin() { _db6_grp "$(_db6_pid "$_db6_lab")"; _db6_E=(); _db6_I=DEFAULT; _db6_Q=DEFAULT; _db6_lim=100; _db6_S=8; _db6_W=""; _db6_twice=""; }
_db6_wait() { _db6_wait0; _db6_fin; }
# LABEL SIGNAL: SIGNAL to the driver (twice, 0.5 s apart, when _db6_twice is set), then at most 45 s for it to end (a run still there is killed by group, and _db6_late says so).
# _db6_stop0 does that and collects the status only; _db6_stop also checks and ends the run's group
_db6_stop0() {
  local p i=0; p="$(_db6_pid "$1")"; _db6_late=""
  [ -z "$p" ] || kill -"$2" "$p" 2>/dev/null
  [ -z "$_db6_twice" ] || { sleep 0.5; [ -z "$p" ] || kill -"$_db6_twice" "$p" 2>/dev/null; }
  while [ "$i" -lt 225 ]; do kill -0 "$p" 2>/dev/null || break; sleep 0.2; i=$((i + 1)); done
  if kill -0 "$p" 2>/dev/null; then _db6_late=" the parent was still running 45 s after the signal;"; kill -KILL -- "-$p" 2>/dev/null; fi
}
_db6_stop() { _db6_stop0 "$@"; _db6_wait; }
_db6_rcpt() { if [ -f "$_db6_F/.git/felix-suite-receipt" ]; then echo present; else echo absent; fi; }
_db6_id()   { printf '%s' "${TMP##*/}-${_db6_c##*/}"; }
_db6_key()  { printf '%s' "${DB6#/private}/n/${_db6_c##*/}/"; }
# GROUP: the live pids of the current case's run, for the check: in its group, or with its directory or its id in the command line (not mine at _db6_hp)
_db6_ps() {
  ps -A -ww -o pid= -o pgid= -o stat= -o command= 2>/dev/null | G="${1:-}" K="$(_db6_key)" I="$(_db6_id)" H="$_db6_hp" LC_ALL=C awk \
    '$3 !~ /^Z/ && $1 != ENVIRON["H"] && (($2 == ENVIRON["G"] && ENVIRON["G"] != "") || index($0, ENVIRON["K"]) || index($0, ENVIRON["I"])) { printf "%s ", $1 }'
}
_db6_clear() { [ -z "$(_db6_ps "$1")" ]; }
_db6_alive() { local s; s="$(ps -o stat= -p "$1" 2>/dev/null | tr -d ' ')"; [ -n "$s" ] && [ "${s#Z}" = "$s" ]; }   # PID: there, and not a zombie
_db6_dead()  { ! _db6_alive "$1"; }
_db6_kf() {   # FILE...: ends the pids those files record, each only while its command line still carries the case's id
  local f p
  for f in "$@"; do [ -f "$f" ] || continue
    for p in $(cat "$f" 2>/dev/null); do case "$(ps -o command= -p "$p" 2>/dev/null)" in *"$(_db6_id)"*) kill -CONT "$p" 2>/dev/null; kill -KILL "$p" 2>/dev/null ;; esac; done
  done
}
_db6_inos() {   # TMPDIR: name:kind:inode of each entry of felix-suite-slots, in name order
  perl -e 'for my $f (sort glob("$ARGV[0]/felix-suite-slots/*")) { my @s = lstat($f); (my $n = $f) =~ s{.*/}{}; print "$n:", (-f _ ? "f" : "x"), ":$s[1] " }' "$1"
}
_db6_held() {   # TMPDIR: the slot files under it that some process holds
  perl -e 'use Fcntl ":flock"; for my $f (sort glob("$ARGV[0]/felix-suite-slots/*")) { next unless -f $f; open(my $h, "<", $f) or next; flock($h, LOCK_EX | LOCK_NB) or print "$f "; close $h }' "$1"
}
_db6_up() { test -e "$_db6_c/up.$1"; }
_db6_slotline() {   # PID PART: line 2 of a slot file in the run's own pj directory, which the planted part PART wrote to pj.PART (${FELIX_TEST_RAN%/*}, R28), whose first field is PID, or nothing
  local d f l
  d="$(cat "$_db6_c/pj.$2" 2>/dev/null)"; [ -n "$d" ] || return 1
  for f in "$d"/slot.*; do [ -f "$f" ] || continue; l="$(sed -n 2p "$f" 2>/dev/null)"; case "$l" in "$1 "*) printf '%s' "$l"; return 0 ;; esac; done
  return 1
}
_db6_nslots() { ls "$(cat "$_db6_c/pj.$1" 2>/dev/null)"/slot.* 2>/dev/null | wc -l | tr -d ' '; }   # PART: how many slot files that pj directory holds
_db6_hold() {   # SLOTFILE: a perl of mine holds its lock until _db6_unhold; _db6_hp is its pid
  [ -d "${1%/*}" ] || mkdir -m 0700 "${1%/*}"
  perl -e 'use Fcntl ":flock"; open(my $h, ">>", $ARGV[0]) or exit 4; flock($h, LOCK_EX | LOCK_NB) or exit 3; $| = 1; print "held\n"; sleep 300' "$1" > "$_db6_c/hold.out" 2>&1 &
  _db6_hp=$!
  _db6_until 100 test -s "$_db6_c/hold.out"
}
_db6_unhold() { [ "$_db6_hp" = 0 ] || { kill -KILL "$_db6_hp" 2>/dev/null; { wait "$_db6_hp"; } 2>/dev/null; }; _db6_hp=0; return 0; }
_db6_started() { local f r=""; for f in "$_db6_c"/started.*; do [ -e "$f" ] && r="$r${f##*/} "; done; printf '%s' "$r"; }
# the parent's prelude is done (a mark at the end of the copy's 0006), and the parent's $TMP is recorded in ptmp (the first prelude to run is the parent's)
_db6_pre() { local f; for f in "$_db6_T"/parts/0006-*.sh; do printf '\n[ -e %q ] || printf "%%s\\n" "$TMP" > %q\n: > "%s/pre.done.$$"\n' "$_db6_c/ptmp" "$_db6_c/ptmp" "$_db6_c" >> "$f"; done; }
_db6_pre_up() { ls "$_db6_c"/pre.done.* >/dev/null 2>&1; }
_db6_hpid() {   # the pid on line 2 of the first slot.* of the parent's pj directory that has one (the holder's, R4), or nothing
  local t f l; t="$(cat "$_db6_c/ptmp" 2>/dev/null)"; [ -n "$t" ] || return 1
  for f in "$t"/pj/slot.*; do [ -f "$f" ] || continue; l="$(sed -n 2p "$f" 2>/dev/null)"; [ -n "$l" ] || continue; printf '%s' "${l%% *}"; return 0; done
  return 1
}
_db6_hpid_up() { [ -n "$(_db6_hpid)" ]; }
_db6_only() {   # GROUP PID: waits up to 8 s for the run to hold no live process but PID (0: none), by its group, its directory or its id (_db6_ps); _db6_ol is what else was there, named
  local g="$1" k="$2" i=0 l="" p
  while [ "$i" -lt 40 ]; do l=""; for p in $(_db6_ps "$g"); do [ "$p" = "$k" ] || l="$l $p:$(ps -o stat= -p "$p" 2>/dev/null | tr -d ' ')"; done; [ -z "$l" ] && break; sleep 0.2; i=$((i + 1)); done
  _db6_ol="${l# }"
}
_db6_pst() {   # PID: runs, stopped or gone
  local s; s="$(ps -o stat= -p "${1:-0}" 2>/dev/null | tr -d ' ')"
  case "$s" in ''|Z*) echo gone ;; *T*) echo stopped ;; *) echo runs ;; esac
}
# "ok", or what an interrupted run left behind: LABEL STATUS (a STATUS of non0 is any but 0 and the runner's 124)
_db6_gone() {
  local l="$1" r="" g; g="$(_db6_pid "$l")"
  case "$2" in
    non0) { [ "$_db6_rc" != 0 ] && [ "$_db6_rc" != 124 ]; } || r="$r exit $_db6_rc, which is 0 or the runner's 124;" ;;
    *) [ "$_db6_rc" = "$2" ] || r="$r exit $_db6_rc, not $2;" ;;
  esac
  [ "$(_db6_cnt "$_db6_c/$l.out" reached)" = 0 ] || r="$r reached was printed;"
  _db6_until 25 _db6_clear "$g" || r="$r still running: $(_db6_ps "$g");"
  [ -z "$(_db6_held "$_db6_tmp")" ] || r="$r a slot is still held;"
  [ -z "$_db6_ino0" ] || [ "$(_db6_inos "$_db6_tmp")" = "$_db6_ino0" ] || r="$r the slot files changed: [$_db6_ino0] became [$(_db6_inos "$_db6_tmp")];"
  [ "$(_db6_rcpt)" = absent ] || r="$r a receipt was left;"
  [ "$_db6_ctl" = 1 ] || r="$r no positive control, so these absences say nothing;"
  printf '%s' "${r:-ok}"
}
# NAME ACTUAL EXPECTED: is, with what the run's group had left added to the actual
_db6_is() { local a="$2"; [ -z "$_db6_leak" ] || a="$a [$_db6_leak ]"; _db6_leak=""; is "$1" "$a" "$3"; }
# CASE FILE: pp/CASE/FILE is stdin behind a header that names the case's directory, id, the part and this block's directory
_db6_w() {
  mkdir -p "$DB6/pp/$1" || return 1
  { printf 'DJ6D=%q; DJ6I=%q; DJ6N=%q; DJ6L=%q\n' "$DB6/n/$1" "${TMP##*/}-$1" "$2" "$DB6"
    printf '%s\n' "printf '\\ndjy-sec %s\\n' \"\$DJ6N\""; cat; } > "$DB6/pp/$1/$2"
}
_db6_long() {   # CASE FILE...: parts that write the pids of the unit and of its parent and the run's own pj directory (R28), note they are up, and wait for a release file (at most 90 s) before they pass
  local c="$1" f; shift
  for f in "$@"; do _db6_w "$c" "$f" <<'X'
printf '%s %s\n' "$$" "$(ps -o ppid= -p $$ 2>/dev/null | tr -d ' ')" > "$DJ6D/pids.$DJ6N"
printf '%s\n' "${FELIX_TEST_RAN%/*}" > "$DJ6D/pj.$DJ6N"
: > "$DJ6D/up.$DJ6N"
_i=0; until [ -e "$DJ6D/release" ] || [ "$_i" -ge 450 ]; do sleep 0.2; _i=$((_i + 1)); done
ok "djy $DJ6N"
X
  done
}
_db6_quick() { _db6_w "$1" "$2" <<'X'
: > "$DJ6D/started.$DJ6N"
ok "djy $DJ6N"
X
}
# CASE FILE: a part that notes it started, waits for the file $DJ6D/release2 (at most 60 s) and passes
_db6_lateq() { _db6_w "$1" "$2" <<'X'
: > "$DJ6D/started.$DJ6N"
_i=0; until [ -e "$DJ6D/release2" ] || [ "$_i" -ge 300 ]; do sleep 0.2; _i=$((_i + 1)); done
ok "djy $DJ6N"
X
}
# ---- end of the helpers

# ---- the control: two quick parts pass under -j 2 and leave a receipt
_db6_quick ctl 0010-qa.sh; _db6_quick ctl 0020-qb.sh; _db6_new ctl "$DB6/g-empty.tsv" + "$DB6/pp/ctl"/*.sh
_db6_go c -j 2; _db6_wait
[ "$_db6_rc" = 0 ] && [ "$(_db6_rcpt)" = present ] && _db6_ctl=1
_db6_is "D6: two quick parts pass under -j 2: exit 0 and a receipt (positive control)" "$_db6_rc $_db6_ctl" "0 1"
rm -rf "$DB6/n/ctl"
# the timing perl: it reports a killed process gone and a living one left, and finds a member of a group by the group and by the id in its command line
_db6_sel djk; mkdir -p "$_db6_c"
perl -e 'sleep 60' "$(_db6_id)" djk & _db6_p1=$!
perl -e 'sleep 60' "$(_db6_id)" djk & _db6_p2=$!
_db6_x="$(perl "$DB6/djk.pl" KILL "$_db6_p1" - 3000 pids "$_db6_p1" | sed 's/ .*//') $(perl "$DB6/djk.pl" 0 0 - 300 pids "$_db6_p2" | sed 's/ .*//') $(perl "$DB6/djk.pl" 0 0 - 300 group 0 "$(_db6_id)" "$(_db6_id)" | sed 's/ .*//')"
kill -KILL "$_db6_p1" "$_db6_p2" 2>/dev/null; for _db6_p in "$_db6_p1" "$_db6_p2"; do { wait "$_db6_p"; } 2>/dev/null; done
_db6_x="$_db6_x $(perl "$DB6/djk.pl" 0 0 - 3000 group 0 "$(_db6_id)" "$(_db6_id)" | sed 's/ .*//')"
_db6_is "R12: the timing perl reports a killed process gone, a living one left, a process with the case's id in its command line left, and none once both are killed (control)" "$_db6_x" "gone left left gone"
rm -rf "$DB6/n/djk"
# the group check finds a process left in a run's group after its leader has gone, names it, and ends it
_db6_sel gctl; mkdir -p "$_db6_c"; _db6_lab=g
perl "$DB6/run.pl" 60 DEFAULT DEFAULT "$_db6_c/g.pid" bash -c 'perl -e "sleep 100" "$0" gc & exit 0' "$(_db6_id)" & _db6_p1=$!
{ wait "$_db6_p1"; } 2>/dev/null
_db6_gn=5; _db6_grp "$(_db6_pid g)"; _db6_gn=150
case "$_db6_leak" in *"perl -e sleep 100"*) _db6_x=named ;; *) _db6_x="not named [$_db6_leak]" ;; esac   # not inside $( ): bash 3.2 ends the substitution at the pattern's )
_db6_x="$_db6_x $(_db6_until 25 _db6_clear '' && echo gone || echo still)"; _db6_leak=""
is "R12: the group check names a process left in the run's group after the leader exited, and ends it (control)" "$_db6_x" "named gone"
rm -rf "$DB6/n/gctl"

# ---- R13: the parent never waits in an alarm-timed read, so no ending is cut. W is FELIX_TEST_SLOT_NOTE (2 here), so a 2 s read would be cut by an ending of 10 s or more
# CASE SIGNAL STATUS KIND NUNITS: NUNITS parts (KIND ign: they trap TERM, fork a sleeper on it and go on, so the ending waits 10 s for them before STOP and KILL; KIND quick: they end at
# once when signalled), a -j 2 run with W = $_db6_W (the default when empty), SIGNAL to the parent once they are up; _db6_x is "ok", or what was wrong
_db6_sig() {
  local c="$1" sg="$2" st="$3" kind="$4" nu="${5:-1}" tw="$_db6_twice" r="" g f d=""
  for f in 0010-ka.sh 0020-kb.sh; do
    [ "$f" = 0010-ka.sh ] || [ "$nu" = 2 ] || continue
    if [ "$kind" = ign ]; then _db6_w "$c" "$f" <<'X'
trap 'perl -e "sleep 300" "$DJ6I" gc & echo $! >> "$DJ6D/gc.pids"' TERM
: > "$DJ6D/up.$DJ6N"
while :; do sleep 0.1; done
X
    else _db6_w "$c" "$f" <<'X'
: > "$DJ6D/up.$DJ6N"
_i=0; until [ -e "$DJ6D/release" ] || [ "$_i" -ge 450 ]; do sleep 0.2; _i=$((_i + 1)); done
X
    fi
  done
  _db6_new "$c" "$DB6/g-empty.tsv" + "$DB6/pp/$c"/*.sh || { _db6_x="the copy could not be made"; return 0; }
  [ -z "$_db6_W" ] || _db6_E=(FELIX_TEST_SLOT_NOTE="$_db6_W")
  _db6_lim=150; _db6_go i -j 2
  _db6_until 450 _db6_up 0010-ka.sh || r=" no unit came up;"
  [ "$nu" != 2 ] || _db6_until 75 _db6_up 0020-kb.sh || r="$r the second unit did not come up;"
  _db6_ino0="$(_db6_inos "$_db6_tmp")"; [ -n "$_db6_ino0" ] || r="$r no slot file before the signal;"
  sleep 0.5
  _db6_stop i "$sg"; r="$r$_db6_late"
  g="$(_db6_gone i "$st")"; _db6_ino0=""; [ "$g" = ok ] || r="$r$g"
  [ "$kind" != ign ] || [ -s "$_db6_c/gc.pids" ] || r="$r the TERM never reached a unit;"
  d="$(LC_ALL=C grep -v '^$' "$_db6_c/i.err" 2>/dev/null | LC_ALL=C sort | uniq -d | head -n 2 | tr '\n' '|')"
  [ -z "$tw" ] || [ -z "$d" ] || r="$r a stderr line was printed twice: $d"
  _db6_kf "$_db6_c/gc.pids"
  _db6_x="${r:-ok}"; rm -rf "$_db6_c"
}
_db6_W=2; _db6_sig r13-term TERM 143 ign 1
_db6_is "R13: with FELIX_TEST_SLOT_NOTE=2 (W is 2, so the ending outlasts what a 2 s read -t left it) and a unit that ignores TERM, TERM to the parent once the unit is up: exit 143, no reached, nothing of the run left, stopped or running, no slot held, the slot files kept, no receipt" "$_db6_x" ok
_db6_W=2; _db6_sig r13-int INT 130 quick 2
_db6_is "R13: the same with INT, sent to a parent started with INT at its default, and two units that end at once when signalled (W is 2): exit 130, with the same afterwards" "$_db6_x" ok
_db6_W=2; _db6_sig r13-usr1 USR1 non0 ign 2
_db6_is "R13: USR1, which the parent does not trap, sent while two units that ignore TERM run (W is 2): the EXIT trap's ending completes: a status that is not 0, no reached, nothing of the run left, stopped or running, no slot held, the slot files kept, no receipt" "$_db6_x" ok
_db6_W=""; _db6_twice=TERM; _db6_sig d6-twice TERM 143 ign 1
_db6_is "D6: a second TERM sent to the parent during its ending changes nothing: exit 143, nothing of the run left, stopped or running, no slot held, no receipt, and no line of its stderr printed twice" "$_db6_x" ok

# ---- R4: the parent's own ending of a lost unit's holder. A stopped holder cannot check its parent, so with its wrapper killed (W = 2: the parent finds the wrapper gone within a few seconds) only the parent can end it.
# R13/R28: the second unit ends while the parent is inside that ending (about 10 s: a stopped holder answers kill -0), so its line waits in the FIFO behind at least one @@tick, and the first look at the
# wrappers after the ending finds its wrapper gone. The unit still reads as ok: a build that marks a wrapper found gone lost at once, or waits only for the next @@tick, fails it.
_db6_long lh 0010-lh.sh; _db6_lateq lh 0020-lr.sh
_db6_new lh "$DB6/g-empty.tsv" + "$DB6/pp/lh"/*.sh
_db6_E=(FELIX_TEST_SLOT_NOTE=2); _db6_lim=150; _db6_go l -j 2
_db6_r=""
_db6_until 450 _db6_up 0010-lh.sh || _db6_r=" the unit did not come up;"
read -r _db6_u _db6_h < "$_db6_c/pids.0010-lh.sh" 2>/dev/null
_db6_wr="$(ps -o ppid= -p "${_db6_h:-0}" 2>/dev/null | tr -d ' ')"
_db6_sl="$(_db6_slotline "${_db6_h:-0}" 0010-lh.sh >/dev/null && echo slot-line || echo "no-slot-line[holder ${_db6_h:-none}: pj [$(cat "$_db6_c/pj.0010-lh.sh" 2>/dev/null)], $(_db6_nslots 0010-lh.sh) slot files in it]")"
if [ -n "${_db6_u:-}" ] && [ -n "${_db6_h:-}" ] && [ -n "$_db6_wr" ] && [ "$_db6_wr" -gt 1 ]; then
  _db6_until 150 test -e "$_db6_c/started.0020-lr.sh" || _db6_r="$_db6_r the second unit never started;"
  kill -STOP "$_db6_h" 2>/dev/null; kill -KILL "$_db6_wr" 2>/dev/null
  sleep 0.6
  _db6_st="$(ps -o stat= -p "$_db6_h" 2>/dev/null | tr -d ' ')"
  case "$_db6_st" in *T*) ;; *) _db6_r="$_db6_r the holder was not stopped 0.6 s after the stop (stat [$_db6_st]);" ;; esac
  sleep 4; : > "$_db6_c/release2"   # about 5 s after the kill: inside the parent's ending of the stopped holder
  _db6_wait0
  _db6_alive "$_db6_h" && _db6_r="$_db6_r the stopped holder $_db6_h still ran after the parent had exited;"
  _db6_alive "$_db6_u" && _db6_r="$_db6_r its unit $_db6_u still ran after the parent had exited;"
else _db6_r="$_db6_r no unit, holder and wrapper pids were found [$_db6_u $_db6_h $_db6_wr];"; _db6_wait0
fi
_db6_x="$_db6_rc $(_db6_cnt "$_db6_c/l.out" '  FAIL  part ended without its mark: 0010-lh.sh') $(_db6_pfx "$_db6_c/l.out" '  FAIL  part ended without its mark: 0020-lr.sh') $(_db6_cnt "$_db6_c/l.out" '  ok    djy 0020-lr.sh') $(_db6_rcpt) $_db6_sl${_db6_r}"
_db6_kf "$_db6_c/pids.0010-lh.sh"; _db6_fin
_db6_is "R4: a holder STOPped and its wrapper then killed with kill -9, W = 2: the parent ends the lost unit's holder (its pid and start time are line 2 of the slot file, found in the run's own pj directory): once the parent has exited the holder and its unit are gone, the unit failed without its mark, exit 1, no receipt" "$_db6_x" "1 1 0 1 absent slot-line"
rm -rf "$DB6/n/lh"

# ---- R15 (a): the parent killed with kill -9 runs no trap, so each holder finds its parent gone: within 3 s no holder or unit of the run is left, stopped or running, and every slot's file grants a lock
_db6_long pk 0010-pa.sh 0020-pb.sh; _db6_new pk "$DB6/g-empty.tsv" + "$DB6/pp/pk"/*.sh
_db6_lim=150; _db6_go p -j 2
_db6_r=""; _db6_until 450 _db6_up 0010-pa.sh || _db6_r=" no unit came up;"; _db6_until 75 _db6_up 0020-pb.sh || _db6_r="$_db6_r the second unit did not come up;"
_db6_ino0="$(_db6_inos "$_db6_tmp")"; _db6_g="$(_db6_pid p)"; sleep 0.5
_db6_y="$(perl "$DB6/djk.pl" KILL "$_db6_g" - 3000 group "$_db6_g" "$(_db6_key)" "$(_db6_id)")"
case "$_db6_y" in gone*) ;; *) _db6_r="$_db6_r the run was not gone within 3 s of its parent's kill -9 ($_db6_y);" ;; esac
_db6_hl="$(_db6_held "$_db6_tmp")"; [ -z "$_db6_hl" ] || _db6_r="$_db6_r a slot was still held: $_db6_hl;"
[ "$_db6_ino0" = "$(_db6_inos "$_db6_tmp")" ] || _db6_r="$_db6_r the slot files changed;"
_db6_wait0; _db6_x="$_db6_rc $(_db6_rcpt) $(_db6_cnt "$_db6_c/p.out" reached)${_db6_r}"
_db6_kf "$_db6_c/pids.0010-pa.sh" "$_db6_c/pids.0020-pb.sh"; _db6_fin; _db6_ino0=""
_db6_is "R15: the parent killed with kill -9 while two units run a long member: within 3 s nothing of the run runs, stopped or not, and every slot file grants its lock (the parent's status is 137, no receipt, no reached)" "$_db6_x" "137 absent 0"
rm -rf "$DB6/n/pk"

# ---- R15 (b): a holder killed with kill -9 frees its slot at once while its unit runs on below pid 1: within 3 s the unit is gone, and the run fails naming it
_db6_long hh 0010-hh.sh; _db6_quick hh 0020-hq.sh; _db6_new hh "$DB6/g-empty.tsv" + "$DB6/pp/hh"/*.sh
_db6_lim=150; _db6_go h -j 2
_db6_r=""; _db6_until 450 _db6_up 0010-hh.sh || _db6_r=" the unit did not come up;"
read -r _db6_u _db6_h < "$_db6_c/pids.0010-hh.sh" 2>/dev/null
_db6_sl="$(_db6_slotline "${_db6_h:-0}" 0010-hh.sh >/dev/null && echo slot-line || echo "no-slot-line[holder ${_db6_h:-none}: pj [$(cat "$_db6_c/pj.0010-hh.sh" 2>/dev/null)], $(_db6_nslots 0010-hh.sh) slot files in it]")"
if [ -n "${_db6_u:-}" ] && [ -n "${_db6_h:-}" ] && [ "$_db6_h" -gt 1 ]; then
  _db6_y="$(perl "$DB6/djk.pl" KILL "$_db6_h" - 3000 pids "$_db6_u")"
  case "$_db6_y" in gone*) ;; *) _db6_r="$_db6_r the unit was not gone within 3 s of its holder's kill -9 ($_db6_y);" ;; esac
else _db6_r="$_db6_r no unit and holder pids were found [$_db6_u $_db6_h];"
fi
_db6_wait0
_db6_until 25 _db6_clear "$(_db6_pid h)" || _db6_r="$_db6_r still running after the parent had exited: $(_db6_ps "$(_db6_pid h)");"
_db6_x="$_db6_rc $(_db6_cnt "$_db6_c/h.out" '  FAIL  part ended without its mark: 0010-hh.sh') $(_db6_pfx "$_db6_c/h.out" '  FAIL  part ended without its mark: 0020-hq.sh') $(_db6_rcpt) $_db6_sl [$(_db6_held "$_db6_tmp")]${_db6_r}"
_db6_kf "$_db6_c/pids.0010-hh.sh"; _db6_fin
_db6_is "R15: a holder killed with kill -9 while its unit runs a member (its pid is line 2 of the slot file): within 3 s the unit is gone, the run fails naming it (part ended without its mark), the other unit passes, exit 1, no receipt, no slot held, and nothing of the run is left" "$_db6_x" "1 1 0 absent slot-line []"
rm -rf "$DB6/n/hh"

# ---- R14: a stopper signals a member only while a listing shows its pid with its start time (R28). A unit starts P with &, which writes its pid, logs each TERM it gets and goes on running. A ps first on
# PATH shows P's start one second later from the ending's second listing on. The unit dies on the ending's TERM before that listing, so P (under pid 1 by then) is a member held with its first
# listing's start time, and is not present in the second: a stopper that signals by pid alone STOPs and KILLs it. R21's twin (mode twin): R, a child P starts, is left out of the first listing and shown
# from the second, so the second listing adds a member and step 4 makes a second round with the third listing, where P's start is shifted after P was sent STOP; P ignores TERM. What a stopper has
# stopped it signals by its pid from then on, so P and R are gone; a build without that leaves P stopped.
# CASE MODE: _db6_x is "ok", or what was wrong
_db6_pr() {
  local c="$1" m="$2" r="" g p q lc w
  _db6_w "$c" 0010-pa.sh <<'X'
_ra="$(cat "$DJ6D/rarg")"
perl "$DJ6L/p.pl" "$DJ6D/p.pid" "$DJ6D/p.terms" "$_ra" "$DJ6I" &
_i=0
until [ -s "$DJ6D/p.pid" ] && { [ "$_ra" = - ] || [ -s "$_ra" ]; }; do [ "$_i" -lt 300 ] || break; sleep 0.1; _i=$((_i + 1)); done
: > "$DJ6D/up.$DJ6N"
wait
X
  _db6_new "$c" "$DB6/g-empty.tsv" + "$DB6/pp/$c"/0010-pa.sh || { _db6_x="the copy could not be made"; return 0; }
  if [ "$m" = twin ]; then printf '%s' "$_db6_c/r.pid" > "$_db6_c/rarg"; else printf '%s' - > "$_db6_c/rarg"; fi
  _db6_E=(PATH="$DB6/psshim:$PATH" DJ6_PSREAL="$(command -v ps)" DJ6_MODE="$m" DJ6_GATE="$_db6_c/gate" DJ6_CNT="$_db6_c/pscnt" DJ6_P="$_db6_c/p.pid" DJ6_R="$_db6_c/r.pid")
  _db6_lim=150; _db6_go i -j 2
  _db6_until 450 _db6_up 0010-pa.sh || r=" no unit came up;"
  sleep 0.5; : > "$_db6_c/gate"
  _db6_stop0 i TERM; r="$r$_db6_late"; _db6_wait0
  g="$(_db6_pid i)"; p="$(cat "$_db6_c/p.pid" 2>/dev/null)"; q="$(cat "$_db6_c/r.pid" 2>/dev/null)"
  [ -n "$p" ] || r="$r P never wrote its pid;"
  if [ "$m" = twin ]; then _db6_only "$g" 0; w=3; else _db6_only "$g" "${p:-0}"; w=2; fi
  lc="$(wc -l < "$_db6_c/pscnt" 2>/dev/null | tr -d ' ')"; [ "${lc:-0}" -ge "$w" ] 2>/dev/null || r="$r the ending asked for ${lc:-0} listings, so listing $w never came;"
  if [ "$m" = twin ]; then _db6_x="$_db6_rc P-$(_db6_pst "${p:-0}") R-$(_db6_pst "${q:-0}") ${_db6_ol:-none-else} [$(_db6_held "$_db6_tmp")] $(_db6_cnt "$_db6_c/i.out" reached) $(_db6_rcpt)${r}"
  else _db6_x="$_db6_rc P-$(_db6_pst "${p:-0}") terms-$(wc -l < "$_db6_c/p.terms" 2>/dev/null | tr -d ' ') ${_db6_ol:-none-else} [$(_db6_held "$_db6_tmp")] $(_db6_cnt "$_db6_c/i.out" reached) $(_db6_rcpt)${r}"
  fi
  _db6_kf "$_db6_c/p.pid" "$_db6_c/r.pid"; _db6_fin; rm -rf "$_db6_c"
}
_db6_pr r14 skew
_db6_is "R14: a ps that shows planted process P's start one second later from the ending's second listing on: once the parent has exited with 143, P still runs, is not stopped, got exactly one TERM, and nothing else of the run is left, stopped or running (a stopper that signals by pid alone STOPs and KILLs it)" "$_db6_x" "143 P-runs terms-1 none-else [] 0 absent"
_db6_pr r21 twin
_db6_is "R21: with R, P's child, left out of the ending's first listing and shown from the second, so that step 4 makes a second round, and P's start shifted from the third listing on, after P was sent STOP, P that ignores TERM and R are both gone once the parent has exited with 143, nothing of the run left stopped or running (what a stopper has stopped it signals by its pid)" "$_db6_x" "143 P-gone R-gone none-else [] 0 absent"

# ---- R15 (a), R20: the parent killed with kill -9 while a holder WAITS for a slot (R28, R36). One slot, its lock held by a perl of mine, two parts: once the parent's prelude has ended, a holder has written its slot line
# (_db6_hpid_up) and 1.5 s have passed (the holder tries each slot, then waits 1 s and tries again, so at least one poll has run) the parent is killed with kill -9. After the prelude's mark the parent still sources 0007 and
# the lib files before it forks a wrapper, so a kill 2 s after the mark could land before any holder existed and pass for every build. Within 3 s nothing of the run is left, stopped or running; and once I let the slot go no unit
# starts. A holder that checks the parent only while its unit runs outlives the run, waiting
_db6_quick pw 0010-wa.sh; _db6_quick pw 0020-wb.sh
_db6_td="$DB6/td-pw"; rm -rf "$_db6_td"; mkdir -p "$_db6_td"
_db6_new pw "$DB6/g-empty.tsv" + "$DB6/pp/pw"/*.sh
_db6_pre; _db6_hold "$_db6_tmp/felix-suite-slots/0"; _db6_ino0="$(_db6_inos "$_db6_tmp")"
_db6_S=1; _db6_lim=150; _db6_go w -j 2
_db6_r=""; _db6_until 450 _db6_pre_up || _db6_r=" the parent's prelude never ended;"
_db6_until 450 _db6_hpid_up || _db6_r="$_db6_r no holder wrote its slot line before the kill;"
sleep 1.5
[ -z "$(_db6_started)" ] || _db6_r="$_db6_r a unit ran while the slot was held elsewhere ($(_db6_started));"
_db6_g="$(_db6_pid w)"
_db6_y="$(perl "$DB6/djk.pl" KILL "$_db6_g" - 3000 group "$_db6_g" "$(_db6_key)" "$(_db6_id)")"
case "$_db6_y" in gone*) ;; *) _db6_r="$_db6_r the run was not gone within 3 s of its parent's kill -9 ($_db6_y);" ;; esac
_db6_unhold; sleep 3
[ -z "$(_db6_started)" ] || _db6_r="$_db6_r a unit started once the slot was let go ($(_db6_started));"
[ -z "$(_db6_held "$_db6_tmp")" ] || _db6_r="$_db6_r a slot is held;"
[ "$_db6_ino0" = "$(_db6_inos "$_db6_tmp")" ] || _db6_r="$_db6_r the slot files changed;"
_db6_wait0; _db6_x="$_db6_rc $(_db6_rcpt) $(_db6_cnt "$_db6_c/w.out" reached)${_db6_r}"
_db6_fin; _db6_ino0=""; _db6_td=""
_db6_is "R20: the parent killed with kill -9 while its holders wait for the only slot, held by another process: within 3 s nothing of the run is left, stopped or running; once the slot is let go no unit starts, and every slot file grants its lock (the parent's status is 137, no receipt, no reached)" "$_db6_x" "137 absent 0"
rm -rf "$DB6/n/pw" "$DB6/td-pw"

# ---- R22: no unit runs before unit.I is written. With the only slot held by a perl of mine, the holder has made its own ps call (its slot line is there); then a gate file starts a ps first on PATH that treats
# the next ps -o lstart= -p for any pid but the holder's and the parent's, which is the unit the holder forked, as the case asks, and I let the slot go.
# blank: every such call prints nothing (the holder takes it five times, 0.2 s apart, and gives up): the unit never runs, has no mark and the run fails. block: the first is held while the holder is killed with
# kill -9, and then let through: the forked unit, held back until unit.I is written, must find its holder gone and exit without running the member
# CASE MODE: _db6_x is "ok" or what was wrong
_db6_u22() {
  local c="$1" m="$2" r="" h par
  _db6_quick "$c" 0010-ua.sh
  _db6_td="$DB6/td-$c"; rm -rf "$_db6_td"; mkdir -p "$_db6_td"
  _db6_new "$c" "$DB6/g-empty.tsv" + "$DB6/pp/$c"/0010-ua.sh || { _db6_x="the copy could not be made"; _db6_td=""; return 0; }
  _db6_pre; _db6_hold "$_db6_tmp/felix-suite-slots/0"
  _db6_E=(PATH="$DB6/psshim:$PATH" DJ6_PSREAL="$(command -v ps)" DJ6_MODE="$m" DJ6_GATE="$_db6_c/gate" DJ6_ONCE="$_db6_c/once" DJ6_BLK="$_db6_c/blk" DJ6_GO="$_db6_c/go" DJ6_SKIPF="$_db6_c/skip")
  _db6_S=1; _db6_lim=120; _db6_go u -j 2
  _db6_until 450 _db6_pre_up || r=" the parent's prelude never ended;"
  _db6_until 100 _db6_hpid_up || r="$r the holder never wrote its slot line;"
  h="$(_db6_hpid)"; par="$(_db6_pid u)"
  printf '%s %s' "$h" "$par" > "$_db6_c/skip"
  : > "$_db6_c/gate"; _db6_unhold
  if [ "$m" = block ]; then
    _db6_until 150 test -s "$_db6_c/blk" || r="$r no ps -o lstart= call was held;"
    [ -z "$h" ] || kill -KILL "$h" 2>/dev/null
    sleep 0.3; : > "$_db6_c/go"
    sleep 4
  fi
  _db6_wait0
  _db6_x="$_db6_rc $(_db6_cnt "$_db6_c/u.out" '  FAIL  part ended without its mark: 0010-ua.sh') [$(_db6_started)] $(_db6_rcpt)${r}"
  _db6_fin; _db6_td=""; rm -rf "$_db6_c" "$DB6/td-$c"
}
_db6_u22 u22-blank blank
_db6_is "R22: where every ps -o lstart= for the forked unit prints nothing (five tries), the holder gives up before the unit runs: the member never ran, the unit has no mark (part ended without its mark, once), exit 1, no receipt, and nothing of the run is left" "$_db6_x" "1 1 [] absent"
_db6_u22 u22-block block
_db6_is "R22: with the holder's ps -o lstart= for the forked unit held and the holder then killed with kill -9, the unit, held back until unit.I is written, finds its holder gone and exits without running the member: it never ran, has no mark (once), exit 1, no receipt, and nothing of the run is left" "$_db6_x" "1 1 [] absent"

# ---- the part leaves the shell as it found it
rm -rf "${DB6:?}"
unset -f $(compgen -A function _db6_) 2>/dev/null
unset $(compgen -A variable _db6_) DB6 2>/dev/null
# <<< gate-friction-d-losses-blind
