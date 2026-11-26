import re, os
files=['C:/ios26/now-032636.bin','C:/ios26/now-032817.bin']
for p in files:
    if not os.path.exists(p):
        print(p,'MISSING'); continue
    d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
    L=d.splitlines()
    print("="*24, os.path.basename(p), "lines",len(L), "="*24)
    hits=[(i,l.strip()) for i,l in enumerate(L) if 'pac:' in l.lower()]
    print("total pac: lines:", len(hits))
    print("--- first 40 verbatim ---")
    for i,l in hits[:40]:
        print(f"  [{i}] {l[:220]}")
    print("--- last 12 verbatim ---")
    for i,l in hits[-12:]:
        print(f"  [{i}] {l[:220]}")
    print()
