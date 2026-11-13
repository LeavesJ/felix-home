# The authority that holds main: its parameters, its store's identity and its standing.
#
# Trust-plane step 4, stage 1, slice 1 (docs/2026-11-13-trust-step4-shadow-slice1.md; the hosted-authority design
# of 2026-11-09 and the door design of 2026-11-10). An authority is a store it alone writes, a judgement, and a
# record. This slice builds the store, the door that takes the founder's statements (lib/door.sh), the reading of
# them (lib/door-read.sh) and the decision for a candidate up to the judge (lib/authority-tick.sh). It lands
# nothing, in either standing.
#
# SHADOW IS THE DEFAULT, AND NOTHING READS IT. The founder's decision of 2026-11-13: the authority judges and
# records, but nothing it says counts and it holds nothing until it runs as its own login, the reach test has
# passed, and he has given the first start at that login's console. Until then the standing is `shadow`, each
# line it prints for a candidate starts with that word, and each statement kept says it was given in shadow and
# never counts. No code outside these four files reads the store, the log or the ledger to decide anything, so
# what a shadow authority says changes no merge. Under the founder's own login a worker can write every file
# here. That is why it is shadow, and no check in this file is a wall there.
#
# THE PARAMETERS (W1 to W3). One file, AH/authority.conf, one row a key: the key, a tab, the value. AH is
# $FELIX_AUTHORITY_HOME, or $HOME/.felix/authority. Moving the authority to another login is a change of these
# rows and of that variable. Nothing here takes the user, the home, the store or the door's directory from
# anywhere else. The file is read as data and never sourced.
#
# GIT (W10). felix_authority_gitenv gives each git this process runs no configuration, attributes or replacement
# from the caller, the user or the system. It changes the process's own environment, which is why only
# `felix authority` and `felix door` call it: they run nothing else afterwards.
#
# Bash 3.2. No project is named here.

FELIX_AUTH_KEYS='user workers source source-main store door lock'
FELIX_AUTH_ZERO=0000000000000000000000000000000000000000

felix_authority_home() { printf '%s' "${FELIX_AUTHORITY_HOME:-$HOME/.felix/authority}"; }

_fa_sha() { local LC_ALL=C; case "${1:-}" in ""|*[!0123456789abcdef]*) return 1 ;; esac; [ "${#1}" -eq 40 ]; }
_fa_login() { local LC_ALL=C; case "${1:-}" in ""|[!A-Za-z_]*|*[!A-Za-z0-9_.-]*) return 1 ;; esac; return 0; }
_fa_abs() { case "${1:-}" in /*) return 0 ;; esac; return 1; }
_fa_g() { git --git-dir="$_FA_STORE" "$@"; }

# W2. The rows of a configuration, from its text on stdin. Sets the _FA_* variables and returns 0, or returns 1
# with _FA_WHY. A value is printable ASCII, so a second tab in a row makes the file unreadable.
_fa_parse() {   # HOME <- text
  local line k v seen=" " w rest LC_ALL=C
  _FA_HOME="$1"; _FA_WHY=""
  _FA_USER=""; _FA_WORKERS=""; _FA_SOURCE=""; _FA_SRCMAIN="refs/heads/main"
  _FA_STORE="$_FA_HOME/store.git"; _FA_DOOR="$_FA_HOME/door"; _FA_LOCK=""
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in ""|"#"*) continue ;; esac
    case "$line" in *$'\t'*) ;; *) _FA_WHY="authority.conf holds a row with no tab"; return 1 ;; esac
    k="${line%%$'\t'*}"; v="${line#*$'\t'}"
    case " $FELIX_AUTH_KEYS " in *" $k "*) ;; *) _FA_WHY="authority.conf holds a key this engine does not know"; return 1 ;; esac
    case "$seen" in *" $k "*) _FA_WHY="authority.conf holds the key $k twice"; return 1 ;; esac
    seen="$seen$k "
    case "$v" in ""|*[!\ -~]*) _FA_WHY="authority.conf gives $k no value, or one with a byte outside printable ASCII"; return 1 ;; esac
    case "$k" in
      user)    _fa_login "$v" || { _FA_WHY="authority.conf names a user that is not a login name"; return 1; }; _FA_USER="$v" ;;
      workers) case "$v" in *[!A-Za-z0-9_.,-]*|,*|*,|*,,*) _FA_WHY="authority.conf names a worker that is not a login name"; return 1 ;; esac
               rest="$v,"
               while [ -n "$rest" ]; do
                 w="${rest%%,*}"; rest="${rest#*,}"
                 _fa_login "$w" || { _FA_WHY="authority.conf names a worker that is not a login name"; return 1; }
               done
               _FA_WORKERS="$v" ;;
      source)  _FA_SOURCE="$v" ;;
      source-main)
               case "$v" in refs/*) ;; *) _FA_WHY="authority.conf names a source-main that is not a ref"; return 1 ;; esac
               git check-ref-format "$v" 2>/dev/null || { _FA_WHY="authority.conf names a source-main that is not a ref"; return 1; }
               _FA_SRCMAIN="$v" ;;
      store)   _fa_abs "$v" || { _FA_WHY="authority.conf names a store that is not an absolute path"; return 1; }; _FA_STORE="$v" ;;
      door)    _fa_abs "$v" || { _FA_WHY="authority.conf names a door that is not an absolute path"; return 1; }; _FA_DOOR="$v" ;;
      lock)    _fa_abs "$v" || { _FA_WHY="authority.conf names a lock that is not an absolute path"; return 1; }; _FA_LOCK="$v" ;;
    esac
  done
  [ -n "$_FA_USER" ] || { _FA_WHY="authority.conf names no user"; return 1; }
  [ -n "$_FA_WORKERS" ] || { _FA_WHY="authority.conf names no workers"; return 1; }
  [ -n "$_FA_SOURCE" ] || { _FA_WHY="authority.conf names no source"; return 1; }
  return 0
}

# The parameters of the authority set up at AH. Returns 1 with _FA_WHY when there is none or its file is unreadable.
felix_authority_load() {
  local home f
  home="$(felix_authority_home)"; f="$home/authority.conf"; _FA_WHY=""
  _fa_abs "$home" || { _FA_WHY="the authority's home, $home, is not an absolute path"; return 1; }
  [ -f "$f" ] && [ ! -L "$f" ] || { _FA_WHY="no authority is set up at $home (felix authority init makes one)"; return 1; }
  _fa_parse "$home" < "$f" || return 1
  [ -d "$_FA_STORE" ] && [ ! -L "$_FA_STORE" ] || { _FA_WHY="the store, $_FA_STORE, is not a directory"; return 1; }
  return 0
}

# W10. Nothing of the caller's, the user's or the system's reaches a git this process runs from here on. The
# list is bind.sh's (git 2.56's variables that choose a repository, an object store, an index, replacement,
# config or a helper program), with the ones that choose a transport's program; one found later is added here.
felix_authority_gitenv() {
  local v
  unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_COMMON_DIR \
        GIT_NAMESPACE GIT_REPLACE_REF_BASE GIT_SHALLOW_FILE GIT_GRAFT_FILE GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT \
        GIT_EXEC_PATH GIT_EXTERNAL_DIFF GIT_CONFIG GIT_CONFIG_SYSTEM GIT_SSH GIT_SSH_COMMAND GIT_ASKPASS \
        GIT_PROXY_COMMAND GIT_ATTR_SOURCE GIT_TEMPLATE_DIR GIT_DEFAULT_HASH 2>/dev/null
  for v in ${!GIT_CONFIG_KEY_@} ${!GIT_CONFIG_VALUE_@}; do unset "$v"; done
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_ATTR_NOSYSTEM=1 GIT_NO_REPLACE_OBJECTS=1 \
         GIT_TERMINAL_PROMPT=0 LC_ALL=C LANGUAGE=C \
         GIT_AUTHOR_NAME=felix-authority GIT_AUTHOR_EMAIL=authority@felix.invalid \
         GIT_COMMITTER_NAME=felix-authority GIT_COMMITTER_EMAIL=authority@felix.invalid
  umask 077
}

# W5. The store's identity: the id of a blob made once, at init, from the system's random source.
felix_authority_id() {   # [STORE] -> 40 hex, or 1
  local id
  id="$(git --git-dir="${1:-$_FA_STORE}" rev-parse --verify --quiet refs/felix/identity 2>/dev/null)" || return 1
  _fa_sha "$id" || return 1
  [ "$(git --git-dir="${1:-$_FA_STORE}" cat-file -t "$id" 2>/dev/null)" = blob ] || return 1
  printf '%s' "$id"
}

# W4. Returns 0 with the id in _FA_ID, or 1 with _FA_WHY. Each refusal comes before the first write.
felix_authority_init() {   # USER WORKERS SOURCE SRCMAIN STORE DOOR LOCK (each "" for its default)
  local home text me w rest nonce id f
  home="$(felix_authority_home)"; f="$home/authority.conf"; _FA_WHY=""
  _fa_abs "$home" || { _FA_WHY="the authority's home, $home, is not an absolute path"; return 1; }
  [ ! -e "$f" ] && [ ! -L "$f" ] || { _FA_WHY="an authority is already set up at $home"; return 1; }
  text="$(printf 'user\t%s\nworkers\t%s\nsource\t%s\n' "$1" "$2" "$3"
          [ -z "$4" ] || printf 'source-main\t%s\n' "$4"
          [ -z "$5" ] || printf 'store\t%s\n' "$5"
          [ -z "$6" ] || printf 'door\t%s\n' "$6"
          [ -z "$7" ] || printf 'lock\t%s\n' "$7")"
  _fa_parse "$home" <<EOF || return 1
$text
EOF
  me="$(id -un 2>/dev/null)"
  [ "$_FA_USER" = "$me" ] || { _FA_WHY="this login is $me, not $_FA_USER: an authority is set up by the login it runs as"; return 1; }
  rest="$_FA_WORKERS,"
  while [ -n "$rest" ]; do
    w="${rest%%,*}"; rest="${rest#*,}"
    id -u "$w" >/dev/null 2>&1 || { _FA_WHY="$w is not a login of this machine"; return 1; }
  done
  if [ -e "$_FA_STORE" ] || [ -L "$_FA_STORE" ]; then
    [ -d "$_FA_STORE" ] && [ ! -L "$_FA_STORE" ] && [ -z "$(ls -A "$_FA_STORE" 2>/dev/null)" ] \
      || { _FA_WHY="the store's path, $_FA_STORE, exists and is not an empty directory"; return 1; }
  fi
  mkdir -p "$home" "$_FA_DOOR" && chmod 700 "$home" "$_FA_DOOR" || { _FA_WHY="$home could not be made"; return 1; }
  git init -q --bare "$_FA_STORE" >/dev/null 2>&1 && chmod 700 "$_FA_STORE" \
    && _fa_g symbolic-ref HEAD refs/heads/main || { _FA_WHY="the store could not be made at $_FA_STORE"; return 1; }
  # The store takes no push. Under another login the file system says so; this hook says so to a push by mistake
  # from the same login, which the file system would take.
  mkdir -p "$_FA_STORE/hooks" \
    && printf '#!/bin/sh\necho "this store takes no push: the authority alone writes it" >&2\nexit 1\n' > "$_FA_STORE/hooks/pre-receive" \
    && chmod 700 "$_FA_STORE/hooks/pre-receive" || { _FA_WHY="the store could not be closed to pushes"; return 1; }
  nonce="$(od -An -N16 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n')"
  [ "${#nonce}" -eq 32 ] || { _FA_WHY="the system's random source could not be read"; return 1; }
  id="$(printf 'felix-authority/v1\nnonce: %s\n' "$nonce" | _fa_g hash-object -w --stdin 2>/dev/null)" \
    && _fa_g update-ref refs/felix/identity "$id" "$FELIX_AUTH_ZERO" 2>/dev/null \
    || { _FA_WHY="the store's identity could not be written"; return 1; }
  printf '%s\n' "$text" > "$f.new.$$" && mv "$f.new.$$" "$f" || { _FA_WHY="$f could not be written"; return 1; }
  _FA_ID="$id"
}

# W6 a and b. Prints one line for each condition that does not hold; returns 0 when both hold.
felix_authority_own() {
  local me rest w p rc=0
  me="$(id -un 2>/dev/null)"
  if [ "$me" != "$_FA_USER" ]; then
    printf 'not its own login: this process runs as %s, and the authority'"'"'s user is %s\n' "${me:-?}" "$_FA_USER"; rc=1
  fi
  rest="$_FA_WORKERS,"
  while [ -n "$rest" ]; do
    w="${rest%%,*}"; rest="${rest#*,}"
    [ "$w" != "$_FA_USER" ] || { printf 'not its own login: %s is also a login workers run as\n' "$_FA_USER"; rc=1; }
  done
  for p in "$_FA_HOME" "$_FA_STORE" "$_FA_DOOR"; do
    [ -n "$(find "$p" -prune -user "$_FA_USER" ! -perm -020 ! -perm -002 2>/dev/null)" ] \
      || { printf 'not the authority'"'"'s alone: %s is not owned by %s, or someone else can write it\n' "$p" "$_FA_USER"; rc=1; }
  done
  return "$rc"
}

# W8. How a statement given now is given: shadow, console or desktop. The console is this machine with no
# process of a login workers run as: after a restart, before the founder logs in as himself. Where the
# processes cannot be listed the answer is desktop, the one that asks for more.
felix_authority_given() {
  local rest w uid
  felix_authority_own >/dev/null || { printf 'shadow'; return 0; }
  ps -o pid= -p "$$" >/dev/null 2>&1 || { printf 'desktop'; return 0; }
  rest="$_FA_WORKERS,"
  while [ -n "$rest" ]; do
    w="${rest%%,*}"; rest="${rest#*,}"
    uid="$(id -u "$w" 2>/dev/null)" || { printf 'desktop'; return 0; }
    [ -z "$(ps -U "$uid" -o pid= 2>/dev/null)" ] || { printf 'desktop'; return 0; }
  done
  printf 'console'
}

# W6. Sets _FA_STANDING (live or shadow) and _FA_WHYS (one line a reason). The log is read first by the caller
# (felix_door_log_read); a log that does not read back is one more reason.
felix_authority_standing() {
  local own
  _FA_STANDING=live; _FA_WHYS=""
  own="$(felix_authority_own)" || { _FA_STANDING=shadow; _FA_WHYS="$own"; }
  if [ -n "${_DL_BAD:-}" ]; then
    _FA_STANDING=shadow; _FA_WHYS="${_FA_WHYS:+$_FA_WHYS$'\n'}the door's log does not read back: statement $_DL_BAD"
    return 0
  fi
  if [ "${_DL_N:-0}" -eq 0 ] || [ "${_DL_VERB[0]}" != start ] || [ "${_DL_GIVEN[0]}" != console ]; then
    _FA_STANDING=shadow; _FA_WHYS="${_FA_WHYS:+$_FA_WHYS$'\n'}no first start at the console"
  fi
  if [ "${_DL_REACH:-0}" -ne 1 ]; then
    _FA_STANDING=shadow; _FA_WHYS="${_FA_WHYS:+$_FA_WHYS$'\n'}the reach test has not passed"
  fi
  return 0
}

# `felix authority status`. The caller has loaded the parameters and read the log.
felix_authority_status() {
  local id main why word
  id="$(felix_authority_id)" || id="-"
  felix_authority_standing
  printf 'authority: %s\nstanding: %s\n' "$id" "$_FA_STANDING"
  while IFS= read -r why; do [ -z "$why" ] || printf 'why: %s\n' "$why"; done <<EOF
$_FA_WHYS
EOF
  main="$(_fa_g rev-parse --verify --quiet refs/heads/main 2>/dev/null)" || main="-"
  word=go; [ -z "$(felix_word_stop)" ] || word=stop
  printf 'user: %s\nworkers: %s\nhome: %s\nstore: %s\ndoor: %s\nsource: %s\nsource-main: %s\nlock: %s\nmain: %s\nstatements: %s\nword: %s\n' \
    "$_FA_USER" "$_FA_WORKERS" "$_FA_HOME" "$_FA_STORE" "$_FA_DOOR" "$_FA_SOURCE" "$_FA_SRCMAIN" "${_FA_LOCK:--}" \
    "$main" "${_DL_N:-0}" "$word"
}
