# Handing Elenchus to Riyan: the general guide

Written 2026-09-06. Read this one first. It is the shape of the transition and
the decisions it needs, in about five minutes.

Longer documents sit under it and none is needed yet:

- `2026-09-06-handover-setup.md` is the linear run sheet you execute.
- `2026-09-06-elenchus-handover-runbook.md` is the reasoning behind every step,
  with the evidence, and is where to look when a step seems wrong.
- `2026-09-06-riyan-onboarding.md` is what Riyan receives on day one.
- `2026-09-06-elenchus-environment.md` is the local environment written out from
  the tracked code. It goes in the bundle as `ENVIRONMENT.md` and it is the
  answer to Riyan saying he does not know the setup, which the repository by
  itself genuinely does not tell him.

---

## 1. It is three handovers, not one

The single most useful idea here is that these separate, and that keeping them
separate is most of the work.

**Elenchus development.** Riyan takes the majority. The repository is public, so
the code is already his to read. What he lacks is everything the repository
deliberately does not carry.

**Felix use.** He runs Felix against his checkout while you keep developing it.
Felix is private and stays private.

**Beta operations.** Thirty invitations are ready and none has been run, so the
per invitee databases are empty today. Once they are not, they hold real
decisions written by real people, and that is the one part of this handover that
cannot be un-sent.

The recommendation throughout is that Riyan gets the first, gets a narrow slice
of the second, and gets none of the third.

---

## 2. The decisions

Take these before anything else. Reversing one mid sequence is where a handover
leaks.

**D0. Sign the Felix and beta confidentiality acknowledgment.** Resolved
2026-09-06. Riyan is already a legal founder of Elenchus Labs, Inc., with a
signed CIIAA from incorporation, confirmed carrying an actual signature. Both
the license's founder exclusion and the IP assignment were already in place
before this handover started, so the document that remains is not a contractor
letter, it is three short clauses covering what a founder CIIAA does not reach:
Felix confidentiality (Felix also governs a separate venture), the beta and
invitee-data restriction (a promise about third parties, not an IP question),
and credential handling. Runbook §D0 has the full reasoning.

**D1. How he gets Felix.** Decided: a read only seat on `LeavesJ/felix`. This
reverses the earlier recommendation of a narrow distribution repository, and it
reverses it because D4's answer changed the facts. He already has write on
Elenchus, and write on Elenchus is read on `felix` through CI, so the
distribution repo would have withheld nothing while costing a sync step forever.
Read on `felix` is also positively better: there is then exactly one copy of the
gate contract, which he reads, CI reads, and you edit. It cannot diverge, only
lag, and `git pull` fixes lag. He sees `HANDOFF.md` and learns ReserveGrid OS
exists; confirmed acceptable. The one cost is that the grant widens on its own as
`felix` grows.

**D2. Who operates the beta.** Recommended: you keep it entirely. Development
needs nothing from production, so there is no engineering reason to move it.

**D3. Anthropic billing.** Recommended: his own key, his own workspace, his own
spend limit. A shared key makes spend unattributable and means a leak from
either machine burns both.

**D4. His GitHub role.** Recommended: `write` on `LeavesJ/Elenchus`, pushing
branches directly. Not a fork, and not `admin`.

**D4b. Whether the CI deploy key stays pointed at Felix.** Resolved by D1: it
stays, and no workflow changes. The finding behind it still matters as a standing
rule, because nothing in either repository enforces it. **Write on Elenchus is
read on `felix`**, since both workflows check out the private repo with
`FELIX_DEPLOY_KEY` and a same repo pull request runs the workflow file from the
branch it came from, before any review. Grant the first only to someone you would
grant the second.

**D5. Whether `.env.example` gets added to Elenchus.** Yours alone. It changes
the tracked set of a public repo, which your own doctrine puts at T3.

---

## 3. The Felix problem, and why it is smaller than it looks

Felix is private, he needs to use it, and you keep building it. That sounds like
it needs a new mechanism. It does not.

He clones `felix`, runs `felix install --home ~/felix`, and Felix governs his
Elenchus checkout. That is the whole thing. Read access is sufficient: Felix
writes only into a gitignored `state/` inside the clone and into
`~/.felix/memory/` in his own home, so he never needs to push.

What it costs you is nothing ongoing. What you push is what he gets.

Two traps worth knowing. **Sending him only a marketplace line without the clone**
gives him a working command with no doctrine and no gate, and no error saying so,
because only `engine/` enters the plugin cache and Felix stays silent where it
does not govern. And **his clone carries all three projects**, so opening the
felix clone itself in Claude Code binds that session to the Felix project rather
than to Elenchus. Harmless, and alarming the first time.

For the record, the narrower option was built and verified before D1 was decided:
a tree of `engine/` plus `projects/elenchus/` is 105 files and 1.8 MB, resolves
Elenchus correctly, and passes every doctrine check including the five a fork can
never reach. The recipe is in the runbook at §4e, unused, for the day someone
else gets write on Elenchus.

---

## 4. Things worth knowing before you start

**Riyan already has write on Elenchus.** He is `InsertWittyCommentHere`, so D4
needs no action. It also means he could already read `felix` through CI before
this handover began, which is what settled D1.

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

**Reversibility ends at step two, not step three.** An earlier version of this
paragraph said everything before step three could be undone "by deleting a
repository and removing a collaborator", which was true only while D1 called for
a separate distribution repository. There is no such repository now. The moment
Riyan accepts the `felix` invitation and clones, everything in `LeavesJ/felix`
is disclosed permanently; removing the seat afterwards removes future access,
not the copy on his disk.

1. **Prepare.** Assemble the bundle. Read every file in it. Nothing has been
   sent.
2. **Grant access.** Add him to `felix` with read, issue his key. He already has
   write on Elenchus. **This is the first irreversible step.**
3. **Send the bundle.** Encrypted. Irreversible too, and worse in one respect:
   the bundle holds material that is in no repository, so nothing else has a
   copy of it.
4. **His first green gate.** The finish line for day one.
5. **His first pushed commit.** Small on purpose, so the whole chain gets
   exercised while nothing is at stake.
6. **Cut over.** Agree the boundary and who escalates what.

---

## 6. What never moves

Each of these is a boundary with a reason, not a matter of trust.

- The memory root's raw logs. `routes.log` and `says.log` hold verbatim prompt
  text, `unresolved.log` spans every governed project, and `mistakes.log`,
  `verification.log` and `ledger.tsv` are per-machine records.
- Your own sittings database. That is your personal decision history.
- Any invitee's database. That is other people's writing.
- Your API key, and your Cloudflare credentials.

**Two earlier entries on this list were wrong and are struck.** "Felix's memory
directory, in any form" cannot hold, because `docs/lessons.md`, `docs/DEVLOG.md`
and `docs/SESSION_HANDOFF.md` are symlinks into that directory and all three are
in the bundle. They are authored prose rather than raw logs and they travel as
contents. And "`HANDOFF.md`, and the Felix and Veldra project directories" was
struck by D1: read on `felix` is read on all of it. That is not a leak, it is
the grant, and §2's D1 records it as accepted. What covers it is clause 1 of the
confidentiality acknowledgment, not an access boundary.

If he later needs something still on this list, that is a new decision on its
own merits, not an extension of this one.

---

## 7. What only you can answer

Three are answered as of 2026-09-06. Riyan is engaged with high authority, he is
`InsertWittyCommentHere` and already holds write, and the CI deploy key stays
where it is. What remains:

1. Date the Felix and beta confidentiality acknowledgment. **This is not the
   license question**, which is closed: `LICENSE:12`'s founder exclusion is
   self-executing and the CIIAA was signed at incorporation. An earlier version
   of this item told you to get the engagement in writing before his first
   commit, which was D0's pre-reversal answer. What is left covers only what a
   founder CIIAA does not reach, and its deadline is **before Part 2**, the
   access grant, not before his first commit.
2. Does the beta stay yours indefinitely, or is there a date?
3. Which of your untracked root documents are drafts you would rather not send?
4. Does `.env.example` get added?
5. Does he eventually get write access to the gate contract, and how?

Only the first needs doing before you grant the felix seat. The rest can wait
until you are at the machine.

**One question came off this list on 2026-09-06 and it changed the shape of the
handover.** Thirty invitations are ready and none has been run, so the tenant
root is empty and no invitee material exists. Every "this is safe because
nothing has accumulated yet" judgement in these documents is therefore correct
today and expires the day the first invitation goes out. Doing the handover
before the beta rather than during it is the single largest piece of luck in the
sequence. Use it.
