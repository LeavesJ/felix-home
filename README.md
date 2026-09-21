# Felix

Felix is a Claude Code plugin, written in bash, that decides when an agent's
work is done without taking the agent's word for it. When a session that
changed the code tries to stop, Felix holds it unless a gate has passed on
that exact tree. A pass stops counting when the tree moves, or when anything
the project declared the pass rests on moves.

The obvious alternative is a twenty-line Stop hook that runs the tests. Felix
differs in three ways:

- It records which tree passed, so a pass is neither re-earned nor assumed.
- It notices when something outside the tree that the pass relied on has
  changed.
- It treats "could not check" as a failure, never as a pass.

Around that sit rules for who may grant an exception, what a merge may do
without a person, and which tools may be trusted.

It exists because of a question that gets sharper as models get better. When
an agent does most of the engineering, and one instruction turns into dozens
of model turns and tool calls, a person can no longer watch each action. So
something else has to hold the answers to: what has actually been proven, and
against which state of the code? What is still unknown? Who may grant an
exception, and who may change the rules the agent is judged by? A smarter
model does not answer those questions. Felix is one founder's working attempt
at that layer. It is used every day on the founder's own projects and is still
well short of what it is designed to be.

## What it looks like

The agent finishes, reports success, and tries to stop. Felix answers from the
state of the tree, not from the report:

```
The gate last ran at 2026-09-19T20:37:10Z, on a different tree. It has not seen this work.

Do not describe this work as complete until it has passed.

  felix gate

If you have already decided to stop with a red gate, that is the founder's call
to make, not yours: they can set FELIX_ALLOW_RED=1 in the environment they
launch a session from. If the red is one TASK_BLOCKING obligation, the narrower
way past it is a row in the project's exceptions.tsv, keyed to that obligation
and dated, merged by a person; a session cannot grant itself one.
```

The agent runs `felix gate`. The gate is the project's own shell command
(`npm run verify`, `cargo test`, `make check`), plus Felix's checks. The result
is written down as a receipt for this tree, and after a pass the next stop goes
through without a hold. ("The founder" in the message means whoever owns the
project.)

A receipt can also go stale when the tree has not changed at all:

```
The gate passed on this exact tree at 2026-09-18T22:12:29Z, but the grounded
facts moved since the receipt.
```

Here a fact that one of the project's probes reads has changed since the pass,
such as a tool's version, a count or a deployed route. The message says which
kind of input moved, not which fact.

## Words used here

- **Gate**: the command that proves a project correct, declared per project.
- **Receipt**: the record of a gate's last result, green or red, bound to a
  tree and an epoch.
- **Tree id**: HEAD, the full diff against it, and the names, sizes and mtimes
  of untracked files.
- **Probe**: a command a project declares to read one fact, such as a tool's
  version or whether a route is deployed.
- **Epoch**: a hash of what a verdict rests on besides the tree. That covers
  the facts the probes read, the project's policy tables, which project it
  is, and the branch it targets.
- **Obligation**: something a project must satisfy before it ships. It has a
  command that says whether it applies and a command that says whether it is
  met. A blocking obligation fails the gate until it is met.
- **Home**: where each project's rules live. That includes its constitution
  (a CLAUDE.md of standing rules), its gate, and its tables of risks, refusals
  and obligations. The home sits outside every governed repository except
  Felix's own, because a gate stored in the tree it judges can be edited by
  the change it is judging.

## What it does today

**A green receipt for this exact tree is what lets a session stop.** The Stop
hook compares the current tree id with the last receipt and never reads what
the agent said ([stop](engine/harness/hooks/stop)). A commit does not get round
it.

**A green goes stale when what it rested on moves, not only when the diff
does.** Invalidating an approval when the diff changes is standard. Felix
also invalidates on inputs outside the tree. It says which kind moved: the
probed facts, the policy tables, the project or the target branch
([verify.sh](engine/harness/lib/verify.sh), [epoch.sh](engine/harness/lib/epoch.sh)).

**"Cannot tell" blocks. It never passes.** An obligation's "does this apply"
command may be missing (127), unable to enter the checkout (126), or exit with
anything but yes or no. Any of those makes it UNKNOWN, and on a blocking
obligation UNKNOWN fails the gate just as a failed check does. State is
recomputed from exit codes on every run and never stored. Until 2026-09-16, a
crashing `applies` command quietly retired a blocking obligation instead. The
comment recording that is still in
[obligations.sh](engine/harness/lib/obligations.sh).

**An exception is meant to be a person's act, not the agent's.** An exception
is a person's dated row that clears one obligation. Felix reads it only from
`refs/remotes/origin/main`, never from the working tree or a local branch
([exceptions.sh](engine/harness/lib/exceptions.sh)). This works only on
Felix's own repository so far. There, deny rows refuse the commands a session
would use to move that ref. Without branch protection, though, a session that
merges its own pull request with `gh pr merge` can still grant itself one.
See "Floor and wall".

**Felix's changes to itself are judged by the Felix on main.** `felix merge`
judges a change to the engine with the engine that `main` declares. It refuses
any judge that is not byte-identical to main's copy. The code says plainly
that this "is not a signature" ([resolve.sh](engine/harness/lib/resolve.sh)).
This came from an observed failure: one day, nine engine changes in a row were
each deployed before being judged, so each candidate judged itself.

**Some changes always go to a person.** A change's risk tier only advises.
What stops a merge is an escape, named by what a revert cannot undo.
`felix merge` hands these to a person:

- a credential in the added lines;
- workflow changes, since workflows run with the repository's secrets;
- a change to the autonomy grant or the exception table;
- migrations or destructive SQL;
- any change that removes rows from an enforcing table.

A project can add its own escapes. Felix does this for a gate or suite that
loses checks ([escape.sh](engine/harness/lib/escape.sh)). When Felix governs
itself, the risk table is read at both base and head, and the stricter wins
([classify.sh](engine/harness/lib/classify.sh)).

**A declared check has to be shown to fail.** A project can list checkers in
`qualification.tsv`. For each one, `felix qualify` plants six mutations of the
thing the checker protects, and requires the checker to fail or pass as each
mutation demands. The gate fails on any unmet control. A checker with no rows
is not held to this. New engine tests are also run against the previous
engine, and the ones that fail there are kept in
[red.tsv](engine/harness/tests/red.tsv).

**Tools Felix finds on its own are read before they are trusted.**
`felix discover` fetches a plugin at its pinned commit and reads it without
running anything. Hooks, a floating version or an interpolated secret score it
high, and nothing installs high. In its own words it "catches carelessness,
not an attacker" ([discover.sh](engine/harness/lib/discover.sh)). A tool a
model merely suggested never installs
([admit.sh](engine/harness/lib/admit.sh)). Rows in the catalogue install at the
risk tier a person wrote for them.

**Use is counted apart from recommendation.** The ledger records which tools a
session was pointed at separately from which it used. So a tool Felix never
mentioned is not scored as a tool nobody needs. Retirement is a printed
proposal, never an act ([ledger.sh](engine/harness/lib/ledger.sh)).

Felix's own code on the deciding path is bash, git and the POSIX userland. It
calls no model, no network and no key. It also runs the project's own gate and
probe commands, which do whatever the project wrote.

## Floor and wall

Felix's hooks run inside the agent's session, so they are a floor, not a wall.
They stop a careless agent. A hostile one could get past them.

- **The Stop hook holds a session once per stop attempt.** If the agent tries
  again it goes through, and the hold stays on record. The hook calls itself
  "a speed bump with a permanent record, not an inescapable barrier".
- **Refusals in a project's `deny.tsv` fail open.** A command spelled in a way
  no row matches gets through.
- **Receipts are plain files in the home.** Any process running as you can
  write one.
- **`felix merge` runs on your machine.** `gh pr merge` skips it.

The wall is a check the agent cannot write to. It takes three things:

- a required CI check that re-runs `felix gate` on the pushed tree;
- a branch that admins cannot bypass;
- a judge fetched from a repository the agent cannot push to.

`felix bootstrap` writes a workflow that checks Felix out from its own
repository, separate from the project it judges. It leaves admin bypass on,
so the branch rule is yours to tighten. Whether a given repository has the
whole wall is a fact about that repository, so check yours. Felix's own
development repository does not have it yet.

The honest summary: Felix writes the rules and the judge, and records every
hold, denial and escalation. Where the whole wall is in place, it holds
against an agent that ignores it. Everywhere else it holds against an agent
that forgets.

## What was measured, and what was dropped

Felix measures itself and keeps the negative results.

- **Its tool routing was mostly wrong.** Felix used to point sessions at the
  skill or plugin it thought each prompt needed, turn after turn.
    - A blind study of 158 real prompts put that advice at about 2% precision.
      A tool actually applied on only 8 of those prompts, so treat the number
      as a direction, not a measurement.
    - Over five days the advice was followed 2 times out of 11. All three
      mandates audited live were wrong for their turn, so ignoring them was
      correct.
    - Felix now names a tool only on a session's first routed turn and when
      that route's next step comes due. When it does not fit, Felix asks for a
      recorded decline. Otherwise the choice is left to the session's model.
- **The part that worked was the Stop hold.** In the same period it held 17
  times, and every hold that was audited was correct.
- **A move off bash was dropped on evidence.** The proposal was to move the
  engine's record-keeping into a typed language. Every one of 159 recorded
  lessons was classified by cause. 36 were strictly caused by the language,
  and a typed kernel would have prevented 26 of those. That was not enough to
  justify the move, so the engine stays in bash, and a table validator comes
  first.

Interesting is not proven. Nothing yet shows that governed sessions produce
fewer defects than ungoverned ones. The planned demonstration is one
obligation's whole life, replayable offline with no model. It would show the
mechanism working end to end, not that comparison, and it is not built.

## Which parts should outlive better models

[Every part of a harness encodes an assumption about what the model cannot
do](https://www.anthropic.com/engineering/harness-design-long-running-apps),
and those assumptions go stale. Felix applies that test to itself: if the
model were ten times better tomorrow, would this part still need to exist?

- **Expected to outlast better models**: the rules and the judge.
    - receipts bound to a tree and an epoch
    - UNKNOWN blocking
    - exceptions only a person can make effective
    - the merge escapes
    - checks that must be shown to fail
    - tools read before they are trusted
    - the record of what was refused and why
- **Expected to die**: the parts that compensate for today's models.
    - keyword routing of prompts to tools (already measured and demoted)
    - lessons matched to prompts by keyword
    - reminders to read the handoff or verify before claiming done
    - notes injected into subagents
- **Temporary in a different way**: where the durable parts run. Today they all
  run on the agent's own machine, either as hooks inside the Claude Code
  session or as commands that session runs. They need to move to where the
  agent cannot reach them.

The first list is argued, not measured. None of it has yet been tested against
a capable worker trying to get round it.

## Status

- **In daily use, on the founder's projects**:
    - the Stop hold, receipts and epochs;
    - the merge escapes;
    - obligations with UNKNOWN blocking;
    - project setup, which Felix calls commissioning;
    - the refusal table;
    - checker qualification (on Felix's own checks);
    - plugin discovery;
    - the ledger.
- **Built, never used on real input**:
    - exceptions (none has been granted);
    - obligations proposed by a model (the request has never produced an
      answer);
    - the unattended repair workflow (a template, switched off).
- **Partial**:
    - Pinning the judge to main covers `felix merge` only; `felix gate` still
      loads the branch's own code.
    - Auto-merge keys on a CI streak rather than on obligations, and has no
      post-deploy check or rollback.
    - A receipt covers a whole gate run, not each claim.
    - The epoch depends on which `git` is on PATH, so the same tree can read
      stale in another environment.
- **Designed, not built**:
    - `felix dispatch`, which runs a worker as a restricted, headless session
      and records what it did;
    - installing a new engine only after it is accepted.
- **Absent**:
    - sandboxing;
    - time-limited grants of tools and their revocation;
    - deciding how deep to search for missing obligations, and when to stop;
    - support for any host but Claude Code.

## Try it safely

What installing changes:

- **The plugin loads in every Claude Code session on the machine**, and records
  which tools each session calls.
- **In a governed project it also**:
    - logs the start of each prompt to the project's memory directory;
    - clones candidate plugins once a week to read them;
    - adds catalogue rows for tools it detects in the checkout.
- **`felix install` may bump the patch version in
  `engine/.claude-plugin/plugin.json`.**
- **Governing a project installs plugins at user scope** (see below).
- **Nothing merges on its own.** `felix merge` and `felix automerge` run only
  when invoked.

To look without committing:

1. Point `HOME` at a scratch directory for every command. You will need to
   sign in to `claude` there.
2. Skip the `/usr/local/bin` symlink.
3. Govern a scratch repository.

Setting `FELIX_HOME` and `FELIX_MEMORY` moves doctrine and memory. It does not
contain the side effects: the plugin and anything commissioning installs still
land in your user scope.

## Install

Requires bash 3.2 or later, git, the POSIX userland and the `claude` CLI. `gh`
is needed for `brief`, `pr`, `merge`, `automerge`, `repair`, `bootstrap`,
`unattended`, `classify --apply` and `incident --create`. Commissioning and
discovery use the network. `felix pulse --install` is macOS only.

```bash
git clone https://github.com/LeavesJ/Felix.git felix
felix/engine/harness/felix install
ln -s "$PWD/felix/engine/harness/felix" /usr/local/bin/felix
```

`felix install` does three things:

- registers the checkout as a local plugin marketplace;
- installs the plugin at user scope;
- checks that what Claude Code deployed matches the tree.

Claude Code caches plugins by version, so a changed engine at an unchanged
version would otherwise fail to deploy while reporting success. On drift,
install bumps the patch version and redeploys (`--no-bump` turns that off).

A clone that ships `projects/` becomes the home itself, and is governed as the
project `felix`. Install from a main checkout, never a git worktree: installing
from a worktree points the marketplace at the worktree.

## Govern a project

```bash
cd your-project
felix new your-project
```

This does three things:

- It writes `projects/your-project/` in the home, a memory directory under
  `~/.felix/memory`, and a `.felix` marker in the checkout.
- It guesses a gate.
- It commissions the project. This uses the network and registers
  Anthropic's official plugin marketplace. It then installs, at user scope:
    - the catalogue's low-risk plugins for every project, currently
      superpowers, claude-md-management, claude-code-setup, context7,
      code-review, security-guidance and code-simplifier;
    - the catalogue rows that match what it detects in the checkout;
    - any low-risk plugin that discovery has read and matched.

High-risk rows, such as semgrep, are held for a person. There is no flag to
skip commissioning yet.

If the guessed gate is empty, set `gate` in `project.json` to any shell
command that proves the project correct. A checkout binds to a project by its
`.felix` marker, or by `remote_match` in `project.json`.

Run `felix` with no arguments for every command, grouped. Inside Claude Code,
`/felix` is the place to start.

## What happens in a session

[hooks.json](engine/hooks/hooks.json) binds eight events:

| Event | What Felix does |
|---|---|
| Session start | Names the constitution and handoff to read and reports due upkeep. Records tools the checkout has grown, by adding their catalogue rows to the project's tables, without installing anything. Refreshes discovery weekly in the background |
| Prompt | Mounts recorded lessons that match the prompt, and names a tool on the first routed turn. Logs the first 160 characters of each prompt, and up to 200 beside anything Felix says in reply, to the project's memory directory, outside the repository |
| Before a tool call | Refuses what the project's `deny.tsv` names, with the reason. A new project has no rows, so nothing is refused until you write some |
| After a tool call | Appends one ledger line. Async, never blocks |
| Subagent start | Tells the subagent the project, its constitution and its gate |
| Subagent stop | Once per session, if the checkout holds changes no gate has passed, tells the parent that a subagent's report must call its own changes unverified |
| Session end | Folds the session into the ledger, with a zero for every declared tool never used |
| Stop | Holds the stop attempt unless a receipt for this exact tree is green and its epoch holds |

Four other events are declined, each with its reason, in
[lifecycle.tsv](engine/harness/templates/lifecycle.tsv).

## Verify

```bash
felix gate                  # this project's gate, recorded as a receipt
engine/harness/tests/run    # the engine's own suite
```

The suite drives the real CLI and hooks against an invented project in a
throwaway root. It has about 2,400 assertions, and it fails if any assertion
in its manifest was never reached.

## Uninstall

`felix install --uninstall` removes the plugin and nothing else, because Felix
never deletes doctrine or memory. The rest is by hand:

- `felix pulse --uninstall`, if you installed the schedule;
- `claude plugin uninstall` for each plugin commissioning added that you did
  not already have;
- `claude plugin marketplace remove felix`, and
  `claude plugin marketplace remove claude-plugins-official` if commissioning
  added it;
- delete `~/.felix-home`, the PATH symlink, and each repository's `.felix`
  marker;
- optionally delete `~/.felix` (memory) and the home's `projects/` and
  `state/`.

## Where it is going

The adopted direction is an autonomous engineering control plane in two
halves:

- **Capability**: what engineering a project needs, who can provide it, how
  well it did, and when to retire it.
- **Trust**: what is known and unknown, what was proven against which
  revision, and who may release.

The person states intent and makes the decisions that are genuinely theirs.
Workers do the engineering in narrow, disposable sessions. Felix decides what
counts as done.

The control plane's first piece will be `felix dispatch`, queued behind the
table validator and two engine fixes. It gives one worker per lease, launched
with only the tools its task needs, and its record is the handoff. The shape
is not tied to Claude, although the first version launches Claude Code
headless. The bet is on models getting better, not on them staying weak. The
layer that decides what counts as done should become more necessary, not
less, as the workers improve.

Two things here are not new. Binding a verdict to a commit is also done by
AI-SDLC, which commits SHA-bound attestations into the repository. Governing
several agent vendors from one place is also done by GitHub's Agent HQ.

Apache-2.0.
