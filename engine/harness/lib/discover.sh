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

FELIX_DISCOVER_MAX="${FELIX_DISCOVER_MAX:-8}"

# capability <TAB> keywords, for capabilities this project actually declared.
_felix_discover_rules() {
  local tpl="$1" proj="$2" cap kws
  [ -f "$tpl/discover-rules.tsv" ] || return 0
  while IFS=$'\t' read -r cap kws; do
    case "$cap" in ''|'#'*) continue ;; esac
    felix_has_line "$(felix_declared "$proj")" "$cap" || continue
    printf '%s\t%s\n' "$cap" "$kws"
  done < "$tpl/discover-rules.tsv"
}

# Everything the marketplaces offer that this project has not declared.
# score <TAB> capability <TAB> name <TAB> description
#
# Scored only against capabilities the project declared, so a project with no
# database never sees database tooling however loudly a plugin advertises.
felix_discover_candidates() {
  local proj="$1" tpl="$2" rules
  command -v claude >/dev/null 2>&1 || return 0
  rules="$(_felix_discover_rules "$tpl" "$proj")"
  [ -n "$rules" ] || return 0

  local declared
  declared="$(grep -vE '^[[:space:]]*(#|$)' "$proj/stack.tsv" 2>/dev/null | cut -f2 | sed 's/@.*//')"

  claude plugin list --json --available </dev/null 2>/dev/null \
    | sed -n -e 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/N \1/p' \
             -e 's/.*"description"[[:space:]]*:[[:space:]]*"\(.*\)".*/D \1/p' \
    | awk '/^N /{ if (n != "") print n "\t" d; n=substr($0,3); d="" }
           /^D /{ d=substr($0,3) }
           END{ if (n != "") print n "\t" d }' \
    | while IFS=$'\t' read -r name desc; do
        [ -n "$name" ] || continue
        felix_has_line "$declared" "$name" && continue
        local nhay dhay best_cap="" best=0
        nhay=" $(printf '%s' "$name" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9-' ' ') "
        dhay=" $(printf '%s' "$desc" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9-' ' ') "
        local cap kws kw score
        while IFS=$'\t' read -r cap kws; do
          [ -n "$cap" ] || continue
          score=0
          for kw in $kws; do
            # The name is what a thing IS; the prose is what it mentions.
            case "$nhay" in *"$kw"*) score=$((score+3)); continue ;; esac
            case "$dhay" in *"$kw"*) score=$((score+1)) ;; esac
          done
          if [ "$score" -gt "$best" ]; then best="$score"; best_cap="$cap"; fi
        done <<EOF
$rules
EOF
        [ "$best" -ge "${FELIX_DISCOVER_MIN:-3}" ] && printf '%s\t%s\t%s\t%s\n' "$best" "$best_cap" "$name" "$desc"
      done \
    | sort -k1,1nr | head -"$FELIX_DISCOVER_MAX"
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

# Fetch a candidate's source, shallow and at its pinned commit, into a scratch
# directory. Read only. Never executed, never sourced, never put on a path.
felix_discover_fetch() {
  local url="$1" sha="$2" dest="$3"
  [ -n "$url" ] || return 1
  rm -rf "$dest" 2>/dev/null
  mkdir -p "$dest" 2>/dev/null || return 1
  if [ -n "$sha" ]; then
    git -C "$dest" init -q 2>/dev/null || return 1
    git -C "$dest" remote add origin "$url" 2>/dev/null || return 1
    git -C "$dest" fetch -q --depth 1 origin "$sha" 2>/dev/null || return 1
    git -C "$dest" checkout -q FETCH_HEAD 2>/dev/null || return 1
  else
    git clone -q --depth 1 "$url" "$dest" 2>/dev/null || return 1
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

  [ -d "$base/skills" ] && printf 'skills\t%s\n' "$(ls "$base/skills" 2>/dev/null | wc -l | tr -d ' ')"
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
