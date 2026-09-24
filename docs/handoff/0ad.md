## 0ad. Verified at session close, 2026-08-29 (late) — a defect found, and the instrument that nearly hid it

Each line produced by a command. Newest first under §0.

| | |
|---|---|
| head | `1810178` on `main`, CI `gate` **success** |
| deployed engine | **0.49.24**, matching `plugin.json` on `main` |
| suite | **882 assertions** across 874 manifest lines |
| governed projects | **three** — felix, elenchus, veldra; **two committed** (below) |
| open issues | **8**, unchanged |
| open PRs | **one** — this handoff, #95 |

**Nothing merged after §0ac except §0ac itself** (#94). This section covers one
investigation and no code change. It is here so the finding is not re-derived.

### The Stop hook names the wrong thing when a play is partly followed

`felix_route_skipped` is correct: given a play and a transcript it returns only
the steps that were *not* used. The defect is in the sentence the hook builds
from it — the sentence opens at `engine/harness/hooks/stop:189` and both
interpolations sit on `:190`:

> this session routed to work that asks for `${skipped}`, and the transcript
> shows `${skipped}` was never used.

The first `${skipped}` should be the **play**. Demonstrated under `bash`, with a
three-step play and two steps present in the transcript:

| | |
|---|---|
| the play asked for | `brainstorming writing-plans requesting-code-review` |
| genuinely skipped | `requesting-code-review` |
| the hook says the route asked for | `requesting-code-review` |

So the message is true about the skip and false about the route. It understates
the route to exactly the subset that was missed, which makes a partly-followed
play indistinguishable from a one-step play that was ignored outright — and the
message asks the reader to judge whether the skip was right, which is the one
judgement it has just removed the context for.

**A second half, which is design rather than a typo.** There is no
acknowledgement channel. The message asks for a sentence either way and nothing
records that one was given, so it fires identically at every close. A prompt
that cannot be answered gets read as furniture, and this one is asking for the
judgement most worth having.

**Not filed.** The founder redirected to a handoff before an issue was opened.
Both halves are grounded above; whoever files it does not need to re-derive them.

**It is not #29, and checking cost a minute.** #29 is that the play is wrong for
where the turn sits in the work — a routing question, answered by a notion of
turn shape. This is that the *message* misnames the play it is complaining
about, which is true even when #29 is fixed and the route is perfect. The
acknowledgement half sits nearer #29's orbit — that issue already observes such
complaints get skimmed — but its remedy is turn shape, not an answer channel.
File separately; do not fold it in.

### The instrument nearly manufactured a bigger, false defect

Worth more than the defect. My first two demonstrations reported **all three**
steps as skipped, including the two plainly present in the transcript. Read
literally that is a far worse bug — a hook that always complains about
everything — and it was wrong.

The cause, measured rather than guessed:

| | |
|---|---|
| my Bash tool runs | `/bin/zsh` — `for w in $P` splits into **1** word |
| the engine runs | `#!/usr/bin/env bash` — the same line splits into **3** |

zsh does not word-split unquoted parameter expansions. The whole play arrived as
one giant "step", matched nothing, and came back as entirely skipped. What caught
it was an inconsistency, not a re-read: per-step calls said *used* while the
aggregate said *skipped*, and two results that cannot both be true are worth more
than either result alone.

**This project already had this lesson written down** — `lessons.md` records a
play loop run under zsh reporting the whole play as one step. It did not prevent
the recurrence, and the reason is structural rather than a lapse: the lesson
lives in memory, the trap lives in the default shell of every ad-hoc command.
Any hand-run check of engine behaviour is executed by a *different interpreter
than the engine*, silently, every time.

**Standing, and cheap:** verify engine behaviour through `bash -c`, a `#!` script,
or the suite — never a bare tool snippet. A snippet is not running the engine's
language. This is the third instrument-error of the month after the broken
follow-through counter (§0z) and the eight assertions that passed for the wrong
reason (§0ac); **all three reported something false in the safe-sounding
direction.**

### The independence fix protects the committed set, not the governed set

§0ac recorded that project names are enumerated from `projects/` so mounting a
new project cannot quietly widen what the engine may say. Measured at this
close, that is true of the *checkout* and not of the *fleet*:

| | |
|---|---|
| `projects/` on disk | elenchus, felix, veldra, `widget` (an empty stray) |
| `projects/` on `origin/main` | elenchus, felix |
| therefore enumerated by CI | elenchus, felix |

`projects/veldra/` — 13 entries, including `project.json`, `CLAUDE.md`,
`gate.sh` and **seven** `.tsv` tables — has never been committed. So an engine
hard-coding **`veldra`** passes CI today, which is the exact failure §0ac
closed for `elenchus`. **Nothing leaks right now:** `veldra`, `elenchus` and
`widget` each appear **0 times** across `felix`, `lib/`, `hooks/` and `bin/`.
The hole is in the enumeration's reach, not in a live violation — which is
why it is easy to miss.

**And the enumeration reads directory names, not projects**
(`projects/felix/gate.sh:183`). `widget` is an empty directory and still
contributes a grep term. A stray named after a common word would fail the gate
with a confusing independence violation; an empty directory is an odd thing to
grant that power.

**Founder item, unchanged from §0ac and now with a measured consequence:**
commit `projects/veldra/`. Until then the fleet is three projects and the
enforcement covers two.

### Standing, carried forward

`engine/harness/tests/assertions.tsv` must be re-recorded by any change to
assertions — `tests/run --record-assertions`. Note it holds **874 lines and 882
assertions**; five lines carry more than one, so `wc -l` is the wrong instrument
for that number.

**Still not reviewed.** `/code-review b2af32c..6dfc9f6` — five PRs of red-tier
engine code merged with no review but my own. Unchanged from §0ac.

**The follow-through baseline is still not re-derived.**

