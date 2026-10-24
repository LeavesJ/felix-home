# >>> unit-facts-and-tracer-blind
printf '\naudit b30: unit facts, the tracer and maps (blind)\n'
# Blind, written on 2026-10-24 from docs/2026-10-24-audit-fixes/b30-plan-a-unit-facts-and-map.md alone (B1 to B20, A1 to A67, fixture S). No code
# the contract is about was read: tests/run, tests/trace.sh, tests/select*.sh and felix testmap are run, never read, in copies of this suite that
# _suite_copy_tree (part 0003) makes under $TMP/tm. Each copy gets a second commit, with refs/remotes/origin/main moved to it, holding this suite's
# trace.sh, select.sh and select-*.sh (those that exist) and, in T, the fixture libraries. Every run of a copy is from its top, under a bounded runner
# of part 1291's shape (its own process group, a time limit, INT, QUIT, HUP and TERM at their defaults), in the environment fixture S names, with
# TMPDIR a fixture directory and a stand-in mktemp first on PATH that hands mktemp -d a template under TMPDIR (part 1295's R41: macOS mktemp -d
# ignores TMPDIR). Every run ends by asking its process group to hold no live process for 30 s; what is left is named in the closing fixture
# assertion, then sent CONT and KILL by pid. Nothing is killed by pattern. felix testmap is run with FELIX_HOME naming no directory (B21).
# Readings taken where the contract leaves room, said here:
# - T has eleven units, not twelve: A15 lists them, ten part names and tg (0080 and 0090 are tg), and that list is what is asserted.
# - A path the engine prints may be spelled with links resolved (/private/var on macOS) or as $TMP spells it; output is read with the first
#   spelling of $TMP replaced by the second. A top line is compared with links resolved on both sides.
# - A12's "no new file" is read as: the runs of P were there before the --part run and are byte for byte the same after it.
# - A35 asks only that 0040 and 0110 are fail: the contract pins no verdict for 0120 under tracing. A64 also asks for B17's felix testmap: prefix.
# - A19 and A32 hold on main too (an untraced run, and a trace dir main ignores); the contract marks neither a control.
# - B3x and B5x assertions skip on the other bash. An assertion whose name ends in (control) holds before and after the fix.
UF="$TMP/tm"
mkdir -p "$UF/pp/P" "$UF/pp/T" "$UF/lib" "$UF/c" "$UF/o" "$UF/x" "$UF/mk" "$UF/tmp" "$UF/d/D1" "$UF/d/D2" "$UF/d/D3" "$UF/d/D4" "$UF/d/D5"
_uf_pf=(); _uf_leak=""; _uf_fx=""; _uf_rc=""; _uf_E=(); _uf_tab="$(printf '\t')"
_uf_P="$(uname -s 2>/dev/null | LC_ALL=C tr ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz)"
_uf_ph="$(cd "$TMP" && pwd -P)"
_uf_b3=0; if [ "${BASH_VERSINFO[0]}" -lt 4 ] || { [ "${BASH_VERSINFO[0]}" -eq 4 ] && [ "${BASH_VERSINFO[1]}" -eq 0 ]; }; then _uf_b3=1; fi
_uf_s3="bash $BASH_VERSION here: this checks the bash 3.2 to 4.0 tracer"; _uf_s5="bash $BASH_VERSION here: this checks the bash 4.1 or later tracer"
cat > "$UF/run.pl" <<'UFPL'
my ($t, $f) = splice(@ARGV, 0, 2);
my $p = fork; defined $p or exit 125;
if (!$p) { setpgrp(0, 0); $SIG{INT} = 'DEFAULT'; $SIG{QUIT} = 'DEFAULT'; $SIG{HUP} = 'DEFAULT'; $SIG{TERM} = 'DEFAULT'; if (open(my $h, ">", $f)) { print $h "$$\n"; close $h } exec @ARGV; exit 127 }
$SIG{ALRM} = sub { kill "KILL", -$p; exit 124 };
alarm $t; waitpid $p, 0;
exit(($? & 127) ? 128 + ($? & 127) : $? >> 8);
UFPL
printf '#!/bin/sh\nt=0\nfor a in "$@"; do case "$a" in -*) ;; *) t=1 ;; esac; done\nif [ "$t" = 0 ] && [ -n "${TMPDIR:-}" ]; then set -- "$@" "${TMPDIR%%/}/tmp.XXXXXXXXXX"; fi\nexec "%s" "$@"\n' \
  "$(command -v mktemp)" > "$UF/mk/mktemp"; chmod +x "$UF/mk/mktemp"
: > "$UF/g-empty.tsv"; printf 'tg\t0080-tm-h.sh\ntg\t0090-tm-i.sh\n' > "$UF/g-T.tsv"
_uf_U="0010-tm-a.sh 0020-tm-b.sh 0030-tm-c.sh 0040-tm-d.sh 0050-tm-e.sh 0060-tm-f.sh 0070-tm-g.sh tg 0100-tm-j.sh 0110-tm-k.sh 0120-tm-l.sh"

# NAME TOOLS LIBS [--red] GROUPS MANIFEST STUB...: the copy $UF/c/NAME and its second commit (TOOLS 1: trace.sh, select.sh, select-*.sh; LIBS 1:
# the fixture libraries and an engine/harness/bin to resolve bin/.. through). A copy that cannot be made is named in _uf_fx.
_uf_copy() {
  local n="$1" t="$2" l="$3" r="" g f; shift 3
  [ "${1:-}" != --red ] || { r=--red; shift; }
  g="$UF/c/$n"; rm -rf "$g"
  _suite_copy_tree ${r:+"$r"} "$g" "$@" || { _uf_fx="$_uf_fx [$n: _suite_copy_tree]"; return 1; }
  if [ "$t" = 1 ]; then for f in "$HERE/trace.sh" "$HERE/select.sh" "$HERE"/select-*.sh; do [ ! -f "$f" ] || cp "$f" "$g/engine/harness/tests/${f##*/}"; done; fi
  if [ "$l" = 1 ]; then cp "$UF/lib"/tm-*.sh "$g/engine/harness/lib/" && mkdir -p "$g/engine/harness/bin" && : > "$g/engine/harness/bin/.keep"; fi
  { _fx_git "$g" add -A && _fx_git "$g" -c user.name=uf -c user.email=uf@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -q --allow-empty -m tools \
      && _fx_git "$g" update-ref refs/remotes/origin/main HEAD; } >/dev/null 2>&1 || { _uf_fx="$_uf_fx [$n: the second commit]"; return 1; }
}
_uf_gm() { ps -A -o pid= -o pgid= -o stat= -o command= 2>/dev/null | G=" $1 " LC_ALL=C awk 'index(ENVIRON["G"], " " $2 " ") && $3 !~ /^Z/ { print $1 }'; }
_uf_sweep() {   # LABEL: the run's process group holds no live process within 30 s, or what is left is named in _uf_leak and sent CONT and KILL by pid
  local g l="" i=0 p
  g="$(cat "$UF/o/$1.pid" 2>/dev/null)"; [ -n "$g" ] || return 0
  while [ "$i" -lt 150 ]; do l="$(_uf_gm "$g")"; [ -n "$l" ] || return 0; sleep 0.2; i=$((i + 1)); done
  for p in $l; do kill -CONT "$p" 2>/dev/null; kill -KILL "$p" 2>/dev/null; done
  _uf_leak="$_uf_leak [$1: $(printf '%s' "$l" | tr '\n' ' ')]"
}
# LABEL COPY LIMIT ARG...: the copy's driver, from its top, bounded, in fixture S's environment and _uf_E; $UF/o/LABEL.out and .err, _uf_rc
_uf_run() {
  local l="$1" c="$UF/c/$2" t="$3"; shift 3
  mkdir -p "$UF/tmp/$2"
  ( cd "$c" && exec env -u FELIX_TEST_UNIT -u FELIX_TEST_TRACE_DIR -u BASH_ENV -u FELIX_TEST_JOBS -u FELIX_TEST_SLOTS -u FELIX_TEST_NO_MANIFEST \
      -u FELIX_TEST_RED_JOBS -u FELIX_TEST_PART_LOG -u FELIX_TEST_PART_RAN -u FELIX_TEST_PART_END -u FELIX_TEST_PART_RECORD -u FELIX_TEST_SLOT_NOTE \
      TMPDIR="$UF/tmp/$2" FELIX_TEST_SLOTS=4 PATH="$UF/mk:$PATH" DJX_PMAN="$UF/pman.tsv" ${_uf_E[@]+"${_uf_E[@]}"} \
      perl "$UF/run.pl" "$t" "$UF/o/$l.pid" "$BASH" "$c/engine/harness/tests/run" "$@" ) > "$UF/o/$l.out" 2> "$UF/o/$l.err"
  _uf_rc=$?; _uf_E=(); _uf_sweep "$l"
}
# LABEL DIR ARG...: felix testmap ARG... from DIR with no Felix home; $UF/o/LABEL.out and .err, _uf_rc
_uf_tm() { local l="$1" d="$2"; shift 2; ( cd "$d" && exec env FELIX_HOME="$UF/nohome" "$FELIX" testmap "$@" ) > "$UF/o/$l.out" 2> "$UF/o/$l.err"; _uf_rc=$?; }
_uf_nm() { PH="$_uf_ph" LG="$TMP" LC_ALL=C awk '{ s = $0; o = ""; if (ENVIRON["PH"] != ENVIRON["LG"]) while ((i = index(s, ENVIRON["PH"])) > 0) { o = o substr(s, 1, i - 1) ENVIRON["LG"]; s = substr(s, i + length(ENVIRON["PH"])) } print o s }' "$1" 2>/dev/null; }
_uf_vl() { grep -E '^  (ok    |FAIL  |skip  )' "$UF/o/$1.out" 2>/dev/null | LC_ALL=C sort; }
_uf_same() { local d; d="$(LC_ALL=C diff <(_uf_vl "$1") <(_uf_vl "$2") | head -4 | tr '\n' '|')"; printf '%s' "${d:-same}"; }
_uf_rcpt() { if [ -f "$UF/c/$1/.git/felix-suite-receipt" ]; then echo present; else echo absent; fi; }
_uf_runs() { ls "$UF/c/$1/.git/felix-testmap/runs" 2>/dev/null | LC_ALL=C sort | tr '\n' ' '; }
_uf_runsum() { local f; for f in "$UF/c/$1/.git/felix-testmap/runs"/*; do [ ! -f "$f" ] || printf '%s %s|' "${f##*/}" "$(cksum < "$f")"; done; }
_uf_err1() { P="$2" LC_ALL=C awk 'NR == 1 { a = $0 } END { print (NR == 1 && index(a, ENVIRON["P"]) == 1) ? "ok" : NR + 0 " stderr lines, the first [" a "]" }' "$UF/o/$1.err" 2>/dev/null; }
_uf_grep() { grep "^$2" "$UF/o/$1.out" 2>/dev/null | tr '\n' ' '; }   # LABEL PREFIX: the stdout lines starting with it, joined
_uf_ntr() { local n=0 f; for f in "$1"/[0123456789]*.trace; do [ ! -f "$f" ] || n=$((n + 1)); done; printf '%s' "$n"; }   # DIR: its trace files
_uf_ref() { _uf_run "$1" "$2" 150 -j 2; _uf_v="$_uf_rc|$(_uf_err1 "$1" 'tests/run: FELIX_TEST_TRACE_DIR')|$(grep -c '^djx-sec' "$UF/o/$1.out")"; }   # B8's refusal: 2|ok|0
_uf_mu() { U="$1" LC_ALL=C awk -F'\t' '$1 == "unit" && $2 == ENVIRON["U"] { print $3 "|" $5; exit }' "$_uf_MT" 2>/dev/null; }   # UNIT: status|reason in MT
_uf_rows() { local r m="" n; for r in "$@"; do n="$(grep -cxF -e "${r// /$_uf_tab}" "$_uf_MT" 2>/dev/null)"; [ "${n:-0}" -ge 1 ] || m="$m [$r]"; done; printf '%s' "${m:-ok}"; }
_uf_tma() { local i b; printf 'tm_top=1\n'; for i in 1 2 3 4 5 6 7; do b=':'; [ "$i${1:-0}" != 71 ] || b=': changed'; printf 'tm_f%s() {\n  %s\n}\n' "$i" "$b"; done; }

# ---- the planted parts and libraries (fixture S)
_uf_pp() { local f="$1" n="$2"; shift 2; { printf 'printf "\\ndjx-sec %s\\n"\n' "$n"; printf '%s\n' "$@"; } > "$f"; }
_uf_pp "$UF/pp/P/0010-pp-a.sh" 0010-pp-a.sh 'printf "djx-unit:%s\n" "${FELIX_TEST_UNIT-unset}"' 'printf "djx-benv:%s\n" "${BASH_ENV-unset}"' 'ok "djx pp a"'
_uf_pp "$UF/pp/P/0020-pp-b.sh" 0020-pp-b.sh 'ok "djx pp b"'
_uf_pp "$UF/pp/P/0030-pp-c.sh" 0030-pp-c.sh 'ok "djx pp c"' 'skip "djx pp c skip" "a reason"'
_uf_tma > "$UF/lib/tm-a.sh"; printf 'tm_b1() {\n  :\n}\n' > "$UF/lib/tm-b.sh"; printf 'tm_r1() {\n  :\n}\n' > "$UF/lib/tm-r.sh"; printf 'tm_c() { :; }\ntm_c\n' > "$UF/lib/tm-child.sh"
cat > "$UF/pp/T/0010-tm-a.sh" <<'UFT10'
printf '\ndjx-sec 0010-tm-a.sh\n'
. "$REAL_HARNESS/lib/tm-a.sh"
tm_f1
( tm_f3 )
_x="$(tm_f4)"
bash "$REAL_HARNESS/lib/tm-child.sh"
mkdir -p "$TMP/tmcp/harness/lib" && cp "$REAL_HARNESS/lib/tm-a.sh" "$TMP/tmcp/harness/lib/tm-a.sh"
. "$TMP/tmcp/harness/lib/tm-a.sh"
tm_f5
. "$REAL_HARNESS/bin/../lib/tm-b.sh"
tm_b1
( cd "$REAL_HARNESS" && . ./lib/tm-r.sh && cd / && tm_r1 )
( export FELIX_TEST_UNIT=elsewhere; bash "$REAL_HARNESS/lib/tm-child.sh" )
printf 'djx-unit:%s\n' "${FELIX_TEST_UNIT-unset}"
printf 'djx-benv:%s\n' "${BASH_ENV-unset}"
_m1=-; ! shopt -oq xtrace || _m1=x
trap -p DEBUG > "$TMP/djx-trap.txt"
_m3="$(wc -l < "$TMP/djx-trap.txt" | tr -d ' ')"
_m4=off; ! shopt -oq functrace || _m4=on
printf 'djx-mech:%s:%s:%s:%s\n' "$_m1" "${BASH_XTRACEFD:--}" "$_m3" "$_m4"
ok "djx tm a"
UFT10
_uf_pp "$UF/pp/T/0020-tm-b.sh" 0020-tm-b.sh 'sleep 2' 'ok "djx tm b"'
_uf_pp "$UF/pp/T/0030-tm-c.sh" 0030-tm-c.sh "perl -e 'my \$s = (times)[0]; while (1) { for (1 .. 100000) { } last if (times)[0] - \$s >= 2.0 }'" 'ok "djx tm c"'
_uf_pp "$UF/pp/T/0040-tm-d.sh" 0040-tm-d.sh 'bad "djx tm d" "planted to fail"'
_uf_pp "$UF/pp/T/0050-tm-e.sh" 0050-tm-e.sh 'env -i PATH="$PATH" /bin/bash -c true' 'ok "djx tm e"'
_uf_pp "$UF/pp/T/0060-tm-f.sh" 0060-tm-f.sh 'false | true; _r="${PIPESTATUS[0]}"' 'printf "djx-ps:%s\n" "$_r"' 'ok "djx tm f"'
cat > "$UF/pp/T/0070-tm-g.sh" <<'UFT70'
printf '\ndjx-sec 0070-tm-g.sh\n'
_q='env -i is only words here'
tm_g3() { return 3; }; tm_g3
is "djx tm g: the status a function returned" "$?" 3
: a b
is "djx tm g: the last word of the command before" "$_" b
is "djx tm g: with extdebug on no command is skipped" "$(shopt -s extdebug; false; _y=1; printf %s "$_y")" 1
is "djx tm g: under set -eu nothing is stopped" "$(set -eu; tm_g0() { :; }; tm_g0; printf reached)" reached
is "djx tm g: a child bash prints nothing" "$(bash -c 'f() { :; }; f' 2>&1)" ""
UFT70
_uf_pp "$UF/pp/T/0080-tm-h.sh" 0080-tm-h.sh '. "$REAL_HARNESS/lib/tm-a.sh"' 'tm_f7'
_uf_pp "$UF/pp/T/0090-tm-i.sh" 0090-tm-i.sh 'ok "djx tm i"'
_uf_pp "$UF/pp/T/0100-tm-j.sh" 0100-tm-j.sh '( trap - DEBUG; : )' '( set +x; : )' 'ok "djx tm j"'
_uf_pp "$UF/pp/T/0110-tm-k.sh" 0110-tm-k.sh 'if [ -z "${FELIX_TEST_TRACE_DIR:-}" ]; then ok "djx tm k"; else bad "djx tm k" "FELIX_TEST_TRACE_DIR is set"; fi'
cat > "$UF/pp/T/0120-tm-l.sh" <<'UFT120'
printf '\ndjx-sec 0120-tm-l.sh\n'
_il="$TMP/djx-in"; mkdir -p "$_il/pp" "$_il/tmp"
printf '%s\n' 'printf "\ndjx-sec 0010-in-a.sh\n"' '. "$REAL_HARNESS/lib/tm-a.sh"' 'tm_f6' 'ok "djx in a"' > "$_il/pp/0010-in-a.sh"
printf '%s\n' 'printf "\ndjx-sec 0020-in-b.sh\n"' 'ok "djx in b"' > "$_il/pp/0020-in-b.sh"
: > "$_il/g.tsv"
_suite_copy_tree "$_il/I" "$_il/g.tsv" "$DJX_PMAN" "$_il/pp/0010-in-a.sh" "$_il/pp/0020-in-b.sh"
( cd "$_il/I" && TMPDIR="$_il/tmp" FELIX_TEST_SLOTS=2 "$BASH" "$_il/I/engine/harness/tests/run" -j 2 ) > "$_il/out" 2> "$_il/err"
_ir="$?"
is "djx tm l: the inner -j 2 run exits 0 and leaves a receipt" "$_ir $([ -f "$_il/I/.git/felix-suite-receipt" ] && echo receipt || echo none)" "0 receipt"
UFT120

# ---- the manifest a passing run leaves a receipt by (part 1291's pman.tsv), then the copies
_uf_copy h 0 0 "$UF/g-empty.tsv" - "$UF/pp/P"/*.sh && _uf_run h1 h 150 -j 1
printf '1\t%s\n' "$(sed -n 's/^  ok    //p' "$UF/o/h1.out" 2>/dev/null | sed -n 1p)" > "$UF/pman.tsv"; rm -rf "$UF/c/h"
_uf_copy P 1 0 "$UF/g-empty.tsv" "$UF/pman.tsv" "$UF/pp/P"/*.sh
_uf_copy P0 0 0 "$UF/g-empty.tsv" "$UF/pman.tsv" "$UF/pp/P"/*.sh
_uf_copy R 1 0 --red "$UF/g-empty.tsv" "$UF/pman.tsv" "$UF/pp/P"/*.sh
_uf_copy T 1 1 "$UF/g-T.tsv" - "$UF/pp/T"/*.sh
_uf_PG="$UF/c/P/.git"; _uf_PH="$(git -C "$UF/c/P" rev-parse HEAD 2>/dev/null)"; _uf_TH="$(git -C "$UF/c/T" rev-parse HEAD 2>/dev/null)"
_uf_D1="$UF/d/D1"; _uf_D2="$UF/d/D2"; _uf_D3="$UF/d/D3"; _uf_D4="$UF/d/D4"; _uf_D5="$UF/d/D5"

# ---- P: unit facts (B1 to B6)
_uf_run p1 P 150 -j 1
is "A1: a -j 1 run sets no FELIX_TEST_UNIT, so its part sees it unset (control)" "$(_uf_grep p1 djx-unit:)" "djx-unit:unset "
_uf_run pu P 150 -j 2; _uf_rpu="$_uf_rc"
is "A2: a -j 2 run starts each unit with FELIX_TEST_UNIT exported as the unit's name" "$(_uf_grep pu djx-unit:)" "djx-unit:0010-pp-a.sh "
is "A4: an untraced -j 2 run sets no BASH_ENV for its units (control)" "$(_uf_grep pu djx-benv:)" "djx-benv:unset "
is "A5: that run exits 0, leaves a receipt, and its durations name the three units (control)" \
   "$_uf_rpu $(_uf_rcpt P) $(awk -F'\t' '{ print $2 }' "$_uf_PG/felix-suite-durations" 2>/dev/null | LC_ALL=C sort | tr '\n' ' ')" "0 present 0010-pp-a.sh 0020-pp-b.sh 0030-pp-c.sh "
_uf_T="$(awk -F'\t' 'NR == 1 { print $2 }' "$_uf_PG/felix-suite-receipt" 2>/dev/null)"; _uf_F="$_uf_PG/felix-testmap/runs/$_uf_T.tsv"
is "A6: it keeps one facts file in C/felix-testmap/runs, named for the tree its receipt names" "$(_uf_runs P)" "$_uf_T.tsv "
is "A7: the facts file is a run line (v1, that tree, 2, the runner's BASH_VERSION), then one unit line a unit, in driver order, each pass" \
   "$(awk -F'\t' '{ if ($1 == "run") print $1 "|" $2 "|" $3 "|" $4 "|" $5 "|" NF; else print $1 "|" $2 "|" $3 "|" NF }' "$_uf_F" 2>/dev/null)" \
   "$(printf 'run|v1|%s|2|%s|5\nunit|0010-pp-a.sh|pass|5\nunit|0020-pp-b.sh|pass|5\nunit|0030-pp-c.sh|pass|5' "$_uf_T" "$BASH_VERSION")"
is "A8: every wall field is whole seconds or unknown, and every cpu field has two decimals or is unknown" \
   "$(awk -F'\t' '$1 == "unit" { n++; if ($4 !~ /^(0|[123456789][0123456789]*|unknown)$/ || $5 !~ /^([0123456789]+[.][0123456789][0123456789]|unknown)$/) b = b " " $2 "[" $4 "|" $5 "]" } END { print (n == 3 && b == "") ? "ok" : n + 0 " units" b }' "$_uf_F" 2>/dev/null)" ok
_uf_E=(FELIX_TEST_UNIT=stray); _uf_run ps P 150 -j 2
is "A3: a FELIX_TEST_UNIT the caller exported is replaced for the units" "$(_uf_grep ps djx-unit:)" "djx-unit:0010-pp-a.sh "
_uf_run pu2 P 150 -j 2
is "A9: another run of the same tree replaces the facts file: the runs of P are still one file" "$(_uf_runs P)" "$_uf_T.tsv "
is "A10: a run that keeps its facts prints what a -j 1 run prints, and nothing about facts, maps or tracing (control)" \
   "$(_uf_same pu p1) [$(cat "$UF/o/pu.err" 2>/dev/null)] $(grep -cE 'testmap|unit facts|trace' "$UF/o/pu.out")" "same [] 0"
_uf_run p0 P0 150 -j 2
is "A11: a copy with no select.sh keeps no facts and says nothing: exit 0, empty stderr, no .git/felix-testmap (control)" \
   "$_uf_rc [$(cat "$UF/o/p0.err" 2>/dev/null)] $({ [ -e "$UF/c/P0/.git/felix-testmap" ] || [ -L "$UF/c/P0/.git/felix-testmap" ]; } && echo present || echo absent)" "0 [] absent"
_uf_b="$(_uf_runsum P)"; _uf_run pp P 150 --part 0010-pp-a.sh
is "A12: a --part run keeps no facts: the runs of P are the same file, byte for byte, after it" \
   "$([ -n "$_uf_b" ] && [ "$(_uf_runsum P)" = "$_uf_b" ] && echo same || echo "before [$_uf_b] after [$(_uf_runsum P)]")" same
_uf_ftm="$_uf_PG/felix-testmap"; mv "$_uf_ftm" "$UF/x/ftm-P" 2>/dev/null; : > "$_uf_ftm"; _uf_run pf P 150 -j 2
is "A13: with .git/felix-testmap a regular file the run says once on stderr that the facts were not kept, and exits, receipts and judges as before" \
   "$_uf_rc|$(_uf_err1 pf 'tests/run: the unit facts were not kept: ')|$(_uf_rcpt P)|$(_uf_same pf pu)" "0|ok|present|same"
rm -f "$_uf_ftm"; mkdir -p "$UF/x/E"; ln -s "$UF/x/E" "$_uf_ftm"; _uf_run pl P 150 -j 2
is "A14: with .git/felix-testmap a link to an empty directory it says so once, and writes nothing through the link" \
   "$(_uf_err1 pl 'tests/run: the unit facts were not kept: ')|$(ls -A "$UF/x/E" | wc -l | tr -d ' ')" "ok|0"
rm -f "$_uf_ftm"; [ ! -d "$UF/x/ftm-P" ] || mv "$UF/x/ftm-P" "$_uf_ftm"

# ---- P: what a traced run refuses (B7, B8), and what it leaves (B9)
_uf_E=(FELIX_TEST_TRACE_DIR=d); _uf_ref r20 P
is "A20: a relative FELIX_TEST_TRACE_DIR is refused: exit 2, one stderr line naming it, no unit started" "$_uf_v" "2|ok|0"
: > "$_uf_D2/one"; _uf_E=(FELIX_TEST_TRACE_DIR="$_uf_D2"); _uf_ref r21 P
is "A21: a trace directory that holds an entry is refused the same way, and is left holding only it" "$_uf_v|$(ls -A "$_uf_D2" | tr '\n' ' ')" "2|ok|0|one "
rm -f "$_uf_D2/one"; mkdir -p "$UF/c/P/sub"; _uf_E=(FELIX_TEST_TRACE_DIR="$UF/c/P/sub"); _uf_ref r22 P; rm -rf "$UF/c/P/sub"
is "A22: a trace directory below the checkout's top is refused the same way" "$_uf_v" "2|ok|0"
_uf_E=(FELIX_TEST_TRACE_DIR="$_uf_D2" BASH_ENV=/dev/null); _uf_ref r23 P
is "A23: a traced run with BASH_ENV already set is refused the same way, and writes nothing in the directory" "$_uf_v|$(ls -A "$_uf_D2" | wc -l | tr -d ' ')" "2|ok|0|0"
_uf_E=(FELIX_TEST_TRACE_DIR="$_uf_D2"); _uf_ref r24 P0
is "A24: a suite with no trace.sh or select.sh beside it refuses a traced run the same way, and writes nothing in the directory" "$_uf_v|$(ls -A "$_uf_D2" | wc -l | tr -d ' ')" "2|ok|0|0"
ln -s "$_uf_D5" "$UF/d/lnk"; _uf_E=(FELIX_TEST_TRACE_DIR="$UF/d/lnk"); _uf_ref r25 P
is "A25: a trace directory that is a symbolic link is refused the same way" "$_uf_v" "2|ok|0"
_uf_E=(FELIX_TEST_TRACE_DIR=); _uf_run r26 P 150 -j 2
is "A26: an empty FELIX_TEST_TRACE_DIR is no trace: exit 0, a receipt, and no BASH_ENV for the units (control)" "$_uf_rc $(_uf_rcpt P) $(_uf_grep r26 djx-benv:)" "0 present djx-benv:unset "
_uf_d0="$(cksum < "$_uf_PG/felix-suite-durations" 2>/dev/null)"; _uf_r0="$(_uf_runsum P)"
_uf_E=(FELIX_TEST_TRACE_DIR="$_uf_D2"); _uf_run pt P 300 -j 2; _uf_rpt="$_uf_rc"
is "A27: a traced -j 2 run of P exits 0 with nothing on stderr" "$_uf_rpt [$(cat "$UF/o/pt.err" 2>/dev/null)]" "0 []"
_uf_x="$(sed -n 's/^djx-benv://p' "$UF/o/pt.out" | sed -n 1p)"
if [ "${_uf_x#/}" != "$_uf_x" ] && [ "${_uf_x%/engine/harness/tests/trace.sh}" != "$_uf_x" ]; then _uf_y=ok; else _uf_y="[$_uf_x]"; fi
is "A28: every unit of a traced run starts with BASH_ENV the absolute path of the suite's tests/trace.sh" "$_uf_y" ok
is "A29: a traced run leaves no receipt, and the durations file and the runs of P are as they were before it" \
   "$(_uf_rcpt P)|$([ -n "$_uf_d0" ] && [ "$(cksum < "$_uf_PG/felix-suite-durations" 2>/dev/null)" = "$_uf_d0" ] && echo same || echo changed)|$([ "$(_uf_runsum P)" = "$_uf_r0" ] && echo same || echo changed)" "absent|same|same"
_uf_ut="$_uf_D2/units.tsv"; _uf_x="$(awk -F'\t' '$1 == "top" { print $2; exit }' "$_uf_ut" 2>/dev/null)"; _uf_y="$([ -n "$_uf_x" ] && cd "$_uf_x" 2>/dev/null && pwd -P)"
is "A30: D/units.tsv is run, top (the checkout's top), head (HEAD, clean), a unit line a unit, then end (HEAD, clean)" \
   "$(awk -F'\t' '{ printf "%s ", $1 }' "$_uf_ut" 2>/dev/null)|$_uf_y|$(awk -F'\t' '$1 == "head" || $1 == "end" { printf "%s %s %s;", $1, $2, $3 }' "$_uf_ut" 2>/dev/null)" \
   "run top head unit unit unit end |$(cd "$UF/c/P" && pwd -P)|head $_uf_PH clean;end $_uf_PH clean;"
is "A31: the unit's directory D/0010-pp-a.sh holds a trace file named by a process id" "$([ "$(_uf_ntr "$_uf_D2/0010-pp-a.sh")" -ge 1 ] && echo yes || echo none)" yes
is "A32: a traced run prints the verdict lines the untraced run prints" "$(_uf_same pt pu)" same
_uf_E=(FELIX_TEST_TRACE_DIR="$_uf_D3"); _uf_run rr R 300 --record-assertions -j 2
is "A33: a record run never reads FELIX_TEST_TRACE_DIR: exit 0, nothing in the directory, no BASH_ENV for the units" \
   "$_uf_rc|$(ls -A "$_uf_D3" | wc -l | tr -d ' ')|$(grep '^djx-benv:' "$UF/o/rr.out" | LC_ALL=C sort -u | tr '\n' ' ')" "0|0|djx-benv:unset "

# ---- T: facts of an untraced run (B3), then the traced run (B9 to B14)
_uf_run tu T 300 -j 4; _uf_rtu="$_uf_rc"
_uf_TF="$UF/c/T/.git/felix-testmap/runs/none.tsv"; for _uf_x in "$UF/c/T/.git/felix-testmap/runs"/*.tsv; do [ ! -f "$_uf_x" ] || _uf_TF="$_uf_x"; done
is "A15: the facts of T name its units in driver order, the group tg once and in its place" "$(awk -F'\t' '$1 == "unit" { printf "%s ", $2 }' "$_uf_TF" 2>/dev/null)" "$_uf_U "
is "A16: the unit that added a FAIL is fail, and every other unit is pass" "$(awk -F'\t' '$1 == "unit" { printf "%s=%s ", $2, $3 }' "$_uf_TF" 2>/dev/null)" \
   "$(for _uf_x in $_uf_U; do if [ "$_uf_x" = 0040-tm-d.sh ]; then printf '%s=fail ' "$_uf_x"; else printf '%s=pass ' "$_uf_x"; fi; done)"
is "A17: a unit that sleeps 2 s has a wall of 2 or more" "$(awk -F'\t' '$1 == "unit" && $2 == "0020-tm-b.sh" { print ($4 ~ /^[0123456789]+$/ && $4 + 0 >= 2) ? "ok" : "wall [" $4 "]" }' "$_uf_TF" 2>/dev/null)" ok
is "A18: a unit whose child spends 2.0 s of CPU has a cpu at least 1.20 above a unit that sleeps" \
   "$(awk -F'\t' '$1 == "unit" && $2 == "0020-tm-b.sh" { b = $5 } $1 == "unit" && $2 == "0030-tm-c.sh" { c = $5 } END { r = "[" c "] against [" b "]"; if (b ~ /^[0123456789]+[.][0123456789]+$/ && c ~ /^[0123456789]+[.][0123456789]+$/ && c + 0 >= b + 1.20) r = "ok"; print r }' "$_uf_TF" 2>/dev/null)" ok
is "A19: the untraced run of T exits 1 and its PIPESTATUS reader prints 1" "$_uf_rtu $(grep -c '^djx-ps:1$' "$UF/o/tu.out")" "1 1"
_uf_E=(FELIX_TEST_TRACE_DIR="$_uf_D1"); _uf_run tt T 600 -j 4; _uf_rtt="$_uf_rc"
is "A34: the traced run of T exits 1 with nothing on stderr" "$_uf_rtt [$(cat "$UF/o/tt.err" 2>/dev/null)]" "1 []"
is "A35: its units.tsv has head and end at T's HEAD, both clean, eleven unit lines, and 0040 and 0110 fail" \
   "$(awk -F'\t' '$1 == "head" || $1 == "end" { printf "%s %s %s;", $1, $2, $3 } $1 == "unit" { n++ } $1 == "unit" && ($2 == "0040-tm-d.sh" || $2 == "0110-tm-k.sh") { v = v " " $2 "=" $3 } END { printf " %d units%s", n, v }' "$_uf_D1/units.tsv" 2>/dev/null)" \
   "head $_uf_TH clean;end $_uf_TH clean; 11 units 0040-tm-d.sh=fail 0110-tm-k.sh=fail"
is "A36: D holds one directory a unit and no other: none for a name a process set itself, none for an inner run's units" \
   "$(for _uf_x in "$_uf_D1"/*; do [ ! -d "$_uf_x" ] || [ -L "$_uf_x" ] || printf '%s\n' "${_uf_x##*/}"; done | LC_ALL=C sort | tr '\n' ' ')" "$(printf '%s\n' $_uf_U | LC_ALL=C sort | tr '\n' ' ')"
is "A37: the unit that runs a child bash has at least two trace files" "$([ "$(_uf_ntr "$_uf_D1/0010-tm-a.sh")" -ge 2 ] && echo yes || echo "$(_uf_ntr "$_uf_D1/0010-tm-a.sh") files")" yes
_uf_x="$(sed -n 's/^djx-mech://p' "$UF/o/tt.out" | sed -n 1p)"
if [ "$_uf_b3" = 1 ]; then _uf_re='^-:-:[123456789][0123456789]*:on$'; [[ $_uf_x =~ $_uf_re ]] && _uf_y=ok || _uf_y="[$_uf_x]"
  is "A38: under bash 3.2 to 4.0 the tracer is a DEBUG trap with functrace on and xtrace off, and no BASH_XTRACEFD" "$_uf_y" ok
else skip "A38: under bash 3.2 to 4.0 the tracer is a DEBUG trap with functrace on and xtrace off, and no BASH_XTRACEFD" "$_uf_s3"; fi
if [ "$_uf_b3" = 0 ]; then _uf_y="[$_uf_x]"; _uf_re='^x:([0123456789]+):'
  if [[ $_uf_x =~ $_uf_re ]] && [ "${BASH_REMATCH[1]}" -gt 9 ] && [ "${BASH_REMATCH[1]}" -ne 63 ]; then _uf_y=ok; fi
  is "A39: under bash 4.1 or later the tracer is xtrace on a BASH_XTRACEFD above 9 that is not 63" "$_uf_y" ok
else skip "A39: under bash 4.1 or later the tracer is xtrace on a BASH_XTRACEFD above 9 that is not 63" "$_uf_s5"; fi
is "A40: under tracing \$?, \$_, extdebug, set -eu and a child bash are as untraced: 0070's section holds no FAIL" \
   "$(awk 'index($0, "djx-sec ") == 1 { s = ($0 == "djx-sec 0070-tm-g.sh"); if (s) seen = 1 } s && /^  FAIL  / { n++ } END { print seen ? n + 0 " FAIL" : "no section" }' "$UF/o/tt.out")" "0 FAIL"
is "A41: every other line the traced run prints, verdicts, details, notes, djx- lines and the summary apart, is one the untraced run prints" \
   "$(awk 'FILENAME == ARGV[1] { u[$0] = 1; next } /^  (ok    |FAIL  |skip  |note  )/ || /^        / || /^djx-/ || /^[0123456789]+ passed, / { next } !($0 in u) { printf "[%s]", $0 }' "$UF/o/tu.out" "$UF/o/tt.out")" ""

# ---- compiling the map of T (B16 to B20)
_uf_C="$UF/c/T/.git"; _uf_MT="$_uf_C/felix-testmap/$_uf_P/$_uf_TH/map.tsv"
_uf_tm cm "$UF/c/T" --compile "$_uf_D1"
is "A42: compile exits 0 and prints three lines, the first naming the map for T's HEAD and this platform, under C/felix-testmap" \
   "$_uf_rc|$(awk 'END { print NR }' "$UF/o/cm.out")|$(_uf_nm "$UF/o/cm.out" | sed -n 1p)" "0|3|testmap: map for $_uf_TH ($_uf_P) written to $_uf_MT"
_uf_x="$(sed -n 3p "$UF/o/cm.out")"; _uf_re='^testmap: unit time from untraced runs: traced CPU [0123456789]+[.][0123456789][0123456789] s against untraced [0123456789]+[.][0123456789][0123456789] s for the same tree, [0123456789]+[.][0123456789][0123456789]x$'
is "A43: its third line sets the traced CPU against the untraced run of the same tree" "$([[ $_uf_x =~ $_uf_re ]] && echo ok || echo "[$_uf_x]")" ok
is "A44: the map's first line is map, v1, T's HEAD, the platform, an epoch of the last hour and untraced; then a unit line a unit, in driver order" \
   "$(awk -F'\t' -v now="$(date +%s)" 'NR == 1 { e = ($5 ~ /^[0123456789]+$/ && $5 + 0 <= now + 5 && $5 + 0 >= now - 3600) ? "recent" : "epoch [" $5 "]"; print $1 "|" $2 "|" $3 "|" $4 "|" e "|" $6 "|" NF } $1 == "unit" { u = u $2 " " } END { print u }' "$_uf_MT" 2>/dev/null)" \
   "$(printf 'map|v1|%s|%s|recent|untraced|6\n%s ' "$_uf_TH" "$_uf_P" "$_uf_U")"
is "A45: the counts compile prints are the counts of each status among the map's unit lines" "$(sed -n 2p "$UF/o/cm.out")" \
   "$(awk -F'\t' '$1 == "unit" { n++; c[$3]++ } END { if (n) printf "testmap: %d units: %d complete, %d incomplete, %d unfaithful", n, c["complete"], c["incomplete"], c["unfaithful"]; else printf "no unit line in the map" }' "$_uf_MT" 2>/dev/null)"
is "A46: the units that do nothing the tracer cannot follow are complete, with reason -" \
   "$(for _uf_x in 0010-tm-a.sh 0020-tm-b.sh 0030-tm-c.sh tg; do printf '%s=%s ' "$_uf_x" "$(_uf_mu "$_uf_x")"; done)" "0010-tm-a.sh=complete|- 0020-tm-b.sh=complete|- 0030-tm-c.sh=complete|- tg=complete|- "
is "A47: a unit that only quotes env -i, in an assignment's value, is complete (control for B13's last sentence)" "$(_uf_mu 0070-tm-g.sh)" "complete|-"
_uf_x=""; for _uf_y in 0040-tm-d.sh 0110-tm-k.sh; do _uf_z="$(_uf_mu "$_uf_y")"; case "$_uf_z" in "unfaithful|"*"failed under tracing"*) ;; *) _uf_x="$_uf_x $_uf_y[$_uf_z]" ;; esac; done
is "A48: a unit that failed under tracing is unfaithful, failed under tracing" "${_uf_x:-ok}" ok
_uf_z="$(_uf_mu 0050-tm-e.sh)"; case "$_uf_z" in "incomplete|"*"env -i"*) _uf_x=ok ;; *) _uf_x="[$_uf_z]" ;; esac
is "A49: a unit that ran env -i is incomplete, and the reason names env -i" "$_uf_x" ok
_uf_z="$(_uf_mu 0060-tm-f.sh)"
if [ "$_uf_b3" = 1 ]; then case "$_uf_z" in "unfaithful|"*PIPESTATUS*) _uf_x=ok ;; *) _uf_x="[$_uf_z]" ;; esac
  is "A50: under bash 3.2 to 4.0 a unit that reads PIPESTATUS after a pipeline is unfaithful, and the reason says PIPESTATUS" "$_uf_x" ok
else skip "A50: under bash 3.2 to 4.0 a unit that reads PIPESTATUS after a pipeline is unfaithful, and the reason says PIPESTATUS" "$_uf_s3"; fi
if [ "$_uf_b3" = 0 ]; then is "A51: under bash 4.1 or later that unit is complete, and its traced run read PIPESTATUS as 1" "${_uf_z%%|*} $(grep -c '^djx-ps:1$' "$UF/o/tt.out")" "complete 1"
else skip "A51: under bash 4.1 or later that unit is complete, and its traced run read PIPESTATUS as 1" "$_uf_s5"; fi
_uf_z="$(_uf_mu 0100-tm-j.sh)"; _uf_x="[$_uf_z]"
if [ "$_uf_b3" = 1 ]; then case "$_uf_z" in "incomplete|"*trap*|"incomplete|"*set*) _uf_x=ok ;; esac; else case "$_uf_z" in "incomplete|"*"set +x"*) _uf_x=ok ;; esac; fi
is "A52: a unit that turns the tracer off in a subshell is incomplete, and the reason names the command (trap or set; set +x under bash 4.1 or later)" "$_uf_x" ok
is "A53: a function entered in the process, a subshell and a command substitution, and one from a copy under \$TMP/.../harness/, map to lib/tm-a.sh" \
   "$(_uf_rows 'fn 0010-tm-a.sh engine/harness/lib/tm-a.sh tm_f1' 'fn 0010-tm-a.sh engine/harness/lib/tm-a.sh tm_f3' 'fn 0010-tm-a.sh engine/harness/lib/tm-a.sh tm_f4' 'fn 0010-tm-a.sh engine/harness/lib/tm-a.sh tm_f5')" ok
is "A54: a file sourced through bin/.., one sourced by a relative path before a cd, and one a child bash ran, each map to their lib path" \
   "$(_uf_rows 'fn 0010-tm-a.sh engine/harness/lib/tm-b.sh tm_b1' 'fn 0010-tm-a.sh engine/harness/lib/tm-r.sh tm_r1' 'fn 0010-tm-a.sh engine/harness/lib/tm-child.sh tm_c')" ok
is "A55: the top level of the sourced library, of the child's script and of the part itself is recorded" \
   "$(_uf_rows 'top 0010-tm-a.sh engine/harness/lib/tm-a.sh' 'top 0010-tm-a.sh engine/harness/lib/tm-child.sh' 'top 0010-tm-a.sh engine/harness/tests/parts/0010-tm-a.sh')" ok
is "A56: no fn row names a function nobody entered (tm_f2), and none names main or source" \
   "$(if [ -s "$_uf_MT" ]; then awk -F'\t' '$1 == "fn" && ($4 == "tm_f2" || $4 == "main" || $4 == "source") { printf "[%s]", $0 }' "$_uf_MT"; else printf 'no map at %s' "$_uf_MT"; fi)" ""
is "A57: what a group's member entered is the group's row" "$(_uf_rows 'fn tg engine/harness/lib/tm-a.sh tm_f7')" ok
is "A58: what an inner -j run's unit entered is the outer unit's row, and no row is for elsewhere or an inner unit" \
   "$(_uf_rows 'fn 0120-tm-l.sh engine/harness/lib/tm-a.sh tm_f6')|$(awk -F'\t' '($1 == "fn" || $1 == "top" || $1 == "unit") && ($2 == "elsewhere" || $2 == "0010-in-a.sh" || $2 == "0020-in-b.sh") { printf "[%s %s]", $1, $2 }' "$_uf_MT" 2>/dev/null)" "ok|"
git -C "$UF/c/T" ls-tree -r --name-only HEAD > "$UF/x/lstree" 2>/dev/null
is "A59: every row's path is relative and is a file in T's HEAD" \
   "$(awk -F'\t' 'FILENAME == ARGV[1] { t[$0] = 1; next } $1 == "fn" || $1 == "top" { n++; if (substr($3, 1, 1) == "/" || !($3 in t)) b = b " [" $3 "]" } END { print (n > 0 && b == "") ? "ok" : n + 0 " rows" b }' "$UF/x/lstree" "$_uf_MT" 2>/dev/null)" ok
awk -F'\t' '$1 == "fn" || $1 == "top"' "$_uf_MT" > "$UF/x/rows" 2>/dev/null; LC_ALL=C sort -u "$UF/x/rows" > "$UF/x/rows.s"
is "A60: the fn and top lines are in byte order, none twice" "$([ -s "$UF/x/rows" ] && cmp -s "$UF/x/rows" "$UF/x/rows.s" && echo ordered || echo "not [$(LC_ALL=C diff "$UF/x/rows" "$UF/x/rows.s" | head -3 | tr '\n' '|')]")" ordered
_uf_m0="$(cksum < "$_uf_MT" 2>/dev/null)"; _uf_msame() { [ -n "$_uf_m0" ] && [ "$(cksum < "$_uf_MT" 2>/dev/null)" = "$_uf_m0" ] && echo same || echo changed; }
_uf_tm c61 "$UF/c/T" --compile "$_uf_D4"
is "A61: compile of an empty directory exits 1, says one felix testmap: line on stderr, and leaves the map" "$_uf_rc|$(_uf_err1 c61 'felix testmap:')|$(_uf_msame)" "1|ok|same"
rm -rf "$UF/d/c62" "$UF/d/c63"; cp -R "$_uf_D1" "$UF/d/c62"; cp -R "$_uf_D1" "$UF/d/c63"
awk -F'\t' -v OFS='\t' '$1 == "head" { $3 = "dirty" } { print }' "$_uf_D1/units.tsv" > "$UF/d/c62/units.tsv" 2>/dev/null
awk -F'\t' -v OFS='\t' '$1 == "head" || $1 == "end" { $2 = "0000000000000000000000000000000000000000" } { print }' "$_uf_D1/units.tsv" > "$UF/d/c63/units.tsv" 2>/dev/null
_uf_tm c62 "$UF/c/T" --compile "$UF/d/c62"
is "A62: compile of a traced run whose head was dirty is refused the same way" "$_uf_rc|$(_uf_err1 c62 'felix testmap:')|$(_uf_msame)" "1|ok|same"
_uf_tm c63 "$UF/c/T" --compile "$UF/d/c63"
is "A63: compile of a traced run at a commit this checkout lacks is refused the same way" "$_uf_rc|$(_uf_err1 c63 'felix testmap:')|$(_uf_msame)" "1|ok|same"
_uf_tm c64 "$UF/d" --compile "$_uf_D1"
is "A64: compile run outside every checkout exits 1 with one felix testmap: line on stderr" "$_uf_rc|$(_uf_err1 c64 'felix testmap:')" "1|ok"
mv "$_uf_PG/felix-testmap/runs" "$UF/x/P-runs" 2>/dev/null; _uf_tm c65 "$UF/c/P" --compile "$_uf_D2"
_uf_x="$(awk -F'\t' '$1 == "run" { print $3; exit }' "$_uf_D2/units.tsv" 2>/dev/null)"
is "A65: with no untraced run of the tree recorded, compile says the overhead is not known, and the map's source is traced" \
   "$(sed -n 3p "$UF/o/c65.out")|$(awk -F'\t' 'NR == 1 { print $NF }' "$_uf_PG/felix-testmap/$_uf_P/$_uf_PH/map.tsv" 2>/dev/null)" \
   "testmap: unit time from the traced run: no untraced run of tree $_uf_x is recorded here, so the tracer's overhead is not known|traced"
_uf_tma 1 > "$UF/c/T/engine/harness/lib/tm-a.sh"; _uf_tm c66 "$UF/c/T" --report; _uf_tma > "$UF/c/T/engine/harness/lib/tm-a.sh"
is "A66: with tm_f7's body changed the report selects the group that entered it, and gives 0010 no function reason" \
   "$(grep -cxF 'selected tg: function tm_f7 in engine/harness/lib/tm-a.sh' "$UF/o/c66.out")|$(grep '^selected 0010-tm-a.sh:' "$UF/o/c66.out" | grep -c function)" "1|0"
rm -rf "$UF/d/c67"; cp -R "$_uf_D1" "$UF/d/c67"
for _uf_x in "$UF/d/c67/0070-tm-g.sh"/[0123456789]*.trace; do [ ! -f "$_uf_x" ] || { printf '#junk\n' >> "$_uf_x"; break; }; done
_uf_tm c67 "$UF/c/T" --compile "$UF/d/c67"
is "A67: a trace line that is not a record makes its unit incomplete: a trace line could not be read" "$_uf_rc|$(_uf_mu 0070-tm-g.sh)" "0|incomplete|a trace line could not be read"

is "fixture S: every copy was made, and every run of one left no live process in its process group" "${_uf_fx:-made}|${_uf_leak:-none}" "made|none"
unset -f $(compgen -A function _uf_) 2>/dev/null
unset $(compgen -A variable _uf_) UF 2>/dev/null
# <<< unit-facts-and-tracer-blind
