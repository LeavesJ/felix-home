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
# line their session-start still tidied by.
#
# A reader grants a line that is the capability with whitespace around it, as
# its locale reads whitespace. So a line names the capability when it holds it
# once and nothing else in the line is an ASCII letter or '#': no whitespace
# character, in any encoding a macOS or glibc locale runs in, holds either
# byte. UTF-8's and the EUC encodings' are bytes from \200 up, Shift-JIS's
# ideographic space is \201@ and Big5's \241@, and GB18030's four-byte spaces
# hold digits. Checked 2026-10-08 against Python's codecs and every LC_CTYPE
# on this Mac. The encodings that do put a letter in a space are ones no
# locale reads with it: EBCDIC, ISO-2022 and UTF-7, and Shift_JIS-2004, whose
# no-break space is \205A (macOS has no such locale, and glibc's space class
# leaves out U+00A0). 2026-10-08, from the third review: trimming whitespace
# and bytes from \200 up missed Shift-JIS, whose ideographic space ends in an
# ASCII '@', so an older engine under ja_JP.SJIS still tidied by "tidy\201@"
# after "revoked: tidy".
#
# A line that only looks like the grant ("tidy.", "- tidy", "tidy=0") goes too;
# no reader granted it. This holds while the capability names are letters: a
# second copy, or any other letter, is then a letter before or after a copy.
# Call it in the C locale, so a letter is A-Z or a-z.
#
# Only case patterns. 2026-10-08, from the fourth review: bash's # and %
# operators run a match from every position of the line, and each match
# measures the rest of it again, so they are quadratic in the line's length:
# one 512 KB line cost 8.8 s of CPU. A case alternative is also tried from
# every position, so the order matters (2026-10-08, from the fifth review):
# "a letter before a copy" tried first scanned the rest of "tidy" plus 64 KB
# of letters from each letter, 5.5 s. "A letter after a copy" fails at most
# once per line, and the other runs only when no letter follows any copy.
_felix_autonomy_names() {   # line want -> 0 when some reader might take the line as want
  case "$1" in
    *'#'*) return 1 ;;
    *"$2"*) ;;
    *) return 1 ;;
  esac
  case "$1" in *"$2"*[A-Za-z]*|*[A-Za-z]*"$2"*) return 1 ;; esac
}

# One pass of revoke, in the C locale. Checks the file holds no NUL byte, then
# reads it a line at a time, straight from the file, and drops every line
# _felix_autonomy_names matches. The bytes the lines account for are counted,
# and the count must come to the file's size: a loop that never ran, or a read
# cut short, is a file not read whole, never one with nothing to remove.
#   tmp "":   writes nothing; 5 something to remove (at the first such line),
#             4 nothing to remove
#   with tmp: writes every other line to tmp, each with the newline it had, so
#             an unended last line stays unended; 0 written, 4 nothing to remove
#   1 the file could not be read whole, or tmp could not be written
#   2 the file holds a NUL byte
#
# 2026-10-08, from the third review: the lines came from a here-string of the
# one read, and bash 3.2 writes a here-string to a temp file in /tmp or
# /var/tmp. When that write failed, the loop never ran and the pass said
# nothing to remove, so over a tidy<NBSP> line only older engines grant,
# revoke said "revoked: tidy" and left the line. And the kept text, built up in
# one string, made a revoke quadratic: 1 MB took 111 s of CPU.
_felix_autonomy_rewrite() {   # file want tmp
  local f="$1" want="$2" tmp="$3" size rc line end seen=0 hit=1 wrote=0 nl='
'
  _felix_autonomy_read "$f"; rc=$?
  [ "$rc" = 0 ] || return "$rc"
  # A read cut short mid-file also ends like the end of the file, and a NUL
  # past the cut would go unseen. In the C locale ${#…} counts bytes.
  #
  # wc's answer is checked as digits and never put through $(( )). 2026-10-08,
  # from the writer lock's third review and revoke's fifth: under bash 3.2, in
  # a script such as felix, a word in an arithmetic expansion stops the shell
  # under set -u, and the subshell exits with the status of the command before
  # the stop. A stale stdout buffer flushed into this wc made its answer
  # "revoked: tidy"; the stop left wc's 0, the pass read as written, and the mv
  # put an empty file over the grants.
  size="$(wc -c < "$f")" || return 1
  case "$size" in *[0-9]*) ;; *) return 1 ;; esac
  case "$size" in *[!0-9\ \	]*) return 1 ;; esac
  size="${size//[!0-9]/}"
  [ "$size" -eq "${#_felix_autonomy_text}" ] || return 1
  _felix_autonomy_text=""
  # Nothing may fork after this loop. When a printf to tmp fails, bash 3.2
  # keeps the unwritten tail in its buffer and flushes it into the next child,
  # where a $(…) would read file text as its answer.
  while :; do
    if IFS= read -r line; then end="$nl"
    elif [ -n "$line" ]; then end=""
    else break; fi
    seen=$(( seen + ${#line} + ${#end} ))
    if _felix_autonomy_names "$line" "$want"; then
      hit=0
      [ -n "$tmp" ] || break
    elif [ -n "$tmp" ]; then
      printf '%s%s' "$line" "$end" || { wrote=1; break; }
    fi
  done < "$f" > "${tmp:-/dev/null}"
  [ -n "$tmp" ] || [ "$hit" = 1 ] || return 5
  [ "$wrote" = 0 ] && [ "$seen" -eq "$size" ] || return 1
  [ "$hit" = 0 ] || return 4
}

felix_autonomy_allows() {
  local proj="$1" want="$2" line
  [ -n "$want" ] || return 1
  [ -f "$proj/autonomy" ] || return 1
  # The NUL check reads the whole file once, then the lines are read again and
  # the first grant answers. One line at a time, because splitting the text in
  # shell copies the rest of it per line, and that is quadratic on the hook
  # path: a 100 KB file took a minute at this machine's load.
  # A grant answers 10, not 0. Under bash 3.2, in a script such as felix, a
  # subshell that set -u stops in an arithmetic expansion exits with the status
  # of the command before the stop, often 0 (2026-10-08). The reader does no
  # arithmetic on what it reads, so it has no such stop; the 10 keeps one a
  # later change might add from reading as a grant.
  ( LC_ALL=C
    _felix_autonomy_read "$proj/autonomy" || exit 1
    while IFS= read -r line || [ -n "$line" ]; do
      _felix_autonomy_grants "$line" "$want" && exit 10
    done < "$proj/autonomy"
    exit 1 ) 2>/dev/null
  [ "$?" = 10 ]
}

# Take a grant back: rewrite the file without every line _felix_autonomy_names
# matches (every line any reader could take as that grant, and lines that only
# look like it), keeping every other byte, an unended last line unended. The
# caller says "revoked" only on 0.
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
# Decided: revoke removes every line a reader could count as the grant — the
# capability with whitespace of any kind, in any encoding, around it, CRs too —
# and with it any line holding the capability and no other letter or '#'. It
# keeps every other byte. Matching exactly instead would leave a revoke that
# cannot take back a grant a reader honours.
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
  # that is file text. The first pass writes nothing, not even a temp file, so
  # a revoke with nothing to remove needs no writable directory and leaves the
  # file as it was.
  #
  # A pass says it wrote with 10, never 0. 2026-10-08, from the writer lock's
  # third review: under bash 3.2, in a script such as felix, a subshell that
  # set -u stops in an arithmetic expansion exits with the status of the
  # command before the stop, and the pass's old $(( $(wc -c) )) stopped with
  # wc's 0, so the mv put an empty file over the grants. The pass now does no
  # arithmetic on text it reads, so it has no such stop; the 10 is kept for
  # any other. The first pass never writes, so a 0 from it is a refusal (its
  # empty tmp could not be moved in any case).
  ( LC_ALL=C; _felix_autonomy_rewrite "$f" "$want" "" ) > /dev/null 2>&1; rc=$?
  [ "$rc" != 0 ] || rc=1
  if [ "$rc" = 5 ]; then
    # mktemp creates the name or fails; it never opens a link planted there.
    tmp="$(mktemp "$f.new.XXXXXX" 2>/dev/null)" || return 1
    ( LC_ALL=C; _felix_autonomy_rewrite "$f" "$want" "$tmp" && exit 10 ) > /dev/null 2>&1; rc=$?
    case "$rc" in 10) rc=0 ;; 0) rc=1 ;; esac
  fi
  if [ "$rc" = 0 ]; then
    # mktemp made it 0600; give it the file's permission bits, or keep 0600.
    # BSD's %Lp leaves out setuid, setgid and sticky, which a grant file has no
    # use for.
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
