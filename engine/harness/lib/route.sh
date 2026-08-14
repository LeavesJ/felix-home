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
# How much the working tree may contribute, in total, however many of its
# tokens match. Two is exactly the threshold, so a tree can still route when you
# said nothing routable — and can never outvote a word you actually typed.
#
# Uncapped, this fails in the ordinary case rather than a contrived one. A
# checkout carrying a couple of untracked backup directories offers a few
# hundred path tokens; against that, a sentence contributing four is inaudible,
# and prompts route to whatever the stale directories happen to be about.
FELIX_ROUTE_CONTEXT_CAP="${FELIX_ROUTE_CONTEXT_CAP:-2}"

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
# The hook is handed the whole payload rather than a parsed prompt, on purpose,
# so the envelope's own field names are in the token stream: session_id, prompt,
# transcript_path, permission_mode and the rest. Any route keyed on one of those
# scored on every turn whatever was typed, and a project whose subject matter IS
# prompts sent everything to one route.
#
# The first fix was a blacklist of those words, and it was worse than the bug:
# `hook` and `prompt` are words people type. Asking about a hook matched nothing
# at all, because the word had been banned to silence a field name.
#
# So the keys are removed and the values are kept. A JSON key is a quoted word
# followed by a colon, which no sentence contains, and stripping those leaves
# every real word usable — including the ones that happen to share a name with
# a field.
# Stripping the keys was half the job, and the half that showed. The VALUES the
# runtime fills in are still machine-generated text nobody typed: transcript_path
# and cwd carry the entire checkout path, so a home directory named Documents put
# "documents" into every prompt, and a branch named ...-review-... put "review"
# there too — both at the double weight reserved for what you actually said. The
# word `continue` routed to a document skill, and the score was a clean 2 typed.
#
# So the pairs are removed whole, key and value together, for the fields the
# runtime owns. `prompt` is deliberately not among them: its value is the one
# thing in the envelope a person did type. A path typed inside the prompt still
# counts, because that is a word you chose.
# LC_ALL=C on every text stage, and it is load-bearing rather than tidy.
#
# `cut -c` is byte-oriented in the environment the hook actually runs in — LANG
# unset, LC_CTYPE=C — so a prompt truncated at 160 can keep half of a multibyte
# character. Reading that back through `sed -E` under the UTF-8 locale a
# Terminal has raises "illegal byte sequence" and, with `set -o pipefail`, takes
# the whole pipeline down. In the C locale every byte is a valid character and
# no stage can refuse a line. Nothing here is doing character-aware work: the
# patterns are ASCII and the tokeniser splits on an ASCII class.
#
# It also makes the two userlands agree on what a truncated prompt contains.
# Before this the same prompt logged 160 characters on a laptop and 160 bytes on
# CI, so the recorded evidence differed by machine.
_felix_envelope_strip() {
  LC_ALL=C sed -E 's/"(session_id|transcript_path|cwd|permission_mode|hook_event_name|session_title|source|model|version)"[[:space:]]*:[[:space:]]*("[^"]*"|[^,}]*)/ /g'
}

# What a person actually typed, with the JSON around it gone: the runtime's own
# pairs removed whole, and then every remaining key removed but not its value.
#
# Its own function because the reader needed it and did not have it. Recording
# the payload with only half this applied put the literal words `prompt` and
# `prompt_id` into every miss, and they were the top two rows of
# `felix route --promote` — above every word anybody had typed, in the one
# report that exists to improve the routing table.
#
# Applied on the way OUT only, which also cleans rows written before any of this.
# The first fix applied it on the way in as well and broke `felix monitor`: its
# route panel finds the sentence by looking for the literal `"prompt":` key, so
# stripping keys at write time made every new row render as the JSON around the
# sentence instead of the sentence. The log is a record for a person to read.
# Nothing promote needs is lost by leaving the keys in it.
_felix_envelope_text() {
  _felix_envelope_strip | LC_ALL=C sed 's/"[A-Za-z_][A-Za-z0-9_]*"[[:space:]]*:/ /g'
}

# The words a route may be scored on. Frequency order is the caller's business,
# which is the only reason this is not felix_route_tokens itself: promote counts
# repeats and the router does not.
#
# There were two of these and they drifted. Anything the router discards must be
# absent from promote as well, or the report proposes keywords that could never
# have matched.
_felix_route_words() {
  export LC_ALL=C
  _felix_envelope_text \
    | tr '[:upper:]' '[:lower:]' \
    | tr -cs 'a-z0-9_-' '\n' \
    | grep -E '^.{4,}$' \
    | grep -vE '^(this|that|with|from|have|been|will|when|what|there|their|would|could|should|about|into|then|than|they|them|your|make|does|just|also|only|some|more|most|need|want|please|help|file|code|lets)$' \
    | grep -vE '^(true|false|null)$'
}

felix_route_tokens() {
  printf '%s' "$1" | _felix_route_words | sort -u
}

# Whether this payload is the runtime talking to itself rather than a person.
#
# UserPromptSubmit carries more than what somebody typed: task completions,
# system reminders, and the Stop hook's own feedback all arrive on the same
# channel. Five of the first 89 rows in Felix's own miss log were machine text
# scored as a prompt, and they picked real routes — three `harness`, one
# `research`, one `gate`. Each one announced a play at text nobody wrote, put a
# row in the log that skews `--promote`, and then had the Stop hook ask why the
# named play went unused. That last one is a loop: a question generated by a
# route that fired on a machine's own message.
#
# Structure, never vocabulary. `<task-notification>` opening the payload is a
# tag no sentence begins with; the word "notification" is one people type, and
# this project has already broken a word once by banning it to silence a field
# name. So this anchors at the start and matches the marker, not the noun —
# asking "why did the task-notification route to harness?" is still a prompt.
#
# Erring toward "a person typed it" is the safe direction: a false positive
# costs one turn of silence, a false negative is the loop above.
# The prompt value out of a hook payload, from the FIRST occurrence of the key.
#
# Parameter expansion rather than sed, because `#` is shortest-match-from-left
# and POSIX sed has no non-greedy form: `s/.*"prompt"...` would bind to the LAST
# copy of the key, and this project already has a lesson about a later copy in
# the envelope being read in preference to the real one. Returns the remainder
# of the payload after the opening quote, which is all a prefix test needs.
felix_route_prompt() {
  local raw="$1" rest
  case "$raw" in *'"prompt"'*) ;; *) return 1 ;; esac
  rest="${raw#*\"prompt\"}"
  rest="${rest#*:}"
  rest="${rest#"${rest%%[![:space:]]*}"}"
  rest="${rest#\"}"
  printf '%s' "$rest"
}

felix_route_is_machine() {
  local p="$1"
  [ -n "$p" ] || return 1
  # Leading whitespace only; anything else before the marker means prose.
  p="${p#"${p%%[![:space:]]*}"}"
  case "$p" in
    '<task-notification>'*|'<system-reminder>'*|'Stop hook feedback:'*|\
    '[SYSTEM NOTIFICATION'*) return 0 ;;
  esac
  return 1
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
  local phay chay i=0
  # One space-delimited haystack per source, tested once per keyword, rather
  # than a nested loop re-reading a heredoc for every keyword. Same answer,
  # and the keyword can no longer span a token boundary because the tokens are
  # separated by spaces and keywords never contain one.
  phay=" $(felix_route_tokens "$prompt" | tr '\n' ' ')"
  chay=" $(felix_route_tokens "$ctx"    | tr '\n' ' ')"
  while IFS=$'\t' read -r name kws profile play; do
    [ -n "${name:-}" ] || continue
    i=$((i+1))
    local pscore=0 cscore=0 kw
    for kw in $kws; do
      case "$phay" in
        *"$kw"*) pscore=$((pscore + 2)); continue ;;
      esac
      case "$chay" in
        *"$kw"*) cscore=$((cscore + 1)) ;;
      esac
    done
    [ "$cscore" -gt "$FELIX_ROUTE_CONTEXT_CAP" ] && cscore="$FELIX_ROUTE_CONTEXT_CAP"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$((pscore + cscore))" "$pscore" "$cscore" "$i" "$name" "$profile" "$play"
  done <<EOF
$(_felix_route_rows "$proj")
EOF
}

# Ordered by what you typed first, then by the tree, then by file order.
#
# Sorting on the total let a route win on tree tokens alone against a route you
# had actually named. The prompt is the claim; the tree only corroborates.
felix_route_best() {
  local line
  line="$(felix_route_score "$1" "$2" "$3" | sort -k2,2nr -k3,3nr -k4,4n | head -1)"
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
# Worded as a requirement, because politeness does not survive contact with a
# model that has its own plan. The nearby superpowers hook is the proof: it says
# YOU DO NOT HAVE A CHOICE and it fires reliably, while "use these, in this
# order" was read as a suggestion and skipped.
#
# The escape is named rather than removed. An agent that silently ignores a bad
# route teaches nobody anything; one that says "this looks like backend work,
# not frontend" surfaces a keyword worth fixing. Obedience is not the goal —
# the goal is that skipping costs a sentence.
felix_route_render() {
  local proj="$1" name="$2" play="$3" root="$4" pscore="${5:-1}" transcript="${6:-}"
  local p kind due rest
  printf 'Felix routed this to: %s\n' "$name"
  [ "${pscore:-1}" -eq 0 ] && \
    printf 'Read off the working tree, not the prompt: nothing you typed named a\nkind of work, so this is a guess from what is currently changed.\n'

  if [ "$play" != "-" ] && [ -n "$play" ]; then
    if due="$(felix_route_due "$transcript" "$play")"; then
      rest="$(printf '%s' "$due" | cut -f2)"
      due="$(printf '%s' "$due" | cut -f1)"
      kind="$(_felix_route_kind "$proj" "$due")"

      if [ "$kind" = "not declared" ]; then
        printf '\nThis kind of work wants %s, which this project has not declared and\n' "$due"
        printf 'is not installed here. Carry on without it and say that you did.\n'
      else
        printf '\nUse this now: %s (%s)\n' "$due" "$kind"
        printf '\nThis is a requirement, not a suggestion. This project already decided\n'
        printf 'that work of this kind goes through it, and the decision is not yours\n'
        printf 'to skip quietly. If the routing is wrong, say so and choose otherwise —\n'
        printf 'but say it out loud, because a route that keeps guessing wrong is a bug\n'
        printf 'in a table someone can fix, and silence is how it stays broken.\n'
      fi
      [ -n "$rest" ] && \
        printf '\nLater, only if the work actually reaches them: %s\n' "$rest"
    fi
  fi
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

# Has a play step actually been used in this session?
#
# The session transcript records it three ways depending on what the step is: a
# skill carries an attribution, a plugin's skill carries its owner, and a plugin
# that ships an MCP server shows up as a tool name. Checked with grep rather
# than parsed — 21ms against a 5MB transcript, and no JSON reader in an engine
# that promises only bash and git.
felix_route_step_used() {
  local transcript="$1" step="$2" owner
  [ -n "$transcript" ] && [ -f "$transcript" ] || return 1
  case "$step" in *:*) owner="${step%%:*}" ;; *) owner="$step" ;; esac
  grep -q "\"attributionSkill\":\"$step\""    "$transcript" 2>/dev/null && return 0
  grep -q "\"attributionSkill\":\"$owner"     "$transcript" 2>/dev/null && return 0
  grep -q "\"attributionPlugin\":\"$owner\""  "$transcript" 2>/dev/null && return 0
  grep -qE "\"name\":\"mcp__[^\"]*$owner"     "$transcript" 2>/dev/null && return 0
  return 1
}

# The first step of a play that has not been used yet, and everything after it.
#
# Naming the whole play at the first prompt tells an agent to critique and
# browser-test something that does not exist, and spends context saying it. A
# play is a sequence, so only the step that is actually due gets named; the rest
# arrive as the work reaches them, or not at all if it never does.
felix_route_due() {
  local transcript="$1" play="$2" p due="" rest=""
  [ -n "$play" ] && [ "$play" != "-" ] || return 1
  for p in $play; do
    if [ -z "$due" ]; then
      felix_route_step_used "$transcript" "$p" && continue
      due="$p"
    else
      rest="$rest $p"
    fi
  done
  [ -n "$due" ] || return 1
  printf '%s\t%s' "$due" "${rest# }"
}

# Steps a route asked for that the session never used. Read at the finish line,
# where "you are about to call this done and never opened a browser" is a fact
# about the work rather than a rule quoted at turn one.
felix_route_skipped() {
  local transcript="$1" play="$2" p out=""
  [ -n "$play" ] && [ "$play" != "-" ] || return 0
  for p in $play; do
    felix_route_step_used "$transcript" "$p" || out="$out $p"
  done
  printf '%s' "${out# }"
}

# Add a tool to a route's play, in place.
#
# Appended, never reordered. A play is ordered — the router names the first
# entry that has not been used yet — so rewriting one to insert something would
# change what a session is told to reach for first, which is not what "also make
# this reachable" means.
#
# Comments and row order are preserved because this table is written by hand and
# its comments explain why rows sit where they do. Returns 1 when the route does
# not exist or already names the tool, so a caller can tell "wired" from
# "nothing to do".
felix_route_append_play() {
  local proj="$1" route="$2" tool="$3" tmp line n kw pr play found=0
  # Declared separately. A `local` statement does not reliably see a variable
  # being declared by the same statement, and under `set -u` that is an unbound
  # variable rather than an empty one.
  local f="$proj/routes.tsv"
  [ -f "$f" ] || return 1
  [ -n "$route" ] && [ -n "$tool" ] || return 1
  tmp="$(mktemp)" || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      ''|'#'*) printf '%s\n' "$line" >> "$tmp"; continue ;;
    esac
    IFS=$'\t' read -r n kw pr play <<EOF
$line
EOF
    if [ "${n:-}" = "$route" ]; then
      case " ${play:-} " in
        *" $tool "*) : ;;                       # already there
        *)
          # `-` is the template's way of writing "no play", so it is replaced
          # rather than appended to. Leaving it would emit "- playwright", and
          # the router would try to name a tool called "-".
          case "${play:-}" in
            ''|'-') play="$tool" ;;
            *)      play="$play $tool" ;;
          esac
          found=1 ;;
      esac
      printf '%s\t%s\t%s\t%s\n' "$n" "$kw" "$pr" "$play" >> "$tmp"
    else
      printf '%s\n' "$line" >> "$tmp"
    fi
  done < "$f"
  [ "$found" -eq 1 ] || { rm -f "$tmp"; return 1; }
  mv -f "$tmp" "$f"
}

# Hits and misses both. The misses are the raw material for --promote, and they
# are the only record of what the table failed to understand.
felix_route_log() {
  local proj="$1" name="$2" score="$3" prompt="$4"
  local mem; mem="$(felix_mem_dir "$proj")"
  [ -d "$mem" ] || mkdir -p "$mem" 2>/dev/null || return 0
  printf '%s\t%s\t%s\t%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${name:--}" "${score:-0}" \
    "$(printf '%s' "$prompt" | _felix_envelope_strip | tr '\t\n' '  ' | LC_ALL=C cut -c1-160)" \
    >> "$mem/routes.log" 2>/dev/null || true
}

# Words that keep turning up in prompts the table did not understand.
#
# Frequency, not understanding — the same caveat felix promote already prints
# about the devlog. Felix does not edit routes.tsv itself, for the reason
# felix lesson is a command rather than an inference.
# Whether a recorded route was Felix's guess rather than something asked for.
#
# Lives here rather than inside the Stop hook so it can be tested at all. The
# first version of this decision was hook-internal, and the test written for it
# was vacuous — it drove the whole hook through a fixture whose transcript path
# was empty, so the complaint never fired in either direction and the assertion
# that it stayed quiet passed by finding nothing.
#
# Tab-separated second field. Not a third colon field: a due step is a play
# entry and play entries contain colons, so a colon scheme silently read part of
# the step name instead — and did, in production, while every fixture using a
# due step of `done` passed. Anything that is not `tree` means somebody
# typed words that chose this route, including the empty third field of a state
# file written before provenance existed — which complains, exactly as it did
# before. Hooks bind at session start, so writer and reader are always the same
# version and that case is only ever a stale file from a session that is gone.
felix_route_state_guessed() {
  local state="$1"
  [ -f "$state" ] || return 1
  case "$(cut -f2 < "$state" 2>/dev/null)" in
    tree) return 0 ;;
    *)    return 1 ;;
  esac
}

felix_route_promote() {
  # Two `local` statements, not one. `local proj="$1" log="$proj/…"` expands
  # every word before it assigns any of them, so `$proj` was read before it
  # existed and this looked for `/memory/routes.log` — absent, so the function
  # returned nothing and reported no misses at all. It appeared to work from the
  # CLI and only from there: `cmd_route` happens to hold a variable called
  # `proj`, and bash's scoping handed that one over. Correct output from the one
  # caller anybody ran, and silence from every other.
  local proj="$1"
  local log="$(felix_mem_dir "$proj")/routes.log"
  [ -f "$log" ] || return 0
  awk -F'\t' '$2 == "-" { print $4 }' "$log" \
    | _felix_route_words \
    | sort | uniq -c | sort -rn \
    | awk -v m="$FELIX_ROUTE_PROMOTE_MIN" '$1 >= m { print $1 "\t" $2 }'
}
