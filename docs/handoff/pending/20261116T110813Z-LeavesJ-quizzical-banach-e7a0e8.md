### 2026-11-16: what the authority's login runs from: the drop, the engine copy, the lock, and condition e reading what the copy relies on (trust step 4, the setup slice, 0.49.351)

**Scope.** The three things slice 1 (0.49.343) left open for the founder's step 3: a source the authority's
login can read, the engine copy it runs, and a program that locks this macOS; and condition e reading what that
copy relies on. The judge, landing, a connector, a signer and keys are not in it. The document is
`docs/2026-11-16-trust-step4-authority-setup.md` (PDF in `docs/pdf/`); the spec (rev 3), the review record and
the rehearsal log are in the memory root, `audits/2026-11-16-trust-step4-authority-setup/`.

**Built.** `felix authority publish` (`lib/authority-publish.sh`) writes a bundle to
`/Users/Shared/felix-authority/source.bundle`. `bin/authority-engine COMMIT [SOURCE]` copies that commit's
engine from git's objects into the authority's `~/.felix/engine/COMMIT` with the root-owned git, and writes
launchers in `~/.felix/bin` that run it with an empty environment and the system's `PATH`. `bin/lock-macos`
locks through the system's lock call and exits 0 only on reading locked. Condition e reads the whole engine,
the running git's exec path and every directory above, a directory not there yet, a link on the way that leads
to no directory, and a lock that is a link.

**State when this was written.** Branch `LeavesJ/trust-step4-authority-setup`; blind parts 2190 to 2192, then
the build, two reviews (13 findings, none rejected), two automated security reviews (3 findings), each fixed.
Each part of the slice and of slice 1 passes alone. The gate and the PR follow this section.

**Never run by this session or its agents:** `lock-macos` with no argument (it locks the screen of whoever is at this Mac),
`reach-probe --run`, anything as the authority's login.

**The founder's acts,** all his, none done by merging: finish the login (password, fingerprint); the sharing
settings (the authority's Public folder is shared with guest access); after this lands, `felix authority
publish` at his desktop; the six lines of the document's §7 (eight since 0.49.356, whose section replaces these acts) at the authority's Terminal with the printed
commit, then the `next:` line with `--workers a14808`; restart, the first start at the console, the reach test,
its pass or fail at the console.

**Left open:** the document's §8 and the spec's section 8. The nearest: what condition e does not read (a
program in a `PATH` directory that is a link, the libraries a program loads, the third login `dengs`); what the
authority's shell runs at start; Remote Login admitting admins.
