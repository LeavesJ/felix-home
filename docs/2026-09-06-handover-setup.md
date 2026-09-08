# Elenchus handover: setup guide

Written 2026-09-06. **Every decision is taken.** This is the run sheet: what to
do, in order, with the command and the check that proves it worked. No options
and no reasoning. The reasoning lives in
`2026-09-06-elenchus-handover-runbook.md` if you ever need to know why a step is
shaped the way it is.

**What was decided.** Riyan is engaged with high authority. He already holds
`write` on both repositories, which is the only collaborator level a personal
repo has, so Felix was disclosed before this began. He gets his own Anthropic
key. The beta stays yours. CI is untouched. Nothing tracked is added to
Elenchus.

**One step cannot be undone: Part 3, sending the bundle.** Part 2 was written as
the first irreversible step, on the belief that it was when Felix got disclosed.
It was not. The bundle is the only thing here that exists in no repository.

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

So paths come from variables, set once per terminal window. **Set them by hand
and make them absolute.**

```
ELENCHUS=$(cd ~/Documents/Elenchus && pwd)
FELIX=$(cd ~/Documents/Felix && pwd)
test -d "$ELENCHUS/src" && test -x "$FELIX/engine/harness/bin/secret-scan" && echo ok
echo "$ELENCHUS"
echo "$FELIX"
```

Adjust the two paths to your checkouts. `cd ... && pwd` is what makes them
absolute, and the `test` line refuses to print `ok` unless both are what they
claim to be. Do not continue without `ok` and two paths starting with `/`.

**An earlier version derived `FELIX` from `felix which` and it produced a
relative path**, which then silently broke every command built on it: zsh
reported `no such file or directory: Documents/Felix/engine/...` and the
secret-scan simply did not run, while the second grep in the same paste ran fine
and printed results, so the block looked like it had worked. The cause is in
Felix rather than in the awk: `felix_home()` returns `$FELIX_HOME` verbatim
(`engine/harness/lib/resolve.sh:133`) and the engine directory verbatim
(`:147`), neither normalised to an absolute path, so `felix which` prints
whatever it was given. Asking a tool where it lives is still the right instinct,
and it is why `scripts/preflight.py:35` uses the launcher's own resolver, but it
only works when the answer is absolute.

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

**What actually travels, from an `ls` of this checkout on 2026-09-06.** Under
`docs/`: `DEVLOG.md`, `lessons.md`, `SESSION_HANDOFF.md`, `spike-results/`,
`superpowers/`, and by default not `YC_answers.md` or `admissions/`. At the
root: `POSITIONING.md` and the twelve design documents, four of which are ML
design work he should have on day one. Under `.claude/`: `CLAUDE.md` and
`settings.local.json`, but not the pre-reset copy. Plus the real lift banks.

`.claude/worktrees/` is denied outright now, and it had to be. Found live on
2026-09-06: it held a full nested checkout for unrelated work, and the deny rule
at the time only matched `.worktrees` with a leading dot, which is the different
thing your `.gitignore` names. Claude Code creates the undotted one for isolated
per-task sessions and there were eleven of them registered. Both spellings are
denied.

**Do not paste copies by hand. Run the script, and it is a different script
than it was an hour ago.**

The goal you stated is that Riyan's Elenchus folder ends up in the state yours
is in. That makes this a deny-list, not an allow-list: everything untracked
travels except what must not and what he regenerates. The allow-list version was
built for minimum disclosure and it withheld four ML design documents
(`Elenchus_JudgmentLoop_v0.1.md`, both `Elenchus_LiftTest_EXP-*.md`,
`Elenchus_ModelBreakpoint_Eval_v0.1.md`) from the person you brought in for
being better at ML. Wrong objective, wrong bundle.

```
"$FELIX/docs/2026-09-06-build-handover-bundle.sh" "$ELENCHUS" "$FELIX"
```

It asks git what is untracked, which IS the delta between a fresh clone and your
working checkout, then walks it. It refuses if `~/handover` exists, so remove a
previous attempt first:

```
du -sh ~/handover
find ~/handover -type f | wc -l
rm -rf ~/handover
```

**Never travels, whatever else changes.** `.env` and any `.env.*`, `data/`,
anything matching `*.db` or `*.sqlite`, any `*.key` or `cert.pem` or `id_rsa`.
That is your key, the beta invitee databases and your own sittings history. The
deny list also drops what he regenerates: `.git`, `.venv*`, `__pycache__`, the
caches, `build/`, `graphify-out/`, `node_modules`, both spellings of
`worktrees`, and the stale copies `docs.bak-*` and `CLAUDE.md.pre-reset-*`.

**Held back unless you pass `--all`:** `docs/YC_answers.md` and
`docs/admissions/`. Founder material rather than engineering material. The
script prints both so it stays a visible decision rather than an omission.

**Symlinks are recorded, never copied and never followed.** Your checkout has
`data` pointing at the invitee store and `.env` pointing at your key file, plus
three in `docs/` pointing into the memory root. Copying a link would hand Riyan
a dead pointer; following one would put your key or the invitee databases in the
bundle. The script writes `symlinks.tsv` instead and `restore.sh` rebuilds the
equivalent structure against **his** home directory.

**The bundle carries its own `restore.sh`**, which is what makes this
"integrate and go" rather than twelve manual placements. On his machine it
refuses unless he is in a checkout whose origin is `LeavesJ/Elenchus`, since a
fork is governed by nothing and Felix says nothing about it; places every file;
creates his own empty `data/` store and his own out-of-tree key file, repointing
either if it arrives aimed at your home; seeds his Felix memory root with the
three authored documents and links `docs/` to them the way yours is; and then
verifies. It is idempotent and it never overwrites a file he has changed.

Refusals print a stable `reason_code` and a free-form `reason_detail`:

| `reason_code` | What it means |
|---|---|
| `bundle_dest_exists` | `~/handover` is already there. Inspect, remove, re-run. |
| `bundle_not_a_checkout` | A path argument is not an Elenchus checkout. |
| `bundle_empty_surface` | git reports nothing untracked. Wrong directory. |
| `bundle_symlink_present` | A symlink reached the bundle. Should be impossible. |
| `bundle_forbidden_path` | Something on the deny list got in anyway. |
| `bundle_empty_file` | A required document is zero bytes. |
| `bundle_too_many_files` / `bundle_too_large` | Over 4000 files or 200 MB. |
| `restore_wrong_remote` | On his side: he cloned a fork. |
| `restore_incomplete` | On his side: verification failed, details above it. |

Both scripts were exercised end to end against a fixture built to mirror your
checkout, symlinks included: build, then restore into a fresh clone, then verify
the structure matched.

Check what was held back before moving on:

```
ls -la "$ELENCHUS/docs/" "$ELENCHUS/.claude/"
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

### 1.3 Confirm what the script decided

The script already ran every mechanical check and exits non-zero on any of them,
so there is nothing to re-run here. What is worth two minutes is reading its
three reports, because each is a decision it made on your behalf.

**The manifest.** Every file with its byte count. Look for anything you did not
expect to see and anything conspicuously large.

**`not sent, by rule`.** Each `deny` line is something the script refused. Each
`held` line is founder material you can include with `--all`. If a `deny` line
names something you actually want Riyan to have, that is a deny-list change
rather than a copy you make by hand.

**`symlinks recorded`.** Should list the three under `docs/` pointing into your
memory root. `data` and `.env` will not appear because they are denied outright,
which is correct: `restore.sh` creates his own rather than replicating yours.

If you want the paranoid version anyway:

```
find ~/handover -type l
find ~/handover -type d -name worktrees
find ~/handover -type f | wc -l
du -sh ~/handover
```

**`-type d -name worktrees`, not `-path "*worktree*"`.** The substring form was
in an earlier draft and it is useless: plugin source code implementing worktree
features has "worktree" in dozens of filenames, so it reports thirty benign hits
and buries a real one. Match the directory name exactly.

The count and size are the checks that actually catch a fetched tree. Two have
got in so far, both silently: a nested checkout under `.claude/worktrees/`, and
690 MB across 22418 files of plugin downloads under `~/.claude/plugins/cache`
and `marketplaces`. Both scripts now refuse on a count ceiling, which is the
earlier and clearer signal than size.

`find` must print nothing. When this step went wrong on 2026-09-06 the bundle
was 13328 files and 276 MB, so the failure is not subtle once someone looks.

### 1.4 Add the agent setup

The bundle builder walks the Elenchus checkout, so it sees `.claude/` inside the
repo and nothing else. Most of what makes your agent setup an agent setup lives
in `~/.claude/`, outside every repository, and none of it was travelling.

```
"$FELIX/docs/2026-09-06-build-agent-setup.sh" ~/handover
```

It appends `agent-setup/` to the bundle you already built, so no rebuild.
Carries `agents/`, `commands/`, `skills/`, `plugins/`, your hook scripts, the
user-level `CLAUDE.md` and `settings.json`. Refuses `projects/`, which is
session transcripts and was 62 MB on the machine this was tested against, plus
`history.jsonl`, `.credentials.json`, `sessions/`, `shell-snapshots/` and
`backups/`.

`~/.claude.json` never travels: mode 600, and it holds your OAuth account, every
directory you have ever opened, and each MCP server's env block. The script
extracts the server list from it, keeping names, commands and args, and rewrites
every env value to `SET-YOUR-OWN`. Riyan wires them up with his own credentials.

Two verification gates rather than one: no denied path in the output, and
separately no credential-shaped content, since a token in a settings file has an
innocent path.

**NOTES.md was dropped on 2026-09-06.** The earlier plan had you hand-write the
things only you know. You and Riyan have been driving Elenchus work together and
have covered it in person, so a written version adds nothing. What replaced it
is `SETUP-RUNBOOK.md`, which the builder ships automatically and which is
everything he has to *do* rather than everything you know.

### 1.5 Scan it, twice, and know what each pass misses

**The scan comes before the read**, which is the reverse of an earlier draft and
of nothing else in this document. The scan is thirty seconds and mechanical, and
what it surfaces tells you where to look during the read. Reading first means
reading blind.

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

Neither pass looks for a person. That is 1.6.

### 1.6 Read the bundle, hardest files first

This is the step that gets skipped and it is the one that matters. It is also
the one with no tooling behind it, so the useful thing this section can do is
tell you where the risk actually concentrates rather than telling you to read
everything with equal attention.

**Second pass, mechanical, before you read anything.** Neither scan in 1.5 looks
for a person or for a second venture:

```
cd ~/handover
grep -rniE '[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}|veldra|reservegrid|retnovation|execlog|\+1[0-9]{10}' .
grep -rn -A3 'provenance:' content-lift/candidates.yaml
```

The first finds email addresses, phone numbers, and every mention of the other
venture. The second is specific and it is the one to look at hardest.

**The lift banks are the highest-risk files in this bundle and you may not need
to send them at all.** Both tracked stubs say the real banks are "Veldra-derived"
in their own header comments (`content/lift/scenarios.example.yaml:2`,
`content/lift/candidates.example.yaml:2`), and each candidate carries a
`provenance.pointer` into an internal execution log, in the example's case
`"EXECLOG EX-028 (abstracted)"`. The design intent is sound, the stub says
"provenance is a POINTER, never quoted ore", but a pointer still names a real
internal record and a `frame_detail` can still describe a recognisable real
situation.

They are also conditional. No tracked caller uses the default bank names, the
suite is green without them, and Riyan needs them only for lift and mining work.
**If he is not doing lift work this week, delete both from the bundle rather than
reading them.** That converts the hardest reading job in this step into one
command:

```
rm ~/handover/content-lift/scenarios.yaml ~/handover/content-lift/candidates.yaml
```

Then read what remains, in this order:

1. **`docs/DEVLOG.md`.** The one that genuinely needs reading. It was written
   for an audience of one and it is the longest thing in the bundle. Read for a
   pasted credential, anyone's name, and anything about the other venture you
   would rather introduce yourself.
2. **`docs/lessons.md`.** Skim, but stop at every incident description. Lessons
   are written after something went wrong and what went wrong sometimes
   involved a person.
3. **`POSITIONING.md`** and **`NOTES.md`.** You wrote both. Re-read them as
   someone who does not already know what you meant.
4. **`docs/superpowers/`** and **`docs/spike-results/`.** Volume rather than
   risk. Design and plan documents named after engineering surfaces. Skim the
   list, open anything whose filename is not obviously technical.
5. **`docs/SESSION_HANDOFF.md`.** Confirmed clean 2026-09-06 on the specific
   ground that no invitation has been run. Read it anyway, once, because that
   ground is circumstantial and this is the last moment it is free to check.
6. **`claude-config/CLAUDE.md`** and **`ENVIRONMENT.md`.** Doctrine you wrote and
   a document generated from tracked code. Lowest risk in the bundle.

**Stop here until both scans come back clean and you have read at least items 1
and 2.**

---

## Part 2. Grant access

**This is the first irreversible step.** From the moment Riyan accepts the
`felix` invitation he can clone, and removing the seat later removes future
access, not the copy on his disk. Everything in `LeavesJ/felix` is disclosed
permanently, which is what was decided.

**2.1 Nothing to add. Verified 2026-09-06 against the API:** Riyan
(`InsertWittyCommentHere`) already holds `write` on both `LeavesJ/Elenchus` and
`LeavesJ/felix`, and has since before this handover began.

Two things follow. Felix was already disclosed, so **Part 2 is not the first
irreversible step** and the sequencing this document was built on was wrong from
the start. And `read` was never available: a personal GitHub repository has one
collaborator level and it is `write`. An org-owned repo is what makes read-only
possible, and that is a move for the day Felix becomes a company tool.

`main` on `felix` is also unprotected, unlike Elenchus's, so the gate contract
is his to change. Reviewed and accepted as is on 2026-09-06: he is a cofounder
with a signed CIIAA and no reason to touch Felix. The onboarding document states
the norm plainly rather than claiming an access boundary that does not exist.

**2.2 His Elenchus role. Verified, nothing to do.** `write`, not `admin`.

**2.3 Elenchus `main` protection. Verified, nothing to do.** `protected: true`
on 2026-09-06.

**2.4 Issue his Anthropic key.** His own workspace, his own spend limit, so spend
stays attributable and either machine can be revoked without touching the other.
Send it through a different channel from the bundle.

**So Part 2 is one step: issue the key.** Everything else was already true.

**Verify:** ask him to clone `LeavesJ/felix` and confirm `git log -1` works. He
will see `HANDOFF.md` and `projects/veldra/`. That is correct and expected.

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
`felix which` names `elenchus`. He never needs to push to `felix`: it writes
only into a gitignored `state/` in the clone and into his own
`~/.felix/memory/`.

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

Seven things nothing in either repository enforces. They live here because there
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
6. **This bundle's safety expires when the first invitation goes out.**
   Confirmed 2026-09-06: thirty invitations are ready and none has been run, so
   the tenant root is empty and `SESSION_HANDOFF.md` has nothing invitee-shaped
   in it. Both of those are why the allow-list is safe today. Neither is
   structural. If you rebuild this bundle after the rollout starts, the script
   will pass exactly as it does now and the contents will no longer be clean, so
   anything derived from the memory root has to be read line by line first.
   Doing the handover before the beta rather than during it is the largest piece
   of luck in this sequence.
7. **The beta is yours.** There is no invitee registry in code; the operator
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
