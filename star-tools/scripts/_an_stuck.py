import re,os,glob
p=r"C:/ios26/now-042536.bin"; d=open(p,'rb').read().decode('utf-8','replace').replace('\x00','')
L=d.splitlines(); print("=== FILE:",os.path.basename(p),"size",os.path.getsize(p),"lines",len(L))
# 崩溃判据
print("\n--- 崩溃判据 ---")
for kw in ['non-platform','userspace panic','PANIC','KERNEL FAULT','haltRestart','BOOT FALLBACK','panic(','watchdog','hang','deadlock']:
    c=sum(1 for l in L if kw in l)
    if c: print(f"  {kw}: {c}")
# 最后 25 行原文
print("\n--- 最后 25 行 ---")
for l in L[-25:]: print("  "+l.strip()[:200])
# 带时间戳的最后 15 条
tl=[(i,l.strip()) for i,l in enumerate(L) if re.search(r'2025-12-10 \d\d:\d\d:\d\d',l)]
print("\n--- 最后 15 条带时间戳 (index) ---")
for i,l in tl[-15:]: print(f"  [{i}] {l[:190]}")
# 时间跨度
if tl:
    print(f"\n时间线: 首={tl[0][1][:25]} 末={tl[-1][1][:25]}")
# 进程活动统计：最后 3000 行里哪些进程还在打日志
print("\n--- 最后 3000 行进程活跃度 ---")
tail=L[-3000:]
from collections import Counter
c=Counter()
for l in tail:
    m=re.search(r'\b([A-Za-z][A-Za-z0-9_.\-]{2,30})\[\d+:',l)
    if m: c[m.group(1)]+=1
for k,v in c.most_common(20): print(f"  {k}: {v}")
