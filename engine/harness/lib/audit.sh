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
# DIR/*/*.jsonl, a session per file, DIR defaulting to
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
#             pattern outside quotes and here-document bodies; it FAILED when
#             its tool_result says is_error:true
#   a STOP    a distinct end_turn message id. Claude Code writes a line per
#             content block, logs a message again later, and copies history
#             into a new file on resume or fork: none is a second stop, and a
#             copied one answers the edits before it
# and a stop with an edit since the previous one is exactly one of: passed
# (the last check after the last edit reported no error), failed (it did),
# stale (no check since the last edit, one before it) or never (no check in
# the session yet). A passed check whose exit status could not reach the
# transcript — piped, followed by another command, backgrounded — is counted
# again on its own line, because "no error reported" is all it can say.
# isSidechain records and the subagents/ tree are never read; the report says
# so, since a session that delegated its testing reads as `never` here.
#
# A Felix hold is a user record whose content starts "Stop hook feedback" and
# carries a sentence Felix's Stop hook uses when it refuses to let a turn end
# on an ungated tree. Quoted by a person or an attachment, it is not one;
# copied into a resumed session, it is the same one.

# What counts as a check when --verify is not given: the usual test and gate
# runners, at command position — the start of the command, or after ; & | ( or
# $( — behind any VAR=value, a wrapper (npx, or any `<tool> run` or `<tool>
# exec`), and a path. At command position so that `sed -n 1p tests/run` and
# `grep jest package.json` read as the reads they are. The roster names test
# runners across every ecosystem on purpose, the way a probe does; ecosystem.tsv
# carries the row that says so.
FELIX_AUDIT_CHECKS='(^|[;&|(]|[$][(])[ ]*([A-Za-z_][A-Za-z0-9_]*=[^ ]* +)*((env|time|exec|command|nice|timeout +[0-9.smh]+|bash|sh|zsh|npx|bunx|[a-z]+ +(run|exec)) +)*([^ ;&|()]*/)?((npm|pnpm|yarn|bun) +(run +)?(test|verify|check)|pytest|python[0-9.]* +-m +pytest|tox|cargo +(test|check|nextest)|go +test|make +(test|check)|mvnw? +([^;&|]* +)?(test|verify)|gradlew? +([^;&|]* +)?(test|check)|rspec|phpunit|dotnet +test|swift +test|mix +test|ctest|jest|vitest|tests/run|gate[.]sh|felix +gate)([^A-Za-z0-9_]|$)'

felix_audit_usage() {
  printf 'usage: felix audit [--dir DIR] [--since YYYY-MM-DD] [--verify ERE]\n'
  printf '  read-only: how often a turn stopped on an edit that no check had run after,\n'
  printf '  read from Claude Code transcripts. Writes nothing, installs nothing.\n'
  printf '  --dir DIR      transcripts to read, DIR/*/*.jsonl, or DIR/*.jsonl for one\n'
  printf '                 project (default: ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects)\n'
  printf '  --since DATE   skip records timestamped before this UTC date\n'
  printf '  --verify ERE   what counts as a check: a Bash command matching this POSIX ERE\n'
}

_felix_audit_refuse() {
  printf 'felix audit: %s\n' "$1" >&2
  felix_audit_usage >&2
  return 2
}

# The pass. File names on stdin, one per line; out, one line of tab-separated
#   files sessions first last stops stop_sessions passed failed stale never
#   holds hold_sessions hidden aside unread
# (first and last - where no record had a timestamp), then the first file that
# could not be read, if one. A session filed under two projects counts once.
felix_audit_scan() {
  awk '
  BEGIN {
    since = ENVIRON["FELIX_AUDIT_SINCE"]; vre = ENVIRON["FELIX_AUDIT_VERIFY"]
    Q = "\""; BS = "\\"; SQ = "\047"; UUID = "\"uuid\":\"[^\"]*\",$"
    K_SIDE = "\"isSidechain\":true"; K_TS = "\"timestamp\":\""; K_MSG = "\"message\":{"
    K_ASST = "\"type\":\"assistant\""; K_USER = "\"type\":\"user\""; K_TYPE = "\"type\":\""
    K_USE = "\"type\":\"tool_use\""; K_RES = "\"type\":\"tool_result\""
    K_END = "\"stop_reason\":\"end_turn\""; K_TID = "\"tool_use_id\":\""
    K_ERR = "\"is_error\":true"; K_CMD = "\"command\":\""; K_BG = "\"run_in_background\":true"
    EDITS["Edit"]; EDITS["Write"]; EDITS["MultiEdit"]; EDITS["NotebookEdit"]
    naside = 0; ASIDE[++naside] = "/tmp/"; ASIDE[++naside] = "/private/tmp/"
    t = ENVIRON["FELIX_AUDIT_TMP"]; sub(/\/*$/, "/", t)
    if (length(t) > 1) { ASIDE[++naside] = t; if (t ~ /^\/var\//) ASIDE[++naside] = "/private" t }
    t = ENVIRON["FELIX_AUDIT_CFG"]; sub(/\/*$/, "/", t)
    if (length(t) > 1) ASIDE[++naside] = t
    # A backslash in a command is kept as \001 unless the pattern asks for one:
    # putting them back is a copy per backslash, and a command can hold 300,000.
    rejoin = index(vre, BS BS) > 0
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
  function decode(r,    n, P, i) {
    if (!index(r, BS)) return r
    gsub(/\\\\/, "\001", r); gsub(/\\"/, Q, r); gsub(/\\n/, "\n", r); gsub(/\\t/, " ", r)
    if (rejoin && index(r, "\001")) {
      n = split(r, P, "\001"); r = P[1]
      for (i = 2; i <= n; i++) r = r BS P[i]
    }
    return r
  }

  # A here-document body is text handed to a command, never a command. Read on
  # the JSON text, where a line break is backslash-n.
  function heredocs(c,    out, p, rest, d, t) {
    out = ""
    while ((p = index(c, "<<")) > 0) {
      out = out substr(c, 1, p + 1); rest = substr(c, p + 2); c = rest
      if (!match(rest, "^-?[ ]*(" SQ "|" BS BS Q ")?[A-Za-z_][A-Za-z0-9_]*")) continue
      d = substr(rest, 1, RLENGTH); sub("^-?[ ]*(" SQ "|" BS BS Q ")?", "", d)
      if (!(p = index(rest, BS "n"))) continue
      t = substr(rest, p)
      if (!match(t, BS BS "n( |" BS BS "t)*" d "(" BS BS "n|$)")) continue
      out = out substr(rest, 1, p + 1); c = substr(t, RSTART + RLENGTH)
    }
    return out c
  }

  # Quoted text is an argument: a single-quoted span always (a grep pattern), a
  # double-quoted one when it runs over a line (a commit message). split(s, C,
  # "") is a character per element in BWK awk, gawk and mawk alike.
  function unquote(c,    n, C, i, ch, out, q, st) {
    n = split(c, C, ""); out = ""; q = ""; st = 1
    for (i = 1; i <= n; i++) {
      ch = C[i]
      if ((ch == BS || ch == "\001") && q != SQ) { i++; continue }
      if (q == "") { if (ch == SQ || ch == Q) { out = out substr(c, st, i - st); q = ch; st = i } }
      else if (ch == q) {
        if (q == Q && !index(substr(c, st, i - st), "\n")) out = out substr(c, st, i - st + 1)
        q = ""; st = i + 1
      }
    }
    return q == "" ? out substr(c, st) : out
  }

  # Whether the exit status of the last check could reach the transcript: not
  # when a later command, a pipe (without pipefail) or || takes it, nor when
  # & sends it to the background.
  function hidden(c,    s, off, e, a, t) {
    s = c; off = 0; e = 1
    while (s != "" && match(s, vre)) {
      a = RSTART + RLENGTH - 1; if (a < 1) a = 1
      e = off + a; off = e; s = substr(c, off + 1)
    }
    t = substr(c, e); sub(/[; ]+$/, "", t)
    if (index(t, ";") || index(t, "||")) return 1
    if (index(t, "|") && !index(c, "pipefail")) return 1
    gsub(/&&|[<>]&|&>/, "", t)
    return index(t, "&") > 0
  }

  function check(seg,    r, c, n, P) {
    r = heredocs(rawcmd(seg)); if (r == "") return 0
    if ((n = length(r)) > 262144) {
      c = decode(substr(r, n - 65535)); n = split(c, P, "[" Q SQ "]")
      c = unquote(decode(substr(r, 1, 65536))) "\n" P[n]
    } else c = decode(r)
    r = c; gsub(/\n/, ";", r); if (r !~ vre) return 0
    c = unquote(c); gsub(/\n/, ";", c); if (c !~ vre) return 0
    HID = index(seg, K_BG) || hidden(c)
    return 1
  }

  function edit(seg,    p, k) {
    p = sval(seg, "\"file_path\":\""); if (p == "") p = sval(seg, "\"notebook_path\":\"")
    if (p != "") for (k = 1; k <= naside; k++) if (index(p, ASIDE[k]) == 1) { aside = 1; return }
    last_edit = pos; edited = 1
  }

  # A tool_use block whose "type" is not its first key (Claude Code writes it
  # first): its own keys, at its own depth, from its opening brace to its close.
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
    seen = 0; sstops = 0; sholds = 0; edited = 0; aside = 0; pos = 0
    last_edit = 0; last_chk = 0; last_chk_id = ""; last_hid = 0; any_chk = 0
    split("", chk); split("", failed); split("", used)
  }

  # Every tool_use block on the line. Claude Code writes one per line, but a
  # line holding several is read block by block.
  function uses(l,    n, S, i, pre, seg, id, name) {
    n = split(l, S, K_USE)
    for (i = 2; i <= n; i++) {
      pre = S[i - 1]; seg = S[i]
      if (substr(pre, length(pre)) == "{") { id = sval(seg, "\"id\":\""); name = sval(seg, "\"name\":\"") }
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

  function stop() {
    if (!edited) { if (aside) naside_stops++; aside = 0; return }
    edited = 0; aside = 0; stops++; sstops++
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
  function record(l,    im, p, r, v) {
    im = index(l, K_MSG)
    p = index(l, K_SIDE); if (p && (!im || p < im)) return
    stamp(l)
    if (TS != "") {
      if (since != "" && TS < since) return
      seen = 1
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
        if (!(r in stopped)) { stopped[r] = fno; stop() }
        else if (stopped[r] != fno) { edited = 0; aside = 0 }
      }
      return
    }
    if (index(l, K_TID)) { if (index(l, K_ERR)) results(l); return }
    if ((index(l, "\"content\":\"Stop hook feedback") || index(l, "\"text\":\"Stop hook feedback")) \
        && (index(l, "The gate last ran at") || index(l, "The gate has never run") \
            || index(l, "The gate failed on this exact tree") || index(l, "The gate passed on this exact tree at")) \
        && (UU == "" || !(UU in held))) {
      if (UU != "") held[UU] = 1
      holds++; sholds++
    }
  }

  NF {
    f = $0; files++; fno++; reset()
    if ((st = (getline line < f)) < 0) { if (!unread++) unread1 = f; next }
    while (st > 0) { record(line); st = (getline line < f) }
    close(f)
    b = f; sub(/.*\//, "", b)
    if (seen && !(b in S1)) { S1[b] = 1; sessions++ }
    if (sstops && !(b in S2)) { S2[b] = 1; stop_sessions++ }
    if (sholds && !(b in S3)) { S3[b] = 1; hold_sessions++ }
  }

  END {
    printf "%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n", files, sessions, \
      (first == "" ? "-" : first), (last == "" ? "-" : last), stops, stop_sessions, \
      npass, nfail, nstale, nnever, holds, hold_sessions, nhid, naside_stops, unread
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

_felix_audit_next() {
  printf 'Next, still cheap: felix new <name> --no-commission binds one project (its rules, a gate guess, a marker) with no plugin installs and no network; its sessions are held once felix install has run.\n'
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
       | FELIX_AUDIT_SINCE="$since" FELIX_AUDIT_VERIFY="${verify:-$FELIX_AUDIT_CHECKS}" \
         FELIX_AUDIT_CFG="$cfg" FELIX_AUDIT_TMP="${TMPDIR:-}" felix_audit_scan)" \
    || { printf 'felix audit: the read failed part way; nothing to report\n' >&2; return 1; }
  case "$t" in *$'\n'*) bad="${t#*$'\n'}"; t="${t%%$'\n'*}" ;; esac
  # Fifteen fields, none empty and none with a space, so plain word splitting
  # reads them; a tab-IFS read of a substitution is the trap the constitution
  # names, and this avoids needing one.
  # shellcheck disable=SC2086
  set -- $t
  [ $# -eq 15 ] || { printf 'felix audit: the read returned %s fields, not 15; nothing to report\n' "$#" >&2; return 1; }
  local nfiles="$1" sessions="$2" first="$3" last="$4" stops="$5" ssess="$6"
  local passed="$7" failed="$8" stale="$9" never="${10}" holds="${11}" hsess="${12}"
  local hid="${13}" aside="${14}" unread="${15}"

  printf '  transcripts  %s%s\n' "$dir" "$([ "$mode" -eq 2 ] && printf ' (one project: DIR/*.jsonl)')"
  local span=", from $first to $last${since:+ (--since $since)}"
  [ "$first" = "$last" ] && span=", all on $first${since:+ (--since $since)}"
  [ "$first" = "-" ] && span=""
  [ "$sessions" -eq 0 ] && span=" of the $nfiles transcripts had a record${since:+ on or after $since}"
  printf '  sessions     %s%s\n\n' "$sessions" "$span"

  printf '%s came after an edit, in %s. Where each one stood:\n\n' \
    "$(_felix_audit_n "$stops" stop)" "$(_felix_audit_n "$ssess" session)"
  printf '  passed  %5s  %3s%%  the last check after the last edit reported no error\n' \
    "$passed" "$(_felix_audit_pct "$passed" "$stops")"
  [ "$hid" -gt 0 ] && \
    printf '                      and %s of those could not have: piped, followed by another command, or backgrounded\n' "$hid"
  printf '  failed  %5s  %3s%%  the last check after the last edit failed, and the turn stopped anyway\n' \
    "$failed" "$(_felix_audit_pct "$failed" "$stops")"
  printf '  stale   %5s  %3s%%  a check ran earlier in the session, but none after the last edit\n' \
    "$stale" "$(_felix_audit_pct "$stale" "$stops")"
  printf '  never   %5s  %3s%%  no check had run in the session at all\n\n' \
    "$never" "$(_felix_audit_pct "$never" "$stops")"

  [ "$aside" -gt 0 ] && \
    printf 'Left out: %s after edits only to scratch files or Claude'"'"'s own (memory, plans, settings), which no gate covers.\n\n' \
      "$(_felix_audit_n "$aside" stop)"
  [ "$holds" -gt 0 ] && \
    printf 'Felix held %s, in %s, because no passing gate result was current for the tree. A held stop is still counted above: the turn tried to end there.\n\n' \
      "$(_felix_audit_n "$holds" stop)" "$(_felix_audit_n "$hsess" session)"
  [ "$unread" -gt 0 ] && \
    printf 'Not read: %s could not be opened (the first: %s).\n\n' "$(_felix_audit_n "$unread" transcript)" "$bad"

  if [ -n "$verify" ]; then
    printf 'A check is a Bash command matching --verify %s, outside quotes and here-documents.\n' "'$verify'"
  else
    printf 'A check is a Bash command running tests or a gate (npm test, pytest, cargo test, go test, make check, jest, vitest, felix gate and the like), outside quotes and here-documents; --verify ERE replaces that list.\n'
  fi
  printf 'A check piped into another command, followed by one, or run in the background hands its exit status to something else, so its result is never marked an error, whatever it printed.\n'
  printf 'Subagents are not seen: their edits and checks sit in files this does not read.\n\n'
  _felix_audit_next
  return 0
}
