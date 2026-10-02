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
# [[:space:]], and what that matches depends on the caller's locale. Under a
# UTF-8 locale it takes U+00A0 (Option-Space), U+2003 and a lone \240 byte;
# under C it takes none of them. So "tidy<NBSP>" was a grant to a UTF-8
# session-start and not to a C one, and a revoke run under C said "revoked:
# tidy" over a line the next UTF-8 session still tidied by. bash 5.2's read
# also swallows the newline after a stray UTF-8 lead byte in a UTF-8 locale,
# hiding the next line inside a comment. And a NUL byte ends a line on bash 3.2
# but is skipped on 5.2, so "tidy\0x" was a grant to one and not the other.
#
# So the file is read in the C locale, in one read, and a file holding a NUL
# grants nothing: lines are bytes split on newline, and only ASCII whitespace
# (space, tab, CR, VT, FF) is trimmed. The locale is set inside a subshell so
# it binds this read and nothing of the caller's. Narrowing the UTF-8 reading
# fails closed: a grant typed with a non-ASCII space is shown [ ] and no
# longer acts.

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

# Every line of _felix_autonomy_text that does not grant want, byte for byte
# and in order, into _felix_autonomy_kept; an unended last line stays unended.
# 0 when some line granted want. The reader and revoke both go through this.
_felix_autonomy_filter() {   # want -> 0 when a line grants want
  local rest="$_felix_autonomy_text" line hit=1 nl='
'
  _felix_autonomy_kept=""
  while [ -n "$rest" ]; do
    case "$rest" in
      *"$nl"*) line="${rest%%"$nl"*}"; rest="${rest#*"$nl"}"
               if _felix_autonomy_grants "$line" "$1"; then hit=0
               else _felix_autonomy_kept="$_felix_autonomy_kept$line$nl"; fi ;;
      *)       line="$rest"; rest=""
               if _felix_autonomy_grants "$line" "$1"; then hit=0
               else _felix_autonomy_kept="$_felix_autonomy_kept$line"; fi ;;
    esac
  done
  return "$hit"
}

felix_autonomy_allows() {
  local proj="$1" want="$2"
  [ -n "$want" ] || return 1
  [ -f "$proj/autonomy" ] || return 1
  ( LC_ALL=C
    _felix_autonomy_read "$proj/autonomy" || exit 1
    _felix_autonomy_filter "$want" ) 2>/dev/null
}

# Take a grant back: rewrite the file without every line the reader counts as
# that grant, keeping every other byte. The caller says "revoked" only on 0.
#   0  no line grants cap now (or there was no file to grant anything)
#   1  the file could not be read whole, or the rewrite could not be written
#   2  the file holds a NUL byte, so what it grants cannot be read
#   3  rewritten, and a read of it still finds the grant
#
# 2026-10-01: this was `grep -vxF cap autonomy > autonomy.new && mv` in
# cmd_autonomy. grep exits 1 when it selects no line, so a file holding the
# grant alone kept it — the && skipped the mv — while the command printed
# "revoked:" and deleted the stamp, and left autonomy.new behind. An unreadable
# file did the same through grep's exit 2. And grep matched whole lines
# exactly where the reader trims, so a hand-edited "commission " stayed granted
# after a revoke that said otherwise.
#
# Decided: revoke removes exactly the lines the reader counts as the grant —
# trailing and leading ASCII whitespace included, CRs too — and keeps every
# other byte. Matching exactly instead would leave a revoke that cannot take
# back a grant the reader honours.
#
# Not covered: two felix autonomy runs at once. Nothing locks the file, so the
# later mv can put back what the earlier one removed, after it said so. Only a
# person writes this file, by typing the command; the lock is its own change.
felix_autonomy_revoke() {
  local proj="$1" want="$2" f tmp rc
  [ -n "$want" ] || return 1
  f="$proj/autonomy"
  # The reader takes nothing from what is not a regular file.
  [ -f "$f" ] || return 0
  # mktemp creates the name or fails; it never opens a link planted there.
  tmp="$(mktemp "$f.new.XXXXXX" 2>/dev/null)" || return 1
  # Its own C locale, and its stdout thrown away: bash 3.2's printf can leave
  # the unwritten tail of a failed write in its buffer, and that is file text.
  ( LC_ALL=C
    _felix_autonomy_read "$f"; rc=$?
    [ "$rc" = 0 ] || exit "$rc"
    # A read cut short mid-file also ends like the end of the file. The byte
    # count is the check: in the C locale ${#…} counts bytes.
    [ "$(( $(wc -c < "$f") ))" -eq "${#_felix_autonomy_text}" ] || exit 1
    _felix_autonomy_filter "$want"
    printf '%s' "$_felix_autonomy_kept" > "$tmp" || exit 1
  ) > /dev/null 2>&1; rc=$?
  if [ "$rc" != 0 ] || ! mv -f "$tmp" "$f" 2>/dev/null; then
    rm -f "$tmp" 2>/dev/null
    [ "$rc" = 2 ] && return 2
    return 1
  fi
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
