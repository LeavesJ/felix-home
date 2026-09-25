# Authority That Cannot Be Earned

*Notes on a root-of-trust model for a self-modifying engineering agent, and the
place my own implementation breaks it.*

Jarron Deng · August 2026

---

## The setting

I maintain a harness that governs an autonomous coding agent. It binds session
lifecycle hooks, refuses shell commands a project has forbidden, runs a
verification gate, classifies diffs by blast radius, and decides what a change
owes before it may merge. It is bash and git, deliberately: the enforcing path
has to work with no network, no key, and no model, because a permission check
that needs a model to answer is not a permission check.

The agent's most consequential changes are to the harness itself. That is the
whole problem in one sentence. A system that can edit the code that governs it
can, in principle, edit the part that decides what it is allowed to edit.

What follows is the model I arrived at, and then the part that matters more:
what happened when I had every mechanical claim in this note independently
attacked before publishing it.

## Risk is not authority

The first thing that had to come apart was a conflation I had shipped without
noticing. My classifier rates changes green / yellow / red by blast radius.
It is natural to reach for "very red" to mean "changes what the system may do."

That representation is wrong, and it is wrong in a way that fails later rather
than immediately. If authority is the top of a risk ladder, then a system that
accumulates evidence of competence will eventually — reasonably — ask why it has
earned red and still cannot touch this. The honest answer is that it was never
the same kind of thing.

So the two are orthogonal axes:

- **risk** describes consequence. It is earnable.
- **channel** describes non-delegable authority. It is not.

Mechanically these are different columns of the same table and different code
paths. `tier` feeds the classifier. A non-empty `channel` is what produces a
merge-blocking escape. In my implementation `felix merge` refuses on exactly
three blocker kinds, all emitted by one function: an `escape` (merging writes
something outside the tree that a revert cannot reach), `unverified` (no green
gate receipt for this exact tree), and `evidence` (a behaviour change with no
test). Every one is computed offline — the first network call in the command
sits below the line that refuses, so the refusal is identical with and without
a network.

Four channels are engine constants, computed from the diff before any project's
table is opened: secrets in added lines, CI workflow paths, destructive
migrations, and a weakened verifier. A governed project may **add** a channel by
naming one in its own table, and that name is emitted verbatim — the namespace
is open, and a project-invented channel blocks a merge exactly as an engine one
does. What a project cannot do is **subtract**: every suppression in the file is
a `continue` inside the loop over project rows, so it can only skip a project
row about to fire, never an engine emission already written.

That asymmetry — a project may tighten, never loosen — is the only structural
idea here I would defend without qualification.

## The kernel has to be transitive

My first attempt named one file: the detector that decides whether a candidate
change widens authority. Protect that file, and the system cannot quietly
redefine what counts as authority.

Two escapes make that fake, and both are obvious once stated. The system cannot
modify the detector, but can modify the table telling it what to protect. Or it
can modify the merge path so the detector's verdict is ignored. A verdict
nothing acts on is not a gate.

So the protected thing is the smallest **transitive** authority kernel, closed
under its own fourth clause:

1. the detector — decides whether a candidate changes authority
2. the protected-set definition — decides what constitutes (1) and (3)
3. enforcement — turns a verdict into an unavoidable stop
4. the mechanism for changing 1–3 — must itself be covered by 1–3

Clause 4 is not decoration. Without it, the first thing sufficient autonomy buys
is the ability to stop the gate noticing.

## The recursion is solved by who evaluates, not by what is protected

Enumerating a protected set is necessary and not sufficient, because the
enumeration is itself a file. The clause that closes it is about the evaluator:

> A candidate must not evaluate its own authority change. The currently trusted
> version evaluates the candidate.

`V_n` judges `V_n+1`. If the candidate touches the authority root, a human is
required; only after approval does the candidate become the evaluator of
`V_n+2`. The alternative — a candidate whose new detector judges itself — is
self-certification with extra steps.

## Where my own system breaks this

This is the part I would want to read, so it is the part I checked hardest.

**The classification table rates itself.** My risk table assigns tiers by path
regex. It contains rows marking certain paths green, and it rates *itself* only
yellow. The classifier reads the table off disk at classification time. So a
single commit that deletes the row marking the harness red, adds a row marking
the same path green, and edits the table — all in one diff — is classified by
the table it just rewrote, and comes out **green**, harness shell files
included.

I did not find this by reading. I wrote down the opposite claim — that no code
change in this repository could ever be classified green — handed it to a
hostile reader, and got back a reproduction on a scratch repository using my own
committed table.

The system already knew. There is a line of prose in the merge path reading *"a
change editing risk.tsv or evidence.tsv must never auto-merge."* Nothing
anywhere enforces it. The warning was written by someone who saw the hole and
described it instead of closing it, and then it sat in a string literal where no
check could reach it.

**The label is not the classification.** The auto-merge counter I built queries
merged pull requests carrying a `risk-green` label and never re-derives the tier
from the merged diff. The label is applied by a manual command. Adding it by
hand to any pull request advances the counter. A gate whose input is an
assertion rather than a derivation is a gate on the honour system.

**Absence of use is not evidence of uselessness, and I only half fixed it.** My
capability ledger records, per session, how many times each declared capability
was actually called, and separately how many times the router pointed at it. The
distinction exists because I got it wrong the first time: I had treated a zero
call count as unconfounded evidence that a capability was not worth mounting,
when a capability the router never named has a zero that measures the router's
priors, not the capability. Recording "named" beside "calls" fixes that half.

The half still broken: the zero rows are generated from the *declaration* file,
and nothing reads installed state. The argument is "absence of use **given
presence**," and presence is the term never checked. A capability that is
declared, never actually installed, and named by a route every session
accumulates `named=6, calls=0` and is reported as pointed-at-and-ignored. The
confound I removed from one axis reappeared on another.

**The evidence itself is malformed.** In shell, `grep -c` prints `0` *and* exits
non-zero when nothing matches, so a `|| echo 0` fallback fires on top of output
that was already correct and yields a two-line value. In my committed ledger,
215 of the physical lines are one-column stray zeros — a majority of the file.
Downstream readers that require a full row skip them, so the analysis is right;
the session count in the report header is not, because it counts distinct first
fields and the string `0` is one. The suite misses it because its assertions
test for substrings and step over the broken lines.

That is a verification system whose own evidence file is malformed, whose own
test suite cannot see it, and whose only visible symptom is an off-by-one in a
number nobody was checking.

## What this note is worth

Before publishing I wrote down fifteen mechanical claims about my own system and
gave each to an independent reader instructed to refute it against source, with
a standing instruction to default to *refuted* when it could not personally
verify the claim in code.

**Eleven of fifteen failed.** Not typos — category errors. Claims true of one
configuration and stated as properties of a function. A claim that a comment was
a stale counter, when the comment was past tense and describing why the file
existed. An assertion count that is a property of one machine: four assertions
are gated on a CLI being present, so the same suite reports a different total on
a continuous-integration runner. Two claims where I had reprinted half of my own
design document as a correction of the other half.

The four that survived did so with tightened wording.

I record that number because it is the actual finding. I am describing a
verification harness, and my unverified claims about it were wrong about
seventy percent of the time. That rate is the argument for the architecture, not
an embarrassment beside it — and any similar note that reports no such number
has either done the work and not said so, or not done it.

## Open

- **Base-version evaluation is undesigned.** `V_n` judges `V_n+1` is a
  requirement I can state and cannot yet implement. A pinned copy of the last
  trusted engine is the obvious candidate and I have not built it.
- **Eight competence dimensions, three with data.** Merge correctness and
  self-maintenance are measurable now. Classification accuracy needs observed
  consequences; repair and recovery have never run for real. I intend to ship
  the dimensions that have data and leave the rest *absent* rather than empty.
  An absent dimension is honest. An empty one accumulates into something shaped
  like a dataset and is a mirror.
- **Self-modification is not the same as self-improvement**, and nothing here
  distinguishes them. A system that reliably passes its own checks after
  changing itself has demonstrated consistency, not competence — which is the
  same objection as the classification table rating itself, one level up.

---

*Corrections welcome. Every mechanical claim above cites a specific mechanism;
if one is wrong I would rather know.*
