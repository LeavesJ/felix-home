### 2026-10-01: a seeded commissioning check reads done only when its lookups ran to the end

Found by the adversarial review of claude/commission-lookup-fails-unknown,
and reproduced there with `ulimit -u 1` inside a check's own substitution.

**Defect closed.** Ten of the template's fourteen rows decided from what an
engine lookup printed. They read `done` when the lookup never finished.
Measured on macOS bash 3.2.57:
- `[ -z "$(lookup)" ]` (probes, obligations, reach) is true when the lookup
  cannot fork inside the substitution, which prints nothing with status 128.
  It is also true when the substitution cannot make its pipe
  (`ulimit -n 3`), which prints nothing with status **0**. So
  `out="$(lookup)" && [ -z "$out" ]` would not close it.
- `[ "$(lookup | grep -c bad)" -eq 0 ]` (stack, preflight, discover,
  human_steps) is true when the lookup dies inside the pipe, with pipefail
  or without.
- `[ -n "$(lookup)" ]` (gate_declared) is true on what a lookup printed
  before it died.
- `lookup | grep -q good` (envelope, baseline) is true on what a lookup
  printed before it died when pipefail is off. With pipefail on, it holds on
  a lookup that answered and returned non-zero.

The rows are in engine/harness/templates/commissioning.tsv and in every
governed project's copy: bazaar, behaviorchangebench, elenchus, felix,
sv2-apps, veldra and webapp.

**Mechanism, and why this one.** Each lookup is read alone with a mark after
it, `x="$(lookup; [ $? -lt 128 ] && printf .)" && [ "${x%.}" != "$x" ]`.
The row then decides by `grep -c` over `${x%.}`, never over a pipe from the
lookup. Probes feeds felix_probes_blocking from the value it read, through
`{ felix_probes_blocking; [ $? -lt 128 ] && printf .; }`.
- **Status 128 or more is a death.** A dead last pipeline stage returns 128
  or 129 (felix_stack_plan, felix_setup_status), so the mark is not written.
- **A lower status is an answer.** felix_stack_plan returns grep's 1 under
  pipefail on a stack.tsv holding only comments. A shape that carries any
  status holds that row.
- **Blank lines read as before.** The count, rather than `[ "$x" = . ]` or
  `[ -n "${x%.}" ]`, keeps the old reading of blank lines. felix_json_str
  prints an empty line for `"gate": ""`.
- **`unknown` lines hold their rows.**
  - stack counts an `unknown` action.
  - human_steps counts an `unknown` step.
  - preflight counts an `unknown` line, which felix_ready_report already
    prints when it cannot list plugins.

  claude/cap-unread-callers makes felix_stack_plan and felix_setup_status
  print theirs. With that engine and these rows, an unreadable capabilities
  file holds the stack row. Old rows read done there, and on main's engine
  both still do.
- **No lint.** #375 tried a validator for the check column and reverted it:
  a correct one needs a quote-, redirect- and list-aware parser.

**Built as spec, blind assertions, fix, review.**
- **Blind assertions.** A blind author wrote 115 assertions from the contract
  alone, in its own worktree on origin/main. 37 were red there. The
  reachability and old-finding cases were green.
- **First fix and its gaps.** The first fix (e8bb0029) covered seven rows.
  The blind block found envelope, gate_declared and baseline, plus a status
  read on the probes stage (521e0757).
- **Adversarial review.** The review of e8bb0029 confirmed the fix where it
  claims to work. It found the 128/129 loop deaths and the missing `unknown`
  in felix_stack_plan, and corrected three sentences of the header (eb2d8374).
- **Assertions after review.** Eight not-blind assertions were added after
  review (7e4e429c). They are red against 521e0757, so they pin the status rule.
- **Final count.** 123 assertions: 123/123 against the template and against
  the bazaar, behaviorchangebench, felix, sv2-apps and webapp tables.
  origin/main fails 45. Elenchus and
  veldra fail only six named obligations cases, because neither table has an
  obligations row.
- **Mutation.** Reverting any one row to main's text reds only that need's
  assertions, 2 to 8 each, 45 in all.
- **Normal states.** `felix commission --status` reads the same done and held
  rows under old and new tables in all six checkouts found here (every
  project but webapp).
  - One state changes on purpose: preflight, when the claude CLI is present
    and its plugin list is empty, goes from done to held, and the routed
    plugins really are absent.
  - Provider answers read `stale`, because their topology hashes
    commissioning.tsv.

**What landing costs.**
- **It escapes.** commissioning.tsv is in FELIX_ESCAPE_TABLES, so
  `felix merge` refuses it. It lands by `gh pr merge` on the founder's yes.
- **Every policy hash moves.**
  - Felix's commission grant and receipt go stale. `felix merge` refuses
    every PR until the founder runs `felix autonomy --allow commission`, then
    `felix commission`.
  - Each other project's receipt goes stale until a `felix commission` run in
    its checkout.
  - The provider skills (constitution_audited, automation_surveyed, and
    obligations_surveyed on elenchus) read `stale` until they run again.
- **Slot.** The carrier placed this at 0.49.265, after #340 (.263) and #385
  (.264), which also change felix's tables, so one re-stamp covers all three.
- **#388's two tables are done.** #388 brought projects/webapp and
  projects/behaviorchangebench with the old checks, unchanged from the old
  template. Main was merged at ea865e82, and both tables now carry the
  template's check cell for all ten needs. Each passes 123/123 and fails 45
  on main. behaviorchangebench's checkout reads the same states under old and
  new rows. No checkout here is bound to webapp. A table added after this
  must be given the same cells.

**Handed on, not done here:**
- **Nested deaths.** A fork failure nested inside a lookup can still leave a
  short answer, a status under 128 and the mark. The review reproduced it for:
  - preflight, in felix_ready_wanted;
  - probes, in felix_probe_state;
  - obligations, in felix_obligations_orphans' row read;
  - preflight again with `ulimit -n 11`, a redirection failing inside
    felix_ready_report.

  Each is the lookup's to report. Most lookups end in `return 0`.
- **preflight's `unknown` cannot be cleared by its answer.**
  felix_ready_report prints `unknown` ("no claude CLI here") for an empty
  plugin list even when the CLI is present, and `felix ready --fix` acts only
  on absent and disabled. The row reads held rather than unknown. It ignores
  `undeclared`, which `felix ready` itself counts.
- **The mark is only a trailing `.`.** A lookup that exits 0 mid-line after a
  `.` would pass. No lookup calls exit.
- **gate_shown_failing can hold falsely.** It ends in `grep -q .` behind
  three filters. Under pipefail, a mistakes.log that fills the pipe after
  grep quits reads held. That fails closed.
- **Tables copied from older templates.** Tables outside this repository, or
  copied from an older template, keep the old rows. A drift report is being
  built as claude/commission-template-drift.

**Traps paid:**
- **C3 cannot go through felix_commission_ask.** Its `</dev/null` needs fd 3,
  which `ulimit -n 3` refuses. The block evaluates the check text directly.
- **The fact-forcing gate.** In a Bash call, `rm -rf` trips it whatever facts
  come first. Create a fresh `mktemp -d` instead.
- **"Held on every fresh project" was wrong.** `felix new` seeds the
  catalogue's `always` rows into stack.tsv, so a manifest of only comments
  comes from a hand edit, not from `felix new`.
