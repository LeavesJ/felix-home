# Intent routing.
#
# Felix knows what a project has (stack.tsv), what a kind of work needs
# (profiles.tsv), and what a change risks (risk.tsv). It did not know what the
# current prompt was about, so none of that reached the session while it could
# still change the outcome. Choosing tools stayed manual, and with enough
# options manual means the good ones go unused: a capability nobody remembers to
# invoke is indistinguishable from one nobody installed.
#
# One new link in a chain that was otherwise built:
#
#   prompt + tree -> routes.tsv -> profiles.tsv -> stack.tsv -> the play
#
# A model classifier was designed for the miss case and rejected on measurement,
# not on principle: 4.9-8.6s per call through the CLI, of which about 2s is
# process startup that --effort low does not touch, and --json-schema costs 31x
# more because it forces a tool-use round trip. Quality was fine. A router that
# adds five seconds to a prompt is not a router anyone keeps. The table learns
# from its misses instead, through felix route --promote.
#
# Everything here reads files. Nothing calls the network, and nothing queries
# live mount state: `claude mcp list` runs health checks, and a hook that waits
# on those before every prompt is a hook that gets removed. Declared-versus-not
# is the useful signal here anyway; live mounting is the reconciler's job.

FELIX_ROUTE_MIN_SCORE="${FELIX_ROUTE_MIN_SCORE:-2}"
FELIX_ROUTE_PROMOTE_MIN="${FELIX_ROUTE_PROMOTE_MIN:-3}"

# Only rows with all four fields. A malformed row is skipped rather than fatal:
# one bad line must not silently stop the whole table from routing.
_felix_route_rows() {
  local proj="$1" n p pr pl
  [ -f "$proj/routes.tsv" ] || return 0
  while IFS=$'\t' read -r n p pr pl; do
    case "$n" in ''|'#'*) continue ;; esac
    [ -n "${pr:-}" ] || continue
    printf '%s\t%s\t%s\t%s\n' "$n" "$p" "$pr" "${pl:--}"
  done < "$proj/routes.tsv"
}

# Same filter the lessons matcher uses, for the same reason: short words and
# filler match everything and would decide what you meant on the word "the".
felix_route_tokens() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' \
    | tr -cs 'a-z0-9_-' '\n' \
    | grep -E '^.{4,}$' \
    | grep -vE '^(this|that|with|from|have|been|will|when|what|there|their|would|could|should|about|into|then|than|they|them|your|make|does|just|also|only|some|more|most|need|want|please|help|file|code|lets)$' \
    | sort -u
}

# Where you are standing: the branch name, and every path git considers changed
# including untracked ones. `git diff --name-only` was not enough — a brand new
# file is exactly the kind of change that says what the work is about.
#
# `-uall` matters more than it looks. Plain porcelain collapses a wholly new
# directory into one `?? ui/` entry, so starting a feature by creating a folder
# of files contributes a single two-letter token and routes nothing. That is
# precisely the moment the router should have the most to say.
felix_route_context() {
  local root="$1"
  git -C "$root" status --porcelain -uall 2>/dev/null | cut -c4- | tr '/._-' '    '
  git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null | tr '/-_' '   '
}

# score <TAB> promptscore <TAB> order <TAB> name <TAB> profile <TAB> play, best first.
#
# Prompt words score two and context words one. Each distinct keyword counts at
# most once however often it occurs, so a repeated word cannot dominate. Ties
# break by file order, which is why the table is written specific-to-general.
#
# promptscore is carried separately so the caller can tell a route you asked for
# from one the working tree decided. Both are legitimate — two corroborating
# tree tokens meet the threshold on purpose — but they are different claims, and
# a block that presents the second as the first is quietly lying about why.
felix_route_score() {
  local proj="$1" prompt="$2" ctx="$3"
  local ptok ctok i=0
  ptok="$(felix_route_tokens "$prompt")"
  ctok="$(felix_route_tokens "$ctx")"
  while IFS=$'\t' read -r name kws profile play; do
    [ -n "${name:-}" ] || continue
    i=$((i+1))
    local score=0 pscore=0 kw t hit
    for kw in $kws; do
      hit=0
      while IFS= read -r t; do
        [ -n "$t" ] || continue
        case "$t" in *"$kw"*) hit=2; break ;; esac
      done <<EOF
$ptok
EOF
      if [ "$hit" -eq 0 ]; then
        while IFS= read -r t; do
          [ -n "$t" ] || continue
          case "$t" in *"$kw"*) hit=1; break ;; esac
        done <<EOF
$ctok
EOF
      fi
      score=$((score + hit))
      [ "$hit" -eq 2 ] && pscore=$((pscore + 2))
    done
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$score" "$pscore" "$i" "$name" "$profile" "$play"
  done <<EOF
$(_felix_route_rows "$proj")
EOF
}

felix_route_best() {
  local line
  line="$(felix_route_score "$1" "$2" "$3" | sort -k1,1nr -k3,3n | head -1)"
  [ -n "$line" ] || return 1
  [ "$(printf '%s' "$line" | cut -f1)" -ge "$FELIX_ROUTE_MIN_SCORE" ] || return 1
  printf '%s' "$line"
}

# What kind of thing a play entry is, according to what the project declared.
#
# Three shapes have to resolve against one manifest. A bare name matches a stack
# row named exactly that, or one qualifying it with a marketplace, so
# `playwright` finds `playwright@claude-plugins-official`. A qualified skill —
# `superpowers:brainstorming`, which is what Claude Code itself calls it — is
# owned by a plugin, and the manifest declares the plugin rather than each of
# its fourteen skills, so the part before the colon is what gets looked up.
# Without that, every play naming a real skill would report itself missing.
_felix_route_kind() {
  local proj="$1" want="$2" owner="$1" kind name
  [ -f "$proj/stack.tsv" ] || { printf 'not declared'; return; }
  case "$want" in
    *:*) owner="${want%%:*}" ;;
    *)   owner="$want" ;;
  esac
  while IFS=$'\t' read -r kind name _rest; do
    case "$kind" in ''|'#'*) continue ;; esac
    case "$name" in
      "$want"|"$want@"*)   printf '%s' "$kind"; return ;;
      "$owner"|"$owner@"*) printf 'skill'; return ;;
    esac
  done < "$proj/stack.tsv"
  printf 'not declared'
}

# The block. Written as an instruction to the model, because that is what it is:
# additionalContext is never rendered to the user, and every context-injecting
# hook on this machine writes second person for the same reason.
felix_route_render() {
  local proj="$1" name="$2" play="$3" root="$4" pscore="${5:-1}" p kind missing=""
  printf 'Felix routed this to: %s\n' "$name"
  [ "${pscore:-1}" -eq 0 ] && \
    printf 'Read off the working tree, not the prompt: nothing you typed named a\nkind of work, so this is a guess from what is currently changed.\n'
  if [ "$play" != "-" ] && [ -n "$play" ]; then
    printf '\nUse these, in this order:\n'
    for p in $play; do
      kind="$(_felix_route_kind "$proj" "$p")"
      printf '  %-22s %s\n' "$p" "$kind"
      [ "$kind" = "not declared" ] && missing="$missing $p"
    done
  fi
  [ -n "$missing" ] && printf '\nNot declared for this project:%s\n' "$missing"
  _felix_route_red "$proj" "$root"
}

# A router that hands you fast tools while you edit the authorization model is
# worse than no router. Only fires when the working tree actually touches a red
# path, and only when the project declared any.
_felix_route_red() {
  local proj="$1" root="$2" paths sev
  [ -f "$proj/risk.tsv" ] || return 0
  command -v felix_incident_severity >/dev/null 2>&1 || return 0
  paths="$(git -C "$root" status --porcelain 2>/dev/null | cut -c4- | grep -v '^$')"
  [ -n "$paths" ] || return 0
  sev="$(felix_incident_severity "$proj" "$paths")"
  [ "$sev" = "red" ] || return 0
  printf '\nThis working tree touches a path the project calls red. A person\n'
  printf 'decides here: show the change and its reversal before touching it.\n'
}

# Hits and misses both. The misses are the raw material for --promote, and they
# are the only record of what the table failed to understand.
felix_route_log() {
  local proj="$1" name="$2" score="$3" prompt="$4"
  [ -d "$proj/memory" ] || return 0
  printf '%s\t%s\t%s\t%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${name:--}" "${score:-0}" \
    "$(printf '%s' "$prompt" | tr '\t\n' '  ' | cut -c1-160)" \
    >> "$proj/memory/routes.log" 2>/dev/null || true
}

# Words that keep turning up in prompts the table did not understand.
#
# Frequency, not understanding — the same caveat felix promote already prints
# about the devlog. Felix does not edit routes.tsv itself, for the reason
# felix lesson is a command rather than an inference.
felix_route_promote() {
  local proj="$1" log="$proj/memory/routes.log"
  [ -f "$log" ] || return 0
  awk -F'\t' '$2 == "-" { print $4 }' "$log" \
    | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9_-' '\n' \
    | grep -E '^.{4,}$' \
    | sort | uniq -c | sort -rn \
    | awk -v m="$FELIX_ROUTE_PROMOTE_MIN" '$1 >= m { print $1 "\t" $2 }'
}
