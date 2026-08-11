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
# The asymmetry the whole design rests on: "loaded and used" is confounded,
# because loading a capability is what causes it to be used. "Loaded across many
# sessions and never once invoked" is not confounded — it was mounted, it was in
# scope, and it was ignored every time. So mounting is driven by declared need
# and only retiring is driven by evidence, which closes the loop permanently.
#
# That is why the zero rows matter more than the counts. A capability that was
# never reached for leaves no trace of its own; if nothing writes the zero down,
# the only thing the ledger can ever say is that whatever got used got used.

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

  seen=""
  while IFS=$'\t' read -r kind name; do
    [ -n "${name:-}" ] || continue
    printf '%s\t%s\t%s\t%s\t%s\n' "$session" "$date" "$kind" "$name" \
      "$(grep -cxF "$kind	$name" "$state" 2>/dev/null || echo 0)" >> "$tmp"
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
      printf '%s\t%s\t%s\t%s\t0\n' "$session" "$date" "$kind" "$name" >> "$tmp"
    done < "$proj/stack.tsv"
  fi

  mv -f "$tmp" "$out" 2>/dev/null || rm -f "$tmp"
}
