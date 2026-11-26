#!/bin/bash
# 分析 s199 采样：tl: s / tl: v / tl: l / milestone: first_frame 的时间线
cd /mnt/c/ios26 || exit 1
python3 - <<'PY'
import glob, re, collections

files = sorted(glob.glob('s199mon-*.bin'), key=lambda p: int(re.search(r'-(\d+)\.bin', p).group(1)))
if not files:
    print('no samples yet'); raise SystemExit

subs, vers, lats, stats, miles = {}, {}, {}, [], []
for f in files:
    d = open(f, 'rb').read().decode('utf-8', 'replace').replace(chr(0), '')
    for l in d.split('\n'):
        s = l.strip()
        m = re.search(r'tl: s (\d+) (-?\d+) (\d+) (\S+) at (\d+)', s)
        if m:
            subs[int(m.group(5))] = (m.group(1), int(m.group(2)), m.group(4)); continue
        m = re.search(r'tl: v (\d+) ready (\d+) shown (\d+) done (\d+)', s)
        if m:
            vers[int(m.group(1))] = tuple(int(m.group(i)) for i in (2, 3, 4)); continue
        m = re.search(r'tl: l (\d+) at (\d+) frame (\d+)', s)
        if m:
            lats[int(m.group(1))] = (int(m.group(2)), int(m.group(3))); continue
        if 'milestone: first_frame' in s:
            miles.append(s[:150]); continue
        if 'frames in ' in s:
            stats.append(s[:160])

print('samples: %d  (%s .. %s)' % (len(files), files[0], files[-1]))
print()
print('=== milestone: first_frame ===')
if miles:
    for m in dict.fromkeys(miles): print('  ', m)
else:
    print('   NONE  <-- 首帧根本没画进面板')
print()
print('=== tl: s  (用户态交来的 swap)  count=%d ===' % len(subs))
if subs:
    ts = sorted(subs)
    print('  提交者:', dict(collections.Counter(subs[t][2] for t in ts)))
    print('  首次 %.2f s  末次 %.2f s  跨度 %.1f s' % (ts[0]/1e6, ts[-1]/1e6, (ts[-1]-ts[0])/1e6))
    print('  --- 时间线抽样 ---')
    step = max(1, len(ts)//15)
    for t in ts[::step]:
        sid, pid, who = subs[t]
        print('    at %9.2f s  swap %-5s pid %-5d %s' % (t/1e6, sid, pid, who))
    print('  --- 最后 10 个 ---')
    for t in ts[-10:]:
        sid, pid, who = subs[t]
        print('    at %9.2f s  swap %-5s pid %-5d %s' % (t/1e6, sid, pid, who))
print()
print('=== tl: v  (presenter 画进面板)  count=%d ===' % len(vers))
for sid in sorted(vers)[-8:]:
    r, s2, dn = vers[sid]
    print('    swap %-5s ready %d  shown %d  done %d us' % (sid, r, s2, dn))
print()
print('=== tl: l  (面板翻页)  count=%d ===' % len(lats))
for sid in sorted(lats)[-8:]:
    at, fr = lats[sid]
    print('    swap %-5s at %d frame %d' % (sid, at, fr))
print()
print('=== frames-in 统计行 (%d) ===' % len(stats))
for s in list(dict.fromkeys(stats))[-8:]:
    print('   ', s)
PY
