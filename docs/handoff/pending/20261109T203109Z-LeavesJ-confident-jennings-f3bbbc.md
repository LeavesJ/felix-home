### 2026-11-09: the hosted trust authority, designed around Felix holding main and tried on a local mock (trust-plane step 4, documents only)

**What this is.** The design for the hosted authority of design §4.8 and direction row 43, and a spike of the claims it rests on most. The founder answered its calls on 2026-11-09 and 11-10 (UTC), and the design was rewritten around his answer to the third. Nothing in `engine/` changes. Nothing was built at GitHub, and no login, account, repository, App, token, key or setting was made or changed.
- The design is `docs/2026-11-09-trust-hosted-authority-design.md`. The measurement is `docs/2026-11-09-trust-hosted-authority-spike.md`. Both have a PDF in `docs/pdf/`.
- The spike's code and logs are in the memory root, `audits/2026-11-09-trust-hosted-authority/` (its `README.md` lists each file).

**The founder's answers** (design §9 has each call, with his words where he wrote them).
1. Whose name the authority carries at GitHub: "Yours, after the proof".
2. Whether an agent stops being him at GitHub: "Agents get their own name".
3. What walls main: he sent back the first draft, whose wall was a GitHub rule that a private repository gets on a paid plan. "will this be a limitation for our future users? If so we cannot accept this design", and then "Is there no design that does not require such strict bonding to Github plans? ... it should run indpendently". He then chose "Felix holds main".
4. The throwaway proof at GitHub: "Yes, a public throwaway".
5. Where the authority runs first: "This Mac, then a server".
6. Where his yes counts: "At Felix's own door".
7. His own changes, and a judge that is wrong: "Same door, with an override".
8. What is built before March: "Build and sign now".

**Decided on 2026-11-10 at 07:23Z.** Asked what happens to this pull request, he chose "Land it; defects recorded open". The option read: "The design and your answers become main's record today. The mock's defects are recorded as open against it and fixed when the authority is actually built."

**A yes to a call is not a yes to the act.** Making a login, an account, a repository, an App, a token or a key is each still his to do, or to tell a session to do by name. None was done.

**What the design says now.**
- **Today there is no wall.** The token a session uses is the founder's admin token, felix-home's plan offers no rule on main (both APIs answer 403), and the lander's job file, the first directory on its PATH, the installed engine and the receipts are each writable by a worker (`logs/today.tsv`).
- **Main lives in the authority's own store,** which takes no push. A forge is a connector: pull requests are read from it and main is published to it. A push around the authority changes the published copy and not main, and the authority puts the copy back or reports it.
- **The founder speaks at the authority's own door,** in person, and each statement names a commit. Until the door exists his yes is read from GitHub under his name, which is worth what his token's custody is worth.
- **Twelve rules** (design §4) and **nine decisions** that are Felix's (§5.6). Each record is signed from the first landing, by a signer that is not the kernel, and nothing that decides reads a signature.
- **Budget** (§6): judging runs on the authority's machine. On this Mac that is no money and about 32 hours of judging a month at the suite's quiet time, 96 at its loaded time, for the 66 landings of the last 30 days. Today's gate on GitHub costs about $0.83 for each landed change.
- **Migration** in stages 0 to 6 (§7): a rehearsal in shadow under a second login on this Mac, his word, the authority takes main, then a small rented server.

**Measured, on the mock** (74 cases with main in the authority's store, 46 in each of the first draft's two modes; written over two days by one author and two reviewers, one round each; an open set). The final run, on 2026-11-10 from 00:47Z, had no row that ended otherwise than expected.
- **With main in the store,** no request a worker made moved main, except through the judge or the founder's word at the door. The worker's pushes to the forge took there, since the forge has no rule in this mode, and each changed the published copy alone.
- **A worker holding the founder's token for the forge** moved no main and got no authorization, release or override while his word was read at the door. In the interim, where his word is read from the forge, the same token authorized a direction change and removed his hold (D1i, D2i).
- **Still landing in the mock:** an instrument that takes candidate code into its own process (E7), and a label hold shed by sending the same commit up under a new branch name (H6).
- **Breaks found and closed in the mock:** a hold at the door shed by opening the change again (R1, R2, the second review); an authorization and an override each used a second time (H7, O4); a foreign commit overwritten with no copy kept (R4); a planted branch that kept the published main from being sent again (P6). Before the first draft: the units' copy was not the tree that landed (X1, X7).

**Open against the mock, by his decision.** The session that designed the door found six things on a copy of this mock on 2026-11-10 (design §8, and "Open against this mock" in the spike report). None is fixed here.
- The mock's door reads his word without its order, so a release passes over a hold given after it (that session's case V5f).
- An override passes each hold (V6f), and names a head and no tree, so the tree that lands can be one he was not shown (V31f).
- The kernel's founder-path rule missed a path with a newline.
- The battery's case T1 has a default outcome equal to its expected word. In the final run its race was staged in each mode.
- The interim, where his yes is read from GitHub, does not stand against a session that drives his signed-in browser.

**Not shown.** That a login holds: the mock's wall is a sandbox profile. That the door can be made so a session cannot imitate the founder there: its mechanism is not designed. Whether GitHub does what the connector needs: `spike/wall-test.sh` was written for the first draft's questions and has never run. Confinement on Linux, Felix's own suite as the judge, and a signer apart from the kernel are not measured either. The store mode was written and reviewed over one day.

**Asked of direction.**
- **A row for signing.** His answer to call 8 brings the signed record forward from "Not before March". Direction does not say so yet.
- **The 11-07 design's §5 and §4.8** name GitHub's merge queue for the final merge and a token that cannot push to main. Design §10 lists what this revision replaces there.

**Follow-ups, not done here.**
- **The door's mechanism** (design §5.5), and whether a session that drives the founder's screen can get past it.
- **The throwaway proof.** `spike/wall-test.sh` has to be written again for the connector's questions. It needs a public repository and identities that the founder makes.
- **A reader with no memory** accepts a published copy that was moved back to an earlier genuine main, until the authority's next tick (spike R7). A signed and dated statement of the tip is not designed.
- **What installs the engine on this Mac** takes main from GitHub, by files a worker can write (design §8).
- **The engine's run tree obeys the candidate's `.gitattributes`.** `lib/instrument-run.sh` (`_felix_instr_repo`) writes it with `read-tree` and `checkout-index`. On git 2.56.0 a blob under `working-tree-encoding=UTF-16LE` was written out as UTF-16, and a byte search of the copy missed text the blob holds. This Mac's filesystem also folds case under those units. Both belong to step 3, and a follow-up session was started to measure them.

**The founder's next acts,** each his to make or to order by name: the second and third logins on this Mac and the commit main starts from (stage 2); the public throwaway repository and its identities (the proof); the App, after the proof; the agents' own identity at GitHub; the server's account and fee, once the rehearsal has numbers; the daily ceiling on judgements.

**Release.** None: documents only. The pull request was labelled needs-founder for his calls. With his decision above the label comes off, and it lands on green as any other pull request does.
