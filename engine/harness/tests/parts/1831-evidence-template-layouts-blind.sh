printf '\nthe seeded evidence template gives true verdicts for the layouts it names (audit b11, blind)\n'
# Blind, written on 2026-10-24 from docs/2026-10-24-audit-fixes/b11-evidence-policy-gives-true-verdicts.md
# alone: section 4's A57 to A80 over fixture F6, with B20 and B21 for what each means. No engine code was
# read; felix_evidence_check and felix_table_check are driven as black boxes. This part ships with change A
# of the contract's section 7, the new engine/harness/templates/evidence.tsv, and is red on the template
# that change replaces; its controls (A58 and A74 to A80) hold on both. A81 to A108, at the end, are the
# review round's (B22 and B23), red on the template change A ships until the review fix. Round 3
# (docs/2026-10-24-audit-fixes/b11-round-3.md, 2026-10-28, blind) rewrote A101 to A107, which set nothing
# aside now, and added A150 and A151; its other assertions are part 1832's.
#
# Each case is a fresh repository built as F1 builds one: main holds README, every file the change
# deletes and every =PATH, and work, one commit on top, adds each +PATH and deletes each -PATH. Every file
# holds its own path (a go.mod a module line), so no deletion and addition pair up as a rename. A
# VENDORED line the case expects (_b11t_vend) is read last, with its reason. The policy directory holds
# a byte copy of the template of the tree under test, and the check runs as F1 runs it (base main, cwd the
# repository, stdin /dev/null). A case's assertion is every line the check printed, as name=status in the
# order printed, against the template's rows in file order with the verdict the contract names, or n/a for
# a row it does not name: so a missing, extra or reordered line fails the case as a wrong verdict does.

B11T="$TMP/b11t"; mkdir -p "$B11T/p"
_b11t_tpl="$REAL_HARNESS/templates/evidence.tsv"
cp "$_b11t_tpl" "$B11T/p/evidence.tsv" 2>/dev/null
# The template's row names in file order, comment and empty lines aside.
_b11t_names="$(LC_ALL=C awk -F'\t' '/^#/ || $0 == "" { next } { printf "%s%s", s, $1; s = " " }' "$_b11t_tpl" 2>/dev/null)"
_b11t_n=0; _b11t_vend=""
# PATH: $_b11t_G/PATH written, holding its own path, or a module line for a go.mod.
_b11t_w() {
  mkdir -p "$(dirname "$_b11t_G/$1")"
  case "$1" in go.mod|*/go.mod) printf 'module example.com/b11t\n' > "$_b11t_G/$1" ;; *) printf '%s\n' "$1" > "$_b11t_G/$1" ;; esac
}
# SPEC...: a fresh repository in _b11t_G: main holds README and each -PATH and =PATH, and work, one commit
# on top, adds each +PATH and deletes each -PATH.
_b11t_g() {
  local s
  _b11t_n=$((_b11t_n + 1)); _b11t_G="$B11T/g$_b11t_n"; mkdir -p "$_b11t_G"; printf 'a readme\n' > "$_b11t_G/README"
  for s in "$@"; do case "$s" in -*|=*) _b11t_w "${s#?}" ;; esac; done
  ( _fx_cd "$_b11t_G" && git init -q -b main && git add -A && git -c user.name=t -c user.email=t@t commit -qm main \
    && git checkout -q -b work ) >/dev/null 2>&1
  for s in "$@"; do
    case "$s" in -*) rm -f "$_b11t_G/${s#-}" ;; +*) _b11t_w "${s#+}" ;; esac
  done
  ( _fx_cd "$_b11t_G" && git add -A && git -c user.name=t -c user.email=t@t commit -qm work ) >/dev/null 2>&1
  _b11t_G="$(cd "$_b11t_G" && pwd -P)"
}
_b11t_chk() { ( cd "$_b11t_G" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/evidence.sh"
                felix_evidence_check "$B11T/p" main "$_b11t_G" ) </dev/null 2>/dev/null; }
# NAME VERDICTS SPEC...: one assertion that the check over the change SPEC reads VERDICTS ("unit=met
# api=met") for the rows named and n/a for every other row of the template, one line each, in file order;
# then, when _b11t_vend is set (and it is cleared), one line n/a VENDORED with that reason, else none.
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
  [ -z "$_b11t_vend" ] || w="${w}VENDORED=n/a[$_b11t_vend] "
  _b11t_vend=""
  is "$n" "$(_b11t_chk | LC_ALL=C awk -F'\t' '$2 == "VENDORED" { printf "%s=%s[%s] ", $2, $1, $3; next } { printf "%s=%s ", $2, $1 }')" "$w"
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

# ---- Review round: B22 and B23, A81 to A108; round 3: A101 to A107, A150, A151 ------------------------
# Blind, written on 2026-10-26 from the contract's "Review round" section alone, over F6 as above. The
# controls (A100, A108) hold on the branch as built; every other assertion here fails on the template
# change A ships. Round 3's (2026-10-28, from b11-round-3.md section 4 alone): A151 is a control on
# d1f2cdc1; A101 to A107 and A150 fail there.
printf '\n  review round: code in any language is code; round 3: vendored code is set aside only where project.json or a root go.mod says so\n'
# B22: a code file under a code directory gaps unit without a test, whatever its language.
_b11t_case "b11 A81: a C header under src/ with no test gaps unit, not n/a on every row" "unit=gap" +src/foo.h
_b11t_case "b11 A82: a C++ header under src/ with no test gaps unit" "unit=gap" +src/foo.hpp
_b11t_case "b11 A83: Objective-C under src/ with no test gaps unit" "unit=gap" +src/Foo.m
_b11t_case "b11 A84: Lua under src/ with no test gaps unit" "unit=gap" +src/foo.lua
_b11t_case "b11 A85: Haskell under src/ with no test gaps unit" "unit=gap" +src/foo.hs
_b11t_case "b11 A86: OCaml under src/ with no test gaps unit" "unit=gap" +src/foo.ml
_b11t_case "b11 A87: Zig under src/ with no test gaps unit" "unit=gap" +src/foo.zig
_b11t_case "b11 A88: a Kotlin script under src/ with no test gaps unit" "unit=gap" +src/foo.kts
_b11t_case "b11 A89: Erlang, a language neither the template nor the review names, gaps unit" "unit=gap" +src/a.erl
_b11t_case "b11 A90: Clojure under src/ gaps unit" "unit=gap" +src/a.clj
_b11t_case "b11 A91: Julia under src/ gaps unit" "unit=gap" +src/a.jl
_b11t_case "b11 A92: C++ spelled .cxx under src/ gaps unit" "unit=gap" +src/a.cxx
_b11t_case "b11 A93: a C header at depth, under packages/*/src, gaps unit" "unit=gap" +packages/core/src/foo.h
# B22: and the same file with a test in its own language meets unit, so no false gap comes back.
_b11t_case "b11 A94: a C++ header with its test under tests/ meets unit" "unit=met" +src/foo.hpp +tests/foo_test.cpp
_b11t_case "b11 A95: Objective-C with its FooTests.m beside it meets unit" "unit=met" +src/Foo.m +src/FooTests.m
_b11t_case "b11 A96: Lua with its spec under spec/ meets unit" "unit=met" +src/foo.lua +spec/foo_spec.lua
_b11t_case "b11 A97: Haskell with its spec under test/ meets unit" "unit=met" +src/Foo.hs +test/FooSpec.hs
_b11t_case "b11 A98: OCaml with its test under test/ meets unit" "unit=met" +src/foo.ml +test/test_foo.ml
_b11t_case "b11 A99: a Terraform variables file gaps config, not n/a" "config=gap" +infra/main.tfvars
_b11t_case "b11 A100: a README under src/ is still no code, so every row reads n/a (control)" "" +src/README.md
# B23 as round 3 left it (b11-round-3.md, B11R3-1): with no project.json and no go.mod in the base,
# nothing is set aside by its name alone, so each of these changes fires the rows it matches.
_b11t_case "B11R3 A101: with no go.mod in the base, vendored Go under vendor/ is not set aside, so it gaps unit" "unit=gap" \
           +vendor/github.com/x/y/pkg/z.go
_b11t_case "B11R3 A102: C under third_party/lib, with nothing declared, gaps unit" "unit=gap" +third_party/lib/a.c
_b11t_case "B11R3 A103: a package under node_modules, with nothing declared, gaps unit" "unit=gap" +node_modules/a/lib/index.js
_b11t_case "B11R3 A104: a vendor bump of github.com/pkg/errors with no go.mod in the base gaps unit" "unit=gap" \
           -vendor/github.com/pkg/errors/go113.go +vendor/github.com/pkg/errors/errors.go +vendor/modules.txt
_b11t_case "B11R3 A105: a vendored module's internal/ and cmd/ directories, with no go.mod in the base, gap unit" "unit=gap" \
           +vendor/golang.org/x/text/internal/tag/tag.go +vendor/example.com/tool/cmd/tool/main.go
_b11t_case "B11R3 A106: vendored handlers and components, with nothing declared, gap unit, e2e and api" \
           "unit=gap e2e=gap api=gap" +vendor/github.com/gorilla/handlers/cors.go +third_party/ui/src/components/Button.tsx
_b11t_case "B11R3 A107: a nested module's vendor directory, with no go.mod at the root, gaps unit" "unit=gap" \
           +services/auth/vendor/github.com/pkg/errors/errors.go
_b11t_case "b11 A108: vendored code beside the project's own untested handler hides nothing: unit and api gap (control)" \
           "unit=gap api=gap" +vendor/github.com/pkg/errors/errors.go +internal/handlers/auth.go
# Round 3: M2's bump under a go.mod at the root of the base (B11R3-3, B11R3-6, B11R3-12), and a vendored
# test that proves nothing (B11R3-4).
_b11t_vend="3 changed path(s) set aside as vendored, under vendor/, so no rule read them"
_b11t_case "B11R3 A150: M2's go mod vendor bump under a go.mod at the root of the base reads n/a on every row, then one VENDORED line counting 3 under vendor/" \
           "" =go.mod -vendor/github.com/pkg/errors/go113.go +vendor/github.com/pkg/errors/errors.go +vendor/modules.txt
_b11t_case "B11R3 A151: a vendored _test.go proves nothing, so the project's own untested handler beside it gaps unit and api (control)" \
           "unit=gap api=gap" +internal/handlers/auth.go +vendor/github.com/pkg/errors/errors_test.go
unset -f _b11t_w _b11t_g _b11t_chk _b11t_case
