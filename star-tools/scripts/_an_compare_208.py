import re,glob,os
files={
 's208(能进桌面)':r"C:/ios26/s208-rollback-live2.bin",
 's212(卡住)':r"C:/ios26/now-042536.bin",
 's205(能进桌面)':r"C:/ios26/s205-boot.bin",
}
keys=['MiniAppleKeyStore','selector 0x2b not implemented','Failed to bump UIK','Failed to commit UIK',
      'unlockedEnvironmentMode','SystemShell] activate','activation_installed','MKB_INIT',
      'keybagd','Failed to perform system key','not a platform binary']
for name,p in files.items():
    if not os.path.exists(p): print(f"\n### {name}: NOT FOUND ({p})"); continue
    d=open(p,'rb').read().decode('utf-8','replace').replace('\x00',''); L=d.splitlines()
    print(f"\n### {name}: {os.path.getsize(p)}B {len(L)}行")
    for k in keys:
        c=sum(1 for l in L if k in l)
        if c: print(f"  {k}: {c}")
