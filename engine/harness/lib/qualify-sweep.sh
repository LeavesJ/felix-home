# The sweep of checker qualification: the scratch trees a killed run left,
# found and removed by a later run, and nothing else touched.
#
# Each row of qualification.tsv runs in a base mktemp makes under TMPDIR,
# felix-qualify.XXXXXX, holding a worktree of HEAD at w that is registered in
# the user's repository (_felix_qualify_one, lib/qualify-run.sh). The row
# throws it away at its end, and its traps do on INT, TERM and HUP. No trap
# reaches SIGKILL: kill -9, or a tool's TERM-then-KILL. Three trees from runs
# killed that way were found in the founder's checkout on 2026-09-25, on disk
# and still in git worktree list. So each row first writes down which process
# owns its base, and each run, before its first row, removes the bases whose
# owner is shown dead, then the registrations whose base is gone.
#
# Several sessions share one TMPDIR, and their runs are alive. So every step
# below decides toward leaving a base:
#
#   - Only TMPDIR, as the row's template names it: T is ${TMPDIR:-/tmp} with
#     one trailing slash taken off. git records a tree's physical path, and on
#     macOS /var/folders/... is registered as /private/var/folders/...
#     (measured), so a registration matches T as given or as pwd -P says.
#   - A candidate is exactly what a row makes: named felix-qualify. and six
#     letters or digits, a directory and no symlink (never followed), the
#     user's own, holding owner as a symlink whose text is a record a row
#     writes, `<pid>` or `<pid> <start>` with one space (_felix_qualify_me).
#     A base from an older engine (tmp.*), a base with no record, a record in
#     a regular file, and any other text are left. A base whose owner cannot
#     be read, its search bit gone, is left.
#   - Dead only when shown dead. kill -0 that fails saying No such process,
#     under LC_ALL=C; any other failure is a process that exists (Operation
#     not permitted is another user's, pid 1 among them, measured on bash
#     3.2.57), and a message lost to a fork that failed is not a death. Or the
#     process exists, the record has a start, and ps prints a start that is
#     not it: the pid is another process's now. A record with no start, or a
#     ps that prints nothing, is judged by kill -0 alone.
#   - Then the base gets its owner's rwx back, since a dead row's mutation may
#     have taken the write bit that a claim needs. That is the only mode a
#     sweep ever changes on a base it has not claimed, and only on one it has
#     judged dead.
#   - The claim, because two runs starting together both judge the same dead
#     record. Only rename(2) and symlink(2), each checked after
#     (_felix_qualify_claim): the record moved aside to a name of this
#     sweep's, the aside read back as the very text judged dead, this sweep's
#     own record linked at owner. A rename hands the dead record to one sweep
#     alone, so only one goes on; the other finds no owner, or finds the
#     winner's record and puts it back, and leaves the base without a word. A
#     sweep killed after its claim leaves a record naming itself, dead, and a
#     later sweep takes the base over.
#   - The drop is the row's own, _felix_qualify_drop, with the root this
#     sweep was given: the tree, its registration when this root holds it,
#     and the base, its record last. It says, as it always has, only what is
#     really left; a base it cannot empty keeps a record, so each later run
#     tries again and says again that it is left.
#   - Orphans: a registration in this root of exactly <T>/felix-qualify.<six>/w
#     whose base is neither there nor a symlink, from a base swept by another
#     repository's run, or by a run of this root whose drop lost the
#     registration. One `git worktree remove -f -f` of that path each, which
#     removes a registration whose directory is gone (measured, rc 0 on git
#     2.54). Never `git worktree prune`: it removes every stale entry, and
#     other sessions' and the user's own are not Felix's.
#
# It prints nothing on stdout, which the row loop's verdict lines own, and no
# line of its begins with two spaces, which felix gate counts rows by. It
# changes no verdict, count or status.
#
# What it cannot reach:
#   - A base made before this: a tmp.* name, or a felix-qualify.* base with no
#     record.
#   - A run killed between mktemp and its record: an empty base, no record.
#   - A base whose owner cannot be read, because the row's mutation took the
#     owner's read or search bit off the base and the row was then killed.
#   - A base in another TMPDIR; only a later run under the same one sees it.
#   - A row whose own mutation removes or rewrites ../owner, which same-user
#     code can do and nothing here can stop. Removed, that row's tree is never
#     swept if it is killed. Forged dead, a concurrent sweep may drop the live
#     row's tree under it, and that row then reads unrunnable.
#   - Another repository's registration of a base swept here from disk. That
#     repository's own next sweep removes it as an orphan.
#   - Rarer interleavings than two sweeps on one base, such as three and a
#     kill inside the claim, may let two sweeps drop the same dead base. No
#     live row's tree is reached that way: only a record judged dead is ever
#     claimed.

# The letters and digits of a base's six, spelled out: a range in a bracket
# follows the locale's collation on bash 3.2.
_felix_qualify_alnum='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'

# A symlink's text, every byte of it, in _felix_qualify_text, which the caller
# makes local: a record of a pid and a newline is not a record. readlink -n,
# because macOS's readlink adds its newline only to a text that does not end
# in one (measured 2026-10-01), so no newline can be taken off as its own; and
# a sentinel, because $(...) drops trailing newlines. Non-zero when it is not
# a symlink or cannot be read.
_felix_qualify_link() {   # path -> _felix_qualify_text
  local t
  _felix_qualify_text=""
  [ -L "$1" ] || return 1
  t="$(readlink -n "$1" 2>/dev/null && printf x)" || return 1
  _felix_qualify_text="${t%x}"
}

# Whether a text is a record a row writes: a pid of one to ten digits with no
# leading zero, then nothing, or one space and a start with no blank in it.
_felix_qualify_isrec() {   # text
  local p="${1%% *}" s
  case "$p" in ''|0*|*[!0123456789]*) return 1 ;; esac
  [ "${#p}" -le 10 ] || return 1
  [ "$1" = "$p" ] && return 0
  s="${1#"$p" }"
  [ -n "$s" ] && [ "$1" = "$p $s" ] || return 1
  case "$s" in *[[:space:]]*) return 1 ;; esac
}

# Whether a record's process is shown dead. 0 only when it is; every other
# case, a check that could not be made among them, is alive.
_felix_qualify_dead() {   # pid, start or empty
  local said now
  if said="$(LC_ALL=C builtin kill -0 "$1" 2>&1)"; then
    [ -n "$2" ] || return 1
    now="$(TZ=UTC0 LC_ALL=C ps -o lstart= -p "$1" 2>/dev/null)"
    now="${now//[[:space:]]/}"
    [ -n "$now" ] && [ "$now" != "$2" ]
    return
  fi
  case "$said" in *"No such process"*) return 0 ;; esac
  return 1
}

# The claim on a base whose record was judged dead: 0 when this sweep alone
# goes on to drop it. The aside's name carries this sweep's pid, so two sweeps
# never share it, and one already there is not this sweep's to move over.
#
# owner absent after this sweep linked its record is the one case it goes on
# without reading its own record back: a sweep that judged the dead record
# before this one moved it has moved this one's record aside to check it, and
# puts it back. The rename already made this sweep the only holder of the dead
# record, so no other sweep can be going on. Anything else at owner, a link of
# other text or no link at all, and the base is left.
_felix_qualify_claim() {   # base, the record judged dead, this sweep's record
  local b="$1" aside="$1/owner.claim.${3%% *}" _felix_qualify_text
  if [ -e "$aside" ] || [ -L "$aside" ]; then return 1; fi
  mv -f "$b/owner" "$aside" 2>/dev/null || return 1
  if ! _felix_qualify_link "$aside" || [ "$_felix_qualify_text" != "$2" ]; then
    [ -e "$b/owner" ] || [ -L "$b/owner" ] || mv -f "$aside" "$b/owner" 2>/dev/null
    return 1
  fi
  if ! ln -s -- "$3" "$b/owner" 2>/dev/null; then
    [ -e "$b/owner" ] || [ -L "$b/owner" ] || mv -f "$aside" "$b/owner" 2>/dev/null
    return 1
  fi
  if [ -L "$b/owner" ]; then
    _felix_qualify_link "$b/owner" && [ "$_felix_qualify_text" = "$3" ] || return 1
  elif [ -e "$b/owner" ]; then
    return 1
  fi
  rm -f "$aside" 2>/dev/null
  return 0
}

# Whether a registered path is an orphan of this sweep's: exactly
# <T>/felix-qualify.<six>/w, T as given or physical, its base shown absent.
_felix_qualify_orphan() {   # path, T, T physical or empty
  local b d n
  case "$1" in */w) ;; *) return 1 ;; esac
  b="${1%/w}"; d="${b%/*}"; n="${b##*/}"
  [ "$d" = "$2" ] || { [ -n "$3" ] && [ "$d" = "$3" ]; } || return 1
  case "$n" in felix-qualify.??????) ;; *) return 1 ;; esac
  case "${n#felix-qualify.}" in *[!"$_felix_qualify_alnum"]*) return 1 ;; esac
  _felix_qualify_absent "$d" "$n"
}

# Whether a directory holds no entry of a name, shown: it can be entered and
# listed, the listing lacks the name, and the name is neither there nor a
# symlink. A test of the path alone reads a base as absent when TMPDIR has
# lost its search bit, or a stat fails, and a live row's registration was
# removed for good (review 2026-10-01). Its own process, for the cd.
_felix_qualify_absent() {   # dir, name
  ( nl='
'
    CDPATH='' cd -- "$1" 2>/dev/null || exit 1
    l="$(ls -A . 2>/dev/null && printf x)" || exit 1
    case "$nl${l%x}" in *"$nl$2$nl"*) exit 1 ;; esac
    [ ! -e "$2" ] && [ ! -L "$2" ] )
}

# Its own process, so the glob options it sets (_felix_qualify_globs) reach
# no caller.
_felix_qualify_sweep() (   # root
  local root="$1" t="${TMPDIR:-/tmp}" tp b n rec p s me="" listed relisted rest line failed="" nl='
'
  local _felix_qualify_text _felix_qualify_rec
  _felix_qualify_globs
  t="${t%/}"
  [ -n "$t" ] && [ -d "$t" ] || return 0
  # T's physical path, with any newline it ends in: $(...) alone would drop
  # it and name another directory.
  tp=""; _felix_qualify_phys "$t" && tp="$_felix_qualify_text"
  for b in "$t"/felix-qualify.??????; do
    n="${b##*/}"; n="${n#felix-qualify.}"
    case "$n" in *[!"$_felix_qualify_alnum"]*) continue ;; esac
    [ -d "$b" ] && [ ! -L "$b" ] && [ -O "$b" ] || continue
    _felix_qualify_link "$b/owner" || continue
    rec="$_felix_qualify_text"
    _felix_qualify_isrec "$rec" || continue
    p="${rec%% *}"; s=""
    [ "$rec" = "$p" ] || s="${rec#* }"
    _felix_qualify_dead "$p" "$s" || continue
    # This sweep's own record, once, and only for a base judged dead: with
    # none to be had, nothing can be claimed, and the bases are left.
    if [ -z "$me" ]; then
      _felix_qualify_me && me="$_felix_qualify_rec" || me=-
    fi
    [ "$me" != - ] || continue
    chmod u+rwx "$b" 2>/dev/null
    _felix_qualify_claim "$b" "$rec" "$me" || continue
    _felix_qualify_drop "$root" "$b"
  done
  # The orphans, off one list. A remove that failed is said only if a second
  # list still shows it: two sweeps remove the same orphan, and one of them
  # fails on a registration the other took. A second list that cannot be had
  # leaves the status to say it.
  listed="$(git -C "$root" worktree list --porcelain 2>/dev/null)" || return 0
  rest="$listed"
  while [ -n "$rest" ]; do
    line="${rest%%"$nl"*}"
    case "$rest" in *"$nl"*) rest="${rest#*"$nl"}" ;; *) rest="" ;; esac
    case "$line" in "worktree "*) ;; *) continue ;; esac
    p="${line#worktree }"
    _felix_qualify_orphan "$p" "$t" "$tp" || continue
    git -C "$root" worktree remove -f -f "$p" >/dev/null 2>&1 || failed="$failed$p$nl"
  done
  [ -n "$failed" ] || return 0
  relisted=yes
  listed="$(git -C "$root" worktree list --porcelain 2>/dev/null)" || relisted=no
  rest="$failed"
  while [ -n "$rest" ]; do
    p="${rest%%"$nl"*}"; rest="${rest#*"$nl"}"
    if [ "$relisted" = yes ]; then
      case "$nl$listed$nl" in *"${nl}worktree $p$nl"*) ;; *) continue ;; esac
    fi
    printf 'felix: %s still lists the scratch worktree %s, which could not be removed\n' "$root" "$p" >&2
  done
  return 0
)
