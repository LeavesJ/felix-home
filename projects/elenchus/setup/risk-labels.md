# Escalation and risk labels

**Status check:** `gh label list --repo LeavesJ/Elenchus` includes `needs-founder`.

Already done. Felix created these itself, since label creation needs no account,
no consent screen, and no credential. It stays declared so that a fresh clone or
a new repo can be brought to the same state, and so the check catches it if
someone deletes one.

| Label | Meaning |
|---|---|
| `needs-founder` | The repair loop hit its ceiling. Stop patching. |
| `needs-architecture` | The failure is a design problem, not a patch. |
| `risk-green` | Reversible. Auto-merge eligible once policy allows it. |
| `risk-yellow` | User-facing or schema change. Founder reviews. |
| `risk-red` | Auth, secrets, money, irreversible. Founder approval required. |

## Recreating them

```bash
gh label create needs-founder --repo LeavesJ/Elenchus --color D93F0B \
  --description "Repair loop hit its ceiling; a human must diagnose"
```

The other four follow the same shape. Colours are from the guidebook's merge
policy table (p8).
