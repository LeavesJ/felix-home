# >>> instrument-removers
printf '\n%s\n' "the judge's removers each finish, whatever the other is doing: the watchdog, the shell that starts it, the supervisor (contract 2026-11-17, IR1 to IR6, blind)"
# Blind, written on 2026-11-17 from docs/2026-11-17-instrument-removers-contract.md (rev 1, IR1 to IR6), and amended from its
# rev 2 (IR3's order, IR5 in the race rounds, IR6's per-race collisions and limited waits) and its rev 3 (limits above
# the programs' own 30 s, and a worker under J past rev 2's attempts) and its rev 4 (which worker rounds count, and the
# supervisor's worker at work from PARENT gone) and its rev 5 (the part signals only what it started), alone, by an author
# who has not read lib/instrument-run.sh, lib/instrument.sh, lib/bind.sh or lib/merge-judge.sh. The programs are taken from
# the fixture engine's lib/instrument-run.sh, _felix_instr_wdpl (the watchdog) and _felix_instr_pl (the supervisor), and run
# as perl -e PROGRAM ARGS; _felix_instr_watch is run in a shell that sources that file. A name ending (control) holds on the
# engine the contract was cut from, on purpose; the others are the new behaviour. Every tree is under $TMP/irb.
#
# Readings, where the contract leaves room:
# - PARENT, in the IR2 and IR4 rounds, is a bash subshell that starts the program as its own child, passing its own pid (read
#   through /bin/sh's $PPID, since bash 3.2 has no BASHPID), then execs a holder (IRB_HD) that writes the program's pid
#   file and sleeps 30 s; the part KILLs and reaps it. A supervisor's COMMAND is perl -e "sleep 60" DIR/unit. A KILLed parent
#   cannot report its orphan's status, so the status is read by a recorder the part puts in front of the program,
#   perl -e RECORDER -e PROGRAM ARGS: an END block, in the program's own process and for that pid only, that writes $? to
#   the file IRB_ST names. Its BEGIN also sets INT and QUIT back to default, which bash ignores in a background job, so what
#   the program does with them is its own. IR6's recorder control arms it against wait, on a watchdog and on a supervisor.
# - "Left" is read by lstat at once after the program is gone (polled every 0.02 s), before the rival is waited for. A
#   program still running 45 s (IRB_PLIM) after its PARENT was KILLed, IR3's "within a few seconds" included, is KILLed by
#   exact pid and its round counted as left, "timeout". A round's tree also holds keep/, beside the PATHs, for "removes only
#   its PATHs". 45 s (rev 3) is the program's own 30 s on one PATH, the only PATH a rival works under being J, plus its other
#   steps (up to 0.25 s to see PARENT gone, the salvage, the other PATHs, a supervisor's group ended in about 1 s) and room.
# - The rival (the concurrent remover) waits until the program is ready: the watchdog leads its own process group, the
#   supervisor has written GROUP-FILE. Then the part KILLs PARENT. The rival checks every 0.05 s for PARENT gone (IR2, IR3)
#   or the unit's group gone (IR4), then runs one plain File::Path::remove_tree of J, no eval, and stops.
# - The tree: J is A directories of 10 directories of 10 empty files. A starts at 20 and doubles, to at most 160, until
#   one plain removal of J takes 0.3 s or more on this host (above the 0.25 s window); a note line prints what was chosen.
#   R, UP (u1 and u2, made mode 0311 after its contents, as a real run has it), HP and BD are small. BD is a bare
#   repository's shape: objects/ab and objects/cd with one loose object each, objects/pack with pack-move.{pack,idx} and
#   pack-keep.{pack,idx}, objects/info/packs; BD.list beside it; TO (the home's objects, ho) beside them, empty.
# - KEEP is pack-keep; pack/KEEP.* is read as a file in pack/ whose name is KEEP and a dot and more. XX is two lowercase
#   hex digits: zz/ and abc/ are not, and info/packs and a directory under ab/ are not moved either.
# - IR3's shell is a fresh "$BASH" -c, so its $$ is its BASHPID; BD is DIR/felix-objects.irb. It does not own the bind
#   copy when _FELIX_BIND_OWNER is 1. Its watchdog's status is not read: _felix_instr_watch starts it, not the part.
# - IR5's waiting watchdog has the part's own shell for PARENT; the four signals go 0.1 s apart, it is read alive 0.5 s
#   after the last, and "within about a second" of USR1 is 1.5 s. "Stays", for a link's target, is that it and its file
#   exist; its mode is not read. A supervisor whose PARENT lives runs sh -c 'exit 7' and gives 7.
# - IR6: when no arming round collides, the race assertions are skipped by name and their rounds are not run.
# - IR6 (rev 2), "died": a plain removal died when its process exited non-zero with a File::Path croak in its stderr, a
#   line ending "aborting." (all four of rmtree's croaks in File::Path 2.18 end so: cannot chdir, cannot stat, and the two
#   "changed" checks). Arming counts only those; another non-zero exit is counted apart and shown in the note line. Each race
#   counts its rounds in which the rival's removal died so, and a note line gives the count. In a race with none, each
#   assertion that would pass is skipped by name, saying no round of it collided; one that fails still fails, as a failure
#   needs no arming.
# - IR6 (rev 2), limits: the ready file 10 s; the rival 10 s to get ready, 15 s for PARENT or the group, then 4.2 s of
#   work (the supervisor's worker: up to 15 s more for the group, then 4.2 s); a program removing 45 s (rev 3), in rounds
#   and in the controls that run the watchdog; the pair's go file 10 s, each of the pair 30 s; USR1 1.5 s; a supervisor
#   whose PARENT lives 10 s; a group leader 5 s; PARENT's holder lives 30 s. The part's programs that make or time a tree
#   run in the foreground, bounded by the tree; a tree not made fails its round ("no tree", or the arming assertion).
# - Rev 3 and 4, the worker, for the watchdog (its own program, as in IR2) and the supervisor's judge-gone path, J small:
#   from PARENT gone it turns J's contents over, each cycle making J/gK (4 x 5 directories, 100 files) then removing
#   J/g(K-1), its deaths caught with a chdir to /; it never empties or remakes J. It works 4.2 s ("about 4 s") from PARENT
#   gone for the watchdog, and for the supervisor until 4.2 s after it sees the group gone. It writes rebuilds, cycles,
#   deaths, whether J was there, and when the group went. A round outlasted the program when rebuilds is above 0 and J was
#   there as it stopped; another round with a report counts neither way. Rounds go on until 5 outlast, 10 at most; a
#   note gives the counts. No report is a fixture failure; a PATH left is red in any round (a failure needs no arming,
#   and the worker cannot leave J); none outlasted is a skip by name; else ok.
# - IR3's order (rev 2): 3 rounds, no rival, J of the calibrated size, so its removal takes 0.3 s or more. From just after
#   the KILL until the watchdog is gone the judge looks every 0.01 s (about 30 looks in that removal) for BD and BD.list
#   gone while J is there; every round must show it. The detail gives the looks that saw it, those that saw J gone with
#   BD there (the old order), those that saw J, and all looks.
# - IR5 in the race rounds (rev 2): each race asserts that keep/, beside the PATHs, stays in every round (control).
# - Rev 5, the mark: "$IRB/", this run's directory under the suite's mktemp $TMP, read with ps -ww -o command= -p PID.
#   Every process the part starts holds a path under it: the programs' PATHs, PARENT's holder's pid file (written after
#   the exec, so nothing signals PARENT before it carries the mark), IR3's shell ($0) and holder, COMMAND (DIR/unit), the
#   arming pair's go file. Checked before PARENT's KILL, the waiter's KILL after a timeout, a unit group's KILL (on its
#   leader) and each signal to the waiting watchdog; not before the KILL of a child just started and still asleep. A
#   target without it is left alone, not waited for, and its round or control fails saying so ("alone", "PARENT ...
#   left alone", "not sent"); a note line lists each. A control arms the check. A program that rewrote its own command
#   line would be left alone after a timeout: the contract does not say the programs keep theirs.
IRB="$TMP/irb"; rm -rf "${IRB:?}"; mkdir -p "$IRB"; IRB="$(cd "$IRB" && pwd -P)"; IRB_P="instrument removers:"
IRB_LIB="$FROOT/harness/lib/instrument-run.sh"
IRB_WD="$( set +u; . "$IRB_LIB" >/dev/null 2>&1; printf '%s' "${_felix_instr_wdpl-}" )"
IRB_SV="$( set +u; . "$IRB_LIB" >/dev/null 2>&1; printf '%s' "${_felix_instr_pl-}" )"
IRB_ME="$(exec /bin/sh -c 'echo "$PPID"')"
IRB_N=20; IRB_N3=20; IRB_NA=5; IRB_ARM=5; IRB_R=0; IRB_A=20; IRB_NO3=3; IRB_SEE=""; IRB_RVD=0; IRB_PLIM=45; IRB_NW=5; IRB_NWX=10; IRB_WS=4.2; IRB_WORK=""; IRB_LA=""
IRB_L1="$(printf '%038d' 0 | tr 0 1)"; IRB_L2="$(printf '%038d' 0 | tr 0 2)"
sleep 30 & IRB_DEAD=$!; { kill -KILL "$IRB_DEAD"; wait "$IRB_DEAD"; } 2>/dev/null   # a PARENT that is gone

# ------------------------------------------------------------------ programs ---
# The recorder, put in front of a program (see the readings).
IRB_REC='BEGIN { $SIG{INT} = $SIG{QUIT} = "DEFAULT"; $irb::pid = $$ }
END { if (defined $irb::pid and $$ == $irb::pid and defined $ENV{IRB_ST}) { my $irb_s = $?;
  if (open my $irb_f, ">", $ENV{IRB_ST}) { print {$irb_f} "$irb_s\n"; close $irb_f } $? = $irb_s } }'
# DIR A B C BD: a round's tree under DIR, which it makes; BD empty makes no bind copy.
IRB_MK='use strict; use warnings;
my ($d, $na, $nb, $nc, $bd) = @ARGV;
sub md { mkdir $_[0] or die "mkdir $_[0]: $!\n" }
sub wf { my ($p, $t) = @_; open(my $f, ">", $p) or die "write $p: $!\n"; print {$f} (defined $t ? $t : "x\n"); close $f or die "close $p: $!\n" }
md $d; md "$d/J";
for my $i (1 .. $na) { md "$d/J/d$i"; for my $j (1 .. $nb) { md "$d/J/d$i/e$j"; wf("$d/J/d$i/e$j/f$_", "") for 1 .. $nc } }
md "$d/R"; wf "$d/R/records"; md "$d/R/sub"; wf "$d/R/sub/a";
md "$d/UP"; for my $u (qw(u1 u2)) { md "$d/UP/$u"; wf "$d/UP/$u/out"; md "$d/UP/$u/tmp"; wf "$d/UP/$u/tmp/f" }
md "$d/HP"; for my $h (qw(h1 h2)) { md "$d/HP/$h"; wf "$d/HP/$h/.profile" }
md "$d/keep"; wf "$d/keep/file";
if (length $bd) {
  my $o = "$d/$bd/objects"; my $l1 = "1" x 38; my $l2 = "2" x 38;
  md "$d/$bd"; wf "$d/$bd/HEAD", "ref: refs/heads/main\n"; md "$d/$bd/refs"; md $o;
  md "$o/ab"; wf "$o/ab/$l1", "loose ab\n"; md "$o/cd"; wf "$o/cd/$l2", "loose cd\n"; md "$o/pack";
  wf("$o/pack/pack-move.$_", "move $_\n") for qw(pack idx); wf("$o/pack/pack-keep.$_", "keep $_\n") for qw(pack idx);
  md "$o/info"; wf "$o/info/packs", "P pack-move.pack\n"; wf "$d/$bd.list", "$o\n"; md "$d/ho";
}
chmod 0311, "$d/UP" or die "chmod $d/UP: $!\n";'
# MODE WHO PIDFILE GRPFILE READY TARGET: the rival (see the readings). MODE pid waits on WHO, grp on the group in GRPFILE.
# With IRB_WORK set to SECONDS and FILE, one a line, it is the worker (rev 3, 4): from WHO gone it makes TARGET/gK and
# removes TARGET/g(K-1), its own deaths caught, for SECONDS (MODE pid) or until SECONDS after the group is gone (MODE grp,
# 15 s at most for the group), then stops with TARGET as it is and writes what it did to FILE.
IRB_RV='use strict; use warnings; use File::Path qw(remove_tree); use Time::HiRes qw(sleep time);
my ($ws, $wf) = split /\n/, (defined $ENV{IRB_WORK} ? $ENV{IRB_WORK} : "");
sub mkg { my $g = shift; mkdir $g or return 0; for my $i (1 .. 4) { mkdir "$g/d$i" or return 0; for my $j (1 .. 5) {
  mkdir "$g/d$i/e$j" or return 0; for my $f (1 .. 5) { open(my $h, ">", "$g/d$i/e$j/f$f") or return 0; close $h } } } 1 }
my ($mode, $who, $pf, $gf, $ready, $path) = @ARGV;
sub num { open(my $h, "<", $_[0]) or return 0; my $l = <$h>; return (defined $l and $l =~ /(\d+)/) ? $1 : 0 }
my $t = time; my ($p, $g) = (0, 0);
until ($p = num($pf)) { exit 3 if time - $t > 10; sleep 0.01 }
if ($mode eq "grp") { until ($g = num($gf)) { exit 3 if time - $t > 10; sleep 0.01 } }
else { until (getpgrp($p) == $p) { last if time - $t > 10; sleep 0.01 } }
open(my $r, ">", "$ready.t") or exit 3; print {$r} "1\n"; close $r; rename("$ready.t", $ready) or exit 3;
my $wk = (defined $wf and length $path) ? 1 : 0;
$t = time;
while (time - $t < 15) { last unless kill(0, ($mode eq "grp" and !$wk) ? -$g : $who); sleep 0.05 }
if ($wk) {
  my $t0 = time; my ($end, $k, $n, $died, $gs) = ($mode eq "grp" ? undef : $t0 + $ws, 0, 0, 0, "-");
  while (1) {
    if (!defined $end) {
      if (!kill(0, -$g)) { $gs = sprintf("%.2f", time - $t0); $end = time + $ws } elsif (time - $t0 > 15) { $gs = "never"; $end = time }
    }
    last if defined $end and time >= $end;
    $k++; if (mkg("$path/g$k")) { $n++ } else { sleep 0.01 }
    if ($k > 1) { eval { remove_tree("$path/g" . ($k - 1), { error => \my $e }); 1 } or $died++; chdir "/" }
  }
  my $there = lstat($path) ? 1 : 0;
  open(my $o, ">", $wf) or exit 3; print {$o} "rebuilds=$n cycles=$k died=$died jthere=$there groupgone=$gs\n"; close $o; exit 0;
}
remove_tree($path) if length $path;
exit 0;'
# PID TIMEOUT PATH...: waits until PID is gone, then prints how and the last name of each PATH left. After TIMEOUT s it
# KILLs PID when PID's command line holds IRB_OWN, this run's mark ("timeout"), and else leaves it alone ("alone", rev 5).
# With IRB_SEE set to FILE, BD, BD.list and J, one a line, it looks every 0.01 s while PID lives and writes what it saw to FILE.
IRB_JG='use strict; use warnings; use Time::HiRes qw(sleep time);
my ($p, $to, @paths) = @ARGV; my $t = time; my $how = "exited"; my $own = defined $ENV{IRB_OWN} ? $ENV{IRB_OWN} : "";
sub mine { my $c = `ps -ww -o command= -p $_[0] 2>/dev/null`; return (length $own and index($c, $own) >= 0) ? 1 : 0 }
my @s = split /\n/, (defined $ENV{IRB_SEE} ? $ENV{IRB_SEE} : ""); my ($n, $seen, $jf, $jt) = (0, 0, 0, 0);
sub look { return unless @s == 4; $n++; my ($xb, $xl, $xj) = map { lstat($_) ? 1 : 0 } @s[1 .. 3];
  $jt++ if $xj; $seen++ if !$xb and !$xl and $xj; $jf++ if $xb and !$xj }
if (defined $p and $p =~ /^\d+$/ and $p > 1) {
  while (kill 0, $p) {
    look();
    if (time - $t > $to) { if (mine($p)) { kill "KILL", $p; $how = "timeout"; sleep 0.3 } else { $how = "alone" } last }
    sleep(@s == 4 ? 0.01 : 0.02);
  }
} else { $how = "nopid" }
if (@s == 4 and open(my $o, ">", $s[0])) { print {$o} "seen=$seen jfirst=$jf jthere=$jt looks=$n\n"; close $o }
my @left; for (@paths) { push @left, (split m{/}, $_)[-1] if length($_) and lstat($_) }
print join(" ", $how, @left), "\n";'
# PID: 0 once PID leads its own process group, 1 after 5 s.
IRB_RDY='use Time::HiRes qw(sleep time); my $t = time;
until (getpgrp($ARGV[0]) == $ARGV[0]) { exit 1 if time - $t > 5; sleep 0.02 } exit 0;'
# GO TREE: waits for GO (exit 4 after 10 s), then one plain remove_tree of TREE, no eval (IR6 arming).
IRB_PL='use File::Path qw(remove_tree); use Time::HiRes qw(sleep time); my $t = time;
until (-e $ARGV[0]) { exit 4 if time - $t > 10; sleep 0.002 } remove_tree($ARGV[1]);'
# TREE: one plain remove_tree of TREE, and the seconds it took.
IRB_TM='use File::Path qw(remove_tree); use Time::HiRes qw(time); my $t = time; remove_tree($ARGV[0]); printf "%.3f\n", time - $t;'
# PIDFILE PID: PARENT, once its shell has exec'd into it (rev 5): writes PID to PIDFILE, then sleeps 30 s. PIDFILE is under
# $IRB, so PARENT carries this run's mark before the pid file exists, and the rival is ready only after that.
IRB_HD='my ($f, $p) = @ARGV; open(my $o, ">", "$f.t") or exit 3; print {$o} ((defined $p ? $p : "") . "\n"); close $o;
rename("$f.t", $f) or exit 3; sleep 30;'

# ------------------------------------------------------------------- helpers ---
_irb_wait() { local n=0; while [ ! -s "$1" ]; do [ "$n" -lt $(($2 * 5)) ] || return 1; sleep 0.02; n=$((n + 1)); done; }   # FILE TENTHS
_irb_rm() { chmod 0700 "$1/UP" 2>/dev/null; rm -rf "${1:?}"; }   # DIR: a round's tree, gone
# Rev 5: this run's mark is "$IRB/", under the suite's own mktemp $TMP; every process the part starts holds a path under
# it in its command line. PID -> 0 when PID's command line holds the mark.
_irb_mine() { case "$(ps -ww -o command= -p "$1" 2>/dev/null)" in *"$IRB/"*) return 0 ;; esac; return 1; }
_irb_jg() { IRB_OWN="$IRB/" IRB_SEE="$IRB_SEE" perl -e "$IRB_JG" "$@"; }   # the waiter, told the mark
_irb_la() { IRB_LA="$IRB_LA $1;"; }   # TEXT: a target left alone, for the note at the end
_irb_run() {   # TIMEOUT CMD...: CMD in the background, KILLed after TIMEOUT s when it carries the mark -> IRB_RC its status
  local t="$1" p j; shift
  "$@" </dev/null >/dev/null 2>>"$IRB/err" & p=$!
  j="$(_irb_jg "$p" "$t")"
  case "$j" in
    alone*) IRB_RC=255; _irb_la "pid $p, still answering after $t s without this run's mark, was left alone and not waited for" ;;
    *) { wait "$p"; } 2>/dev/null; IRB_RC=$? ;;
  esac
}
_irb_is() { [ "$(cat "$1" 2>/dev/null)" = "$2" ] || printf ' %s is not [%s];' "${1#"$IRB/"}" "$2"; }   # FILE TEXT
_irb_no() { [ ! -e "$1" ] && [ ! -L "$1" ] || printf ' %s is there;' "${1#"$IRB/"}"; }               # PATH
_irb_salv() { _irb_is "$1/ho/ab/$IRB_L1" "loose ab"; _irb_is "$1/ho/cd/$IRB_L2" "loose cd"; _irb_is "$1/ho/pack/pack-move.pack" "move pack"
  _irb_is "$1/ho/pack/pack-move.idx" "move idx"; _irb_no "$1/ho/pack/pack-keep.pack"; _irb_no "$1/ho/pack/pack-keep.idx"; }   # DIR
_irb_intact() {   # DIR -> what changed in a waiting watchdog's tree: nothing is removed, BD's objects stay, TO is empty
  local f
  for f in J R UP HP BD BD.list "BD/objects/ab/$IRB_L1" BD/objects/pack/pack-move.pack keep/file; do
    [ -e "$1/$f" ] || printf ' %s is gone;' "$f"
  done
  [ -z "$(ls -A "$1/ho" 2>/dev/null)" ] || printf ' TO holds %s;' "$(ls -A "$1/ho" | tr '\n' ' ')"
}
# DIR PARENT MODE TARGET TIMEOUT PATH...: the rival removes TARGET (none when empty) once PARENT (MODE pid) or the unit's
# group (MODE grp) is gone; PARENT is KILLed once the program is ready. -> IRB_LEFT, IRB_S, IRB_WP (the program's pid),
# IRB_RVD: 0 the rival exited 0, 1 its removal died with a File::Path croak (IR6: this round collided), 2 another exit
_irb_go() {
  local d="$1" pp="$2" m="$3" tg="$4" to="$5" rv pa; shift 5
  IRB_WORK="$IRB_WORK" perl -e "$IRB_RV" "$m" "$pp" "$d/pid" "$d/grp" "$d/ready" "$tg" </dev/null >/dev/null 2>>"$d/rv.err" &
  rv=$!
  _irb_wait "$d/ready" 100 || :
  if _irb_mine "$pp"; then { kill -KILL "$pp"; wait "$pp"; } 2>/dev/null; pa=""
  else pa="PARENT $pp did not carry this run's mark and was left alone, not waited for: "; _irb_la "${d#"$IRB/"}: $pa"; fi
  IRB_WP="$(LC_ALL=C sed -n '1{s/[^0-9]//g;p;}' "$d/pid" 2>/dev/null)"
  IRB_LEFT="$pa$(_irb_jg "${IRB_WP:-x}" "$to" "$@")"
  case "$IRB_LEFT" in alone*) _irb_la "${d#"$IRB/"}: the program $IRB_WP still answered after $to s without this run's mark, left alone" ;; esac
  { wait "$rv"; } 2>/dev/null; IRB_RVD=$?
  if [ "$IRB_RVD" != 0 ]; then case "$(cat "$d/rv.err" 2>/dev/null)" in *"aborting."*) IRB_RVD=1 ;; *) IRB_RVD=2 ;; esac; fi
  IRB_S="$(cat "$d/st" 2>/dev/null)"; IRB_S="${IRB_S:-none}"
}
_irb_wd() {   # DIR RACE A: a watchdog round; RACE 1 adds the rival on J. PATHs in today's order, the bind copy last.
  local d="$1" pp tg=""
  [ "$2" != 1 ] || tg="$d/J"
  perl -e "$IRB_MK" "$d" "$3" 10 10 BD 2>>"$IRB/err" || { IRB_LEFT="no tree"; IRB_S=none; IRB_WP=""; IRB_RVD=0; return 0; }
  ( p="$(exec /bin/sh -c 'echo "$PPID"')"
    IRB_ST="$d/st" perl -e "$IRB_REC" -e "$IRB_WD" "$p" "$d/BD/objects" "$d/ho" pack-keep \
      "$d/J" "$d/R" "$d/UP" "$d/HP" "$d/BD" "$d/BD.list" </dev/null >/dev/null 2>>"$d/err" &
    exec perl -e "$IRB_HD" "$d/pid" "$!" ) &
  pp=$!
  _irb_go "$d" "$pp" pid "$tg" "$IRB_PLIM" "$d/J" "$d/R" "$d/UP" "$d/HP" "$d/BD" "$d/BD.list"
}
_irb_sv() {   # DIR RACE A: a supervisor round, COMMAND a long sleep; RACE 1 adds the rival on J
  local d="$1" pp tg="" g
  [ "$2" != 1 ] || tg="$d/J"
  perl -e "$IRB_MK" "$d" "$3" 10 10 "" 2>>"$IRB/err" || { IRB_LEFT="no tree"; IRB_S=none; IRB_WP=""; IRB_RVD=0; return 0; }
  ( p="$(exec /bin/sh -c 'echo "$PPID"')"
    IRB_ST="$d/st" perl -e "$IRB_REC" -e "$IRB_SV" "$p" 60 "$d/log" "$d/grp" \
      "$d/J" "$d/R" "$d/UP/u1" "$d/UP" "$d/HP" perl -e "sleep 60" "$d/unit" </dev/null >/dev/null 2>>"$d/err" &
    exec perl -e "$IRB_HD" "$d/pid" "$!" ) &
  pp=$!
  _irb_go "$d" "$pp" grp "$tg" "$IRB_PLIM" "$d/J" "$d/R" "$d/UP/u1" "$d/UP" "$d/HP"
  g="$(LC_ALL=C sed -n '1{s/[^0-9]//g;p;}' "$d/grp" 2>/dev/null)"
  if [ -n "$g" ] && kill -0 -- "-$g" 2>/dev/null; then   # the unit's group outlived its supervisor: KILL it if it is ours
    if _irb_mine "$g"; then kill -KILL -- "-$g" 2>/dev/null
    else _irb_la "${d#"$IRB/"}: group $g still answered, its leader without this run's mark, left alone"; fi
  fi
}
_irb_sh() {   # DIR RACE A OWN [SEE]: a shell sources the lib, runs _felix_instr_watch over DIR and execs sleep; OWN 1 owns
  local d="$1" pp tg=""   # BD; SEE 1 has the judge look for IR3's order and write it to DIR/see
  [ "$2" != 1 ] || tg="$d/J"
  IRB_SEE=""; [ "${5:-0}" != 1 ] || IRB_SEE="$d/see"$'\n'"$d/felix-objects.irb"$'\n'"$d/felix-objects.irb.list"$'\n'"$d/J"
  perl -e "$IRB_MK" "$d" "$3" 10 10 felix-objects.irb 2>>"$IRB/err" || { IRB_LEFT="no tree"; IRB_S=none; IRB_WP=""; IRB_RVD=0; return 0; }
  "$BASH" -c '
    . "$1" || exit 3
    d="$2"; _FELIX_INSTR_J="$d/J"; _FELIX_INSTR_R="$d/R"; _FELIX_INSTR_UP="$d/UP"; _FELIX_INSTR_HP="$d/HP"
    _FELIX_INSTR_OWNER=$$; _FELIX_BIND_DIR="$d/felix-objects.irb"; _FELIX_BIND_OWNER=$$
    [ "$3" = 1 ] || _FELIX_BIND_OWNER=1
    _FELIX_BIND_HOME="$d/ho"; _FELIX_BIND_PACK=pack-keep
    _felix_instr_watch
    exec perl -e "$4" "$d/pid" "${_FELIX_INSTR_WD-}"' "$d/shell" "$IRB_LIB" "$d" "$4" "$IRB_HD" </dev/null >/dev/null 2>>"$d/err" &
  pp=$!
  _irb_go "$d" "$pp" pid "$tg" "$IRB_PLIM" "$d/felix-objects.irb" "$d/felix-objects.irb.list" "$d/J" "$d/R" "$d/UP" "$d/HP"
  IRB_SEE=""
}
# KIND N RACE A: N rounds of _irb_KIND -> IRB_K rounds run; IRB_CL rounds with a PATH left (IRB_DL), IRB_CK rounds with
# keep/ gone (IRB_DK), IRB_CS rounds whose status is not KIND's (IRB_DS; sh's is not read), IRB_CV rounds whose salvage is
# wrong (IRB_DV), IRB_CR rounds in which the rival's removal died with a File::Path croak, IRB_CO its other non-zero exits
_irb_rounds() {
  local kind="$1" n="$2" k=0 d w want=0
  IRB_CL=0; IRB_DL=""; IRB_CK=0; IRB_DK=""; IRB_CS=0; IRB_DS=""; IRB_CV=0; IRB_DV=""; IRB_CR=0; IRB_CO=0
  [ "$kind" != sv ] || want=125
  while [ "$k" -lt "$n" ]; do
    k=$((k + 1)); IRB_R=$((IRB_R + 1)); d="$IRB/$kind.$IRB_R"
    "_irb_$kind" "$d" "$3" "$4" 1
    if [ "$IRB_LEFT" != exited ]; then
      IRB_CL=$((IRB_CL + 1)); IRB_DL="$IRB_DL r$k: $IRB_LEFT;"
      [ -n "$IRB_WP" ] || IRB_DL="$IRB_DL [$(head -c 200 "$d/err" 2>/dev/null | tr '\n' ' ')]"
    fi
    [ "$IRB_RVD" != 1 ] || IRB_CR=$((IRB_CR + 1)); [ "$IRB_RVD" != 2 ] || IRB_CO=$((IRB_CO + 1))
    [ -e "$d/keep/file" ] || { IRB_CK=$((IRB_CK + 1)); IRB_DK="$IRB_DK r$k;"; }
    [ "$kind" = sh ] || [ "$IRB_S" = "$want" ] || { IRB_CS=$((IRB_CS + 1)); IRB_DS="$IRB_DS r$k: $IRB_S;"; }
    if [ "$kind" != sv ]; then w="$(_irb_salv "$d")"; [ -z "$w" ] || { IRB_CV=$((IRB_CV + 1)); IRB_DV="$IRB_DV r$k:$w"; }; fi
    _irb_rm "$d"
    [ "$kind" != sh ] || [ -n "$IRB_WP" ] || break   # no watchdog was started: each later round would wait out the rival
  done
  IRB_K=$k
}
_irb_ck() { if [ "$2" -eq 0 ]; then ok "$1"; else bad "$1" "$3"; fi; }   # NAME COUNT DETAIL
_irb_rc() {   # NAME COUNT DETAIL: a race's assertion, from _irb_rounds; one that would pass is skipped when no round collided
  if [ "$2" -eq 0 ] && [ "$IRB_CR" -eq 0 ]; then skip "$1" "no round of this race collided: the rival's plain removal died in 0 of $IRB_K rounds"
  else _irb_ck "$1" "$2" "$3 (the rival's plain removal died in $IRB_CR of $IRB_K rounds)"; fi
}
_irb_note() { printf "  note  instrument removers: %s race: the rival's plain removal died in %s of %s rounds; it exited non-zero otherwise in %s\n" "$1" "$IRB_CR" "$IRB_K" "$IRB_CO"; }
# KIND NAME (rev 3, 4): rounds of _irb_KIND, J small, the worker under J (see IRB_RV), until IRB_NW rounds have
# outlasted the program or IRB_NWX have run. A round outlasted when the worker made something and J was there as it
# stopped; one that did not is in the detail and counts neither way. NAME is red when a worker wrote no report or a
# PATH was left, skipped when no round outlasted, ok otherwise; a note line gives the counts.
_irb_work() {
  local k=0 d w f=0 l=0 o=0 x="" c
  while [ "$o" -lt "$IRB_NW" ] && [ "$k" -lt "$IRB_NWX" ]; do
    k=$((k + 1)); IRB_R=$((IRB_R + 1)); d="$IRB/$1.w$IRB_R"
    IRB_WORK="$IRB_WS"$'\n'"$d/work"; "_irb_$1" "$d" 1 2; IRB_WORK=""
    w="$(cat "$d/work" 2>/dev/null)"
    [ "$IRB_LEFT" = exited ] || l=$((l + 1))
    case "$w" in
      "") f=$((f + 1)); c="no report" ;;
      "rebuilds=0 "*) c="did not outlast" ;;
      *" jthere=1 "*) o=$((o + 1)); c="outlasted" ;;
      *) c="did not outlast" ;;
    esac
    x="$x r$k $c: [$IRB_LEFT] exit $IRB_S, worker [${w:-none}];"
    _irb_rm "$d"
  done
  printf '  note  instrument removers: %s worker: %s rounds, %s outlasted the program, %s did not, %s wrote no report\n' \
    "$([ "$1" = wd ] && printf IR2 || printf IR4)" "$k" "$o" "$((k - o - f))" "$f"
  if [ "$f" -gt 0 ]; then bad "$2" "the worker wrote no report in $f of $k rounds, a fixture failure:$x"
  elif [ "$l" -gt 0 ]; then bad "$2" "a PATH was left in $l of $k rounds ($o outlasted the program):$x"
  elif [ "$o" -eq 0 ]; then skip "$2" "no round outlasted the program, in $k rounds:$x"
  else ok "$2"; fi
}

# ------------------------------------------------------- IR6 (rev 5), the mark ---
# A probe the part starts carries the mark, read as before a signal; the suite's own shell does not. The probe is KILLed
# as a child of this shell just started and still sleeping, which rev 5 lets go unchecked.
IRB_NM="$IRB_P IR6: the mark this part reads before each signal is found on a process it started and not on the suite's own shell (control)"
perl -e "sleep 10" "$IRB/mark.probe" </dev/null >/dev/null 2>&1 & IRB_W=$!
IRB_K=0; until _irb_mine "$IRB_W" || [ "$IRB_K" -ge 40 ]; do sleep 0.05; IRB_K=$((IRB_K + 1)); done
IRB_X=""; _irb_mine "$IRB_W" || IRB_X=" not found on its probe within 2 s: [$(ps -ww -o command= -p "$IRB_W" 2>&1 | head -c 200)];"
! _irb_mine "$IRB_ME" || IRB_X="$IRB_X found on the suite's shell $IRB_ME;"
{ kill -KILL "$IRB_W"; wait "$IRB_W"; } 2>/dev/null
_irb_ck "$IRB_NM" "${#IRB_X}" "$IRB_X"

# ---------------------------------------------------------------- IR1, IR5 ---
IRB_NS1="$IRB_P IR1: salvage moves the regular files at FROM/XX/* and FROM/pack/* to the same paths in TO, not pack/KEEP.*, nothing else, and overwrites nothing TO holds (control)"
IRB_D="$IRB/salv"; perl -e "$IRB_MK" "$IRB_D" 1 1 1 BD 2>>"$IRB/err"
mkdir -p "$IRB_D/BD/objects/zz" "$IRB_D/BD/objects/abc" "$IRB_D/BD/objects/ab/sub" "$IRB_D/ho/cd"
printf 'zz\n' > "$IRB_D/BD/objects/zz/$IRB_L1"; printf 'abc\n' > "$IRB_D/BD/objects/abc/f"; printf 'sub\n' > "$IRB_D/BD/objects/ab/sub/f"
printf 'theirs\n' > "$IRB_D/ho/cd/$IRB_L2"
_irb_run "$IRB_PLIM" perl -e "$IRB_WD" "$IRB_DEAD" "$IRB_D/BD/objects" "$IRB_D/ho" pack-keep "$IRB_D/BD" "$IRB_D/BD.list"
IRB_X="$(_irb_is "$IRB_D/ho/ab/$IRB_L1" "loose ab"; _irb_is "$IRB_D/ho/cd/$IRB_L2" theirs; _irb_is "$IRB_D/ho/pack/pack-move.pack" "move pack"
  _irb_is "$IRB_D/ho/pack/pack-move.idx" "move idx"; for IRB_F in pack/pack-keep.pack pack/pack-keep.idx info zz abc ab/sub HEAD refs; do _irb_no "$IRB_D/ho/$IRB_F"; done
  _irb_no "$IRB_D/BD"; _irb_no "$IRB_D/BD.list")"
_irb_ck "$IRB_NS1" "$(( ${#IRB_X} + IRB_RC ))" "exit $IRB_RC;$IRB_X"
IRB_NS2="$IRB_P IR1: with KEEP empty, salvage moves pack/KEEP.* too (control)"
IRB_D="$IRB/salv0"; perl -e "$IRB_MK" "$IRB_D" 1 1 1 BD 2>>"$IRB/err"
_irb_run "$IRB_PLIM" perl -e "$IRB_WD" "$IRB_DEAD" "$IRB_D/BD/objects" "$IRB_D/ho" "" "$IRB_D/BD" "$IRB_D/BD.list"
IRB_X="$(_irb_is "$IRB_D/ho/pack/pack-keep.pack" "keep pack"; _irb_is "$IRB_D/ho/pack/pack-keep.idx" "keep idx"; _irb_is "$IRB_D/ho/ab/$IRB_L1" "loose ab"; _irb_no "$IRB_D/BD")"
_irb_ck "$IRB_NS2" "$(( ${#IRB_X} + IRB_RC ))" "exit $IRB_RC;$IRB_X"

IRB_NL="$IRB_P IR1: a symbolic-link PATH is removed as a link, its target and what it holds stay, and an empty PATH is skipped (control)"
IRB_D="$IRB/link"; mkdir -p "$IRB_D/tgt/in"; printf 'kept\n' > "$IRB_D/tgt/in/f"; ln -s "$IRB_D/tgt" "$IRB_D/lnk"
_irb_run "$IRB_PLIM" perl -e "$IRB_WD" "$IRB_DEAD" "" "" "" "$IRB_D/lnk" ""
IRB_X="$(_irb_no "$IRB_D/lnk"; _irb_is "$IRB_D/tgt/in/f" kept)"
[ "$IRB_RC" = 0 ] || IRB_X="$IRB_X exit $IRB_RC;"
_irb_ck "$IRB_NL" "${#IRB_X}" "$IRB_X"

# A watchdog waiting on the part's own shell: four signals it ignores, then USR1.
IRB_NG="$IRB_P IR5: TERM, INT, HUP and QUIT leave a watchdog waiting on a live PARENT alive, and nothing is removed or moved (control)"
IRB_NU="$IRB_P IR5: USR1 ends a watchdog waiting on a live PARENT with status 0 within about a second, moving and removing nothing (control)"
IRB_D="$IRB/sig"; perl -e "$IRB_MK" "$IRB_D" 1 1 1 BD 2>>"$IRB/err"
env IRB_ST="$IRB_D/st" perl -e "$IRB_REC" -e "$IRB_WD" "$IRB_ME" "$IRB_D/BD/objects" "$IRB_D/ho" pack-keep \
  "$IRB_D/J" "$IRB_D/R" "$IRB_D/UP" "$IRB_D/HP" "$IRB_D/BD" "$IRB_D/BD.list" </dev/null >/dev/null 2>>"$IRB/err" &
IRB_W=$!
perl -e "$IRB_RDY" "$IRB_W"; IRB_Y=$?; sleep 0.3
IRB_X2=""   # each signal goes only to a watchdog that still carries this run's mark (rev 5)
for IRB_G in TERM INT HUP QUIT; do
  if _irb_mine "$IRB_W"; then kill -s "$IRB_G" "$IRB_W" 2>/dev/null
  else IRB_X2="$IRB_X2 $IRB_G not sent: pid $IRB_W did not carry this run's mark, left alone;"; _irb_la "sig: $IRB_G not sent to $IRB_W"; fi
  sleep 0.1
done; sleep 0.5
IRB_X="$(_irb_intact "$IRB_D")$IRB_X2"; kill -0 "$IRB_W" 2>/dev/null || IRB_X="$IRB_X it is gone;"
[ "$IRB_Y" = 0 ] || IRB_X="$IRB_X it never led its own process group;"
_irb_ck "$IRB_NG" "${#IRB_X}" "$IRB_X"
IRB_X2=""
if _irb_mine "$IRB_W"; then kill -s USR1 "$IRB_W" 2>/dev/null
else IRB_X2=" USR1 not sent: pid $IRB_W did not carry this run's mark, left alone;"; _irb_la "sig: USR1 not sent to $IRB_W"; fi
IRB_J="$(_irb_jg "$IRB_W" 1.5)"
case "$IRB_J" in alone*) IRB_RC=255; _irb_la "sig: $IRB_W left alone and not waited for" ;; *) { wait "$IRB_W"; } 2>/dev/null; IRB_RC=$? ;; esac
IRB_X="$(_irb_intact "$IRB_D")$IRB_X2"; [ "$IRB_J" = exited ] || IRB_X="$IRB_X 1.5 s after USR1 the waiter said [$IRB_J];"
_irb_ck "$IRB_NU" "$(( ${#IRB_X} + IRB_RC ))" "exit $IRB_RC;$IRB_X"
IRB_RW="$(cat "$IRB_D/st" 2>/dev/null)"; IRB_WW="$IRB_RC"

IRB_NV="$IRB_P IR5: a supervisor whose PARENT lives removes nothing and exits with its unit's status (control)"
IRB_D="$IRB/live"; perl -e "$IRB_MK" "$IRB_D" 1 1 1 "" 2>>"$IRB/err"
_irb_run 10 env IRB_ST="$IRB_D/st" perl -e "$IRB_REC" -e "$IRB_SV" "$IRB_ME" 30 "$IRB_D/log" "$IRB_D/grp" \
  "$IRB_D/J" "$IRB_D/R" "$IRB_D/UP/u1" "$IRB_D/UP" "$IRB_D/HP" sh -c 'exit 7'
IRB_X=""; for IRB_F in J R UP/u1 UP HP keep/file; do [ -e "$IRB_D/$IRB_F" ] || IRB_X="$IRB_X $IRB_F is gone;"; done
[ "$IRB_RC" = 7 ] || IRB_X="$IRB_X exit $IRB_RC, not the unit's 7;"
_irb_ck "$IRB_NV" "${#IRB_X}" "$IRB_X"
IRB_NR="$IRB_P IR6: the exit-status recorder this part puts in front of a program reads what wait reads, 0 for a watchdog ended by USR1 and 7 for a unit (control)"
IRB_X="watchdog: recorder [$IRB_RW] wait [$IRB_WW]; supervisor: recorder [$(cat "$IRB_D/st" 2>/dev/null)] wait [$IRB_RC]"
if [ "$IRB_RW" = 0 ] && [ "$IRB_WW" = 0 ] && [ "$(cat "$IRB_D/st" 2>/dev/null)" = 7 ] && [ "$IRB_RC" = 7 ]; then ok "$IRB_NR"; else bad "$IRB_NR" "$IRB_X"; fi

IRB_NWA="$IRB_P IR5: with no other remover, the watchdog leaves none of its PATHs, removes nothing else and exits 0, in every round (control)"
_irb_rounds wd "$IRB_NA" 0 1
_irb_ck "$IRB_NWA" "$((IRB_CL + IRB_CK + IRB_CS))" "of $IRB_K rounds: $IRB_CL left a PATH:$IRB_DL $IRB_CK removed keep/; $IRB_CS exited other than 0:$IRB_DS"
IRB_NSA="$IRB_P IR5: with no other remover, the supervisor's judge-gone path leaves none of J R U UP HP, removes nothing else and exits 125, in every round (control)"
_irb_rounds sv "$IRB_NA" 0 1
_irb_ck "$IRB_NSA" "$((IRB_CL + IRB_CK + IRB_CS))" "of $IRB_K rounds: $IRB_CL left a PATH:$IRB_DL $IRB_CK removed keep/; $IRB_CS exited other than 125:$IRB_DS"
IRB_NO="$IRB_P IR3: a shell that does not own the bind copy hands the watchdog no BD and no BD.list: both stay, and J R UP HP go (control)"
IRB_R=$((IRB_R + 1)); IRB_D="$IRB/sh.$IRB_R"; _irb_sh "$IRB_D" 0 1 0
if [ "$IRB_LEFT" = "exited felix-objects.irb felix-objects.irb.list" ]; then ok "$IRB_NO"
else bad "$IRB_NO" "after the watchdog: [$IRB_LEFT], want [exited felix-objects.irb felix-objects.irb.list] [$(head -c 200 "$IRB_D/err" 2>/dev/null | tr '\n' ' ')]"; fi
_irb_rm "$IRB_D"

# ------------------------------------------------------------- IR6 arming ---
# The tree's size first: J doubles until one plain removal of it outlasts the window.
while :; do
  IRB_D="$IRB/cal$IRB_A"
  perl -e "$IRB_MK" "$IRB_D" "$IRB_A" 10 10 "" 2>>"$IRB/err" || { IRB_T="no tree"; _irb_rm "$IRB_D"; break; }
  IRB_T="$(perl -e "$IRB_TM" "$IRB_D/J" 2>/dev/null)"; _irb_rm "$IRB_D"
  LC_ALL=C awk -v t="${IRB_T:-0}" 'BEGIN { exit !(t + 0 < 0.3) }' && [ "$IRB_A" -lt 160 ] || break
  IRB_A=$((IRB_A * 2))
done
printf '  note  instrument removers: J is %s directories of 10 directories of 10 files (%s entries); one plain removal of it took %s s\n' \
  "$IRB_A" "$((IRB_A * 111 + 1))" "${IRB_T:-?}"

# IR3's order (rev 2): no rival; the judge looks for BD and BD.list gone while J is there.
IRB_N3O="$IRB_P IR3: with no other remover, a shell KILLed after _felix_instr_watch reaches a moment where BD and BD.list are gone while J, whose removal takes a while, is still there, in every round"
IRB_K=0; IRB_CL=0; IRB_DL=""
while [ "$IRB_K" -lt "$IRB_NO3" ]; do
  IRB_K=$((IRB_K + 1)); IRB_R=$((IRB_R + 1)); IRB_D="$IRB/sh.$IRB_R"
  _irb_sh "$IRB_D" 0 "$IRB_A" 1 1
  IRB_X="$(cat "$IRB_D/see" 2>/dev/null)"
  case "$IRB_X" in "seen=0 "*|"") IRB_CL=$((IRB_CL + 1)) ;; esac
  IRB_DL="$IRB_DL r$IRB_K: [${IRB_X:-nothing looked at}] then [$IRB_LEFT];"
  _irb_rm "$IRB_D"
done
_irb_ck "$IRB_N3O" "$IRB_CL" "BD and BD.list were never seen gone while J was there in $IRB_CL of $IRB_K rounds:$IRB_DL"

IRB_NA6="$IRB_P IR6: two plain File::Path::remove_tree calls in two processes, started together with no eval, collide on this part's tree: one dies in at least one round (arming)"
IRB_AK=0; IRB_ARMED=0; IRB_AO=0; IRB_AM=0; IRB_AD=""
while [ "$IRB_AK" -lt "$IRB_ARM" ]; do
  IRB_AK=$((IRB_AK + 1)); IRB_D="$IRB/arm$IRB_AK"
  if ! perl -e "$IRB_MK" "$IRB_D" "$IRB_A" 10 10 "" 2>>"$IRB/err"; then
    IRB_AM=$((IRB_AM + 1)); IRB_AD="$IRB_AD no-tree"; _irb_rm "$IRB_D"; continue
  fi
  perl -e "$IRB_PL" "$IRB_D/go" "$IRB_D/J" </dev/null >/dev/null 2>"$IRB_D/e1" & IRB_P1=$!
  perl -e "$IRB_PL" "$IRB_D/go" "$IRB_D/J" </dev/null >/dev/null 2>"$IRB_D/e2" & IRB_P2=$!
  sleep 0.2; : > "$IRB_D/go"
  case "$(_irb_jg "$IRB_P1" 30)" in alone*) IRB_S1=alone; _irb_la "arm$IRB_AK: $IRB_P1 left alone" ;; *) { wait "$IRB_P1"; } 2>/dev/null; IRB_S1=$? ;; esac
  case "$(_irb_jg "$IRB_P2" 30)" in alone*) IRB_S2=alone; _irb_la "arm$IRB_AK: $IRB_P2 left alone" ;; *) { wait "$IRB_P2"; } 2>/dev/null; IRB_S2=$? ;; esac
  IRB_Y=0
  for IRB_G in "$IRB_S1:e1" "$IRB_S2:e2"; do
    [ "${IRB_G%%:*}" != 0 ] || continue
    case "$(cat "$IRB_D/${IRB_G#*:}" 2>/dev/null)" in *"aborting."*) IRB_Y=1 ;; *) IRB_AO=$((IRB_AO + 1)) ;; esac
  done
  IRB_AD="$IRB_AD $IRB_S1/$IRB_S2"; [ "$IRB_Y" = 0 ] || { IRB_ARMED=$((IRB_ARMED + 1)); IRB_AD="$IRB_AD(died)"; }
  _irb_rm "$IRB_D"
done
printf '  note  instrument removers: the plain pair died in %s of %s arming rounds, exited non-zero otherwise %s times, and %s trees could not be made (statuses%s)\n' \
  "$IRB_ARMED" "$IRB_ARM" "$IRB_AO" "$IRB_AM" "$IRB_AD"
IRB_N2L="$IRB_P IR2: the watchdog, its PATHs given J R UP HP BD BD.list and another process removing J once PARENT is gone, leaves none of them, in every round"
IRB_N2S="$IRB_P IR2: the watchdog exits 0 in every round of that race"
IRB_N2V="$IRB_P IR2: in that race the salvage still moves BD's objects into TO, a collision neither stops nor undoes it (control)"
IRB_N3L="$IRB_P IR3: a shell running _felix_instr_watch over its own bind copy, KILLed while another process removes J, leaves none of BD, BD.list, J, R, UP and HP within a few seconds, in every round"
IRB_N3V="$IRB_P IR3: in that race BD's loose objects and packs, less pack/KEEP.*, are found in _FELIX_BIND_HOME, in every round (control)"
IRB_N4L="$IRB_P IR4: the supervisor's judge-gone path, another process removing J once the unit's group is gone, leaves none of J R U UP HP, in every round"
IRB_N4S="$IRB_P IR4: the supervisor exits 125 in every round of that race"
IRB_N2K="$IRB_P IR5: in the IR2 race the watchdog removes only its PATHs: keep/ beside them stays, in every round (control)"
IRB_N3K="$IRB_P IR5: in the IR3 race the watchdog removes only its PATHs: keep/ beside them stays, in every round (control)"
IRB_N4K="$IRB_P IR5: in the IR4 race the supervisor removes only its PATHs: keep/ beside them stays, in every round (control)"
if [ "$IRB_AM" -gt 0 ]; then bad "$IRB_NA6" "a tree could not be made in $IRB_AM of $IRB_ARM rounds [$(head -c 200 "$IRB/err" 2>/dev/null | tr '\n' ' ')]"
elif [ "$IRB_ARMED" -gt 0 ]; then ok "$IRB_NA6"
else skip "$IRB_NA6" "the host gave no collision: two plain remove_tree calls died in 0 of $IRB_ARM rounds"; fi
if [ "$IRB_ARMED" -eq 0 ]; then
  IRB_X="the host gave no collision: two plain remove_tree calls died in 0 of $IRB_ARM rounds"
  for IRB_G in "$IRB_N2L" "$IRB_N2S" "$IRB_N2V" "$IRB_N2K" "$IRB_N3L" "$IRB_N3V" "$IRB_N3K" "$IRB_N4L" "$IRB_N4S" "$IRB_N4K"; do
    skip "$IRB_G" "$IRB_X"
  done
else
  # ---------------------------------------------------------------- IR2 ---
  _irb_rounds wd "$IRB_N" 1 "$IRB_A"; _irb_note IR2
  _irb_rc "$IRB_N2L" "$IRB_CL" "a PATH was left in $IRB_CL of $IRB_K rounds:$IRB_DL"
  _irb_rc "$IRB_N2S" "$IRB_CS" "the watchdog exited other than 0 in $IRB_CS of $IRB_K rounds:$IRB_DS"
  _irb_rc "$IRB_N2V" "$IRB_CV" "the salvage was wrong in $IRB_CV of $IRB_K rounds:$IRB_DV"
  _irb_rc "$IRB_N2K" "$IRB_CK" "keep/ was removed in $IRB_CK of $IRB_K rounds:$IRB_DK"
  # ---------------------------------------------------------------- IR3 ---
  _irb_rounds sh "$IRB_N3" 1 "$IRB_A"; _irb_note IR3
  _irb_rc "$IRB_N3L" "$IRB_CL" "a path was left in $IRB_CL of $IRB_K rounds:$IRB_DL"
  _irb_rc "$IRB_N3V" "$IRB_CV" "the salvage was wrong in $IRB_CV of $IRB_K rounds:$IRB_DV"
  _irb_rc "$IRB_N3K" "$IRB_CK" "keep/ was removed in $IRB_CK of $IRB_K rounds:$IRB_DK"
  # ---------------------------------------------------------------- IR4 ---
  _irb_rounds sv "$IRB_N" 1 "$IRB_A"; _irb_note IR4
  _irb_rc "$IRB_N4L" "$IRB_CL" "a path was left in $IRB_CL of $IRB_K rounds:$IRB_DL"
  _irb_rc "$IRB_N4S" "$IRB_CS" "the supervisor exited other than 125 in $IRB_CS of $IRB_K rounds:$IRB_DS"
  _irb_rc "$IRB_N4K" "$IRB_CK" "keep/ was removed in $IRB_CK of $IRB_K rounds:$IRB_DK"
fi
# ------------------------------------------- rev 3: a worker under J past the attempts ---
_irb_work wd "$IRB_P IR2: the watchdog, another process removing and making again what is under J for about 4 s after it starts removing and then stopping with J still there, leaves none of its PATHs, in every round"
_irb_work sv "$IRB_P IR4: the supervisor's judge-gone path, another process removing and making again what is under J for about 4 s after the unit's group is gone and then stopping with J still there, leaves none of J R U UP HP, in every round"

[ -z "$IRB_LA" ] || printf '  note  instrument removers: left alone, not carrying the mark of this run (rev 5):%s\n' "$IRB_LA"
chmod 0700 "$IRB"/*/UP 2>/dev/null; rm -rf "${IRB:?}"
unset -f _irb_wait _irb_rm _irb_run _irb_is _irb_no _irb_salv _irb_intact _irb_go _irb_wd _irb_sv _irb_sh _irb_rounds _irb_ck \
         _irb_rc _irb_note _irb_work _irb_mine _irb_jg _irb_la
unset IRB IRB_P IRB_LIB IRB_WD IRB_SV IRB_ME IRB_N IRB_N3 IRB_NA IRB_ARM IRB_R IRB_A IRB_L1 IRB_L2 IRB_DEAD IRB_REC IRB_MK \
      IRB_RV IRB_JG IRB_RDY IRB_PL IRB_TM IRB_RC IRB_LEFT IRB_S IRB_WP IRB_K IRB_CL IRB_DL IRB_CK IRB_CS IRB_DS IRB_CV IRB_DV \
      IRB_X IRB_W IRB_Y IRB_G IRB_J IRB_RW IRB_WW IRB_T IRB_AK IRB_ARMED IRB_AD IRB_P1 IRB_P2 IRB_S1 IRB_S2 \
      IRB_NS1 IRB_NS2 IRB_NL IRB_NG IRB_NU IRB_NV IRB_NR IRB_NWA IRB_NSA IRB_NO IRB_NA6 IRB_N2L IRB_N2S IRB_N2V IRB_N3L \
      IRB_N3V IRB_N4L IRB_N4S IRB_D IRB_F IRB_NO3 IRB_SEE IRB_RVD IRB_DK IRB_CR IRB_CO IRB_AO IRB_AM IRB_N3O IRB_N2K IRB_N3K \
      IRB_N4K IRB_PLIM IRB_NW IRB_WS IRB_WORK IRB_NWX IRB_LA IRB_HD IRB_NM IRB_X2
# <<< instrument-removers
