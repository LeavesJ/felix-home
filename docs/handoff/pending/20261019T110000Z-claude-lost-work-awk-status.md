### 2026-10-19: the lost-work page's awk failing exits 1, and a lint for gawk builtin names in lib's awk

**Engine 0.49.302 (this branch, `claude/lost-work-awk-status`, on origin/main
ff592e55, step 6 as #450 at 0.49.301).** It closes two of step 6's open items
(`20261018T125033Z-claude-lost-work-page.md`, Open: "The page ignores its own
awk's status"). The contract is `docs/2026-10-18-lost-work-page-contract.md`:
B8 amended, B9 items 41 and 42 added, and a new B12.

**What changed.**
- **The page.** `felix_lost_work_page` in `lib/lost-work.sh` writes each
  repository's block to its scratch directory, and prints it only when the
  page's awk exits 0. When the awk fails, the page:
  - sets status 1;
  - writes `felix monitor: <the directory as given>: the page could not be
    made from its rows (awk exited <n>)` to stderr;
  - prints nothing of that repository, not even what the awk printed before
    it stopped;
  - goes on to the next repository.

  Before this, the page took its exit status only from `felix inventory`. On
  the Linux runner the awk died on `RT` and the page exited 0 with nothing
  printed: a silent 0, which B4 forbids.
- **The lint.** `tests/lib/awk-names.sh` defines `_awk_names FILE...`.
  - It reads the files as bash does: quotes, `$( )`, `${ }`, comments and
    here-documents, with only the `$( )` commands of an unquoted body read.
  - It finds every awk command and its program word. From there it follows
    every variable the word expands to that variable's assignments, in any of
    the files, and every `$1`-`$9` inside a function to its callers'
    arguments.
  - In the program text it reads identifiers outside strings, regex literals,
    comments and numbers.
  - It prints `name` for a gawk builtin used as an identifier, a `-v`
    variable or an operand variable; `unread` for a part it cannot read (a
    command substitution, `-f`, a variable nothing assigns, a special
    parameter); `open` for a quote, `$(` or here-document still open at the
    end of a file; then `programs N`.
  - It passes only with none of those rows and N above 0, so a lint that read
    nothing does not pass.
  - It runs under BWK awk and gawk, with LC_ALL=C: each line and each text is
    split once, and quoted runs are appended whole.

**Measured.**
- Over `lib/*.sh` (83 files) the lint reads 280 program texts and prints no
  other row, under macOS awk and gawk 5.4.1.
- Every awk command a grep finds outside comment lines is read.
- The 19 program variables resolve. `_felix_qualify_read`'s `$2` resolves to
  its three callers' actions.
- On `lib/lost-work.sh` at 17230ff3 it prints six `name` rows for `RT`.
- Over `lib/*.sh` plus `felix`, `hooks/*` and `bin/*` it reads 366 and is
  clean. The part reads `lib/*.sh` only, as B12 asks.

**Tests.** Two new parts, sourced after 1490, both written blind from the
contract alone (Opus) before the fix:
- 1495, 23 assertions, B8 and B9.41. It uses three awk stubs ahead of the real
  awk: one that fails every `order=` call, one that fails only the first, and
  one that prints the real output and then exits 2. Its controls compare the
  page and both sources with the real awk.
- 1497, 44 assertions, B12 items 1-6. It checks `lib/*.sh` clean, and the RT
  defect replayed on a copy. It checks 21 positive forms, each giving the
  exact `name` row, and 10 negative forms. It also checks the `unread` and
  `open` cases, and a file with no awk command.

Red on 925b8000 (the contract, no fix): 1495 failed 14, every exit-1
assertion, with its fixture and real-awk controls passing; 1497 failed all 44.

After the fix one assertion in 1497 still failed under both awks: its count
check used `$(case ... in '') ...`, which bash 3.2 closes at the pattern's
`)`. Leading `(` on the two patterns fixed it in 2cdd6abb. The name and the
expected value are unchanged.

Alone at nice 19 under macOS awk and under gawk, each part reaches its end
with 0 failed: 0003, 0006, 0590, 0600, 0940, 0960, 0970, 1040, 1290 and
1450-1497. `c1-part.sh` gives the same pairs alone and in chain for 1495 and
1497. Evidence: `audits/2026-10-19-lost-work-awk-status/` under the memory
root.

**Open.**
- The lint reads `lib/*.sh` only. `felix`, `hooks/*` and `bin/*` are clean
  today (366 programs) and could be added to the part's file list.
- The lint's bash reading has known edges it does not follow:
  - a `case` pattern's `)` inside a `$( )` closes the frame early;
  - `$( )` inside `${...}` is not opened;
  - backtick command substitution is not read;
  - a here-document opened inside a here-document's `$( )` is not tracked.

  None occurs around an awk command in lib/ today, and the grep cross-check
  above found every awk command. A form like these that hides a program
  would be missed silently.
- The step 6 note's other open items stand: test gaps from review finding 7,
  `tests/run` near its limit (484 lines now, 1040 allows 500), helper
  worktrees in "never reached a PR", no PR titles, S3 unobserved, `handoff`
  and an `unknown` default cover row.

**Next.** PR at 0.49.302 (the carrier's slot, 2026-10-19, after #451 lands): record, red, gate in
this worktree, then the land job lands it on green.
