## 0ao. Verified at session close, 2026-09-05 — the four high-severity audit findings are closed, and the manifest row says who grounded it

| | |
|---|---|
| head | `afe165f` on `main` (#170–#174, five merges), CI `gate` **success** on each |
| suite | **1534** passed, 0 failed, manifest re-recorded |
| deployed engine | **0.49.67**, deployed from the home checkout after each merge |
| the audit's high-severity four | **all closed** |

### What closed, and what each was

The measurement audit of 2026-09-04 left four high-severity findings. All four
are now fixed, each with assertions probed against the old behaviour to
confirm they fail there.

1. **#170 — a zero the ledger cannot see is not a zero.**
   `felix_ledger_signal` could name three shapes of thing, so a plugin
   contributing anything else was pinned to zero reaches *by construction* and
   could never leave the retire list. Three fixes: an `Agent` call records
   which agent (and the older `Task` spelling); the `plugin_<plugin>_<server>`
   MCP prefix joins to the plugin — **773 reaches across three projects** had
   been credited to a name no table contains; and a hook's zero is separated
   from a disuse zero into three shapes, `none` / `only` / `mixed`. Felix's
   retire list is now **empty**: it had no true positives.

2. **#172 — the manifest row carries who grounded it.** The founder's decision
   of this morning. `stack.tsv` gains a sixth column. See §"The grounding
   column" below, which is the standing description.

3. **#173 — the receipt says which checks the gate skipped.** `felix gate
   --quick` skips the suite and still exits 0, so its receipt was
   byte-identical to a full run's — one bit — and the Stop hook said "the gate
   is green, which means the suite passed" over it. The receipt has a fifth
   field naming what the gate *reported* skipping, read off the gate's own
   output rather than off this command's flags, so a project gate that skips
   for its own reasons is recorded too. Proven on the real repository: same
   tree, same green verdict, `-` versus `tests`.

4. **#174 — a state that means "not measured" is said.** `felix_ready_report`
   emits `undeclared` and `unknown`, both meaning not measured; `next.sh` kept
   only `absent|disabled` and dropped them, and an empty rank-3 list renders as
   "every tool a route names is reachable". `cmd_ready` gets this right on the
   same data, so the engine held both renderings and the wrong one was on the
   command that answers "what now". Elenchus really carries one: `felix next`
   now prints that `google-cloud-storage` is named by a route and declared
   nowhere.

### The grounding column — standing, do not re-derive

`stack.tsv` has a sixth column, `grounding`.

* `DECLARED` — a person's judgment. Written by `felix new`'s seed and `felix
  adopt`'s backfill, because a catalogue tier was decided by somebody and the
  engine writing it down does not make it the engine's.
* `OBSERVED` — what the engine read off a plugin it fetched at a pinned sha.
  Written by `discover --adopt` and by `felix_commission_apply_declares`.
* **Absent means `DECLARED`.** That is the compatibility promise every
  manifest written before the column relies on, and it is asserted directly.

`felix_stack_plan` and `ready --fix` read it and hand it to `felix_admit`,
which holds an `OBSERVED` medium where it installs a `DECLARED` one. **Every
reader of a manifest row must take the column** — a trailing `read` variable
absorbs the last field *and its tab*, which is exactly how `cmd_profile` and
`lib/monitor.sh` broke in the first draft.

**Known and deliberate:** no writer can produce an `OBSERVED` medium today.
The admit phase emits `declare` only from the policy's `install` arm, and
`medium`+`OBSERVED` is `hold`, so every row it writes is `low` — where both
groundings give the same answer. The asymmetry is reachable by `discover
--adopt`'s tiering and by a person editing a row, not by the admit path.

### The method that is now load-bearing

Every substantive change this session was put through an adversarial review
before merge — four lenses over the diff, three refuters per finding — and
**two of the three reviews found a regression in the change under review**:

* the ledger catch-up folded every project's sessions into whichever asked;
* the hook classifier made "ships a hook" one bit and mislabelled a plugin
  shipping a hook *and* countable surfaces;
* the grounding column broke `felix profile` for every row the engine writes.

All three are the same shape: **correct logic applied too narrowly.** The
reviews cost real money and have paid for themselves three times. Full
write-ups: `~/.felix/memory/felix/audits/2026-09-04-measurement-audit.md`.

### Not done, in order

1. The grounding review's remaining low findings, none of them urgent: the
   provider-row kind filter accepts a kind containing a space (`case " $KINDS "
   in *" $kind "*` matches `plugin mcp`); `ready --fix`'s `head -1` grep can
   take the grounding off a row other than the one naming the tool; a
   catalogue row hand-copied into `stack.tsv` carries `keywords` in column six
   and is refused forever (fails closed, but says so only in the plan's detail
   column); a failed `stack.tsv` append is silent.
2. **PR 4 needs re-aiming before it is built, because its premise is stale.**
   The conformance amendments §1.3 say "Unbuilt and required: nothing schedules
   discovery. The pulse command reports staleness and refreshes nothing. A
   founder-granted schedule is the missing piece." **That is no longer true.**
   `felix_discover_refresh_bg` exists, is wired into the session-start hook,
   runs detached under a lock directory when `felix_discover_stale` says so,
   writes to a temp and renames — which is exactly the shape §1.3 prescribes.

   Verified behaviourally, not by reading: the cache's stamp line was removed
   to force staleness, the hook was run, and the cache came back rewritten with
   a current stamp. Two further hook runs did **not** refresh it again, so it
   settles rather than fetching every session.

   What is genuinely still unbuilt is the other half: an autonomy grant for
   unattended **commissioning**, which is a different and much sharper thing,
   because commissioning installs and discovery does not. `autonomy.sh` calls
   the existing `tidy` grant "the sharpest trust boundary in the system" for
   merely deleting a stray file. Building the sharpest-boundary feature on a
   premise the governing document gets wrong is not something to do
   unsupervised, so it is reported here instead. The founder re-aims it.

   One caution for whoever does: a hand-rolled subshell sourcing
   `lib/discover.sh` computes a different stamp than the hook or the CLI does,
   because `_felix_discover_stamp` resolves its inputs from `BASH_SOURCE`.
   Three subshell invocations gave three different answers, none matching what
   the CLI writes, and that reads convincingly as a permanently stale cache.
   It is not one. Test the behaviour, not the function.
3. `commission-provider.sh` reads the installed registry with the leaky awk
   shape #170 replaced in `ledger.sh` — same fault, not yet fixed there.

