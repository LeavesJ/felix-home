### 0bu. 2026-09-23 — Phase 0: the Elenchus candidates checked, deny rows read the command the shell runs, three small items

**Deployed from this session: engine 0.49.149 (#299) and 0.49.152 (#301).**
#298 added rows to `projects/felix/risk.tsv`, a commissioning table, and from
then `felix merge` refused every felix-home PR until the founder re-stamped
the commission, which he did on 2026-09-23; #300 and then #301 merged. The
engine queue now, agreed between the sessions by message: #306 (the audit
decode fix, 0.49.153), #307 (overnight mode, another session's, .154), then
this session's #303 (.155) and #304 (.156, last on purpose). Each merge owes
everyone behind it a red re-run; #303 and #304 also need main merged in and
their versions re-bumped, and they are gated on an older main.

| PR | What | Engine |
|---|---|---|
| #299 | The `granted` count in the obligations sentence is asserted every run, against a fixture that makes the sentence print; the suite's standing skip | 0.49.149, deployed |
| #301 | Deny rows are refused only when they still match the command the shell runs: heredoc bodies, quoted messages, comments and line breaks stop being read as commands; `lib/deny-read.sh` | 0.49.152, deployed |
| #303 | The repair ceiling and the auto-merge streak read the gate workflow's runs alone (`gate_workflow` in project.json, default gate.yml); the unattended template proceeds only when `felix repair` exits 0 | waiting, then 0.49.155 |
| #304 | The decision epoch is the same under any PATH: the instrument token is provenance and leaves the topology hash. Lands last: every receipt and the Elenchus candidates read stale once after it deploys | waiting, then 0.49.156 |

**The Elenchus candidates, checked (roadmap Phase 0, for Sep 26-27).** The six
unverified rows of the 2026-09-22 blind request were checked against the code
at `a45a985` and against every place Elenchus keeps a record, one agent each,
each verdict attacked by a second. The founder has
`~/.felix/memory/elenchus/commission/pdf/candidates-checked.pdf`; source and
the full verdicts are beside it (`candidates-checked.md`, `.json`). In short:
all six evidence commands fail on main for the reason they name and flip on
the obvious fix, and all six checkers are flawed (each can pass with its hole
open, or fail a reasonable fix). The launcher's `0.0.0.0` default was found by
Elenchus's own security audit of 2026-08-31 and dropped: it reached no report,
no DEVLOG item, no table. The untested forecast route is the strongest new
one: renaming it leaves 1,439 tests green. The roadmap listed five candidates;
`served_route_has_http_test` was the sixth, left off. After the epoch change
deploys, these rows read `stale` in `felix obligations` once; that is the hash
definition moving, not the facts.

**The deny change, and what measuring it found.** 175 refusals had been logged
(`says.log`, felix and elenchus). Replayed: 38 are now allowed, every one read
and confirmed prose or data; 132 still refused. Of those 132, more than 100
are real commands in scratch fixture repos (a marker written by `printf`,
`git remote add`, `update-ref refs/remotes`), the largest source of false
blocks, which no regex can tell from the governed checkout. 140 cases written
blind: the new reading agrees on 128, the old on 82. Three adversarial
reviewers found ten defects between them, all fixed: the semantic ones are
assertions, the performance ones measured. Their out-of-scope findings are
filed below. The
reader was run under macOS's BWK awk here, and its assertions passed on CI's
Ubuntu runner; mawk and gawk were not run locally.

**Filed as separate tasks, several already running in their own sessions:**
deny rows scoped to the governed checkout; the widening direction (commands a
row names that the raw string never matched); three rows that refuse reads and
dry runs (escape tables, a person's); `felix_deny_subject`'s bash 3.2 cost on
large payloads (12-45 s on some 31K payloads, every call); `lib/audit-read.sh`'s
one-character `split` on BWK awk; Elenchus's copy of the unattended step.

**Still open in Phase 0:** the marker deny rows for Elenchus and Veldra (after
#301, so the prose refusals do not spread; Veldra has no deny.tsv); the
obligations request on a second project, answered blind; the GitHub runner
probe with no `claude` CLI. The founder admits or refuses the Elenchus
candidates on Sep 26-27 and re-stamps the commission after #298.

**Traps paid for this session:**

- BWK awk splits on every line break when `split()` is given a
  one-character string separator, whatever RS is. Use a regex separator.
- bash 3.2's `${s//pat/rep}` is quadratic: 14 s over a 31K command. A hook's
  per-call work is `[[ =~ ]]` or one awk process, never parameter expansion.
- An awk program held in a bash single-quoted string may hold no apostrophe,
  not even in a comment; one silently disabled the hook in a working copy.
- An "allowed" assertion whose payload the old matcher already allowed tests
  nothing: check every such payload is refused by main's library first.
- A PR with conflicts gets no `pull_request` CI at all; merge main and push.
- `felix pr --create` opens a draft when the gate has not passed on that
  tree; `gh pr ready` after the landing gate, then `felix merge`.
- zsh reads `$var:e` in `git show $mb:engine/...` as a modifier; brace it.
- Engine merges went through one queue agreed between sessions by message
  (#298, #300, #301, the audit-decode fix); each merge costs everyone behind
  it a red re-run.
