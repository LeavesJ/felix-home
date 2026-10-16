### 2026-10-01 to 10-02: a declared-capabilities list that could not be read is said as unknown by setup, maintenance, the stack plan, next, pulse and session start, never as dormant or owed

Stacked on claude/commission-lookup-fails-unknown (merged in at 8d508021). That
branch makes `_felix_cap_active` return 2 when the declared list could not be
read, and `felix_commission_state` reads 2 as unknown. This branch handles the
other callers. The plan had been to ride in slot 7 with lookup-fails. Then
lookup-fails' session ended, and the carrier carries that PR alone (slot 6,
0.49.244). This branch goes to the weekly batch, after lookup-fails is on main
(carrier ruling, 2026-10-02). No table under projects/ changes, and neither
does templates/commissioning.tsv.

**Defect closed.** Three callers asked `_felix_cap_active` with `!`, so its 2
read as "not active" and printed `dormant`. That is a valid state, and it looks
like a well-kept repository:
- `felix_setup_status` called a step that still needs a person "not needed
  yet";
- `felix_maint_status` called a routine that may be due dormant;
- `felix_stack_plan` called a row it never classified dormant.

`felix_maint_unreachable` read the list itself with `felix_has_line`, so an
unread list said "nothing declares" the capability. Session start put a
provider row whose answer state was `unknown`, or empty because the state call
failed, among the answers a session still owes. That sends a session to redo
an answer that may be whole (f7bed8's point 3).

**Now.**
- Each caller asks `_felix_cap_active` once and branches on 0, 1 or anything
  else. On 2:
  - setup prints `unknown` and does not run its check;
  - maintenance prints `unknown <name> - <cadence> <desc>` and neither runs
    the check nor reads the log;
  - the unreachable report adds a third column, `unknown`;
  - the stack plan prints `unknown` with a detail naming the capability.
- The CLI renders the new word in each place:
  - `felix setup` shows `[?]`, and `felix maintenance` shows `? not read`.
    Neither prints "Nothing outstanding." or "Nothing due." over an unknown
    row; each says how many could not be read instead.
  - `felix stack plan` and `felix stack apply` say how many rows could not be
    read. `apply --yes` installs nothing for those rows and exits 1.
- next.sh rank 6 says an unknown routine "could not be read" and never "nothing
  declares", including a routine on a built-in capability (ci, tests, ...).
  Unreachable passes over those, so before review they reached no rank, and
  `felix next` said "no upkeep is past its cadence" over them.
- pulse prints an `unknown <project> <names>` line beside `unchecked`.
- Session start keeps awaiting, stale and partial rows in the owed list. It
  says any other state on its own line at every start, and holds back the
  once-per-topology receipt line while such a row exists.

**Decided here, not asked.**
- *Maintenance due-ness.* An unread list makes no routine due. `due` drives
  session start's "Maintenance due", the stop hook's overnight list, next's
  rank 4 and pulse. A false due sends someone to work that may not apply.
  This follows the `unchecked` precedent: a row that could not be asked gets
  its own word.
- *Stack apply.* It installs nothing for a row it could not classify, and
  exits 1 so a caller can tell. The commissioning runner records that status
  in the row's detail.
- *Exit status.* `felix setup` and `felix maintenance` keep exiting 0. Their
  answer is in the text, as it is with todo or due rows.

**Shown red first.** A separate agent wrote 34 assertions blind, from the
contract, before the fix (7ef49f1c). Library assertions stub
`felix_declared() { return 128; }` in a subshell, after the libs are sourced,
over a capabilities file that does declare the capability. The CLI runs in
another process, so there the capabilities file is a link whose target is
gone. Session start runs from a scratch copy of the engine whose
`felix_commission_provider_state` answers unknown, awaiting, or nothing.
Against origin/main 27573cbe and the dependency head 2776521e, all 18
non-control assertions failed, and the 16 controls passed (the same rows over
a list that was read).

**Adversarial review** (two Opus reviewers: one asking whether a smaller design
would do and whether each assertion fails for the reason it names, one checking
readers and bash 3.2 traps). The mechanism held. The block passed under an
inherited tab IFS, set -u, the CLI's pipefail, empty or `always` capability
columns, and statuses 3 and 127. Of 25 mutants, 20 were caught.

Five mutants stayed green. Each now has an assertion, added after review and
not blind:
- setup counting unknown as todo;
- maintenance counting it as due;
- apply trying to install it;
- the plan counting it to install;
- session start spending the once-per-topology line over unread rows (caught
  only by the fixture check, and not at all when state/commission already
  exists, as it does in the full suite).

Also fixed after review:
- next.sh rank 6 now covers built-in capabilities. Its assertions use a
  routine on ci.
- `felix stack apply` without --yes now says how many rows could not be read.

Declined:
- folding the four case statements into a helper (optional, said the
  reviewer);
- the third mention of each unread routine in `felix maintenance`, which the
  contract asks for.

Eight mutants of the final fix, run with state/commission already present as
in the full suite. Each turns at least one assertion red, and the fix passes
43 of 43:
- due counting unknown (m5);
- todo counting unknown (m6);
- apply admitting unknown rows (m7);
- the plan's install count taking unknown (m7b);
- the all-clear no longer held back (m13d);
- rank 6's status loop dropped (mN), or its dedupe dropped (mN2);
- the no-`--yes` line dropped (mY).

Existing sections run against the fix and the dependency head gave the same
counts. Scheduled maintenance passed 13 of 13 on both, and stack plan 35 of 35.
The maintenance and pulse sections passed 69 of 73 on both. Their four failures
are graph and discovery-cache assertions that need fixture context the section
runner does not build.

**Gate.** Until the slot was called, no suite ran: under the carrier's rule
(2026-10-01) no suite runs before a session's slot, and load was 200 to 450.
One-block section runs were used instead, tests/run's preamble and this block,
in about a second each.

At the slot (2026-10-08, weekly batch, 0.49.275):
- This branch merged adopt-newline's gated head (dd68b3b8). The block alone
  then passed 43 of 43 on the merged engine.
- The record holds 6863 assertions, and 6855 pass, 0 fail, 8 skip. Its red is
  21 of 6863 against origin/main e2748140 at 0.49.274, all 21 this branch's
  own.
- main (#418 698825a5, #417 e2748140) was merged in with no engine file
  changed, and `felix gate` passed. An earlier gate on 6fe5f986 also passed,
  at the founder's direction ahead of the slot.

**Handed on, not done here:**
- The commissioning `stack` and `human_steps` checks, in every
  projects/*/commissioning.tsv and in the template, count only `install` and
  `todo`. Both still read done over unknown rows. Changing them changes a
  commissioning table, which needs the founder's re-stamp. That is f7bed8's
  separate founder-gated task.
- Seven direct `felix_declared` readers still read an unread list as empty:
  - `cmd_recommend`, and the `declared:` line;
  - `felix_undeclared`;
  - the probes gaps and orphans;
  - the discover rules;
  - the procedures facts;
  - the commission topology and request.

  Session "Make the other felix_declared readers say an unread list" has them,
  stacked after this branch.
- On a project whose list cannot be read, every row goes unknown together,
  because 2 depends on the project, not on the capability. Saying that once
  per project rather than per row would be quieter; it is a later design
  choice.
