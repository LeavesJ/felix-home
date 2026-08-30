# Authenticate the GitHub MCP server

**Check:** `claude mcp list` shows `plugin:github:github` as `Connected`.

## You may not need it

If `gh` is authenticated, it already covers issues, pull requests, secrets,
labels, branch protection, and CI logs. The MCP is a nicer interface inside a
session, not new capability.

## It does not use OAuth

The plugin ships an http server whose header interpolates an environment
variable:

```json
"headers": { "Authorization": "Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}" }
```

Unset, the header becomes a bare `Bearer`, the server rejects it, and Claude Code
falls back to OAuth discovery. GitHub's endpoint does not support dynamic client
registration, so that fallback dead-ends with a confusing message about
incompatible auth servers. **Choosing Authenticate in `/mcp` cannot fix it.**

## The fix

Add a line to `~/.zshrc` that exports `GITHUB_PERSONAL_ACCESS_TOKEN`, setting it
to the output of `gh auth token`. Reuse the credential `gh` already holds in the
keychain rather than minting a second long-lived token to sit in a dotfile.

Then start `claude` from a **new** terminal. The variable must exist in the
environment Claude Code inherits.

**Type it yourself, and do not hand this step to an agent.** Not as a shell
command it runs for you either: a credential that passes through a model's
context has been disclosed to every system that logs that context, and an
`echo … >> ~/.zshrc` is exactly the shape that looks harmless enough to
delegate.

## If the check still fails

It reads the environment it runs from. An older shell reports
`Authorization header is badly formatted`, which is the unset-variable case, not
a bad token. Check which shell you are in before concluding it failed.

If the `gh` token's scopes are rejected, create a fine-grained PAT with read
access to contents, issues, and pull requests, and export that instead.
