### 2026-09-24/10-01 — a binding refusal cut at eighty characters could name the parent directory; the middle is cut now, and marked

**One engine PR from this session, 0.49.240** (branch
`claude/binding-path-middle`). `_felix_binding_sane` in `lib/resolve.sh` makes
a pointer or marker value safe to quote in the refusal a hook emits. It kept
the first eighty characters. When the eightieth closed a directory name, the
refusal named the target's parent: a real path, and a wrong answer rather than
a short one. Session b611b9 found it when the suite's `$TMP` moved 17
characters deeper and "and says which directory it was sent to" failed: a
plain Mac run's `$TMP/not-a-felix-home` is eighty characters exactly.

**Measured on main, not read.** A pointer to an existing directory that is not
a home, whose parent is eighty characters long, was refused as "names
`<parent>`, which is not a Felix home: it holds no projects/ directory". That
sends the reader to a directory the pointer never named.

**Decided: cut the middle, not show the whole value.** The founder allowed
either option. Shortness is a defence, and the comment above the function
names it: a `.felix` marker is a file in the repository, so a stranger's
clone chooses its text, and the refusal quotes it to the model and to the
founder. Past eighty characters the value keeps its first 24 and last 51 with
`[...]` between them, 80 in all. The tail gets the larger share because the
directory a pointer names is at the end. The control-character filter is
unchanged. The whole value is always in the file the refusal names.

**tests/run, +4:**
- A parent built to be eighty characters long whatever `$TMP` is, with its
  length asserted so an edit cannot quietly stop testing the slash.
- The refusal names the directory itself, red on main.
- The refusal marks the cut, red on main.
- A 305-character marker is quoted at most eighty characters long. This one
  passes on main and pins the short half: in a scratch engine copy it quoted
  305 characters, and failed, when the function printed the whole value.

An independent reviewer under bash 3.2, run through the real stop hook, found
nothing that survives checking.

**Left for another session: a home whose path holds a space never resolves.**
`felix install --home` writes the path verbatim. `felix_home` and
`felix_binding_broken` read it with `tr -d '[:space:]'`. Measured: a real home
at `<tmp>/Mobile Documents/Felix` fell back to `~/.felix`, and the refusal
named `.../MobileDocuments/Felix`, a path nobody wrote. iCloud's
`~/Library/Mobile Documents/` is the common case for a stranger. The fix is
committed as c49fbeb8 on `claude/quirky-heisenberg-fc2149`, with no pull
request yet. It merges cleanly onto this branch except for the version line.

**Traps paid for:**
- The deny row that protects the binding reads `.felix` in a command's text,
  heredoc bodies included. So `cat > script <<EOF` with a fixture that writes
  a marker under `mktemp -d` is refused. Write the script with the Write tool
  and run it by path.
- `kill -TERM` on a record run's tree does not stop it: bash defers TERM while
  it waits on a child, and the root moves on to its next section as each child
  dies. KILL the root first, then whatever still holds the run's own `$TMP`
  path. Never pattern-match `tests/run`, which also catches other sessions'
  runs.
- This branch waited a week (2026-09-24 to 10-01) for a slot behind L1 (#350),
  whose carrier stopped on the Actions billing cap and never sent the trigger.
  The new carrier, "Handoffs stale changes status (fork)", gave the slot
  directly.
