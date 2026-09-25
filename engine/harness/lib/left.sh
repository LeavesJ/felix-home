# How a session left its tree, written at every Stop and once more at
# SessionEnd.
#
# What a person needs at the end of a session is whether its work is safe:
# committed, pushed, or waiting on an answer from them. SessionEnd fired for 13
# of the 60 sessions started or resumed from 2026-09-22 to 2026-09-24, since a
# desktop session left idle never ends, so the fact is written at every Stop,
# whose payload carries the final message. Each stop overwrites the last; the
# last one written is how the session left.
#
# One line per session at $(felix_mem_dir <project>)/left/<session>.tsv, its
# columns the left row of templates/schemas.tsv:
#
#   time     UTC, 2026-09-24T12:00:00Z, the stamp the other memory logs use
#   session  the payload's session_id
#   dir      the checkout's root, as the hook resolved it
#   head     the full sha of HEAD; unborn with no commit yet; - outside git
#   state    clean | dirty | unpushed | dirty+unpushed | no-remote | unborn | -
#   asked    yes when the final message asked something; no when it did not;
#            - when there was no message
#
# The states. dirty is what felix_tree_dirty says: tracked changes, or
# untracked files git does not ignore, less Felix's own bookkeeping where its
# home is inside the tree. unpushed is HEAD holding a commit that no
# remote-tracking ref reaches (git rev-list --count HEAD --not --remotes above
# 0). Where that question has no answer the state says why. no-remote is a
# repository with no remote, where unpushed means nothing, when its tree is
# clean; a dirty one reads dirty, since uncommitted work is still the fact that
# matters there. unborn is a repository with no commit, whatever its tree,
# since everything in it is uncommitted. - is no repository git can read, or a
# status it could not take.
#
# asked. The payload's last_assistant_message, JSON-escaped, is decoded by
# asktext and judged by asks, both in lib/asks.sh: the program felix inventory
# runs over a transcript's final text, so the two cannot read one message two
# ways. SessionEnd's payload has no such field, so the end keeps the asked the
# session's last Stop recorded. A Stop's payload lacks it only when the last
# message held no text, and that stop asked nothing: its asked is -, not the
# stop before it's. The message is recorded and never decided on: the Stop
# hook still holds on the tree alone, as its header says why.
#
# It never blocks and never fails its caller. The line is written to a dotted
# file beside the record and renamed over it, so a reader sees the old line or
# the new one and never half of one. An unwritable memory root, a missing git
# or a malformed payload loses the record, not the session, and every error
# goes nowhere. A stop costs one git status, which also names HEAD and which
# the Stop hook's clean-tree check reuses (felix_left_dirty) in place of the
# two git calls it made; one rev-list, asked for one commit at most, since
# only whether any is unpushed matters and a repository no remote-tracking
# ref covers would otherwise be walked whole; one awk pass over the payload,
# which judges only the message's last 16 KiB (lib/asks.sh says why); a date
# and a rename. git remote, which reads only the configuration, runs only
# when HEAD is unpushed, to tell no-remote apart. No transcript is read.
#
# The platform's summary request (#264) writes nothing here: both hooks pass
# over that session before they call in, except where a chain of Felix's own
# hold ends, and Felix never holds that session.
#
# felix_left_facts computes the facts alone and leaves them in FELIX_LEFT_STATE,
# FELIX_LEFT_HEAD and FELIX_LEFT_PUSHED (yes when HEAD is on a remote-tracking
# ref, no when it is not, - where there is no HEAD), so that anything else a
# Stop decides on how the tree stands reads them instead of asking git again.
# Three more say where HEAD stands against the branch's upstream, for a caller
# that must know the exact commit a remote holds and not only that one holds
# it: FELIX_LEFT_BRANCH, the branch checked out, empty when HEAD is detached;
# FELIX_LEFT_UPSTREAM, that branch's upstream as git abbreviates it, such as
# origin/topic, empty when it has none or the one it names is not there; and
# FELIX_LEFT_AT_UPSTREAM, yes only when HEAD is that upstream's commit exactly,
# else no. PUSHED is weaker: a commit a remote's main already contains is
# pushed, and is at no upstream. All three come from the same git status, and
# nothing here reaches a remote.

case "${BASH_SOURCE[0]:-}" in
  */*) _FELIX_LEFT_LIB="${BASH_SOURCE[0]%/*}" ;;
  *)   _FELIX_LEFT_LIB=. ;;
esac
# The rule, and what the facts and the record lean on, when the caller has not
# loaded them. Both hooks have; a caller that sources this file alone gets the
# same definitions rather than a command not found.
[ -n "${_FI_HOST_ASKTEXT:-}" ] || . "$_FELIX_LEFT_LIB/asks.sh" 2>/dev/null
command -v felix_mem_dir >/dev/null 2>&1 || . "$_FELIX_LEFT_LIB/resolve.sh" 2>/dev/null
command -v felix_tree_dirty >/dev/null 2>&1 || . "$_FELIX_LEFT_LIB/verify.sh" 2>/dev/null

# Its input read as one record. In payload mode, the raw value of the
# payload's last_assistant_message, found by a key that follows a brace or a
# comma, which a key quoted inside a string cannot (there it follows a
# backslash); in message mode, the input is that raw value. Prints yes, no, -
# for no message (absent, null, or empty once decoded), or absent for a
# payload with no such field.
# shellcheck disable=SC2016
_FELIX_LEFT_AWK='
  BEGIN { RS = "\001" }
  { p = p $0 }
  END {
    if (mode == "payload") {
      if (!match(p, /[{,][ \t\r\n]*"last_assistant_message"[ \t\r\n]*:[ \t\r\n]*/)) { print "absent"; exit }
      p = substr(p, RSTART + RLENGTH)
      if (substr(p, 1, 1) != "\"") { print "-"; exit }
      p = substr(p, 2); p = match(p, /^([^"\\]|\\.)*/) ? substr(p, 1, RLENGTH) : ""
    }
    p = asktext(p)
    print (p == "" ? "-" : (asks(p) ? "yes" : "no"))
  }
'

# Whether a final message asks something, as the record and felix inventory
# judge it: yes, no, or - when there is no message.
felix_left_asked() {   # message, JSON-escaped as a payload carries it
  local a
  a="$(printf '%s' "${1:-}" | LC_ALL=C awk -v mode=message "$_FI_HOST_ASK$_FI_HOST_ASKTEXT$_FELIX_LEFT_AWK" 2>/dev/null)"
  case "$a" in yes|no) ;; *) a=- ;; esac
  printf '%s\n' "$a"
}

# The facts of one checkout, into FELIX_LEFT_STATE, FELIX_LEFT_HEAD and
# FELIX_LEFT_PUSHED, each - when git cannot say, and FELIX_LEFT_BRANCH,
# FELIX_LEFT_UPSTREAM and FELIX_LEFT_AT_UPSTREAM, empty, empty and no when it
# cannot. home, when given, is Felix's home, whose bookkeeping is not the work
# (felix_tree_dirty's excludes).
#
# One git status answers them all. Porcelain v2 with --branch heads its
# entries with the commit HEAD names, or (initial) where there is none yet, so
# it stands in for a rev-parse; with the branch, or (detached); and, where the
# branch has an upstream, its name and a branch.ab line. Every line after the
# headers is a change, the same set felix_tree_dirty's v1 status lists.
# --no-ahead-behind keeps it from walking history: the ab line then reads
# +0 -0 when HEAD is the upstream's commit and +? -? when it is not, and is
# missing when the upstream named is not there, which is when rev-parse
# --abbrev-ref @{u} fails and names none. A git that cannot run (126, 127) or
# does not know those flags (129, before 2.17) is not taken for a missing
# repository: the facts stay -, nothing is recorded over the last stop's line,
# and the clean-tree check asks felix_tree_dirty instead. The status is cut by
# bash patterns, under C: in a UTF-8 locale they cost bash 3.2 five times as
# much, 0.77 s against 0.14 s of CPU on a status of 50,000 files.
felix_left_facts() {   # dir [home]
  local dir="${1:-}" home="${2:-}" st rc n r ex f dirty unp="" nl=$'\n' h l up="" ab="" LC_ALL=C
  local -a exargs=()
  FELIX_LEFT_STATE=- FELIX_LEFT_HEAD=- FELIX_LEFT_PUSHED=-
  FELIX_LEFT_BRANCH="" FELIX_LEFT_UPSTREAM="" FELIX_LEFT_AT_UPSTREAM=no
  _FELIX_LEFT_KEY="" _FELIX_LEFT_DIRTY="" _FELIX_LEFT_GIT=no
  [ -n "$dir" ] || return 0
  # The excludes are asked for only where the home is inside this tree, the
  # one case in which _felix_tree_excludes names any.
  if [ -n "$home" ]; then
    case "$home" in
      "$dir"|"$dir"/*)
        ex="$(_felix_tree_excludes "$dir" "$home" 2>/dev/null)"
        while [ -n "$ex" ]; do
          f="${ex%%"$nl"*}"; [ -z "$f" ] || exargs[${#exargs[@]}]="$f"
          case "$ex" in *"$nl"*) ex="${ex#*"$nl"}" ;; *) ex="" ;; esac
        done ;;
    esac
  fi
  st="$(git --no-optional-locks -C "$dir" status --porcelain=v2 --branch --no-ahead-behind \
          -- . ${exargs[@]+"${exargs[@]}"} 2>/dev/null)"; rc=$?
  case "$rc" in 126|127|129) return 0 ;; esac
  _FELIX_LEFT_GIT=yes
  # Any other failure is no repository git can read here, as lib/lifecycle.sh
  # reads rev-parse's 128.
  [ "$rc" = 0 ] || return 0
  case "$st" in "# branch.oid "*) ;; *) return 0 ;; esac
  case "$st" in *"$nl"[!#]*) dirty=yes ;; *) dirty=no ;; esac
  _FELIX_LEFT_KEY="$dir"$'\t'"$home"; _FELIX_LEFT_DIRTY="$dirty"
  # The headers, one a line, cut at the first entry first, so a tree with a
  # long status is copied once here and not once a header.
  h="${st%%"$nl"[!#]*}"
  while :; do
    l="${h%%"$nl"*}"
    case "$l" in
      "# branch.head (detached)") ;;
      "# branch.head "*)     FELIX_LEFT_BRANCH="${l#"# branch.head "}" ;;
      "# branch.upstream "*) up="${l#"# branch.upstream "}" ;;
      "# branch.ab +0 -0")   ab=yes ;;
      "# branch.ab "*)       ab=no ;;
      "# "*) ;;
      *) break ;;
    esac
    case "$h" in *"$nl"*) h="${h#*"$nl"}" ;; *) break ;; esac
  done
  if [ -n "$up" ] && [ -n "$ab" ]; then FELIX_LEFT_UPSTREAM="$up" FELIX_LEFT_AT_UPSTREAM="$ab"; fi
  st="${st#"# branch.oid "}"; st="${st%%"$nl"*}"
  if [ "$st" = "(initial)" ]; then FELIX_LEFT_HEAD=unborn FELIX_LEFT_STATE=unborn; return 0; fi
  FELIX_LEFT_HEAD="$st"
  n="$(git --no-optional-locks -C "$dir" rev-list --count --max-count=1 HEAD --not --remotes 2>/dev/null)" || n=""
  case "$n" in
    0) FELIX_LEFT_PUSHED=yes; unp=no ;;
    ''|*[!0-9]*) ;;
    *) FELIX_LEFT_PUSHED=no
       if r="$(git --no-optional-locks -C "$dir" remote 2>/dev/null)"; then
         if [ -n "$r" ]; then unp=yes; else unp=none; fi
       fi ;;
  esac
  case "$dirty,$unp" in
    yes,yes)  FELIX_LEFT_STATE=dirty+unpushed ;;
    yes,*)    FELIX_LEFT_STATE=dirty ;;
    no,yes)   FELIX_LEFT_STATE=unpushed ;;
    no,none)  FELIX_LEFT_STATE=no-remote ;;
    *)        FELIX_LEFT_STATE=clean ;;
  esac
  return 0
}

# felix_tree_dirty's answer for a root and a home, from the status
# felix_left_facts took of that same checkout in this process when it could,
# else asked afresh. The Stop hook's clean-tree check reads it a few lines
# after the record, so a stop takes one git status and not two.
felix_left_dirty() {   # root [home] -> 0 when dirty
  if [ -n "${_FELIX_LEFT_DIRTY:-}" ] && [ "${_FELIX_LEFT_KEY:-}" = "${1:-}"$'\t'"${2:-}" ]; then
    [ "$_FELIX_LEFT_DIRTY" = yes ]
    return
  fi
  felix_tree_dirty "$@"
}

# Write how one session leaves one checkout, overwriting its line. The facts
# are left in FELIX_LEFT_STATE, FELIX_LEFT_HEAD and FELIX_LEFT_PUSHED, and the
# asked in FELIX_LEFT_ASKED, whether or not the line could be written. end,
# SessionEnd's, keeps the asked of the session's last Stop where the payload
# carries no message; any other caller records - there.
felix_left_record() {   # proj dir session payload [home] [end]
  local proj="${1:-}" dir="${2:-}" sid="${3:-}" home="${5:-}" asked mem store l="" d stamp tmp tab=$'\t'
  FELIX_LEFT_ASKED=-
  felix_left_facts "$dir" "$home"
  [ -n "$proj" ] && [ -n "$dir" ] || return 0
  asked="$(printf '%s' "${4:-}" | LC_ALL=C awk -v mode=payload "$_FI_HOST_ASK$_FI_HOST_ASKTEXT$_FELIX_LEFT_AWK" 2>/dev/null)"
  # The id names a file, so it is held to what the hold's record accepts
  # (_felix_hold_path in lib/verify.sh).
  case "$sid" in ''|.|..|-*|*[!A-Za-z0-9._-]*) sid="" ;; esac
  [ "${#sid}" -le 128 ] || sid=""
  mem="$(felix_mem_dir "$proj" 2>/dev/null)"
  [ -n "$mem" ] || return 0
  store="$mem/left"
  case "$asked" in
    yes|no|-) ;;
    absent)
      asked=-
      if [ "${6:-}" = end ] && [ -n "$sid" ] && [ -f "$store/$sid.tsv" ]; then
        { IFS= read -r l < "$store/$sid.tsv"; } 2>/dev/null
        case "${l##*"$tab"}" in yes|no) asked="${l##*"$tab"}" ;; esac
      fi ;;
    *) asked=- ;;
  esac
  FELIX_LEFT_ASKED="$asked"
  [ -n "$sid" ] && [ "${_FELIX_LEFT_GIT:-}" = yes ] || return 0
  stamp="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)"
  d="${dir//$tab/ }"; d="${d//$'\n'/ }"; d="${d//$'\r'/ }"
  [ -d "$store" ] || mkdir -p "$store" 2>/dev/null || return 0
  # Dotted and unsuffixed, so a reader's *.tsv glob cannot see it in flight.
  tmp="$store/.$sid.$$"
  if { printf '%s\t%s\t%s\t%s\t%s\t%s\n' "${stamp:--}" "$sid" "$d" "$FELIX_LEFT_HEAD" \
         "$FELIX_LEFT_STATE" "$asked" > "$tmp"; } 2>/dev/null \
     && mv -f "$tmp" "$store/$sid.tsv" 2>/dev/null; then
    return 0
  fi
  rm -f "$tmp" 2>/dev/null
  return 0
}
