# The parallel runner (contract D6, and D3's log and verdict). _par_run hands each
# unit of $_sj_units (part 0001) to a process of its own, at most $_suite_jobs at
# a time, and judges what they leave. The driver calls it once, under -j N, in
# place of the part lines, which it then reads as no-ops. This part defines
# functions and variables, runs nothing when sourced, makes no assertion, and is
# self-contained: of receipt.sh it uses only _rcp_mark and the bounded
# _rcp_red_end, where a record run's unit failed (R1). It is not in _suite_preamble.
#
# A unit is `bash tests/run --part NAME...` (part mode, 0001) in the directory
# the parent was started in, with its log, ran file and end file in $TMP/pj.
# From the outside in:
# - a wrapper, a ( ) subshell in this shell's job table: it closes the FIFO for
#   what it runs, runs the holder in the foreground with stdout and stderr
#   appended to the unit's log (R4), writes "UNIT STATUS" to the FIFO as one
#   line, and traps TERM (run once the holder has ended; it exits, writing nothing).
# - a holder, one perl: it waits for a slot (a flock on a regular file of
#   ${TMPDIR:-/tmp}/felix-suite-slots, tried in turn, once a second) and writes
#   the slot file the wrapper names, whole each time (R4): line 1 "- -" until it
#   holds a slot, then "SLOT-EPOCH FIRST-TRY-EPOCH"; line 2 its pid and start
#   time. It forks and execs the unit with INT and QUIT as this shell had them and
#   every signal it changed put back. The slot file is close-on-exec, so the unit
#   holds no lock; the kernel drops the holder's lock when it goes. Its TERM
#   handler exits 143 while it has no child and otherwise returns, and TERM is
#   blocked across the fork. Once a second while it waits and while the unit runs
#   (a poll), and before it forks, it checks its wrapper (its parent's pid) and the -j
#   parent (kill 0; its start time every 10 s): when either is gone it starts no unit,
#   or ends the unit's tree as R14 says, and exits 2. It writes the unit's pid and start
#   time to unit.I after it forks (R15).
# Part mode (part 0001) also records the shell a unit starts with and compares it when the unit
# ends (_pm_snap, _pm_diff below; R8): a change a part leaves in the shell is the seventh runner
# failure, printed by _par_show after the unit's others, since a serial run carries it to the parts after.
# This shell reads the FIFO (held open read-write) with a plain read, never read -t (R13: a
# trap run while a timed read blocks is cut short by its alarm), and forks nothing while it
# waits. A ticker perl writes @@tick to the FIFO every W s. On a tick, a wrapper that is not in the
# job table and has no line is gone (R14), ends its unit as one with no mark and has its holder
# ended (R4). A unit whose holder has had no slot for FELIX_TEST_SLOT_NOTE s (300) is said once on stderr (R6).
_pj_pl='use Fcntl qw(:flock);
use POSIX ();
my ($dir, $k, $ef, $si, $sq, $mp, $mst, $uf, @cmd) = @ARGV;
my ($pp, $pid, $old, @M, %H, @P) = (getppid, undef, $SIG{TERM});
$SIG{TERM} = sub { exit 143 unless defined $pid };
sub trim { my $x = shift; $x =~ s/^\s+|\s+$//g; $x }
sub wr { my ($f, $t, $z) = @_; my $o; (open($o, ">", "$f.t") and print({$o} $t) and close($o) and rename("$f.t", $f)) or $z or exit 2 }
my $st = trim(`ps -o lstart= -p $$ 2>/dev/null`);
my $lq = time;
sub gone {   # the wrapper or the -j parent is gone, or the parent has another start time (R4, R15)
  return 1 if getppid() != $pp or !kill(0, $mp);
  return 0 unless $_[0] || time - $lq >= 10;
  $lq = time; my $x = trim(`ps -o lstart= -p $mp 2>/dev/null`);
  $x ne "" && $mst ne "" && $x ne $mst
}
sub add { $H{"$_[0];$_[1]"}++ ? 0 : (push(@M, [@_]) && 1) }
sub grow {   # R14: members are a pid and a start time; a listing seeds from the members present in it
  my ($n, @l, %R, %Q, @q, $a) = (0);
  while ($n++ < 5) { @l = `ps -A -o pid= -o ppid= -o lstart= 2>/dev/null`; last if @l; select(undef, undef, undef, 0.2) if $n < 5 }
  return 0 unless @l;
  for (@l) { next unless /^\s*(\d+)\s+(\d+)\s+(.*?)\s*$/; $R{$1} = [$2, $3]; push @{ $Q{$2} }, $1 }
  my %v;
  for my $m (@M) {
    $m->[1] = (exists $R{$m->[0]} && $R{$m->[0]}[0] == $$) ? $R{$m->[0]}[1] : "~" if $m->[1] eq "@";
    push @q, $m->[0] if exists $R{$m->[0]} && ($m->[1] eq "" || $m->[1] eq $R{$m->[0]}[1]) && !$v{$m->[0]}++;
  }
  for (my $h = 0; $h < @q; $h++) { for my $c (@{ $Q{$q[$h]} || [] }) { $a += add($c, $R{$c}[1]); push @q, $c unless $v{$c}++ } }
  @P = @q;
  $a || 0
}
sub endtree {
  (@M, %H) = (); add($_[0], "@"); @P = ($_[0]); grow();
  kill TERM => @P;
  for (1 .. 100) { last if waitpid($_[0], POSIX::WNOHANG()) != 0; select(undef, undef, undef, 0.1) }
  for (1 .. 30) { my $a = grow(); kill STOP => @P; last unless $a }
  kill KILL => @P; grow(); kill KILL => @P; kill CONT => @P;
  waitpid($_[0], 0);
}
wr($ef, "- -\n$$ $st\n");
my ($got, $w, $t0) = (undef, undef, time);
SLOT: while (1) {
  exit 2 if gone();
  for my $i (0 .. $k - 1) {
    open(my $fh, "<", "$dir/$i") or exit 2;
    if (flock($fh, LOCK_EX | LOCK_NB)) { $got = $fh; last SLOT }
    $!{EWOULDBLOCK} or exit 2;
    close $fh;
  }
  $w = 1;
  sleep 1;
}
my $t1 = time;
wr($ef, $t1 . " " . ($w ? $t0 : $t1) . "\n$$ $st\n");
exit 2 if gone(1);
my $set = POSIX::SigSet->new(POSIX::SIGTERM());
POSIX::sigprocmask(POSIX::SIG_BLOCK(), $set);
$pid = fork;
defined $pid or exit 2;
if (!$pid) {
  $SIG{TERM} = defined $old ? $old : "DEFAULT";
  POSIX::sigprocmask(POSIX::SIG_UNBLOCK(), $set);
  $SIG{INT} = $si; $SIG{QUIT} = $sq;
  exec { $cmd[0] } @cmd;
  exit 127;
}
POSIX::sigprocmask(POSIX::SIG_UNBLOCK(), $set);
my $us = trim(`ps -o lstart= -p $pid 2>/dev/null`);
wr($uf, "$pid $us\n", 1) if $us ne "";
my ($r, $last) = (0, time);
while (1) {
  $r = waitpid($pid, POSIX::WNOHANG());
  last if $r != 0;
  if (time() != $last) { $last = time; if (gone()) { endtree($pid); exit 2 } }
  select(undef, undef, undef, 0.05);
}
my $s = $?;
exit($r == $pid ? (($s & 127) ? 128 + ($s & 127) : $s >> 8) : 2);'
# How INT and QUIT stand in this shell, read from a foreground child before any
# trap is set here: IGNORE or DEFAULT for each, in that order, a blank after each.
_pj_sgpl='for my $s (qw(INT QUIT)) { my $v = $SIG{$s}; print((defined $v && $v eq "IGNORE") ? "IGNORE " : "DEFAULT ") }'
# The lock the parent takes and drops before it starts a wrapper: 0 where it was
# granted, or refused with EWOULDBLOCK (another run holds the slot, and flock
# works); 3 for a file it cannot open; 4 for any other error from flock.
_pj_lkpl='use Fcntl qw(:flock);
open(my $h, "<", $ARGV[0]) or exit 3;
if (flock($h, LOCK_EX | LOCK_NB)) { flock($h, LOCK_UN); exit 0 }
exit($!{EWOULDBLOCK} ? 0 : 4)'
# The slots directory D, checked by one perl (R5): exit 10 nothing at D, 11 a symbolic link, 12
# not a directory, 13 not owned by the effective user, 14 writable by group or others, 15 not
# readable; 16 an entry that is not a regular file (its path is printed): every name but . and ..
_pj_dpl='my $d = shift; my @s = lstat($d) or exit 10;
-l _ and exit 11; -d _ or exit 12; $s[4] == $> or exit 13; $s[2] & 022 and exit 14;
opendir(my $h, $d) or exit 15;
for (sort readdir $h) { next if /^[.][.]?$/; lstat("$d/$_") and -f _ or do { print "$d/$_"; exit 16 } }'
# The set a stopper holds (R2, R14): members "pid;start" joined by "|" on -v seed, a member being a pid and
# the start time it had when it joined (empty: any; "@": a root whose start is taken from the first non-empty
# listing, when its row has -v par as its parent, and otherwise never present). Reads ps -A -o pid= -o ppid= -o
# lstart=. Prints, tab separated: the rows read, the members added (everything below a member present in this
# listing), the whole set, and the pids present in it.
_pj_tw='{ p = $1; s = $0; sub(/^ *[0-9]+ +[0-9]+ */, "", s); sub(/ +$/, "", s); R[p] = s; P[p] = $2; K[$2] = K[$2] " " p }
END {
  n = split(seed, M, "|")
  for (i = 1; i <= n; i++) {
    if (M[i] == "") continue
    split(M[i], a, ";"); p = a[1]; s = a[2]
    if (s == "@" && NR) s = ((p in R) && P[p] == par) ? R[p] : "~"
    m++; sp[m] = p; ss[m] = s; have[p ";" s] = 1
  }
  for (i = 1; i <= m; i++)
    if (NR && (sp[i] in R) && (ss[i] == "" || ss[i] == R[sp[i]])) { pres[sp[i]] = 1; if (!(sp[i] in vis)) { vis[sp[i]] = 1; Q[++qn] = sp[i] } }
  for (h = 1; h <= qn; h++) {
    nc = split(K[Q[h]], C, " ")
    for (j = 1; j <= nc; j++) {
      c = C[j]; pres[c] = 1
      if (!((c ";" R[c]) in have)) { have[c ";" R[c]] = 1; m++; sp[m] = c; ss[m] = R[c]; add++ }
      if (!(c in vis)) { vis[c] = 1; Q[++qn] = c }
    }
  }
  out = ""; for (i = 1; i <= m; i++) out = out (i > 1 ? "|" : "") sp[i] ";" ss[i]
  pl = ""; for (c in pres) pl = pl " " c
  printf "%d\t%d\t%s\t%s\n", NR, add + 0, out, pl
}'
# The ticker (R13): writes @@tick to the FIFO every W s, so that the parent reads with no alarm pending.
_pj_tkpl='use POSIX ();
my ($f, $w) = @ARGV;
$SIG{TERM} = $SIG{HUP} = "DEFAULT";
POSIX::sigprocmask(POSIX::SIG_UNBLOCK(), POSIX::SigSet->new(POSIX::SIGTERM(), POSIX::SIGHUP()));
my ($pp, $l) = (getppid, time);
sysopen(my $h, $f, POSIX::O_WRONLY() | POSIX::O_NONBLOCK()) or exit 1;
while (1) {
  select(undef, undef, undef, 1);
  exit 0 if getppid() != $pp;
  next if time - $l < $w;
  $l = time;
  defined syswrite($h, "\@\@tick\n") or $!{EAGAIN} or exit 0;
}'
# The shell a unit leaves (R8). _pm_snap writes this shell's state to a file; _pm_diff sets _pm_chg to one line
# a change between the two that part mode takes, at _pm_start and _pm_fin (part 0001). Both use no variable whose
# name does not start _pm, so what they read is the parts' shell and not their own. The perl is given the two
# snapshots and $TMP/lib-before.names; "+fn NAME" lines it prints are functions added, which bash classifies.
_pm_pl='use strict;
my ($bf, $af, $nf) = @ARGV;
sub rd { open(my $h, "<", $_[0]) or return ""; local $/; my $t = <$h>; close $h; defined $t ? $t : "" }
sub parse { my %s; my $t = shift; while ($t =~ /^\@\@pm:(\w+)([^\n]*)\n(.*?)(?=^\@\@pm:|\z)/msg) { $s{$1} = [$2, $3] } \%s }
sub ln { my $t = shift; $t =~ s/\n\z//; split /\n/, $t, -1 }
sub recs { my (%h, $c); for (split /^/m, shift) { if (/^declare -(\S+) ([A-Za-z_][A-Za-z0-9_]*)(?:=|$)/) { $c = $2; $h{$c} = [$1, $_] } elsif (defined $c) { $h{$c}[1] .= $_ } } \%h }
sub trp { my %h; for (split /(?=^trap -- )/m, shift) { (my $x = $_) =~ s/\s+\z//; $h{$1} = $x if $x =~ /^trap -- .*?(\S+)\z/s } \%h }
sub fns { my (%h, $c); for (split /^/m, shift) { if (/^([^\s()]+) \(\)\s*$/) { $c = $1; $h{$c} = $_ } elsif (defined $c) { $h{$c} .= $_ } } \%h }
my ($B, $A) = (parse(rd($bf)), parse(rd($af)));
unless (exists $B->{end} && exists $A->{end}) { print "the shell state could not be read back to compare it\n"; exit 0 }
my @o;
my ($w, $n) = ((ln($B->{um}[1]))[0], (ln($A->{um}[1]))[0]);
push @o, "umask $w is now $n" if $w ne $n;
for my $k (qw(set shopt)) {
  my (%w, %n);
  for (ln($B->{$k}[1])) { $w{$1} = $_ if /(\S+)$/ }
  for (ln($A->{$k}[1])) { $n{$1} = $_ if /(\S+)$/ }
  for (sort keys %w) { push @o, "$w{$_} is now " . (defined $n{$_} ? $n{$_} : "gone") if !defined $n{$_} || $n{$_} ne $w{$_} }
}
for my $k (qw(ul uh)) {
  my @w = ln($B->{$k}[1]); my @n = ln($A->{$k}[1]);
  for my $i (0 .. ($#w > $#n ? $#w : $#n)) {
    my ($x, $y) = (defined $w[$i] ? $w[$i] : "", defined $n[$i] ? $n[$i] : "");
    push @o, ($k eq "ul" ? "ulimit -a: " : "ulimit -Ha: ") . "$x is now $y" if $x ne $y;
  }
}
my ($tw, $tn) = (trp($B->{trap}[1]), trp($A->{trap}[1]));
for (sort keys %$tw) { push @o, "trap on $_ " . (exists $tn->{$_} ? "changed" : "removed") if !exists $tn->{$_} || $tn->{$_} ne $tw->{$_} }
for (sort keys %$tn) { push @o, "trap on $_ added" unless exists $tw->{$_} }
my (%fw, %fa); $fw{$_} = 1 for split " ", $B->{fds}[0]; $fa{$_} = 1 for split " ", $A->{fds}[0];
for (0 .. 9) { push @o, "descriptor $_ opened" if $fa{$_} && !$fw{$_}; push @o, "descriptor $_ closed" if $fw{$_} && !$fa{$_} }
my ($xw, $xa) = (recs($B->{exp}[1]), recs($A->{exp}[1]));
my %st = map { $_ => 1 } qw(LANG TZ HOME TMPDIR PATH CDPATH ENV BASH_ENV SHELLOPTS BASHOPTS POSIXLY_CORRECT XDG_CONFIG_HOME);
for (sort keys %$xw) {
  next if /^(?:PWD|OLDPWD)$/;
  if (!exists $xa->{$_}) { push @o, "export $_ removed" } elsif ($xa->{$_}[1] ne $xw->{$_}[1]) { push @o, "export $_ changed" }
}
for (sort keys %$xa) { push @o, "export $_ added" if !exists $xw->{$_} && (/^(?:GIT_|LC_|FELIX_)/ || $st{$_}) }
my %nm; if (open(my $h, "<", $nf)) { while (my $l = <$h>) { chomp $l; $nm{$l} = 1 } close $h } else { push @o, "the prelude names [$nf] could not be read" }
my %xc = map { $_ => 1 } qw(PASS FAIL SKIP _fx_walkroot _fx_r SHELLOPTS PWD OLDPWD COLUMNS DIRSTACK EPOCHREALTIME EPOCHSECONDS FUNCNAME GROUPS HISTCMD LINENO LINES OPTARG OPTERR OPTIND PIPESTATUS RANDOM REPLY SECONDS SRANDOM _);
my ($dw, $da) = (recs($B->{decl}[1]), recs($A->{decl}[1]));
for (sort keys %$dw) {
  next if $dw->{$_}[0] =~ /x/ || !$nm{$_} || $xc{$_} || /^(?:_og_|_pm|_par_|_pj_|BASH)/;
  if (!exists $da->{$_}) { push @o, "variable $_ removed" } elsif ($da->{$_}[1] ne $dw->{$_}[1]) { push @o, "variable $_ changed" }
}
my ($gw, $ga) = (fns($B->{fn}[1]), fns($A->{fn}[1]));
for (sort keys %$gw) { if (!exists $ga->{$_}) { push @o, "function $_ removed" } elsif ($ga->{$_} ne $gw->{$_}) { push @o, "function $_ changed" } }
for (sort keys %$ga) { push @o, "+fn $_" unless exists $gw->{$_} }
print "$_\n" for @o'
_pm_snap() {   # FILE; the variables are asked for by name (bash 3.2 prints declare -p with no name in set's form)
  local _pm_i=0 _pm_d="" _pm_v
  while [ "$_pm_i" -le 9 ]; do { true >&"$_pm_i"; } 2>/dev/null && _pm_d="$_pm_d $_pm_i"; _pm_i=$((_pm_i + 1)); done
  { printf '@@pm:fds%s\n@@pm:um\n' "$_pm_d"; umask; printf '@@pm:set\n'; set +o; printf '@@pm:shopt\n'; shopt -p
    printf '@@pm:trap\n'; trap -p; printf '@@pm:ul\n'; ulimit -a; printf '@@pm:uh\n'; ulimit -Ha
    printf '@@pm:exp\n'; export -p; printf '@@pm:decl\n'
    while IFS= read -r _pm_v; do declare -p "$_pm_v"; done < "$TMP/lib-before.names"
    printf '@@pm:fn\n'; declare -f; printf '@@pm:end\n'; } > "$1" 2>/dev/null
}
_pm_diff() {
  local _pm_l _pm_b="" _pm_k=""
  _pm_chg=""
  perl -e "$_pm_pl" "$TMP/pm.0" "$TMP/pm.1" "$TMP/lib-before.names" > "$TMP/pm.out" 2>&1 || _pm_chg="the shell state could not be compared"$'\n'
  while IFS= read -r _pm_l; do
    case "$_pm_l" in
      "+fn "*)
        _pm_l="${_pm_l#+fn }"
        [ -n "$_pm_b" ] || { _pm_b=$'\n'"$(compgen -b)"$'\n'; _pm_k=$'\n'"$(compgen -k)"$'\n'; }
        case "$_pm_b" in *$'\n'"$_pm_l"$'\n'*) _pm_chg="${_pm_chg}function $_pm_l added over a builtin"$'\n'; continue ;; esac
        case "$_pm_k" in *$'\n'"$_pm_l"$'\n'*) _pm_chg="${_pm_chg}function $_pm_l added over a keyword"$'\n'; continue ;; esac
        [ -z "$(PATH="$_pm_path0" type -P -- "$_pm_l" 2>/dev/null)" ] || _pm_chg="${_pm_chg}function $_pm_l added over a command"$'\n' ;;
      *) _pm_chg="$_pm_chg$_pm_l"$'\n' ;;
    esac
  done < "$TMP/pm.out"
}
# One unit's log, as D3 prints it. -v unit, mem (its part files, blank between),
# efail (the FAIL counter its end file holds, -1 when unknown), epf (what its
# prelude counted, from `prefail`, -1 when unknown), rc (the holder's
# exit status, or lost), note (a line or empty) and stats (a file). It prints
# the note; then, if the file has a FAIL before @@prelude-done or no
# @@prelude-done at all, a failure and the lines before it behind two spaces, a
# bar and a space; then the rest as written without the runner lines; then the
# failures the runner owns. It writes "ok FAIL skip runner-failures" to stats:
# the lines counted after @@prelude-done, as tests/red counts them.
_pj_aw='function pre(f,   j) {
  if (f) {
    print "  FAIL  part\047s prelude failed: " unit; rf++
    for (j = 1; j <= np; j++) print "  | " P[j]
  }
  np = 0
}
BEGIN {
  nm = split(mem, M, " ")
  for (j = 1; j <= nm; j++) idx[M[j]] = j
  if (note != "") print note
}
{
  l = $0
  if (l == "@@prelude-done") { if (s == 0) { s = 1; pre(npf > 0 || epf > npf) } else bad = 1; next }
  if (substr(l, 1, 14) == "@@member-done ") {
    j = substr(l, 15)
    if (s == 1 && !mk && (j in idx) && idx[j] > last) { last = idx[j]; done[last] = 1 } else bad = 1
    next
  }
  if (substr(l, 1, 12) == "@@part-done ") {
    if (s == 1 && !mk && substr(l, 13) == mem) mk = 1; else bad = 1
    next
  }
  if (l == "reached") { bad = 1; if (s == 0) P[++np] = l; else print "  | reached"; next }
  if (s == 0) { P[++np] = l; if (substr(l, 1, 8) == "  FAIL  ") npf++; next }
  h = substr(l, 1, 8)
  if (h == "  ok    ") nok++
  else if (h == "  FAIL  ") nf++
  else if (h == "  skip  ") nsk++
  print l
}
END {
  if (s == 0) pre(1)
  for (j = 1; j <= nm; j++) if (!(j in done)) { print "  FAIL  part did not finish: " M[j]; rf++ }
  if (!mk || rc == "lost") { print "  FAIL  part ended without its mark: " unit; rf++ }
  else if (rc != "0") { print "  FAIL  part process ended with status " rc ": " unit; rf++ }
  if (efail >= 0 && efail > nf + 0) { print "  FAIL  part failed more than it printed: " unit; rf++ }
  if (bad) { print "  FAIL  part printed a line the runner owns: " unit; rf++ }
  printf "%d %d %d %d\n", nok + 0, nf + 0, nsk + 0, rf + 0 > stats
  close(stats)
}'

# -> _pj_k, the slots: FELIX_TEST_SLOTS where set, else the core count found as
# the gate finds it (sysctl, then getconf, then 1; 1 to 64).
_par_cores() {
  local n
  n="$(sysctl -n hw.ncpu 2>/dev/null)"
  case "$n" in ""|*[!0123456789]*) n="$(getconf _NPROCESSORS_ONLN 2>/dev/null)" ;; esac
  case "$n" in ""|*[!0123456789]*) n=1 ;; esac
  n="${n#"${n%%[!0]*}"}"
  [ -n "$n" ] || n=1
  [ "${#n}" -le 2 ] || n=64
  [ "$n" -le 64 ] || n=64
  _pj_k="$n"
}
# Makes the slots directory (0700, an absolute path: R5), checks it and every name in it, makes
# every slot file, then takes and drops one lock; refuses (exit 2, one line) when it cannot, and
# never opens a name that is not a regular file. -> _pj_sd and _pj_k.
_par_slots() {
  local d="${TMPDIR:-/tmp}/felix-suite-slots" f i=0 v e
  if [ -n "${FELIX_TEST_SLOTS+x}" ]; then
    _sj_n "$FELIX_TEST_SLOTS" || _sj_die "FELIX_TEST_SLOTS is [$FELIX_TEST_SLOTS]: it must be a number from 1 to 64 in plain decimal"
    _pj_k="$FELIX_TEST_SLOTS"
  else
    _par_cores
  fi
  case "$d" in /*) ;; *) d="${_og_start%/}/$d" ;; esac
  [ -e "$d" ] || [ -L "$d" ] || mkdir -p -m 0700 "$d" 2>/dev/null
  v="$(perl -e "$_pj_dpl" "$d" 2>/dev/null)"; e=$?
  case "$e" in
    0) ;;
    10) _sj_die "the slots directory [$d] cannot be made" ;;
    11) _sj_die "the slots directory [$d] is a symbolic link" ;;
    12) _sj_die "the slots directory [$d] is not a directory" ;;
    13) _sj_die "the slots directory [$d] is not owned by this user" ;;
    14) _sj_die "the slots directory [$d] is writable by its group or by others" ;;
    16) _sj_die "[$v] is not a regular file: the slots directory holds slot files and nothing else" ;;
    *)  _sj_die "the slots directory [$d] cannot be read (perl is needed)" ;;
  esac
  while [ "$i" -lt "$_pj_k" ]; do
    f="$d/$i"
    [ -e "$f" ] || : 2>/dev/null >> "$f" || _sj_die "cannot make the slot file [$f]"
    [ -r "$f" ] || _sj_die "cannot open the slot file [$f]"
    i=$((i + 1))
  done
  perl -e "$_pj_lkpl" "$d/0" 2>/dev/null || _sj_die "cannot take a lock on [$d/0]: flock fails here, and the slots are flocks"
  _pj_sd="$d"
}
# -> _pj_nm, _pj_mb (the units), their durations from the file (D4) and _pj_q,
# the start order: units with no valid row first, then longest first, ties in
# driver order. A row is used only as `0` or digits with no leading zero, a tab
# and the name of a unit of this run; no value from the file is ever evaluated.
_par_order() {
  local tab=$'\t' u m l s i k d f t top a b lines="" ix
  _pj_n=0; _pj_nm=(); _pj_mb=(); _pj_dur=(); _pj_q=(); _pj_df=""
  while IFS="$tab" read -r u m; do
    [ -n "$u" ] || continue
    _pj_nm[_pj_n]="$u"; _pj_mb[_pj_n]="$m"; _pj_dur[_pj_n]=""; _pj_n=$((_pj_n + 1))
  done <<< "$_sj_units"
  if [ "${_rcp_on:-0}" = 1 ] && [ -n "${_rcp_root:-}" ]; then
    t="$(git -C "$_rcp_root" rev-parse --show-toplevel --git-path felix-suite-durations 2>/dev/null)" || t=""
    top="${t%%$'\n'*}"; f="${t#*$'\n'}"
    case "$f" in ""|"$t") f="" ;; /*) ;; *) f="${_rcp_root%/}/$f" ;; esac
    a="$(cd -P "$_rcp_root" 2>/dev/null && pwd -P)"; b="$(cd -P "$top" 2>/dev/null && pwd -P)"
    [ -n "$a" ] && [ "$a" = "$b" ] || f=""
    _pj_df="$f"
  fi
  if [ -n "$_pj_df" ] && [ -f "$_pj_df" ] && [ -r "$_pj_df" ]; then
    while IFS= read -r l || [ -n "$l" ]; do
      case "$l" in *"$tab"*) ;; *) continue ;; esac
      s="${l%%"$tab"*}"; u="${l#*"$tab"}"
      case "$s" in 0) ;; [123456789]*) case "$s" in *[!0123456789]*) continue ;; esac ;; *) continue ;; esac
      [ "${#s}" -le 18 ] || continue
      i=0
      while [ "$i" -lt "$_pj_n" ]; do
        if [ "${_pj_nm[$i]}" = "$u" ]; then [ -n "${_pj_dur[$i]}" ] || _pj_dur[i]="$s"; break; fi
        i=$((i + 1))
      done
    done < "$_pj_df"
  fi
  i=0
  while [ "$i" -lt "$_pj_n" ]; do
    d="${_pj_dur[$i]}"
    if [ -z "$d" ]; then lines="${lines}0${tab}-${tab}$i"$'\n'
    else k="${#d}"; [ "$k" -ge 10 ] || k="0$k"; lines="${lines}1${tab}${k}${d}${tab}$i"$'\n'; fi
    i=$((i + 1))
  done
  k=0
  while IFS="$tab" read -r a b ix; do
    case "$ix" in ""|*[!0123456789]*) continue ;; esac
    _pj_q[k]="$ix"; k=$((k + 1))
  done < <(printf '%s' "$lines" | LC_ALL=C sort -t "$tab" -k1,1 -k2,2r -k3,3n)
  if [ "$k" -ne "$_pj_n" ]; then
    _pj_q=(); i=0
    while [ "$i" -lt "$_pj_n" ]; do _pj_q[i]="$i"; i=$((i + 1)); done
  fi
}
# Unit I's end file (D2, D3) -> _pe_fail, its FAIL counter or -1, _pe_pf, the FAIL
# counter at its @@prelude-done (R7), _pe_sh (1 when it left the shell changed) and
# _pe_shm, the changes a line each (R8); and, for 9990
# under -j N, one line a fact in _pj_9fl (floors that read bad), _pj_9rf
# (refusals) and _pj_9om (origin messages), the verdicts counted in _pj_9ob,
# _pj_9os and _pj_9ok. A file that is missing, cut short (no `end` record) or
# without a verdict makes all three bad.
_par_endrec() {
  local nm f l tag txt fl="" fm="" rf="" ov="" om="" n=-1 pf=-1 sh="" shm="" dn="" good=1 tab=$'\t'
  nm="${_pj_nm[$1]}"; f="$_pj_dir/end.$1"; _pe_fail=-1; _pe_pf=-1; _pe_sh=0; _pe_shm=""
  if [ -f "$f" ] && [ -r "$f" ]; then
    while IFS= read -r l || [ -n "$l" ]; do
      case "$l" in *"$tab"*) tag="${l%%"$tab"*}"; txt="${l#*"$tab"}" ;; *) tag="$l"; txt="" ;; esac
      case "$tag" in
        floor)    fl="$txt" ;;
        floormsg) fm="$fm$nm: $txt"$'\n' ;;
        refused)  rf="$rf$nm: $txt"$'\n' ;;
        og)       ov="$txt" ;;
        ogmsg)    om="$om$nm: $txt"$'\n' ;;
        fail)     case "$txt" in ""|*[!0123456789]*) ;; *) [ "${#txt}" -gt 9 ] || n="$txt" ;; esac ;;
        prefail)  case "$txt" in ""|*[!0123456789]*) ;; *) [ "${#txt}" -gt 9 ] || pf="$txt" ;; esac ;;
        shell)    sh="$txt" ;;
        shellmsg) shm="$shm$txt"$'\n' ;;
        end)      dn=1 ;;
      esac
    done < "$f"
  fi
  case "$fl" in ok|bad) ;; *) good="" ;; esac
  case "$ov" in ok|skip|bad) ;; *) good="" ;; esac
  case "$sh" in ok|changed) ;; *) good="" ;; esac
  [ "$n" -ge 0 ] && [ "$pf" -ge 0 ] && [ "$dn" = 1 ] || good=""
  if [ -z "$good" ]; then
    fl=bad; ov=bad; n=-1; pf=-1; sh=""
    fm="$nm: it left no readable end file"$'\n'; rf="$fm"; om="$fm"
  fi
  _pe_fail="$n"; _pe_pf="$pf"; [ "$sh" != changed ] || { _pe_sh=1; _pe_shm="$shm"; }
  if [ "$fl" = bad ]; then [ -n "$fm" ] || fm="$nm: its floor read bad"$'\n'; _pj_9fl="$_pj_9fl$fm"; fi
  _pj_9rf="$_pj_9rf$rf"
  case "$ov" in
    ok)   _pj_9ok=$((_pj_9ok + 1)) ;;
    skip) _pj_9os=$((_pj_9os + 1)) ;;
    *)    _pj_9ob=$((_pj_9ob + 1)); [ -n "$om" ] || om="$nm: its origin check read bad"$'\n'; _pj_9om="$_pj_9om$om" ;;
  esac
}
# Unit I has ended with _pj_rc[I] set: its duration (from the epoch its holder
# wrote to now, so without the slot wait) and the seconds the holder waited.
_par_fin() {
  local i="$1" ep="" st="" now
  _pj_s[i]=2; _pj_run=$((_pj_run - 1)); _pj_t[i]=0; _pj_w[i]=0
  { read -r ep st < "$_pj_dir/slot.$i"; } 2>/dev/null
  case "$ep" in ""|*[!0123456789]*) return 0 ;; esac
  case "$st" in ""|*[!0123456789]*) st="$ep" ;; esac
  [ "${#ep}" -le 12 ] && [ "${#st}" -le 12 ] || return 0
  now="$(date +%s)"
  case "$now" in ""|*[!0123456789]*) return 0 ;; esac
  [ "$now" -lt "$ep" ] || _pj_t[i]=$((now - ep))
  [ "$ep" -lt "$st" ] || _pj_w[i]=$((ep - st))
}
# Prints unit I (D3) and adds what its log holds to PASS, FAIL and SKIP.
_par_show() {
  local i="$1" nm="${_pj_nm[$1]}" note="" a=0 b=0 c=0 d=0 st="$_pj_dir/stats" w l
  _par_endrec "$i"
  w="${_pj_w[$i]}"
  if [ "$w" -gt 1 ]; then note="  note  $nm waited $w s for a slot"; fi
  rm -f "$st"
  LC_ALL=C awk -v unit="$nm" -v mem="${_pj_mb[$i]}" -v efail="$_pe_fail" -v epf="$_pe_pf" -v rc="${_pj_rc[$i]}" -v note="$note" -v stats="$st" \
    "$_pj_aw" "$_pj_dir/log.$i" 2>/dev/null
  if [ -f "$st" ]; then { read -r a b c d < "$st"; } 2>/dev/null; fi
  case "$a$b$c$d" in
    ""|*[!0123456789]*) a=0; b=0; c=0; d=1; printf '  FAIL  part ended without its mark: %s\n' "$nm" ;;
  esac
  if [ "$_pe_sh" = 1 ]; then   # R8: the seventh runner failure, after the unit's others
    printf '  FAIL  part left the shell changed for the parts after it: %s\n' "$nm"; d=$((d + 1))
    while IFS= read -r l; do printf '  | %s\n' "$l"; done <<< "${_pe_shm%$'\n'}"
  fi
  PASS=$((PASS + a)); FAIL=$((FAIL + b + d)); SKIP=$((SKIP + c)); _pj_rfn=$((_pj_rfn + d))
}
# Prints, in the driver's order, every unit that has ended once all before it have.
_par_flush() {
  while [ "$_pj_pr" -lt "$_pj_n" ] && [ "${_pj_s[$_pj_pr]}" = 2 ]; do
    _par_show "$_pj_pr"
    _pj_s[_pj_pr]=3
    _pj_pr=$((_pj_pr + 1))
  done
}
# A line from the FIFO: "UNIT STATUS". A status above 128 may be a holder killed under its unit
# (R15): the unit it recorded in unit.I is then ended, if it still runs.
_par_ev() {
  local l="$1" nm st i=0
  nm="${l% *}"; st="${l##* }"
  case "$st" in ""|*[!0123456789]*) return 0 ;; esac
  while [ "$i" -lt "$_pj_n" ]; do
    if [ "${_pj_nm[$i]}" = "$nm" ]; then
      [ "${_pj_s[$i]}" = 1 ] || return 0
      [ "${#st}" -gt 3 ] || [ "$st" -le 128 ] || _par_unit "$i"
      _pj_rc[i]="$st"; _par_fin "$i"
      return 0
    fi
    i=$((i + 1))
  done
}
# The set a stopper holds, _pj_set (see _pj_tw), gains everything below a member present in a
# listing; an empty listing is taken again, five tries in all, 0.2 s apart (R2, R14). A listing
# that comes back empty leaves _pj_pres, the pids to signal, as the last non-empty one had it.
# -> _pj_set, _pj_add, _pj_pres.
_par_grow() {
  local o="" t=0 r tab=$'\t'
  while [ "$t" -lt 5 ]; do
    o="$(ps -A -o pid= -o ppid= -o lstart= 2>/dev/null | LC_ALL=C awk -v seed="$_pj_set" -v par="${_pj_par:-}" "$_pj_tw")"
    t=$((t + 1))
    case "$o" in ""|"0$tab"*) [ "$t" -ge 5 ] || sleep 0.2 ;; *) break ;; esac
  done
  _pj_add=0
  case "$o" in
    [123456789]*"$tab"*) r="${o#*"$tab"}"; _pj_add="${r%%"$tab"*}"; r="${r#*"$tab"}"; _pj_set="${r%%"$tab"*}"; _pj_pres="${r#*"$tab"}" ;;
  esac
}
_par_pids() { local IFS='|' e; _pj_pres=""; for e in $_pj_set; do _pj_pres="$_pj_pres ${e%%;*}"; done; }
# A stopper (R14) for the roots in _pj_set, with _pj_par the process they are children of. The
# set only grows, and a member is signalled only while the latest non-empty listing shows its pid
# with its start time. TERM, the roots given up to 10 s, STOP while a listing adds a member (30
# times at most), KILL, one more listing, KILL and then CONT. The caller ignores or holds its signals.
_par_k() { local p; for p in $_pj_pres; do kill -"$1" "$p" 2>/dev/null; done; }
_par_stop() {
  local p roots n=0 up
  _par_pids; roots="$_pj_pres"
  _par_grow; _par_k TERM
  while [ "$n" -lt 50 ]; do
    up=""; for p in $roots; do ! kill -0 "$p" 2>/dev/null || up=1; done
    [ -n "$up" ] || break
    sleep 0.2; n=$((n + 1))
  done
  n=0
  while [ "$n" -lt 30 ]; do _par_grow; _par_k STOP; [ "$_pj_add" -gt 0 ] || break; n=$((n + 1)); done
  _par_k KILL; _par_grow; _par_k KILL; _par_k CONT
}
# The signals, armed for the runner; or held, so that the first to come is kept (R2) and acted on
# once what the parent was doing is done.
_par_arm()  { trap '_par_sig 130' INT; trap '_par_sig 143' TERM; trap '_par_sig 129' HUP; trap '_par_sig 131' QUIT; }
_par_hold() { _pj_sq=""; trap '_pj_sq="${_pj_sq:-130}"' INT; trap '_pj_sq="${_pj_sq:-143}"' TERM; trap '_pj_sq="${_pj_sq:-129}"' HUP; trap '_pj_sq="${_pj_sq:-131}"' QUIT; }
# Ends the tree of PID, held with START, when that pid still has that start time, holding the
# signals meanwhile as R2 says and acting on the first to come once it is done.
_par_endp() {
  local b
  case "$1" in ""|*[!0123456789]*) return 0 ;; esac
  [ -n "$2" ] || return 0
  b="$(ps -o lstart= -p "$1" 2>/dev/null)"; b="${b#"${b%%[! ]*}"}"; b="${b%"${b##*[! ]}"}"
  [ "$b" = "$2" ] || return 0
  _par_hold; _pj_set="$1;$2"; _pj_par=""; _par_stop
  _par_arm; [ -z "$_pj_sq" ] || _par_sig "$_pj_sq"
}
# Unit I's wrapper is gone without a line (R4). Its holder, named by line 2 of the slot file
# with the start time it had, is ended if that pid still has that start time.
_par_lost() {
  local a="" b="" p s
  { { read -r a; read -r b; } < "$_pj_dir/slot.$1"; } 2>/dev/null
  p="${b%% *}"; s="${b#* }"
  [ "$s" != "$b" ] || return 0
  _par_endp "$p" "$s"
}
# Unit I's holder ended with a status above 128 (R15): the unit it recorded in unit.I, a pid and
# its start time, is ended if it still runs.
_par_unit() {
  local a="" p s
  { read -r a < "$_pj_dir/unit.$1"; } 2>/dev/null
  p="${a%% *}"; s="${a#* }"
  [ "$s" != "$a" ] || return 0
  _par_endp "$p" "$s"
}
# After a tick (R13), and so after a silence of W s: a wrapper that is not in this shell's job
# table and has no line is gone (R14: its pid is not asked about, since it may be another
# process's by now). @@gone goes into the FIFO and is read back, handling every line before it;
# the wrapper writes its line before it exits, so a wrapper found gone has had its line read
# by then. One still without one ends its unit as one with no mark (R4).
_par_gone() {
  local i=0 g="" l jl=" "
  { builtin jobs -rp > "$_pj_dir/jobs"; } 2>/dev/null || return 0
  while IFS= read -r l; do jl="$jl$l "; done < "$_pj_dir/jobs"
  while [ "$i" -lt "$_pj_n" ]; do
    if [ "${_pj_s[$i]}" = 1 ] && [ -n "${_pj_pid[$i]}" ]; then case "$jl" in *" ${_pj_pid[$i]} "*) ;; *) g="$g $i" ;; esac; fi
    i=$((i + 1))
  done
  [ -n "$g" ] || return 0
  printf '@@gone\n' >&63
  while read -r -u 63 l; do
    case "$l" in "@@gone") break ;; "@@tick") ;; *) _par_ev "$l" ;; esac
  done
  for i in $g; do
    [ "${_pj_s[$i]}" = 1 ] || continue
    _par_lost "$i"; _pj_rc[i]=lost; _par_fin "$i"
  done
}
# R6: a unit whose holder has had no slot for T s since its wrapper started is said once on stderr.
_par_nt() {
  local i=0 a
  while [ "$i" -lt "$_pj_n" ]; do
    if [ "${_pj_s[$i]}" = 1 ] && [ -z "${_pj_nt[$i]:-}" ] && [ "$((SECONDS - ${_pj_ws[$i]}))" -ge "$_pj_T" ]; then
      a=""; { read -r a < "$_pj_dir/slot.$i"; } 2>/dev/null
      case "$a" in ""|"- "*) _pj_nt[i]=1; printf 'tests/run: %s has waited %s s for a slot and goes on waiting\n' "${_pj_nm[$i]}" "$_pj_T" >&2 ;; esac
    fi
    i=$((i + 1))
  done
}
# Starts unit I: a wrapper (see the head of this file) for its holder. The unit is marked
# running with no pid before the fork and takes it from $! after (R3): an ending between
# the two finds the wrapper by $! differing from _pj_bg0.
_par_start() {
  local i="$1" nm="${_pj_nm[$1]}" mb="${_pj_mb[$1]}"
  : > "$_pj_dir/log.$i"
  _pj_bg0="$!"; _pj_s[i]=1; _pj_pid[i]=""; _pj_ws[i]="$SECONDS"
  (
    trap 'exit 143' TERM
    cd "${_og_start:-.}" || exit 125
    exec >/dev/null 2>&1
    export FELIX_TEST_PART_LOG="$_pj_dir/log.$i" FELIX_TEST_PART_RAN="$_pj_dir/ran.$i" FELIX_TEST_PART_END="$_pj_dir/end.$i"
    [ "$FELIX_TEST_RECORD" != 1 ] || export FELIX_TEST_PART_RECORD=1
    perl -e "$_pj_pl" "$_pj_sd" "$_pj_k" "$_pj_dir/slot.$i" $_pj_sg "$_pj_pp" "$_pj_ps" "$_pj_dir/unit.$i" "$BASH" "$HERE/run" --part $mb >> "$_pj_dir/log.$i" 2>&1 63>&-
    printf '%s %s\n' "$nm" "$?" >&63
  ) &
  _pj_pid[i]=$!
}
# The ending (D6, R2, R14): every wrapper running, the one being forked and the ticker (R13) are
# ended with all that runs below them by the stopper, INT, TERM, HUP and QUIT ignored from the
# first step; then each is waited for, so every unit is reaped before this shell goes. Roots are
# members "pid;@": their start times come from the first listing, where this shell is their
# parent. Slots are not touched.
_par_end() {
  local bg="$!" i=0 p rl=""
  trap '' INT TERM HUP QUIT
  _pj_set=""; _pj_par="$$"
  while [ "$i" -lt "${_pj_n:-0}" ]; do
    if [ "${_pj_s[$i]:-0}" = 1 ]; then
      if [ -n "${_pj_pid[$i]:-}" ]; then rl="$rl ${_pj_pid[$i]}"
      elif [ -n "$bg" ] && [ "$bg" != "${_pj_bg0:-}" ]; then rl="$rl $bg"; fi
    fi
    i=$((i + 1))
  done
  rl="$rl ${_pj_tk:-}"
  for p in $rl; do _pj_set="${_pj_set:+$_pj_set|}$p;@"; done
  [ -n "$_pj_set" ] || return 0
  _par_stop
  for i in $rl; do { wait "$i"; } 2>/dev/null; done
  _pj_tk=""; i=0
  while [ "$i" -lt "$_pj_n" ]; do [ "${_pj_s[$i]}" != 1 ] || _pj_s[i]=9; i=$((i + 1)); done
}
_par_sig() { trap '' INT TERM HUP QUIT; _par_end; exit "$1"; }
# The runner. Under -j N the driver calls it after the prelude; it leaves, for
# 9990, _pj_9fl, _pj_9rf, _pj_9om and _pj_9ob/_pj_9os/_pj_9ok, adds the units'
# ran files to $FELIX_TEST_RAN and their counts to PASS, FAIL and SKIP, writes
# the durations (D4), and ends with _par_done=1. A record run with any runner
# failure writes the mark `failed`, waits for red up to 60 s (R1) and exits 1 here,
# before 9990 (D4).
_par_run() {
  local i p l def
  _pj_dir="$TMP/pj"; _pj_rfn=0; _pj_pr=0; _pj_qi=0; _pj_run=0; _pj_s=(); _pj_pid=(); _pj_rc=(); _pj_t=(); _pj_w=(); _pj_ws=(); _pj_nt=(); _pj_sq=""; _pj_tk=""; _pj_pp="$$"
  _pj_ps="$(ps -o lstart= -p "$$" 2>/dev/null)"; _pj_ps="${_pj_ps#"${_pj_ps%%[! ]*}"}"; _pj_ps="${_pj_ps%"${_pj_ps##*[! ]}"}"
  ( : ) & { wait "$!"; } 2>/dev/null   # $! is set from here on, which _par_start and _par_end read under set -u
  _pj_T="${FELIX_TEST_SLOT_NOTE-}"
  case "$_pj_T" in ""|0*|*[!0123456789]*) _pj_T=300 ;; *) [ "${#_pj_T}" -le 6 ] || _pj_T=300 ;; esac
  _pj_W=30; [ "$_pj_T" -ge 30 ] || _pj_W="$_pj_T"
  _pj_9fl=""; _pj_9rf=""; _pj_9om=""; _pj_9ob=0; _pj_9os=0; _pj_9ok=0
  mkdir -p "$_pj_dir" || _sj_die "cannot make [$_pj_dir]"
  _par_order
  i=0; while [ "$i" -lt "$_pj_n" ]; do _pj_s[i]=0; _pj_pid[i]=""; _pj_rc[i]=""; i=$((i + 1)); done
  _pj_sg="$(perl -e "$_pj_sgpl" 2>/dev/null)"
  case "$_pj_sg" in "IGNORE IGNORE "|"IGNORE DEFAULT "|"DEFAULT IGNORE "|"DEFAULT DEFAULT ") ;; *) _sj_die "cannot read how INT and QUIT stand here (perl is needed)" ;; esac
  _par_slots
  mkfifo "$_pj_dir/fifo" 2>/dev/null && { exec 63<> "$_pj_dir/fifo"; } 2>/dev/null || _sj_die "cannot make the FIFO [$_pj_dir/fifo]"
  def="$(declare -f _fx_exit)" && eval "_par_fx_exit0${def#_fx_exit}"
  _fx_exit() { _par_end; _par_fx_exit0 "$@"; }
  _par_arm
  perl -e "$_pj_tkpl" "$_pj_dir/fifo" "$_pj_W" </dev/null >/dev/null 2>&1 63>&- &
  _pj_tk=$!
  while [ "$_pj_pr" -lt "$_pj_n" ]; do
    while [ "$_pj_run" -lt "$_suite_jobs" ] && [ "$_pj_qi" -lt "$_pj_n" ]; do
      _par_start "${_pj_q[$_pj_qi]}"
      _pj_qi=$((_pj_qi + 1)); _pj_run=$((_pj_run + 1))
    done
    _par_flush
    [ "$_pj_pr" -lt "$_pj_n" ] || break
    read -r -u 63 l || { sleep 1; l="@@tick"; }
    case "$l" in "@@tick") _par_gone ;; *) _par_ev "$l" ;; esac
    _par_nt
  done
  { kill -KILL "$_pj_tk"; wait "$_pj_tk"; } 2>/dev/null; _pj_tk=""
  exec 63>&-
  if [ "$_pj_rfn" -gt 0 ] && [ "$FELIX_TEST_RECORD" = 1 ]; then
    [ -z "${_rcp_red:-}" ] || { _rcp_mark failed "$TMP/manifest.mark"; _rcp_red_end "$TMP/manifest.mark" "$TMP/red.out" 60; }
    exit 1
  fi
  trap - INT TERM HUP QUIT
  if [ "$_pj_rfn" -eq 0 ] && [ -n "$_pj_df" ] && [ ! -L "$_pj_df" ] && { [ ! -e "$_pj_df" ] || [ -f "$_pj_df" ]; }; then
    {
      i=0
      while [ "$i" -lt "$_pj_n" ]; do printf '%s\t%s\n' "${_pj_t[$i]:-0}" "${_pj_nm[$i]}"; i=$((i + 1)); done
    } > "$_pj_df.tmp.$$" 2>/dev/null && mv -f "$_pj_df.tmp.$$" "$_pj_df" 2>/dev/null || rm -f "$_pj_df.tmp.$$" 2>/dev/null
  fi
  cat "$_pj_dir"/ran.* >> "$FELIX_TEST_RAN" 2>/dev/null
  _par_done=1
}
