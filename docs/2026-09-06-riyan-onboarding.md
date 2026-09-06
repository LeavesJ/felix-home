# Elenchus: onboarding

For Riyan, 2026-09-06. This is the document to read first and to keep open for
the first week. It takes you from a machine with nothing on it to a green gate
and a pushed commit, and then tells you the six things that will otherwise cost
you a day or a bill each.

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

You get read access to the whole Felix repository. Most of it is not about you:
`HANDOFF.md` is J's standing direction for developing Felix itself,
`projects/felix/` governs Felix, and `projects/veldra/` governs a different
product. The part that is yours is `projects/elenchus/`, and §5 is drawn from it.

Read access is all you need and all you have. Felix writes into `<clone>/state/`
for gate receipts and route memory, which is gitignored, and into
`~/.felix/memory/` for your lessons and ledger, which is outside the clone. You
will never need to push there.

**One thing to settle with J before you commit anything.** Elenchus is public but
it is not open source. The tracked `LICENSE` is source available: section 5(b)
forbids modifying or preparing patches for the Materials, and section 6 says not
to submit pull requests. Section 1 then carves out "Owner's founders, employees,
contractors, or agents acting on Owner's behalf", and section 6 repeats that
carve-out, so the work is squarely permitted once you are engaged in one of those
capacities. Make sure that is written down before your first commit. It is J's to
arrange, and it is worth your asking rather than assuming.

---

## 3. Day one

Roughly ninety minutes if nothing surprises you. Do the steps in order, and stop
at each verify line rather than reading ahead.

### 3.1 Elenchus

```
git clone https://github.com/LeavesJ/Elenchus.git
cd Elenchus
python3.14 -m venv .venv
.venv/bin/pip install -e ".[dev,web]" "ruff==0.16.0" "pytest==9.1.1"
```

**Those two pins are not optional and are not in `pyproject.toml`.** CI installs
exactly that line (`.github/workflows/gate.yml:90`) while `pyproject.toml`
declares only `ruff>=0.6`. The project has already been bitten by this: the
comment at `pyproject.toml:58` records that rebuilding the venv on a newer ruff
"turned a green gate red across ~40 pre-existing sites that no one had chosen to
change". Install without the pins and your local `felix gate` lint can disagree
with CI's for reasons that have nothing to do with your change.

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

**Verify:** `1439 passed, 35 skipped`. This was run on 2026-09-06 from a clone
with nothing untracked in it, no `.env`, no `data/`, no `docs/` and no lift
banks, and it took 74 seconds. So it is the number to expect exactly, not
roughly, and if you get it your environment is correct before anything else
arrives.

The 35 skips break down precisely, which is worth knowing because it makes them
a signal rather than noise:

- **31 are "no key".** `test_voice_live.py` (21), `test_live_model.py` (6), and
  one each in `test_steer_f1.py`, `test_lift_acceptance.py`,
  `test_frame_gen_spike.py` and `test_elicitation_acceptance.py`. These are the
  `@live` tests. They stay skipped and that is correct.
- **4 need untracked corpus.** Two in `test_run_injection_probe.py` (238 and
  214, "real payloads are gitignored and absent in a fresh worktree") and two in
  `test_generator.py` (552 and 534, "real seeded corpus (gitignored data/) not
  present").

**Those four are your bundle check.** After you unpack what J sends, re-run the
suite. If the corpus files landed where they belong, some or all of those four
turn from skipped into passed and the skip count drops below 35. If it stays at
exactly 35, something is in the wrong directory. That is a mechanical test of a
step that otherwise has no feedback at all.

The suite also writes nothing into the tree. `git status --short
--untracked-files=all` was empty after a full run, so a dirty tree after testing
means you did it, not pytest.

If this fails on imports you skipped the `PYTHONPATH=src` part.

One note on the version. This run used Python 3.13 and was green, and
`pyproject.toml` declares a 3.12 floor, so the suite is not 3.14 locked. Match CI
at 3.14 anyway: it is what `main` is gated by, and lesson L-19 about the editable
install is specific to 3.14, so on any lower version you will not hit the problem
the `PYTHONPATH=src` rule exists to route around and you may forget the rule
matters.

### 3.2 Felix

`LeavesJ/felix` is private and you have read on it. **Clone it somewhere
permanent and do not move or delete it afterwards.** The install does not make
the clone disposable: only `engine/` is copied into the plugin cache, and
`projects/` never enters it, so your constitution and your gate script are read
from the clone on every session for as long as you use Felix. Felix also
explicitly refuses to treat a plugin cache copy as a home, because that would
freeze the constitution at install time and write memory into a directory the
next plugin update deletes.

```
git clone git@github.com:LeavesJ/felix.git ~/felix
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

**Verify:** it names `elenchus`, and `governs:` names your Elenchus checkout.

If it says no project governs this directory, it is one of two things.

**Your home is wrong.** Felix resolves the home in this order: the `FELIX_HOME`
environment variable, then the `~/.felix-home` pointer file, then a checkout
carrying `projects/` beside the engine, then `~/.felix`. Re-run
`felix install --home ~/felix`.

**Or your `origin` is not `LeavesJ/Elenchus`.** Elenchus carries no `.felix`
marker, so it binds purely on the remote: `projects/elenchus/project.json`
declares `"remote_match": "LeavesJ/Elenchus"` and nothing else identifies the
project. Clone from a fork and Felix governs nothing, silently, because it is
designed to stay quiet in repositories it does not govern. **This is the real
reason to work on branches of the origin repository rather than a fork**, ahead
of the CI reason in §10. If you ever genuinely need a differently named remote,
`printf 'elenchus\n' > .felix` at the checkout root restores full binding, and
that file will show as untracked because it is not in `.gitignore`.

Prerequisites, while you are here: the engine core needs only `bash` and `git`.
The `claude` CLI is needed for `felix install` to register the plugin, and `gh`
for a subset of commands. Neither the gate nor the hooks need `jq` or Python.

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
are first-run states and a green gate still reads `gate: pass`.

**`commission` will bite you later though, at `felix merge` rather than at the
gate.** It is an escape channel, and `escape.sh:14` says "Empty output means
nothing escaped and Felix may merge." So expect your first `felix merge` to
refuse on a machine that has never been commissioned, even with a green gate
behind it. Ask J to walk you through `felix commission` once, before you need it.

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
- A `docs/DEVLOG.md` entry rides with the change. **Read this one carefully,
  because taken literally it is impossible.** `CLAUDE.md:229` says the entry goes
  "in the same change", and `.gitignore:6` ignores `/docs/` wholesale, so the
  entry can never be staged in that commit or any other. The workable reading is
  that the DEVLOG is a local record you update in the same sitting, not a file
  you commit. Do not try to force it in: `git add -f` on an ignored path is
  blocked by `deny.tsv` and is T3 anyway. If in doubt ask J which he means.
- **No `Co-Authored-By` trailer** in an Elenchus commit.
- No em dashes in prose.

---

## 6. The six traps

Each of these has already cost real time or money. They are in order of how
likely you are to hit them.

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

**5. The gate is only offline while no key is in the shell.** This one costs
money rather than time. `gate.sh:126` runs a bare `pytest -q` with no
`-m "not live"`, and the 31 live tests are held back only by
`@pytest.mark.skipif(not _HAS_KEY)`. So the moment `ANTHROPIC_API_KEY` is in your
environment, `felix gate` stops being free and starts making real paid Opus
calls. The gate's own comment says live tests "are never part of the gate", which
is the intention and not the mechanism.

The habit that avoids it: never source `.env` in the shell you gate in. Run the
web app in its own shell with the key, and keep your gating shell clean. If a
gate run suddenly takes minutes instead of about ninety seconds, that is what
happened.

**6. Hooks bind at session start.** If Felix changes, or you re-run
`felix install`, the session you are sitting in keeps running the engine it
loaded when it started. It is live for the *next* session, which is a much
weaker claim than it sounds.

Felix's own notes say to check the version in the session start banner. **Do not
bother: this banner does not carry one.** It prints `Felix: elenchus`, plus
`N due` and `new tooling found` when either applies, and nothing else
(`engine/harness/hooks/session-start:439`). The checks that do work are
`claude plugin list`, which names the deployed version, and re-running
`felix install`, which compares the tree against the cache and says which it
found.

There is a seventh that is not yet your problem but is worth knowing the shape of.
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

**When Felix changes.** J pushes to `felix` and you run:

```
cd ~/felix && git pull && ./engine/harness/felix install --home ~/felix
```

**Forgetting this is quiet and stays quiet.** There is no check that catches it.
The `installed` gate check exists only in Felix's own project, not in Elenchus's,
so a stale engine on your machine produces no red gate and no warning. Your
sessions just keep running the engine you installed last. Make the two commands
above a habit tied to J telling you he pushed, because nothing else will remind
you.

**You can be behind. You cannot be divergent.** Elenchus CI checks out
`LeavesJ/felix` directly (`.github/workflows/gate.yml:73`), which is the same
repository you cloned. So CI runs the gate as it exists on `main` and you run it
as of your last pull. Those are the same file at different times, never two
different files, which is why the fix is always just `git pull`.

If CI and local disagree anyway, that is a finding rather than flakiness, and
Felix's own notes say so. Pull first, and if it still disagrees, tell J rather
than re-running the job.

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

**One thing about `docs/lessons.md` that will confuse you otherwise.** On J's
machine, three files in `docs/` are symlinks into his memory root:
`lessons.md`, `DEVLOG.md` and `SESSION_HANDOFF.md`. You receive their contents
as ordinary files, which is correct, but it means **they are a snapshot and
they will not update themselves.** Run `felix lesson "..."` and it writes to
*your* `~/.felix/memory/elenchus/lessons.md`, not to the `docs/lessons.md` in
your checkout. Those two then drift apart silently, and the 252 code comments
citing `L-nn` keep pointing at the frozen copy.

If you want J's setup rather than the snapshot, replicate the symlinks once,
after your first `felix` run has created the memory directory:

```
mv docs/lessons.md ~/.felix/memory/elenchus/lessons.md    # seed with J's copy
ln -s ~/.felix/memory/elenchus/lessons.md docs/lessons.md
```

Same shape for the other two. That makes your own `felix lesson` writes land in
the path the code comments cite, which is the behaviour J has been running with
since 2026-08-18. Ask him before doing it if you would rather not inherit the
accumulated file as your own starting point.

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
