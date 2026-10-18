### 2026-10-08: a commissioning check says it could not be asked by exiting 2

**Defect.** A commissioning row's check had two answers: yes (0) and no
(anything but 126 and 127). It had no way to say it could not ask. Two seeded
rows could not be asked, and both read `held`. That means OBSERVED, a person's
queue, a receipt that passes, and a merge the commission blocker does not stop.
- `reach`, with claude/declared-unread-readers. `felix_toolbox_unwired` prints
  `?<TAB>the capabilities this project declares could not be read` and
  returns 2. Before that branch the row read `done`.
- `discover`, with no current discovery cache (absent, written under an older
  stamp, or unreadable). `felix_discover_cache_current` returns 1.

**Decided: a check's exit 2 is "could not be asked".** The row is `unknown`,
class UNKNOWN, and the receipt is `indeterminate`.
- Why 2:
  - grep, test, diff, cmp and make -q return 2 when they could not answer.
  - The `when` column already reads 2 as unknown.
  - The engine's lookups already return 2 for a list they could not read.
- 126 and 127 stay unknown. Every other status stays held, deaths included,
  as 0di ruled.
- A check that does not parse is unknown. It is parsed first, as the `when`
  is. eval returns 1 on bash 3.2 and 2 on bash 5, so without the parse the row
  read held here and unknown on CI. Two pinned when-crash assertions flip
  with it.
- A real run still runs a `felix:` answer for a row whose check exited 2,
  then asks again.
  - Those rows read held before, so the same answers run.
  - `discover --adopt` fills the cache its own check reads.
  - No other unknown runs its answer.
  - The detail is one string, `_felix_commission_unasked`, which the run loop
    recognises.

**The rows** (in the template and in every projects/*/commissioning.tsv):
- `reach` carries the lookup's status in its mark, as `/S.` below 128, and
  exits 2 on `/2.`.
- `discover` exits 2 when the cache is not current (status 1). Any other
  status from the cache lookup reads held.

**Review** was adversarial and run after the fix. What it found:
- **A lookup that ends its check's shell with exit 2, rather than returning
  2, makes its row unknown.** The status reaches the end of the check through
  the `&&` chain. This is pinned for every seeded row's first lookup, so a
  change to it shows.
- **A `felix:` row whose check does not parse runs nothing.** Under the old
  rule it read held and its answer ran.
- **The discover cell's `*)` arm was unpinned.** Changing it to `exit 2`
  passed every assertion. Three cases now read held for statuses 3, 4 and
  127, and that mutant fails all three.
- **Two pieces of wording were wrong.** The header text in commission.sh and
  the felix CLI's unknown-rows text said only the machine could clear an
  unknown row. A run whose answer makes the row askable clears it too.
- **The template header test looked for three words.** It now reads the
  sentence.
- **Each after-review block ends on a marker that is counted.** Under bash
  3.2 a block can stop early and emit nothing. That happened once, when a
  `case` inside `$( )` ended the substitution at its `)`.

**For the founder, when the table branch reaches you.** escape.sh stops a
merge on an indeterminate receipt, and never on held.
- A `discover` row whose run cannot fill the cache now reads unknown and
  blocks a merge, where before it read held and did not. That happens offline,
  or when a marketplace cannot be read.
- The same is true of `reach` over a capabilities list that cannot be read.
- Both are the honest state, but a project that commissions offline cannot
  `felix merge` until a run fills the cache.
- The escape.sh comment names this case.

**Two branches.**
- claude/commission-check-unasked changes the engine and no table. It lands
  by `felix merge` at its carrier slot (position 10).
- claude/commission-unasked-rows is stacked on it. It changes the template
  and the eight project tables.
  - commissioning.tsv is in FELIX_ESCAPE_TABLES by basename, and
    `_felix_escape_shrank` reads a changed row as a removed one. So the
    template escapes just as the project tables do.
  - It lands as a draft marked needs-founder, by `gh pr merge` on his yes,
    after the engine branch and last in the batch.
  - Then one re-stamp. The policy hash moves, so every project's receipt goes
    stale, along with the felix and elenchus commission grants.

**Built as contract, blind assertions, fix, review.** The contract is C1-C8.
An author who saw no fix wrote the blind assertions:
- the engine branch's share (C1-C3) is 8cdd71d0;
- the table branch's share (C4-C8) is 9cc705c1.

The section runner covers the 0di header up to the engine manifest:

| Block | Branch | Origin/main | Engine branch | Table branch |
|---|---|---|---|---|
| Engine branch's block | 174/0 | 152/22 | | |
| Table branch's block | 211/2 | 176/37 | 198/15 | |

- The engine branch's 22 failures on origin/main are:
  - 11 blind cases;
  - 10 lookups that end with exit 2;
  - 1 `felix:` row that does not parse.
- The two flipped when-crash assertions lie outside that range. Run from the
  commissioning header they fail on main and pass on the engine branch: 539/2
  and 541/0. The runner then stops on a variable the full suite sets earlier.
- On the table branch, the 2 failures are the real-engine reach cases, which
  need claude/declared-unread-readers. With that branch's toolbox.sh,
  detect.sh and discover.sh overlaid, the table branch reads 213/0.

**Project tables** under the 0di and exit-2 blocks:
- bazaar, behaviorchangebench, felix, sv2-apps and webapp read like the
  template.
- elenchus and veldra also fail the 6 obligations cases, because neither has
  that row (as at 0di).
- elenchus-capital-research's other eight rows still have the pre-#393 shapes
  it was tracked with in #408. On main it fails 45 of 0di's 123. On the table
  branch it fails 36, plus the 2 reach cases.

**Waits on** claude/declared-unread-readers, for the reach case to mean
anything. Then main is merged into both branches and the section runners run
again, then the carrier's slot for record, red and gate.
