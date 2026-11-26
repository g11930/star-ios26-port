import re
d=open('/mnt/c/ios26/s208-touch1.bin','rb').read().decode('utf-8','replace').replace('\0','')
L=[l.strip() for l in d.split('\n') if l.strip()]

ts_re=re.compile(r'(2025-12-10 [\d:]{8})')
def ts_of(l):
    m=ts_re.search(l)
    return m.group(1) if m else None

print("=== [1] WorldClockWidget spam rate ===")
spam=[l for l in L if 'WorldClockWidget' in l]
print("  total WorldClockWidget lines:",len(spam))
by_sec={}
for l in spam:
    t=ts_of(l)
    if t: by_sec[t]=by_sec.get(t,0)+1
secs=sorted(by_sec)
print("  seconds covered:",len(secs))
if secs:
    print("  first:",secs[0],"rate",by_sec[secs[0]])
    print("  last :",secs[-1],"rate",by_sec[secs[-1]])
    mx=max(by_sec.values())
    print("  max lines/sec:",mx,"at",[k for k,v in by_sec.items() if v==mx][:3])
    # 每分钟速率
    by_min={}
    for k,v in by_sec.items(): by_min[k[:16]]=by_min.get(k[:16],0)+v
    for k in sorted(by_min): print("   ",k,"->",by_min[k],"lines")

print("\n=== [2] crash/exit/jetsam lines ===")
pat=re.compile(r'exit|jetsam|Jetsam|ReportCrash|crash|terminat|kill|fatal',re.I)
cl=[l for l in L if pat.search(l) and 'WorldClockWidget' not in l]
print("  matched:",len(cl))
seen=set()
for l in cl[-25:]:
    k=l[:80]
    if k in seen: continue
    seen.add(k); print("   ",l[:170])

print("\n=== [3] backboardd/WindowServer recent ===")
bb=[l for l in L if re.search(r'backboardd|WindowServer',l)]
print("  total:",len(bb))
for l in bb[-8:]: print("   ",l[:170])

print("\n=== [4] WindowServer Timer delayed ===")
td=[l for l in L if 'Timer delayed' in l or 'timer delayed' in l]
print("  count:",len(td))
for l in td[-6:]: print("   ",l[:170])

print("\n=== [5] render/pipeline lines ===")
rp=[l for l in L if re.search(r'render pipeline|MTLCompiler|Compilation|metal',re.I)]
print("  count:",len(rp))
for l in rp[-5:]: print("   ",l[:160])

print("\n=== [6] 每分钟日志量(整体) ===")
allsec={}
for l in L:
    t=ts_of(l)
    if t: allsec[t[:16]]=allsec.get(t[:16],0)+1
for k in sorted(allsec)[-20:]: print("   ",k,"->",allsec[k],"lines")

print("\n=== [7] 最后一条非 runningboardd/chronod 行 ===")
for l in reversed(L):
    if not re.search(r'runningboardd|chronod|WirelessRadioManagerd',l):
        print("   ",l[:170]); break
print("\n=== [8] log 时间分布的最后时间 ===")
lastt=None
for l in L:
    t=ts_of(l)
    if t: lastt=t
print("  last timestamp in log:",lastt)
