# Felix receipts as in-toto statements: a mapping for March

**Status.** March prep, and a document only. Nothing in it is built, keyed or
signed before March. `docs/direction.md` §5 lists "DSSE receipts" under "Not
before March", and roadmap §4 (`docs/2026-09-23-roadmap.md`, line 371) defers
"DSSE or in-toto receipts (and never a key on the enforcing path)". Building or
signing earlier would be a direction change, and that change is the founder's.
This file proposes a shape for review; it decides nothing.

Read at main `78f0268` (0.49.308, 2026-10-29). Every engine path below is at
that commit. Outside sources were read on 2026-10-29 and are listed in §9.

## 0. The short version

- Felix already writes two receipts: the gate receipt and the commission
  receipt. Both already go stale when something they depend on moves. This
  document maps them into an in-toto Statement v1, in a DSSE envelope, with a
  Felix predicate. It invents no new proof record.
- Signed, commit-bound receipts are not Felix's own. What is Felix's own is a
  receipt that names what its verdict rests on, so a reader can tell when it
  has gone stale. The predicate is built around that.
- Signing happens in CI, keyless, with a certificate Fulcio issues for 10
  minutes from the workflow's OIDC token. No key exists anywhere an agent
  runs, and none exists on the enforcing path.
- felix-home is private on GitHub Free. Keyless signing on the public Sigstore
  instance would publish its identity, so felix-home gets no signed receipts
  on public infrastructure. Public repositories, starting with the Phase 4
  replay repository, are the first that would.
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

`felix_receipt` (`engine/harness/lib/receipt.sh:91`), printed by `felix
receipt` (`felix:4099`). JSON with `schema: "felix.receipt/1"`, a `status` of
`verified`, `unverified`, `blocked` or `indeterminate`, an `unknown` list, a
`verification.state` of `none`, `stale` or `current` read through
`felix_verify_current`, risk, evidence, authority, and a `limits` object
(`receipt.sh:269`). Its rule, "a receipt may not claim more than it knows",
carries straight into the predicate below.

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
when a dependency changes". A signature cannot go stale; it is valid forever
over the bytes it covers. So staleness has to live in the statement as data:
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
| `tree.gitTree`, `tree.clean` | `git rev-parse HEAD^{tree}` | `gate.yml` already prints this as the "gated tree" notice. On a clean CI checkout the tree id is a function of the commit alone, so `clean: true` is what lets a verifier trust `gitCommit` as the thing judged. A Mac receipt over uncommitted edits is never signed (§3). |
| `checks.reported`, `checks.skipped` | gate fields 6 and 5 | Split from `name:verdict` pairs. Their limit travels with them: a check that runs without printing a line is not here (`verify.sh` comment above `felix_verify_record`). |
| `obligationSet.policyVersion` | component 3 | Covers all twelve tables at once. |
| `obligationSet.obligations.digest.gitBlob` | `git rev-parse <commit>:projects/<p>/obligations.tsv` | Not recorded today: the obligation set is folded into the policy hash. Derivable from the commit, so a verifier with the repository can check it. See open question Q2. |
| `epoch.*` | gate fields 7 and 8 | As written. |
| `judge.pinned`, `judge.pin` | nothing yet | Roadmap Phase 0b step 14 (the judge-identity epoch) and step 15 (the judge pinned outside the change it judges) are not built. Until they are, `pinned` is `false` and `pin` is `null`, and a verifier must read that as "this gate was judged by the engine in the change". |
| `judge.engineCommit` | the engine commit CI ran | An interim provenance fact, not a pin. On felix-home it equals the subject commit, which is exactly the self-judging case the pin exists to end. |
| `commission.*` | the gate's `commission` line and component 3 | The commission receipt is per machine. A CI runner has none, so the CI statement carries what the gate reported, not a Mac's receipt. See Q4. |
| `staleWhen` | `felix_verify_current` and `felix_commission_receipt_valid` | Canonical snake_case codes for the reasons those functions print today as sentences. See §2.5. |
| `limits` | `receipt.sh:269`, plus one line | The first two are carried verbatim from `felix.receipt/1`. |

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
signed: in March they get a test for the mapping from each sentence and a
test that the set does not drift.

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

**Nowhere Felix or an agent runs.** No private key is created, stored or
read by Felix. Signing is keyless: a CI job asks GitHub for its OIDC token,
Fulcio exchanges it for an X.509 certificate valid for 10 minutes (Sigstore,
"Fulcio signs X.509 certificates valid for 10 minutes"), the job signs the
DSSE envelope with an ephemeral key that never leaves that job, and the key
is discarded.

**Never on a Mac where agents run.** Receipts written on the laptop stay
unsigned, whatever they say. A Mac receipt can be over uncommitted edits, and
anything on that machine is reachable by the sessions running there.
Roadmap §4's "never a key on the enforcing path" is kept by having no key at
all on any machine that enforces.

**The exact step.** In March, one new job in `.github/workflows/gate.yml`:
- named `sign`, with `needs: gate`;
- runs only on `push` to `main`, never on `pull_request`, so no unlanded
  code ever runs beside an OIDC token;
- holds `permissions: { contents: read, id-token: write }` and nothing else;
- runs only after the `gate` job passed on the exact commit, and refuses
  (fails closed) when the `reuse` job stood on an earlier run's tree, because
  then this run's gate produced no receipt;
- reads the gate receipt the `gate` job uploaded as an artifact, builds the
  Statement, and signs it with `cosign attest-blob --statement <file>
  --bundle <file>` (cosign's `--statement` takes a prebuilt statement, which
  `--predicate` does not allow, since our subject is a commit and not a
  file);
- publishes the bundle as an artifact of that run (and, for a public
  repository, the transparency log entry with it).

What an agent can and cannot reach:

| | Can reach | Cannot reach |
|---|---|---|
| Session on the Mac | the gate receipt in `state/gate/`, every engine file, any branch it pushes | any signing key (none exists); the OIDC token (minted only inside the `sign` job on GitHub's runner) |
| A pull request it opens | the `gate` job, which runs its code with `contents: read` only | the `sign` job, which never runs on `pull_request` |
| Code it lands on main | what the next `sign` job signs, because that job runs main's engine to build the statement | the workflow file: `.github/workflows/` is an unconditional escape channel (`engine/harness/lib/escape.sh:116`, `FELIX_ESCAPE_EXECUTE`), so a change to the `sign` job waits for the founder |

The third row is the real exposure. Land on green lands engine PRs,
judge-changing ones included (direction row 24). An agent that lands a change
to the gate or to the statement builder changes what gets signed, and the
signature will be perfectly valid. That is why `judge.pinned` exists, and
why the statement builder in March should live inside the workflow file or
under an escape path, not in ordinary engine code (Q3).

## 4. Private repositories

**felix-home.** Private since 10-24 (`docs/direction.md` §6), on GitHub Free
(J, 10-29). Three facts decide it:
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

| Repository | Receipts | How |
|---|---|---|
| A public repository Felix governs, first the Phase 4 public replay repository (roadmap Phase 4) | Signed | Keyless on the public Sigstore instance, logged in Rekor. Its identity is public already. |
| felix-home | Unsigned | Never on public Sigstore. Signed only if a private path below is chosen, which is a cost and a direction call (Q1). |
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
  log. This is a key, but not one on any enforcing path or any agent's
  machine; whether it still breaks roadmap §4's wording is Q1.

## 5. Verification

For a public repository, the buyer runs:

```sh
cosign verify-blob-attestation \
  --bundle felix-receipt.sigstore.json \
  --type '<FELIX_PREDICATE_BASE>/gate-receipt/v0' \
  --certificate-identity 'https://github.com/OWNER/REPO/.github/workflows/gate.yml@refs/heads/main' \
  --certificate-oidc-issuer 'https://token.actions.githubusercontent.com' \
  --certificate-github-workflow-repository 'OWNER/REPO' \
  --certificate-github-workflow-trigger push \
  --digest "$(git rev-parse HEAD)" --digestAlg gitCommit
```

`--digest` and `--digestAlg` check the statement's subject against a digest
"instead of providing a blob" (cosign docs). Whether cosign accepts
`gitCommit` as the algorithm name is not confirmed; if it does not, the
fallback is `--check-claims=false` (which, per cosign, verifies "only the
DSSE envelope") followed by a `jq` check that `subject[0].digest.gitCommit`
equals the commit. Testing that is the first March task (Q6). Then, for
staleness, `felix receipt verify` (not built) would recompute what §2.6 says
can be recomputed and print the `staleWhen` codes that fire.

For a private repository on Enterprise Cloud, `gh attestation verify` with
`--predicate-type` and `-R OWNER/REPO`, if GitHub's tooling accepts a commit
subject; else the same cosign command against GitHub's trusted root (Q6).

**What a passing check proves:**
- this exact statement was signed by a certificate Fulcio issued to the
  `gate.yml` workflow on `main` of that repository, for a `push`;
- the statement names that commit;
- for a public repository, the signing was logged in Rekor at a time inside
  the certificate's 10 minutes.

**What it does not prove:**
- that the gate was the right gate. The signer is the workflow, and the
  workflow ran whatever engine was on main. `judge.pinned: false` says this
  in the statement itself.
- that the obligations were the right obligations, or complete. Admission
  is a person's act (direction §3), and the 10-27 snapshot there counts 0 of
  22 candidates admitted.
- that the receipt is still current. The signature is permanent; staleness
  needs the recomputation in §2.6, and part of it (topology) cannot be
  recomputed by a buyer at all.
- anything about controls, policies or an audit framework. Felix makes no
  compliance claim from these receipts until a buyer asks for one.

## 6. The landscape

in-toto Statement v1 in a DSSE envelope is the most common choice among the
projects that sign agent receipts. It is not a settled standard for them: no
standards body has adopted an agent receipt format, and every project below is
young and small. Star counts were read on the repository pages on 2026-10-29.

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

## 7. What this asks of March

Nothing before March. In March, in this order, each as its own change:
1. Q6 settled by a test: does cosign verify a `gitCommit` subject.
2. The stale codes of §2.5 as a contract, with the mapping and drift tests.
3. The predicate, written from the gate receipt by a builder that lives
   under an escape path (Q3).
4. The `sign` job, as a draft labelled `needs-founder` (it touches
   `.github/workflows/`).
5. The first signed receipt on the public replay repository, verified by the
   §5 command from a clean machine.

## 8. Open questions only J can answer

- **Q1.** Does a cloud KMS key reached only by CI's OIDC identity count as "a
  key on the enforcing path"? And is a private signing path for felix-home
  wanted at all before a customer asks?
- **Q2.** Should the gate receipt record the obligation set's own digest
  (a ninth field), or is deriving it from the commit enough?
- **Q3.** Where the statement builder lives: inside `gate.yml` (founder
  stop, simple), or a new escape path in `risk.tsv`.
- **Q4.** Does the commission receipt get its own predicate type, or only
  ride inside the gate statement as the gate reported it?
- **Q5.** Whether `epoch_absent` and `epoch_unreadable` stay one code each or
  split into the sentences they merge.
- **Q6.** Not his to answer, but on his machine: the cosign `gitCommit`
  test, run by the desktop session in March. The same run confirms the
  certificate identity string in §5, which this doc takes from the GitHub
  workflow ref form and did not read on a live certificate.
- **Q7.** The predicate type URI. It needs a stable base Felix controls;
  this doc writes `<FELIX_PREDICATE_BASE>` rather than name a domain.

## 9. Sources

Repository, at main `78f0268`: `docs/direction.md` (§1, §4 rows 4, 10, 24,
§5 "Not before March", §6); `docs/2026-09-23-roadmap.md` (Phase 0b steps 14
and 15, Phase 2, Phase 4, §4); `docs/2026-09-19-direction-decisions.md` §4;
`README.md:429`; `engine/harness/lib/verify.sh`, `epoch.sh`,
`commission.sh`, `receipt.sh`, `escape.sh`; `engine/harness/felix`
(`cmd_gate`, `cmd_receipt`); `.github/workflows/gate.yml`;
`engine/.claude-plugin/plugin.json`.

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
- IETF draft: https://datatracker.ietf.org/doc/draft-marques-asqav-compliance-receipts/
- agentattest: https://github.com/AuroraAeon/agentattest and https://github.com/BlockTarioIQ/agentattest
- agent-receipt: https://github.com/pramodreddyboddu/agent-receipt
- agentproof: https://github.com/PawanPatil19/agentproof and https://github.com/GenRamzi/AgentProof
- attested: https://github.com/Praxso/attested
- VeriForge: https://github.com/AdriaBA/veriforge-attest
- agentkey: https://github.com/mgillr/agentkey
- Traceseal: https://github.com/traceseal/traceseal-verify, https://pypi.org/project/traceseal-verify/ and https://traceseal.io/blog/in-toto-slsa-provenance-ai-agents/

Not confirmed: whether cosign's `--digestAlg` accepts `gitCommit` (Q6);
where AuroraAeon/agentattest keeps a producer's key; agentproof's predicate
type; VeriForge's license; whether Praxso/attested names DSSE; the draft's
full reference list. felix-home's plan (GitHub Free) is J's statement, not
read from GitHub.
