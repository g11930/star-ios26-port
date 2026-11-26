#!/bin/bash
# 深挖 s205-cur.bin：Event latency 分布、渲染合成相关行、锁屏/HomeGrabberView
python3 - <<'PY'
import re
from collections import Counter
d = open('/mnt/c/ios26/s205-cur.bin','rb').read().decode('utf-8','replace').replace('\0','')
lines = d.split('\n')

# 1. Event latency 分布（纳秒）
lats = [int(x) for x in re.findall(r'Event latency:(\d+)', d)]
print('== Event latency ==')
print('count=%d' % len(lats))
if lats:
    lats_s = sorted(x/1e9 for x in lats)
    import statistics
    print('min=%.3fs median=%.3fs max=%.3fs' % (lats_s[0], statistics.median(lats_s), lats_s[-1]))
    # 按秒分组计数
    c = Counter()
    for x in lats_s:
        c['%.1f-%.1f' % (int(x), int(x)+1)] += 1
    print('分布(秒区间):', dict(sorted(c.items())))

# 2. latency 行来源进程
procs = Counter()
for l in lines:
    m = re.search(r'Event latency:\d+', l)
    if m:
        procs[l.split('|')[0].split('[')[0].strip()] += 1
print('latency 来源进程:', dict(procs))

# 3. 渲染/合成/帧相关行（03:22 批次）
print('== 渲染/合成相关 ==')
for kw in ['MiniIOMobileFramebuffer','swap','present','composite','Frame','frame','VSync','vsync','Timer delayed','dirty','render']:
    hits = [l for l in lines if kw.lower() in l.lower() and '2025-12-10 03:22' in l]
    if hits:
        print('[%s] %d hits, 样例:' % (kw, len(hits)))
        for l in hits[:2]: print('   ', l[:170])

# 4. 锁屏 / HomeGrabberView / AttentionAwareness
print('== 界面状态 ==')
hg = Counter()
for l in lines:
    m = re.search(r'HomeGrabberView-(\d+)', l)
    if m: hg[m.group(1)] += 1
print('HomeGrabberView 出现:', dict(hg))
print('AttentionAwareness notify:', len(re.findall(r'AttentionAwareness.*notify', d)))
print('Dropping clientEvent:', len(re.findall(r'Dropping.*clientEvent', d)))
print('Dropping clientState:', len(re.findall(r'Dropping.*clientState', d)))

# 5. 03:22 批次进程分布
procs22 = Counter()
for l in lines:
    if '2025-12-10 03:22' in l:
        p = l.split('[')[0].strip()
        procs22[p] += 1
print('03:22 批次进程分布 top:', dict(procs22.most_common(12)))
PY
