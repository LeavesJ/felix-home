# What Felix may do here without being asked.
#
# Felix removing a file from somebody's product repository, unattended, at
# session start, is the sharpest trust boundary in the system. Everything else
# it does unattended is additive: it injects text, appends a log, or refuses a
# command. This deletes.
#
# So it is opted into per project and never inferred. An absent `autonomy` file
# means nothing is permitted, which is the state every project starts in and
# the state one stays in until somebody types the opt-in themselves. Felix does
# not write this file on a project's behalf, because a permission a system
# grants itself is not a permission.
#
# projects/<p>/autonomy: one capability per line.
#   tidy        remove a lookalike script when Felix already holds that file
#   commission  run the commissioning pipeline with nobody present
#
# Reporting is not listed and never needs opting into. Saying "this exists and
# nothing can reach it" changes nothing on disk.

# The commission grant, and the table it was granted over.
#
# Every other grant here names an action the engine defines. This one names a
# pipeline whose steps come from a project's own commissioning.tsv, and two of
# that table's columns — `when` and `check` — are eval'd in the checkout
# (commission.sh). Today nothing on a hook path evaluates them; the session
# hook says so in as many words, and felix_commission_run has exactly two
# callers, both in the CLI. Granting this puts them on a hook path.
#
# That is the whole of the risk, and it is not about today's table: every check
# in it is a read-only predicate, and the run declares stack.tsv rows without
# installing anything — felix_commission_apply_declares writes a row and a log
# line, and no installer is downstream of it. The risk is that
# projects/<p>/commissioning.tsv is ORDINARY-tier by this project's own
# constitution, so a routine edit to it would otherwise become code that runs
# unattended, forever, with nothing on any surface to show it.
#
# So the grant is bound to the table it was granted over. The policy version —
# already a hash across the table set — is stamped when a person types the
# command, and a background run refuses when the current hash differs. A table
# edited after the grant does not inherit it, and re-arming is a person's act
# of reading what changed. The same shape as the discovery cache's stamp: a
# stale verdict is not a verdict.
felix_autonomy_stamp_path() { printf '%s/autonomy.%s' "$1" "$2"; }

# Does the grant still cover what is on disk?
felix_autonomy_commission_current() {   # proj -> 0 when the stamp matches
  local proj="$1" stamped now
  felix_autonomy_allows "$proj" commission || return 1
  stamped="$(head -1 "$(felix_autonomy_stamp_path "$proj" commission)" 2>/dev/null)"
  [ -n "$stamped" ] || return 1
  command -v felix_commission_policy_version >/dev/null 2>&1 || return 1
  now="$(felix_commission_policy_version "$proj" 2>/dev/null)"
  [ -n "$now" ] && [ "$stamped" = "$now" ]
}

# What a grant is, read the same way by every caller.
#
# 2026-10-02, from the adversarial review of the revoke fix: the reader trimmed
# [[:space:]], and what that matches depends on the caller's locale and its C
# library. Under macOS's UTF-8 locales it takes U+00A0 (Option-Space), U+2003
# and a lone \240 byte; glibc's take U+2003 but not U+00A0; C takes none. So a
# line was a grant to one session-start and not to another, and a revoke run
# under C said "revoked: tidy" over a line the next UTF-8 session still tidied
# by. bash 5.2's read also swallows the newline after a stray UTF-8 lead byte
# in a UTF-8 locale, hiding the next line inside a comment. And bash 3.2 cuts
# a line's value at a NUL byte while 5.2 skips the byte, so "tidy\0x" was a
# grant to one and not the other.
#
# So the reader runs in the C locale, and a file holding a NUL grants nothing:
# lines are bytes split on newline, and only ASCII whitespace (space, tab, CR,
# VT, FF) is trimmed. The locale is set inside a subshell so it binds this
# read and nothing of the caller's. Against the old reader this narrows the
# trim everywhere (a grant typed with a non-ASCII space is shown [ ] by this
# engine) and widens one case: on bash 5.2 in a UTF-8 locale, a line after a
# stray lead byte is read as its own line and can grant.

# The file's whole text into _felix_autonomy_text, in one read. Call it in the
# C locale. 0 read whole, 1 could not be read, 2 holds a NUL byte.
_felix_autonomy_read() {
  local rc=1
  _felix_autonomy_text=""
  { IFS= read -r -d '' _felix_autonomy_text; rc=$?; } < "$1" 2>/dev/null || return 1
  # read -d '' stops at a NUL with status 0, and at the end of the file with 1.
  [ "$rc" = 1 ] || return 2
  # A first read that fails also ends with 1 and nothing read, which would pass
  # for an empty file; a file with bytes in it was not read if nothing came.
  [ -n "$_felix_autonomy_text" ] || [ ! -s "$1" ] || return 1
  return 0
}

# Does this one line grant this capability? Call it in the C locale.
_felix_autonomy_grants() {   # line want -> 0 when the line grants want
  local line="$1"
  case "$line" in ''|'#'*) return 1 ;; esac
  # Trimmed, because a trailing space in a hand-edited file should not be the
  # difference between a permission holding and silently not.
  line="${line%"${line##*[![:space:]]}"}"
  line="${line#"${line%%[![:space:]]*}"}"
  [ "$line" = "$2" ]
}

# Could any reader, of this engine or an older one, in any locale, take this
# line as granting this capability? Revoke removes these, which is wider than
# what this engine's reader grants. 2026-10-08, from the second review: the
# engines already deployed (plugin caches up to 0.49.273, and every session
# started before a deploy) keep the locale-bound reader, so a revoke that
# matched only this engine's reader said "revoked: tidy" over a tidy<NBSP>
# line their session-start still tidied by. Every non-ASCII whitespace
# character is made of bytes from \200 up in UTF-8, and is one such byte in a
# single-byte locale, so trimming all of them from both ends covers every
# reader. A line that only looks like the grant goes too; it granted nothing
# here. Call it in the C locale, so the byte range is bytes.
_felix_autonomy_names() {   # line want -> 0 when some reader might take the line as want
  local line="$1" hi=$'\200-\377'
  case "$line" in ''|'#'*) return 1 ;; esac
  line="${line%"${line##*[![:space:]$hi]}"}"
  line="${line#"${line%%[![:space:]$hi]*}"}"
  [ "$line" = "$2" ]
}

# One pass of revoke, in the C locale. Reads the file once, checks the read
# was whole, and drops every line _felix_autonomy_names matches.
#   with tmp: writes what is kept to tmp; 0 written, 4 nothing to remove
#   tmp "":   writes nothing; 5 something to remove, 4 nothing to remove
#   1 the file could not be read whole, or tmp could not be written
#   2 the file holds a NUL byte
_felix_autonomy_rewrite() {   # file want tmp
  local f="$1" want="$2" tmp="$3" rc line kept="" hit=1 ended=1 last=0 body nl='
'
  _felix_autonomy_read "$f"; rc=$?
  [ "$rc" = 0 ] || return "$rc"
  # A read cut short mid-file also ends like the end of the file. The byte
  # count is the check: in the C locale ${#…} counts bytes.
  [ "$(( $(wc -c < "$f") ))" -eq "${#_felix_autonomy_text}" ] || return 1
  body="$_felix_autonomy_text"
  case "$body" in *"$nl") body="${body%"$nl"}" ;; *) ended=0 ;; esac
  # One line at a time, from the one read: the here-string hands back the
  # same bytes plus a final newline. When the file's last line was unended
  # and is kept, that newline is not the file's, and comes off again.
  while IFS= read -r line; do
    if _felix_autonomy_names "$line" "$want"; then hit=0 last=0
    else kept="$kept$line$nl" last=1; fi
  done <<< "$body"
  [ "$hit" = 0 ] || return 4
  [ -n "$tmp" ] || return 5
  [ "$ended$last" != 01 ] || kept="${kept%"$nl"}"
  printf '%s' "$kept" > "$tmp" || return 1
}

felix_autonomy_allows() {
  local proj="$1" want="$2" line
  [ -n "$want" ] || return 1
  [ -f "$proj/autonomy" ] || return 1
  # The NUL check reads the whole file once, then the lines are read again and
  # the first grant answers. One line at a time, because splitting the text in
  # shell copies the rest of it per line, and that is quadratic on the hook
  # path: a 100 KB file took a minute at this machine's load.
  ( LC_ALL=C
    _felix_autonomy_read "$proj/autonomy" || exit 1
    while IFS= read -r line || [ -n "$line" ]; do
      _felix_autonomy_grants "$line" "$want" && exit 0
    done < "$proj/autonomy"
    exit 1 ) 2>/dev/null
}

# Take a grant back: rewrite the file without every line any reader could take
# as that grant (_felix_autonomy_names), keeping every other byte, an unended
# last line unended. The caller says "revoked" only on 0.
#   0  no line any reader takes as cap is left (or there was none to begin
#      with, and the file was not touched)
#   1  the file could not be read whole, or the rewrite could not be written
#   2  the file holds a NUL byte: this engine reads nothing from it, an older
#      one may, and the bytes cannot be rewritten as they are
#   3  rewritten, and this engine's reader still finds the grant
#
# 2026-10-01: this was `grep -vxF cap autonomy > autonomy.new && mv` in
# cmd_autonomy. grep exits 1 when it selects no line, so a file holding the
# grant alone kept it — the && skipped the mv — while the command printed
# "revoked:" and deleted the stamp, and left autonomy.new behind. An unreadable
# file did the same through grep's exit 2. And grep matched whole lines
# exactly where the reader trims, so a hand-edited "commission " stayed granted
# after a revoke that said otherwise.
#
# Decided: revoke removes every line a reader could count as the grant —
# leading and trailing whitespace of any kind, CRs too — and keeps every other
# byte. Matching exactly instead would leave a revoke that cannot take back a
# grant a reader honours.
#
# The rewrite keeps the file's mode, and a revoke with nothing to remove
# writes nothing. A linked file is replaced by a regular one: the revoke is
# this project's, and the link's target, with anything else that shares it,
# keeps what it had.
#
# Not covered: two felix autonomy runs at once. Nothing locks the file, so the
# later mv can put back what the earlier one removed, after it said so. The
# file changes when a person runs this command, edits it by hand, or checks
# out a commit that carries it; the lock is its own change.
felix_autonomy_revoke() {
  local proj="$1" want="$2" f tmp="" rc mode
  [ -n "$want" ] || return 1
  f="$proj/autonomy"
  # The reader takes nothing from what is not a regular file.
  [ -f "$f" ] || return 0
  # Each pass runs in its own C locale with its output thrown away: bash 3.2's
  # printf can leave the unwritten tail of a failed write in its buffer, and
  # that is file text. The first pass writes nothing, so a revoke with nothing
  # to remove needs no writable directory and leaves the file as it was.
  ( LC_ALL=C; _felix_autonomy_rewrite "$f" "$want" "" ) > /dev/null 2>&1; rc=$?
  if [ "$rc" = 5 ]; then
    # mktemp creates the name or fails; it never opens a link planted there.
    tmp="$(mktemp "$f.new.XXXXXX" 2>/dev/null)" || return 1
    ( LC_ALL=C; _felix_autonomy_rewrite "$f" "$want" "$tmp" ) > /dev/null 2>&1; rc=$?
  fi
  if [ "$rc" = 0 ]; then
    # mktemp made it 0600; give it the file's own mode, or keep 0600.
    mode="$(stat -L -c %a "$f" 2>/dev/null || stat -L -f %Lp "$f" 2>/dev/null)"
    [ -z "$mode" ] || chmod "$mode" "$tmp" 2>/dev/null
    mv -f "$tmp" "$f" 2>/dev/null || rc=1
  fi
  rm -f "$tmp" 2>/dev/null
  case "$rc" in
    0|4) ;;
    2) return 2 ;;
    *) return 1 ;;
  esac
  # Read back through the reader rather than trusting the rewrite.
  felix_autonomy_allows "$proj" "$want" && return 3
  return 0
}

# Give a grant: rewrite the file with it on a line of its own, keeping every
# byte already there. The caller says "allowed" only on 0.
#   0  the reader grants cap now
#   1  cap is not a capability the engine defines; or the file is not a
#      regular file, is read-only or could not be read whole; or the rewrite
#      could not be written
#   2  the file holds a NUL byte, so what it grants cannot be read
#   3  rewritten, and a read of it does not find the grant
#
# 2026-10-08: this was `printf '%s\n' cap >> autonomy` in cmd_autonomy, which
# then printed "allowed:" whatever had happened. A hand-written last line with
# no newline took the grant onto it: `tidy` became `tidycommission`, which
# grants neither, so tidy was lost and commission never held, and `# note`
# took it into a comment. A file holding a NUL took the append and still
# granted nothing, since the reader refuses such a file whole. The commission
# stamp was written in each case.
#
# So a grant is written the way a revoke is: one read in the C locale, checked
# against the file's size, a newline first where the last line is unended, the
# whole text into a mktemp file and mv'd into place, then read back through the
# reader. A file that cannot be read whole, or a directory that cannot take the
# new file, is left as it was rather than half appended to.
#
# Not covered, as in revoke: two felix autonomy runs at once. A grant that read
# the file before a revoke's mv puts back what the revoke removed, after it
# said so, which an append could not do; the lock on both is its own change
# (claude/autonomy-writer-lock). As in revoke, the rewrite keeps the file's
# mode and replaces a link at the path with a regular file; a new file takes
# the umask's mode, as the append's did.
felix_autonomy_grant() {
  local proj="$1" want="$2" f tmp rc mode
  # Only what the engine defines, as cmd_autonomy checks: a value with a
  # newline in it would write a second line and then report no grant.
  case "$want" in tidy|commission) ;; *) return 1 ;; esac
  f="$proj/autonomy"
  # A regular file or nothing. The reader takes nothing from anything else, so
  # a link that leads nowhere, a directory or a pipe a person put there is
  # theirs to fix and not replaced, and a pipe is never opened, since the read
  # would wait for a writer that never comes. Nor a file made read-only: the mv
  # would replace it where the append could not write it, and a grant is the
  # direction that asks first.
  if [ -e "$f" ] || [ -L "$f" ]; then [ -f "$f" ] && [ -w "$f" ] || return 1; fi
  tmp="$(mktemp "$f.new.XXXXXX" 2>/dev/null)" || return 1
  # As in revoke: its own C locale, and its stdout thrown away.
  ( LC_ALL=C; nl='
'
    if [ -e "$f" ]; then
      _felix_autonomy_read "$f"; rc=$?
      [ "$rc" = 0 ] || exit "$rc"
      [ "$(( $(wc -c < "$f") ))" -eq "${#_felix_autonomy_text}" ] || exit 1
    else
      _felix_autonomy_text="# What Felix may do here unattended.$nl"
    fi
    case "$_felix_autonomy_text" in
      ''|*"$nl") ;;
      *) _felix_autonomy_text="$_felix_autonomy_text$nl" ;;
    esac
    printf '%s' "$_felix_autonomy_text$want$nl" > "$tmp" || exit 1
  ) > /dev/null 2>&1; rc=$?
  if [ "$rc" = 0 ]; then
    # mktemp made it 0600: the file's own mode, or the umask's for a new one.
    if [ -e "$f" ]; then mode="$(stat -L -c %a "$f" 2>/dev/null || stat -L -f %Lp "$f" 2>/dev/null)"
    else mode="$(printf '%o' "$(( 0666 & ~0$(umask) ))")"; fi
    [ -z "$mode" ] || chmod "$mode" "$tmp" 2>/dev/null
  fi
  if [ "$rc" != 0 ] || ! mv -f "$tmp" "$f" 2>/dev/null; then
    rm -f "$tmp" 2>/dev/null
    [ "$rc" = 2 ] && return 2
    return 1
  fi
  felix_autonomy_allows "$proj" "$want" || return 3
  return 0
}

# Remove lookalike scripts, and only where every check holds.
#
# The checks, in order, each one able to stop the removal on its own:
#
#   1. The project opted in. No file, no removal, however safe it looks.
#   2. Felix holds a file of that exact name for this project, so the copy that
#      matters survives regardless of what happens next.
#   3. Git does not track it. A tracked file is part of the repository's stated
#      contents, and deleting one is a change to the project rather than the
#      removal of a stray — a different and much larger act, whoever is right
#      about which copy is better.
#   4. It is not the declared gate, and does not live inside Felix's own home.
#   5. The backup was written and is readable. Nothing is removed on the
#      strength of a copy nobody confirmed.
#
# Emits one line per removal. Silence means nothing was touched.
felix_tidy_safe() {
  local proj="$1" root="$2" home="$3"
  felix_autonomy_allows "$proj" tidy || return 0

  local gate; gate="$(felix_json_str "$proj/project.json" gate 2>/dev/null)"
  local rivals; rivals="$(_felix_rival_gates "$root" "$proj" "$gate" 2>/dev/null)"
  [ -n "$rivals" ] || return 0

  local state f note base backup
  while IFS=$'\t' read -r state f note; do
    [ -n "${f:-}" ] || continue
    # 3. Tracked stays. _felix_rival_gates reports both, and only one of them
    #    is a stray file somebody left behind.
    [ "${state:-}" = "untracked" ] || continue
    base="${f##*/}"
    # 2. Felix holds the copy that matters.
    [ -f "$proj/$base" ] || continue
    # 4. Never the gate, never Felix's own storage.
    [ "$root/$f" -ef "$proj/$gate" ] 2>/dev/null && continue
    # The same repository test as the reporter, and it matters more here. A
    # prefix match against the home is true only when standing in the home, so
    # from a worktree of Felix this guard lapsed entirely — on the one path in
    # the system that deletes. Guard 3 above still held it back (Felix's stored
    # files are tracked, and only untracked ones are removed), so nothing was
    # ever lost; a defence that only works from one directory is not a defence.
    case "$f" in
      projects/*) felix_same_repo "$root" "${home:-/nonexistent}" && continue ;;
    esac

    # 5. Copy first, confirm the copy, then remove. A backup nobody checked is
    #    the same as no backup at the moment it turns out to matter.
    mkdir -p "$home/state/rivals" 2>/dev/null || continue
    backup="$home/state/rivals/$(basename "$proj")-$(printf '%s' "$f" | tr '/' '-')"
    cp "$root/$f" "$backup" 2>/dev/null || continue
    [ -s "$backup" ] || [ ! -s "$root/$f" ] || continue

    rm -f "$root/$f" 2>/dev/null || continue
    printf '%s\n' "$f"
  done <<EOF
$rivals
EOF
}
