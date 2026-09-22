# felix audit: how often a turn stopped on an edit nothing had checked, read
# from the transcripts Claude Code already keeps.
#
# The cheapest way to try Felix is to be shown the problem it exists for, on
# your own record, before installing anything. So this is the one command that
# runs from a plain clone (git clone <felix> && felix/engine/harness/felix
# audit), and it is read-only by construction, not by care: the CLI dispatches
# it before any other library is sourced and before a home is resolved, it
# opens no file for writing, makes no temporary file (no here-document either:
# bash backs those with one), calls no model and touches no network. It reads
# DIR/*/*.jsonl, a transcript per file, DIR defaulting to
# ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects; an explicit --dir holding only
# transcripts is read as one project, DIR/*.jsonl. No transcripts is a report.
#
# One awk pass, because a heavy user keeps gigabytes of these, and no loop in
# it re-copies the rest of a line per step, because one line can hold
# megabytes. No JSON parser, on purpose (invariant 2), and why that is safe:
# every pattern below is structural — a key, a colon, a quoted value — and
# inside a JSON string every double quote is escaped, so `"type":"tool_use"`
# can only match the structure, never a message that quotes it.
#
# Per session, in file order:
#   an EDIT   a tool_use named Edit, Write, MultiEdit or NotebookEdit, unless
#             its file is scratch (/tmp, TMPDIR) or Claude's own (the config
#             directory: memory, plans): no gate covers those, and a stop they
#             alone precede is counted aside, and said
#   a CHECK   a Bash command (never its description) matching the verify
#             pattern outside quoted text and here-document bodies, save the
#             script a shell is handed (bash -c, bash <<EOF); it FAILED when
#             its tool_result says is_error:true
#   a STOP    a distinct end_turn message id. Claude Code writes a line per
#             content block, logs a message again later, and copies history
#             into a new file on resume or fork: none is a second stop, and a
#             copied one answers the edits before it
# and a stop with an edit since the previous one is exactly one of: passed
# (the last check after the last edit reported no error), failed (it did),
# stale (no check since the last edit, one before it) or never (no check in
# the session yet). A passed check whose exit status could not reach the
# transcript — piped, followed by another command, backgrounded, turned over
# by ! — is counted again on its own line, because "no error reported" is all
# it can say.
# isSidechain records and the subagents/ tree are never read; the report says
# so, since a session that delegated its testing reads as `never` here.
#
# A Felix hold is a meta user record (isMeta, as Claude Code writes what a
# hook returns) whose content starts "Stop hook feedback" and carries a
# sentence Felix's Stop hook uses when it refuses to let a turn end on an
# ungated tree. Quoted by a person, even as the first words of their message,
# or by an attachment, it is not one; copied into a resumed session, it is the
# same one. The four classes count only stops after an edit, and a hold can
# follow any stop, so each hold is told by the stop just before it: counted in
# the four, left out as after scratch edits only, after no new edit, or none
# that was read.

# What counts as a check when --verify is not given: the usual test and gate
# runners, at command position — the start of the command, or after ; & | ( or
# $( — behind any VAR=value, a wrapper (npx, env, nohup, sudo, timeout and
# the like, each with its options, or any `<tool> run` or `<tool> exec`), and
# a path. At command position so that `sed -n 1p tests/run` and `grep jest
# package.json` read as the reads they are. A value ends where the word does,
# so what follows `W=/w;` or a line break is the next command, and the path
# before a runner holds no = , so assigning `G=scripts/gate.sh` is not running
# it. The shell's reserved words stand where a command does, so the runner
# after if, then, else, elif, do, while, until, ! or { is run. Options may
# stand between a tool and its test command (make -C engine test, npm --prefix
# web test, pnpm --filter web test). The roster names the test runners of
# many ecosystems side by side on purpose, the way a probe does, and no list
# names them all: a runner it does not name is no check, and the report says
# so rather than calling the session unchecked. ecosystem.tsv carries the row.
FELIX_AUDIT_WORD='(if|then|else|elif|do|while|until|!|[{]) +'
FELIX_AUDIT_ASSIGN='[A-Za-z_][A-Za-z0-9_]*=[^ ;&|()]* +'
FELIX_AUDIT_OPTS='( +-[-A-Za-z0-9]+(=[^ ;&|()]*)?( +[^- ;&|()][^ ;&|()]*)?)*'
FELIX_AUDIT_WRAP='((env|time|exec|command|nice|nohup|sudo|bash|sh|zsh|npx|bunx)'"$FELIX_AUDIT_OPTS"'|timeout( +-[-A-Za-z]+( +[A-Z0-9][A-Za-z0-9]*)?)* +[0-9.]+[smhd]?) +'
FELIX_AUDIT_RUNNERS='(npm|pnpm|yarn|bun)'"$FELIX_AUDIT_OPTS"'( +workspace +[^ ;&|()]+)? +(run +)?(test|verify|check)'\
'|pytest|python[0-9.]*'"$FELIX_AUDIT_OPTS"' +-m +(pytest|unittest)|tox|nox|cargo +(test|check|nextest)|go +test'\
'|make'"$FELIX_AUDIT_OPTS"' +(test|check)|mvnw? +([^;&|]* +)?(test|verify)|gradlew? +([^;&|]* +)?(test|check)'\
'|rspec|phpunit|rake +(test|spec)|rails +test|php +artisan +test|dotnet +test|swift +test|mix +test|ctest'\
'|jest|vitest|mocha|playwright +test|deno +test|hardhat +test|forge +test|flutter +test|dart +test'\
'|sbt +test|lein +test|stack +test|cabal +test|zig +build +test|bazel +test'\
'|tests/run|gate[.]sh|felix +gate'
FELIX_AUDIT_CHECKS='(^|[;&|(]|[$][(])[ ]*('"$FELIX_AUDIT_WORD|$FELIX_AUDIT_ASSIGN|$FELIX_AUDIT_WRAP"'|[a-z]+ +(run|exec) +)*([^ ;&|()=]*/)?('"$FELIX_AUDIT_RUNNERS"')([^A-Za-z0-9_]|$)'
# Where a double-quoted span stands for a command, as "./tests/run" can: the
# same position, read on text whose line breaks are already ; .
FELIX_AUDIT_CMDPOS='(^|[;&|(])[ ]*('"$FELIX_AUDIT_WORD|$FELIX_AUDIT_ASSIGN|$FELIX_AUDIT_WRAP"')*$'

felix_audit_usage() {
  printf 'usage: felix audit [--dir DIR] [--since YYYY-MM-DD] [--verify ERE]\n'
  printf '  read-only: how often a turn stopped on an edit that no check had run after,\n'
  printf '  read from Claude Code transcripts. Writes nothing, installs nothing.\n'
  printf '  --dir DIR      transcripts to read, DIR/*/*.jsonl, or DIR/*.jsonl for one\n'
  printf '                 project (default: ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects)\n'
  printf '  --since DATE   count only stops and holds on or after this UTC date; what\n'
  printf '                 came before still says whether a check had run\n'
  printf '  --verify ERE   what counts as a check, in every project read: a Bash command\n'
  printf '                 matching this POSIX ERE, in place of the default runners\n'
}

_felix_audit_refuse() {
  printf 'felix audit: %s\n' "$1" >&2
  felix_audit_usage >&2
  return 2
}

# The pass. File names on stdin, one per line; out, one line of tab-separated
#   files sessions first last stops stop_sessions passed failed stale never
#   holds hold_sessions hidden aside unread held_counted held_aside held_noedit
# (first and last - where no record had a timestamp), then the first file that
# could not be read, if one. A session is the sessionId its records carry (the
# file name where they carry none), so one filed under two projects counts
# once, and a stop or a hold copied into a resumed session stays with the
# session it was made in, whichever transcript is read first.
felix_audit_scan() {
  awk '
  BEGIN {
    since = ENVIRON["FELIX_AUDIT_SINCE"]; vre = ENVIRON["FELIX_AUDIT_VERIFY"]
    Q = "\""; BS = "\\"; SQ = "\047"; UUID = "\"uuid\":\"[^\"]*\",$"
    K_SID = "\"sessionId\":\""; K_SIDE = "\"isSidechain\":true"; K_TS = "\"timestamp\":\""; K_MSG = "\"message\":{"
    K_ASST = "\"type\":\"assistant\""; K_USER = "\"type\":\"user\""; K_TYPE = "\"type\":\""
    K_USE = "\"type\":\"tool_use\""; K_RES = "\"type\":\"tool_result\""
    K_END = "\"stop_reason\":\"end_turn\""; K_TID = "\"tool_use_id\":\""
    K_ERR = "\"is_error\":true"; K_META = "\"isMeta\":true"; K_CMD = "\"command\":\""; K_BG = "\"run_in_background\":true"
    EDITS["Edit"]; EDITS["Write"]; EDITS["MultiEdit"]; EDITS["NotebookEdit"]
    naside = 0; ASIDE[++naside] = "/tmp/"; ASIDE[++naside] = "/private/tmp/"
    t = ENVIRON["FELIX_AUDIT_TMP"]; sub(/\/*$/, "/", t)
    if (length(t) > 1) { ASIDE[++naside] = t; if (t ~ /^\/var\//) ASIDE[++naside] = "/private" t }
    t = ENVIRON["FELIX_AUDIT_CFG"]; sub(/\/*$/, "/", t)
    if (length(t) > 1) ASIDE[++naside] = t
    # A backslash in a command is kept as \001 unless the pattern asks for one:
    # putting them back is a copy per backslash, and a command can hold 300,000.
    rejoin = index(vre, BS BS) > 0
    # What stands before a quote that makes the quoted text code: a shell and
    # its -c, whose script it is; or command position, behind any VAR=value and
    # wrapper, where a quoted path is the command itself.
    SHC = "(^|[^A-Za-z0-9_.-])(bash|sh|zsh)( +-[-A-Za-z]+| +-[A-Za-z]*o +[a-z]+)* +-[A-Za-z]*c +$"
    CMDPOS = ENVIRON["FELIX_AUDIT_CMDPOS"]
    first = ""; last = ""
  }

  # A short string value after a key: an id, a tool name, a path.
  function sval(s, k,    p, r, q) {
    p = index(s, k); if (!p) return ""
    r = substr(s, p + length(k), 1024); q = index(r, Q)
    return q ? substr(r, 1, q - 1) : ""
  }

  # The Bash command as JSON holds it, and that text unescaped to shell with
  # real line breaks. BWK awk spends minutes on a gsub over megabytes, so
  # here-documents go before decoding, and of a command still over 256K only
  # the first 64K and what follows its last quote are read: the ends hold the
  # runner and what takes its exit status, and past the last quote is outside.
  function rawcmd(s,    p, r) {
    p = index(s, K_CMD); if (!p) return ""
    r = substr(s, p + length(K_CMD))
    return match(r, /^([^"\\]|\\.)*/) ? substr(r, 1, RLENGTH) : ""
  }
  # A line that ends in an odd run of backslashes goes on to the next, as the
  # shell reads it: the last backslash and the line break go, before any line
  # break becomes a command boundary. Pairs of backslashes are set aside first,
  # since each is one escaped backslash.
  function decode(r,    n, P, i) {
    if (!index(r, BS)) return r
    gsub(/\\\\/, "\001", r)
    if (index(r, "\001" BS "n")) { gsub("\001\001", "\002", r); gsub("\001" BS BS "n", "", r); gsub("\002", "\001\001", r) }
    gsub(/\\"/, Q, r); gsub(/\\n/, "\n", r); gsub(/\\t/, " ", r)
    if (rejoin && index(r, "\001")) {
      n = split(r, P, "\001"); r = P[1]
      for (i = 2; i <= n; i++) r = r BS P[i]
    }
    return r
  }

  # A here-document body is text handed to a command, never a command, unless
  # the command is a shell: then the body is its script, and only the closing
  # line goes. Read on the JSON text, where a line break is backslash-n. It is
  # split once on << and once into lines, a line that could close a body is
  # filed under its word, and each word is looked up from a pointer that only
  # moves on, so a command of ten thousand << that are shifts costs one read.
  function heredocs(c,    n, P, m, L, LS, CL, NC, PT, k, j, w, d, at, ln, t, from, out) {
    if ((n = split(c, P, "<<")) < 2) return c
    m = split(c, L, BS BS "n"); LS[1] = 1
    for (k = 1; k <= m; k++) {
      LS[k + 1] = LS[k] + length(L[k]) + 2
      if (k > 1 && length(L[k]) <= 256) {
        w = L[k]; sub("^( |" BS BS "t)+", "", w)
        if (w ~ /^[A-Za-z_][A-Za-z0-9_]*$/) CL[w, ++NC[w]] = k
      }
    }
    out = ""; from = 1; at = 1; ln = 1
    for (k = 2; k <= n; k++) {
      at += length(P[k - 1]) + 2
      if (at < from) continue
      w = substr(P[k], 1, 256)
      if (!match(w, "^-?[ ]*(" SQ "|" BS BS Q ")?[A-Za-z_][A-Za-z0-9_]*")) continue
      d = substr(w, 1, RLENGTH); sub("^-?[ ]*(" SQ "|" BS BS Q ")?", "", d)
      while (ln < m && LS[ln + 1] <= at) ln++
      for (j = PT[d] + 1; j <= NC[d] && CL[d, j] <= ln; j++) ;
      PT[d] = j - 1
      if (j > NC[d]) continue
      t = CL[d, j]
      w = (k == 2) ? P[1] : P[k - 2] "<<" P[k - 1]
      if (k > 3 || length(w) > 64) w = "x" substr(w, length(w) > 64 ? length(w) - 63 : 1)
      if (w ~ ("(^|[ ;&|(]|" BS BS "n)([^ ;&|()]*/)?(bash|sh|zsh)( +-[-A-Za-z]+)*[ ]*$"))
        out = out substr(c, from, LS[t] - 2 - from) BS "n"
      else out = out substr(c, from, LS[ln + 1] - from)
      from = t < m ? LS[t + 1] : LS[m + 1] - 2
    }
    return out substr(c, from)
  }

  # Quoted text is an argument: a single-quoted span (a grep pattern), and a
  # double-quoted one (a message, an echo, a pattern) unless it stands where a
  # command does, as "./tests/run" or "$W/.venv/bin/python" can, where it is
  # the program, one word: read without its quotes, and with any blank or
  # ; & | ( ) in it as part of that word, so "npm test" as one name is not npm
  # (a path holding a blank is not read as a runner either). Or it holds a $(
  # that runs one, which is kept from there. The script a shell is handed with
  # -c is a command, and is read as one, from a line of its own. A # that
  # starts a word outside quotes starts a comment, which goes to the end of its
  # line before any quote in it is paired.
  # split(s, C, "") is a character per element in BWK awk, gawk and mawk alike.
  function unquote(c,    n, C, i, ch, out, q, st, s, w, p) {
    n = split(c, C, ""); out = ""; q = ""; st = 1
    for (i = 1; i <= n; i++) {
      ch = C[i]
      if ((ch == BS || ch == "\001") && q != SQ) { i++; continue }
      if (q == "") {
        if (ch == "#" && (i == 1 || index(" \n;&|()<>", C[i - 1]))) {
          out = out substr(c, st, i - st); while (i < n && C[i + 1] != "\n") i++
          st = i + 1; continue
        }
        if (ch == SQ || ch == Q) { out = out substr(c, st, i - st); q = ch; st = i }
      }
      else if (ch == q) {
        s = substr(c, st + 1, i - st - 1)
        w = st > 129 ? "x" substr(c, st - 128, 128) : substr(c, 1, st - 1); gsub(/\n/, ";", w)
        if (w ~ SHC) out = out "\n" unquote(s)
        else if (q == Q && !index(s, "\n")) {
          if (w ~ CMDPOS) { gsub(/[ ;&|()]/, "_", s); out = out s }
          else if (p = index(s, "$(")) out = out " " substr(s, p)
        }
        q = ""; st = i + 1
      }
    }
    return q == "" ? out substr(c, st) : out
  }

  # Whether the exit status of the last check could reach the transcript: not
  # when a later command, a pipe (without pipefail set as an option) or ||
  # takes it, nor when & sends it to the background, nor when a ! before it
  # turns it over. The } that closes a group hands it on, as the fi of an if
  # whose branch it ends does; the done of a loop does not, since an earlier
  # pass can fail unseen.
  function hidden(c,    s, off, e, a, b, t) {
    s = c; off = 0; e = 1; b = 1
    while (s != "" && match(s, vre)) {
      a = RSTART + RLENGTH - 1; if (a < 1) a = 1
      b = off + RSTART; e = off + a; off = e; s = substr(c, off + 1)
    }
    t = substr(c, b > 64 ? b - 64 : 1, e - (b > 64 ? b - 64 : 1) + 1); sub(/[;&|()]$/, "", t)
    if (t ~ /(^|[;&|(])[ ]*((if|elif|while|until|then|else|do|[{]) +)*! +[^;&|()]*$/) return 1
    t = substr(c, e); sub(/([; }]|[; ]fi)+$/, "", t)
    if (index(t, ";") || index(t, "||")) return 1
    if (index(t, "|") && c !~ /-[A-Za-z]*o +pipefail/) return 1
    gsub(/&&|[<>]&|&>/, "", t)
    return index(t, "&") > 0
  }

  # The quick test reads a quote as a command boundary, since what follows one
  # can be the script of a shell, and a double quote also as nothing, since
  # the quoted path before it can be the program; unquote() then decides what
  # the quotes held.
  function check(seg,    r, c, n, P, u, big, t) {
    r = heredocs(rawcmd(seg)); if (r == "") return 0
    if (big = ((n = length(r)) > 262144)) {
      c = decode(substr(r, n - 65535)); n = split(c, P, "[" Q SQ "]")
      c = decode(substr(r, 1, 65536)); u = unquote(c) "\n" P[n]; c = c "\n" P[n]
    } else c = decode(r)
    r = c; gsub(/\n/, ";", r); gsub(SQ, ";", r); t = r; gsub(Q, "", t); gsub(Q, ";", r)
    if (r !~ vre && t !~ vre) return 0
    if (!big) u = unquote(c)
    gsub(/\n/, ";", u); if (u !~ vre) return 0
    HID = index(seg, K_BG) || hidden(u)
    return 1
  }

  function edit(seg,    p, k) {
    p = sval(seg, "\"file_path\":\""); if (p == "") p = sval(seg, "\"notebook_path\":\"")
    if (p != "") for (k = 1; k <= naside; k++) if (index(p, ASIDE[k]) == 1) { aside = 1; return }
    last_edit = pos; edited = 1
  }

  # A tool_use block whose "type" is not its first key (Claude Code writes it
  # first), or whose input comes before its id and name: its own keys, at its
  # own depth, from its opening brace to its close.
  function own(pre, seg,    n, C, i, ch, s, d, sp, stk, st, v, k) {
    n = split(pre, C, ""); s = 0; sp = 0
    for (i = 1; i <= n; i++) {
      ch = C[i]
      if (s) { if (ch == BS) i++; else if (ch == Q) s = 0; continue }
      if (ch == Q) s = 1; else if (ch == "{") stk[++sp] = i; else if (ch == "}" && sp) sp--
    }
    BLK = substr(pre, sp ? stk[sp] : 1) K_USE seg
    n = split(BLK, C, ""); s = 0; d = 0; k = ""; OWN["id"] = ""; OWN["name"] = ""
    for (i = 1; i <= n; i++) {
      ch = C[i]
      if (s) { if (ch == BS) i++; else if (ch == Q) { s = 0; v = substr(BLK, st, i - st)
                 if (d == 1) { if (C[i + 1] == ":") k = v; else { if (k in OWN) OWN[k] = v; k = "" } } }
               continue }
      if (ch == Q) { s = 1; st = i + 1 }
      else if (ch == "{" || ch == "[") { if (d++ == 1) k = "" }
      else if ((ch == "}" || ch == "]") && --d == 0) break
    }
    BLK = substr(BLK, 1, i)
  }

  function reset() {
    edited = 0; aside = 0; pos = 0; lastd = ""
    last_edit = 0; last_chk = 0; last_chk_id = ""; last_hid = 0; any_chk = 0
    split("", chk); split("", failed); split("", used)
  }

  # Every tool_use block on the line. Claude Code writes one per line, but a
  # line holding several is read block by block. Its own id and name come
  # before its input there, and are read straight off; where the input comes
  # first, an id or a name inside it would be read instead, so the block is
  # read by depth, as one whose type is not first is.
  function uses(l,    n, S, i, pre, seg, id, name, pi, fast) {
    n = split(l, S, K_USE)
    for (i = 2; i <= n; i++) {
      pre = S[i - 1]; seg = S[i]; fast = 0
      if (substr(pre, length(pre)) == "{") {
        id = index(seg, "\"id\":\""); name = index(seg, "\"name\":\""); pi = index(seg, "\"input\":")
        if (id && name && (!pi || (id < pi && name < pi))) fast = 1; else pre = "{"
      }
      if (fast) { id = sval(seg, "\"id\":\""); name = sval(seg, "\"name\":\"") }
      else { own(pre, seg); id = OWN["id"]; name = OWN["name"]; seg = BLK }
      if (id != "") { if (id in used) continue; used[id] = 1 }
      pos++
      if (name in EDITS) edit(seg)
      else if (name == "Bash" && check(seg)) {
        last_chk = pos; last_chk_id = id; last_hid = HID; any_chk = 1
        if (id != "") chk[id] = 1
      }
    }
  }

  # The message id a stop is known by: the API id where there is one.
  function msgid(l,    p, r) {
    if (p = index(l, "\"id\":\"msg_")) return sval(substr(l, p, 300), "\"id\":\"")
    if ((p = index(l, K_MSG)) && (r = sval(substr(l, p), "\"id\":\"")) != "") return r
    return (r = sval(l, "\"uuid\":\"")) != "" ? r : "line " (++anon)
  }

  # lastd is what the stop was, for a hold after it: c counted in the four, a
  # left out as after scratch edits only, n after no new edit. One before the
  # --since cutoff ends its turn and is counted nowhere.
  function stop() {
    if (cut) { edited = 0; aside = 0; lastd = ""; return }
    if (!edited) { if (aside) { naside_stops++; lastd = "a" } else lastd = "n"; aside = 0; return }
    edited = 0; aside = 0; stops++; lastd = "c"; if (!(SK in S2)) { S2[SK] = 1; stop_sessions++ }
    if (last_chk > last_edit) { if (last_chk_id in failed) nfail++; else { npass++; if (last_hid) nhid++ } }
    else if (any_chk) nstale++
    else nnever++
  }

  # A failed result marks its check. A line holding more than one tool_result
  # is cut between them, at the last "},{" before each next marker, so an
  # error is only ever charged to the block that reported it.
  function mark(seg,    n, P, i, id) {
    if (!index(seg, K_ERR)) return
    n = split(seg, P, K_TID)
    for (i = 2; i <= n; i++) { id = substr(P[i], 1, index(P[i], Q) - 1); if (id in chk) failed[id] = 1 }
  }
  function results(l,    n, P, m, k, b, region, R, c, j, t) {
    n = split(l, P, K_RES) - 1
    if (n <= 1) { mark(l); return }
    m[1] = length(P[1]) + 1
    for (k = 2; k <= n; k++) m[k] = m[k - 1] + length(K_RES) + length(P[k])
    b[0] = 1
    for (k = 1; k < n; k++) {
      region = substr(l, m[k], m[k + 1] - m[k]); c = split(region, R, "}"); t = 0; b[k] = m[k + 1]
      for (j = c; j > 1; j--) {
        t += length(R[j]) + 1
        if (substr(R[j], 1, 2) == ",{") { b[k] = m[k] + length(region) - t + 2; break }
      }
      mark(substr(l, b[k - 1], b[k] - b[k - 1]))
    }
    mark(substr(l, b[n - 1]))
  }

  # A record s own timestamp follows its uuid; a nested one, in a message or a
  # tool result, does not. Where none does, the last is taken.
  function stamp(l,    p, n, T, i, x, pre) {
    TS = ""; UU = ""; p = index(l, K_TS); if (!p) return
    pre = substr(l, p > 64 ? p - 64 : 1, p > 64 ? 64 : p - 1)
    if (match(pre, UUID)) TS = substr(l, p + length(K_TS), 10)
    else {
      n = split(l, T, K_TS)
      for (i = 2; i <= n; i++) {
        x = length(T[i - 1]); pre = substr(T[i - 1], x > 64 ? x - 63 : 1)
        if (match(pre, UUID)) break
      }
      if (i > n) { i = n; pre = "" }
      TS = substr(T[i], 1, 10)
    }
    if (pre != "" && match(pre, UUID)) UU = substr(pre, RSTART + 8, RLENGTH - 10)
    if (UU != "") { x = substr(l, p + length(K_TS), 40); UU = UU " " substr(x, 1, index(x, Q) - 1) }
    if (TS !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) TS = ""
  }

  # Whose record a line is, from its own keys: isSidechain and a user type sit
  # before its message, an assistant type after it (or before, when synthetic);
  # any other type first is a progress or attachment record, which may nest one.
  # A record before the --since cutoff is read for what it did, an edit or a
  # check, so a stop after the cutoff is told by all of its session; only its
  # own stops and holds, and its dates, are not counted.
  function record(l,    im, p, r, v) {
    im = index(l, K_MSG)
    p = index(l, K_SIDE); if (p && (!im || p < im)) return
    stamp(l); cut = (since != "" && TS != "" && TS < since)
    SK = sval(l, K_SID); if (SK == "") SK = BASE
    if (TS != "" && !cut) {
      if (!(SK in S1)) { S1[SK] = 1; sessions++ }
      if (first == "" || TS < first) first = TS
      if (TS > last) last = TS
    }
    if (!im) return
    if ((p = index(l, K_USER)) && p < im) r = "u"
    else if ((p = index(l, K_ASST)) && p < im) r = "a"
    else if ((p = index(l, K_TYPE)) && p < im) return
    else {
      p = index(l, "\"role\":\""); v = p ? substr(l, p + 8, 10) : ""
      if (v == "assistant\"") r = "a"; else if (substr(v, 1, 5) == "user\"") r = "u"; else return
    }
    if (r == "a") {
      if (index(l, K_USE)) uses(l)
      if (index(l, K_END)) {
        r = msgid(l)
        if (!(r in stopped)) { stopped[r] = fno; stop(); sdisp[r] = lastd }
        else if (stopped[r] != fno) { edited = 0; aside = 0; lastd = sdisp[r] }
      }
      return
    }
    if (index(l, K_TID)) { if (index(l, K_ERR)) results(l); return }
    if (index(l, K_META) && (index(l, "\"content\":\"Stop hook feedback") || index(l, "\"text\":\"Stop hook feedback")) \
        && (index(l, "The gate last ran at") || index(l, "The gate has never run") \
            || index(l, "The gate failed on this exact tree") || index(l, "The gate passed on this exact tree at")) \
        && !cut && (UU == "" || !(UU in held))) {
      if (UU != "") held[UU] = 1
      holds++; if (!(SK in S3)) { S3[SK] = 1; hold_sessions++ }
      if (lastd == "c") hcount++; else if (lastd == "a") haside++; else if (lastd == "n") hnoedit++
    }
  }

  NF {
    f = $0; files++; fno++; reset(); BASE = f; sub(/.*\//, "", BASE); sub(/[.]jsonl$/, "", BASE)
    if ((st = (getline line < f)) < 0) { if (!unread++) unread1 = f; next }
    while (st > 0) { record(line); st = (getline line < f) }
    close(f)
  }

  END {
    printf "%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n", files, sessions, \
      (first == "" ? "-" : first), (last == "" ? "-" : last), stops, stop_sessions, \
      npass, nfail, nstale, nnever, holds, hold_sessions, nhid, naside_stops, unread, \
      hcount, haside, hnoedit
    if (unread) print unread1
  }'
}

_felix_audit_n() {     # count noun -> "1 stop", "4 stops"
  [ "$1" = 1 ] && printf '1 %s' "$2" || printf '%s %ss' "$1" "$2"
}

_felix_audit_pct() {   # part whole -> whole-number percent
  [ "$2" -gt 0 ] || { printf '0'; return; }
  printf '%d' $(( (100 * $1 + $2 / 2) / $2 ))
}

_felix_audit_list() {  # dir mode -> the transcripts, one per line; mode 2 is one project's
  local f g="*/*.jsonl"; [ "$2" -eq 2 ] && g="*.jsonl"
  for f in "$1"/$g; do if [ -f "$f" ]; then printf '%s\n' "$f"; fi; done
}

# What the stop just before each hold was. Holds are read from every stop hook
# feedback, the four classes only from stops after an edit, so a held stop is
# among the stops above only when an edit came before it; most real holds
# follow a turn that edited nothing, and a sentence saying every held stop is
# counted there was false for them.
_felix_audit_held() {  # holds counted aside noedit -> the clauses, joined by "; "
  local all="$1" out="" k n one many
  for k in c a n x; do
    case "$k" in
      c) n="$2"; one="is still counted above, where the turn tried to end"
         many="are still counted above, where the turn tried to end" ;;
      a) n="$3"; one="followed edits only to scratch files or Claude's own, left out above"; many="$one" ;;
      n) n="$4"; one="followed a turn with no new edit"; many="$one" ;;
      x) n=$(($1 - $2 - $3 - $4)); one="had no stop before it in what was read"
         many="had no stop before them in what was read" ;;
    esac
    [ "$n" -gt 0 ] || continue
    [ "$n" -eq 1 ] || one="$many"
    if [ "$n" -eq "$all" ]; then
      case "$n" in 1) out="It $one" ;; 2) out="Both $one" ;; *) out="All $n $one" ;; esac
    elif [ -z "$out" ]; then out="$n of them $one"
    else out="$out; $n $one"
    fi
  done
  printf '%s' "$out"
}

_felix_audit_next() {
  printf 'Next, still cheap: felix new <name> --no-commission binds one project (its rules, a gate guess, a marker) with no plugin installs and no network; its sessions are held once felix install has run and project.json names a gate.\n'
}

felix_audit() {
  local dir="" since="" verify="" explicit=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --dir)    [ $# -ge 2 ] && [ -n "$2" ] || { _felix_audit_refuse "--dir needs a value"; return; }
                dir="$2"; explicit=1; shift 2 ;;
      --since)  [ $# -ge 2 ] && [ -n "$2" ] || { _felix_audit_refuse "--since needs a value"; return; }
                since="$2"; shift 2 ;;
      --verify) [ $# -ge 2 ] && [ -n "$2" ] || { _felix_audit_refuse "--verify needs a value"; return; }
                verify="$2"; shift 2 ;;
      -h|--help) felix_audit_usage; return 0 ;;
      *) _felix_audit_refuse "unknown argument: $1"; return ;;
    esac
  done
  # A date, and a real month and day: it is compared as text, so 2026-19-39
  # would be a cutoff nobody meant rather than an error.
  case "$since" in
    '') ;;
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
      [ "1${since:5:2}" -ge 101 ] && [ "1${since:5:2}" -le 112 ] \
        && [ "1${since:8:2}" -ge 101 ] && [ "1${since:8:2}" -le 131 ] \
        || { _felix_audit_refuse "--since takes a date, YYYY-MM-DD; got: $since"; return; } ;;
    *) _felix_audit_refuse "--since takes a date, YYYY-MM-DD; got: $since"; return ;;
  esac
  # Perl and GNU escapes read as a plain letter on some awks and as a class on
  # others, so the same flag would answer differently on macOS and Linux.
  case "$verify" in
    *'\s'*|*'\S'*|*'\d'*|*'\D'*|*'\w'*|*'\W'*|*'\b'*|*'\B'*|*'\y'*|*'\<'*|*'\>'*)
      _felix_audit_refuse "--verify is a POSIX ERE, where \\s \\d \\w \\b are not classes on every awk; use [[:space:]], [[:digit:]], [[:alnum:]_], ([^[:alnum:]_]|\$): $verify"; return ;;
  esac
  if [ -n "$verify" ] && ! FELIX_AUDIT_VERIFY="$verify" awk 'BEGIN { if ("" ~ ENVIRON["FELIX_AUDIT_VERIFY"]) x = 1 }' 2>/dev/null; then
    _felix_audit_refuse "--verify is not an extended regular expression awk can read: $verify"; return
  fi
  local cfg="${CLAUDE_CONFIG_DIR:-}"
  [ -n "$cfg" ] || [ -z "${HOME:-}" ] || cfg="$HOME/.claude"
  [ -n "$dir" ] || dir="${cfg:+$cfg/projects}"
  [ "$dir" = "/" ] || dir="${dir%/}"
  if [ "$explicit" -eq 1 ] && [ ! -d "$dir" ]; then
    _felix_audit_refuse "--dir $dir is not a directory"; return
  fi

  printf 'felix audit: read-only. Nothing was written, installed or sent.\n\n'

  local f mode=0
  if [ -n "$dir" ]; then
    for f in "$dir"/*/*.jsonl; do if [ -f "$f" ]; then mode=1; break; fi; done
    if [ "$mode" -eq 0 ] && [ "$explicit" -eq 1 ]; then
      for f in "$dir"/*.jsonl; do if [ -f "$f" ]; then mode=2; break; fi; done
    fi
  fi
  if [ "$mode" -eq 0 ]; then
    if [ -z "$dir" ]; then
      printf 'No Claude Code transcripts found: neither CLAUDE_CONFIG_DIR nor HOME is set, so there is nowhere to look.\n'
    else
      printf 'No Claude Code transcripts found in %s.\n' "$dir"
    fi
    printf 'It reads DIR/*/*.jsonl, or DIR/*.jsonl for one project; point it elsewhere with --dir DIR.\n\n'
    _felix_audit_next
    return 0
  fi

  local t bad=""
  t="$(_felix_audit_list "$dir" "$mode" \
       | FELIX_AUDIT_SINCE="$since" FELIX_AUDIT_VERIFY="${verify:-$FELIX_AUDIT_CHECKS}" FELIX_AUDIT_CMDPOS="$FELIX_AUDIT_CMDPOS" \
         FELIX_AUDIT_CFG="$cfg" FELIX_AUDIT_TMP="${TMPDIR:-}" felix_audit_scan)" \
    || { printf 'felix audit: the read failed part way; nothing to report\n' >&2; return 1; }
  case "$t" in *$'\n'*) bad="${t#*$'\n'}"; t="${t%%$'\n'*}" ;; esac
  # Eighteen fields, none empty and none with a space, so plain word splitting
  # reads them; a tab-IFS read of a substitution is the trap the constitution
  # names, and this avoids needing one.
  # shellcheck disable=SC2086
  set -- $t
  [ $# -eq 18 ] || { printf 'felix audit: the read returned %s fields, not 18; nothing to report\n' "$#" >&2; return 1; }
  local nfiles="$1" sessions="$2" first="$3" last="$4" stops="$5" ssess="$6"
  local passed="$7" failed="$8" stale="$9" never="${10}" holds="${11}" hsess="${12}"
  local hid="${13}" aside="${14}" unread="${15}" hcount="${16}" haside="${17}" hnoedit="${18}"

  printf '  transcripts  %s%s\n' "$dir" "$([ "$mode" -eq 2 ] && printf ' (one project: DIR/*.jsonl)')"
  local span=", from $first to $last${since:+ (--since $since)}"
  [ "$first" = "$last" ] && span=", all on $first${since:+ (--since $since)}"
  [ "$first" = "-" ] && span=""
  # A transcript can hold records and still no session: summaries carry no
  # timestamp, and --since can put every stamp before the cutoff.
  [ "$sessions" -eq 0 ] && span=": $(_felix_audit_n "$nfiles" transcript) read, holding no timestamped record${since:+ on or after $since}"
  printf '  sessions     %s%s\n\n' "$sessions" "$span"

  printf '%s came after an edit, in %s. Where each one stood:\n\n' \
    "$(_felix_audit_n "$stops" stop)" "$(_felix_audit_n "$ssess" session)"
  printf '  passed  %5s  %3s%%  the last check after the last edit reported no error\n' \
    "$passed" "$(_felix_audit_pct "$passed" "$stops")"
  [ "$hid" -gt 0 ] && \
    printf '                      and %s of those could not have: piped, followed by another command, backgrounded, or turned over by !\n' "$hid"
  printf '  failed  %5s  %3s%%  the last check after the last edit failed, and the turn stopped anyway\n' \
    "$failed" "$(_felix_audit_pct "$failed" "$stops")"
  printf '  stale   %5s  %3s%%  a check ran earlier in the session, but none after the last edit\n' \
    "$stale" "$(_felix_audit_pct "$stale" "$stops")"
  printf '  never   %5s  %3s%%  no check it recognises had run in the session at all\n\n' \
    "$never" "$(_felix_audit_pct "$never" "$stops")"

  [ "$aside" -gt 0 ] && \
    printf 'Left out: %s after edits only to scratch files or Claude'"'"'s own (memory, plans, settings), which no gate covers.\n\n' \
      "$(_felix_audit_n "$aside" stop)"
  [ "$holds" -gt 0 ] && \
    printf 'Felix held %s, in %s, because no passing gate result was current for the tree. %s.\n\n' \
      "$(_felix_audit_n "$holds" stop)" "$(_felix_audit_n "$hsess" session)" \
      "$(_felix_audit_held "$holds" "$hcount" "$haside" "$hnoedit")"
  [ "$unread" -gt 0 ] && \
    printf 'Not read: %s could not be opened (the first: %s).\n\n' "$(_felix_audit_n "$unread" transcript)" "$bad"

  if [ -n "$verify" ]; then
    printf 'A check is a Bash command matching --verify %s, in every project read, outside quoted text and here-documents, save a script handed to a shell.\n' "'$verify'"
  else
    printf 'A check is a Bash command running tests or a gate (npm test, pytest, cargo test, go test, make check, jest, vitest, felix gate and the like), outside quoted text and here-documents, save a script handed to a shell. A runner it does not name is not a check, so a session that ran only one reads as never; --verify ERE replaces that list for every project read (--dir one project'"'"'s directory to narrow it).\n'
  fi
  printf 'A check piped into another command, followed by one, run in the background or turned over by ! hands its exit status to something else, so its own failure goes unseen: a stop after one is counted failed only when what took that status failed.\n'
  printf 'Subagents are not seen: their edits and checks sit in files this does not read.\n\n'
  _felix_audit_next
  return 0
}
