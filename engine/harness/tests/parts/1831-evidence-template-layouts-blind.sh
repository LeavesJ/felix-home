printf '\nthe seeded evidence template gives true verdicts for the layouts it names (audit b11, blind)\n'
# Blind, written on 2026-10-24 from docs/2026-10-24-audit-fixes/b11-evidence-policy-gives-true-verdicts.md
# alone: section 4's A57 to A80 over fixture F6, with B20 and B21 for what each means. No engine code was
# read; felix_evidence_check and felix_table_check are driven as black boxes. This part ships with change A
# of the contract's section 7, the new engine/harness/templates/evidence.tsv, and is red on the template
# that change replaces; its controls (A58 and A74 to A80) hold on both.
#
# Each case is a fresh repository built as F1 builds one: main holds README and every file the change
# deletes, and work, one commit on top, adds each +PATH and deletes each -PATH. The policy directory holds
# a byte copy of the template of the tree under test, and the check runs as F1 runs it (base main, cwd the
# repository, stdin /dev/null). A case's assertion is every line the check printed, as name=status in the
# order printed, against the template's rows in file order with the verdict the contract names, or n/a for
# a row it does not name: so a missing, extra or reordered line fails the case as a wrong verdict does.

B11T="$TMP/b11t"; mkdir -p "$B11T/p"
_b11t_tpl="$REAL_HARNESS/templates/evidence.tsv"
cp "$_b11t_tpl" "$B11T/p/evidence.tsv" 2>/dev/null
# The template's row names in file order, comment and empty lines aside.
_b11t_names="$(LC_ALL=C awk -F'\t' '/^#/ || $0 == "" { next } { printf "%s%s", s, $1; s = " " }' "$_b11t_tpl" 2>/dev/null)"
_b11t_n=0
# SPEC...: a fresh repository in _b11t_G: main holds README and each -PATH, and work, one commit on top,
# adds each +PATH and deletes each -PATH.
_b11t_g() {
  local s p
  _b11t_n=$((_b11t_n + 1)); _b11t_G="$B11T/g$_b11t_n"; mkdir -p "$_b11t_G"; printf 'a readme\n' > "$_b11t_G/README"
  for s in "$@"; do case "$s" in -*) p="$_b11t_G/${s#-}"; mkdir -p "$(dirname "$p")"; printf 'x\n' > "$p" ;; esac; done
  ( _fx_cd "$_b11t_G" && git init -q -b main && git add -A && git -c user.name=t -c user.email=t@t commit -qm main \
    && git checkout -q -b work ) >/dev/null 2>&1
  for s in "$@"; do
    case "$s" in -*) rm -f "$_b11t_G/${s#-}" ;; +*) p="$_b11t_G/${s#+}"; mkdir -p "$(dirname "$p")"; printf 'x\n' > "$p" ;; esac
  done
  ( _fx_cd "$_b11t_G" && git add -A && git -c user.name=t -c user.email=t@t commit -qm work ) >/dev/null 2>&1
  _b11t_G="$(cd "$_b11t_G" && pwd -P)"
}
_b11t_chk() { ( cd "$_b11t_G" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/evidence.sh"
                felix_evidence_check "$B11T/p" main "$_b11t_G" ) </dev/null 2>/dev/null; }
# NAME VERDICTS SPEC...: one assertion that the check over the change SPEC reads VERDICTS ("unit=met
# api=met") for the rows named and n/a for every other row of the template, one line each, in file order.
_b11t_case() {
  local n="$1" want="$2" w="" r v
  shift 2
  _b11t_g "$@"
  for r in $_b11t_names; do
    v="n/a"
    case " $want " in *" $r="*) v="${want#*"$r="}"; v="${v%% *}" ;; esac
    w="$w$r=$v "
  done
  [ -n "$w" ] || w="(the template holds no row)"
  is "$n" "$(_b11t_chk | LC_ALL=C awk -F'\t' '{ printf "%s=%s ", $2, $1 }')" "$w"
}

_b11t_case "b11 A57: a Go handler with its _test.go beside it meets unit and api" "unit=met api=met" \
           +internal/handlers/auth.go +internal/handlers/auth_test.go
_b11t_case "b11 A58: a Go handler with no test gaps unit and api (control)" "unit=gap api=gap" +internal/handlers/auth.go
_b11t_case "b11 A59: a TypeScript module with its .test.ts beside it meets unit" "unit=met" \
           +src/auth/session.ts +src/auth/session.test.ts
_b11t_case "b11 A60: and with its test in a __tests__ directory beside it" "unit=met" \
           +src/auth/session.ts +src/auth/__tests__/session.test.ts
_b11t_case "b11 A61: a Python package with tests/test_*.py inside it meets unit" "unit=met" +src/pkg/core.py +src/pkg/tests/test_core.py
_b11t_case "b11 A62: a Rust crate under crates/*/src with an integration test meets unit, not n/a" "unit=met" \
           +crates/core/src/lib.rs +crates/core/tests/it.rs
_b11t_case "b11 A63: and with no test file gaps unit, never n/a" "unit=gap" +crates/core/src/lib.rs
_b11t_case "b11 A64: deleting code under packages/*/src gaps unit, not n/a everywhere" "unit=gap" \
           -packages/server/src/middleware/ratelimit.ts
_b11t_case "b11 A65: deleting code under apps/api/src gaps unit and api" "unit=gap api=gap" -apps/api/src/middleware/ratelimit.ts
_b11t_case "b11 A66: a README under tests/ is no test, so code beside it gaps unit" "unit=gap" +src/auth/session.ts +tests/README.md
_b11t_case "b11 A67: code under agents/src gaps unit" "unit=gap" +agents/src/a.ts
_b11t_case "b11 A68: a Go command under cmd/ gaps unit" "unit=gap" +cmd/server/main.go
_b11t_case "b11 A69: Java under src/main with its test under src/test meets unit" "unit=met" \
           +src/main/java/com/x/Foo.java +src/test/java/com/x/FooTest.java
_b11t_case "b11 A70: a migration with a store_test.go meets unit and database" "unit=met database=met" \
           +migrations/001.sql +internal/db/store_test.go
_b11t_case "b11 A71: a Dockerfile under services/api gaps config and is no api change" "config=gap" +services/api/Dockerfile
_b11t_case "b11 A72: a component under apps/web/src gaps unit and e2e" "unit=gap e2e=gap" +apps/web/src/components/Button.tsx
_b11t_case "b11 A73: a README under tests/api proves neither unit nor api" "unit=gap api=gap" +src/api/users.ts +tests/api/README.md
_b11t_case "b11 A74: code with its test under tests/ meets unit (control)" "unit=met" +src/thing.js +tests/thing.test.js
_b11t_case "b11 A75: a Rails model with its spec meets unit (control)" "unit=met" +app/models/user.rb +spec/models/user_spec.rb
_b11t_case "b11 A76: an api module with its api test meets unit and api (control)" "unit=met api=met" \
           +src/api/users.ts +tests/api/users.test.ts
_b11t_case "b11 A77: a migration with no test gaps database (control)" "database=gap" +migrations/001.sql
_b11t_case "b11 A78: a README alone touches no surface (control)" "" +README.md
_b11t_case "b11 A79: a page under book/src is not code (control)" "" +book/src/chapter.md

# B21: the template is a valid table, its five rows by name, and every when and requires cell compiles.
_b11t_tc="$( . "$FROOT/harness/lib/table.sh" 2>/dev/null
             felix_table_check "$REAL_HARNESS/templates/schemas.tsv" "$_b11t_tpl" </dev/null 2>&1; printf '|rc=%s' "$?" )"
_b11t_bad=""
while IFS= read -r _b11t_c; do
  LC_ALL=C grep -E -e "$_b11t_c" </dev/null >/dev/null 2>&1; _b11t_r=$?
  [ "$_b11t_r" -eq 1 ] || _b11t_bad="$_b11t_bad [$_b11t_c] exits $_b11t_r;"
done < <(LC_ALL=C awk -F'\t' '/^#/ || $0 == "" { next } { print $2; print $3 }' "$_b11t_tpl" 2>/dev/null)
is "b11 A80: the template passes felix_table_check silently, holds unit database e2e api config in that order, and every when and requires cell compiles (control)" \
   "table check [$_b11t_tc], rows [$_b11t_names], cells [${_b11t_bad:-every one compiles}]" \
   "table check [|rc=0], rows [unit database e2e api config], cells [every one compiles]"
unset -f _b11t_g _b11t_chk _b11t_case
