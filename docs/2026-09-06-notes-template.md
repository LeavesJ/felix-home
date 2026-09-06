# NOTES.md, template

Copy this to `~/handover/NOTES.md` and fill it in. It is the only file in the
bundle nobody but you can write.

```
cp ~/felix/docs/2026-09-06-notes-template.md ~/handover/NOTES.md
```

Everything Riyan needs that is *derivable* is already written down. The
environment is in `ENVIRONMENT.md`, the doctrine and the traps are in the
onboarding document, the lesson numbers resolve in `docs/lessons.md`, and the
reasoning behind every shaped decision is in `docs/DEVLOG.md`. What none of
those hold is the state of the work on the day you stopped being the person
doing it. That is this file, and it goes stale within a week, which is fine.

Delete every prompt line as you answer it. Delete whole sections that do not
apply. A short honest NOTES.md beats a complete-looking one.

---

## 1. Where the beta actually stands

**Settle this first, because two documents currently imply different things.**
`2026-09-06-riyan-onboarding.md:27` tells Riyan the status is "a closed beta,
one invited person per instance, from 2026-09-05". You told me on 2026-09-06
that nobody has been invited yet. Both can be true, if the infrastructure went
live on the 5th and no invite has gone out, but Riyan cannot tell that from
what he has. Write the real sentence here and I will correct the onboarding
document to match.

- How many people have been invited, and how many have actually sat down?
- Is anything serving right now? Is a tunnel up?
- What is the next thing that has to happen for the beta to move.

Riyan operates none of this and that is D2. He still needs to know it, because
almost every fragile thing in the codebase is fragile *because* of it.

## 2. What you were part way through

The last thing merged was `dd99ba0`, "Beta hardening: three territories, spend
ceiling, preflight, forget, and the deploy fixes". So that is where the public
record stops.

- What is half-built, on a branch or in your head, that is not in that commit?
- What did you have opinions about that never got written down anywhere?
- Is there a branch he should know exists?

## 3. What you would have him do first

Not a backlog. The one or two things you would pick up on Monday if nothing had
changed, and why those and not something else.

## 4. What you would not touch yet, and why

Some candidates, so this is a review rather than a blank page. Delete the ones
that are wrong and add the ones I do not know about.

- `src/elenchus/web/runtime.py`. The two-instance isolation guard. Its own
  docstring says a misconfiguration here is a privacy incident rather than a
  degraded experience.
- `src/elenchus/web/app.py:14`, `_SID = "single"`. Correct only while one
  database holds one person. A lot rests on that being true.
- `src/elenchus/spend.py`. The ceiling that keeps a loop from spending until
  someone notices.
- The injection probe and its grader, if the payload corpus is in his bundle.
- Anything that touches the tunnel or Cloudflare Access. That is yours entirely.

For each: is it fragile, is it load-bearing, or is it just unfinished? Those
want different behaviour from him.

## 5. What you already tried that did not work

The highest value section and the easiest to skip. Anything he would plausibly
attempt, that you have already attempted, that failed for a reason that is not
obvious from the code. Save him the week.

## 6. Decisions still open

These are the ones I know are open as of 2026-09-06. Say what you want done
about each, or say "ask me".

- **`.env.example`.** Whether one gets added to the public repo. It changes the
  tracked set, which your own doctrine puts at T3. `ENVIRONMENT.md` covers the
  same ground for him today without touching the repository.
- **`docs/admissions/`.** Held back by default. You said you would open a couple
  and decide. Did you.
- **The beta timeline.** Does it stay yours indefinitely, or is there a date.
- **Write access to the gate contract.** He reads `projects/elenchus/` in the
  felix clone. Does he ever get to change it, and through what.
- **`data/injection_payloads.yaml`.** In his bundle or not. If yes, say in the
  same message what it is.

## 7. People and context

Anything about partners, advisors, the incorporation, YC, or anyone whose name
he will encounter, that he should not learn by accident or by asking the wrong
person.

Keep this short and keep it to what affects his work. This is the section most
likely to contain something you would not want forwarded.

## 8. How to reach you, and for what

- What he should decide alone.
- What he should tell you about after the fact.
- What he should stop and ask about.
- How fast you actually answer, honestly.

The onboarding document has a version of this in its §8, written from the
outside. This is the version from your side, and where they disagree, yours is
the real one.
