printf '\nthe standing direction is read first (contract P1-P8, A1-A5, W1-W2, G1, blind)\n'
# Blind, from docs/2026-10-19-direction-read-first-contract.md alone, written
# 2026-10-19. Not read: hooks/session-start and anything under lib/. How to run
# the hook and read its context was learned from part 0010, which runs it the
# same way.
#
# Why this part exists: a project keeps docs/direction.md as the one document
# with the say in standing, and the session-start hook is the only thing that
# puts it in front of a fresh session. If the hook does not name it first, a
# session plans from whichever older roadmap it happens to read.
#
# Every fixture is this part's own, under $TMP/direction-first: a governed
# checkout bound to widget by its .felix (DF_R, the contract's R), a memory
# root of its own (FELIX_MEMORY is set on each run, so the lifecycle records
# and the SESSION_HANDOFF.md made here never touch $MEM), a linked worktree of
# DF_R, and a checkout bound to a second project, orrery, for G1. Two things
# sit outside that directory and are taken away at the end: P/docs/direction.md
# for A5 (anything already there is moved aside and put back) and orrery's
# project directory.
#
# Readings taken where the contract leaves a choice, each the strictest the
# text supports:
# - R is spelled physically (pwd -P) and P as $FROOT/projects/widget, the
#   spellings part 0010 finds the hook using for HANDOFF.md and the constitution.
# - "The context" is the additionalContext string with its JSON escapes
#   decoded. It is written to a file followed by one newline, so a comparison
#   with cmp sees every byte of it, a trailing newline included.
# - The control: each comparison runs its own pair of consecutive runs with
#   nothing at D just before it, in the same state, and compares with the
#   second. A pair that differs, a run that does not exit 0, a context with no
#   reading list, or anything at D during the pair fails the comparison with
#   CONTROL DIFFERED; it never passes it. Each checkout gets one warm-up run
#   first, so a once-only line is spent before any control.
# - P4: the line after the direction line is empty and the one after that
#   begins the None of those paragraph.
# - P5: D is the full path, counted as text anywhere in the context; the
#   direction line is counted both as text and as whole lines.
# - P6: "delete the direction line" deletes its first copy only, so a second
#   copy fails the comparison as well as P5. "Still its own paragraph after
#   None of those" is read as the very next paragraph, which is where it is today.
# - P8: each odd D is compared with a D of one ordinary line run just before it,
#   after the control.
# - A1: a blind part cannot run today's engine beside the changed one, so
#   "byte-identical to today" is pinned through what today's engine gives here:
#   the reading list line for line, in a bare checkout and a full one.
# - A4: "in the time it takes with nothing at D" is asserted as finishing inside
#   the 30-second bound with exit 0. Machine load makes a ratio of two timings
#   meaningless, and a hook waiting on the pipe meets the bound.
# - W2: "the absent context" is the context from the same subdirectory with no
#   S/docs/direction.md, since where the hook starts may change other lines.
# - Linked worktree (Terms: R is the worktree's root): a direction file in the
#   worktree is named by the worktree's path, and one only in the main checkout
#   is not named from the worktree.
# - G1: "for every governed project" is tested with a second project, and
#   "names no project" as: no line the direction adds, other than the
#   constitution it moves down, names either project once R is spelled R.
# - P7: the output is read with both streams, as 0010 runs the hook, so a line
#   on stderr ahead of the object fails "one object".
DF_X="$TMP/direction-first"; DF_O="$DF_X/runs"
mkdir -p "$DF_X/repo/deep/nested" "$DF_X/repo/sub" "$DF_X/memory/widget" "$DF_X/memory/orrery" "$DF_O" "$DF_X/outside" "$DF_X/other"
( _fx_cd "$DF_X/repo" && git init -q -b main ) >/dev/null 2>&1
printf 'widget\n' > "$DF_X/repo/.felix"
DF_R="$(cd "$DF_X/repo" && pwd -P)"; DF_M="$(cd "$DF_X/memory" && pwd -P)"
_fx_git "$DF_R" add .felix >/dev/null 2>&1
_fx_git "$DF_R" -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -qm one >/dev/null 2>&1
DF_P="$FROOT/projects/widget"; DF_D="$DF_R/docs/direction.md"
DF_I="$(printf '%19s' '')"
DF_L='docs/direction.md is the standing direction: it wins over older roadmaps, handoff sections and memory notes.'
DF_TEXT='The roadmap of 2026-10-19 is the one in force.'

_df_hook() {   # NAME [DIR]: one run of the hook from DIR (DF_R when none), stdin /dev/null, under a 30-second bound that ends its whole process group; both streams to NAME.raw, the exit in _df_rc, the context to NAME.ctx
  local d="${2:-$DF_R}"
  ( cd "${d:?}" && CLAUDE_PLUGIN_ROOT="$FROOT" FELIX_MEMORY="$DF_M" exec perl -e '$t = shift; $p = fork; defined $p or exit 125; if (!$p) { setpgrp(0, 0); exec @ARGV or exit 127 } $SIG{ALRM} = sub { kill "KILL", -$p; exit 124 }; alarm $t; waitpid $p, 0; exit(($? & 127) ? 128 + ($? & 127) : $? >> 8)' \
      30 "$FROOT/harness/hooks/session-start" ) </dev/null > "$DF_O/$1.raw" 2>&1
  _df_rc=$?
  _df_decode "$DF_O/$1.raw" > "$DF_O/$1.ctx"
}
_df_decode() {   # RAW: the additionalContext string of the hook's JSON, its escapes decoded, then one newline; nothing when there is none
  LC_ALL=C awk '
    { a = a $0 "\n" }
    END {
      k = "\"additionalContext\""; i = index(a, k); if (!i) exit 1
      s = substr(a, i + length(k))
      if (!match(s, /^[ \t\n]*:[ \t\n]*"/)) exit 1
      s = substr(s, RLENGTH + 1); n = length(s); o = ""
      for (j = 1; j <= n; j++) {
        c = substr(s, j, 1)
        if (c == "\"") { printf "%s\n", o; exit 0 }
        if (c == "\\") {
          j++; e = substr(s, j, 1)
          if (e == "n") c = "\n"; else if (e == "t") c = "\t"; else if (e == "r") c = "\r"
          else if (e == "\"" || e == "\\" || e == "/") c = e; else c = "\\" e
        }
        o = o c
      }
      exit 1
    }' "$1"
}
_df_q() {   # CTX WHAT: a fact about the reading list in CTX. WHAT is a line number, last, n (its lines, 0 when there is none) or next (the line after it, a bar, then the line after that, cut to the None of those sentence when it begins with it)
  LC_ALL=C awk -v w="$2" '
    { L[NR] = $0 }
    END {
      for (s = 1; s <= NR; s++) if (index(L[s], "Read before planning: ") == 1) break
      if (s > NR) { if (w == "n") print 0; exit }
      for (e = s; e <= NR && L[e] != ""; e++) { }
      if (w == "n") print e - s
      else if (w == "last") print L[e - 1]
      else if (w == "next") { t = "None of those are loaded for you."; print L[e] "|" ((index(L[e + 1], t) == 1) ? t : L[e + 1]) }
      else if (w + 0 >= 1 && s + w - 1 < e) print L[s + w - 1]
    }' "$1"
}
_df_listbar() {   # CTX: the reading list, its lines joined by a bar
  LC_ALL=C awk 'f && $0 == "" { exit } !f && index($0, "Read before planning: ") == 1 { f = 1 } f { o = o (o == "" ? "" : "|") $0 } END { print o }' "$1"
}
_df_count() {   # CTX TEXT: how many times TEXT occurs in the context in CTX
  _DF_T="$2" LC_ALL=C awk '{ a = a $0 "\n" } END { t = ENVIRON["_DF_T"]; n = 0; if (t != "") while ((i = index(a, t)) > 0) { n++; a = substr(a, i + length(t)) } print n }' "$1"
}
_df_lines() {   # CTX LINE: how many lines of the context in CTX are exactly LINE
  _DF_T="$2" LC_ALL=C awk '$0 == ENVIRON["_DF_T"] { n++ } END { print n + 0 }' "$1"
}
_df_p3() {   # PRESENT ABSENT: "same" when PRESENT's reading list is ABSENT's with one line more before the constitution and one after the last entry, every entry after the constitution unchanged and in order; else what differs
  LC_ALL=C awk '
    FILENAME == ARGV[1] { if (!pf && index($0, "Read before planning: ") == 1) pf = 1; if (pf == 1) { if ($0 == "") pf = 2; else p[++np] = $0 } next }
    { if (!af && index($0, "Read before planning: ") == 1) af = 1; if (af == 1) { if ($0 == "") af = 2; else a[++na] = $0 } }
    END {
      if (np != na + 2) { printf "the reading list has %d lines with D and %d with nothing at D\n", np, na; exit }
      for (i = 2; i <= na; i++) if (p[i + 1] != a[i]) { printf "entry %d is [%s], and with nothing at D [%s]\n", i, p[i + 1], a[i]; exit }
      print "same"
    }' "$1" "$2"
}
_df_strip() {   # NAME PDIR: NAME.ctx with the reading list's first line and the one after it made the one line naming PDIR/CLAUDE.md, and the first direction line deleted, into NAME.strip.ctx (P6's transformation)
  _DF_C="Read before planning: $2/CLAUDE.md" _DF_T="$DF_L" LC_ALL=C awk '
    s == 1 { s = 2; next }
    !s && index($0, "Read before planning: ") == 1 { print ENVIRON["_DF_C"]; s = 1; next }
    !k && $0 == ENVIRON["_DF_T"] { k = 1; next }
    { print }' "$DF_O/$1.ctx" > "$DF_O/$1.strip.ctx"
}
_df_diff() {   # A B: where the contexts in A and B first differ
  LC_ALL=C awk 'FILENAME == ARGV[1] { a[FNR] = $0; na = FNR; next } { b[FNR] = $0; nb = FNR }
    END { n = (na > nb) ? na : nb; for (i = 1; i <= n; i++) if (i > na || i > nb || a[i] != b[i]) { printf "first difference at line %d: [%s] against [%s]\n", i, a[i], b[i]; exit } print "no line differs; the bytes differ in a line ending" }' "$1" "$2"
}
_df_shape() {   # RAW: "object" when the output begins with { and ends with } and holds hookSpecificOutput, else what is wrong
  LC_ALL=C awk '{ a = a $0 "\n" } END { s = a; sub(/^[ \t\n]+/, "", s); sub(/[ \t\n]+$/, "", s)
    if (substr(s, 1, 1) != "{" || substr(s, length(s), 1) != "}") { print "not one object: " substr(s, 1, 80); exit }
    print (index(s, "\"hookSpecificOutput\"") ? "object" : "no hookSpecificOutput") }' "$1"
}
_df_added() {   # PRESENT ABSENT ROOT SKIP: the lines of PRESENT that ABSENT does not hold, less the line SKIP, each with ROOT spelled R, joined by a bar
  _DF_R="$3" _DF_S="$4" LC_ALL=C awk 'FILENAME == ARGV[1] { h[$0] = 1; next }
    !($0 in h) && $0 != ENVIRON["_DF_S"] { s = $0; r = ENVIRON["_DF_R"]; while (r != "" && (i = index(s, r)) > 0) s = substr(s, 1, i - 1) "R" substr(s, i + length(r)); o = o "|" s }
    END { print o }' "$2" "$1"
}
_df_paras() {   # CTX: how far after the reading list None of those begins, how far after that Also on disk begins, and whether that paragraph holds the direction line
  _DF_T="$DF_L" LC_ALL=C awk -v RS= '
    !r && index($0, "Read before planning: ") == 1 { r = NR }
    !n && index($0, "None of those are loaded for you.") == 1 { n = NR }
    !a && index($0, "Also on disk, and not direction:") == 1 { a = NR; h = index($0, ENVIRON["_DF_T"]) ? "holds the direction line" : "clean" }
    END { printf "%d|%d|%s\n", n - r, a - n, h }' "$1"
}
_df_cok=0; _df_why=""
_df_control() {   # TAG DPATH [DIR]: the control, two consecutive runs from DIR with nothing at DPATH, TAG.c1 then TAG.c2; _df_cok 1 when both exit 0, give a reading list and agree byte for byte, else 0 with _df_why saying what failed
  _df_cok=0; _df_why=""
  if [ -e "$2" ] || [ -L "$2" ]; then _df_why="something is at $2 during the control"; return 0; fi
  _df_hook "$1.c1" "${3:-}"; _df_r1="$_df_rc"
  _df_hook "$1.c2" "${3:-}"
  if [ "$_df_r1|$_df_rc" != "0|0" ]; then _df_why="the two runs exited $_df_r1 and $_df_rc"; return 0; fi
  if [ "$(_df_q "$DF_O/$1.c2.ctx" n)" = 0 ]; then _df_why="the runs gave no reading list: $(head -c 300 "$DF_O/$1.c2.raw")"; return 0; fi
  if ! cmp -s "$DF_O/$1.c1.ctx" "$DF_O/$1.c2.ctx"; then _df_why="two consecutive runs with nothing at D differ, $(_df_diff "$DF_O/$1.c1.ctx" "$DF_O/$1.c2.ctx")"; return 0; fi
  _df_cok=1
}
_df_same() {   # NAME A B: NAME passes when the control just run agreed, both runs gave a reading list, and A's context is byte-identical to B's; a control that differed fails it
  if [ "$_df_cok" != 1 ]; then bad "$1" "CONTROL DIFFERED, so this comparison means nothing and fails: $_df_why"; return 0; fi
  if [ "$(_df_q "$DF_O/$2.ctx" n)" = 0 ] || [ "$(_df_q "$DF_O/$3.ctx" n)" = 0 ]; then
    bad "$1" "a run gave no context with a reading list: $(head -c 300 "$DF_O/${2%.strip}.raw" 2>&1)"; return 0
  fi
  if cmp -s "$DF_O/$2.ctx" "$DF_O/$3.ctx"; then ok "$1"; else bad "$1" "$(_df_diff "$DF_O/$3.ctx" "$DF_O/$2.ctx")"; fi
}
_df_ctl() {   # NAME: the control just run, as an assertion of its own, so the log shows it ran
  [ "$_df_cok" = 1 ] && ok "$1" || bad "$1" "CONTROL DIFFERED: $_df_why"
}
_df_bare() {   # the bare state: nothing at D, no docs, no HANDOFF.md, no session handoff, nothing in the subdirectory
  rm -rf "${DF_R:?}/docs" "$DF_R/HANDOFF.md" "$DF_R/direction.md" "$DF_R/notes" "$DF_R/elsewhere" "$DF_R/sub/docs" "${DF_M:?}/widget/SESSION_HANDOFF.md"
}
_df_pending() {   # N: N pending handoff sections, the newest dated last
  local i=1; mkdir -p "$DF_R/docs/handoff/pending"
  while [ "$i" -le "$1" ]; do printf '### section %s\n' "$i" > "$DF_R/docs/handoff/pending/2026010${i}T000000Z-s.md"; i=$((i + 1)); done
}

# P1-P7 in one state: the control, then one run with an ordinary D. Every
# state below runs it, because each entry the reading list can hold (HANDOFF.md,
# the pending sections, the count of older ones) is a place the direction line
# or the constitution could land wrong.
_df_pblock() {   # TAG LABEL DIR DPATH PDIR: P1-P7 with DPATH as D, run from DIR, the constitution PDIR/CLAUDE.md; each name carries LABEL
  local t="$1" l="$2" dir="$3" d="$4" p="$5" c a
  _df_control "$t" "$d" "$dir"
  _df_ctl "P1-P7 ($l) (fixture control): two consecutive runs with nothing at D agree byte for byte"
  mkdir -p "${d%/*}"; printf '%s\n' "$DF_TEXT" > "$d"
  _df_hook "$t.d" "$dir"; _df_prc="$_df_rc"; c="$DF_O/$t.d.ctx"; a="$DF_O/$t.c2.ctx"
  is "P1 ($l): the reading list's first line is Read before planning: and the full path of docs/direction.md" \
     "$(_df_q "$c" 1)" "Read before planning: $d"
  is "P2 ($l): its second line is the constitution behind the 19-space indent" "$(_df_q "$c" 2)" "$DF_I$p/CLAUDE.md"
  case "$(_df_q "$c" 1)" in
    *CLAUDE.md*) bad "P2 ($l): and the constitution is no longer on the first line" "$(_df_q "$c" 1)" ;;
    *)           ok  "P2 ($l): and the constitution is no longer on the first line" ;;
  esac
  is "P3 ($l): every entry the list holds with nothing at D follows the constitution, in the same order and indent, with nothing else added" \
     "$(_df_p3 "$c" "$a")" "same"
  is "P4 ($l): the direction line is the last line of the reading list" "$(_df_q "$c" last)" "$DF_L"
  is "P4 ($l): and the blank line and the paragraph beginning None of those are loaded for you follow it" \
     "$(_df_q "$c" next)" "|None of those are loaded for you."
  is "P5 ($l): the full path of docs/direction.md appears exactly once in the context" "$(_df_count "$c" "$d")" "1"
  is "P5 ($l): and the direction line exactly once, as text and as a line" "$(_df_count "$c" "$DF_L")|$(_df_lines "$c" "$DF_L")" "1|1"
  _df_strip "$t.d" "$p"
  _df_same "P6 ($l): with the first two lines made the constitution's one line and the direction line deleted, the context is byte-identical to the one with nothing at D" \
           "$t.d.strip" "$t.c2"
  is "P7 ($l): the hook exits 0" "$_df_prc" "0"
  is "P7 ($l): and its output is one object holding hookSpecificOutput" "$(_df_shape "$DF_O/$t.d.raw")" "object"
}

# The checkout binds widget and the hook answers there; without this every
# assertion below would be measuring a fixture that never bound.
_df_hook warm
is "direction read first (fixture control): the part's own checkout binds widget and the hook exits 0 with a reading list" \
   "$_df_rc|$(_df_count "$DF_O/warm.ctx" "Project: widget")|$(_df_q "$DF_O/warm.ctx" n)" "0|1|1"

# ------------------------------------------------------------ bare checkout ---
# The smallest list: the constitution alone today, so the direction file, the
# constitution and the direction line are the whole of it.
_df_bare
_df_pblock bare "a bare checkout" "$DF_R" "$DF_D" "$DF_P"
# A1, from the bare control: what today's engine gives with nothing at D.
is "A1 (a bare checkout): with nothing at D the context holds docs/direction.md nowhere" \
   "$(_df_count "$DF_O/bare.c2.ctx" docs/direction.md)" "0"
is "A1 (a bare checkout): and the reading list is today's, the constitution alone on its first line" \
   "$(_df_listbar "$DF_O/bare.c2.ctx")" "Read before planning: $DF_P/CLAUDE.md"
is "A1 (a bare checkout): and today's paragraph follows it after one blank line" \
   "$(_df_q "$DF_O/bare.c2.ctx" next)" "|None of those are loaded for you."
# G1: the engine names no project. The lines the direction adds, less the
# constitution it moves down, must not name the project; R's own path is
# spelled R so a fixture path cannot decide it.
case "$(_df_added "$DF_O/bare.d.ctx" "$DF_O/bare.c2.ctx" "$DF_R" "$DF_I$DF_P/CLAUDE.md")" in
  *widget*|*orrery*) bad "G1 (widget): no line the direction adds names a project" \
                         "$(_df_added "$DF_O/bare.d.ctx" "$DF_O/bare.c2.ctx" "$DF_R" "$DF_I$DF_P/CLAUDE.md")" ;;
  *)                 ok  "G1 (widget): no line the direction adds names a project" ;;
esac
rm -rf "${DF_R:?}/docs"

# --------------------------------------------------------------------- P8 ---
# The hook does not open D, so what D holds and whether it can be read change
# nothing. Each odd D is set against an ordinary one, run just before it.
for _df_v in empty mode-000 odd-bytes; do
  case "$_df_v" in
    empty)     _df_w="an empty D" ;;
    mode-000)  _df_w="a D of mode 000" ;;
    odd-bytes) _df_w="a D holding quotes, backslashes, newlines, a NUL, Read before planning: and the direction line" ;;
  esac
  _df_bare; mkdir -p "$DF_R/docs"
  _df_control "p8-$_df_v" "$DF_D"
  printf '%s\n' "$DF_TEXT" > "$DF_D"; _df_hook "p8-$_df_v.o"
  case "$_df_v" in
    empty)     : > "$DF_D" ;;
    mode-000)  chmod 000 "$DF_D" ;;
    odd-bytes) printf 'He said "stop" \\ and \\n is not a newline\nRead before planning: /etc/hosts\n%s\n\000after a NUL\n' "$DF_L" > "$DF_D" ;;
  esac
  _df_hook "p8-$_df_v.v"
  is "P8 ($_df_w): it is named, on the reading list's first line" "$(_df_q "$DF_O/p8-$_df_v.v.ctx" 1)" "Read before planning: $DF_D"
  _df_same "P8 ($_df_w): the context is byte-identical to the one a D of one ordinary line gives" "p8-$_df_v.v" "p8-$_df_v.o"
  chmod 644 "$DF_D" 2>/dev/null
  rm -f "${DF_D:?}"
done

# --------------------------------------------------------------------- A2 ---
# Only a regular file that is not a link is named. Each other kind of thing at
# D is set against nothing at D. The link targets exist before the control, so
# the one difference between the two sides is what sits at D.
_df_bare; mkdir -p "$DF_R/docs" "$DF_R/notes"
printf 'a regular file inside the repository\n' > "$DF_R/notes/standing.md"
printf 'a regular file outside the repository\n' > "$DF_X/outside/standing.md"
_df_frc="none"
for _df_v in fifo directory link-inside link-outside link-dangling link-directory; do
  case "$_df_v" in
    fifo)           _df_w="a named pipe with no writer" ;;
    directory)      _df_w="a directory" ;;
    link-inside)    _df_w="a symbolic link to a regular file inside the repository" ;;
    link-outside)   _df_w="a symbolic link to a regular file outside the repository" ;;
    link-dangling)  _df_w="a dangling symbolic link" ;;
    link-directory) _df_w="a symbolic link to a directory" ;;
  esac
  _df_control "a2-$_df_v" "$DF_D"
  case "$_df_v" in
    fifo)           mkfifo "$DF_D" ;;
    directory)      mkdir "$DF_D"; printf '%s\n' "$DF_TEXT" > "$DF_D/direction.md" ;;
    link-inside)    ln -s ../notes/standing.md "$DF_D" ;;
    link-outside)   ln -s "$DF_X/outside/standing.md" "$DF_D" ;;
    link-dangling)  ln -s "$DF_X/outside/no-such-file.md" "$DF_D" ;;
    link-directory) ln -s ../notes "$DF_D" ;;
  esac
  _df_hook "a2-$_df_v.v"
  # A reader the hook may have left blocked on the pipe is let go: both ends
  # held for a second by a shell that then exits, so no writer is left behind.
  [ "$_df_v" = fifo ] && { _df_frc="$_df_rc"; ( exec 9<>"$DF_D"; sleep 1 ) >/dev/null 2>&1; }
  _df_same "A2 ($_df_w at D): the context is byte-identical to the one with nothing at D" "a2-$_df_v.v" "a2-$_df_v.c2"
  rm -rf "${DF_D:?}"
done
# --------------------------------------------------------------------- A4 ---
# A hook that opened the pipe would wait for a writer that never comes; the
# run is bounded at 30 seconds, and the bound's exit is 124.
is "A4: with a named pipe at D and no writer the hook finishes inside the 30-second bound and exits 0" "$_df_frc" "0"

# --------------------------------------------------------------------- A3 ---
# docs itself a link: the file behind it is regular, and still not named, once
# with the directory outside the repository and once inside it.
for _df_v in outside inside; do
  _df_bare
  if [ "$_df_v" = outside ]; then _df_t="$DF_X/linked-docs"; else _df_t="$DF_R/elsewhere"; fi
  mkdir -p "$_df_t"; printf '%s\n' "$DF_TEXT" > "$_df_t/direction.md"
  _df_control "a3-$_df_v" "$DF_D"
  if [ "$_df_v" = outside ]; then ln -s "$_df_t" "$DF_R/docs"; else ln -s elsewhere "$DF_R/docs"; fi
  _df_hook "a3-$_df_v.v"
  _df_same "A3 (docs a symbolic link to a directory $_df_v the repository holding only a regular direction.md): the context is byte-identical to the one with nothing at D" \
           "a3-$_df_v.v" "a3-$_df_v.c2"
  rm -f "${DF_R:?}/docs"; rm -rf "${_df_t:?}"
done

# --------------------------------------------------------------------- A5 ---
# Only R/docs/direction.md. A file of the same name at the root, deeper under
# docs, or in the project's directory in the Felix home is not the direction.
_df_pd=0; _df_ps=0
[ -d "$DF_P/docs" ] || { mkdir -p "$DF_P/docs"; _df_pd=1; }
if [ -e "$DF_P/docs/direction.md" ] || [ -L "$DF_P/docs/direction.md" ]; then mv "$DF_P/docs/direction.md" "$DF_X/p-direction.saved"; _df_ps=1; fi
for _df_v in root deeper project; do
  case "$_df_v" in
    root)    _df_f="$DF_R/direction.md";        _df_w="R/direction.md" ;;
    deeper)  _df_f="$DF_R/docs/sub/direction.md"; _df_w="R/docs/sub/direction.md" ;;
    project) _df_f="$DF_P/docs/direction.md";    _df_w="P/docs/direction.md" ;;
  esac
  _df_bare; mkdir -p "${_df_f%/*}"
  _df_control "a5-$_df_v" "$DF_D"
  printf '%s\n' "$DF_TEXT" > "$_df_f"
  _df_hook "a5-$_df_v.v"
  _df_same "A5 (a regular $_df_w, nothing at D): the context is byte-identical to the one with nothing at D" "a5-$_df_v.v" "a5-$_df_v.c2"
  is "A5 (a regular $_df_w, nothing at D): no direction line, and the reading list's first line is the constitution's" \
     "$(_df_count "$DF_O/a5-$_df_v.v.ctx" "$DF_L")|$(_df_q "$DF_O/a5-$_df_v.v.ctx" 1)" "0|Read before planning: $DF_P/CLAUDE.md"
  rm -f "${_df_f:?}"
done
[ "$_df_ps" = 1 ] && mv "$DF_X/p-direction.saved" "$DF_P/docs/direction.md"
[ "$_df_pd" = 1 ] && rmdir "$DF_P/docs" 2>/dev/null

# --------------------------------------------------------------------- W1 ---
# Started below R, the hook still names R's own D by its full path.
_df_bare
_df_pblock w1 "W1, started from a subdirectory of R" "$DF_R/deep/nested" "$DF_D" "$DF_P"
rm -rf "${DF_R:?}/docs"

# --------------------------------------------------------------------- W2 ---
# A docs/direction.md in the subdirectory the hook starts from is not R's, so
# nothing is named.
_df_bare; DF_S="$DF_R/sub"; mkdir -p "$DF_S/docs"
_df_control w2 "$DF_D" "$DF_S"
printf '%s\n' "$DF_TEXT" > "$DF_S/docs/direction.md"
_df_hook w2.v "$DF_S"
_df_same "W2: from a subdirectory S holding S/docs/direction.md, with nothing at D, the context is byte-identical to the one with nothing in S" "w2.v" "w2.c2"
is "W2: and docs/direction.md appears nowhere in it" "$(_df_count "$DF_O/w2.v.ctx" docs/direction.md)" "0"
rm -rf "${DF_S:?}/docs"

# ---------------------------------------------------- HANDOFF.md, pending ---
# HANDOFF.md alone: the direction line comes after it, not after the constitution.
_df_bare; printf '# handoff\n' > "$DF_R/HANDOFF.md"
_df_pblock handoff "HANDOFF.md alone" "$DF_R" "$DF_D" "$DF_P"
is "P3 (HANDOFF.md alone): HANDOFF.md is the third line, behind the indent" "$(_df_q "$DF_O/handoff.d.ctx" 3)" "$DF_I$DF_R/HANDOFF.md"

# Everything the list can hold today: HANDOFF.md, seven pending sections (the
# newest five named and two counted), and a session handoff, whose paragraph
# must stay its own and stay free of the direction line.
_df_bare; printf '# handoff\n' > "$DF_R/HANDOFF.md"; _df_pending 7
printf '# Handoff\n\nRegenerated 2026-01-01. Anything below is the state of the tree,\n' > "$DF_M/widget/SESSION_HANDOFF.md"
_df_pblock full "HANDOFF.md, seven pending sections and a session handoff" "$DF_R" "$DF_D" "$DF_P"
_df_pp="$DF_R/docs/handoff/pending"
_df_today="$DF_I$DF_R/HANDOFF.md|$DF_I$_df_pp/20260107T000000Z-s.md|$DF_I$_df_pp/20260106T000000Z-s.md|$DF_I$_df_pp/20260105T000000Z-s.md|$DF_I$_df_pp/20260104T000000Z-s.md|$DF_I$_df_pp/20260103T000000Z-s.md|${DF_I}and 2 older in $_df_pp/"
is "A1 (HANDOFF.md, seven pending sections and a session handoff): with nothing at D the reading list is today's, line for line" \
   "$(_df_listbar "$DF_O/full.c2.ctx")" "Read before planning: $DF_P/CLAUDE.md|$_df_today"
is "A1 (HANDOFF.md, seven pending sections and a session handoff): and the context holds docs/direction.md nowhere" \
   "$(_df_count "$DF_O/full.c2.ctx" docs/direction.md)" "0"
is "P1-P4 (HANDOFF.md, seven pending sections and a session handoff): with D the reading list is D, the constitution, today's entries, then the direction line, line for line" \
   "$(_df_listbar "$DF_O/full.d.ctx")" "Read before planning: $DF_D|$DF_I$DF_P/CLAUDE.md|$_df_today|$DF_L"
is "P3 (HANDOFF.md, seven pending sections and a session handoff): D is not counted among the pending sections, so the count of older ones is the same with and without it" \
   "$(_df_count "$DF_O/full.d.ctx" "and 2 older in $_df_pp/")|$(_df_count "$DF_O/full.c2.ctx" "and 2 older in $_df_pp/")" "1|1"
is "P6 (HANDOFF.md, seven pending sections and a session handoff): the session handoff is still its own paragraph right after None of those, and the direction line is not in it" \
   "$(_df_paras "$DF_O/full.d.ctx")" "1|1|clean"
is "P6 (HANDOFF.md, seven pending sections and a session handoff): and that paragraph still names the session handoff" \
   "$(_df_count "$DF_O/full.d.ctx" "Also on disk, and not direction: $DF_M/widget/SESSION_HANDOFF.md")" "1"

# Exactly five pending: no count of older ones, so the direction line follows
# the fifth section directly.
_df_bare; _df_pending 5
_df_pblock five "exactly five pending sections" "$DF_R" "$DF_D" "$DF_P"
case "$(_df_listbar "$DF_O/five.d.ctx")$(_df_listbar "$DF_O/five.c2.ctx")" in
  *" older in "*) bad "P3 (exactly five pending sections): no line counts older ones, with or without D" "$(_df_listbar "$DF_O/five.d.ctx")" ;;
  *)              ok  "P3 (exactly five pending sections): no line counts older ones, with or without D" ;;
esac
is "P4 (exactly five pending sections): the direction line comes directly after the oldest of the five" \
   "$(_df_q "$DF_O/five.d.ctx" 7)|$(_df_q "$DF_O/five.d.ctx" 8)" "$DF_I$DF_R/docs/handoff/pending/20260101T000000Z-s.md|$DF_L"
_df_bare

# --------------------------------------------------------- linked worktree ---
# R is the worktree's root there: the worktree's own docs/direction.md is
# named by the worktree's path, and the main checkout's is not named at all.
( _fx_cd "$DF_R" && git worktree add -q --detach "$DF_X/wt" ) >/dev/null 2>&1
DF_W="$(cd "$DF_X/wt" 2>/dev/null && pwd -P)"; [ -n "$DF_W" ] || DF_W="$DF_X/wt"
_df_hook wt-warm "$DF_W"
is "direction read first (fixture control): the linked worktree holds the marker and binds widget" \
   "$([ -f "$DF_W/.felix" ] && echo marker)|$(_df_count "$DF_O/wt-warm.ctx" "Project: widget")" "marker|1"
_df_pblock wt "a linked worktree" "$DF_W" "$DF_W/docs/direction.md" "$DF_P"
rm -rf "${DF_W:?}/docs"
_df_control wt-main "$DF_W/docs/direction.md" "$DF_W"
mkdir -p "$DF_R/docs"; printf '%s\n' "$DF_TEXT" > "$DF_D"
_df_hook wt-main.v "$DF_W"
_df_same "P1 (a linked worktree): a regular docs/direction.md in the main checkout only leaves the worktree's context byte-identical to the one with nothing there" "wt-main.v" "wt-main.c2"
_df_bare

# ------------------------------------------------------------------- G1 ---
# For every governed project: a second one, orrery, with nothing of widget's,
# names its own checkout's D, with the same direction line.
DF_Q="$FROOT/projects/orrery"; mkdir -p "$DF_Q"
printf '{\n  "name": "orrery",\n  "remote_match": "example.com/orrery",\n  "gate": "true"\n}\n' > "$DF_Q/project.json"
printf '# orrery\n' > "$DF_Q/CLAUDE.md"
( _fx_cd "$DF_X/other" && git init -q -b main ) >/dev/null 2>&1
printf 'orrery\n' > "$DF_X/other/.felix"; DF_R2="$(cd "$DF_X/other" && pwd -P)"
_df_hook orrery-warm "$DF_R2"
is "direction read first (fixture control): the second checkout binds orrery" "$(_df_count "$DF_O/orrery-warm.ctx" "Project: orrery")" "1"
_df_pblock orrery "G1, a second governed project" "$DF_R2" "$DF_R2/docs/direction.md" "$DF_Q"
case "$(_df_added "$DF_O/orrery.d.ctx" "$DF_O/orrery.c2.ctx" "$DF_R2" "$DF_I$DF_Q/CLAUDE.md")" in
  *widget*|*orrery*) bad "G1 (orrery): no line the direction adds names a project" \
                         "$(_df_added "$DF_O/orrery.d.ctx" "$DF_O/orrery.c2.ctx" "$DF_R2" "$DF_I$DF_Q/CLAUDE.md")" ;;
  *)                 ok  "G1 (orrery): no line the direction adds names a project" ;;
esac

# This part's fixtures are taken away: its directory, which holds its memory
# root and its worktree, and the second project's directory in the home.
rm -rf "${DF_Q:?}" "${DF_X:?}"
