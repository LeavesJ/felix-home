### 2026-11-10: the founder's door is designed and its protocol tried on a mock (trust step 4, documents only)

**What this is.** The mechanism the 11-09 hosted-authority design left open at its §5.5: how the founder gives his word to the authority. Two documents, `docs/2026-11-10-trust-door-design.md` and `docs/2026-11-10-trust-door-spike.md`, with their PDFs. Nothing in `engine/` changes and nothing is released. The 11-09 design is on pull request 504, which is open; this work cites it and does not depend on its merge. The mock and its logs are in the memory root, `audits/2026-11-10-trust-door/`.

**What it says.**
- **What decides is the terminal, and not the credential.** A password, a fingerprint or a touch at the Mac shows he was there and not what he was shown. On the mock, the same key and door with the Mac as the terminal kept his override of a worker's defect (case V50).
- **Recommended:** his phone is the door's terminal. An SSH client on it holds a key made on it, that key runs one command at the authority, and the door is bash over the authority's store. The first start, enrolling a key and a lost phone go through the authority's console after a restart, before he logs in as himself.
- **The first form lends no key,** so a statement carries no signature of his. Lending the key let a false door open the true one once its host key was accepted (transport row T13).
- **The 11-09 design's own candidate is rejected:** a command as the authority's login from his terminal.

**Measured.**
- 47 door cases on the mock, 38 the author's and 9 an adversarial reviewer's, none ending otherwise than expected. Twelve were written to show a route open.
- The door's transport against this Mac's `sshd`, started by the spike on a loopback port: 13 rows as expected and 5 readings.
- The 11-09 battery on the changed kernel: 46, 46 and 74 cases, none ending otherwise than expected.
- The review found no break. Two routes it reasoned about were run afterwards. One found the door and the kernel reading the founder-path policy differently on one path of fourteen, fixed in the mock. One showed that a hold dropped from the log leaves both readers saying ok.

**Not shown.** A phone, an app, a hardware key, a second login, a person, or iPhone Mirroring. The "phone" is a directory the worker's sandbox denies and the founder is a script.

**For pull request 504,** found here and not changed there:
- its mock's door reads his word without its order (V5f), lets an override pass each hold (V6f), and lets an override land a tree he was not shown (V31f);
- its kernel's founder-path rule does not hold a path with a newline, which it turns into `?` before the rule reads it (V43). The copy check refused that change later;
- a path's tab reaches its ledger's "why" column as it is;
- its battery gives case T1 a default outcome that equals the expected word, so the row reads "as expected" when the race was not staged (seen in modes on and off);
- its §5.5 interim does not stand against a session that drives his signed-in browser, and its rule 2 needs a clause on recovering the hosting account.

**Open.** Whether his phone is out of a session's reach, which he reads on the phone. A signature of his on each statement. A founder who confirms without reading. How he says stop with the door shut. A statement dropped from the log. The design's §10 has the list.

**The founder's calls.** Two, in the design's §11, and not asked yet: which surface is his door first, and how the phone is kept out of a session's reach. The acts are his and none was done: an app and a key on the phone, the mirroring list, Remote Login for the authority's login, and the console steps. The parts at the authority wait for 11-09 stage 2's logins. The pull request is labelled needs-founder.
