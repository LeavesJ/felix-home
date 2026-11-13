# The authority that holds main, in shadow: the first slice of step 4's first stage

2026-11-13 (dates in UTC). What this change builds, from the founder's door as designed on 2026-11-10
(`docs/2026-11-10-trust-door-design.md`, §5 and §7) and from the hosted-authority design of 2026-11-09 (pull
request 504, which was not on main when this was written). The contract the tests were written from is in the
memory root, `audits/2026-11-13-trust-step4-shadow/spec-slice1.md` (revision 3), with the review and the log
of each run named here.

**Scope.** One slice of the first stage, in the engine: the authority's parameters and store, its standing, the
founder's door, the reading of his statements, the decision for a candidate up to the judge, a reader's check of
the log, the reach test with its witness, and the lock at the end of a statement. A question outside that is
listed in §7 with where it belongs, and is not answered here.

**The founder's decision this rests on,** 2026-11-13, in his words: "Build now, login this week". The authority
is built now and runs in shadow. It judges and records. Nothing it says counts and it holds nothing until three
things are true: it runs as its own login, the reach test has passed, and he has given the first start at that
login's desktop.

**What this does not show.** It comes first because the rest is easy to read as more than it is.
- **Nothing lands.** A tick ends where the judge would begin, in shadow and in a fixture's live standing alike.
  The judge, the landing and the record of a landing are later slices (§7).
- **No second login.** Each run was under the founder's own login on this Mac. No login was made, and no
  fingerprint, restart, switch of desktop or sharing setting was touched. Those are his acts (§8).
- **The reach test was not run.** Its two programs are written. The probe's `--run` posts keys and a click and
  was never started. The witness was run for 0 and for 2 seconds with nobody at a second desktop, which shows
  that it writes a record and nothing about what macOS keeps apart.
- **"Live" was reached in a fixture alone.** There the authority was the founder's login, and the workers'
  login was a system login that was not his: one that runs no process for the console, one that runs a process
  for the desktop. It shows the code that reads the five conditions. It shows no separation, because one login
  played both sides.
- **No lock known to work.** The door runs whatever program the `lock` parameter names. Which program locks
  this macOS from bash was not read, and the tests use a stub that writes a mark.
- **No signature.** A statement carries none and says `key: none`. What stands behind one is that the
  authority's desktop was unlocked and that this code ran there.
- **No forge.** A candidate is a branch of a git repository on this disk. Pull requests, labels and a
  published copy are a connector's, which is not built.
- **No person.** The founder at the door is a test's script, which reads the card and types the confirmation.
- **One day, one author, one blind test author and one reviewer.** The cases are examples of their rules.

## 1. What was built

| Piece | Where | What it does |
|---|---|---|
| Parameters | `lib/authority.sh` | `authority.conf` in the authority's home: `user`, `workers`, `source`, `source-main`, `store`, `door`, `lock`. With `FELIX_AUTHORITY_HOME`, these say where the authority lives and who it is |
| The store | `lib/authority.sh` | A bare git repository the authority alone writes. A hook refuses a push. It has an identity made once from the system's random source |
| Standing | `lib/authority.sh` | `shadow` unless five conditions hold (§2). `felix authority status` prints one `why` line for each that does not |
| The door | `lib/door.sh`, `felix door` | Reads back what stands, lists what waits on his word, takes one verb, prints the statement and the card, takes a typed confirmation, keeps the statement, runs the lock. `felix door stop` is the brake: it fetches nothing and lists nothing |
| The log | `lib/door-read.sh` | `refs/felix/door` in the store. Each statement is a commit whose message is the statement and whose parent is the one before it |
| The reading | `lib/door-read.sh` | His statements read in order: stop and go, hold, release, authorize, override |
| Founder paths | `lib/authority-paths.sh` | One function, used by the door's card and by the decision, that says which changed paths are his |
| The decision | `lib/authority-tick.sh`, `felix authority tick`, `decide` | For each candidate: `stopped`, `override`, `held`, `conflict`, `nothing`, `waits` or `eligible`, with what it leaned on. A ledger row when a decision changes |
| The reader's check | `felix authority verify` | Checks each entry of the log, and with `--memory` notices a log that no longer holds an entry this reader saw |
| The reach test | `bin/reach-witness`, `bin/reach-probe` | The witness records what arrives at the authority's desktop. The probe tries to reach it from a session of the founder's login |

The enforcing path is bash 3.2 and git, as the rest of the engine. Each git the authority runs drops the
caller's `GIT_` variables and takes no configuration, attributes file or replacement objects from the caller,
the user or the system. A fetch checks each object it takes, and takes a source that is an absolute path or a
`file`, `https` or `ssh` URL.

## 2. Shadow, and what makes it live

The standing is `live` when each of these holds, and `shadow` otherwise:

| # | Condition | Whose act it waits on |
|---|---|---|
| a | The process runs as the `user` row; that login is not among `workers`; no worker is root | The authority's login, which is the founder's to make |
| b | Each file and directory under the home, the store and the door's directory is that login's and writable by no one else, and none carries an access-control list | Follows from a, with `init` run as that login |
| e | No login named in `workers` owns or can write the code the process runs: the engine's directory, `felix`, each file of `lib/`, each directory `PATH` names and each program in one, and the lock with its directory | A copy of the engine, and a `PATH`, that are the authority's login's or the system's |
| c | The log's first statement is a `start` given at the console | His first start, after a restart, with no worker's login open |
| d | The latest `reach` statement is a `pass` given at the console | The reach test, with him at the screen |

"At the console" is read as: no process on this Mac has a login named in `workers` as its real or its
effective user. Where the list of processes fails, or lacks process 1 or the door's own process, the answer
is the weaker one, `desktop`. It is read when the door opens and again when a statement is kept, and a
statement whose answer changed in between is refused.

**What condition e found on this Mac.** Under the founder's own login the `git` on his `PATH` is
`/opt/homebrew/bin/git`, in a directory his login owns. So an authority whose `PATH` holds that directory runs
a `git` a worker's session can replace, and e says so. The authority's login needs a `PATH` of directories no
worker can write (the system's own were clean when read: no worker's file, no access-control entry), which is
one of the founder's acts in §8. What e does not read is in §7.

In shadow:
- each line a tick or `decide` prints for a candidate starts with `shadow`, and the door says `SHADOW` and
  why before it asks for anything;
- no other command of the engine reads the store, the log or the ledger. The gate, the lander and the merge
  judge are as they were. This was checked by reading: the five new libraries are called from `felix authority`
  and `felix door` and from nowhere else;
- main in the store follows the source's main forward, so the rehearsal decides against the main that
  exists, and reads the policy of that main. In a live standing it does not follow: main is then the
  authority's own.

**Moving to the other login is a change of configuration.** No command takes the user, the home, the store or
the door's directory from anywhere but `FELIX_AUTHORITY_HOME` and the rows of `authority.conf`.

**A store started in shadow stays a rehearsal.** Main starts once, and a first start that does not count
leaves no room for one that does. So the store made under his own login is not carried to the authority's
login: that login runs `init` in its own home, and its first statement is the start that counts. The door
refuses a start at the desktop for the same reason, and a later start on a shadow store is refused with a
line that says the store stays a rehearsal.

## 3. What the mocks left open, and what this slice does with each

The 11-09 and 11-10 mocks recorded defects as open. The founder's instruction was that they are fixed in the
build and not copied. These are the ones this slice meets. The list is the ones found so far.

| Recorded as | The defect | Here |
|---|---|---|
| V5f | The door's reader took his word without its order: a release given before a hold passed that hold | Statements are read by their place. A hold given after a release holds again |
| V6f | An override passed each hold, whenever given | A permission is in effect while no covering hold was given after it. A release after that hold does not bring it back |
| V31f | An override named no tree, so it could land a tree he was not shown | An override names the tree of the merge he was shown, and is in effect for that tree alone. The read-back says `lapsed:` once main has moved |
| V43 | The founder-path rule turned a newline in a path into `?` before the rule read it | Paths are read NUL-terminated. A path holding a byte outside printable ASCII is his, and the card shows it as `\x0a` |
| 11-10 review | The door and the kernel read the founder-path policy differently on one path of fourteen | One function answers for both |
| V62 | A hold dropped from the log left both readers saying ok | A reader with `--memory` says the log no longer holds the entry it saw. A reader without memory says, on each run, that it could not tell |
| No-key run of 11-13, VD3 | The confirmation's four characters sat at one place known before the card | Two pairs of characters at places the statement's nonce picks, one try, and a refused try is recorded (§4) |
| 11-09 ledger | A path's tab reached the ledger's "why" column as it was | A worker's word is escaped before it is written to a line or a row |

**Not fixed by this slice,** because the thing it lives in is not built: the 11-09 battery's case T1 (its
default outcome equals the expected word), the interim against a session that drives his signed-in browser,
and the clause on recovering a hosting account. Each belongs to the slice or the document named in §7.

**The limit of V62's fix.** A hand with the authority's login that rewrites the log from its first entry is
not caught by a reader with no memory, and a reader's memory is one file that reader keeps. No statement is
signed, and `verify` says how many it took on the authority's word: each of them.

## 4. The review, and what changed because of it

One reviewer with the spec and the code, which wrote neither, attacked the first build (commit 593fba1d) and
reported fifteen findings, each with a script. Each was fixed in the build or is listed as open in §7. The
record, finding by finding with the script and the log of the run after the fix, is in the memory root,
`audits/2026-11-13-trust-step4-shadow/review/findings-and-responses.md`. In short:

| Finding | What it showed | Now |
|---|---|---|
| The policy's root | A candidate that replaced `.felix` moved the policy and read `eligible` | `.felix`, the land table and a path under either are his |
| A blind confirmation | A guess typed without the card was kept on run 31 of a loop, and a refused run left no trace | Two pairs at places the nonce picks (one blind try in 361); a refused try is a row and a count in the next read-back; three at the desktop send the next statement to the console; `go` is confirmed against the nonce |
| Attributes | The user's attributes file changed the merge that makes the tree he is shown | No attributes file is read, and a store that holds one is refused |
| The caller's variables | Three of the engine's own variables were taken from the environment | Each is unset before anything is read |
| When "console" is read | It was read when the door opened, and a login that opened later was not seen | Read again when the statement is kept |
| A list that fails | A `ps` that errored read as "no worker is logged in" | A list that fails or is not the full list answers `desktop` |
| "The authority's alone" | Three directories' modes were read; an entry in an access-control list, a writable directory inside the store and a replaceable lock program each left `live` | Conditions b and e of §2 |
| A start that does not count | It made main and blocked the one that would | Refused at the desktop; a shadow store stays a rehearsal |
| Cost | One long path cost more than linear time, and `stop` waited behind the list | Escaping is one pass; `felix door stop` is the brake. The rest is open (§5, §7) |
| The read-back | An override whose tree was no longer the merge read "in effect" | It reads `lapsed:` |
| The screen | A padded path drew rows that read as the authority's own lines at 80 columns | The door folds each line itself, and a continuation row starts with a bar |
| The reader | A second start, a reused nonce, an extra header and bytes after a NUL each read `ok`, and a signature header ran a program named in the store | Each is refused; the commit's size is accounted against its statement; no signature is shown |
| The parameters | An unknown key passed; a source could be read as an option | Keys match whole; a source is a path or one of three URL forms |

Two automated checks of the commits then raised three more points (a source as an option, access-control
entries hidden behind extended attributes, a tool missing from a list), each fixed in the build.

## 5. What was run

RUN_SECTION_PLACEHOLDER

## 6. What a statement is

```
felix-door/v1
authority: <the store's id>
serial: <its place, from 0>
prev: <the entry before it, or ->
verb: <start|hold|release|authorize|override|stop|go|reach>
commit: <40 hex, or ->
tree: <40 hex for an override, else ->
main: <main as he was shown it, or ->
card: <the digest of the card as printed>
key: none
given: <console|desktop|shadow>
result: <pass|fail for reach, else ->
witness: <the digest of the witness record for reach, else ->
nonce: <32 hex>
at: <UTC time>
```

A statement counts when it was given at the console, or at the desktop after a reach pass that was given at
the console with no reach fail after it. One given in shadow does not count. In a live standing the decision
reads the statements that count. In shadow it reads each one, so the rehearsal reads what a live authority
would, and says `shadow` on each line.

## 7. What this slice leaves open, and where each belongs

This is an open list: the items found so far.

| Open | Belongs to |
|---|---|
| The judge: T's copy, P's units run with no power, the record of a landing, the ceiling | Slice 2 |
| Landing, and so the spending of an authorization or an override (the 11-09 design's rule 7) | The slice that lands |
| A forge connector: pull requests as doorbells, labels as holds, a published copy | Its own slice |
| The signer and each key (rule 8). Until then a hand-written entry by the authority's own login reads `ok` | Its own slice. Making a key is the founder's act |
| Which copy of the engine the authority's login runs. Condition e says when a worker can write it; it does not install one | Before the first start. Not designed here |
| What condition e does not read: the directories above the ones it reads, the directories a link's target sits in, whose entry an access-control entry is, the libraries a program loads, and a login that is not named in `workers` | Before the first start, with the reach test |
| A source the authority's login can read. Whether git refuses a repository another login owns was not shown here either way | The connector's slice |
| The proxy variables of the caller reach the authority's fetch | The connector's slice |
| A program that locks this macOS, for the `lock` row | Read on this system before the first start |
| What macOS keeps apart between two logins | The reach test, run by the founder |
| A genuine login window he can tell from a drawn one | The door design's §10. Not addressed here |
| The cost of the door and the tick with many candidates or many paths (§5). Each candidate is decided anew on each open, and no cache is built | The slice that lands, or sooner if the rehearsal shows it hurts |
| The size of a fetch is the source's to set, and no cap is built | The connector's slice |
| One object the checked fetch refuses pauses each decision until it is gone from the source | The connector's slice |
| The typed confirmation is one blind try in 361, not none, and `stop` takes its verb alone | The door design's §10, with the reach test's result |
| A scheduled job of a worker's login that starts after the door read the list | The reach test and the door design's §10 |
| A repository whose policy lives in another repository (a governed product) | Not designed |
| Look-alike characters inside printable ASCII on the card | The door design's §10 |
| A founder who confirms without reading | The door design's §10 |
| Linux: the suite runs there in CI; the review and the smoke runs were on this Mac | Each later slice's CI |

## 8. The founder's acts

None was done by this change, and none is done by merging it. A yes to a call is not a yes to the act.

1. Make the authority's login, and enroll a fingerprint for it.
2. Decide the sharing settings: no road in from the network for that login.
3. As that login, with a copy of the engine and a `PATH` that no worker's login can write: `felix authority
   init --user <login> --workers <his own login> --source <source> --lock <program>`. This makes a new home
   and a new store. The shadow store under his own login stays where it is, as the rehearsal.
4. Restart. Log in as the authority with his own login not open. At that desktop: `felix door`, then
   `start <commit>`. This is the first start, and the door takes it at the console and nowhere else.
5. The reach test. At the authority's desktop: `engine/harness/bin/reach-witness`. In a session of his own
   login: `engine/harness/bin/reach-probe --run --user <login> --home <the authority's home> --out <a
   directory>`, then switch to the authority's desktop and touch nothing. Afterwards he compares what the probe
   captured with what he saw. `reach-probe --list` names what is tried. The list is open, and a pass says what
   was tried.
6. Restart, and at the console: `felix door`, then `reach pass <the record>` or `reach fail <the record>`.

After 4 and a pass at 6, `felix authority status` says `live` when a, b and e hold too, and prints the `why`
line of each that does not. Nothing lands then either, until the slices of §7 exist and are released. A
release needs the founder by name (direction row 49).
