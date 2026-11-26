#!/usr/bin/env python3
import re, sys, datetime

TS = re.compile(r'^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{6})\+\d{4} ([A-Za-z0-9_.\-]+)')

def rows(path):
    out = []
    for line in open(path, 'rb').read().decode('utf-8', 'ignore').split('\n'):
        m = TS.match(line)
        if m:
            t = datetime.datetime.strptime(m.group(1), '%Y-%m-%d %H:%M:%S.%f')
            out.append((t, m.group(2), line))
    return out

path = sys.argv[1]
r = rows(path)
print('==', path, 'lines', len(r))
gaps = []
for (a, _, _), (b, n2, _) in zip(r, r[1:]):
    d = (b - a).total_seconds()
    if d >= 1.0:
        gaps.append((d, a.strftime('%H:%M:%S'), n2))
gaps.sort(reverse=True)
print('total idle (>=1s gaps): %.1f s over %d gaps' % (sum(g[0] for g in gaps), len(gaps)))
for d, at, who in gaps[:12]:
    print('   %5.1f s idle ending %s next %s' % (d, at, who))
