# Making promotion real — the specification for issue #2

Written 2026-08-18. This is a specification, not a decision. The decision was
taken on 2026-08-18 and is recorded in `HANDOFF.md` §0b and in the 2026-08-14
comment on [#2](https://github.com/LeavesJ/felix/issues/2); the ordering that
puts this first is `HANDOFF.md` §0c. None of that is re-argued here.

What this adds is the part that was missing: what to build, in what order, what
evidence each step owes, and the one experiment that has to run before any of it
lands.

Every empirical claim below was produced by a command in this session, not
carried over from the file that recorded it. Where a number differs from the
previously recorded one, both are shown.

---

## 1. The defect, stated as a property of the system rather than a bug

**Felix can be worked on in exactly one directory.**

The gate's `installed` check asks whether the engine in the tree you are
standing in is the engine deployed on this machine. Only one tree can ever
answer yes — the one the marketplace serves, because the felix marketplace is a
directory source pinned to a single path. `felix merge` requires a green gate.
So the command that ships work exists in one folder and nowhere else.

Everything that has been filed as a separate problem is that one property seen
from a different side:

- worktrees are a trap, and the workaround is an undocumented fact about
  marketplace registration;
- concurrent sessions are a hazard rather than a capability ([#31](https://github.com/LeavesJ/felix/issues/31));
- a peer session can review work but can never finish it;
- and the trust chain is violated structurally, because the only workflow
  available is `edit → felix install → gate → felix merge`, which deploys the
  candidate before it is judged. By merge time the candidate is the evaluator.

That last one is [#28](https://github.com/LeavesJ/felix/issues/28)'s clause 5
and `docs/2026-08-14-earned-autonomy-decision.md` §4a. It is why this is not a
convenience fix.

## 2. The change, in one line

`installed` stops asking

> is the engine you are holding deployed?

and asks

> is the deployed engine the one this project has accepted?

Every checkout can answer the second question. #2 dissolves rather than being
excused, and no gate is loosened to get there.

### Reproduced this session, in a live worktree

At `.claude/worktrees/youthful-lamarr-1c21f2`, sitting at `b47423d` while `main`
was `53b1f61`:

```
today's check   → FAIL   (live cache 0.49.6 vs this tree's engine/harness)
proposed check  → PASS   (main declares 0.49.6; cache 0.49.6 matches main's tree)
```

Real data, not a fixture. A previous session observed the same at `aaa60e3`.

## 3. It is a strengthening, and here is the sentence it strengthens

`engine/harness/lib/resolve.sh` currently disclaims, in prose, the assumption
the kernel rests on:

> the trust is that the cache entry for the base's version is what the base
> contained when somebody installed it

Nothing checks that. Under this change the gate checks exactly it, every run.
The disclaimer becomes a verified fact, and the gate certifies the precise
engine that `felix merge` uses as its judge. That is the loop closing.

## 4. Resolve **both** sides from the base — this is the blocker, not a detail

The first version of this design changed only the left side of the comparison
and inherited the right side from today's check: the *live* plugin, or the
newest cache entry. Those two disagree the moment anyone runs `felix install` on
a branch, which is what the current workflow demands.

The check would then have been **green if you skip the install and red if you
perform it** — a gate whose verdict depends on whether you did the thing it is
about to tell you to do.

So:

| side | resolve from | how |
|---|---|---|
| left | the base's engine content | `git archive <base> engine/harness` |
| right | the base's declared version | `felix_kernel_dir "$root" "$base"` |

`felix_kernel_dir` already computes the right side verbatim — it reads
`_felix_plugin_version` at `origin/<base>` or `<base>`, and resolves
`$FELIX_KERNEL_CACHE/<ver>/harness`. **Call it. Do not re-derive it.** Three of
the last four defects on this surface came from re-deriving something that
already existed with a subtlety in it, and this function carries two: the
`origin/<base>` fallback that made fixtures machine-independent, and the
`FELIX_KERNEL_CACHE` / `FELIX_PLUGIN_CACHE` collision that seven passing
assertions never exercised.

### Verified this session

```
main declares                               0.49.5   (before the day's merges)
git archive main engine/harness  vs  cache/0.49.5/harness
  contents                                  byte-identical
  modes                                     identical
cost (archive + extract + recursive diff)   ~81 ms
```

The previously recorded cost was 56–58 ms. Mine includes two `python3` startups
for the timestamps, so the real figure is at or below the earlier one. Either
way it is noise against a gate whose `tests` step takes minutes.

## 5. The lifecycle this implies

Today `felix install` deploys whatever tree it is standing in. If that tree is a
candidate, the chain is destroyed before the authority check ever executes. The
merge predicate from #2 therefore has a fourth line, and its position is the
point:

```
candidate C has valid exact-tree evidence              (candidate verification)
AND trusted V_n evaluated B → C for authority change   (base evaluation)
AND the base has not advanced since that evaluation    (staleness)
→ merge
→ THEN, and only then, promote C to trusted evaluator  (promotion)
```

Two evaluators, deliberately different. The candidate must be allowed to run its
own tests, its own gate and verifiers `V_n` has never heard of — otherwise Felix
could never introduce a new check. `V_n` performs only the non-delegable half:
*does this diff touch the transitive authority kernel?*

**Promotion becomes an explicit step that runs from an accepted base state.**
Not a side effect of standing in a directory. `felix install` on an unmerged
candidate must stop being the thing that makes the machine's engine change.

### Staleness binds to the tree, not the commit

`felix merge` squashes, so the merged commit SHA never matches the branch. The
**tree OID is identical** — verified across PRs #16–#19 previously, and again
today: after #49 squash-merged, `git diff --name-only main <branch>` reported no
difference outside the one file the stacked branch actually changed.

So "the content `V_n` authorised is the content that landed" is checkable with
`git rev-parse <ref>^{tree}`, and commit SHA is the wrong identity to bind a
verdict to. Anything in this work that records a verdict records a tree OID.

## 6. The blocking experiment — run 2026-08-18, and the answer is yes

**Question.** Will the plugin machinery move the live pointer *backwards* when
the cache already holds the base's version?

It had to be answered before anything here lands, because the whole design
assumes a machine can be returned to the engine `main` declares. Nothing pins a
version — the marketplace is a directory source and the version is read from the
served checkout — so demotion was *probably* `git checkout <base> &&
felix install`. Probably is not this project's standard; §0a of `HANDOFF.md`
lists three green-but-wrong states shipped in one week on exactly that reasoning.

**Answer: yes, and `claude plugin update` is what does it.**

Run against `claude` 2.1.226, in a throwaway `HOME` with a scratch clone
registered as the marketplace, so the machine under test was never modified:

| step | clone at | live pointer after |
|---|---|---|
| install | `0d9a436`, declares 0.49.4 | `…/cache/felix/felix/0.49.4` |
| `marketplace update` + `plugin update` | `53b1f61`, declares 0.49.6 | `…/0.49.6` — cache now holds both |
| `marketplace update` + `plugin update` | `0d9a436` again, 0.49.4 | **`…/0.49.4`** |

```
✔ Plugin "felix" updated from 0.49.6 to 0.49.4 for scope user.
```

Three findings, all of which the implementation depends on:

1. **`update` demotes; `install` does not.** On the way back, `claude plugin
   install` answered `already installed (scope: user)` and changed nothing.
   Only `update` moved the pointer. `felix install` runs both unconditionally,
   so it already has the working call — but anything written to demote
   deliberately must not rely on `install`.
2. **`marketplace update` first, or nothing happens.** A directory marketplace
   that is already registered does not re-read its manifest on `add`. This is
   the same refresh already commented in `cmd_install`, and it is load-bearing
   in the backwards direction too.
3. **The reused cache entry was correct.** The demoted `0.49.4` tree was
   `diff -rq` byte-identical to that commit's `engine/harness`. The cache did
   not serve a stale or rebuilt copy, which is the assumption §3 turns into a
   checked fact.

**Isolation verified rather than assumed.** `~/.claude/plugins/
known_marketplaces.json` had mtime `1787030873` before and after, the real cache
held 102 felix versions before and after, and the machine's live pointer stayed
at `0.49.6` throughout.

So `felix install` needs no new demotion path. That was the risk this experiment
was carrying, and it is retired.

## 7. What this does not fix, named so nobody assumes it did

Each of these is real, none is in scope, and leaving them unwritten is how a
partial kernel gets read as a whole one.

- **The check says nothing about which engine is *live*.** It certifies the
  cache entry for the base's version. Installing a candidate adds a *different*
  cache entry and moves the live pointer; it does not touch the entry being
  checked, so the gate stays green while the developer's own sessions run an
  unreviewed engine. This is acceptable for the thing the spec is for — `felix
  merge` judges through `felix_kernel_dir`, which reads the cache entry and not
  the live pointer, so the judge is right either way — but it is a real
  narrowing of what a green `installed` tells a human, and it should be said out
  loud rather than discovered. §8 criterion 2 is what keeps the original
  protection alive; if that assertion cannot be made to fail, this change drops
  a guarantee instead of relocating one.
- **`projects/felix/gate.sh` is promoted by nothing.** Every worktree runs the
  served checkout's *working copy* of it — dirty, on any branch — and it is the
  file that decides whether Felix's own merges are permitted. This is an
  authority-kernel hole and it is **larger than #2**. It should be filed and
  scheduled, not folded in here.
- **`evidence.tsv` gets no base-version treatment.** It is read off the branch
  that changes it, exactly as `risk.tsv` was before #42. It cannot demote a tier
  — the `^projects/[^/]+/(routes|profiles|stack|risk|evidence)\.tsv$` row floors
  any diff touching it at yellow — but `felix_merge_blockers` consults it for
  the evidence blocker, and there the candidate is still its own judge.
- **#28 clause 3 still has no home.** An unavoidable enforcement point needs a
  required status check, which needs a public repository or a paid plan. The
  repository is private and staying that way. Nothing in this spec changes that.
- **[#51](https://github.com/LeavesJ/felix/issues/51)**, filed today: a stacked
  branch is classified against a merge-base that squashing freezes. It fails
  safe, but it shares this spec's root cause — the squash — and the fix
  ("classify the tree a merge would produce") is the same object this spec binds
  verdicts to.

## 8. Acceptance criteria

Written as things that must be **shown failing first**, because clause 5 of the
constitution says a gate that cannot fail is not a gate, and because §0a records
three separate features whose suites were green while the feature was wrong.

1. In a worktree whose engine differs from the deployed one, `installed` is
   **ok**. Show it FAIL before the change.
2. On `main`, after a merge that changed `engine/harness` and before
   `felix install` has run, `installed` is **FAIL**. This is where the original
   "written is not installed" protection moves to, and it must be shown failing
   or that protection has been dropped rather than relocated. See §7 — this is
   the assertion the relocation stands or falls on.
3. Both sides resolve from the base: with `felix install` performed on the
   branch and with it skipped, the verdict is **the same**. This is the round-2
   blocker, and it is the one assertion that would have caught it.
4. A fixture whose cache entry for the base's version has been tampered with
   fails. Otherwise the check is asserting that two things it derived the same
   way are equal.
5. Every fixture pins `git init -b main`. `init.defaultBranch` made a previous
   version of this surface green on a laptop and red on a runner.
6. No assertion sets `FELIX_KERNEL_CACHE` unless it is testing that variable.
   Seven assertions passed over a collision because every one of them set it,
   and so none ever ran the default.

Criterion 3 is the one to write first. It is the only one that fails against the
design this spec replaces.

## 9. Order of work

1. ~~Run §6's experiment.~~ Done 2026-08-18; the answer is in §6 and it retires
   the demotion risk.
2. Write the assertions in §8, red. Criterion 3 first — it is the only one that
   fails against the design this spec replaces.
3. Change `installed` in `projects/felix/gate.sh` to resolve both sides through
   `felix_kernel_dir`. This is the whole gate change.
4. Green. Nothing about `felix install` needs to change: §6 established it
   already demotes.
5. Promotion as an explicit post-merge step. Separate change, separate review —
   it is inside the authority kernel by #28's clause 5, so it is the piece that
   least tolerates being bundled.

Step 3 classifies **yellow** — `gate.sh` matches
`^projects/[^/]+/gate\.sh$`. Step 5 classifies **red**, because promotion lives
under `engine/harness/lib/`. Neither is a green merge, so neither advances the
auto-merge streak, and step 5 needs a founder approval that step 3 does not.
