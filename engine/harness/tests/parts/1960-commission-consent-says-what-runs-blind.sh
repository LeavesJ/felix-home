printf '\nthe commission consent says what the unattended run does, and the grant is bound to that text (audit b17, A38-A60, blind)\n'
# Written blind on 2026-10-24 from docs/2026-10-24-audit-fixes/b17-commission-grant-cannot-be-self-
# given-or.md alone (section 2's terms, B14-B26, and section 4's A38-A60). No engine code was read:
# felix, session start and the libs the contract names are run as black boxes. This part builds its
# own fixtures A and B under $TMP/b17a and $TMP/b17b and relies on nothing part 1950 left.
#
# Readings, where the contract leaves room, mine:
# - "Fresh fixture A" is rebuilt for A38, A39, A40, A43, and for the consent section (A44 on), which
#   then carries one fixture A through A44-A55 in the items' order; A41 and A42 follow A40's.
# - B/claude.log is removed before each run whose calls are read as "absent or empty".
# - A44's "each whole on one line" is read as a line of the page holding the whole phrase.
# - A46 and A47 write the one-line stamp as P of the table as it then stands, with commission granted.
# - A49 changes the hash's first digit to a when it is not a, and to b when it is; A52 and A53 edit
#   the first file (in C-locale name order) outside tests/ that holds the line, written back with cat.
# - A54 and A55 read the page under the same 20 s watchdog as the grant: a page that does not end has
#   no commission line, and that is a failure, not a pass.
# - C048: A56-A59 are one assertion per table, named by it (A57-A59 for the template too); with no
#   project table found, each of A56-A59 is one skip that says so.

# ---- helpers: a run under a watchdog, and the readings of section 2
_b7c_kt() { local c; kill -STOP "$1" 2>/dev/null
            for c in $(pgrep -P "$1" 2>/dev/null); do _b7c_kt "$c"; done; kill -KILL "$1" 2>/dev/null; }
_b7c_wd() {   # SECONDS DIR IN OUT ERR CMD...: CMD in DIR, its tree killed by pid if it outlives SECONDS; sets B7RC, B7END
  local s="$1" d="$2" in="$3" o="$4" e="$5" pid i=0
  shift 5
  ( cd "$d" && "$@" ) < "$in" > "$o" 2> "$e" &
  pid=$!
  while kill -0 "$pid" 2>/dev/null && [ "$i" -lt "$((s * 10))" ]; do sleep 0.1; i=$((i + 1)); done
  if kill -0 "$pid" 2>/dev/null; then _b7c_kt "$pid"; B7END=killed; else B7END=ended; fi
  wait "$pid" 2>/dev/null; B7RC=$?
}
_b7c_trow() { LC_ALL=C awk -F'\t' -v n="$2" '$1 == n' "$1/templates/commissioning.tsv"; }   # HARNESS NEED: the template's row
_b7c_use() {   # a or b: the B7 variables name fixture A ($TMP/b17a, project p) or fixture B ($TMP/b17b, project q)
  B7B="$TMP/b17$1"; [ ! -d "$B7B" ] || B7B="$(cd "$B7B" && pwd -P)"
  if [ "$1" = a ]; then B7N=p; else B7N=q; fi
  B7G="$B7B/home"; B7P="$B7G/projects/$B7N"; B7M="$B7B/mem"; B7U="$B7B/user"; B7T="$B7B/tmp"; B7S="$B7B/stub"
  B7R="$B7B/repo"; B7R2="$B7B/other"; B7O="$B7B/out"; B7F="$B7G/harness/felix"; B7ST="$B7P/autonomy.commission"
  B7RCP="$B7G/state/commission/$B7N"
}
_b7c_fix() {   # a or b: that fixture, built from nothing (section 2, Terms)
  case "$TMP" in /?*) ;; *) return 1 ;; esac
  rm -rf "$TMP/b17$1"; mkdir -p "$TMP/b17$1"; _b7c_use "$1"
  mkdir -p "$B7P" "$B7M" "$B7U" "$B7T" "$B7S" "$B7R" "$B7R2" "$B7O"; chmod 700 "$B7T"
  _copy_content "$REAL_HARNESS" "$B7G/harness"
  printf '{"name": "%s", "remote_match": "example/%s", "gate": "true"}\n' "$B7N" "$B7N" > "$B7P/project.json"
  printf '# %s\n' "$B7N" > "$B7P/CLAUDE.md"
  _b7c_trow "$B7G/harness" stack > "$B7P/commissioning.tsv"
  printf 'plugin\tsome-low-plugin@mkt\t-\tlow\talways\nplugin\tsome-high-plugin@mkt\t-\thigh\talways\n' > "$B7P/stack.tsv"
  printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s"\nexit 0\n' "$B7B/claude.log" > "$B7S/claude"
  printf '#!/bin/sh\nexit 0\n' > "$B7S/gh"; chmod +x "$B7S/claude" "$B7S/gh"
  ( _fx_cd "$B7R" && git init -q -b main && git remote add origin "https://github.com/example/$B7N.git" ) >/dev/null 2>&1
  ( _fx_cd "$B7R2" && git init -q -b main && git remote add origin "https://github.com/someone-else/$B7N.git" ) >/dev/null 2>&1
  printf '%s\n' "$B7N" > "$B7R/.felix"; printf '%s\n' "$B7N" > "$B7R2/.felix"
}
B7WD=60
_b7c_run() {   # TAG MODE DIR IN [NAME=value...] -- EXE ARGS...: a no-terminal (nt) or session (ss) run
  local tag="$1" m="$2" d="$3" in="$4"
  local -a x e
  shift 4; x=()
  while [ "$#" -gt 0 ] && [ "$1" != -- ]; do x[${#x[@]}]="$1"; shift; done
  [ "$#" -eq 0 ] || shift
  e=(env -u CLAUDECODE -u CLAUDE_CODE_SESSION_ID -u FELIX_COMMISSION_UNATTENDED HOME="$B7U" FELIX_HOME="$B7G"
     FELIX_MEMORY="$B7M" TMPDIR="$B7T" PATH="$B7S:$PATH")
  [ "$m" != ss ] || e=("${e[@]}" CLAUDECODE=1 CLAUDE_CODE_SESSION_ID=b17-sid)
  _b7c_wd "$B7WD" "$d" "$in" "$B7O/$tag.out" "$B7O/$tag.err" "${e[@]}" ${x[@]+"${x[@]}"} "$@"
  B7OUT="$(cat "$B7O/$tag.out")"; B7ERR="$(cat "$B7O/$tag.err")"
  [ "$B7END" = ended ] || B7ERR="[killed after $B7WD s] $B7ERR"
}
_b7c_lacks() { local t="$1" w; shift; for w in "$@"; do case "$t" in *"$w"*) ;; *) printf ' lacks [%s]' "$w" ;; esac; done; }
_b7c_holds() { local t="$1" w; shift; for w in "$@"; do case "$t" in *"$w"*) printf ' holds [%s]' "$w" ;; esac; done; }
_b7c_there() { local f; for f in "$@"; do if [ -e "$f" ] || [ -L "$f" ]; then printf ' [%s] is there' "${f##*/}"; fi; done; }
_b7c_is() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "$(printf 'expected [%s] got [%s]%s' "$3" "$2" "${4:+ ($4)}" | tr '\n\r' '  ')"; fi; }
_b7c_cl() { if [ -s "$B7B/claude.log" ]; then echo "$(LC_ALL=C awk 'END { print NR }' "$B7B/claude.log") line(s)"; else echo none; fi; }
_b7c_inst() {   # -> low:yes|no high:none|N, from B/claude.log: the low row's user-scope install, and any install of the high row
  [ -f "$B7B/claude.log" ] || { echo "no claude.log"; return 0; }
  LC_ALL=C awk 'index($0, "plugin install") && index($0, "some-low-plugin@mkt") && index($0, "--scope user") { l = 1 }
    index($0, "some-high-plugin@mkt") && index($0, "install") { h++ }
    END { print "low:" (l ? "yes" : "no") " high:" (h ? h : "none") }' "$B7B/claude.log"
}
_b7c_rcpt() {   # -> the receipt as N line(s), M fields, and whether field 5 is held or commissioned
  [ -f "$B7RCP" ] || { echo "no receipt"; return 0; }
  LC_ALL=C awk -F'\t' '{ n++; nf = NF; s = $5 }
    END { print n + 0 " line(s), " nf + 0 " fields, " ((s == "held" || s == "commissioned") ? "held or commissioned" : "[" s "]") }' "$B7RCP"
}
_b7c_snap() {   # FILE: the snapshot of section 2 (G/state, the project's directory, its memory; not says.log)
  local f
  for f in "$B7G/state" "$B7P" "$B7M/$B7N"; do if [ -e "$f" ]; then find "$f" -print 2>/dev/null; fi; done | LC_ALL=C sort |
    while IFS= read -r f; do
      [ "$f" != "$B7M/$B7N/says.log" ] || continue
      if [ -f "$f" ] && [ ! -L "$f" ]; then printf '%s %s\n' "$f" "$(cksum < "$f")"; else printf '%s\n' "$f"; fi
    done > "$1"
}
_b7c_same() { if cmp -s "$1" "$2"; then echo same; else echo "changed: $(LC_ALL=C diff "$1" "$2" | LC_ALL=C sed -n '2,4p' | tr '\n' ' ')"; fi; }
_b7c_pv() { ( export FELIX_HOME="$B7G" FELIX_MEMORY="$B7M" HOME="$B7U"; . "$B7G/harness/lib/resolve.sh"
              . "$B7G/harness/lib/detect.sh"; . "$B7G/harness/lib/commission.sh"; felix_commission_policy_version "$B7P" ) 2>/dev/null; }
_b7c_cur() { ( export FELIX_HOME="$B7G" FELIX_MEMORY="$B7M" HOME="$B7U"; H="$B7G/harness"; . "$H/lib/resolve.sh"; . "$H/lib/detect.sh"
               . "$H/lib/commission.sh"; . "$H/lib/autonomy.sh"
               felix_autonomy_commission_current "$B7P" && echo current || echo stale ) 2>/dev/null; }
_b7c_page() {   # TAG [EXE]: the status page; its file is $B7O/TAG.out, its commission line B7CL
  _b7c_run "$1" nt "$B7R" /dev/null -- "${2:-$B7F}" autonomy
  B7CL="$(LC_ALL=C awk '/^ *\[.\] commission / { s = $0; sub(/^ +/, "", s); gsub(/[ \t]+/, " ", s); print s; exit }' "$B7O/$1.out")"
}
_b7c_until() { local i=0 n="$(( $1 * 5 ))"; while [ "$i" -lt "$n" ]; do eval "$2" && return 0; sleep 0.2; i=$((i + 1)); done; eval "$2"; }
_b7c_l2f2() { LC_ALL=C awk -F'\t' 'NR == 2 { print $2 }' "$1" 2>/dev/null; }   # STAMP: field 2 of line 2, the hash
_b7c_holders() {   # HARNESS PHRASE: the files outside tests/ holding a line with PHRASE, one a line, C-locale order
  ( cd "$1" 2>/dev/null && LC_ALL=C grep -rlF -- "$2" . 2>/dev/null ) | LC_ALL=C awk '!/^\.\/tests\//' | LC_ALL=C sort
}
_b7c_edit() {   # HARNESS PHRASE FROM TO: in the first holder of PHRASE, FROM becomes TO on PHRASE's line, the file rewritten by cat
  local f
  f="$(_b7c_holders "$1" "$2" | LC_ALL=C sed -n 1p)"
  [ -n "$f" ] || return 1
  _P="$2" _F="$3" _T="$4" LC_ALL=C awk 'index($0, ENVIRON["_P"]) { i = index($0, ENVIRON["_F"]); if (i) $0 = substr($0, 1, i - 1) ENVIRON["_T"] substr($0, i + length(ENVIRON["_F"])) } { print }' \
    "$1/$f" > "$B7O/edit.tmp" && cat "$B7O/edit.tmp" > "$1/$f"
}
B7STALE='[!] commission granted, but not over this commissioning.tsv'
B7ENG='[!] commission granted, but not over what this engine says the grant does'

# ---- the run installs, and only on the grant (B14, B15, B20)
_b7c_fix a
_b7c_run a38 nt "$B7R" /dev/null -- "$B7F" commission
_b7c_is "b17 A38: felix commission from no terminal writes a ten-field receipt, installs the low row at user scope and never the high one (control)" \
  "rc=$B7RC $(_b7c_rcpt) $(_b7c_inst)" "rc=0 1 line(s), 10 fields, held or commissioned low:yes high:none" "${B7ERR:0:300}"
_b7c_fix a
_b7c_run a39g nt "$B7R" /dev/null -- "$B7F" autonomy --allow commission
_b7c_run a39 ss "$B7R" /dev/null FELIX_COMMISSION_UNATTENDED=1 -- "$B7F" commission
_b7c_v="$(_b7c_rcpt)"
_b7c_is "b17 A39: under a current grant the unattended run goes from a session: exit 0, the ten-field receipt, the low row installed, not the high (control)" \
  "rc=$B7RC ${_b7c_v%, *} $(_b7c_inst)" "rc=0 1 line(s), 10 fields low:yes high:none" "${B7ERR:0:300}"
_b7c_unatt() {   # TAG: an unattended session run of felix commission; the snapshot around it and the calls made
  rm -f "$B7B/claude.log"; _b7c_snap "$B7O/$1.s1"
  _b7c_run "$1" ss "$B7R" /dev/null FELIX_COMMISSION_UNATTENDED=1 -- "$B7F" commission
  _b7c_snap "$B7O/$1.s2"
  printf 'rc=%s%s; snapshot %s; claude: %s' "$B7RC" "$(_b7c_lacks "$B7ERR" 'no current commission grant' FELIX_COMMISSION_UNATTENDED 'nothing was run or written')" \
    "$(_b7c_same "$B7O/$1.s1" "$B7O/$1.s2")" "$(_b7c_cl)"
}
_b7c_fix a
_b7c_is "b17 A40: with nothing granted the unattended run is refused: exit 1, no current commission grant, FELIX_COMMISSION_UNATTENDED, nothing was run or written; nothing changed" \
  "$(_b7c_unatt a40)" "rc=1; snapshot same; claude: none" "$(head -c 300 "$B7O/a40.err" 2>/dev/null)"
_b7c_run a41g nt "$B7R" /dev/null -- "$B7F" autonomy --allow commission
printf '# b17: a comment line, so the table has changed\n' >> "$B7P/commissioning.tsv"
_b7c_is "b17 A41: with the grant made stale by an edited table, the unattended run is refused the same way" \
  "$(_b7c_unatt a41)" "rc=1; snapshot same; claude: none" "$(head -c 300 "$B7O/a41.err" 2>/dev/null)"
_b7c_run a42g nt "$B7R" /dev/null -- "$B7F" autonomy --allow commission
_b7c_v="$(_b7c_cur)"
_b7c_run a42 ss "$B7R2" /dev/null FELIX_COMMISSION_UNATTENDED=1 -- "$B7F" commission
_b7c_is "b17 A42: with the grant current but the checkout not its own, the unattended run is refused naming the own checkout, and writes no receipt" \
  "grant $_b7c_v; rc=$B7RC$(_b7c_lacks "$B7ERR" 'own checkout' 'nothing was run or written')$(_b7c_there "$B7RCP")" "grant current; rc=1" "${B7ERR:0:300}"
_b7c_fix a
_b7c_run a43g nt "$B7R" /dev/null -- "$B7F" autonomy --allow commission
printf '{"source":"startup","session_id":"b17-ss"}' > "$B7O/ss.json"
_b7c_run a43 ss "$B7R" "$B7O/ss.json" -- "$B7G/harness/hooks/session-start"
_b7c_v="rc=$B7RC"
_b7c_bgran() { [ -f "$B7RCP.bg.log" ] && LC_ALL=C awk -F'\t' '$2 == "ran" { f = 1 } END { exit !f }' "$B7RCP.bg.log"; }
_b7c_lowin() { case "$(_b7c_inst)" in low:yes*) return 0 ;; esac; return 1; }
if _b7c_until 60 _b7c_bgran; then _b7c_v="$_b7c_v bg:ran"; else _b7c_v="$_b7c_v bg:no ran row in 60 s"; fi
_b7c_until 10 _b7c_lowin; _b7c_x="$(_b7c_inst)"
_b7c_is "b17 A43: session start under a current grant still runs the commission: the bg log gains a ran row and the low row is installed (control)" \
  "$_b7c_v ${_b7c_x%% high*}" "rc=0 bg:ran low:yes" "$(cat "$B7RCP.bg.log" 2>/dev/null | tail -3 | tr '\n' ' ')"
_b7c_until 30 '[ ! -d "$B7G/state/discover/.lock" ]'

# ---- C034: the consent says what the run does (B19), and the grant is bound to it (B21-B24)
_b7c_fix a
_b7c_page c0
_b7c_run c1g nt "$B7R" /dev/null -- "$B7F" autonomy --allow commission
_b7c_page c1
printf '# b17: a comment line, so the table has changed\n' >> "$B7P/commissioning.tsv"
_b7c_page c2
_b7c_consent() {   # PAGE FILE: each phrase B19 wants that no line holds whole, and each it forbids that the page holds
  local p
  for p in 'With nobody present, the run installs' 'at user scope' 'nothing marked high is installed' 'enables'; do
    LC_ALL=C grep -qF -- "$p" "$1" 2>/dev/null || printf ' lacks [%s]' "$p"
  done
  for p in 'What it does NOT do is install anything' 'which a person still runs'; do
    ! LC_ALL=C grep -qF -- "$p" "$1" 2>/dev/null || printf ' holds [%s]' "$p"
  done
}
_b7c_is "b17 A44: the status page, with nothing granted, granted and stale, says the run installs at user scope, nothing high, and enables, and not that it installs nothing" \
  "none:$(_b7c_consent "$B7O/c0.out") current:$(_b7c_consent "$B7O/c1.out") stale:$(_b7c_consent "$B7O/c2.out")" "none: current: stale:"
_b7c_v="$(_b7c_holders "$B7G/harness" 'With nobody present, the run installs')"
_b7c_is "b17 A45: exactly one engine file outside tests/ holds a line with the consent sentence" \
  "$(printf '%s' "$_b7c_v" | LC_ALL=C awk 'END { print NR }') file(s)" "1 file(s)" "$(printf '%s' "$_b7c_v" | tr '\n' ' ')"
_b7c_P="$(_b7c_pv)"
if [ -n "$_b7c_P" ]; then printf '%s\n' "$_b7c_P" > "$B7ST"; _b7c_page c3; _b7c_v="$B7CL"; else _b7c_v="P could not be computed"; fi
_b7c_is "b17 A46: a one-line stamp holding P reads granted, but not over what this engine says the grant does" "$_b7c_v" "$B7ENG"
rm -f "$B7B/claude.log"
_b7c_run a47 nt "$B7R" /dev/null FELIX_COMMISSION_UNATTENDED=1 -- "$B7F" commission
_b7c_is "b17 A47: a one-line stamp is stale, and the unattended run on it is refused, no current commission grant, calling no claude" \
  "currency $(_b7c_cur); rc=$B7RC$(_b7c_lacks "$B7ERR" 'no current commission grant'); claude: $(_b7c_cl)" "currency stale; rc=1; claude: none" "${B7ERR:0:300}"
_b7c_run a48g nt "$B7R" /dev/null -- "$B7F" autonomy --allow commission
_b7c_page c4
_b7c_is "b17 A48: a stamp the engine wrote is current, and the commission line begins [x] commission (control)" \
  "currency $(_b7c_cur); ${B7CL:0:14}" "currency current; [x] commission"
cp "$B7ST" "$B7O/stamp.keep" 2>/dev/null
LC_ALL=C awk -F'\t' -v OFS='\t' 'NR == 2 { c = substr($2, 1, 1); $2 = (c == "a" ? "b" : "a") substr($2, 2) } { print }' \
  "$B7O/stamp.keep" > "$B7O/stamp.hash" 2>/dev/null && cat "$B7O/stamp.hash" > "$B7ST"
_b7c_page c5
_b7c_is "b17 A49: that stamp with its hash's first digit changed reads granted, but not over what this engine says the grant does" "$B7CL" "$B7ENG"
[ ! -f "$B7O/stamp.keep" ] || cat "$B7O/stamp.keep" > "$B7ST"
printf '# b17: another comment line\n' >> "$B7P/commissioning.tsv"
_b7c_page c6
_b7c_is "b17 A50: an engine-written stamp over a table edited since reads granted, but not over this commissioning.tsv (control)" "$B7CL" "$B7STALE"
_b7c_ha="$(_b7c_l2f2 "$B7O/stamp.keep")"
_b7c_fix b
_b7c_run a51 nt "$B7R" /dev/null -- "$B7F" autonomy --allow commission
_b7c_hb="$(_b7c_l2f2 "$B7ST")"
if [ -z "$_b7c_ha" ] || [ -z "$_b7c_hb" ]; then _b7c_v="no hash: A [$_b7c_ha] B [$_b7c_hb]"
elif [ "$_b7c_ha" = "$_b7c_hb" ]; then _b7c_v=same; else _b7c_v="A [$_b7c_ha] B [$_b7c_hb]"; fi
_b7c_is "b17 A51: the hash is the same for another project in another home with its own engine copy" "$_b7c_v" "same"
_b7c_use a
_b7c_run a52g nt "$B7R" /dev/null -- "$B7F" autonomy --allow commission
_copy_content "$REAL_HARNESS" "$B7B/e2"
if _b7c_edit "$B7B/e2" 'With nobody present, the run installs' 'With nobody present' 'With nobody at all present'; then
  _b7c_page c7 "$B7B/e2/felix"; _b7c_v="$B7CL"
  _b7c_run a52 nt "$B7R" /dev/null FELIX_COMMISSION_UNATTENDED=1 -- "$B7B/e2/felix" commission
  _b7c_v="$_b7c_v; rc=$B7RC$(_b7c_lacks "$B7ERR" 'no current commission grant')"
else _b7c_v="no file in the copy outside tests/ holds the consent sentence"; fi
_b7c_is "b17 A52: an engine copy whose consent sentence is edited does not take the grant: the page reads [!] over this engine, the unattended run is refused" \
  "$_b7c_v" "$B7ENG; rc=1" "home grant $(_b7c_cur)"
_copy_content "$REAL_HARNESS" "$B7B/e3"
if _b7c_edit "$B7B/e3" 'Tidy removes a file only when every one of these holds' 'Tidy removes' 'Tidy only removes'; then
  _b7c_page c8 "$B7B/e3/felix"; _b7c_v="edited; ${B7CL:0:14}"
else _b7c_v="no file in the copy outside tests/ holds the tidy line"; fi
_b7c_is "b17 A53: an engine copy whose tidy paragraph is edited still takes the grant: the commission line begins [x] commission (control)" \
  "$_b7c_v" "edited; [x] commission"
_b7c_atstamp() {   # TAG KIND: --allow commission over what stands at the stamp's path, both runs under a 20 s watchdog
  local end rc out err what line
  B7WD=20; _b7c_run "$1" nt "$B7R" /dev/null -- "$B7F" autonomy --allow commission
  end="$B7END"; rc="$B7RC"; out="$B7OUT"; err="$B7ERR"
  if [ -p "$B7ST" ]; then what="named pipe"
  elif [ -d "$B7ST" ] && [ ! -L "$B7ST" ]; then
    if [ -z "$(ls -A "$B7ST" 2>/dev/null)" ]; then what="empty directory"; else what="directory holding $(ls -A "$B7ST" | tr '\n' ' ')"; fi
  elif [ -e "$B7ST" ]; then what="something else"; else what=absent; fi
  _b7c_page "$1p"; B7WD=60
  if [ "$B7END" != ended ]; then line="the page did not end in 20 s"
  elif [ -z "$B7CL" ]; then line="no commission line"
  elif [ "${B7CL:0:3}" = "[x]" ]; then line="[x]"; else line="not [x]"; fi
  [ "$rc" -ne 0 ] && rc=nonzero
  printf 'end=%s rc=%s%s%s; %s; line %s' "$end" "$rc" "$(_b7c_lacks "$err" stamp 'not written')" "$(_b7c_holds "$out$err" 'stamped against')" "$what" "$line"
}
rm -f "$B7ST"; mkdir "$B7ST"
_b7c_is "b17 A54: a directory at the stamp's path: --allow commission ends within 20 s, fails, says stamp not written, never stamped against, leaves the directory" \
  "$(_b7c_atstamp a54 dir)" "end=ended rc=nonzero; empty directory; line not [x]" "$(head -c 300 "$B7O/a54.err" 2>/dev/null)"
rm -rf "$B7ST"; mkfifo "$B7ST"
_b7c_is "b17 A55: a named pipe at the stamp's path: the same, and the pipe is left a pipe" \
  "$(_b7c_atstamp a55 fifo)" "end=ended rc=nonzero; named pipe; line not [x]" "$(head -c 300 "$B7O/a55.err" 2>/dev/null)"
rm -f "$B7ST"

# ---- C048: the project tables carry the template's checks (B25, B26)
_b7c_lint() {   # L1|L2|L3 TABLE: the need of each 7-field, non-comment row whose check (field 6) fails the lint, or unreadable
  [ -f "$2" ] && [ -r "$2" ] || { echo unreadable; return 0; }
  LC_ALL=C awk -F'\t' -v l="$1" '
    function l1(s,   k, w, pos, j, i, pre, post) {
      for (k = 1; k <= 3; k++) {
        w = (k == 1) ? "grep" : (k == 2) ? "cut" : "tr"; pos = 0
        while ((j = index(substr(s, pos + 1), w)) > 0) {
          i = pos + j; pos = i
          pre = (i == 1) ? "" : substr(s, i - 1, 1); post = substr(s, i + length(w), 1)
          if ((i == 1 || index(" |(;", pre) > 0) && (post == "" || post == " "))
            if (i < 10 || substr(s, i - 9, 9) != "LC_ALL=C ") return 0
        }
      }
      return 1
    }
    function l2(s,   pos, j, r, c, b) {
      pos = 0
      while ((j = index(substr(s, pos + 1), "$(felix_")) > 0) {
        pos = pos + j; r = substr(s, pos + 2); c = index(r, ")"); b = index(r, "|")
        if (b > 0 && (c == 0 || b < c)) return 0
      }
      return 1
    }
    function l3(need, s) { return (need != "stack" && need != "preflight" && need != "human_steps") || index(s, "unknown") > 0 }
    /^#/ || NF != 7 { next }
    { good = (l == "L1") ? l1($6) : ((l == "L2") ? l2($6) : l3($1, $6)); if (!good) out = out (out == "" ? "" : " ") $1 }
    END { print out }' "$2"
}
_b7c_root="$(cd "$REAL_HARNESS/../.." && pwd)"
_b7c_tabs="$(for _b7c_f in "$_b7c_root"/projects/*/commissioning.tsv; do [ ! -f "$_b7c_f" ] || printf '%s\n' "$_b7c_f"; done | LC_ALL=C sort)"
_b7c_none="no projects/*/commissioning.tsv beside this harness"
_b7c_drift() { ( . "$REAL_HARNESS/lib/resolve.sh"; . "$REAL_HARNESS/lib/commission.sh"; felix_commission_template_drift "$1" "$REAL_HARNESS/templates" ); }
mkdir -p "$TMP/b17c"
if [ -n "$_b7c_tabs" ]; then
  while IFS= read -r _b7c_f; do
    _b7c_p="${_b7c_f%/commissioning.tsv}"
    _b7c_wd 60 "$PWD" /dev/null "$TMP/b17c/drift.out" "$TMP/b17c/drift.err" _b7c_drift "$_b7c_p"
    _b7c_is "b17 A56: felix_commission_template_drift exits 0 and names no check cell for projects/${_b7c_p##*/}" \
      "rc=$B7RC, $(LC_ALL=C awk -F'\t' 'index($2, "check") { n++ } END { print n + 0 }' "$TMP/b17c/drift.out") check row(s)" "rc=0, 0 check row(s)" \
      "$(head -c 300 "$TMP/b17c/drift.out")$(head -c 200 "$TMP/b17c/drift.err")"
  done <<< "$_b7c_tabs"
else skip "b17 A56: felix_commission_template_drift names no check cell of any project table" "$_b7c_none"; fi
_b7c_lints() {   # L N TEXT: lint L over the template and every project table, one assertion each
  local f
  _b7c_is "b17 $2 ($1): $3 in templates/commissioning.tsv" "$(_b7c_lint "$1" "$REAL_HARNESS/templates/commissioning.tsv")" ""
  if [ -z "$_b7c_tabs" ]; then skip "b17 $2 ($1): $3 in every project table" "$_b7c_none"; return 0; fi
  while IFS= read -r f; do
    _b7c_is "b17 $2 ($1): $3 in projects/$(basename "${f%/commissioning.tsv}")/commissioning.tsv" "$(_b7c_lint "$1" "$f")" ""
  done <<< "$_b7c_tabs"
}
_b7c_lints L1 A57 "every grep, cut and tr that starts a command in a check is run under LC_ALL=C"
_b7c_lints L2 A58 'no $(felix_ substitution in a check has a pipe before its first )'
_b7c_lints L3 A59 "the stack, preflight and human_steps checks look for unknown"
printf 'stack\t-\t-\t-\t-\t%s\t6\npreflight\t-\t-\t-\t-\ttrue\t5\n' '[ "$(felix_stack_plan p | grep -c install)" -eq 0 ]' > "$TMP/b17c/lint.tsv"
_b7c_is "b17 A60: the lints have teeth: a planted table fails L1 and L2 on its stack row and L3 on both rows (control)" \
  "L1 [$(_b7c_lint L1 "$TMP/b17c/lint.tsv")] L2 [$(_b7c_lint L2 "$TMP/b17c/lint.tsv")] L3 [$(_b7c_lint L3 "$TMP/b17c/lint.tsv")]" \
  "L1 [stack] L2 [stack] L3 [stack preflight]"
