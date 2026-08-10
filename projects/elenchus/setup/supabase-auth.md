# Authenticate the Supabase MCP

**Status check:** `claude mcp list` shows supabase as `Connected`.

**Dormant.** Elenchus persists through `persistence.Store`, not Supabase. The
plugin is installed but nothing in this project uses it. `felix doctor` surfaces
`database` when migrations, an ORM, or a Supabase directory appears.

## When it becomes real

1. Create the project at <https://supabase.com/dashboard>.
2. Run `/mcp` in an interactive `claude` session, pick supabase, authenticate.
3. Keep dev and production as separate projects with separate credentials. The
   guidebook is explicit (p11): production credentials stay physically separate
   from development, and destructive production SQL is never exposed to a normal
   feature session.
4. Add the production project to `stack.tsv` at `risk=high` so no automation
   flag can ever mount it.
