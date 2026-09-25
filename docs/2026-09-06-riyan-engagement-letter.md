# Felix and beta confidentiality acknowledgment

Written 2026-09-06, rewritten the same day once the facts changed. This is now
step 0.1 of `2026-09-06-handover-setup.md`. The version history matters here,
so it is kept rather than replaced silently: a document that hides its own
reversal is harder to trust than one that shows it.

---

## What this document used to be, and why it shrank

The first four drafts of this file were a contractor engagement letter: an
independent-contractor recital, an authorisation clause reaching Riyan through
`LICENSE`'s "contractors, or agents acting on Owner's behalf" prong, and a full
IP assignment in section 3.

**Two facts, confirmed 2026-09-06, dissolve most of that.**

**Riyan is already a legal founder of Elenchus Labs, Inc.**, with issued
founders' stock, an RSPA, an 83(b) election, and an indemnification agreement,
all executed at incorporation through Stripe Atlas. `LICENSE:12` excludes
"Owner's founders" from the defined term "You" as its own category, independent
of "contractors" or "agents". That exclusion is self-executing: it does not
need a side letter to invoke it. Riyan has very likely been outside "You" since
the day the stock was issued, not from anything drafted in this file.

**Riyan already signed a CIIAA (Confidential Information and Invention
Assignment Agreement) with Elenchus Labs, Inc.**, also confirmed 2026-09-06,
also part of the Atlas incorporation package, listed as "Form of Employee CIIAA
for Riyan Jain" and verified to carry an actual signature rather than sitting
as a generated, unsigned form. That agreement is Elenchus Labs, Inc.'s standard
instrument for assigning a founder's work product to the company, and a
bespoke letter duplicating it in different words is worse than no letter at
all, because two differently worded assignments over the same work is exactly
the kind of ambiguity a diligence review flags.

**So sections 1 through 3 of every earlier draft are gone.** The contractor
recital was inaccurate the moment it was confirmed he holds equity. The
authorisation clause was solving a problem the incorporation had already
solved. The IP assignment was duplicating a document that already exists and
is already signed.

## What is left, and why it survives this cut

Two things a standard founder CIIAA does not reach, plus one operational
reminder.

**Felix confidentiality does not obviously follow from the CIIAA's scope.**
A CIIAA's confidentiality duty runs to "the Company", meaning Elenchus Labs,
Inc. and its confidential information. Felix is not only Elenchus's tooling:
`projects/veldra/CLAUDE.md` shows it also governs a separate venture, Veldra,
Inc. Whether Elenchus Labs, Inc.'s CIIAA reaches material that is shared across
a different venture, or that belongs to J personally rather than to either
company, is genuinely unclear and not something to assume silently either way.
An explicit line closes the gap regardless of how that question resolves.

**The beta and invitee-data restriction is not an IP question at all.** No
incorporation document reaches it, because it is a promise about third parties
who wrote personal material and never consented to a second reader. Being a
trusted cofounder does not retroactively obtain that consent, which is the
same reasoning this handover applied when the question was first raised.

**Credentials get one operational line**, kept short because it is a practice
reminder rather than a legal term.

---

## Draft

> **FELIX AND BETA CONFIDENTIALITY ACKNOWLEDGMENT**
>
> This acknowledgment is made on **September 6, 2026** by **Riyan Jain**, a
> founder of **Elenchus Labs, Inc.** ("the Company"), in connection with his
> access to the systems and material described below.
>
> **1. Felix.** Riyan will be given read access to the private repository at
> `github.com/LeavesJ/felix` ("Felix"), which governs engineering practice
> across more than one venture, not only the Company. Riyan will keep Felix's
> contents confidential, use them only to develop and operate the Company's
> Elenchus product, and not disclose them to any third party, regardless of
> whether Felix's contents are covered by any other confidentiality obligation
> Riyan holds to the Company. This obligation survives for as long as Riyan
> retains access to Felix and does not depend on his status as a founder,
> employee, or in any other capacity.
>
> **2. Beta and personal data.** The Company operates a closed beta of
> Elenchus in which invited individuals have written personal material. Riyan
> is not granted access to invitee databases, server logs, Cloudflare Access
> policies, or any other record of invitee activity, and will not seek or
> retain access to them. If Riyan encounters such data incidentally, he will
> not copy it, will not use it, and will tell Jarron Wan Deng promptly. Any
> future change to this section requires a separate written agreement between
> Riyan and Jarron Wan Deng.
>
> **3. Credentials.** Riyan will use only credentials issued to him, will not
> share them, and will not use Jarron Wan Deng's personal credentials. Riyan
> will not commit any credential, key, or personal data to any repository.
>
> **Agreed:**
>
> Riyan Jain \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_ Date: \_\_\_\_\_\_

---

## What to do with it

1. **Decide whether this needs a signature at all.** It is short enough that
   some founders would just say it once and move on. The one clause worth a
   real signature is section 2: it is a promise about people who are not party
   to this conversation, and a signed acknowledgment carries more weight than
   a verbal one if it is ever needed. Sections 1 and 3 are lower stakes either
   way.
2. Send it to Riyan alongside, or ahead of, Phase B1 in the setup guide.
   Nothing else in this handover is gated on it now that D0's original premise
   is resolved by the incorporation paperwork.
3. Sign, date, and keep the executed copy with the rest of the incorporation
   records, not in git.
4. Start Part 1, if it has not already started.
