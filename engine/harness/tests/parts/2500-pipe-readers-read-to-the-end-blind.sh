# >>> pipe-readers-read-to-the-end
printf '\na pipe'\''s reader reads to the end: _felix_instr_sha, _gt_detail, _gt_class, and a lint for an awk that exits early (contract 2026-11-16, blind)\n'
# Blind, written on 2026-11-16 from docs/2026-11-16-pipe-readers-contract.md (rev 1, PR1 to PR8) alone. The engine
# was read, as it stands on main, for how to call _felix_instr_sha, _gt_detail and _gt_class, for what they print
# today, and for the suite's idiom (tests/run's helpers, part 0960's _spl_scan and its samples, part 0970's size
# check, part 2490's opening); every expected value of the new behaviour comes from the contract's text. A name
# ending (control) holds on the engine the contract was cut from, on purpose; the others are its new behaviour.
#
# Readings, where the contract leaves room:
# - "Under set -o pipefail, with SIGPIPE ignored and at its default" is a child bash that sets pipefail, sources the
#   one library and calls the function, started through perl with $SIG{PIPE} set to IGNORE or DEFAULT, since the
#   suite's own shell may run with it ignored. A large argument is read by the child from a file, never handed on argv.
# - "Writes nothing to standard error" is an empty stderr file, the library's sourcing excepted (sent to /dev/null).
# - PR2's "_gt_class prints hourly and a newline when STATUS is not 3": today it prints hourly with no newline, and
#   PR7 says the bytes do not change, so that case is compared with its trailing newlines dropped. The STATUS 3 words
#   are compared exactly, newline included; _gt_detail exactly, with no newline.
# - _gt_detail's "the last line that holds a non-blank character" over an OUTPUT with no such line is read as nothing.
# - A felix merge block line is laid out as '  %-11s %-22s %s'; its fields are awk's blank-split fields.
# - PR4: the program is also found past a backslash that ends the line inside awk's own arguments (bash reads one
#   command), and the flagged line is still the awk's. A `#` "begins a program line" when it is the first byte of one
#   (the byte after the opening quote is the first of the first line). END is a word at brace depth 0, followed by
#   blanks or newlines and then `{`. Within a line, the pipe search resumes after the closing quote of a program it
#   read, so an awk on a program's closing line is read too. An awk after `;` is not the pipe's reader.
# - PR4's allowance is matched on the flagged line's text, which on the base engine holds the whole quoted phrase.
# Everything this writes is under $TMP/_pra.

PRA="$TMP/_pra"; mkdir -p "$PRA"
_pra_t="$(printf '\t')"
_pra_nl='
'
# DISP LIB FUNC ARG...: FUNC of LIB in a child bash under pipefail with SIGPIPE at DISP (IGNORE or DEFAULT). An
# argument @FILE is FILE's text. stdout to $PRA/so, stderr to $PRA/se, the status in _pra_rc.
_pra_go() {
  _pra_rc=0
  perl -e '$SIG{PIPE} = shift; exec @ARGV; exit 127' "$1" "$BASH" -c '
    set -o pipefail
    . "$1" >/dev/null 2>&1 || exit 125
    f="$2"; shift 2; n=0
    for x in "$@"; do case "$x" in @*) a[n]="$(cat "${x#@}")" ;; *) a[n]="$x" ;; esac; n=$((n + 1)); done
    "$f" "${a[@]}"' _ "$REAL_HARNESS/$2" "$3" "${@:4}" > "$PRA/so" 2> "$PRA/se" || _pra_rc=$?
}
# NAME WANT [trim]: the last _pra_go printed WANT exactly (trim: with trailing newlines dropped), nothing on stderr,
# and returned 0.
_pra_is() {
  if [ "${3:-}" = trim ]; then _pra_o="$(cat "$PRA/so")"; else _pra_o="$(cat "$PRA/so"; printf x)"; _pra_o="${_pra_o%x}"; fi
  _pra_e="$(sed -n 1p "$PRA/se")"
  if [ "$_pra_o" = "$2" ] && [ ! -s "$PRA/se" ] && [ "$_pra_rc" = 0 ]; then ok "$1"
  else bad "$1" "stdout [$_pra_o] want [$2]; stderr [$_pra_e]; status $_pra_rc (want empty and 0)"; fi
}
# FILE FIRST LAST LINE: FILE is FIRST (lines, may be empty), 6,000 copies of LINE (awk printf, one %05d), then LAST.
_pra_big() {
  _PRA_F="$2" _PRA_L="$3" _PRA_B="$4" awk 'BEGIN { f = ENVIRON["_PRA_F"]; l = ENVIRON["_PRA_L"]; b = ENVIRON["_PRA_B"]
    if (f != "") print f
    for (i = 1; i <= 6000; i++) printf b "\n", i
    if (l != "") print l }' > "$1"
}
_pra_size() { wc -c < "$1" | tr -d ' '; }

# ---------------------------------------------------------------- PR1 ----
_pra_id=0123456789abcdef0123456789abcdef01234567
_pra_id2=fedcba9876543210fedcba9876543210fedcba98
_pra_idt=eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
_pra_hit="100644 blob $_pra_id${_pra_t}pra/target.sh"
_pra_row="100644 blob 00000000000000000000000000000000%08d${_pra_t}pra/bulk/file.sh"
_pra_big "$PRA/first.ls" "$_pra_hit" "100644 blob $_pra_id2${_pra_t}pra/target.sh" "$_pra_row"
_pra_big "$PRA/tree.ls" "040000 tree $_pra_idt${_pra_t}pra/target.sh$_pra_nl$_pra_hit" "" "$_pra_row"
_pra_big "$PRA/last.ls" "" "$_pra_hit" "$_pra_row"
_pra_big "$PRA/none.ls" "" "" "$_pra_row"
_pra_short=""
for _pra_f in first tree last none; do
  [ "$(_pra_size "$PRA/$_pra_f.ls")" -ge 262144 ] || _pra_short="$_pra_short $_pra_f.ls ($(_pra_size "$PRA/$_pra_f.ls") bytes)"
done
[ "$(sed -n 1p "$PRA/first.ls")" = "$_pra_hit" ] || _pra_short="$_pra_short first.ls does not start with the blob asked for"
[ "$(sed -n 2p "$PRA/tree.ls")" = "$_pra_hit" ] || _pra_short="$_pra_short tree.ls does not hold the blob on its second line"
[ "$(tail -n 1 "$PRA/last.ls")" = "$_pra_hit" ] || _pra_short="$_pra_short last.ls does not end with the blob asked for"
[ -z "$_pra_short" ] \
  && ok  "every _felix_instr_sha listing below is past 256 KB, the early ones with the blob asked for first" \
  || bad "every _felix_instr_sha listing below is past 256 KB, the early ones with the blob asked for first" \
         "too small or out of order, so a pass below would prove nothing:$_pra_short"
for _pra_d in IGNORE DEFAULT; do
  case "$_pra_d" in IGNORE) _pra_w="with SIGPIPE ignored" ;; *) _pra_w="with SIGPIPE at its default" ;; esac
  _pra_go "$_pra_d" lib/instrument.sh _felix_instr_sha "@$PRA/first.ls" pra/target.sh
  _pra_is "_felix_instr_sha over a listing past 256 KB whose first line is the blob prints its id and a newline, writes nothing on stderr and returns 0, $_pra_w" "$_pra_id$_pra_nl"
  _pra_go "$_pra_d" lib/instrument.sh _felix_instr_sha "@$PRA/tree.ls" pra/target.sh
  _pra_is "_felix_instr_sha over a listing past 256 KB that opens with a tree at the path and then the blob prints the blob's id, quietly and with status 0, $_pra_w" "$_pra_id$_pra_nl"
  _pra_go "$_pra_d" lib/instrument.sh _felix_instr_sha "@$PRA/last.ls" pra/target.sh
  _pra_is "_felix_instr_sha over a listing past 256 KB whose last line is the blob prints its id, quietly and with status 0, $_pra_w (control)" "$_pra_id$_pra_nl"
  _pra_go "$_pra_d" lib/instrument.sh _felix_instr_sha "@$PRA/none.ls" pra/target.sh
  _pra_is "_felix_instr_sha over a listing past 256 KB that does not hold the path prints nothing, quietly and with status 0, $_pra_w (control)" ""
done
_pra_go IGNORE lib/instrument.sh _felix_instr_sha "040000 tree $_pra_idt${_pra_t}pra/target.sh
160000 commit $_pra_id2${_pra_t}pra/target.sh
$_pra_hit" pra/target.sh
_pra_is "_felix_instr_sha passes over a tree and a commit at the path for the blob after them (control)" "$_pra_id$_pra_nl"
_pra_go IGNORE lib/instrument.sh _felix_instr_sha "040000 tree $_pra_idt${_pra_t}pra/target.sh" pra/target.sh
_pra_is "_felix_instr_sha prints nothing when the path is there only as another type (control)" ""
_pra_go IGNORE lib/instrument.sh _felix_instr_sha "100644 blob $_pra_idt${_pra_t}pra/target.sh.bak
100644 blob $_pra_id2${_pra_t}x/pra/target.sh
$_pra_hit
100644 blob $_pra_idt${_pra_t}pra/target.sh" pra/target.sh
_pra_is "_felix_instr_sha takes only a path that is exactly the one asked for, and the first such blob (control)" "$_pra_id$_pra_nl"

# ---------------------------------------------------------------- PR2 ----
_pra_blk="  not-green   tests                  the gate receipt is not green on this head"
_pra_big "$PRA/detail.out" "$_pra_blk" "  escape      write                  a later blocker${_pra_nl}closing words" \
  "felix merge output line %05d, read past the deciding line"
_pra_rcpt="  commission  receipt                the commission receipt predates the change"
_pra_big "$PRA/class.out" "not merging$_pra_nl$_pra_nl$_pra_rcpt$_pra_nl" \
  "not merging$_pra_nl$_pra_nl  escape      write                  notes/x.md: outside the tree$_pra_nl${_pra_nl}closing words" \
  "  escape      write                  notes/file-%05d.md: outside the tree"
_pra_short=""
for _pra_f in detail class; do
  [ "$(_pra_size "$PRA/$_pra_f.out")" -ge 262144 ] || _pra_short="$_pra_short $_pra_f.out ($(_pra_size "$PRA/$_pra_f.out") bytes)"
done
[ "$(sed -n 1p "$PRA/detail.out")" = "$_pra_blk" ] || _pra_short="$_pra_short detail.out does not open with its two-space line"
[ "$(sed -n 1p "$PRA/class.out")" = "not merging" ] && [ "$(sed -n 3p "$PRA/class.out")" = "$_pra_rcpt" ] \
  && [ -z "$(sed -n 4p "$PRA/class.out")" ] || _pra_short="$_pra_short class.out does not open with not merging and its one-line block"
[ -z "$_pra_short" ] \
  && ok  "the _gt_detail and _gt_class outputs below are past 256 KB with their deciding lines first" \
  || bad "the _gt_detail and _gt_class outputs below are past 256 KB with their deciding lines first" \
         "too small or out of order, so a pass below would prove nothing:$_pra_short"
for _pra_d in IGNORE DEFAULT; do
  case "$_pra_d" in IGNORE) _pra_w="with SIGPIPE ignored" ;; *) _pra_w="with SIGPIPE at its default" ;; esac
  _pra_go "$_pra_d" lib/green-tick.sh _gt_detail "@$PRA/detail.out"
  _pra_is "_gt_detail over felix merge output past 256 KB whose first line is a blocker prints that line with no newline, writes nothing on stderr and returns 0, $_pra_w" "$_pra_blk"
  _pra_go "$_pra_d" lib/green-install.sh _gt_class 3 "@$PRA/class.out"
  _pra_is "_gt_class 3 over felix merge output past 256 KB that opens with a receipt-only block prints receipt and a newline, writes nothing on stderr and returns 0, $_pra_w" "receipt$_pra_nl"
done
_pra_go IGNORE lib/green-tick.sh _gt_detail "a
 one space is not two
  the first blocker
b
  a second blocker"
_pra_is "_gt_detail prints the first line that begins with two spaces (control)" "  the first blocker"
_pra_go IGNORE lib/green-tick.sh _gt_detail "first words
last words
$_pra_t
"
_pra_is "_gt_detail with no two-space line prints the last line that holds a non-blank character (control)" "last words"
_pra_go IGNORE lib/green-tick.sh _gt_detail ""
_pra_is "_gt_detail of an empty output prints nothing (control)" ""

# STATUS WANT OUTPUT NAME: _gt_class STATUS OUTPUT prints WANT and a newline.
_pra_cls() { _pra_go IGNORE lib/green-install.sh _gt_class "$1" "$3"; _pra_is "$4" "$2$_pra_nl"; }
_pra_cl="  commission  receipt                stale"
_pra_nt="  not-green   tests                  red"
_pra_es="  escape      write                  notes/x.md: outside the tree"
_pra_bp="  base        provider               unknown"
_pra_go IGNORE lib/green-install.sh _gt_class 1 "not merging

$_pra_cl

closing"
_pra_is "_gt_class prints hourly when STATUS is 1, whatever the block (control)" "hourly" trim
_pra_go IGNORE lib/green-install.sh _gt_class 4 "not merging

$_pra_es"
_pra_is "_gt_class prints hourly when STATUS is 4, a blocker in the block notwithstanding (control)" "hourly" trim
_pra_cls 3 receipt "not merging

$_pra_cl

closing" "_gt_class prints receipt for a block of a commission receipt line alone (control)"
_pra_cls 3 hourly "not merging

$_pra_nt
$_pra_cl

closing" "_gt_class prints hourly for a block whose not-green line names tests (control)"
_pra_cls 3 hourly "not merging

  unverified  tests                  red

closing" "_gt_class prints hourly for a block whose unverified line names tests (control)"
_pra_cls 3 receipt "not merging

  not-green   gate                   red

closing" "_gt_class reads a not-green line that does not name tests as setting neither h nor b (control)"
_pra_cls 3 final "not merging

$_pra_nt
$_pra_es

closing" "_gt_class prints final for a block that holds any other blocker (control)"
_pra_cls 3 hourly "not merging

$_pra_bp

closing" "_gt_class prints hourly for a block of a base provider line alone (control)"
_pra_cls 3 final "not merging

$_pra_bp
$_pra_cl

closing" "_gt_class prints final for a base provider line beside another line (control)"
_pra_cls 3 receipt "not merging

$_pra_cl

$_pra_es
$_pra_bp" "_gt_class does not read the lines after the block's closing empty line (control)"
_pra_cls 3 receipt "not merging

$_pra_cl

not merging

$_pra_es

closing" "_gt_class does not read a second not merging and its block (control)"
_pra_cls 3 receipt "not merging
$_pra_cl

$_pra_es" "_gt_class reads a block that starts on the line after not merging when that line is not empty (control)"
_pra_cls 3 final "not merging


$_pra_cl" "_gt_class prints final for an empty block, and reads nothing after it (control)"
_pra_cls 3 final "  not merging
$_pra_cl" "_gt_class prints final when no line is exactly not merging (control)"

# ---------------------------------------------------------------- PR4 ----
# _pra_scan FILE...: FILE:LINE for each line holding an awk that a pipe hands its output to and whose single-quoted
# program holds exit outside any END action. The pipe rules are part 0960's: a | that is not half of ||, carried from
# the end of a code line (before a comment, or a backslash) onto the next code line, a line may start with |, comment
# lines skipped; the words that may stand before the reader are 0960's. Then options -F, -v (argument attached or
# the next word, quoted or not) and --; -f, a program in a variable or in double quotes are not read.
_pra_scan() {
  LC_ALL=C awk '
    function skipword(s,   i, n, c, k) {
      n = length(s); i = 1
      while (i <= n) {
        c = substr(s, i, 1)
        if (c == " " || c == "\t") break
        if (c == "\\") { i += 2; continue }
        if (c == "\047") { k = index(substr(s, i + 1), "\047"); if (!k) return ""; i += k + 1; continue }
        if (c == "\"") { i++; while (i <= n && substr(s, i, 1) != "\"") { if (substr(s, i, 1) == "\\") i++; i++ }; i++; continue }
        i++
      }
      return substr(s, i)
    }
    # Blanks off the front, and on to the next line past a backslash that ends this one.
    function lead(s) {
      sub(/^[ \t]+/, "", s)
      while (s ~ /^\\[ \t]*$/ && LN < N) { LN++; s = L[LN]; sub(/^[ \t]+/, "", s) }
      return s
    }
    # exit as a word outside double-quoted strings, comments and the braces of an END action.
    function exits(p,   n, i, c, pc, d, e, pe, w) {
      n = length(p); d = 0; e = 0; pe = 0; i = 1
      while (i <= n) {
        c = substr(p, i, 1); pc = (i > 1) ? substr(p, i - 1, 1) : "\n"
        if (c == "\"") {
          i++
          while (i <= n) { c = substr(p, i, 1); if (c == "\\") { i += 2; continue }; if (c == "\"" || c == "\n") break; i++ }
          i++; pe = 0; continue
        }
        if (c == "#" && (pc == "\n" || pc == " " || pc == "\t")) { while (i <= n && substr(p, i, 1) != "\n") i++; continue }
        if (c ~ /[A-Za-z_]/) {
          w = ""
          while (i <= n && substr(p, i, 1) ~ /[A-Za-z0-9_]/) { w = w substr(p, i, 1); i++ }
          if (w == "exit" && !e) return 1
          pe = (w == "END" && d == 0); continue
        }
        if (c == "{") { d++; if (pe && d == 1) e = 1; pe = 0 }
        else if (c == "}") { if (d > 0) d--; if (d == 0) e = 0; pe = 0 }
        else if (c !~ /[ \t\n]/) pe = 0
        i++
      }
      return 0
    }
    # s follows a pipe on line LN. 0: no awk; 1: an awk not flagged; 2: flagged, at line FL. AFTER is the shell
    # text after it on line LN, which may have moved on.
    function tryawk(s,   j, p) {
      sub(/^[ \t]+/, "", s)
      while (s ~ /^(command|env|nice|if|!)[ \t]/ || s ~ /^timeout[ \t]+[0-9.]+[smhd]?[ \t]/ ||
             s ~ /^[A-Za-z_][A-Za-z0-9_]*=[^ \t]*[ \t]/) {
        if (s ~ /^timeout[ \t]/) sub(/^timeout[ \t]+/, "", s)
        sub(/^[^ \t]*[ \t]+/, "", s)
      }
      sub(/^\\/, "", s)
      if (s !~ /^[gmn]?awk([ \t]|$)/) return 0
      FL = LN; sub(/^[gmn]?awk/, "", s)
      while (1) {
        s = lead(s)
        if (s ~ /^--([ \t]|$)/) { s = lead(substr(s, 3)); break }
        if (s ~ /^-f/) { AFTER = s; return 1 }
        if (s ~ /^-[Fv]/) { s = substr(s, 3); if (s == "" || s ~ /^[ \t]/) s = lead(s); s = skipword(s); continue }
        break
      }
      if (substr(s, 1, 1) != "\047") { AFTER = s; return 1 }
      s = substr(s, 2); p = ""
      while (!(j = index(s, "\047"))) {
        if (LN >= N) { AFTER = ""; return exits(p s) ? 2 : 1 }
        p = p s "\n"; LN++; s = L[LN]
      }
      AFTER = substr(s, j + 1)
      return exits(p substr(s, 1, j - 1)) ? 2 : 1
    }
    function scan(   i, k, rest, last, first, j, r, at, t, open) {
      split("", F); open = 0; i = 1
      while (i <= N) {
        if (L[i] ~ /^[ \t]*(#|$)/) { i++; continue }
        LN = i; rest = L[i]; last = rest; first = open
        while (1) {
          if (!first) {
            while ((j = index(rest, "|")) > 0 && substr(rest, j + 1, 1) == "|") rest = substr(rest, j + 2)
            if (!j) break
            rest = substr(rest, j + 1)
          }
          first = 0; at = LN
          r = tryawk(rest)
          if (r == 2) F[FL] = 1
          if (r > 0) { rest = AFTER; if (LN != at) last = AFTER }
        }
        t = last; sub(/[ \t]*(\\[ \t]*)?$/, "", t)
        open = (t ~ /(^|[^|])[|]([ \t]+#.*)?$/)
        i = LN + 1
      }
      for (k = 1; k <= N; k++) if (k in F) print NAME ":" k
    }
    FNR == 1 && NR > 1 { scan() }
    FNR == 1 { NAME = FILENAME; N = 0; split("", L) }
    { L[++N] = $0 }
    END { if (N) scan() }
  ' "$@"
}
mkdir -p "$PRA/s"
_pra_s() { cat > "$PRA/s/sample"; }
_pra_flags() { ( cd "$PRA/s" && _pra_scan sample ) | awk -F: '{ printf "%s%s", s, $NF; s = " " }'; }

_pra_s <<'PRA_S1'
x | awk '{ print; exit }'
x | LC_ALL=C awk '/a/ { print; exit }'
x |awk 'NR == 2 { exit }'
PRA_S1
is "the awk lint flags a plain pipe into an awk whose main rule exits, with or without a VAR=value prefix (sample)" "$(_pra_flags)" "1 2 3"
_pra_s <<'PRA_S2'
x | command awk '{ exit }'
x | env LC_ALL=C awk '{ exit }'
x | nice awk '{ exit }'
x | timeout 5 awk '{ exit }'
x | \awk '{ exit }'
x | if awk '{ exit }'; then :; fi
x | ! awk '{ exit }'
PRA_S2
is "the awk lint flags an awk reached through command, env, nice, timeout N, if, ! or a leading backslash (sample)" "$(_pra_flags)" "1 2 3 4 5 6 7"
_pra_s <<'PRA_S3'
x | awk -F: '{ exit }'
x | awk -F : '{ exit }'
x | awk -F'\t' '{ exit }'
x | awk -F '\t' '{ exit }'
x | awk -F"$t" '{ exit }'
x | awk -F "$t" -- '{ exit }'
PRA_S3
is "the awk lint reads past -F with its argument attached, apart and quoted to the program (sample)" "$(_pra_flags)" "1 2 3 4 5 6"
_pra_s <<'PRA_S4'
x | awk -v p="$2" '{ exit }'
x | awk -vp=1 '{ exit }'
x | awk -v 'p=a b' -F'\t' '{ exit }'
x | awk -- '{ exit }'
PRA_S4
is "the awk lint reads past -v with its argument apart and attached, and past -- (sample)" "$(_pra_flags)" "1 2 3 4"
_pra_s <<'PRA_S5'
x | gawk '{ exit }'
x | mawk '{ exit }'
x | nawk '{ exit }'
PRA_S5
is "the awk lint flags gawk, mawk and nawk (sample)" "$(_pra_flags)" "1 2 3"
_pra_s <<'PRA_S6'
x | awk '
  /a/ { n++ }
  /b/ { exit }
'
y | LC_ALL=C awk -v p="$2" '{ t = index($0, "\t"); if (!t) next
    if (m[2] == "blob") { print m[3]; exit } }'
z | awk -F: \
  '{ exit }'
PRA_S6
is "the awk lint flags a program over several lines on the line that holds the awk (sample)" "$(_pra_flags)" "1 5 7"
_pra_s <<'PRA_S7'
x |
  awk '{ exit }'
x | \
  awk '{ exit }'
x |   # why it is piped

  awk '{ exit }'
x \
| awk '{ exit }'
PRA_S7
is "the awk lint flags an awk after a pipe that ends a line, before a backslash or a comment, and one on a line that starts with the pipe (sample)" "$(_pra_flags)" "2 4 7 9"
_pra_s <<'PRA_S8'
x | awk '$1 == "a" { exit 1 }'
x | awk '/a/ { f = 1; exit !f }'
x | awk 'BEGIN { exit }'
x | awk 'function q(s) { if (s) exit 2; return 0 } { q($1) }'
PRA_S8
is "the awk lint flags exit N and exit !f in a main rule, an exit in BEGIN and one in a function body (sample)" "$(_pra_flags)" "1 2 3 4"
_pra_s <<'PRA_S9'
x | awk '/a/ { n++; exit } END { print n }'
x | awk 'END { print n }
  /b/ { exit }'
done 3< "$T/oi" | awk -v st="$T/oib" 'substr($0, 1, 1) == "\001" { b++; next } ++n > 2000 { p = 1; exit } { print }
  END { printf "%d %d\n", b, p > st }' > "$T/oi1"
x | awk '{ print }
  ' | awk '{ exit }'
PRA_S9
is "the awk lint flags a main-rule exit beside an END action, and an awk on the closing line of another's program (sample)" "$(_pra_flags)" "1 2 4 7"
_pra_s <<'PRA_S10'
x | awk '{ n++ } END { print n; exit }'
x | awk '{ n++ }
  END {
    if (n) { print n; exit 0 }
    for (i = 1; i <= n; i++) { if (i > 3) { exit 1 } }
    exit 2
  }'
x | awk 'END{exit !n}'
PRA_S10
is "the awk lint leaves an exit inside an END action, a multi-line END with braces nested inside it among them (sample)" "$(_pra_flags)" ""
_pra_s <<'PRA_S11'
awk '{ exit }' file
a || awk '{ exit }'
a ||
  awk '{ exit }'
x | grep y; awk '{ exit }' file
PRA_S11
is "the awk lint leaves an awk no pipe feeds, an || and an || that ends a line (sample)" "$(_pra_flags)" ""
_pra_s <<'PRA_S12'
x | awk '{ exitcode = 1; do_exit = 2 }'
x | awk '{ print "do not exit here" }'
x | awk '{ print "say \"exit\" now" }'
x | awk '{ n++ } # exit early would break the pipe'
x | awk '
# exit at the first match
{ n++ }
    # exit, said an indented comment
END { print n }'
PRA_S12
is "the awk lint does not count exitcode, do_exit, an exit in a double-quoted string or one in an awk comment (sample)" "$(_pra_flags)" ""
_pra_s <<'PRA_S13'
x | awk -f exit.awk
x | awk -F: -f prog.awk -v exit=1
x | awk "$prog"
x | awk $prog
x | awk "{ exit }"
# x | awk '{ exit }'
  # y | awk 'BEGIN { exit }'
PRA_S13
is "the awk lint does not read a program in a file, in a variable or in double quotes, nor a comment line (sample)" "$(_pra_flags)" ""

# The allowance: PR3's one site, by file and by the text of its flagged line, with the reason beside it.
_pra_allow="lib/inventory-orphans.sh${_pra_t}++n > 2000 { p = 1; exit }${_pra_t}the cost bound on the loop of find over ignored directories: find and /usr/bin/printf write the pipe, their errors go to a file read only for two messages, and the loop's status is not read (PR3)"
_pra_na=0; _pra_bad=""
while IFS="$_pra_t" read -r _pra_af _pra_at _pra_why; do
  [ -n "$_pra_af" ] || continue
  _pra_na=$((_pra_na + 1)); [ -n "$_pra_at" ] && [ -n "$_pra_why" ] || _pra_bad="$_pra_bad [$_pra_af]"
done <<< "$_pra_allow"
[ "$_pra_na" = 1 ] && [ -z "$_pra_bad" ] \
  && ok  "the awk lint's allowance list holds exactly one entry, each with its text and its reason" \
  || bad "the awk lint's allowance list holds exactly one entry, each with its text and its reason" \
         "$_pra_na entries; without a text or a reason:$_pra_bad"

_pra_sites="$( cd "$REAL_HARNESS" 2>/dev/null && [ -f felix ] \
                 || { printf 'no-engine-to-scan-at:%s\n' "$REAL_HARNESS"; exit 0; }
               set --
               for _pra_x in felix lib/*.sh hooks/* bin/* tests/lib/* tests/run; do [ -f "$_pra_x" ] && set -- "$@" "$_pra_x"; done
               _pra_scan "$@" || printf 'the-scan-itself-failed:%s\n' "$?" )"
_pra_left=""; _pra_used=""
while IFS= read -r _pra_x; do
  [ -n "$_pra_x" ] || continue
  _pra_f="${_pra_x%:*}"; _pra_n="${_pra_x##*:}"; _pra_ok=0
  case "$_pra_n" in *[!0-9]*|"") _pra_text="" ;; *) _pra_text="$(sed -n "${_pra_n}p" "$REAL_HARNESS/$_pra_f" 2>/dev/null)" ;; esac
  while IFS="$_pra_t" read -r _pra_af _pra_at _pra_why; do
    [ -n "$_pra_af" ] && [ "$_pra_f" = "$_pra_af" ] || continue
    case "$_pra_text" in *"$_pra_at"*) _pra_ok=1; _pra_used="$_pra_used$_pra_nl$_pra_af$_pra_t$_pra_at" ;; esac
  done <<< "$_pra_allow"
  [ "$_pra_ok" = 1 ] || _pra_left="$_pra_left $_pra_x"
done <<< "$_pra_sites"
_pra_stale=""
while IFS="$_pra_t" read -r _pra_af _pra_at _pra_why; do
  [ -n "$_pra_af" ] || continue
  case "$_pra_used$_pra_nl" in *"$_pra_nl$_pra_af$_pra_t$_pra_at$_pra_nl"*) ;; *) _pra_stale="$_pra_stale [$_pra_af: $_pra_at]" ;; esac
done <<< "$_pra_allow"
[ -z "$_pra_stale" ] \
  && ok  "every allowance of the awk lint matches a line the scan of the harness flags" \
  || bad "every allowance of the awk lint matches a line the scan of the harness flags" \
         "stale, so a moved or fixed site left its allowance behind:$_pra_stale"
[ -z "$_pra_left" ] \
  && ok  "no awk in the engine or the suite's library reads a pipe and exits outside its END action, the allowance aside" \
  || bad "no awk in the engine or the suite's library reads a pipe and exits outside its END action, the allowance aside" \
         "a writer can be left on a broken pipe at:$_pra_left"
unset -f _pra_go _pra_is _pra_big _pra_size _pra_cls _pra_scan _pra_s _pra_flags
# <<< pipe-readers-read-to-the-end
