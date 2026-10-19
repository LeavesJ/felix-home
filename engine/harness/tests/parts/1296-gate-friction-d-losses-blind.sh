# >>> gate-friction-d-losses-blind
printf '\ngate friction D: the ending under a short read, a lost holder, a parent and a holder killed (blind, author 2; revision 8)\n'
# Blind, written on 2026-10-19 from contract D, revision 8 (D1 to D8, "Amended after review 1" and "Amended after
# review 2"), by an author who read no implementation. tests/run, tests/red and tests/receipt.sh are run, never read,
# in copies of this suite that _suite_copy_tree (part 0003) makes under $TMP with planted parts of this block's own.
# Part 1292 holds the signals, dispositions and holders, part 1294 the slots, the gate and the log; this part holds
# what the revision added about losing something: R13 (the parent never waits in an alarm-timed read, so an ending
# is not cut), R2 (a second TERM while it stops), R4 (the parent's own ending of a lost unit's holder) and R15 (a
# parent killed with -9, a holder killed with -9). Names say the clause.
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
# - "no stderr line printed twice" is: no non-empty line of the parent's stderr occurs twice after a second TERM;
# - "the holder's slot line" is line 2 of a $TMP/pj/slot.I whose first field is the holder's pid (R4). A run's $TMP is
#   made beside this suite's own, whatever TMPDIR the case sets (measured), so it is found by a glob of the directory
#   that holds this suite's $TMP; the cases use the unit's parent as the holder either way, and say in their verdict
#   whether a slot line names it;
# - R4's lost-holder case reads: with W = 2 a STOPped holder (a stopped process cannot check its parent) whose wrapper
#   is then killed is ended by the parent alone, and once the parent has exited neither holder nor unit runs;
# - R15's "within 3 s" is timed inside the perl (djk.pl) that takes the ps listing, from the kill to the start of the
#   first listing that shows what was asked for (the listing's own cost is not charged to the run).
# An assertion whose name ends in (control) passes before D is built on purpose.
DB6="$TMP/db6"; mkdir -p "$DB6/n" "$DB6/pp"
_db6_E=(); _db6_I=DEFAULT; _db6_Q=DEFAULT; _db6_lim=100; _db6_S=8; _db6_td=""; _db6_ctl=0; _db6_bg=0; _db6_rc=0; _db6_lab=""
_db6_leak=""; _db6_ino0=""; _db6_late=""; _db6_x=""; _db6_gn=150; _db6_W=""; _db6_twice=""
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
# LABEL SIGNAL: SIGNAL to the driver (twice, 0.5 s apart, when _db6_twice is set), then at most 45 s for it to end (a run still there is killed by group, and _db6_late says so)
_db6_stop() {
  local p i=0; p="$(_db6_pid "$1")"; _db6_late=""
  [ -z "$p" ] || kill -"$2" "$p" 2>/dev/null
  [ -z "$_db6_twice" ] || { sleep 0.5; [ -z "$p" ] || kill -"$_db6_twice" "$p" 2>/dev/null; }
  while [ "$i" -lt 225 ]; do kill -0 "$p" 2>/dev/null || break; sleep 0.2; i=$((i + 1)); done
  if kill -0 "$p" 2>/dev/null; then _db6_late=" the parent was still running 45 s after the signal;"; kill -KILL -- "-$p" 2>/dev/null; fi
  _db6_wait
}
_db6_rcpt() { if [ -f "$_db6_F/.git/felix-suite-receipt" ]; then echo present; else echo absent; fi; }
_db6_id()   { printf '%s' "${TMP##*/}-${_db6_c##*/}"; }
_db6_key()  { printf '%s' "${DB6#/private}/n/${_db6_c##*/}/"; }
# GROUP: the live pids of the current case's run, for the check: in its group, or with its directory or its id in the command line
_db6_ps() {
  ps -A -ww -o pid= -o pgid= -o stat= -o command= 2>/dev/null | G="${1:-}" K="$(_db6_key)" I="$(_db6_id)" LC_ALL=C awk \
    '$3 !~ /^Z/ && (($2 == ENVIRON["G"] && ENVIRON["G"] != "") || index($0, ENVIRON["K"]) || index($0, ENVIRON["I"])) { printf "%s ", $1 }'
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
_db6_slotline() {   # PID: line 2 of a slot file (pj/slot.I) of a run's $TMP whose first field is PID, or nothing. A run's $TMP is made beside this suite's own, not under the TMPDIR the case sets (measured)
  local f l
  for f in "${TMP%/*}"/*/pj/slot.*; do [ -f "$f" ] || continue; l="$(sed -n 2p "$f" 2>/dev/null)"; case "$l" in "$1 "*) printf '%s' "$l"; return 0 ;; esac; done
  return 1
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
_db6_long() {   # CASE FILE...: parts that write the pids of the unit and of its parent, note they are up, and wait for a release file (at most 90 s) before they pass
  local c="$1" f; shift
  for f in "$@"; do _db6_w "$c" "$f" <<'X'
printf '%s %s\n' "$$" "$(ps -o ppid= -p $$ 2>/dev/null | tr -d ' ')" > "$DJ6D/pids.$DJ6N"
: > "$DJ6D/up.$DJ6N"
_i=0; until [ -e "$DJ6D/release" ] || [ "$_i" -ge 450 ]; do sleep 0.2; _i=$((_i + 1)); done
ok "djy $DJ6N"
X
  done
}
_db6_quick() { _db6_w "$1" "$2" <<'X'
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
_db6_W=""; _db6_twice=TERM; _db6_sig r2-twice TERM 143 ign 1
_db6_is "R2: TERM sent twice, 0.5 s apart, to a parent whose unit ignores TERM: exit 143, nothing of the run left, stopped or running, no slot held, no receipt, and no line of its stderr printed twice" "$_db6_x" ok

# ---- R4: the parent's own ending of a lost unit's holder. A stopped holder cannot check its parent, so with its wrapper killed (W = 2: the parent finds the wrapper gone within a few seconds) only the parent can end it
_db6_long lh 0010-lh.sh; _db6_quick lh 0020-lq.sh
_db6_new lh "$DB6/g-empty.tsv" + "$DB6/pp/lh"/*.sh
_db6_E=(FELIX_TEST_SLOT_NOTE=2); _db6_lim=150; _db6_go l -j 2
_db6_r=""
_db6_until 450 _db6_up 0010-lh.sh || _db6_r=" the unit did not come up;"
read -r _db6_u _db6_h < "$_db6_c/pids.0010-lh.sh" 2>/dev/null
_db6_wr="$(ps -o ppid= -p "${_db6_h:-0}" 2>/dev/null | tr -d ' ')"
_db6_sl="$(_db6_slotline "${_db6_h:-0}" >/dev/null && echo slot-line || echo "no-slot-line[holder ${_db6_h:-none}: $(ls "${TMP%/*}"/*/pj/slot.* 2>/dev/null | wc -l | tr -d ' ') slot files in all]")"
if [ -n "${_db6_u:-}" ] && [ -n "${_db6_h:-}" ] && [ -n "$_db6_wr" ] && [ "$_db6_wr" -gt 1 ]; then
  kill -STOP "$_db6_h" 2>/dev/null; kill -KILL "$_db6_wr" 2>/dev/null
  sleep 0.6
  _db6_st="$(ps -o stat= -p "$_db6_h" 2>/dev/null | tr -d ' ')"
  case "$_db6_st" in *T*) ;; *) _db6_r="$_db6_r the holder was not stopped 0.6 s after the stop (stat [$_db6_st]);" ;; esac
  _db6_wait0
  _db6_alive "$_db6_h" && _db6_r="$_db6_r the stopped holder $_db6_h still ran after the parent had exited;"
  _db6_alive "$_db6_u" && _db6_r="$_db6_r its unit $_db6_u still ran after the parent had exited;"
else _db6_r="$_db6_r no unit, holder and wrapper pids were found [$_db6_u $_db6_h $_db6_wr];"; _db6_wait0
fi
_db6_x="$_db6_rc $(_db6_cnt "$_db6_c/l.out" '  FAIL  part ended without its mark: 0010-lh.sh') $(_db6_pfx "$_db6_c/l.out" '  FAIL  part ended without its mark: 0020-lq.sh') $(_db6_rcpt) $_db6_sl${_db6_r}"
_db6_kf "$_db6_c/pids.0010-lh.sh"; _db6_fin
_db6_is "R4: a holder STOPped and its wrapper then killed with kill -9, W = 2: the parent ends the lost unit's holder (its pid and start time are line 2 of the slot file): once the parent has exited the holder and its unit are gone, the unit failed without its mark, the other unit passed, exit 1, no receipt" "$_db6_x" "1 1 0 absent slot-line"
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
_db6_sl="$(_db6_slotline "${_db6_h:-0}" >/dev/null && echo slot-line || echo "no-slot-line[holder ${_db6_h:-none}: $(ls "${TMP%/*}"/*/pj/slot.* 2>/dev/null | wc -l | tr -d ' ') slot files in all]")"
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

# ---- the part leaves the shell as it found it
rm -rf "${DB6:?}"
unset -f $(compgen -A function _db6_) 2>/dev/null
unset $(compgen -A variable _db6_) DB6 2>/dev/null
# <<< gate-friction-d-losses-blind
