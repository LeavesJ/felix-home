# Discovery: what is worth having that this project does not have.
#
# The catalogue is fifteen hand-written rows. There are 273 plugins in one
# marketplace alone, and the ones that matter most are the ones a general
# recommendation pass is least likely to name: rust-analyzer for a crate,
# deepeval for a model harness, a SAST scanner for anything shipping to users.
#
# Three stages, and the middle one has no platform support whatsoever.
#
#   enumerate   what the marketplaces offer
#   evaluate    fetch the source at its pinned sha and READ it
#   recommend   a row you could add; Felix never adds it
#
# Evaluation has to be built because nothing else does it. `claude plugin
# validate` checks schema only — a plugin whose hook uploads an ssh key passes
# it with one cosmetic warning — and the plugin format has no permission
# declaration at all, so installing is unconditionally granting arbitrary code
# execution. `plugin eval` is not a sandbox and does not claim to be.
#
# What is fetched is read and deleted. Nothing from it is executed, sourced, or
# put on a path. That distinction is the entire safety argument for this stage,
# and any change that weakens it invalidates the design.
#
# The ceiling, stated because it will be forgotten once the output starts
# looking authoritative: this catches carelessness, not an attacker. A plugin
# that ships no hooks, pins its versions and interpolates no secrets can still
# do as it likes the moment it runs, because there is no boundary holding it to
# any of that. What it buys is finding out that something ships hooks BEFORE
# installing it rather than never.

# admit.sh holds the one install policy. Sourced by path because the suite
# sources this library alone, in a subshell, and this file's own rule — stated
# again at the adopt call below — is that a helper from a sibling lib turns
# that into a runtime error rather than a failing assertion. The guard is how
# that rule and the shared policy both hold.
if ! command -v felix_admit >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/admit.sh"
fi

FELIX_DISCOVER_MAX="${FELIX_DISCOVER_MAX:-8}"

# capability <TAB> keywords, for capabilities this project actually declared.
#
# Driven by what the project declared, not by what the table happens to hold.
# Row-first, a capability nobody wrote a row for contributed nothing — no
# score, no candidate, no complaint — and that is not hypothetical: one
# governed project here declares `security`, the table has no `security`
# row, and every security plugin on the machine was invisible to it.
# Measured across three governed projects, the funnel matched 4 of 35
# installed plugins.
#
# A capability's own name is also the highest-precision keyword there is,
# and it is free, so it is added to whatever the table says. It was written
# out by hand for only 4 of 12 rows, which is how a project declaring
# `frontend` failed to match a plugin named `frontend-design`.
#
# Only from five characters up. Short names are substrings of ordinary
# words — `ci` sits inside `specification`, `api` inside `rapid`, `iac`
# inside `hypothetical` — and this matcher is substring-based by design, so
# a three-letter capability used as a keyword would match nearly everything.
# The table's own header records what that costs: a keyword matching
# everything identifies nothing. Every capability detection can adopt that
# is at least five characters keeps working; the shorter ones stay dependent
# on their curated row, and felix_capabilities_unruled says when one has
# none.
# Emitted in two passes, and the order is the point. felix_capability_match
# keeps the FIRST rule at equal score, so emission order breaks ties — and
# driving the whole thing from the capabilities file handed that authority to
# whichever line somebody happened to put first. The `iac` row is the first
# pair in this table that can actually tie (`terraform` belongs to both it
# and `deploy`, and a plugin by that name exists), so reordering two lines in
# a file people edit freely would have silently re-filed a real plugin.
# Curated rows first, in the engine's own table order; then the capabilities
# no row covers, sorted, so a curated row also beats a name-only fallback.
_felix_discover_rules() {
  local tpl="$1" proj="$2" cap kws rcap rkws table="" declared ruled=""
  [ -f "$tpl/discover-rules.tsv" ] \
    && table="$(grep -vE '^[[:space:]]*(#|$)' "$tpl/discover-rules.tsv" 2>/dev/null)"
  declared="$(felix_declared "$proj")"

  while IFS=$'\t' read -r rcap rkws; do
    [ -n "${rcap:-}" ] || continue
    felix_has_line "$declared" "$rcap" || continue
    ruled="$ruled$rcap
"
    kws="$rkws"
    # Appended only when the row does not already say it. Two rows list their
    # own name as the first keyword, and the matcher adds three per
    # occurrence with no dedup, so those scored a name hit twice.
    case " $kws " in
      *" $rcap "*) ;;
      *) [ "${#rcap}" -ge 5 ] && kws="$kws $rcap" ;;
    esac
    printf '%s\t%s\n' "$rcap" "${kws# }"
  done <<EOF
$table
EOF

  while IFS= read -r cap; do
    [ -n "$cap" ] || continue
    felix_has_line "$ruled" "$cap" && continue
    # A capability name is an identifier. felix_declared strips whole-line
    # comments only, so a line carrying a trailing remark survives as one
    # long "capability" — harmlessly dropped while the table drove the loop,
    # and, once declarations drive it, a keyword and a name that
    # `discover --adopt` would write into stack.tsv.
    case "$cap" in *[!a-z0-9_-]*) continue ;; esac
    [ "${#cap}" -ge 5 ] || continue
    printf '%s\t%s\n' "$cap" "$cap"
  done <<EOF
$(printf '%s\n' "$declared" | LC_ALL=C sort -u)
EOF
  return 0
}

# Declared capabilities the table has no curated row for, one per line.
#
# They are not unscored any more — the name carries them — but a single
# keyword is far thinner than a curated row, and which capabilities are in
# that state is a fact about this project's tables that nothing else says
# out loud. Same shape as the overbroad-deny report: a rule quietly doing
# almost nothing is the complaint Felix makes about other people's plugins.
felix_capabilities_unruled() {
  local proj="$1" tpl="$2" cap ruled
  [ -f "$tpl/discover-rules.tsv" ] || return 0
  ruled="$(grep -vE '^[[:space:]]*(#|$)' "$tpl/discover-rules.tsv" 2>/dev/null | cut -f1)"
  while IFS= read -r cap; do
    [ -n "$cap" ] || continue
    felix_has_line "$ruled" "$cap" && continue
    printf '%s\n' "$cap"
  done <<EOF
$(felix_declared "$proj")
EOF
  return 0
}

# Everything the marketplaces offer that this project has not declared.
# score <TAB> capability <TAB> name <TAB> description
#
# Scored only against capabilities the project declared, so a project with no
# database never sees database tooling however loudly a plugin advertises.
#
# Exit 0 is a catalogue that was read, whether or not anything in it matched.
# Exit 3 is a catalogue that could not be read: no CLI, a CLI that failed, or
# a CLI that answered with something other than a listing. The two used to be
# one — a CLI error came back through the pipeline as no rows — and the quiet
# form then wrote "nothing matches" into a cache that stays current for seven
# days. Nothing that reads the cache could tell a marketplace with nothing for
# this project from a morning the CLI was broken. Read by an agent from the
# find-skills plugin, which draws the same line in its own catalogue reader.
felix_discover_candidates() {
  local proj="$1" tpl="$2" rules listing
  command -v claude >/dev/null 2>&1 || return 3
  rules="$(_felix_discover_rules "$tpl" "$proj")"
  [ -n "$rules" ] || return 0

  local declared
  declared="$(grep -vE '^[[:space:]]*(#|$)' "$proj/stack.tsv" 2>/dev/null | cut -f2 | sed 's/@.*//')"

  listing="$(claude plugin list --json --available </dev/null 2>/dev/null)" || return 3
  # A listing is a JSON array or object. An error printed to stdout with a
  # zero exit — which the CLI has done — begins with neither, and would have
  # matched no name and read as an empty marketplace.
  #
  # The residual, stated rather than closed: a JSON-SHAPED error with a zero
  # exit, `{"error":"could not reach the marketplace"}`, still passes here and
  # still reads as a catalogue with nothing in it. Requiring a parsed name
  # would catch it, and would also call a genuinely empty marketplace
  # unreadable — an over-refusal in the one direction nobody can act on, which
  # is how a check gets switched off. The measured failure is the plain-text
  # one and that is what this rejects.
  case "$(printf '%s' "$listing" | tr -d '[:space:]' | cut -c1)" in
    '['|'{') ;;
    *) return 3 ;;
  esac

  # The rows are computed into a variable and the status is stated, not
  # inherited from the last pipeline. Two ways this function reported failure
  # over a catalogue it had read perfectly well, both of which mattered only
  # once cmd_discover started reading the status:
  #
  #   a `while` loop's status is that of the last command its body ran, and
  #   the body ended in `[ "$best" -ge N ] && printf ...`. So whenever the LAST
  #   entry in the listing scored below the threshold — the common case, since
  #   most of a marketplace does not match one project — the loop returned 1.
  #   Measured on main as well: it is older than the status being read, and
  #   harmless until something read it.
  #
  #   and `head -N` closes the pipe on the N+1th row, so a catalogue with more
  #   matches than FELIX_DISCOVER_MAX takes SIGPIPE upstream and returns 141
  #   under pipefail. This repository already carries that lesson about grep -q.
  #
  # Reaching this line means the catalogue WAS read. Whether anything in it
  # matched is the answer, not an error, so the status is 0 and the rows say
  # the rest.
  local rows
  rows="$(printf '%s\n' "$listing" \
    | sed -n -e 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/N \1/p' \
             -e 's/.*"description"[[:space:]]*:[[:space:]]*"\(.*\)".*/D \1/p' \
    | awk '/^N /{ if (n != "") print n "\t" d; n=substr($0,3); d="" }
           /^D /{ d=substr($0,3) }
           END{ if (n != "") print n "\t" d }' \
    | while IFS=$'\t' read -r name desc; do
        [ -n "$name" ] || continue
        felix_has_line "$declared" "$name" && continue
        local hit best best_cap
        hit="$(felix_capability_match "$name" "$desc" "$rules")"
        best="$(printf '%s' "$hit" | cut -f1)"
        best_cap="$(printf '%s' "$hit" | cut -f2)"
        if [ "$best" -ge "${FELIX_DISCOVER_MIN:-3}" ]; then
          printf '%s\t%s\t%s\t%s\n' "$best" "$best_cap" "$name" "$desc"
        fi
      done)"
  printf '%s\n' "$rows" | grep . | sort -k1,1nr | head -"$FELIX_DISCOVER_MAX"
  return 0
}

# Source coordinates for one candidate: url <TAB> sha <TAB> subdir
# The CLI reads stdin. Called from inside a `while read` loop it drains the very
# list being iterated, so most candidates silently resolved to nothing while one
# happened to survive — the erratic kind of failure that looks like a network
# problem. Every invocation here is fed /dev/null.
#
# Splitting the document on braces and grepping for the name was the first
# attempt, and it found nothing: a plugin's name and its nested source object
# land in different records, so the record carrying the name never carries the
# url. Tag every interesting line with which field it is, then walk them in
# order and keep whichever entry was open when the url appeared.
felix_discover_source() {
  local name="$1"
  command -v claude >/dev/null 2>&1 || return 1
  claude plugin list --json --available </dev/null 2>/dev/null \
    | sed -n -e 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/N \1/p' \
             -e 's/.*"url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/U \1/p' \
             -e 's/.*"sha"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/S \1/p' \
             -e 's/.*"path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/P \1/p' \
    | awk -v want="$name" '
        # Deliberately reads to the end instead of exiting on the first match.
        # Exiting early closes the pipe, the CLI upstream takes SIGPIPE and
        # reports 141, and under pipefail that becomes the status of this whole
        # pipeline: every candidate resolved to no source while the same call by
        # hand worked perfectly. This repository already carries a lesson about
        # exactly this, written about grep -q.
        /^N /{ if (!found && cur == want && u != "") { U=u; S=s; P=p; found=1 }
               cur=substr($0,3); u=""; s=""; p="" }
        /^U /{ u=substr($0,3) }
        /^S /{ s=substr($0,3) }
        /^P /{ p=substr($0,3) }
        END{ if (!found && cur == want && u != "") { U=u; S=s; P=p; found=1 }
             if (found) print U "\t" S "\t" P }'
}

# Git, for the one place Felix talks to a host it does not control.
#
# Two things this fixes, both of which only bite where nobody is watching.
#
# A fetch with no deadline waits forever. In the foreground that is a hang a
# person cancels; behind any caller that is not a person it is a hang nobody
# can see. There is no portable `timeout` — neither it nor gtimeout is on this
# machine, and the enforcing path may not depend on coreutils — so the deadline
# is git's own: abort an http transfer moving less than LIMIT bytes/sec for
# TIME seconds. That covers a stalled transfer, which a wall-clock kill covers
# by also killing a slow success.
#
# And a private or moved URL makes git ask for credentials on a terminal. Asked
# where there is none it blocks; asked where there is one it interrupts a person
# with a prompt from a command that never said it would authenticate. Both are
# refusals dressed as hangs. GIT_TERMINAL_PROMPT=0 turns them into an ordinary
# non-zero exit, which every caller here already handles: a fetch that did not
# complete reads as `unknown` in the admit phase, and unknown holds.
#
# Overridable, so a slow link is a setting rather than a fork.
_felix_discover_git() {
  GIT_TERMINAL_PROMPT=0 \
  GIT_ASKPASS="${GIT_ASKPASS:-/bin/echo}" \
  GIT_HTTP_LOW_SPEED_LIMIT="${FELIX_FETCH_LOW_SPEED_LIMIT:-1000}" \
  GIT_HTTP_LOW_SPEED_TIME="${FELIX_FETCH_LOW_SPEED_TIME:-30}" \
  git "$@"
}

# Fetch a candidate's source, shallow and at its pinned commit, into a scratch
# directory. Read only. Never executed, never sourced, never put on a path.
felix_discover_fetch() {
  local url="$1" sha="$2" dest="$3"
  [ -n "$url" ] || return 1
  rm -rf "$dest" 2>/dev/null
  mkdir -p "$dest" 2>/dev/null || return 1
  if [ -n "$sha" ]; then
    _felix_discover_git -C "$dest" init -q 2>/dev/null || return 1
    _felix_discover_git -C "$dest" remote add origin "$url" 2>/dev/null || return 1
    _felix_discover_git -C "$dest" fetch -q --depth 1 origin "$sha" 2>/dev/null || return 1
    _felix_discover_git -C "$dest" checkout -q FETCH_HEAD 2>/dev/null || return 1
  else
    _felix_discover_git clone -q --depth 1 "$url" "$dest" 2>/dev/null || return 1
  fi
  return 0
}

# Read three files and report facts. fact <TAB> detail, one per line.
felix_discover_inspect() {
  local dir="$1" sub="${2:-}" base f
  base="$dir"
  [ -n "$sub" ] && [ -d "$dir/$sub" ] && base="$dir/$sub"

  f="$base/hooks/hooks.json"
  if [ -f "$f" ]; then
    printf 'hooks\t%s\n' \
      "$(grep -oE '"(PreToolUse|PostToolUse|SessionStart|SessionEnd|Stop|UserPromptSubmit|PostToolBatch)"' "$f" \
         | tr -d '"' | sort -u | tr '\n' ' ')"
    grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]{0,90}' "$f" \
      | sed 's/.*"command"[[:space:]]*:[[:space:]]*"//' \
      | while IFS= read -r c; do printf 'hook-command\t%s\n' "$c"; done
  fi

  for f in "$base/.mcp.json" "$base/mcp.json"; do
    [ -f "$f" ] || continue
    grep -qE '"type"[[:space:]]*:[[:space:]]*"(http|sse)"' "$f" \
      && printf 'mcp\tremote endpoint\n' || printf 'mcp\tlocal subprocess\n'
    grep -oE '\$\{[A-Z_]+' "$f" | tr -d '${' | sort -u \
      | while IFS= read -r v; do [ -n "$v" ] && printf 'interpolates\t%s\n' "$v"; done
    grep -qE '@latest|:latest' "$f" && printf 'floating\tan unpinned version in the mcp command\n'
  done

  if [ -d "$base/skills" ]; then
    printf 'skills\t%s\n' "$(ls "$base/skills" 2>/dev/null | wc -l | tr -d ' ')"
    # Named, not only counted. The count feeds the risk read; the names are
    # manifest facts — what the thing ships — and matching on them is what
    # replaces guessing from a listing's prose (Decision C, 2026-08-30).
    for f in "$base"/skills/*/; do
      [ -d "$f" ] || continue
      f="${f%/}"
      printf 'skill\t%s\n' "${f##*/}"
    done
  fi
  return 0
}

# Facts in, tier out. Same three tiers stack.tsv already uses, so a discovered
# row can be pasted into it unchanged.
felix_discover_risk() {
  local facts="$1"
  case "$facts" in
    *"hooks	"*)        printf 'high';   return ;;
    *"floating	"*)     printf 'high';   return ;;
    *"interpolates	"*) printf 'high';   return ;;
  esac
  case "$facts" in
    *"mcp	"*) printf 'medium'; return ;;
  esac
  printf 'low'
}

# Why a tier was chosen, in the words of what was actually found.
felix_discover_why() {
  local facts="$1" out=""
  case "$facts" in *"hooks	"*)
    out="$out; ships hooks, which run on your machine every session" ;; esac
  case "$facts" in *"floating	"*)
    out="$out; unpinned version, so its code can change with no manifest change" ;; esac
  case "$facts" in *"interpolates	"*)
    out="$out; interpolates an environment variable, check what it sends where" ;; esac
  case "$facts" in *"mcp	remote"*)
    out="$out; talks to a remote endpoint" ;; esac
  case "$facts" in *"mcp	local"*)
    out="$out; runs a local subprocess" ;; esac
  printf '%s' "${out#; }"
}

# ---------------------------------------------------------------- cadence ---
#
# Inspection fetches over the network and takes seconds per candidate, so it
# cannot sit in front of a prompt. "Automatic" honestly means: run between
# sessions, cache the answer, and speak only when the answer changed.
#
# Nothing here installs, and nothing here blocks. A refresh that fails leaves
# the previous answer in place, which is the right trade for a background job
# nobody is watching.

FELIX_DISCOVER_STALE_DAYS="${FELIX_DISCOVER_STALE_DAYS:-7}"

_felix_discover_cache() { printf '%s/state/discover/%s' "$2" "$(basename "$1")"; }

# The cache carries the provenance of the verdicts in it. Its rows are
# (name, capability, tier) computed by the matcher against the rules table at
# the time it was written, and on the first live commissioning run a cache
# from five days earlier — written by a matcher that has since been fixed —
# declared and installed a storage plugin under llm, twice: the fix to the
# matcher changed nothing the adopt path read. So the first line is a stamp
# over the rules table and the engine version, and every reader treats a
# cache whose stamp is not the current one as ABSENT, which the foreground
# fill in discover --adopt then recomputes. A stale verdict is not a verdict.
_felix_discover_stamp() {
  local tpl="${1:-$(dirname "${BASH_SOURCE[0]:-$0}")/../templates}" ver
  ver="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
          "$(dirname "${BASH_SOURCE[0]:-$0}")/../../.claude-plugin/plugin.json" 2>/dev/null | head -1)"
  { printf 'matcher=words\nengine=%s\n' "${ver:-?}"; cat "$tpl/discover-rules.tsv" 2>/dev/null; } \
    | git hash-object --stdin 2>/dev/null
}
_felix_discover_stamp_line() { printf '# stamp %s\n' "$(_felix_discover_stamp "${1:-}")"; }

# 0 when the cache exists and was written under the current rules and engine.
felix_discover_cache_current() {
  local proj="$1" home="$2" tpl="${3:-}" cache first
  cache="$(_felix_discover_cache "$proj" "$home").tsv"
  [ -f "$cache" ] || return 1
  first="$(head -1 "$cache" 2>/dev/null)"
  [ "$first" = "$(_felix_discover_stamp_line "$tpl" | tr -d '\n')" ]
}

# What a thing looks like, scored once.
#
# There were two of these and they drifted, which is how a plugin was installed
# under a capability it does not have: one scored a marketplace blurb, the other
# scored the name alone, and nothing said they were supposed to agree. A name
# counts triple because it is what a thing IS; a skill name counts triple
# because it is what a thing SHIPS — a manifest fact read off the copy on disk,
# not a word chosen to be found by (Decision C, 2026-08-30); prose counts
# single because it is what a thing mentions.
#
# The fourth argument is optional — skill names, one per line — and every
# caller that has a copy on disk should pass it, because the same read that
# scored the risk already yielded the list.
#
# Emits: score <TAB> capability. The caller applies its own threshold, because
# what is worth reporting and what is worth installing are different bars.
#
# A keyword is a WORD. The first version matched substrings over the token
# string, and on the first live commissioning run `rag` — a keyword of the
# llm rule — matched the name google-cloud-sto*rag*e, scored the name hit of
# 3 that is also the adoption threshold, and a storage plugin was declared
# and installed under llm. The tokeniser now splits on everything that is
# not a letter or digit, hyphens included, so `observability-tool` still
# matches `observability`, and a keyword with a hyphen (`rest-api`) is
# matched as the two-word phrase it tokenises to. `eval` no longer matches
# `evaluation` or `evaltool`, and is not meant to: a keyword that matches
# inside other words is a keyword that matches by accident.
_felix_cap_tokens() { printf ' %s ' "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' ' ' | sed 's/^ *//; s/ *$//')"; }
felix_capability_match() {
  local name="$1" desc="$2" rules="$3" skills="${4:-}"
  local nhay dhay shay cap kws kw kwn score hit best=0 best_cap=""
  nhay="$(_felix_cap_tokens "$name")"
  dhay="$(_felix_cap_tokens "$desc")"
  shay="$(_felix_cap_tokens "$skills")"
  while IFS=$'\t' read -r cap kws; do
    [ -n "${cap:-}" ] || continue
    score=0
    for kw in $kws; do
      hit=0
      kwn="$(_felix_cap_tokens "$kw")"
      [ "$kwn" != "  " ] || continue
      case "$nhay" in *"$kwn"*) score=$((score+3)); hit=1 ;; esac
      case "$shay" in *"$kwn"*) score=$((score+3)); hit=1 ;; esac
      [ "$hit" -eq 1 ] && continue
      case "$dhay" in *"$kwn"*) score=$((score+1)) ;; esac
    done
    if [ "$score" -gt "$best" ]; then best="$score"; best_cap="$cap"; fi
  done <<EOF
$rules
EOF
  printf '%s\t%s' "$best" "$best_cap"
}

# What a plugin says about itself, from the copy on disk.
#
# Preferred over the marketplace listing wherever both exist. The listing is
# written to be chosen from; the manifest is written to describe. Scoring the
# blurb is how a tracing plugin and an inference provider were both filed under
# the capability of the project that happened to be looking.
felix_plugin_description() {
  local dir="$1"
  [ -f "$dir/.claude-plugin/plugin.json" ] || return 0
  sed -n 's/.*"description"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    "$dir/.claude-plugin/plugin.json" 2>/dev/null | head -1
}

# What discovery has already read, judged, and would declare.
#
# Everything expensive is done by the time this runs: the candidate was fetched
# at its pinned sha, its contents were read, and a risk tier was scored from
# what it actually ships. Stopping there and printing a shopping list was the
# governance charter talking. Declaring is a manifest edit, which detection was
# always permitted to do unattended, and the founder is not supposed to be
# thinking about tooling at all.
#
# Low only. Medium means it ships an MCP server, which usually needs credentials
# a person has to supply anyway; high means hooks, a floating version, or an
# interpolated secret, and no flag from any caller installs those.
#
# Emits: action <TAB> name <TAB> capability <TAB> risk
#   declare  low risk, not yet in stack.tsv
#   refuse   medium or high
#   already  named in stack.tsv, whatever the tier
felix_discover_adopt() {
  local proj="$1" home="$2" tpl="${3:-}" cache name cap risk declared
  cache="$(_felix_discover_cache "$proj" "$home").tsv"
  felix_discover_cache_current "$proj" "$home" "$tpl" || return 0

  # Compared without the marketplace suffix, the same way candidates are
  # filtered, so langfuse@x already declared matches a langfuse candidate.
  declared="$(grep -vE '^[[:space:]]*(#|$)' "$proj/stack.tsv" 2>/dev/null \
              | cut -f2 | sed 's/@.*//')"

  while IFS=$'\t' read -r name cap risk; do
    # The cache is not always rows. When nothing matches, discovery writes prose
    # into it explaining why, and a parser that adopted a sentence would be
    # worse than one that adopted nothing. Three fields and a known tier, or it
    # is not a candidate.
    [ -n "${name:-}" ] && [ -n "${cap:-}" ] || continue
    case "$name" in '#'*) continue ;; esac
    case "${risk:-}" in low|medium|high) ;; *) continue ;; esac
    case "$name" in *' '*) continue ;; esac
    # `-` is inspection's own verdict: the copy on disk ships nothing serving
    # any declared capability, whatever the catalogue blurb promised. Declaring
    # and installing under `-` would act on the claim inspection just refuted,
    # and the row would sit in stack.tsv permanently dormant.
    [ "$cap" = "-" ] && continue

    # Self-contained on purpose: this file is sourced alone by the suite, and a
    # helper from a sibling lib turns that into a runtime error rather than a
    # failing assertion. grep without -q for the usual reason — a consumer that
    # exits on its first match kills the producer under `set -o pipefail`.
    if printf '%s\n' "$declared" | grep -xF "$name" >/dev/null 2>&1; then
      printf 'already\t%s\t%s\t%s\n' "$name" "$cap" "$risk"; continue
    fi
    # A cache row was tiered by this engine reading what the candidate ships,
    # so the policy is asked as OBSERVED. `hold` and `refuse` both read
    # `refuse` here: this command's caller can only declare or not, and the
    # difference between "a person decides" and "nobody may" belongs to the
    # report, not to a manifest edit that either happens or does not.
    case "$(felix_admit "$risk" OBSERVED)" in
      install) printf 'declare\t%s\t%s\t%s\n' "$name" "$cap" "$risk" ;;
      *)       printf 'refuse\t%s\t%s\t%s\n'  "$name" "$cap" "$risk" ;;
    esac
  done < "$cache"
}

# Has the cache aged out, or never existed?
felix_discover_stale() {
  local f; f="$(_felix_discover_cache "$1" "$2").tsv"
  [ -f "$f" ] || return 0
  # Stale by provenance before stale by age: a cache the current rules and
  # engine did not write is due for a refresh whatever its mtime says.
  felix_discover_cache_current "$1" "$2" "${3:-}" || return 0
  local age
  age="$(find "$f" -mtime +"$FELIX_DISCOVER_STALE_DAYS" 2>/dev/null)"
  [ -n "$age" ]
}

# Refresh in the background, at most one at a time. The lock is a directory
# because mkdir is atomic everywhere and a stale lock file is not.
felix_discover_refresh_bg() {
  local proj="$1" home="$2" felix_bin="$3"
  local dir lock
  dir="$home/state/discover"
  lock="$dir/.lock"
  mkdir -p "$dir" 2>/dev/null || return 0
  mkdir "$lock" 2>/dev/null || return 0   # already running; leave it alone
  (
    trap 'rmdir "$lock" 2>/dev/null' EXIT
    cd "$(felix_repo_root "$PWD")" 2>/dev/null || exit 0
    # A refresh that could not read the marketplaces exits non-zero and writes
    # nothing, and the previous answer stands: an unreadable catalogue is not
    # an empty one, and must not become one for seven days.
    if "$felix_bin" discover --inspect --quiet > "$(_felix_discover_cache "$proj" "$home").new.$$" 2>/dev/null; then
      mv -f "$(_felix_discover_cache "$proj" "$home").new.$$" \
            "$(_felix_discover_cache "$proj" "$home").tsv" 2>/dev/null
    else
      rm -f "$(_felix_discover_cache "$proj" "$home").new.$$" 2>/dev/null
    fi
  ) </dev/null >/dev/null 2>&1 &
  return 0
}

# Findings not yet mentioned. Reporting the same three plugins every session is
# how a useful signal becomes wallpaper.
felix_discover_unseen() {
  local proj="$1" home="$2" base cache seen
  base="$(_felix_discover_cache "$proj" "$home")"
  cache="$base.tsv"; seen="$base.seen"
  [ -s "$cache" ] || return 0
  felix_discover_cache_current "$proj" "$home" || return 0
  if [ -f "$seen" ]; then
    LC_ALL=C comm -23 <(grep -v '^#' "$cache" | cut -f1 | LC_ALL=C sort -u) \
                      <(LC_ALL=C sort -u "$seen") 2>/dev/null
  else
    grep -v '^#' "$cache" | cut -f1 | LC_ALL=C sort -u
  fi
}

felix_discover_mark_seen() {
  local base; base="$(_felix_discover_cache "$1" "$2")"
  [ -s "$base.tsv" ] || return 0
  grep -v '^#' "$base.tsv" | cut -f1 | LC_ALL=C sort -u >> "$base.seen" 2>/dev/null
  LC_ALL=C sort -u -o "$base.seen" "$base.seen" 2>/dev/null
  return 0
}
