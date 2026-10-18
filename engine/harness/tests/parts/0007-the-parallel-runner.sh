# The parallel runner (contract D6, and D3's log and verdict). _par_run hands each
# unit of $_sj_units (part 0001) to a process of its own, at most $_suite_jobs at
# a time, and judges what they leave. The driver calls it once, under -j N, in
# place of the part lines, which it then reads as no-ops. This part defines
# functions and variables and runs nothing when sourced, makes no assertion, and
# is self-contained: it uses nothing of receipt.sh but the one _rcp_mark call
# that ends a record run whose unit failed. It is not in _suite_preamble.
#
# A unit is `bash tests/run --part NAME...` (part mode, 0001) in the directory
# the parent was started in, with its log, ran file and end file in $TMP/pj.
# What starts it, from the outside in:
# - a wrapper, a ( ) subshell in this shell's job table: it closes the FIFO for
#   what it runs, runs the holder in the foreground, writes "UNIT STATUS" to the
#   FIFO as one line, and traps TERM (the trap runs once the holder has ended
#   and exits without writing). The shell's own "Killed" notices go to
#   /dev/null; the holder and the unit keep the wrapper's stderr.
# - a holder, one perl: it waits for a slot (a flock on a regular file of
#   ${TMPDIR:-/tmp}/felix-suite-slots, tried in turn, once a second), writes
#   "SLOT-EPOCH WAIT-FROM-EPOCH" to the file the wrapper names (the second is
#   when it began to wait: the first again when the first try got a slot, so a
#   stall of a loaded machine before that try is no wait), forks, and execs the
#   unit in the child with INT and QUIT as this shell had them and every signal
#   it changed put back. The slot file is close-on-exec, so the unit holds no
#   lock; the kernel drops the holder's lock when the holder goes, however.
#   Its TERM handler exits 143 while it has no child and otherwise returns, and
#   TERM is blocked across the fork so that no unit is made and then orphaned.
# This shell reads the FIFO (held open read-write) with read -t 30 and forks
# nothing while it waits. A wrapper gone without a line is found by kill -0 on a
# silence and ends its unit as one with no mark.
_pj_pl='use Fcntl qw(:flock);
use POSIX ();
my ($dir, $k, $ef, $si, $sq, @cmd) = @ARGV;
my $t0 = time;
my ($pid, $old) = (undef, $SIG{TERM});
$SIG{TERM} = sub { exit 143 unless defined $pid };
my ($got, $w);
SLOT: while (1) {
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
open(my $o, ">", $ef) or exit 2;
print $o $t1, " ", ($w ? $t0 : $t1), "\n";
close $o or exit 2;
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
my $r;
while (1) { $r = waitpid($pid, 0); last if $r == $pid || ($r < 0 && !$!{EINTR}); }
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
# Seed pids on -v seed, "pid ppid" a line on stdin: prints the number of pids
# added, then the seed pids the listing holds with everything below them.
_pj_tw='BEGIN { n = split(seed, S, " "); for (j = 1; j <= n; j++) want[S[j]] = 1 }
{ present[$1] = 1; kid[$2] = kid[$2] " " $1 }
END {
  q = ""; for (j = 1; j <= n; j++) if (S[j] in present) q = q " " S[j]
  out = ""; add = 0
  while (q != "") {
    m = split(q, A, " "); q = ""
    for (j = 1; j <= m; j++) {
      p = A[j]
      if (p == "" || (p in seen)) continue
      seen[p] = 1; out = out " " p
      if (!(p in want)) add++
      q = q kid[p]
    }
  }
  print add out
}'
# One unit's log, as D3 prints it. -v unit, mem (its part files, blank between),
# efail (the FAIL counter its end file holds, -1 when unknown), rc (the holder's
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
  if (l == "@@prelude-done") { if (s == 0) { s = 1; pre(prefail) } else bad = 1; next }
  if (substr(l, 1, 14) == "@@member-done ") {
    j = substr(l, 15)
    if (s == 1 && !mk && (j in idx) && idx[j] > last) { last = idx[j]; done[last] = 1 } else bad = 1
    next
  }
  if (substr(l, 1, 12) == "@@part-done ") {
    if (s == 1 && !mk && substr(l, 13) == mem) mk = 1; else bad = 1
    next
  }
  if (l == "reached") { bad = 1; next }
  if (s == 0) { P[++np] = l; if (substr(l, 1, 8) == "  FAIL  ") prefail = 1; next }
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
  case "$n" in ""|*[!0-9]*) n="$(getconf _NPROCESSORS_ONLN 2>/dev/null)" ;; esac
  case "$n" in ""|*[!0-9]*) n=1 ;; esac
  n="${n#"${n%%[!0]*}"}"
  [ -n "$n" ] || n=1
  [ "${#n}" -le 2 ] || n=64
  [ "$n" -le 64 ] || n=64
  _pj_k="$n"
}
# Makes the slot directory and every slot file, then takes and drops one lock;
# refuses (exit 2, one line) when it cannot, or when a name there is not a
# regular file, which it never opens. -> _pj_sd and _pj_k.
_par_slots() {
  local d="${TMPDIR:-/tmp}/felix-suite-slots" f i=0
  if [ -n "${FELIX_TEST_SLOTS+x}" ]; then
    _sj_n "$FELIX_TEST_SLOTS" || _sj_die "FELIX_TEST_SLOTS is [$FELIX_TEST_SLOTS]: it must be a number from 1 to 64 in plain decimal"
    _pj_k="$FELIX_TEST_SLOTS"
  else
    _par_cores
  fi
  { mkdir -p "$d" && [ -d "$d" ]; } 2>/dev/null || _sj_die "cannot make the slots directory [$d]"
  while [ "$i" -lt "$_pj_k" ]; do
    f="$d/$i"
    if [ -L "$f" ] || { [ -e "$f" ] && [ ! -f "$f" ]; }; then _sj_die "[$f] is not a regular file: the slots directory holds slot files and nothing else"; fi
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
      case "$s" in 0) ;; [1-9]*) case "$s" in *[!0-9]*) continue ;; esac ;; *) continue ;; esac
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
    case "$ix" in ""|*[!0-9]*) continue ;; esac
    _pj_q[k]="$ix"; k=$((k + 1))
  done < <(printf '%s' "$lines" | LC_ALL=C sort -t "$tab" -k1,1 -k2,2r -k3,3n)
  if [ "$k" -ne "$_pj_n" ]; then
    _pj_q=(); i=0
    while [ "$i" -lt "$_pj_n" ]; do _pj_q[i]="$i"; i=$((i + 1)); done
  fi
}
# Unit I's end file (D2, D3) -> _pe_fail, its FAIL counter or -1; and, for 9990
# under -j N, one line a fact in _pj_9fl (floors that read bad), _pj_9rf
# (refusals) and _pj_9om (origin messages), the verdicts counted in _pj_9ob,
# _pj_9os and _pj_9ok. A file that is missing, cut short (no `end` record) or
# without a verdict makes all three bad.
_par_endrec() {
  local nm f l tag txt fl="" fm="" rf="" ov="" om="" n=-1 dn="" good=1 tab=$'\t'
  nm="${_pj_nm[$1]}"; f="$_pj_dir/end.$1"; _pe_fail=-1
  if [ -f "$f" ] && [ -r "$f" ]; then
    while IFS= read -r l || [ -n "$l" ]; do
      case "$l" in *"$tab"*) tag="${l%%"$tab"*}"; txt="${l#*"$tab"}" ;; *) tag="$l"; txt="" ;; esac
      case "$tag" in
        floor)    fl="$txt" ;;
        floormsg) fm="$fm$nm: $txt"$'\n' ;;
        refused)  rf="$rf$nm: $txt"$'\n' ;;
        og)       ov="$txt" ;;
        ogmsg)    om="$om$nm: $txt"$'\n' ;;
        fail)     case "$txt" in ""|*[!0-9]*) ;; *) [ "${#txt}" -gt 9 ] || n="$txt" ;; esac ;;
        end)      dn=1 ;;
      esac
    done < "$f"
  fi
  case "$fl" in ok|bad) ;; *) good="" ;; esac
  case "$ov" in ok|skip|bad) ;; *) good="" ;; esac
  [ "$n" -ge 0 ] && [ "$dn" = 1 ] || good=""
  if [ -z "$good" ]; then
    fl=bad; ov=bad; n=-1
    fm="$nm: it left no readable end file"$'\n'; rf="$fm"; om="$fm"
  fi
  _pe_fail="$n"
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
  case "$ep" in ""|*[!0-9]*) return 0 ;; esac
  case "$st" in ""|*[!0-9]*) st="$ep" ;; esac
  [ "${#ep}" -le 12 ] && [ "${#st}" -le 12 ] || return 0
  now="$(date +%s)"
  case "$now" in ""|*[!0-9]*) return 0 ;; esac
  [ "$now" -lt "$ep" ] || _pj_t[i]=$((now - ep))
  [ "$ep" -lt "$st" ] || _pj_w[i]=$((ep - st))
}
# Prints unit I (D3) and adds what its log holds to PASS, FAIL and SKIP.
_par_show() {
  local i="$1" nm="${_pj_nm[$1]}" note="" a=0 b=0 c=0 d=0 st="$_pj_dir/stats" w
  _par_endrec "$i"
  w="${_pj_w[$i]}"
  if [ "$w" -gt 1 ]; then note="  note  $nm waited $w s for a slot"; fi
  rm -f "$st"
  LC_ALL=C awk -v unit="$nm" -v mem="${_pj_mb[$i]}" -v efail="$_pe_fail" -v rc="${_pj_rc[$i]}" -v note="$note" -v stats="$st" \
    "$_pj_aw" "$_pj_dir/log.$i" 2>/dev/null
  if [ -f "$st" ]; then { read -r a b c d < "$st"; } 2>/dev/null; fi
  case "$a$b$c$d" in
    ""|*[!0-9]*) a=0; b=0; c=0; d=1; printf '  FAIL  part ended without its mark: %s\n' "$nm" ;;
  esac
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
# A line from the FIFO: "UNIT STATUS".
_par_ev() {
  local l="$1" nm st i=0
  nm="${l% *}"; st="${l##* }"
  case "$st" in ""|*[!0-9]*) return 0 ;; esac
  while [ "$i" -lt "$_pj_n" ]; do
    if [ "${_pj_nm[$i]}" = "$nm" ]; then
      [ "${_pj_s[$i]}" = 1 ] || return 0
      _pj_rc[i]="$st"; _par_fin "$i"
      return 0
    fi
    i=$((i + 1))
  done
}
# After 30 s of silence: a wrapper that is gone without a line (killed, say) ends
# its unit as one with no mark. One more second is given to a line that was
# written as the wrapper went.
_par_gone() {
  local i=0 g="" l
  while [ "$i" -lt "$_pj_n" ]; do
    if [ "${_pj_s[$i]}" = 1 ] && ! kill -0 "${_pj_pid[$i]}" 2>/dev/null; then g="$g $i"; fi
    i=$((i + 1))
  done
  [ -n "$g" ] || return 0
  if read -r -t 1 -u 63 l; then _par_ev "$l"; return 0; fi
  for i in $g; do _pj_rc[i]=lost; _par_fin "$i"; done
}
# Starts unit I: a wrapper (see the head of this file) for its holder.
_par_start() {
  local i="$1" nm="${_pj_nm[$1]}" mb="${_pj_mb[$1]}"
  : > "$_pj_dir/log.$i"
  (
    trap 'exit 143' TERM
    cd "${_og_start:-.}" || exit 125
    exec 3>&2 2>/dev/null
    export FELIX_TEST_PART_LOG="$_pj_dir/log.$i" FELIX_TEST_PART_RAN="$_pj_dir/ran.$i" FELIX_TEST_PART_END="$_pj_dir/end.$i"
    [ "$FELIX_TEST_RECORD" != 1 ] || export FELIX_TEST_PART_RECORD=1
    perl -e "$_pj_pl" "$_pj_sd" "$_pj_k" "$_pj_dir/slot.$i" $_pj_sg "$BASH" "$HERE/run" --part $mb 2>&3 3>&- 63>&-
    printf '%s %s\n' "$nm" "$?" >&63
  ) &
  _pj_pid[i]=$!; _pj_s[i]=1
}
# The ending (D6): every wrapper still running, with all that runs below it, is
# asked to end, given up to 10 s, then listed again with everything below every
# pid held so far (a child moved to pid 1 and what it forked since), stopped, and
# listed again until a listing adds nothing, then killed; and every wrapper is
# waited for, so that each unit is reaped before this shell goes. Slots are not
# touched: each holder's lock goes with it.
_par_end() {
  local i=0 r="" held out add p n=0
  while [ "$i" -lt "${_pj_n:-0}" ]; do
    [ "${_pj_s[$i]:-0}" != 1 ] || r="$r ${_pj_pid[$i]}"
    i=$((i + 1))
  done
  [ -n "$r" ] || return 0
  out="$(ps -A -o pid=,ppid= 2>/dev/null | LC_ALL=C awk -v seed="$r" "$_pj_tw")"
  set -- $out; [ "$#" -eq 0 ] || shift; held="$*"
  for p in $held $r; do kill -TERM "$p" 2>/dev/null; done
  while [ "$n" -lt 50 ]; do
    out=""; for p in $r; do ! kill -0 "$p" 2>/dev/null || out=1; done
    [ -n "$out" ] || break
    sleep 0.2; n=$((n + 1))
  done
  n=0
  while [ "$n" -lt 30 ]; do
    out="$(ps -A -o pid=,ppid= 2>/dev/null | LC_ALL=C awk -v seed="$held" "$_pj_tw")"
    set -- $out; add="${1:-0}"; [ "$#" -eq 0 ] || shift; held="$*"
    for p in $held; do kill -STOP "$p" 2>/dev/null; done
    [ "$add" -gt 0 ] || break
    n=$((n + 1))
  done
  for p in $held $r; do kill -KILL "$p" 2>/dev/null; done
  for p in $r; do { wait "$p"; } 2>/dev/null; done
  i=0
  while [ "$i" -lt "$_pj_n" ]; do [ "${_pj_s[$i]}" != 1 ] || _pj_s[i]=9; i=$((i + 1)); done
}
_par_sig() { trap '' INT TERM HUP; _par_end; exit "$1"; }
# The runner. Under -j N the driver calls it after the prelude; it leaves, for
# 9990, _pj_9fl, _pj_9rf, _pj_9om and _pj_9ob/_pj_9os/_pj_9ok, adds the units'
# ran files to $FELIX_TEST_RAN and their counts to PASS, FAIL and SKIP, writes
# the durations (D4), and ends with _par_done=1. A record run with any runner
# failure writes the mark `failed` and exits 1 here, before 9990 (D4).
_par_run() {
  local i p l def
  _pj_dir="$TMP/pj"; _pj_rfn=0; _pj_pr=0; _pj_qi=0; _pj_run=0; _pj_s=(); _pj_pid=(); _pj_rc=(); _pj_t=(); _pj_w=()
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
  trap '_par_sig 130' INT; trap '_par_sig 143' TERM; trap '_par_sig 129' HUP
  while [ "$_pj_pr" -lt "$_pj_n" ]; do
    while [ "$_pj_run" -lt "$_suite_jobs" ] && [ "$_pj_qi" -lt "$_pj_n" ]; do
      _par_start "${_pj_q[$_pj_qi]}"
      _pj_qi=$((_pj_qi + 1)); _pj_run=$((_pj_run + 1))
    done
    _par_flush
    [ "$_pj_pr" -lt "$_pj_n" ] || break
    if read -r -t 30 -u 63 l; then _par_ev "$l"; else _par_gone; fi
  done
  exec 63>&-
  trap - INT TERM HUP
  if [ "$_pj_rfn" -gt 0 ] && [ "$FELIX_TEST_RECORD" = 1 ]; then
    [ -z "${_rcp_red:-}" ] || _rcp_mark failed "$TMP/manifest.mark"
    exit 1
  fi
  if [ "$_pj_rfn" -eq 0 ] && [ -n "$_pj_df" ] && [ ! -L "$_pj_df" ] && { [ ! -e "$_pj_df" ] || [ -f "$_pj_df" ]; }; then
    {
      i=0
      while [ "$i" -lt "$_pj_n" ]; do printf '%s\t%s\n' "${_pj_t[$i]:-0}" "${_pj_nm[$i]}"; i=$((i + 1)); done
    } > "$_pj_df.tmp.$$" 2>/dev/null && mv -f "$_pj_df.tmp.$$" "$_pj_df" 2>/dev/null || rm -f "$_pj_df.tmp.$$" 2>/dev/null
  fi
  cat "$_pj_dir"/ran.* >> "$FELIX_TEST_RAN" 2>/dev/null
  _par_done=1
}
