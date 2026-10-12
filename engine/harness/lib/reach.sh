# Reach: whether the MCP servers a project declares actually connect.
#
# felix stack plan calls a plugin row present once `claude plugin list` names
# it, and has never asked whether the servers that plugin ships connect. Measured
# 2026-10-12: one plugin declared `always` in eight projects was listed as
# needing authentication in a live session while `claude mcp list` from an empty
# folder said Connected; another fails every session with ENOTFOUND on a
# placeholder address; a third fails with HTTP 400. Nothing reported any of it.
# This reads `claude mcp list` once and says, per declared plugin or mcp row and
# per server, connected, needs-auth, failed, not-listed, no-server or unknown.
#
# ADVISORY ONLY, and that is the whole safety argument. The bash-and-git rule of
# invariant 2 holds because nothing on the enforcing path waits on or reads this
# result. The SessionStart hook only starts a refresh, detached, and never reads
# what it writes; the gate, the Stop hook, commissioning and felix stack plan
# never read the cache. felix stack plan keeps reading `claude plugin list` and the
# mount test in lib/stack.sh, so a plugin whose server needs authentication is
# still present there. A slow, failed or absent read costs the person a stale
# line in the pulse and nothing else; it never blocks, holds, installs, or
# changes an existing decision. The only readers of the cache are felix stack
# --reach, the pulse's report (lib/pulse.sh) and felix status (lib/status.sh),
# and each reaches it through the functions here.
#
# Unknown never reads as fine. A list that could not be read (no claude CLI, a
# failed run, a substitution that could not make its pipe, nothing printed) is
# not an empty list: it would turn every declared server into not-listed. A
# plugin with no installed directory is unknown, not no-server, because whether
# it ships a server cannot be told from disk. Every age is read from the cache's
# own header epoch and never from the file's mtime, so a copied or touched file
# cannot look fresh.
#
# A detail never carries a URL's query string, which can hold a key: the target
# column of a list line is never copied, and the status text is cut before its
# first question mark. It is not truncated by bytes, because a byte cut can
# split a multibyte character and one bad byte empties a macOS UTF-8 sort.
#
# THE LIST IS READ FROM AN EMPTY DIRECTORY, NEVER THE CHECKOUT. `claude mcp list`
# starts the servers it lists, a project-scoped one included once it is approved
# or auto-enabled (enableAllProjectMcpServers), and this runs at every session
# start of every governed project, repositories opened to hunt for bugs among
# them. Measured 2026-10-12 with the real CLI: a server pending approval is
# listed and not started, so reading in the checkout was safe only while Claude
# Code's approval state held; from an empty directory it is not listed at all,
# but the CLI walks up to a parent's .mcp.json, so a scratch directory with one
# above it is refused. felix_reach_read makes a fresh directory under TMPDIR
# (never the checkout, never $HOME, itself a repository here), reads from there,
# removes it, and when it cannot reads nothing, never in the caller's directory.
# A server only a project's .mcp.json declares is not seen: unknown, not not-listed.
#
# Cache: <home>/state/reach/<project>.tsv, first line `# read <epoch> <dir>`
# (dir is the empty directory the read ran in, gone by now), then the rows
# felix_reach_rows printed, written to a temp file and moved into place, and
# only when the list was read: a failed read leaves the old cache.
# Each row is `state<TAB>kind<TAB>declared name<TAB>server<TAB>detail`.

# Sourced by path because the suite sources libraries alone, in subshells, and a
# call that resolved to nothing would degrade to saying nothing (house pattern).
if ! command -v _felix_stack_rows >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/stack.sh"
fi
if ! command -v felix_toolbox_path >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/toolbox.sh"
fi
if ! command -v felix_close_inherited_fds >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

# One line of the list as a server row `key<TAB>state<TAB>detail`, or nothing
# for a line that is not a server line. A server line holds `: ` and the text
# before the first `: ` (its key) holds no space, so the health header, the
# blank line and prose are ignored. Reads the list on stdin.
_felix_reach_parse() {
  local line key state phrase d tab=$'\t' cr=$'\r'
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in *": "*) ;; *) continue ;; esac
    key="${line%%: *}"
    case "$key" in ''|*" "*) continue ;; esac
    _felix_mcp_line_set "$line"; state="$_FELIX_MCP_STATE"
    case "$state" in
      failed)     phrase="Failed to connect" ;;
      needs-auth) phrase="Needs authentication" ;;
      connected)  phrase="Connected" ;;
      *)          phrase="" ;;
    esac
    if [ -n "$phrase" ]; then
      d="$phrase${line#*"$phrase"}"
    else
      state=unknown
      case "$line" in *" - "*) d="${line##* - }" ;; *) d="" ;; esac
    fi
    d="${d%%\?*}"
    d="${d//$tab/ }"; d="${d//$cr/ }"
    [ -n "$d" ] || d="-"
    key="${key//$tab/ }"; key="${key//$cr/ }"
    printf '%s\t%s\t%s\n' "$key" "$state" "$d"
  done
}

# Remove a scratch directory felix_reach_read made, and whatever claude left in
# it. Only a path shaped as mktemp gave it, absolute and not a symlink.
_felix_reach_rm() {
  case "${1:-}" in
    /*/felix-reach.??????) [ -d "$1" ] && [ ! -L "$1" ] && rm -rf "$1" 2>/dev/null ;;
  esac
  return 0
}

# 0 when no directory from $1 up to / holds a .mcp.json (the CLI reads a parent's).
_felix_reach_neutral() {
  local d="$1"
  while :; do
    [ -e "$d/.mcp.json" ] && return 1
    [ -n "$d" ] || return 0
    d="${d%/*}"
  done
}

# Run `claude mcp list` once, from a fresh empty directory (the head of this file
# says why). 0 when read, with the server table in _FELIX_REACH_SRV and the
# directory it ran in in _FELIX_REACH_CWD; 1 when not, one sentence in
# _FELIX_REACH_WHY. The directory is made under $TMPDIR with a template (a bare
# mktemp on macOS ignores TMPDIR) and removed once the command returns, on every
# path. When it cannot be made, entered or trusted, claude is not run at all.
# Output, exit status and a sentinel come back in one substitution: one that
# cannot make its pipe expands to nothing with status 0 on bash 3.2, and that
# must read as unread, never as an empty list. stderr is discarded. No timeout:
# nobody waits on the background read, a person running --reach can interrupt it,
# and macOS ships no `timeout` binary to bound it with.
felix_reach_read() {
  local out rc body parsed nl=$'\n' ws=$' \t\r\n' tmpd made dir=""
  _FELIX_REACH_OK=0; _FELIX_REACH_WHY=""; _FELIX_REACH_SRV=""; _FELIX_REACH_CWD=""
  if ! command -v claude >/dev/null 2>&1; then
    _FELIX_REACH_WHY="no claude CLI on PATH"; return 1
  fi
  tmpd="${TMPDIR:-/tmp}"
  # A relative TMPDIR would put it under the caller's own directory.
  case "$tmpd" in /*) ;; *) tmpd=/tmp ;; esac
  made="$(mktemp -d "${tmpd%/}/felix-reach.XXXXXX" 2>/dev/null)" || made=""
  case "$made" in /*/felix-reach.??????) ;; *) made="" ;; esac
  if [ -n "$made" ] && [ -d "$made" ] && [ ! -L "$made" ]; then
    dir="$(cd "$made" 2>/dev/null && pwd -P)" || dir=""
  fi
  if [ -z "$dir" ]; then
    _felix_reach_rm "$made"
    _FELIX_REACH_WHY="could not make an empty directory to run claude mcp list in"; return 1
  fi
  if ! _felix_reach_neutral "$dir"; then
    _felix_reach_rm "$made"
    _FELIX_REACH_WHY="a .mcp.json sits above the scratch directory, so claude mcp list could start a project-scoped server there"; return 1
  fi
  out="$(cd "$dir" 2>/dev/null && claude mcp list 2>/dev/null </dev/null; printf '\n.%s' "$?")"
  _felix_reach_rm "$made"
  case "$out" in
    *"$nl."[0-9]*) ;;
    *) _FELIX_REACH_WHY="the list's output could not be captured"; return 1 ;;
  esac
  rc="${out##*"$nl."}"
  case "$rc" in
    ''|*[!0-9]*) _FELIX_REACH_WHY="the list's output could not be captured"; return 1 ;;
  esac
  body="${out%"$nl.$rc"}"
  if [ "$rc" != 0 ]; then
    _FELIX_REACH_WHY="claude mcp list exited $rc"; return 1
  fi
  # Tested with case and not by stripping the whitespace out with ${body//..//}:
  # on bash 3.2 a global substitution over a list this size is quadratic, three
  # seconds for a hundred lines.
  case "$body" in
    *[!$ws]*) ;;
    *) _FELIX_REACH_WHY="claude mcp list printed nothing"; return 1 ;;
  esac
  parsed="$(printf '%s\n' "$body" | _felix_reach_parse; printf '.')"
  case "$parsed" in
    *.) _FELIX_REACH_SRV="${parsed%.}" ;;
    *)  _FELIX_REACH_WHY="the list's output could not be captured"; return 1 ;;
  esac
  _FELIX_REACH_CWD="$dir"
  _FELIX_REACH_OK=1
  return 0
}

# Does the plugin directory $1 declare an MCP server? 0 yes, 1 no, 2 a manifest
# is there and could not be read. .mcp.json counts when its text holds "command"
# (every stdio server) or "url" (every remote one), so an empty {} declares
# nothing; plugin.json counts on "mcpServers" alone, because it may carry an
# author "url". The text is read whole and tested with case, never piped into a
# grep that can stop early.
_felix_reach_declares() {
  local d="$1" t
  if [ -f "$d/.mcp.json" ]; then
    [ -r "$d/.mcp.json" ] || return 2
    t="$(cat "$d/.mcp.json" 2>/dev/null)" || return 2
    case "$t" in *'"command"'*|*'"url"'*) return 0 ;; esac
  fi
  if [ -f "$d/.claude-plugin/plugin.json" ]; then
    [ -r "$d/.claude-plugin/plugin.json" ] || return 2
    t="$(cat "$d/.claude-plugin/plugin.json" 2>/dev/null)" || return 2
    case "$t" in *'"mcpServers"'*) return 0 ;; esac
  fi
  return 1
}

# The server rows of the table on stdin that a declared row names, as full rows.
# $1 kind, $2 the name to match, $3 the declared name. A plugin x@mkt owns the
# keys that begin plugin:x: ; an mcp row matches as _felix_mcp_connected does,
# the key equal to the name or containing :name: , the name always quoted so it
# is a literal and never a pattern.
_felix_reach_match() {
  local kind="$1" want="$2" declared="$3" key st d
  while IFS=$'\t' read -r key st d; do
    [ -n "$key" ] || continue
    case "$kind" in
      plugin) case "$key" in "plugin:$want:"*) ;; *) continue ;; esac ;;
      *)      case "$key:" in "$want:"*|*":$want:"*) ;; *) continue ;; esac ;;
    esac
    printf '%s\t%s\t%s\t%s\t%s\n' "$st" "$kind" "$declared" "$key" "$d"
  done
}

# The rows for one declared plugin or mcp row, against the list already read.
_felix_reach_one() {
  local kind="$1" name="$2" x m dir rc
  if [ "${_FELIX_REACH_OK:-0}" != 1 ]; then
    printf 'unknown\t%s\t%s\t-\t%s\n' "$kind" "$name" "${_FELIX_REACH_WHY:-the server list was not read}"
    return 0
  fi
  x="$name"
  [ "$kind" = plugin ] && x="${name%%@*}"
  m="$(printf '%s\n' "${_FELIX_REACH_SRV:-}" | _felix_reach_match "$kind" "$x" "$name")"
  if [ -n "$m" ]; then printf '%s\n' "$m"; return 0; fi
  if [ "$kind" = mcp ]; then
    # Unknown, never not-listed: from an empty directory a project-scoped server
    # is not listed, so its absence says nothing about whether it connects.
    printf 'unknown\tmcp\t%s\t-\tno line of claude mcp list names this server; a project-scoped server is not started by Felix, so whether it connects is not known\n' "$name"
    return 0
  fi
  dir="$(felix_toolbox_path "$x")" || dir=""
  if [ -z "$dir" ]; then
    printf 'unknown\tplugin\t%s\t-\tno installed directory for %s, so whether it ships an MCP server is not known\n' "$name" "$x"
    return 0
  fi
  _felix_reach_declares "$dir"; rc=$?
  case "$rc" in
    0) printf 'not-listed\tplugin\t%s\t-\tthe plugin declares an MCP server and no line of claude mcp list names one\n' "$name" ;;
    1) printf 'no-server\tplugin\t%s\t-\tthe plugin declares no MCP server; its reach is its install, which felix stack plan reports\n' "$name" ;;
    *) printf 'unknown\tplugin\t%s\t-\tthe plugin'\''s MCP manifest could not be read, so whether it ships a server is not known\n' "$name" ;;
  esac
  return 0
}

# Classify every plugin and mcp row of <proj>/stack.tsv against the list that
# felix_reach_read left behind (or, when that read failed, as unknown), in stack
# order and then list order. Prints rows and nothing else. marketplace and skill
# rows emit nothing, and capability is not consulted: a dormant row is read like
# any other, because capability says whether a row should be installed and not
# whether a server connects.
felix_reach_rows() {
  local proj="$1" kind name
  _felix_stack_rows "$proj" | while IFS=$'\t' read -r kind name _; do
    case "$kind" in plugin|mcp) ;; *) continue ;; esac
    [ -n "${name:-}" ] || continue
    _felix_reach_one "$kind" "$name"
  done
}

# How many plugin and mcp rows <proj> declares.
_felix_reach_count() {
  _felix_stack_rows "$1" | LC_ALL=C awk -F'\t' '$1 == "plugin" || $1 == "mcp" { n++ } END { print n + 0 }'
}

felix_reach_cache() {
  local p="${1%/}"
  printf '%s/state/reach/%s.tsv' "$2" "${p##*/}"
}

# The epoch in the cache's header, or nothing when there is no cache or its first
# line is not `# read <digits> ...`. Anything else is treated as absent.
_felix_reach_epoch() {
  local f="$1" first="" e
  [ -f "$f" ] && [ -r "$f" ] || return 0
  { IFS= read -r first || [ -n "$first" ]; } < "$f" 2>/dev/null || return 0
  case "$first" in "# read "*) ;; *) return 0 ;; esac
  e="${first#"# read "}"; e="${e%% *}"
  case "$e" in ''|*[!0-9]*) return 0 ;; esac
  [ "${#e}" -le 12 ] || return 0
  printf '%s' "$e"
}

# The clock, as digits, or nothing and status 1 when it cannot be read. Checked
# because an empty value inside $(( )) is a syntax error, and on bash 3.2 that
# discards the whole top-level command it sits in.
_felix_reach_now() {
  local n
  n="$(date +%s 2>/dev/null)"
  case "$n" in ''|*[!0-9]*) return 1 ;; esac
  printf '%s' "$n"
}

# Seconds since the cache was read, from the header epoch; nothing when there is
# no valid cache or no clock. A header from the future reads as age zero.
_felix_reach_age() {
  local e now
  e="$(_felix_reach_epoch "$1")"
  [ -n "$e" ] || return 0
  now="$(_felix_reach_now)" || return 0
  if [ "$((10#$now))" -le "$((10#$e))" ]; then printf '0'; else printf '%s' "$(( 10#$now - 10#$e ))"; fi
}

# 0 when <proj> declares a plugin or mcp row and its cache is absent, has no
# valid header, was read a day or more ago, or claims to have been read in the
# future (it cannot be trusted to be fresh). With no clock it is not due: a
# refresh nobody can date is not worth starting blind.
felix_reach_due() {
  local proj="$1" home="$2" e now
  [ "$(_felix_reach_count "$proj")" -gt 0 ] 2>/dev/null || return 1
  e="$(_felix_reach_epoch "$(felix_reach_cache "$proj" "$home")")"
  [ -n "$e" ] || return 0
  now="$(_felix_reach_now)" || return 1
  [ "$((10#$now))" -lt "$((10#$e))" ] && return 0
  [ "$(( 10#$now - 10#$e ))" -ge 86400 ]
}

# Write the cache: header, then the rows. Temp file, then moved into place; the
# temp file is removed on any failure.
_felix_reach_store() {
  local proj="$1" home="$2" rows="$3" cache tmp cwd
  cache="$(felix_reach_cache "$proj" "$home")"
  tmp="$cache.new.$$"
  mkdir -p "${cache%/*}" 2>/dev/null || return 1
  # The empty directory felix_reach_read ran in, not where this was called from.
  cwd="${_FELIX_REACH_CWD:--}"; cwd="${cwd//$'\n'/ }"
  if { printf '# read %s %s\n' "$(date +%s)" "$cwd"
       [ -z "$rows" ] || printf '%s\n' "$rows"
     } > "$tmp" 2>/dev/null && mv -f "$tmp" "$cache" 2>/dev/null; then
    return 0
  fi
  rm -f "$tmp" 2>/dev/null
  return 1
}

# Read the list, classify, store when the list was read. Leaves the rows in
# _FELIX_REACH_ROWS and the cache write's status in _FELIX_REACH_STORED; returns
# the read's status. A project declaring no plugin or mcp row runs nothing and
# gets no cache.
felix_reach_collect() {
  local proj="$1" home="$2" rc
  _FELIX_REACH_ROWS=""; _FELIX_REACH_STORED=1
  [ "$(_felix_reach_count "$proj")" -gt 0 ] 2>/dev/null || return 0
  felix_reach_read; rc=$?
  _FELIX_REACH_ROWS="$(felix_reach_rows "$proj")"
  if [ -z "$_FELIX_REACH_ROWS" ]; then
    # Every declared row emits at least one row, so none at all means the
    # substitution above could not run, and that is not a list of nothing.
    rc=1; _FELIX_REACH_WHY="the classified rows could not be captured"
  fi
  if [ "$rc" -eq 0 ]; then
    _felix_reach_store "$proj" "$home" "$_FELIX_REACH_ROWS"; _FELIX_REACH_STORED=$?
  fi
  return "$rc"
}

# collect, then print the rows. Returns the read's status.
felix_reach_refresh() {
  local rc
  felix_reach_collect "$1" "$2"; rc=$?
  [ -z "$_FELIX_REACH_ROWS" ] || printf '%s\n' "$_FELIX_REACH_ROWS"
  return "$rc"
}

# The refresh, detached, in felix_discover_refresh_bg's shape without its cd: a
# lock directory taken with mkdir (held means a refresh is running, so return), a
# subshell that removes it on EXIT, the inherited descriptors closed, every
# stream closed so nothing about it can reach the session or hold the hook open.
# It stands nowhere in particular: felix_reach_read reads from an empty directory
# of its own. A lock older than 30 minutes is broken, because a refresh killed by
# a signal never runs its trap and reach would otherwise never refresh again.
felix_reach_refresh_bg() {
  local proj="$1" home="$2" dir lock p
  dir="$home/state/reach"
  p="${proj%/}"
  lock="$dir/${p##*/}.lock"
  mkdir -p "$dir" 2>/dev/null || return 0
  if [ -d "$lock" ] && [ -n "$(find "$lock" -maxdepth 0 -mmin +30 2>/dev/null)" ]; then
    rmdir "$lock" 2>/dev/null
  fi
  mkdir "$lock" 2>/dev/null || return 0
  (
    trap 'rmdir "$lock" 2>/dev/null' EXIT
    felix_close_inherited_fds
    felix_reach_refresh "$proj" "$home" >/dev/null
  ) </dev/null >/dev/null 2>&1 &
  return 0
}

# The pulse's lines for one project, from its cache only; the pulse never runs
# claude (lib/pulse.sh says why). Nothing for a project that declares no plugin
# or mcp row. Otherwise reach-unread when there is no valid cache; else one
# unreachable line per needs-auth, failed or not-listed row in cache order, one
# reach-unknown line when any row is unknown, and reach-stale when the cache was
# read seven days or more ago. connected and no-server rows print nothing.
felix_reach_report() {
  local proj="$1" home="$2" name p n cache age
  p="${proj%/}"; name="${p##*/}"
  n="$(_felix_reach_count "$proj")"
  [ "${n:-0}" -gt 0 ] 2>/dev/null || return 0
  cache="$(felix_reach_cache "$proj" "$home")"
  age="$(_felix_reach_age "$cache")"
  if [ -z "$age" ]; then
    printf 'reach-unread\t%s\t%s declared plugin or mcp row(s) and no reach cache; the next session in its checkout reads one, or run felix stack --reach there\n' "$name" "$n"
    return 0
  fi
  LC_ALL=C awk -F'\t' -v p="$name" '
    NR == 1 || NF != 5 { next }
    $1 == "needs-auth" || $1 == "failed" || $1 == "not-listed" { printf "unreachable\t%s\t%s %s %s\n", p, $3, $4, $1 }
    $1 == "unknown" { k++; names = names (names == "" ? "" : " ") $3 }
    END { if (k > 0) printf "reach-unknown\t%s\t%d declared row(s) whose reach is not known: %s\n", p, k, names }
  ' "$cache"
  if [ "$age" -ge 604800 ]; then
    printf 'reach-stale\t%s\tthe reach cache was read %s days ago\n' "$name" "$(( age / 86400 ))"
  fi
  return 0
}

# felix status's reach row for <proj>: state<TAB>value<TAB>detail. value is
# connected/total, with total leaving out no-server rows. none when the project
# declares no plugin or mcp row; unknown, never zero, when it has no valid cache.
felix_reach_summary() {
  local proj="$1" home="$2" name p n cache age out ct rest labels k tab=$'\t' h unr ago
  p="${proj%/}"; name="${p##*/}"
  n="$(_felix_reach_count "$proj")"
  if ! [ "${n:-0}" -gt 0 ] 2>/dev/null; then
    printf 'none\t-\t%s declares no plugin or mcp rows\n' "$name"; return 0
  fi
  cache="$(felix_reach_cache "$proj" "$home")"
  age="$(_felix_reach_age "$cache")"
  if [ -z "$age" ]; then
    printf 'unknown\t-\tno reach cache for %s; felix stack --reach reads one\n' "$name"; return 0
  fi
  out="$(LC_ALL=C awk -F'\t' '
    NR == 1 || NF != 5 || $1 == "no-server" { next }
    { t++ }
    $1 == "connected" { c++ }
    $1 == "unknown" { k++ }
    $1 == "needs-auth" || $1 == "failed" || $1 == "not-listed" {
      l = ($4 == "-" ? $3 : $4) " " $1
      labels = labels (labels == "" ? "" : ", ") l
    }
    END { printf "%d/%d\t%s\t%d\n", c, t, labels, k }
  ' "$cache")"
  ct="${out%%$tab*}"; rest="${out#*$tab}"; labels="${rest%$tab*}"; k="${rest##*$tab}"
  if [ -n "$labels" ]; then unr="unreachable: $labels"; else unr="none unreachable"; fi
  [ "${k:-0}" -gt 0 ] 2>/dev/null && unr="$unr; $k unknown"
  h=$(( age / 3600 ))
  if [ "$h" -lt 48 ]; then ago="${h}h"; else ago="$(( age / 86400 ))d"; fi
  printf 'value\t%s\t%s; read %s ago\n' "$ct" "$unr" "$ago"
}

# felix stack --reach [--tsv]: a live read, printed, and the cache written.
# --tsv prints exactly the rows. Otherwise aligned columns under a header, a
# blank line, the counts (total leaves out no-server rows; unknown is counted on
# its own), and a sentence that says what was and was not touched. Always 0:
# an unread list is a report, not a failure.
felix_reach_command() {
  local proj="$1" home="$2" tsv="${3:-0}" rc name p
  p="${proj%/}"; name="${p##*/}"
  if [ "$(_felix_reach_count "$proj")" -eq 0 ]; then
    [ "$tsv" -eq 1 ] || printf '%s declares no plugin or mcp rows; nothing to reach.\n' "$name"
    return 0
  fi
  felix_reach_collect "$proj" "$home"; rc=$?
  if [ "$tsv" -eq 1 ]; then
    [ -z "$_FELIX_REACH_ROWS" ] || printf '%s\n' "$_FELIX_REACH_ROWS"
    return 0
  fi
  printf '%-11s %-7s %-44s %-34s %s\n' STATE KIND NAME SERVER DETAIL
  printf '%s\n' "$_FELIX_REACH_ROWS" | {
    local st kd nm sv dt t=0 c=0 u=0 k=0
    while IFS=$'\t' read -r st kd nm sv dt; do
      [ -n "$st" ] || continue
      printf '%-11s %-7s %-44s %-34s %s\n' "$st" "$kd" "$nm" "$sv" "$dt"
      case "$st" in
        no-server) ;;
        connected) t=$((t+1)); c=$((c+1)) ;;
        unknown)   t=$((t+1)); k=$((k+1)) ;;
        *)         t=$((t+1)); u=$((u+1)) ;;
      esac
    done
    printf '\n%s of %s servers connected; %s unreachable; %s unknown.\n' "$c" "$t" "$u" "$k"
  }
  if [ "$rc" -ne 0 ]; then
    printf 'The server list could not be read (%s); the cache was left as it was.\n' "${_FELIX_REACH_WHY:-no reason given}"
  elif [ "${_FELIX_REACH_STORED:-1}" -eq 0 ]; then
    printf 'Advisory: nothing was installed, enabled or held. Written to %s.\n' "$(felix_reach_cache "$proj" "$home")"
  else
    printf 'Advisory: nothing was installed, enabled or held. The cache could not be written to %s.\n' "$(felix_reach_cache "$proj" "$home")"
  fi
  return 0
}
