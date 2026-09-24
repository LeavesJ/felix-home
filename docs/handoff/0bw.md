### 0bw. 2026-09-23 — building Felix, measured as Felix's own workload; direction-level documents wait for the founder

**Nothing deployed from this session; no engine change.** The founder's point:
the founder brings an idea, sharpens it and judges it, the agent does the rest,
and that exchange is the model for how Felix works with every user. So the
history of building Felix is a record of that whole pipeline, from intent
through the work in between and the delivery to the outcome.

| PR | What |
|---|---|
| #316 | The episode pilot. Twenty episodes, weighted to the big decisions, reconstructed from the transcripts with each record checked and the report critiqued: `docs/2026-09-23-episode-pilot.md`, data and method in `docs/episodes/`. |
| #319 | **DECIDED by the founder.** Documents that change what Felix is, who it is for or its build order wait for his yes, and he rates each delivery in one word. Nothing else waits. Written into the split in `projects/felix/CLAUDE.md`. |
| #327 | Batch 2: the five episodes the pilot missed, plus two control sessions, with a second blind reader per turn: `docs/2026-09-23-episode-batch-2.md`. The prompt index and transcript reader now tell the founder apart from notifications and other sessions. |

**What the harvest found, briefly.**
- About a third of the founder's effort went into the agent's job. The pilot's
  figure is 31% by strict majority, but on turns both batches read the rate
  runs 42 to 49%. Selection moves the figure more than the counting rule does,
  so state both beside any rate.
- The largest kinds are needless stops, restated decisions and answering
  questions the agent should have decided. Report them as shares, with their
  label splits.
- The two readers agreed on 70% of labels. Their most common split was "go":
  an approval, or a push past a stop that should not have happened.
- The agent originated 60 decisions across batch 2's records. Several became
  the founder's chores: a twelve-table hash under the commission receipt and
  grant, per-project overnight state, and "the commission run is his".
- The new thing is checks fired at moments, not advice: pilot §7 as amended by
  batch 2 §6.

**Waiting on the founder.**
- The one direction-level question in batch 2 §8: status in the end-of-session
  notice, with the monitor kept as the deeper page.
- Carried from §0bv: the Elenchus and Veldra candidates' admission, then #310's
  verifier escape, then #304 (all open on 2026-09-23).

**Next, Felix's to do (none needs the founder):**
- **Capture.**
  - `says.log` keeps whole prompts, or a pointer to the transcript line.
  - Question-tool answers are indexed.
  - `escalated` rows carry the session id (`felix:1441`) and are not written
    on `--dry-run`.
- **#319 has no mechanism yet.** Build a merge stop on roadmap paths and the
  charter's split section only, and never on an engineering path.
- **The interaction layer's first moments.**
  - The Stop hook reads the closing report for work handed back, and for
    "next is X" when X is approved work.
  - An `asked` row per question.
  - A decisions table with the originator, whether the owner was asked, and
    the owner cost stated at the time.
- **Lessons-ladder fixes (batch 2 §6).**
  - Mount the full headline, not the bare date (132 of 181 entries mount as a
    date).
  - Match on the prompt, not the envelope.
  - Give `mistakes.log` rows a session id.
  - `projects/felix/CLAUDE.md:160-163` and `felix:930` describe the ladder
    wrongly.
- **The next episode batch.** Apply the four codebook rules in batch 2 §4 first,
  and sample every session in a fixed week rather than choosing episodes.
- **Carried from §0bv.**
  - Control 7 after #310.
  - The request that names a gitignored doctrine.
  - #308, #309 and #311 (deny scope) and #312 (README), all still open.

**Traps paid for this session:**
- **A docs-only branch passes the gate only while its engine equals
  `refs/remotes/origin/main`.** Worktrees share that ref, and other sessions
  fetch it mid-run. Merge main, check
  `git diff --quiet refs/remotes/origin/main -- :/engine`, and gate at once.
  Two gates failed on this before the third passed.
- **Any `*.tsv` in the tree needs a `schemas.tsv` row, or `schema-check` fails
  the gate.** Put data in as JSONL.
- **At a load average of 100 to 140 the suite took over an hour, not ten
  minutes.** Watch your own gate's PID: a watch keyed on "any `felix gate`"
  never fires while other sessions are gating.
- **A workflow dies with the session process.** Resuming it with the same
  arguments re-ran finished stages under new cache keys. The first run's
  `journal.jsonl` already held every result, so finish from the journal.
- **The transcript reader printed task notifications and other sessions'
  messages as FOUNDER,** and the old prompt index counted peer messages as
  founder prompts. Both are fixed. The pilot, re-checked, holds no peer turns.
- **The fact gate refuses a force-push whatever facts are given.** Add a commit
  instead of amending.
- **A plain `cd` into `docs/episodes` in one Bash call moved the working
  directory for the calls after it.** Use absolute paths.
