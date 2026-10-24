# Audit fix batch b22: Snapshot builds, is tested, and ships the Stop fix

Contract, 2026-10-24. Branch `claude/audit-b22-snapshot-builds-is-tested-and-ships-the`, cut from origin/main
69b51a61 (0.49.307). Defects C113, C114, C037 and C039 of the 2026-10-24 register. Parts 2050 to 2069.

Publishing the public snapshot is the founder's act. This batch builds and tests what makes the snapshot
buildable and safe to run. It never runs a publish and never pushes to LeavesJ/Felix. Section 7 lists what
only the founder can do.

**Measured on this tree before writing**, read-only in a scratch `mktemp -d` (nothing in the home, the memory
root or another worktree was written):

- The scrub plan, built as snapshot.sh:115-117 and :256-263 build it, hands out these tokens: elenchus
  another, veldra third, bazaar fourth, sv2-apps fifth, behaviorchangebench sixth, webapp seventh,
  elenchus-capital-research eighth, team1 ninth.
- Over a `git archive` of the published set, the halves rule (snapshot-scrub.sh:149-154) changes exactly five
  lines. Four are ordinary words: incident.sh:68 `src/web/app.py` (it becomes `src/sev/enth.py`),
  cm-stub.sh:124 `a web app`, 0700-continued.sh:521 `a web app` and :523 `the web app`. The fifth is a
  deliberately split name, projects/felix/qualification.tsv:112 `"$1" vel dra`, which becomes `thi rd`.
- A copy of the scrub that refuses a whitespace or slash separator leaves all five alone, the deliberate split
  included. cm-stub.sh, 0700-continued.sh and qualification.tsv all hold the joined name too. So neither
  criterion tells the five apart (section 6).
- snapshot-audit.sh was probed on fixture FA and snapshot-scrub.sh on fixture FS. Every expected output below
  is what the shipped scripts print today, except the items marked new.

## 1. Defects

**C037** (high, overclaim). The public engine, LeavesJ/Felix at 0.49.232, resolves its Stop hook from `$PWD`.
Claude Desktop starts every hook in the main checkout while the session works in a git worktree, so the public
hook judges the wrong tree. Main has had the fix since #399 (2abedde4, 0.49.245, 2026-10-02), unpublished for
22 days; 33 first-parent fix( commits separate a1af3c00 from main, counting #460. *Scenario:* a stranger
installs from github.com/LeavesJ/Felix and works in Claude Desktop. The agent edits files in
`.claude/worktrees/x` and stops. The Stop hook runs in the clean main checkout, sees no commit and no edit
there, and exits 0 with no hold and no record. The public README (line 38) says that moment is the one Felix
catches.

**C113** (low; the kind is corrected to a naive scrub rule plus stale acknowledgements, since the stop is
loud, not a silent stall). Three parts:

- (a) `~/.felix/memory/zz` exists, empty, created and last modified 2026-10-01 18:04, and the suite does not
  recreate it. No `@name` row covers it, so snapshot.sh:175-176 dies at the names stage, printing the name.
  Only a person can clear it: invariant 6 bars Felix from deleting a memory root, and an `@name` row is a
  person's judgment.
- (b) Three rows of .snapshot-ack.tsv (lines 29-31) are keyed on engine/harness/tests/run. That file was split
  into parts on 10-11, and no line of it matches them now. The comment at lines 24-28 still calls webapp "an
  untracked stub", although #388 (2dc171de) put projects/webapp on main.
- (c) webapp is scrub token `seventh` now, and the halves rule rewrites the four ordinary lines into
  `a sev enth` and `src/sev/enth.py`. After the scrub nothing flags them, so the garbled comments would be
  published without a word. The scrub header's claim, "only where no ordinary word can be meant"
  (snapshot-scrub.sh:28-29), is false for them. *Scenario:* the founder says "publish". snapshot.sh stops at
  the names stage. Once that is cleared, the build publishes comments that read `a sev enth`.

**C114** (low; the verifier corrected "no gate" and the scenario). No suite part runs snapshot.sh,
snapshot-scrub.sh or snapshot-audit.sh; gate.sh only syntax checks them with `bash -n`. #447 (0db47b70,
2026-10-18) rewrote the home-pointer read (snapshot.sh:152-156) after the last run, on 09-26. Most regressions
fail closed while the script runs: the stray check, the read failure, the planted secrets and the suite on the
exact commit all stop it. But no check covers a narrowed address, halves, pieces or stand-in rule in
snapshot-audit.sh. *Scenario:* a PR narrows one of those rules. The gate stays green, and the next
founder-attended snapshot misses a leak it used to catch.

**C039** (low; one verifier said medium, and the batch record keeps low). Only the owner part of the finding
holds. remote_forms (snapshot.sh:141-145) begins with `sed 's|.*/||'`, so the owner of every remote_match is
thrown away before anything is searched for, although the comment at :132-133 says remotes are searched
"whole". Main's manifests have declared two owners besides the founder, joshcodes42 and stratum-mining. The
scrub rewrites an owner only together with its repository (snapshot-scrub.sh:143), and the `part` check finds
an owner only beside a token. The rest of the finding is not a defect (section 6). *Scenario:* a lesson
promoted into projects/felix/CLAUDE.md names a governed project's owner alone. The scrub leaves it, the audit
prints "none open", and the printed push would publish it.

## 2. Required behaviour

Paths are relative to the home's root. The shipped scripts are projects/felix/snapshot.sh, snapshot-scrub.sh
and snapshot-audit.sh, reached from a part at `$REAL_HARNESS/../../projects/felix/`.

### Fixtures

**FA (audit).** A directory ROOT. A NAMES file holding `quillfen`, `tidewater` and `zub`. AUTHOR
`lead@corpmail.org` and OTHER `pat@corpmail.org`, both assembled at run time, never written literally (section
5). SLUG `quillcorp/lantern-home`. ROOT/a.md, one case a line:

| line | text | expected row (path, line, name, rule) |
|---:|---|---|
| 1 | `the QuillFen tool` | a.md 1 quillfen name |
| 2 | `xxquillfenyy` | a.md 2 quillfen name |
| 3 | `a quill here` | a.md 3 quillfen halves |
| 4 | `nothing` | none |
| 5 | `the fen there` | a.md 5 quillfen halves |
| 6 | `qu ill fen` | a.md 6 quillfen pieces |
| 7 | `quil\x6cfen` (a backslash, then x6c) | a.md 7 quillfen name |
| 8 | `q[u]illfen` | a.md 8 quillfen name |
| 9 | `quil.fen` | a.md 9 quillfen stand-in |
| 10 | `'uillfen` (a quote first) | a.md 10 quillfen stand-in |
| 11 | `xuillfen` | none |
| 12 | `quil(l\|x)fen` | a.md 12 quillfen stand-in |
| 13 | `quil[lx]fen` | a.md 13 quillfen stand-in |
| 14 | `quillfen and tidewater` | exactly one row: a.md 14 quillfen name |
| 15 | `zxb and z.b` | none (under four characters, no stand-in) |
| 16 | `mail AUTHOR now` | none |
| 17 | `mail OTHER now` | a.md 17 @pat@corpmail.org address |
| 18 | `[OTHER](mailto:OTHER)` | exactly one row: a.md 18 @pat@corpmail.org address |
| 19 | `[AUTHOR](mailto:AUTHOR)` | none |
| 20 | `x@example.com y@sub.example.org z@h.invalid w@a.test` | none |
| 21 | `deploy[bot]@users.noreply.github.com 41898282+github-actions[bot]@users.noreply.github.com` | none |
| 22 | `git@github.com:o/r.git` | a.md 22 @git@github.com address |
| 23 | `repo: QuillCorp/Lantern_Home` | a.md 23 quillcorp/lantern_home repository |
| 24 | `quillcorp:lanternhome` | a.md 24 quillcorp:lanternhome repository |
| 25 | `xquillcorp/lantern-home` | none |

Also under ROOT: far.md (`a quill`, `b`, `c`, `the fen`: halves three lines apart); nul.bin (`quill`, one NUL
byte, `fen`, newline); docs/quillfen-notes.md (`plain`); and lnk, a symbolic link whose target is
`../quillfen`.

**FS (scrub).** PLAN is one line, ending in a space, as snapshot.sh writes it:
`quillfen<TAB>seventh<TAB>a seventh governed project<TAB>quillcorp/quillfen-site `. notes.md has the fifteen
lines of B14 and B17. x.sh holds `quillfen=1` and `echo "$quillfen"`; unlisted.md holds `quillfen in prose`;
y.sh holds `quillfen=1`, `seventh=2` and `echo "$quillfen $seventh"`; z.md holds `quillfen=1`. LIST is
NUL-separated paths, as each case names them.

**FD (driver).** Under the part's temporary directory T:

- O, a bare origin. H, a clone of O on branch `main`, standing for the home.
- P, the public fixture: one commit on `main` holding `LICENSE`. U, a user home whose basename is `umberwick`.
- M, a memory root holding `lantern/` and `tidewater/` (`qz/` added at B22).
- Q, a pointed-at home whose path holds a space (T/`other home`), holding `projects/fernbrook/`.

Commits on H's main. C0, C1a and C1b are pushed to O, which makes marigold token `another` and fennel token
`third`:

- **C0**: projects/lantern/project.json with `"remote_match": "quillcorp/lantern-home"` on its own line; byte
  copies of the three shipped scripts in projects/lantern/; projects/lantern/autonomy (`fixture grant`);
  engine/harness/README.md (`the engine`, `a mari gold line`); .gitignore (`*.tmp`); README.md
  (`install from LeavesJ/Felix`); .claude-plugin/marketplace.json (`{}`).
- **C1a**: projects/marigold/project.json (remote_match `brackenhall/marigold-site`) and
  engine/harness/notes.md (`the marigold gate runs`).
- **C1b**: projects/fennel/project.json (remote_match `zq/fennel-tools`).
- **C2**, later: .snapshot-ack.tsv holding `@name<TAB>qz<TAB>fixture leftover, not a project`.
- **C3**, later: engine/harness/plants.md, eight lines: 1 `ask brackenhall about it`, 2 `the quillcorp desk`,
  3 `from LeavesJ/Felix`, 4 `a tidewater note`, 5 `a fernbrook note`, 6 `a saltmarsh note`, 7
  `a umberwick note`, 8 `plain words only`.

Every FD run executes H/projects/lantern/snapshot.sh (the fixture's copy) with HOME=U, FELIX_MEMORY=M and
FELIX_HOME unset, passing `--public-clone P` and `--out` set to a path that does not yet exist. U/.felix-home
is absent unless a case says "pointer"; then it holds two spaces, Q's path, two spaces and a newline.

### snapshot-audit.sh (FA)

- **B1** A call with two arguments, a NAMES that is not a file, or a ROOT that is not a directory exits 2,
  with `usage: snapshot-audit.sh NAMES AUTHOR ROOT [SLUG] < paths` on stderr and nothing on stdout.
- **B2** For `a.md`, `far.md`, `nul.bin`, `docs/quillfen-notes.md` and `lnk` on stdin (NUL-separated), with
  SLUG given, it exits 0. Each row is five tab-separated fields: path, line (from 1), name, rule, hash. The
  hash is `printf '%s\n' "<the line>" | git hash-object --stdin`.
- **B3** A name is found in any case and inside a longer word (a.md 1, 2).
- **B4** Halves up to two lines apart are found, and both lines get a row (a.md 3, 5). Halves three lines
  apart get none (far.md has no row).
- **B5** Adjacent words that join into a name are found (a.md 6, pieces).
- **B6** A decoded copy is searched too: a `\x` escape (a.md 7) and a one-letter bracket class (a.md 8) are
  read, and NUL bytes are dropped (nul.bin 1). Each row's rule is `name`.
- **B7** One character can stand in for a letter: a mark inside the name, a mark in first position, a group, a
  two-letter class (a.md 9, 10, 12, 13, rule `stand-in`). A letter in first position is not one (a.md 11, no
  row), and a three-letter name has no stand-in (a.md 15, no row).
- **B8** A line holding two names gets exactly one `name` row (a.md 14).
- **B9** A path is read as line 0 (docs/quillfen-notes.md, line 0, quillfen, name). A symbolic link reads as
  its target (lnk, line 1, quillfen, name).
- **B10** The paths `a.md` and `missing.md` exit 2. stderr holds `snapshot-audit: cannot read missing.md`, and
  a.md's rows are still printed, the same rows as in B2.
- **B11** Addresses. AUTHOR passes, and so do the reserved domains, `[bot]` at GitHub's no-reply domain, and a
  Markdown link holding AUTHOR (a.md 16, 19, 20, 21: no row). OTHER stops, and so does a Markdown link holding
  it, once a line, with the leading bracket dropped (a.md 17, 18: name `@pat@corpmail.org`). `git@github.com`
  stops (a.md 22). That last case pins today's design; if the founder decides a rule for it (section 7, item
  2), it changes with that decision.
- **B12** With SLUG, the home's owner/repo gets rule `repository`: any case, `/` or `:` between, any
  separators in the repository (a.md 23, 24). With a letter before the owner it gets none (a.md 25). With no
  SLUG argument, no row has rule `repository`.

### snapshot-scrub.sh (FS)

- **B13** One argument, or a PLAN or LIST that is not a file, exits 2 with
  `usage: snapshot-scrub.sh PLAN LIST` on stderr. An empty LIST exits 0 and changes nothing.
- **B14** With LIST = notes.md and x.sh it exits 0. notes.md keeps 15 lines, unlisted.md is byte-identical,
  and lines 1 to 8 read exactly:

  | line | before | after |
  |---:|---|---|
  | 1 | `see quillcorp/quillfen-site now` | `see OWNER/seventh now` |
  | 2 | `see quillcorp:quillfen-site now` | `see OWNER:seventh now` |
  | 3 | `the quillfen gate` | `the a seventh governed project gate` |
  | 4 | `projects/quillfen/CLAUDE.md` | `projects/seventh/CLAUDE.md` |
  | 5 | `set QUILLFEN_HOME first` | `set SEVENTH_PROJECT_HOME first` |
  | 6 | `subquillfen` | `subseventh` |
  | 7 | `Quillfen runs` | `a seventh governed project runs` |
  | 8 | `the quillfen-site repo` | `the a seventh governed project repo` |

- **B15** x.sh becomes `seventh=1` and `echo "$seventh"`, and `bash -n x.sh` exits 0.
- **B16** Stops: each exits non-zero and leaves its file byte-identical. LIST = y.sh puts
  `uses quillfen as a shell variable and already has one named seventh; a person renames it` on stderr. LIST =
  z.md puts `uses quillfen as a shell variable in a file that is not shell` on stderr.
- **B17** The halves and stand-in rewrites keep today's bytes. In the B14 run, notes.md lines 9 to 15:

  | line | before | after |
  |---:|---|---|
  | 9 | `a quill fen here` | `a seven th here` |
  | 10 | `see src/quill/fen.py` | `see src/seven/th.py` |
  | 11 | `the quill-fen form` | `the seven-th form` |
  | 12 | `the quill_fen form` | `the seven_th form` |
  | 13 | `quil.fen` | `seve.nth` |
  | 14 | `plain words` | `plain words` |
  | 15 | `a<TAB>quill<TAB>fen` | `a<TAB>seven<TAB>th` |

- **B18** (new) Each line that the halves rule or the one-character stand-in rule changes is reported on
  stdout, one line per changed line, rule and name, beginning `scrub: <rule> <name> <path>:<line>`. `<rule>`
  is `halves` or `stand-in`, `<name>` is the plan's name, `<path>` is exactly as LIST gives it, `<line>`
  counts from 1, and any further text follows after a space. The B14 run's stdout is exactly six such lines:
  halves for notes.md 9, 10, 11, 12 and 15, and stand-in for 13. Lines changed only by the owner/repo,
  repository or whole-name rules (1 to 8) get none, and neither does x.sh. A run with no halves or stand-in
  rewrite prints nothing on stdout. The report never enters a scrubbed file; B14 and B17 still hold.
  snapshot.sh passes it through to its own output (B24).
- **B19** The header of snapshot-scrub.sh no longer claims the pieces are rewritten "only where no ordinary
  word can be meant". It says they can take ordinary words and that each such rewrite is reported for a person
  to read. `grep -c 'only where no ordinary word can be meant' projects/felix/snapshot-scrub.sh` prints 0.

### snapshot.sh, the fixture's copy (FD)

- **B20** With FELIX_MEMORY set to an empty directory (no `lantern/`), the run exits 1, stderr holds
  `no lantern directory in the memory root`, and no `<out>/build` exists.
- **B21** With the pointer naming T/nowhere (a directory without `projects/`), the run exits 1 and stderr
  holds `the home the engine points at, <T>/nowhere, has no projects/ to read`.
- **B22** The C113(a) stop stays loud and unchanged. With `qz/` in M and no row on origin/main, the run's exit
  status is 1 and stderr holds
  `snapshot: audit names too short to search for; exclude each with a reviewed @name row, or rename:` and a
  line that is exactly `  qz`, and does not name `zq`. No `<out>/build` exists. C2 committed on H but not
  pushed gives the same result: only origin/main's acknowledgements count.
- **B23** With C2 pushed, a run with `--source <C2>` and `--expect-tree 0` passes the names stage. Its stdout
  line beginning `names: ` holds `1 of memory's excluded by a reviewed row`.
- **B24** That run's stdout has a line beginning `audit: ` holding both `2 rewritten` and `none open`, a line
  `built tree    <40 hex>`, and a line `DIFFER`; the run exits 1. Under `<out>/build`:
  - engine/harness/notes.md reads `the another governed project gate runs`;
  - engine/harness/README.md line 2 reads `a anot her line`, and stdout holds the B18 line for it, beginning
    `scrub: halves marigold ` and ending `engine/harness/README.md:2`;
  - projects/ holds only `lantern`, and its project.json's remote_match reads `LeavesJ/Felix`;
  - no file named `autonomy` exists anywhere;
  - the three scripts under projects/lantern/ are byte-identical to the shipped ones.

  A second run with `--expect-tree <that tree id>` prints `MATCH` and exits 0.
- **B25** The cross-check fails closed. H's working copy of projects/lantern/snapshot-scrub.sh is replaced,
  uncommitted, by a wrapper that runs the shipped scrub with the same arguments and then rewrites the word
  `install` to `instail` in every listed file. A run with `--source <C2>` and `--expect-tree 0` exits 1, and
  stderr holds `the scrub changed lines the audit reads no name on:` and a line `  README.md:1`. The working
  copy is restored afterwards.
- **B26** With C3 pushed, the pointer set and `--name saltmarsh`, and no `--expect-tree`, the run exits 1.
  stdout has `audit: STOP`. For plants.md lines 4, 5, 6 and 7 it has a line
  `  engine/harness/plants.md:<n> [<name>, name] <text>`, naming `tidewater`, `fernbrook`, `saltmarsh` and
  `umberwick`. Each is followed by a line beginning `      ack: engine/harness/plants.md\t` (a literal
  backslash and t). Lines 3 and 8 get no such line, and `<out>/clone` does not exist. Line 5 is reachable only
  through the trimmed pointer path, the one with the space (#447); line 7 only through the basename of HOME.
- **B27** (new, C039) Every owner of a remote_match that any manifest on main has declared, the home's own
  included, is an audit name, read as the scrub plan reads owner/repo (snapshot.sh:261). The exception is the
  public slug's owner, `LeavesJ`. An owner is searched whole (the audit normalizes it), never split into
  components. In the B26 run, plants.md line 1 gets `[brackenhall, name]`, line 2 gets `[quillcorp, name]`,
  and line 3 gets none.
- **B28** (new, C039) An owner whose normalized form is under three characters is not an audit name and does
  not stop the run. It is said instead: the stdout line beginning `names: ` holds the owner, `zq`, and the
  words `not searched`. This holds in the B23 run and in the B26 run.
- **B29** No FD run creates or moves a ref in P: after every run, `git for-each-ref refs/heads` in P prints
  only `main`, at its first commit. No FD run prints `Nothing was pushed`.
- **B30** The comment at snapshot.sh:132-133 says the remotes source searches each owner whole, except the
  public repository's owner. It no longer calls "whole" a form that drops the owner.

### Data and text, checked by command at the branch head

- **B31** Compared with origin/main, .snapshot-ack.tsv loses exactly four rows: the three whose first field is
  `engine/harness/tests/run`, and the incident.sh row `23e57464...`, which B32 voids. No non-comment row is
  added or changed. The detect.sh and evidence.tsv rows and the seven `@name` rows are byte-identical. No
  comment says "untracked stub". The comment says webapp has been a governed project on main since #388 and is
  scrubbed as a token, and that the tests/run rows were dropped on 2026-10-24, since no line has matched them
  since the 10-11 split.
- **B32** The four ordinary lines (incident.sh:68, cm-stub.sh:124, 0700-continued.sh:521 and :523) are
  reworded so the halves rule no longer matches them: for example "a web application", and an example path
  holding no project's halves. incident.sh:68 still says the longest match wins over a bare file name.
  `git grep -n -i -E '(^|[^a-z0-9])web[^a-z0-9]{1,8}app([^a-z0-9]|$)' HEAD -- engine projects/felix README.md .gitignore .claude-plugin/marketplace.json assets`
  prints nothing. Optional and slow (minutes): the shipped scrub over an archive of the published set, with
  the real plan built as above, reports exactly one line, projects/felix/qualification.tsv:112.
- **B33** Line budgets: projects/felix/snapshot.sh at most 509 lines (it is 509 now and must not grow);
  snapshot-scrub.sh at most 500; engine/harness/tests/run at most 500. snapshot-audit.sh stays byte-identical
  to origin/main: no audit rule changes in this batch.
- **B34** The two new parts name no governed project, no owner of one (joshcodes42, stratum-mining), no split
  form of a name (such as `web app`), no literal address outside the reserved domains, and never the home's
  own owner/repo in any spelling. The independence scan and the rest of the gate pass with them.

### C037: checked at the founder's run, not by a part

- **B35** Once this batch has landed and section 7 items 1 and 2 are on main, `projects/felix/snapshot.sh`,
  run from the home's main, gets past the names stage and prints an audit line reading `none open`. On the
  clone it names: `git -C <out>/clone show HEAD:engine/harness/hooks/stop | grep -c felix_hook_enter` prints
  at least 1; engine/.claude-plugin/plugin.json's version is at least 0.49.245; and the suite line snapshot.sh
  prints reads `0 failed` (that suite includes part 0204).
- **B36** After the public PR merges,
  `gh api repos/LeavesJ/Felix/contents/engine/.claude-plugin/plugin.json --jq .content | base64 -d` shows
  B35's version.

## 3. What must not change

- **The audit's rules and the scrub's rewritten bytes.** snapshot-audit.sh is untouched (B1 to B12); every
  scrub rule keeps today's output, halves and stand-in included (B14 to B17), the only addition being stdout.
  No existing part runs either; 2050 pins both (controls).
- **snapshot.sh's stops and the order it runs in.** The names-stage stops (self memory directory, pointer,
  empty sources, short names, `@name` rows read only from main and only out of the memory source); the
  raw-bytes, consent, shell-parse, stray, phrase, code and `part` checks; and that it never pushes and prints
  the push instead. B20 to B26 and B29 pin these as controls; no existing part does.
- **The self-test.** The founder runs it:
  `--source a3eee3c --base f6341ba --public-readme --expect-tree f5a4d6f` and
  `--source a8ab281 --base 3091a76 --public-readme --expect-tree 5455d56`. It needs the home's fetch and the
  public repository, and today it stops on `zz` like any run. Nothing here changes a built byte: the report is
  stdout, and the owner names change only what is searched for.
- **The published set and the "Withheld, and why" list** (snapshot.sh:216-224, :490-506); **the detect.sh and
  evidence.tsv acknowledgements and the seven `@name` rows**, byte for byte.
- **The Stop hook's payload-cwd resolution on main**, C037's fix, which this batch does not touch:
  parts/0204-hooks-stand-where-the-session-stands.sh.
- **The cm-stub fixtures, whose comments B32 rewords**: tests/lib/cm-stub.sh and the parts that build through
  it (0060-a-partial-backfill-a-pipe-at-a-table-and-a-m.sh, 0190-continued.sh, 0700-continued.sh,
  0710-commissioning-a-seeded-check-reads-done-only.sh). No assertion line changes, so the verifier channel's
  count confine holds.
- **incident.sh's behaviour; only the comment at line 68 changes.** It is run by 0070-stack-provisioning.sh,
  0330-one-rollup-one-file.sh, 0360-what-felix-merge-records-and-what-it-hands-g.sh,
  0370-a-receipt-that-cannot-claim-more-than-it-kno.sh, 0994-bash-s-own-collation-and-the-bsd-text-tools.sh
  and 0996-continued.sh.
- **The suite's floor and guards.** No fixture git command is refused, the run stays inside its temporary
  directory, and the checkout's remotes do not move: 0001-the-origin-guard-and-the-temporary-directory.sh,
  0002-fixture-git-commands-stay-in-tmp.sh, 0003-the-lint-the-origin-record-and-the-exit-trap.sh and
  9990-the-run-stayed-inside-its-temporary-directory.sh.
- **red.tsv's reading of a published snapshot's base** (1010-the-record-this-branch-carries.sh), and
  **gate.sh's `bash -n` loop over `projects/*/*.sh`**.
- **Files this batch never edits**: engine/harness/tests/assertions.tsv, red.tsv,
  engine/.claude-plugin/plugin.json, HANDOFF.md and docs/handoff/. The landing step records the new count, not
  the build.

## 4. Assertions

"Red" means false before the fix and true after. "Control" means true both before and after. Fixtures are
those of section 2.

| # | B | part | check | kind |
|---|---|---|---|---|
| A1 | B1 | 2050 | audit with two arguments: exit 2, usage on stderr, stdout empty | control |
| A2 | B2 | 2050 | FA run exits 0; a.md 1's row is exactly `a.md<TAB>1<TAB>quillfen<TAB>name<TAB><hash of "the QuillFen tool">` | control |
| A3 | B3 | 2050 | a.md 2: name | control |
| A4 | B4 | 2050 | a.md 3 and 5: halves; far.md: no row | control |
| A5 | B5 | 2050 | a.md 6: pieces | control |
| A6 | B6 | 2050 | a.md 7 and 8: name; nul.bin 1: name | control |
| A7 | B7 | 2050 | a.md 9, 10, 12, 13: stand-in; no row for 11 or 15 | control |
| A8 | B8 | 2050 | a.md 14: exactly one row, quillfen | control |
| A9 | B9 | 2050 | docs/quillfen-notes.md line 0; lnk line 1 | control |
| A10 | B10 | 2050 | a.md plus missing.md: exit 2, stderr names missing.md, a.md's rows equal A2's | control |
| A11 | B11 | 2050 | address rows for a.md 17, 18 (once) and 22; none for 16, 19, 20, 21 | control |
| A12 | B12 | 2050 | repository rows for 23 and 24; none for 25; none at all without SLUG | control |
| A13 | B13 | 2050 | scrub with one argument: exit 2, usage; empty LIST: exit 0 | control |
| A14 | B14 | 2050 | notes.md 1 to 8 exact; 15 lines; unlisted.md unchanged | control |
| A15 | B15 | 2050 | x.sh exact; `bash -n` exits 0 | control |
| A16 | B16 | 2050 | y.sh and z.md: non-zero exit, stderr text, file unchanged | control |
| A17 | B17 | 2050 | notes.md 9 to 15 exact | control |
| A18 | B18 | 2050 | B14 run's stdout: exactly six report lines (9, 10, 11, 12, 15 halves; 13 stand-in), each naming quillfen and the listed path | red |
| A19 | B18 | 2050 | scrub with LIST = x.sh alone: stdout empty | control |
| A20 | B20 | 2051 | empty memory root: exit 1, stderr text, no build | control |
| A21 | B21 | 2051 | pointer to a directory without projects/: exit 1, stderr text | control |
| A22 | B22 | 2051 | `qz` with no row: exit 1, message, `  qz`, no build, no `zq` | control |
| A23 | B22 | 2051 | C2 committed, not pushed: same as A22 | control |
| A24 | B23, B24 | 2051 | C2 pushed, `--expect-tree 0`: exclusion text, `2 rewritten`, `none open`, tree id, DIFFER, exit 1 | control |
| A25 | B24 | 2051 | same run's build: phrase, line-2 bytes, only lantern, LeavesJ/Felix, no autonomy, scripts identical | control |
| A26 | B18, B24 | 2051 | same run's stdout holds `scrub: halves marigold ` ... `engine/harness/README.md:2` | red |
| A27 | B24 | 2051 | `--expect-tree <id>`: MATCH, exit 0 | control |
| A28 | B25 | 2051 | wrapper scrub: exit 1, stray message, `  README.md:1` | control |
| A29 | B26 | 2051 | C3, pointer, `--name saltmarsh`: STOP; hits and ack lines for 4 to 7; none for 3 or 8; no clone; exit 1 | control |
| A30 | B27 | 2051 | same run: `[brackenhall, name]` on line 1, `[quillcorp, name]` on line 2 | red |
| A31 | B28 | 2051 | the names lines of A24's and A29's runs hold `zq` and `not searched` | red |
| A32 | B29 | 2051 | after all runs P has only `main`, at its first commit; no run printed `Nothing was pushed` | control |

B19, B30 and B31 to B34 are checked by the commands they state. B35 and B36 are the founder's.

## 5. Parts

Two new files, written blind from this contract:

- `engine/harness/tests/parts/2050-snapshot-audit-and-scrub-blind.sh`: B1 to B18, A1 to A19.
- `engine/harness/tests/parts/2051-snapshot-run-blind.sh`: B20 to B29, A20 to A32.

Each gets one `. "$HERE/parts/<file>"` line in engine/harness/tests/run, after the last part numbered below it
and before the `! alias .` line ahead of 9990. The driver goes from 497 to 499 lines. Neither file enters
groups.tsv: each builds its own fixture and reads nothing the other writes.

Rules for both:

- Reach the shipped scripts at `$REAL_HARNESS/../../projects/felix/`. If one is missing, or `perl` is, emit
  every assertion as `skip` with the reason (for example "no projects/felix/snapshot-*.sh beside this
  harness"), never as a pass.
- 2051 never runs the shipped snapshot.sh in place: its HOME_TOP would be the real checkout, and its first act
  is a `git fetch` of the real origin. It runs only H's copy, always with `--public-clone P` and a new `--out`
  under the part's temporary directory, and with HOME, FELIX_MEMORY and FELIX_HOME set as FD says. The suite
  exports FELIX_HOME (part 0004), so it must be unset for these runs. No case may reach the network.
- 2051 first reads `id -un`, lower-cased and stripped to letters and digits, as L; the machine source searches
  for it. If L is under three characters, every FD assertion is a `skip` naming L, since every run then stops
  at the names stage by design. If L occurs, case-insensitively, in any file of H's published set, A24 to A29
  are `skip`s naming L. Every assertion name is emitted on every run, whatever the scripts answered.
- Fixture git commands follow the suite's fixture rules (`_fx_git` and `_fx_cd`, as part 0002 checks). Commit
  each part before any lint run, since lints read tracked files only. No pattern kill, and no background job
  left behind.
- Bash 3.2 and bash 5, BWK awk and gawk: no `case` inside `$( )`; no tab IFS over fields that may be empty;
  spelled digit brackets (`[0123456789]`); `LC_ALL=C` for sort and comparisons; no associative arrays; no
  gawk-only builtins; quote `$(( ))`.
- B34 holds for both files. Assemble AUTHOR, OTHER and every planted address at run time (as in `"$_a@$_d"`)
  so that no line of the file is an address. The real snapshot audits these files when it publishes them.

## 6. Out of scope, and why

**C113(c): which criterion.** The auditor sketched rewriting halves only where the joined name is in the file;
I also tried refusing a whitespace or slash separator. Measured on this tree, both fail on the evidence's own
lines. The first would still garble cm-stub.sh:124 and 0700-continued.sh:521 and :523, whose files hold
`cmwebapp`. The second would stop scrubbing the deliberate `vel dra` at qualification.tsv:112, a project's
name assembled from pieces that no person could acknowledge. No mechanical test tells ordinary words from a
deliberate split; only a person can. So the rewrite stays, each halves or stand-in rewrite is put in front of
that person (B18), the header stops claiming otherwise (B19), and the four ordinary lines are reworded (B32).
Having the scrub read acknowledgement rows was considered and not chosen: it adds a second authority input to
the scrub, and a line that also holds a whole name would still need a second row.

**C113: no lint for writes to the real memory root.** `zz` was made once, at 2026-10-01 18:04, and never
touched again. The suite exports `FELIX_MEMORY=$TMP/memory` at part 0004:16, and the verifier found it does
not recreate `zz`. An end-of-suite check of `~/.felix/memory` would also go red whenever any other session on
the machine made a directory there. The leftover is the founder's (item 1). Nor is the stop a silent stall:
die() prints the message and the name and exits 1 (snapshot.sh:50, :176), and B22 keeps that.

**Also not done.** A lint that keeps acknowledgement rows live: it would put every engine edit to an
acknowledged line behind a row change, and the file's own rule is "Editing the line voids its row" (a void row
waives nothing). Rows for the 41 hits that stop the audit once `zz` is cleared (40 address lines and the
stand-in `oterm1` at 0530-continued.sh:491): each is a person's row by design, and the run prints every one
(item 2). Scheduling C114's self-test: it needs the home's fetch and the public repository, so it is the
founder's run.

**C039, not a defect.** Third-party words (the TSMC-subcontractor test, Retnovation, a point72 case folder),
the Claude auto-memory under ~/.claude/projects, and repositories elsewhere under ~/Documents. The audit's
stated scope is "accidents of our own authoring" (snapshot.sh:72), with its sources listed at :122-140; it
never promises a search for general confidential words, and `--name` exists for a run's extra words (:65,
:165). The memory source lists directory names, not file contents (:160), so reading ~/.claude/projects would
add `-Users-...` folders, not the word TSMC. ReserveGrid-OS is caught: `LeavesJ/ReserveGrid-OS` is
projects/veldra's remote_match, and the verifier's fixture line naming it was flagged.
`git grep -i -E 'tsmc|joshcodes|stratum|retnovation|point72'` over the published set finds nothing on main. So
the proposed seventh source, `.snapshot-names.tsv`, is not built.

**C037: a Status line in the home README.** Not done. The home README is published with the engine that fixes
the gap, so the line would be false the moment it went out. Only the public README itself can carry it, and
changing that is publishing (item 4).

**A deny row refusing a session's push to LeavesJ/Felix.** Not needed by these defects. deny.tsv:135 refuses a
push to main only, so a session could push a `snapshot/*` branch, which is public once pushed. If the founder
wants that push to be his alone, the row is his to write and merge.

## 7. Founder PR

This batch's own PR needs nothing only the founder may merge: no .github/workflows change, no deny or escape
row, no commission grant. Its edits to .snapshot-ack.tsv only remove rows that waive nothing (B31).

Shipping the Stop fix is his, in this order, after the batch lands:

1. **The memory leftover.** Either `rmdir ~/.felix/memory/zz`, which refuses if the directory is not empty, or
   a PR adding this row to .snapshot-ack.tsv:
   `@name<TAB>zz<TAB>engine exercise leftover under the memory root, empty since 2026-10-01 18:04 (made while part 0990's projects/zz fixture was written), not a governed project (reviewed <date>)`
2. **The rows the run prints.** Run snapshot.sh once (item 3's first command). It stops with `audit: STOP` and
   prints each unacknowledged line with its `ack:` row. Today those are about 40 address lines and one
   stand-in:
   - `git@github.com` in SSH remotes: setup.sh:81, tests/lib/inventory-blind.sh, tests/assertions.tsv, and
     parts 0190, 0610, 0920, 0930, 0996 and 1130;
   - `tok@github.com` and `SECRETTOKEN@github.com`, URL credentials in fixtures;
   - `git@ssh.github.com`, `git@gitlab.com`, and `noreply@anthropic.com` (lib/own.sh);
   - the stand-in `oterm1` at tests/parts/0530-continued.sh:491.

   For each line you judge harmless, add its printed row (`<path><TAB><hash><TAB><why>`) to .snapshot-ack.tsv,
   all in one PR, and merge it. The hashes must be the run's, not this document's: any later edit to a line
   changes them. Or decide instead that SSH transport users (`git@<host>`) and URL userinfo before
   `@github.com` are no person's address; Felix then adds that rule to snapshot-audit.sh as its own change,
   and B11's `git@github.com` case flips with it.
3. **The publish.** In the home's main checkout, at or after this batch and items 1 and 2:
   ```
   git -C /Users/a14808/Documents/Felix pull --ff-only
   /Users/a14808/Documents/Felix/projects/felix/snapshot.sh
   ```
   Read the audit and every line beginning `scrub: `, check B35 on the clone it names, then run the two
   commands it prints:
   ```
   git -C <out>/clone push https://github.com/LeavesJ/Felix.git snapshot/<day>
   gh pr create --repo LeavesJ/Felix --base main --head snapshot/<day> --title <subject> --body-file <out>/pr-body.md
   ```
   Merge on green public CI and check B36. Then, in the home, run `felix maintenance --ran snapshot` and
   commit projects/felix/maintenance.log.
4. **Only if item 3 waits.** A direct PR to LeavesJ/Felix's README.md appending this sentence to the
   **Partial** cell of the Status table:
   `In Claude Desktop, which runs a session in a git worktree, this engine (0.49.232) judges the main checkout at a stop instead of the worktree; the fix (0.49.245) is not yet published here.`
   Remove it when item 3 lands.
