# Lessons

Written down when something cost time, or would have cost it twice.

## Always

Run the gate before claiming anything is done. The Stop hook enforces this now,
but it blocks once per chain and fails open on every error, so it is a reminder
with a record, not a substitute for running it.

- **A suite section that inherits fixture state reads like a product bug.**
  `tests/run` rewrites the widget project's gate in several places to prove
  different things. A later section assumed the original gate and asserted that
  a failing gate blocks; by then the gate was `true`, which cannot fail. Two
  assertions went red and the hook looked broken. It was correct the whole time,
  and reproducing it standalone passed immediately, which is the tell. A section
  that depends on a fixture value must declare that value itself.

- **A check that skips absent files passes by finding nothing.** The first
  version of the gitignore guard looped over `projects/*/memory/*.log` and
  skipped anything not present. In a worktree those files are untracked and
  therefore absent, so it reported ok while proving nothing. `git check-ignore`
  evaluates a path whether or not a file is there. Assert the rule, not the
  filesystem — and show the check failing before believing it, which is already
  the constitution's fourth invariant.

- **`tests/run` computes the harness path from `$0`.** It does
  `REAL_HARNESS="$(cd "$(dirname "$0")/.." && pwd)"` and then `cp -R` that into a
  temp root. Copy the suite anywhere outside `engine/harness/tests/` and it
  resolves to the parent of wherever it landed: from `/tmp` it began copying the
  root filesystem, reached 18GB, and the `cp` survived its parent shell as an
  orphan reparented to init, so every attempt to delete the temp directory lost
  ground until the copy itself was killed. Debug the suite in place.

- **Verification has no native record anywhere in Claude Code.** Transcripts
  carry `is_error` on tool results; Bash results carry stdout and stderr but no
  exit code. Whether a gate passed exists only if Felix writes it down. That is
  what `memory/verification.log` is for, and why the completion gate was built
  before the capability ledger that depends on it.

- **A changed engine at an unchanged version never deploys.** Claude Code
  caches a plugin by version, so `claude plugin install` and `claude plugin
  update` are both no-ops on a same-version change and both report success.
  Adding an already-registered marketplace also does not re-read the manifest,
  so a bumped version stays invisible until `marketplace update`. Three
  separate defects, all hidden behind cheerful output. `felix install` now
  diffs the tree against the version the CLI reports as live and is the only
  thing that speaks. Announcing a deployment is what let this recur.

- **A redeployed engine never reaches the session that deployed it.** Hooks are
  bound at session start. `felix install` updates the cache and the CLI on
  PATH, and every later `felix` command runs the new code, so verifying a hook
  fix through the CLI passes convincingly — while the hook still firing on
  every prompt is the one loaded hours ago. An envelope fix was built, tested,
  deployed, verified three times, and reported as live for every session on the
  machine; the session that shipped it kept misrouting through the old hook for
  the rest of its life, and the routing log kept recording the raw payload the
  fix existed to remove. Read the version in the SessionStart banner before
  claiming a hook change is in effect here. It is in effect for the *next*
  session, which is a different and much weaker claim.

- **A record written inside the tree it describes invalidates itself.** Felix's
  home is the Felix repository when Felix governs itself, so the gate receipt
  landed in the tree whose identity it recorded. Writing it changed the tree,
  which invalidated the receipt just written, and no gate run could ever
  produce a valid one. The suite never saw it because its fixture puts the home
  outside the governed repo — true of every project except the one Felix is.
  Test the layout you actually run in, not the convenient one.

- **Banning a word to silence a field name breaks the word.** The prompt hook
  is handed whole JSON, so the envelope\'s keys are in the token stream and a
  route keyed on `prompt` or `hook` scored every turn. The first fix blacklisted
  those words — and then asking "the stop hook is blocking" matched nothing at
  all, because `hook` had been banned to silence `hook_event_name`. Remove the
  structure, not the vocabulary: a JSON key is a quoted word followed by a
  colon, which no sentence contains.

- **Write route keywords in their shortest form.** A keyword matches when it
  appears inside a word you typed, so `hook` matches "hook" and "hooks" while
  `hooks` matches neither "hook" nor "hooking". Felix\'s own table said `hooks`
  and stayed silent the first time anybody asked it about a hook.

- **A trap body is evaluated when it fires, so it cannot reference a `local`.**
  By then the function has returned and the variable is gone, so under `set -u`
  the cleanup dies on an unbound variable and leaves behind exactly what it
  existed to remove. Use a global and guard it: `trap 'rm -rf "${VAR:-}"' EXIT`.
  Made twice in one day, in two functions of the same file, because the first
  fix was explained in a commit message.

- **Explain a fix where the fix will be read again.** A commit message is
  written once and never mounted; `lessons.md` is injected into every turn that
  matches it. The trap bug above was diagnosed correctly, fixed correctly, and
  described beautifully in a commit nobody would ever read at the moment of
  repeating it. If it is worth explaining, it goes here.

- **A lesson written down is not a lesson applied.** This file already carried
  the pipefail trap — `producer | grep -q x` reports 141 because the consumer
  exits first and the producer takes SIGPIPE — and it was written in this very
  repository, by this project, about this exact failure. It happened again
  anyway, as an `awk` that exited on its first match inside `felix discover`:
  every candidate resolved to "no source" while the identical call by hand
  worked perfectly. The rule generalises past grep. **Any** consumer that stops
  early kills a pipeline under `set -o pipefail`. Read to the end and decide
  afterwards.

- **A command substitution is a subshell, so it cannot cache anything.** A
  helper memoised which `stat` flavour the platform had, and was called as
  `$(helper "$f")` inside a loop. Every file re-probed, three processes instead
  of one, 510 spawns on a checkout with two untracked backup directories: 1.9s
  on every attempt to finish, down to 0.22s once both stat implementations were
  handed every path at once. Memoisation and `$( )` do not compose.

- **Instrumentation can be the thing you are measuring.** A `bash -x` trace with
  a timestamped `PS4` blamed loop bookkeeping and reported 9.6s of work. The
  `PS4` was spawning a `date` process per traced line. Time the whole thing
  first, confirm the number is real, and only then narrow.

- **A hook payload's envelope is not what the user said.** The prompt hook is
  handed whole JSON and tokenises it deliberately. A comment claimed the extra
  field names cost nothing in a keyword match; they cost everything, because the
  envelope contains `prompt` and `system` and any route keyed on those matched
  every turn regardless of input. A comment asserting something is free is a
  claim, and this one was never checked.

- **Signal from where you are standing must never outvote signal from what you
  said.** Uncapped, a few hundred untracked path tokens drown four typed words,
  and prompts route to whatever stale directories happen to be about. The tree
  corroborates; it does not vote.

- **Run the deployed thing against the real repository.** Both defects above
  survived a green 233-assertion suite and were found within minutes of
  executing the installed hooks by hand. The suite tests the code; only running
  it where it will run tests the deployment. Third occurrence of this shape.

- **Ask what a measurement is caused by before acting on it.** Usage counts
  cannot show a capability is useful, because loading it is what causes it to be
  used. Absence of use given presence is the unconfounded direction, and it is
  the only one worth acting on. The same shape will recur anywhere Felix
  measures something it also controls.

- **An inline plugin cannot be uninstalled, and the CLI says it can.**
  `claude plugin uninstall togetherai-skills` printed "Successfully
  uninstalled". Afterwards `claude plugin list` showed nothing, the on-disk
  registry showed nothing, `settings.json` showed nothing — and the plugin was
  still there, because `~/.claude.json` carries it as `name@inline` and its
  skills stay live in every session. Felix reported it as present and was
  right; three separate CLI views were wrong together. Backing out an adoption
  is therefore not always possible by uninstalling: undeclaring it in
  `stack.tsv` and removing it from every play stops Felix reaching for it,
  which is all Felix can promise. Never report something as removed on the
  strength of the command that removed it saying so.

- **Establish who set a limit before reporting it as one.** A rule in Felix's
  own doctrine, invariants or CLI is a decision, not a constraint, and it reads
  exactly like a real limit to every later session. Twice in one turn a ceiling
  Felix had built for itself was described as though it were the platform:
  "Felix guides rather than acts" was called principled when Felix had wired 3
  of Claude Code's 9 hooks and skipped `PreToolUse`, the only one that can deny
  an action; and "Felix does not install" was called a well-founded refusal
  when `claude plugin install` exists, `felix discover` already reads a
  candidate at its pinned sha, and the refusal was a single `die` in Felix's
  own CLI. Before writing that something cannot be done, check whether the
  platform exposes it and whether the refusal lives in a file this repository
  owns. If it does, say so plainly and default to overriding it. Reserve
  "impossible" for cases where a specific mechanism can be named.

- **A charter narrower than the intent regenerates the drift every session.**
  Felix's constitution opened with "the governance layer", and Felix built
  exactly that: a complete vocabulary for saying no — gate, classify, evidence,
  quarantine, guard, scope — and not one word for saying "do this next". The
  guidebook had asked for the whole loop, with governance as one box of
  fourteen, and for the OS to own implementation planning and execution. Six
  boxes came out strong; the one at the centre, plan and route and dispatch,
  was a third built and that third only printed advice.
  Nothing here was a mistake given the charter, which is why it compounded for
  weeks instead of surfacing: every session read the sentence, followed it
  correctly, and reinforced it. The founder noticed, not the gate. A doctrine
  file is mounted into every session and is therefore the highest-leverage
  place to be wrong, so when work keeps coming out subtly off-target, suspect
  the first paragraph of the constitution before suspecting the work.

- **A three-letter term can never be a route keyword.** `felix_route_tokens`
  drops every typed token shorter than four characters, so `pdf`, `api`, `sql`,
  `css` and `ci` are gone before scoring begins. A `document` route keyed on
  `pdf` was written, declared, and would have matched nothing — an attached
  `report.pdf` tokenises to `pdf` and is discarded. It was caught by routing a
  real sentence through it rather than by reading the row, which is the only
  way it could have been caught. The floor also runs the other way: a short
  *keyword* still matches inside any long word containing it, so `arm` in the
  probe route quietly matches `harm`, `alarm` and `farmer`. Route a real
  sentence through every new row before believing the row.

- **`felix route --promote` reads the envelope, not the prompt.** The scoring
  path strips JSON keys; the log does not. `felix_route_log` stores `$want`
  verbatim, so every miss written to `routes.log` carries `session_id`,
  `transcript_path`, the session UUID and every component of the transcript
  path. `--promote` tokenises that and ranks `users`, `claude`, `projects` and
  `a14808` above anything a person typed. Those appear in *every* miss, so they
  cross the threshold first and permanently, and the pollution is already on
  disk. Same lesson as the envelope bug next door, in the one place the first
  fix did not look: fixing a read path leaves the write path storing the thing
  you stopped reading.
