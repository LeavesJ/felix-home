### 2026-10-01: a seeded commissioning check reads done only when its lookups ran to the end

Found by the adversarial review of claude/commission-lookup-fails-unknown. It
was reproduced there with `ulimit -u 1` inside a check's own substitution.

**Defect closed.** Ten of the template's fourteen rows decided from what an
engine lookup printed, and they read `done` when the lookup never finished.
Measured on macOS bash 3.2.57:
- `[ -z "$(lookup)" ]` (probes, obligations, reach) is true when the
  substitution cannot fork: it prints nothing, status 128. It is also true
  when the substitution cannot make its pipe (`ulimit -n 3`): nothing,
  status **0**. So `out="$(lookup)" && [ -z "$out" ]` does not close it.
- `[ "$(lookup | grep -c bad)" -eq 0 ]` (stack, preflight, discover,
  human_steps) is true when the lookup dies inside the pipe, with pipefail
  or without, because grep -c still prints 0.
- `[ -n "$(lookup)" ]` (gate_declared) is true on what a lookup printed
  before it died.
- `lookup | grep -q good` (envelope, baseline) is true on what a lookup
  printed before it died when pipefail is off. With pipefail on, it holds on
  a lookup that answered and returned non-zero.

The rows are in engine/harness/templates/commissioning.tsv and in every
governed project's copy: bazaar, elenchus, felix, sv2-apps and veldra.

**Mechanism, and why this one.** Each lookup is read alone with a mark
written after it, `x="$(lookup; printf .)" && [ "${x%.}" != "$x" ]`. The
row decides by `grep -c` over `${x%.}`, never over a pipe from the lookup.
Probes feeds `felix_probes_blocking` from the value it read, through
`{ felix_probes_blocking; printf .; }`.
- The lookup's status is deliberately not asked. Under pipefail,
  `felix_stack_plan` returns grep's 1 on a stack.tsv holding only comments,
  so a status-carrying shape would hold the stack row on every fresh project.
- The count, rather than `[ "$x" = . ]` or `[ -n "${x%.}" ]`, keeps the old
  reading of blank lines. `felix_json_str` prints an empty line for
  `"gate": ""`.
- Stack now counts `unknown` lines. That is the action `felix_stack_plan` is
  to print when the declared list cannot be read (claude/commission-lookup-fails-unknown).
- Preflight counts `unknown` too. `felix_ready_report` already prints it when
  it cannot list plugins, and the old check passed it.
- A lint was not added. #375 tried a validator for the check column and
  reverted it: a correct one needs a quote-, redirect- and list-aware parser.

**Built as spec, blind assertions, fix, review.**
- A blind author wrote 115 assertions from the contract alone, in its own
  worktree on origin/main. 37 are red against origin/main, and C4
  (reachability) and the old findings are green there.
- The first fix (e8bb0029) covered seven rows. The blind block found
  envelope, gate_declared and baseline, plus a status read on the probes
  stage (521e0757).
- Final rows: 115/115 against the template and against the bazaar, felix
  and sv2-apps tables. Elenchus and veldra pass all but six named
  obligations cases, because neither table has an obligations row.
- Mutation: reverting any one row to main's text reds only that need's
  assertions (2 to 6 each, 37 in all).
- `felix commission --status` reads the same done and held rows under old
  and new tables in all five checkouts. Provider answers read `stale`,
  because their topology hashes the table set.

**What landing costs.** Every project's table changed, so every policy hash
moved.
- Felix: the commission grant (projects/felix/autonomy.commission) and the
  receipt go stale. `felix merge` refuses every PR until the founder runs
  `felix autonomy --allow commission` and then `felix commission`.
- The other projects: each receipt goes stale until a `felix commission` run
  in that checkout.
- Provider rows: constitution_audited and automation_surveyed (and
  obligations_surveyed on elenchus) read `stale` until their skills run again.
- The carrier placed this at 0.49.265, right after #340 (.263) and #385
  (.264). Those also change felix's tables, so one re-stamp covers all three.
  It lands after #388, which brings projects/webapp and
  projects/behaviorchangebench with the old shapes. Merge main once #388 is
  on it. In both tables, give each of the ten needs above the check cell
  (column 6) of the template's row for the same need. Then point the blind
  block at each table (`CMT_TABLE`).

**Handed on, not done here:**
- A fork that fails deeper, inside a pipeline or substitution the lookup
  runs itself, leaves the lookup printing a short answer and reaching its
  end. Most lookups end in `return 0`. That is the lookup's to report as an
  `unknown` line, which the lookup-fails-unknown branch does for the declared
  list.
- gate_shown_failing ends in `grep -q .` behind three filters. Under
  pipefail, a mistakes.log large enough to fill the pipe after grep quits
  reads held, not done. It fails closed, so it was left alone.
- Nothing reports a project row whose check still differs from the
  template's for the same need (offered as its own task).

**Traps paid:**
- A blind assertion of C3 (no pipe can be made) cannot go through
  felix_commission_ask: its `</dev/null` needs fd 3, which `ulimit -n 3`
  refuses. The block evaluates the check text directly.
- In a Bash call, `rm -rf` trips the fact-forcing gate whatever facts come
  first. Create a fresh `mktemp -d` instead.
