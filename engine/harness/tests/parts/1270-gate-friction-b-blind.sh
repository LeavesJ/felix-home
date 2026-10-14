# >>> gate-friction-b
printf '\ngate friction B: the slow assertions, and qualified rows in parallel (contract B, blind)\n'
# Blind, written from docs/2026-10-13-gate-friction-contract-b.md alone on
# 2026-10-13, before the code it describes existed. Nothing here was read off
# an implementation of it.
#
# B1 and B2 change parts 0580, 0900 and 0920, which run before this one in the
# same shell. B1 is asserted by running the 0580 block again, cut out of the
# part between its own comment and the next heading, with this part's own
# ok/bad/is/has/skip, so its verdicts are read here and counted nowhere else.
# A claude this part writes stands first on PATH beneath the block, and logs
# any call that reaches it: the block's own stub must stand in front of it. B2
# is asserted on the gh stub part 0900 wrote and on _ibsig itself.
#
# B3 drives _felix_qualify_run_rows in a bash of its own (set -uo pipefail, as
# the felix CLI has it) and felix qualify, on repositories this part makes
# under $TMP, each run with a TMPDIR of its own and in a process group of its
# own, started by perl with INT at its default (a job started with & in a
# non-interactive bash ignores INT). A row that must wait for an event polls a
# file for it, with a bound; no sleep stands in for a race, and no assertion
# reads elapsed time.
#
# Readings of the contract taken here:
#   - A row's stderr (B3.3) is what the row's own process writes on fd 2. A
#     column's stderr goes to a file in its base and never reaches the caller,
#     so the fixture makes each row say one line the way rows already do: the
#     command swaps its base for a symlink, and the drop says so.
#   - At N = 1 (B3.5) the signal goes to the process group, the case the
#     contract says reaches each serial row's trap today. Measured on the loop
#     before B, bash 3.2.57: the loop exits at once with 128+N and starts no
#     row after, and the row's trap removes its tree a moment after the loop
#     has exited. "Before the loop exits" is bound under N > 1 and N = 1 is
#     today's loop, so at 1 the tree is looked for once the run's processes
#     have all ended.
#   - A row killed outright (B3.2) is the process its base's owner record
#     names, the record the sweep (B3.6) judges.
GFQ="$TMP/gfq-b"; mkdir -p "$GFQ"; GFQ="$(cd "$GFQ" && pwd -P)"
GFQ_LIB="$FROOT/harness/lib"
_gfq_git() { git -c user.name=gfb -c user.email=gfb@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"; }
_gfq_q() { sed 's/^/| /' | head -20; }
_gfq_ls() { local o; o="$(ls -A "$1" 2>/dev/null | tr '\n' ' ')"; printf '%s' "${o:-empty}"; }
_gfq_wts() { git -C "$1" worktree list --porcelain 2>/dev/null | grep -c '^worktree '; }
_gfq_repo() {   # dir: a repository on main holding f.txt = good
  mkdir -p "$1" && ( cd "$1" && _gfq_git init -q -b main && printf 'good\n' > f.txt \
    && _gfq_git add -A && _gfq_git commit -qm base ) >/dev/null 2>&1
}
GFQ_PERL=0; command -v perl >/dev/null 2>&1 && GFQ_PERL=1

# ---------------------------------------------------------------------- B1 ---
# The block, cut out of part 0580 as the suite has it now.
GFQ_BLK="$GFQ/b1-block.sh"
awk '$0 == "# It recommends. It must never acquire." { on = 1 }
     on && /^printf .*seeing the whole toolbox/ { exit }
     on { print }' "$HERE"/parts/0580-*.sh > "$GFQ_BLK" 2>/dev/null
mkdir -p "$GFQ/trip"
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/trip.log"\nexit 3\n' "$GFQ" > "$GFQ/trip/claude"
chmod +x "$GFQ/trip/claude"
# The block's verdicts, one `ok|bad|skip <TAB> name` a line, run with FELIX
# and PATH as given and every other name as the suite has it.
_gfq_b1() {   # felix, PATH
  ( FELIX="$1"; PATH="$2"
    ok()   { printf 'GFQV\tok\t%s\n' "$1"; }
    bad()  { printf 'GFQV\tbad\t%s\n' "$1"; }
    skip() { printf 'GFQV\tskip\t%s\n' "$1"; }
    is()   { [ "$2" = "$3" ] && ok "$1" || bad "$1"; }
    has()  { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1" ;; esac; }
    . "$GFQ_BLK" ) 2>/dev/null | LC_ALL=C awk -F'\t' '$1 == "GFQV" { print $2 "\t" $3 }'
}
_gfq_v() { printf '%s\n' "$1" | LC_ALL=C awk -F'\t' -v n="$2" '$2 == n { print $1 }' | tr '\n' ' ' | sed 's/ $//'; }
_gfq_noclaude() {
  local IFS=: d out=""
  for d in $PATH; do
    [ -n "$d" ] || continue
    [ -x "$d/claude" ] && continue
    out="${out:+$out:}$d"
  done
  printf '%s' "$out"
}
cp "$FROOT/projects/widget/stack.tsv" "$GFQ/stack.keep" 2>/dev/null
_gfq_restack() { cp "$GFQ/stack.keep" "$FROOT/projects/widget/stack.tsv" 2>/dev/null; }
# widget declares llm for the re-runs, besides whatever it declares, so that
# felix discover always has a rule to read a catalogue for: a project that
# declares nothing the rules name asks no claude anything, and a tripwire
# nobody could reach would pass over nothing. Put back after.
GFQ_CAPS="$FROOT/projects/widget/capabilities"; GFQ_CAPK=0
[ -f "$GFQ_CAPS" ] && cp "$GFQ_CAPS" "$GFQ/caps.keep" && GFQ_CAPK=1
grep -qx llm "$GFQ_CAPS" 2>/dev/null || printf 'llm\n' >> "$GFQ_CAPS"
GFQ_B1N="B1: the discovery block runs felix discover only with a claude the suite wrote first on PATH, never one it found there"
GFQ_B1K="B1: the block's two assertions keep their names and pass: discovery writes nothing, there is no --yes"
GFQ_B1P="B1: the block has a positive control besides those two, and it passes"
GFQ_B1M="B1: the block's discovery writes nothing fails against an engine whose plain felix discover appends a row to stack.tsv, with a claude on PATH the block did not write"
GFQ_B1X="B1: and fails against that engine with no claude anywhere on PATH"
if [ -s "$GFQ_BLK" ] && grep -q '"\$FELIX" discover' "$GFQ_BLK"; then
  : > "$GFQ/trip.log"
  GFQ_V="$(_gfq_b1 "$FELIX" "$GFQ/trip:$PATH")"; _gfq_restack
  if [ -s "$GFQ/trip.log" ]; then bad "$GFQ_B1N" "the claude PATH had took: $(_gfq_q < "$GFQ/trip.log" | tr '\n' ' ')"
  else ok "$GFQ_B1N"; fi
  is  "$GFQ_B1K" "$(_gfq_v "$GFQ_V" "discovery writes nothing") $(_gfq_v "$GFQ_V" "there is no --yes")" "ok ok"
  GFQ_VO="$(printf '%s\n' "$GFQ_V" | LC_ALL=C awk -F'\t' '$2 != "discovery writes nothing" && $2 != "there is no --yes"')"
  if [ -z "$GFQ_VO" ]; then bad "$GFQ_B1P" "the block made no assertion but the two it had"
  else is "$GFQ_B1P" "$(printf '%s\n' "$GFQ_VO" | cut -f1 | LC_ALL=C sort -u | tr '\n' ' ')" "ok "; fi
  # The mutant: plain discover, once it has read a catalogue, appends a row.
  rm -rf "$GFQ/mut"; cp -R "$FROOT/harness" "$GFQ/mut" 2>/dev/null
  GFQ_ANCH='  [ "$quiet" -eq 1 ] && _felix_discover_stamp_line "$tpl"'
  if [ "$(grep -cxF "$GFQ_ANCH" "$GFQ/mut/felix" 2>/dev/null)" = 1 ]; then
    LC_ALL=C awk -v a="$GFQ_ANCH" '$0 == a { print "  [ \"$quiet\" -eq 1 ] || printf '"'"'plugin\\tgfb-mutant\\t-\\tlow\\t-\\tOBSERVED\\n'"'"' >> \"$proj/stack.tsv\"" } { print }' \
      "$FROOT/harness/felix" > "$GFQ/mut/felix"
    chmod +x "$GFQ/mut/felix"
    GFQ_V="$(_gfq_b1 "$GFQ/mut/felix" "$GFQ/trip:$PATH")"; _gfq_restack
    is  "$GFQ_B1M" "$(_gfq_v "$GFQ_V" "discovery writes nothing")" "bad"
    GFQ_V="$(_gfq_b1 "$GFQ/mut/felix" "$(_gfq_noclaude)")"; _gfq_restack
    is  "$GFQ_B1X" "$(_gfq_v "$GFQ_V" "discovery writes nothing")" "bad"
  else
    bad "$GFQ_B1M" "the mutant could not be made: the line it goes before is not in felix once"
    bad "$GFQ_B1X" "the mutant could not be made"
  fi
else
  for _gfqn in "$GFQ_B1N" "$GFQ_B1K" "$GFQ_B1P" "$GFQ_B1M" "$GFQ_B1X"; do
    bad "$_gfqn" "part 0580 holds no block from \"# It recommends. It must never acquire.\" that runs felix discover"
  done
fi
if [ "$GFQ_CAPK" -eq 1 ]; then cp "$GFQ/caps.keep" "$GFQ_CAPS"; else rm -f "$GFQ_CAPS"; fi

# ---------------------------------------------------------------------- B2 ---
GFQ_B2S="B2: the gh stub part 0900 writes no longer sleeps 30 s unconditionally once it has written its pid"
GFQ_B2A="B2: when _ibsig sends the signal the gh stub is still waiting, and the run then leaves no scratch (control)"
if [ -n "${IB:-}" ] && [ -f "$IB/stub/gh" ]; then
  if grep -q 'exec sleep 30' "$IB/stub/gh"; then bad "$GFQ_B2S" "$(grep -n 'sleep 30' "$IB/stub/gh" | _gfq_q)"
  else ok "$GFQ_B2S"; fi
else
  bad "$GFQ_B2S" "part 0900 left no gh stub at \$IB/stub/gh"
fi
if [ "$(type -t _ibsig)" = function ] && [ -n "${IB:-}" ] && command -v perl >/dev/null 2>&1; then
  # kill, shadowed for the one call: whether the stub is alive when the
  # signal goes, and still alive a second later, before it is sent.
  GFQ_B2R="$( kill() {
                case " $* " in
                  (" -TERM "*|" -HUP "*|" -INT "*|" -s TERM "*|" -s HUP "*|" -s INT "*)
                    local g j=0 st=alive
                    g="$(cat "$IB/gh.pid" 2>/dev/null)"
                    if [ -z "$g" ] || ! builtin kill -0 "$g" 2>/dev/null; then st=released
                    else
                      while [ "$j" -lt 10 ]; do
                        builtin kill -0 "$g" 2>/dev/null || { st=released; break; }
                        sleep 0.1; j=$((j + 1))
                      done
                    fi
                    printf '%s ' "$st" ;;
                esac
                builtin kill "$@"; }
              _ibsig TERM )"
  is  "$GFQ_B2A" "$GFQ_B2R" "alive gone"
else
  bad "$GFQ_B2A" "part 0920's _ibsig, part 0900's \$IB or perl is not here"
fi

# ---------------------------------------------------------------------- B3 ---
# <name> <dir> <command...>: started in <dir>, in a process group of its own
# with INT, QUIT, TERM and HUP at their defaults; GFQ_PID is its pid and group.
_gfq_spawn() {
  local n="$1" d="$2"; shift 2
  if [ "$GFQ_PERL" -eq 1 ]; then
    ( cd "$d" || exit 97
      exec perl -e '$SIG{$_} = "DEFAULT" for qw(INT QUIT TERM HUP); setpgrp(0, 0); exec @ARGV or exit 127' "$@" ) \
      > "$GFQ/$n.out" 2> "$GFQ/$n.err" &
  else
    ( cd "$d" || exit 97; exec "$@" ) > "$GFQ/$n.out" 2> "$GFQ/$n.err" &
  fi
  GFQ_PID=$!
}
# Wait for GFQ_PID, at most <tenths> (default 1800); GFQ_RC its status, 124
# when it was killed for running past that.
_gfq_end() {
  local i=0 b="${1:-1800}"
  while kill -0 "$GFQ_PID" 2>/dev/null && [ "$i" -lt "$b" ]; do sleep 0.1; i=$((i + 1)); done
  if kill -0 "$GFQ_PID" 2>/dev/null; then
    kill -KILL -- "-$GFQ_PID" 2>/dev/null; kill -KILL "$GFQ_PID" 2>/dev/null
    wait "$GFQ_PID" 2>/dev/null; GFQ_RC=124
  else
    wait "$GFQ_PID"; GFQ_RC=$?
  fi
}
# <name> <jobs, or unset> <TMPDIR> <root> <rows> [checker]: the loop, started.
_gfq_loop_start() {
  local n="$1" j="$2" t="$3" r="$4" rows="$5" w="${6:-}"
  mkdir -p "$t"
  if [ "$j" = unset ]; then set -- env -u FELIX_QUALIFY_JOBS; else set -- env "FELIX_QUALIFY_JOBS=$j"; fi
  _gfq_spawn "$n" "$r" "$@" TMPDIR="$t" bash -c \
    'set -uo pipefail; . "$1/resolve.sh" && . "$1/qualify.sh" || exit 97; _felix_qualify_run_rows "$2" "$3" "$4"' \
    _ "$GFQ_LIB" "$rows" "$r" "$w"
}
_gfq_loop() { _gfq_loop_start "$@"; _gfq_end; }
_gfq_row() { local IFS='	'; printf '%s\n' "$*"; }
_gfq_fill() { local t="$1"; t="${t//@S@/$2}"; printf '%s' "${t//@B@/${3:-0}}"; }
_gfq_verdict() { LC_ALL=C awk -F'\t' -v c="$2" '$1 == c { print $5 }' "$GFQ/$1.out" | tr '\n' ' ' | sed 's/ $//'; }
_gfq_fresh() { rm -rf "$1"; mkdir -p "$1"; }
GFQ_R="$GFQ/r"; _gfq_repo "$GFQ_R"; GFQ_R="$(cd "$GFQ_R" && pwd -P)"

# The concurrency table (B3.1 and B3.7): the first row's command waits, at most
# @B@ tenths, for the second's to start, and passes only if it did.
GFQ_WA='i=0; until [ -e "@S@/second" ] || [ "$i" -ge @B@ ]; do sleep 0.1; i=$((i + 1)); done; [ -e "@S@/second" ]'
GFQ_WB='touch "@S@/second"'
_gfq_ab() {   # S, bound
  _gfq_row gfbfirst "$(_gfq_fill "$GFQ_WA" "$1" "$2")" restoration pass true
  _gfq_row gfbsecond "$(_gfq_fill "$GFQ_WB" "$1")" restoration pass true
}

# ---- B3.7: concurrency is real
_gfq_fresh "$GFQ/s7a"; _gfq_loop c7a 2 "$GFQ/t7a" "$GFQ_R" "$(_gfq_ab "$GFQ/s7a" 200)"
is  "B3.7: at FELIX_QUALIFY_JOBS=2 the first row's command sees the second row's start while it waits, and is met" \
    "$(_gfq_verdict c7a gfbfirst) $(_gfq_verdict c7a gfbsecond) rc=$GFQ_RC" "met met rc=0"
_gfq_fresh "$GFQ/s7b"; _gfq_loop c7b 1 "$GFQ/t7b" "$GFQ_R" "$(_gfq_ab "$GFQ/s7b" 200)"
case "$(_gfq_verdict c7b gfbfirst)" in
  held|unrunnable) ok  "B3.7: at FELIX_QUALIFY_JOBS=1 the same table's first row is held or unrunnable, not met (control)" ;;
  *)               bad "B3.7: at FELIX_QUALIFY_JOBS=1 the same table's first row is held or unrunnable, not met (control)" "$(_gfq_q < "$GFQ/c7b.out")" ;;
esac

# ---- B3.1: how many at once
for _gfqj in empty 0 -2 abc +2 ' 2' '2 ' 2x; do
  _gfqv="$_gfqj"; [ "$_gfqj" = empty ] && _gfqv=""
  _gfq_fresh "$GFQ/s1"; _gfq_loop c1 "$_gfqv" "$GFQ/t1" "$GFQ_R" "$(_gfq_ab "$GFQ/s1" 20)"
  is  "B3.1: FELIX_QUALIFY_JOBS=[$_gfqj] is read as 1: the first row never sees the second start" \
      "$(_gfq_verdict c1 gfbfirst) rc=$GFQ_RC" "held rc=0"
done
GFQ_CPU="$(getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null)"
case "$GFQ_CPU" in ''|*[!0-9]*) GFQ_CPU=1 ;; esac
_gfq_fresh "$GFQ/s1u"; _gfq_loop c1u unset "$GFQ/t1u" "$GFQ_R" "$(_gfq_ab "$GFQ/s1u" 200)"
if [ "$GFQ_CPU" -ge 2 ]; then GFQ_W1U=met; else GFQ_W1U=held; fi
is  "B3.1: FELIX_QUALIFY_JOBS unset runs as many rows at once as the machine has CPUs" \
    "$(_gfq_verdict c1u gfbfirst)" "$GFQ_W1U"
# At most N: three rows each waiting for all three to be in flight at once.
GFQ_W3='touch "@S@/in.$0"; i=0; until [ -e "@S@/all" ] || [ "$(ls -1 "@S@" | grep -c "^in\.")" -ge 3 ] || [ "$i" -ge @B@ ]; do sleep 0.1; i=$((i + 1)); done; if [ -e "@S@/all" ] || [ "$(ls -1 "@S@" | grep -c "^in\.")" -ge 3 ]; then touch "@S@/all"; else rm -f "@S@/in.$0"; exit 1; fi'
_gfq_three() {   # S, bound
  local k
  for k in 1 2 3; do _gfq_row "gfbthree$k" "$(_gfq_fill "${GFQ_W3//\$0/$k}" "$1" "$2")" restoration pass true; done
}
_gfq_fresh "$GFQ/s1c"; _gfq_loop c1c 3 "$GFQ/t1c" "$GFQ_R" "$(_gfq_three "$GFQ/s1c" 200)"
is  "B3.1: at FELIX_QUALIFY_JOBS=3 three rows are in flight at once" \
    "$(_gfq_verdict c1c gfbthree1) $(_gfq_verdict c1c gfbthree2) $(_gfq_verdict c1c gfbthree3)" "met met met"
_gfq_fresh "$GFQ/s1d"; _gfq_loop c1d 2 "$GFQ/t1d" "$GFQ_R" "$(_gfq_three "$GFQ/s1d" 20)"
is  "B3.1: at FELIX_QUALIFY_JOBS=2 no three rows are ever in flight at once" \
    "$(_gfq_verdict c1d gfbthree1) $(_gfq_verdict c1d gfbthree2) $(_gfq_verdict c1d gfbthree3)" "held held held"

# ---- B3.2: the same output. A met, a held, an unrunnable and an inapplicable
# row; a line the loop skips; and a met row that, run in parallel, finishes
# after the unrunnable row below it.
GFQ_EQ1='i=0; until [ -e "@S@/third" ] || [ "$i" -ge 30 ]; do sleep 0.1; i=$((i + 1)); done; exit 0'
_gfq_eq() {   # S
  _gfq_row eqmet "$(_gfq_fill "$GFQ_EQ1" "$1")" restoration pass true
  printf '\n'
  _gfq_row eqheld 'exit 0' violation fail 'printf bad > f.txt'
  _gfq_row equnrun "$(_gfq_fill 'touch "@S@/third"; ./gfb-no-such-checker' "$1")" violation fail true
  printf 'eqshort\tonly two fields\n'
  _gfq_row eqinapp 'exit 0' violation fail 'printf bad > f.txt' 'exit 1'
  _gfq_row eqheld true alternate fail 'printf other > f.txt'
}
GFQ_EQW="$(printf 'eqmet\trestoration\tpass\tpass\tmet\neqheld\tviolation\tfail\tpass\theld\nequnrun\tviolation\tfail\tunrunnable\tunrunnable\neqinapp\tviolation\tfail\t-\tinapplicable\neqheld\talternate\tfail\tpass\theld')"
_gfq_fresh "$GFQ/s2"; _gfq_loop e1 1 "$GFQ/t2a" "$GFQ_R" "$(_gfq_eq "$GFQ/s2")"; GFQ_E1RC=$GFQ_RC
_gfq_fresh "$GFQ/s2"; _gfq_loop e4 4 "$GFQ/t2b" "$GFQ_R" "$(_gfq_eq "$GFQ/s2")"; GFQ_E4RC=$GFQ_RC
is  "B3.2: at FELIX_QUALIFY_JOBS=1 the table gives today's verdict lines, in its order (control)" "$(cat "$GFQ/e1.out")" "$GFQ_EQW"
cmp -s "$GFQ/e1.out" "$GFQ/e4.out" \
  && ok  "B3.2: at FELIX_QUALIFY_JOBS=4 stdout is byte for byte what it is at 1, over a met, a held, an unrunnable and an inapplicable row" \
  || bad "B3.2: at FELIX_QUALIFY_JOBS=4 stdout is byte for byte what it is at 1, over a met, a held, an unrunnable and an inapplicable row" "$(_gfq_q < "$GFQ/e4.out")"
is  "B3.2: and its exit status is the same" "$GFQ_E4RC" "$GFQ_E1RC"
is  "B3.2: and the run at 4 leaves its TMPDIR empty" "$(_gfq_ls "$GFQ/t2b")" "empty"
_gfq_fresh "$GFQ/s2"; _gfq_loop e1s 1 "$GFQ/t2c" "$GFQ_R" "$(_gfq_eq "$GFQ/s2")" eqheld; GFQ_E1RC=$GFQ_RC
_gfq_fresh "$GFQ/s2"; _gfq_loop e4s 4 "$GFQ/t2d" "$GFQ_R" "$(_gfq_eq "$GFQ/s2")" eqheld
cmp -s "$GFQ/e1s.out" "$GFQ/e4s.out" && [ -s "$GFQ/e1s.out" ] \
  && ok  "B3.2: with one checker selected, stdout at 4 is byte for byte what it is at 1, the others' rows skipped" \
  || bad "B3.2: with one checker selected, stdout at 4 is byte for byte what it is at 1, the others' rows skipped" "$(cat "$GFQ/e1s.out" "$GFQ/e4s.out" | _gfq_q)"
is  "B3.2: and its exit status is the same" "$GFQ_RC" "$GFQ_E1RC"

# A row whose process is killed outright gives no verdict: the command kills
# the process its base's owner record names.
_gfq_k() {
  _gfq_row kmet true restoration pass true
  _gfq_row kdie 'p="$(readlink ../owner)"; kill -9 "${p%% *}"; exit 0' restoration pass true
  _gfq_row kafter true restoration pass true
}
for _gfqj in 1 4; do
  _gfq_fresh "$GFQ/tk$_gfqj"
  _gfq_loop "k$_gfqj" "$_gfqj" "$GFQ/tk$_gfqj" "$GFQ_R" "$(_gfq_k)"
  is  "B3.2: at FELIX_QUALIFY_JOBS=$_gfqj a row whose process was killed before its verdict reads unrunnable, between the rows around it" \
      "$(cut -f1,5 "$GFQ/k$_gfqj.out" | tr '\t\n' ': ')" "kmet:met kdie:unrunnable kafter:met "
  [ "$GFQ_RC" -ne 0 ] && ok "B3.2: and at $_gfqj the run's status is not zero" \
                      || bad "B3.2: and at $_gfqj the run's status is not zero" "it was 0"
  GFQ_KL="$(ls -A "$GFQ/tk$_gfqj" 2>/dev/null)"
  case "$GFQ_KL" in
    felix-qualify.??????) ok  "B3.4: at $_gfqj the TMPDIR then holds only the killed row's base" ;;
    *)                    bad "B3.4: at $_gfqj the TMPDIR then holds only the killed row's base" "it holds: $(_gfq_ls "$GFQ/tk$_gfqj")" ;;
  esac
  _gfq_loop "k${_gfqj}s" "$_gfqj" "$GFQ/tk$_gfqj" "$GFQ_R" "$(_gfq_row kmet true restoration pass true)"
  is  "B3.6: at $_gfqj the next run's sweep removes that base and its registration (control)" \
      "$(_gfq_ls "$GFQ/tk$_gfqj") $(_gfq_wts "$GFQ_R")" "empty 1"
done

# ---- B3.3: stderr. Each row's command records its base, then swaps it for a
# symlink, so the row's drop says one line naming it. The first row waits, at
# most five seconds, for the second row's base to be gone, so in parallel the
# second row has said its line before the first one has.
GFQ_SWAP='b="${PWD%/w}"; printf "%s\n" "$b" > "@S@/base.@K@"; cd / && mv "$b" "$b.mv" && ln -s "$b.mv" "$b"'
GFQ_SE1='i=0; until { [ -s "@S@/base.2" ] && b2="$(cat "@S@/base.2")" && [ ! -e "$b2" ] && [ ! -L "$b2" ]; } || [ "$i" -ge 50 ]; do sleep 0.1; i=$((i + 1)); done'
_gfq_se() {   # S
  _gfq_row se1 "$(_gfq_fill "$GFQ_SE1; ${GFQ_SWAP//@K@/1}" "$1")" restoration pass true
  _gfq_row se2 "$(_gfq_fill "${GFQ_SWAP//@K@/2}" "$1")" restoration pass true
  _gfq_row se3 "$(_gfq_fill "${GFQ_SWAP//@K@/3}" "$1")" restoration pass true
}
# The run's stderr with each row's base named by its row, then the moved trees
# taken away.
_gfq_senorm() {   # name S repo
  local k b
  cp "$GFQ/$1.err" "$GFQ/$1.norm"
  for k in 1 2 3; do
    b="$(cat "$2/base.$k" 2>/dev/null)"; [ -n "$b" ] || continue
    LC_ALL=C awk -v b="$b" -v r="<row $k>" '{ while ((i = index($0, b)) > 0) $0 = substr($0, 1, i - 1) r substr($0, i + length(b)); print }' \
      "$GFQ/$1.norm" > "$GFQ/$1.norm2" && mv "$GFQ/$1.norm2" "$GFQ/$1.norm"
    rm -rf "${b:?}.mv"
  done
  git -C "$3" worktree prune >/dev/null 2>&1
}
GFQ_RS="$GFQ/rse"; _gfq_repo "$GFQ_RS"; GFQ_RS="$(cd "$GFQ_RS" && pwd -P)"
_gfq_fresh "$GFQ/sse"; _gfq_loop se_1 1 "$GFQ/tse1" "$GFQ_RS" "$(_gfq_se "$GFQ/sse")"; _gfq_senorm se_1 "$GFQ/sse" "$GFQ_RS"
_gfq_fresh "$GFQ/sse"; _gfq_loop se_4 4 "$GFQ/tse4" "$GFQ_RS" "$(_gfq_se "$GFQ/sse")"; _gfq_senorm se_4 "$GFQ/sse" "$GFQ_RS"
GFQ_SEW=""
for _gfqk in 1 2 3; do
  GFQ_SEW="$GFQ_SEW$(grep -c "^felix: the scratch directory <row $_gfqk> had been replaced by a symlink" "$GFQ/se_1.norm")"
done
is  "B3.3: at FELIX_QUALIFY_JOBS=1 each of the fixture's rows says one line on stderr naming its own base (control)" "$GFQ_SEW" "111"
cmp -s "$GFQ/se_1.norm" "$GFQ/se_4.norm" \
  && ok  "B3.3: at FELIX_QUALIFY_JOBS=4 each row's stderr reaches the caller whole and in the table's order, as at 1" \
  || bad "B3.3: at FELIX_QUALIFY_JOBS=4 each row's stderr reaches the caller whole and in the table's order, as at 1" "$(_gfq_q < "$GFQ/se_4.norm")"
is  "B3.3: and its stdout is what it is at 1" "$(cat "$GFQ/se_4.out")" "$(cat "$GFQ/se_1.out")"

# ---- B3.4: what the loop writes lives where no sweep looks. Seen while two
# rows wait in flight: every felix-qualify. name is a row's base (it holds an
# owner record), and nothing is named tmp.*.
GFQ_W4='touch "@S@/in.$0"; i=0; until [ -e "@S@/go" ] || [ "$i" -ge 300 ]; do sleep 0.1; i=$((i + 1)); done'
_gfq_fresh "$GFQ/s4"
_gfq_loop_start l4 2 "$GFQ/t4" "$GFQ_R" \
  "$(_gfq_row l4a "$(_gfq_fill "${GFQ_W4//\$0/a}" "$GFQ/s4")" restoration pass true; _gfq_row l4b "$(_gfq_fill "${GFQ_W4//\$0/b}" "$GFQ/s4")" restoration pass true)"
_gfqi=0; while [ ! -e "$GFQ/s4/in.a" ] && [ "$_gfqi" -lt 300 ]; do sleep 0.1; _gfqi=$((_gfqi + 1)); done
GFQ_L4=""
for _gfqe in "$GFQ/t4"/* "$GFQ/t4"/.[!.]*; do
  [ -e "$_gfqe" ] || [ -L "$_gfqe" ] || continue
  case "${_gfqe##*/}" in
    tmp.*) GFQ_L4="$GFQ_L4 ${_gfqe##*/}(tmp.*)" ;;
    felix-qualify.??????) [ -L "$_gfqe/owner" ] || GFQ_L4="$GFQ_L4 ${_gfqe##*/}(no owner)" ;;
  esac
done
touch "$GFQ/s4/go"; _gfq_end
is  "B3.4: while rows are in flight nothing in TMPDIR but a row's base is named felix-qualify. and six, and nothing is named tmp.*" "${GFQ_L4:-none}" "none"
is  "B3.4: and when the loop returns its TMPDIR is empty" "$(_gfq_ls "$GFQ/t4") rc=$GFQ_RC" "empty rc=0"

# ---- B3.5: signals. Each row's command says it is running through a file and
# waits, at most twenty seconds, for the file the test writes once the signal
# is sent.
GFQ_W5='touch "@S@/ready.$0"; i=0; until [ -e "@S@/sent" ] || [ "$i" -ge 200 ]; do sleep 0.1; i=$((i + 1)); done; exit 0'
GFQ_RG="$GFQ/rsig"; _gfq_repo "$GFQ_RG"; GFQ_RG="$(cd "$GFQ_RG" && pwd -P)"
rm -f "$GFQ/sig.serial"
# How many processes are left in process group $1.
_gfq_pg() { ps -A -o pgid= 2>/dev/null | LC_ALL=C awk -v g="$1" '$1 == g { n++ } END { print n + 0 }'; }
# The state is read the moment the loop exits, or, given settle, once every
# process of its group has ended too (at most thirty seconds more).
_gfq_sig() {   # signal jobs rows group|loop [settle] -> "rc=.. in-flight=.. started-after=.. worktrees=.. tmpdir=.."
  local sig="$1" j="$2" n="$3" to="$4" S="$GFQ/s5" T="$GFQ/t5" k rows="" i=0 want c a b
  _gfq_fresh "$S"; _gfq_fresh "$T"
  for k in $(seq 1 "$n"); do rows="$rows$(_gfq_row "gfbsig$k" "$(_gfq_fill "${GFQ_W5//\$0/$k}" "$S")" restoration pass true)
"; done
  _gfq_loop_start "s5$sig$j$to" "$j" "$T" "$GFQ_RG" "$rows"
  while [ ! -e "$S/ready.1" ] && [ "$i" -lt 300 ] && kill -0 "$GFQ_PID" 2>/dev/null; do sleep 0.1; i=$((i + 1)); done
  if [ ! -e "$S/ready.1" ]; then _gfq_end 1; printf 'no row command ever ran'; return; fi
  # Up to thirty seconds for every row that may be in flight to say so; none
  # once a run has shown that rows here do not run at once.
  want="$j"; [ "$want" -gt "$n" ] && want="$n"; i=0; b=300; [ -e "$GFQ/sig.serial" ] && b=0
  while [ "$(ls -1 "$S" | grep -c '^ready\.')" -lt "$want" ] && [ "$i" -lt "$b" ]; do sleep 0.1; i=$((i + 1)); done
  c="$(ls -1 "$S" | grep -c '^ready\.')"
  [ "$c" -ge "$want" ] || : > "$GFQ/sig.serial"
  if [ "$to" = group ]; then kill -s "$sig" -- "-$GFQ_PID" 2>/dev/null; else kill -s "$sig" "$GFQ_PID" 2>/dev/null; fi
  touch "$S/sent"
  _gfq_end 600
  if [ "${5:-}" = settle ]; then
    i=0; while [ "$(_gfq_pg "$GFQ_PID")" -gt 0 ] && [ "$i" -lt 300 ]; do sleep 0.1; i=$((i + 1)); done
  fi
  a="$(ls -1 "$S" | grep -c '^ready\.')"
  printf 'rc=%s in-flight=%s started-after=%s worktrees=%s tmpdir=%s' "$GFQ_RC" "$c" "$((a - c))" "$(_gfq_wts "$GFQ_RG")" "$(_gfq_ls "$T")"
  # Whatever a failing run left is taken away, so the next starts clean.
  kill -KILL -- "-$GFQ_PID" 2>/dev/null
  rm -rf "${T:?}"/*; git -C "$GFQ_RG" worktree prune >/dev/null 2>&1
}
for _gfqs in INT:130 TERM:143 HUP:129; do
  _gfqn="${_gfqs%%:*}"; _gfqc="${_gfqs#*:}"
  GFQ_N1="B3.5: $_gfqn to the group at FELIX_QUALIFY_JOBS=1 while a row's command runs: exit $_gfqc, no row after it, its tree and registration gone once the run's processes have ended (control)"
  GFQ_N4="B3.5: $_gfqn to the group at FELIX_QUALIFY_JOBS=4 while four rows' commands run: exit $_gfqc, no row after it, every tree and registration gone when the loop exits"
  GFQ_NL="B3.5: $_gfqn to the loop alone at FELIX_QUALIFY_JOBS=4 while four rows' commands run: exit $_gfqc, no row after it, every tree and registration gone when the loop exits"
  if [ "$GFQ_PERL" -eq 1 ]; then
    is "$GFQ_N1" "$(_gfq_sig "$_gfqn" 1 3 group settle)" "rc=$_gfqc in-flight=1 started-after=0 worktrees=1 tmpdir=empty"
    is "$GFQ_N4" "$(_gfq_sig "$_gfqn" 4 6 group)" "rc=$_gfqc in-flight=4 started-after=0 worktrees=1 tmpdir=empty"
    is "$GFQ_NL" "$(_gfq_sig "$_gfqn" 4 6 loop)"  "rc=$_gfqc in-flight=4 started-after=0 worktrees=1 tmpdir=empty"
  else
    for _gfqm in "$GFQ_N1" "$GFQ_N4" "$GFQ_NL"; do skip "$_gfqm" "no perl to start the loop with INT at its default"; done
  fi
done

# ---- B3.9: shared git state. Eight rows, each mutating f.txt its own way,
# each command waiting (at most three seconds) until four mutations are made,
# then reading its own mutation and its own worktree in git's list.
GFQ_M='i=0; until [ "$(ls -1 "@S@" | grep -c "^mut\.")" -ge 4 ] || [ "$i" -ge 30 ]; do sleep 0.1; i=$((i + 1)); done; git worktree list --porcelain | grep -qx "worktree $(pwd -P)" || exit @X@; '
_gfq_m() {   # S
  local k
  for k in 1 2 3 4 5 6 7 8; do
    case "$k" in
      1|3|5|7) _gfq_row "mut$k" "$(_gfq_fill "${GFQ_M//@X@/1}" "$1")[ \"\$(cat f.txt)\" = M$k ]" restoration pass \
                 "$(_gfq_fill "printf 'M$k\\n' > f.txt; touch \"@S@/mut.$k\"" "$1")" ;;
      *)       _gfq_row "mut$k" "$(_gfq_fill "${GFQ_M//@X@/0}" "$1")[ \"\$(cat f.txt)\" != V$k ]" violation fail \
                 "$(_gfq_fill "printf 'V$k\\n' > f.txt; touch \"@S@/mut.$k\"" "$1")" ;;
    esac
  done
}
_gfq_fresh "$GFQ/s9"; _gfq_loop m4 4 "$GFQ/t9" "$GFQ_R" "$(_gfq_m "$GFQ/s9")"
is  "B3.9: at FELIX_QUALIFY_JOBS=4 eight rows with different mutations each see their own mutation and their own worktree, and each is met" \
    "$(cut -f1,5 "$GFQ/m4.out" | tr '\t\n' ': ')" "mut1:met mut2:met mut3:met mut4:met mut5:met mut6:met mut7:met mut8:met "
is  "B3.9: and afterwards the repository lists its main worktree alone, and TMPDIR is empty" \
    "$(_gfq_wts "$GFQ_R") $(_gfq_ls "$GFQ/t9")" "1 empty"

# ---- B3.8: felix qualify prints what it prints at 1, over the same table.
GFQ_QP="$FROOT/projects/gfbq"; GFQ_QR="$GFQ/rq"
mkdir -p "$GFQ_QP" "$MEM/gfbq"
printf '{\n  "name": "gfbq",\n  "remote_match": "example.invalid/gfbq",\n  "gate": "true"\n}\n' > "$GFQ_QP/project.json"
printf '# gfbq\n' > "$GFQ_QP/CLAUDE.md"
mkdir -p "$GFQ_QR" && ( cd "$GFQ_QR" && _gfq_git init -q -b main && printf 'good\n' > f.txt && printf 'gfbq\n' > .felix \
  && _gfq_git add -A && _gfq_git commit -qm base ) >/dev/null 2>&1
GFQ_QR="$(cd "$GFQ_QR" && pwd -P)"
_gfq_eq "$GFQ/s8" | grep -v '^eqshort' > "$GFQ_QP/qualification.tsv"
_gfq_fresh "$GFQ/s8"; mkdir -p "$GFQ/t8a"
_gfq_spawn q1 "$GFQ_QR" env FELIX_QUALIFY_JOBS=1 TMPDIR="$GFQ/t8a" "$FELIX" qualify; _gfq_end; GFQ_Q1RC=$GFQ_RC
_gfq_fresh "$GFQ/s8"; mkdir -p "$GFQ/t8b"
_gfq_spawn q4 "$GFQ_QR" env FELIX_QUALIFY_JOBS=4 TMPDIR="$GFQ/t8b" "$FELIX" qualify; _gfq_end
has "B3.8: felix qualify over the fixture's table runs its rows (control)" "$(cat "$GFQ/q1.out")" "eqinapp"
cmp -s "$GFQ/q1.out" "$GFQ/q4.out" \
  && ok  "B3.8: felix qualify at FELIX_QUALIFY_JOBS=4 prints byte for byte what it prints at 1" \
  || bad "B3.8: felix qualify at FELIX_QUALIFY_JOBS=4 prints byte for byte what it prints at 1" "$(diff "$GFQ/q1.out" "$GFQ/q4.out" | _gfq_q)"
is  "B3.8: and exits as it does at 1" "$GFQ_RC" "$GFQ_Q1RC"
is  "B3.8: and leaves its TMPDIR empty" "$(_gfq_ls "$GFQ/t8b")" "empty"
# <<< gate-friction-b
