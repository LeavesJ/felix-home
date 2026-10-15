# Land on green: the scheduled job that runs `felix merge` on a pull request
# whose gate run has passed (docs/2026-10-15-land-on-green-contract.md).
#
# CI went green on four pull requests and nothing merged until the founder
# asked, up to 16.5 hours later, with the author sessions alive. A session may
# not poll CI and the desktop app wakes one on a failure, never on a pass. So a
# job of Felix's own looks every five minutes and does the one thing a session
# would have done at that moment.
#
# It is not the landing actor of the 2026-09-24 design and judges nothing. The
# author's gate wrote the receipt, CI judged the head, and `felix merge` judges
# escapes, commission tables, the receipt, rule C9 and staleness with main's
# installed engine. This file only chooses which pull request to hand it, hands
# it over from the checkout a session would have used, and deploys what landed.
# A pull request `felix merge` refuses stays with its session, as before.
#
# State is in $(felix_mem_dir <project>)/land/: ledger.tsv (append-only), paused
# (its content is the reason) and lock/ (pid and started). Every outside command
# is called by name through PATH, so a test puts a stub first and nothing here
# reaches a real GitHub, launchd or notification.
#
# Sourced by felix, which defines die, resolve_or_die and $FELIX_HOME_DIR; every
# function here is _gt_ or felix_land so that it names nothing another library
# owns. It sits outside the lib/land*.sh trust-base glob on purpose: it holds no
# rule, only the order in which the existing ones are asked.

# The ledger's time is UTC ISO 8601, the one format that sorts as text and that
# an awk can turn back into seconds without a date(1) that differs per OS.
_gt_now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# Tabs and newlines in a detail would break the row's seven fields.
_gt_clean() { printf '%s' "$1" | LC_ALL=C tr '\t\r\n' '   '; }

_gt_epoch() {   # an ISO time in UTC -> seconds since the epoch
  LC_ALL=C awk -v t="$1" 'BEGIN {
    split(t, a, /[-T:Z]/); y = a[1] + 0; m = a[2] + 0; d = a[3] + 0
    if (m <= 2) y--
    era = int(y / 400); yoe = y - era * 400
    doy = int((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5) + d - 1
    doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy
    print (era * 146097 + doe - 719468) * 86400 + a[4] * 3600 + a[5] * 60 + a[6] }'
}

# One notification per row of the kinds a person should see. The ledger row is
# written first and is the record; a failing osascript changes nothing.
_gt_say() {   # EVENT PR DETAIL
  local title="Felix: $1" det
  case "$1" in landed|refused|founder|deployed|deployed-unverified|paused) ;; *) return 0 ;; esac
  [ "$2" = "-" ] || title="$title #$2"
  det="$(printf '%s' "$3" | LC_ALL=C sed 's/\\/\\\\/g; s/"/\\"/g')"
  osascript -e "display notification \"$det\" with title \"$title\"" >/dev/null 2>&1 || true
}

_gt_row() {   # EVENT PR SHA WORKTREE WALL DETAIL
  local det; det="$(_gt_clean "${6:-}")"; [ -n "$det" ] || det="-"
  mkdir -p "$_GT_LAND" 2>/dev/null
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$(_gt_now)" "$1" "${2:--}" "${3:--}" "${4:--}" "${5:-0}" "$det" \
    >> "$_GT_LEDGER" 2>/dev/null
  _gt_say "$1" "${2:--}" "$det"
}

# A pull request that waits writes one row, not one every five minutes: the row
# is written only when it differs from that pull request's previous row.
_gt_row_once() {   # EVENT PR SHA WORKTREE WALL DETAIL
  local det prev
  det="$(_gt_clean "${6:-}")"
  [ -f "$_GT_LEDGER" ] && prev="$(LC_ALL=C awk -F'\t' -v p="$2" '$3 == p { l = $2 "\t" $4 "\t" $7 } END { print l }' "$_GT_LEDGER")" || prev=""
  [ "$prev" != "$(printf '%s\t%s\t%s' "$1" "$3" "${det:--}")" ] || return 0
  _gt_row "$@"
}

# Pausing writes the file; the ledger row and the notification are the next
# tick's, which finds the file first (G2). A hand pause does the same.
_gt_pause() { mkdir -p "$_GT_LAND" 2>/dev/null; printf '%s\n' "$1" > "$_GT_LAND/paused"; }

# --- the lock -------------------------------------------------------------
# held by a live tick: its pid is alive and its started line is that process's
# start time. A pid that is alive under another start time was reused, so the
# lock is dead; it is taken, never waited on.
_gt_started() { LC_ALL=C ps -o lstart= -p "$1" 2>/dev/null | LC_ALL=C sed 's/^ *//; s/ *$//'; }

_gt_unlock() {
  [ "${_GT_LOCKED:-0}" = 1 ] || return 0
  rm -rf "$_GT_LAND/lock" 2>/dev/null; _GT_LOCKED=0
}

_gt_lock() {   # 0 when taken; 1 when a live tick holds it
  local l="$_GT_LAND/lock" pid st
  mkdir -p "$_GT_LAND" 2>/dev/null
  if ! mkdir "$l" 2>/dev/null; then
    [ -s "$l/pid" ] || sleep 1   # the holder is between its mkdir and its pid
    pid="$(sed -n 1p "$l/pid" 2>/dev/null)"; st="$(sed -n 1p "$l/started" 2>/dev/null)"
    case "$pid" in ""|*[!0123456789]*) pid="" ;; esac
    if [ -n "$pid" ] && [ -n "$st" ] && kill -0 "$pid" 2>/dev/null && [ "$(_gt_started "$pid")" = "$st" ]; then
      return 1
    fi
    rm -rf "$l" 2>/dev/null
    mkdir "$l" 2>/dev/null || return 1
  fi
  _GT_LOCKED=1
  # Released on every way out, a signal included: bash runs the TERM trap once
  # the foreground command returns, and the exit it names runs the EXIT one.
  trap '_gt_unlock' EXIT
  trap 'exit 143' TERM; trap 'exit 130' INT; trap 'exit 129' HUP
  printf '%s\n' "$$" > "$l/pid"; _gt_started "$$" > "$l/started"
  return 0
}

# --- what main holds --------------------------------------------------------
_gt_cache() { printf '%s/felix/felix' "${FELIX_PLUGIN_CACHE:-$HOME/.claude/plugins/cache}"; }

# G3. felix_accepted_deploy_diff is the question the gate's `installed` check
# and felix merge's judge check ask: the cache entry for the version main
# declares, against main's own engine read from the commit. Asked with the
# caller's FELIX_KERNEL_CACHE out of the environment, because that variable
# names a judge the merge boundary does not take from the environment either.
_gt_deploy_owed() {   # prints why a deploy is owed; 0 when one is
  local why rc
  why="$( unset FELIX_KERNEL_CACHE; felix_accepted_deploy_diff "$FELIX_HOME_DIR" origin/main 2>&1 )"; rc=$?
  [ "$rc" -ne 0 ] || return 1
  printf '%s' "$(printf '%s\n' "$why" | sed -n 1p)"
}

_gt_unverified() { _gt_row deployed-unverified - - - "$((SECONDS - _GT_T0))" "$1"; _gt_pause "$1"; }

# G7. Returns 0 when the new engine is installed and verified. Every other way
# out has written its row, and a deploy that is not known good pauses the job:
# nothing is rolled back, because that is roadmap step 12.
_gt_deploy() {
  local home="$FELIX_HOME_DIR" why ver out entry rc
  _GT_T0=$SECONDS
  # A gate or suite measures the engine it runs under. Replacing the engine
  # beneath it would invalidate the measurement, and nothing is ever signalled.
  if pgrep -f '/engine/harness/tests/run|/gate\.sh' >/dev/null 2>&1; then
    _gt_row deploy-owed - - - 0 "a gate or suite is running"; return 1
  fi
  why=""
  [ "$(git -C "$home" rev-parse --abbrev-ref HEAD 2>/dev/null)" = "main" ] || why="the home checkout is not on main"
  [ -n "$why" ] || [ -z "$(git -C "$home" status --porcelain --untracked-files=no 2>/dev/null)" ] \
    || why="the home checkout holds a tracked change"
  if [ -n "$why" ]; then
    _gt_row deploy-owed - - - 0 "$why"; _gt_pause "$why"; return 1
  fi
  out="$(git -C "$home" pull -q --ff-only 2>&1 </dev/null)" || { _gt_unverified "pull: git pull --ff-only failed: $(printf '%s\n' "$out" | sed -n 1p)"; return 1; }
  # An ff-only pull succeeds on a home that is ahead of origin, and what that
  # home holds is a tree nothing judged. Only origin/main's own commit is main.
  if [ "$(git -C "$home" rev-parse HEAD 2>/dev/null)" != "$(git -C "$home" rev-parse origin/main 2>/dev/null)" ]; then
    why="the home checkout's main is not origin/main: it holds a commit origin does not"
    _gt_row deploy-owed - - - 0 "$why"; _gt_pause "$why"; return 1
  fi
  out="$(cd "$home" && "$home/engine/harness/felix" install --no-bump 2>&1 </dev/null)" \
    || { _gt_unverified "install: felix install --no-bump failed: $(printf '%s\n' "$out" | LC_ALL=C tail -1)"; return 1; }
  ver="$(_felix_plugin_version "$home")"
  entry="$(_gt_cache)/$ver"
  out="$(diff -rq "$entry/harness" "$home/engine/harness" 2>&1)" \
    || { _gt_unverified "diff: the cache entry for ${ver:-no version} differs from the home's engine/harness: $(printf '%s\n' "$out" | sed -n 1p)"; return 1; }
  printf '{"session_id":"felix-land-verify","source":"startup","cwd":"%s"}\n' "$home" \
    | ( cd "$home" && "$home/engine/harness/hooks/session-start" ) >/dev/null 2>&1
  rc=$?
  [ "$rc" -eq 0 ] || { _gt_unverified "session-start: the home's hooks/session-start exited $rc on a stub payload"; return 1; }
  ( cd "$home" && "$home/engine/harness/felix" gate --quick ) >/dev/null 2>&1 </dev/null
  rc=$?
  [ "$rc" -eq 0 ] || { _gt_unverified "gate: felix gate --quick exited $rc in the home"; return 1; }
  _gt_row deployed - - - "$((SECONDS - _GT_T0))" "$ver is installed, matches the home, and passed session-start and felix gate --quick"
  return 0
}

# --- one pull request -------------------------------------------------------
# The files a pull request changes: gh's list, and git's as well, because gh
# caps the files it lists and a direction document past the cap must not read
# as absent. The union only ever holds more back. Empty output is a failure.
_gt_files() {   # PR SHA
  local out n g
  out="$(gh pr view "$1" ${_GT_REPO:+--repo "$_GT_REPO"} --json files \
          --jq '(.files // []) as $f | ($f | length), ($f[].path)' 2>/dev/null)" || return 1
  n="$(printf '%s\n' "$out" | sed -n 1p)"
  case "$n" in ""|*[!0123456789]*) return 1 ;; esac
  [ "$(printf '%s\n' "$out" | LC_ALL=C awk 'END { print NR - 1 }')" = "$n" ] || return 1
  # --no-renames: a rename lists both the old path and the new one, so a
  # direction document renamed away is still a changed path. gh gives only the
  # new name, which is why git's list is not optional here.
  g="$(git -C "$FELIX_HOME_DIR" diff --no-renames --name-only "origin/main...$2" 2>/dev/null)" || return 1
  { printf '%s\n' "$out" | sed '1d'; printf '%s\n' "$g"; } | LC_ALL=C awk 'NF && !seen[$0]++'
}

# G5. These two patterns are an engine constant and name no project.
_gt_direction() {   # FILES -> the first path that is a direction document
  local f LC_ALL=C
  while IFS= read -r f; do
    case "$f" in projects/*/CLAUDE.md|docs/*roadmap*) printf '%s' "$f"; return 0 ;; esac
  done <<EOF
$1
EOF
  return 1
}

# The checkout a session would have merged from: a worktree of the home whose
# branch is the pull request's and whose HEAD is the head the gate ran on. The
# tick never checks one out, fetches into it, resets, cleans or writes to it.
_gt_checkout() {   # BRANCH SHA -> the worktree's path
  git -C "$FELIX_HOME_DIR" worktree list --porcelain 2>/dev/null | LC_ALL=C awk -v br="refs/heads/$1" -v sha="$2" '
    function flush() { if (p != "" && b == br && h == sha) { print p; found = 1; exit } }
    /^worktree / { flush(); p = substr($0, 10); h = ""; b = ""; next }
    /^HEAD /     { h = $2; next }
    /^branch /   { b = $2; next }
    END { if (!found) flush() }' | sed -n 1p
}

# G6. The installed engine's felix, from the worktree, with no argument, and
# with the three variables that choose or loosen a judge taken out of its
# environment whatever this process was given.
_gt_merge() {   # WORKTREE VERSION -> output on stdout, felix merge's status
  ( cd "$1" && exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE FELIX_HOME="$FELIX_HOME_DIR" \
      "$(_gt_cache)/$2/harness/felix" merge ) 2>&1 </dev/null
}

_gt_detail() {   # felix merge's output -> the first blocker line, else the last line
  local d
  d="$(printf '%s\n' "$1" | LC_ALL=C awk '/^  / { print; exit }')"
  [ -n "$d" ] || d="$(printf '%s\n' "$1" | LC_ALL=C awk 'NF { l = $0 } END { print l }')"
  printf '%s' "$d"
}

_gt_candidate() {   # PR BRANCH SHA DRAFT HOLD MERGEABLE CROSS -> 0 when it landed
  local n="$1" br="$2" sha="$3" why files dir wt out rc t0
  if   [ "$4" = true ]; then why="a draft"
  elif [ "$5" = true ]; then why="labelled felix:hold"
  elif [ "$7" = true ]; then why="cross-repository: the head is not in this repository"
  elif [ "$6" = CONFLICTING ]; then why="conflicting with main"
  else
    why="$(_felix_merge_gate_held "$PROJ" "$FELIX_HOME_DIR" "$sha")" || why="gate run not green: $why"
    case "$why" in "gate run not green: "*) ;; *) why="" ;; esac
  fi
  if [ -n "$why" ]; then _gt_row_once skip "$n" "$sha" - 0 "$why"; return 1; fi
  files="$(_gt_files "$n" "$sha")" || files=""
  [ -n "$files" ] || { _gt_row_once skip "$n" "$sha" - 0 "could not read the files the pull request changes"; return 1; }
  dir="$(_gt_direction "$files")" && {
    _gt_row_once founder "$n" "$sha" - 0 "touches $dir, a direction document; those merge on the founder's yes"; return 1; }
  wt="$(_gt_checkout "$br" "$sha")"
  [ -n "$wt" ] || { _gt_row_once session "$n" "$sha" - 0 "no checkout holds the gated head"; return 1; }
  t0=$SECONDS
  out="$(_gt_merge "$wt" "$_GT_VER")"; rc=$?
  if [ "$rc" -eq 0 ]; then
    _gt_row landed "$n" "$sha" "$wt" "$((SECONDS - t0))" "merged"
    printf '%s\n' "$files" | LC_ALL=C awk '/^engine\// { f = 1 } END { exit !f }' && _GT_ENGINE=1
    return 0
  fi
  _gt_row_once refused "$n" "$sha" "$wt" "$((SECONDS - t0))" "$(_gt_detail "$out")"
  return 1
}

# --- the tick ---------------------------------------------------------------
_gt_prs() {   # prints "number branch oid draft hold mergeable cross" lines, ascending
  local out n
  out="$(gh pr list ${_GT_REPO:+--repo "$_GT_REPO"} --state open --limit 200 \
          --json number,headRefName,headRefOid,isDraft,labels,mergeable,isCrossRepository \
          --jq 'length, (.[] | [(.number | tostring), (.headRefName // "-"), (.headRefOid // "-"), (.isDraft | tostring),
                (((.labels // []) | any(.name == "felix:hold")) | tostring), (.mergeable // "UNKNOWN"),
                (.isCrossRepository | tostring)] | join("\t"))' 2>/dev/null)" || return 1
  n="$(printf '%s\n' "$out" | sed -n 1p)"
  case "$n" in ""|*[!0123456789]*) return 1 ;; esac
  [ "$(printf '%s\n' "$out" | LC_ALL=C awk 'END { print NR - 1 }')" = "$n" ] || return 1
  printf '%s\n' "$out" | sed '1d' | LC_ALL=C sort -t "$(printf '\t')" -k1,1n
}

_gt_tick() {
  local last age ver why prs n br sha dr ho mg cr
  # Not paused. One row, at most one an hour, so a long pause shows itself.
  if [ -e "$_GT_LAND/paused" ]; then
    last=""
    [ -f "$_GT_LEDGER" ] && last="$(LC_ALL=C awk -F'\t' '$2 == "paused" { t = $1 } END { print t }' "$_GT_LEDGER")"
    age=999999
    [ -z "$last" ] || age=$(( $(date -u +%s) - $(_gt_epoch "$last") ))
    [ "$age" -lt 3600 ] || _gt_row paused - - - 0 "$(cat "$_GT_LAND/paused" 2>/dev/null)"
    return 0
  fi
  _gt_lock || return 0
  if ! gh auth status >/dev/null 2>&1; then
    _gt_row gh - - - 0 "gh auth status failed: the job cannot see pull requests or CI"; return 0
  fi
  # G3: what main holds is deployed before anything merges, because felix merge
  # refuses every candidate for want of an installed judge.
  if ! git -C "$FELIX_HOME_DIR" fetch -q origin >/dev/null 2>&1; then
    _gt_row fetch - - - 0 "git fetch origin failed in the home: main's version is not known"; return 0
  fi
  ver="$(_felix_plugin_version "$FELIX_HOME_DIR" origin/main)"
  [ -n "$ver" ] || { _gt_row fetch - - - 0 "origin/main declares no engine version"; return 0; }
  _GT_VER="$ver"
  if why="$(_gt_deploy_owed)"; then
    _gt_deploy || return 0
  fi
  prs="$(_gt_prs)" || { _gt_row gh - - - 0 "gh pr list failed"; return 0; }
  _GT_ENGINE=0
  while IFS=$'\t' read -r -u 3 n br sha dr ho mg cr; do
    [ -n "${n:-}" ] || continue
    if _gt_candidate "$n" "$br" "$sha" "$dr" "$ho" "$mg" "$cr"; then
      # One landing per tick; a landing that changed engine/ is deployed now.
      [ "$_GT_ENGINE" -ne 1 ] || _gt_deploy
      break
    fi
  done 3<<EOF
$prs
EOF
  return 0
}

# --- the commands -----------------------------------------------------------
_gt_usage() {
  printf 'usage: felix land --tick | --pause [reason] | --resume | --install | --uninstall | --status [--tsv]\n' >&2
  return 2
}

_gt_xml() { printf '%s' "$1" | LC_ALL=C sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }
_gt_sq() { printf "'%s'" "$(printf '%s' "$1" | LC_ALL=C sed "s/'/'\\\\''/g")"; }

_gt_install() {
  local p tr plist uid="$(id -u)"
  p="$(basename "$PROJ")"
  tr="$HOME/Library/Application Support/felix/land/$p/tick"
  plist="$HOME/Library/LaunchAgents/felix.land.$p.plist"
  mkdir -p "$(dirname "$tr")" "$HOME/Library/LaunchAgents" "$_GT_LAND" || die "could not make the job's directories"
  # Static: it names no version and no working tree. The installed engine for
  # the version origin/main declares is resolved when it runs, so a deploy
  # needs no new trampoline. When that engine is not installed it runs nothing:
  # every gated branch leaves a newer, unmerged version in the cache, and that
  # candidate's code must never pick what merges. The job records the wait in
  # the ledger and tells the founder, who deploys by hand from the home.
  # FELIX_HOME is what the installed engine reads to find its home; the plist
  # names FELIX_HOME_DIR, which is the contract's word.
  {
    printf '#!/bin/sh\n# Written by felix land --install; felix land --uninstall removes it.\n'
    printf ': "${FELIX_HOME_DIR:=%s}"\nexport FELIX_HOME_DIR\nFELIX_HOME="$FELIX_HOME_DIR"; export FELIX_HOME\n' "$(_gt_sq "$FELIX_HOME_DIR")"
    printf 'cd "$FELIX_HOME_DIR" || exit 1\n'
    printf 'cache="${FELIX_PLUGIN_CACHE:-$HOME/.claude/plugins/cache}/felix/felix"\nledger=%s\n' "$(_gt_sq "$_GT_LEDGER")"
    printf 'ver="$(git show origin/main:engine/.claude-plugin/plugin.json 2>/dev/null | LC_ALL=C sed -n %s | LC_ALL=C sed -n 1p)"\n' \
      "'s/.*\"version\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p'"
    printf 'if [ -z "$ver" ] || [ ! -x "$cache/$ver/harness/felix" ]; then\n'
    printf '  d="main'"'"'s engine ${ver:-(version unreadable)} is not installed under $cache: nothing runs until it is deployed from the home"\n'
    printf '  t="$(printf '"'"'deploy-owed\\t%%s'"'"' "$d")"\n'
    printf '  [ "$(tail -n 1 "$ledger" 2>/dev/null | LC_ALL=C cut -f2,7)" = "$t" ] || {\n'
    printf '    mkdir -p "$(dirname "$ledger")"\n'
    printf '    printf '"'"'%%s\\tdeploy-owed\\t-\\t-\\t-\\t0\\t%%s\\n'"'"' "$(date -u +%%Y-%%m-%%dT%%H:%%M:%%SZ)" "$d" >> "$ledger"\n'
    printf '    osascript -e "display notification \\"Felix land: no installed engine for main to run\\" with title \\"Felix: deploy-owed\\"" >/dev/null 2>&1\n'
    printf '  }\n  echo "felix land: $d" >&2; exit 1\nfi\n'
    printf 'exec "$cache/$ver/harness/felix" land --tick\n'
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

felix_land() {
  case "${1:-}" in
    --tick|--resume|--install|--uninstall) [ $# -eq 1 ] || { _gt_usage; return 2; } ;;
    --pause) ;;
    --status) { [ $# -eq 1 ] || { [ $# -eq 2 ] && [ "$2" = "--tsv" ]; }; } || { _gt_usage; return 2; } ;;
    *) _gt_usage; return 2 ;;
  esac
  resolve_or_die
  local cmd="$1"; shift
  _GT_LAND="$(felix_mem_dir "$PROJ")/land"; _GT_LEDGER="$_GT_LAND/ledger.tsv"
  _GT_REPO="$(felix_repo_slug "$FELIX_HOME_DIR" 2>/dev/null)"
  case "$cmd" in
    --tick)      _gt_tick; _gt_unlock; return 0 ;;
    --pause)     _gt_pause "${*:-paused by hand}" ;;
    --resume)    rm -f "$_GT_LAND/paused" ;;
    --install)   _gt_install ;;
    --uninstall) _gt_uninstall ;;
    --status)    _gt_status "$@" ;;
  esac
}
