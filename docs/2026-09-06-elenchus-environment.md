# Elenchus: the local environment

Written 2026-09-06 for Riyan. Everything here was read out of the tracked code
on the date above, with the file and line beside each claim so you can check any
of it yourself in about a minute. Nothing here is a secret value.

The public `README.md` covers install and the two commands. This covers the part
the repository deliberately does not carry: which variables exist, where the key
goes, which untracked files have to be present for which command, and the one
asymmetry between the two ways of starting the server that has cost this project
real hours.

---

## 1. Start here

A fresh clone runs the whole offline suite green with nothing untracked present.
That is deliberate and it is your baseline:

```
git clone https://github.com/LeavesJ/Elenchus.git
cd Elenchus
python3 -m venv .venv
.venv/bin/pip install -e ".[dev,web]"
PYTHONPATH=src .venv/bin/pytest -q
```

Roughly 1439 pass and 35 skip in about a minute. If that is green you have a
working checkout and every later failure is configuration rather than code.

`PYTHONPATH=src` is not optional and is not a style preference. The editable
install is unreliable on 3.14, which is lesson L-19, so `import elenchus` may
resolve to nothing even after a successful `pip install -e`. The install line is
there for the dependencies. Every command that runs project code carries
`PYTHONPATH=src`.

---

## 2. Every environment variable

There are six, and none of them is required for the test suite.

| Variable | Read at | Default | What it does |
|---|---|---|---|
| `ANTHROPIC_API_KEY` | `web/__main__.py:41`, `scripts/serve_invitee.py:87` | none | The model key. Without it the web app boots and health-checks green while every door dies on the first click. See §4. |
| `ELENCHUS_DB` | `web/runtime.py:40` | `<repo>/data/elenchus.db` | Which database file this process opens. Override only. |
| `ELENCHUS_HOST` | `web/runtime.py:39` | `127.0.0.1` | Bind address. Anything outside loopback means serving other people, and the resolver refuses that combination against the default database. |
| `ELENCHUS_PORT` | `web/runtime.py:67` | `8000` | Port. A non-numeric value raises at boot rather than falling back, because a typo that silently reuses the default puts two people in one process. |
| `ELENCHUS_MAX_CALLS` | `spend.py:61` | unset, meaning unbounded | Per-process model call ceiling. Must be a positive integer. `scripts/serve_invitee.py:163` sets it to 500 for launches it owns. |
| `ELENCHUS_ENV_FILE` | `scripts/serve_invitee.py:95`, `scripts/preflight.py:68` | `~/.config/elenchus/env` | An out-of-tree file to read the key from. **Only the launcher and preflight honour this.** See §4. |

`ANTHROPIC_AUTH_TOKEN` also appears, but only as a skip gate. Three live test
modules (`tests/test_live_model.py:10`,
`tests/test_elicitation_acceptance.py:9`, `tests/test_lift_acceptance.py:151`)
skip unless one of it or `ANTHROPIC_API_KEY` is set. Nothing under `src/` reads
it, so setting it alone would un-skip those tests without giving the code a key.
Set `ANTHROPIC_API_KEY` and ignore this one.

One more exists and is not yours: `TUNNEL_ORIGIN_CERT`
(`scripts/serve_invitee.py:204`, default `~/.cloudflared/cert.pem`) names the
Cloudflare origin certificate. It belongs to beta operations, which J keeps in
full. You will not have that certificate and you should not need it.

`ELENCHUS_DB`, `ELENCHUS_HOST` and `ELENCHUS_PORT` are override only by design.
With none of them set the behaviour is byte for byte what it was before they
existed, so leaving all three unset is the correct development configuration.

There is no `.env.example` in the repository. Whether one gets added is J's
call, because it changes the tracked set of a public repository.

---

## 3. Your `.env`

Put your own key in `<repo>/.env`, which `.gitignore` already covers along with
`.env.*` and `*.key`:

```
ANTHROPIC_API_KEY=paste-your-key-here
```

That placeholder is deliberately not key-shaped. An earlier version wrote it
with the real prefix, which meant this document tripped the handover secret scan
every time it ran, and a scan with a known-acceptable hit in it is a scan people
stop reading.

Use your own key on your own workspace with its own spend limit. Do not use J's.
That is not a formality: a shared key makes spend unattributable and a leak from
either machine burns both.

`_load_dotenv` (`web/__main__.py:25`) parses simple `KEY=VALUE` lines, strips an
optional `export ` prefix and surrounding quotes, skips comments and blanks, and
uses `setdefault`, so a variable you actually exported in the shell always beats
the file. It never logs values.

---

## 4. The asymmetry that will bite you

The two ways to start a server do not resolve the key the same way.

`python -m elenchus.web` reads **only** `<repo>/.env`. The single call at
`web/__main__.py:41` is `_load_dotenv(_ROOT / ".env")` and it consults nothing
else. `ELENCHUS_ENV_FILE` does not appear anywhere in `src/`.

`scripts/serve_invitee.py` reads `<repo>/.env` first and then the out-of-tree
file, either `ELENCHUS_ENV_FILE` or `~/.config/elenchus/env`
(`scripts/serve_invitee.py:90` to `:96`). That second location exists because
J's checkout lives inside the macOS Documents sync container, so a key at
`<repo>/.env` is replicated to Apple and to every device on the Apple ID.

So if you read about the out-of-tree location, put your key only at
`~/.config/elenchus/env`, and then run the README's `python -m elenchus.web`,
you get a keyless instance. It will not tell you. `/api/health` costs zero
tokens and returns green, and the failure rides back to the browser as HTTP 200,
so even the access log reads like a served turn. That is lesson L-18 and the
code comments record it being paid for three times.

If your checkout is not inside a sync container, use `<repo>/.env` and ignore
the out-of-tree path entirely.

If it is, there is a better answer than keeping two copies, and it is the one
J's own checkout uses. Make `<repo>/.env` a symlink to the out-of-tree file:

```
ln -s ~/.config/elenchus/env <repo>/.env
```

The sync container then replicates a symlink, which is a short text file holding
a path, rather than the key itself. Both entrypoints find the key because both
read `<repo>/.env` and the link resolves locally, and there is one copy of the
secret rather than two to keep in step. Verified on J's machine 2026-09-06.

---

## 5. Untracked files, and which command needs which

Nothing here is in the repository. Everything here arrives in the handover
bundle.

| Path | Needed for | Without it |
|---|---|---|
| `.env` | the web app, the `@live` suite | keyless, silently, per §4 |
| `docs/lessons.md` | reading the codebase | 252 code comments cite lesson numbers that resolve to nothing |
| `docs/DEVLOG.md` | knowing why anything is shaped as it is | you are guessing |
| `content/lift/scenarios.yaml`, `candidates.yaml` | the lift workflow against real content | the tracked `*.example.yaml` stubs are the public shape and the tests use those |
| `.claude/CLAUDE.md` | Claude Code sessions in this checkout | sessions run without project doctrine |
| `data/` | nothing you must create | `persistence.py:53` creates the parent directory itself |

`data/elenchus.db` is not in the bundle and will not be. That file is J's own
sitting history, meaning one particular person's recorded decisions. Your
instance creates its own empty database on first boot.

---

## 6. Check the machine, not just the code

```
PYTHONPATH=src .venv/bin/python scripts/preflight.py --repo .
```

This is tracked and public, and it is the answer to "is my machine actually set
up". It exists because the project's own gate reads the repository and passed
every check while the beta served keyless for seventeen hours and a live paid
key sat at mode 644 inside iCloud. None of those defects were in the code, which
is why a code linter cannot see them.

Read its output selectively. The axis you want is `key_reachable`, which uses
the launcher's own resolver rather than a second copy of the logic, so it
answers §4's question directly. Axes about open listeners, public surface and
access configuration are beta operations concerns. J holds the beta in full, so
a warning there is information rather than a task, and it is never a reason to
touch anything serving real invitees.

Exit 1 on any FAIL. A WARN prints and does not block.

---

## 7. Things not to run

- Anything that serves a non-loopback address. `web/runtime.py:50` refuses the
  default database on a non-loopback bind, and the refusal exists because two
  people on one database file become one learner and cannot be separated
  afterwards.
- `pytest -m live`. It calls the real model and spends. The offline suite is the
  one you run constantly.
- `scripts/serve_invitee.py` against anything real. It is the beta launcher.
- Anything involving `~/.cloudflared/`. You will not have it.

---

## 8. Felix

Felix is the governance engine and it is a separate repository and a separate
setup. That is covered in `2026-09-06-riyan-onboarding.md`, which is the
document to work through after this one. The short version is that you clone
`LeavesJ/felix`, run `felix install --home <your-felix-clone>`, and it then
governs your Elenchus checkout by matching the git remote.

One thing worth knowing before you get there: clone Elenchus from
`LeavesJ/Elenchus`, never from a fork. Elenchus carries no marker file and binds
to its doctrine purely by remote name, so a fork is governed by nothing, and
Felix is built to stay quiet where it does not govern. You would get no error.
