## 0ab. Verified at session close, 2026-08-28 — the backlog was verified, and a third of it was wrong

Each line produced by a command. Sections are ordered newest-first under §0;
`0ab` follows `0aa`, and the letters carry no other meaning.

| | |
|---|---|
| head | `45d627d` on `main`, CI `gate` **success** |
| deployed engine | **0.49.15** — `main` is at **0.49.19**, four behind |
| suite | **855 assertions** |
| open issues | **11** — five architecture/design, six filed today |
| open PRs | **none** |

**Start here, and it is still the same command.** Unchanged from §0aa and now
four versions stale, so #79 and #81 are on `main` and running nowhere.

```
cd /Users/a14808/Documents/Felix && git pull && ./engine/harness/felix install
```

### What merged

| | |
|---|---|
| #79 | three of the gate's seven checks sat outside the guard that protects it |
| #81 | `felix ready --fix` reported success for a run in which every repair failed |

### Both fixes were wrong the first time, in the issue I wrote myself

This is the part worth keeping. #77 proposed adding a `check <name>` marker line
so the confine would count it. **That does not work**, and it took a
counter-example rather than an argument to see why: a marker is a separate token
from the report, so it catches deleting a whole check block and leaves the
marker standing when only the reporting line goes — the smaller, likelier, more
deniable weakening, and the exact shape the issue described. What works is
making the reports *themselves* line-initial, so the counted token **is** the
thing whose removal matters. Count 9 → 15.

The same issue's exit-code model was wrong in both directions — exit 0 covers
three states, exit 1 covers four. Chasing that down is where #80 came from.

**The lesson generalises past both: an issue's proposed fix is a hypothesis, and
the fact that the same person wrote the diagnosis and the remedy is a reason to
test the remedy harder, not less.**

### The backlog was verified, and that is the headline

§0z's list carried six entries "found by the completeness critic, not yet
verified". Nobody had ever constructed them. Each one's failing input was built
and run, then independently re-verified by a second agent that rebuilt the
fixture rather than re-running the first.

**Two of the six died.** `felix repair`'s red-path guard is reachable and
harmless — the skip changes nothing. The `budget ceiling` box prints the
*ceiling*, not the remaining, so its constant `[x]` asserts a fact that
genuinely is constant, and the commit that added it says exactly that.

Six candidates died the same way in the original sweep. **That ratio holding is
the evidence the method works rather than manufactures findings**, and it is the
reason to keep paying for it.

A rule fell out of the second one, and it is now in `lessons.md`: **a constant
is only a defect when the fact it asserts is not constant.** The two literal
`[x]` rows in `felix unattended` sit side by side; one states a structural bound
that cannot vary and is correct as written, the other asserts a property of a
table that may not exist.

### Filed, in severity order

| | |
|---|---|
| #83 `risk-red` | `subagent-stop` misses committed work **and** over-fires on Felix's own bookkeeping — wrong in both directions, one root cause. `stop` already solved this for itself and the fix was never carried across |
| #84 `risk-red` | `felix budget --record` ignores a failed append, so `used` stays 0 forever and the unattended ceiling silently becomes no ceiling — the failure `budget.sh`'s own header warns about |
| #82 | `installed` compares `harness/` only, so a `hooks.json` that never deployed reads as `installed ok`. A hook binary can deploy perfectly and run nowhere |
| #85 | `independence` greps one literal over three paths, and the gate **executes** a file it does not search |
| #86 | `installed` counts untracked strays as drift; in a worktree the message is a wrong diagnosis **with its own evidence suppressed** |
| #87 | `felix unattended`'s scope-bound box is checked by construction |

**#83 and #84 are the two to take first.** Both are red, and both have either a
known-good sibling implementation to copy or a documented invariant to restore,
so neither needs a design decision first.

### Corrections that would have sent fixes the wrong way

Recorded because each was a plausible reading that the construction refuted, and
acting on any of them would have made things worse:

- The plugin has **two** undiffed directories, not four. `engine/agents/` does
  not exist and is not tracked.
- **Do not widen the `installed` diff to `engine/`.** `.claude-plugin/plugin.json`
  legitimately differs whenever a bump is pending, which is this tree's normal
  state. The correct scope is `harness/ + hooks/ + commands/`.
- The third `diff -rq` site, the merge-time self-judgement guard, is
  deliberately harness-only and must be left alone.
- `engine/harness/.claude-flow/` **does not exist**. The stray defect is latent
  and reachable, not currently firing, and #57 asserted it in the present tense.

### Two findings nobody was looking for

Both surfaced from agents in the middle of *refuting* a different claim, which
is an argument for adversarial verification producing more than it removes: the
`subagent-stop` over-fire, and the `budget --record` silent failure. Neither was
on any list.

### Standing, unchanged from §0aa

`engine/harness/tests/assertions.tsv` must be re-recorded by any change that
adds or removes assertions — `tests/run --record-assertions`.

**The follow-through baseline is still not re-derived.** No number before it is.

