#!/usr/bin/env python3
"""Compare original cache files vs rewrite report sizes."""
import json
from pathlib import Path

rep = json.loads(Path('/root/dsc26_work/rewrite-report.json').read_text())
print('schema:', rep.get('schema'), 'page_shift:', rep.get('page_shift'))
print('files in report:', len(rep['files']))
orig_dir = Path('/root/dsc26/System/Library/Caches/com.apple.dyld')
files = sorted(f for f in orig_dir.iterdir() if f.is_file())
print('files on disk:', len(files))
by_name = {f['name']: f for f in rep['files']}
grow = 0
grew, shrank = [], []
for f in files:
    r = by_name.get(f.name)
    o = f.stat().st_size
    if r is None:
        print(f'  NOT-IN-REPORT {f.name} {o}')
        continue
    new = r.get('size', r.get('output_size'))
    if new is None:
        keys = list(r.keys())
        print('  report keys sample:', keys[:14])
        break
    delta = new - o
    grow += delta
    if delta > 0:
        grew.append((f.name, o, new))
    elif delta < 0:
        shrank.append((f.name, o, new))
else:
    print(f'total growth: {grow} bytes')
    print('grew:', len(grew), 'top5:', [(n, o, nw) for n, o, nw in sorted(grew, key=lambda x: -x[2]+x[1])[:5]])
    print('shrank:', len(shrank), shrank[:3])
