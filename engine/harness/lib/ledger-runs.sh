# Which routed tool a shell command runs, read in bash alone.
#
# The ledger records a call by what it reached, and a Bash call that ran a
# command-line tool reached that tool: `graphify query ...` is a reach of
# graphify, not a use of Bash. felix_ledger_signal asks this, through
# _felix_ledger_cli in lib/ledger.sh, about a Bash call whose command holds one
# of the session's names. That runs after such a call in any governed session,
# so this starts no process and reads no file: it walks the command as the
# payload writes it, JSON escapes and all, the way the shell would read it, and
# only as far as telling which words are programs.
#
# Precision first. A miss leaves the call as `tool Bash`, which is what it was
# before; a false reach takes a capability off the retire list on evidence of
# nothing, and keeps a route that is ignored. So what this cannot follow ends
# the reading rather than being guessed at, and text a command only carries (a
# quoted string, a here-document, a comment, an argument) is never a program.
# The rules, and the runs they do not see: docs/2026-10-31-cli-reach-spec.md,
# section 3.
#
# Nothing here slices or matches the whole text more than once a block: bash
# 3.2 copies a variable whole to take any slice of it, and the regex library
# walks the whole of its subject even for an anchored pattern, so a 16 KB
# command of `a;a;a;...` once took 1.3 s of CPU. The text in hand, _r, is kept
# short and topped up a block at a time (_felix_lr_step), every match is of the
# next 256 bytes at most, and a longer token is read a window at a time.
#
# The readers share their state through bash's dynamic scope. Each list keeps
# its own in locals, and the word, quote and escape readers change the list's
# that called them. _r is the text in hand, _rest what is not yet and _left its
# length; _n the steps left, _d the nesting, _l the line _felix_lr_line passed,
# and _hdc the here-documents a nested list opened on a line it did not end.
_FELIX_LR_PLAIN='^([^\\"'"'"' $`;&|()<>]*)'
_FELIX_LR_SQTEXT='^([^'"'"'\\"]|\\.)*'
_FELIX_LR_ANSITEXT='^(\\\\(\\.|[^\\"])|\\[^\\]|[^'"'"'\\"])*'
_FELIX_LR_DQPLAIN='^([^\\"$`]*)'
_FELIX_LR_BRPLAIN='^([^\\"'"'"'$`{}]*)'
_FELIX_LR_ARPLAIN='^([^\\"()]*)'
_FELIX_LR_LINE='^([^\\"]|\\[^n])*'
_FELIX_LR_VAR='^\$([A-Za-z_][A-Za-z0-9_]*|[0-9@*#?$!-])'
_FELIX_LR_FD='^[0-9]+$'
_FELIX_LR_HDWORD='^ *(\\\\)?('"'"'([A-Za-z0-9_.-]+)'"'"'|\\"([A-Za-z0-9_.-]+)\\"|([A-Za-z0-9_.-]+))'
_FELIX_LR_PARENS='^\(( |\\t)*\)'
_FELIX_LR_DEFN='^( |\\t)*\(( |\\t)*\)'

# NAMES TEXT: the first of NAMES, separated by single spaces, that TEXT runs as
# a program, in FELIX_LEDGER_RUN. TEXT is a command as a JSON payload writes
# it, from just after the opening quote of its value. Status 0 when one is.
felix_ledger_runs() {
  local LC_ALL=C IFS=$' \t\n' _r _rest _left _names=" $1 " _n=8193 _d=-1 _hdc="" _l=""
  _r="${2:0:832}"; _rest="${2:832}"; _left=${#_rest}
  FELIX_LEDGER_RUN=""
  _felix_lr_list ""
  [ -n "$FELIX_LEDGER_RUN" ]
}

# One step of the reading, counted against the bound, with the text in hand
# topped up first. A step consumes at most 256 bytes before its last look
# ahead, so 320 in hand is always enough, and only the end of the text leaves
# less.
_felix_lr_step() {
  _n=$((_n - 1)); [ "$_n" -gt 0 ] || return 1
  if [ "$_left" -gt 0 ] && [ "${#_r}" -lt 320 ]; then
    _r="$_r${_rest:0:512}"; _rest="${_rest:512}"; _left=$((_left - 512))
  fi
}

# A list of commands, to END: "" (the value's end), ")" or "`". Status 1 ends
# the reading, found or not.
_felix_lr_list() {
  local end="$1" cmd=1 w="" lit=1 inw=0 wf="" wrap="" warg=0 tdur=0 tgt=0 \
        cw=0 cpat=0 cfirst=0 tst=0 fnw=0 pw=0 m c op hd=""
  _d=$((_d + 1)); [ "$_d" -le 32 ] || return 1
  while :; do
    _felix_lr_step || return 1
    c="${_r:0:1}"
    # A run of plain bytes, matched only when there is one: the match is the
    # dearest thing a step does, and half of all steps start on an operator.
    case "$c" in
      [\\\"\'\ \$\`\;\&\|\(\)\<\>]|'') ;;
      *)
        # A comment runs to the end of its line, from the start of a word only.
        if [ "$inw" = 0 ] && [ "$c" = "#" ]; then _felix_lr_line || return 1; continue; fi
        [[ ${_r:0:64} =~ $_FELIX_LR_PLAIN ]]
        m="${BASH_REMATCH[1]}"
        [ "$inw" = 1 ] || wf="$m"
        w="$w$m"; inw=1; _r="${_r:${#m}}"
        case "$m" in */*) lit=1; w="/${w##*/}" ;; esac
        continue ;;
    esac
    # Inside [[ ]] these are the test's own operators, and none starts a
    # command. A word ]] ends the test, so the word in hand is ended first.
    if [ "$tst" = 1 ]; then
      case "$c" in
        '('|')'|'<'|'>'|'|'|'&'|';')
          _felix_lr_word
          if [ "$tst" = 1 ]; then _r="${_r:1}"; continue; fi ;;
      esac
    fi
    case "$c" in
      # The text ends unclosed: a byte bound cut it, and the word in hand too.
      '') return 1 ;;
      # The value ends, and a word in hand at the top is whole.
      '"') [ "$_d" -gt 0 ] || _felix_lr_word; return 1 ;;
      ' ') _felix_lr_word || return 1; _r="${_r:1}" ;;
      '\')
        op="${_r:0:2}"
        case "$op" in
          '\n') _felix_lr_word || return 1; _r="${_r:2}"
                if [ -n "$hd" ]; then _felix_lr_bodies || return 1; fi
                # Not a separator in a case's head or patterns, nor in a test.
                [ "$cw$cpat$tst" = 000 ] && _felix_lr_sep ;;
          '\t') _felix_lr_word || return 1; _r="${_r:2}" ;;
          '\"') [ "$inw" = 1 ] || wf=""; inw=1; _r="${_r:2}"; _felix_lr_dq || return 1 ;;
          '\\') if [ "${_r:2:2}" = '\n' ]; then _r="${_r:4}"
                else [ "$inw" = 1 ] || wf=""; _r="${_r:2}"; _felix_lr_esc || return 1; fi ;;
          '\/') [ "$inw" = 1 ] || wf=""; w="/"; lit=1; inw=1; _r="${_r:2}" ;;
          '\u') [ "$inw" = 1 ] || wf=""; w="$w?"; inw=1; _r="${_r:6}" ;;
          *) [ "$inw" = 1 ] || wf=""; w="$w?"; inw=1; _r="${_r:2}" ;;
        esac ;;
      "'") [ "$inw" = 1 ] || wf=""; inw=1; _r="${_r:1}"; _felix_lr_sq || return 1 ;;
      '$')
        [ "$inw" = 1 ] || wf=""
        inw=1; lit=0
        case "${_r:0:3}" in
          '$(('*) _r="${_r:3}"; _felix_lr_arith || return 1 ;;
          '$('*) _r="${_r:2}"; _felix_lr_sub ')' || return 1 ;;
          '${'*) _r="${_r:2}"; _felix_lr_brace || return 1 ;;
          "\$'"*) _r="${_r:2}"; _felix_lr_ansi || return 1 ;;
          '$\"') _r="${_r:3}"; _felix_lr_dq || return 1 ;;
          *) if [[ ${_r:0:64} =~ $_FELIX_LR_VAR ]]; then _r="${_r:${#BASH_REMATCH[0]}}"
             else w="$w?"; _r="${_r:1}"; fi ;;
        esac ;;
      '`')
        if [ "$end" = '`' ]; then
          _felix_lr_word || return 1; _r="${_r:1}"; _hdc="$hd"; _d=$((_d - 1)); return 0
        fi
        [ "$inw" = 1 ] || wf=""
        inw=1; lit=0; _r="${_r:1}"; _felix_lr_sub '`' || return 1 ;;
      '(')
        if [ "$inw" = 0 ] && [ "$pw" = 1 ] && [[ ${_r:0:64} =~ $_FELIX_LR_PARENS ]]; then
          # NAME (): the word before named a function, and its body follows.
          _r="${_r:${#BASH_REMATCH[0]}}"; cmd=1; pw=0
        elif [ "$inw" = 1 ] && [ "$cmd$fnw" != 00 ] && ! _felix_lr_assign \
             && [[ ${_r:0:64} =~ $_FELIX_LR_PARENS ]]; then
          # NAME(): the same, with the name still in hand, which runs nothing.
          _r="${_r:${#BASH_REMATCH[0]}}"; inw=0; w=""; lit=1; wf=""; cmd=1; fnw=0; wrap=""
        elif [ "$inw" = 0 ] && [ "$cpat" = 1 ]; then
          _r="${_r:1}"
        elif [ "$inw" = 0 ] && [ "$cmd" = 1 ]; then
          if [ "${_r:1:1}" = '(' ]; then _r="${_r:2}"; _felix_lr_arith || return 1
          else _r="${_r:1}"; _felix_lr_sub ')' || return 1; fi
          cmd=0
        else
          [ "$inw" = 1 ] || wf=""
          inw=1; _r="${_r:1}"; _felix_lr_args || return 1
        fi ;;
      ')')
        _felix_lr_word || return 1; _r="${_r:1}"
        if [ "$cpat" = 1 ]; then cpat=0; _felix_lr_sep
        elif [ "$end" = ')' ]; then _hdc="$hd"; _d=$((_d - 1)); return 0
        else return 1; fi ;;
      ';')
        _felix_lr_word || return 1
        case "${_r:0:3}" in
          ';;&') _r="${_r:3}"; cpat=1; cfirst=1 ;;
          ';;'*|';&'*) _r="${_r:2}"; cpat=1; cfirst=1 ;;
          *) _r="${_r:1}"; _felix_lr_sep ;;
        esac ;;
      '&')
        _felix_lr_word || return 1
        case "${_r:0:2}" in
          '&>') _r="${_r:2}"; [ "${_r:0:1}" = '>' ] && _r="${_r:1}"; tgt=1 ;;
          '&&') _r="${_r:2}"; _felix_lr_sep ;;
          *) _r="${_r:1}"; _felix_lr_sep ;;
        esac ;;
      '|')
        _felix_lr_word || return 1
        case "${_r:0:2}" in '||'|'|&') _r="${_r:2}" ;; *) _r="${_r:1}" ;; esac
        [ "$cpat" = 1 ] || _felix_lr_sep ;;
      '<'|'>') _felix_lr_redir || return 1 ;;
      *) return 1 ;;
    esac
  done
}

# A nested list, and the here-documents it opened on a line it did not end,
# whose bodies follow that line and so are the caller's to pass.
_felix_lr_sub() {
  _felix_lr_list "$1" || return 1
  hd="$hd$_hdc"; _hdc=""
}

# A separator: the next word starts a simple command.
_felix_lr_sep() { cmd=1; wrap=""; warg=0; tdur=0; tgt=0; pw=0; fnw=0; }

# Ends the word in hand and decides what it was. Status 1 when it ran one of
# the names, with FELIX_LEDGER_RUN set.
_felix_lr_word() {
  [ "$inw" = 1 ] || return 0
  inw=0; pw=0
  if [ "$tgt" = 1 ]; then
    tgt=0
  elif [ "$tst" = 1 ]; then
    [ "$lit" = 1 ] && [ "$w" = ']]' ] && { tst=0; cmd=0; }
  elif [ "$cw" = 1 ]; then
    [ "$lit" = 1 ] && [ "$w" = in ] && { cw=0; cpat=1; cfirst=1; }
  elif [ "$cpat" = 1 ]; then
    [ "$cfirst" = 1 ] && [ "$lit" = 1 ] && [ "$w" = esac ] && { cpat=0; cmd=0; }
    cfirst=0
  elif [ "$fnw" = 1 ]; then
    # `function NAME`: the name runs nothing, and the body follows it.
    fnw=0; cmd=1; pw=1
  elif [ "$cmd" = 1 ]; then
    _felix_lr_program || return 1
  fi
  w=""; lit=1; wf=""
  return 0
}

# A word where a simple command starts: an assignment, a wrapper or one of its
# options, a reserved word, or the program. A wrapper is known by the part of
# its word after the last slash, and the program by its name there.
_felix_lr_program() {
  local b
  if [ -n "$wrap" ]; then
    if [ "$warg" = 1 ]; then warg=0; return 0; fi
    case "$w" in
      --) return 0 ;;
      -*)
        case "$wrap" in
          # command -v and -V look a program up and run none.
          command) case "$w" in *[vV]*) wrap=""; cmd=0 ;; esac ;;
          nice) [ "$w" = -n ] && warg=1 ;;
          timeout) case "$w" in -s|-k) warg=1 ;; esac ;;
          env) case "$w" in -u|-C|-P) warg=1 ;; -S*|--split-string*) wrap=""; cmd=0 ;; esac ;;
          exec) [ "$w" = -a ] && warg=1 ;;
        esac
        return 0 ;;
    esac
    if [ "$wrap" = timeout ] && [ "$tdur" = 0 ]; then tdur=1; return 0; fi
    wrap=""; tdur=0
  fi
  _felix_lr_assign && return 0
  if [ "$lit" = 1 ]; then
    case "$w" in
      '!'|'{'|if|then|else|elif|while|until|do) return 0 ;;
      '[[') tst=1; cmd=0; return 0 ;;
      function) fnw=1; cmd=0; return 0 ;;
      case) cw=1; cmd=0; return 0 ;;
      '}'|fi|done|esac|for|select|coproc|']]') cmd=0; return 0 ;;
    esac
    b="${w##*/}"
    case "$b" in
      time|nohup|exec|command|nice|env|timeout) wrap="$b"; warg=0; tdur=0; return 0 ;;
    esac
    case "$_names" in
      # NAME () defines a function by that name, which runs nothing yet.
      *" $b "*) [[ ${_r:0:64} =~ $_FELIX_LR_DEFN ]] || { FELIX_LEDGER_RUN="$b"; return 1; } ;;
    esac
    pw=1
  fi
  cmd=0
}

# Whether the word in hand began as an assignment, NAME= or NAME+=, by its
# first plain run. A glob, not a match: it is asked of every program word.
_felix_lr_assign() {
  local v
  case "$wf" in *=*) ;; *) return 1 ;; esac
  v="${wf%%=*}"; v="${v%+}"
  case "$v" in ''|[0-9]*|*[!A-Za-z0-9_]*) return 1 ;; esac
}

# A redirection, at < or >. A word of digits in hand is its file descriptor and
# the word after it its target, so neither is a program.
_felix_lr_redir() {
  if [ "$inw" = 1 ] && [ "$lit" = 1 ] && [[ $w =~ $_FELIX_LR_FD ]]; then inw=0; w=""; wf=""
  else _felix_lr_word || return 1; fi
  case "${_r:0:3}" in
    '<<<'*) _r="${_r:3}"; tgt=1 ;;
    '<<'*)
      if [ "${_r:2:1}" = - ]; then _r="${_r:3}"; op=-; else _r="${_r:2}"; op=+; fi
      [[ ${_r:0:256} =~ $_FELIX_LR_HDWORD ]] || return 1
      hd="$hd$op${BASH_REMATCH[3]}${BASH_REMATCH[4]}${BASH_REMATCH[5]} "
      _r="${_r:${#BASH_REMATCH[0]}}"
      # A delimiter that goes on past what was matched has some other shape.
      case "${_r:0:2}" in ' '*|'\n'|'\t'|';'*|'&'*|'|'*|'<'*|'>'*|')'*|'"'*) ;; *) return 1 ;; esac ;;
    '<('*|'>('*) _r="${_r:2}"; inw=1; lit=0; _felix_lr_sub ')' || return 1 ;;
    '>>'*|'>&'*|'>|'*|'<&'*|'<>'*) _r="${_r:2}"; tgt=1 ;;
    *) _r="${_r:1}"; tgt=1 ;;
  esac
}

# The character a shell backslash quotes, joined to the word in hand. A JSON
# escape stands for a character no name holds, except a slash.
_felix_lr_esc() {
  case "${_r:0:2}" in
    '\/') w="/"; lit=1; _r="${_r:2}" ;;
    '\u') w="$w?"; _r="${_r:6}" ;;
    '\'?) w="$w?"; _r="${_r:2}" ;;
    '"'*|'') return 1 ;;
    /*) w="/"; lit=1; _r="${_r:1}" ;;
    *) w="$w${_r:0:1}"; _r="${_r:1}" ;;
  esac
  inw=1
}

# One character as JSON writes it, passed: two bytes for an escape and six for
# \uXXXX. Status 1 at the end of the value.
_felix_lr_jchar() {
  case "${_r:0:2}" in
    '\u') _r="${_r:6}" ;;
    '\'?) _r="${_r:2}" ;;
    '"'*|'') return 1 ;;
    *) _r="${_r:1}" ;;
  esac
}

# Inside single quotes, entered past the opening one, to the closing one:
# nothing in them is special, and the text joins the word in hand. An escape
# inside stands for a character no name holds.
_felix_lr_sq() {
  local m
  while :; do
    _felix_lr_step || return 1
    [[ ${_r:0:256} =~ $_FELIX_LR_SQTEXT ]]
    m="${BASH_REMATCH[0]}"; _r="${_r:${#m}}"
    case "$m" in *\\*) w="$w?" ;; */*) lit=1; w="/${m##*/}" ;; *) w="$w$m" ;; esac
    case "${_r:0:1}" in "'") _r="${_r:1}"; return 0 ;; '"'|'') return 1 ;; esac
    [ -n "$m" ] || return 1
  done
}

# Inside $'...', entered past its quote, to the quote no backslash escapes. It
# is never a name, so only its end matters.
_felix_lr_ansi() {
  local m
  while :; do
    _felix_lr_step || return 1
    [[ ${_r:0:256} =~ $_FELIX_LR_ANSITEXT ]]
    m="${BASH_REMATCH[0]}"; _r="${_r:${#m}}"
    case "${_r:0:1}" in "'") _r="${_r:1}"; return 0 ;; '"'|'') return 1 ;; esac
    [ -n "$m" ] || return 1
  done
}

# The rest of a line, passed to its line break or the value's end and left in
# _l, or `?` when it is longer than a window, which no delimiter is.
_felix_lr_line() {
  local k=0
  _l=""
  while :; do
    _felix_lr_step || return 1
    [[ ${_r:0:256} =~ $_FELIX_LR_LINE ]]
    if [ "$k" = 0 ]; then _l="${BASH_REMATCH[0]}"; else _l="?"; fi
    _r="${_r:${#BASH_REMATCH[0]}}"
    case "${_r:0:2}" in '\n'|'"'*) return 0 ;; esac
    [ -n "$_r" ] && [ -n "${BASH_REMATCH[0]}" ] || return 1
    k=1
  done
}

# Inside double quotes, to the closing one: the text joins the word in hand,
# and a substitution in it runs.
_felix_lr_dq() {
  local m
  _d=$((_d + 1)); [ "$_d" -le 32 ] || return 1
  while :; do
    _felix_lr_step || return 1
    case "${_r:0:1}" in
      [\\\"\$\`]|'') ;;
      *)
        [[ ${_r:0:64} =~ $_FELIX_LR_DQPLAIN ]]
        m="${BASH_REMATCH[1]}"
        w="$w$m"; _r="${_r:${#m}}"
        case "$m" in */*) lit=1; w="/${w##*/}" ;; esac
        continue ;;
    esac
    case "${_r:0:2}" in
      '\"') _r="${_r:2}"; _d=$((_d - 1)); return 0 ;;
      '\\') case "${_r:2:2}" in
              '\n') _r="${_r:4}" ;;
              '\"'|'\\') w="$w?"; _r="${_r:4}" ;;
              '$'?|'`'?) w="$w?"; _r="${_r:3}" ;;
              *) w="$w?"; _r="${_r:2}" ;;
            esac ;;
      '\/') w="/"; lit=1; _r="${_r:2}" ;;
      '\u') w="$w?"; _r="${_r:6}" ;;
      '\'?) w="$w?"; _r="${_r:2}" ;;
      '$(') lit=0
            if [ "${_r:2:1}" = '(' ]; then _r="${_r:3}"; _felix_lr_arith || return 1
            else _r="${_r:2}"; _felix_lr_sub ')' || return 1; fi ;;
      '${') lit=0; _r="${_r:2}"; _felix_lr_brace || return 1 ;;
      '$'?) lit=0
            if [[ ${_r:0:64} =~ $_FELIX_LR_VAR ]]; then _r="${_r:${#BASH_REMATCH[0]}}"
            else w="$w?"; _r="${_r:1}"; fi ;;
      '`'?) lit=0; _r="${_r:1}"; _felix_lr_sub '`' || return 1 ;;
      *) return 1 ;;
    esac
  done
}

# Inside ${...}, to its closing brace. None of it is a word of the command, but
# a substitution in it runs.
_felix_lr_brace() {
  local m w="" lit=1 inw=0
  _d=$((_d + 1)); [ "$_d" -le 32 ] || return 1
  while :; do
    _felix_lr_step || return 1
    [[ ${_r:0:256} =~ $_FELIX_LR_BRPLAIN ]]
    m="${BASH_REMATCH[1]}"
    if [ -n "$m" ]; then _r="${_r:${#m}}"; [ "${#m}" -lt 256 ] || continue; fi
    case "${_r:0:2}" in
      '}'*) _r="${_r:1}"; _d=$((_d - 1)); return 0 ;;
      '{'*) _r="${_r:1}" ;;
      '\"') _r="${_r:2}"; _felix_lr_dq || return 1 ;;
      '\\') _r="${_r:2}"; _felix_lr_jchar || return 1 ;;
      '\u') _r="${_r:6}" ;;
      '\'?) _r="${_r:2}" ;;
      "'"*) _r="${_r:1}"; _felix_lr_sq || return 1 ;;
      '$(') if [ "${_r:2:1}" = '(' ]; then _r="${_r:3}"; _felix_lr_arith || return 1
            else _r="${_r:2}"; _felix_lr_sub ')' || return 1; fi ;;
      '${') _r="${_r:2}"; _felix_lr_brace || return 1 ;;
      '`'*) _r="${_r:1}"; _felix_lr_sub '`' || return 1 ;;
      '$'*) _r="${_r:1}" ;;
      *) return 1 ;;
    esac
  done
}

# A parenthesised group that is no list of commands, such as an array's values
# or a for's arithmetic: words only, though a substitution in one still runs.
_felix_lr_args() {
  local m w="" lit=1 inw=0
  _d=$((_d + 1)); [ "$_d" -le 32 ] || return 1
  while :; do
    _felix_lr_step || return 1
    [[ ${_r:0:256} =~ $_FELIX_LR_PLAIN ]]
    m="${BASH_REMATCH[1]}"
    if [ -n "$m" ]; then _r="${_r:${#m}}"; continue; fi
    case "${_r:0:2}" in
      ')'*) _r="${_r:1}"; _d=$((_d - 1)); return 0 ;;
      '('*) _r="${_r:1}"; _felix_lr_args || return 1 ;;
      ' '*|';'*|'&'*|'|'*|'<'*|'>'*) _r="${_r:1}" ;;
      '\"') _r="${_r:2}"; _felix_lr_dq || return 1 ;;
      '\\') _r="${_r:2}"; _felix_lr_jchar || return 1 ;;
      '\u') _r="${_r:6}" ;;
      '\'?) _r="${_r:2}" ;;
      "'"*) _r="${_r:1}"; _felix_lr_sq || return 1 ;;
      '$(') if [ "${_r:2:1}" = '(' ]; then _r="${_r:3}"; _felix_lr_arith || return 1
            else _r="${_r:2}"; _felix_lr_sub ')' || return 1; fi ;;
      '${') _r="${_r:2}"; _felix_lr_brace || return 1 ;;
      '`'*) _r="${_r:1}"; _felix_lr_sub '`' || return 1 ;;
      '$'*) _r="${_r:1}" ;;
      *) return 1 ;;
    esac
  done
}

# Arithmetic, entered past its two opening parentheses: passed to the pair
# that closes them and not read into, so a substitution inside is not seen.
_felix_lr_arith() {
  local p=2 m
  while :; do
    _felix_lr_step || return 1
    [[ ${_r:0:256} =~ $_FELIX_LR_ARPLAIN ]]
    m="${BASH_REMATCH[1]}"
    if [ -n "$m" ]; then _r="${_r:${#m}}"; [ "${#m}" -lt 256 ] || continue; fi
    case "${_r:0:1}" in
      '(') p=$((p + 1)); _r="${_r:1}" ;;
      ')') p=$((p - 1)); _r="${_r:1}"; [ "$p" -gt 0 ] || return 0 ;;
      '\') _felix_lr_jchar || return 1 ;;
      *) return 1 ;;
    esac
  done
}

# The bodies of the here-documents the line just ended opened, in order. Each
# runs to a line that is its delimiter alone, after leading tabs for <<-, and
# the lines that cannot be are passed a window at a time, not one by one.
_felix_lr_bodies() {
  local d t f re U='([^\\"]|\\[^n])'
  for d in $hd; do
    t="${d:0:1}"; d="${d:1}"; f="${d:0:1}"
    [ "$f" = - ] && f='\\"-' || f="$f"'\\"'
    if [ "$t" = - ]; then re='^((\\t)*([^'"$f"']'"$U"'*|\\[^nt]'"$U"'*)?\\n)*'
    else re='^(([^'"$f"']'"$U"'*|\\[^n]'"$U"'*)?\\n)*'; fi
    while :; do
      _felix_lr_step || return 1
      [[ ${_r:0:256} =~ $re ]]; _r="${_r:${#BASH_REMATCH[0]}}"
      _felix_lr_line || return 1
      if [ "$t" = - ]; then while [ "${_l:0:2}" = '\t' ]; do _l="${_l:2}"; done; fi
      if [ "$_l" = "$d" ]; then [ "${_r:0:2}" = '\n' ] && _r="${_r:2}"; break; fi
      [ "${_r:0:2}" = '\n' ] || return 1
      _r="${_r:2}"
    done
  done
  hd=""
}
