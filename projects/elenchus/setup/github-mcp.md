# Authenticate the GitHub MCP server

**Status check:** `claude mcp list` shows `plugin:github:github` as `Connected`.

Right now it reports `✗ Failed to connect`. The plugin is installed; the OAuth
consent has not been given, and only you can give it.

## Before you spend time on this

You may not need it. Felix already drives GitHub through the `gh` CLI, which is
authenticated as `LeavesJ` with `repo` and `workflow` scopes. Everything done so
far went through `gh`: opening PR #1, setting the `FELIX_DEPLOY_KEY` secret,
installing the deploy key, configuring branch protection, and reading CI logs.

The MCP adds a nicer interface for issue and PR browsing inside a session. It
does not unlock anything `gh` cannot already do. If you are short on time, skip
it and nothing breaks.

## Steps

1. Open an interactive terminal and run `claude`. This cannot be done from a
   non-interactive session, which is why it is your step and not Felix's.
2. Type `/mcp`.
3. Select `plugin:github:github` from the list.
4. Choose **Authenticate**. A browser opens.
5. Sign in as `LeavesJ` and approve the requested scopes.
6. Back in the terminal, confirm the server shows as connected.

## Verify

```bash
claude mcp list | grep github
```

Expect `✓ Connected`. Then `felix setup` will drop this row on its own.

## If it fails

`✗ Failed to connect` after authenticating usually means the token was issued
for a different account than the one that owns the repo. Re-run `/mcp`, remove
the server, and authenticate again as `LeavesJ`.
