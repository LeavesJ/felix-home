# Felix receipts as in-toto statements: the receipt format the trust authority's signing builds on

**Status.** The receipt format that the hosted trust authority's signing builds
on, and a document only. Nothing in it is built, keyed or signed. At main
0.49.340 the engine and `.github/` hold no signing code (no `cosign`,
`in-toto` or `DSSE` in either), and the authority that would sign is a design
and a local mock (#504). On 2026-11-10 the founder decided this pull request
("Land it as signing's base"), and his answer 8 on the hosted trust authority
design (`docs/2026-11-09-trust-hosted-authority-design.md`, pull request #504,
merged on 2026-11-13 as `bc237f7e`) was "Build and sign now". That brought
signing forward from "Not before March". Its decision 5 names this mapping:
the record is an in-toto Statement v1 with Felix's predicate in a DSSE
envelope, and "which scheme Felix signs with follows PR 476's mapping and is
open". Direction §5 still lists "DSSE receipts" under "Not before March", and
the design asks for a row that says otherwise; this pull request does not edit
`docs/direction.md`.

**What carries over, and what does not.** The format (§1, §2) and the
landscape (§6) do not depend on where the signer runs. §3, the felix-home
rows of §4 and the commands of §5 describe signing as a GitHub Actions job
(a cloud KMS key reached by CI, or keyless Sigstore), which was the March
proposal. The authority's design has a signer under a login of its own on the
authority's machine, and no GitHub Actions job that signs. The design keeps
main in the authority's own store and treats a forge as a connector, because
the founder would not accept a design that depends on a GitHub plan. So those
parts are the record
of the CI path and of J's ruling on it. They are not the signing design, and
where the authority's signer differs they give way to the design in #504.

Read at main `78f0268` (0.49.308, 2026-10-29). Every engine path and every
line number below is at that commit (`git show 78f0268:<path>`). The branch
was brought up to main at 0.49.340 on 2026-11-13, and the files this document
cites have moved since: `receipt.sh`, `verify.sh`, `escape.sh`, `bootstrap.sh`,
`green-tick.sh` and `engine/harness/felix` changed, so line numbers there
have drifted, and §1.3 says what changed in the gate receipt document.
`epoch.sh`, `commission.sh`, `automerge.sh` and `gate.yml` did not change in
that span. Outside sources were read on 2026-10-29 and are listed in §9.

## 0. The short version

- Felix already writes two receipts: the gate receipt and the commission
  receipt. Both already go stale when something they depend on moves. This
  document maps them into an in-toto Statement v1, in a DSSE envelope, with a
  Felix predicate. It invents no new proof record.
- Signed, commit-bound receipts are not Felix's own. What is Felix's own is a
  receipt that names what its verdict rests on, so a reader can tell when it
  has gone stale. The predicate is built around that.
- This document proposed signing in CI, in its own workflow, after CI has
  judged the head: keyless for a public repository, or a cloud KMS key
  reached only by CI. That was the March proposal. The authority's design
  (#504, rule 8) signs each kept record with a signer that is not the kernel,
  after the fact, so that by its design nothing that decides reads or waits
  on a signature. The
  enforcing path is defined by what a decision needs, and no deciding step
  (the hooks, the gate, CI's judgment, `felix merge`, the land tick) needs a
  key. J ruled on 10-29 that a CI only KMS key is off that path on three
  conditions; §3.2 gives each and how it was to be checked on the CI path.
- felix-home is private on GitHub Free. Keyless signing on the public Sigstore
  instance would publish its identity, so felix-home gets no signed receipts
  on public infrastructure. On the CI path, a CI only KMS key could sign them
  on its current plan, once the three conditions of §3.2 hold. The main only
  pin lives in the token's own claims and the signing job names no
  environment (J's ruling of 10-31). If Free cannot set the token template
  on a private repository, the pin moves into the KMS trust policy's own
  claim conditions; if neither works, the key is on the path and felix-home
  stays unsigned. Under #504 the signer is not in CI, and none of that
  applies to it. Public repositories, starting with the Phase 4 replay
  repository, can sign keyless.
- A signed receipt proves who signed which statement about which commit. It
  does not prove the gate was the right gate. Until the judge pin (roadmap
  step 15) exists, the predicate says so in a field of its own.

## 1. What Felix writes today

Three records. The first two are the receipts this document maps. The third
is the JSON document Felix already prints for a peer; the predicate keeps its
rule and its limits, and replaces nothing.

### 1.1 The gate receipt

Written by `felix_verify_record` (`engine/harness/lib/verify.sh:526`), called
from `cmd_gate` (`engine/harness/felix:1128`) on every gate run, green or red.
One line of eight tab separated fields, overwritten each run, at
`$FELIX_HOME_DIR/state/gate/<hash of the checkout path>`
(`_felix_receipt_path`, `verify.sh:481`).

| # | Field | Written from | What it is |
|---|---|---|---|
| 1 | tree id | `felix_tree_id` (`verify.sh:354`) | `git hash-object --stdin` (`verify.sh:33`) over HEAD's commit id, the diff of the working tree against HEAD, and the size and mtime of untracked files (`_felix_tree_id_on`, `verify.sh:377`). Taken before the gate runs, so a gate that rewrites files cannot stamp a tree it never saw (`felix:754`). It is not a git tree id. |
| 2 | result | gate exit status | `green` or `red`. |
| 3 | when | `_felix_now` | UTC, to the second. |
| 4 | gate | `project.json` `gate` | The command the project declares as its gate (`felix:742`). A command string, not a pinned identity. |
| 5 | skipped | the gate's own report | Checks the gate printed as `skipped`, comma joined, or `-`. |
| 6 | reported | the gate's own report | Every check it printed, as `name:verdict` pairs, or `-`. `obligations` and `commission` appear here. |
| 7 | epoch | `felix_verify_epoch_fields` (`verify.sh:639`) | The decision epoch: one hash over the four components below. |
| 8 | components | the same | `subject_identity,topology_version,policy_version,release_target`, comma joined (`engine/harness/lib/epoch.sh:173`). |

The four components (`epoch.sh`):
- **subject_identity** (`epoch.sh:81`): the project name and its
  `remote_match`.
- **topology_version** (`epoch.sh:118`): the project's probe answers, first
  six fields, sorted. Which instrument answered is deliberately left out.
- **policy_version** (`epoch.sh:134`): `felix_commission_policy_version`
  (`engine/harness/lib/commission.sh:541`), one hash over the twelve tables in
  `FELIX_COMMISSION_TABLES` (`commission.sh:52`), `obligations.tsv` among
  them, with a header line per file.
- **release_target** (`epoch.sh:154`): `FELIX_RELEASE_TARGET`, else
  `project.json` `release_target`, else origin's default branch, else `main`.

How it goes stale, today, in `felix_verify_current` (`verify.sh:578`), in the
order it checks:
1. no receipt (`none`), or a red one (`red`);
2. the tree id no longer matches;
3. a six field receipt, written before epochs existed;
4. an epoch of `-`, meaning the project declares no probes;
5. the epoch cannot be read now (`epoch.sh` not loaded, or a probe answer
   unknown);
6. the epoch moved, named by the component that moved: topology first, then
   policy, then subject, then release target.

### 1.2 The commission receipt

Written by `felix_commission_receipt_write` (`commission.sh:649`), the §8
step 10 `project_commissioned` receipt. One line of ten tab separated fields
at `$FELIX_HOME_DIR/state/commission/<project>` (`commission.sh:637`): when;
policy version; capabilities hash (`felix_commission_caps_hash`,
`commission.sh:556`, the detected surfaces); toolchain (the `claude` CLI the
probes resolve); result (`commissioned`, `held` or `indeterminate`); and five
counts (done, held, unknown, malformed, awaiting).

Its validity is never stored. `felix_commission_receipt_valid`
(`commission.sh:680`) derives it on every read: stale when the table set
moved, stale when the detected surfaces moved, not current when
indeterminate, unreadable when its counts are not numbers, and flagged when
the CLI changed since.

The gate reads it announce only (`felix:980` to `1002`): a stale or absent
commission receipt is printed and never fails the gate. It is per project and
per machine, not per commit, so a CI runner has none and reports it absent.

### 1.3 The `felix.receipt/1` document

At 78f0268, `felix_receipt` (`engine/harness/lib/receipt.sh:91`), printed by
`felix receipt` (`felix:4099`). JSON with `schema: "felix.receipt/1"`, a
`status` of `verified`, `unverified`, `blocked` or `indeterminate`, an
`unknown` list, a
`verification.state` of `none`, `stale` or `current` read through
`felix_verify_current`, risk, evidence, authority, and a `limits` object
(`receipt.sh:269`). Its rule, "a receipt may not claim more than it knows",
carries straight into the predicate below.

**What changed on main since.** `receipt.sh` at 0.49.338 writes
`felix.receipt/2` (0.49.327), not `/1`. Its `status` has six words: `checked`,
`failed`, `evidence-owed`, `unchecked`, `blocked` and `indeterminate`. The old
`verified` is now `checked`, and the old `unverified` is split three ways by
what the gate did on this tree. The same file now adds `evidence` to `unknown`
when a row of the evidence table could not be judged. The `limits` object is
untouched by that change. This document does not map `status` into the
predicate, so nothing in §2 moves, but a builder written from this document
reads `/2` at main, and the "verified" and "unverified" of the paragraph above
are the `/1` words.

## 2. What is Felix's own

### 2.1 What is not

Signed attestations bound to a commit are not new. The 09-19 market review
(`docs/2026-09-19-direction-decisions.md` §4) found that AI-SDLC "already
commits SHA-bound signed attestations into the adopter's repository" and
concluded that "repo-owned, revision-bound receipts are NOT novel". The README
says the same (`README.md:429`). In-toto, DSSE and Sigstore are also not ours.
Shipping in them is the point: a receipt in a common shape can be checked by
tooling Felix does not write.

### 2.2 What is

The same review names what nobody else documented: receipts "that go stale
when a dependency changes". A signature does not go stale on its own: it
stays a signature over the bytes it covers. So staleness has to live in the statement as data:
the statement names every input the verdict rested on, with its digest, and a
verifier recomputes whichever of them it can reach. Section 1 shows Felix
already records those inputs. The predicate below carries them, plus two
things the receipts do not record yet.

The Felix predicate has four groups J named: the tree, the obligation set,
the judge pin, and what makes the receipt stale.

### 2.3 The statement

Illustrative only. Field names are proposals; values are placeholders.

```json
{
  "_type": "https://in-toto.io/Statement/v1",
  "subject": [
    {
      "uri": "git+https://github.com/OWNER/REPO",
      "digest": { "gitCommit": "<40 hex: the commit CI checked out>" }
    }
  ],
  "predicateType": "<FELIX_PREDICATE_BASE>/gate-receipt/v0",
  "predicate": {
    "receipt": {
      "kind": "gate",
      "source": "felix.gate-receipt/8",
      "result": "green",
      "when": "2027-03-02T18:04:11Z",
      "gateCommand": "<project.json gate>",
      "engineVersion": "0.49.308"
    },
    "tree": {
      "felixTreeId": "<field 1>",
      "felixTreeIdAlgorithm": "felix-tree-id/1",
      "gitTree": "<HEAD^{tree} of the subject commit>",
      "clean": true
    },
    "checks": {
      "reported": [ { "name": "obligations", "verdict": "ok" } ],
      "skipped": []
    },
    "obligationSet": {
      "policyVersion": "<component 3>",
      "tables": ["project.json", "capabilities", "...", "obligations.tsv"],
      "obligations": {
        "path": "projects/<p>/obligations.tsv",
        "digest": { "gitBlob": "<blob id at the subject commit>" }
      }
    },
    "epoch": {
      "id": "<field 7>",
      "subjectIdentity": "<component 1>",
      "topologyVersion": "<component 2>",
      "policyVersion": "<component 3>",
      "releaseTarget": "<component 4>"
    },
    "judge": {
      "pinned": false,
      "pin": null,
      "engineCommit": "<commit of the engine that ran the gate>"
    },
    "commission": {
      "reported": "<the gate's commission line>",
      "policyVersion": "<component 3>"
    },
    "staleWhen": [
      "tree_changed",
      "epoch_absent",
      "epoch_unreadable",
      "topology_moved",
      "policy_moved",
      "subject_moved",
      "release_target_moved",
      "judge_moved"
    ],
    "limits": {
      "authority": "one authority writes both the work and the judgement of the work",
      "enumeration": "an entrypoint never found is never executed",
      "signature": "a signature says who signed this statement, not that the gate was the right gate"
    }
  }
}
```

### 2.4 Field by field

| Predicate field | From | Notes |
|---|---|---|
| `subject[0].digest.gitCommit` | the commit CI checked out | The in-toto digest set lists `gitCommit` as "The lowercase hex SHA-1 (40 character) or SHA-256 (64 character) of a git commit". The receipt itself does not store the commit; HEAD is inside the tree id's hash. In CI the commit is `GITHUB_SHA`. |
| `receipt.result`, `when`, `gateCommand` | gate fields 2, 3, 4 | As written. |
| `receipt.engineVersion` | `engine/.claude-plugin/plugin.json` `version` | Not in the receipt today. |
| `tree.felixTreeId` | gate field 1 | Felix's own hash, so it gets its own algorithm label and is never put in `digest`, which in-toto reserves for named algorithms. `git hash-object` is SHA-1 here, which is one more reason the subject uses `gitCommit` and this stays inside the predicate. |
| `tree.gitTree`, `tree.clean` | `git rev-parse HEAD^{tree}` | `gate.yml` already prints this as the "gated tree" notice. On a clean CI checkout the tree id is a function of the commit alone, so `clean: true` is what lets a verifier trust `gitCommit` as the thing judged. A Mac receipt over uncommitted edits is not what is signed (§3.3 on the CI path; #504 signs the authority's record of a landing). |
| `checks.reported`, `checks.skipped` | gate fields 6 and 5 | Split from `name:verdict` pairs. Their limit travels with them: a check that runs without printing a line is not here (`verify.sh` comment above `felix_verify_record`). |
| `obligationSet.policyVersion` | component 3 | Covers all twelve tables at once. |
| `obligationSet.obligations.digest.gitBlob` | `git rev-parse <commit>:projects/<p>/obligations.tsv` | Not recorded today: the obligation set is folded into the policy hash. Derivable from the commit, so a verifier with the repository can check it. See open question Q2. |
| `epoch.*` | gate fields 7 and 8 | As written. |
| `judge.pinned`, `judge.pin` | nothing yet | Roadmap Phase 0b step 14 (the judge-identity epoch) and step 15 (the judge pinned outside the change it judges) are not built. Until they are, `pinned` is `false` and `pin` is `null`, and a verifier must read that as "this gate was judged by the engine in the change". |
| `judge.engineCommit` | the engine commit CI ran | An interim provenance fact, not a pin. On felix-home it equals the subject commit, which is exactly the self-judging case the pin exists to end. |
| `commission.*` | the gate's `commission` line and component 3 | The commission receipt is per machine. A CI runner has none, so the CI statement carries what the gate reported, not a Mac's receipt. See Q4. |
| `staleWhen` | `felix_verify_current` and `felix_commission_receipt_valid` | Canonical snake_case codes for the reasons those functions print today as sentences. See §2.5. |
| `limits` | `receipt.sh:269`, plus one line | The first two are carried verbatim from `felix.receipt/1`; `/2` left `limits` as it was. |

### 2.5 Staleness as codes

Today the stale reasons are sentences printed by `felix_verify_current`. A
signed, machine read statement needs stable codes. Proposed mapping, one code
per reason, with no code reused:

| Code | `felix_verify_current` text today |
|---|---|
| `tree_changed` | "the tree changed since the receipt" |
| `epoch_absent` | "the receipt predates the epoch" and "the receipt carries no epoch" |
| `epoch_unreadable` | "the epoch cannot be read now" and "the grounded facts cannot be read now" |
| `topology_moved` | "the grounded facts moved since the receipt" |
| `policy_moved` | "the table set moved since the receipt" |
| `subject_moved` | "the subject moved since the receipt" |
| `release_target_moved` | "the release target moved since the receipt" |
| `epoch_moved_unexplained` | "the epoch moved since the receipt and no component says why" |
| `judge_moved` | none yet; reserved for the pin |

And for the commission receipt, from `felix_commission_receipt_valid`:
`commission_policy_moved`, `commission_surfaces_moved`,
`commission_indeterminate`, `commission_unreadable`, `commission_toolchain_moved`.

Two of the rows above merge two sentences into one code. Whether they should
stay separate is Q5. Whichever way it goes, the codes become a contract once
signed: before the first record is signed they get a test for the mapping
from each sentence and a test that the set does not drift (§7, step 1).

### 2.6 What a verifier can and cannot recompute

This is the honest limit of "goes stale", and it belongs in the doc a buyer
reads.
- **Can, offline, from the repository:** `gitCommit`, `gitTree`, the
  `obligations.tsv` blob, and `policyVersion` when the twelve tables live in
  the same repository.
- **Cannot, offline:** `topologyVersion`. It is the answer of the project's
  probes, which ask the world. A buyer can rerun them only with the engine
  and the same environment, so for them it is a recorded fact, not a checked
  one.
- **Cannot, for other people's repositories today:** `policyVersion` and the
  obligation set. A governed product's tables live in felix-home
  (`docs/direction.md` §5, "A product project's tables live in felix-home"),
  which the product's owner cannot read. Until the tables move into the
  governed repository (roadmap Phase 2), a customer verifier can check the
  signature and the commit, and must take the policy hash on trust.

## 3. Where the key lives

**Read this section as the CI path.** It answers where the key lives if a
GitHub Actions job signs, which was the proposal for March. The authority's
design (#504, rule 8 and decision 5) puts the signer under a login of its own
on the authority's machine, the key made there, its public half a founder
path, and the signature made after the fact so that, by its design, nothing
that decides reads it. That design does not pass through this section's `sign.yml`, OIDC
token, KMS trust policy or Fulcio certificate. What survives it is the
definition in §3.1 and the rule behind J's three conditions: no deciding step
reads or waits on the signature. §3.2 and §3.3 stay as the record of the CI
path, of J's rulings on it, and of the review that shaped them, for a
connector that signs from a forge's CI. Nothing in them says a key exists.
"March" in §3, §4 and §5 is the date those steps were proposed for, when this
was written; #504 schedules none of them.

### 3.1 What "the enforcing path" means here

Felix's own documents define the enforcing path by what a decision needs, not
by who can reach what. The 2026-08-15 authority note: "the enforcing path has
to work with no network, no key, and no model, because a permission check that
needs a model to answer is not a permission check"
(`docs/2026-08-15-authority-that-cannot-be-earned.md:15`). The 2026-08-11
self-diagnosis design says the same twice: the blocking part "works with no
network, no key, no model" (`docs/2026-08-11-self-diagnosis-design.md:98`),
and "The enforcing path must work with no network, no key and no model"
(line 340).

The deciding steps are the deny hooks, the gate, CI's judgment of the head,
`felix merge` and the land tick. That path is not only on the Mac. CI is on it
too: `engine/harness/lib/green-tick.sh:11` puts it as "The author's gate wrote
the receipt, CI judged the head, and `felix merge` judges escapes, commission
tables, the receipt, rule C9 and staleness with main's installed engine", and
rule C9 (`engine/harness/lib/escape.sh:495`) reads the gate workflow's own run
on the exact commit. So "a key on the enforcing path" means **a deciding step
that needs a key in order to decide**. It does not mean "a key on the Mac".

### 3.2 The founder's reading (2026-10-29, condition 3 on 2026-10-31)

J ruled on 2026-10-29 that a cloud KMS key that only CI can reach is off the
enforcing path on three conditions, and that if any one fails, the key is on
the path. On 2026-10-31 he ruled how condition 3 is met. `docs/direction.md`
§5, under "Not before March", now records this reading in brief. This pull
request does not edit direction.

**Condition 1. Nothing that decides reads or waits on the signature.** Not
the gate, CI's judgment, `felix merge` or the land tick. If KMS is down,
landing goes ahead and the receipt is recorded as unsigned. The signing job
is never a required check.

How it is checked:
- **Its own workflow file.** Signing lives in a new
  `.github/workflows/sign.yml`, never as a job inside `gate.yml`. Rule C9
  asks `gh run list --workflow gate.yml` for the newest run's conclusion
  (`escape.sh:557`, the workflow named by `felix_gate_workflow`,
  `engine/harness/lib/bootstrap.sh:37`), and `automerge.sh:67` filters its
  run list by the gate workflow it is handed. A failed signing job inside
  `gate.yml` would turn that run red and hold every merge, so it would be on
  the path. A separate workflow's failure is invisible to both.
  `lib/pr-status-gh.sh` and `lib/inventory-gh.sh` read a pull request's whole
  `statusCheckRollup` and count any failing check. A `sign.yml` run sits on
  main's newest commit, not on a pull request's head, so they should not see
  it either; they are in the grep and the stubbed test below all the same.
- **The receipt upload cannot fail the judging run.** `gate.yml` uploads no
  receipt artifact today, so March adds one upload step to it. That step
  runs with `continue-on-error: true`, held by a test, because a failed
  upload that turned the gate red would hold merges through C9.
- **Not a required check.** felix-home has no branch protection
  (`escape.sh:498`: "the plan does not allow it on a private repository"). On
  any repository that has it, `gh api repos/OWNER/REPO/branches/main/protection`
  and `gh api repos/OWNER/REPO/rulesets` must list no required status check
  from `sign.yml`. The March build adds this read to the repository's setup
  checks, and the check fails if it finds one.
- **Nothing in the engine reads a signature.** A test in March greps the
  deciding code (the hooks, `lib/verify.sh`, `lib/escape.sh`, the gate,
  `felix merge`, `lib/green-tick.sh`, `lib/pr-status-gh.sh`,
  `lib/inventory-gh.sh`) for any reference to a bundle,
  `cosign` or the signing workflow, and fails on one.
- **Unsigned is a state, not a failure.** When the signing run fails or
  never runs (KMS down, the `reuse` job stood on an earlier tree so no
  receipt exists), no bundle is published for that commit. A reader reports
  the receipt as `unsigned`, and nothing maps `unsigned` to red. A test
  stubs a failed signing run and asserts the land tick still lands and the
  pull request status and inventory readers count nothing failing.

**Condition 2. Signing is a separate job that runs after CI's judging job and
cannot change its result.**

How it is checked:
- **Ordering.** `sign.yml` runs `on: workflow_run` for the `gate` workflow,
  `types: [completed]`, `branches: [main]`, and its job runs only when
  `github.event.workflow_run.conclusion == 'success'` and
  `github.event.workflow_run.event == 'push'`. It signs
  `github.event.workflow_run.head_sha` and no other commit.
- **No write path back.** Its `permissions` block is exactly `contents:
  read`, `actions: read` (to download the gate run's receipt artifact) and
  `id-token: write`. No `checks`, `statuses`, `actions: write`,
  `pull-requests` or `contents: write`, so it cannot post a status, re-run or
  cancel a run, or push. A March test reads `sign.yml` and fails on any
  other permission, the way `tests/run` already holds every workflow's
  `uses:` to a commit (`gate.yml` header).
- **Main's copy runs.** GitHub's `workflow_run` section says "This event
  will only trigger a workflow run if the workflow file exists on the default
  branch", and lists `GITHUB_SHA` as "Last commit on default branch" and
  `GITHUB_REF` as "Default branch" (read by the desktop review, 10-30). So
  `sign.yml` always runs main's copy, and `github.sha` in it is main's newest
  commit, never the gated one.
- **Both guards stay.** The `branches` filter names "what branches the
  triggering workflow must run on", which is a branch name. A fork's pull
  request from a branch called `main` passes it, so the `event == 'push'`
  guard is what keeps that run out.

**Which commits get a signed receipt.** As specified, few. On a push to main,
`gate.yml`'s `gate` job runs only when `needs.reuse.outputs.run == ''`
(`gate.yml:65`); otherwise it is skipped and the run still concludes
`success`. The file's header counts 174 of 203 pushes from 09-01 to 09-25
that gated a tree the pull request's run had already passed, so about one
main commit in seven would have a receipt to sign. Two ways, a design call
for the March build:
- `sign.yml` follows reuse's pointer to the pull request's run and signs that
  run's receipt, after checking that its gated tree equals the subject
  commit's tree (the check `reuse-verified-tree.sh` already makes);
- or a reused commit stays unsigned, and the reader says `unsigned`.

**Condition 3. The KMS trust policy accepts only the signing workflow on
`refs/heads/main`, by the token pin alone.** J ruled on 10-31: the signing
job names no environment, and the KMS trust policy accepts only a token
whose `sub` names main's ref and the reusable signing workflow at
`@refs/heads/main`. If Free cannot set the token template on a private
repository, the pin moves into the KMS trust policy's own claim conditions.
If neither works, the key is on the path and felix-home stays unsigned.

Why no environment, in J's words of the same ruling: an environment does
not weaken the pin everywhere. It moves the branch check out of the token
and into the environment's branch rule. A private repository on Free has no
such rule, so there, naming an environment would leave no branch check at
all. On a public or paid repository, an environment with a main only branch
rule is just as strong, but it is not needed, so this doc uses the token pin
everywhere.

A change to `.github/workflows/` is an escape channel (`escape.sh:116`,
`FELIX_ESCAPE_EXECUTE`), so an agent's edit to the workflow cannot land on
its own. But CI runs a branch's own copy of a workflow before anything lands,
and that run can ask for an OIDC token. Without the main only pin, an agent
could push a branch carrying its own `sign.yml`, or calling the reusable
signing workflow at `@main`, and get its own verdict signed. This condition
is what makes "no agent ever reaches that key" true.

How it is checked:
- **The token's subject.** GitHub's `sub` is
  `repo:ORG/REPO:ref:refs/heads/BRANCH` for a branch and
  `repo:ORG/REPO:pull_request` for a pull request, and it carries the ref
  only when the job names no environment; naming one replaces the ref with
  `environment:NAME` (GitHub OIDC reference), and the branch check moves
  to the environment's branch rule. So the signing job names no
  environment, on every repository.
- **The pin.** The repository's subject template is set with
  `include_claim_keys: ["repo", "context", "job_workflow_ref"]` (GitHub OIDC
  reference, "customizing the subject claims"). For a reusable workflow the
  standard claims, `sub`'s context and `ref` among them, describe the calling
  run, and only `job_workflow_ref` describes the called file. So the signing
  run, started by `workflow_run` on the default branch, gets
  `repo:ORG/REPO:ref:refs/heads/main:job_workflow_ref:ORG/REPO/.github/workflows/<reusable>.yml@refs/heads/main`.
  A branch that calls the reusable workflow at `@main` gets
  `ref:refs/heads/<branch>` in the same place, and a pull request run gets
  `pull_request`, so KMS refuses both. The trust policy matches the string
  exactly, with `aud` pinned too and no wildcard.
- **Read from a real token, in March.** GitHub's REST page for the subject
  template (`PUT /repos/{owner}/{repo}/actions/oidc/customization/sub`)
  states no limit by plan or visibility, but does not say Free either. The
  first March step sets the template on felix-home and reads a real token's
  `sub`. The same endpoint has `use_immutable_subject`, which switches `sub`
  to a form built from repository ids, so the trust policy matches the
  string read from that real token, never one written by hand. If the
  template cannot be set on a private repository on Free, the pin moves into
  the KMS trust policy's own claim conditions: a GCP Workload Identity
  Federation attribute condition, for one, can check `assertion.ref`,
  `assertion.job_workflow_ref` and `assertion.repository` directly. If
  neither can be set, the key is on the path and felix-home stays unsigned.
- **The refusal test.** Before the first signed receipt, the desktop session
  shows KMS refusing the two cases J's ruling names: a throwaway branch
  carrying its own copy of the signing workflow, and a `pull_request` run.
  The same run adds a branch that calls the reusable workflow at `@main`,
  since that is the case only `job_workflow_ref` and the ref together
  catch. A pass is the signing call failing on every one.
- **The signing job runs nothing an agent can land on green.** The pin
  controls which workflow file can use the key, not what that file runs. If
  the job checked out the repository and ran `engine/harness/felix` or a
  builder under `engine/`, an engine change landed on green would run with
  `id-token: write` and the pinned `sub`, and could have KMS sign any
  statement about any commit. GitHub's `workflow_run` section warns of this:
  "Running untrusted code on the `workflow_run` trigger may lead to security
  vulnerabilities". The same `sign.yml` lint that checks permissions also
  fails on any of these:
    - a `run:` step that calls a path outside `.github/workflows/` and
      `.github/actions/`;
    - `actions/cache` or any other cache restore;
    - the gate's output sourced or run, rather than read as data with `jq`;
    - a subject taken from anywhere but
      `github.event.workflow_run.head_sha`, or a statement whose own subject
      differs from it;
    - `github.sha` anywhere in the file;
    - any trigger on `sign.yml` but `workflow_run`, or any caller of the
      reusable workflow but `sign.yml`.

The statement builder therefore lives in the signing workflow, under the
existing `.github/workflows/` channel, and needs no new escape path (Q3).
It cannot live inside `gate.yml`: a step after `./engine/harness/felix gate`
in the same job shares the runner with whatever the engine left behind, the
workspace, `GITHUB_ENV` and `GITHUB_PATH` included.

With the template, or the same pin in the KMS trust policy's own claim
conditions, all three conditions can hold on felix-home on its current
plan, and the key is off the path. If any one fails, it is on the path and
felix-home stays unsigned.

### 3.3 The keyless path and the Mac

For a public repository, the same `sign.yml` signs keyless instead: a
certificate Fulcio issues for 10 minutes from the workflow's OIDC token
(Sigstore, "Fulcio signs X.509 certificates valid for 10 minutes"), an
ephemeral key that never leaves the job, and no key stored anywhere. There
the main only pin lives in the verifier: §5's `--certificate-identity`
(the reusable signing file, since Fulcio puts the job's `job_workflow_ref`
in the certificate's identity) and `--certificate-github-workflow-ref` pin
the signing workflow and the run's ref to `main`, so a receipt a branch copy got signed fails
verification. Both are needed: a branch's own workflow can call the reusable
signing workflow at `@main`, and only the run's ref tells that run apart.
Conditions 1 and 2 hold the same way.

Receipts written on the Mac are never signed, whatever they say. A Mac
receipt can be over uncommitted edits, and the signing step only ever signs
a commit CI judged on `main`.

What an agent can and cannot reach, with all three conditions met:

| | Can reach | Cannot reach |
|---|---|---|
| Session on the Mac | the gate receipt in `state/gate/`, every engine file, any branch it pushes | the KMS key; an OIDC token with the pinned subject |
| A branch or pull request it pushes | a run of its own workflow copy, which can ask for an OIDC token | a token KMS accepts: its `sub` names its own branch or `pull_request`, even when it calls the reusable workflow at `@main` (condition 3). For keyless, a certificate that passes §5's identity and ref checks |
| Code it lands on main | what the next signing run signs, because the gate run that produced the receipt ran main's engine | `sign.yml`, the reusable workflow and the statement builder inside it, since `.github/workflows/` waits for the founder and the signing job runs nothing else |

The third row is the real exposure, and the conditions do not close it. Land
on green lands engine PRs, judge-changing ones included (direction row 24).
An agent that lands a change to the gate changes what gets signed, and the
signature will be valid. That is why `judge.pinned` exists. The conditions keep the agent away from
the key; only the judge pin keeps it away from the verdict.

## 4. Private repositories

**felix-home.** Private, on GitHub Free (J, 10-29). `docs/direction.md` §6
says the founder made it private on 10-30 at about 06:00Z, that a 10-24
switch never took effect, and that it was public from 08-09. (This document
first said private since 10-24.) Three facts decide the public Sigstore case:
1. GitHub's artifact attestations on Free, Pro or Team are "only available
   for public repositories", and "To use artifact attestations in private or
   internal repositories, you must be on a GitHub Enterprise Cloud plan"
   (GitHub docs, using artifact attestations).
2. Keyless signing on the public Sigstore instance publishes the signer. The
   Fulcio certificate for a GitHub Actions token carries the source
   repository URI, its owner, the ref, the commit, the workflow path and the
   repository's visibility at signing (Fulcio OID extensions
   `1.3.6.1.4.1.57264.1.12` to `.22`). Rekor makes the signing event
   "publicly auditable".
3. Skipping Rekor does not hide it. Fulcio appends every certificate it
   issues "to an immutable, append-only, cryptographically verifiable
   certificate transparency (CT) log", separate from Rekor. So `cosign`
   without the transparency log upload still publishes felix-home's name
   and commit through the CT log.

So felix-home gets **no signed receipts on public infrastructure**. Its
receipts stay as they are: unsigned, local, and current only by
`felix_verify_current`.

**Which repositories get receipts, and how:**

| Repository | Receipts, proposed | How |
|---|---|---|
| A public repository Felix governs, first the Phase 4 public replay repository (roadmap Phase 4) | Signed, on the CI path | Keyless on the public Sigstore instance, logged in Rekor. Its identity is public already. |
| felix-home | On the CI path: a CI only KMS key. Under #504: a record signed by the authority's signer. Nothing is signed today | Never on public Sigstore, on either path. On the CI path only once all three conditions of §3.2 hold, checked as that section says, with the main only pin in the token template or else in the KMS trust policy's own claim conditions and no environment named; if neither pin can be set, the key is on the path and felix-home stays unsigned (Q1). The authority's signer has its own conditions in #504 rule 8. |
| LeavesJ/Felix (public) | None from this design | Publishing there is a founder stop (direction row 4); this doc proposes nothing for it. |
| A customer's private repository | Signed only on their infrastructure | One of the three options below. |

**What a private repository customer needs**, one of:
- **GitHub Enterprise Cloud.** Attestations from private repositories then
  go through "GitHub's own Sigstore instance", which "does not have a
  transparency log and only federates with GitHub Actions" (GitHub docs,
  artifact attestations). Nothing is published; verification is `gh
  attestation verify` with access to the repository.
- **Their own Sigstore.** A private Fulcio, CT log and Rekor, verified
  against their own trusted root (`cosign verify-blob-attestation
  --trusted-root`). Most control, most to run.
- **A cloud KMS key, reached by OIDC.** cosign signs with `--key
  awskms://...`, `gcpkms://...` or `azurekms://...`; the CI job reaches the
  key through its OIDC identity and the key never leaves the KMS. No public
  log. Off the enforcing path only under the three conditions of §3.2,
  which the customer's own plan and trust policy have to meet.

## 5. Verification

The commands below are for the CI path. They check a GitHub workflow's
identity, which the authority's signer does not have. A record signed by the
authority is checked against the public key the founder holds as a founder
path in P (#504 decision 5), and which scheme made it is open there, so no
command here is tested against it. The key form further down is the closest
of the three. Of the two lists after the commands, "what it does not prove"
holds for any signer; "what a passing check proves" is stated for the CI path.

For a public repository on the CI path, the buyer runs:

```sh
cosign verify-blob-attestation \
  --bundle felix-receipt.sigstore.json \
  --type '<FELIX_PREDICATE_BASE>/gate-receipt/v0' \
  --certificate-identity 'https://github.com/OWNER/REPO/.github/workflows/<reusable signing workflow>.yml@refs/heads/main' \
  --certificate-oidc-issuer 'https://token.actions.githubusercontent.com' \
  --certificate-github-workflow-repository 'OWNER/REPO' \
  --certificate-github-workflow-ref refs/heads/main \
  --certificate-github-workflow-trigger workflow_run \
  --digest "$(git rev-parse HEAD)" --digestAlg gitCommit
```

`--digest` and `--digestAlg` check the statement's subject against a digest
"instead of providing a blob" (cosign docs). Whether cosign accepts
`gitCommit` as the algorithm name is not confirmed; if it does not, the
fallback is `--check-claims=false` (which, per cosign, verifies "only the
DSSE envelope") followed by a `jq` check that `subject[0].digest.gitCommit`
equals the commit. Testing that is Q6 (§7, step 5). Then, for
staleness, `felix receipt verify` (not built) would recompute what §2.6 says
can be recomputed and print the `staleWhen` codes that fire.

For a repository signed with a KMS key under §3.2, the buyer holds the
public key the owner publishes and runs:

```sh
cosign verify-blob-attestation \
  --bundle felix-receipt.sigstore.json \
  --key felix-receipt.pub \
  --type '<FELIX_PREDICATE_BASE>/gate-receipt/v0' \
  --insecure-ignore-tlog \
  --digest "$(git rev-parse HEAD)" --digestAlg gitCommit
```

`--insecure-ignore-tlog` is cosign's own flag for a signature never
uploaded to a log, and cosign says plainly that such "Artifacts cannot be
publicly verified when not included in a log". That is the trade of a
private repository: the buyer trusts the published key, not a public log.

For a private repository on Enterprise Cloud, `gh attestation verify` with
`--predicate-type` and `-R OWNER/REPO`, if GitHub's tooling accepts a commit
subject; else the same cosign command against GitHub's trusted root (Q6).

**What a passing check proves, on the CI path:**
- this exact statement was signed by a certificate Fulcio issued to the
  signing workflow of that repository, in a run on `main` that a completed
  gate run started;
- the statement names that commit;
- for a public repository, the signing was logged in Rekor at a time inside
  the certificate's 10 minutes.

**What it does not prove, whoever signs:**
- that the gate was the right gate. The signer is the workflow, and the
  workflow ran whatever engine was on main. `judge.pinned: false` says this
  in the statement itself.
- that the obligations were the right obligations, or complete. Admission
  is a person's act (direction §3), and direction §2, as of 2026-11-12,
  counts 22 candidates proposed and 0 admitted.
- that the receipt is still current. The signature is permanent; staleness
  needs the recomputation in §2.6, and part of it (topology) cannot be
  recomputed by a buyer at all.
- anything about controls, policies or an audit framework. Felix makes no
  compliance claim from these receipts until a buyer asks for one.

## 6. The landscape

in-toto Statement v1 in a DSSE envelope is what six of the ten rows below use
for signed receipts. That counts what was found when this was read, not the
field. It is not a settled standard for them: none of the sources read on
2026-10-29 showed a standards body adopting an agent receipt format, and each
project below had one star or none. Star counts were read on the repository
pages on 2026-10-29.

**The base layers.** The in-toto attestation framework defines the Statement
(`_type` is "Always `https://in-toto.io/Statement/v1`"; each subject "MUST
have `digest` set") and recommends DSSE: "The RECOMMENDED format and protocol
for Envelopes are defined per DSSE v1.0", with `payloadType`
`application/vnd.in-toto+json`. Its latest release is v1.2.0, and the
Statement layer is still v1. SLSA build provenance is itself "a predicate type
within the in-toto attestation framework" (SLSA v1.2), which is why the
supply chain verifiers a buyer may already run (cosign, `gh attestation`)
read this shape.

**Agent receipt projects.**

| Project | Format | Key and log | License, stars |
|---|---|---|---|
| agentattest, `AuroraAeon/agentattest` | in-toto Statement v1 in DSSE; predicate `https://agentattest.dev/predicate/v1` | Sigstore, cosign, Fulcio; Rekor inclusion. Where a producer's key lives is not stated | Apache-2.0, 1 star |
| agentattest, `BlockTarioIQ/agentattest` | A fork of the above, same format | Same; verifies against the Sigstore TUF root | Apache-2.0 per its README, 0 stars |
| Two more repositories named agentattest (`rogerchappel`, `leijingqiu3-ops`) | Unsigned JSON, and a SHA-256 hash chain | No public key signing | MIT, 0 stars each |
| agent-receipt, `pramodreddyboddu/agent-receipt` | Markdown receipt with an optional Ed25519 sidecar; its `attest` command writes in-toto Statement v1 in DSSE, predicate `https://agent-receipt.dev/run/v1` | Local Ed25519 keys, or `--keyless` through Fulcio and Rekor | MIT, 0 stars |
| agentproof, `PawanPatil19/agentproof` | JSON receipts, signed as "an Ed25519 DSSE signature over an in-toto statement" | A local key pair | MIT, 0 stars |
| AgentProof, `GenRamzi/AgentProof` | A SHA-256 digest; in-toto and DSSE only planned | None yet | Apache-2.0, 1 star |
| attested, `Praxso/attested` | "an in-toto Statement whose subject is the CTRF report"; DSSE implied by GitHub's bundles, not stated | Keyless through GitHub's `actions/attest` | Apache-2.0, 0 stars |
| VeriForge, `AdriaBA/veriforge-attest` | in-toto Statement in DSSE, predicate `https://veriforge.dev/predicates/agent-execution/v0.1` | Local keys, a cosign key, or cosign keyless with GitHub OIDC (recommended for CI) | No license seen, 0 stars |
| agentkey, `mgillr/agentkey` | "DSSE with the in-toto Statement v1 inside"; predicate set by the caller | One Ed25519 key per agent role, by default a file on the machine the agent runs on; optional keyless to Rekor | Apache-2.0, 0 stars |
| Traceseal (`traceseal/traceseal-verify`, PyPI `traceseal-verify` 1.0.2) | **Not in-toto.** Canonical JSON (sorted keys, compact separators) of `{execution, provenance}`, signed with Ed25519, public key embedded "so verification is self-contained" | Operator key; log fields present but not checked by verification | Apache-2.0, 0 stars |

Two of these matter beyond the count:
- **Traceseal's own post (2026-10-20)** weighs DSSE against its design and
  concedes: "the DSSE authors' objection is a fair one and it applies to us",
  and "signing the exact bytes with a typed envelope is the safer default".
  It does not use the words "better design".
- **agentkey's default** keeps the signing key in a file on the machine the
  agent runs on. That is the arrangement §3 rules out for Felix.

**The IETF draft.** `draft-marques-asqav-compliance-receipts`, revision -09
(2026-09-21), Informational, an individual submission aimed at the
Independent Submission stream, not an IETF working group document, expiring
2027-03-25. It defines its own JSON envelope: "The JSON signing input is the
UTF-8 JCS serialization of the complete payload object" (RFC 8785), with
"New issuance under this revision MUST use alg="ML-DSA-65"". Receipts are
hash chained and anchored by timestamps and a witness policy, not a
transparency log. It does not mention in-toto, DSSE or Sigstore; SCITT
appears only as a possible future "SCITT-style inclusion-proof profile".

**Why in-toto v1 in DSSE over the draft:**
1. **The subject is right.** A Felix receipt is a claim about a revision.
   in-toto's subject is a digest of the thing the claim is about, and
   `gitCommit` is a listed digest. The draft's receipt is a record of an
   agent's action, chained to the previous one; Felix's verdict is not an
   action in a chain.
2. **No canonicalization.** DSSE signs the exact payload bytes. The draft,
   like Traceseal, signs a JCS re-encoding, which is the design Traceseal's
   own post calls the riskier default.
3. **Existing verifiers.** cosign and GitHub's attestation tooling verify
   in-toto in DSSE today, against Sigstore and GitHub identities, which is
   what §3 and §5 rely on. None of the verifiers we read handles the draft's
   envelope or ML-DSA-65.
4. **Its standing.** An individual Informational draft can change in every
   revision (it is at -09). That is a reason to watch it,
   not to build on it. If it reaches a working group, Felix can emit a second
   envelope over the same predicate; nothing in §2 is tied to DSSE.

## 7. What this asks of the build

Nothing here is built. This list is what the format asks of whoever builds
the authority's signing (#504 rule 8, decision 5), in an order that holds
whichever scheme the signer uses. #504's own staged order (its §7) decides
when each lands; none of these is scheduled here.
1. The stale codes of §2.5 as a contract, with the mapping and drift tests.
   This reads the gate receipt at main, which is `felix.receipt/2` (§1.3).
2. The predicate, written from the gate receipt by a builder. Where it runs
   is the authority's design to place: it has to sit with the signer, outside
   the kernel, so that, by the authority's design, nothing that decides reads
   it or waits on it. On the
   CI path it was to live in the signing workflow (§3.2, Q3).
3. The predicate type URI (Q7), chosen before the first record is signed,
   since a signed statement carries it.
4. The signing scheme, which #504 leaves open and which this document
   proposes nothing for: DSSE (§6) signs the exact payload bytes and leaves the
   key to the signer, so the envelope does not fix the scheme. What §5 can say about each
   scheme is in §5.
5. The verification command run from a clean machine on the first signed
   record. If the scheme is Sigstore's or a cosign key, that includes Q6,
   whether cosign verifies a `gitCommit` subject.
6. Only if a connector signs from a forge's CI: `sign.yml` and its reusable
   signing workflow, as a draft labelled `needs-founder` (it touches
   `.github/workflows/`), with the checks §3.2 names for each condition and
   the branch refusal test run before any receipt is signed.

## 8. Open questions

Nothing waits on J now. Q1 is ruled, and Q7 waits until the first record is
to be signed. Q2, Q4 and Q5 are how questions: the build decides them and
writes down why. Q3 is settled for the CI path, and Q6 is a test. The signing
scheme is open in #504 and is not one of these seven.

**Ruled by J, or held:**
- **Q1, ruled 2026-10-29 and 2026-10-31.** A cloud KMS key that only CI
  can reach is off the enforcing path on the three conditions of §3.2, and
  on the path if any one fails. On 10-31 J ruled condition 3 as the token
  pin alone, with no environment, with the fallback into the KMS trust
  policy's own claim conditions, and felix-home unsigned if neither works.
  The refusal test still runs before the first receipt on the CI path.
  `docs/direction.md` §5 records the ruling in brief. #504 rule 8 carries
  condition 1 into the authority's design.
- **Q7, held.** The predicate type URI. It needs a stable base Felix
  controls; this doc keeps `<FELIX_PREDICATE_BASE>`, and the address gets
  chosen before the first record is signed.

**For the build:**
- **Q2.** Whether the gate receipt records the obligation set's own digest
  (a ninth field), or deriving it from the commit is enough.
- **Q3, settled.** The statement builder lives in the signing workflow,
  under the existing `.github/workflows/` channel; not in `gate.yml`, whose
  later steps share the runner with what the engine left (§3.2).
- **Q4.** Whether the commission receipt gets its own predicate type, or
  only rides inside the gate statement as the gate reported it.
- **Q5.** Whether `epoch_absent` and `epoch_unreadable` stay one code each
  or split into the sentences they merge.
- **Q6.** The cosign `gitCommit` test, run by a session before the first
  signed record, if the scheme is one cosign verifies.
  The same run reads a live certificate's identity, which names the reusable
  signing file (§5).
- **Reused pushes.** On the CI path: sign the pull request's run receipt
  after the tree check, or leave reused commits unsigned (§3.2, "Which
  commits get a signed receipt"). The authority signs each landing's record,
  so the question takes another form there that #504 does not raise.

## 9. Sources

Repository, at main `78f0268`: `docs/direction.md` (§1, §4 rows 4, 10, 24,
§5 "Not before March", §6); `docs/2026-09-23-roadmap.md` (Phase 0b steps 14
and 15, Phase 2, Phase 4, §4); `docs/2026-09-19-direction-decisions.md` §4;
`README.md:429`; `engine/harness/lib/verify.sh`, `epoch.sh`,
`commission.sh`, `receipt.sh`, `escape.sh`; `engine/harness/felix`
(`cmd_gate`, `cmd_receipt`); `.github/workflows/gate.yml`;
`engine/.claude-plugin/plugin.json`; `engine/harness/lib/green-tick.sh`,
`bootstrap.sh`, `automerge.sh`; `docs/2026-08-15-authority-that-cannot-be-earned.md`;
`docs/2026-08-11-self-diagnosis-design.md`; `lib/pr-status-gh.sh`,
`lib/inventory-gh.sh`. The founder's ruling on the KMS key is his message of
2026-10-29 in the felix-cso channel, and his ruling on condition 3 and Q7 is
his message of 2026-10-31 there. The desktop session's review of 10-30
is the PR 476 comment of that date; its quotes from GitHub's OIDC
reference, reusable workflows guide and `workflow_run` section are as that
review read them.

Outside, read 2026-10-29:
- in-toto Statement v1: https://github.com/in-toto/attestation/blob/main/spec/v1/statement.md
- in-toto digest set: https://github.com/in-toto/attestation/blob/main/spec/v1/digest_set.md
- in-toto envelope: https://github.com/in-toto/attestation/blob/main/spec/v1/envelope.md
- in-toto attestation releases: https://github.com/in-toto/attestation/releases
- SLSA build provenance v1.2: https://slsa.dev/spec/v1.2/build-provenance
- cosign attest-blob: https://github.com/sigstore/cosign/blob/main/doc/cosign_attest-blob.md
- cosign verify-blob-attestation: https://github.com/sigstore/cosign/blob/main/doc/cosign_verify-blob-attestation.md
- cosign verifying: https://docs.sigstore.dev/cosign/verifying/verify/
- Fulcio overview (10 minute certificates): https://docs.sigstore.dev/fulcio/overview/
- Fulcio certificate issuing (CT log): https://docs.sigstore.dev/fulcio/certificate-issuing-overview/
- Fulcio OID extensions: https://github.com/sigstore/fulcio/blob/main/docs/oid-info.md
- Sigstore signing overview: https://docs.sigstore.dev/cosign/signing/overview/
- GitHub, using artifact attestations: https://docs.github.com/actions/security-guides/using-artifact-attestations-to-establish-provenance-for-builds
- GitHub, artifact attestations concepts: https://docs.github.com/en/actions/concepts/security/artifact-attestations
- GitHub OIDC reference (subject claims, customizing them): https://docs.github.com/de/actions/reference/security/oidc and https://docs.github.com/en/enterprise-server@3.8/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect
- GitHub, deployments and environments: https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments
- GitHub, events that trigger workflows: https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows
- IETF draft: https://datatracker.ietf.org/doc/draft-marques-asqav-compliance-receipts/
- agentattest: https://github.com/AuroraAeon/agentattest and https://github.com/BlockTarioIQ/agentattest
- agent-receipt: https://github.com/pramodreddyboddu/agent-receipt
- agentproof: https://github.com/PawanPatil19/agentproof and https://github.com/GenRamzi/AgentProof
- attested: https://github.com/Praxso/attested
- VeriForge: https://github.com/AdriaBA/veriforge-attest
- agentkey: https://github.com/mgillr/agentkey
- Traceseal: https://github.com/traceseal/traceseal-verify, https://pypi.org/project/traceseal-verify/ and https://traceseal.io/blog/in-toto-slsa-provenance-ai-agents/

Not confirmed: whether cosign's `--digestAlg` accepts `gitCommit` (Q6);
whether the OIDC subject template can be set on a private repository on
GitHub Free (read from a real token in March);
where AuroraAeon/agentattest keeps a producer's key; agentproof's predicate
type; VeriForge's license; whether Praxso/attested names DSSE; the draft's
full reference list. felix-home's plan (GitHub Free) is J's statement, not
read from GitHub.
