printf '\nb10: the durable channel covers migration layouts and SQL, execute covers what a credential-holding workflow runs (blind)\n'
# Written blind on 2026-10-24 from the contract
# docs/2026-10-24-audit-fixes/b10-escape-channels-see-what-they-claim.md alone:
# C021 and C081 (B10-B24; its A41-A60). No engine code was read. The calls are
# the contract's ESC and BLK, each in a child of this suite's bash under set -uo
# pipefail (the suite's own options), standing in the fixture repository, stdin
# from /dev/null, under perl's alarm; A59 and A60 run the judge's /bin/bash line
# exactly as the contract gives it. E is "$FROOT/harness"; P is an empty
# directory; R (B10DR here) is a repository with one base commit on main and the
# change committed on feat, B = main, unless an item says otherwise.
#
# Readings, where the contract leaves room:
# - every fixture repository sets core.quotePath true in its own config (git's
#   default); a file the base holds or the change edits holds `echo base`, and an
#   edit appends `echo changed`;
# - "prints nothing" and "no execute row" also want exit 0, so a call that never
#   ran or timed out fails rather than passing; the =~ checks also want the
#   constant non-empty, since an empty regex matches every path;
# - B15's workflow is written byte for byte as the contract shows it, without its
#   list indent; each variant changes only what it names: (a) the environment in
#   block form in release.yaml, (b) a job-level permissions block, (c) a top-level
#   permissions line, (d) and (e) the run step; B17, B18 and B21 put their uses or
#   run step in place of B15's run step;
# - A54.4 and A54.5 are B20 (d)'s two paths, each its own assertion over the one
#   branch that edits both.
B10D="$(mktemp -d "$TMP/b10-XXXXXX" 2>/dev/null)" && B10D="$(cd "$B10D" && pwd -P)" || B10D=""
_b10d_all=""
if [ -z "$B10D" ] || [ ! -d "$B10D" ]; then B10D="$TMP/b10-d"; mkdir -p "$B10D"; _b10d_all="no directory for this part could be made under $TMP"; fi
_b10d_E="$FROOT/harness"; _b10d_P="$B10D/p"; mkdir -p "$_b10d_P"

# ---- fixtures ----------------------------------------------------------------
_b10d_repo() {  # NAME: B10DR is a new repository $B10D/NAME on main holding README.txt; _b10d_why is empty, or why it could not be made
  B10DR="$B10D/$1"; _b10d_why="$_b10d_all"; [ -z "$_b10d_why" ] || return 0
  { mkdir "$B10DR" && ( _fx_cd "$B10DR" && git init -q -b main && git config core.quotePath true ) >/dev/null 2>&1 \
      && printf 'base\n' > "$B10DR/README.txt"; } || _b10d_why="the repository $1 could not be made"
}
_b10d_ci() {  # MESSAGE: B10DR's tree staged and committed
  ( _fx_cd "$B10DR" && git add -A \
      && git -c user.name=b10 -c user.email=b10@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm "$1" ) >/dev/null 2>&1
}
_b10d_base() {  # [main]: the one base commit on main, then B10DR on a new branch feat unless main is given
  [ -z "$_b10d_why" ] || return 0
  _b10d_ci base || { _b10d_why="the base commit in $B10DR failed"; return 0; }
  [ "${1-}" = main ] || ( _fx_cd "$B10DR" && git checkout -q -b feat ) >/dev/null 2>&1 || _b10d_why="no branch feat could be made in $B10DR"
}
_b10d_feat() { [ -z "$_b10d_why" ] || return 0; _b10d_ci change || _b10d_why="the change on feat in $B10DR could not be committed"; }
_b10d_put() {  # PATH TEXT: B10DR/PATH holds TEXT and a line feed
  [ -z "$_b10d_why" ] || return 0
  case "$1" in */*) mkdir -p "$B10DR/${1%/*}" 2>/dev/null ;; esac
  printf '%s\n' "$2" > "$B10DR/$1" 2>/dev/null || _b10d_why="$1 could not be written in $B10DR"
}
_b10d_edit() {  # PATH...: a line appended to each, then committed on feat
  local f
  for f in "$@"; do [ -n "$_b10d_why" ] || printf 'echo changed\n' >> "$B10DR/$f" 2>/dev/null || _b10d_why="$f could not be edited in $B10DR"; done
  _b10d_feat
}
_b10d_one() {  # NAME PATH TEXT: B10DR on feat, whose one commit over the base adds PATH holding TEXT
  _b10d_repo "$1"; _b10d_base; _b10d_put "$2" "$3"; _b10d_feat
}
# FILE CRED STEP [TOP]: B15's workflow at B10DR/FILE, CRED (whole lines at the
# job's indent, "" for none) in place of its environment line, STEP in place of
# its last step, and TOP (whole lines) after the on: block.
_b10d_wf() {
  [ -z "$_b10d_why" ] || return 0
  { mkdir -p "$B10DR/${1%/*}" && {
      printf 'on:\n  push:\n    branches: [main]\n'
      [ -z "${4-}" ] || printf '%s\n' "$4"
      printf 'jobs:\n  deploy:\n    runs-on: ubuntu-latest\n'
      [ -z "$2" ] || printf '%s\n' "$2"
      printf '    steps:\n      - uses: actions/checkout@v4\n      - %s\n' "$3"
    } > "$B10DR/$1"; } 2>/dev/null || _b10d_why="the workflow $1 could not be written in $B10DR"
}
_b10d_env='    environment: production'; _b10d_run='run: ./scripts/deploy.sh'
_b10d_wfrepo() {  # NAME FILE CRED STEP TOP [main] -- PATH...: base holds the workflow, scripts/deploy.sh and each PATH; B10DR then on feat unless main
  local n="$1" f="$2" c="$3" s="$4" t="$5" m=""; shift 5
  [ "${1-}" != main ] || { m=main; shift; }
  [ "${1-}" != -- ] || shift
  _b10d_repo "$n"; _b10d_wf "$f" "$c" "$s" "$t"; _b10d_put scripts/deploy.sh 'echo deploy'
  for f in "$@"; do _b10d_put "$f" 'echo base'; done
  _b10d_base $m
}

# ---- calls -------------------------------------------------------------------
_b10d_sh() {  # SECS DIR SNIPPET ENGINE ARG...: as part 1810's: stdout in _b10d_out, status in _b10d_rc (125: nothing ran)
  local s="$1" d="$2" c="$3"; shift 3
  _b10d_out=""; _b10d_rc=125
  [ -d "$d" ] || return 0
  _b10d_out="$( ( _fx_cd "$d" || exit 125
      exec perl -e 'alarm shift; exec @ARGV or exit 127' "$s" "$BASH" -c "set -uo pipefail; $c" _ "$@" ) </dev/null 2>/dev/null )"
  _b10d_rc=$?
}
_b10d_esc() {  # [BASE]: ESC on B10DR, B = main unless given
  _b10d_out=""; _b10d_rc=125; [ -z "$_b10d_why" ] || return 0
  _b10d_sh 90 "$B10DR" '. "$1/lib/escape.sh"; felix_escapes "$2" "$3" "$4" ""' "$_b10d_E" "$_b10d_P" "${1-main}" "$B10DR"
}
_b10d_blk() {
  _b10d_out=""; _b10d_rc=125; [ -z "$_b10d_why" ] || return 0
  _b10d_sh 180 "$B10DR" 'for f in resolve verify review classify evidence escape; do . "$1/lib/$f.sh"; done
    felix_merge_blockers "$2" main "$3" "$4"' "$_b10d_E" "$_b10d_P" "$B10DR" "$FROOT"
}
_b10d_re() {  # PATH -> yes when [[ PATH =~ $FELIX_ESCAPE_DURABLE_PATH ]] holds in bash under LC_ALL=C after escape.sh is sourced, no when not, else what went wrong
  local o
  o="$(LC_ALL=C perl -e 'alarm shift; exec @ARGV or exit 127' 30 "$BASH" -c '. "$1/lib/escape.sh" >/dev/null 2>&1
    [ -n "${FELIX_ESCAPE_DURABLE_PATH:-}" ] || { echo "FELIX_ESCAPE_DURABLE_PATH is empty or unset"; exit 0; }
    if [[ $2 =~ $FELIX_ESCAPE_DURABLE_PATH ]]; then echo yes; else echo no; fi' _ "$_b10d_E" "$1" </dev/null 2>/dev/null)"
  printf '%s' "${o:-nothing was printed}"
}

# ---- readings: as part 1810's ---------------------------------------------------
_b10d_n() {  # CHANNEL PATH [NEEDLE]: lines of _b10d_out with CHANNEL first, PATH second ("-": any), NEEDLE in the reason
  printf '%s\n' "$_b10d_out" | B10_C="$1" B10_P="$2" B10_S="${3-}" LC_ALL=C awk '
    BEGIN { c = ENVIRON["B10_C"]; p = ENVIRON["B10_P"]; s = ENVIRON["B10_S"] }
    { i = index($0, "\t"); f1 = i ? substr($0, 1, i - 1) : $0; r = i ? substr($0, i + 1) : ""
      j = index(r, "\t"); f2 = j ? substr(r, 1, j - 1) : r; f3 = j ? substr(r, j + 1) : ""
      if ((c == "-" || f1 == c) && (p == "-" || f2 == p) && (s == "" || index(f3, s) > 0)) n++ }
    END { print n + 0 }'
}
_b10d_fx() { [ -z "$_b10d_why" ] || { bad "$1" "the fixture could not be built: $_b10d_why"; return 1; }; }
_b10d_said() { printf 'exit %s, output [%s]' "$_b10d_rc" "$_b10d_out"; }
_b10d_row() {  # NAME CHANNEL PATH [NEEDLE]
  _b10d_fx "$1" || return 0
  if [ "$(_b10d_n "$2" "$3" "${4-}")" -gt 0 ]; then ok "$1"
  else bad "$1" "no [$2] row for [$3]${4:+ whose reason holds [$4]}: $(_b10d_said)"; fi
}
_b10d_norow() {  # NAME CHANNEL PATH: exit 0 and no such row
  _b10d_fx "$1" || return 0
  if [ "$_b10d_rc" -eq 0 ] && [ "$(_b10d_n "$2" "$3")" -eq 0 ]; then ok "$1"; else bad "$1" "$(_b10d_said)"; fi
}
_b10d_none() {  # NAME: exit 0 and nothing printed
  _b10d_fx "$1" || return 0
  if [ "$_b10d_rc" -eq 0 ] && [ -z "$_b10d_out" ]; then ok "$1"; else bad "$1" "$(_b10d_said)"; fi
}

# ---- C021: the durable channel covers the common migration layouts and SQL -------
_b10d_new="db/migrate/20261023000000_drop_users.rb engines/billing/db/migrate/1_x.rb db/migration/V7__init.sql
  src/main/resources/db/migration/V8__more.sql src/migration/1700000000000-Init.ts Migrations/20231010_Init.cs
  src/Data/Migrations/20231010_Init.cs drizzle/0001_init.sql db/changelog/db.changelog-master.yaml liquibase/changelog.xml"
_b10d_old="migrations/1.sql app/migrations/0002_x.py alembic/versions/1_x.py prisma/migrations/1_init/migration.sql"
_b10d_not="lib/migrations.rb docs/migrating.md drizzle.config.ts CHANGELOG.md db/seeds.rb src/migrate.ts changelog/unreleased/1.md"
_b10d_k=0
for _b10d_p in $_b10d_new; do
  _b10d_k="$((_b10d_k + 1))"; _b10d_one "a41-$_b10d_k" "$_b10d_p" x; _b10d_esc
  _b10d_row "b10 A41.$_b10d_k: $_b10d_p, committed on its own branch, gets a durable row" durable "$_b10d_p"
done
_b10d_k=0
for _b10d_p in $_b10d_new; do
  _b10d_k="$((_b10d_k + 1))"
  is "b10 A42.$_b10d_k: FELIX_ESCAPE_DURABLE_PATH matches $_b10d_p under bash's =~ with LC_ALL=C" "$(_b10d_re "$_b10d_p")" "yes"
done
_b10d_k=0
for _b10d_p in $_b10d_old; do
  _b10d_k="$((_b10d_k + 1))"; _b10d_one "a43-$_b10d_k" "$_b10d_p" x; _b10d_esc
  _b10d_nm="b10 A43.$_b10d_k: $_b10d_p stays durable, by ESC and by =~ (control)"
  if _b10d_fx "$_b10d_nm"; then
    _b10d_v="$(_b10d_re "$_b10d_p")"
    if [ "$(_b10d_n durable "$_b10d_p")" -gt 0 ] && [ "$_b10d_v" = yes ]; then ok "$_b10d_nm"; else bad "$_b10d_nm" "=~ says [$_b10d_v]; $(_b10d_said)"; fi
  fi
done
_b10d_k=0
for _b10d_p in $_b10d_not; do
  _b10d_k="$((_b10d_k + 1))"; _b10d_one "a44-$_b10d_k" "$_b10d_p" x; _b10d_esc
  _b10d_nm="b10 A44.$_b10d_k: $_b10d_p is not durable: ESC prints nothing and =~ does not hold (control)"
  if _b10d_fx "$_b10d_nm"; then
    _b10d_v="$(_b10d_re "$_b10d_p")"
    if [ "$_b10d_rc" -eq 0 ] && [ -z "$_b10d_out" ] && [ "$_b10d_v" = no ]; then ok "$_b10d_nm"; else bad "$_b10d_nm" "=~ says [$_b10d_v]; $(_b10d_said)"; fi
  fi
done
# B13 and B14: each line the only line of notes/case.txt on its own branch.
_b10d_k=0
while IFS= read -r _b10d_l; do
  _b10d_k="$((_b10d_k + 1))"; _b10d_one "a45-$_b10d_k" notes/case.txt "$_b10d_l"; _b10d_esc
  case " 1 9 13 15 18 " in *" $_b10d_k "*) _b10d_c=" (control)" ;; *) _b10d_c="" ;; esac
  _b10d_nm="b10 A45.$_b10d_k: the added line [$_b10d_l] gives exactly one durable ADDED-LINES row$_b10d_c"
  _b10d_fx "$_b10d_nm" && is "$_b10d_nm" "$(_b10d_n durable ADDED-LINES) rows; exit $_b10d_rc" "1 rows; exit 0"
done <<'B10D_DESTRUCTIVE'
DROP TABLE users;
drop table users;
  Drop Table If Exists users;
DROP SCHEMA public CASCADE;
drop database app;
ALTER TABLE accounts DROP COLUMN email;
alter table accounts drop email;
    DROP COLUMN email;
TRUNCATE sessions;
truncate table sessions;
truncate sessions;
DELETE FROM Widgets;
DELETE FROM nowhere;
delete from users;
DELETE FROM users
UPDATE users SET email = NULL;
update users set active=false
db.Exec("DELETE FROM sessions")
B10D_DESTRUCTIVE
_b10d_k=0
while IFS= read -r _b10d_l; do
  _b10d_k="$((_b10d_k + 1))"; _b10d_one "a46-$_b10d_k" notes/case.txt "$_b10d_l"; _b10d_esc
  _b10d_none "b10 A46.$_b10d_k: the added line [$_b10d_l] gives ESC nothing (control)"
done <<'B10D_HARMLESS'
DELETE FROM users WHERE id = 1;
delete from users where id = 1;
UPDATE users SET a = 1 WHERE id = 2;
Truncate the log before rotating it.
We drop tables we no longer need.
CREATE TABLE users (id int);
DROP INDEX idx_users_email;
Update the set of rules.
-- the old job used to delete from the queue here
B10D_HARMLESS

# ---- C081: execute covers what a workflow holding main-only credentials runs -----
_b10d_wy=.github/workflows/deploy.yml
_b10d_wfrepo a47 "$_b10d_wy" "$_b10d_env" "$_b10d_run" ""; _b10d_edit scripts/deploy.sh; _b10d_esc
_b10d_R47="$B10DR"; _b10d_W47="$_b10d_why"
_b10d_row "b10 A47: scripts/deploy.sh, run by a push workflow whose job has environment: production, gets an execute row naming the workflow" \
  execute scripts/deploy.sh "$_b10d_wy"
_b10d_wfrepo a48-1 .github/workflows/release.yaml "$(printf '    environment:\n      name: production')" "$_b10d_run" ""
_b10d_edit scripts/deploy.sh; _b10d_esc
_b10d_row "b10 A48.1: the environment in block form, in release.yaml, gives scripts/deploy.sh an execute row naming release.yaml" \
  execute scripts/deploy.sh .github/workflows/release.yaml
_b10d_wfrepo a48-2 "$_b10d_wy" "$(printf '    permissions:\n      id-token: write')" "$_b10d_run" ""; _b10d_edit scripts/deploy.sh; _b10d_esc
_b10d_row "b10 A48.2: no environment and a permissions block holding id-token: write gives scripts/deploy.sh an execute row" execute scripts/deploy.sh "$_b10d_wy"
_b10d_wfrepo a48-3 "$_b10d_wy" "" "$_b10d_run" 'permissions: write-all'; _b10d_edit scripts/deploy.sh; _b10d_esc
_b10d_row "b10 A48.3: no environment and permissions: write-all gives scripts/deploy.sh an execute row" execute scripts/deploy.sh "$_b10d_wy"
_b10d_wfrepo a48-4 "$_b10d_wy" "$_b10d_env" 'run: bash scripts/deploy.sh --prod' ""; _b10d_edit scripts/deploy.sh; _b10d_esc
_b10d_row "b10 A48.4: the step run: bash scripts/deploy.sh --prod gives scripts/deploy.sh an execute row" execute scripts/deploy.sh "$_b10d_wy"
_b10d_wfrepo a48-5 "$_b10d_wy" "$_b10d_env" 'run: ${{ github.workspace }}/scripts/deploy.sh' ""; _b10d_edit scripts/deploy.sh; _b10d_esc
_b10d_row "b10 A48.5: the step run with the workspace expression before /scripts/deploy.sh gives scripts/deploy.sh an execute row" execute scripts/deploy.sh "$_b10d_wy"
_b10d_wfrepo a49 "$_b10d_wy" "$_b10d_env" 'uses: ./tools/deploy-action' "" -- tools/deploy-action/index.js
_b10d_edit tools/deploy-action/index.js; _b10d_esc
_b10d_row "b10 A49: a file under a local action the workflow uses, tools/deploy-action/index.js, gets an execute row" execute tools/deploy-action/index.js
_b10d_wfrepo a50 "$_b10d_wy" "$_b10d_env" 'run: .github/scripts/deploy.sh' "" -- .github/scripts/deploy.sh
_b10d_edit .github/scripts/deploy.sh; _b10d_esc
_b10d_row "b10 A50: .github/scripts/deploy.sh, run by the workflow, gets an execute row" execute .github/scripts/deploy.sh
_b10d_repo a51; _b10d_put action.yml 'name: act'; _b10d_base; _b10d_edit action.yml; _b10d_esc
_b10d_row "b10 A51: a root action.yml changed, with no workflow at all, gets an execute row" execute action.yml
_b10d_repo a52; _b10d_put action.yaml 'name: act'; _b10d_base; _b10d_edit action.yaml; _b10d_esc
_b10d_row "b10 A52: a root action.yaml changed gets an execute row" execute action.yaml
_b10d_why="$_b10d_all"; _b10d_sh 30 "$B10D" '. "$1/lib/escape.sh"; felix_land_protected "$2"' "$_b10d_E" action.yml
_b10d_nm="b10 A53: PROT action.yml prints execute and exits 0"
_b10d_fx "$_b10d_nm" && is "$_b10d_nm" "exit $_b10d_rc [$_b10d_out]" "exit 0 [execute]"
_b10d_wfrepo a54-1 "$_b10d_wy" "$(printf '    env:\n      KEY: ${{ secrets.PROD_KEY }}')" "$_b10d_run" ""; _b10d_edit scripts/deploy.sh; _b10d_esc
_b10d_norow "b10 A54.1: a workflow holding only a repository secret in env gives scripts/deploy.sh no execute row (control)" execute scripts/deploy.sh
_b10d_nm="b10 A54.2: Felix's own gate.yml at the base gives an edit to engine/harness/felix no execute row (control)"
_b10d_g="$REAL_HARNESS/../../.github/workflows/gate.yml"
if [ ! -f "$_b10d_g" ]; then skip "$_b10d_nm" "no .github/workflows/gate.yml beside the harness"
else
  _b10d_repo a54-2; _b10d_put engine/harness/felix 'echo base'
  [ -n "$_b10d_why" ] || { mkdir -p "$B10DR/.github/workflows" && cp "$_b10d_g" "$B10DR/.github/workflows/gate.yml"; } 2>/dev/null \
    || _b10d_why="gate.yml could not be copied into $B10DR"
  _b10d_base; _b10d_edit engine/harness/felix; _b10d_esc
  _b10d_norow "$_b10d_nm" execute engine/harness/felix
fi
_b10d_wfrepo a54-3 "$_b10d_wy" "$_b10d_env" "$_b10d_run" "" -- scripts/other.sh; _b10d_edit scripts/other.sh; _b10d_esc
_b10d_norow "b10 A54.3: scripts/other.sh, which the workflow does not name, gets no execute row (control)" execute scripts/other.sh
_b10d_wfrepo a54-4 "$_b10d_wy" "$_b10d_env" "$_b10d_run" "" -- myscripts/deploy.sh scripts/deploy.sh.bak
_b10d_edit myscripts/deploy.sh scripts/deploy.sh.bak; _b10d_esc
_b10d_norow "b10 A54.4: myscripts/deploy.sh, a longer word than the one the workflow names, gets no execute row (control)" execute myscripts/deploy.sh
_b10d_norow "b10 A54.5: scripts/deploy.sh.bak, edited on the same branch, gets no execute row (control)" execute scripts/deploy.sh.bak
_b10d_wfrepo a54-6 "$_b10d_wy" '    # environment: production' "$_b10d_run" ""; _b10d_edit scripts/deploy.sh; _b10d_esc
_b10d_norow "b10 A54.6: an environment line written as a comment gives scripts/deploy.sh no execute row (control)" execute scripts/deploy.sh
_b10d_wfrepo a55 "$_b10d_wy" "$_b10d_env" 'uses: ./.github/actions/deploy' "" -- .github/actions/deploy/action.yml
_b10d_edit .github/actions/deploy/action.yml; _b10d_esc; _b10d_nm="b10 A55: .github/actions/deploy/action.yml, used by the workflow, gets exactly one execute row (control)"
_b10d_fx "$_b10d_nm" && is "$_b10d_nm" "$(_b10d_n execute .github/actions/deploy/action.yml) rows" "1 rows"
_b10d_wfrepo a56 "$_b10d_wy" "$_b10d_env" "$_b10d_run" "" main
[ -n "$_b10d_why" ] || printf 'echo changed\n' >> "$B10DR/scripts/deploy.sh" 2>/dev/null || _b10d_why="scripts/deploy.sh could not be edited in $B10DR"
_b10d_esc ""
_b10d_row "b10 A56: with an empty base, an unstaged edit to scripts/deploy.sh on main gets an execute row, the workflows read from HEAD" execute scripts/deploy.sh
_b10d_wfrepo a57 "$_b10d_wy" "$_b10d_env" "$_b10d_run" ""; _b10d_edit scripts/deploy.sh
if [ -z "$_b10d_why" ]; then
  _b10d_b="$(_fx_git "$B10DR" rev-parse --verify -q "main:$_b10d_wy" 2>/dev/null)"
  case "$_b10d_b" in
    [0123456789abcdef][0123456789abcdef]?*) rm -f "$B10DR/.git/objects/${_b10d_b:0:2}/${_b10d_b:2}" ;;
    *) _b10d_why="the blob of main's $_b10d_wy could not be named: [$_b10d_b]" ;;
  esac
  [ -n "$_b10d_why" ] || ! _fx_git "$B10DR" cat-file -e "$_b10d_b" 2>/dev/null \
    || _b10d_why="git cat-file -e still reads $_b10d_b after its loose object file was removed"
fi
_b10d_esc
_b10d_row "b10 A57: when main's workflow blob cannot be read, ESC prints unknown CHANGED-PATHS naming .github/workflows" unknown CHANGED-PATHS .github/workflows
_b10d_blk
_b10d_row "b10 A58: and BLK prints a line unknown CHANGED-PATHS" unknown CHANGED-PATHS
B10DR="$_b10d_R47"; _b10d_why="$_b10d_W47"; _b10d_out=""; _b10d_rc=125; _b10d_err="$B10D/a59.err"; : > "$_b10d_err"
if [ -z "$_b10d_why" ] && [ -d "$B10DR" ]; then
  _b10d_out="$( ( _fx_cd "$B10DR" || exit 125
      exec perl -e 'alarm shift; exec @ARGV or exit 127' 90 /bin/bash -c 'set -uo pipefail; for f in resolve verify review classify evidence escape; do . "$1/lib/$f.sh"; done; felix_escapes "$2" main "$3" ""' \
        _ "$_b10d_E" "$_b10d_P" "$B10DR" ) </dev/null 2>"$_b10d_err" )"
  _b10d_rc=$?
fi
_b10d_row "b10 A59: the judge's /bin/bash under set -uo pipefail, six libraries sourced, prints B15's execute row" execute scripts/deploy.sh "$_b10d_wy"
_b10d_nm="b10 A60: and its stderr does not say unbound variable (control)"
if _b10d_fx "$_b10d_nm"; then
  if [ -f "$_b10d_err" ] && ! LC_ALL=C grep -q 'unbound variable' "$_b10d_err"; then ok "$_b10d_nm"
  else bad "$_b10d_nm" "stderr: [$(cat "$_b10d_err" 2>/dev/null)]"; fi
fi

# ---- Review round (2026-10-26), M1: the added-line rule keeps every catch main's rule makes ----
# Written blind from the contract's Review round section. Main's rule, as §1 C021
# states it, is the upper-case ERE below; a line it catches, holding no "where" in
# any case, must still give exactly one durable ADDED-LINES row. Each line is
# checked against that ERE first, so a corpus line outside the class is a bad
# assertion, never a silent pass. The file is db/cleanup.sql, on no migration
# path; <TAB> in a corpus line stands for the byte 0x09.
_b10d_main='DROP TABLE|TRUNCATE |DELETE FROM [^W]*$'; _b10d_T="$(printf '\t')"
_b10d_k=0
while IFS= read -r _b10d_r; do
  _b10d_k="$((_b10d_k + 1))"; _b10d_l="${_b10d_r//<TAB>/$_b10d_T}"
  _b10d_nm="b10 M1.$_b10d_k: main's rule catches the added line [$_b10d_r] in db/cleanup.sql, and ESC still gives exactly one durable ADDED-LINES row"
  if ! LC_ALL=C grep -Eq "$_b10d_main" <<<"$_b10d_l" || LC_ALL=C grep -iq where <<<"$_b10d_l"; then
    bad "$_b10d_nm" "the corpus line is not one main's rule catches without a where: the test is wrong"; continue
  fi
  _b10d_one "m1-$_b10d_k" db/cleanup.sql "$_b10d_l"; _b10d_esc
  _b10d_fx "$_b10d_nm" && is "$_b10d_nm" "$(_b10d_n durable ADDED-LINES) rows; exit $_b10d_rc" "1 rows; exit 0"
done <<'B10D_MAIN_CATCHES'
DROP TABLESPACE app_data INCLUDING CONTENTS AND DATAFILES;
DROP TABLE`users`;
DROP TABLE"users";
DROP TABLE[users];
db.Exec("DROP TABLE"+name)
DROP TABLE<TAB>users;
DELETE FROM "users";
DELETE FROM `users`;
DELETE FROM [users];
TRUNCATE "sessions";
B10D_MAIN_CATCHES
_b10d_one m1-c db/cleanup.sql 'SELECT 1;'; _b10d_esc
_b10d_none "b10 M1.11: db/cleanup.sql holding only SELECT 1; gives ESC nothing, so the path itself is not durable (control)"
