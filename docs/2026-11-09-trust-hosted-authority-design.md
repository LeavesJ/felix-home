# The hosted trust authority: who moves main, and on whose word

2026-11-09. A design for the hosted authority that `docs/2026-11-07-trust-plane-design.md` §4.8 and direction row 43 call for. It is the step that design names "the queue owns landing" (§9, step 4). The measurement beside it is `docs/2026-11-09-trust-hosted-authority-spike.md`.

**Scope.** A proposal. It decides what the authority is and how it works, which is Felix's to decide. It lists the identity and account calls and does not answer them (§9). Nothing is built at GitHub, no setting on any repository or account was changed, no key was touched, and nothing in `engine/` changes. Statements about GitHub are read from its documentation on 2026-11-09 unless a row says they were read from the API. None of them was exercised.

**Outside this document, and where each belongs:**
- review and commission evidence once worker receipts stop counting (design §4.4, §4.5);
- release and deployment transitions, beyond what row 49 already says (design §4.6, and §9 step 9);
- the suites of governed products, each with a partition of its own (step 3's open list);
- a sandbox for the worker's own sessions (direction, "Not before March");
- batching and reuse at the authority (design §9, step 8);
- the language (row 6).

**This is an open set.** The threats, mechanisms and cases below are the ones found so far, by one session on one day. A count says what it counted. A route found later is a new row (design §11).

## 1. Answer

- **Today there is no wall, and a rule made while workers hold the founder's token would not be one.** The token a worker uses is the founder's admin token, which could edit the rule. GitHub offers felix-home no rule on main on its plan. The lander's job file, the first directory on its PATH, the engine it runs and the receipts it accepts are each writable by a worker (§2).
- **The authority is three things.** An identity at the provider that alone moves main. A judgement that reads the candidate and the provider's own record, reads no file from a worker's machine, and runs repository code with no power. A record from which main can be checked link by link.
- **The identity split comes first.** No rule can tell the founder from a worker while they share a token, and a rule an admin token can edit is not a wall.
- **The authority lands the commit it judged.** It does not ask GitHub to merge. That closes the window slice 2 left open (inventory row G1).
- **One full judgement for each landing, in place of the pull request's CI run.** On GitHub's hosted runners that is about $0.73 for each landed change at the rates measured here (§6).
- **Migration is five stages.** The guard that exists today keeps running until the authority has landed changes itself. The wall is one setting, and it adds refusals (§7).
- **The spike.** On a local mock with the wall on, no worker's request moved main except through the authority, and no forged or replayed record was accepted. A review of the mock found one break, and fixing it found a second. Both are closed in the mock and both are now part of rule 5 here. Two of the battery's cases still land what they should not (§8).
- **Nine calls are the founder's** (§9): two about identity, two about account settings, one about money, two about keys, and two about his own acts.

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
- **The founder** owns the account. He is root at the provider: no rule binds him that he cannot change. The design does not wall him. It makes his acts visible.
- **A worker** is any process that runs as the founder's user on his Mac: a session, its subagents, the lander, and whatever those run. Today it holds the token, the checkout, the home and the lander's files. A session also has tools that drive the founder's own browser. Whether that browser is signed in at GitHub was not looked at.
- **A candidate** is bytes a worker authored: content the judge reads and code the judge runs.
- **The provider** is trusted to enforce its rules and to say who did what. The spike assumes this and does not show it.
- **Not assumed:** root on the Mac, the founder's password or second factor, or a provider that lies.

**Intent.** The design does not assume a worker means harm. A worker that errs, follows an instruction planted in what it read, or routes around a blocker finds the same paths as one that does. So each path is treated as one that will be taken.

**What a worker can do today.** Classes, with members found so far as examples. The inventory's residuals R1, R4, R6 and E4 are where this list started.

| # | Class | Examples, not the set | Met by |
|---|---|---|---|
| 1 | Land without the judge | `git push` to main; `gh pr merge`; the refs API; force or delete main (R1) | Rules 1, 2 |
| 2 | Change what judges it | A `gh` or `git` planted earlier on the lander's PATH; the lander's job file; the installed engine; the home pointer; the branch's own workflow, which CI runs (inventory row D3); a repository setting, with the admin token | Rules 2, 3, 10 |
| 3 | Write its own evidence | Gate, review and commission receipts, and kept judgements (R4); a commit status under any name; a workflow on its branch named as the gate's | Rules 3, 6 |
| 4 | Speak as the founder | Remove a hold label (R6); post the comment he would; clear his deferred decisions; write "authorized by name" where a session reads it | Rules 2, 7 |
| 5 | Act from inside the judgement | Candidate code, run by P's units as this user, reads the token, pushes, writes a receipt, ends or outlives its judge (E4) | Rule 4 |
| 6 | Race the landing | Move the head after the judgement; let main move before GitHub's squash (slice 2's open window); reuse an authorization given for another head | Rules 5, 7 |
| 7 | Rewrite history | Move main back to an earlier landed commit; replay a genuine record on another commit | Rules 1, 8 |
| 8 | Make the judged copy differ from the tree | A `.gitattributes` that hides a file from the copy (spike X1); a filesystem that folds case (X7) | Rule 5 |
| 9 | Use the founder | Drive his signed-in browser; read a credential of his at rest; ask him to approve | Not met (§8) |
| 10 | Spend | Fill the queue; burn the minutes budget until nothing lands | Rule 9, in part |
| 11 | Reach the authority itself | Its kernel's source; the actions and image its jobs use; its key; its host | Rules 4, 10; calls 4 and 5 |
| 12 | Act after main | What deploys from main to this Mac; the public snapshot; a release | Outside (row 49; design §9 step 9) |

## 4. What the authority has to be

Ten rules. Each names the spike's cases that tried it.

- **Rule 1. One identity moves main, and the provider enforces it.** It is not the founder's and not a worker's. Main moves forward, for every identity, the authority included. *Tried: cases A1 to A5.*
- **Rule 2. No worker holds the founder's identity or the authority's.** The founder's token leaves the worker's reach, and workers act under an identity of their own, so the provider's record of who did what tells them apart. This comes before the wall. *Tried: cases A4, H1 to H5.*
- **Rule 3. The decision reads five things.** Main, as the provider holds it. The pull request's head, as the provider holds it. P, from main. The provider's events, with the actor of each. The kernel. No file from a worker's machine is read: a worker's receipts become a pre-flight for the worker. *Tried: case F4.*
- **Rule 4. Nothing that reads candidate bytes holds the identity.** The part with the credential runs git's plumbing and its own few files. P's units and the candidate run with no credential, no network and one directory to write, as another user, and the kernel takes an exit status from them. *Tried: cases E1 to E6, X4.*
- **Rule 5. What is judged is what lands.** Three parts:
  - **The tree.** T is the merge of the head onto main, made in the authority's own clone. The copy the units read is T's blobs under T's names, written by object id, on a filesystem that does not fold names, and checked against T before the first unit and after the last. *Tried: cases X1, X7.*
  - **The commit.** The authority makes the commit over T with main as its parent, and lands that object. *Tried: case T2.*
  - **The moment.** The head and the holds are read again just before landing, and the push is a fast-forward, so it fails when main has moved. *Tried: cases T1, T2.*
- **Rule 6. Evidence is the authority's own run, or its own read of the provider.** *Tried: cases F1 to F5.*
- **Rule 7. The founder speaks through the provider, about an exact head.** A hold stands until his identity clears it. An authorization names the head's commit id. A session's words authorize nothing. Row 49's release "by name" becomes a statement of the same kind. *Tried: cases H1 to H5, K5.*
- **Rule 8. Each landing leaves a record, posted before main moves.** It binds the result, the commit, the tree, the base, the head, the policy, the kernel and the units. The authority remembers its last tip, so a main moved back, or moved by another hand, stops it. A signature over the record is a separate, later step that nothing deciding reads (the 10-29 ruling). The spike signs each record, to show what a signature adds: with the wall off, it is what tells a landed commit from a pushed one. *Tried: cases A5, B1, and F1 to F3 with the wall off.*
- **Rule 9. One full judgement for each landing, under a ceiling the authority enforces.** When the ceiling is reached, or a job cannot start, the queue waits. *Not tried.*
- **Rule 10. The kernel changes by the founder's hand, and a change to it takes effect after it lands.** The kernel that judges a change is main's. *Tried: cases J1 to J3, for P's judge.*

## 5. The shape

### 5.1 One tick

The authority is the land tick, moved off the worker's machine, given its own identity, and fed from the provider.

1. **Check main.** It must be the tip the authority last landed. If not, pause: the founder moved it, or the wall failed.
2. **Pick a candidate.** An open pull request a worker queued, with no hold in effect and, where it changes a founder path, the founder's authorization of this head. The worker's request is a doorbell: it names a pull request and carries no other input.
3. **Make T** in the authority's clone, with no configuration from anywhere. A conflict is the worker's to resolve and costs no judgement.
4. **Write T out** and check the copy (rule 5).
5. **Judge.** P's instruments, from main, over the copy, confined (rule 4). This is where slices 1 to 3 run. `bind.sh`'s class is git in the worker's checkout answering with what the provider does not hold. The members found so far each need a write to that checkout or its environment, which a clone the authority made does not offer.
6. **Record** the decision on the commit (rule 8).
7. **Read the head and the holds again.**
8. **Land** the commit by fast-forward, then close the pull request with a pointer to it.

A refusal is recorded against the head and is not judged again until the head changes or the worker asks. The spike's kernel judges a refused head again when main moves. The design does not, since each landing would then buy a judgement of each refused head.

### 5.2 The mechanisms, weighed

These answer three different questions: who may move main, who the authority is, and where it runs. They are parts of one answer more often than they are alternatives.

| Mechanism | Closes | Leaves open | Needs |
|---|---|---|---|
| **A ruleset on main:** updates restricted to the authority's App; force pushes and deletion blocked for every actor | Classes 1 and 7, for each token but the App's | An admin can edit it, so rule 2 comes first. It says nothing about what was judged. Rulesets cover branches and tags, so the authority's own state has to live in a branch | A paid plan for a private repository: Pro on a personal account, Team in an organization. An App as the bypass actor on a personal repository was not exercised |
| **Classic branch protection** | Direct pushes, by requiring a pull request and a check | It cannot name who may push on a personal repository. Anyone with write access merges once the check is green | The same plan |
| **A required check from the authority,** its source pinned to the App | A check forged under the same name | GitHub merges, and the check is on the head: main can move after it. Requiring branches to be up to date closes that by judging each open change again after each landing. The worker presses merge, so a hold has to become a failing check in time | The same plan |
| **A merge queue** | The same window, natively: GitHub builds the combined commit, asks for the check on it, and fast-forwards. Batching comes with it | Not offered to a repository a personal account owns, and for a private repository in an organization it needs Enterprise Cloud | Out of reach for felix-home as it is |
| **Two repositories:** workers have no access to the one that holds main, and push candidates to the other | Class 1, with no ruleset and no paid plan | Each reader that assumes one repository changes: pull requests, CI, the lander, the desktop app's pull-request tools, cloud sessions. It is redone at the move to the organization | GitHub Free |
| **A GitHub App as the authority** | Attribution (rules 6 and 8): its events and checks carry its name, and it can be the one actor a ruleset lets through | Its private key has to live somewhere (call 5) | The founder creates it |
| **A small host** runs the tick with the App's key | Off the worker's machine; a flat cost; no minutes | The key sits beside the code being judged unless judging runs elsewhere. One founder patches and watches it. When it is down, nothing lands | Paid hosting |
| **Actions jobs pinned to main's workflow:** a judging job with no secret, then a landing job with the credential | A fresh machine for each job, so the judged code and the credential never share one. No host to keep | The workflow's own token is every workflow's, so it cannot be the identity: an App is still needed. The credential has to be reachable from main's workflow alone: an environment restricted to main (a paid plan on a private repository), or a key service that checks the job's token for main's workflow (the 10-29 ruling's pin). A repository secret is readable by a workflow on any branch. A job has root, so the kernel confines the units itself. Minutes are billed | A paid plan, or a cloud key service |
| **This Mac under a second user** | Costs nothing; a judgement in tens of minutes | Not off the machine. One admin password away from a worker. Asleep when the Mac is | Rehearsal and shadow |

### 5.3 Three compositions

Each of these meets rules 1 to 10. The kernel is the same in each. Calls 1 to 5 choose among them.

- **One repository.** A ruleset on felix-home's main; the authority's App; Actions for judging and landing, with the credential reachable from main's workflow alone. It changes least about how work flows. It needs a paid plan for the ruleset.
- **Two repositories.** The same App and jobs, with the wall made by access. It runs on GitHub Free, and changes most about how work flows.
- **A host.** The App's tick on a rented machine, with either wall. Judging runs on the host or in Actions jobs that hold no credential.

### 5.4 Decisions made here

These are Felix's. Each names what was rejected.

- **Decision 1. The authority lands its own commit.** Rejected: calling GitHub's merge and checking the result after, since the check would run with an unjudged tree already on main. The cost: GitHub shows the pull request as closed, not merged, and each reader of "merged" changes (the lander's ledger, `felix land --prs`, the audits that count merged pull requests). Whether a pull request reads as merged when the authority first moves its branch to the landed commit is a question for the sandbox (§7, stage 1).
- **Decision 2. The landing kernel lives under `.github/`,** runs no file from elsewhere in the repository, and uses no third-party action. `.github/workflows` is already a channel that waits for the founder (`projects/felix/risk.tsv`), the kernel's files beside it become founder paths in P, and the 10-29 review asked the same of the signing job. Rejected for now: a kernel repository of its own, which is worth its cost when a second repository is governed.
- **Decision 3. The judge is P's instruments as slices 1 to 3 built them,** run from main's copy. `felix merge` keeps them for the worker's dry run.
- **Decision 4. Holds and authorizations are provider events, read by actor.** A label hold follows the pull request and its branch. What must wait for the founder because of its content is a founder path in P, which no renaming sheds (§8, case H6).
- **Decision 5. The record is an in-toto Statement v1 with Felix's predicate,** posted under the authority's identity as a check on the commit. It is unsigned until signing is decided. It takes the shape PR 476's mapping proposes, so a signature added later changes no reader.
- **Decision 6. The authority's state lives at the provider,** in a branch that it alone moves: its tip and its ledger.
- **Decision 7. Failing closed means waiting.** A job that cannot start, a ceiling reached, or a provider that cannot be read lands nothing and refuses nothing.

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

**Cost for each change.** A judgement is taken to be one gate-sized run of 93 minutes. That is an assumption until the shadow stage measures P's suite on a runner. Judgements for each landing: 1.3 if a head is judged once when queued (one pass, plus the failure rates measured: 0.32 failed runs a pull request in one count, 27 failures to 97 passes in the other), and 1.88 if each push is judged as today.

| Where judging runs | One judgement | One landed change, at 1.3 and at 1.88 | Fixed each month |
|---|---|---|---|
| GitHub's hosted runners | $0.56 | $0.73 and $1.05 | Nothing on Free. Where the wall needs a paid plan, its fee: Pro was $4 a month when last read, and was not read again today |
| A rented host | Nothing more | Nothing more | The host's fee, not read today, and the founder's upkeep |
| This Mac under a second user | Nothing | Nothing | Nothing. Not hosted |
| The landing job itself, wherever judging runs | One billed minute, $0.006 | About a cent | |

**For each month, at 66 landings.** These are projections from one month on one repository, not promises.
- **Today:** about 9,200 minutes, $55, which is $43 past what Free includes.
- **The authority in place of the pull request's CI, on hosted runners:** about 8,000 minutes and $48 at 1.3, which is $36 past Free's included amount. At 1.88 it is about 11,500 minutes and $69.
- **The authority on top of today's CI:** the two added, about 17,200 minutes and $103. The design does not do this past stage 2's sample: the judging job takes the place of the pull request's gate run (§7).

**Time is a budget too.** One 93-minute judgement at a time is about 11 hours of judging on a day with 7 landings, before any failure. A second judging job at once, on the tree the first would leave, buys time with minutes when the first fails. That belongs with batching (design §9, step 8) and is not designed here.

**What the authority enforces.** A ceiling on judgements for each day and each month, counted from its own ledger. At the ceiling the queue waits and says so. The account's own spending limit stays the backstop. On 09-25 a $0 cap failed each job at its start, and from 10-25 to 10-30 each run ended in a start-up failure whose cause was not confirmed. The authority reads a job that did not start as "wait", never as a refusal of the change.

## 7. Migration

**The rule for each stage:** the guard that exists keeps running until the next one has been seen to work, and each stage can be undone by the hand that made it.

| Stage | What changes | What guards main | Needs |
|---|---|---|---|
| 0. Today | Nothing | `felix merge`, run by the lander and by sessions on the worker's machine, and local hooks | |
| 1. The sandbox proof | On a throwaway repository: the App, a worker identity, a ruleset, and one run of `spike/wall-test.sh`. felix-home is not touched | The same | Call 6 |
| 2. Shadow, then swap | A judging job on felix-home, started from main's workflow, with a read-only token and no secret. It judges P over T. First it runs beside the gate run on a sample of pull requests and decides nothing: its verdicts are compared with `felix merge`'s. Then it takes the gate run's place, and the lander reads its result where it read CI's | The same. After the swap, CI's judge is P's and not the candidate's (inventory row D3) | The founder's merge of a workflow change, as today |
| 3. The split | Workers act under their own identity. The founder's token leaves their reach. His holds and authorizations move to the provider (rule 7) | The same. The judging job now tells his label from a worker's (R6) | Calls 1, 2, 8 |
| 4. The authority lands, then the wall | One change stops the lander merging and starts the landing job. After its first landings each carry a record and the verifier agrees, the founder turns the rule on | The authority's judgement from that change on; the provider's rule from the founder's switch on | Calls 3, 4, 5, 9 |
| 5. Retire | `felix merge` keeps its dry run and loses its landing. Receipts stop being read as evidence. The inventory is measured again, against the real provider | The provider's rule and the authority | |

**No window.** Until stage 4's switch, a worker's token can still move main, as it can today. The stages before it leave `felix merge` deciding, and stage 2 swaps the candidate's own CI run for P's once the two have been compared. At stage 4 the lander's merge and the authority's landing change hands in one landed change, so main is at no point without a judge it had the day before. Two landers at once would stop the authority at its first tick (step 1 of §5.1), which is why they change hands and do not overlap.

**The way back.** Stage 4: the founder turns the rule off, and one change starts the lander again. Stage 3: he puts his token back. Stage 2: the workflow change is reverted.

**What changes for each part:**

| Part | Today | After |
|---|---|---|
| The land tick (`lib/green-tick.sh`) | Decides and merges, on the worker's machine, with the founder's token | Queues and reports. It may still nurse a pull request (a conflict, a stale branch). Its reading of labels is display |
| `felix merge` | The judgement and the landing | The worker's dry run of the judgement the authority will make (design §4.7). The landing branch of `cmd_merge` goes |
| Gate, review and commission receipts, and kept judgements | Evidence the merge accepts, worker-written (R4) | A worker's pre-flight. The authority's record is the evidence |
| The pull request's CI gate | The candidate's suite, on the candidate's workflow | The authority's judging job: P's suite, on main's workflow |
| The founder's yes | Words in a session, or a label | A statement under his identity at the provider, naming the head (call 8) |

## 8. Open

These are the open items seen so far. More will come.
- **GitHub's half of the claim.** Whether GitHub refuses what the mock's provider refuses was not exercised. Stage 1 measures it.
- **Confinement on a Linux runner.** A job there has root. The kernel has to drop to another user in a namespace with no network before it runs a unit. The spike showed the idea with macOS's sandbox, on macOS. Direction defers "the Docker sandbox" to March; whether that line covers the authority's own confinement is part of call 7.
- **Instruments that run candidate code in their own process** (spike E7). The authority confines that code. It cannot stop it deciding its own unit's result. That is step 3's, and slice 3's canary and partition are aimed at it.
- **A hold by label can be shed by sending the same commit up under another branch name** (spike H6). Following the commit would stop that and would not stop an amended commit. Decision 4 is the answer this design gives: what must wait by content is a founder path.
- **The founder's own session** (class 9). An agent that drives a browser signed in as the founder is the founder at GitHub. Call 2 names it. No rule in this design closes it.
- **Re-rooting.** When the founder lands by hand, the authority stops (spike B1). The act by which he tells it to go on from the new tip is not designed (call 9).
- **Review evidence.** A review is not something the authority can run again from P. Who reviews, under which identity, once a worker's receipt is a pre-flight, is design §4.5's question.
- **Deployment.** The authority guards main. The copy of the engine this Mac runs is installed from main by files a worker can write.
- **Felix's suite under the authority.** Its false blocks on a runner, its time there, and its units that test where they run (slice 3's A17) are measured in shadow, not here.
- **The engine's own copy.** `lib/instrument-run.sh` writes the tree its units run in with a checkout that obeys the tree's own `.gitattributes`, on a filesystem that folds case. The spike report gives the three-line reproduction. Whether a guard can be passed that way is not measured. It is a follow-up for step 3.
- **Supply chain.** The runner image, git itself reading a candidate's objects, and the account's own security are trusted and not examined.
- **Two authorities, or a tick that dies between its record and its landing.** Not designed and not tried.

## 9. The founder's calls

Listed, not answered. Each says what waits on it. Where a call needs something the session was told not to do without his explicit yes, the row says so.

| # | The call | The choices, as outcomes | Waits on it |
|---|---|---|---|
| 1 | **Whose name the authority carries.** It needs an identity of its own at GitHub | (a) An App under his account now, made again at the organization. (b) An App when the Daimonion organization exists (row 43). (c) An App for the sandbox alone, for now. (d) None: the authority stays advisory | Stages 1, 3, 4. *Creating an App needs his yes* |
| 2 | **Whether a worker stops being him** | (a) Workers get an identity of their own, his admin token leaves the sessions' reach, and sessions stop driving a browser signed in as him at GitHub. (b) Workers get a narrower token of his: main can be walled, and his label and a worker's still read alike. (c) As today: no wall is real. (d) Workers move off this Mac with their own identity | Stage 3. *Creating tokens or an account needs his yes* |
| 3 | **What walls main** | (a) A rule on felix-home that the authority alone passes, which needs a paid plan for a private repository. (b) Two repositories on the free plan, and a larger change to how work flows. (c) Wait for the organization and its plan. (d) No wall: the record detects and nothing prevents | Stage 4. *A ruleset, and a plan, are his settings* |
| 4 | **Where judging runs, and what it may cost** | (a) GitHub's runners under a monthly ceiling he names. (b) A rented host at a flat fee, his to keep running. (c) This Mac under a second user: free, and not off the machine. (d) The Mac for shadow, and the choice after it is measured | Stages 2, 4. *Paid hosting is his* |
| 5 | **Where the authority's key lives** | (a) GitHub's secret store, reachable from main's workflow alone, on the paid plan. (b) A cloud key service that signs for main's workflow and never releases the key. (c) The rented host's disk. (d) This Mac's second user, for rehearsal | Stage 4. *Keys are his* |
| 6 | **The sandbox proof** | (a) Yes to one throwaway repository, one App, two tokens and one ruleset there, and one run of the wall test. (b) The same on a repository he names. (c) Skip it and learn in shadow. (d) Not now | Stage 1. *A repository, an App, tokens and a ruleset each need his yes* |
| 7 | **What waits for March.** Roadmap §4 says "never a key on the enforcing path", and direction defers DSSE receipts and "the Docker sandbox". The authority's identity is a credential that moves main, and rule 4 confines units | (a) Records are posted under the authority's identity, unsigned, until March, and units are confined from the start. (b) Records are signed now with a second key under the 10-29 conditions, and nothing deciding reads the signature. (c) Nothing is recorded but the ledger until March. (d) Those lines cover the authority's credential or its confinement, and the authority waits for March | Decision 5; rules 4 and 8 |
| 8 | **Where his yes is given** | (a) At GitHub, under his identity, naming the head: a comment, or a label he alone clears. (b) Through a channel of Felix's own that workers cannot write, not yet designed. (c) In sessions, as today: a worker can then speak as him. (d) At GitHub for releases and policy, in sessions for the rest | Stage 3; row 49 |
| 9 | **Landing by his own hand** | (a) He switches the rule off, pushes, and tells the authority to go on. (b) The rule names him as well: then his token is a way through wherever it sits. (c) Main moves through the authority alone, him included. (d) Decide after the first pause in shadow | Stage 4 |

Nothing in this design needs felix-home's visibility to change. It stays private.

## 10. What this changes in the 11-07 design

- **§5, "hands the final merge to GitHub's merge queue once felix-home is in an org".** For a private repository a merge queue needs Enterprise Cloud. The authority's own fast-forward landing does that job on each plan.
- **§4.8, "Workers hold tokens that cannot push to main".** That presupposes workers hold tokens of their own. Today's is the founder's (§2), so the split (rule 2) is a step of its own, before the wall.
- **§4.8, "It can also read branch protection".** On felix-home's plan that read answers 403.
- **§11, "Enumerating every input the authority reads … can miss something".** The copy the units read was such an input, found by the review on the day this was written (spike X1).
