# Denial.
#
# The first thing Felix can stop rather than mention. Every other hook it wires
# injects text a session is free to ignore: SessionStart mounts doctrine,
# UserPromptSubmit names a play, Stop asks a question at the end. PreToolUse
# decides, and it is the only one that does.
#
# Felix skipped it while the charter said "governance layer", which only
# reports. The case it exists for is a project running a stale copy of its own
# gate all day and reporting green: Felix could see it and stop nobody.
#
# Narrow on purpose, in three ways:
#
#   - Table-driven, per project. The engine names no rule of its own, the same
#     way it names no project. What a repo refuses is the repo's decision.
#   - A rule matches the one field naming what the tool acts on, never the
#     payload and never file content. See _felix_deny_field.
#   - Fails open on everything. A missing table, an unparseable payload, a bad
#     regex, an unresolvable project: all allow. The cost of a false deny is a
#     person fighting their own tools and switching the harness off; the cost of
#     a missed deny is the status quo.
#
# It used to be narrow in a fourth way, a mistake: the matcher in hooks.json
# bound Bash alone, so no rule saw Read, Edit or Write, where the ledger showed
# real sessions spending most of their calls. It stood in for blast-radius
# control, since a bad regex reaching Edit looks like a broken editor. That is
# felix_deny_overbroad's job now: a pattern broad enough to refuse ordinary work
# is a wrong rule, not a strict one, and is skipped, which can only allow more.
#
# The matcher is gone altogether (audit b16, C020): the hook is bound to every
# tool and decides for itself which have a subject. Monitor and the MCP terminals
# run a shell command as Bash does, and carried the same `command` field past a
# floor that never saw them. A Bash row now judges the command of every tool that
# may run one (felix_deny_class); a row naming a tool judges that tool's calls.
#
# deny.tsv rows: tool <TAB> extended-regex <TAB> reason [<TAB> scope]
#
# scope is empty, or `checkout`. Empty is every row written before the column
# existed and means what it always meant: refuse whatever the regex matches.
# `checkout` means the row protects the governed checkout and nothing else, so
# a match is refused unless everything the matched command acts on is
# throwaway — a fixture under the session scratchpad or $TMPDIR — which
# lib/where.sh decides. Any other value is read as empty: a scope spelled
# wrong keeps refusing, which is the direction a typo should fail in.

_felix_deny_rows() {
  local proj="$1" tool pattern reason scope
  [ -f "$proj/deny.tsv" ] || return 0
  # The `|| [ -n ]` keeps a last row that has no newline: `read` returns 1 on
  # it with the fields filled, and the row was dropped, so a deny rule written
  # last by hand never refused anything (2026-10-01).
  while IFS=$'\t' read -r tool pattern reason scope || [ -n "${tool:-}" ]; do
    case "$tool" in ''|'#'*) continue ;; esac
    # A row with no pattern is skipped rather than fatal, the same way a
    # malformed routes.tsv row is: one bad line must not stop a table enforcing.
    [ -n "${pattern:-}" ] || continue
    printf '%s\t%s\t%s\t%s\n' "$tool" "$pattern" "${reason:-refused by this project}" "${scope:-}"
  done < "$proj/deny.tsv"
}

# A call's class, in _FELIX_DENY_CLASS: the one answer the hook's early exit,
# its row scan, felix_deny_match and the unknown-shell report all take (audit
# b16, round 3, R3-10). Names are exact, so a plugin prefix is another tool.
#   terminal  Bash, Monitor and the MCP terminals Felix names: Bash rows judge it.
#   exempt    an mcp__ tool known not to run its `command` here: claude-flow's
#             hooks_pre-command assesses one, hooks_post-command records one
#             that ran, Vercel's run_session_command runs a program in a remote
#             sandbox. Only rows naming it judge it.
#   unknown   any other mcp__ tool: Bash rows judge it too, and the hook reports
#             it (R3-1, R3-3). A list of terminals was an instance, and every
#             miss of it passed in silence.
#   tool      any other tool: only rows naming it (B7).
# Given a PAYLOAD, `none` when it holds no key for the tool's field (R3-7). The
# two spellings Claude Code writes are found by case alone; any other costs the
# subject's own reading, which is one awk only on a large payload.
_FELIX_DENY_BL=$' \t\r\n'
felix_deny_class() {
  local tool="$1" f LC_ALL=C
  case "$tool" in
    Bash|Monitor|mcp__terminal__run_in_terminal|mcp__claude-flow__terminal_execute) _FELIX_DENY_CLASS=terminal ;;
    mcp__claude-flow__hooks_pre-command|mcp__claude-flow__hooks_post-command|mcp__plugin_vercel_vercel__run_session_command)
      _FELIX_DENY_CLASS=exempt ;;
    mcp__*) _FELIX_DENY_CLASS=unknown ;;
    *) _FELIX_DENY_CLASS=tool ;;
  esac
  [ "$#" -ge 2 ] || return 0
  _felix_deny_field "$tool" >/dev/null; f="$_FELIX_DENY_FIELD"
  case "$2" in
    *"\"$f\":"*|*"\"$f\" :"*) ;;
    *"\"$f\""[$_FELIX_DENY_BL]*) felix_deny_subject "$2" "$tool" >/dev/null; [ "$?" -ne 1 ] || _FELIX_DENY_CLASS=none ;;
    *) _FELIX_DENY_CLASS=none ;;
  esac
  return 0
}

# Which field of a payload a rule for this tool is about: one per tool, chosen
# rather than searched. Scanning for the first field present is the wrong
# trade: an Edit whose new_string holds `"command": "rm -rf"` would hand that
# text to a rule, which would fire on content the person was only writing
# down. Bash, Monitor and every mcp__ tool are read on `command`; any other
# tool on a file, never on `command`, and a tool acting on nothing has no
# subject. Whether a Bash row judges it is felix_deny_class's question.
#
# The answer is left in _FELIX_DENY_FIELD as well as printed, so the hook, which
# runs on every tool call, can read it without a subshell.
_felix_deny_field() {
  case "$1" in
    Bash|Monitor|mcp__*) _FELIX_DENY_FIELD=command ;;
    NotebookEdit)        _FELIX_DENY_FIELD=notebook_path ;;
    WebFetch)            _FELIX_DENY_FIELD=url ;;
    *)                   _FELIX_DENY_FIELD=file_path ;;
  esac
  printf '%s' "$_FELIX_DENY_FIELD"
}

# That field's value, out of a PreToolUse payload, without parsing JSON. It is
# the value of the first key, the name quoted, any blanks, a colon (round 3,
# R3-7), so a value spelling the name is passed over. Status 1 is no key, and
# 2 a value that is not a string, which no row reads (R3-4), where the next
# string after it was read before. Escaped quotes are protected first, so a
# value holding one cannot run the match past its own end into text the
# person never typed. The first key wins, not the last: file content naming
# the field puts a second copy after the real one.
#
# Small and large payloads are read two ways that return the same string:
# parameter expansion, which runs no program, and one awk, because
# ${s//pat/rep} in bash 3.2 (macOS's, the hook's there) costs about the length
# squared times the escaped quotes. Measured 2026-09-23 on 3.2.57: a 31K
# commit-template payload took 12 to 13 s, a 9K `python3 -c` payload 19 s, and
# a 45K one did not finish in 110 s. Claude Code's hook timeout is 60 s.
_FELIX_DENY_INLINE=1024
felix_deny_subject() {
  local raw="$1" field rest val LC_ALL=C
  _felix_deny_field "${2:-}" >/dev/null; field="$_FELIX_DENY_FIELD"
  case "$raw" in *"\"$field\""*) ;; *) return 1 ;; esac
  # A raw \001 is a control character no JSON string may hold, so this is not
  # a payload Claude Code sent, and like any payload that does not parse it
  # has no subject. The expansion below uses \001 as its placeholder, and one
  # already in the payload would read as a quote there and not in the awk.
  case "$raw" in *$'\001'*) return 1 ;; esac

  if [ "${#raw}" -gt "$_FELIX_DENY_INLINE" ]; then
    # Printed only when awk finished, after a letter for what it found. Part
    # of a subject can be refused by a row anchored at its end that the whole
    # would not match, so an awk that dies, or none on PATH, reads as no key.
    val="$(printf '%s' "$raw" | LC_ALL=C awk -v f="$field" "$_FELIX_DENY_SUBJECT_AWK" 2>/dev/null \
           && printf x)" || return 1
    case "$val" in s*) val="${val#s}"; printf '%s' "${val%x}"; return 0 ;; u*) return 2 ;; esac
    return 1
  fi

  # All parameter expansion, no pipeline: this runs on every tool call. To the
  # first key, keeping a closing quote that may open the next appearance.
  rest="$raw"
  while :; do
    case "$rest" in *"\"$field\""*) ;; *) return 1 ;; esac
    rest="${rest#*\"$field\"}"; val="${rest#"${rest%%[!$_FELIX_DENY_BL]*}"}"
    case "$val" in :*) break ;; esac
    rest="\"$rest"
  done
  rest="${val#:}"; rest="${rest#"${rest%%[!$_FELIX_DENY_BL]*}"}"
  case "$rest" in \"*) rest="${rest#\"}" ;; *) return 2 ;; esac
  rest="${rest//\\\"/$'\001'}"        # neutralise escaped quotes first
  val="${rest%%\"*}"                 # to the first real closing quote
  printf '%s' "${val//$'\001'/\"}"
}

# The same reading as the expansion above, for a large payload: the first
# "field" with blanks and a colon after it, then `u` and nothing more when the
# value is not a string, or `s` and the value up to the first quote with no
# backslash before it, each backslash-quote in what it took read as a quote.
#
# Linear in BWK awk, mawk and gawk. It uses no gsub and no split on a regex,
# since in BWK awk, which macOS ships, both cost the length times the number
# of matches: a gsub of 70,000 escaped quotes in 1M took 12 s. match, index,
# substr and a split on one character are linear. BWK awk splits on a line
# break as well when the separator is one character, so the value is split
# into lines first and each line on its quotes. The records are split on
# \001, which felix_deny_subject has turned away before this runs, so the
# payload is always one record: joining many would be quadratic too. The
# program holds no single quote, since it is a bash single-quoted string.
_FELIX_DENY_SUBJECT_AWK='
  BEGIN { RS = "\001" }
  { s = (NR > 1) ? s RS $0 : $0 }
  END {
    if (!match(s, "\"" f "\"[ \t\r\n]*:")) exit
    s = substr(s, RSTART + RLENGTH)
    if (match(s, /^[ \t\r\n]+/)) s = substr(s, RLENGTH + 1)
    if (substr(s, 1, 1) != "\"") { printf "u"; exit }
    printf "s"; s = substr(s, 2)
    if (substr(s, 1, 1) == "\"") exit
    if (match(s, /[^\\]"/)) s = substr(s, 1, RSTART)
    nl = split(s, L, "\n")
    for (i = 1; i <= nl; i++) {
      if (i > 1) printf "\n"
      np = split(L[i], P, "\"")
      for (j = 1; j < np; j++) printf "%s\"", substr(P[j], 1, length(P[j]) - 1)
      if (np) printf "%s", P[np]
    }
  }'

# Whether a pattern is too broad to be a rule. A pattern that also matches
# ordinary work is a broken rule, not a strict one, and honouring it makes a
# session where nothing can be edited and no error says why. These two probes
# are ordinary: a routine command, and a path in no way special. A pattern
# matching either is skipped, which can only allow more than its author asked,
# never less, so it is safe to run ahead of every rule rather than new ones.
FELIX_DENY_PROBES='git status --short
/felix/probe/ordinary'

felix_deny_overbroad() {
  local pattern="$1" probe LC_ALL=C
  [ -n "$pattern" ] || return 0
  while IFS= read -r probe; do
    [ -n "$probe" ] || continue
    # Bash's own ERE. The pipeline this replaces spawned a grep per probe per
    # rule, on every matched tool call; it also carried a documented SIGPIPE
    # hazard under pipefail that simply cannot arise without a pipe.
    [[ "$probe" =~ $pattern ]] && return 0
  done <<EOF
$FELIX_DENY_PROBES
EOF
  return 1
}

# The rows this project wrote that are too broad to enforce, for reporting.
# Nothing in the hot path calls this: the hook runs on every tool call, and a
# harness that repeats a static complaint on every call is noise. felix doctor
# is where somebody goes to be told what is wrong with their tables.
felix_deny_overbroad_rows() {
  local proj="$1" tool pattern reason scope
  while IFS=$'\t' read -r tool pattern reason scope; do
    [ -n "${pattern:-}" ] || continue
    felix_deny_overbroad "$pattern" && printf '%s\t%s\t%s\n' "$tool" "$pattern" "$reason"
  done <<EOF
$(_felix_deny_rows "$proj")
EOF
}

# What felix doctor says of this project's deny table: the rows the hook skips
# without a word, each kind under a header of its own. The hook is silent as it
# runs on every tool call; that is paid for here, or a rule quietly does
# nothing, the complaint Felix makes of other plugins. The pattern and tool
# sections are lib/table.sh's, which the hook never loads; if it will not load,
# they are said not to have been made. An unreadable table is said, no more.
felix_deny_doctor() {
  local proj="$1" wide t p r
  [ -f "$proj/deny.tsv" ] || return 0
  if [ ! -r "$proj/deny.tsv" ]; then
    printf '\n%s/deny.tsv could not be read, so what it refuses is not known\n' "$proj"
    return 0
  fi
  wide="$(felix_deny_overbroad_rows "$proj" 2>/dev/null)"
  if [ -n "$wide" ]; then
    printf '\ndeny rules too broad to enforce\n\n'
    printf '%s\n' "$wide" | while IFS=$'\t' read -r t p r; do
      [ -n "${p:-}" ] || continue
      printf '  %-14s %s\n' "$t" "$p"
    done
    printf '\nEach of these refuses everything it was asked about, so Felix skips it\n'
    printf 'rather than honouring it. A rule that also matches ordinary work cannot\n'
    printf 'be told apart from a broken editor by the person hitting it, and the\n'
    printf 'harness gets switched off rather than the row corrected.\n'
    printf '\nNarrow the pattern in %s/deny.tsv, or drop the row.\n' "$proj"
  fi
  command -v felix_table_deny_report >/dev/null 2>&1 || . "${_FELIX_DENY_LIB:-.}/table.sh" 2>/dev/null
  if command -v felix_table_deny_report >/dev/null 2>&1; then felix_table_deny_report "$proj"
  else printf '\nthe deny patterns could not be checked: lib/table.sh did not load, so rules that never fire cannot be listed\n'; fi
  return 0
}

# The first row for this tool whose pattern matches the text: its reason goes
# in _FELIX_DENY_REASON, and the status says whether there was one. A variable
# and not output, so the call that nearly always finds nothing costs no
# subshell to find it.
# Locale, 2026-10-08: a pattern holding a byte that was not UTF-8 compiled to
# nothing under UTF-8, so its row refused nothing. The rules are above
# felix_json_str in resolve.sh.
_felix_deny_first() {
  local proj="$1" want="$2" text="$3" tool pattern reason scope LC_ALL=C
  _FELIX_DENY_REASON=""
  while IFS=$'\t' read -r tool pattern reason scope; do
    [ "${tool:-}" = "$want" ] || continue
    felix_deny_overbroad "$pattern" && continue
    # Bash's own ERE rather than `printf | grep`. The old form needed a comment
    # explaining why it could not use `grep -q` — a consumer exiting on first
    # match kills the producer with SIGPIPE and pipefail reports 141, read as
    # "no match" every time. No pipe, no hazard, and no process per rule.
    [[ "$text" =~ $pattern ]] || continue
    # A row scoped to the checkout is passed over, not answered, when the
    # command acts only on throwaway places: a later row may still refuse it.
    # Everything this costs is spent on a command a row already matched.
    if [ "${scope:-}" = checkout ]; then
      _felix_deny_scoped "$want" "$pattern" "$reason" && continue
      reason="$reason
It stood although this row covers only the governed checkout: ${_FELIX_WHERE_WHY:-where the command acts cannot be told}."
    fi
    _FELIX_DENY_REASON="$reason"
    return 0
  done <<EOF
$(_felix_deny_rows "$proj")
EOF
  return 1
}

# Prints the reason when a command matches a row for this tool, and returns 0.
# Silent and returns 1 otherwise.
#
# A Bash row is about the command the shell runs, not text it only carries.
# Until 2026-09-23 a row was matched against the payload's string, where all
# the command carries reads as if it ran: a here-document body for `git commit
# -F -`, a `-m "..."` message, JSON in single quotes, a comment. The marker row
# refused a commit message saying "felix new <name> ... a .felix marker", for
# the `>` in `<name>`; and a JSON line break is a backslash and an `n`, so
# `[^;&|]*` ran from `git push -q` on one line to `gh api -f` on the next and
# read a force push. Of the 175 refusals logged by then, about thirty were text.
#
# So a Bash command is judged on felix_deny_code's reading of it, as the shell
# reads it, and on nothing else. The first form, on 2026-09-23, consulted it
# only after the raw string matched, which could only turn a refusal into an
# allow: where the shell ends a word and the JSON line puts no blank — a `;`
# glued on, a line break, the quote closing a `-c` script, a `)` — a row ending
# at a blank or the line's end saw neither, and the command ran. The founder
# listed twelve such commands that day; reading every command refuses all
# twelve, and the reader prints each separator as a token of its own. Forty-one
# commands written blind that only carry a row's words as data are still
# allowed; the four others of that set of forty-five are refused by the rows as
# written under any reader. A reading in bash itself was measured first: bash
# 3.2's ${s//...} took fourteen seconds over a 31K command.
#
# What it costs, now on every Bash call in a project with Bash rows: one awk,
# the subshell capturing it, one source of lib/deny-read.sh. Measured
# 2026-09-23 by child CPU, since wall time here measures a load of 100 to 300:
# 150 interleaved runs of each engine on one payload, `git status --short` at
# 31 ms of CPU a call before and 39 after (medians; the minima 28 and 35), and
# a commit with Claude Code's template 32 before and 41 after: about 8 ms on a
# floor of about 30. A prefilter skipping the awk was priced and not built: a
# test for the characters where reading and string differ skips 7% of real
# commands, since most carry a JSON backslash, and a per-row keyword test needs
# a proof it never skips a command its row would refuse. Over the real commands
# in this machine's transcripts the reading newly refuses about one in two
# hundred, all but two performing the row's action; the two hand a gate's path
# to a shell function, which a row matching the path after any blank refuses
# on any reading. The counts are in the pull request that made the change.
#
# START is the directory the command starts in, the payload's cwd. It matters
# only to a row scoped to the checkout, which matches the reading like any
# other and is then judged by lib/where.sh on the command as the payload
# carries it; the governed checkout is the one this process stands in.
#
# WANT is the tool the call is for. Where felix_deny_class says Bash rows judge
# it, they do, on the same reading, before its own rows judge it as it stands,
# which is how every row but a Bash row reads.
felix_deny_match() {
  local proj="$1" want="$2" cmd="$3" start="${4:-$PWD}" text
  [ -n "$cmd" ] || return 1
  _FELIX_DENY_RAW="$cmd"; _FELIX_DENY_START="$start"; _FELIX_DENY_SCOPED=""; _FELIX_DENY_TOOL="$want"
  felix_deny_class "$want"
  if [ "$_FELIX_DENY_CLASS" = terminal ] || [ "$_FELIX_DENY_CLASS" = unknown ]; then
    text="$(felix_deny_code "$cmd")"
    if _felix_deny_first "$proj" Bash "$text"; then
      # A Bash row refusing a tool Felix does not know says why (round 3, R3-2).
      [ "$_FELIX_DENY_CLASS" = terminal ] || _FELIX_DENY_REASON="$_FELIX_DENY_REASON
Felix does not know whether $want runs its command on this machine; until it does, the Bash rows judge that command as well."
      printf '%s' "$_FELIX_DENY_REASON"; return 0
    fi
  fi
  if [ "$want" != Bash ] && _felix_deny_first "$proj" "$want" "$cmd"; then
    printf '%s' "$_FELIX_DENY_REASON"
    return 0
  fi
  _felix_deny_record_lifts "$proj" "$cmd"
  return 1
}

# A scoped row, judged once per command however many rows share its pattern.
# The judgement is kept in _FELIX_DENY_SCOPED, which a second row with the
# same pattern asks instead of the reader, and which the lifts are recorded
# from.
_felix_deny_scoped() {
  local want="$1" pattern="$2" reason="$3" line
  while IFS= read -r line; do
    case "$line" in
      "L	$pattern	"*) return 0 ;;
      "S	$pattern	"*) _FELIX_WHERE_WHY="${line#S	"$pattern"	}"; return 1 ;;
    esac
  done <<EOF
$_FELIX_DENY_SCOPED
EOF
  if _felix_deny_scoped_lifts "$want" "$pattern" "$_FELIX_DENY_RAW" "$_FELIX_DENY_START"; then
    _FELIX_DENY_SCOPED="$_FELIX_DENY_SCOPED"$'\n'"L	$pattern	$reason"
    return 0
  fi
  _FELIX_DENY_SCOPED="$_FELIX_DENY_SCOPED"$'\n'"S	$pattern	$_FELIX_WHERE_WHY"
  return 1
}

# Written down as well as allowed, and only when the command was allowed. A
# lift is a row refusing less than its regex says, and a record of each is how
# a later audit replays exactly what the column let through.
_felix_deny_record_lifts() {
  local proj="$1" cmd="$2" line rest
  command -v felix_say >/dev/null 2>&1 || return 0
  while IFS= read -r line; do
    case "$line" in L$'\t'*) ;; *) continue ;; esac
    rest="${line#L	}"
    felix_say "$proj" lifted "$cmd
${rest#*	}" "" "" 2>/dev/null
  done <<EOF
$_FELIX_DENY_SCOPED
EOF
}

# Whether a row scoped to the checkout passes this call over. Bash and Monitor
# are read for where they act; a tool naming one path acts on that path; a URL
# acts on no place the checkout owns, and neither can be told for an mcp__ shell
# tool, which may carry a directory of its own or a server session's, so
# nothing is known and the row stands. The tool is the call's, not the row's:
# a Bash row can judge a Monitor or an mcp__ command.
#
# lib/where.sh is loaded here, from beside this file, and not by the hook: the
# hook runs on every tool call and this runs only after a scoped row matched.
# If it cannot be loaded nothing is known, and the row stands.
_FELIX_DENY_LIB="${BASH_SOURCE[0]%/*}"
_felix_deny_scoped_lifts() {
  local want="${_FELIX_DENY_TOOL:-$1}" pattern="$2" subj="$3" start="$4"
  _FELIX_WHERE_WHY=""
  case "$want" in WebFetch|mcp__*) return 1 ;; esac
  command -v felix_where_lifts >/dev/null 2>&1 \
    || . "$_FELIX_DENY_LIB/where.sh" 2>/dev/null || return 1
  case "$want" in
    Bash|Monitor) felix_where_lifts "$pattern" "$subj" "$start" "$PWD" ;;
    *) felix_where_path_lifts "$subj" "$start" "$PWD" ;;
  esac
}

# The command the shell runs, as one line for a row to match, read from the
# payload's JSON string: commands joined by `;`, every quoted span that is data
# standing as the word `_`, comments and here-document bodies gone, and each
# piece of code found inside something else appended after it, ` ; ` apart, as
# a command of its own.
#
# What counts as data, and each exception to it, since an exception missed is
# a command the shell runs and a row can no longer see:
#
#   - A here-document body is data, unless what reads it runs its input as
#     code: a shell, ssh, su, runuser, watch, eval, source, or `.` in command
#     position. Then its lines are commands. Where its word is unquoted the
#     shell expands the body, so a $( ) or a backtick in it is read as code.
#     And a body written to a file is read as code when the same command then
#     runs that file by the same spelling: `cat > $S/t.sh <<'EOF' ... EOF;
#     bash $S/t.sh`, the shape a scratch fixture takes. Seven of the logged
#     refusals had it, and in each the body ran what its row names. The same
#     holds for quoted text printf or echo writes to a file the command runs.
#   - A quoted span is data, `_`, when it holds a blank or a line break. It is
#     read as code where it is a shell's -c script or an argument of eval,
#     ssh, su, runuser or watch, gathered whole when it is quoted in pieces
#     (`'...'\''...'`). It is its own text, without the quotes, where it is a
#     redirect's target, an operand of a command that writes its operands
#     (cp, mv, ln, install, tee, dd, truncate, rm, touch, rsync, sed -i), the
#     program itself, glued to the word it sits in
#     (`--for'ce'`, `"$HOME"/.felix`, but not `--message="..."`), a single
#     word, or a path rooted in a variable, a home or a relative directory
#     (`$T/...`, `${D}...`, `~/...`, `./...`), so `> "$T/repo/.felix"` still
#     writes the marker. A span starting with a bare `/` is not taken for a
#     path, because `sed -n '/git push .* main /p'` starts that way too.
#   - Inside double quotes a $( ) or a backtick runs, and is read as code. The
#     here-document inside the $( ) of Claude Code's commit template is data
#     by the first rule. A substitution keeps its shape where it stood, as
#     `$(_)` or `<(_)`, since a row can be written about the shape itself.
#   - A # starting a word outside quotes starts a comment. `$(( ))` and
#     `(( ))` are arithmetic, whose << is a shift; the second is read as code
#     as well, in case bash takes it for two subshells.
#   - A pipe into a shell, a shell reading a process substitution, or a $( )
#     handed to something that runs its arguments, makes the data the script:
#     then the whole command is read with every quote dropped and each line
#     break a `;`.
#
# What it does not follow is a file written by anything but a here-document,
# or run by another name: a script printf wrote to $S/bin/claude and PATH
# later finds. That is the limit any reading of one command has.
#
# One awk process, run with LC_ALL=C, so split(s, A, "") is one byte per
# element in BWK awk, mawk and gawk alike (in a UTF-8 locale macOS's BWK awk
# still splits bytes but matches by characters, and aborted). Nothing here
# fails closed: no awk, or a program error, prints nothing, and a row matches
# nothing in nothing, which allows.
#
# The program is lib/deny-read.sh, sourced the first time a command needs it:
# by a call Bash rows judge (felix_deny_class), in a project that has them.
# Locale, 2026-10-08: this awk ran in the caller's locale and aborted under
# UTF-8 on any non-ASCII character, so the reading came back empty and every
# Bash row allowed. The rules are above felix_json_str in resolve.sh.
felix_deny_code() {
  [ -n "${_FELIX_DENY_READ:-}" ] || . "$(dirname "${BASH_SOURCE[0]:-$0}")/deny-read.sh" 2>/dev/null
  printf '%s' "$1" | LC_ALL=C awk "${_FELIX_DENY_READ:-}" 2>/dev/null
}
