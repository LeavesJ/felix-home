# The standing direction is read first: the contract

On 2026-10-19 the founder asked for one document with "the absolute say in
standing", so that a fresh session knows which roadmap is current without
reading every past roadmap note. A project keeps that document at
`docs/direction.md` in its repository. Today the session-start hook names the
constitution, `HANDOFF.md` and the newest five pending handoff sections, and
does not name a direction file. This change makes the hook name it first.

This file is the whole specification the blind assertions are written from.
It says what must be true, not how.

## Terms

- **The hook**: `engine/harness/hooks/session-start`, run with the working
  directory inside a governed checkout and stdin at `/dev/null`. Its output is
  one JSON object; **the context** is the decoded value of its
  `additionalContext`, with `\n` read as a newline.
- **R**: the root of the repository the working directory is in. The hook
  finds it as it does today, and spells it as it spells `R/HANDOFF.md` today
  (physically, so `/private/var` and not `/var` on macOS). In a linked
  worktree it is the worktree's root.
- **P**: the governed project's directory in the Felix home, so that the
  constitution is `P/CLAUDE.md`.
- **D**: the path `R/docs/direction.md`.
- **The reading list**: the lines of the context from the one that begins
  `Read before planning: ` down to the next blank line. Its continuation lines
  are indented with exactly 19 spaces, as they are today.
- **Named**: D appears in the context.
- **Regular**: D exists, is a regular file, and is not a symbolic link; and
  `R/docs` is not a symbolic link either.
- **The direction line**: exactly this text, as a line of its own with no
  indent:

  ```
  docs/direction.md is the standing direction: where an older roadmap, handoff section or memory note disagrees with it, it wins.
  ```

## Present: D is regular

- **P1.** The first line of the reading list is exactly
  `Read before planning: R/docs/direction.md`.
- **P2.** The second line of the reading list is the 19-space indent followed
  by `P/CLAUDE.md`. The constitution is no longer on the first line.
- **P3.** Every entry the reading list holds today follows, in today's order
  and with today's indent: `R/HANDOFF.md` when today's rule names it, then the
  newest five of `R/docs/handoff/pending/*.md`, newest first, then
  `and N older in R/docs/handoff/pending/` when there are more than five.
  D is not counted among the pending sections, and N is unchanged by D.
- **P4.** The direction line is the line directly before
  `Read before planning: R/docs/direction.md`, with no blank line between
  them, and the line before the direction line is blank: it stands where the
  reading list's first line stands today. The reading list's last entry is
  followed by the blank line and then the paragraph beginning
  `None of those are loaded for you.`, as today.
- **P5.** D appears exactly once in the context, and the direction line
  appears exactly once.
- **P6.** The rest of the context is unchanged. Precisely: take the context
  with D present and (a) replace its first reading-list line and the line after
  it with the single line `Read before planning: P/CLAUDE.md`, and (b) delete
  the direction line. The result is byte-identical to the context the hook
  gives in the same fixture with nothing at D. This includes the
  `Also on disk, and not direction:` paragraph about `SESSION_HANDOFF.md` when
  that file exists: it is still its own paragraph after
  `None of those are loaded for you.`, and the direction line is not in it.
- **P7.** The hook still exits 0 and still emits the Claude Code shape (an
  object holding `hookSpecificOutput`).
- **P8.** The hook does not open D. So D is named whatever it holds and
  whatever its mode: an empty file, a file with mode 000, and a file whose
  bytes include quotes, backslashes, newlines, a NUL, the text
  `Read before planning:` or the direction line itself all give the same
  context as a file holding one ordinary line.
- **P9.** No symbolic link at `R/docs` or at D is followed to decide whether
  D is named, so a link into a mount that does not answer cannot stall
  session start through this check.

## Absent or not regular

- **A1.** With nothing at D, the context is byte-identical to the context the
  engine gives today. In particular it does not contain the string
  `docs/direction.md` anywhere, and the first line of the reading list is
  exactly `Read before planning: P/CLAUDE.md`.
- **A2.** Each of the following at D gives a context byte-identical to the
  context with nothing at D, in the same fixture:
  - a named pipe (FIFO) with no writer;
  - a directory;
  - a symbolic link to a regular file inside the repository;
  - a symbolic link to a regular file outside the repository;
  - a dangling symbolic link;
  - a symbolic link to a directory.
- **A3.** `R/docs` a symbolic link to a directory that holds a regular
  `direction.md` (and nothing else): byte-identical to nothing at D.
- **A4.** With a FIFO at D and no writer, the hook finishes. It is not
  waiting on the pipe: it finishes in the time it takes with nothing at D,
  well inside 30 seconds.
- **A5.** `R/docs/direction.md` is the only path. A regular file named
  `direction.md` anywhere else, such as `R/direction.md` or
  `P/docs/direction.md`, with nothing at D, gives the absent context: no
  direction line, and the first line of the reading list is the
  constitution's.

## Where the hook is started

- **W1.** Started from a subdirectory of R, with a regular D at R's root, D
  is named by its full path under R, exactly as in P1.
- **W2.** Started from a subdirectory S of R that holds `S/docs/direction.md`
  while R has nothing at D: nothing is named and the context is the absent
  context.

## The engine names no project

- **G1.** The path the hook tests is `docs/direction.md` under the
  repository root, for every governed project. The direction line names no
  project, and nothing this change adds under `engine/harness` names one.

## What is not in scope

- The hook does not read, validate, summarise or quote the direction file.
- Nothing changes in the terminal line (`systemMessage`), in any other hook,
  or in any command.
- No other entry of the reading list changes its rule: `HANDOFF.md` and the
  pending sections are named exactly as today.

## How a byte-identical comparison is made fair

The hook writes some once-only lines and records what it has said. A
comparison between two runs is meaningful only if two consecutive runs with
nothing at D already agree byte for byte in that fixture. Each comparison
first runs that control and fails loudly, rather than passing, if the control
itself differs.

## Amendment 1, 2026-10-19, from the adversarial review

- The direction line's text was `... it wins over older roadmaps, handoff
  sections and memory notes.`, which reads "older" as applying to roadmaps
  only, so it told the model the file beats every handoff section and memory
  note, newer ones included. The file it names says the opposite for a
  founder decision dated after its "As of" line. The text above now scopes
  "older" to all three.
- P4 put the direction line last in the reading list. The next paragraph
  opens "None of those are loaded for you. They carry standing direction",
  whose nearest antecedent was then the material the line had just said the
  file outranks. The line now stands above the list, and the paragraph after
  the list is as it is today.
- P9 is new: the link checks come before anything that follows a link.
