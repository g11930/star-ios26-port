import re
p='/mnt/c/ios26/s208-now.bin'
d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
L=[l.strip() for l in d.splitlines() if l.strip()]
print("lines:",len(L))

def c(s): return sum(1 for l in L if s in l)
print("\n=== health counters ===")
for k in ['PANIC','haltRestart','pac: page','mount-phase-2','THE GPU STAYS',
          'unlockedEnvironmentMode','render pipelines','swap #','SpringBoard','backboardd',
          'THE GPU DID NOT FINISH','no answer','commit','fence_wait']:
    print(f"  {k}: {c(k)}")

# panic / error lines
print("\n=== panic / error / crash lines ===")
n=0
for l in L:
    if re.search(r'PANIC|panic:|haltRestart|not a platform binary|THE GPU DID NOT FINISH|no answer|crash|abort\(\)', l, re.I):
        print("  ",l[:190]); n+=1
        if n>=30: break
if n==0: print("  (none)")

# wall-clock span + gaps >30s (freeze detector)
print("\n=== wall-clock gaps > 30s (potential freezes) ===")
from datetime import datetime
def parse(l):
    m=re.match(r'\s*(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d)',l)
    if not m: return None
    try: return datetime.strptime(m.group(1),'%Y-%m-%d %H:%M:%S')
    except: return None
prev=None; gaps=[]
for l in L:
    t=parse(l)
    if t:
        if prev and (t-prev).total_seconds()>30: gaps.append((prev,t,(t-prev).total_seconds()))
        prev=t
for g in gaps[:20]: print(f"  {g[0].time()} -> {g[1].time()}  gap {g[2]:.0f}s")
if not gaps: print("  (none)")

# PAC traps rate over timeline
print("\n=== PAC traps timeline ===")
last=None; samp=[]
for l in L:
    t=parse(l) or last
    if parse(l): last=t
    m=re.search(r'traps=(\d+)',l)
    if m and t: samp.append((t,int(m.group(1))))
uniq=[]
for s in samp:
    if not uniq or s!=(uniq[-1]): uniq.append(s)
step=max(1,len(uniq)//12)
for s in uniq[::step][:13]: print(f"  {s[0].time()}  {s[1]:,}")
if uniq: print(f"  FINAL {uniq[-1][0].time()}  {uniq[-1][1]:,}")

# swap / frames / touch
print("\n=== frame / swap / touch (last 3 each) ===")
for k in ['swap #','frames in','so far','tl: c','tl: p','tl: s','commit ','built']:
    kl=[l for l in L if k in l]
    print(f"  [{k}] {len(kl)}")
    for l in kl[-2:]: print("     ",l[:160])

# last 15 lines
print("\n=== last 15 lines ===")
for l in L[-15:]: print("  ",l[:170])
