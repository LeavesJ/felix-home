# Land on green: the commands that install, remove and report the scheduled job
# (docs/2026-10-15-land-on-green-contract.md G9, A1). The tick is lib/green-tick.sh;
# this file holds the trampoline launchd runs, the plist that names it, and the
# read-only status, and the helpers the tick calls that did not fit under its 500
# lines (the checkout helpers, A23; the retry and wait helpers, audit b02, in
# docs/2026-10-24-audit-fixes/b02-land-tick-never-refuses-or-waits-silentl.md).
# Sourced by felix beside green-tick.sh, outside the
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
  git -C "$home" hash-object --no-filters --stdin-paths < "$t/paths" > "$t/got" 2>/dev/null
  if ! cmp -s "$t/want" "$t/got"; then
    n="$(LC_ALL=C awk 'NR == FNR { w[FNR] = $0; next } { g = FNR; if ($0 != w[FNR] && !f) f = FNR } END { print f ? f : g + 1 }' "$t/want" "$t/got")"
    x="$(LC_ALL=C sed -n "${n}p" "$t/paths")"; rm -rf "$t"
    printf '%s does not hash to the blob origin/main holds, or cannot be read' "$x"; return 1
  fi
  rm -rf "$t"
  x="$(git -C "$home" ls-files -v -- engine "$pj" 2>/dev/null | LC_ALL=C awk '/^[a-zS] / { print substr($0, 3); exit }')"
  [ -z "$x" ] || { printf '%s carries assume-unchanged or skip-worktree in the index' "$x"; return 1; }
  x="$(git -C "$home" ls-files --others -- engine 2>/dev/null | LC_ALL=C sed -n 1p)"
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

# B1-B9 (audit b02). What lifts a refusal, said in its detail as one of three clauses.
_GT_CR='(tried again when a new gate or commission receipt is written)'
_GT_CF='(final until the head or main moves)'
_GT_CH='(tried again an hour after this row)'
_gt_clause() { case "$1" in receipt) printf '%s' "$_GT_CR" ;; final) printf '%s' "$_GT_CF" ;; *) printf '%s' "$_GT_CH" ;; esac; }

# B1. receipt: exit 3 and a blocker block of unverified and commission receipt lines only, so a new
# receipt can lift it; final: exit 3 with any other block or none; hourly: any other status. The
# block follows the first line that is exactly "not merging", past its one empty line, to the next
# empty line.
_gt_class() {   # STATUS OUTPUT -> receipt, final or hourly
  [ "$1" = 3 ] || { printf hourly; return 0; }
  printf '%s\n' "$2" | LC_ALL=C awk 'BEGIN { s = 0; n = 0; b = 0 }
    s == 0 { if ($0 == "not merging") s = 1; next }
    s == 1 { s = 2; if ($0 == "") next }
    $0 == "" { exit }
    { n++; if (!($1 == "unverified" || ($1 == "commission" && $2 == "receipt"))) b = 1 }
    END { print (n > 0 && !b) ? "receipt" : "final" }'
}

# B4. What one receipt file holds, by its sum: - when absent, ? when unknown. Other bytes, other sum.
_gt_sum() {   # FILE
  local s
  [ -n "$1" ] || { printf '%s' '?'; return 0; }
  [ -e "$1" ] || { printf '%s' -; return 0; }
  s="$(LC_ALL=C cksum < "$1" 2>/dev/null)"; printf '%s' "${s:-?}"
}
_gt_rsig() {   # WORKTREE -> what its gate receipt and the project's commission receipt hold now
  local w; w="$(cd "$1" 2>/dev/null && pwd -P)" || w="$1"
  printf 'gate %s commission %s' "$(_gt_sum "$(_felix_receipt_path "$w" "$FELIX_HOME_DIR")")" \
    "$(_gt_sum "$(felix_commission_receipt_path "$FELIX_HOME_DIR" "$PROJ")")"
}

# B3-B6, B9. 0 when the pull request's newest row is a refusal that still stands: on this head and
# this main, and either final (or from before the clauses), or hourly and under an hour old, or
# receipt and the receipts hold what the tick recorded before that run. A receipt refusal with no
# record is unknown, not unchanged, and is run once more. Sets _GT_SIG for the run about to follow.
_gt_held() {   # PR SHA WORKTREE
  local n="$1" T row t ev hd det age
  T="$(printf '\t')"; _GT_SIG="$(_gt_rsig "$3")"
  row="$(LC_ALL=C awk -F'\t' -v p="$n" '$3 == p { l = $1 "\t" $2 "\t" $4 "\t" $7 } END { print l }' "$_GT_LEDGER" 2>/dev/null)"
  t="${row%%"$T"*}"; row="${row#*"$T"}"; ev="${row%%"$T"*}"; row="${row#*"$T"}"; hd="${row%%"$T"*}"; det="${row#*"$T"}"
  [ "$ev" = refused ] && [ "$hd" = "$2" ] || return 1
  case "$det" in *" [main $_GT_MS]") ;; *) return 1 ;; esac
  case "$det" in
    *" $_GT_CH [main "*)
      age=$(( $(date -u +%s) - $(_gt_epoch "$t") ))
      [ "$age" -ge 0 ] && [ "$age" -lt 3600 ] && return 0; return 1 ;;
    *" $_GT_CR [main "*)
      [ "$(cat "$_GT_LAND/retry.$n" 2>/dev/null)" = "$hd $_GT_MS $_GT_SIG" ] && return 0; return 1 ;;
  esac
  return 0
}
_gt_record() {   # PR SHA CLASS: after a refusal, what the receipts held before the run, kept for a receipt refusal only
  if [ "$3" = receipt ]; then printf '%s %s %s\n' "$2" "$_GT_MS" "$_GT_SIG" > "$_GT_LAND/retry.$1" 2>/dev/null
  else rm -f "$_GT_LAND/retry.$1"; fi
  return 0
}

# B13. A job row (no pull request) is said when it is not the same wait as the newest job row, and
# again, with when it began, each hour it lasts. The same wait: the same event and the same detail
# up to the first "; ". The run it began is the unbroken run of such rows ending at the newest job
# row; a row for a pull request does not break it.
_gt_job_once() {   # EVENT DETAIL
  local ev="$1" det="$2" hd tl run age
  hd="${det%%; *}"; tl=""; case "$det" in *"; "*) tl="; ${det#*; }" ;; esac
  run="$(GT_E="$ev" GT_H="$hd" LC_ALL=C awk -F'\t' '$3 == "-" { i = index($7, "; "); k = (i ? substr($7, 1, i - 1) : $7)
      if ($2 == ENVIRON["GT_E"] && k == ENVIRON["GT_H"]) { if (!r) t = $1; r = 1; l = $1 } else r = 0 }
    END { if (r) print l, t }' "$_GT_LEDGER" 2>/dev/null)"
  if [ -n "$run" ]; then
    age=$(( $(date -u +%s) - $(_gt_epoch "${run%% *}") ))
    [ "$age" -ge 0 ] && [ "$age" -lt 3600 ] && return 0
    det="$hd; still so since ${run#* }$tl"
  fi
  _gt_row "$ev" - - - 0 "$det"
}

# B12. The processes a gate-or-suite wait names: pid <p> (<its command, cut to 80 bytes>) for each.
_gt_procs() {   # PIDS, one per line
  local p c out="" s=""
  for p in $1; do
    case "$p" in ""|*[!0123456789]*) continue ;; esac
    c="$(LC_ALL=C ps -o command= -p "$p" 2>/dev/null | LC_ALL=C cut -c1-80)"
    out="$out${s}pid $p${c:+ ($c)}"; s=", "
  done
  printf '%s' "${out:-no pid}"
}

# B20. felix install does not replace an entry that exists: say so when the one that differs was there.
_gt_didnt() {   # HAD ENTRY
  [ "$1" = 1 ] || return 0
  printf 'it existed before the install, and felix install does not replace an entry that exists, so %s stays as it is: ' "$2"
}

# B22-B25. The brakes leave a row, with the session that used them.
_gt_by() { printf 'by session %s' "${CLAUDE_CODE_SESSION_ID:--}"; }
_gt_hand_pause() {   # REASON
  _gt_pause "$1"; _gt_row paused - - - 0 "$1; $(_gt_by)"; return 0
}
_gt_hand_resume() {
  local why
  [ -e "$_GT_LAND/paused" ] || return 0
  why="$(LC_ALL=C sed -n 1p "$_GT_LAND/paused" 2>/dev/null)"
  _gt_row resumed - - - 0 "the pause read: $why; $(_gt_by)"
  rm -f "$_GT_LAND/paused"; return 0
}

_gt_xml() { printf '%s' "$1" | LC_ALL=C sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }
_gt_sq() { printf "'%s'" "$(printf '%s' "$1" | LC_ALL=C sed "s/'/'\\\\''/g")"; }

# The trampoline's static body. It is /bin/bash, the program macOS's privacy control
# has been told may read the home (A31), and names no version and no working
# tree. Run by launchd every five minutes, it first opens a tracked file in the
# home for reading (A31) and, when that fails, writes one unreadable row and runs
# nothing; when it succeeds after an unreadable row, it writes one readable row
# first and goes on. It then reads the version origin/main
# declares (no fetch), and runs that cache entry's `felix land --tick` only when
# main's OWN felix_accepted_deploy_diff, read out of origin/main with git show
# and sourced by bash in a subshell as felix merge's judge block does, says the
# entry is main's engine (A1). A cache entry at main's version number that a
# branch installed is not main's engine, and this check is what tells the two
# apart. In every other case it runs nothing: it writes one deploy-owed row
# naming the case (not again while the ledger's last row says the same, and
# again with when it began each hour it lasts, B15), sends one notification and
# exits 1. It never runs the newest entry, another version or any working tree.
# The one exception (B16) is a home whose own main, strictly behind origin/main,
# has an installed engine that main's check accepts: that engine's tick deploys
# main's, so it is run, and writes its own rows.
_gt_trampoline_body() {
  cat <<'TRAMPOLINE'
cache="${FELIX_PLUGIN_CACHE:-$HOME/.claude/plugins/cache}/felix/felix"
owed() {   # DETAIL [KIND]: say why nothing runs, once an hour, and stop; KIND is deploy-owed unless A31's unreadable
  k="${2:-deploy-owed}"; d="$1"
  # B15: the same wait as the ledger's last row (its kind, and its detail up to the first "; ") is not
  # written again inside the hour, and after it is written with when the run of such rows began.
  w="$(GT_K="$k" GT_D="$d" LC_ALL=C awk -F'\t' -v now="$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
    function ep(t,   a, y, m, e, o, n, c) { split(t, a, /[-T:Z]/); y = a[1] + 0; m = a[2] + 0; if (m <= 2) y--
      e = int(y / 400); o = y - e * 400; n = int((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5) + a[3] - 1
      c = o * 365 + int(o / 4) - int(o / 100) + n; return (e * 146097 + c - 719468) * 86400 + a[4] * 3600 + a[5] * 60 + a[6] }
    function hd(s,   i) { i = index(s, "; "); return i ? substr(s, 1, i - 1) : s }
    { if ($2 == ENVIRON["GT_K"] && hd($7) == hd(ENVIRON["GT_D"])) { if (!r) t0 = $1; r = 1; l = $1 } else r = 0 }
    END { if (!r) print "new"; else if (ep(now) - ep(l) >= 0 && ep(now) - ep(l) < 3600) print "skip"; else print "still " t0 }' "$ledger" 2>/dev/null)"
  case "$w" in still*) tl=""; case "$d" in *"; "*) tl="; ${d#*; }" ;; esac; d="${d%%; *}; still so since ${w#still }$tl" ;; esac
  [ "$w" = skip ] || {
    mkdir -p "$(dirname "$ledger")"
    printf '%s\t%s\t-\t-\t-\t0\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$k" "$d" >> "$ledger"
    osascript -e "display notification \"Felix land: $d\" with title \"Felix: $k\"" >/dev/null 2>&1
  }
  echo "felix land: $d" >&2; exit 1
}
accepts() {   # REF: main's own felix_accepted_deploy_diff on the home and REF, read from origin/main as below; its status, 4 when it cannot be loaded
  local t r
  t="$(mktemp -d "${TMPDIR:-/tmp}/felix-land.XXXXXX" 2>/dev/null)" || return 4
  git show refs/remotes/origin/main:engine/harness/lib/resolve.sh > "$t/resolve.sh" 2>/dev/null || { rm -rf "$t"; return 4; }
  env -u FELIX_KERNEL_CACHE /bin/bash -c '. "$1" >/dev/null 2>&1
    command -v felix_accepted_deploy_diff >/dev/null 2>&1 || exit 3
    felix_accepted_deploy_diff "$2" "$3" >/dev/null 2>&1' felix-land "$t/resolve.sh" "$FELIX_HOME_DIR" "$1"
  r=$?; rm -rf "$t"; return "$r"
}
plugver() { LC_ALL=C sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | LC_ALL=C sed -n 1p; }
handmerge() {   # B16: main's entry is missing; the home's own main, strictly behind origin/main, may deploy it
  local h
  [ "$(git symbolic-ref HEAD 2>/dev/null)" = refs/heads/main ] || return 1
  git merge-base --is-ancestor refs/heads/main refs/remotes/origin/main 2>/dev/null || return 1
  [ "$(git rev-parse refs/heads/main 2>/dev/null)" != "$(git rev-parse refs/remotes/origin/main 2>/dev/null)" ] || return 1
  h="$(git show refs/heads/main:engine/.claude-plugin/plugin.json 2>/dev/null | plugver)"
  [ -n "$h" ] && [ -x "$cache/$h/harness/felix" ] || return 1
  accepts refs/heads/main || return 1
  echo "felix land: main's engine $ver is not installed under $cache, and the home's main is behind origin/main with its own engine $h installed and accepted: $h's felix land --tick deploys $ver" >&2
  exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE "$cache/$h/harness/felix" land --tick
}
cd "$FELIX_HOME_DIR" 2>/dev/null || owed "the trampoline cannot enter FELIX_HOME_DIR ($FELIX_HOME_DIR), so no engine is run"
# A31: entering a directory is not a read. Before anything else, and with no fork, open a file
# tracked in every Felix home and read a byte of it: macOS's privacy control refuses the open,
# which [ -r ] does not see. A file the open reached and found empty is no refusal.
px=engine/.claude-plugin/plugin.json
{ IFS= read -r -d '' -n 1 rb || { [ -f "$px" ] && [ ! -s "$px" ]; }; } 2>/dev/null < "$px" \
  || owed "the trampoline cannot read FELIX_HOME_DIR ($FELIX_HOME_DIR): reading a byte of $px failed, so no engine is run. macOS may be refusing the read: /bin/bash needs Full Disk Access (System Settings > Privacy & Security > Full Disk Access)" unreadable
# A31, recovery: a read that succeeds while the ledger's newest row says it failed is written down once,
# as a row of kind readable and no notification, and the trampoline goes on. Only the newest row counts.
if [ "$(tail -n 1 "$ledger" 2>/dev/null | LC_ALL=C cut -f2)" = unreadable ]; then
  printf '%s\treadable\t-\t-\t-\t0\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "the trampoline read FELIX_HOME_DIR ($FELIX_HOME_DIR) again: reading a byte of $px worked, so the trampoline goes on to its other checks" >> "$ledger" 2>/dev/null
fi
# A24: an untracked .gitignore under engine/ would widen what the check below calls residue.
un="$(git ls-files --others -- engine 2>/dev/null)" || owed "git could not list the home's untracked files under engine/, so no engine is run"
[ -z "$un" ] || owed "the home holds an untracked or ignored file under engine/ ($(printf '%s\n' "$un" | LC_ALL=C sed -n 1p)): nothing runs until it is removed"
pj="$(git show refs/remotes/origin/main:engine/.claude-plugin/plugin.json 2>/dev/null)" \
  || owed "git could not read origin/main's engine version, so no engine is run"
ver="$(printf '%s\n' "$pj" | plugver)"
[ -n "$ver" ] || owed "origin/main declares no readable engine version, so no engine is run"
entry="$cache/$ver"
[ -e "$entry/harness/felix" ] || { handmerge; owed "main's engine $ver is not installed under $cache: nothing runs until it is deployed from the home"; }
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
  1) owed "the cache entry for main's $ver differs from origin/main's engine, so it is not main's engine, and felix install does not replace an entry that exists, so $entry stays as it is: nothing runs" ;;
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
    printf '#!/bin/bash\n# Written by felix land --install; felix land --uninstall removes it.\n'
    printf ': "${FELIX_HOME_DIR:=%s}"\nexport FELIX_HOME_DIR\nFELIX_HOME="$FELIX_HOME_DIR"; export FELIX_HOME\n' "$(_gt_sq "$FELIX_HOME_DIR")"
    printf 'ledger=%s\nFELIX_LAND_LEDGER="$ledger"; export FELIX_LAND_LEDGER\n' "$(_gt_sq "$_GT_LEDGER")"
    _gt_trampoline_body
  } > "$tr" && chmod +x "$tr" || die "could not write $tr"
  {
    printf '<?xml version="1.0" encoding="UTF-8"?>\n'
    printf '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n'
    printf '<plist version="1.0">\n<dict>\n'
    printf '  <key>Label</key><string>felix.land.%s</string>\n' "$(_gt_xml "$p")"
    printf '  <key>ProgramArguments</key><array><string>/bin/bash</string><string>%s</string></array>\n' "$(_gt_xml "$tr")"
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
  _gt_row installed - - - 0 "the job is armed: $plist; $(_gt_by)"   # B24
  printf 'land on green is installed for %s: %s\n' "$p" "$plist"
}

_gt_uninstall() {
  local p; p="$(basename "$PROJ")"
  launchctl bootout "gui/$(id -u)/felix.land.$p" >/dev/null 2>&1 || true
  rm -f "$HOME/Library/LaunchAgents/felix.land.$p.plist" "$HOME/Library/Application Support/felix/land/$p/tick"
  rmdir "$HOME/Library/Application Support/felix/land/$p" 2>/dev/null || true
  _gt_row uninstalled - - - 0 "the job is disarmed: nothing lands unattended until felix land --install; $(_gt_by)"   # B25
  printf 'land on green is uninstalled for %s\n' "$p"
}

# installed, loaded and paused for project name $1 whose land directory is $2,
# read-only, in _GT_INS, _GT_LOD and _GT_PAU. felix land --status and --prs both
# read them here, so the two cannot drift.
_gt_job_state() {   # NAME LANDDIR
  _GT_INS=no; _GT_LOD=no; _GT_PAU=no
  [ -f "$HOME/Library/LaunchAgents/felix.land.$1.plist" ] && _GT_INS=yes
  launchctl print "gui/$(id -u)/felix.land.$1" >/dev/null 2>&1 && _GT_LOD=yes
  [ -e "$2/paused" ] && _GT_PAU=yes
  return 0
}

# The ledger $1's newest row of any kind, whole, in _GT_LAST; empty when the
# file is absent or holds no row. felix land --status (A31) and --prs (R11)
# both read it here, so the two cannot drift.
_gt_last_row() {   # LEDGER
  _GT_LAST=""
  [ -f "$1" ] && _GT_LAST="$(LC_ALL=C tail -n 1 "$1" 2>/dev/null)"
  return 0
}

_gt_status() {   # [--tsv]: read-only, writes nothing and loads nothing
  local p tab; p="$(basename "$PROJ")"; tab="$(printf '\t')"
  local ins lod pau rows="" last=""
  _gt_job_state "$p" "$_GT_LAND"; ins="$_GT_INS"; lod="$_GT_LOD"; pau="$_GT_PAU"
  # A31: the newest row of any kind, so a job that cannot run shows at the next status.
  _gt_last_row "$_GT_LEDGER"; last="$_GT_LAST"
  # The last row of each pull request seen, in pull request order.
  [ -f "$_GT_LEDGER" ] && rows="$(LC_ALL=C awk -F'\t' '$3 != "-" { last[$3] = $0 } END { for (k in last) print last[k] }' "$_GT_LEDGER" \
                                   | LC_ALL=C sort -t "$tab" -k3,3n)"
  if [ "${1:-}" = "--tsv" ]; then
    printf 'installed\t%s\nloaded\t%s\npaused\t%s\nlast\t%s\n' "$ins" "$lod" "$pau" "${last:-none}"
    [ -z "$rows" ] || printf '%s\n' "$rows"
  else
    printf 'installed  %s\nloaded     %s\npaused     %s\n' "$ins" "$lod" "$pau"
    if [ -n "$last" ]; then printf '%s\n' "$last" | LC_ALL=C awk -F'\t' '{ printf "last       %s  %-19s  %s\n", $1, $2, $7 }'
    else printf 'last       none\n'; fi
    [ -z "$rows" ] || printf '%s\n' "$rows" | LC_ALL=C awk -F'\t' '{ printf "#%-5s %-19s %-8s %s  %s\n", $3, $2, substr($4, 1, 7), $1, $7 }'
  fi
}

