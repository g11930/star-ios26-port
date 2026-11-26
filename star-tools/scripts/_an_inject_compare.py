import os
files={
 's208(进桌面)':r"C:/ios26/s208-now.bin",
 's212(卡激活)':r"C:/ios26/now-042536.bin",
 's212(929KB)':r"C:/ios26/now-041052.bin",
}
keys=['sb26:','activation_installed','_setupActivationState','validate ','build=23G90',
      'libannibale','SBLockdownManager','discovery_image','inject','sb26_install',
      'unlock notification','unlockUI','autounlock','non-platform','unexpected exec']
for name,p in files.items():
    if not os.path.exists(p):
        print(f"\n### {name}: NOT FOUND"); continue
    d=open(p,'rb').read().decode('utf-8','replace').replace('\x00','')
    L=d.splitlines()
    print(f"\n### {name}: {os.path.getsize(p)}B {len(L)}行")
    for k in keys:
        hits=[(i,l.strip()) for i,l in enumerate(L) if k in l]
        if hits:
            print(f"  {k}: {len(hits)}")
            for i,l in hits[:3]: print(f"      [{i}] {l[:210]}")
