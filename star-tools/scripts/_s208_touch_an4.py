import re,glob
ts_re=re.compile(r'(2025-12-10 [\d:]{8})')
def load(p):
    d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
    return [l.strip() for l in d.split('\n') if l.strip()]

print("=== [A] all earlier s208 captures: swap/frame/tl:s evidence ===")
for p in sorted(glob.glob('/mnt/c/ios26/s208-live*.bin'))+['/mnt/c/ios26/s208c.bin','/mnt/c/ios26/s208d.bin','/mnt/c/ios26/s208-touch1.bin','/mnt/c/ios26/s208-touch2.bin']:
    try: L=load(p)
    except Exception as e: print(p,"ERR",e); continue
    def cnt(s): return sum(1 for l in L if s in l)
    sw=[l for l in L if 'swap #' in l]; fr=[l for l in L if 'frames in' in l]; tls=[l for l in L if 'tl: s ' in l]
    allt=[m.group(1) for m in (ts_re.search(l) for l in L) if m]
    rng=f"{allt[0][11:]}->{allt[-1][11:]}" if allt else "?"
    lastsw=""
    if sw:
        t=ts_re.search(sw[-1]); lastsw=f" last swap @{t.group(1)[11:] if t else '?'}: {sw[-1][:90]}"
    print(f" {p.split('/')[-1]:24s} lines={len(L):6d} ts={rng} swap={cnt('swap #')} frin={cnt('frames in')} tls={len(tls)}{lastsw}")

print("\n=== [B] touch2 (fresh): nonzero tl: cnt + GPU activity ===")
L=load('/mnt/c/ios26/s208-touch2.bin')
nz=[l for l in L if 'tl: cnt' in l and not re.search(r'tl: cnt 0 0 0 0 0',l)]
print(" nonzero heartbeat rows:",len(nz))
for l in nz[-12:]: print("  ",l[:150])
# 各进程心跳统计
from collections import Counter
hb=[l for l in L if 'tl: cnt' in l]
procs=Counter(re.search(r'annibalemetal\[(\S+) \d+\]',l).group(1) for l in hb if re.search(r'annibalemetal\[(\S+) \d+\]',l))
print(" heartbeat by process:",dict(procs))
# 非0 commit 的进程
for l in hb[-6:]: print("  [hb]",l[:140])

print("\n=== [C] touch2: latest GPU/draw/commit lines ===")
for key in ['has run for','has not moved','tl: fw','tl: t ','work kind']:
    hits=[l for l in L if key in l]
    print(f" '{key}': {len(hits)}")
    for l in hits[-5:]: print("   ",l[:160])

print("\n=== [D] touch2: iconservicesagent / cameracaptured / SpringBoard render lines ===")
for key in ['iconservicesagent','cameracaptured']:
    hits=[l for l in L if key in l and 'annibalemetal' in l]
    print(f" {key}: {len(hits)} annibalemetal lines")
    for l in hits[-6:]: print("   ",l[:160])

print("\n=== [E] touch2: MiniIOMobileFramebuffer lines ===")
for l in [l for l in L if 'MiniIOMobileFramebuffer' in l]:
    t=ts_re.search(l); print("   ",(t.group(1)[11:] if t else '     ?    '),l[:130])

print("\n=== [F] touch2: last 8 timestamps of any line ===")
allt=[(ts_re.search(l).group(1),l) for l in L if ts_re.search(l)]
for t,l in allt[-8:]: print("   ",t[11:],l[:120])
