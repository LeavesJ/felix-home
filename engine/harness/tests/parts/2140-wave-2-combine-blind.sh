# >>> wave-2-combine
printf '\nwave 2 combined: an event is compared with its own last record, and a resume ends the pause it resumed (wave-2-combine.md D1-D3, blind)\n'
# Blind, written on 2026-10-28 from docs/2026-10-24-audit-fixes/wave-2-combine.md alone (section 2, D1-D3, and the
# cases of its section 4), reading the clauses it cites (wave-1-combine.md C1 and C2, b05 B1-B11 and R1-R4, b02
# B15 and B22-B23, b03 B1-B4) for the words it uses. lib/, the felix CLI, hooks/ and bin/ were not read: felix land
# and the trampoline are run as black boxes. Parts 1280, 1680, 1720 and 2120 and tests/lib were read for how their
# fixtures are built. Fixture controls are their own assertions, named so; a case that holds before the fix too
# says in its name that D1 or D2 leaves it unchanged, or that it is a control.
#
# Fixture G is 2120's: the shared land fixture (_lg_build amend), its home on main at origin's main with main's
# entry cached, in the GitHub state (the home's origin reads https://github.com/fixture/lgh.git and insteadOf sends
# fetch to the local origin). A gh wrapper of this part's own takes the fixture's gh's place: it logs every call
# (its kind, then its argv) to $W2CF/s/calls.log, answers api user (fixture-bot), api repos/fixture/lgh (owner
# fixture, a User, push true), issue list (from its issues file), issue create (adding the issue) and workflow run
# (keeping each body= value as $W2CF/s/body.K and printing a run URL; while $W2CF/nowf exists it says gh's
# not-found line and exits 1, as for a repository with no felix-alert.yml), and hands every other call to the
# fixture's gh. Each run carries CLAUDE_CODE_SESSION_ID=s-w2c. A paused tick raises no waiting row (b03 B3), so
# the other kind dispatched after a pause is the trampoline's deploy-owed (1720's A28: a home that does not
# exist), or, in one control, a waiting record written by hand as b05 B7 shapes it. The part puts the origin, the
# gh and the job back at its end.
_lg_build amend
W2CF="$LG/w2c"; rm -rf "$W2CF"; mkdir -p "$W2CF/s"
W2CCWD="$(pwd -P)"
W2CDL='details: felix land --status on the machine that runs the lander'
W2CNC='no checkout holds the gated head'
_fx_git "$LGH" fetch -q origin >/dev/null 2>&1; _fx_git "$LGH" checkout -q main >/dev/null 2>&1
_fx_git "$LGH" reset -q --hard refs/remotes/origin/main >/dev/null 2>&1
W2CV="$(_l3_mainv)"; [ -n "$W2CV" ] && _lg_cache "$W2CV"
[ -n "${LATR:-}" ] || LATR="$LGU/Library/Application Support/felix/land/lgh/tick"
_lg_reset; _lg_land --uninstall; _lg_reset
is "W2C fixture G: the land fixture's home is on main at origin's main, clean, and main's check accepts its cached entry (fixture control)" \
   "$(git -C "$LGH" rev-parse HEAD 2>&1)|$(git -C "$LGH" status --porcelain 2>&1)|$(_l4_acc refs/remotes/origin/main)" "$(git -C "$LGO" rev-parse main 2>&1)||0"

/bin/mv "$LGB/gh" "$W2CF/gh.prev"
sed "s#@W2C@#$W2CF#g" > "$LGB/gh" <<'W2CGHSTUB'
#!/bin/bash
L='@W2C@'; S="$L/s"; mkdir -p "$S"
kind="${1:-} ${2:-}"
if [ "${1:-}" = api ]; then kind="api ?"; for a in "$@"; do case "$a" in user) kind="api user" ;; repos/fixture/lgh) kind="api repos/fixture/lgh" ;; esac; done; fi
line="$kind"; for a in "$@"; do a="${a//$'\n'/ }"; line="$line"$'\t'"${a//$'\t'/ }"; done
printf '%s\n' "$line" >> "$S/calls.log"
step=""
case "$kind" in "api user") step=user ;; "api repos/fixture/lgh") step=repos ;; "issue list") step=list ;;
  "issue create") step=create ;; "workflow run") step=dispatch ;; esac
[ -n "$step" ] || exec "$L/gh.prev" "$@"
jqx=""; bf=""; t=""; prev=""
for a in "$@"; do
  case "$prev" in -q|--jq) jqx="$a" ;; -F|--body-file) bf="$a" ;; -t|--title) t="$a" ;; esac
  case "$a" in --jq=*) jqx="${a#--jq=}" ;; --body-file=*) bf="${a#--body-file=}" ;; --title=*) t="${a#--title=}" ;; esac
  prev="$a"
done
out() { if [ -n "$jqx" ] && command -v jq >/dev/null 2>&1; then jq -r "$jqx"; else cat; fi; }
case "$step" in
  user) printf '{"login":"fixture-bot"}\n' | out ;;
  repos) printf '{"full_name":"fixture/lgh","owner":{"login":"fixture","type":"User"},"permissions":{"admin":false,"maintain":false,"push":true}}\n' | out ;;
  list) { printf '['; s=""
      if [ -f "$L/issues.tsv" ]; then while IFS=$'\t' read -r n ti au; do
        printf '%s{"number":%s,"title":"%s","author":{"login":"%s"},"state":"OPEN"}' "$s" "$n" "$ti" "$au"; s=","; done < "$L/issues.tsv"; fi
      printf ']\n'; } | out ;;
  create) [ "$bf" = - ] && cat > /dev/null
    n=1; [ -f "$L/issues.tsv" ] && n=$(( $(awk 'END { print NR }' "$L/issues.tsv") + 1 ))
    printf '%s\t%s\t%s\n' "$n" "$t" fixture-bot >> "$L/issues.tsv"
    printf 'https://github.com/fixture/lgh/issues/%s\n' "$n" ;;
  dispatch) k=0; [ -f "$S/k" ] && k="$(cat "$S/k")"; k=$((k+1)); printf '%s\n' "$k" > "$S/k"
    pv=""; for a in "$@"; do case "$pv" in -f|-F|--field|--raw-field) case "$a" in body=*) printf '%s' "${a#body=}" > "$S/body.$k" ;; esac ;; esac; pv="$a"; done
    if [ -f "$L/nowf" ]; then printf 'could not find any workflows named felix-alert.yml\n' >&2; exit 1; fi
    printf 'Created workflow_dispatch event for felix-alert.yml at main\n' >&2
    printf 'https://github.com/fixture/lgh/actions/runs/%s\n' "$((k + 900))" ;;
esac
exit 0
W2CGHSTUB
chmod +x "$LGB/gh"

# ---------------------------------------------------------------- helpers ---
_w2c_on() { _fx_git "$LGH" config remote.origin.url https://github.com/fixture/lgh.git >/dev/null 2>&1
            _fx_git "$LGH" config "url.$LGO.insteadOf" https://github.com/fixture/lgh.git >/dev/null 2>&1; }
_w2c_off() { _fx_git "$LGH" config remote.origin.url "$LGO" >/dev/null 2>&1; _fx_git "$LGH" config --unset-all "url.$LGO.insteadOf" >/dev/null 2>&1; }
_w2c_clear() { rm -rf "$W2CF/s"; mkdir -p "$W2CF/s"; }   # this step's calls and bodies emptied
_w2c_reset() {   # land state, issues, the missing-workflow switch and calls emptied, in the GitHub state
  _lg_reset; rm -f "$W2CF/issues.tsv" "$W2CF/nowf"; _w2c_clear; _w2c_on
  LGX=(GIT_ALLOW_PROTOCOL=file CLAUDE_CODE_SESSION_ID=s-w2c)
}
_w2c_nk() { if [ -f "$W2CF/s/calls.log" ]; then LC_ALL=C awk -F'\t' -v r="$1" '$1 ~ r { n++ } END { print n + 0 }' "$W2CF/s/calls.log"; else echo 0; fi; }   # KIND-REGEX -> calls this step
_w2c_n() { if [ -f "$LAND/alerts.tsv" ]; then LC_ALL=C awk 'END { print NR }' "$LAND/alerts.tsv"; else echo 0; fi; }   # -> records
_w2c_f() { [ -f "$LAND/alerts.tsv" ] && LC_ALL=C awk -F'\t' -v r="$1" -v k="$2" 'NR == r + 0 { v = $k } END { printf "%s", v }' "$LAND/alerts.tsv"; }   # ROW FIELD
_w2c_recs() { [ -f "$LAND/alerts.tsv" ] && LC_ALL=C awk -F'\t' '{ printf "%s %s %s;", $2, $3, $4 }' "$LAND/alerts.tsv"; }   # -> each record's state, kind and PR, in order
_w2c_srt() {   # -> each record's state, kind, PR and field 8, sorted, each followed by ;
  [ -f "$LAND/alerts.tsv" ] || return 0
  LC_ALL=C awk -F'\t' '{ print $2 " " $3 " " $4 " " $8 }' "$LAND/alerts.tsv" | LC_ALL=C sort | LC_ALL=C awk '{ printf "%s;", $0 }'
}
_w2c_lines() { [ -f "${1:-/nonexistent}" ] && LC_ALL=C awk '{ printf "%s%s", s, $0; s = "|" }' "$1"; }   # FILE -> its lines joined by |
_w2c_l1s() {   # -> each dispatch BODY's line 1 this step, sorted, each followed by |
  local b; for b in "$W2CF/s"/body.*; do [ -f "$b" ] && sed -n 1p "$b"; done | LC_ALL=C sort | LC_ALL=C awk '{ printf "%s|", $0 }'
}
_w2c_osa() { _lg_logs osa | LC_ALL=C grep -c "with title \"Felix: $1" ; }   # TITLE -> banners sent with it
_w2c_starts() { case "$1" in "$2"*) printf '%s' "$3" ;; *) printf '[%s]' "$1" ;; esac; }   # TEXT PREFIX TAG -> TAG, or the text
_w2c_t() { local t; t="$(( $(date +%s) - $1 ))"; date -u -r "$t" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$t" +%Y-%m-%dT%H:%M:%SZ; }   # SECONDS-AGO -> UTC ISO
_w2c_minus1() {   # UTC-ISO -> the second before it, as UTC ISO (nothing when it cannot be read)
  local e; e="$(date -j -u -f '%Y-%m-%dT%H:%M:%SZ' "$1" +%s 2>/dev/null || date -u -d "$1" +%s 2>/dev/null)"
  case "$e" in ''|*[!0123456789]*) return 0 ;; esac
  e=$((e - 1)); date -u -r "$e" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$e" +%Y-%m-%dT%H:%M:%SZ
}
_w2c_row() { mkdir -p "$LAND"; printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$@" >> "$LAND/ledger.tsv"; }   # TIME EVENT PR HEAD WORKTREE WALL DETAIL
_w2c_rec() { mkdir -p "$LAND"; printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$@" >> "$LAND/alerts.tsv"; }   # STATE KIND PR ISSUE RUN NOTE DETAIL -> one record, timed now (b05 B7)
_w2c_age() {   # the ledger's rows a year older, so the newest paused row is past its hour (1720's reading); resumed rows move too
  [ -f "$LAND/ledger.tsv" ] || return 0
  LC_ALL=C awk -F'\t' -v OFS='\t' -v y="$(date -u +%Y)" '{ if (index($1, y)) sub(y, y - 1, $1); print }' "$LAND/ledger.tsv" > "$LAND/ledger.aged" \
    && /bin/mv "$LAND/ledger.aged" "$LAND/ledger.tsv"
}
_w2c_back() {   # KIND SECONDS-AGO -> every ledger row of that kind moved to that many seconds ago
  [ -f "$LAND/ledger.tsv" ] || return 0
  LC_ALL=C awk -F'\t' -v OFS='\t' -v k="$1" -v t="$(_w2c_t "$2")" '$2 == k { $1 = t } { print }' "$LAND/ledger.tsv" > "$LAND/ledger.w2c" \
    && /bin/mv "$LAND/ledger.w2c" "$LAND/ledger.tsv"
}
_w2c_wait() {   # PR... -> a fresh ledger in which each PR has waited on a session for five hours; gh lists them, green
  local n; local -a p; p=()
  mkdir -p "$LAND"; : > "$LAND/ledger.tsv"; W2CT0="$(_w2c_t 18000)"
  for n in "$@"; do _w2c_row "$W2CT0" session "$n" "$(_lg_sha "$n")" - 1 "$W2CNC"; p[${#p[@]}]="$(_lg_pr "$n")"; done
  _lg_prs "${p[@]}"; _lg_green "$@"
}
_w2c_tramp() {   # -> the trampoline as launchd runs it, with a home that does not exist (1720's A28); status in LARC
  ( cd "$TMP/cwd" 2>/dev/null || cd "$LG" || exit 97
    exec env -i HOME="$LGU" FELIX_HOME_DIR="$W2CF/no-home" PATH="$LGB:$PATH" GIT_CEILING_DIRECTORIES="${GIT_CEILING_DIRECTORIES-}" \
      "$LATR" ) > "$LG/out.tramp" 2>&1
  LARC=$?
}

_w2c_reset
W2CW1="$(PATH="$LGB:$PATH" gh workflow run felix-alert.yml --repo github.com/fixture/lgh -f issue=1 -f body="$(printf 'one\ntwo')" 2>/dev/null; echo "rc=$?")"
: > "$W2CF/nowf"; W2CW2="$(PATH="$LGB:$PATH" gh workflow run felix-alert.yml --repo github.com/fixture/lgh -f issue=1 -f body=b 2>&1 >/dev/null; echo "rc=$?")"
is "W2C fixture G: the gh wrapper answers workflow run with a run URL and keeps BODY by line, and with nowf says gh's not-found line and exits 1 (fixture control)" \
   "$(printf '%s' "$W2CW1" | tr '\n' ' ')|$(_w2c_lines "$W2CF/s/body.1")|$(printf '%s' "$W2CW2" | tr '\n' ' ')" \
   "https://github.com/fixture/lgh/actions/runs/901 rc=0|one|two|could not find any workflows named felix-alert.yml rc=1"

# ------------------------------------------------------- D1, two pull requests ---
# L1's case: one tick raises waiting for 31 and 32, and the next day's rows for the same two, with the same
# details, are each compared with their own pull request's record, never with the other's.
_w2c_reset; _w2c_wait 31 32; _lg_land --tick
W2CD31="$(_lg_f waiting 31 7)"; W2CD32="$(_lg_f waiting 32 7)"; W2CWP="waits on a session since $W2CT0: session: "
is "W2C D1a (fixture control): a tick over green PRs 31 and 32, which no checkout holds and whose session waits are five hours old, exits 0 and writes one waiting row for each, as b03 B1 says" \
   "$LGRC|$(_lg_n waiting 31) $(_lg_n waiting 32)|$(_w2c_starts "$W2CD31" "$W2CWP$W2CNC" 31-waits)|$(_w2c_starts "$W2CD32" "$W2CWP" 32-waits)" \
   "0|1 1|31-waits|32-waits"
is "W2C D1a1 (unchanged by D1: each event's first raise is attempted): that tick dispatches each waiting row once, two workflow runs whose BODYs begin @fixture Felix land: waiting #31 and #32, and two records, dispatched, waiting, one per pull request, field 8 its row's detail" \
   "$(_w2c_nk '^workflow run')|$(_w2c_l1s)|$(_w2c_srt)" \
   "2|@fixture Felix land: waiting #31|@fixture Felix land: waiting #32||dispatched waiting 31 $W2CD31;dispatched waiting 32 $W2CD32;"
_w2c_back waiting 90000; _w2c_clear; _lg_land --tick
is "W2C D1a2: with both waiting rows moved 25 hours back, the next tick writes each again with the same detail, and each is a repeat of its own pull request's dispatched record, whatever the other's: no api, issue or workflow call and still two records" \
   "$(_lg_n waiting 31) $(_lg_n waiting 32)|$([ "$(_lg_f waiting 31 7)" = "$W2CD31" ] && echo same || echo changed) $([ "$(_lg_f waiting 32 7)" = "$W2CD32" ] && echo same || echo changed)|$(_w2c_nk '^(api|issue|workflow) ')|$(_w2c_n)" \
   "2 2|same same|0|2"

# --------------------------------------------- D1, the hourly pause; D3, the trampoline ---
# L1's second case. --install writes the trampoline and alerts.repo (b05 B11) and alerts nothing (C2); the
# trampoline with a home that does not exist raises deploy-owed, a first row whenever the ledger's last row is of
# another kind (b02 B15). --pause with a second reason while paused is a new event (C1), dispatched between the
# trampoline's two deploy-owed rows.
_w2c_reset; _lg_land --install; W2CI="$LGRC"; _lg_land --pause "W2C held"
_w2c_tramp; W2CDO="$(_lg_f deploy-owed "" 7)"
is "W2C D1b (fixture control): --install exits 0; --pause R is dispatched and recorded paused with field 8 R; then the trampoline with a home that does not exist exits 1, writes one deploy-owed row and dispatches it, recorded after the pause's" \
   "$W2CI|$(_w2c_nk '^workflow run')|$(_w2c_recs)|$(_w2c_f 1 8)|$LARC|$(_lg_n deploy-owed)|$([ -n "$W2CDO" ] && echo detail || echo no-detail)" \
   "0|2|dispatched paused -;dispatched deploy-owed -;|W2C held|1|1|detail"
_w2c_age; _w2c_clear; _lg_land --tick
is "W2C D1b: with the ledger aged past the hour, the tick's hourly paused row R is a repeat of the pause's own dispatched record although the trampoline's deploy-owed was dispatched after it: one more paused row and Felix: paused banner, no gh call, still two records" \
   "$(_lg_n paused)|$(_lg_f paused - 7)|$(_w2c_osa paused)|$(_w2c_nk .)|$(_w2c_n)" "2|W2C held|2|0|2"
# Counted from the records before each step, so neither depends on what D1b's tick did.
W2CN="$(_w2c_n)"; _w2c_clear; _lg_land --pause "W2C held again"
is "W2C D1c (fixture control): --pause with a second reason while paused is a new event: one workflow run and one more record, the newest, dispatched, paused, field 8 that reason" \
   "$(_w2c_nk '^workflow run')|+$(( $(_w2c_n) - W2CN ))|$(_w2c_f "$(_w2c_n)" 2) $(_w2c_f "$(_w2c_n)" 3) $(_w2c_f "$(_w2c_n)" 4)|$(_w2c_f "$(_w2c_n)" 8)" "1|+1|dispatched paused -|W2C held again"
W2CN="$(_w2c_n)"; _w2c_clear; _w2c_tramp
is "W2C D1c (D3): the trampoline's deploy-owed raised again after that paused row, with the same detail, is a repeat of its own dispatched record although a paused record was dispatched after it: exit 1, a second deploy-owed row, no gh call, no new record" \
   "$LARC|$(_lg_n deploy-owed)|$([ "$(_lg_f deploy-owed "" 7)" = "$W2CDO" ] && echo same || echo changed)|$(_w2c_nk .)|+$(( $(_w2c_n) - W2CN ))" "1|2|same|0|+0"
_lg_land --uninstall

# ------------------------------------------------------------- D1, the control ---
# The newest record of the paused event is no-alert-workflow, and a waiting record, written by hand a second
# later as b05 B7 shapes it, is dispatched after it: the event is attempted again (R4), and R4's line 4 counts only
# what follows the newest dispatched record of any kind, so it has none.
_w2c_reset; : > "$W2CF/nowf"; _lg_land --pause "W2C no workflow"; W2CR1="$(sed -n 1p "$LAND/alerts.tsv" 2>/dev/null)"
sleep 1; _w2c_rec dispatched waiting 31 'fixture/lgh#1' 'https://github.com/fixture/lgh/actions/runs/990' \
  'through felix-alert.yml mentioning @fixture' "waits on a session since $(_w2c_t 18000): session: $W2CNC"
rm -f "$W2CF/nowf"; _w2c_age; _w2c_clear; _lg_land --tick
is "W2C D1d (control): a paused event whose newest same-kind record is no-alert-workflow is attempted again when the hourly row raises it: one workflow run, the third record dispatched, paused, field 8 R, and the first, no-alert-workflow, unchanged" \
   "$(_w2c_nk '^workflow run')|$(_w2c_recs)|$(_w2c_f 3 8)|$(if [ -n "$W2CR1" ] && [ "$(sed -n 1p "$LAND/alerts.tsv" 2>/dev/null)" = "$W2CR1" ]; then echo first-unchanged; else echo first-changed; fi)" \
   "1|no-alert-workflow paused -;dispatched waiting 31;dispatched paused -;|W2C no workflow|first-unchanged"
is "W2C D1d2 (unchanged by D1, R4's line 4): its BODY has no line 4, since N counts only the records after the newest dispatched record of any kind, the waiting one: @fixture Felix land: paused, empty, the paused sentence, the details line" \
   "$(_w2c_lines "$W2CF/s/body.1")" "@fixture Felix land: paused||Landing is paused until felix land --resume.|$W2CDL"

# ------------------------------------------------------- D1 and D2, a waiting row ---
_w2c_reset; _w2c_wait 31; _lg_land --tick; W2CD31E="$(_lg_f waiting 31 7)"
_lg_land --pause "W2C between"; _lg_land --resume
is "W2C D1e (fixture control): a tick dispatches 31's waiting row, --pause R is then dispatched, and --resume writes its resumed row: two records in that order, dispatched waiting 31 and dispatched paused -, and one resumed row" \
   "$(_w2c_nk '^workflow run')|$(_w2c_recs)|$(_lg_n resumed)" "2|dispatched waiting 31;dispatched paused -;|1"
_w2c_back waiting 90000; _w2c_clear; _lg_land --tick
is "W2C D1e: with the waiting row moved 25 hours back, the tick after the resume writes it again with the same detail, a repeat of 31's own dispatched record: the paused record dispatched since does not count (D1), and a resume ends only a pause (D2): no api, issue or workflow call, still two records" \
   "$(_lg_n waiting 31)|$([ "$(_lg_f waiting 31 7)" = "$W2CD31E" ] && echo same || echo changed)|$(_w2c_nk '^(api|issue|workflow) ')|$(_w2c_n)" "2|same|0|2"

# ------------------------------------------------------------- D2, a resume ends it ---
# L2's case. Nothing ages the ledger between the resume and the second pause; the ledger is aged after it, which
# moves the resumed row a year back too, so the tick's hourly row meets only the second pause's dispatch.
_w2c_reset; _lg_land --pause "W2C again"; _lg_land --resume; _lg_land --pause "W2C again"
is "W2C D2a: --pause R, --resume, --pause R: the resume ended the first pause, so the second is said as well: two workflow runs and two records, both dispatched, paused, field 8 R" \
   "$(_w2c_nk '^workflow run')|$(_w2c_srt)" "2|dispatched paused - W2C again;dispatched paused - W2C again;"
W2CN="$(_w2c_n)"; _w2c_age; _w2c_clear; _lg_land --tick
is "W2C D2a2 (unchanged by D2: an hourly row after a dispatch is a repeat): with the ledger then aged past the hour, the resumed row with it, the tick's hourly paused row R repeats the second pause's dispatch: a third paused row, no gh call, no new record" \
   "$(_lg_n paused)|$(_lg_f paused - 7)|$(_w2c_nk .)|$(_w2c_n)" "3|W2C again|0|$W2CN"

# ------------------------------------------------------------ D2, one second ---
# No command resumes within the second a dispatch is recorded, so here the resumed row is written by hand after
# the ledger is aged (so its time stays as written): in the record's own second, then, as a control, the second
# before it.
_w2c_reset; _lg_land --pause "W2C same second"; W2CTS="$(_w2c_f 1 1)"
_w2c_age; _w2c_row "$W2CTS" resumed - - - 0 "the pause read: W2C same second; by session s-w2c"; _w2c_clear; _lg_land --tick
is "W2C D2b: a resumed row whose time is the very second of the pause's dispatched record ends that pause (the error is one extra alert, never a silent pause): the tick's hourly paused row R is attempted and dispatched, a second record, paused, field 8 R" \
   "$([ -n "$W2CTS" ] && echo timed || echo untimed)|$(_lg_n paused)|$(_w2c_nk '^workflow run')|$(_w2c_n)|$(_w2c_f 2 2) $(_w2c_f 2 3) $(_w2c_f 2 4)|$(_w2c_f 2 8)" \
   "timed|2|1|2|dispatched paused -|W2C same second"
_w2c_reset; _lg_land --pause "W2C second before"; W2CTS="$(_w2c_f 1 1)"; W2CTB="$(_w2c_minus1 "$W2CTS")"
_w2c_age; _w2c_row "$W2CTB" resumed - - - 0 "the pause read: W2C second before; by session s-w2c"; _w2c_clear; _lg_land --tick
is "W2C D2c (control): a resumed row one second before the pause's dispatched record does not end it: the tick's hourly paused row R is a repeat, no gh call, still one record" \
   "$(if [ -n "$W2CTB" ] && [ "$W2CTB" \< "$W2CTS" ]; then echo earlier; else printf '[%s|%s]' "$W2CTB" "$W2CTS"; fi)|$(_lg_n paused)|$(_w2c_nk .)|$(_w2c_n)" \
   "earlier|2|0|1"

# --------------------------------------------------------------- G undone ---
_w2c_off; /bin/mv "$W2CF/gh.prev" "$LGB/gh"; _lg_reset; _lg_land --uninstall; _lg_reset; rm -rf "$W2CF"
is "W2C fixture G: the part put the land fixture back: origin the local path, no insteadOf, the home clean, the fixture's gh in place, and the working directory where it was (fixture control)" \
   "$(git -C "$LGH" config --get remote.origin.url 2>&1)|$(git -C "$LGH" config --get-regexp '^url\.' 2>&1)|$(git -C "$LGH" status --porcelain 2>&1)|$(LC_ALL=C grep -c 'amend/gh.1280' "$LGB/gh" 2>&1)|$(pwd -P)" \
   "$LGO|||1|$W2CCWD"
# <<< wave-2-combine
