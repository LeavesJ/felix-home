printf '\ndeclared tools reach, the pulse settings and reach lines, and felix status\n'
# The contract is docs/2026-10-12-declared-tools-reach-spec.md, and these were
# written from it alone, before any of it was built: R1-R12 (reach), P1-P7 (the
# pulse), S1-S11 (felix status). Each name is the sentence it proves. Some hold
# against the engine before this change too, on purpose: they are what the
# spec says must not change (a needs-auth plugin is still present in the plan,
# the pulse runs no claude, felix status writes nothing, unknown never reads as
# ok or zero, a query string is never printed).
#
# Everything lives in one directory of its own: a Felix home, a HOME, a plugin
# cache, a memory root and stubs for claude, launchctl, uname and jq, so no
# assertion here can read or write the machine's own.
RX="$(mktemp -d "$TMP/rx.XXXXXX")"; RX="$(cd "$RX" && pwd -P)"
RXH="$RX/home"; RXHOME="$RX/user"; RXB="$RX/bin"; RXU="$RX/ubin"; RXPC="$RX/cache"
RXMEM="$RX/memory"; RXLOG="$RX/claude.log"; RXLA="$RX/list-a"; RXPLAIN="$RX/plain"
mkdir -p "$RXH/projects" "$RXH/state" "$RXHOME/.claude" "$RXB" "$RXU" "$RXPC" "$RXMEM" "$RXPLAIN" "$RX/jq"
: > "$RXLOG"
printf '{"enabledPlugins":{"felix@felix":true}}\n' > "$RXHOME/.claude/settings.json"

# A claude that logs every argument line, answers `mcp list` from a file with
# an exit status the test chooses (after a sleep, if asked), says something on
# stderr that must never surface, and refuses every shape it was not taught.
cat > "$RXB/claude" <<'RXCLAUDESTUB'
#!/bin/bash
printf '%s\n' "$*" >> "${RX_LOG:-/dev/null}"
case "$*" in
  "mcp list")
    printf 'RX-STDERR-NOISE\n' >&2
    if [ -n "${RX_SLEEP:-}" ]; then sleep "$RX_SLEEP"; fi
    if [ -n "${RX_LIST:-}" ]; then cat "$RX_LIST"; fi
    exit "${RX_RC:-0}" ;;
  "plugin list") if [ -n "${RX_PLUGINS:-}" ]; then printf '  > %s\n    Status: enabled\n' "$RX_PLUGINS"; fi; exit 0 ;;
  "plugin marketplace list") exit 0 ;;
  *) printf 'stub: untaught shape: %s\n' "$*" >&2; exit 2 ;;
esac
RXCLAUDESTUB
cat > "$RXU/launchctl" <<'RXLAUNCHSTUB'
#!/bin/bash
case "${1:-}" in list) if [ -n "${RX_LAUNCH:-}" ]; then cat "$RX_LAUNCH"; fi; exit "${RX_LAUNCH_RC:-0}" ;; esac
exit 0
RXLAUNCHSTUB
printf '#!/bin/bash\nprintf "%%s\\n" "${UNAME_STUB:-Darwin}"\n' > "$RXU/uname"
printf '#!/bin/bash\nexit 0\n' > "$RX/jq/jq-empty"
printf '#!/bin/bash\nprintf "banana\\n"\n' > "$RX/jq/jq-banana"
printf '#!/bin/bash\nprintf "ok\\n"\nexit 1\n' > "$RX/jq/jq-okfail"
chmod +x "$RXB/claude" "$RXU/launchctl" "$RXU/uname" "$RX/jq/"*

# LIST-A, verbatim from the spec.
cat > "$RXLA" <<'RXLISTA'
Checking MCP server health…

plugin:ctx:ctx: https://mcp.example/mcp?client=claude&key=SECRET (HTTP) - ✔ Connected
plugin:gh:gh: https://api.example/mcp/ (HTTP) - ✘ Failed to connect — HTTP 400: bad request
plugin:cf:cf-api: https://cf.example/mcp (HTTP) - ! Needs authentication
plugin:cf:cf-docs: https://docs.cf.example/mcp (HTTP) - ✔ Connected
plugin:dd:mcp: https://not-setup/v1/mcp?referrer=x (HTTP) - ✘ Failed to connect — ENOTFOUND: TypeError dialing https://not-setup[redacted]?k=REDACTED (ENOTFOUND)
sentry: https://mcp.sentry.example/mcp (HTTP) - ✔ Connected
RXLISTA

# Every command runs through this: the fixture's HOME and home, the stubs first
# on PATH, CLAUDE_CONFIG_DIR and FELIX_JQ unset unless a test sets them.
_rx_env() {
  env -u CLAUDE_CONFIG_DIR -u FELIX_JQ HOME="${RX_HOMEOVR:-$RXHOME}" FELIX_HOME="${RX_FH:-$RXH}" \
      FELIX_HOME_DIR="${RX_FH:-$RXH}" FELIX_MEMORY="$RXMEM" FELIX_PLUGIN_CACHE="$RXPC" \
      PATH="${RX_PATH:-$RXB:$PATH}" RX_LOG="$RXLOG" RX_LIST="${RX_LIST-$RXLA}" RX_RC="${RX_RC:-0}" \
      RX_SLEEP="${RX_SLEEP:-}" RX_PLUGINS="${RX_PLUGINS:-}" "$@"
}
# One lib under /bin/bash, sourced alone after resolve.sh (the house pattern
# says each new lib sources what it needs), then the code given.
_rxl() {
  _rx_env /bin/bash -c '. "$1/lib/resolve.sh" && . "$1/lib/$2.sh" || exit 97; eval "$3"' \
    rxl "$FROOT/harness" "$1" "$2" 2>/dev/null
}
_rx_now() { date +%s; }
_rx_ms() { perl -MTime::HiRes=time -e 'printf "%d\n", time * 1000'; }
_rx_ago() { local e=$(( $(date +%s) - $1 )); date -r "$e" +%Y%m%d%H%M.%S 2>/dev/null || date -d "@$e" +%Y%m%d%H%M.%S; }
_rx_utc() { date -u -r "$1" +%Y-%m-%dT%H:%MZ 2>/dev/null || date -u -d "@$1" +%Y-%m-%dT%H:%MZ; }
_rx_wait() {   # <seconds> <test>: poll five times a second until the test holds
  local i=0 n=$(( $1 * 5 ))
  while [ "$i" -lt "$n" ]; do eval "$2" && return 0; sleep 0.2; i=$((i+1)); done
  eval "$2"
}
_rx_mcpn() { grep -c '^mcp list$' "$RXLOG"; }
_rx_cache() { printf '%s' "$RXH/state/reach/$1.tsv"; }
_rx_put() {   # <project> <epoch> <cwd> <rows file>: a cache written by hand
  mkdir -p "$RXH/state/reach"
  { printf '# read %s %s\n' "$2" "$3"; cat "$4"; } > "$(_rx_cache "$1")"
}
_rx_age() {   # <project> <epoch>: the header's epoch set, the rest kept
  local c; c="$(_rx_cache "$1")"
  sed "1s/^# read [0-9][0-9]* /# read $2 /" "$c" > "$c.rxtmp" && mv -f "$c.rxtmp" "$c"
}
_rx_proj() {
  mkdir -p "$RXH/projects/$1"
  printf '{"name": "%s", "remote_match": "example.com/%s", "gate": "true"}\n' "$1" "$1" > "$RXH/projects/$1/project.json"
  printf '# %s\n' "$1" > "$RXH/projects/$1/CLAUDE.md"
}
_rx_checkout() {   # <dir> <project>
  mkdir -p "$1"
  ( cd "$1" && git init -q -b main && printf '%s\n' "$2" > .felix && printf 'x\n' > f.txt \
    && git add -A && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
}
# has(), without printing a haystack that may be a whole file.
_rx_has() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1" "lacks [$3]" ;; esac; }
_rx_field() { printf '%s\n' "$1" | awk -F'\t' -v r="$2" '$1 == r'; }

# reachy: the spec's R4 project. A marketplace row and a skill row emit
# nothing; gone@m names a capability nobody declared, so it is dormant (D7).
_rx_proj reachy
{ printf 'marketplace\tm\thttps://example.invalid/m\tlow\talways\n'
  for _p in ctx gh cf dd quiet; do printf 'plugin\t%s@m\t-\tlow\talways\n' "$_p"; done
  printf 'plugin\tgone@m\t-\tlow\tnot-a-declared-capability\n'
  printf 'plugin\tlost@m\t-\tlow\talways\n'
  printf 'skill\tsome-skill\t-\tlow\talways\n'
} > "$RXH/projects/reachy/stack.tsv"
mkdir -p "$RXPC/m/quiet/1.0.0" "$RXPC/m/lost/1.0.0"
printf '{"lost": {"command": "npx", "args": ["lost"]}}\n' > "$RXPC/m/lost/1.0.0/.mcp.json"
RXC="$RX/reachy-checkout"; _rx_checkout "$RXC" reachy; RXC="$(cd "$RXC" && pwd -P)"
RXR4="$RX/rows-r4"
printf '%s\t%s\t%s\t%s\t%s\n' \
  connected plugin ctx@m plugin:ctx:ctx 'Connected' \
  failed plugin gh@m plugin:gh:gh 'Failed to connect — HTTP 400: bad request' \
  needs-auth plugin cf@m plugin:cf:cf-api 'Needs authentication' \
  connected plugin cf@m plugin:cf:cf-docs 'Connected' \
  failed plugin dd@m plugin:dd:mcp 'Failed to connect — ENOTFOUND: TypeError dialing https://not-setup[redacted]' \
  no-server plugin quiet@m - 'the plugin declares no MCP server; its reach is its install, which felix stack plan reports' \
  unknown plugin gone@m - 'no installed directory for gone, so whether it ships an MCP server is not known' \
  not-listed plugin lost@m - 'the plugin declares an MCP server and no line of claude mcp list names one' \
  > "$RXR4"
RXR4U="$RX/rows-r4-unread"
for _p in ctx gh cf dd quiet gone lost; do
  printf 'unknown\tplugin\t%s@m\t-\tclaude mcp list exited 1\n' "$_p"
done > "$RXR4U"

# mcpy: mcp rows beside one plugin row.
_rx_proj mcpy
{ printf 'plugin\tcf@m\t-\tlow\talways\n'
  printf 'mcp\tsentry\thttps://mcp.sentry.example/mcp\tlow\talways\n'
  printf 'mcp\tcf-api\thttps://cf.example/mcp\tlow\talways\n'
  printf 'mcp\tnothere\thttps://nothere.example/mcp\tlow\talways\n'
} > "$RXH/projects/mcpy/stack.tsv"
RXM="$RX/mcpy-checkout"; _rx_checkout "$RXM" mcpy; RXM="$(cd "$RXM" && pwd -P)"
RXR6="$RX/rows-r6"
printf '%s\t%s\t%s\t%s\t%s\n' \
  needs-auth plugin cf@m plugin:cf:cf-api 'Needs authentication' \
  connected plugin cf@m plugin:cf:cf-docs 'Connected' \
  connected mcp sentry sentry 'Connected' \
  needs-auth mcp cf-api plugin:cf:cf-api 'Needs authentication' \
  not-listed mcp nothere - 'no line of claude mcp list names this server' \
  > "$RXR6"

# bare: rows the stack does not hold only. nostack: no stack.tsv at all.
_rx_proj bare
printf 'marketplace\tm\thttps://example.invalid/m\tlow\talways\nskill\tsome-skill\t-\tlow\talways\n' \
  > "$RXH/projects/bare/stack.tsv"
RXN="$RX/bare-checkout"; _rx_checkout "$RXN" bare; RXN="$(cd "$RXN" && pwd -P)"
_rx_proj nostack

# shapes: the three manifest shapes of section 0, and two that declare nothing.
_rx_proj shapes
for _p in wrapped top pj emptyj authorurl; do
  printf 'plugin\t%s@m\t-\tlow\talways\n' "$_p"; mkdir -p "$RXPC/m/$_p/2.0.0/.claude-plugin"
done > "$RXH/projects/shapes/stack.tsv"
printf '{"mcpServers": {"w": {"command": "node", "args": ["s.js"]}}}\n' > "$RXPC/m/wrapped/2.0.0/.mcp.json"
printf '{"t": {"type": "http", "url": "https://t.example/mcp"}}\n'      > "$RXPC/m/top/2.0.0/.mcp.json"
printf '{"name": "pj", "mcpServers": "./.dd_claude-code_mcp.json"}\n'  > "$RXPC/m/pj/2.0.0/.claude-plugin/plugin.json"
printf '{}\n'                                                          > "$RXPC/m/emptyj/2.0.0/.mcp.json"
printf '{"name": "authorurl", "author": {"url": "https://a.example"}}\n' > "$RXPC/m/authorurl/2.0.0/.claude-plugin/plugin.json"

# oddy: a prose line, a status phrase nobody knows, a tab and a CR in an error.
_rx_proj oddy
printf 'plugin\tctx@m\t-\tlow\talways\nplugin\tod@m\t-\tlow\talways\nplugin\ttb@m\t-\tlow\talways\n' \
  > "$RXH/projects/oddy/stack.tsv"
RXLO="$RX/list-odd"
{ printf 'Checking MCP server health\342\200\246\n\n'
  printf 'Note on plugin:ctx:ctx: https://evil.example - \342\234\230 Failed to connect\n'
  printf 'plugin:ctx:ctx: https://mcp.example/mcp (HTTP) - \342\234\224 Connected\n'
  printf 'plugin:od:od: https://o.example/x?tok=SECRET (HTTP) - ~ Starting?tok=SECRET\n'
  printf 'plugin:tb:tb: https://t.example/mcp (HTTP) - \342\234\230 Failed to connect \342\200\224 a\tb\rc\n'
} > "$RXLO"

printf '\nreach: the parsing rule, extracted (D3)\n'
_rx_ls() { _rxl stack "_felix_mcp_line_state '$1'"; }
is "a line saying Failed to connect reads failed"                "$(_rx_ls 'k: u - x Failed to connect — e')" "failed"
is "a line saying Needs authentication reads needs-auth"         "$(_rx_ls 'k: u - ! Needs authentication')" "needs-auth"
is "a line saying Connected reads connected"                     "$(_rx_ls 'k: u - x Connected')" "connected"
is "a line saying none of them reads other"                      "$(_rx_ls 'k: u - ~ Starting')" "other"
is "Failed to connect is checked first, before Connected"        "$(_rx_ls 'k: u - Failed to connect — was Connected')" "failed"
is "Needs authentication is checked before Connected"            "$(_rx_ls 'k: u - Needs authentication (Connected once)')" "needs-auth"
_rx_mc() { _rx_env /bin/bash -c '. "$1/lib/resolve.sh"; . "$1/lib/stack.sh"; _FELIX_MCPS="$(cat "$2")"; _felix_mcp_connected "$3"; printf "%s" "$?"' \
             rxl "$FROOT/harness" "$1" "$2" 2>/dev/null; }
printf 'x: https://x.example (HTTP) - ~ Starting\n' > "$RX/list-other"
is "_felix_mcp_connected still mounts a connected server (sentry)"           "$(_rx_mc "$RXLA" sentry)" "0"
is "and still mounts a plugin server it matches by :name: (ctx)"             "$(_rx_mc "$RXLA" ctx)" "0"
is "and still refuses a server that needs authentication (cf-api)"           "$(_rx_mc "$RXLA" cf-api)" "1"
is "and still refuses a server that failed to connect (gh)"                  "$(_rx_mc "$RXLA" gh)" "1"
is "and still refuses a server no line names"                                "$(_rx_mc "$RXLA" nothere)" "1"
is "and still mounts a matching line that says something unrecognised"       "$(_rx_mc "$RX/list-other" x)" "0"

printf '\nreach: one read (R1)\n'
: > "$RXLOG"
is  "a stub that prints LIST-A and exits 0 is read" \
    "$(_rxl reach 'felix_reach_read >/dev/null; printf "%s" "$?"')" "0"
is  "and one read runs claude mcp list exactly once" "$(cat "$RXLOG")" "mcp list"
is  "a stub that prints LIST-A and exits 1 is unread, and says the exit" \
    "$(RX_RC=1 _rxl reach 'felix_reach_read >/dev/null; printf "%s|%s" "$?" "$_FELIX_REACH_WHY"')" "1|claude mcp list exited 1"
is  "a stub that exits 0 and prints nothing is unread, not an empty list (D5)" \
    "$(RX_LIST= _rxl reach 'felix_reach_read >/dev/null; printf "%s|%s" "$?" "$_FELIX_REACH_WHY"')" "1|claude mcp list printed nothing"
if [ -z "$(PATH=/usr/bin:/bin command -v claude 2>/dev/null)" ]; then
  is "no claude on PATH is unread, and says so" \
     "$(RX_PATH=/usr/bin:/bin _rxl reach 'felix_reach_read >/dev/null; printf "%s|%s" "$?" "$_FELIX_REACH_WHY"')" "1|no claude CLI on PATH"
else
  skip "no claude on PATH is unread, and says so" "a claude sits in /usr/bin or /bin here"
fi
_rx_has "an output that could not be captured has its own sentence" \
    "$(cat "$FROOT/harness/lib/reach.sh" 2>/dev/null)" "the list's output could not be captured"

printf '\nreach: the rows (R2-R8)\n'
_rx_rows() { _rxl reach "felix_reach_read >/dev/null; felix_reach_rows '$RXH/projects/$1'"; }
_rxr="$(_rx_rows reachy)"
is  "with LIST-A the reachy rows are R4's eight, in stack order and then list order" "$_rxr" "$(cat "$RXR4")"
_rx_pick() { printf '%s\n' "$1" | awk -F'\t' -v n="$2" -v s="$3" '$3 == n && (s == "" || $4 == s)'; }
is  "a plugin whose server connects reads connected, its server the list's key" \
    "$(_rx_pick "$_rxr" ctx@m)" "$(printf 'connected\tplugin\tctx@m\tplugin:ctx:ctx\tConnected')"
is  "a plugin that ships two servers gets one row for each, in list order (D4)" \
    "$(_rx_pick "$_rxr" cf@m | cut -f1,4)" "$(printf 'needs-auth\tplugin:cf:cf-api\nconnected\tplugin:cf:cf-docs')"
is  "a plugin with no installed directory reads unknown, never ok (D8)" \
    "$(_rx_pick "$_rxr" gone@m | cut -f1)" "unknown"
is  "and a dormant row is read like any other (D7)" "$(_rx_pick "$_rxr" gone@m | grep -c .)" "1"
is  "a plugin whose directory declares no server reads no-server" "$(_rx_pick "$_rxr" quiet@m | cut -f1)" "no-server"
is  "a plugin that declares a server no line names reads not-listed" "$(_rx_pick "$_rxr" lost@m | cut -f1)" "not-listed"
is  "marketplace and skill rows emit nothing" \
    "$(printf '%s\n' "$_rxr" | awk -F'\t' '$2 != "plugin" && $2 != "mcp"' | grep -c .)" "0"
is  "every row is five tab fields, a known state, and a detail never empty" \
    "$(printf '%s\n' "$_rxr" | awk -F'\t' 'NF != 5 || $1 !~ /^(connected|needs-auth|failed|not-listed|no-server|unknown)$/ || $5 == "" { print NR }')" ""
is  "an unread list gives one unknown row per plugin row, its reason as the detail" \
    "$(RX_RC=1 _rx_rows reachy)" "$(cat "$RXR4U")"
_rxs="$(_rx_rows shapes)"
is  "a .mcp.json wrapping servers in mcpServers declares a server (R5)"   "$(_rx_pick "$_rxs" wrapped@m | cut -f1)" "not-listed"
is  "a .mcp.json with servers at the top level declares a server"         "$(_rx_pick "$_rxs" top@m | cut -f1)" "not-listed"
is  "a plugin.json naming mcpServers declares a server"                   "$(_rx_pick "$_rxs" pj@m | cut -f1)" "not-listed"
is  "an empty .mcp.json declares nothing (D6)"                            "$(_rx_pick "$_rxs" emptyj@m | cut -f1)" "no-server"
is  "a plugin.json carrying only an author url declares nothing"          "$(_rx_pick "$_rxs" authorurl@m | cut -f1)" "no-server"
_rx_src_pipe="$(awk '/\|[[:space:]]*grep -q/ { print FILENAME ":" FNR }' "$FROOT/harness/lib/reach.sh" 2>/dev/null)"
if [ -f "$FROOT/harness/lib/reach.sh" ]; then is "and reach.sh pipes nothing into grep -q" "$_rx_src_pipe" ""
else bad "and reach.sh pipes nothing into grep -q" "there is no lib/reach.sh"; fi
is  "with LIST-A the mcp rows match by key or :name:, and an unnamed one reads not-listed (R6)" \
    "$(_rx_rows mcpy)" "$(cat "$RXR6")"
_rxo="$(RX_LIST="$RXLO" _rx_rows oddy)"
is  "a line whose key holds a space is prose and is ignored (R2)" "$(_rx_pick "$_rxo" ctx@m | cut -f1)" "connected"
is  "a status nobody knows reads unknown, its detail after the last ' - ' and before any ?" \
    "$(_rx_pick "$_rxo" od@m)" "$(printf 'unknown\tplugin\tod@m\tplugin:od:od\t~ Starting')"
is  "a tab or a CR inside an error becomes a space, so the row keeps five fields (R3)" \
    "$(_rx_pick "$_rxo" tb@m)" "$(printf 'failed\tplugin\ttb@m\tplugin:tb:tb\tFailed to connect \342\200\224 a b c')"
is  "the oddy rows are exactly three" "$(printf '%s\n' "$_rxo" | grep -c .)" "3"
for _w in SECRET REDACTED client= referrer '?' mcp.example; do
  case "$_rxr$_rxo" in *"$_w"*) bad "no row carries a query string or the target column: $_w" "$_rxr" ;;
                       *) ok "no row carries a query string or the target column: $_w" ;; esac
done
is  "the dd detail is the error, cut before its query string (R7)" \
    "$(_rx_pick "$_rxr" dd@m | cut -f5)" "Failed to connect — ENOTFOUND: TypeError dialing https://not-setup[redacted]"
is  "a project with only marketplace and skill rows emits nothing (R8)" "$(_rx_rows bare)" ""
is  "a project with no stack.tsv emits nothing"                         "$(_rx_rows nostack)" ""

printf '\nreach: the cache (R9) and when it is due\n'
is  "felix_reach_cache names state/reach/<project>.tsv under the home" \
    "$(_rxl reach "felix_reach_cache '$RXH/projects/reachy' '$RXH'")" "$(_rx_cache reachy)"
_rx_t0="$(_rx_now)"
_rxf="$(cd "$RXC" && _rxl reach "felix_reach_refresh '$RXH/projects/reachy' '$RXH'")"; _rxfrc=$?
is  "a refresh prints the rows" "$_rxf" "$(cat "$RXR4")"
is  "and returns the read's status, 0 when read" "$_rxfrc" "0"
_rxhd="$(head -1 "$(_rx_cache reachy)" 2>/dev/null)"
case "$_rxhd" in "# read "[0-9]*" $RXC") ok "the cache opens # read <epoch> <the directory the read ran in>" ;;
                 *) bad "the cache opens # read <epoch> <the directory the read ran in>" "$_rxhd" ;; esac
_rxe="${_rxhd#\# read }"; _rxe="${_rxe%% *}"
case "$_rxe" in ''|*[!0-9]*) _rxe=0 ;; esac
[ $(( _rxe - _rx_t0 )) -ge -5 ] && [ $(( _rxe - _rx_t0 )) -le 5 ] \
  && ok "and its epoch is the time of the read" || bad "and its epoch is the time of the read" "$_rxhd"
if [ -s "$(_rx_cache reachy)" ]; then
  is "and the rest of it is exactly the rows the refresh printed" "$(tail -n +2 "$(_rx_cache reachy)")" "$_rxf"
else
  bad "and the rest of it is exactly the rows the refresh printed" "no cache was written"
fi
_rxn=0; for _f in "$RXH/state/reach/"*.new.*; do [ -e "$_f" ] && _rxn=$((_rxn+1)); done
is  "and no temporary file is left beside it" "$_rxn" "0"
cp "$(_rx_cache reachy)" "$RX/cache.keep" 2>/dev/null
_rxf="$(cd "$RXC" && RX_RC=1 _rxl reach "felix_reach_refresh '$RXH/projects/reachy' '$RXH'")"; _rxfrc=$?
is  "an unread list returns 1 from the refresh" "$_rxfrc" "1"
cmp -s "$RX/cache.keep" "$(_rx_cache reachy)" && [ -s "$RX/cache.keep" ] \
  && ok "and leaves the existing cache byte-identical" || bad "and leaves the existing cache byte-identical"
( cd "$RXM" && RX_RC=1 _rxl reach "felix_reach_refresh '$RXH/projects/mcpy' '$RXH'" ) >/dev/null
[ -e "$(_rx_cache mcpy)" ] && bad "an unread list creates no cache" || ok "an unread list creates no cache"
( cd "$RXN" && _rxl reach "felix_reach_refresh '$RXH/projects/bare' '$RXH'" ) >/dev/null
[ -e "$(_rx_cache bare)" ] && bad "a project with no plugin or mcp row gets no cache" || ok "a project with no plugin or mcp row gets no cache"
_rx_due() { _rxl reach "felix_reach_due '$RXH/projects/$1' '$RXH'" >/dev/null; printf '%s' "$?"; }
is  "a cache read under 24 hours ago is not due" "$(_rx_due reachy)" "1"
_rx_age reachy "$(( $(_rx_now) - 90000 ))"
is  "a cache whose header was read 25 hours ago is due, though the file was just written (D9)" "$(_rx_due reachy)" "0"
_rx_age reachy "$(( $(_rx_now) - 3600 ))"; touch -t "$(_rx_ago 172800)" "$(_rx_cache reachy)"
is  "and a header an hour old is not due, though the file's mtime is two days old" "$(_rx_due reachy)" "1"
is  "an absent cache is due" "$(_rx_due mcpy)" "0"
printf 'garbage\n' > "$(_rx_cache mcpy)"
is  "a cache whose first line is not # read <digits> is absent, so due" "$(_rx_due mcpy)" "0"
rm -f "$(_rx_cache mcpy)"
is  "a project that declares no plugin or mcp row is never due" "$(_rx_due bare)" "1"

printf '\nreach: the SessionStart refresh (R10)\n'
_rx_hook() { ( cd "$RXC" && _rx_env CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" ) 2>/dev/null; }
_rx_lock="$RXH/state/reach/reachy.lock"
rm -f "$(_rx_cache reachy)"; : > "$RXLOG"
_rxho="$(_rx_hook)"; _rxhrc=$?
for _w in reach needs-auth not-listed 'Failed to connect' 'Needs authentication'; do
  # The fixture project is called reachy, and the hook names its project, so
  # the project's own name is taken out before the word is looked for.
  case "$(printf '%s' "$_rxho" | sed 's/reachy//g')" in
    *"$_w"*) bad "nothing about reach reaches the session: $_w" "$(printf '%s' "$_rxho" | grep -i "$_w" | head -3)" ;;
                   *) ok "nothing about reach reaches the session: $_w" ;; esac
done
is  "the hook exits 0" "$_rxhrc" "0"
is  "and its stdout is still valid JSON" \
    "$(printf '%s' "$_rxho" | python3 -c 'import json,sys; json.load(sys.stdin); print("json")' 2>&1)" "json"
_rx_wait 10 '[ -s "$(_rx_cache reachy)" ] && [ ! -d "$_rx_lock" ]' && _rxhook=1 || _rxhook=0
[ "$_rxhook" = 1 ] && ok "with the cache absent, a session start writes one within 10 s" \
                   || bad "with the cache absent, a session start writes one within 10 s" "no cache, or the lock is still held"
case "$(head -1 "$(_rx_cache reachy)" 2>/dev/null)" in
  "# read "[0-9]*" $RXC") ok  "and its header's directory is the checkout root" ;;
  *)                      bad "and its header's directory is the checkout root" "$(head -1 "$(_rx_cache reachy)" 2>/dev/null)" ;;
esac
is  "and its rows are R4's" "$(tail -n +2 "$(_rx_cache reachy)" 2>/dev/null)" "$(cat "$RXR4")"
_rxw=10; [ "$_rxhook" = 1 ] || _rxw=1
_rxn0="$(_rx_mcpn)"; _rx_hook >/dev/null; [ "$_rxhook" = 1 ] && sleep 2
is  "a cache read under 24 hours ago starts no read at the next session" "$(_rx_mcpn)" "$_rxn0"
[ -f "$(_rx_cache reachy)" ] || _rx_put reachy 0 "$RXC" "$RXR4"
_rx_age reachy "$(( $(_rx_now) - 90000 ))"; _rx_hook >/dev/null
_rx_wait "$_rxw" '_e="$(head -1 "$(_rx_cache reachy)")"; _e="${_e#\# read }"; _e="${_e%% *}"; [ "${_e:-0}" -ge $(( $(_rx_now) - 60 )) ] 2>/dev/null' \
  && ok "a cache whose header is 90,000 s old is refreshed by the next session" \
  || bad "a cache whose header is 90,000 s old is refreshed by the next session" "$(head -1 "$(_rx_cache reachy)")"
_rx_wait "$_rxw" '[ ! -d "$_rx_lock" ]'
_rx_age reachy "$(( $(_rx_now) - 90000 ))"; cp "$(_rx_cache reachy)" "$RX/cache.keep"
_rxn0="$(_rx_mcpn)"; RX_RC=1 _rx_hook >/dev/null
_rx_wait "$_rxw" '[ "$(_rx_mcpn)" -gt "$_rxn0" ] && [ ! -d "$_rx_lock" ]' \
  && ok "a due cache with a failing list still asks the list" || bad "a due cache with a failing list still asks the list"
cmp -s "$RX/cache.keep" "$(_rx_cache reachy)" \
  && ok "and the cache is byte-identical after the refresh has had its time" \
  || bad "and the cache is byte-identical after the refresh has had its time"
mkdir -p "$_rx_lock"; _rxn0="$(_rx_mcpn)"; _rx_hook >/dev/null; [ "$_rxhook" = 1 ] && sleep 2
is  "a fresh lock directory holds the refresh off" "$(_rx_mcpn)" "$_rxn0"
touch -t "$(_rx_ago 1860)" "$_rx_lock"; _rx_hook >/dev/null
_rx_wait "$_rxw" '[ "$(_rx_mcpn)" -gt "$_rxn0" ]' \
  && ok "a lock 31 minutes old is broken and the refresh runs (D10)" \
  || bad "a lock 31 minutes old is broken and the refresh runs (D10)"
_rx_wait "$_rxw" '[ ! -d "$_rx_lock" ]'
rmdir "$_rx_lock" 2>/dev/null
_rx_age reachy "$(( $(_rx_now) - 90000 ))"
_rxt0="$(_rx_ms)"; RX_SLEEP=5 _rx_hook >/dev/null; _rxhrc=$?; _rxt1="$(_rx_ms)"
[ $(( _rxt1 - _rxt0 )) -lt 3000 ] && ok "with a list that takes 5 s the hook still returns in under 3 s" \
  || bad "with a list that takes 5 s the hook still returns in under 3 s" "$(( _rxt1 - _rxt0 )) ms"
is  "and exits 0" "$_rxhrc" "0"
_rx_wait 10 '[ ! -d "$_rx_lock" ]'

printf '\nreach: felix stack --reach (R11)\n'
_rx_stk() { ( cd "$1" && shift && _rx_env "$FELIX" stack "$@" 2>"$RX/err" ); }
rm -f "$(_rx_cache reachy)"; : > "$RXLOG"
_rxso="$(_rx_stk "$RXC" --reach --tsv)"; _rxsrc=$?
is  "felix stack --reach --tsv prints exactly the rows, no header and no summary" "$_rxso" "$(cat "$RXR4")"
is  "and exits 0" "$_rxsrc" "0"
is  "and runs one claude command, mcp list, and no plugin or marketplace list" "$(cat "$RXLOG")" "mcp list"
case "$_rxso$(cat "$RX/err")" in *RX-STDERR-NOISE*) bad "the list's stderr is discarded" ;; *) ok "the list's stderr is discarded" ;; esac
case "$(head -1 "$(_rx_cache reachy)" 2>/dev/null)" in
  "# read "[0-9]*" $RXC") ok  "and it writes the cache, read from the checkout the person stands in" ;;
  *)                      bad "and it writes the cache, read from the checkout the person stands in" ;;
esac
_rxso="$(_rx_stk "$RXC" --reach)"; _rxsrc=$?
_rxexp="$( printf '%-11s %-7s %-44s %-34s %s\n' STATE KIND NAME SERVER DETAIL
           while IFS="$(printf '\t')" read -r _a _b _c _d _e; do
             printf '%-11s %-7s %-44s %-34s %s\n' "$_a" "$_b" "$_c" "$_d" "$_e"; done < "$RXR4"
           printf '\n2 of 7 servers connected; 4 unreachable; 1 unknown.\n'
           printf 'Advisory: nothing was installed, enabled or held. Written to %s.\n' "$(_rx_cache reachy)" )"
is  "the human form is the header, the aligned rows, a blank line, the count and the advisory" "$_rxso" "$_rxexp"
has "the count leaves no-server out of the total and counts unknown on its own" "$_rxso" "2 of 7 servers connected; 4 unreachable; 1 unknown."
is  "and exits 0" "$_rxsrc" "0"
cp "$(_rx_cache reachy)" "$RX/cache.keep" 2>/dev/null
_rxso="$(RX_RC=1 _rx_stk "$RXC" --reach)"; _rxsrc=$?
has "an unread list says so, and that the cache was left" "$_rxso" \
    "The server list could not be read (claude mcp list exited 1); the cache was left as it was."
has "and counts every row unknown, none connected" "$_rxso" "0 of 7 servers connected; 0 unreachable; 7 unknown."
is  "and still exits 0" "$_rxsrc" "0"
cmp -s "$RX/cache.keep" "$(_rx_cache reachy)" && ok "and the cache is untouched" || bad "and the cache is untouched"
is  "and --tsv on an unread list prints one unknown row per plugin row" "$(RX_RC=1 _rx_stk "$RXC" --reach --tsv)" "$(cat "$RXR4U")"
_rxso="$(_rx_stk "$RXN" --reach)"; _rxsrc=$?
is  "a project with no plugin or mcp row says there is nothing to reach" "$_rxso" "bare declares no plugin or mcp rows; nothing to reach."
is  "and exits 0" "$_rxsrc" "0"
[ -e "$(_rx_cache bare)" ] && bad "and writes no cache" || ok "and writes no cache"
for _args in "--reach --json" "--reach --tsv --tsv" "--reach plan"; do
  # shellcheck disable=SC2086
  _rxso="$(_rx_stk "$RXC" $_args)"; _rxsrc=$?
  is  "felix stack $_args is a usage error, exit 2" "$_rxsrc" "2"
  is  "and prints nothing on stdout ($_args)" "$_rxso" ""
  has "and names both forms on stderr through die ($_args)" "$(cat "$RX/err")" \
      "felix: usage: felix stack [plan|apply|reconcile] [--yes] | felix stack --reach [--tsv]"
done
: > "$RXLOG"
_rxso="$(_rx_stk "$RXC" apply --yes --reach)"; _rxsrc=$?
is  "felix stack apply --yes --reach is refused with exit 2 (D1)" "$_rxsrc" "2"
is  "and runs no claude command, so installs nothing" "$(cat "$RXLOG")" ""
is  "and prints nothing on stdout" "$_rxso" ""
_rxpa="$(_rx_stk "$RXM" plan)"; _rxpb="$(_rx_stk "$RXM")"
is  "bare felix stack still answers what felix stack plan answers" "$_rxpb" "$_rxpa"
has "and felix stack apply without --yes still changes nothing" "$(_rx_stk "$RXM" apply)" "Nothing changed"

printf '\nreach: advisory only (R12)\n'
_rxpo="$(RX_PLUGINS='cf@m' _rx_stk "$RXM" plan)"
_rx_pl() { printf '%s\n' "$_rxpo" | awk -v n="$1" '!f { for (i = 1; i <= NF; i++) if ($i == n) { print; f = 1; break } }'; }
has "plugin cf@m reads present in the plan, though its server cf-api needs authentication" "$(_rx_pl cf@m)" "present"
has "mcp sentry reads present in the plan" "$(_rx_pl sentry)" "present"
case "$(_rx_pl cf-api)" in *present*) bad "and mcp cf-api, matched through :cf-api:, is not present" "$(_rx_pl cf-api)" ;;
                           "") bad "and mcp cf-api, matched through :cf-api:, is not present" "no plan line" ;;
                           *) ok "and mcp cf-api, matched through :cf-api:, is not present" ;; esac
_rxsr=""
for _f in "$FROOT/harness/felix" "$FROOT/harness/lib/"*.sh "$FROOT/harness/hooks/"* "$FROOT/harness/bin/"*; do
  [ -f "$_f" ] || continue
  case "$(cat "$_f")" in *state/reach*) _rxsr="$_rxsr ${_f#"$FROOT/harness/"}" ;; esac
done
is  "of felix, lib, hooks and bin, only lib/reach.sh names state/reach" "$_rxsr" " lib/reach.sh"
_rx_head() { awk '/^[A-Za-z_][A-Za-z0-9_]*\(\)/ { exit } /^#/ { sub(/^#+ */, ""); printf "%s ", $0 }' "$1" 2>/dev/null | tr -s ' '; }
_rxhc="$(_rx_head "$FROOT/harness/lib/reach.sh")"
for _w in "invariant 2" "detached" "the gate" "Stop hook" "commissioning" "felix stack plan"; do
  has "reach.sh's head says why invariant 2 holds, naming: $_w" "$_rxhc" "$_w"
done

printf '\nthe pulse: the settings check (P1)\n'
RXJQ="$(command -v jq 2>/dev/null)"
_rx_si=0
_rx_set() { _rx_si=$((_rx_si+1)); RXS="$RX/s$_rx_si"; mkdir -p "$RXS/.claude"; RXSP="$RXS/.claude/settings.json"
            [ "$1" = "-" ] || printf '%s' "$1" > "$RXSP"; }
_rx_ss() { RX_HOMEOVR="$RXS" _rxl status "${1:-} _o=\"\$(felix_settings_state)\"; _r=\$?; printf '%s|%s' \"\$_o\" \"\$_r\""; }
_rx_set -
is "no settings file reads missing, and the check returns 0" "$(_rx_ss)" "$(printf 'missing\t%s does not exist|0' "$RXSP")"
_rx_set '{"enabledPlugins":{"felix@felix":true}}'
is "with no parser the answer is unknown, and the file is not read (D13)" \
   "$(_rx_ss 'export FELIX_JQ=/nonexistent;')" "$(printf 'unknown\tno JSON parser on this machine (jq); %s was not read|0' "$RXSP")"
is "a parser that exits 0 and prints nothing reads invalid, never ok" \
   "$(_rx_ss "export FELIX_JQ='$RX/jq/jq-empty';" | cut -f1)" "invalid"
is "a parser that answers something unknown reads unknown" \
   "$(_rx_ss "export FELIX_JQ='$RX/jq/jq-banana';")" "$(printf 'unknown\tthe parser answered something this check does not know|0')"
case "$(_rx_ss "export FELIX_JQ='$RX/jq/jq-okfail';")" in
  ok*|"") bad "a parser that prints ok and exits 1 is not ok" "$(_rx_ss "export FELIX_JQ='$RX/jq/jq-okfail';")" ;;
  *)      ok  "a parser that prints ok and exits 1 is not ok" ;;
esac
if [ "$(id -u)" != 0 ]; then
  chmod 000 "$RXSP"
  is "a settings file that is not readable reads unknown" "$(_rx_ss)" "$(printf 'unknown\t%s is not readable|0' "$RXSP")"
  chmod 644 "$RXSP"
else
  skip "a settings file that is not readable reads unknown" "root reads everything"
fi
if [ -n "$RXJQ" ]; then
  _rx_set '{"enabledPlugins":{"felix@felix":true}}'
  is "felix@felix enabled reads ok" "$(_rx_ss)" "$(printf 'ok\t%s enables felix@felix|0' "$RXSP")"
  _rx_set '{"enabledPlugins":{"felix@felix":false}}'
  is "felix@felix false reads felix-off, quoting false" "$(_rx_ss)" \
     "$(printf 'felix-off\t%s does not enable felix@felix (enabledPlugins["felix@felix"] reads false)|0' "$RXSP")"
  _rx_set '{}'
  is "an empty object reads felix-off, quoting null" "$(_rx_ss)" \
     "$(printf 'felix-off\t%s does not enable felix@felix (enabledPlugins["felix@felix"] reads null)|0' "$RXSP")"
  _rx_set '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"/x/engine/harness/hooks/session-start"}]}]}}'
  is "felix-off with a session-start hook in the file says the hook is registered by hand" "$(_rx_ss)" \
     "$(printf 'felix-off\t%s does not enable felix@felix (enabledPlugins["felix@felix"] reads null); a session-start hook is registered by hand|0' "$RXSP")"
  _rx_set '{"enabledPlugins":'
  case "$(_rx_ss)" in "$(printf 'invalid\t%s does not parse as JSON: ' "$RXSP")"?*) ok "a truncated file reads invalid, with the parser's first line" ;;
                      *) bad "a truncated file reads invalid, with the parser's first line" "$(_rx_ss)" ;; esac
  _rx_set ''
  is "an empty file reads invalid" "$(_rx_ss)" "$(printf 'invalid\t%s is empty|0' "$RXSP")"
  _rx_set '[]'
  is "a top level that is not an object reads invalid" "$(_rx_ss)" "$(printf 'invalid\t%s parses, and its top level is not an object|0' "$RXSP")"
  _rx_set '-'; mkdir -p "$RX/ccd"; printf '{"enabledPlugins":{"felix@felix":true}}' > "$RX/ccd/settings.json"
  is "CLAUDE_CONFIG_DIR names the settings file read (D12)" "$(_rx_ss "export CLAUDE_CONFIG_DIR='$RX/ccd';")" \
     "$(printf 'ok\t%s enables felix@felix|0' "$RX/ccd/settings.json")"
else
  for _w in "felix@felix enabled reads ok" "felix@felix false reads felix-off, quoting false" \
            "an empty object reads felix-off, quoting null" \
            "felix-off with a session-start hook in the file says the hook is registered by hand" \
            "a truncated file reads invalid, with the parser's first line" "an empty file reads invalid" \
            "a top level that is not an object reads invalid" "CLAUDE_CONFIG_DIR names the settings file read (D12)"; do
    skip "$_w" "no jq on PATH"
  done
fi

printf '\nthe pulse: settings and reach lines, the record (P2-P7)\n'
_rx_put reachy "$(_rx_now)" "$RXC" "$RXR4"
rm -f "$(_rx_cache mcpy)" "$(_rx_cache shapes)"
printf 'garbage\n' > "$(_rx_cache oddy)"
: > "$RXLOG"; _rx_t0="$(_rx_now)"
_rxpu="$(cd "$RXC" && _rx_env "$FELIX" pulse 2>/dev/null)"; _rxprc=$?
is  "felix pulse exits 0 whatever the settings or the reach lines say (P7)" "$_rxprc" "0"
is  "felix pulse runs no claude command (P4)" "$(cat "$RXLOG")" ""
_rxsl="$(printf '%s\n' "$_rxpu" | awk -F'\t' '$1 == "settings" { print NR }')"
_rxrl="$(printf '%s\n' "$_rxpu" | awk -F'\t' '$1 ~ /^(due|unchecked|unknown|stale|unreachable|reach-unknown|reach-stale|reach-unread)$/ { print NR; exit }')"
is  "felix pulse prints one settings line (P2)" "$(printf '%s\n' "$_rxpu" | awk -F'\t' '$1 == "settings"' | grep -c .)" "1"
if [ -n "$RXJQ" ]; then
  is "and it is the settings check's answer" "$(_rx_field "$_rxpu" settings)" \
     "$(printf 'settings\tok\t%s enables felix@felix' "$RXHOME/.claude/settings.json")"
else
  skip "and it is the settings check's answer" "no jq on PATH"
fi
[ "${_rxsl:-0}" -gt 2 ] && ok "and it comes after the backup lines" || bad "and it comes after the backup lines" "$_rxpu"
[ -n "$_rxsl" ] && [ -n "$_rxrl" ] && [ "$_rxsl" -lt "$_rxrl" ] && ok "and before the report lines" \
  || bad "and before the report lines" "$_rxpu"
_rx_kind() { printf '%s\n' "$_rxpu" | awk -F'\t' -v k="$1" -v p="$2" '$1 == k && $2 == p'; }
is  "a cache's needs-auth, failed and not-listed rows are unreachable lines, in cache order (P3)" \
    "$(_rx_kind unreachable reachy)" \
    "$(printf 'unreachable\treachy\t%s\n' 'gh@m plugin:gh:gh failed' 'cf@m plugin:cf:cf-api needs-auth' 'dd@m plugin:dd:mcp failed' 'lost@m - not-listed')"
is  "and its unknown rows are one reach-unknown line naming them" "$(_rx_kind reach-unknown reachy)" \
    "$(printf 'reach-unknown\treachy\t1 declared row(s) whose reach is not known: gone@m')"
is  "and a fresh cache prints no reach-stale line" "$(_rx_kind reach-stale reachy)" ""
_rxrr="$(printf '%s\n' "$_rxpu" | awk -F'\t' '$1 ~ /^(unreachable|reach-)/ && $2 == "reachy"')"
for _w in ctx@m cf-docs quiet@m; do
  case "$_rxrr" in *"$_w"*) bad "connected and no-server rows print nothing: $_w" "$_rxrr" ;; *) ok "connected and no-server rows print nothing: $_w" ;; esac
done
is  "a project with declared rows and no cache gets one reach-unread line" "$(_rx_kind reach-unread mcpy)" \
    "$(printf 'reach-unread\tmcpy\t4 declared plugin or mcp row(s) and no reach cache; the next session in its checkout reads one, or run felix stack --reach there')"
has "and a cache with no valid header reads as no cache" "$(_rx_kind reach-unread oddy)" "3 declared plugin or mcp row(s) and no reach cache"
is  "a project with no plugin or mcp row gets no reach line" \
    "$(printf '%s\n' "$_rxpu" | awk -F'\t' '$1 ~ /^(unreachable|reach-)/ && ($2 == "bare" || $2 == "nostack")')" ""
for _w in SECRET REDACTED client= referrer '?'; do
  case "$_rxpu" in *"$_w"*) bad "no pulse line carries a query string: $_w" ;; *) ok "no pulse line carries a query string: $_w" ;; esac
done
_rxrec="$RXH/state/pulse.status.tsv"
case "$(head -1 "$_rxrec" 2>/dev/null)" in "# ran "[0-9]*) ok "the run writes state/pulse.status.tsv opening # ran <epoch> (P5)" ;;
     *) bad "the run writes state/pulse.status.tsv opening # ran <epoch> (P5)" "$(head -1 "$_rxrec" 2>/dev/null)" ;; esac
_rxe="$(head -1 "$_rxrec" 2>/dev/null)"; _rxe="${_rxe#\# ran }"; case "$_rxe" in ''|*[!0-9]*) _rxe=0 ;; esac
[ $(( _rxe - _rx_t0 )) -ge -5 ] && [ $(( _rxe - _rx_t0 )) -le 5 ] && ok "and its epoch is the run's" \
  || bad "and its epoch is the run's" "$_rxe against $_rx_t0"
is  "and the rest is every line the run printed after its header, in order" \
    "$(tail -n +2 "$_rxrec" 2>/dev/null)" "$(printf '%s\n' "$_rxpu" | tail -n +2)"
is  "and the log gains exactly what was printed" \
    "$(tail -n "$(printf '%s\n' "$_rxpu" | grep -c '')" "$RXH/state/pulse.log" 2>/dev/null)" "$_rxpu"
_rxn=0; for _f in "$RXH/state/"pulse.status.tsv.new.*; do [ -e "$_f" ] && _rxn=$((_rxn+1)); done
is  "and no temporary record is left" "$_rxn" "0"
_rx_age reachy "$(( $(_rx_now) - 8 * 86400 ))"
_rxpu="$(cd "$RXC" && _rx_env "$FELIX" pulse 2>/dev/null)"
is  "a cache read 8 days ago adds a reach-stale line" "$(_rx_kind reach-stale reachy)" \
    "$(printf 'reach-stale\treachy\tthe reach cache was read 8 days ago')"
RXP2="$RX/pulse-home2"; mkdir -p "$RXP2/projects" "$RXP2/state" "$RX/pulse-user2"
( cd "$RXPLAIN" && RX_FH="$RXP2" RX_HOMEOVR="$RX/pulse-user2" RX_PATH="$RXU:$RXB:$PATH" \
  _rx_env UNAME_STUB=Darwin "$FELIX" pulse --install ) >/dev/null 2>&1
( cd "$RXPLAIN" && RX_FH="$RXP2" RX_HOMEOVR="$RX/pulse-user2" RX_PATH="$RXU:$RXB:$PATH" \
  _rx_env UNAME_STUB=Darwin "$FELIX" pulse --uninstall ) >/dev/null 2>&1
[ -e "$RXP2/state/pulse.status.tsv" ] && bad "pulse --install and --uninstall write no record" \
                                      || ok  "pulse --install and --uninstall write no record"
RXP3="$RX/pulse-home3"; mkdir -p "$RXP3/projects" "$RXP3/state/pulse.log"
( cd "$RXPLAIN" && RX_FH="$RXP3" _rx_env "$FELIX" pulse ) >/dev/null 2>&1
case "$(head -1 "$RXP3/state/pulse.status.tsv" 2>/dev/null)" in
  "# ran "[0-9]*) ok  "the record is written even when the log append fails" ;;
  *)              bad "the record is written even when the log append fails" ;;
esac
_rxph="$(_rx_head "$FROOT/harness/lib/pulse.sh")"
case "$_rxph" in *"Duties, deliberately two"*) bad "pulse.sh's header no longer says two duties (P6)" ;; *) ok "pulse.sh's header no longer says two duties (P6)" ;; esac
has "and it names the record" "$_rxph" "state/pulse.status.tsv"
has "and the settings duty"   "$_rxph" "settings"
has "and the reach duty"      "$_rxph" "reach"
has "and it keeps the sentence that nothing here schedules itself" "$_rxph" "nothing here schedules itself"
_rx_has "the pulse says why it runs no claude: launchd's bash holds Full Disk Access (P4)" \
    "$(cat "$FROOT/harness/lib/pulse.sh" "$FROOT/harness/felix" 2>/dev/null)" "Full Disk Access"

printf '\nfelix status (S1-S11)\n'
RXLT="$RX/launch-table"
printf 'PID\tStatus\tLabel\n-\t0\tcom.example.other\n-\t0\tfelix.pulse\n' > "$RXLT"
mkdir -p "$RXHOME/Library/LaunchAgents"; printf '<plist/>\n' > "$RXHOME/Library/LaunchAgents/felix.pulse.plist"
_rx_st() {   # <dir> [args]: felix status from there, launchctl and uname stubbed
  local d="$1"; shift
  ( cd "$d" && RX_PATH="$RXU:$RXB:$PATH" _rx_env UNAME_STUB="${UNAME_STUB_RX:-Darwin}" \
      RX_LAUNCH="${RX_LAUNCH:-$RXLT}" RX_LAUNCH_RC="${RX_LAUNCH_RC:-0}" FELIX_JQ="${RX_JQ:-}" \
      "$FELIX" status "$@" 2>"$RX/err" )
}
_rx_put reachy "$(( $(_rx_now) - 3630 ))" "$RXC" "$RXR4"
_rxst="$(_rx_st "$RXC" --tsv)"; _rxstrc=$?
is  "felix status --tsv exits 0" "$_rxstrc" "0"
is  "and prints exactly five rows: settings, schedule, pulse, reach, gate" \
    "$(printf '%s\n' "$_rxst" | cut -f1 | tr '\n' ' ')" "settings schedule pulse reach gate "
is  "every row is four tab fields, a known state, - unless the state is value, a detail, and a bare value (D16)" \
    "$(printf '%s\n' "$_rxst" | awk -F'\t' 'NF != 4 || $2 !~ /^(value|none|unknown)$/ || ($2 != "value" && $3 != "-") || $4 == "" || $3 ~ / / { print NR }')" ""
_rxhu="$(_rx_st "$RXC")"
is  "felix status prints the same rows, aligned, with no header (S2, D17)" "$_rxhu" \
    "$(printf '%s\n' "$_rxst" | awk -F'\t' '{ s = ($2 == "value") ? $3 : $2; printf "%-9s %-12s %s\n", $1, s, $4 }')"
for _args in "--json" "--tsv --tsv" "plan"; do
  # shellcheck disable=SC2086
  _rxso="$(_rx_st "$RXC" $_args)"; _rxsrc=$?
  is  "felix status $_args is a usage error, exit 2 (S3)" "$_rxsrc" "2"
  is  "and prints nothing on stdout ($_args)" "$_rxso" ""
  has "and says its usage through die ($_args)" "$(cat "$RX/err")" "felix: usage: felix status [--tsv]"
done
_rxso="$(_rx_st "$RXC" --help)"; _rxsrc=$?
is  "felix status --help exits 0" "$_rxsrc" "0"
_rx_has "and prints the general usage, which names felix status" "$_rxso" "felix status [--tsv]"
( cd "$RXC" && touch f.txt ); mkdir -p "$RXH/state"; sleep 1; touch "$RX/marker"; : > "$RXLOG"
_rxst="$(_rx_st "$RXC" --tsv)"
if [ "$(printf '%s\n' "$_rxst" | grep -c .)" = 5 ]; then
  is "felix status writes nothing under the home's state, the memory root or the checkout, .git included (S4)" \
     "$(find "$RXH/state" "$RXMEM" "$RXC" -newer "$RX/marker" 2>/dev/null)" ""
  is "and runs no claude command" "$(cat "$RXLOG")" ""
else
  bad "felix status writes nothing under the home's state, the memory root or the checkout, .git included (S4)" "status did not answer five rows"
  bad "and runs no claude command" "status did not answer five rows"
fi
# S5: the settings row.
_rxsp="$RXHOME/.claude/settings.json"
if [ -n "$RXJQ" ]; then
  is "the settings row carries ok as a value (S5)" "$(_rx_field "$(_rx_st "$RXPLAIN" --tsv)" settings)" \
     "$(printf 'settings\tvalue\tok\t%s enables felix@felix' "$_rxsp")"
else
  skip "the settings row carries ok as a value (S5)" "no jq on PATH"
fi
is "with no parser the settings row is unknown, never ok" "$(_rx_field "$(RX_JQ=/nonexistent _rx_st "$RXPLAIN" --tsv)" settings)" \
   "$(printf 'settings\tunknown\t-\tno JSON parser on this machine (jq); %s was not read' "$_rxsp")"
mkdir -p "$RX/nosettings"
is "with no settings file the settings row is the value missing" \
   "$(_rx_field "$(RX_HOMEOVR="$RX/nosettings" _rx_st "$RXPLAIN" --tsv)" settings)" \
   "$(printf 'settings\tvalue\tmissing\t%s does not exist' "$RX/nosettings/.claude/settings.json")"
# S6: the schedule row.
_rx_sch() { _rx_field "$(_rx_st "$RXPLAIN" --tsv)" schedule | cut -f2-; }
_rx_tab() { printf 'PID\tStatus\tLabel\n%s\n' "$1" > "$RX/launch-case"; }
is "a loaded agent whose last run exited 0 reads loaded (S6)" "$(_rx_sch)" "$(printf 'value\tloaded\tlast exit 0')"
_rx_tab "$(printf -- '-\t126\tfelix.pulse')"
is "a last exit of 126 reads exit-126" "$(RX_LAUNCH="$RX/launch-case" _rx_sch)" "$(printf 'value\texit-126\tloaded; the last run exited 126')"
_rx_tab "$(printf -- '-\t-9\tfelix.pulse')"
is "a negative status reads signal-9" "$(RX_LAUNCH="$RX/launch-case" _rx_sch)" "$(printf 'value\tsignal-9\tloaded; the last run was stopped by signal 9')"
_rx_tab "$(printf '412\t0\tfelix.pulse')"
is "a pid in the first field adds that it is running now" "$(RX_LAUNCH="$RX/launch-case" _rx_sch)" "$(printf 'value\tloaded\tlast exit 0; running now, pid 412')"
_rx_tab "$(printf -- '-\tweird\tfelix.pulse')"
is "a status it does not read is unknown, and quoted" "$(RX_LAUNCH="$RX/launch-case" _rx_sch)" \
   "$(printf 'unknown\t-\tlaunchctl reported a status this check does not read: weird')"
_rx_tab "$(printf -- '-\t0\tcom.example.other')"
is "a table without the label reads not-loaded" "$(RX_LAUNCH="$RX/launch-case" _rx_sch)" \
   "$(printf "value\tnot-loaded\tthe agent's plist exists and launchd has not loaded it")"
_rx_tab "$(printf -- '-\t0\tfelix.pulse.extra')"
is "the label is matched exactly, not as a prefix" "$(RX_LAUNCH="$RX/launch-case" _rx_sch | cut -f2)" "not-loaded"
is "a launchctl that exits 113 is unknown" "$(RX_LAUNCH_RC=113 _rx_sch)" "$(printf 'unknown\t-\tlaunchctl could not answer')"
printf 'Something else\n-\t0\tfelix.pulse\n' > "$RX/launch-case"
is "a table whose first line is not its header is unknown" "$(RX_LAUNCH="$RX/launch-case" _rx_sch)" "$(printf 'unknown\t-\tlaunchctl could not answer')"
mkdir -p "$RX/noplist"
is "no plist reads none, and says how to schedule one" "$(RX_HOMEOVR="$RX/noplist" _rx_sch)" \
   "$(printf 'none\t-\tno felix.pulse agent; felix pulse --install schedules one')"
is "a machine that is not Darwin is unknown whatever else holds" "$(UNAME_STUB_RX=Linux _rx_sch)" "$(printf 'unknown\t-\tno launchd on Linux')"
# S7: the pulse row.
_rx_pr() { _rx_field "$(RX_FH="$1" _rx_st "$RXPLAIN" --tsv)" pulse | cut -f2-; }
_rxdet='days since memory reached its remote; last run'
RXQ1="$RX/q1"; mkdir -p "$RXQ1/projects"
is "a home where the pulse never ran reads none (S7)" "$(_rx_pr "$RXQ1")" "$(printf 'none\t-\tthe pulse has never run here')"
RXQ2="$RX/q2"; mkdir -p "$RXQ2/projects"
( cd "$RXPLAIN" && RX_FH="$RXQ2" _rx_env "$FELIX" pulse ) >/dev/null 2>&1
_rxe="$(head -1 "$RXQ2/state/pulse.status.tsv" 2>/dev/null)"; _rxe="${_rxe#\# ran }"; case "$_rxe" in ''|*[!0-9]*) _rxe=0 ;; esac
is "after one pulse with no memory repository the row is never, with the run's UTC minute" "$(_rx_pr "$RXQ2")" \
   "$(printf 'value\tnever\t%s %s' "$_rxdet" "$(_rx_utc "$_rxe")")"
has "and the detail reads last run 20" "$(_rx_pr "$RXQ2")" "last run 20"
RXQ3="$RX/q3"; mkdir -p "$RXQ3/projects" "$RXQ3/state"; printf 'pulse\tx\n' > "$RXQ3/state/pulse.log"
is "a log with no record says the last run is not recorded" "$(_rx_pr "$RXQ3")" "$(printf 'value\tnever\t%s not recorded' "$_rxdet")"
printf '# ran soon\n' > "$RXQ3/state/pulse.status.tsv"
is "and so does a record whose first line is not # ran <digits>" "$(_rx_pr "$RXQ3" | cut -f3)" "$_rxdet not recorded"
printf '# ran 86400\n' > "$RXQ3/state/pulse.status.tsv"; printf '%s\n' "$(( $(_rx_now) - 2 * 86400 - 60 ))" > "$RXQ3/state/pulse.last-push"
is "a verified push two days ago reads 2, and the record's epoch is shown as a UTC minute" "$(_rx_pr "$RXQ3")" \
   "$(printf 'value\t2\t%s 1970-01-02T00:00Z' "$_rxdet")"
is "a home that is not a directory reads unknown" "$(_rx_pr "$RX/no-such-home")" "$(printf 'unknown\t-\tno Felix home resolved')"
# S8: the reach row.
_rx_rr() { _rx_field "$(_rx_st "$1" --tsv)" reach | cut -f2-; }
_rxud='unreachable: plugin:gh:gh failed, plugin:cf:cf-api needs-auth, plugin:dd:mcp failed, lost@m not-listed; 1 unknown; read'
_rx_put reachy "$(( $(_rx_now) - 3630 ))" "$RXC" "$RXR4"
is "with the R4 rows cached an hour ago the reach row is 2/7, naming what is unreachable (S8)" "$(_rx_rr "$RXC")" \
   "$(printf 'value\t2/7\t%s 1h ago' "$_rxud")"
_rx_age reachy "$(( $(_rx_now) - 47 * 3600 - 60 ))"
is "an age under 48 hours is counted in hours" "$(_rx_rr "$RXC" | cut -f3)" "$_rxud 47h ago"
_rx_age reachy "$(( $(_rx_now) - 48 * 3600 - 60 ))"
is "and from 48 hours in days" "$(_rx_rr "$RXC" | cut -f3)" "$_rxud 2d ago"
printf 'connected\tplugin\tctx@m\tplugin:ctx:ctx\tConnected\n' > "$RX/rows-one"
_rx_put reachy "$(_rx_now)" "$RXC" "$RX/rows-one"
is "nothing unreachable says none unreachable, and no unknown clause at zero" "$(_rx_rr "$RXC")" \
   "$(printf 'value\t1/1\tnone unreachable; read 0h ago')"
printf 'garbage\n' > "$(_rx_cache reachy)"
is "a cache with no valid header is unknown, never zero" "$(_rx_rr "$RXC")" \
   "$(printf 'unknown\t-\tno reach cache for reachy; felix stack --reach reads one')"
rm -f "$(_rx_cache reachy)"
is "and so is no cache at all" "$(_rx_rr "$RXC" | cut -f1)" "unknown"
is "a project with no plugin or mcp rows reads none" "$(_rx_rr "$RXN")" "$(printf 'none\t-\tbare declares no plugin or mcp rows')"
is "a directory that is not a governed checkout reads none" "$(_rx_rr "$RXPLAIN")" "$(printf 'none\t-\tthis directory is not a governed checkout')"
# S9: the gate row.
_rx_gr() { _rx_field "$(_rx_st "$1" --tsv)" gate | cut -f2-; }
_rx_rec() { ( cd "$RXC" && . "$FROOT/harness/lib/verify.sh"
              felix_verify_record "$RXC" "$RXH" "$1" "gate.sh" "$(felix_tree_id "$RXC" "$RXH")" ) >/dev/null 2>&1; }
is "outside a governed checkout the gate row is none (S9)" "$(_rx_gr "$RXPLAIN")" "$(printf 'none\t-\tthis directory is not a governed checkout')"
is "with no receipt it is none-run" "$(_rx_gr "$RXC")" "$(printf 'value\tnone-run\tno gate has run in this checkout')"
_rx_rec 1
is "a red receipt for this tree reads red" "$(_rx_gr "$RXC")" "$(printf 'value\tred\tthe last gate run here was red')"
_rx_rec 0
is "a green receipt for this tree reads current" "$(_rx_gr "$RXC")" "$(printf 'value\tcurrent\t-')"
printf 'edited\n' > "$RXC/f.txt"
is "and an edit to a tracked file after it reads stale, with the reason" "$(_rx_gr "$RXC")" "$(printf 'value\tstale\tthe tree changed since the receipt')"
( cd "$RXC" && git checkout -q -- f.txt )
# S11: discoverable.
_rxhp="$(_rx_env "$FELIX" help 2>&1)"
_rx_has "felix help names felix status (S11)" "$_rxhp" \
    "felix status [--tsv]     read-only: settings, the pulse schedule and last run, declared tools' reach, this checkout's gate"
_rx_has "and its stack line names --reach" "$_rxhp" \
    "felix stack [plan|apply|reconcile|--reach [--tsv]] install what this project declares; reconcile reads the record; --reach asks whether declared servers connect"
_rxfs="$(cat "$FROOT/harness/felix")"
case "$_rxfs" in *'status) shift; cmd_status "$@" ;;'*|*'status)  shift; cmd_status "$@" ;;'*) ok "the dispatcher sends status to cmd_status" ;;
  *) bad "the dispatcher sends status to cmd_status" ;; esac
_rxfh="$(awk 'NR > 1 && !/^#/ { exit } { print }' "$FROOT/harness/felix")"
_rx_has "and the felix header comment names felix status" "$_rxfh" "felix status"
_rx_has "and felix stack --reach" "$_rxfh" "--reach"
for _l in reach status pulse; do
  _rxlc="$(awk 'END { print NR }' "$FROOT/harness/lib/$_l.sh" 2>/dev/null)"
  [ -n "$_rxlc" ] && [ "$_rxlc" -gt 0 ] && [ "$_rxlc" -lt 500 ] && ok "lib/$_l.sh is under 500 lines" \
    || bad "lib/$_l.sh is under 500 lines" "${_rxlc:-absent}"
done
