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

- **Restore the fixture state you changed, and assert that you did.** Declaring
  what a section depends on is only half the rule. One new suite section seeded
  a route table, seeded an evidence policy, created a branch called
  `feature/thing` and committed on it — then broke four later assertions in a
  way that read as a routing bug, because routing scores the branch name and
  `feature` is a keyword of the `build` route. The cleanup itself then failed
  three times, silently every time: `git checkout` refused because deleting a
  tracked file had dirtied the tree; `rev-parse --abbrev-ref HEAD` returned the
  literal string `HEAD` on a detached head; and the branch it tried to return
  to was unborn, because that fixture has no commits until a later section
  makes the first one. Point HEAD back with `git symbolic-ref` rather than
  checking anything out, and end the section asserting the fixture is as it was
  found. A cleanup nobody checks is the same as no cleanup.

- **A `local` statement cannot see a variable it is declaring.**
  `local proj="$1" f="$proj/routes.tsv"` leaves `f` empty at best, and under
  `set -u` it is an unbound variable that kills the function — so the caller
  sees "no such route" or "no such file" rather than a syntax complaint, and
  the bug reads as missing data. Written twice in one session, an hour apart,
  in two different libraries, the second time by the person who had just fixed
  the first. Declare the parameters, then declare anything derived from them on
  the next line.

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

- **A deny pattern matches the command string, not the command.** Verifying the
  widened `PreToolUse` meant driving the deployed hook with sample payloads, and
  one of those payloads quoted a forbidden command as a literal. The live hook
  refused the whole script. Nothing was being force-pushed; the text was inside
  a single-quoted argument to `printf`, on its way to a *different* process. The
  rule cannot tell those apart, because a `deny.tsv` pattern is tested against
  the command string as one blob and matches anywhere inside it. So any script
  that documents, tests, echoes or greps for a forbidden command is itself
  forbidden. This is not a bug to fix — anchoring the patterns would break the
  compound-command case they exist for, which is the more dangerous direction —
  but it is the reason a verification script has to use neutral probe patterns
  rather than the project's real rules. Reach for a temporary row with an
  invented pattern, and do not work around the refusal, which is what
  reconstructing the string from fragments would have been.

- **A test can be green because it cannot reach the branch it names.** Three
  assertions called "a bundled plugin reads as usable" passed on the laptop for
  every commit of their life and failed on every CI run, and the reason was the
  same fact in both places: the code path they describe only executes where no
  `claude` CLI answers. A laptop always answers, so the assertion ran against a
  different branch and reported ok; a runner never answers, so it ran against
  the right one and found a real defect sitting there — the 0.26.0 bundled fix
  had been written one branch *below* the short-circuit that returns first. The
  lifecycle roster test had the identical shape: it discovers events from what
  the machine binds, so on a bare runner it discovered nothing and asserted
  nothing, which is precisely the failure the roster was built to prevent,
  reproduced inside the test for it. **When a test depends on the machine, make
  the machine part of the fixture** — a stripped `PATH`, a fixture `HOME` — or
  the suite is only ever testing the developer's laptop. And when CI and local
  disagree, CI is the one standing in the branch nobody can reach by hand.

- **Comparing lines compares formatting, not meaning.** The verifier channel
  decides whether a change *removed* something from a table that decides what
  stops, and the first implementation compared non-comment lines before against
  after. It fired on the commit that added two keys to `project.json` and
  removed nothing — because JSON has no trailing comma, so adding a key rewrites
  the line above it, and a literal comparison reads that rewrite as a deletion.
  The most ordinary edit anybody makes to that file was the one it flagged.
  Found by running the check against its own commit rather than by reading it.
  Two things generalise. Normalise before comparing, or the check is about the
  serialiser rather than the content. And a stop that fires on ordinary work is
  worse than no stop at all, because it also teaches people to skim past the
  ones that mean something — which is the same complaint Felix makes about
  other people's plugins, arrived at from the inside.

- **Some stops cannot be placed where they belong, because the gate needs the
  thing they would block.** Freeing the plugin-version bump to merge was meant
  to come with a compensating refusal in `felix install` — do not deploy an
  engine whose HEAD is not on `origin/main`. It cannot work. `felix gate` has an
  `installed` check comparing the tree to the deployed cache, so an engine
  change must be installed *before* the gate can go green, and the gate must be
  green before anything is pushed. Install-then-gate-then-push is a cycle, and
  any refusal keyed on "already pushed" deadlocks it. Establish that a proposed
  guard is reachable in the real loop before writing it down as the mitigation
  that makes something else safe.

- **Utilisation is not utility, and the ledger was punishing prevention.** The
  capability ledger claimed a zero "has no alternative explanation: it was
  mounted, it was in scope, and it was ignored every time." Three explanations
  it could not distinguish: the session never recognised the need, which is a
  routing defect charged to the capability; the capability works by presence and
  is never invoked when it succeeds, which is every deterrent — a deny rule
  nobody trips reads exactly like a deny rule nobody needs; and Felix itself
  chose both what to mount and what to point at, so the log records the logging
  policy. That last one is the recommender-bias shape and it is self-confirming:
  it accumulates into something that looks like a dataset and is a mirror. The
  half-fix is recording what the policy *named* beside what was reached for,
  which is cheap because the naming was already computed and thrown away. The
  unfixed half needs an exploration arm, and exploration costs real sessions.
  **The general form: when a measurement is produced by the thing being
  measured, write down the decision as well as the outcome, and do it before the
  data exists rather than after.** The correction cost an hour today; a year of
  that data would have been unusable and would not have looked it.

- **A fallback carries the semantics of the feature it was written for.**
  `user-prompt` derives `sid` from the payload and falls back to a repo-derived
  key when the session id cannot be read. That fallback exists for
  announce-on-change dedup, where two concurrent sessions sharing a key costs
  one missed suggestion — a deliberate, documented, benign degradation. Ledger
  recording was then hung on the same variable because it was in scope, and it
  inherited a degradation that is not benign there: `post-tool` and
  `session-end` both *exit* rather than invent a key, so the named half would
  land under a repo-shaped name nothing ever rolls up while the calls half went
  to a real session. With several terminals open on one checkout those orphans
  accumulate into a single pseudo-session with names and no calls beside them —
  reading as "pointed at and ignored", which is the one shape that proposes
  retirement. **Before reusing an in-scope variable, read why its fallback
  exists.** The value was right; the failure mode attached to it was not.

- **"Nothing due" and "nothing is being checked" render identically.**
  `maintenance.tsv`'s third column takes `always` or a capability name; anything
  else resolves to dormant. Felix's own table used `-` for all four routines, so
  every one was inert from the day it was written and `felix maintenance` said
  "Nothing due" every single time — which is exactly what a well-kept repository
  looks like. Elenchus's table used `always` and worked fine, so there was no
  contrast to notice. Found by building the command that *ranks* upkeep, not by
  reading the table: the ranker asked for due rows and got none from a project
  with four overdue routines. Third instance of this shape after the ledger
  overclaim and the coverage roster. **A report whose empty state is
  indistinguishable from its healthy state needs a check that the inputs can
  even produce a finding** — `felix_maint_unreachable` is that check here, and
  it deliberately does not flag a real capability left undeclared, because that
  is a dormant row working as designed.

- **A backlog entry is a claim, and it can be stale in the same way code is.**
  "Convert the pure recommenders: `doctor`, `handoff`, `promote`, `recommend`,
  `which`" misfiled three of five. `handoff` already wrote a file, `which` is a
  query with nothing to do, and `recommend` deliberately installs nothing with a
  suite assertion behind that decision. Building all five as written would have
  broken a tested decision and added noise to two commands that were correct.
  The entry was written once, months of sessions read it as a specification, and
  nobody checked it against the commands. **Read the thing before implementing
  the note about the thing** — the same discipline as reading a file before
  editing it, applied to a plan.

- **A status table is the least trustworthy thing in the repository.** HANDOFF's
  exit-criteria table was hand-maintained, read as a specification for weeks, and
  wrong in nine places at once: it claimed 334 tests when there were 570, claimed
  a browser verification whose only record was the sentence claiming it, and said
  "Felix can merge" in bold about a command that could not merge. Everything
  around it — the gate, the ledger, the coverage table — regenerates or is
  checked. The table did neither, so it aged into fiction while every session
  read it as ground truth. **Re-run a cell before editing it, and prefer a table
  that a command regenerates to one a person maintains.** The tell is that no
  entry ever gets worse without somebody deciding to write that down.
