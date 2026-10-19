printf '\nFelix refuses a pattern kill (blind)\n'
# Written blind, on 2026-10-19, from the contract alone (audits/2026-10-19-
# pattern-kill-deny/contract.md, C1 to C5; the founder decided it that day), before
# the row existed and without reading the pattern of any row in any deny.tsv. The
# decision: every session and subagent gets an immediate refusal for a pattern
# kill, with the reason and the one allowed way. Twice, on 2026-09-25 and
# 2026-10-18, an agent killed by pattern although its prompt forbade it, and the
# pattern reached other sessions' runs on the same machine.
#
# The row is read out of projects/felix/deny.tsv as it ships, by its reason (C5:
# it begins `a pattern kill`, and exactly one row there does), and put alone into
# a fixture project's deny.tsv, so each verdict below is the shipped row's and not
# a copy of it. It keeps all its columns: the contract gives it no checkout scope,
# and a fourth column is asserted absent below, not dropped here.
#
# Each case is a command as the shell would be handed it, one a line, with <NL> for
# a line break; the payload is that command as the hook receives it, escaped as JSON
# escapes it (a quote, a backslash, a line break). The assertion's name is the
# command: `pattern kill refused: <command>` or `pattern kill allowed: <command>`.
# Every name is emitted on every run, whatever the hook answered. A refused case
# wants exit 2 and the row's whole reason on stderr; an allowed case wants exit 0.
#
# Readings, where the contract leaves room. The wrappers of C1 and the positions of
# C1 are tried on pkill and killall; C2 is tried bare, behind `true &&`, and with
# the substitution double-quoted, which still runs it. `pkill -P 1234` is refused:
# C1 says any options, and the engine's own tests/parts/0350 line that does it sits
# in a script body, which the hook does not judge. `kill $(cat pidfile)` and
# `kill $(jobs -p)` are allowed, as the contract's last section says. What the
# reason must say is asserted by plain words only: `session` for the harm, `pid` for
# the way, and `$!` or `pidfile` for where the pid comes from; the wording of the
# rest (STOP then KILL the root, then its tree by pid) is the row's.
#
# Every part runs alone: this one makes its own checkout, bound to the widget
# project by marker, and relies on nothing an earlier part left but what the
# prelude builds (FROOT, TMP, REAL_HARNESS, _pre, _fx_cd, is, has, skip).

# ---- the row, found by its reason
_pk_tab="$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix/deny.tsv"
_pk_row=""; _pk_n=0
if [ -f "$_pk_tab" ]; then
  _pk_row="$(LC_ALL=C awk -F'\t' '/^#/ { next } index($3, "a pattern kill") == 1' "$_pk_tab")"
  _pk_n="$(LC_ALL=C awk -F'\t' '/^#/ { next } index($3, "a pattern kill") == 1 { n++ } END { print n + 0 }' "$_pk_tab")"
fi
# A field of the first such row, or its field count: _pk_f 1, _pk_f 3, _pk_f NF.
_pk_f() { printf '%s\n' "$_pk_row" | LC_ALL=C awk -F'\t' -v k="$1" 'NR == 1 { print (k == "NF" ? NF : $k) }'; }
_pk_tool="$(_pk_f 1)"; _pk_nf="$(_pk_f NF)"; _pk_reason="$(_pk_f 3)"
_pk_tabs="$(printf '%s' "$_pk_row" | LC_ALL=C tr -cd '\t' | wc -c | tr -d ' ')"
_pk_len="$(printf '%s' "$_pk_reason" | wc -c | tr -d ' ')"
_pk_odd="$(printf '%s' "$_pk_reason" | LC_ALL=C tr -d ' -~' | wc -c | tr -d ' ')"
_pk_low="$(printf '%s' "$_pk_reason" | LC_ALL=C tr '[:upper:]' '[:lower:]')"

# One assertion about the row, or a skip, with the same name either way.
_pk_row_is() {   # name got want
  if [ -f "$_pk_tab" ]; then is "$1" "$2" "$3"
  else skip "$1" "no projects/felix/deny.tsv beside this harness"; fi
}
_pk_row_is "pattern kill row: exactly one row in projects/felix/deny.tsv has a reason beginning a pattern kill" "$_pk_n" "1"
_pk_row_is "pattern kill row: it is a Bash row" "$_pk_tool" "Bash"
_pk_row_is "pattern kill row: it has three columns, so no checkout scope" "$_pk_nf" "3"
_pk_row_is "pattern kill row: it holds two tabs, so the reason holds none" "$_pk_tabs" "2"
if [ "$_pk_len" -gt 0 ] && [ "$_pk_odd" -eq 0 ]; then _pk_v="printable ASCII"
else _pk_v="$_pk_odd of $_pk_len bytes are not printable ASCII"; fi
_pk_row_is "pattern kill row: the reason is printable ASCII" "$_pk_v" "printable ASCII"
if [ "$_pk_len" -gt 0 ] && [ "$_pk_len" -lt 200 ]; then _pk_v="under 200 bytes"
else _pk_v="$_pk_len bytes"; fi
_pk_row_is "pattern kill row: the reason is under 200 bytes" "$_pk_v" "under 200 bytes"
case "$_pk_low" in *session*) _pk_v="names sessions" ;; *) _pk_v="[$_pk_reason] does not name sessions" ;; esac
_pk_row_is "pattern kill row: the reason names the harm, other sessions" "$_pk_v" "names sessions"
case "$_pk_low" in *pid*) _pk_v="names the pid" ;; *) _pk_v="[$_pk_reason] does not name the pid" ;; esac
_pk_row_is "pattern kill row: the reason names the way, a pid" "$_pk_v" "names the pid"
case "$_pk_low" in
  *'$!'*|*pidfile*|*'pid file'*) _pk_v="says where the pid comes from" ;;
  *) _pk_v="[$_pk_reason] does not say where the pid comes from" ;;
esac
_pk_row_is "pattern kill row: the reason says the pid comes from \$! or a pidfile" "$_pk_v" "says where the pid comes from"

# ---- the fixture: the row alone in the widget project's table, in a checkout of its own
mkdir -p "$FROOT/projects/widget"
if [ -n "$_pk_row" ]; then printf '%s\n' "$_pk_row" > "$FROOT/projects/widget/deny.tsv"
else : > "$FROOT/projects/widget/deny.tsv"; fi
_pk_repo="$TMP/pattern-kill-repo"
mkdir -p "$_pk_repo"
( _fx_cd "$_pk_repo" && git init -q -b main )
_pk_repo="$(cd "$_pk_repo" && pwd -P)"
printf 'widget\n' > "$_pk_repo/.felix"

# The payload the hook receives for a command: <NL> is a line break, and a quote and
# a backslash are escaped as JSON escapes them.
_pk_json() {
  printf '%s' "$1" | LC_ALL=C awk '
    function esc(s,   i, c, o) {
      o = ""
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == "\\") o = o "\\\\"
        else if (c == "\"") o = o "\\\""
        else o = o c
      }
      return o
    }
    { o = esc($0)
      while ((p = index(o, "<NL>")) > 0) o = substr(o, 1, p - 1) "\\n" substr(o, p + 4)
      printf "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"%s\"}}", o }'
}
# _pk_cases 2 (refused) or 0 (allowed); stdin is the commands, one a line.
_pk_cases() {
  local want="$1" word _c _j _rc _got
  if [ "$want" = 2 ]; then word=refused; else word=allowed; fi
  while IFS= read -r _c; do
    [ -n "$_c" ] || continue
    if [ ! -f "$_pk_tab" ]; then
      skip "pattern kill $word: $_c" "no projects/felix/deny.tsv beside this harness"; continue
    fi
    _j="$(_pk_json "$_c")"
    ( cd "$_pk_repo" && _pre "$_j" ); _rc=$?
    _got="$_rc"
    if [ "$_rc" = 2 ]; then
      case "$(cat "$FROOT/.deny-err")" in *"$_pk_reason"*) ;; *) _got="2 without the row's reason" ;; esac
    fi
    is "pattern kill $word: $_c" "$_got" "$want"
  done
}

printf '\npattern kill: pkill and killall are refused, with their options and paths\n'
_pk_cases 2 <<'J'
pkill -f 'engine/harness/tests/run'
pkill -f 'sleep 3'
pkill node
pkill -9 -x python
pkill -u 501 node
pkill -P 1234
pkill -TERM -f "next dev"
killall node
killall -9 Safari
killall -q -s TERM sleep
/usr/bin/pkill -f x
/opt/homebrew/bin/pkill -f x
./tools/pkill -f x
/usr/bin/killall node
/usr/local/bin/killall -9 Dock
J

printf '\npattern kill: and behind a wrapper\n'
_pk_cases 2 <<'J'
sudo pkill -f x
sudo killall node
env A=1 pkill -f x
env A=1 B=2 killall node
nohup pkill -f x
command pkill -f x
exec pkill -f x
nice -n 5 pkill -f x
nice pkill -f x
timeout 5 pkill -f x
echo node | xargs pkill
printf 'a\nb\n' | xargs -n 1 killall
sudo nohup pkill -f x
J

printf '\npattern kill: and wherever a command can start\n'
_pk_cases 2 <<'J'
ls; pkill -f x
ls;pkill -f x
true && pkill -f x
false || pkill -f x
echo x | pkill -f y
sleep 1 & pkill -f x
(pkill -f x)
echo $(pkill -f x)
echo "$(pkill -f x)"
echo `pkill -f x`
{ pkill -f x; }
echo hi<NL>pkill -f x
if true; then pkill -f x; fi
for i in 1 2; do pkill -f x; done
if false; then :; else pkill -f x; fi
! pkill -f x
time pkill -f x
J

printf '\npattern kill: a kill fed by a pattern search is refused\n'
_pk_cases 2 <<'J'
kill $(pgrep -f x)
kill `pgrep x`
kill -9 $(pgrep -f 'a b')
kill -TERM $(pgrep -d' ' x)
kill -9 "$(pgrep -f x)"
true && kill $(pgrep -f x)
pgrep -f x | xargs kill
pgrep x | xargs -r kill -9
pgrep -f x | xargs -n 1 kill
pgrep -f 'a b' | xargs -r -n1 kill -TERM
J

printf '\npattern kill: a kill of a pid you hold is allowed, and so is looking\n'
_pk_cases 0 <<'J'
kill 1234
kill -STOP 1234; kill -KILL 1234
kill -0 "$pid"
kill -TERM "$(cat run.pid)"
kill $!
kill -- -1234
kill %1
kill -l
kill $(cat pidfile)
kill $(jobs -p)
sleep 30 & kill $!
pgrep -fl tests/run
pgrep -P 1234
ps -axo pid,command | grep tests/run
p=$(pgrep -f x); echo "$p"
pgrep -f x | wc -l
pgrep -f x | xargs ps -o pid,command -p
J

printf '\npattern kill: text that names a pattern kill is allowed\n'
_pk_cases 0 <<'J'
git commit -m "never pkill -f"
echo 'no killall'
echo pkill
echo hi; echo pkill -f x
grep -n pkill lib/x.sh
printf '%s\n' "pkill"
ps -axo pid,command | grep pkill
sed -n '/killall/p' notes.md
git log --grep=killall
man pkill
which killall
# pkill -f x
ls # pkill -f x
git commit -m "title<NL><NL>pkill -f is refused now<NL>killall too"
echo "first<NL>pkill -f x"
for c in 'pkill -f x' 'ls'; do echo "$c"; done
J

printf '\npattern kill: a here-document, and a commit message, that names one is data\n'
_pk_cases 0 <<'J'
git commit -m "$(cat <<'EOF'<NL>fix: never pkill -f here<NL>EOF<NL>)"
git commit -m "$(cat <<'EOF'<NL>docs: kill by pid, not killall<NL><NL>pkill -f reaches other sessions<NL>EOF<NL>)"
git commit -F - <<'EOF'<NL>never pkill -f<NL>EOF
cat <<'EOF'<NL>killall node<NL>EOF
cat > notes.md <<'EOF'<NL>pkill -f x<NL>EOF
cat > notes.md <<'EOF'<NL>use:<NL>pkill -f x<NL>killall node<NL>EOF<NL>ls
J

printf '\npattern kill: words that merely contain the letters are allowed\n'
_pk_cases 0 <<'J'
mypkill --run
pkiller x
/usr/bin/mypkill -f x
./pkill-notes/run.sh
cat killall_report.txt
cat docs/killall.md
ls pkill-notes/
J

rm -f "$FROOT/projects/widget/deny.tsv" "$FROOT/.deny-err"
