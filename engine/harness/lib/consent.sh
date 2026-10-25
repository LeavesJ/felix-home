# A grant is a person's word, and the commission grant is a grant over a wording.
#
# Audit b17 (2026-10-24). Three things were wrong with the commission grant,
# and each is mended here, in the one place that holds the consent.
#
# 1. A session could give itself a grant. `felix autonomy --allow` checked its
#    arguments and a lock, and nothing else, then printed that a permission a
#    system grants itself is not a permission. Now a run whose stdin is not a
#    terminal and which sits in a Claude session is refused (felix_caller_class),
#    and every grant, revoke and refusal leaves one says.log row naming who asked.
#    `felix commission` is refused to a session the same way, unless the grant
#    itself is making the run (FELIX_COMMISSION_UNATTENDED=1, set only by
#    felix_commission_resume_bg, and honoured only under a current grant in the
#    project's own checkout). This is the floor, not the wall: a session that
#    unsets its own variables, fakes a terminal or writes the file through a shell
#    redirect is not stopped, and nothing here says it is.
#
# 2. The consent said the run installs nothing, and the unattended run installs.
#    The consent is now one function (felix_consent_commission_text), printed on
#    the status page and hashed, and the stamp carries that hash on its second
#    line. A grant is current only over the wording this engine holds, so an
#    engine that changes what the run does cannot inherit a grant made over the
#    old words. One-line stamps, which every earlier engine wrote, are stale.
#
# 3. A stamp that could not be written was reported as written (a directory at
#    its path gave exit 0 and "stamped against"; a pipe hung the command). The
#    path is checked before the grant is written, and the stamp is read back.
#
# The stamp: line 1 is the policy version, as it always was, so every reader of
# line 1 is unchanged. Line 2 is `consent<TAB>hash<TAB>class<TAB>time`.

# Who is asking. A terminal wins: a person at a keyboard may be inside a session's
# environment. Otherwise a Claude session's variables mark a session, and anything
# else (CI, launchd, a script) is no terminal.
felix_caller_class() {
  if [ -t 0 ]; then printf 'terminal\n'
  elif [ -n "${CLAUDECODE:-}" ] || [ -n "${CLAUDE_CODE_SESSION_ID:-}" ]; then printf 'session\n'
  else printf 'no-terminal\n'; fi
}

command -v _felix_hash >/dev/null 2>&1 || . "$(dirname "${BASH_SOURCE[0]:-$0}")/verify.sh"

# What the commission grant consents to: the text hashed into the stamp, and the
# text the status page prints, one and the same. Nothing in it names a project or
# a path, so the hash is the same for every project and every home. A line is a
# printf argument, and each phrase a test or a person looks for stays whole on one.
felix_consent_commission_text() {
  printf '%s\n' \
    'Commission is not a scheduling change, and the wording matters because' \
    'it is what is being consented to. The pipeline evaluates two columns of' \
    "this project's commissioning.tsv as shell, \`when\` and \`check\`, in the" \
    "project's own checkout. Without this grant nothing on a hook path does" \
    'that. With it, session start runs felix commission in the background,' \
    'with nobody present.' \
    '' \
    'With nobody present, the run installs every stack.tsv row the install' \
    'policy admits (a low row, and a medium row a person declared), through' \
    'claude plugin install at user scope, claude plugin marketplace add, or' \
    'claude mcp add with no scope flag, and it enables a plugin that is' \
    'installed but disabled; nothing marked high is installed, and a medium' \
    'row Felix only observed waits for a person. It also appends rows to the' \
    "project's stack.tsv, setup.tsv, capabilities and routes.tsv. An install" \
    'is undone with claude plugin uninstall or claude mcp remove, not by' \
    'deleting a line.' \
    '' \
    "The grant is stamped against two things. One is the project's tables:" \
    'edit commissioning.tsv, or any table the receipt covers, and the grant' \
    'stops covering it. The other is this wording: an engine that says' \
    'something else about what the run does is not the engine consented to.' \
    'Either way the row above reads [!] and the unattended run refuses,' \
    'because an ordinary edit to a project table, or an engine upgrade that' \
    'changes what the run does, must not become something that runs' \
    'unattended. Re-granting is how a person says they have read the change.'
}

# The hash of that text, or nothing when it cannot be made.
felix_consent_hash() { felix_consent_commission_text | _felix_hash; }

# One says.log row for a consent act: time, consent, the session id (or -), the
# command, and the text with the literal \n felix_say ends its rows with. Written
# here rather than through felix_say, which cannot say whether it wrote. The
# session id is what the platform exports; one holding a tab, a newline or a CR,
# or longer than 200 bytes, would break the row, so it is written as -.
felix_consent_record() {   # proj cause text -> 0 written
  local proj="$1" cause="$2" text sid="${CLAUDE_CODE_SESSION_ID:-}" mem t=$'\t' n=$'\n' r=$'\r'
  case "$sid" in ''|*"$t"*|*"$n"*|*"$r"*) sid=- ;; esac
  [ "${#sid}" -le 200 ] || sid=-
  text="$(printf '%s' "$3" | LC_ALL=C tr '\t\n\r\\' '    ')"
  mem="$(felix_mem_dir "$proj" 2>/dev/null)" && [ -n "$mem" ] || return 1
  [ -d "$mem" ] || mkdir -p "$mem" 2>/dev/null || return 1
  printf '%s\tconsent\t%s\t%s\t%s\\n\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$sid" "$cause" "$text" \
    >> "$mem/says.log" 2>/dev/null
}
# The same, and a word on stderr when it could not be written. What was asked still holds.
felix_consent_note() {   # proj cause text
  felix_consent_record "$@" && return 0
  printf 'felix: not recorded: the says.log row for "%s" could not be written under the project memory, so nothing records who did this. What was asked still holds.\n' "$3" >&2
  return 0
}

# Where the commission grant stands: none (not granted), table (the stamp is
# absent or was made over other tables), engine (over these tables, but not over
# this engine's consent text), current. Line 1 is read first, so a moved table
# reads as table whatever line 2 says.
felix_autonomy_commission_state() {   # proj
  local proj="$1" stamp l12 l1 l2="" now="" h want t=$'\t' n=$'\n'
  felix_autonomy_allows "$proj" commission || { printf 'none\n'; return 0; }
  stamp="$(felix_autonomy_stamp_path "$proj" commission)"
  # Only a regular file: a pipe at the path held a reader open for a writer that never came.
  [ -f "$stamp" ] || { printf 'table\n'; return 0; }
  l12="$(LC_ALL=C awk 'NR <= 2 { print } NR >= 2 { exit }' "$stamp" 2>/dev/null)"
  l1="${l12%%"$n"*}"
  case "$l12" in *"$n"*) l2="${l12#*"$n"}" ;; esac
  if command -v felix_commission_policy_version >/dev/null 2>&1; then
    now="$(felix_commission_policy_version "$proj" 2>/dev/null)"
  fi
  if [ -z "$l1" ] || [ -z "$now" ] || [ "$l1" != "$now" ]; then printf 'table\n'; return 0; fi
  case "$l2" in "consent$t"*) ;; *) printf 'engine\n'; return 0 ;; esac
  h="${l2#"consent$t"}"; h="${h%%"$t"*}"
  want="$(felix_consent_hash)"
  if [ -n "$want" ] && [ "$h" = "$want" ]; then printf 'current\n'; else printf 'engine\n'; fi
}

# Could a stamp be written? Asked before the grant is, so a refusal leaves nothing
# behind. Prints why not.
felix_consent_stamp_check() {   # proj -> 0 yes; 1 and the reason
  local stamp
  stamp="$(felix_autonomy_stamp_path "$1" commission)"
  if [ -e "$stamp" ] || [ -L "$stamp" ]; then
    [ -f "$stamp" ] || { printf 'something that is not a regular file is at %s' "$stamp"; return 1; }
  fi
  [ -n "$(felix_commission_policy_version "$1" 2>/dev/null)" ] \
    || { printf 'the policy version of %s could not be computed' "$1"; return 1; }
  [ -n "$(felix_consent_hash)" ] || { printf 'the consent text could not be hashed'; return 1; }
  return 0
}

# Write the stamp, then read it back: written is a claim the next reader must be
# able to confirm. $2 is the caller class the stamp records.
felix_consent_stamp() {   # proj class -> 0 the stamp reads current
  local stamp pv hh
  stamp="$(felix_autonomy_stamp_path "$1" commission)"
  pv="$(felix_commission_policy_version "$1" 2>/dev/null)"; hh="$(felix_consent_hash)"
  [ -n "$pv" ] && [ -n "$hh" ] || return 1
  { printf '%s\n' "$pv"; printf 'consent\t%s\t%s\t%s\n' "$hh" "$2" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"; } \
    > "$stamp" 2>/dev/null || return 1
  [ "$(felix_autonomy_commission_state "$1")" = current ]
}

# A session's --allow, refused. Said on stderr; the caller exits.
felix_consent_refuse_allow() {   # proj allow not-sentence
  felix_consent_note "$1" "felix autonomy" "refused: allow $2 (session)"
  printf 'felix: %s, because a grant is a person'"'"'s word: felix autonomy --allow is run from a terminal, and this run came from a session. Nothing was written. If you are the person, run it in your own terminal.\n' "$3" >&2
}

# May this felix commission run? A run that is not --status.
#   FELIX_COMMISSION_UNATTENDED=1 (exactly) is the mark session start's detached
#   run carries. Whatever the caller, it runs only under a current grant in the
#   project's own checkout. Any other value is as if unset.
#   Otherwise a session is refused: the run evaluates the table's `when` and
#   `check` as shell and installs, and that is a person's, from a terminal.
# Nothing has been read for running, locked or written when this answers.
felix_consent_run_gate() {   # proj root -> 0 go on; 1 refused, why on stderr
  local proj="$1" root="$2" cls why
  if [ "${FELIX_COMMISSION_UNATTENDED:-}" = 1 ]; then
    if ! felix_autonomy_commission_current "$proj"; then
      why="there is no current commission grant for $(basename "$proj") (none, or one over other tables or another consent text); a person grants it from a terminal with felix autonomy --allow commission"
    elif ! felix_checkout_is_own "$proj" "$root"; then
      why="this checkout is not the project's own checkout"
    else return 0; fi
    printf 'felix: FELIX_COMMISSION_UNATTENDED is set, but %s: nothing was run or written.\n' "$why" >&2
    return 1
  fi
  cls="$(felix_caller_class)"
  [ "$cls" = session ] || return 0
  felix_consent_note "$proj" "felix commission" "refused: commission run (session)"
  printf 'felix: felix commission is run from a terminal, or by a current commission grant at session start, and this run came from a session: nothing was run or written. felix commission --status reads where the rows stand without running anything.\n' >&2
  return 1
}

# The status page: everything felix autonomy prints with no arguments.
felix_consent_page() {   # proj
  local proj="$1" st stamp cls w
  st="$(felix_autonomy_commission_state "$proj")"
  printf '\nautonomy for %s\n\n' "$(basename "$proj")"
  if felix_autonomy_allows "$proj" tidy; then
    printf '  [x] tidy    remove a lookalike script when Felix already holds that file\n'
  else
    printf '  [ ] tidy    remove a lookalike script when Felix already holds that file\n'
  fi
  printf '\nNothing is granted by default, and Felix never writes this file for a\n'
  printf 'project: a permission a system grants itself is not a permission. So a\n'
  printf 'grant is refused when a Claude session asks for it, and every grant,\n'
  printf 'revoke and refusal is recorded in says.log with the session that asked.\n'
  printf 'Felix refuses a grant typed by a session. That stops a session that\n'
  printf 'follows its instructions, not one that works around it.\n'
  printf '\nTidy removes a file only when every one of these holds: this project\n'
  printf 'opted in, Felix holds a file of that exact name, git does not track it,\n'
  printf 'it is not the declared gate, and a backup was written and confirmed\n'
  printf 'readable first. A tracked file is part of what the repository says it\n'
  printf 'contains, and removing one is a change to the project rather than the\n'
  printf 'removal of a stray.\n'
  case "$st" in
    current) printf '\n  [x] commission  run the commissioning pipeline with nobody present\n' ;;
    table)   printf '\n  [!] commission  granted, but not over this commissioning.tsv\n' ;;
    engine)  printf '\n  [!] commission  granted, but not over what this engine says the grant does\n' ;;
    *)       printf '\n  [ ] commission  run the commissioning pipeline with nobody present\n' ;;
  esac
  stamp="$(felix_autonomy_stamp_path "$proj" commission)"
  if [ "$st" != none ] && [ -f "$stamp" ]; then
    cls="$(LC_ALL=C awk -F'\t' 'NR == 2 { if ($1 == "consent") print $3; exit }' "$stamp" 2>/dev/null)"
    case "$cls" in
      terminal)    w='stamped from a terminal' ;;
      no-terminal) w='stamped with no terminal attached' ;;
      *)           w='the stamp does not say where it was made' ;;
    esac
    printf '      %s\n' "$w"
  fi
  [ "$st" != engine ] || printf '      The wording below is not what that stamp was made over. Read it, then\n      felix autonomy --allow commission.\n'
  printf '\n'
  felix_consent_commission_text
  printf '\n  felix autonomy --allow tidy      grant it\n'
  printf '  felix autonomy --revoke tidy     take it back\n'
  printf '  felix autonomy --allow commission    grant it, over the table as it stands\n'
  printf '  felix autonomy --revoke commission   take it back\n'
}
