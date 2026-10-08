### 2026-10-08: every engine sort, comm, join and uniq reads bytes in the C locale

Found by the adversarial review of claude/no-caller-env-in-tool-output, and
re-measured under `bash -c` on macOS 26, bash 3.2.57, at main 6fe5f986.

**Defects.** The engine runs in its caller's locale. A macOS Terminal sets
LANG=en_US.UTF-8, which reaches `felix` run by a person and every hook of a
`claude` started from that Terminal. A desktop session's tool shell has no
LANG and runs in C, which is why no session saw any of this.
- lib/escape.sh `_felix_escape_shrank` ran `comm -23` in the locale over two
  sides sorted in C. An added deny row that sorts before an existing one in
  bytes and after it in the locale (`Zulu` and `_under`) read as a removal,
  which is a false founder stop.
- macOS sort in a UTF-8 locale prints nothing when one line is not UTF-8. So
  one Latin-1 byte in any route's play routed no prompt (`felix_route_best`,
  rc 1). One in a declared capability made `felix_undeclared` name a declared
  one. glibc sort does not do this.
- 37 call lines were unpinned: 6 in felix and 31 in lib, including the
  ledger's `sort -u "$state"`, felix scope's path list, coverage, incident,
  the inventory sets, and two `uniq` calls after a C sort.

**Rule.** In runtime code (felix, lib, hooks, bin, templates), every sort,
comm, join and uniq is written `LC_ALL=C <tool>` on the command itself.
tests/run lints it, and its block names the shapes the matcher reads and the
three it still does not. It is one rule for all of them because macOS sort can
empty a sort whose order does not matter, so a per-site judgement cannot be
linted. `felix_route_best` also re-read the winning line with `cut`, which
BSD's UTF-8 build fails on, so that cut is pinned too.

**Not this branch.** Glob and `ls` order, and BSD sed, tr, cut and grep on
bytes that are not UTF-8, are claude/locale-glob-bsd-tools ([c686f0]),
stacked on this one. That branch carries the fail-open the review found:
`_felix_escape_lines` runs `sed -E` in the locale, so a deny row removed
after a non-UTF-8 row reads as no escape, on main and here. The `felix` header
bullet that names this bug ("not every one does yet") lives on
claude/no-caller-env-in-tool-output. Whichever of the two lands second
rewrites it (agreed with that session).

**State.** Branch claude/locale-c-sort-comm, head 789377f5. It holds blind
assertions (Opus), the fix (Sonnet), two Opus reviews and a fix round. Section
runner: 17/0/0 here, and 11 pass with 6 fail on origin/main. Carrier slot 21.
No record, red or gate run yet. Contract and stage log:
~/.felix/memory/felix/audits/2026-10-08-locale-sort-comm/contract.md.
