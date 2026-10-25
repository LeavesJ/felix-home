# Audit batch b10: escape channels see what they claim (contract)

Base: origin/main at 69b51a61. Branch: `claude/audit-b10-escape-channels-see-what-they-claim`.
Batch files: `engine/harness/lib/escape.sh` and `engine/harness/lib/classify.sh`.
This is a founder stop, because it changes the engine's escape channels. It is
built and tested in full, then opened as a draft labelled `needs-founder`, and
only the founder merges it.

"Today" in this document means origin/main at 69b51a61. Where a skeptic
corrected a claim or a severity in the brief, the correction is used here.

## 1. Defects

- **C015** (high). `felix_escapes` (escape.sh:340) and `felix_classify_diff`
  (classify.sh:187) read the changed paths from `felix_changed_paths`
  (resolve.sh:945-969). That runs `git diff --name-only` with git's default
  `core.quotePath`, so a name holding a byte past ASCII, a double quote, a
  backslash or a control character comes back C-quoted, beginning with `"`.
  Every anchored channel then misses it, and so does the basename test for
  enforcing tables.
  *Scenario:* a branch adds `.github/workflows/q"uote.yml`, a job that runs on
  push holding the repository's secrets. `felix_escapes` prints nothing, and
  `felix merge` says "nothing in it escaped the tree". The land-on-green tick
  passes it too: `_gt_files` maps only bytes outside printable ASCII to a
  founder row, and `"` is printable. A session's own `felix merge` merges
  `.github/workflows/déploy.yml` as well, and the tick holds that one for the
  founder (skeptic correction). A deny table under `projects/fé/` can be shrunk
  with no `verifier` row.
- **C021** (high). The durable channel (escape.sh:153-154) matches only paths
  under `migrations/`, `alembic/` and `prisma/migrations/`, and only
  upper-case `DROP TABLE`, `TRUNCATE ` and `DELETE FROM [^W]*$`. The `[^W]` test
  also skips any table name that contains a W.
  *Scenario:* a Rails `db/migrate/*.rb` with `drop_table :users`, a Flyway
  `db/migration/V7__drop.sql` with `drop table users;`, a TypeORM
  `src/migration/*.ts`, a drizzle `drizzle/0001.sql`, or any file adding
  `ALTER TABLE accounts DROP COLUMN email;` or `DELETE FROM Widgets;` merges
  with no person asked, and the rows are lost on deploy. Skeptic correction:
  `op.drop_table` under `alembic/` or `migrations/` is already caught by the
  path, and an upper-case `DROP TABLE` in a Flyway file is caught by the
  added-lines rule.
- **C081** (medium). The execute channel (escape.sh:116) names only
  `.github/workflows/` and `.github/actions/`. It does not name the files a
  workflow runs while holding a credential that only a run on main can get.
  *Scenario:* a push-to-main deploy job declares `environment: production` and
  runs `./scripts/deploy.sh`. A branch rewrites `scripts/deploy.sh` and merges
  with no escape. Its first run after the merge holds the production secrets.
  This is latent for every project governed today.
- **C006** (medium; the skeptics lowered it from high). Nothing on the merge
  path holds `docs/direction.md`. `_gt_direction` (green-tick.sh:304) matches
  only `projects/*/claude.md|docs/*roadmap*`. The risk table classes
  `docs/*.md` green with no channel, and no escape channel names the file.
  *Scenario:* a session folds a founder decision into `docs/direction.md` and
  opens an ordinary pull request. CI passes and the tick lands it, or the
  session runs `felix merge` itself. A direction change then binds without the
  founder's yes, and only the draft-plus-label habit stops it. The
  session-start half of the finding is refuted (§6).
- **C075** (medium). `project.json` is matched by basename in every directory
  (escape.sh:78, 160-167). In a product repository, editing any Nx
  `apps/*/project.json` or `libs/*/project.json`, or a root `project.json`,
  removes a line, so the `verifier` escape fires.
  *Scenario:* an ordinary build-config change in an Nx monorepo stops at
  `felix merge` with "this decides what stops, and the change removes from
  it". The founder has to clear it, which raises the founder-interruption
  count, the objective this project steers by.
- **C077** (medium; the skeptic re-kinded it as a silently dropped check, not
  a stall). `if [ -x "$FELIX_ESCAPE_SCAN" ]` (escape.sh:358) has no else
  branch. A missing or non-executable `bin/secret-scan` therefore drops the
  credential scan with no row.
  *Scenario:* the engine copy that judges a product's merge loses the
  scanner's execute bit, or loses `bin/`. A branch that adds a key then gets
  no `disclose` row and no `unknown` row, and `felix merge` says nothing
  escaped. For products this is the only credential check on the merge path.
  The self-governed half is refuted (§6).

## 2. Required behaviour

### Calls and fixtures used below

E is the engine under test. In the suite that is `"$FROOT/harness"`. Every call
runs in a subshell, standing in the fixture repository R, with stdin from
`/dev/null`:

- **ESC P B R**: `. "$E/lib/escape.sh"; felix_escapes P B R ""`. It prints
  lines of the form `channel<TAB>path<TAB>reason` and exits 0. Empty output
  means nothing escaped.
- **BLK P B R**:
  `. "$E/lib/resolve.sh"; . "$E/lib/verify.sh"; . "$E/lib/review.sh"; . "$E/lib/classify.sh"; . "$E/lib/evidence.sh"; . "$E/lib/escape.sh"; felix_merge_blockers P B R "$FROOT"`.
  These are the six libraries the kernel judge sources, in its order. It
  prints lines of the form `kind<TAB>subject<TAB>reason`.
- **CLS P B R**: `. "$E/lib/classify.sh"; felix_classify_diff P B R`, and
  **TIER** is `felix_classify_tier "<CLS output>"`.
- **PROT X**: `. "$E/lib/escape.sh"; felix_land_protected X`. When X is
  protected it prints one word and exits 0. When it is not, it prints nothing
  and exits 1.

Fixture defaults, unless an item says otherwise:

- P is an empty directory under `$TMP`. It holds no tables, so no
  project-declared channel can fire.
- R is a repository made with `git init -b main` under `$TMP`. It has one base
  commit on `main`, and the change is committed on a branch `feat` on top of
  it, with B = `main`.
- Fixture git commands go through `_fx_git` and `_fx_cd`, in subshells, as
  parts 0002 and 9990 require.
- "A row for X" means a line whose second tab-separated field is X, byte for
  byte.
- `<TAB>`, `<LF>` and `<DEL>` stand for the bytes 0x09, 0x0a and 0x7f.

### C015: path names reach every channel as the names they are

- **B1.** R has `core.quotePath true` in its own `.git/config`. On `feat`,
  commit `.github/workflows/déploy.yml` (é is UTF-8, `\303\251`) holding
  `on: push`. ESC prints an `execute` row for `.github/workflows/déploy.yml`,
  with the name exactly as created: no surrounding quotes and no octal escapes.
  Today it prints nothing.
- **B2.** The same file, staged and not committed: R is on `main` with its base
  commit, the file is added to the index, and B = `main`. ESC prints the same
  `execute` row. Today it prints nothing.
- **B3.** B1's ESC, called with `GIT_CONFIG_PARAMETERS="'core.quotepath=true'"`
  exported in the calling subshell, prints the same row. So does a call with
  `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.quotepath GIT_CONFIG_VALUE_0=true`
  exported instead. The caller's setting never decides how names are read.
  After `felix_escapes` returns, and after `felix_classify_diff` returns, in a
  shell that exported `GIT_CONFIG_PARAMETERS="'x.y=z'"` and then called the
  function directly (not inside `$( )`), `$GIT_CONFIG_PARAMETERS` is still
  exactly `'x.y=z'`.
- **B4.** git quotes some names even with `core.quotePath` off. Use these,
  each committed on its own branch under `.github/workflows/` and holding
  `on: push`:

  | Name | What git quotes |
  |---|---|
  | `q"uote.yml` | a double quote |
  | `b\ack.yml` | a backslash |
  | `t<TAB>ab.yml` | a tab |
  | `n<LF>l.yml` | a line feed |
  | `d<DEL>el.yml` | DEL |

  For each name, ESC prints at least one row with first field `unknown` and
  second field `CHANGED-PATHS`. Its reason contains the name exactly as
  `git -c core.quotePath=false diff --name-only` prints it: the quoted form,
  with its quotes and backslash escapes (for example
  `".github/workflows/q\"uote.yml"`). No row's path field is a piece of a
  name: nothing for `.github/workflows/t`, `.github/workflows/n` or `l.yml`.
  Today ESC prints nothing for any of them. Where the file system refuses a
  name, that name's assertions are skips that say so.
- **B5.** One branch holds both `.github/workflows/q"uote.yml` and
  `.github/workflows/plain.yml`. ESC prints B4's `unknown CHANGED-PATHS` row
  for the first and an `execute` row for `.github/workflows/plain.yml`. A path
  that can be read still goes through every channel.
- **B6.** On B4's double-quote branch, BLK prints a line with kind `unknown`
  and subject `CHANGED-PATHS`. It prints no line with kind `escape` and
  subject `unknown`.
- **B7.** The base holds `projects/fé/deny.tsv` with two rows,
  `Bash<TAB>rm -rf<TAB>a` and `Bash<TAB>git push --force<TAB>b`, and `feat`
  removes the second row. ESC prints a `verifier` row for
  `projects/fé/deny.tsv`. Today it prints nothing.
- **B8.** For CLS, P holds a copy of `$E/templates/risk.tsv`:
  - On B1's branch, CLS prints a finding with tier `red` and path
    `.github/workflows/déploy.yml`, and TIER is `red`. Today the finding is
    `yellow`, with the quoted name.
  - On B4's double-quote branch, CLS prints a finding with tier `unknown` and
    path field `CHANGED-PATHS`, and TIER is `unknown`. Today TIER is `yellow`.
- **B9.** Controls:
  - (a) `.github/workflows/plain.yml` gives ESC an `execute` row, and CLS
    (with the template) gives TIER `red`.
  - (b) `docs/café.md` on its own: ESC prints nothing.
  - (c) For (b), CLS prints no finding with tier `unknown`. A name that is
    merely non-ASCII is not unknown.

### C021: the durable channel covers the common migration layouts and SQL

- **B10.** Commit each of these paths on its own branch, holding the one line
  `x`. ESC prints a `durable` row for each:
  - `db/migrate/20261023000000_drop_users.rb`
  - `engines/billing/db/migrate/1_x.rb`
  - `db/migration/V7__init.sql`
  - `src/main/resources/db/migration/V8__more.sql`
  - `src/migration/1700000000000-Init.ts`
  - `Migrations/20231010_Init.cs`
  - `src/Data/Migrations/20231010_Init.cs`
  - `drizzle/0001_init.sql`
  - `db/changelog/db.changelog-master.yaml`
  - `liquibase/changelog.xml`

  Today ESC prints nothing for each. Also, in bash with `LC_ALL=C`,
  `[[ $p =~ $FELIX_ESCAPE_DURABLE_PATH ]]` holds for each path p after
  sourcing `$E/lib/escape.sh`. The stuck-PR page reads the constant that way.
- **B11.** Controls, durable today and after, by ESC and by `=~`:
  `migrations/1.sql`, `app/migrations/0002_x.py`, `alembic/versions/1_x.py`,
  `prisma/migrations/1_init/migration.sql`.
- **B12.** Not durable. Committed the same way, each of these gives ESC no
  output at all, and `=~` does not hold: `lib/migrations.rb`,
  `docs/migrating.md`, `drizzle.config.ts`, `CHANGELOG.md`, `db/seeds.rb`,
  `src/migrate.ts`, `changelog/unreleased/1.md`.
- **The added-line rule.** These are the destructive statements, with blanks
  meaning one or more spaces or tabs:
  - `DROP`, then `TABLE`, `SCHEMA`, `DATABASE` or `COLUMN`, followed by a
    blank, `;` or the end of the line.
  - `ALTER TABLE <name>`, with the word `DROP` later on the same line.
  - `TRUNCATE`.
  - `DELETE FROM <name>`.
  - `UPDATE <name> SET <column> =`.

  DELETE and UPDATE count only when the line holds no word `WHERE`, in any
  case, as a whole word; `nowhere` does not count as `WHERE`.

  A statement written with its keywords in capitals fires anywhere on an added
  line. For `TRUNCATE`, that means `TRUNCATE` followed by a blank, as today.
  Written in any other case, a statement fires only when it is the first
  non-blank text on the line. Lower-case `truncate` must also be followed by an
  optional `table` and one name, then optional blanks and `;` or the end of the
  line.

  However many lines fire, the added lines give at most one row,
  `durable<TAB>ADDED-LINES<TAB>…`.
- **B13.** Each line below is committed as the only line of `notes/case.txt`,
  on its own branch. ESC prints exactly one `durable<TAB>ADDED-LINES` row.
  Controls fire today; every other line is silent today.
  1. `DROP TABLE users;` (control)
  2. `drop table users;`
  3. `  Drop Table If Exists users;`
  4. `DROP SCHEMA public CASCADE;`
  5. `drop database app;`
  6. `ALTER TABLE accounts DROP COLUMN email;`
  7. `alter table accounts drop email;`
  8. `    DROP COLUMN email;`
  9. `TRUNCATE sessions;` (control)
  10. `truncate table sessions;`
  11. `truncate sessions;`
  12. `DELETE FROM Widgets;`
  13. `DELETE FROM nowhere;` (control: it fires today, and a substring test
      for "where" would silence it)
  14. `delete from users;`
  15. `DELETE FROM users` (control)
  16. `UPDATE users SET email = NULL;`
  17. `update users set active=false`
  18. `db.Exec("DELETE FROM sessions")` (control)
- **B14.** Each line below, committed the same way, gives ESC no output. Every
  one is a control, silent today and after.
  1. `DELETE FROM users WHERE id = 1;`
  2. `delete from users where id = 1;`
  3. `UPDATE users SET a = 1 WHERE id = 2;`
  4. `Truncate the log before rotating it.`
  5. `We drop tables we no longer need.`
  6. `CREATE TABLE users (id int);`
  7. `DROP INDEX idx_users_email;`
  8. `Update the set of rules.`
  9. `-- the old job used to delete from the queue here`

### C081: execute covers what a workflow holding main-only credentials runs

- **B15.** The base holds two files. `.github/workflows/deploy.yml` is exactly:

  ```
  on:
    push:
      branches: [main]
  jobs:
    deploy:
      runs-on: ubuntu-latest
      environment: production
      steps:
        - uses: actions/checkout@v4
        - run: ./scripts/deploy.sh
  ```

  `scripts/deploy.sh` holds `echo deploy`. `feat` edits `scripts/deploy.sh`.
  ESC prints an `execute` row for `scripts/deploy.sh` whose reason contains
  `.github/workflows/deploy.yml`. Today it prints nothing.

  The rule: a top-level `.github/workflows/*.yml` or `*.yaml` at the base holds
  main-only credentials when any line's first non-blank text is one of:
  - `environment:` (inline or block form)
  - `id-token: write`
  - `permissions: write-all`

  The files such a workflow runs are the changed paths that equal one of its
  words. Its text is split at every byte other than an ASCII letter, digit,
  `.`, `_`, `/` or `-`, and leading `./` and `/` are removed from each word.
  Also included is every changed path under a directory D that a `uses: ./D`
  line names. A path gets at most one `execute` row however many rules name
  it.
- **B16.** Each variant below gives an `execute` row for `scripts/deploy.sh`,
  with the reason naming that variant's workflow file:
  - (a) The job's environment in block form (`environment:` with
    `  name: production` on the next line), in
    `.github/workflows/release.yaml`.
  - (b) No environment, and a `permissions:` block holding `id-token: write`.
  - (c) No environment, and `permissions: write-all`.
  - (d) B15 with the step `run: bash scripts/deploy.sh --prod`.
  - (e) B15 with the step `run: ${{ github.workspace }}/scripts/deploy.sh`.
- **B17.** B15's workflow with the step `uses: ./tools/deploy-action`. `feat`
  edits `tools/deploy-action/index.js`, which the base holds. ESC prints an
  `execute` row for `tools/deploy-action/index.js`.
- **B18.** B15's workflow with the step `run: .github/scripts/deploy.sh`.
  `feat` edits `.github/scripts/deploy.sh`. ESC prints an `execute` row for
  it. Today it prints nothing.
- **B19.** With no workflow at all, `feat` changes a root `action.yml`, and
  another branch changes a root `action.yaml`. ESC prints an `execute` row
  for each. `PROT action.yml` prints `execute` and exits 0. Today ESC prints
  nothing, and PROT prints nothing and exits 1. This rule is carried by
  `FELIX_ESCAPE_EXECUTE`, so the land table and the stuck-PR page see it too.
- **B20.** Controls. Each gives no `execute` row for the changed path, today
  and after:
  - (a) A workflow on push whose job sets `env: KEY: ${{ secrets.PROD_KEY }}`
    and runs `./scripts/deploy.sh`, with no environment and no write
    permission. `feat` edits `scripts/deploy.sh`.
  - (b) Felix's own `.github/workflows/gate.yml`, copied from the repository
    that holds E (`"$REAL_HARNESS/../../.github/workflows/gate.yml"`; a skip
    if absent), sits at the base with a file `engine/harness/felix`. `feat`
    edits `engine/harness/felix`.
  - (c) B15's workflow, with `feat` editing `scripts/other.sh`, which the base
    holds.
  - (d) B15's workflow, with `feat` editing `myscripts/deploy.sh` and
    `scripts/deploy.sh.bak`, both held by the base. Neither gets a row.
  - (e) B15's workflow with its `environment:` line written as the comment
    `# environment: production`, and no other credential line. `feat` edits
    `scripts/deploy.sh`.
- **B21.** B15's workflow with the step `uses: ./.github/actions/deploy`.
  `feat` edits `.github/actions/deploy/action.yml`. ESC prints exactly one
  `execute` row for that path. This is a control.
- **B22.** No base. `main` holds B15's two files, committed, and
  `scripts/deploy.sh` is edited in the working tree and not staged.
  `ESC P "" R` prints an `execute` row for `scripts/deploy.sh`. With an empty
  base, the workflows are read from HEAD; a repository with no HEAD has none.
  Today it prints nothing.
- **B23.** Unknown, never silence. Use B15's fixture, checked out on `feat`.
  Then remove the loose object file of main's `.github/workflows/deploy.yml`
  blob from `R/.git/objects`; the fixture asserts that `git cat-file -e` on
  that blob now fails. ESC prints a row with first field `unknown` and second
  field `CHANGED-PATHS`, whose reason contains `.github/workflows`. BLK prints
  a line `unknown<TAB>CHANGED-PATHS<TAB>…`. Today ESC prints nothing.
- **B24.** In the judge's shell, on B15's fixture:
  `/bin/bash -c 'set -uo pipefail; for f in resolve verify review classify evidence escape; do . "$1/lib/$f.sh"; done; felix_escapes "$2" main "$3" ""' _ E P R`
  prints B15's `execute` row, and its stderr does not contain
  `unbound variable`.

### C006: a change to docs/direction.md escapes to the founder

- **B25.** The base holds `docs/direction.md` (`# direction`), and `feat`
  appends a line. ESC prints a row `direction` for `docs/direction.md` whose
  reason contains `founder`. Today it prints nothing.
- **B26.** `feat` creates `docs/direction.md` where the base has none: the
  same row. `feat` deletes it where the base has it: the same row.
- **B27.** In a repository whose base has no `docs/` directory, `feat` creates
  `DOCS/Direction.md`. ESC prints a `direction` row for `DOCS/Direction.md`.
  This Mac's file system folds case.
- **B28.** Controls. Created on a branch, each of these gives ESC no output:
  `docs/direction-notes.md`, `docs/directions.md`, `sub/docs/direction.md`.
- **B29.** On B25's branch, BLK prints the line
  `escape<TAB>direction<TAB>docs/direction.md: <reason>`.

### C075: project.json is an enforcing table only where Felix keeps one

- **B30.** R is a product repository. Its base holds three files:
  - `apps/web/project.json`: `{`, `  "name": "web",`,
    `  "outputPath": "dist/apps/web"`, `}`, one item a line.
  - `libs/ui/project.json`: the same shape.
  - a root `project.json`: `{`, `  "name": "root",`, `  "targets": "x"`, `}`.

  Each of these changes, on its own branch, gives ESC no output: (a)
  outputPath changed to `dist/web`; (b) `libs/ui/project.json` deleted; (c)
  the `targets` key removed from the root `project.json`, along with the comma
  before it. Today each gives a `verifier` row.
- **B31.** `PROT apps/web/project.json` and `PROT project.json` no longer
  print `escape-table`. Today each prints it. They may print
  `commission-table`, because commission.sh's own basename list
  (`FELIX_COMMISSION_TABLES`, batch 17's file) still names `project.json`, so
  only the absence of `escape-table` is asserted. `PROT
  projects/p/project.json` prints `escape-table` and exits 0, which is a
  control.
- **B32.** Controls, the same today and after:
  - (a) `projects/web/project.json` with a key removed: a `verifier` row.
  - (b) `some/dir/land.tsv` with the row `b.txt<TAB>version-above<TAB>-<TAB>-`
    added: a `verifier` row.
  - (c) `config/risk.tsv`, whose base holds two rows, with one removed: a
    `verifier` row.
  - (d) `projects/web/project.json` with a key added, where the line above
    gains a comma: no output.

### C077: a missing secret scan is said, never skipped

- **B33.** X is a copy of the engine. Run `cp -R "$E/lib" "$X/lib"` and
  `mkdir "$X/bin"`, copy `$E/bin/secret-scan` into `$X/bin/`, then
  `chmod 644` it. `feat` commits `notes/a.txt` holding `hello`.
  `. "$X/lib/escape.sh"; felix_escapes P main R ""` prints a row
  `unknown<TAB>ADDED-LINES<TAB><reason>` whose reason contains `secret scan`,
  and no `disclose` row. Today it prints nothing.
- **B34.** The same holds with `$X/bin/secret-scan` absent, and with `$X/bin`
  absent.
- **B35.** BLK through X, with the six libraries read from `$X/lib`, on B33's
  branch prints a line `unknown<TAB>ADDED-LINES<TAB>…`. It prints no line of
  kind `escape` for it.
- **B36.** Controls:
  - (a) A copy whose scanner is executable, on the same branch: no `unknown`
    row.
  - (b) B33's copy with the scanner not executable, on a branch that changes
    nothing (`feat` at `main`): ESC prints nothing.

### Structure

- **B37.** `engine/harness/lib/escape.sh` has at most 799 lines, its count
  today. `engine/harness/lib/classify.sh` has at most 500.
- **B38.** If the build adds a lib file, it is
  `engine/harness/lib/escape-channels.sh` and only that one. In that case:
  - `escape.sh` loads it itself.
  - `felix_land_trust_base engine/harness/lib/escape-channels.sh` exits 0.
  - In a copy of `$E/lib` without that file, sourcing `escape.sh` still
    defines `felix_escapes` and `felix_merge_blockers`. On B15's fixture,
    `felix_escapes` then prints a row `unknown<TAB>CHANGED-PATHS` and never
    nothing.

  If no such file exists, these assertions are skips that say so.

## 3. What must not change

**Interface.**

- Rows keep their shapes: `channel<TAB>path<TAB>reason` from `felix_escapes`,
  and `kind<TAB>subject<TAB>reason` from `felix_merge_blockers`, where empty
  means merge.
- An `unknown` row's subject is a base name, `CHANGED-PATHS` or
  `ADDED-LINES`, and nothing else. `cmd_merge` (felix:1930), `next.sh:105`
  and `receipt.sh:184` place their text by those subjects.
- `felix_merge_blockers` stays in escape.sh and prints exactly the kinds
  `commission escape evidence obligations probes unknown unverified`. Part 0100
  reads them out of the function's text with sed.
- `FELIX_ESCAPE_TABLES` stays a one-line, single-quoted assignment in
  escape.sh.
  - It holds `ecosystem.tsv`, `probes.tsv` and `obligations.tsv` as words, and
    `land.tsv` exactly once (parts 0650, 0400, 0450, 0990).
  - `FELIX_ESCAPE_EXEMPTION_TABLES` stays exactly `ecosystem.tsv land.tsv`
    (0990).
- `FELIX_ESCAPE_EXECUTE`, `FELIX_ESCAPE_AUTHORITY`, `FELIX_ESCAPE_EXCEPTION`
  and `FELIX_ESCAPE_DURABLE_PATH` stay defined, non-empty, after escape.sh is
  sourced.
  - They stay POSIX EREs that `grep -E` and bash `[[ =~ ]]` read the same way
    under `LC_ALL=C`. pr-status-state.sh:102-105 and land-table.sh:139 read
    them.
  - `felix_land_protected` fails closed to `unknown` when one is blanked
    (0990).
- `_felix_merge_gate_held` remains reachable after sourcing escape.sh, because
  green-tick.sh and part 1280 call it.

**Verdicts.**

- An unresolvable base prints one `unknown` row naming no channel. An empty
  base is not unknown (0090).
- Every existing channel fires where it fires today (0090, 0100, 0110, 0360,
  0370, 0600, 0990, 1520):
  - `execute` for `.github/workflows/` and `.github/actions/`
  - `authority` and `exception`
  - `durable` for `migrations/`, `alembic/` and `prisma/migrations/` paths,
    and for upper-case `DROP TABLE`, `TRUNCATE ` and `DELETE FROM` without
    `WHERE`
  - `disclose`
  - `verifier`: a shrink fires; an add is free except to an exemption table,
    where any change fires, compared byte for byte in file order
  - project rows: confine, `count:`, the `reviewed` clearance, and the
    `declared-unknown` rename
- An enforcing TSV table is still matched by basename in any directory:
  - `some/dir/land.tsv`, a root `ecosystem.tsv`, `t/deny.tsv` and
    `projects/<x>/<table>` (0990, 0090, 0994, 0110).
  - `_felix_escape_listed` still lists `engine/harness/templates/schemas.tsv`
    and `projects/any/risk.tsv`, and still does not list `db/schemas.tsv`
    (0730).
  - Only `project.json` changes where it matches.
- 1520's fail-closed rows are unchanged:
  - A tracked pipe and a corrupt index each give one unknown row.
  - A readable change gives no unknown row and exactly one `execute` row for
    `.github/workflows/ci.yml`.
  - Scanner exits 0, 1, 2 and 3 give nothing, `disclose`, unknown and unknown.
- Part 0400 still sees "probe library is not loaded" from a copy of six libs
  with no `bin/`. With no `bin/`, that copy now also prints C077's unknown row,
  which is right and does not touch the assertion.

**Mechanics.**

- `felix_escapes` stays offline and exits 0. It never blocks on a FIFO, because
  workflows are read from git objects, never from the working tree.
- Its output and status are the same under bash 3.2 with BWK awk as under
  bash 5 with gawk, and under `set -uo pipefail` (the judge's shell; parts
  1520 and 1530).
- Every rule the suite lints still holds for any lib the build touches:
  - `LC_ALL=C` on every sort, comm, join and uniq (0003, 0992).
  - Text tools that decide something run in the C locale (0994).
  - No `printf … | grep -q`; here-strings instead (0960).
  - No gawk-only awk names (1497).
  - Porcelain `git diff` carries `--no-ext-diff --no-textconv` (1530).
  - Digit brackets are spelled out; there are no associative arrays.
- A blob is read as stored, through `git cat-file blob` or a `git show` with no
  textconv, so no attribute or filter changes the workflow text that is read.

**Files.**

- `engine/harness/lib/resolve.sh` is not edited. It belongs to batch 12 and is
  over 500 lines.
- escape.sh does not grow (B37). classify.sh stays under 500 lines.
- If B38's file is created, land-table.sh changes only on line 97, to add it to
  `FELIX_TRUST_BASE`; land-table.sh is in no batch. No other file outside the
  batch is edited.
- `tests/run` gains exactly the two part lines, after 1600, and stays at or
  under 500 lines (part 1040; it is at 497 today).
- `assertions.tsv`, `red.tsv`, `plugin.json`, `HANDOFF.md` and
  `docs/handoff/` are not edited by the build.

## 4. Assertions

Every assertion name begins with `b10 A<n>:`, and every name is emitted on
every run. A fixture that cannot be built makes its assertions `bad` with the
reason. Skips happen only where an item names one: a file system that refuses
a name, no `gate.yml` beside the harness, or no B38 file. "(control)" marks an
assertion that is true both before and after the fix. Every other assertion
fails today.

**Part 1810: C015, C006, C075, C077 and structure**

| A | B | Fixture | Expect |
|---|---|---|---|
| A1 | B1 | R with core.quotePath true; feat commits `.github/workflows/déploy.yml` | ESC has `execute` for the raw name |
| A2 | B2 | the same file staged on main, nothing committed on top | ESC has `execute` for the raw name |
| A3 | B3 | A1's fixture; caller exports GIT_CONFIG_PARAMETERS `'core.quotepath=true'` | the A1 row |
| A4 | B3 | A1's fixture; caller exports GIT_CONFIG_COUNT/KEY_0/VALUE_0 quotepath=true | the A1 row |
| A5 | B3 | caller exports `'x.y=z'` and calls `felix_escapes` directly | `$GIT_CONFIG_PARAMETERS` reads `'x.y=z'` after (control) |
| A6 | B3 | the same with `felix_classify_diff` | unchanged after (control) |
| A7.1–A7.5 | B4 | one branch per name: `q"uote`, `b\ack`, `t<TAB>ab`, `n<LF>l`, `d<DEL>el` (`.yml`) | an `unknown CHANGED-PATHS` row whose reason holds git's quoted form |
| A8 | B4 | the tab and LF branches | no row whose path field is `.github/workflows/t`, `.github/workflows/n` or `l.yml` (control) |
| A9 | B5 | one branch with `q"uote.yml` and `plain.yml` | both the unknown row and `execute` for `.github/workflows/plain.yml` |
| A10 | B6 | A7.1's branch, BLK | a line `unknown<TAB>CHANGED-PATHS` |
| A11 | B6 | the same | no line `escape<TAB>unknown` (control) |
| A12 | B7 | base `projects/fé/deny.tsv` with two rows; feat removes one | `verifier` for `projects/fé/deny.tsv` |
| A13 | B8 | A1's branch, CLS with the template risk.tsv | a `red` finding for the raw name; TIER `red` |
| A14 | B8 | A7.1's branch, CLS with the template | a finding `unknown<TAB>CHANGED-PATHS`; TIER `unknown` |
| A15 | B9 | feat commits `.github/workflows/plain.yml` | ESC `execute`; CLS TIER `red` (control) |
| A16 | B9 | feat commits `docs/café.md` | ESC prints nothing (control) |
| A17 | B9 | the same, CLS with the template | no `unknown` finding (control) |
| A18 | B25 | base `docs/direction.md`; feat appends a line | ESC `direction` row; reason holds `founder` |
| A19 | B26 | feat creates `docs/direction.md` (base has none) | ESC `direction` row |
| A20 | B26 | feat deletes it (base has it) | ESC `direction` row |
| A21 | B27 | base with no `docs/`; feat creates `DOCS/Direction.md` | ESC `direction` row for `DOCS/Direction.md` |
| A22.1–A22.3 | B28 | feat creates `docs/direction-notes.md`, `docs/directions.md`, `sub/docs/direction.md` | ESC prints nothing (control) |
| A23 | B29 | A18's branch, BLK | the line `escape<TAB>direction<TAB>docs/direction.md: …` |
| A24.1–A24.3 | B30 | product R: outputPath edit; libs/ui deleted; root targets key removed | ESC prints nothing |
| A25 | B31 | — | PROT `apps/web/project.json` does not print `escape-table` |
| A26 | B31 | — | PROT `project.json` does not print `escape-table` |
| A27 | B31 | — | PROT `projects/p/project.json`: `escape-table`, exit 0 (control) |
| A28.1–A28.4 | B32 | the four keep-firing and stay-free cases | as B32 says (control) |
| A29 | B33 | engine copy X, scanner mode 644; feat adds `notes/a.txt` | `unknown<TAB>ADDED-LINES` row whose reason holds `secret scan` |
| A30 | B33 | the same | no `disclose` row (control) |
| A31 | B34 | X with `bin/secret-scan` absent | A29's row |
| A32 | B34 | X with `bin/` absent | A29's row |
| A33 | B35 | BLK from X's six libs on A29's branch | a line `unknown<TAB>ADDED-LINES`; no `escape` line for it |
| A34 | B36 | copy with an executable scanner, same branch | no `unknown` row (control) |
| A35 | B36 | A29's copy; feat at main | ESC prints nothing (control) |
| A36 | B37 | — | escape.sh ≤ 799 lines (control) |
| A37 | B37 | — | classify.sh ≤ 500 lines (control) |
| A38–A40 | B38 | when `lib/escape-channels.sh` exists | the three B38 checks; otherwise skips |

**Part 1820: C021 and C081**

| A | B | Fixture | Expect |
|---|---|---|---|
| A41.1–A41.10 | B10 | one branch per path, content `x` | ESC `durable` row for the path |
| A42.1–A42.10 | B10 | — | `[[ $p =~ $FELIX_ESCAPE_DURABLE_PATH ]]` under LC_ALL=C holds |
| A43.1–A43.4 | B11 | one branch per path | ESC `durable` row, and `=~` holds (control) |
| A44.1–A44.7 | B12 | one branch per path, content `x` | ESC prints nothing, and `=~` does not hold (control) |
| A45.1–A45.18 | B13 | one branch per line, as the only line of `notes/case.txt` | exactly one `durable<TAB>ADDED-LINES` row; 45.1, 45.9, 45.13, 45.15 and 45.18 are controls |
| A46.1–A46.9 | B14 | the same, one branch per line | ESC prints nothing (control) |
| A47 | B15 | B15's base; feat edits `scripts/deploy.sh` | `execute` for `scripts/deploy.sh`; reason holds `.github/workflows/deploy.yml` |
| A48.1–A48.5 | B16 | variants (a) to (e) | `execute` for `scripts/deploy.sh`, naming the variant's workflow |
| A49 | B17 | `uses: ./tools/deploy-action`; feat edits `tools/deploy-action/index.js` | `execute` for that path |
| A50 | B18 | `run: .github/scripts/deploy.sh`; feat edits it | `execute` for `.github/scripts/deploy.sh` |
| A51 | B19 | no workflows; feat changes a root `action.yml` | `execute` for `action.yml` |
| A52 | B19 | the same with `action.yaml` | `execute` for `action.yaml` |
| A53 | B19 | — | PROT `action.yml`: `execute`, exit 0 |
| A54.1–A54.6 | B20 | (a), (b), (c), (d) with two paths, (e) | no `execute` row for the changed path (control); (b) skips if gate.yml is absent |
| A55 | B21 | `uses: ./.github/actions/deploy`; feat edits its `action.yml` | exactly one `execute` row for it (control) |
| A56 | B22 | main holds B15's files; the script is edited unstaged; base "" | `execute` for `scripts/deploy.sh` |
| A57 | B23 | B15's fixture on feat, main's workflow blob removed, removal checked | ESC `unknown<TAB>CHANGED-PATHS` row; reason holds `.github/workflows` |
| A58 | B23 | the same, BLK | a line `unknown<TAB>CHANGED-PATHS` |
| A59 | B24 | B15's fixture, judge's shell, `/bin/bash` | the `execute` row |
| A60 | B24 | the same | stderr lacks `unbound variable` (control) |

## 5. Parts

Two new part files:

- `engine/harness/tests/parts/1810-escape-names-and-tables-blind.sh`: A1 to
  A40.
- `engine/harness/tests/parts/1820-escape-durable-and-execute-blind.sh`: A41
  to A60.

Both are written blind from this contract, and both are listed in
`tests/run` after 1600 in this order. They are not in `groups.tsv`. Each
builds its own fixtures under a `mktemp -d "$TMP/b10-XXXXXX"`, reads nothing
another part left, and runs alone through `--part`. Each stays under 1,000
lines (part 1040), and ideally under 500.

## 6. Out of scope, and why

**Not fixed: not a defect**

- **C006, the session-start half.** session-start:532 names
  `${PROJ}/CLAUDE.md` as required reading. projects/felix/CLAUDE.md:40-43
  names `docs/direction.md`, says it wins, and says any change to it waits for
  the yes. MEMORY.md's first line points there too. A fresh session reaches
  the file in one hop, and #452's hook line would only reorder that.
- **C077, the self-governed half.** `cmd_merge` lets a cache entry judge only
  when `felix_accepted_deploy_diff` matches main byte for byte, and that check
  compares the execute bit (`(m == "100755") != ex` in resolve.sh). The gated
  tree's own `executable-check` fails on a script that lost its bit. The
  refusal on the product path (B33-B36) is still built.
- **C015's side claims.**
  - `land-table.sh:329` feeds report-only would-refuse rows.
  - `classify.sh` is advisory, though it is fixed anyway (B8).
  - The self-judgement guard at felix:1872 is backed by the
    accepted-deploy-diff check at felix:1890-1905.
  - The tick already holds `déploy.yml` (green-tick.sh:285-290, 367).
- **C021's overstatements.** `op.drop_table` in a file under `alembic/` or
  `migrations/` is already durable by path, and an upper-case `DROP TABLE` in a
  Flyway file is already durable by the added-lines rule.

**Out of scope**

- **Other readers of `felix_changed_paths`.** The root fix is to read with `-z`
  inside `felix_changed_paths` (resolve.sh, batch 12's file). That would also
  fix `evidence.sh:72` (batch 11), `land-table.sh:329` and `felix:1872`
  (batch 13). This batch reads real names inside its own two files and turns a
  name git still quotes into `unknown`. Whoever moves `felix_changed_paths` to
  `-z` must keep a name holding a line feed or tab from reaching a
  newline-separated list unflagged. Today git's quoting is what flags it.
- **green-tick.sh's `_gt_direction` and #452 (A32).** These are batch 2's
  file. After this batch, the tick runs `felix merge`, gets the `direction`
  escape, and writes a `refused` row, so it never lands such a pull request.
  #452 would still make that a `founder` row before any attempt, and is still
  worth landing.
- **The gate's skip of a missing secret-scan** (projects/felix/gate.sh:367-379)
  is batch 8's file.
- **README:141-142 and :180** describe the durable and execute channels. That
  is batch 21's file. Once this lands it should name the classes covered here
  and the limits below.
- **The template risk.tsv** has advisory migration and SQL rows (rows 13, 14
  and 24). They set a tier and stop nothing, and the file is not this batch's.
- **The stuck-PR page** (pr-status-state.sh, batch 3) reads the path
  constants, so B10 and B19 reach it. It does not evaluate the added-line
  rule, the workflow-reference rule, or a `direction` channel (it uses
  `_gt_direction`). It can therefore show "would land" for a pull request
  `felix merge` refuses, while the tick still refuses it.
- **ORM verbs as content** (`drop_table`, `remove_column`, `RemoveField`,
  `DeleteModel`, `op.drop_*`). The files that hold them sit on migration paths,
  which now escape whole. Matching the verbs in every added line would stop
  ordinary test and app code.
- **`db/schema.rb` and `db/structure.sql`.** A schema dump records what the
  migrations did, and merging one writes nothing a revert cannot restore.
- **Lower-case SQL in the middle of a code line**
  (`execute("delete from users")`) is not matched. That is run-time code, not
  a deploy-time migration, and matching it would stop ordinary code. In
  capitals it is matched, as today.
- **Repository secrets** (`secrets.X`) do not make a workflow
  credential-holding (B20a). A branch's own CI run in the same repository can
  already read them before any merge, so the merge boundary is not where they
  are kept. Environment-gated secrets and OIDC credentials are main-only.
- **Paths keying cannot see everything a job runs.** It misses a script
  reached through `cd`, `working-directory`, a variable, `npm run`, `make`, a
  dependency, or a root `uses: ./` action's entry point. The skeptic named
  this class unclosable by path keying.
- **Other CI systems** (`.gitlab-ci.yml`, `azure-pipelines.yml`) are out of
  scope.
- **Workflow triggers are not parsed.** A workflow holding main-only
  credentials counts whatever its triggers are.
- **Roadmaps merged by a session's own `felix merge`.** The brief names only
  `docs/direction.md`. The tick already holds roadmaps.
- **TSV tables still match by basename in any directory.** 0990 pins
  `some/dir/land.tsv`, and escape.sh:98-100 records that trade-off; product
  data files with those names are rare. `project.json` differs because every
  Nx app and lib has one. An Angular workspace moved to Nx keeps
  `projects/<lib>/project.json`, which still matches.
- **`FELIX_COMMISSION_TABLES` still lists `project.json` by basename**
  (commission.sh:52, batch 17's file). `felix_land_protected` therefore still
  calls an Nx `apps/web/project.json` a commission table. That is report-only
  land-table wording, not a merge stop. The stuck-PR page already limits its
  commission tag to `projects/<name>/<file>`.
- **Non-ASCII case folding of `docs/direction.md`** (for example `ſ`) is not
  matched at the merge. The tick holds any path outside printable ASCII for
  the founder.
- **A direction pull request after the founder's yes** is merged by hand, as
  every escape is.

## 7. Founder PR

This batch's pull request is itself the founder PR. It changes the engine's
escape channels:

- the escape.sh constants and the per-path loop in `felix_escapes`
- `_felix_escape_listed`'s entry for `project.json`
- the secret-scan else branch
- if B38's file is created, one word in land-table.sh:97

Open it as a draft labelled `needs-founder`; only he merges it. Main's engine
judges this pull request, so its own `felix merge` does not see the new
channels, and it must be held by hand. Under main's engine, its added lines
(this contract's SQL examples, and the blind parts' fixtures) already escape
as `durable ADDED-LINES`. That is expected.

Nothing else needs the founder: no `.github/workflows` change, no deny row, no
commission grant and no publishing.

One optional edit is his to make after it lands. `docs/direction.md:14-18`
would then be stale, and editing that file is a direction change.

Replace:

```
(§10). The land-on-green tick holds such a pull request only once contract
amendment A32 lands (`lib/green-tick.sh` treats this path as a direction
document; it is being built on `claude/direction-read-first`). Until then,
open it as a draft labelled `needs-founder`, or the tick will land it on
green.
```

with:

```
(§10). `felix merge` refuses such a pull request as a `direction` escape, so
neither a session nor the land-on-green tick can land it; the tick records
the refusal. Contract amendment A32 (`claude/direction-read-first`) would
also have the tick hold it as a founder row before trying. Open it as a draft
labelled `needs-founder` all the same, so it is never attempted.
```

## 8. Red

Before any engine change, parts 1810 and 1820 ran alone under macOS awk (BWK)
and bash 3.2, in one `--part` run from a fresh temporary directory, against
the lib files of origin/main at 69b51a61. The branch held only the two parts
and their two lines in `tests/run`.

**Result: 132 assertion names emitted, 76 failed, 53 passed, 3 skipped.** The
run also printed 62 `fixture floor` assertions from the suite's preamble. They
all passed and are not counted above. No assertion was `bad` for a fixture that
could not be built, and every name in A1 to A60 was emitted.

**The 76 that failed** are the defects: A1-A4, A7.1-A7.5, A9, A10, A12-A14
(C015); A18-A21, A23 (C006); A24.1-A24.3, A25, A26 (C075); A29, A31-A33
(C077); A41.1-A41.10, A42.1-A42.10, A45.2-A45.8, A45.10-A45.12, A45.14,
A45.16, A45.17 (C021); A47, A48.1-A48.5, A49-A53, A56-A59 (C081).

**The 3 skips** are A38, A39 and A40. The contract makes them skips while the
build adds no `lib/escape-channels.sh`.

**The 53 that passed.** Every one is marked "(control)" in its name, so each
was expected to pass today. None is an assertion that should have failed and
did not. They are of two kinds.

- *True today and must stay true.* These exercise code that fires today, so
  they pin existing behaviour against the fix: A15, A16, A17, A27,
  A28.1-A28.4, A34, A36, A37, A43.1-A43.4, A45.1, A45.9, A45.13, A45.15,
  A45.18, A55. A5 and A6 are of this kind too: today `felix_escapes` and
  `felix_classify_diff` leave `GIT_CONFIG_PARAMETERS` alone, and the two
  assertions refuse a fix that exports a `core.quotepath` override into the
  caller's shell.
- *True today because the rule they guard does not exist yet (vacuous today,
  a guard against the fix over-reaching).* They can fail only once the new
  rule is in. A8: no row holds a piece of the tab or line-feed name, and ESC
  prints no row at all today. A11: BLK prints no `escape unknown` line, and
  no `unknown` line of any kind today. A22.1-A22.3: no direction rule exists,
  so nothing fires on the near-miss names. A30: ESC prints no `disclose` row
  because it prints nothing for the unreadable scanner. A35: ESC prints
  nothing for a branch that changes nothing, as it prints nothing for any
  branch here. A44.1-A44.7: the new path rules are what could over-match
  them. A46.1-A46.9: the new SQL rule is what could over-match them.
  A54.1-A54.6: no workflow-reference rule exists, so no path can be
  over-matched. A60: ESC runs none of the new code under `set -u` today.
