# >>> instrument-removers
printf '\n%s\n' "the judge's removers each finish, whatever the other is doing: the watchdog, the shell that starts it, the supervisor (contract 2026-11-17, IR1 to IR6, blind)"
# Blind, written on 2026-11-17 from docs/2026-11-17-instrument-removers-contract.md (rev 1, IR1 to IR6) alone, by an author
# who has not read lib/instrument-run.sh, lib/instrument.sh, lib/bind.sh or lib/merge-judge.sh. The programs are taken from
# the fixture engine's lib/instrument-run.sh, _felix_instr_wdpl (the watchdog) and _felix_instr_pl (the supervisor), and run
# as perl -e PROGRAM ARGS; _felix_instr_watch is run in a shell that sources that file. A name ending (control) holds on the
# engine the contract was cut from, on purpose; the others are the new behaviour. Every tree is under $TMP/irb.
#
# Readings, where the contract leaves room:
# - PARENT, in the IR2 and IR4 rounds, is a bash subshell that starts the program as its own child, passing its own pid (read
#   through /bin/sh's $PPID, since bash 3.2 has no BASHPID), then execs sleep; the part KILLs and reaps it. A KILLed parent
#   cannot report its orphan's status, so the status is read by a recorder the part puts in front of the program,
#   perl -e RECORDER -e PROGRAM ARGS: an END block, in the program's own process and for that pid only, that writes $? to
#   the file IRB_ST names. Its BEGIN also sets INT and QUIT back to default, which bash ignores in a background job, so what
#   the program does with them is its own. IR6's recorder control arms it against wait, on a watchdog and on a supervisor.
# - "Left" is read by lstat at once after the program is gone (polled every 0.02 s), before the rival is waited for. A
#   program still running 10 s after its PARENT was KILLed (6 s in IR3, "within a few seconds") is KILLed by exact pid and its
#   round counted as left, "timeout". A round's tree also holds keep/, beside the PATHs, for "removes only its PATHs".
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
IRB="$TMP/irb"; rm -rf "${IRB:?}"; mkdir -p "$IRB"; IRB="$(cd "$IRB" && pwd -P)"; IRB_P="instrument removers:"
IRB_LIB="$FROOT/harness/lib/instrument-run.sh"
IRB_WD="$( set +u; . "$IRB_LIB" >/dev/null 2>&1; printf '%s' "${_felix_instr_wdpl-}" )"
IRB_SV="$( set +u; . "$IRB_LIB" >/dev/null 2>&1; printf '%s' "${_felix_instr_pl-}" )"
IRB_ME="$(exec /bin/sh -c 'echo "$PPID"')"
IRB_N=20; IRB_N3=20; IRB_NA=5; IRB_ARM=5; IRB_R=0; IRB_A=20
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
IRB_RV='use strict; use warnings; use File::Path qw(remove_tree); use Time::HiRes qw(sleep time);
my ($mode, $who, $pf, $gf, $ready, $path) = @ARGV;
sub num { open(my $h, "<", $_[0]) or return 0; my $l = <$h>; return (defined $l and $l =~ /(\d+)/) ? $1 : 0 }
my $t = time; my ($p, $g) = (0, 0);
until ($p = num($pf)) { exit 3 if time - $t > 10; sleep 0.01 }
if ($mode eq "grp") { until ($g = num($gf)) { exit 3 if time - $t > 10; sleep 0.01 } }
else { until (getpgrp($p) == $p) { last if time - $t > 10; sleep 0.01 } }
open(my $r, ">", "$ready.t") or exit 3; print {$r} "1\n"; close $r; rename("$ready.t", $ready) or exit 3;
$t = time;
while (time - $t < 15) { last unless kill(0, $mode eq "grp" ? -$g : $who); sleep 0.05 }
remove_tree($path) if length $path;
exit 0;'
# PID TIMEOUT PATH...: waits until PID is gone (KILLs it after TIMEOUT s), then prints how and the last name of each PATH left.
IRB_JG='use strict; use warnings; use Time::HiRes qw(sleep time);
my ($p, $to, @paths) = @ARGV; my $t = time; my $how = "exited";
if (defined $p and $p =~ /^\d+$/ and $p > 1) {
  while (kill 0, $p) { if (time - $t > $to) { kill "KILL", $p; $how = "timeout"; sleep 0.3; last } sleep 0.02 }
} else { $how = "nopid" }
my @left; for (@paths) { push @left, (split m{/}, $_)[-1] if length($_) and lstat($_) }
print join(" ", $how, @left), "\n";'
# PID: 0 once PID leads its own process group, 1 after 5 s.
IRB_RDY='use Time::HiRes qw(sleep time); my $t = time;
until (getpgrp($ARGV[0]) == $ARGV[0]) { exit 1 if time - $t > 5; sleep 0.02 } exit 0;'
# GO TREE: waits for GO, then one plain remove_tree of TREE, no eval (IR6 arming).
IRB_PL='use File::Path qw(remove_tree); use Time::HiRes qw(sleep); sleep 0.002 until -e $ARGV[0]; remove_tree($ARGV[1]);'
# TREE: one plain remove_tree of TREE, and the seconds it took.
IRB_TM='use File::Path qw(remove_tree); use Time::HiRes qw(time); my $t = time; remove_tree($ARGV[0]); printf "%.3f\n", time - $t;'

# ------------------------------------------------------------------- helpers ---
_irb_wait() { local n=0; while [ ! -s "$1" ]; do [ "$n" -lt $(($2 * 5)) ] || return 1; sleep 0.02; n=$((n + 1)); done; }   # FILE TENTHS
_irb_rm() { chmod 0700 "$1/UP" 2>/dev/null; rm -rf "${1:?}"; }   # DIR: a round's tree, gone
_irb_run() {   # TIMEOUT CMD...: CMD in the background, KILLed after TIMEOUT s -> IRB_RC its status
  local t="$1" p; shift
  "$@" </dev/null >/dev/null 2>>"$IRB/err" & p=$!
  perl -e "$IRB_JG" "$p" "$t" >/dev/null
  { wait "$p"; } 2>/dev/null; IRB_RC=$?
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
# group (MODE grp) is gone; PARENT is KILLed once the program is ready. -> IRB_LEFT, IRB_S, IRB_WP (the program's pid)
_irb_go() {
  local d="$1" pp="$2" m="$3" tg="$4" to="$5" rv; shift 5
  perl -e "$IRB_RV" "$m" "$pp" "$d/pid" "$d/grp" "$d/ready" "$tg" </dev/null >/dev/null 2>>"$d/rv.err" &
  rv=$!
  _irb_wait "$d/ready" 100 || :
  { kill -KILL "$pp"; wait "$pp"; } 2>/dev/null
  IRB_WP="$(LC_ALL=C sed -n '1s/[^0-9]//gp' "$d/pid" 2>/dev/null)"
  IRB_LEFT="$(perl -e "$IRB_JG" "${IRB_WP:-x}" "$to" "$@")"
  { wait "$rv"; } 2>/dev/null
  IRB_S="$(cat "$d/st" 2>/dev/null)"; IRB_S="${IRB_S:-none}"
}
_irb_wd() {   # DIR RACE A: a watchdog round; RACE 1 adds the rival on J. PATHs in today's order, the bind copy last.
  local d="$1" pp tg=""
  [ "$2" != 1 ] || tg="$d/J"
  perl -e "$IRB_MK" "$d" "$3" 10 10 BD 2>>"$IRB/err" || { IRB_LEFT="no tree"; IRB_S=none; IRB_WP=""; return 0; }
  ( p="$(exec /bin/sh -c 'echo "$PPID"')"
    IRB_ST="$d/st" perl -e "$IRB_REC" -e "$IRB_WD" "$p" "$d/BD/objects" "$d/ho" pack-keep \
      "$d/J" "$d/R" "$d/UP" "$d/HP" "$d/BD" "$d/BD.list" </dev/null >/dev/null 2>>"$d/err" &
    printf '%s\n' "$!" > "$d/pid"
    exec sleep 60 ) &
  pp=$!
  _irb_go "$d" "$pp" pid "$tg" 10 "$d/J" "$d/R" "$d/UP" "$d/HP" "$d/BD" "$d/BD.list"
}
_irb_sv() {   # DIR RACE A: a supervisor round, COMMAND a long sleep; RACE 1 adds the rival on J
  local d="$1" pp tg="" g
  [ "$2" != 1 ] || tg="$d/J"
  perl -e "$IRB_MK" "$d" "$3" 10 10 "" 2>>"$IRB/err" || { IRB_LEFT="no tree"; IRB_S=none; IRB_WP=""; return 0; }
  ( p="$(exec /bin/sh -c 'echo "$PPID"')"
    IRB_ST="$d/st" perl -e "$IRB_REC" -e "$IRB_SV" "$p" 60 "$d/log" "$d/grp" \
      "$d/J" "$d/R" "$d/UP/u1" "$d/UP" "$d/HP" sleep 60 </dev/null >/dev/null 2>>"$d/err" &
    printf '%s\n' "$!" > "$d/pid"
    exec sleep 60 ) &
  pp=$!
  _irb_go "$d" "$pp" grp "$tg" 10 "$d/J" "$d/R" "$d/UP/u1" "$d/UP" "$d/HP"
  g="$(LC_ALL=C sed -n '1s/[^0-9]//gp' "$d/grp" 2>/dev/null)"
  [ -z "$g" ] || ! kill -0 -- "-$g" 2>/dev/null || kill -KILL -- "-$g" 2>/dev/null
}
_irb_sh() {   # DIR RACE A OWN: a shell sources the lib, runs _felix_instr_watch over DIR and execs sleep; OWN 1 owns BD
  local d="$1" pp tg=""
  [ "$2" != 1 ] || tg="$d/J"
  perl -e "$IRB_MK" "$d" "$3" 10 10 felix-objects.irb 2>>"$IRB/err" || { IRB_LEFT="no tree"; IRB_S=none; IRB_WP=""; return 0; }
  "$BASH" -c '
    . "$1" || exit 3
    d="$2"; _FELIX_INSTR_J="$d/J"; _FELIX_INSTR_R="$d/R"; _FELIX_INSTR_UP="$d/UP"; _FELIX_INSTR_HP="$d/HP"
    _FELIX_INSTR_OWNER=$$; _FELIX_BIND_DIR="$d/felix-objects.irb"; _FELIX_BIND_OWNER=$$
    [ "$3" = 1 ] || _FELIX_BIND_OWNER=1
    _FELIX_BIND_HOME="$d/ho"; _FELIX_BIND_PACK=pack-keep
    _felix_instr_watch
    printf "%s\n" "${_FELIX_INSTR_WD-}" > "$d/pid"
    exec sleep 60' irb-shell "$IRB_LIB" "$d" "$4" </dev/null >/dev/null 2>>"$d/err" &
  pp=$!
  _irb_go "$d" "$pp" pid "$tg" 6 "$d/felix-objects.irb" "$d/felix-objects.irb.list" "$d/J" "$d/R" "$d/UP" "$d/HP"
}
# KIND N RACE A: N rounds of _irb_KIND -> IRB_K rounds run; IRB_CL rounds with a PATH left (IRB_DL), IRB_CK rounds with
# keep/ gone, IRB_CS rounds whose status is not KIND's (IRB_DS; sh's is not read), IRB_CV rounds whose salvage is wrong (IRB_DV)
_irb_rounds() {
  local kind="$1" n="$2" k=0 d w want=0
  IRB_CL=0; IRB_DL=""; IRB_CK=0; IRB_CS=0; IRB_DS=""; IRB_CV=0; IRB_DV=""
  [ "$kind" != sv ] || want=125
  while [ "$k" -lt "$n" ]; do
    k=$((k + 1)); IRB_R=$((IRB_R + 1)); d="$IRB/$kind.$IRB_R"
    "_irb_$kind" "$d" "$3" "$4" 1
    if [ "$IRB_LEFT" != exited ]; then
      IRB_CL=$((IRB_CL + 1)); IRB_DL="$IRB_DL r$k: $IRB_LEFT;"
      [ -n "$IRB_WP" ] || IRB_DL="$IRB_DL [$(head -c 200 "$d/err" 2>/dev/null | tr '\n' ' ')]"
    fi
    [ -e "$d/keep/file" ] || IRB_CK=$((IRB_CK + 1))
    [ "$kind" = sh ] || [ "$IRB_S" = "$want" ] || { IRB_CS=$((IRB_CS + 1)); IRB_DS="$IRB_DS r$k: $IRB_S;"; }
    if [ "$kind" != sv ]; then w="$(_irb_salv "$d")"; [ -z "$w" ] || { IRB_CV=$((IRB_CV + 1)); IRB_DV="$IRB_DV r$k:$w"; }; fi
    _irb_rm "$d"
    [ "$kind" != sh ] || [ -n "$IRB_WP" ] || break   # no watchdog was started: each later round would wait out the rival
  done
  IRB_K=$k
}
_irb_ck() { if [ "$2" -eq 0 ]; then ok "$1"; else bad "$1" "$3"; fi; }   # NAME COUNT DETAIL

# ---------------------------------------------------------------- IR1, IR5 ---
IRB_NS1="$IRB_P IR1: salvage moves the regular files at FROM/XX/* and FROM/pack/* to the same paths in TO, not pack/KEEP.*, nothing else, and overwrites nothing TO holds (control)"
IRB_D="$IRB/salv"; perl -e "$IRB_MK" "$IRB_D" 1 1 1 BD 2>>"$IRB/err"
mkdir -p "$IRB_D/BD/objects/zz" "$IRB_D/BD/objects/abc" "$IRB_D/BD/objects/ab/sub" "$IRB_D/ho/cd"
printf 'zz\n' > "$IRB_D/BD/objects/zz/$IRB_L1"; printf 'abc\n' > "$IRB_D/BD/objects/abc/f"; printf 'sub\n' > "$IRB_D/BD/objects/ab/sub/f"
printf 'theirs\n' > "$IRB_D/ho/cd/$IRB_L2"
_irb_run 10 perl -e "$IRB_WD" "$IRB_DEAD" "$IRB_D/BD/objects" "$IRB_D/ho" pack-keep "$IRB_D/BD" "$IRB_D/BD.list"
IRB_X="$(_irb_is "$IRB_D/ho/ab/$IRB_L1" "loose ab"; _irb_is "$IRB_D/ho/cd/$IRB_L2" theirs; _irb_is "$IRB_D/ho/pack/pack-move.pack" "move pack"
  _irb_is "$IRB_D/ho/pack/pack-move.idx" "move idx"; for IRB_F in pack/pack-keep.pack pack/pack-keep.idx info zz abc ab/sub HEAD refs; do _irb_no "$IRB_D/ho/$IRB_F"; done
  _irb_no "$IRB_D/BD"; _irb_no "$IRB_D/BD.list")"
_irb_ck "$IRB_NS1" "$(( ${#IRB_X} + IRB_RC ))" "exit $IRB_RC;$IRB_X"
IRB_NS2="$IRB_P IR1: with KEEP empty, salvage moves pack/KEEP.* too (control)"
IRB_D="$IRB/salv0"; perl -e "$IRB_MK" "$IRB_D" 1 1 1 BD 2>>"$IRB/err"
_irb_run 10 perl -e "$IRB_WD" "$IRB_DEAD" "$IRB_D/BD/objects" "$IRB_D/ho" "" "$IRB_D/BD" "$IRB_D/BD.list"
IRB_X="$(_irb_is "$IRB_D/ho/pack/pack-keep.pack" "keep pack"; _irb_is "$IRB_D/ho/pack/pack-keep.idx" "keep idx"; _irb_is "$IRB_D/ho/ab/$IRB_L1" "loose ab"; _irb_no "$IRB_D/BD")"
_irb_ck "$IRB_NS2" "$(( ${#IRB_X} + IRB_RC ))" "exit $IRB_RC;$IRB_X"

IRB_NL="$IRB_P IR1: a symbolic-link PATH is removed as a link, its target and what it holds stay, and an empty PATH is skipped (control)"
IRB_D="$IRB/link"; mkdir -p "$IRB_D/tgt/in"; printf 'kept\n' > "$IRB_D/tgt/in/f"; ln -s "$IRB_D/tgt" "$IRB_D/lnk"
_irb_run 10 perl -e "$IRB_WD" "$IRB_DEAD" "" "" "" "$IRB_D/lnk" ""
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
for IRB_G in TERM INT HUP QUIT; do kill -s "$IRB_G" "$IRB_W" 2>/dev/null; sleep 0.1; done; sleep 0.5
IRB_X="$(_irb_intact "$IRB_D")"; kill -0 "$IRB_W" 2>/dev/null || IRB_X="$IRB_X it is gone;"
[ "$IRB_Y" = 0 ] || IRB_X="$IRB_X it never led its own process group;"
_irb_ck "$IRB_NG" "${#IRB_X}" "$IRB_X"
kill -s USR1 "$IRB_W" 2>/dev/null
IRB_J="$(perl -e "$IRB_JG" "$IRB_W" 1.5)"; { wait "$IRB_W"; } 2>/dev/null; IRB_RC=$?
IRB_X="$(_irb_intact "$IRB_D")"; [ "$IRB_J" = exited ] || IRB_X="$IRB_X still running 1.5 s after USR1;"
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
  IRB_D="$IRB/cal$IRB_A"; perl -e "$IRB_MK" "$IRB_D" "$IRB_A" 10 10 "" 2>>"$IRB/err"
  IRB_T="$(perl -e "$IRB_TM" "$IRB_D/J" 2>/dev/null)"; _irb_rm "$IRB_D"
  LC_ALL=C awk -v t="${IRB_T:-0}" 'BEGIN { exit !(t + 0 < 0.3) }' && [ "$IRB_A" -lt 160 ] || break
  IRB_A=$((IRB_A * 2))
done
printf '  note  instrument removers: J is %s directories of 10 directories of 10 files (%s entries); one plain removal of it took %s s\n' \
  "$IRB_A" "$((IRB_A * 111 + 1))" "${IRB_T:-?}"
IRB_NA6="$IRB_P IR6: two plain File::Path::remove_tree calls in two processes, started together with no eval, collide on this part's tree: one dies in at least one round (arming)"
IRB_AK=0; IRB_ARMED=0; IRB_AD=""
while [ "$IRB_AK" -lt "$IRB_ARM" ]; do
  IRB_AK=$((IRB_AK + 1)); IRB_D="$IRB/arm$IRB_AK"; perl -e "$IRB_MK" "$IRB_D" "$IRB_A" 10 10 "" 2>>"$IRB/err"
  perl -e "$IRB_PL" "$IRB_D/go" "$IRB_D/J" </dev/null >/dev/null 2>&1 & IRB_P1=$!
  perl -e "$IRB_PL" "$IRB_D/go" "$IRB_D/J" </dev/null >/dev/null 2>&1 & IRB_P2=$!
  sleep 0.2; : > "$IRB_D/go"
  { wait "$IRB_P1"; } 2>/dev/null; IRB_S1=$?; { wait "$IRB_P2"; } 2>/dev/null; IRB_S2=$?
  IRB_AD="$IRB_AD $IRB_S1/$IRB_S2"
  [ "$IRB_S1" = 0 ] && [ "$IRB_S2" = 0 ] || IRB_ARMED=$((IRB_ARMED + 1))
  _irb_rm "$IRB_D"
done
printf '  note  instrument removers: the plain pair died in %s of %s arming rounds (statuses%s)\n' "$IRB_ARMED" "$IRB_ARM" "$IRB_AD"
IRB_N2L="$IRB_P IR2: the watchdog, its PATHs given J R UP HP BD BD.list and another process removing J once PARENT is gone, leaves none of them, in every round"
IRB_N2S="$IRB_P IR2: the watchdog exits 0 in every round of that race"
IRB_N2V="$IRB_P IR2: in that race the salvage still moves BD's objects into TO, a collision neither stops nor undoes it (control)"
IRB_N3L="$IRB_P IR3: a shell running _felix_instr_watch over its own bind copy, KILLed while another process removes J, leaves none of BD, BD.list, J, R, UP and HP within a few seconds, in every round"
IRB_N3V="$IRB_P IR3: in that race BD's loose objects and packs, less pack/KEEP.*, are found in _FELIX_BIND_HOME, in every round (control)"
IRB_N4L="$IRB_P IR4: the supervisor's judge-gone path, another process removing J once the unit's group is gone, leaves none of J R U UP HP, in every round"
IRB_N4S="$IRB_P IR4: the supervisor exits 125 in every round of that race"
if [ "$IRB_ARMED" -eq 0 ]; then
  IRB_X="the host gave no collision: two plain remove_tree calls died in 0 of $IRB_ARM rounds"
  for IRB_G in "$IRB_NA6" "$IRB_N2L" "$IRB_N2S" "$IRB_N2V" "$IRB_N3L" "$IRB_N3V" "$IRB_N4L" "$IRB_N4S"; do skip "$IRB_G" "$IRB_X"; done
else
  ok "$IRB_NA6"
  # ---------------------------------------------------------------- IR2 ---
  _irb_rounds wd "$IRB_N" 1 "$IRB_A"
  _irb_ck "$IRB_N2L" "$IRB_CL" "a PATH was left in $IRB_CL of $IRB_K rounds:$IRB_DL"
  _irb_ck "$IRB_N2S" "$IRB_CS" "the watchdog exited other than 0 in $IRB_CS of $IRB_K rounds:$IRB_DS"
  _irb_ck "$IRB_N2V" "$IRB_CV" "the salvage was wrong in $IRB_CV of $IRB_K rounds:$IRB_DV"
  # ---------------------------------------------------------------- IR3 ---
  _irb_rounds sh "$IRB_N3" 1 "$IRB_A"
  _irb_ck "$IRB_N3L" "$IRB_CL" "a path was left in $IRB_CL of $IRB_K rounds:$IRB_DL"
  _irb_ck "$IRB_N3V" "$IRB_CV" "the salvage was wrong in $IRB_CV of $IRB_K rounds:$IRB_DV"
  # ---------------------------------------------------------------- IR4 ---
  _irb_rounds sv "$IRB_N" 1 "$IRB_A"
  _irb_ck "$IRB_N4L" "$IRB_CL" "a path was left in $IRB_CL of $IRB_K rounds:$IRB_DL"
  _irb_ck "$IRB_N4S" "$IRB_CS" "the supervisor exited other than 125 in $IRB_CS of $IRB_K rounds:$IRB_DS"
fi

chmod 0700 "$IRB"/*/UP 2>/dev/null; rm -rf "${IRB:?}"
unset -f _irb_wait _irb_rm _irb_run _irb_is _irb_no _irb_salv _irb_intact _irb_go _irb_wd _irb_sv _irb_sh _irb_rounds _irb_ck
unset IRB IRB_P IRB_LIB IRB_WD IRB_SV IRB_ME IRB_N IRB_N3 IRB_NA IRB_ARM IRB_R IRB_A IRB_L1 IRB_L2 IRB_DEAD IRB_REC IRB_MK \
      IRB_RV IRB_JG IRB_RDY IRB_PL IRB_TM IRB_RC IRB_LEFT IRB_S IRB_WP IRB_K IRB_CL IRB_DL IRB_CK IRB_CS IRB_DS IRB_CV IRB_DV \
      IRB_X IRB_W IRB_Y IRB_G IRB_J IRB_RW IRB_WW IRB_T IRB_AK IRB_ARMED IRB_AD IRB_P1 IRB_P2 IRB_S1 IRB_S2 \
      IRB_NS1 IRB_NS2 IRB_NL IRB_NG IRB_NU IRB_NV IRB_NR IRB_NWA IRB_NSA IRB_NO IRB_NA6 IRB_N2L IRB_N2S IRB_N2V IRB_N3L \
      IRB_N3V IRB_N4L IRB_N4S IRB_D IRB_F
# <<< instrument-removers
