## 0ac. Verified at session close, 2026-08-29 — a second project, and what it broke the same day

Each line produced by a command. Newest first under §0.

| | |
|---|---|
| head | `6dfc9f6` on `main`, CI `gate` **success** |
| deployed engine | **0.49.24**, byte-identical to `main` — gate `installed ok` |
| suite | **882 assertions**, from 855 |
| governed projects | **three** — felix, elenchus, and **veldra** (`LeavesJ/ReserveGrid-OS`) |
| open issues | **8** — five architecture/design, three yellow |
| open PRs | **none** |

**No outstanding action.** The deploy is current for the first time at a session
close, and the gate is green.

### What merged

| | |
|---|---|
| #89 | `subagent-stop` was wrong in BOTH directions, from one raw dirtiness test |
| #90 | a budget spend that was never written reported itself as recorded |
| #91 | three shells could overrun the only ceiling on unattended model runs |
| #92 | the engine could name a governed project and the gate said ok |
| #93 | the readiness checklist manufactured the evidence for its own switch-on |

### Mounting veldra broke invariant 1 the same afternoon

The `independence` check grepped one hard-coded literal, `elenchus`. Invariant 1
— the first in the constitution — says *the engine names no project*. Demonstrated
against the real gate: an engine hard-coding **`veldra`**, a project Felix now
actually governs, **passed**; the identical edit naming `elenchus` failed.

Names are enumerated from `projects/` now, so mounting something new cannot
quietly widen what the engine may say. The engine's own name is the one
exemption and the suite asserts it is the only one — measured, `felix` appears
about 1450 times in runtime code because it is the product, the prefix and the
binary. `bin/` is searched now; the gate *executes* it, and the literal the
check was written for could sit in `bin/secret-scan` and pass.

**The general lesson, which is not about this check.** A rule enforced by
grepping one member of a set stops enforcing the moment the set grows, and it
does so silently and on somebody else's schedule. Enumerate the set.

### DECIDED 2026-08-29 — the unattended budget is deferred, and the loop stays off

Recorded so nobody re-derives it. #84's two mechanical halves are fixed (#90,
#91). The remaining half — the ceiling cannot bind in CI — is **deliberately not
fixed**.

**The obvious fix was rejected on its blast radius.** Giving `FELIX_DEPLOY_KEY`
write access would let an Actions job on a *product* repo push to the *engine
and doctrine* repo. It cannot be constrained: branch protection on this
repository returns `403 — Upgrade to GitHub Pro`. A compromised run on one
product could rewrite the engine governing all three. Adjacent to #28.

**The loop has never been on.** `FELIX_UNATTENDED` is unset on Elenchus, the
only repo carrying `unattended repair`; veldra has no Felix workflow at all. A
ceiling that does not bind costs nothing while nothing runs.

**If it is ever wanted, the design is settled and needs no new credential:** an
append-only ledger on `refs/felix/budget` in the governed repo, using the
`contents: write` the workflow already has. A ref push is atomic and fails on
non-fast-forward, which is the compare-and-swap this needs. One thing to confirm
first: that `GITHUB_TOKEN` can push a non-branch ref.

**And a precondition that has nothing to do with budgets**, in the workflow's own
words: *"The rules deciding what is in scope were written in one sitting and
have never been tested against a real failure."*

### An append-only ledger can be its own compare-and-swap

`cmd_budget` was check-then-act with no lock. Reproduced on one machine, no CI:
seeded at 9 of 10, three concurrent callers, **all three recorded**, ledger at 12.

Fixed without a lock — a lock needs a staleness rule, and a lock that can be
broken can be raced. Append first, decide after, and the ledger's own length is
the serialisation point. A race loser sees a ledger at least as large as it
read, so it can only refuse *sooner*. **Over-spending is unreachable;
over-refusing is not**, which is the asymmetry invariant 3 asks for. Measured
with five racers against one slot: once one recorded with the ledger exactly at
the ceiling, twice nobody did.

It only became visible because #90 replaced `used + 1` with a re-read. The
arithmetic printed `10 of 10` three times and the ledger looked exactly full.

### A third mark, and when a constant is not a defect

`felix unattended` had two `printf` constants among five readiness rows. `scope
bound` was simply wrong — checked for a project declaring no red path at all.

`budget ceiling` is the interesting one. Its `[x]` was **not wrong about what it
said**: a ceiling is configured, and an adversarial pass correctly refuted it as
a defect on those terms. But readiness means the bound *holds*, and Felix cannot
determine that — the deciding fact is whether the filesystem is ephemeral, which
neither git nor bash can answer. So it gets `[?]`, and the report explains the
mark. **Marking it either way would be a claim it has not earned.**

That is the second time this month the answer was a third state rather than a
better guess, after `unknown` in the receipt and the escape scan.

### What I got wrong, and how

Recorded because the pattern is consistent and worth watching for.

**I mis-diagnosed my own issue.** #84 said "the append is unchecked". It was
not — a failed redirection already returns non-zero, in a function too. I added
a `|| return 1`, reverse-tested, found removing it changed nothing, and checked
the shell rather than assuming my fix had worked. The status was always there;
**the caller discarded it.**

**Eight of my own assertions passed for the wrong reason** across five PRs, each
caught by reverse-testing rather than by reading: a glob spanning a whole report
so `[x] api key` satisfied a check about a different row; two matching an error
message because a fixture had no git remote; a `sed` range that matched nothing,
letting an empty string satisfy a `case`; one satisfied by an unrelated line in
the *secret* check. **An assertion that passes before the fix is the defect this
project keeps finding, and writing them does not confer immunity.**

**A fixture subtlety worth keeping:** directory permissions gate *creation*, not
appends to a file that already exists. `chmod 555` on a directory with the log
still present leaves the append perfectly writable.

### Standing

`engine/harness/tests/assertions.tsv` must be re-recorded by any change to
assertions — `tests/run --record-assertions`.

**The follow-through baseline is still not re-derived.** No number before it is.

**Not reviewed.** Five PRs of red-tier engine code merged this session with no
review but my own. The adversarial workflows reviewed the *analysis*; nothing
read the *diffs*. `/code-review b2af32c..6dfc9f6` is the outstanding gap.

