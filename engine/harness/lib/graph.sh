# The knowledge graph, as a fact the session is told rather than a tool it
# might think to reach for.
#
# Measured 2026-09-10: the graph under graphify-out/ had been built three times
# and queried once across 72 recorded sessions, and the once was the session in
# which the founder asked why it was never used. The first fix was a route —
# `orient`, keyed on the words a structure question is asked with. That was
# right and insufficient: a route fires when the prompt matches it, and most
# sessions do not open by saying "trace" or "architecture". A tool that is only
# named when you already knew to ask for it is a tool for people who did not
# need it.
#
# So the graph stops being a suggestion and becomes a line in the one place a
# session always reads: the start. Three facts, no advice — that it exists,
# whether it still describes this tree, and the command that asks it.
#
# What this file may not do, and the boundary is the second invariant rather
# than taste: no model, no network, no cost in front of a person. Reading the
# stamp is a tail of the last four kilobytes, measured at 8ms on a 1.9MB graph;
# reading the whole file to count nodes was 83ms and bought a number nobody
# acts on.

FELIX_GRAPH_TAIL="${FELIX_GRAPH_TAIL:-4096}"

# felix_graph_deliver records in the ledger. Sourced by path with the house
# guard, because the suite sources libraries alone, in subshells.
if ! command -v felix_ledger_record >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/ledger.sh"
fi

# The graph belongs to the checkout that holds it, not to the tree you are
# standing in. A worktree has no graphify-out/ of its own and never will: the
# graph is built from the holding checkout, so that is the tree it describes
# and the tree its staleness is measured against. This is the same correction
# the graphify maintenance row needed.
felix_graph_home() {
  local root="${1:-$PWD}" common
  common="$(git -C "$root" rev-parse --git-common-dir 2>/dev/null)" || return 1
  case "$common" in
    /*) ;;
    *)  common="$root/$common" ;;
  esac
  (cd "$(dirname "$common")" 2>/dev/null && pwd -P) || return 1
}

felix_graph_file() {
  local home; home="$(felix_graph_home "${1:-$PWD}")" || return 1
  [ -f "$home/graphify-out/graph.json" ] || return 1
  printf '%s/graphify-out/graph.json\n' "$home"
}

# The commit the graph says it was built from, or nothing.
#
# From the tail rather than the whole document. `built_at_commit` is the last
# key graphify writes, and a hook that runs in every session of every governed
# project does not get to read two megabytes to learn forty characters. If the
# key ever moves to the front this returns nothing, which reads as "no stamp"
# — the honest answer, and the one that does not claim currency it cannot
# establish.
felix_graph_stamp() {
  local f="${1:-}" s
  [ -f "$f" ] || return 1
  s="$(tail -c "$FELIX_GRAPH_TAIL" "$f" 2>/dev/null \
       | sed -n 's/.*"built_at_commit"[[:space:]]*:[[:space:]]*"\([0-9a-f]\{7,40\}\)".*/\1/p' | head -1)"
  [ -n "$s" ] || return 1
  printf '%s\n' "$s"
}

# How many commits the holding checkout has taken since the graph was built.
# Nothing and non-zero when the stamp names a commit this repository does not
# have — a graph built elsewhere describes something, but not this.
felix_graph_behind() {
  local root="${1:-$PWD}" stamp="${2:-}" home n
  [ -n "$stamp" ] || return 1
  home="$(felix_graph_home "$root")" || return 1
  git -C "$home" cat-file -e "${stamp}^{commit}" 2>/dev/null || return 1
  n="$(git -C "$home" rev-list --count "${stamp}..HEAD" 2>/dev/null)" || return 1
  case "$n" in ''|*[!0123456789]*) return 1 ;; esac
  printf '%s\n' "$n"
}

# The line a session is told at its start, or nothing at all.
#
# Nothing is the important half. A project with no graph hears no line, and a
# line that cannot say whether the graph is current does not pretend: an
# unreadable stamp says so rather than implying freshness. The rule this file
# exists to serve is that a session should know the graph is there; it is not
# served by a sentence that is wrong.
felix_graph_line() {
  local root="${1:-$PWD}" f stamp behind
  f="$(felix_graph_file "$root")" || return 1
  stamp="$(felix_graph_stamp "$f")" || {
    printf 'Knowledge graph: present, and carrying no build stamp, so whether it\n'
    printf 'still describes this tree is unknown. Ask it with: graphify query "..."\n'
    return 0
  }
  if ! behind="$(felix_graph_behind "$root" "$stamp")"; then
    printf 'Knowledge graph: built at %s, which is not a commit this repository\n' "${stamp%"${stamp#???????}"}"
    printf 'holds. Ask it with: graphify query "..." and treat it as describing another tree.\n'
    return 0
  fi
  if [ "$behind" -eq 0 ]; then
    printf 'Knowledge graph: current with this checkout. Ask it before reading files:\n'
    printf '  graphify query "how does X work"   graphify explain "X"   graphify affected "X"\n'
  else
    printf 'Knowledge graph: %s commit(s) behind this checkout, built at %s.\n' \
      "$behind" "${stamp%"${stamp#???????}"}"
    printf 'Still worth asking — it is stale, not wrong — with: graphify query "..."\n'
  fi
  return 0
}

# Code-only refresh, in the background, at most one at a time.
#
# `graphify update` re-extracts code files and says so itself: no LLM needed.
# That is what makes this legal here. The semantic half — documents, papers,
# images — needs a model, a hook may never call one, and so the documents in
# this repository stay the job of the maintenance routine a session runs. This
# closes the common case, which is code moving, and says nothing about the
# other.
#
# The shrink guard is left on deliberately. `graphify update` refuses to write
# a graph with fewer nodes than the one it replaces unless forced, and a
# background job that quietly shrank the graph would be worse than one that did
# nothing. A refusal leaves the previous graph in place and the staleness line
# keeps saying so.
#
# The lock is a directory because mkdir is atomic everywhere and a stale lock
# file is not. Same shape as the discovery refresh, for the same reason.
felix_graph_refresh_bg() {
  local root="${1:-$PWD}" home lock
  command -v graphify >/dev/null 2>&1 || return 0
  home="$(felix_graph_home "$root")" || return 0
  [ -d "$home/graphify-out" ] || return 0
  lock="$home/graphify-out/.felix-refresh.lock"
  # A lock older than any refresh takes is one a killed refresh left behind,
  # and the trap that removes it never ran. Without this it held off every
  # refresh after it and nothing said so, and a session end, the likeliest
  # moment for a refresh to be killed, now starts one (hooks/session-end).
  # find, not stat, because the two stats disagree on their flags.
  if [ -d "$lock" ] && [ -n "$(find "$lock" -maxdepth 0 -type d -mmin +"${FELIX_GRAPH_LOCK_STALE:-30}" 2>/dev/null)" ]; then
    rmdir "$lock" 2>/dev/null
  fi
  mkdir "$lock" 2>/dev/null || return 0   # already running; leave it alone
  (
    trap 'rmdir "$lock" 2>/dev/null' EXIT
    felix_close_inherited_fds
    cd "$home" 2>/dev/null || exit 0
    graphify update "$home" >/dev/null 2>&1
  ) </dev/null >/dev/null 2>&1 &
  return 0
}

# Due for a refresh: the stamp names a commit the holding checkout has, and HEAD
# has moved past it. Everything else, including a stamp nobody can read, is not
# due, because a refresh cannot make an unknown graph known.
felix_graph_refresh_due() {
  local root="${1:-$PWD}" f stamp behind
  f="$(felix_graph_file "$root")" || return 1
  stamp="$(felix_graph_stamp "$f")" || return 1
  behind="$(felix_graph_behind "$root" "$stamp")" || return 1
  [ "$behind" -gt 0 ]
}

# ---------------------------------------------------------------- answers ----
# The graph's answer, handed to the session rather than named to it.
#
# Everything above this line names the graph. Measured 2026-10-29: the line
# was in 193 sessions and the graph was queried in 3; the orient route named it
# in 15 and it was reached in none. Naming is advice, and forty lines of banner
# are where advice goes to be skimmed. So the hook asks the graph the prompt
# itself and puts what it returns in front of the model, and the ledger records
# the delivery and what the session did next (lib/ledger.sh, "answers").
#
# `query` and not `affected`, and that is a measurement too. Of the files that
# depend on each engine file, the graph links 16% (74 of 455): graphify's bash
# extractor resolves `source` only from felix and bin/, and an edge for a call
# inside $(...) is never made. `affected` on a file finds nothing at all,
# because it seeds through `contains` and bash files `defines`. An injected
# dependents list that short reads as complete, which is worse than none. What
# the graph does answer is where a thing is, and that is what is handed over.
#
# A hook may not call a model. graphify query loads graph.json with networkx and
# walks it: no model, no network, read in its cli.py and serve.py. It runs under
# a bound (_felix_graph_bounded), so a prompt never waits on it for long.
# docs/2026-10-29-answers-delivered-spec.md, A1-A3.

# The prompt string out of a UserPromptSubmit payload, read to its first
# unescaped quote, with \" and \\ unescaped. Not felix_route_prompt, which
# returns the rest of the payload after the key: what is asked here must be the
# prompt and nothing after it.
felix_graph_prompt() {
  local raw="$1" rest nl='
'
  case "$raw" in *'"prompt"'*) ;; *) return 1 ;; esac
  rest="${raw#*\"prompt\"}"
  rest="${rest#*:}"
  rest="${rest#"${rest%%[![:space:]]*}"}"
  case "$rest" in \"*) rest="${rest#\"}" ;; *) return 1 ;; esac
  printf '%s\n' "${rest%%"$nl"*}" | LC_ALL=C sed -E -e 's/^(([^"\\]|\\.)*)".*$/\1/' -e 's/\\(["\\])/\1/g'
}

# The graph's answer to <prompt>: src<TAB>loc<TAB>label per node, or nothing
# and 1. Spec A1, step by step.
felix_graph_answer() {
  local root="${1:-$PWD}" prompt="${2:-}" f home q words out parsed line src loc rest label
  local files="${FELIX_GRAPH_FILES:-8}" n=0 rows=0 seen="" tab=$'\t' nl='
'
  [ "${FELIX_GRAPH_ANSWER:-1}" = 0 ] && return 1
  f="$(felix_graph_file "$root")" || return 1
  home="${f%/graphify-out/graph.json}"
  command -v graphify >/dev/null 2>&1 || return 1
  command -v perl >/dev/null 2>&1 || return 1
  # Whitespace, real or JSON-escaped, is one space; then the first 400
  # characters, because a long brief's opening is its subject and the rest only
  # widens what the traversal seeds on.
  q="$(printf '%s\n' "$prompt" | LC_ALL=C sed -e 's/\\[ntr]/ /g' | LC_ALL=C tr '\t\r\n' '   ' \
       | LC_ALL=C sed -e 's/  */ /g' -e 's/^ //' -e 's/ $//' | LC_ALL=C cut -c1-400)"
  words="$(printf '%s\n' "$q" | LC_ALL=C awk '{ print NF }')"
  [ "${words:-0}" -ge "${FELIX_GRAPH_MIN_WORDS:-5}" ] 2>/dev/null || return 1
  out="$(_felix_graph_bounded "${FELIX_GRAPH_TIMEOUT:-4}" \
           graphify query "$q" --budget "${FELIX_GRAPH_BUDGET:-600}" --graph "$f" 2>/dev/null)" || return 1
  [ -n "$out" ] || return 1
  # NODE <label> [src=<src> loc=<loc> community=<c>]. Split on the field
  # markers rather than on spaces, since labels carry spaces; `None` is how
  # graphify prints a node with no location. Control bytes, tabs among them,
  # leave the label here, so nothing after this has a tab inside a field.
  parsed="$(printf '%s\n' "$out" | LC_ALL=C awk '
    /^NODE / {
      line = substr($0, 6)
      i = index(line, " [src="); if (!i) next
      label = substr(line, 1, i - 1); rest = substr(line, i + 6)
      j = index(rest, " loc="); if (!j) next
      src = substr(rest, 1, j - 1); rest = substr(rest, j + 5)
      k = index(rest, " community="); if (!k) k = index(rest, "]"); if (!k) next
      loc = substr(rest, 1, k - 1); if (loc == "None") loc = ""
      gsub(/[[:cntrl:]]/, "", label); label = substr(label, 1, 120)
      printf "%s\t%s\t%s\n", src, loc, label
    }')"
  # Split by hand, not with IFS=tab: tab is IFS whitespace, so an empty loc
  # between two tabs would vanish and the label would land in its place.
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    src="${line%%"$tab"*}"; rest="${line#*"$tab"}"
    loc="${rest%%"$tab"*}"; label="${rest#*"$tab"}"
    case "$src" in ''|/*|None) continue ;; esac
    case "/$src/" in */../*) continue ;; esac
    [ -f "$home/$src" ] || continue
    case "$nl$seen" in
      *"$nl$src$nl"*) ;;
      *) [ "$n" -ge "$files" ] && continue
         seen="$seen$src$nl"; n=$((n + 1)) ;;
    esac
    printf '%s\t%s\t%s\n' "$src" "$loc" "$label"
    rows=$((rows + 1))
    [ "$rows" -ge 16 ] && break
  done <<EOF
$parsed
EOF
  [ "$rows" -gt 0 ]
}

# <command> run for at most <seconds>, then killed with everything it started.
#
# Not a bare `perl -e 'alarm shift; exec @ARGV'`: that kills the command and
# leaves its children, and a child still holding the command's stdout keeps the
# caller's $(...) open until it exits, so the bound bounded nothing the prompt
# waits on. The command runs in a process group of its own and the group is
# killed. A command ended by a signal exits 128 + the signal, never 0, so a
# killed query is not read as an answer. macOS ships no timeout(1).
_felix_graph_bounded() {
  perl -e '
    my $t = shift;
    my $pid = fork;
    exit 127 unless defined $pid;
    if ($pid == 0) { setpgrp(0, 0); exec @ARGV or exit 127 }
    $SIG{ALRM} = sub { kill "KILL", -$pid; waitpid($pid, 0); exit 142 };
    alarm $t;
    waitpid($pid, 0);
    exit(($? & 127) ? 128 + ($? & 127) : $? >> 8);
  ' "$@"
}

# Is <file> a shell script: named .sh, or a #! line naming sh, bash or zsh.
_felix_graph_is_shell() {
  local first=""
  case "$1" in *.sh) return 0 ;; esac
  IFS= read -r first 2>/dev/null < "$1" || [ -n "$first" ] || return 1
  case "$first" in
    '#!'*/sh|'#!'*/sh' '*|'#!'*' sh'|'#!'*' sh '*|'#!'*bash*|'#!'*zsh*) return 0 ;;
  esac
  return 1
}

# The answer as the block a session is handed, once per file per session, with
# the delivery recorded in the ledger and the files it named recorded where the
# post-tool hook can see what the session did next. Spec A2.
felix_graph_deliver() {
  local home="$1" session="${2:-}" root="${3:-$PWD}" prompt="${4:-}" rows state dir prior=""
  local kept="" files="" n=0 shell=0 line src loc rest label f gh stamp behind head
  local tab=$'\t' nl='
'
  [ -n "$session" ] || return 1
  rows="$(felix_graph_answer "$root" "$prompt")" || return 1
  dir="$home/state/answer"; state="$dir/$session.tsv"
  [ -f "$state" ] && prior="$(LC_ALL=C awk -F'\t' '$1 == "answer" && $2 == "graphify" { print $3 }' "$state" 2>/dev/null)"
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    src="${line%%"$tab"*}"
    case "$nl$prior$nl" in *"$nl$src$nl"*) continue ;; esac
    kept="$kept$line$nl"
    case "$nl$files" in *"$nl$src$nl"*) ;; *) files="$files$src$nl"; n=$((n + 1)) ;; esac
  done <<EOF
$rows
EOF
  [ "$n" -gt 0 ] || return 1

  # Recorded before it is said, and never at the cost of saying it: a lost
  # record is a lost measurement, and a lost block is the graph unused again.
  # Silenced outside the group, for the reason felix_answer_touch gives.
  if mkdir -p "$dir" 2>/dev/null; then
    { { printf 'given\tgraphify\t%s\n' "$n"
        while IFS= read -r src; do
          [ -n "$src" ] && printf 'answer\tgraphify\t%s\n' "$src"
        done <<EOF
$files
EOF
      } >> "$state"; } 2>/dev/null || true
  fi
  command -v felix_ledger_record >/dev/null 2>&1 \
    && felix_ledger_record "$home" "$session" "answer	graphify" 2>/dev/null

  f="$(felix_graph_file "$root")"; gh="${f%/graphify-out/graph.json}"
  if stamp="$(felix_graph_stamp "$f")" && behind="$(felix_graph_behind "$root" "$stamp")"; then
    if [ "$behind" -eq 0 ]; then
      head="graph built at
${stamp%"${stamp#???????}"}, current with the checkout that holds it"
    else
      head="graph built at
${stamp%"${stamp#???????}"}, ${behind} commit(s) behind the checkout that holds it"
    fi
  else
    head="graph carrying no build stamp"
  fi
  printf "The knowledge graph's answer to this prompt (graphify query, %s). Where it places what was asked, so you can open these\n" "$head"
  printf 'instead of searching for them:\n\n'
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    src="${line%%"$tab"*}"; rest="${line#*"$tab"}"
    loc="${rest%%"$tab"*}"; label="${rest#*"$tab"}"
    if [ -n "$loc" ]; then printf '  %s:%s  %s\n' "$src" "$loc" "$label"
    else                   printf '  %s  %s\n' "$src" "$label"; fi
    [ "$shell" = 1 ] || { _felix_graph_is_shell "$gh/$src" && shell=1; }
  done <<EOF
$kept
EOF
  if [ "$shell" = 1 ]; then
    printf '\nIt finds where things are, not who calls them: in shell scripts the graph\n'
    printf 'sees few callers, so for "what calls this" grep is still the oracle.\n'
  fi
  return 0
}
