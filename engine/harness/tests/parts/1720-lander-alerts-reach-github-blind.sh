# >>> lander-alerts-reach-github
printf '\nthe lander tells the founder through one standing issue on the governed repository (audit b05: C018; B1-B13, blind)\n'
# Blind, written on 2026-10-24 from docs/2026-10-24-audit-fixes/b05-lander-install-guard-and-off-mac-notifie.md
# alone (section 4, A14-A35, fixture F2). lib/green-tick.sh, lib/green-install.sh, lib/status.sh, the notifier
# and the felix CLI were not read; the CLI's line that sources lib/green-tick.sh is found by 1285's pattern only.
# One assertion per contract item, each a composite of what the item names; fixture controls are their own.
#
# F2 is the shared land fixture (_lg_build amend), whose origin is a local path. The GitHub state points the
# home's origin at https://github.com/fixture/lgh.git and rewrites that URL back to the local origin with
# insteadOf, so fetch stays offline; each run then carries GIT_ALLOW_PROTOCOL=file, GH_HOST=evil.example and
# GH_REPO=someone/else. A gh wrapper takes the fixture's gh's place for the part: it logs every call (its kind,
# whether GH_HOST and GH_REPO are set, GH_PROMPT_DISABLED, the argv) to this scenario's log and to the part's,
# keeps the standard input of issue create and issue comment, answers user, repos/fixture/lgh, issue list,
# issue create and issue comment as the contract's F2 says (a control file per step makes it exit a status or
# hang), and hands every other call to the fixture's gh. The part puts all of it back at its end.
_lg_build amend
L20="$LG/alerts20"; rm -rf "$L20"; mkdir -p "$L20/s" "$L20/ctl" "$L20/gitbin" "$L20/noproj" "$L20/nohome/projects"
L20T="$(printf '\t')"; L20CWD="$(pwd -P)"; L20PJ="$LGH/projects/lgh/project.json"; L20PL="$LGH/engine/.claude-plugin/plugin.json"
_fx_git "$LGH" fetch -q origin >/dev/null 2>&1; _fx_git "$LGH" checkout -q main >/dev/null 2>&1
_fx_git "$LGH" reset -q --hard refs/remotes/origin/main >/dev/null 2>&1
L20V="$(_l3_mainv)"; [ -n "$L20V" ] && _lg_cache "$L20V"
cp -p "$L20PJ" "$L20/project.json.keep"; cp -p "$L20PL" "$L20/plugin.json.keep"; command -v git > "$L20/realgit"
_lg_reset; _lg_land --uninstall; _lg_reset
is "the land fixture: the home is on main at origin's main, clean, and main's check accepts its cached entry (fixture control)" \
   "$(git -C "$LGH" rev-parse HEAD 2>&1)|$(git -C "$LGH" status --porcelain 2>&1)|$(_l4_acc refs/remotes/origin/main)" "$(git -C "$LGO" rev-parse main 2>&1)||0"

/bin/mv "$LGB/gh" "$L20/gh.prev"
sed "s#@L20@#$L20#g" > "$LGB/gh" <<'L20GH'
#!/bin/bash
L='@L20@'; C="$L/ctl"; S="$L/s"; mkdir -p "$S"
kind="${1:-} ${2:-}"
case "${1:-}" in
  api) kind="api ?"; for a in "$@"; do case "$a" in user) kind="api user" ;; repos/fixture/lgh) kind="api repos/fixture/lgh" ;; esac; done ;;
  issue) if [ "${2:-}" = comment ]; then n=""; sk=""; i=0
           for a in "$@"; do i=$((i+1)); [ "$i" -le 2 ] && continue
             if [ -n "$sk" ]; then sk=""; continue; fi
             case "$a" in -R|--repo|-F|--body-file|-b|--body|-q|--jq|-t|--template) sk=1 ;; -*) ;; *) [ -n "$n" ] || n="$a" ;; esac
           done; kind="issue comment $n"; fi ;;
esac
h=unset; [ -n "${GH_HOST+x}" ] && h=set; r=unset; [ -n "${GH_REPO+x}" ] && r=set
line="$kind	H=$h	R=$r	P=${GH_PROMPT_DISABLED-unset}"
for a in "$@"; do a="${a//$'\n'/ }"; line="$line	${a//	/ }"; done
printf '%s\t\n' "$line" >> "$S/calls.log"; printf '%s\t\n' "$line" >> "$L/all.log"
step=""
case "$kind" in "api user") step=user ;; "api repos/fixture/lgh") step=repos ;; "issue list") step=list ;;
  "issue create") step=create ;; "issue comment "*) step=comment ;; esac
[ -n "$step" ] || exec "$L/gh.prev" "$@"
jqx=""; bf=""; t=""; prev=""
for a in "$@"; do
  case "$prev" in -q|--jq) jqx="$a" ;; -F|--body-file) bf="$a" ;; -t|--title) t="$a" ;; esac
  case "$a" in --jq=*) jqx="${a#--jq=}" ;; --body-file=*) bf="${a#--body-file=}" ;; --title=*) t="${a#--title=}" ;; esac
  prev="$a"
done
if [ "$step" = create ] || [ "$step" = comment ]; then
  k=0; [ -f "$S/k" ] && k="$(cat "$S/k")"; k=$((k+1)); printf '%s\n' "$k" > "$S/k"
  if [ -n "$bf" ] && [ "$bf" != - ]; then cp "$bf" "$S/body.$k" 2>/dev/null; else cat > "$S/body.$k"; fi
  printf '%s\t%s\n' "$k" "$step" >> "$S/bodies.log"
fi
if [ -f "$C/$step" ]; then
  v="$(cat "$C/$step")"
  if [ "$v" = hang ]; then printf '%s\n' "$$" > "$L/hung.pid"; exec sleep 300; fi
  echo "HTTP 500: the fixture's $step step fails" >&2; exit "$v"
fi
out() { if [ -n "$jqx" ] && command -v jq >/dev/null 2>&1; then jq -r "$jqx"; else cat; fi; }
login=fixture-bot; [ -f "$C/login" ] && login="$(cat "$C/login")"
case "$step" in
  user) printf '{"login":"%s"}\n' "$login" | out ;;
  repos) fn=fixture/lgh; ty=User; pu=true
    [ -f "$C/full_name" ] && fn="$(cat "$C/full_name")"; [ -f "$C/type" ] && ty="$(cat "$C/type")"; [ -f "$C/push" ] && pu="$(cat "$C/push")"
    printf '{"full_name":"%s","owner":{"login":"fixture","type":"%s"},"permissions":{"admin":false,"maintain":false,"push":%s}}\n' "$fn" "$ty" "$pu" | out ;;
  list) { printf '['; s=""
      if [ -f "$L/issues.tsv" ]; then while IFS='	' read -r n ti au; do
        printf '%s{"number":%s,"title":"%s","author":{"login":"%s"},"state":"OPEN"}' "$s" "$n" "$ti" "$au"; s=","; done < "$L/issues.tsv"; fi
      printf ']\n'; } | out ;;
  create) n=1; [ -f "$L/issues.tsv" ] && n=$(( $(awk 'END { print NR }' "$L/issues.tsv") + 1 ))
    printf '%s\t%s\t%s\n' "$n" "$t" "$login" >> "$L/issues.tsv"
    if [ -f "$C/create.out" ]; then cat "$C/create.out"; else printf 'https://github.com/fixture/lgh/issues/%s\n' "$n"; fi ;;
  comment) printf 'https://github.com/fixture/lgh/issues/%s#issuecomment-%s\n' "${kind##* }" "$k" ;;
esac
exit 0
L20GH
chmod +x "$LGB/gh"; : > "$L20/all.log"
printf '#!/bin/bash\nprintf '"'"'%%s\\n'"'"' "$*" >> '"'"'%s/git.log'"'"'\nexec "$(cat '"'"'%s/realgit'"'"')" "$@"\n' "$L20" "$L20" > "$L20/gitbin/git"
chmod +x "$L20/gitbin/git"

# ---------------------------------------------------------------- helpers ---
_l20_on() { _fx_git "$LGH" config remote.origin.url https://github.com/fixture/lgh.git >/dev/null 2>&1
            _fx_git "$LGH" config "url.$LGO.insteadOf" https://github.com/fixture/lgh.git >/dev/null 2>&1; }
_l20_off() { _fx_git "$LGH" config remote.origin.url "$LGO" >/dev/null 2>&1; _fx_git "$LGH" config --unset-all "url.$LGO.insteadOf" >/dev/null 2>&1; }
_l20_clear() { rm -rf "$L20/s"; mkdir -p "$L20/s"; : > "$L20/git.log"; }
_l20_reset() {   # [gh] -> land state, wrapper controls, issues and scenario log emptied; with gh, the GitHub state
  _lg_reset; rm -rf "$L20/ctl" "$L20/issues.tsv" "$L20/hung.pid"; mkdir -p "$L20/ctl"; _l20_clear
  if [ "${1:-}" = gh ]; then _l20_on; LGX=(GIT_ALLOW_PROTOCOL=file GH_HOST=evil.example GH_REPO=someone/else); else _l20_off; fi
}
_l20_pj() {   # [ALERT-LOGIN] -> projects/lgh/project.json as kept, with alert_login when given
  if [ -z "${1:-}" ]; then cp -p "$L20/project.json.keep" "$L20PJ"; return 0; fi
  printf '{\n  "name": "lgh",\n  "remote_match": "github.com/fixture/lgh",\n  "gate": "true",\n  "alert_login": "%s"\n}\n' "$1" > "$L20PJ"
}
_l20_ev() { _lg_land --pause "$1"; _lg_land --tick; }   # REASON -> one paused event: --pause REASON, then --tick
# REASON -> a new paused event after one: --resume, --pause, the ledger aged past the hour, --tick. The age is
# not in the contract's A18, but without it no paused row is written: the engine writes one paused row an hour,
# whatever the reason, so the contract's sequence alone raises no event (the control after A17 shows it).
_l20_next() { _lg_land --resume; _lg_land --pause "$1"; _l20_age; _lg_land --tick; }
_l20_age() {   # the ledger's rows a year older, so the newest paused row is past its hour (1280's G2 reading)
  [ -f "$LAND/ledger.tsv" ] || return 0
  LC_ALL=C awk -F'\t' -v OFS='\t' -v y="$(date -u +%Y)" '{ if (index($1, y)) sub(y, y - 1, $1); print }' "$LAND/ledger.tsv" > "$LAND/ledger.aged" \
    && /bin/mv "$LAND/ledger.aged" "$LAND/ledger.tsv"
}
_l20_kinds() { [ -f "$L20/s/calls.log" ] && LC_ALL=C awk -F'\t' '{ printf "%s%s", s, $1; s = "," }' "$L20/s/calls.log"; }   # -> this scenario's calls, by kind
_l20_nk() { if [ -f "$L20/s/calls.log" ]; then LC_ALL=C awk -F'\t' -v r="$1" '$1 ~ r { n++ } END { print n + 0 }' "$L20/s/calls.log"; else echo 0; fi; }   # REGEX -> calls of that kind
_l20_lack() {   # KIND-REGEX VALUE OPT... -> calls of that kind that carry none of OPT VALUE, OPT=VALUE
  [ -f "$L20/s/calls.log" ] || { echo 0; return; }
  LC_ALL=C awk -F'\t' -v r="$1" -v v="$2" -v o="${*:3}" 'BEGIN { m = split(o, os, " ") }
    $1 ~ r { f = 0; for (i = 5; i <= NF; i++) for (j = 1; j <= m; j++) if (($i == os[j] && $(i + 1) == v) || $i == os[j] "=" v) f = 1; if (!f) n++ }
    END { print n + 0 }' "$L20/s/calls.log"
}
_l20_cb() { [ -f "$L20/s/bodies.log" ] && LC_ALL=C awk -F'\t' -v d="$L20/s" '$2 == "comment" { print d "/body." $1 }' "$L20/s/bodies.log"; }   # -> comment bodies
_l20_l1s() { local b; _l20_cb | while IFS= read -r b; do printf '%s|' "$(sed -n 1p "$b")"; done; }   # -> each comment's line 1, then |
_l20_body() { local b; _l20_cb | while IFS= read -r b; do case "$(sed -n 1p "$b")" in "$1"*) printf '%s' "$b"; break ;; esac; done; }   # LINE1-PREFIX -> that comment's body file
_l20_n() { if [ -f "$LAND/alerts.tsv" ]; then LC_ALL=C awk -F'\t' -v k="${1:-}" 'k == "" || $2 == k { n++ } END { print n + 0 }' "$LAND/alerts.tsv"; else echo 0; fi; }   # [posted|failed] -> records
_l20_f() { [ -f "$LAND/alerts.tsv" ] && LC_ALL=C awk -F'\t' -v r="$1" -v k="$2" 'r == "last" || NR == r + 0 { v = $k } END { printf "%s", v }' "$LAND/alerts.tsv"; }   # ROW|last FIELD
_l20_nf() { [ -f "$LAND/alerts.tsv" ] && LC_ALL=C awk -F'\t' '{ printf "%s%s", s, NF; s = "," }' "$LAND/alerts.tsv"; }   # -> each record's field count
_l20_starts() { case "$1" in "$2"*) printf ok ;; *) printf '[%s]' "$1" ;; esac; }   # TEXT PREFIX -> ok, or the text
_l20_in() { case "$1" in *"$2"*) printf '%s' "$3" ;; *) printf '[%s]' "$1" ;; esac; }   # TEXT NEEDLE TAG -> TAG when TEXT holds NEEDLE, or the text
_l20_lacks() { case "$1" in *"$2"*) printf '[%s]' "$1" ;; *) printf '%s' "$3" ;; esac; }   # TEXT NEEDLE TAG -> TAG when TEXT lacks NEEDLE, or the text
_l20_like() { case "$1" in $2) printf '%s' "$3" ;; *) printf '[%s]' "$1" ;; esac; }   # TEXT GLOB TAG -> TAG when TEXT matches GLOB, or the text
_l20_osa() { _lg_logs osa | LC_ALL=C grep -c "with title \"Felix: $1" ; }   # TITLE -> banners sent with it
_l20_tramp() {   # HOME-DIR [PATH-PREFIX] -> the trampoline as launchd runs it, FELIX_HOME_DIR as given; status in LARC
  ( cd "$TMP/cwd" 2>/dev/null || cd "$LG" || exit 97
    exec env -i HOME="$LGU" FELIX_HOME_DIR="$1" PATH="${2-}$LGB:$PATH" GIT_CEILING_DIRECTORIES="${GIT_CEILING_DIRECTORIES-}" \
      "$LATR" ) > "$LG/out.tramp" 2>&1
  LARC=$?
}
_l20_felix() {   # HOME-DIR ARGS... -> felix ARGS from the home's checkout with that home; stdout $LG/out, stderr $LG/err
  local hd="$1"; shift
  ( cd "$LGH" || exit 97
    exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE ${LGX[@]+"${LGX[@]}"} HOME="$LGU" FELIX_HOME="$hd" \
      FELIX_HOME_DIR="$hd" FELIX_MEMORY="$LGM" FELIX_PLUGIN_CACHE="$LGC" PATH="$LGB:$PATH" "$FELIX" "$@" ) > "$LG/out" 2> "$LG/err"
  LGRC=$?
}
L20F="$FROOT/harness/felix-l20fn"
LC_ALL=C awk '{ print } index($0, ". \"${SCRIPT_DIR}/lib/green-tick.sh\"") == 1 && !d { print "_FN_SECS=2"; d = 1 }' "$FELIX" > "$L20F" && chmod +x "$L20F"
_l20_slow() {   # -> the patched CLI's --tick in a process group of its own, ended at 20 seconds (124); L20RC, L20EL seconds
  local p n=0 t0="$SECONDS"
  ( cd "$LGH" || exit 97
    exec perl -e 'setpgrp(0, 0); exec @ARGV or exit 127' env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE \
      ${LGX[@]+"${LGX[@]}"} HOME="$LGU" FELIX_HOME="$LGH" FELIX_HOME_DIR="$LGH" FELIX_MEMORY="$LGM" FELIX_PLUGIN_CACHE="$LGC" \
      PATH="$LGB:$PATH" "$L20F" land --tick ) > "$LG/out.slow" 2>&1 &
  p=$!
  while kill -0 "$p" 2>/dev/null && [ "$n" -lt 200 ]; do sleep 0.1; n=$((n+1)); done
  if kill -0 "$p" 2>/dev/null; then kill -KILL -- "-$p" 2>/dev/null; kill -KILL "$p" 2>/dev/null; wait "$p" 2>/dev/null; L20RC=124
  else wait "$p"; L20RC=$?; fi
  L20EL=$(( SECONDS - t0 ))
}
_l20_hung() {   # -> alive or gone: the pid the hung step wrote, given two seconds to be reaped
  local h n=0; h="$(cat "$L20/hung.pid" 2>/dev/null)"
  [ -n "$h" ] || { echo "no-hang"; return; }
  while kill -0 "$h" 2>/dev/null && [ "$n" -lt 20 ]; do sleep 0.1; n=$((n+1)); done
  if kill -0 "$h" 2>/dev/null; then kill -KILL "$h" 2>/dev/null; echo alive; else echo gone; fi
}

is "the land fixture: a copy of the CLI sets _FN_SECS=2 on the line after it sources lib/green-tick.sh, and differs in nothing else (fixture control)" \
   "$(LC_ALL=C awk 'p && $0 == "_FN_SECS=2" { n++ } { p = (index($0, ". \"${SCRIPT_DIR}/lib/green-tick.sh\"") == 1) } END { print n + 0 }' "$L20F" 2>&1)|$(diff "$FELIX" "$L20F" 2>&1 | LC_ALL=C grep -c '^[<>]')" "1|1"
_l20_reset gh
if command -v jq >/dev/null 2>&1; then
  is "the land fixture: the gh wrapper answers user and repos as F2 says, applies --jq, and hands auth status to the fixture's gh (fixture control)" \
     "$(PATH="$LGB:$PATH" gh api --hostname github.com user --jq .login)|$(PATH="$LGB:$PATH" gh api --hostname github.com repos/fixture/lgh --jq '[.full_name, .owner.login, .owner.type, .permissions.push] | join(" ")')|$(PATH="$LGB:$PATH" gh auth status >/dev/null 2>&1; echo $?)|$(_lg_cnt gh)" \
     "fixture-bot|fixture/lgh fixture User true|0|1"
else skip "the land fixture: the gh wrapper answers user and repos as F2 says, applies --jq, and hands auth status to the fixture's gh (fixture control)" "no jq"; fi
_l20_reset gh
is "the land fixture: in the GitHub state the origin reads as github.com, fetch stays on the local origin, and felix land --status --tsv from the home still exits 0 (fixture control)" \
   "$(git -C "$LGH" config --get remote.origin.url 2>&1)|$(GIT_ALLOW_PROTOCOL=file git -C "$LGH" ls-remote origin refs/heads/main 2>&1 | cut -f1)|$(_lg_land --status --tsv; echo "$LGRC")" \
   "https://github.com/fixture/lgh.git|$(git -C "$LGO" rev-parse main 2>&1)|0"

# ------------------------------------------------------------ B2, B7 ---
_l20_reset; _l20_ev r1
is "A14 (B2, control): with the origin a local path, --pause then --tick writes one paused row, sends one banner titled Felix: paused, and asks gh nothing" \
   "$(_lg_n paused)|$(_l20_osa paused)|fixture-gh=$(_lg_cnt gh)|wrapper=$(_l20_nk .)" "1|1|fixture-gh=0|wrapper=0"
is "A15 (B2, B7): and that run appends one eight-field alerts.tsv record, failed, of kind paused, whose note starts origin:, and holding no text of the origin URL" \
   "$(_l20_n)|$(_l20_nf)|$(_l20_f 1 2)|$(_l20_f 1 3)|$(_l20_starts "$(_l20_f 1 7)" origin:)|$(LC_ALL=C grep -cF "$LGO" "$LAND/alerts.tsv" 2>/dev/null)" "1|8|failed|paused|ok|0"

# ------------------------------------------------------ B3, B5, B6, B7 ---
_l20_reset gh; _l20_ev "held for the alerts test"
L20B="$(_l20_body "@")"
is "A16 (B3, B5, B6, B7): a paused event in the GitHub state calls user, repos, issue list, issue create and issue comment 1, in that order, with the title, --state all, --repo github.com/fixture/lgh and GH_HOST and GH_REPO unset; comments @fixture Felix land: paused, an empty line, the detail indented four spaces; and records it posted on fixture/lgh#1 as @fixture-bot mentioning @fixture" \
   "$(_l20_kinds)|title-lacking=$(_l20_lack '^issue create' 'Felix needs you' --title -t)|state-lacking=$(_l20_lack '^issue list' all --state -s)|repo-lacking=$(_l20_lack '^issue ' github.com/fixture/lgh --repo -R)|env-set=$(LC_ALL=C awk -F'\t' '$1 ~ /^(api|issue) / && ($2 != "H=unset" || $3 != "R=unset") { n++ } END { print n + 0 }' "$L20/s/calls.log" 2>/dev/null)|$(sed -n 1p "$L20B" 2>&1)|[$(sed -n 2p "$L20B" 2>&1)]|$(sed -n 3p "$L20B" 2>&1)|$(_l20_n)|$(_l20_nf)|$(_l20_f 1 2) $(_l20_f 1 3) $(_l20_f 1 4) $(_l20_f 1 5)|$(_l20_starts "$(_l20_f 1 6)" 'https://github.com/fixture/lgh/issues/1#issuecomment-')|$(_l20_f 1 7)" \
   "api user,api repos/fixture/lgh,issue list,issue create,issue comment 1|title-lacking=0|state-lacking=0|repo-lacking=0|env-set=0|@fixture Felix land: paused|[]|    held for the alerts test|1|8|posted paused - fixture/lgh#1|ok|as @fixture-bot mentioning @fixture"
_l20_felix "$LGH" status --tsv; L20S2="$(LC_ALL=C awk -F'\t' '$1 == "alerts"' "$LG/out")"; L20S2F6="$(_l20_f last 6)"
_l20_felix "$LGH" status; L20S2P="$(cat "$LG/out")"

# ---------------------------------------------------------------- B8 ---
_l20_age; _l20_clear; _lg_land --tick
is "A17 (B8): the same paused event raised again past its hour writes one more paused row and banner, but no gh call and no second record" \
   "$(_lg_n paused)|$(_l20_osa paused)|$(_l20_nk .)|$(_l20_n)" "2|2|0|1"

# ------------------------------------------------------------ B5, B1 ---
_l20_clear; _l20_next r2
is "the land fixture: --resume, --pause r2, the ledger aged past the hour and --tick write one more paused row (fixture control)" "$(_lg_n paused)" "3"
is "A18 (B5, B1): a new event comments on the standing issue again, issue 1, without creating another, and records a second posted row" \
   "create=$(_l20_nk '^issue create')|comment-1=$(_l20_nk '^issue comment 1$')|posted=$(_l20_n posted)" "create=0|comment-1=1|posted=2"

# ---------------------------------------------------------------- B1 ---
_l20_reset gh; printf '1\n' > "$LGK/gh-auth.rc"; _lg_land --tick
is "A19 (B1): a tick whose gh auth status fails writes one gh row and comments @fixture Felix land: gh" \
   "$(_lg_n gh)|$(_l20_l1s)" "1|@fixture Felix land: gh|"
_l20_reset gh; _lg_prs "$(_lg_pr 42)" "$(_lg_pr 41)"; _lg_green 41 42
printf 'felix merge: refused\n  blocker one: the receipt is stale\n' > "$LGK/merge.b41.out"; printf '1\n' > "$LGK/merge.b41.rc"
printf 'merged\n' > "$LGK/merge.b42.out"; _lg_land --tick
is "the land fixture: the tick over 41 and 42 refused 41 and landed 42 (fixture control)" "$(_lg_n refused 41)|$(_lg_n landed 42)" "1|1"
L20B="$(_l20_body "@fixture Felix land: refused #41")"; L20L3="$(sed -n 3p "$L20B" 2>/dev/null)"
is "A20 (B1, B6): a refused and a landed pull request each get a comment: @fixture Felix land: refused #41 with the refusal's line indented and no [main suffix, and @fixture Felix land: landed #42" \
   "$(sed -n 1p "$L20B" 2>&1)|$(_l20_starts "$L20L3" '    ')|$(_l20_in "$L20L3" "blocker one" blocker)|$(_l20_lacks "$L20L3" " [main " no-main)|$(sed -n 1p "$(_l20_body "@fixture Felix land: landed #42")" 2>&1)" \
   "@fixture Felix land: refused #41|ok|blocker|no-main|@fixture Felix land: landed #42"
_l20_reset gh; _lg_prs "$(_lg_pr 21 true)"; _lg_green 21; _lg_land --tick
is "A21 (B1): a skip row is no event: a draft pull request gets its skip row and no api or issue call" \
   "$(_lg_n skip 21)|$(_l20_nk '^(api|issue) ')" "1|0"

# ---------------------------------------------------------------- B4 ---
_l20_b4() {   # CASE PREFIX -> after one paused event: CASE:prefix-or-text,records,creates+comments,calls
  _l20_ev "a22 $1"
  printf '%s:%s,%s,%s,%s;' "$1" "$(_l20_starts "$(_l20_f last 7)" "$2")" "$(_l20_n failed)/$(_l20_n)" \
    "$(_l20_nk '^issue (create|comment)')" "$(_l20_kinds)"
}
L20A22=""
_l20_reset gh; printf 'fixture/other\n' > "$L20/ctl/full_name"; L20A22="$L20A22$(_l20_b4 full_name full_name:)"
_l20_reset gh; printf 'false\n' > "$L20/ctl/push"; L20A22="$L20A22$(_l20_b4 push permission:)"
_l20_reset gh; printf 'Organization\n' > "$L20/ctl/type"; L20A22="$L20A22$(_l20_b4 org owner:)"
_l20_reset gh; _l20_pj "bad login"; L20A22="$L20A22$(_l20_b4 login alert_login:)"; _l20_pj
_l20_reset gh; printf 'https://github.com/fixture/other/issues/1\n' > "$L20/ctl/create.out"; L20A22="$L20A22$(_l20_b4 create 'gh issue create:')"
_l20_reset gh; printf '1\n' > "$L20/ctl/user"; L20A22="$L20A22$(_l20_b4 user 'gh api user:')"
L20A22="$L20A22$(_l20_in "$(_l20_f last 7)" "exited 1" exited-1)"
is "A22 (B4): the post is refused and recorded failed, with no issue create or comment, when GitHub names another repository, the account cannot push, the owner is an organization with no alert_login, alert_login is not a login (no gh call at all), create answers another repository's issue, or gh api user exits 1 (exited 1, no later call)" \
   "$L20A22" \
   "full_name:ok,1/1,0,api user,api repos/fixture/lgh;push:ok,1/1,0,api user,api repos/fixture/lgh;org:ok,1/1,0,api user,api repos/fixture/lgh;login:ok,1/1,0,;create:ok,1/1,0,api user,api repos/fixture/lgh,issue list,issue create;user:ok,1/1,0,api user;exited-1"

# ---------------------------------------------------------------- B6 ---
_l20_reset gh; _l20_pj someone-else; _l20_ev a23; _l20_pj
is "A23 (B6): with alert_login someone-else in project.json the comment mentions @someone-else" \
   "$(_l20_starts "$(_l20_l1s)" '@someone-else Felix land:')" "ok"
_l20_reset gh; printf '1\n' > "$L20/ctl/comment"; _l20_ev r24a; _l20_next r24b; rm -f "$L20/ctl/comment"; _l20_next r24c
L20NL="Not delivered before this one: 2 (the newest: $(_l20_f 2 3) at $(_l20_f 2 1))."
is "A24 (B6, B7): two events whose comment fails leave two failed records noting gh issue comment:, and the third, posted, says Not delivered before this one: 2 with the newest's kind and time" \
   "$(_l20_f 1 2) $(_l20_f 2 2) $(_l20_f 3 2)|$(_l20_starts "$(_l20_f 1 7)" 'gh issue comment:')$(_l20_starts "$(_l20_f 2 7)" 'gh issue comment:')|$(LC_ALL=C grep -cxF "$L20NL" "$(_l20_cb | tail -n 1)" 2>/dev/null)" \
   "failed failed posted|okok|1"
_l20_reset gh; _l20_ev "$LGU/x and a@b"; L20B="$(_l20_body "@fixture")"
is "A25 (B6): a detail naming \$HOME/ is shown as ~/ in a code line, and no line of the comment holds \$HOME" \
   "$(sed -n 3p "$L20B" 2>&1)|$(LC_ALL=C grep -cF "$LGU" "$L20B" 2>/dev/null)" "    ~/x and a@b|0"

# ---------------------------------------------------------------- B9 ---
_l20_reset gh; printf 'hang\n' > "$L20/ctl/comment"; _lg_land --pause r9; _l20_slow
is "A26 (B9): with _FN_SECS=2 and the comment step hanging, the tick exits 0 within 20 seconds, the hung gh is no longer running, and one failed record says timed out" \
   "$L20RC|$([ "$L20EL" -le 20 ] && echo within || echo "took-$L20EL")|$(_l20_hung)|$(_l20_n failed)/$(_l20_n)|$(_l20_in "$(_l20_f last 7)" "timed out" timed-out)" \
   "0|within|gone|1/1|timed-out"

# --------------------------------------------------------------- B10 ---
_l20_b10() { printf '%s;osa=%s;rc=%s' "$(cut -f2-7 "$LAND/ledger.tsv" 2>/dev/null | tr '\n' '|')" "$(_lg_cnt osa)" "$1"; }
_l20_reset; _l20_ev "r27 the same pause"; L20K1="$(_l20_b10 "$LGRC")"
_l20_reset gh; printf '1\n' > "$L20/ctl/user"; _l20_ev "r27 the same pause"; L20K2="$(_l20_b10 "$LGRC")"
_l20_reset gh; printf 'hang\n' > "$L20/ctl/comment"; _lg_land --pause "r27 the same pause"; _l20_slow; L20K3="$(_l20_b10 "$L20RC")"; _l20_hung >/dev/null
is "A27 (B10): the paused scenario writes the same ledger fields 2-7, one banner and exit 0 with a local origin, with gh api user failing, and with the comment hanging" \
   "$(_l20_like "$L20K1" "paused$L20T-$L20T-$L20T-$L20T*${L20T}r27 the same pause|;osa=1;rc=0" one-paused-row) // $L20K2 // $L20K3" \
   "one-paused-row // $L20K1 // $L20K1"

# --------------------------------------------------------------- B11 ---
_l20_reset gh; _lg_land --install; L20I="$LGRC|$(_l20_nk .)"; _l20_clear; _l20_tramp "$L20/no-home"
is "A28 (B11): --install calls no gh; the trampoline with a home that does not exist exits 1, writes one deploy-owed row, comments @fixture Felix land: deploy-owed once, and records it posted" \
   "$L20I|$LARC|$(_lg_n deploy-owed)|$(_l20_l1s)|$(_l20_f last 2) $(_l20_f last 3)" "0|0|1|1|@fixture Felix land: deploy-owed||posted deploy-owed"
# A31 follows A28 with no reset between: the tick's attempt rewrites alerts.repo from a local origin.
_l20_off; _l20_ev r31; _l20_clear; _l20_tramp "$L20/no-home"
is "the land fixture: after the paused tick the trampoline wrote its deploy-owed row again, the ledger's newest (fixture control)" \
   "$(tail -n 1 "$LAND/ledger.tsv" 2>/dev/null | cut -f2)" "deploy-owed"
is "A31 (B11): once a tick with a local origin rewrote alerts.repo, the trampoline calls no gh and its newest record is failed" \
   "$(_l20_nk .)|$(_l20_f last 2)" "0|failed"
_l20_reset gh; _lg_land --install; /bin/mv "$L20PL" "$L20/plugin.json.moved"; mkdir "$L20PL"
_l20_clear; _l20_tramp "$LGH" "$L20/gitbin:"; rm -rf "$L20PL"; cp -p "$L20/plugin.json.keep" "$L20PL"
is "A29 (B11): with plugin.json unopenable the trampoline comments @fixture Felix land: unreadable and runs no git" \
   "$(_l20_l1s)|git=$(if [ -f "$L20/git.log" ]; then LC_ALL=C awk 'END { print NR }' "$L20/git.log"; else echo none; fi)" "@fixture Felix land: unreadable||git=0"
_l20_reset gh; _lg_land --install
printf ': > "%s/tripwire"\n' "$L20" > "$LGH/engine/harness/lib/notify.sh"; cp "$LGH/engine/harness/lib/notify.sh" "$LGV/$L20V/harness/lib/notify.sh"
is "the land fixture: the tripwire notify.sh is untracked in the home and sits in main's cache entry (fixture control)" \
   "$(git -C "$LGH" status --porcelain -- engine 2>&1)|$([ -f "$LGV/$L20V/harness/lib/notify.sh" ] && echo cached)" "?? engine/harness/lib/notify.sh|cached"
_l20_clear; _l20_tramp "$LGH"
is "A30 (B11): the trampoline sources no notify.sh from the home or the cache: its deploy-owed row names the untracked file, it comments, and the tripwire is never written" \
   "$(_l20_in "$(_lg_f deploy-owed "" 7)" lib/notify.sh names-it)|$(_l20_l1s)|$([ -e "$L20/tripwire" ] && echo tripped || echo untouched)" \
   "names-it|@fixture Felix land: deploy-owed||untouched"
rm -f "$LGH/engine/harness/lib/notify.sh" "$LGV/$L20V/harness/lib/notify.sh" "$L20/tripwire"

# --------------------------------------------------------------- B12 ---
_l20_reset gh; _l20_ev a32; _lg_land --resume; L20M0="$(find "$LGM" -name alerts.tsv 2>/dev/null | LC_ALL=C sort)|$(cksum < "$LAND/alerts.tsv" 2>/dev/null)"
L20M1="$([ -s "$LAND/alerts.tsv" ] && echo record || echo no-record)"
_l20_clear
( cd "$L20/noproj" || exit 97
  exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE -u FELIX_LAND_LEDGER ${LGX[@]+"${LGX[@]}"} HOME="$LGU" FELIX_HOME="$LGH" \
    FELIX_HOME_DIR="$LGH" FELIX_MEMORY="$LGM" FELIX_PLUGIN_CACHE="$LGC" PATH="$LGB:$PATH" "$FELIX" land --tick ) > "$LG/out" 2>&1
is "A32 (B12): a hand-run tick that resolves no project, with no FELIX_LAND_LEDGER, makes no gh call and writes no alerts record anywhere" \
   "$L20M1|$(_l20_nk '^(api|issue) ')|$(find "$LGM" -name alerts.tsv 2>/dev/null | LC_ALL=C sort)|$(cksum < "$LAND/alerts.tsv" 2>/dev/null)" "record|0|$L20M0"

# --------------------------------------------------------------- B13 ---
_l20_st() {   # [HOME-DIR] -> felix status --tsv: the alerts row's state and value, and whether the run wrote or called anything
  local s0; s0="$(_lgsnap)"; _l20_clear; _l20_felix "${1:-$LGH}" status --tsv
  L20SR="$(LC_ALL=C awk -F'\t' '$1 == "alerts"' "$LG/out")"
  printf '%s %s' "$(printf '%s' "$L20SR" | cut -f2)" "$(printf '%s' "$L20SR" | cut -f3)"
  [ "$(_lgsnap)" = "$s0" ] || printf ' (wrote)'; [ "$(_l20_nk .)" = 0 ] || printf ' (called gh)'
}
_l20_has() { [ -n "$2" ] || { printf '[nothing to look for]'; return 0; }; case "$1" in *"$2"*) printf ok ;; *) printf '[%s lacks %s]' "$1" "$2" ;; esac; }
_l20_reset gh; L20A33="rows=$(_l20_felix "$LGH" status --tsv; cut -f1 "$LG/out" | tr '\n' ' ')|none=$(_l20_st)"
L20A33="$L20A33|posted=$(printf '%s' "$L20S2" | cut -f2,3 | tr '\t' ' ') $(_l20_has "$(printf '%s' "$L20S2" | cut -f4)" "$L20S2F6")"
L20A33="$L20A33|plain=$(_l20_has "$L20S2P" "$(printf '%s\n' "$L20S2" | LC_ALL=C awk -F'\t' '{ s = ($2 == "value") ? $3 : $2; printf "%-9s %-12s %s", $1, s, $4 }')")"
_l20_ev a33a; printf 'fixture\n' > "$L20/ctl/login"; _l20_next a33b
L20A33="$L20A33|self=$(_l20_st) $(_l20_has "$(_lg_lc "$(printf '%s' "$L20SR" | cut -f4)")" own)"
printf '1\n' > "$L20/ctl/comment"; _l20_next a33c
L20A33="$L20A33|failed=$(_l20_st) $(_l20_has "$(printf '%s' "$L20SR" | cut -f4)" "$(_l20_f last 7)")"
printf 'a\tb\tc\n' >> "$LAND/alerts.tsv"; L20A33="$L20A33|three=$(_l20_st)"
L20A33="$L20A33|nohome=$(_l20_st "$L20/nohome")"
is "A33 (B13): felix status --tsv prints six rows ending alerts, which reads none, posted with the comment URL, posted-self saying own, failed with its note, and unknown for an unreadable record or a home with no project, writing nothing and calling no gh; plain status aligns it" \
   "$L20A33" "rows=settings schedule pulse reach gate alerts |none=none -|posted=value posted ok|plain=ok|self=value posted-self ok|failed=value failed ok|three=unknown -|nohome=unknown -"

# --------------------------------------------------------------- B10 ---
_l20_reset gh; _l20_ev a35
is "A35 (B10, control): in the GitHub state a paused tick still writes one seven-field paused row and one banner titled Felix: paused" \
   "$(_lg_n paused)|$(LC_ALL=C awk -F'\t' 'NF != 7' "$LAND/ledger.tsv" 2>/dev/null | wc -l | tr -d ' ')|$(_l20_osa paused)" "1|0|1"

# ---------------------------------------------------------------- B3 ---
is "A34 (B3): across the part, gh saw no issue call but list, create and comment, no pr call but the tick's list and view, no label or workflow call, and no api call that writes (and some comment was made)" \
   "$(LC_ALL=C awk -F'\t' '
      $1 ~ /^issue / && $1 !~ /^issue (list|create|comment)/ { i++ }
      $1 ~ /^pr / && $1 != "pr list" && $1 != "pr view" { p++ }
      $1 ~ /^(label|workflow) / { l++ }
      $1 ~ /^api / { for (k = 5; k <= NF; k++) if ($k ~ /^(-X|--method|-f|-F|--field|--raw-field|--input)(=.*)?$/ || $k ~ /^-X./) { a++; break } }
      $1 ~ /^issue comment/ { c++ }
      END { printf "issue=%d|pr=%d|label-workflow=%d|api-writes=%d|%s", i, p, l, a, (c ? "commented" : "no-comment") }' "$L20/all.log" 2>&1)" \
   "issue=0|pr=0|label-workflow=0|api-writes=0|commented"

# ------------------------------------------------------------- undone ---
_l20_off; _l20_pj; rm -rf "$L20PL"; cp -p "$L20/plugin.json.keep" "$L20PL"; /bin/mv "$L20/gh.prev" "$LGB/gh"; rm -f "$L20F"
_lg_reset; _lg_land --uninstall; _lg_reset; rm -rf "$L20"
is "the land fixture: the part put the home back: origin is the local path, no insteadOf, the home clean, the fixture's gh in place, and the working directory where it was (fixture control)" \
   "$(git -C "$LGH" config --get remote.origin.url 2>&1)|$(git -C "$LGH" config --get-regexp '^url\.' 2>&1)|$(git -C "$LGH" status --porcelain 2>&1)|$(LC_ALL=C grep -c 'amend/gh.1280' "$LGB/gh" 2>&1)|$(pwd -P)" \
   "$LGO|||1|$L20CWD"
