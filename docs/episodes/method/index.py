"""index.py <prompts-out.tsv> <sessions-out.tsv>: every user-role prompt in the Felix
transcripts, one row each: timestamp, session, worktree, branch, length, origin, text.
Origin tells founder-typed text from task notifications, messages from other
sessions and platform summaries. A chip-launched session's first prompt is
agent-written and still reads founder-typed here: check it by hand."""
import json, sys, glob, os, re
root = os.path.expanduser('~/.claude/projects')
dirs = [d for d in glob.glob(root + '/*') if 'Felix' in d and '-private-tmp-' not in d]
out = open(sys.argv[1], 'w')
sess = open(sys.argv[2], 'w')
strip = re.compile(r'<(system-reminder|command-message|command-args|local-command-stdout)>.*?</\1>', re.S)


def origin(text):
    """Who wrote a user-role message. Only founder-typed rows are founder turns."""
    t = text.lstrip()
    if t.startswith('<task-notification>'): return 'task-notification'
    if t.startswith('<cross-session-message'): return 'peer-session'
    if t.startswith('This session is being continued from a previous conversation'): return 'platform-summary'
    return 'founder-typed'
n = 0
for d in sorted(dirs):
    wt = os.path.basename(d).split('worktrees-')[-1] if 'worktrees-' in d else os.path.basename(d)
    for f in sorted(glob.glob(d + '/*.jsonl')):
        sid = os.path.basename(f)[:-6]
        title = ''; first = last = ''; branch = ''; count = 0; size = os.path.getsize(f)
        seen = set()
        for line in open(f, errors='replace'):
            try: e = json.loads(line)
            except Exception: continue
            t = e.get('type')
            if t == 'custom-title': title = e.get('customTitle') or e.get('title') or title
            ts = e.get('timestamp', '')
            if ts:
                first = first or ts; last = ts
            branch = e.get('gitBranch') or branch
            text = None
            if t == 'user' and not e.get('isMeta') and not e.get('isSidechain'):
                c = (e.get('message') or {}).get('content')
                if isinstance(c, str): text = c
                elif isinstance(c, list):
                    if any(b.get('type') == 'tool_result' for b in c if isinstance(b, dict)): continue
                    text = '\n'.join(b.get('text', '') for b in c if isinstance(b, dict) and b.get('type') == 'text')
            elif t == 'queue-operation' and e.get('operation') == 'enqueue':
                text = e.get('content') if isinstance(e.get('content'), str) else None
            if not text: continue
            text = strip.sub('', text).strip()
            if not text or text.startswith('<local-command') or text.startswith('Caveat:'): continue
            key = text[:200]
            if key in seen: continue
            seen.add(key)
            count += 1; n += 1
            out.write('\t'.join([ts, sid, wt, branch, str(len(text)), origin(text), text.replace('\\', '\\\\').replace('\t', ' ').replace('\n', '\\n')]) + '\n')
        sess.write('\t'.join([sid, wt, branch, first, last, str(count), str(size), title.replace('\t', ' ')]) + '\n')
print(n, 'prompts from', len(dirs), 'dirs')
