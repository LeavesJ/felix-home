# The judges of tests/lib (contract C2, amended 2026-10-16): _lib_runs_nothing
# FILE, which says whether sourcing a lib file runs anything, and _lib_clashes,
# which says whether a lib file takes a name the suite already has. Both are
# defined here and not in part 0003, beside _suite_files, because 0003 would
# pass the 1,000 lines part 1040 allows; they are defined before the driver
# writes lib-before.names, so a lib file that defines either is a clash.

# _lib_runs_nothing FILE -> 0 when sourcing FILE does nothing, 1 and one line
# naming FILE and the first thing it did when it does something. A lib file
# defines functions and sets plain variables (contract C2); a fixture built, a
# file written, a line printed or an assertion made at source time would run in
# every part's prelude: in the serial run once, and in a part run alone once
# more.
#
# FILE is judged in a new process, never in the suite's own shell:
#   env -i PATH=... HOME=... TMPDIR=... TMP=... FROOT=... MEM=... REPO=...
#          FELIX_HOME=... FELIX=... /bin/bash --noprofile --norc -c SCRIPT
# with all eight below a fresh scratch directory made under $TMP (TMP is the
# directory itself; the others are directories made in it, FELIX a path in it),
# under the suite's own options, set -u and -o pipefail. So nothing the file
# does to the shell (a trap, an option, the umask, the directory, an exec, a
# readonly or exported name, an exit) reaches the suite, and a variable the
# caller exported, such as the guard of a fixture built once, is not there for
# the file to find. It returns 0 only if all of these hold:
#   1. every command the file runs while it is sourced is a plain assignment: a
#      simple command made only of NAME=VALUE words (NAME+=VALUE as well), no
#      VALUE holding $( , a backtick, <( or >( , and nothing else in it, so no
#      redirect. A function definition runs no command and is allowed;
#   2. nothing was printed on stdout or stderr;
#   3. nothing under the scratch directory was created, changed or removed;
#   4. the shell did not end before the source returned (an exit, an unbound
#      variable under set -u, a signal).
# Not judged here: a name the file sets that the suite already uses (FAIL=0,
# PATH=, IFS=, a function named bad). That is no command; it is _lib_clashes.
#
# How the commands are seen, measured on /bin/bash 3.2.57(1)-release (arm64):
# - A DEBUG trap fires inside a sourced file only under set -T (functrace). Not
#   set, it fires once for the `.` command in the caller and for no command in
#   the file. Set, it fires before every simple command the file runs at its
#   top level, with BASH_COMMAND the command's text as written.
# - In the trap BASH_SOURCE[0] is the path the file was named by in `.`, here
#   absolute, and BASH_SOURCE[1] the file that sourced it. The wrapper's own
#   commands run with BASH_SOURCE[0] the wrapper, so the trap records a command
#   only where BASH_SOURCE[0] is FILE.
# - A function definition fires nothing, in all three spellings (name() {,
#   name () {, function name {). Its body runs, and fires, only when it is
#   called, and a call is a command.
# - A compound command fires for what it holds: if, while and { } do not fire
#   for themselves, only for the commands inside; for, case, (( )) and [[ ]]
#   fire for their header as well ("for i in 1 2", "case $A in ",
#   "[[ -n $A ]]"). ( ) runs its commands in a subshell that has the trap, and
#   fires for them.
# - A command substitution inside an assignment fires the assignment, text and
#   all ("E=$(date +%s)"), and then, from the subshell, the commands inside it.
#   So the text of the assignment is what is judged, and a value holding $( is
#   refused whatever it runs. $(( )) is refused with it: it holds $( as text.
# - A redirect is part of the text, spaced as the shell prints it: "H=1 >
#   /abs/file", "I=1 2> /dev/null". It is not a NAME=VALUE word, so an
#   assignment with a redirect is refused. So are `export S=1`, `declare -x`,
#   `readonly` and `local`: their first word is not a name with an =.
# - A command run in the background, X=1 &, fires in the shell; ( sleep 1;
#   : > f ) & fires its commands from the subshell, a moment later, in no order
#   with the shell's own. A record cannot be counted on for those, so the
#   wrapper asks `jobs -p` once the source has returned: a job the file left
#   running is a failure of its own, and is killed. ($! is no use: under set -u
#   in 3.2, reading it before any background command ran ends the shell.)
# - exit, return, set, trap, shopt, umask, cd, exec, sleep, mkdir and every
#   other command fire as their text, so rule 1 refuses each before it does
#   anything rules 2 and 3 would see. Rule 3 is the net for what rule 1 cannot
#   see; it compares the paths under the scratch directory before and after,
#   and asks find -newer a file made just before the run, since find -ls shows
#   a modification time only to the minute.
# The wrapper writes the commands to a log outside the scratch directory, one
# record to a command, each begun by a \001 (a multi-line command is one
# record); the log, the output and the end mark are under a second directory
# made beside the scratch one. The caller keeps no function or variable from
# FILE, and its TMP, FROOT, MEM and REPO are as they were: all of it happens in
# the child.
_lrn_awk='
function plain(s,   n, i, c, st, w, m, d, nw) {   # s holds only NAME=VALUE words
  n = length(s); i = 1; nw = 0
  for (;;) {
    while (i <= n && substr(s, i, 1) ~ /[ \t\n]/) i++
    if (i > n) return nw > 0
    st = i
    if (!match(substr(s, i), /^[A-Za-z_][A-Za-z0-9_]*\+?=/)) return 0
    i += RLENGTH; d = 0
    if (substr(s, i, 1) == "(") d = 1
    while (i <= n) {
      c = substr(s, i, 1)
      if (c == "\\") { i += 2; continue }
      if (c == sq) {
        w = index(substr(s, i + 1), sq)
        if (w == 0) return 0
        i += w + 1; continue
      }
      if (c == "\"") {
        for (m = i + 1; m <= n; m++) {
          c = substr(s, m, 1)
          if (c == "\\") m++
          else if (c == "\"") break
        }
        if (m > n) return 0
        i = m + 1; continue
      }
      if (d == 0 && c ~ /[ \t\n]/) break
      if (d > 0 && c == "(") d++
      if (d > 0 && c == ")") { d--; if (d == 0) { i++; break } }
      i++
    }
    w = substr(s, st, i - st)
    if (index(w, "$(") || index(w, "`") || index(w, "<(") || index(w, ">(")) return 0
    nw++
  }
}
BEGIN { RS = "\001"; sq = sprintf("%c", 39) }
{ sub(/\n$/, "") }
NR > 1 && !plain($0) { gsub(/[\n\r\t]+/, " "); print substr($0, 1, 100); exit }'
_lib_runs_nothing() {
  local f="${1-}" s w said="" nb na rc k script
  case "$f" in /*) ;; *) f="$PWD/$f" ;; esac
  if [ -z "${1-}" ] || [ ! -f "$f" ]; then printf '%s: no such lib file to source\n' "${1-}"; return 1; fi
  s="$(mktemp -d "$TMP/lib-runs-nothing.XXXXXX")" && w="$(mktemp -d "$TMP/lib-runs-nothing-out.XXXXXX")" \
    && [ -n "$s" ] && [ -n "$w" ] || { printf '%s: no scratch directory to source it in\n' "$f"; return 1; }
  mkdir "$s/home" "$s/tmp" "$s/froot" "$s/memory" "$s/repo" "$s/felix-home" && : > "$w/log" && : > "$w/ref" \
    || { printf '%s: no scratch directory to source it in\n' "$f"; return 1; }
  nb="$(LC_ALL=C find "$s")"
  read -r -d '' script <<'LRN_CHILD_SCRIPT' || true
set -uTo pipefail
_lrn_f="$1"; _lrn_log="$2"; _lrn_end="$3"; shift 3
cd -- "$TMP" || exit 99
trap '[ "${BASH_SOURCE[0]-}" != "$_lrn_f" ] || printf "\001%s\n" "$BASH_COMMAND" >> "$_lrn_log"' DEBUG
. "$_lrn_f"
trap - DEBUG
jobs -p > "$_lrn_end.jobs"
exec >/dev/null 2>&1
[ ! -s "$_lrn_end.jobs" ] || kill -9 $(< "$_lrn_end.jobs")
: > "$_lrn_end"
LRN_CHILD_SCRIPT
  env -i PATH="$PATH" HOME="$s/home" TMPDIR="$s/tmp" TMP="$s" FROOT="$s/froot" MEM="$s/memory" REPO="$s/repo" \
    FELIX_HOME="$s/felix-home" FELIX="$s/felix" /bin/bash --noprofile --norc -c "$script" lrn "$f" "$w/log" "$w/end" \
    > "$w/out" 2>&1 < /dev/null; rc=$?
  k="$(LC_ALL=C awk "$_lrn_awk" "$w/log")"
  if [ -n "$k" ]; then said="ran [$k]"
  elif [ ! -f "$w/end" ]; then said="ended the shell before the source returned (status $rc)"
  elif [ -s "$w/end.jobs" ]; then said="left a background job running"
  elif [ -s "$w/out" ]; then
    said="printed $(wc -c < "$w/out" | tr -d ' ') byte(s) to stdout or stderr, the first line [$(head -1 "$w/out" | LC_ALL=C tr -d '\r' | cut -c1-60)]"
  else
    na="$(LC_ALL=C find "$s")"
    if [ "$na" != "$nb" ]; then
      k="$(LC_ALL=C comm -13 <(LC_ALL=C sort <<<"$nb") <(LC_ALL=C sort <<<"$na") | head -3 | sed "s|^$s/*||" | LC_ALL=C tr '\n' ' ')"
      if [ -n "$k" ]; then said="created under its scratch directory: $k"
      else
        k="$(LC_ALL=C comm -23 <(LC_ALL=C sort <<<"$nb") <(LC_ALL=C sort <<<"$na") | head -3 | sed "s|^$s/*||" | LC_ALL=C tr '\n' ' ')"
        said="removed under its scratch directory: $k"
      fi
    else
      k="$(LC_ALL=C find "$s" -newer "$w/ref" | head -3 | sed "s|^$s/*||" | LC_ALL=C tr '\n' ' ')"
      [ -z "$k" ] || said="changed under its scratch directory: $k"
    fi
  fi
  chmod -R u+rwX "$s" "$w" 2>/dev/null
  rm -rf "$s" "$w"
  [ -z "$said" ] && return 0
  printf '%s: sourcing it %s\n' "$f" "$said" | LC_ALL=C tr '\n' ' ' | sed 's/ $//'; printf '\n'
  return 1
}
