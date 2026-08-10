# Restricted Stripe keys behind a billing broker

**Status check:** none automated. This one ends in a human decision, so its
check is `false` by design and the row stays visible until removed by hand.

**Dormant.** Elenchus has no payments. This exists so the shape is written down
before the pressure to ship billing arrives.

## The rule that matters most

**Never give an agent a live Stripe secret key.** Guidebook p13, stated as
plainly as anything in the document.

Live writes go through a small internal broker exposing business-level
operations (`preview_plan_change`, `reconcile_customer`, `request_refund`) with
allowlisted operations, amount ceilings, idempotency, and an audit log. The
agent calls the broker. It never holds the account.

## When it becomes real

1. Create the account, and use Stripe Atlas if incorporating through it.
2. Work exclusively in **test mode** first. Test-mode tooling is low risk and
   can be mounted normally.
3. Create a **restricted key** (Developers → API keys → Restricted) with reads
   only. Never a live secret key.
4. Build the broker before the first live write, not after.
5. Add rows to `stack.tsv` at `risk=high`. High is refused by every automation
   flag, which is the correct tier for anything touching money.
6. Model money in integer minor units with an explicit currency. Never floats.

## What stays human forever

New live prices, mass plan migrations, payout destinations, bank or tax
settings, and refunds above written policy. Guidebook p13. These are not
"not yet automated." They are decisions with a person's name attached.
