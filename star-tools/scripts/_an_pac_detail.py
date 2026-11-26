import re, os
p='C:/ios26/now-032817.bin'
d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
L=d.splitlines()

def is_stat(s): return 'pac: traps=' in s

# 1) 单页改写日志（排除统计行）
single=[(i,l.strip()) for i,l in enumerate(L) if 'pac:' in l.lower() and not is_stat(l)]
print("=== 单页 pac: 日志 (非统计行) 共 %d 条 ===" % len(single))
for i,l in single[:60]:
    print(f"  [{i}] {l[:230]}")
print()

# 2) 统计行里 pages 从 0 到非零的转折点 + FIPS/关键事件的行号
stats=[(i,l.strip()) for i,l in enumerate(L) if is_stat(l)]
print("=== 统计行 pages 首次非零 ===")
for i,l in stats:
    m=re.search(r'pages=(\d+)',l)
    if m and int(m.group(1))>0:
        print(f"  [{i}] {l[:180]}")
        break
print("统计行总数:",len(stats),"| 最后:",stats[-1][1][:180] if stats else '-')
print()

# 3) 关键事件行号
keys=['FIPSPOST','About to call the FIPS_POST','Returned from calling the FIPS_POST',
      'fipspost_post_integrity','pac: gate','pac gate','pac: fips','FIPS gate',
      'mount-phase-2','unexpected exec','exec of non-platform','PXBEXIT','haltRestart']
for k in keys:
    hits=[(i,l.strip()) for i,l in enumerate(L) if k in l]
    if hits:
        print(f"--- {k} ({len(hits)}) ---")
        for i,l in hits[:6]: print(f"  [{i}] {l[:190]}")
print()

# 4) 页改写关键词（可能带 vm/pmap/proc 名）
for kw in ['page at','patch page','pac_patch','patches in','pac: patched','wrote','instrs in','owner=','vm_map','proc:','code dir','cdhash','platform']:
    hits=[(i,l.strip()) for i,l in enumerate(L) if kw in l.lower()]
    if hits:
        print(f"=== {kw} ({len(hits)}) ===")
        for i,l in hits[:8]: print(f"  [{i}] {l[:190]}")
