p='C:/ios26/now-032636.bin'
d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
L=d.splitlines()
print("######## [110..140] handoff / milestone 区块 ########")
for i in range(108,142):
    if i<len(L): print(f"[{i}] {L[i].strip()[:200]}")
print()
print("######## 全部 STARL star_display 相关 ########")
for i,l in enumerate(L):
    if 'STARL' in l or ('star_display' in l):
        print(f"[{i}] {l.strip()[:230]}")
print()
print("######## present / scanout / swap / vsync / flip 关键词 ########")
for kw in ['present','Present','scanout','scan-out','swap','Swap','vsync','VSync','flip','Flip','page_flip','commit','Commit','IOFramebuffer','IODisplay','displayWrangler','DCP','dcp']:
    hits=[(i,l.strip()) for i,l in enumerate(L) if kw in l]
    if hits:
        print(f"--- {kw} ({len(hits)}) ---")
        for i,l in hits[:6]: print(f"  [{i}] {l[:170]}")
print()
print("######## triangle 相关（GPU app 是否在画并为谁画） ########")
hits=[(i,l.strip()) for i,l in enumerate(L) if 'triangle' in l.lower()]
for i,l in hits[:40]: print(f"  [{i}] {l[:200]}")
