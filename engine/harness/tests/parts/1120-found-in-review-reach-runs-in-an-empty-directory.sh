printf '\nfound in review: reach reads the list from an empty directory, and the CLI has one home\n'
# Written by the implementer after the adversarial review of this branch, not
# blind. Two blockers, and the first was shown failing before it was fixed.
#
# The first. `claude mcp list` ran in the checkout: the session's own for the
# SessionStart refresh, the person's cwd for felix stack --reach. Claude Code
# starts a project-scoped server of the directory it is run in once that server
# is approved, or auto-enabled (enableAllProjectMcpServers), so in a checkout
# whose .mcp.json declares a stdio server the refresh could start the
# repository's own command at session start, before the person had looked at
# it; and the founder opens hostile repositories for bounty work. Measured
# 2026-10-12 with the real claude: in a checkout with a project .mcp.json the
# server is listed as "Pending approval" and not started; from an empty
# directory it is not listed at all, whatever CLAUDE_PROJECT_DIR says. So the
# list is read from a fresh empty directory under TMPDIR, removed after, and an
# mcp row that list does not name is unknown (a project-scoped server is not
# started by Felix), never not-listed. The stub below models the case after
# approval: it starts the .mcp.json command of the directory it is run in, and
# its control comes first, so "no marker" cannot pass on a stub that never
# starts anything.
#
# The second. The reviewer ran felix stack --reach with FELIX_HOME_DIR set to a
# scratch directory and the real home's cache was written. FELIX_HOME_DIR is
# not the CLI's override: felix and the hooks assign it from felix_home, which
# reads FELIX_HOME and then the ~/.felix-home pointer. Part 1100's _rx_env sets
# both to one value, so nothing here could have told them apart; these do.
#
# Uses the fixtures part 1100 leaves behind: RXH (the project reachy and its
# stack), RXPC, RXMEM, RXLA (LIST-A), RXR4 (its rows) and the helpers.
RZ="$(mktemp -d "$TMP/rz.XXXXXX")"; RZ="$(cd "$RZ" && pwd -P)"
RZB="$RZ/bin"; RZT="$RZ/tmp"; RZU="$RZ/user"; RZC="$RZ/hostile-checkout"
mkdir -p "$RZB" "$RZT" "$RZU"
RZT="$(cd "$RZT" && pwd -P)"
cat > "$RZB/claude" <<'RZCLAUDESTUB'
#!/bin/bash
printf '%s\n' "$*" >> "${RZ_ARGLOG:-/dev/null}"
case "$*" in
  "mcp list")
    pwd -P >> "${RZ_PWDLOG:-/dev/null}"
    if [ -f .mcp.json ]; then
      c="$(sed -n 's/.*"command": *"\([^"]*\)".*/\1/p' .mcp.json | head -1)"
      if [ -n "$c" ]; then "$c" >/dev/null 2>&1; fi
    fi
    if [ -n "${RZ_DROP:-}" ]; then printf 'x\n' > ./dropped-by-claude; pwd -P >> "${RZ_DROPLOG:-/dev/null}"; fi
    if [ -n "${RX_LIST:-}" ]; then cat "$RX_LIST"; fi
    exit "${RX_RC:-0}" ;;
  *) printf 'stub: untaught shape: %s\n' "$*" >&2; exit 2 ;;
esac
RZCLAUDESTUB
chmod +x "$RZB/claude"
for _w in co home; do
  printf '#!/bin/bash\nprintf started > "%s/marker-%s"\n' "$RZ" "$_w" > "$RZ/writer-$_w.sh"
  chmod +x "$RZ/writer-$_w.sh"
done
# A project-scoped server in the checkout, and another in HOME, which is itself a
# repository on the machine this was found on.
_rx_checkout "$RZC" reachy; RZC="$(cd "$RZC" && pwd -P)"
printf '{"mcpServers": {"evil": {"command": "%s/writer-co.sh", "args": []}}}\n' "$RZ" > "$RZC/.mcp.json"
printf '{"mcpServers": {"evil": {"command": "%s/writer-home.sh", "args": []}}}\n' "$RZ" > "$RZU/.mcp.json"

_rz_env() {   # the stub first on PATH, a TMPDIR of its own, the pwd of every list read logged
  RX_PATH="$RZB:$PATH" RX_HOMEOVR="$RZU" _rx_env TMPDIR="${RZ_TMPDIR:-$RZT}" \
    RZ_PWDLOG="$RZ/pwd.log" RZ_ARGLOG="$RZ/args.log" RZ_DROPLOG="$RZ/drop.log" RZ_DROP="${RZ_DROP:-}" "$@"
}
_rz_stk() { ( cd "$1" && shift && _rz_env "$FELIX" stack "$@" 2>"$RZ/err" ); }
_rz_lib() {   # <lib> <code>: one lib under /bin/bash, the stub and the fixture TMPDIR in place
  _rz_env /bin/bash -c '. "$1/lib/resolve.sh" && . "$1/lib/$2.sh" || exit 97; eval "$3"' rzl "$FROOT/harness" "$1" "$2" 2>/dev/null
}
_rz_reset() { : > "$RZ/pwd.log"; : > "$RZ/args.log"; : > "$RZ/drop.log"; rm -f "$RZ/marker-co" "$RZ/marker-home"; }
_rz_n() { wc -l < "$1" 2>/dev/null | tr -d ' '; }
_rz_left() { ls -A "$RZT" 2>/dev/null | wc -l | tr -d ' '; }
_rz_marks() { local m=""; [ -e "$RZ/marker-co" ] && m="$m checkout"; [ -e "$RZ/marker-home" ] && m="$m home"; printf '%s' "$m"; }
_rz_where() {   # <test name> <logged pwd>: under TMPDIR, fresh, and neither the checkout nor HOME
  case "$2" in
    "$RZT"/felix-reach.??????) ok "$1: a fresh felix-reach directory under TMPDIR" ;;
    *) bad "$1: a fresh felix-reach directory under TMPDIR" "ran in [$2]" ;;
  esac
  case "$2" in
    "$RZC"|"$RZC"/*|"$RZU"|"$RZU"/*|"") bad "$1: not the checkout and not HOME" "ran in [$2]" ;;
    *) ok "$1: not the checkout and not HOME" ;;
  esac
}

printf '\nthe control: the stub starts what a project-scoped .mcp.json declares\n'
_rz_reset
( cd "$RZC" && _rz_env "$RZB/claude" mcp list ) >/dev/null 2>&1
is "run in the checkout, the stub starts the checkout's project server" "$(_rz_marks)" " checkout"
_rz_reset
( cd "$RZU" && _rz_env "$RZB/claude" mcp list ) >/dev/null 2>&1
is "run in HOME, it starts HOME's" "$(_rz_marks)" " home"
_rz_reset

printf '\nreach: felix stack --reach reads from an empty directory\n'
_rzo="$(_rz_stk "$RZC" --reach --tsv)"; _rzrc=$?
is  "felix stack --reach --tsv from the hostile checkout still answers R4's rows" "$_rzo" "$(cat "$RXR4")"
is  "and exits 0" "$_rzrc" "0"
is  "and runs claude mcp list once" "$(_rz_n "$RZ/pwd.log")" "1"
_rzp="$(head -1 "$RZ/pwd.log" 2>/dev/null)"
_rz_where "felix stack --reach" "$_rzp"
is  "and it started no project-scoped server, in the checkout or in HOME" "$(_rz_marks)" ""
is  "and the directory it ran in is gone afterwards, so nothing is left in TMPDIR" "$(_rz_left)" "0"
case "$(head -1 "$(_rx_cache reachy)" 2>/dev/null)" in
  "# read "[0-9]*" $_rzp") ok "and the cache header names the directory the read ran in, not the checkout" ;;
  *) bad "and the cache header names the directory the read ran in, not the checkout" "$(head -1 "$(_rx_cache reachy)" 2>/dev/null) against [$_rzp]" ;;
esac

_rz_reset
_rzo="$(RZ_DROP=1 _rz_stk "$RZC" --reach --tsv)"
is  "a list read that leaves a file behind: the stub did drop one, in the directory it ran in" \
    "$(head -1 "$RZ/drop.log" 2>/dev/null)" "$(head -1 "$RZ/pwd.log" 2>/dev/null)"
_rz_where "a list read that leaves a file behind" "$(head -1 "$RZ/drop.log" 2>/dev/null)"
is  "and the directory, file and all, is removed afterwards" "$(_rz_left)" "0"
is  "and the rows are the same" "$_rzo" "$(cat "$RXR4")"
_rz_reset
_rzo="$(RX_RC=1 _rz_stk "$RZC" --reach --tsv)"
is  "a list that fails (exit 1) ran claude once" "$(_rz_n "$RZ/pwd.log")" "1"
_rz_where "a list that fails" "$(head -1 "$RZ/pwd.log" 2>/dev/null)"
is  "and its directory is removed all the same" "$(_rz_left)" "0"

printf '\nreach: felix_reach_read called from anywhere\n'
_rz_reset
is  "called with HOME as the cwd it reads the list" \
    "$(_rz_lib reach "cd '$RZU'; felix_reach_read >/dev/null; printf '%s' \"\$?\"")" "0"
_rz_where "called from HOME" "$(head -1 "$RZ/pwd.log" 2>/dev/null)"
is  "and started no server when called from HOME" "$(_rz_marks)" ""
_rz_reset
_rz_lib reach "cd '$RZC'; felix_reach_read" >/dev/null
_rz_where "called from the checkout" "$(head -1 "$RZ/pwd.log" 2>/dev/null)"
is  "and started no server when called from the checkout" "$(_rz_marks)" ""
_rz_reset
is  "a TMPDIR that cannot make a directory leaves the list unread, and says so" \
    "$(RZ_TMPDIR="$RZ/no-such-tmp" _rz_lib reach 'felix_reach_read >/dev/null; printf "%s|%s" "$?" "$_FELIX_REACH_WHY"')" \
    "1|could not make an empty directory to run claude mcp list in"
is  "and claude was not run, in the checkout or anywhere" "$(_rz_n "$RZ/args.log")" "0"
cp "$(_rx_cache reachy)" "$RZ/cache.keep" 2>/dev/null
_rzo="$(RZ_TMPDIR="$RZ/no-such-tmp" _rz_stk "$RZC" --reach --tsv)"; _rzrc=$?
is  "felix stack --reach with no directory to read from gives one unknown row per plugin row" "$_rzo" \
    "$(for _p in ctx gh cf dd quiet gone lost; do printf 'unknown\tplugin\t%s@m\t-\tcould not make an empty directory to run claude mcp list in\n' "$_p"; done)"
is  "and exits 0" "$_rzrc" "0"
is  "and ran no claude command" "$(_rz_n "$RZ/args.log")" "0"
cmp -s "$RZ/cache.keep" "$(_rx_cache reachy)" && ok "and left the cache as it was" || bad "and left the cache as it was"
# Measured 2026-10-12 with the real claude: run in a subdirectory of a checkout it lists the server of the parent's .mcp.json, so an empty directory under a project is not neutral. A TMPDIR below a .mcp.json (a repository's own tmp, or a planted /tmp/.mcp.json) must leave the list unread.
RZUP="$RZ/under-mcp"; mkdir -p "$RZUP"; printf '{"mcpServers": {}}\n' > "$RZUP/.mcp.json"
_rz_reset
is  "a .mcp.json above the scratch directory leaves the list unread, and says why" \
    "$(RZ_TMPDIR="$RZUP" _rz_lib reach 'felix_reach_read >/dev/null; printf "%s|%s" "$?" "$_FELIX_REACH_WHY"')" \
    "1|a .mcp.json sits above the scratch directory, so claude mcp list could start a project-scoped server there"
is  "and claude was not run" "$(_rz_n "$RZ/args.log")" "0"
is  "and the scratch directory it made is gone, the .mcp.json left alone" "$(ls -A "$RZUP" | tr '\n' ' ')" ".mcp.json "
_rzo="$(RZ_TMPDIR="$RZUP" _rz_stk "$RZC" --reach --tsv)"
is  "felix stack --reach under such a TMPDIR gives unknown rows that carry the reason" \
    "$(printf '%s\n' "$_rzo" | awk -F'\t' '{ print $1 "|" $5 }' | sort -u)" \
    "unknown|a .mcp.json sits above the scratch directory, so claude mcp list could start a project-scoped server there"
is  "and ran no claude command" "$(_rz_n "$RZ/args.log")" "0"
rm -f "$RZUP/.mcp.json"
is  "the same TMPDIR without the .mcp.json reads the list (the control)" \
    "$(RZ_TMPDIR="$RZUP" _rz_lib reach 'felix_reach_read >/dev/null; printf "%s" "$?"')" "0"
_rz_reset
_rz_src="$(awk '/^[[:space:]]*#/ { next } /claude mcp list 2>/ { print }' "$FROOT/harness/lib/reach.sh" 2>/dev/null)"
is  "reach.sh runs claude mcp list in exactly one place" "$(printf '%s\n' "$_rz_src" | grep -c 'claude mcp list 2>')" "1"
_rx_has "and that place changes into the scratch directory first" "$_rz_src" 'cd "'

printf '\nreach: the SessionStart refresh reads from an empty directory\n'
_rz_hook() { ( cd "$RZC" && _rz_env CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" ) >/dev/null 2>&1; }
_rz_lock="$RXH/state/reach/reachy.lock"
_rx_wait 10 '[ ! -d "$_rz_lock" ]'
rm -f "$(_rx_cache reachy)"; _rz_reset
_rz_hook
_rx_wait 10 '[ -s "$(_rx_cache reachy)" ] && [ ! -d "$_rz_lock" ]' && _rzk=1 || _rzk=0
[ "$_rzk" = 1 ] && ok "with the cache absent a session start in the hostile checkout writes one" \
                || bad "with the cache absent a session start in the hostile checkout writes one" "no cache, or the lock is still held"
_rzp="$(head -1 "$RZ/pwd.log" 2>/dev/null)"
_rz_where "the refresh" "$_rzp"
is  "and it started no project-scoped server, in the checkout or in HOME" "$(_rz_marks)" ""
is  "and nothing is left in TMPDIR" "$(_rz_left)" "0"
case "$(head -1 "$(_rx_cache reachy)" 2>/dev/null)" in
  "# read "[0-9]*" $_rzp") ok "and the cache header names that directory" ;;
  *) bad "and the cache header names that directory" "$(head -1 "$(_rx_cache reachy)" 2>/dev/null)" ;;
esac
rm -f "$(_rx_cache reachy)"; _rz_reset
RZ_TMPDIR="$RZ/no-such-tmp" _rz_hook
_rx_wait 10 '[ ! -d "$_rz_lock" ]'
is  "a refresh that cannot make its directory runs no claude command" "$(_rz_n "$RZ/args.log")" "0"
if [ -e "$(_rx_cache reachy)" ]; then bad "and writes no cache"; else ok "and writes no cache"; fi
is  "and the lock is not left behind" "$([ -d "$_rz_lock" ] && echo held || echo free)" "free"

printf '\nreach: an mcp row the neutral list does not name is unknown\n'
_rzr="$(_rx_rows mcpy)"
_rz_nh() { printf '%s\n' "$_rzr" | awk -F'\t' '$2 == "mcp" && $3 == "nothere"' | cut -f"$1"; }
is  "an mcp row no line of the list names reads unknown" "$(_rz_nh 1)" "unknown"
is  "with no server" "$(_rz_nh 4)" "-"
is  "and a detail that says a project-scoped server is not started by Felix" \
    "$(_rz_nh 5)" "no line of claude mcp list names this server; a project-scoped server is not started by Felix, so whether it connects is not known"
is  "no mcp row ever reads not-listed" "$(printf '%s\n' "$_rzr" | awk -F'\t' '$2 == "mcp" && $1 == "not-listed"' | wc -l | tr -d ' ')" "0"
is  "and none reads failed unless a line says Failed to connect" "$(printf '%s\n' "$_rzr" | awk -F'\t' '$2 == "mcp" && $1 == "failed"' | wc -l | tr -d ' ')" "0"
is  "an mcp row the list does name still reads by its line (sentry connected)" \
    "$(printf '%s\n' "$_rzr" | awk -F'\t' '$2 == "mcp" && $3 == "sentry" { print $1 }')" "connected"
is  "and one a plugin's server answers to still reads by its line (cf-api needs-auth)" \
    "$(printf '%s\n' "$_rzr" | awk -F'\t' '$2 == "mcp" && $3 == "cf-api" { print $1 }')" "needs-auth"
case "$_rzr" in *"?"*) bad "and no row carries a query string" "$_rzr" ;; *) ok "and no row carries a query string" ;; esac
printf '%s\n' "$_rzr" > "$RZ/rows-mcpy"
_rx_put mcpy "$(_rx_now)" "$RZ/x" "$RZ/rows-mcpy"
_rzpl="$(_rxl reach "felix_reach_report '$RXH/projects/mcpy' '$RXH'")"
is  "the pulse names it in a reach-unknown line" \
    "$(printf '%s\n' "$_rzpl" | awk -F'\t' '$1 == "reach-unknown"')" \
    "$(printf 'reach-unknown\tmcpy\t1 declared row(s) whose reach is not known: nothere')"
is  "and not in an unreachable line" "$(printf '%s\n' "$_rzpl" | awk -F'\t' '$1 == "unreachable" && index($3, "nothere")' | wc -l | tr -d ' ')" "0"
rm -f "$(_rx_cache mcpy)"

printf '\nthe CLI has one home: FELIX_HOME, then the pointer, and FELIX_HOME_DIR is assigned from them\n'
RZREAL="$RZ/realhome"; RZSCR="$RZ/scratchhome"; RZP="$RZ/pointer-user"
for _h in "$RZREAL" "$RZSCR"; do
  mkdir -p "$_h/projects/reachy" "$_h/state"
  for _f in project.json CLAUDE.md stack.tsv; do cp "$RXH/projects/reachy/$_f" "$_h/projects/reachy/$_f"; done
done
mkdir -p "$RZP"; printf '%s\n' "$RZREAL" > "$RZP/.felix-home"
_rz_h() {   # no FELIX_HOME and no FELIX_HOME_DIR but what the test passes; the pointer names the real home
  env -u CLAUDE_CONFIG_DIR -u FELIX_JQ -u FELIX_HOME -u FELIX_HOME_DIR HOME="$RZP" FELIX_MEMORY="$RXMEM" \
      FELIX_PLUGIN_CACHE="$RXPC" PATH="$RZB:$PATH" TMPDIR="$RZT" RZ_PWDLOG="$RZ/pwd.log" RZ_ARGLOG="$RZ/args.log" \
      RX_LIST="$RXLA" RX_RC=0 "$@"
}
_rz_has_state() { local h="$1" r="" f; for f in reach/reachy.tsv pulse.status.tsv pulse.log; do [ -e "$h/state/$f" ] && r="$r ${f##*/}"; done; printf '%s' "$r"; }
_rz_clear() { rm -rf "$RZREAL/state" "$RZSCR/state"; mkdir -p "$RZREAL/state" "$RZSCR/state"; }
_rz_hset() { ( cd "$RZC" && _rz_h "$@" 2>/dev/null ); }

_rz_clear; _rz_reset
_rz_hset "$FELIX" stack --reach --tsv >/dev/null
is  "with no override the pointer's home receives the reach cache (the control)" "$(_rz_has_state "$RZREAL")" " reachy.tsv"
is  "and the scratch home receives nothing" "$(_rz_has_state "$RZSCR")" ""
_rz_clear
_rz_hset FELIX_HOME="$RZSCR" "$FELIX" stack --reach --tsv >/dev/null
is  "FELIX_HOME names the home: the scratch home receives the reach cache" "$(_rz_has_state "$RZSCR")" " reachy.tsv"
is  "and the home the pointer names receives nothing" "$(_rz_has_state "$RZREAL")" ""
case "$(head -1 "$RZSCR/state/reach/reachy.tsv" 2>/dev/null)" in "# read "[0-9]*) ok "and the scratch cache has a valid header" ;; *) bad "and the scratch cache has a valid header" ;; esac
_rz_hset FELIX_HOME="$RZSCR" "$FELIX" pulse >/dev/null
is  "the pulse's record and log land beside it, in the scratch home" "$(_rz_has_state "$RZSCR")" " reachy.tsv pulse.status.tsv pulse.log"
is  "and the home the pointer names still has none of them" "$(_rz_has_state "$RZREAL")" ""
_rz_clear; _rz_reset
( cd "$RZC" && _rz_h FELIX_HOME="$RZSCR" CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" ) >/dev/null 2>&1
_rz_slock="$RZSCR/state/reach/reachy.lock"
_rx_wait 10 '[ -s "$RZSCR/state/reach/reachy.tsv" ] && [ ! -d "$_rz_slock" ]'
is  "the SessionStart refresh writes the scratch home's cache" "$(_rz_has_state "$RZSCR")" " reachy.tsv"
is  "and the home the pointer names receives nothing" "$(_rz_has_state "$RZREAL")" ""
_rz_clear
_rz_hset FELIX_HOME_DIR="$RZSCR" "$FELIX" stack --reach --tsv >/dev/null
is  "FELIX_HOME_DIR alone is not an override: the pointer's home is written (what the review saw)" "$(_rz_has_state "$RZREAL")" " reachy.tsv"
is  "and the directory it named is not" "$(_rz_has_state "$RZSCR")" ""
_rz_clear; _rz_reset
