# Denial.
#
# The first thing Felix can stop rather than mention. Every other hook it wires
# injects text a session is free to ignore: SessionStart mounts doctrine,
# UserPromptSubmit names a play, Stop asks a question at the end. PreToolUse
# decides, and it is the only one that does.
#
# Felix skipped it for a long time because the charter said "governance layer",
# and a governance layer that only reports is a coherent thing to build. It is
# not what was wanted. A project running a stale copy of its own gate all day
# and reporting green is the case this exists for: Felix could see the rival
# gate and could not stop anybody running it.
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
# It used to be narrow in a fourth way, and that one was a mistake. The matcher
# in hooks.json bound Bash alone, so no rule could see Read, Edit or Write —
# and the ledger then showed real sessions spending most of their calls on
# exactly those three. The matcher was doing duty as the blast-radius control,
# because a bad regex reaching Edit is indistinguishable from a broken editor.
#
# That is now handled where it belongs, by felix_deny_overbroad, so the matcher
# no longer has to be the answer. A pattern broad enough to refuse ordinary
# work is treated as a rule that is wrong rather than a rule that is strict,
# and skipped. Skipping can only ever allow more than the author intended,
# which is the same direction every other failure here already takes.
#
# deny.tsv rows: tool <TAB> extended-regex <TAB> reason

_felix_deny_rows() {
  local proj="$1" tool pattern reason
  [ -f "$proj/deny.tsv" ] || return 0
  while IFS=$'\t' read -r tool pattern reason; do
    case "$tool" in ''|'#'*) continue ;; esac
    # A row with no pattern is skipped rather than fatal, the same way a
    # malformed routes.tsv row is: one bad line must not stop a table enforcing.
    [ -n "${pattern:-}" ] || continue
    printf '%s\t%s\t%s\n' "$tool" "$pattern" "${reason:-refused by this project}"
  done < "$proj/deny.tsv"
}

# Which field of a payload a rule for this tool is about.
#
# One field per tool, chosen rather than searched. Scanning the payload for the
# first field that happens to be present looks more future-proof and is the
# wrong trade: an Edit whose new_string contains the text `"command": "rm -rf"`
# would hand that string to the matcher, and a rule would fire on content the
# person was only writing down. A tool nobody has taught this function is read
# as acting on a file, and a tool acting on nothing has no subject and is
# always allowed.
_felix_deny_field() {
  case "$1" in
    Bash)         printf 'command' ;;
    NotebookEdit) printf 'notebook_path' ;;
    WebFetch)     printf 'url' ;;
    *)            printf 'file_path' ;;
  esac
}

# That field's value, out of a PreToolUse payload, without parsing JSON.
#
# Escaped quotes are protected first, so a value containing one cannot run the
# match past the end of its own string and swallow the rest of the envelope.
# That over-capture is the dangerous direction here: it is how a rule matches
# text the person never typed and denies something legitimate.
#
# The first occurrence wins, not the last. A greedy leading `.*` in sed takes
# the last one, which is reachable: file content mentioning the field name puts
# a second copy after the real one, and the rule would then be tested against
# whatever that content said.
#
# Read two ways, split by size, and both return the same string. A small
# payload is read with parameter expansion, which costs no process. A large
# one is read by one awk, because ${s//pat/rep} in bash 3.2, which macOS ships
# and the hook runs under there, is not linear: for each match it tries every
# end position back from the end of the string and measures each with a
# strlen, so it costs about the length squared times the number of escaped
# quotes. Measured 2026-09-23 on 3.2.57: a 31K commit-template payload took 12
# to 13 s, a 9K `python3 -c` payload 19 s, and a 45K one did not finish in
# 110 s. Claude Code's hook timeout is 60 s.
_FELIX_DENY_INLINE=1024
felix_deny_subject() {
  local raw="$1" field rest val
  field="$(_felix_deny_field "${2:-}")"
  case "$raw" in *"\"$field\""*) ;; *) return 0 ;; esac

  if [ "${#raw}" -gt "$_FELIX_DENY_INLINE" ]; then
    printf '%s' "$raw" | LC_ALL=C awk -v f="$field" "$_FELIX_DENY_SUBJECT_AWK" 2>/dev/null
    return 0
  fi

  # All parameter expansion, no pipeline. This runs inside a synchronous hook on
  # every tool call, and the old tr/sed/awk/sed chain cost four process spawns
  # for a substring bash can find itself.
  rest="${raw#*\"$field\"}"          # after the key
  rest="${rest#*\"}"                 # past the colon, to the value's quote
  rest="${rest//\\\"/$'\001'}"        # neutralise escaped quotes first
  val="${rest%%\"*}"                 # to the first real closing quote
  printf '%s' "${val//$'\001'/\"}"
}

# The same reading as the expansion above, for a large payload: after the
# first "field", past the next quote, up to the first quote with no backslash
# before it, and each backslash-quote in what it took read as a quote.
#
# Linear in BWK awk, mawk and gawk. It uses no gsub and no split on a regex,
# since in BWK awk, which macOS ships, both cost the length times the number
# of matches: a gsub of 70,000 escaped quotes in 1M took 12 s. match, index,
# substr and a split on one character are linear. BWK awk splits on a line
# break as well when the separator is one character, so the value is split
# into lines first and each line on its quotes. The program holds no single
# quote, since it is a bash single-quoted string.
_FELIX_DENY_SUBJECT_AWK='
  BEGIN { RS = "\001" }
  { s = (NR > 1) ? s RS $0 : $0 }
  END {
    k = index(s, "\"" f "\"")
    if (!k) exit
    s = substr(s, k + length(f) + 2)
    if ((q = index(s, "\"")) > 0) s = substr(s, q + 1)
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

# Whether a pattern is too broad to be a rule.
#
# A rule says which work this project refuses. A pattern that also matches
# ordinary work is not a strict rule, it is a broken one, and honouring it
# produces a session where nothing can be edited and no error explains why.
# These two probes are what ordinary looks like: a routine command, and a path
# in no way special. Anything matching either is skipped.
#
# This can only ever allow more than the author asked for, never less, which is
# why it is safe to run ahead of every rule rather than only new ones.
FELIX_DENY_PROBES='git status --short
/felix/probe/ordinary'

felix_deny_overbroad() {
  local pattern="$1" probe
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
  local proj="$1" tool pattern reason
  while IFS=$'\t' read -r tool pattern reason; do
    [ -n "${pattern:-}" ] || continue
    felix_deny_overbroad "$pattern" && printf '%s\t%s\t%s\n' "$tool" "$pattern" "$reason"
  done <<EOF
$(_felix_deny_rows "$proj")
EOF
}

# Prints the reason when a command matches a row for this tool, and returns 0.
# Silent and returns 1 otherwise.
felix_deny_match() {
  local proj="$1" want="$2" cmd="$3" tool pattern reason
  [ -n "$cmd" ] || return 1
  while IFS=$'\t' read -r tool pattern reason; do
    [ "${tool:-}" = "$want" ] || continue
    felix_deny_overbroad "$pattern" && continue
    # Bash's own ERE rather than `printf | grep`. The old form needed a comment
    # explaining why it could not use `grep -q` — a consumer exiting on first
    # match kills the producer with SIGPIPE and pipefail reports 141, read as
    # "no match" every time. No pipe, no hazard, and no process per rule.
    if [[ "$cmd" =~ $pattern ]]; then
      printf '%s' "$reason"
      return 0
    fi
  done <<EOF
$(_felix_deny_rows "$proj")
EOF
  return 1
}
