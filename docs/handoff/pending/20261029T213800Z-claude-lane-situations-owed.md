### 2026-10-29: the capability lane restarted, and the founder's decisions on what Felix is

**Docs only so far (branch `claude/lane-situations-owed`).** This session
checked the capability plane against direction. It laid out every
capability-plane design on file in one document
(`docs/2026-10-29-capability-plane-designs-on-file.md`, with its PDF), and it
worked through the thesis with the founder in conversation. The lane's first
item is not built yet: intake, the intent design's §9 slice "situations owed".
He approved its design on 10-29, with the lane counter and come-backs, and a
build plan per slice follows.

**Why now.** The founder, 10-29: "supposedly, according to your direction map,
we should have begun working on capability plane simultaneously long ago. You
can check the directions marked down to verify that statement. I think we
really need to get it going."

**What was found.**
- From row 25's note (10-19 07:18 UTC: build intake now) to `e54e31f3`
  (10-29), 17 landings reached main. One was a lane item: the mods round's
  report (#451, lane item 2), that same day. None was intake. The engine
  landings went to the audit, gate and suite work, a discovery test, the
  lost-work page and inventory, and the pattern-kill deny row.
- The 22 proposed obligations are still at 0 admitted.
- Nothing starts a lane session unless the founder or the carrier does.
  Nothing counts the one-in-four share of row 15, so the lane fell to zero
  without a warning.
- The audit swept the code that exists, which is mostly trust code, so it
  could not see what was never built. This is the stagnation of 09-25 again.

**Founder decisions, binding from this section.**
1. **The first client is a generic software development team.** The rumored
   industrial prospect is not standing ground: "this is rumored, unconfirmed.
   don't make this the standing ground. Just envision that our first client
   will be a software dev team". Read row 28's "keep that weight in view" this
   way. Egress control is one enterprise ask among others, not a
   prerequisite.
2. **Felix's role is the senior manager over the whole pipeline.** In his
   words, Felix is "dynamically in charge of disaptching + communicating +
   organizing (again senior manager remember) role, delete distribute tasks,
   all of the above, plus the entire pipeline of from ideas, to skills/tools
   installations, ledger, contract, answers, obligations, routing, model
   adjustment, token optimization, scaffolding, and more I did not name." He
   was asked which of four ideas felt most like Felix: the standing need
   ledger, the contract and lease, answers at the moment, and one
   obligation's whole life. He chose all four.
3. **An engineer's run ends in one shot, with no questions.** The options were
   "Done, plus what it owed", "Questions, then done" and "Plan to approve,
   then done". He answered: "Final state should be that second option is not
   even an option bc felix's pipeline already figures out everything. 'what
   changed owed that nobody asked for' is indeed the hardest part isn'
   it...there's so many things. But we'll design it when we get there".
4. **Positioning: the independent manager.** He chose it over "Senior
   engineer, as pitched" and "Orchestrator first". Felix is the engineering
   manager your agents report to, whoever made them. It decides what the work
   owes, who checks whom and what counts as done, and dispatches through the
   agents the team already uses. Its number is verified work per hour of the
   team's attention. Felix rents the dispatch, and it owns the judgment and the
   cross-vendor record of accepted outcomes. The pitch (tag `pitch/2026-10-27`)
   is his document and is not edited here.
5. **The lane's share is half until intake lands, then one in four.** He chose
   it over "One in four, enforced" and "Felix sets the share"; row 15 gives the
   share to him. Felix counts the share. Whenever the lane is short, the first
   open lane item goes to the next session that starts without a task from
   him, and trust work gets the other half in the meantime. "Intake lands"
   means the intent design's §9 slice merges on main.

6. **Two editions, enterprise first.** He set out "a clear enterprise versus
   commercial separation". The commercial edition is for "founders and people
   who want to build but lack the engineering hygiene and the entire
   engineering team to do so, right? Like a solo company founder". The
   enterprise edition is for software teams, where "a lot of things overlap,
   but there are some small details that are like very critical to change".
   Enterprise comes first: "that'd be very enterprise oriented which is what
   we're doing first for our potential users". In a team, Felix starts
   underneath, briefing agents and checking changes, and "later becomes this
   figure inside slack". He expects enterprise to be "a lot harder to build",
   with commercial derived from it afterwards. He then drew the scope line:
   "I don't want to make it so this becomes another Claude duet, ChatGPT
   bots", and "we should really stick with the engineering ground first, and
   later use the engineering leverage to introduce the departmental liaison".
   More interaction between managers and engineers, and a better Slack
   presence, come "once we ship the MCP later on".
7. **Inside a company, the first champion is the engineering manager, and the
   target is the whole engineering department.** In his words: "entire
   engineering department, so ig engineering manager....but like that'll just
   be natural you know once the autonomous engineering control plane is built
   it'll spread across entire engineering department". On how Felix's value
   shows inside a team, he said (22:41 UTC): "And for Enterprise we really
   need to make sure the additional value of Felix is still visibily present
   bc before with solo founder felix's upside is clearly shown...how we
   reflect inside an engineering team will need careful positioning."
8. **A change to the lane's share lands on green.** Asked whether a change to
   the share should wait for his merge, he chose "No, it lands on green" over
   "Yes, it waits for me", which the session had recommended. `felix lane`
   names the commit that last changed the share, so a change shows, but
   nothing holds it.

**This session's reading, not his decision.**
- **Model adjustment and token optimization.** He pointed at report v5: "it's
  in the docs we had...i remember second report had many points in there a
  lot of design brainstorming". The 10-01 review's ruling, row 17 (D1),
  already covers what he listed:
  - the host picks the model;
  - Felix raises the model when the stakes call for it, and escalates a failed
    check by one tier;
  - it keeps accepted outcomes per model, and saves tokens through context;
  - the held-out replay decides whether adaptive routing is built.

  Row 17 stands unchanged.
- **Two guesses.** The session played back two guesses and he did not correct
  them:
  - "organizing" includes cancelling or reassigning tasks mid-run;
  - Felix may mount a tool by itself once it has shown it can use that tool
    well (his 10-29 floor).

  Treat them as this session's reading until he confirms them.
- **Felix as software, not only a plugin.** He asked: "do you not think we need
  an actual software?". The session proposed three layers, which he has not
  confirmed:
  - the judge stays a small deterministic engine on bash and git;
  - plugins become adapters, one for each host or tool;
  - new software sits on top: a desktop app for the commercial edition, and an
    org service for the enterprise edition that keeps the company's code inside
    the company.

  Felix cannot run on a server today.

**Not done.**
- The lane counter and the hand-off are not built.
- The strategy pass is still pending: whether the invariants hold, what is
  missing, and whether intake-first is the right order.
- The design for the lane's first three slices
  (`docs/2026-10-29-capability-lane-first-slices-design.md`) was approved by
  the founder on 10-29, then corrected after a fact-check. A build plan per
  slice is written and checked against main at `01e24cfc`
  (`docs/2026-10-29-lane-slice-0-plan.md`, `-1-plan.md`, `-2-plan.md`). The
  plans wait for his review; each slice is then built by its own engine-build
  Workflow, slice 0 first.
- Folding items 1 to 8 into `docs/direction.md` waits for his yes in its own
  draft PR.

### 2026-10-31: slice 1 build

Slice 0 landed on main as #480 (0.49.319, `deca9fdc`) on 10-31. This
session merged `origin/main` into the branch at the starting session's
instruction (the plan says rebase; `felix merge` copies only non-merge
messages into a landing, so the lane mark survives either way). Both
conflicting documents, the design and slice 0's plan, took main's text,
which is the landed and later one.

**Pre-flight (Task 1), 10-31.** Four open engine PRs: #452, #425 and the
old drafts #365 and #360 (the limit is 10). Parts
2400 to 2470 are free on `origin/main` and on every open PR head.
`tests/run` has 487 lines on `origin/main`; #452 adds 2 and this slice 8,
so 497 of 500. (#365 and #360 rewrite the pre-parts driver and do not
apply.) `ListAgents` showed no other session on the branch.

**The seed.** `engine/harness/templates/situations.tsv`, eight rows, one per
failure mode the design names in §7.2. Every source is a survey candidate:
`candidate:` and the first 12 hex digits of `git hash-object --stdin` over
the candidate's whole row in the memory root's `candidates.tsv`, without its
trailing newline. The passages, quoted from each row's rationale cell:

| Class | Source | Candidate | Passage |
|---|---|---|---|
| `paid_ingress` | `candidate:629281b96896` | Elenchus `public_bind_has_spend_ceiling`, uncontrolled_cost | "The ceiling defaults on only inside serve_invitee.build_env; python -m elenchus.web with ELENCHUS_HOST=0.0.0.0 and ELENCHUS_DB set boots with spend.from_env returning None, so the other entrypoint serves unbounded paid calls to whoever reaches it." |
| `route_has_http_test` | `candidate:63d76b1dc780` | Elenchus `served_route_has_http_test`, untested_route | "POST /api/session/{sid}/expectation is requested by no test: record_expectation is tested on the registry, but the route, its _Expectation body and the token field the client echoes are not, so a rename would pass the suite and silently drop every forecast." |
| `request_body_bounded` | `candidate:e9a611a8b5c5` | Elenchus `request_text_bounded`, unbounded_storage | "No request str field declares max_length: /outcome and /expectation store the learner text verbatim with zero model calls, outside the spend ceiling, and an oversized /say dies past model.py 20000-character raise inside the worker instead of a 422 at the boundary." |
| `health_reflects_readiness` | `candidate:48b1d341c3c1` | Elenchus `health_reflects_model_key`, false_green | "/api/health answers ok:true with no ANTHROPIC_API_KEY, the L-18 shape paid for three times; only serve_invitee refuses a keyless launch, so python -m elenchus.web, or any monitor polling health, still reports a dead instance alive." |
| `local_listener_binds_loopback` | `candidate:b1f19fc348dd` | Elenchus `invitee_launcher_binds_loopback`, privacy_exposure | "serve_invitee.py defaults --host to 0.0.0.0 though both its tunnels dial localhost, so anyone on the same network can POST /api/session and read the live transcript around Cloudflare Access; the product's own preflight open-listeners check fails on this default." |
| `ci_actions_pinned` | `candidate:1d0f456b27c1` | Veldra `actions_pinned_to_commit`, supply_chain_compromise | "None of the 37 action references in either workflow is pinned to a commit and dtolnay/rust-toolchain@stable is a branch, so a moved tag runs with the GHCR push token and, in release-desktop.yml, the updater signing key." |
| `ci_secret_scoped_to_step` | `candidate:eb650849fb47` | Veldra `secrets_scoped_to_step`, signing_key_exfiltration | "release-desktop.yml sets the Tauri updater signing key and its password in workflow-level env, so npm ci install scripts and every third-party action in every job can read the key that signs auto-updates shipped to customer desktops." |
| `container_runs_unprivileged` | `candidate:159d1ead7b06` | Veldra `container_runs_unprivileged`, privilege_escalation | "rg-auth's image never drops root while holding the Ed25519 license signing key and the account database, and docker-compose.setup-b.yml, the mainnet node stack, runs pool-verifier and template-manager as user 0 on the host network." |

**R1 to R4.** `<cap3>` is `local_listener`. R1 is `paid_ingress`. The
HTTP-keyed classes (R2) are `paid_ingress`, `route_has_http_test`,
`request_body_bounded` and `health_reflects_readiness`. R3 is
`local_listener_binds_loopback`. The named R4 class is `ci_actions_pinned`;
`ci_secret_scoped_to_step` and `container_runs_unprivileged` also hold no
term on `api` or `local_listener`.

**Calls made in the seed** (design §10 leaves the rows to the builder):
- Three capabilities no detector names and no project grounds yet:
  `local_listener`, `ci_secret` and `container`. Each is a `probe:` term,
  so where no probe grounds it the term is unbound and the class could not
  look, which is §7.10's first limit. Veldra's container probe grounds
  `deploy`, not `container`, so `container_runs_unprivileged` reads could
  not look there until a probe grounds `container`.
- `class_by_maturity` never decreases, rises to `RELEASE_BLOCKING` at most,
  and holds `AUTHORITY_BLOCKING` nowhere: no row is a protected boundary.
  It is printed only, and the founder's reading rides slice 4's admission.
- No row has an `env:` term: no project declares a maturity, so such a term
  reads undecided on all three, and R1 forbids one on `paid_ingress`.

**A departure from the plan: the libraries load lazily.** The plan's Task 4
put three source lines after `lib/facts.sh`, at `felix`'s top level. Then
`felix gate`, `felix merge` and `felix land` would load `lib/situations*.sh`
on every run, and a broken top level there would break them. Direction row
39 (in the fold, draft #481) calls code that a hook, the gate or landing
runs high-stakes, and design §4 puts that at B3. So by Felix's reading, which
the starting session raised at 18:3xZ, the eager load would have made this
slice a high-stakes feature. It would then inherit the shared-code defects
the founder refused at 18:13Z, and it would have to open as a `needs-founder`
draft under decision 7b. Instead, `cmd_situations` sources its three
libraries inside its own body. That is how `cmd_audit`, `cmd_inventory` and
`cmd_cost` already load theirs (`felix:245-273`). `felix` itself carries only
the usage entry, that short function and the dispatch line. The slice stays
below B3 and lands on green. Its unchecked limits are listed here and in the
PR, as decision 5 says for such code.

**Blind parts (Task 2).** Five authors (Opus 5.5, high) wrote the eight
parts in one workflow (`wf_c56d0007-d12`, 16 minutes) from the design, the
plan's Contracts and the seed, without reading `felix`, `lib/`, `hooks/` or
`bin/`. Committed as `fbd44a32`. Where the Contracts left room, they read:
the side in `--at` mode is `at`; the admit command holds `\t` and `\n` as
text, and only the `row` line holds tab bytes; a trailing tab is a field
count, not an empty cell; the usage lines come directly after `felix
obligations`; `--at=x` and `--change -x` are usage errors; `"maturity":""`
declares none; and the scratch directory is checked before the recorded tree
or the base.

**Red on main (Task 3).** The red tree is `origin/main` at `1fca9559`
(0.49.320) with this branch's `engine/harness/tests`. Each part ran alone
through the four-slot helper, under BWK awk. Every part reached
`@@part-done`, with no FAIL before `@@prelude-done` and no harness error.

| Part | FAIL on main |
|---|---|
| 2400 table | 26, after the fix below (the first run: 25, and one passed) |
| 2410 recorded | 81 |
| 2420 change | 62 |
| 2430 output | 106 |
| 2440 web fixture | 45 |
| 2450 cargo fixture | 29 |
| 2460 seed siblings | 2: the part reads the shipped table at run time, and main has none, so only the ledger and the network check run |
| 2470 review focus | 30 |

One 2400 assertion passed on main: "schema-check, run in a tree holding only
schemas.tsv and the shipped situations.tsv, exits 0". The copy of the absent
table copied nothing, so schema-check checked one table and passed. It went
back to a blind author (Opus 5.5, high), as Task 3 says. The assertion now
also compares a token for each template copied byte for byte. On main it
reads `situations.tsv not copied`, and all 26 of 2400's assertions fail
there. On the branch it passes. No other assertion in the part held without
the table.
