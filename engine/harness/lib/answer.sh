# Answers: a capability's output handed to a session without being asked for,
# and what the session did next.
#
# The ledger was built for reaches: a session chose a capability and the call
# shows it. That cannot see the case the knowledge graph was in on 2026-10-29,
# named in 193 sessions and queried in 3, because the fix for a tool nobody
# reaches for is to stop waiting for the reach and deliver what it would have
# said. A delivery is not a reach, so it gets its own kind and its own measure,
# and the measure is the one that matters: not whether the answer was given,
# which the hook guarantees, but whether the session went where it pointed.
#
# Three records, one file per session, state/answer/<session>.tsv:
#
#   given<TAB><tool><TAB><n>        one delivery, naming n files
#   answer<TAB><tool><TAB><file>    one file it named, relative to the repository
#   touch<TAB><Tool><TAB><value>    a later Read/Edit/Write/Grep/Glob/Bash, by path or command
#
# and one ledger signal per delivery, `answer<TAB><tool>`, folded by the rollup
# into rows no capability reading sees (lib/ledger.sh). The graph is the first
# tool to answer (lib/graph.sh, felix_graph_deliver); the next one writes the
# same rows and is measured by the same function. That is the point of keeping
# this apart from graph.sh: a capability plane that can mount a tool but cannot
# tell whether its answers were used has not arranged the tool, only installed
# it. docs/2026-10-29-answers-delivered-spec.md, T1-T2 and L3-L4.

# What the session did after an answer was handed to it, from the post-tool
# payload. Only when the session has an answer record, so a session nothing
# was handed to pays a file test and nothing else.
#
# The FIRST occurrence of the key, by index rather than by a greedy sed: the
# payload carries tool_input before tool_response, and a Read's response holds
# the file's text, which may itself contain a "file_path" key.
felix_answer_touch() {
  local home="$1" session="$2" signal="$3" raw="$4" f key tool v cap=0
  [ -n "$session" ] || return 0
  f="$home/state/answer/$session.tsv"
  [ -f "$f" ] || return 0
  case "$signal" in
    "tool	Read"|"tool	Edit"|"tool	Write"|"tool	MultiEdit") key=file_path ;;
    "tool	NotebookEdit") key=notebook_path ;;
    "tool	Grep"|"tool	Glob") key=path ;;
    "tool	Bash") key=command ;;
    *) return 0 ;;
  esac
  tool="${signal#*	}"
  [ "$key" = command ] && cap=400
  v="$(printf '%s\n' "$raw" | LC_ALL=C awk -v k="\"$key\"" -v cap="$cap" '
    done { next }
    {
      i = index($0, k); if (!i) next
      s = substr($0, i + length(k))
      sub(/^[ \t]*:[ \t]*/, "", s)
      if (substr(s, 1, 1) != "\"") { done = 1; next }
      s = substr(s, 2); j = index(s, "\""); if (j) s = substr(s, 1, j - 1)
      if (cap > 0) s = substr(s, 1, cap)
      print s; done = 1
    }')"
  [ -n "$v" ] || return 0
  # The 2>/dev/null outside the group: a redirection that fails reports on the
  # stderr in force before it, so one written after `>>` silences nothing.
  { printf 'touch\t%s\t%s\n' "$tool" "$v" >> "$f"; } 2>/dev/null || true
  return 0
}

# Deliveries per tool, from the folded ledger: tool<TAB>sessions<TAB>deliveries.
felix_ledger_answers() {
  _felix_ledger_rows "$(felix_mem_dir "$1")" | LC_ALL=C awk -F'\t' '
    $3 == "answer" && $4 != "" {
      if (!(($4 SUBSEP $1) in seen)) { seen[$4 SUBSEP $1] = 1; s[$4]++ }
      d[$4] += $5
    }
    END { for (t in s) printf "%s\t%s\t%s\n", t, s[t], d[t] }' | LC_ALL=C sort
}

# Whether the sessions went where the answers pointed, per tool:
# tool<TAB>sessions<TAB>sessions_acted<TAB>deliveries<TAB>deliveries_acted<TAB>files<TAB>files_acted
#
# A named file is acted on when a touch AFTER its answer row matches it: a path
# equal to it or ending in /<file>, or, for Bash, a command holding its path or
# a basename with a dot in it (`run` alone would match half the commands typed).
# Only sessions this repository owns, by the same test the catch-up uses, since
# state/ carries no project namespace.
#
# What it cannot say, and the caller prints it: a file the session would have
# opened anyway is counted too, so this bounds what the answers caused from
# above. The baseline that bounds it from below is in the spec, section 8.
felix_answer_use() {
  local proj="$1" home="$2" root="${3:-}" f session
  local -a owned=()
  for f in "$home"/state/answer/*.tsv; do
    [ -f "$f" ] || continue
    session="${f##*/}"; session="${session%.tsv}"
    _felix_ledger_owns "$home" "$root" "$session" || continue
    owned+=("$f")
  done
  [ "${#owned[@]}" -gt 0 ] || return 0
  LC_ALL=C awk -F'\t' '
    function hit(f, tool, v,   b) {
      if (tool == "Bash") {
        if (index(v, f)) return 1
        b = f; sub(/.*\//, "", b)
        return (index(b, ".") && index(v, b)) ? 1 : 0
      }
      if (v == f) return 1
      return (length(v) > length(f) && substr(v, length(v) - length(f)) == "/" f) ? 1 : 0
    }
    function flush(   i, t) {
      for (i = 1; i <= n; i++) {
        t = nt[i]; files[t]++
        if (acted[i]) { files_acted[t]++; dhit[nd[i]] = 1 }
      }
      for (i = 1; i <= dn; i++) {
        t = dt[i]; deliveries[t]++; sess_tool[t] = 1
        if (dhit[i]) { deliveries_acted[t]++; sess_acted[t] = 1 }
      }
      for (t in sess_tool) { sessions[t]++; if (t in sess_acted) sessions_acted[t]++ }
      n = 0; dn = 0; split("", acted); split("", dhit); split("", sess_tool); split("", sess_acted)
      split("", cur)
    }
    FNR == 1 && NR > 1 { flush() }
    $1 == "given"  && $2 != "" { dn++; dt[dn] = $2; cur[$2] = dn; next }
    $1 == "answer" && $2 != "" && $3 != "" {
      if (!($2 in cur)) { dn++; dt[dn] = $2; cur[$2] = dn }
      n++; nm[n] = $3; nt[n] = $2; nd[n] = cur[$2]; acted[n] = 0; next
    }
    $1 == "touch" {
      for (i = 1; i <= n; i++) if (!acted[i] && hit(nm[i], $2, $3)) acted[i] = 1
    }
    END {
      flush()
      for (t in sessions)
        printf "%s\t%d\t%d\t%d\t%d\t%d\t%d\n", t, sessions[t], sessions_acted[t],
               deliveries[t], deliveries_acted[t], files[t], files_acted[t]
    }' "${owned[@]}" | LC_ALL=C sort
}
