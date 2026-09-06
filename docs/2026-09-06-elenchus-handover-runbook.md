# Elenchus handover runbook

Written 2026-09-06. The operator of this runbook is J. It is the private half of a
two document handover: this file says what to do and in what order, and
`docs/2026-09-06-riyan-onboarding.md` is the document Riyan actually receives.

**Do not paste from this file.** It is the reasoning record: why each step is
what it is, what was measured, and what was reversed. The thing you execute is
`docs/2026-09-06-handover-setup.md`, whose command blocks are written for zsh
and contain no angle brackets and no `#`, because both are errors rather than
placeholders in an interactive shell. Blocks here still carry both, some of them
show sample output rather than commands, and §4e is a recipe that was built,
verified and then deliberately not used.

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
3. **Beta operations.** Per-invitee databases hold real decisions written by
   real people. That is third party personal data and it is the one thing in
   this handover that cannot be un-sent.

   **How many people is unresolved and it matters.** This paragraph said "eight
   or so" from an early reading; on 2026-09-06 the founder said nobody has been
   invited yet, and `2026-09-06-riyan-onboarding.md:27` tells Riyan the beta has
   been running one invited person per instance since 2026-09-05. Those cannot
   all hold. The answer is load-bearing rather than cosmetic: §3c sends
   `SESSION_HANDOFF.md` on the specific ground that no invitee material has
   accumulated in it yet, and that ground evaporates if eight people have sat
   down. Section 1 of `2026-09-06-notes-template.md` asks for the real sentence,
   and every document gets corrected from it.

The recommendation running through this entire document is that these three
separate cleanly, and that separating them is what makes the handover safe
rather than merely fast.

---

## 2. Decisions to take before step one

Take these seven now. Every phase below assumes an answer, and reversing one
mid-sequence is where a handover leaks. D0 is a prerequisite rather than a
preference, so it comes first.

### D0. Put Riyan inside the license before he writes a line

**This is a prerequisite rather than a preference, and none of the first three
drafts of this document mentioned it.**

Elenchus's tracked `LICENSE` is source available, not open source. Section 5(b)
forbids "You" from modifying, adapting, creating derivative works of, or
preparing patches for the Materials, and section 6 says "Do not submit pull
requests or code contributions unless Owner agrees otherwise in writing."

The license already anticipates exactly this situation, which is why it is a
step and not a blocker. Section 1 defines the term: **"'You' does not include
Owner's founders, employees, contractors, or agents acting on Owner's behalf,"**
and section 6 repeats the carve-out explicitly. So the whole handover is
lawful the moment Riyan is inside that category, and outside it every commit he
makes is one the license tells him not to make.

So: a contractor agreement, employment, or a written engagement as an agent of
Elenchus Labs, Inc., **dated before Phase B1**. An earlier draft said "before
Phase E" and named Phase C in the same sentence as the moment he first takes
possession, which was two deadlines in one paragraph. B1 is the right one and it
is the earliest: it is the first thing this handover does that the license has an
opinion about. Section 3 permits viewing and running for Internal Evaluation
regardless, so nothing before B1 is at risk, and section 5(b) makes his first
commit the hard line.

**Answered 2026-09-06: yes.** Riyan holds high authority in Elenchus and J will
say so. One thing remains, and it is the whole point of the carve-out: the
license turns on a *capacity*, not on a shared understanding. Put it in writing
with a date, before Phase E. A one paragraph engagement letter is enough, and
"we both knew" is not what section 1 asks for.

**Updated 2026-09-06: Elenchus Labs, Inc. is already incorporated, and Riyan is
legally a cofounder, not only a working title.** This changes which half of the
letter is load bearing and opens one question the letter has not yet answered.

`LICENSE:12` excludes "Owner's founders" from "You" as its own, first-listed
category, independent of "contractors" or "agents". If Riyan is a legal cofounder
of the entity that holds the copyright, he is covered by that clause directly.
The engagement letter's section 2, which reaches him through the contractor and
agent prongs instead, is no longer the operative reasoning. It does no harm left
as written, but it is not what is actually doing the work.

**What does not change, and may matter more than before, is section 3.** Being a
cofounder does not by itself assign his code to the company. That is a distinct
legal act, and it is exactly why standard incorporation packages (Clerky, Stripe
Atlas, Cooley GO, and similar) have each founder separately sign a founder IP or
invention assignment agreement at formation: a cofounder owes the company no
automatic assignment duty the way an employee typically does, absent one.

**Answered 2026-09-06: yes, and it is signed.** J confirmed the Stripe Atlas
incorporation package includes "Form of Employee CIIAA for Riyan Jain" under
Documents → Ownership, alongside his stock certificate, RSPA and 83(b) filing,
and confirmed it carries an actual signature rather than sitting as a generated,
unsigned form.

**This resolves D0 more completely than the question anticipated.** Not only is
section 3 redundant, so are sections 1 and 2. Riyan has held founders' stock
since incorporation, so `LICENSE:12`'s founder exclusion has very likely applied
to him from that date, self-executing, needing no side letter at all. The
contractor-engagement letter was solving a problem the incorporation had already
solved before this handover began.

**The document was rewritten rather than relabeled.** `2026-09-06-riyan-
engagement-letter.md` dropped the engagement, authorisation and IP-assignment
sections entirely and kept only what a founder CIIAA does not reach: Felix
confidentiality (Felix governs more than one venture, and whether Elenchus
Labs, Inc.'s CIIAA extends to a different venture's material is not something
to assume), the beta and invitee-data restriction (a promise about third
parties, never an IP question), and one line on credential handling. Three
short clauses, not eight.

### D1. How Riyan gets Felix

**Decided 2026-09-06: a read only collaborator seat on `LeavesJ/felix`.**

This reverses the recommendation the earlier drafts of this document carried, and
it reverses it because D4's answer changed the facts rather than because the
earlier reasoning was sloppy. Both are recorded, because a plan that hides its
own reversal is harder to trust than one that shows it.

**The earlier recommendation was a private distribution repository** holding only
`engine/` and `projects/elenchus/`, on the grounds that a seat on `felix` hands
Riyan `HANDOFF.md`, `projects/veldra/` and `projects/felix/`, none of which he
needs. That reasoning was sound and the unit was built and verified (§4e). It
rested on one assumption that turned out to be false: that the boundary it drew
was a boundary at all.

**What changed.** Riyan already holds `write` on Elenchus, and `write` on
Elenchus is read on `felix` through CI (D4b). So the distribution repository
would have been withholding something he could already fetch, at the cost of a
sync step on every Felix change, forever. Paying maintenance for a boundary that
does not hold is the worst of both.

**Why read on `felix` is positively better, not merely equal.** One copy of the
gate contract exists. Riyan reads `felix` and CI reads `felix`, so the two cannot
disagree in content, only in time, and `git pull` closes that. The two sources of
truth problem in §7 does not exist under this decision. There is also no
publishing step: what you push is what he gets.

**What he sees that he does not need.** `HANDOFF.md`, 4061 lines of working
notes, candid about what this project keeps getting wrong. `projects/veldra/`, 79
lines revealing that ReserveGrid OS exists and is a Rust verification stack for
Bitcoin mining pools at `LeavesJ/ReserveGrid-OS`. Confirmed acceptable
2026-09-06.

**The one forward looking cost, worth naming because nothing will announce it.**
The grant widens by itself. Add a fourth project to `felix`, or a client's, and
Riyan reads it the day it lands, with nobody deciding. §4e keeps the distribution
recipe intact and verified for the day that matters.

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

Three facts make that future decision harder than it looks. They are worth
writing down now, while they are in view, because each would otherwise have to
be rediscovered on the day the beta actually moves.

**There is no invitee registry in the code.** Every operator script enumerates
invitees by globbing the tenant root: `scripts/retention_report.py:35` globs
`*/elenchus.db` and `scripts/call_report.py:36` globs `*/server.log`. Nothing in
`src/` holds a name, an email, or a list.

**The invitee allocation table lives inside the memory root.**
`src/elenchus/forget.py:166` names it directly: one of the by-hand deletion
steps is "Remove `<slug>` from the invitee allocation table in the session
handoff." Felix writes `SESSION_HANDOFF.md` per project into the memory root
(`engine/harness/lib/memory.sh:77`), which is the one directory §3c says never
travels. So the beta's authoritative record of who exists sits inside the
directory that is off limits. Under D2 that is fine and even tidy. On the day
D2 is revisited, that table has to be extracted deliberately rather than moved
with anything else.

**Cloudflare Access holds the email addresses, and deletion cannot reach them.**
`forget.py:163` is explicit: the Access application "carries this person's EMAIL
ADDRESS in its policy, and this script cannot reach it." So the script prints
three by-hand steps and reports success without having done them, which means
the same-day deletion promise in the README depends on an operator completing
work the tool announces but does not perform. That is a known and stated gap
rather than a hidden one, and the handover is a reasonable moment to close it,
but closing it is Elenchus work and not part of this sequence.

Together these say the same thing three ways: handing over the beta is not a
file transfer. It is a transfer of a Cloudflare account, a directory of other
people's writing, and a table that lives somewhere nothing else should follow.
That is the strongest argument for leaving D2 where it is.

### D3. Anthropic billing

**Recommendation: Riyan gets his own key on his own workspace with his own
spend limit. Your key never moves.**

A shared key makes spend unattributable, which is the exact confounding
`HANDOFF.md:3937` records deciding against for the pentest provider. It also
means a leak from either machine burns both. Issue him a key scoped to a
workspace you can cap and revoke independently.

### D4. Riyan's GitHub role on Elenchus

**Answered 2026-09-06: already done.** `InsertWittyCommentHere` is Riyan, and he
already holds `write` on `LeavesJ/Elenchus`. So B0 and B2 in the sequence
collapse to a confirmation, and there is nothing to grant.

The recommendation stood at `write`, pushing branches directly, not a fork and
not `admin`, and the current state matches it. The reasoning below still matters
because it explains what he must not do, not what you must set up.

**And it means D4b is not a future risk. It is the state today.**

Forks are actively worse here, for two mechanical reasons rather than a
preference. The second one is the decisive one and it was tested rather than
reasoned about.

**A fork checkout is not governed by Felix at all.** Elenchus carries no `.felix`
marker file, so it binds purely by `remote_match` in
`projects/elenchus/project.json`, which is the literal string `LeavesJ/Elenchus`.
Verified 2026-09-06 by cloning Elenchus, pointing `origin` at a fork URL, and
running the real CLI:

```
felix: no project governs <checkout>.
  Either add a .felix file naming one, or declare remote_match in a project.json.
  Known projects: elenchus
```

No constitution, no gate, no session binding, nothing. Riyan on a fork gets
ungoverned sessions and does not necessarily notice, because Felix stays quiet
in repositories it does not govern by design.

**And CI degrades.** `gate.yml` decides from the event whether the private
harness is reachable, and a pull request from a fork gets `harness=no`, which
runs format, lint and the suite while skipping `confidential`, `secret`,
`lift-bank`, `ignore-leak` and `inversion`. The workflow announces that itself in
its final step.

So: branches on the origin repository, which `write` permits.

**The escape hatch, if a fork ever becomes necessary.** The error message names
the remedy and it works, also verified: `printf 'elenchus\n' > .felix` at the
checkout root restores full binding, doctrine, gate and memory. Note that
`.felix` is not in Elenchus's `.gitignore`, so it shows up as an untracked file.
That is harmless for the gate, whose `inversion` check filters untracked entries
(`projects/elenchus/gate.sh:200`), but it is one more untracked thing in a
repository that already has opinions about those. Prefer the origin branch.

`admin` is not needed for anything he does and would let him change branch
protection, which is the one enforcement Elenchus actually has
(`HANDOFF.md:3710` records that Felix's own repository cannot have it).

### D4b. Write on Elenchus is transitively read on Felix

**This one undercuts D1 and has to be settled with it rather than after it.
Since D4 is already answered, this is not a decision about what to allow. Riyan
can read the whole of `LeavesJ/felix` today, through CI, and could before this
handover began.**

D1 spends real effort keeping `HANDOFF.md` and two other projects away from
Riyan. D4 then grants him `write` on Elenchus, which hands him a route to the
whole of `LeavesJ/felix` anyway. The route is CI.

Both Elenchus workflows check out the private repository with a deploy key:

- `.github/workflows/gate.yml:73` on `pull_request` and on `push` to `main`
- `.github/workflows/unattended.yml:57` on `workflow_dispatch`

both with `repository: LeavesJ/felix` and
`ssh-key: ${{ secrets.FELIX_DEPLOY_KEY }}`.

A `pull_request` from a branch **in the same repository** runs the workflow file
as it exists on that branch, with repository secrets available. `gate.yml`'s own
fork guard confirms this by inverting it: it computes `harness=no` only when
`head.repo.full_name != github.repository`. So a write collaborator can push a
branch that edits the workflow, open a same-repo pull request, and have CI check
out the private repository under a step of their choosing. No review is needed,
because the workflow runs before review. Branch protection on `main` does not
help, and neither would a `CODEOWNERS` entry on `.github/`, since neither gates
the pull request event itself.

This is not a claim that Riyan would do it. It is a claim that the boundary D1
draws is not actually enforced by anything, and a boundary you believe in but do
not have is worse than one you know you lack.

**Resolved 2026-09-06 by D1, and no CI change is needed.**

Once Riyan holds read on `felix` deliberately, the CI route stops being an
escalation and becomes a second path to access he already has. Both workflows
stay exactly as they are. `FELIX_DEPLOY_KEY` stays pointed at `felix`. There is
nothing to fix, because there is no longer a gap between what the boundary says
and what it does.

Two options were live before D1 was decided, and they are recorded because they
become relevant again the moment the answer to D4 changes, which it will if
anyone else ever gets `write` on Elenchus.

**Point CI at a distribution repository.** Change both workflows to check out a
narrowed repo with its own deploy key. A workflow-file exploit then reaches only
what the collaborator already holds. Costs a sync step that becomes load bearing
for a public repo's required status check.

**Put `FELIX_DEPLOY_KEY` behind a protected Environment** with you as required
reviewer, so the secret is issued only after you approve the job. Keeps CI on
`felix` and puts you in the loop on every pull request, which is friction this
project's own doctrine would call a defect.

**The standing rule this leaves behind:** `write` on Elenchus is read on `felix`.
Grant the first only to someone you would grant the second, or take one of the
two fixes above first. Nothing in either repository enforces this, so it lives
here.

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

A second untracked corpus belongs in that table and is easy to miss because
`.gitignore` covers it only through the blanket `/data/` rule:
**`data/injection_payloads.yaml`**, read at
`src/elenchus/run_injection_probe.py:88`. The tracked stub is
`content/gate/injection_payloads.example.yaml`, which is what the tests use
(`tests/test_injection_probe.py:51`).

Treat this one as its own class rather than as corpus. The stub's own header
says what it is: "The real corpus lives at `data/injection_payloads.yaml` and is
GITIGNORED on purpose: a payload that works is a live exploit against our own
grader, and this repo is public." The tracked example is deliberately inert and
carries no column-0 structure so admission rejects it. So the real file is a set
of working attacks against the grader of a public product. Send it only if Riyan
is going to work on the injection probe, send it in the same encrypted archive
and never separately, and say plainly what it is when you do. A `git add -f` on
this file publishes live exploits, which is one of the three things `deny.tsv`
exists to prevent.

Three of these rows are the ones to slow down on.

**`docs/` is the highest value thing in the bundle, and the number says so.**
Tracked code cites **27 distinct lesson identifiers a total of 252 times**
across `src/`, `tests/`, `scripts/` and `projects/elenchus/`, and the file those
identifiers resolve to is not in the repository. Without `docs/lessons.md`
Riyan reads 252 dangling references to reasoning he cannot reach. This is the
single item whose absence would most slow him down, and it is also the one that
most needs reading before it is sent, per Phase A step 3.

**`content/lift/*.yaml` unblocks the lift pipeline, and nothing else.** This
correction matters because the obvious reading is stronger than the truth.
`content_loader.load_lift_scenarios` and `load_lift_candidates`
(`src/elenchus/content_loader.py:259` and `:264`) default to the untracked bank
names, but **no tracked caller invokes them with those defaults**: the only
callers are `tests/test_content_loader.py:243`, which passes
`"scenarios.example"`, and `:278`, which passes an explicit `root`. So the suite
is green without them and day to day development does not touch them. They are
needed for lift and mining work specifically. The gate still fails if either
real bank is ever tracked (`projects/elenchus/gate.sh:175`), so they move out of
band and stay out of band.

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

**Corrected 2026-09-06, and this correction matters more than the rule it
replaces.** Earlier drafts of this section said "no memory directory is copied
to Riyan," full stop. That rule is unworkable, and it was unworkable from the
moment it was written, because **three of the memory root's files are already
surfaced into the Elenchus repository as symlinks**:

```
docs/lessons.md          -> ~/.felix/memory/elenchus/lessons.md
docs/DEVLOG.md           -> ~/.felix/memory/elenchus/DEVLOG.md
docs/SESSION_HANDOFF.md  -> ~/.felix/memory/elenchus/SESSION_HANDOFF.md
```

All three created 2026-08-18, observed directly. So the file this handover kept
calling the single highest-value item in the bundle, the one 252 code comments
cite, **is** a memory-root file. "Nothing under `~/.felix/memory/` travels" and
"send `docs/lessons.md`" were asserted in the same document and cannot both
hold.

**The rule that actually holds, and it is J's own, not an invention of this
document.** Felix writes nine or so files per project into the memory root. J
symlinked exactly three of them into `docs/`, and left the rest alone. That
symlinking was the editorial judgment, made months before this handover: the
three authored files, the ones a person writes deliberately through
`felix lesson`, `felix log` and `felix handoff`, are project documentation. The
raw logs are not.

So:

| Memory-root file | Travels? | Why |
|---|---|---|
| `lessons.md` | **yes**, as contents | authored prose, cited by 252 code comments |
| `DEVLOG.md` | **yes**, as contents | authored prose, required by the constitution |
| `SESSION_HANDOFF.md` | **yes**, as contents | authored prose, confirmed clean 2026-09-06 |
| `routes.log`, `says.log` | never | verbatim text typed at a prompt |
| `mistakes.log`, `verification.log`, `ledger.tsv` | never | machine records, per machine |
| `unresolved.log` | never | written at the root, spans every governed project |

`felix_mem_dir` (`resolve.sh:216`) keys on the project's directory name, so the
per-project trees are separable, but `unresolved.log` sits at the root
(`resolve.sh:399`) and spans everything Felix governs. That is why "send the
Elenchus subdirectory" is still wrong even now. What travels is three files, by
name, as contents.

**As contents, never as links.** A `cp -R` over `docs/` preserves symlinks, so
Riyan would receive three dangling pointers into `/Users/a14808/` that resolve
to nothing on his machine. The allow-list copy in Phase A2 dereferences because
it names files individually without `-R`, which is correct by construction
rather than by luck once you know why.

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

**The shortcut that looks sufficient and is not.** `claude plugin marketplace
add` accepts an `owner/repo` form, so once the distribution repository exists it
is tempting to tell Riyan only that, and skip the clone. Do not. The plugin
carries `engine/` alone, `projects/` never enters the cache, and a cache copy is
explicitly refused as a home. He would end up with a working `felix` command,
no constitution, no gate, and no error saying so, because Felix stays silent in
anything it does not govern. The clone plus `felix install --home <clone>` is
the whole install, not the long way round.

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

### 4d. The options, ranked as they stood before D1 was decided

**Read this as history plus a recipe, not as a live recommendation.** D1 chose
option 2. The ranking below was written when the boundary was believed to hold,
and it is kept because the moment a second person gets `write` on Elenchus, or a
fourth project lands in `felix`, option 1 is what you reach for and §4e is how
you build it in twenty minutes.

**1. Private distribution repository, squashed per release. Was recommended.**

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

**2. Read only collaborator on `LeavesJ/felix`. CHOSEN, see D1.**

Simplest to set up, and it hands over `HANDOFF.md`, `projects/veldra/`,
`projects/felix/` and `docs/`. GitHub has no path level read scoping, so there is
no way to narrow it after the fact, and the grant widens on its own as `felix`
grows. Confirmed acceptable 2026-09-06.

What tipped it, once D4 was answered, is that this option has a property none of
the others do: **there is exactly one copy of the gate contract.** Riyan reads
`felix`, CI reads `felix`, you edit `felix`. They cannot disagree in content,
only in time, and `git pull` closes that. Every other option here creates a
second copy and then needs a discipline to keep the two in step.

Riyan's install becomes:

```
git clone git@github.com:LeavesJ/felix.git ~/felix
cd ~/felix && ./engine/harness/felix install --home ~/felix
```

Read is genuinely sufficient. Felix writes into `<home>/state/` for gate
receipts, route memory, pulse and discovery, and `state/` is gitignored
(`.gitignore:27`), so nothing it writes ever wants a push. His lessons, ledger
and session handoffs go to `~/.felix/memory/`, outside the clone entirely.

One surprise to pre-empt: his clone carries all three projects and `felix`'s own
`.felix` marker names `felix`, so opening the felix clone itself in Claude Code
binds that session to the Felix project and shows him its constitution. Harmless,
and it looks alarming the first time.

**3. SSH deploy key on `LeavesJ/felix`. Not recommended for a person.**

This is what CI already does (`gate.yml` uses `secrets.FELIX_DEPLOY_KEY` for the
Felix checkout), and it proves the mechanism works. As a grant to a human it has
the same exposure as option 2 with worse revocation, because a deploy key is a
shared bearer secret rather than an identity.

**4. Tarball or release artifact. Works, and still rejected.**

An earlier draft rejected this on mechanics and was wrong. Tested 2026-09-06: a
distribution tree with its `.git` removed entirely still resolves correctly,
`felix which` names `elenchus`, and doctrine, gate and memory paths all come out
right. `felix_repo_root` falls back to the directory itself outside git, and
`cmd_install`'s refusal is aimed at a plugin cache copy specifically, not at the
absence of a repository.

Reject it for the real reason instead: **there is no update path and no way to
tell which version you are holding.** Every Felix change becomes an archive to
build, send, and unpack by hand, and nothing in the tree records where it came
from. Option 1 is the same thing with `git pull`.

### 4e. Building option 1, and the run that proved it

**This was executed end to end on 2026-09-06 against the real trees, not
reasoned about.** The output of each step is below so you can compare rather
than guess.

Do this in Phase A, before Riyan has any access, so a mistake costs nothing.

```
# 1. New private repo, no history carried over.
mkdir -p ~/felix-dist && cd ~/felix-dist && git init
mkdir -p .claude-plugin projects

# 2. Copy exactly three things from the Felix checkout.
cp -R <felix>/engine              ./engine
cp -R <felix>/projects/elenchus   ./projects/elenchus
cp    <felix>/.claude-plugin/marketplace.json ./.claude-plugin/marketplace.json
```

`cp -R` rather than `rsync`, deliberately. `rsync` is absent from some
environments and this step must not depend on one; if you use `rsync -a --delete`
on your own machine for the re-sync in §7, that is fine and faster.

Result: **105 files, 1.8 MB.** For comparison the full Felix checkout carries
`HANDOFF.md`, `docs/`, `projects/felix/` and `projects/veldra/` on top of that.

**Step 3, the structural check.** All five must pass before the first push:

```
grep -rn "elenchus" engine/ | grep -v "harness/tests/run"   # must be EMPTY
test -x engine/harness/felix
test -f projects/elenchus/gate.sh
test -f projects/elenchus/project.json
test -f engine/.claude-plugin/plugin.json
```

Verified: the first grep returned empty, so invariant 1 survives the copy, and
all four files were present with the executable bit intact.

**Step 4, the leak check, and what it actually finds.** Run it and read it
rather than expecting silence, because it is not silent:

```
grep -rniE "veldra|berkeley|guidebook|founderceo" . --exclude-dir=.git
```

Three classes come back and only one of them is a decision.

- **`veldra`, three hits.** One is `veldra_ingest` at
  `projects/elenchus/CLAUDE.md:148`, which is an Elenchus module name that Riyan
  reads in the public source anyway. The other two are comment lines in
  `engine/harness/tests/run` (9440 and 9485) where the test's own prose explains
  why hard-coding a project name was wrong, and names Veldra as the example. Two
  comment lines in a 9000 line file. **This is the "a path filter does not filter
  prose" trap from `HANDOFF.md:52` appearing in the tree rather than in commit
  messages, which that entry did not anticipate.** Harmless here, and worth
  knowing you have decided rather than missed.
- **`guidebook` and `berkeley`, 37 hits**, across `evidence.tsv`,
  `maintenance.tsv`, `profiles.tsv`, `stack.tsv`, `risk.tsv` and the `setup/`
  documents. Every one is a page citation to the p41 guidebook as the source of a
  rule. No content travels, but Riyan gets page-number references to a document
  Elenchus's own `confidential` check is written to keep out of git
  (`projects/elenchus/gate.sh:145` greps for exactly these words). Decide whether
  he is told what the source is, or whether the citations read as noise to him.
- **Everything else: nothing.** No `HANDOFF.md`, no other project.

**Step 5, prove the thing actually governs.** This is the step that turns the
recommendation from an argument into a fact:

```
cd <elenchus-checkout>
FELIX_HOME=~/felix-dist FELIX_MEMORY=~/felix-mem \
  ~/felix-dist/engine/harness/felix which
```

Verified output:

```
project:      elenchus
doctrine:     ~/felix-dist/projects/elenchus/CLAUDE.md
memory:       ~/felix-mem/elenchus/
gate:         gate.sh
governs:      <elenchus-checkout>
```

Then the gate itself, through the same tree:

```
FELIX_HOME=~/felix-dist FELIX_MEMORY=~/felix-mem \
  ~/felix-dist/engine/harness/felix gate
```

Verified: **all five doctrine checks passed through the distribution tree**,
`confidential ok`, `secret ok`, `lift-bank ok`, `ignore-leak ok`, `inversion ok`.
Those five are precisely the ones a fork pull request cannot run, so this is the
proof that the distribution unit carries the real gate and not a subset of it.
`secret ok` in particular means `$FELIX_BIN` resolved and
`engine/harness/bin/secret-scan` travelled correctly, which is the check most
likely to degrade silently.

`format`, `lint` and `test` failed in that run because the machine it ran on had
no venv and no ruff. That is the expected shape of the failure and not a finding.

Two states surfaced that Riyan will meet on his first run and that are worth
pre-empting: `probes` reports one blind `http_route`, and `commission` reports
"never commissioned on this machine". Both are first-run states rather than
defects, and §5 Phase D lists them.

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

**A1. Nothing to build.** D1 chose read on `felix`, so there is no distribution
repository to assemble and Phase A is now only about the bundle. The recipe in
§4e stays valid and unrun, for the day D4b's standing rule bites.

**A2. Assemble the transfer bundle.** One directory, built by hand, containing
only what §3a marks as his:

```
handover/
  docs/                      # allow-listed from Elenchus, never a blanket copy
  POSITIONING.md             # the one binding root document
  content-lift/
    scenarios.yaml           # only if he does lift work
    candidates.yaml          # only if he does lift work
  data-corpus/
    injection_payloads.yaml  # ONLY if he works the injection probe. Live exploits.
  claude-config/
    CLAUDE.md                # the ONLY .claude/ entry that travels, see A2b
  ENVIRONMENT.md             # the local environment, written out from the code
  NOTES.md                   # anything that was only ever in your head
```

**A2 correction, from an actual `ls` of the checkout on 2026-09-06.** `docs/`
does not hold only `DEVLOG.md` and `lessons.md`. On this machine it also
contains `YC_answers.md`, `SESSION_HANDOFF.md`, and two subdirectories,
`admissions/` and `superpowers/`. `cp -R docs/. ~/handover/docs/` sweeps all of
it in without distinguishing any of them.

Each was checked rather than assumed to be excludable, and they did not all come
out the same way. `YC_answers.md` reads as YC application material and stays
out. `admissions/` holds entries like `withhold_your_best_product_from_funders.yaml`
and `cap_effort_on_your_best_prospect.yaml`, founder-strategy reflections rather
than engineering reference, and it stays out by default; open a couple yourself
if you think otherwise. `superpowers/plans/` and `superpowers/specs/` are a
different thing entirely: forty-some dated design and plan documents named
after real engineering surfaces (`harden-judgment-loop`, `cs-checkable-scorer`,
`injection-efficacy-probe`), with no strategic language anywhere in the list.
That is exactly the engineering history a new lead should have, and it goes in.

**`SESSION_HANDOFF.md` goes in, and an earlier draft of this paragraph got the
reason wrong.** That draft said it was "a different file from the one in §3c,"
distinguishing a checkout copy from a memory-root copy. There is no such
distinction. `docs/SESSION_HANDOFF.md` is a symlink to
`~/.felix/memory/elenchus/SESSION_HANDOFF.md`, verified 2026-09-06. One file,
two paths.

What actually justifies sending it is the fact J supplied, which holds
regardless of where the file sits: it contains no invitee material, because no
invitee exists yet. That is the load-bearing check, not the path. **If this is
ever revisited after the beta has real users, re-verify rather than inheriting
this answer**, because the file keeps accumulating and the reason it is clean
today is circumstantial.

**So copy `docs/` by allow-list, not wholesale**:

```
mkdir -p ~/handover/docs
cp docs/DEVLOG.md docs/lessons.md docs/SESSION_HANDOFF.md ~/handover/docs/
cp -R docs/spike-results ~/handover/docs/
cp -R docs/superpowers ~/handover/docs/
```

`TODO(assumption)`: this exact file list is one checkout's `docs/`, observed
once. A later session may hold different files. Re-run `ls docs/` before
building the bundle rather than trusting this list.

**A2b. `.claude/` is allow-listed too, and the reason is sharper than `docs/`.**
Its four entries, observed 2026-09-06, are `CLAUDE.md`,
`CLAUDE.md.pre-reset-2026-07-25`, `settings.local.json` and `worktrees`. Only
the first is project doctrine.

The pre-reset copy is superseded, and sending both hands Riyan two documents
with no way to tell which one binds. `settings.local.json` is the per-machine
permission allowlist, which is what `.local` means: it encodes paths under J's
home directory, Riyan's will differ, and he builds his own as he goes.
`worktrees` is the one with teeth. If it holds actual git worktrees, then
`cp -R .claude/.` sweeps entire checkouts into the bundle along with whatever
untracked files sit inside them, which is precisely the shape that defeats A3's
read-every-file. Look at it before deciding, and if it holds checkouts, leave it.

```
ls -la .claude/
cp .claude/CLAUDE.md ~/handover/claude-config/
```

**A2c. `ENVIRONMENT.md` is generated, not copied, and it is the answer to the
gap Riyan named.** He said he does not know the setup, and he is right that the
repository does not tell him: there is no `.env.example`, and the public README
covers install and two commands but not one environment variable.
`2026-09-06-elenchus-environment.md` in this directory is the whole local
environment read out of the tracked code on 2026-09-06, with a file and line
beside each claim: the six variables and their defaults, where the key goes,
which untracked file each command needs, and the asymmetry in §4 of that
document where `python -m elenchus.web` reads only `<repo>/.env` while the
launcher and preflight also honour `ELENCHUS_ENV_FILE`. That asymmetry is L-18's
shape and the code comments record it being paid for three times.

It names no secret value, so it carries no disclosure risk of its own, and it
could later become a tracked file. That is D5's question and not this step's.

**A3. Read every file in the bundle.** This is the step that gets skipped and it
is the one that matters. Even with the allow-list above, `DEVLOG.md` and
`lessons.md` are still a devlog written for an audience of one, and a devlog
written for an audience of one says things. Read for: credentials pasted into a
log, invitee names or slugs, anything about a person, and anything about Veldra
or Felix strategy that is not Riyan's business.

Verify mechanically as well as by eye. **The obvious way to do this does not
work, and it fails silently, so read this part before running anything.**

`secret-scan` takes a git base ref or `-` for stdin. It does not take a
directory. Pointed at the bundle it prints "no base ref found; scanning
uncommitted changes only" and **exits 0**, which reads exactly like a clean
bundle while having scanned a different tree entirely. Verified 2026-09-06
against a bundle with a live-shaped key planted in it.

The working invocation is stdin, and it keeps file and line attribution because
`grep -rn` puts them in the text:

```
grep -rnI '' handover/ | "$FELIX/engine/harness/bin/secret-scan" -
```

**And it has one blind spot that matters here more than anywhere else.**
`FELIX_SCAN_CONTEXT` (`engine/harness/bin/secret-scan:40`) lists
`ANTHROPIC_API_KEY` as a whole-line exclusion, so **any line containing that
string is skipped entirely**, including `ANTHROPIC_API_KEY=sk-ant-<a real key>`.
That exclusion is correct for the job the scanner was built for, which is reading
source diffs full of `os.environ["ANTHROPIC_API_KEY"]` lookups. It is exactly
wrong for a bundle, where a line copied out of a `.env` is the single most likely
way a key travels.

Measured, so you know what you are and are not covered for:

| Planted line | `secret-scan -` |
|---|---|
| `ANTHROPIC_API_KEY=sk-ant-...` | **missed** |
| `export ANTHROPIC_API_KEY="sk-ant-..."` | **missed** |
| a bare `sk-ant-...` in prose | caught |
| `aws_key = AKIA...` | caught |
| `BEGIN RSA PRIVATE KEY` | caught |
| `my_password = "..."` | caught |

So run both, and treat the second as the one that covers the gap:

```
grep -rnI '' handover/ | "$FELIX/engine/harness/bin/secret-scan" -
grep -rniE 'sk-ant-|sk-[A-Za-z0-9]{20}|AKIA[0-9A-Z]{16}|BEGIN [A-Z ]*PRIVATE KEY|ANTHROPIC_API_KEY[[:space:]]*=' handover/
```

The second will fire on any mention of `ANTHROPIC_API_KEY=` including harmless
ones. That is the right trade for one directory you are reading anyway.

Fixing the exclusion in Felix is not part of this handover. It is arguably not a
defect at all, because the scanner's designed input is a diff of tracked source
where that exclusion is load-bearing. It is a wrong tool for this one job, and
the second command is the fix.

**A4. There is nothing to reconcile. Verify the symlinks resolved, instead.**

Earlier drafts of this step had you diff `docs/lessons.md` against
`~/.felix/memory/elenchus/lessons.md` and merge any divergence, on the
assumption they were two files that might have drifted apart. They cannot
drift. `docs/lessons.md` is a symlink to the memory-root file, confirmed
2026-09-06, so `diff` is silent by construction and always will be.

What replaces the diff is a check that the copy actually dereferenced, since
that is the step that can genuinely go wrong. Check the whole bundle rather than
one directory: the three named files are copied without `-R` and so dereference,
but `spike-results` and `superpowers` are copied with `-R`, and `cp -R`
preserves a symlink found inside a directory instead of following it.

```
find ~/handover -type l
```

**It must print nothing at all.** Anything it prints is a pointer into
`/Users/a14808/` that resolves to nothing on Riyan's machine, and it fails
silently rather than loudly. Replace each one with its contents by copying the
target over the link, without `-R`.

Then confirm they are not empty, which a broken link would also produce:

```
wc -l ~/handover/docs/lessons.md ~/handover/docs/DEVLOG.md ~/handover/docs/SESSION_HANDOFF.md
```

`lessons.md` was 36475 bytes when observed. A near-zero line count means the
copy did not follow the link.

**A5. Confirm the inventory against your actual disk.** Every
`TODO(assumption)` in §3 becomes a fact here:

```
ELENCHUS=~/Documents/Elenchus
ls -la "$ELENCHUS"/*.md
ls -la "$ELENCHUS/docs/"
ls -la ~/.config/elenchus/ ~/.local/share/elenchus/data/
cat "$ELENCHUS/.git/info/exclude"
cd "$ELENCHUS" && git status --short --untracked-files=all | head -50
```

The first listing is the twelve root documents, of which only `POSITIONING.md`
binds.

That last command is the real inventory. It lists exactly what is in your
checkout and not in the repository, which is the question this whole section is
asking.

**Stop.** Do not continue until the bundle is read and the scanner is clean.

### Phase B. Grant access, still reversible

**Observed state, 2026-09-06, before any of this runs.** Read via the GitHub API
rather than a settings page, so you are starting from facts:

| Repository | Collaborators | `main` |
|---|---|---|
| `LeavesJ/Elenchus` | `LeavesJ` (admin), **`InsertWittyCommentHere` (write)** | protected |
| `LeavesJ/felix` | `LeavesJ` (admin) only | not checked |

**B0. Resolve who `InsertWittyCommentHere` is, before anything else.** There is
already a second person with `write` on the public repository. Either that is
Riyan and D4 is done, in which case confirm it and skip B2, or it is somebody
else and a handover is the right moment to decide whether that grant should
still exist. This runbook cannot tell which, and it is the one item in Phase B
that is not a step so much as a question.

**B1. Add Riyan to `LeavesJ/felix` with `read`.** Per D1. This is the only access
grant the handover still needs, and it is the first time anyone but you has been
able to read that repository.

**B2. Nothing to do.** He already holds `write` on `LeavesJ/Elenchus`. Confirm he
is not on `admin` and move on.

**B3. Confirm branch protection on `main` is intact** and that `gate` is still
the required status check. `main` reads `protected: true` today. Adding a
collaborator does not change that, and checking takes ten seconds.

**B4. Issue his Anthropic key** on his own workspace with its own spend limit,
per D3. Send it through a channel that is not the same channel as anything else
in this handover.

**Verify:** ask Riyan to confirm he can clone `LeavesJ/felix` and that
`felix which` from his Elenchus checkout names `elenchus`. Under D1 he **should**
be able to see `HANDOFF.md` and `projects/veldra/`. An earlier draft of this step
told you to stop the handover if he could, which was correct under the old D1 and
would now halt it every time.

**Stop, and note what "reversible" does and does not mean here.** Removing a
collaborator seat is not an undo. From the moment Riyan accepts the invitation he
can clone, and a clone on his disk survives the seat being removed. What Phase B
is reversible about is *future* access: revoking the seat stops him receiving
anything new, and revoking the key stops the spend. The disclosure itself is done
the first time he runs `git clone`.

So the real boundary is not between Phase B and Phase C. **Phase B1 is the first
irreversible step, and Phase C is the second.** Phase C is worse only because the
bundle contains material that was never in any repository, so nothing else holds
a copy.

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

**The good news, measured rather than assumed.** A completely fresh clone with
nothing untracked in it runs **1439 passed, 35 skipped in 74 seconds**, with no
`.env`, no `data/`, no `docs/` and no lift banks. Verified 2026-09-06. So his
first hour does not depend on the bundle arriving, and a failure at this point
is an environment problem rather than a missing file. The suite also writes
nothing into the tree, so `git status` stays clean through a full run.

The 35 skips are 31 `@live` tests without a key plus exactly 4 that want
untracked corpus: two in `tests/test_run_injection_probe.py` and two in
`tests/test_generator.py`.

**An earlier version of this paragraph called that a mechanical receipt for the
bundle. It is not one, and the claim was checked and withdrawn on 2026-09-06.**
The two `test_generator.py` skips key on `data/elenchus.db` existing (`:534`,
`:552`), which is the founder's own sittings database and never travels under
any option in this runbook. The two injection-probe skips key on
`<repo>/data/injection_payloads.yaml` (`src/elenchus/run_injection_probe.py:88`),
which is conditional and which `2026-09-06-build-handover-bundle.sh` lists in
`FORBIDDEN`. So 35 is Riyan's permanent correct count, and telling him a
persistent 35 means a misfiled bundle sends him hunting something that cannot
exist, in a direction that ends at asking for the founder's own database.

Phase C therefore has no verification beyond the checksum and his own reading of
the unpacked tree against the placement table. That is a real gap and naming it
is better than a receipt that reports failure on a correct outcome.

The finish line is one command producing one line:

```
~/felix/engine/harness/felix gate
# gate: pass
```

**What fails first, and what it means.** These are the ones worth pre-empting
rather than debugging live.

- `felix which` says no project governs the directory. The home is wrong. It is
  `$FELIX_HOME`, then `~/.felix-home`, then a checkout with `projects/` beside
  the engine, then `~/.felix` (`resolve.sh:131`). `felix install --home ~/felix`
  writes the pointer (`engine/harness/felix:288`).
- The `secret` check prints `skipped (run through felix gate to enable)`. He ran
  `gate.sh` directly instead of through `felix gate`, so `$FELIX_BIN` was unset
  (`projects/elenchus/gate.sh:162`). This is exactly the failure `deny.tsv` row
  one exists to stop, and it is the one that has already cost a day.
- The suite fails on imports. He is relying on the editable install. Everything
  runs with `PYTHONPATH=src`, per `README.md` Develop and L-19.
- He reports the gate has fewer checks than this document says. Count them: the
  Elenchus gate has eight, `format lint test confidential secret lift-bank
  ignore-leak inversion`. There is no `installed` check here; that one lives in
  Felix's own project only, which is why a stale engine on his machine is silent.
- `lift-bank` or `confidential` fails. He staged something from the bundle. This
  is the gate doing its job, and it is worth him seeing once.
- **The gate takes minutes instead of seconds and bills him.** `gate.sh:126` runs
  a bare `pytest -q` with no `-m "not live"`, and the 31 live tests are held back
  only by `@pytest.mark.skipif(not _HAS_KEY)`. So the gate is offline only while
  no key is in the environment. Source `.env` in a shell and then run the gate in
  that same shell and it makes real paid calls. The gate's own comment at line
  120 says live tests "are never part of the gate", which is the intent and not
  the mechanism. Tell him to keep the key out of the shell he gates in.
- `probes` reports a blind `http_route`, and `commission` says "never
  commissioned on this machine". Both are first-run states rather than defects,
  observed in the 4e verification run, and neither blocks `gate: pass`.
  **But `commission` does block `felix merge`.** It is an escape channel, and
  `engine/harness/lib/escape.sh:14` is explicit that "Empty output means nothing
  escaped and Felix may merge." So the gate goes green on day one and his first
  `felix merge` refuses. That is a surprise worth spending five minutes on before
  he hits it, not after.

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
later, both from `projects/elenchus/CLAUDE.md` Delivery: no `Co-Authored-By`
trailer goes in an Elenchus commit, and a `docs/DEVLOG.md` entry rides with the
change.

**That second one needs a ruling from you, because as written it cannot be
obeyed.** `CLAUDE.md:229` says the DEVLOG entry goes "in the same change", and
`.gitignore:6` ignores `/docs/` wholesale, so it can never be staged in that
commit or any other. The only reading that works is that the DEVLOG is a local
record updated in the same sitting. Riyan's document says so and tells him to ask
you if in doubt. Worth deciding once and rewording the constitution, because the
alternative is that every new person reads a rule that forbids itself and quietly
picks their own interpretation.

### Phase F. Cut over

**F1. Agree the boundary in writing.** Riyan owns Elenchus development. You own
Felix, the beta, and every credential. T3 in `projects/elenchus/CLAUDE.md` is
the escalation list and it already names the right things: stable identifier
meaning changes, durable state migrations, secrets and the public tracked set,
history rewrites, and any conflict between his design and your instruction.

**F2. Decide how a gate change reaches you.** `projects/elenchus/` is the gate
contract, it lives in `felix`, and he has read but not write. An earlier draft
offered "make the distribution repo writable for that one directory" as an
option; D1 removed the distribution repo, so under the chosen design there are
only two: he asks you and you push, or he gets `write` on `felix`.

Asking is the better default while the arrangement is new, and it is not much
friction because gate changes are rare. Note that `write` on `felix` is the one
grant that would let him change what governs him, which is a different kind of
authority from writing Elenchus code, so it deserves its own decision rather than
arriving as a convenience.

**F3. Set the maintenance cadence.** `projects/elenchus/maintenance.tsv` drives
the "Maintenance due" line the session start hook prints. Under a handover those
routines change owner, and a routine whose owner changed silently is a routine
that lapses.

---

## 6. What Riyan never receives, and why

Worth stating as a list, because each of these is something a helpful person
would send without thinking.

- **`~/.felix/memory/`, except the three authored files.** `routes.log` and
  `says.log` hold verbatim text typed at a prompt; `mistakes.log`,
  `verification.log` and `ledger.tsv` are per-machine records; `unresolved.log`
  spans every governed project. None travel. `lessons.md`, `DEVLOG.md` and
  `SESSION_HANDOFF.md` do travel, as contents rather than as symlinks, per the
  corrected rule in §3c.
- **`data/elenchus.db`.** Your own sittings. `web/runtime.py:54` calls this file
  one that "holds one particular person's decisions", which is the whole reason
  it may not be served off loopback; the count itself is not in the code and an
  earlier draft cited that line for a figure it does not contain. Your
  personal decision history.
- **`~/.local/share/elenchus/data/tenants/*`.** Beta invitees' writing.
  Disclosure, not file transfer.
- **Your `ANTHROPIC_API_KEY`,** from `.env` or `~/.config/elenchus/env`.
- **`~/.cloudflared/cert.pem` and tunnel credentials.** These authorize DNS on
  your domain (`serve_invitee.py:204`).
- **The eleven non binding root strategy documents.**

**Struck by D1, and worth saying so rather than quietly deleting:** this list
used to carry `HANDOFF.md`, `projects/felix/`, `projects/veldra/` and Felix's
`docs/`. D1 grants read on `LeavesJ/felix`, where all four are tracked, so he
receives every one of them. That includes the three handover documents in this
directory, this one included. Written accordingly.

What remains on the list has a property those four never had: **none of it is in
any repository.** It is your key, your machine, your personal history, and other
people's writing. A collaborator seat cannot leak it, and only a deliberate act
can.

If Riyan later needs something still on this list, that is a new decision taken
on its own merits, not an extension of this one.

---

## 7. Steady state: two people, one private engine

### Shipping a Felix change to Riyan

**D1 removed a step from this loop rather than adding one.** It is now three, and
none of them is new work:

1. Develop in `LeavesJ/felix` as you do today.
2. `felix install`, which bumps `engine/.claude-plugin/plugin.json` when the
   tree differs and the version did not. The bump is the deployment
   (`HANDOFF.md:3699`).
3. Push. Riyan runs `git pull && felix install --home ~/felix`.

Step 3's second half is the one that will be forgotten, and the failure is quiet.
**Correcting an earlier draft of this section, which claimed a safety net that
does not exist:** the `installed` gate check lives only in
`projects/felix/gate.sh:148` and `:182`. Elenchus's gate has eight checks and
`installed` is not one of them, verified by grep. So a stale engine on Riyan's
machine produces **no red gate and no signal at all**. His sessions simply keep
running the engine he installed last.

What is actually true is weaker and worth stating accurately. Hooks bind at
session start (`HANDOFF.md:3690`), so a stale engine is stale for a whole session
rather than half of one. That is the only automatic property here.

So it needs a human check. The cheapest version: after any push that touches
`engine/` or `projects/elenchus/`, tell him in one line. `felix install` verifies
itself and prints either "verified the installed engine matches this tree" or an
explanation, so his side is one command with a readable answer.

Note what this failure now is and is not. He can be **behind**, which is annoying
and fixed by pulling. He cannot be **divergent**, because there is one copy of
the contract and he is reading it. That distinction is the whole benefit of D1.

### The version skew D1 dissolved, and the one it left

**This section is much shorter than it was, and that is the point of D1.**

Two earlier drafts argued about skew. The first claimed a squashed distribution
repository made it "structurally impossible", which was wrong: it would have been
true within that repo and false between Riyan's machine and CI, because CI checks
out `LeavesJ/felix` directly at `.github/workflows/gate.yml:73` while he would
have been reading a synced copy. Two independently maintained sources of one gate
contract, kept in step by remembering.

Under D1 there is one source. You edit `projects/elenchus/gate.sh` in `felix`,
CI checks out `felix`, Riyan pulls `felix`. Nothing can disagree in content.

**What survives is ordinary and cheap.** He can be behind, if he has not pulled.
That is visible the moment CI and his local run disagree, and
`HANDOFF.md:4052` already records that CI and local disagreeing is a finding
rather than flakiness. The fix is `git pull`. There is no diff to run and no
discipline to keep.

One thing genuinely has no guard, and it is unchanged by D1: `plugin.json` carries
a version, but nothing checks that `projects/elenchus/gate.sh` and the engine came
from the same commit. Since both live in one repository and move together, this
only bites someone who pulls a partial tree, which git does not do.

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

**Corrected after D1.** An earlier draft said everything before Phase C could be
undone and that "nothing was disclosed". That was true when Phase B only created
a distribution repository you controlled. It is false now.

**Before B1**: nothing has happened. Riyan's existing `write` on Elenchus is the
status quo, not something this handover granted.

**After B1, the `felix` seat**: not reversible. Removing the seat removes future
access, not the clone he already took. Assume everything in `LeavesJ/felix` is
permanently disclosed the moment he accepts, which is the decision D1 took
deliberately.

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

1. **Who is `InsertWittyCommentHere`?** They hold `write` on `LeavesJ/Elenchus`
   today. If that is Riyan, D4 is already satisfied. If it is not, decide whether
   the grant stands. (§5 B0)
2. Does Riyan get `projects/elenchus/` write access eventually, and through what
   mechanism? (§5 F2)
3. Does his `maintenance.log` start from yours or from empty? (§4e)
4. Which of the twelve root documents are drafts you would rather not hand over,
   beyond keeping `POSITIONING.md`? (§3a)
5. Which `docs/lessons.md` is canonical, the one in Elenchus or the one in the
   memory root, and have they diverged? (§5 A4)
6. Is `.env.example` added to Elenchus? (D5, T3)
7. Does the beta stay entirely yours indefinitely, or is there a date where
   Riyan takes it with the invitees told? (D2)
8. Does the distribution repository get its own `HANDOFF.md` for Riyan, so his
   standing direction accumulates the way yours does? The session start hook
   already reads `<repo_root>/HANDOFF.md` when present
   (`engine/harness/hooks/session-start`, the `read_lines` block), so the slot
   exists and is currently empty for him.
