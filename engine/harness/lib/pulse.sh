# The pulse: Felix's heartbeat between sessions.
#
# Everything else Felix does runs only when a session happens to start, so the
# memory backup was as current as the last time somebody typed the command —
# measured four days stale once, on the one asset the repository cannot
# rebuild — and the first session of any day paid discovery's staleness. This
# is the piece that runs on a schedule instead: bash and git only, no model,
# no checkout touched, no network beyond the backup remote a person already
# configured.
#
# Duties, deliberately two:
#   backup   commit and push the memory repository, verified by asking the
#            remote what it now holds; a rejected push is reported and never
#            forced, because a divergence is another machine's work and
#            reconciling it is a person's call
#   report   name what is waiting — maintenance due, discovery caches stale —
#            so the pulse log doubles as a note about what the next session
#            will find
#
# Scheduling is a grant, not a default. `felix pulse --install` writes the
# launchd agent and a person runs that command; nothing here schedules
# itself, because a permission a system grants itself is not a permission.

# The git repository holding the memory root, empty when nothing versions it.
felix_pulse_mem_repo() {
  git -C "$(felix_mem_root)" rev-parse --show-toplevel 2>/dev/null
}

# Commit if dirty, push if a remote exists, then verify by re-reading the
# remote head. Emits status lines and always returns 0: an honest "nothing to
# do" is not a failure, and neither is a refusal this deliberately makes.
felix_pulse_backup() {
  local repo="$1" remote branch local_head remote_head
  if [ -z "$repo" ]; then
    printf 'backup\tmemory is not in a git repository; nothing versions it\n'
    return 0
  fi
  if [ -n "$(git -C "$repo" status --porcelain 2>/dev/null)" ]; then
    git -C "$repo" add -A >/dev/null 2>&1
    if git -C "$repo" -c user.name=felix-pulse -c user.email=pulse@felix.invalid \
         commit -q -m "pulse: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >/dev/null 2>&1; then
      printf 'backup\tcommitted\n'
    else
      printf 'backup\tcommit FAILED; the working copy is unchanged\n'
    fi
  else
    printf 'backup\tnothing new to commit\n'
  fi
  remote="$(git -C "$repo" remote 2>/dev/null | head -1)"
  if [ -z "$remote" ]; then
    printf 'backup\tno remote; the backup is this disk and only this disk\n'
    return 0
  fi
  branch="$(git -C "$repo" symbolic-ref --short HEAD 2>/dev/null)" || branch=main
  if git -C "$repo" push -q "$remote" "$branch" >/dev/null 2>&1; then
    # Pushed is a claim; verified is a fact. Ask the remote what it holds
    # rather than trusting the exit status — a backup believed and absent is
    # worse than none, which is why the first one was restored before it was
    # believed.
    local_head="$(git -C "$repo" rev-parse HEAD 2>/dev/null)"
    remote_head="$(git -C "$repo" ls-remote "$remote" "refs/heads/$branch" 2>/dev/null | cut -f1)"
    if [ -n "$local_head" ] && [ "$local_head" = "$remote_head" ]; then
      printf 'backup\tpushed and verified: %s holds %.12s\n' "$remote" "$local_head"
    else
      printf 'backup\tpushed, but %s reads back %.12s against local %.12s\n' \
        "$remote" "${remote_head:-nothing}" "$local_head"
    fi
  else
    printf 'backup\tpush REFUSED, likely diverged; a person reconciles, nothing was forced\n'
  fi
  return 0
}

# What is waiting, one line per fact. Reads only Felix's own tables and state.
felix_pulse_report() {
  local home="$1" proj name due
  for proj in "$home"/projects/*/; do
    proj="${proj%/}"
    [ -f "$proj/project.json" ] || continue
    name="$(basename "$proj")"
    if [ -f "$proj/maintenance.tsv" ]; then
      due="$(felix_maint_status "$proj" 2>/dev/null | grep '^due' | cut -f2 | tr '\n' ' ')"
      due="${due% }"
      [ -n "$due" ] && printf 'due\t%s\t%s\n' "$name" "$due"
    fi
    if [ -f "$proj/routes.tsv" ] && felix_discover_stale "$proj" "$home"; then
      printf 'stale\t%s\tdiscovery cache; the next session refreshes it in the background\n' "$name"
    fi
  done
  return 0
}

# The launchd agent, emitted rather than written so a test can read it and the
# writer stays four lines. 09:07 local, daily: early enough that the first
# session of a day inherits a fresh backup, odd enough to say a machine chose
# it.
felix_pulse_plist() {
  local bin="$1" log="$2"
  cat <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>felix.pulse</string>
  <key>ProgramArguments</key><array>
    <string>$bin</string>
    <string>pulse</string>
  </array>
  <key>StartCalendarInterval</key><dict>
    <key>Hour</key><integer>9</integer>
    <key>Minute</key><integer>7</integer>
  </dict>
  <key>StandardOutPath</key><string>$log</string>
  <key>StandardErrorPath</key><string>$log</string>
</dict></plist>
PLIST
}
