"""The pilot's recount: a canonical founder-turn table from the pilot's corrected records.

Each exchange row is matched to the real prompt in prompts.tsv (same session,
nearest timestamp within 90 s, seconds taken from the row when it has them).
Rows that match no indexed prompt (question-tool answers, queued attachments)
fall back to session + minute. One vote per episode per turn."""
import json, re, sys, collections
from datetime import datetime, timedelta
# usage: turns.py <records.jsonl> <prompts.tsv> <turns-out.json>
records_path, prompts_path, out_path = sys.argv[1:4]
d = {'records': [json.loads(l) for l in open(records_path) if not l.startswith('{"meta"')]}
P = collections.defaultdict(list)
for line in open(prompts_path):
    ts, sid, wt, br, n, org, text = line.rstrip('\n').split('\t', 6)
    try: t = datetime.strptime(ts[:19], '%Y-%m-%dT%H:%M:%S')
    except ValueError: continue
    P[sid[:8]].append((t, int(n), ts[:19], org))
def parse(x):
    blob = x['when'] + ' ' + x['source']
    sid = re.search(r'\b([0-9a-f]{8})\b', x['source'] + ' ' + x['when'])
    date = re.search(r'(\d{4}-\d{2}-\d{2})', x['when']) or re.search(r'(\d{4}-\d{2}-\d{2})', x['source'])
    hms = re.findall(r'(\d{2}):(\d{2})(?::(\d{2}))?', x['when'])
    src_hms = re.findall(r'(\d{2}):(\d{2}):(\d{2})', x['source'])
    if not (sid and date and hms): return None, None, False
    h, m, s = hms[0]
    exact = bool(s)
    if not s and src_hms and src_hms[0][:2] == (h, m): s, exact = src_hms[0][2], True
    t = datetime.strptime(f'{date.group(1)}T{h}:{m}:{s or "30"}', '%Y-%m-%dT%H:%M:%S')
    return sid.group(1), t, exact
turns = {}          # key -> dict
votes = collections.defaultdict(lambda: collections.defaultdict(list))  # key -> ep -> kinds
unmatched = 0
for r in d['records']:
    for x in r['middle']['exchanges']:
        sid, t, exact = parse(x)
        if not sid: unmatched += 1; continue
        cands = [p for p in P.get(sid, []) if abs((p[0] - t).total_seconds()) <= (60 if exact else 90)]
        if exact: cands = [p for p in cands if abs((p[0] - t).total_seconds()) <= 60]
        if cands:
            p = min(cands, key=lambda p: abs((p[0] - t).total_seconds()))
            key, chars, when, org = sid + ' ' + p[2], p[1], p[2], p[3]
        else:
            key, chars, when, org = sid + ' ' + t.strftime('%Y-%m-%dT%H:%M') + ' (not indexed)', None, t.strftime('%Y-%m-%dT%H:%M'), 'not indexed'
        turns.setdefault(key, {'key': key, 'session': sid, 'when': when, 'chars': chars, 'origin': org, 'said': x['founder_said'][:160]})
        votes[key][r['id']].append(x['founder_turn_kind'])
L = lambda k: k.startswith('leakage')
table = []
for key, eps in votes.items():
    ev = {e: collections.Counter(ks).most_common(1)[0][0] for e, ks in eps.items()}
    n = len(ev); nl = sum(L(k) for k in ev.values()); no = sum(k == 'operational' for k in ev.values())
    row = dict(turns[key]); row.update(episodes=sorted(ev), readers=n, leak_votes=nl, op_votes=no,
        kinds=dict(collections.Counter(ev.values())),
        operational=no * 2 > n, strict_leak=nl * 2 > n, tie_leak=nl * 2 == n and nl > 0,
        unanimous_leak=nl == n, leak_kind=collections.Counter(k for k in ev.values() if L(k)).most_common(1)[0][0] if nl else '')
    table.append(row)
table.sort(key=lambda r: r['when'])
json.dump(table, open(out_path, 'w'), indent=1)
nonop = [r for r in table if not r['operational']]
print('exchange rows', sum(len(r['middle']['exchanges']) for r in d['records']), 'unparsed', unmatched)
print('distinct turns', len(table), 'operational', len(table) - len(nonop), 'non-operational', len(nonop))
print('matched to index', sum(r['chars'] is not None for r in table), 'not indexed', sum(r['chars'] is None for r in table))
sl = [r for r in nonop if r['strict_leak']]; tl = [r for r in nonop if r['tie_leak']]
print('strict-majority leakage', len(sl), f'{len(sl)/len(nonop):.0%}', '| ties', len(tl), '| unanimous with >=2 readers', sum(r['unanimous_leak'] and r['readers'] >= 2 for r in nonop), '| any leakage label', sum(r['leak_votes'] > 0 for r in nonop))
print('single-reader turns', sum(r['readers'] == 1 for r in nonop))
print('origin of non-operational turns:', dict(collections.Counter(r['origin'] for r in nonop)), '| of strict-leakage turns:', dict(collections.Counter(r['origin'] for r in sl)))
print('leak kinds (strict):', collections.Counter(r['leak_kind'] for r in sl).most_common())
# effort by characters
ch = [r for r in nonop if r['chars']]
tot = sum(r['chars'] for r in ch); lch = sum(r['chars'] for r in ch if r['strict_leak'])
print(f'chars: non-op indexed turns {len(ch)}, total {tot}, strict-leak {lch} ({lch/tot:.0%})')
top = sorted([r for r in ch if r['strict_leak']], key=lambda r: -r['chars'])[:5]
print('top leakage turns by chars:'); [print('  ', r['key'], r['chars'], r['leak_kind'], r['episodes']) for r in top]
topall = sorted(ch, key=lambda r: -r['chars'])[:8]
print('top turns by chars overall:'); [print('  ', r['key'], r['chars'], r['kinds'], r['episodes']) for r in topall]
# windows
def win(w): return 'Aug 10-15' if w < '2026-08-16' else 'Aug 16-31' if w < '2026-09-01' else 'Sep 1-15' if w < '2026-09-16' else 'Sep 16-23'
W = collections.defaultdict(lambda: [0, 0])
for r in nonop: W[win(r['when'])][1] += 1; W[win(r['when'])][0] += r['strict_leak']
print('windows:', {k: f'{a}/{b} ({a/b:.0%})' for k, (a, b) in sorted(W.items())})
# per episode, the episode's own labels, distinct turns
print('\nper episode (own labels, distinct turns): id nonop leak share leak_chars/chars')
for r in d['records']:
    seen = {}
    for x in r['middle']['exchanges']:
        pass
    mine = [t for t in table if r['id'] in t['episodes']]
    own = {}
    for t in mine:
        ks = votes[t['key']][r['id']]; own[t['key']] = collections.Counter(ks).most_common(1)[0][0]
    no = [k for k, v in own.items() if v != 'operational']
    lk = [k for k in no if L(own[k])]
    c_all = sum(turns[k]['chars'] or 0 for k in no); c_l = sum(turns[k]['chars'] or 0 for k in lk)
    print(f"{r['id']} {len(no):3d} {len(lk):3d} {len(lk)/max(1,len(no)):4.0%}  {c_l:6d}/{c_all:6d} {r['outcome']['matched_intent']:8s} {r['kind']}")
