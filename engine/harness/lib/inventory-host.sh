# felix inventory's host adapter: what only Claude Code's own session records
# can say about a directory. lib/inventory.sh holds everything git and GitHub
# can answer and asks this file its questions through the functions below,
# without knowing how they are answered; a second host is a second file
# defining the same names. Nothing here runs git.
#
# Where the records are. Claude Code files the sessions of a working directory
# D under $HOME/.claude/projects/E, E being D with every UTF-16 unit outside
# [A-Za-z0-9] replaced by '-': one '-' for a character of the Basic
# Multilingual Plane, two for one beyond it (_fi_host_enc does this bytewise
# under LC_ALL=C). An E longer than 200 is cut at 200 and followed by '-' and
# a hash of D this file does not compute: the one directory whose name starts
# so is taken, and two such are unknown. A session is a top-level *.jsonl
# there, and the newest session is the one of those modified last. Beside
# each, <session-id>/subagents/ holds its helpers' records (a workflow's under
# workflows/ there), which are not sessions and are never read; but a session
# waiting on a helper writes nothing of its own, so a file written there is
# that session's activity. The time a directory was last active is the
# newest of its sessions' files and every file under their subagents/, found
# by find -newer against the newest session's own file.
# A directory is looked up under both spellings of its path, as git lists it
# and as the kernel resolves it, since a session records the second
# (/private/tmp on a Mac) where git may hold the first.
#
# How a session ended is read from its last 256 KiB (tail -c), by awk: a
# transcript can be hundreds of megabytes, and its end is all this needs.
#   question  the final text (the last assistant record holding a text item)
#             asks, by _FI_HOST_ASK below, and no human text comes after it.
#             Two rules came before it: the text ends on a ?, which found
#             none of the questions real sessions end on, and a ? anywhere in
#             the last paragraph, which found 2 of 41 read by hand, since real
#             endings ask and then say what happens either way, or offer
#             without a ?.
#   blocked   the last assistant record's last item is a tool call, and no
#             later record carries a result for its id; the caller is told how
#             long ago, since a call that has waited seconds is merely running,
#             and when a file under the session's subagents/ was written last,
#             since a call to a helper waits as long as the helper works
# Human text is a user record whose content is a string or holds a text item,
# and is not a tool result, not a hook's own record (isMeta: Stop hook
# feedback, a message from another session, a skill's body), and not a system
# envelope: text that starts with < once any leading <system-reminder> block is
# set aside. Those blocks are set aside because the host puts one before the
# first message of every session it opens in a worktree, a chip's included;
# read without that, 72 of 73 real chips looked never started. A read holding
# no record of a known shape (empty, cut, or not JSON) answers unknown, not
# no. A question's note is its text's last 160 bytes, line breaks read as
# spaces, starting on a whole UTF-8 character.
#
# Chips. A tool call to mcp__ccd_session__spawn_task proposes one, its result
# names the task id, and a later mcp__ccd_session__dismiss_task with that id
# withdraws it; only the session that proposed a chip can, so a dismiss is
# looked for in the files that hold a proposal. A chip was started when some
# session file modified since it was proposed begins with a human message
# whose first 120 characters are the prompt's first 120. One grep finds the
# files holding a proposal (a second pattern quadruples its time on a week of
# transcripts), and of those only the lines holding "task" are read, as every
# proposal, result and dismissal does (on one repository's week, 22 s of CPU
# read whole, 18 s so); the others are read up to their first human message.
# A directory given with a trailing / stands for every directory under it, so
# a worktree since removed still counts.
#
# No JSON parser, for the reason lib/audit.sh gives: every pattern is a key, a
# colon and a quoted value, and inside a JSON string a double quote is always
# escaped, so a structural pattern cannot match text that merely quotes one.
# No here-document either: bash 3.2 backs one with a file in the system's
# temp directory. Whatever cannot be read is unknown, never absent.

FELIX_INV_HOST_NAME="Claude Code"

_fi_host_root() { [ -n "${HOME:-}" ] && [ -d "$HOME/.claude/projects" ] && printf '%s' "$HOME/.claude/projects"; }

# E for a directory, as Claude Code spells it.
_fi_host_enc() {
  local LC_ALL=C
  case "$1" in
    *[!\ -~]*) printf '%s' "$1" | LC_ALL=C awk 'BEGIN { RS = "\001" }
        { n = length($0); for (i = 1; i <= n; i++) { c = substr($0, i, 1)
            if (c ~ /[A-Za-z0-9]/) o = o c; else if (c < "\200") o = o "-"; else if (c >= "\360") o = o "--"; else if (c >= "\300") o = o "-" } }
        END { printf "%s", o }' ;;
    *) printf '%s' "${1//[^A-Za-z0-9]/-}" ;;
  esac
}
# The record directory of E under root: printed if there is one; status 2
# when E was cut and more than one directory could be it.
_fi_host_one() {
  local x m=""
  if [ "${#2}" -le 200 ]; then [ -d "$1/$2" ] && printf '%s\n' "$1/$2"; return 0; fi
  for x in "$1/${2:0:200}"-*; do [ -d "$x" ] || continue; [ -z "$m" ] || return 2; m="$x"; done
  [ -z "$m" ] || printf '%s\n' "$m"
}

# The record directories of one working directory that exist, one per line;
# a line ? when one cannot be told from another's.
_fi_host_dirs() {
  local e p
  e="$(_fi_host_enc "$2")"; _fi_host_one "$1" "$e" || printf '?\n'
  p="$(cd "$2" 2>/dev/null && pwd -P)" || return 0
  [ -n "$p" ] && [ "$p" != "$2" ] || return 0
  p="$(_fi_host_enc "$p")"; [ "$p" = "$e" ] || _fi_host_one "$1" "$p" || printf '?\n'
  return 0
}

# The record directories of each directory named, or, for one named with a
# trailing /, of every directory under it: children of P are filed under
# E(P) followed by '-', or under the first 200 of it when that is longer.
_fi_host_scope() {
  local root="$1" d e p
  shift
  for d in "$@"; do
    case "$d" in
      */) for p in "${d%/}" "$(cd "$d" 2>/dev/null && pwd -P)"; do
            [ -n "$p" ] || continue
            p="$(_fi_host_enc "$p")"; if [ "${#p}" -lt 200 ]; then p="$p-"; else p="${p:0:200}"; fi
            for e in "$root/$p"*; do [ -d "$e" ] && printf '%s\n' "$e"; done
          done ;;
      *) _fi_host_dirs "$root" "$d" | grep -v '^?$' ;;
    esac
  done
  return 0
}

# The awk both readers share: whose record a line is, the human text a user
# record starts with, and a JSON string value decoded far enough to compare.
# shellcheck disable=SC2016
_FI_HOST_AWK='
  BEGIN {
    Q = "\""; K_MSG = "\"message\":{"; K_SIDE = "\"isSidechain\":true"; K_META = "\"isMeta\":true"
    K_USER = "\"type\":\"user\""; K_ASST = "\"type\":\"assistant\""; K_TYPE = "\"type\":\""
    K_RES = "\"type\":\"tool_result\""; K_STR = "\"role\":\"user\",\"content\":\""
    K_TXT = "\"type\":\"text\",\"text\":\""; K_TU = "\"type\":\"tool_use\",\"id\":\""
    K_TID = "\"tool_use_id\":\""; ENV_O = "<system-reminder>"; ENV_C = "</system-reminder>"
  }
  # "u", "a", or "" for any other record, told as lib/audit.sh tells it: a user
  # type sits before the message, an assistant one after it, and any other type
  # before it is an attachment or progress record, which may nest a message.
  function kind(l,    im, p, v) {
    im = index(l, K_MSG); if (!im) return ""
    p = index(l, K_SIDE); if (p && p < im) return ""
    if ((p = index(l, K_USER)) && p < im) return "u"
    if ((p = index(l, K_ASST)) && p < im) return "a"
    if ((p = index(l, K_TYPE)) && p < im) return ""
    p = index(l, "\"role\":\""); v = p ? substr(l, p + 8, 10) : ""
    if (v == "assistant\"") return "a"
    return substr(v, 1, 5) == "user\"" ? "u" : ""
  }
  # The raw JSON text a user record s human message starts with, from its first
  # character after any <system-reminder> blocks; "" when it holds none.
  function human(l,    p, r, e) {
    if (index(l, K_META) || index(l, K_RES)) return ""
    if (p = index(l, K_STR)) p += length(K_STR)
    else if (p = index(l, K_TXT)) p += length(K_TXT)
    else return ""
    r = substr(l, p, 65536)
    while (1) {
      sub(/^( |\\n|\\t|\\r)+/, "", r)
      if (substr(r, 1, length(ENV_O)) != ENV_O) break
      if (!(e = index(r, ENV_C))) return ""
      r = substr(r, e + length(ENV_C))
    }
    e = substr(r, 1, 1)
    return (e == "" || e == Q || e == "<") ? "" : r
  }
  # A string value, raw, from its first character to the quote that ends it.
  function str(r) { return match(r, /^([^"\\]|\\.)*/) ? substr(r, 1, RLENGTH) : "" }
  function val(s, k,    p) { p = index(s, k); return p ? str(substr(s, p + length(k))) : "" }
  # Decoded far enough to compare two strings and to print one on a line; an
  # escaped backslash is held aside as \001 while the others are read.
  function dec(s,    i, o) {
    gsub(/\\\\/, "\001", s); gsub(/\\[nrt]/, " ", s); gsub(/\\"/, Q, s); gsub(/\\\//, "/", s); gsub(/\t/, " ", s)
    while (i = index(s, "\001")) { o = o substr(s, 1, i - 1) "\\"; s = substr(s, i + 1) }
    return o s
  }
  function key(r) { return substr(dec(substr(str(r), 1, 2048)), 1, 120) }
'

# Whether a final text, decoded with its line breaks kept, asks the person
# something: asks(t) is 1 or 0. Set aside first: curly quotes read as straight
# ones, fenced blocks, code spans, double-quoted spans and blockquote lines;
# paragraphs are runs of lines between lines of only blanks. It asks when a ?
# ends a line (only * _ ) " ' and blanks after it) in the last three
# paragraphs, or when an offer below appears anywhere in it, lowercased, as
# whole words, and none of no, not, nothing, never, none is in the 40 bytes
# before it, cut after the last . ! ? ; : or line break. Measured on 227
# session endings read by hand on 2026-09-24 (rule R4 of that labelling): 36
# of 45 asks found and nothing else, over the 201 sessions sampled without
# regard to any rule; 51 hits over all 227, 50 of them asks. \047 is the
# apostrophe.
# shellcheck disable=SC2016
_FI_HOST_ASK='
  BEGIN {
    AQ_B = "(^|[^a-z0-9_])"; AQ_E = "([^a-z0-9_]|$)"; AQ_L = "[?][*_)\"\047]*[ \t\r]*(\n|$)"
    AQ_N = "(^|[^a-z])(no|not|nothing|never|none)([^a-z]|$)"
    AQ_P[1] = "your (call|decision|answer|options|side|sign-off|merge|go-ahead)"
    AQ_P[2] = "([a-z]+\047s|is|are|still|all|both) yours|yours (to|rather)"
    AQ_P[3] = "(wait(s|ing)?|blocked) (on|for) your?"
    AQ_P[4] = "needs? your?"
    AQ_P[5] = "say (so|the word|yes|if|go)"
    AQ_P[6] = "and i(\047ll| will)"
    AQ_P[7] = "(want|like) me to|(should|shall) i"
    AQ_P[8] = "if you(\047d)? rather|if you (want|prefer)[^.?!]*, i(\047ll| can| will| could)|i(\047ll| can| could) [^.?!]* if you want"
    AQ_P[9] = "(for|on) you:"
    AQ_P[10] = "(for|to) you to (decide|choose|approve|merge|review|start|run|confirm|pick)"
    AQ_NP = 10
  }
  # An offer matched in t and not negated within its clause.
  function offer(t, re,    r, s0, off, rest, w) {
    r = AQ_B "(" re ")" AQ_E; off = 0; rest = t
    while (match(rest, r)) {
      s0 = off + RSTART; w = substr(t, s0 > 40 ? s0 - 39 : 1, s0 > 40 ? 40 : s0)
      while (match(w, /[.!?;:\n]/)) w = substr(w, RSTART + 1)
      if (w !~ AQ_N) return 1
      off = s0; rest = substr(t, off + 1)
    }
    return 0
  }
  function asks(t,    L, n, i, s, fence, cur, np, par, all, l3, k) {
    n = split(t, L, "\n"); np = 0; fence = 0; cur = ""
    for (i = 1; i <= n; i++) {
      s = L[i]
      if (s ~ /^[ \t]*(```|~~~)/) { fence = !fence; s = "" }
      else if (fence) s = ""
      else {
        gsub("\342\200\234|\342\200\235", "\"", s); gsub("\342\200\231", "\047", s)
        gsub(/`[^`]*`/, "", s); gsub(/"[^"]*"/, "", s)
        if (s ~ /^[ \t]*>/) s = ""
      }
      if (s ~ /^[ \t\r]*$/) { if (cur != "") par[++np] = cur; cur = "" }
      else cur = cur (cur != "" ? "\n" : "") s
    }
    if (cur != "") par[++np] = cur
    all = ""; l3 = ""
    for (i = 1; i <= np; i++) { all = all "\n" par[i]; if (i > np - 3) l3 = l3 "\n" par[i] }
    if (l3 ~ AQ_L) return 1
    all = tolower(all)
    for (k = 1; k <= AQ_NP; k++) if (offer(all, AQ_P[k])) return 1
    return 0
  }
'

# The newest file under the directories after the first argument written
# after it, or nothing: candidates by find -newer, sorted by ls -t, and asked
# again until none is newer, since a long list reaches ls in batches.
_fi_host_newer() {
  local x="$1" c="" i=0
  shift
  while [ "$i" -lt 8 ]; do
    x="$(find "$@" -type f -newer "$x" -exec ls -dt {} + 2>/dev/null | head -n 1)"
    [ -n "$x" ] || break
    c="$x"; i=$((i + 1))
  done
  printf '%s' "$c"
}
# A file's mtime as an epoch, or nothing.
_fi_host_mt() { local e; e="$(date -r "$1" +%s 2>/dev/null)"; case "$e" in ''|*[!0-9]*) ;; *) printf '%s' "$e" ;; esac; }

# How the newest session of one working directory stands.
#   felix_inv_host_dir DIR NOW LIVE_MIN BLOCKED_MIN
# prints one tab-separated line: owner mtime live question blocked note, where
# owner is the newest session's id (- when none ever ran there), mtime when
# the directory was last active, each state yes, no or unknown, and note what
# the question or the waiting call was. Unknown throughout when the records
# cannot be read.
felix_inv_host_dir() {
  local root d f newest="" amb=0 m mt sa age size cut=0 out q b note live=no t=$'\t' nl=$'\n' nn; local -a subs=()
  root="$(_fi_host_root)" || { printf 'unknown\t-\tunknown\tunknown\tunknown\tno Claude Code session records under $HOME/.claude/projects\n'; return 0; }
  while IFS= read -r d; do
    [ "$d" != '?' ] || { amb=1; continue; }
    for f in "$d"/*.jsonl; do
      [ -f "$f" ] || continue
      [ ! -d "${f%.jsonl}/subagents" ] || subs[${#subs[@]}]="${f%.jsonl}/subagents"
      if [ -z "$newest" ] || [ "$f" -nt "$newest" ]; then newest="$f"; fi
    done
  done < <(_fi_host_dirs "$root" "$1")
  [ "$amb" = 0 ] || { printf 'unknown\t-\tunknown\tunknown\tunknown\tits session records cannot be told from another directory'"'"'s: its name is over 200 characters\n'; return 0; }
  [ -n "$newest" ] || { printf -- '-\t-\tno\tno\tno\t-\n'; return 0; }
  nn="${newest//$t/ }"; nn="${nn//$nl/ }"
  mt="$(_fi_host_mt "$newest")"
  [ -n "$mt" ] || { printf 'unknown\t-\tunknown\tunknown\tunknown\tcould not read the time of %s\n' "$nn"; return 0; }
  m="$mt"
  if [ "${#subs[@]}" -gt 0 ]; then
    sa="$(_fi_host_newer "$newest" "${subs[@]}")"; [ -z "$sa" ] || sa="$(_fi_host_mt "$sa")"
    [ -z "$sa" ] || [ "$sa" -le "$m" ] || m="$sa"
  fi
  age=$(($2 - m)); [ "$age" -le $(($3 * 60)) ] && live=yes
  size="$(wc -c 2>/dev/null < "$newest" | tr -d ' ')"
  [ "${size:-0}" -gt 262144 ] && cut=1
  out="$(tail -c 262144 "$newest" 2>/dev/null | awk -v cut="$cut" "$_FI_HOST_AWK$_FI_HOST_ASK"'
    NR == 1 && cut { next }
    { k = kind($0); if (k != "") rec++ }
    k == "a" {
      la = NR; pend = ""; pname = ""
      n = split($0, P, K_TXT); if (n > 1) { ft = str(P[n]); fa = NR }
      n = split($0, P, K_TU)
      if (n > 1 && !index(P[n], "},{\"type\":\"text\"") && !index(P[n], "},{\"type\":\"thinking\"")) {
        pend = substr(P[n], 1, index(P[n], Q) - 1); pname = val(P[n], "\"name\":\"")
      }
      next
    }
    pend != "" && index($0, K_TID pend Q) { pend = "" }
    k == "u" && human($0) != "" { lh = NR }
    END {
      if (!rec) { printf "unknown\tunknown\tthe newest session holds no record this can read\n"; exit }
      if (fa) {
        # Decoded with its line breaks kept, and asked whether it asks.
        t = ft; gsub(/\\\\/, "\001", t); gsub(/\\n/, "\n", t); t = dec(t); sub(/[ \n]+$/, "", t)
        q = (lh < fa && asks(t)) ? "yes" : "no"
        if (q == "yes") { gsub(/\n/, " ", t); s = substr(t, length(t) > 160 ? length(t) - 159 : 1)
          while (s != "" && substr(s, 1, 1) >= "\200" && substr(s, 1, 1) < "\300") s = substr(s, 2)
          note = "ended on: " s }
      } else q = (lh || !cut) ? "no" : "unknown"
      if (la) b = pend != "" ? "pending" : "no"; else b = cut ? "unknown" : "no"
      if (b == "pending") note = (note != "" ? note "; " : "") "waiting on " (pname != "" ? pname : "a tool call")
      printf "%s\t%s\t%s\n", q, b, (note == "" ? "-" : note)
    }')" || out=""
  # Split by expansion, not a tab-IFS read (the constitution says why).
  q="${out%%"$t"*}"; out="${out#*"$t"}"; b="${out%%"$t"*}"; note="${out#*"$t"}"
  case "$q" in yes|no|unknown) ;; *) q=unknown; b=unknown; note="could not read $nn" ;; esac
  # Blocked once the call has waited past BLOCKED_MIN and nothing under this
  # session's own subagents/ was written within it.
  if [ "$b" = pending ]; then
    sa=""; [ ! -d "${newest%.jsonl}/subagents" ] || sa="$(_fi_host_newer "$newest" "${newest%.jsonl}/subagents")"
    [ -z "$sa" ] || sa="$(_fi_host_mt "$sa")"
    if [ $(($2 - mt)) -gt $(($4 * 60)) ] && { [ -z "$sa" ] || [ $(($2 - sa)) -gt $(($4 * 60)) ]; }; then b=yes; note="$note for $((($2 - mt) / 60)) min"
    else b=no; note="${note%waiting on *}"; note="${note%; }"; note="${note:--}"; fi
  fi
  f="${newest##*/}"; f="${f%.jsonl}"; f="${f//$t/ }"; f="${f//$nl/ }"; note="${note//$t/ }"; note="${note//$nl/ }"
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$f" "$m" "$live" "$q" "$b" "$note"
}

# Chips proposed in the sessions of these directories modified within DAYS
# days that no session was started from and none withdrew.
#   felix_inv_host_chips NOW DAYS DIR...
# prints one line per chip: id session epoch title. Status 1, and nothing
# printed, when the records cannot be read.
felix_inv_host_chips() {
  local root now="$1" days="$2" d e f list chips mins
  root="$(_fi_host_root)" || return 1
  shift 2
  list="$(_fi_host_scope "$root" "$@" | sort -u | while IFS= read -r e; do
            find "$e" -maxdepth 1 -type f -name '*.jsonl' -mmin -$((days * 1440)) 2>/dev/null
          done | tr '\n' '\000' | xargs -0 grep -l -F -e '"name":"mcp__ccd_session__spawn_task","input":{' -- 2>/dev/null)"
  [ -n "$list" ] || return 0
  # Each file's lines holding task, after a line naming the file (\002
  # cannot start a JSON line).
  chips="$(printf '%s\n' "$list" | while IFS= read -r f; do printf '\002%s\n' "$f"; grep -F -e task -- "$f" 2>/dev/null; done | awk "$_FI_HOST_AWK"'
    function ep(t,    y, mo, e) {
      if (t !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/) return ""
      y = substr(t, 1, 4) + 0; mo = substr(t, 6, 2) + 0; if (mo <= 2) { y--; mo += 12 }
      e = 365 * y + int(y / 4) - int(y / 100) + int(y / 400) + int((153 * (mo - 3) + 2) / 5) + substr(t, 9, 2) - 719469
      return e * 86400 + substr(t, 12, 2) * 3600 + substr(t, 15, 2) * 60 + substr(t, 18, 2)
    }
    BEGIN {
      SP = "\"name\":\"mcp__ccd_session__spawn_task\",\"input\":{"; KP = "\"prompt\":\""
      DI = "\"name\":\"mcp__ccd_session__dismiss_task\",\"input\":{"
    }
    substr($0, 1, 1) == "\002" { s = $0; sub(/.*\//, "", s); sub(/[.]jsonl$/, "", s); gsub(/\t/, " ", s); next }
    { l = $0
      if (p = index(l, SP)) {
        if (kind(l) != "a") next
        n = split(substr(l, 1, p - 1), P, "\"id\":\""); id = substr(P[n], 1, index(P[n], Q) - 1)
        r = substr(l, p + length(SP))
        if (id == "" || (id in CS) || !(q = index(r, KP))) next
        CS[id] = s; CT[id] = dec(val(r, "\"title\":\"")); CK[id] = key(substr(r, q + length(KP)))
        t = match(l, /"uuid":"[^"]*","timestamp":"[^"]*"/) ? substr(l, RSTART, RLENGTH) : ""
        sub(/.*"timestamp":"/, "", t); CE[id] = ep(t)
      } else if (p = index(l, DI)) DIS[val(substr(l, p), "\"task_id\":\"")] = 1
      else if ((p = index(l, K_TID)) && (q = index(l, "task_id: task_"))) {
        id = substr(l, p + length(K_TID)); id = substr(id, 1, index(id, Q) - 1)
        t = substr(l, q + 9); match(t, /^[A-Za-z0-9_]+/); TASK[id] = substr(t, 1, RLENGTH)
      }
    }
    END {
      for (id in CS) {
        t = (id in TASK) ? TASK[id] : id
        if (!(t in DIS)) printf "%s\t%s\t%s\t%s\t%s\n", t, CS[id], (CE[id] == "" ? "-" : CE[id]), CT[id], CK[id]
      }
    }')"
  [ -n "$chips" ] || return 0
  # Every session file under the records modified since the oldest chip, read
  # up to its first human message.
  mins="$(printf '%s\n' "$chips" | awk -F'\t' -v now="$now" '$3 != "-" && (o == "" || $3 < o) { o = $3 } END { print (o == "" ? 0 : int((now - o) / 60) + 2) }')"
  [ "${mins:-0}" -gt 0 ] || mins=$((days * 1440))
  { printf '%s\n' "$chips"; printf '\001\n'
    find "$root" -mindepth 2 -maxdepth 2 -type f -name '*.jsonl' -mmin -"$mins" 2>/dev/null
  } | awk -F'\t' "$_FI_HOST_AWK"'
    $0 == "\001" { files = 1; next }
    !files { C[$5] = C[$5] $1 "\t" $2 "\t" $3 "\t" $4 "\n"; next }
    {
      f = $0
      while ((getline l < f) > 0) if (kind(l) == "u" && (h = human(l)) != "") { S[key(h)] = 1; break }
      close(f)
    }
    END { for (k in C) if (!(k in S)) printf "%s", C[k] }'
}
