# What the authority's login runs from: the setup slice of step 4's first stage

2026-11-16 (dates in UTC). What this change builds, from slice 1 of the first stage
(`docs/2026-11-13-trust-step4-shadow-slice1.md`, landed as 0.49.343) and from what was read on this Mac the
same day. The contract the tests were written from is in the memory root,
`audits/2026-11-16-trust-step4-authority-setup/spec.md` (revision 3), with the review and the log of each run
named here. Engine version 0.49.351.

**Revised the same day by the hardening change (0.49.354),** after two reviews of the code that landed, a
review of the hardening's build, an automated security review of it, and a rehearsal of the new lines: where he reads the commit id (§2 step 1, §7 step 3), the lines he types (§2,
§7 step 4), what `authority-engine` and `publish` read before they trust a path (§2, after the chain), what
condition e reads (§4), and what is left open (§8). Its contract is
`audits/2026-11-16-trust-step4-setup-hardening/spec.md` (revision 3).

**Scope.** Step 3 of slice 1's §8 has the founder run `felix authority init` as the authority's login "with a
copy of the engine and a `PATH` that no worker's login can write", naming a source and a lock. Slice 1 left
three of those open in its §7: which copy of the engine that login runs, a source it can read, and a program
that locks this macOS. This slice builds those three, and makes condition e read what the copy relies on. It
builds nothing of the judge, landing, a forge connector, a signer or keys, and no schedule that refreshes the
source. A question outside that is listed in §8 with where it belongs, and is not answered here.

**The founder's decision this rests on,** 2026-11-16, his answer to "Should I build the engine copy, source and
lock that step 3 needs?": "Yes, build them". His login for the authority, `authority`, was made the same day
(00:26 local time, uid 503, a standard login).

**What this does not show.** It comes first because the rest is easy to read as more than it is.
- **Nothing ran as the authority's login.** Each run was under the founder's own login, `a14808`. The
  rehearsal in §6 ran the setup end to end there, with a scratch `HOME` and the roles swapped (`workers` named
  `authority`). It shows the steps work; it shows nothing about what macOS keeps apart between two logins.
- **The lock was never made.** `lock-macos --status` was run, and so was the lookup of the system's lock call,
  which found it by name. The call itself, which locks the screen of whoever is at this Mac, was not run by a
  test, by this session or by its agents. Whether it locks is read by the program afterwards, and exit 0 rests
  on that reading alone.
- **The reach test was not run.** Its programs are slice 1's.
- **The drop is a worker's.** The founder's login writes it, so everything in it is a worker's word. What the
  authority runs out of it is fixed by the commit id he types in full (§2). Everything else it reads from the
  drop is candidates, as slice 1's source was.
- **The commit id is read, not checked.** He reads it on his phone from a pull request whose number he fixed
  himself (§7 step 3). Nothing the bootstrap runs checks it against a key of his; that is §8's signer.
- **Linux is CI's.** The parts run there; the lock is macOS only.
- **One day, one builder, one blind test author, two reviewers, and two automated reviews of the commits.**
  The hardening added another blind test author, three automated findings, a sweep and a review of its build.

## 1. What was built

| Piece | Where | What it does |
|---|---|---|
| The drop | `lib/authority-publish.sh`, `felix authority publish [--to DIR] [--from REPO]` | Writes one git bundle of the repository's branches and its `origin/main` to `DIR/source.bundle` (default `/Users/Shared/felix-authority`), readable by another login, and prints the commit its `origin/main` names: a worker's word, not the id to type (§7 step 3). A worker's login runs it |
| The engine copy | `bin/authority-engine COMMIT [SOURCE]` | Run by the authority's login. Fetches the drop with the root-owned git, checking each object, copies the engine of COMMIT file by file from git's objects into `~/.felix/engine/COMMIT`, and writes three launchers in `~/.felix/bin` that run that copy with an empty environment and the system's `PATH` |
| The lock | `bin/lock-macos [--status]` | Locks this login's session through the system's lock call, then reads whether it is locked; exit 0 only on that reading. `--status` reads alone |
| Condition e | `lib/authority.sh` | Reads the whole engine, the directory the running git's programs come from, and each directory above any of these (§4) |

The enforcing path is bash 3.2 and git, as the rest of the engine. `authority-engine` names every program by
its absolute path and runs git with no configuration, attributes file, hooks or replacement objects from the
caller, the user or the system. The lines he types before it (§7 step 4) run git with no configuration of the
system's or the login's, no hooks and no replacement objects, in a `~/.felix` they make fresh.

## 2. How the copy is fixed to the commit he names

The chain, from his desktop to the authority's:

1. At his desktop, `felix authority publish` writes the bundle. On his phone he reads the id he will type: the
   merged commit of the pull request whose number he fixed himself when he released it, read on the commit's
   own page. `publish` also prints `origin-main:`, the commit his checkout's `origin/main` names, and that is
   not the id. A worker can move that ref with no push, and can write to any window of his login, so a number
   read on this Mac under his login is a worker's to choose. GitHub is not out of a worker's reach either:
   Felix merges with his login's token, so "the pull request released last" may be a worker's.
2. At the authority's desktop he types eight lines (§7). Each program in them is named by a path root owns
   (`/Library/Developer/CommandLineTools/usr/bin/git`, `/bin/mkdir`, `/usr/bin/env`, `/bin/bash`), so none is
   looked up on the `PATH`. The authority's own `PATH` holds `/opt/homebrew/bin`, which the founder's login
   owns, through `/etc/paths.d/homebrew`. What the Terminal's shell runs as it starts is not read here (§8).
3. The first four set what git reads: no configuration file of the system's or the login's, no replacement
   objects, and `core.hooksPath` set to `/dev/null`, so no hook runs. The fifth makes `~/.felix`, then
   `~/.felix/engine`, each with mode 700 and without `-p`, so a `~/.felix` already there stops the rest before
   anything is made in it or git runs anything out of it, and makes the repository with no template. The sixth fetches the bundle into it,
   checking each object. A bundle holding a malformed object is refused and leaves no ref.
4. The last two read `authority-engine` out of the commit he typed, and run it under `/usr/bin/env -i` with
   `HOME` alone, so no function or variable of the Terminal's reaches it.
5. `authority-engine` checks that the commit is one the bundle holds and holds an engine, then writes each file
   from the blob that commit names. A path that is a link or a submodule, or one this file system would fold
   into another, is refused. An existing copy is read for a match and otherwise left as it is.

So the bytes the authority runs are the bytes of the commit id he typed. That id is his as far as the pull
request's number is: he fixed the number, he read the id on his phone and not on this Mac, and a merged pull
request's merge commit does not change after the merge. A worker can put any bundle in the drop, and the most it
can do is make the fetch or the copy fail.

Before the copy, `authority-engine` reads what it relies on (0.49.354), and refuses unless each reads as follows.
Root owns the git, each directory above it, the directory that git runs its helper programs from, each
directory above that, and every path under it, with no write for a group or other and no access-control entry
that allows, and so do what each link among them points at, read by its physical path, and each directory
above that. A link on the way that is not followed is refused, not passed over. The Command Line
Tools' git finds its helpers from where its own file is, which a hard link to it in a folder of the founder's
showed. The authority's login owns its `HOME`, a `HOME` that is a link, and the four directories it writes in,
with no write for another; each directory above `HOME` is root's or that login's, or sticky. A copy already in
place must be that login's too. "Each directory above" is read along the path as written, along its physical
path, and along each hop of a link met on the way. `publish` writes only in a directory that its login owns
alone, under directories that are root's or its login's or sticky; a directory that was not there is made by
one `mkdir`, and one another login puts at that name first makes `publish` refuse. Each later run goes through
the launchers:
`~/.felix/bin/felix`, `~/.felix/bin/reach-witness` and `~/.felix/bin/lock`, each three lines that name the
commit and run the copy with an empty environment, `HOME`, the login's name, `TERM`, the system's `PATH` and
`DEVELOPER_DIR` set to the Command Line Tools.

## 3. The lock

`lock-macos` loads the system's login framework and looks up its lock call by name. When it is not found, it
says so and exits 1. Otherwise it makes the call and reads, for at least 5 seconds, the session list
`ioreg` gives: locked when each session of this login is marked locked or is not at the console. It exits 0
only on reading locked, so a later macOS that drops or changes the call reads as `NOT LOCKED` at the door, not as
locked. With no session of this login listed it does not make the call, which would lock whoever is at the
console. On this Mac, `sysadminctl` reads a screen-lock delay of 300 s for the founder's login, so putting the
display to sleep would not have locked it; that is why this is a call and not a sleep.

## 4. Condition e reads what the copy relies on

Slice 1's condition e read the engine's directory, `felix`, each file of `lib/`, each `PATH` directory and
program, and the lock with its directory. It now reads:

| Rule | What | Why |
|---|---|---|
| C1 | Every path under the engine's root, at every depth, and the root itself | The lock program and the witness the launchers run are under it |
| C2 | The directory `git --exec-path` prints, for the git first on `PATH`, read as a `PATH` directory is | On this Mac `/usr/bin/git` runs Xcode's git, whose programs are under `/Applications` (root, group admin, mode 775), and the founder's login is in admin |
| C3 | Each directory above those, along the path as written, along its physical path, and along each hop of a link met on the way (0.49.354). One offends when a worker owns it, when every login or a worker's group can write it without the sticky bit, or when it carries an access-control entry that allows | A worker who can rename a directory above the code can replace the code |
| A link's target | What each link under the engine's root, and each link directly in a `PATH` directory, points at: read by its physical path for an access-control entry that allows, and each directory above it read as C3 reads them. A link that leads to nothing is read as a path not there yet (0.49.354) | macOS `ls -lLde` prints a link's own entries, not its target's; a worker who can write where a link leads chooses what runs |
| C3, not there | A `PATH` entry, the exec-path directory or the lock's directory that is not a directory yet: the deepest directory above it that is there offends when a worker owns or can write it, sticky bit or not. A link on the way that leads to no directory offends itself. A lock that is a link offends | A worker who can make the missing directory, or the thing a link points at, chooses what runs |

With the system's `PATH`, which the launchers set, the Command Line Tools' git comes first and its directories
are root's, so the Xcode route is not taken. The rule is there for a `PATH` that is not the launchers'.

## 5. The review, and what changed because of it

Two reviewers with the spec and the code, neither of which wrote either, read the blind parts and the build
(commits a4d65b40 and c2f635e3): one for the trust boundary, one clause by clause. Neither found a blocker.
Their thirteen findings were each reproduced before they were answered, and none was rejected. Two automated
security reviews of the commits after that found three more ways past condition e, each reproduced and fixed.
The record, finding by finding, is in the memory root,
`audits/2026-11-16-trust-step4-authority-setup/review/findings-and-responses.md`. In short:

| Finding | What it showed | Now |
|---|---|---|
| A directory not there yet | A `PATH` entry or lock directory that did not exist, under a directory every login could write, gave no `why` line | The deepest directory above it that is there is read, sticky bit or not |
| Not a directory | An entry that was a file or a link to one was skipped, and a walk up through a link to nothing never read where it points (automated review) | Read as not there; a link on the way that leads to no directory is named |
| A lock that is a link | A lock linked to a file in a directory every login could write passed (automated review) | A lock that is a link is named, whatever it points at |
| An impossible assertion | One blind assertion compared 32 bytes with a 31-byte string and could not pass | Offset corrected; its name and meaning unchanged |
| Tests that did not reach | Mutations that stopped reading the engine's root, or the directories above it, or that left the caller's `GIT_` variables in, passed every assertion | An assertion for each, red on the mutation |
| The caller's functions | An exported function named `builtin` or `unset` ran inside `authority-engine`, which a program cannot undo from inside | The bootstrap line runs it under `env -i` with `HOME` alone; a part reads that a caller's `BASH_ENV` does not reach it |
| Access-control entries | `authority-engine` read modes and not entries on the directories it writes, and on a copy it found in place | Each refuses an entry that allows |
| Showing a path | A path with a quote or a backslash was printed raw, and the `next:` line he types did not quote its words for the shell | Each is shown as section 0 of the spec says; the `next:` line is quoted |
| The lock's wait | It could end after about 4.25 s while saying 5 | At least 5 s |

## 6. What was run

Each run was on this Mac on 2026-11-16: macOS 27.0.1, bash 3.2.57, the Command Line Tools' git 2.54.0.

**The blind tests.** Three parts, written from the spec alone (revision 1) by an author that did not read the
implementation, before the build existed:

| Part | About | Assertions at red |
|---|---|---|
| 2190 | The drop: `publish`, its refusals, its lines, the CLI | 35 |
| 2191 | The engine copy: its environment, its refusals, the copy, the launchers, and the founder's three lines run as written | 71 |
| 2192 | The lock's reading and usage, and what condition e reads | 22 |

- **Red first.** On the tree with the three parts and no build: 103 fail, 21 pass and 4 skip. The 21 are
  controls of the fixtures themselves.
- **After the build, the review and the fixes,** each run alone: 2190 35 pass and 1 skip, 2191 76 and 1,
  2192 26 and 2, with no failure. The skips: the default drop directory where `/Users/Shared` exists, a run as
  root, and two checks off macOS. The review's assertions are in those counts. Each assertion added after the
  review was shown red on the code it was written against.
- **Slice 1's parts,** 2186 to 2189, and the wording and driver lints, pass alone on this tree.
- **What they do not reach:** a run as another login, a change of owner or group, the lock call, a fetch over
  `https` or `ssh`, Linux (CI runs it).

**The hardening's tests (0.49.354).** Two more parts, written from the hardening's spec alone (revision 1) by an
author that did not read its implementation: 2193 (`authority-engine`: the git, its helper directory, `HOME`
and above, the four directories and a copy in place by owner, entries where `ls` takes no `-e`) and 2194
(`publish`'s directory and those above it, condition e's `PATH` with globbing off, step 3 of §7).

- **Red first.** On main with the two parts: 2193 had 13 failing and 2194 15, with every fixture control
  passing (the audit folder, `blind/`).
- **The review of the build** added eight assertions, the builder's and not blind, in 2191, 2193 and 2194. Each
  was shown red on the build it was written against (d4ac2338), with every other assertion of those parts
  passing. One count in 2192 rose from 1 to 2: the walk now follows each link to its target, and the
  directory that target sits in, of mode 777, is a second offender.
- **After the fixes,** each part alone: 2190 97 pass and 1 skip, 2191 139 and 1, 2192 88 and 2, 2193 92 and 7,
  2194 95 and 0; slice 1's 2186 to 2189 and the three lints this change could reach (1296, 1500, 1510) pass
  alone. 2193's skips: three need a directory owned by another uid, which only root makes, and four are for
  where `ls` takes no `-e` (Linux).
- **What they do not reach,** beyond the list above: the walk of the git's own directory is shadowed by the
  helper-directory reading, since this git finds its helpers beside the file it was run as, so each fixture for
  the one is refused by the other with the same line; and a link under the git's helper directory whose
  target, or a directory above it, is not root's has no fixture, since staging one there needs root. A walk
  that meets more than 40 links is refused rather than passed over; no fixture reaches it, since this Mac stops
  resolving a path after 32 links (read on 2026-11-16: a chain of 32 resolved, one of 33 did not).

**A rehearsal of the founder's steps 3 and 4,** under his own login in scratch (the script and its output are in
the audit folder, `logs/`): `publish` to a scratch drop, 46 MB and 220 branches; the six lines §7 held then, run by
`zsh` with an empty environment and the scratch drop for `S`, which copied the 512 files of the branch's head
commit; the `next:` line it
printed, with `--workers authority`; then `status` and a tick through the launcher. `status` read `shadow` with the two `why` lines of c and d alone, so conditions a, b and e held with the roles
swapped. The tick said it waits for the first start. The lock launcher was written and not run.

**Not in this document:** the gate's result and the suite's count on the final tree, which are in the pull
request, since the document is part of the tree the gate reads.

## 7. The founder's acts (replaces step 3 of slice 1's §8)

Each is his. None is done by this change, and none is done by merging it. A yes to a call is not a yes to the act.

**Step 0.** This change lands and is deployed, so that `felix` at his own desktop has `authority publish`.

**Step 1. Finish the login.** Its real password, typed at the login window and nowhere else; a fingerprint
for it.

**Step 2. The sharing settings.** File Sharing shares the authority's Public folder with guest access on, and
a second Public folder, `/Users/jarrondeng/Public`, a path not on this Mac now. No road in from the network for
that login: remove the first share at least. Remote Login and Screen Sharing admit admins, and the authority is
not one (the founder's login is; §8).

**Step 3. The commit, and the drop.** When he releases the pull request whose engine the authority will run, he
writes down its number himself, off this Mac. On his phone, not this Mac: open the pull request with that
number, tap its merged commit, and on the commit's own page read all 40 characters of its id. That is COMMIT.
Read every character there; never type a short id and complete it on this Mac, where a worker chooses what it
completes to. COMMIT must hold this change, 0.49.354, or a later one: an earlier engine copies without the
reads of §2. Then at his own desktop, in his checkout of this repository, after `git fetch`:
`felix authority publish`. Do not take COMMIT from what it prints after `origin-main:`, from any window of his
own login, or from whichever pull request was merged last: a worker can make each of them name any commit.

**Step 4. At the authority's desktop,** in Terminal, the eight lines as they stand, with COMMIT (twice) the 40
characters read on his phone in step 3. Lines 5 and 6 end with `&&` and line 7 with `|`, so the shell reads on
to the eighth and runs lines 5 to 8 as one: each runs only when the one before it worked. A `~/.felix` already
there stops them at the fifth line, before git runs; these lines are for a login that has none (an upgrade is
§8).

```
umask 077; G=/Library/Developer/CommandLineTools/usr/bin/git
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_NO_REPLACE_OBJECTS=1
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0=/dev/null
B=~/.felix/engine/boot.git; S=/Users/Shared/felix-authority/source.bundle
/bin/mkdir -m 700 ~/.felix && /bin/mkdir -m 700 ~/.felix/engine && $G init -q --bare --template= $B &&
$G --git-dir=$B -c transfer.fsckObjects=true fetch -q -- $S '+refs/*:refs/boot/*' &&
$G --git-dir=$B show COMMIT:engine/harness/bin/authority-engine |
  /usr/bin/env -i HOME="$HOME" /bin/bash -s -- COMMIT $S
```

It prints `engine:`, `state: made` and the lines after them, the last `next:`. Read that its `version:` line
says 0.49.354 or later. Type that `next:` line, with `a14808` in place of `WORKERS`. That makes the
authority's home and store, in shadow.

**Step 5. Restart,** and from here as slice 1's §8 steps 4 to 6, with `~/.felix/bin/felix` for `felix` and
`~/.felix/bin/reach-witness` for the witness: the first start at the console, the reach test with him at the
screen, and its pass or fail at the console.

After 5, `~/.felix/bin/felix authority status` says `live` when a, b and e hold too, and prints the `why` line
of each that does not. Nothing lands then either, until the slices that land exist and are released. A release
needs the founder by name (direction row 49).

## 8. What this slice leaves open, and where each belongs

The items found so far.

| Open | Belongs to |
|---|---|
| Who refreshes the drop, and when. Today: by hand, before a tick | The connector's slice |
| A bundle is the whole repository each time, and nothing caps its size | The connector's slice |
| A worker that replaces the drop with a bundle that is slow to read or large | The connector's slice |
| `/etc/paths.d/homebrew` puts a directory a worker can write on every login's `PATH` | His; the launchers do not depend on it |
| Upgrading the authority's engine: the eight lines stop at a `~/.felix` already there, so an upgrade needs steps of its own; nothing tells him one is due | A later slice |
| A worker holds GitHub write access through his login's token (Felix merges with it), so GitHub does not say which merges were his: step 3 rests on the number he fixed (0.49.354) | The trust plane's signer |
| What the eight lines rely on before `authority-engine` reads anything: the git they name, its helper programs, and the authority's `HOME`, as they are when he types them. `authority-engine`'s reads of the git passed on this Mac on 2026-11-16, under the founder's login | His, before step 4 |
| A lock on a system that is not macOS | When one is needed |
| What the lock call does on a later macOS. Exit 0 rests on the reading, so a missing call reads `NOT LOCKED` | Read on each macOS before relying on it |
| What condition e does not read: the libraries a program loads; what a link's target's directory holds, for a program in a `PATH` directory that is a link; a login not named in `workers` (this Mac has a third, `dengs`) | Before live, with the reach test |
| What the authority's Terminal runs as its shell starts: that login's own startup files and the system's. Its home held none of its own when read on 2026-11-16; one added later, such as a line that runs Homebrew's setup, would run from a directory a worker can write | His, before step 4; with the reach test |
| Remote Login enabled, with admins admitted: the founder's login is an admin | His, with the reach test |
| Slice 1's §7, less the three items this slice builds | As slice 1 says |
| A signature on the commit he names, checked by the bootstrap against a key only he holds, so the id is checked and not only read on his phone (0.49.354) | The trust plane's signer; a key is his to make |
