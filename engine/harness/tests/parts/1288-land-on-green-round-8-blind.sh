# >>> land-on-green-round-8
printf '\nland on green: the amendment A31 (contract A31, blind)\n'
# Blind, from the contract's "Amended after install, 2026-10-18" alone, on the
# fixture parts 1280-1287 build: lib/green-install.sh, lib/green-tick.sh,
# lib/resolve.sh and the felix CLI were not read. The trampoline is run as
# launchd runs it: an empty environment but HOME, FELIX_HOME_DIR and PATH, from
# a directory that is not the home.
#
# macOS's privacy control cannot be summoned from a fixture, so the open A31
# asks for is failed another way, one where [ -r ] still says yes:
#   - a unix socket named plugin.json: [ -r ] passes and open(2) is refused.
#     This is the case that follows the contract to the letter (an open that
#     fails). It needs perl to bind the socket, and skips without it.
#   - a directory named plugin.json: [ -r ] passes, bash can open it for
#     reading, and only a read of it fails. So this case holds only for a
#     trampoline that reads a byte, not one that merely opens.
#   - a file of mode 000, when the suite is not root.
# A git first on the trampoline's PATH logs each call and runs the real one, so
# "before anything else" can be seen: an unopenable file leaves it no call to
# make. It sits ahead of the stubs only for the trampoline, never for felix land.
L8="$LG/round8"; L8CWD="$(pwd -P)"; mkdir -p "$L8/gitbin" "$L8/home2/engine/.claude-plugin"
L8TR="$LGU/Library/Application Support/felix/land/lgh/tick"
L8PL="$LGU/Library/LaunchAgents/felix.land.lgh.plist"
L8PJ="$LGH/engine/.claude-plugin/plugin.json"; L8P2="$L8/home2/engine/.claude-plugin/plugin.json"
L8T="$(printf '\t')"
command -v git > "$L8/realgit"; cp -p "$L8PJ" "$L8/plugin.json.keep"
_lg_put "$L8/gitbin/git" <<'L8STUB'
#!/bin/bash
LG='@LG@'
printf '%s\n' "$*" >> "$LG/log/git.log"
exec "$(cat "$LG/round8/realgit")" "$@"
L8STUB
_l8_ticks() { _lg_logs felix | LC_ALL=C awk -F'\t' '$3 == "land --tick"' | wc -l | tr -d ' '; }
_l8_mainv() { git -C "$LGH" show refs/remotes/origin/main:engine/.claude-plugin/plugin.json 2>/dev/null | sed -n 's/.*"version": *"\([^"]*\)".*/\1/p'; }
_l8_tramp() {   # [HOME-DIR] -> the trampoline as launchd runs it, FELIX_HOME_DIR as given; status in L8RC
  ( cd "$TMP/cwd" 2>/dev/null || cd "$LG" || exit 97
    exec env -i HOME="$LGU" FELIX_HOME_DIR="${1:-$LGH}" PATH="$L8/gitbin:$LGB:$PATH" \
      GIT_CEILING_DIRECTORIES="${GIT_CEILING_DIRECTORIES-}" "$L8TR" ) > "$LG/out.tramp" 2>&1
  L8RC=$?
}
_l8_probe() {   # FILE -> whether [ -r ] passes, and whether opening it for reading is refused
  local a=unreadable b=opens
  [ -r "$1" ] && a=readable
  ( : < "$1" ) 2>/dev/null || b=refused
  printf '%s %s' "$a" "$b"
}
_l8_sock() {   # FILE -> a unix socket at FILE (bound by a relative name, for the length of the path)
  ( cd "$(dirname "$1")" || exit 97
    exec perl -e 'use Socket; socket(S, PF_UNIX, SOCK_STREAM, 0) or exit 1; bind(S, sockaddr_un($ARGV[0])) or exit 2; exit 0' "$(basename "$1")" ) >/dev/null 2>&1
}
_l8_restore() { chmod -R u+rwx "$L8PJ" 2>/dev/null; rm -rf "$L8PJ"; cp -p "$L8/plugin.json.keep" "$L8PJ"; }
_l8_unread() {   # WHAT -> the trampoline twice over an unopenable plugin.json: what A31 says of the failed open
  local w="$1" r1 r2 d; _lg_reset; _l8_tramp; r1=$L8RC; _l8_tramp; r2=$L8RC; d="$(_lg_f unreadable "" 7)"
  is "A31: $w: the trampoline exits 1, on each of two runs" "$r1 $r2" "1 1"
  is "A31: $w: it runs no felix at all, so no felix land --tick" "$(_lg_cnt felix)|$(_l8_ticks)" "0|0"
  is "A31: $w: it runs no git: nothing comes before the open" "$(_lg_cnt git)" "0"
  is "A31: $w: two identical runs write one row of kind unreadable, and no other row" "$(_lg_n unreadable)|$(_lg_rows)" "1|1"
  is "A31: $w: and send one notification" "$(_lg_cnt osa)" "1"
  is "A31: $w: the row is seven tab-separated fields with - for pull request, head and worktree" \
     "$(LC_ALL=C awk -F'\t' '$2 == "unreadable" { printf "%d|%s|%s|%s", NF, $3, $4, $5 }' "$LAND/ledger.tsv" 2>/dev/null)" "7|-|-|-"
  case "$(_lg_f unreadable "" 1)" in ""|-) bad "A31: $w: and it carries a time" "[$(_lg_f unreadable "" 1)]" ;; *) ok "A31: $w: and it carries a time" ;; esac
  has "A31: $w: the detail names FELIX_HOME_DIR" "$d" "$LGH"
  has "A31: $w: and says macOS may be refusing the read" "$d" "macOS"
  has "A31: $w: and that /bin/bash needs Full Disk Access" "$d" "/bin/bash"
  has "A31: $w: naming Full Disk Access" "$d" "Full Disk Access"
  has "A31: $w: and where to give it, as the contract writes it" "$d" "System Settings > Privacy & Security > Full Disk Access"
  _lg_osa 'with title "Felix: unreadable"' "A31: $w: the notification is titled Felix: unreadable"
  has "A31: $w: and carries the detail" "$(_lg_logs osa | cut -f1)" "Full Disk Access"
}
_l8_unread_short() {   # WHAT -> the same, in its four parts that do not depend on how the file was made unopenable
  local w="$1" r1 r2; _lg_reset; _l8_tramp; r1=$L8RC; _l8_tramp; r2=$L8RC
  is "A31: $w: the trampoline exits 1, on each of two runs" "$r1 $r2" "1 1"
  is "A31: $w: it runs no felix at all" "$(_lg_cnt felix)" "0"
  is "A31: $w: two identical runs write one row of kind unreadable, and no other row" "$(_lg_n unreadable)|$(_lg_rows)" "1|1"
  is "A31: $w: and send one notification titled Felix: unreadable" \
     "$(_lg_cnt osa)|$(_lg_logs osa | grep -c 'with title "Felix: unreadable"')" "1|1"
}

# --------------------------------------------------- the fixture, checked ---
_fx_git "$LGH" fetch -q origin >/dev/null 2>&1; _fx_git "$LGH" checkout -q main >/dev/null 2>&1
_fx_git "$LGH" reset -q --hard refs/remotes/origin/main >/dev/null 2>&1
L8V="$(_l8_mainv)"; [ -n "$L8V" ] && _lg_cache "$L8V"
is "A31 (fixture control): the home is on main at origin's main, which declares a version, and plugin.json is a file it can read" \
   "$(git -C "$LGH" rev-parse HEAD 2>&1)|$(git -C "$LGH" rev-parse --abbrev-ref HEAD 2>&1)|$([ -n "$L8V" ] && echo v)|$(_l8_probe "$L8PJ")" \
   "$(git -C "$LGO" rev-parse main 2>&1)|main|v|readable opens"
is "A31 (fixture control): the home holds no change, tracked or untracked, under engine/" \
   "$(git -C "$LGH" status --porcelain -- engine 2>&1 | tr '\n' '|')" ""
_lg_reset; _lg_land --uninstall; _lg_land --install
is "A31 (fixture control): --install exits 0 and leaves the plist and an executable trampoline" \
   "$LGRC|$([ -f "$L8PL" ] && echo plist)|$([ -x "$L8TR" ] && echo tramp)" "0|plist|tramp"

# ----------------------------------------------------------- the program ---
is "A31: the trampoline's first line is #!/bin/bash" "$(head -n 1 "$L8TR" 2>&1)" "#!/bin/bash"
_l8p="$( { tr -d ' \t\r\n' < "$L8PL"; } 2>/dev/null)"
has "A31: the plist's ProgramArguments are /bin/bash, then the trampoline's path, and nothing else" "$_l8p" \
    "<key>ProgramArguments</key><array><string>/bin/bash</string><string>$(printf '%s' "$L8TR" | tr -d ' ')</string></array>"
if plutil -extract Label raw -o - "$L8PL" >/dev/null 2>&1; then
  is "A31: plutil reads ProgramArguments as two strings: /bin/bash, then the trampoline's path with its space" \
     "$(plutil -extract ProgramArguments raw -o - "$L8PL" 2>&1)|$(plutil -extract ProgramArguments.0 raw -o - "$L8PL" 2>&1)|$(plutil -extract ProgramArguments.1 raw -o - "$L8PL" 2>&1)" \
     "2|/bin/bash|$L8TR"
else skip "A31: plutil reads ProgramArguments as two strings: /bin/bash, then the trampoline's path with its space" "no plutil that extracts raw values on this machine"; fi

# ----------------------------------------- the open that succeeds, goes on ---
_lg_reset; _l8_tramp
is "A31: with plugin.json a file it can open, the trampoline goes on as before: it runs main's entry's felix land --tick once and exits 0" \
   "$L8RC|$(_l8_ticks)|$(_lg_logs felix | LC_ALL=C awk -F'\t' '$3 == "land --tick" { print $1 }')" "0|1|$LGV/$L8V/harness/felix"
is "A31: and writes no unreadable row and sends no notification" "$(_lg_n unreadable)|$(_lg_rows)|$(_lg_cnt osa)" "0|0|0"
is "A31 (fixture control): the git wrapper sees the trampoline's own git when the open succeeds, so no git in the cases below means it ran before them" \
   "$([ "$(_lg_cnt git)" -ge 1 ] && echo seen)" "seen"

# --------------------------------------- the open that fails: a socket ---
if command -v perl >/dev/null 2>&1; then
  mv "$L8PJ" "$L8/plugin.json.moved"; _l8_sock "$L8PJ"
  is "A31 (fixture control): plugin.json is a socket: [ -r ] passes and opening it for reading is refused" \
     "$([ -S "$L8PJ" ] && echo socket)|$(_l8_probe "$L8PJ")" "socket|readable refused"
  _l8_unread "with plugin.json a socket ([ -r ] passes, the open is refused)"
  # The open is first: main's entry is gone, which A1 would say as a deploy-owed
  # row, and the unopenable file still leaves the unreadable row alone.
  [ -n "$L8V" ] && rm -rf "$LGV/$L8V"
  _lg_reset; _l8_tramp
  is "A31: the open comes before A1's check: with main's cache entry gone, the unopenable file writes the unreadable row alone and no deploy-owed row" \
     "$L8RC|$(_lg_n unreadable)|$(_lg_n deploy-owed)|$(_lg_rows)|$(_lg_cnt felix)|$(_lg_cnt git)" "1|1|0|1|0|0"
  [ -n "$L8V" ] && _lg_cache "$L8V"
  # A row is written when it differs from the previous one: another home, an
  # unopenable plugin.json there too, is another detail.
  _l8_sock "$L8P2"
  _lg_reset; _l8_tramp; _l8_tramp; _l8_tramp "$L8/home2"
  is "A31 (fixture control): the second home's plugin.json is a socket" "$([ -S "$L8P2" ] && echo socket)" "socket"
  is "A31: the row is written again when it differs from the previous one: a second home gives a second row and a second notification, and exit 1" \
     "$(_lg_n unreadable)|$(_lg_cnt osa)|$L8RC" "2|2|1"
  has "A31: and that row names the second home" "$(_lg_f unreadable "" 7)" "$L8/home2"
  rm -f "$L8P2"; _l8_restore
  is "A31 (fixture control): plugin.json is the home's file again, as it was" \
     "$(cksum < "$L8PJ")|$(_l8_probe "$L8PJ")" "$(cksum < "$L8/plugin.json.keep")|readable opens"
else
  skip "A31: with plugin.json a socket, the trampoline writes one unreadable row, notifies once, exits 1 and runs nothing" "no perl to bind a socket"
fi

# ------------------------------------- the open that fails: a directory ---
mv "$L8PJ" "$L8/plugin.json.moved"; mkdir "$L8PJ"
is "A31 (fixture control): plugin.json is a directory: [ -r ] passes" "$([ -d "$L8PJ" ] && echo dir)|$([ -r "$L8PJ" ] && echo readable)" "dir|readable"
_l8_unread_short "with plugin.json a directory (a trampoline that reads a byte refuses it; one that only opens does not)"
_l8_restore

# ----------------------------------------- the open that fails: mode 000 ---
if [ "$(id -u)" != 0 ]; then
  chmod 000 "$L8PJ"
  is "A31 (fixture control): plugin.json is a file of mode 000 that cannot be opened" "$([ -f "$L8PJ" ] && echo file)|$(_l8_probe "$L8PJ")" "file|unreadable refused"
  _l8_unread_short "with plugin.json a file of mode 000"
  _l8_restore
else skip "A31: with plugin.json a file of mode 000, the trampoline writes one unreadable row, notifies once and exits 1" "the suite runs as root, which opens any file"; fi

# --------------------------------------------------------------- --status ---
_l8_led() {   # -> PR 5's two rows and PR 6's, the job installed, loaded, not paused
  _lg_reset; mkdir -p "$LAND"
  { printf '2026-10-18T08:00:00Z\tskip\t5\t%s\t-\t0\tdraft\n' "$(_lg_sha 21)"
    printf '2026-10-18T08:05:00Z\tsession\t5\t%s\t-\t1\tno checkout holds the gated head\n' "$(_lg_sha 21)"
    printf '2026-10-18T08:06:00Z\tlanded\t6\t%s\t%s\t3\tmerged\n' "$(_lg_sha 22)" "$LGW/b22"; } > "$LAND/ledger.tsv"
  : > "$LGK/loaded"
}
_l8_ln() { sed -n "${1}p" "$LG/out"; }
_l8_led; printf '2026-10-18T08:07:00Z\tunreadable\t-\t-\t-\t0\tquartz detail of the newest row, FELIX_HOME_DIR cannot be read\n' >> "$LAND/ledger.tsv"
_l8s0="$(_lgsnap)"; _lg_land --status --tsv
is "A31: --status --tsv exits 0" "$LGRC" 0
is "A31: --status --tsv keeps installed, loaded and paused as its first three lines" "$(sed -n 1,3p "$LG/out" | tr '\t\n' ':|')" "installed:yes|loaded:yes|paused:no|"
is "A31: --status --tsv prints a fourth line: last, a tab, then the ledger's newest row exactly as the ledger has it, a row whose pull request is - included" \
   "$(_l8_ln 4)" "last${L8T}$(tail -n 1 "$LAND/ledger.tsv")"
is "A31: --status --tsv prints one last line" "$(LC_ALL=C awk -F'\t' '$1 == "last"' "$LG/out" | wc -l | tr -d ' ')" "1"
_l8a="$(sed -n 1,4p "$LG/out")"; _l8b="$(sed -n '5,$p' "$LG/out")"
case "$_l8b" in *"$(sed -n 2p "$LAND/ledger.tsv")"*) ok "A31: the pull requests' rows follow last, as before: PR 5's newest row" ;;
  *) bad "A31: the pull requests' rows follow last, as before: PR 5's newest row" "after line 4: [$_l8b]" ;; esac
case "$_l8b" in *"$(sed -n 3p "$LAND/ledger.tsv")"*) ok "A31: and PR 6's row, both after line 4" ;;
  *) bad "A31: and PR 6's row, both after line 4" "after line 4: [$_l8b]" ;; esac
case "$_l8b" in *"$(sed -n 1p "$LAND/ledger.tsv")"*) bad "A31: and not a pull request's earlier rows" "after line 4: [$_l8b]" ;;
  *) ok "A31: and not a pull request's earlier rows" ;; esac
case "$_l8a" in *"$(sed -n 3p "$LAND/ledger.tsv")"*) bad "A31: no pull request's row comes before last" "in the first four lines: [$_l8a]" ;;
  *) ok "A31: no pull request's row comes before last" ;; esac
is "A31: --status writes nothing: the land directory and LaunchAgents are as they were, and launchctl bootstraps and boots out nothing" \
   "$(_lgsnap)|$(_lg_logs launchctl | grep -cE '^(bootstrap|bootout|load|unload)')" "$_l8s0|0"
mkdir -p "$LAND"; printf 'held for the test\n' > "$LAND/paused"; _lg_land --status --tsv
is "A31: paused yes does not move last: the fourth line is still the newest row" "$(_l8_ln 3)|$(_l8_ln 4)" "paused${L8T}yes|last${L8T}$(tail -n 1 "$LAND/ledger.tsv")"
rm -f "$LAND/paused"

# The newest row belongs to a pull request.
_l8_led; printf '2026-10-18T08:09:00Z\trefused\t7\t%s\t-\t2\tblocker one: the receipt is stale\n' "$(_lg_sha 40)" >> "$LAND/ledger.tsv"
_lg_land --status --tsv
is "A31: with a pull request's row newest, --status --tsv's last line is that row exactly as the ledger has it" \
   "$(_l8_ln 4)" "last${L8T}$(tail -n 1 "$LAND/ledger.tsv")"
case "$(sed -n '5,$p' "$LG/out")" in *"$(tail -n 1 "$LAND/ledger.tsv")"*) ok "A31: and that pull request's row also follows last, as before" ;;
  *) bad "A31: and that pull request's row also follows last, as before" "after line 4: [$(sed -n '5,$p' "$LG/out")]" ;; esac

# A ledger with no row.
_lg_reset; : > "$LGK/loaded"; _lg_land --status --tsv
is "A31: with no ledger, --status --tsv prints four lines, the fourth last, a tab, none" \
   "$(tr '\t\n' ':|' < "$LG/out")" "installed:yes|loaded:yes|paused:no|last:none|"
_lg_reset; mkdir -p "$LAND"; : > "$LAND/ledger.tsv"; : > "$LGK/loaded"; _lg_land --status --tsv
is "A31: with an empty ledger, --status --tsv prints four lines, the fourth last, a tab, none" \
   "$(tr '\t\n' ':|' < "$LG/out")" "installed:yes|loaded:yes|paused:no|last:none|"

# Plain.
_l8_led; printf '2026-10-18T08:07:00Z\tunreadable\t-\t-\t-\t0\tquartz detail of the newest row, FELIX_HOME_DIR cannot be read\n' >> "$LAND/ledger.tsv"
_lg_land --status
_l8o="$(sed -n 1,3p "$LG/out" | LC_ALL=C awk '{ k = $1; gsub(/[^a-z]/, "", k); printf "%s %s|", k, $NF }')"
is "A31: plain --status keeps installed, loaded and paused, each yes or no, as its first three lines" "$_l8o" "installed yes|loaded yes|paused no|"
case "$(_l8_ln 4)" in last*) ok "A31: plain --status's fourth line starts with last" ;; *) bad "A31: plain --status's fourth line starts with last" "[$(_l8_ln 4)]" ;; esac
has "A31: and shows the newest row's time" "$(_l8_ln 4)" "2026-10-18T08:07:00Z"
has "A31: and its kind" "$(_l8_ln 4)" "unreadable"
has "A31: and its detail" "$(_l8_ln 4)" "quartz detail of the newest row, FELIX_HOME_DIR cannot be read"
_l8b="$(sed -n '5,$p' "$LG/out")"
case "$_l8b" in *landed*) ok "A31: the pull requests' rows follow last: PR 6's landed row" ;; *) bad "A31: the pull requests' rows follow last: PR 6's landed row" "after line 4: [$_l8b]" ;; esac
case "$_l8b" in *session*) ok "A31: and PR 5's newest row" ;; *) bad "A31: and PR 5's newest row" "after line 4: [$_l8b]" ;; esac
case "$_l8b" in *skip*) bad "A31: and not PR 5's earlier row" "after line 4: [$_l8b]" ;; *) ok "A31: and not PR 5's earlier row" ;; esac
_lg_reset; : > "$LGK/loaded"; _lg_land --status
case "$(_l8_ln 4)" in last*none*) ok "A31: plain --status with no ledger says last, then none, on its fourth line" ;;
  *) bad "A31: plain --status with no ledger says last, then none, on its fourth line" "[$(_l8_ln 4)]" ;; esac

# An install whose job cannot run shows it at the next status.
if command -v perl >/dev/null 2>&1; then
  mv "$L8PJ" "$L8/plugin.json.moved"; _l8_sock "$L8PJ"; _lg_reset; _l8_tramp; _l8_restore
  : > "$LGK/loaded"; _lg_land --status --tsv
  is "A31: an unreadable home shows at the next status: --status --tsv's last line is the trampoline's own unreadable row" \
     "$(_l8_ln 4 | cut -f1,3)|$(_l8_ln 4)" "last${L8T}unreadable|last${L8T}$(tail -n 1 "$LAND/ledger.tsv")"
  _lg_land --status
  has "A31: and plain --status says unreadable on its last line" "$(_l8_ln 4)" "unreadable"
  has "A31: and names Full Disk Access there" "$(_l8_ln 4)" "Full Disk Access"
else skip "A31: an unreadable home shows at the next status" "no perl to bind a socket"; fi

# ----------------------------------------------------------------- clean ---
_l8_restore; _lg_reset; _lg_land --uninstall; _lg_reset; rm -rf "$L8"
is "A31 (fixture control): the home's plugin.json is the file it was, and the part leaves the working directory where it found it" \
   "$([ -f "$L8PJ" ] && [ ! -S "$L8PJ" ] && echo file)|$(git -C "$LGH" status --porcelain -- engine 2>&1 | tr '\n' '|')|$(pwd -P)" "file||$L8CWD"
