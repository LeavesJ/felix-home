# Denial.
#
# The first thing Felix can stop rather than mention. Every other hook it wires
# injects text a session is free to ignore: SessionStart mounts doctrine,
# UserPromptSubmit names a play, Stop asks a question at the end. PreToolUse
# decides, and it is the only one that does.
#
# Felix skipped it for a long time because the charter said "governance layer",
# and a governance layer that only reports is a coherent thing to build. It is
# not what was wanted. A project running a stale copy of its own gate all day
# and reporting green is the case this exists for: Felix could see the rival
# gate and could not stop anybody running it.
#
# Narrow on purpose, in three ways:
#
#   - Table-driven, per project. The engine names no rule of its own, the same
#     way it names no project. What a repo refuses is the repo's decision.
#   - A rule matches the one field naming what the tool acts on, never the
#     payload and never file content. See _felix_deny_field.
#   - Fails open on everything. A missing table, an unparseable payload, a bad
#     regex, an unresolvable project: all allow. The cost of a false deny is a
#     person fighting their own tools and switching the harness off; the cost of
#     a missed deny is the status quo.
#
# It used to be narrow in a fourth way, and that one was a mistake. The matcher
# in hooks.json bound Bash alone, so no rule could see Read, Edit or Write —
# and the ledger then showed real sessions spending most of their calls on
# exactly those three. The matcher was doing duty as the blast-radius control,
# because a bad regex reaching Edit is indistinguishable from a broken editor.
#
# That is now handled where it belongs, by felix_deny_overbroad, so the matcher
# no longer has to be the answer. A pattern broad enough to refuse ordinary
# work is treated as a rule that is wrong rather than a rule that is strict,
# and skipped. Skipping can only ever allow more than the author intended,
# which is the same direction every other failure here already takes.
#
# deny.tsv rows: tool <TAB> extended-regex <TAB> reason

_felix_deny_rows() {
  local proj="$1" tool pattern reason
  [ -f "$proj/deny.tsv" ] || return 0
  while IFS=$'\t' read -r tool pattern reason; do
    case "$tool" in ''|'#'*) continue ;; esac
    # A row with no pattern is skipped rather than fatal, the same way a
    # malformed routes.tsv row is: one bad line must not stop a table enforcing.
    [ -n "${pattern:-}" ] || continue
    printf '%s\t%s\t%s\n' "$tool" "$pattern" "${reason:-refused by this project}"
  done < "$proj/deny.tsv"
}

# Which field of a payload a rule for this tool is about.
#
# One field per tool, chosen rather than searched. Scanning the payload for the
# first field that happens to be present looks more future-proof and is the
# wrong trade: an Edit whose new_string contains the text `"command": "rm -rf"`
# would hand that string to the matcher, and a rule would fire on content the
# person was only writing down. A tool nobody has taught this function is read
# as acting on a file, and a tool acting on nothing has no subject and is
# always allowed.
_felix_deny_field() {
  case "$1" in
    Bash)         printf 'command' ;;
    NotebookEdit) printf 'notebook_path' ;;
    WebFetch)     printf 'url' ;;
    *)            printf 'file_path' ;;
  esac
}

# That field's value, out of a PreToolUse payload, without parsing JSON.
#
# Escaped quotes are protected first, so a value containing one cannot run the
# match past the end of its own string and swallow the rest of the envelope.
# That over-capture is the dangerous direction here: it is how a rule matches
# text the person never typed and denies something legitimate.
#
# The first occurrence wins, not the last. A greedy leading `.*` in sed takes
# the last one, which is reachable: file content mentioning the field name puts
# a second copy after the real one, and the rule would then be tested against
# whatever that content said.
felix_deny_subject() {
  local raw="$1" field rest val
  field="$(_felix_deny_field "${2:-}")"
  case "$raw" in *"\"$field\""*) ;; *) return 0 ;; esac

  # All parameter expansion, no pipeline. This runs inside a synchronous hook on
  # every tool call, and the old tr/sed/awk/sed chain cost four process spawns
  # for a substring bash can find itself.
  rest="${raw#*\"$field\"}"          # after the key
  rest="${rest#*\"}"                 # past the colon, to the value's quote
  rest="${rest//\\\"/$'\001'}"        # neutralise escaped quotes first
  val="${rest%%\"*}"                 # to the first real closing quote
  printf '%s' "${val//$'\001'/\"}"
}

# Whether a pattern is too broad to be a rule.
#
# A rule says which work this project refuses. A pattern that also matches
# ordinary work is not a strict rule, it is a broken one, and honouring it
# produces a session where nothing can be edited and no error explains why.
# These two probes are what ordinary looks like: a routine command, and a path
# in no way special. Anything matching either is skipped.
#
# This can only ever allow more than the author asked for, never less, which is
# why it is safe to run ahead of every rule rather than only new ones.
FELIX_DENY_PROBES='git status --short
/felix/probe/ordinary'

felix_deny_overbroad() {
  local pattern="$1" probe
  [ -n "$pattern" ] || return 0
  while IFS= read -r probe; do
    [ -n "$probe" ] || continue
    # Bash's own ERE. The pipeline this replaces spawned a grep per probe per
    # rule, on every matched tool call; it also carried a documented SIGPIPE
    # hazard under pipefail that simply cannot arise without a pipe.
    [[ "$probe" =~ $pattern ]] && return 0
  done <<EOF
$FELIX_DENY_PROBES
EOF
  return 1
}

# The rows this project wrote that are too broad to enforce, for reporting.
# Nothing in the hot path calls this: the hook runs on every tool call, and a
# harness that repeats a static complaint on every call is noise. felix doctor
# is where somebody goes to be told what is wrong with their tables.
felix_deny_overbroad_rows() {
  local proj="$1" tool pattern reason
  while IFS=$'\t' read -r tool pattern reason; do
    [ -n "${pattern:-}" ] || continue
    felix_deny_overbroad "$pattern" && printf '%s\t%s\t%s\n' "$tool" "$pattern" "$reason"
  done <<EOF
$(_felix_deny_rows "$proj")
EOF
}

# The first row for this tool whose pattern matches the text: its reason goes
# in _FELIX_DENY_REASON, and the status says whether there was one. A variable
# and not output, so the call that nearly always finds nothing costs no
# subshell to find it.
_felix_deny_first() {
  local proj="$1" want="$2" text="$3" tool pattern reason
  _FELIX_DENY_REASON=""
  while IFS=$'\t' read -r tool pattern reason; do
    [ "${tool:-}" = "$want" ] || continue
    felix_deny_overbroad "$pattern" && continue
    # Bash's own ERE rather than `printf | grep`. The old form needed a comment
    # explaining why it could not use `grep -q` — a consumer exiting on first
    # match kills the producer with SIGPIPE and pipefail reports 141, read as
    # "no match" every time. No pipe, no hazard, and no process per rule.
    if [[ "$text" =~ $pattern ]]; then
      _FELIX_DENY_REASON="$reason"
      return 0
    fi
  done <<EOF
$(_felix_deny_rows "$proj")
EOF
  return 1
}

# Prints the reason when a command matches a row for this tool, and returns 0.
# Silent and returns 1 otherwise.
#
# A Bash row is about the command the shell runs, and not about text the
# command only carries. Until 2026-09-23 a row was matched against the payload's
# string alone, where everything the command carries reads as if it ran: a
# here-document body handed to `git commit -F -`, a message in `-m "..."`, a
# JSON payload in single quotes, a comment. The marker row refused a commit
# message saying "felix new <name> ... a .felix marker", because `<name>` holds
# a `>`. And the string is JSON, so a line break arrives as a backslash and an
# `n`, and a pattern's `[^;&|]*` ran across it: `git push -q` on one line and
# `gh api -f` on the next read as a force push. Of the 175 refusals the hooks
# had logged by then, about thirty were text of those kinds.
#
# So a Bash command that matches a row is read a second time, by
# felix_deny_code, as the shell reads it, and refused only if the row still
# matches there. That second reading costs a process, and it is spent only on
# a command about to be refused: every other call pays exactly what it paid
# before, which matters because this hook runs on every one of them. A reading
# done in bash itself was tried first and measured: bash 3.2's ${s//...} took
# fourteen seconds over a 31K command.
#
# This can only ever turn a refusal into an allow. What it does not do is the
# other direction, and there are commands a row names that the shell runs and
# the raw string never matched: `git push -f` with a line break after it, or
# `bash -c "git push --force"`, whose quote stands where the row wants a
# space. Refusing those would mean reading every command, not only the ones a
# row already matched, and that is a separate decision with its own cost.
felix_deny_match() {
  local proj="$1" want="$2" cmd="$3"
  [ -n "$cmd" ] || return 1
  _felix_deny_first "$proj" "$want" "$cmd" || return 1
  if [ "$want" = "Bash" ]; then
    _felix_deny_first "$proj" Bash "$(felix_deny_code "$cmd")" || return 1
  fi
  printf '%s' "$_FELIX_DENY_REASON"
}

# The command the shell runs, as one line for a row to match, read from the
# payload's JSON string: commands joined by `;`, every quoted span that is data
# standing as the word `_`, comments and here-document bodies gone, and each
# piece of code found inside something else appended after it, ` ; ` apart, as
# a command of its own.
#
# What counts as data, and each exception to it, since an exception missed is
# a command the shell runs and a row can no longer see:
#
#   - A here-document body is data, unless what reads it runs its input as
#     code: a shell, ssh, su, runuser, watch, eval, source, or `.` in command
#     position. Then its lines are commands. Where its word is unquoted the
#     shell expands the body, so a $( ) or a backtick in it is read as code.
#     And a body written to a file is read as code when the same command then
#     runs that file by the same spelling: `cat > $S/t.sh <<'EOF' ... EOF;
#     bash $S/t.sh`, the shape a scratch fixture takes. Seven of the logged
#     refusals had it, and in each the body ran what its row names. The same
#     holds for quoted text printf or echo writes to a file the command runs.
#   - A quoted span is data, `_`, when it holds a blank or a line break. It is
#     read as code where it is a shell's -c script or an argument of eval,
#     ssh, su, runuser or watch, gathered whole when it is quoted in pieces
#     (`'...'\''...'`). It is its own text, without the quotes, where it is a
#     redirect's target, an operand of a command that writes its operands
#     (cp, mv, ln, install, tee, dd, truncate, rm, touch, rsync, sed -i), the
#     program itself, glued to the word it sits in
#     (`--for'ce'`, `"$HOME"/.felix`, but not `--message="..."`), a single
#     word, or a path rooted in a variable, a home or a relative directory
#     (`$T/...`, `${D}...`, `~/...`, `./...`), so `> "$T/repo/.felix"` still
#     writes the marker. A span starting with a bare `/` is not taken for a
#     path, because `sed -n '/git push .* main /p'` starts that way too.
#   - Inside double quotes a $( ) or a backtick runs, and is read as code. The
#     here-document inside the $( ) of Claude Code's commit template is data
#     by the first rule. A substitution keeps its shape where it stood, as
#     `$(_)` or `<(_)`, since a row can be written about the shape itself.
#   - A # starting a word outside quotes starts a comment. `$(( ))` and
#     `(( ))` are arithmetic, whose << is a shift; the second is read as code
#     as well, in case bash takes it for two subshells.
#   - A pipe into a shell, a shell reading a process substitution, or a $( )
#     handed to something that runs its arguments, makes the data the script:
#     then the whole command is read with every quote dropped and each line
#     break a `;`.
#
# What it does not follow is a file written by anything but a here-document,
# or run by another name: a script printf wrote to $S/bin/claude and PATH
# later finds. That is the limit any reading of one command has.
#
# One awk process. The program is the same in BWK awk, mawk and gawk:
# split(s, A, "") is one character per element in all three. Nothing here
# fails closed: no awk, or a program error, prints nothing, and a row matches
# nothing in nothing, which allows.
felix_deny_code() {
  printf '%s' "$1" | awk "$_FELIX_DENY_READ" 2>/dev/null
}

# shellcheck disable=SC2016
_FELIX_DENY_READ='
  BEGIN { RS = "\001"; SQ = "\047"; BQ = "`"; NX = 0; FB = 0; LV = 0; WN = 0; SEG = 0 }
  { S = unjson($0); S0 = S; N = split(S, C, ""); I = 1; out = code("", N)
    for (m = 1; m <= WN; m++) if (WT[m] in RUN) X[++NX] = sub_view(WB[m])
    for (sid in TGT) { tg = TGT[sid]; sub(/^\.\//, "", tg); if (WD[sid] != "" && tg in RUN) X[++NX] = sub_view(WD[sid]) }
    for (k = 1; k <= NX; k++) out = out " ; " X[k]
    if (FB) out = lines(S0)
    printf "%s", out }

  # The JSON string escapes taken off. A doubled backslash is set aside
  # first, so that \\n stays a backslash and an n. It is put back by a split
  # on a regex: BWK awk, which macOS ships, splits on a line break as well
  # when the separator is a one-character string, and gsub reads the
  # backslashes of its replacement differently in each awk.
  function unjson(s,   n, P, k, r) {
    gsub(/\\\\/, "\001", s); gsub(/\\n/, "\n", s); gsub(/\\t/, "\t", s)
    gsub(/\\r/, "", s); gsub(/\\"/, "\"", s); gsub(/\\\//, "/", s)
    n = split(s, P, /\001/); r = P[1]
    for (k = 2; k <= n; k++) r = r "\\" P[k]
    return r
  }
  function base(w) { sub(/^.*\//, "", w); return w }
  function lines(s) {
    gsub(/\\\n/, "", s); gsub(/\n/, " ; ", s); gsub(SQ, "", s); gsub(/"/, "", s)
    return s
  }
  # Text that is read in its own right, appended to the buffer and read there,
  # so the place in the outer string needs no copy to come back to.
  function append(t,   n, T, j) {
    n = split(t, T, ""); C[N + 1] = "\002"
    for (j = 1; j <= n; j++) C[N + 1 + j] = T[j]
    S = S "\002" t; N = N + 1 + n
    return n
  }
  function sub_view(t,   n, at, si, r) {
    at = N + 2; n = append(t)
    si = I; I = at; r = code("", at + n - 1); I = si
    return r
  }
  # An unquoted here-document body, which the shell expands: its $( ) and
  # backticks run.
  function expand(t,   n, at, si, lim) {
    at = N + 2; n = append(t); lim = at + n - 1
    si = I; I = at
    while (I <= lim) {
      if (C[I] == "\\") { I += 2; continue }
      if (C[I] == "$" && C[I + 1] == "(" && C[I + 2] != "(") { I += 2; X[++NX] = code(")", lim); continue }
      if (C[I] == BQ) { I++; X[++NX] = code(BQ, lim); continue }
      I++
    }
    I = si
  }
  # One command being read, per level of nesting: its words so far, and
  # whether one of them runs a script (HSH), its arguments (ARG) or its input
  # (INR), or takes files for its operands (PATHOP); whether the next word is
  # a redirect target (RED) or a here-string (HS); and what separated it from
  # the command before (SEP).
  function newseg(sep) {
    CUR[LV] = ""; NW[LV] = 0; PREV[LV] = ""; HSH[LV] = 0; ARG[LV] = 0
    INR[LV] = 0; RED[LV] = 0; HS[LV] = 0; SEP[LV] = sep; PATHOP[LV] = 0
    SID[LV] = ++SEG; FIRST[LV] = ""; PSCR[LV] = ""; SCRW[LV] = 0; RUNNEXT[LV] = 0
  }
  # A file named where it is run: in command position, or as the first
  # operand of a shell, source or `.`. Compared by its spelling, so the
  # file a here-document wrote is recognised when the same spelling runs it.
  function runs(w) { sub(/^\.\//, "", w); RUN[w] = 1 }
  function endword(   w, b) {
    w = CUR[LV]; CUR[LV] = ""
    if (SCRW[LV]) { X[++NX] = sub_view(PSCR[LV]); PSCR[LV] = ""; SCRW[LV] = 0 }
    if (w == "") return
    if (RED[LV] && !(SID[LV] in TGT) && w !~ /^\/dev\//) TGT[SID[LV]] = w
    RED[LV] = 0; HS[LV] = 0
    if (NW[LV] == 0 && w ~ /^[A-Za-z_][A-Za-z0-9_]*=/) return
    if (NW[LV] == 0) { FIRST[LV] = base(w); runs(w) }
    else if (FIRST[LV] == "tee" && w !~ /^-/ && !(SID[LV] in TGT)) TGT[SID[LV]] = w
    if (RUNNEXT[LV] && w !~ /^-/) { runs(w); RUNNEXT[LV] = 0 }
    NW[LV]++; PREV[LV] = w; b = base(w)
    # A path is data to the shell, but to cp or tee it is the file written, and
    # the marker row is about exactly that operand. So a command with a word
    # that writes its operands keeps them as text, quoted or not; sed only
    # when it edits in place.
    if (b ~ /^(cp|mv|ln|install|tee|dd|truncate|rm|touch|rsync)$/) PATHOP[LV] = 1
    if (FIRST[LV] == "sed" && w ~ /^(-[A-Za-z]*i|--in-place)/) PATHOP[LV] = 1
    if (b ~ /^(bash|sh|zsh|dash|ksh|fish|source)$/ || NW[LV] == 1 && w == ".") RUNNEXT[LV] = 1
    if (b ~ /^(bash|sh|zsh|dash|ksh|fish)$/) { HSH[LV] = 1; INR[LV] = 1 }
    if (b ~ /^(eval|ssh|su|runuser|watch)$/) { ARG[LV] = 1; INR[LV] = 1 }
    if (b == "source" || NW[LV] == 1 && w == ".") INR[LV] = 1
    if (INR[LV] && SEP[LV] == "|") FB = 1
  }
  # Whether a quoted span here is a script something will run.
  function script() { return ARG[LV] || HSH[LV] && PREV[LV] ~ /^-[A-Za-z]*c[A-Za-z]*$/ }
  function quoted(t, glued) {
    if (HS[LV]) { if (INR[LV]) X[++NX] = sub_view(t); return "_" }
    if (script() && (SCRW[LV] || CUR[LV] == "")) { PSCR[LV] = PSCR[LV] t; SCRW[LV] = 1; return "_" }
    gsub(/\n/, " ", t)
    if (RED[LV] || PATHOP[LV] || glued || NW[LV] == 0 && CUR[LV] == "") return t
    if (t !~ /[ \t\n]/) return t
    if (t ~ /^(~\/|\.\.?\/|\$[A-Za-z_{]|\$\(_\))/) return t
    # Data, and kept by the command it belongs to: if that command writes a
    # file the same command line then runs, this is what the file says.
    WD[SID[LV]] = WD[SID[LV]] t "\n"
    return "_"
  }
  function word(t) { CUR[LV] = CUR[LV] t; return t }
  # An unquoted piece of a script word, which the shell joins to the rest.
  function piece(t) { if (SCRW[LV]) { PSCR[LV] = PSCR[LV] t; return "" }; return word(t) }
  function after(lim) { return I <= lim && C[I] !~ /[ \t\n;&|()<>]/ }
  function before() { return CUR[LV] != "" && CUR[LV] !~ /=$/ }
  function closeparen(lim,   d, e) {
    d = 0; e = I
    while (e <= lim) { if (C[e] == "(") d++; else if (C[e] == ")" && --d == 0) break; e++ }
    return e
  }

  # stop is "" for a whole string, ")" for a $( ), or a backtick; lim is the
  # last character of the string being read.
  function code(stop, lim,   out, ch, nx, t, e, k, d, dash, hw, hq, nh, HW, HD, HC, HQ, HSID, line, body, ls, depth, g) {
    LV++; newseg(""); out = ""; nh = 0; depth = 0
    while (I <= lim) {
      ch = C[I]; nx = I < lim ? C[I + 1] : ""
      if (stop == BQ && ch == BQ) { I++; break }
      if (ch == "\\") {
        if (nx == "\n") { I += 2; continue }
        out = out word(ch nx); I += 2; continue
      }
      if (ch == " " || ch == "\t") { endword(); out = out " "; I++; continue }
      if (ch == "(" && nx == "(" && CUR[LV] == "") {
        e = closeparen(lim); t = substr(S, I, e - I + 1); I = e + 1
        X[++NX] = sub_view(substr(t, 3, length(t) - 4)); out = out word("_"); continue
      }
      if (ch == "(") { endword(); depth++; out = out "("; I++; newseg("("); continue }
      if (ch == ")") {
        endword()
        if (depth > 0) { depth--; out = out ")"; I++; newseg(")"); continue }
        if (stop == ")") { I++; break }
        out = out ")"; I++; continue
      }
      if (ch == "&" && nx == ">") { endword(); out = out "&>"; I += 2; RED[LV] = 1; continue }
      if (ch == ";" || ch == "&" || ch == "|" || ch == "\n") {
        endword(); out = out (ch == "\n" ? " ; " : ch); I++; newseg(ch)
        if (ch == "\n" && nh > 0) {
          for (k = 1; k <= nh; k++) {
            body = ""
            while (I <= lim) {
              e = I; while (e <= lim && C[e] != "\n") e++
              line = substr(S, I, e - I); I = e + 1
              ls = line; if (HD[k]) sub(/^\t+/, "", ls)
              if (ls == HW[k]) break
              body = body line "\n"
            }
            if (HC[k]) X[++NX] = sub_view(body)
            else {
              if (!HQ[k]) expand(body)
              if (HSID[k] in TGT) { WT[++WN] = TGT[HSID[k]]; sub(/^\.\//, "", WT[WN]); WB[WN] = body }
            }
          }
          nh = 0
        }
        continue
      }
      if (ch == "#" && CUR[LV] == "") { while (I <= lim && C[I] != "\n") I++; continue }
      if (ch == "$" && nx == SQ) {
        g = before(); e = I + 2; t = ""
        while (e <= lim && C[e] != SQ) { if (C[e] == "\\") { t = t C[e]; e++ }; t = t C[e]; e++ }
        I = e + 1; out = out word(quoted(t, g || after(lim))); continue
      }
      if (ch == SQ) {
        g = before(); e = I + 1; while (e <= lim && C[e] != SQ) e++
        t = substr(S, I + 1, e - I - 1); I = e + 1
        out = out word(quoted(t, g || after(lim))); continue
      }
      if (ch == "\"" || ch == "$" && nx == "\"") {
        g = before(); I += (ch == "$") ? 2 : 1; t = ""
        while (I <= lim && C[I] != "\"") {
          if (C[I] == "\\") {
            if (C[I + 1] == "\n") { I += 2; continue }
            if (C[I + 1] ~ /["\\$`]/) { t = t C[I + 1]; I += 2; continue }
            t = t C[I]; I++; continue
          }
          if (C[I] == "$" && C[I + 1] == "(" && C[I + 2] != "(") {
            if (script()) FB = 1
            I += 2; t = t "$(_)"; X[++NX] = code(")", lim); continue
          }
          if (C[I] == BQ) { if (script()) FB = 1; I++; t = t "_"; X[++NX] = code(BQ, lim); continue }
          t = t C[I]; I++
        }
        I++
        out = out word(quoted(t, g || after(lim))); continue
      }
      if (ch == "$" && nx == "(") {
        if (C[I + 2] == "(") {
          I++; e = closeparen(lim); t = "$" substr(S, I, e - I + 1); I = e + 1; out = out word(t); continue
        }
        if (script()) FB = 1
        I += 2; out = out word("$(_)"); X[++NX] = code(")", lim); continue
      }
      if (ch == BQ) { if (script()) FB = 1; I++; out = out word("_"); X[++NX] = code(BQ, lim); continue }
      if ((ch == "<" || ch == ">") && nx == "(") {
        endword(); if (INR[LV]) FB = 1
        I += 2; out = out word(ch "(_)"); X[++NX] = code(")", lim); continue
      }
      if (ch == "<" && nx == "<" && C[I + 2] == "<") { endword(); out = out "<<<"; I += 3; HS[LV] = 1; continue }
      if (ch == "<" && nx == "<") {
        endword(); I += 2; dash = 0; hq = 0
        if (C[I] == "-") { dash = 1; I++ }
        while (I <= lim && (C[I] == " " || C[I] == "\t")) I++
        hw = ""
        if (C[I] == SQ || C[I] == "\"") {
          d = C[I]; e = I + 1; while (e <= lim && C[e] != d) e++
          hw = substr(S, I + 1, e - I - 1); I = e + 1; hq = 1
        } else {
          if (C[I] == "\\") { I++; hq = 1 }
          while (I <= lim && C[I] ~ /[A-Za-z0-9_.-]/) { hw = hw C[I]; I++ }
        }
        if (hw != "") { nh++; HW[nh] = hw; HD[nh] = dash; HC[nh] = INR[LV]; HQ[nh] = hq; HSID[nh] = SID[LV] }
        out = out "<<" hw " "; continue
      }
      if (ch == "<" || ch == ">") {
        endword(); out = out ch; I++
        while (I <= lim && C[I] ~ /[>&|]/) { out = out C[I]; I++ }
        RED[LV] = 1; continue
      }
      out = out piece(ch); I++
    }
    endword(); LV--
    return out
  }
'
