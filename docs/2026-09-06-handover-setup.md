# Elenchus handover: setup guide

Written 2026-09-06. **Every decision is taken.** This is the run sheet: what to
do, in order, with the command and the check that proves it worked. No options
and no reasoning. The reasoning lives in
`2026-09-06-elenchus-handover-runbook.md` if you ever need to know why a step is
shaped the way it is.

**What was decided.** Riyan is engaged with high authority. He gets read on
`LeavesJ/felix` and keeps the `write` he already has on `LeavesJ/Elenchus`. He
gets his own Anthropic key. The beta stays yours. CI is untouched. Nothing
tracked is added to Elenchus.

**Two steps cannot be undone.** Part 2 and Part 3, marked below. Everything
before Part 2 is private to you.

**Nothing you are meant to paste contains an angle bracket or a `#`.** In prose,
angle brackets mark something only you can fill in, and `$ELENCHUS` and `$FELIX`
are the two shell variables step 1.0 has you set. Inside a command block they
would be an input redirection and a stray argument respectively, so they are not
there. If you ever see one inside a block in this document, that block is a bug
and has not been fixed yet.

---

## Part 0. Before anything else

**0.1 Sign the Felix and beta confidentiality acknowledgment.** Resolved
2026-09-06: Riyan is already a legal founder of Elenchus Labs, Inc. with a
signed CIIAA from incorporation, so `LICENSE:12`'s founder exclusion and the IP
assignment were both already in place before this handover started. What is
left, and what `2026-09-06-riyan-engagement-letter.md` now covers, is three
short things a founder CIIAA does not reach: Felix confidentiality, since Felix
also governs a separate venture and its CIIAA-scope is not something to assume;
the beta and invitee-data restriction, which is a promise about third parties
rather than an IP question; and one line on credential handling.

**This must be dated before Part 2.** It is the only prerequisite in this
document.

**0.2 Have these open:** the GitHub settings pages for both repositories, the
Anthropic console, and a terminal in `<elenchus>`.

---

## Part 1. Prepare the bundle

Nothing leaves your machine in this part. Roughly forty minutes, most of it
reading.

### 1.0 Set two variables, and read this about your shell

**Every command block below is written for zsh and contains no angle brackets
and no `#`.** Both were in earlier drafts and both are errors rather than
comments in an interactive zsh, which is what you are running. `<felix>/docs/x`
is parsed as an input redirection from a file named `felix`, so zsh answers
`no such file or directory: felix` and the command never runs. A trailing
`# must print nothing` is parsed as two more arguments, so `find` answers
`unknown primary or operator` and the command never runs. Both were observed
live on 2026-09-06 and both failures looked like output rather than like
nothing having happened.

So paths come from variables, set once per terminal window:

```
ELENCHUS=~/Documents/Elenchus
FELIX=$(cd "$ELENCHUS" && felix which | awk '/^doctrine:/ {print $2}')
FELIX=${FELIX%/projects/*}
echo "$ELENCHUS" "$FELIX"
```

The second and third lines ask Felix where it lives rather than keeping a second
copy of the resolution logic, which is the same reason `scripts/preflight.py:35`
calls the launcher's own resolver. If `felix` is not on your PATH, set `FELIX`
by hand to your felix checkout instead. Confirm the `echo` prints two real
directories before running anything below.

### 1.1 See your actual untracked surface

```
cd "$ELENCHUS"
git status --short --untracked-files=all
ls -la ./*.md docs/ 2>/dev/null
ls -la ~/.config/elenchus/ ~/.local/share/elenchus/data/ 2>/dev/null
cat .git/info/exclude
```

That first command is the real inventory. It lists exactly what is in your
checkout and not in the repository, which is the whole question this part
answers.

Look for symlinks in that listing, because this checkout has at least five and
two of them matter more than anything else in this document. Observed
2026-09-06: `.env` points at `~/.config/elenchus/env`, which is your live key,
and `data` points at `~/.local/share/elenchus/data`, which is the invitee
databases. Any recursive copy that starts at the repository root reaches both.

### 1.2 Build the bundle

The script below takes both checkouts as arguments and does not care what
directory you run it from. That is deliberate. The two failures this step has
actually produced were both about paths: once every source was prefixed with the
checkout name while already inside the checkout, and once a recursive copy ran
against the wrong source entirely.

**`docs/` is allow-listed below, not copied wholesale.** Observed directly on
2026-09-06, then checked item by item rather than assumed: alongside
`DEVLOG.md` and `lessons.md`, this checkout's `docs/` also holds
`YC_answers.md`, `SESSION_HANDOFF.md`, and two subdirectories, `admissions/`
and `superpowers/`. `cp -R docs/. ...` would not distinguish any of them.

`YC_answers.md` reads as YC application material and stays out. `admissions/`
holds entries like `withhold_your_best_product_from_funders.yaml`, founder
reflection rather than engineering reference, and stays out by default; open a
couple yourself before overriding that. `superpowers/plans/` and `superpowers/specs/`
are forty-some dated design and plan documents named after real engineering
surfaces, no strategic language in the list, and they go in.

**Three of these are symlinks into the memory root, and that changes how they
must be copied.** Verified 2026-09-06: `docs/lessons.md`, `docs/DEVLOG.md` and
`docs/SESSION_HANDOFF.md` all point at `~/.felix/memory/elenchus/`. They are
authored prose rather than raw logs, and they travel, but **as contents, never
as links**. The script copies those three by name without `-R`, which is what
makes `cp` read through the link; a `cp -R` over `docs/` would instead hand
Riyan three pointers into your home directory that resolve to nothing on his
machine.

`SESSION_HANDOFF.md` travels because it holds no invitee material, none having
been invited yet, confirmed 2026-09-06. That is circumstantial rather than
structural, so re-verify if this is ever revisited once the beta has real users.

**`.claude/` is allow-listed too, and for a sharper reason than `docs/`.** Its
four entries, observed 2026-09-06, are `CLAUDE.md`,
`CLAUDE.md.pre-reset-2026-07-25`, `settings.local.json` and `worktrees`. Only
the first is project doctrine and only the first travels.

`CLAUDE.md.pre-reset-2026-07-25` is a superseded copy and sending it hands Riyan
two documents with no way to tell which one binds. `settings.local.json` is the
per-machine permission allowlist, which is what `.local` means; it encodes paths
under your home directory and Riyan's will differ, so he builds his own as he
goes. `worktrees` is the one that matters: if it holds actual git worktrees then
`cp -R .claude/.` sweeps entire checkouts into the bundle, along with whatever
untracked files sit inside them, which is exactly the shape that defeats step
1.5. **Look at it before you decide**, and if it holds checkouts, leave it.

**Do not paste these copies by hand. Run the script.**
`2026-09-06-build-handover-bundle.sh`, beside this document in the felix
checkout, performs exactly the allow-list above and refuses on the first thing
that is wrong instead of continuing. That is not a convenience. On 2026-09-06
the pasted version produced a 276 MB bundle holding an entire repository
checkout, both root symlinks, both `docs.bak-*` directories, `YC_answers.md`,
`admissions/` and `settings.local.json`, and none of the three documents it was
supposed to contain, and every one of those failures was silent.

```
"$FELIX/docs/2026-09-06-build-handover-bundle.sh" "$ELENCHUS" "$FELIX"
```

It refuses if `~/handover` already exists, so if you have a previous attempt,
look at it and then remove it:

```
du -sh ~/handover
find ~/handover -type f | wc -l
rm -rf ~/handover
```

Removing it loses nothing. Every file in it is a copy.

Each refusal prints a stable `reason_code` and a free-form `reason_detail`:

| `reason_code` | What it means |
|---|---|
| `bundle_dest_exists` | `~/handover` is already there. Inspect, remove, re-run. |
| `bundle_missing_source` | An allow-listed file is not in the checkout. The list has drifted. |
| `bundle_dangling_symlink` | A `docs/` entry points at a memory-root file that is gone. |
| `bundle_symlink_in_source` | `spike-results/` or `superpowers/` contains a symlink, which `cp -R` would preserve. |
| `bundle_symlink_present` | A symlink reached the bundle anyway. |
| `bundle_forbidden_path` | Something matching `.env`, `.git`, `.venv`, `data`, `admissions`, `docs.bak-*`, `*.db`, `settings.local.json` and twenty more got in. |
| `bundle_empty_file` | A required document is zero bytes, which is what a broken dereference leaves. |
| `bundle_too_many_files` / `bundle_too_large` | Over 2000 files or 50 MB. Something recursive got in. |

Every one of those was exercised against a fixture built to mirror this
checkout, symlinks included, before this document was written.

Check what you left behind, so the allow-list stays a decision rather than an
oversight:

```
ls -la "$ELENCHUS/.claude/" "$ELENCHUS/docs/"
```

**`ENVIRONMENT.md` is the answer to "he does not know the setup".** The script
copies it in for you. `2026-09-06-elenchus-environment.md` is the whole local
environment written out from the tracked code: all six variables with the file
and line that reads each, where the key goes, which untracked file each command
needs, and the asymmetry between `python -m elenchus.web` and
`scripts/serve_invitee.py` over key resolution that has cost this project real
hours. It names no secret value, so it carries no disclosure risk of its own and
could later be tracked, which is D5's question rather than this step's.

This allow-list is one checkout observed once, not a permanent inventory. If a
source file has moved, the script stops with `bundle_missing_source` naming it
rather than quietly shipping a bundle without it, which is the failure the
pasted version produced.

Two more are conditional and should be left out unless he needs them now:

- `data/injection_payloads.yaml` only if he is working the injection probe. It is
  a set of working attacks against the grader of a public product, which the
  tracked stub at `content/gate/injection_payloads.example.yaml` says in its own
  header. If you send it, say what it is in the same message.
- The eleven non binding root markdown documents. Only `POSITIONING.md` binds.
  Send the drafts only if you want him to have the history.

### 1.3 Verify the symlinks dereferenced

Earlier drafts had you diff `docs/lessons.md` against the memory-root copy and
merge any divergence. **There is nothing to reconcile and never was**: the two
paths are one file, so `diff` is silent by construction.

What can actually go wrong is the copy preserving links instead of contents.
The three named files are copied without `-R` so they dereference, but two of
the copies use `-R`, and `cp -R` preserves a symlink found inside a directory
rather than following it.

**The script already ran every check in this step and exits non-zero on any of
them.** If it printed a manifest and the word `built`, 1.3 is done. Run the
following only if you built the bundle some other way:

```
find ~/handover -type l
wc -l ~/handover/docs/lessons.md ~/handover/docs/DEVLOG.md ~/handover/docs/SESSION_HANDOFF.md
du -sh ~/handover
find ~/handover -type f | wc -l
```

`find` must print nothing at all. Any line it prints is a pointer into your home
directory that resolves to nothing on Riyan's machine, and it fails silently
rather than loudly. Replace each one with its contents by copying the target
over the link, without `-R`.

A near-zero line count means the same failure reached the three primary files.
`lessons.md` was 36475 bytes when observed, so it should be well into the
hundreds of lines.

The last two check scale rather than content. You are about to read every file
in this bundle by hand in 1.5, so a count in the low hundreds is workable. A
count in the thousands, or a size in the hundreds of megabytes, means something
recursive got in. When this went wrong on 2026-09-06 the numbers were 13328
files and 276 MB, so the failure is not subtle once someone looks. The problem
was that nothing was looking.

### 1.4 Write NOTES.md

Anything that has only ever been in your head. Start from the scaffold rather
than a blank file:

```
cp "$FELIX/docs/2026-09-06-notes-template.md" ~/handover/NOTES.md
```

Eight sections with the verifiable parts already filled in and a prompt under
each of the rest: where the beta stands, what you were part way through, what
you would have him do first, what you would not touch yet and why, what you
already tried that did not work, the five decisions still open, people and
context, and how to reach you for what. Delete each prompt as you answer it and
delete whole sections that do not apply. A short honest NOTES.md beats a
complete-looking one.

**Section 1 has a real conflict to resolve.**
`2026-09-06-riyan-onboarding.md:27` tells Riyan the beta has been running with
one invited person per instance since 2026-09-05, and you said on 2026-09-06
that nobody has been invited yet. Both can be true if the infrastructure went
live and no invite went out, but he cannot tell that from what he has. Write
the real sentence in NOTES.md and the onboarding document gets corrected to
match it.

### 1.5 Read every file in the bundle

This is the step that gets skipped and it is the one that matters. `docs/` holds
a DEVLOG written for an audience of one. Read for credentials, invitee names or
slugs, anything about a person, and anything about Veldra you would rather
introduce yourself.

### 1.6 Scan it, twice, and know what each pass misses

```
grep -rnI '' ~/handover/ | "$FELIX/engine/harness/bin/secret-scan" -
grep -rniE 'sk-ant-|sk-[A-Za-z0-9]{20}|AKIA[0-9A-Z]{16}|BEGIN [A-Z ]*PRIVATE KEY|ANTHROPIC_API_KEY[[:space:]]*=' ~/handover/
```

**Both, not either.** `secret-scan` takes a git ref or `-` for stdin, never a
directory: point it at the bundle and it prints "no base ref found; scanning
uncommitted changes only" and exits 0, which reads exactly like a clean bundle.
And `FELIX_SCAN_CONTEXT` (`engine/harness/bin/secret-scan:40`) excludes any line
containing `ANTHROPIC_API_KEY`, so a line copied straight out of a `.env` is
invisible to it. The second grep is what covers that.

Measured, so you know the shape of the gap:

| Planted line | `secret-scan -` |
|---|---|
| `ANTHROPIC_API_KEY=sk-ant-...` | missed |
| `export ANTHROPIC_API_KEY="sk-ant-..."` | missed |
| bare `sk-ant-...` in prose | caught |
| `aws_key = AKIA...` | caught |
| `BEGIN RSA PRIVATE KEY` | caught |
| `my_password = "..."` | caught |

**Stop here until both come back clean and you have read the files.**

---

## Part 2. Grant access

**This is the first irreversible step.** From the moment Riyan accepts the
`felix` invitation he can clone, and removing the seat later removes future
access, not the copy on his disk. Everything in `LeavesJ/felix` is disclosed
permanently, which is what was decided.

**2.1 Add Riyan to `LeavesJ/felix` with `read`.** Settings, Collaborators, add,
role `Read`. This is the only grant the handover needs.

**2.2 Confirm his Elenchus role.** He is `InsertWittyCommentHere` and already
holds `write`. Confirm it still says `write` and not `admin`. Nothing to change.

**2.3 Confirm `main` is still protected** and `gate` is still the required status
check. It read `protected: true` on 2026-09-06. Adding a collaborator does not
change it; checking takes ten seconds.

**2.4 Issue his Anthropic key.** His own workspace, his own spend limit, so spend
stays attributable and either machine can be revoked without touching the other.
Send it through a different channel from the bundle.

**Verify:** ask him to clone `LeavesJ/felix` and confirm `git log -1` works. He
will be able to see `HANDOFF.md` and `projects/veldra/`. That is correct and
expected.

---

## Part 3. Send the bundle

**This is the second irreversible step**, and it is worse than Part 2 in one
respect: the bundle holds material that is in no repository, so nothing else has
a copy of it.

**3.1 Encrypt.** The archive is the boundary, not the transport, so any of these
is fine:

Set `RECIP` to his age public key, or to his gpg key id if you use the second
form, then run one of these:

```
RECIP=age1...
tar czf - -C ~ handover | age -r "$RECIP" > handover.tar.gz.age
```

```
RECIP=his-gpg-key-id
tar czf - -C ~ handover | gpg -e -r "$RECIP" > handover.tar.gz.gpg
```

Not a shared drive link that outlives the transfer, and not a channel that
indexes content.

**The archive step is not a second chance to catch a leak.** `tar` on macOS
stores a symlink as a symlink and does not follow it, so a bad link inside the
bundle would travel as a dead pointer rather than as its target's contents. That
sounds reassuring and is not: it means a symlink pointing at your key would
reach Riyan as a visible path into your home directory, and it means adding `-h`
or `-L` to that command, or compressing the folder in Finder, changes the answer.
The place symlinks are caught is 1.2, by the script, before anything is packed.

**3.2 Send it, and send a checksum separately.**

```
shasum -a 256 handover.tar.gz.age
```

**3.3 Tell him where each piece goes.** His onboarding document says this too,
so this is a backstop:

| From the bundle | Goes to |
|---|---|
| `docs/` | `<his-elenchus>/docs/` |
| `POSITIONING.md` | `<his-elenchus>/POSITIONING.md` |
| `content-lift/*.yaml` | `<his-elenchus>/content/lift/` |
| `claude-config/CLAUDE.md` | `<his-elenchus>/.claude/CLAUDE.md` |
| `ENVIRONMENT.md` | read first, then wherever he keeps notes |
| `NOTES.md` | wherever he keeps notes |

Every destination is already covered by `.gitignore`, so none of it can be
staged by accident.

---

## Part 4. His setup

He follows `2026-09-06-riyan-onboarding.md`. This is what happens and where you
need to be reachable. Roughly ninety minutes.

**4.1 Elenchus.**

```
git clone https://github.com/LeavesJ/Elenchus.git
cd Elenchus
python3.14 -m venv .venv
.venv/bin/pip install -e ".[dev,web]" "ruff==0.16.0" "pytest==9.1.1"
PYTHONPATH=src .venv/bin/pytest -q
```

Expect exactly **`1439 passed, 35 skipped`**, about 74 seconds. Verified from a
clone with nothing untracked in it. The two pins are not in `pyproject.toml` and
are what CI installs (`.github/workflows/gate.yml:90`); without them his lint can
disagree with CI for reasons unrelated to his change.

**4.2 Felix.**

```
ELENCHUS=~/Elenchus
git clone git@github.com:LeavesJ/felix.git ~/felix
cd ~/felix && ./engine/harness/felix install --home ~/felix
cd "$ELENCHUS" && ~/felix/engine/harness/felix which
```

`felix install` ends with `verified   the installed engine matches this tree`.
`felix which` names `elenchus`. Read access is enough: Felix writes only into a
gitignored `state/` in the clone and into his own `~/.felix/memory/`.

**4.3 Unpack the bundle, then re-run the suite. Expect 35 again.**

Earlier drafts called this a mechanical receipt: 31 of the skips are `@live`
tests without a key, 4 want untracked corpus, so a count below 35 after
unpacking would prove the corpus landed. **That is wrong and it would have cost
Riyan a day.** Both `test_generator.py` skips key on `data/elenchus.db` existing
(`:534`, `:552`), which is your own sittings database and never travels. Both
`test_run_injection_probe.py` skips key on `<repo>/data/injection_payloads.yaml`
(`src/elenchus/run_injection_probe.py:88`), which is conditional and which the
bundle builder refuses by default.

So 35 is his permanent correct count and the bundle has no self-check at all.
Verification is him listing what he unpacked against the table in 3.3, which is
why that table has to be right.

**4.4 First green gate.**

```
cd "$ELENCHUS" && ~/felix/engine/harness/felix gate
```

The last line should read `gate: pass`. Eight checks: `format lint test
confidential secret lift-bank ignore-leak inversion`.

**What goes wrong, and what it means:**

- **`secret` prints `skipped`.** He ran `gate.sh` directly instead of through
  `felix gate`, so `$FELIX_BIN` was unset (`projects/elenchus/gate.sh:162`).
  Seven checks wearing an eight check name. A `deny.tsv` rule blocks this, so
  Felix should stop him first.
- **`felix which` finds no project.** Either the home is wrong, fixed by re-running
  `felix install --home ~/felix`, or his `origin` is not `LeavesJ/Elenchus`.
  Elenchus binds purely on `remote_match`, so a fork is governed by nothing,
  silently.
- **Imports fail.** He is relying on the editable install. Everything runs with
  `PYTHONPATH=src`.
- **The gate takes minutes and bills him.** `gate.sh:126` runs a bare `pytest -q`
  and the live tests are held back only by `skipif` on the key, so the gate is
  offline only while no key is in that shell. Keep the key out of the shell he
  gates in.
- **`probes` and `commission` print below the eight.** Neither blocks the gate.

---

## Part 5. First commit, and the one refusal to expect

**5.1 A deliberately trivial change.** He declares T0, runs `felix gate`, commits
with explicit paths, and pushes a branch **on the origin repository**, never a
fork. Two doctrine points he will get wrong once: no `Co-Authored-By` trailer in
an Elenchus commit, and the `docs/DEVLOG.md` entry is a local record rather than
something he can stage. See 5.4.

**5.2 Watch CI.** The `gate` job must run the harness path. If the log says "the
private harness is unreachable", he pushed from a fork.

**5.3 His first `felix merge` will refuse.** Expect this rather than debugging
it. `commission` is an escape channel and
`engine/harness/lib/escape.sh:14` is explicit that "Empty output means nothing
escaped and Felix may merge", so a machine that has never been commissioned
escapes even behind a green gate. Walk him through `felix commission` once,
before he needs it.

**5.4 Rule on the DEVLOG.** `projects/elenchus/CLAUDE.md:229` requires a
`docs/DEVLOG.md` entry "in the same change", and `.gitignore:6` ignores `/docs/`
wholesale, so it can never be staged. As written the rule forbids itself. Tell
him which you mean, and consider rewording the constitution, because otherwise
every new person meets a rule that cannot be obeyed and picks their own reading.

---

## Part 6. Cut over

**6.1 The boundary.** He owns Elenchus development. You own Felix, the beta, and
every credential. `projects/elenchus/CLAUDE.md` T3 is the escalation list and it
already names the right things: changing a stable identifier's meaning, migrating
durable state, secrets or the tracked set of the public repo, history rewrites,
and any conflict between his design and an explicit instruction from you.

**6.2 Gate changes come to you.** `projects/elenchus/` lives in `felix` and he
has read, not write. He proposes, you push. `write` on `felix` would let him
change what governs him, which is a different authority from writing Elenchus
code, so leave it as its own decision rather than a convenience.

**6.3 Shipping Felix changes.** Three steps, and no publishing step:

1. Develop in `LeavesJ/felix`.
2. `felix install`, which bumps `engine/.claude-plugin/plugin.json` when the tree
   differs and the version did not. The bump is the deployment.
3. Push, and tell him. He runs `git pull && felix install --home ~/felix`.

Nothing catches a stale engine on his side: the `installed` check exists only in
`projects/felix/gate.sh`, not in Elenchus's. So step 3's second half is a habit,
not a mechanism. He can be behind, which `git pull` fixes; he cannot diverge,
because there is one copy of the contract.

**6.4 His memory backup.** `felix pulse` pushes his memory root to a git remote
if he gives it one. Set that up in his first week, pointed at **his own** private
remote, never yours. Otherwise every lesson he pays for exists in exactly one
place.

**6.5 Maintenance cadence.** `projects/elenchus/maintenance.tsv` drives the
"Maintenance due" line at session start. Decide which routines are now his, and
whether his `maintenance.log` starts from yours or from empty. Starting from
yours is the better default, because a routine that resets to never-run lapses
silently.

---

## Standing rules that outlive this setup

Six things nothing in either repository enforces. They live here because there
is nowhere else to put them.

1. **`write` on Elenchus is read on `felix`.** Both workflows check out the
   private repo with `FELIX_DEPLOY_KEY`, and a same repo pull request runs the
   workflow file from the branch it came from, before any review. Grant the first
   only to someone you would grant the second, or narrow CI first. The recipe for
   a narrowed distribution repository is in the runbook at §4e, built and
   verified, unused.
2. **The felix read grant widens by itself.** Add a fourth project and Riyan
   reads it the day it lands, with nobody deciding.
3. **The memory root's raw logs never travel; its three authored files do.**
   `routes.log` and `says.log` hold verbatim prompt text, `unresolved.log` sits
   at the root across all projects, and `mistakes.log`, `verification.log` and
   `ledger.tsv` are per-machine records. None of those move. `lessons.md`,
   `DEVLOG.md` and `SESSION_HANDOFF.md` are authored prose, are already
   symlinked into `docs/`, and travel as contents. Sending the subdirectory
   wholesale is still wrong; sending three files by name is right.
4. **Your repository root has symlinks in it, and two of them are the crown
   jewels.** `.env` points at your key file and `data` points at the invitee
   database root, both observed 2026-09-06. Any recursive copy, archive or sync
   that starts at the repository root reaches both, and `cp -R` and `tar` each
   handle them differently. This is why no step in this document copies a
   directory it has not first checked, and why the bundle script refuses a tree
   containing a symlink rather than deciding per link.
5. **Angle brackets and `#` are not placeholders and not comments in your
   shell.** `<felix>/x` is an input redirection, so zsh says
   `no such file or directory: felix` and the command never runs. A trailing
   `# must print nothing` becomes two arguments, so `find` says
   `unknown primary or operator` and the command never runs. Both were observed
   live on 2026-09-06 and both looked like output rather than like nothing
   having happened. Anything meant to be pasted uses `$ELENCHUS` and `$FELIX`
   and carries no `#`.
6. **The beta is yours.** There is no invitee registry in code; the operator
   scripts glob the tenant root, the allocation table lives in your memory root,
   and Cloudflare Access holds the email addresses that `forget_invitee.py`
   cannot reach. Handing it over later is a Cloudflare account transfer and a
   disclosure, not a file copy.

---

## Every command, in order

No angle brackets and no `#`, so every block below can be pasted into zsh as it
stands. An earlier version of this appendix also still carried `cp -R docs/.`
and `cp -R .claude/.` after the body had moved to allow-lists, which if run
would have sent `YC_answers.md`, `admissions/` and `settings.local.json`. It is
now the same allow-list as 1.2 because it is the same script.

**Part 1, on your machine.**

```
ELENCHUS=~/Documents/Elenchus
FELIX=$(cd "$ELENCHUS" && felix which | awk '/^doctrine:/ {print $2}')
FELIX=${FELIX%/projects/*}
echo "$ELENCHUS" "$FELIX"
```

```
cd "$ELENCHUS" && git status --short --untracked-files=all
ls -la "$ELENCHUS/docs/" "$ELENCHUS/.claude/"
"$FELIX/docs/2026-09-06-build-handover-bundle.sh" "$ELENCHUS" "$FELIX"
```

```
grep -rnI '' ~/handover/ | "$FELIX/engine/harness/bin/secret-scan" -
grep -rniE 'sk-ant-|AKIA[0-9A-Z]{16}|BEGIN [A-Z ]*PRIVATE KEY|ANTHROPIC_API_KEY[[:space:]]*=' ~/handover/
```

Then write `~/handover/NOTES.md` and read every file. Neither is a command.

**Part 2** is the GitHub UI: add Riyan to `LeavesJ/felix` with Read.

**Part 3.**

```
RECIP=age1...
tar czf - -C ~ handover | age -r "$RECIP" > handover.tar.gz.age
shasum -a 256 handover.tar.gz.age
```

**Part 4, his machine.** Expect `1439 passed, 35 skipped`, then `elenchus`, then
`gate: pass`.

```
ELENCHUS=~/Elenchus
git clone https://github.com/LeavesJ/Elenchus.git "$ELENCHUS"
cd "$ELENCHUS"
python3.14 -m venv .venv
.venv/bin/pip install -e ".[dev,web]" "ruff==0.16.0" "pytest==9.1.1"
PYTHONPATH=src .venv/bin/pytest -q
```

```
git clone git@github.com:LeavesJ/felix.git ~/felix
cd ~/felix && ./engine/harness/felix install --home ~/felix
cd "$ELENCHUS" && ~/felix/engine/harness/felix which
~/felix/engine/harness/felix gate
```
