# Land on green: the commands that install, remove and report the scheduled job
# (docs/2026-10-15-land-on-green-contract.md G9, A1). The tick is lib/green-tick.sh;
# this file holds the trampoline launchd runs, the plist that names it, and the
# read-only status. Sourced by felix beside green-tick.sh, outside the
# lib/land*.sh trust-base glob like it, and for the same reason: it holds no
# rule, only the order in which the existing ones are asked.

# A22. A tick that cannot resolve its project has no ledger of its own. The
# trampoline carries the ledger's path and exports it as FELIX_LAND_LEDGER; this is
# the only case that reads it. The row is deduplicated as A10's are, so five
# minutes of the same failure is one row and one notification. Without the
# variable it is rationed to one an hour by a stamp.
_gt_noproj() {
  local s="$HOME/Library/Application Support/felix/land/noproject" m
  m="felix land --tick cannot resolve its project from $PWD: nothing was looked at"
  if [ -n "${FELIX_LAND_LEDGER:-}" ]; then
    _GT_LEDGER="$FELIX_LAND_LEDGER"; _GT_LAND="$(dirname "$_GT_LEDGER")"
    _gt_row_once unresolved - - - 0 "$m"; return 0
  fi
  [ -z "$(find "$s" -mmin -60 2>/dev/null)" ] || return 0
  mkdir -p "${s%/*}" 2>/dev/null; : > "$s" 2>/dev/null
  _gt_say unresolved - "$m"
}

# A24. Before the deploy runs anything from the home, its engine/ and its
# projects/<p>/ are main, byte for byte: every tracked path hashes (git
# hash-object over the working-tree file, never through git status, which an
# assume-unchanged or skip-worktree flag blinds) to the blob refs/remotes/origin/main
# holds, no index entry carries either flag, and no untracked or ignored file
# exists under engine/ (--others with no exclude rules). One batch of hashes
# against one ls-tree keeps it fast. Prints the first path that is not, and why.
_gt_home_exact() {   # -> 0 when the home is main's; else 1, with the path and why on stdout
  local home="$FELIX_HOME_DIR" pj="projects/$(basename "$PROJ")" t n x
  t="$(mktemp -d "${TMPDIR:-/tmp}/felix-land-home.XXXXXX" 2>/dev/null)" || { printf 'no temporary directory to compare the home in'; return 1; }
  git -C "$home" ls-tree -r "$_GT_MAIN" -- engine "$pj" 2>/dev/null \
    | LC_ALL=C awk -F'\t' -v w="$t/want" -v p="$t/paths" '$1 ~ /^[0-7]+ blob / { split($1, a, " "); print a[3] > w; print $2 > p }'
  [ -s "$t/paths" ] || { rm -rf "$t"; printf "git could not list origin/main's engine/ and %s/" "$pj"; return 1; }
  git -C "$home" hash-object --stdin-paths < "$t/paths" > "$t/got" 2>/dev/null
  if ! cmp -s "$t/want" "$t/got"; then
    n="$(LC_ALL=C awk 'NR == FNR { w[FNR] = $0; next } { g = FNR; if ($0 != w[FNR] && !f) f = FNR } END { print f ? f : g + 1 }' "$t/want" "$t/got")"
    x="$(sed -n "${n}p" "$t/paths")"; rm -rf "$t"
    printf '%s does not hash to the blob origin/main holds, or cannot be read' "$x"; return 1
  fi
  rm -rf "$t"
  x="$(git -C "$home" ls-files -v -- engine "$pj" 2>/dev/null | LC_ALL=C awk '/^[a-zS] / { print substr($0, 3); exit }')"
  [ -z "$x" ] || { printf '%s carries assume-unchanged or skip-worktree in the index' "$x"; return 1; }
  x="$(git -C "$home" ls-files --others -- engine 2>/dev/null | sed -n 1p)"
  [ -z "$x" ] || { printf '%s is untracked or ignored under engine/' "$x"; return 1; }
  return 0
}

# The checkout helpers (A23), kept here so that green-tick.sh stays under 500 lines.
# Reads the list on stdin and prints the first record on BRANCH at SHA. A function
# of its own: bash 3.2 cannot parse a case pattern's ) inside $( ).
_gt_wt_scan() {   # BRANCH SHA
  local f p="" h="" b=""
  while IFS= read -r -d '' f; do
    if [ -z "$f" ]; then
      [ -z "$p" ] || [ "$b" != "refs/heads/$1" ] || [ "$h" != "$2" ] || { printf '%s' "$p"; return 0; }
      p=""; h=""; b=""; continue
    fi
    case "$f" in
      "worktree "*) p="${f#worktree }" ;;
      "HEAD "*)     h="${f#HEAD }" ;;
      "branch "*)   b="${f#branch }" ;;
    esac
  done
  return 0
}

# The directory's own answers: on the branch, at the head, and a git common dir
# that is the home's own .git (a clone, or a directory swapped for another's).
_gt_common() {   # DIR -> its git common dir, resolved
  local c; c="$(git -C "$1" rev-parse --git-common-dir 2>/dev/null)" && [ -n "$c" ] || return 1
  ( cd "$1" 2>/dev/null && cd "$c" 2>/dev/null && pwd -P )
}
_gt_wt_asks() {   # DIR BRANCH SHA
  local hc dc
  [ "$(git -C "$1" symbolic-ref HEAD 2>/dev/null)" = "refs/heads/$2" ] || return 1
  [ "$(git -C "$1" rev-parse HEAD 2>/dev/null)" = "$3" ] || return 1
  dc="$(_gt_common "$1")" && hc="$(_gt_common "$FELIX_HOME_DIR")" && [ -n "$dc" ] && [ "$dc" = "$hc" ]
}

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
cd "$FELIX_HOME_DIR" 2>/dev/null || owed "the trampoline cannot enter FELIX_HOME_DIR ($FELIX_HOME_DIR), so no engine is run"
# A24: an untracked .gitignore under engine/ would widen what the check below calls residue.
un="$(git ls-files --others -- engine 2>/dev/null)" || owed "git could not list the home's untracked files under engine/, so no engine is run"
[ -z "$un" ] || owed "the home holds an untracked or ignored file under engine/ ($(printf '%s\n' "$un" | sed -n 1p)): nothing runs until it is removed"
pj="$(git show refs/remotes/origin/main:engine/.claude-plugin/plugin.json 2>/dev/null)" \
  || owed "git could not read origin/main's engine version, so no engine is run"
ver="$(printf '%s\n' "$pj" | LC_ALL=C sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | LC_ALL=C sed -n 1p)"
[ -n "$ver" ] || owed "origin/main declares no readable engine version, so no engine is run"
entry="$cache/$ver"
[ -e "$entry/harness/felix" ] || owed "main's engine $ver is not installed under $cache: nothing runs until it is deployed from the home"
[ -x "$entry/harness/felix" ] || owed "main's engine $ver is not executable under $cache: nothing runs until it is deployed from the home"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/felix-land.XXXXXX" 2>/dev/null)" \
  || owed "main's accepted-engine check cannot be loaded: no temporary directory to read it into"
git show refs/remotes/origin/main:engine/harness/lib/resolve.sh > "$tmp/resolve.sh" 2>/dev/null \
  || { rm -rf "$tmp"; owed "main's accepted-engine check cannot be loaded: origin/main holds no lib/resolve.sh"; }
out="$(env -u FELIX_KERNEL_CACHE /bin/bash -c '. "$1" >/dev/null 2>&1
  command -v felix_accepted_deploy_diff >/dev/null 2>&1 || exit 3
  felix_accepted_deploy_diff "$2" refs/remotes/origin/main 2>/dev/null' felix-land "$tmp/resolve.sh" "$FELIX_HOME_DIR")"
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
    printf 'ledger=%s\nFELIX_LAND_LEDGER="$ledger"; export FELIX_LAND_LEDGER\n' "$(_gt_sq "$_GT_LEDGER")"
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
    printf '    <key>PATH</key><string>%s/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>\n' "$(_gt_xml "$HOME")"
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

