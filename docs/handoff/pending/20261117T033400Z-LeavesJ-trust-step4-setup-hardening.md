### 2026-11-17: the setup slice's own checks, hardened (trust step 4, stage 1, 0.49.354)

**Scope.** What #518 (0.49.351) left weak in the checks the authority's login relies on before anything of its
own runs: `publish`'s directory and those above it, `authority-engine`'s git, its helper directory, `HOME` and
the directories it writes, condition e's reading of `PATH`, links and the directories above the code, and
step 3 of the document's §7, where the founder reads the commit he types. No new command is added. The
spec (rev 5), the review record, the probes and the run logs are in the memory root,
`audits/2026-11-16-trust-step4-setup-hardening/`; the document is revised in place
(`docs/2026-11-16-trust-step4-authority-setup.md`, PDF in `docs/pdf/`).

**Built.** H1 to H14 of the spec, in `bin/authority-engine`, `lib/authority-publish.sh`, `lib/authority.sh`
and a new `lib/authority-walk.sh` (the walk above the code, and on macOS a flag rule that excuses a directory
only when each child on the code's paths carries `sunlnk` or `schg`, or `restricted` while SIP is on).

**State when this was written.** Branch `LeavesJ/trust-step4-setup-hardening`, main (0.49.352) merged in.
Blind parts 2193 and 2194, red on main first; a review of the build (sixteen findings), a rehearsal of steps 3
and 4, and three automated security reviews, each answered with assertions shown red on the commit it
answers, or by a probe where no test can reach. Each part of the slice, slice 1's and the three lints pass
alone. Part 2190 renames one assertion (775 to 705), an instrument escape: the founder merges this by hand.
The record, the gate and the PR follow this section.

**Never run by this session or its agents:** `lock-macos` with no argument, `reach-probe --run`, anything as
the authority's login.

**The founder's acts** replace the 0.49.351 section's: step 3 reads COMMIT on his phone from the merged
commit's own page of a pull request whose number he fixed, all 40 characters, 0.49.354 or later; step 4 is
eight lines, not six. Until this lands he takes COMMIT neither from what `publish` prints nor from "the pull
request released last". The rest is as the 0.49.351 section says, and none of it is done by merging.

**Left open:** the document's §8, with rows for who holds GitHub write, what the eight lines rely on before
`authority-engine` reads anything, what the flag rule trusts, and upgrading an existing copy. Part 2183's A14
flake under load is the pipe-readers session's (two removers of one run tree), not this change's.
