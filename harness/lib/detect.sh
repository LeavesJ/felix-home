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

# Search the dependency manifests of any ecosystem for a token.
_felix_dep_grep() {
  local root="$1" pat="$2" f
  for f in pyproject.toml requirements.txt requirements/*.txt setup.cfg Pipfile \
           package.json Cargo.toml go.mod Gemfile composer.json build.gradle \
           pom.xml *.csproj; do
    # shellcheck disable=SC2086
    for m in $root/$f; do
      [ -f "$m" ] || continue
      grep -qiE "$pat" "$m" && return 0
    done
  done
  return 1
}

_felix_any() {
  local root="$1"; shift
  local p
  for p in "$@"; do
    # shellcheck disable=SC2086
    for m in $root/$p; do
      [ -e "$m" ] && return 0
    done
  done
  return 1
}

# Print one capability name per line for everything the checkout shows evidence of.
felix_detect() {
  local root="${1:-$PWD}"

  _felix_any "$root" ".github/workflows/*.yml" ".github/workflows/*.yaml" \
                     ".gitlab-ci.yml" "azure-pipelines.yml" && echo ci

  _felix_any "$root" "Dockerfile" "Dockerfile.*" "docker-compose.yml" "Procfile" \
                     "fly.toml" "vercel.json" "render.yaml" "railway.json" \
                     "app.yaml" "k8s" "kubernetes" "helm" && echo deploy

  _felix_any "$root" "*.tf" "terraform" "infra/*.tf" "pulumi.yaml" && echo iac

  _felix_dep_grep "$root" "sentry|opentelemetry|datadog" && echo observability
  _felix_dep_grep "$root" "\"?stripe\"?" && echo billing
  _felix_dep_grep "$root" "playwright|cypress|selenium|puppeteer" && echo e2e
  _felix_dep_grep "$root" "supabase|prisma|alembic|sqlalchemy|drizzle|typeorm" && echo database
  _felix_dep_grep "$root" "fastapi|flask|django|express|next|fastify|starlette" && echo api

  _felix_any "$root" "migrations" "supabase/migrations" "alembic.ini" \
                     "prisma/schema.prisma" && echo database

  _felix_any "$root" "package.json" && echo frontend
  _felix_any "$root" "tests" "test" "spec" "__tests__" && echo tests

  _felix_any "$root" ".env.example" ".env.sample" && echo secrets
}

# Capabilities a project has declared it knows about, one per line.
felix_declared() {
  local proj="$1"
  [ -f "$proj/capabilities" ] || return 0
  grep -vE '^\s*(#|$)' "$proj/capabilities" 2>/dev/null
}

# Present in the checkout but never declared. This is the drift worth surfacing.
felix_undeclared() {
  local root="$1" proj="$2"
  comm -23 \
    <(felix_detect "$root" | sort -u) \
    <(felix_declared "$proj" | sort -u)
}

# Best guess at the command that proves this project correct. A guess, printed
# for a human to confirm, never silently trusted: a wrong gate that exits 0 is
# the one failure mode worse than having no gate.
felix_guess_gate() {
  local root="${1:-$PWD}"
  if [ -f "$root/package.json" ]; then
    grep -q '"verify"' "$root/package.json" && { echo "npm run verify"; return; }
    grep -q '"test"'   "$root/package.json" && { echo "npm test"; return; }
  fi
  [ -f "$root/Makefile" ] && grep -qE '^(check|verify):' "$root/Makefile" \
    && { echo "make check"; return; }
  [ -f "$root/Cargo.toml" ] && { echo "cargo test"; return; }
  [ -f "$root/go.mod" ]     && { echo "go test ./..."; return; }
  [ -f "$root/pyproject.toml" ] || [ -f "$root/setup.cfg" ] \
    && { echo "python -m pytest -q"; return; }
  echo ""
}

# owner/name for a GitHub checkout, empty otherwise.
felix_repo_slug() {
  (cd "${1:-$PWD}" 2>/dev/null && git remote get-url origin 2>/dev/null) \
    | sed -E 's#.*github\.com[:/]##; s#\.git$##'
}
