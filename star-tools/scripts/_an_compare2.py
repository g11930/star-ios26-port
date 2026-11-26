import os,re,glob
# 找 s208 进桌面的日志
cands=glob.glob(r"C:/ios26/s208*.bin")+glob.glob(r"C:/ios26/now-04*.bin")
print("候选:",[os.path.basename(x) for x in cands])
files={'s208-now(进桌面)':r"C:/ios26/s208-now.bin",'s212-最新(卡住)':r"C:/ios26/now-042536.bin"}
keys=['MiniAppleKeyStore','selector 0x2b','Failed to bump UIK','Failed to commit UIK',
 'unlockedEnvironmentMode','SystemShell] activate','activation_installed','MKB_INIT','keybagd',
 'Failed to perform system key','AMFDRDataApTicket','Unable to read AP Ticket','effective-security-mode']
for name,p in files.items():
    if not os.path.exists(p): print(f"\n### {name}: NOT FOUND"); continue
    d=open(p,'rb').read().decode('utf-8','replace').replace('\x00',''); L=d.splitlines()
    print(f"\n### {name}: {os.path.getsize(p)}B {len(L)}行")
    for k in keys:
        c=sum(1 for l in L if k in l)
        if c: print(f"  {k}: {c}")
    # MKB_INIT 上下文
    mk=[(i,l.strip()) for i,l in enumerate(L) if 'MKB_INIT' in l]
    if mk:
        print("  MKB_INIT 首末:")
        for i,l in mk[:2]+mk[-2:]: print(f"    [{i}] {l[:170]}")
