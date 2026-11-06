### 2026-11-06: a declared cli is a name, a route step run as a program is used, the session id is read in a window

**What changed, in one line.** Three gaps that the cli-reach change (0.49.321)
left open are closed, under section 9 of `docs/2026-10-31-cli-reach-spec.md`.

**1. `stack.tsv`'s own `cli` kind** (N7 to N9). `felix_ledger_cli_names` now
adds the second field of each `cli` row of `stack.tsv` (elenchus declares
`cli strix-agent`) after the `routes.tsv` play entries: once each, N2's byte
rule, 32 in all with the routes first. A session that runs `strix-agent` is
recorded as `cli strix-agent`, and the fold, which already let a `cli` reach
suppress the zero row of a declaration of the same name, no longer writes it.

**2. A route step run as a program** (U1 to U6). `felix_route_step_used`,
`felix_route_due`, `felix_route_skipped` and `felix_route_render` take an
optional session ledger. A step that is a name counts as used when the ledger
holds a line that is exactly `cli<TAB>name` and ends in a line break. The
prompt hook hands the ledger to `felix_route_due` and the render, and the Stop
hook to `felix_route_skipped`, for a session id that can be a file name
(`felix_route_ledger`). So graphify, run from the shell, is no longer the step
the route keeps naming as due, nor one Stop calls skipped. The ledger is read
once into a variable and searched with a `case` (a line-by-line loop cost 0.35
s of CPU on a 325 KB ledger, the review found; the one read costs 12 ms).

**3. The session id is read in a window** (W1 to W6). `felix_ledger_session_id`
looks only in the first 32,768 bytes of the payload, and `hooks/post-tool`
hands it the first 32,768 characters instead of the payload. Claude Code writes
the key second, so no real payload is affected; a payload whose first
`session_id` lies past the window now records nothing, as one with none does.

**CPU of `felix_ledger_session_id`, measured 2026-11-06**, bash 3.2.57, per
call, the minimum of 7 to 9 runs of 20 calls with the setup subtracted, by
`getrusage` (the Mac was at load 100 to 200, so a single run varied by a
factor of three and the minimum is what is reported):

| 4 MB payload                         | before  | after (function only) | after (hook cuts too) |
|--------------------------------------|---------|-----------------------|-----------------------|
| `session_id` first                   | 24.5 ms | 25.0 ms               | 5 ms                  |
| `session_id` absent                  | 55 ms   | 21 ms                 | not run (a 32 KB string, so about the first row) |
| (an empty function, same argument)   | 19 ms   |                       |                       |

The cut in the function alone does nothing for a payload that has the key
first: 19 of the 25 ms is bash copying a 4 MB string into the function's
argument, so the hook cuts it before the call. That one is 20 ms. The
Bash-payload reading and the `sed` over the payload in `felix_ledger_signal`
(not changed here) still handle the full payload.

**Built, and checked.**
- Spec amendment, then 204 blind assertions in parts 2190, 2191 and 2192 by an
  author who did not see the code. Run at the base (the export of the tree
  before the change): 160 ok, 44 FAIL, across N7, N8, U1, U4, U5, W1, W3 and W4.
  Run on the change: 204 ok after three fixes: two were the first
  implementation's (a doubled tab in `stack.tsv` shifted a field; a last
  ledger line with no newline counted) and one was an assertion that read the
  "rest" half of `felix_route_due`'s output as the due list, narrowed to the
  due field.
- Parts 0996 and 0998 (the locale lints): 99 and 112 ok on the change.
- One review (Opus, read-only): no blocker. Two should-fix, both fixed (the
  per-step line loop above, and a stderr leak on an unreadable ledger). Notes
  taken: N7 now says a carriage return is not stripped and what the fold does
  with a doubled tab; W6 records the hook's cut.

**Not done, and why.**
- `hooks/stop` takes its session id with a `sed` that keeps the last
  `"session_id"` key in the payload, where post-tool keeps the first. That is
  older than this change and it keys the route state too; with the ledger now
  chosen by it, a payload with two keys would point Stop at another session's
  ledger. Claude Code writes the key once at the top level. Left as it is.
- The fold reads `stack.tsv` with a tab in `IFS`, which runs two tabs together:
  a `cli` row with an empty second field and a third field keeps a zero row
  under the third field's name. Not changed (N7 says so).
- D6's standalone-skill filing is untouched.
- Bash 5 and gawk were not run here (this Mac has neither); CI runs both.
