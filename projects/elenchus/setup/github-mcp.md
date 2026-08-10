# Authenticate the GitHub MCP server

**Status check:** `claude mcp list` shows `plugin:github:github` as `Connected`.

## Do you actually need this?

Probably not. Felix drives GitHub through the `gh` CLI, already authenticated as
`LeavesJ` with `repo` and `workflow` scopes. Everything so far went through `gh`:
opening and merging PR #1, setting `FELIX_DEPLOY_KEY`, installing the deploy key,
branch protection, the escalation labels, and reading CI logs.

The MCP is a nicer interface for browsing issues and PRs inside a session. It
unlocks nothing `gh` cannot already do. Skipping it costs you nothing.

## The error, and why the obvious fix does not work

```
Status: ✗ failed
Auth:   ✗ not authenticated
URL:    https://api.githubcopilot.com/mcp/
Error:  Incompatible auth server: does not support dynamic client registration
```

Choosing **Authenticate** in `/mcp` cannot fix this, and will keep failing with
the same message. The server does not use OAuth at all.

The plugin ships this config:

```json
{ "github": { "type": "http",
    "url": "https://api.githubcopilot.com/mcp/",
    "headers": { "Authorization": "Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}" } } }
```

It expects a token from the environment. When `GITHUB_PERSONAL_ACCESS_TOKEN` is
unset the header becomes an empty bearer, the server rejects the request, and
Claude Code falls back to OAuth discovery. GitHub's endpoint does not support
dynamic client registration, so that fallback dead-ends. The message describes
the fallback, not the real problem, which is why it points somewhere useless.

## The fix

Reuse the credential `gh` already holds in your keychain rather than minting a
second long-lived token to sit in a dotfile. Add to `~/.zshrc`:

```bash
export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token)"
```

Then open a new terminal and start `claude` from it. The variable has to exist in
the environment Claude Code inherits, so restarting the app from an old shell
will not pick it up.

**Run this yourself.** Do not ask an agent to fetch, echo, or paste the token: a
credential that passes through a model's context has been disclosed to every
system that logs that context.

## Verify

```bash
claude mcp list | grep github
```

Expect `✓ Connected`, after which `felix setup` drops this row on its own.

## If it still fails

The `gh` OAuth token carries `gist`, `read:org`, `repo`, and `workflow`. If the
Copilot MCP endpoint rejects those, create a fine-grained PAT at
<https://github.com/settings/tokens> with read access to repository contents,
issues, and pull requests, and export that value instead.

**Untested.** Nobody has confirmed the `gh` token satisfies this endpoint's scope
requirements. If it works, delete this section. If it does not, record what the
endpoint actually wanted so the next person is not guessing either.
