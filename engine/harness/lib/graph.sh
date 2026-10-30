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
if ! command -v _felix_answer_sid_ok >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/answer.sh"
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
# file is not. Same shape as the discovery refresh, for the same reason, and a
# lock older than 30 minutes is broken as there: an update killed by SIGKILL or a
# power loss never runs its trap, and the graph would otherwise never refresh
# again (audit b06, C043). The update leaves no record.
felix_graph_refresh_bg() {
  local root="${1:-$PWD}" home lock
  command -v graphify >/dev/null 2>&1 || return 0
  home="$(felix_graph_home "$root")" || return 0
  [ -d "$home/graphify-out" ] || return 0
  lock="$home/graphify-out/.felix-refresh.lock"
  # The age is FELIX_GRAPH_LOCK_STALE minutes, 30 unless set (spec R3), and a
  # session end, the likeliest moment for a refresh to be killed, now starts
  # one (hooks/session-end). find, not stat, because the two stats disagree on
  # their flags.
  if [ -d "$lock" ] && [ -n "$(find "$lock" -maxdepth 0 -type d -mmin +"${FELIX_GRAPH_LOCK_STALE:-30}" 2>/dev/null)" ]; then
    rmdir "$lock" 2>/dev/null
  fi
  mkdir "$lock" 2>/dev/null || return 0   # already running; leave it alone
  (
    trap 'rmdir "$lock" 2>/dev/null' EXIT
    felix_close_inherited_fds
    cd "$home" 2>/dev/null || exit 0
    # What this refresh describes, read before it runs, and written only when
    # it succeeds. graphify writes nothing when the code's topology did not
    # change, so its stamp stays behind HEAD and, without this, every session
    # start and end ran another full update that could not clear it. A commit
    # landing during the run leaves the marker behind HEAD, so the next call
    # refreshes again, which is right.
    #
    # Written to a file made new for it and renamed into place, never through
    # `>`: a checkout can carry the marker as a link, and `>` would follow it
    # and overwrite whatever it names. Renamed by perl, which is rename(2)
    # itself: it replaces a link at the marker path and fails on a directory
    # there. mv is not: given a directory, or a link to one, it moves the file
    # inside. Not at all when graphify-out is itself a link, since then the
    # rename lands wherever that points.
    _at="$(git -C "$home" rev-parse HEAD 2>/dev/null)"
    if graphify update "$home" >/dev/null 2>&1 && [ -n "$_at" ] && [ ! -L "$home/graphify-out" ]; then
      _m="$home/graphify-out/.felix-refreshed-at"
      _t="$(mktemp "$_m.XXXXXX" 2>/dev/null)" \
        && { { printf '%s\n' "$_at" > "$_t" \
          && perl -e 'rename($ARGV[0], $ARGV[1]) or exit 1' "$_t" "$_m"; } 2>/dev/null || rm -f "$_t" 2>/dev/null; }
    fi
  ) </dev/null >/dev/null 2>&1 &
  return 0
}

# Due for a refresh: the stamp names a commit the holding checkout has, HEAD
# has moved past it, and no refresh has already run at this HEAD. Everything
# else, including a stamp nobody can read, is not due, because a refresh cannot
# make an unknown graph known. Spec A3 and A4.
#
# The marker is a file of the checkout, and session start asks this before its
# ownership gate. So only a regular file that is not a link is read, and only
# 64 bytes of it: a review planted the marker as a link to /dev/zero, and an
# unbounded read of it never returned and held session start until the
# platform killed the hook. Bytes in any locale: bash 5 counts `read -n` in
# characters under a UTF-8 one.
felix_graph_refresh_due() {
  local root="${1:-$PWD}" f stamp behind home head m mark="" LC_ALL=C
  f="$(felix_graph_file "$root")" || return 1
  stamp="$(felix_graph_stamp "$f")" || return 1
  behind="$(felix_graph_behind "$root" "$stamp")" || return 1
  [ "$behind" -gt 0 ] || return 1
  home="${f%/graphify-out/graph.json}"
  head="$(git -C "$home" rev-parse HEAD 2>/dev/null)" || return 1
  m="$home/graphify-out/.felix-refreshed-at"
  if [ -f "$m" ] && [ ! -L "$m" ]; then
    { IFS= read -r -n 64 mark < "$m"; } 2>/dev/null
  fi
  [ "$mark" != "$head" ]
}

# ---------------------------------------------------------------- answers ----
# The graph's answer, handed to the session rather than named to it.
#
# Everything above this line names the graph. Measured 2026-10-29: the line
# was in 193 sessions and the graph was queried in 3; the orient route named it
# in 15 and it was reached in none. Naming is advice, and forty lines of banner
# are where advice goes to be skimmed. So the hook asks the graph the prompt
# itself and puts what it returns in front of the model, and lib/answer.sh
# records the delivery and what the session did next.
#
# `query` and not `affected`, and that is a measurement too. Of the files that
# depend on each engine file, the graph links 16% (74 of 455): graphify's bash
# extractor resolves `source` only from felix and bin/, and an edge for a call
# inside $(...) is never made. `affected` on a file finds nothing at all,
# because it seeds through `contains` and bash files `defines`. An injected
# dependents list that short reads as complete, which is worse than none. What
# the graph does answer is where a thing is, and that is what is handed over,
# saying so when graphify cut it short.
#
# A hook may not call a model. graphify query loads graph.json with networkx and
# walks it: no model, no network, read in graphify 0.9.37's cli.py and serve.py.
# It runs under a bound (_felix_graph_bounded), so a prompt never waits on it
# for long. docs/2026-10-29-answers-delivered-spec.md, A1-A4.

# Can the graph be asked at all: switched on, a graph beside the checkout, and
# graphify and perl to ask it with. The cheap half of the hook's test, run
# before the ownership test and before the prompt is read (spec U1).
felix_graph_ready() {
  [ "${FELIX_GRAPH_ANSWER:-1}" = 0 ] && return 1
  felix_graph_file "${1:-$PWD}" >/dev/null 2>&1 || return 1
  command -v graphify >/dev/null 2>&1 || return 1
  command -v perl >/dev/null 2>&1 || return 1
}

# The prompt string out of a UserPromptSubmit payload, read to its first
# unescaped quote, with \" and \\ unescaped. Not felix_route_prompt, which
# returns the rest of the payload after the key: what is asked here must be the
# prompt and nothing after it.
#
# Linear in the payload. The first 16384 bytes after the opening quote, and the
# first line by sed: a review measured ${x%%"$nl"*} at 7.9 s on a 200 KB paste
# under bash 3.2 in a UTF-8 locale, because a JSON payload has no newline to
# stop it and bash 3.2 rescans the rest of the string at every offset. In the C
# locale, so the cut counts bytes whatever the hook's locale (a UTF-8 one kept
# 16384 characters, up to four times the bytes) and the scans do not convert
# the payload to wide characters first.
felix_graph_prompt() {
  local raw="$1" rest LC_ALL=C
  case "$raw" in *'"prompt"'*) ;; *) return 1 ;; esac
  rest="${raw#*\"prompt\"}"
  rest="${rest#*:}"
  rest="${rest#"${rest%%[![:space:]]*}"}"
  case "$rest" in \"*) rest="${rest#\"}" ;; *) return 1 ;; esac
  rest="${rest:0:16384}"
  printf '%s\n' "$rest" | LC_ALL=C sed -E -n -e '1{' -e 's/^(([^"\\]|\\.)*)".*$/\1/' \
    -e 's/\\(["\\])/\1/g' -e 'p' -e '}'
}

# Ask graphify about <prompt>: spec A1 steps 1-5. Prints graphify's output.
#   1    not asked: switched off, no graph, no graphify or perl, too few words
#   0    asked, and graphify printed something
#   142  asked, and the bound killed it at the deadline
#   3    asked, and graphify failed or printed nothing
_felix_graph_ask() {
  local root="${1:-$PWD}" prompt="${2:-}" f q words out rc tab=$'\t'
  felix_graph_ready "$root" || return 1
  f="$(felix_graph_file "$root")" || return 1
  # Whitespace, real or JSON-escaped, is one space; then the first 400
  # characters, because a long brief's opening is its subject and the rest only
  # widens what the traversal seeds on. Characters, not bytes: a byte cut can
  # end inside a UTF-8 sequence. Printed as words<TAB>question.
  q="$(printf '%s\n' "$prompt" | LC_ALL=C awk '
    { s = s " " $0 }
    END {
      gsub(/\\[ntr]/, " ", s); gsub(/[ \t\r]+/, " ", s); sub(/^ /, "", s); sub(/ $/, "", s)
      s = substr(s, 1, 1600); m = length(s); o = ""; k = 0
      for (i = 1; i <= m; i++) {
        c = substr(s, i, 1)
        if (c < "\200" || c >= "\300") { if (++k > 400) break }
        o = o c
      }
      sub(/ $/, "", o)
      printf "%d\t%s\n", split(o, w, " "), o
    }')"
  words="${q%%"$tab"*}"; q="${q#*"$tab"}"
  [ "${words:-0}" -ge "${FELIX_GRAPH_MIN_WORDS:-5}" ] 2>/dev/null || return 1
  out="$(_felix_graph_bounded "${FELIX_GRAPH_TIMEOUT:-4}" \
           graphify query "$q" --budget "${FELIX_GRAPH_BUDGET:-600}" --graph "$f" 2>/dev/null)"
  rc=$?
  [ "$rc" = 142 ] && return 142
  [ "$rc" = 0 ] && [ -n "$out" ] || return 3
  printf '%s\n' "$out"
}

# graphify's output on stdin, its nodes out as src<TAB>loc<TAB>label: spec A1
# steps 6-8, against the holding checkout <home>.
_felix_graph_rows() {
  local home="$1" files="${FELIX_GRAPH_FILES:-8}" parsed line src loc rest label n=0 rows=0 seen=""
  local tab=$'\t' nl='
'
  # NODE <label> [src=<src> loc=<loc> community=<c>]. Split on the field
  # markers rather than on spaces, since labels carry spaces; `None` is how
  # graphify prints a node with no location. Control bytes, tabs among them,
  # leave all three fields here, so nothing after this has a tab inside a field
  # and nothing reaches the hook's JSON that its escaper does not handle. The
  # label is cut by characters: a byte cut can end inside a UTF-8 sequence.
  parsed="$(LC_ALL=C awk '
    function cut(s, m,   i, c, k, o, n) {
      o = ""; k = 0; n = length(s)
      for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if (c < "\200" || c >= "\300") { if (++k > m) break }
        o = o c
      }
      return o
    }
    /^NODE / {
      line = substr($0, 6)
      i = index(line, " [src="); if (!i) next
      label = substr(line, 1, i - 1); rest = substr(line, i + 6)
      j = index(rest, " loc="); if (!j) next
      src = substr(rest, 1, j - 1); rest = substr(rest, j + 5)
      k = index(rest, " community="); if (!k) k = index(rest, "]"); if (!k) next
      loc = substr(rest, 1, k - 1); if (loc == "None") loc = ""
      gsub(/[[:cntrl:]]/, "", src); gsub(/[[:cntrl:]]/, "", loc)
      gsub(/[[:cntrl:]]/, "", label); label = cut(label, 120)
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
  return 0
}

# The graph's answer to <prompt>: src<TAB>loc<TAB>label per node, or nothing
# and 1. Spec A1.
felix_graph_answer() {
  local root="${1:-$PWD}" out rows f
  out="$(_felix_graph_ask "$root" "${2:-}")" || return 1
  f="$(felix_graph_file "$root")" || return 1
  rows="$(printf '%s\n' "$out" | _felix_graph_rows "${f%/graphify-out/graph.json}")"
  [ -n "$rows" ] || return 1
  printf '%s\n' "$rows"
}

# <command> run for at most <seconds>, then killed with everything it started.
#
# Not a bare `perl -e 'alarm shift; exec @ARGV'`: that kills the command and
# leaves its children, and a child still holding the command's stdout keeps the
# caller's $(...) open until it exits, so the bound bounded nothing the prompt
# waits on. The command runs in a process group of its own, set by both sides
# of the fork so the alarm cannot land before the group exists, and the group
# is killed at the deadline and again after the command exits, for anything it
# left behind: signalled until none of it is left, because on macOS a member
# being forked or exec'd at the instant of one kill can miss it. A command
# ended by a signal exits 128 + the signal, never 0, so a killed query is not
# read as an answer. A deadline that is not a whole number of one or more is
# the default: alarm(0) cancels the alarm, and no setting may remove the bound.
# macOS ships no timeout(1).
_felix_graph_bounded() {
  perl -e '
    my $t = shift;
    $t = 4 unless defined $t && $t =~ /\A[0-9]+\z/ && $t > 0;
    my $pid = fork;
    exit 127 unless defined $pid;
    if ($pid == 0) { setpgrp(0, 0); exec @ARGV or exit 127 }
    setpgrp($pid, $pid);
    my $sweep = sub { for (1 .. 20) { kill("KILL", -$pid) or last; select(undef, undef, undef, 0.01) } };
    $SIG{ALRM} = sub { kill "KILL", -$pid; waitpid($pid, 0); $sweep->(); exit 142 };
    alarm $t;
    waitpid($pid, 0);
    my $st = $?;
    alarm 0;
    $sweep->();
    exit(($st & 127) ? 128 + ($st & 127) : $st >> 8);
  ' "$@"
}

# Is <file> a shell script: named .sh, or a #! line naming sh, bash or zsh.
# The first 128 bytes only, since an answer can name a minified file whose
# first line is the whole file; bytes in the C locale, because GNU bash's read
# -n counts characters in a UTF-8 one and CI would classify differently.
_felix_graph_is_shell() {
  local first="" LC_ALL=C
  case "$1" in *.sh) return 0 ;; esac
  [ -f "$1" ] || return 1
  { IFS= read -r -n 128 first < "$1"; } 2>/dev/null || [ -n "$first" ] || return 1
  case "$first" in
    '#!'*/sh|'#!'*/sh' '*|'#!'*' sh'|'#!'*' sh '*|'#!'*bash*|'#!'*zsh*) return 0 ;;
  esac
  return 1
}

# The answer as the block a session is handed, each node once a session, with
# every ask and what it gave recorded where the post-tool hook and
# felix_answer_use can see it (lib/answer.sh). Spec A2.
felix_graph_deliver() {
  local home="$1" session="${2:-}" root="${3:-$PWD}" prompt="${4:-}" out rc rows state dir
  local prior="" kept="" files="" n=0 k=0 shell=0 line src loc rest label f gh top stamp behind head found
  local roots="" r tab=$'\t' nl='
'
  _felix_answer_sid_ok "$session" || return 1
  out="$(_felix_graph_ask "$root" "$prompt")"; rc=$?
  [ "$rc" = 1 ] && return 1
  dir="$home/state/answer"; state="$dir/$session.tsv"
  mkdir -p "$dir" 2>/dev/null
  # Every ask is written down, answered or not. Under load graphify reaches the
  # bound and the prompt is told nothing, and a record of deliveries alone could
  # not say how many asks that was. Silenced outside the group: a redirection
  # that fails reports on the stderr in force before it.
  case "$rc" in
    142) { printf 'asked\tgraphify\ttimeout\n' >> "$state"; } 2>/dev/null; return 1 ;;
    0)   ;;
    *)   { printf 'asked\tgraphify\tfailed\n' >> "$state"; } 2>/dev/null; return 1 ;;
  esac
  f="$(felix_graph_file "$root")"; gh="${f%/graphify-out/graph.json}"
  rows="$(printf '%s\n' "$out" | _felix_graph_rows "$gh")"
  if [ -z "$rows" ]; then
    { printf 'asked\tgraphify\tempty\n' >> "$state"; } 2>/dev/null; return 1
  fi
  # Once per node, not per file: a later question about a symbol in a file
  # named earlier still gets its line, which is the part the graph is right
  # about. A review found file-level dedupe withholding exactly that. In awk,
  # because a long session's record is too long for a bash pattern match.
  prior="$state"; [ -f "$prior" ] || prior=/dev/null
  kept="$(printf '%s\n' "$rows" | LC_ALL=C awk -F'\t' '
    phase == 1 { if ($1 == "node" && $2 == "graphify") had[$3 "\t" $4 "\t" $5] = 1; next }
    $0 != "" && !($0 in had) { had[$0] = 1; print }' phase=1 "$prior" phase=2 - 2>/dev/null)"
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    k=$((k + 1))
    src="${line%%"$tab"*}"
    case "$nl$files" in *"$nl$src$nl"*) ;; *) files="$files$src$nl"; n=$((n + 1)) ;; esac
  done <<EOF
$kept
EOF
  if [ "$n" -eq 0 ]; then
    { printf 'asked\tgraphify\trepeat\n' >> "$state"; } 2>/dev/null; return 1
  fi
  # How many nodes graphify found, from the end of its first line, `... | <n>
  # nodes found`, so a list it cut to its budget is said to be partial: its own
  # notice exists so that a truncated answer is never mistaken for a complete
  # one. The end, because the line before it lists labels.
  found="$(printf '%s\n' "$out" | LC_ALL=C awk 'NR == 1 && match($0, /\| [0-9]+ nodes? found[ \r]*$/) {
             s = substr($0, RSTART, RLENGTH); gsub(/[^0-9]/, "", s); print s }')"
  [ -n "$found" ] || found="-"
  # The roots a touched path can be anchored to: the session's working tree and
  # the checkout the graph describes, each once a session.
  top="$(git -C "$root" rev-parse --show-toplevel 2>/dev/null)"
  [ -f "$state" ] && roots="$(LC_ALL=C awk -F'\t' '$1 == "root" { print $2 }' "$state" 2>/dev/null)"

  # Recorded before it is said, and never at the cost of saying it: a lost
  # record is a lost measurement, and a lost block is the graph unused again.
  { { printf 'asked\tgraphify\tanswered\n'
      for r in "$top" "$gh"; do
        [ -n "$r" ] || continue
        case "$nl$roots$nl" in *"$nl$r$nl"*) continue ;; esac
        printf 'root\t%s\n' "$r"; roots="$roots$nl$r"
      done
      printf 'given\tgraphify\t%s\t%s\n' "$n" "$found"
      while IFS= read -r line; do
        [ -n "$line" ] && printf 'node\tgraphify\t%s\n' "$line"
      done <<EOF
$kept
EOF
      while IFS= read -r src; do
        [ -n "$src" ] && printf 'answer\tgraphify\t%s\n' "$src"
      done <<EOF
$files
EOF
    } >> "$state"; } 2>/dev/null || true
  command -v felix_ledger_record >/dev/null 2>&1 \
    && felix_ledger_record "$home" "$session" "answer	graphify" 2>/dev/null

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
  printf "The knowledge graph's answer to this prompt (graphify query, %s). Where it places what was asked, to open first:\n\n" "$head"
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
  case "$found" in
    ''|*[!0123456789]*) ;;
    *) if [ "$found" -gt "$k" ]; then
         printf '\nThese are %s of the %s nodes graphify found for it; graphify query\n' "$k" "$found"
         printf 'with a larger --budget shows more.\n'
       fi ;;
  esac
  if [ "$shell" = 1 ]; then
    printf '\nIt finds where things are, not who calls them: in shell scripts the graph\n'
    printf 'sees few callers, so for "what calls this" grep is still the oracle.\n'
  fi
  return 0
}
