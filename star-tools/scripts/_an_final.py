p='C:/ios26/now-032636.bin'
d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
L=d.splitlines()
print("######## MiniIOMobileFramebuffer / flip 上下文 (行 88..108) ########")
for i in range(88,109):
    print(f"[{i}] {L[i].strip()[:200]}")
print()
print("######## userspace 显示 / 桌面 / 激活 ########")
for kw in ['Setup Assistant','SetupAssistant','activation','Activation','makeKeyAndVisible',
           'makeKey','makeVisible','setNeedsDisplay','CAWindow','UIWindow','window:','SpringBoard:','SBApplication',
           'splashboard','SplashBoard','lockscreen','LockScreen','home screen','HomeScreen','FBDisplay','display:']:
    hits=[(i,l.strip()) for i,l in enumerate(L) if kw in l]
    if hits:
        print(f"--- {kw} ({len(hits)}) ---")
        for i,l in hits[:4]: print(f"  [{i}] {l[:165]}")
print()
print("######## kernel VA / display ownership ########")
for kw in ['scan-out','owner=loader','does NOT clear','cont_splash_region','handoff base','vc_initialize']:
    for i,l in enumerate(L):
        if kw in l: print(f"  [{i}] {l.strip()[:220]}")
print()
print("######## backboardd / SpringBoard 最后状态 ########")
for i,l in enumerate(L):
    s=l.strip()
    if ('backboardd[' in s or 'SpringBoard[' in s) and i>12000:
        if any(k in s for k in ['display','Display','surface','Surface','window','Window','render','Render','connect','activate','Boot','boot']):
            print(f"  [{i}] {s[:180]}")
