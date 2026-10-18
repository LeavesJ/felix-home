# >>> gate-friction-d-signals-blind
printf '\ngate friction D: signals, slots, the gate and what the first blind part left (blind, author 2)\n'
# Blind, written on 2026-10-18 from contract D alone (docs/2026-10-18-gate-
# friction-contract-d.md, D1 to D6 and D8), by a second author who had not read
# any implementation. tests/run, tests/red and tests/receipt.sh are run, never
# read, in copies of this suite that _suite_copy_tree (part 0003) makes under
# $TMP with planted parts of this block's own; every case points TMPDIR at a
# fixture directory, so none touches the machine's slots. Where part 1291 (the
# first author's) asks the same thing, this block asks it a second way: a
# process that is still there is found by its process group, its command line
# or the id its planted children carry, never by one of the three alone; units
# are counted by sampling ps, not by what they write; and the dispositions a
# unit sees are those perl reads. Names say the clause: D1 the interface and
# the gate, D2 a unit, D3 the log and the verdict, D4 the record and the
# durations, D6 the runner (signals, slots, holders), D8 the fixtures.
#
# Readings taken where the contract leaves room, for the reviewers to confirm:
# - "no unit, holder or wrapper left" is read from ps after the parent has
#   ended: nothing in the run's process group, with the copy's directory or the
#   case's id in its command line, that is not a zombie, within 5 s of the exit;
# - "a slot is free at once" is read as the unit's run --part process in ps
#   within 2 s of the kill -9; "no slot held" as a LOCK_EX|LOCK_NB that every
#   slot file grants;
# - "A -j 1 run takes none" is read as: it is not held up by a slot another
#   process holds. Whether it also leaves the slot directory unmade is not asked;
# - the holder's own failure (the parent's lock passed, the holder's did not)
#   is read as a unit with no mark, so "part ended without its mark: UNIT";
# - "a wrapper that is gone without a line ends its unit as having no mark" is
#   read the same way, whatever the unit's own file holds;
# - a name under the slots directory beyond slot K-1 is not asked.
# An assertion whose name ends in (control) passes before D is built on
# purpose: it pins what makes the others mean something. Against a tree where
# -j and --part are not understood every run below is a serial one, so each
# case that would pass serially also asks for something only -j gives (the
# summary suffix, a part that reports it ran as a unit).
DB2="$TMP/db2"; mkdir -p "$DB2/n" "$DB2/pp"
_db2_E=(); _db2_I=DEFAULT; _db2_Q=DEFAULT; _db2_lim=100; _db2_S=8; _db2_td=""; _db2_hp=0; _db2_ctl=0; _db2_bg=0; _db2_rc=0; _db2_pk=0; _db2_late=""
: > "$DB2/g-empty.tsv"; printf '1\tdjy seed\n' > "$DB2/man.tsv"
cat > "$DB2/run.pl" <<'DB2PL'
# run.pl LIMIT INT QUIT PIDFILE CMD...: CMD leads a process group of its own, started with INT and QUIT as given and no descriptor above 2;
# at LIMIT seconds the group is killed (exit 124). Exits as bash reports CMD's status.
use POSIX ();
my ($t, $i, $q, $f) = splice(@ARGV, 0, 4);
my $p = fork;
defined $p or exit 125;
if (!$p) { setpgrp(0, 0); $SIG{INT} = $i; $SIG{QUIT} = $q; POSIX::close($_) for 3 .. 255; exec @ARGV; exit 127 }
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
_db2_until() { local n="$1" i=0; shift; while [ "$i" -lt "$n" ]; do "$@" && return 0; sleep 0.2; i=$((i + 1)); done; "$@"; }
_db2_cnt() { LC_ALL=C awk -v l="$2" '$0 == l { n++ } END { print n + 0 }' "$1" 2>/dev/null || echo 0; }   # FILE LINE: lines that are exactly LINE
_db2_pfx() { LC_ALL=C awk -v p="$2" 'index($0, p) == 1 { n++ } END { print n + 0 }' "$1" 2>/dev/null || echo 0; }   # FILE PREFIX: lines that start with it
_db2_ms()  { perl -MTime::HiRes=time -e 'printf "%d", time * 1000'; }
_db2_cores() { local n; n="$(sysctl -n hw.ncpu 2>/dev/null)"; case "$n" in ''|*[!0-9]*) n="$(getconf _NPROCESSORS_ONLN 2>/dev/null)" ;; esac
  case "$n" in ''|*[!0-9]*) n=1 ;; esac; [ "$n" -ge 1 ] || n=1; [ "$n" -le 64 ] || n=64; printf '%s' "$n"; }
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
# LABEL ARG...: the copy's driver in the background, TMPDIR $_db2_tmp, INT and QUIT as _db2_I and _db2_Q, FELIX_TEST_SLOTS=$_db2_S (none when
# empty), _db2_E added to its environment, the group killed at _db2_lim s; its pid is $_db2_c/LABEL.pid, its output LABEL.out and LABEL.err
_db2_go() {
  local l="$1"; shift
  ( cd "$_db2_F" && exec env -u FELIX_TEST_NO_MANIFEST -u FELIX_TEST_JOBS -u FELIX_TEST_SLOTS -u FELIX_TEST_PART_LOG -u FELIX_TEST_PART_RAN \
      -u FELIX_TEST_PART_END -u FELIX_TEST_PART_RECORD -u FELIX_TEST_RED_JOBS -u PERL5OPT TMPDIR="$_db2_tmp" ${_db2_S:+FELIX_TEST_SLOTS=$_db2_S} \
      ${_db2_E[@]+"${_db2_E[@]}"} perl "$DB2/run.pl" "$_db2_lim" "$_db2_I" "$_db2_Q" "$_db2_c/$l.pid" "$BASH" "$_db2_T/run" "$@" \
  ) > "$_db2_c/$l.out" 2> "$_db2_c/$l.err" &
  _db2_bg=$!
}
_db2_wait() { { wait "$_db2_bg"; } 2>/dev/null; _db2_rc=$?; _db2_E=(); _db2_I=DEFAULT; _db2_Q=DEFAULT; _db2_lim=100; _db2_S=8; }
_db2_pid()  { cat "$_db2_c/$1.pid" 2>/dev/null; }
# LABEL SIGNAL: SIGNAL to the driver, then at most 45 s for it to end (a run still there is killed by group, and _db2_late says so)
_db2_stop() {
  local p i=0; p="$(_db2_pid "$1")"; _db2_late=""
  [ -z "$p" ] || kill -"$2" "$p" 2>/dev/null
  while [ "$i" -lt 225 ]; do kill -0 "$p" 2>/dev/null || break; sleep 0.2; i=$((i + 1)); done
  if kill -0 "$p" 2>/dev/null; then _db2_late=" the parent was still running 45 s after the signal;"; kill -KILL -- "-$p" 2>/dev/null; fi
  _db2_wait
}
_db2_rcpt() { if [ -f "$_db2_F/.git/felix-suite-receipt" ]; then echo present; else echo absent; fi; }
_db2_last() { tail -n 1 "$_db2_c/$1.out" 2>/dev/null; }
_db2_id()   { printf '%s' "${TMP##*/}-${_db2_c##*/}"; }
_db2_key()  { printf '%s' "${DB2#/private}/n/${_db2_c##*/}/"; }
# PGID: the live pids of the current case's run: in its process group, or with its directory or its id in the command line (not mine at _db2_hp)
_db2_ps() {
  ps -A -ww -o pid= -o pgid= -o stat= -o command= 2>/dev/null | G="${1:-}" K="$(_db2_key)" I="$(_db2_id)" H="$_db2_hp" LC_ALL=C awk \
    '$3 !~ /^Z/ && $1 != ENVIRON["H"] && (($2 == ENVIRON["G"] && ENVIRON["G"] != "") || index($0, ENVIRON["K"]) || index($0, ENVIRON["I"])) { printf "%s ", $1 }'
}
_db2_clear() { [ -z "$(_db2_ps "$1")" ]; }
_db2_reap()  { local p; for p in $(_db2_ps "$(_db2_pid "$1")"); do kill -KILL "$p" 2>/dev/null; done; }
# the unit processes of the current case: bash run --part, not perl (the holder may carry the same words)
_db2_units() { ps -A -ww -o pid= -o stat= -o command= 2>/dev/null | K="$(_db2_key)" LC_ALL=C awk '$2 !~ /^Z/ && index($0, ENVIRON["K"]) && index($0, " --part ") && $3 !~ /perl/ { printf "%s ", $1 }'; }
# KEY: how many unit processes (a --part process not below another) of the copies with KEY in their path run now
_db2_snap() {
  ps -A -ww -o pid= -o ppid= -o stat= -o command= 2>/dev/null | K="$1" LC_ALL=C awk '
    { u[$1] = (index($0, " --part ") && index($0, ENVIRON["K"]) && $3 !~ /^Z/); pp[$1] = $2 }
    END { n = 0; for (p in u) if (u[p] && !((pp[p] in u) && u[pp[p]])) n++; print n }'
}
_db2_peak() {   # KEY BGPID...: samples until those jobs have ended; _db2_pk is the most units seen at once
  local k="$1" m=0 n b alive; shift
  while :; do
    alive=0; for b in "$@"; do ! kill -0 "$b" 2>/dev/null || alive=1; done
    [ "$alive" = 1 ] || break
    n="$(_db2_snap "$k")"; [ "${n:-0}" -le "$m" ] || m="$n"
    sleep 0.15
  done
  _db2_pk="$m"
}
_db2_held() {   # TMPDIR: the slot files under it that some process holds
  perl -e 'use Fcntl ":flock"; for my $f (sort glob("$ARGV[0]/felix-suite-slots/*")) { next unless -f $f; open(my $h, "<", $f) or next; flock($h, LOCK_EX | LOCK_NB) or print "$f "; close $h }' "$1"
}
_db2_hold() {   # SLOTFILE: a perl of mine holds its lock until _db2_unhold; _db2_hp is its pid
  mkdir -p "${1%/*}"
  perl -e 'use Fcntl ":flock"; open(my $h, ">>", $ARGV[0]) or exit 4; flock($h, LOCK_EX | LOCK_NB) or exit 3; $| = 1; print "held\n"; sleep 300' "$1" > "$_db2_c/hold.out" 2>&1 &
  _db2_hp=$!
  _db2_until 100 test -s "$_db2_c/hold.out"
}
_db2_unhold() { [ "$_db2_hp" = 0 ] || { kill -KILL "$_db2_hp" 2>/dev/null; { wait "$_db2_hp"; } 2>/dev/null; }; _db2_hp=0; return 0; }
_db2_started() { local f r=""; for f in "$_db2_c"/started.*; do [ -e "$f" ] && r="$r${f##*/} "; done; printf '%s' "$r"; }
_db2_pre()   { local f; for f in "$_db2_T"/parts/0006-*.sh; do printf '\n: > "%s/pre.done.$$"\n' "$_db2_c" >> "$f"; done; }   # the parent's prelude is done
_db2_pre_up() { ls "$_db2_c"/pre.done.* >/dev/null 2>&1; }
_db2_up()    { test -e "$_db2_c/up.$1"; }
# "ok", or what an interrupted run left behind: LABEL STATUS
_db2_gone() {
  local l="$1" r="" g; g="$(_db2_pid "$l")"
  [ "$_db2_rc" = "$2" ] || r="$r exit $_db2_rc, not $2;"
  [ "$(_db2_cnt "$_db2_c/$l.out" reached)" = 0 ] || r="$r reached was printed;"
  _db2_until 25 _db2_clear "$g" || r="$r still running: $(_db2_ps "$g");"
  _db2_reap "$l"
  [ -z "$(_db2_held "$_db2_tmp")" ] || r="$r a slot is still held;"
  [ "$(_db2_rcpt)" = absent ] || r="$r a receipt was left;"
  [ "$_db2_ctl" = 1 ] || r="$r no positive control, so these absences say nothing;"
  printf '%s' "${r:-ok}"
}
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
_db2_sl() {   # CASE: two parts that start a sleeping child and wait for a release file, and a third that only notes it started
  local f
  for f in 0010-sa.sh 0020-sb.sh; do _db2_w "$1" "$f" <<'X'
: > "$DJ2D/started.$DJ2N"
perl -e 'open(my $h, ">", $ARGV[0]); close $h; sleep 300' "$DJ2D/ch.$DJ2N" "$DJ2I" sl &
_k=$!
until [ -e "$DJ2D/ch.$DJ2N" ]; do sleep 0.1; done
: > "$DJ2D/up.$DJ2N"
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

# ---- the control: released at once, the sleeper parts pass under -j 2 and leave a receipt
_db2_sl ctl; _db2_new ctl "$DB2/g-empty.tsv" + "$DB2/pp/ctl"/*.sh
: > "$_db2_c/release"; _db2_go c -j 2; _db2_wait
[ "$_db2_rc" = 0 ] && [ "$(_db2_rcpt)" = present ] && [ -e "$_db2_c/started.0030-sc.sh" ] && _db2_ctl=1
is "D6: the sleeper parts, released at once, pass under -j 2: exit 0, a receipt, and the third part ran (positive control)" "$_db2_rc $_db2_ctl" "0 1"
rm -rf "$DB2/n/ctl"

# ---- dispositions (D6): a unit starts with INT and QUIT as the parent had them, in each of the four ways
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
for _db2_m in "DEFAULT DEFAULT" "IGNORE IGNORE" "IGNORE DEFAULT" "DEFAULT IGNORE"; do
  _db2_i="${_db2_m% *}"; _db2_q="${_db2_m#* }"
  _db2_I="$_db2_i"; _db2_Q="$_db2_q"; _db2_go d3 -j 3; _db2_wait
  _db2_I="$_db2_i"; _db2_Q="$_db2_q"; _db2_go d1 -j 1; _db2_wait
  _db2_x3="$(grep '^djy-sig:' "$_db2_c/d3.out" | LC_ALL=C sort | tr '\n' ' ')"; _db2_x1="$(grep '^djy-sig:' "$_db2_c/d1.out" | LC_ALL=C sort | tr '\n' ' ')"
  _db2_k="$(grep -c "^djy-sig:INT=$_db2_i,QUIT=$_db2_q," "$_db2_c/d1.out")"
  is "D6: -j 1 parts read INT $_db2_i and QUIT $_db2_q from a parent started that way, on all three parts (control)" "$_db2_k $(_db2_cnt "$_db2_c/d1.out" djy-mode:serial)" "3 3"
  is "D6: from a parent with INT $_db2_i and QUIT $_db2_q the three parts, two of them a group, ran as units under -j 3 and read the dispositions a -j 1 run reads" \
     "$(_db2_cnt "$_db2_c/d3.out" djy-mode:unit) $([ "$_db2_x3" = "$_db2_x1" ] && echo same || echo "differ [$_db2_x3] [$_db2_x1]")" "3 same"
done
rm -rf "$DB2/n/dis"

# ---- an interrupt (D6): units are up, the signal goes to the parent, and the run ends as D6 says
# CASE SIGNAL STATUS [INT QUIT]: a -j 2 run of three parts, SIGNAL once the first two are up: "ok", or what was wrong
_db2_intr() {
  local c="$1" s="$2" w="$3" r="" g
  _db2_sl "$c"
  _db2_new "$c" "$DB2/g-empty.tsv" + "$DB2/pp/$c"/*.sh || { printf 'the copy could not be made'; return 0; }
  _db2_I="${4:-DEFAULT}"; _db2_Q="${5:-DEFAULT}"; _db2_lim=150
  _db2_go i -j 2
  _db2_until 450 _db2_up 0010-sa.sh || r=" no unit came up;"
  _db2_until 75 _db2_up 0020-sb.sh || r="$r the second unit did not come up;"
  sleep 0.5
  _db2_stop i "$s"; r="$r$_db2_late"
  g="$(_db2_gone i "$w")"; [ "$g" = ok ] || r="$r$g"
  [ ! -e "$_db2_c/started.0030-sc.sh" ] || r="$r the part that was queued started;"
  rm -rf "$_db2_c"; printf '%s' "${r:-ok}"
}
is "D6: TERM to the parent while two units run and a third waits: exit 143, no reached, nothing of the run left, no slot held, no receipt, the queued unit never started" "$(_db2_intr i-term TERM 143)" ok
is "D6: INT to a parent started with INT at its default: exit 130, with the same afterwards" "$(_db2_intr i-int INT 130)" ok
is "D6: HUP to the parent: exit 129, with the same afterwards" "$(_db2_intr i-hup HUP 129)" ok
is "D6: TERM to a parent started with INT and QUIT both ignored: exit 143, with the same afterwards" "$(_db2_intr i-ign TERM 143 IGNORE IGNORE)" ok

# ---- a child that ignores TERM and is moved to pid 1 when its unit dies, and what it forks (D6, the ending)
_db2_igr() {   # CASE MODE: a unit starts that child with & and waits; TERM to the parent; afterwards nothing of the run runs
  local c="$1" m="$2" r="" g
  _db2_w "$c" 0010-ka.sh <<'X'
perl "$DJ2L/ign.pl" "$DJ2D" "$DJ2I" "$(cat "$DJ2D/mode")" &
until [ -s "$DJ2D/ign.pid" ]; do sleep 0.1; done
: > "$DJ2D/up.$DJ2N"
wait
X
  _db2_new "$c" "$DB2/g-empty.tsv" + "$DB2/pp/$c"/0010-ka.sh || { printf 'the copy could not be made'; return 0; }
  printf '%s' "$m" > "$_db2_c/mode"
  _db2_lim=150; _db2_go i -j 2
  _db2_until 450 _db2_up 0010-ka.sh || r=" no unit came up;"
  sleep 0.5
  _db2_stop i TERM; r="$r$_db2_late"
  g="$(_db2_gone i 143)"; [ "$g" = ok ] || r="$r$g"
  case "$m" in h) [ -s "$_db2_c/gc.pids" ] || r="$r the TERM never reached the child, which forked nothing;" ;; esac
  rm -rf "$_db2_c"; printf '%s' "${r:-ok}"
}
is "D6: a child a unit started with & that ignores TERM, once the unit dies on TERM and the child is at pid 1, is gone when the parent has ended" "$(_db2_igr g-ign n)" ok
is "D6: and so is the sleeper that child forked in its TERM handler, which is a descendant of a pid the parent had listed" "$(_db2_igr g-h h)" ok
is "D6: and so are the sleepers a child forks every 20 ms from its first TERM on, which only STOP can hold still" "$(_db2_igr g-s s)" ok

# ---- an interrupt while a holder waits, and a slot freed by kill -9 (D6): one slot, held by a process of mine, two parts waiting for it
_db2_hw() {   # CASE MODE: MODE term sends TERM to the parent, MODE free kills my holder with kill -9; _db2_x is the verdict
  local c="$1" m="$2" r="" t0 t1 i g
  _db2_q "$c"; _db2_td="$DB2/td-$c"; rm -rf "$_db2_td"; mkdir -p "$_db2_td"
  if ! _db2_new "$c" "$DB2/g-empty.tsv" + "$DB2/pp/$c"/0010-qa.sh "$DB2/pp/$c"/0020-qb.sh; then _db2_x="the copy could not be made"; _db2_td=""; return 0; fi
  _db2_pre; _db2_hold "$_db2_tmp/felix-suite-slots/0"
  _db2_S=1; _db2_go h -j 2
  _db2_until 450 _db2_pre_up || r=" the parent's prelude never ended;"
  sleep 2.5
  [ -z "$(_db2_started)$(_db2_units)" ] || r="$r a unit ran while the slot was held elsewhere ($(_db2_started)$(_db2_units));"
  if [ "$m" = term ]; then
    _db2_stop h TERM; r="$r$_db2_late"; _db2_unhold; sleep 3
    g="$(_db2_gone h 143)"; [ "$g" = ok ] || r="$r$g"
    [ -z "$(_db2_started)" ] || r="$r a unit started after the parent had exited ($(_db2_started));"
    [ -z "$(_db2_units)" ] || r="$r a unit process ran after the parent had exited;"
  else
    t0="$(_db2_ms)"; kill -KILL "$_db2_hp" 2>/dev/null; { wait "$_db2_hp"; } 2>/dev/null; _db2_hp=0
    t1=""; i=0; while [ "$i" -lt 60 ]; do [ -z "$(_db2_units)" ] || { t1="$(_db2_ms)"; break; }; sleep 0.05; i=$((i + 1)); done
    if [ -z "$t1" ]; then r="$r no unit process within 3 s of the kill -9;"; elif [ $((t1 - t0)) -gt 2000 ]; then r="$r the unit appeared $((t1 - t0)) ms after the kill -9;"; fi
    _db2_wait
    [ "$_db2_rc" = 0 ] || r="$r exit $_db2_rc, not 0;"
    [ "$(_db2_rcpt)" = present ] || r="$r no receipt;"
    _db2_reap h
  fi
  _db2_unhold; _db2_td=""; rm -rf "$DB2/n/$c" "$DB2/td-$c"; _db2_x="${r:-ok}"
}
_db2_hw hw-term term
is "D6: with one slot, its lock held elsewhere and two parts waiting, TERM to the parent starts no unit, before the exit or after it, and the exit is 143" "$_db2_x" ok
_db2_hw hw-free free
is "D6: a slot whose holder was killed with kill -9 is free at once: no unit while it was held, one within 2 s of the kill, and the run then passes" "$_db2_x" ok

# ---- a record run that is interrupted writes no manifest (D6, what it leaves)
_db2_sl rrt; _db2_new rrt --red "$DB2/g-empty.tsv" "$DB2/man.tsv" "$DB2/pp/rrt"/*.sh
_db2_lim=150; _db2_go r -j 2 --record-assertions
_db2_until 450 _db2_up 0010-sa.sh; _db2_until 75 _db2_up 0020-sb.sh; sleep 0.5
_db2_stop r TERM; _db2_x="$([ -e "$_db2_c/up.0020-sb.sh" ] && echo both-up || echo one-up) $(cmp -s "$DB2/man.tsv" "$_db2_T/assertions.tsv" && echo same || echo changed) $(_db2_cnt "$_db2_c/r.out" reached) $(_db2_pfx "$_db2_c/r.out" '  recorded ') $(_db2_rcpt)"
_db2_reap r
for _db2_p in $(ps -A -ww -o pid= -o command= 2>/dev/null | K="$(_db2_key)" LC_ALL=C awk 'index($0, ENVIRON["K"]) && index($0, "/tests/red") { printf "%s ", $1 }'); do kill -KILL "$_db2_p" 2>/dev/null; done
is "D6: TERM to a record run under -j 2, both units up: exit 143, the manifest as it was, no reached, no recorded line and no receipt" "$_db2_rc $_db2_x" "143 both-up same 0 0 absent"
rm -rf "$DB2/n/rrt"

# ---- the slots (D6): two -j 4 runs share FELIX_TEST_SLOTS slots, and a run is held to its -j
_db2_two() {   # TMPDIR SLOTS JOBS: two runs of four quick parts at once, the same TMPDIR; _db2_pk is the most units seen at once, _db2_rc2 the two exit statuses
  local td="$1" k="$2" j="$3" ba bb r1
  rm -rf "$td"; mkdir -p "$td"; _db2_td="$td"
  _db2_q capa; _db2_q capb
  _db2_new capa "$DB2/g-empty.tsv" + "$DB2/pp/capa"/*.sh; _db2_new capb "$DB2/g-empty.tsv" + "$DB2/pp/capb"/*.sh
  _db2_sel capa; _db2_S="$k"; _db2_go a -j "$j"; ba="$_db2_bg"
  _db2_sel capb; _db2_S="$k"; _db2_go b -j "$j"; bb="$_db2_bg"
  _db2_peak "${DB2#/private}/n/cap" "$ba" "$bb"
  _db2_bg="$ba"; _db2_wait; r1="$_db2_rc"; _db2_bg="$bb"; _db2_wait
  _db2_rc2="$r1 $_db2_rc"; _db2_td=""; rm -rf "$DB2/n/capa" "$DB2/n/capb" "$td"
}
_db2_two "$DB2/td-c3" 3 4
is "D6: with FELIX_TEST_SLOTS=3, two -j 4 runs of four parts never have more than three units running at once, and both pass" "$([ "$_db2_pk" -le 3 ] && echo "at most 3" || echo "$_db2_pk") $_db2_rc2" "at most 3 0 0"
is "D6: and they do get to three at once, which is the slots and not the parts' own order holding them there" "$_db2_pk" 3
_db2_two "$DB2/td-c8" 8 4
is "D6: and with FELIX_TEST_SLOTS=8 the same two runs do have more than three at once, so the count above can fail" "$([ "$_db2_pk" -gt 3 ] && echo more || echo "$_db2_pk") $_db2_rc2" "more 0 0"
_db2_one() {   # CASE JOBS: one run of four quick parts with eight slots; _db2_pk is the most units seen at once
  _db2_q "$1"; _db2_td=""; _db2_new "$1" "$DB2/g-empty.tsv" + "$DB2/pp/$1"/*.sh
  _db2_S=8; _db2_go a -j "$2"; _db2_peak "${DB2#/private}/n/$1/" "$_db2_bg"; _db2_wait; rm -rf "$DB2/n/$1"
}
_db2_one nj2 2
is "D6: a run is held to its own N: -j 2 over four parts and plenty of slots has two units at once and never more, and passes" "$_db2_pk $_db2_rc" "2 0"
_db2_one nj4 4
is "D6: and -j 4 over the same parts has more than two at once, so the count above can fail" "$([ "$_db2_pk" -gt 2 ] && echo more || echo "$_db2_pk") $_db2_rc" "more 0"

# one slot free of two: the parts still run, one at a time; a -j 1 run is not held up by a slot held elsewhere
_db2_q fo; _db2_td="$DB2/td-fo"; rm -rf "$_db2_td"; mkdir -p "$_db2_td"; _db2_new fo "$DB2/g-empty.tsv" + "$DB2/pp/fo"/*.sh
_db2_hold "$_db2_tmp/felix-suite-slots/0"
_db2_S=2; _db2_lim=120; _db2_go a -j 2; _db2_peak "${DB2#/private}/n/fo/" "$_db2_bg"; _db2_wait
is "D6: with slot 0 of 2 held elsewhere the four parts still run, through slot 1, one unit at a time (never none, never two), and pass" "$_db2_pk $_db2_rc $(_db2_started | wc -w | tr -d ' ')" "1 0 4"
rm -rf "$DB2/pp/fo"; _db2_q fo; rm -rf "$DB2/n/fo"; _db2_new fo "$DB2/g-empty.tsv" + "$DB2/pp/fo"/*.sh
_db2_S=1; _db2_lim=60; _db2_go a -j 1; _db2_wait
is "D6: and a -j 1 run is not held up by the only slot being held elsewhere: it passes and runs all four parts (control)" "$_db2_rc $(_db2_started | wc -w | tr -d ' ')" "0 4"
_db2_unhold; _db2_td=""; rm -rf "$DB2/n/fo" "$DB2/td-fo"

# the slot files a run makes: K regular files, 0 to K-1 (K is FELIX_TEST_SLOTS, or the core count)
_db2_slotnames() { local f r=""; for f in "$1"/felix-suite-slots/*; do [ -e "$f" ] || continue; if [ -f "$f" ] && [ ! -L "$f" ]; then r="$r${f##*/} "; else r="$r(${f##*/}:not a file) "; fi; done; printf '%s' "$r"; }
_db2_q sf; _db2_td="$DB2/td-sf"; rm -rf "$_db2_td"; mkdir -p "$_db2_td"; _db2_new sf "$DB2/g-empty.tsv" + "$DB2/pp/sf"/*.sh
_db2_S=3; _db2_go a -j 2; _db2_wait; _db2_x="$(_db2_slotnames "$_db2_td")|$(_db2_held "$_db2_td")"
is "D6: a -j 2 run with FELIX_TEST_SLOTS=3 in a fresh TMPDIR leaves exactly the regular files 0, 1 and 2 in felix-suite-slots, none of them held" "$_db2_rc $_db2_x" "0 0 1 2 |"
rm -rf "$_db2_td"; mkdir -p "$_db2_td"; _db2_S=""; _db2_go a -j 2; _db2_wait
_db2_x="$(_db2_slotnames "$_db2_td")"; _db2_y="$(set -- $_db2_x; echo $#)"
is "D6: with FELIX_TEST_SLOTS unset the slots are as many as the cores (sysctl, then getconf, then 1, held to 1 to 64), all regular files" "$_db2_rc $_db2_y $(printf '%s' "$_db2_x" | grep -c 'not a file')" "0 $(_db2_cores) 0"
_db2_td=""; rm -rf "$DB2/n/sf" "$DB2/td-sf"

# slots that cannot be taken: the parent refuses, exit 2 and one line, before it starts a unit
_db2_srv() {   # the -j 2 run in the current copy is refused; _db2_v is "ok" or what differed
  local r="" n
  _db2_lim=60; _db2_go sr -j 2; _db2_wait
  n="$(awk 'END { print NR }' "$_db2_c/sr.err")"
  [ "$_db2_rc" = 2 ] || r="$r exit $_db2_rc, not 2;"
  [ "$n" = 1 ] || r="$r $n stderr lines, not 1;"
  [ -z "$(_db2_started)" ] || r="$r a unit started ($(_db2_started));"
  _db2_v="${r:-ok}"
}
cat > "$DB2/Djflock2.pm" <<'DB2PM'
package Djflock2;
use Errno qw(ENOLCK);
use Fcntl qw(O_CREAT O_EXCL O_WRONLY);
# DJ2_FLOCK=all: every flock but LOCK_UN fails with ENOLCK. DJ2_FLOCK=later: the first one, in whatever process asks first, succeeds
# (the parent's one lock), and every later one fails with ENOLCK (a holder's).
BEGIN {
  *CORE::GLOBAL::flock = sub {
    my ($fh, $op) = @_;
    return CORE::flock($fh, $op) if $op & 8;
    if (($ENV{DJ2_FLOCK} || "") eq "later" && sysopen(my $x, $ENV{DJ2_MARK}, O_CREAT | O_EXCL | O_WRONLY)) { close $x; return CORE::flock($fh, $op) }
    $! = ENOLCK; return 0;
  };
}
1;
DB2PM
_db2_fk() { perl -I"$DB2" -MDjflock2 -e 'use Fcntl ":flock"; open(my $h, "<", $ARGV[0]) or exit 3; for (1, 2) { print flock($h, LOCK_EX | LOCK_NB) ? "granted " : ($!{EWOULDBLOCK} ? "wouldblock " : "other ") }' "$DB2/man.tsv"; }
is "D6: the flock stand-in used below fails with an errno that is not EWOULDBLOCK in mode all, and only after the first call in mode later (control)" \
   "$(DJ2_FLOCK=all _db2_fk)| $(DJ2_FLOCK=later DJ2_MARK="$DB2/fk.mark" _db2_fk)" "other other | granted other "
_db2_q fl; _db2_td="$DB2/td-fl"; rm -rf "$_db2_td"; mkdir -p "$_db2_td"; _db2_new fl "$DB2/g-empty.tsv" + "$DB2/pp/fl"/*.sh
_db2_S=2; _db2_E=(PERL5OPT="-I$DB2 -MDjflock2" DJ2_FLOCK=all); _db2_srv
is "D6: where flock fails with ENOLCK, and not EWOULDBLOCK, the parent's one lock fails and the run is refused: exit 2, one stderr line, no unit" "$_db2_v" ok
rm -rf "$DB2/td-fl/felix-suite-slots" "$_db2_c/started".*; _db2_S=2; _db2_E=(PERL5OPT="-I$DB2 -MDjflock2" DJ2_FLOCK=later DJ2_MARK="$_db2_c/flock.mark"); _db2_lim=90; _db2_go hf -j 2; _db2_wait
_db2_x=""
[ "$_db2_rc" = 1 ] || _db2_x="$_db2_x exit $_db2_rc, not 1;"
for _db2_p in 0010-qa.sh 0020-qb.sh; do [ "$(_db2_cnt "$_db2_c/hf.out" "  FAIL  part ended without its mark: $_db2_p")" = 1 ] || _db2_x="$_db2_x no runner failure for $_db2_p;"; done
[ -z "$(_db2_started)" ] || _db2_x="$_db2_x a unit started;"
[ "$(_db2_rcpt)" = absent ] || _db2_x="$_db2_x a receipt was left;"
_db2_reap hf
is "D6: where the parent's lock is granted and a holder's flock fails with ENOLCK, the holder exits 2 before its unit starts: each unit has no mark, exit 1, no receipt" "${_db2_x:-ok}" ok
rm -rf "$DB2/n/fl" "$DB2/td-fl"
_db2_nd() {   # CASE KIND: the slots directory holds a KIND at name 0 (and for dirs at 1) of two; _db2_v as _db2_srv's
  _db2_q "$1"; _db2_td="$DB2/td-$1"; rm -rf "$_db2_td"; mkdir -p "$_db2_td/felix-suite-slots"
  case "$2" in
    dir0)  mkdir "$_db2_td/felix-suite-slots/0" ;;
    dir1)  : > "$_db2_td/felix-suite-slots/0"; mkdir "$_db2_td/felix-suite-slots/1" ;;
    fifo0) mkfifo "$_db2_td/felix-suite-slots/0" 2>/dev/null || _db2_v=skip ;;
    mode0) : > "$_db2_td/felix-suite-slots/0"; chmod 000 "$_db2_td/felix-suite-slots/0" ;;
  esac
  if [ "$2" = fifo0 ] && [ ! -p "$_db2_td/felix-suite-slots/0" ]; then _db2_v=skip
  elif [ "$2" = mode0 ] && [ -r "$_db2_td/felix-suite-slots/0" ]; then _db2_v=skip
  elif ! _db2_new "$1" "$DB2/g-empty.tsv" + "$DB2/pp/$1"/*.sh; then _db2_v="the copy could not be made"
  else _db2_S=2; _db2_srv; fi
  _db2_reap sr; chmod 644 "$_db2_td/felix-suite-slots/0" 2>/dev/null; rm -rf "$DB2/n/$1" "$_db2_td"; _db2_td=""
}
_db2_nd nd0 dir0
is "D6: a directory at slot 0 makes a -j run refuse: exit 2, one stderr line, no unit" "$_db2_v" ok
_db2_nd nd1 dir1
is "D6: a directory at slot 1 of 2, beside a regular file at 0, refuses the same way" "$_db2_v" ok
_db2_nd nf0 fifo0
if [ "$_db2_v" = skip ]; then skip "D6: a FIFO at slot 0 refuses the same way and does not block the parent on opening it" "mkfifo made no FIFO here"
else is "D6: a FIFO at slot 0 refuses the same way and does not block the parent on opening it" "$_db2_v" ok; fi
_db2_nd nm0 mode0
if [ "$_db2_v" = skip ]; then skip "D6: a slot file the parent cannot open makes a -j run refuse: exit 2, one stderr line, no unit" "a mode 000 file is still readable by this user"
else is "D6: a slot file the parent cannot open makes a -j run refuse: exit 2, one stderr line, no unit" "$_db2_v" ok; fi

# ---- the gate (D1): projects/felix/gate.sh run whole in a fixture checkout, beside a stub tests/run that records $#:$* and FELIX_TEST_JOBS
DG="$DB2/gate"; DGC="$DG/c"
mkdir -p "$DGC/engine/harness/bin" "$DGC/engine/harness/lib" "$DGC/engine/harness/tests" "$DGC/projects/felix" "$DG/tmp" "$DG/home" "$DG/shim" "$DG/out"
_db2_gs="$REAL_HARNESS/../../projects/felix/gate.sh"
if [ ! -f "$_db2_gs" ]; then
  for _db2_a in "with GITHUB_ACTIONS unset gate.sh sets FELIX_TEST_JOBS to the core count and its argument list stays --reuse" \
                "with GITHUB_ACTIONS=true it sets nothing, and the argument list is --reuse (control)" \
                "only the value true stops it: GITHUB_ACTIONS=false still sets the core count" \
                "a FELIX_TEST_JOBS the caller already had is replaced by the core count" \
                "the core count is held to 64, falls from sysctl to getconf to 1, and sysctl answers first" \
                "when tests/run exits 2 the log's last line is shown under tests FAIL"; do
    skip "D1: $_db2_a" "no projects/felix/gate.sh beside this engine"
  done
else
  cp "$_db2_gs" "$DGC/projects/felix/gate.sh"
  printf '#!/bin/sh\nexit 0\n' > "$DGC/engine/harness/bin/schema-check"
  printf '#!/bin/sh\n[ "${1:-}" = --paths ] && echo engine/harness/bin\nexit 0\n' > "$DGC/engine/harness/bin/independence-scan"
  printf '_gfg_probe() {\n  _felix_dep_grep "$root" "gfgzzword"\n}\n' > "$DGC/engine/harness/lib/detect.sh"
  printf '# kind\tfile\ttoken\treason\n' > "$DGC/engine/harness/ecosystem.tsv"
  cat > "$DGC/engine/harness/tests/run" <<'DB2ST'
#!/usr/bin/env bash
printf '%s:%s\n' "$#" "$*" >> "$DJ2_OUT/$DJ2_L.args"
printf '%s\n' "${FELIX_TEST_JOBS-unset}" >> "$DJ2_OUT/$DJ2_L.jobs"
if [ -n "${DJ2_EXIT2:-}" ]; then printf 'djy stub: first line of a refusal\n' >&2; printf 'djy stub: the last line of a refusal\n' >&2; exit 2; fi
printf 'reused the suite run that ended 09:00 on this tree (normal), not run again\n\n7 passed, 0 failed (reused)\n'
DB2ST
  chmod +x "$DGC/engine/harness/bin/schema-check" "$DGC/engine/harness/bin/independence-scan" "$DGC/engine/harness/tests/run"
  for _db2_t in sysctl getconf; do
    cat > "$DG/shim/$_db2_t" <<'DB2SH'
#!/bin/sh
# the tool of this name, unless DJ2_<name> is set: then it answers with that (and fails where it is empty)
n="${0##*/}"
eval "v=\${DJ2_$n-djy-unset}"
if [ "$v" != djy-unset ]; then [ -n "$v" ] || exit 1; echo "$v"; exit 0; fi
[ -x "@REAL@" ] || exit 1
exec "@REAL@" "$@"
DB2SH
    sed "s|@REAL@|$(command -v "$_db2_t" 2>/dev/null || echo /nonexistent)|g" "$DG/shim/$_db2_t" > "$DG/shim/$_db2_t.n" && mv "$DG/shim/$_db2_t.n" "$DG/shim/$_db2_t"
    chmod +x "$DG/shim/$_db2_t"
  done
  ( _fx_cd "${DGC:?}" && git init -q -b main && git add -A && git -c user.name=djy -c user.email=djy@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm fixture ) >/dev/null 2>&1
  _db2_gate() {   # LABEL NAME=value...: gate.sh in the fixture; its output is $DG/out/LABEL.out, its status _db2_grc
    local l="$1"; shift
    rm -f "$DG/out/$l.args" "$DG/out/$l.jobs"
    ( cd "${DGC:?}" && exec env -u GITHUB_ACTIONS -u FELIX_TEST_JOBS -u FELIX_TEST_NO_MANIFEST -u DJ2_EXIT2 -u DJ2_sysctl -u DJ2_getconf HOME="$DG/home" \
        FELIX_KERNEL_CACHE="$DG/nocache" TMPDIR="$DG/tmp" PATH="$DG/shim:$PATH" DJ2_OUT="$DG/out" DJ2_L="$l" ${1+"$@"} \
        perl "$DB2/run.pl" 90 DEFAULT DEFAULT "$DG/out/$l.pid" bash projects/felix/gate.sh ) > "$DG/out/$l.out" 2>&1
    _db2_grc=$?
  }
  _db2_gj() { sed -n 1p "$DG/out/$1.jobs" 2>/dev/null; }
  _db2_ga() { sed -n 1p "$DG/out/$1.args" 2>/dev/null; }
  _db2_gc() {   # LABEL WANT NAME=value...: gate.sh with those; "ok" when the stub saw FELIX_TEST_JOBS=WANT and the arguments 1:--reuse
    local l="$1" w="$2"; shift 2
    _db2_gate "$l" ${1+"$@"}
    if [ "$(_db2_gj "$l") $(_db2_ga "$l")" = "$w 1:--reuse" ]; then printf ok; else printf '[%s] [%s]' "$(_db2_gj "$l")" "$(_db2_ga "$l")"; fi
  }
  is "D1: with GITHUB_ACTIONS unset gate.sh sets FELIX_TEST_JOBS to the core count for its call to tests/run, and its argument list stays --reuse" "$(_db2_gc g1 "$(_db2_cores)")" ok
  is "D1: with GITHUB_ACTIONS=true it sets nothing, and the argument list is --reuse (control)" "$(_db2_gc g2 unset GITHUB_ACTIONS=true)" ok
  is "D1: only the value true stops it: GITHUB_ACTIONS=false still sets the core count" "$(_db2_gc g3 "$(_db2_cores)" GITHUB_ACTIONS=false)" ok
  is "D1: a FELIX_TEST_JOBS the caller already had is replaced by the core count" "$(_db2_gc g4 "$(_db2_cores)" FELIX_TEST_JOBS=7)" ok
  _db2_x="$(_db2_gc g5 64 DJ2_sysctl=200)"; _db2_x="$_db2_x $(_db2_gc g6 64 DJ2_sysctl= DJ2_getconf=100)"
  _db2_x="$_db2_x $(_db2_gc g7 12 DJ2_sysctl= DJ2_getconf=12)"; _db2_x="$_db2_x $(_db2_gc g8 1 DJ2_sysctl= DJ2_getconf=)"
  _db2_x="$_db2_x $(_db2_gc g9 3 DJ2_sysctl=3 DJ2_getconf=9)"; _db2_x="$_db2_x $(_db2_gc g10 5 DJ2_sysctl=abc DJ2_getconf=5)"
  is "D1: the core count is held to 64 (sysctl 200, getconf 100), falls from sysctl to getconf to 1, and sysctl answers first and a non-number does not" "$_db2_x" "ok ok ok ok ok ok"
  _db2_gate g11 DJ2_EXIT2=1
  is "D1: when tests/run exits 2 with one line on stderr the gate reports tests FAIL and shows the log's last line under it" \
     "$(LC_ALL=C awk '/^  tests +FAIL$/ { f = 1; s = 1; next } /^  [A-Za-z-]+ +(ok|FAIL|skipped|reused)/ { f = 0 } f && index($0, "djy stub: the last line of a refusal") { h = 1 } END { print s + 0, h + 0 }' "$DG/out/g11.out" 2>/dev/null) $([ "$_db2_grc" != 0 ] && echo failed || echo passed)" "1 1 failed"
fi

# ---- what the first blind part left: the largest N, six names of --part, and part mode keyed on its argument alone (D1)
_db2_q acc; _db2_new acc "$DB2/g-empty.tsv" + "$DB2/pp/acc"/*.sh
_db2_go a -j 64; _db2_wait; _db2_x="$_db2_rc $(_db2_last a | grep -c ' (counted from lines)$')"
_db2_E=(FELIX_TEST_JOBS=64); _db2_go b; _db2_wait; _db2_x="$_db2_x | $_db2_rc $(_db2_last b | grep -c ' (counted from lines)$')"
is "D1: the largest N, 64, is accepted both as -j 64 and as FELIX_TEST_JOBS=64: exit 0 and a summary counted from lines" "$_db2_x" "0 1 | 0 1"
rm -rf "$DB2/n/acc"
_db2_q accr; _db2_new accr "$DB2/g-empty.tsv" + "$DB2/pp/accr"/*.sh
_db2_go a -j 3 --reuse; _db2_wait
is "D3: -j 3 --reuse with no receipt to reuse runs the suite: exit 0, a summary that ends (counted from lines) and not (reused), and a receipt left" \
   "$_db2_rc $(_db2_last a | grep -c ' (counted from lines)$') $(_db2_last a | grep -c ' (reused)$') $(_db2_rcpt)" "0 1 0 present"
rm -rf "$DB2/n/accr"
for _db2_i in 1 2 3 4 5 6; do _db2_w six "00${_db2_i}0-f$_db2_i.sh" <<'X'
ok "djy $DJ2N"
X
done
_db2_new six "$DB2/g-empty.tsv" + "$DB2/pp/six"/*.sh
_db2_go p --part 0010-f1.sh 0020-f2.sh 0030-f3.sh 0040-f4.sh 0050-f5.sh 0060-f6.sh; _db2_wait
_db2_x="$(grep '^@@' "$_db2_c/p.out" | tr '\n' '|')"
is "D1: --part takes six names: the prelude mark, a member mark for each in order, and the part mark naming all six, with exit 0" "$_db2_rc $_db2_x" \
   "0 @@prelude-done|@@member-done 0010-f1.sh|@@member-done 0020-f2.sh|@@member-done 0030-f3.sh|@@member-done 0040-f4.sh|@@member-done 0050-f5.sh|@@member-done 0060-f6.sh|@@part-done 0010-f1.sh 0020-f2.sh 0030-f3.sh 0040-f4.sh 0050-f5.sh 0060-f6.sh|"
_db2_go p1 --part 0030-f3.sh; _db2_wait
is "D1: and one name: the member between the two marks, and only that part's assertion after the prelude" \
   "$_db2_rc $(sed -n '/^@@prelude-done$/,$p' "$_db2_c/p1.out" | tr '\n' '|')" "0 @@prelude-done||djy-sec 0030-f3.sh|  ok    djy 0030-f3.sh|@@member-done 0030-f3.sh|@@part-done 0030-f3.sh|"
_db2_E=(FELIX_TEST_PART_LOG="$_db2_c/x.log" FELIX_TEST_PART_RAN="$_db2_c/x.ran" FELIX_TEST_PART_END="$_db2_c/x.end"); _db2_go e -j 1; _db2_wait
is "D1: the FELIX_TEST_PART_ variables alone do not make part mode: a run without --part reaches its end on stdout and writes none of the files (control)" \
   "$_db2_rc $(_db2_cnt "$_db2_c/e.out" reached) $(grep -c '^@@' "$_db2_c/e.out") $(ls "$_db2_c"/x.* 2>/dev/null | wc -l | tr -d ' ')" "0 1 0 0"
rm -rf "$DB2/n/six"

# ---- the durations file (D4): written whole by a -j run with no runner failure, and by nothing else
_db2_q dur; _db2_new dur "$DB2/g-empty.tsv" + "$DB2/pp/dur"/*.sh
_db2_dg="$_db2_F/.git/felix-suite-durations"; printf '5\tdjy-sentinel.sh\n' > "$_db2_dg"; cp "$_db2_dg" "$DB2/dur.seed"
_db2_E=(FELIX_TEST_NO_MANIFEST=1); _db2_go n -j 3; _db2_wait
_db2_x="$_db2_rc $(_db2_last n | grep -c ' (counted from lines)$') $(cmp -s "$_db2_dg" "$DB2/dur.seed" && echo kept || echo changed) $(_db2_rcpt)"
is "D4: a -j 3 run under FELIX_TEST_NO_MANIFEST=1, as red runs, counts from lines, reads and writes no durations and leaves no receipt" "$_db2_x" "0 1 kept absent"
_db2_go j1 -j 1; _db2_wait; _db2_x="$_db2_rc $(cmp -s "$_db2_dg" "$DB2/dur.seed" && echo kept || echo changed) $(_db2_rcpt)"
_db2_go ru --reuse; _db2_wait; _db2_x="$_db2_x | $_db2_rc $(cmp -s "$_db2_dg" "$DB2/dur.seed" && echo kept || echo changed)"
is "D4: a -j 1 run and a --reuse after it neither remove nor rewrite the durations file (control)" "$_db2_x" "0 kept present | 0 kept"
_db2_go j3 -j 3; _db2_wait
is "D4: a -j 3 run does write it, whole: the sentinel row gone, one row for each of the four parts" \
   "$_db2_rc $(grep -c 'djy-sentinel' "$_db2_dg") $(awk 'END { print NR }' "$_db2_dg") $(_db2_last j3 | grep -c ' (counted from lines)$')" "0 0 4 1"
rm -rf "$DB2/n/dur"
_db2_w dk 0010-ka.sh <<'X'
ok "djy $DJ2N"
X
_db2_w dk 0020-kb.sh <<'X'
ok "djy before"
kill -9 $$
X
_db2_new dk "$DB2/g-empty.tsv" + "$DB2/pp/dk"/*.sh
printf '5\t0010-ka.sh\n' > "$_db2_F/.git/felix-suite-durations"; cp "$_db2_F/.git/felix-suite-durations" "$DB2/dk.seed"
_db2_go k -j 3; _db2_wait
is "D4: a -j 3 run with a runner failure writes no durations: the file is as it was, and the failure is the unit's" \
   "$_db2_rc $(cmp -s "$_db2_F/.git/felix-suite-durations" "$DB2/dk.seed" && echo kept || echo changed) $(_db2_cnt "$_db2_c/k.out" '  FAIL  part ended without its mark: 0020-kb.sh')" "1 kept 1"
# the three assertions of 9990 judge the units' end states: a unit with no end file makes all three bad (D3)
_db2_n9a="no fixture git command was refused for a directory outside the suite's temporary directory"
_db2_n9b="fixture floor: at the end of the suite it still stands in cwd inside its temporary directory, under a ceiling at that directory's parent"
_db2_n9c="the remotes of the checkout this run started in did not move while it ran"
_db2_x="$(for _db2_a in "$_db2_n9a" "$_db2_n9b" "$_db2_n9c"; do grep -qF -e "$_db2_a" "$HERE"/parts/9990-*.sh && printf 'named '; done)"
is "D3: the three names the cases below read are 9990's (control)" "$_db2_x" "named named named "
is "D3: a unit killed with kill -9 has no end file, so 9990's floor, refusal and origin assertions each FAIL once, beside the unit's own failures" \
   "$(_db2_cnt "$_db2_c/k.out" "  FAIL  $_db2_n9b") $(_db2_cnt "$_db2_c/k.out" "  FAIL  $_db2_n9a") $(_db2_cnt "$_db2_c/k.out" "  FAIL  $_db2_n9c")" "1 1 1"
rm -rf "$DB2/n/dk"
# a unit's own origin verdict: a remote moved and put back inside one unit is still a move (the unit's record), and the parent, which never saw the config differ, must say so
_db2_w om 0010-oa.sh <<'X'
ok "djy $DJ2N"
X
_db2_w om 0020-ob.sh <<'X'
_cfg="$_og_start/.git/config"
cp -p "$_cfg" "$DJ2D/config.save"
sleep 1.2
printf '[remote "djyx"]\n\turl = /nonexistent/djyx.git\n\tfetch = +refs/heads/*:refs/remotes/djyx/*\n' >> "$_cfg"
ok "djy $DJ2N moved"
cp -p "$DJ2D/config.save" "$_cfg"
ok "djy $DJ2N put back"
X
_db2_new om "$DB2/g-empty.tsv" + "$DB2/pp/om"/*.sh
_db2_go o1 -j 1; _db2_wait; _db2_x="$_db2_rc $(_db2_cnt "$_db2_c/o1.out" "  FAIL  $_db2_n9c")"
is "D3: a remote moved and put back inside a part makes a -j 1 run's origin assertion FAIL (control for the case below)" "$_db2_x" "1 1"
_db2_go o3 -j 3; _db2_wait
is "D3: and inside a unit it does the same under -j 3: the unit's verdict is bad, so the origin assertion FAILs once and the run exits 1" \
   "$_db2_rc $(_db2_cnt "$_db2_c/o3.out" "  FAIL  $_db2_n9c") $(_db2_last o3 | grep -c ' (counted from lines)$')" "1 1 1"
rm -rf "$DB2/n/om"
# a record run with a runner failure ends in the runner, before 9990's lines and the record's (D4)
_db2_new rk --red "$DB2/g-empty.tsv" "$DB2/man.tsv" "$DB2/pp/dk"/*.sh
_db2_go r -j 3 --record-assertions; _db2_wait
_db2_rps() { ps -A -ww -o pid= -o stat= -o command= 2>/dev/null | K="$(_db2_key)" LC_ALL=C awk '$2 !~ /^Z/ && index($0, ENVIRON["K"]) && index($0, "/tests/red") { printf "%s ", $1 }'; }
_db2_nored() { [ -z "$(_db2_rps)" ]; }
_db2_t0="$(_db2_ms)"; _db2_until 100 _db2_nored; _db2_t1="$(_db2_ms)"
_db2_x="$_db2_rc $(grep -cF -e "$_db2_n9a" -e "$_db2_n9b" -e "$_db2_n9c" "$_db2_c/r.out") $(_db2_pfx "$_db2_c/r.out" '  recorded ') $(_db2_cnt "$_db2_c/r.out" reached) $(_db2_cnt "$_db2_c/r.out" '  FAIL  part ended without its mark: 0020-kb.sh')"
is "D4: a record run with a unit killed exits 1 in the runner: none of 9990's three lines, no recorded line, no reached, and the unit's failure printed" "$_db2_x" "1 0 0 0 1"
is "D4: and red, which the watcher ends once the mark failed is written, is gone within 15 s of the parent's exit, the runner having failed the unit" \
   "$([ $((_db2_t1 - _db2_t0)) -le 15000 ] && _db2_nored && echo gone || echo "still running after $((_db2_t1 - _db2_t0)) ms") $(_db2_cnt "$_db2_c/r.out" '  FAIL  part ended without its mark: 0020-kb.sh')" "gone 1"
_db2_reap r; rm -rf "$DB2/n/rk"

# ---- the log is printed in the driver's order, once a unit and every unit before it have ended (D3)
_db2_w ord 0010-ea.sh <<'X'
: > "$DJ2D/up.$DJ2N"
_i=0; until [ -e "$DJ2D/release.a" ] || [ "$_i" -ge 400 ]; do sleep 0.2; _i=$((_i + 1)); done
ok "djy $DJ2N"
X
for _db2_a in 0020-eb.sh 0030-ec.sh; do _db2_w ord "$_db2_a" <<'X'
: > "$DJ2D/done.$DJ2N"
ok "djy $DJ2N"
X
done
_db2_new ord "$DB2/g-empty.tsv" + "$DB2/pp/ord"/*.sh
_db2_lim=200; _db2_go o -j 3
_db2_until 450 _db2_up 0010-ea.sh; _db2_until 150 test -e "$_db2_c/done.0030-ec.sh"; _db2_until 50 test -e "$_db2_c/done.0020-eb.sh"; sleep 3
_db2_x="$(_db2_cnt "$_db2_c/o.out" 'djy-sec 0020-eb.sh') $(_db2_cnt "$_db2_c/o.out" 'djy-sec 0030-ec.sh')"; _db2_y="$([ -e "$_db2_c/done.0030-ec.sh" ] && echo ended-first || echo not-ended)"
: > "$_db2_c/release.a"; _db2_wait
is "D3: the two units after a slow first one end before it, and the log shows neither of them until the first has ended" "$_db2_y $_db2_x" "ended-first 0 0"
is "D3: once it has, the sections come in the driver's order, and the run passes, counted from lines" \
   "$_db2_rc $(_db2_last o | grep -c ' (counted from lines)$') $(grep '^djy-sec ' "$_db2_c/o.out" | tr '\n' ' ')" "0 1 djy-sec 0010-ea.sh djy-sec 0020-eb.sh djy-sec 0030-ec.sh "
rm -rf "$DB2/n/ord"

# ---- a unit that waited for a slot (D3, D4, D6): the note says how long, and the duration written does not count the wait
for _db2_a in 0010-wa.sh 0020-wb.sh; do _db2_w wt "$_db2_a" <<'X'
perl -e 'sleep 4'
ok "djy $DJ2N"
X
done
_db2_new wt "$DB2/g-empty.tsv" + "$DB2/pp/wt"/*.sh; _db2_S=1; _db2_go a -j 2; _db2_wait
_db2_nt="$(grep '^  note  ' "$_db2_c/a.out")"; _db2_nu="$(printf '%s' "$_db2_nt" | awk '{ print $2 }')"; _db2_ns="$(printf '%s' "$_db2_nt" | awk '{ print $4 }')"
_db2_dd="$(awk -F'\t' '{ d[NR] = $1 } END { x = d[1] - d[2]; if (x < 0) x = -x; print NR, x }' "$_db2_F/.git/felix-suite-durations" 2>/dev/null)"
is "D3: with one slot the unit that waited gets one note, whose seconds are at least the 4 s the other held the slot, and not an assertion" \
   "$_db2_rc $(printf '%s' "$_db2_nt" | awk 'END { print NR }') ${_db2_nu:+named} $([ "${_db2_ns:-0}" -ge 4 ] 2>/dev/null && echo long || echo "S=${_db2_ns:-none}")" "0 1 named long"
is "D4: and the durations of the two units differ by under 3 s, so the one that waited is not charged for the wait (it would be about 4 s more)" "${_db2_dd%% *} $([ "${_db2_dd#* }" -lt 3 ] 2>/dev/null && echo near || echo "apart [$_db2_dd]")" "2 near"
rm -rf "$DB2/n/wt"

# ---- what the parent prints of a unit (D3): what comes after the mark stays, the runner's own lines and the prelude's prefix do not show
_db2_w fm 0010-fa.sh <<'X'
trap 'printf "djy-after-mark\n"; rm -rf "$TMP"' EXIT
case "$(ps -p $$ -o command= 2>/dev/null)" in *" --part "*) printf 'djy-mode:unit\n' ;; *) printf 'djy-mode:serial\n' ;; esac
ok "djy $DJ2N"
X
_db2_w fm 0020-fb.sh <<'X'
ok "djy $DJ2N"
X
_db2_new fm "$DB2/g-empty.tsv" + "$DB2/pp/fm"/*.sh; _db2_go f -j 3; _db2_wait
is "D3: a line a unit's own EXIT trap prints after the mark is printed as written; no runner line, no prelude-prefixed line and no wait note shows in a passing run" \
   "$_db2_rc $(_db2_cnt "$_db2_c/f.out" djy-after-mark) $(_db2_cnt "$_db2_c/f.out" djy-mode:unit) $(grep -c '^@@' "$_db2_c/f.out") $(_db2_pfx "$_db2_c/f.out" '  | ') $(_db2_pfx "$_db2_c/f.out" '  note  ')" "0 1 1 0 0 0"
rm -rf "$DB2/n/fm"

# ---- a wrapper that is gone without a line ends its unit as having no mark (D6, learning that a unit ended)
_db2_w wg 0010-wa.sh <<'X'
_d="$(cat "$DJ2D/w.pid")"; _p=$$; _w=""
while [ -n "$_p" ] && [ "$_p" -gt 1 ]; do
  _pp="$(ps -o ppid= -p "$_p" 2>/dev/null | tr -d ' ')"
  [ -n "$_pp" ] || break
  if [ "$_pp" = "$_d" ]; then _w="$_p"; break; fi
  _p="$_pp"
done
: > "$DJ2D/wrapper.${_w:-none}"
[ -z "$_w" ] || kill -KILL "$_w" 2>/dev/null
sleep 1
ok "djy $DJ2N"
X
_db2_w wg 0020-wb.sh <<'X'
ok "djy $DJ2N"
X
_db2_new wg "$DB2/g-empty.tsv" + "$DB2/pp/wg"/*.sh; _db2_lim=100; _db2_go w -j 2; _db2_wait
_db2_x="$_db2_rc $(ls "$_db2_c" | grep -c '^wrapper\.[0-9]') $(_db2_cnt "$_db2_c/w.out" '  FAIL  part ended without its mark: 0010-wa.sh') $(_db2_pfx "$_db2_c/w.out" '  FAIL  part ended without its mark: 0020-wb.sh') $(_db2_rcpt)"
_db2_reap w
is "D6: the wrapper of a unit killed with kill -9 while the unit runs: the run does not hang, ends 1 with that unit alone failed as having no mark, and leaves no receipt" "$_db2_x" "1 1 1 0 absent"
rm -rf "$DB2/n/wg"

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
is "D6: a unit has no pipe or FIFO descriptor above 2 that the same part has not under -j 1, and the probe sees a FIFO a part opens itself" \
   "$([ "$_db2_x3" = "$_db2_x1" ] && echo same || echo "[$_db2_x3] differs from [$_db2_x1]") $(case "$_db2_y3" in *9*) echo sees-9 ;; *) echo "ctl [$_db2_y3]" ;; esac) $(_db2_cnt "$_db2_c/f3.out" djy-mode:unit)" "same sees-9 1"
rm -rf "$DB2/n/fd"

# ---- the part leaves the shell as it found it
_db2_unhold
rm -rf "${DB2:?}"
unset -f $(compgen -A function _db2_) 2>/dev/null
unset $(compgen -A variable _db2_) DB2 DG DGC 2>/dev/null
# <<< gate-friction-d-signals-blind
