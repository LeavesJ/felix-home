# Audit fix b12, round 3: the remote a grant is checked against comes from fixed state (contract)

Round 3 of batch 12. The batch contract is `b12-judge-base-and-binding-read-what-is-comm.md` beside this file, and its rounds 1 and 2 are built; 8332c6e7 is round 2's fix. A background security review of 8332c6e7 flagged `felix_exceptions_doubt` in `engine/harness/lib/exceptions.sh`. The session that holds the batch verified the finding, and it is verified again below. Line numbers are from 8332c6e7. This file amends B1(d) and B41 only. Where it differs from them, this file supersedes them.

## 1. Defect

- **R3-a. The URL picks the project it is checked against.** exceptions.sh:200 reads `rp="$(felix_resolve_project "$repo" "$repo")"`. When REPO's root has no `.felix`, `felix_resolve_project` uses its rule 2 (resolve.sh:525-528, through `_felix_resolve_remote` at :480-501), which binds the project whose `remote_match` names origin's URL. Check (d) then compares that same URL with that project's `remote_match`, and the two match by construction. So an origin pointed at a copy whose URL names *any* registered project's `remote_match` passes (d). Rule 1 also reads a `.felix` that is not a regular file as no marker (resolve.sh:516), so a `.felix` directory or a dangling link sends the reader down the same route.
- **R3-b. A marker naming a project that declares no `remote_match` skips (d).** At exceptions.sh:202-203, an empty `m` means no check, whosever grant is being read. In a home whose marker names a project that declares no `remote_match`, a product's grant is honoured from any origin.
- **R3-c (found while verifying).** A marker that names no directory under `REPO/projects/` makes `felix_resolve_project` return 1 (resolve.sh:518-522). The reader then falls back to PROJ's own `remote_match`, so it treats a repository it cannot place as though it were PROJ's own.

*Reproduced on 8332c6e7* (bash 3.2.57). The fixture is a scratch copy shaped like §2's fixture S, with the libraries sourced as part 1850 sources them.
- **R3-a.** S1 has no marker and holds `x` (`acme/x`) and `y` (`acme/y`). Its origin is `srv/acme/x.git`, whose `main` holds no grant for x. A branch `forged` adds x's grant and is pushed as `main` to `srv/acme/y.git` and to `srv/other/x.git`.
  - With the URL at `srv/other/x.git` and a plain fetch, x is doubted with DM and `felix_exception_for` exits 1.
  - With the URL at `srv/acme/y.git` and a plain fetch, origin/main is forged's commit and the reflog reads `fetch -q: fast-forward`. Then:
    - `felix_resolve_project S1 S1` prints `S1/projects/y`;
    - `felix_exceptions_doubt` prints nothing;
    - `felix_exception_for` prints `excepted|2027-06-01T00:00:00Z|the-founder` and exits 0;
    - the judge prints a `live` row, and column 8 reads `excepted|…`.

    A grant nobody merged clears.
  - In the same home at baseline, y's grant, which is merged, clears because rule 2 picks `x` for the home.
- **R3-b.** S2's `.felix` names `felix`, which declares `""`, and `p` declares `acme/p`. Its origin is `srv2/home/felix.git`. With the URL at `srv2/evil/z.git` (which names nothing) and a plain fetch, p's grant clears with nothing doubted. The same happens through a symlinked spelling of the path, and with the URL at `srv2/look/acme/p.git`.
- **R3-c and the non-regular marker.** With the URL at `srv2/look/acme/p.git`, p's grant clears in each of these cases: a `.felix` holding `gone`, a `.felix` that is a directory, and no `.felix` at all. Only the last is the stated limit (B12R3-2).
- **Real state.** The home's `.felix` names `felix`, which declares `LeavesJ/felix-home`. No real exceptions table holds a grant row (§9, M4 of the batch contract), so nothing live is honoured through these routes today.

*Not the defect.* Rule 2 is fine as a binding. It tells the hooks which project governs a checkout, and a convenience path is acceptable there. A grant check is different: what is being checked must not choose the standard it is checked against.

*Why the marker is fixed state and the URL is not.* `projects/felix/deny.tsv` refuses a hand rewrite of `.felix`:
- the rows at lines 33-34 cover Write and Edit;
- the rows at lines 79-82 cover redirection, `tee`, `mv`, `rm`, `truncate`, `sed -i`, `dd`, `cp`, `ln` and `install`.

No row refuses `git config remote.origin.url` until §7 of the batch contract lands. The rows are patterns and not a wall. The marker is the better guarded of the two; it is not tamper-proof.

## 2. Required behaviour

Conventions are those of the batch contract's §2. `L`, `ROW` and `LIVE` are fixture G's. Three lines are exact:
- **D1** = `remote_match cannot be read: this repository's .felix marker names no project in it`
- **D2(n)** = `remote_match cannot be read: n, the project this repository's .felix marker names, declares none`
- **DM** = `remote_match: origin's URL does not name the remote_match this project declares`, unchanged from 8332c6e7.

- **B12R3-1. Which project (d) reads.** REPO is as B1 defines it. Q, the project whose `remote_match` origin must name, is chosen from fixed state alone:
  - If REPO's root has no `.felix` entry of any kind (no file, directory or link, dangling or not), Q is PROJ.
  - If `.felix` is a regular file, or a link to one, and is readable, take its bytes with every blank and newline removed under `LC_ALL=C`. If the result is a name `_felix_name_ok` accepts and `REPO/projects/<name>` is a directory, Q is `REPO/projects/<name>`.
  - Any other `.felix` gives doubt D1. That covers a name with no directory, an empty file, an unreadable file, a directory and a link to nothing.

  Origin's URL never chooses Q. An origin that names another project's `remote_match` changes nothing about Q.
- **B12R3-2. Q declares none.** Q's `remote_match` M is read as today: `felix_json_str` of `Q/project.json` in the working tree, as M″ of B39. Suppose M is empty (no file, an unreadable file, no key, or an empty value):
  - If Q is the directory PROJ names, there is no check, as B1(d) and B7 say. "The directory PROJ names" means the same directory under any spelling, a symlinked path or a trailing slash included, as `[ Q -ef PROJ ]` judges it.
  - Otherwise the line is D2, with n Q's directory name, whatever origin's URL is.

  With no marker Q is PROJ, so an origin left at a copy whose path ends in PROJ's own `remote_match` gets past, as route r4 does (B35). That is a stated limit.
- **B12R3-3. Q declares M.** This is unchanged. If `git remote get-url origin` fails, the line is `remote_match cannot be read: git exited <rc>`. If the URL does not match M under B21 and B39, the line is DM. The URL is never printed.
- **B12R3-4. Place and effect.** D1 and D2 come where check (d) stands in B1's order, so (a)-(c) are found first and (e) comes after. B2-B4 follow:
  - `felix_exception_for` prints nothing and exits 1;
  - the judge prints `refused<TAB>ob1<TAB>LIVE<TAB>the-founder<TAB>not honoured: <line>`;
  - `felix_obligations_run` prints column 8 as `-`.

  B5's four readers do not change.
- **B12R3-5. Read only.** The check reads `.felix` and `Q/project.json`, as well as what B1 already reads. It runs no `fetch`, `pull`, `ls-remote`, `remote update` or `gh`. It changes no ref, reflog, config or file under REPO. It writes nothing under the memory root; in particular it appends no `bindings.tsv` line, because it records no binding.
- **B12R3-6. The binding does not change.** `engine/harness/lib/resolve.sh` is not edited, and `felix_resolve_project`, `felix_binding_broken` and the hooks keep rule 2. Under route s1, `felix_resolve_project S1 S1` still prints `S1/projects/y`.
- **B12R3-7. The comments.** Read `lib/exceptions.sh`'s comment lines as A86 reads them:
  - The file's head contains `.felix marker`. The head runs from line 1 to the first line that is neither blank nor a comment.
  - The run of comment lines ending on the line just above `felix_exceptions_doubt() {` contains `.felix marker`, `never the project the origin URL binds`, `circular` and `with no marker`.
  - No comment line contains `marker first`.
  - A86's phrases stay.

  Those phrases are the floor. The comments must say three things:
  - which project is read: the one the marker names, and with no marker PROJ itself;
  - why: a project chosen by origin's URL would be checked against the URL that chose it, which is circular, and the marker is guarded by deny rows where the URL is not;
  - the limits: with no marker, an origin left at a copy whose path ends in PROJ's own `remote_match` gets past; a project that declares none is not checked in its own repository; and the marker and `remote_match` are read from the working tree.

**Fixture S.** Everything sits under one `mktemp -d` in `$TMP`, made physical with `cd && pwd -P`. HOME and an empty FELIX_MEMORY directory M are set there, along with `GIT_CONFIG_NOSYSTEM=1`. Each project directory holds three files:
- `project.json`: `{ "name": "<n>", "remote_match": "<m>", "gate": "true" }`;
- `obligations.tsv`: L;
- `exceptions.tsv`: B6's header comment, plus ROW where this section says so.

These are the fixture's parts:
- **The bare repositories**, each made with `git init --bare -b main`: `srv/acme/x.git`, `srv/acme/y.git`, `srv/other/x.git`, `srv2/home/felix.git`, `srv2/evil/z.git` and `srv2/look/acme/p.git`.
- **S1**, with no `.felix`:
  - It holds `projects/x` (`acme/x`, header only) and `projects/y` (`acme/y`, with ROW). It is committed on `main`.
  - Its origin is `srv/acme/x.git` with `+refs/heads/*:refs/remotes/origin/*`. `main` is pushed and fetched.
  - A branch `forged`, cut from `main`, appends ROW to `projects/x/exceptions.tsv` and is committed. It is pushed as `main` to `srv/acme/y.git` and to `srv/other/x.git`, and S1 is back on `main`.
- **S2**, whose `.felix` holds `felix\n`:
  - It holds `projects/felix` (`""`) and `projects/p` (`acme/p`), both header only. It is committed.
  - Its origin is `srv2/home/felix.git` with the default refspec. `main` is pushed and fetched.
  - A branch `forged` appends ROW to both tables and is committed. It is pushed as `main` to `srv2/evil/z.git` and to `srv2/look/acme/p.git`, and S2 is back on `main`.
  - A symbolic link `slink` points at S2.
- **The routes.** Each starts from the baseline. Afterwards the URL is put back and one plain `git fetch` restores origin/main.
  - **s1**: S1's URL set to `srv/acme/y.git`, then a plain fetch.
  - **s1o**: S1's URL set to `srv/other/x.git`, then a plain fetch.
  - **s2**: S2's URL set to `srv2/evil/z.git`, then a plain fetch.
  - **s2l**: S2's URL set to `srv2/look/acme/p.git`, then a plain fetch.
  - **s3**: s2l, after which `.felix` is replaced in turn by a file holding `gone\n`, an empty file, a directory, a link to a missing file, and nothing at all. Then `.felix` is put back as `felix\n`.

The outcomes, where "for" is `felix_exception_for PROJ ob1 TASK_BLOCKING "$L"` and "doubt" is `felix_exceptions_doubt PROJ`:

| state | PROJ | for | doubt |
|---|---|---|---|
| S1 baseline | `S1/projects/x` | nothing, exit 1 | nothing |
| S1 baseline | `S1/projects/y` | nothing, exit 1 | DM |
| s1o | `S1/projects/x` | nothing, exit 1 | DM |
| s1 | `S1/projects/x` | nothing, exit 1 | DM |
| S2 baseline | `S2/projects/p` | nothing, exit 1 | D2(felix) |
| s2 | `S2/projects/p` and `slink/projects/p` | nothing, exit 1 | D2(felix) |
| s2l | `S2/projects/p` | nothing, exit 1 | D2(felix) |
| s2 | `S2/projects/felix`, `slink/projects/felix` and `S2/projects/felix/` | `excepted\|LIVE\|the-founder`, exit 0 | nothing |
| s3, each of `gone`, empty, directory, dangling link | `S2/projects/p` | nothing, exit 1 | D1 |
| s3, no `.felix` | `S2/projects/p` | `excepted\|LIVE\|the-founder`, exit 0 | nothing (stated limit) |

## 3. What must not change

- **Every clause of the batch contract except B1(d)'s choice of project and B41's.** B41's "the one `felix_resolve_project REPO REPO` binds, marker first. When REPO binds no project, it reads PROJ's" becomes "the one REPO's `.felix` marker names, or PROJ with no marker" (B12R3-1).
- **Fixture Q's outcomes, A89 and A90.** The marker names `felix`, so Q is `felix` (`acme/felix`) for both grants.
- **Part 1850 entire.** Fixture G and fixture P have no marker, so Q is x:
  - A1-A24 hold, A17 especially: with `remote_match` emptied, Q is PROJ, so there is no check.
  - A84-A88 hold: r4 is still named by §2's row, not doubted.
  - A86's phrases stay.
- **Part 1860 entire.** The binding, the tie and the record are resolve.sh's, and resolve.sh is untouched. 1860 also pins B12R3-6.
- **0780.** XH and XC are self-governed homes whose marker names the project itself, which declares no `remote_match`, so they clear as before. XB, XN, XR and XK stay as they are.
- **0970 and 1080**, as the batch contract lists them.
- **K1-K4:**
  - resolve.sh stays at 1872 lines and is not edited;
  - `lib/exceptions.sh` stays under 500 lines;
  - the code runs under bash 3.2 and 5, with `LC_ALL=C` on reading `.felix` and `project.json`;
  - there is no network call;
  - the engine names no project.
- **`docs/2026-09-21-where-felix-stands.md`.** It is not edited (see Decisions).

## 4. Assertions

[red] fails at 8332c6e7. [control] holds before and after. Each runs under bwk and gawk. The assertions are numbered after the batch contract's A97.

98. B12R3-1 [control]: at S1's baseline, x's doubt prints nothing and `felix_exception_for` prints nothing and exits 1.
99. B12R3-1 [red]: at S1's baseline, y's `felix_exception_for` prints nothing and exits 1, and y's doubt is exactly DM. With no marker, Q is y, not the project the URL binds.
100. B12R3-3 [control]: under s1o, x's doubt is exactly DM and `felix_exception_for` exits 1.
101. B12R3-1, B12R3-4 [red]: under s1, x's `felix_exception_for` prints nothing and exits 1, and x's doubt is exactly DM. The judge prints `refused<TAB>ob1<TAB>LIVE<TAB>the-founder<TAB>not honoured: ` followed by DM, and `felix_obligations_run S1/projects/x S1` prints column 8 as `-`.
102. B12R3-6 [control]: under s1, origin/main is forged's commit and its newest reflog entry begins `fetch`, and `felix_resolve_project S1 S1` prints `S1/projects/y`.
103. B12R3-2 [red]: at S2's baseline, p's doubt is exactly `remote_match cannot be read: felix, the project this repository's .felix marker names, declares none`.
104. B12R3-2, B12R3-4 [red]: under s2, p's `felix_exception_for` prints nothing and exits 1 for `S2/projects/p` and for `slink/projects/p`. Its doubt is exactly D2(felix), its judge's why is `not honoured: ` followed by D2(felix), and column 8 is `-`.
105. B12R3-2 [red]: under s2l, p's `felix_exception_for` exits 1 and its doubt is exactly D2(felix).
106. B12R3-2 [control]: under s2, felix's own grant clears (`excepted|LIVE|the-founder`, exit 0) and its doubt prints nothing. This holds for `S2/projects/felix`, for `slink/projects/felix` and for `S2/projects/felix/`.
107. B12R3-1 [red]: under s3, for each of `gone`, an empty file, a directory and a dangling link, p's `felix_exception_for` exits 1 and its doubt is exactly D1.
108. B12R3-2 [control, the stated limit]: under s3 with no `.felix`, p's grant clears and its doubt prints nothing.
109. B12R3-5 [control]: while the doubt, `felix_exception_for` and the judge run on `S2/projects/p`, under s2 and under the `gone` marker, the following hold:
     - a logging git wrapper first on PATH records no `fetch`, `pull`, `ls-remote` or `remote update`, and a gh stub records no call;
     - S2's `git for-each-ref`, `git reflog show refs/remotes/origin/main`, `git config --list --local`, `git status --porcelain --ignored` and the bytes of `.felix` are identical before and after;
     - at the part's end, `find M -type f` prints nothing.
110. B12R3-7 [red]: the head holds `.felix marker`; the comment block above `felix_exceptions_doubt() {` holds `.felix marker`, `never the project the origin URL binds`, `circular` and `with no marker`; and no comment line holds `marker first`.

*Expected red, checked on a scratch fixture of this shape before this file was written, not on the part.* A99, A101, A103, A104, A105, A107 and A110 fail at 8332c6e7. Each red case clears or prints nothing today, and the head holds no `.felix marker`, while line 142 holds `marker first`. A98, A100, A102, A106, A108 and A109 hold.

## 5. Part

`engine/harness/tests/parts/1851-grant-remote-from-fixed-state-blind.sh` holds A98-A110. It is written blind from this file, the batch contract's §2 and §9 conventions, and the definition lines of `lib/exceptions.sh` for argument order. It builds fixture S under its own `mktemp -d` in `$TMP`, and uses only the driver's helpers (`ok`, `bad`, `is`, `has`, `skip`, `$FROOT`, `$TMP`) and nothing that part 1850 defines. One line registers it in `tests/run`, directly after 1850's line (tests/run:411). It joins no group.

The fix touches `engine/harness/lib/exceptions.sh` alone.

## 6. Decisions

- **With no marker, Q is PROJ, as the finding says.** A no-marker home's own grants keep working (fixture G, A1, A17). The consequence is that a no-marker home's *product* grants are refused unless its origin names that product's remote (A99). That is round 1's B1(d) for such homes, and it fails closed. The real home has a marker, and no real table holds a grant.
- **A `.felix` present but naming nothing is D1, not a fallback to PROJ.** This covers a missing name, an empty or unreadable file, a directory and a dangling link. The repository says it is a project the engine cannot find, so the engine cannot tell whose remote names origin. A `.felix` directory or a dangling link is also exactly what sends rule 2 down the circular route today (R3-a). The finding's "else $proj" is read as "no marker at all".
- **The marker is read from the working tree, as rule 1 reads it.** It is not read from HEAD or from the judged ref:
  - the ref is what is being judged, so reading the marker from it would be circular again;
  - HEAD adds nothing while the `remote_match` beside it is read from the working tree (B1(d), A17);
  - the working-tree marker is the one the deny rows guard and the hooks bind by.
- **If Q is PROJ and declares none, there is no check; if Q is another project and declares none, the line is D2.** This is the finding's scope, and it keeps A17 and 0780. "The same" is directory identity (`-ef`), so a symlinked or trailing-slash spelling of PROJ cannot turn a self-governed home's grant into a doubt (A106 guards against a string compare).
- **D2 applies whatever origin's URL is,** the URL of the home's own remote included (A103). A home whose own project declares no `remote_match` has nothing to vouch for its origin, so it cannot vouch for a product's grant either.
- **The exact texts.** D1 and D2 contain `remote_match` and `cannot be read` (the finding), and they name the project by its directory name, which `_felix_name_ok` keeps printable. They never print the URL. DM is unchanged: A15, A16 and A90 read only its word. Naming the project there is not what round 3 asks, and D2 names it where the choice of project is the cause.
- **The fix lives in `lib/exceptions.sh`, and resolve.sh is untouched.** resolve.sh is at K1's 1872-line limit. The binding keeps rule 2, which the hooks need. The reader reads the marker itself, with `_felix_name_ok` (already loaded). It does not call `felix_resolve_project`, so no remote step can be reached.
- **A new part, 1851, rather than more lines in 1850.** 1850 is 436 lines, and round 3's fixture and thirteen assertions would put it past 490, close to the 500-line rule. A self-contained part also runs alone under `alone.sh`.
- **The status document is unchanged.** Its §2 row already says the reader stops "not a worker set on forging one", and it lists the fetch routes. r4's "the declared remote_match" stays true, now meaning the marker's project's, or PROJ's with no marker. Round 3 closes a widening and adds no claim.

## 7. Founder stops

There are none. The fix touches `lib/exceptions.sh` and the new part, which the batch already changes, and one `tests/run` line, which the batch's parts already use. It adds no table column and no deny, escape, risk or `exceptions.tsv` row. It touches no `.github/workflows` file and no commission grant. The `.felix` deny rows it relies on (deny.tsv lines 33-34 and 79-82) are already on main.

## 8. Review round (2026-10-28)

The review of 9ad32600 raised two findings, V1 and V2. Both are accepted. Each is restated below as required behaviour, and where it changes an earlier item of this file, the text here supersedes that item. The new assertions are A111-A116, named `B12R3V A<n>`, in the same part, `engine/harness/tests/parts/1851-b12-round-3-blind.sh`. Two lines are new and exact:
- **DH** = `remote_match cannot be read: the repository git finds for this project is not the one whose projects directory holds it`
- **D3(n)** = `remote_match cannot be read: n declares none, and this repository has no .felix marker and holds other projects`

### V1: with no marker, a project that declares none is not checked in a repository that holds other projects (amends B12R3-2)

*The finding.* With no marker, Q is PROJ. When PROJ declares no `remote_match`, B12R3-2 runs no check. So in a home with no marker that holds `x` (`acme/x`) and a product `p` declaring none, p's grant clears from any origin: point origin at a copy whose `main` holds the grant, and fetch. That is R3-b without a marker, a product's grant honoured from any origin, which is what round 3 closes. §6 says a no-marker home's product grants fail closed (A99); that holds only for a product that declares a `remote_match`. And the stated limits (B12R3-2, B12R3-7) name only the copy whose path ends in PROJ's own `remote_match`, and "not checked in its own repository", where a repository with no marker is not shown to be p's own at all.

*Accepted*, because the contract's own reason for "Q is PROJ and declares none, so no check" is A17 and 0780, and each of those is a repository whose `projects/` holds PROJ alone. The finding's other remedy, a doubt whenever PROJ declares none, breaks A17 and B7, which round 3 keeps; it is not taken.

- **B12R3-8. No marker, PROJ declares none, other projects present.** Suppose REPO's root has no `.felix` entry (so Q is PROJ, B12R3-1) and Q's M is empty (B12R3-2). If `REPO/projects/` holds an entry that is a directory, or a link to one, whose name does not begin with `.` and is not PROJ's directory name, the line is D3(n), with n PROJ's directory name, whatever origin's URL is. Otherwise there is no check, as B12R3-2 says (B7, A17, and 0780's XB and XK).
  - With a `.felix` entry, B12R3-8 does not apply. A marker naming PROJ is the repository saying it is PROJ's own, so A106 holds whatever else `projects/` holds. A marker naming another project is B12R3-2's D2.
  - The listing is read from the working tree, as the marker and `remote_match` are. A session that removes the other projects from the working tree gets past, as one that empties `remote_match` does. That is a stated limit (A112).

### V2: the repository a grant is read from is the home whose projects directory holds PROJ (amends B1's REPO, for check (d))

*The finding.* REPO is `felix_exceptions_repo PROJ`, which git finds by discovery over the working tree. A git repository nested between the home's root and PROJ moves REPO: `git init` in `projects/`, or a `.git` file there. The reader then never sees the home's `.felix`. It takes the no-marker branch, so Q is PROJ, and the table, the ref, the fetch configuration, the URL and the reflog all come from the nested repository. An origin there at a copy whose path ends in PROJ's `remote_match` passes, and one anywhere passes when PROJ declares none. The marker was never touched, so the deny rows that make it fixed state (§1) do not help: they guard the file, not the boundary that decides which file is read.

*Accepted*, because the marker is fixed state only while the repository it is read from is. The guarantee round 3 gives, that in a home whose marker names `felix` a product's grant is D2 or DM, otherwise fails without a single write to `.felix`.

- **B12R3-9. REPO must be the home.** Let P be PROJ with every trailing `/` removed. PROJ's parent is `dirname P`, and H is `dirname` of the parent. If the parent's last path component is not exactly `projects`, or `[ REPO -ef H ]` fails, the line is DH, whatever `.felix`, M and origin's URL are.
  - H comes from PROJ's spelling alone and never from git's discovery. A symlinked spelling or a trailing slash still names the same directory under `-ef`, so A106 holds for `slink/projects/felix` and `S2/projects/felix/`. Under s5 the symlinked spelling of p is DH too (A114), because git finds the nested repository for it as well.
  - When REPO is H, the check goes on as B12R3-1 to B12R3-3 say, and the marker read is H's.
  - A project directory that is not directly under a directory named `projects` at the top of its repository is DH. That covers 0780's XR, a project that is the repository root, which already grants nothing there.
  - B1 is otherwise unchanged. In particular, the doubt still prints nothing when REPO's `refs/remotes/origin/main` does not exist.
- **B12R3-10. Place, effect and read only.** DH is found first within check (d). Then come D1 or D2 (B12R3-1, B12R3-2), D3 (B12R3-8) or DM (B12R3-3). As B12R3-4 says, (a)-(c) are found before (d) and (e) after it. B2-B4 and B12R3-4's three effects apply to DH and D3 unchanged. B5's four readers do not change. B12R3-5 holds as written: the new checks read PROJ's spelling and the names under `REPO/projects/`, and nothing else.
- **B12R3-11. The comments.** The run of comment lines ending on the line just above `felix_exceptions_doubt() {`, read as A110 reads it, also contains `nested repository` and `the only project`. The limits the comments state (B12R3-7) become these:
  - with no marker, an origin left at a copy whose path ends in PROJ's own `remote_match` gets past;
  - a project that declares none is not checked when the marker names it, or, with no marker, when it is the only project in the working tree's `projects/`;
  - the marker, the `projects/` listing and `remote_match` are read from the working tree.

  The comments also say why a nested repository is doubted: the marker is fixed state only while the repository it is read from is, and git's discovery over the working tree is not.

**Fixture S, continued.** These routes start from S2's baseline, after A108's state is put back:
- **s4**: S2's `.felix` removed, and S2's URL set to `srv2/evil/z.git`, then a plain fetch. Within s4, `projects/p` is moved out of S2 to `$RR3/p.away` and moved back. Afterwards `.felix` is put back as `felix\n`, the URL is put back, and a plain fetch restores origin/main.
- **s5**: A repository is made at `S2/projects` with `git init -b main`, and its tree (`felix/` and `p/`, both header only) is committed on `main`. A branch `forged` appends ROW to `p/exceptions.tsv` and is committed. It is pushed as `main` to a new bare repository `srv2/nest/acme/p.git`, and the nested repository goes back to `main`. Its origin is that bare repository, with `+refs/heads/*:refs/remotes/origin/*`, and it fetches once. Afterwards `S2/projects/.git` is removed.

| state | PROJ | for | doubt |
|---|---|---|---|
| s4 | `S2/projects/felix` | nothing, exit 1 | D3(felix) |
| s4, p moved out | `S2/projects/felix` | `excepted\|LIVE\|the-founder`, exit 0 | nothing (stated limit) |
| s5 | `S2/projects/p` and `slink/projects/p` | nothing, exit 1 | DH |
| s5, then the nested `.git` removed | `S2/projects/p` | nothing, exit 1 | D2(felix) |

**What must not change**, beyond §3:
- 1850's fixtures each hold `projects/x` alone with no marker, so B12R3-8 does not apply, and REPO is H in each, so B12R3-9 does not either. A1-A24, A17 and A84-A90 hold.
- 0780's XH and XC have a marker naming their one project, so they clear as before. XR is DH now, and it already grants nothing. XB, XN and XK keep their outcomes.
- A98-A110 hold. In S1, x and y both declare a `remote_match`. S2 has a marker in every state but s3's last, and there p declares `acme/p`.

**Assertions A111-A116.** [red] fails at 9ad32600. [control] holds before and after. Each runs under bwk and gawk.

111. B12R3-8, B12R3-10 [red]: under s4, felix's `felix_exception_for` prints nothing and exits 1, and its doubt is exactly D3(felix). The judge prints `refused<TAB>ob1<TAB>LIVE<TAB>the-founder<TAB>not honoured: ` followed by D3(felix), and `felix_obligations_run S2/projects/felix S2` prints column 8 as `-`.
112. B12R3-8 [control, the stated limit]: under s4 with `p` moved out of the working tree, felix is the only project, so its grant clears (`excepted|LIVE|the-founder`, exit 0) and its doubt prints nothing.
113. B12R3-9 [control, the fixture]: under s5, `git -C S2/projects/p rev-parse --show-toplevel` prints `S2/projects`. The nested repository's origin/main is its `forged` commit, its newest reflog entry begins `fetch`, and `origin/main:p/exceptions.tsv` holds ROW once.
114. B12R3-9, B12R3-10 [red]: under s5, p's `felix_exception_for` prints nothing and exits 1 for `S2/projects/p` and for `slink/projects/p`, and its doubt is exactly DH for both. The judge's why for `S2/projects/p` is `not honoured: ` followed by DH, and `felix_obligations_run S2/projects/p S2/projects` prints column 8 as `-`.
115. B12R3-9 [control]: with `S2/projects/.git` removed, p's doubt is exactly D2(felix) again and `felix_exception_for` exits 1.
116. B12R3-11 [red]: the comment block above `felix_exceptions_doubt() {` holds `nested repository` and `the only project`.

*Expected red, not yet run when this was written:* A111, A114 and A116. A112, A113 and A115 hold.

**Decisions.**
- **D3 is narrow on purpose.** A repository with no marker whose `projects/` holds PROJ alone is the shape B7 and A17 treat as PROJ's own. A second project makes the repository a home, and the reader cannot tell from fixed state whose remote origin should name, so it doubts.
- **H comes from PROJ's path, not from an environment variable.** The reader takes only PROJ. A variable such as the home's root is not state the deny rows guard, and the parts call the reader without one. `projects/<name>` is also where the grant table lives: the exception channel fires only on `projects/<p>/exceptions.tsv` (0780).
- **A nested repository anywhere between H and PROJ is DH.** That includes `projects/<name>` itself. The assertion builds the case at `projects/`, the one where the table path differs from the home's and the bypass is plainest.
- **The exact texts.** DH and D3 contain `remote_match` and `cannot be read`, as D1 and D2 do. DH names no path and D3 names only PROJ's directory name, so neither prints a URL or a location.

**Founder stops.** There are none. The fix stays in `lib/exceptions.sh`, and the assertions stay in part 1851.
