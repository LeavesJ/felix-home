# felix situations, the readings (slice 1 of the capability lane; contracts C3.1 to C3.4 of
# docs/2026-10-29-lane-slice-1-plan.md). Loaded by cmd_situations in felix, after lib/situations.sh. Definitions only.
#
# ONE SIDE READ. A side is read into a reading file, one per side, inside the run's scratch directory. Its lines are
# tab-separated and each is named by its first cell; only the order of the probe lines matters, they are in reading order:
#
#   how      recorded|scratch
#   commit   <sha40>|-
#   tree     <tree id>
#   stamp    <stamp>|-
#   detector run|not-run
#   cap      <capability>            zero or more, the detector's names, sorted and unique, present only when it ran
#   probe    <pred> <grounds> <state> <count> <detail>|-
#
# THE RECORDED READING (--at, C3.1) comes from facts.log under the project's memory root, read and never written. THE
# SCRATCH READING (--change, C3.3) comes from a shared clone of the repository's common git directory, checked out detached
# at one commit and removed with the scratch directory.
#
# THE SCRATCH DIRECTORY (C3.3). One per run, made under ${TMPDIR:-/tmp}, in both modes. Every reading and evaluation file
# the run writes lives in it. It is removed before the report is printed, on every exit after it was made, and on TERM,
# HUP and INT, which then exit 143, 129 and 130. Its path is the global _FELIX_SITUATIONS_SCRATCH, set empty before any
# trap is installed, because a trap body is read when it fires and a local is gone by then (felix_discover's precedent).

# Sets _FELIX_SITUATIONS_ME to the pid of the process that runs this, which a subshell's own differs from its parent's: the
# parent of a shell that has exec'd sh is the process that forked it. bash 3.2 has no BASHPID, and neither $$ nor
# BASH_SUBSHELL tells a subshell apart. It sets a global and is never called inside a substitution of its own, since that
# would make the substitution's process the answer.
_felix_situations_self() {
  _FELIX_SITUATIONS_ME="$(exec /bin/sh -c 'echo "$PPID"')"
}

# The directory, removed. Written for a trap: it reads the global, tolerates it unset or empty, and does nothing twice. It
# acts only in the process that made the directory: a child of that process that bash 5.2 has forked but not yet given
# its own traps runs this trap too when a signal reaches it, and must not remove what the run still stands on.
felix_situations_scratch_remove() {
  local d="${_FELIX_SITUATIONS_SCRATCH:-}"
  [ -n "$d" ] || return 0
  _felix_situations_self
  [ "$_FELIX_SITUATIONS_ME" = "${_FELIX_SITUATIONS_OWNER:-}" ] || return 0
  rm -rf "$d" 2>/dev/null
  _FELIX_SITUATIONS_SCRATCH=""
  return 0
}

# Makes the scratch directory with its traps installed first: EXIT removes it, and TERM, HUP and INT remove it and exit 143,
# 129 and 130. Returns 0, or 3 with C2's scratch-directory sentence on stderr and no directory made. <tmpdir> in the
# sentence is ${TMPDIR:-/tmp} as given.
felix_situations_scratch_begin() {
  local tmp="${TMPDIR:-/tmp}" d
  _FELIX_SITUATIONS_SCRATCH=""
  _felix_situations_self
  _FELIX_SITUATIONS_OWNER="$_FELIX_SITUATIONS_ME"
  trap 'felix_situations_scratch_remove' EXIT
  trap 'felix_situations_scratch_remove; exit 143' TERM
  trap 'felix_situations_scratch_remove; exit 129' HUP
  trap 'felix_situations_scratch_remove; exit 130' INT
  d="$(mktemp -d "${TMPDIR:-/tmp}/felix-situations.XXXXXX" 2>/dev/null)" || d=""
  if [ -z "$d" ] || [ ! -d "$d" ]; then
    printf 'felix situations: the scratch directory could not be made: mktemp -d failed under %s\n' "$tmp" >&2
    return 3
  fi
  _FELIX_SITUATIONS_SCRATCH="$d"
  return 0
}

# The directory removed, and the traps put back. Called before the report is printed.
felix_situations_scratch_end() {
  felix_situations_scratch_remove
  trap - EXIT TERM HUP INT
  return 0
}

# The newest recorded tree of a facts.log (C3.1): the tree field of the last line, in file order, that has 8 or more
# fields and whose tree is not unknown-tree (an empty tree field names no tree and is passed over). Prints it. Returns 3,
# printing nothing, when the log is absent, unreadable, empty, or records no tree.
felix_situations_newest_tree() {   # LOG
  local log="${1-}" t
  [ -f "$log" ] && [ -r "$log" ] || return 3
  t="$(LC_ALL=C awk -F'\t' 'NF >= 8 && $2 != "unknown-tree" && $2 != "" { t = $2 "" } END { print t }' "$log")" || return 3
  [ -n "$t" ] || return 3
  printf '%s' "$t"
}

# The recorded reading of one tree (C3.1), written to OUT as the first lines of a reading file: how, tree, stamp, then one
# probe line per predicate of the run. The run is decided by the last line, in file order, that has 8 or more fields and
# names TREE: its stamp and the tree name the run, whose rows are every such line with that stamp and tree. An older run
# of the same tree is never read, a predicate that appears more than once in the run is read from its first line, and
# unknown-tree is never a tree. A line with fewer than 8 fields is ignored, and columns 4, 8 and 9 are not read. The probe's
# own sentence is not in the log, so each probe line's detail is - (C10 gives its reason). Returns 3 when no run is
# recorded for TREE, with OUT unwritten.
felix_situations_read_recorded() {   # LOG TREE OUT
  local log="${1-}" tree="${2-}" out="${3-}" body
  [ -f "$log" ] && [ -r "$log" ] || return 3
  body="$(FELIX_SITUATIONS_TREE="$tree" LC_ALL=C awk -F'\t' '
    BEGIN { want = ENVIRON["FELIX_SITUATIONS_TREE"] "" }
    NF >= 8 && ($2 "") == want && want != "unknown-tree" && want != "" {
      n++; STAMP[n] = $1 ""; PRED[n] = $3 ""; GRND[n] = $7 ""; STATE[n] = $5 ""; COUNT[n] = $6 ""
    }
    END {
      if (n == 0) exit 3
      run = STAMP[n]
      printf "stamp\t%s\n", run
      for (i = 1; i <= n; i++) {
        if (STAMP[i] != run || (PRED[i] in SEEN)) continue
        SEEN[PRED[i]] = 1
        printf "probe\t%s\t%s\t%s\t%s\t-\n", PRED[i], GRND[i], STATE[i], COUNT[i]
      }
    }' "$log")" || return 3
  [ -n "$body" ] || return 3
  { printf 'how\trecorded\n'; printf 'tree\t%s\n' "$tree"; printf '%s\n' "$body"; } > "$out" 2>/dev/null || return 3
  return 0
}

# A revision resolved to a commit id in the live repository, printed whole; status 1 and nothing printed when it names no
# commit here. A revision that begins with - is not one, so git never reads it as an option.
_felix_situations_rev() {   # ROOT REV
  local root="${1-}" rev="${2-}" sha
  case "$rev" in ''|-*) return 1 ;; esac
  sha="$(_felix_git_rules "$root" rev-parse --verify --quiet "${rev}^{commit}" 2>/dev/null)" || return 1
  [ -n "$sha" ] || return 1
  printf '%s' "$sha"
}

# The two ends of a change (C3.3): prints <base commit><TAB><head commit>. A given RANGE is <base>..<head> as C1 splits it,
# and each half is resolved in the live repository to a commit, the base first. Returns 3 with C2's sentence on stderr
# (<rev> is the half as given) when a half names no commit:
#   felix situations: base could not be read: <rev> is not a commit here      (and the same with head)
# Only a given range is read here. The default range, from the main ref's merge base to HEAD, comes with the scratch readings.
felix_situations_range() {   # ROOT RANGE
  local root="${1-}" r="${2-}" b h bs hs
  b="${r%%..*}"; h="${r#*..}"
  if ! bs="$(_felix_situations_rev "$root" "$b")"; then
    printf 'felix situations: base could not be read: %s is not a commit here\n' "$b" >&2
    return 3
  fi
  if ! hs="$(_felix_situations_rev "$root" "$h")"; then
    printf 'felix situations: head could not be read: %s is not a commit here\n' "$h" >&2
    return 3
  fi
  printf '%s\t%s\n' "$bs" "$hs"
}
