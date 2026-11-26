import os
files={
 's208(进桌面)':r"C:/ios26/s208-now.bin",
 's212(929KB)':r"C:/ios26/now-041052.bin",
 's212(1.3MB)':r"C:/ios26/now-042536.bin",
}
keys=['sb26: unlock','unlock boot','unlock notification','boot unlock','cover sheet','CoverSheet',
      '_appearState','isUILocked','lacks isUILocked','autounlock!=','not locked',
      'unlockUIFromSource:','unlockedEnvironmentMode']
for name,p in files.items():
    if not os.path.exists(p): continue
    d=open(p,'rb').read().decode('utf-8','replace').replace('\x00','')
    L=d.splitlines()
    print(f"\n### {name}")
    for k in keys:
        hits=[(i,l.strip()) for i,l in enumerate(L) if k in l]
        if hits:
            print(f"  [{len(hits)}] {k}")
            for i,l in hits[:3]: print(f"       [{i}] {l[:190]}")
