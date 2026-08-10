# Add ANTHROPIC_API_KEY so CI can run Claude unattended

**Status check:** `gh secret list --repo LeavesJ/Elenchus` includes
`ANTHROPIC_API_KEY`.

This is the switch between *attended* autonomy and *unattended* autonomy, and it
is the one setup step with an ongoing cost, so it is deliberately yours.

## What it changes

Today CI runs the gate and reports pass or fail. Claude is not involved; a run
costs nothing beyond GitHub Actions minutes.

With this key present, a workflow can invoke Claude on a GitHub event: an issue
opens and a branch appears, CI fails and the repair loop attempts a patch. That
is the guidebook's Phase 5, "Claude wakes up on company events without founder
prompts" (p42).

**Every triggered run spends tokens, with nobody watching.** A loop that
misfires spends money while you sleep. That is why this is not automated and why
the repair loop is bounded at three attempts before it escalates.

## Steps

1. Go to <https://console.anthropic.com/settings/keys>.
2. Create a key scoped to this use. Name it something like `elenchus-ci` so it
   can be revoked without affecting your other work.
3. Copy it. You will not be shown it again.
4. Set it as a repository secret:

```bash
gh secret set ANTHROPIC_API_KEY --repo LeavesJ/Elenchus
```

Paste the value when prompted, then press Ctrl+D. Do not pass it with `--body`,
which would leave the key in your shell history.

## Set a spend limit first

Before the key exists, set a monthly cap under **Billing → Limits** in the
console. An unattended loop should have a ceiling that is enforced by Anthropic
rather than by an agent's good judgment.

## Verify

```bash
gh secret list --repo LeavesJ/Elenchus
```

## Revoking

Delete the key in the console and run
`gh secret delete ANTHROPIC_API_KEY --repo LeavesJ/Elenchus`. Any workflow
depending on it fails loudly rather than running degraded, which is correct.
