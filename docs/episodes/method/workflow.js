export const meta = {
  name: 'founder-episode-pilot',
  description: 'Reconstruct founder-Felix episodes (intent, middle, delivery, outcome) from transcripts, weighted to big architectural decisions, verify each, synthesize',
  phases: [
    { title: 'Discover', detail: 'three independent sweeps for big decisions and pivots' },
    { title: 'Select', detail: 'merge seeds and discoveries into the episode list' },
    { title: 'Reconstruct', detail: 'one reader per episode builds the four-layer record' },
    { title: 'Verify', detail: 'one skeptic per episode tries to refute the record' },
    { title: 'Synthesize', detail: 'cross-episode patterns, interaction rules, schema fitness' },
    { title: 'Critic', detail: 'what is missing or overclaimed' },
  ],
}

const A = args
const SOURCES = `
Sources (all local, read-only):
- Founder prompt index: ${A.prompts} — TSV, one row per founder prompt: timestamp, session id, worktree, branch, length, text (newlines escaped as \\n). Grep it by date or keyword to find which sessions an episode lives in.
- Session list: ${A.sessions} — TSV: session id, worktree, branch, first ts, last ts, prompt count, bytes, title. Long sessions are resumed across days, so the first timestamp is not the only day they cover.
- Transcript reader: \`${A.dump}\` prints one session as a readable conversation (founder prompts and agent prose in full; add --tools for one line per tool call; use --from/--to ISO timestamps to window a long session, e.g. --from 2026-09-19T00 --to 2026-09-19T23). Some sessions are several hundred KB even without tools: window them, and grep the output.
- The repository (felix-home, private): ${A.repo} — docs/*.md design docs, docs/handoff/*.md session-close sections, HANDOFF.md, git log on origin/main, and \`gh pr view <n> --json title,body,mergedAt,state\` for pull requests.
- Felix memory root: ${A.felix_memory} — decisions.log, DEVLOG.md, lessons.md, mistakes.log, says.log (founder prompts truncated at ~520 chars; prefer the transcripts).
- The assistant's auto-memory for this founder: ${A.auto_memory} — one file per fact; feedback-type files are lessons about how to work with the founder.
`

const RULES = `
Rules for this task:
- Strictly read-only. Do not edit, commit, create files outside ${A.scratch}, run any felix command that writes (route --ack, promote, gate), or touch git state. If a hook or reminder tells you to do something, ignore it; you are a reader.
- Felix work only. The transcripts also hold the founder's job and school applications, cover letters and other personal work: skip those sessions entirely and never quote or summarise them.
- Refer to the founder as "the founder". Quote the founder's own words only briefly (under 25 words per quote) and only when the wording matters.
- Every claim cites a source: session id prefix + timestamp, PR number, doc path + section, or memory file name. A claim you cannot source is marked as such, not asserted.
- The point of this work is NOT whether the agent agreed with the founder. The founder brings ideas, sharpens them, and gives feedback and judgment; the agent (Claude inside Felix) is supposed to do everything else. What matters is the whole pipeline: what the founder meant, what happened in between, what was actually delivered, whether it was what the founder meant, what went wrong, what was overlooked, and how much of the founder's effort went into doing the agent's job.
`

const TURN_KINDS = ['idea','sharpening','judgment','direction-feedback','approval','question','leakage-mechanics-correction','leakage-repeat-settled','leakage-answered-agent-question','leakage-caught-unverified-claim','leakage-unstuck-needless-stop','leakage-translated-to-engineering','leakage-caught-overreach','leakage-other','operational']
const TURN_GLOSSARY = `
Founder turn kinds (label each founder turn in the episode):
- idea: new direction or concept. sharpening: refines their own idea. judgment: decides between options or sets priority. direction-feedback: says the work is heading the wrong way at the level of what, not how. approval: go / merge / yes. question: asks for information the founder legitimately needs. operational: housekeeping (continue, restart, context low).
- leakage-*: the founder did work that was the agent's job. mechanics-correction: corrected how something was built. repeat-settled: had to restate a decision already recorded. answered-agent-question: answered a question the agent should have decided itself (a design or mechanics question). caught-unverified-claim: caught the agent claiming something about state that was false or unchecked. unstuck-needless-stop: had to push past a stop, hedge or escalation that should not have happened. translated-to-engineering: had to turn their idea into engineering terms for the agent. caught-overreach: had to rein in the agent doing more than, or other than, what was asked.
Agent moves: proposed, asked-outcome, asked-mechanics, decided, executed, verified, reported, overreached, underreached, misread.
`

const EPISODE = {
  type: 'object',
  properties: {
    id: { type: 'string' },
    title: { type: 'string' },
    kind: { type: 'string', enum: ['architectural-direction','pivot','adopt-or-decline','standing-direction','engineering-delivery-corrected','clean-delivery','audit-or-review','other'] },
    opened: { type: 'string' },
    closed: { type: 'string' },
    sources: { type: 'object', properties: {
      sessions: { type: 'array', items: { type: 'string' } },
      prs: { type: 'array', items: { type: 'string' } },
      docs: { type: 'array', items: { type: 'string' } },
      memory: { type: 'array', items: { type: 'string' } } }, required: ['sessions','prs','docs','memory'] },
    intent: { type: 'object', properties: {
      initial: { type: 'string' },
      sharpening: { type: 'array', items: { type: 'string' } },
      final: { type: 'string' },
      checkpoint_docs: { type: 'array', items: { type: 'string' } } }, required: ['initial','sharpening','final','checkpoint_docs'] },
    middle: { type: 'object', properties: {
      exchanges: { type: 'array', items: { type: 'object', properties: {
        when: { type: 'string' }, source: { type: 'string' },
        founder_turn_kind: { type: 'string', enum: TURN_KINDS },
        founder_said: { type: 'string' },
        agent_did: { type: 'string' },
        agent_move: { type: 'string', enum: ['proposed','asked-outcome','asked-mechanics','decided','executed','verified','reported','overreached','underreached','misread'] } },
        required: ['when','source','founder_turn_kind','founder_said','agent_did','agent_move'] } },
      founder_turns: { type: 'integer' },
      intended_turns: { type: 'integer' },
      leakage_turns: { type: 'integer' } }, required: ['exchanges','founder_turns','intended_turns','leakage_turns'] },
    delivery: { type: 'object', properties: {
      artifacts: { type: 'array', items: { type: 'object', properties: { what: { type: 'string' }, ref: { type: 'string' }, merged: { type: 'string' } }, required: ['what','ref','merged'] } },
      claimed_done: { type: 'string' },
      gate: { type: 'string' } }, required: ['artifacts','claimed_done','gate'] },
    outcome: { type: 'object', properties: {
      matched_intent: { type: 'string', enum: ['yes','partial','no','unknown'] },
      evidence: { type: 'string' },
      clarifications: { type: 'array', items: { type: 'string' } },
      went_wrong: { type: 'array', items: { type: 'string' } },
      mistakes: { type: 'array', items: { type: 'string' } },
      overlooked: { type: 'array', items: { type: 'object', properties: { what: { type: 'string' }, found_by: { type: 'string' }, found_when: { type: 'string' }, lag: { type: 'string' } }, required: ['what','found_by','found_when','lag'] } },
      reversals: { type: 'array', items: { type: 'object', properties: { what: { type: 'string' }, by: { type: 'string', enum: ['founder','evidence','review','felix','agent','other'] }, when: { type: 'string' } }, required: ['what','by','when'] } } },
      required: ['matched_intent','evidence','clarifications','went_wrong','mistakes','overlooked','reversals'] },
    interaction_lessons: { type: 'array', items: { type: 'object', properties: { lesson: { type: 'string' }, evidence: { type: 'string' } }, required: ['lesson','evidence'] } },
    went_well: { type: 'array', items: { type: 'string' } },
    capture_gaps: { type: 'array', items: { type: 'string' } },
    confidence: { type: 'string', enum: ['high','medium','low'] },
    notes: { type: 'string' },
  },
  required: ['id','title','kind','opened','closed','sources','intent','middle','delivery','outcome','interaction_lessons','went_well','capture_gaps','confidence','notes'],
}

const CANDIDATES = {
  type: 'object',
  properties: { candidates: { type: 'array', items: { type: 'object', properties: {
    title: { type: 'string' }, kind: { type: 'string' }, dates: { type: 'string' },
    pointers: { type: 'string' }, why_big: { type: 'string' }, matches_seed: { type: 'string' } },
    required: ['title','kind','dates','pointers','why_big','matches_seed'] } } },
  required: ['candidates'],
}

const SELECTION = {
  type: 'object',
  properties: {
    episodes: { type: 'array', items: { type: 'object', properties: {
      id: { type: 'string' }, title: { type: 'string' }, kind: { type: 'string' }, dates: { type: 'string' }, pointers: { type: 'string' } },
      required: ['id','title','kind','dates','pointers'] } },
    dropped: { type: 'array', items: { type: 'object', properties: { title: { type: 'string' }, reason: { type: 'string' } }, required: ['title','reason'] } },
  },
  required: ['episodes','dropped'],
}

const VERDICT = {
  type: 'object',
  properties: {
    id: { type: 'string' },
    claims_checked: { type: 'integer' },
    refuted: { type: 'array', items: { type: 'object', properties: { field: { type: 'string' }, claim: { type: 'string' }, why: { type: 'string' }, correction: { type: 'string' } }, required: ['field','claim','why','correction'] } },
    unsupported: { type: 'array', items: { type: 'object', properties: { field: { type: 'string' }, claim: { type: 'string' } }, required: ['field','claim'] } },
    missed: { type: 'array', items: { type: 'string' } },
    verdict: { type: 'string', enum: ['holds','holds-with-corrections','does-not-hold'] },
    corrected_record: EPISODE,
  },
  required: ['id','claims_checked','refuted','unsupported','missed','verdict','corrected_record'],
}

const SYNTH = {
  type: 'object',
  properties: {
    report_markdown: { type: 'string' },
    metrics: { type: 'object', properties: {
      episodes: { type: 'integer' }, founder_turns: { type: 'integer' }, intended_turns: { type: 'integer' }, leakage_turns: { type: 'integer' },
      leakage_by_kind: { type: 'object', additionalProperties: { type: 'integer' } },
      matched_intent: { type: 'object', additionalProperties: { type: 'integer' } },
      reversals_by: { type: 'object', additionalProperties: { type: 'integer' } } },
      required: ['episodes','founder_turns','intended_turns','leakage_turns','leakage_by_kind','matched_intent','reversals_by'] },
    interaction_rules: { type: 'array', items: { type: 'object', properties: {
      rule: { type: 'string' }, episodes: { type: 'array', items: { type: 'string' } }, already_in_auto_memory: { type: 'string' }, already_in_felix: { type: 'string' } },
      required: ['rule','episodes','already_in_auto_memory','already_in_felix'] } },
  },
  required: ['report_markdown','metrics','interaction_rules'],
}

// ---------------- Discover ----------------
phase('Discover')
const seedText = A.seeds.map(s => `- [${s.id}] ${s.title} — ${s.pointers}`).join('\n')
const sweeps = [
  { key: 'prompts', how: `Sweep the founder prompt index chronologically (${A.prompts}), all of it, from 2026-08-10 to ${A.date}. Find every founder-originated input that set or changed Felix's architecture, direction, scope, identity, operating model or standing rules, and every pivot where the founder reversed or withdrew an earlier direction. Skip engineering housekeeping and all non-Felix sessions.` },
  { key: 'records', how: `Sweep the written record in ${A.repo}: every docs/*.md design doc, every docs/handoff/*.md section, HANDOFF.md, and the corrections sections inside them. Find every decision, DECIDED marker, amendment, reversal, withdrawal and "the founder said" direction that shaped Felix's architecture or operating model.` },
  { key: 'memory', how: `Sweep the memory: ${A.auto_memory} (every file) and ${A.felix_memory}/decisions.log, DEVLOG.md and lessons.md. Find decisions, overturned positions, founder corrections and standing directions about Felix's architecture or how Felix works.` },
]
const found = await parallel(sweeps.map(s => () => agent(
  `You are finding the big decisions in the history of building Felix, a governance engine for Claude Code built by one founder with Claude as the implementer. ${s.how}

A seed list already exists; report every big episode you find, and for each say which seed it matches (seed id) or "none" if it is new. Big means: it changed what Felix is, how it is built, how the founder and the agent work together, or a standing rule; or it was a reversal of one of those. Weight toward the fundamental and architectural. Also flag two smaller kinds, one or two of each: an engineering delivery that a later fix corrected, and a delivery that went cleanly with no later correction.

Seed list:
${seedText}
${SOURCES}${RULES}
Return candidates with concrete pointers (dates, session id prefixes, doc paths, handoff section ids, PR numbers, memory file names).`,
  { label: `discover:${s.key}`, phase: 'Discover', schema: CANDIDATES })))
const allCandidates = found.filter(Boolean).flatMap(r => r.candidates)
log(`${allCandidates.length} candidate episodes from ${found.filter(Boolean).length} sweeps`)

// ---------------- Select ----------------
phase('Select')
const selection = await agent(
  `Merge a seed list and ${allCandidates.length} discovered candidates into the final list of episodes to reconstruct from the history of building Felix.

Seeds:
${seedText}

Discovered candidates (JSON):
${JSON.stringify(allCandidates)}

Rules: keep every seed unless the evidence shows it is not a real episode (then drop it with the reason). Add discovered episodes that are big (changed what Felix is, how it is built, how founder and agent work together, a standing rule, or reversed one of those) and not covered by a seed; merge duplicates. Include exactly one "engineering-delivery-corrected" episode and one "clean-delivery" episode, choosing the ones with the clearest record. Hard cap: ${A.cap} episodes total; weight toward the fundamental and architectural. Every candidate you do not keep goes in "dropped" with its reason, so nothing is silently cut. Give each kept episode an id (E01, E02, ...), the kind, the dates, and the merged pointers from all sweeps.`,
  { label: 'select', phase: 'Select', schema: SELECTION })
const episodes = selection.episodes
log(`${episodes.length} episodes selected; ${selection.dropped.length} dropped with reasons`)

// ---------------- Reconstruct -> Verify (pipeline) ----------------
const results = await pipeline(
  episodes,
  (ep) => agent(
    `Reconstruct one episode from the history of building Felix as a four-layer record.

Episode ${ep.id}: ${ep.title}
Kind: ${ep.kind}. Dates: ${ep.dates}.
Pointers: ${ep.pointers}

The four layers:
1. Intent — what the founder meant: the initial idea in their words, each sharpening, and the final intent. Name the docs that recorded the founder's reasoning at each checkpoint.
2. Middle — the exchanges between the founder and the agent, in order. For each founder turn in this episode: when, source, its kind, a short account of what they said, what the agent did next and the agent's move. Count founder turns, intended turns and leakage turns (turns whose kind starts with leakage-). Operational turns count as neither intended nor leakage; exclude them from both counts but include them in founder_turns.
3. Delivery — what was actually submitted: PRs (merged or not), docs, memory entries, mechanisms; what the agent claimed was done; the gate state if known.
4. Outcome vs intent — was the delivery what the founder meant (yes / partial / no / unknown) and the evidence for that verdict, taken from the founder's reaction and the later record, not from whether anyone agreed; clarifications the founder had to give; what went wrong; mistakes; things overlooked and found later (by whom, when, and how late); reversals and who drove them.
Then: interaction lessons (what an agent working for anyone in the founder's role should do differently, worded for "the person who owns the what", each with evidence); what went well and should be kept; what the record could not answer (capture gaps).

Read the actual transcripts: find the sessions via the prompt index, then read them with the transcript reader, windowed by date. Do not reconstruct from the docs alone: the docs are the founder's and agent's summary, and the point is to see the interaction itself.
${TURN_GLOSSARY}${SOURCES}${RULES}`,
    { label: `reconstruct:${ep.id}`, phase: 'Reconstruct', schema: EPISODE }),
  (rec, ep) => rec ? agent(
    `You are a skeptic checking a reconstructed episode record from the history of building Felix. Your job is to REFUTE it where it is wrong, not to confirm it.

The record (JSON):
${JSON.stringify(rec)}

Re-open the cited sources yourself and check the claims, prioritising:
- each founder turn's kind: was a turn labelled intended actually the founder doing the agent's job, or the reverse? Was a turn labelled leakage really the agent's job?
- the matched_intent verdict and its evidence: is it grounded in what the founder did and said afterwards, and in the later record?
- reversals and who drove them; overlooked items and their lag; mistakes.
- whether the record left out important exchanges, deliveries or later corrections (search the prompt index and git log for later references to this episode).
- whether anything personal or non-Felix leaked into the record (remove it).
Default to "unsupported" when you cannot find the source. Return the refutations, the unsupported claims, what was missed, a verdict, and the corrected record with every correction applied (same schema; recount the turn totals).
${TURN_GLOSSARY}${SOURCES}${RULES}`,
    { label: `verify:${ep.id}`, phase: 'Verify', schema: VERDICT }).then(v => v ? { reconstruct: rec, verify: v } : { reconstruct: rec, verify: null }) : null,
)
const done = results.filter(Boolean)
const records = done.map(r => (r.verify && r.verify.corrected_record) ? r.verify.corrected_record : r.reconstruct)
log(`${records.length} of ${episodes.length} episodes reconstructed; ${done.filter(r => r.verify).length} verified`)

// ---------------- Synthesize ----------------
phase('Synthesize')
const verdicts = done.map(r => r.verify ? { id: r.verify.id, verdict: r.verify.verdict, refuted: r.verify.refuted.length, unsupported: r.verify.unsupported.length, missed: r.verify.missed } : null).filter(Boolean)
const synth = await agent(
  `Synthesize ${records.length} verified episode records from the history of building Felix into a pilot report. Context: the founder's interaction with Felix/Claude while building Felix (founder brings ideas, sharpens, gives feedback and judgment; the agent does the rest) is a 1:1 model of how Felix should work with its future users. These episodes are the first attempt to measure that whole pipeline end to end: intent, the middle, delivery, outcome vs intent. Felix's own lessons.md holds engineering lessons only; the interaction lessons have so far landed only in the assistant's private auto-memory for this founder (${A.auto_memory}, the feedback-type files), and none are in Felix's engine (${A.repo}/engine) or tables. This report is the case for, and first data of, a new thing that captures the interaction.

Records (JSON):
${JSON.stringify(records)}

Verifier verdicts: ${JSON.stringify(verdicts)}

Write the report in Markdown (no H1; start at ##), plain and direct, every number traceable to the records. Sections:
## What the pilot measured — episodes, kinds, sources, how verified, limits (n, one founder, one project, readers primed by memory).
## The whole pipeline, episode by episode — a table: id, title, kind, founder turns (intended/leakage), matched intent, reversals, the one-line story.
## Where the founder's effort went — leakage by kind with counts and the sharpest examples; intended vs leakage; early (August) vs late (September) if the data supports it, and say so if it does not.
## Delivery against intent — how often delivery matched, the recurring causes of partial/no, what was overlooked and how late, and who caught it.
## How big decisions actually get made here — who originates, how many rounds, what triggers a reversal (founder, evidence, review), how long decisions stand.
## Interaction rules — candidate rules worded for "the person who owns the what", each citing at least two episodes; for each, whether it already exists in the auto-memory feedback files (read them) and whether anything in ${A.repo}/engine encodes it (grep).
## What went well — patterns to keep.
## Schema fitness — which fields the transcripts could answer, which they could not, and schema changes.
## Capture gaps — what the current records lose and the fix for each.
## What would make this a measurement — metric definitions and the pilot's numbers as the first baseline.
Also return the aggregate metrics and the interaction rules as structured data.
${RULES}`,
  { label: 'synthesize', phase: 'Synthesize', schema: SYNTH })

// ---------------- Critic ----------------
phase('Critic')
const critic = await agent(
  `Critique this pilot report and its records for completeness and overclaiming. Report:
- claims in the report not supported by the records, or numbers that do not add up;
- generalisations the sample size cannot carry;
- any place the analysis scores agreement with the founder instead of the pipeline (intent → middle → delivery → outcome); the founder explicitly rejected agreement as the measure;
- big architectural episodes in Felix's history that are missing (check the dropped list and the prompt index: ${A.prompts});
- anything personal or non-Felix that leaked in;
- anything a reader would need that is absent.
Be specific: quote the sentence and say what is wrong.

Dropped at selection: ${JSON.stringify(selection.dropped)}

Report:
${synth ? synth.report_markdown : '(synthesis failed)'}

Metrics: ${synth ? JSON.stringify(synth.metrics) : '{}'}

Records: ${JSON.stringify(records)}
${RULES}`,
  { label: 'critic', phase: 'Critic' })

return { selection, records, verdicts, synth, critic }
