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
#   - Scoped to Bash by the matcher in hooks.json. A denial bug that reached
#     Edit and Write would look exactly like a broken editor, which is the
#     failure guard.sh was written to explain to people it had happened to.
#   - Table-driven, per project. The engine names no rule of its own, the same
#     way it names no project. What a repo refuses is the repo's decision.
#   - Fails open on everything. A missing table, an unparseable payload, a bad
#     regex, an unresolvable project: all allow. The cost of a false deny is a
#     person fighting their own tools and switching the harness off; the cost of
#     a missed deny is the status quo.
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

# The command out of a PreToolUse payload, without parsing JSON.
#
# Escaped quotes are protected first, so a command containing one cannot run the
# match past the end of its own string and swallow the rest of the envelope.
# That over-capture is the dangerous direction here: it is how a rule matches
# text the person never typed and denies something legitimate.
felix_deny_command() {
  printf '%s' "$1" \
    | sed 's/\\"/\x01/g' \
    | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | sed 's/\x01/"/g' \
    | head -1
}

# Prints the reason when a command matches a row for this tool, and returns 0.
# Silent and returns 1 otherwise.
felix_deny_match() {
  local proj="$1" want="$2" cmd="$3" tool pattern reason
  [ -n "$cmd" ] || return 1
  while IFS=$'\t' read -r tool pattern reason; do
    [ "${tool:-}" = "$want" ] || continue
    # grep without -q on purpose. Under `set -o pipefail` a consumer that exits
    # on its first match kills the producer with SIGPIPE and the pipeline
    # reports 141, which this file would read as "no match" every time. This
    # project has paid for that lesson twice; read to the end and decide after.
    if printf '%s\n' "$cmd" | grep -E "$pattern" >/dev/null 2>&1; then
      printf '%s' "$reason"
      return 0
    fi
  done <<EOF
$(_felix_deny_rows "$proj")
EOF
  return 1
}
