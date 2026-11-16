# The drop: one git bundle the authority's login can read, written by a worker's login.
#
# Trust-plane step 4, stage 1, the setup slice (0.49.351; P1 to P6 of its spec). `felix authority publish [--to
# DIR] [--from REPO]` is run by a worker's login, the founder's own today. It writes DIR/source.bundle, which the
# authority's login fetches as its `source` row and from which authority-engine copies the engine of a commit the
# founder names in full.
#
# THE DROP IS NOT TRUSTED, AND DOES NOT NEED TO BE (P6). Any worker can replace it. The authority reads it as
# input: each object is checked as it is fetched (fetch.fsckObjects), a commit it names counts only as the founder
# names it, and the one code run out of it is the engine of the commit he names by its whole id, whose bytes that
# id fixes. So nothing here checks who wrote the bundle, and DIR is left readable by every login on purpose.
#
# DIR IS THIS LOGIN'S TO WRITE, AND NO OTHER'S (H5, 0.49.354). P4 writes a name another login can know, then sets
# its mode and renames it, and chmod follows a link. So DIR must be this login's and writable by no group or other
# login, and each directory above it root's or this login's, or sticky: no other login can then put a link in
# its place, or own the drop's directory by making it first.
#
# THE ID IS NOT READ FROM HERE (H9, 0.49.354). origin-main: is this repository's refs/remotes/origin/main, which a
# worker can move with no push, printed by a worker's login. The commit the founder names at the authority's
# Terminal is read on his phone: the merged commit of the pull request whose number he fixed when he released it,
# all forty characters on the commit's own page. GitHub is not out of a worker's reach (Felix merges with his
# login's token), so the number he fixed, and not "the last one", is what names it.
#
# WHAT IT READS: the repository at REPO and nothing of the caller's git environment (each GIT_ variable is
# unset, as felix_authority_gitenv does, so REPO alone decides which repository is read). NOT READ: any
# authority's home or authority.conf; this command makes none and needs none.
#
# Bash 3.2. No project is named here.

# The rows of P3: each ref under refs/heads/, and refs/remotes/origin/main when it is there. No tag, no other
# remote's ref, no stash, no note: the authority's source-main is one of these two, and nothing else of a
# worker's repository is the authority's to hold. Printed as "ID REF", one a line.
_fap_refs() {   # REPO
  git -C "$1" for-each-ref --format='%(objectname) %(refname)' refs/heads/ refs/remotes/origin/main 2>/dev/null \
    | LC_ALL=C awk '{ r = substr($0, index($0, " ") + 1) } index(r, "refs/heads/") == 1 || r == "refs/remotes/origin/main"'
}

# H5. 0 when PATH carries an access-control entry that is not a deny: read where ls prints entries (ls -lde, a line
# that starts with a space, a number and a colon), and where ls takes no -e, a + as the mode's eleventh character.
_fap_acl() {   # PATH
  if ls -lde / >/dev/null 2>&1; then
    ls -lde "$1" 2>/dev/null | LC_ALL=C awk '/^ [0-9]+: / && $0 !~ / deny / { n++ } END { exit n ? 0 : 1 }'
  else
    ls -ld "$1" 2>/dev/null | LC_ALL=C awk 'substr($1, 11, 1) == "+" { n++ } END { exit n ? 0 : 1 }'
  fi
}
# H5. 0 when only this login (uid UID) can change DIR: its owner, no write by group or other, no entry that allows.
_fap_mine() {   # DIR UID
  [ -n "$(find "$1" -prune -user "$2" ! -perm -020 ! -perm -002 -print 2>/dev/null)" ] && ! _fap_acl "$1"
}
# H5. 0 when only root or this login can change a directory above DIR, or it has the sticky bit, and no entry allows.
# A link on the way is read for its owner, not its mode bits, which grant nothing (on Linux they are rwxrwxrwx).
_fap_above_ok() {   # DIR UID
  [ -n "$(find "$1" -prune \( -user 0 -o -user "$2" \) \( -type l -o \( ! -perm -020 ! -perm -002 \) -o -perm -1000 \) -print 2>/dev/null)" ] \
    && ! _fap_acl "$1"
}

# Returns 0 and prints P5's seven lines, or returns 1 or 2 with _FA_WHY (felix prints it after "felix: ").
# Every refusal comes before DIR is made and before anything is written in it.
felix_authority_publish() {   # DIR|"" REPO|""
  local to="$1" from="$2" up refs k main om sm tmp n shown me ups y p absent=0 LC_ALL=C
  local -a names=()
  _FA_WHY=""
  # P1. The directory: --to, or /Users/Shared/felix-authority where /Users/Shared is a directory.
  if [ -z "$to" ]; then
    [ -d /Users/Shared ] || { _FA_WHY="name the directory to publish to with --to"; return 2; }
    to=/Users/Shared/felix-authority
  fi
  case "$to" in /*) ;; *) _FA_WHY="--to names a directory that is not an absolute path"; return 1 ;; esac
  case "$to" in *[!\ -~]*) _FA_WHY="--to names a path with a byte outside printable ASCII"; return 1 ;; esac
  while :; do case "$to" in /) break ;; */) to="${to%/}" ;; *) break ;; esac; done
  up="${to%/*}"; [ -n "$up" ] || up=/
  if [ -e "$to" ] || [ -L "$to" ]; then
    [ -d "$to" ] && [ ! -L "$to" ] || { _FA_WHY="$(_fa_show "$to") is not a directory"; return 1; }
    # The authority's login reads the drop as "other": a directory it cannot read and search hides the drop.
    [ -n "$(find "$to" -prune -perm -005 2>/dev/null)" ] || { _FA_WHY="$(_fa_show "$to") cannot be read by another login"; return 1; }
  else
    absent=1
    [ -d "$up" ] || { _FA_WHY="$(_fa_show "$up") is not a directory"; return 1; }
  fi
  # H5. DIR, when it is there, is this login's alone; each directory above it, as written and physical, is root's
  # or this login's or sticky. When DIR is not there yet, the walk starts at its parent, which is. Whether DIR is
  # there is decided once, above (review trust 1): it is not looked at again before it is made.
  me="$(id -u 2>/dev/null)"
  case "$me" in ""|*[!0123456789]*) _FA_WHY="this login's uid could not be read"; return 1 ;; esac
  if [ "$absent" = 0 ]; then
    _fap_mine "$to" "$me" || { _FA_WHY="$(_fa_show "$to") can be written by another login"; return 1; }
    ups="$(_fa_above "$to")"
  else
    ups="$(printf '%s\n' "$up"; p="$(cd -P -- "$up" 2>/dev/null && pwd -P)" && printf '%s\n' "$p"; _fa_above "$up")"
  fi
  while IFS= read -r y; do
    [ -n "$y" ] || continue
    _fap_above_ok "$y" "$me" || { _FA_WHY="$(_fa_show "$y") can be written by another login"; return 1; }
  done <<EOF
$ups
EOF
  # P2. The repository: REPO, or the current directory. Shown as given, escaped by section 0's rule, as DIR is
  # (review F6).
  [ -n "$from" ] || from="$PWD"
  shown="$(_fa_show "$from")"
  git -C "$from" rev-parse --git-dir >/dev/null 2>&1 || { _FA_WHY="$shown is not inside a git repository"; return 1; }
  refs="$(_fap_refs "$from")"
  k="$(printf '%s\n' "$refs" | LC_ALL=C awk 'index($2, "refs/heads/") == 1 { n++ } END { print n + 0 }')"
  [ "$k" -gt 0 ] || { _FA_WHY="$shown has no branch to publish"; return 1; }
  main="$(printf '%s\n' "$refs" | LC_ALL=C awk '$2 == "refs/heads/main" { print $1; exit }')"
  om="$(printf '%s\n' "$refs" | LC_ALL=C awk '$2 == "refs/remotes/origin/main" { print $1; exit }')"
  while IFS= read -r n; do [ -z "$n" ] || names[${#names[@]}]="${n#* }"; done <<EOF
$refs
EOF
  # P1. Made one level, 755 whatever the umask: the authority's login reads it as another login. A DIR that was not
  # there when H5 read it is made by this one mkdir, which fails on anything at the name by then (a directory or a
  # link another login made after that read), and that failure is P4's refusal (review trust 1). mkdir -m sets the
  # mode by name just after it makes the directory (macOS); no other login can put anything at the name between
  # the two, because each directory above DIR is root's, this login's or sticky.
  if [ "$absent" = 1 ]; then
    mkdir -m 755 -- "$to" 2>/dev/null || { _FA_WHY="the bundle could not be written in $(_fa_show "$to")"; return 1; }
  fi
  # P4. Written whole under a name of this process's, then renamed: a reader sees the old bundle or the new one.
  # A directory (or a link to one) at source.bundle would take the rename into itself, so it is a failure to write.
  # git bundle writes through its own lock file beside the name it is given; both are removed on a failure.
  tmp="$to/.source.bundle.$$"
  if [ -d "$to/source.bundle" ] \
     || ! git -C "$from" bundle create -q "$tmp" "${names[@]}" >/dev/null 2>&1 \
     || ! chmod 644 "$tmp" 2>/dev/null || ! mv -f "$tmp" "$to/source.bundle" 2>/dev/null; then
    rm -f "$tmp" "$tmp.lock" 2>/dev/null
    _FA_WHY="the bundle could not be written in $(_fa_show "$to")"; return 1
  fi
  # P5.
  sm=-
  if [ -n "$om" ]; then sm=refs/remotes/origin/main; elif [ -n "$main" ]; then sm=refs/heads/main; fi
  n="$(wc -c < "$to/source.bundle" 2>/dev/null | tr -d ' ')"
  printf 'published: %s\nbytes: %s\nbranches: %s\nmain: %s\norigin-main: %s\nsource: %s\nsource-main: %s\n' \
    "$(_fa_show "$to/source.bundle")" "${n:-?}" "$k" "${main:--}" "${om:--}" "$(_fa_show "$to/source.bundle")" "$sm"
}
