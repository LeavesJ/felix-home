printf '\na grant is a person'"'"'s word: a session cannot give itself a grant or run the commission (audit b17, A1-A37, blind)\n'
# Written blind on 2026-10-24 from docs/2026-10-24-audit-fixes/b17-commission-grant-cannot-be-self-
# given-or.md alone (section 2's terms and B1-B18, section 4's A1-A37). No engine code was read: felix,
# its hooks and its libs are run as black boxes, from a copy of the harness in fixture A. Every name is
# emitted on every run, whatever the engine answered.
#
# Readings, where the contract leaves room, mine:
# - fixture A is built once and carried through A2-A37 in the items' order. A21 moves M/p aside and puts
#   it back, so the says.log A37 reads is the one every run here wrote to.
# - "a run appended rows" is what says.log gained across that run. A row is compared whole, as B1, B3
#   and B4 describe it (five fields, kind consent, the session, the cause, and the text by its start),
#   where an item names fewer of its fields.
# - tidy is revoked from no terminal before A18 and A21, since B5 records nothing for a tidy already
#   allowed; B/claude.log is removed before A26, so A27 reads that run's calls alone.
# - a terminal is made with script(1) as the terms say. Where neither form gives one, A17 and A18 are
#   skipped naming script, and so is A19, which reads the page after A17's grant.
# - A24 and A25 are one assertion each; a failure lists every case that answered otherwise.
# - A37 counts the rows whose cause (field 4) is felix autonomy or felix commission, the two causes the
#   contract gives consent rows: session start (A33) and felix commission's own work may write rows of
#   other kinds to the same file, and the contract says nothing of those.

# ---- helpers: a run under a 60 s watchdog, and the readings of section 2
_b7g_kt() { local c; kill -STOP "$1" 2>/dev/null
            for c in $(pgrep -P "$1" 2>/dev/null); do _b7g_kt "$c"; done; kill -KILL "$1" 2>/dev/null; }
_b7g_wd() {   # SECONDS DIR IN OUT ERR CMD...: CMD in DIR, its tree killed by pid if it outlives SECONDS; sets B7RC, B7END
  local s="$1" d="$2" in="$3" o="$4" e="$5" pid i=0
  shift 5
  ( cd "$d" && "$@" ) < "$in" > "$o" 2> "$e" &
  pid=$!
  while kill -0 "$pid" 2>/dev/null && [ "$i" -lt "$((s * 10))" ]; do sleep 0.1; i=$((i + 1)); done
  if kill -0 "$pid" 2>/dev/null; then _b7g_kt "$pid"; B7END=killed; else B7END=ended; fi
  wait "$pid" 2>/dev/null; B7RC=$?
}
_b7g_trow() { LC_ALL=C awk -F'\t' -v n="$2" '$1 == n' "$1/templates/commissioning.tsv"; }   # HARNESS NEED: the template's row
_b7g_fix() {   # fixture A, built from nothing under $TMP/b17a (section 2, Terms)
  case "$TMP" in /?*) ;; *) return 1 ;; esac
  rm -rf "$TMP/b17a"; mkdir -p "$TMP/b17a"
  B7B="$(cd "$TMP/b17a" && pwd -P)"; B7G="$B7B/home"; B7P="$B7G/projects/p"; B7M="$B7B/mem"; B7U="$B7B/user"
  B7T="$B7B/tmp"; B7S="$B7B/stub"; B7R="$B7B/repo"; B7R2="$B7B/other"; B7O="$B7B/out"; B7D="$B7B/drepo"
  B7SL="$B7M/p/says.log"; B7ST="$B7P/autonomy.commission"; B7F="$B7G/harness/felix"
  mkdir -p "$B7P" "$B7M" "$B7U" "$B7T" "$B7S" "$B7R" "$B7R2" "$B7O" "$B7D"; chmod 700 "$B7T"
  _copy_content "$REAL_HARNESS" "$B7G/harness"
  printf '{"name": "p", "remote_match": "example/p", "gate": "true"}\n' > "$B7P/project.json"
  printf '# p\n' > "$B7P/CLAUDE.md"
  _b7g_trow "$B7G/harness" stack > "$B7P/commissioning.tsv"
  printf 'plugin\tsome-low-plugin@mkt\t-\tlow\talways\nplugin\tsome-high-plugin@mkt\t-\thigh\talways\n' > "$B7P/stack.tsv"
  printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s"\nexit 0\n' "$B7B/claude.log" > "$B7S/claude"
  printf '#!/bin/sh\nexit 0\n' > "$B7S/gh"; chmod +x "$B7S/claude" "$B7S/gh"
  ( _fx_cd "$B7R" && git init -q -b main && git remote add origin https://github.com/example/p.git ) >/dev/null 2>&1
  ( _fx_cd "$B7R2" && git init -q -b main && git remote add origin https://github.com/someone-else/p.git ) >/dev/null 2>&1
  printf 'p\n' > "$B7R/.felix"; printf 'p\n' > "$B7R2/.felix"
}
B7TTY=""; B7WD=60; B7PAGES=""; B7EOT="$(printf '\004\010\010')"; _b7g_lf=$'\n'
_b7g_run() {   # TAG MODE DIR IN [NAME=value...] -- EXE ARGS...: a no-terminal (nt), session (ss) or terminal (tt) run
  local tag="$1" m="$2" d="$3" in="$4"
  local -a x e
  shift 4; x=()
  while [ "$#" -gt 0 ] && [ "$1" != -- ]; do x[${#x[@]}]="$1"; shift; done
  [ "$#" -eq 0 ] || shift
  e=(env -u CLAUDECODE -u CLAUDE_CODE_SESSION_ID -u FELIX_COMMISSION_UNATTENDED HOME="$B7U" FELIX_HOME="$B7G"
     FELIX_MEMORY="$B7M" TMPDIR="$B7T" PATH="$B7S:$PATH")
  [ "$m" != ss ] || e=("${e[@]}" CLAUDECODE=1 CLAUDE_CODE_SESSION_ID=b17-sid)
  e=("${e[@]}" ${x[@]+"${x[@]}"} "$@")
  if [ "$m" = tt ] && [ "$B7TTY" = bsd ]; then e=(script -q /dev/null "${e[@]}")
  elif [ "$m" = tt ]; then e=(script -q -e -c "$(printf '%q ' "${e[@]}")" /dev/null); fi
  _b7g_wd "$B7WD" "$d" "$in" "$B7O/$tag.out" "$B7O/$tag.err" "${e[@]}"
  B7OUT="$(LC_ALL=C tr -d '\r' < "$B7O/$tag.out" | LC_ALL=C sed "s/$B7EOT//g")"; B7ERR="$(cat "$B7O/$tag.err")"
  [ "$B7END" = ended ] || B7ERR="[killed after $B7WD s] $B7ERR"
}
_b7g_lacks() { local t="$1" w; shift; for w in "$@"; do case "$t" in *"$w"*) ;; *) printf ' lacks [%s]' "$w" ;; esac; done; }
_b7g_holds() { local t="$1" w; shift; for w in "$@"; do case "$t" in *"$w"*) printf ' holds [%s]' "$w" ;; esac; done; }
_b7g_there() { local f; for f in "$@"; do if [ -e "$f" ] || [ -L "$f" ]; then printf ' [%s] is there' "${f##*/}"; fi; done; }
_b7g_said() { if [ -f "$1" ] && LC_ALL=C grep -qF -- "$2" "$1"; then echo said; else echo silent; fi; }   # FILE PHRASE
_b7g_ln() { if [ -f "$1" ] && LC_ALL=C awk -v w="$2" '$0 == w { f = 1 } END { exit !f }' "$1"; then echo yes; else echo no; fi; }
_b7g_nl() { if [ -f "$1" ]; then LC_ALL=C awk 'END { print NR }' "$1"; else echo 0; fi; }
_b7g_ck() { if [ -f "$1" ]; then cksum < "$1"; else echo absent; fi; }
_b7g_cl() { if [ -s "$B7B/claude.log" ]; then echo "$(_b7g_nl "$B7B/claude.log") line(s)"; else echo none; fi; }
_b7g_is() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "$(printf 'expected [%s] got [%s]%s' "$3" "$2" "${4:+ ($4)}" | tr '\n\r' '  ')"; fi; }
_b7g_shape() {   # FILE: how many lines it holds, and whether the last is ended
  local n e
  [ -f "$1" ] || { echo absent; return 0; }
  n="$(LC_ALL=C awk 'END { print NR }' "$1")"; e="$(wc -l < "$1" | tr -d ' ')"
  if [ "$n" = "$e" ]; then echo "$n lines, each ended"; else echo "$n lines, the last unended"; fi
}
_b7g_says() {   # FROM PREFIX|PREFIX...: the rows says.log gained after line FROM, as NF/kind/session/cause/text, text cut to its prefix
  [ -f "$B7SL" ] || { printf 'no says.log'; return 0; }
  LC_ALL=C awk -F'\t' -v n="$1" -v ps="$2" 'BEGIN { k = split(ps, pp, "|") }
    NR > n { i++; p = (i <= k) ? pp[i] : ""; t = (p != "" && index($5, p) == 1) ? p : "[" $5 "]"
             printf "%s%s/%s/%s/%s/%s", (i > 1 ? " ; " : ""), NF, $2, $3, $4, t }
    END { if (!i) printf "no row" }' "$B7SL"
}
_b7g_tail() {   # FROM: how many lines says.log gained after line FROM, and NF/field 3 of each
  [ -f "$B7SL" ] || { echo "no says.log"; return 0; }
  LC_ALL=C awk -F'\t' -v n="$1" 'NR > n { c++; s = s " " NF "/" $3 } END { print c + 0 " line(s):" s }' "$B7SL"
}
_b7g_snap() {   # FILE: the snapshot of section 2 (G/state, G/projects/p, M/p; cksum of each regular file; not says.log)
  local f
  for f in "$B7G/state" "$B7P" "$B7M/p"; do if [ -e "$f" ]; then find "$f" -print 2>/dev/null; fi; done | LC_ALL=C sort |
    while IFS= read -r f; do
      [ "$f" != "$B7SL" ] || continue
      if [ -f "$f" ] && [ ! -L "$f" ]; then printf '%s %s\n' "$f" "$(cksum < "$f")"; else printf '%s\n' "$f"; fi
    done > "$1"
}
_b7g_same() { if cmp -s "$1" "$2"; then echo same; else echo "changed: $(LC_ALL=C diff "$1" "$2" | LC_ALL=C sed -n '2,4p' | tr '\n' ' ')"; fi; }
_b7g_pv() { ( export FELIX_HOME="$B7G" FELIX_MEMORY="$B7M" HOME="$B7U"; . "$B7G/harness/lib/resolve.sh"
              . "$B7G/harness/lib/detect.sh"; . "$B7G/harness/lib/commission.sh"; felix_commission_policy_version "$B7P" ) 2>/dev/null; }
_b7g_page() {   # TAG: the status page; stdout in B7PG, the commission line in B7CL, the file added to B7PAGES
  _b7g_run "$1" nt "$B7R" /dev/null -- "$B7F" autonomy
  B7PG="$B7OUT"; B7PAGES="$B7PAGES$B7O/$1.out$_b7g_lf"
  B7CL="$(LC_ALL=C awk '/^ *\[.\] commission / { s = $0; sub(/^ +/, "", s); gsub(/[ \t]+/, " ", s); print s; exit }' "$B7O/$1.out")"
}
_b7g_settle() {   # HOME: session start's background discovery has a moment to start, then up to 30 s to drop its lock
  local i=0
  sleep 1
  while [ -d "$1/state/discover/.lock" ] && [ "$i" -lt 150 ]; do sleep 0.2; i=$((i + 1)); done
}

# ---- A1, then fixture A and how a terminal is made here
_b7g_is "b17 A1: the suite runs with CLAUDECODE and CLAUDE_CODE_SESSION_ID both unset, as on the CI runner" \
  "[${CLAUDECODE+set}][${CLAUDE_CODE_SESSION_ID+set}]" "[][]"
_b7g_fix
_b7g_wd 10 "$B7O" /dev/null "$B7O/tty1.out" "$B7O/tty1.err" script -q /dev/null sh -c 'test -t 0 && echo b17-tty'
case "$(cat "$B7O/tty1.out" 2>/dev/null)" in *b17-tty*) B7TTY=bsd ;; esac
if [ -z "$B7TTY" ]; then
  _b7g_wd 10 "$B7O" /dev/null "$B7O/tty2.out" "$B7O/tty2.err" script -q -e -c "sh -c 'test -t 0 && echo b17-tty'" /dev/null
  case "$(cat "$B7O/tty2.out" 2>/dev/null)" in *b17-tty*) B7TTY=util ;; esac
fi
B7NOTTY="neither BSD script -q /dev/null CMD nor util-linux script -q -e -c CMD /dev/null gives a terminal here"
_b7g_page g0

# ---- C032: a session's grant is refused, its revoke and its read are not (B1-B3)
_b7g_n="$(_b7g_nl "$B7SL")"
_b7g_run a2 ss "$B7R" /dev/null -- "$B7F" autonomy --allow tidy
_b7g_is "b17 A2: a session's felix autonomy --allow tidy is refused: exit 1, tidy is not allowed, from a terminal, Nothing was written" \
  "rc=$B7RC$(_b7g_lacks "$B7ERR" 'tidy is not allowed' 'from a terminal' 'Nothing was written')" "rc=1" "${B7ERR:0:300}"
_b7g_is "b17 A3: and that refusal leaves no autonomy file and no autonomy.lock" "$(_b7g_there "$B7P/autonomy" "$B7P/autonomy.lock")" ""
_b7g_run a4 ss "$B7R" /dev/null -- "$B7F" autonomy --allow commission
_b7g_is "b17 A4: a session's --allow commission is refused the same way and leaves neither the grant file nor the stamp" \
  "rc=$B7RC$(_b7g_lacks "$B7ERR" 'commission is not allowed' 'from a terminal' 'Nothing was written')$(_b7g_there "$B7P/autonomy" "$B7ST")" \
  "rc=1" "${B7ERR:0:300}"
_b7g_is "b17 A5: the two refusals appended two says rows: consent, the session id, felix autonomy, refused: allow tidy, then commission (session)" \
  "$(_b7g_says "$_b7g_n" 'refused: allow tidy (session)|refused: allow commission (session)')" \
  "5/consent/b17-sid/felix autonomy/refused: allow tidy (session) ; 5/consent/b17-sid/felix autonomy/refused: allow commission (session)"
_b7g_run a6t nt "$B7R" /dev/null -- "$B7F" autonomy --allow tidy
_b7g_c="$(_b7g_ck "$B7P/autonomy")"; _b7g_t="$(_b7g_ln "$B7P/autonomy" tidy)"
_b7g_run a6 ss "$B7R" /dev/null -- "$B7F" autonomy --allow commission
if [ "$(_b7g_ck "$B7P/autonomy")" = "$_b7g_c" ]; then _b7g_v=same; else _b7g_v=changed; fi
_b7g_is "b17 A6: with tidy granted from no terminal, a session's --allow commission leaves the grant file's bytes and writes no stamp" \
  "tidy granted first: $_b7g_t; grant file $_b7g_v$(_b7g_there "$B7ST")" "tidy granted first: yes; grant file same"
_b7g_run a7 ss "$B7R" /dev/null -- "$B7F" autonomy --revoke tidy --allow commission
_b7g_is "b17 A7: a session's --revoke tidy --allow commission is refused whole: exit 1, commission is not allowed, tidy is not revoked, tidy kept" \
  "rc=$B7RC$(_b7g_lacks "$B7ERR" 'commission is not allowed' 'tidy is not revoked') tidy=$(_b7g_ln "$B7P/autonomy" tidy)" "rc=1 tidy=yes" "${B7ERR:0:300}"
_b7g_n="$(_b7g_nl "$B7SL")"
_b7g_run a8 ss "$B7R" /dev/null -- "$B7F" autonomy --revoke tidy
_b7g_is "b17 A8: a session may revoke: --revoke tidy exits 0, takes tidy away, and records revoked tidy (session) under its session id" \
  "rc=$B7RC tidy=$(_b7g_ln "$B7P/autonomy" tidy) $(_b7g_says "$_b7g_n" 'revoked tidy (session)')" \
  "rc=0 tidy=no 5/consent/b17-sid/felix autonomy/revoked tidy (session)" "${B7ERR:0:300}"
_b7g_snap "$B7O/s9a"; _b7g_n="$(_b7g_nl "$B7SL")"
_b7g_run a9 ss "$B7R" /dev/null -- "$B7F" autonomy
_b7g_snap "$B7O/s9b"
_b7g_is "b17 A9: a session may read: felix autonomy with no arguments exits 0, changes nothing and records no row (control)" \
  "rc=$B7RC snapshot $(_b7g_same "$B7O/s9a" "$B7O/s9b"), says rows +$(( $(_b7g_nl "$B7SL") - _b7g_n ))" "rc=0 snapshot same, says rows +0"

# ---- C032: a grant from no terminal, or from a terminal, works and is recorded (B4-B9)
_b7g_n="$(_b7g_nl "$B7SL")"
_b7g_run a10 nt "$B7R" /dev/null -- "$B7F" autonomy --allow commission
_b7g_is "b17 A10: a grant from no terminal works: --allow commission exits 0, saying allowed: commission and stamped against (control)" \
  "rc=$B7RC$(_b7g_lacks "$B7OUT" 'allowed: commission' 'stamped against')" "rc=0" "${B7ERR:0:300}"
_b7g_s13="$(_b7g_says "$_b7g_n" 'allowed commission (no-terminal)')"
_b7g_P="$(_b7g_pv)"; _b7g_l1="$(LC_ALL=C sed -n 1p "$B7ST" 2>/dev/null)"
if [ -z "$_b7g_P" ]; then _b7g_v="P could not be computed"
elif [ "$_b7g_l1" = "$_b7g_P" ]; then _b7g_v="line 1 is P"; else _b7g_v="line 1 is [$_b7g_l1], P is [$_b7g_P]"; fi
_b7g_is "b17 A11: the stamp is exactly two newline-ended lines, and line 1 is the policy version" \
  "$(_b7g_shape "$B7ST"); $_b7g_v" "2 lines, each ended; line 1 is P"
_b7g_l2() {   # FILE: line 2 of a stamp as NF/field 1/hex or [field 2]/field 3/utc or [field 4]
  LC_ALL=C awk -F'\t' 'NR == 2 { d = "[0123456789]"; t = "^" d d d d "-" d d "-" d d "T" d d ":" d d ":" d d "Z$"
      h = (length($2) >= 40 && $2 !~ /[^0123456789abcdef]/) ? "hex" : "[" $2 "]"
      printf "%s/%s/%s/%s/%s", NF, $1, h, $3, ($4 ~ t ? "utc" : "[" $4 "]"); f = 1 }
    END { if (!f) printf "no line 2" }' "$1" 2>/dev/null
}
_b7g_is "b17 A12: the stamp's line 2 is consent, 40 or more lowercase hex digits, no-terminal, and a UTC time, tab-separated" \
  "$(_b7g_l2 "$B7ST")" "4/consent/hex/no-terminal/utc"
_b7g_is "b17 A13: the grant from no terminal appended one says row: consent, -, felix autonomy, allowed commission (no-terminal)" \
  "$_b7g_s13" "5/consent/-/felix autonomy/allowed commission (no-terminal)"
_b7g_page g10
_b7g_n="$(_b7g_nl "$B7SL")"
_b7g_run a14 nt "$B7R" /dev/null -- "$B7F" autonomy --allow tidy
_b7g_is "b17 A14: --allow tidy from no terminal records allowed tidy (no-terminal) and writes no autonomy.tidy" \
  "$(_b7g_says "$_b7g_n" 'allowed tidy (no-terminal)')$(_b7g_there "$B7P/autonomy.tidy")" "5/consent/-/felix autonomy/allowed tidy (no-terminal)"
_b7g_n="$(_b7g_nl "$B7SL")"
_b7g_run a15c nt "$B7R" /dev/null -- "$B7F" autonomy --allow commission
_b7g_v="$(_b7g_says "$_b7g_n" 'allowed commission (no-terminal)') | stamp $(_b7g_shape "$B7ST")"
_b7g_n="$(_b7g_nl "$B7SL")"
_b7g_run a15t nt "$B7R" /dev/null -- "$B7F" autonomy --allow tidy
_b7g_is "b17 A15: re-granting commission records one more row and keeps a two-line stamp; a second --allow tidy says already allowed, records nothing" \
  "$_b7g_v | tidy again$(_b7g_lacks "$B7OUT" 'already allowed: tidy'), says rows +$(( $(_b7g_nl "$B7SL") - _b7g_n ))" \
  "5/consent/-/felix autonomy/allowed commission (no-terminal) | stamp 2 lines, each ended | tidy again, says rows +0"
_b7g_n="$(_b7g_nl "$B7SL")"
_b7g_run a16t ss "$B7R" /dev/null "CLAUDE_CODE_SESSION_ID=b17$(printf '\t')x" -- "$B7F" autonomy --allow tidy
_b7g_v="tab: $(_b7g_tail "$_b7g_n")"
_b7g_n="$(_b7g_nl "$B7SL")"
_b7g_run a16n ss "$B7R" /dev/null "CLAUDE_CODE_SESSION_ID=b17${_b7g_lf}x" -- "$B7F" autonomy --allow tidy
_b7g_is "b17 A16: a session id holding a tab or a newline is written as -, in one says line of exactly five fields" \
  "$_b7g_v; newline: $(_b7g_tail "$_b7g_n")" "tab: 1 line(s): 5/-; newline: 1 line(s): 5/-"
_b7g_n17="A17: a grant from a terminal exits 0 and records the class terminal in the stamp's line 2 and in the says row"
if [ -n "$B7TTY" ]; then
  _b7g_n="$(_b7g_nl "$B7SL")"
  _b7g_run a17 tt "$B7R" /dev/null -- "$B7F" autonomy --allow commission
  _b7g_is "b17 $_b7g_n17" "rc=$B7RC class=$(LC_ALL=C awk -F'\t' 'NR == 2 { print $3 }' "$B7ST" 2>/dev/null) $(_b7g_says "$_b7g_n" 'allowed commission (terminal)')" \
    "rc=0 class=terminal 5/consent/-/felix autonomy/allowed commission (terminal)" "${B7OUT:0:300}"
  _b7g_page g17
else skip "b17 $_b7g_n17" "$B7NOTTY"; fi
_b7g_run a18r nt "$B7R" /dev/null -- "$B7F" autonomy --revoke tidy
_b7g_n18="A18: a terminal wins over the session variables: tidy is granted and recorded as (terminal) under the session id"
if [ -n "$B7TTY" ]; then
  _b7g_n="$(_b7g_nl "$B7SL")"
  _b7g_run a18 tt "$B7R" /dev/null CLAUDECODE=1 CLAUDE_CODE_SESSION_ID=b17-sid -- "$B7F" autonomy --allow tidy
  _b7g_is "b17 $_b7g_n18" "rc=$B7RC tidy=$(_b7g_ln "$B7P/autonomy" tidy) $(_b7g_says "$_b7g_n" 'allowed tidy (terminal)')" \
    "rc=0 tidy=yes 5/consent/b17-sid/felix autonomy/allowed tidy (terminal)" "${B7OUT:0:300}"
else skip "b17 $_b7g_n18" "$B7NOTTY"; fi
_b7g_n19="A19: the status page says where the stamp was made (a terminal, no terminal attached, or that it does not say), and an unknown place keeps [x]"
if [ -n "$B7TTY" ]; then
  cp "$B7ST" "$B7O/stamp.keep" 2>/dev/null
  LC_ALL=C awk -F'\t' -v OFS='\t' 'NR == 2 && NF >= 3 { $3 = "elsewhere" } { print }' "$B7O/stamp.keep" > "$B7O/stamp.else" 2>/dev/null \
    && cat "$B7O/stamp.else" > "$B7ST"
  _b7g_page g19
  _b7g_v="terminal:$(_b7g_said "$B7O/g17.out" 'stamped from a terminal') no-terminal:$(_b7g_said "$B7O/g10.out" 'stamped with no terminal attached')"
  _b7g_v="$_b7g_v elsewhere:$(_b7g_said "$B7O/g19.out" 'the stamp does not say where it was made') line:${B7CL:0:14}"
  [ ! -f "$B7O/stamp.keep" ] || cat "$B7O/stamp.keep" > "$B7ST"
  _b7g_is "b17 $_b7g_n19" "$_b7g_v" "terminal:said no-terminal:said elsewhere:said line:[x] commission"
else skip "b17 $_b7g_n19" "$B7NOTTY, and A19 reads the page after A17's terminal grant"; fi
_b7g_v=""; _b7g_c=0
while IFS= read -r _b7g_f; do
  [ -n "$_b7g_f" ] || continue
  _b7g_c=$((_b7g_c + 1)); _b7g_t="$(LC_ALL=C awk '/^ *\[.\] commission / { n++ } END { print n + 0 }' "$_b7g_f" 2>/dev/null)"
  [ "$_b7g_t" = 1 ] || _b7g_v="$_b7g_v ${_b7g_f##*/}: $_b7g_t commission lines;"
  [ "$(_b7g_said "$_b7g_f" 'not one that works around it')" = said ] || _b7g_v="$_b7g_v ${_b7g_f##*/}: no floor sentence;"
done <<< "$B7PAGES"
[ "$_b7g_c" -ge 2 ] || _b7g_v="$_b7g_v only $_b7g_c page(s) read;"
_b7g_is "b17 A20: every status page read here has exactly one commission line and says the refusal stops only a session that follows its instructions" \
  "$_b7g_v" "" "$_b7g_c pages"
_b7g_run a21r nt "$B7R" /dev/null -- "$B7F" autonomy --revoke tidy
_b7g_mv=0; if [ -e "$B7M/p" ]; then mv "$B7M/p" "$B7M/p.keep" && _b7g_mv=1; fi
printf 'x\n' > "$B7M/p"
_b7g_run a21 nt "$B7R" /dev/null -- "$B7F" autonomy --allow tidy
_b7g_v="rc=$B7RC tidy=$(_b7g_ln "$B7P/autonomy" tidy)$(_b7g_lacks "$B7OUT$_b7g_lf$B7ERR" 'not recorded')"
rm -f "$B7M/p"; [ "$_b7g_mv" = 0 ] || mv "$B7M/p.keep" "$B7M/p"
_b7g_is "b17 A21: a says row that cannot be written is said (not recorded), and the grant of tidy still holds" "$_b7g_v" "rc=0 tidy=yes" "${B7ERR:0:300}"

# ---- the deny rows (B10): read out of projects/felix/deny.tsv by their reason, alone in project d's table
B7DT="$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix/deny.tsv"; B7NODT="no projects/felix/deny.tsv beside this harness"
_b7g_rows=""
if [ -f "$B7DT" ]; then _b7g_rows="$(_P="a grant is a person's word" LC_ALL=C awk -F'\t' '/^#/ { next } index($3, ENVIRON["_P"]) == 1' "$B7DT")"; fi
mkdir -p "$B7G/projects/d"; printf '{"name": "d", "gate": "true"}\n' > "$B7G/projects/d/project.json"
if [ -n "$_b7g_rows" ]; then printf '%s\n' "$_b7g_rows" > "$B7G/projects/d/deny.tsv"; else : > "$B7G/projects/d/deny.tsv"; fi
( _fx_cd "$B7D" && git init -q -b main ) >/dev/null 2>&1; printf 'd\n' > "$B7D/.felix"
_b7g_reason() { printf '%s\n' "$_b7g_rows" | LC_ALL=C awk -F'\t' -v t="$1" '$1 == t { print $3; exit }'; }
_b7g_dcases() {   # WANT (2 refused, 0 allowed); the cases on fd 3, TOOL PATH a line -> each case that answered otherwise
  local want="$1" t p r
  while read -r t p <&3; do
    [ -n "$t" ] || continue
    printf '{"tool_name":"%s","tool_input":{"file_path":"%s","content":"x"},"cwd":"%s"}' "$t" "$p" "$B7D" > "$B7O/hook.json"
    _b7g_wd 60 "$B7D" "$B7O/hook.json" "$B7O/hook.out" "$B7O/hook.err" \
      env FELIX_HOME="$B7G" FELIX_MEMORY="$B7M" TMPDIR="$TMP" "$B7G/harness/hooks/pre-tool"
    r="$(_b7g_reason "$t")"
    if [ "$B7RC" != "$want" ]; then printf ' %s %s gave %s;' "$t" "$p" "$B7RC"
    elif [ "$want" = 2 ] && { [ -z "$r" ] || ! LC_ALL=C grep -qF -- "$r" "$B7O/hook.err"; }; then
      printf ' %s %s gave 2 without the reason whole;' "$t" "$p"
    fi
  done
}
printf '%s\n' "Write /b17-nowhere/home/projects/p/autonomy" "Write /b17-nowhere/home/projects/p/autonomy.commission" \
  "Edit /b17-nowhere/home/projects/felix/autonomy" "Edit /b17-nowhere/home/.claude/worktrees/w/projects/q/autonomy.tidy" \
  "Write $B7D/projects/p/autonomy" > "$B7O/refused.cases"
printf '%s\n' "Write /b17-nowhere/home/projects/p/commissioning.tsv" "Write /b17-nowhere/home/docs/autonomy" \
  "Write /b17-nowhere/home/projects/p/my-autonomy" "Write /b17-nowhere/home/projects/p/autonomy/notes" \
  "Read /b17-nowhere/home/projects/p/autonomy" "Write $B7G/projects/p/autonomy" > "$B7O/allowed.cases"
_b7g_d22="A22: projects/felix/deny.tsv has exactly two rows whose reason begins a grant is a person's word"
_b7g_d23="A23: they are one Write row and one Edit row, four fields each, scoped checkout, with one pattern between them"
_b7g_d24="A24: those rows refuse a Write or Edit of a project's autonomy or autonomy.<word>, outside the checkout and in it, with the reason whole"
_b7g_d25="A25: and they allow commissioning.tsv, docs/autonomy, my-autonomy, autonomy/notes, a Read, and a fixture outside the checkout (control)"
if [ -f "$B7DT" ]; then
  _b7g_is "b17 $_b7g_d22" "$(printf '%s' "$_b7g_rows" | LC_ALL=C awk 'END { print NR }')" "2"
  _b7g_is "b17 $_b7g_d23" \
    "$(printf '%s\n' "$_b7g_rows" | LC_ALL=C awk -F'\t' '$0 != "" { print $1 ":" NF ":" $4 }' | LC_ALL=C sort | tr '\n' ' ')| $(printf '%s\n' "$_b7g_rows" | LC_ALL=C awk -F'\t' '$0 != "" { print $2 }' | LC_ALL=C sort -u | LC_ALL=C awk 'END { print NR }') pattern(s)" \
    "Edit:4:checkout Write:4:checkout | 1 pattern(s)"
  _b7g_is "b17 $_b7g_d24" "$(_b7g_dcases 2 3< "$B7O/refused.cases")" ""
  _b7g_is "b17 $_b7g_d25" "$(_b7g_dcases 0 3< "$B7O/allowed.cases")" ""
else
  skip "b17 $_b7g_d22" "$B7NODT"; skip "b17 $_b7g_d23" "$B7NODT"; skip "b17 $_b7g_d24" "$B7NODT"; skip "b17 $_b7g_d25" "$B7NODT"
fi

# ---- C033: the commission run is never a session's (B12-B18)
rm -f "$B7B/claude.log"
_b7g_snap "$B7O/s26a"; _b7g_n="$(_b7g_nl "$B7SL")"
_b7g_run a26 ss "$B7R" /dev/null -- "$B7F" commission
_b7g_snap "$B7O/s26b"
_b7g_is "b17 A26: a session's felix commission is refused: exit 1, from a terminal, nothing was run or written, felix commission --status" \
  "rc=$B7RC$(_b7g_lacks "$B7ERR" 'from a terminal' 'nothing was run or written' 'felix commission --status')" "rc=1" "${B7ERR:0:300}"
_b7g_is "b17 A27: that refusal changes nothing, writes no receipt and calls no claude" \
  "snapshot $(_b7g_same "$B7O/s26a" "$B7O/s26b")$(_b7g_there "$B7G/state/commission/p"); claude: $(_b7g_cl)" "snapshot same; claude: none"
_b7g_is "b17 A28: and records one says row: consent, the session id, felix commission, refused: commission run (session)" \
  "$(_b7g_says "$_b7g_n" 'refused: commission run (session)')" "5/consent/b17-sid/felix commission/refused: commission run (session)"
_b7g_run a29n nt "$B7R" /dev/null -- "$B7F" commission
_b7g_r="$(_b7g_there "$B7G/state/commission/p")"
printf '# b17: a comment line, so the table has changed\n' >> "$B7P/commissioning.tsv"
_b7g_c="$(_b7g_ck "$B7G/state/commission/p")"
_b7g_run a29 ss "$B7R" /dev/null -- "$B7F" commission
if [ "$(_b7g_ck "$B7G/state/commission/p")" = "$_b7g_c" ]; then _b7g_v=same; else _b7g_v=changed; fi
_b7g_is "b17 A29: with a receipt written from no terminal and the table since edited, a session's felix commission exits 1 and leaves the receipt's bytes" \
  "receipt first:${_b7g_r:- none}; rc=$B7RC; receipt $_b7g_v" "receipt first: [p] is there; rc=1; receipt same" "${B7ERR:0:300}"
_b7g_snap "$B7O/s30a"; _b7g_n="$(_b7g_nl "$B7SL")"
_b7g_run a30s ss "$B7R" /dev/null -- "$B7F" commission --status
_b7g_rs="$B7RC"; _b7g_os="$(printf '%s' "$B7OUT" | LC_ALL=C sed 's/[0123456789][0123456789]*/0/g')"
_b7g_snap "$B7O/s30b"; _b7g_d="$(( $(_b7g_nl "$B7SL") - _b7g_n ))"
_b7g_run a30n nt "$B7R" /dev/null -- "$B7F" commission --status
_b7g_rn="$B7RC"; _b7g_on="$(printf '%s' "$B7OUT" | LC_ALL=C sed 's/[0123456789][0123456789]*/0/g')"
if [ "$_b7g_os" = "$_b7g_on" ]; then _b7g_v=equal; else _b7g_v=differ; fi
_b7g_is "b17 A30: felix commission --status stays open to a session: its exit and stdout are no-terminal's, digits aside, and it changes nothing (control)" \
  "exit $_b7g_rs vs $_b7g_rn; stdout $_b7g_v; snapshot $(_b7g_same "$B7O/s30a" "$B7O/s30b"), says rows +$_b7g_d" \
  "exit $_b7g_rn vs $_b7g_rn; stdout equal; snapshot same, says rows +0" "session [${_b7g_os:0:200}] no terminal [${_b7g_on:0:200}]"
_b7g_run a31y ss "$B7R" /dev/null FELIX_COMMISSION_UNATTENDED=yes -- "$B7F" commission
_b7g_v="yes: rc=$B7RC$(_b7g_lacks "$B7ERR" 'from a terminal')"
_b7g_run a31z ss "$B7R" /dev/null FELIX_COMMISSION_UNATTENDED=0 -- "$B7F" commission
_b7g_is "b17 A31: FELIX_COMMISSION_UNATTENDED=yes or =0 is not the unattended mark: a session's felix commission is still refused" \
  "$_b7g_v; 0: rc=$B7RC$(_b7g_lacks "$B7ERR" 'from a terminal')" "yes: rc=1; 0: rc=1"
_b7g_run a32 ss "$B7R" /dev/null FELIX_COMMISSION_UNATTENDED=1 -- "$B7F" commission --status
_b7g_is "b17 A32: a session's --status with FELIX_COMMISSION_UNATTENDED=1 exits as the no-terminal --status does (control)" "exit $B7RC" "exit $_b7g_rn"
_b7g_trow "$B7G/harness" constitution_audited > "$B7O/ca.row"; cat "$B7O/ca.row" > "$B7P/commissioning.tsv"
printf '{"source":"startup","session_id":"b17-ss"}' > "$B7O/ss.json"
_b7g_run a33 ss "$B7R" "$B7O/ss.json" CLAUDE_CODE_SESSION_ID=b17-ss -- "$B7G/harness/hooks/session-start"
_b7g_rc33="$B7RC"; _b7g_settle "$B7G"
_b7g_n33="A33: session start's owed paragraph says the run is made from a terminal, names felix commission --status, and no longer says then felix commission"
if command -v jq >/dev/null 2>&1; then
  _b7g_x="$(jq -r '.hookSpecificOutput.additionalContext' < "$B7O/a33.out" 2>/dev/null)"
  _b7g_is "b17 $_b7g_n33" \
    "rc=$_b7g_rc33$(_b7g_lacks "$_b7g_x" 'A session still owes these' 'write the answer file it names' 'from a terminal' 'felix commission --status')$(_b7g_holds "$_b7g_x" 'write the answer file it names, then felix commission')" \
    "rc=0" "${_b7g_x:0:300}"
else skip "b17 $_b7g_n33" "jq is not on PATH"; fi
_b7g_md="$REAL_HARNESS/../commands/felix.md"
if [ -f "$_b7g_md" ]; then _b7g_v="old:$(_b7g_said "$_b7g_md" 'Then run `felix commission` again') terminal:$(_b7g_said "$_b7g_md" 'from a terminal')"
else _b7g_v="no engine/commands/felix.md"; fi
_b7g_is "b17 A34: the felix skill no longer says Then run felix commission again, and says the run is made from a terminal" "$_b7g_v" "old:silent terminal:said"
B7G3="$B7B/newhome"; B7R3="$B7B/repo3"; B7R4="$B7B/repo4"
mkdir -p "$B7G3/projects" "$B7R3" "$B7R4"
_copy_content "$REAL_HARNESS" "$B7G3/harness"
_b7g_trow "$B7G3/harness" stack > "$B7O/stack.row"; cat "$B7O/stack.row" > "$B7G3/harness/templates/commissioning.tsv"
( _fx_cd "$B7R3" && git init -q -b main && git remote add origin https://github.com/example/q.git ) >/dev/null 2>&1
( _fx_cd "$B7R4" && git init -q -b main && git remote add origin https://github.com/example/r.git ) >/dev/null 2>&1
_b7g_run a35 ss "$B7R3" /dev/null FELIX_HOME="$B7G3" -- "$B7G3/harness/felix" new q
_b7g_v="rc=$B7RC json=$(if [ -f "$B7G3/projects/q/project.json" ]; then echo yes; else echo no; fi) marker=$(cat "$B7R3/.felix" 2>/dev/null)"
_b7g_is "b17 A35: felix new from a session binds the project and does not commission, saying commissioning skipped and from a terminal" \
  "$_b7g_v$(_b7g_there "$B7G3/state/commission/q")$(_b7g_lacks "$B7OUT" 'commissioning skipped' 'from a terminal')" "rc=0 json=yes marker=q" "${B7ERR:0:300}"
_b7g_run a36 nt "$B7R4" /dev/null FELIX_HOME="$B7G3" -- "$B7G3/harness/felix" new r
_b7g_is "b17 A36: felix new from no terminal still commissions: exit 0 and a receipt (control)" \
  "rc=$B7RC receipt=$(if [ -e "$B7G3/state/commission/r" ]; then echo yes; else echo no; fi)" "rc=0 receipt=yes" "${B7ERR:0:300}"
_b7g_settle "$B7G3"
_b7g_v="$(if [ -f "$B7SL" ]; then LC_ALL=C awk -F'\t' '$4 == "felix autonomy" || $4 == "felix commission" { n++; if (NF != 5 || $2 != "consent") o++ }
  END { print (n >= 6 ? "six or more" : n + 0 " only") ", " o + 0 " not five fields of kind consent" }' "$B7SL"; else echo "no says.log"; fi)"
_b7g_is "b17 A37: the says rows this part caused through felix autonomy and felix commission number six or more, each five fields of kind consent" \
  "$_b7g_v" "six or more, 0 not five fields of kind consent"
