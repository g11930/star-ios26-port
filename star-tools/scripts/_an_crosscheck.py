import re, os

def pages_of(p, limit=30):
    if not os.path.exists(p): return []
    d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
    out=[]
    for l in d.splitlines():
        m=re.search(r'pac: page (0x[0-9a-f]+)',l)
        if m: out.append(int(m.group(1),16))
        if len(out)>=limit: break
    return out

for name in ['s210-alive210.bin','s211-now.bin','now-032817.bin']:
    p='C:/ios26/'+name
    pg=pages_of(p)
    buckets={}
    for a in pg:
        hi=a>>32
        buckets[hi]=buckets.get(hi,0)+1
    print(f"{name}: {len(pg)} pages, hi32 dist = { {hex(k):v for k,v in sorted(buckets.items())} }")
    print("   sample:", [hex(a) for a in pg[:6]])
print()

# dyld shared cache 地址线索
p='C:/ios26/now-032817.bin'
d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
L=d.splitlines()
print("=== dyld shared cache / mapping 基址 ===")
for kw in ['dyld_shared_cache','shared cache','SharedCache','dyld-','DyldSharedCache',
           'mapping','0x19','0x1a','0x2b','__TEXT','text segment']:
    hits=[(i,l.strip()) for i,l in enumerate(L) if kw in l]
    if hits:
        print(f"--- {kw} ({len(hits)}) ---")
        for i,l in hits[:4]: print(f"  [{i}] {l[:170]}")

# s210 vs s211 trap 累计对比（同时间点附近）
print()
print("=== trap 累计对比 ===")
for name in ['s210-alive210.bin','s211-now.bin','now-032817.bin']:
    p='C:/ios26/'+name
    if not os.path.exists(p): continue
    d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
    tr=[int(m.group(1)) for l in d.splitlines() for m in [re.search(r'pac: traps=(\d+)',l)] if m]
    pg=[int(m.group(1)) for l in d.splitlines() for m in [re.search(r'traps=\d+ pages=(\d+)',l)] if m]
    print(f"  {name}: traps last={tr[-1] if tr else 0} pages last={pg[-1] if pg else 0}")
