# The suite's receipt: what a run that reached its end leaves behind, and what a
# later run reads before it pays for the suite again.
#
# Sourced by tests/run, and sourceable on its own. It needs bash 3.2, git and
# ../lib/verify.sh, which it loads inside a subshell each time it asks for a
# tree id, so the shell that sources this file gains no felix_verify_* name and
# no FELIX_UNTRACKED_CAP. The driver is 500 lines at most (part 1040), and this
# is where the receipt's rules live so that the driver only decides when to ask.
#
# Why it exists. An engine change paid for the whole suite three times before
# it landed: the record run, the red run the record run then made, and the
# gate. Measured on a quiet machine on 2026-10-10 the suite was 1429 s of the
# gate's 1565 s (audits/2026-10-10-gate-time). The record run and red now run
# side by side, and the third pass is the gate's `tests` check asking this file
# whether the tree it is about to gate is one a run already passed. The design
# is docs/2026-10-12-gate-friction-design.md, section 3; the rules are
# docs/2026-10-12-gate-friction-contract-a.md, C4 and C5.
#
# One receipt for each checkout, one line, tab-separated, in the checkout's git
# directory (git rev-parse --git-path), which is outside the tree: writing it
# moves no tree id. A linked worktree has a git directory of its own, so it has
# a receipt of its own.
#
#   v1  <tree id>  <mode>  <passed>  <failed>  <skipped>  <env>  <start>  <end>
#
# <mode> is normal or record; <start> and <end> are Unix seconds.
#
# What a receipt cannot say, plainly. It is a file a session can write, as the
# gate's own receipt is that `felix merge` already trusts. Reuse adds no new
# kind of trust, and GitHub CI still runs the whole suite on Linux before
# anything merges. What it does refuse is the honest mistakes: a tree that
# moved, a run that failed, a different bash, a different host, a `claude` CLI
# that turns skips into passes or back, a receipt older than twelve hours.

_SR_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" 2>/dev/null && pwd)/verify.sh"

# Where this checkout's receipt is. git prints the path relative to the
# directory it was asked from when the git directory is inside it, which is
# every ordinary checkout, so it is made absolute against the root.
_sr_path() {   # <root> -> the absolute path; status 1 and nothing when <root> is no git checkout
  local p
  p="$(git -C "$1" rev-parse --git-path felix-suite-receipt 2>/dev/null)" || return 1
  [ -n "$p" ] || return 1
  case "$p" in /*) ;; *) p="${1%/}/$p" ;; esac
  printf '%s\n' "$p"
}

# The tree as felix_tree_id names it, with Felix's home left empty so nothing is
# excluded: a suite run judges the whole checkout. `stable` also leaves out the
# two files a record run rewrites while it runs, the manifest and red.tsv, so a
# record run can say that nothing else moved (C8). A coarse id, the one a tree
# with more untracked files than the cap gets, is a hash of a count and not of
# the tree, and a receipt keyed to it would stand for any tree with as many
# stray files, so it counts as an id that cannot be had.
_sr_tree() {   # <root> [stable] -> the id; status 1 and nothing when it cannot be had
  local id
  if [ "${2:-}" = stable ]; then
    id="$( . "$_SR_LIB" 2>/dev/null && felix_tree_id "$1" "" \
             ':(exclude)engine/harness/tests/assertions.tsv' ':(exclude)engine/harness/tests/red.tsv' )" || return 1
  else
    id="$( . "$_SR_LIB" 2>/dev/null && felix_tree_id "$1" "" )" || return 1
  fi
  case "$id" in ''|coarse:*) return 1 ;; esac
  printf '%s\n' "$id"
}

# What a run depends on that the tree does not hold. The host and the bash are
# what the suite's timing and its syntax rules answer to; the locale changes
# how sort and awk order names; the PATH, as a hash because it is long and only
# its identity matters, decides which tools the fixtures find; and whether a
# `claude` CLI is on it turns some assertions into skips (has_claude), so a run
# with one and a run without are different runs.
_sr_env() {
  local loc="${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" cl=no ph
  command -v claude >/dev/null 2>&1 && cl=yes
  ph="$(printf '%s' "$PATH" | git hash-object --stdin 2>/dev/null)"
  printf 'host=%s;bash=%s;locale=%s;path=%s;claude=%s\n' "$(uname -n 2>/dev/null)" "$BASH_VERSION" "$loc" "$ph" "$cl"
}

# Whether a run may be answered from the receipt: `reuse <passed> <failed>
# <skipped> <end> <mode>`, or `run <reason>`, the first reason that applies, in
# the order a person would find it out. One line either way and status 0, so a
# caller reads the line and not the status. The fields are digits and are never
# put through $(( )): a leading zero is an octal error there, and in bash 3.2 an
# arithmetic error discards the whole command it sits in. The tabs are counted
# and cut with parameter expansion because read with a tab in IFS folds a run
# of tabs into one and would read an empty field as no field at all.
_sr_check() {   # <root>
  local root="$1" p rec line t="" f1 f2 f3 f4 f5 f6 f7 f8 f9 rest now cur
  p="$(_sr_path "$root")" || { echo "run no checkout"; return 0; }
  if [ ! -e "$p" ] && [ ! -L "$p" ]; then echo "run no receipt"; return 0; fi
  if [ -L "$p" ] || [ ! -f "$p" ]; then echo "run not a regular file"; return 0; fi
  # A trailing x keeps the newlines $( ) would strip, so two lines are two.
  rec="$(cat -- "$p" 2>/dev/null && printf x)"
  case "$rec" in *x) rec="${rec%x}" ;; *) echo "run unreadable receipt"; return 0 ;; esac
  line="$rec"; case "$line" in *$'\n') line="${line%$'\n'}" ;; esac
  case "$line" in ''|*$'\n'*) echo "run malformed receipt"; return 0 ;; esac
  t="${line//[!$'\t']/}"
  [ "${#t}" -eq 8 ] || { echo "run malformed receipt"; return 0; }
  f1="${line%%$'\t'*}"; rest="${line#*$'\t'}"
  f2="${rest%%$'\t'*}"; rest="${rest#*$'\t'}"
  f3="${rest%%$'\t'*}"; rest="${rest#*$'\t'}"
  f4="${rest%%$'\t'*}"; rest="${rest#*$'\t'}"
  f5="${rest%%$'\t'*}"; rest="${rest#*$'\t'}"
  f6="${rest%%$'\t'*}"; rest="${rest#*$'\t'}"
  f7="${rest%%$'\t'*}"; rest="${rest#*$'\t'}"
  f8="${rest%%$'\t'*}"; f9="${rest#*$'\t'}"
  now="$(date +%s)"
  [ "$f1" = v1 ] || { echo "run malformed receipt"; return 0; }
  case "$f3" in normal|record) ;; *) echo "run malformed receipt"; return 0 ;; esac
  for cur in "$f4" "$f5" "$f6" "$f8" "$f9"; do
    case "$cur" in ''|*[!0-9]*) echo "run malformed receipt"; return 0 ;; esac
  done
  # Compared as numbers by awk, which reads a long digit string as a float and
  # never fails on it; a time too large to be one is in the future anyway.
  awk -v s="$f8" -v e="$f9" -v n="$now" 'BEGIN { exit !(s + 0 > e + 0 || e + 0 > n + 60) }' \
    && { echo "run malformed receipt"; return 0; }
  awk -v f="$f5" 'BEGIN { exit !(f + 0 != 0) }' && { echo "run failures recorded"; return 0; }
  cur="$(_sr_tree "$root")" || cur=""
  { [ -n "$cur" ] && [ "$cur" = "$f2" ]; } || { echo "run another tree"; return 0; }
  [ "$(_sr_env)" = "$f7" ] || { echo "run another environment"; return 0; }
  awk -v e="$f9" -v n="$now" 'BEGIN { exit !(n - e > 43200) }' && { echo "run older than 12 hours"; return 0; }
  echo "reuse $f4 $f5 $f6 $f9 $f3"
}

# What `tests/run --reuse` prints when the receipt stands: the line the gate
# shows first and the summary it shows last. The time is the local one the run
# ended at, BSD date's -r first and GNU's -d @ if that is the one here, and the
# skipped clause is left out when nothing was skipped, as the summary of a run
# leaves it out.
_sr_reused() {   # <the `reuse ...` line _sr_check printed>
  local w p f s e m hm
  read -r w p f s e m <<< "$1"
  e="$(awk -v x="$e" 'BEGIN { printf "%d", x }')"
  hm="$(date -r "$e" +%H:%M 2>/dev/null || date -d "@$e" +%H:%M 2>/dev/null)" || hm=""
  printf 'reused the suite run that ended %s on this tree (%s), not run again\n' "${hm:-unknown}" "$m"
  printf '\n%s passed, 0 failed' "$p"
  awk -v x="$s" 'BEGIN { exit !(x + 0 > 0) }' && printf ', %s skipped' "$s"
  printf ' (reused)\n'
}

# The --reuse question, asked before anything is built. A receipt that stands
# ends the run here with exit 0, which is why this exits and does not return;
# one that does not says why on the first line and the run goes on, receipt
# rules and all.
_sr_answer() {   # <root>
  local v
  v="$(_sr_check "$1")"
  case "$v" in
    "reuse "*) _sr_reused "$v"; exit 0 ;;
    *)         printf 'not reused: %s\n' "${v#run }" ;;
  esac
}

# What a run takes before its first part: the tree, the tree without the two
# record files, the environment and the clock. Before any part, and before red
# can rewrite those two files, so what the end compares is what the start saw.
_sr_begin() {   # <root> -> sets _sr_t0, _sr_s0, _sr_e0 and _sr_start
  _sr_t0="$(_sr_tree "$1")"; _sr_s0="$(_sr_tree "$1" stable)"
  _sr_e0="$(_sr_env)"; _sr_start="$(date +%s)"
}

# What a run that reached its end does about the receipt, after its summary
# line and with no say in its exit status. It writes one only when it can say
# that the tree it passed is the tree it leaves: nothing failed; the manifest
# was compared; the environment is the one the run began in; and the tree is
# the one it began with. A record run leaves a different tree on purpose, since
# it and red rewrite the manifest and red.tsv, so it compares the tree with
# those two files left out, and says its record was judged. That is sound
# because nothing in the suite but the judged checks reads those two files'
# content; every other mention of them reads a fixture (the design checked
# parts 0440, 0720, 0730, 0740, 0990 and 1000 on 2026-10-12, and a search of
# the parts for a read of the real files, by HERE or REAL_HARNESS, finds none
# outside part 1010), and the build shows it with the suite run twice on one
# tree under two different valid records. The tree id written is the full one
# taken now. Any other run takes the last receipt away.
_sr_finish() {   # <root> <record: 1 or 0> <compared: 1 or 0> <judged: 1 or 0> <passed> <failed> <skipped>
  local root="$1" mode=normal t1="" s1="" ok=0
  [ "$2" = 1 ] && mode=record
  if [ "$6" = 0 ] && [ "$3" = 1 ] && [ -n "$_sr_t0" ] && [ -n "$_sr_s0" ] && [ "$(_sr_env)" = "$_sr_e0" ]; then
    t1="$(_sr_tree "$root")"
    if [ "$mode" = normal ]; then
      [ -n "$t1" ] && [ "$t1" = "$_sr_t0" ] && ok=1
    elif [ "$4" = 1 ] && [ -n "$t1" ]; then
      s1="$(_sr_tree "$root" stable)"
      [ -n "$s1" ] && [ "$s1" = "$_sr_s0" ] && ok=1
    fi
  fi
  if [ "$ok" = 1 ]; then
    _sr_write "$root" "$t1" "$mode" "$5" "$6" "$7" "$_sr_e0" "$_sr_start" "$(date +%s)"
  else
    _sr_drop "$root"
  fi
}

# A receipt path that holds something other than a regular file is left alone,
# written through by nothing and removed by nothing: a symbolic link would be
# followed to wherever it points and a directory would take the temporary file
# in as a member. Said, so that the run that declined is not mistaken for one
# that wrote.
_sr_plain() {   # <path>: status 0 when nothing is there or a regular file is
  if [ -L "$1" ] || { [ -e "$1" ] && [ ! -f "$1" ]; }; then
    printf '  receipt not written: %s is not a regular file\n' "$1"
    return 1
  fi
}

# A sibling temporary file in the same directory, then one mv, so a reader sees
# the old receipt or the new one and never half of one.
_sr_write() {   # <root> <tree id> <mode> <passed> <failed> <skipped> <env> <start> <end>
  local p t
  p="$(_sr_path "$1")" || return 1
  _sr_plain "$p" || return 1
  t="$p.tmp.$$"
  if printf 'v1\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" > "$t" 2>/dev/null \
     && mv -f "$t" "$p" 2>/dev/null; then
    return 0
  fi
  rm -f "$t" 2>/dev/null
  printf '  receipt not written: could not write %s\n' "$p"
  return 1
}

# A run that reached its end and did not earn a receipt takes the checkout's
# last one away, so that a failing run, or one whose tree moved under it, never
# leaves an earlier pass standing for the next gate to find.
_sr_drop() {   # <root>
  local p
  p="$(_sr_path "$1")" || return 0
  if [ ! -e "$p" ] && [ ! -L "$p" ]; then return 0; fi
  _sr_plain "$p" || return 1
  rm -f "$p" 2>/dev/null
  return 0
}
