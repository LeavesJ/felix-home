# Audit batch b21: README claims match the engine

Batch b21 of the audit fixes of 2026-10-24, branch
`claude/audit-b21-readme-claims-match-the-engine`, cut from origin/main at 69b51a61
(0.49.307, #460). It changes `README.md` and the closing lines of `felix install`
(`engine/harness/felix`, for C099), and adds two parts in 2030-2049. README.md follows
`docs/direction.md`, which this batch never edits. No other engine behaviour changes. The
brief is `batches/b21.json`. Where a skeptic corrected a claim or a severity, the
correction is followed and named.

No existing lint covers these claims. Parts 0830 and 0840 read only the README's
`## Try it` section. So this is not a README-only batch that an existing lint can carry,
and it adds two parts.

**Terms**, used by every item:

- **README**: `README.md` at the checkout root. A part reads `"$REAL_HARNESS/../../README.md"`.
- **Section NAME**: the lines after the line that begins `## NAME`, up to but not including
  the next line that begins `## ` (a `### ` line does not end it), or the end of the file. The
  sections read are `Why not just run the tests in CI?`, `Status`, `Where it's going` (ASCII
  apostrophe) and `Install`. **Uninstall part**: the lines of the Install section from the
  line `### Verify and uninstall` to the section's end.
- **Flat text** of some lines is made in five steps: remove every backtick and every `*`,
  turn tabs into spaces, join the lines with one space, squeeze runs of spaces to one, and
  lower-case A-Z. Every pattern below except those in B19-B20 is an ERE matched against
  flat text, and is written in lower case.
- **Sentence**: a piece of flat text split at every `. ` (a full stop and a space). The last
  piece runs to the end.
- **Negated**: a sentence that matches `(^|[^a-z])(not|never|no|nor)([^a-z]|$)` or contains `n't`.
- **Status row**: a line of the Status section that begins `| **`. The **Partial row** is
  the one that begins `| **Partial**`.
- **Bullet**: a line of a section that begins `- `, together with the lines after it, up to
  but not including the next line that begins `- `, a blank line, or the section's end.
- **Red on base**: the assertion fails on 69b51a61. **Control**: it holds before and after.

## 1. Defects

**C008 (high; both skeptics kept it).** README.md:287-291 says an old pass stops counting
when "the program its first word names is now a file of a different size". Since #304
(97ccb117, 2026-10-02), the epoch hashes only `cut -f1-6` of `felix_probes_run`
(lib/epoch.sh:93-123). The `word@size` token is field 7, kept out on purpose
(lib/probes.sh:359-366). `felix_verify_current` compares only the tree id and the epoch.
README.md:387 (Status, Partial) still blames "which `git` is on PATH", which #304 removed.
*Scenario:* a toolchain upgrade replaces `cargo` with a file of a different size, and every
probe prints what it printed before. The green receipt stays current, so Stop and
`felix merge` accept it, while the README says that pass no longer counts. A reader of
Status chases a PATH dependence that no longer exists. *Correction followed:* the
`core.abbrev=auto` calls are at lib/verify.sh:400, 403 and 407, not 418.

**C017 (high; both skeptics kept it).** README.md:408-415 says "Three things come first"
(corpus, retire list, dry run) and "If it finds nothing the plain session misses, Felix will
narrow to the obligations people name". Direction says otherwise:
- row 18 (direction.md:163) and roadmap §5 as amended 10-01
  (docs/2026-09-23-roadmap.md:128-130, 382-386): a weak result is investigated, not
  narrowed on;
- direction.md:63: "Do not narrow Felix";
- the 10-19 lane order (§5) puts the corpus 3rd, the dry-run lease 5th and the retire
  re-key 6th.

*Scenario:* a stranger reads the public README, which `projects/felix/snapshot.sh`
publishes by default. It tells them Felix will shrink to a checking tool if one experiment
is weak, which contradicts the founder's 10-01 ruling. *Correction followed:* the §8 rows
are direction.md:432-433 and the stale-text entry is :453, not 433-434 and 454.

**C007 (medium, following the first skeptic's correction; the second kept high).**
README.md:455-457 says "Nothing merges on its own unless you run `felix automerge
--enable`". The README never names `felix land`. `felix land --install`
(lib/green-install.sh:155-188) loads a LaunchAgent that every 300 s runs `felix merge` on
a green pull request with nobody present, then deploys a landing that changed engine/
(lib/green-tick.sh:225-271, called at 431 and 438). The Status table and the uninstall list
(README.md:530-539) omit it. *Scenario:* someone who ran `felix land --install` trusts
README:455 and believes merges happen only by hand or by GitHub auto-merge, and they
uninstall by the README's list, which leaves the job loaded. It is medium because the job
needs an explicit `felix land --install`, which nothing else calls, and it acts only on the
home's repository. *Also fixed here, low:* README:524 says "about 3,000 assertions", but
`tests/assertions.tsv` holds 13,818 rows. That understates the suite and is not an
overclaim.

**C099 (medium).** README.md:480, and the end of every `felix install`
(engine/harness/felix:726-727), say `ln -s <path> /usr/local/bin/felix`. On a stock Mac,
/usr/local/bin is `root:wheel 755`, and `test -w /usr/local/bin` is false for an admin
user (2026-10-24). *Scenario:* a new user follows the three README lines. The third fails
with "Permission denied", and every later `felix ...` gets "command not found". *Also
verified here:* the printed path is unquoted, so from an engine path holding a space `ln`
gets three arguments and fails. *Correction followed:* "/usr/local/bin may not exist at all
on a fresh Apple Silicon Mac" was not verified and is not relied on.

**Facts the new text may state.** These are measured or read on 69b51a61. The new text
claims nothing beyond them:
- F1: a probe whose first word now names a file of another size, printing the same
  answer, leaves the decision epoch and the receipt unchanged. `felix probes` reports
  "the instrument changed" when it compares the run with the last run on a different tree
  (lib/facts.sh:198-207, felix:6458-6469, "Read rather than enforced"). Parts 0750:286-297
  and 0390 pin this. Making it stale receipts by selector is v3.2 Phase 2 work (row 21), not
  built.
- F2: the tree id hashes `git diff`, in which git abbreviates blob ids (`core.abbrev=auto`,
  lib/verify.sh:342-345, 400-407). The abbreviation is 7 hex digits below 16,384 objects
  and 8 from 16,384 to 65,535. So the id of a tree with uncommitted edits to tracked files
  changes, with no file touched, when the object count crosses such a bound. A clean tree's
  id does not. In a scratch repository on git 2.54, 2026-10-24, the dirty id b2f7fc18
  became 2dafd3d4 after 17,000 unreachable blobs were added, and a clean id stayed fd4e367b.
- F3: `felix land --install` is macOS only (launchctl). Nothing but `felix land --install`
  calls `_gt_install`: not `felix install`, not `felix new`, not commissioning. Each tick
  lands at most one open pull request of the home's GitHub repository that meets direction
  row 24, through `felix merge`, and runs `felix install --no-bump` in the home after a
  landing that changed engine/. It needs `gh`. `felix land --uninstall` boots the job out
  and removes its plist and trampoline (green-install.sh:190-196). On Felix's own
  repository it has landed five pull requests (10-19 to 10-23, the lander ledger) and
  deployed three times.
- F4: the land job's PATH begins `$HOME/.local/bin` (green-install.sh:178, pinned by 1281
  and 1283), and the founder's own link is `~/.local/bin/felix`.

## 2. Required behaviour

**B1. The README is found, or nothing passes.** Part 2030 reads the README. If the file is
missing or unreadable, or any of the four sections or the `### Verify and uninstall` line is
absent, every assertion of B2-B5 and B8-B20 fails with a detail naming what was not found.
None passes and none is skipped. A run from the plugin cache, which has no README, fails the
same way, as 0830 does.

*C008*
- **B2.** In section Why not just run the tests in CI?, no sentence matches both
  `(different size|program|instrument|binary|upgrade)` and
  `(stops counting|(goes|is|are|becomes|turns|reads) stale)`. Red on base, from item 2's
  sentence. There is no exemption for negation, because the base sentence contains "no
  file". So the new text states the negative with "stop counting" or a negated "stale", for
  example "does not make the pass stop counting".
- **B3.** That section has a sentence that matches `felix probes`, is negated, and matches
  `(stop counting|stale)`. Red on base, which never names `felix probes`.
- **B4.** The Partial row matches neither `on path` nor `which git`. Red on base.
- **B5.** The Partial row matches `abbreviat`, `object` and `uncommitted`: the F2 residual.
  Red on base.
- **B6. The engine still does what B2 and B3 say (control).** Fixture E is described in A6.
  (a) Under `binA` and under `binB`, `felix_probes_run`'s field 7 for the row are two
  different `mytool@<digits>` tokens. (b) `felix_epoch` exits 0 under both, and prints the
  same non-empty hash. (c) Under `binC` it prints a different hash. If (a) fails, (b) and
  (c) are reported failed ("the two instruments were not told apart") and never pass. A
  failing (b) says in its detail that the README's Why-not-CI item 2 is now false.
- **B7. The engine still does what B5 says (control).** Fixture T is described in A9.
  (a) After growth, `git count-objects -v` reports `in-pack:` of at least 20000, and
  `git status --porcelain` prints what it printed before. (b) The dirty tree's
  `felix_tree_id` differs from its value before growth. Both values are non-empty and both
  calls exit 0. (c) The clean tree's id is the same before and after. If (a) fails, (b) and
  (c) are reported failed and never pass. A failing (b) says in its detail that the
  Partial row is now false.

*C017*
- **B8.** The README's flat text, the whole file, does not contain `narrow to the
  obligations`. Red on base, where a line break splits the phrase across lines 414-415.
- **B9.** In Where it's going, no sentence matches
  `narrow(s|ed|ing)? (to|on)([^a-z]|$)` or `(will|would) narrow` unless it is negated.
  Red on base. "with narrow permissions" (line 396) matches neither pattern.
- **B10.** Where it's going has a sentence that matches `investigat` and
  `(weak|finds nothing|misses|does not beat|doesn't beat)`. Red on base.
- **B11.** Where it's going does not match `comes? first`. Red on base.
- **B12.** In Where it's going's flat text, let c be the offset of the first match of
  `(test of what a model finds|corpus)`, d the first `dry.run`, and r the first `retire`.
  Wherever both of a pair are found, c < d, d < r and c < r (direction §5's relative
  order). A pair with one side absent is not checked. Red on base, where the retire list
  comes before the dry run.

*C007*
- **B13.** The Install section has a bullet that contains `felix land --install`,
  `felix merge`, `macos`, `deploy` and `home`, and matches
  `(nobody|unattended|on its own|without you)`. Red on base.
- **B14.** Every sentence of the whole README that matches `merges? on its own` also matches
  `felix land`. Red on base (line 455). The check passes vacuously when no such sentence
  remains, and B13 still holds the land bullet.
- **B15.** The uninstall part contains `felix land --uninstall`. Red on base.
- **B16.** A Status row matches `felix land[^|]*own repository`, the scope stated inside
  the same cell. Red on base.
- **B17.** At least one sentence of the Install section matches `gh is needed for`, and
  each such sentence matches `(^|[^a-z-])land([^a-z-]|$)`. Red on base.
- **B18.** The whole README does not match `[0123456789][0123456789,]* assertions`. Red on
  base ("about 3,000 assertions").

*C099, the README*. B19 and B20 match raw lines, case-sensitively.
- **B19.** In the Install section: (a) no line contains `/usr/local/bin`. (b) Take the first
  fenced block (from a line beginning ```` ``` ```` to the next such line) that holds a line
  containing `felix install`. Exactly one line of it contains `ln -s`, and that line contains
  `mkdir -p` and `.local/bin/felix`. (c) Some line contains both `export PATH=` and
  `.local/bin`. All three are red on base.
- **B20.** The block's `ln -s` line works when run. **Guard:** the line contains no `;`,
  `|`, `>`, `<`, backtick, `$(`, `sudo` or `rm `. Split the line on blanks and strip each
  word's quotes: every word that then begins with `/` begins with $TMP's logical or
  physical path. If the guard fails, the assertion fails and the line is not run. The
  fixture: D is a fresh directory under $TMP holding an executable file
  `D/felix/engine/harness/felix`, and H is a fresh directory under $TMP with no `.local`.
  `( cd D && HOME=H bash -c "$line" )` exits 0, `H/.local/bin/felix` is a symbolic link,
  and `[ H/.local/bin/felix -ef D/felix/engine/harness/felix ]` holds. Red on base: the
  guard refuses `/usr/local/bin/felix`, so the base line is never run.

*C099, felix install.* The runs and their fixture are in A27. The guard is B20's.
- **B21. The printed link line.** In every run: (a) exactly one output line contains
  `ln -s` (control); (b) that line contains no `/usr/local` and contains `mkdir -p` and
  `.local/bin/felix` (red on base); (c) none of its blank-separated words begins with `-`
  and contains `f`, so there is no `-f`, `-sf` or `--force`, and an existing felix is never
  replaced silently (control); (d) the guard holds (red on base). felix install still prints
  the line in every run. It does not create the link itself: README:467-468's "skip the
  symlink" depends on that.
- **B22. It works.** R1's line, run as `( cd <fresh dir under $TMP> && HOME=H bash -c
  "$line" )`, exits 0. `H/.local/bin/felix` is then a symlink `-ef S/engine/harness/felix`.
  R2's line, run with HOME=H2s (see A27, where the source path and the home both hold a
  space), likewise exits 0 and leaves a link `-ef` R2's source. Red on base.
- **B23. It fails aloud, never silently** (red on base, because the guard stops the run):
  (a) R1's line run a second time exits non-zero, and the link is still `-ef` the source;
  (b) R3's line, run with HOME=H3, exits non-zero, and `readlink H3/.local/bin/felix` is
  still X; (c) R4's line, run with HOME=H4, exits non-zero and writes to stderr. After it,
  `H4/.local` is still a regular file and no `H4/.local/bin` exists.
- **B24. PATH advice when it is needed** (red on base). In R1 and in R2, where PATH has no
  entry `HOME/.local/bin` and none `HOME/.local/bin/`, an output line contains
  `export PATH=` and `.local/bin`. Take the text from the first `export PATH=` on that
  line to the line's end. It must contain no `;`, `|`, `&`, `<`, `>`, backtick or `$(`.
  Then `HOME=<that run's home> PATH=/usr/bin:/bin bash -c "<text>; printf '%s\n' \"\$PATH\""`
  prints a PATH whose `:`-separated entries include `<home>/.local/bin`, `/usr/bin` and
  `/bin`.
- **B25. No advice when it is not needed** (control). R3 has `H3/.local/bin` on PATH and R4
  has `H4/.local/bin/`. In each, no output line contains `export PATH=`. This passes only
  when that run exited 0 and printed exactly one `ln -s` line. A crashed run never passes
  it.
- **B26. Unchanged around it** (control). Each of R1-R4 exits 0. felix install itself
  creates nothing under `$HOME/.local`. After R1 and after R2, `HOME/.local` does not exist
  until the printed line is run. After R3 the link still points at X, and after R4
  `H4/.local` is still a regular file. In each run, the last non-empty output line contains
  `felix new <name>`.

## 3. What must not change

- **README headings.** Every `## ` and `### ` line is byte-identical. In-page links depend
  on them: `#why-not-just-run-the-tests-in-ci` (lines 76 and 194), and `#install`,
  `#status` and `#try-it` (lines 17, 21 and 209). Parts 0830 and 0840 find `## Try it`.
- **The Try it section** is not edited. `0830-felix-audit-what-the-reviews-left-open.sh` and
  `0840-felix-audit-what-the-third-review-found.sh` pin its claims: `git clone` and
  `felix audit`, `felix new <name> --no-commission`, `felix install` as what holds
  sessions, and a conditional `felix gate` promise.
- **Sizes.** README.md stays at or under its 655 base lines and `engine/harness/felix` at or
  under 6734. Both are already past 500 and must not get longer (the batch rule). Lines are
  found by reflowing the paragraphs this batch edits, which Markdown renders the same, and
  by folding the land uninstall item into the pulse bullet. Checked at review with `wc -l`,
  not by a part.
- **Untouched files:** `docs/direction.md` (its stale-text list and step 14 are §6's),
  `projects/felix/snapshot.sh`, `HANDOFF.md`, `docs/handoff/`, `tests/assertions.tsv`,
  `tests/red.tsv` and `engine/.claude-plugin/plugin.json`. The version slot for the felix
  change is the carrier's.
- **Engine behaviour, no change:** epoch, probes, verify, facts and land (lib/epoch.sh,
  probes.sh, verify.sh, facts.sh, green-tick.sh and green-install.sh are not edited). These
  parts pin it:
  - `0750-decision-epochs-the-four-things-a-decision-w.sh`: a different git on PATH gives
    the same epoch;
  - `0390-probes-what-reality-says-and-the-difference.sh`: "the instrument changed";
  - `0510-the-receipt-carries-the-epoch-and-a-fact-tha.sh`;
  - `1281-land-on-green-deploy-blind.sh` and `1283-land-on-green-round-3-blind.sh`: the
    plist PATH begins `$HOME/.local/bin`, which the new instruction relies on.
- **felix install's other output and its exit status.** `home:`, `engine:`, `marketplace
  registered`, `refreshed` and `already registered`, `verified   the installed engine
  matches this tree`, the WARNING blocks, the settings.json double-hook warning, and the
  uninstall messages naming doctrine and memory are pinned by
  `0630-the-subject-of-a-large-payload.sh` and
  `0640-the-deployed-surface-is-three-directories.sh`. The return 1 with "The claude CLI is
  not on PATH", which prints no PATH instruction, is unchanged (§6). A link through a
  symlink still resolves the libraries: `0250-on-path-via-a-symlink.sh`.
- **The suite's own rules,** which both new parts meet:
  - `1040-the-suite-is-cut-into-parts.sh`: the driver stays at 500 lines or fewer, and b00
    (`1610-driver-room-blind.sh`) frees room. Each part line goes in name order inside the
    frozen region, before the 9990 line;
  - `0002-fixture-git-commands-stay-in-tmp.sh`: git writes go through `_fx_git DIR ...` or
    `( _fx_cd DIR && git ... )`;
  - `9990-the-run-stayed-inside-its-temporary-directory.sh` and
    `1000-the-engine-makes-its-scratch-under-tmpdir.sh`: every write stays under $TMP, and
    HOME is a fixture directory for every felix install and every `bash -c` of a printed
    line;
  - `0960-no-engine-test-reads-a-pipe-through-a-grep-t.sh`: no pipe into `grep -q`;
  - `0994-bash-s-own-collation-and-the-bsd-text-tools.sh`: `LC_ALL=C`, and digit brackets
    spelled out;
  - `1497-lib-awk-gawk-names-blind.sh`: no gawk-only awk names. Bash 3.2 and bash 5 alike.
- **Other batches edit the README too.** b01 (C019), b06 (C055), b12 (C009, C010), b13
  (C067) and b22 (C037) touch other passages. The lints key on sections, sentences and
  patterns, never on line numbers. Sentences outside the passages these four defects name
  are not reworded.

## 4. Assertions

Every name below is emitted on every run, whatever the outcome. Its detail on failure is
the offending sentence, line or output.

**Part 2030** reads the README (fixture: the checkout's own README.md).
- A1 (B1, control): the README, its four sections and the Verify and uninstall line are
  found.
- A2 (B2): no sentence in Why not just run the tests in CI? says a probe's program
  changing size makes the pass stop counting.
- A3 (B3): that section says `felix probes` reports an instrument change that does not, by
  itself, stale the pass.
- A4 (B4): the Partial row no longer blames which git is on PATH.
- A5 (B5): the Partial row names abbreviated object names as what stales a receipt for
  uncommitted edits.
- A6-A8 (B6 a, b, c; controls). Fixture E is `$TMP/b21-ep/`:
  - `proj/project.json` is `{"name": "b21-ep", "remote_match": "example.com/b21-ep",
    "gate": "true"}`;
  - `proj/probes.tsv` holds the header `# predicate<TAB>grounds<TAB>when<TAB>probe<TAB>witness`
    and the row `member<TAB>-<TAB>-<TAB>mytool<TAB>true`;
  - `$MEM/b21-ep` exists, as part 0750 makes one;
  - `repo` is a git repository on `main`, holding one committed file, built through
    `_fx_git` or `_fx_cd`;
  - `binA/mytool` is a `#!/bin/sh` script printing `a` and `b`, one a line, and
    `binB/mytool` prints the same after an added comment line, so it is a larger file.
    `binC/mytool` prints `a`, `b` and `c`. All three are executable.

  Each value is computed as `( PATH="$TMP/b21-ep/binX:$PATH"; . "$FROOT/harness/lib/epoch.sh";
  felix_epoch "$TMP/b21-ep/proj" "$TMP/b21-ep/repo" )`, and field 7 comes from
  `felix_probes_run` with the same arguments.
- A9-A11 (B7 a, b, c; controls). Fixture T is `$TMP/b21-tid/dirty` and
  `$TMP/b21-tid/clean`. Each is a git repository on `main` with `a.txt` (`a`) committed.
  In `dirty`, a line `b` is appended to `a.txt` and not committed. The id is
  `( . "$FROOT/harness/lib/verify.sh"; felix_tree_id <repo> )`. For growth, run in each
  repository, through `_fx_cd`:
  `LC_ALL=C awk 'BEGIN { for (i = 0; i < 20000; i++) { s = "blob " i "\n"; printf "blob\ndata %d\n%s\n", length(s), s } }' | git fast-import --quiet`.
  It takes about 0.2 s each.
- A12 (B8): nowhere does the README say Felix will narrow to the obligations people name.
- A13 (B9): Where it's going narrows Felix on no result.
- A14 (B10): Where it's going says a weak corpus result is investigated.
- A15 (B11): Where it's going says nothing comes first.
- A16 (B12): Where it's going keeps the corpus, the dry run and the retire list in
  direction §5's order.
- A17 (B13): the Install list names `felix land --install` as an unattended `felix merge`
  that deploys, on macOS, for the home's repository.
- A18 (B14): every sentence saying something merges on its own names `felix land`.
- A19 (B15): Verify and uninstall names `felix land --uninstall`.
- A20 (B16): the Status table names `felix land`, scoped to Felix's own repository.
- A21 (B17): land is among the commands that need `gh`.
- A22 (B18): the README states no assertion count.
- A23-A25 (B19 a, b, c): the Install section names no /usr/local/bin, its install block
  links felix into ~/.local/bin after `mkdir -p`, and it says how to put ~/.local/bin on
  PATH.
- A26 (B20): the install block's link line, run in a scratch home, links felix there.
  Fixture D and home H are as B20 gives them.

**Part 2031** covers felix install. Fixture I:
- S is a fresh directory under $TMP. `S/engine/harness` is a copy of `$FROOT/harness`
  (`tests/` may be left out). `S/engine/.claude-plugin/plugin.json` is
  `{"name": "felix", "version": "0.49.9"}`. `S/.claude-plugin/marketplace.json` declares
  the plugin `felix` with source `./engine`.
- C is a directory holding `claude`, an executable that exits 0 for any arguments and prints
  `[]` for `plugin list --json`. tests/lib/install-fixture.sh's stub may serve.
- A run is `( cd S && HOME=<home> FELIX_HOME=S PATH=<path> S/engine/harness/felix install
  --no-bump )`, with stdout and stderr captured together, and its status kept.
- R1: home H, a fresh directory; path `C:$PATH`.
- R2: the source is S2, a copy of S at `$TMP/b21 src/S2`, run from S2 with FELIX_HOME=S2;
  home `$TMP/b21 home/H2s`; path `C:$PATH`.
- R3: home H3 holding `.local/bin/felix`, a symlink to X, which is the existing regular file
  `H3/other-felix`; path `H3/.local/bin:C:$PATH`.
- R4: home H4, where `.local` is a regular file; path `H4/.local/bin/:C:$PATH`.
- About 0.7 s a run, about 4 s for the part.

Its assertions:
- A27 (B26, control): R1-R4 each exit 0. The detail lists the four statuses.
- A28 (B21a, control): each run prints exactly one `ln -s` line.
- A29 (B21b): the line names no /usr/local, and links `.local/bin/felix` after `mkdir -p`.
- A30 (B21c, control): the line forces over nothing.
- A31 (B21d): every absolute path in the line lies inside the fixture.
- A32 (B22, R1): run, the line links felix into the home.
- A33 (B22, R2): from a source path and into a home that each hold a space, the line still
  works.
- A34 (B23a): run twice, it fails the second time and keeps the first link.
- A35 (B23b, R3): a felix link to another file is kept, and the line fails.
- A36 (B23c, R4): where ~/.local is a file, the line fails aloud and creates nothing.
- A37 (B24, R1) and A38 (B24, R2): with ~/.local/bin off PATH, it prints an `export PATH=`
  line that adds it.
- A39 (B25, R3) and A40 (B25, R4, trailing slash; controls): with ~/.local/bin on PATH, it
  prints no `export PATH=` line.
- A41 (B26, control): felix install itself creates nothing under ~/.local.
- A42 (B26, control): each run's last non-empty line names `felix new <name>`.

Red on base: A2-A5, A12-A26, A29, A31-A38. Controls: A1, A6-A11, A27, A28, A30, A39-A42.

## 5. Parts

- `engine/harness/tests/parts/2030-readme-claims-match-the-engine-blind.sh`: A1-A26. It
  reads the README, plus fixtures E and T.
- `engine/harness/tests/parts/2031-felix-on-path-without-sudo-blind.sh`: A27-A42.

Each begins with `printf '\n<title>\n'`, as the other parts do. Each gets one driver line,
`. "$HERE/parts/<name>"`, in name order before the 9990 line, and no `groups.tsv` entry
and no new lib file. Both pass alone under both awks, as
`alone.sh <worktree> bwk 2030-readme-claims-match-the-engine-blind.sh 2031-felix-on-path-without-sudo-blind.sh`
and again with `gawk`. The same holds for the parts named in §3, each run in its own call:
0250; 0390; 0510; 0630 with 0640; 0750; 0830 with 0840; 1280 to 1283. On base, 2030 and
2031 fail exactly the assertions §4 lists as red. The record (`--record-assertions`) and
`red.tsv` are the carrier's, not this batch's.

## 6. Out of scope

- **direction.md:227** ("14: #304" as future work, though #304 landed 10-02) and the
  **§8 stale-text entry** "README.md lines 409-420", which is stale itself once this lands.
  Adding README:455 to that list, as C007's sketch suggests, would be moot. direction.md is
  never edited by this batch, and every edit to it waits for the founder's yes (direction
  §10). Both go to the next direction fold.
- **Bringing instrument changes back as receipt invalidation by selector** (C008's other
  fix). That is v3.2's "affected receipts invalidated by selector", and row 21 places it in
  Phase 2. The batch describes the engine as it is, and A7 fails the day that changes.
- **The tree id's dependence on object count** (F2, found by the C008 skeptics). Making the
  id independent, with `--full-index` for example, is an engine change that stales every
  dirty-tree receipt once. It fails safe, holding rather than passing. It is not in the
  register, so it is recorded here for the dispatcher. A10 fails the day it is fixed, and
  says the Partial row must change.
- **README.md:401-405**, "The next step joins the two planes". Direction §5 puts the
  qualified-judge join in Phase 1, after the trust track (item 5). This was found while
  reading and is not in the brief, so it is left for the next README pass.
- **Lane items the README does not list**: Workflow stage checks, the #417 round, Codex
  read-only, the outcome record and more. The README lists a subset in direction's
  relative order (B12). The rest are internal.
- **felix install with no `claude` on PATH** returns 1 before the PATH instruction. That
  is unchanged and in no defect.
- **felix install creating the link itself.** It does not, because the README's "skip the
  symlink" route (README:467-468) depends on it not doing so.
- **The `felix land` usage line** (felix:467: no `--uninstall`, no platform note) and the
  install guard. Batch b05 (C013, C042) owns them.
- **Other batches' README defects:** C019 (b01), C055 (b06), C009 and C010 (b12), C067
  (b13), C037 (b22).
- **Not fixed: not a defect.** None. All four defects hold on 69b51a61, as §1 shows. The
  skeptics' corrections only narrow them.

## 7. Founder PR

None. The batch changes no `.github/workflows` file, deny or escape row, commission grant
or commission table. README.md and engine/harness/felix land on green, and README.md is
neither a direction path nor a roadmap path.

One note for his next bring-forward to LeavesJ/Felix (row 4: publishing is his). Once this
lands, a snapshot built with `--public-readme` ships part 2030 beside the old public README,
whose line 415 still says "narrow to the obligations people name". The public suite would
then go red, correctly. Publishing the home README, which means running the snapshot
without `--public-readme`, keeps it green.
