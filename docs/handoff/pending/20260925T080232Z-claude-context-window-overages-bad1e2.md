### 2026-09-25 — the context cap the founder counted on did not exist, and every session now summarizes at 500K

**No engine change.** One key in the founder's `~/.claude/settings.json`, this
section, and one `maintenance.log` row.

**What the founder reported.** "Almost every single session we have now
disregarded the context cap." Measured by joining the transcripts to the
desktop's session records (`~/Library/Application
Support/Claude/claude-code-sessions`, which hold each session's chosen
`model`), main-chain calls since 2026-09-21 11:05Z, sessions of 20 calls or
more:

| Model as chosen | Sessions | Past 200K | Past 500K | Past 800K | Largest |
|---|---|---|---|---|---|
| `claude-opus-5-5` | 73 | 66 | 21 | 8 | 966K |
| `claude-opus-5` | 13 | 13 | 4 | 2 | 891K |
| `claude-opus-5[1m]` | 2 | 0 | 0 | 0 | 163K |

Of the 41 unarchived sessions on 09-25, 36 had passed 200K and 9 had passed
500K. Two sessions since 09-21 reached the old ceiling and summarized, at 969K
and 967K, so "over the window" meant over 200K, not a 1M hit.

**Why.**
- In Claude Code 2.1.280, Opus 5.5 and Opus 5 have a native 1M window. The
  200K default applies only to models without one, so picking the plain entry
  over `[1m]` caps nothing. `CLAUDE_CODE_DISABLE_1M_CONTEXT` does not bind
  them either; the binary warns that "the 200K limit isn't enforced" for such
  a model, "so this session can grow past it".
- Felix's own line, restart past about 500K (09-21 §6, restart-moments scope
  §7), had no carrier. It was a memory note that said "recommend", nothing
  read a session's size, and this session's harness prompt tells the model it
  need not wrap up early. ECC's nudge had been followed 0 times in 88.

**Decided by the founder, 2026-09-25: summarize at 500K, in every project.**
Put to the founder because the file is the founder's global settings, with
200K and leaving it at 1M as the other choices. Set as `"autoCompactWindow":
500000`, written 07:49:43Z. The schema takes an integer from 100000 to 1000000
and drops anything else without a warning. A turn reads the window when it
starts, so a turn already running keeps the old one: a call at 661K 18 s after
the write did not summarize. No session had yet summarized under the new
window when this was written; the pull request that carries this section
records what a watcher on the transcripts saw.

**What this changes in Felix's plans.**
- Restart moments step 2 loses its size trigger. A session past 500K now
  summarizes in place, so the transcript context reader and the 500K line
  (scope §8, excluded from step 1) need not be built to name size. Step 1
  (engine behind) and idle resume are unchanged.
- Scope §7 put the compaction window last, after a continue/restart/compact
  experiment. The window is now set first, by the founder. The experiment, if
  it is still wanted, compares summarizing at 500K with restarting there.
- The 09-21 replay's 18-28% saving modelled restarts, not summaries, and does
  not transfer as a number. What summarizing at 500K saves is unmeasured;
  sessions from 2026-09-25 on are the first data.

**Also from the founder, 2026-09-25: auto-archive, and switches a user
chooses.**
- A finished session should archive itself, and for the founder it is always
  on. The desktop setting is "Auto-archive sessions when their pull request
  closes" (`ccAutoArchiveOnPrClose`; the `ccd_settings` key is
  `auto_archive_on_pr_close`). It was off. Only archiving after 30 inactive
  days was set. This session had no `ccd_settings` tools, so the founder was
  pointed at the toggle. A session that has those tools should check it is on.
  A session with no pull request of its own is not archived by it.
- The wider idea: Felix functions become on/off switches a user sets in a UI.
  Which functions, and their defaults, are the founder's to decide later, and
  nothing is scheduled. Until then the founder's own answer is on, for all of
  them.

**Traps paid:**
- The tool shell's `grep` is ugrep, which refuses `.{0,400}`-style context
  patterns as too complex. Read context around a match in the binary's strings
  with python.
- `felix maintenance --ran` writes its row into the home checkout's
  `projects/felix/maintenance.log`, not the session's worktree, so the row is
  copied into the branch that carries the handoff. Git then refuses the home's
  next pull over that uncommitted row, even though it is identical to the one
  arriving (shown on a scratch repository). Once the row lands, drop the
  home's copy before pulling.
