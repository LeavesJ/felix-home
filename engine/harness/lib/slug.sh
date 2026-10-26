# The GitHub slug of a checkout, and nothing else.
#
# Until audit b19 (C096) this was a sed over the remote that cut everything through
# the last github.com[: /] and kept the rest. A remote that was not GitHub passed
# through almost unchanged, an ssh alias for GitHub (git@github-work:acme/app.git)
# among them, so every `[ -n "$slug" ] || die "no github remote"` guard in the CLI
# was bypassed: gh was handed --repo git@github-work:acme/app and failed with a
# diagnosis that never mentioned the remote. A remote is read for what it is now,
# and what is not a GitHub repository has no slug.
#
# The forms git takes are scheme://[user@]host[:port]/path, for https, http, git
# and ssh, and scp-like [user@]host:path with no slash before the colon. The host
# is GitHub when it is github.com, www.github.com or ssh.github.com, in any case.
# In an ssh or scp form any other host may be an alias from the person's ssh
# config, the usual way to keep two GitHub accounts' keys apart, and `ssh -G`
# says what it stands for: it prints the configuration ssh would use, reads only
# local files and connects to nothing, and CanonicalizeHostname is turned off on
# its command line because canonicalising is a DNS lookup. It is never asked for
# the other forms, for a host that is already GitHub, or for one that is not a
# plain hostname (a remote cannot hand ssh an option). A local path ending
# github.com/OWNER/NAME, as an absolute path or a file:// URL, is the fixture
# shape the suite's remotes have, and a slug too.
#
# The path is exactly OWNER/NAME after trailing slashes and then one .git are
# taken off, each made of letters, digits, dot, underscore and hyphen; OWNER does
# not begin with a hyphen or a dot, NAME not with a hyphen and is not . or .. .
# The case of the path is kept. It is spliced into commands bash runs, which is
# why it is accepted only in the shape a GitHub owner/name has. Prints OWNER/NAME
# and a newline, or nothing, and returns 0 either way: the remote is read once.
_felix_slug_ok() {
  local ok="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-"
  [ -n "$1" ] && [ -n "$2" ] || return 1
  case "$1" in -*|.*) return 1 ;; esac
  case "$2" in -*|.|..) return 1 ;; esac
  case "$1$2" in *[!$ok]*) return 1 ;; esac
  return 0
}

felix_repo_slug() {
  local u host path o n g q ssh=0 real="" lh ok="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-"
  u="$(git -C "${1:-$PWD}" remote get-url origin 2>/dev/null)" || return 0
  case "$u" in
    https://*|http://*|git://*|ssh://*)
      case "$u" in ssh://*) ssh=1 ;; esac
      path="${u#*://}"; host="${path%%/*}"
      case "$path" in */*) path="${path#*/}" ;; *) return 0 ;; esac
      host="${host##*@}"; host="${host%%:*}" ;;
    /*|file:///*)
      path="${u#file://}"
      while :; do case "$path" in */) path="${path%/}" ;; *) break ;; esac; done
      path="${path%.git}"
      n="${path##*/}"; q="${path%/*}"; o="${q##*/}"; q="${q%/*}"; g="${q##*/}"
      [ "$g" = github.com ] && _felix_slug_ok "$o" "$n" && printf '%s/%s\n' "$o" "$n"
      return 0 ;;
    *://*|/*) return 0 ;;
    *:*)
      host="${u%%:*}"
      case "$host" in */*) return 0 ;; esac
      ssh=1; path="${u#*:}"; host="${host##*@}" ;;
    *) return 0 ;;
  esac
  case "$host" in ''|-*|*[!$ok]*) return 0 ;; esac
  lh="$(printf '%s' "$host" | LC_ALL=C tr 'A-Z' 'a-z')"
  case "$lh" in
    github.com|www.github.com|ssh.github.com) ;;
    *)
      [ "$ssh" -eq 1 ] && command -v ssh >/dev/null 2>&1 || return 0
      # awk reads all of ssh's output rather than exiting on the first match, so
      # ssh is never killed mid-write: under pipefail a SIGPIPE'd producer turns
      # the whole pipeline's status to 141.
      real="$(ssh -G -o CanonicalizeHostname=no "$host" </dev/null 2>/dev/null \
              | LC_ALL=C awk '$1 == "hostname" && !s { print $2; s = 1 }' | LC_ALL=C tr 'A-Z' 'a-z')" || real=""
      case "$real" in github.com|www.github.com|ssh.github.com) ;; *) return 0 ;; esac ;;
  esac
  while :; do case "$path" in */) path="${path%/}" ;; *) break ;; esac; done
  path="${path%.git}"
  case "$path" in */*) ;; *) return 0 ;; esac
  o="${path%%/*}"; n="${path#*/}"
  case "$n" in */*) return 0 ;; esac
  _felix_slug_ok "$o" "$n" && printf '%s/%s\n' "$o" "$n"
  return 0
}
