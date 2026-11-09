### 2026-11-09: slice 3's units read the bytes and names that land (trust step 3, A22 and A23, 0.49.338)

**What this is.** A fix to trust step 3's slice 3 (0.49.336), on branch `claude/trust-run-tree-bytes`. The finding came from the hosted-authority spike's review (`audits/2026-11-09-trust-hosted-authority/review/round1.md` in the memory root) and was reproduced in plain git 2.56. The spec is section 8 of `audits/2026-11-08-trust-plane-step3/spec-slice3.md`.

**What changed.**
- **`lib/instrument-run.sh`.** The run tree T and the canary's copy were written by `checkout-index`, which obeys the tree's own `.gitattributes`. `working-tree-encoding`, `ident` and `eol=crlf` changed the bytes P's units read, while GitHub's squash lands the blob's bytes.
  - A22: the copy's `info/attributes` unsets every converting attribute. After the checkout, every entry's file is hashed as a blob, and its kind and executable bit are compared with its mode.
  - A23: where the filesystem folds names (probed beside T), two names of the tree, paths or directory prefixes, that fold to one are unknown SUITE. So is a name of B's tree that folds to a different one of T's.
  - Each difference names its paths, escaped. No unit runs.
- **`lib/instrument.sh`.** The blocker names A22 or A23's reason, and carries no control byte from any source.
- **Tests.** Blind part 2185, in two passes from the spec and its amendment. On 0.49.336, 5 of the first pass's assertions fail. The second pass's 3 new assertions fail on the first fix (6ab2d37e). Here it has 21 ok, 0 FAIL and 1 skip on this Mac. Parts 2180 to 2183 pass on the fix.

**Open.**
- **Reach.** The fix acts only when T is made: a candidate that changes an instrument part or the machinery. A candidate that changes an engine file and a `.gitattributes`, and no test, is judged by its own suite in the gate's and CI's checkouts, which obey the attributes too (R3, R4).
- **Not driven by 2185:** the Unicode-decomposition fold, the canary's copy, and the kind, symbolic-link and gitlink checks.
- **A false block:** a case-only rename by an honest candidate is refused on this Mac (A23).

**Release.** 0.49.338 fails closed until the founder authorizes it by name (direction row 49).
