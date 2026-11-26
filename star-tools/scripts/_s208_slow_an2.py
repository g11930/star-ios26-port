import re
p='/mnt/c/ios26/s208-slow-1.bin'
d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
L=[l.strip() for l in d.splitlines() if l.strip()]

# Build indexed lines with wall-clock timestamp where available
def wts(l):
    m=re.match(r'\s*(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d)', l)
    return m.group(1) if m else None

# 1. exact milestone markers (star: milestone) - these are kernel boot phases
print("=== [1] star: milestone markers (kernel boot phases) ===")
for i,l in enumerate(L):
    if 'star: milestone' in l:
        print(f"  L{i}: {l[:140]}")

# 2. PAC trap rate: sample counter value vs wallclock at that line
print("\n=== [2] PAC counter vs wall-clock (rate estimate) ===")
last_ts=None
samples=[]
for i,l in enumerate(L):
    ts=wts(l)
    if ts: last_ts=ts
    m=re.search(r'pac: traps=(\d+)', l)
    if m and last_ts:
        samples.append((last_ts, int(m.group(1)), i))
# dedupe consecutive identical (ts,val)
uniq=[]
for s in samples:
    if not uniq or (s[0],s[1])!=(uniq[-1][0],uniq[-1][1]):
        uniq.append(s)
# sample across timeline: every ~Nth
step=max(1,len(uniq)//15)
for s in uniq[::step][:16]:
    print(f"  {s[0]}  traps={s[1]:>12,}  L{s[2]}")
if uniq:
    print(f"  FINAL {uniq[-1][0]}  traps={uniq[-1][1]:,}")

# 3. timer delays
print("\n=== [3] timer / delay / slow lines ===")
for l in L:
    if re.search(r'Timer.*delay|delayed \d|took \d+\.?\d* ?(s|ms)|slow', l, re.I):
        print("  ", l[:170])

# 4. wall clock span
ts=[wts(l) for l in L if wts(l)]
print("\n=== [4] wall-clock span ===")
print("  first:", ts[0] if ts else "NONE", " last:", ts[-1] if ts else "NONE", " count:", len(ts))

# 5. GPU commit run-time (slow render)
print("\n=== [5] GPU commit run-time >=10ms ===")
slow=[l for l in L if re.search(r'commit \d+ has run for \d+ ?ms', l)]
print("  count:", len(slow))
for l in slow[:15]: print("  ", l[:150])
