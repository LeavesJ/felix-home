# >>> b19-detection-slug-and-lookups
printf '\naudit b19: detection below the root, one reading of the GitHub slug, and lookups that cannot end in done (A23-A48, blind)\n'
# Blind, written on 2026-10-24 from docs/2026-10-24-audit-fixes/b19-capability-detection-and-omission-
# surfac.md alone (sections 2 to 5): no engine code was read. One assertion per contract item, named by the
# sentence it proves and tagged with the item; one marked (control) holds before the fix and after it.
#
# Fixtures (A0): git through _fx_git and _fx_cd under $TMP; lib calls in a fresh /bin/bash standing in the
# checkout, with a home of its own, sourcing lib/resolve.sh and then the libs named, from $FROOT/harness
# (or from a harness copy where the item says so); project directories $TMP/b19/<name>, each name used
# once; the gh and ssh stubs from _fsgh_build. Readings where the contract leaves room, mine:
# - Each A23 to A29 fixture is a repository of its own with every file committed (A27's ignored
#   Dockerfile apart); detection is compared sorted and space-joined, duplicates kept.
# - A32 reads the slug's stdout with each newline as |, so "acme/app|rc=0|" is the slug, its newline and
#   status 0, and "rc=0|" is nothing. A33 asserts no ssh line for the rows it names and exactly one line,
#   naming work, for the alias; the gitlab rows and no origin are asserted neither way.
# - A36 to A38 run classify with GIT_ALLOW_PROTOCOL=file, so no fetch it might make reaches a network.
# - A41 evals the preflight row's field 6 in that fresh bash, with the ready libs sourced.
# - A47 and A48 use a project under the fixture home (the hook reads HOME/projects), removed at the end.
# Every part runs alone: this one builds its own checkouts and relies on the prelude only.
_cmstub_build; _fsgh_build
B91="$TMP/b19"; B91R="$TMP/b19dr"; mkdir -p "$B91/home" "$B91R"
_b91T="$(printf '\t')"
_b91_h="$FROOT/harness"; _b91_path=""
# DIR LIBS SCRIPT ARGS...: SCRIPT in a fresh /bin/bash standing in DIR, HOME the fixture's, after
# lib/resolve.sh and each lib in LIBS from $_b91_h; ARGS are its $1...; $_b91_path goes first on PATH.
_b91_sh() {
  local _b91d="$1" _b91l="$2" _b91s="$3"; shift 3
  ( cd "$_b91d" || exit 125
    [ -z "$_b91_path" ] || PATH="$_b91_path:$PATH"
    HOME="$B91/home" /bin/bash -c '_h="$1"; _l="$2"; _s="$3"; shift 3; . "$_h/lib/resolve.sh"
      for _x in $_l; do . "$_h/lib/$_x.sh"; done; eval "$_s"' _b91 "$_b91_h" "$_b91l" "$_b91s" "$@" ) 2>/dev/null
}
_b91_git() { _fx_git "$@" >/dev/null 2>&1; }   # DIR ARGS...: a fixture git command, quiet
_b91_repo() { mkdir -p "$1"; _b91_git "$1" init -q -b main && _b91_git "$1" add -A \
              && _b91_git "$1" -c user.name=t -c user.email=t@t commit -qm m; }   # DIR: all of DIR committed
_b91_put() { mkdir -p "$(dirname "$1/$2")"; printf '%s\n' "$3" > "$1/$2"; }   # ROOT PATH TEXT
_b91_fx() { _b91r="$B91R/$1"; rm -rf "$_b91r"; mkdir -p "$_b91r"; }   # NAME: a fresh fixture directory, in _b91r
_b91_det() { _b91_sh "$1" detect 'felix_detect "$1"' "$1" | LC_ALL=C sort | paste -sd' ' -; }   # ROOT: detected, sorted, space-joined
_b91_has() { printf '%s\n' "$1" | LC_ALL=C awk -v c="$2" '{ for (i = 1; i <= NF; i++) if ($i == c) f = 1 } END { print (f ? "yes" : "no") }'; }   # WORDS WORD
_b91_in() { printf '%s\n' "$1" | LC_ALL=C awk -v l="$2" 'index($0, l) { f = 1 } END { print (f ? "yes" : "no") }'; }   # OUTPUT TEXT

# ---- D: detection (A23 to A31) ------------------------------------------------------------------------
_b91v=""
_b91_fx mono; _b91_put "$_b91r" package.json '{"name":"mono","private":true,"workspaces":["apps/*"]}'
_b91_put "$_b91r" apps/api/package.json '{"name":"svc","dependencies":{"express":"^4.19.0","stripe":"^17.0.0","@sentry/node":"^8.0.0","pg":"^8.11.0","openai":"^4.0.0"}}'
_b91_put "$_b91r" apps/api/Dockerfile 'FROM scratch'; _b91_put "$_b91r" apps/api/migrations/001.sql 'select 1;'
_b91_repo "$_b91r"; _b91v="$_b91v mono=[$(_b91_det "$_b91r")]"
_b91_fx rails; _b91_put "$_b91r" Gemfile $'gem "rails"\ngem "pg"\ngem "devise"\ngem "rack-attack"\ngem "stripe"'
_b91_put "$_b91r" db/migrate/1_init.rb 'class Init; end'; _b91_put "$_b91r" test/t.rb 'true'
_b91_repo "$_b91r"; _b91v="$_b91v rails=[$(_b91_det "$_b91r")]"
_b91_fx go; _b91_put "$_b91r" go.mod $'module example.com/gosvc\n\ngo 1.22\n\nrequire (\n\tgithub.com/gin-gonic/gin v1.10.0\n\tgithub.com/jackc/pgx/v5 v5.6.0\n)'
_b91_repo "$_b91r"; _b91v="$_b91v go=[$(_b91_det "$_b91r")]"
_b91_fx spring; _b91_put "$_b91r" pom.xml $'<project>\n  <modelVersion>4.0.0</modelVersion>\n  <groupId>com.example</groupId>\n  <artifactId>svc</artifactId>\n  <version>1</version>\n  <dependencies>\n    <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-web</artifactId></dependency>\n    <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-security</artifactId></dependency>\n  </dependencies>\n</project>'
_b91_repo "$_b91r"; _b91v="$_b91v spring=[$(_b91_det "$_b91r")]"
_b91_fx hono; _b91_put "$_b91r" package.json '{"name":"h","dependencies":{"hono":"^4.0.0","drizzle-orm":"^0.30.0"}}'
_b91_repo "$_b91r"; _b91v="$_b91v hono=[$(_b91_det "$_b91r")]"
_b91_fx cargo; _b91_put "$_b91r" crates/web/Cargo.toml $'[package]\nname = "web"\nversion = "0.1.0"\n\n[dependencies]\naxum = "0.7"\nsqlx = { version = "0.7" }\ngovernor = "0.6"\njsonwebtoken = "9"'
_b91_repo "$_b91r"; _b91v="$_b91v cargo=[$(_b91_det "$_b91r")]"
_b91_fx python; _b91_put "$_b91r" requirements.txt $'fastapi\nasyncpg>=0.29\nslowapi\nPyJWT[crypto]'
_b91_repo "$_b91r"; _b91v="$_b91v python=[$(_b91_det "$_b91r")]"
_b91_fx dotnet; _b91_put "$_b91r" src/Api/Api.csproj $'<Project Sdk="Microsoft.NET.Sdk.Web">\n  <ItemGroup>\n    <PackageReference Include="Npgsql" Version="8.0.0" />\n    <PackageReference Include="AspNetCoreRateLimit" Version="5.0.0" />\n    <PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="8.0.0" />\n  </ItemGroup>\n</Project>'
_b91_repo "$_b91r"; _b91v="$_b91v dotnet=[$(_b91_det "$_b91r")]"
_b91_fx php; _b91_put "$_b91r" composer.json '{"require":{"laravel/framework":"^11.0","laravel/sanctum":"^4.0"}}'
_b91_put "$_b91r" database/migrations/0001_init.php '<?php'
_b91_repo "$_b91r"; _b91v="$_b91v php=[$(_b91_det "$_b91r")]"
is "b19 A23: manifests below the root and the new dependency names give api, auth, database, ratelimit and their neighbours for a monorepo, Rails, Go, Spring, Hono, Cargo, Python, .NET and PHP" \
   "$_b91v" " mono=[api billing database deploy llm observability] rails=[api auth billing database ratelimit tests] go=[api database] spring=[api auth] hono=[api database] cargo=[api auth database ratelimit rust] python=[api auth database ratelimit] dotnet=[api auth database ratelimit] php=[api auth database]"

_b91_fx bare; _b91_put "$_b91r" package.json '{"name":"x","scripts":{"verify":"echo ok"}}'; _b91_repo "$_b91r"
is "b19 A24: a package.json that declares no frontend name gives no frontend" "frontend $(_b91_has "$(_b91_det "$_b91r")" frontend)" "frontend no"
_b91_fx react; _b91_put "$_b91r" package.json '{"name":"r","dependencies":{"react":"^18.3.0","react-dom":"^18.3.0"}}'; _b91_repo "$_b91r"
is "b19 A24 (control): a package.json naming react gives frontend" "frontend $(_b91_has "$(_b91_det "$_b91r")" frontend)" "frontend yes"
_b91_fx css; _b91_put "$_b91r" package.json '{"name":"x","scripts":{"verify":"echo ok"}}'
for _b91i in a b c; do _b91_put "$_b91r" "$_b91i.css" 'p { margin: 0 }'; done; _b91_repo "$_b91r"
is "b19 A24 (control): a bare package.json with three committed .css files gives frontend" "frontend $(_b91_has "$(_b91_det "$_b91r")" frontend)" "frontend yes"

_b91_skipped() { _b91_put "$1" node_modules/x/package.json '{"name":"x","dependencies":{"express":"^4.19.0"}}'
                 _b91_put "$1" vendor/y/go.mod $'module example.com/y\n\nrequire github.com/gin-gonic/gin v1.10.0'
                 _b91_put "$1" third_party/z/Gemfile 'gem "rails"'; }
_b91_fx skipr; _b91_skipped "$_b91r"; _b91_git "$_b91r" init -q -b main; _b91_git "$_b91r" add -f -A
_b91_git "$_b91r" -c user.name=t -c user.email=t@t commit -qm m; _b91a="$(_b91_det "$_b91r")"
_b91_fx skipd; _b91_skipped "$_b91r"
is "b19 A25 (control): manifests under node_modules, vendor and third_party give no api, force-added in a repository or in a plain directory" \
   "repository api $(_b91_has "$_b91a" api) | directory api $(_b91_has "$(_b91_det "$_b91r")" api)" "repository api no | directory api no"

_b91v=""
_b91_fx dk; _b91_put "$_b91r" services/w/Dockerfile 'FROM scratch'; _b91_repo "$_b91r"; _b91v="$_b91v deploy $(_b91_has "$(_b91_det "$_b91r")" deploy)"
_b91_fx env; _b91_put "$_b91r" pkg/.env.example 'X=1'; _b91_repo "$_b91r"; _b91v="$_b91v secrets $(_b91_has "$(_b91_det "$_b91r")" secrets)"
_b91_fx mig; _b91_put "$_b91r" app/db/migrate/1_init.rb 'class Init; end'; _b91_repo "$_b91r"; _b91v="$_b91v database $(_b91_has "$(_b91_det "$_b91r")" database)"
_b91_fx crate; _b91_put "$_b91r" crates/x/Cargo.toml $'[package]\nname = "x"\nversion = "0.1.0"'; _b91_repo "$_b91r"; _b91v="$_b91v rust $(_b91_has "$(_b91_det "$_b91r")" rust)"
is "b19 A26: a Dockerfile, a .env.example, a db/migrate file and a Cargo.toml below the root give deploy, secrets, database and rust" \
   "$_b91v" " deploy yes secrets yes database yes rust yes"

_b91v=""
_b91_fx ci; _b91_put "$_b91r" .github/workflows/ci.yml 'on: push'; _b91_repo "$_b91r"; _b91v="$_b91v ci $(_b91_has "$(_b91_det "$_b91r")" ci)"
_b91_fx iac; _b91_put "$_b91r" infra/main.tf 'terraform {}'; _b91_repo "$_b91r"; _b91v="$_b91v iac $(_b91_has "$(_b91_det "$_b91r")" iac)"
_b91_fx tst; _b91_put "$_b91r" tests/t.sh 'true'; _b91_repo "$_b91r"; _b91v="$_b91v tests $(_b91_has "$(_b91_det "$_b91r")" tests)"
_b91_fx k8s; _b91_put "$_b91r" k8s/svc.yaml 'kind: Service'; _b91_repo "$_b91r"; _b91v="$_b91v deploy $(_b91_has "$(_b91_det "$_b91r")" deploy)"
_b91_fx ign; _b91_put "$_b91r" .gitignore 'Dockerfile'; _b91_repo "$_b91r"; _b91_put "$_b91r" Dockerfile 'FROM scratch'
_b91v="$_b91v ignored-deploy $(_b91_has "$(_b91_det "$_b91r")" deploy)"
_b91_fx subci; _b91_put "$_b91r" sub/.github/workflows/ci.yml 'on: push'; _b91_repo "$_b91r"; _b91v="$_b91v sub-ci $(_b91_has "$(_b91_det "$_b91r")" ci)"
_b91_fx subtst; _b91_put "$_b91r" sub/tests/t.sh 'true'; _b91_repo "$_b91r"; _b91v="$_b91v sub-tests $(_b91_has "$(_b91_det "$_b91r")" tests)"
is "b19 A27 (control): ci, iac, tests and deploy are read at the root, an ignored root Dockerfile included, and a workflow or tests directory below it is not" \
   "$_b91v" " ci yes iac yes tests yes deploy yes ignored-deploy yes sub-ci no sub-tests no"

_b91_fx once; _b91_put "$_b91r" package.json '{"name":"p","dependencies":{"prisma":"^5.0.0"}}'; _b91_put "$_b91r" migrations/1.sql 'select 1;'
_b91_repo "$_b91r"
is "b19 A28: a capability found by two rules is printed once" \
   "$(_b91_sh "$_b91r" detect 'felix_detect "$1"' "$_b91r" | LC_ALL=C awk '$0 == "database" { n++ } END { print n + 0 }')" "1"

_b91v=""
_b91_fx pgt; _b91_put "$_b91r" package.json '{"name":"t","dependencies":{"pgtools":"^1.0.0"}}'; _b91_repo "$_b91r"; _b91a="$(_b91_det "$_b91r")"
_b91v="$_b91v pgtools=$(_b91_has "$_b91a" database)$(_b91_has "$_b91a" api)"
_b91_fx pgs; _b91_put "$_b91r" Gemfile 'gem "pg_search"'; _b91_repo "$_b91r"; _b91a="$(_b91_det "$_b91r")"
_b91v="$_b91v pg_search=$(_b91_has "$_b91a" database)$(_b91_has "$_b91a" api)"
_b91_fx wg; _b91_put "$_b91r" Cargo.toml $'[package]\nname = "t"\nversion = "0.1.0"\n\n[dependencies]\nwarpgate = "1"'; _b91_repo "$_b91r"; _b91a="$(_b91_det "$_b91r")"
_b91v="$_b91v warpgate=$(_b91_has "$_b91a" database)$(_b91_has "$_b91a" api)"
_b91_fx pool; _b91_put "$_b91r" requirements.txt 'psycopg-pool'; _b91_repo "$_b91r"; _b91a="$(_b91_det "$_b91r")"
_b91v="$_b91v psycopg-pool=$(_b91_has "$_b91a" database)$(_b91_has "$_b91a" api)"
is "b19 A29 (control): pgtools, pg_search, warpgate and psycopg-pool are not the names they begin with, so none gives database or api" \
   "$_b91v" " pgtools=nono pg_search=nono warpgate=nono psycopg-pool=nono"

_b91gs="$B91/gitstub"; mkdir -p "$_b91gs"
printf '#!/bin/sh\nfor a in "$@"; do\n  if [ "$a" = ls-files ]; then exit 1; fi\ndone\nexec %s "$@"\n' "'$(command -v git)'" > "$_b91gs/git"
chmod +x "$_b91gs/git"
_b91_fx lsfail; _b91_put "$_b91r" .env.example 'X=1'; _b91_repo "$_b91r"
mkdir -p "$B91/b19a30" "$MEM/b19a30"
_b91_path="$_b91gs"
_b91v="$(_b91_sh "$_b91r" "detect probes facts obligations procedures" '
  felix_detect "$1" >/dev/null; a=$?
  _felix_capability_union "$1" "" >/dev/null; b=$?; [ "$b" -eq 0 ] || b=nonzero
  o="$(felix_undeclared "$1" "$2")"; c=$?
  felix_procedures_items "$2" "$1" >/dev/null; d=$?
  printf "detect %s, union %s, undeclared %s [%s], procedures %s" "$a" "$b" "$c" "$o" "$d"' "$_b91r" "$B91/b19a30")"
_b91_path=""
is "b19 A30: when git cannot list the checkout detection returns 2 and its callers fail closed: the union, felix_undeclared and felix_procedures_items" \
   "$_b91v" "detect 2, union nonzero, undeclared 2 [], procedures 2"
_b91a="$(cd "$REAL_HARNESS/../.." && pwd)"
is "b19 A31 (control): Felix's own tree still detects as exactly ci" "$(_b91_sh "$_b91a" detect 'felix_detect "$1"' "$_b91a")" "ci"

# ---- S: the GitHub slug (A32 to A38) --------------------------------------------------------------------
_b91s="$B91R/slug"; mkdir -p "$_b91s"; _b91_git "$_b91s" init -q -b main
_b91D="$B91/slugd"
# URL, or - for no origin: _b91so is the slug's stdout with each newline as |, then rc=N|; _b91sl the ssh log.
_b91_slug() {
  if [ "$1" = - ]; then _b91_git "$_b91s" config --unset remote.origin.url; else _b91_git "$_b91s" config remote.origin.url "$1"; fi
  : > "$_fs_sshlog"; _b91_path="$_fs_gh"
  _b91so="$(_b91_sh "$_b91s" detect 'felix_repo_slug "$1"; printf "rc=%s\n" "$?"' "$_b91s" | LC_ALL=C tr '\n' '|')"
  _b91_path=""; _b91sl="$(cat "$_fs_sshlog" 2>/dev/null)"
}
_b91u=( 'git@github.com:acme/app.git' 'https://github.com/acme/app.git' 'https://github.com/acme/app/' 'https://www.github.com/acme/app'
        'ssh://git@ssh.github.com:443/acme/app.git' 'git@work:acme/app.git' 'git@gitlab-alias:acme/app.git' 'git@gitlab.com:acme/app.git'
        'https://gitlab.com/acme/app.git' 'https://github.acme.com/acme/app.git' 'https://github.com/acme/app/tree' '/srv/git/app.git'
        "$_b91D/github.com/fixture/lgh.git" "file://$_b91D/github.com/fixture/lgh.git" "$_b91D/github.com/fixture/ta${_b91T}by.git" - )
_b91e=( acme/app acme/app acme/app acme/app acme/app acme/app '' '' '' '' '' '' fixture/lgh fixture/lgh '' '' )
_b91q=( n n n n n w x x n n n n n n n x )   # ssh: n runs it never, w once naming work, x is not asserted
_b91a=""; _b91x=""; _b91sv=""; _b91w=""; _b91i=0
while [ "$_b91i" -lt "${#_b91u[@]}" ]; do
  _b91_slug "${_b91u[$_b91i]}"; _b91n="$((_b91i + 1))"
  _b91a="$_b91a $_b91n=$_b91so"; _b91x="$_b91x $_b91n=${_b91e[$_b91i]:+${_b91e[$_b91i]}|}rc=0|"
  if [ "${_b91q[$_b91i]}" = n ] && [ -n "$_b91sl" ]; then _b91sv="$_b91sv [row $_b91n ran ssh: $_b91sl]"; fi
  if [ "${_b91q[$_b91i]}" = w ]; then
    _b91w="$(printf '%s\n' "$_b91sl" | LC_ALL=C awk 'NF { n++; if (index($0, "work")) w++ } END { print n + 0 " line(s), " w + 0 " naming work" }')"
  fi
  _b91i="$((_b91i + 1))"
done
is "b19 A32: felix_repo_slug prints O/N and a newline only for a github.com remote, an ssh alias for one, or a local path ending github.com/O/N, and exits 0 for every origin" \
   "$_b91a" "$_b91x"
is "b19 A33: ssh -G is never run for https, path, file, github.com or ssh.github.com remotes, and is run once for the work alias" \
   "silent:${_b91sv:- none ran ssh}; alias: $_b91w" "silent: none ran ssh; alias: 1 line(s), 1 naming work"
_b91_slug -
is "b19 A34 (control): with no origin felix_repo_slug prints nothing and exits 0" "$_b91so" "rc=0|"
is "b19 A35: felix holds no line reading the slug with its own github.com pattern" \
   "$(LC_ALL=C grep -cF 'github\.com[:/]##' "$FROOT/harness/felix" 2>/dev/null)" "0"

_b91wc="$B91R/wck"; mkdir -p "$_b91wc"; printf 'widget\n' > "$_b91wc/.felix"; printf 'contents\n' > "$_b91wc/WIDGET.txt"
_b91_repo "$_b91wc"; _b91wc="$(cd "$_b91wc" && pwd -P)"
_b91rk=""; [ -f "$FROOT/projects/widget/risk.tsv" ] || { cp "$REAL_HARNESS/templates/risk.tsv" "$FROOT/projects/widget/risk.tsv"; _b91rk=1; }
# URL: origin set to URL, then felix classify --base HEAD~0 --apply in the widget checkout, stubs first on PATH:
# _b91co its output, _b91crc its status, _b91cn the lines it added to the gh log, _b91ck whether the log is unchanged.
_b91_cls() {
  local _b91n0 _b91k0
  _b91_git "$_b91wc" config remote.origin.url "$1"
  _b91n0="$(LC_ALL=C awk 'END { print NR }' "$_fs_ghlog" 2>/dev/null)"; _b91k0="$(cksum < "$_fs_ghlog" 2>/dev/null)"
  _b91co="$( cd "$_b91wc" && HOME="$B91/home" GIT_ALLOW_PROTOCOL=file PATH="$_fs_path" "$FELIX" classify --base HEAD~0 --apply 2>&1 )"; _b91crc=$?
  _b91cn="$(LC_ALL=C awk -v n="${_b91n0:-0}" 'NR > n' "$_fs_ghlog" 2>/dev/null)"
  _b91ck=changed; [ "$(cksum < "$_fs_ghlog" 2>/dev/null)" != "$_b91k0" ] || _b91ck=unchanged
}
# An uncommitted edit to a tracked file, so there is a change against HEAD~0 to classify and label.
printf 'changed\n' > "$_b91wc/WIDGET.txt"
_b91_cls 'git@gitlab.com:acme/app.git'; _b91a=nonzero; [ "$_b91crc" -ne 0 ] || _b91a=0
is "b19 A36: classify --apply over a GitLab origin exits non-zero, says no github remote; cannot label, and runs no gh" \
   "exit $_b91a, said $(_b91_in "$_b91co" 'no github remote; cannot label'), gh log $_b91ck" "exit nonzero, said yes, gh log unchanged"
_b91_cls 'git@work:acme/app.git'
is "b19 A37: classify --apply over an ssh alias for github.com calls gh with --repo acme/app" "$(_b91_in "$_b91cn" '--repo acme/app')" "yes"
_b91_cls 'https://github.com/acme/app.git'
is "b19 A38 (control): classify --apply over a github.com https origin calls gh with --repo acme/app" "$(_b91_in "$_b91cn" '--repo acme/app')" "yes"
_b91_git "$_b91wc" config --unset remote.origin.url; printf 'contents\n' > "$_b91wc/WIDGET.txt"
[ -z "$_b91rk" ] || rm -f "$FROOT/projects/widget/risk.tsv"

# ---- L: lookups that cannot end in done (A39 to A48) ------------------------------------------------------
_b91_rl="detect stack admit verify route toolbox ledger deny monitor ready discover"
_b91_proj() { mkdir -p "$B91/$1" "$MEM/$1"; printf '{"name":"%s","gate":"true"}\n' "$1" > "$B91/$1/project.json"; }   # NAME
_b91why="unknown${_b91T}routes.tsv${_b91T}the plays this project's routes name could not be read whole, so no tool was checked"
_b91pf="$(LC_ALL=C awk -F'\t' '$1 == "preflight" && !f { print $6; f = 1 }' "$FROOT/harness/templates/commissioning.tsv")"
_b91_pre() { _b91_path="$CMSTUB"; _b91a="$(_b91_sh "$B91" "$_b91_rl" 'FELIX_PROJECT="$1"; export FELIX_PROJECT; eval "$2"; printf "%s" "$?"' "$1" "$_b91pf")"; _b91_path=""
             [ -z "$_b91a" ] || [ "$_b91a" = 0 ] || _b91a=nonzero; printf '%s' "${_b91a:-not run}"; }   # PROJ: the preflight check's exit
_b91_proj b19rd1; mkdir -p "$B91/b19rd1/routes.tsv"
_b91_path="$CMSTUB"
_b91v="$(_b91_sh "$B91" "$_b91_rl" 'felix_ready_wanted "$1" >/dev/null; a=$?; o="$(felix_ready_report "$1")"; printf "wanted %s | report %s | %s" "$a" "$?" "$o"' "$B91/b19rd1")"
_b91_path=""
is "b19 A39: with routes.tsv a directory felix_ready_wanted returns 2 and felix_ready_report prints exactly the unknown routes.tsv row and returns 2" \
   "$_b91v" "wanted 2 | report 2 | $_b91why"
_b91_proj b19rd2; _b91_path="$CMSTUB"
_b91v="$(_b91_sh "$B91" "$_b91_rl" 'felix_ready_wanted() { printf "some-skill\n"; return 1; }; o="$(felix_ready_report "$1")"; printf "%s | %s" "$?" "$o"' "$B91/b19rd2")"
_b91_path=""
is "b19 A40: a wanted list that is not whole gives exactly the unknown routes.tsv row, no row for what it did print, and status 2" \
   "$_b91v" "2 | $_b91why"
is "b19 A41: the preflight check of the commissioning template exits non-zero when routes.tsv is a directory" \
   "exit $(_b91_pre "$B91/b19rd1")" "exit nonzero"
_b91_proj b19rd3; _b91_path="$CMSTUB"
_b91v="$(_b91_sh "$B91" "$_b91_rl" 'o="$(felix_ready_report "$1")"; printf "%s [%s]" "$?" "$o"' "$B91/b19rd3")"
_b91_path=""
is "b19 A42 (control): with no routes.tsv the report prints nothing and returns 0, and the preflight check exits 0" \
   "report $_b91v, preflight exit $(_b91_pre "$B91/b19rd3")" "report 0 [], preflight exit 0"

_b91_proj b19ob1; printf 'thing\t-\t-\tls -1 x\ttest -f x\n' > "$B91/b19ob1/probes.tsv"
printf 'a\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\tthing\tholds\n' > "$B91/b19ob1/obligations.tsv"
is "b19 A43: felix_obligations_orphans over rows that were not read whole prints nothing and returns 2" \
   "$(_b91_sh "$B91" "probes obligations" 'felix_obligation_rows() { return 1; }; o="$(felix_obligations_orphans "$1")"; printf "%s|%s" "$?" "$o"' "$B91/b19ob1")" "2|"
_b91_proj b19ob2; printf 'thing\t-\t-\tls -1 x\ttest -f x\n' > "$B91/b19ob2/probes.tsv"
LC_ALL=C awk -F'\t' -v OFS='\t' '!/^#/ && NF && !f { $6 = "ghostp"; print; f = 1 }' "$FROOT/harness/templates/obligations.tsv" > "$B91/b19ob2/obligations.tsv"
is "b19 A44 (control): a row grounded on a probe nothing declares is still named, ghostp, with status 0" \
   "$(_b91_sh "$B91" "probes obligations" 'o="$(felix_obligations_orphans "$1")"; printf "%s|%s" "$?" "$o"' "$B91/b19ob2")" "0|ghostp"

_b91hx="$B91/hx"; _copy_content "$FROOT/harness" "$_b91hx/harness" >/dev/null 2>&1
printf '\nfelix_obligations_orphans() { return 2; }\n' >> "$_b91hx/harness/lib/obligations.sh"
cp -p "$FROOT/projects/widget/obligations.tsv" "$B91/widget-obligations.keep" 2>/dev/null
cp "$TMP/obligations.keep" "$FROOT/projects/widget/obligations.tsv"
_b91o="$( cd "$_b91wc" && HOME="$B91/home" PATH="$CMSTUB:$PATH" "$_b91hx/harness/felix" obligations 2>&1 )"
( cd "$_b91wc" && HOME="$B91/home" PATH="$CMSTUB:$PATH" "$_b91hx/harness/felix" obligations --gate ) >/dev/null 2>&1; _b91a=$?
is "b19 A45: when the orphans lookup fails felix obligations says whether a row grounds on an undeclared probe could not be read whole, and --gate exits 1" \
   "said $(_b91_in "$_b91o" 'could not be read whole'), gate exit $_b91a" "said yes, gate exit 1"
_b91_h="$_b91hx/harness"
_b91v="$(_b91_sh "$_b91wc" "detect verify evidence escape probes facts obligations" 'felix_merge_blockers "$1" "" "$2" "$3"' "$FROOT/projects/widget" "$_b91wc" "$FROOT")"
_b91_h="$FROOT/harness"
is "b19 A46: and felix_merge_blockers emits an obligations table row saying the grounding could not be read" \
   "$(printf '%s\n' "$_b91v" | LC_ALL=C awk 'index($0, "obligations\ttable\t") == 1 && index($0, "could not be read") { f = 1 } END { print (f ? "emitted" : "not emitted") }')" "emitted"
[ ! -f "$B91/widget-obligations.keep" ] || cp -p "$B91/widget-obligations.keep" "$FROOT/projects/widget/obligations.tsv"

_b91made=''; [ -d "$FROOT/state" ] || _b91made=state; [ -d "$FROOT/state/commission" ] || _b91made="$_b91made commission"
_b91sp="$FROOT/projects/b19sess"; _b91sr="$B91R/sess"; mkdir -p "$_b91sp" "$MEM/b19sess" "$_b91sr"
printf '{\n  "name": "b19sess",\n  "remote_match": "example.com/b19sess",\n  "gate": "true"\n}\n' > "$_b91sp/project.json"
printf '# b19sess\n' > "$_b91sp/CLAUDE.md"
printf 'x_plain\t-\t-\t-\t-\ttrue\t-\n' > "$_b91sp/commissioning.tsv"
printf 'b19sess\n' > "$_b91sr/.felix"; _b91_repo "$_b91sr"; _b91sr="$(cd "$_b91sr" && pwd -P)"
_b91_path="$CMSTUB"
_b91_sh "$_b91sr" commission 'FELIX_HOME_DIR="$3"; _o="$(felix_commission_run "$1" "$2" -)"; felix_commission_receipt_write "$3" "$1" "$2" "$_o" "" >/dev/null' "$_b91sp" "$_b91sr" "$FROOT"
_b91tp="$(_b91_sh "$_b91sr" "detect stack probes verify toolbox discover ready commission commission-provider epoch" 'felix_commission_topology "$1" "$2"' "$_b91sp" "$_b91sr")"
_b91_path=""
_copy_content "$FROOT/harness" "$B91/plug-a/harness" >/dev/null 2>&1
printf '\nfelix_commission_rows() { return 1; }\n' >> "$B91/plug-a/harness/lib/commission.sh"
_copy_content "$FROOT/harness" "$B91/plug-b/harness" >/dev/null 2>&1
_b91_ss() { local _b91so; _b91so="$(cd "$_b91sr" && HOME="$B91/home" CLAUDE_PLUGIN_ROOT="$1" "$1/harness/hooks/session-start" 2>&1)"
            printf '%s\n' "${_b91so//\\n/$'\n'}"; }   # PLUGIN-ROOT: session start's context, \n read as a line break
_b91seen="$FROOT/state/commission/b19sess.seen"
rm -f "$_b91seen"; _b91o="$(_b91_ss "$B91/plug-a")"; _b91a=absent; [ ! -e "$_b91seen" ] || _b91a=written
is "b19 A47: when the commissioning rows are not read whole session start says no receipt line, writes no seen file, and names commissioning.tsv in the unread paragraph" \
   "receipt $(_b91_in "$_b91o" 'Commissioning: receipt'), seen $_b91a, unread $(_b91_in "$_b91o" 'Commissioning: whether these answers are whole could not be read'), row $(_b91_in "$_b91o" 'commissioning.tsv (unknown: its rows could not be read whole)')" \
   "receipt no, seen absent, unread yes, row yes"
rm -f "$_b91seen"; _b91o="$(_b91_ss "$B91/plug-b")"; _b91a=no
[ -n "$_b91tp" ] && [[ "$(cat "$_b91seen" 2>/dev/null)" == *"$_b91tp"* ]] && _b91a=yes
is "b19 A48 (control): an unmodified engine says the receipt line and its seen file holds the topology" \
   "receipt $(_b91_in "$_b91o" 'Commissioning: receipt'), seen holds the topology $_b91a" "receipt yes, seen holds the topology yes"
rm -rf "$_b91sp" "$MEM/b19sess" "$B91/plug-a" "$B91/plug-b" "$_b91hx"
[ -d "$FROOT/state" ] && find "$FROOT/state" -name '*b19sess*' -exec rm -rf {} + 2>/dev/null
case "$_b91made" in *commission*) rmdir "$FROOT/state/commission" 2>/dev/null ;; esac
case "$_b91made" in state*) rmdir "$FROOT/state" 2>/dev/null ;; esac
# <<< b19-detection-slug-and-lookups
