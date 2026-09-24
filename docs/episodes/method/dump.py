#!/usr/bin/env python3
"""dump.py <session-id-or-prefix> [--tools] [--from ISO] [--to ISO]
Prints one Claude Code transcript as a readable conversation: every founder
prompt in full, every assistant prose message in full, and (with --tools) one
line per tool call. Tool results and attachments are omitted."""
import json, sys, glob, os, re
args = sys.argv[1:]
sid = args[0]; tools = '--tools' in args
lo = args[args.index('--from') + 1] if '--from' in args else ''
hi = args[args.index('--to') + 1] if '--to' in args else '9999'
files = [f for f in glob.glob(os.path.expanduser('~/.claude/projects/*/' + sid + '*.jsonl'))]
if not files: sys.exit('no transcript for ' + sid)
strip = re.compile(r'<(system-reminder|command-message|command-args|local-command-stdout)>.*?</\1>', re.S)
def who(t):
    t = t.lstrip()
    if t.startswith('<task-notification>'): return 'NOTIFICATION (not the founder)'
    if t.startswith('<cross-session-message'): return 'PEER SESSION (not the founder)'
    return 'FOUNDER'

for f in files:
    print('#### transcript', f)
    for line in open(f, errors='replace'):
        try: e = json.loads(line)
        except Exception: continue
        ts = e.get('timestamp', '')
        if ts and not (lo <= ts <= hi): continue
        t = e.get('type'); m = e.get('message') or {}
        c = m.get('content') if isinstance(m, dict) else None
        if t == 'user' and not e.get('isMeta'):
            if isinstance(c, list) and any(isinstance(b, dict) and b.get('type') == 'tool_result' for b in c): continue
            text = c if isinstance(c, str) else '\n'.join(b.get('text', '') for b in (c or []) if isinstance(b, dict) and b.get('type') == 'text')
            text = strip.sub('', text or '').strip()
            if text: print(f'\n=== {who(text)} {ts}\n{text}')
        elif t == 'queue-operation' and e.get('operation') == 'enqueue' and isinstance(e.get('content'), str):
            t = strip.sub("", e["content"]).strip()
            print(f'\n=== {who(t)} (mid-turn) {ts}\n{t}')
        elif t == 'assistant' and isinstance(c, list):
            for b in c:
                if not isinstance(b, dict): continue
                if b.get('type') == 'text' and b.get('text', '').strip():
                    print(f'\n--- AGENT {ts}\n{b["text"].strip()}')
                elif tools and b.get('type') == 'tool_use':
                    i = b.get('input') or {}
                    desc = i.get('description') or i.get('file_path') or i.get('command', '')[:160] or i.get('prompt', '')[:160] or ''
                    print(f'  [tool {b.get("name")}] {str(desc)[:200]}')
