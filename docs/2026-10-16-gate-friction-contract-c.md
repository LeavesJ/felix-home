# Contract C: every part runs alone

Step 3a of docs/2026-10-12-gate-friction-design.md (section 5), its own pull
request, engine tier, tests only. Built on main e95e5d3b (land on green, 0.49.293).
Version: the next free one when it records. D (step 3b, `tests/run -j`) needs
it, and the founder put C and then D ahead of everything else on 2026-10-16.

The design's rule binds every item: weaken no check. A part is restructured;
what it asserts is not touched.

## What decided the list

Measured on d6310bd5, the tree #442 squashed as e95e5d3b, through
audits/2026-10-16-gate-friction-c/one.sh. That script runs each part alone
after the prelude, in a contained clone, six at a time. Of 144 parts:

- 61 reach their end with no FAIL;
- 22 reach their end with a FAIL, because they read state an earlier part left
  behind (a commit in a fixture repository, a file under `$FROOT`);
- 61 die before their end: 47 on an unbound variable and 13 on a missing
  function, each defined by an earlier part. The last one dies for some other
  reason.

Most of the 83 sit in chains: a part that builds a fixture, then its
`continued` parts, which use it. Examples are 0420 to 0570, 0820 to 0850,
0860 to 0890, 0900 to 0930, 0992 to 0998, 1050 to 1070 and 1280 to 1287.
deps.tsv names, for each part that dies, the name it lacks and the latest
earlier part that defines it.

## C1. The property

The prelude is `tests/run` down to the line that sources the first part
numbered 0010 or later. That covers parts 0001-0009 and every file in
`tests/lib/`, which the driver sources there in name order (C2). For every
other part P:

- run as the prelude followed by P alone, P reaches its end;
- the (name, verdict) pairs P prints alone are exactly the pairs it prints in
  the serial run, counted as a multiset. ok, FAIL and skip are the verdicts,
  and a skip's reason is not part of its name;
- the serial run gives the same manifest (`assertions.tsv`, names and
  counts) as main does, and every name in it passes or skips as on main.

The second point is checked across the whole suite at once: the multiset
union over all parts run alone equals the serial run's multiset. That
proves no part prints a name alone that it does not print in order, and
none drops one, with no need to map serial output to parts.

## C2. Where shared things live

- **Shared definitions.** A function or variable that a part uses and does
  not define itself is defined in the prelude. Something used by more than
  one part goes in a file under `tests/lib/`, named for the parts it
  serves, for example `tests/lib/land-on-green.sh`. `tests/run` sources
  every `tests/lib/*.sh` in name order, after part 0005 and before the first
  part 0010 or later. Each file defines things and runs nothing at source
  time: no fixture is built, no assertion is made, no file is written.
- **Fixtures.** A fixture a part needs is built by that part, or by a named
  function in `tests/lib/` that the part calls. The fixtures are a
  repository with commits, a home, a cache, a stub on PATH, or a file under
  `$TMP`, `$FROOT`, `$REPO` or a fixture root. No part relies on what an
  earlier part left in a shared fixture.
- **Continued parts.** A `continued` part that shares its fixture with the
  part before it calls the same builder, and gets the fixture in the state
  the serial run gave it. Where the serial run handed it a fixture already
  changed by the earlier part's assertions, the builder takes an argument
  that brings the fixture to that state. The state is named, not replayed by
  rerunning the earlier part's assertions.
- **Name collisions.** Two parts that define one name differently each get a
  name of their own.
- **Cost.** A builder that a chain calls once per part costs time in the
  serial run. C may add at most 10% to the serial run's CPU (`times`, as
  2026-10-10 measured it). If it costs more, the builder caches its fixture
  under `$TMP` by name, and each part takes a copy.

## C3. Nothing is weakened

For every assertion in every part:

- its name, the expression it checks and the value it expects are unchanged;
- a skip keeps its condition;
- only the place its inputs come from may move.

A reviewer reads the diff of every part to check this. An assertion line that
changed anything but where an input variable gets its value is a blocker.

Code that moves into `tests/lib/` stays under every lint that read it in its
part. That covers the fixture lint in 0002 (no git write from a raw `cd` or
`git -C`), 0003's lint, the locale and byte lints in 0990-0998, and the
size and shape checks in 1040: no file over 1,000 lines, and every file
parses on its own. Each lint that reads `tests/parts/*.sh` or the driver
also reads `tests/lib/*.sh`. This is shown by moving one known violation
into `tests/lib/` and seeing each lint name it. Otherwise a helper moved out
of a part would also move out of its lint's view, and C would weaken a
check by relocating code.

The manifest the record writes is main's manifest. Every name and every count
is the same, and it is compared byte for byte after sorting. `red.tsv`
against main names nothing as red, because no engine code changes.

## C4. What the build must show

- **Before.** The measurement above (61, 22, 61), from one.sh on main's tree.
- **After.** one.sh on C's tree: every part reaches its end with no FAIL, and
  C1's multiset union equals the serial record's multiset.
- **The record.** On C's tree: 0 FAIL, the manifest identical to main's, and
  no red.
- **A mutant, to show the check bites.** Take one restructured part, put back
  one dependency on an earlier part, and the after-sweep must name it.

## Not in this

- The parallel runner, `-j`, slots and the ordered log: that is D.
- Any change to what CI runs.
- Any change to engine code. A part that fails alone because of a defect in
  the engine, not the test, is reported to the founder and left as it is.
- Gate-time claims. Those come after D, measured on a quiet machine.
