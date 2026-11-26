import os
files={
 's208(进桌面)':r"C:/ios26/s208-now.bin",
 's212(卡929KB)':r"C:/ios26/now-041052.bin",
 's212(卡1.3MB)':r"C:/ios26/now-042536.bin",
}
# 解锁相关 + 进桌面 marker
keys=['unlockUIFromSource:','com.annibale.unlock','unlock notification','boot_unlock',
      'sb26: unlock','isUILocked','SystemShell] activate','unlockedEnvironmentMode',
      'UserInteractiveFocal','activation_installed=1','auto unlock','autounlock',
      'SBApplicationController','iconfill','springboardd']
for name,p in files.items():
    if not os.path.exists(p): print(f"\n### {name}: NOT FOUND"); continue
    d=open(p,'rb').read().decode('utf-8','replace').replace('\x00','')
    L=d.splitlines()
    print(f"\n### {name}: {os.path.getsize(p)}B {len(L)}行")
    for k in keys:
        hits=[(i,l.strip()) for i,l in enumerate(L) if k in l]
        if hits:
            print(f"  {k}: {len(hits)}")
            for i,l in hits[:2]: print(f"      [{i}] {l[:200]}")
