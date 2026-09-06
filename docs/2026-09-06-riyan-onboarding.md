# Elenchus: onboarding

For Riyan, 2026-09-06. This is the document to read first and to keep open for
the first week. It takes you from a machine with nothing on it to a green gate
and a pushed commit, and then tells you the five things that will otherwise cost
you a day each.

Everything here was verified against the two repositories rather than
remembered. Where a claim is about a file you have not received yet it says so.

---

## 1. What you are taking over

**Elenchus runs the case method on a business decision the user is actually
facing.** They describe a decision, it forges an unlabeled scenario around it,
and then it cross examines them. It never hands the answer, never names the move
they are missing, and never agrees to soften. What gets scored is how they
reasoned, never what they concluded.

The one line that explains most design decisions: **rent capability, gate
doctrine.** The model is rented through the Anthropic API and is one config site
in `model.py`. The loop, the gates, the maps, the rubrics and the territories are
ours, versioned on disk under `content/`, and are never handed to the model as
taste.

Status is a closed beta, one invited person per instance, from 2026-09-05. J
operates the beta and you do not. That boundary is deliberate and §7 explains
it.

Python 3.14, `src/` layout, FastAPI, SQLite, a vendored Three.js renderer. No
orchestration framework and no vector database. Thin is the architecture, not a
stage the project is passing through.

## 2. What Felix is, and why it is talking to you

Felix is J's engineering governance layer. It is a Claude Code plugin that binds
each session to the project it woke up in, tells that session where the gate is,
and holds the project's constitution.

The thing to understand on day one is that **Elenchus's doctrine does not live
in Elenchus.** It lives in Felix at `projects/elenchus/CLAUDE.md`, along with the
gate script, the risk rules, the routes and the evidence requirements. The
Elenchus repository is deliberately thin: `.github/workflows/gate.yml` says so in
its own header comment, "The gate itself lives in the private Felix repo, not
here."

So Felix is not optional tooling. Without it you cannot run the gate that `main`
requires.

You are getting the Felix engine and the one project directory that governs
Elenchus. You are not getting the rest of the Felix repository, and you do not
need it.

---

## 3. Day one

Roughly ninety minutes if nothing surprises you. Do the steps in order, and stop
at each verify line rather than reading ahead.

### 3.1 Elenchus

```
git clone https://github.com/LeavesJ/Elenchus.git
cd Elenchus
python3.14 -m venv .venv
.venv/bin/pip install -e ".[dev,web]"
```

Match 3.14 rather than the 3.12 floor in `pyproject.toml`. CI pins 3.14
(`.github/workflows/gate.yml`, `python-version: '3.14'`), and the whole
`PYTHONPATH=src` rule below exists because of a 3.14 specific problem.

**That `pip install -e` line installs dependencies and nothing else.** Do not
rely on `import elenchus` working through the editable install. Setuptools
editable mode is unreliable on this Python and the project's lesson L-19 records
it. Everything runs with `PYTHONPATH=src`.

Now run the suite:

```
PYTHONPATH=src .venv/bin/pytest -q
```

**Verify:** roughly `1439 passed, 35 skipped`. The suite is fully offline against
a scripted fake model, so this needs no API key and costs nothing. Four of the
skips need a corpus that is not in the repository, and the rest are the `@live`
tests that skip without a key.

If this fails on imports you skipped the `PYTHONPATH=src` part.

### 3.2 Felix

You will receive a private repository URL from J. Clone it somewhere permanent,
not in `/tmp`, because it becomes your Felix home.

```
git clone <felix-dist-url> ~/felix
cd ~/felix
./engine/harness/felix install --home ~/felix
```

`felix install` does four things: it writes `~/.felix-home` pointing at your
clone, registers the marketplace, installs the plugin, and then verifies that
the installed engine actually matches the tree. That last step matters more than
it sounds, and §6 explains why.

**Verify:** the output ends with `verified   the installed engine matches this
tree`. If it says anything else, read what it says rather than re-running it.
The command is unusually good at explaining its own failures.

Then, from inside your Elenchus checkout:

```
cd ~/Elenchus
~/felix/engine/harness/felix which
```

**Verify:** it names `elenchus`. If it says no project governs this directory,
your home is wrong. Felix resolves the home in this order: the `FELIX_HOME`
environment variable, then the `~/.felix-home` pointer file, then a checkout
carrying `projects/` beside the engine, then `~/.felix`. Re-run
`felix install --home ~/felix`.

Start a new Claude Code session in the Elenchus directory. You should see a
`Felix: elenchus` line. Hooks bind at session start, so a session you already
had open will not pick this up.

### 3.3 The bundle

J sends you an encrypted archive. Nothing in it is in either repository and
nothing in it is ever committed.

| From the bundle | Goes to | Never |
|---|---|---|
| `docs/` | `<Elenchus>/docs/` | staged, ever |
| `POSITIONING.md` | `<Elenchus>/POSITIONING.md` | staged, ever |
| `scenarios.yaml`, `candidates.yaml` | `<Elenchus>/content/lift/` | staged, ever |
| `NOTES.md` | wherever you keep notes | staged, ever |

All four destinations are already covered by `.gitignore`, so this is safe by
construction rather than by your memory. `/docs/` is line 6, `/*.md` is line 2,
and the two lift banks are lines 19 and 20. The gate has a check whose only job
is to fail if either lift bank ever becomes tracked
(`projects/elenchus/gate.sh:175`).

Read `docs/lessons.md` when you first touch a surface it covers. It is a runbook
and not a gate, it is long, and it is mostly historical. The parts that still
bind are restated as Invariants in the constitution.

That file is worth more than its status suggests. Tracked code cites **27
distinct lesson identifiers a total of 252 times**, in the form `L-19`, `L-23`
and so on, scattered through `src/`, `tests/`, `scripts/` and the Felix project
directory. Every one of those comments points at a file that is not in the
repository. When you hit an `L-nn` reference and want to know why a piece of
code is shaped the way it is, that is where the answer is.

Two of the bundle's files are narrower than they look. `content/lift/scenarios.yaml`
and `candidates.yaml` are needed for lift and mining work only: the loaders at
`src/elenchus/content_loader.py:259` and `:264` default to those names, but no
tracked caller uses the defaults, and the suite is green without them. If a
`data/injection_payloads.yaml` is in your bundle, it is the corpus for
`run_injection_probe.py` and the tests use the tracked
`content/gate/injection_payloads.example.yaml` stub instead.

### 3.4 Your Anthropic key

J issues you your own key on your own workspace with your own spend limit. It is
not his key and you should never be handed his.

You need it only for the web app and the `@live` suite. The offline suite, which
is what you will run a hundred times a day, needs nothing.

Two places it can live, and the launcher checks them in this order:

1. `<Elenchus>/.env`, which is gitignored at line 23.
2. `~/.config/elenchus/env`, which is what `DEFAULT_ENV_FILE` points at
   (`scripts/serve_invitee.py:39`).

The second exists because on J's machine the repository sits inside the macOS
Desktop and Documents sync container, so a key at `<repo>/.env` replicates to
Apple and to every device on the Apple ID. If your checkout is not inside a sync
folder, `.env` is fine. If it is, use the second location and put the file at
mode 600.

The file is `KEY=value` lines, an optional `export ` prefix, optional quotes, and
`#` comments. `ANTHROPIC_API_KEY` is the only one you need.
`src/elenchus/web/__main__.py:41` loads `<repo>/.env` at import with `setdefault`,
so a real exported variable always wins over the file.

**One warning before you run the web app locally.** The launcher
`scripts/serve_invitee.py` refuses to start without a reachable key and arms the
spend ceiling by default (`serve_invitee.py:163`). The direct entrypoint,
`python -m elenchus.web`, does neither. It performs no key check, so a keyless
instance health checks green and dies at the first learner turn, and
`from_env` returns `None` for unbounded when `ELENCHUS_MAX_CALLS` is unset
(`src/elenchus/spend.py:54`). With a real key and no ceiling, a loop on your own
machine spends until you notice. Set `ELENCHUS_MAX_CALLS` when you run the app
directly.

### 3.5 The first green gate

This is the finish line for day one.

```
cd ~/Elenchus
~/felix/engine/harness/felix gate
```

**Verify:** the last line reads `gate: pass`.

**Run it through `felix gate`, never as `./scripts/gate.sh`.** This is not
style. The `secret` check only runs when `$FELIX_BIN` is set, which happens when
Felix invokes the gate and not when you run the script directly
(`projects/elenchus/gate.sh:162`). Run it directly and that check prints
`skipped` and you have a seven check gate wearing an eight check name. A session
did exactly this and reported green all day. There is a `deny.tsv` rule that
blocks the direct invocation for precisely this reason, so Felix will stop you,
and now you know why.

---

## 4. The eight checks, and what each one means when it fails

From `projects/elenchus/gate.sh`. Read once now, and you will recognize every
failure later.

| Check | Fails when |
|---|---|
| `format` | ruff would rewrite a file. It rewrites, then names what it touched. Review and stage those. |
| `lint` | `ruff check` fails. The rule set is pinned to `E4, E7, E9, F` on purpose. |
| `test` | the offline suite is red. Note the summary line: it prints skips too, deliberately. |
| `confidential` | a tracked path matches `docs/`, `.claude`, `.pdf`, or one of several internal document names. `git rm -r --cached <path>` to untrack. |
| `secret` | Felix's scanner found a credential in added lines. See §3.5 on why this can silently skip. |
| `lift-bank` | either real lift bank got tracked. Only the `*.example.yaml` stubs belong in git. |
| `ignore-leak` | `.gitignore` names a confidential file. Naming it leaks what it hides. Those names go in `.git/info/exclude`, which is local only. |
| `inversion` | the tree is dirty. This one prints `dirty` rather than failing. Fine mid task, not fine when you claim done. |

`inversion` is the only one that is advisory. The other seven decide the exit
code.

Below the eight, Felix prints two more lines that are not gate checks and do not
decide the verdict. On a fresh machine expect `probes` to report one blind
`http_route`, and `commission` to say "never commissioned on this machine". Both
are first-run states. A green gate still reads `gate: pass`.

---

## 5. Doctrine, in the order it will bite you

`projects/elenchus/CLAUDE.md` in your Felix clone is the constitution and it is
232 lines. Read all of it before your second commit. What follows is what you
need before your first.

### Default: act

You have standing authority over Elenchus. Attempt first, report after. Out of
scope is not a reason to decline: attempt it and label the confidence. Do not ask
permission for reversible work and do not narrate what you are about to do.

There is no mandatory reading ritual.

### Claims are pinned to evidence

Every statement about the codebase cites a `file:line` you read or a command
whose output you saw. Never infer that a symbol exists from a doc, a filename or
a prior session. Grep it. The constitution's own previous version named a
`core.py` that has never existed.

Label confidence as one of three: **verified** (ran it, read the output),
**read** (read the code, did not run it), **assumed** (neither, and here is what
would falsify it).

"Wired", "green" and "should work" are claims. A green test over a hand built
fixture that no production path can emit is a lie with a checkmark on it.

### Tiers

Declare the tier in one line before you start, then run that tier's gate.
Escalate freely, never downgrade silently.

- **T0 direct.** Reversible, one module, no behavior or interface change. Run
  `felix gate`, then ship.
- **T1 checked.** Behavior changes, or the diff crosses a module boundary. T0
  plus naming the failure classes for that surface and checking each. A return
  type change updates every caller in the same commit, so grep `tests/` for the
  symbol and treat a hit inside a `@live` file as a real caller.
- **T2 adversarial.** A canonical interface, durable state, or a doctrine
  surface: `types.py`, `persistence.py`, `orchestration.py`,
  `assessment/judgment_loop.py`, the `content/` schemas, and anything a learner
  sees. T1 plus an independent reviewer in an isolated worktree at the reviewed
  commit.
- **T3 stop and ask J.** The full list is in the constitution. In practice:
  changing the meaning of a stable identifier, migrating durable state, anything
  touching secrets or `.env*` or the tracked set of the public repo, force push
  or history rewrite, and any case where your better design conflicts with an
  explicit instruction from J.

### The invariants worth memorizing on day one

Ten are listed in the constitution. These three are the ones a well meant change
breaks by accident.

1. **Doctrine is data.** Maps and rubrics live in `content/`, never in `src/`,
   and the model never holds the doctrine.
2. **No learner-facing surface names a frame or a move, in any medium.** Naming
   the frame passes the conclusion-agnostic check and still corrupts the
   unprompted signal, which is the whole measurement.
3. **The unlabeled problem is the moat.** If recognizing the type and running a
   procedure solves it, it is homework in a costume and does not ship.

### Delivery

- Unified diff against current files, never a rewritten file.
- Never invent a path or a symbol. Grep first. Missing context becomes a
  `TODO(assumption):` inside the patch.
- Stage explicit paths. Never `git add -A`, never `git add .`, never `-f` on an
  ignored file. Felix's `deny.tsv` enforces all three.
- Run the suite and `git commit` as one gated chain. A piped `pytest | tail`
  masks the exit status and commits a red tree. This is lesson L-23.
- A `docs/DEVLOG.md` entry rides in the same change. A change without one did
  not happen.
- **No `Co-Authored-By` trailer** in an Elenchus commit.
- No em dashes in prose.

---

## 6. The five traps

Each of these has already cost real time. They are in order of how likely you
are to hit them.

**1. The editable install.** Setuptools editable mode is unreliable on the 3.14
venv, so `import elenchus` may resolve to something stale or to nothing.
`PYTHONPATH=src` does not depend on it at all, which is why the rule is absolute
rather than a preference. Lesson L-19.

**2. Running the gate script directly.** Covered in §3.5. It silently drops the
`secret` check.

**3. A piped pytest.** `pytest -q | tail` gives you the exit status of `tail`,
which is always zero. Every command in the gate writes to a log and branches on
the captured status for this reason. Lesson L-23.

**4. `@live` tests rotting silently.** The gate never runs them, because they
cost money and need a key. So a signature change breaks them and nothing tells
you until someone runs `pytest -m live` weeks later. Eight test files carry
`@live` callers. When you change a signature, grep `tests/` for the symbol
including those files. Lesson L-22.

**5. Hooks bind at session start.** If Felix changes, or you re-run
`felix install`, the session you are sitting in keeps running the engine it
loaded when it started. Check the `Felix:` line in the session start banner
before concluding a Felix change is live for you. It is live for the *next*
session, which is a much weaker claim.

There is a sixth that is not yet your problem but is worth knowing the shape of.
When code is correct and does nothing, the cause is almost always *where* it was
installed rather than *what* it says. That failure has happened four times in
Felix's short life and the tell is always CI and local disagreeing. Treat that
disagreement as a finding and not as flakiness.

---

## 7. What you do not have, and why

Not a matter of trust. Each of these is a boundary with a specific reason.

- **Beta invitee data.** `~/.local/share/elenchus/data/tenants/*` on J's machine
  holds what real invited people wrote about real decisions they are facing.
  They agreed to J seeing it. Your `data/` starts empty and that is the correct
  state.
- **J's own `data/elenchus.db`.** Nineteen of his own sittings. The code
  describes this file as holding "one particular person's decisions"
  (`src/elenchus/web/runtime.py:54`) and refuses to serve it on a non-loopback
  address for exactly that reason.
- **Cloudflare credentials and the invite domain.** These authorize DNS on J's
  domain.
- **His Anthropic key.** You have your own, with its own spend limit, so a leak
  from either machine does not burn the other and so spend stays attributable.
- **The rest of the Felix repository.** `HANDOFF.md`, `projects/veldra/`,
  `projects/felix/`. Standing strategy for other things.
- **Elenchus's `projects/elenchus/` in Felix.** You have it read only. A gate
  contract change is a request to J. See §8.

If you need something on this list, ask. It is a decision, not a permission
error.

---

## 8. Working with J from here

**The split.** You own Elenchus development. J owns Felix, the beta, and every
credential. Felix development exists to make your Elenchus development better,
so what Felix gets wrong for you is worth telling him about specifically.

**When Felix changes.** J pushes the distribution repository and you run:

```
cd ~/felix && git pull && ./engine/harness/felix install --home ~/felix
```

Forgetting this is quiet at first and then loud: your sessions keep the engine
you installed last, and your next `felix gate` goes red on the `installed` check
because your tree and your deployed cache disagree. That red is the system
telling you to run the two commands above.

**When you need the gate contract changed.** `projects/elenchus/gate.sh`, the
risk rules, the routes and the evidence requirements live in Felix and you
cannot push there. Send J the change you want and why. This is the one place the
arrangement makes you slower, and it is on purpose while it is new.

**Record lessons where they get read.** `felix lesson "..."` writes to your
`lessons.md`, which is matched into future prompts. A fix explained in a commit
message is read once and never again, and Felix has the receipts on that: a
lesson written into a commit message rather than `lessons.md` was repeated
within the same day.

**Back up your memory root.** Felix writes your `lessons.md`, `DEVLOG.md`,
`mistakes.log`, `ledger.tsv` and session handoffs under `~/.felix/memory/`,
outside any checkout. `felix pulse` will commit and push that to a git remote if
you give it one. Set up your own private remote in week one. Point it at your
own, never at J's, because the two records must not merge.

**Escalate with a recommendation, not a research task.** When something needs
J's call, do the analysis first and arrive with a proposal. His input should be
a yes or no on a resolved question. Reserve the open question for things that
turn on his preference or authority, such as what gets built or which credit
pool to spend, and not for facts a command can establish.

---

## 9. The codebase, one level up

`orchestration.run_session` wires the loop. Verify this map against the import
list before relying on it, per §5.

- `aim` opens the session. `Core`, `CoreCandidate` and `CoreVerdict` are types in
  `types.py`, not a module.
- `experience.select_experience` picks what gets served. `forge` builds dynamic
  experiences over curated rubrics.
- `assessment` is regime split behind `ASSESSORS[regime]`:
  `judgment_loop.assess` for open ended, `checkable_scorer.assess` for
  `cs_technical`, with `sharper_grader` auditing.
- `state.STATE_UPDATERS` moves learner state. `scheduler.propose_open_ended` and
  `scheduler.schedule_cs` queue what is next.
- `persistence.Store` is the only thing that persists: state, ledger, queue.
- `content_loader.load_library` and `load_progression` read `content/`.
- `surface` and `terrain` shape what reaches the learner.
- `web/` is a package: `app`, `runtime`, `session_runner`, `sitting_store`,
  `slots`, `vessels`, `voice`, and `__main__`.
- Alongside the loop: `generator`, `admission`, `crystallization`,
  `elicitation`, `lift_test`, `policy`, `veldra_ingest`.

`content/` is fourteen directories of versioned doctrine: `cadence`,
`checkables`, `elicitation`, `eval`, `gate`, `lift`, `maps`, `personas`,
`prompts`, `rubrics`, `spike`, `steer`, `territories`, `voice`. Anything added
there is doctrine and is reviewed as doctrine.

Adding a domain later means new content plus a map under `content/`, never an
engine edit. The graded engine core is held byte stable and surface work rides
additive seams around it, which is why changing the rented model is a config
line that never touches what does the grading.

One correction to the README on that last point, since you will otherwise trust
it. The claim is "one config site in `model.py`", and that is accurate for the
default: `model.py:727` carries `model: str = "claude-opus-5"` and
`AnthropicModel` never reads the environment itself, it hands `api_key` straight
to the SDK (`model.py:743`). But three probe modules carry their own constant
that overrides it: `run_prompt_shift_probe.py:55`, `run_injection_probe.py:79`
and `run_push_screen_probe.py:38`. A model change is one line for the product and
four lines for the tree.

Run the web app when you want to see it:

```
PYTHONPATH=src ELENCHUS_MAX_CALLS=200 .venv/bin/python -m elenchus.web
# http://127.0.0.1:8000
```

That spends real tokens. So does `pytest -m live`. Nothing else does.

---

## 10. First week checklist

- [ ] Suite green offline, roughly `1439 passed, 35 skipped`
- [ ] `felix which` names `elenchus`
- [ ] `felix gate` reads `gate: pass`, with `secret` showing `ok` and not `skipped`
- [ ] Bundle unpacked, and `git status --short` shows none of it
- [ ] Constitution read end to end
- [ ] One trivial T0 change: gated, committed with explicit paths, DEVLOG entry,
      pushed as a branch on `LeavesJ/Elenchus` rather than a fork
- [ ] CI `gate` job green, and its log shows the harness path rather than
      "the private harness is unreachable"
- [ ] `felix pulse` pointed at your own private memory backup remote
- [ ] `docs/lessons.md` skimmed for the surfaces you expect to touch first

On that sixth item: push branches on the origin repository, never from a fork.
A fork pull request cannot reach the private harness, so CI runs format, lint
and the suite and skips all five doctrine checks. The workflow says so itself in
its final step. It looks green and it is not the gate.
