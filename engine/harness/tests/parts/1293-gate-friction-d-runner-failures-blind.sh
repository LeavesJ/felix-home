# >>> gate-friction-d-runner-failures-blind
printf '\ngate friction D: a unit that goes wrong, what that does to a run and to a record run, and the gate (blind, revision 7)\n'
# Blind, written from contract D revision 7 alone (docs/2026-10-18-gate-friction-
# contract-d.md: D3, D4, D8, R1, R7, R8, R12). Nothing here was read off an
# implementation; tests/run, tests/red and tests/receipt.sh are run, never read,
# in copies of this suite that _suite_copy_tree (part 0003) makes under $TMP, each
# with planted parts of this block's own. Every case points TMPDIR at a fixture
# directory, runs every inner run under a bounded runner that makes its own
# process group and resets INT, QUIT, HUP and TERM, and ends by asking that
# group to hold no live process, stopped or running (zombies aside), for 30 s;
# what is left is named, then sent CONT and KILL by pid. Nothing is killed by
# pattern. Names say the clause: D3 the runner's failures and the log, D4 the
# record, R1 red's tree, R7 the log's shape, R8 the shell a unit leaves.
# An assertion whose name ends in (control) passes before D is built on purpose.
DB3="$TMP/db3"
mkdir -p "$DB3/pp/std" "$DB3/n"
_db3_E=(); _db3_INT=DEFAULT; _db3_QUIT=DEFAULT; _db3_ctl=0; _db3_ctlr=0; _db3_pf=(); _db3_cl=ok; _db3_ex=ok; _db3_leak=""; _db3_skip=""; _db3_hook=""; _db3_post=""; _db3_postn=""
cat > "$DB3/run.pl" <<'DB3PL'
my ($t, $i, $q, $f) = splice(@ARGV, 0, 4);
my $p = fork; defined $p or exit 125;
if (!$p) { setpgrp(0, 0); $SIG{INT} = $i; $SIG{QUIT} = $q; $SIG{HUP} = 'DEFAULT'; $SIG{TERM} = 'DEFAULT'; if (open(my $h, ">", $f)) { print $h "$$\n"; close $h } exec @ARGV; exit 127 }
$SIG{ALRM} = sub { kill "KILL", -$p; exit 124 };
alarm $t; waitpid $p, 0;
exit(($? & 127) ? 128 + ($? & 127) : $? >> 8);
DB3PL
: > "$DB3/g-empty.tsv"; printf '1\tdjx a1\n' > "$DB3/man.tsv"
_db3_until() { local n="$1" i=0; shift; while [ "$i" -lt "$n" ]; do "$@" && return 0; sleep 0.2; i=$((i + 1)); done; "$@"; }
_db3_cnt()  { LC_ALL=C awk -v p="$2" 'index($0, p) == 1 { n++ } END { print n + 0 }' "$1" 2>/dev/null; }   # FILE PREFIX: lines starting with it
_db3_line() { grep -cxF -e "$2" "$1" 2>/dev/null; }   # FILE LINE: lines that are exactly it
# The members of the process groups $* that are not zombies, one a line: PID STAT COMMAND.
_db3_gm() { ps -A -o pid= -o pgid= -o stat= -o command= 2>/dev/null | G=" $* " LC_ALL=C awk 'index(ENVIRON["G"], " " $2 " ") && $3 !~ /^Z/ { c = $0; sub(/^ *[0123456789]+ +[0123456789]+ +[^ ]+ +/, "", c); print $1 " " $3 " " substr(c, 1, 70) }'; }
_db3_gs() { local f; for f in ${_db3_pf[@]+"${_db3_pf[@]}"}; do printf ' %s' "$(cat "$f" 2>/dev/null)"; done; }   # the ids of the process groups of this case's runs
# R1: "ok" when no process of those groups is alive at two listings 0.1 s apart, the first taken at once after a run has exited (a process killed
# a moment ago is in the first listing only), else the processes that were in both.
_db3_atexit() {
  local g l1 l2 l="" p; g="$(_db3_gs)"
  [ -n "${g// /}" ] || { printf ok; return 0; }
  l1="$(_db3_gm $g)"; [ -n "$l1" ] || { printf ok; return 0; }
  sleep 0.1; l2="$(_db3_gm $g)"
  for p in $(printf '%s\n' "$l1" | awk '{ print $1 }'); do case "$l2" in "$p "*|*$'\n'"$p "*) l="$l$(printf '%s\n' "$l2" | grep -F -e "$p " | sed -n 1p);" ;; esac; done
  [ -n "$l" ] && printf 'left at its exit: %s' "$l" || printf ok
}
# R12: "ok" once the groups of this case's runs hold no live process (30 s), else what was left, sent CONT and then KILL by pid.
_db3_clean() {
  local g l="" i=0 p; g="$(_db3_gs)"
  [ -n "${g// /}" ] || { printf ok; return 0; }
  while [ "$i" -lt 150 ]; do l="$(_db3_gm $g)"; [ -n "$l" ] || { printf ok; return 0; }; sleep 0.2; i=$((i + 1)); done
  for p in $(printf '%s\n' "$l" | awk '{ print $1 }'); do kill -CONT "$p" 2>/dev/null; done
  for p in $(printf '%s\n' "$l" | awk '{ print $1 }'); do kill -KILL "$p" 2>/dev/null; done
  printf 'left behind: %s' "$(printf '%s' "$l" | tr '\n' ';')"
}
_db3_cores() { local n; n="$(sysctl -n hw.ncpu 2>/dev/null)"; case "$n" in ''|*[!0123456789]*) n="$(getconf _NPROCESSORS_ONLN 2>/dev/null)" ;; esac
  case "$n" in ''|*[!0123456789]*) n=1 ;; esac; [ "$n" -ge 1 ] || n=1; [ "$n" -le 64 ] || n=64; printf '%s' "$n"; }
# CASE [--red] GROUPS MANIFEST STUB...: the copy at $DB3/n/CASE (_db3_F, _db3_T, _db3_c, _db3_tmp); 1 when it could not be made
_db3_new() {
  local n="$1" r=""; shift
  [ "${1:-}" != --red ] || { r=--red; shift; }
  _db3_c="$DB3/n/$n"; _db3_F="$_db3_c/f"; _db3_T="$_db3_F/engine/harness/tests"; _db3_tmp="$_db3_c/tmp"; _db3_pf=()
  rm -rf "$_db3_c"; mkdir -p "$_db3_tmp" || return 1
  _suite_copy_tree ${r:+"$r"} "$_db3_F" "$@"
}
# LABEL ARG...: the copy's driver in the background under a bounded runner (stdout LABEL.out, stderr LABEL.err, the group's id LABEL.pid)
_db3_start() {
  local l="$1"; shift
  ( cd "$_db3_F" && exec env -u FELIX_TEST_NO_MANIFEST -u FELIX_TEST_JOBS -u FELIX_TEST_SLOTS -u FELIX_TEST_RED_JOBS -u FELIX_TEST_SLOT_NOTE -u FELIX_TEST_PART_LOG \
      -u FELIX_TEST_PART_RAN -u FELIX_TEST_PART_END -u FELIX_TEST_PART_RECORD -u PERL5OPT \
      TMPDIR="$_db3_tmp" FELIX_TEST_SLOTS=8 DJX_DIR="$_db3_c" DJX_CFG="$_db3_F/.git/config" DJX_KEEP=1 ${_db3_E[@]+"${_db3_E[@]}"} \
      perl "$DB3/run.pl" "${_db3_lim:-150}" "$_db3_INT" "$_db3_QUIT" "$_db3_c/$l.pid" "$BASH" "$_db3_T/run" "$@" \
  ) > "$_db3_c/$l.out" 2> "$_db3_c/$l.err" &
  _db3_bg=$!; _db3_pf[${#_db3_pf[@]}]="$_db3_c/$l.pid"
}
_db3_wait() { { wait "$_db3_bg"; } 2>/dev/null; _db3_rc=$?; _db3_E=(); _db3_INT=DEFAULT; _db3_QUIT=DEFAULT; }
_db3_run()  {   # _db3_ex: R1's verdict on this run, _db3_cl: R12's, whose findings _db3_leak keeps
  _db3_start "$@"; _db3_wait; _db3_ex="$(_db3_atexit)"; _db3_cl="$(_db3_clean)"
  [ "$_db3_cl" = ok ] || _db3_leak="$_db3_leak [$_db3_c: $_db3_cl]"
}
_db3_rcpt() { if [ -f "$_db3_F/.git/felix-suite-receipt" ]; then echo present; else echo absent; fi; }
_db3_last() { tail -n 1 "$_db3_c/$1.out" 2>/dev/null; }
_db3_redrows() { if [ -f "$_db3_T/red.tsv" ]; then grep -v '^#' "$_db3_T/red.tsv" | tr '\n' '|'; else printf '(no red.tsv)'; fi; }
_db3_std() { printf 'printf "\\ndjx-sec %s\\n"\nok "djx %s"\nok "djx %s again"\n' "$2" "$3" "$3" > "$1"; }
_db3_std "$DB3/pp/std/0010-pa.sh" 0010-pa.sh a1; _db3_std "$DB3/pp/std/0020-pb.sh" 0020-pb.sh b1; _db3_std "$DB3/pp/std/0030-pc.sh" 0030-pc.sh c1
_db3_mk() {   # CASE [FILE]: pp/CASE holds 0010-pa.sh, 0030-pc.sh and the part read from stdin (default 0020-pb.sh)
  local d="$DB3/pp/$1"; mkdir -p "$d" && cp "$DB3/pp/std/0010-pa.sh" "$DB3/pp/std/0030-pc.sh" "$d/" && cat > "$d/${2:-0020-pb.sh}"
}
# LABEL EXPECT...: "ok", or what differed, for the run LABEL just made: exit 1; each EXPECT a FAIL line printed once ("!X": never starting so;
# "#N": N failures in the summary; else as many as the log has "  FAIL  " lines); no receipt, and a control showing a passing run leaves one
_db3_chk() {
  local l="$1" e c r="" wf="" s; shift
  [ "$_db3_rc" = 1 ] || r="$r exit $_db3_rc, not 1;"
  for e in "$@"; do
    case "$e" in
      \#*) wf="${e#\#}" ;;
      !*) c="$(_db3_cnt "$_db3_c/$l.out" "  FAIL  ${e#!}")"; [ "$c" = 0 ] || r="$r [${e#!}] printed $c times;" ;;
      *) c="$(_db3_cnt "$_db3_c/$l.out" "  FAIL  $e")"; [ "$c" = 1 ] || r="$r [$e] printed $c times;" ;;
    esac
  done
  s="$(_db3_last "$l")"; [ -n "$wf" ] || wf="$(_db3_cnt "$_db3_c/$l.out" '  FAIL  ')"
  case "$s" in *" passed, "*" failed"*) s="${s#* passed, }"; s="${s%% failed*}"; [ "$s" = "$wf" ] || r="$r summary counts $s failed, not $wf;" ;; esac
  [ "$_db3_ctl" = 1 ] || r="$r the control left no receipt, so a missing one says nothing;"
  [ "$(_db3_rcpt)" = absent ] || r="$r a receipt was left;"
  printf '%s' "${r:-ok}"
}
# LABEL EXPECT...: _db3_chk for a record run, the manifest as it was, and red.tsv the two retraction rows (red has gone: _db3_run waited for the group)
_db3_chkr() {
  local r; r="$(_db3_chk "$@")"; [ "$r" != ok ] || r=""
  cmp -s "$DB3/man.tsv" "$_db3_T/assertions.tsv" || r="$r the manifest was rewritten;"
  [ "$(_db3_redrows)" = "$(printf 'base\t-\t-\t-|run\t-\t-\t-|')" ] || r="$r red.tsv holds [$(_db3_redrows)];"
  [ "$_db3_ctlr" = 1 ] || r="$r the record control wrote no manifest and no counts, so their absence says nothing;"
  printf '%s' "${r:-ok}"
}

# ---- the positive controls: planted passing parts under -j 3, plain and as a record run in a --red copy (D8)
# A receipt is left by a passing run only where a manifest was compared, so every copy whose "no receipt" means something has one: it lists the first
# assertion of the prelude, which every run reaches once, and which a serial run without a manifest names here.
_db3_new pn "$DB3/g-empty.tsv" - "$DB3/pp/std/0010-pa.sh"; _db3_run n1 -j 1
printf '1\t%s\n' "$(sed -n 's/^  ok    //p' "$_db3_c/n1.out" | sed -n 1p)" > "$DB3/pman.tsv"
_db3_new ctl "$DB3/g-empty.tsv" "$DB3/pman.tsv" "$DB3/pp/std"/*.sh
_db3_run c3 -j 3
[ "$_db3_rc" = 0 ] && [ -n "$(cat "$_db3_F/.git/felix-suite-receipt" 2>/dev/null)" ] && _db3_ctl=1
is "D8: a -j 3 run of planted passing parts in a copy with a manifest exits 0 and leaves a receipt (runner-failure copy, positive control)" "$_db3_rc $_db3_ctl" "0 1"
is "R12: and it leaves no process in its group, stopped or running (control)" "$_db3_cl" ok
_db3_new rc --red "$DB3/g-empty.tsv" "$DB3/man.tsv" "$DB3/pp/std"/*.sh
_db3_run r3 -j 3 --record-assertions
case "$_db3_rc|$(_db3_redrows)" in 0\|base$'\t'origin/main$'\t'*$'\t'0.0.1\|run$'\t'0$'\t'[0-9]*$'\t'[0-9]*\|) cmp -s "$DB3/man.tsv" "$_db3_T/assertions.tsv" || _db3_ctlr=1 ;; esac
is "D8: a -j 3 record run of planted passing parts rewrites the manifest and leaves red.tsv with counts (runner-failure copy, positive control)" "$_db3_ctlr $_db3_cl" "1 ok"
rm -rf "$DB3/n/pn" "$DB3/n/ctl" "$DB3/n/rc"

# ---- the runner's own failures (D3), and what they do to a record run (D4, R1)
# CASE GROUPS DESC EXPECT...: pp/CASE under -j 3, then under -j 3 --record-assertions in a --red copy. _db3_hook runs in each copy before its run,
# _db3_post after the plain run (it asserts _db3_postn); _db3_skip says why to reach every name below as a skip.
_db3_rf() {
  local n="$1" g="$2" d="$3" a1 a2 a3; shift 3
  a1="D3: $d fails with its runner line, exits 1 and leaves no receipt and no process"
  a2="D4: $d in a record run writes no manifest, and red.tsv holds the rows base - - - and run - - -"
  a3="R1: and once the record run after $d has exited no process of red's tree is left, stopped or running"
  if [ -n "$_db3_skip" ]; then
    skip "$a1" "$_db3_skip"; skip "$a2" "$_db3_skip"; skip "$a3" "$_db3_skip"; [ -z "$_db3_postn" ] || skip "$_db3_postn" "$_db3_skip"
    _db3_skip=""; _db3_hook=""; _db3_post=""; _db3_postn=""; return 0
  fi
  if _db3_new "$n" "$g" "$DB3/pman.tsv" "$DB3/pp/$n"/*.sh; then
    [ -z "$_db3_hook" ] || "$_db3_hook"
    _db3_run p -j 3
    is "$a1" "$(_db3_chk p "$@") $_db3_cl" "ok ok"
    [ -z "$_db3_post" ] || "$_db3_post"
  else bad "$a1" "the copy could not be made"; fi
  rm -rf "$DB3/n/$n"
  if _db3_new "$n-r" --red "$g" "$DB3/man.tsv" "$DB3/pp/$n"/*.sh; then
    [ -z "$_db3_hook" ] || "$_db3_hook"
    _db3_run r -j 3 --record-assertions
    is "$a2" "$(_db3_chkr r "$@")" ok
    is "$a3" "$_db3_ex" ok
  else bad "$a2" "the copy could not be made"; bad "$a3" "the copy could not be made"; fi
  rm -rf "$DB3/n/$n-r"; _db3_hook=""; _db3_post=""; _db3_postn=""
}
_db3_mk kill9 <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx kill9 before"
kill -9 $$
ok "djx kill9 after"
X
_db3_rf kill9 "$DB3/g-empty.tsv" "a unit killed with kill -9 while it runs a member" \
   "part did not finish: 0020-pb.sh" "part ended without its mark: 0020-pb.sh" "!part process ended with status"
_db3_mk lastkill <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx lastkill member"
_og_check() { : > "$DJX_DIR/killed.lastkill"; kill -9 $$; }
X
_db3_rf lastkill "$DB3/g-empty.tsv" "a unit killed after its last member and before its mark" \
   "part ended without its mark: 0020-pb.sh" "!part did not finish" "!part process ended with status"
_db3_mk exit0 <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx exit0 before"
exit 0
X
_db3_rf exit0 "$DB3/g-empty.tsv" "a part that runs exit 0" "part did not finish: 0020-pb.sh" "part ended without its mark: 0020-pb.sh"
_db3_mk setu <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx setu before"
: "$djx_unbound_variable_zz"
ok "djx setu after"
X
_db3_rf setu "$DB3/g-empty.tsv" "a part that dies on an unbound variable under set -u" "part did not finish: 0020-pb.sh" "part ended without its mark: 0020-pb.sh"
_db3_mk reached <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx reached"
printf 'reached\n'
X
_db3_pr7() { is "$_db3_postn" "$(_db3_line "$_db3_c/p.out" '  | reached') $([ "$(_db3_line "$_db3_c/p.out" reached)" -le 1 ] && echo one-or-none || echo two)" "1 one-or-none"; }
_db3_post=_db3_pr7; _db3_postn="R7: a part's own reached line is printed in its place as a bar line, once, and reads as no completion marker"
_db3_rf reached "$DB3/g-empty.tsv" "a part that prints reached" "part printed a line the runner owns: 0020-pb.sh" "!part did not finish" "!part ended without its mark"
_db3_mk forged <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
printf '@@prelude-done\n'
X
printf '%s\n' 'printf "\ndjx-sec 0030-pc.sh\n"' 'printf "@@member-done 0030-pc.sh\n"' > "$DB3/pp/forged/0030-pc.sh"
printf '%s\n' 'printf "\ndjx-sec 0040-pd.sh\n"' 'printf "@@part-done 0040-pd.sh\n"' > "$DB3/pp/forged/0040-pd.sh"
_db3_rf forged "$DB3/g-empty.tsv" "parts that print a runner line (a second @@prelude-done, a forged @@member-done, a forged @@part-done)" \
   "part printed a line the runner owns: 0020-pb.sh" "part printed a line the runner owns: 0030-pc.sh" "part printed a line the runner owns: 0040-pd.sh" \
   "!part printed a line the runner owns: 0010-pa.sh"
mkdir -p "$DB3/pp/gdie"; printf 'grp\t0010-ga.sh\ngrp\t0020-gb.sh\ngrp\t0030-gc.sh\n' > "$DB3/g-grp.tsv"
printf '%s\n' 'printf "\ndjx-sec 0010-ga.sh\n"' 'ok "djx gdie a"' > "$DB3/pp/gdie/0010-ga.sh"
printf '%s\n' 'printf "\ndjx-sec 0020-gb.sh\n"' 'ok "djx gdie b"' 'kill -9 $$' > "$DB3/pp/gdie/0020-gb.sh"
printf '%s\n' 'printf "\ndjx-sec 0030-gc.sh\n"' 'ok "djx gdie c"' > "$DB3/pp/gdie/0030-gc.sh"
_db3_rf gdie "$DB3/g-grp.tsv" "a group member that dies" "part did not finish: 0020-gb.sh" "part did not finish: 0030-gc.sh" \
   "part ended without its mark: grp" "!part did not finish: 0010-ga.sh"
_db3_mk partial <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
printf 'djx partial text'
bad "djx lands on a partial line"
X
_db3_rf partial "$DB3/g-empty.tsv" "a part whose bad line lands on a partial line" "part failed more than it printed: 0020-pb.sh" "!part did not finish"
_db3_mk trap5 <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx trap5"
trap 'rm -rf "$TMP"; exit 5' EXIT
X
_db3_pt5() { _db3_run t1 -j 1; is "$_db3_postn" "$_db3_rc $_db3_cl" "5 ok"; }
_db3_post=_db3_pt5; _db3_postn="D3: the part that replaces the EXIT trap with one that exits 5 makes a -j 1 run exit 5 (control)"
_db3_rf trap5 "$DB3/g-empty.tsv" "a part that replaces the EXIT trap with one that removes \$TMP and exits 5" \
   "part process ended with status 5: 0020-pb.sh" "!part did not finish" "!part ended without its mark"
# The units' preludes alone. The copy's 0006 gets a line that does nothing the first time it runs, in the parent's prelude, which makes a marker file,
# and does PLANT in every prelude after it, the units'. Each unit's prelude lines are then printed behind a bar, so none reads as an assertion.
_db3_plant() {   # PLANT: the copy's 0006 runs PLANT only where the marker file exists
  local f; for f in "$_db3_T"/parts/0006-*.sh; do printf '\nif [ -e "%s" ]; then %s; else : > "%s"; fi\n' "$_db3_c/pre.marker" "$1" "$_db3_c/pre.marker" >> "$f"; done
}
mkdir -p "$DB3/pp/pre"; cp "$DB3/pp/std"/*.sh "$DB3/pp/pre/"
_db3_h6() { _db3_plant 'bad "djx planted prelude failure"'; }
_db3_pp6() { is "$_db3_postn" "$(_db3_line "$_db3_c/p.out" '  |   FAIL  djx planted prelude failure') $(_db3_line "$_db3_c/p.out" '  FAIL  djx planted prelude failure')" "3 0"; }
_db3_hook=_db3_h6; _db3_post=_db3_pp6; _db3_postn="D3: the lines of a failed prelude follow its runner line, each behind two spaces, a bar and a space, so none reads as an assertion"
_db3_rf pre "$DB3/g-empty.tsv" "a FAIL in the units' prelude only" "part's prelude failed: 0010-pa.sh" "part's prelude failed: 0020-pb.sh" "part's prelude failed: 0030-pc.sh"
mkdir -p "$DB3/pp/prp"; cp "$DB3/pp/std"/*.sh "$DB3/pp/prp/"
_db3_h7() { _db3_plant 'printf "djx-partial"; bad "djx planted partial prelude failure"'; }
_db3_pp7() { is "$_db3_postn" "$(_db3_cnt "$_db3_c/p.out" '  | djx-partial  FAIL  djx planted partial prelude failure')" 3; }
_db3_hook=_db3_h7; _db3_post=_db3_pp7; _db3_postn="R7: and the prelude lines it prints are behind a bar, the FAIL that landed on a partial line among them"
_db3_rf prp "$DB3/g-empty.tsv" "a FAIL printed onto a partial line in the units' prelude only" \
   "part's prelude failed: 0010-pa.sh" "part's prelude failed: 0020-pb.sh" "part's prelude failed: 0030-pc.sh" "!part failed more than it printed"
mkdir -p "$DB3/pp/prk"; cp "$DB3/pp/std"/*.sh "$DB3/pp/prk/"
_db3_hk() { _db3_plant 'printf "djx-prekill\n"; kill -9 $$'; }
_db3_pk() { is "$_db3_postn" "$(_db3_cnt "$_db3_c/p.out" '  | djx-prekill')" 3; }
_db3_hook=_db3_hk; _db3_post=_db3_pk; _db3_postn="D3: and a unit that dies in its prelude, with no @@prelude-done at all, prints the lines it wrote behind a bar"
_db3_rf prk "$DB3/g-empty.tsv" "a unit that dies in its prelude, before @@prelude-done" \
   "part's prelude failed: 0010-pa.sh" "part's prelude failed: 0020-pb.sh" "part's prelude failed: 0030-pc.sh" "part ended without its mark: 0020-pb.sh"
# Does a top-level a[1/0]=1 end a sourced file and the rest of the line that sourced it, in this bash? Measured in a child of it.
printf 'echo S1\na[1/0]=1\necho S2\n' > "$DB3/cut.sh"; printf '. "%s"; echo SAMELINE\necho NEXTLINE\n' "$DB3/cut.sh" > "$DB3/cut.drv"
_db3_m="$("$BASH" "$DB3/cut.drv" 2>/dev/null | tr '\n' ' ')"
mkdir -p "$DB3/pp/acut"; printf 'acut\t0010-ka.sh\nacut\t0020-kb.sh\nacut\t0030-kc.sh\n' > "$DB3/g-acut.tsv"
printf '%s\n' 'printf "\ndjx-sec 0010-ka.sh\n"' 'ok "djx acut a"' > "$DB3/pp/acut/0010-ka.sh"
printf '%s\n' 'printf "\ndjx-sec 0020-kb.sh\n"' 'ok "djx acut b before"' 'a[1/0]=1' 'ok "djx acut b after"' > "$DB3/pp/acut/0020-kb.sh"
printf '%s\n' 'printf "\ndjx-sec 0030-kc.sh\n"' 'ok "djx acut c"' > "$DB3/pp/acut/0030-kc.sh"
_db3_pcut() { is "$_db3_postn" "$(_db3_line "$_db3_c/p.out" '  ok    djx acut c') $(_db3_line "$_db3_c/p.out" '  ok    djx acut b after')" "1 0"; }
_db3_post=_db3_pcut; _db3_postn="D2: and the member after it ran, as the next part line does in a serial run"
[ "$_db3_m" = "S1 NEXTLINE " ] || _db3_skip="this bash does not end a sourced file and the rest of its line there (it printed [$_db3_m])"
_db3_rf acut "$DB3/g-acut.tsv" "a member whose sourcing a top-level a[1/0]=1 cuts short, while later members run" \
   "part did not finish: 0020-kb.sh" "!part did not finish: 0010-ka.sh" "!part did not finish: 0030-kc.sh" "!part ended without its mark"
_db3_mk arith <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx arith before"
x=$((1/0))
ok "djx arith after"
X
_db3_new arith "$DB3/g-empty.tsv" "$DB3/pman.tsv" "$DB3/pp/arith"/*.sh; _db3_run a3 -j 3; _db3_run a1 -j 1
_db3_x="$(LC_ALL=C diff <(grep -E '^  (ok    |FAIL  |skip  )' "$_db3_c/a3.out" | LC_ALL=C sort) <(grep -E '^  (ok    |FAIL  |skip  )' "$_db3_c/a1.out" | LC_ALL=C sort) | head -4 | tr '\n' '|')"
is "D2: a top-level x=\$((1/0)) between two assertions gives the same (verdict, name) lines under -j 3 as under -j 1, the -j 3 run counted from lines" \
   "${_db3_x:-same} $(_db3_last a3 | grep -c ' (counted from lines)$')" "same 1"
rm -rf "$DB3/n/arith"

# ---- a runner failure in red's suite only (D4, R8): red leaves the runner's lines out of its counts and names, and refuses a log it cannot trust
# The part dies, prints reached or leaves the shell changed only where FELIX_TEST_NO_MANIFEST=1, which only red's suite sees. The record run itself passes.
_db3_pfx=("part's prelude failed: " "part did not finish: " "part ended without its mark: " "part process ended with status " "part failed more than it printed: " "part printed a line the runner owns: " "part left the shell changed for the parts after it: ")
_db3_ro() {   # CASE BODY: pp/CASE's 0020 does BODY in red's suite only; a -j 3 record run in a --red copy
  local n="$1"; mkdir -p "$DB3/pp/$n"; cp "$DB3/pp/std/0010-pa.sh" "$DB3/pp/std/0030-pc.sh" "$DB3/pp/$n/"
  printf 'printf "\\ndjx-sec 0020-pb.sh\\n"\nok "djx b1"\n[ "${FELIX_TEST_NO_MANIFEST:-0}" != 1 ] || { %s; }\nok "djx b2"\n' "$2" > "$DB3/pp/$n/0020-pb.sh"
  _db3_new "$n" --red "$DB3/g-empty.tsv" "$DB3/man.tsv" "$DB3/pp/$n"/*.sh && _db3_run r -j 3 --record-assertions
}
_db3_rt() {   # red.tsv's name rows: how many, their failed counts added, the run row's failed count, djx b2's, how many start with a runner prefix
  P="$(printf '%s\n' "${_db3_pfx[@]}")" LC_ALL=C awk -F'\t' 'BEGIN { np = split(ENVIRON["P"], P, "\n") }
    /^#/ || $1 == "base" { next }
    $1 == "run" { f = $2; next }
    { n++; s += $2; if ($1 == "djx b2") b = $2; for (i = 1; i <= np; i++) if (P[i] != "" && index($1, P[i]) == 1) q++ }
    END { print n + 0, s + 0, f + 0, b + 0, q + 0 }' "$_db3_T/red.tsv" 2>/dev/null
}
_db3_ro rdie 'kill -9 $$'
read -r _db3_n _db3_s _db3_f _db3_b _db3_q <<< "$(_db3_rt)"
is "D4: a unit that dies in red's suite only: the record run exits 0, no process is left, and red.tsv counts the run with name rows that add up to its failed count" \
   "$_db3_rc $_db3_cl $([ "$_db3_n" -gt 0 ] && [ "$_db3_s" = "$_db3_f" ] && echo adds-up || echo "rows $_db3_n sum $_db3_s run $_db3_f")" "0 ok adds-up"
is "D4: and no name row starts with one of the runner's seven failure prefixes, and djx b2, which the dead unit never reached, is named by its shortfall of one" "$_db3_q $_db3_b" "0 1"
rm -rf "$DB3/n/rdie"
_db3_ro rrch 'printf "reached\n"'
is "D4: a unit that prints reached in red's suite only makes red refuse the log, the record run having passed: red.tsv holds the rows base - - - and run - - -" \
   "$_db3_rc $_db3_cl $(_db3_redrows)" "0 ok $(printf 'base\t-\t-\t-|run\t-\t-\t-|')"
rm -rf "$DB3/n/rrch"
_db3_ro rshl 'umask 077'
read -r _db3_n _db3_s _db3_f _db3_b _db3_q <<< "$(_db3_rt)"
_db3_x="$(_db3_redrows)"; case "$_db3_x" in base$'\t'origin/main$'\t'*run$'\t'[0123456789]*) _db3_x=counts ;; esac
is "R8: a unit that leaves the shell changed in red's suite only is left out of red's counts and names, and red does not refuse the log: red.tsv counts the run with no failure and no name row" \
   "$_db3_rc $_db3_cl $_db3_n $_db3_f $_db3_x" "0 ok 0 0 counts"
rm -rf "$DB3/n/rshl"

# ---- the parent's own state under -j N (D3): a failure the parent alone makes is not lost when the units end well
# The copy's 0006 does nothing in a unit's prelude (the marker is there) and, in the parent's only, fails an assertion, plants a refusal record, and moves
# the origin's config (newer than the guard's stamp, so the next assertion sees it) and puts it back: put back is not unmoved.
mkdir -p "$DB3/pp/par"; cp "$DB3/pp/std"/*.sh "$DB3/pp/par/"
_db3_n9a="no fixture git command was refused for a directory outside the suite's temporary directory"
_db3_n9c="the remotes of the checkout this run started in did not move while it ran"
_db3_parent() {
  local f m="$_db3_c/par.marker"
  for f in "$_db3_T"/parts/0006-*.sh; do
    printf '\nif [ ! -e "%s" ]; then : > "%s"; bad "djx parent-only prelude failure"; printf "djx planted refusal\\n" >> "$FELIX_TEST_FXREFUSED"\n' "$m" "$m" >> "$f"
    printf '  cp -p "$DJX_CFG" "$DJX_DIR/cfg.save"; printf "[remote \\"djxmoved\\"]\\n\\turl = /djx/moved\\n" >> "$DJX_CFG"; touch -t 203001010000 "$DJX_CFG"\n  ok "djx tick"; cp -p "$DJX_DIR/cfg.save" "$DJX_CFG"\nfi\n' >> "$f"
  done
}
_db3_new par "$DB3/g-empty.tsv" "$DB3/pman.tsv" "$DB3/pp/par"/*.sh; _db3_parent; _db3_run q3 -j 3; _db3_q3="$(_db3_chk q3 "djx parent-only prelude failure" "$_db3_n9a" "$_db3_n9c" "!part " '#3') $_db3_cl"
rm -f "$_db3_c/par.marker"; _db3_run q1 -j 1; _db3_q1="$(_db3_chk q1 "djx parent-only prelude failure" "$_db3_n9a" "$_db3_n9c" '#3') $_db3_cl"
is "D3: a failure, a refusal record and a moved origin made in the parent's prelude alone give three FAILs under -j 3, each once, with no runner failure, exit 1, three in the summary and no receipt" "$_db3_q3" "ok ok"
is "D3: and under -j 1, where one shell runs everything, the same three (control)" "$_db3_q1" "ok ok"
rm -rf "$DB3/n/par"

# ---- assertion failures (D3, D4): their own FAIL, exit 1, and the manifest written as -j 1 writes it
is "D3: the two 9990 names the cases below read are 9990's (control)" "$(grep -qF -e "$_db3_n9a" "$HERE"/parts/9990-*.sh && grep -qF -e "the fixture floor still holds" "$HERE"/parts/9990-*.sh; echo ok)" ok
_db3_n9b="fixture floor: at the end of the suite it still stands in cwd inside its temporary directory, under a ceiling at that directory's parent"
_db3_af() {   # CASE DESC FAILNAME: pp/CASE under -j 3: that FAIL once, no runner failure, exit 1, no receipt; and the record run's manifest is -j 1's
  local n="$1" d="$2" w="$3" a b
  _db3_new "$n" "$DB3/g-empty.tsv" "$DB3/pman.tsv" "$DB3/pp/$n"/*.sh; _db3_run p -j 3
  a="$(_db3_chk p "$w" "!part " '#1')"
  is "D3: $d gives its own FAIL, no runner failure, exit 1, no receipt and no process" "$a $_db3_cl" "ok ok"
  rm -rf "$DB3/n/$n"; _db3_new "$n-r" --red "$DB3/g-empty.tsv" "$DB3/man.tsv" "$DB3/pp/$n"/*.sh
  _db3_run r -j 3 --record-assertions; a="$_db3_rc $_db3_cl"; b="$(cat "$_db3_T/assertions.tsv")"
  cp "$DB3/man.tsv" "$_db3_T/assertions.tsv"; _db3_run r1 -j 1 --record-assertions
  is "D4: $d in a -j 3 record run exits 1 and writes the manifest -j 1 writes (not the old one)" \
     "$a $([ "$b" = "$(cat "$_db3_T/assertions.tsv")" ] && [ "$b" != "$(cat "$DB3/man.tsv")" ] && echo same || echo differ)" "1 ok same"
  rm -rf "$DB3/n/$n-r"
}
_db3_mk afail <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
ok "djx afail one"
bad "djx afail fails"
ok "djx afail two"
X
_db3_af afail "a failing assertion" "djx afail fails"
_db3_mk arefuse <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
printf 'djx planted refusal line\n' >> "$FELIX_TEST_FXREFUSED"
ok "djx arefuse one"
X
_db3_af arefuse "a refusal record planted in a unit" "$_db3_n9a"
_db3_mk afloor <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
cd /
ok "djx afloor one"
X
_db3_af afloor "a unit that ends outside its \$TMP/cwd" "$_db3_n9b"

# ---- the shell a unit leaves (R8): sixteen planted parts, twelve that leave it changed and four that do not
mkdir -p "$DB3/pp/sh"; _db3_i=0; _db3_sn=(); _db3_sd=(); _db3_sr=(); _db3_sk=""; _db3_w="part left the shell changed for the parts after it"
_db3_ul="$(ulimit -S -n 2>/dev/null)"; case "$_db3_ul" in ''|*[!0123456789]*) _db3_ul=0 ;; esac
# the first two functions tests/lib defines, other than its _vars functions: a part redefines the first and unsets the second
_db3_fn=($(LC_ALL=C awk '/^_[a-z0-9_]+\(\) *[{]/ { s = $1; sub(/\(\).*/, "", s); if (s !~ /_vars$/ && !(s in seen) && ++k <= 2) { seen[s] = 1; print s } }' "$HERE"/lib/*.sh))
_db3_sp() {   # NAME DESC EXPECT CODE: part pp/sh/NNN0-NAME.sh does CODE and then an ok. EXPECT is the change line as a regex, @FILE for the one the part wrote to $DJX_DIR/FILE, - for none
  _db3_i=$((_db3_i + 1)); local f; f="$(printf '%04d' $((_db3_i * 10)))-$1.sh"
  printf 'printf "\\ndjx-sec %s\\n"\n%s\nok "djx shell %s"\n' "$f" "$4" "$1" > "$DB3/pp/sh/$f"
  _db3_sn[$_db3_i]="$1"; _db3_sd[$_db3_i]="$2"; _db3_sr[$_db3_i]="$3"
}
_db3_sp umask  "umask 077 left set" '@exp.umask' '_w="$(umask)"; umask 077; printf "umask %s is now %s\n" "$_w" "$(umask)" > "$DJX_DIR/exp.umask"'
_db3_sp shopt  "shopt -s nullglob left set" 'shopt -u nullglob is now shopt -s nullglob' 'shopt -s nullglob'
_db3_sp trap   "a trap on USR1 left set" 'trap on .*USR1.* added' 'trap : USR1'
_db3_sp path   "PATH changed" 'export PATH changed' 'PATH="$PATH:/djx/none"'
_db3_sp unexp  "an exported variable the case set, unset" 'export DJX_KEEP removed' 'unset DJX_KEEP'
_db3_sp fnre   "a function of tests/lib redefined" "function ${_db3_fn[0]:-NONE} changed" "${_db3_fn[0]:-NONE}() { :; }"
_db3_sp fnun   "a function of tests/lib unset, as part 0290 did" "function ${_db3_fn[1]:-NONE} removed" "unset -f ${_db3_fn[1]:-NONE}"
_db3_sp git    "git() { :; } left defined" 'function git added over a command' 'git() { :; }'
_db3_sp gitdir "GIT_DIR exported" 'export GIT_DIR added' 'export GIT_DIR=/djx/x'
_db3_sp felix  "FELIX given another value" 'variable FELIX changed' 'FELIX=/djx/other'
_db3_sp fd7    "descriptor 7 left open" 'descriptor 7 opened' 'exec 7>/dev/null'
if [ "$_db3_ul" -ge 8 ]; then _db3_sp ulimit "a soft limit lowered with ulimit -S" 'ulimit -a: .* is now .*' 'ulimit -S -n "$((DJX_ULIM - 1))"'
else _db3_sp ulimit "a soft limit lowered with ulimit -S" - ':'; _db3_sk="the soft limit on open files is [$(ulimit -S -n 2>/dev/null)], not a number to lower"; fi
_db3_sc=$_db3_i
_db3_sp newexp "a new export outside the steering list" - 'export DJX_NEW_EXPORT=1'
_db3_sp newvar "a new variable" - 'djx_new_variable=1'
_db3_sp newfn  "a new function that hides no builtin, keyword or command" - 'djx_new_function() { :; }'
_db3_sp libvar "a variable of tests/lib changed" - 'IB_BR=x; _AU_F=/djx/changed'
_db3_sh() {   # OUT UNIT REGEX: ok when UNIT's seventh failure is printed once and a "  | " line right after it, before any other, matches REGEX
  LC_ALL=C R="$3" awk -v u="  FAIL  $_db3_w: $2" '
    $0 == u { n++; on = 1; next }
    on && index($0, "  | ") == 1 { if (substr($0, 5) ~ ("^" ENVIRON["R"] "$")) m = 1; next }
    { on = 0 }
    END { if (n == 1 && m) print "ok"; else print "failure printed " n + 0 " times, change line " (m ? "found" : "not found") }' "$_db3_c/$1"
}
_db3_unit() { printf '%04d-%s.sh' $(($1 * 10)) "${_db3_sn[$1]}"; }
_db3_xx=(); _db3_k=1; while [ "$_db3_k" -le "$_db3_sc" ]; do [ "${_db3_sr[$_db3_k]}" = - ] || _db3_xx[${#_db3_xx[@]}]="$_db3_w: $(_db3_unit "$_db3_k")"; _db3_k=$((_db3_k + 1)); done
_db3_new sh "$DB3/g-empty.tsv" "$DB3/pman.tsv" "$DB3/pp/sh"/*.sh; _db3_E=(DJX_ULIM="$_db3_ul"); _db3_run s3 -j 3
is "R8: the parts that leave the shell changed each give the seventh failure, once, and the four that do not give none: the run exits 1, counts them in its summary, leaves no receipt and no process" \
   "$(_db3_chk s3 "${_db3_xx[@]}" "!$_db3_w: $(_db3_unit 13)" "!$_db3_w: $(_db3_unit 14)" "!$_db3_w: $(_db3_unit 15)" "!$_db3_w: $(_db3_unit 16)") $_db3_cl" "ok ok"
_db3_k=1; while [ "$_db3_k" -le "$_db3_sc" ]; do
  _db3_re="${_db3_sr[$_db3_k]}"; case "$_db3_re" in @*) _db3_re="$(head -n 1 "$_db3_c/${_db3_re#@}" 2>/dev/null)" ;; esac
  if [ "${_db3_sr[$_db3_k]}" = - ]; then skip "R8: ${_db3_sd[$_db3_k]} gives the seventh failure with its change line" "$_db3_sk"
  else is "R8: ${_db3_sd[$_db3_k]} gives the seventh failure with its change line" "$(_db3_sh s3.out "$(_db3_unit "$_db3_k")" "$_db3_re")" ok; fi
  _db3_k=$((_db3_k + 1))
done
_db3_new shp "$DB3/g-empty.tsv" "$DB3/pman.tsv" "$DB3/pp/sh"/01[3456]0-*.sh; _db3_run sp -j 3
_db3_x=""; _db3_k=13; while [ "$_db3_k" -le 16 ]; do
  _db3_x="$_db3_x $(_db3_line "$_db3_c/sp.out" "  ok    djx shell ${_db3_sn[$_db3_k]}")$(_db3_cnt "$_db3_c/sp.out" "  FAIL  $_db3_w: $(_db3_unit "$_db3_k")")"; _db3_k=$((_db3_k + 1)); done
is "R8: a part that exports a new name outside the steering list, one that sets a new variable, one that defines a new function that hides nothing and one that changes a variable of tests/lib each pass under -j 3: the run exits 0, leaves a receipt and no process" \
   "$_db3_rc $(_db3_rcpt) $_db3_cl$_db3_x" "0 present ok 10 10 10 10"
_db3_new sj "$DB3/g-empty.tsv" "$DB3/pman.tsv" "$DB3/pp/sh"/*.sh; _db3_E=(DJX_ULIM="$_db3_ul"); _db3_lim=100; _db3_run s1 -j 1; _db3_lim=150
is "R8: under -j 1 none of the sixteen gives the seventh failure: a change carries to the parts after it, as it always did" "$(_db3_cnt "$_db3_c/s1.out" "  FAIL  $_db3_w") $_db3_cl" "0 ok"
_db3_new sr --red "$DB3/g-empty.tsv" "$DB3/man.tsv" "$DB3/pp/sh"/00[123456789]0-*.sh "$DB3/pp/sh"/01[012]0-*.sh; _db3_E=(DJX_ULIM="$_db3_ul"); _db3_run r -j 3 --record-assertions
is "R8: in a record run the seventh failure writes no manifest, and red.tsv holds the rows base - - - and run - - -" "$(_db3_chkr r "${_db3_xx[@]}")" ok
is "R1: and once that record run has exited no process of red's tree is left, stopped or running" "$_db3_ex" ok
rm -rf "$DB3/n/sh" "$DB3/n/shp" "$DB3/n/sj" "$DB3/n/sr"

# ---- the gate (D1, R10): gate.sh beside a stub tests/run that records its arguments and FELIX_TEST_JOBS
_db3_G="$DB3/gt"; mkdir -p "$_db3_G/engine/harness/tests" "$_db3_G/projects/felix" "$DB3/gtmp" "$DB3/gout"
cp "$REAL_HARNESS/../../projects/felix/gate.sh" "$_db3_G/projects/felix/gate.sh"
cat > "$_db3_G/engine/harness/tests/run" <<'DB3STUB'
#!/usr/bin/env bash
printf '%s:%s\n' "$#" "$*" >> "$DJX_OUT/$DJX_L.args"
printf '%s\n' "${FELIX_TEST_JOBS-unset}" >> "$DJX_OUT/$DJX_L.jobs"
if [ -n "${DJX_EXIT2:-}" ]; then printf 'djx stub: a refusal of its own\n' >&2; exit 2; fi
printf 'reused the suite run that ended 09:00 on this tree (normal), not run again\n'
printf '\n7 passed, 0 failed (reused)\n'
DB3STUB
chmod +x "$_db3_G/engine/harness/tests/run"
( _fx_cd "${_db3_G:?}" && git init -q -b main && git add -A && git -c user.name=djx -c user.email=djx@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm seed ) >/dev/null 2>&1
_db3_gate() {   # LABEL ENV...: gate.sh in the fixture, the stub recording as LABEL
  local l="$1"; shift
  ( cd "${_db3_G:?}" && perl "$DB3/run.pl" 90 DEFAULT DEFAULT "$DB3/gout/$l.pid" env -u FELIX_TEST_NO_MANIFEST -u GITHUB_ACTIONS -u FELIX_TEST_JOBS \
      FELIX_KERNEL_CACHE="$_db3_G/no-cache" TMPDIR="$DB3/gtmp" DJX_OUT="$DB3/gout" DJX_L="$l" ${1+"$@"} bash projects/felix/gate.sh ) > "$DB3/gout/$l.out" 2>&1
}
_db3_gate g1; _db3_gate g2 GITHUB_ACTIONS=true; _db3_gate g3 DJX_EXIT2=1; _db3_gate g4 GITHUB_ACTIONS=true FELIX_TEST_JOBS=7
is "D1: with GITHUB_ACTIONS unset, gate.sh sets FELIX_TEST_JOBS to the core count for its call to tests/run (sysctl, then getconf, then 1; held to 1 to 64)" "$(cat "$DB3/gout/g1.jobs" 2>/dev/null)" "$(_db3_cores)"
is "D1: with GITHUB_ACTIONS=true it does not set it (control)" "$(cat "$DB3/gout/g2.jobs" 2>/dev/null)" unset
is "R10: and with GITHUB_ACTIONS=true and a FELIX_TEST_JOBS=7 it inherited, the stub sees it unset" "$(cat "$DB3/gout/g4.jobs" 2>/dev/null)" unset
is "D1: and its argument list stays --reuse, in all three (control)" "$(cat "$DB3/gout/g1.args" 2>/dev/null) $(cat "$DB3/gout/g2.args" 2>/dev/null) $(cat "$DB3/gout/g4.args" 2>/dev/null)" "1:--reuse 1:--reuse 1:--reuse"
is "D1: when tests/run exits 2, the log's last line is shown under tests FAIL" \
   "$(LC_ALL=C awk '/^  tests +FAIL$/ { f = 1; next } f && index($0, "djx stub: a refusal of its own") { h = 1 } END { print f + 0, h + 0 }' "$DB3/gout/g3.out" 2>/dev/null)" "1 1"
is "R12: no run of this part left a process in its process group, stopped or running, after the 30 s it was given" "${_db3_leak:-none}" none
unset -f $(compgen -A function _db3_) 2>/dev/null
unset $(compgen -A variable _db3_) DB3 2>/dev/null
# <<< gate-friction-d-runner-failures-blind
