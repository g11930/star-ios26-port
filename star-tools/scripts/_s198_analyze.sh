#!/bin/bash
# 分析 s198 采样：tl: s / tl: v / tl: l 的时间线与频率
cd /mnt/c/ios26 || exit 1
python3 - <<'PY'
import glob, re, os, collections

files = sorted(glob.glob('s198mon-*.bin'), key=lambda p: int(re.search(r'-(\d+)\.bin', p).group(1)))
if not files:
    print('no samples yet'); raise SystemExit

subs = {}   # (id) -> (pid, name, at)
vers = {}
lats = {}
stats = []
boot = None

for f in files:
    d = open(f, 'rb').read().decode('utf-8', 'replace').replace(chr(0), '')
    for l in d.split('\n'):
        s = l.strip()
        m = re.search(r'tl: s (\d+) (-?\d+) (\d+) (\S+) at (\d+)', s)
        if m:
            sid, pid, tid, who, at = m.group(1), int(m.group(2)), m.group(3), m.group(4), int(m.group(5))
            subs[at] = (sid, pid, who)
            continue
        m = re.search(r'tl: v (\d+) ready (\d+) shown (\d+) done (\d+)', s)
        if m:
            vers[int(m.group(1))] = (int(m.group(2)), int(m.group(3)), int(m.group(4)))
            continue
        m = re.search(r'tl: l (\d+) at (\d+) frame (\d+)', s)
        if m:
            lats[int(m.group(1))] = (int(m.group(2)), int(m.group(3)))
            continue
        if 'frames in ' in s:
            stats.append(s[:150])

print('samples: %d  (%s .. %s)' % (len(files), files[0], files[-1]))
print()
print('=== tl: s  (用户态交来的 swap) ===')
print('  distinct swaps: %d' % len(subs))
if subs:
    ts = sorted(subs)
    per = collections.Counter(subs[t][2] for t in ts)
    print('  提交者:', dict(per))
    print('  首次 at %.1f s, 末次 at %.1f s, 跨度 %.1f s' % (ts[0]/1e6, ts[-1]/1e6, (ts[-1]-ts[0])/1e6))
    # 每 20 个打印一次，看频率
    print('  --- 时间线（每 20 个取一个）---')
    for i in range(0, len(ts), max(1, len(ts)//20)):
        t = ts[i]
        sid, pid, who = subs[t]
        print('    at %10.2f s  swap %-5s pid %-4d %s' % (t/1e6, sid, pid, who))
    print('  --- 最后 12 个 ---')
    for t in ts[-12:]:
        sid, pid, who = subs[t]
        print('    at %10.2f s  swap %-5s pid %-4d %s' % (t/1e6, sid, pid, who))

print()
print('=== tl: v  (presenter 画进面板) ===')
print('  count: %d' % len(vers))
for sid in sorted(vers)[-6:]:
    r, s, dn = vers[sid]
    print('    swap %-5s ready %d shown %d done %d us' % (sid, r, s, dn))

print()
print('=== tl: l  (面板翻页被观察) ===')
print('  count: %d' % len(lats))
for sid in sorted(lats)[-6:]:
    at, fr = lats[sid]
    print('    swap %-5s at %d frame %d' % (sid, at, fr))

print()
print('=== frames-in 统计行 (%d) ===' % len(stats))
for s in stats[-6:]:
    print('   ', s)
PY
