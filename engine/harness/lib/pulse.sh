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
# The review of the first version confirmed ten ways an unattended committer
# can corrupt the thing it protects, each by construction, and the guards
# below are those findings inverted: never conclude a person's merge, never
# commit a repository that is not the memory's own, never commit onto a
# detached HEAD, never record a nested repository as an empty gitlink, never
# pick a push target by alphabetical accident. Every refusal is a printed
# sentence and exit 0 — for a heartbeat, an honest "not safe to act" is a
# successful run.
#
# Scheduling is a grant, not a default. `felix pulse --install` writes the
# launchd agent and a person runs that command; nothing here schedules
# itself, because a permission a system grants itself is not a permission.

# The git repository holding the memory root. Emits nothing when no repo
# encloses it; the toplevel when that repository is the memory's own — the
# root itself, or its immediate parent, which is the documented ~/.felix
# layout; and `foreign<TAB>toplevel` when the nearest repository is anything
# deeper — a dotfiles repo tracking $HOME is the realistic case, and running
# `git add -A` at that toplevel would commit and publish everything the
# founder owns, daily.
felix_pulse_mem_repo() {
  local home="${1:-}" root top
  root="$(cd "$(felix_mem_root)" 2>/dev/null && pwd -P)" || return 0
  [ -n "$root" ] || return 0
  top="$(git -C "$root" rev-parse --show-toplevel 2>/dev/null)" || return 0
  [ -n "$top" ] || return 0
  top="$(cd "$top" 2>/dev/null && pwd -P)"

  # The memory's own repository, or a repository Felix established. Nothing
  # else — and "the immediate parent" was not that test. FELIX_MEMORY is the
  # one documented knob, so pointing it at a subdirectory of somebody's notes
  # vault made that vault the backup repository, `git add -A` and all. A
  # parent qualifies only when it is the Felix home this run resolved, which
  # is a directory Felix created for exactly this.
  [ -n "$home" ] && home="$(cd "$home" 2>/dev/null && pwd -P)"
  if [ "$top" = "$root" ] || { [ -n "$home" ] && [ "$top" = "$home" ]; }; then
    printf '%s' "$top"
  else
    printf 'foreign\t%s' "$top"
  fi
}

# Paths staged as gitlinks that HEAD does not already carry, and that
# .gitmodules does not declare. Emits one path per line; empty is the good
# answer.
#
# Both halves were wrong before. Testing `[ ! -f .gitmodules ]` asked whether
# the file exists rather than whether THIS link is declared in it, so one
# legitimate submodule — or the remedy the refusal message itself recommends
# — switched the guard off for every other nested repository forever. And
# counting every gitlink in the index counted the ones already in HEAD, so a
# nested repo committed once, before this guard existed, refused every future
# backup permanently. Only what this run would newly introduce is a decision.
_felix_pulse_new_gitlinks() {
  local repo="$1" declared idx head
  idx="$(git -C "$repo" ls-files -s 2>/dev/null | awk '$1 == "160000" { $1=$2=$3=""; sub(/^[ \t]+/, ""); print }')"
  [ -n "$idx" ] || return 0
  head="$(git -C "$repo" ls-tree -r HEAD 2>/dev/null | awk '$1 == "160000" { $1=$2=$3=""; sub(/^[ \t]+/, ""); print }')"
  declared="$(git -C "$repo" config -f "$repo/.gitmodules" --get-regexp '^submodule\..*\.path$' 2>/dev/null \
              | sed 's/^[^ ]* //')"
  printf '%s\n' "$idx" | while IFS= read -r p; do
    [ -n "$p" ] || continue
    felix_has_line "$head" "$p" && continue
    felix_has_line "$declared" "$p" && continue
    printf '%s\n' "$p"
  done
}

# Commit if dirty, push if a target is unambiguous, then verify by re-reading
# the remote head. Emits status lines and always returns 0: an honest
# "nothing to do" is not a failure, and neither is a refusal this
# deliberately makes.
felix_pulse_backup() {
  local repo="$1" gitdir remotes remote branch local_head remote_head n160 n_remotes
  if [ -z "$repo" ]; then
    printf 'backup\tmemory is not in a git repository; nothing versions it\n'
    return 0
  fi
  case "$repo" in
    "foreign	"*)
      printf 'backup\tmemory sits inside a repository that is not its own (%s); not touching it\n' \
        "${repo#foreign	}"
      return 0 ;;
  esac

  # A merge or rebase in progress is a person's work-site. `git add -A` would
  # stage their conflict markers as resolved and `commit` would conclude
  # their merge under this machine's name — then push it as a fast-forward
  # the divergence guard below can never catch, because the machine-made
  # merge contains the remote head. Constructed in review; never again.
  # The index is the fact, and the state files are only a symptom of it.
  # Checking the five files alone let `git merge --squash`, `git cherry-pick
  # -n` and `git stash pop` conflicts through — all three leave unmerged
  # entries and write no state file — and `git add -A` then resolves an
  # unmerged path to whatever the worktree holds, which is the conflict
  # markers. The push that followed reported "verified", and because local
  # and remote then agreed, no later run could ever notice.
  if [ "$(git -C "$repo" ls-files -u 2>/dev/null | grep -c .)" -gt 0 ]; then
    printf 'backup\tunresolved conflicts are staged here; that is a person mid-reconciliation, and nothing here touches it\n'
    return 0
  fi
  # Kept beside it: an in-progress operation that has not conflicted YET
  # leaves a state file and an ordinary index, and concluding somebody's
  # rebase under this machine's name is its own harm.
  gitdir="$(git -C "$repo" rev-parse --git-dir 2>/dev/null)"
  case "$gitdir" in /*) ;; *) gitdir="$repo/$gitdir" ;; esac
  if [ -f "$gitdir/MERGE_HEAD" ] || [ -f "$gitdir/CHERRY_PICK_HEAD" ] \
     || [ -f "$gitdir/REVERT_HEAD" ] || [ -f "$gitdir/SQUASH_MSG" ] \
     || [ -d "$gitdir/rebase-merge" ] || [ -d "$gitdir/rebase-apply" ]; then
    printf 'backup\ta merge or rebase is in progress; that is a person mid-reconciliation, and nothing here touches it\n'
    return 0
  fi

  # Detached HEAD is a person inspecting history. A commit here lands on no
  # branch, and the next ordinary checkout strands it.
  branch="$(git -C "$repo" symbolic-ref --short HEAD 2>/dev/null)" || branch=""
  if [ -z "$branch" ]; then
    printf 'backup\tHEAD is detached; a commit would land on no branch, so nothing was committed\n'
    return 0
  fi

  if [ -n "$(git -C "$repo" status --porcelain 2>/dev/null)" ]; then
    git -C "$repo" add -A >/dev/null 2>&1
    # A nested git repository stages as a bare gitlink: the push then reports
    # verified while a restore materializes an empty directory — the exact
    # disaster-recovery path this feature exists for. Counted with grep -c,
    # which reads its whole input, because grep -q under pipefail kills the
    # producer and this repository has paid for that before. A repository
    # with .gitmodules declared its links on purpose and is left alone.
    # Named before the reset, not after: the reset is what removes the entry
    # the name comes from, so asking afterwards printed an empty path and the
    # message named nothing at all.
    local links; links="$(_felix_pulse_new_gitlinks "$repo")"
    if [ "$(printf '%s\n' "$links" | grep -c .)" -gt 0 ]; then
      git -C "$repo" reset -q >/dev/null 2>&1
      printf 'backup\ta nested git repository sits inside memory (%s); backed up it would restore EMPTY, so nothing was committed — move it out, or declare it in .gitmodules\n' \
        "$(printf '%s\n' "$links" | tr '\n' ' ' | sed 's/ $//')"
      return 0
    fi
    if git -C "$repo" -c user.name=felix-pulse -c user.email=pulse@felix.invalid \
         commit -q -m "pulse: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >/dev/null 2>&1; then
      printf 'backup\tcommitted\n'
    else
      # Returns rather than falling through. It used to push anyway: the push
      # succeeded because there was nothing new to send, the verification
      # passed because both heads were the stale one, and the run's LAST
      # line — the one a person skims — read "pushed and verified". A backup
      # that has silently stopped must not end on a success sentence.
      printf 'backup\tcommit FAILED; nothing was pushed, and this memory is NOT backed up\n'
      return 0
    fi
  else
    printf 'backup\tnothing new to commit\n'
  fi

  # The push target, never by alphabetical accident: the branch's own
  # upstream first, then origin, then the only remote there is. Two remotes
  # and no upstream is a person's ambiguity — `git remote | head -1` pushed
  # to whichever name sorted first and then verified that same wrong remote.
  remotes="$(git -C "$repo" remote 2>/dev/null)"
  remote="$(git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null)"
  remote="${remote%%/*}"
  if [ -z "$remote" ]; then
    if felix_has_line "$remotes" origin; then
      remote=origin
    else
      n_remotes="$(printf '%s\n' "$remotes" | grep -c .)"
      if [ "${n_remotes:-0}" -eq 1 ]; then
        remote="$remotes"
      elif [ "${n_remotes:-0}" -eq 0 ]; then
        printf 'backup\tno remote; the backup is this disk and only this disk\n'
        return 0
      else
        printf 'backup\t%s remotes and no upstream; a person picks where this pushes\n' "$n_remotes"
        return 0
      fi
    fi
  fi

  # Bounded the ways git can be bounded without a watchdog binary: http gets
  # a low-speed floor, ssh gets connect and keepalive caps. The documented
  # layout — a bare remote on this disk — cannot hang at all. What none of
  # this can bound is a transport streaming one byte a minute; launchd runs
  # the next pulse regardless.
  if git -C "$repo" \
       -c http.lowSpeedLimit=1 -c http.lowSpeedTime=30 \
       -c core.sshCommand="ssh -o ConnectTimeout=15 -o ServerAliveInterval=20 -o ServerAliveCountMax=3" \
       push -q "$remote" "$branch" >/dev/null 2>&1; then
    # Pushed is a claim; verified is a fact. Ask the remote what it holds
    # rather than trusting the exit status — a backup believed and absent is
    # worse than none, which is why the first one was restored before it was
    # believed.
    local_head="$(git -C "$repo" rev-parse HEAD 2>/dev/null)"
    remote_head="$(git -C "$repo" \
       -c http.lowSpeedLimit=1 -c http.lowSpeedTime=30 \
       -c core.sshCommand="ssh -o ConnectTimeout=15 -o ServerAliveInterval=20 -o ServerAliveCountMax=3" \
       ls-remote "$remote" "refs/heads/$branch" 2>/dev/null | cut -f1)"
    if [ -n "$local_head" ] && [ "$local_head" = "$remote_head" ]; then
      printf 'backup\tpushed and verified: %s holds %.12s\n' "$remote" "$local_head"
    else
      printf 'backup\tpushed, but %s reads back %.12s against local %.12s\n' \
        "$remote" "${remote_head:-nothing}" "$local_head"
    fi
  else
    printf 'backup\tpush failed — unreachable, or diverged; nothing was forced, and a divergence is a person'\''s to reconcile\n'
  fi
  return 0
}

# Days since the memory repository last committed, empty when there is no
# repository to ask.
#
# Every refusal above is honest and invisible: it prints into a log file
# nobody opens, and a heartbeat that has refused for ninety days looks
# exactly like one that ran. This is the number that makes a silent stop
# observable, and the session hook is where a person actually reads.
felix_pulse_backup_age() {
  local repo="$1" last now
  case "${repo:-}" in ''|"foreign	"*) return 0 ;; esac
  last="$(git -C "$repo" log -1 --format=%ct 2>/dev/null)"
  [ -n "$last" ] || return 0
  now="$(date +%s)"
  printf '%s' $(( (now - last) / 86400 ))
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

# The launchd agent, emitted rather than written so a test can read it and
# the writer stays four lines. 09:07 local, daily: early enough that the
# first session of a day inherits a fresh backup, odd enough to say a machine
# chose it. launchd's own capture goes to a separate file — the pulse tees
# its structured lines into the log itself, and one line written twice reads
# as two heartbeats. Paths land inside <string> verbatim; the standard
# layouts contain no XML metacharacters, and one that did would break the
# schedule loudly at load, not silently.
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
  <key>StandardOutPath</key><string>$log.launchd.log</string>
  <key>StandardErrorPath</key><string>$log.launchd.log</string>
</dict></plist>
PLIST
}
