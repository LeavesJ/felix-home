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

# _lib_clashes -> one line NAME<TAB>LIBFILE<TAB>WHAT for each of
# - a name that a tests/lib file assigns or defines and that the driver's
#   $TMP/lib-before.names holds (WHAT: defined before the lib block): a lib
#   file that defines bad, or sets FAIL, PATH or IFS, takes over what the
#   suite already runs on, and _lib_runs_nothing cannot see it, since FAIL=0
#   is a plain assignment;
# - a function that a tests/lib file defines and that another file of
#   _suite_files defines too (WHAT: that file's path): which of the two a
#   later part meets depends on the order they were sourced in.
# and nothing when there is none, so "prints nothing" is the verdict. A lib
# file may set a variable that a later part sets too; that is no clash. The
# files are read from $HERE (the tests directory, the driver's or a copy's) and
# the names from $TMP, and none is run: a lib file is read as text, one
# character at a time, as far as these need: what it assigns at its top level
# (NAME=VALUE words at the start of a statement, outside any { } body) and what
# it defines (name() , name () , function name), through quotes, comments,
# backslash-newline and here-documents. Another file is read for the functions
# it defines only, by the shape of the line, name() or function name at the
# start of a line: a here-document in it that holds such a line is read as a
# definition, which can only add a clash, never hide one. A lib file nothing
# can read, or no lib-before.names beside lib files, is status 2 and a message
# on stderr, not an empty verdict.
_lcl_awk='
function app(c) { if (word == "") wdepth = depth; word = word c }
function addv(nm) { lv[FILENAME SUBSEP nm] = 1 }
function addf(nm) { lf[FILENAME SUBSEP nm] = 1; if (!((nm SUBSEP FILENAME) in fl)) { fl[nm SUBSEP FILENAME] = 1; fn[nm] = fn[nm] SUBSEP FILENAME } }
function boundary() { endword(); stmt_i = 0; chain = 1; lastword = ""; lastidx = -1; pend_fn = 0; stmt_fn = 0 }
function endword(   nm) {
  if (word == "") return
  if (wdepth == 0) {
    if (pend_fn) { addf(word); pend_fn = 0 }
    else if (stmt_i == 0 && word == "function") { pend_fn = 1; stmt_fn = 1 }
    else if (chain && match(word, /^[A-Za-z_][A-Za-z0-9_]*\+?=/)) { nm = word; sub(/\+?=.*/, "", nm); addv(nm) }
    else chain = 0
    lastword = word; lastidx = stmt_i
  }
  stmt_i++; word = ""
}
function scan(line,   n, i, c, rest, cand, first, l) {
  if (hd != "") { l = line; if (hdtab) sub(/^\t+/, "", l); if (l == hd) hd = ""; return }
  n = length(line)
  for (i = 1; i <= n; i++) {
    c = substr(line, i, 1)
    if (esc) { esc = 0; app(c); continue }
    if (q == sq) { app(c); if (c == sq) q = ""; else if (ansi && c == "\\") esc = 1; continue }
    if (q == "\"") { app(c); if (c == "\\") esc = 1; else if (c == "\"") q = ""; continue }
    if (c == "\\") { esc = 1; app(c); continue }
    if (c == sq) { ansi = (word ~ /\$$/); q = sq; app(c); continue }
    if (c == "\"") { q = "\""; app(c); continue }
    if (c == "#" && word == "") break
    if (c == " " || c == "\t") { endword(); continue }
    if (c == ";" || c == "&" || c == "|") { boundary(); continue }
    if (c == "<" && substr(line, i + 1, 1) == "<" && substr(line, i + 2, 1) != "<" && substr(line, i - 1, 1) != "<") {
      rest = substr(line, i + 2)
      if (match(rest, /^-?[ \t]*["\047]?[A-Za-z_0-9]+/)) {
        hdtab = (substr(rest, 1, 1) == "-"); l = substr(rest, 1, RLENGTH)
        sub(/^-?[ \t]*["\047]?/, "", l); hd = l
      }
    }
    if (c == "(" && depth == 0 && substr(line, i + 1) ~ /^[ \t]*\)/) {
      cand = (word != "") ? word : lastword
      first = (word != "") ? (stmt_i == 0) : (lastidx == 0)
      if (cand ~ /^[A-Za-z_][A-Za-z0-9_:.+@%-]*$/ && (first || stmt_fn)) {
        word = ""; pend_fn = 0
        addf(cand); match(substr(line, i + 1), /^[ \t]*\)/); i += RLENGTH
        stmt_i = 1; chain = 0; continue
      }
    }
    if (c == "{" && word == "" && (i == n || substr(line, i + 1, 1) ~ /[ \t]/)) { depth++; stmt_i++; continue }
    if (c == "}" && word == "" && stmt_i == 0 && (i == n || substr(line, i + 1, 1) ~ /[ \t;&|)]/)) {
      if (depth > 0) depth--
      if (depth == 0) boundary()
      continue
    }
    app(c)
  }
  if (q != "") { esc = 0; app("\n"); return }
  if (esc) { esc = 0; word = substr(word, 1, length(word) - 1); endword(); return }
  boundary()
}
function reset() { q = ""; esc = 0; ansi = 0; depth = 0; word = ""; wdepth = 0; hd = ""; hdtab = 0; stmt_fn = 0; stmt_i = 0; chain = 1; lastword = ""; lastidx = -1; pend_fn = 0 }
BEGIN {
  sq = sprintf("%c", 39)
  while ((getline l < b) > 0) before[l] = 1
  close(b)
}
FNR == 1 { islib = (index(FILENAME, d) == 1); reset(); if (islib) libs[FILENAME] = 1 }
islib { scan($0); next }
index($0, "()") || index($0, "function") {
  s = $0; sub(/^[ \t]+/, "", s); nm = ""
  if (s ~ /^function[ \t]+[A-Za-z_]/) { sub(/^function[ \t]+/, "", s); match(s, /^[A-Za-z_][A-Za-z0-9_:.+@%-]*/); nm = substr(s, 1, RLENGTH) }
  else if (match(s, /^[A-Za-z_][A-Za-z0-9_:.+@%-]*[ \t]*\(\)/)) { nm = substr(s, 1, RLENGTH); sub(/[ \t]*\(\)$/, "", nm) }
  if (nm != "" && !((nm SUBSEP FILENAME) in fl)) { fl[nm SUBSEP FILENAME] = 1; fn[nm] = fn[nm] SUBSEP FILENAME }
}
END {
  for (k in lv) { split(k, p, SUBSEP); if (p[2] in before) print p[2] "\t" p[1] "\tdefined before the lib block" }
  for (k in lf) {
    split(k, p, SUBSEP)
    if (p[2] in before) print p[2] "\t" p[1] "\tdefined before the lib block"
    m = split(fn[p[2]], o, SUBSEP)
    for (j = 2; j <= m; j++) if (o[j] != p[1]) print p[2] "\t" p[1] "\t" o[j]
  }
}'
_lib_clashes() {
  local f libs=0 files=()
  while IFS= read -r f; do
    files[${#files[@]}]="$f"
    case "$f" in "$HERE"/lib/*) libs=1 ;; esac
  done < <(_suite_files)
  [ "$libs" -eq 1 ] || return 0
  [ -r "$TMP/lib-before.names" ] || {
    printf '_lib_clashes: no %s/lib-before.names to read the names defined before the lib block from\n' "$TMP" >&2; return 2; }
  LC_ALL=C awk -v d="$HERE/lib/" -v b="$TMP/lib-before.names" "$_lcl_awk" "${files[@]}" | LC_ALL=C sort -u
}
