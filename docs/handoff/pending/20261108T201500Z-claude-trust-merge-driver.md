### 2026-11-08: the change readers' merge ignores the checkout's merge configuration (S6.6, 0.49.334)

**What this is.** A security fix on branch `claude/trust-merge-driver`, separate from trust step 3's slices.
- The write-up is `docs/2026-11-08-trust-merge-driver.md`, with a PDF in `docs/pdf/`.
- The finding's cases, the spec and the review are in the memory root, `audits/2026-11-08-trust-plane-step3/checkout-merge-driver/`.
- The inventory, `docs/2026-11-08-trust-step3-inventory.md`, gains row A11.

**What changed.**
- **`lib/resolve.sh`, `_felix_merge_refs`.** The 3-way merge that `felix_added_lines` and `felix_changed_paths` take,
  when main has moved since the branch was cut, runs in a bare repository made for the call:
  - no config or attributes come from the checkout, the global config or the system;
  - the sides are named by commit id;
  - the caller's `GIT_DIR`, `GIT_WORK_TREE`, `GIT_COMMON_DIR` and `GIT_INDEX_FILE` reach neither git;
  - a TERM or INT removes it.

  Before this, a merge driver in the checkout's `.git/config`, named in its `.git/info/attributes`, kept main's side
  of a file both sides changed. So `felix merge` merged an added line and a `danger/` change that it refuses without
  the driver.
- **`lib/bind.sh`.** Once the checked copy is in force, its location is kept in a shell variable, and the merge reads
  the copy's stores alone. With the checkout's objects behind the copy, a loose object planted under the merged blob's
  id was taken as the merge's result, which hid destructive SQL from the escape scan.
- **Tests.** Blind part 2179, written from the spec before the fix, plus its rule-2 cases, also blind.

**Measured.** In the write-up: part 2179 was red first (15 of 31 on main), and its blind rule-2 cases were red
without rule 2. The cost is about 36 ms more CPU per merge the readers take.

**Open, for whoever takes it next.**
- The readers outside `felix merge` still see the checkout's objects, so a planted merged blob hides a line from the
  gate's reading. The gate's receipt is R4.
- `lib/pr-status.sh`'s merge, which feeds a report page.
- The built-in `binary` driver.
- Every other reader that runs git in the checkout, which is slice 3's class.

**Release.** 0.49.334 fails closed until the founder authorizes it by name (direction row 49). Under row 51 it lands
before slice 3, which then takes the next release (0.49.336: #501 took 0.49.335).
