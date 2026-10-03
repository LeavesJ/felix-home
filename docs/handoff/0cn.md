### 0cn. 2026-09-25: `felix qualify --gate` fails closed. One read of the table, a failed read refuses with exit 2, a short run refuses, and the gate always says why under `qualified FAIL`

This PR carries claude/qualify-membership-sigpipe (the section beside this
one) in the same slot, by agreement with the carrier. The engine changes are
in lib/qualify.sh, felix (cmd_qualify and the gate's qualified block) and
tests/run.

**Defect closed.** `felix qualify --gate` read `qualification.tsv` four or more
times per run and checked only the first read's status. A later read failing
(a table rewritten mid-run, or a fork failure at load) ran no control and
counted `0 of 0 held` as a pass. `felix gate` then printed `qualified ok` over
a HELD control. Now:
- The table is read once (`felix_qualify_snapshot`), and the verdict comes
  only from that read.
- A failed read exits 2, saying the table could not be read.
- `--gate` exits 0 only with one verdict per selected row, and at least one
  row selected.
- Every derived count and list takes its own status.
- The row command, mutation and premise read /dev/null. A stdin-reading
  checker used to swallow every later row.
- The reader refuses as MALFORMED a row with an empty checker or a checker
  that is not an id, more than six fields, or a CR.
- `felix gate` lifts every refusal reason under `qualified FAIL`, falls back to
  a line saying where to read why, and counts checkers from the rendered rows,
  never from a second read.

**Built by the engine-build workflow, with one process defect.** The workflow
ran a blind contract, the implementation, three adversarial reviewers and a
fixer. The defect: I sent scope rulings mid-run by SendMessage to the
workflow's fixer agent. That started a second copy of it, and the two copies
wrote to one worktree until I stopped the workflow. The auto-memory note
`message-to-workflow-agent-forks-a-copy` records it. Put rulings in the
prompts, or stop the workflow first.

**Handed on, not done here:**
- A checker exiting 126/127 meets fail-expecting controls. The session on
  claude/qualify-rows-fresh-shell owns `_felix_qualify_one`'s eval lines, is
  stacked on this branch, and takes it next in the queue.
- A row led by a NUL byte is invisible to macOS awk and is skipped as a blank
  line. Filed as a task. Its fix must keep the one read.

**Traps paid:**
- The slice runner (the suite's prologue plus only the obligations and
  qualification sections, with one commit standing in for the omitted
  sections) ran those sections in 45 s against the full suite's 50 minutes.
  Without that commit, every control is unrunnable, because the fixture repo
  has no HEAD.
- Another session's `pkill -f 'engine/harness/tests/run'` killed a reviewer's
  mutation run mid-way. A killed run's log has no summary line. Score a
  mutant only from a log that has one.
