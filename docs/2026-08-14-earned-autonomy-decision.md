# Earned autonomy — the founder's decision on issue #5, and what it costs to build

Decided by the founder 2026-08-14, in response to issue #5. This file records the
decision, the two corrections the session pushed back with, and the ordering.
It is not a plan. Nothing below is built.

---

## 1. The decision

Neither "Felix stays manual" nor "red counts as green".

> Replace the green-only notion of trust with an earned harness-autonomy record.
> Successful RED Felix changes count as evidence of harness competence, while
> GREEN streaks continue to measure low-risk classification reliability.
> Autonomous self-maintenance becomes available once Felix demonstrates
> sufficient verification / repair / merge / recovery reliability. Changes that
> widen Felix's own authority remain behind a separate explicit auditable
> authority-change gate.

The reasoning, which is the part worth keeping: **Felix cannot earn autonomy
through the work required to become autonomous.** Its important changes live in
`engine/harness/lib/`, `risk.tsv` calls that red, and only green merges advance
the counter. For an ordinary governed project that is fine. For the Engineering
OS itself it is a bootstrap deadlock, and the incentive is backwards — a
docs typo scores and a verification-engine refactor does not, when the second
says far more about whether this system can run engineering.

This supersedes the framing in issue #5, which treated the problem as an edge
case in a five-PR counter. It is the first real design problem in Felix learning
to govern itself.

## 2. It fits v3, and v3 supplies the phrasing

v3.0's build order says each domain OS *"must earn autonomy using domain-specific
verification and evals"*. That is this decision, stated by the document a day
before the decision was made. Not "accumulate five green PRs" — earn autonomy
through observed performance of the harness at its own function.

For Felix that eval is: can this system repeatedly perform engineering changes,
verify them correctly, catch its own mistakes, repair failures, and respect
authority boundaries?

## 3. Two corrections, both from evidence in the session that recorded this

### 3.1 "Successful RED change" cannot mean "merged green"

On 2026-08-13 an adversarial audit of one day's work found eight defects that
survived independent refutation. **Four were introduced that same day**, by the
commits that were themselves fixing signals that misreport. Every one of them
merged with a green gate and passing CI.

A counter that scores a successful RED merge at merge time would have recorded
**+5 harness competence for a day that introduced 4 defects**. That is the same
shape as gate pass rate, which this project already rejected: a number that
improves for the wrong reason.

**So success needs a lag.** A RED change earns evidence only after it has
survived — no revert, and no later fix touching the lines it introduced, for
some window. A RED change that had to be repaired within a week is *negative*
evidence, not neutral. The machinery exists: `mistakes.log`, the fortnight
liveness window added 2026-08-13, and `git log -S` over the lines a later fix
touched.

### 3.2 Five of the eight proposed dimensions have no data

| Dimension | Measurable today? |
|---|---|
| Merge — the exact verified tree is what reaches main | **yes**, receipts are keyed on tree identity |
| Self-maintenance — Felix changes harness internals successfully | **yes**, with the lag from §3.1 |
| Verification — required evidence covers changed behaviour | **partly**, `evidence.tsv` says what is owed, not whether it covered anything |
| Classification — predicted risk agrees with observed consequences | **no.** Requires observed consequences. Nothing is deployed |
| Repair — Felix fixes failed checks without regressions | **no.** `unattended.yml` has run 3 times, every one skipped in under a second |
| Recovery — failures detected and reverted correctly | **no.** Never exercised |
| Security — privilege boundaries not crossed | **no.** No incidents to measure against |
| Production — telemetry confirms expected state | **no.** Sentry declared, unconfigured, nothing deployed |

Building all eight now produces five columns reading "no data" inside something
shaped like a measurement. That is the exact failure `felix ledger` had to be
corrected for: it claimed a zero "has no alternative explanation" when the zero
measured Felix's own priors, and the fix was recording `named` beside `calls`.

**Ship the dimensions that have data. Leave the others absent rather than
empty.** An absent dimension is honest; an empty one accumulates into something
that looks like a dataset and is a mirror.

## 4. The fixed point the decision needs and does not yet have

The authority-change gate answers: *may Felix merge a change that widens what
Felix may do?* It does not answer: *who decides whether a change widens it?*

If that detector lives in the engine, and Felix may change the engine, then a
change to the detector is itself authority-widening — and can hide itself. That
is circular authorization one level above the one the decision correctly catches.

Felix already has the shape of the answer. `disclose` and `verifier` are emitted
by `escape.sh` itself, not from any project's table, and no project may declare
them away. `authority_change` must be an engine constant of the same kind.

That is necessary and not sufficient. The decision needs one more clause:

> **A change to the authority-change detector escalates to the founder,
> permanently, and is never earnable.**

An invariant, not a policy. Without it the gate is decorative, because the first
thing sufficient autonomy could buy is the ability to stop the gate noticing.

## 5. `verifier` is already this gate, for one case

Worth knowing before designing the general mechanism, because it is proof the
pattern works rather than a hope that it will.

`escape.sh:165` emits `verifier` when a change *removes* from a file that decides
what stops — measured by counting assertion lines, declared per row in
`risk.tsv` as `count:^[[:space:]]*(ok|is|has|bad)`. That is exactly "a change
that weakens verification requirements" from the decision's own list. It is
shipped, it fires, and `felix merge` refuses on it.

The general mechanism is that idea widened from one pattern to a set, and moved
from a per-project column to an engine constant.

## 6. Path-based RED is transitional, and replacing it needs no engine change

The decision observes that `engine/harness/lib/* = RED` is too coarse for the
final architecture, and that files differ: `reporting.sh` is elevated but has no
authority; `escape.sh` and `deny.tsv` are where authority lives.

**`risk.tsv` already supports this.** Rows are path regexes carrying tier,
reason, `channel` and `confine`, so per-file rows can be written today with no
code change at all — `engine/harness/lib/escape\.sh$` can carry a channel that
`engine/harness/lib/monitor\.sh$` does not.

Deliberately not done in this session. It changes what stops, on the project
whose risk table decides what stops, and the right time to write those rows is
alongside the `authority_change` channel they would name — not before it exists.

## 7. Ordering, and the recommendation

**Gate before ledger.** Three reasons:

1. **Safety.** You cannot safely earn autonomy into a system that cannot tell
   when it is widening its own authority. The gate must exist before the first
   grant, not after.
2. **Buildability.** The gate is buildable now against a proven pattern. The
   ledger mostly is not: five of eight dimensions have no data, and the lag
   definition in §3.1 needs a window nobody has chosen.
3. **The gate is useful with no autonomy at all.** It refuses a circular
   authorization today, from a human at a keyboard, which is the situation Felix
   is actually in.

Proposed first `authority_change` pattern set, for the founder to accept, cut, or
extend. Each is a thing that changes what Felix is *permitted* to do, rather
than what it does:

| Pattern | Why |
|---|---|
| Removing or loosening a row in `risk.tsv` or `deny.tsv` | those tables decide what stops |
| Weakening a verifier | already `verifier`; folds in |
| Editing the channel constants in `escape.sh` | the list of things no project may declare away |
| Editing `felix_merge_blockers` | what a merge refuses on |
| Granting or widening an `autonomy` file | what may happen unattended |
| Editing the authority-change detector itself | §4 — permanent escalation, never earnable |

Everything else in `engine/harness/lib/` is ordinary engineering risk under the
existing tiers, and is exactly the work the decision wants Felix eventually able
to do on its own.

## 8. What is not decided

- The lag window in §3.1. A fortnight matches the recurrence window already in
  `felix_mem_recurring_mistakes`; nothing argues for that number beyond
  consistency.
- What "sufficient" means for each measurable dimension. Deliberately left open:
  choosing thresholds before there is any data is how a number gets picked to be
  reachable rather than to be meaningful.
- Whether GREEN streaks survive at all once the ledger exists, or become one
  dimension among several. The decision says they continue; §3.2 of the issue
  thread notes every green change Felix can produce is a document, so the
  dimension may be measuring nothing on this repository specifically.
