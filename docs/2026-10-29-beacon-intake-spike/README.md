# Agent Beacon as the Codex and Droid transcript reader: a spike

Read on 2026-10-29. Lane item 11 (direction row 19: the Factory Droid adapter first, then Codex).
A design on file and a measurement kit, not engine code. Nothing here is on the enforcing path,
and nothing here changes a table, a hook, the gate or `docs/direction.md`.

## The claim under test

Rescoped on 2026-10-29 by the founder's review. The claim is **"Beacon replaces the transcript
reader for Codex and Droid"**, not "Felix may not have to build the adapter". Of the seven items
left on the Codex adapter (roadmap §3 item 5), one is capture: one transcript reader per host,
including `felix inventory`'s session reader. The other six (apply_patch paths for the Write and
Edit rows, a Codex aware Stop output, "installed" from Codex's config, the trusted hook hash check,
the session id and shell working directory, `view_image` as a read) stay Felix's either way.

It passes on four conditions. Changing roadmap item 5 is a direction.md edit and waits for the
founder's yes; this spike does not make it. The roadmap change that followed the run is #474.

## Verdict: no go on Beacon as the Codex reader. Droid and the live OTLP path were not run

**Decided by the founder on 2026-11-10** (recorded on PR 473 and PR 474). He chose "Approve, but
measure Droid first": "The no-go lands for Codex now. Droid, which the spike never ran, is tested
before its reader is decided." So the verdict below is for Codex and for Beacon's offline rollout
reader, the one thing the runs measured. Two parts of the claim under test were not run, and this
spike gives no verdict on them:

- **Factory Droid: not run.** No Droid session was run, so Beacon's Factory reader, Droid's real
  tool names and the Factory session record are untested. Droid's transcript reader is not decided
  until a Droid run measures it. That measurement is open and is not done in this spike.
- **Beacon's live OTLP path: not run.** No collector ran during the after runs, so that row reads
  `not_run`. What this file says about the live path is a reading of Beacon's source at the pin.

Measured on the founder's Mac on 2026-10-29, twice (`run-2026-10-29.md`: run 2 on codex 0.162,
run 3 end to end on codex 0.165). All four conditions pass for
Codex on the offline reader, and that is exactly why Beacon is not worth taking on for Codex: its
reader parses the same rollout file Felix would read, and the rollout already holds the
`write_stdin` chars. So, for Codex:

- **Felix writes its own Codex transcript reader**, the one roadmap §3 item 5 already names ("one
  transcript reader per host"). It reads `apply_patch` paths, the tool output (where this Codex
  writes the exit status, `Process exited with code <n>`, since it writes no `exec_command_end`),
  and the `write_stdin` chars.
- **At Stop, that reader scans the rollout's `write_stdin` chars against the deny rows**, the check
  the 10-02 audit proposed. It cannot stop a typed `git commit --no-verify`, only name it after the
  fact; the merge time check stays the guarantee.
- **Beacon stays at most an optional extra source** behind that reader, not the Codex reader.
  What it would add, a maintained parser across hosts, is untested here (Droid not run, live path
  not measured), and its install edits Codex's config, turns on prompt logging
  (`log_user_prompt = true`) and puts its own Stop hook ahead of Felix's.
- `docs/direction.md` is unchanged; any edit there is the founder's.

## Results per condition

Run 2's results; run 3 repeated each one on codex 0.165, with every behaviour row passing.

| # | Condition | Mac run, 2026-10-29 | What it rests on |
|---|---|---|---|
| 4 | `write_stdin`: is input typed into an open shell recorded? | **Pass**, offline reader; live OTLP not measured | A `typed` row carrying the `--no-verify` commit; no collector ran, so the live row measured nothing |
| 1 | Hook trust survives `beacon endpoint install` | **Pass** | 8 of 8 `felix@felix` trust lines byte identical, plugin files unchanged, deny and hold unchanged |
| 2 | It runs isolated and nothing leaves the machine | **Pass** | The same 12 proxy CONNECTs before and after, all Codex's own plugin sync; lsof clean; no launchd job |
| 3 | Field by field parity with the raw session record | **Pass** on every field the rollout holds | `exit_code` is `absent_in_raw`: this Codex writes none; the status is in the output on both sides |
| 4 | The same, on Beacon's live OTLP path | **Not run** | No `beacon-otelcol` process ran during the after runs |
| | Droid, every condition | **Not run** | No Droid session was run; its reader is not decided until one is |

The first run of that day measured nothing and still printed verdicts (the mock plays no plan
without `PROBEMARK`, and a failed install was carried past). `mac-run.sh` now refuses both. The
sections below are the reading of Beacon's source at the pin that the run was built to test; where
the run settled a point, the section says so.

### Condition 4: write_stdin

Felix's gap, from the 10-02 run: a `git commit --no-verify` typed into an open Codex shell reached
no hook and went straight through. Beacon's source at the pin says:

- **It is recorded, on both paths, as a generic tool call.** The rollout reader writes every
  `function_call` as `tool.invoked` with `tool.name` `write_stdin` and the parsed arguments, so
  `gen_ai.tool.call.arguments.chars` holds the typed text. The live OTLP path writes Codex's
  `codex.tool_result` as `tool.invoked` with `tool.command` holding the raw arguments string.
- **It is not recognised as a command.** `write_stdin` is not in Beacon's shell tool list, and
  `ToolCommandLine` has no case for its `chars` field (it has one for another vendor's
  `terminal_send`). So `command.command` is empty, and any Beacon rule that matches commands would
  miss the typed `git commit --no-verify`. The string `write_stdin` appears nowhere in Beacon's
  source.
- **What Felix gets.** `beacon-intake.sh` now pulls `chars` out of a counted Codex `write_stdin`
  call and prints a `typed` row after its signal, JSON escaped, so a newline or a tab cannot break
  the row. A call with no `chars`, or `chars` that are not text, prints a `typed_unknown` row with a
  reason code instead of nothing. Empty `chars` (a read of the shell's output) prints nothing.
- **Limits.** Beacon redacts secrets and caps sizes, so the text may be shortened. The record is
  after the fact: it can raise a question about a session, never stop the commit. The merge time
  check stays the guarantee, as the roadmap says.

The run showed this detection is not Beacon's to give: the raw rollout holds the same chars, so
Felix's own reader gets them without Beacon. `mac-run.sh` checks for a `typed` row carrying
`--no-verify` on the offline reader, and on the live OTLP path only when a collector process ran.

### Condition 1: hook trust survives

What Beacon's installer does to Codex, read in `internal/endpoint/hooks/codex.go` and
`settings_hooks.go`:

- It writes `$CODEX_HOME/hooks.json` (it honours `CODEX_HOME`), mode 0600. It removes only commands
  carrying its own `beacon-hooks` binary, keeps every other group, and keeps fields it does not
  model. Then it appends two groups of its own: a SessionStart and a Stop hook.
- Both answer `{}` and exit 0 on every path. Neither blocks, and Beacon's comment says the Stop
  answer "continues the turn's normal end".
- It also edits `$CODEX_HOME/config.toml` to point Codex's OTLP export at its local collector.
- For Droid it appends SessionStart, UserPromptSubmit, a PostToolUse on `Write|Edit|MultiEdit|Create`,
  Stop and SessionEnd. It installs no PreToolUse for Droid, so it adds no deny of its own.

Felix's Codex hooks are not in that `hooks.json`. They are plugin hooks (corrected by the
founder's Mac session in the PR 473 review):

- definitions in `$CODEX_HOME/plugins/cache/felix/felix/<ver>/hooks/hooks.json`;
- trust in `config.toml`, one `[hooks.state."felix@felix:hooks/hooks.json:<event>:0:0"]` table per
  hook with a `trusted_hash`.

So the risk is Beacon's rewrite of `config.toml`, not of the user level `hooks.json`. The roadmap
records that a changed hook silently turns off in Codex until it is trusted again. `mac-run.sh`
decides condition 1 two ways:

- **Static, pass or fail.** Every `felix@felix` trust table and its `trusted_hash` line must come
  through Beacon's install byte for byte, and every file of the Felix plugin must keep its hash.
- **Dynamic.** It plays the deny, Stop hold and write_stdin scenarios before the install and again
  after it, and compares every call, output and user or assistant message. Developer messages carry
  Felix's session-start text, which can change from run to run, so they are compared apart as a
  row to read, never as a fail.

Run 2 passed both ways once the comparison stopped counting values that change on every run:
Felix's `hook_run_id` index (Beacon's Stop hook ahead of Felix's moves `stop:7` to `stop:9`),
chunk ids, shell session ids and short commit hashes.

For Droid there is nothing to keep yet. The Droid adapter is not built, so Felix has no Droid hooks,
and that row reads `not_run` by design.

### Condition 2: isolation and egress

`mac-run.sh` builds Beacon from the pinned commit first, before any proxy or egress log exists, so
the build's own traffic is neither refused nor counted. It then runs with a scratch `HOME` and a
scratch `CODEX_HOME` seeded fresh the 10-02 way (`rig/base.toml`, then `codex plugin marketplace
add` and `codex plugin add felix@felix` from a copy of the deployed plugin, then the trust hashes),
never from the real `~/.codex`, which holds the founder's login and a real provider. It installs
with `--service none --no-start --no-backfill`
and stdin from `/dev/null`, so there is no daemon, no launchd job, no 30 day backfill and no
interactive setup (which is where Beacon Cloud is preselected). It then logs egress three ways:

- every proxy aware client points at the rig's `refuser.py`, started as `refuser.py <portfile>
  <logfile>` on the random port it writes out; Codex gets it through `cx.sh`'s own `PROXY_PORT`;
- an `lsof` poll every 0.2 seconds records any socket to a non loopback address held by a
  process named `beacon*`, or by any process the run itself started (run 3 counted other
  sessions' node servers when the poll matched on names alone);
- optionally, `sudo tcpdump` on a named interface records every non loopback packet.

It also checks that no launchd job was added and no skills were written under the scratch HOME.
This path asks for none of Beacon's memory, browser extension or SIEM forwarding. On the run, the
proxy saw only Codex's own plugin sync, the same before and after.

### Condition 3: field by field parity

"Evidence format" is not a defined term in this repository, so here are the fields, each with the
source it is read from. `parity.sh` joins calls on the host's own call id and reports, per field,
how many calls the raw record holds it for, how many Beacon holds it for, and how many are equal.

Codex, raw rollout against Beacon's rollout reader (`sync --print`):

| Field | Raw source | Beacon source | By source at the pin |
|---|---|---|---|
| session id | `session_meta.payload.id` | `session.id` | held |
| working directory | `turn_context.payload.cwd` | `session.working_directory` | held on the rollout path; on OTLP only if Codex exports `cwd` |
| tool name | `function_call.name`, `custom_tool_call.name` | `tool.name` | held, the host's own name |
| full tool input | `function_call.arguments`, `custom_tool_call.input` | `gen_ai.tool.call.arguments` | held, subject to redaction and size caps |
| paths inside apply_patch | the `*** Add/Update/Delete File:` and `*** Move to:` lines of the patch | the same lines in Beacon's copy of the input | the patch text is carried whole; Beacon parses no paths, so Felix must |
| typed input | `write_stdin` `arguments.chars` | `gen_ai.tool.call.arguments.chars` | held as an argument, not as a command |
| tool output | `function_call_output.output` | `command.output`, else `gen_ai.tool.call.result` | held on the rollout path (`emitToolResult` keeps it); the OTLP path keeps no output for a shell call |
| exit code | `event_msg` `exec_command_end.exit_code` | `command.exit_code` | **absent**: the rollout reader parses no exit code |

Droid, raw Factory session against Beacon's Factory reader:

| Field | Raw source | Beacon source | By source at the pin |
|---|---|---|---|
| session id | the session file's name | `session.id` | held |
| working directory | the record's `cwd` | `session.working_directory` | held |
| tool name | `tool_use.name` | `tool.name` | held; a tool result arrives with no name |
| full tool input | `tool_use.input` | `gen_ai.tool.call.arguments` | held |
| exit code | none, only `tool_result.is_error` | `event.action` `tool.failed` | **no exit code on either side**; failure is a flag |

Two raw record shapes were assumptions read from Beacon's own parsers. The run settled the first:
codex-cli `0.162.0-alpha.17.2` writes no `exec_command_end`, so `exit_code` reads `absent_in_raw`
and the exit status is only in the output text. The second, that the Factory session id is the
file name, stays a TODO in `parity.sh` until Droid runs.

The PR 473 review read Beacon's Codex `command.executed` as carrying neither the exit code nor
the output text. At the pin that holds for the live OTLP path only. The rollout reader keeps the
output (`codexsession/mapper.go`, `emitToolResult`), and the run confirmed it: `tool_output`
matched, and the exit status sits in it. Either way, on Codex Beacon is an extra source behind a
Felix reader, not the reader itself.

Exit codes matter to Felix: `lib/verify.sh` already notes that Claude Code records only `is_error`
and that Bash results carry no exit code. Beacon does not close that gap on either host.

## Dependency shape, if Beacon is ever an extra source

The founder's terms, held here:

- **Pin an exact version.** `v1.3.47`, commit `90b19ae0626fd6fd060c62ddbc70827a23242f4e`.
  `mac-run.sh` refuses to run if the tag has moved. The spike read `7b23b15`, nine commits later,
  and none of the nine touch the Codex reader, the Factory reader, the OTLP converter or the
  installer.
- **Felix's own record format is the contract.** The rows `beacon-intake.sh` prints (a ledger
  signal in `felix_ledger_signal`'s shape, a skip with a reason code, a `typed` row) are what
  Felix keeps. Beacon's schema is an input to one reader, not Felix's format.
- **Beacon sits behind a reader, as one source among others.** If Beacon changes course, or a pilot
  machine cannot run it, a native reader for the rollout or the Factory store prints the same rows.
- **Why this needs care.** Asymptote's paid tier sells policy guardrails, which competes with
  Felix. Its README now leads with agent memory. Depending on its readers is fine; depending on
  its direction is not.

## Trust, plainly

Every Beacon event comes from the agent's side of the boundary: a hook the host runs, OTLP the
host's own process exports, or a session file the host wrote. An agent that wants to look like it
ran the tests can write that into its own transcript, and the loopback OTLP receiver takes records
from any local process without authentication. That is the trust class of Felix's own PostToolUse
ledger, so the ledger's rule holds:

- A Beacon row never reaches a receipt, the gate, a merge blocker, or an obligation's SATISFIED.
  Done is decided by checks Felix runs itself against the tree (the agent must not grade its own
  exam).
- A Beacon row may narrow and never widen (direction §1). It can raise a question ("this session
  typed `--no-verify` into a shell"); it can never clear one.
- A missing event is unknown, not zero. An empty log is refused, not read as "no tools used".

## Egress and footprint risks

- **The interactive installer preselects Beacon Cloud.** Confirming it forwards session history to
  Asymptote Labs at `beacon.sh`. On a pilot machine where egress control comes first, Felix must
  never run or suggest the interactive setup.
- **It installs into the agent.** Setup can write Beacon Skills into `~/.claude/skills` and
  `~/.agents/skills`, register an MCP server, and edits Codex's `config.toml` and `hooks.json`.
- **A new runtime.** A Go daemon is not acceptable on the enforcing path (row 6). Off it, as a
  reader, it is a third party binary from a seed stage company.
- **Updates and intel are opt in.** Beacon Intel (`intel.beacon.sh`) was not traced in this read.

The two offline readers avoid most of it: no daemon, no hooks, no account, no network in their
code path. `mac-run.sh` checks that last claim rather than trusting it.

## What the reader does

`beacon-intake.sh` reads a Beacon log and prints one signal or skip row per event, so nothing is
dropped silently, plus `typed` rows as above. Fixed in this round: on the live OTLP path Beacon
writes a finished non shell Codex call as `tool.invoked`, which the first version skipped. A
Codex `tool.invoked` with collection method `otlp` now counts as the finished call; on the rollout
path, and for every other harness, `tool.invoked` still opens a call and is skipped.

Run on Beacon's own dashboard test log (47 events) it counts none: 24 events are not tool
completions, 22 carry no `event.fidelity`, and 1 is from a harness Felix does not govern. The
fields Felix needs to trust a row are optional, and older or hand built writers leave them out.

Gaps, in order of cost:

1. **No exit codes** from Beacon on Codex or Droid (condition 3). On Codex the rollout itself
   holds none; the status is in the output text, which Felix's own reader parses.
2. **write_stdin is unclassified** by Beacon, so Felix parses it (condition 4).
3. **Provenance is optional.** A log without `event.fidelity` yields nothing
   (`beacon_fidelity_absent`).
4. **Failed calls count on Codex OTLP.** Beacon does not map `codex.tool_result`'s `success`
   attribute to `tool.failed`, so a failed non shell call counts. Claude Code's PostToolUse counts
   only completed calls, so the two ledgers differ here.
5. **Tool names are the host's.** Felix's tables key on Claude Code's names; a per host name table
   is Felix's decision and is not built here.
6. **apply_patch paths are not parsed by Beacon.** Felix parses the patch text, which it must do
   for the Write and Edit rows anyway.
7. **The fixtures are modeled, not captured.** They follow Beacon's writers at the pin; the Mac
   run checked the same fields on real rollouts.

## Run it

```
docs/2026-10-29-beacon-intake-spike/test.sh
docs/2026-10-29-beacon-intake-spike/beacon-intake.sh <runtime.jsonl>
docs/2026-10-29-beacon-intake-spike/parity.sh codex|factory <raw-session.jsonl> <beacon.jsonl>
docs/2026-10-29-beacon-intake-spike/mac-run.sh <audit-dir>    # the founder's Mac only
```

`beacon-intake.sh` rows:

```
signal        <TAB> harness <TAB> session <TAB> collection_method <TAB> kind <TAB> name
skip          <TAB> reason_code <TAB> line <TAB> event_id <TAB> reason_detail
typed         <TAB> harness <TAB> session <TAB> call_id <TAB> chars as a JSON string
typed_unknown <TAB> reason_code <TAB> line <TAB> event_id <TAB> reason_detail
```

`parity.sh` rows:

```
field    <TAB> name <TAB> raw_source <TAB> beacon_source <TAB> raw_n <TAB> beacon_n <TAB> equal_n <TAB> verdict
mismatch <TAB> name <TAB> call_id <TAB> raw value as JSON <TAB> beacon value as JSON
```

with verdict `match`, `differs`, `absent_in_beacon` or `absent_in_raw`.

`mac-run.sh` writes `results.tsv` (condition, check, verdict, detail) with verdict `pass`, `fail`,
`not_run`, `info` or `look`. `<audit-dir>` is the archived 10-02 audit; the script copies it whole
and runs from the copy, since the rig writes `runs/<name>/` next to `rig/`. It drives
`rig/run.sh` directly, patches the copy of `cx.sh` to today's Codex path and records the Codex
version, and swaps `plan-M4.json`'s typed text for a `git commit --allow-empty --no-verify` in a
git fixture made by `rig/fixture.sh`. The header documents each fill-in as the 2026-10-29 run set
it; the Stop plan, the trust command and the marketplace copy are still the founder's to give,
because they are not in felix-home. The run checks the seed it gets and refuses a bad one, refuses
a baseline Felix did not govern, and refuses a failed install.

Each script exits 0 when it read everything and 2 with one `refuse` row on stderr when it could
not. They need bash and jq (`FELIX_JQ` names the parser, as `lib/status.sh` does). jq is the one
new dependency, named because these read JSON a third party writes, which sed extraction misreads
on the first nested object; it never runs on the enforcing path. `mac-run.sh` also needs git, Go
and make to build the pinned Beacon, and python3 for the rig.

## Reason codes

Canonical, snake_case, stable. `test.sh` fails if any script and these tables ever differ.

`beacon-intake.sh`:

| reason_code | Row | Meaning |
|---|---|---|
| `beacon_usage` | refuse | Not exactly one argument. |
| `beacon_jq_missing` | refuse | No JSON parser at `FELIX_JQ` (default `jq`). |
| `beacon_input_unreadable` | refuse | Nothing readable at the path, or the path is a directory. |
| `beacon_input_empty` | refuse | The log holds no events, which cannot be told from capture never wired. |
| `beacon_line_not_json` | refuse | A line is not one JSON document. |
| `beacon_line_not_object` | refuse | A line is JSON but not an object. |
| `beacon_vendor_mismatch` | refuse | A line does not say `vendor: beacon`. |
| `beacon_schema_version_unsupported` | refuse | A line's `schema_version` is not `1.0`. |
| `beacon_parser_failed` | refuse | jq itself failed. |
| `beacon_tool_failed` | skip | A failed call. PostToolUse records completed calls only. |
| `beacon_action_not_counted` | skip | The action does not close a tool call (prompts, approvals, `tool.invoked` outside Codex OTLP, usage). |
| `beacon_harness_missing` | skip | No `harness.name`. |
| `beacon_harness_not_governed` | skip | Not `claude_code`, `codex_cli`, `codex_desktop` or `factory`. |
| `beacon_fidelity_absent` | skip | No `event.fidelity`. |
| `beacon_fidelity_inferred` | skip | Beacon derived the action rather than the source naming it. |
| `beacon_session_missing` | skip | No `session.id`, so no ledger file to hold it. |
| `beacon_call_identity_missing` | skip | No call id and no event id, so a second report could not be told apart. |
| `beacon_duplicate_call` | skip | This call was already counted. |
| `beacon_tool_name_missing` | skip | No tool name, and none is guessed. |
| `beacon_field_unsafe` | skip | A tab or line break would break the ledger row. |
| `beacon_typed_input_absent` | typed_unknown | A counted `write_stdin` call has no `chars`, so what was typed is unknown, not nothing. |
| `beacon_typed_input_not_text` | typed_unknown | `chars` is present but not a string. |

`parity.sh`:

| reason_code | Row | Meaning |
|---|---|---|
| `parity_usage` | refuse | Not exactly three arguments. |
| `parity_host_unknown` | refuse | The host is not `codex` or `factory`. |
| `parity_jq_missing` | refuse | No JSON parser at `FELIX_JQ`. |
| `parity_input_unreadable` | refuse | Nothing readable at one of the paths. |
| `parity_input_empty` | refuse | One of the files holds no records. |
| `parity_line_not_json` | refuse | A line of either file is not one JSON document. |
| `parity_parser_failed` | refuse | jq itself failed. |

`mac-run.sh`:

| reason_code | Row | Meaning |
|---|---|---|
| `mac_usage` | refuse | Not exactly one argument, the audit directory. |
| `mac_not_darwin` | refuse | Not a Mac. |
| `mac_rig_missing` | refuse | A rig file or a named plan is missing under the audit directory. |
| `mac_env_missing` | refuse | A required variable from the header is not set. |
| `mac_otelcol_missing` | refuse | No executable `beacon-otelcol` at `BEACON_OTELCOL`. |
| `mac_prompt_unmarked` | refuse | `RIG_PROMPT` carries no `PROBEMARK`, so the mock would play no plan. |
| `mac_codex_missing` | refuse | No executable Codex at `CODEX_BIN`, or `cx.sh` still names the old path after patching. |
| `mac_plan_unpatched` | refuse | `plan-M4.json` holds no write_stdin `chars` to swap. |
| `mac_seed_untrusted` | refuse | After seeding, `rig/hookslist.py` failed, or does not list every Felix hook that has a trust line as trusted (codex 0.165 trusts only the hook half of a two part hash). |
| `mac_seed_invalid` | refuse | The fresh seed failed: no marketplace copy, the plugin install or trust command failed, not exactly one Felix plugin `hooks.json`, or no `felix@felix` `trusted_hash` in `config.toml`. |
| `mac_refuser_failed` | refuse | `refuser.py` wrote no port. |
| `mac_tool_missing` | refuse | git, go, jq, lsof, shasum, make or python3 is not on PATH. |
| `mac_scratch_failed` | refuse | The scratch directory could not be made. |
| `mac_clone_failed` | refuse | Beacon's repository could not be cloned. |
| `mac_pin_missing` | refuse | The pinned commit is not in the repository. |
| `mac_pin_moved` | refuse | The tag no longer names the pinned commit. |
| `mac_build_failed` | refuse | `make build` failed or left no binary. |
| `mac_baseline_ungoverned` | refuse | A before run does not show Felix governing it: no PreToolUse block in the deny rollout, no `hook_prompt` in the stop or stdin rollout, or no spike commit in the stdin fixture. |
| `mac_install_failed` | refuse | `beacon endpoint install` failed, so the after runs would measure Felix alone. |

## What is still unchecked

- `mac-run.sh` ran end to end at `50f5ab09` (run 3). Run 3's three fixes (the trust fill-in
  text, the `mac_seed_untrusted` check, the `lsof` poll limited to this run) are not yet run on the
  Mac; the trust check reads `hookslist.py`'s line shape from run 3's report.
- Droid: no session was run, so Droid's real tool names, whether the Factory session id is the
  file name, and Beacon's Factory reader are untested. By the founder's decision of 2026-11-10 a
  Droid run comes before Droid's reader is decided. It is open, and it belongs with the Factory
  Droid adapter (direction row 19).
- Beacon's live OTLP path: no collector ran during the after runs.
- Beacon Intel's network behaviour and the hosted MCP.

**Open for the founder, unchanged:** may the Beacon binary (its offline readers only) run on a pilot
engineer's machine, or only on his own? The recommendation stays his own machine now, and native
readers that print the same Felix rows for the pilot.
