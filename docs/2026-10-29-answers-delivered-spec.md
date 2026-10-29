# A tool's answer, delivered: the knowledge graph at every prompt, the specification

Written 2026-10-29 against main at 78f0268f (engine 0.49.308). Every behaviour
below is numbered, says what is observable, and is meant to become one or more
assertions in `engine/harness/tests/parts/`. Decisions taken where the brief
left a choice are in section 7, each with its evidence.

Tier: adversarial. `lib/graph.sh`, `lib/ledger.sh`, the `felix` CLI and the
user-prompt, post-tool and session-end hooks run in every session of every
governed project.

Notation: `\t` is one tab byte. A row written `a\tb\tc` is one line ending in a
newline. Paths are relative to `engine/harness/` unless they start with
`projects/` or `docs/`.

---

## 0. Why, in one paragraph

The graph under `graphify-out/` was named three ways and used by none of them:
an `orient` route (2026-09-10), a line in every session-start banner, and a
background refresh. `felix ledger` on 2026-10-29: the banner line was in 193
sessions and the graph was queried 3 times; the route named it in 15 sessions
and it was reached 0 times. A name is advice, and advice among forty lines of
banner does not change what a model does. This change stops naming the graph
and hands the session its answer: on each prompt a person types, the hook asks
the graph the prompt and puts the files and symbols it returns into the model's
context, then records whether the session went to them. The same plumbing is
the class, not the instance: an *answer* is any capability's output delivered
without being asked for, and the ledger and the use measure are written for
answers in general, with graphify the first tool to give one.

## 1. What the graph can and cannot answer here (measured, not assumed)

- `graphify query`, `explain` and `affected` load `graph.json` with networkx and
  walk it. No model, no network (read in graphify's `cli.py` and `serve.py`,
  installed 0.4.x). `query` writes one stamp file,
  `graphify-out/cache/last_query_stamp`, and nothing else.
- Time on this Mac, 8 MB graph, 7,584 nodes: `affected` 0.28-0.38 s, `query`
  with `--budget 600` 0.98-1.40 s wall, 0.57 s CPU.
- Recall of *who depends on a file*, on the engine: for every file under
  `lib/` and `hooks/`, the files the graph links to it by any cross-file edge
  against the files that name one of its functions or source it: 74 of 455
  non-test dependents, 16%. The bash extractor resolves `source` only from
  `felix` and `bin/`, and 134 of 2,931 call edges cross a file. `affected` on a
  file is worse: it seeds through `contains`/`method` and the bash extractor
  writes `defines`, so `affected lib/graph.sh` answers "No affected nodes".
  This is the 2026-09-10 lesson ("for a caller question on bash, grep is the
  oracle") with a number on it.
- What the graph does answer well: where a thing is (which file and line holds
  the symbols and documents a question is about) and how files group.

So the answer delivered is `query` on the prompt, the "where is it" answer, and
not `affected` on an edited file, whose list would be 84% short on the only
project that has a graph.

---

## 2. `lib/graph.sh`: the answer

### A1. `felix_graph_answer <root> <prompt>`

Prints the graph's answer to `<prompt>` as rows `src\tloc\tlabel`, one per
graph node, and exits 0; or prints nothing and exits 1. In order:

1. `FELIX_GRAPH_ANSWER=0` in the environment: exit 1, nothing run.
2. No graph file for `<root>` (`felix_graph_file`, so a worktree uses the
   holding checkout's graph): exit 1.
3. `graphify` not on `PATH`, or `perl` not on `PATH`: exit 1.
4. The prompt, with every run of whitespace (spaces, tabs, newlines, and the
   two-character JSON escapes `\n`, `\t`, `\r`) made one space and trimmed,
   cut to its first 400 characters. Fewer than `FELIX_GRAPH_MIN_WORDS` words
   (default 5): exit 1, graphify not run.
5. Runs exactly
   `graphify query "<prompt>" --budget <FELIX_GRAPH_BUDGET> --graph <graph file>`
   (default budget 600), bounded by `FELIX_GRAPH_TIMEOUT` seconds (default 4)
   through `perl -e 'alarm shift; exec @ARGV'`. Its stderr is discarded. A
   non-zero exit, a timeout, or no output: exit 1.
6. Reads graphify's lines of the form
   `NODE <label> [src=<src> loc=<loc> community=<anything>]`. Every other line
   is ignored. A node is kept only when `<src>` is a relative path (does not
   start with `/`, is not `None`, contains no `..` segment) naming a regular
   file under the graph's holding checkout.
7. `<label>` is cleaned: tab and control bytes removed, cut to 120 characters.
   `<loc>` is kept as printed (`L83`, `§0ae`, or empty for `None`).
8. Rows stop once `FELIX_GRAPH_FILES` distinct files (default 8) have appeared;
   further nodes of a file already listed are still printed, and no more than
   16 rows in all.
9. No node kept: exit 1.

### A2. `felix_graph_deliver <home> <session> <root> <prompt>`

The answer, made into the block the hook hands the model, once per file per
session. Prints the block and exits 0, or prints nothing and exits 1.

1. Empty `<session>`: exit 1, nothing written.
2. `felix_graph_answer` fails: exit 1, nothing written.
3. The session's answer record is `<home>/state/answer/<session>.tsv`. A file
   already recorded there as `answer\tgraphify\t<src>` is dropped from this
   answer. Nothing left: exit 1, nothing written.
4. Otherwise appends, in this order: one `given\tgraphify\t<n>` row, `<n>`
   being the number of distinct files kept; then one `answer\tgraphify\t<src>`
   row per distinct file, in the order graphify gave them.
5. Records the delivery in the ledger: `felix_ledger_record <home> <session>`
   with the signal `answer\tgraphify`, once per delivery.
6. Prints:

   ```
   The knowledge graph's answer to this prompt (graphify query, graph built at
   <sha7>, <freshness>). Where it places what was asked, so you can open these
   instead of searching for them:

     <src>:<loc>  <label>
     ...
   ```

   `<freshness>` is `current with the checkout that holds it` when
   `felix_graph_behind` is 0, `<n> commit(s) behind the checkout that holds it`
   when it is more, and the first line reads `graph carrying no build stamp`
   in place of `graph built at <sha7>, <freshness>` when the stamp cannot be
   read or names no commit here. A row whose `<loc>` is empty prints
   `<src>  <label>`. Rows are indented two spaces.
7. When any listed file is a shell script (its name ends in `.sh`, or its first
   line starts `#!` and names `sh`, `bash` or `zsh`), the block ends with one
   more paragraph:

   ```
   It finds where things are, not who calls them: in shell scripts the graph
   sees few callers, so for "what calls this" grep is still the oracle.
   ```

   No shell script listed: no such paragraph.
8. Writing the record may fail (an unwritable `state/`); the block is still
   printed and the exit is still 0.

### A3. `felix_graph_refresh_due <root>`

Exits 0 when the graph exists and its stamp names a commit the holding
checkout has, behind HEAD by one or more; 1 otherwise (no graph, no stamp,
an unknown commit, or current). Prints nothing.

---

## 3. `hooks/user-prompt`: where the answer is given

### U1. Who gets one

The hook calls `felix_graph_deliver` only when all hold:
- the payload is a person's prompt (`felix_route_machine` printed nothing);
- the payload carries a session id;
- the checkout is the project's own: `felix_checkout_is_own <proj> <root>`
  returned 0. A checkout bound by a `.felix` marker alone, or by an origin that
  is not the project's, is told nothing: its `graph.json` is a file its authors
  chose, and the labels would reach the model under Felix's name.

### U2. What it is asked

The prompt is the payload's `"prompt"` string, read up to its first unescaped
double quote, with `\"` read as a quote and `\\` as a backslash. The rest of
the payload is never part of the question.

### U3. Where it goes

The block is one more part of the one `additionalContext` this hook already
emits, after the route and shape parts and before the lessons part, separated
from its neighbours by one blank line. A prompt that produces only this part
still produces the hook's JSON output. A prompt that produces none of the parts
still exits 0 with no output.

### U4. It never costs the prompt

A graphify that fails, hangs past the timeout, prints garbage, or is absent
leaves the hook's exit 0 and its other parts unchanged.

---

## 4. `hooks/post-tool`: what the session did next

### T1. Recording follow-through

After the existing ledger append, when `<home>/state/answer/<session>.tsv`
exists, the hook appends one `touch\t<Tool>\t<value>` row for these tools:

| Tool | value |
|---|---|
| `Read`, `Edit`, `Write`, `MultiEdit` | the first `"file_path"` string in the payload |
| `NotebookEdit` | the first `"notebook_path"` string |
| `Grep`, `Glob` | the first `"path"` string (a key spelled exactly `"path"`) |
| `Bash` | the first `"command"` string, cut to 400 characters |

"First" is the first occurrence in the payload, so a key of the same name
inside the tool's response cannot replace the input. Taken up to the first
double quote after the opening one. A tool not in the table, or a payload
without the key, appends nothing. No state file: nothing is read beyond what
the hook reads today and nothing is appended.

### T2. Cost

No git, and no process beyond one for the extraction, and that only when the
state file exists. A failed append is silent and the exit is 0.

---

## 5. `hooks/session-end`: the graph refreshed after every session

### R1. When

At the end of every session that is not a machine session (the existing early
exit stands) and resolves to a project, the hook runs
`felix_graph_refresh_bg <root>` when, and only when:
- `felix_graph_refresh_due <root>` exits 0 (the holding checkout has moved past
  the graph), and
- `felix_checkout_is_own <proj> <root>` returned 0.

`<root>` is the top level of the session's working tree.

### R2. What it does not do

It never waits: the hook returns while the refresh runs (the existing
background and lock in `felix_graph_refresh_bg`). It prints nothing. A graph
that is current, or a checkout that is not own, starts nothing. The ledger
rollup runs as before, whether or not a refresh starts, and a failure to load
`lib/graph.sh` or `lib/own.sh` never stops it.

### R3. A lock a killed refresh left behind is taken back

`felix_graph_refresh_bg` takes `graphify-out/.felix-refresh.lock`, a directory,
and its trap removes it on exit. A refresh killed by a signal the trap cannot
catch leaves the directory behind. A lock directory whose modification time is
more than `FELIX_GRAPH_LOCK_STALE` minutes old (default 30) is removed and the
refresh proceeds; one younger than that still means a refresh is running, and
the call does nothing, as before.

---

## 6. `lib/ledger.sh` and `felix ledger`: the answer as its own surface

### L1. The rollup

A row of kind `answer` in a session's appends is folded like any other kind,
`<session>\t<date>\tanswer\t<tool>\t<deliveries>\t`, with the sixth field
empty: a route naming the same tool is the policy's decision about the tool and
is not a naming of the answer. An `answer` row stands for no declared
capability, so a session given graphify's answer still gets its zero row for a
declared `graphify` it never reached for.

### L2. Kept out of every capability reading

`felix_ledger_summary`, `felix_ledger_mcp`, and so the retire, unobserved,
partly and unrouted lists, the stack reconciler and the monitor's compliance
reading, never see an `answer` row. Delivering an answer is not reaching for
the capability; counted as a reach it would read as use the session never
chose.

### L3. `felix_ledger_answers <proj>`

Prints `tool\tsessions\tdeliveries` per tool from the folded `answer` rows:
distinct sessions, and the summed delivery count. Nothing when there are none.

### L4. `felix_answer_use <proj> <home> <root>`

Reads `<home>/state/answer/*.tsv` for the sessions this repository owns
(`_felix_ledger_owns`, the same test the catch-up uses). Prints, per tool,
`tool\tsessions\tsessions_acted\tdeliveries\tdeliveries_acted\tfiles\tfiles_acted`.

- A file named by an `answer` row is *acted on* when a `touch` row after it in
  the same file matches it: for `Read`, `Edit`, `Write`, `MultiEdit`,
  `NotebookEdit`, `Grep` and `Glob`, the value equals the file or ends in
  `/<file>`; for `Bash`, the command contains the file's path, or contains its
  basename when the basename has a `.` in it.
- A delivery is acted on when any file it named was. A session is acted on when
  any of its deliveries was.
- `files` counts `answer` rows; `deliveries` counts `given` rows.

### L5. `felix ledger` prints it

When `felix_ledger_answers` prints anything, `felix ledger` adds, after the
capability table, a section headed
`answers handed to sessions without being asked for`, one line per tool:

```
  graphify     given 37 times in 12 sessions; 21 answers (57%) named a file the session then opened, edited or ran; 61 of 190 files (32%)
```

followed by the sentence: `A file the session would have opened anyway counts
here too, so this is the most the answers can have caused, not what they
caused.` The capability table's rows are unchanged by `answer` rows.

---

## 7. Decisions, with their evidence

- **`query` on the prompt, not `affected` on the edit.** Section 1: 16% recall
  of dependents on bash; `affected` on a file finds none. An injected list that
  is 84% short is worse than none, because it reads as complete.
- **Every substantive prompt, once per file per session.** The first prompt is
  "read the graph at the beginning", the founder's words of 2026-10-29. Later
  prompts add only files not yet named, so the context cost is bounded by the
  session's distinct files, not its prompts.
- **No holdout.** A held-out arm would measure cause, and it would withhold the
  graph from one session in five that the founder wants it in. The cause is
  bounded instead by a baseline from the transcripts of the fourteen days before
  this change (section 8), the same query, and no injection.
- **Own checkout only.** `lib/own.sh`'s class: a tool whose behaviour depends on
  the checkout's files. Here the output is the model's context.
- **The answer surface is general.** `state/answer/`, ledger kind `answer`, the
  tool as the name: the next tool whose answer should be delivered writes the
  same three rows and is measured by the same function.

## 8. The baseline, measured before the change

Recorded in the pull request: over Felix transcripts from the 14 days before
2026-10-29, for each person prompt of five words or more, what this query would
have answered, and whether the session then opened, edited or ran one of those
files with no answer given. That is the share a delivered answer has to beat.
