# Land on green: the commands that install, remove and report the scheduled job
# (docs/2026-10-15-land-on-green-contract.md G9, A1). The tick is lib/green-tick.sh;
# this file holds the trampoline launchd runs, the plist that names it, and the
# read-only status. Sourced by felix beside green-tick.sh, outside the
# lib/land*.sh trust-base glob like it, and for the same reason: it holds no
# rule, only the order in which the existing ones are asked.

_gt_xml() { printf '%s' "$1" | LC_ALL=C sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }
_gt_sq() { printf "'%s'" "$(printf '%s' "$1" | LC_ALL=C sed "s/'/'\\\\''/g")"; }

# The trampoline's static body. It is /bin/sh and names no version and no working
# tree. Run by launchd every five minutes, it reads the version origin/main
# declares (no fetch), and runs that cache entry's `felix land --tick` only when
# main's OWN felix_accepted_deploy_diff, read out of origin/main with git show
# and sourced by bash in a subshell as felix merge's judge block does, says the
# entry is main's engine (A1). A cache entry at main's version number that a
# branch installed is not main's engine, and this check is what tells the two
# apart. In every other case it runs nothing: it writes one deploy-owed row
# naming the case (not again while the ledger's last row says the same), sends
# one notification and exits 1. It never runs the newest entry, another version
# or any working tree.
_gt_trampoline_body() {
  cat <<'TRAMPOLINE'
cd "$FELIX_HOME_DIR" || exit 1
cache="${FELIX_PLUGIN_CACHE:-$HOME/.claude/plugins/cache}/felix/felix"
owed() {   # DETAIL: say why nothing runs, once, and stop
  t="$(printf 'deploy-owed\t%s' "$1")"
  [ "$(tail -n 1 "$ledger" 2>/dev/null | LC_ALL=C cut -f2,7)" = "$t" ] || {
    mkdir -p "$(dirname "$ledger")"
    printf '%s\tdeploy-owed\t-\t-\t-\t0\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" >> "$ledger"
    osascript -e "display notification \"Felix land: $1\" with title \"Felix: deploy-owed\"" >/dev/null 2>&1
  }
  echo "felix land: $1" >&2; exit 1
}
pj="$(git show origin/main:engine/.claude-plugin/plugin.json 2>/dev/null)" \
  || owed "git could not read origin/main's engine version, so no engine is run"
ver="$(printf '%s\n' "$pj" | LC_ALL=C sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | LC_ALL=C sed -n 1p)"
[ -n "$ver" ] || owed "origin/main declares no readable engine version, so no engine is run"
entry="$cache/$ver"
[ -e "$entry/harness/felix" ] || owed "main's engine $ver is not installed under $cache: nothing runs until it is deployed from the home"
[ -x "$entry/harness/felix" ] || owed "main's engine $ver is not executable under $cache: nothing runs until it is deployed from the home"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/felix-land.XXXXXX" 2>/dev/null)" \
  || owed "main's accepted-engine check cannot be loaded: no temporary directory to read it into"
git show origin/main:engine/harness/lib/resolve.sh > "$tmp/resolve.sh" 2>/dev/null \
  || { rm -rf "$tmp"; owed "main's accepted-engine check cannot be loaded: origin/main holds no lib/resolve.sh"; }
out="$(env -u FELIX_KERNEL_CACHE /bin/bash -c '. "$1" >/dev/null 2>&1
  command -v felix_accepted_deploy_diff >/dev/null 2>&1 || exit 3
  felix_accepted_deploy_diff "$2" origin/main 2>/dev/null' felix-land "$tmp/resolve.sh" "$FELIX_HOME_DIR")"
rc=$?
rm -rf "$tmp"
case "$rc" in
  0) ;;
  1) owed "the cache entry for main's $ver differs from origin/main's engine, so it is not main's engine: nothing runs until main is deployed from the home" ;;
  3) owed "main's accepted-engine check cannot be loaded: origin/main's lib/resolve.sh defines no felix_accepted_deploy_diff" ;;
  *) owed "main's accepted-engine check could not examine the entry for $ver (status $rc): nothing runs" ;;
esac
exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE "$entry/harness/felix" land --tick
TRAMPOLINE
}

_gt_install() {
  local p tr plist uid="$(id -u)"
  p="$(basename "$PROJ")"
  tr="$HOME/Library/Application Support/felix/land/$p/tick"
  plist="$HOME/Library/LaunchAgents/felix.land.$p.plist"
  mkdir -p "$(dirname "$tr")" "$HOME/Library/LaunchAgents" "$_GT_LAND" || die "could not make the job's directories"
  # FELIX_HOME is what the installed engine reads to find its home; the plist
  # names FELIX_HOME_DIR, which is the contract's word.
  {
    printf '#!/bin/sh\n# Written by felix land --install; felix land --uninstall removes it.\n'
    printf ': "${FELIX_HOME_DIR:=%s}"\nexport FELIX_HOME_DIR\nFELIX_HOME="$FELIX_HOME_DIR"; export FELIX_HOME\n' "$(_gt_sq "$FELIX_HOME_DIR")"
    printf 'ledger=%s\n' "$(_gt_sq "$_GT_LEDGER")"
    _gt_trampoline_body
  } > "$tr" && chmod +x "$tr" || die "could not write $tr"
  {
    printf '<?xml version="1.0" encoding="UTF-8"?>\n'
    printf '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n'
    printf '<plist version="1.0">\n<dict>\n'
    printf '  <key>Label</key><string>felix.land.%s</string>\n' "$(_gt_xml "$p")"
    printf '  <key>ProgramArguments</key><array><string>%s</string></array>\n' "$(_gt_xml "$tr")"
    printf '  <key>StartInterval</key><integer>300</integer>\n  <key>RunAtLoad</key><true/>\n'
    printf '  <key>ProcessType</key><string>Interactive</string>\n'
    printf '  <key>EnvironmentVariables</key><dict>\n'
    printf '    <key>PATH</key><string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>\n'
    printf '    <key>FELIX_HOME_DIR</key><string>%s</string>\n  </dict>\n' "$(_gt_xml "$FELIX_HOME_DIR")"
    printf '  <key>StandardOutPath</key><string>%s</string>\n' "$(_gt_xml "$_GT_LAND/launchd.log")"
    printf '  <key>StandardErrorPath</key><string>%s</string>\n' "$(_gt_xml "$_GT_LAND/launchd.log")"
    printf '</dict>\n</plist>\n'
  } > "$plist" || die "could not write $plist"
  # A job already loaded is booted out first, or bootstrap refuses it.
  launchctl print "gui/$uid/felix.land.$p" >/dev/null 2>&1 && launchctl bootout "gui/$uid/felix.land.$p" >/dev/null 2>&1
  launchctl bootstrap "gui/$uid" "$plist" || die "launchctl bootstrap gui/$uid $plist failed; the files are written, the job is not loaded"
  printf 'land on green is installed for %s: %s\n' "$p" "$plist"
}

_gt_uninstall() {
  local p; p="$(basename "$PROJ")"
  launchctl bootout "gui/$(id -u)/felix.land.$p" >/dev/null 2>&1 || true
  rm -f "$HOME/Library/LaunchAgents/felix.land.$p.plist" "$HOME/Library/Application Support/felix/land/$p/tick"
  rmdir "$HOME/Library/Application Support/felix/land/$p" 2>/dev/null || true
  printf 'land on green is uninstalled for %s\n' "$p"
}

_gt_status() {   # [--tsv]: read-only, writes nothing and loads nothing
  local p tab; p="$(basename "$PROJ")"; tab="$(printf '\t')"
  local ins=no lod=no pau=no rows=""
  [ -f "$HOME/Library/LaunchAgents/felix.land.$p.plist" ] && ins=yes
  launchctl print "gui/$(id -u)/felix.land.$p" >/dev/null 2>&1 && lod=yes
  [ -e "$_GT_LAND/paused" ] && pau=yes
  # The last row of each pull request seen, in pull request order.
  [ -f "$_GT_LEDGER" ] && rows="$(LC_ALL=C awk -F'\t' '$3 != "-" { last[$3] = $0 } END { for (k in last) print last[k] }' "$_GT_LEDGER" \
                                   | LC_ALL=C sort -t "$tab" -k3,3n)"
  if [ "${1:-}" = "--tsv" ]; then
    printf 'installed\t%s\nloaded\t%s\npaused\t%s\n' "$ins" "$lod" "$pau"
    [ -z "$rows" ] || printf '%s\n' "$rows"
  else
    printf 'installed  %s\nloaded     %s\npaused     %s\n' "$ins" "$lod" "$pau"
    [ -z "$rows" ] || printf '%s\n' "$rows" | LC_ALL=C awk -F'\t' '{ printf "#%-5s %-19s %-8s %s  %s\n", $3, $2, substr($4, 1, 7), $1, $7 }'
  fi
}

