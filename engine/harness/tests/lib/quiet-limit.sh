# tests/lib/quiet-limit.sh: the quiet limit of a run (audit b01, C004;
# docs/2026-10-24-audit-fixes/b01-time-limits-on-suite-gate-ci-and-probe-c.md, B1 to B10). Definitions only.
#
# A suite that hangs on a FIFO, on a wait for a child that never ends, or on a credential prompt used to
# hang for ever: no layer had a time limit, and the gate printed nothing until it ended. The rule here is
# a quiet limit, not a wall deadline: when the run's ran file (one line for each ok, FAIL or skip, in any
# subshell) grows by no byte for Q seconds (FELIX_TEST_QUIET_LIMIT, 1800 when unset), the run is ended and
# says which assertion it reached last. A wall deadline taken from the durations file would end healthy
# units on a loaded Mac (part 0010 took 136 s alone and 1377 s loaded), and does nothing for the serial run
# CI makes.
#
# _ql_go starts the watchdog, one perl, in the driver once tests/lib is loaded, in a serial run and in part
# mode (a unit, or a part by hand), not in a -j N parent, which sources no part, and not in a driver copy
# with no tests/lib, which does not define it. _ql_end stops it before part 9990 (serial) or before part
# mode's ending. The watchdog is started in a subshell that ends at once, so it is no job of the run's
# shell: a part's `jobs -p` does not list it and its bare `wait` does not wait for it, the shell snapshot of
# part mode sees no job, no descriptor and no variable of it, and the tree walk below does not meet it. It
# stays in the run's process group, so a group that is stopped stops it as well. Time is counted in polls a
# second apart, not read from a clock, so a stretch in which the group is frozen (a Mac asleep, SIGSTOP)
# counts as one poll at most.
#
# When the limit is reached the watchdog does this, in order:
#   - prints, on the run's stdout, a newline and the line `  FAIL  no new assertion in Q s, so the run was
#     ended; the last it reached: NAME` (the ran file's last line, `none` for an empty file), so the gate's
#     FAIL lines name the stall; tests/red leaves this prefix out of its counts, as it does the runner's;
#   - records the processes below the run's shell, and gives the shell TERM first, so that its EXIT trap
#     runs and its $TMP goes. The shell is not stopped and its children are not ended before it: a shell
#     that is blocked on a child ends on TERM at once, and one whose children are ended first goes on to
#     print the next assertion. If it is still there 10 s later by the clock (a part left TERM ignored; ps may be
#     slow, and the wait does not stretch with it) a note names its $TMP, which is left, and it is sent KILL;
#   - ends what was below it: TERM, a second to go, then STOP and KILL while a listing still adds members.
#     In a record run that is red's tree as well. A process that left the tree (setsid, a double fork) is
#     found by neither this nor the process group; nothing here claims it.
# The run exits on the signal, so neither 0 nor 2, and no `reached` line, receipt or record follows.
#
# If perl does not run, or does not come up in 3 s, the run goes on with no limit and says so on one stderr
# line beginning `tests/run: this run has no quiet limit: `.
_ql_go() {
  local q="${FELIX_TEST_QUIET_LIMIT:-1800}" up="$TMP/ql.up" why="" rc i=0 pl
  _ql_pid=""; _ql_st=""
  rm -f "$up" "$up.t"
  perl -e 'exit 0' >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 0 ] || why="perl exited $rc when asked to run"
  pl='my ($f, $q, $sh, $tmp, $up) = @ARGV;
use Time::HiRes qw(time);
$| = 1; $SIG{PIPE} = "IGNORE"; chdir("/");
sub lst { my $o = `ps -o stat= -o lstart= -p $_[0] 2>/dev/null`; $o =~ s/^\s+|\s+$//g; return "" if $o eq "" or $o =~ /^Z/; $o =~ s/^\S+\s+//; $o }
sub nap { select(undef, undef, undef, $_[0]) }
my $s0 = lst($sh); exit 0 if $s0 eq "";
my $me = lst($$);
my $h; open($h, ">", "$up.t") and print({$h} "$$\n$me\n") and close($h) and rename("$up.t", $up) or exit 3;
sub alive { kill(0, $sh) and lst($sh) eq $s0 }
my (%M, @P);
sub grow {   # the members below the shell (a pid and its start time) and the ones present in this listing
  my (%R, %K, @l, @qu, %v, $a);
  for (1 .. 5) { @l = `ps -A -o pid= -o ppid= -o lstart= 2>/dev/null`; last if @l; nap(0.2) }
  return 0 unless @l;
  for (@l) { next unless /^\s*(\d+)\s+(\d+)\s+(.*?)\s*$/; $R{$1} = $3; push @{ $K{$2} }, $1 }
  push @qu, $sh if exists $R{$sh} and $R{$sh} eq $s0;
  for my $p (keys %M) { push @qu, $p if exists $R{$p} and $R{$p} eq $M{$p} and !$v{$p}++ }
  for (my $i = 0; $i < @qu; $i++) {
    for my $c (@{ $K{$qu[$i]} || [] }) {
      next if $c == $$ or $v{$c}++;
      $M{$c} = $R{$c}, $a++ unless exists $M{$c} and $M{$c} eq $R{$c};
      push @qu, $c;
    }
  }
  @P = grep { $_ != $sh } @qu;
  $a || 0
}
sub last_name {
  open(my $g, "<", $f) or return "none";
  my $z = -s $g; return "none" unless $z;
  my $b = $z > 65536 ? 65536 : $z; seek($g, -$b, 2); local $/; my $t = <$g>; close($g);
  $t =~ s/\n\z//; my $i = rindex($t, "\n"); $t = substr($t, $i + 1) if $i >= 0; $t
}
sub gone {   # 1 when the shell is gone within $_[0] s of the clock (a listing is read twice a second at most, however slow ps is)
  my ($e, $i) = (time + $_[0], 0);
  while (1) {
    return 1 unless kill(0, $sh);
    return 1 if $i++ % 4 == 3 and !alive();
    return 0 if time >= $e;
    nap(0.1);
  }
}
sub sweep {   # TERM to what was below the shell, a second to go, then STOP while a listing adds members, and KILL
  grow(); kill TERM => @P;
  for (my $e = time + 1; time < $e; ) { nap(0.1); grow(); last unless @P }
  my @S;
  for (my ($i, $e) = (0, time + 5); $i < 20; $i++) { my $a = grow(); kill STOP => @P, @S; push @S, @P; last if !$a or time >= $e }
  kill KILL => @P, @S; grow(); kill KILL => @P, @S;
}
my ($last, $n, $k, $t) = ((-s $f) || 0, 0, 0, 0);
while (1) {
  nap(0.05);   # the shell is looked for twenty times a second, so that this is gone a moment after it is; a poll is twenty naps
  exit 0 unless kill(0, $sh);
  next if ++$t < 20;
  $t = 0; $k++;
  exit 0 if $k % 2 == 0 and lst($sh) ne $s0;
  my $s = (-s $f) || 0;
  if ($s != $last) { ($last, $n) = ($s, 0); next }
  next if ++$n < $q;
  my $name = last_name();
  grow();
  if (open(my $m, ">", "$tmp/ql.fired")) { close $m }   # tells the shell that the end is the watchdog itself, so that its exit trap leaves the sweep to it
  print "\n  FAIL  no new assertion in $q s, so the run was ended; the last it reached: $name\n";
  kill TERM => $sh;
  if (!gone(10) and alive()) {
    print "  note  the run\x27s shell did not end on TERM and was killed; its temporary directory is left: $tmp\n";
    kill KILL => $sh;
    gone(2);
  }
  sweep();
  exit 0;
}'
  if [ -z "$why" ]; then
    ( perl -e "$pl" -- "$FELIX_TEST_RAN" "$q" "$$" "$TMP" "$up" </dev/null & )
    while [ ! -s "$up" ] && [ "$i" -lt 60 ]; do sleep 0.05; i=$((i + 1)); done
    { read -r _ql_pid; read -r _ql_st; } 2>/dev/null < "$up" || _ql_pid=""
    case "$_ql_pid" in ""|*[!0123456789]*) why="the watchdog did not report within 3 s"; _ql_pid="" ;; esac
  fi
  rm -f "$up" "$up.t"
  [ -z "$why" ] || printf 'tests/run: this run has no quiet limit: %s\n' "$why" >&2
  return 0
}
# Stops the watchdog, and waits until it is gone (3 s at most), so that the run's group holds nothing of it
# when the run ends. The start time it reported is checked first: a pid is not a process.
_ql_end() {
  local i=0 s
  [ -n "${_ql_pid:-}" ] || return 0
  [ ! -e "$TMP/ql.fired" ] || return 0   # the watchdog ended this run: it is still sweeping, and the shell must not take it away
  s="$(ps -o lstart= -p "$_ql_pid" 2>/dev/null)"; s="${s#"${s%%[! ]*}"}"; s="${s%"${s##*[! ]}"}"
  if [ "$s" = "$_ql_st" ]; then
    builtin kill -TERM "$_ql_pid" 2>/dev/null
    while builtin kill -0 "$_ql_pid" 2>/dev/null && [ "$i" -lt 60 ]; do command sleep 0.05; i=$((i + 1)); done
  fi
  _ql_pid=""
  return 0
}
