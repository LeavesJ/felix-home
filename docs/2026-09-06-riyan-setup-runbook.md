# Setup runbook

Riyan, 2026-09-06. Everything you have to actually do, in order. Nothing here
explains the product; you already know it. Where a step has a check, stop at the
check rather than reading ahead.

Two other documents sit beside this one in the bundle. `ENVIRONMENT.md` is the
reference for variables and key resolution, read out of the tracked code. The
onboarding document covers Felix doctrine and the gate's eight checks. This one
is the sequence.

About ninety minutes, most of it waiting on a venv.

**J is remote for your first commit**, so every check below says what a failure
means rather than telling you to ask him. Where something genuinely needs him,
the last section says so and that list is short.

---

## 1. Unpack and restore

```
cd <your Elenchus checkout>
/path/to/bundle/restore.sh
```

It refuses unless you are standing in a checkout whose origin is
`LeavesJ/Elenchus`. That is not bureaucracy: Elenchus carries no marker file and
binds to its Felix doctrine purely by remote name, so **a fork is governed by
nothing and Felix says nothing about it**. You would get a silent no-op instead
of an error.

It places every untracked file, creates your own empty `data/` store and your
own out-of-tree key file, and links `docs/lessons.md`, `docs/DEVLOG.md` and
`docs/SESSION_HANDOFF.md` into your Felix memory root the way J's checkout is
arranged. It is idempotent and it never overwrites a file you have changed.

**Check:** it ends with `structure matches`. Anything marked `!!` is something
it deliberately left alone for you to look at.

---

## 2. Your own key

```
$EDITOR ~/.config/elenchus/env
```

Replace `paste-your-key-here`. Your own key, on your own Anthropic workspace,
with its own spend limit. Not J's, ever: a shared key makes spend unattributable
and a leak from either machine burns both.

`restore.sh` linked `<repo>/.env` to that file rather than putting the key in
the checkout, which is J's arrangement and worth keeping. His checkout sits
inside the macOS Documents sync container, so a key at `<repo>/.env` would
replicate to Apple and to every device on the Apple ID; a symlink replicates a
short text file holding a path instead.

**Read `ENVIRONMENT.md` §4 before you move on.** The two ways of starting the
server do not resolve the key the same way, and getting it wrong gives you an
instance that health-checks green and dies on the first click.

---

## 3. Venv and the suite

```
python3.14 -m venv .venv
.venv/bin/pip install -e ".[dev,web]" "ruff==0.16.0" "pytest==9.1.1"
PYTHONPATH=src .venv/bin/pytest -q
```

**Check: `1439 passed, 35 skipped`.** Exactly that, not roughly. About 74
seconds.

Three things about that line, each of which has cost someone a day:

- **The two pins are not in `pyproject.toml` and are not optional.** CI installs
  exactly that line (`.github/workflows/gate.yml:90`) while `pyproject.toml`
  declares only `ruff>=0.6`. `pyproject.toml:58` records that rebuilding on a
  newer ruff "turned a green gate red across ~40 pre-existing sites that no one
  had chosen to change".
- **`PYTHONPATH=src` on every command that runs project code.** The editable
  install is unreliable on 3.14, which is lesson L-19, so `import elenchus` can
  resolve to nothing after a successful `pip install -e`. That install line is
  for dependencies.
- **35 is your permanent correct number.** It does not drop after unpacking.
  Two of those skips need `data/elenchus.db`, which is J's own sittings database
  and never travels; two need `data/injection_payloads.yaml`, which is
  conditional. An earlier draft of the handover told you a persistent 35 meant a
  misfiled bundle. It does not.

---

## 4. Felix, and a green gate

```
git clone git@github.com:LeavesJ/felix.git ~/felix
cd ~/felix && ./engine/harness/felix install --home ~/felix
cd <your Elenchus checkout> && ~/felix/engine/harness/felix which
```

**Clone it somewhere permanent.** Only `engine/` is copied into the plugin
cache; `projects/` never is, so your constitution and gate script are read from
that clone on every session for as long as you use Felix.

**Check:** `felix which` names `elenchus`. Then:

```
~/felix/engine/harness/felix gate
```

**Check:** the last line reads `gate: pass`.

Below the eight checks Felix prints two more lines, and they are not
equivalent. `commission` is announce-only and never changes the verdict.
**`probes` decides it**: one row coming back `blind` or `unknown` prints
`probes FAIL` and `gate: FAIL (probes)` and sets a non-zero exit even when all
eight project checks passed (`engine/harness/lib/probes.sh:355`,
`engine/harness/felix:3935`). If you see a blind `http_route`, the cause is
almost always your venv, because the probe falls back to system `python3` when
`.venv/bin/python` is missing (`projects/elenchus/probes.tsv:29`).

---

## 4b. Commissioning, which is what will actually block your first merge

`commission` is announce-only at the gate, so a green gate tells you nothing
about it. It bites at `felix merge`: it is an escape channel, and
`escape.sh:14` says "Empty output means nothing escaped and Felix may merge",
so a machine that has never been commissioned refuses to merge with a green
gate behind it.

An earlier draft of this document said to ask J to walk you through it. He is
remote, so here it is instead.

**Look before you run anything. `--status` is read-only:**

```
cd <your Elenchus checkout>
~/felix/engine/harness/felix commission --status
```

`projects/elenchus/commissioning.tsv` declares thirteen needs. Most are answered
from the checkout itself and will already be `done`. Of the states it reports,
only **`unknown` blocks**; `held` is a person's queue and does not.

**Three prerequisites, and a row goes `unknown` when its instrument is missing
rather than when its check fails.** That distinction is why a missing tool
blocks and an unmet task does not.

| Row | Instrument | If missing |
|---|---|---|
| `discover`, `stack`, `preflight` | `claude` | three rows `unknown`, blocks |
| `baseline` | `gh` | `unknown`, blocks |

So before commissioning: `claude` on your PATH, and `gh` installed and
authenticated (`gh auth status`). Neither is in the bundle and neither is
mentioned anywhere else.

**One row you cannot satisfy by preparing, only by working.**
`gate_shown_failing` checks that `mistakes.log` holds a gate failure that is
neither `commission` nor `probes`. You cannot commission a fresh machine until
your gate has genuinely failed at least once for a real reason. That is
deliberate, it is the first-encounter moment doing its job, and on a new machine
it reads like a bug. Do a real piece of work, let the gate catch something,
then commission.

**One row nobody can satisfy, including J.** `projects/elenchus/setup.tsv` has a
`stripe` row whose check is literally `false`, so `human_steps` is permanently
`held`. That is correct and does not block. Do not go looking for what you did
wrong.

**Two rows you cannot satisfy with the access you have.** `ci-anthropic-key` and
`strix` both check `gh secret list --repo LeavesJ/Elenchus`, and listing secrets
needs `admin`. You have `write`. Both stay `held`, which is fine, and neither is
yours to fix.

Then, when `--status` shows nothing `unknown`:

```
~/felix/engine/harness/felix commission
```

There is no `--yes`. The engine refuses one by name, because the stages already
hold the install policy and a person's rows stay a person's.

---

## 5. The agent setup

Present only if the bundle has an `agent-setup/` directory.

`restore.sh` already placed it into `~/.claude/`. Three things remain, and no
script can do them for you.

**Authenticate Claude Code as yourself.** Nothing in the bundle carries J's
account, session or tokens, deliberately.

**Merge anything marked `.from-jarron`.** Where you already had an entry that
differed, yours was left untouched and J's landed beside it:

```
ls -d ~/.claude/*.from-jarron 2>/dev/null
```

Diff each one and merge deliberately. Your own agents, commands and settings win
by default.

**Wire up the MCP servers yourself.**

```
cat ~/.claude/mcp-servers.from-jarron.json
```

That file lists which servers J runs and how, with every credential replaced by
`SET-YOUR-OWN`. **Nothing reads it automatically** and that is on purpose; a
half-configured server is worse than an absent one. Add the ones you need with
your own credentials.

What did not travel and never will: `~/.claude/projects/`, which is session
transcripts, and `~/.claude.json`, which holds an OAuth account. Both are
verbatim records rather than configuration.

---

## 6. What costs money, before you run anything live

You will run evaluation that J mostly could not afford to run casually. Read
this before the first sweep.

**`ELENCHUS_MAX_CALLS` bounds exactly one process, and it is not the one you
will be running.** Verified 2026-09-06: seven `AnthropicModel` construction
sites exist in `src/`, and exactly one passes a budget,
`src/elenchus/web/app.py:97`. The other six build an unbounded model:

| Site | What it is |
|---|---|
| `src/elenchus/cli.py:92` | the CLI |
| `src/elenchus/run_injection_probe.py:293` | injection probe |
| `src/elenchus/run_prompt_shift_probe.py:229` | prompt-shift probe |
| `src/elenchus/run_push_screen_probe.py:110` | push-screen probe |
| `src/elenchus/frame_gen_spike.py:324` | frame-gen spike |
| `src/elenchus/run_elicitation.py:38` | elicitation |

Every one of those is ML work, which means every one of them is yours. Setting
`ELENCHUS_MAX_CALLS` and then running a probe gives you a ceiling that is not
applied and a false sense of one.

`from_env` returns `None` meaning unbounded when the variable is unset
(`src/elenchus/spend.py:61`), and absent must mean unbounded rather than zero
because the suite and the CLI construct models with no budget and a default that
refused every call would take the product down. `DEFAULT_MAX_CALLS` is 500
(`spend.py:26`) and `scripts/serve_invitee.py:163` applies it to launches it
owns.

So before a live sweep: set a spend limit **on the Anthropic workspace itself**,
not only in the environment. That is the only ceiling that covers all seven
sites. Then `pytest -m live` and the probe scripts are safe to explore.

---

## 7. Your first commit

Make it small on purpose, so the whole chain gets exercised while nothing is at
stake.

```
git checkout -b <branch>
```

Work on origin branches, never a fork, for the binding reason in step 1.

```
~/felix/engine/harness/felix gate
```

Green before you push. The gate is what `main` requires and it lives in Felix,
not in Elenchus: `.github/workflows/gate.yml` says so in its own header.

One thing you cannot change alone: `projects/elenchus/` in the Felix clone is
the gate contract and you have it read-only. A change there is a request to J.

---

## 8. Where the risk actually is

Not a tour. Four places where a reasonable change produces a wrong result rather
than an error.

- **`src/elenchus/web/runtime.py`.** The two-instance isolation guard. Its own
  docstring says a misconfiguration here is a privacy incident rather than a
  degraded experience: two people on one database file become one learner and
  cannot be separated afterwards.
- **`src/elenchus/web/app.py:14`, `_SID = "single"`.** Correct only while one
  database holds one person. The partial index and the unscoped store reads all
  depend on it.
- **Anything that binds a non-loopback address.** `runtime.py:50` refuses the
  default database on one, deliberately.
- **Anything touching the tunnel or Cloudflare Access.** That is beta
  operations, which J keeps in full. You will not have the credentials and you
  should not need them.

The beta has not run yet: thirty invitations are ready and none has been sent,
so the tenant root is empty today. Nothing you do this week can reach a real
person's data. The window in which that is true is short, so the habits you
build now are the ones running when there are thirty people on the other side.

---

## What to ask J rather than work out

- Anything in §4b that `commission --status` reports as `unknown` after you have
  `claude` and `gh` in place. Everything else there you can resolve alone.
- Anything that would change `projects/elenchus/` in Felix.
- Anything touching the beta, the tunnel, or invitee data.
- Whether a lift or mining change should go in the real banks or the example
  stubs.
