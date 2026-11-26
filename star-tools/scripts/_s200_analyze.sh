#!/bin/bash
# s200 分析：把 fb_diff 的每帧变化像素数与 tl: 时间线对齐。
R=/root/star26/star26-analyze-s200
OUT=/mnt/c/ios26
python3 - "$OUT" <<'PY'
import sys, glob, re, os
out = sys.argv[1]
files = sorted(glob.glob(os.path.join(out, 's200mon-*.bin')),
               key=lambda p: int(re.search(r'-(\d+)\.bin', p).group(1)))

def load(f):
    return open(f, 'rb').read().decode('utf-8', 'replace').replace('\0', '')

print('=== per-snapshot summary ===')
for f in files:
    d = load(f)
    ts = re.findall(r'\d{4}-\d\d-\d\d \d\d:\d\d:\d\d', d)
    diffs = re.findall(r'(\d+) pixels of the panel changed a frame, all within (\d+),(\d+) to (\d+),(\d+)', d)
    frames = re.findall(r'(\d+) frames in (\d+) ms', d)
    print('%-16s %6d B  last=%s  tl_s=%-3d tl_v=%-3d diff=%-2d frames=%-2d' % (
        os.path.basename(f), len(d.encode()), ts[-1] if ts else '-',
        d.count('tl: s '), d.count('tl: v '), len(diffs), len(frames)))

print()
print('=== every diff line, in order ===')
seen = []
for f in files:
    d = load(f)
    for m in re.finditer(r'(\d+) pixels of the panel changed a frame, all within (\d+),(\d+) to (\d+),(\d+)', d):
        seen.append(m.groups())
if not seen:
    print('  (none)')
else:
    ded = []
    for g in seen:
        if not ded or ded[-1] != g:
            ded.append(g)
    for g in ded:
        print('  %8s px changed, box %s,%s .. %s,%s' % g)
    vals = [int(g[0]) for g in ded]
    print('  --- min %d  max %d  last %d  of a 1440x3200=%d panel ---' % (
        min(vals), max(vals), vals[-1], 1440*3200))

print()
print('=== tl: s (swap handed to the kernel) ===')
seen = []
for f in files:
    d = load(f)
    for l in d.split('\n'):
        if ' tl: s ' in ' ' + l or l.strip().startswith('tl: s '):
            s = l.strip()
            if not seen or seen[-1] != s:
                seen.append(s)
for s in seen[-25:]:
    print(' ', s[:170])
print('  total distinct', len(seen))

print()
print('=== frames-in stat lines ===')
seen = []
for f in files:
    d = load(f)
    for l in d.split('\n'):
        if re.search(r'\d+ frames in \d+ ms', l):
            s = l.strip()
            if not seen or seen[-1] != s:
                seen.append(s)
for s in seen[-8:]:
    print(' ', s[:290])

print()
print('=== P34 pairs (surface vs panel) ===')
seen = []
for f in files:
    d = load(f)
    for l in d.split('\n'):
        if l.strip().startswith('P34:'):
            s = l.strip()
            if not seen or seen[-1] != s:
                seen.append(s)
for s in seen[-10:]:
    print(' ', s[:200])
PY
