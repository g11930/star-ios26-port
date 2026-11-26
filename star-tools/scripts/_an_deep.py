import re,os
def load(p): return open(p,'rb').read().decode('utf-8','replace').replace('\x00','').splitlines()
L=load(r"C:/ios26/now-042536.bin")
print("### 1) watchdog / hang 原文 ###")
for i,l in enumerate(L):
    if re.search(r'watchdog|\bhang\b|hung',l,re.I):
        print(f"  [{i}] {l.strip()[:220]}")
print("\n### 2) mobileactivationd 全部 ###")
for i,l in enumerate(L):
    if 'mobileactivationd' in l or 'activation' in l.lower() and re.search(r'mobile|device|状态|state',l):
        print(f"  [{i}] {l.strip()[:220]}")
print("\n### 3) appprotectiond fetching 计数与首末 ###")
h=[(i,l.strip()) for i,l in enumerate(L) if 'fetching all bundles' in l]
print("  count=",len(h))
for i,l in h[:3]+h[-3:]: print(f"  [{i}] {l[:200]}")
print("\n### 4) 解锁/激活/Setup 相关 marker ###")
for kw in ['unlocked','unlock','Setup Assistant','setupassistant','activation','Data Migration','migration','persona','UserInteractive','SystemShell','launchd_unsecure','autounlock','keybag','MKB','data protection','dataprotection']:
    c=sum(1 for l in L if kw.lower() in l.lower())
    if c: print(f"  {kw}: {c}")
print("\n### 5) kbd (最活跃进程) 在打什么 ###")
k=[l.strip() for l in L if re.search(r'\bkbd\[',l)]
for l in k[:8]: print("  "+l[:200])
