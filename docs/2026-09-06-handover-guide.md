# Handing Elenchus to Riyan: the general guide

Written 2026-09-06. Read this one first. It is the shape of the transition and
the decisions it needs, in about five minutes.

Two longer documents sit under it and neither is needed yet:

- `2026-09-06-elenchus-handover-runbook.md` is the step by step execution
  runbook, with commands, and is for when you are at the machine.
- `2026-09-06-riyan-onboarding.md` is what Riyan receives on day one.

---

## 1. It is three handovers, not one

The single most useful idea here is that these separate, and that keeping them
separate is most of the work.

**Elenchus development.** Riyan takes the majority. The repository is public, so
the code is already his to read. What he lacks is everything the repository
deliberately does not carry.

**Felix use.** He runs Felix against his checkout while you keep developing it.
Felix is private and stays private.

**Beta operations.** Real invited people have written real decisions into per
invitee databases. This is the one part that cannot be un-sent.

The recommendation throughout is that Riyan gets the first, gets a narrow slice
of the second, and gets none of the third.

---

## 2. The five decisions

Take these before anything else. Reversing one mid sequence is where a handover
leaks.

**D1. How he gets Felix.** Recommended: a private distribution repository
holding only the engine and the Elenchus project directory, squashed, no
history. Not a read only seat on `felix`, which would hand him 4000 lines of
standing strategy and two projects that are not his business, with no way to
narrow it afterwards.

**D2. Who operates the beta.** Recommended: you keep it entirely. Development
needs nothing from production, so there is no engineering reason to move it.

**D3. Anthropic billing.** Recommended: his own key, his own workspace, his own
spend limit. A shared key makes spend unattributable and means a leak from
either machine burns both.

**D4. His GitHub role.** Recommended: `write` on `LeavesJ/Elenchus`, pushing
branches directly. Not a fork, and not `admin`.

**D5. Whether `.env.example` gets added to Elenchus.** Yours alone. It changes
the tracked set of a public repo, which your own doctrine puts at T3.

---

## 3. The Felix problem, and why it is smaller than it looks

Felix is private, he needs to use it, and you keep building it. That sounds like
it needs a new mechanism. It does not.

The engine already contains no reference to any project by name, and a test
fails if one ever appears. So the engine and one project directory form a
complete unit that leaks nothing. I built that unit from your actual repository
and ran it: it resolved Elenchus correctly and passed every doctrine check,
including the five that a fork can never reach.

What that buys you: he gets exactly what the code requires, you ship changes
with a sync and a push, and he pulls. What it costs you: one publishing step
per Felix change, which is small.

The trap to avoid is the shortcut. Sending him only a marketplace line without
the clone gives him a working command with no doctrine and no gate, and no error
saying so.

---

## 4. Four things worth knowing before you start

**Someone already has write access to Elenchus.** The account
`InsertWittyCommentHere` holds `write` today. If that is Riyan, D4 is already
done. If not, a handover is the moment to decide whether it stands.

**A fork breaks Felix completely.** Elenchus binds to its project purely by its
remote name. Clone from a fork and Felix governs nothing, silently, because it
is built to stay quiet where it does not govern. That, more than CI, is why he
works on origin branches.

**A fresh clone already works.** The suite runs green in about a minute with
nothing untracked present. So his first hour does not wait on anything you send,
and a failure there is his environment rather than a missing file.

**The internal docs are the valuable part of the bundle.** Your code refers to
lessons by number 252 times, and the file those numbers point at is not in the
repository. That single file is what makes the codebase legible.

---

## 5. The order

Reversibility drops sharply at step three. Everything before it can be undone by
deleting a repository and removing a collaborator.

1. **Prepare.** Build the distribution repository. Assemble the bundle. Read
   every file in it. Nothing has been sent.
2. **Grant access.** Push the distribution repo, add him to both, issue his key.
   Still fully reversible.
3. **Send the bundle.** Encrypted. This is the point of no return.
4. **His first green gate.** The finish line for day one.
5. **His first pushed commit.** Small on purpose, so the whole chain gets
   exercised while nothing is at stake.
6. **Cut over.** Agree the boundary and who escalates what.

---

## 6. What never moves

Each of these is a boundary with a reason, not a matter of trust.

- Felix's memory directory, in any form. It holds verbatim founder prompts.
- Your own sittings database. That is your personal decision history.
- Any invitee's database. That is other people's writing.
- Your API key, and your Cloudflare credentials.
- `HANDOFF.md`, and the Felix and Veldra project directories.

If he later needs something on this list, that is a new decision on its own
merits, not an extension of this one.

---

## 7. What only you can answer

1. Is `InsertWittyCommentHere` Riyan?
2. Does the beta stay yours indefinitely, or is there a date?
3. Which of your untracked root documents are drafts you would rather not send?
4. Does `.env.example` get added?
5. Does he eventually get write access to the gate contract, and how?

The first one changes step two. The rest can wait until you are at the machine.
