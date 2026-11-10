# The hosted trust authority: who moves main, and on whose word

2026-11-09, revised on 2026-11-10 (dates in UTC) after the founder answered its calls. A design for the authority that `docs/2026-11-07-trust-plane-design.md` §4.8 and direction row 43 call for. It is the step that design names "the queue owns landing" (§9, step 4). The measurement beside it is `docs/2026-11-09-trust-hosted-authority-spike.md`.

**Scope.** A design. It decides what the authority is and how it works, which is Felix's to decide, and it records the founder's answers to the calls that were his (§9). Nothing is built. No account, repository, App, login or setting was made or changed, no credential of the founder's was touched, and nothing in `engine/` changes. The spike makes its own keys and tokens for each run and removes them with it. Statements about GitHub are from its documentation, read on 2026-11-09, unless a row says they were read from the API. None of them was exercised.

**What this revision changes.** The first draft kept main at GitHub and made the wall a GitHub rule. The founder sent that back: "Is there no design that does not require such strict bonding to Github plans?" and "it should run indpendently". The 11-07 design had already said "The queue is provider-neutral" (its §5), and the draft drifted from that. In this revision main lives in a store the authority keeps itself, and GitHub is a connector. §10 lists what was replaced.

**Outside this document, and where each belongs:**
- review and commission evidence once worker receipts stop counting (design §4.4, §4.5);
- release and deployment transitions, beyond what row 49 already says (design §4.6, and §9 step 9);
- the suites of governed products, each with a partition of its own (step 3's open list);
- a sandbox for the worker's own sessions (direction, "Not before March");
- batching and reuse at the authority (design §9, step 8);
- the language (row 6);
- running the authority for other people's repositories: custody of their source, tenancy and terms (the product roadmap);
- a forge other than GitHub, and a project with no forge: §5.3 states what a connector is, and no second connector is designed;
- how the founder's door works: §5.5 says what it has to do, and not how.

**This is an open set.** The threats, mechanisms and cases below are the ones found so far, by one session over two days. A count says what it counted. A route found later is a new row (design §11).

## 1. Answer

- **Main lives in the authority's own store.** The authority keeps a repository that takes no push. It reads candidates from wherever workers put them, judges them, and moves its own main. The wall is who can log in to the authority's machine. It does not rest on a forge, a plan or a rule.
- **A forge is a connector.** With GitHub connected, pull requests are read from it and main is published to it. The published copy decides nothing. A push around the authority changes that copy and not main, and the authority puts the copy back or reports it. A change that was built on a defaced copy carries the defacement with it and is judged as a whole.
- **The founder speaks at the authority's own door.** His yes counts when it is given to the authority directly, about one exact commit, in person. Until the door exists, his yes is read from GitHub under his name, and that reading is worth what his token's custody is worth.
- **An authority is three things.** A store that it alone writes. A judgement that reads the candidate and that store, reads no file from a worker's machine, and runs repository code with no power. A signed record from which main can be checked link by link.
- **Each record is signed from the first landing.** Nothing that decides reads the signature. It is for a reader somewhere else: with it, a published copy can be checked without asking the authority.
- **It runs first on this Mac, under a second login, and then on a small rented server.** The first is a rehearsal: an agent is one admin password away. The move waits for the rehearsal's measured cost.
- **Today there is still no wall** (§2). The guard that exists keeps running until the authority has landed changes itself (§7).
- **The spike.** With main in the authority's store and no rule at the forge, 74 cases ran on the mock and none ended otherwise than expected (final run, 2026-11-10 from 00:47Z).
  - Each push around the authority changed the published copy alone. The next tick put the copy back, except where the authority was set to report and leave it, and where the founder's token had been used to lock the authority out of it.
  - A worker holding the founder's token for the forge moved no main and got no authorization, release or override.
  - Three cases put on main what should not be there. One is known and open (E7). Two run the kernel as it was before a fix (X1r, X7r).
  - Three cases shed a hold: a label under a new branch name (H6), and the interim falling to his token, twice (D1i, D2i).
  - This mode was written and tried over one day, and §8 says what review it has had.
- **The founder's calls are answered** (§9). Each act that follows from them is still his: a login, an account, an App, a key.

## 2. Today, measured

Read on this Mac on 2026-11-09 at 19:54Z by `spike/today.sh` (`logs/today.tsv` in the audit folder). The probe changes nothing: it reads permission bits, the lander's PATH and four read-only API answers. It asked `gh` whether the token could be printed, and kept the exit status alone.

| What | Read | So |
|---|---|---|
| The token a session uses | Any process of this user can read it. Scopes `repo`, `workflow`, `gist`, `read:org`. Admin on felix-home | At GitHub, a worker is the founder |
| A rule on main | The branch-protection and ruleset APIs both answer 403: "Upgrade to GitHub Pro or make this repository public to enable this feature" | GitHub holds no rule on main |
| The lander's job | Its launchd file is writable. `~/.local/bin`, first on its PATH, is writable. So is `/opt/homebrew/bin`, where its `gh` and `git` are found | What the lander runs is a worker's to choose |
| The engine the lander runs | The plugin cache and the home pointer are writable | The same |
| The evidence | The home's `state`, `state/gate` and `state/commission` are writable | A worker writes its own receipts (R4) |
| The home's `.git`, and the lander's ledger, pause and lock | Writable | The same |

Read from the code and from this session's start-up report:
- **Hold labels are read by name.** The lander holds on `felix:hold`, `felix:founder` and `needs-founder` without asking who set or removed them (`lib/green-tick.sh`; R6).
- **The rule against pushing to main is a local hook.** The start-up report said that 9 tool calls in the last 7 days ended with no verdict from that hook, and each was allowed.
- **Candidate code in P's run executes as this user** (E4; `lib/instrument-run.sh` lists what that leaves open).

## 3. The threat model

**Who acts.**
- **The founder** owns the accounts and the machines. No rule binds him that he cannot change. The design does not wall him. It makes his acts visible, and it asks that his word reach the authority in a way a worker cannot imitate.
- **A worker** is any process that runs as the founder's user on his Mac: a session, its subagents, the lander, and whatever those run. Today it holds his GitHub token, the checkout, the home and the lander's files. A session also has tools that drive the founder's own browser and screen.
- **A candidate** is bytes a worker authored: content the judge reads and code the judge runs.
- **A forge** holds what was pushed to it. What it says can hold a change back, since a label there is a hold. It does not land, authorize or release one, with one exception: until the door exists, its record of who commented is how the founder's yes is read (§5.5).
- **The authority's machine** is trusted. Whoever can log in to it as the authority, or as its administrator, is the authority. The rehearsal puts that one admin password from a worker.
- **Not assumed:** root on the Mac, or the founder's password, fingerprint or second factor, in a worker's hands.

**Intent.** The design does not assume a worker means harm. A worker that errs, follows an instruction planted in what it read, or routes around a blocker finds the same paths as one that does. So each path is treated as one that will be taken.

**What a worker can do today.** Classes, with members found so far as examples. The inventory's residuals R1, R4, R6 and E4 are where this list started.

| # | Class | Examples, not the set | Met by |
|---|---|---|---|
| 1 | Land without the judge | `git push` to main; `gh pr merge`; the refs API; force or delete main (R1) | Rule 1 |
| 2 | Change what judges it | A `gh` or `git` planted earlier on the lander's PATH; the lander's job file; the installed engine; the home pointer; the branch's own workflow, which CI runs (inventory row D3); a repository setting, with the admin token | Rules 1, 3, 10 |
| 3 | Write its own evidence | Gate, review and commission receipts, and kept judgements (R4); a commit status under any name; a workflow on its branch named as the gate's | Rules 3, 6 |
| 4 | Speak as the founder | Remove a hold label (R6); post the comment he would, with his token; clear his deferred decisions; write "authorized by name" where a session reads it | Rule 7. In the interim, rule 2's second half |
| 5 | Act from inside the judgement | Candidate code, run by P's units as this user, reads the token, pushes, writes a receipt, ends or outlives its judge (E4) | Rule 4 |
| 6 | Race the landing | Move the head after the judgement; let main move before the merge (slice 2's open window); reuse an authorization given for another head | Rules 5, 7 |
| 7 | Rewrite history | Move main back to an earlier landed commit; replay a genuine record on another commit | Rules 1, 8 |
| 8 | Make the judged copy differ from the tree | A `.gitattributes` that hides a file from the copy (spike X1); a filesystem that folds case (X7) | Rule 5 |
| 9 | Use the founder | Drive his signed-in browser; read a credential of his at rest; ask him to approve | Rule 7 is aimed at it. Not shown (§8) |
| 10 | Spend | Fill the queue; set holds on every change; keep the judge busy until nothing lands | Rule 9, in part |
| 11 | Reach the authority itself | Its kernel's source; a branch name or title the kernel hands to a shell; its key; a login on its machine | Rules 2, 4, 10. The rehearsal's limit (§8) |
| 12 | Act after main | What deploys from main to this Mac; the public snapshot; a release | Outside (row 49; design §9 step 9) |
| 13 | Deface a published copy | Push to GitHub's main; delete it; with the founder's token, set a rule that shuts the authority out | Rule 11: seen, and put back or reported. Not prevented where the forge has no lock |
| 14 | Feed a reader from a copy | A deploy, an install or a session that takes main from GitHub while the copy is wrong | Rule 11's last part. Open for this Mac's own install (§8) |

## 4. What the authority has to be

Twelve rules. Each names the spike's cases that tried it, in the mode where the authority holds main.

- **Rule 1. Main lives in the authority's own store, and the kernel alone writes it.** The store takes no push and holds no rule that could be edited. Main moves forward, by the kernel's own compare-and-swap. *Tried: cases A1 to A5, S1.*
- **Rule 2. No worker can log in as the authority, and no worker can give the founder's word.** The authority runs under a login no worker has. His word reaches it at the door (rule 7). So a worker that holds the founder's token for the forge can deface the published copy, and can neither move main nor speak as him to the authority. The first draft's first finding was that the identity split at GitHub had to come before any wall. With main in the store that is no longer so. The split is still what the interim rests on, where his yes is read from the forge. *Tried: cases D1, D2, O2, P3. Cases D1i and D2i show the interim falling to his token.*
- **Rule 3. The decision reads five things.** Main, in the store. The candidate's head, as fetched. P, from main. The founder's word, at the door. The kernel. No file from a worker's machine is read, and nothing is decided from a forge's main, its rules, or who it says the founder is. *Tried: cases F4, D1, D2, P3.*
- **Rule 4. Candidate code runs with no power.** P's units and the candidate run under a third login, with no network and one directory to write. They are given no way to write the store or reach a key, and the kernel takes an exit status from them. The kernel itself handles a candidate with git's plumbing and its own few files. *Tried: cases E1 to E6, X4, R6.*
- **Rule 5. What is judged is what lands.** Three parts:
  - **The tree.** T is the merge of the head onto main, made in the authority's store. The copy the units read is T's blobs under T's names, written by object id, on a filesystem that does not fold names, and checked against T before the first unit and after the last. *Tried: cases X1, X7.*
  - **The commit.** The authority makes the commit over T with main as its parent, and lands that object. *Tried: case T2.*
  - **The moment.** The head and the holds are read again just before landing, and main moves only if it is still the base that was judged. *Tried: cases T1, T2.*
- **Rule 6. Evidence is the authority's own run.** A worker's receipts are a pre-flight for the worker. *Tried: cases F1 to F5.*
- **Rule 7. The founder speaks at the door, and each statement names a commit.**
  - **A hold** names a commit, and holds each candidate whose history holds it: the same commit under another branch or pull request, and each commit made on top.
  - **A release, an authorization and an override** each name one exact head.
  - **An authorization or an override is a permission for one landing,** and is spent by it. Saying it again allows one more.
  - **His stop** lands nothing until his go.
  - A session's words authorize nothing, and once the door exists neither does a comment at a forge. Row 49's release "by name" becomes a statement of the same kind.

  *Tried: cases K5, H3, H7, D1 to D5, O1 to O4, R1, R2.*
- **Rule 8. Each landing leaves a record, kept in the store before main moves, and signed.** It binds the result, the commit, the tree, the base, the head, the policy, the kernel and the units. The kernel holds no key: a signer under a login of its own signs each kept record after the fact, so that nothing that decides reads a signature or waits for one (the 10-29 ruling's conditions). The signature is for readers elsewhere. *Tried: cases A5, F1 to F3, R8. The spike's kernel signs in line, which is its shortcut.*
- **Rule 9. One full judgement for each landing, under a ceiling the authority enforces.** When the ceiling is reached, or the judge cannot start, the queue waits. *Not tried.*
- **Rule 10. The kernel changes by the founder's hand, on the authority's machine.** He installs it there from a commit he names. A landed change to the kernel's source takes effect when he installs it, and not before. P, the judge, is main's own. *Tried: cases J1 to J3, for P's judge.*
- **Rule 11. A published copy decides nothing, and is kept true.** Behind or gone, it is sent again. Holding a commit the authority did not land, its foreign tip is kept aside in the store and main is put back; or, by the user's setting, it is left and reported. A branch at the forge that keeps the name main from being made there is kept in the store and removed. A candidate built on a defaced copy carries the defacement and is judged with it. Whatever deploys or installs reads from the authority, or checks the signature. *Tried: cases P1 to P6, R3, R4, R8, and A1 to A5 and F1 to F3 for the copy.*
- **Rule 12. The founder's own changes go through the same door, and he can override.** He tells the authority, in person, to land one exact head unjudged. The record says so, and a reader of the chain is told how many landings rest on his word. *Tried: cases O1 to O4.*

## 5. The shape

### 5.1 One tick

1. **Check the store.** Main must be the tip the authority recorded. If not, stop: another hand was in the store (spike S2).
2. **Check each published copy** against main, and send, put back or report (rule 11). If the founder has said stop, go no further.
3. **Pick a candidate.** A pull request a worker queued, with no hold in effect and, where it changes a founder path, the founder's authorization of this head at the door. The worker's request is a doorbell: it names a pull request and carries no other input. An override of this exact head passes over a refusal, a hold and the judge.
4. **Make T** in the store, with no configuration from anywhere. A conflict is the worker's to resolve and costs no judgement.
5. **Write T out** and check the copy (rule 5).
6. **Judge.** P's instruments, from main, over the copy, confined (rule 4). This is where slices 1 to 3 run.
7. **Record** the decision in the store (rule 8).
8. **Read the head and the holds again.**
9. **Land:** move the store's main to the commit, if main is still the base that was judged.
10. **Publish,** and close the pull request with a pointer to the commit.

A refusal is recorded against the head and is not judged again until the head changes or the worker asks. The spike's kernel judges a refused head again when main moves. The design does not, since each landing would then buy a judgement of each refused head.

### 5.2 The mechanisms, weighed

These answer three questions: where main lives, where the authority runs, and what a forge adds.

| Mechanism | Closes | Leaves open | Needs |
|---|---|---|---|
| **The authority's own store,** which takes no push | Classes 1 and 7 for main, on each plan, on each forge and with none. A foreign commit does not become the base the authority judges against | A login on that machine is the authority. Readers have to take main from it, or check a copy. Something has to run it | A machine, or a login, that workers cannot use |
| **A signed log that whoever uses main checks,** with no store of the authority's own (gittuf, an OpenSSF project in beta, keeps policy with the repository in this way) | No machine keeps the code. Independent of each forge | By itself it stops no push at the store: a foreign commit is on main until a reader refuses it, and each reader has to check. The signature is then on the deciding path | Rejected as the wall. Kept as what a signature adds to a published copy |
| **A forge's own rule on its main:** a GitHub ruleset that lets one identity through | The published copy is locked as well | It is bound to the forge's plan: for a private repository, Pro on a personal account or Team in an organization. An admin can edit it. It says nothing about what was judged | Optional, for each forge |
| **Access at the forge:** agents read-only, proposing from a fork (a free organization), or a second repository (a free personal account, where GitHub has no read-only collaborator) | The published copy is locked on a free plan | It changes where pull requests and CI live. Read from the documentation, not run | Optional |
| **A GitHub App as the connector's identity** | The published main and the posted records carry its name | Its key lives on the authority's machine. With it one can publish, and so deface a copy. One cannot land | The founder creates it (§9, call 1) |
| **This Mac under a second login** | It costs nothing. A judgement in tens of minutes. Off the worker's login | Not off the machine. One admin password from a worker. Asleep when the Mac is. The judge shares its CPU with the founder's sessions | The rehearsal |
| **A small rented server** | Off the machine, at a flat cost | It holds a copy of the code and the signing key. One founder patches and watches it. When it is down, nothing lands | Paid hosting (§9, call 5) |
| **A forge's hosted jobs for judging** (GitHub Actions) | Compute with no machine to keep | Minutes are billed. A job has root, so the kernel confines the units itself. It ties the judge to one forge | Optional. Not used for Felix's own repository |

The first draft weighed classic branch protection, a required check and GitHub's merge queue as the wall. With main in the store none of them is the wall. A merge queue is not offered to a repository a personal account owns, and for a private repository in an organization it needs Enterprise Cloud.

### 5.3 What a connector is

A forge connector reads and writes these, and nothing it reads moves main without the judge or the door.
- **Read:** branches, as candidates. Pull requests, as doorbells: each names a head. Labels, as holds, which anyone may set.
- **Written:** main, as a publication. Each record, posted beside its commit. A pointer on the pull request when its change lands. A foreign tip, kept aside under a name of its own. A branch that blocks the name main is removed, after its tip is kept in the store.
- **Not read as true:** the forge's main, its rules, and who it says the founder is. The interim of §5.5 is the one exception.

A list the forge sends is data. A number or a branch name in it that is not one is passed over before it reaches a file name or a ref name.

A project with no forge needs a place for candidates and a doorbell. Neither is designed here.

### 5.4 Where the authority runs

- **The rehearsal: this Mac.** The authority has a login of its own, and the units a third. It is free, and its limits are in §5.2.
- **Apart: a small rented server.** The store, the signer and the kernel move there once the rehearsal has shown what a judgement costs.
- **For other people's repositories:** outside this document.

**One authority serves one repository,** and is the same thing whoever runs it.

### 5.5 The door

What it has to do:
- **Only the founder can speak there,** and each statement is given in person: by something he knows or is, at the moment he says it.
- **Each statement names a commit:** hold, release, authorize, override (rule 7). Stop and go name none. The first start is a statement too: he names the commit main starts from.
- **What he said is kept** in the store, in order, and each record that leaned on a statement says which.

How it works is not designed. One candidate for the rehearsal: a command run as the authority's login, which this Mac allows after his password or his fingerprint. It adds no new runtime (row 6). It has not been tried, and whether a session that drives his screen can get past it is not known.

**The interim.** Until the door exists, his yes is read from GitHub under his name there. That is worth something once agents act at GitHub under a name of their own and his token is out of their reach (§9, call 2). Spike cases D1i and D2i show it falling when a worker holds his token.

### 5.6 Decisions made here

These are Felix's. Each names what was rejected.

- **Decision 1. The authority lands its own commit, in its own store.** Rejected: asking a forge to merge and checking after, since an unjudged tree would already be on main. The cost: GitHub is expected to show the pull request as closed, not merged, and each reader of "merged" changes (the lander's ledger, `felix land --prs`, the audits that count merged pull requests). Whether GitHub shows it as merged when the published commit holds the head's changes is a question for the throwaway proof (§7).
- **Decision 2. The kernel lives on the authority's machine,** installed by the founder from a commit he names. It runs no file from the repository but P's units, confined, and uses no third-party code. Rejected: a kernel that updates itself from main, and the first draft's kernel under `.github/`.
- **Decision 3. The judge is P's instruments as slices 1 to 3 built them,** run from main's copy. `felix merge` keeps them for the worker's dry run.
- **Decision 4. A label at a forge is a hold that anyone may set.** Holding for the founder, releasing, authorizing and overriding are statements at the door. A hold there covers what is built on the commit it names, and a change made again under a new commit is not held by it. What must wait for the founder because of its content is a founder path in P, which no renaming sheds. What must hold whatever comes is his stop.
- **Decision 5. The record is an in-toto Statement v1 with Felix's predicate, in a DSSE envelope, signed from the first landing** (§9, call 8). The key is made on the authority's machine by the signer's login, and its public half is a founder path in P. The spike signs with an SSH key because this Mac has one. Which scheme Felix signs with follows PR 476's mapping and is open.
- **Decision 6. The authority's state lives in its store:** main, the records, the ledger, and what was said at the door.
- **Decision 7. Failing closed means waiting.** A judge that cannot start, a ceiling reached, or a forge that cannot be read lands nothing and refuses nothing.
- **Decision 8. A defaced copy is put back by default.** The foreign tip is first kept aside, in the store and, where the forge takes it, at the forge. The user may set it to report and leave. Rejected: stopping the authority when a copy is touched, which is what the first draft did when main moved, and which would let any push stop each landing.
- **Decision 9. Each record says what it stands on:** whether the authority ran apart or in rehearsal, and whether the founder's word was read at the door or at a forge. Felix does not report a wall that is not there.

## 6. Budgets

**Measured.** The first four rows are from 200 runs of the `gate` workflow, 2026-10-14 to 11-09, read from the Actions API by this session. Minutes are a run's start to its last update, which stands in for billed minutes.

| What | Value | From |
|---|---|---|
| A passing pull-request gate run since 11-01 | Median 93 min, 90th percentile 110, longest 118 (35 runs) | Those 200 runs |
| The same over the whole window | Median 51, 90th percentile 103 (97 runs) | The same |
| Runs that failed, and runs cancelled | 27 and 22 | The same |
| Minutes on the gate | 8,161 over 26.6 days, about 9,200 in 30 days | The same |
| Landings on main | 66 in 30 days, on 21 of those days; 7 on the busiest | `git log origin/main`, first parent |
| Gate runs for each merged pull request | Median 1, mean 1.88; failed runs, mean 0.32 (93 pull requests) | `audits/2026-11-08-trust-plane-step4-baseline/` |
| P's whole suite on this Mac | 1,350 s for 202 units on the final honest run; 1,395 to 4,044 s across the rounds, by load | Slice 3's measurement |
| A hosted Linux 2-core minute | $0.006. Included each month: $12 on Free, $18 on Pro | GitHub's pricing and plan pages, read 2026-11-09 |
| The mock kernel's own CPU for a landing | 0.57 s at a load average of 4 to 7, with main at the forge (20 landings). Measured again in two back-to-back pairs of 20 landings, as the load average fell from 31 to 16: 1.16 and 1.13 s with main at the forge, 1.10 and 1.11 s with main in the store | `logs/overhead.tsv`, `logs/overhead-pairs.tsv` |

**Cost for each change.** Judgements for each landing: 1.3 if a head is judged once when queued (one pass, plus the failure rates measured), and 1.88 if each push is judged as today.

| Where judging runs | One judgement | A month at 66 landings | Fixed each month |
|---|---|---|---|
| This Mac, in the rehearsal | No money. 23 minutes of the suite when the Mac is quiet, 67 when it is loaded | About 32 hours of judging at 1.3 and the quiet figure, 96 at the loaded one | Nothing |
| A rented server | No more money. Its time is not measured | The same count of judgements | The server's fee, which was not read, and the founder's upkeep |
| GitHub's hosted runners, as a connector | $0.56 at the 93-minute median | About $48 at 1.3, $69 at 1.88 | Nothing on Free |

- **Today** the gate on GitHub costs about 9,200 minutes a month, $55, which is $43 past what Free includes: about $0.83 for each landed change.
- **With the authority judging,** the pull request's gate run on GitHub is no longer what decides. Kept, it is a pre-flight at today's price. Dropped, that spend goes.
- **Holding main cost the mock's kernel no CPU that this measurement can see.** In the two pairs it used 5% and 2% less with main in the store than with main at the forge, and the load was falling while they ran, so the difference is not told apart from that.

These are one month on one repository, with Felix's own suite. A user's cost is their own suite's time on whatever runs their authority.

**Time is a budget too.** One judgement at a time is about 3.4 hours of judging on a day with 7 landings at the quiet figure, and about 10 at the loaded one. On this Mac the scarce thing is CPU the founder's sessions also want: while this was written the load average stood between 16 and 64. How the judge yields to that work is not designed, and the rehearsal measures it.

**What the authority enforces.** A ceiling on judgements for each day, counted from its own ledger. At the ceiling the queue waits and says so. A judge that did not start reads as "wait", and not as a refusal of the change.

## 7. Migration

**The rule for each stage:** the guard that exists keeps running until the next one has been seen to work, and each stage can be undone by the hand that made it.

| Stage | What changes | What guards main | Needs |
|---|---|---|---|
| 0. Today | Nothing | `felix merge`, run by the lander and by sessions on the worker's machine, and local hooks | |
| 1. The trial | Done on the mock: the authority holds main, publishes to a forge with no rule, and workers attack both (the spike report) | The same | |
| 2. Rehearsal, in shadow | A second login on this Mac holds the authority: its store, started from the commit the founder names, the kernel he installs, and a signer. A third login runs the units. It fetches candidates from a place workers push to, judges a sample of pull requests, and lands nothing. Its verdicts and its times are compared with `felix merge`'s and the gate's | The same | The founder makes the logins, which is a system setting and his act |
| 3. His word | Holds, authorizations and overrides are given at the door, in its first form. Or the interim: agents act at GitHub under a name of their own, his token leaves their reach, and his yes is read there | The same | The door, or call 2's identity |
| 4. The authority takes main | One landed change stops the lander merging at GitHub and starts the authority landing in its store. GitHub's main becomes a publication, pushed under the connector's identity. Sessions take their base from the authority | The authority's judgement and its login, at rehearsal strength | The throwaway proof and the App (calls 4 and 1); the founder's merge of that change |
| 5. Apart | The store, the kernel and a signer with a new key move to a small rented server. The published copy and its signed records are the check that nothing changed on the way | The authority, on a machine no worker runs on | The founder's account there and his yes to its fee, with the rehearsal's numbers in hand |
| 6. Retire | `felix merge` keeps its dry run and loses its landing. Receipts stop being read as evidence. The gate run on GitHub goes, or stays as a pre-flight. The inventory is measured again | The authority | |

**The throwaway proof** comes before stage 4. On a public repository that holds nothing of Felix's: does a push under the App's identity publish; does GitHub show a pull request as merged when the published commit is the authority's own; does a rule on that repository lock the copy. `spike/wall-test.sh` was written for the first draft's questions and has to be written again for these. It has never run.

**No window.** Until stage 4's switch, `felix merge` decides, as it does today. At the switch the lander's merge and the authority's landing change hands in one landed change, so main is at no point without a judge it had the day before. After it, a worker's token can still write GitHub's main, as it can today. What it writes there is no longer main.

**The way back.** Stage 4: one change starts the lander again, and GitHub's main, which the authority kept true, is main again. Stage 5: the store moves back to the Mac. Stages 2 and 3: the logins are removed.

**What changes for each part:**

| Part | Today | After |
|---|---|---|
| The land tick (`lib/green-tick.sh`) | Decides and merges, on the worker's machine, with the founder's token | Queues and reports. It may still nurse a pull request (a conflict, a stale branch). Its reading of labels is display |
| `felix merge` | The judgement and the landing | The worker's dry run of the judgement the authority will make (design §4.7). The landing branch of `cmd_merge` goes |
| Gate, review and commission receipts, and kept judgements | Evidence the merge accepts, worker-written (R4) | A worker's pre-flight. The authority's record is the evidence |
| The pull request's gate run on GitHub | The candidate's suite, on the candidate's workflow. It decides | A pre-flight, or gone |
| The gate run on a push to main | Runs again, or is skipped by the `reuse` job | Goes: the tree that lands is the tree that was judged, and a published main would otherwise buy a second judgement for each landing |
| The founder's yes | Words in a session, or a label | A statement at the door, naming the commit |
| Where a session takes its base | GitHub's main | The authority's main, or a published copy it has checked |

## 8. Open

These are the open items seen so far. More will come.
- **The mode this design rests on is one day old.** It had one adversarial review, by a fresh reviewer given the code and not the conclusion.
  - That review found a hold at the door being shed (R1, R2) and a foreign tip being lost (R4).
  - The author found two more while it ran: an authorization and an override could each be used a second time (H7, O4), and H7 was in the first draft's mode as well.
  - One route the review reasoned about and did not run was run afterwards: a planted branch kept the published main from being sent again (P6).
  - Each of these is closed in the mock and is now part of rules 7 and 11. The review's other unrun ideas are listed in the spike report, and none of them is shown to hold or to fail.
  - One review of one day's code is not an audit, and the next route found is a new case.
- **The rehearsal's wall is a login.** One admin password, or a way to run as root on this Mac, is the authority. The spike's worker sandbox stands for that login and is not one. Spike S2 shows what the kernel does when another hand has been in the store: it stops. It cannot prevent it.
- **The door.** Its mechanism is not designed, and the candidate in §5.5 is not tried. Class 9, a session that drives the founder's screen or browser, is what it has to stand against, and nothing here shows that it does.
- **GitHub's half.** What the connector needs from GitHub was not exercised. The throwaway proof measures it.
- **Confinement.** The units need a login of their own with no network: on this Mac that login and the sandbox the spike used, and on a Linux server another user in a namespace. Direction defers "the Docker sandbox" to March. This design takes that line to be about the workers' sessions and confines the units from the start, as the founder's answer to call 8 says.
- **Instruments that run candidate code in their own process** (spike E7). The authority confines that code. It cannot stop it deciding its own unit's result. That is step 3's, and slice 3's canary and partition are aimed at it.
- **A hold can be shed by making the change again.** A label follows the pull request and its branch, so the same commit under another branch name sheds it (spike H6). A hold at the door follows the commit, so that route is closed (R1, R2), and a change made again under a new commit sheds it still. Decision 4 is the answer this design gives: a founder path for content, and his stop for whatever comes.
- **A reader with no memory.** A copy moved back to an earlier genuine main checks as ok until the authority's next tick sends it again (spike R7, and A5 before it). A signed and dated statement of the tip would let such a reader see that a copy is stale. It is not designed.
- **Who reads a copy.** What installs the engine on this Mac takes it from main by files a worker can write, and takes main from GitHub. Rule 11 says it should read from the authority or check the signature. That change is not designed.
- **The store is the one true copy.** It needs a backup that workers cannot write. A published copy whose signed chain checks is a way to rebuild it, which is one reason the records are signed.
- **The signing key.** Its rotation, and what a reader does with records made under an old key, are not designed.
- **Review evidence.** A review is not something the authority can run again from P. Who reviews, under which identity, once a worker's receipt is a pre-flight, is design §4.5's question.
- **Felix's suite under the authority.** Its false blocks, its time, and its units that test where they run (slice 3's A17) are measured in the rehearsal, not here.
- **The engine's own copy.** `lib/instrument-run.sh` writes the tree its units run in with a checkout that obeys the tree's own `.gitattributes`, on a filesystem that folds case. A follow-up session is measuring it. It belongs to step 3.
- **Supply chain.** Git itself reading a candidate's objects into the store, the machine's system, and the accounts' own security are trusted and not examined.
- **A tick that dies between its record and its landing, and two authorities at once.** Not designed and not tried.

## 9. The founder's calls, as answered

Asked and answered on 2026-11-09 and 11-10. Where he wrote an answer himself it is quoted as written. A yes to a call is not a yes to each act under it: making a login, an account, a repository, an App, a token or a key is still his to do, or to tell a session to do by name.

| # | The call | His answer | What it starts |
|---|---|---|---|
| 1 | Whose name the authority carries at GitHub | "Yours, after the proof": an App under his personal account once the throwaway proof passes, made again at the organization | The connector's identity, for stage 4. It no longer guards main |
| 2 | Whether an agent stops being him at GitHub | "Agents get their own name" | The interim of stage 3, and a published copy where an agent's push carries the agent's name |
| 3 | What walls main | First: "i don't mind paying personal plan...but will this be a limitation for our future users? If so we cannot accept this design". Then, of a wall that follows the user's plan: "the most practical....but i do not rly like this". Then he chose "Felix holds main" | This revision |
| 4 | The throwaway proof at GitHub | "Yes, a public throwaway" | The proof before stage 4, for the connector |
| 5 | Where the authority runs first | "This Mac, then a server" | Stages 2 and 5. The server's account and fee wait for the rehearsal's numbers |
| 6 | Where his yes counts | "At Felix's own door" | Rule 7 and §5.5. Until it exists, the interim |
| 7 | His own changes, and a judge that is wrong | "Same door, with an override" | Rule 12 |
| 8 | What is built before March | "Build and sign now" | Rule 8 and decision 5. It brings signing forward from direction's "Not before March", and direction needs a row that says so |

**Calls the first draft listed that this revision dissolves:** the GitHub plan, a monthly ceiling on runner minutes, and GitHub's secret store as the place for the authority's key.

**Still open with him:** the daily ceiling on judgements, once the rehearsal has measured one; the server; and who runs an authority for other people's repositories.

Nothing in this design needs felix-home's visibility to change. It stays private.

## 10. What this changes

**In the 11-07 design:**
- **§5, "hands the final merge to GitHub's merge queue once felix-home is in an org".** The authority lands in its own store, on each plan. A merge queue for a private repository needs Enterprise Cloud.
- **§4.8, "Workers hold tokens that cannot push to main".** With main in the store, a worker's token at a forge is not what guards main.
- **§4.8, "It can also read branch protection".** On felix-home's plan that read answers 403, and the design no longer needs it.
- **§11, "Enumerating every input the authority reads … can miss something".** The copy the units read was such an input, found by the review on the day this was written (spike X1).

**In this document's first draft** (commit d9373e7d):
- **Rule 1** had the provider enforce who moves main. The store does.
- **Rule 2** put the identity split at GitHub before the wall. It now comes before the interim alone.
- **Rule 7** had the founder speak through the provider. He speaks at the door.
- **Rule 8's signature** was "a separate, later step". It is from the first landing, by a signer that is not the kernel.
- **Decisions 2 and 6** kept the kernel under `.github/` and the authority's state in a branch at the provider. Both are on the authority's machine.
- **The three compositions** (one repository with a ruleset, two repositories, a host) are now ways to lock a published copy, or where the authority runs.
- **The budget** priced a judgement in GitHub's minutes. Judging runs on the authority's machine.
- **A push around the authority** stopped the first draft's authority. It now changes a copy, and landing goes on.
