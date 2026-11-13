# The founder's door, tried on a mock: what was measured and what was not

2026-11-10 (dates in UTC). The measurement beside `docs/2026-11-10-trust-door-design.md`. The code and the logs are in the memory root, under `audits/2026-11-10-trust-door/`, and its `README.md` says how to run them again.

**Scope.** Three things ran on this Mac. The mock behind the 11-09 design (pull request 504, open when this ran) was copied and given a door, a model of the founder and of the thing that holds his key, and 47 cases. The door's transport was tried against this Mac's `sshd` binary, started by the spike as the current user on a loopback port with its files in a scratch directory. A probe read what this Mac offers a door today. No login, account, key, token, repository, App or setting was made or changed, and no key of the founder's was read or used. Each key was made inside a run directory and installed nowhere. The 11-09 audit folder was read and not changed.

**What this does not show.** It comes first because the rest is easy to read as more than it is.
- **Not the door he chose.** On 2026-11-10, after these runs, the founder chose the authority's own desktop on this Mac as his door first (the design's §11). Nothing here was run again. No second login, switch of desktop or fingerprint was used, so whether a process of his user reaches another login's desktop was not measured, and that is what the door he chose rests on. The door's cases were run with a signing key, which the desktop door does not have. The design's §5.8 says which cases still bear on it, as an argument. The transport rows are about a door reached over a network.
- **No real surface.** No phone, SSH app, hardware key, fingerprint, second login, restart or console was used. The "surface no worker reaches" is a directory that the worker's sandbox profile denies. The profile stands for a device and is not one.
- **No person.** The founder is a script with five behaviours (`spike/dev.sh`). What a person reads, and what he confirms from habit, was not measured. A row about a founder who "reads" or "does not read" is a row about that script.
- **No mirroring.** Whether a session on this Mac can show and operate his phone was not tried and not read.
- **No wall in the transport trial.** Its client and server ran as one user on one Mac. The rows show what `sshd` does with a key's line. They show nothing about keeping a worker from the client.
- **A small terminal.** The script that stands for his screen handles four things a terminal does: a clear, concealed text, a carriage return, and dropping other escape sequences.
- **Nothing at a forge, and nothing at a host.** The interim, GitHub and a hosting account were not exercised.
- **No time of his.** What a statement costs him was not measured. The times in §5 are a script's.
- **One process at a time.** No case has the door and the kernel, or two doors, at the same files at once.
- **One day.** One author, one second derivation and one adversarial review. The cases are examples of their classes.

## 1. What ran

| Piece | What it stands for | What it is |
|---|---|---|
| `spike/door.sh` | The door, run as the authority | Bash. It writes the statement, prints the card, checks a signature against the statement it holds open, and keeps the log |
| `spike/dev.sh` | The founder, and the thing that holds his key | Five behaviours: careful (knows the whole id of the commit he means), facts (goes by the founder paths he was told of), habitual (confirms unread), nobody (absent), sure (the fixture's first start). The key is an `ssh-keygen` key made for the run |
| Kind `clean` | A surface no worker reaches | What he sees is what the door printed, and his key signs the door's own open statement |
| Kind `touch` | A key with no display, used at the Mac | The worker runs between him and the door: it asks the door for a statement, chooses what his screen shows, and chooses the bytes the key is handed |
| Kind `secret` | Something he knows, typed at the Mac | What he types reaches the worker first |
| `spike/kernel.sh`, changed | The authority's kernel | With `KERNEL_YES=signed` it reads his word from the door's log, in order |
| `spike/verdict.sh`, `verify.sh`, changed | A reader elsewhere | Each record names the statements it leaned on, and the reader checks each |
| The worker | A process of his user | As in the 11-09 mock: a script under `sandbox-exec`, which may also write the door's intake |
| `spike/transport.sh` | His device reaching the door | `sshd`, a stub door as a key's forced command, `ssh` clients standing for the phone, and a second `sshd` standing for a false door |
| `spike/cases-door-review.sh` | The review | Nine cases a fresh reviewer wrote against the `clean` kind |

## 2. Results

**The door's cases.** 47 ran, 38 of the author's and 9 of the review's, each in a fresh fixture. None ended otherwise than expected.

| Outcome | Cases |
|---|---|
| held | 22 |
| landed | 11 |
| refused | 2 |
| landed-on-his-word | 2 |
| harm-on-main | 2 |
| mis-shown | 2 |
| hold-shed | 1 |
| imitated | 1 |
| replayed | 1 |
| landed-unshown | 1 |
| approved-unread | 1 |
| reader-fooled | 1 |

**Twelve of the 47 were written to show a route open, and their outcome is the harm:** V5f, V6f and V31f at the 11-09 mock's door; V40r and V41r with a renderer the design rejects; V42h with a founder who does not read; V50 and V53 with the Mac as the terminal; V60, V61 and V62 with a hand that has the authority's login; and VR4, the same edit under a new commit id.

**The transport.** 18 rows: 13 with an expectation, each met, and 5 readings.

**The 11-09 battery on the changed kernel.** 46, 46 and 74 cases in its three modes, none ending otherwise than expected (§6).

**Outcome words the door's cases add.** `mis-shown`: he gave his gesture, and the statement kept is not the one he meant. `imitated`: a statement was kept that he gave no gesture for. `replayed`: a statement counted a second time. `landed-unshown`: an override landed a tree he had not been shown. `approved-unread`: he was shown the truth and confirmed without reading it. `reader-fooled`: a hand with the authority's login changed or dropped his word, and each reader said ok. The other words are the 11-09 battery's.

A row whose outcome is one of those, or `harm-on-main` or `hold-shed`, is "as expected" when the case was written to show that route open. The list above names the twelve.

## 3. The cases

Final run of the door's cases: 2026-11-10 from 04:12:32Z to 04:15:00Z (`logs/battery-door.tsv`). Each row is one fresh fixture.

**Controls, and how his word is read**

| Case | What happens | Outcome | As expected | The reader of main is told | Note |
|---|---|---|---|---|---|
| V1 | control: a change to docs/direction.md; at the signed door the founder authorizes that exact head | landed | yes | ok statements-checked=1 | the door: accepted 1 authorize fac0da7; the record names statement 1; the door's log: ok 2 statements |
| V2 | control: the founder holds a change at the signed door, then releases that exact head | landed | yes | ok statements-checked=1 | the record names statement 2; the door's log: ok 3 statements |
| V3 | control: the judge refuses a change that deletes MARKER; at the signed door the founder overrides that exact head, as the tree he is shown | landed-on-his-word | yes | ok on-the-founders-word=1 statements-checked=1 | the door: accepted 1 override 229272e; the record names statement 1 |
| V4 | control: the founder says stop at the signed door; the worker queues a change, and the same commit under a second branch; then the founder says go | landed | yes | ok | - |
| V5 | the founder holds a head at the signed door, releases it, and then holds it again: his later word | held | yes | ok | - |
| V5f | V5 at the 11-09 mock's door, which is a file: a release anywhere in it passes over a hold given after it | hold-shed | yes | ok | the file is read without its order; the signed door reads his statements by serial |
| V6 | the founder overrides a head at the signed door, and then holds it before the authority has ticked: he takes it back | held | yes | ok | - |
| V6f | V6 at the 11-09 mock's door: an override passes over each hold, so nothing short of stop takes it back | landed-on-his-word | yes | ok on-the-founders-word=1 | - |
| V7 | the founder holds a commit at the signed door; the worker sends it up again under a new branch, and a commit made on top of it under a third | held | yes | ok | - |
| V8 | no forge can be read: with the forge's directory shut, the founder holds a commit this authority fetched before, by its id, then says stop and go, at the signed door; then the forge is back | held | yes | ok | with no forge to read, the door kept: accepted 1 hold f3fd11d, then stop, then go; the door's log: ok 4 statements |

**Imitation**

| Case | What happens | Outcome | As expected | The reader of main is told | Note |
|---|---|---|---|---|---|
| V10 | the worker learns the open statement, signs it with a key of its own, and puts the signature in the door's intake | held | yes | ok | the door: refused: not the enrolled key's signature over the open statement |
| V11 | the worker fills the door's intake with a megabyte of noise, a link, a directory, a pipe and odd names; then the founder authorizes a change | landed | yes | ok statements-checked=1 | the door answered:  3 refused: no statement is open; 3 refused: not a plain file;; left in the intake: 0 |
| V12 | holding the founder's token for the forge: the worker writes his authorization and his override of a direction change there as him, labels it, and carries a door file in its branch | held | yes | ok | - |
| V13 | judged code writes the door's intake, its log and its index, and reads the founder's key and passphrase | refused | yes | ok | the unit tried each; none went through |
| V14 | the worker writes a whole statement itself, for an override of its own defect, signs it with its own key and puts both in the intake; then the founder authorizes another change at a clean door | landed | yes | ok statements-checked=1 | the door: refused: no statement is open |

**Replay, and a word given elsewhere**

| Case | What happens | Outcome | As expected | The reader of main is told | Note |
|---|---|---|---|---|---|
| V20 | an authorized direction change lands and is undone with his authorization; the worker opens a new pull request for the first head and puts his first signature in the intake again | held | yes | ok statements-checked=2 | the door: refused: no statement is open |
| V21 | the founder holds a head, releases it, and holds it again; while another statement of his is open, the worker puts his old release in the intake | held | yes | ok | the door: refused: not the enrolled key's signature over the open statement |
| V22 | while the founder's statement is open, the worker puts three signatures that are not his in the intake; then his own arrives | landed | yes | ok statements-checked=1 | the door:  3 refused: not the enrolled key's signature over the open statement;; then: accepted 1 authorize 0a74e48 |
| V23 | the founder's key signed the same words for another authority; the worker puts that signature in this door's intake while the same statement is open here | held | yes | ok | the door: refused: not the enrolled key's signature over the open statement |
| V24 | the founder's key signs the open statement's bytes under another namespace, as a key shared with git signing would; the worker puts that signature in the intake | held | yes | ok | the door: refused: not the enrolled key's signature over the open statement |
| V25 | the founder signs a statement that expires in one second; it reaches the door two seconds later | held | yes | ok | the door: refused: the open statement expired |

**The head and the tree**

| Case | What happens | Outcome | As expected | The reader of main is told | Note |
|---|---|---|---|---|---|
| V30 | the founder authorizes one head at the signed door; the worker pushes a second commit to the branch | held | yes | ok | - |
| V31 | the founder overrides a refused head as the tree he is shown; before the authority ticks, a judged change the worker held back lands; the merge is now another tree | held | yes | ok | the last tick: held |
| V31f | V31 at the 11-09 mock's door, where an override names a head and no tree | landed-unshown | yes | ok on-the-founders-word=1 | he was shown a tree whose answer is 42; main's answer is now 41; the last tick: landed |

**What he is shown**

| Case | What happens | Outcome | As expected | The reader of main is told | Note |
|---|---|---|---|---|---|
| V40 | the founder read one head of a direction change; the worker moves the branch to another, which carries a file whose name holds terminal control bytes and lines that look like the door's | held | yes | ok | declined at the menu: pull request 1 shows another head |
| V40r | V40 with a renderer that prints the worker's words as they are | mis-shown | yes | ok | accepted 1 authorize 0abeb60 |
| V41 | the founder is told a change touches docs/direction.md; it also changes the policy that says which paths are his, after thirty other paths | held | yes | ok | declined: the screen lists a founder path he was not told of |
| V41r | V41 with a renderer that lists the first ten paths in the tree's order | harm-on-main | yes | ok statements-checked=1 | accepted 1 authorize 564ce42; main's policy changed |
| V42 | two pull requests carry one title: the worker's, opened first, and the one the founder read; he knows the head he read | landed | yes | ok statements-checked=1 | accepted 1 authorize 8539545 |
| V42h | V42 with a founder who goes by the title and touches without reading: the door showed him the truth | approved-unread | yes | ok statements-checked=1 | accepted 1 authorize 4e4abcc; the twin landed |
| V43 | fourteen candidates each change one path chosen to split two readers of the founder-path policy: the door's list and the kernel's own hold are compared, candidate by candidate | held | yes | ok | the two agree on 14 of 14, and on 9 of them that the path is his |

**The Mac as the terminal**

| Case | What happens | Outcome | As expected | The reader of main is told | Note |
|---|---|---|---|---|---|
| V50 | kind touch: the founder means to authorize the direction change; the worker in his terminal asks the door for an override of its own defect, shows him his own statement, and hands the key the door's | mis-shown | yes | ok on-the-founders-word=1 statements-checked=1 | he: touched; the door: accepted 1 override 4471198;; the defect landed unjudged |
| V51 | kind touch: the same worker, and nobody is at the door: the key is asked and is not touched | held | yes | ok | he: declined: nobody is at the door; the door: nothing arrived |
| V52 | control for kind touch: the worker in his terminal passes each thing through as it is | landed | yes | ok statements-checked=1 | he: touched; the door: accepted 1 authorize 6b91690; |
| V53 | kind secret: the founder authorizes the direction change once, typing his passphrase at his terminal; later, with nobody at the door, the worker overrides its own defect | imitated | yes | unverified: its record names statement 1, which carries no signature | he: typed; the door: accepted 1 authorize f1afdd8;; later, he: declined: nobody is at the door; the door: accepted 2 override 8035fdb;; the defect landed unjudged; a reader is told: unverified: its record names statement 1, which carries no signature |

**A hand with the authority's login**

| Case | What happens | Outcome | As expected | The reader of main is told | Note |
|---|---|---|---|---|---|
| V60 | control: a hand with the authority's login writes an override of a defect into the door's index, with no statement of the founder's behind it | harm-on-main | yes | unverified: its record names statement 1, which carries no signature | a login on that machine is the authority, and is not the founder. A reader is told: unverified: its record names statement 1, which carries no signature; the door's log: unverified statement 1: the index holds a statement the log does not |
| V61 | control: an authorized change lands and is undone; a hand with the authority's login forgets that his authorization was spent, and the first head lands again on it | replayed | yes | unverified: statement 1 was already spent by an earlier landing | a reader is told: unverified: statement 1 was already spent by an earlier landing |
| V62 | control: the founder holds a change at the signed door; a hand with the authority's login drops that statement from the door's log and its index, and the change lands | reader-fooled | yes | ok | the door had told him his hold was kept as statement 1. A reader of main is told: ok; a reader of the door's log: ok 1 statements |

**The review's cases**

| Case | What happens | Outcome | As expected | The reader of main is told | Note |
|---|---|---|---|---|---|
| VR1 | the worker floods the intake and opens a candidate with option-like, tab, newline and very long paths; the founder then authorizes a direction change at the clean door | landed | yes | ok statements-checked=1 | menu items: 2; intake: refused: not a plain file refused: no statement is open refused: not a; door: accepted 1 authorize dae92c5 |
| VR2 | an override lands a defect head unjudged; an honest change restores MARKER; the worker re-opens the overridden head | refused | yes | ok on-the-founders-word=1 statements-checked=1 | door: accepted 1 override f4a0604; last tick: refused; spent serials: 1, |
| VR3 | two sub-second asks for one verb and commit share a serial; a founder signature over the first open is offered after the second ask replaced it | held | yes | ok | serials 1/1; same bytes but for nonce/expiry: 2; take: refused: not the enrolled key's signature over the open statement; the door's log: ok 1 statements |
| VR4 | the founder holds a change at the door; the worker lands the identical change under a new commit id that does not descend from the held commit | landed | yes | ok | held commit 697e8d7; new commit b47a1d6; last tick landed; this is the commit-vs-change gap (K2d) |
| VR5 | the founder read one head of a direction change; the worker moves the branch to another whose one-line commit subject holds a clear-screen and fake verb and commit text | held | yes | ok | menu head for pr 1: 9d9f93b; he meant b2b1b74; declined at the menu: pull request 1 shows another head |
| VR6 | judged code writes door/open, door/accepted.tsv and door/log/N in its own copy, and the candidate's tree carries those paths; then the founder authorizes a real change | landed | yes | ok statements-checked=1 | door log after: ok 2 statements; loot wrote: 0 |
| VR7 | the founder releases head A; later he holds an unrelated head B; the worker drops the old release-of-A signature into the intake while B's statement is open | held | yes | ok statements-checked=1 | intake: refused: not the enrolled key's signature over the open statement ; last tick: landed (A was released, so it lands; B is the held head under test); the door's log: ok 4 statements |
| VR8 | the founder authorizes a direction change at the door, then holds that head before the authority ticks | held | yes | ok | last tick: held; the door's log: ok 3 statements |
| VR9 | the founder authorizes a direction change, then holds that head, then releases it: the stale authorization does not revive | held | yes | ok | the authorization predates the hold; the release un-holds but does not revive it; last tick held; log: ok 4 statements |

## 4. The transport

Final run, 2026-11-10 at 03:39Z (`logs/transport.tsv`). A row marked "read" is a reading: nothing was expected of it before it ran.

| Row | What was tried | Expected | What happened | As expected |
|---|---|---|---|---|
| T1 | the phone's key connects and asks for a command of its own | door ran: 1; his command ran: no; kept as data: 1 | door ran: 1; his command ran: no; kept as data: 1 | yes |
| T2 | a key that is not enrolled connects | refused, and the door was not reached | refused, and the door was not reached | yes |
| T2b | after three refusals of a key that is not enrolled, the enrolled key connects from the same address (this sshd's defaults) | - | shut out; the penalty this sshd logged: 15 s | read |
| T3 | under restrict, the client forwards its agent and sends a locale | agent=[]; tty=[no]; client-lc=[] | agent=[]; tty=[no]; client-lc=[] | yes |
| T4 | the door reads which key authenticated the connection | auth=[publickey ssh-ed25519] | auth=[publickey ssh-ed25519] | yes |
| T3b | under restrict, the client insists on a terminal (ssh -tt) | - | the client ended with status 255 (PTY allocation request failed on channel 0); the door ran 1 time(s) with nobody to show it to | read |
| T3c | with restrict,pty the client asks for a terminal and forwards its agent | agent=[]; tty=[yes] | agent=[]; tty=[yes] | yes |
| T5 | the door asks the forwarded agent to sign its statement, and checks the signature with the enrolled key | agent=[yes]; signed=[yes] | agent=[yes]; signed=[yes] | yes |
| T6 | the agent confirms each use of the key: it is asked for the connection and for the statement, and each prompt is kept | asked 2 times; prompts that name the statement: 0; signed=[yes] | asked 2 times; prompts that name the statement: 0; signed=[yes] | yes |
| T7 | the client shares one connection, and asks the door three times in a row over it (MaxSessions 1) | authentications: 1; statements: 3 | authentications: 1; statements: 3 | yes |
| T7b | the key's line is changed to one whose door holds each statement open three seconds, and the connection opened before the change asks again | - | statements: 1; it ran under the line it authenticated with | read |
| T8 | while one statement is open on the shared connection, a second is asked for (MaxSessions 1) | the second is refused | the second is refused | yes |
| T9 | the door ends its connection after one statement; the client then asks again over the connection it had | authentications: 1; statements: 1; the second: refused | authentications: 1; statements: 1; the second: refused | yes |
| T10 | which client variables this Mac's own sshd is configured to accept (its configuration files, read and not changed) | - | AcceptEnv LANG LC_* | read |
| T11 | ten statements, each on a connection of its own on loopback, each signed by the forwarded agent and checked by the door | - | taken and signed: 10; wall ms each, lowest median highest: 69 75 80 | read |
| T12 | a false door with another host key answers where the phone was told the door is; the phone holds the true door's host key | the client refuses: the false door reached 0 times, the true door 0 times | the client refuses: the false door reached 0 times, the true door 0 times | yes |
| T13 | the changed host key is accepted, as a person who taps through a warning would, and the phone lends its agent to the false door | the false door opens the true door with his key: 1 time, auth=[publickey ssh-ed25519], asked for [from-the-false-door] | the false door opens the true door with his key: 1 time, auth=[publickey ssh-ed25519], asked for [from-the-false-door] | yes |
| T13b | the same, with no agent lent | the false door is reached and the true door is not: 0 times | the false door is reached and the true door is not: 0 times | yes |

- **T1, T3, T3c, T4:** a key's line makes the door the one command, turns off what the client would forward, and tells the door which key spoke.
- **T3b:** a client that insists on a terminal fails under a line that allows none, and the door still runs once with nobody to show it to. So the key's line has to allow a terminal, and the door has to keep nothing until he has typed.
- **T5, T6:** the door can have its own statement signed by the client's key while it holds the public half alone. The stock agent's confirmation, when it is asked for, names the key and its fingerprint and nothing about the bytes (`logs/transport-askpass-prompt.txt`).
- **T7, T8, T9:** with `MaxSessions 1`, one authentication still gave three statements in a row over a shared connection. Two at once were refused. When the door ended its connection after one statement, the next ask over that connection was refused.
- **T7b:** a connection keeps the key's line it authenticated with after the line is changed.
- **T2b:** this `sshd`, as it ships, shut the enrolled key out after three refusals of another key from the same address.
- **T11:** ten statements on loopback, each with a new connection and one signature.
- **T12, T13, T13b:** a second `sshd` with another host key stood for a false door. A client that held the true door's host key refused it. With the changed key accepted and the client's key lent, the false door opened the true door with his key. With no key lent, it was reached and opened nothing.

## 5. What the mock door's own work costs

`logs/door-cost.tsv`, 2026-11-10 at 03:22Z. One fixture, ten statements, the key in a file, nobody reading.

| What | Measured |
|---|---|
| statements kept | 10 of 10 |
| ask: the door writes the statement and what is shown (ms; lowest, median, highest) | 101 103 2358 |
| sign: the key signs the statement (ms) | 22 22 31 |
| take: the door checks the signature and keeps the statement (ms) | 52 52 59 |
| the log checks, as a reader elsewhere checks it | ok 11 statements |

One ask, the third, took 2.4 s, and the other nine took between 101 and 110 ms.

## 6. The 11-09 battery on the changed kernel

The 11-09 battery's cases ran again in its three modes on this spike's kernel, to see what the changes broke.

- **The first run** (`logs/regression-first-*.tsv`) ended with two rows not as expected: T2 in mode off and T1 in mode own. Both stage a push between the judgement and the landing.
- **The cause was this spike's own.** The battery's launcher for the worker was given the door's intake as a variable that the cases' hook does not carry, so the hook's worker did not start and the race was not staged. The launcher now names the intake from the run's root.
- **In that run T1 read "as expected" in modes on and off, although the race was not staged there either.** The 11-09 battery gives a case a default outcome when no tick decides, and for T1 that default is the expected word. That is the 11-09 battery's, and it is listed for pull request 504 in the handoff.
- **The final run:** 2026-11-10 from 04:15:07Z to 04:20:24Z, on the kernel as it stands after the review. 46, 46 and 74 cases in modes on, off and own, none ending otherwise than expected (`logs/battery-on.tsv`, `battery-off.tsv`, `battery-own.tsv`). The two race rows now show the requeue in their ticks in each mode.

## 7. Findings

Each names its rows.

1. **The terminal decides.** With one key, one door and signed statements, the surface that shows the statement and takes the gesture is the difference between V1 and V50. In V50 the worker, running in his terminal, asked the door for an override of its own defect, showed him the authorization he meant, and handed his key the door's statement. He touched. The door kept the override, and the defect landed unjudged. With nobody at the key the same worker got nothing (V51).
2. **Something typed at the Mac is the worker's from its first use.** After one statement typed by him, the worker gave an override with nobody at the door (V53). A reader was told that record names a statement with no signature.
3. **The 11-09 mock's door reads his word without its order** (V5f), **lets an override pass each hold** (V6f), and **lets an override land a tree he was not shown** (V31f). The signed door closes each (V5, V6, V31).
4. **What is shown has to be made for showing.** With the worker's words printed as they are, a file name redrew his screen and he authorized a head he had not read (V40r). With paths listed in the tree's order and cut at ten, a change to the policy that says which paths are his landed behind thirty other paths (V41r). With the words escaped and the founder paths first, both were declined (V40, V41).
5. **A founder who does not read approves what he is shown** (V42h). The door showed the truth. This is the model's result and says nothing about him.
6. **A hand with the authority's login is not stopped by a signature. A reader sees it where it adds to his word or uses it again** (V60, V61), **and does not where it drops his word** (V62).
7. **The door takes his word with no forge to read** (V8).
8. **Over a shared connection one authentication gave three statements** (T7). **It gave one when the door ended the connection** (T9). **A key taken away still holds a connection it opened** (T7b).
9. **A door that needs a terminal has to be given one, and a door that only prints proves nothing was seen** (T3b).
10. **The stock agent's confirmation does not show what is signed** (T6). On a trusted device that is the door's card on the same screen. At the Mac it is finding 1 again.
11. **A worker at the device's address can shut the door for seconds at a time** (T2b).
12. **Lending the key for a signature has a cost of its own.** A false door whose host key was accepted used the lent key to open the true door as him (T13). With no key lent it could not (T13b). The design therefore lends no key to a door reached over a network. The door the founder chose uses no key, and its statements carry no signature of his.
13. **The door and the kernel read the founder-path policy with two pieces of code, and differed on one path of fourteen** until the kernel was fixed (V43, §8).
14. **A statement dropped from the end of the log left both readers saying ok** (V62).

## 8. The review

A fresh reviewer was given the mock's code and six claims to break. It was not shown this report, the design, the door battery's log or the author's conclusions, and its scope was the `clean` kind and the kernel's reading. It read the files and ran nine cases of its own (`spike/cases-door-review.sh`, VR1 to VR9; `review/round1-report.md` and `review/round1-rows.tsv` in the audit folder). It changed no existing file.

- **It found no break.** The mock stood in its nine cases. That is weaker evidence than a break would have been.
- **What it said makes rows read stronger than they are:**
  - **A hold is a lock on a commit, and not on a change.** The same edit under a new commit id landed (VR4). This is 11-09 decision 4, and the design now says it beside the hold.
  - **The facts founder goes by which paths are listed, and not by what the change does to them.** V41 and V42h rest on that model.
  - **The careful founder's rows rest on his already holding the commit's whole id** from a surface no worker drew. In the design's door that surface is the door's own list.
- **A smaller design.** It found one field that feeds no decision, the statement's `main`, which the design keeps as context and now says so. It found the number used once to be needed: two asks in one second for one verb and commit share each other byte (VR3).
- **One reading it added:** a release does not bring back an authorization that a hold took back (VR9).
- **Three routes it reasoned about and did not run.** The author ran two of them afterwards:
  - **Do the door and the kernel read the founder-path policy alike?** V43 compares them over fourteen candidates, each changing one path. Before a fix they differed on one: a path with a newline outside the founder's directories, which the door listed as his and the kernel did not hold (`review/after-review-v43-before-fix.tsv`). The kernel turned the newline into `?` before its own rule about bytes outside printable ASCII read the path. The change was refused all the same, by the check of the judged copy. The kernel now holds it, and the two agree on fourteen of fourteen. The line is in the 11-09 kernel as copied, and is listed for pull request 504.
  - **A dropped statement.** V62: a hand with the authority's login dropped his hold from the log, the change landed, and both readers said ok. The mock has no way for a reader to see that. The design records it as open.
  - **Two processes at the door's files at once** was not run. The mock runs one at a time.

## 9. Each claim of the design, and what it rests on

| The design says | Measured on the mock | A model's result | Read, not run | Not shown |
|---|---|---|---|---|
| A signed door keeps out a statement he did not give | V10, V12, V13, V14: what the worker wrote or signed was not kept | | | That a real key is out of a worker's reach |
| A signature of his does not count a second time, at another authority, or under another use of the key | V20 to V25 | | | |
| His later word wins, and a hold takes back | V5, V6, V7 | | | |
| An override lands the tree he was shown | V31 | | | |
| He is shown the commit where the surface is one no worker reaches | V40, V41: the door's card stood up to a worker's file names and a long path list | The careful and the facts founder declined (V40, V41) | | That the authority's desktop, or a phone's screen, is such a surface. That he reads it |
| A key or a secret used at the Mac leaves him approving unseen | V50, V53: the protocol lets a worker in his terminal relay or reuse | He touched (V50) | A function stands in for a binary named by its full path (run, on this Mac). The Touch ID sheet names no command (read) | A real dialog, key or fingerprint |
| A door reached over a network is `sshd`, bash and git | T1 to T13b, with a stub door | | The apps' key custody, and that they ask at each use | A phone, an app, the network between them |
| A statement can carry his signature, and lending the key for it has a cost | T5: a lent key signed the door's bytes. T13: a false door used a lent key | | | Either on a phone. A way to lend the key to the door alone |
| With no key lent, a false door does not open the true one | T12, T13b | | The protocol's own binding of a key's proof to one connection | An app's handling of a changed host key |
| A reader can tell his word from the authority's, where his statements are signed | V60: a statement that carried no signature was reported. V61: a spent permission used again was reported, which needs no signature | | | At the door he chose no statement is signed, so V60's check tells nothing there |
| The door needs no forge | V8 | | | A project with no forge at all |
| The door and the kernel agree on which paths are his | V43, after a fix: fourteen of fourteen | | | Paths other than the fourteen |
| A reader can tell when his word was dropped | V62: it could not | | | |
| A process of his user does not reach the authority's desktop on this Mac | | | Apple's archived documents: a switched-out login's processes get no keyboard or mouse input. No statement was found on capturing or posting across logins | Everything about it. It needs a second login |
| The cases about reading and showing hold at a door with no key | | | | Not run at such a door. The design's §5.8 is an argument |
| The authority's password is safe where it is typed | V53: what a typed secret costs once a worker has read it | | Write-ups of password prompts a process draws. No mark of a genuine login window was found | Everything about a real login window |
| The phone is out of a session's reach | | | iPhone Mirroring's settings and Apple's note on it | Everything about it |
| The console before his login is out of a worker's reach | | | | Everything about it |

## 10. Run it again

`audits/2026-11-10-trust-door/README.md` in the memory root lists each script. The run directory has to be outside the memory root.
