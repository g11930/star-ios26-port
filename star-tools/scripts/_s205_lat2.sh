#!/bin/bash
python3 - <<'PY'
import re
d = open('/mnt/c/ios26/s205-cur.bin','rb').read().decode('utf-8','replace').replace('\0','')
lines = d.split('\n')

# 1. 完整 cmdline
print('== 完整 cmdline ==')
for l in lines:
    if 'cmdline:' in l:
        # 打印完整
        print(l)
        break

# 2. 各类行计数（整个日志）
print('== 全日志关键字计数 ==')
for kw in ['Timer delayed','P34','MiniIOMobileFramebuffer','swap','Event latency',
           'star_display','tl: v','tl: c','ktrace','kernel','panic','hang','stall',
           'IOAccelerator','fence','present','vsync','VSync','display']:
    cnt = sum(1 for l in lines if kw.lower() in l.lower())
    if cnt: print('%-22s %d' % (kw, cnt))

# 3. Timer delayed 分布
delays = [float(x) for x in re.findall(r'Timer delayed by ([\d.]+)s', d)]
print('Timer delayed: count=%d' % len(delays), sorted(delays, reverse=True)[:10] if delays else '')

# 4. Event latency 的 type 分布
types = {}
for l in lines:
    m = re.search(r'Event latency:\d+ type:(\d+)', l)
    if m:
        types[m.group(1)] = types.get(m.group(1), 0) + 1
print('Event latency type 分布:', types)

# 5. 03:22 批次里 backboardd 行按子模块分类
mods = {}
for l in lines:
    if '2025-12-10 03:22' in l and 'backboardd' in l:
        m = re.search(r'backboardd\[\d+:\d+\] \[([^\]]+)\]', l)
        if m:
            mods[m.group(1)] = mods.get(m.group(1), 0) + 1
print('backboardd 子模块分布:', sorted(mods.items(), key=lambda x:-x[1])[:15])

# 6. Event latency 前后行：看延迟行附近上下文，判断是哪个连接/客户端
print('== Event latency 上下文样例 ==')
idx = [i for i,l in enumerate(lines) if 'Event latency:' in l]
if idx:
    i = idx[0]
    for j in range(max(0,i-3), min(len(lines), i+4)):
        print(lines[j][:200])
PY
