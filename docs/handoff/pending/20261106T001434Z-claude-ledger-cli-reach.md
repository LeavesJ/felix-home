### 2026-11-05: a Bash command that runs a routed tool is recorded as a reach of it (0.49.321)

**What changed, in one line.** A session's Bash call that runs, as a program, a
tool the project's route table names is now recorded in the ledger as
`cli <name>`, not `tool Bash`. `felix ledger` and the session-start line count
it as a reach. Spec: `docs/2026-10-31-cli-reach-spec.md`.

**Why.** graphify is a command-line tool, and sessions run `graphify query ...`
through Bash. The ledger recorded every such call as `tool Bash`. So the
session-start line said graphify was "pointed at in 17 of 244 sessions, named
25 times, never reached", and `felix_ledger_retire` proposed retiring it. Over
those sessions it had been run 81 times.

**How** (branch `claude/ledger-cli-reach`).
- **The names file.** Session start writes `state/ledger/<session>.names`
  (`felix_ledger_cli_note`):
  - one line holding the project's bare `routes.tsv` play entries that can be a
    program name, at most 32;
  - written for every source and named for the payload's first `session_id`;
  - made under a dotted name and renamed;
  - a link at its path is replaced, never followed.
- **The reading.** The post-tool hook passes that file to `felix_ledger_signal`.
  When a Bash call's own command text, up to its closing quote, holds a name's
  bytes, the hook loads `lib/ledger-runs.sh`.
  - It reads the command's shell grammar in bash alone, with no process, and
    says whether a name is run as a program. A name that is quoted, an
    argument, in a here-document or comment, or a function being defined does
    not count.
  - It reads through the wrappers `env`, `time`, `nohup`, `timeout`, `command`,
    `nice` and `exec`, and their options.
- **What is recorded.** Only the name. The command, its arguments and its text
  never reach a file: a command can hold a credential, and the home sits in
  synced Documents.
- **The fold** needed no change. `cli` is a kind, like `skill` or `mcp`: its
  row carries the session's namings and suppresses the `named` row and the
  stack zero row of the same owner. `felix_answer_touch` is still handed
  `tool Bash`.

**The baseline, re-read on 2026-11-05.** There is no backfill (D5): the ledger
never held the command.
- **The replay.** Every successful Bash call in the transcripts was replayed
  through the new reading, each session against its own project's names.
  - Each tool_use id is counted once. A resumed session's transcript copies the
    earlier history under its own id, so a copied call is credited to the
    session that ran it.
  - For felix this covers 191,036 calls in 238 of the ledger's 244 sessions.
- **The result: 95 reaches.**
  - felix: graphify 81 calls in 12 sessions, and semgrep 10 in 5.
  - elenchus: graphify 1, and semgrep 3.
  - In 6 of graphify's 12 sessions, and 4 of semgrep's 5, no route had named
    the tool.
- **Folded into a copy of each ledger**, the way the fold writes a `cli` row:
  - felix's graphify row goes from 17 sessions, 0 reaches, 25 named to 23, 81,
    26;
  - semgrep goes from 0 reaches to 10;
  - the retire list (the session-start line's) and the partly list are both
    empty after. In elenchus, semgrep leaves its partly list.
- Method and tables: the PR body.

**Built, and checked.**
- **Blind tests.** A blind author wrote 401 assertions from the spec, without
  the code: 2170 holds 324 on the reading and 2180 holds 77 on the names file,
  the record, the fold and the cost. They ran red at origin/main, then at the
  review's spec commit.
- **Review.** One review round ran, with two lenses: one asked whether a smaller
  design would do, and one looked for wrong answers. It found no blocker, three
  false reaches and seven notes. None of the three is among the 2,151 real
  commands that hold a name. They are fixed, with two of the notes, under
  amended rules:
  - R7: a here-document's end right after a backslash-continued line;
  - R6: a comment inside an array;
  - R5: a quoted word holding two names;
  - R3, a note: wrapper options that take an argument, long forms too;
  - N4, a note: the names file followed a link into a directory.

  The other five notes are now stated limits (R10, R11) or a decision (D1). A
  shorter reading that stops at `case`, `[[ ]]`, `${...}` and the like was
  measured and declined (D7).
- **Cost**, measured on 2026-11-05 under bash 3.2 at load 6.
  - The reading averages about 3 ms of CPU on each of the 2,151 real commands
    that hold a name, and loading it about 0.6 ms more. A command that holds no
    name pays neither.
  - A 4 MB Bash payload costs about 5 ms more than before, about as much as
    the noise between runs.
  - The five hardest 16 KB shapes the review found take 0.1 to 0.7 s, under
    C4's 2 s.
- **Bash 5 and gawk** were not run here, since this Mac has neither. CI's suite
  runs under both.

**Limits, stated** (R10 and R11).
- Runs it misses, which stay `tool Bash`:
  - a command handed to another shell as text;
  - a program named as another program's argument (`xargs`, `sudo`, a package
    runner);
  - `coproc` and aliases;
  - a substitution inside arithmetic or inside an unquoted here-document's body;
  - anything past the bounds.
- Runs it reports that the shell would not make:
  - a quoted word that spells a reserved word or an operator (`'!' graphify`);
  - an assignment or `--` after a wrapper;
  - a function the command defines under a tool's name and then calls;
  - a command the shell cannot parse, read up to where it breaks.

  Most of these fail when run, and a call that fails is never sent to the
  hook.

**Follow-ups.**
- `stack.tsv`'s own `cli` kind (elenchus declares `cli strix-agent`) is not
  read for names yet, so a declared CLI that is run keeps its zero row (D1).
- A Skill call of a standalone skill declared `skill <name>` is filed under
  `<name> (built-in)` (D6).
- `felix_route_step_used` does not see a CLI run.
- `felix_ledger_session_id` matches a regex over the whole payload, up to 4 MB,
  on every tool call.
