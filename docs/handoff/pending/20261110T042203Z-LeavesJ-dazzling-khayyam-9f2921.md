### 2026-11-10: the founder's door is designed, its protocol tried on a mock, and his choice of surface recorded (trust step 4, documents only)

**What this is.** The mechanism the 11-09 hosted-authority design left open at its §5.5: how the founder gives his word to the authority. Two documents, `docs/2026-11-10-trust-door-design.md` and `docs/2026-11-10-trust-door-spike.md`, with their PDFs. Nothing in `engine/` changes and nothing is released. The 11-09 design is pull request 504's; this work cites it and does not depend on its merge. The mock and its logs are in the memory root, `audits/2026-11-10-trust-door/`.

**What it says.**
- **What decides is the terminal, and not the credential.** A password, a fingerprint or a touch inside his own login shows he was there and not what he was shown. On the mock, the same key and door with the Mac as the terminal kept his override of a worker's defect (case V50).
- **His choice, 2026-11-10 at 07:22Z: the authority's own desktop on this Mac is his door first.** The design had recommended his phone. In his words: "we can do a screen on this mac...the reason is imo a smoother transition to our infra UI later". He picked none of the four outcomes offered. His words repeat the label of the second, and the design reads them as that one. The design's §5 is now that door: a switch to the authority's desktop by fingerprint, a door there in bash over the authority's store, one unlock meant for one statement, no key and no network.
- **What that door rests on, and neither was measured:** that macOS keeps a process of his user off another login's desktop, and that the authority's password is typed where no worker draws. A reach test comes before any statement that counts. It needs the authority's login, which is his to make.
- **The 11-09 design's own candidate is still rejected:** a command as the authority's login from his terminal. The desktop he chose is another login's session, and not his terminal.
- **His second answer,** "Unpair the Mac, keys later (Recommended)", was asked on the condition that the phone is the door. It is kept as given, and comes due where a phone becomes a door. By its own words the keys come "before the authority moves to a server".

**Measured,** before his choice, and not run again after it.
- 47 door cases on the mock, 38 the author's and 9 an adversarial reviewer's, none ending otherwise than expected. Twelve were written to show a route open. They were run with a signing key, which the desktop door does not have. The design's §5.8 says which still bear on it, as an argument.
- The transport of a door reached over a network, against this Mac's `sshd` on a loopback port: 13 rows as expected and 5 readings.
- The 11-09 battery on the changed kernel: 46, 46 and 74 cases, none ending otherwise than expected.
- The review found no break. Two routes it reasoned about were run afterwards. One found the door and the kernel reading the founder-path policy differently on one path of fourteen, fixed in the mock. One showed that a hold dropped from the log leaves both readers saying ok.

**Not shown.** A second login, a switch of desktop, a fingerprint, a restart, a phone, an app, a hardware key, or a person. The surface no worker reaches is a directory the worker's sandbox denies, and the founder is a script.

**For pull request 504,** found here and not changed there. He chose on 2026-11-10 to land it with its mock's defects recorded as open. The question put to him named the first two below and the newline path. This is this session's whole list:
- its mock's door reads his word without its order (V5f), lets an override pass each hold (V6f), and lets an override land a tree he was not shown (V31f);
- its kernel's founder-path rule does not hold a path with a newline, which it turns into `?` before the rule reads it (V43). The copy check refused that change later;
- a path's tab reaches its ledger's "why" column as it is;
- its battery gives case T1 a default outcome that equals the expected word, so the row reads "as expected" when the race was not staged (seen in modes on and off);
- its §5.5 interim does not stand against a session that drives his signed-in browser, and its rule 2 needs a clause on recovering the hosting account.

**Open.** Whether a process of his user reaches the authority's desktop. A genuine login window he can tell from a drawn one. How often the password is asked. No signature of his on a statement. The door's cases at a door with no key. A founder who confirms without reading. A statement dropped from the log. The design's §10 has the list.

**The founder's acts.** Both calls are answered (the design's §11). Each act under them is still his, and none was done: the authority's login, a fingerprint for it, a restart for the first start, the reach test with him at the screen, and no road in from the network for that login. Whether this Mac comes off the phone's mirroring list now, with the phone not the door, was not asked. The pull request is labelled needs-founder.
