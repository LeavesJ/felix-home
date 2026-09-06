# Elenchus handover runbook

Written 2026-09-06. The operator of this runbook is J. It is the private half of a
two document handover: this file says what to do and in what order, and
`docs/2026-09-06-riyan-onboarding.md` is the document Riyan actually receives.

**Why this file lives in Felix and not in Elenchus.** Elenchus is public. This
runbook names credential locations, a personal data boundary, and an access
decision, and none of that belongs in a public tracked set. Elenchus's own gate
would refuse it anyway: the `confidential` check fails on any tracked path
matching `^docs/` (`projects/elenchus/gate.sh:145`), and `.gitignore:2` untracks
every root level markdown file, so a root placed copy could only be tracked with
`git add -f`, which `projects/elenchus/deny.tsv` blocks and `projects/elenchus/CLAUDE.md`
forbids under Delivery. Nothing tracked is added to Elenchus by this handover.
The one candidate that would be legitimate is raised as decision D5 below and
is yours to take, because it is T3.

Every claim here cites a file and a line that was read while writing it. Where a
fact is about your laptop rather than about a repository, it is marked
`TODO(assumption)` and you confirm or correct it before that step runs.

---

## 1. The shape of the problem

Three things are being handed over at once and they have different risk
profiles. Keeping them separate is most of the work.

1. **Elenchus development.** Riyan takes the majority of it. Elenchus is public,
   so the code is already his to read. What he is missing is everything the
   repository deliberately does not carry.
2. **Felix use.** Riyan runs Felix against his Elenchus checkout. Felix is
   private and stays private, and you keep developing it. He needs the engine and
   one project directory, and nothing else in the repository.
3. **Beta operations.** Eight or so real people have written real decisions into
   per invitee databases. That is third party personal data and it is the one
   thing in this handover that cannot be un-sent.

The recommendation running through this entire document is that these three
separate cleanly, and that separating them is what makes the handover safe
rather than merely fast.

---

## 2. Decisions to take before step one

Take these five now. Every phase below assumes an answer, and reversing one
mid-sequence is where a handover leaks.

### D1. How Riyan gets Felix

**Recommendation: a private distribution repository, squashed, no history.**

The reasoning is in §4. The short version is that a read only collaborator seat
on `LeavesJ/felix` hands Riyan `HANDOFF.md` (4061 lines of standing strategy),
`projects/veldra/`, `projects/felix/`, and `docs/`, none of which he needs and
some of which is founder private. A distribution repository carrying `engine/`
and `projects/elenchus/` gives him exactly what the code requires and nothing
more.

### D2. Who operates the beta

**Recommendation: you keep it, entirely, and Riyan never touches it.**

This is the cleanest boundary available and the code already supports it. The
offline suite runs against a scripted fake model with no key
(`.github/workflows/gate.yml` runs the full gate with no `ANTHROPIC_API_KEY` on
purpose, and says so in a comment above the step). Development therefore needs
nothing from production. Handing invitee databases to a person those invitees
have never heard of is a disclosure, not a file copy, and there is no
engineering reason to make it.

If you later want Riyan operating the beta, that is a second decision taken on
its own terms with the invitees told. Do not fold it into this one.

### D3. Anthropic billing

**Recommendation: Riyan gets his own key on his own workspace with his own
spend limit. Your key never moves.**

A shared key makes spend unattributable, which is the exact confounding
`HANDOFF.md:3937` records deciding against for the pentest provider. It also
means a leak from either machine burns both. Issue him a key scoped to a
workspace you can cap and revoke independently.

### D4. Riyan's GitHub role on Elenchus

**Recommendation: `write`, pushing branches on `LeavesJ/Elenchus` directly.
Not a fork, and not `admin`.**

Forks are actively worse here, and this is mechanical rather than a preference.
`gate.yml` decides from the event whether the private harness is reachable, and
a pull request from a fork gets `harness=no`, which runs format, lint and the
suite while skipping `confidential`, `secret`, `lift-bank`, `ignore-leak` and
`inversion`. The workflow announces that itself in its final step. A fork
contributor can never turn the real gate green, so Riyan must push branches on
the origin repository.

`admin` is not needed for anything he does and would let him change branch
protection, which is the one enforcement Elenchus actually has
(`HANDOFF.md:3710` records that Felix's own repository cannot have it).

### D5. Whether to add `.env.example` to Elenchus

**This is yours. It is T3.**

`projects/elenchus/CLAUDE.md` puts "anything that changes the tracked set of the
public repo" and "`.env*`" under T3 stop and ask. `.gitignore:25` already carries
`!.env.example`, so the slot was anticipated and never filled, and Riyan
currently has to be told the shape of `.env` out of band. Adding a values free
example would close that. It is a good idea and it is still your call, so
nothing in this handover adds it.

---

## 3. Inventory: everything that is not in the repository

This is the answer to "what do I actually have to send". Sources are cited so
each row can be re-derived rather than trusted.

### 3a. Elenchus, gitignored or out of tree

| What | Where | Class | Riyan gets it? |
|---|---|---|---|
| `docs/` (`DEVLOG.md`, `lessons.md`, spike results, specs) | repo, untracked (`.gitignore:6`) | internal | **yes**, reviewed |
| Root strategy markdown, twelve files | repo root, untracked (`.gitignore:2`) | internal, mixed | **only `POSITIONING.md`** |
| `content/lift/scenarios.yaml`, `content/lift/candidates.yaml` | repo, untracked (`.gitignore:19-20`) | internal | **yes** |
| `.env` | repo root, untracked (`.gitignore:23`) | secret | **no**, he writes his own |
| `~/.config/elenchus/env` | outside the repo | secret | **no**, he writes his own |
| `data/elenchus.db` | repo, untracked (`.gitignore:13`) | **your own personal data** | **never** |
| `~/.local/share/elenchus/data/tenants/*` | outside the repo | **third party personal data** | **never** |
| `.claude/` | repo, untracked (`.gitignore:7`) | internal config | optional, reviewed |
| `scripts/prepush.sh` | repo, untracked | duplicate | **no**, Felix holds it |
| `.git/info/exclude` | repo local | internal | contents only, reviewed |

Two of those rows are the ones to slow down on.

**`content/lift/*.yaml` is required, not optional.** The tracked
`*.example.yaml` stubs are the public shape and the gate actively fails if the
real banks are ever tracked (`projects/elenchus/gate.sh:175`, the `lift-bank`
check). Riyan cannot do lift work without the real files and cannot commit them,
so they move out of band and stay out of band.

**`data/` is two different sensitivities wearing one directory name.**
`src/elenchus/web/runtime.py:24` sets `DEFAULT_DB` to `<repo>/data/elenchus.db`,
and the refusal at line 54 describes that file as holding "one particular
person's decisions", which is you. Separately, `scripts/serve_invitee.py:153`
puts each invitee under `<root>/<slug>/elenchus.db`, and
`scripts/forget_invitee.py:27` shows the live root on your machine is
`~/.local/share/elenchus/data`. Riyan starts with an empty `data/`. That is not
a limitation on him, it is the correct state.

`TODO(assumption)`: the twelve root strategy documents and the exact contents of
`docs/` were read from the description in `projects/elenchus/CLAUDE.md`
(Architecture section, "Twelve strategy documents sit untracked at the repo
root. Only `POSITIONING.md` binds") rather than from the files, which are not in
any clone. Confirm the list before Phase C and drop anything that is a draft
kept for history.

### 3b. Elenchus, credentials and services

Environment variables, from a grep over `src/`, `scripts/`, `tests/` and
`.github/`:

| Variable | Read at | Purpose |
|---|---|---|
| `ANTHROPIC_API_KEY` | 29 sites | the rented model |
| `ANTHROPIC_AUTH_TOKEN` | 3 sites | SDK alternate auth |
| `ELENCHUS_DB` | `web/runtime.py:40` | which learner's file this process opens |
| `ELENCHUS_HOST` | `web/runtime.py:39` | bind address |
| `ELENCHUS_PORT` | `web/runtime.py:67` | port |
| `ELENCHUS_MAX_CALLS` | `spend.py`, `serve_invitee.py:163` | per process paid call ceiling |
| `ELENCHUS_ENV_FILE` | `serve_invitee.py:95` | override for the out of tree key file |
| `TUNNEL_ORIGIN_CERT` | `serve_invitee.py:204` | cloudflared origin certificate |

The key file location is the item most likely to be missed, because nothing in
`.gitignore` mentions it. `scripts/serve_invitee.py:39` hardcodes
`DEFAULT_ENV_FILE = Path.home() / ".config" / "elenchus" / "env"`, and the
comment above it explains why: the repository sits inside the macOS Desktop and
Documents sync container, so a key at `<repo>/.env` replicates to Apple and to
every device on the Apple ID. Riyan needs to know that the key can live in two
places and which one the launcher prefers, even though he gets neither of your
copies.

GitHub Actions secrets, from `.github/workflows/gate.yml`:

- `FELIX_DEPLOY_KEY`, an SSH deploy key used to check out `LeavesJ/felix` in CI.
  This already exists and is the proof that read only Felix distribution is a
  solved problem in this system. See §4.
- `ANTHROPIC_API_KEY` and `LLM_API_KEY` appear as human setup rows in
  `projects/elenchus/setup.tsv`, both currently unset by design.

External services: Cloudflare (the account holding the invite domain, named
tunnels `elenchus-<slug>`, DNS routes, and the Access applications the README
describes), and the Anthropic workspace carrying the spend limit. Under D2 none
of these move.

Two facts that shorten this phase considerably.

**Nothing secret is in Elenchus history.** `git log --all --name-only` over
`*.env`, `*.key` and `*.pem` returns empty, so no history rewrite is needed and
no already-public credential needs rotating on account of the repository. The
only reason to rotate anything is D3, which is about attribution rather than
about a leak.

**`ANTHROPIC_AUTH_TOKEN` is a test-only path.** It appears in three sites, all
under `tests/`, so it is not a second production credential to track.

### 3c. Felix, off repository

`engine/harness/lib/resolve.sh:175` puts the memory root at `$FELIX_MEMORY` or
`$HOME/.felix/memory`, computed from `$HOME` and deliberately never from
`felix_home`. `engine/harness/lib/memory.sh` writes `DEVLOG.md` (line 29),
`lessons.md` (line 35), `SESSION_HANDOFF.md` (line 77) and `mistakes.log`
(line 95) per project, alongside `ledger.tsv`, `routes.log`, `says.log` and
`verification.log`.

The comment block above `felix_mem_root` states the rule this handover has to
respect: memory "holds verbatim founder prompts, and whatever a governed
project's work happens to be about, which includes material belonging to
somebody who never agreed to be published."

**So: no memory directory is copied to Riyan.** Not `~/.felix/memory/felix/`,
and not `~/.felix/memory/elenchus/` either. His starts empty and fills up with
his own work. `felix_mem_dir` keys on the project's directory name
(`resolve.sh` at the definition), so the two never collide.

The one real cost of that is `lessons.md`, which is matched into prompts and is
the mechanism that stops a lesson being re-learned. Handling it is Phase A step
4: you extract the Elenchus lessons that are about the codebase rather than
about you, and they travel as prose in the onboarding document. Do not copy the
file.

---

## 4. The Felix problem, and the mechanism that already solves it

### 4a. What Riyan actually needs

Three things, and the code is explicit about each.

**The engine, as an installed plugin.** `.claude-plugin/marketplace.json`
declares `"source": "./engine"`, so the deployed tree is the contents of
`engine/` and nothing above it.

**A home carrying `projects/elenchus/`.** `felix_home`
(`engine/harness/lib/resolve.sh:131`) resolves in order: `$FELIX_HOME`, then the
`~/.felix-home` pointer file, then a checkout carrying `projects/` beside the
engine, then `$HOME/.felix`. A plugin cache copy is explicitly never adopted as
a home, and the comment says why: it would govern from a constitution frozen at
install time and write memory into a directory the next plugin update deletes.

**A real checkout to install from.** `cmd_install`
(`engine/harness/felix:257`) refuses when it cannot find a Felix checkout to
deploy from, with the message "this is the deployed copy of Felix, not a
checkout of it". So a tarball of `engine/` is not enough. Riyan needs a git
checkout.

He needs no part of `projects/felix/`, `projects/veldra/`, `HANDOFF.md` or
`docs/`.

### 4b. Why the split is clean, verified rather than assumed

`grep -rn elenchus engine/` returns **zero** hits outside
`engine/harness/tests/run`, and inside that file the hits are the invariant test
itself: `tests/run:9591` fails the suite when the gate's code names any project
literally. This is invariant 1 from `HANDOFF.md:47`, and it is mechanically
enforced rather than merely intended. The engine genuinely does not know what
Elenchus is.

That is what makes a distribution repository possible at all. It is also the
same property `HANDOFF.md:47` names as the eventual open source path.

### 4c. The trap in the obvious version

`HANDOFF.md:52` records it plainly: **a path filter does not filter prose.** 21
of the 105 commits touching `engine/` name the other project in their messages,
and messages travel with commits. For a public release that matters. For Riyan
it matters less, since he is working on Elenchus, but the same filter would also
carry every commit message about Veldra and about founder decisions.

The fix is to not carry history at all.

### 4d. The options, ranked

**1. Private distribution repository, squashed per release. Recommended.**

A new private repository, `LeavesJ/felix-dist` or similar, containing
`.claude-plugin/marketplace.json`, `engine/`, and `projects/elenchus/`. No
history: each release is one commit that replaces the tree. Riyan gets read
access.

What he sees: exactly what he runs. What leaks: nothing. How you ship: a sync
script plus a version bump, which is the deployment anyway
(`HANDOFF.md:3699`, "the bump *is* the deployment"). How he pulls: `git pull`
then `felix install`. The gate still works because `projects/elenchus/gate.sh`
is in the tree and `project.json` declares it.

The one honest cost is that you now maintain a publishing step. It is small,
and §7 gives it.

**2. Read only collaborator on `LeavesJ/felix`. Not recommended.**

Simplest to set up and it hands over `HANDOFF.md`, `projects/veldra/`,
`projects/felix/` and `docs/`. GitHub has no path level read scoping, so there
is no way to narrow it after the fact. If you take this option anyway, take it
knowing that 4061 lines of standing strategy went with it.

**3. SSH deploy key on `LeavesJ/felix`. Not recommended for a person.**

This is what CI already does (`gate.yml` uses `secrets.FELIX_DEPLOY_KEY` for the
Felix checkout), and it proves the mechanism works. As a grant to a human it has
the same exposure as option 2 with worse revocation, because a deploy key is a
shared bearer secret rather than an identity.

**4. Tarball or release artifact. Rejected on mechanics.**

`cmd_install` refuses to deploy from anything that is not a checkout, so this
does not work without also making it a git repository, at which point it is
option 1 with a worse update path.

### 4e. Building option 1

Do this in Phase A, before Riyan has any access, so a mistake costs nothing.

```
# 1. New private repo, no history carried over.
mkdir -p /tmp/felix-dist && cd /tmp/felix-dist && git init

# 2. Sync exactly three things from the Felix checkout.
rsync -a --delete <felix>/engine/ ./engine/
rsync -a --delete <felix>/projects/elenchus/ ./projects/elenchus/
cp <felix>/.claude-plugin/marketplace.json ./.claude-plugin/marketplace.json

# 3. Prove nothing else came along.
grep -rniE "veldra|handoff|founder" . --exclude-dir=.git | head
git status --short
```

Then verify the invariant still holds in the distributed tree before the first
push:

```
grep -rn "elenchus" engine/ | grep -v "harness/tests/run" # must be empty
test -x engine/harness/felix                              # must succeed
test -f projects/elenchus/gate.sh                         # must succeed
```

`TODO(assumption)`: `projects/elenchus/maintenance.log` is committed on purpose
(`.gitignore:8` carries the `!projects/*/maintenance.log` negation with a comment
explaining that cadence is doctrine). Decide whether Riyan's copy starts from
yours or from empty. Starting from yours is the better default, because a
maintenance routine that resets to never-run is a routine that silently lapses.

---

## 5. The sequence

Six phases. Each phase says what to do, how to prove it worked, and what stops
you. **Do not start a phase before the previous one verifies.** The ordering is
not stylistic: phases A and B are reversible and phase C is not.

### Phase A. Prepare, with nothing sent

Nothing in this phase is visible to anyone but you. If you get something wrong
here you delete it and start again.

**A1. Build the distribution repository.** Per §4e. Do not push it yet.

**A2. Assemble the transfer bundle.** One directory, built by hand, containing
only what §3a marks as his:

```
handover/
  docs/                      # from Elenchus, reviewed file by file
  POSITIONING.md             # the one binding root document
  content-lift/
    scenarios.yaml
    candidates.yaml
  claude-config/             # .claude/, if you are sending it
  NOTES.md                   # anything that was only ever in your head
```

**A3. Read every file in the bundle.** This is the step that gets skipped and it
is the one that matters. `docs/` holds `DEVLOG.md` and `lessons.md` for a
project you have been running alone, and a devlog written for an audience of one
says things. Read for: credentials pasted into a log, invitee names or slugs,
anything about a person, and anything about Veldra or Felix strategy that is not
Riyan's business.

Verify mechanically as well as by eye, using Felix's own scanner rather than a
fresh regex:

```
<felix>/engine/harness/bin/secret-scan   # run against the bundle
grep -rniE "sk-ant|BEGIN [A-Z ]*PRIVATE KEY|api[_-]?key *=" handover/
```

**A4. Extract the Elenchus lessons.** From `~/.felix/memory/elenchus/lessons.md`,
pull the entries that are about the codebase and rewrite them as prose in
`handover/NOTES.md`. The file itself does not travel, per §3c. The onboarding
document already carries the ones this runbook could recover from the tracked
tree (`L-19` on the editable install, `L-22` on live test rot, `L-23` on piped
pytest, `L-2` and `L-26` on confidential documents), so you are adding what only
your memory root holds.

**A5. Confirm the inventory against your actual disk.** Every
`TODO(assumption)` in §3 becomes a fact here:

```
ls -la <elenchus>/*.md                        # the twelve, and which bind
ls -la <elenchus>/docs/
ls -la ~/.config/elenchus/ ~/.local/share/elenchus/data/
cat <elenchus>/.git/info/exclude
cd <elenchus> && git status --short --untracked-files=all | head -50
```

That last command is the real inventory. It lists exactly what is in your
checkout and not in the repository, which is the question this whole section is
asking.

**Stop.** Do not continue until the bundle is read and the scanner is clean.

### Phase B. Grant access, still reversible

**B1. Push the distribution repository** as a private repo. Add Riyan with
`read`.

**B2. Add Riyan to `LeavesJ/Elenchus` with `write`.** Per D4. Confirm he did not
end up with `admin`.

**B3. Confirm branch protection on `main` is intact** and that `gate` is still
the required status check. Adding a collaborator does not change it, and
checking takes ten seconds.

**B4. Issue his Anthropic key** on his own workspace with its own spend limit,
per D3. Send it through a channel that is not the same channel as anything else
in this handover.

**Verify:** ask Riyan to confirm he can clone both repositories and can see
neither `HANDOFF.md` nor `projects/veldra/`. If he can see either, D1 was
misapplied and you stop here.

**Stop.** Everything to this point can be undone by removing two collaborator
seats and revoking one key.

### Phase C. Transfer the bundle

This is the irreversible phase. After it, the internal documents exist on a
second machine.

**C1. Send `handover/` through an encrypted channel.** Not email, not a shared
drive link that outlives the transfer, and not a channel that indexes content.
An age or GPG encrypted archive over any transport is fine, because the archive
is the boundary rather than the transport.

**C2. Confirm receipt and integrity** by checksum, not by "got it".

**C3. Tell him where each piece goes**, which the onboarding document already
says: `docs/` and `POSITIONING.md` to the repo root, the two lift banks to
`content/lift/`, and neither ever gets staged.

### Phase D. Riyan's first green gate

He follows `docs/2026-09-06-riyan-onboarding.md`. Your job in this phase is to
be reachable, because two of these steps fail in ways that are not
self-explanatory.

The finish line is one command producing one line:

```
<felix-dist>/engine/harness/felix gate
# gate: pass
```

**What fails first, and what it means.** These are the ones worth pre-empting
rather than debugging live.

- `felix which` says no project governs the directory. The home is wrong. It is
  `$FELIX_HOME`, then `~/.felix-home`, then a checkout with `projects/` beside
  the engine, then `~/.felix` (`resolve.sh:131`). `felix install --home <dist>`
  writes the pointer (`engine/harness/felix:288`).
- The `secret` check prints `skipped (run through felix gate to enable)`. He ran
  `gate.sh` directly instead of through `felix gate`, so `$FELIX_BIN` was unset
  (`projects/elenchus/gate.sh:162`). This is exactly the failure `deny.tsv` row
  one exists to stop, and it is the one that has already cost a day.
- The suite fails on imports. He is relying on the editable install. Everything
  runs with `PYTHONPATH=src`, per `README.md` Develop and L-19.
- The `installed` check is red. The engine tree and the deployed cache disagree.
  On Riyan's machine this should not happen, because he never edits the engine.
  If it does, it means the distribution repo moved without him re-running
  `felix install`.
- `lift-bank` or `confidential` fails. He staged something from the bundle. This
  is the gate doing its job, and it is worth him seeing once.

`TODO(assumption)`: Python 3.14 is what CI pins (`gate.yml`, `python-version:
'3.14'`) while `pyproject.toml` declares `requires-python = ">=3.12"`. Riyan
should match CI at 3.14 rather than the floor, and L-19 (editable install
unreliable on 3.14) is the reason the `PYTHONPATH=src` rule exists at all.

### Phase E. First pushed commit

The point of this phase is that his first commit exercises the whole chain
while the change itself is trivial enough that nothing is at stake.

He picks something genuinely small, declares T0, runs `felix gate`, commits with
an explicit path list, and pushes a branch on the origin repository. Then
watch CI: `gate` must run the harness path rather than the fork path. If the
job logs "the private harness is unreachable", he pushed from a fork and D4 was
not applied.

Two doctrine points he will get wrong once and should get wrong here rather than
later, both from `projects/elenchus/CLAUDE.md` Delivery: a `docs/DEVLOG.md`
entry rides in the same change, and no `Co-Authored-By` trailer goes in an
Elenchus commit.

### Phase F. Cut over

**F1. Agree the boundary in writing.** Riyan owns Elenchus development. You own
Felix, the beta, and every credential. T3 in `projects/elenchus/CLAUDE.md` is
the escalation list and it already names the right things: stable identifier
meaning changes, durable state migrations, secrets and the public tracked set,
history rewrites, and any conflict between his design and your instruction.

**F2. Move `projects/elenchus/` ownership deliberately.** It is the gate
contract and it lives in Felix, which he cannot push to. Decide now whether a
gate change is a request to you or whether the distribution repo becomes
writable for that one directory. Requesting is the smaller change and the better
default while the arrangement is new.

**F3. Set the maintenance cadence.** `projects/elenchus/maintenance.tsv` drives
the "Maintenance due" line the session start hook prints. Under a handover those
routines change owner, and a routine whose owner changed silently is a routine
that lapses.

---

## 6. What Riyan never receives, and why

Worth stating as a list, because each of these is something a helpful person
would send without thinking.

- **`~/.felix/memory/` in any form.** Verbatim founder prompts, by the design
  note at `resolve.sh:175`.
- **`data/elenchus.db`.** Your own 19 sittings, per `web/runtime.py:54`. Your
  personal decision history.
- **`~/.local/share/elenchus/data/tenants/*`.** Beta invitees' writing.
  Disclosure, not file transfer.
- **Your `ANTHROPIC_API_KEY`,** from `.env` or `~/.config/elenchus/env`.
- **`~/.cloudflared/cert.pem` and tunnel credentials.** These authorize DNS on
  your domain (`serve_invitee.py:204`).
- **`HANDOFF.md`, `projects/felix/`, `projects/veldra/`, Felix `docs/`.**
- **The eleven non binding root strategy documents.**

If Riyan later needs something on this list, that is a new decision taken on its
own merits, not an extension of this one.

---

## 7. Steady state: two people, one private engine

### Shipping a Felix change to Riyan

The loop is four steps and only the last is new work:

1. Develop in `LeavesJ/felix` as you do today.
2. `felix install`, which bumps `engine/.claude-plugin/plugin.json` when the
   tree differs and the version did not. The bump is the deployment
   (`HANDOFF.md:3699`).
3. Sync and push the distribution repository, per §4e.
4. Riyan pulls and runs `felix install`.

Step 4 is the one that will be forgotten, and the failure is quiet: his sessions
keep running the engine version he installed last. Two properties of the system
make this survivable. Hooks bind at session start
(`HANDOFF.md:3690`), so a stale engine is stale for a whole session and then
notices. And the `installed` gate check compares his tree against his deployed
cache, so a pull without an install turns his next gate red rather than letting
him ship against a contract he does not have.

### The version skew that has no guard

`plugin.json` carries a version, but nothing checks that
`projects/elenchus/gate.sh` and the engine are from the same release. Since your
sync always ships both together as one commit, a squashed distribution
repository makes this structurally impossible rather than merely unlikely. That
is a second reason to prefer option 1 over a collaborator seat, where he could
pull a partially updated tree.

### The feedback loop, and what you lose

Felix's records are per machine and live in the memory root. Once Riyan is doing
Elenchus development, his `lessons.md`, `mistakes.log`, `ledger.tsv` and
`routes.log` accumulate on his disk, and you will not see them. The declared
objective in `HANDOFF.md:3379` is founder interruptions per session, measured
from `says.log`. After the handover most Elenchus sessions are his, so that
number stops measuring what it used to measure.

Two mechanisms already in the tree are worth pointing at him rather than
building anything new. `felix lesson` writes to `lessons.md`, which is how a
lesson gets matched into future prompts instead of being lost in a commit
message (`HANDOFF.md:4052` records this exact failure mode). And `felix pulse`
backs the memory root up to a git remote, refusing loudly rather than silently
(`engine/harness/lib/pulse.sh:117`). Riyan should have his own private backup
remote from day one, because the alternative is that every lesson he pays for
exists in exactly one place, which is the state
`HANDOFF.md:60` already flags as undecided for you.

**Do not point his pulse at your memory remote.** It would merge his record into
yours and hand him yours.

---

## 8. Rollback

Reversibility drops sharply after Phase C, so the honest answer differs by
phase.

**Before Phase C**: delete the distribution repository, remove both collaborator
seats, revoke the key. Nothing was disclosed.

**After Phase C**: the bundle exists on another machine and cannot be recalled.
What you can still do is revoke access going forward and rotate anything
credential shaped. If you find after the fact that something sensitive was in
`docs/`, treat it as a disclosure to one known person and handle it as such,
which mostly means rotating whatever it named.

**Any phase, if the beta is implicated**: nothing in this runbook grants access
to invitee data under D2, so a handover mistake should never reach it. If one
somehow does, `scripts/forget_invitee.py` is the deletion path and it prints the
by hand steps it cannot perform itself.

---

## 9. Open questions only you can answer

1. Does Riyan get `projects/elenchus/` write access eventually, and through what
   mechanism? (§5 F2)
2. Does his `maintenance.log` start from yours or from empty? (§4e)
3. Which of the twelve root documents are drafts you would rather not hand over,
   beyond keeping `POSITIONING.md`? (§3a)
4. Is `.env.example` added to Elenchus? (D5, T3)
5. Does the beta stay entirely yours indefinitely, or is there a date where
   Riyan takes it with the invitees told? (D2)
6. Does the distribution repository get its own `HANDOFF.md` for Riyan, so his
   standing direction accumulates the way yours does? The session start hook
   already reads `<repo_root>/HANDOFF.md` when present
   (`engine/harness/hooks/session-start`, the `read_lines` block), so the slot
   exists and is currently empty for him.
