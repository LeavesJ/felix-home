# >>> gate-friction-d-shell-blind
printf '\ngate friction D: the shell a unit leaves for the parts after it (blind, revision 9)\n'
# Blind, written from contract D revision 9 alone (docs/2026-10-18-gate-friction-contract-d.md: D3, D8, R8, R12, R16, R24, R28). Nothing here was read off an
# implementation; tests/run is run, never read, in copies of this suite that _suite_copy_tree (part 0003) makes under $TMP, each with planted parts of
# this block's own. Every case points TMPDIR at a fixture directory, runs every inner run under a bounded runner that makes its own process group and
# resets HUP and TERM, and ends by asking that group to hold no live process, stopped or running (zombies aside), for 30 s; what is left is named,
# then sent CONT and KILL by pid. Nothing is killed by pattern: a sleeper a planted part leaves is ended by the pid it wrote down.
# The planted parts are one set, each doing one thing to the shell and then printing its own ok line. They are numbered so that the ones that spoil
# the shell for what follows (a closed descriptor, a disabled printf or enable, a removed EXIT trap) come last, so a -j 1 run reaches every one.
# Four kinds: x leaves the shell changed (the seventh failure under -j 3, none under -j 1); p passes; s is skipped; j is a part that is only judged
# under -j 3 and left out of the -j 1 run, since a function that forwards nothing (perl() { :; }) would break the parts after it there (R28); c is a
# part that only the -j 1 run holds, a control (a function that forwards, which R28 no longer counts as a case of the seventh failure).
# Names say the clause: R8 the first comparison, R16 what it was widened to, R24 every builtin's status, aliases and readonly functions, R28 the
# shadows that forward nothing, the watched variables, a trap removed and a group. Each change line is the one the contract gives, as written.
# An assertion whose name ends in (control) passes before D is built on purpose.
DB5="$TMP/db5"
mkdir -p "$DB5/pp/std" "$DB5/pp/sh" "$DB5/exp" "$DB5/n"
_db5_E=(); _db5_pf=(); _db5_cl=ok; _db5_ex=ok; _db5_leak=""; _db5_ctl=0; _db5_lim=150
cat > "$DB5/run.pl" <<'DB5PL'
my ($t, $f) = splice(@ARGV, 0, 2);
my $p = fork; defined $p or exit 125;
if (!$p) { setpgrp(0, 0); $SIG{INT} = 'DEFAULT'; $SIG{QUIT} = 'DEFAULT'; $SIG{HUP} = 'DEFAULT'; $SIG{TERM} = 'DEFAULT'; if (open(my $h, ">", $f)) { print $h "$$\n"; close $h } exec @ARGV; exit 127 }
$SIG{ALRM} = sub { kill "KILL", -$p; exit 124 };
alarm $t; waitpid $p, 0;
exit(($? & 127) ? 128 + ($? & 127) : $? >> 8);
DB5PL
# FIRST SECOND LABEL: LABEL: FIRST-line is now SECOND-line, for the first line of two listings that differs
cat > "$DB5/ld.pl" <<'DB5LD'
my @a = split /\n/, $ARGV[0]; my @b = split /\n/, $ARGV[1];
for my $i (0 .. $#a) { next if $a[$i] eq ($b[$i] // ""); print "$ARGV[2]: $a[$i] is now ", ($b[$i] // ""), "\n"; last }
DB5LD
: > "$DB5/g-empty.tsv"; printf '1\tdjx a1\n' > "$DB5/man.tsv"
printf 'printf "\\ndjx-sec 0010-pa.sh\\n"\nok "djx a1"\n' > "$DB5/pp/std/0010-pa.sh"
_db5_until() { local n="$1" i=0; shift; while [ "$i" -lt "$n" ]; do "$@" && return 0; sleep 0.2; i=$((i + 1)); done; "$@"; }
_db5_cnt()  { LC_ALL=C awk -v p="$2" 'index($0, p) == 1 { n++ } END { print n + 0 }' "$1" 2>/dev/null; }   # FILE PREFIX: lines starting with it
_db5_line() { grep -cxF -e "$2" "$1" 2>/dev/null; }   # FILE LINE: lines that are exactly it
# The members of the process groups $* that are not zombies, one a line: PID STAT COMMAND.
_db5_gm() { ps -A -o pid= -o pgid= -o stat= -o command= 2>/dev/null | G=" $* " LC_ALL=C awk 'index(ENVIRON["G"], " " $2 " ") && $3 !~ /^Z/ { c = $0; sub(/^ *[0123456789]+ +[0123456789]+ +[^ ]+ +/, "", c); print $1 " " $3 " " substr(c, 1, 70) }'; }
_db5_gs() { local f; for f in ${_db5_pf[@]+"${_db5_pf[@]}"}; do printf ' %s' "$(cat "$f" 2>/dev/null)"; done; }   # the ids of the process groups of this case's runs
# R1: "ok" when no process of those groups is alive at two listings 0.1 s apart, the first taken at once after a run has exited, else the ones in both.
_db5_atexit() {
  local g l1 l2 l="" p; g="$(_db5_gs)"
  [ -n "${g// /}" ] || { printf ok; return 0; }
  l1="$(_db5_gm $g)"; [ -n "$l1" ] || { printf ok; return 0; }
  sleep 0.1; l2="$(_db5_gm $g)"
  for p in $(printf '%s\n' "$l1" | awk '{ print $1 }'); do case "$l2" in "$p "*|*$'\n'"$p "*) l="$l$(printf '%s\n' "$l2" | grep -F -e "$p " | sed -n 1p);" ;; esac; done
  [ -n "$l" ] && printf 'left at its exit: %s' "$l" || printf ok
}
# R12: "ok" once the groups of this case's runs hold no live process (30 s), else what was left, sent CONT and then KILL by pid.
_db5_clean() {
  local g l="" i=0 p; g="$(_db5_gs)"
  [ -n "${g// /}" ] || { printf ok; return 0; }
  while [ "$i" -lt 150 ]; do l="$(_db5_gm $g)"; [ -n "$l" ] || { printf ok; return 0; }; sleep 0.2; i=$((i + 1)); done
  for p in $(printf '%s\n' "$l" | awk '{ print $1 }'); do kill -CONT "$p" 2>/dev/null; done
  for p in $(printf '%s\n' "$l" | awk '{ print $1 }'); do kill -KILL "$p" 2>/dev/null; done
  printf 'left behind: %s' "$(printf '%s' "$l" | tr '\n' ';')"
}
# The sleepers a planted part left running (job.pids): each is ended by the pid it wrote down, after a look that the pid still is that sleep.
_db5_reap() {
  local p c
  for p in $(cat "$_db5_c/job.pids" 2>/dev/null); do
    c="$(ps -o command= -p "$p" 2>/dev/null)"; case "$c" in "sleep 30"*) kill -KILL "$p" 2>/dev/null ;; esac
  done
  return 0
}
# CASE [--red] GROUPS MANIFEST STUB...: the copy at $DB5/n/CASE (_db5_F, _db5_T, _db5_c, _db5_tmp); 1 when it could not be made
_db5_new() {
  local n="$1" r=""; shift
  [ "${1:-}" != --red ] || { r=--red; shift; }
  _db5_c="$DB5/n/$n"; _db5_F="$_db5_c/f"; _db5_T="$_db5_F/engine/harness/tests"; _db5_tmp="$_db5_c/tmp"; _db5_pf=()
  rm -rf "$_db5_c"; mkdir -p "$_db5_tmp" || return 1
  _suite_copy_tree ${r:+"$r"} "$_db5_F" "$@"
}
# LABEL ARG...: the copy's driver in the background under a bounded runner (stdin /dev/null, stdout LABEL.out, stderr LABEL.err, the group's id
# LABEL.pid). LC_ALL, LC_COLLATE and CLAUDE_CONFIG_DIR are taken out of its environment, so that a part that exports them adds them.
_db5_start() {
  local l="$1"; shift
  ( cd "$_db5_F" && exec env -u FELIX_TEST_NO_MANIFEST -u FELIX_TEST_JOBS -u FELIX_TEST_SLOTS -u FELIX_TEST_RED_JOBS -u FELIX_TEST_SLOT_NOTE -u FELIX_TEST_PART_LOG \
      -u FELIX_TEST_PART_RAN -u FELIX_TEST_PART_END -u FELIX_TEST_PART_RECORD -u PERL5OPT -u LC_ALL -u LC_COLLATE -u CLAUDE_CONFIG_DIR \
      TMPDIR="$_db5_tmp" FELIX_TEST_SLOTS=8 DJX_DIR="$_db5_c" DJX_PL="$DB5" DJX_KEEP=1 ${_db5_E[@]+"${_db5_E[@]}"} \
      perl "$DB5/run.pl" "$_db5_lim" "$_db5_c/$l.pid" "$BASH" "$_db5_T/run" "$@" \
  ) < /dev/null > "$_db5_c/$l.out" 2> "$_db5_c/$l.err" &
  _db5_bg=$!; _db5_pf[${#_db5_pf[@]}]="$_db5_c/$l.pid"
}
_db5_wait() { { wait "$_db5_bg"; } 2>/dev/null; _db5_rc=$?; _db5_E=(); }
_db5_run()  {   # _db5_ex: R1's verdict on this run, _db5_cl: R12's, whose findings _db5_leak keeps
  _db5_start "$@"; _db5_wait; _db5_reap; _db5_ex="$(_db5_atexit)"; _db5_cl="$(_db5_clean)"
  [ "$_db5_cl" = ok ] || _db5_leak="$_db5_leak [$_db5_c: $_db5_cl]"
}
_db5_rcpt() { if [ -f "$_db5_F/.git/felix-suite-receipt" ]; then echo present; else echo absent; fi; }
_db5_last() { tail -n 1 "$_db5_c/$1.out" 2>/dev/null; }
_db5_redrows() { if [ -f "$_db5_T/red.tsv" ]; then grep -v '^#' "$_db5_T/red.tsv" | tr '\n' '|'; else printf '(no red.tsv)'; fi; }
_db5_w="part left the shell changed for the parts after it"
# LABEL EXPECT...: "ok", or what differed, for the run LABEL just made: exit 1; each EXPECT a FAIL line printed once ("!X": never starting so); the summary
# counts as many failures as the log has FAIL lines; no receipt, and a control showing a passing run leaves one
_db5_chk() {
  local l="$1" e c r="" s wf; shift
  [ "$_db5_rc" = 1 ] || r="$r exit $_db5_rc, not 1;"
  for e in "$@"; do
    case "$e" in
      !*) c="$(_db5_cnt "$_db5_c/$l.out" "  FAIL  ${e#!}")"; [ "$c" = 0 ] || r="$r [${e#!}] printed $c times;" ;;
      *) c="$(_db5_cnt "$_db5_c/$l.out" "  FAIL  $e")"; [ "$c" = 1 ] || r="$r [$e] printed $c times;" ;;
    esac
  done
  s="$(_db5_last "$l")"; wf="$(_db5_cnt "$_db5_c/$l.out" '  FAIL  ')"
  case "$s" in *" passed, "*" failed"*) s="${s#* passed, }"; s="${s%% failed*}"; [ "$s" = "$wf" ] || r="$r summary counts $s failed, not $wf;" ;; esac
  [ "$_db5_ctl" = 1 ] || r="$r the control left no receipt, so a missing one says nothing;"
  [ "$(_db5_rcpt)" = absent ] || r="$r a receipt was left;"
  printf '%s' "${r:-ok}"
}
# LABEL EXPECT...: _db5_chk for a record run, the manifest as it was, and red.tsv the two retraction rows (red has gone: _db5_run waited for the group)
_db5_chkr() {
  local r; r="$(_db5_chk "$@")"; [ "$r" != ok ] || r=""
  cmp -s "$DB5/man.tsv" "$_db5_T/assertions.tsv" || r="$r the manifest was rewritten;"
  [ "$(_db5_redrows)" = "$(printf 'base\t-\t-\t-|run\t-\t-\t-|')" ] || r="$r red.tsv holds [$(_db5_redrows)];"
  printf '%s' "${r:-ok}"
}
# OUT UNIT: the "  | " lines directly after UNIT's seventh failure, sorted, one a line; when the failure is not printed exactly once, say so
_db5_bars() {
  LC_ALL=C awk -v u="  FAIL  $_db5_w: $2" '
    $0 == u { n++; on = 1; next }
    on && index($0, "  | ") == 1 { b[++k] = substr($0, 5); next }
    { on = 0 }
    END { if (n != 1) { print "[the failure was printed " n + 0 " times]"; exit } for (i = 1; i <= k; i++) print b[i] }' "$_db5_c/$1" | LC_ALL=C sort
}
# The planted parts. _db5_sp NAME DESC KIND CODE [EXPECTED-LINE...]: part NNN0-NAME.sh does CODE and then its own ok line. KIND x: it leaves the shell
# changed, and the seventh failure's bar lines are exactly the EXPECTED-LINEs (none given: the part writes them to $DJX_DIR/exp.NAME); j: as x, but
# only the -j 3 run holds it; c: as p, but only the -j 1 run holds it; p: it passes; s: skipped, the part does nothing, and _db5_skr says why.
_db5_i=0; _db5_sn=(); _db5_sd=(); _db5_sk=(); _db5_sc=(); _db5_sr=(); _db5_skr=
_db5_sp() {
  local f
  _db5_i=$((_db5_i + 1)); f="$(printf '%04d-%s.sh' $((_db5_i * 10)) "$2")"
  printf 'printf "\\ndjx-sec %s\\n"\n%s\nok "djx shell %s"\n' "$f" "$5" "$2" > "$DB5/pp/sh/$f"
  _db5_sc[$_db5_i]="$1"; _db5_sn[$_db5_i]="$2"; _db5_sd[$_db5_i]="$3"; _db5_sk[$_db5_i]="$4"; _db5_sr[$_db5_i]="$_db5_skr"; _db5_skr=""
  [ "$#" -le 5 ] || { shift 5; printf '%s\n' "$@" > "$DB5/exp/${_db5_sn[$_db5_i]}"; }
}
_db5_unit() { printf '%04d-%s.sh' $(($1 * 10)) "${_db5_sn[$1]}"; }
_db5_ul="$(ulimit -S -n 2>/dev/null)"; case "$_db5_ul" in ''|*[!0123456789]*) _db5_ul=0 ;; esac
# the first two functions tests/lib defines, other than its _vars functions: a part redefines the first and unsets the second
_db5_fn=($(LC_ALL=C awk '/^_[a-z0-9_]+\(\) *[{]/ { s = $1; sub(/\(\).*/, "", s); if (s !~ /_vars$/ && !(s in seen) && ++k <= 2) { seen[s] = 1; print s } }' "$HERE"/lib/*.sh))
# R16: a resource whose hard limit is above its soft one and can be lowered to it, measured in a child of this bash (flag and soft value), or nothing
_db5_uh="$("$BASH" -c 'for f in c s n d f l m t v u; do
    s="$(ulimit -S -$f 2>/dev/null)" || continue; h="$(ulimit -H -$f 2>/dev/null)" || continue
    case "$s" in ""|*[!0123456789]*) continue ;; esac
    [ "$s" != "$h" ] || continue
    ( ulimit -H -$f "$s" ) 2>/dev/null || continue
    echo "$f $s"; exit 0
  done' 2>/dev/null)"
_db5_ulf="${_db5_uh% *}"; _db5_uls="${_db5_uh#* }"
_db5_umk='djx_w="$(umask)"; case "$djx_w" in 0077|077) umask 027 ;; *) umask 077 ;; esac; printf "umask %s is now %s\n" "$djx_w" "$(umask)"'

_db5_sp R8 umask "umask 077 left set" x "$_db5_umk"' > "$DJX_DIR/exp.umask"; unset djx_w'
_db5_sp R8 shopt "shopt -s nullglob left set" x 'shopt -s nullglob' 'shopt -u nullglob is now shopt -s nullglob'
_db5_sp R8 trap "a trap on USR1 left set" x 'trap : USR1' 'trap on SIGUSR1 added'
_db5_sp R8 unexp "an exported variable the case set, unset" x 'unset DJX_KEEP' 'export DJX_KEEP removed'
_db5_sp R8 fnre "a function of tests/lib redefined" x "${_db5_fn[0]:-NONE}() { :; }" "function ${_db5_fn[0]:-NONE} changed"
_db5_sp R8 fnun "a function of tests/lib unset, as part 0290 did" x "unset -f ${_db5_fn[1]:-NONE}" "function ${_db5_fn[1]:-NONE} removed"
_db5_sp R8 felix "FELIX given another value" x 'FELIX=/djx/other' 'variable FELIX changed'
_db5_sp R8 fd7 "descriptor 7 left open" x 'exec 7>/dev/null' 'descriptor 7 opened'
if [ "$_db5_ul" -ge 8 ]; then
  _db5_sp R8 ulimit "a soft limit lowered with ulimit -S" x 'djx_w="$(ulimit -Sa)"; ulimit -S -n "$((DJX_ULIM - 1))"; djx_n="$(ulimit -Sa)"
perl "$DJX_PL/ld.pl" "$djx_w" "$djx_n" "ulimit -a" > "$DJX_DIR/exp.ulimit"; unset djx_w djx_n'
else _db5_skr="the soft limit on open files is [$(ulimit -S -n 2>/dev/null)], not a number to lower"; _db5_sp R8 ulimit "a soft limit lowered with ulimit -S" s ':'; fi
_db5_sp R8 newvar "a part that sets a new variable" p 'djx_new_variable=1'
_db5_sp R8 newfn "a part that defines a new function that hides no builtin, keyword or command" p 'djx_new_function() { :; }'
_db5_sp R8 libvar "a part that changes a variable of tests/lib" p 'IB_BR=x; _AU_F=/djx/changed'
_db5_sp R16 newexp "a part that exports a new name outside the old steering list, which R8 passed" x 'export DJX_NEW_EXPORT=1' 'export DJX_NEW_EXPORT added'
_db5_sp R16 repo "unset REPO, a plain variable the prelude sets" x 'unset REPO' 'variable REPO removed'
_db5_sp R16 roots "a change to _fx_roots, an underscore-prefixed prelude variable" x '_fx_roots="$_fx_roots"$'"'"'\n'"'"'"$TMP/djx-root"' 'variable _fx_roots changed'
_db5_sp R16 keep "a new value for an export the case made before the run" x 'DJX_KEEP=2' 'export DJX_KEEP changed'
_db5_sp R16 lcall "export LC_ALL=C, with LC_ALL absent from the run's environment" x 'export LC_ALL=C' 'export LC_ALL added'
_db5_sp R16 cfgdir "export CLAUDE_CONFIG_DIR=/x, with it absent from the run's environment" x 'export CLAUDE_CONFIG_DIR=/x' 'export CLAUDE_CONFIG_DIR added'
_db5_sp R28 cdpath "CDPATH=/djx, a plain variable the main shell itself reads" x 'CDPATH=/djx' 'variable CDPATH added'
_db5_sp R28 lccoll "LC_COLLATE=C plain, with LC_COLLATE absent from the run's environment" x 'LC_COLLATE=C' 'variable LC_COLLATE added'
_db5_sp R28 optind "OPTIND=5" x 'OPTIND=5' 'variable OPTIND changed'
_db5_sp R16 posn "set -- a b c" x 'set -- a b c' 'positional parameters changed'
_db5_sp R16 pushd "pushd of the working directory, which leaves the stack changed and the directory as found" x 'pushd "$PWD" >/dev/null' 'directory stack changed'
_db5_sp R16 ro "readonly djx_ro=1" x 'readonly djx_ro=1' 'readonly djx_ro added'
_db5_sp R16 job "sleep 30 & left running" x 'sleep 30 &
printf "%s\n" "$!" >> "$DJX_DIR/job.pids"; printf "job %s left running\n" "$!" > "$DJX_DIR/exp.job"'
if [ -n "$_db5_ulf" ] && [ "$_db5_ulf" != "$_db5_uh" ]; then
  _db5_sp R16 ulh "a hard limit lowered with ulimit -H to its soft value" x 'djx_w="$(ulimit -Ha)"; ulimit -H -'"$_db5_ulf $_db5_uls"'; djx_n="$(ulimit -Ha)"
perl "$DJX_PL/ld.pl" "$djx_w" "$djx_n" "ulimit -Ha" > "$DJX_DIR/exp.ulh"; unset djx_w djx_n'
else _db5_skr="no resource has a hard limit above its soft one that this bash can lower"; _db5_sp R16 ulh "a hard limit lowered with ulimit -H to its soft value" s ':'; fi
_db5_sp R8 path "PATH changed" x 'PATH="$PATH:/djx/none"' 'export PATH changed'
_db5_sp R8 git "git() { :; } left defined" x 'git() { :; }' 'function git added over a command'
_db5_sp R8 gitdir "GIT_DIR exported" x 'export GIT_DIR=/djx/x' 'export GIT_DIR added'
# functions that forward to the real tool pin nothing of the guard (a comparator that calls perl or export by name reads the same through them), so under -j 3 they
# are no case of the seventh failure (R28): they stay as -j 1 controls. The ones that forward nothing are the cases, each in a unit of its own, beside umask 077.
_db5_sp R16 expfn "export() { builtin export \"\$@\"; } left defined, a -j 1 control" c 'export() { builtin export "$@"; }'
_db5_sp R16 perlum "perl() { command perl \"\$@\"; } beside umask 077, a -j 1 control" c "$_db5_umk"' > "$DJX_DIR/exp.perlum"; unset djx_w; perl() { command perl "$@"; }'
_db5_sp R28 shperl "perl() { :; } beside umask 077" j "$_db5_umk"' > "$DJX_DIR/exp.shperl"; unset djx_w
printf "function perl added over a command\n" >> "$DJX_DIR/exp.shperl"; perl() { :; }'
_db5_sp R28 shcomp "compgen() { :; } beside umask 077" j "$_db5_umk"' > "$DJX_DIR/exp.shcomp"; unset djx_w
printf "function compgen added over a builtin\n" >> "$DJX_DIR/exp.shcomp"; compgen() { :; }'
_db5_sp R28 shdecl "declare() { :; } beside umask 077" j "$_db5_umk"' > "$DJX_DIR/exp.shdecl"; unset djx_w
printf "function declare added over a builtin\n" >> "$DJX_DIR/exp.shdecl"; declare() { :; }'
# the driver runs under set -uo pipefail (tests/run:17), so a bare set -o pipefail would change nothing: the part measures the option in its own shell and flips it
_db5_sp R16 pipefail "the set -o pipefail option flipped from what the unit's shell has" x 'djx_w="$(set +o | grep " pipefail$")"
case "$djx_w" in "set -o pipefail") set +o pipefail ;; *) set -o pipefail ;; esac
printf "%s is now %s\n" "$djx_w" "$(set +o | grep " pipefail$")" > "$DJX_DIR/exp.pipefail"; unset djx_w'
_db5_sp R16 fd0 "exec 0<&-" x 'exec 0<&-' 'descriptor 0 closed'
_db5_sp R16 enable "enable -n printf" x 'enable -n printf' 'builtin printf disabled'
_db5_sp R24 enabl2 "enable -n enable, which hides the list of disabled builtins from the comparison" x 'enable -n enable' 'the shell state could not be compared'
_db5_sp R24 alias "alias djx_al=true" x 'alias djx_al=true' 'alias djx_al added'
_db5_sp R24 rofn "a readonly function" x 'djx_rf() { :; }; readonly -f djx_rf' 'readonly function djx_rf added'
_db5_sp R16 fd2 "exec 2>&-" x 'exec 2>&-' 'descriptor 2 closed'
_db5_sp R16 trapexit "trap 'printf \"djx-exit\\n\"' EXIT" x 'trap '"'"'printf "djx-exit\n"'"'"' EXIT' 'trap on EXIT changed'
_db5_sp R28 trapnone "trap - EXIT, the prelude's EXIT trap removed, numbered last so that the -j 1 run reaches every part" x 'trap - EXIT' 'trap on EXIT removed'
_db5_n=$_db5_i
_db5_a1=(); _db5_a3=(); _db5_px=(); _db5_pp=(); _db5_xx=(); _db5_k=1   # the -j 1 set, the -j 3 set, the parts that fail, the ones that pass, their failures
while [ "$_db5_k" -le "$_db5_n" ]; do
  _db5_f="$DB5/pp/sh/$(_db5_unit "$_db5_k")"
  case "${_db5_sk[$_db5_k]}" in
    x|j) _db5_px[${#_db5_px[@]}]="$_db5_f"; _db5_xx[${#_db5_xx[@]}]="$_db5_w: $(_db5_unit "$_db5_k")" ;;
    p) _db5_pp[${#_db5_pp[@]}]="$_db5_f" ;;
  esac
  case "${_db5_sk[$_db5_k]}" in j) ;; *) _db5_a1[${#_db5_a1[@]}]="$_db5_f" ;; esac
  case "${_db5_sk[$_db5_k]}" in c) ;; *) _db5_a3[${#_db5_a3[@]}]="$_db5_f" ;; esac
  _db5_k=$((_db5_k + 1))
done
_db5_oks() {   # OUT KINDS: the ok line of every planted part of those kinds is in OUT exactly once: "ok", or the names of those that are not
  local k=1 r="" c
  while [ "$k" -le "$_db5_n" ]; do
    case "$2" in *"${_db5_sk[$k]}"*) c="$(_db5_line "$_db5_c/$1" "  ok    djx shell ${_db5_sn[$k]}")"; [ "$c" = 1 ] || r="$r ${_db5_sn[$k]}:$c" ;; esac
    k=$((k + 1))
  done
  printf '%s' "${r:-ok}"
}

# ---- the controls: planted parts that pass, under -j 3 (D8), and a copy with a manifest, so that a missing receipt says something
_db5_new pn "$DB5/g-empty.tsv" - "$DB5/pp/std/0010-pa.sh"; _db5_run n1 -j 1
printf '1\t%s\n' "$(sed -n 's/^  ok    //p' "$_db5_c/n1.out" | sed -n 1p)" > "$DB5/pman.tsv"
rm -rf "$DB5/n/pn"
_db5_new sp "$DB5/g-empty.tsv" "$DB5/pman.tsv" ${_db5_pp[@]+"${_db5_pp[@]}"}; _db5_E=(DJX_ULIM="$_db5_ul"); _db5_run sp -j 3
_db5_x="$(_db5_oks sp.out p)"
[ "$_db5_rc" = 0 ] && [ "$(_db5_rcpt)" = present ] && _db5_ctl=1
is "R8: a new plain variable, a new function that hides nothing and a change to a variable of tests/lib each pass under -j 3: the run exits 0, leaves a receipt and no process, every part printed its ok line once, and none gave the seventh failure" \
   "$_db5_rc $(_db5_rcpt) $_db5_cl $_db5_x $(_db5_cnt "$_db5_c/sp.out" "  FAIL  $_db5_w")" "0 present ok ok 0"
rm -rf "$DB5/n/sp"

# ---- every part together under -j 3: the seventh failure of each, once, with exactly its change lines
_db5_new sh "$DB5/g-empty.tsv" "$DB5/pman.tsv" "${_db5_a3[@]}"; _db5_E=(DJX_ULIM="$_db5_ul"); _db5_run s3 -j 3
_db5_ny=(); _db5_k=1; while [ "$_db5_k" -le "$_db5_n" ]; do
  case "${_db5_sk[$_db5_k]}" in p) _db5_ny[${#_db5_ny[@]}]="!$_db5_w: $(_db5_unit "$_db5_k")" ;; esac; _db5_k=$((_db5_k + 1)); done
is "R8: every part that leaves the shell changed gives the seventh failure, once, and the ones that do not give none: the run exits 1, counts them in its summary, leaves no receipt and no process, and every part printed its ok line once" \
   "$(_db5_chk s3 "${_db5_xx[@]}" ${_db5_ny[@]+"${_db5_ny[@]}"}) $_db5_cl $(_db5_oks s3.out xpsj)" "ok ok ok"
_db5_k=1; while [ "$_db5_k" -le "$_db5_n" ]; do
  _db5_nm="${_db5_sn[$_db5_k]}"; _db5_t="${_db5_sc[$_db5_k]}: ${_db5_sd[$_db5_k]} gives the seventh failure with exactly its change line"
  case "${_db5_sk[$_db5_k]}" in
    s) skip "$_db5_t" "${_db5_sr[$_db5_k]}" ;;
    p) ;;
    x|j)
      _db5_e="$(if [ -f "$DB5/exp/$_db5_nm" ]; then cat "$DB5/exp/$_db5_nm"; else cat "$_db5_c/exp.$_db5_nm" 2>/dev/null; fi | LC_ALL=C sort)"
      _db5_g="$(_db5_bars s3.out "$(_db5_unit "$_db5_k")")"
      is "$_db5_t" "$([ -n "$_db5_e" ] && [ "$_db5_g" = "$_db5_e" ] && echo ok || echo "got [$(printf '%s' "$_db5_g" | tr '\n' '|')], wanted [$(printf '%s' "$_db5_e" | tr '\n' '|')]")" ok ;;
  esac
  _db5_k=$((_db5_k + 1))
done

# ---- R28: a group's unit is compared over its members: the first of two members leaves nullglob set, and the unit gives one seventh failure, named for the group
mkdir -p "$DB5/pp/grp"; printf 'djg\t0010-ga.sh\ndjg\t0020-gb.sh\n' > "$DB5/g-grp.tsv"
printf '%s\n' 'printf "\ndjx-sec 0010-ga.sh\n"' 'shopt -s nullglob' 'ok "djx grp a"' > "$DB5/pp/grp/0010-ga.sh"
printf '%s\n' 'printf "\ndjx-sec 0020-gb.sh\n"' 'ok "djx grp b"' > "$DB5/pp/grp/0020-gb.sh"
_db5_new sg "$DB5/g-grp.tsv" "$DB5/pman.tsv" "$DB5/pp/grp/0010-ga.sh" "$DB5/pp/grp/0020-gb.sh"; _db5_run g3 -j 3
is "R28: a two-member group whose first member leaves nullglob set gives one seventh failure naming the group's unit, exit 1, no receipt, no process, and both members printed their ok line once" \
   "$(_db5_chk g3 "$_db5_w: djg" "!$_db5_w: 0010-ga.sh" "!$_db5_w: 0020-gb.sh") $_db5_cl $(_db5_line "$_db5_c/g3.out" '  ok    djx grp a') $(_db5_line "$_db5_c/g3.out" '  ok    djx grp b')" "ok ok 1 1"
is "R28: and its one bar line is shopt -u nullglob is now shopt -s nullglob" "$(_db5_bars g3.out djg)" "shopt -u nullglob is now shopt -s nullglob"
rm -rf "$DB5/n/sg"

# ---- under -j 1 nothing is compared: none of them gives the seventh failure, and the run is known to have reached every part
_db5_new sj "$DB5/g-empty.tsv" "$DB5/pman.tsv" "${_db5_a1[@]}"; _db5_E=(DJX_ULIM="$_db5_ul"); _db5_lim=100; _db5_run s1 -j 1; _db5_lim=150
is "R8: under -j 1 none of them gives the seventh failure (R24, R28 included), a change carrying to the parts after it as it always did, and every part of the -j 1 set printed its ok line once, so the run reached them all" \
   "$(_db5_cnt "$_db5_c/s1.out" "  FAIL  $_db5_w") $(_db5_oks s1.out xpsc) $_db5_cl" "0 ok ok"

# ---- a record run: the seventh failure writes no manifest, and red.tsv holds the two retraction rows
_db5_new sr --red "$DB5/g-empty.tsv" "$DB5/man.tsv" "${_db5_px[@]}"; _db5_E=(DJX_ULIM="$_db5_ul"); _db5_run r -j 3 --record-assertions
is "R8: in a record run the seventh failure writes no manifest, and red.tsv holds the rows base - - - and run - - -, with no process left" "$(_db5_chkr r "${_db5_xx[@]}") $_db5_cl" "ok ok"
is "R1: and once that record run has exited no process of red's tree is left, stopped or running" "$_db5_ex" ok
rm -rf "$DB5/n/sh" "$DB5/n/sj" "$DB5/n/sr"

is "R12: no run of this part left a process in its process group, stopped or running, after the 30 s it was given" "${_db5_leak:-none}" none
unset -f $(compgen -A function _db5_) 2>/dev/null
unset $(compgen -A variable _db5_) DB5 2>/dev/null
# <<< gate-friction-d-shell-blind
