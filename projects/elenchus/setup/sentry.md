# Create a Sentry project and mount its MCP

**Status check:** `claude mcp list` shows a `sentry` server as `Connected`.

**Dormant.** Elenchus is deployed nowhere, so there is no production to observe.
`felix doctor` will surface `observability` the moment `sentry-sdk` appears in a
dependency manifest, and this row activates then. Do not do this early.

## When it becomes real

1. Create an account at <https://sentry.io> and a project of type **Python**.
2. Copy the DSN from **Settings → Projects → [project] → Client Keys**.
3. Add `sentry-sdk` to the `web` extra in `pyproject.toml` and initialise it in
   `src/elenchus/web/app.py`.
4. Put the DSN in `.env` locally. It is not a secret in the strict sense, but it
   is machine-specific, and `.env` is already gitignored.
5. Mount the MCP for triage from inside a session:

```bash
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
```

6. Authenticate it with `/mcp` in an interactive `claude` session.

## The invariant that applies here

Elenchus invariant 10: log the traceback server side before genericizing the
wire. Sentry is the server-side copy. Until it exists, a caught error whose only
copy rides the client response is destroyed by the refresh the product itself
recommends.
