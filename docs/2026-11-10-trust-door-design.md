# The founder's door: how his word reaches the authority

2026-11-10 (dates in UTC). A design for the door that `docs/2026-11-09-trust-hosted-authority-design.md` §5.5 leaves open: "How it works is not designed." That design is on pull request 504, which is open and not merged, so it is cited here by its path on that branch and called "the 11-09 design". The measurement beside this document is `docs/2026-11-10-trust-door-spike.md`. Its code and logs are in the memory root under `audits/2026-11-10-trust-door/`, called "the audit folder" below.

**Scope.** A design, which is Felix's to decide: how one statement of the founder's reaches the authority, what the door shows him, what is kept, and what he would have to do for it. Nothing is built in `engine/`. No login, account, key, token, repository, App or setting was made or changed, and no key of the founder's was read or used. The spike made its own keys for each run, inside that run's directory, and installed none of them. No phone, hardware key, second login or SSH app was used. Statements about Apple's systems, OpenSSH, FIDO and the apps named are from documentation read on 2026-11-09 and 11-10 through a tool that summarises long pages. Where a row says "run", it was run on this Mac.

**Outside this document, and where each belongs:**
- what makes a path a founder path (P, and step 3);
- the signer of landing records (11-09 rule 8);
- which host the authority moves to, and who can recover that host's account (11-09 §9 call 5, and stage 5). §8 records what this work found about it and does not answer it;
- a place for candidates and a doorbell where no forge is connected (11-09 §5.3). §5.1 says what the door itself needs from a forge;
- the interim, in which his yes is read from GitHub (11-09 §5.5). §8 records what this work implies for it;
- a door for more than one person, or for other people's repositories (the product roadmap);
- a sandbox for the workers' own sessions (direction, "Not before March").

**This is an open set.** The properties, mechanisms, routes and cases below are what one session found in one day, with one second derivation written blind and one adversarial review of the mock. A count says what it counted. A route found later is a new row.

## 1. Answer

The question: can the founder give a statement in a way that a session running as him, with tools that drive his browser and his screen, cannot imitate, cannot replay, and cannot get him to approve without his seeing the commit it names?

- **Imitating and replaying: yes, and by more than one mechanism.** A key that no process of his user can use closes both, in two ways that were tried. It signs bytes the door wrote for one exchange: on the mock, ten cases tried to imitate him or to replay a signature of his, and in none was a statement kept that he had not given in that exchange (cases V10, V12 to V14, V20 to V25). Or it opens the connection the door runs on: against this Mac's `sshd`, a key that was not enrolled did not reach the door, and a false door that was handed no key could not open the true one (rows T2, T13b).
- **Approving unseen: yes, where the commit is shown and his choice is taken on a surface no worker draws on or types into. No mechanism found closes it without such a surface.** A password, a fingerprint or a touch shows that he was there. None of them carries what he was shown. On the mock the same key and the same door, with the Mac as the terminal, kept his override of a worker's defect while he meant to authorize another change (case V50).
- **So what decides is the terminal, and not the credential.** §3 gives five properties a door needs. §4 weighs the mechanisms found so far against them.
- **Recommended: his phone is the door's terminal.** An SSH client on the phone holds a key made on the phone. That key may run one command at the authority, the door, which is bash over the authority's own store. The door shows him the candidate from the store, takes his typed confirmation, writes the statement, and ends the connection. In this first form a statement is recorded as given over his key's connection, and carries no signature of his. A signature is what would let a reader elsewhere check his word, and the one way tried to get it, lending the device's key to the door, also let a false door open the true one (T13). So signing waits (§5.3, step 7). The first start, enrolling a key and recovering from a lost phone happen at the authority's own console after a restart, before he logs in as himself (§5).
- **What it needs from him** is in §7: an app and a key on his phone, one line in a file of the authority's login, that login allowed for Remote Login, and either this Mac taken off the phone's mirroring list or a hardware key that is tapped on the phone. The parts at the authority wait for the authority's login (11-09 stage 2).
- **The riskiest assumption is that the phone is out of a session's reach.** Apple's iPhone Mirroring lets a Mac on the same account show and operate the phone, and it can be set to connect with no question asked. No mock measures that. He can read the setting on the phone (§10).
- **The 11-09 design's own candidate is rejected:** a command run as the authority's login from his terminal, after his password or his fingerprint. His terminal is a worker's surface (§4, rows 1 and 2).
- **Three gaps were found in the 11-09 mock's door,** each shown on that door and closed at the signed one: a release passed over a hold he gave after it (V5f), nothing short of stop took back an override (V6f), and an override landed a tree he had not been shown (V31f).
- **The spike** (`docs/2026-11-10-trust-door-spike.md`): 47 cases on the mock, 38 of the author's and 9 of the review's, none ending otherwise than expected (final run, 2026-11-10 from 04:12Z to 04:15Z). Twelve of the 47 were written to show a route open, and their outcome is the harm. The door's transport was tried against this Mac's own `sshd`, started by the spike as the current user on a loopback port: 13 rows as expected and 5 readings.
- **Not shown,** and said again in the report: a phone, an app, a hardware key, a second login, a gesture, a person reading a screen, or mirroring. In the mock the "phone" is a directory the worker's sandbox denies, and the founder is a script.

## 2. Today, read

Read on this Mac on 2026-11-10 at 04:22Z by `spike/door-today.sh` (`logs/door-today.tsv` in the audit folder). The probe reads versions, whether files exist, permission bits and counts. It opens no key, raises no dialog and runs no `sudo`.

| What | Read | So |
|---|---|---|
| This user | An administrator | One password stands between a worker and root, and so between a worker and each other login on this Mac |
| A shell function named `/bin/echo`, then `/bin/echo` run by its full path, in zsh and in bash | The function ran | A full path typed in his shell does not reach the binary once a start-up file has defined a function of that name |
| `~/.zshenv`, `~/.zprofile`, `~/.zshrc`, `~/.ssh/config` | Writable | A worker can write what his shell and his `ssh` read when they start |
| Touch ID for `sudo` | Not set up (`/etc/pam.d/sudo_local` is absent) | `sudo` asks for his password, typed in a terminal of the worker's user |
| Remote Login | Port 22 is listening. The system's `sshd` accepts `LANG` and `LC_*` from a client | An `sshd` door needs no new service here. The door sets its own locale |
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
| 3 | **A switch to the authority's own desktop, and a door there** | A trusted path, if macOS keeps a switched-out session's processes off the screen and the keys. Apple's archived documents say such processes receive no keyboard or mouse input (read). No statement was found that one user's process is kept from capturing or posting into another's session | The password is asked after each restart, after 48 hours without an unlock, and after five misses (read). At a few statements a week that is most times. It is typed at a login window, and no way was found for him to tell a genuine one from a window a worker draws (not found). That password is the authority. It does not carry to a server | A fingerprint for that login, and its desktop kept logged in | `clean`, as far as the mock goes |
| 3b | **The authority's console after a restart, before he logs in as himself** | Out of reach and a trusted path: no process of his user runs yet (inferred; it holds while no worker has root) | Minutes for each use. The statement carries no signature of his | A restart | `clean` |
| 4 | **A key in this Mac's Secure Enclave, under his own login** (the system's provider, or an app such as Secretive) | Out of reach. Bound and fresh, since it signs the door's bytes | A process of his user asks for a signature over bytes it chose. The sheet shows no commit: the reason text comes from the caller, and Secretive's prompt names the app and the key and not the data (read) | Making the key | `touch`: V50 |
| 5 | **A hardware key touched at the Mac** | Out of reach, and an act for each use. Bound and fresh | It has no display, so a worker's wrapper for `ssh`, or his `~/.ssh/config`, picks what the touch allows. For a signature kept on file, `ssh-keygen -Y verify` offers no way to require that the key was touched (read from its source) | Keys bought, and a provider library | `touch`: V50 |
| 6 | **A second device with a screen of its own as an SSH client, a key made on it, and a door that is the one command that key may run.** Recommended | The five, with the limits beside. The key is on the device. The door shows the candidate from the store on the device's screen. He starts each statement. One statement for each connection, since the door ends it (run: T1, T9) | The device has to be out of a session's reach: iPhone Mirroring (read). A third-party app holds the key. In the first form the statement is not signed by him (§5.3). A founder who confirms without reading (V42h). A worker at the same address can shut the door for seconds at a time (run: T2b) | An app, a key, one line in a file of the authority's login, that login allowed for Remote Login, and mirroring off for this Mac | `clean`: V1 to V42 |
| 7 | **Row 6 with a hardware key tapped on the phone** | Adds: a tap is not an input a Mac can send (inferred), so mirroring no longer reaches the key. `sshd` asks for the touch by default (read) | A connection left open after the tap, which the door ends itself (run: T9) | Two keys bought, and an app that takes them. Termius, Blink and Prompt 3 document this over NFC (read) | `clean` |
| 8 | **A page the authority serves, approved with a passkey** | Out of reach, for a passkey that does not sync | A passkey made on his phone syncs to this Mac through iCloud Keychain (read). When the phone approves for a browser on the Mac, it is given the site's name and a hash, and no text of the statement (read). In his Mac's browser the page is a worker's to draw. Checking it needs a new runtime on the deciding path, which direction row 6 rules out | | Not run |
| 9 | **A comment or a label under his name at a forge, or mail.** The interim | Nothing against a session that drives his signed-in browser | The browser is signed in as him, whatever becomes of his token (inferred) | | 11-09 cases D1i, D2i. V12 shows the signed door does not read it |
| 10 | **A one-time code typed at the Mac** | Out of reach, for the seed | The code names no statement. A worker in his terminal spends it on another | | Not run |
| 11 | **A signer with a screen of its own,** as a bank's card reader shows the amount, or a small box that is the authority's console | The five in principle, with his signature on each statement | Showing a commit's facts on such a device needs code written for it. No maintained open-source phone app that signs a text it shows was found | A purchase | Not run |
| 12 | **A delay, a notice on a second device, and a way to cancel** | Detection, where a trusted path is missing | Each landing waits. The notice and the cancel are a second door | | Not run |
| 13 | **A signature made on his own machine** (a signed push, gitsign, a gittuf approval) | Bound, for what the signature covers | The key is used on the machine the worker runs on. None of the three projects' pages read claims to hold there | | `touch`: V50 |

The kinds, not the rows, are what the spike tried. A row marked `clean` rests on its surface being one no worker reaches, and the spike did not show that for any real surface.

## 5. The recommended door

### 5.1 With no forge connected

The door reads the authority's store and writes it. Nothing in a statement's path calls a forge. A hold, a stop and a go were given and kept with the mock forge's directory shut (case V8). The mock's door also asks the forge for new candidates before it prints a card, and goes on when it cannot. Where a forge is connected, the door adds the pull request's number beside a head, marked as the forge's word.

### 5.2 What stands before the first statement

- **The authority's login** on the machine the authority runs on (11-09 stage 2).
- **A key made on his device,** which does not leave it.
- **One line** in the key file of the authority's login: `restrict,pty,command="<the door>" <the key's public half>`. By `sshd`'s manual that key then runs the door whatever the client asks for, and `restrict` turns off forwarding. Run on the mock transport: the door ran whatever the client asked for, and the client's own command was kept as text (T1). Under `restrict`, the client's agent and locale did not arrive (T3). With `pty` the door had a terminal (T3c).
- **Remote Login allowed for that login.** It needs no change to the system's `sshd` configuration: the limits are in the key's line, and the door ends its own connection.
- **The authority's own password stays at its console.** That login has a password, and with it `ssh` gives a shell there, door or no door. He types it at the authority's console and nowhere a process of his user runs. A root-owned `sshd` rule that takes keys alone for that login would close this. It is a system setting, so it is his act, and the first form does not need it.
- **The device pins the authority's host key** at its first connection, and he compares it with what the console showed.

### 5.3 One statement

1. **He connects** from the device. The app asks for his face, or he taps the key.
2. **`sshd` runs the door.** The door sets its own locale and path, and reads nothing the client sent but his keystrokes.
3. **The door reads back:** the authority's name, where main is, whether he has said stop, his last statements, and each permission of his that is not yet spent.
4. **It lists what waits on his word,** from the store.
5. **He picks one and a verb.** The door prints the card: the verb in words, the whole commit id, the main it is shown against, what would land, each founder path the change touches, the count of other paths, the judge's last result on this head, and the worker's words, each escaped, quoted and labelled.
6. **He confirms** by typing the verb and the four characters of the id that the card brackets. A door that runs with nobody at the device keeps nothing: one ran so on the mock transport, when a client that insisted on a terminal was refused one (T3b).
7. **The door writes the statement** (§5.4). In the first form it is recorded as given over the connection his key opened.
   - **Signing it was tried one way.** With `agent-forwarding` in the key's line, the client lends its key over the connection, and the door has the statement's bytes signed while it holds the public half alone (T5).
   - **What that costs was tried too.** A client that held the door's host key refused a false door (T12). Once the false door's changed key was accepted, as a person who taps through a warning would, the false door used the lent key to open the true door as him (T13). With no key lent it could not (T13b).
   - **So signing waits** for a way to lend the key to the door alone, or for a signer that shows what it signs (§4, row 11). Neither was found on a phone.
8. **The door keeps the statement** in the store, in order, tells him its number, and **ends the connection** (run: T9). That is what makes one connection one statement: where the door did not end it, a client that shared one connection among several sessions got three statements on one authentication (T7).

**What it costs.** The mock door's own work for one statement took a median of 103 ms to ask, 22 ms to sign and 52 ms to check and keep (ten statements; one ask took 2.4 s). Over the mock transport, a connection, the key, the door and one signature by a lent key took a median of 75 ms on loopback (T11). What a statement costs him was not measured. The second derivation guessed half a minute.

### 5.4 What is kept

The statement is text that the door writes, and no field in it comes from what the device sends back.

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
key: <the fingerprint of the key that opened the connection>
given: signed | connection | console
nonce: <used once>
at: <the authority's clock>
```

- **The log is a ref in the authority's store.** Each statement is a commit on it whose parent is the statement before, moved by compare-and-swap, with the signature beside it where there is one. The mock keeps files and an index. A ref is chosen for the build so that the store's own backup and the signer reach it (11-09 decision 6).
- **`main` and `card` are context.** They say what he was shown. No decision reads `main`: what binds an override is its tree. The review found that field feeding nothing in the mock, and it is kept for the record alone.
- **`given` says how his word arrived:** signed by his key over these bytes; given over a connection his key opened, with no signature of his; or given at the authority's console. A reader elsewhere checks a signed statement itself. For the other two it has the authority's word, and is told so.
- **Each landing record names the statements it leaned on,** and a reader checks each: the signature, the authority, the place in the order, that the commit is the record's head, that an override's tree is the record's tree, and that a permission was not spent before. On the mock, a hand with the authority's login that wrote an override into the door's index landed a defect, and the reader was told the record was unverified (V60). The same for a spent authorization used again (V61). The signature does not stop that hand. It lets a reader see it.

### 5.5 How the kernel reads his word

- **His later word wins.** Statements are read in their order. A hold covers each candidate whose history holds the commit it names, until a release that comes after it and names that exact head. A hold given after a release holds again (V5).
- **A hold takes back.** An authorization or an override is in effect while it is unspent and no hold that covers its head was given after it (V6, VR8). A release after that hold does not bring the permission back: he gives it again (VR9).
- **A hold is a lock on a commit, and not on a change.** The same edit made again under a new commit id is not held by it (VR4, and 11-09 decision 4). What must wait for him because of its content is a founder path, and what holds whatever comes is his stop.
- **An override names the tree he was shown.** If main has moved, so that the head would now land as another tree, the override is not in effect, and the door says so until he gives it again (V31).
- **A permission is one statement, by its number,** and the landing it allowed spends that number (V20).
- **Stop and go** are read the same way: the later of the two.
- **A permission does not lapse with time.** The door reads each unspent one back to him when it opens, and a hold takes it back. Rejected: a timer, which would let the authority's clock or a slow judge undo his word.

### 5.6 The first start, enrolling a key, and a lost device

- **At the authority's console, after a restart, before he logs in as himself.** No process of his user runs yet (§4, row 3b).
- **The first start** is statement 0: he names the commit main starts from.
- **Enrolling.** The key's public half may travel by any road, since it is not a secret. At the console the door shows its fingerprint, and he compares that with the fingerprint on the device before he accepts it.
- **A second key** is enrolled the same way, or by a statement under the first.
- **A lost device.** He restarts, takes the lost key's line out at the console, and enrols another. Each of these is a statement in the log, given at the console.
- **Taking a key away does not end a connection that key already opened.** On the mock transport a connection kept the line it had authenticated with after the line was changed (T7b). The door's connections last one statement, so that window is one statement long.

### 5.7 On the server

The door is the same: `sshd`, bash and git, and a key on a device. The device reaches it over the network. What differs is the side door. §8 records it.

## 6. Decisions made here

These are Felix's. Each names what was rejected.

- **Decision 1. The door is a terminal apart, and not a credential at the Mac.** Rejected: rows 1, 2, 4, 5 and 13 of §4 as the door, since each leaves the commit to be shown by the worker.
- **Decision 2. The door writes the statement, and he confirms the door's bytes.** Rejected: a statement composed on his side and parsed by the door. On the mock, a whole statement written and signed by a worker was refused because no statement of the door's was open, and no field of it was read (V14).
- **Decision 3. His statements are read in order, and a hold takes back a permission** (§5.5). Rejected: the 11-09 mock's reading, in which a release anywhere passes a hold and an override passes each hold.
- **Decision 4. An override names the tree that would land.** Rejected: an override of a head on whatever main has become. On the 11-09 mock's door that landed a tree whose content he had not been shown (V31f).
- **Decision 5. A statement names its authority and its place in the order.** A signature given to another authority, or under another use of the same key, does not count here (V23, V24).
- **Decision 6. What he is shown is the authority's facts first.** Each founder path the change touches is listed whole, before the rest and never cut. A worker's words are escaped to printable ASCII, quoted, and put on a line whose label the door wrote. Rejected: printing them as they are, with which a file name redrew the screen and he authorized a head he had not read (V40r), and a list in the tree's order cut at ten, with which a change to the founder-path policy itself went unseen and landed (V41r).
- **Decision 7. He is not asked to match a short id.** The card shows the whole id. The typed confirmation is there to make the act deliberate. It does not identify the commit: four characters are cheap to grind.
- **Decision 8. One statement is open at a time, one statement for each connection, and the door ends the connection.**
- **Decision 9. Each statement says how it was given, and each record says which statements it leaned on.** This extends 11-09 decision 9. Felix does not report a signature that is not there.
- **Decision 10. A permission does not lapse with time** (§5.5).
- **Decision 11. The door and the kernel read the founder-path policy through one function.** In the mock they were two, and they differed on one path of fourteen until the kernel was fixed: a path with a newline, which the door listed as his and the kernel did not hold (V43). Rejected: two readers kept alike by care.
- **Decision 12. The door's first form lends no key.** A statement is recorded as given over his key's connection. Rejected for now: a signature by a lent key, which a false door can use once its host key is accepted (T13). Rejected: a signature made on his Mac, and holding the door back until a signer is found. What is given up is in §10.

## 7. What the founder would have to do

Rows 4 to 6 wait for the authority's login, which is his act at 11-09 stage 2. Rows 1 to 3 are on his phone and could come before it. Each row is his to do, and this session did none of them.

| # | Act | Where | Why |
|---|---|---|---|
| 1 | Choose the device that is his door. The examples here assume his phone | | The trusted path is that device's screen |
| 2 | Install an SSH app that keeps its key in the phone's own hardware and asks for his face at each use, and make a key in it. Termius documents that. Blink, Prompt 3 and Secure ShellFish document hardware-held keys and do not all say it is asked for at each use. None was tried | The phone | Out of reach |
| 3 | Take this Mac off the phone's iPhone Mirroring list, or buy two hardware keys that are tapped on the phone and use row 7 | The phone, under Settings, General, AirPlay & Continuity; or a purchase | The riskiest assumption (§10) |
| 4 | Allow the authority's login for Remote Login | This Mac, System Settings | So the device reaches the door |
| 5 | Restart, log in as the authority first, give the first start, and enrol the key after comparing its fingerprint on the two screens | The authority's console | §5.6 |
| 6 | At the device's first connection, compare the host key's fingerprint with the console's | The phone | So a false door on the network is not taken for the true one |

What Felix builds, in bash, once he has chosen: the door, the kernel's reading of its log, the reader's check, and the console's enrolling command.

## 8. What this changes in the 11-09 design

A section or rule in bold is the 11-09 design's. One in brackets is this document's.

- **§5.5, the candidate** ("a command run as the authority's login, which this Mac allows after his password or his fingerprint") is rejected (§4, rows 1 and 2).
- **§5.5, "by something he knows or is, at the moment he says it"** says who he is, and not what he was shown. It needs a third part: shown from the store on a surface no worker draws on.
- **Rule 7** gains the order of his statements, the hold that takes back, and the authority and number in each statement (§5.5).
- **Rule 12** gains the tree: an override lands the tree he was shown, or is given again.
- **Rule 2** needs a further clause. "No worker can log in as the authority" has to cover recovering an account that can. Where the server's hosting account is opened in his browser, or can be reset through his mail, a session that drives both has what that account has. No provider was read. This belongs to call 5 and stage 5 and is open there.
- **§3, class 9** is no longer "Not shown" for the door's own protocol on a mock. It is still not shown for a real surface.
- **§5.5, the interim** is worth less than stated. A session that drives his signed-in browser comments as him with no token, so taking his token out of an agent's reach does not close it (inferred; GitHub was not exercised).
- **§8, the rehearsal's wall** ("one admin password") is weaker than "one password away" reads. That password is typed in a terminal of the worker's user, where a function can stand in for `sudo` (§2).
- **The 11-09 mock's door** has the three gaps of §1. They are in pull request 504's kernel and are that pull request's to fix or to state.

## 9. The second derivation

A second author derived the door from the same decided list, without sight of this one's reasoning or mock, and ran its own reads on this Mac (`sources/second-derivation.md` in the audit folder; the facts read for both are in `sources/facts.md`, each with its source).

- **It reached the same recommendation:** a second device as an SSH client, a forced-command door, a tapped key as the advised upgrade, and the console after a restart for enrolling and recovery. It named the same riskiest assumption.
- **Taken from it:** the function that stands in for `su` (its run, repeated in §2); the statement's `card` digest and `key` fingerprint; the typed confirmation; the log as a ref; the door reading his recent statements back; and four of §8's points (the interim, the hosting account, the first start having no door, and "names a commit" not being "sees a commit").
- **Where this design differed, and where it ended:** the second derivation accepted statements with no signature of his as the cost. This design set out to sign each one, because a signature is what lets a reader tell the founder from a hand with the authority's login (V60, V61). The trial then showed what the one way found costs (T13). So the first form is as the second derivation has it, each statement says how it was given, and signing is open.
- **Two authors agreeing is not a proof.** Both read the same Apple pages and neither held a phone.

## 10. Open

These are the open items seen so far. More will come.

- **Whether the phone is out of reach.** Whether this Mac is on his phone's mirroring list, and whether it connects unasked, was not read. Apple's note says a request for the face alone fails while a phone is mirrored, and that an app may choose to let the Mac approve instead (read). Which of the apps named does that was not read.
- **The app.** That it keeps the key in the phone's hardware and asks at each use is from vendors' pages. None was installed.
- **A founder who does not read.** The door showed the truth and a founder modelled as going by the title confirmed the wrong change (V42h). No mechanism found closes that. Property 4 and the typed confirmation make the act deliberate, and a model of a person shows nothing about a person.
- **The terminal on the phone.** The mock's reader of the screen handles four things a terminal does. A real one does more. The door's escaping leaves printable ASCII alone, and look-alike characters within it (`l`, `1`, `I`) are not treated.
- **Shutting the door.** After three refusals of a key that was not enrolled, this `sshd`, as it ships, refused the enrolled key from the same address for about 15 seconds (T2b). A worker behind the same address as the phone can repeat that. A hold and a stop are the statements this hurts. How he says stop with the door shut, or the device lost, is not designed.
- **A signature of his on each statement.** Without it a statement rests on the authority's word, and a reader cannot tell his override from one written by a hand with the authority's login (V60 shows the reader's check working where there is a signature). It matters most once the authority is on a server. What is needed is a key lent to the door alone, or a signer that shows what it signs.
- **A changed host key.** What each app shows when the door's host key changes, and how easily it is tapped through, was not read. With no key lent, a false door was reached and did not open the true one (T13b). It would still learn what he typed.
- **Row 3's question:** whether macOS keeps one login's processes from another login's screen and keys. No statement by Apple was found either way.
- **The way from the phone to this Mac** during the rehearsal: the local network, and a Mac that sleeps. Not tried.
- **The hosting account** (§8).
- **A dropped statement.** A hand with the authority's login dropped his hold from the log, the change landed, and both of the mock's readers said ok (V62). The door reads his recent statements back each time it opens, so he could notice. A reader elsewhere could not. A signed and dated statement of the log's tip would let one (11-09 §8, "a reader with no memory"). Not designed.
- **Two processes at the door's log at once.** The mock runs one at a time. The build's log is a ref moved by compare-and-swap for that reason, and that is a claim about a build that does not exist.
- **The review.** A fresh reviewer, given the mock's code and not this document, found no break in nine cases of its own. Two routes it reasoned about and did not run were run afterwards: V43 found the difference of decision 11, and V62 the dropped statement. It also named what makes rows read stronger than they are, which the report repeats. One review of one day's mock is not an audit, and a review that finds no break is weaker evidence than one that finds some.

## 11. The founder's calls

The acts of §7 are his, and so is the choice of device. Two calls follow from this design. Neither is answered. Each is put to him through the question dialog, with four outcomes and the recommended one first, when he takes this pull request up. A yes to a call is not a yes to each act under it.

| # | The call | Recommended | The other outcomes | His answer |
|---|---|---|---|---|
| 1 | Which surface is his door first | His phone, over SSH, to a door at the authority | The authority's own desktop on this Mac (§4, row 3). A signer with a screen of its own (row 11). Staying with the interim until the server (row 9) | Not asked yet |
| 2 | How the phone is kept out of a session's reach | This Mac taken off the phone's mirroring list now, and tapped keys before the server | The list alone. Tapped keys alone, with mirroring kept. A device that is not on his Apple account | Not asked yet |

Nothing in this design needs felix-home's visibility to change. It stays private.
