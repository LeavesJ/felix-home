## 0bk. Verified at session close, 2026-09-17 (night; 2026-09-18 UTC) — the judge is pinned outside the tree it judges, and a fixture that modelled the hole had to be rebuilt honest

| | |
|---|---|
| open | **#263** (red tier: `lib/resolve.sh`, the CLI's merge command, the suite's self-governing fixture, 0.49.122): gate green, CI green, refused by `felix merge` on the stale commission receipt alone, beside #262 |
| deployed | still **0.49.121**; 0.49.122 is carried in #263 and deploys after the founder's `felix commission`, the `felix merge` of #263, and a home pull plus `felix install` |
| suite | **2457 passed, 0 failed, 1 skipped**; 14 assertions authored blind, 13 on the self-governing fixture and 1 on the governed-product fixture |
| red.tsv | **10 of 2458** against `a8ab281` at 0.49.121; the four that hold there hold by design |
| closes | **#260**, found by the exception channel's reachability refuter the same day |

**What #260 was.** `felix_kernel_dir` returned `$FELIX_KERNEL` verbatim before
resolving anything, so a session could copy the harness, delete a channel
from its `escape.sh`, and run `FELIX_KERNEL=/tmp/k felix merge`: every
escape channel, the new `exception` one included, was evadable in one
variable. The variable existed so the suite could point at a constructed
kernel, and the suite never used it; every reference in the suite was an
`unset`.

**What closes it, and what does not.** The variable is gone from the
resolver and refused by name at the boundary before anything is judged. The
cache location is still composable — `FELIX_KERNEL_CACHE`, `FELIX_PLUGIN_CACHE`
— and what makes that safe is not the path but a comparison: the boundary
now asks `felix_accepted_deploy_diff` whether the entry it resolved is
byte-identical to main's engine at the base ref, the same question the
gate's `installed` check asks, and refuses any judge that is not. A cache
the session doctored does not match main and does not judge. The question
is asked through main's *own* `resolve.sh`, read out of the base commit and
sourced in a subshell, the fold's pattern from §0bi, so the code that
answers is code main accepted and nothing a candidate writes reaches it. A
successful merge names the judge on stdout and says it to `says.log`. The
understand phase's critic said what a flag could never do: a "judge chosen
by flag" note is written by the process that chose the judge and read by
nobody the session cannot also write; only the byte comparison, or a remote
reader, narrows anything.

**The fixture that modelled the hole.** The suite's self-governing fixture
gave its `main` a one-line stub for an engine while its kernel cache held a
real harness, so that the tree could not judge itself — which is exactly a
cache that differs from main, the thing the boundary now refuses, and seven
assertions went red. Its base is the real harness now, with an ignore file
mirroring the repository's so the residue the suite leaves in its harness
copy is residue here too; its "give main the real engine" step commits only
when there is a change, since an empty commit aborted the chain and the
prose branch it needed was never made; the pair that tested the reviewed
channel by rewriting the kernel's `review.sh` records a real verdict through
the real library instead; and two assertions that matched the substring
`identical` matched the new success line too, so they match the guard's own
phrase. One count-only assertion was made to print its reason, because that
is what found the empty commit.

**What the readers found.** An understand phase (two maps and a critic) and
the earlier refuter. The critic caught a defect the blind assertions could
not: the `judged by` line was the merge command's last statement behind a
short-circuit, so a product merge, which has no judge to name, would have
returned non-zero after merging. It is an `if` with an explicit return now.
The same critic named what this does not pin: the tables the judge applies
come from the home `FELIX_HOME` chooses, and `risk.tsv` gives the CLI and the
libraries a tier and no verifier confine, so a later branch deleting the
refusal sets no escape. What would go red are the ten assertions `red.tsv`
records failing against 0.49.121; the other four of the fourteen are controls
that hold without the fix.

**Next, in order.** The founder's first: `felix commission` in the home, which no session may run for him. After it a session merges #263 and #262, both green, and deploys 0.49.122 with a home pull and `felix install`. Then, unchanged from §0bj minus #260: the boundary reading the
home's diff so the exception channel reaches products; qualification
control 7 and the author column; #259 for the graph row. Branch protection on `main` stands as before.

