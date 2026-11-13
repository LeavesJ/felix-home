# The founder's door: where he gives one statement to the authority, at the authority's own desktop.
#
# Trust-plane step 4, stage 1, slice 1 (lib/authority.sh says what the slice is; the door design of 2026-11-10,
# section 5, is the door he chose). `felix door` reads back what stands, lists what waits on his word, takes a
# verb and what it is about, prints the statement and the card, takes a typed confirmation, keeps the statement
# as the next entry of the log, and runs the lock. One run gives at most one statement.
#
# NO KEY, NO NETWORK, NOTHING HANDED IN. A statement carries no signature and says so. What stands behind one
# is that this desktop was unlocked and that this code ran there. The door refuses to open under a network
# login. The open statement lives in this process and nowhere else: there is no file a second process could
# write, replace or leave behind, and a second door that keeps a statement first makes this one's keep fail.
#
# THE DOOR WRITES THE STATEMENT (D8). No field comes from outside: the verb is one of eight, the commit is one
# the store holds, the tree is the merge this code made, and what he types is compared with the statement and
# is never read as a field of it. There is one try (the door design's decision 17), and the place of the
# brackets comes from the statement's nonce, so it is not known before the card (decision 16): with the
# brackets in one known place a worker made a commit whose id agreed with his there in tens of thousands of tries.
#
# THE CARD (D5). The authority's facts first, each on a line whose label this code wrote. Each founder path is
# listed whole, before any other path and never cut. Each word a worker chose (a path, a branch name, a commit
# subject) is shown escaped and quoted (lib/authority-paths.sh), so no byte of a worker's starts a line or
# moves the cursor. One function, _fdoor_card, makes the card from the store; the terminal is one way to draw
# it (D11).
#
# WHAT IS NOT HERE: telling a genuine login window from a drawn one, a signature of his, and a lock known to
# work on this macOS. `lock` is a parameter because how a desktop is locked from bash was not read for this
# system. Where it is unset or fails the door says NOT LOCKED.
#
# Bash 3.2. No project is named here.

_fdoor_effect() {
  case "$1" in
    start)     printf 'main starts from this commit' ;;
    hold)      printf 'holds each candidate whose history holds this commit, and takes back an authorization or an override of it that you gave before' ;;
    release)   printf 'passes over the holds you gave before now on this exact head' ;;
    authorize) printf 'the authority may land this exact head once, if its judge passes' ;;
    override)  printf 'LANDS THIS EXACT HEAD ONCE WITH NO JUDGE, as the tree named below and no other' ;;
    stop)      printf 'nothing lands until you say go' ;;
    go)        printf 'landing goes on' ;;
    reach)     printf 'records the result of the reach test: after a pass, statements given at this desktop by a switch count' ;;
  esac
}

# W8, for the card: whether a statement given now, this way, counts.
_fdoor_counts() {   # GIVEN
  case "$1" in
    console) printf 'yes' ;;
    desktop) if [ "${_DL_REACH:-0}" -eq 1 ]; then printf 'yes'
             else printf 'no: the reach test has not passed, so nothing given by a switch counts'; fi ;;
    *)       printf 'no: this authority is in shadow, and nothing said in shadow counts' ;;
  esac
}

# D5. The card for VERB about HEAD (or - for a verb that names none). Prints it; sets _FDC_TREE to the tree
# the head would land as, or to nothing.
_fdoor_card() {   # VERB HEAD GIVEN [RESULT WITNESS]
  local verb="$1" h="$2" b="$_FA_MAIN" t="" mt rc btree from="" i listed=0 r hh br
  _FDC_TREE=""
  printf 'effect: %s\n' "$(_fdoor_effect "$verb")"
  printf 'counts: %s\n' "$(_fdoor_counts "$3")"
  if [ "$verb" = reach ]; then printf 'result: %s\nwitness-record: %s\n' "${4:--}" "${5:--}"; fi
  [ "$h" != - ] || return 0
  printf 'commit: %s\n' "$h"
  if [ -z "$b" ]; then
    printf 'main-shown: -\nlands-as: main starts from this commit\n'
  else
    printf 'main-shown: %s\n' "$b"
    mt="$(_fa_g --attr-source="$_FA_EMPTY" merge-tree --write-tree --no-messages "$b" "$h" 2>/dev/null)"; rc=$?
    t="${mt%%$'\n'*}"; btree="$(_fa_g rev-parse --verify --quiet "$b^{tree}" 2>/dev/null)"
    if [ "$rc" -ne 0 ] || ! _fa_sha "$t" || ! _fa_g cat-file -e "$t^{tree}" 2>/dev/null; then
      printf 'lands-as: nothing, as it stands: it conflicts with main\n'
      t="$(_fa_g rev-parse --verify --quiet "$h^{tree}" 2>/dev/null)"
      from="$(_fa_g merge-base "$b" "$h" 2>/dev/null)" && from="$from^{tree}" || from="$_FA_EMPTY"
    elif [ "$t" = "$btree" ]; then
      printf 'lands-as: nothing: it changes nothing\n'
    else
      printf 'lands-as: tree %s\n' "$t"; _FDC_TREE="$t"
    fi
    felix_authority_paths "$b" "$t" "$from"
    [ "$_FP_UNREADABLE" -ne 1 ] || printf 'policy: the founder-path policy at main cannot be read, so each path is taken as yours\n'
    [ "$_FP_UNREADABLE" -ne 2 ] || printf 'policy: the paths this change touches could not be listed\n'
    printf 'founder-paths-changed: %s\n' "$_FP_NF"
    for (( i = 0; i < _FP_NF; i++ )); do printf 'founder-path: %s\n' "$(_fa_esc "${_FP_FOUNDER[$i]}")"; done
    for (( i = 0; i < _FP_NO && i < 20; i++ )); do printf 'path: %s\n' "$(_fa_esc "${_FP_OTHER[$i]}" 200)"; listed=$((listed + 1)); done
    printf 'paths-changed: %s (not listed above: %s)\n' "$((_FP_NF + _FP_NO))" "$((_FP_NO - listed))"
    felix_authority_decide "$h"
    printf 'decision: %s %s\n' "$_FD_DECISION" "$_FD_DETAIL"
  fi
  while IFS=' ' read -r hh r; do
    [ "$hh" = "$h" ] || continue
    br="${r#refs/remotes/src/}"
    printf 'carried-by: branch %s (the worker'"'"'s word)\n' "$(_fa_esc "$br" 200)"
  done <<EOF
$(_fa_g for-each-ref --format='%(objectname) %(refname)' refs/remotes/src/ 2>/dev/null)
EOF
  printf 'commit-subject: %s (the worker'"'"'s word)\n' "$(_fa_esc "$(_fa_g log -1 --format=%s "$h" 2>/dev/null)" 200)"
}

# D2. What stands, read back before anything is asked.
_fdoor_readback() {   # GIVEN
  local why i s from
  printf 'FELIX DOOR  authority %s\n' "$_FA_ID"
  printf 'standing: %s\n' "$_FA_STANDING"
  if [ "$_FA_STANDING" = shadow ]; then
    # What the authority says counts for nothing in shadow (W7). What he says is another question (W8): a
    # statement given at the console counts, and the first start and the reach result are given exactly so.
    if [ "$1" = shadow ]; then
      printf 'SHADOW: this authority holds nothing, nothing it decides counts, and nothing said here counts\n'
    else
      printf 'SHADOW: this authority holds nothing and nothing it decides counts; a statement given here is kept, and its card says whether it counts\n'
    fi
    while IFS= read -r why; do [ -z "$why" ] || printf 'SHADOW why: %s\n' "$why"; done <<EOF
$_FA_WHYS
EOF
  fi
  printf 'given: a statement given now is given at: %s\n' "$1"
  printf 'main: %s\n' "${_FA_MAIN:--}"
  s="$(felix_word_stop)"
  if [ -n "$s" ]; then printf 'word: stop (statement %s)\n' "$s"; else printf 'word: go\n'; fi
  printf 'statements: %s\n' "$_DL_N"
  from=$((_DL_N - 5)); [ "$from" -ge 0 ] || from=0
  for (( i = from; i < _DL_N; i++ )); do
    printf 'statement: %s %s %s given %s at %s\n' "$i" "${_DL_VERB[$i]}" "${_DL_COMMIT[$i]}" "${_DL_GIVEN[$i]}" "${_DL_AT[$i]}"
  done
  for (( i = 0; i < _DL_N; i++ )); do
    [ "${_DL_READ[$i]}" = 1 ] || continue
    case "${_DL_VERB[$i]}" in authorize|override) ;; *) continue ;; esac
    _fw_hold "${_DL_COMMIT[$i]}"
    [ -z "$_FW_HOLD" ] || [ "$i" -gt "$_FW_HOLD" ] || continue
    if [ "${_DL_VERB[$i]}" = override ]; then
      printf 'in-effect: %s override %s as tree %s\n' "$i" "${_DL_COMMIT[$i]}" "${_DL_TREE[$i]}"
    else
      printf 'in-effect: %s authorize %s\n' "$i" "${_DL_COMMIT[$i]}"
    fi
  done
}

# D3. What waits on his word, numbered. Sets _FDI (an array of heads) and _FDI_N.
_fdoor_list() {
  local h br other=0 cands
  _FDI=(); _FDI_N=0
  if [ -z "$_FA_MAIN" ]; then
    printf 'waiting: this authority has no main yet; the first statement is the first start: start COMMIT\n'
    return 0
  fi
  [ -n "$(felix_word_stop)" ] && printf 'waiting: you have said stop, so nothing lands; what follows is what the store holds\n'
  cands="$(felix_authority_candidates)"
  while IFS=$'\t' read -r h br; do
    [ -n "$h" ] || continue
    # What waits on him is listed under a stop too: the list reads each head as if he had said go.
    _FD_NOSTOP=1; felix_authority_decide "$h"; _FD_NOSTOP=""
    case "$_FD_DECISION" in
      waits|held) _FDI[$_FDI_N]="$h"; _FDI_N=$((_FDI_N + 1))
                  printf 'item: %s %s %s branch %s\n' "$_FDI_N" "$h" "$_FD_DECISION" "$(_fa_esc "$br" 200)" ;;
      *) other=$((other + 1)) ;;
    esac
  done <<EOF
$cands
EOF
  printf 'items: %s waiting on your word; other candidates: %s\n' "$_FDI_N" "$other"
}

# D10. The lock, after a kept statement.
_fdoor_lock() {
  if [ -z "$_FA_LOCK" ]; then printf 'NOT LOCKED: no lock is set, so this desktop is still open; lock it yourself\n'
  elif [ ! -x "$_FA_LOCK" ] || [ -d "$_FA_LOCK" ]; then printf 'NOT LOCKED: the lock that is set cannot be run; lock this desktop yourself\n'
  elif "$_FA_LOCK" </dev/null >/dev/null 2>&1; then printf 'locked\n'
  else printf 'NOT LOCKED: the lock that is set failed; lock this desktop yourself\n'; fi
}

# D4. A witness record: a plain file under AH/reach/, of a megabyte at most.
_fdoor_record() {   # PATH -> 0 when it is one
  local p="$1"
  case "$p" in "$_FA_HOME/reach/"*) ;; *) return 1 ;; esac
  case "$p" in */../*|*/..|*/./*) return 1 ;; esac
  [ -f "$p" ] && [ ! -L "$p" ] && [ ! -L "$_FA_HOME/reach" ] || return 1
  [ "$(LC_ALL=C wc -c < "$p" | tr -d ' ')" -le 1048576 ]
}

# `felix door`. Returns 0 when a statement was kept, 1 when none was.
felix_door() {
  local ttl="${FELIX_DOOR_TTL:-120}" given line verb what extra h="-" t="-" result="-" witness="-" record=""
  local card cardid nonce at stmt want o tree c n LC_ALL=C
  case "$ttl" in ""|*[!0123456789]*|0) ttl=120 ;; esac
  # D1. No road in from the network.
  if [ -n "${SSH_CONNECTION:-}" ] || [ -n "${SSH_TTY:-}" ]; then
    printf 'refused: this door opens at the authority'"'"'s own desktop, and this is a network login\n'; return 1
  fi
  felix_authority_open || { printf 'felix: %s\n' "$_FA_WHY" >&2; return 1; }
  [ -z "$_DL_BAD" ] || { printf 'refused: the door'"'"'s log does not read back: statement %s\n' "$_DL_BAD"; return 1; }
  given="$(felix_authority_given)"
  felix_authority_fetch || printf 'source: the source could not be read; what follows is what the store holds\n'
  felix_authority_main || :
  _fdoor_readback "$given"
  _fdoor_list
  printf 'say: one verb and what it is about (start COMMIT, hold WHAT, release WHAT, authorize WHAT, override WHAT, stop, go, reach pass RECORD, reach fail RECORD)\n'
  IFS= read -r -t "$ttl" line || { printf 'refused: nothing was said; no statement was given\n'; return 1; }
  case "$line" in ""|*[!\ -~]*) printf 'refused: that line is empty or holds a byte outside printable ASCII\n'; return 1 ;; esac
  read -r verb what extra <<EOF
$line
EOF
  case " $FELIX_DOOR_VERBS " in *" $verb "*) ;; *) printf 'refused: %s is not a verb this door knows\n' "$(_fa_esc "$verb" 40)"; return 1 ;; esac
  if [ "$_DL_N" -eq 0 ] && [ "$verb" != start ]; then printf 'refused: the first statement is the first start\n'; return 1; fi
  if [ "$_DL_N" -gt 0 ] && [ "$verb" = start ]; then printf 'refused: the first start was given, and main starts once\n'; return 1; fi
  case "$verb" in
    stop|go)
      [ -z "$what" ] || { printf 'refused: %s names nothing\n' "$verb"; return 1; } ;;
    reach)
      result="$what"; record="$extra"
      case "$result" in pass|fail) ;; *) printf 'refused: a reach result is pass or fail\n'; return 1 ;; esac
      if [ "$result" = pass ] && [ "$given" != console ]; then
        printf 'refused: a reach result that passes is given at the console, where no login of a worker is open\n'; return 1
      fi
      if [ "$record" = - ] && [ "$result" = fail ]; then :
      elif _fdoor_record "$record"; then
        witness="$(_fa_g hash-object -w --no-filters -- "$record" 2>/dev/null)" && _fa_sha "$witness" \
          || { printf 'refused: the witness record could not be read\n'; return 1; }
      else printf 'refused: a reach result names a witness record, a plain file under %s\n' "$_FA_HOME/reach/"; return 1; fi ;;
    *)
      [ -z "$extra" ] || { printf 'refused: %s names one thing\n' "$verb"; return 1; }
      case "$what" in
        ""|*[!0123456789abcdef]*) printf 'refused: %s names a commit, by its whole id or by its number in the list\n' "$verb"; return 1 ;;
      esac
      if [ "${#what}" -eq 40 ]; then h="$what"
      elif [ "${#what}" -le 4 ] && case "$what" in *[!0123456789]*) false ;; esac && [ "$what" -ge 1 ] && [ "$what" -le "$_FDI_N" ]; then
        h="${_FDI[$((10#$what - 1))]}"
      else printf 'refused: there is no such item in the list\n'; return 1; fi
      [ "$(_fa_g rev-parse --verify --quiet "$h^{commit}" 2>/dev/null)" = "$h" ] \
        || { printf 'refused: that names no commit this authority holds\n'; return 1; } ;;
  esac
  if [ "$given" = desktop ] && [ -z "$_FA_LOCK" ]; then
    printf 'refused: no lock is set, so one unlock would give more than one statement\n'; return 1
  fi
  card="$(_fdoor_card "$verb" "$h" "$given" "$result" "$witness")"
  # The card ran in a subshell, so the tree it found is found again here, for the statement.
  if [ "$verb" = override ]; then
    t="$(_fa_g --attr-source="$_FA_EMPTY" merge-tree --write-tree --no-messages "$_FA_MAIN" "$h" 2>/dev/null)" && t="${t%%$'\n'*}" && _fa_sha "$t" \
      || { printf 'refused: it conflicts with main, so there is no tree to override\n'; return 1; }
    [ "$t" != "$(_fa_g rev-parse --verify --quiet "$_FA_MAIN^{tree}" 2>/dev/null)" ] \
      || { printf 'refused: it changes nothing, so there is nothing to override\n'; return 1; }
  fi
  cardid="$(printf '%s\n' "$card" | _fa_g hash-object --stdin 2>/dev/null)"
  nonce="$(od -An -N16 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n')"
  _fa_sha "$cardid" && [ "${#nonce}" -eq 32 ] || { printf 'refused: the statement could not be made\n'; return 1; }
  at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"; n="$_DL_N"
  stmt="$(printf 'felix-door/v1\nauthority: %s\nserial: %s\nprev: %s\nverb: %s\ncommit: %s\ntree: %s\nmain: %s\ncard: %s\nkey: none\ngiven: %s\nresult: %s\nwitness: %s\nnonce: %s\nat: %s' \
    "$_FA_ID" "$n" "${_DL_TIP:--}" "$verb" "$h" "$t" "${_FA_MAIN:--}" "$cardid" "$given" "$result" "$witness" "$nonce" "$at")"
  printf 'statement: the statement this door will keep, given with no key:\n%s\n' "$stmt"
  printf 'card: the authority'"'"'s own facts:\n%s\n' "$card"
  case "$verb" in
    stop|go) want="$verb"; printf 'confirm: to give it, type its verb\n' ;;
    reach)   want="reach $result"; printf 'confirm: to give it, type: reach %s\n' "$result" ;;
    *)       o=$(( 0x${nonce:0:4} % 37 )); want="$verb ${h:o:4}"
             printf 'confirm: %s[%s]%s\n' "${h:0:o}" "${h:o:4}" "${h:o+4}"
             printf 'confirm: to give it, type its verb and the four characters in brackets\n' ;;
  esac
  # D6. One try.
  IFS= read -r -t "$ttl" line || { printf 'refused: no confirmation came; the statement is closed and nothing was kept\n'; return 1; }
  [ "$line" = "$want" ] || { printf 'refused: that is not this statement'"'"'s confirmation; the statement is closed and nothing was kept\n'; return 1; }
  # D7, D9. The next entry of the log, by compare-and-swap.
  tree="$_FA_EMPTY"
  if [ "$witness" != - ]; then
    tree="$(printf '100644 blob %s\twitness\n' "$witness" | _fa_g mktree 2>/dev/null)" && _fa_sha "$tree" \
      || { printf 'refused: the witness record could not be kept; nothing was kept\n'; return 1; }
  fi
  if [ -n "$_DL_TIP" ]; then c="$(printf '%s\n' "$stmt" | _fa_g commit-tree "$tree" -p "$_DL_TIP" 2>/dev/null)"
  else c="$(printf '%s\n' "$stmt" | _fa_g commit-tree "$tree" 2>/dev/null)"; fi
  _fa_sha "$c" || { printf 'refused: the statement could not be written; nothing was kept\n'; return 1; }
  _fa_g update-ref refs/felix/door "$c" "${_DL_TIP:-$FELIX_AUTH_ZERO}" 2>/dev/null \
    || { printf 'refused: the log moved while this statement was open; nothing was kept\n'; return 1; }
  printf 'kept: statement %s %s %s\n' "$n" "$verb" "$h"
  # The commit a statement names stays in the store for as long as the statement does.
  [ "$h" = - ] || _fa_g update-ref "refs/felix/named/$n" "$h" 2>/dev/null || :
  if [ "$verb" = start ]; then
    _DL_N=1; _DL_VERB[0]=start; _DL_COMMIT[0]="$h"
    felix_authority_main && printf 'main: %s\n' "$_FA_MAIN" || printf 'main: could not be made; the next tick makes it from statement 0\n'
  fi
  _fdoor_lock
  return 0
}
