# The capability ledger.
#
# Which capabilities earn their place. Specced 2026-08-09 and unbuilt until
# 2026-08-11, because the spec contradicted itself: its body argued that parsing
# a session transcript breaks the bash-and-git invariant and that the pipeline
# must invert to recording as it happens, and its Records section then described
# a hook that parses a transcript. Recording needs no parser, so the invariant
# wins and this file has no JSON reader in it beyond pulling two known fields
# out of a hook payload.
#
# The asymmetry the design rests on: "loaded and used" is confounded, because
# loading a capability is what causes it to be used. So mounting is driven by
# declared need and only retiring is driven by evidence.
#
# That is why the zero rows matter more than the counts. A capability never
# reached for leaves no trace of its own; if nothing writes the zero down, the
# only thing the ledger can say is that whatever got used got used.
#
# **The correction, 2026-08-12.** This file used to claim a zero "is not
# confounded — it was mounted, it was in scope, and it was ignored every time."
# That is false, and the false half is the half Felix controls. Felix decides
# what the routes name, so a capability no route ever named was never in scope
# in any sense a session could act on. Its zero measures Felix's own priors, and
# retiring on it is a loop closing on itself: logged data confounded by the
# logging policy, which reads as evidence and is not. A year of it would be
# unusable, and the fix is only cheap before the year exists.
#
# So the policy's decision is recorded beside the outcome. `named` counts the
# times a route pointed at a capability; `calls` counts the times it was reached
# for. That splits one zero into two that mean opposite things:
#
#   named>0, calls=0   pointed at and ignored. Evidence about the capability.
#   named=0, calls=0   never pointed at. Evidence about ROUTING, and none at all
#                      about the capability. Reported by felix_ledger_unrouted.
#
# Two things this still does not fix, and they should not be written as if it
# did. Utilisation is not utility: a capability whose whole value is keeping the
# session off a wrong path is never invoked when it works, so counting calls
# punishes prevention and no column here observes the counterfactual. And a gate
# verdict is one bit for a session holding dozens of decisions, so nothing here
# can say which mounted capability earned it.

# How many sessions each capability was present for, and how often it was
# actually reached for.
#
# Reduced to the owner on both sides. A package is declared as
# `superpowers@marketplace` and invoked as `superpowers:brainstorming`, and an
# MCP server is declared under its own name and invoked as `mcp__server__tool`.
# Counting those as three different things would report every capability as
# unused and every use as belonging to nothing.
#
# Emits: name <TAB> sessions <TAB> invocations <TAB> named
#
# `named` is -1 when no row for this capability carried the column, which is how
# data written before 2026-08-12 says "unknown" rather than "zero".
felix_ledger_summary() {
  local proj="$1"
  local f="$proj/memory/ledger.tsv"
  [ -f "$f" ] || return 0
  awk -F'\t' '
    $4 != "" {
      owner = $4
      sub(/@.*/, "", owner)
      sub(/:.*/, "", owner)
      key = owner SUBSEP $1
      if (!(key in seen)) { seen[key] = 1; sessions[owner]++ }
      calls[owner] += $5
      if (NF >= 6 && $6 != "") { named[owner] += $6; known[owner] = 1 }
    }
    END { for (o in sessions)
            printf "%s\t%s\t%s\t%s\n", o, sessions[o], calls[o],
                   (o in known ? named[o] : -1) }
  ' "$f" | LC_ALL=C sort
}

# What Felix pointed at and nobody reached for.
#
# The only direction this may ever run. "Loaded and used" is confounded, because
# loading is what causes use, so no amount of counting can turn a high number
# into a reason to mount something.
#
# `named` is required, and a missing one never counts. Rows written before that
# column existed say nothing either way, and reading a blank as "named" would
# put the overclaim back in the one place nobody would look for it: the data
# already on disk.
#
# The window is sessions, not days. A capability unused across two sessions may
# simply not have come up; the threshold is what separates that from evidence.
FELIX_LEDGER_MIN="${FELIX_LEDGER_MIN:-5}"
felix_ledger_retire() {
  local proj="$1" name sessions calls named
  felix_ledger_summary "$proj" | while IFS=$'\t' read -r name sessions calls named; do
    [ -n "${name:-}" ] || continue
    [ "${calls:-0}" -eq 0 ] 2>/dev/null || continue
    [ "${named:--1}" -gt 0 ] 2>/dev/null || continue
    [ "${sessions:-0}" -ge "$FELIX_LEDGER_MIN" ] 2>/dev/null || continue
    printf '%s\t%s\t%s\n' "$name" "$sessions" "$named"
  done
}

# Mounted, and no route ever pointed at it.
#
# A finding about routes.tsv, never about the capability. It costs context in
# every session and Felix has never once suggested it, so the thing to fix is
# either the table or the mounting — and retiring it on this evidence would be
# concluding that Felix was right to ignore it because Felix ignored it.
felix_ledger_unrouted() {
  local proj="$1" name sessions calls named
  felix_ledger_summary "$proj" | while IFS=$'\t' read -r name sessions calls named; do
    [ -n "${name:-}" ] || continue
    [ "${named:--1}" -eq 0 ] 2>/dev/null || continue
    [ "${calls:-0}" -eq 0 ] 2>/dev/null || continue
    printf '%s\t%s\n' "$name" "$sessions"
  done
}

# One line per tool call, appended. This runs after every tool call in every
# governed session, so its cost is the design constraint: no subshells, no git,
# no reading anything back.
#
# Emits: kind <TAB> name. Empty when the payload carries no tool name, which is
# a normal answer and never an error.
felix_ledger_signal() {
  local raw="$1" tool skill
  tool="$(printf '%s' "$raw" \
    | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  [ -n "$tool" ] || return 0

  case "$tool" in
    # mcp__<server>__<tool>. The server is the unit that gets mounted, so it is
    # the unit worth counting: the design notes that MCP contribution is
    # invisible to the attribution fields and only tool names reveal it.
    mcp__*)
      tool="${tool#mcp__}"
      printf 'mcp\t%s' "${tool%%__*}"
      return 0 ;;
    Skill|skill)
      skill="$(printf '%s' "$raw" \
        | sed -n 's/.*"skill"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
      [ -n "$skill" ] && { printf 'skill\t%s' "$skill"; return 0; }
      ;;
  esac
  printf 'tool\t%s' "$tool"
}

_felix_ledger_state() { printf '%s/state/ledger/%s.tsv' "$1" "$2"; }

# What a route named, recorded at the moment it was named.
#
# This is the policy's decision, and without it the ledger only ever holds the
# outcome. Same append-only, never-fatal shape as felix_ledger_record: it runs
# on every prompt, so a failure here loses a measurement and must never cost the
# session. Takes the play verbatim — a space-separated list of tools — because
# that is exactly what the route table holds and what got rendered.
felix_ledger_note_named() {
  local home="$1" session="$2" play="$3" f one
  [ -n "$session" ] && [ -n "$play" ] || return 0
  f="$(_felix_ledger_state "$home" "$session")"
  mkdir -p "$(dirname "$f")" 2>/dev/null || return 0
  for one in $play; do
    [ -n "$one" ] || continue
    printf 'named\t%s\n' "$one" >> "$f" 2>/dev/null || true
  done
}

# Append. Failure is never fatal and never blocks a tool call: a ledger that
# cannot write is a lost measurement, and a hook that fails loudly over one is a
# hook somebody removes.
felix_ledger_record() {
  local home="$1" session="$2" signal="$3" f
  [ -n "$session" ] && [ -n "$signal" ] || return 0
  f="$(_felix_ledger_state "$home" "$session")"
  mkdir -p "$(dirname "$f")" 2>/dev/null || return 0
  printf '%s\n' "$signal" >> "$f" 2>/dev/null || true
}

# Fold one session's appends into the committed ledger, once.
#
# Rewritten rather than appended to, so rolling the same session twice cannot
# double it: a SessionEnd hook can fire more than once, and a ledger that grows
# on every clear would report a capability as used far more than it was.
felix_ledger_rollup() {
  local proj="$1" home="$2" session="$3" date="$4" state out seen kind name
  state="$(_felix_ledger_state "$home" "$session")"
  [ -f "$state" ] || return 0
  [ -d "$proj/memory" ] || return 0
  out="$proj/memory/ledger.tsv"

  local tmp; tmp="$(mktemp)" || return 0
  # Everything this session did not write stays exactly as it was.
  [ -f "$out" ] && grep -v "^${session}	" "$out" >> "$tmp" 2>/dev/null

  # `named` rows are the policy's decision, not a call. They are folded into the
  # sixth column of whatever they name rather than being rows of their own.
  seen=""
  while IFS=$'\t' read -r kind name; do
    [ -n "${name:-}" ] || continue
    [ "$kind" = "named" ] && continue
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$session" "$date" "$kind" "$name" \
      "$(grep -cxF "$kind	$name" "$state" 2>/dev/null || echo 0)" \
      "$(grep -cxF "named	$name" "$state" 2>/dev/null || echo 0)" >> "$tmp"
    seen="$seen
$name"
  done <<EOF
$(sort -u "$state" 2>/dev/null)
EOF

  # Anything a route named that was never reached for. It has no call row to
  # hang a count on, and it is the most important cell in the table: Felix
  # pointed at it and the session went elsewhere.
  while IFS=$'\t' read -r kind name; do
    [ "${kind:-}" = "named" ] || continue
    [ -n "${name:-}" ] || continue
    printf '%s\n' "$seen" | grep -xF "$name" >/dev/null 2>&1 && continue
    printf '%s\t%s\tnamed\t%s\t0\t%s\n' "$session" "$date" "$name" \
      "$(grep -cxF "named	$name" "$state" 2>/dev/null || echo 0)" >> "$tmp"
    seen="$seen
$name"
  done <<EOF
$(sort -u "$state" 2>/dev/null)
EOF

  # The zero rows. Every declared capability that this session never reached
  # for, written down because absence of use given presence is the only
  # unconfounded evidence in the design and it leaves no trace of its own.
  if [ -f "$proj/stack.tsv" ]; then
    while IFS=$'\t' read -r kind name _src _risk _cap; do
      case "${kind:-}" in ''|'#'*) continue ;; esac
      [ -n "${name:-}" ] || continue
      # stack.tsv names a package (`superpowers@marketplace`); a signal names
      # what was actually invoked (`superpowers:brainstorming`). Compared with
      # both sides reduced to the owner, or a plugin whose skill was used all
      # session gets recorded as never reached for — which would put the one
      # unconfounded signal in the design permanently in the wrong column.
      local bare="${name%%@*}"
      printf '%s\n' "$seen" | sed 's/:.*//' | grep -xF "$bare" >/dev/null 2>&1 && continue
      printf '%s\t%s\t%s\t%s\t0\t%s\n' "$session" "$date" "$kind" "$name" \
        "$(grep -cF "named	$bare" "$state" 2>/dev/null || echo 0)" >> "$tmp"
    done < "$proj/stack.tsv"
  fi

  mv -f "$tmp" "$out" 2>/dev/null || rm -f "$tmp"
}
