# Preflight: the facts a repository cannot hold.
#
# From a real incident on a governed project, four days before its first
# launch. A security audit found a python http.server bound to every interface
# for fifty-five hours serving a home directory, a .env at mode 644, a service
# started without its key, and no request ceiling. Exactly one of those —
# secrets in git history — is visible to something reading the repository, and
# the gate already checked it and correctly found none.
#
# The first reading was "we were sloppy; we should have run the scanners
# first". That is not what happened, and it matters because the wrong lesson
# buys nothing. Static analysis matches patterns that are PRESENT in code.
# A process somebody started by hand is not in the code. A filesystem mode is
# not in the code. A missing rate limit is the ABSENCE of a pattern, which is
# not a thing a matcher can find. Those are facts about the machine, and no
# amount of scanning a repository will ever surface one.
#
# So this is not a scanner and does not try to be. It is the short list of
# machine facts that have actually bitten, checked on the machine that will
# serve, in bash, with no network and no model.
#
# `felix ready` asks whether the tools a session may reach for are usable.
# This asks whether the machine is safe to serve from. The names are close
# and the questions are not related.
#
# It reports and never acts. A listening process is somebody's work, and a
# mode that looks wrong may be load-bearing for a service running as another
# user. `--fix` is where a person says otherwise, and it tightens modes only:
# nothing here ever kills a process.

# Is a listener worth a person's attention? Prints the reason, or nothing.
#
# Pure, and separated from the collection below for one reason: lsof output is
# not something a fixture can produce, so a check built as one long pipeline
# would be untestable and would therefore be trusted without evidence.
#
# The rule is not "bound broadly", which would report Spotify, AirPlay and the
# Rapport daemon on any Mac and teach the reader to skim. It is bound broadly
# AND serving from inside the home — measured on this machine, every
# legitimate broad listener runs from `/`, and the incident's did not. Serving
# your own files to the network is never infrastructure; it is always somebody
# having forgotten.
felix_preflight_judge() {
  local addr="$1" cwd="$2" home="$3"
  [ -n "$addr" ] && [ -n "$cwd" ] && [ -n "$home" ] || return 0
  case "$addr" in
    127.0.0.1:*|'[::1]:'*|localhost:*) return 0 ;;
  esac
  # The trailing slash is the boundary: a sibling directory whose name merely
  # begins with the same characters is a different directory.
  case "$cwd" in
    "$home") ;;
    "$home"/*) ;;
    *) return 0 ;;
  esac
  printf 'serving %s to %s\n' "$cwd" "$addr"
}

# Every listener on a non-loopback address, with the directory it is serving.
# Emits: command <TAB> pid <TAB> address <TAB> cwd
#
# Silent where lsof is absent or answers nothing, which is a normal answer on
# a machine that serves nothing rather than an error.
felix_preflight_listeners() {
  command -v lsof >/dev/null 2>&1 || return 0
  local pid cmd addr cwd
  lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null \
    | awk 'NR > 1 { print $1 "\t" $2 "\t" $9 }' \
    | LC_ALL=C sort -u \
    | while IFS=$'\t' read -r cmd pid addr; do
        [ -n "${pid:-}" ] || continue
        cwd="$(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null \
               | grep '^n' | head -1 | cut -c2-)"
        printf '%s\t%s\t%s\t%s\n' "$cmd" "$pid" "$addr" "${cwd:-?}"
      done
  return 0
}

# Secret-bearing files any group or the world can read.
# Emits: mode <TAB> path
#
# Found with `find` rather than `git ls-files`, and that is the whole point:
# .env is gitignored precisely so it never enters the tree, which is why the
# repository cannot answer this question about itself.
#
# Vendored dependency trees are skipped. Somebody else's node_modules is not
# this project's exposure, and walking it turns a one-second check into a
# minute-long one that people stop running.
felix_preflight_modes() {
  local root="$1" f mode m g o
  [ -d "$root" ] || return 0
  # `.claude` is pruned with the vendored trees, and for a sharper reason: it
  # holds nested worktrees, which are separate checkouts of the same project
  # with their own preflight. Run against a real repository the first version
  # of this returned eighteen findings, seventeen of them one template copied
  # across worktrees — a report that floods on its first run is one nobody
  # reads twice.
  #
  # Templates are excluded by name. `.env.example` is committed on purpose,
  # holds placeholders, and is meant to be readable; calling it an exposure is
  # how the signal drowns.
  find "$root" \
       \( -name .git -o -name .claude -o -name node_modules -o -name vendor \
          -o -name .venv -o -name venv -o -name target -o -name dist \) -prune -o \
       -type f \( -name '.env' -o -name '.env.*' -o -name '*.pem' \
                  -o -name '*.key' -o -name 'id_rsa' -o -name 'id_ed25519' \
                  -o -name '*.p12' -o -name '*.keystore' \) \
       ! -name '*.example' ! -name '*.sample' ! -name '*.template' \
       ! -name '*.dist' -print 2>/dev/null \
  | while IFS= read -r f; do
      [ -f "$f" ] || continue
      mode="$(stat -f '%Lp' "$f" 2>/dev/null || stat -c '%a' "$f" 2>/dev/null)"
      [ -n "$mode" ] || continue
      # Group and other, read bit only. The owner's own bits are not the
      # question, and a setuid mode arrives as four digits, so the last three
      # are taken by trimming rather than by a negative offset that bash 3.2
      # does not support.
      m="$mode"
      while [ "${#m}" -gt 3 ]; do m="${m#?}"; done
      while [ "${#m}" -lt 3 ]; do m="0$m"; done
      g="${m:1:1}"; o="${m:2:1}"
      case "$g$o" in
        *[4-7]*) printf '%s\t%s\n' "$mode" "$f" ;;
      esac
    done
  return 0
}
