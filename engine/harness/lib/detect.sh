# Capability detection.
#
# The guidebook's later phases assume surfaces a young project does not have
# yet: no deploy target, so no preview environments; no Sentry, so no incident
# loop; no Stripe, so no billing gate. Declaring those permanently out of scope
# is wrong, because the day a Dockerfile lands the deploy phase becomes real and
# nobody is watching for it.
#
# So Felix probes for the surface instead of asking. Each probe answers one
# question: does evidence of this capability exist in the checkout right now.
#
# Detection reports. It never enables. A gate that switched itself on would
# block a pull request for a reason no one chose, and the whole doctrine here is
# that a gate's meaning has to be deliberate. `felix doctor` shows the drift;
# adopting it is a decision someone makes.

# The dependency names that say a capability, by the kind of manifest they are
# read in: kind, capability, then the names (audit b19, C090). A name in a JSON
# manifest is a key, in a Gemfile a gem line, in a Cargo manifest the first token
# of a line, in a Python manifest a package name bounded on both sides, and in the
# others (go.mod, pom.xml and build.gradle, *.csproj) a substring. They add to the
# tokens felix_detect greps for in every manifest; they take nothing away.
FELIX_DEP_NAMES='npm api koa hono @nestjs/core @hapi/hapi
npm database pg postgres mysql2 mongodb mongoose sequelize knex better-sqlite3 kysely
npm auth passport next-auth @auth/core lucia jsonwebtoken
npm ratelimit express-rate-limit rate-limiter-flexible @upstash/ratelimit
npm frontend react vue svelte @angular/core next nuxt solid-js preact astro @sveltejs/kit
composer api laravel/framework symfony/framework-bundle slim/slim
composer database doctrine/orm illuminate/database
composer auth laravel/sanctum laravel/passport
gem api rails sinatra grape hanami
gem database pg mysql2 sqlite3 activerecord sequel mongoid
gem auth devise omniauth rodauth
gem ratelimit rack-attack
cargo api axum actix-web rocket warp
cargo database sqlx diesel sea-orm tokio-postgres
cargo auth jsonwebtoken
cargo ratelimit governor tower_governor
gomod api github.com/gin-gonic/gin github.com/labstack/echo github.com/go-chi/chi github.com/gofiber/fiber github.com/gorilla/mux
gomod database github.com/jackc/pgx github.com/lib/pq gorm.io/gorm github.com/jmoiron/sqlx go.mongodb.org/mongo-driver github.com/go-sql-driver/mysql
gomod auth github.com/golang-jwt/jwt
gomod ratelimit github.com/ulule/limiter github.com/didip/tollbooth
jvm api spring-boot-starter-web
jvm database spring-boot-starter-data-jpa spring-boot-starter-jdbc hibernate-core
jvm auth spring-boot-starter-security
jvm ratelimit bucket4j resilience4j-ratelimiter
cs api Microsoft.NET.Sdk.Web
cs database EntityFrameworkCore Npgsql Dapper
cs auth Microsoft.AspNetCore.Authentication Microsoft.AspNetCore.Identity
cs ratelimit AspNetCoreRateLimit
py database psycopg psycopg2 psycopg2-binary asyncpg pymongo peewee sqlmodel
py auth authlib django-allauth flask-login pyjwt
py ratelimit slowapi flask-limiter django-ratelimit'

# Every path the checkout shows, one to a line and relative to ROOT, without
# the vendored trees (see _felix_select). In a checkout holding .git, what git
# lists as tracked, or untracked and not ignored; in a directory that is none,
# every regular file. 2 when it could not be listed. Git that fails is not
# answered with find: a checkout that cannot be listed has not been read.
_felix_files() {
  if [ -e "$1/.git" ] || [ -L "$1/.git" ]; then
    git -C "$1" -c core.quotepath=off ls-files --cached --others --exclude-standard
  else
    ( cd "$1" 2>/dev/null || exit 2
      find . \( -name node_modules -o -name vendor -o -name third_party -o -name .venv \
             -o -name venv -o -name bower_components -o -name .git \) -prune -o -type f -print \
        | LC_ALL=C sed 's#^\./##'
      set -- "${PIPESTATUS[@]}"
      [ "${1:-1}" -eq 0 ] && [ "${2:-1}" -eq 0 ] )
  fi
}

# What the listing says, in one pass over it (one awk, whatever the size of the
# checkout): M and a path for each manifest below the root; P, a capability and a
# path for a file that is evidence by its name (at most three paths for each
# capability, since the shell asks whether each exists); and A and the number of
# web assets. A path with a component node_modules, vendor, third_party, .venv,
# venv, bower_components or .git below the root is skipped: it is somebody
# else's tree, and a vendored dependency tree must not manufacture a frontend, an
# api or a deploy target. Root files are the filesystem's (_felix_manifests, _felix_any).
# Non-zero when the listing or the awk did not complete.
_felix_select() {
  _felix_files "$1" | LC_ALL=C awk '
    function emit(cap, p) { if (cnt[cap]++ < 3) print "P\t" cap "\t" p }
    BEGIN {
      n = split("node_modules vendor third_party .venv venv bower_components .git", w, " ")
      for (i = 1; i <= n; i++) skip[w[i]] = 1
      n = split("pyproject.toml requirements.txt setup.cfg Pipfile package.json Cargo.toml go.mod Gemfile composer.json build.gradle build.gradle.kts pom.xml", w, " ")
      for (i = 1; i <= n; i++) man[w[i]] = 1
      n = split("docker-compose.yml docker-compose.yaml Procfile fly.toml vercel.json render.yaml railway.json", w, " ")
      for (i = 1; i <= n; i++) dep[w[i]] = 1
    }
    { nc = split($0, c, "/"); b = c[nc]
      if (nc > 1) for (i = 1; i <= nc; i++) if (c[i] in skip) next
      if (tolower(b) ~ /\.(jsx?|tsx?|vue|svelte|s[ac]ss|css)$/) assets++
      if (nc == 1) next
      if (((b in man) || b ~ /\.csproj$/ || (b ~ /\.txt$/ && c[nc - 1] == "requirements")) && !(nc == 2 && c[1] == "requirements")) print "M\t" $0
      if (b == "Dockerfile" || b ~ /^Dockerfile\./ || (b in dep)) emit("deploy", $0)
      if (b == ".env.example" || b == ".env.sample") emit("secrets", $0)
      if (b == "Cargo.toml") emit("rust", $0)
      if (b == "alembic.ini" || (b == "schema.prisma" && c[nc - 1] == "prisma")) emit("database", $0)
      for (i = 1; i < nc; i++) if (c[i] == "migrations" || (c[i] == "db" && c[i + 1] == "migrate" && i + 1 < nc)) { emit("database", $0); break }
    }
    END { print "A\t" assets + 0 }'
  set -- "${PIPESTATUS[@]}"
  [ "${1:-1}" -eq 0 ] && [ "${2:-1}" -eq 0 ]
}

# The lines of STRING in _fm_lines. Split with IFS and noglob confined to this
# function, and no here-document: a temporary file that cannot be written is
# nothing read.
_felix_lines() {
  local IFS=$'\n' f=1
  case $- in *f*) f=0 ;; esac
  set -f
  _fm_lines=( $1 )
  [ "$f" -eq 0 ] || set +f
}

# What the checkout holds that detection reads, into the caller's variables:
# _fm_all, the manifests, and the same by kind (_fm_npm _fm_composer _fm_gem
# _fm_cargo _fm_gomod _fm_jvm _fm_cs _fm_py); _fm_found, the capabilities some
# file's name says, one to a line with a newline after each; _fm_assets, the
# number of web assets. 2 when the checkout could not be listed.
#
# The root is read on the filesystem, as it always was (an untracked or an
# ignored manifest there counts); below it, from the listing. The globs are
# quoted here so they reach the inner loop whole and expand against the root
# there. Bare, they expanded against the current directory first: run from a
# folder holding requirements/dev.txt, the root's requirements/prod.txt was never
# read. The root is quoted and the pattern is not, since an unquoted root splits
# on IFS and a checkout whose path holds a space matched nothing at all.
_felix_manifests() {
  local root="$1" f m line kind rest cap p sel="" rc=0 nl=$'\n' tab=$'\t'
  _fm_all=(); _fm_npm=(); _fm_composer=(); _fm_gem=(); _fm_cargo=(); _fm_gomod=(); _fm_jvm=(); _fm_cs=(); _fm_py=()
  _fm_found=""; _fm_assets=0
  for f in pyproject.toml requirements.txt 'requirements/*.txt' setup.cfg Pipfile \
           package.json Cargo.toml go.mod Gemfile composer.json build.gradle \
           build.gradle.kts pom.xml '*.csproj'; do
    # shellcheck disable=SC2086
    for m in "$root"/$f; do
      [ -f "$m" ] && _fm_all[${#_fm_all[@]}]="$m"
    done
  done
  felix_capture sel _felix_select "$root" || rc=2
  _felix_lines "$sel"
  for line in ${_fm_lines[@]+"${_fm_lines[@]}"}; do
    kind="${line%%$tab*}"; rest="${line#*$tab}"
    case "$kind" in
      M) [ -f "$root/$rest" ] && _fm_all[${#_fm_all[@]}]="$root/$rest" ;;
      P) cap="${rest%%$tab*}"; p="${rest#*$tab}"
         case "$nl$_fm_found" in *"$nl$cap$nl"*) continue ;; esac
         [ -f "$root/$p" ] && _fm_found="$_fm_found$cap$nl" ;;
      A) _fm_assets="$rest" ;;
    esac
  done
  for p in ${_fm_all[@]+"${_fm_all[@]}"}; do
    case "${p##*/}" in
      package.json)  _fm_npm[${#_fm_npm[@]}]="$p" ;;
      composer.json) _fm_composer[${#_fm_composer[@]}]="$p" ;;
      Gemfile)       _fm_gem[${#_fm_gem[@]}]="$p" ;;
      Cargo.toml)    _fm_cargo[${#_fm_cargo[@]}]="$p" ;;
      go.mod)        _fm_gomod[${#_fm_gomod[@]}]="$p" ;;
      pom.xml|build.gradle|build.gradle.kts) _fm_jvm[${#_fm_jvm[@]}]="$p" ;;
      *.csproj)      _fm_cs[${#_fm_cs[@]}]="$p" ;;
      *)             _fm_py[${#_fm_py[@]}]="$p" ;;
    esac
  done
  return "$rc"
}

# Search the dependency manifests of any ecosystem, at any depth, for a token.
# Until audit b19 (C090) only the root's were read, so a monorepo whose service sat
# in apps/api showed no api, database or billing surface. Inside felix_detect it
# reads the list that call made; alone it makes its own. 0 when a manifest
# matches, 1 when none does, and 2 when the checkout could not be listed or a
# manifest could not be read.
_felix_dep_grep() {
  local root="$1" pat="$2"
  if [ "${_fm_live:-}" != "$root" ]; then
    local _fm_all=() _fm_npm=() _fm_composer=() _fm_gem=() _fm_cargo=() _fm_gomod=() _fm_jvm=() _fm_cs=() _fm_py=() _fm_lines=() _fm_found="" _fm_assets=0
    _felix_manifests "$root" || return 2
  fi
  [ "${#_fm_all[@]}" -gt 0 ] || return 1
  LC_ALL=C grep -qiE -- "$pat" "${_fm_all[@]}"
}

# felix_detect's two small helpers, which write to its variables: a capability
# found (once, whatever found it), and the status of a lookup that says whether it
# was found (0), was not (1), or could not be asked (anything else).
_felix_add() {
  case "$_fd_nl$_fd_found" in *"$_fd_nl$1$_fd_nl"*) ;; *) _fd_found="$_fd_found$1$_fd_nl" ;; esac
}
_felix_hit() {
  case "$2" in 0) _felix_add "$1" ;; 1) ;; *) _fd_rc=2 ;; esac
}

# The names of FELIX_DEP_NAMES, in the manifests of each kind that were found.
# Each (kind, capability) is one grep over all of that kind's files, so the
# processes started do not grow with the number of manifests.
_felix_dep_names() {
  local IFS=' ' nl=$'\n' rest="$FELIX_DEP_NAMES" line cls cap names n re i fx st
  while [ -n "$rest" ]; do
    line="${rest%%$nl*}"
    if [ "$line" = "$rest" ]; then rest=""; else rest="${rest#*$nl}"; fi
    cls="${line%% *}"; line="${line#* }"; cap="${line%% *}"; names="${line#* }"
    case "$cls" in
      npm|composer) set -- ${_fm_npm[@]+"${_fm_npm[@]}"}
                    [ "$cls" = npm ] || set -- ${_fm_composer[@]+"${_fm_composer[@]}"} ;;
      gem)   set -- ${_fm_gem[@]+"${_fm_gem[@]}"} ;;
      cargo) set -- ${_fm_cargo[@]+"${_fm_cargo[@]}"} ;;
      gomod) set -- ${_fm_gomod[@]+"${_fm_gomod[@]}"} ;;
      jvm)   set -- ${_fm_jvm[@]+"${_fm_jvm[@]}"} ;;
      cs)    set -- ${_fm_cs[@]+"${_fm_cs[@]}"} ;;
      py)    set -- ${_fm_py[@]+"${_fm_py[@]}"} ;;
    esac
    [ "$#" -gt 0 ] || continue
    case "$cls" in
      gomod|jvm|cs)
        fx=(); for n in $names; do fx[${#fx[@]}]=-e; fx[${#fx[@]}]="$n"; done
        LC_ALL=C grep -qiF "${fx[@]}" -- "$@" ;;
      *)
        re="${names// /|}"
        case "$cls" in
          npm|composer) re="\"($re)\"[[:space:]]*:" ;;
          gem)   re="^[[:space:]]*gem[[:space:]]+['\"]($re)['\"]" ;;
          cargo) re="^[[:space:]]*($re)[[:space:]]*[=.]" ;;
          py)    re="(^|[^[:alnum:]._-])(${re//-/[-_]})([^[:alnum:]._-]|\$)" ;;
        esac
        if [ "$cls" = py ]; then LC_ALL=C grep -qiE -- "$re" "$@"; else LC_ALL=C grep -qE -- "$re" "$@"; fi ;;
    esac
    st=$?
    _felix_hit "$cap" "$st"
  done
}

# True when ROOT shows evidence of any of the patterns, by existence on the
# filesystem. The root only: what sits below it is the listing's.
_felix_any() {
  local root="$1"; shift
  local p m
  for p in "$@"; do
    # Quoted root, bare pattern, as in _felix_manifests.
    # shellcheck disable=SC2086
    for m in "$root"/$p; do
      [ -e "$m" ] && return 0
    done
  done
  return 1
}

# Print one capability name per line for everything the checkout shows evidence of.
#
# Each is printed once, in a fixed order. 0 when the checkout was listed and every
# manifest read, and 2 when it was not, in which case what is printed is not
# the whole and a caller that believes it has made a claim from a part (audit b19,
# C060): felix_undeclared, _felix_capability_union and felix_procedures_items
# all read the status. The status is explicit because the last test's is not.
felix_detect() {
  local root="${1:-$PWD}" _fd_found="" _fd_rc=0 _fd_nl=$'\n' c line
  local _fm_all=() _fm_npm=() _fm_composer=() _fm_gem=() _fm_cargo=() _fm_gomod=() _fm_jvm=() _fm_cs=() _fm_py=() _fm_lines=() _fm_found="" _fm_assets=0 _fm_live=""
  _felix_manifests "$root" || _fd_rc=2
  _fm_live="$root"
  _felix_lines "$_fm_found"
  for line in ${_fm_lines[@]+"${_fm_lines[@]}"}; do _felix_add "$line"; done

  _felix_any "$root" ".github/workflows/*.yml" ".github/workflows/*.yaml" \
                     ".gitlab-ci.yml" "azure-pipelines.yml" && _felix_add ci

  _felix_any "$root" "Dockerfile" "Dockerfile.*" "docker-compose.yml" "docker-compose.yaml" "Procfile" \
                     "fly.toml" "vercel.json" "render.yaml" "railway.json" \
                     "app.yaml" "k8s" "kubernetes" "helm" && _felix_add deploy

  _felix_any "$root" "*.tf" "terraform" "infra/*.tf" "pulumi.yaml" && _felix_add iac

  _felix_dep_grep "$root" "sentry|opentelemetry|datadog"; _felix_hit observability $?
  _felix_dep_grep "$root" "\"?stripe\"?"; _felix_hit billing $?
  _felix_dep_grep "$root" "playwright|cypress|selenium|puppeteer"; _felix_hit e2e $?
  _felix_dep_grep "$root" "supabase|prisma|alembic|sqlalchemy|drizzle|typeorm"; _felix_hit database $?
  _felix_dep_grep "$root" "fastapi|flask|django|express|next|fastify|starlette"; _felix_hit api $?

  _felix_any "$root" "migrations" "supabase/migrations" "alembic.ini" \
                     "prisma/schema.prisma" && _felix_add database

  # An application built on a model SDK is a different kind of thing from an
  # application that happens to call an API, and none of the probes above can
  # tell. Prompts get pinned, outputs get graded, cost and refusal are failure
  # modes — none of which the ordinary api/tests capabilities imply.
  _felix_dep_grep "$root" \
    "anthropic|openai|langchain|llama-?index|mistralai|cohere|ollama|google-generativeai|litellm|instructor|dspy|transformers"; _felix_hit llm $?

  _felix_any "$root" "Cargo.toml" && _felix_add rust

  _felix_dep_names

  # A web surface exists whether or not npm was ever run there, and a package.json
  # alone is not one: it must name a frontend library (_felix_dep_names), or the
  # checkout lists FELIX_FRONTEND_MIN web assets (a vendored dependency tree
  # cannot manufacture a frontend). A Python app with templates and a static
  # directory has a frontend by any definition a designer would recognise.
  [ "${_fm_assets:-0}" -ge "${FELIX_FRONTEND_MIN:-3}" ] && _felix_add frontend

  _felix_any "$root" "tests" "test" "spec" "__tests__" && _felix_add tests

  _felix_any "$root" ".env.example" ".env.sample" && _felix_add secrets

  for c in ci deploy iac observability billing e2e database api auth ratelimit llm rust frontend tests secrets; do
    case "$_fd_nl$_fd_found" in *"$_fd_nl$c$_fd_nl"*) printf '%s\n' "$c" ;; esac
  done
  return "$_fd_rc"
}

# Capabilities a project has declared it knows about, one per line.
#
# 0 when there is no file or it was read, whether or not it holds a
# capability line, and 2 when something is there and could not be read as a
# list. Only nothing at all is absent: a link whose target is gone, a
# directory or a pipe is something there that is not a list, and is 2 without
# being opened (a pipe must not be opened at all, since a reader would wait on
# it for a writer).
#
# 2026-10-08: until then it read with grep -vE '^\s*(#|$)' in the caller's
# locale, which treated a file that is not text as a list. A NUL made BSD grep
# print "Binary file <path> matches" as the one capability (measured), and by
# GNU grep's manual (not run) stop printing at the first NUL with 0 and, under
# a UTF-8 locale, drop each line holding a byte that is not valid UTF-8; BSD
# grep reads such a byte as text. A byte-order mark before a comment listed the
# comment, a line of only a no-break space was listed in the C locale and
# dropped in UTF-8, and a CR made every name one no table holds. Now a NUL
# anywhere is no list (as #383 refused a qualification.tsv holding one), the
# file is read byte for byte in the C locale, a leading UTF-8 byte-order mark
# is dropped, and a listed line holding a byte outside tab and printable ASCII
# makes the whole file no list, the way qualify calls a row with a CR
# malformed. A file that is no list is 2 with nothing printed.
# It reads with cat into a subshell, not a redirect or a second grep, so that
# the file is opened once by a named command whose status says a read failed
# (the read builtin returns a read error as end of input). The C locale is set
# inside the subshell because bash 4 to 5.2 in a UTF-8 locale reads the byte
# after a UTF-8 lead byte as part of a character without asking whether it is
# the delimiter, so a NUL right after one hid from read -d '' (#383's review);
# the subshell keeps the locale, IFS and set -f its own, and its stderr is
# discarded as grep's was. A caller whose LC_ALL is readonly and not C gets 2
# and no message: bash 3.2 abandons the subshell at the assignment, and the
# second test refuses where a shell would carry on in the caller's locale.
# cat is `command cat`, so no function of that name stands in. The lines are
# judged by two regular expressions, each tried on known input first, since
# one that cannot be compiled returns 2 and `&&` would read that as no match.
# The cost is one process more per call than the grep it replaced, a cat and a
# subshell, measured, and linear in the file: the mark is cut by offset, the
# names kept in an array and each line matched once, because `${x#mark}`,
# string appends, `${x//tab/ }` and stripping leading space by pattern grew
# with the square of a file or a line (5.7 s for 670 KB, 17 s for one line of
# 10,000 tabs; found by review).
felix_declared() {
  local proj="$1" st
  # Declared as the locale rules above felix_json_str in resolve.sh ask of every
  # function holding a [[ =~ ]]. A readonly LC_ALL refuses it, silently here,
  # and the subshell's own test below then returns 2.
  local LC_ALL=C 2>/dev/null
  [ -e "$proj/capabilities" ] || [ -L "$proj/capabilities" ] || return 0
  [ -f "$proj/capabilities" ] || return 2
  command cat -- "$proj/capabilities" 2>/dev/null | (
    [ "${LC_ALL-}" = C ] || LC_ALL=C
    [ "${LC_ALL-}" = C ] || exit 6
    IFS= read -r -d '' _fdb && exit 3
    case "$_fdb" in $'\357\273\277'*) _fdb="${_fdb:3}" ;; esac
    _fdskip='^[[:space:]]*(#|$)' _fdbad=$'[^\t[:print:]]'
    [[ '' =~ $_fdskip ]] && [[ $'\001' =~ $_fdbad ]] && ! [[ $'a\t~' =~ $_fdbad ]] || exit 5
    _fdk=(); IFS=$'\n'; set -f; set -- $_fdb
    for _fdl; do
      [[ $_fdl =~ $_fdskip ]] && continue
      [[ $_fdl =~ $_fdbad ]] && exit 4
      _fdk[${#_fdk[@]}]="$_fdl"
    done
    [ "${#_fdk[@]}" -eq 0 ] || printf '%s\n' "${_fdk[@]}" ) 2>/dev/null
  st="${PIPESTATUS[0]}:${PIPESTATUS[1]}"
  [ "$st" = 0:0 ] || return 2
}

# NAME CMD [ARGS...]: run CMD in one command substitution and assign its output
# to the variable named NAME, minus one trailing newline, only when CMD returned
# 0 and the substitution ran to its end. 0 when it did, the empty string being
# output too, and 2 when it did not, with NAME left as the caller had it. The
# status of CMD is not enough, because a substitution can end with nothing
# printed and status 0 when its fork fails (EAGAIN) or, on bash 3.2, when it
# cannot make its pipe, so a newline and a `.` are printed only after CMD
# returned 0, and output that does not end in them was never whole.
#
# Every status but 0 reads as not whole, so a command captured here returns 0
# only when what it printed is whole. The sentinel is forged by a last line that
# is exactly `.`, printed by a command that then failed, and by nothing else.
# Until 2026-10-01 it was a bare `.`, which a failed felix_declared forged with a
# last line ending in a dot (`billing.`). No locals, because a local of the name
# the caller passed would take the assignment printf -v makes and the caller's
# variable would never see it, and no variable of its own, because a global would
# not hide a caller's variable of the same name but overwrite it (lib/commission.sh
# felix_commission_ask has no locals either, for the first reason only):
# everything is held in the positional parameters. The newlines are stripped
# with a literal one in the pattern, which is the same in bash 3.2 and 5.
felix_capture() {
  set -- "$1" "$(shift; "$@" && printf '\n.')"
  case "$2" in *"
.") ;; *) return 2 ;; esac
  set -- "$1" "${2%"
."}"
  set -- "$1" "${2%"
"}"
  printf -v "$1" '%s' "$2"
  return 0
}

# The declared list read into the variable named $1, one capability per line
# with no trailing newline, and whether it was read. 0 when it was, the empty
# string being a list too (no file, or one that declares nothing), and 2 when it
# was not, with the variable left as the caller had it.
#
# Until 2026-10-01 each reader of the list but _felix_cap_active ran
# `$(felix_declared ...)` and took what came back as the list, so a list that
# could not be read was an empty one and every reader made a claim from it: a
# capability not declared, drift to adopt, an orphan, a gap that was not one, a
# topology that was not the project's. Now they read here and branch on the
# status, and felix_capture says whether the substitution came back whole.
felix_declared_into() {
  felix_capture "$1" felix_declared "$2"
}

# The capabilities this checkout shows and the project declares, one to a line,
# sorted and without repeats: ROOT and LIST, which is the declared list as
# felix_declared_into read it. 0 when the pipeline that made it ran whole, and
# nonzero when either half of it did not: a sort that could not run is as much a
# union that was not made as a list that could not be read, and so is detection
# that did not return 0, since what it printed is then part of the checkout
# (audit b19, C060; felix_detect says so with 2). Captured by felix_capture,
# which is what makes the status mean something. Until 2026-10-01 each caller
# made this union itself, in a group piped to sort whose status nobody asked, so
# a sort that could not run was a list with nothing in it.
#
# The declared half is printed first, so a felix_detect that exits inside the
# group cannot take it along. A fork that fails inside the group (felix_detect's
# EAGAIN) is another thing: on bash 3.2 it kills the group's subshell with 128, so
# the pipeline's status is nonzero, the union is not made, and its readers say the
# declared list could not be read, the one sentence they have for it. The
# statuses are taken whole into the positional parameters, which pipefail does
# not change and the first test would reset.
_felix_capability_union() {
  { [ -z "$2" ] || printf '%s\n' "$2"; felix_detect "$1" 2>/dev/null || exit 2; } | LC_ALL=C sort -u
  set -- "${PIPESTATUS[@]}"
  [ "${1:-1}" -eq 0 ] && [ "${2:-1}" -eq 0 ]
}

# Present in the checkout but never declared. This is the drift worth surfacing.
#
# 0 with the surfaces on stdout, and 2 with nothing printed when the declared
# list could not be read, or when detection could not be made whole (audit b19,
# C060: a checkout git could not list has not been read, and what it showed is
# not the drift). Until 2026-10-01 an unread list subtracted nothing, so
# every detected surface was undeclared drift and session start adopted each one,
# capabilities that may already have been declared. The list is read once, in
# this shell, before the pipeline, and what it holds is skipped by a case, the
# way _felix_cap_active asks, where felix_has_line's here-document is a
# temporary file on bash 3.2. A process substitution would hand a loop an empty
# file when its fork failed, so there is none. The detected half is captured
# too, and sorted by the loop's own producer: a sort that fails there reads as
# less drift, unlike in _felix_capability_union, where a sort that could not run
# is a union that was not made.
felix_undeclared() {
  local root="$1" proj="$2" declared det="" nl=$'\n' cap
  felix_declared_into declared "$proj" || return 2
  felix_capture det felix_detect "$root" || return 2
  printf '%s\n' "$det" | LC_ALL=C sort -u | while IFS= read -r cap; do
    [ -n "$cap" ] || continue
    case "$nl$declared$nl" in *"$nl$cap$nl"*) ;; *) printf '%s\n' "$cap" ;; esac
  done
  return 0
}

# Best guess at the command that proves this project correct. A guess, printed
# for a human to confirm, never silently trusted: a wrong gate that exits 0 is
# the one failure mode worse than having no gate.
felix_guess_gate() {
  local root="${1:-$PWD}"
  if [ -f "$root/package.json" ]; then
    LC_ALL=C grep -q '"verify"' "$root/package.json" && { echo "npm run verify"; return; }
    LC_ALL=C grep -q '"test"'   "$root/package.json" && { echo "npm test"; return; }
  fi
  [ -f "$root/Makefile" ] && LC_ALL=C grep -qE '^(check|verify):' "$root/Makefile" \
    && { echo "make check"; return; }
  [ -f "$root/Cargo.toml" ] && { echo "cargo test"; return; }
  [ -f "$root/go.mod" ]     && { echo "go test ./..."; return; }
  [ -f "$root/pyproject.toml" ] || [ -f "$root/setup.cfg" ] \
    && { echo "python -m pytest -q"; return; }
  echo ""
}

# Moved out for size, and sourced here so that whoever has detect.sh has them.
command -v _felix_rival_gates >/dev/null 2>&1 || . "$(dirname "${BASH_SOURCE[0]:-$0}")/rivals.sh"
command -v felix_repo_slug >/dev/null 2>&1 || . "$(dirname "${BASH_SOURCE[0]:-$0}")/slug.sh"
