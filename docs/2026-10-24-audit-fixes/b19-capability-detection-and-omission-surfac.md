# Audit fix b19: capability detection and omission surfaces

The whole specification for batch b19; the blind assertions are written from it alone. It says what
must be true, not how. Against `origin/main` 69b51a61 (0.49.307). Five defects, each confirmed by a
skeptic, with their corrections used (C060 lowered to low); claims that do not hold are in section 6.

Words used below. PROJ is a project directory (in the CLI, `HOME/projects/NAME`). ROOT is a checkout.
TPL is `engine/harness/templates`. MEM is `$FELIX_MEMORY/NAME` (what `felix_mem_dir PROJ` prints). A
**run** in `MEM/facts.log` is the rows sharing field 1 (stamp) and field 2 (tree id). **Not whole**
means a lookup whose status was non-zero or whose output did not reach the caller entire, as
`felix_capture` decides today.

## 1. Defects

- **C089** (medium). What the plane works out about omissions reaches no automatic surface, and
  `felix next` says "nothing due" over it. *Scenario:* Elenchus has 7 unadmitted candidate obligations
  and a detected surface no probe grounds; every gate pass prints only counts and throws away the drift
  and gap sections `cmd_probes` computed (`felix`:846-852), `felix_next` ranks nothing from probe gaps,
  procedure gaps or candidates, and the only way to learn of any of them is to type `felix probes` or
  `felix obligations`.
- **C090** (medium). Detection reads only root manifests and a short framework list, so monorepos and
  most API stacks show no api, database or billing surface, and no auth or rate-limit surface exists.
  *Scenario:* a Go/gin service with pgx detects as nothing; a monorepo whose `apps/api` holds express,
  stripe, sentry, pg, openai, a Dockerfile and migrations detects as `frontend` only; Rails with pg,
  devise and rack-attack as `billing tests`. No gap, stance item, commission re-run or candidate
  request then names those surfaces.
- **C096** (medium). `felix_repo_slug` passes any non-github.com remote through almost unchanged, so
  every `[ -n "$slug" ] || die "no github remote"` guard is bypassed. *Scenario:* with an ssh alias
  (`git@github-work:acme/app.git`), `felix classify --apply`, `felix merge`, `felix pr` and the land
  tick pass `--repo git@github-work:acme/app` to gh and fail with a diagnosis that never mentions the
  remote. For GitLab or a local path only the diagnosis changes.
- **C056** (medium). The drift section compares against whichever tree last wrote the facts log, which
  every worktree and clone of the project shares. *Scenario:* worktree A commits the deletion of 2 hooks;
  untouched worktree B then runs `felix probes` and reads `hook_binding 6 members -> 8 members, 2 more
  than on the last tree`, about A's work, not B's.
- **C060** (low, as corrected). Lookups that end in `return 0`, or read a here-document of an unchecked
  substitution, still answer when a nested lookup dies. `felix_ready_report` over a routes list that is
  not whole prints nothing, so the commissioning preflight row reads done with nothing checked;
  `felix_obligations_orphans` returns 0 over rows that are not whole; session start walks
  `felix_commission_rows` unchecked and can spend the once-per-topology all-clear over rows nobody read;
  inside `felix_detect`, a `git ls-files` that fails falls back to `find`, and its status says nothing
  about whether it ran.

## 2. Required behaviour

### N. What nothing answers yet (C089)

**B1. `felix_next_unanswered PROJ ROOT TPL`** (new; sourcing `lib/resolve.sh` then `lib/next.sh` defines
it and everything it calls). It prints zero to three rows `owner<TAB>what<TAB>do`, in this order: the
probes row (B2), the procedures row (B3), the candidates row (B4); nothing else on stdout. It exits 0 in
every case below: unknown is a row, never a status. In each row NAMES are the first five names in the
order their lookup prints them, joined by `, `, followed by `, and K more` when there are more than five.
PROJ is printed as given.

**B2. Probes row.** (a) `felix_probes_gaps PROJ ROOT` returns 0 with N ≥ 1 names:
`felix<TAB>N surface(s) nothing probes: NAMES<TAB>ground each in PROJ/probes.tsv with a probe; felix probes says how`.
(b) No names: no row. (c) It returns non-zero: exactly
`felix<TAB>which surfaces nothing probes is not known: the capabilities this checkout shows or this project declares could not be read<TAB>felix probes says the same, and reads them again`.

**B3. Procedures row.** As B2 over `felix_procedures_gaps PROJ ROOT TPL`:
`felix<TAB>N item(s) nothing answers: NAMES<TAB>take a stance on each in PROJ/procedures.tsv; felix procedures lists them`;
non-zero:
`felix<TAB>which items nothing answers is not known: the capabilities this checkout shows or this project declares could not be read<TAB>felix procedures says the same, and reads them again`.

**B4. Candidates row.** Reads the recorded file `felix_candidates_path PROJ`; ingests no answer file
(`felix obligations` does). (a) A readable regular file: count the distinct field-6 names of its data rows
(not blank, not `#`) that are not among `felix_obligation_names PROJ`; N ≥ 1 gives
`founder<TAB>N candidate obligation(s) proposed and not admitted: NAMES<TAB>felix obligations lists them; a person admits one by copying its row into PROJ/obligations.tsv`.
(b) N = 0, or the file absent: no row. (c) The path exists and is not a readable regular file:
`felix<TAB>whether candidate obligations wait on a person is not known: PATH could not be read<TAB>felix obligations reads it again`
(PATH the candidates path).

**B5. `felix next`** calls B1 with the project, the checkout root it already uses and the engine's
templates directory. (a) `felix_next` is unchanged: same rows for the same inputs. (b) Ranked rows and
unanswered rows: after the last ranked row, a blank line, the heading `  what nothing answers yet`, then
each B1 row printed as ranked rows are (`    %-8s %s` for owner and what, `    %-8s   %s` for do); then
the trailer `N item(s). Ranked by …`, N counting ranked rows only, and its two lines after it unchanged.
(c) No ranked rows, unanswered rows: the line `next for NAME`, the section as in (b), a blank line and
exactly `Nothing is ranked. None of the above blocks anything; each is a question no table answers yet.`;
no line contains `nothing due` and none contains `item(s). Ranked by`. (d) Neither: the all-clear exactly
as today.

**B6. The gate's probes block** (`felix gate`, a project with `probes.tsv`, probes pass). (a) Unchanged:
the `  probes             ok` line, then the counts line. (b) Next, one line per row `cmd_probes --gate`
printed under `changed since the last tree`, in its order:
`                     changed since the last tree: PRED WAS -> NOW, DETAIL` (the counts line's 21-space
indent; WAS and NOW the row's second and third fields, trimmed), and for a row whose predicate is `-`,
`                     not compared with an earlier tree: DETAIL`. At most 10 such lines; when there are
more they are followed by
`                     changed since the last tree: and K more; felix probes lists them`.
(c) Then, when `cmd_probes` listed surfaces nothing probes,
`                     surfaces nothing probes: A, B, …` (every name); when it said not known,
`                     surfaces nothing probes: not known: the capabilities this project declares could not be read`;
otherwise nothing. (d) The new lines go to stdout only, never appended to the gate's log, so the failure
recorder reads what it reads today; the gate's exit status and its FAIL path (`  probes  FAIL`, up to 12
lines) are unchanged. (e) No drift row and no gap: the block is exactly today's two lines.

### F. The fact log's baseline (C056)

**B7. Provenance.** `felix_probes_record PROJ ROOT TID ROWS` appends three fields to every row it writes;
fields 1-9, the status rules and the write's confirmation are unchanged. Field 10: ROOT's HEAD as 40
lowercase hex, or `-` when ROOT has no commit or is not a git checkout. Field 11: a checkout identity, not
empty, no tab or newline, the same for two calls in the same checkout, different between a repository's
main checkout and its linked worktree and between two clones; `-` when not a git checkout. Field 12:
`clean` when `git status --porcelain` in ROOT prints nothing (untracked files count; ignored ones do not),
`dirty` when it prints something, `-` when it cannot be read.

**B8. Three arguments.** `felix_probes_drift PROJ TID ROWS` behaves exactly as today.

**B9. Four arguments.** `felix_probes_drift PROJ TID ROWS ROOT`: (a) TID empty: the no-tree-id row as
today. (b) ROOT has no commit (unborn, or not a checkout): exactly one row
`-<TAB>-<TAB>-<TAB>this checkout has no commit to place the run on, so nothing was compared`.
(c) A run **qualifies** when: its tree id differs from TID; its rows have 12 fields with a 40-hex commit in
field 10; that commit is ROOT's HEAD or an ancestor of it; and its field 12 is `clean` or its field 11
equals ROOT's checkout identity. The baseline is the qualifying run appearing last in the log. A row of
fewer than 12 fields never qualifies; a commit ROOT's repository does not have does not qualify, and
nothing is said about it on stdout. (d) With a baseline every row is computed against that run exactly as
today (instrument changed, state changed, not a number, fewer, more, nothing recorded for this predicate,
not read). (e) No qualifying run: exactly one row
`-<TAB>-<TAB>-<TAB>no earlier run on another tree in this branch's history is recorded, so nothing was compared`.
(f) The number of processes it starts does not grow with the number of runs in the log (review).

**B10. `felix probes`** passes its checkout root, so its `changed since the last tree` section follows
B9, in today's format; heading and closing paragraph unchanged.

### D. Detection (C090)

**B11. What is read.** At the root, existence is tested on the filesystem as today (an untracked or
ignored root file still counts). Below the root: in a ROOT holding `.git` (directory or file), what git
lists as tracked, or untracked and not ignored, that exists as a regular file; in a ROOT without `.git`,
every regular file under it. Below the root, a path with a component `node_modules`, `vendor`,
`third_party`, `.venv`, `venv`, `bower_components` or `.git` is skipped.

**B12. Manifests at any depth.** Read at any depth: `pyproject.toml`, `requirements.txt`, `setup.cfg`,
`Pipfile`, `package.json`, `Cargo.toml`, `go.mod`, `Gemfile`, `composer.json`, `build.gradle`,
`build.gradle.kts`, `pom.xml`, any `*.csproj`, and any `*.txt` directly in a directory named
`requirements`. Today's case-insensitive substring tokens (observability, billing, e2e, database, api,
llm) match in every one of them.

**B13. Dependency names.** A name below matches: in `package.json` and `composer.json` as a JSON key
(`"NAME"`, then optional spaces and `:`); in a `Gemfile` as a line `gem 'NAME'` or `gem "NAME"` (leading
whitespace allowed); in `Cargo.toml` as a line whose first token is NAME followed by optional spaces and
`=` or `.`; in Python manifests case-insensitively, `-` and `_` alike, when bounded on both sides by a
character that cannot occur in a package name (anything but letters, digits, `.`, `_`, `-`) or a line end;
in `go.mod`, `pom.xml`, `build.gradle(.kts)` and `*.csproj` as a case-insensitive substring.

| capability | package.json | Gemfile | go.mod | Cargo.toml | pom / gradle | composer.json | csproj | Python |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| api | koa, hono, @nestjs/core, @hapi/hapi | rails, sinatra, grape, hanami | github.com/gin-gonic/gin, github.com/labstack/echo, github.com/go-chi/chi, github.com/gofiber/fiber, github.com/gorilla/mux | axum, actix-web, rocket, warp | spring-boot-starter-web | laravel/framework, symfony/framework-bundle, slim/slim | Microsoft.NET.Sdk.Web | (today's tokens) |
| database | pg, postgres, mysql2, mongodb, mongoose, sequelize, knex, better-sqlite3, kysely | pg, mysql2, sqlite3, activerecord, sequel, mongoid | github.com/jackc/pgx, github.com/lib/pq, gorm.io/gorm, github.com/jmoiron/sqlx, go.mongodb.org/mongo-driver, github.com/go-sql-driver/mysql | sqlx, diesel, sea-orm, tokio-postgres | spring-boot-starter-data-jpa, spring-boot-starter-jdbc, hibernate-core | doctrine/orm, illuminate/database | EntityFrameworkCore, Npgsql, Dapper | psycopg, psycopg2, psycopg2-binary, asyncpg, pymongo, peewee, sqlmodel |
| auth | passport, next-auth, @auth/core, lucia, jsonwebtoken | devise, omniauth, rodauth | github.com/golang-jwt/jwt | jsonwebtoken | spring-boot-starter-security | laravel/sanctum, laravel/passport | Microsoft.AspNetCore.Authentication, Microsoft.AspNetCore.Identity | authlib, django-allauth, flask-login, pyjwt |
| ratelimit | express-rate-limit, rate-limiter-flexible, @upstash/ratelimit | rack-attack | github.com/ulule/limiter, github.com/didip/tollbooth | governor, tower_governor | bucket4j, resilience4j-ratelimiter | — | AspNetCoreRateLimit | slowapi, flask-limiter, django-ratelimit |
| frontend | react, vue, svelte, @angular/core, next, nuxt, solid-js, preact, astro, @sveltejs/kit | — | — | — | — | — | — | — |

**B14. Files at any depth** (B11's skips apply): deploy for `Dockerfile`, `Dockerfile.*`,
`docker-compose.yml`, `docker-compose.yaml`, `Procfile`, `fly.toml`, `vercel.json`, `render.yaml`,
`railway.json`; database for a file under a directory named `migrations`, a file under `db/migrate/`,
`alembic.ini`, `prisma/schema.prisma`; secrets for `.env.example`, `.env.sample`; rust for `Cargo.toml`.

**B15. Root only, unchanged:** ci (`.github/workflows/*.yml|yaml`, `.gitlab-ci.yml`,
`azure-pipelines.yml`), iac, tests (`tests`, `test`, `spec`, `__tests__`), deploy's `app.yaml`, `k8s`,
`kubernetes`, `helm`, and database's root `migrations` and `supabase/migrations` by existence.

**B16. frontend** is printed when a `package.json` read declares a frontend name (B13), or when at least
`FELIX_FRONTEND_MIN` (3) asset files are listed (the asset rule's extensions and count unchanged); never
because a `package.json` exists without one.

**B17. Output and status.** Each capability is printed at most once, one per line; the new names are
`auth` and `ratelimit`. Status 0 when every listing and read completed; 2 when ROOT holds `.git` and git
could not list it (no fallback to `find`), or a read was not whole, and then its output is incomplete and
the callers in B18 discard it. Manifest text is read in a number of processes that does not grow with the
number of manifests (review).

**B18. Callers fail closed.** When `felix_detect` returns non-zero: `_felix_capability_union` returns
non-zero, `felix_undeclared` returns 2 and prints nothing, and `felix_procedures_items` returns 2. Through
them: `felix probes` prints its existing not-known sentences, `felix next` prints B2(c) and B3's not-known
row, and session start adopts nothing and says `Capability drift was not checked` as today.
`felix_commission_caps_hash` is unchanged (detection that is not whole reads the receipt stale, as today).

### S. The GitHub slug (C096)

**B19. `felix_repo_slug [DIR]`** reads origin once, with `git … remote get-url origin` in DIR (part 0350
injects at it), exits 0 in every case, and prints `O/N` and a newline only when: the URL is
`scheme://[user@]host[:port]/O/N` (scheme `https`, `http`, `git` or `ssh`) or the scp form
`[user@]host:O/N`, and the host, compared case-insensitively, is `github.com`, `www.github.com` or
`ssh.github.com`, or (ssh and scp forms only) a host `ssh -G -o CanonicalizeHostname=no HOST` maps to one
of those; or the URL is an absolute path, or `file://` and an absolute path, whose last three components
are `github.com`, O and N. In every form, after trailing slashes and then one `.git` are removed, the path
is exactly two components, O and N are letters, digits, `.`, `_`, `-`, O does not begin with `-` or `.`,
N does not begin with `-` and is neither `.` nor `..`; the path's case is kept. Otherwise nothing. ssh is
never run for the https, http or git forms, for a path, or when the host is already one of the three.

**B20. The cases.**

| origin | prints |
|:---|:---|
| `git@github.com:acme/app.git` | `acme/app` |
| `https://github.com/acme/app.git` | `acme/app` |
| `https://github.com/acme/app/` | `acme/app` |
| `https://www.github.com/acme/app` | `acme/app` |
| `ssh://git@ssh.github.com:443/acme/app.git` | `acme/app` |
| `git@work:acme/app.git`, ssh maps `work` to github.com | `acme/app` |
| `git@gitlab-alias:acme/app.git`, ssh maps it to itself | nothing |
| `git@gitlab.com:acme/app.git`, `https://gitlab.com/acme/app.git` | nothing |
| `https://github.acme.com/acme/app.git` | nothing |
| `https://github.com/acme/app/tree` | nothing |
| `/srv/git/app.git` | nothing |
| `$D/github.com/fixture/lgh.git`, `file://$D/github.com/fixture/lgh.git` | `fixture/lgh` |
| `$D/github.com/fixture/ta<TAB>by.git` | nothing |
| no origin | nothing |

**B21. One reading of the slug.** `felix repair` reads its repository through `felix_repo_slug`; `felix`
holds no line containing `github\.com[:/]##`. `felix_remote_github_slug` (`lib/own.sh`, the own-checkout
check) is unchanged.

**B22. End to end.** `felix classify --base HEAD~0 --apply` in a governed checkout: with origin
`git@gitlab.com:acme/app.git` it exits non-zero, prints `no github remote; cannot label`, and runs no gh;
with origin `git@work:acme/app.git` gh is called with `--repo acme/app`.

### L. Lookups that cannot end in done (C060)

**B23.** `felix_ready_wanted PROJ` returns 0 with the list when `routes.tsv` is absent (empty) or read
whole; 2 when `PROJ/routes.tsv` exists and is not a readable regular file, or its pipeline did not
complete.

**B24.** `felix_ready_report PROJ`, when `felix_ready_wanted` was not whole, prints exactly one row
`unknown<TAB>routes.tsv<TAB>the plays this project's routes name could not be read whole, so no tool was checked`
and returns 2. Otherwise its rows and states are as today. The preflight row of `TPL/commissioning.tsv`
is unchanged, so it now reads held, not done; `felix next`'s rank 3 names `routes.tsv`.

**B25.** `felix_obligations_orphans PROJ` returns 2 and prints nothing when `felix_obligation_rows` was
not whole; otherwise 0 with the orphans as today.

**B26.** `felix obligations`, when `felix_obligations_orphans` returns non-zero, prints
`whether a row grounds on a probe PROJ/probes.tsv does not declare is not known: the rows could not be read whole`,
and `felix obligations --gate` exits 1.

**B27.** `felix_merge_blockers`, when `felix_obligations_orphans` returns non-zero, emits
`obligations<TAB>table<TAB>whether a row of PROJ/obligations.tsv grounds on a probe PROJ/probes.tsv does not declare could not be read`.

**B28.** Session start, when `felix_commission_rows PROJ` is not whole: the all-clear
`Commissioning: receipt …` is not said, `state/commission/NAME.seen` is not written, and the unread
paragraph (`Commissioning: whether these answers are whole could not be read…`) carries the line
`  commissioning.tsv (unknown: its rows could not be read whole)`. The rows are walked in the hook's
shell, not through a here-document. Otherwise as today.

### X. Budgets

**B29.** Checked with `wc -l` at review. Not longer than today: `felix` (6734), `hooks/session-start`
(780), `lib/escape.sh` (799), `lib/resolve.sh`, `lib/discover.sh`, `lib/where-read.sh`,
`lib/commission.sh`. At most 500: `lib/detect.sh`, `lib/facts.sh`, `lib/next.sh`, `lib/procedures.sh`,
`lib/ready.sh`, `lib/obligations.sh`, `lib/probes.sh`, `lib/candidates.sh`, `tests/run` (497 today, 499
with two registrations). At most two new `lib/` files of at most 500 lines, each sourced from an existing
lib with the house guard (`command -v X || . "$(dirname "${BASH_SOURCE[0]:-$0}")/x.sh"`), so the CLI's
source list does not grow. Bash 3.2 and 5; no gawk-only awk (part 1497); `LC_ALL=C` for every sort and
comparison; digit brackets spelled out.

## 3. What must not change

| Behaviour | Pinned by |
|:---|:---|
| `felix_next`'s rows, ranks and "with nothing due it reports nothing"; the all-clear's claims; rank 3 and 6 unknown rows | `0600-what-to-do-next.sh`, `0220-the-binding-itself.sh`, `0590-the-pre-flight.sh`, `0671-continued.sh`, `0460-maintenance-a-check-that-names-work-already.sh` |
| The record's columns (8 the probe, 9 the instrument), OBSERVED/UNKNOWN, an append that failed or wrote nothing, two writers at once; the three-argument drift | `0390-probes-what-reality-says-and-the-difference.sh` |
| The gate: `  probes             ok`, the FAIL path and `gate: FAIL (probes)`, skipped without a table; failures recorded under their names; candidates only outside `--gate` | `0400-candidates-what-a-model-proposed-and-nothing.sh`, `0170-mistakes-record-themselves.sh`, `0380-the-reconciler-reads-the-record-reached-besi.sh` |
| The not-known sentences for an unread declared list, everywhere they appear today | `0670-continued.sh`, `0671-continued.sh`, `0680-continued.sh`, `0681-continued.sh`, `0711-commissioning-a-check-says-it-could-not-be-a.sh`, 0600 |
| Detection outcomes of existing fixtures: no drift on the widget, sentry gives observability, a Dockerfile gives deploy, the stranger gives billing; adoption at session start and its drift-not-checked line | `0010-resolution.sh`, `0060-a-partial-backfill-a-pipe-at-a-table-and-a-m.sh`, 0680, `0580-tidying-with-the-checks-that-make-it-safe.sh`, `0200-generated-constitution.sh`, `0030-appends-onto-a-hand-written-last-line.sh` |
| Setup remote classification (`ssh -G`), own-checkout strictness | `0190-continued.sh`, `1130-unattended-work-runs-only-in-its-own-checkout.sh` |
| Fixture slugs from local `…/github.com/fixture/NAME.git` remotes | `1280-land-on-green-blind.sh` to `1289-land-on-green-round-9-blind.sh`, `1296-gate-friction-d-losses-blind.sh`, `1300-stuck-pr-page-blind.sh` to `1360-stuck-pr-page-last-ledger-row-blind.sh` (1340's tab case reads as no slug either way) |
| `felix_repo_slug` reached through one `remote get-url`; the slug from the engine's source checkout | `0350-what-it-verified-and-what-it-merges-are-the.sh`, `0110-a-base-ref-that-is-behind-its-remote.sh` |
| Callers of the slug: stack, classify, merge, gate evidence, repair | `0070-stack-provisioning.sh`, `0080-risk-classification.sh`, `0100-merging.sh`, `0130-only-the-gate-workflow-is-evidence.sh`, `0140-the-unattended-repair-acts-only-on-a-brief.sh` |
| Readiness states and the preflight row's reading | 0590, `0710-commissioning-a-seeded-check-reads-done-only.sh`, 0711 |
| Orphans named and refused; merge blockers for obligations | `0410-an-answer-that-is-neither-yes-nor-no.sh`, `0420-obligations-what-would-discharge-each-by-nam.sh`, `0996-continued.sh`, 0100 |
| Session start: owed rows repeat, unread rows on their own line, the all-clear said once and spent | 0671, 0680, 0681, 0710 |
| The deployed surface; awk names | `0640-the-deployed-surface-is-three-directories.sh`, `1497-lib-awk-gawk-names-blind.sh` |

Also unchanged: the engine names no project; `felix_detect` reports and never enables; Felix's own
detection stays `ci` (the Felix tree holds no file B12-B14 read, checked on this tree), so its caps hash
and receipt are unaffected; `felix next` and `felix gate` write nothing new to memory; no existing
assertion is renamed or removed; `tests/assertions.tsv` and `tests/red.tsv` are not edited here.

## 4. Assertions

**A0, for every fixture.** Git through `_fx_git` or `_fx_cd` under `$TMP` (parts 0002, 0003). **Lib
calls** run in a fresh `/bin/bash` sourcing `lib/resolve.sh` then the lib (and `lib/verify.sh` for
`felix_tree_id`), from `$FROOT/harness`. **Project dirs** are `$TMP/b19/<name>`, each name used once, so
each has its own `MEM/<name>`. **Stubs**: gh and ssh from `_fsgh_build` (`tests/lib/cm-stub.sh`; gh logs
its arguments to `$_fs_ghlog`, ssh maps `work` to github.com and any other host to itself and logs to
`$_fs_sshlog`). **Harness copies** with `_copy_content` (part 0004) and one line appended to one lib, run
as the CLI or, with `CLAUDE_PLUGIN_ROOT`, as the plugin, the way part 0671 runs its cucr plugin. **G**: a
repository with `pdir/` holding `p1 p2 p3`, committed as `m`, and the probes table row
`pfiles<TAB>-<TAB>-<TAB>ls -1 pdir<TAB>test -d pdir`. Worktrees with `git worktree add`; runs recorded with
`felix_probes_record PROJ WT "$(felix_tree_id WT "$FROOT")" "$(felix_probes_run PROJ WT)"`. Widget edits
(probes.tsv, capabilities, origin) are saved first and restored after. **[control]** marks an assertion
true before and after the fix; every other one is red before it.

### Part 1990 (omission surfaces and drift)

- **A1 (B1, B2a).** ROOT with `Dockerfile`, `.env.example`, `tests/t.sh` and `requirements.txt` of
  `sentry-sdk`; PROJ's probes.tsv grounds only `deploy`
  (`dk<TAB>deploy<TAB>-<TAB>ls -1 Dockerfile<TAB>test -f Dockerfile`), no capabilities file: the first row is
  exactly `felix<TAB>3 surface(s) nothing probes: observability, secrets, tests<TAB>ground each in PROJ/probes.tsv with a probe; felix probes says how`.
- **A2 (B2a).** The same ROOT with `.github/workflows/ci.yml`, `migrations/1.sql` and `stripe` added to its
  requirements (6 gaps): the probes row's what-field is
  `6 surface(s) nothing probes: billing, ci, database, observability, secrets, and 1 more`.
- **A3 (B2c, B3).** PROJ's `capabilities` a symlink whose target is gone: the output is exactly B2(c)'s row
  then B3's not-known row; exit 0.
- **A4 (B3).** No procedures.tsv, no mistakes.log: the procedures row is
  `felix<TAB>4 item(s) nothing answers: capability:deploy, capability:observability, capability:secrets, capability:tests<TAB>take a stance on each in PROJ/procedures.tsv; felix procedures lists them`;
  with procedures.tsv holding `ITEM<TAB>pre-deploy<TAB>a person<TAB>n` for each of the four: no procedures row.
- **A5 (B4a).** `MEM/<name>/candidates.tsv` holding a comment line and three 13-field rows whose field 6 is
  `ob_a`, `ob_a`, `ob_b`, no obligations.tsv:
  `founder<TAB>2 candidate obligation(s) proposed and not admitted: ob_a, ob_b<TAB>felix obligations lists them; a person admits one by copying its row into PROJ/obligations.tsv`;
  then obligations.tsv holding `TPL/obligations.tsv`'s first data row with field 1 set to `ob_b`: the row
  says `1 candidate obligation(s) proposed and not admitted: ob_a`.
- **A6 (B4b, c).** candidates.tsv absent: no candidates row; candidates.tsv a directory: exactly B4(c)'s row.
- **A7 (B1).** Across A1-A6: three fields per row, order probes then procedures then candidates, exit 0;
  a fresh bash sourcing only `lib/resolve.sh` and `lib/next.sh` can call `felix_next_unanswered`.
- **A8 (B5b, c).** `felix next` in the widget checkout with a capabilities file of `frontend` and a probes
  table grounding nothing: the output holds `  what nothing answers yet` and a line beginning
  `    felix    ` containing `surface(s) nothing probes: `; if it holds `item(s). Ranked by`, the number
  before it equals the number of owner lines above the heading; if not, it holds no `nothing due` and holds
  B5(c)'s closing line.
- **A9 (B6a, b, e).** The widget with a committed `pdir` of three files, G's probes row as its whole probes
  table, A8's capabilities file, and `FELIX_MEMORY` a fresh directory for these gates only. The first `felix gate` exits 0 and holds `  probes             ok`, the
  counts line, and
  `                     not compared with an earlier tree: no earlier run on another tree in this branch's history is recorded, so nothing was compared`.
  After committing the deletion of `pdir/p2` and `pdir/p3`, the second exits 0 and holds
  `                     changed since the last tree: pfiles 3 members -> 1 members, 2 fewer than on the last tree`.
- **A10 (B6c).** The second gate of A9 also holds a line beginning
  `                     surfaces nothing probes: ` that names `frontend`.
- **A11 (B6d) [control].** A blind row: `  probes             FAIL`, exit 1, and the failure recorded under
  `probes` (0400's case, rerun here).
- **A12 (B7).** G clean at `m`: every row recorded has 12 fields; field 10 equals `git -C G rev-parse
  HEAD`; field 12 `clean`; field 8 is `ls -1 pdir` **[control]**.
- **A13 (B7).** Field 11 is equal for two records in worktree A of G, differs between G and A and between
  G and a clone K of G, and holds no tab; an uncommitted `pdir/p4` makes field 12 `dirty`; a ROOT that is
  not a repository gives `-` in fields 10, 11 and 12.
- **A14 (B9c).** Runs recorded in order: R in G at `m` (3 files); worktree C whose side-branch commit on
  `m` adds `p4` and `p5`; worktree A whose commit `a` on `m` deletes `p2` and `p3`. A's four-argument
  drift prints `pfiles<TAB>3 members<TAB>1 members<TAB>2 fewer than on the last tree`.
- **A15 (B9e).** Then worktree B made at `m` (clean, so its tree id is R's): its four-argument drift prints
  exactly B9(e)'s row, once.
- **A16 (B9c).** Worktree D at `m` with an uncommitted `pdir/p4`, a run recorded there; then worktree E
  commits a README change `e` on `m`: E's four-argument drift has no `pfiles` row (the baseline is R, not D).
- **A17 (B9c) [control].** In E, record with an uncommitted `pdir/p4`, then commit it as `e2`: the drift at
  `e2` has no `pfiles` row (E's own dirty run qualifies).
- **A18 (B9c).** A 9-field run with tree id `oldtree` and `pfiles` count `9` appended last: A's
  four-argument drift is still A14's row.
- **A19 (B9b).** A repository U with no commit, TID `untree`: exactly B9(b)'s row.
- **A20 (B9a) [control].** Empty TID, four arguments: a row holding `no tree id`.
- **A21 (B8) [control].** Right after A14, the three-argument drift in A prints
  `pfiles<TAB>5 members<TAB>1 members<TAB>4 fewer than on the last tree` (C's run), as today.
- **A22 (B10).** The widget with `pdir` and the `pfiles` row committed and its own fresh `FELIX_MEMORY`:
  `felix probes` once; a linked worktree W on a side branch commits two more files in `pdir` and a run is
  recorded in W through the lib for the widget project; then a README change is committed in the widget
  checkout: `felix probes` there prints no `fewer than on the last tree` and no `more than on the last tree`
  for `pfiles`.

### Part 1991 (detection, slug and lookups)

- **A23 (B12-B14, B16, B17).** Each fixture a repository with every file committed; `felix_detect`
  compared sorted and space-joined:

| fixture | files | detected |
|:---|:---|:---|
| mono | root `package.json` `{"name":"mono","private":true,"workspaces":["apps/*"]}`; `apps/api/package.json` with dependencies express, stripe, @sentry/node, pg, openai; `apps/api/Dockerfile`; `apps/api/migrations/001.sql` | `api billing database deploy llm observability` |
| rails | `Gemfile` with `gem "rails"`, `gem "pg"`, `gem "devise"`, `gem "rack-attack"`, `gem "stripe"`; `db/migrate/1_init.rb`; `test/t.rb` | `api auth billing database ratelimit tests` |
| go | `go.mod` requiring `github.com/gin-gonic/gin v1.10.0` and `github.com/jackc/pgx/v5 v5.6.0` | `api database` |
| spring | `pom.xml` with artifactIds `spring-boot-starter-web` and `spring-boot-starter-security` | `api auth` |
| hono | `package.json` with dependencies hono and drizzle-orm | `api database` |
| cargo | `crates/web/Cargo.toml` with `axum = "0.7"`, `sqlx = { version = "0.7" }`, `governor = "0.6"`, `jsonwebtoken = "9"` | `api auth database ratelimit rust` |
| python | `requirements.txt` of `fastapi`, `asyncpg>=0.29`, `slowapi`, `PyJWT[crypto]` | `api auth database ratelimit` |
| dotnet | `src/Api/Api.csproj`: `<Project Sdk="Microsoft.NET.Sdk.Web">`, PackageReferences Npgsql, AspNetCoreRateLimit, Microsoft.AspNetCore.Authentication.JwtBearer | `api auth database ratelimit` |
| php | `composer.json` requiring laravel/framework and laravel/sanctum; `database/migrations/0001_init.php` | `api auth database` |

- **A24 (B16).** A bare `package.json` `{"name":"x","scripts":{"verify":"echo ok"}}`: no `frontend`. The
  react fixture (`react`, `react-dom`): `frontend` **[control]**; bare package.json plus three committed
  `.css` files: `frontend` **[control]**.
- **A25 (B11) [control].** A repository whose only manifests are force-added `node_modules/x/package.json`
  (express), `vendor/y/go.mod` (gin) and `third_party/z/Gemfile` (rails): no `api`; a plain directory
  holding the same: no `api`.
- **A26 (B14).** Each alone in a repository: `services/w/Dockerfile` gives `deploy`; `pkg/.env.example`
  gives `secrets`; `app/db/migrate/1_init.rb` gives `database`; `crates/x/Cargo.toml` with no dependencies
  gives `rust`.
- **A27 (B15) [control].** Root `.github/workflows/ci.yml` gives `ci`; `infra/main.tf` `iac`; root
  `tests/t.sh` `tests`; root `k8s/` `deploy`; an ignored, untracked root `Dockerfile` `deploy`;
  `sub/.github/workflows/ci.yml` no `ci`; `sub/tests/t.sh` no `tests`.
- **A28 (B17).** A root `package.json` with `prisma` plus a root `migrations/1.sql`: `database` printed
  exactly once.
- **A29 (B13) [control].** No `database` or `api` from a package.json key `"pgtools"`, `gem "pg_search"`,
  `warpgate = "1"` in Cargo.toml, or `psycopg-pool` in requirements.
- **A30 (B17, B18).** A git stub on PATH that exits 1 on `ls-files` and runs git otherwise, over a
  repository holding a root `.env.example`: `felix_detect` returns 2; `_felix_capability_union ROOT ""`
  non-zero; `felix_undeclared ROOT PROJ` returns 2 and prints nothing; `felix_procedures_items PROJ ROOT`
  returns 2.
- **A31 (B17) [control].** `felix_detect` on `$REAL_HARNESS/../..` prints exactly `ci`.
- **A32 (B19, B20).** With PATH holding the ssh stub, `felix_repo_slug` in a repository with each origin of
  B20 prints exactly the table's value, exit 0 each.
- **A33 (B19).** The ssh stub's log: no line for the https, path, file, `github.com` and `ssh.github.com`
  rows; one naming `work` for the alias row.
- **A34 (B19) [control].** No origin: nothing, exit 0.
- **A35 (B21).** `grep -cF 'github\.com[:/]##' "$FROOT/harness/felix"` prints `0`.
- **A36 (B22).** The widget checkout, origin `git@gitlab.com:acme/app.git`, stubs on PATH:
  `felix classify --base HEAD~0 --apply` exits non-zero, holds `no github remote; cannot label`, and
  `$_fs_ghlog` is unchanged.
- **A37 (B22).** Origin `git@work:acme/app.git`: `$_fs_ghlog` gains a line holding `--repo acme/app`.
- **A38 (B22) [control].** Origin `https://github.com/acme/app.git`: it gains a line holding `--repo acme/app`.
- **A39 (B23, B24).** `PROJ/routes.tsv` a directory: `felix_ready_wanted` returns 2;
  `felix_ready_report` prints exactly B24's row and returns 2.
- **A40 (B24).** `felix_ready_wanted() { printf 'some-skill\n'; return 1; }` defined after sourcing: the
  report is exactly B24's row (no `some-skill` row), status 2.
- **A41 (B24).** The preflight check (field 6 of the `preflight` row of `TPL/commissioning.tsv`, run with
  `ready.sh` sourced and `FELIX_PROJECT=PROJ`) exits non-zero with routes.tsv a directory.
- **A42 (B23, B24) [control].** No routes.tsv: nothing printed, status 0, and the preflight check exits 0.
- **A43 (B25).** `felix_obligation_rows() { return 1; }` defined after sourcing:
  `felix_obligations_orphans` prints nothing and returns 2.
- **A44 (B25) [control].** The first template row with field 6 set to `ghostp` (no such probe): it prints
  `ghostp` and returns 0.
- **A45 (B26).** A harness copy with `felix_obligations_orphans() { return 2; }` appended to
  `lib/obligations.sh`, run as the CLI in the widget checkout (obligations.tsv holding a valid row):
  `felix obligations` holds `could not be read whole`; `felix obligations --gate` exits 1.
- **A46 (B27).** From that copy's libs, `felix_merge_blockers` prints a line beginning
  `obligations<TAB>table<TAB>` that holds `could not be read`.
- **A47 (B28).** A session fixture shaped as 0671's cucr fixture with its own names (commissioning.tsv of
  one non-provider row `x_plain<TAB>-<TAB>-<TAB>-<TAB>-<TAB>true<TAB>-`, a valid receipt), run from a plugin
  copy whose `lib/commission.sh` ends with `felix_commission_rows() { return 1; }`: the context holds no
  `Commissioning: receipt`; `NAME.seen` is absent; the context holds
  `Commissioning: whether these answers are whole could not be read` and
  `commissioning.tsv (unknown: its rows could not be read whole)`.
- **A48 (B28) [control].** An unmodified copy, `NAME.seen` removed: the context says
  `Commissioning: receipt` and `NAME.seen` holds the topology.

## 5. Parts

`engine/harness/tests/parts/1990-omission-surfaces-and-drift-blind.sh` holds A1-A22, and
`engine/harness/tests/parts/1991-detection-slug-and-lookups-blind.sh` holds A23-A48. Each is at most 500
lines, registered in `engine/harness/tests/run` in numeric order after
`1600-felix-refuses-a-pattern-kill-blind.sh` and before `9990-…`, in no group of `groups.tsv`, and
committed before the run that lints it (lints read tracked files only). Each assertion name is the
sentence it proves, and is new.

## 6. Out of scope, with why

- **C089: session start and the pulse.** `hooks/session-start` cannot grow (780) and already repeats the
  owed `obligations_surveyed` request. **A candidate count in `felix status --tsv`**: status is home-scoped
  and part 1100 pins exactly five rows. **Drift in `felix next`**: drift needs a probe run that records
  facts, and `felix next` writes nothing. **Ingesting answer files in `felix next`**: that writes
  `candidates.tsv`; `felix obligations` does it. **Asking the founder to admit**: `docs/direction.md` §6
  asks once; B4 is a count, not an ask.
- **C056: member names per predicate** (a new log design; the log is count-only by design,
  `facts.sh`:94-96, README 287-298); **rotation** (a recorded choice, `facts.sh`:54-62); **one read per
  predicate** (0.52 s measured on the real 1.1 MB log); **recording a run at the merge base when none
  exists** (it needs a checkout of that commit; B9(e) says when nothing was compared).
- **C090: a `detect.tsv` table.** Direction §5 (lines 305-307) says additions to the detection patterns
  must escape before row 27 arms anything; a new table belongs to that build and to the founder's row-24
  amendment. The names here are engine code, landing on green as detection code does today. **Tests at
  depth** (it would change Felix's own caps hash for its `engine/harness/tests`). **Naming the absence of
  auth or ratelimit on an api** (an obligation; admitting one is a person's act). **Today's substring
  over-matches** (`next` in `next-auth`) and **lock files**. **Discovery rules and `_felix_why` text for
  auth and ratelimit**: `felix` cannot grow, and a discovery-rules row moves the discovery stamp; doctor
  says truthfully that they score on their own name. **Rewording the shared sentence "the capabilities
  this project declares could not be read"** for a detection failure: pinned in seven parts; the new rows
  say "this checkout shows or this project declares".
- **C096: GitHub Enterprise.** An https Enterprise URL that worked by accident (gh accepts a URL in
  `--repo`) now reads "no github remote"; accepted and said. `felix_remote_github_slug` and pr-status's
  `remote_match` parsing are unchanged.
- **C060: the session-start here-document's temporary-file failure** is closed by the same in-shell walk
  (B28) and not asserted separately: it cannot be injected portably.

### Not fixed: not a defect

- **C089, "session start is silent"**: it repeats the owed `obligations_surveyed` request while unanswered
  (`hooks/session-start`:676-748) and says `N provider row(s) recorded` once when answered; what it never
  says is the count of unadmitted candidates, which B4 puts in `felix next`.
- **C056, "worktree B's gate reports A's drop"**: on success the gate discards drift (`felix`:846-852) and
  on FAIL shows at most 12 lines, so the misattribution reached people through `felix probes`; after this
  batch the gate shows drift, with B9's baseline. **"The /admin to /admin/v2 swap is not seen"**: the
  stated limit of a count-only log, not this defect.
- **C060, "a merge verdict changes"**: none does; the receipt check passes commissioned and held alike
  (`escape.sh`:755-783, `commission.sh`:680-727), and `felix next` and `felix ready` re-run the report, so
  this only makes a wrong word true. **`felix_probe_state` letting the witness decide on a probe that
  printed nothing** is by design. **The grep fork in the union** already fails closed (`detect.sh`:228-242,
  since 2026-10-08).
- **C090, "high"**: detection reports and never enables (`detect.sh`:12-15); nothing is let through, so it
  stays medium.
- **C096, GitLab and local-path remotes**: Felix cannot work there anyway; only the diagnosis changes. The
  ssh alias is the material case.

## 7. Founder PR

None to merge: no `.github/workflows` change, no deny or escape row, no commission grant or table edit,
nothing published. Row 27 is not armed, so detection code lands on green today (direction §5). Two
founder actions follow the deploy, neither a merge: a project whose checkout the new rules read
differently gets the new capabilities adopted at its next session start, an uncommitted edit to
`projects/NAME/capabilities` in the home to commit; and its commission receipt then reads stale (the
detected surfaces and the table set moved) until `felix commission` is run there, which is his. Felix's
own detection stays `ci`, so its receipt and landing are unaffected.
