# The table validator: one definition of a row, and the shapes it refuses.
#
# The engine is tab-separated the whole way down and had no shared reader. On
# 2026-09-22 there were 507 sites parsing rows in 52 files, in about a dozen
# idioms, and they did not agree about what a row is. Two readers of one deny
# table disagreed about its last rule: the enforcing path reads the file with
# `while read ... done < file`, which drops a final line that has no newline,
# and the escape check reads it with grep, which keeps it. Remove the final
# newline and the rule stops refusing anything while the check that guards the
# table sees an identical set of lines.
#
# docs/2026-09-19-direction-decisions.md §1 chose rows first, in bash: a
# validator before a reader, a table declaring every table's columns, and a
# gate check that fails on a table nobody declared. This is the validator.
# Nothing here is migrated onto it yet. An existing reader moves when a row
# forces it, and the kill test in the suite is what makes that move safe.
#
# THE ROW. A data row is any line, including bytes after the last newline,
# that does not match `^[[:space:]]*(#|$)` in the C locale. Its cells are the
# exact tab-separated substrings, awk -F'\t' semantics: an empty cell is kept,
# nothing is trimmed, a CR is not stripped. That is byte-identical to the 42
# sites that filter with `grep -vE '^[[:space:]]*(#|$)'` (or `\s`) and to the
# awk scans in obligations.sh and exceptions.sh, the largest family.
#
# THE REFUSALS. Each is a shape on which two reader families already in the
# engine read different rows, or put a cell boundary in different places, so
# on a table this accepts every family reads the same rows split at the same
# tabs:
#
#   indented-comment   whitespace before `#`. The `IFS=$'\t' read` + `case
#                      ''|'#'*` loops read a space-indented comment as a row;
#                      the grep family skips it; the raw `case` loops read a
#                      tab-indented one as a row.
#   whitespace-line    a line of only whitespace that is not empty. The raw
#                      `case` loops and qualify's awk read it as data.
#   nonascii-lead      a line whose first byte after ASCII whitespace is not
#                      ASCII. None of those readers pins a locale, and in a
#                      UTF-8 one some of them take a Unicode space before `#`
#                      for whitespace and some do not, so what kind of line it
#                      is depends on the machine. Every first cell the engine
#                      writes is ASCII.
#   carriage-return    a CR anywhere. The tab-IFS reads keep it in the last
#                      cell, and exceptions.sh alone strips it.
#   no-final-newline   the last byte of a non-empty file is not a newline.
#                      The `done < file` loops drop that line and grep, awk
#                      and cut keep it; and the appenders that do not check
#                      glue their next row onto it.
#   nul-byte           a NUL anywhere. grep calls such a file binary and prints
#                      no rows at all, while a read loop reads on.
#   encoding           a line that is not UTF-8 as RFC 3629 has it: no
#                      overlong form, no surrogate, nothing past U+10FFFF. In a
#                      UTF-8 locale grep drops such a line and some cut and sed
#                      builds stop there, while the read loops go on; and macOS
#                      awk aborts on a code point past U+10FFFF and reads no
#                      rows at all, which is why this is checked here, byte by
#                      byte, and not by the platform's iconv, which lets those
#                      through.
#   empty-cell         a leading tab, a trailing tab, or two tabs together.
#                      `IFS=$'\t' read` collapses a run of tabs, so every
#                      later column moves left one; awk and cut keep the empty
#                      cell where it is.
#   cells              fewer cells than the table's required columns, or more
#                      than all of them. `cut -fN` passes a line with no tab
#                      through whole for every N.
#   symlink            the table is a link. What the escape check compares is
#                      the link's text, and what a reader reads is its target.
#
# What this does NOT promise. A reader that assigns fewer variables than a
# table has columns folds the rest into its last one — a four-variable read of
# a six-column risk row puts channel and confine inside the reason — and the
# engine does that on purpose in places that only want the first columns.
# Accepted means the cells are where the tabs say; which cells a given reader
# asks for is that reader's business, and an inventory of reader arities waits
# until readers move onto this one.
#
# NOT refused: trailing spaces inside a cell (a governed project's risk table
# carries load-bearing ones in a regex), a `#` in a later cell, a truly empty
# line, non-ASCII text that is UTF-8 and not at the start of a line. Nothing
# here rewrites or normalises a file: the commissioning policy is a hash of
# these files' bytes, and a validator that tidied them would change what it
# certified.
#
# THE SCHEMA. Columns come from one row in templates/schemas.tsv, never from a
# table's own header comment: header comments in use write their tabs as the
# literal text `<TAB>`, and one table has two header forms.
#
# Bash 3.2, and awk and grep as BSD, BWK, mawk and GNU share them. No function
# here writes anything. Every file is handed to awk and tail on standard input,
# never as an operand: awk takes an operand shaped like `k=v` for an assignment
# and `-` for standard input, and tail takes one starting with `-` for an
# option, and each of those skipped the file it was given without a word.

FELIX_TABLE_SKIP='^[[:space:]]*(#|$)'

# A whole line of well-formed UTF-8, as bytes in the C locale: ASCII except NUL
# (refused on its own), then the two- to four-byte forms of RFC 3629 §4. No
# interval expressions, which not every awk here has.
FELIX_TABLE_UTF8="$(printf '^([\001-\177]|[\302-\337][\200-\277]|\340[\240-\277][\200-\277]|[\341-\354\356\357][\200-\277][\200-\277]|\355[\200-\237][\200-\277]|\360[\220-\277][\200-\277][\200-\277]|[\361-\363][\200-\277][\200-\277][\200-\277]|\364[\200-\217][\200-\277][\200-\277])*$')"

# The rows of a table, byte for byte, one per line. A final row with no newline
# comes out with one, as grep and awk print it.
felix_table_rows() {
  [ -f "$1" ] || return 0
  LC_ALL=C awk -v skip="$FELIX_TABLE_SKIP" '$0 !~ skip' < "$1"
}

# The schema row for a table, looked up by basename: the key a table's readers
# and FELIX_ESCAPE_TABLES already use. Empty when there is none.
felix_table_schema() {
  local schemas="$1" table="$2"
  [ -f "$schemas" ] || return 0
  felix_table_rows "$schemas" | T="$table" LC_ALL=C awk -F'\t' '$1 == ENVIRON["T"] { print; exit }'
}

# Required and total columns of a schema row, as "<required> <total>". Counted
# by awk, never by a shell loop over the list: a column written `name?` is a
# glob, and an unquoted expansion would match it against whatever files sit in
# the directory the caller happens to be in.
_felix_table_arity() {
  printf '%s\n' "$1" | LC_ALL=C cut -f3 | LC_ALL=C awk '{ for (i = 1; i <= NF; i++) { t++; if ($i !~ /\?$/) r++ } } END { printf "%d %d\n", r, t }'
}

# Everything wrong with one file as an instance of one table. One line per
# refusal: <file>:<line> TAB <reason> TAB <detail>, with `-` for the line of a
# refusal about the whole file.
#
#   exit 0  accepted
#   exit 1  refused
#   exit 2  cannot examine: no such file, or no schema row for the table.
#           Never read as accepted; a table nobody declared is not a clean one.
felix_table_check() {
  local schemas="$1" file="$2" table="${3:-}"
  [ -n "$table" ] || table="${file##*/}"
  if [ -L "$file" ]; then
    printf '%s:-\tsymlink\ta link, so the escape check compares its text and a reader reads its target\n' "$file"; return 1
  fi
  if [ ! -f "$file" ] || [ ! -r "$file" ]; then
    printf '%s:-\tcannot-examine\tno readable file\n' "$file"; return 2
  fi
  local row; row="$(felix_table_schema "$schemas" "$table")"
  if [ -z "$row" ]; then
    printf '%s:-\tno-schema\t%s has no row in %s\n' "$file" "$table" "${schemas##*/}"; return 2
  fi
  local req tot empty
  read -r req tot <<EOF
$(_felix_table_arity "$row")
EOF
  empty="$(printf '%s\n' "$row" | LC_ALL=C cut -f4)"

  # One pass classifies every line and applies every per-line refusal. The last
  # line it prints is the row count, which the shell splits off.
  local out
  out="$(LC_ALL=C awk -F'\t' -v f="$file" -v req="$req" -v tot="$tot" \
      -v cols="$(printf '%s\n' "$row" | cut -f3)" -v hi="$(printf '[\200-\377]')" -v u8="$FELIX_TABLE_UTF8" '
    $0 !~ u8 { printf "%s:%d\tencoding\ta line that is not UTF-8, which grep drops in a UTF-8 locale and macOS awk cannot read\n", f, NR }
    /\r/ { printf "%s:%d\tcarriage-return\ta CR byte, which a tab-IFS read keeps in the last cell\n", f, NR }
    $0 ~ ("^[ \t\v\f\r]*" hi) { printf "%s:%d\tnonascii-lead\ta line that starts with a non-ASCII byte, which is whitespace to some locales and not others\n", f, NR }
    /^[[:space:]]+#/ { printf "%s:%d\tindented-comment\twhitespace before #, which the read-and-case loops take for a row\n", f, NR; next }
    /^#/ { next }
    /^[[:space:]]+$/ { printf "%s:%d\twhitespace-line\ta line of only whitespace, which the raw case loops take for a row\n", f, NR; next }
    /^$/ { next }
    {
      rows++
      if ($0 ~ /^\t/ || $0 ~ /\t$/ || $0 ~ /\t\t/)
        printf "%s:%d\tempty-cell\ta leading, trailing or doubled tab, which moves every later column under an IFS read\n", f, NR
      if (NF < req || NF > tot)
        printf "%s:%d\tcells\t%d cell(s); %s declares %s\n", f, NR, NF, (req == tot ? "exactly " req : req " to " tot), cols
    }
    END { printf "\t%d\n", rows + 0 }
  ' < "$file")"
  local rows="${out##*	}"
  out="${out%	*}"
  out="${out%
}"

  # File-level shapes one awk pass cannot see: it reads a final line with no
  # newline as a line like any other, and stops or truncates at a NUL
  # depending on its build.
  local more=""
  # The last byte, read as a number: a command substitution drops a newline and
  # a NUL alike, so a file ending in a NUL looked like one ending in a newline.
  if [ -s "$file" ] && [ "$(tail -c 1 < "$file" | od -An -tx1 | tr -d ' \n')" != "0a" ]; then
    more="$more$(printf '%s:-\tno-final-newline\tthe last line has no newline, and the done-< loops drop it while grep and awk keep it' "$file")
"
  fi
  if [ "$(LC_ALL=C tr -d '\000' < "$file" | wc -c)" -ne "$(wc -c < "$file")" ]; then
    more="$more$(printf '%s:-\tnul-byte\ta NUL byte, which makes grep treat the file as binary and print no rows' "$file")
"
  fi
  if [ "${rows:-0}" -eq 0 ] && [ "$empty" = "refused" ]; then
    more="$more$(printf '%s:-\tempty\tno rows, and %s declares that emptiness is never legitimate' "$file" "$table")
"
  fi
  out="${out:+$out
}${more%
}"
  out="${out%
}"

  [ -n "$out" ] || return 0
  printf '%s\n' "$out"
  return 1
}

# What is wrong with schemas.tsv's own rows, beyond what its row in itself
# already says. <line> TAB <reason> TAB <detail>. The generic check covers cell
# counts and shapes; these are the values only a schema row can get wrong.
felix_table_schema_malformed() {
  local schemas="$1"
  [ -f "$schemas" ] || return 0
  LC_ALL=C awk -F'\t' -v skip="$FELIX_TABLE_SKIP" '
    $0 ~ skip { next }
    {
      if (NF != 4)
        printf "%d\tcells\t%d cell(s); a schema row has four: table lives columns empty\n", NR, NF
      if ($3 !~ /^[^ ]+( [^ ]+)*$/)
        printf "%d\tcolumns\tnames separated by single spaces, with none before or after\n", NR
      if ($1 !~ /^[A-Za-z0-9._-]+$/)
        printf "%d\ttable\t\"%s\" is not a basename\n", NR, $1
      if ($1 in seen)
        printf "%d\tduplicate\t%s already has a row at line %d\n", NR, $1, seen[$1]
      else seen[$1] = NR
      if ($2 != "tree" && $2 != "memory")
        printf "%d\tlives\t\"%s\" is neither tree nor memory\n", NR, $2
      if ($4 != "refused" && $4 != "allowed")
        printf "%d\tempty\t\"%s\" is neither refused nor allowed\n", NR, $4
      n = split($3, c, " "); opt = 0; req = 0
      for (i = 1; i <= n; i++) {
        if (c[i] !~ /^[a-z][a-z0-9_-]*\??$/)
          printf "%d\tcolumns\t\"%s\" is not a column name\n", NR, c[i]
        if (c[i] ~ /\?$/) opt = 1
        else { req++; if (opt) printf "%d\tcolumns\t\"%s\" is required after an optional column\n", NR, c[i] }
      }
      # One column, or at least two that every row must carry. A row allowed
      # to stop after its first cell is a line with no tab, and cut -f2 hands
      # such a line back whole as its second column.
      if (n == 0)
        printf "%d\tcolumns\tno columns\n", NR
      else if (n > 1 && req < 2)
        printf "%d\tcolumns\tfewer than two required columns, so a row may have no tab\n", NR
    }
  ' < "$schemas"
}

# PATTERNS (audit b16, C076). A deny.tsv pattern is run by `[[ =~ ]]` in the
# pre-tool hook, a risk.tsv pattern by `LC_ALL=C grep -qE` in escape.sh and
# classify.sh. Each skips a row whose pattern it cannot compile and says
# nothing, so a row can sit in a table and never fire. Two refusals, made by one
# function that schema-check and felix doctor share and the hook never calls:
#
#   uncompilable  the engine that runs the pattern gives status 2 for it, as
#                 `(?i)rm -rf` and `git push (` do; for grep, also a pattern
#                 that opens with `-`, which grep reads as an option.
#   unportable    the pattern holds an unescaped \s \S \d \D \w \W \b \B \y \<
#                 or \>, or [[:<:]] or [[:>:]]: unescaped means an even number
#                 of backslashes before it, none included, so `a\\d` is clean.
#                 BSD and GNU engines read these differently, so the row fires
#                 on one machine and not the other. This is the list audit.sh
#                 refuses for --verify. What every engine rejects is not on it:
#                 that is uncompilable.
#
# A row is a line that is not a comment or blank, with a first cell and a
# pattern. Pattern is column 2 of a deny.tsv, column 3 of a risk.tsv.
#
#   felix_table_pattern_check <file> bash|grep
#
# prints one line per problem, in file order, tab-separated: line number, kind,
# first cell, the escapes found (`-` for none), why, pattern. The pattern is
# last since it may end in a blank. Returns 2, printing nothing, for a file it
# cannot read or an engine it does not know. Locale C throughout, as the hook
# compiles: a pattern holding a byte that is not UTF-8 must not read two ways.
felix_table_pattern_check() {
  local file="$1" engine="$2" col ln esc cell pat why rc rows all=0 LC_ALL=C
  local -a gargs=()
  [ -f "$file" ] && [ -r "$file" ] || return 2
  case "$engine" in bash) col=2 ;; grep) col=3 ;; *) return 2 ;; esac
  rows="$(LC_ALL=C awk -F'\t' -v col="$col" -v skip="$FELIX_TABLE_SKIP" '
    function escapes(p,   i, n, d, o) {
      n = length(p); o = ""
      for (i = 1; i <= n; i++) {
        if (substr(p, i, 1) != "\\") continue
        i++; d = substr(p, i, 1)
        if (d != "" && index("sSdDwWbBy<>", d) && index(" " o " ", " \\" d " ") == 0) o = o (o == "" ? "" : " ") "\\" d
      }
      if (index(p, "[[:<:]]")) o = o (o == "" ? "" : " ") "[[:<:]]"
      if (index(p, "[[:>:]]")) o = o (o == "" ? "" : " ") "[[:>:]]"
      return (o == "" ? "-" : o)
    }
    $0 ~ skip { next }
    $1 != "" && $col != "" { printf "%d\t%s\t%s\t%s\n", NR, escapes($col), $1, $col }
  ' < "$file")" || return 2
  [ -n "$rows" ] || return 0
  # One grep over every pattern says whether any needs a closer look: a grep
  # compiles all of its patterns before it reads, so status 2 is any of them.
  if [ "$engine" = grep ]; then
    while IFS=$'\t' read -r ln esc cell pat; do
      gargs+=(-e "$pat")
    done <<EOF
$rows
EOF
    LC_ALL=C grep -qE "${gargs[@]}" <<<"" 2>/dev/null; [ "$?" -eq 2 ] || all=1
  fi
  while IFS=$'\t' read -r ln esc cell pat; do
    rc=0
    if [ "$engine" = bash ]; then
      [[ "" =~ $pat ]] || rc=$?
    else
      case "$pat" in
        -*) rc=2 ;;
        *)  [ "$all" -eq 1 ] || { LC_ALL=C grep -qE "$pat" <<<"" 2>/dev/null; rc=$?; } ;;
      esac
    fi
    if [ "$rc" -eq 2 ]; then
      case "$engine$pat" in
        bash*)  why="bash's =~ cannot compile this pattern, so the hook skips the row and it refuses nothing" ;;
        grep-*) why="grep reads a pattern that opens with - as an option, so the runners skip the row and it matches nothing" ;;
        *)      why="grep -E cannot compile this pattern, so the runners skip the row and it matches nothing" ;;
      esac
      printf '%s\tuncompilable\t%s\t-\t%s\t%s\n' "$ln" "$cell" "$why" "$pat"
    fi
    if [ "$esc" != - ]; then
      why="holds $esc, which is not POSIX ERE and reads differently on macOS and Linux; spell it "'[[:space:]], [[:digit:]], [[:alnum:]_] or ([^[:alnum:]_]|$)'
      printf '%s\tunportable\t%s\t%s\t%s\t%s\n' "$ln" "$cell" "$esc" "$why" "$pat"
    fi
  done <<EOF
$rows
EOF
  return 0
}

# What felix doctor says of a project's deny table beyond the rows too broad to
# enforce (lib/deny.sh): the patterns the hook skips or reads differently by
# machine, and the rows for a tool Felix reads no field of. Each under a header
# of its own, and none printed when there is nothing to say. A row for a tool
# outside the list is matched against file_path (_felix_deny_field), so it
# refuses nothing when that tool has none, and the name is case-sensitive.
felix_table_deny_report() {
  local proj="$1" f="$1/deny.tsv" recs unk ln kind cell esc why pat nl=$'\n' bad="" port=""
  recs="$(felix_table_pattern_check "$f" bash)" \
    || { printf '\nthe deny patterns could not be checked: %s could not be examined\n' "$f"; recs=""; }
  while IFS=$'\t' read -r ln kind cell esc why pat; do
    [ -n "$kind" ] || continue
    if [ "$kind" = uncompilable ]; then bad="$bad$(printf '  %-14s %s' "$cell" "$pat")$nl"
    else port="$port$(printf '  %-14s %s   (%s)' "$cell" "$pat" "$esc")$nl"; fi
  done <<EOF
$recs
EOF
  if [ -n "$bad" ]; then
    printf '\ndeny rules whose pattern does not compile\n\n%s' "$bad"
    printf '\nBash cannot compile each of these, and the hook skips a row it cannot\n'
    printf 'compile without saying so, so the row refuses nothing.\n'
    printf '\nFix the pattern in %s, or drop the row.\n' "$f"
  fi
  if [ -n "$port" ]; then
    printf '\ndeny rules that read differently on macOS and Linux\n\n%s' "$port"
    printf '\nEach of these holds an escape that is not POSIX ERE. The regex engine on a\n'
    printf 'Mac and the one on Linux read it differently, so the row can refuse on one\n'
    printf 'machine and nothing on the other. Spell it [[:space:]], [[:digit:]],\n'
    printf '[[:alnum:]_] or ([^[:alnum:]_]|$) in %s.\n' "$f"
  fi
  unk="$(felix_table_rows "$f" | LC_ALL=C awk -F'\t' '
    $1 != "" && $2 != "" && $1 !~ /^mcp__/ && $1 !~ /^(Bash|Monitor|Edit|MultiEdit|Write|Read|NotebookEdit|WebFetch)$/ { printf "%s\t%s\n", $1, $2 }')"
  if [ -n "$unk" ]; then
    printf '\ndeny rules naming a tool Felix reads no field of\n\n'
    printf '%s\n' "$unk" | while IFS=$'\t' read -r cell pat; do printf '  %-14s %s\n' "$cell" "$pat"; done
    printf '\nFelix reads a field for Bash, Monitor, Edit, MultiEdit, Write, Read,\n'
    printf 'NotebookEdit, WebFetch and every mcp__ tool. A row for any other tool is\n'
    printf 'matched against its file_path, so it refuses nothing when that tool has\n'
    printf 'none. Tool names are case-sensitive: bash is not Bash.\n'
  fi
  return 0
}
