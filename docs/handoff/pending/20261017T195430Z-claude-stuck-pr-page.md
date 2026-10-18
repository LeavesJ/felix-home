### 2026-10-17: the stuck-PR page, `felix land --prs` and `--queue` (Phase 0b step 5)

**Engine 0.49.298 (placeholder; this branch, `claude/stuck-pr-page`, based on
origin/main e95e5d3b).** The page says why each open pull request has not
landed and who has to act. The contract is spec v2,
`audits/2026-10-01-report-v5-review/specs/stuck-pr/spec-v2.md`. It supersedes the
2026-10-13 spec, because land on green (#442) took `--status` for the tick's own
state and is the lander. The command is therefore `--prs`, and the tick's
ledger became a source.

**What it is.**
- `felix land --prs [--tsv] [--repo DIR] [--no-gh]` prints one row per open
  pull request of the repository holding the directory: the state, who acts
  next, why, and what each source said.
- `felix land --queue [--tsv]` prints the pull requests in state `founder` for
  every governed project, each once.
- The tick's commands keep their meaning. Any other argument or combination,
  `felix land` alone included, prints the usage (which now names `--prs` and
  `--queue`) and exits 2. A repository that no project governs prints the page
  with land, ledger and lander unread ("no project governs this repository")
  and exits 0.

**The twelve states.** First match wins, and the row's detail lists every
condition that holds: `outside`, `stacked`, `held`, `needs-session`, `red`,
`pending`, `unknown`, `founder`, `needs-attended`, `refused`, `ready`,
`unready`. Session problems come before the founder, so a founder-lane PR
reaches him only when nothing a session must do comes ahead of it. `ready`
means what the tick would hand to `felix merge`: green checks, not a draft, no
other open PR sharing its head branch, and no refusal on this head and this
main.

**The tick-ledger join.** The last ledger row for the PR decides state 10 when
it names this head and is `refused` on the current `refs/remotes/origin/main`,
or is `session`. A refusal on an older main, or any row for an older head,
decides nothing and is listed as `the lander last saw <head>`. A ledger that is
absent reads `none`. A ledger that is there and cannot be read makes a PR that
would otherwise be `ready` `unknown`, never `ready`.

**What it reads, and that it writes nothing.** One `gh pr list` call per
repository, the land table and risk rows from `refs/remotes/origin/main`, the
escape, commission and trust-base tables, the tick's ledger, `paused` and
`lock/`, launchctl `print`, and one `gh api` GET for the Actions budget. It runs
no fetch, no merge-tree, no worktree and no checkout, and writes to no
repository and to nothing under the tick's `land/` directory. The tests snapshot
refs, index, config, HEAD, the object count, FETCH_HEAD, worktrees and every path
under `land/` before and after each command, and the stubs' logs hold only
`pr list`, `api` and `print`. An unread fact is `unread`, never zero: gh absent
or failing prints `pull requests not read: <reason>`, not "no open pull
requests".

**Founder rules, applied path-level.** `commission`, `exemption`, `verifier`
(a deleted line in an escape table), `execute`, `authority`, `exception`,
`durable`, `risk` (a risk.tsv `path` row with a channel and no confine), `land`
(a founder row at origin/main), `direction` (lower-cased, so a case-folding file
system cannot hide CLAUDE.md or a roadmap) and `path-bytes` (a byte outside
printable ASCII), plus the labels `needs-founder` and `felix:founder` in any
case. Content rules (the secret scan, destructive SQL in added lines, a risk
confine) are not evaluated; each `founder` row decided by a path says
`path-level`.

**Where it lives.** `lib/pr-status.sh`, `lib/pr-status-state.sh` and
`lib/pr-status-gh.sh`, deliberately not `lib/land*.sh`, which is in the trust
base. `green-tick.sh` gains the two cases and the usage line, and
`green-install.sh` shares the installed, loaded and paused read with the page so
the two cannot drift. The files are 311, 240 and 185 lines.

**What stays out.** The closing-notice line stays with step 7 (L6a): the notice
it belongs in is not built, and a line in `hooks/stop` is adversarial tier.

**Tests.** Four new parts, sourced after 1286: 1300 (the fixture, usage and the
unread readings), 1310 (the states), 1320 (the queue once, the lock, the ledger,
`--repo` and section 5) and 1330 (what the review found). They hold 42, 95, 37
and 43 assertion lines; loops make the count at run time higher. The blind parts
were written from spec v2 alone before the implementation, and the review
findings were written blind again before the fixes. A partial smoke of parts
0001-0005 and 1300-1330 at bf9b27e2 reached the end: 435 passed, 0 failed. The
fixture lint on the four parts is clean and each parses with `bash -n`. The full
suite, the record and the gate were not run on this branch.

**Review findings, and how each closed.** One adversarial review on the
read-only contract and the unknown readings, in two reports.
- Report A F1 / Report B F1 (path-bytes lost to the flattener): a new
  `_PS_UNESC` pass decodes `\t \n \r \b \f` and `\u00XX` controls to byte 001
  before `_FI_JSON`, so `/[^ -~]/` alone fires. The shared `_FI_JSON` is
  untouched. Cases 160, 164, 165, 166 and 168 are now founder (path-bytes).
- Report A F2' / Report B F2 (a plain backslash read as path-bytes, doubled in
  the detail): `\\` decodes to byte 002 and back to one real backslash, and the
  `index(p, backslash)` clause is removed. #161 is ready, and #162 is founder by
  land with one backslash.
- Report A F2 (an unreadable ledger read as none): `_ps_ledger` walks the
  ancestors and says unread when any existing one cannot be searched (`land/` at
  mode 000, or the project memory dir at 000).
- Report A F3 (a comma in a label name): labels are joined with byte 003 and
  matched as whole names.
- Report A F4 (terminal injection) and Report B F11 / Report A F4 title cut:
  `_ps_tame` filters both pages (controls but tab and newline, DEL, and C1 as C2
  80..9F become `?`), and the 60-byte title cut backs off a half UTF-8
  character. New assertions are in 1330.
- Report A F5 / Report B F8 (two GETs for the budget, scope hint on every
  failure): one GET of `users/<o>/settings/billing/actions`; `orgs/<o>` only
  after a 404; the scope hint only on a 404.
- Report A F6 / Report B F6 (the origin row contradicted the default branch):
  the row reads `default branch X (origin/HEAD)` when set and `not read` only
  when empty.
- Report A F7 (tab, CR or LF in the repo cell): the repo and queue slug pass
  through `tr`, and `_ps_slug_ok` rejects CR and LF.
- Report A F8 (FETCH_HEAD age): the row gives the reflog time of
  `refs/remotes/origin/main` (`origin/main last moved ...`) and FETCH_HEAD
  labelled `last fetch, of any ref`.
- Report B F3 (the queue silent on truncation): the queue text appends `the list
  may be incomplete: ...` to the project line and a footer note; the 1330 F3
  assertions pass.
- Report B F4 (the cap of five hid rules): items are still capped at five, but
  `and N more: <every distinct rule>` follows, so every trust-base path is named.
- Report B F5 (the queue cross-project check was vacuous): closed in the blind
  stage by the stub serving the default-branch GET; the build already listed
  two's #101 once.
- Report B F7 (ledger-unread and both founder labels not listed): the
  ledger-unread condition is added to every green row, and both founder labels
  are named together.
- Report B F9 (an ungoverned repository exited 1): the page prints with land,
  ledger and lander unread and exits 0; `_ps_blob` refuses an empty project dir.
- Report B F10 (a duplicate slug listed twice in the queue): slugs are
  lowercased and read once under the first project, with a note naming the
  second.

**Open.**
- Spec v2 sections 2 and 4.2 still lack the line saying the queue reads a
  non-checkout project's default branch with a `gh api repos/<owner>/<name>`
  GET. The spec lives under ~/.felix/memory, outside this checkout, so it was not
  edited here.
- No blind assertion covers the F6 origin-row wording, the F8 reflog age, the F7
  tab-in-slug cleanup, the F10 duplicate-slug dedupe or the F5 "exactly one
  billing call" count. The code was changed and no regression showed, but those
  are untested. Assertions were added only for the title filter, the title cut
  and the ungoverned repository.
- The 1300 snapshot helper prints `FETCH_HEAD: No such file or directory` to the
  smoke log for a fixture repository that has no FETCH_HEAD. It is noise, not a
  failure; the redirect sits on the `cksum`, not on the shell's `<`.

**Owed at "you are next".** The carrier takes the record, the gate and the
version number: 0.49.298 is a placeholder (.294 the escape batch, .295 A30, .296
slot 18, .297 gate friction C), and is set to the number above main then. This
is one engine PR, risk-red because it adds lib files.
