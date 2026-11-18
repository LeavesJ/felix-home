# >>> pipe-readers-lint
printf '\na pipe'\''s reader reads to the end, the lint: no awk a pipe feeds exits outside its END action (contract 2026-11-16, blind)\n'
# Blind. Part 2500's first author wrote this lint on 2026-11-16 from docs/2026-11-16-pipe-readers-contract.md rev 1
# alone; a second blind author amended it the same day from rev 3 (PR3, PR4 and the Revisions section) and moved
# it here whole from part 2500, every assertion name kept. The second author read the contract, the two parts, and
# the engine only as an export of main from before the fix: tests/run's helpers and the lines the scan names. Every
# sample's expected flags come from the contract's text. A name ending (sample) pins the matcher on written-out
# text, so it holds on any engine; the scan of the harness is the one new-behaviour assertion that fails on main
# (32 lines there, the allowance's among them; rev 3 says 31, but bin/authority-engine:157, an awk named through
# "$_AE_AWK" whose exit is two lines below it, is a site by PR4's text too). The allowance's two assertions hold on
# main, whose site it names.
#
# Readings, where the contract leaves room:
# - The program is also found past a backslash that ends the line inside awk's own arguments, and the flagged line
#   is still the awk's. A `#` "begins a program line" when it is the first byte of one (the byte after the opening
#   quote is the first of the first line). END is a word at brace depth 0, followed by blanks or newlines and then
#   `{`. Within a line, the pipe search resumes after the closing quote of a program it read, so an awk on a
#   program's closing line is read too. An awk after `;` is not the pipe's reader.
# - A variable that names an awk is $NAME or ${NAME}, bare or in double quotes, NAME ending in AWK, as a whole word.
# - A VAR=value prefix's value is one shell word: single quotes, double quotes (with \ escapes and $( ) inside) and
#   $( ) (with its own quotes and parentheses) are read to their close on the line.
# - "The start of a pattern" is the program's start, a newline, or a `}` that closes a rule on the same line; after
#   any other operator than the contract lists, a `/` is division. A bracket expression may hold [:class:], and a
#   regex literal ends at a newline if no `/` closes it. A regex literal's text is searched for exit as a word.
# - The shell's quote state that decides a trailing `#` is read within the line; a quote a line leaves open hides
#   the rest of it. Text after a program's closing quote on a later line is read the same way.
# - The allowance is matched on the flagged line's text, which on the base engine holds the whole quoted phrase.
# Everything this writes is under $TMP/_prl.

PRL="$TMP/_prl"; mkdir -p "$PRL/s"
_pra_t="$(printf '\t')"
_pra_nl='
'
# _pra_scan FILE...: FILE:LINE for each line holding an awk that a pipe hands its output to and whose single-quoted
# program holds exit outside any END action. The pipe rules are part 0960's: a | that is not half of ||, carried from
# the end of a code line (before a comment, or a backslash) onto the next code line, a line may start with |, comment
# lines skipped; a shell line's code ends at a # after a blank outside quotes. Before the reader: 0960's words and
# VAR=value prefixes; the reader is awk, gawk, mawk, nawk or a variable whose name ends in AWK. Then options -F, -v
# (argument attached or the next word, quoted or not) and --; -f, a program in a variable or in double quotes are
# not read.
_pra_scan() {
  LC_ALL=C awk '
    # wend: the index past the shell word that starts at i in s; 0 when a quote or $( ) it opens does not close.
    function wend(s, i,   n, c, k) {
      n = length(s)
      while (i <= n) {
        c = substr(s, i, 1)
        if (c == " " || c == "\t") break
        if (c == "\\") { i += 2; continue }
        if (c == "\047") { k = index(substr(s, i + 1), "\047"); if (!k) return 0; i += k + 1; continue }
        if (c == "\"") { i = dq(s, i + 1); if (!i) return 0; continue }
        if (c == "$" && substr(s, i + 1, 1) == "(") { i = cs(s, i + 2); if (!i) return 0; continue }
        i++
      }
      return i
    }
    # dq: from inside a double-quoted string at i, the index past its closing quote; cs: the same for $( and its ).
    function dq(s, i,   n, c) {
      n = length(s)
      while (i <= n) {
        c = substr(s, i, 1)
        if (c == "\\") { i += 2; continue }
        if (c == "\"") return i + 1
        if (c == "$" && substr(s, i + 1, 1) == "(") { i = cs(s, i + 2); if (!i) return 0; continue }
        i++
      }
      return 0
    }
    function cs(s, i,   n, c, k) {
      n = length(s)
      while (i <= n) {
        c = substr(s, i, 1)
        if (c == "\\") { i += 2; continue }
        if (c == "\047") { k = index(substr(s, i + 1), "\047"); if (!k) return 0; i += k + 1; continue }
        if (c == "\"") { i = dq(s, i + 1); if (!i) return 0; continue }
        if (c == "(") { i = cs(s, i + 1); if (!i) return 0; continue }
        if (c == ")") return i + 1
        i++
      }
      return 0
    }
    function skipword(s,   k) { k = wend(s, 1); return k ? substr(s, k) : "" }
    # code: s up to a # that follows a blank outside quotes, the trailing comment that is not code.
    function code(s,   n, i, c, q) {
      n = length(s); q = ""
      for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if (q == "\047") { if (c == "\047") q = ""; continue }
        if (c == "\\") { i++; continue }
        if (q == "\"") { if (c == "\"") q = ""; continue }
        if (c == "\047" || c == "\"") { q = c; continue }
        if (c == "#" && i > 1 && substr(s, i - 1, 1) ~ /[ \t]/) return substr(s, 1, i - 1)
      }
      return s
    }
    # Blanks off the front, and on to the next line past a backslash that ends this one.
    function lead(s) {
      sub(/^[ \t]+/, "", s)
      while (s ~ /^\\[ \t]*$/ && LN < N) { LN++; s = L[LN]; sub(/^[ \t]+/, "", s) }
      return s
    }
    # brk: p[i] is the [ of a bracket expression; the index past its closing ].
    function brk(p, i,   n, c, k) {
      n = length(p); i++
      if (substr(p, i, 1) == "^") i++
      if (substr(p, i, 1) == "]") i++
      while (i <= n) {
        c = substr(p, i, 1)
        if (c == "\n") return i
        if (c == "[" && substr(p, i + 1, 1) ~ /[:.=]/) {
          k = index(substr(p, i + 2), substr(p, i + 1, 1) "]"); if (k) { i += k + 3; continue }
        }
        if (c == "\\") { i += 2; continue }
        if (c == "]") return i + 1
        i++
      }
      return i
    }
    # exit as a word outside double-quoted strings, comments and the braces of an END action; a regex literal,
    # opened by a / where an operand is expected (op), is code whose " opens no string.
    function exits(p,   n, i, c, pc, d, e, pe, w, op, b) {
      n = length(p); d = 0; e = 0; pe = 0; op = 1; i = 1
      while (i <= n) {
        c = substr(p, i, 1); pc = (i > 1) ? substr(p, i - 1, 1) : "\n"
        if (c == "\"") {
          i++
          while (i <= n) { c = substr(p, i, 1); if (c == "\\") { i += 2; continue }; if (c == "\"" || c == "\n") break; i++ }
          i++; pe = 0; op = 0; continue
        }
        if (c == "#" && (pc == "\n" || pc == " " || pc == "\t")) { while (i <= n && substr(p, i, 1) != "\n") i++; continue }
        if (c == "/" && op) {
          b = ""; i++
          while (i <= n) {
            c = substr(p, i, 1)
            if (c == "\\") { b = b substr(p, i, 2); i += 2; continue }
            if (c == "[") { w = brk(p, i); b = b substr(p, i, w - i); i = w; continue }
            if (c == "/" || c == "\n") break
            b = b c; i++
          }
          if (c == "/") i++
          if (!e && b ~ /(^|[^A-Za-z0-9_])exit([^A-Za-z0-9_]|$)/) return 1
          pe = 0; op = 0; continue
        }
        if (c ~ /[A-Za-z_]/) {
          w = ""
          while (i <= n && substr(p, i, 1) ~ /[A-Za-z0-9_]/) { w = w substr(p, i, 1); i++ }
          if (w == "exit" && !e) return 1
          pe = (w == "END" && d == 0); op = 0; continue
        }
        if (c == "{") { d++; if (pe && d == 1) e = 1; pe = 0; op = 1 }
        else if (c == "}") { if (d > 0) d--; if (d == 0) e = 0; pe = 0; op = (d == 0) }
        else if (c == "\n") op = 1
        else if (c == "&" || c == "|") { op = (pc == c); pe = 0 }
        else if (c ~ /[(,!~;]/) { op = 1; pe = 0 }
        else if (c !~ /[ \t]/) { op = 0; pe = 0 }
        i++
      }
      return 0
    }
    # s follows a pipe on line LN. 0: no awk; 1: an awk not flagged; 2: flagged, at line FL. AFTER is the shell
    # text after it on line LN, which may have moved on.
    function tryawk(s,   j, p, k) {
      sub(/^[ \t]+/, "", s)
      while (1) {
        if (s ~ /^(command|env|nice|if|!)[ \t]/) sub(/^[^ \t]*[ \t]+/, "", s)
        else if (s ~ /^timeout[ \t]+[0-9.]+[smhd]?[ \t]/) { sub(/^timeout[ \t]+/, "", s); sub(/^[^ \t]*[ \t]+/, "", s) }
        else if (s ~ /^[A-Za-z_][A-Za-z0-9_]*=/) {
          k = wend(s, 1); if (!k || substr(s, k, 1) !~ /[ \t]/) return 0
          s = substr(s, k); sub(/^[ \t]+/, "", s)
        } else break
      }
      sub(/^\\/, "", s)
      if (s ~ /^[gmn]?awk([ \t]|$)/) sub(/^[gmn]?awk/, "", s)
      else if (match(s, /^("[$]([A-Za-z_][A-Za-z0-9_]*)?AWK"|"[$][{]([A-Za-z_][A-Za-z0-9_]*)?AWK[}]"|[$]([A-Za-z_][A-Za-z0-9_]*)?AWK|[$][{]([A-Za-z_][A-Za-z0-9_]*)?AWK[}])([ \t]|$)/)) s = substr(s, RLENGTH + 1)
      else return 0
      FL = LN
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
        LN = i; rest = code(L[i]); last = rest; first = open
        while (1) {
          if (!first) {
            while ((j = index(rest, "|")) > 0 && substr(rest, j + 1, 1) == "|") rest = substr(rest, j + 2)
            if (!j) break
            rest = substr(rest, j + 1)
          }
          first = 0; at = LN
          r = tryawk(rest)
          if (r == 2) F[FL] = 1
          if (r > 0) { if (LN != at) { rest = code(AFTER); last = rest } else rest = AFTER }
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
_pra_s() { cat > "$PRL/s/sample"; }
_pra_flags() { ( cd "$PRL/s" && _pra_scan sample ) | awk -F: '{ printf "%s%s", s, $NF; s = " " }'; }

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
# Rev 3: an awk named through a variable whose name ends in AWK.
_pra_s <<'PRA_S14'
x | "$_AE_AWK" '/^ [0-9]+: / && $0 !~ / deny / { print; exit }'
x | $AWK '{ exit }'
x | "${X_AWK}" '{ exit }'
x | ${AWK} -F: '{ exit }'
x | LC_ALL=C "$NAWK" -v p=1 '{ exit }'
PRA_S14
is "the awk lint flags an awk named through a variable whose name ends in AWK, bare, braced or quoted (sample)" "$(_pra_flags)" "1 2 3 4 5"
_pra_s <<'PRA_S15'
x | "$AWKWARD" '{ exit }'
x | $AWKWARD '{ exit }'
x | "$AWK_BIN" '{ exit }'
x | "$_AE_SED" '{ exit }'
x | "$_AE_AWK" "$prog"
x | "$X_AWK" -f p.awk
x | awk "$_FI_HOST_AWK"'{ exit }'
x | "$_AE_AWK" '{ n++ } END { exit }'
PRA_S15
is "the awk lint leaves a variable whose name does not end in AWK, and an AWK variable whose program is not read or exits only in END (sample)" "$(_pra_flags)" ""
# Rev 3: a VAR=value prefix whose value is quoted and holds blanks or $( ).
_pra_s <<'PRA_S16'
x | X="a b" awk '{ exit }'
x | P="$1" N="$t $(r) " awk '{ exit }'
x | M='a b' LC_ALL=C awk '{ exit }'
x | G=" $(id -G "$1" 2>/dev/null) " LC_ALL=C awk '{ exit }'
x | A="x\" y" B=$(r "s t") awk '{ exit }'
x | Q="a b" "$_AE_AWK" '{ exit }'
PRA_S16
is "the awk lint reads past VAR=value prefixes whose quoted values hold blanks, an escaped quote or a \$( ), several in a row (sample)" "$(_pra_flags)" "1 2 3 4 5 6"
_pra_s <<'PRA_S17'
x | X="a b" sort
x | X="b awk '{ exit }'" sort
x | OLD="(after $x comes $y)" NEW="(a b)" LC_ALL=C awk '{ n++ } END { print n; exit }'
x | X="a b" awk "$prog"
PRA_S17
is "the awk lint leaves a quoted prefix before another reader, an awk inside a prefix's value, and a prefixed awk that exits only in END (sample)" "$(_pra_flags)" ""
# Rev 3: a regex literal where awk expects an operand; a " inside it opens no string.
_pra_s <<'PRA_S18'
x | awk '/"/ { print; exit }'
x | awk '$0 ~ /"/ { exit }'
x | awk '!/"/ { exit }'
x | awk 'NR > 1 && /"/ { exit }'
x | awk 'NR > 9 || /"/ { exit }'
x | awk '(/"/) { exit }'
x | awk '/a/,/"/ { exit }'
x | awk '{ n = split($0, a, /"/); exit }'
x | awk '{ /"/ && m++; exit }'
x | awk '{ n++; /"/ && m++; exit }'
x | awk '{ n++ }
/"/ { exit }'
x | awk '{ n++ } /"/ { exit }'
x | awk '/[/"]/ { exit }'
x | awk '/a\/"/ { exit }'
x | awk '/[[:alpha:]/"]/ { exit }'
x | awk '/exit/ { print }'
PRA_S18
is "the awk lint reads a regex literal where an operand is expected as code, so an exit after a double quote inside one counts (sample)" "$(_pra_flags)" "1 2 3 4 5 6 7 8 9 10 11 13 14 15 16 17"
_pra_s <<'PRA_S19'
x | awk '/"/ { print "say exit" }'
x | awk '/[/"]/ { print "exit" }'
x | awk '/a\/"/ { print "exit" }'
x | awk '{ print n / 2, "a/b exit" }'
x | awk '{ r = a / 2; s = "x/"; print "exit" }'
x | awk '$1 ~ /x/ { print "do not exit" }'
x | awk '{ n++ } END { if (/"/) exit }'
PRA_S19
is "the awk lint leaves an exit in a string after a regex that holds a quote, a slash or a bracket, and reads a / after an operand as division (sample)" "$(_pra_flags)" ""
# Rev 3: a shell # that follows a blank outside quotes ends the line's code.
_pra_s <<'PRA_S20'
x | sort   # then | awk '{ exit }'
x | grep a # | awk 'BEGIN { exit }'
x | grep a  # an "| awk '{ exit }'" in a comment
x | grep a  # ends with a pipe |
  awk '{ exit }' file
PRA_S20
is "the awk lint leaves a pipe into an awk written in a trailing shell comment, and a pipe that only a comment ends with (sample)" "$(_pra_flags)" ""
_pra_s <<'PRA_S21'
x | awk '{ exit }'   # a trailing comment
x | awk -F# '{ exit }'
echo "a # b" | awk '{ exit }'
echo 'a # b' | awk '{ exit }'
x | awk '{ n++ } # an awk comment, not a shell one
  { exit }'
x | sort # a | b
x | awk '{ print }
  ' | sort   # | awk '{ exit }'
PRA_S21
is "the awk lint reads code before a trailing comment and a # inside quotes or a word or an awk program as code (sample)" "$(_pra_flags)" "1 2 3 4 5"

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
unset -f _pra_scan _pra_s _pra_flags
# <<< pipe-readers-lint
