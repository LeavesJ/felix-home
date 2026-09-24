## 0bm. 2026-09-18 — the public snapshot brought forward and found uninstallable, and ECC read against v3.2

The founder's instruction was to update the public repository first and then
go deeper on what ECC's best-known skills can do for the v3.2 state. It also
closed the first item of §0bl's queue, and how that came about is worth
reading, because this section was first written saying the opposite.

**The commission had already been re-stamped, and this section said it had
not.** `commissioning.log` holds a full run at 2026-09-18T20:31:38Z, two
minutes before `says.log` records this session's first prompt at 20:33:54Z.
It was a person's, by elimination: the session's only commission call was
`--status`, which writes nothing, and the unattended path appends to
`state/commission/felix.bg.log` whether it runs or fails, and that file was
last written on 2026-09-12. The first draft of this section, already pushed
to #262 as `ed03691`, said #262 "still waits on `felix commission`", copied
from §0bl and not read from the tree. A dry run of `felix merge` is what
contradicted it. §0bh and §0bl record the same failure: a claim about state
that was recalled and not read.

| | |
|---|---|
| public | `LeavesJ/Felix` main at `f6341ba`, engine **0.49.121**, by `LeavesJ/Felix#1`: two commits, `06393be` and `5455d56`, merged on green CI |
| cut from | felix-home main `a8ab281` (#261) |
| suite on the snapshot tree | 2441 passed, 0 failed, 3 skipped, run locally before anything was pushed; the public `suite` workflow passed on the pull request in 2m33s |
| private | **#263 merged** as `53eaf24` through `felix merge`, after a fresh gate on its tree (2457 passed, 0 failed, 1 skipped). The home was fast-forwarded and `felix install` run from it: **0.49.122** is in the registry and its cache entry is byte-identical to the home's engine. It reaches sessions that start after this one; this session's hooks ran 0.49.121 throughout |
| this section | rides on #262 with `docs/2026-09-18-ecc-against-v32.md` and a `snapshot` maintenance row, on a branch that now has main merged into it |

### The snapshot rule, derived and then proven

The first snapshot was made by hand on 2026-09-13 and its rule lived in nobody's
hands, which is why it fell twenty-two pull requests behind. Comparing blob ids
showed it was cut from `4578ae8` (#232) with five files changed on the way out,
and the rule below, applied to `4578ae8`, reproduces the three scrubbed files
byte for byte. That is the evidence that it is the rule and not a guess at it.

- **Published:** `engine/`, `projects/felix/`, `.gitignore`, `README.md`, and
  since today `.claude-plugin/marketplace.json`.
- **Withheld as consent:** `projects/felix/autonomy` and
  `autonomy.commission`. `projects/felix/exceptions.tsv` ships only while it is
  byte-identical to `templates/exceptions.tsv`; the build stops if it holds a
  row, because a grant is a person's consent (§0ba).
- **Withheld as private:** `HANDOFF.md`, `docs/`, `.felix`, every other
  directory under `projects/`, `.github/workflows/gate.yml`.
- **Public only:** `LICENSE`, `.github/workflows/suite.yml`, and the public
  `README.md`, which differs from the private one and has not moved since.
- **Rewritten:** `remote_match` to `LeavesJ/Felix`, and other governed
  projects' names in `tests/run`, `qualification.tsv` and `stack.tsv`.
- **Built** by `git archive` into a scratch directory, staged onto a clone of
  the public repository through `--work-tree`, so nothing is deleted by hand
  and a removal upstream is a removal downstream.
- **Commit identity:** this machine's default git email is not the address the
  public commits carry. The first local commit took the default and was
  re-authored before it was pushed. Set it in the clone before committing.

### What the audit caught that the rule did not

**The rule that scrubs must not be the rule that audits.** The scrub matched
two spellings. A case-insensitive grep afterwards found a third: an upper-case
shell variable in a qualification control added since the first snapshot. A
fragment search found two more, a name assembled from two halves in a
commented control and a regex-metacharacter fixture in `tests/run`. All three
spellings **have been public since 2026-09-13**: they are in the first
snapshot's history, which a new commit does not change. It is a project's
name and nothing about it. Whether that is worth rewriting five public commits
is the founder's call, and a deny row refuses the forced update from a session
either way.

**A scrub can break a command.** #236 gave controls a premise column holding a
path under `projects/`. Replacing a name with a phrase put spaces in that path
and made `test -f` a usage error. Paths now have their own replacement, ahead
of the prose one.

**The published engine could not be installed.** `felix install` registers the
checkout as a directory marketplace, and the CLI wants
`.claude-plugin/marketplace.json` at the repository root and does not resolve
upward (#66 measured this). The first snapshot published `engine/` and left
the root manifest behind. Measured today in a scratch HOME against the public
tree: without the file, "Marketplace file not found"; with it, the marketplace
registers and the plugin installs at 0.49.121. The README's first instruction
had failed for anybody who tried it for five days, and the suite cannot see
it, because the suite builds its own roots and the omission only exists in a
checkout nobody on the authoring side installs from.

**A deny row refused the last step, and it was left alone.** #261's row
against pushing to a `main` matches command text and cannot tell one
repository from another, so it refused the fast-forward of the public main.
The pull request was merged instead, which is what the row says to do, and the
two audited commits landed with their ids unchanged.

### Not established

Whether `felix gate` can pass in the public repository's CI. `suite.yml` says
it cannot because two independence controls have no second project to name,
and #236 made those controls not apply, so that reason is stale. An attempt to
run the gate as a clean runner would (an empty HOME) failed for a reason that
exists only in the attempt: the gate's own `tests` check invoked the real
`claude` CLI, which wrote a `known_marketplaces.json` into the empty HOME with
no felix entry, and `marketplace_root` then read blind. A runner has no
`claude`. The public workflow still runs the suite and its comment still gives
the old reason.

### ECC, read at source

`docs/2026-09-18-ecc-against-v32.md`. Four read-only readers over ECC 2.2.1 at
`e04ea0b`, the load-bearing claims re-read by hand. In short:

- v3.2 names ECC three times, always as a content provider and discovery
  worker that proposes and never decides. The engine's one discovery request
  names no source to consult, so the Baseline Coverage Compiler is built as
  `projection -> host reasoning -> candidates`, and the host is who dropped
  rate limiting three times.
- ECC's `security-review` states rate limiting on every new endpoint. The
  canonical omission was one named file away.
- ECC's flagship mechanisms (`verification-loop`, `eval-harness`, the santa
  loop) are prose in which a model grades itself: MODEL_CLAIM, no use on a
  receipt-driven path. `tdd-workflow`'s red and green commit pair is the one
  tree-bound artifact.
- GateGuard reads nothing: it denies a first touch, records the key, and the
  bare retry passes. Its runtime holds five blocking points outside obligation
  state, one Stop hook that rewrites the tree after a gate has judged it, and
  17 MB of captured tool calls that nothing reads.

What it says to build, all bash and git: a `coverage.tsv` from grounded
predicate to provider text, with citations the engine verifies offline, which
is what opens admission pathway 3; trust recorded per provider **surface**
rather than per plugin; a red and green pair as one `accepted_evidence`
alternative, replayed by the machinery `tests/red` already has; counts on
lessons, for the historical miss rate spec §10 needs; challengers as rows.

**The founder's, added to §0bl's list:** `ECC_HOOKS_ENABLED=false` in the user
settings keeps every ECC skill, agent and command and turns off its hooks. The
document's §4 is the case for it. It is the founder's file and the founder
chose to install ECC, so it is not Felix's to set.

**Felix's, added to §0bl's queue:** the coverage table as a design, with three
refuters before any build; the snapshot as a command, so the rule above is a
table and an audit instead of a section in this file; and what actually stops
`felix gate` in the public repository. `routes.tsv` is in the commission's
table set, so a route naming ECC's reviewers stales the receipt again: batch
it with the next change that already needs a re-stamp.

`felix maintenance` now carries a `snapshot` row at fourteen days. The
snapshot fell behind while that command said nothing was due, because nothing
was checking.

