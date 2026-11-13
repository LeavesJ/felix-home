# The founder's door: how his word reaches the authority

2026-11-10 (dates in UTC). A design for the door that `docs/2026-11-09-trust-hosted-authority-design.md` §5.5 leaves open: "How it works is not designed." That design is pull request 504's, which was open when this was written, so it is cited here by its path on that branch and called "the 11-09 design". The measurement beside this document is `docs/2026-11-10-trust-door-spike.md`. Its code and logs are in the memory root under `audits/2026-11-10-trust-door/`, called "the audit folder" below.

**Reworked on 2026-11-10, after the founder answered** (§11). This document first recommended his phone as the door. He chose the authority's own desktop on this Mac. §4 still weighs each mechanism found. §5 now designs the door he chose, §7 lists what it needs from him, and §10 says what it rests on that was not measured. Nothing was run again for the rework. On 2026-11-13 the cases that can run at a door with no key were run at one on the mock, and §5.8 now reports that run.

**Scope.** A design, which is Felix's to decide: how one statement of the founder's reaches the authority, what the door shows him, what is kept, and what he would have to do for it. Nothing is built in `engine/`. No login, account, key, token, repository, App or setting was made or changed, and no key of the founder's was read or used. The spike made its own keys for each run, inside that run's directory, and installed none of them. No phone, hardware key, second login or SSH app was used. Statements about Apple's systems, OpenSSH, FIDO and the apps named are from documentation read on 2026-11-09 and 11-10 through a tool that summarises long pages. Where a row says "run", it was run on this Mac.

**Outside this document, and where each belongs:**
- what makes a path a founder path (P, and step 3);
- the signer of landing records (11-09 rule 8);
- which host the authority moves to, and who can recover that host's account (11-09 §9 call 5, and stage 5). §8 records what this work found about it and does not answer it;
- a place for candidates and a doorbell where no forge is connected (11-09 §5.3). §5.1 says what the door itself needs from a forge;
- the interim, in which his yes is read from GitHub (11-09 §5.5). §8 records what this work implies for it;
- a door for more than one person, or for other people's repositories (the product roadmap);
- what Felix's own interface is, and where it is drawn (the interface direction). §5.7 says what the door needs from it;
- a sandbox for the workers' own sessions (direction, "Not before March").

**This is an open set.** The properties, mechanisms, routes and cases below are what one session found in one day, with one second derivation written blind and one adversarial review of the mock. A count says what it counted. A route found later is a new row.

## 1. Answer

The question: can the founder give a statement in a way that a session running as him, with tools that drive his browser and his screen, cannot imitate, cannot replay, and cannot get him to approve without his seeing the commit it names?

- **Imitating and replaying: yes, and by more than one mechanism.** A key that no process of his user can use closes both, in two ways that were tried. It signs bytes the door wrote for one exchange: on the mock, ten cases tried to imitate him or to replay a signature of his, and in none was a statement kept that he had not given in that exchange (cases V10, V12 to V14, V20 to V25). Or it opens the connection the door runs on: against this Mac's `sshd`, a key that was not enrolled did not reach the door, and a false door that was handed no key could not open the true one (rows T2, T13b). The door he chose uses no key: there, imitation and replay come down to whether a worker reaches the authority's desktop (§5.8). On the mock's door with no key, what a worker put where the intake had been was not read (VD1).
- **Approving unseen: yes, where the commit is shown and his choice is taken on a surface no worker draws on or types into. No mechanism found closes it without such a surface.** A password, a fingerprint or a touch shows that he was there. None of them carries what he was shown. On the mock the same key and the same door, with the Mac as the terminal, kept his override of a worker's defect while he meant to authorize another change (case V50).
- **So what decides is the terminal, and not the credential.** §3 gives five properties a door needs. §4 weighs the mechanisms found so far against them.
- **His choice, on 2026-11-10: the authority's own desktop on this Mac is his door first** (§11 has his words; it is row 3 of §4). This document had recommended his phone. He wrote that the reason is "a smoother transition to our infra UI later". The outcome his words name said that sessions run on the same machine.
- **The door he chose** (§5). He switches to the authority's desktop with a fingerprint enrolled for that login. The door there is bash over the authority's own store. It shows him the candidate, takes his typed confirmation, writes the statement, and locks that desktop again. No key, no `sshd` and no network are on its path, and a statement carries no signature of his.
- **What the measurement showed against the Mac as the terminal.** With the card and the gesture inside his own login, the door kept a worker's override while he meant to authorize another change (V50), and a passphrase he typed there was used again with nobody present (V53). A command typed in his terminal did not reach the binary it named (§2). Each of these is his own session, where a worker draws, reads, and writes the files his shell starts from.
- **How the authority's desktop differs.** It is another login's session. Its shell starts from the authority's files, and by Apple's archived documents a switched-out login's processes get no keyboard or mouse input (read). A worker would have to draw on, or type into, a session that is not its own. Whether macOS stops that was read in part and not run (§5.2).
- **So the riskiest assumption is now that separation,** and no longer the phone's reach. The mock's results sit on both sides of it. Where the separation holds, the cases about how his word is read and what he is shown apply: on 2026-11-13 they were run at a door with no key and ended as they had at the signed door (§5.8). Where it fails, the desktop is V50's terminal. The test that tells which needs the authority's login, and making that login is his act. No statement given by a switch counts before the test has passed (§5.6).
- **The second thing it rests on is where the authority's password is typed.** No way was found for him to tell a genuine login window from one a worker draws. So it is typed at the login window after a restart, before he logs in as himself, and otherwise he comes in by fingerprint. That is a habit. No mechanism was found that enforces it (§10).
- **What it needs from him** is in §7: the authority's login, which his answer 5 on the 11-09 design already chose; a fingerprint for it; a restart for the first start; the reach test, with him at the screen; and no road in from the network for that login.
- **His answer about the phone** (§11, call 2) is kept as he gave it. It was asked on the condition that the phone is the door, so no act under it is due for the desktop door. It comes due where a phone becomes a door (§5.7).
- **The 11-09 design's own candidate is still rejected:** a command run as the authority's login from his terminal, after his password or his fingerprint. His terminal is a worker's surface (§4, rows 1 and 2). The desktop he chose is not that candidate.
- **Three gaps were found in the 11-09 mock's door,** each shown on that door and closed at the signed one: a release passed over a hold he gave after it (V5f), nothing short of stop took back an override (V6f), and an override landed a tree he had not been shown (V31f).
- **The spike** (`docs/2026-11-10-trust-door-spike.md`): 47 cases on the mock, 38 of the author's and 9 of the review's, none ending otherwise than expected (final run, 2026-11-10 from 04:12Z to 04:15Z). Twelve of the 47 were written to show a route open, and their outcome is the harm. The door's transport was tried against this Mac's own `sshd`, started by the spike as the current user on a loopback port: 13 rows as expected and 5 readings. The transport rows are about a door reached over a network, which the door he chose is not (§5.7).
- **Not shown,** and said again in the report: a second login, a switch of desktop, a fingerprint, a restart, a phone, an app, a hardware key, a person reading a screen, or mirroring. In the mock the surface no worker reaches is a directory the worker's sandbox denies, the founder is a script, and the door's cases were run with a signing key, which the desktop door does not have.

## 2. Today, read

Read on this Mac on 2026-11-10 at 04:22Z by `spike/door-today.sh` (`logs/door-today.tsv` in the audit folder). The probe reads versions, whether files exist, permission bits and counts. It opens no key, raises no dialog and runs no `sudo`.

| What | Read | So |
|---|---|---|
| This user | An administrator | One password stands between a worker and root, and so between a worker and each other login on this Mac |
| A shell function named `/bin/echo`, then `/bin/echo` run by its full path, in zsh and in bash | The function ran | A full path typed in his shell does not reach the binary once a start-up file has defined a function of that name |
| `~/.zshenv`, `~/.zprofile`, `~/.zshrc`, `~/.ssh/config` | Writable | A worker can write what his shell and his `ssh` read when they start |
| Touch ID for `sudo` | Not set up (`/etc/pam.d/sudo_local` is absent) | `sudo` asks for his password, typed in a terminal of the worker's user |
| Remote Login | Port 22 is listening. The system's `sshd` accepts `LANG` and `LC_*` from a client | An `sshd` door needs no new service here, and sets its own locale. For the desktop door it is a road to shut for the authority's login (§5.2) |
| This `ssh` | Lists 4 key types held in hardware. Support for a USB key is not built in. The system's provider for Secure Enclave keys is present | A key touched at the Mac needs a provider library |
| iPhone Mirroring | The app is present | Whether this Mac is paired with his phone, and in which mode, is read on the phone and was not read |
| Logins | 2 with an id of 501 or more | Counted and not examined |

Read from this session's own tool list: tools that read and type in his terminal panel, drive his signed-in browser, take and operate his screen, read his mail, and ask his password manager to fill a sign-in. A worker's reach is taken to be at least that.

## 3. What a door has to have

Five properties. Each names what it is for and which cases tried it on the mock.

1. **Out of reach.** What proves him is nowhere a process of his user can read it or make it act. It is not typed in his session, it is not a file under his home, and it is not a prompt that a worker can raise and he would answer from habit. *For: imitation. Tried: V10, V12, V13, V14, and V53 for a door that lacks it.*
2. **Bound, fresh and spent once.** The door writes the statement, and what he confirms is the door's own bytes. They name this authority, the statement's place in the order, the verb, the whole commit id, the main he was shown, and a number used once. A permission that lands with no judge also names the tree that would land. An unconfirmed statement expires, and a permission counts for one landing. *For: replay, and a word given elsewhere. Tried: V20 to V25, V30, V31.*
3. **A trusted path.** What he sees is made by the authority from its store and drawn on a surface no worker draws on. His choice returns by a way no worker types into. Words a worker wrote, such as a path, a branch name or a subject, are escaped, quoted and labelled as the worker's. *For: approving unseen. Tried: V40 to V43, and V50, V40r, V41r for a door that lacks a part of it.*
4. **He starts it.** No prompt comes to him. A statement begins with an act he makes for nothing else. *For: habit. Not tried: the mock's founder is a script.*
5. **No weaker side door.** Enrolling or replacing the key, the first start, recovery, and a login on the authority's machine or its hosting account are each as hard as the door. *For: going around. Tried in part: V60 and V61 show what a reader is told when a hand with the authority's login speaks as him.*

A door of the first two properties alone stops imitation and replay. The third is what the question's last part asks for, and it is a property of where the statement is shown. It is not a property of a key.

## 4. The mechanisms, weighed

Fourteen found so far. Each is an example of its kind. "Mock" names the kind of door that stood for it in the spike: `clean` (shown and confirmed on a surface no worker reaches), `touch` (the same key and signed statements, with the Mac as the terminal and no display on the key), `secret` (something he knows, typed at the Mac).

| # | Mechanism | Closes | Leaves open | Needs from him | Mock |
|---|---|---|---|---|---|
| 1 | **A command as the authority's login, typed in his own terminal, by password** (`su`, `sudo -u`). The 11-09 design's candidate, in one reading | None of the five, once he has typed it there | His terminal is a worker's surface. A start-up file a worker can write defines a function that runs in place of `/usr/bin/su`, even by its full path (run, §2). The password is then the worker's. With it the worker is the authority, and for `sudo` it is root | A password habit | `secret`: V53 |
| 2 | **The same, by Touch ID for `sudo`** | Out of reach: a fingerprint is not read | The sheet names no command and no target user (read: `pam_tid.c`). A process of his user should be able to raise it (inferred, not run). `sudo` then keeps the permission for five minutes for that terminal (read). Not set up here (run) | A root edit of the system's PAM files | `touch`: V50 |
| 3 | **A switch to the authority's own desktop, and a door there.** His choice on 2026-11-10 (§5) | A trusted path, if macOS keeps a switched-out session's processes off the screen and the keys. Apple's archived documents say such processes receive no keyboard or mouse input (read). No statement was found that one user's process is kept from capturing or posting into another's session. Out of reach, for a fingerprint | The password is asked after each restart, after 48 hours without an unlock, and after five misses (read; §5.3 says how often that may fall on him). It is typed at a login window, and no way was found for him to tell a genuine one from a window a worker draws (not found). That password is the authority. A statement carries no signature of his. The desktop does not carry to a server | The authority's login, a fingerprint for it, its desktop kept logged in, and a reach test (§7) | `clean` for how his word is read and what he is shown, if the separation holds. `touch` (V50) if it does not. Neither was shown for a real desktop |
| 3b | **The authority's console after a restart, before he logs in as himself** | Out of reach and a trusted path: no process of his user runs yet (inferred; it holds while no worker has root) | Minutes for each use. The statement carries no signature of his | A restart | `clean` |
| 4 | **A key in this Mac's Secure Enclave, under his own login** (the system's provider, or an app such as Secretive) | Out of reach. Bound and fresh, since it signs the door's bytes | A process of his user asks for a signature over bytes it chose. The sheet shows no commit: the reason text comes from the caller, and Secretive's prompt names the app and the key and not the data (read) | Making the key | `touch`: V50 |
| 5 | **A hardware key touched at the Mac** | Out of reach, and an act for each use. Bound and fresh | It has no display, so a worker's wrapper for `ssh`, or his `~/.ssh/config`, picks what the touch allows. For a signature kept on file, `ssh-keygen -Y verify` offers no way to require that the key was touched (read from its source) | Keys bought, and a provider library | `touch`: V50 |
| 6 | **A second device with a screen of its own as an SSH client, a key made on it, and a door that is the one command that key may run.** This document's first recommendation, and the form measured for a door reached over a network (§5.7) | The five, with the limits beside. The key is on the device. The door shows the candidate from the store on the device's screen. He starts each statement. One statement for each connection, since the door ends it (run: T1, T9) | The device has to be out of a session's reach: iPhone Mirroring (read). A third-party app holds the key. With no key lent the statement is not signed by him (§5.7). A founder who confirms without reading (V42h). A worker at the same address can shut the door for seconds at a time (run: T2b) | An app, a key, one line in a file of the authority's login, that login allowed for Remote Login, and mirroring off for this Mac | `clean`: V1 to V42 |
| 7 | **Row 6 with a hardware key tapped on the phone** | Adds: a tap is not an input a Mac can send (inferred), so mirroring no longer reaches the key. `sshd` asks for the touch by default (read) | A connection left open after the tap, which the door ends itself (run: T9) | Two keys bought, and an app that takes them. Termius, Blink and Prompt 3 document this over NFC (read) | `clean` |
| 8 | **A page the authority serves, approved with a passkey** | Out of reach, for a passkey that does not sync | A passkey made on his phone syncs to this Mac through iCloud Keychain (read). When the phone approves for a browser on the Mac, it is given the site's name and a hash, and no text of the statement (read). In his Mac's browser the page is a worker's to draw. Checking it needs a new runtime on the deciding path, which direction row 6 rules out | | Not run |
| 9 | **A comment or a label under his name at a forge, or mail.** The interim | Nothing against a session that drives his signed-in browser | The browser is signed in as him, whatever becomes of his token (inferred) | | 11-09 cases D1i, D2i. V12 shows the signed door does not read it |
| 10 | **A one-time code typed at the Mac** | Out of reach, for the seed | The code names no statement. A worker in his terminal spends it on another | | Not run |
| 11 | **A signer with a screen of its own,** as a bank's card reader shows the amount, or a small box that is the authority's console | The five in principle, with his signature on each statement | Showing a commit's facts on such a device needs code written for it. No maintained open-source phone app that signs a text it shows was found | A purchase | Not run |
| 12 | **A delay, a notice on a second device, and a way to cancel** | Detection, where a trusted path is missing | Each landing waits. The notice and the cancel are a second door | | Not run |
| 13 | **A signature made on his own machine** (a signed push, gitsign, a gittuf approval) | Bound, for what the signature covers | The key is used on the machine the worker runs on. None of the three projects' pages read claims to hold there | | `touch`: V50 |

The kinds, not the rows, are what the spike tried. A row marked `clean` rests on its surface being one no worker reaches, and the spike did not show that for any real surface.

## 5. The door he chose: the authority's desktop on this Mac

### 5.1 With no forge connected

The door reads the authority's store and writes it. Nothing in a statement's path calls a forge. A hold, a stop and a go were given and kept with the mock forge's directory shut (case V8). The mock's door also asks the forge for new candidates before it prints a card, and goes on when it cannot. Where a forge is connected, the door adds the pull request's number beside a head, marked as the forge's word.

### 5.2 What stands before the first statement

- **The authority's login** on this Mac (11-09 stage 2). It is the second login of his answer 5 on the 11-09 design: this Mac first, as a rehearsal. It is a standard login and not an administrator. It signs in to no Apple account, so that no keychain, watch or phone of his is joined to it (inferred, not read).
- **Its desktop is the door's terminal.** The door is bash in a terminal window of that login. That shell starts from the authority's files, in a home his user is to have no permission to write (11-09 rule 2; not read, since that login does not exist). His own terminal starts from files a worker can write, and there a function stood in for a binary named by its whole path (run, §2).
- **The separation it rests on.** Each login has a session of its own. A switched-out login's processes keep running and receive no keyboard or mouse input (read: Apple's archived documents, 2013 and older). One window server serves the sessions (read). No statement by Apple was found that a process of one user is kept from capturing another login's screen or posting into it. So this is taken from no page that was read. The reach test of §5.6 is what would answer it on this Mac, for what it tries. It holds no further than a worker without root does (inferred).
- **A fingerprint enrolled for that login.** With fast user switching on, Touch ID switches to a login that has logged in by password since the restart (read). A window a worker draws has no way to get a match, so what it can collect is a typed password (inferred).
- **One place for the authority's password:** the login window after a restart, before he logs in as himself. No login of his is open then, so no process of his has a session to draw in or to read keys from (inferred; a job his user scheduled can still run, with no screen). With that password a worker is the authority.
- **No road in from the network.** This door uses no `sshd`. Remote Login, screen sharing and remote management are not allowed for the authority's login. Port 22 is listening on this Mac today (§2), and for which logins was not read.
- **That desktop is to lock when it is left,** and to open to the fingerprint or the password. Which setting does that for a switched-out login was not read.

### 5.3 One statement

1. **He switches** to the authority's desktop, from the user menu or the sensor, with the fingerprint. Where the system asks for the password instead, he does not type it there. He restarts (§5.2).
2. **The door reads back:** the authority's name, where main is, whether he has said stop, his last statements, and each permission of his that is not yet spent.
3. **It lists what waits on his word,** from the store.
4. **He picks one and a verb.** The door prints the card: the verb in words, the whole commit id, the main it is shown against, what would land, each founder path the change touches, the count of other paths, the judge's last result on this head, and the worker's words, each escaped, quoted and labelled.
5. **He confirms** by typing the verb and the four characters of the id that the card brackets. The door chooses where the brackets go, anew for each statement. A confirmation that does not match closes the statement, and he asks again (decisions 16 and 17).
6. **The door writes the statement** (§5.4), recorded as given at the authority's desktop. No key is used, and the statement carries no signature. What stands behind it is that this desktop was unlocked and that the door ran there.
7. **The door keeps the statement** in the store, in order, tells him its number, and **locks the desktop,** so that one unlock gives one statement. That rests on a lock from bash, which was not read for this macOS (§10).
8. **He switches back.**

**What it costs.** The mock door's own work for one statement took a median of 103 ms to ask and 52 ms to check and keep (ten statements; one ask took 2.4 s). What a statement costs him was not measured: a switch, a fingerprint, a card to read, a typed confirmation and a switch back.

**The larger cost is the password.** It is asked again after a restart, after 48 hours with no unlock, after five misses, and after 156 hours since it was last typed where no fingerprint was used in the last four (read). If those clocks run for each login, a founder who speaks less often than every two days restarts for each statement, and one who speaks daily restarts about once a week. Whether they run for each login or for the Mac was not read.

### 5.4 What is kept

The statement is text that the door writes, and no field in it comes from outside the door.

```
felix-door/v1
authority: <the digest of the start commit and the authority's public key>
serial: 17
prev: <the digest of statement 16>
verb: override
commit: <40 hex>
tree: <40 hex: what would land; for an override>
main: <40 hex: the main he was shown>
card: <the digest of the card as it was printed>
key: <none at the desktop; over a network, the fingerprint of the key that opened the connection>
given: desktop | console | connection | signed
nonce: <used once>
at: <the authority's clock>
```

- **The log is a ref in the authority's store.** Each statement is a commit on it whose parent is the statement before, moved by compare-and-swap, with the signature beside it where there is one. The mock keeps files and an index. A ref is chosen for the build so that the store's own backup and the signer reach it (11-09 decision 6).
- **`main` and `card` are context.** They say what he was shown. No decision reads `main`: what binds an override is its tree. The review found that field feeding nothing in the mock, and it is kept for the record alone.
- **`given` says how his word arrived:** at the authority's desktop, reached by a switch; at its console after a restart, with no login of his open; over a connection his key opened; or signed by his key over these bytes. The door he chose gives the first two. A reader elsewhere checks a signed statement itself. For the other three it has the authority's word, and is told so. How the door tells the desktop from the console is for the build.
- **Each landing record names the statements it leaned on,** and a reader checks each: the authority, the place in the order, that the commit is the record's head, that an override's tree is the record's tree, that a permission was not spent before, and the signature where there is one. On the mock, a hand with the authority's login that wrote an override into the door's index landed a defect, and the reader was told the record was unverified (V60). The same for a spent authorization used again (V61). V60's reader was told so because that statement carried no signature. At the desktop none does, so a reader that expects one says unverified of his own statements too: on the mock's door with no key it did, in each case where a landing leaned on his word. A reader made for that door takes such a statement on the authority's word, says how many it took so, and makes each other check. On the mock it reported V61's spent permission, and a record that names a statement the log does not hold (V60). It said ok of an override that hand wrote out in full (VD4). So a reader has no way to tell his statement from one that hand wrote (§10).

### 5.5 How the kernel reads his word

- **His later word wins.** Statements are read in their order. A hold covers each candidate whose history holds the commit it names, until a release that comes after it and names that exact head. A hold given after a release holds again (V5).
- **A hold takes back.** An authorization or an override is in effect while it is unspent and no hold that covers its head was given after it (V6, VR8). A release after that hold does not bring the permission back: he gives it again (VR9).
- **A hold is a lock on a commit, and not on a change.** The same edit made again under a new commit id is not held by it (VR4, and 11-09 decision 4). What must wait for him because of its content is a founder path, and what holds whatever comes is his stop.
- **An override names the tree he was shown.** If main has moved, so that the head would now land as another tree, the override is not in effect, and the door says so until he gives it again (V31).
- **A permission is one statement, by its number,** and the landing it allowed spends that number (V20, VR2).
- **Stop and go** are read the same way: the later of the two.
- **A permission does not lapse with time.** The door reads each unspent one back to him when it opens, and a hold takes it back. Rejected: a timer, which would let the authority's clock or a slow judge undo his word.

### 5.6 The first start, the fingerprint, the reach test, and losing the way in

- **At the login window after a restart, before he logs in as himself,** he logs in as the authority with its password (§4, row 3b).
- **The first start** is statement 0: he names the commit main starts from. It is given there.
- **The fingerprint** is enrolled there. A finger he uses for nothing else would make the switch an act he makes for the door alone (property 4). Whether macOS lets one finger open two logins was not read.
- **The reach test comes before any statement given by a switch.** The first start does not wait for it: it is given at the console after a restart, with no login of his open. The authority's desktop is in front and his own login is switched out. A session under his login, with the screen and input permissions its tools hold today, tries to see that desktop and to act on it. Examples of what it tries: capturing the screen, posting keys and clicks, reading keys, raising a window in front, and asking the system to run something in that session. On the authority's desktop a witness records what arrived, and he compares what the session captured with what he saw. The door stands on this Mac if nothing of that desktop reached the session and nothing of the session reached that desktop. Those are examples of tries, and a pass says what was tried.
- **If it fails,** this desktop is V50's terminal. The door is then the console after a restart for each statement (row 3b), or another row of §4.
- **The test is described here, and not written or run.** It needs the authority's login, and him at the screen.
- **Losing the way in.** A fingerprint that stops matching: a restart and the password. A password forgotten: an administrator resets it, and his own login is one (inferred, not read for this macOS). So a worker that has his admin password has the authority's (§8).

### 5.7 Later: Felix's own interface, and a server

- **His reason,** in his words, is "a smoother transition to our infra UI later". This document reads "our infra UI" as the interface Felix's own infrastructure will have, and calls it Felix's own interface. What it is was not asked. So the card and the statement are made by one function from the store, and the terminal window is one way to draw them. Another interface draws the same card and returns the same confirmation, and what is kept does not change.
- **What that interface has to keep is property 3.** It is drawn on a surface no worker draws on. On this Mac that can be the authority's desktop. A page opened in the browser of his own login is a worker's surface, whatever serves it (§4, row 8). What Felix's interface is belongs to the interface direction, and is not designed here.
- **On a server the desktop does not follow.** The authority's console is then not this Mac's screen, and a door needs a terminal that reaches it. The form measured for that is row 6: a device with a screen of its own as an SSH client, a key made on it, and a door that is the one command that key may run. What the transport trial showed for it:
  - **One line in the key file of the authority's login:** `restrict,pty,command="<the door>" <the key's public half>`. With `restrict` and a forced command, the door ran whatever the client asked for, and the client's own command was kept as text (T1). Under `restrict` the client's agent and locale did not arrive (T3). With `pty` added the door had a terminal (T3c).
  - **One connection gives one statement because the door ends the connection** (T9). Where it did not, a client that shared one connection among several sessions got three statements on one authentication (T7).
  - **No key is lent.** With the key lent for a signature (T5), a false door whose changed host key had been accepted used it to open the true door as him (T13). With no key lent it could not (T13b). A client that held the door's host key refused the false door (T12).
  - **Enrolling a device's key, and taking a lost one out, needs a way in that is not the door.** On this Mac that is the console after a restart, with the key's fingerprint compared on the two screens. On a server it is the host's own console, which the hosting account opens (§8). Not designed, and no row tried it.
  - **A connection kept the line it had authenticated with after that line was changed** (T7b). So taking a key away is not expected to end a connection that key already opened (inferred from that row).
  - **Three refusals of a key that was not enrolled shut this `sshd` to that address for about 15 seconds** (T2b).
- **His answer about the phone applies there** (§11, call 2): this Mac off the phone's mirroring list, and keys that are tapped on the phone before the authority moves to a server (§4, row 7).
- **What else differs on a server** is the side door: the hosting account. §8 records it.

### 5.8 What the mock says about this door

The mock's `clean` door was run with a signing key on 2026-11-10, and the desktop door has none. This section first sorted the 47 cases by argument. On 2026-11-13 the mock was given a door with no key, and each case that can run there as it is written was run there: 29 of the 47, and four new ones (the report's §10). What each was expected to end as was written down before it ran, and each ended so. What stands for the authority's desktop is still a directory the worker's sandbox denies. So this is the door's protocol with no key. It is not the desktop, and the separation of §5.2 is as unmeasured as before.

- **How his word is read: V1, V2, V3, V4, V5, V6, V7, V8, V30, V31, and the review's VR2, VR4, VR8 and VR9. What he is shown: V40, V41, V42, V43 and VR5.** Each of the nineteen ended at the door with no key with the outcome it had at the signed door. The kernel is the same file in both runs.
- **What a reader of main is told changed, as argued.** A reader that expects a signature said unverified wherever a landing leaned on his word. It said so of a statement he gave (V1) as of a row written by a hand with the authority's login (V60). A reader made for this door takes an unsigned statement on the authority's word, says how many it took so, and makes each other check (§5.4).
- **What he types.** At this door he types the verb and four characters of the id, and the door compares them with its own statement. With the worker's words printed as they are, the drawn card that got his signature at the signed door (V40r) was refused here: he typed four characters of the id he meant, at a place the worker had guessed. With the brackets in one known place, the worker made its commit again until the id agreed with his there, and the door kept the worker's head (VD3, and decision 16). A founder modelled as not reading typed what the card bracketed (V41r, V42h). A statement has one try, and a confirmation counts once (VD2, and decision 17).
- **A road this door does not have: V10, V11, V14, V20 to V25, VR3 and VR7** hand a signature in, and were not run there. In their place one case was written. With an override of its own defect open and nobody at the door, a worker that knew the statement and its card put the right confirmation where the intake had been. The door read none of it and kept nothing (VD1). The worker's tries at the door's own files failed against its sandbox. On the real door what stands there is the reach test, which was not run. VR1, which also puts odd paths in the door's list, ran and ended the same. V20's rule, that a landing spends the permission it used, is the kernel's, and VR2 showed it again.
- **The Mac as the terminal, inside his own login: V50, V51, V52 and V53** are about another terminal and were not run there. V50 and V53 show what a failed separation, or a password typed in the wrong place, costs. V51 and V52 are their controls.
- **A hand with the authority's login: V60, V61, V62, and the new VD4.** The reader made for this door reported an index row with no statement behind it (V60) and a spent permission used again (V61). It said ok of an override that hand wrote out in full (VD4), and of a dropped hold (V62).
- **As they are: V12, V13 and VR6** ran there and ended the same. The door does not read the forge, and judged code did not reach the door's files.
- **The variants V5f, V6f and V31f** are about the 11-09 mock's file door, and were not run there.

## 6. Decisions made here

These are Felix's. Each names what was rejected.

- **Decision 1. The door is a terminal apart from his own login, and not a credential used inside it.** Rejected: rows 1, 2, 4, 5 and 13 of §4 as the door, since each leaves the commit to be shown by the worker. The desktop he chose is on this Mac, and is a terminal apart as far as a reach test would show (§5.6; not run).
- **Decision 2. The door writes the statement, and he confirms the door's bytes.** Rejected: a statement composed on his side and parsed by the door. On the mock, a whole statement written and signed by a worker was refused because no statement of the door's was open, and no field of it was read (V14).
- **Decision 3. His statements are read in order, and a hold takes back a permission** (§5.5). Rejected: the 11-09 mock's reading, in which a release anywhere passes a hold and an override passes each hold.
- **Decision 4. An override names the tree that would land.** Rejected: an override of a head on whatever main has become. On the 11-09 mock's door that landed a tree whose content he had not been shown (V31f).
- **Decision 5. A statement names its authority and its place in the order.** A signature given to another authority, or under another use of the same key, does not count here (V23, V24).
- **Decision 6. What he is shown is the authority's facts first.** Each founder path the change touches is listed whole, before the rest and never cut. A worker's words are escaped to printable ASCII, quoted, and put on a line whose label the door wrote. Rejected: printing them as they are, with which a file name redrew the screen and he authorized a head he had not read (V40r), and a list in the tree's order cut at ten, with which a change to the founder-path policy itself went unseen and landed (V41r).
- **Decision 7. He is not asked to match a short id.** The card shows the whole id. The typed confirmation is there to make the act deliberate. It does not identify the commit: four characters are cheap to grind. On the mock a worker made a commit whose id agreed with his at four known places in 83,083 tries in one run and 26,635 in another (VD3).
- **Decision 8. One statement is open at a time, and each statement has its own gesture.** At the desktop the door is to lock after one statement, so that one unlock gives one (the lock was not read, §10). Over a network the door ends the connection, so one connection gives one (T9, and T7 for where it did not). Rejected: a sitting in which one unlock gives several statements. The decided list asks for each statement "at the moment he says it".
- **Decision 9. Each statement says how it was given, and each record says which statements it leaned on.** This extends 11-09 decision 9. Felix does not report a signature that is not there. A reader says how many statements it took on the authority's word, as the mock's reader made for the door with no key does (§5.8).
- **Decision 10. A permission does not lapse with time** (§5.5).
- **Decision 11. The door and the kernel read the founder-path policy through one function.** In the mock they were two, and they differed on one path of fourteen until the kernel was fixed: a path with a newline, which the door listed as his and the kernel did not hold (V43). Rejected: two readers kept alike by care.
- **Decision 12. A statement at the door he chose carries no signature of his.** At the desktop no key is used. Over a network the form measured lends no key: rejected for now, a signature by a lent key, which a false door can use once its host key is accepted (T13). Rejected: a signature made in his own login, and holding the door back until a signer is found. What is given up is in §10.
- **Decision 13. The authority's password is typed in one place: the login window after a restart.** Otherwise he comes in by fingerprint. Rejected: typing it at a login window reached by a switch, where his own login's processes run, and where no way was found to tell a genuine login window from a drawn one. This is a habit of his and not a mechanism, and it is listed as open.
- **Decision 14. No statement given by a switch counts before the reach test has passed on this Mac.** The first start is given at the console after a restart, with no login of his open, and does not wait for it. Rejected: taking the separation between logins from documents. In the pages read, none states it.
- **Decision 15. The card and the statement are made by one function, and a surface draws them.** So the terminal window can give way to Felix's own interface with no change in what is kept. Rejected: a door whose protocol lives in its screen.
- **Decision 16. The door chooses where the brackets go, anew for each statement.** Rejected: the same four places each time. On the mock, with the worker's words printed as they are and the brackets in one known place, the worker drew his card, made its commit again until the id agreed with his at that place, and the door kept the worker's head on four characters he typed from his own id (VD3). With the place chosen by the door, a drawn card that guessed the place was refused (V40r at the door with no key). A drawn card with such a commit that guesses the place is right one time in 37 (arithmetic, not run). So this is a second line behind decision 6, and does not stand in for it.
- **Decision 17. A statement has one try.** A confirmation that does not match closes the open statement, and he asks again (VD2). Rejected: leaving it open for another try. Four characters are 65,536 guesses.

## 7. What the founder would have to do

Each row is his to do, and this session did none of them. His answers of 2026-11-10 chose a direction. The question he answered said that each act under it is still his to approve separately.

| # | Act | Where | Why |
|---|---|---|---|
| 1 | Make the authority's login: a standard login, signed in to no Apple account | This Mac, System Settings | 11-09 stage 2, and his answer 5 there. The door's terminal is that login's desktop |
| 2 | Not allow Remote Login, screen sharing or remote management for that login | This Mac, System Settings | No road in from the network (§5.2) |
| 3 | Restart and log in as the authority first. There: enrol a fingerprint for it, set its desktop to lock when it is left, and give the first start | The login window, then the authority's desktop | §5.6 |
| 4 | Run the reach test with a session, he at the screen | Both logins | The riskiest assumption (§5.6, §10). Before any statement given by a switch |
| 5 | Keep one place for the authority's password: the login window after a restart | | §5.2. A habit: no mechanism was found |
| 6 | For each statement: switch by fingerprint, read the card, type the confirmation | The authority's desktop | §5.3 |

**For a door reached over a network, later** (§5.7), the acts are the ones this document first listed: an SSH app and a key on the phone, this Mac off the phone's iPhone Mirroring list, keys that are tapped on the phone before the authority moves to a server (his answer to call 2), Remote Login for the door's key, and the two fingerprints compared on two screens. None is due for the desktop door.

What Felix builds, in bash, once the login exists: the door, the kernel's reading of its log, the reader's check, the reach test and its witness, and the lock at the end of a statement.

## 8. What this changes in the 11-09 design

A section or rule in bold is the 11-09 design's. One in brackets is this document's.

- **§5.5, the candidate** ("a command run as the authority's login, which this Mac allows after his password or his fingerprint") is rejected (§4, rows 1 and 2). What he chose is not that candidate. It is the authority's own desktop (row 3).
- **§9, call 6** ("At Felix's own door") now has a surface: the authority's desktop on this Mac, by his answer of 2026-11-10 (§11).
- **Stage 2** gains the reach test, before his word counts (§5.6).
- **§5.5, "by something he knows or is, at the moment he says it"** says who he is, and not what he was shown. It needs a third part: shown from the store on a surface no worker draws on.
- **Rule 7** gains the order of his statements, the hold that takes back, and the authority and number in each statement (§5.5).
- **Rule 12** gains the tree: an override lands the tree he was shown, or is given again.
- **Rule 2** needs a further clause. "No worker can log in as the authority" has to cover recovering an account that can. Where the server's hosting account is opened in his browser, or can be reset through his mail, a session that drives both has what that account has. No provider was read. This belongs to call 5 and stage 5 and is open there.
- **§3, class 9** is no longer "Not shown" for the protocol of a door with a key, on a mock. Since 2026-11-13 the same holds for the protocol of a door with no key, on the same mock (§5.8). It is still not shown for a real surface: neither a phone nor the desktop he chose.
- **§5.5, the interim** is worth less than stated. A session that drives his signed-in browser comments as him with no token, so taking his token out of an agent's reach does not close it (inferred; GitHub was not exercised).
- **§8, the rehearsal's wall** ("one admin password") is weaker than "one password away" reads. That password is typed in a terminal of the worker's user, where a function can stand in for `sudo` (§2). The desktop door stands behind the same wall: with his admin password a worker is root, resets the authority's password, and reaches its session (inferred).
- **The 11-09 mock's door** has the three gaps of §1. They are in pull request 504's kernel. On 2026-11-10 he chose to land that pull request with its mock's defects recorded as open against it, to be fixed when the authority is built. The question put to him named the first two of these gaps and the newline path of decision 11. Whether what is recorded there covers the third gap (V31f) is that pull request's to say.

## 9. The second derivation

A second author derived the door from the same decided list, without sight of this one's reasoning or mock, and ran its own reads on this Mac (`sources/second-derivation.md` in the audit folder; the facts read for both are in `sources/facts.md`, each with its source).

- **It reached the recommendation this document first made:** a second device as an SSH client, a forced-command door, a tapped key as the advised upgrade, and the console after a restart for enrolling and recovery. It named the riskiest assumption this document then named: the phone's reach.
- **Taken from it:** the function that stands in for `su` (its run, repeated in §2); the statement's `card` digest and `key` fingerprint; the typed confirmation; the log as a ref; the door reading his recent statements back; and four of §8's points (the interim, the hosting account, the first start having no door, and "names a commit" not being "sees a commit").
- **Where this design differed, and where it ended:** the second derivation accepted statements with no signature of his as the cost. This design set out to sign each one, because a signature is what lets a reader tell the founder from a hand with the authority's login (V60, V61). The trial then showed what the one way found costs (T13). So a door over a network lends no key, as the second derivation has it, each statement says how it was given, and signing is open.
- **Two authors agreeing is not a proof.** Both read the same Apple pages and neither held a phone.
- **Neither author recommended the desktop.** Both weighed it (row 3 here, and row 3 of the second derivation) and recommended the phone. This document's reasons were the login window, and a separation between logins that no page read states. The founder weighed what neither did: where Felix's own interface will later be drawn.

## 10. Open

These are the open items seen so far. More will come.

**For the door he chose**

- **Whether a process of his user reaches the authority's desktop.** No statement by Apple was found either way for capturing that screen or posting into it. The reach test answers it on this Mac, for what it tries (§5.6). It was not run: it needs the authority's login.
- **A genuine login window.** No way was found for him to tell one from a window a worker draws, and no documented key sequence that reaches a genuine one. Published write-ups show a process of the same user drawing a password prompt with its own title, icon and text (read). Decision 13 answers with a habit.
- **How often the password is asked.** Whether the 48-hour and 156-hour clocks run for each login or for the Mac was not read. It sets how often he restarts (§5.3).
- **Locking from bash.** How the door locks the authority's desktop after a statement was not read for this macOS.
- **Root.** With his admin password a worker is root, and root reaches each login on this Mac (inferred). That password is typed in a terminal of the worker's user (§2, §8). The desktop door does not change that.
- **No signature of his.** A statement rests on the authority's word, and a reader has no way to tell his override from one written by a hand with the authority's login (V60 shows the reader's check working where there is a signature, and VD4 shows a reader made for a door with no key saying ok of an override that hand wrote out in full). It matters most once the authority is on a server. What is needed is a signer that shows what it signs, or a key lent to the door alone.
- **The cases at a door with no key.** Run on 2026-11-13, for the 29 that can run at such a door as they are written (§5.8). The other eighteen were not. The mock's door with no key was read and run by its author alone: a fresh reviewer was started, and the model's safeguards stopped it before it ran a case.
- **Felix's own interface.** What it is, and that it is drawn where no worker draws (§5.7).
- **What he was not asked.** Whether this Mac comes off the phone's mirroring list now, with the phone not the door (§11).

**For a door reached over a network** (§5.7)

- **Whether the phone is out of reach.** Whether this Mac is on his phone's mirroring list, and whether it connects unasked, was not read. Apple's note says a request for the face alone fails while a phone is mirrored, and that an app may choose to let the Mac approve instead (read). Which of the apps named does that was not read.
- **The app.** That it keeps the key in the phone's hardware and asks at each use is from vendors' pages. None was installed.
- **The terminal on the phone.** The mock's reader of the screen handles four things a terminal does. A real one does more.
- **Shutting the door.** After three refusals of a key that was not enrolled, this `sshd`, as it ships, refused the enrolled key from the same address for about 15 seconds (T2b). A worker behind the same address as the phone can repeat that. A hold and a stop are the statements this hurts.
- **A changed host key.** What each app shows when the door's host key changes, and how easily it is tapped through, was not read. With no key lent, a false door was reached and did not open the true one (T13b). It would still learn what he typed.

**For any door**

- **A founder who does not read.** The door showed the truth and a founder modelled as going by the title confirmed the wrong change (V42h, at the signed door and at the door with no key). No mechanism found closes that. Property 4 and the typed confirmation make the act deliberate, and a model of a person shows nothing about a person.
- **What the card escapes.** The door's escaping leaves printable ASCII alone, and look-alike characters within it (`l`, `1`, `I`) are not treated.
- **Saying stop with the door out of reach:** the Mac off or away, or the desktop not opening. Not designed.
- **The hosting account** (§8).
- **A dropped statement.** A hand with the authority's login dropped his hold from the log, the change landed, and both of the mock's readers said ok (V62). The door reads his recent statements back each time it opens, so he could notice. A reader elsewhere could not. A signed and dated statement of the log's tip would let one (11-09 §8, "a reader with no memory"). Not designed.
- **Two processes at the door's log at once.** The mock runs one at a time. The build's log is a ref moved by compare-and-swap for that reason, and that is a claim about a build that does not exist.
- **The review.** A fresh reviewer, given the mock's code and not this document, found no break in nine cases of its own. Two routes it reasoned about and did not run were run afterwards: V43 found the difference of decision 11, and V62 the dropped statement. It also named what makes rows read stronger than they are, which the report repeats. One review of one day's mock is not an audit, and a review that finds no break is weaker evidence than one that finds some. It reviewed the door with its key. The mock's door with no key has had no review (above).

## 11. The founder's calls

Two calls followed from this design. He answered both on 2026-11-10 at 07:22Z, in the question dialog of the session that put them to him. His answers are copied here from that session's record.

| # | The call, as it was put | The outcomes offered | His answer |
|---|---|---|---|
| 1 | "Which surface is it first?" | "My phone (Recommended)". "A screen on this Mac". "A signer with its own screen". "Keep the interim for now" | He picked none of the four and wrote his own answer: **"we can do a screen on this mac...the reason is imo a smoother transition to our infra UI later"** |
| 2 | "If your phone is the door, how is it kept out of a session's reach?" | "Unpair the Mac, keys later (Recommended)". "Unpair the Mac only". "Hardware keys only". "A separate device" | **"Unpair the Mac, keys later (Recommended)":** "This Mac comes off the phone's mirroring list now, so no session here can drive the phone. Hardware keys you tap are added before the authority moves to a server." |

**How call 1 is read.** His words repeat the label of the second outcome, "A screen on this Mac", whose text read: "The authority's own desktop on this Mac shows you the change. It is quicker to start, but sessions run on the same machine." This document reads his answer as that outcome, and §5 is that door. If he meant another screen on this Mac than the authority's desktop, §5 is his to correct. It is not the outcome this document recommended. It agrees with his answer 5 on the 11-09 design: this Mac first, with a second login as a rehearsal.

**How call 2 is read.** It was asked on a condition, "If your phone is the door", and the phone is not the door first. So:
- As §5 designs it, the desktop door has no step that uses the phone, so no act under this answer is due for it. That rests on the authority's login being joined to no Apple account (§5.2, inferred).
- The answer is kept as he gave it. It comes due where a phone becomes a door, and its own words set the latest time for the keys: "before the authority moves to a server" (§5.7).
- Its first half, "This Mac comes off the phone's mirroring list now", was chosen with the phone as the door in view. Whether he wants that done now all the same is his, and is not assumed.

**A call picks a direction.** The question said so: "each act under it, such as making a key or changing a device, is still yours to approve separately." Each act of §7 is still his.

Nothing in this design needs felix-home's visibility to change. It stays private.
