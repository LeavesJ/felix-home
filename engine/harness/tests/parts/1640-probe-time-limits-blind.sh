# >>> probe-time-limits-blind
printf '\ntime limits on probe, when, witness, applies and evidence commands (audit b01, blind)\n'
# Blind, written on 2026-10-24 from the contract alone (docs/2026-10-24-audit-fixes/b01-time-limits-on-suite-gate-ci-and-probe-c.md,
# B14 to B20, assertions A21 to A40). No engine file was read: lib/probes.sh, lib/obligations.sh and lib/epoch.sh are only sourced and called.
# Every call runs in a fresh bash (call.sh) that sources the harness's lib/resolve.sh, detect.sh, probes.sh, facts.sh and obligations.sh, as
# tests/lib/probes.sh's _ob does (and verify.sh and epoch.sh for the epoch), under the callers' set -uo pipefail, and that bash runs under this
# part's own bounded runner (run.pl): it forks, the child makes a process group of its own and execs, and at T seconds the parent sends that group
# KILL and exits 124. So against an engine without the limits a hanging case fails at T and does not hang. T is 20 unless a case says otherwise.
# Every call points TMPDIR at a directory of this part's own. Nothing is ended by pattern: a marker process writes its own process group to a
# file before it sleeps, and a group a marker left alive is sent KILL by its id once the case has judged it; a run's own group is listed after
# the call and what is left in it is sent CONT and KILL by pid.
# Readings taken where the contract leaves room. A marker is `perl mark.pl MODE PGFILE fx-p-X-PID` (one perl that sleeps 300 s, carrying the
# tag on its command line), where the contract writes `perl -e 'sleep 300' fx-p-X-$$`: the same process, and it can say its group. A21's
# calling shell holds a trap (USR2) and a job (a sleep 30) of its own before the call, so that its traps and job table are not empty when they are
# compared. A36 gives the call a stdin that is a pipe nobody writes or closes, held by the runner, so a probe that inherited it would hang.
# A39's marker is `sh -c 'ps -o pgid= -p $$ >> PGFILE; sleep 300; :' fx-p-H-PID`, with the contract's sh, sleep and tag.
PVL="$TMP/pvl"; PVID="$$"; PVC="$PVL/c"
rm -rf "$PVL"; mkdir -p "$PVL/r" "$PVC" "$PVL/td" "$PVL/fake"
_pv_perl="$(command -v perl)"; _pv_E=(); _pv_T=20; _pv_in=-; _pv_snap=-; _pv_g=ok; _pv_el=0; _pv_rc=0
cat > "$PVL/run.pl" <<'PVLRUN'
# run.pl T PIDFILE STDIN CMD...: CMD in a process group of its own, whose id goes to PIDFILE, with INT QUIT HUP and TERM at their defaults and
# stdin inherited (-) or a pipe this process holds open and never writes (pipe). At T seconds the group is sent KILL and the exit is 124.
my ($t, $f, $in) = splice(@ARGV, 0, 3);
my ($r, $w); if ($in eq "pipe") { pipe($r, $w) or exit 125 }
my $p = fork; defined $p or exit 125;
if (!$p) {
  setpgrp(0, 0); $SIG{$_} = "DEFAULT" for qw(INT QUIT HUP TERM);
  if ($in eq "pipe") { close $w; open(STDIN, "<&", $r) or exit 125; close $r }
  if (open(my $h, ">", $f)) { print $h "$$\n"; close $h }
  exec @ARGV; exit 127;
}
close $r if $in eq "pipe";
$SIG{ALRM} = sub { kill "KILL", -$p; exit 124 };
alarm $t; waitpid $p, 0;
exit(($? & 127) ? 128 + ($? & 127) : $? >> 8);
PVLRUN
cat > "$PVL/call.sh" <<'PVLCALL'
# call.sh LIBDIR SNAP SNIPPET ARG...: the libraries a caller loads, then SNIPPET, with ARG... as $1 on, under the callers' set -uo pipefail.
# With SNAP not -, a USR2 trap and a background sleep are set first, and the options, traps and jobs are written to SNAP.before and SNAP.after.
set -uo pipefail
pv_l="$1"; pv_s="$2"; pv_x="$3"; shift 3
. "$pv_l/resolve.sh"; . "$pv_l/detect.sh"; . "$pv_l/probes.sh"; . "$pv_l/facts.sh"; . "$pv_l/obligations.sh"
[ "${PV_EPOCH:-0}" != 1 ] || { . "$pv_l/verify.sh"; . "$pv_l/epoch.sh"; }
if [ "$pv_s" != - ]; then trap 'printf "pv-usr2\n"' USR2; sleep 30 & pv_j=$!; { set +o; trap -p; jobs -p; } > "$pv_s.before"; fi
eval "$pv_x"; pv_rc=$?
if [ "$pv_s" != - ]; then { set +o; trap -p; jobs -p; } > "$pv_s.after"; kill "$pv_j" 2>/dev/null; { wait "$pv_j"; } 2>/dev/null; fi
exit "$pv_rc"
PVLCALL
cat > "$PVL/mark.pl" <<'PVLMARK'
# mark.pl MODE PGFILE TAG: appends its process group to PGFILE, then sleeps 300 s. MODE f forks first, and both sleep; MODE e forks, and the
# parent prints m and exits while the child sleeps with stdout still open.
my ($m, $pg) = @ARGV;
if (open(my $h, ">>", $pg)) { print $h getpgrp(), "\n"; close $h }
if ($m eq "f") { fork }
elsif ($m eq "e") { $| = 1; if (fork) { print "m\n"; exit 0 } }
sleep 300;
PVLMARK
for _pv_x in perl python3 timeout gtimeout; do printf '#!/bin/sh\nexit 1\n' > "$PVL/fake/$_pv_x"; chmod +x "$PVL/fake/$_pv_x"; done
( _fx_cd "$PVL/r" && git init -q -b main && printf 'a\n' > a.txt && printf 'b\n' > b.txt && git add a.txt b.txt \
  && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm seed ) >/dev/null 2>&1
PVR="$(cd "$PVL/r" && pwd -P)"
_pv_ms()  { perl -MTime::HiRes=time -e 'printf "%d", time * 1000'; }
_pv_m()   { printf 'perl %s %s %s fx-p-%s-%s' "$PVL/mark.pl" "$1" "$PVL/pg" "$2" "$PVID"; }   # MODE LETTER: the marker command
_pv_row() { printf '%s\t%s\t%s' "$1" "$2" "$3"; }
_pv_show() { LC_ALL=C awk 'NR <= 6 { gsub(/\t/, "\\t"); printf "%s|", substr($0, 1, 200) }' "$PVL/$1" 2>/dev/null; }
_pv_gm()  { ps -A -o pid= -o pgid= -o stat= -o command= 2>/dev/null | G=" $* " LC_ALL=C awk 'index(ENVIRON["G"], " " $2 " ") && $3 !~ /^Z/ { c = $0; sub(/^ *[0123456789]+ +[0123456789]+ +[^ ]+ +/, "", c); print $1 " " substr(c, 1, 60) }'; }
# MARK: "none" once no live process carries MARK on its command line (2 s at most), else their pids
_pv_left() {
  local i=0 l
  while :; do
    l="$(ps -A -o pid= -o stat= -o command= 2>/dev/null | K="$1" LC_ALL=C awk 'index($0, ENVIRON["K"]) && $2 !~ /^Z/ { printf "%s ", $1 }')"
    [ -n "$l" ] || { printf none; return 0; }
    [ "$i" -lt 10 ] || break; sleep 0.2; i=$((i + 1))
  done
  printf 'left alive: %s' "$l"
}
# The groups markers reported that still hold a live process are sent KILL by their id (never this shell's own group)
_pv_reap() {
  local g me; me="$(ps -o pgid= -p "$$" 2>/dev/null | tr -d ' ')"
  [ -s "$PVL/pg" ] || return 0
  for g in $(tr -d ' ' < "$PVL/pg" | LC_ALL=C sort -u); do
    case "$g" in ''|*[!0123456789]*) continue ;; esac
    [ "$g" -gt 1 ] && [ "$g" != "$me" ] || continue
    [ -z "$(_pv_gm "$g")" ] || perl -e 'kill "KILL", -$ARGV[0]' "$g"
  done
  : > "$PVL/pg"
}
# LABEL SNIPPET ARG...: one call under the bounded runner, with _pv_E in its environment; _pv_rc, _pv_el (ms), $PVL/LABEL.out and .err;
# _pv_g "ok" when the runner's group held no live process within 2 s of the return, else what was left (then sent CONT and KILL by pid)
_pv_go() {
  local l="$1" t0 g i=0 x p; shift
  t0="$(_pv_ms)"
  env -u FELIX_PROBE_LIMIT -u FELIX_EVIDENCE_LIMIT -u PV_EPOCH TMPDIR="$PVL/td" ${_pv_E[@]+"${_pv_E[@]}"} \
    "$_pv_perl" "$PVL/run.pl" "$_pv_T" "$PVL/$l.pid" "$_pv_in" "$BASH" "$PVL/call.sh" "$FROOT/harness/lib" "$_pv_snap" "$@" \
    > "$PVL/$l.out" 2> "$PVL/$l.err"
  _pv_rc=$?; _pv_el="$(( $(_pv_ms) - t0 ))"
  _pv_E=(); _pv_T=20; _pv_in=-; _pv_snap=-; _pv_g=ok
  g="$(cat "$PVL/$l.pid" 2>/dev/null)"; [ -n "$g" ] || return 0
  while x="$(_pv_gm "$g")"; [ -n "$x" ] && [ "$i" -lt 10 ]; do sleep 0.2; i=$((i + 1)); done
  [ -n "$x" ] || return 0
  _pv_g="its group kept: $(printf '%s' "$x" | tr '\n' ';')"
  for p in $(printf '%s\n' "$x" | awk '{ print $1 }'); do kill -CONT "$p" 2>/dev/null; kill -KILL "$p" 2>/dev/null; done
}
# NAME LETTER WANT RAN SNIPPET ARG...: the call must print exactly WANT within _pv_lim ms (7 s), leave no process carrying marker LETTER
# after 2 s, and never make the case file RAN (- for none)
_pv_lim=7000
_pv_hang() {
  local n="$1" c="$2" k="fx-p-$2-$PVID" w="$3" f="$4" r="" x; shift 4
  _pv_go "h$c" "$@"
  [ "$_pv_el" -le "$_pv_lim" ] || r="$r it returned after $_pv_el ms (exit $_pv_rc);"
  _pv_lim=7000
  [ "$(cat "$PVL/h$c.out" 2>/dev/null)" = "$w" ] || r="$r it printed [$(_pv_show "h$c.out")];"
  [ "$f" = - ] || [ ! -e "$PVC/$f" ] || r="$r $f was made, so that command ran;"
  x="$(_pv_left "$k")"; [ "$x" = none ] || r="$r marker $c $x;"
  [ "$_pv_g" = ok ] || r="$r $_pv_g;"
  _pv_reap; rm -f "$PVC"/*.ran
  is "$n" "${r:-ok}" ok
}
_pv_ps='felix_probe_state "$1" "$2" "$3" "$4"'; _pv_os='felix_obligation_state "$1" "$2" "$3"'
_pv_bad='is set to something that is not a whole number of seconds from 1 to 3600'

# ---- a command past its limit (B15, B19)
_pv_E=(FELIX_PROBE_LIMIT=2); _pv_snap="$PVL/a21"
_pv_go a21 'set -uo pipefail; '"$_pv_ps" "$PVR" - "$(_pv_m s A)" "touch $PVC/wit.ran"
_pv_r=""
[ "$_pv_el" -le 7000 ] || _pv_r="$_pv_r it returned after $_pv_el ms (exit $_pv_rc);"
[ "$(cat "$PVL/a21.out" 2>/dev/null)" = "$(_pv_row unknown 0 'the probe ran past its limit of 2 s and was ended, so its enumeration is not known')" ] || _pv_r="$_pv_r it printed [$(_pv_show a21.out)];"
[ ! -s "$PVL/a21.err" ] || _pv_r="$_pv_r stderr [$(_pv_show a21.err)];"
[ ! -e "$PVC/wit.ran" ] || _pv_r="$_pv_r the witness ran;"
_pv_x="$(_pv_left "fx-p-A-$PVID")"; [ "$_pv_x" = none ] || _pv_r="$_pv_r marker A $_pv_x;"
if [ -s "$PVL/a21.before" ] && [ -f "$PVL/a21.after" ]; then
  cmp -s "$PVL/a21.before" "$PVL/a21.after" || _pv_r="$_pv_r the calling shell changed: [$(LC_ALL=C diff "$PVL/a21.before" "$PVL/a21.after" | sed -n '2,5p' | tr '\n' '|')];"
else _pv_r="$_pv_r no options, traps and jobs were read after the call;"; fi
[ "$_pv_g" = ok ] || _pv_r="$_pv_r $_pv_g;"
_pv_reap; rm -f "$PVC"/*.ran
is "time limits A21 (B15, B19): with FELIX_PROBE_LIMIT=2, under set -uo pipefail, a probe that hangs returns within 7 s as exactly unknown, 0, 'the probe ran past its limit of 2 s and was ended, so its enumeration is not known', says nothing on stderr, runs no witness, leaves no process of it after 2 s, and leaves the calling shell's options, traps and jobs as they were" "${_pv_r:-ok}" ok
_pv_E=(FELIX_PROBE_LIMIT=2)
_pv_hang "time limits A22 (B15): a \`when\` command that hangs is ended within 7 s, the row reads unknown, 0, 'the \`when\` command ran past its limit of 2 s and was ended, so whether this row applies is not known', and the probe behind it is not run" \
  B "$(_pv_row unknown 0 'the `when` command ran past its limit of 2 s and was ended, so whether this row applies is not known')" probe.ran \
  "$_pv_ps" "$PVR" "$(_pv_m s B)" "touch $PVC/probe.ran; echo x" "test -d ."
_pv_E=(FELIX_PROBE_LIMIT=2)
_pv_hang "time limits A23 (B15): a witness that hangs behind a probe that found nothing is ended within 7 s, and the row reads unknown, 0, 'the witness ran past its limit of 2 s and was ended, so absent and blind cannot be told apart'" \
  C "$(_pv_row unknown 0 'the witness ran past its limit of 2 s and was ended, so absent and blind cannot be told apart')" - \
  "$_pv_ps" "$PVR" - true "$(_pv_m s C)"
_pv_E=(FELIX_PROBE_LIMIT=2)
_pv_hang "time limits A24 (B15): a probe that prints a member and then forks and hangs reads the probe row with count 0 within 7 s, and neither the hung process nor its fork is left after 2 s" \
  D "$(_pv_row unknown 0 'the probe ran past its limit of 2 s and was ended, so its enumeration is not known')" - \
  "$_pv_ps" "$PVR" - "echo member; $(_pv_m f D)" "test -d ."
_pv_E=(FELIX_PROBE_LIMIT=2)
_pv_hang "time limits A25 (B15): a probe whose own process exits while a child it left holds its stdout open counts as past its limit: the probe row within 7 s, and the child is not left after 2 s" \
  E "$(_pv_row unknown 0 'the probe ran past its limit of 2 s and was ended, so its enumeration is not known')" - \
  "$_pv_ps" "$PVR" - "$(_pv_m e E)" "test -d ."
mkdir -p "$PVL/p26"; { printf 'hang\t-\t-\t%s\ttest -d .\n' "$(_pv_m s J)"; printf 'files\t-\t-\tgit ls-files\ttest -e .git\n'; } > "$PVL/p26/probes.tsv"
_pv_E=(FELIX_PROBE_LIMIT=2); _pv_lim=10000
_pv_hang "time limits A26 (B15): in a table with a row whose probe hangs and a row that finds its members, felix_probes_run piped to felix_probes_blocking lists exactly the hanging row's predicate, within 10 s" \
  J hang - 'felix_probes_run "$1" "$2" | felix_probes_blocking | cut -f1' "$PVL/p26" "$PVR"

# ---- the probe limit itself (B14, B16)
_pv_T=60; _pv_go a27 "$_pv_ps" "$PVR" - "sleep 40; echo x" "test -d ."
_pv_r=""
[ "$_pv_el" -ge 25000 ] && [ "$_pv_el" -le 38000 ] || _pv_r="$_pv_r it returned after $_pv_el ms (exit $_pv_rc);"
case "$(cat "$PVL/a27.out" 2>/dev/null)" in *"30 s"*) ;; *) _pv_r="$_pv_r it printed [$(_pv_show a27.out)];" ;; esac
[ "$_pv_g" = ok ] || _pv_r="$_pv_r $_pv_g;"
is "time limits A27 (B14): with FELIX_PROBE_LIMIT unset a probe of sleep 40 is ended at the default of 30 s: the call returns after 25 s and within 38 s, and its detail names 30 s" "${_pv_r:-ok}" ok
_pv_E=("FELIX_PROBE_LIMIT="); _pv_go a28 "$_pv_ps" "$PVR" - "echo x" "test -d ."
is "time limits A28 (B14; control): FELIX_PROBE_LIMIT set and empty is the default, so a probe that answers reads found, 1, '1 member(s) enumerated'" \
   "$(cat "$PVL/a28.out" 2>/dev/null) $_pv_g" "$(_pv_row found 1 '1 member(s) enumerated') ok"
_pv_r=""
for _pv_v in 0 07 3601 abc 1.5 -1 '2 '; do
  _pv_E=("FELIX_PROBE_LIMIT=$_pv_v"); _pv_go a29 "$_pv_ps" "$PVR" "touch $PVC/when.ran" "touch $PVC/probe.ran; echo x" "touch $PVC/wit.ran"
  [ "$(cat "$PVL/a29.out" 2>/dev/null)" = "$(_pv_row unknown 0 "FELIX_PROBE_LIMIT $_pv_bad, so nothing was run")" ] || _pv_r="$_pv_r [$_pv_v] printed [$(_pv_show a29.out)];"
  for _pv_x in when probe wit; do [ ! -e "$PVC/$_pv_x.ran" ] || _pv_r="$_pv_r [$_pv_v] ran its $_pv_x command;"; done
  [ "$_pv_g" = ok ] || _pv_r="$_pv_r [$_pv_v] $_pv_g;"
  rm -f "$PVC"/*.ran
done
is "time limits A29 (B16): FELIX_PROBE_LIMIT set to 0, 07, 3601, abc, 1.5, -1 or '2 ' runs nothing of the row, not even its \`when\`, and the row reads unknown, 0, 'FELIX_PROBE_LIMIT $_pv_bad, so nothing was run', with no value echoed" "${_pv_r:-ok}" ok

# ---- obligations: applies and evidence (B15, B16, B17)
_pv_E=(FELIX_PROBE_LIMIT=2)
_pv_hang "time limits A30 (B15): an obligation's applies command that hangs is ended within 7 s, the row reads UNKNOWN, UNKNOWN, 'the applies command ran past its limit of 2 s and was ended, so whether this applies is not known', and its evidence is not run" \
  F "$(_pv_row UNKNOWN UNKNOWN 'the applies command ran past its limit of 2 s and was ended, so whether this applies is not known')" ev.ran \
  "$_pv_os" "$PVR" "$(_pv_m s F)" "touch $PVC/ev.ran"
mkdir -p "$PVL/p31"; printf 'hold\tRELEASE_BLOCKING\tdeterministic\t%s\ttrue\t-\ta row whose applies hangs\n' "$(_pv_m s K)" > "$PVL/p31/obligations.tsv"
_pv_E=(FELIX_PROBE_LIMIT=2); _pv_go a31 'felix_obligations_run "$1" "$2" release | felix_obligations_blocking release' "$PVL/p31" "$PVR"
_pv_r=""
[ "$_pv_el" -le 10000 ] || _pv_r="$_pv_r it returned after $_pv_el ms (exit $_pv_rc);"
[ "$(LC_ALL=C awk -F'\t' '$1 == "hold" && index($0, "UNKNOWN") { n++ } END { print n + 0 }' "$PVL/a31.out" 2>/dev/null)" -ge 1 ] || _pv_r="$_pv_r it listed [$(_pv_show a31.out)];"
_pv_x="$(_pv_left "fx-p-K-$PVID")"; [ "$_pv_x" = none ] || _pv_r="$_pv_r marker K $_pv_x;"
[ "$_pv_g" = ok ] || _pv_r="$_pv_r $_pv_g;"
_pv_reap
is "time limits A31 (B15): a RELEASE_BLOCKING obligation whose applies command hangs is listed by felix_obligations_blocking release with UNKNOWN, within 10 s" "${_pv_r:-ok}" ok
_pv_E=(FELIX_PROBE_LIMIT=abc); _pv_go a32 "$_pv_os" "$PVR" "touch $PVC/ap.ran" true
is "time limits A32 (B16): with FELIX_PROBE_LIMIT=abc an obligation's applies command is not run, and the row reads UNKNOWN, UNKNOWN, 'FELIX_PROBE_LIMIT $_pv_bad, so nothing was run'" \
   "$(cat "$PVL/a32.out" 2>/dev/null) $([ -e "$PVC/ap.ran" ] && echo applies-ran || echo applies-not-run) $_pv_g" \
   "$(_pv_row UNKNOWN UNKNOWN "FELIX_PROBE_LIMIT $_pv_bad, so nothing was run") applies-not-run ok"
rm -f "$PVC"/*.ran
_pv_E=(FELIX_EVIDENCE_LIMIT=2)
_pv_hang "time limits A33 (B17): with FELIX_EVIDENCE_LIMIT=2 evidence that hangs is ended within 7 s, the row reads ACTIVE, UNKNOWN, 'the evidence ran past its limit of 2 s and was ended, so nothing was examined', and no process of it is left after 2 s" \
  G "$(_pv_row ACTIVE UNKNOWN 'the evidence ran past its limit of 2 s and was ended, so nothing was examined')" - \
  "$_pv_os" "$PVR" - "$(_pv_m s G)"
_pv_E=(FELIX_EVIDENCE_LIMIT=0); _pv_go a34 "$_pv_os" "$PVR" - "touch $PVC/ev.ran"
is "time limits A34 (B17): with FELIX_EVIDENCE_LIMIT=0 the evidence is not run, and the row reads ACTIVE, UNKNOWN, 'FELIX_EVIDENCE_LIMIT $_pv_bad, so the evidence was not run'" \
   "$(cat "$PVL/a34.out" 2>/dev/null) $([ -e "$PVC/ev.ran" ] && echo evidence-ran || echo evidence-not-run) $_pv_g" \
   "$(_pv_row ACTIVE UNKNOWN "FELIX_EVIDENCE_LIMIT $_pv_bad, so the evidence was not run") evidence-not-run ok"
rm -f "$PVC"/*.ran

# ---- commands that end in time read as they did (B18, B19; controls)
_pv_r=""; _pv_wb='the witness proves this surface exists and the probe'
_pv_a35() {   # PROBE WANT
  _pv_E=(FELIX_PROBE_LIMIT=5); _pv_go a35 "$_pv_ps" "$PVR" - "$1" "test -d ."
  [ "$(cat "$PVL/a35.out" 2>/dev/null)" = "$2" ] || _pv_r="$_pv_r [$1] printed [$(_pv_show a35.out)];"
  [ "$_pv_g" = ok ] || _pv_r="$_pv_r [$1] $_pv_g;"
}
for _pv_v in 1 2 3 124 128 137 142 143; do _pv_a35 "exit $_pv_v" "$(_pv_row blind 0 "$_pv_wb exited $_pv_v")"; done
_pv_a35 'kill -TERM $$' "$(_pv_row blind 0 "$_pv_wb exited 143")"
_pv_a35 'exit 127' "$(_pv_row unknown 0 'a command in the probe does not exist here, so nothing could be looked at')"
_pv_a35 true "$(_pv_row blind 0 "$_pv_wb enumerated none of it")"
_pv_a35 'echo m' "$(_pv_row found 1 '1 member(s) enumerated')"
_pv_a35 'echo m; exit 3' "$(_pv_row unknown 1 'the probe printed 1 member(s) and then exited 3, so the enumeration is partial')"
is "time limits A35 (B18; control): with FELIX_PROBE_LIMIT=5 and a witness that holds, a probe that ends in time reads as before: exit 1, 2, 3, 124, 128, 137, 142, 143 and a real TERM are blind with that status, 127 is unknown for a missing command, none found is blind, a member is found, and a member then exit 3 is partial" "${_pv_r:-ok}" ok
_pv_in=pipe; _pv_go a36 "$_pv_ps" "$PVR" - cat "test -d ."
is "time limits A36 (B18; control): a probe of cat, whose caller's stdin is a pipe nobody closes, still reads /dev/null: it returns within 5 s as blind, 'enumerated none of it'" \
   "$(cat "$PVL/a36.out" 2>/dev/null) $([ "$_pv_el" -le 5000 ] && echo in-time || echo "after $_pv_el ms") $_pv_g" "$(_pv_row blind 0 "$_pv_wb enumerated none of it") in-time ok"
mkdir -p "$PVL/p37"
{ printf 'files\t-\t-\tgit ls-files\ttest -e .git\n'; printf 'rust\t-\t-\tgit ls-files "*.rs"\ttest -f Cargo.toml\n'
  printf 'cargo\t-\ttest -f Cargo.toml\tls\ttest -d .\n'; } > "$PVL/p37/probes.tsv"
_pv_go a37 'felix_probes_run "$1" "$2" | cut -f1-6' "$PVL/p37" "$PVR"
is "time limits A37 (B18; control): felix_probes_run's fields 1 to 6 for a found, an empty and a not-applicable row are byte for byte what they were, so no epoch moves" \
   "$(cat "$PVL/a37.out" 2>/dev/null)" \
   "$(printf 'files\t-\tfound\t2\t2 member(s) enumerated\tgit ls-files\nrust\t-\tempty\t0\tthe probe found nothing and the witness agrees the surface is absent\tgit ls-files "*.rs"\ncargo\t-\tnot-applicable\t0\tthe `when` command says this does not apply here\tls')"
mkdir -p "$PVL/p38"; for _pv_v in 1 2 3 4 5 6 7 8 9 10; do printf 'r%s\t-\t-\techo m\ttest -d .\n' "$_pv_v"; done > "$PVL/p38/probes.tsv"
_pv_E=(FELIX_PROBE_LIMIT=2917); _pv_go a38 'felix_probes_run "$1" "$2"' "$PVL/p38" "$PVR"
_pv_r=""; [ "$_pv_el" -le 5000 ] || _pv_r="$_pv_r it returned after $_pv_el ms;"; [ ! -s "$PVL/a38.err" ] || _pv_r="$_pv_r stderr [$(_pv_show a38.err)];"
_pv_i=0
while _pv_x="$(ps -A -o pid= -o stat= -o command= 2>/dev/null | LC_ALL=C awk '$2 !~ /^Z/ { p = $1; c = $0; sub(/^ *[0123456789]+ +[^ ]+ +/, "", c); sub(/ +$/, "", c); if (c == "sleep 2917") printf "%s ", p }')"
      [ -n "$_pv_x" ] && [ "$_pv_i" -lt 10 ]; do sleep 0.2; _pv_i=$((_pv_i + 1)); done
[ -z "$_pv_x" ] || _pv_r="$_pv_r sleep 2917 still running as [$_pv_x];"; [ "$_pv_g" = ok ] || _pv_r="$_pv_r $_pv_g;"
is "time limits A38 (B19; control): with FELIX_PROBE_LIMIT=2917 a table of ten rows whose commands end at once returns within 5 s, says nothing on stderr, and leaves no sleep 2917 after 2 s" "${_pv_r:-ok}" ok
_pv_E=(PATH="$PVL/fake:$PATH" FELIX_PROBE_LIMIT=2)
_pv_hang "time limits A39 (B19): with perl, python3, timeout and gtimeout on PATH all failing, a probe of sh -c 'sleep 300; :' is still ended: the probe row within 7 s, and no process of it left after 2 s" \
  H "$(_pv_row unknown 0 'the probe ran past its limit of 2 s and was ended, so its enumeration is not known')" - \
  "$_pv_ps" "$PVR" - "sh -c 'ps -o pgid= -p \$\$ >> $PVL/pg; sleep 300; :' fx-p-H-$PVID" "test -d ."

# ---- the epoch at Stop (B20)
mkdir -p "$PVL/p40"; printf 'slow\t-\t-\t"%s/maybe"\ttest -d .\n' "$PVC" > "$PVL/p40/probes.tsv"
printf '#!/bin/sh\n[ -e "%s/hang" ] || { echo m; exit 0; }\nexec %s\n' "$PVC" "$(_pv_m s I)" > "$PVC/maybe"; chmod +x "$PVC/maybe"
_pv_E=(FELIX_PROBE_LIMIT=2 PV_EPOCH=1); _pv_go a40a 'felix_epoch_topology "$1" "$2"' "$PVL/p40" "$PVR"; _pv_t1="$(cat "$PVL/a40a.out" 2>/dev/null)"; _pv_g1="$_pv_g"
: > "$PVC/hang"
_pv_E=(FELIX_PROBE_LIMIT=2 PV_EPOCH=1); _pv_go a40b 'felix_epoch_topology "$1" "$2"' "$PVL/p40" "$PVR"; _pv_t2="$(cat "$PVL/a40b.out" 2>/dev/null)"
_pv_r=""
[ -n "$_pv_t1" ] || _pv_r="$_pv_r the answering table gave no value;"
[ "$_pv_el" -le 12000 ] || _pv_r="$_pv_r the hanging call returned after $_pv_el ms (exit $_pv_rc);"
[ -n "$_pv_t2" ] || _pv_r="$_pv_r the hanging table gave no value;"
[ -z "$_pv_t2" ] || [ "$_pv_t2" != "$_pv_t1" ] || _pv_r="$_pv_r the value did not move;"
_pv_x="$(_pv_left "fx-p-I-$PVID")"; [ "$_pv_x" = none ] || _pv_r="$_pv_r marker I $_pv_x;"
[ "$_pv_g1 $_pv_g" = "ok ok" ] || _pv_r="$_pv_r $_pv_g1 $_pv_g;"
_pv_reap
is "time limits A40 (B20): with FELIX_PROBE_LIMIT=2 felix_epoch_topology over a project whose one probe hangs returns within 12 s, with a value that is not empty and differs from the value it gives when that probe answers" "${_pv_r:-ok}" ok

rm -rf "$PVL"
unset -f $(compgen -A function _pv_) 2>/dev/null
unset $(compgen -A variable _pv_) PVL PVID PVC PVR 2>/dev/null
# <<< probe-time-limits-blind
