# Cloud verification of Felix

Run on 2026-09-28 in a Claude Code cloud session on branch `LeavesJ/cloud-felix-access-28d34d` at `8d16aea`. The only change to the tree is this file, and no PR was opened.

## Summary

The Felix hooks are live in the cloud, since both the SessionStart and UserPromptSubmit hooks injected their context and the gate runs from the clone. The toolbox is not, because provision got HTTP 403 on all three codeload fetches, so superpowers, claude-md-management and code-simplifier never arrived. That is why "You have superpowers" is missing and why none of the skills or the agent those plugins carry exist here. The gate exits 1, failing on tests, probes and qualified, and a second private repository is unreachable, which is consistent with GitHub access being scoped to felix-home.

| Step | Check | Result |
|---|---|---|
| 1 | remote, user, cwd, bash | `remote=true`, `root`, `/home/user/felix-home`, bash 5.2.21 |
| 2 | hook context | "Felix governs this session" present, "You have superpowers" absent |
| 3 | provision | exit 1, three fetches failed with 403, tree clean |
| 4 | skills and agents | brainstorming, systematic-debugging, claude-md-improver absent; code-simplifier not spawnable; pdf, docx, xlsx present |
| 5 | Skill `systematic-debugging` | not loaded, `Unknown skill` |
| 6 | gate | `exit=1`, FAIL on tests, probes and qualified |
| 7 | other private repo | `other-private-repo=128` |

## 1. Environment

```
$ echo "remote=$CLAUDE_CODE_REMOTE"; whoami; pwd; bash --version | head -1
remote=true
root
/home/user/felix-home
GNU bash, version 5.2.21(1)-release (x86_64-pc-linux-gnu)
```

## 2. Hook context

"Felix governs this session" is present. It arrived as the SessionStart hook's additional context, and its first 10 lines read:

```
Felix governs this session.

Project: felix
Constitution: /home/user/felix-home/projects/felix/CLAUDE.md
Gate: /home/user/felix-home/engine/harness/felix gate
Memory: /root/.felix/memory/felix/

Maintenance due: discover promote graphify
Do them on one branch. See 'felix maintenance'.

```

"You have superpowers" does not occur anywhere in the context, so there are no lines to quote. That follows from step 3, because the text comes from superpowers' own SessionStart hook, which provision replays only from a fetched copy, and the fetch failed.

The UserPromptSubmit hook also fired and routed this turn to `superpowers:brainstorming`, a skill that is not installed here. The route was declined on the record with `felix route --ack`, and `git status --short` stayed empty afterwards.

## 3. Provision

```
$ bash .claude/cloud/provision --report
MISSING   superpowers            obra/superpowers@896224c4b187 (see /root/.cache/felix-cloud/provision.log)
MISSING   claude-md-management   anthropics/claude-plugins-official@2cd88e7947b7 (see /root/.cache/felix-cloud/provision.log)
MISSING   code-simplifier        anthropics/claude-plugins-official@2cd88e7947b7 (see /root/.cache/felix-cloud/provision.log)
builtin   code-review            Claude Code ships /code-review itself, and the plugin's command of the same name would shadow it
no        security-guidance      its only content is a Python hook that calls a model
no        semgrep                risk=high in stack.tsv, which no automation installs (constitution invariant 4)
claude.ai anthropic-skills       cloud sessions load the skills enabled on claude.ai; whether pdf, docx and xlsx are enabled there is the account's setting, not this file's
no        graphify               the graph is built on the founder's machine and is not in the clone, so the skill would have nothing to query
(exit 1)

$ cat ~/.cache/felix-cloud/provision.log
curl: (22) The requested URL returned error: 403

gzip: stdin: unexpected end of file
tar: Child returned status 1
tar: Error is not recoverable: exiting now
18:33:07Z FAILED to fetch obra/superpowers@896224c4b1879920ab573417e68fd51d2ccc9072
curl: (22) The requested URL returned error: 403

gzip: stdin: unexpected end of file
tar: Child returned status 1
tar: Error is not recoverable: exiting now
18:33:08Z FAILED to fetch anthropics/claude-plugins-official@2cd88e7947b7382e045666abee790c7f55f669f3
curl: (22) The requested URL returned error: 403

gzip: stdin: unexpected end of file
tar: Child returned status 1
tar: Error is not recoverable: exiting now
18:33:08Z FAILED to fetch anthropics/claude-plugins-official@2cd88e7947b7382e045666abee790c7f55f669f3

$ git status --short
(empty)
```

All three failures are curl exit 22 on HTTP 403, and the pending handoff for this branch names codeload as the source of the pinned tarballs. The tree is clean, so provision wrote nothing tracked.

## 4. Skills and agents in this session

Checked against the skill list and the agent types this session was given.

| Name | Kind | Present |
|---|---|---|
| brainstorming | skill, from superpowers | no |
| systematic-debugging | skill, from superpowers | no |
| claude-md-improver | skill, from claude-md-management | no |
| code-simplifier | agent | no, the spawnable types are claude, claude-code-guide, Explore, general-purpose, Plan and statusline-setup |
| pdf, docx, xlsx | skills | yes, as `anthropic-skills:pdf`, `anthropic-skills:docx` and `anthropic-skills:xlsx` |

Every absent entry is one the toolbox was meant to carry through provision, and the present ones arrive through claude.ai exactly as `toolbox.json` expects.

## 5. Skill tool

```
Skill(systematic-debugging)
<tool_use_error>Unknown skill: systematic-debugging</tool_use_error>
```

It did not load.

## 6. Gate

```
$ bash engine/harness/felix gate > /tmp/g.txt 2>&1; echo exit=$?; tail -30 /tmp/g.txt
exit=1
  ecosystem          ok
  memory             ok
  cloud              ok

gate: FAIL (tests)
  probes             FAIL
  probes for felix
  
    not-applicable deployed_engine        the `when` command says this does not apply here
    blind      marketplace_root       the witness proves this surface exists and the probe enumerated none of it
  
  1 of 9 could not be established. Those are not passes:
  blind means the witness proves a surface the probe cannot see, and
  unknown means nothing decided either way.
  1 of 9 did not apply here and asked nothing. A row can be switched
  off by making its `when` false, so this number is worth reading.
  
  What none of this can reach. Every row above is an enumeration, and an
  qualified          FAIL
    secret     violation                fail    pass    HELD
    secret     alternate                fail    pass    HELD
    secret     decoupled_violation      fail    pass    HELD
    secret     alternate                fail    pass    HELD
    secret     alternate                fail    pass    HELD
    secret     alternate                fail    pass    HELD
    secret     alternate                fail    pass    HELD
    secret     alternate                fail    pass    HELD
  obligations        ok
                     2 obligation(s): 1 active, 1 dormant, 0 unknown; 0 blocking, 0 excepted; 2 name what discharges them: 0 complete, 0 short, 2 absent; 0 name nothing
  commission         never commissioned on this machine
```

The run took more than ten minutes. The earlier lines of the same output, above the tail, report syntax, executable, schema, handoff, secret, independence, ecosystem, memory and cloud as ok and installed as skipped, with tests failing on ten assertions (full log at `/tmp/felix-gate-tests.Zrkr09`, which dies with the VM):

```
  tests              FAIL
    FAIL  already-installed rows report present
          [ACTION    KIND        NAME
  install   plugin      superpowers@claude-plugins-official            risk: low
  --
    FAIL  a record that could not be written does not exit 0
          exit 0 after: recorded. 1 of 10 used in the last 24h
    FAIL  and does not say it recorded
          recorded. 1 of 10 used in the last 24h
    FAIL  nor report a spend that did not happen
          recorded. 1 of 10 used in the last 24h
    FAIL  and nothing was written
          expected [absent] got [present]
    ok    a writable project still records
  --
    FAIL  the log holds exactly one entry
          expected [1] got [2]
    FAIL  which is the number it printed
          [recorded. 2 of 10 used in the last 24h] lacks [1 of 10]
    FAIL  felix_budget_record itself reports the failure
          exit 0
    ok    at most one caller records when one slot is left
  --
    FAIL  an append that did not happen is reported as a failure
          expected [1] got [0]
    ok    an append that succeeded and wrote nothing is reported as a failure too
  --
    FAIL  and so is a file this user cannot read
          expected [2] got [0]
    ok    lifecycle-check cannot examine a hooks.json that does not parse
  --
                     full log: /tmp/felix-gate-tests.Zrkr09
```

Most of those failures sit in tests that expect a write or read to be refused and then reported, and the session runs as `root` (step 1), which bypasses file permission checks. That is a likely cause for them, but it is unverified here. The probes section also marks `marketplace_root` as blind, and its closing paragraph is cut off mid sentence in the gate's own output.

## 7. Other private repository

```
$ git ls-remote https://github.com/LeavesJ/cash-ops HEAD >/dev/null 2>&1; echo other-private-repo=$?
other-private-repo=128
```

Exit 128 is git's fatal error, so the session cannot read `LeavesJ/cash-ops`. Stderr was discarded as instructed, which means this cannot tell a refusal from a network failure, but it is consistent with the session's GitHub scope being `LeavesJ/felix-home` alone.

## What this answers from the handoff

The handoff left two questions that only a cloud run could settle. Whether skills written at SessionStart appear without a restart is still open, because provision wrote none. What the gate does here is now known, since it runs from the clone, takes over ten minutes and exits 1. The Stop hook had not fired when this file was written, so its behaviour is still open.

## Follow ups

1. Allow `codeload.github.com` in this environment's Network access settings, or widen the access level, then rerun provision so the toolbox can land and the SessionStart question can be measured.
2. Confirm or rule out the root hypothesis for the gate's test failures by running the failing suite as an unprivileged user.
3. The commissioning requests `constitution_audited` and `automation_surveyed` are still awaiting, and the gate reports this machine as never commissioned.

## After this report, 2026-09-29

The Stop hook fired at the end of the turn and held the stop until the gate passed on the exact tree, which answers the last open question above. Follow up 2 is settled too, because as an unprivileged user the permission assertions run and pass, while as root they cannot be built.

The red gate had five causes, all in the environment rather than in this file: root and file modes, a clone that held no `main`, a plugin registry without a felix marketplace, mawk's handling of anchored repeats, and VM system time counted as CPU. Step 4 also changed after a restart, since the plugins that were installed into this VM's `~/.claude` during the first gate run loaded when the session resumed. The branch's pending handoff section records each cause, its fix and the evidence.
