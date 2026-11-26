#!/usr/bin/env python3
import re, sys, collections

TS = re.compile(r'^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+)\+\d{4} ([A-Za-z0-9_.\-]+)\[(\d+):')

def parse(path):
    rows = []
    with open(path, 'rb') as f:
        data = f.read().decode('utf-8', 'ignore')
    for line in data.split('\n'):
        m = TS.match(line)
        if m:
            rows.append((m.group(1), m.group(2), int(m.group(3), 10)))
    return rows

def ts_sec(t):
    import datetime
    d = datetime.datetime.strptime(t[:23], '%Y-%m-%d %H:%M:%S.%f')
    return d.timestamp()

for path in sys.argv[1:]:
    rows = parse(path)
    print('==', path, 'lines', len(rows))
    if not rows:
        continue
    t0 = ts_sec(rows[0][0]); t1 = ts_sec(rows[-1][0])
    print('   span %.1f s (%s -> %s)' % (t1 - t0, rows[0][0][11:], rows[-1][0][11:]))
    first = {}
    for t, name, pid in rows:
        first.setdefault(name, (t, pid))
    for name in ('launchd', 'backboardd', 'SpringBoard', 'iconservicesagent',
                 'MTLCompilerService', 'runningboardd'):
        if name in first:
            print('   first %-22s %+.1f s  pid %d' % (name, ts_sec(first[name][0]) - t0, first[name][1]))
    counts = collections.Counter(name for _, name, _ in rows)
    print('   busiest:', ', '.join('%s %d' % kv for kv in counts.most_common(6)))
