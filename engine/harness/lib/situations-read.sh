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
  # Absolute, so a TMPDIR given relative names the same directory from inside a clone, where the probes run. It is set
  # before anything can fail, so the trap still removes the directory under the name mktemp gave it.
  _FELIX_SITUATIONS_SCRATCH="$d"
  d="$(CDPATH='' cd -P -- "$d" 2>/dev/null && pwd -P)" || d=""
  [ -z "$d" ] || _FELIX_SITUATIONS_SCRATCH="$d"
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

# A string of exactly the digits a full commit id is made of: 40 lowercase hex digits, or 64 under the longer hash.
_felix_situations_fullid() {   # TEXT
  case "${1-}" in *[!0123456789abcdef]*) return 1 ;; esac
  [ "${#1}" -eq 40 ] || [ "${#1}" -eq 64 ]
}

# A revision resolved to a commit id in the live repository, printed whole; status 1 and nothing printed when it names no
# commit here, and so when git resolves it to anything but one full commit id (^HEAD resolves to ^ and the id, C17.7). A
# revision that begins with - is not one, so git never reads it as an option.
_felix_situations_rev() {   # ROOT REV
  local root="${1-}" rev="${2-}" sha
  case "$rev" in ''|-*) return 1 ;; esac
  sha="$(_felix_git_rules "$root" rev-parse --verify --quiet "${rev}^{commit}" 2>/dev/null)" || return 1
  _felix_situations_fullid "$sha" || return 1
  printf '%s' "$sha"
}

# The main ref (C3.3): prints its full name. It is the target of refs/remotes/origin/HEAD when that is a symbolic ref to a
# refs/remotes/origin/<x> that names a commit; otherwise refs/remotes/origin/main when it names a commit; otherwise
# refs/heads/main. Returns 1, printing nothing, when none of the three names a commit.
_felix_situations_mainref() {   # ROOT
  local root="${1-}" t
  t="$(_felix_git_rules "$root" symbolic-ref -q refs/remotes/origin/HEAD 2>/dev/null)" || t=""
  case "$t" in
    refs/remotes/origin/?*)
      if _felix_situations_rev "$root" "$t" >/dev/null; then printf '%s' "$t"; return 0; fi ;;
  esac
  for t in refs/remotes/origin/main refs/heads/main; do
    if _felix_situations_rev "$root" "$t" >/dev/null; then printf '%s' "$t"; return 0; fi
  done
  return 1
}

# The two ends of a change (C3.3): prints <base commit><TAB><head commit>. A given RANGE is <base>..<head> as C1 splits it,
# and each half is resolved in the live repository to a commit, the base first. With no RANGE, the head is HEAD and the base is
# the merge base of the main ref and HEAD. Returns 3 with C2's sentence on stderr (<rev> is the half as given) when a half
# names no commit:
#   felix situations: base could not be read: <rev> is not a commit here      (and the same with head)
# and, with no range, in this order: HEAD is not a commit, no main ref names a commit, or the main ref and HEAD share no merge
# base (the main ref as a full ref name).
felix_situations_range() {   # ROOT [RANGE]
  local root="${1-}" r="${2-}" b h bs hs ref
  if [ -z "$r" ]; then
    if ! hs="$(_felix_situations_rev "$root" HEAD)"; then
      printf 'felix situations: head could not be read: HEAD is not a commit here\n' >&2
      return 3
    fi
    if ! ref="$(_felix_situations_mainref "$root")"; then
      printf 'felix situations: the change could not be read: no main ref here: neither refs/remotes/origin/HEAD, refs/remotes/origin/main nor refs/heads/main names a commit\n' >&2
      return 3
    fi
    bs="$(_felix_git_rules "$root" merge-base "$ref" "$hs" 2>/dev/null)" || bs=""
    if [ -z "$bs" ]; then
      printf 'felix situations: the change could not be read: %s and HEAD share no merge base\n' "$ref" >&2
      return 3
    fi
    printf '%s\t%s\n' "$bs" "$hs"
    return 0
  fi
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

# The repository's common git directory, absolute, which a linked worktree and a main checkout share: the source every scratch
# clone is made from (C3.3). Returns 1, printing nothing, when ROOT is no repository.
felix_situations_gitdir() {   # ROOT
  local root="${1-}" g
  g="$(_felix_git_rules "$root" rev-parse --git-common-dir 2>/dev/null)" || return 1
  [ -n "$g" ] || return 1
  case "$g" in /*) ;; *) g="$root/$g" ;; esac
  ( CDPATH='' cd -P -- "$g" 2>/dev/null && pwd -P )
}

# The detector at a recorded tree (C3.2), appended to OUT as the commit, detector and cap lines of the reading. It runs on the
# live checkout ROOT only when that checkout's tree id, taken as felix probes takes it, equals TREE. Then the commit is the live
# HEAD, or - while HEAD is unborn, and the cap lines are what the detector names, sorted and unique. Otherwise the detector is
# not run, the commit is -, and there is no cap line. Returns 3 when OUT cannot be written.
felix_situations_live_detect() {   # ROOT HOME TREE OUT
  local root="${1-}" home="${2-}" tree="${3-}" out="${4-}" live sha caps c
  live="$(felix_tree_id "$root" "$home" 2>/dev/null)" || live=""
  if [ -n "$live" ] && [ "$live" = "$tree" ]; then
    sha="$(_felix_situations_rev "$root" HEAD)" || sha="-"
    caps="$(felix_detect "$root" 2>/dev/null | LC_ALL=C sort -u)"
    {
      printf 'commit\t%s\ndetector\trun\n' "$sha"
      while IFS= read -r c; do
        [ -z "$c" ] || printf 'cap\t%s\n' "$c"
      done <<EOF2
$caps
EOF2
    } >> "$out" 2>/dev/null || return 3
  else
    printf 'commit\t-\ndetector\tnot-run\n' >> "$out" 2>/dev/null || return 3
  fi
  return 0
}

# One side read in a scratch clone (C3.3), written to OUT as a reading file with how scratch: SIDE is base or head, SHA the
# commit, SRC the repository's common git directory (absolute). The clone is made under the scratch directory at <scratch>/SIDE,
# shared with SRC and with no checkout and no template, then checked out detached at SHA, both through _felix_git_rules (no
# global or system git config, so no hook, template, filter driver or lazy fetch of the caller's runs) with GIT_NO_LAZY_FETCH
# and stdin from /dev/null. The tree id is taken right after the checkout and before anything runs in the clone. Then the
# detector and every row of the project's current probes.tsv run in the clone, with TMPDIR set to <scratch>/tmp-SIDE and none
# of the environment that points git at another repository. The live checkout's edits and untracked files are read by neither
# side, since the clone holds tracked content only. Returns 3 with C2's sentence on stderr when the clone, the checkout or the
# tree id fails.
felix_situations_read_scratch() {   # PROJ HOME SRC SHA SIDE OUT
  local proj="${1-}" home="${2-}" src="${3-}" sha="${4-}" side="${5-}" out="${6-}"
  local scr="${_FELIX_SITUATIONS_SCRATCH:-}" clone tmp tid caps c
  clone="$scr/$side"; tmp="$scr/tmp-$side"
  if [ -z "$scr" ] || [ -z "$src" ] \
     || ! mkdir -p "$tmp" 2>/dev/null \
     || ! GIT_NO_LAZY_FETCH=1 _felix_git_rules "$scr" clone -q --shared --no-checkout --template= -- "$src" "$clone" >/dev/null 2>&1 \
     || ! GIT_NO_LAZY_FETCH=1 _felix_git_rules "$clone" checkout --detach -q "$sha" >/dev/null 2>&1; then
    printf 'felix situations: %s could not be read: the scratch checkout of %s could not be made\n' "$side" "$sha" >&2
    return 3
  fi
  tid="$( unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR
          export HOME="$scr" XDG_CONFIG_HOME="$scr" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
          felix_tree_id_on "$clone" "$sha" "$home" 2>/dev/null )" || tid=""
  if [ -z "$tid" ]; then
    printf 'felix situations: %s could not be read: the tree id of %s could not be taken in its scratch checkout\n' "$side" "$sha" >&2
    return 3
  fi
  caps="$( unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR
           export TMPDIR="$tmp"
           felix_detect "$clone" 2>/dev/null | LC_ALL=C sort -u )"
  if ! ( unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR
         export TMPDIR="$tmp"
         felix_probes_run "$proj" "$clone" ) > "$out.probes" 2>/dev/null \
     || ! {
       printf 'how\tscratch\ncommit\t%s\ntree\t%s\nstamp\t-\ndetector\trun\n' "$sha" "$tid"
       while IFS= read -r c; do
         [ -z "$c" ] || printf 'cap\t%s\n' "$c"
       done <<EOF2
$caps
EOF2
       LC_ALL=C awk -F'\t' '{ printf "probe\t%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, $5 }' "$out.probes"
     } > "$out" 2>/dev/null; then
    printf 'felix situations: %s could not be read: its reading could not be written in %s\n' "$side" "$scr" >&2
    return 3
  fi
  return 0
}
