# felix cost: how many tokens Claude Code spent, read from the transcripts it
# already keeps. A proxy for plan usage, in input-equivalent tokens, never the
# plan's own number: an input token is 1, a cache write 1.25 (five minutes) or 2
# (an hour), a cache read 0.1 and an output token 5, the API's price ratios.
#
# Why it exists. On 2026-10-08 forty-one fix sessions spent 47% of a week's
# allowance in seven hours, and nothing in Felix could say so while it was
# happening (audits/2026-10-09-token-burn in the memory root). This is the
# reading a governor needs before it can limit anything.
#
# Read-only by construction, like felix audit: the CLI dispatches it before a
# home is resolved, and it opens no file for writing and makes no temporary
# file (no here-document or here-string either, which bash backs with one).
#
# Records. The root is $CLAUDE_CONFIG_DIR/projects when that is set and
# non-empty, else $HOME/.claude/projects (lib/inventory-host.sh reads the same
# root). Under it a session is <E>/*.jsonl, E a working directory's record
# directory, and its helper agents are every *.jsonl under <E>/<sid>/subagents/:
# an Agent call's directly, a workflow's two levels down in workflows/<run>/
# (measured 2026-10-11: 222 of the week's 626 transcripts, and 152M of its
# 570M, sat there). Nothing else is read. A file last written before the window opened cannot hold a
# record from inside it, so find's -mmin, with two minutes to spare, keeps it
# out: a week is about a gigabyte of transcripts and a summer ten.
#
# One response, once. Claude Code writes a line per content block of a
# response, each carrying the usage so far, and it grows, so within a file the
# last line of a message id wins. A forked session copies its parent's lines
# into a new file, so an id is counted once across every file read, the last
# read winning, files in byte order.
#
# Which line is a response. A whole line (it opens with { and closes with }) that
# names "type":"assistant", whose top-level message has role assistant, an id
# and a usage object, and whose model is not <synthetic>. A record that nests a
# message (attachment, progress) names its own type before it, as lib/audit.sh
# says, and is not one; a user record has role user, even when a tool result in
# it carries a usage of its own. No JSON parser, on purpose (lib/audit.sh says
# why): inside a JSON string every quote is escaped, so a "key": pattern only
# matches structure.
#
# The usage object. Its top-level counts are read and usage.iterations never
# is: it repeats them, and reading it would count a response twice. So every
# container nested in usage is folded away, innermost first, and the counts
# are read from what is left, cache_creation's two from the one container kept
# by name. Key order is not relied on. No string in a usage object holds a
# bracket (its strings are tiers, regions and speeds); one that did would fold
# wrong and read as no usage, never as a larger one.
#
# The window. A plan week opens Thursday 13:00:00Z (the Unix epoch was a
# Thursday, so a week start is 13 h plus a whole number of weeks) and runs
# seven days; --since opens at an instant and has no end. A record counts when
# start <= its "timestamp" < end, compared as ISO 8601 strings, the timestamp
# being the one after its "uuid" (as lib/inventory-host.sh reads it).
# FELIX_COST_NOW sets the instant taken as now. Dates are integer arithmetic,
# so BSD and GNU date differ in nothing used here.
#
# Unread is unknown, never zero. No root, or a root without one transcript of
# any age, is unknown. A file or directory that cannot be read is counted, and
# the total is then a floor; a floor of nothing is unknown. A response with no
# time cannot be placed in the window, so it makes the total a floor too.
#
# Forks: date once, then find and sort once, and one grep per 256 files of a
# record directory, so never one per line or per file. One awk does the rest.

FELIX_COST_CAP_M_DEFAULT=905

felix_cost_usage() {
  printf 'usage: felix cost [--week | --since YYYY-MM-DD[THH:MM]] [--by worktree|day|model] [--top N] [--tsv]\n'
}
_fc_refuse() { printf 'felix cost: %s\n' "$1" >&2; felix_cost_usage >&2; return 2; }

# _FC_E: seconds since the epoch of Y M D h m s (UTC), from the civil date by
# days-from-civil. Fields may carry leading zeros; they are read base 10.
_fc_epoch() {
  local y=$((10#$1)) m=$((10#$2)) d=$((10#$3)) era yoe doy doe
  [ "$m" -le 2 ] && y=$((y - 1))
  era=$((y / 400)); yoe=$((y - era * 400))
  if [ "$m" -gt 2 ]; then doy=$(((153 * (m - 3) + 2) / 5 + d - 1)); else doy=$(((153 * (m + 9) + 2) / 5 + d - 1)); fi
  doe=$((yoe * 365 + yoe / 4 - yoe / 100 + doy))
  _FC_E=$(((era * 146097 + doe - 719468) * 86400 + 10#$4 * 3600 + 10#$5 * 60 + 10#$6))
}
# _FC_ISO: YYYY-MM-DDTHH:MM:SS of an epoch second at or after 1970.
_fc_iso() {
  local s=$1 z r era doe yoe y doy mp d m
  z=$((s / 86400 + 719468)); r=$((s % 86400))
  era=$((z / 146097)); doe=$((z - era * 146097))
  yoe=$(((doe - doe / 1460 + doe / 36524 - doe / 146096) / 365))
  y=$((yoe + era * 400)); doy=$((doe - (365 * yoe + yoe / 4 - yoe / 100)))
  mp=$(((5 * doy + 2) / 153)); d=$((doy - (153 * mp + 2) / 5 + 1))
  if [ "$mp" -lt 10 ]; then m=$((mp + 3)); else m=$((mp - 9)); fi
  [ "$m" -le 2 ] && y=$((y + 1))
  printf -v _FC_ISO '%04d-%02d-%02dT%02d:%02d:%02d' "$y" "$m" "$d" $((r / 3600)) $((r % 3600 / 60)) $((r % 60))
}
# _FC_E for Y M D h m s when that is a real instant, status 1 when not: the
# civil date it names must come back from its own epoch.
_fc_real() {
  [ "$((10#$4))" -le 23 ] && [ "$((10#$5))" -le 59 ] && [ "$((10#$6))" -le 59 ] || return 1
  [ "$((10#$1))" -ge 1970 ] && [ "$((10#$2))" -ge 1 ] && [ "$((10#$2))" -le 12 ] && [ "$((10#$3))" -ge 1 ] || return 1
  _fc_epoch "$@"; _fc_iso "$_FC_E"
  [ "${_FC_ISO:0:10}" = "$1-$2-$3" ]
}

# felix cost [--week | --since D] [--by F] [--top N] [--tsv]
felix_cost() {
  local -x LC_ALL=C
  local by="" top="" tsv=0 since="" cap root where now real start end=""
  local re_cap='^([0-9]+(\.[0-9]*)?|\.[0-9]+)$'
  local re_since='^([0-9]{4})-([0-9]{2})-([0-9]{2})(T([0-9]{2}):([0-9]{2}))?$'
  local re_now='^([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2})(:([0-9]{2}))?Z$'
  while [ $# -gt 0 ]; do
    case "$1" in
      --week) since=""; shift ;;
      --since) [ $# -ge 2 ] || { _fc_refuse "--since needs a date, YYYY-MM-DD or YYYY-MM-DDTHH:MM"; return; }
               since="$2"; shift 2 ;;
      --by) case "${2:-}" in worktree|day|model) by="$2"; shift 2 ;; *) _fc_refuse "--by takes worktree, day or model"; return ;; esac ;;
      --top) [[ "${2:-}" =~ ^[0-9]+$ ]] && [ "$((10#$2))" -gt 0 ] || { _fc_refuse "--top takes a positive whole number"; return; }
             top=$((10#$2)); shift 2 ;;
      --tsv) tsv=1; shift ;;
      -h|--help) felix_cost_usage; return 0 ;;
      *) _fc_refuse "unknown argument: $1"; return ;;
    esac
  done
  cap="${FELIX_COST_CAP_M:-$FELIX_COST_CAP_M_DEFAULT}"
  [[ "$cap" =~ $re_cap ]] && [[ "$cap" =~ [1-9] ]] \
    || { _fc_refuse "FELIX_COST_CAP_M is not a positive number: $cap"; return; }

  real="$(date -u +%s)"
  case "$real" in ''|*[!0-9]*) printf 'felix cost: the clock could not be read\n' >&2; return 1 ;; esac
  if [ -n "${FELIX_COST_NOW:-}" ]; then
    [[ "$FELIX_COST_NOW" =~ $re_now ]] \
      && _fc_real "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}" "${BASH_REMATCH[5]}" "${BASH_REMATCH[7]:-00}" \
      || { _fc_refuse "FELIX_COST_NOW is not YYYY-MM-DDTHH:MM[:SS]Z: $FELIX_COST_NOW"; return; }
    now=$_FC_E
  else
    now=$real
  fi
  if [ -n "$since" ]; then
    [[ "$since" =~ $re_since ]] \
      && _fc_real "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" "${BASH_REMATCH[5]:-00}" "${BASH_REMATCH[6]:-00}" 00 \
      || { _fc_refuse "--since is not a real YYYY-MM-DD or YYYY-MM-DDTHH:MM: $since"; return; }
    start=$_FC_E
  else
    start=$((((now - 46800) / 604800) * 604800 + 46800))
    end=$((start + 604800))
  fi

  if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then root="$CLAUDE_CONFIG_DIR/projects"; where='$CLAUDE_CONFIG_DIR/projects'
  elif [ -n "${HOME:-}" ]; then root="$HOME/.claude/projects"; where='$HOME/.claude/projects'
  else root=""; where='$HOME/.claude/projects'; fi

  local s_iso e_iso="" n_iso any=0 f mmin
  _fc_iso "$start"; s_iso="$_FC_ISO"
  [ -z "$end" ] || { _fc_iso "$end"; e_iso="$_FC_ISO"; }
  _fc_iso "$now"; n_iso="$_FC_ISO"
  if [ -n "$root" ] && [ -d "$root" ]; then
    for f in "$root"/*/*.jsonl; do [ -f "$f" ] && { any=1; break; }; done
    [ "$any" = 1 ] || for f in "$root"/*/*/subagents/*.jsonl "$root"/*/*/subagents/*/*/*.jsonl; do [ -f "$f" ] && { any=1; break; }; done
  fi
  mmin=$(((real - start) / 60 + 2)); [ "$mmin" -ge 1 ] || mmin=1

  { if [ "$any" = 1 ]; then _fc_files "$root" "$mmin"; fi; } \
    | awk -v any="$any" -v start="$s_iso" -v end="$e_iso" -v asof="${n_iso:0:16}Z" \
          -v cap="$cap" -v by="$by" -v top="$top" -v tsv="$tsv" -v where="$where" "$_FC_AWK"
}

# The transcripts of the window under ROOT, grouped by record directory, for
# the awk below: a line \001E opens a directory's lines, \002 is a grep that
# could not read a file, and the last line, \003 read unread, counts the files.
_fc_files() {
  local root="$1" p rel r2 e cur="" nread=0 unread=0 rc
  local -a fs=()
  _fc_flush() {
    local i=0
    while [ "$i" -lt "${#fs[@]}" ]; do
      printf '\001%s\n' "$cur"
      GREP_OPTIONS='' grep -a -h -s -F -e '"usage":{' -- "${fs[@]:$i:256}"; rc=$?
      [ "$rc" -le 1 ] || printf '\002\n'
      i=$((i + 256))
    done
    fs=()
  }
  while IFS= read -r p; do
    case "$p" in "$root"/*) rel="${p#"$root"/}" ;; *) unread=$((unread + 1)); continue ;; esac
    e="${rel%%/*}"; r2="${rel#*/}"
    case "$r2" in
      */*) r2="${r2#*/}"; case "$r2" in subagents/*.jsonl) ;; *) continue ;; esac ;;
    esac
    [ -r "$p" ] || { unread=$((unread + 1)); continue; }
    [ "$e" = "$cur" ] || { _fc_flush; cur="$e"; }
    fs[${#fs[@]}]="$p"; nread=$((nread + 1))
  done < <(find "$root" -mindepth 2 -name '*.jsonl' -type f -mmin "-$2" -print 2>&1 | sort)
  _fc_flush
  printf '\003\t%d\t%d\n' "$nread" "$unread"
}

# shellcheck disable=SC2016
_FC_AWK='
  # The number after KEY in S, 0 when S has none.
  function num(s, key,    p, v) {
    if (!(p = index(s, key))) return 0
    v = substr(s, p + length(key), 24)
    return match(v, /^[0-9]+/) ? substr(v, 1, RLENGTH) + 0 : 0
  }
  # A response s weight in hundredths of an input token, from S, a usage
  # object from its "{" on; -1 when it does not close inside S. Nested
  # containers fold into \001k\002, innermost first, kept in F[k], until the
  # usage object itself is folded.
  function weight(s,    n, top, k, cc, c5, c1) {
    n = 0
    while (substr(s, 1, 1) != "\001") {
      if (!match(s, /[{[][^][{}]*[]}]/)) return -1
      F[++n] = substr(s, RSTART, RLENGTH)
      s = substr(s, 1, RSTART - 1) "\001" n "\002" substr(s, RSTART + RLENGTH)
    }
    top = F[n]
    if ((k = index(top, "\"cache_creation\":\001"))) {
      k = substr(top, k + 18); cc = F[substr(k, 1, index(k, "\002") - 1)]
      c5 = num(cc, "\"ephemeral_5m_input_tokens\":"); c1 = num(cc, "\"ephemeral_1h_input_tokens\":")
    } else { c5 = num(top, "\"cache_creation_input_tokens\":"); c1 = 0 }
    return 100 * num(top, "\"input_tokens\":") + 125 * c5 + 200 * c1 \
         + 10 * num(top, "\"cache_read_input_tokens\":") + 500 * num(top, "\"output_tokens\":")
  }
  # The string value after KEY in S, "" when none.
  function str(s, key,    p, v) {
    if (!(p = index(s, key))) return ""
    v = substr(s, p + length(key), 256)
    return substr(v, 1, index(v, "\"") - 1)
  }
  function ts(s) {
    if (!match(s, /"uuid":"[^"]*","timestamp":"[^"]*"/)) return ""
    s = substr(s, RSTART, RLENGTH); sub(/.*"timestamp":"/, "", s); sub(/"$/, "", s)
    return s ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T/ ? s : ""
  }
  BEGIN { Q = "\""; capt = cap * 1000000 }
  substr($0, 1, 1) == "\001" { E = substr($0, 2); next }
  substr($0, 1, 1) == "\002" { unread++; next }
  substr($0, 1, 1) == "\003" { split($0, c, "\t"); nread = c[2]; unread += c[3]; next }
  {
    l = $0
    if (substr(l, 1, 1) != "{" || substr(l, length(l), 1) != "}") next
    if (!index(l, "\"type\":\"assistant\"")) next
    if (!(im = index(l, "\"message\":{"))) next
    p = index(l, "\"type\":\""); if (p && p < im && substr(l, p, 18) != "\"type\":\"assistant\"") next
    r = substr(l, im + 11)
    if (substr(r, index(r, "\"role\":\"") + 8, 10) != "assistant\"" || !index(r, "\"role\":\"")) next
    if ((id = str(r, "\"id\":\"")) == "") next
    mo = str(r, "\"model\":\""); if (mo == "<synthetic>") next; if (mo == "") mo = "?"
    if (!(u = index(r, "\"usage\":{"))) next
    w = weight(substr(r, u + 8, 2048)); if (w < 0) w = weight(substr(r, u + 8))
    if (w < 0) next
    t = ts(substr(l, 1, im)); if (t == "") t = ts(substr(r, u, 16384)); if (t == "") t = ts(substr(r, u))
    W[id] = w; T[id] = t; WE[id] = E; WM[id] = mo
  }
  # Keys of A (n of them, in K) ordered: by value largest first then key, or
  # by key alone when bykey. An insertion sort: there are tens of keys, not
  # thousands.
  function order(A, K, n, bykey,    i, j, x) {
    for (i = 2; i <= n; i++) {
      x = K[i]
      for (j = i - 1; j >= 1; j--) {
        if (bykey ? (K[j] <= x) : (A[K[j]] > A[x] || (A[K[j]] == A[x] && K[j] <= x))) break
        K[j + 1] = K[j]
      }
      K[j + 1] = x
    }
  }
  function pct(h) { return sprintf("%.1f", h / capt) }
  function mil(h) { return sprintf("%.1fM", h / 100000000) }
  function facet(name, A, C,    K, n, k, i, lim, head) {
    n = 0; for (k in A) K[++n] = k
    order(A, K, n, name == "day")
    lim = (name == "day") ? n : (top != "" ? top + 0 : (tsv ? n : 10))
    if (tsv) { for (i = 1; i <= n && i <= lim; i++) printf "%s\t%s\t%.2f\t%s\t%d\n", name, K[i], A[K[i]] / 100, pct(A[K[i]]), C[K[i]]; return }
    head = (name == "day") ? "days" : (name == "worktree" ? "worktrees" : "models")
    if (!n) { printf "%s: none in the window\n", head; return }
    if (name == "day") printf "days (UTC): millions, percent of the cap\n"
    else printf "%s, top %d of %d: percent of the cap, millions, %s\n", head, (lim < n ? lim : n), n, (name == "worktree" ? "record directory" : "model")
    for (i = 1; i <= n && i <= lim; i++)
      if (name == "day") printf "  %s  %8s  %5s%%\n", K[i], mil(A[K[i]]), pct(A[K[i]])
      else printf "  %5s%%  %8s  %s\n", pct(A[K[i]]), mil(A[K[i]]), K[i]
  }
  END {
    for (id in W) {
      if (T[id] == "") { untimed++; continue }
      if (T[id] < start || (end != "" && T[id] >= end)) continue
      h = W[id]; tot += h; calls++
      WT[WE[id]] += h; WC[WE[id]]++
      d = substr(T[id], 1, 10); DT[d] += h; DC[d]++
      MT[WM[id]] += h; MC[WM[id]]++
    }
    cov = "measured"; why = ""
    if (!any) { cov = "unknown"; why = "no session records under " where }
    else if (unread || untimed) cov = (tot > 0) ? "floor" : "unknown"
    if (cov == "unknown" && why == "") why = (unread ? unread " could not be read" : "") (unread && untimed ? ", and " : "") (untimed ? untimed " responses had no time" : "") ", and nothing readable was in the window"
    s16 = substr(start, 1, 16) "Z"; e16 = (end == "") ? "now" : substr(end, 1, 16) "Z"
    if (tsv) {
      printf "cover\twindow_start\t%s\ncover\twindow_end\t%s\ncover\tsource\t%s\n", s16, e16, where
      printf "cover\tcap_tokens\t%.0f\ncover\tfiles_read\t%d\ncover\tfiles_unread\t%d\n", capt, nread, unread
      printf "cover\tcoverage\t%s\ncover\tas_of\t%s\n", cov, asof
      if (cov == "unknown") { printf "total\tall\tunknown\tunknown\tunknown\n"; exit }
      printf "total\tall\t%.2f\t%s\t%d\n", tot / 100, pct(tot), calls
      if (by == "" || by == "worktree") facet("worktree", WT, WC)
      if (by == "" || by == "day") facet("day", DT, DC)
      if (by == "" || by == "model") facet("model", MT, MC)
      exit
    }
    printf "felix cost: read-only. A proxy for plan usage in input-equivalent tokens, not the plan%ss own number.\n", "\047"
    printf "window   %s to %s\n", s16, e16
    if (cov == "unknown") {
      printf "total    unknown: %s\ncalls    unknown\n", why
      if (any) printf "files    %d read, %d could not be read under %s\n", nread, unread, where
      exit
    }
    printf "total    %s%s  %s%% of a %gM week\n", (cov == "floor" ? "at least " : ""), mil(tot), pct(tot), cap
    printf "calls    %d\n", calls
    if (unread) printf "files    %d read, %d could not be read under %s: the total is a floor\n", nread, unread, where
    else printf "files    %d read under %s\n", nread, where
    if (untimed) printf "untimed  %d responses had no time and are not counted: the total is a floor\n", untimed
    if (by == "" || by == "worktree") facet("worktree", WT, WC)
    if (by == "" || by == "day") facet("day", DT, DC)
    if (by == "model") facet("model", MT, MC)
  }
'
