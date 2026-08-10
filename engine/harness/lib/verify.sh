# Verification receipts.
#
# The guidebook's central rule is that an agent must never declare a task
# complete while a required deterministic verification step is failing. Felix
# has had the verification step since the beginning; what it lacked was anything
# that noticed when the step had not run. `felix gate` was a command an agent
# could simply not choose.
#
# The mechanism is a receipt rather than a re-run. Re-running the gate at the
# moment someone tries to finish would cost a full test suite every time, which
# on a real project means the hook gets removed, and a removed hook enforces
# nothing. A receipt costs a diff and two small files.
#
# A receipt also answers the question a re-run cannot. Re-running says "the gate
# passes now". The receipt says "this exact tree has been verified", which is a
# different claim, and the common failure is not a red gate but a gate nobody
# ran. A re-run silently converts that failure into a pass.
#
# Dependencies stay bash and git. `git hash-object --stdin` is used rather than
# shasum or sha1sum because those differ across platforms and git is already
# required.

FELIX_UNTRACKED_CAP="${FELIX_UNTRACKED_CAP:-500}"

_felix_hash() { git hash-object --stdin 2>/dev/null; }

_felix_now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# Size and mtime for one file, portably.
#
# GNU must be probed first. `stat -f` on GNU means --file-system, so it succeeds
# with entirely unrelated output rather than failing, and a BSD-first probe would
# silently return filesystem statistics for every file on Linux.
_FELIX_STAT=""
_felix_stat_mode() {
  [ -n "$_FELIX_STAT" ] && return 0
  if stat -c '%s' /dev/null >/dev/null 2>&1; then _FELIX_STAT=gnu
  elif stat -f '%z' /dev/null >/dev/null 2>&1; then _FELIX_STAT=bsd
  else _FELIX_STAT=none; fi
}
_felix_meta() {
  _felix_stat_mode
  case "$_FELIX_STAT" in
    gnu) stat -c '%s %Y' "$1" 2>/dev/null ;;
    bsd) stat -f '%z %m' "$1" 2>/dev/null ;;
    *)   printf 'nostat' ;;
  esac
}

# Does this tree hold anything the gate has not seen committed?
felix_tree_dirty() {
  local root="$1"
  git -C "$root" rev-parse --git-dir >/dev/null 2>&1 || return 1
  [ -n "$(git -C "$root" status --porcelain 2>/dev/null)" ]
}

# Identity of a working tree: the commit it sits on, the content of every
# uncommitted change, and the presence of every untracked file.
#
# `git status --porcelain` alone was rejected. Two different edits to the same
# file produce byte-identical status output, so a receipt keyed on it stays valid
# across a change it never saw. The diff content has to be in the hash.
#
# Untracked file *contents* are deliberately not hashed. Felix governs projects
# in languages it does not know, and an untracked directory in one of them may be
# a virtualenv, a build output, or a multi-gigabyte model artifact. Hashing bytes
# would make this hook's cost a function of somebody else's project layout. Size
# and mtime both change on any write, which is sufficient, and cost one stat.
felix_tree_id() {
  local root="$1" head diff untracked n meta="" prefix="" f
  git -C "$root" rev-parse --git-dir >/dev/null 2>&1 || return 1

  head="$(git -C "$root" rev-parse HEAD 2>/dev/null)" || head=""
  if [ -z "$head" ]; then
    # An unborn HEAD has nothing to diff against. A repository with no commits is
    # a real state — it is what `git init` leaves, and what this suite's own
    # fixture is — and every naive implementation of this dies there.
    head="unborn"
    diff="$(git -C "$root" diff 2>/dev/null)"
  else
    diff="$(git -C "$root" diff HEAD 2>/dev/null)"
  fi

  untracked="$(git -C "$root" ls-files --others --exclude-standard 2>/dev/null | LC_ALL=C sort)"
  n="$(printf '%s' "$untracked" | grep -c . 2>/dev/null)" || n=0

  if [ "${n:-0}" -gt "$FELIX_UNTRACKED_CAP" ]; then
    # A repository in this state has larger problems than receipt precision, and
    # the hook has to stay fast whatever it is handed.
    prefix="coarse:"
    meta="$n untracked"
  else
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      meta="$meta
$f $(_felix_meta "$root/$f")"
    done <<EOF
$untracked
EOF
  fi

  printf '%s%s' "$prefix" \
    "$(printf '%s\n%s\n%s' "$head" "$diff" "$meta" | _felix_hash)"
}

# One receipt per repository, overwritten each run. History of decisions lives in
# the verification log; the receipt only answers "what was verified last".
_felix_receipt_path() {
  printf '%s/state/gate/%s' "$2" "$(printf '%s' "$1" | _felix_hash)"
}

# Called by the gate. Failure to write is never fatal: a gate that cannot record
# its own result is still a gate, and refusing to run would be a worse trade.
felix_verify_record() {
  local root="$1" home="$2" rc="$3" gate="$4" tid="$5" path result
  [ -n "$tid" ] || return 0
  path="$(_felix_receipt_path "$root" "$home")"
  mkdir -p "$(dirname "$path")" 2>/dev/null || return 0
  result=green; [ "$rc" -eq 0 ] || result=red
  printf '%s\t%s\t%s\t%s\n' "$tid" "$result" "$(_felix_now)" "$gate" \
    > "$path" 2>/dev/null || true
}

felix_verify_receipt() { cat "$(_felix_receipt_path "$1" "$2")" 2>/dev/null; }

# Every decision, allowed or refused, appended and committed. Nothing else in
# Claude Code records whether verification passed: transcripts carry is_error on
# tool results and Bash results carry no exit code at all. This file is the only
# place the fact exists.
felix_verify_log() {
  local proj="$1" verdict="$2" tid="$3" reason="$4"
  [ -d "$proj/memory" ] || return 0
  printf '%s\t%s\t%s\t%s\n' "$(_felix_now)" "$verdict" "${tid:-none}" "$reason" \
    >> "$proj/memory/verification.log" 2>/dev/null || true
}
