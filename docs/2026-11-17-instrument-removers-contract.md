# Contract: the judge's removers each finish, whatever the other is doing (rev 5, 2026-11-18)

**Scope.** This contract covers the two perl programs in `engine/harness/lib/instrument-run.sh` that remove a
judgement's directories after the judge is gone. One is the watchdog (`_felix_instr_wdpl`, started by
`_felix_instr_watch`). The other is each unit's supervisor (`_felix_instr_pl`), on its judge-gone path. The contract
says what each must leave when another process removes the same trees at the same time. It also says which of
today's promises stay.

Open, and not answered here:
- Other `File::Path` callers. One is `_felix_instr_tcpl`'s scratch directory, which one process owns; others are in
  other libraries.
- A unit that leaves its process group. That is the step 3 spec's section 3, and it is still open.
- Whether bind.sh's own EXIT trap can meet the same race.
- Whether part 2183's A14 has a second cause. The handoff note's earlier guess was a watchdog started without the bind
  copy. This contract does not rule that out.

## Why

On 2026-11-16, part 2183's A14 failed again on the pipe-readers branch (engine 0.49.353). That branch's dry run
refused over it. A red run against main 212830c4 shows the same failure. A14 KILLs the judge while one unit sleeps.
Then it finds bind.sh's copy `felix-objects.*`, or its `.list`, left under TMPDIR, while the rest of the run tree is
gone. Part 2183 runs among the merge judge's units, so this flake can refuse any machinery PR's merge.

The cause was measured on 2026-11-17, outside the suite. After the judge is KILLed, two kinds of process remove
J, R, UP and HP:
- the watchdog;
- each running unit's supervisor, on its `$why == 126` path.

`File::Path` 2.18, in `/usr/bin/perl` 5.34 on this Mac, walks a tree with `chdir` into each directory and
`chdir("..")` back out. When the other process removes the directory the walker stands in, the walk back fails. Then
`File::Path` *croaks* with "cannot chdir to .. from X, aborting". It croaks even when its `error` option is set
(File/Path.pm lines 442, 513, 518 and 524). A croak ends the program with status 2. The watchdog hands its trees to
`remove_tree` one after another, the bind copy last, so a croak on J leaves the bind copy and its list. The
supervisor never removes those, and the KILLed judge cannot.

The watchdog program was run with a second process removing J at the same moment:
- the branch's copy left the bind directory in 14 of 20 rounds;
- main's copy, byte-identical, left it in 15 of 20;
- run alone, it left it in 0 of 20.

A second trap found while specifying (2026-11-17, scratch probe, 20 rounds each way):
- `rmtree` begins with `getcwd() or return 0` (line 328).
- A croak leaves the process standing in a directory that no longer exists. So the next `remove_tree` removes nothing
  and only warns.
- Five rounds whose first removal croaked each left a second, unrelated tree when the next call came straight after.
  Two such rounds with a `chdir "/"` before the next call left nothing.

So catching the croak is not enough. The program has to return to `/` before it removes anything else.

## Words

- **J, R, UP, HP, U.** J is the run directory: the run tree T and the canary's copy. R is the records. UP is the parent
  of the units' own directories, mode 0311 while the judgement runs. HP is the parent of the units' HOMEs. U is one
  unit's own directory, inside UP.
- **BD.** bind.sh's copy: a bare repository under TMPDIR named `felix-objects.*`, with a file `BD.list` beside it.
  BD's objects are `BD/objects/XX/…` (two hex digits) and `BD/objects/pack/…`.
- **A removal dies** when `File::Path::remove_tree` croaks.
- **Left**: after the program has exited, `lstat` finds the path.
- **A collision**: a second process removes the same tree, or a tree under it, while the program removes it.

## IR1. The watchdog's interface (unchanged)

The arguments are `PARENT FROM TO KEEP PATH...`.

- **PARENT** is a pid. If it is not a positive integer, the program reads `getppid()` when it starts. The program
  waits while `getppid() == PARENT`, checking every 0.25 s.
- **Signals.** It is in a process group of its own. It ignores TERM, INT, HUP, QUIT and PIPE. USR1 makes it exit 0 at
  once, moving and removing nothing.
- **Salvage.** Once the parent is gone, it changes to `/`. When FROM and TO are both non-empty and both directories,
  it moves files from FROM into TO, keeping each file's path relative to FROM. A file is moved when all of these hold:
  - it is a regular file, at `FROM/XX/*` (XX is two hex digits) or `FROM/pack/*`;
  - KEEP is empty, or the file is not `pack/KEEP.*`;
  - TO holds nothing at its relative path.

  The program makes the subdirectory in TO as it needs it.
- **Removal.** Then each PATH is removed, and the program exits 0. An empty PATH is skipped. A PATH that is a symbolic
  link is removed as a link, and its target is not touched. A directory PATH is made mode 0700 before its removal, so
  a 0311 UP can be listed.

## IR2. The watchdog removes every PATH, whatever another process is doing

After the watchdog exits, none of its PATHs is left. This holds when another process removes any of them, or anything
under them, at the same time, or makes something under them, and in whatever order the PATHs were given, as long as
that process stops within 30 s. It also exits 0.

How:
- Each PATH is removed on its own.
- A removal that dies is caught. The program changes back to `/` and removes that PATH again.
- An attempt can die, or end without dying while the path is still there. Either way the program pauses about 0.1 s
  and tries again, while the path is there, for up to 30 s on one PATH from its first attempt. The last attempt can
  run past 30 s by its own walk of the tree.
- Rev 3: rev 2 allowed 20 attempts. On 2026-11-18 a record's red pass against main b03e7c10 (0.49.355), at -j 6
  beside the record's own suite, load 21 to 28, failed IR4's two race assertions, which passed in the record's own
  run. The red log was gone with its temporary directory, so the part's 10 s limit and the 20 attempts were not told
  apart. Read from File::Path's walk, and not measured: a walker that trails another loses each collision, since the
  one ahead removes the directory the other has just entered. So once the program has died once, it dies on every
  attempt until the other process ends, and on a slow host that outlasts 20 attempts 0.1 s apart. A unit still writing
  into J before its supervisor ends it does the same. A bound in time does not depend on the host's speed.
- Then it goes on to the next PATH.
- A PATH that is already gone costs nothing.

The salvage happens before any removal. A collision on a PATH does not stop the salvage, and does not undo it.

## IR3. The shell hands the watchdog the bind copy first

When the judge's shell owns the bind copy, `_felix_instr_watch` passes BD and BD.list as the first PATHs, before J, R,
UP and HP. The shell owns it when `_FELIX_BIND_DIR` is set and `_FELIX_BIND_OWNER` equals `_FELIX_INSTR_OWNER`. Only
the watchdog removes those two, so a dying removal of a shared tree must not stand in front of them.

Interface of `_felix_instr_watch` (unchanged apart from the order):
- It reads `_FELIX_INSTR_J`, `_FELIX_INSTR_R`, `_FELIX_INSTR_UP`, `_FELIX_INSTR_HP` and `_FELIX_INSTR_OWNER`.
  It also reads `_FELIX_BIND_DIR`, `_FELIX_BIND_OWNER`, `_FELIX_BIND_HOME` and `_FELIX_BIND_PACK`.
- PARENT is the calling shell's `BASHPID`.
- FROM is `BD/objects` when `_FELIX_BIND_HOME` is set, and empty otherwise. TO is `_FELIX_BIND_HOME`, and KEEP is
  `_FELIX_BIND_PACK`.
- It starts the watchdog in the background, with stdin, stdout and stderr on `/dev/null`, and sets `_FELIX_INSTR_WD`
  to its pid.
- When the shell does not own the bind copy, it passes no BD and no BD.list.

What can be seen: a bash shell sources `lib/instrument-run.sh`, sets those variables over directories of its own, runs
`_felix_instr_watch`, and is KILLed while another process removes J. Within a few seconds, none of BD, BD.list, J, R,
UP and HP is left. BD's loose objects and packs (except `pack/KEEP.*`) are in `_FELIX_BIND_HOME`, as IR1 moves them.

The order can be seen too (rev 2), with no other remover: over a J large enough that its removal takes a while, a
shell KILLed after `_felix_instr_watch` reaches a moment where BD and BD.list are gone while J is still there. Passed in
the old order (J first), BD stays until J is gone.

## IR4. The supervisor's judge-gone path removes each of its directories

Interface (unchanged): the arguments are `PARENT LIMIT LOG GROUP-FILE J R U UP HP COMMAND...`.
- PARENT is read as IR1 reads it.
- The supervisor leaves its parent's process group. It starts COMMAND in a process group of its own, with stdin from
  `/dev/null` and stdout and stderr appended to LOG. It writes that group's number to GROUP-FILE, then checks every
  0.2 s.
- When the unit ends, it exits with the unit's status.
- When LIMIT seconds pass, it ends the group and exits 124.
- On TERM, HUP, INT or QUIT, it ends the group and exits 125. None of these three paths removes anything.
- To end a group, it sends TERM, waits up to about 1 s, then sends KILL.
- **The judge-gone path:** `getppid() != PARENT`. The supervisor ends the group, changes to `/`, removes J, R, U, UP
  and HP, and exits 125. Each directory PATH is made mode 0700 just before its removal, a symbolic link excepted (rev 2:
  rev 1 said UP alone was made 0700 first, as the old code did, through a link too).

IR4 itself: on the judge-gone path, each of J, R, U, UP and HP is removed on its own, as IR2 removes a PATH. After the
supervisor exits 125, none of the five is left, when another process removes J, or any of the five, at the same time,
as long as that process stops within IR2's 30 s.

Today all five go to one `remove_tree`. A removal of J that dies leaves R, U, UP and HP, and the supervisor exits 2,
not 125.

## IR5. What stays as it is

- A watchdog still waiting on a live PARENT exits 0 within about a second of USR1. It removes and moves nothing.
- TERM, INT, HUP and QUIT do not end a waiting watchdog. It stays, and nothing is removed while PARENT lives.
- With no other process removing anything, the watchdog and the supervisor's judge-gone path each leave nothing, in
  every round.
- A supervisor whose PARENT lives removes nothing. A unit that ends normally gives its status, and nothing is removed.
- A symbolic-link PATH is removed as a link. Its target and what the target holds stay.
- Each program removes only its PATHs and what is under them, in the race rounds as in the others.

## IR6. What the part must show before it believes a pass

The rule is that a gate that cannot fail is not a gate.
- **Arming.** On the host it runs on, the part shows that two plain `File::Path::remove_tree` calls collide on a tree
  of the shape it uses: one dies in at least one of its rounds. The two calls are started together, in two processes,
  with no `eval`. If they never collide in its rounds, the part skips the race assertions by name and says the host
  gave no collision. It does not pass them.
- **Timing.** The concurrent remover starts its removal when it sees what the program is waiting for: the PARENT
  gone, or for the supervisor, the unit's group gone. It checks at least as often as the program does. The tree must be
  large enough that one removal of it outlasts that window on this Mac.
- **Rounds.** At least 20 rounds for each program. The race assertions count rounds in which anything is left. On the
  engine this contract was cut from (main debec2c3, 0.49.352), the watchdog's count is above 0. The supervisor's is
  expected to be above 0 too, and the red run records whether it is.
- **Each race collided (rev 2).** The arming above shows the host can collide; it does not show that a race's rounds
  did. So each race (IR2, IR3, IR4) also counts its rounds in which the other remover's own plain removal died. A race
  with no such round in its rounds has its assertions skipped by name, saying no round of it collided, rather than
  passed. On a host where a walk out of a removed directory does not fail (by the review's reading, not measured,
  Linux, which follows a removed directory's parent), the arming skips the races; that is expected there, and the
  races are read on this Mac.
- **No wait without a limit (rev 2).** Every wait the part makes ends within a stated time, and a round whose tree
  cannot be made is a failure of that round, not a hang.
- **Limits above the program's (rev 3).** The part's limit on a program it waits for is above the program's own
  30 s, with room for the program's other steps (a supervisor first ends its unit's group, about a second), so a slow
  host reads as slow, not as left.
- **Another process working under J for longer than rev 2's attempts (rev 3).** For each program (the watchdog run
  directly, and the supervisor's judge-gone path), the part shows that it leaves none of its PATHs when another
  process keeps working under J for about 4 s after the program starts removing: removing what is under J and making
  it again, repeatedly, then stopping with J still there. That is longer than rev 2's 20 attempts 0.1 s apart. At
  least 5 rounds each. On 0.49.355 (main b03e7c10), J is expected to be left in some rounds.
- **The other process is at work before the supervisor removes (rev 4).** For the supervisor, the other process
  begins working under J once the PARENT is gone, while the supervisor is still ending the unit's group. It keeps on
  until about 4 s after the group is gone. For the watchdog, it begins once the PARENT is gone, as in rev 3.
- **A round that did not outlast the program (rev 4).** A rev 3 round outlasts the program only when the other process
  made something under J and J was still there when it stopped. A round that did not outlast shows nothing either way.
  The part gives it in the detail and counts it as neither a pass nor a failure. A round in which the other process
  wrote no report at all is a failure of the fixture. Rounds go on until 5 have outlasted, up to 10 in all. When none
  outlasted, the assertion is skipped by name, saying so.
  - Why: on 2026-11-18, rev 3's part counted a round in which the other process made nothing as a fixture failure.
    Run alone on the fixed engine, that failed 2 of the supervisor's 5 rounds. In each of them, the other process ran
    about 340 cycles and found J gone before it made anything.
- **What the part signals is what it started (rev 5).** During a suite, pids and process-group ids wrap within
  minutes. So a number the part read earlier, from a file or a poll, can name another part's process or group by the
  time the part signals it. Before the part sends any signal other than 0 to a process or group, it checks that the
  target is still one it started, by a mark that only its own processes carry, such as a name unique to the part in
  their command lines. A process it still holds as an unreaped child of its own shell needs no check. When the check
  fails, the part leaves the target alone and says so in the detail. A probe with signal 0 only reads: a reused
  number can make the probe wait, and every wait is already bounded.
  - Why: on 2026-11-18 a full gate's part 1293 failed D4 and R1, with its record runner KILLed from outside (exit
    137). That pair has failed beside other suites since 2026-11-13, before this part existed, so its own race is
    the likelier cause. But rev 4's part KILLs a supervisor round's unit group by a number read before the round,
    whenever that group still answers to signal 0, and its waiter KILLs a program's pid after a timeout. Either could
    hit another part's process once pids wrap. That reading is not measured.
- **Cost.** The part stays within about 3 minutes on this Mac, and at worst 4. It keeps everything under the suite's
  `$TMP` and leaves no process behind. Rev 2's part already took 118 s, beyond rev 1's 90 s, and rev 3's took 144 s.
