# Contractor engagement letter: draft

Written 2026-09-06. This is step 0.1 of `2026-09-06-handover-setup.md`, the one
prerequisite that must be dated before Part 2.

**This is a draft for a lawyer to review, not legal advice and not a document to
sign as it stands.** It was written by reading `LICENSE` in the Elenchus
repository and reasoning about what that text does and does not do. What it gets
right is the shape of the problem. What a lawyer adds is whether the wording
holds in Delaware, whether the entity is formed, and everything about tax and
employment classification, which is out of scope here entirely.

The executed copy does not go in git. This template may; the signed one with real
names, dates and signatures should live wherever your other corporate records
live.

---

## Why this document exists, and the trap inside it

The obvious reason is the one the setup guide already gives. `LICENSE` §5(b)
forbids "You" from modifying or preparing patches for the Materials, §6 forbids
pull requests, and §1 excludes "Owner's founders, employees, contractors, or
agents acting on Owner's behalf" from the definition of "You". So Riyan needs to
be inside that exclusion before he writes a line, and a shared understanding is
not what §1 asks for.

**The non-obvious reason is the one that actually makes this urgent.** §6 reads:

> Do not submit pull requests or code contributions unless Owner agrees otherwise
> in writing. **This section does not apply to persons excluded from the
> definition of "You" in Section 1.**
> If You submit feedback or a contribution (including code, documentation, or
> suggestions), You grant Owner a perpetual, worldwide, irrevocable, royalty free,
> sublicensable license to use, reproduce, modify, distribute, and create
> derivative works from that feedback or contribution for any purpose, under any
> terms Owner chooses.

**The grant paragraph is keyed to "You", and a contractor is not "You".**
`LICENSE:39` says "If **You** submit... **You** grant Owner", both capitalised,
and `LICENSE:12` excludes "Owner's founders, employees, contractors, or agents
acting on Owner's behalf" from that definition. So the grant never reaches a
contractor at all.

So the license assigns rights in a stranger's contribution to Owner automatically
and assigns nothing whatever in a contractor's. Moving Riyan into the carve-out
gives him permission to modify and, in the same stroke, leaves Owner with no
claim on what he writes. Left there, the handover ends with the majority of
Elenchus development owned by the person doing it.

**The assignment in section 3 below is therefore the load-bearing part of this
letter.** Not the carve-out, which is one sentence. Everything else here is
ordinary.

**Correcting an earlier draft of this section, because the distinction changes
what would fix it.** That draft said the disapplication sentence "is wholesale,
it takes the second paragraph with it", and proposed splitting §6's two sentences
so only the prohibition is disapplied. That is the wrong diagnosis and therefore
the wrong fix. The disapplication sentence is not what excludes a contractor from
the grant; `LICENSE:12` is, because the grant operates on "You" and a contractor
is not "You". Delete the disapplication sentence entirely and nothing changes.
The real fix, if you ever want one, is in item 2b below and it is a different
edit.

**And the exclusion cuts both ways, which is why section 2 was rewritten.** If
being outside "You" removes the restrictions in §§4 to 6, it removes the
permissions in §3 by exactly the same logic: `LICENSE:20` grants "you" the right
to access, copy and run, and a person outside that definition holds no such
grant. A letter that only lifted restrictions would engage Riyan to develop
software he had no stated right to clone or compile. Section 2 therefore
authorises him directly rather than relying on the carve-out for either half.

---

## Draft

> **ENGAGEMENT OF CONTRACTOR**
>
> This engagement is made on **September 6, 2026** between **Elenchus Labs,
> Inc.**, a **Delaware** corporation ("Owner"), and **Riyan Jain** ("Contractor").
>
> **1. Engagement.** Owner engages Contractor as an independent contractor to
> develop, maintain and operate the Elenchus software and related materials.
> Contractor is not an employee, partner or agent for any purpose other than as
> stated in section 2, is responsible for their own taxes and insurance, and
> controls the manner and means of performing the work subject to Owner's
> direction as to what is to be produced.
>
> **2. Authorisation.** Owner, as copyright holder, authorises Contractor to
> access, copy, modify, create derivative works from, run and deploy the Elenchus
> materials (the "Materials") for the purposes of this engagement and on Owner's
> behalf. This authorisation is granted directly by Owner and does not depend on
> the Elenchus Source Available License v1.0 (the "License").
>
> For the avoidance of doubt, Contractor is also a contractor acting on Owner's
> behalf and is therefore excluded from the definition of "You" in section 1 of
> the License, and the restrictions in sections 4, 5 and 6 of the License do not
> apply to Contractor's work performed under this engagement.
>
> This authorisation begins on the date above and ends when this engagement ends,
> after which Contractor's position with respect to the Materials is governed by
> the License alone.
>
> **3. Ownership of work product.** Contractor acknowledges that the contribution
> grant in section 6 of the License operates only on "You" as defined in section 1
> of the License, that Contractor is excluded from that definition, and that
> accordingly no rights in Contractor's contributions pass to Owner under the
> License. This section is the sole source of those rights.
>
> (a) All work product created by Contractor in the course of, in anticipation of,
> or in connection with this engagement, including any contribution made to any
> Owner repository before the date of this engagement, and including source code,
> documentation, rubrics, prompts, gate definitions, doctrine files, test corpora,
> designs and notes, is a work made for hire for Owner where that doctrine
> applies.
>
> (b) To the extent any work product is not a work made for hire, Contractor
> irrevocably assigns to Owner all right, title and interest in it worldwide,
> including all copyright, patent, trade secret and other intellectual property
> rights, effective on creation.
>
> (c) To the extent any right cannot be assigned, Contractor grants Owner a
> perpetual, worldwide, irrevocable, royalty free, exclusive, sublicensable
> license to use, reproduce, modify, distribute and create derivative works from
> it for any purpose, and waives any moral rights to the extent waivable.
>
> (d) If Contractor incorporates any pre-existing material they own into the work
> product, Contractor grants Owner a perpetual, worldwide, irrevocable, royalty
> free, **exclusive**, sublicensable license to use it as part of the work
> product, and will tell Owner in writing when they do so.
>
> (e) Contractor represents that the work product is original to them except as
> disclosed to Owner in writing. Contractor will not incorporate third party or
> open source material into the work product without identifying that material and
> its license to Owner in writing in advance, and will not incorporate material
> under any license that would require Owner to distribute the work product on
> terms other than Owner's own.
>
> (f) Contractor will sign any further documents Owner reasonably requests to
> perfect or record these rights.
>
> **4. Confidentiality.** In the course of this engagement Contractor will receive
> material that is not public, including the private Felix repository and its
> contents, internal development records and lessons, positioning and strategy
> documents, and unpublished content banks. Contractor will keep all of it
> confidential, use it only for this engagement, and not disclose it to anyone
> without Owner's written consent. This obligation survives the end of the
> engagement. It does not cover information that is or becomes public through no
> act of Contractor's.
>
> **5. Personal data.** Owner operates a closed beta in which invited individuals
> have written personal material. Contractor is **not** granted access to invitee
> databases, server logs, Cloudflare Access policies, or any other record of
> invitee activity, and will not seek or retain access to them. If Contractor
> encounters such data incidentally, they will not copy it, will not use it, and
> will tell Owner promptly. Any future change to this section requires a separate
> written agreement.
>
> **6. Credentials.** Contractor will use only credentials issued to Contractor,
> will not share them, and will not use Owner's personal credentials. Contractor
> will not commit any credential, key or personal data to any repository.
>
> **7. Term and termination.** This engagement continues until either party ends
> it by written notice. On termination: the section 2 authorisation ends
> immediately and Contractor's position reverts to that of "You" under the
> License; Contractor will stop using the Materials, return or delete all
> confidential material and all copies of the Materials in their possession or
> control except where retention is required by law; and sections 3, 4, 5 and 8
> survive.
>
> **8. General.** This engagement is governed by the laws of the State of
> Delaware, without regard to conflict of law principles, and any dispute will be
> brought in the state or federal courts located in New Castle County, Delaware.
> It is the entire agreement between the parties on its subject matter and may be
> amended only in writing signed by both. If any provision is unenforceable the
> rest remains in effect.
>
> **Agreed:**
>
> For Elenchus Labs, Inc. \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_ Name/title: \_\_\_\_\_\_\_\_\_\_ Date: \_\_\_\_\_\_
>
> Contractor \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_ Name: \_\_\_\_\_\_\_\_\_\_ Date: \_\_\_\_\_\_

---

## Things to settle before this is signed

**1. Which entity is Owner.** This is the one item here that can quietly
invalidate everything else, and the repositories do not settle it. What they
actually contain, searched rather than assumed:

- **"Elenchus Labs, Inc." appears exactly once in either codebase**, at
  `LICENSE:4`, in the copyright line. There is no other reference anywhere: not
  in a README, a manifest, a doc, or a config.
- **"Veldra, Inc." appears exactly once**, at `projects/veldra/CLAUDE.md:3`,
  describing ReserveGrid OS.
- Both plugin manifests name **Jarron Deng personally**, not any entity
  (`.claude-plugin/marketplace.json:4`, `engine/.claude-plugin/plugin.json:6`).

So Elenchus Labs, Inc. is asserted by one line of one file and corroborated by
nothing. That is not evidence it does not exist; it is evidence the repositories
cannot tell you. **Confirm it is formed and holds the copyright before signing.**
If it is not formed, copyright in the existing work sits with the author
personally by default, the letter engages a contractor on behalf of an entity
that cannot hold the assignment, and section 3 has nowhere to land.

**1b. A second ownership thread, noticed while checking the first.**
`src/elenchus/veldra_ingest.py:1` describes "Curated ingestion of real Veldra
owned-problems into the (gitignored) store", seeded from
`data/seed/veldra_ledger.yaml`. So Elenchus content is derived from material the
file itself calls Veldra's. If Owner is Elenchus Labs, Inc. and that material
belongs to Veldra, Inc., there should be something granting the first the right
to use the second's. Not a handover blocker, and worth raising in the same
conversation with the lawyer since it is the same question wearing different
clothes.

**2. The license mixes "You" and "you", and it matters here.** Section 1 defines
capitalised **"You"**. But **section 5, the one that actually forbids
modification, opens in lowercase**: `LICENSE:29`, "Except as expressly permitted
in Section 3, you may not:". Section 3's grant is lowercase too (`LICENSE:20`,
"Owner grants you a limited... license"). Section 4 uses both in a single
paragraph. Across the file: capital "You" 8 times, lowercase "you" 7 times.

Read strictly, the section 1 carve-out excludes people from capital "You", while
the prohibition Riyan needs lifted is addressed to lowercase "you", which the
license never defines. The drafter plainly meant one thing, and section 6 proves
the exclusion was meant to have force, but the text does not carry it cleanly.

**This is why section 2 of the draft was rewritten to authorise Riyan directly
rather than to rely on the carve-out.** Owner holds the copyright and can
authorise its own contractor regardless of what a public license says to third
parties. The carve-out is kept as a second, weaker argument rather than the load
bearing one. Worth telling the lawyer this specifically, because it is the kind
of thing that reads as pedantry until it is the whole case.

**2b. Whether to fix the license itself, and the fix that does not work.**

An earlier draft proposed splitting §6's two sentences so that only the
prohibition on pull requests is disapplied to excluded persons. **That would close
nothing**, and the reason is worth stating because it is the same trap twice: the
grant paragraph operates on "You" (`LICENSE:39`, "If You submit... You grant
Owner"), and `LICENSE:12` excludes contractors from "You". The disapplication
sentence is not doing the work, so removing it changes nothing.

The change that would actually close it re-keys the grant off the definition
entirely, for example: "Any person who submits feedback or a contribution grants
Owner a perpetual, worldwide, irrevocable, royalty free, sublicensable license
to..." Alongside that, making the "You" and "you" usage consistent throughout
would remove the ambiguity in item 2.

Both are edits to a tracked file in a public repository, so both are T3 under
`projects/elenchus/CLAUDE.md` and both are your call. Neither is required for this
handover. Until they are done, every future contractor needs a letter like this
one, and any engaged without one owns their work by default.

**2c. Riyan has committed nothing yet, and the draft now covers it anyway.**
Checked rather than assumed: `git log --all` over Elenchus returns 111 commits
across three identities, all of them Jarron Deng. `list_commits` filtered to
`InsertWittyCommentHere` returns empty. So the risk that he commits as "You"
before the letter is signed is **prospective, not live**.

It is worth closing regardless, because he holds `write` today and could commit
at any point before signature. Section 3(a) therefore reaches work created "in
anticipation of, or in connection with this engagement, including any contribution
made to any Owner repository before the date of this engagement". If any commit
does land before signing, mention it to the lawyer: such a commit would have been
made as "You" and would sit against `LICENSE:31` and `LICENSE:38`, which is an
odd footing to start an engagement on even though the assignment now reaches it.

**3. Whether the beta carve-out in section 5 is right.** It matches decision D2:
Riyan develops and does not operate the beta. If you expect that to change within
the engagement, say so now rather than amending later, because the invitees agreed
to you seeing their writing and not to a second person.

**4. Section 2's scope.** As drafted, the authorisation covers the Materials "for
the purposes of this engagement and on Owner's behalf", and the carve-out sentence
covers "work performed under this engagement". Both are deliberately narrower than
excluding Riyan from "You" for all purposes forever. A lawyer may want them
narrower still, or tied to a defined statement of work.

**5. What the draft does not contain, deliberately.** No compensation clause, no
statement of work, no notice period, no restriction on pushing to `main`, no
non-compete. Each is a real decision rather than an oversight, and a lawyer will
ask about the first two immediately. Consideration in particular is worth settling
before signing rather than after: an engagement letter that says nothing about
what either side gives is a document a lawyer will want to fix.

---

## What to do with it

**Decided 2026-09-06: skip counsel, send directly to Riyan.** The four items
under "Things to settle before this is signed" are accepted as-is rather than
routed to a lawyer first. This is J's call to make and he made it.

1. **Done 2026-09-06.** Date, state of incorporation and Contractor's full legal
   name are filled in: September 6, 2026; Delaware; Riyan Jain. Delaware was the
   working assumption throughout this draft, matching the governing-law clause in
   section 8, and was not independently confirmed against the entity's actual
   formation documents. Confirm it if that has not already happened.
2. Send the signable letter to Riyan. The Notes for Counsel document is
   background for J's own reference and is not sent to him; it explains why the
   letter is shaped the way it is, not something either signatory needs.
3. Sign, date, and keep the executed copy out of git.
4. Tick step 0.1 and start Part 1.
