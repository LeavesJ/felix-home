## 0bp. DECIDED 2026-09-21 — `projects/bazaar` is tracked, and its gate keeps its own log

The founder handed Felix the call that §0aw through §0bh carried as "stays
untracked, the founder's call". **Decided: `projects/bazaar/` is committed
like elenchus, felix and veldra.** `projects/webapp/` is not decided here.

**Why.** It governs a live checkout: `~/Documents/BlackBoxBazaar` carries
`.felix` = `bazaar`, took commits through 2026-09-18 and holds uncommitted work
today, so every session there is bound by a constitution, a gate and ten tables
that existed on one iCloud-synced disk and in no history. Nothing recorded a
reason to keep it local. `felix new bazaar` wrote it into the home on the
take-home's last night and nobody committed it. Read in full before
committing: no key (only anvil's public defaults and the cross-seam keccak
vector), no third party's material, memory already outside the tree. Tracking
changes no exposure, because this repository is private (§0) and the §0bm
snapshot withholds every project but felix. Left untracked, no check can read
it: the suite enumerates `git ls-files -- projects`.

**Rejected: local, because the take-home is over.** The deadline ended and the
project did not. Retiring it means taking `.felix` out of that checkout, which
is the founder's act, and then `git rm -r projects/bazaar` with the history
kept. It does not mean leaving live doctrine uncommitted.

**Landed as two commits** so the fix has something to be a diff against: the
directory byte for byte, checked against a sha256 manifest of the home copy
(the empty `setup/` is not carried; the engine reads `setup/<id>.md` only when
present), then the fix. `gate.sh` wrote the agents' `npm test` output to a
fixed path under `/tmp` and printed its tail on a FAIL, the class fixed today in
felix, elenchus and veldra. It now writes a `mktemp` log under `${TMPDIR:-/tmp}`,
deletes it on a pass and names it on a failure. On a fixture driving the gate
twice at once, the old script printed run b's output under run a's FAIL and the
new one did not. The real checkout gates ok on it.

**What covers it, and what does not yet.** The class assertion ("no project
script names a fixed path under /tmp outside its comments") reads tracked files
only, so tracking is what brings bazaar under it. But on 2026-09-21 that
assertion exists only in `9d5c667`, on local branch
`claude/unruffled-tesla-8e4e41` (head `0114947` when checked): no remote, no
PR. The felix gate's own fix merged as #276 while this was in review. Until that
branch merges, nothing on main checks any project script for a fixed path. Replayed by hand, its loop flags the committed original and
passes the fix. Its barrier test drives elenchus and veldra only; bazaar joins
it after that branch merges.

**Trap for the home, measured.** With this on main, `git pull` in the home
aborts: git will not overwrite an untracked file even when it is byte-identical
(reproduced on a scratch repository). Move the home's untracked
`projects/bazaar/` aside before pulling, and diff it against the first commit
afterwards.

