import sys, os
for name in ['now-032636.bin','now-032817.bin']:
    p='C:/ios26/'+name
    if not os.path.exists(p):
        print(name,"MISSING"); continue
    d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
    L=d.splitlines()
    print("="*20,name,"lines",len(L),"="*20)
    for kw in ['panic(','panic:','PANIC','non-platform binary','haltRestart','haltAndRestart',
               'userspace panic','KERNEL FAULT','fastboot','boot fallback','kernel returned with log status',
               'unexpected exec']:
        hits=[(i,l.strip()) for i,l in enumerate(L) if kw in l]
        print(f"  {kw}: {len(hits)}")
        for i,l in hits[:4]:
            print(f"      [{i}] {l[:200]}")
    print()
