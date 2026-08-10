# Add ANTHROPIC_API_KEY so CI can run Claude unattended

**Status check:** `gh secret list --repo LeavesJ/Elenchus` includes
`ANTHROPIC_API_KEY`.

## The key already in .env does not count

Elenchus has an `ANTHROPIC_API_KEY` in its local `.env`. That does nothing for
CI, for two independent reasons:

* `.env` is gitignored, and the runner does a fresh clone. It never exists there.
* GitHub Actions secrets are not ambient. A workflow only sees a secret it names
  explicitly as `${{ secrets.NAME }}`. `gate.yml` names only `FELIX_DEPLOY_KEY`.

So adding this secret does **not** cause the live tests to start running. That is
worth stating because it is the natural fear, and it is unfounded as things
stand.

## What the local key does and does not do

Verified 2026-08-09: `ANTHROPIC_API_KEY` is not exported in the shell, and
nothing loads `.env` into pytest. `_load_dotenv` is called only from
`src/elenchus/web/__main__.py`, the web entry point. A gate run reports
31 skipped with reason `no key`, so **local gate runs cost nothing in API
calls.** The `.env` key is for running the app, not the suite.

If you ever `export ANTHROPIC_API_KEY` into your shell, that changes: 31 live
tests begin running on every gate, and every gate run bills.

## Use a separate key, not the one Vera runs on

A repository secret is readable by any workflow in the repository. Anyone who can
push a workflow to a branch can write one that exfiltrates it. If that value is
the same key serving Vera, a workflow compromise becomes a product compromise.

Create a key that exists only for CI, so it can be revoked without taking
anything else down with it.

## Steps

1. Set a monthly cap first, at **Billing → Limits** in the console. An unattended
   loop should have a ceiling enforced by Anthropic, not by an agent's judgment.
2. Create a key at <https://console.anthropic.com/settings/keys>, named
   something like `elenchus-ci`.
3. Set it:

```bash
gh secret set ANTHROPIC_API_KEY --repo LeavesJ/Elenchus
```

Paste, then Ctrl+D. Do not use `--body`, which leaves the key in shell history.

## The trap to watch for later

The day someone adds `ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}` to
`gate.yml`, 31 live tests start running on every pull request and billing for it,
silently, because they will simply stop skipping. If live coverage in CI is ever
wanted, put it in a separate scheduled workflow with its own budget rather than
in the gate. The gate should stay free and fast enough that nobody is tempted to
skip it.

## Revoking

Delete the key in the console, then
`gh secret delete ANTHROPIC_API_KEY --repo LeavesJ/Elenchus`. Anything depending
on it fails loudly rather than running degraded, which is correct.
