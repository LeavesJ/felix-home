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

# A8. Every read of main names the full ref: git resolves a tag or a local
# branch called origin/main before the remote one, and every worktree shares them.
_GT_MAIN=refs/remotes/origin/main

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
  case "$1" in landed|refused|founder|deployed|deployed-unverified|paused|timeout|stuck|gh|fetch|deploy-owed|unresolved) ;; *) return 0 ;; esac
  [ "${_GT_QUIET:-0}" = 1 ] && return 0
  [ "$2" = "-" ] || title="$title #$2"
  det="$(printf '%s' "${3%% \[main *}" | LC_ALL=C sed 's/\\/\\\\/g; s/"/\\"/g')"
  osascript -e "display notification \"$det\" with title \"$title\"" >/dev/null 2>&1 || true
}

_gt_row() {   # EVENT PR SHA WORKTREE WALL DETAIL
  local det; det="$(_gt_clean "${6:-}")"; [ -n "$det" ] || det="-"
  mkdir -p "$_GT_LAND" 2>/dev/null
  # A18: a tab or newline in any column would break the seven fields, not only the detail.
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$(_gt_now)" "$(_gt_clean "$1")" "$(_gt_clean "${2:--}")" "$(_gt_clean "${3:--}")" \
    "$(_gt_clean "${4:--}")" "$(_gt_clean "${5:-0}")" "$det" >> "$_GT_LEDGER" 2>/dev/null
  _gt_say "$1" "${2:--}" "$det"
}

# A pull request that waits writes one row, not one every five minutes: the row
# is written only when it differs from that pull request's previous row.
_gt_last() { LC_ALL=C awk -F'\t' -v p="$1" '$3 == p { l = $2 "\t" $4 "\t" $7 } END { print l }' "$_GT_LEDGER" 2>/dev/null; }
_gt_row_once() {   # EVENT PR SHA WORKTREE WALL DETAIL
  local det; det="$(_gt_clean "${6:-}")"
  [ "$(_gt_last "$2")" != "$(printf '%s\t%s\t%s' "$1" "$3" "${det:--}")" ] || return 0
  _gt_row "$@"
}

# Pausing writes the file; the ledger row and the notification are the next
# tick's, which finds the file first (G2). A hand pause does the same.
_gt_pause() { mkdir -p "$_GT_LAND" 2>/dev/null; printf '%s\n' "$1" > "$_GT_LAND/paused"; }

# --- the lock and the clock --------------------------------------------------
# A lock is held by a live tick when its pid is alive and its started line is
# that process's start time. A pid that is alive under another start time was
# reused, so the lock is dead. A started line that is absent or empty cannot be
# compared, so a live pid holds it: no tick reads a half-written lock as dead (A5).
_gt_started() { LC_ALL=C ps -o lstart= -p "$1" 2>/dev/null | LC_ALL=C sed 's/^ *//; s/ *$//'; }

_gt_unlock() {
  [ -z "${_GT_WD:-}" ] || { kill "$_GT_WD" 2>/dev/null; wait "$_GT_WD" 2>/dev/null; _GT_WD=""; }
  [ "${_GT_LOCKED:-0}" = 1 ] || return 0
  rm -rf "$_GT_LAND/lock" 2>/dev/null; _GT_LOCKED=0
}

# Seconds the process has run, from ps's [[dd-]hh:]mm:ss; empty when unreadable.
_gt_age() {
  LC_ALL=C ps -o etime= -p "$1" 2>/dev/null | LC_ALL=C awk 'NF { n = split($1, a, /[-:]/); s = 0
    if (n == 2) s = a[1] * 60 + a[2]; else if (n == 3) s = a[1] * 3600 + a[2] * 60 + a[3]
    else if (n == 4) s = a[1] * 86400 + a[2] * 3600 + a[3] * 60 + a[4]; else exit; print s }'
}

# 0 when the lock directory names a live tick; sets _GT_HPID to its pid.
_gt_holder_live() {
  local pid="" st=""
  [ -f "$1/pid" ] && pid="$(LC_ALL=C sed -n 1p "$1/pid" 2>/dev/null)"
  [ -f "$1/started" ] && st="$(LC_ALL=C sed -n 1p "$1/started" 2>/dev/null)"; _GT_HPID=""
  case "$pid" in ""|*[!0123456789]*) return 1 ;; esac
  kill -0 "$pid" 2>/dev/null || return 1
  _GT_HPID="$pid"
  [ -z "$st" ] || [ "$(_gt_started "$pid")" = "$st" ]
}

# A5. The pid and started line are written into a fresh directory, which is
# renamed to lock/. A dead lock is first renamed aside to a unique name, and
# only the tick whose rename succeeds goes on to take it. mv onto an existing
# directory would move into it, so a rename that did not win is told by lock/pid.
_gt_take() {   # 0 when this tick's directory is now lock/
  local l="$_GT_LAND/lock" t="$_GT_LAND/lock.new.$$"
  rm -rf "$t"; mkdir "$t" 2>/dev/null || return 1
  printf '%s\n' "$$" > "$t/pid"; _gt_started "$$" > "$t/started"
  [ ! -e "$l" ] && mv "$t" "$l" 2>/dev/null
  if [ "$(LC_ALL=C sed -n 1p "$l/pid" 2>/dev/null)" = "$$" ] && [ ! -e "$t" ]; then return 0; fi
  rm -rf "$t" "$l/lock.new.$$" 2>/dev/null; return 1
}

_gt_lock() {   # 0 when taken; 1 when a live tick holds it or another tick won it
  local l="$_GT_LAND/lock" dead age old
  mkdir -p "$_GT_LAND" 2>/dev/null
  if [ -e "$l" ]; then
    if _gt_holder_live "$l"; then
      age="$(_gt_age "$_GT_HPID")"
      # A live lock older than 45 minutes is said once, and neither taken nor signalled.
      if [ -n "$age" ] && [ "$age" -gt 2700 ]; then
        _gt_row_once stuck - - - 0 "tick $_GT_HPID has held the lock for over 45 minutes: it is neither taken nor signalled"
      fi
      return 1
    fi
    old="$(LC_ALL=C sed -n 1p "$l/pid" 2>/dev/null)"
    dead="$_GT_LAND/lock.dead.$$.$RANDOM"
    mv "$l" "$dead" 2>/dev/null || return 1
    # Another tick may have replaced the dead lock between the look and the
    # rename; what was moved aside is dead only if it still names the same pid.
    if [ "$(LC_ALL=C sed -n 1p "$dead/pid" 2>/dev/null)" != "$old" ]; then
      [ -e "$l" ] || mv "$dead" "$l" 2>/dev/null; return 1
    fi
    rm -rf "$dead" 2>/dev/null
  fi
  _gt_take || return 1
  _GT_LOCKED=1; _GT_T00=$SECONDS
  # Released on every way out. bash runs a trap once the foreground command
  # returns, and the exit a trap names runs the EXIT one.
  trap '_gt_unlock' EXIT
  trap '_gt_timeout' TERM; trap 'exit 130' INT; trap 'exit 129' HUP
  return 0
}

_gt_timeout() {
  trap '' TERM
  _gt_row timeout - - - "$((SECONDS - ${_GT_T00:-0}))" "the tick was stopped by TERM, as the 30 minute watchdog sends it: its lock is released"
  exit 143
}

# A4, A25. After 30 minutes the watchdog sends TERM to the tick's pid first, and
# only then to the tick's descendants, listed before the tick can end and orphan
# them. It never signals its own pid or its own process group: the group is the
# shell's when the tick is run by hand, and holds the watchdog itself.
_gt_descendants() {   # PID [SKIP] -> PID's descendants' pids, one per line, minus SKIP and its own
  LC_ALL=C ps -axo pid=,ppid= 2>/dev/null | LC_ALL=C awk -v root="$1" -v skip="${2:-x}" '{ k[NR] = $1; par[$1] = $2 }
    END { want[root] = 1; sk[skip] = 1
          do { c = 0; for (i = 1; i <= NR; i++) {
                 if (!(k[i] in want) && (par[k[i]] in want)) { want[k[i]] = 1; c = 1 }
                 if (!(k[i] in sk) && (par[k[i]] in sk)) { sk[k[i]] = 1; c = 1 } } } while (c)
          for (i = 1; i <= NR; i++) if (k[i] != root && (k[i] in want) && !(k[i] in sk)) print k[i] }'
}

_GT_WDSECS=1800
_gt_watchdog() {
  local tick=$$ st; st="$(_gt_started "$tick")"
  (
    trap - EXIT; exec >/dev/null 2>&1 </dev/null
    me="$(sh -c 'echo $PPID')"
    sleep "$_GT_WDSECS" & sp=$!
    trap 'kill "$sp" 2>/dev/null; exit 0' TERM
    wait "$sp" 2>/dev/null
    # A15: the pid may name another process by now; only the tick it was set on is signalled.
    [ -n "$st" ] && [ "$(_gt_started "$tick")" = "$st" ] || exit 0
    kids="$(_gt_descendants "$tick" "$me")"
    kill -TERM "$tick" 2>/dev/null
    [ -z "$kids" ] || kill -TERM $kids 2>/dev/null
  ) &
  _GT_WD=$!
}

# fetch and pull neither prompt nor wait on a stalled server forever.
_gt_git() { GIT_TERMINAL_PROMPT=0 GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=60 git "$@"; }

# --- what main holds --------------------------------------------------------
_gt_cache() { printf '%s/felix/felix' "${FELIX_PLUGIN_CACHE:-$HOME/.claude/plugins/cache}"; }

# G3. felix_accepted_deploy_diff is the question the gate's `installed` check
# and felix merge's judge check ask: the cache entry for the version main
# declares, against main's own engine read from the commit. Asked with the
# caller's FELIX_KERNEL_CACHE out of the environment, because that variable
# names a judge the merge boundary does not take from the environment either.
_gt_deploy_owed() {   # prints why a deploy is owed; 0 when one is
  local why rc
  # A20: a verify cut off by the watchdog, a logout or a reboot left this file, and
  # is run again before anything merges.
  [ ! -e "$_GT_LAND/verifying" ] || { printf 'a deploy was started and its verify did not finish: it is run again'; return 0; }
  why="$( unset FELIX_KERNEL_CACHE; felix_accepted_deploy_diff "$FELIX_HOME_DIR" "$_GT_MAIN" 2>&1 )"; rc=$?
  if [ "$rc" -eq 0 ]; then
    # A2: an entry that is already main's does not make the deploy done. The
    # author's gate installs the entry for its own head, so after that head
    # lands the cache is right and the home is still behind, unverified.
    [ "$(git -C "$FELIX_HOME_DIR" rev-parse HEAD 2>/dev/null)" != "$(git -C "$FELIX_HOME_DIR" rev-parse "$_GT_MAIN" 2>/dev/null)" ] || return 1
    why="the home checkout is not at origin/main: the engine it holds has not been deployed and verified"
  fi
  printf '%s' "$(printf '%s\n' "$why" | LC_ALL=C sed -n 1p)"
}

_gt_unverified() { _gt_row deployed-unverified - - - "$((SECONDS - _GT_T0))" "$1"; _gt_pause "$1"; }

# G7. Returns 0 when the new engine is installed and verified. Every other way
# out has written its row, and a deploy that is not known good pauses the job:
# nothing is rolled back, because that is roadmap step 12.
_gt_deploy() {
  local home="$FELIX_HOME_DIR" why ver out entry rc
  _GT_T0=$SECONDS
  # A gate or suite measures the engine it runs under; replacing the engine
  # beneath it would invalidate that, and nothing is ever signalled. A14: tests/red
  # starts the suite by a relative path, and a pgrep that fails reads as a suite running.
  pgrep -f 'engine/harness/tests/run|gate\.sh' >/dev/null 2>&1; rc=$?
  if [ "$rc" -ne 1 ]; then
    [ "$rc" -eq 0 ] && why="a gate or suite is running" || why="a gate or suite may be running: pgrep exited $rc"
    _gt_row_once deploy-owed - - - 0 "$why"; return 1
  fi
  why=""
  [ "$(git -C "$home" rev-parse --abbrev-ref HEAD 2>/dev/null)" = "main" ] || why="the home checkout is not on main"
  [ -n "$why" ] || [ -z "$(git -C "$home" status --porcelain --untracked-files=no 2>/dev/null)" ] \
    || why="the home checkout holds a tracked change"
  if [ -n "$why" ]; then
    _gt_row_once deploy-owed - - - 0 "$why"; _gt_pause "$why"; return 1
  fi
  # A home ahead of origin/main, or diverged from it, holds a tree nothing judged.
  # Only origin/main's own commit is main, and nothing is installed from anything else.
  if ! git -C "$home" merge-base --is-ancestor HEAD "$_GT_MAIN" 2>/dev/null; then
    why="the home checkout holds a commit origin/main does not: it is ahead of or diverged from origin/main"
    _gt_row_once deploy-owed - - - 0 "$why"; _gt_pause "$why"; return 1
  fi
  : > "$_GT_LAND/verifying"   # A26: owed from here; a deploy A24 stops is redone after --resume. Removed only by the deployed row below
  out="$(_gt_git -C "$home" pull -q --ff-only 2>&1 </dev/null)" || { _gt_unverified "pull: git pull --ff-only failed: $(printf '%s\n' "$out" | LC_ALL=C sed -n 1p)"; return 1; }
  if [ "$(git -C "$home" rev-parse HEAD 2>/dev/null)" != "$(git -C "$home" rev-parse "$_GT_MAIN" 2>/dev/null)" ]; then
    why="the home checkout's main is not origin/main: it holds a commit origin does not"
    _gt_row_once deploy-owed - - - 0 "$why"; _gt_pause "$why"; return 1
  fi
  # A24: nothing of the home's runs until its engine/ and project are main's, byte for byte.
  why="$(_gt_home_exact)" || {
    why="the home checkout is not main byte for byte: $why"; _gt_row_once deploy-owed - - - 0 "$why"; _gt_pause "$why"; return 1; }
  out="$(cd "$home" && "$home/engine/harness/felix" install --no-bump 2>&1 </dev/null)" \
    || { _gt_unverified "install: felix install --no-bump failed: $(printf '%s\n' "$out" | LC_ALL=C tail -1)"; return 1; }
  ver="$(_felix_plugin_version "$home")"
  entry="$(_gt_cache)/$ver"
  # A21: against main's own commit, not the home's files: an untracked file in the home's engine/ cannot pass.
  out="$( unset FELIX_KERNEL_CACHE; felix_accepted_deploy_diff "$home" "$_GT_MAIN" 2>&1 )" \
    || { _gt_unverified "diff: the cache entry for ${ver:-no version} is not origin/main's engine: $(printf '%s\n' "$out" | LC_ALL=C sed -n 1p)"; return 1; }
  printf '{"session_id":"felix-land-verify","source":"startup","cwd":"%s"}\n' "$home" \
    | ( cd "$home" && "$home/engine/harness/hooks/session-start" ) >/dev/null 2>&1
  rc=$?
  [ "$rc" -eq 0 ] || { _gt_unverified "session-start: the home's hooks/session-start exited $rc on a stub payload"; return 1; }
  ( cd "$home" && "$home/engine/harness/felix" gate --quick ) >/dev/null 2>&1 </dev/null
  rc=$?
  [ "$rc" -eq 0 ] || { _gt_unverified "gate: felix gate --quick exited $rc in the home"; return 1; }
  _gt_row deployed - - - "$((SECONDS - _GT_T0))" "$ver is installed, matches origin/main, and passed session-start and felix gate --quick"
  rm -f "$_GT_LAND/verifying"
  return 0
}

# --- one pull request -------------------------------------------------------
# The files a pull request changes: git's list and gh's together, because gh caps
# the files it lists and a direction document past the cap must not read as
# absent. The union only ever holds more back. git's is read with -z and
# --no-renames (A9, A3): quoting never hides a byte, and a rename lists its old
# path as well as its new one. Returns 1 when a list cannot be read and 3 when a
# path holds a byte outside printable ASCII: the file system folds Unicode case
# too, so projectſ/x/CLAUDE.md is the founder's file once it is checked out.
_gt_files() {   # PR SHA
  local out n g
  g="$(git -C "$FELIX_HOME_DIR" diff -z --no-renames --name-only "$_GT_MAIN...$2" 2>/dev/null \
        | LC_ALL=C tr -c '\040-\176\000' '\001' | LC_ALL=C tr '\0' '\n')" || return 1
  case "$g" in *$'\001'*) return 3 ;; esac
  out="$(gh pr view "$1" ${_GT_REPO:+--repo "$_GT_REPO"} --json files \
          --jq '(.files // []) as $f | ($f | length), ($f[].path)' 2>/dev/null)" || return 1
  n="$(printf '%s\n' "$out" | LC_ALL=C sed -n 1p)"
  case "$n" in ""|*[!0123456789]*) return 1 ;; esac
  [ "$(printf '%s\n' "$out" | LC_ALL=C awk 'END { print NR - 1 }')" = "$n" ] || return 1
  { printf '%s\n' "$out" | LC_ALL=C sed '1d'; printf '%s\n' "$g"; } | LC_ALL=C awk 'NF && !seen[$0]++'
}

# G5. These two patterns are an engine constant and name no project.
_gt_direction() {   # FILES -> the first path that is a direction document
  local f lc LC_ALL=C
  while IFS= read -r f; do
    # This Mac's file system folds case, so projects/x/claude.md is the founder's CLAUDE.md.
    lc="$(printf '%s' "$f" | tr 'A-Z' 'a-z')"
    case "$lc" in projects/*/claude.md|docs/*roadmap*) printf '%s' "$f"; return 0 ;; esac
  done <<EOF
$1
EOF
  return 1
}

# The checkout a session would have merged from: a worktree of the home whose
# branch is the pull request's and whose HEAD is the head the gate ran on. The
# tick never checks one out, fetches into it, resets, cleans or writes to it.
# A23. The list is read with -z one NUL-ended field at a time and a record ends at
# its empty field, so no byte inside a field (a lock reason holds newlines and
# anything else) is ever a separator. The chosen directory is then asked itself.
# It prints the path; ! when the path holds a tab, CR or newline (A18) and ? when
# the directory does not report the branch, the head and the home's own .git.
_gt_checkout() {   # BRANCH SHA -> the worktree's path
  local w; w="$(git -C "$FELIX_HOME_DIR" worktree list --porcelain -z 2>/dev/null | _gt_wt_scan "$1" "$2")"
  [ -n "$w" ] || return 0
  case "$w" in *[$'\t\r\n']*) printf '!'; return 0 ;; esac
  _gt_wt_asks "$w" "$1" "$2" && printf '%s' "$w" || printf '?'
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

# A13. A refusal is final until the head or main moves; the row records both.
# The ledger row is written on every run; it is notified only if the blocker or
# the head differs from the pull request's previous refused row.
_gt_refuse() {   # PR SHA WORKTREE WALL OUTPUT
  local b; b="$(_gt_clean "$(_gt_detail "$5")")"
  case "$(_gt_last "$1")" in "refused"$'\t'"$2"$'\t'"$b [main "*) _GT_QUIET=1 ;; esac
  _gt_row refused "$1" "$2" "$3" "$4" "$b [main $_GT_MS]"; _GT_QUIET=0
}

# A19: felix merge picks its pull request by branch name, so a head branch two open pull requests share is merged for neither.
_gt_dup() { case $'\n'"$_GT_DUPS"$'\n' in *$'\n'"$1"$'\n'*) return 0 ;; esac; return 1; }

_gt_candidate() {   # PR BRANCH SHA DRAFT HOLD MERGEABLE CROSS BASE -> 0 when it landed
  local n="$1" br="$2" sha="$3" why files dir wt out rc t0 frc
  if   [ "$4" = true ]; then why="a draft"
  elif [ "$5" != - ]; then why="labelled $5"
  elif [ "$7" = true ]; then why="cross-repository: the head is not in this repository"
  elif [ "$6" = CONFLICTING ]; then why="conflicting with main"
  elif [ "$8" != main ]; then why="its base is $8, not main: only pull requests into main are merged"
  elif _gt_dup "$br"; then why="another open pull request has the head branch $br: felix merge picks its pull request by branch name"
  else
    why="$(_felix_merge_gate_held "$PROJ" "$FELIX_HOME_DIR" "$sha")" || why="gate run not green: $why"
    case "$why" in "gate run not green: "*) ;; *) why="" ;; esac
  fi
  if [ -n "$why" ]; then _gt_row_once skip "$n" "$sha" - 0 "$why"; return 1; fi
  files="$(_gt_files "$n" "$sha")"; frc=$?
  [ "$frc" -ne 3 ] || { _gt_row_once founder "$n" "$sha" - 0 "changes a path outside printable ASCII, which this Mac's file system may fold onto a direction document"; return 1; }
  [ "$frc" -eq 0 ] && [ -n "$files" ] || { _gt_row_once skip "$n" "$sha" - 0 "could not read the files the pull request changes"; return 1; }
  dir="$(_gt_direction "$files")" && {
    _gt_row_once founder "$n" "$sha" - 0 "touches $dir, a direction document; those merge on the founder's yes"; return 1; }
  wt="$(_gt_checkout "$br" "$sha")"
  [ -n "$wt" ] || { _gt_row_once session "$n" "$sha" - 0 "no checkout holds the gated head"; return 1; }
  [ "$wt" != "!" ] || { _gt_row_once session "$n" "$sha" - 0 "the checkout holding the gated head has a tab or newline in its path: it is never used"; return 1; }
  [ "$wt" != "?" ] || { _gt_row_once session "$n" "$sha" - 0 "the directory the worktree list names does not report the gated branch, the gated head and the home's own .git: it is never used"; return 1; }
  case "$(_gt_last "$n")" in "refused"$'\t'"$sha"$'\t'*"[main $_GT_MS]") return 1 ;; esac
  t0=$SECONDS
  out="$(_gt_merge "$wt" "$_GT_VER")"; rc=$?
  if [ "$rc" -eq 0 ]; then
    _gt_row landed "$n" "$sha" "$wt" "$((SECONDS - t0))" "merged"
    printf '%s\n' "$files" | LC_ALL=C awk '/^engine\// { f = 1 } END { exit !f }' && _GT_ENGINE=1
    return 0
  fi
  _gt_refuse "$n" "$sha" "$wt" "$((SECONDS - t0))" "$out"
  return 1
}

# --- the tick ---------------------------------------------------------------
# A30: the founder's labels hold as felix:hold does, matched without regard to
# case as GitHub's are. The hold column is the first such label as the pull
# request carries it, or - when it carries none.
_gt_prs() {   # prints "number branch oid draft hold mergeable cross base" lines, ascending
  local out n
  out="$(gh pr list ${_GT_REPO:+--repo "$_GT_REPO"} --state open --limit 200 \
          --json number,headRefName,headRefOid,isDraft,labels,mergeable,isCrossRepository,baseRefName \
          --jq 'length, (.[] | [(.number | tostring), (.headRefName // "-"), (.headRefOid // "-"), (.isDraft | tostring),
                ([(.labels // [])[] | (.name // "") | select(ascii_downcase | . == "felix:hold" or . == "felix:founder" or . == "needs-founder")] | .[0] // "-"),
                (.mergeable // "UNKNOWN"),
                (.isCrossRepository | tostring), (.baseRefName // "-")] | join("\t"))' 2>/dev/null)" || return 1
  n="$(printf '%s\n' "$out" | LC_ALL=C sed -n 1p)"
  case "$n" in ""|*[!0123456789]*) return 1 ;; esac
  [ "$(printf '%s\n' "$out" | LC_ALL=C awk 'END { print NR - 1 }')" = "$n" ] || return 1
  printf '%s\n' "$out" | LC_ALL=C sed '1d' | LC_ALL=C sort -t "$(printf '\t')" -k1,1n
}

_gt_tick() {
  local last age ver why prs n br sha dr ho mg cr bs
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
  _gt_watchdog
  if ! gh auth status >/dev/null 2>&1; then
    _gt_row_once gh - - - 0 "gh auth status failed: the job cannot see pull requests or CI"; return 0
  fi
  # G3: what main holds is deployed before anything merges, because felix merge
  # refuses every candidate for want of an installed judge.
  if ! _gt_git -C "$FELIX_HOME_DIR" fetch -q origin >/dev/null 2>&1; then
    _gt_row_once fetch - - - 0 "git fetch origin failed in the home: main's version is not known"; return 0
  fi
  ver="$(_felix_plugin_version "$FELIX_HOME_DIR" "$_GT_MAIN")"
  [ -n "$ver" ] || { _gt_row_once fetch - - - 0 "origin/main declares no engine version"; return 0; }
  _GT_VER="$ver"; _GT_MS="$(git -C "$FELIX_HOME_DIR" rev-parse "$_GT_MAIN" 2>/dev/null)"
  # A11: a tick that deploys, whether or not it verifies, merges nothing. The next
  # tick merges with the engine just deployed, and that engine runs it.
  if why="$(_gt_deploy_owed)"; then _gt_deploy; return 0; fi
  prs="$(_gt_prs)" || { _gt_row_once gh - - - 0 "gh pr list failed"; return 0; }
  _GT_ENGINE=0; _GT_DUPS="$(printf '%s\n' "$prs" | LC_ALL=C cut -f2 | LC_ALL=C sort | LC_ALL=C uniq -d)"
  while IFS=$'\t' read -r -u 3 n br sha dr ho mg cr bs; do
    [ -n "${n:-}" ] || continue
    if _gt_candidate "$n" "$br" "$sha" "$dr" "$ho" "$mg" "$cr" "$bs"; then
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

felix_land() {
  case "${1:-}" in
    --tick|--resume|--install|--uninstall) [ $# -eq 1 ] || { _gt_usage; return 2; } ;;
    --pause) [ $# -le 2 ] || { _gt_usage; return 2; } ;;
    --status) { [ $# -eq 1 ] || { [ $# -eq 2 ] && [ "$2" = "--tsv" ]; }; } || { _gt_usage; return 2; } ;;
    *) _gt_usage; return 2 ;;
  esac
  # A10: a tick that cannot resolve its project has no ledger to write; it says so.
  [ "$1" != --tick ] || ( resolve_or_die ) >/dev/null 2>&1 </dev/null || _gt_noproj
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
