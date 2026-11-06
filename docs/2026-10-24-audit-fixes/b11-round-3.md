# Audit b11, round 3: only what the project declares vendored is set aside

Round 3 of batch b11, branch `claude/audit-b11-evidence-policy-gives-true-verdicts`
at d1f2cdc1. The batch contract still binds. This file replaces the first
requirement of its B23 and nothing else.

## 1. The finding, and what is real

An automated security review of d1f2cdc1 found a medium evidence-policy
bypass: `_felix_evidence_own` (lib/evidence.sh:48-54) drops every path under
a vendor/, third_party/ or node_modules/ directory, at any depth, before any
row reads it, and nothing says what was set aside. The cause (M2) was real:
a `go mod vendor` bump gapped, and felix merge refused it. Reproduced with the
seeded template: +lib/vendor/parse.go, +src/third_party/shim.ts,
+packages/app/node_modules/local/index.js and +vendor/acme/pkg/x.go (no
go.mod) each read `n/a` on all five rows, and `gap unit` without the
set-aside; an edit to own code under src/vendor/ does too. No line names what
was set aside. Also real: when the set-aside fails, the check prints
`unknown<TAB>CHANGED-PATHS<TAB>...no rule was consulted`. felix_merge_blockers
(escape.sh:672-675) and felix_receipt (receipt.sh:176) keep only `not judged`
unknowns, and felix_escapes never reports this one, so the merge proceeds
(shown by stubbing the function to fail). Not a bypass: the strict half, where
a vendored test proves nothing. Without it, +internal/x/y.go plus a vendored
`errors_test.go` reads `met unit`, so it stays (B11R3-4).

## 2. Required behaviour

**project.json** is the file in the project directory. A **vendor-named path**
has a directory named exactly vendor, third_party or node_modules, at any
depth. A path **set aside** is read by no cell of any row except an opted-in
one (B11R3-7).

- **B11R3-1. Nothing is set aside by its name alone.** With no declaration,
  and no go.mod at the root of the base, every `when` cell reads every
  changed path and no VENDORED line is printed. Own code under a nested
  vendor, third_party or node_modules directory fires the rules it matches.
- **B11R3-2. The declaration.** project.json may hold
  `"evidence_vendored": "D1 D2 ..."`. That is one JSON string of directories
  relative to the root, separated by spaces, each with or without a trailing
  `/`. A changed path is set aside when it begins with an entry plus `/`,
  compared byte for byte. An entry is never a pattern or a glob, never matched
  at another depth and never case-folded. An empty string declares nothing.
- **B11R3-3. Go.** When the base (HEAD with no base) holds `go.mod` at its
  root, every changed path beginning `vendor/` is set aside, declared or not.
  A go.mod the change adds does not count, nor does a nested one; a nested
  module declares its own directory. If git cannot tell, the answer is no.
- **B11R3-4. A vendored test proves nothing.** As in round 2, a row that has
  not opted in never reads a vendor-named path with `requires`, declared or
  not. Its `when` cell still reads such a path unless the path is set aside.
- **B11R3-5. A change is not judged by its own declaration.** When the
  physical path of the project directory is the repository root or below it,
  project.json is read as committed at the base (HEAD with no base), never
  from the working tree. If it is absent there, nothing is declared.
- **B11R3-6. The verdict says how much.** When N >= 1 changed paths are set
  aside, exactly one line follows the last row's line:
  `n/a<TAB>VENDORED<TAB>N changed path(s) set aside as vendored, under DIRS, so no rule read them`.
  When some row opted in, it ends `so only RULES read them` instead, where
  RULES is the names as listed, separated by single spaces. N counts distinct
  paths. DIRS names each directory that set a path aside, with a trailing
  `/`, separated by single spaces, in project.json's order, then `vendor/` for
  B11R3-3 unless already named. A path two entries cover counts under the
  first. There is no such line when N is 0, nor beside a whole-scan unknown,
  B4's line or B11R3-8's line.
- **B11R3-7. A row opts back in.** project.json may hold
  `"evidence_reads_vendored": "NAME ..."`, row names separated by spaces. A
  named row reads every changed path in both cells.
- **B11R3-8. A declaration the engine cannot read is not empty.** In each case
  below, the check prints exactly one line, `unknown<TAB>project.json<TAB>R`,
  and no row's line. R names the key (and the entry or name, in d and e) and
  contains `not judged`, never `no rule was consulted`: (a) project.json is
  not a regular file or cannot be read; (b) a key appears twice; (c) a key's
  value is not one JSON string; (d) an `evidence_vendored` entry has an empty,
  `.` or `..` component, a leading `/`, or a character other than a letter, a
  digit or `. _ - @ +`; (e) an `evidence_reads_vendored` name is the first
  cell of no line of evidence.tsv; (f) under B11R3-5, git cannot read it at
  the base. A whole-scan unknown, a missing evidence.tsv (nothing printed) and
  B4's line each come before it. No command changes: through `not judged`,
  felix evidence prints `[?] project.json` and exits 1, felix merge exits 3
  with `evidence<TAB>project.json<TAB>R`, and the receipt is `indeterminate`.
- **B11R3-9. A failure to set aside says so.** When a tool fails while paths
  are set aside, the check prints exactly `unknown<TAB>VENDORED<TAB>R`, with R
  containing `not judged`, and no row's line. This replaces round 2's
  CHANGED-PATHS line. No outside input reaches it, so it has no assertion: the
  review reads it.
- **B11R3-10. The commands.** felix evidence prints `  [-] VENDORED  R`. Its
  exit status and closing sentence stay those the other lines give: with
  nothing else, `No evidence gaps.` and exit 0. Merge, receipt, next and
  classify ignore it, as they ignore every n/a line.
- **B11R3-11. The brief sets nothing aside.** felix_brief_evidence reads every
  path it is given, as before round 2, and never reads project.json.
  (Amended 2026-11-06: it reads project.json to ask whether it can be read,
  and prints one `project.json` row when it cannot, as B11R3-8 has the check
  do; it still sets nothing aside. See
  `docs/2026-11-06-brief-reads-the-declaration-contract.md`.)
- **B11R3-12. The template says so.** In section 7's generator, replace the
  three heredoc lines beginning `# Vendored code is not read by any row.`
  with the seven below. The result is 32 ASCII lines, sha256
  `f58b5ee640ffb2bc22a5a0da2994352ed564a192493c16921723cc97e06ddbd4`. Its
  rows are byte-identical to 5bde52e3's, so A80 holds.

  ```
  # Vendored code is set aside by the engine, not by a cell, because a cell
  # cannot say "not under a directory" (lib/evidence.sh). A path under a
  # directory named in project.json's evidence_vendored, or under vendor/ when
  # the base holds a go.mod at the root, is read by no row, and the verdict says
  # how many were. A row named in evidence_reads_vendored still reads them. A
  # path under any vendor, third_party or node_modules directory never counts as
  # a test, since a dependency's test proves nothing of the project's code.
  ```

## 3. What must not change

B1 to B22, A1 to A100, A108, B23's second requirement and section 3's pins
stand; B23's first requirement and section 6's "Vendored code the engine
cannot name" are withdrawn. felix, lib/escape.sh, lib/receipt.sh and
lib/next.sh need no change and must not grow; lib/evidence.sh and
lib/intake.sh stay under 500 lines. The contract's portability rules hold,
every reader of project.json or paths runs `LC_ALL=C`, no entry is expanded
unquoted, and project.json is read by line as felix_json_str reads it. The
check writes nothing. No .tsv column; no deny, escape or risk row; nothing
under .github/workflows, in schemas.tsv or in any project's project.json.

## 4. Assertions

**F7:** P holds evidence.tsv (TU or TV) and project.json with exactly the
text given (`-`: none); G as F1/F6, `+X` added on work, `-X` deleted on work,
`=X` on main and kept, `~X` on main and changed on work; the check as F1 runs
it. **F7-in:** P is `G/projects/p`, committed on main with the base JSON;
work changes project.json to the work JSON. Expected is every line in order.
**(control)** holds on d1f2cdc1 and after; every other row fails on d1f2cdc1
(checked against a scratch prototype, not the suite).

- TU: `unit<TAB>(^|/)(src|lib|internal|pkg|cmd)/<TAB>(^|/)tests?/|_test\.go$<TAB>code changes need a test`
- TV: TU's row, then `deps<TAB>(^|/)vendor/<TAB>^vendor/modules\.txt$<TAB>a vendored change names its modules`
- Ug = `gap<TAB>unit<TAB>code changes need a test`; Un = `n/a<TAB>unit<TAB>this change does not touch that surface`
- V(N, D) = `n/a<TAB>VENDORED<TAB>N changed path(s) set aside as vendored, under D, so no rule read them`
- J1 = `{"name":"p","evidence_vendored":"third_party/ web/assets/vendor"}`;
  J2 = `{"evidence_vendored": "third_party/"}`;
  J3 = `{"evidence_reads_vendored": "deps"}`; JX = `{"evidence_vendored": 3}`

### Part 1832 (new, engine PR)

`engine/harness/tests/parts/1832-evidence-vendored-declared-blind.sh`
reads no template. It is registered after 1831's line in tests/run, or after
1830's when 1831 is not in the pull request.

| A | R3 | Table, project.json | Change | Expected |
|---|---|---|---|---|
| A109 | 1 | TU, - | one each: +lib/vendor/parse.go; +src/third_party/shim.ts; +src/node_modules/local/index.js | Ug each |
| A110 | 1, 3 | TU, - | +vendor/acme/pkg/x.go | Ug |
| A111 | 3 | TU, - | +go.mod +vendor/acme/pkg/x.go | Ug |
| A112 | 1 | TU, - | =src/vendor/session.go ~src/vendor/session.go | Ug |
| A113 | 1 (control) | TU, - | -src/auth/session.go +src/vendor/auth/session.go | Ug |
| A114 | 3 | TU, - | =go.mod +services/auth/vendor/github.com/pkg/errors/errors.go | Ug |
| A115 | 3, 6 | TU, - | =go.mod +vendor/github.com/x/y/pkg/z.go | Un, V(1, vendor/) |
| A116 | 3, 6 | TU, - | =go.mod -vendor/github.com/pkg/errors/go113.go +vendor/github.com/pkg/errors/errors.go +vendor/modules.txt | Un, V(3, vendor/) |
| A117 | 3, 6 | TU, - | =go.mod +vendor/github.com/pkg/errors/errors.go +internal/handlers/auth.go | Ug, V(1, vendor/) |
| A118 | 4 (control) | TU, - | one each: +internal/x/y.go +vendor/github.com/pkg/errors/errors_test.go; +src/a.go +src/third_party/x/x_test.go | Ug each |
| A119 | 4 (control) | TU, - | +src/a.go +tests/a_test.go | `met<TAB>unit<TAB>code changes need a test` |
| A120 | 2, 6 | TU, J1 | +third_party/lib/a.c | Un, V(1, third_party/) |
| A121 | 2, 6 | TU, J1 | +web/assets/vendor/lib/jquery.js | Un, V(1, web/assets/vendor/) |
| A122 | 2 | TU, J1 | +src/third_party/shim.ts | Ug |
| A123 | 2, 6 | TU, J2 | +third_party/lib/a.c +src/third_party/shim.ts +vendor/x/pkg/y.go | Ug, V(1, third_party/) |
| A124 | 2, 3, 6 | TU, J2 | =go.mod +third_party/lib/a.c +vendor/x/pkg/y.go | Un, V(2, third_party/ vendor/) |
| A125 | 2, 4 | TU, J2 | +src/a.go +third_party/x/test/a_test.go | Ug, V(1, third_party/) |
| A126 | 2 (control) | TU, `{"evidence_vendored": "lib/vendor"}` with +lib/vendored/x.go; `{"evidence_vendored": ""}` with +src/a.go | as given | Ug each |
| A127 | 5 | F7-in, TU; base `{"name":"p"}`, work `{"name":"p","evidence_vendored":"third_party/"}` | +third_party/lib/a.c | Ug |
| A128 | 5 | F7-in, TU; base and work `{"name":"p","evidence_vendored":"third_party/"}` | +third_party/lib/a.c | Un, V(1, third_party/) |
| A129 | 7 | TV, J3 | =go.mod +vendor/github.com/x/pkg/y.go | Un; `gap<TAB>deps<TAB>a vendored change names its modules`; `n/a<TAB>VENDORED<TAB>1 changed path(s) set aside as vendored, under vendor/, so only deps read them` |
| A130 | 7 | TV, J3 | A129's, +vendor/modules.txt | Un; `met<TAB>deps<TAB>...`; VENDORED reason beginning `2 changed path(s)`, ending `so only deps read them` |
| A131 | 6, 7 | TV, - | =go.mod +vendor/github.com/x/pkg/y.go | Un; `n/a<TAB>deps<TAB>this change does not touch that surface`; V(1, vendor/) |
| A132 | 4, 7 | TV, J3 | +src/a.go +vendor/modules.txt | Ug; `met<TAB>deps<TAB>a vendored change names its modules` |
| A133 | 4 | TV, - | +src/a.go +vendor/modules.txt | Ug; `gap<TAB>deps<TAB>a vendored change names its modules` |
| A134 | 8c | TU, `{"evidence_vendored": ["vendor/"]}`; again with JX | +src/a.go | each: one line, `unknown`, `project.json`, R with `evidence_vendored` and `not judged`, without `no rule was consulted` |
| A135 | 8d | TU, `{"evidence_vendored": "third_party/ E"}`, E each of `../shared/` `/vendor/` `vendor/*` `.` `a//b/` `src/./x` | +src/a.go | each: one line, `unknown`, `project.json`, R containing E and `not judged` |
| A136 | 8b | TU; lines `{`, `"evidence_vendored": "third_party/",`, `"evidence_vendored": "x/"`, `}` | +src/a.go | as A134 |
| A137 | 8e | TU, `{"evidence_reads_vendored": "nosuch"}` | +src/a.go | one line, `unknown`, `project.json`, R containing `nosuch` and `not judged` |
| A138 | 8a | TU, J2 at mode 000 | +src/a.go | one line, `unknown`, `project.json`, `not judged`; skip (not pass) if readable; restore |
| A139 | 8 (control) | no evidence.tsv; JX | +src/a.go | nothing |
| A140 | 8 (control) | TU, JX; base `no-such-ref` | +src/a.go | one line, `unknown`, `no-such-ref`, `no rule was consulted` |
| A141 | 8 (control) | TU at mode 000, JX | +src/a.go | one line, `unknown`, `evidence.tsv`; skip if readable; restore |

The rows below run in F2 and F3, with TU as widget's evidence.tsv. "+K" adds
key K to widget's project.json, keeps it valid JSON, and restores it after.

| A | R3 | Fixture and run | Expected |
|---|---|---|---|
| A142 | 6, 10 | +`"evidence_vendored": "third_party/"`; change third_party/lib/a.c; felix evidence | `[-] VENDORED`, `1 changed path(s) set aside as vendored, under third_party/`, `No evidence gaps.`; exit 0 |
| A143 | 10 (control) | A142's; felix_merge_blockers | no line whose first field is `evidence` |
| A144 | 1 | no key; change third_party/lib/a.c; felix_merge_blockers | the line `evidence<TAB>unit<TAB>code changes need a test` |
| A145 | 8 | +`"evidence_vendored": ["third_party/"]`; change src/a.js; felix merge | exit 3; `project.json` and `not judged` |
| A146 | 8 | A145's; felix receipt | `"unknown"` contains `"evidence"`; `"status": "indeterminate"` |
| A147 | 8 | A145's; felix evidence | `[?] project.json`; exit 1; no `No evidence gaps` |
| A148 | 11 | `felix_brief_evidence P vendor/github.com/x/pkg/a.go`, sourcing only resolve.sh and intake.sh; P holds TU and `{"evidence_vendored": "vendor/"}` | exactly `unit<TAB>code changes need a test` |
| A149 | 11 (control) | as A148 with P holding TU and JX, PATHS src/a.go | exactly `unit<TAB>code changes need a test` |

### Part 1831 (founder PR, with change A)

As F6 on B11R3-12's template; `_b11t_g` learns `=X` and `_b11t_case` a
trailing VENDORED line. A101 to A107 keep their changes (no project.json, no
go.mod): A101-A105 and A107 read `unit gap`, A106 `unit gap`, `e2e gap` and
`api gap`, others n/a. **A150** (R3-3, 6, 12), M2's bump kept mergeable:
=go.mod -vendor/github.com/pkg/errors/go113.go
+vendor/github.com/pkg/errors/errors.go +vendor/modules.txt reads n/a on
every row, then V(3, vendor/). **A151** (R3-4, control):
+internal/handlers/auth.go +vendor/github.com/pkg/errors/errors_test.go reads
`unit gap` and `api gap`, others n/a.

## 5. Decisions

- **project.json, not an evidence.tsv directive.** A set-aside widens. An
  evidence.tsv addition is free, and a comment is free both ways. Editing or
  removing a project.json value line escapes (`_felix_escape_shrank`), and the
  file is a commission table. A product's project.json sits in the Felix
  home, beyond the reach of the product's own branch.
- **Flat string keys, entries separated by spaces**, because felix_json_str
  reads nothing else and no parser is wanted (resolve.sh:317). **A
  root-relative prefix, never a pattern**, because `(^|/)vendor/` would bring
  the any-depth rule back in one line.
- **Go: root only, go.mod only, read at the base.** That is the finding's
  scope. Requiring modules.txt would gap a first `go mod vendor`, and reading
  at the base keeps a change from granting itself the set-aside.
- **Requires keeps round 2's any-depth rule.** Without it, a vendored test
  meets unit. With it, every failure to set a path aside only makes the
  verdict stricter.
- **The count is an n/a line named VENDORED.** Every caller already renders
  or ignores n/a, and the brief drops it, so felix, escape.sh, receipt.sh and
  next.sh are untouched. It comes after the rows, so file order holds.
- **Unreadable is unknown, `not judged`.** Treating it as empty would let a
  test in a declared directory meet a row the declaration meant to gap. The
  merge filter and the receipt key on `not judged`, so B11R3-9 says it too.
- **Read at the base inside the repository**, so a change neither grants nor
  revokes its own set-aside (a removal escapes anyway). **The opt-in is in
  project.json**, so removing one escapes; an unknown name is refused.
- **The brief sets nothing aside**: it has no base and decides nothing.
  **The receipt and classify are unchanged**: the receipt is pinned (0370) and
  felix may not grow. **New part 1832**: 1830 is at 422 of 500 lines.

## 6. Founder stops

None beyond the batch's own: the template header (B11R3-12) is change A's
file in the founder PR, comments only, and 1831's new cases ship with it.
**The founder's call:** the first `evidence_vendored` line added to a
project.json is an addition, which the escape rule reads as free; making it
escape needs an escape row or project.json in the exemption list. Until then
the declaration is visible (felix evidence names the directory each time),
cannot serve the change that adds it (B11R3-5), and moving own code into it
still gaps through the deleted path (A113).

## Review round

The review of 0712fded raised four findings. Findings 1 and 2 are one defect,
accepted as B11R3-13. Finding 4 is accepted as B11R3-14. Finding 3 is
rejected, and the reason is given below. In this section **(control)** means
true on 0712fded and after the review fix. Every other assertion here fails on
0712fded. The assertions are in part 1832, and each name begins `B11R3V`.

### Accepted

- **Findings 1 and 2: B11R3-5 is decided by spelling.** B11R3-5 asks whether
  the *physical* path of the project directory is the root or below it.
  0712fded compares two strings instead. A string from the builtin `pwd -P`
  is not a physical path: it keeps the case the path was typed in, a leading
  `//`, and a firmlink's `/System/Volumes/Data` prefix. So a root or project
  directory spelled another way names the same directory but fails the prefix
  test, and the check then reads project.json from the working tree, where the
  change itself added `evidence_vendored`. felix_repo_root takes ROOT from the
  spelling of the cwd, so `cd ~/documents/felix && felix merge` reaches it.
  That is the bypass B11R3-5 exists to close, and section 6's safeguard rests
  on B11R3-5.
- **B11R3-13. Inside the repository is decided by identity, not spelling.**
  The project directory is inside the repository when it, or a directory above
  it, is the same directory as ROOT, as `[ A -ef B ]` decides. No spelling of
  either path changes the answer: another case on a file system that ignores
  case, a leading `//`, a firmlink, or a symlink. When it is inside,
  project.json is read at the base under the path the repository records for
  it, whatever case the caller typed (projects/p, never projects/P). When the
  check cannot tell whether it is inside, it prints B11R3-8's line,
  `unknown<TAB>project.json<TAB>R` with R containing `not judged`, and no
  row's line. No outside input reaches that last case, so it has no
  assertion.
- **Finding 4: git quotes unusual names.** It was already there before round
  3 (d1f2cdc1 does the same). But B11R3-1 says every `when` cell reads every
  changed path, and a cell that reads `"src/caf\303\251.go"` has not read
  src/café.go. The result is C024's own false all-clear: own code reads n/a on
  every row, and felix evidence says "No evidence gaps". The obvious fix opens
  a worse hole: with `-z` and every NUL turned into a newline, a directory
  named `z<NL>tests` splits into `z` and `tests/z_test.go`, and that meets
  unit. So the clause also says what a newline does.
- **B11R3-14. A changed path is read as its own bytes.** Every `when` and
  `requires` cell, the set-aside (B11R3-2, B11R3-3) and B11R3-6's count read
  each changed path, added or deleted, as the bytes of its name and never as
  git's quoted spelling. This holds whatever core.quotePath is set to, in the
  repository's config, in the caller's, or in neither. A name holding a byte
  above 127, a double quote, a backslash or a tab is read as itself. A name
  holding a newline is never split into two paths: the check prints exactly
  one line, `unknown<TAB>CHANGED-PATHS<TAB>R`, where R contains `not judged`
  and never `no rule was consulted`, and no row's line. A whole-scan unknown,
  a missing evidence.tsv (nothing printed), B4's line and B11R3-8's line each
  come before it. Because R says `not judged`, felix_merge_blockers prints it
  as `evidence<TAB>CHANGED-PATHS<TAB>R`, and no command changes. The builder
  decides where the fix lives. If it changes felix_changed_paths, every part
  that pins that function's other callers stays green, and section 3's
  budgets hold.

### Rejected

- **Finding 3: an uncommitted project.json in a worktree's main checkout.**
  This is not a defect against this contract. B11R3-5 is about a change
  judging itself: a branch must not grant itself a set-aside. In the worktree
  layout it cannot do so. The branch's commits reach the worktree's copy of
  projects/felix/project.json, but the check reads the main checkout's copy,
  which no commit on the branch touches. What the finding shows is that the
  Felix home's checked-out tables are the policy, uncommitted edits included.
  That is true of every table the check reads, not of project.json alone.
  evidence.tsv is read from the same directory in the same way, so an
  uncommitted edit there that deletes the unit row passes the same branch with
  no declaration at all. Reading project.json at the base would close nothing.
  Section 5 accepts the disk read on exactly this ground: the Felix home is
  beyond the branch's reach. Whether the Felix home's tables should be read as
  committed rather than as checked out is a question for every table, so it
  belongs in its own batch, not in round 3.

### Assertions

A152 to A158 and A168 use F7-in. **Grant** is A127's fixture: the base holds
`{"name":"p"}`, work adds `"evidence_vendored":"third_party/"`, and the change
is +third_party/lib/a.c. **Declared** is A128's fixture: the base and work
both declare third_party/. The check runs as F1, with PROJ and ROOT spelled as
given and the cwd set to ROOT as spelled. G and P are the canonical spellings.
Gc is G with the case of its last component changed. Pg is Gc/projects/p,
so the repository's own directory is spelled in another case inside PROJ, and
Pc is G/projects/P, so the case changes below the root.
//G and //P have one more `/` in front. L is a symlink to G. A spelling that
does not name the same directory on the machine (a file system that keeps
case apart, no firmlink) is a skip, never a pass.

| A | R3 | Fixture | PROJ, ROOT | Expected |
|---|---|---|---|---|
| A152 | 13 | grant | P, Gc | Ug |
| A153 | 13 | grant | Pg, G | Ug |
| A154 | 13 | grant | P, //G | Ug |
| A155 | 13 | grant | //P, G | Ug |
| A156 | 13 | grant | P, /System/Volumes/Data followed by G | Ug |
| A157 | 13 (control) | grant | P, L | Ug |
| A158 | 13 | declared | Pc, G | Un, V(1, third_party/) |
| A168 | 13 (control) | grant | Pc, G | Ug |

A159 to A166 use F7, with core.quotePath set to true in the repository's
config. A name the file system refuses is a skip. A167 uses F3, with TU as
widget's evidence.tsv and no key added.

| A | R3 | Table, project.json | Change | Expected |
|---|---|---|---|---|
| A159 | 14 | TU, - | +src/café.go (é as the bytes \303\251) | Ug |
| A160 | 14 | TU, - | +src/a"b.go | Ug |
| A161 | 14 | TU, - | +src/a\b.go (one backslash) | Ug |
| A162 | 14 | TU, - | +src/a<TAB>b.go | Ug |
| A163 | 14 | TU, - | -src/café.go | Ug |
| A164 | 14 | TU, - | +src/café.go +tests/café_test.go | `met<TAB>unit<TAB>code changes need a test` |
| A165 | 14 | TU, J2 | +third_party/café.c | Un, V(1, third_party/) |
| A166 | 14 | TU, - | +src/a.go +z<NL>tests/z_test.go | one line: `unknown`, `CHANGED-PATHS`, R with `not judged`, without `no rule was consulted` |
| A167 | 14 | F3 | change src/a.js and z<NL>tests/z_test.js; felix_merge_blockers | exactly one line whose first field is `evidence`, and it is `evidence<TAB>CHANGED-PATHS<TAB>R` with R containing `not judged` |
