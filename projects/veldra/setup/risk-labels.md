# Escalation and risk labels

**Check:** `gh label list --repo LeavesJ/ReserveGrid-OS` includes `needs-founder`.

The repair loop escalates by applying a label. Without these it has nowhere to
put a problem it has decided to stop working on.

| Label | Meaning |
|---|---|
| `needs-founder` | The repair loop hit its ceiling. Stop patching. |
| `needs-architecture` | The failure is a design problem, not a patch. |
| `risk-green` | Reversible. Auto-merge eligible once policy allows it. |
| `risk-yellow` | User-facing or schema change. A human reviews. |
| `risk-red` | Auth, secrets, money, irreversible. Approval required. |

```bash
gh label create needs-founder --repo LeavesJ/ReserveGrid-OS --color D93F0B \
  --description "Repair loop hit its ceiling; a human must diagnose"
gh label create needs-architecture --repo LeavesJ/ReserveGrid-OS --color 5319E7 \
  --description "Failure is a design problem, not a patch"
gh label create risk-green --repo LeavesJ/ReserveGrid-OS --color 0E8A16 --description "Reversible"
gh label create risk-yellow --repo LeavesJ/ReserveGrid-OS --color FBCA04 --description "Human reviews"
gh label create risk-red --repo LeavesJ/ReserveGrid-OS --color B60205 --description "Approval required"
```

Needs no account and no credential, so an agent can do this for you. It is listed
because the check should catch it if someone deletes one.
