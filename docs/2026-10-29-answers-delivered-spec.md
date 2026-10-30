# A tool's answer, delivered: the knowledge graph at every prompt, the specification

Written 2026-10-29 against main at 78f0268f (engine 0.49.308), and amended the
same day after a six-lens review (section 9 lists every item that changed).
Every behaviour below is numbered, says what is observable, and is meant to
become one or more assertions in `engine/harness/tests/parts/`. Decisions taken
where the brief left a choice are in section 7, each with its evidence.

Tier: adversarial. `lib/graph.sh`, `lib/graph-answer.sh`, `lib/answer.sh`,
`lib/ledger.sh`, the `felix` CLI and the user-prompt, post-tool, session-start
and session-end hooks run in every session of every governed project.

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
banner does not change what a model does. This change no longer leaves the
graph at being named (the banner line stays): on each prompt a person types,
the hook asks the graph the prompt and puts the files and symbols it returns
into the model's context, then records whether the session went to them. The
same plumbing is the class, not the instance: an *answer* is any capability's
output delivered without being asked for, and the ledger and the use measure are
written for answers in general, with graphify the first tool to give one.

## 1. What the graph can and cannot answer here (measured, not assumed)

- `graphify query`, `explain` and `affected` load `graph.json` with networkx and
  walk it. No model, no network (read in graphify 0.9.37's `cli.py` and
  `serve.py`). `query` writes one stamp file, `graphify-out/cache/last_query_stamp`,
  and nothing else.
- Time on this Mac, 8 MB graph, 7,584 nodes: `affected` 0.28-0.38 s, `query`
  with `--budget 600` 0.57 s CPU, 0.98-1.40 s wall at an ordinary load, and
  3.3-4.8 s wall at a load average of 130-180, when other sessions run suites.
- At `--budget 600` graphify truncates most answers and says so: six sampled
  prompts showed 12 of 121, 19 of 97, 15 of 65, 12 of 71, 13 of 135 and 15 of
  144 nodes. The answer handed over has to say it is partial.
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
- `graphify update` writes nothing when the code's topology did not change: it
  compares the rebuilt graph with `built_at_commit` removed and returns before
  writing, so the stamp stays behind HEAD after a commit that changes no node.

So the answer delivered is `query` on the prompt, the "where is it" answer, and
not `affected` on an edited file, whose list would be 84% short on the only
project that has a graph.

---

## 2. `lib/graph.sh` and `lib/graph-answer.sh`: the answer

A1 and A2 are in `lib/graph-answer.sh`, which `lib/graph.sh` loads, so anything
that loads `lib/graph.sh` has them; A3 and A4 are in `lib/graph.sh`.

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
5. When `FELIX_GRAPH_LEFT` is set and not empty, it is the whole seconds a
   calling hook has left before the platform ends it (U4). A value that is not
   a whole number of one or more (`0`, a negative number, anything else): exit
   1, graphify not run, because there is no time left to ask. Otherwise runs
   exactly
   `graphify query "<prompt>" --budget <FELIX_GRAPH_BUDGET> --graph <graph file>`
   (default budget 600), for at most `FELIX_GRAPH_TIMEOUT` seconds (default 4;
   a value that is not a whole number of one or more is taken as the default,
   so no setting removes the bound), and never for more than `FELIX_GRAPH_LEFT`
   seconds when that is set. The command runs in a process group of
   its own. At the deadline the whole group is killed, children included, so
   nothing it started can hold the caller's output open; and any process still
   in the group when the command exits by itself is killed then. The group is
   signalled until none of it is left, so a process that was being started at
   that instant is caught too. Its stderr is discarded. A non-zero exit, a kill
   at the deadline, or no output: exit 1.
6. Reads graphify's lines of the form
   `NODE <label> [src=<src> loc=<loc> community=<anything>]`. Every other line
   is ignored. Tab and control bytes are removed from `<src>`, `<loc>` and
   `<label>`. A node is kept only when `<src>` is a relative path (does not
   start with `/`, is not `None`, has no `..` path segment) naming a regular
   file under the graph's holding checkout.
7. `<label>` is cut to 120 characters, never inside a UTF-8 sequence. `<loc>`
   is kept as printed (`L83`, `§0ae`), and empty for `None`.
8. Rows stop once `FELIX_GRAPH_FILES` distinct files (default 8) have appeared;
   further nodes of a file already listed are still printed, and no more than
   16 rows in all.
9. No node kept: exit 1.

### A2. `felix_graph_deliver <home> <session> <root> <prompt>`

The answer, made into the block the hook hands the model, once per node per
session. Prints the block and exits 0, or prints nothing and exits 1. The
session's answer record is `<home>/state/answer/<session>.tsv`.

1. `<session>` empty, or containing anything but ASCII letters, digits, `-`
   and `_`: exit 1, nothing written.
2. One of A1 steps 1-4 refuses (graphify is not asked): exit 1, nothing
   written.
3. Otherwise exactly one `asked\tgraphify\t<outcome>` row is appended to the
   record, creating `state/answer/` as needed. The outcome is one of:
   - `late`: A1 step 5 found no time left (`FELIX_GRAPH_LEFT`), and graphify
     was not run;
   - `timeout`: the bound killed graphify at the deadline;
   - `failed`: graphify exited non-zero, or printed nothing;
   - `empty`: graphify answered, and no node survived A1 steps 6-8;
   - `repeat`: every node that survived was delivered before in this session;
   - `answered`: at least one node is delivered.
   Anything but `answered`: exit 1, nothing else written, nothing printed.
4. A node is identified by its `src`, `loc` and `label` together. A node the
   record already holds as `node\tgraphify\t<src>\t<loc>\t<label>` is dropped.
   A new node in a file named earlier in the session is delivered.
5. For an answer, after the `asked` row, in this order:
   - the session's roots, once a session: `root\t<root>` for the top level of
     `<root>`'s working tree, and `root\t<holding checkout>` when that is a
     different directory; only roots not already recorded;
   - `given\tgraphify\t<n>\t<found>`, `<n>` being the distinct files among the
     delivered nodes and `<found>` the count graphify printed on its first line
     (`... | <found> nodes found`), or `-` when it printed none;
   - one `node\tgraphify\t<src>\t<loc>\t<label>` row per delivered node, in
     graphify's order;
   - one `answer\tgraphify\t<src>` row per distinct file among the delivered
     nodes, in graphify's order. A file named in an earlier answer of the same
     session gets a row again when this answer delivers a node of it.
6. Records the delivery in the ledger: `felix_ledger_record <home> <session>`
   with the signal `answer\tgraphify`, once per delivery.
7. Prints:

   ```
   The knowledge graph's answer to this prompt (graphify query, graph built at
   <sha7>, <freshness>). Where it places what was asked, to open first:

     <src>:<loc>  <label>
     ...
   ```

   `<freshness>` is `current with the checkout that holds it` when
   `felix_graph_behind` is 0, `<n> commit(s) behind the checkout that holds it`
   when it is more, and the first line reads `graph carrying no build stamp`
   in place of `graph built at <sha7>, <freshness>` when the stamp cannot be
   read or names no commit here. A row whose `<loc>` is empty prints
   `<src>  <label>`. Rows are indented two spaces.
8. When `<found>` is a number larger than the rows printed, the rows are
   followed by a blank line and:

   ```
   These are <rows> of the <found> nodes graphify found for it; graphify query
   with a larger --budget shows more.
   ```

9. When any listed file is a shell script (its name ends in `.sh`, or the first
   128 bytes of its first line, counted as bytes whatever the locale, start
   `#!` and name `sh`, `bash` or `zsh`), the
   block ends with one more paragraph, after a blank line:

   ```
   It finds where things are, not who calls them: in shell scripts the graph
   sees few callers, so for "what calls this" grep is still the oracle.
   ```

   No shell script listed: no such paragraph.
10. Writing the record may fail (an unwritable `state/`); the block is still
    printed, the exit is still 0, and nothing is printed to stderr.

### A3. `felix_graph_refresh_due <root>`

Exits 0 when the graph exists, its stamp names a commit the holding checkout
has, HEAD is one or more commits past it, and
`graphify-out/.felix-refreshed-at` does not hold the holding checkout's HEAD;
1 otherwise (no graph, no stamp, an unknown commit, current, or already
refreshed at this HEAD). Prints nothing. The marker is a file of the checkout,
read before session start's ownership gate, so it is read only when it is a
regular file and not a symbolic link, and only its first 64 bytes, counted as
bytes in any locale; any other marker reads as absent. A checkout that commits it as a link to `/dev/zero`
must not hold session start.

### A4. `felix_graph_refresh_bg <root>`, the marker

A refresh whose `graphify update` exits 0 writes the holding checkout's HEAD,
as it was when that refresh started, to `graphify-out/.felix-refreshed-at` (the
full forty-character name and a newline), so
a refresh that wrote nothing (no topology change) is not started again at the
same HEAD. A refresh that fails writes no marker.

The marker is a file of the checkout too, so it is written to a file made new
for it and renamed into place, and the rename replaces whatever entry stands at
that path without writing through it. A symbolic link there is replaced by the
marker, and what it named, a file or a directory, is left as it was. A
directory there gets no marker and nothing inside it. No marker is written
when `graphify-out` is itself a symbolic link.

---

## 3. `hooks/user-prompt`: where the answer is given

### U1. Who gets one, checked in this order

`felix_graph_deliver` is called only when all hold, and each is checked before
the next:
1. the payload is a person's prompt (`felix_route_machine` printed nothing);
2. the payload carries a session id;
3. the graph can be asked: `FELIX_GRAPH_ANSWER` is not 0, the checkout has a
   graph (`felix_graph_file`), and `graphify` and `perl` are on `PATH`;
4. the checkout is the project's own: `felix_checkout_is_own <proj> <root>`
   returned 0. A checkout bound by a `.felix` marker alone, or by an origin that
   is not the project's, is told nothing: its `graph.json` is a file its authors
   chose, and the labels would reach the model under Felix's name.

The prompt is read out of the payload only once all four hold.

### U2. What it is asked

The prompt is the payload's `"prompt"` string, read up to its first unescaped
double quote, with `\"` read as a quote and `\\` as a backslash. The rest of
the payload is never part of the question. At most the first 16,384 bytes
after the opening quote are read, counted as bytes whatever the hook's locale,
so a pasted prompt is parsed for the same cost whatever its size; finding the
key is a scan of the payload, which grows with it, as the route's already does.

### U3. Where it goes

The block is one more part of the one `additionalContext` this hook already
emits, after the route and shape parts and before the lessons part, separated
from its neighbours by one blank line. A prompt that produces only this part
still produces the hook's JSON output. A prompt that produces none of the parts
still exits 0 with no output.

### U4. It never costs the prompt

A graphify that fails, hangs past the timeout, prints garbage, or is absent
leaves the hook's exit 0 and its other parts unchanged.

Nor may the ask take the hook past the platform's limit on it, 30 seconds. A
run the platform ends prints nothing, so the route, shape and lessons parts
would go with the answer. The hook calls `felix_graph_deliver` with
`FELIX_GRAPH_LEFT` set to `D - S - 3`: `D` is `FELIX_PROMPT_DEADLINE`, 30
unless that is a whole number of at most four digits, and `S` is the whole
seconds the hook has run so far (bash's `SECONDS`). The 3 are kept for the
rest of the run. So with under one second left the ask is recorded as `late`
(A2.3) and graphify is not run, and otherwise its bound is the smaller of
`FELIX_GRAPH_TIMEOUT` and what is left (A1.5).

What this leaves: a run cut off after `felix_graph_deliver` has written its
rows, inside the 3 seconds kept, leaves a record of nodes the model was never
given, and A2.4 does not give them again in that session. The reserve makes
that rare, and nothing records it when it happens.

### U5. A prompt ends the previous answer's window

On every person prompt with a session id, when the session's answer record
`<home>/state/answer/<session>.tsv` already exists, the hook appends one
`prompt` row (the word alone) to it, before anything else this prompt writes
there. No record yet: nothing is written. U1's conditions 3 and 4 do not apply
to this row: a session that was answered once has its prompts counted. It is
written before the hook computes its route, so a run cut off at any later
point, at the platform's limit or otherwise, has still ended the turn.

---

## 4. `hooks/post-tool`: what the session did next

### T1. Recording follow-through, only as matches

After the existing ledger appends, when `<home>/state/answer/<session>.tsv`
exists and the session id passes A2.1's test, the hook reads one value from the
payload. Since 0.49.313 those appends are an `alive<TAB>post-tool` line, written
first, and then the call's own row; the session is the payload's first
`"session_id"`. The value:

| Tool | value |
|---|---|
| `Read`, `Edit`, `Write`, `MultiEdit` | the string after the first `"file_path":` |
| `NotebookEdit` | the string after the first `"notebook_path":` |
| `Grep`, `Glob` | the string after the first `"path":` |
| `Bash` | the string after the first `"command":` |

"First" is the first occurrence in the payload of the key followed directly by
a colon, so a key of the same name inside the tool's response, or a value that
happens to equal the key's name, cannot replace the input. The string is read
to its first unescaped double quote and decoded: `\"` is a quote, `\\` a
backslash, `\/` a slash, and `\n`, `\t`, `\r` are each a space. At most the
first 16,384 bytes are read.

For each distinct file named by an `answer` row after the record's last
`prompt` row, the hook appends `touch\t<Tool>\t<file>` when the value matches
that file by L4's rule. Nothing else of the value is ever written: not the
path, not the command. A tool not in the table, a payload without the key, or
no match appends nothing.

### T2. Cost

No git, and one process beyond what the hook runs today, and that only when
the state file exists. A failed append is silent and the exit is 0. Loading
`lib/ledger.sh`, which loads `lib/answer.sh`, runs no command found on `PATH`;
nor does loading `lib/graph.sh`, which loads `lib/graph-answer.sh`.

---

## 5. `hooks/session-end` and `hooks/session-start`: the graph kept current

### R1. When the session ends

At the end of every session that is not a machine session (the existing early
exit stands) and resolves to a project, the hook runs
`felix_graph_refresh_bg <root>` when, and only when, checked in this order:
- `graphify` is on `PATH`;
- `felix_checkout_is_own <proj> <root>` returned 0;
- `felix_graph_refresh_due <root>` exits 0.

`<root>` is the top level of the session's working tree. Ownership is checked
before anything reads the checkout's `graph.json`.

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

What this leaves: two calls that find the same stale lock at once can both
take it back, the second after the first has made it anew, and two refreshes
then run together. The break existed before this spec (audit b06, C043), with
the same two steps, and it is left so.

### R4. Session start uses the same test

`hooks/session-start` starts its refresh when `felix_graph_refresh_due` exits 0
(and graphify is on `PATH` and the own-checkout gate allows it), in place of
testing its banner line for "behind this checkout". The banner line itself is
unchanged.

---

## 6. `lib/ledger.sh`, `lib/answer.sh` and `felix ledger`: the answer as its own surface

### L1. The rollup

A row of kind `answer` in a session's appends is folded like any other kind,
`<session>\t<date>\tanswer\t<tool>\t<deliveries>\t`, with the sixth field
empty: a route naming the same tool is the policy's decision about the tool and
is not a naming of the answer. An `answer` row stands for no declared
capability, so a session given graphify's answer still gets its zero row for a
declared `graphify` it never reached for.

Nor is an `answer` row a call when the fold decides whether the session's
record is whole, by its `alive` lines against its calls (0.49.313). The
user-prompt hook writes it, so it says nothing about whether a PostToolUse run
recorded what it saw. A session with more `alive` lines than calls, or with
neither, folds its zero and named rows as `-`, unknown, however many answers it
was given.

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
(`_felix_ledger_owns`, the same test the catch-up uses). Prints, per tool that
has a `given` or an `asked` row in one of those records,
`tool\tsessions\tsessions_acted\tdeliveries\tdeliveries_acted\tfiles\tfiles_acted\tfiles_opened\tasked\ttimeouts\tlate\tunknown`.

- **A record that is not whole.** A session whose ledger appends,
  `<home>/state/ledger/<session>.tsv`, are not whole by L1's test (more `alive`
  lines than calls, or neither; a file that is missing or cannot be read is not
  whole) is left out of every column but `unknown`. `unknown` counts those
  sessions, once per tool with an `asked` or a `given` row in the session's
  answer record. A PostToolUse run that recorded nothing may have reached a
  named file, and a touch it missed would read as an answer not used.

- **The window.** A `touch` row can credit only the `answer` rows after the
  record's last `prompt` row before it: an answer is acted on in the turn it was
  given, as the baseline measures it.
- **A row T1 wrote.** A `touch` row whose third field equals a file named by
  an `answer` row in its window credits that file's rows and no other: T1
  already decided which file the call reached, and a second reading of the
  bare name could credit another (the basename rule would credit
  `projects/x/CLAUDE.md` for a row naming `CLAUDE.md`).
- **The match**, for any other `touch` row, a file `f` named by an `answer`
  row and the row's third field `v`, with `R` any directory in the record's
  `root` rows wherever they sit in it. It is the rule T1 applies when it writes
  a row:
  - `Read`, `Edit`, `Write`, `MultiEdit`, `NotebookEdit`, `Grep`, `Glob`: `v`
    equals `f` or `R/f`; when the record has no `root` row, `v` equal to `f` or
    ending in `/f`.
  - `Bash`: `v` holds `f` as a path token, or holds `R/f` anywhere, or, when
    `f`'s basename has a `.`, holds that basename as a token. A token is bounded
    on the left by the start of `v`, a space, a tab, a quote (`"` or `'`), `=`,
    `(`, `:` or `./`, and on the right by the end of `v`, a space, a tab, a
    quote, `;`, `|`, `&`, `)`, `:` or `,`. So `projects/a/CLAUDE.md` does not
    credit `projects/b/CLAUDE.md`, and `1-24.md` does not credit `4.md`.
- An `answer` row is acted on when a later `touch` row in its window matches
  it. A delivery (a `given` row and the `answer` rows after it, up to the next
  `given` or `prompt` row) is acted on when any of its files was. A session is
  acted on when any of its deliveries was.
- `deliveries` counts `given` rows and `files` counts `answer` rows.
  `files_opened` counts the acted-on `answer` rows credited by a touch of any
  tool but `Bash`. `asked` counts `asked` rows whose outcome is not `late`, and
  `timeouts` those whose outcome is `timeout`; `late` counts the `asked` rows
  whose outcome is `late`. `sessions` counts sessions with at least one `given`
  row.
- **What it cannot see.** A call that fails never reaches the post-tool hook
  (PostToolUse runs after a successful call only), so it is never a touch. And
  the post-tool hook runs asynchronously: a call made just before a prompt can
  be recorded just after that prompt's row, and so fall outside its turn. Both
  are left as they are; the baseline applies the first and cannot apply the
  second.

### L5. `felix ledger` prints it

When `felix_answer_use` prints anything, `felix ledger` adds, after the
capability table, a section headed
`answers handed to sessions without being asked for`, one line per tool:

```
  graphify     answered 37 of 50 asks in 12 sessions; 21 answers (57%) named a file the session then opened, edited or ran before the next prompt; 61 of 190 files (32%), 40 of them opened or edited, not only run
```

with, when `timeouts` is more than 0, `; 6 asks timed out` appended to the
line; then, when `late` is more than 0, `; 2 prompts came too late in the hook
to ask`; then, when `unknown` is more than 0, `; 3 sessions left out, their
record of tool calls incomplete`. Then the sentence: `A file the session would have opened anyway counts
here too, so this is the most the answers can have caused, not what they
caused.` Shares are whole percentages, rounded half up, and 0% when the
denominator is 0. The capability table's rows are unchanged by `answer` rows.

---

## 7. Decisions, with their evidence

- **`query` on the prompt, not `affected` on the edit.** Section 1: 16% recall
  of dependents on bash; `affected` on a file finds none. An injected list that
  is 84% short is worse than none, because it reads as complete.
- **Every substantive prompt, once per node per session.** The first prompt is
  "read the graph at the beginning", the founder's words of 2026-10-29. Later
  prompts add only nodes not yet given, so a new symbol in a file named earlier
  still arrives with its line (a review found file-level dedupe withheld exactly
  the location a later question asked for).
- **Partial answers say so.** graphify's own notice exists so that "a truncated
  answer can never be mistaken for a complete one"; dropping it would repeat
  the defect that ruled out `affected`.
- **Matches, never values, in `state/`.** The home checkout sits in synced
  Documents. A raw command can hold a credential, and the measure needs only
  whether a named file was reached.
- **The turn as the window, and rows for misses.** The live measure and its
  baseline must use one rule, or a rule difference reads as a lift. `asked` rows
  give the deliveries a denominator under load.
- **No holdout.** A held-out arm would measure cause, and it would withhold the
  graph from one session in five that the founder wants it in. The cause is
  bounded instead by a baseline replayed from the transcripts of the fourteen
  days before this change with this spec's own rules (section 8).
- **Own checkout only.** `lib/own.sh`'s class: a tool whose behaviour depends on
  the checkout's files. Here the output is the model's context.
- **The answer surface is general.** `state/answer/`, ledger kind `answer`, the
  tool as the name: the next tool whose answer should be delivered writes the
  same rows and is measured by the same function.

## 8. The baseline, measured before the change

Recorded in the pull request: over Felix transcripts from the 14 days before
2026-10-29, a replay of these rules with no answer given: for each person prompt
of five words or more, what this query would have answered after this spec's
dedupe, and whether the session (its subagents included) then opened, edited or
ran one of those files before the next person prompt, matched by L4's rule.
That is the share a delivered answer has to beat.

The replay counts what the live measure can count and nothing else: only
sessions the hooks ran in (a session mark, the test L4 applies through
`_felix_ledger_owns`), so automated SDK sessions that load no plugin are out;
every prompt the user-prompt hook sees as a person's, a prompt queued while the
model worked among them; a touch only from a call that succeeded; and a Bash
value cut at 16,384 bytes of its escaped form, as T1 cuts it.

## 9. What changed after the review of 2026-10-29

A1.5 (the bound kills the process group, at the deadline and after an exit),
A1.6 (src and loc cleaned), A1.7 (label cut by characters); A2.1 (session id
characters), A2.3 (`asked` rows and outcomes), A2.4-A2.5 (dedupe by node;
`root`, `given` with `<found>`, `node` and repeated `answer` rows), A2.7 (the
header ends "to open first:"), A2.8 (new: the partial-answer line), A2.9 (the
first 128 bytes only), A2.10 (silent); A3 and A4 (the refreshed-at marker); U1
(the order, and the cheap tests before the ownership test and the prompt);
U2 (16,384 bytes); U5 (new: `prompt` rows); T1 (key with its colon, decoded
string, matches only, `touch` rows hold the named file); R1 (ownership before
the due test); R4 (new: session start uses the due test); L4 (the window, the
token rule, root anchoring from any root row of the record, the match applied
to a touch row's third field, `files_opened`, `asked`, `timeouts`); L5 (the line,
the timeout clause, rounding). Sections 0, 1, 7 and 8 were corrected to match.

And after the review of the amendment, the same day: A1.5 (a timeout that is
not a whole number of one or more is the default; the group signalled until
empty), A2.9 and U2 (bytes in any locale), A3 (the marker read only as a
regular file, and only 64 bytes of it, in any locale), A4 (the marker renamed into place,
never written through a link or into a directory), L4 (a row T1 wrote credits
its own file only; what the measure cannot see), section 8 (the replay's
population and rules).

And when main's audit wave 2 (0.49.313) was merged in: T1 (the ledger appends
it follows now begin with an `alive` line), L1 (an `answer` row is not a call
in the fold's test of a whole record).

And after the review of that merge, the same day: A1.5 and A2.3 (no ask, and
the outcome `late`, when the calling hook has no time left; the bound never
longer than what is left), U4 (the hook passes what is left of its 30 seconds,
less 3, and what a cut inside those 3 leaves), U5 (the `prompt` row written
before the route), T2 (loading the libraries runs nothing on `PATH`), R3 (the
two-step race, said and left), L4 (a session whose ledger record is not whole
is left out, and counted in `unknown`; `late`), L5 (the late and left-out
clauses). And section 2: A1 and A2 moved to `lib/graph-answer.sh`, which
`lib/graph.sh` loads, because this change had taken `lib/graph.sh` past 500
lines.
